---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Code comments

Whenever you add comment to the code that is expected to be addressed at any time
in future, create a technical debt issue for it. Then put a link to it
to the code comment you've created. This allows other developers to quickly
check if a comment is still relevant and what needs to be done to address it.

Examples:

```ruby
# Deprecated scope until code_owner column has been migrated to rule_type.
# To be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/11834.
scope :code_owner, -> { where(code_owner: true).or(where(rule_type: :code_owner)) }
```
