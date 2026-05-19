---
source_checksum: 3781faa9a252febf
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/backend-ruby.md - it contains foundational rules that apply to all backend work.

# Backend Architecture Principles

## Checklist

### Abstraction Layer Usage

- DO NOT use high-level Finder classes (e.g., `ProjectsFinder`) inside other Finders; use the underlying query primitives directly
- DO NOT call `ActiveRecord` methods (e.g., `where`, `find_by`) directly from controllers, API endpoints, service classes, finders, presenters, or serializers — only from model class/instance methods
- DO NOT use Presenters or Serializers inside Service classes
- DO NOT use Service classes, Presenters, Serializers, or Workers inside Finders
- DO NOT use service classes, presenters, or serializers inside model class/instance methods
- DO NOT invoke a Worker directly with `SomeWorker.new.perform`; use `SomeWorker.perform_async` or `SomeWorker.perform_in`
- DO NOT execute database queries in views; move all data retrieval into the controller or a presenter and pass the result as an instance variable
- DO NOT put business logic in views; extract conditionals that evaluate model state beyond `nil?`, `present?`, or boolean attribute checks into a helper, presenter, or ViewComponent
- Use the abstraction table to verify that each layer only calls permitted abstractions before approving cross-layer calls

### Service Classes

- Ensure service class initializer takes the acted-upon model as the first positional argument
- Ensure service classes that act on behalf of a user include `current_user:` as a keyword argument
- Ensure the `#execute` method takes no arguments (all data passed via initializer)
- Ensure `#execute` returns a `ServiceResponse` object when a return value is needed
- Use `ServiceResponse.success` / `ServiceResponse.error` with a `message:` and optional `payload:` or `reason:`
- Use domain-specific `reason:` symbols in `ServiceResponse.error` (e.g., `:job_not_retriable`, `:duplicate_package`); use Rails HTTP status symbols only for common failures like `:not_found` or `:forbidden`
- Inherit from `BaseContainerService`, `BaseProjectService`, or `BaseGroupService` where appropriate
- DO NOT put business logic that changes application state in objects that are not service classes (use finders or value objects for read-only operations)

### Finders

- Ensure finder `#execute` methods return `ActiveRecord::Relation`; add exceptions to `spec/support/finder_collection_allowlist.yml` only when necessary
- DO NOT reuse other finders inside a finder

### Naming and Ubiquitous Language

- Use ubiquitous language from the product/user documentation instead of CRUD terminology when naming service classes and domain objects (e.g., `Epic::AddExistingIssueService` not `EpicIssues::CreateService`)
- Use CRUD names only when they match the existing ubiquitous language and are unambiguous (e.g., `Projects::CreateService`)
- Ensure new classes and database tables use ubiquitous language; use `self.table_name=` when model name diverges from table name

### Bounded Contexts and Namespaces

- Ensure every Ruby class is nested inside a top-level namespace present in `config/bounded_contexts.yml`; resolve `Gitlab/BoundedContexts` RuboCop offenses by nesting into an existing context
- DO NOT nest feature-specific classes under `Projects::` or `Groups::` namespaces unless the concept is strictly about projects or groups themselves
- DO NOT use stage or group names as bounded context namespaces (feature categories can be reassigned)
- Define event classes and publish events within the same bounded context (top-level Ruby namespace) where the triggering feature lives
- Place FOSS event subscriptions in `lib/gitlab/bounded_contexts/subscriptions/[context]_subscriptions.rb`; EE-only in `ee/lib/gitlab/event_store/subscriptions/[context]_subscriptions.rb`

### Omniscient Classes

- DO NOT add new methods or data to omniscient classes (`Project`, `User`, `MergeRequest`, `Ci::Pipeline`, or any class >1000 LOC); create a dedicated class instead
- Prefer thin domain wrapper objects (e.g., `AntiAbuse::UserTrustScore.new(user)`) over adding methods to large models
- Use dependency inversion to encapsulate related behavior in a bounded context rather than adding it to a shared model

### Use-Case-Oriented Design

- DO NOT reuse a single service class for radically different use cases with different permissions, preconditions, or side-effects; create separate service classes per use case
- Ensure each service class enforces a single, cohesive set of permissions and parameters

### EventStore

