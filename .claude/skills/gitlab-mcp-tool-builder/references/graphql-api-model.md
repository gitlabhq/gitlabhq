# GitLab's GraphQL API — how it's built and how to discover it

Read this when you're navigating an unfamiliar part of the schema and need to know
how the API is constructed in code, or how to introspect it. The API lives entirely
under `app/graphql/` (+ `ee/app/graphql/`). That tree *is* the API.

## How the API is constructed in code

### One endpoint, two roots
- HTTP: a single endpoint, `POST /api/graphql` (note: **not** `/api/v4`).
- Two entry points: **`Query`** (`types/query_type.rb`, all reads) and **`Mutation`**
  (`types/mutation_type.rb`, all writes, mounted with `scopes:`).
- Everything else is reached by **traversing types** from a root. A field's return
  type has its own fields; you walk down a tree.

### Where code lives + the naming convention
| GraphQL thing | Ruby class | File |
|---|---|---|
| Type `Foo` | `Types::…::FooType` (add `Type`) | `types/.../foo_type.rb` |
| Field on a type | `field :name` in that type's file | same file (or a `resolver:`) |
| Resolver `Resolvers::X` | — | `resolvers/.../x.rb` |
| Mutation `fooBar` | `graphql_name 'FooBar'` | `mutations/...` (mounted in `mutation_type.rb`) |
| Enum `FooType` (GraphQL) | `…FooTypeEnum` (add `Enum`) | `types/.../foo_type_enum.rb` |
- The **schema name drops the `Type` suffix**: class `Types::Notes::DiscussionType`
  → registry key `'Discussion'`. So `GitlabSchema.types['Discussion']`, NOT `'DiscussionType'`.

### Interfaces — shared field sets (`implements`)
- A type writes `implements Types::Notes::NoteableInterface` to gain all the
  interface's fields. Mechanically ≈ Ruby `include` (interfaces *are* modules): it
  mixes in both field declarations and instance methods.
- This is **why a type has fields that aren't in its own file.** e.g. `MergeRequest`
  has `notes`/`discussions`/`commenters` only because `MergeRequestType implements
  NoteableInterface`. Issue/Snippet/Epic/Commit/etc. all opt in the same way.

### Three ways a field resolves (in priority)
1. `field :x, resolver: Resolvers::…` → a dedicated resolver class.
2. a `def x` method on the type → that method.
3. **neither → default: call `object.x`** (a method on the underlying model).
- Example, all three on `NoteableInterface`: `notes` (resolver), `commenters` (type
  method), `discussions` (default → `model.discussions` via `include Noteable`).
- Resolvers stay thin and delegate to a **Finder** (e.g. `MergeRequestsFinder`,
  `NotesFinder`); the Finder is what truly hits the DB, run as `current_user`.

### GraphQL resolves field-by-field, top-down
There is no single mega-query. Each field resolves on its own, and its resolved
value becomes the parent object for nested fields:
```
project(fullPath:) → Project  →  mergeRequest(iid:) → MergeRequest
                              →  discussions → [Discussion]  →  notes → [Note]
```
You only write the **selection set** (what you want); the engine dispatches each hop
to its resolver/method. You never call resolvers yourself.

### Connections & pagination (the Relay list pattern)
- Any field whose type ends in `Connection` is a list. You **must** select
  `nodes { … }` (and optionally `pageInfo { hasNextPage endCursor }` / `count`).
- Connections accept `first/after` (forward) and `last/before` (backward), capped by
  a server-side `max_page_size`. **Paginate** — never assume "fetch all."

### Identifiers: `iid` vs global id (why you go through `project`)
- **`iid`** (the `!1`/`#1` in URLs) is **unique only within a project/group**. So you
  cannot fetch by iid at the root — you scope through the parent:
  `project(fullPath:) { mergeRequest(iid:) }`. This is the idiomatic containment shape.
- **global id** (`gid://gitlab/MergeRequest/123`) is system-wide unique; root fields
  that take `id:` use it (e.g. `Query.mergeRequest(id:)`).
- For **reads** by iid, going through the parent needs no global-id resolution. For
  **writes**, mutations like `createNote` need the target's global `id` (`noteableId`),
  so you fetch/convert it.

### Authorization & scopes (important MCP nuance)
- Object access is gated by **abilities**: `authorize :read_x` on types/resolvers/
  mutations + in-resolver `Ability.allowed?`. Enforced against `current_user` — so
  your tool inherits the caller's permissions automatically. **Don't re-check perms.**
- Field/type **`scopes:`** (e.g. `ai_workflows`) are enforced ONLY when
  `context[:scope_validator]` is present — which the HTTP controller sets from the
  token, but the **MCP `GraphqlTool` execution context does NOT** (`scopes_ok?`
  returns true when no validator). So `scopes:`/`ai_workflows` **do not gate MCP tool
  execution** today; only abilities do. (Forward caveat: true only while MCP omits
  the scope_validator.)

### Arguments are a field's contract
- You may pass **only the arguments a field declares**. Passing an undeclared arg
  (`discussions(id:)`, `notes(system:)`) is a hard schema-validation error.
- Likewise every **declared variable must be used**, or the query fails validation.
- Before writing `field(arg: $x)`, verify: `…fields['field'].arguments.keys`.

### Prefer server-side args over client-side filtering
- If a needed filter exists as a real argument (e.g. `notes(filter: ONLY_COMMENTS)`),
  use it. **Client-side post-filtering breaks pagination** — the page boundary is
  applied before your filter, so a page of N can return far fewer items, and "next
  page" is meaningless. Only post-filter when the API offers no server-side arg.

## How to discover the API (never guess)

**Rails console introspection (fastest, reflects your branch):**
```ruby
GitlabSchema.query.fields.keys.sort                       # all top-level reads
GitlabSchema.mutation.fields.keys.grep(/note/i)           # find a mutation
GitlabSchema.types['MergeRequest'].fields.keys            # fields on a type
GitlabSchema.types['MergeRequest'].fields['notes'].arguments.keys          # can I pass this arg?
GitlabSchema.types['X'].fields['y'].arguments.transform_values { |a| a.type.to_type_signature }  # arg types + required(!)
GitlabSchema.types['MergeRequest'].fields['discussions'].type.unwrap        # walk to a return type (strips NonNull/List)
GitlabSchema.types['SomeEnum'].values.keys                # enum values
Object.const_source_location("Types::Notes::DiscussionType")               # jump to the file:line
```
- A field's inspect string names where it's defined, e.g.
  `#<Types::BaseField NoteableInterface.discussions(...)>` → defined on `NoteableInterface`.

**Reference docs:** `doc/api/graphql/reference/_index.md` (committed, greppable) or
<https://docs.gitlab.com/api/graphql/reference/>. **GraphiQL:** `/-/graphql-explorer`
(autocomplete + docs sidebar). **grep:** `rg "field :discussions" app/graphql ee/app/graphql`.
