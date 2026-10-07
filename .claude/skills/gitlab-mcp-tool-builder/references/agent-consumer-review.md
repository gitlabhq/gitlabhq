# Agent-as-consumer review — does the tool call make sense to the LLM?

Run this **before writing specs** (recipe step 6), so the contract is right first.
The agent never sees your Ruby — it sees only what `tools/list` exposes: the **name**,
**description**, **input_schema**, and **annotations**, plus whatever the call
**returns**. Pull that real contract (`tools/list` via curl / MCP Inspector — see the
"Testing locally" section in `SKILL.md`) and review the tool from that vantage point
only. Better yet: hand the contract to a fresh agent and ask it to use the tool for a
realistic user request — watch where it hesitates or guesses.

Three questions the agent must answer **from the contract alone**:

1. **When do I call this?** — *name + description*
   - Name is `verb_object`, consistent with siblings (`get_merge_request`), no
     internal jargon.
   - Description says *what it does* **and** *when to use it*, and disambiguates from
     near-neighbors (MR notes vs work-item notes). One or two sentences; no
     implementation leakage (no `GitlabSchema`, no class names). No trailing full stop.

2. **What do I pass?** — *input_schema*
   - Param names are domain terms an agent can fill from a user request (`project_id`,
     `merge_request_iid`), **not** internal GraphQL names (`fullPath`, `iid`, gids).
   - `required[]` is exactly the args with no sensible default.
   - Every property has a description with **format + example** when not obvious
     (`gid://gitlab/Discussion/<id>`; "ID or full path, e.g. `gitlab-org/gitlab`").
   - Constrained values use `enum`; bounded numbers use `minimum`/`maximum`.
   - The agent should never learn a format or limit by failing a call first.

3. **Can I use the result?** — *return shape + errors*
   - Output is structured and predictable, and carries what the *next* step needs:
     ids to act on, `pageInfo` to paginate, counts for an at-a-glance answer.
   - Errors return a legible `Response.error("…")` the agent can act on (not a raw
     exception/stack trace) — including not-found and permission-denied.
   - Every error passes a `reason:` when the tool knows why it failed (`:bad_request`,
     `:unauthorized`, `:not_found`; `:error` is the default). It is stripped before the
     agent sees the response and only sets `tool_status` in `mcp.log`. See
     [Categorizing tool errors](../../../../doc/development/duo_agent_platform/mcp/_index.md#categorizing-tool-errors).
   - If your tool wraps or aggregates another tool, forward the inner result's reason
     (`Response.error_reason`) rather than building an error without one. A route-backed inner
     tool's reason comes from the HTTP status, so when you match a known refusal and replace its
     message, give that table entry its own reason and read it with `fetch`.
   - It isn't needlessly verbose: every returned field costs the agent tokens, so drop
     what it won't use.
   - **Don't silently truncate or transform a returned value.** If you shorten a field (a
     goal/description preview, a capped patch), the agent can't tell a preview from the
     whole value — either return it whole or signal the cut (a flag, a trailing `…`, or a
     documented limit in the field description). `get_commit` surfaces `collapsed`/`tooLarge`
     on diffs for exactly this reason.

**Description/schema length is a per-session tax, not a per-call one.** `tools/list` is
sent once per session for *every* registered tool, called or not — so a bloated schema
here is paid by every agent always. Keep it tight: don't repeat a rule verbatim across
several property descriptions (state a shared rule like "exactly one of …" once, in the
tool `description`, where the model reads it while *choosing* the tool); don't restate
what the schema already encodes (type, `enum` values, `minimum`/`maximum`, defaults);
cut migration/history prose (that belongs in the code comment and user docs). A quick
check: serialize `{name, description, inputSchema}` for your tool and the neighbours and
compare — an outlier usually means duplication, not necessary detail.

**Chainability:** can the agent get your *inputs* from a prior tool's *output*, and
does your *output* hand off to the likely next call? (e.g. returning `discussion.id`
so a follow-up `save_note` can reply to that thread.)

If your output or error text names another tool for the agent to call next, check that
tool is actually advertised. Being registered in `Mcp::Tools::Manager` is not enough:
a tool can override `unlisted?` to be hidden from `tools/list`, so it stays callable
but the agent never discovers it. Tools pending removal are unlisted this way, often
because an `include` facet on a `get_` tool replaced them, so point to the facet. A
GitLab web URL is also a poor hand-off, because the page needs a browser sign-in and
loads its content with JavaScript; point to a tool instead (a URL for humans alongside
is fine).

To check, list every unlisted tool:

```shell
rg -l 'def unlisted\?' app/services/mcp/tools ee/app/services/mcp/tools --glob '!**/base/**'
```

If the tool you name is in that list, read the comment above its override, which names the
replacement. For example, `get_merge_request_notes_service.rb` says it is "superseded by the
get_merge_request notes facet", so the hand-off becomes `get_merge_request` with
`include: ["notes"]`, not `get_merge_request_notes`.

**Current-user references:** if the tool finds resources belonging to "me" (e.g. "my
open MRs", "MRs awaiting my review"), prefer a **server-side `scope` enum** resolved
from `current_user` (`created_by_me` / `assigned_to_me` / `review_requested`), mapped
onto the underlying person filters in `build_variables`. The agent genuinely cannot
know the caller's username, so making it supply one forces a lookup round trip or a
wrong guess; resolving server-side removes both. Explain the mapping in the `scope`
description, since the agent can't infer which filter each value drives, and note that
an explicit username wins **for its own field** (so `scope` and an explicit filter for a
*different* field combine rather than one overriding the other). Fall back to asking the
agent for an explicit username only when there is no `current_user`-backed path.
(`list_merge_requests` is the reference for this pattern.)

**Smell tests** — each maps to a fix:
- You had to read the code to know what an arg means → the description is missing.
- A field is named after DB/GraphQL internals → rename to the agent's vocabulary.
- The agent must call it twice to learn pagination/format → encode it in the schema.
- A filter parameter and the field it returns use different words for one concept (filter
  `status` but the response field is `statusName`; `include: ["comments"]` but the cursor is
  `comments_after` and the result key is `notes`) → the agent can't line up request with
  response. Pick one vocabulary and use it for the param, its cursor, and the returned field.
  Watch for a *value* mismatch too: if `status` filters by status **group** but the returned
  `status` is the granular value, name the param `status_group` so request and response agree.
- Annotations lie (a write marked `readOnlyHint: true`) → worse than cosmetic: the
  pre-approved tool list is derived from `readOnlyHint` (!231431), so the write runs
  without confirmation.
