---
name: gitlab-mcp-tool-builder
description: "Build a new GraphQL-backed MCP server tool in gitlab-org/gitlab. Use when adding or scaffolding a GitLab Duo Agent Platform MCP tool that follows the app/services/mcp/tools/ *Tool + Graphql*Service pattern — covers GraphQL API discovery, the two-class-plus-registration build recipe, and gotchas. Keywords: MCP tool, MCP server, GraphQL tool, GitLab Duo Agent Platform."
version: 1.8.0
license: MIT
compatibility: opencode
metadata:
  audience: developers
  keywords: MCP tool, MCP server, GraphQL tool, Duo Agent Platform, mcp/tools
  slash-command: enabled
---

# GitLab GraphQL MCP Tool Builder

Build a new **GraphQL-backed MCP server tool** in `gitlab-org/gitlab` — the `*Tool` +
`*Service` pair under `app/services/mcp/tools/`. Scope: GraphQL tools only. Bias to
**minimal, idiomatic change**: copy the closest existing GraphQL tool, swap the
query/variables/schema, register it — don't invent abstractions. Mirror existing
patterns, verify everything against the live schema (never guess field/arg/auth
details), and produce a tool + service + specs that pass `rubocop` and `rspec`.

**Canonical source of truth** (read first; this skill distills them and adds the
gotchas): `doc/development/duo_agent_platform/mcp/_index.md` (tool-proposal process,
versioning, aliases, aggregated tools) and
`doc/development/duo_agent_platform/mcp/graphql_integration.md` (the two-layer
architecture and the `.graphql`-file convention). If this skill and the docs
disagree, the docs win — tell the user so they can refile an update here.

**Before writing any tool: the proposal process is required.** New tools go through an
[MCP Tool Proposal issue](https://gitlab.com/gitlab-org/gitlab/-/issues/new?description_template=MCP%20Tool%20Proposal)
reviewed by the interim `mcp-tool-review-board`. Confirm the proposal exists (or is
waived) before building — tool proliferation degrades every agent's context, so the
bar for a new tool is deliberately high.

## What you're building

A GraphQL MCP tool is **two classes + one registration line**, executed in-process:

```
MCP client (JSON-RPC POST /api/v4/mcp, "tools/call")
  → API::Mcp::Base            (auth: PAT/token with `mcp` scope)
  → Handlers::CallTool        (looks up tool, sets current_user)
  → Manager.get_tool(name:)   (registry lookup)
  → <Name>Service             (picks version, defines agent-facing schema)
      → execute_graphql_tool(arguments)
      → <Name>Tool            (holds the operation + variable mapping)
          → GitlabSchema.execute(query, variables:, context:)   ← the actual call
          → process_result    (shape output → MCP Response)
```

- **`<Name>Tool`** (`.../<area>/<name>_tool.rb`) — subclass of `Mcp::Tools::GraphqlTool`;
  loads the operation from a `.graphql` file, maps `params → variables`, optionally
  reshapes output.
- **`<Name>Service`** (`.../<area>/<name>_service.rb`) — subclass of
  `Base::GraphqlService`; the agent-facing wrapper defining `input_schema`,
  `description`, and `annotations`.
- **Registration** — one line in `manager.rb` `GRAPHQL_TOOLS`:
  `'<tool_name>' => ::Mcp::Tools::<Area>::<Name>Service`.

Key fact: `GraphqlTool#execute` calls **`GitlabSchema.execute(...)`** — the same schema
the HTTP `/api/graphql` endpoint uses, run **as `current_user`**, so the tool inherits
the caller's permissions (don't re-check perms). Field-by-field detail of both classes,
the naming convention, the mapping cheat-sheet, and the mutation (write) deltas are in
**[references/tool-anatomy.md](references/tool-anatomy.md)**.

## GraphQL operations live in `.graphql` files — not inline strings

Every operation is a committed file under `app/graphql/queries/mcp/<domain>/`, loaded
by `GraphqlTool.load_graphql(<relative path>)`. This is enforced, not stylistic:

- The `Mcp/UseGraphqlQueryFile` RuboCop rule **fails** on an inline string / HEREDOC
  passed as `graphql_operation:` and points you at `load_graphql`.
- Files here are validated against `GitlabSchema` at build time by
  `spec/graphql/all_queries_spec.rb`, so an operation that drifts from the schema fails
  CI. An inline operation skips that safety check.

Rules for the file:
- **Name it `<name>.query.graphql` or `<name>.mutation.graphql`** in a subdirectory
  mirroring the tool's domain (`merge_requests/`, `work_items/`, `labels/`).
