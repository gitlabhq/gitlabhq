# Tool anatomy — the two classes, field by field

Detailed reference for the `*Tool` + `*Service` pair. The `SKILL.md` recipe is the
spine; this file is the field-level detail for each class, plus the mutation deltas.

## The Tool class — `app/services/mcp/tools/<area>/<name>_tool.rb`

Holds the **operation reference** and the **variable mapping**. Subclass of
`GraphqlTool` directly (`class <Name>Tool < Mcp::Tools::GraphqlTool`).

- **No `Concerns::Constants` include needed** — `GraphqlTool` already includes
  both `Versionable` and `Constants`, so `VERSIONS` is in scope on any subclass.
  (This is what !240899 landed; the old "re-include Constants" step is gone.)
- `include Mcp::Tools::Concerns::ResourceFinder` — when you resolve a
  project/group from a path/id (most tools do; gives `find_project!` and `find_group!`).
- **URL parsing — two patterns depending on what the `url` points at:**
  - **Specific-resource URL** (e.g. a MR URL like `.../merge_requests/42`): use
    `::MergeRequest.link_reference_pattern.match(url)` directly — extracts `namespace`,
    `project`, and `merge_request` named captures. See `get_merge_request_notes_tool.rb`.
  - **Project-or-group URL** (e.g. `.../namespace/project` or `.../groups/namespace/group`):
    include `Mcp::Tools::Concerns::UrlParser` alongside `ResourceFinder` and call
    `parse_parent_url(url)` → `{ type: :project/:group, path: 'full/path' }`. Handles
    both plain project URLs and `groups/`-prefixed group URLs automatically.
- `include Mcp::Tools::Concerns::ContentValidation` — for write tools that accept
  free-text (gives `validate_no_quick_actions!`).
- `register_version VERSIONS[:v0_1_0], { operation_name: '<root field>', graphql_operation: load_graphql('<domain>/<name>.query.graphql') }`
  — the operation is **loaded from a `.graphql` file**, not an inline heredoc (see
  the "`.graphql` files" section in `SKILL.md`). Both inline `load_graphql(...)` and
  a `self.build_query` wrapper are used in the tree — prefer the inline form unless
  you need a named reference for EE overrides.
- `build_variables` → maps incoming `params` → the `$variables` in the operation;
  end with `.compact` so unset optional vars are dropped.
- **`build_variables_v0_1_0` protected method** — add a `protected def build_variables_v0_1_0`
  that delegates to `build_variables`. This is required by the versioning framework:
  ```ruby
  protected

  def build_variables_v0_1_0
    build_variables
  end
  ```
  The method suffix is the version with dots replaced by underscores and a `v` prefix
  (e.g. `0.1.0` → `v0_1_0`). `Versionable#version_method_suffix` owns this prefix;
  callers build `"perform_#{version_method_suffix}"` and
  `"build_variables_#{version_method_suffix}"`. For a non-`0.1.0` version, apply the
  same rule: `1.0.0` → `v1_0_0`.
- optional `process_result` → reshape `GitlabSchema.execute` output. Call `super`
  first, bail on `processed_result[:isError]`, dig into `structuredContent`, and
  return `::Mcp::Tools::Response.success(content, data)` / `.error(msg)`.

## The Service class — `app/services/mcp/tools/<area>/<name>_service.rb`

The **agent-facing wrapper**. Subclass of `Base::GraphqlService` (the base services
moved under `Mcp::Tools::Base`; write `class <Name>Service < Base::GraphqlService`).