- Name events in past tense: `<DomainObject><Action>Event` (e.g., `Ci::PipelineCreatedEvent`, not `Ci::CreatePipelineEvent`); elide the domain object when obvious from the bounded context (e.g., `MergeRequest::ApprovedEvent` not `MergeRequest::MergeRequestApprovedEvent`)
- Define event schemas as valid JSON Schema; mark unique identifiers as `required` and all other properties as optional
- Publish only properties needed by subscribers; DO NOT tailor the payload to a specific subscriber
- Dispatch events from service classes; use model state machine transitions as an exception, not `ActiveRecord` callbacks
- DO NOT publish events about domain objects outside your bounded context
- Introduce new Sidekiq subscriber workers in a prior deployment (or behind a feature flag) before registering the subscription
- Use conditional dispatch (`if:` lambda) only for cheap synchronous checks; handle complex conditions inside `handle_event`
- Follow the multi-rollout process when renaming events, adding required properties, or removing properties (expand → migrate → contract across separate milestones)
- Use `publish_event` RSpec matcher to test publishers; use `it_behaves_like 'subscribes to event'` shared example to test subscribers
- Define CE events and publish them in CE code; define EE events and publish them in EE code; subscribers may cross CE/EE boundaries

### Modules and Instance Variables

- DO NOT share instance variables across multiple mixed-in modules; keep instance variables contained within the module that owns them
- Prefer the `@var ||= value` single-assignment pattern when memoizing in a module
- DO NOT use instance variables in view partials; pass locals explicitly and fetch with `local_assigns.fetch(:key)`

### Abstract Methods

- Use `Gitlab::AbstractMethodError` (not `NotImplementedError`, `NoMethodError`, or a generic string `raise`) for abstract methods that subclasses must implement
- Prefer composition and duck typing over inheritance; use abstract methods only for framework integration points or shared-template components (e.g., ViewComponents)

### Application Limits

- Add new plan limits as a column in `plan_limits` with a non-null default, then fine-tune per plan using `create_or_update_plan_limit` in a separate migration
- Cover all GitLab.com plans (`default`, `free`, `premium`, `premium_trial`, `ultimate`, `ultimate_trial`, `ultimate_trial_paid_customer`, `opensource`) in limit migrations; omitting a plan causes those customers to receive the default (possibly `0`/unlimited)
- Use `PlanLimits#exceeded?` or the `Limitable` concern to enforce limits; DO NOT implement ad-hoc count checks
- Use `Rack::Attack` for middleware-level rate limiting and `Gitlab::ApplicationRateLimiter` for controller/API-level throttling

### Backwards Compatibility Across Updates

- Follow the expand-and-contract pattern for breaking changes: expand (backward-compatible addition) → migrate (update consumers) → contract (remove old code) across separate milestones
- DO NOT bundle expand and migrate phases into the same milestone for Sidekiq worker parameter changes (Puma may restart before Sidekiq, causing job failures)
- Ensure new GraphQL fields or REST API fields added in release N are not used by frontend code until release N+1 (or are behind a default-disabled feature flag, or degrade gracefully)
- DO NOT add a `NOT NULL` column constraint without a default value when old application nodes are still inserting rows without that column
- Ensure route changes follow expand-and-contract: add new route first, then generate new-format links, then remove old route

### CE/EE Code Separation

- CE code (outside `ee/`) must not directly reference `EE::` namespaced classes
- EE extensions use `prepend_mod` pattern in CE files
- If CE code needs EE-aware behavior, use `prepend_mod` hooks or `Gitlab.ee?` guards
- Flag direct references to `EE::` namespaced classes in CE code (prevents FOSS build failures)

### ActiveRecord Callbacks

- Callbacks should only modify data on the current model, not associated records
- Question if callback logic should be in a service layer instead
- Flag callbacks with side effects (external API calls, updating other records, complex business logic)
- Flag bulk operations on associated records in callbacks (performance concern as associations grow)
- Acceptable uses: data normalization on current model only (trimming whitespace, setting defaults)

### Authorization

- Before changing authorization logic, read the existing `authorize!` / `authorize_admin!` call and verify what permission it currently enforces; the required fix may be documentation- or test-only with no code change needed

## Authoritative sources

For the full picture, see:

- doc/development/reusing_abstractions.md
- doc/development/software_design.md
- doc/development/event_store.md
- doc/development/module_with_instance_variables.md
- doc/development/application_limits.md
- doc/development/multi_version_compatibility.md

