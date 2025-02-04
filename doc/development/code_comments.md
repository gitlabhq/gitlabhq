---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Code comments
---

## Comments for follow-up actions

Whenever you add comments to the code that are expected to be addressed
in the future, create a technical debt issue. Then put a link to it
to the code comment you've created. This allows other developers to quickly
check if a comment is still relevant and what needs to be done to address it.

Examples:

```ruby
# Deprecated scope until code_owner column has been migrated to rule_type.
# To be removed with https://gitlab.com/gitlab-org/gitlab/-/issues/11834.
scope :code_owner, -> { where(code_owner: true).or(where(rule_type: :code_owner)) }
```

## Class and method documentation

Use [YARD](https://yardoc.org/) syntax if documenting method arguments or return values.

Example without YARD syntax:

```ruby
class Order
  # Finds order IDs associated with a user by email address.
  def order_ids_by_email(email)
    # ...
  end
end
```

Example using YARD syntax:

```ruby
class Order
  # Finds order IDs associated with a user by email address.
  #
  # @param email [String, Array<String>] User's email address
  # @return [Array<Integer>]
  def order_ids_by_email(email)
    # ...
  end
end
```
