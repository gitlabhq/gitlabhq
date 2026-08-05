# Gitlab::PolicyStore

The storage-agnostic management layer for GitLab security policies (the "Policy
Store"), distinct from the stateless Policy Engine that evaluates them.

Callers use a single public facade (`Gitlab::PolicyStore`) and never
touch persistence directly. All storage goes through an injectable repository
port (`Gitlab::PolicyStore::Ports::PolicyRepository`), so the
in-monolith backend used today can be swapped for a remote service later without
changing any caller.

```
Facade  →  Port (interface)  →  Adapter (in-memory today, remote later)
```

The facade returns `Gitlab::PolicyStore::Policy` value objects, so no
persistence object ever crosses the component boundary.

## Usage

```ruby
# Create a new policy
policy = Gitlab::PolicyStore.create(
  organization_id: 1,
  name: "My approval policy",
  trigger_id: "merge_request",
  rules: { rules: [{ type: "scan_finding" }] },
  actions: [{ type: "require_approval" }],
  policy_scope: { compliance_frameworks: [{ id: 5 }] },
  mode: "audit"
)

# Find a policy by ID
Gitlab::PolicyStore.find(policy.id)

# List all policies for an organization
Gitlab::PolicyStore.list(organization_id: 1)

# Delete a policy
Gitlab::PolicyStore.delete(policy.id)
```

Swap the storage backend by injecting a different repository:

```ruby
Gitlab::PolicyStore.configure do |config|
  config.repository = MyRemotePolicyRepository.new
end
```

## Scope compilation

A policy's scope is authored one of two ways:

- **Structured data in `policy_scope`**: on create,
  `Gitlab::PolicyStore::ScopeTranspiler` compiles it into `scope_rego`.
- **Rego supplied directly in `scope_rego`**: stored as authored, which always wins
  over compilation.

A policy with neither compiles to a program that applies everywhere, so `scope_rego`
is never blank after create.

```ruby
Gitlab::PolicyStore.create(
  organization_id: 1, name: "Framework 5 only", trigger_id: "deployment_requested",
  policy_scope: { compliance_frameworks: [{ id: 5 }] }
).scope_rego
# => "package gitlab.scope\n\nimport rego.v1\n\n..."
```

The generated program is `package gitlab.scope`, per
[GOVERN-006: Policy scope as Rego and quick-check strategy](https://gitlab.com/gitlab-org/architecture/govern/design-doc/-/blob/main/decisions/006-policy-scope-rego-quick-check.md).
The gem compiles it. Evaluating a program against a project is the engine's job.

## Repository Contract

Any storage adapter must implement the `Gitlab::PolicyStore::Ports::PolicyRepository`
interface:

- `#create(attributes)` - Creates a new policy, returns a `Policy` value object
- `#find(id)` - Returns a `Policy` by ID, raises `NotFound` if not found
- `#delete(id)` - Deletes a policy by ID, raises `NotFound` if not found
- `#list(organization_id:)` - Returns all policies for an organization
