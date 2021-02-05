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