- **First line must be `# @feature_category: mcp_server`** — the
  `graphql_require_feature_category` lint rule fails without it.
- **Verb-first operation name** to match `app/graphql/queries` (`getMergeRequestNotes`,
  `createNote` — not `MergeRequestNotes`).
- **Load with the direct `load_graphql(...)` form, not a lambda.** `-> { load_graphql(...) }`
  rereads the file every request. The one exception is an operation *composed at load
  time* (e.g. a query built from EE-overridden fragments) — build it in a method and
  reference it with a lambda (`graphql_operation: -> { build_query }`).

## Tool naming and consolidation conventions (!245400)

> **Note:** Existing tools (`get_merge_request_notes`, `create_merge_request_note`, etc.)
> predate these conventions. Copy them for the **implementation pattern** but name and
> structure your new tool per the conventions below.

Every tool name uses a `verb_object` shape. The verb signals the operation class:

- **`get_`** — single object (e.g. `get_merge_request`)
- **`list_`** — collection (e.g. `list_merge_requests`)
- **`save_`** — create **or** update field mutations; presence of `id` determines which.
  Mark create-required params as `required` in the schema.
  Intentional exception: when a lifecycle action has its own mutation (e.g. `retry`, `cancel`)
  and targets the resource this tool creates, fold it behind an `action` param rather than
  adding a tool. Route on the resource's own ID, not the parent's, and state the rule in the
  tool description (`save_pipeline`: no `pipeline_id` creates, `pipeline_id` + `action`
  transitions). Annotations are per tool, so the whole tool inherits the most destructive
  action's `destructiveHint`; note the fold in the proposal.
- **`delete_`** — delete operations only; never fold into `save_`.
- **`add_`** or other verbs — reserved for objects without a typical CRUD shape (e.g. `add_commit`).

**Facets fold into `get_`, not separate tools.** Sub-reads scoped to one parent object
(notes, diffs, commits, pipelines) become an `include:` enum on the parent's `get_` tool
(e.g. `get_merge_request` with `include: diffs|commits|notes|pipelines|conflicts`), not
separate `list_*` tools. Independent collections that can be queried on their own get
their own `list_` tool (e.g. `list_merge_requests`, `list_pipelines`).

**Resource identification** is always `url` OR `project_id` + resource internal ID —
never folded into a single `id`. `url` is the single-value convenience path; `project_id`
+ `iid`/`sha`/etc. is the explicit path. When both are supplied they are cross-validated.

**Pagination** mirrors the endpoint, not a forced convention:
- GraphQL-backed tools → native cursor pagination (`first`, `after`); return `pageInfo`
  with `endCursor` and `hasNextPage`. Never hardcode the page size numbers: splat
  `Mcp::Tools::Concerns::CursorPagination.input_schema_params(items:)` into the service's
  `input_schema`, and use its `paginated_first` in the tool.
- REST-backed tools → offset pagination (`page`, `per_page`); return `metadata` with
  `page`, `per_page`, `has_more`.

**Document intentional exceptions** in the tool proposal when a tool deliberately breaks
a convention (non-standard verb, second write tool on one resource).

## Recipe — build a new GraphQL MCP tool

0. **Confirm a tool proposal exists** (MCP Tool Proposal issue / review board — see top), and
   **build exactly what it specifies — under-ship, don't over-ship.** An MCP `input_schema` is
   versioned (`_index.md`): adding a parameter later is additive and safe, but removing one is a
   breaking change needing a new version plus multi-version support. So a param you're unsure
   about is far cheaper to add later than to remove. If the issue is project-scoped, ship
   project-scoped; capability it doesn't ask for is a separate proposal, not a bonus. Resist
   "compatibility" surface too — if this tool replaces/aliases another that still runs (see
   Renaming, tool-anatomy.md), the old tool is the compatibility path and this one need not
   absorb its parameter shape.
1. **Verify the GraphQL field exists — before writing anything.** Check that the schema
   already exposes a field covering your use case:
   - **Type file:** `app/graphql/types/<resource>_type.rb` (or `project_type.rb` /
     `group_type.rb`) — scan for the field name.
   - **Resolver:** `app/graphql/resolvers/<resource>_resolver.rb` — scan `argument`
     lines to confirm the filter args you need exist.
   - **Console fallback:** `GitlabSchema.query_type.fields.keys.grep(/keyword/)` or
     `Types::MergeRequestType.fields.keys` to list available fields at runtime. See
     **[references/graphql-api-model.md](references/graphql-api-model.md)** for more.
   - **⚠️ If the field doesn't exist: stop and alert the user.** A missing field means
     the tool isn't buildable without a schema addition — a separate MR requiring its
     own GraphQL review. Do not invent or guess field names.
