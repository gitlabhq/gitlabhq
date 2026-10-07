# Worked example — `get_commit`

A complete, shipped read tool to copy from. Shows the `.graphql` file, the
`Base::GraphqlService` service, url-or-pair resolution, an `include` facet with cursor
pagination, and the design lessons.

**Scope:** fetch one commit, identified either by `url` **or** by `project_id` +
`commit_sha`, optionally with its diff or its notes (one facet per call).

**Files:**
- Operation: `app/graphql/queries/mcp/commits/get_commit.query.graphql`
- Tool: `app/services/mcp/tools/commits/get_commit_tool.rb`
- Service: `app/services/mcp/tools/commits/get_commit_service.rb`
- Manager: `'get_commit' => ::Mcp::Tools::Commits::GetCommitService`
- specs: unit ×2 + CE & EE `list_tools_spec` entries

**Operation file** — first line is the feature-category comment, verb-first name,
`operation_name` is the **root field** `project` (not `getCommit`). Facets are gated
with `@include` so an unrequested facet costs nothing (abridged):
```graphql
# @feature_category: mcp_server
query getCommit($fullPath: ID!, $ref: String!, $withStats: Boolean = false,
  $withPatch: Boolean = false, $withNotes: Boolean = false,
  $notesAfter: String, $notesFirst: Int) {
  project(fullPath: $fullPath) {
    id
    repository {
      commit(ref: $ref) {
        id sha title message webUrl authoredDate
        diffStatsSummary @include(if: $withStats) { additions deletions fileCount }
        diffs @include(if: $withPatch) { oldPath newPath diff collapsed tooLarge }
        notes(after: $notesAfter, first: $notesFirst) @include(if: $withNotes) {
          pageInfo { hasNextPage endCursor }
          nodes { id body system createdAt author { username } }
        }
      }
    }
  }
}
```

**Tool class** subclasses `Base::GraphqlTool`, includes `Concerns::ResourceFinder`,
loads the operation from the file, and resolves url-or-pair in `build_variables`:
```ruby
class GetCommitTool < Mcp::Tools::Base::GraphqlTool
  include Mcp::Tools::Concerns::ResourceFinder

  register_version VERSIONS[:v0_1_0], {
    operation_name: 'project',
    graphql_operation: load_graphql('commits/get_commit.query.graphql')
  }

  def build_variables
    full_path, ref = resolve_target   # from params[:url] OR params[:project_id]+[:commit_sha]
    facets = Array(params[:include]).map(&:to_s)
    diff_detail = params[:diff_detail] || DEFAULT_DETAIL   # 'stats'
    with_diff = facets.include?('diff')
    { fullPath: full_path, ref: ref,
      withStats: with_diff && diff_detail == 'stats',
      withPatch: with_diff && diff_detail == 'full_patch',
      withNotes: facets.include?('notes'),
      notesAfter: params[:notes_after], notesFirst: params[:notes_first] }.compact
  end
  # resolve_target raises ArgumentError when both or neither identification path is given;
  # process_result maps a null project/commit → Response.error("... not found or inaccessible").
  # get_commit predates `reason:` — pass reason: Response::Reason::NOT_FOUND in a new tool.
end
```

**Service class** subclasses `Base::GraphqlService`, declares its toolset, marks itself
read-only, and requires nothing (either identification path is valid):
```ruby
class GetCommitService < Base::GraphqlService
  register_version '0.1.0', {
    toolset: :repository,
    description: "Get a single commit's metadata, optionally including its diff or notes. " \
      'Identify the commit with either url, or project_id and commit_sha.',
    input_schema: { type: 'object', required: [], properties: {
      url: {...}, project_id: {...}, commit_sha: {...},
      include: { type: 'array', items: { type: 'string', enum: %w[diff notes] }, maxItems: 1 },
      diff_detail: { type: 'string', enum: %w[stats full_patch] },
      **Mcp::Tools::Concerns::CursorPagination.input_schema_params(
        items: 'notes', prefix: 'notes_', applies_to: 'notes is in include')
    } },
    annotations: { readOnlyHint: true }
  }
  # graphql_tool_class → GetCommitTool; perform_v0_1_0/perform_default → execute_graphql_tool
end
```
(No `additionalProperties` in the schema — `SchemaDefaults` adds `false` for you.)

## Design lessons worth keeping
- **Facets go in `include`, not in sibling tools.** Notes on a commit are an `include`
  value on `get_commit`, paginated with `notes_*` params from `CursorPagination`. Several
  older per-facet tools were unlisted for exactly this reason.
- **Bound the payload with a knob, and signal what was cut.** `diff_detail` defaults to
  `stats`, so the patch text is only sent on request, and `collapsed`/`tooLarge` tell the
  agent when a diff was left out.
