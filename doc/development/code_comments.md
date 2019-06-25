# Code comments

Whenever you add comment to the code that is expected to be addressed at any time 
in future, please create a technical debt issue for it. Then put a link to it 
to the code comment you've created. This will allow other developers to quickly
check if a comment is still relevant and what needs to be done to address it.

Examples: 

```rb
# Deprecated scope until code_owner column has been migrated to rule_type.
# To be removed with https://gitlab.com/gitlab-org/gitlab-ee/issues/11834.
scope :code_owner, -> { where(code_owner: true).or(where(rule_type: :code_owner)) }
```