2. **Copy the closest existing GraphQL tool** — tool + service + `.graphql` + specs. A
   full read example is in **[references/worked-example.md](references/worked-example.md)**.
3. **Write the operation** in GraphiQL/console until it returns what you want (variables
   for all inputs; paginate connections), then save it as a `.graphql` file per the
   rules above. **Never inline it.**
4. **Tool class:** `graphql_operation: load_graphql('<domain>/<file>.graphql')`; set
   `operation_name` to the **root field** in `register_version` — or override it as an
   instance method if the root field varies at call time (e.g. project-or-group tools —
   see `references/tool-anatomy.md`); map `params → variables` in `build_variables`;
   reshape in `process_result` if needed.
5. **Service class** (`< Base::GraphqlService`): write `input_schema` (agent-facing args
   + `required`; do **not** add `additionalProperties`), `description`, `annotations`
   (`readOnlyHint` correct — it drives pre-approval); point `graphql_tool_class` at the Tool.
6. **Agent-as-consumer review** — review name/description/schema/output as the LLM sees
   them, *before* specs. See **[references/agent-consumer-review.md](references/agent-consumer-review.md)**.
7. **Register** in `manager.rb` `GRAPHQL_TOOLS`.
8. **Update the `list_tools` specs — required, both files.** Each holds its own copy of the
   same `expected_annotations` hash, so both need the identical
   `'<tool_name>' => { 'readOnlyHint' => … }` entry under the matching comment bucket (write
   non-destructive / write destructive / read-only) — annotations only, neither file asserts
   `description` or `inputSchema`. Both also assert every service under the MCP tools tree is
   registered in `Mcp::Tools::Manager`, so they catch a skipped step 7.
   - `spec/requests/api/mcp/handlers/list_tools_spec.rb` — its annotations example is guarded
     `unless: Gitlab.ee?`.
   - `ee/spec/requests/api/mcp/handlers/list_tools_spec.rb` — unguarded, and its hash also
     lists EE-only tools.
   Only one of the two annotations examples runs in a given pipeline, so green specs never
   prove you updated both files.
9. **Unit specs** for the Tool and the Service. Lock the service `input_schema` as a
   whole with a single `expect(...).to eq({ … })` (a full version-lock, like
   `list_merge_requests_service_spec`), not property-by-property — it catches accidental
   schema drift across versions. Don't re-assert `readOnlyHint` here: the `list_tools`
   specs (step 8) already cover annotations, so a per-tool "is marked read-only" example
   is redundant. Match the sibling MCP specs' `feature_category: :mcp_server` on both files.
10. **Update user docs:** `doc/user/model_context_protocol/mcp_server_tools.md`.
11. **`bundle exec rubocop` + `bundle exec rspec`** the changed files; fix failures. Also
    run `bundle exec rspec spec/graphql/all_queries_spec.rb` — it validates your new
    `.graphql` file against `GitlabSchema`, so a bad field/arg fails here. **It does not check
    `id` selections** — a missing `id` passes rspec and only fails the `graphql-verify` eslint CI
    job (see Gotchas), which can't run locally without the schema dump. Green specs are not proof
    the query lints.

## Gotchas (learned the hard way)

- **Inline operation → RuboCop failure.** `Mcp/UseGraphqlQueryFile` rejects a
  string/HEREDOC as `graphql_operation:`; use a `.graphql` file via `load_graphql`.
- **Missing `# @feature_category:` → lint failure.** Every `.graphql` file needs it as
  the first line (`graphql_require_feature_category`).
- **`load_graphql` in a lambda rereads the file per request.** Use the direct form; a
  method + lambda is only for an operation composed at load time (EE fragments).
- **Don't hand-set `additionalProperties`.** `SchemaDefaults` applies `false`
  automatically (!243352); setting it manually is redundant and will be flagged.
- **`readOnlyHint` changes behavior, not just docs.** The pre-approved tool list is
  derived from it (!231431); a write wrongly marked `readOnlyHint: true` runs without
  confirmation.
- **`operation_name` is the root field, not the `query Name` label.** `process_result`
  digs `result.dig('data', operation_name)`. `{ project(...) { … } }` → `'project'`.
