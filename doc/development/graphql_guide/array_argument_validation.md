---
stage: Developer Experience
group: API Platform
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: GraphQL Array Arguments
---

## Array Argument Validation in GraphQL

### Overview

All array arguments in GitLab GraphQL API should have size validation to prevent abuse and performance issues.

### Validation Approaches

#### Recommended: Explicit Validation (Target State)

Use the `validates` option to explicitly declare array size limits:

```ruby
argument :assignee_usernames, [GraphQL::Types::String],
  required: false,
  validates: { length: { maximum: Types::BaseArgument::MAX_ARRAY_SIZE } },
  description: "Usernames of users assigned to the merge request " \
    "(maximum is #{Types::BaseArgument::MAX_ARRAY_SIZE} usernames)."
```

**Benefits:**

- Clear and explicit
- Visible in the argument definition
- Consistent with existing codebase patterns
- Uses GraphQL-Ruby's built-in validation

#### Automatic Validation (Transition Period)

During the transition period, array arguments **without** explicit `validates: { length: { maximum: ... } }` will automatically be limited to 100 items by `BaseArgument`.

```ruby
# This will automatically be limited to 100 items
argument :items, [GraphQL::Types::String],
  required: false,
  description: 'List of items.'
```

### How It Works

The `BaseArgument` class implements smart detection:

1. **If explicit validation exists**: Uses the explicit limit (no automatic validation)
1. **If no explicit validation**: Applies automatic 100-item limit

```ruby
# Explicit validation - uses 50 as the limit
argument :limited_items, [GraphQL::Types::String],
  validates: { length: { maximum: 50 } },
  description: 'Limited to 50 items.'

# No explicit validation - automatically limited to 100 items
argument :auto_limited_items, [GraphQL::Types::String],
  description: 'Automatically limited to 100 items.'
```

### Migration Path

#### Step 1: Automatic Protection (Current)

All array arguments are automatically protected with a 100-item limit.

#### Step 2: Add Explicit Validation

Gradually add explicit `validates` declarations to all array arguments:

```ruby
# Before (relies on automatic validation)
argument :assignee_usernames, [GraphQL::Types::String],
  required: false,
  description: 'Usernames of users assigned to the merge request.'

# After (explicit validation)
argument :assignee_usernames, [GraphQL::Types::String],
  required: false,
  validates: { length: { maximum: Types::BaseArgument::MAX_ARRAY_SIZE } },
  description: "Usernames of users assigned to the merge request " \
    "(maximum is #{Types::BaseArgument::MAX_ARRAY_SIZE} usernames)."
```

#### Step 3: Remove Automatic Validation

Once all array arguments have explicit validation, we can remove the automatic validation from `BaseArgument`.

### Constants

#### `Types::BaseArgument::MAX_ARRAY_SIZE`

Default maximum size for array arguments (currently 100).

Use this constant for consistency:

```ruby
validates: { length: { maximum: Types::BaseArgument::MAX_ARRAY_SIZE } }
```

#### Custom Limits

For specific use cases, you can use a different limit:

```ruby
# Using a module constant
module WorkItems
  module SharedFilterArguments
    MAX_FIELD_LIMIT = 100
  end
end

argument :ids, [::Types::GlobalIDType[::WorkItem]],
  validates: { length: { maximum: WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
  description: "Filter by global IDs (maximum is #{WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT} IDs)."
```

### Error Messages

When validation fails, users receive a clear error message:

```plaintext
"assigneeUsernames cannot accept more than 100 items"
```

### Examples

#### Good Examples

```ruby
# Example 1: Using the default constant
argument :user_ids, [GraphQL::Types::ID],
  validates: { length: { maximum: Types::BaseArgument::MAX_ARRAY_SIZE } },
  description: "User IDs (maximum is #{Types::BaseArgument::MAX_ARRAY_SIZE})."

# Example 2: Using a custom constant
argument :label_names, [GraphQL::Types::String],
  validates: { length: { maximum: WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT } },
  description: "Label names (maximum is #{WorkItems::SharedFilterArguments::MAX_FIELD_LIMIT})."

# Example 3: Custom limit for specific use case
argument :vulnerability_ids, [GraphQL::Types::ID],
  validates: { length: { minimum: 1, maximum: 50 } },
  description: "Vulnerability IDs (minimum 1, maximum 50)."
```

#### Bad Examples

```ruby
# Bad: No validation and no description of limit
argument :items, [GraphQL::Types::String],
  description: 'List of items.'

# Bad: Hardcoded number without constant
argument :items, [GraphQL::Types::String],
  validates: { length: { maximum: 100 } },
  description: 'List of items (maximum is 100).'
```

### Testing

When testing resolvers or mutations with array arguments, test the validation:

```ruby
RSpec.describe Resolvers::MyResolver do
  it 'accepts arrays within the limit' do
    items = Array.new(50, 'item')
    expect { resolve(items: items) }.not_to raise_error
  end

  it 'rejects arrays exceeding the limit' do
    items = Array.new(101, 'item')
    expect { resolve(items: items) }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
  end
end
```

### Related

- [GraphQL Style Guide](../api_graphql_styleguide.md)
