---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Backend directory structure

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

```ruby
# bad
class MyClass
end

# good
module MyDomain
  class MyClass
  end
end
```

### About namespace naming

A good guideline for naming a top-level namespace (bounded context) is to use the related
feature category. For example, `Continuous Integration` feature category maps to `Ci::` namespace.

Alternatively a new class could be added to `Projects::` or `Groups::` if it's either:

- Strictly related to one of these domains. For example `Projects::Alias`.
- A new component that does not have yet a more specific domain. In this case, when
  a more explicit domain does emerge we would need to move the class to a more specific
  namespace.

Do not use the [stage or group name](https://about.gitlab.com/handbook/product/categories/#devops-stages)
since a feature category could be reassigned to a different group in the future.

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
E.g. `Ci::Config::`.

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
