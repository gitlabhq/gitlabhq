---
stage: none
group: Engineering Productivity
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Software design guides
---

## Use ubiquitous language instead of CRUD terminology

The code should use the same [ubiquitous language](https://handbook.gitlab.com/handbook/communication/#ubiquitous-language)
as used in the product and user documentation. Failure to use ubiquitous language correctly
can be a major cause of confusion for contributors and customers when there is constant translation
or use of multiple terms.
This also goes against our [communication strategy](https://handbook.gitlab.com/handbook/communication/#mecefu-terms).

In the example below, [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete)
terminology introduces ambiguity. The name says we are creating an `epic_issues`
association record, but we are adding an existing issue to an epic. The name `epic_issues`,
used from Rails convention, leaks to higher abstractions such as service objects.
The code speaks the framework jargon rather than ubiquitous language.

```ruby
# Bad
EpicIssues::CreateService
```

Using ubiquitous language makes the code clear and doesn't introduce any
cognitive load to a reader trying to translate the framework jargon.

```ruby
# Good
Epic::AddExistingIssueService
```

You can use CRUD when representing simple concepts that are not ambiguous,
like creating a project, and when matching the existing ubiquitous language.

```ruby
# OK: Matches the product language.
Projects::CreateService
```

New classes and database tables should use ubiquitous language. In this case the model name
and table name follow the Rails convention.

Existing classes that don't follow ubiquitous language should be renamed, when possible.
Some low level abstractions such as the database tables don't need to be renamed.
For example, use `self.table_name=` when the model name diverges from the table name.

We can allow exceptions only when renaming is challenging. For example, when the naming is used
for STI, exposed to the user, or if it would be a breaking change.

## Bounded contexts

See the [Bounded Contexts working group](https://handbook.gitlab.com/handbook/company/working-groups/bounded-contexts/) and
[GitLab Modular Monolith design document](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/modular_monolith/) for more context on the
goals, motivations, and direction related to Bounded Contexts.

### Use namespaces to define bounded contexts

A healthy application is divided into macro and sub components that represent the bounded contexts at play.
As GitLab code has so many features and components, it's hard to see what contexts are involved.
These components can be related to business domain or infrastructure code.

We should expect any class to be defined inside a module/namespace that represents the contexts where it operates.
We maintain a [list of allowed namespaces](#how-to-define-bounded-contexts) to define these contexts.

When we namespace classes inside their domain:

- Similar terminology becomes unambiguous as the domain clarifies the meaning:
  For example, `MergeRequests::Diff` and `Notes::Diff`.
- Top-level namespaces could be associated to one or more groups identified as domain experts.
- We can better identify the interactions and coupling between components.
  For example, several classes inside `MergeRequests::` domain interact more with `Ci::`
  domain and less with `Import::`.

```ruby
# bad
class JobArtifact ... end

# good
module Ci
  class JobArtifact ... end
end
```

### How to define bounded contexts

Allowed bounded contexts are defined in `config/bounded_contexts.yml` which contains namespaces for the
domain layer and infrastructure layer.

For **domain layer** we refer to:

1. Code in `app`, excluding the **application adapters** (controllers, API endpoints and views).
1. Code in `lib` that specifically relates to domain logic.

This includes `ActiveRecord` models, service objects, workers, and domain-specific Plain Old Ruby Objects.

For now we exclude application adapters from the modularization in order to keep the effort smaller and because
a given endpoint don't always match to a single domain (e.g. settings, merge request view, project view, etc.).

For **infrastructure layer** we refer to code in `lib` that is for generic purposes, not containing GitLab business concepts,
and that could be extracted into Ruby gems.

A good guideline for naming a top-level namespace (bounded context) is to use the related
[feature category](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/categories.yml).
For example, `Continuous Integration` feature category maps to `Ci::` namespace.

Projects and Groups are generally container concepts because they identify tenants.
While features exist at the project or group level, like repositories or runners, we must not nest such features
under `Projects::` or `Groups::` but under their relative bounded context.

`Projects::` and `Groups::` namespaces should be used only for concepts that are strictly related to them:
for example `Project::CreateService` or `Groups::TransferService`.

For controllers we allow `app/controllers/projects` and `app/controllers/groups` to be exceptions, also because
bounded contexts are not applied to application layer.
We use this convention to indicate the scope of a given web endpoint.

Do not use the [stage or group name](https://handbook.gitlab.com/handbook/product/categories/#devops-stages)
because a feature category could be reassigned to a different group in the future.

```ruby
# bad
module Create
  class Commit ... end
end

# good
module Repositories
  class Commit ... end
end
```

On the other hand, a feature category may sometimes be too granular. Features tend to be
treated differently according to Product and Marketing, while they may share a lot of
domain models and behavior under the hood. In this case, having too many bounded contexts
could make them shallow and more coupled with other contexts.

Bounded contexts (or top-level namespaces) can be seen as macro-components in the overall app.
Good bounded contexts should be [deep](https://medium.com/@nakabonne/depth-of-module-f62dac3c2fdb)
so consider having nested namespaces to further break down complex parts of the domain.
For example, `Ci::Config::`.

For example, instead of having separate and granular bounded contexts like: `ContainerScanning::`,
`ContainerHostSecurity::`, `ContainerNetworkSecurity::`, we could have:

```ruby
module Security::Container
  module Scanning ... end

  module NetworkSecurity ... end

  module HostSecurity ... end
end
```

If classes that are defined into a namespace have a lot in common with classes in other namespaces,
chances are that these two namespaces are part of the same bounded context.

### How to resolve GitLab/BoundedContexts RuboCop offenses

The `Gitlab/BoundedContexts` RuboCop cop ensures that every Ruby class or module is nested inside a
top-level Ruby namespace existing in [`config/bounded_contexts.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/bounded_contexts.yml).

Offenses should be resolved by nesting the constant inside an existing bounded context namespace.

- Search in `config/bounded_contexts.yml` for namespaces that more closely relate to the feature,
  for example by matching the feature category.
- If needed, use sub-namespaces to further nest the constant inside the namespace.
  For example: `Repositories::Mirrors::SyncService`.
- Create follow-up issues to move the existing related code into the same namespace.

In exceptional cases, we may need to add a new bounded context to the list. This can be done if:

- We are introducing a new product category that does not align with any existing bounded contexts.
- We are extracting a bounded context out of an existing one because it's too large and we want to decouple the two.

### GitLab/BoundedContexts and `config/bounded_contexts.yml` FAQ

1. **Is there ever a situation where the cop should be disabled?**

   - The cop **should not** be disabled but it **could** be disabled temporarily if the offending class or module is part
     of a cluster of classes that should otherwise be moved all together.
     In this case you could disable the cop and create a follow-up issue to move all the classes at once.

1. **Is there a suggested timeline to get all of the existing code refactored into compliance?**

   - We do not have a timeline defined but the quicker we consolidate code the more consistent it becomes.

1. **Do the bounded contexts apply for existing Sidekiq workers?**

   - Existing workers would be already in the RuboCop TODO file so they do not raise offenses. However, they should
     also be moved into the bounded context whenever possible.
     Follow the Sidekiq [renaming worker](sidekiq/compatibility_across_updates.md#renaming-worker-classes) guide.

1. **We are renaming a feature category and the `config/bounded_contexts.yml` references that. Is it safe to update?**

   - Yes the file only expects that the feature categories mapped to bounded contexts are defined in `config/feature_categories.yml`
     and nothing specifically depends on these values. This mapping is primarily for contributors to understand where features
     may be living in the codebase.

## Distinguish domain code from generic code

The [guidelines above](#use-namespaces-to-define-bounded-contexts) refer primarily to the domain code.
For domain code we should put Ruby classes under a namespace that represents a given bounded context
(a cohesive set of features and capabilities).

The domain code is unique to GitLab product. It describes the business logic, policies and data.
This code should live in the GitLab repository. The domain code is split between `app/` and `lib/`
primarily.

In an application codebase there is also generic code that allows to perform more infrastructure level
actions. This can be loggers, instrumentation, clients for datastores like Redis, database utilities, etc.

Although vital for an application to run, generic code doesn't describe any business logic that is
unique to GitLab product. It could be rewritten or replaced by off-the-shelf solutions without impacting
the business logic.
This means that generic code should be separate from the domain code.

Today a lot of the generic code lives in `lib/` but it's mixed with domain code.
We should extract gems into `gems/` directory instead, as described in our [Gems development guidelines](gems.md).

## Taming Omniscient classes

We must consider not adding new data and behavior to [omniscient classes](https://en.wikipedia.org/wiki/God_object) (also known as god objects).
We consider `Project`, `User`, `MergeRequest`, `Ci::Pipeline` and any classes above 1000 LOC to be omniscient.

Such classes are overloaded with responsibilities. New data and behavior can most of the time be added
as a separate and dedicated class.

Guidelines:

- If you mostly need a reference to the object ID (for example `Project#id`) you could add a new model
  that uses the foreign key or a thin wrapper around the object to add special behavior.
- If you find out that by adding a method to the omniscient class you also end up adding a couple of other methods
  (private or public) it's a sign that these methods should be encapsulated in a dedicated class.
- It's temping to add a method to `Project` because that's the starting point of data and associations.
  Try to define behavior in the bounded context where it belongs, not where the data (or some of it) is.
  This helps creating facets of the omniscient object that are much more relevant in the bounded context than
  having generic and overloaded objects which bring more coupling and complexity.

### Example: Define a thin domain object around a generic model

Instead of adding multiple methods to `User` because it has an association to `abuse_trust_scores`,
try inverting the dependency.

```ruby
##
# BAD: Behavior added to User object.
class User
  def spam_score
    abuse_trust_scores.spamcheck.average(:score) || 0.0
  end

  def spammer?
    # Warning sign: we use a constant that belongs to a specific bounded context!
    spam_score > AntiAbuse::TrustScore::SPAMCHECK_HAM_THRESHOLD
  end

  def telesign_score
    abuse_trust_scores.telesign.recent_first.first&.score || 0.0
  end

  def arkose_global_score
    abuse_trust_scores.arkose_global_score.recent_first.first&.score || 0.0
  end

  def arkose_custom_score
    abuse_trust_scores.arkose_custom_score.recent_first.first&.score || 0.0
  end
end

# Usage:
user = User.find(1)
user.spam_score
user.telesign_score
user.arkose_global_score
```

```ruby
##
# GOOD: Define a thin class that represents a user trust score
class AntiAbuse::UserTrustScore
  def initialize(user)
    @user = user
  end

  def spam
    scores.spamcheck.average(:score) || 0.0
  end

  def spammer?
    spam > AntiAbuse::TrustScore::SPAMCHECK_HAM_THRESHOLD
  end

  def telesign
    scores.telesign.recent_first.first&.score || 0.0
  end

  def arkose_global
    scores.arkose_global_score.recent_first.first&.score || 0.0
  end

  def arkose_custom
    scores.arkose_custom_score.recent_first.first&.score || 0.0
  end

  private

  def scores
    AntiAbuse::TrustScore.for_user(@user)
  end
end

# Usage:
user = User.find(1)
user_score = AntiAbuse::UserTrustScore.new(user)
user_score.spam
user_score.spammer?
user_score.telesign
user_score.arkose_global
```

See a real example [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117853#note_1423070054).

### Example: Use Dependency Inversion to extract a domain concept

```ruby
##
# BAD: methods related to integrations defined in Project.
class Project
  has_many :integrations

  def find_or_initialize_integrations
    # ...
  end

  def find_or_initialize_integration(name)
    # ...
  end

  def disabled_integrations
    # ...
  end

  def ci_integrations
    # ...
  end

  # many more methods...
end
```

```ruby
##
# GOOD: All logic related to Integrations is enclosed inside the `Integrations::`
# bounded context.
module Integrations
  class ProjectIntegrations
    def initialize(project)
      @project = project
    end

    def all_integrations
      @project.integrations # can still leverage caching of AR associations
    end

    def find_or_initialize(name)
      # ...
    end

    def all_disabled
      all_integrations.disabled
    end

    def all_ci
      all_integrations.ci_integration
    end
  end
end
```

Real example of [similar refactoring](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92985).

## Design software around use-cases, not entities

Rails, through the power of Active Record, encourages developers to design entity-centric software.
Controllers and API endpoints tend to represent CRUD operations for both entities and service objects.
New database columns tend to be added to existing entity tables despite referring to different use-cases.

This anti-pattern often manifests itself in one or more of the following:

- [Different preconditions](https://gitlab.com/gitlab-org/gitlab/-/blob/d5e0068910b948fd9c921dbcbb0091b5d22e70c9/app/services/groups/update_service.rb#L20-24)
  checked for different use cases.
- [Different permissions](https://gitlab.com/gitlab-org/gitlab/-/blob/1d6cdee835a65f948343a1e4c1abed697db85d9f/ee/app/services/ee/groups/update_service.rb#L47-52)
  checked in the same abstraction (service object, controller, serializer).
- [Different side-effects](https://gitlab.com/gitlab-org/gitlab/-/blob/94922d5555ce5eca8a66687fecac9a0000b08597/app/services/projects/update_service.rb#L124-138)
  executed in the same abstraction for various implicit use-cases. For example, "if field X changed, do Y".

### Anti-pattern example

We have `Groups::UpdateService` which is entity-centric and reused for radically different
use cases:

- Update group description, which requires group admin access.
- Set namespace-level limit for [compute quota](../ci/pipelines/compute_minutes.md), like `shared_runners_minutes_limit`
  which requires instance admin access.

These 2 different use cases support different sets of parameters. It's not likely or expected that
an instance administrator updates `shared_runners_minutes_limit` and also the group description. Similarly, it's not expected
for a user to change branch protection rules and instance runners settings at the same time.
These represent different use cases, coming from different domains.

### Solution

Design around use cases instead of entities. If the personas, use case and intention is different, create a
separate abstraction:

- A different endpoint (controller, GraphQL, or REST) nested to the specific domain of the use case.
- A different service object that embeds the specific permissions and a cohesive set of parameters.
  For example, `Groups::UpdateService` for group admins to update generic group settings.
  `Ci::Minutes::UpdateLimitService` would be for instance admins and would have a completely
  different set of permissions, expectations, parameters, and side-effects.

Ultimately, this requires leveraging the principles in [Taming Omniscient classes](#taming-omniscient-classes).
We want to achieve loose coupling and high cohesion by avoiding the coupling of unrelated use case logic into a single, less-cohesive class.
The result is a more secure system because permissions are consistently applied to the whole action.
Similarly we don't inadvertently expose admin-level data if defined in a separate model or table.
We can have a single permission check before reading or writing data that consistently belongs to the same use case.