- `register_version '0.1.0', { description:, input_schema:, annotations: }`
  - `input_schema` = JSON Schema of the arguments the **agent sends** (this is the
    contract the LLM sees — names, types, required[]).
  - **Do not add `additionalProperties: false` by hand.** It is applied
    automatically to every tool schema by `Mcp::Tools::SchemaDefaults` (!243352),
    so unknown arguments are rejected consistently. Only set `additionalProperties`
    explicitly if you deliberately want `true` (a passthrough tool) — an explicit
    value is never overwritten. (Composition schemas using `oneOf`/`anyOf`/`allOf`/
    `$ref` are skipped, since a top-level `false` can't see subschema properties.)
  - `annotations: { readOnlyHint: true }` for read tools. **This flag changes
    behavior, it is not just documentation:** the pre-approved MCP tool list is
    derived at runtime from `readOnlyHint` (!231431). A write tool wrongly marked
    `readOnlyHint: true` would be auto-approved to run without confirmation — get
    it right.
- `graphql_tool_class` → points at the Tool class.
- `perform_v0_1_0` / `perform_default` → `execute_graphql_tool(arguments)`.

### Naming — no `Graphql` prefix, group by domain

Name the service and tool after the operation, without a `Graphql` prefix (only the
base classes `Base::GraphqlService`/`GraphqlTool` keep it — every subclass already
inherits one, and there is no separate `graphql/` folder, so the prefix adds
nothing). Both classes live in a domain module:
`Mcp::Tools::MergeRequests::GetMergeRequestNotesService` / `..._tool.rb` under
`app/services/mcp/tools/merge_requests/`. The reorganize-by-domain + drop-prefix +
move-base-classes-to `Base::` work is tracked in `gitlab-org/gitlab#603096` (stack:
base services merged; tool classes to `Mcp::Tools::Base` in !243272). The
`tool_name` keys in `Manager` are a public, append-only contract — renaming a Ruby
class never renames its registered tool.

## Registration — `app/services/mcp/tools/manager.rb`

One line in `GRAPHQL_TOOLS`:
```ruby
'<tool_name>' => ::Mcp::Tools::<Area>::<Name>Service
```

## Project-or-group tools — the `@skip`/`@include` pattern

When a tool must query either a project or a group based on the caller's input (e.g.
`list_merge_requests` which works on both), use a **single `.graphql` file** with
GraphQL directives rather than two separate operations:

```graphql
# @feature_category: mcp_server
query myQuery($fullPath: ID!, $isProject: Boolean = false) {
  group(fullPath: $fullPath) @skip(if: $isProject) {
    id
    mergeRequests(...) { ... }
  }
  project(fullPath: $fullPath) @include(if: $isProject) {
    id
    mergeRequests(...) { ... }
  }
}
```

Then in the Tool class:

- **Omit `operation_name:` from `register_version`** — override it as an instance method instead:
  ```ruby
  register_version VERSIONS[:v0_1_0], {
    graphql_operation: load_graphql('domain/my_query.query.graphql')
  }

  def operation_name
    params[:is_project] ? 'project' : 'group'
  end
  ```
- Pass `isProject: <bool>` in `build_variables` — resolved from the url or `project_id`/`group_id` params.
- Use `include Mcp::Tools::Concerns::UrlParser` alongside `ResourceFinder` to parse the `url` param:
  `parse_parent_url(url)` returns `{ type: :project/:group, path: 'full/path' }`,
  handling both plain project URLs and `groups/`-prefixed group URLs automatically.

See `app/services/mcp/tools/labels/search_tool.rb` + `app/graphql/queries/mcp/labels/search.query.graphql` as the canonical example.

## Mapping cheat-sheet (explorer query → code)

| In the explorer | Goes into |
|---|---|
| the query document | a `.graphql` file in `app/graphql/queries/mcp/<domain>/`, loaded via `load_graphql` |
| the Variables pane JSON | Tool `build_variables` |
| the query's **root field** name | Tool `operation_name` |
| which args the agent may send | Service `input_schema` |
| the tool name the agent calls | Manager `GRAPHQL_TOOLS` key |

## Writes (mutations) — the deltas vs. a read tool

Same two-class shape; a mutation just changes a few specifics:

- **`operation_name` is the mutation root field** (e.g. `createNote`), not the
  `mutation Name` label — same rule as reads.
- **Resolve the target to a global id.** Mutation inputs take global ids
  (`gid://gitlab/MergeRequest/123`), not iids. Resolve via a Finder run as
  `current_user` (e.g. `MergeRequestsFinder`) → `record.to_global_id.to_s` → feed
  it as `noteableId` (or whatever the `*Input` type names). Build the input as a
  hash and `.compact` optional keys.
- **Annotations flip:** `annotations: { readOnlyHint: false, destructiveHint: <bool> }`
  (a create/reply is typically non-destructive; a delete/close is destructive).
- **Check the payload `errors`.** Mutations return validation failures *in-band*
  under `data.<root>.errors`, not as a thrown exception — select `errors` in the
  query and inspect it in `process_result`, returning `::Mcp::Tools::Response.error`
  when present. Otherwise the tool reports "success" on a no-op.
- **Specs:** in the CE `list_tools_spec`, add the tool to the **`write_tools`** list
  (not `read_only_tools`); the EE entry's annotations must match the Service.
- **Safety:** mirror existing write tools — reject quick actions in free-text bodies
  via `include Mcp::Tools::Concerns::ContentValidation` and calling
  `validate_no_quick_actions!(params[:body], field_name: 'note body')` at the top of
  `build_variables`.
