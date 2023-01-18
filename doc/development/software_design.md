---
stage: none
group: Engineering Productivity
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Software design guides

## Use ubiquitous language instead of CRUD terminology

The code should use the same [ubiquitous language](https://about.gitlab.com/handbook/communication/#ubiquitous-language)
as used in the product and user documentation. Failure to use ubiquitous language correctly
can be a major cause of confusion for contributors and customers when there is constant translation
or use of multiple terms.
This also goes against our [communication strategy](https://about.gitlab.com/handbook/communication/#mecefu-terms).

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

## Use namespaces to define bounded contexts

A healthy application is divided into macro and sub components that represent the contexts at play,
whether they are related to business domain or infrastructure code.

As GitLab code has so many features and components it's hard to see what contexts are involved.
We should expect any class to be defined inside a module/namespace that represents the contexts where it operates.

When we namespace classes inside their domain:

- Similar terminology becomes unambiguous as the domain clarifies the meaning:
  For example, `MergeRequests::Diff` and `Notes::Diff`.
- Top-level namespaces could be associated to one or more groups identified as domain experts.
- We can better identify the interactions and coupling between components.
  For example, several classes inside `MergeRequests::` domain interact more with `Ci::`
  domain and less with `ImportExport::`.

A good guideline for naming a top-level namespace (bounded context) is to use the related
[feature category](https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/categories.yml).
For example, `Continuous Integration` feature category maps to `Ci::` namespace.

```ruby
# bad
class JobArtifact
end

# good
module Ci
  class JobArtifact
  end
end
```

Projects and Groups are generally container concepts because they identify tenants.
They allow features to exist at the project or group level, like repositories or runners,
but do not nest such features under `Projects::` or `Groups::`.

`Projects::` and `Groups::` namespaces should be used only for concepts that are strictly related to them:
for example `Project::CreateService` or `Groups::TransferService`.

For controllers we allow `app/controllers/projects` and `app/controllers/groups` to be exceptions.
We use this convention to indicate the scope of a given web endpoint.

Do not use the [stage or group name](https://about.gitlab.com/handbook/product/categories/#devops-stages)
because a feature category could be reassigned to a different group in the future.

```ruby
# bad
module Create
  class Commit
  end
end

# good
module Repositories
  class Commit
  end
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
module ContainerSecurity
  module HostSecurity
  end

  module NetworkSecurity
  end

  module Scanning
  end
end
```

If classes that are defined into a namespace have a lot in common with classes in other namespaces,
chances are that these two namespaces are part of the same bounded context.
