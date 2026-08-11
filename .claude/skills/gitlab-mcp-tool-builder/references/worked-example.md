# Worked example — `get_merge_request_notes`

A complete, shipped read tool to copy from. Shows the `.graphql` file, the
`Base::GraphqlService` service, url-or-pair resolution, and the design lessons.

**Scope:** fetch notes for a MR, identified either by `url` **or** by `project_id` +
`merge_request_iid`, with forward/backward pagination.

**Files:**
- Operation: `app/graphql/queries/mcp/merge_requests/get_merge_request_notes.query.graphql`
- Tool: `app/services/mcp/tools/merge_requests/get_merge_request_notes_tool.rb`
- Service: `app/services/mcp/tools/merge_requests/get_merge_request_notes_service.rb`
- Manager: `'get_merge_request_notes' => ::Mcp::Tools::MergeRequests::GetMergeRequestNotesService`
- specs: unit ×2 + CE & EE `list_tools_spec` entries

**Operation file** — first line is the feature-category comment, verb-first name,
`operation_name` is the **root field** `project` (not `getMergeRequestNotes`); iids
are Strings:
```graphql
# @feature_category: mcp_server
query getMergeRequestNotes($fullPath: ID!, $iid: String!, $after: String, $before: String, $first: Int, $last: Int) {
  project(fullPath: $fullPath) {
    id
    mergeRequest(iid: $iid) {
      id
      resolvedDiscussionsCount
      resolvableDiscussionsCount
      notes(after: $after, before: $before, first: $first, last: $last) {
        pageInfo { hasNextPage hasPreviousPage startCursor endCursor }
        nodes { id body system internal createdAt author { username } }
      }
    }
  }
}
```

**Tool class** subclasses `GraphqlTool` directly, includes `Concerns::ResourceFinder`,
loads the operation from the file, and resolves url-or-pair in `build_variables`:
```ruby
class GetMergeRequestNotesTool < Mcp::Tools::GraphqlTool
  include Mcp::Tools::Concerns::ResourceFinder

  def self.build_query
    load_graphql('merge_requests/get_merge_request_notes.query.graphql')
  end

  register_version VERSIONS[:v0_1_0], { operation_name: 'project', graphql_operation: build_query }

  def build_variables
    full_path, iid = resolve_target   # from params[:url] OR params[:project_id]+[:merge_request_iid]
    { fullPath: full_path, iid: iid.to_s,
      after: params[:after], before: params[:before],
      first: params[:first], last: params[:last] }.compact
  end
  # resolve_target + a process_result that maps null project/mergeRequest → Response.error(not found)
end
```

**Service class** subclasses `Base::GraphqlService`, marks itself read-only, and
requires nothing (either identification path is valid):
```ruby
class GetMergeRequestNotesService < Base::GraphqlService
  register_version '0.1.0', {
    description: 'Get the notes (comments and system notes) for a specific merge request.',
    input_schema: { type: 'object', required: [], properties: { url: {...}, project_id: {...},
      merge_request_iid: {...}, after: {...}, before: {...}, first: {...}, last: {...} } },
    annotations: { readOnlyHint: true }
  }
  # graphql_tool_class → GetMergeRequestNotesTool; perform_v0_1_0/perform_default → execute_graphql_tool
end
```
(No `additionalProperties` in the schema — `SchemaDefaults` adds `false` for you.)

## Design lessons worth keeping
- **Prefer flat `MergeRequest.notes(filter:)` over paging `discussions` then
  post-filtering.** `discussions` has no server-side system-note filter; dropping
  system notes client-side after paginating threads returns too few results because a
  page can be all system-only threads. If you need thread structure, group the flat
  notes by `discussion.id` client-side.
- **No efficient single-discussion fetch exists** — no `discussions(id:)` arg, no
  root `node(id:)`, no `Query.discussion(id:)`. Don't page-then-filter to emulate one.
