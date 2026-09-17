---
source_checksum: 9b214d413ac3476e
distilled_at_sha: 98a4a3ab667724497f85efcd3a8545cfe1d1efd3
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

# MCP Server Principles

## Checklist

### Tool Proposal and Governance

- Submit a [MCP Tool Proposal issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/new?related_item_id=undefined&type=ISSUE&description_template=MCP%20Tool%20Proposal) and follow the template before implementing any new tool; the `mcp-tool-review-board` committee evaluates proposals before implementation.
- Implement tools that interact with GitLab resources in the MCP Server (or Agent Platform for short-term needs); implement tools that do not interact with GitLab resources in the Agent Platform.
- DO NOT add a new tool when an existing tool can handle the capability with parameter adjustments; prefer consolidation via an enum or parameter over proliferation.
- Declare which input argument names the project or group for custom, GraphQL, and aggregated tools through `self.namespace_arguments`; mark tools that accept no project or group argument as `ungovernable!` instead. Exception: route-backed `ApiTool` tools derive the namespace from the route's authorization `boundary_type` (`:project` or `:group`) and its `:id` argument, with no custom declaration; when no boundary type is set, they use the default namespace declaration.
- Use the default `{ project: :project_id, group: :group_id }` namespace declaration when the tool's input schema already uses those argument names; override only when the tool uses different argument names (e.g., `project_full_path`, `full_path`).
- Use `:project_or_group` as the container kind when a single argument may name either a project or a group.
- DO NOT add a separate authorization check after calling `ResourceFinder#find_project!` or `#find_group!`; both finders fold authorization into the DB lookup and raise `"'<id>' not found or inaccessible"` on failure to prevent resource enumeration.
- Ensure `ee/spec/lib/ai/tool_rules/governable_tools_namespace_spec.rb` passes: every governed tool must declare a namespace argument or be marked `ungovernable!`, the declared argument must exist in the tool's input schema, and the declaration must use a recognized container kind (`:project`, `:group`, or `:project_or_group`).

### Tool Naming and Consolidation