- **Unused declared variable → validation error.** Don't declare `$x` you don't reference.
- **Undeclared argument → validation error.** Only pass args the field defines (verify
  with `.arguments.keys`).
- **`iid` is a `String` in GitLab GraphQL**, not Int — `iid: "1"`.
- **Client-side post-filtering breaks pagination** — prefer a real server-side arg; if
  none exists, consider cutting the input from v1 (see references/graphql-api-model.md).
- **`position` (DiffPositionType) is null** for non-diff notes — expected.
- **Select `id` on every object type that has one — it is lint-mandated, not padding.**
  `@graphql-eslint/require-selections` (error, applies to `**/*.graphql`) requires `id` on
  `project`, `group`, connection `nodes`, `author`, etc. **`spec/graphql/all_queries_spec.rb`
  passes without them** — it only checks schema-correctness — so the *only* thing that catches a
  missing `id` is the `graphql-verify` CI job, which needs the schema dump and does not run
  locally. Never remove an `id` to "slim" a payload; a reviewer (human or agent) suggesting that
  is wrong.
- **A root `oneOf`/`anyOf` silently disables `additionalProperties: false`.** `SchemaDefaults`
  skips composition schemas (tool-anatomy.md), so expressing "exactly one of `url`/`project_id`"
  as a schema `oneOf` quietly stops unknown args being rejected. Enforce mutual exclusivity in
  Ruby instead (in `resolve_*`, raising on zero-or-many), and keep the schema composition-free so
  the strictness guard survives. State the "exactly one of" rule once in the tool `description`,
  not in each property.
- **`find_project!` / `find_group!` fold authorization in — "forbidden" and "missing" are indistinguishable.**
  `ResourceFinder#find_project!` and `#find_group!` check `Ability.allowed?` after the DB lookup.
  If the record is missing **or** the caller lacks the required ability, both raise the same
  `"'<id>' not found or inaccessible"` `StandardError`. This is intentional: a distinct
  `"Access denied"` message would let an authenticated caller enumerate private projects/groups
  by comparing error strings. Do **not** add a separate authorization check after calling these
  finders — the check is already inside them. If you need a non-default ability (e.g.
  `:read_merge_request` instead of `:read_project`), pass it as `ability:`:
  `find_project!(project_id, ability: :read_merge_request)`. The same uniform-error guarantee
  applies regardless of which ability you pass.
- **Don't hardcode a value list the schema already derives from a model.** GraphQL
  `enum`s are often generated from a model constant (e.g. `DuoWorkflowStatusGroup` is built
  from `Ai::DuoWorkflows::Workflow::GROUPED_STATUSES`). Derive your `input_schema` `enum`
  from that same constant so they stay in lock-step; a hand-copied list silently drifts and
  starts rejecting values the schema accepts. Point at the source of truth, don't duplicate
  it (same for a URL you could read off the model instead of re-templating the route).
- **When you alias/replace another tool, read its real source, not the catalog blurb.** Catalog
  and doc descriptions drift (a tool documented as "project or group" was project-only in code).
  Open the actual tool definition to learn its true parameters and scope. And a `tool_aliases`
  entry only helps clients that had the *old name advertised by the MCP server* — if the tool
  you're replacing lives elsewhere (e.g. a Duo Workflow Python tool that was never MCP-served),
  no MCP client cached the old name, and if it still runs it remains the compatibility path.
  Don't claim the alias "protects cached clients" without confirming the old name was ours.
- **Where you declare an alias depends on the tool type.** Custom, GraphQL, and aggregated tools
  override `self.tool_aliases` on the class. API tools (`route_setting :mcp`) set `tool_aliases:` in
  the route settings instead — the class override does nothing for them, since one `ApiTool` class
  backs every route. `tool_aliases:` on a route that also sets `aggregators:` is ignored; alias that
  tool through the aggregator class's `self.tool_aliases`.
