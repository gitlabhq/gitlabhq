---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Code comments
---

## Core principles

Self-explanatory coding and avoiding additional comments should be the first goal.
It can be strengthened by using descriptive method naming, leveraging Ruby's expressiveness,
using keyword arguments, creating small and single-purpose methods, following idiomatic conventions, using enums, etc.

If the code isn't self-explanatory enough,
comments can play a crucial role in providing context and rationale that cannot be expressed through code alone.

Code comments are as much part of the code as the code itself.
They should be maintained, updated, and refined as the code evolves or as our understanding of the system increases.

Key principles to follow:

- Comments should stay as close as possible to the code they're referencing
- Comments should be thorough but avoid redundancy
- Assume the next person reading this code has no context and limited time to understand it

## Code comments should focus more on the "why" and not the "what" or "how"

The code itself should clearly express what it does.
Explaining functionality within comments creates an additional maintenance burden,
as they can become outdated when code changes, potentially leading to confusion.
Instead, comments should explain why certain decisions were made or why specific approaches were taken.

For example:

- Working around system limitations
- Dealing with edge cases that might not be immediately obvious
- Implementing complex business logic that requires deep domain knowledge
- Handling legacy system constraints

Example of a good comment:

```ruby
# Note: We need to handle nil values separately here because the external 
# payment API treats empty strings and null values differently. 
# See: https://api-docs.example.com/edge-cases
def process_payment_amount(amount)
  # Implementation
end
```

Example of an unnecessary comment:

```ruby
# Calculate the total amount
def calculate_total(items)
  # Implementation
end
```

### Higher level code comments and class/module level documentation

The GitLab codebase has many libraries which are re-used in many places.
Some of these libraries (e.g. [`ExclusiveLeaseHelpers`](https://gitlab.com/gitlab-org/gitlab/-/blob/d1d70895986065115414f6463fb82aa931c26858/lib/gitlab/exclusive_lease_helpers.rb#L31))
have complicated internal implementations which are time-consuming to read through and understand the implications of using the library.
Similarly, some of these libraries have multiple options which have important outcomes
that are difficult to understand by simply reading the name of the parameter.

We don't have hard guidelines for whether or not these libraries should be documented in separate developer-facing Markdown files
or as comments above classes/modules/methods, and we see a mix of these approaches throughout the GitLab codebase.
In either case, we believe the value of the documentation increases with how widely the library is used and decreases
with the frequency of change to the implementation and interface of the library.

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

If a method's return value is not used, the YARD `@return` type should be annotated
as `void`, and the method should explicitly return `nil`. This pattern clarifies that
the return value shouldn't be used and prevents accidental usage in chains or assignments.
For example:

```ruby
class SomeModel < ApplicationRecord
  # @return [void]
  def validate_some_field
    return unless field_is_invalid

    errors.add(:some_field, format(_("some message")))

    # Explicitly return nil for void methods
    nil
  end
end
```

For more context and information, see [the merge request comment](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182979#note_2376631108).