- Use `verb_object` shape for all tool names: `get_` for a single object, `list_` for a collection, `save_` for create/update mutations, `delete_` for delete operations, and `add_` (or another deviation) for objects without a typical CRUD shape (e.g., commits, branches, sessions).
- DO NOT fold `delete_` operations into `save_` tools; keep them separate for governance handling.
- Use a `save_` tool's `action` parameter to fold non-field-mutation lifecycle actions (e.g., `retry`, `cancel`) on the same resource when they don't warrant a dedicated tool; route on the presence of the resource's own ID rather than the parent identifier, and document this as an intentional exception.
- Keep `project_id` and the resource's internal ID (e.g., `merge_request_iid`, `work_item_iid`, `commit_sha`) as separate parameters; DO NOT fold them into a single `id`.
- Accept either `url` (a full GitLab URL) or the ID group (`project_id` plus the resource's internal ID) as input; include `Mcp::Tools::Concerns::UrlParser` and `Mcp::Tools::Concerns::ResourceFinder` to resolve them. When both are supplied, cross-validate and raise an error on mismatch.
- Merge scoped search variants into the unified `search` tool with a `scope` parameter instead of adding per-resource search tools.
- Document intentional exceptions (one-off action verbs, a second write tool on one resource) in the tool proposal so they are not mistaken for oversights.

### Tool Reads, Facets, and Pagination

- Fold facets scoped to one parent object into that object's `get_` tool via an `include` parameter (e.g., `get_merge_request` with `include: ["diffs"]`); declare `include` as an array of enum values bounded with `maxItems` even when only one facet per call is supported.
- Give independent collections their own `list_` tool (e.g., `list_merge_requests`, `list_pipelines`).
- Scope facet pagination to the `get_` reader; name parameters `<facet>_first`/`<facet>_after` (and `<facet>_last`/`<facet>_before` when reading from the end matters); build them with `Mcp::Tools::Concerns::CursorPagination.input_schema_params`; return the connection's `pageInfo` alongside the nodes.
- Add a `detail` enum (`none`/`stats`/`full_patch`) on diff-bearing reads where the diff dominates the payload; DO NOT retrofit `detail` where a better-suited knob already exists (file content uses line pagination `offset`/`limit`; job logs use byte pagination `byte_offset`/`byte_limit`).
- Prefer a filter parameter over a new facet or tool when one facet is a subset of another (e.g., `job_status: failed` instead of a separate `failing_jobs` facet).
- Mirror the pagination scheme of the endpoint the tool wraps; DO NOT translate between schemes (e.g., do not wrap offset pagination in an opaque cursor).
- Use offset pagination (`page`, `per_page` defaulting to 20 capped at 100, returning `metadata` with `page`, `per_page`, `has_more`) for REST-backed tools.
- Use native cursor pagination (`first` defaulting to 20 capped at 100, `after`, returning `pageInfo` with `endCursor` and `hasNextPage`) for GraphQL-backed tools.
- Unwrap GIDs to numeric integers in `process_result` for resources addressed by global numeric ID (groups, projects, pipelines) using `GlobalID.parse(node['id']).model_id.to_i`; DO NOT unwrap IDs of iid-addressed resources (work items, merge requests, issues) — expose `iid` alongside the GID instead.

### REST API Tool Implementation

- Add `route_setting :mcp, tool_name: :name, params: [...], resource_name: "resource"` to an API route to expose it as an MCP tool; use a lowercase `resource_name` string for resource-specific 404 messages.
- Add the matching `allow_mcp_access_*` call (`allow_mcp_access_read`, `allow_mcp_access_create`, `allow_mcp_access_update`, `allow_mcp_access_delete`) to the API class for each HTTP method used by its MCP routes; include `::API::Concerns::McpAccess` in the class.
- Use `Base::AggregatedService` for aggregated REST tools that consolidate multiple related API endpoints (e.g., global, group, and project search into one tool); register underlying API tools with `aggregators: [AggregatorClass]` in their route settings.

### GraphQL Tool Implementation

- Use the two-layer architecture for GraphQL-backed MCP tools: a `GraphqlTool` subclass (Layer 1) handles GraphQL execution, and a `GraphqlService` subclass (Layer 2) handles validation, versioning, and response formatting.
- Name service and tool subclasses after the operation without a `Graphql` prefix (e.g., `Mcp::Tools::Labels::SearchService`, `Mcp::Tools::Notes::SaveNoteTool`); only the base classes `GraphqlService` and `GraphqlTool` keep the prefix.
- Store each tool's GraphQL operation in a `.graphql` file under `app/graphql/queries/mcp/` in a subdirectory mirroring the tool's domain; load it with `GraphqlTool.load_graphql` using the direct form (not a lambda) in `register_version`. Exception: operations composed at load time from EE-overridden fragments must use a lambda (`graphql_operation: -> { build_query }`).
- Name `.graphql` files with a `.query.graphql` or `.mutation.graphql` suffix; use a verb-first name for queries (e.g., `getWorkItemTypes`) and mutations already use verb-first names (e.g., `createNote`).
- Start every `.graphql` file with a `# @feature_category:` comment; the `graphql_require_feature_category` lint rule fails CI without it.
- DO NOT embed GraphQL operations as inline strings or HEREDOCs; the `Mcp/UseGraphqlQueryFile` RuboCop rule flags inline strings or HEREDOCs passed as `graphql_operation:`.
- Register GraphQL tools in `Mcp::Tools::Manager` under `GRAPHQL_TOOLS` with the tool name as key and the service class as value.
- Override `graphql_tool_class` in the service wrapper to return the corresponding `GraphqlTool` subclass; call `execute_graphql_tool(arguments)` in version-specific `perform_v<X>_<Y>_<Z>` methods.
- DO NOT add `additionalProperties: false` to `input_schema`; the shared tool abstraction rejects unrecognized arguments by default. Set `additionalProperties: true` only to accept arbitrary arguments. Schemas using `oneOf`, `anyOf`, `allOf`, or `$ref` keep their own behavior.
- Override `self.namespace_arguments` on GraphQL service classes to declare which input argument names the project or group (see Tool Proposal and Governance).
- Add unit tests for the GraphQL tool, integration tests for the service, and update `ee/spec/services/ee/mcp/tools/manager_spec.rb`, `spec/requests/api/mcp/handlers/list_tools_spec.rb`, and `ee/spec/requests/api/mcp/handlers/list_tools_spec.rb`.

### Tool Versioning

- Register versions using `register_version '<semver>', { description:, input_schema: }` for aggregated, custom, and GraphQL tools; implement a corresponding `perform_v<X>_<Y>_<Z>` method and update `perform_default` to delegate to the latest version.
- DO NOT modify a tool's existing behavior without registering a new version; use the versioning system to avoid breaking cached tool schemas in LLM clients.
- For API tools, specify the version in the route setting (`version: '1.0.0'`) when needed; API tools default to `0.1.0`. For tools requiring multiple versions, implement as a custom tool instead.
- Follow [multi-version compatibility guidelines](https://docs.gitlab.com/development/multi_version_compatibility/) when deprecating versions.
- When adding a second version to a GraphQL tool, rename the existing `.graphql` file to include its version (e.g., `create_note.v0_1_0.mutation.graphql`) and add a new file for the new version; register each version against its own file.
- Define `build_variables_v<X>_<Y>_<Z>` methods for version-specific variable building; `build_variables_for_version` calls the version-specific method when it exists and falls back to `build_variables`.

### Tool Renaming and Aliases

- Override `tool_aliases` on the tool class (or use `tool_aliases:` in the route setting for API tools) to include the old name when renaming a tool; DO NOT remove aliases until a dedicated identity mechanism decouples governance from rename aliases (tracked in [work item 609451](https://gitlab.com/gitlab-org/gitlab/-/work_items/609451)).
- Update all references to the new tool name in route settings, test files, documentation, and hardcoded references when renaming.
- DO NOT use `tool_aliases:` on a route that also sets `aggregators:`; aliases for aggregated tools come from the aggregator class's `self.tool_aliases`.

### Tool Availability and Discovery

- Override `available?` on custom, GraphQL, or aggregated service classes to filter `tools/list` for a user (e.g., behind a feature flag); it runs after `set_cred(current_user:)`. DO NOT rely on it to block `tools/call` or hide tools from the AI Catalog picker; neither checks it. Route-backed API tools are always considered available.
- Override `unlisted?` (or set `unlisted: true` in the route setting for API tools) to hide a tool from `tools/list` and the AI Catalog picker while keeping it callable via `tools/call`; use this to stage a tool before it is ready to be advertised.
- Keep `unlisted?` static; DO NOT drive it from a per-user or credential-dependent check because the AI Catalog picker cannot evaluate one.

### Splitting Actions Out of Aggregated Tools

- When splitting a collection-reading action out of an aggregated tool into a dedicated `list_` tool, document the change with a `[Removed]` entry in the old tool's history block in [MCP server tools](https://docs.gitlab.com/user/model_context_protocol/mcp_server_tools/) noting which action moved and to which tool, alongside the `[Introduced]` entry for the new tool.

### Custom Tool Implementation

- For tools with distinct functionality that should remain separate from API exposure, define a standalone class inheriting from `Base::CustomService`.

### Development Environment and Debugging

- Enable and configure HTTPS in GDK, install `node` and `mcp-remote` globally (not the GDK-bundled version), and connect an AI assistant to the MCP server before developing MCP tools.
- Add `--debug` to the `mcp-remote` command for detailed logging; view MCP server logs in the Output panel under `MCP:SERVERNAME`.
- Clear `~/.mcp-auth` as a last resort to reset stored `mcp-remote` credentials when encountering authentication issues after switching branches.
- Use [MCP Inspector](https://modelcontextprotocol.io/legacy/tools/inspector) (`npx -y @modelcontextprotocol/inspector npx`) for interactive testing and debugging of MCP servers.
- Use the `gitlab-mcp-tool-builder` skill (located at `.claude/skills/gitlab-mcp-tool-builder/`) to scaffold a GraphQL-backed MCP tool; if the skill and the guidelines disagree, follow the guidelines and update the skill.

## Authoritative sources

For the full picture, see:

- doc/development/duo_agent_platform/mcp/_index.md
- doc/development/duo_agent_platform/mcp/graphql_integration.md