- **Add the tool to the built-in catalog only if a custom agent would use it.** Registering in
  `manager.rb` already exposes the tool to **agentic chat** (`Ai::DuoWorkflows::McpConfigService`
  injects the GitLab MCP server's tools). The extra entry in
  `ee/lib/ai/catalog/built_in_tool_definitions.rb` — plus an `Ai::ToolRules::Registry`
  privilege-group mapping, or it's silently ungovernable — is what lets a **custom AI Catalog
  agent** select the tool. So ask: *would someone building a custom agent want to grant this
  tool?* Yes → add it; no → don't. Omitting is safe (adding an entry later is additive), whereas
  removing one is a **breaking change**: custom agent definitions store the tool's catalog `id`
  (`BuiltInTool.where(id: tool_ids)`), so removal makes those stored references silently dangle —
  the same expand-safe / contract-breaking asymmetry as an `input_schema` param. When unsure,
  omit and revisit; it's ultimately a proposal / review-board call.

## Testing locally (easy loop)

**Prove it with a real `tools/list` + `tools/call` round trip, not just specs.** A spec run
confirms the classes wire up; it does not confirm the tool is advertised or that a call returns
what you promised. Restart the app first (`gdk restart rails-web`) so the new tool registers —
`Manager` memoizes `GRAPHQL_TOOLS`.

- **Request spec** (canonical): pattern in `spec/requests/api/mcp/handlers/call_tool_spec.rb`.
- **Don't hardcode the GDK URL, and don't assume port 3000.** Puma may bind a UNIX socket
  (`config/puma.rb`), so `127.0.0.1:3000` can be refused; the app is reachable through nginx at
  whatever `Gitlab.config.gitlab.url` reports (e.g. `https://gdk.test:3443`). Derive it.
- **A `rails runner` script is the most reliable driver.** `curl` to `gdk.test` may hit a
  permission prompt, and a runner script also gives you DB access to pick fixtures inline. Real
  HTTP, self-signed cert, URL derived:
  ```ruby
  require 'net/http'; require 'json'
  base  = URI("#{Gitlab.config.gitlab.url}/api/v4/mcp")
  token = User.find_by_username('root').personal_access_tokens.create!(
    name: 'mcp-verify', scopes: [:api, :mcp], expires_at: 7.days.from_now)
  token.set_token('someknownvalue'); token.save! # token.revoke! when done
  def rpc(base, tok, body)
    req = Net::HTTP::Post.new(base)
    req['Authorization'] = "Bearer #{tok}"; req['Content-Type'] = 'application/json'
    req.body = body.merge(jsonrpc: '2.0', id: 1).to_json
    opts = { use_ssl: base.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE }
    JSON.parse(Net::HTTP.start(base.hostname, base.port, **opts) { |h| h.request(req) }.body)
  end
  # rpc(base, 'someknownvalue', { method: 'tools/list' })
  # rpc(base, 'someknownvalue', { method: 'tools/call', params: { name: '<tool>', arguments: {...} } })
  ```
  Check `tools/list` for registration + the schema the model actually sees; check `tools/call`
  for the result shape, and confirm removed/invalid args are rejected. Measuring the advertised
  JSON (`{name, description, inputSchema}.to_json.length`) against the other tools' is a cheap way
  to catch a bloated schema — `tools/list` is paid once per session for every tool.
- **`curl`** works too if unblocked: `POST {url}/api/v4/mcp -k -H "Authorization: Bearer <PAT>"`
  with the same JSON-RPC body.
- **MCP Inspector:** `npx @modelcontextprotocol/inspector` → Streamable HTTP → the
  endpoint + bearer header. 
-  **Claude Code:** `claude mcp add --transport http gitlab-gdk <url> --header "Authorization: Bearer <PAT>"`.
- **Console:** introspect the GraphQL query directly with `GitlabSchema.execute(...)`.

## References

| Topic | Location |
|---|---|
| Two-class field-by-field detail, naming, mapping, mutation deltas | [references/tool-anatomy.md](references/tool-anatomy.md) |
| How the GraphQL API is built + how to discover it (introspection) | [references/graphql-api-model.md](references/graphql-api-model.md) |
| Full worked read example (`get_merge_request_notes`) | [references/worked-example.md](references/worked-example.md) |
| Agent-as-consumer review checklist | [references/agent-consumer-review.md](references/agent-consumer-review.md) |
| Canonical dev docs | `doc/development/duo_agent_platform/mcp/{_index,graphql_integration}.md` |
| Framework classes | `app/services/mcp/tools/graphql_tool.rb`, `.../base/graphql_service.rb`, `.../manager.rb` |
| Concerns | `app/services/mcp/tools/concerns/{resource_finder,url_parser,content_validation,constants}.rb` |
| Closest read / write templates | `.../merge_requests/get_merge_request_notes_{tool,service}.rb` / `create_merge_request_note_{tool,service}.rb` |
| Project-or-group tool template | `.../labels/search_{tool,service}.rb` + `app/graphql/queries/mcp/labels/search.query.graphql` |
| RuboCop rule forbidding inline operations | `rubocop/cop/mcp/use_graphql_query_file.rb` |
