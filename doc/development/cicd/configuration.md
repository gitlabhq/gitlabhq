---
stage: Verify
group: Pipeline Authoring
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Contribute to the CI/CD configuration
---

## Glossary

- **CI/CD configuration**: The YAML file that defines the CI/CD configuration for a project.
- **keyword**: Each keyword in the CI/CD configuration.
- **entry**: An `Entry` class that represents a keyword in the CI/CD configuration.

Not every keyword in the CI/CD configuration is represented by an `Entry` class.
We create `Entry` classes for keywords that have a complex structure or reusable parts.

For example;

- The `image` keyword is represented by the [`Entry::Image`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/config/entry/image.rb) class.
- The `name` subkeyword of the `image` keyword is not represented by an `Entry` class.
- The `pull_policy` subkeyword of the `image` keyword is represented by the [`Entry::PullPolicy`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/config/entry/pull_policy.rb) class.

## Adding New Keywords

CI config keywords are added in the [`lib/gitlab/ci/config/entry`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/config/entry) directory.
For EE-specific changes, use the [`ee/lib/gitlab/ci/config/entry`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/lib/gitlab/ci/config/entry)
or [`ee/lib/ee/gitlab/ci/config/entry`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/lib/ee/gitlab/ci/config/entry) directory.

### Inheritance

An entry is represented by a class that inherits from;

- `Entry::Node`: for simple keywords.
  (e.g. [`Entry::Stage`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/config/entry/stage.rb))
- `Entry::Simplifiable`: for keywords that have multiple structures.
  For example, [`Entry::Retry`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/config/entry/retry.rb) can be a simple number or a hash configuration.
- `Entry::ComposableArray`: for keywords that have a list of single-type sub-elements.
  For example, [`Entry::Includes`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/config/entry/includes.rb) has a list of `Entry::Include` elements.
- `Entry::ComposableHash`: for keywords that have single-type sub-elements with user-defined keys.
  For example, [`Entry::Variables`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/config/entry/variables.rb) has a list of `Entry::Variable` elements with user-defined keys.

### Helper Classes

The following helper classes are available for use in entries:

- `Entry::Validatable`: Enables the `validations` block in an entry class and provides validations.
- `Entry::Attributable`: Enables the `attributes` method in an entry class. It creates these methods for each attribute; `xxx`, `has_xxx?`, `has_xxx_value?`.
- `Entry::Configurable`: Enables the `entry` method in an entry class. It creates these methods for each entry; `xxx_defined?`, `xxx_entry`, `xxx_value`.

### The `value` Method

The `value` method is the main method of an entry class. It returns the actual value of the entry.
By default, from the `Entry::Node` class, the `value` method returns the hash configuration of the entry unless it has nested entries.
It can be useful for simple entries. For example, `Entry::Paths` has an array of strings as its value. So, it can return the array of strings directly.

In some keywords, we override the `value` method. In this method, we return what and how we want to return from the entry.
The usage of `Entry::Attributable` and `Entry::Configurable` may have a significant role here. For example,
in `Entry::Secret`, we have this;

```ruby
attributes %i[vault file token].freeze

entry :vault, Entry::Vault::Secret
entry :file, ::Gitlab::Config::Entry::Boolean

def value
  {
    vault: vault_value,
    file: file_value,
    token: token
  }.compact
end
```

- `vault_value` is the value of the nested `vault` entry.
- `file_value` is the value of the nested `file` entry.
- `token` is the value of the basic `token` attribute.

**It is important** that we should always use the `xxx_value` method to get the value of a nested entry.

## Feature Flag Usage

When adding new CI/CD configuration keywords, it is important to use feature flags to control the rollout of the change.
This allows us to test the change in production without affecting all users. For more information, see the [feature flags documentation](../feature_flags/_index.md).

A common place to check for a feature flag is in the `Gitlab::Config::Entry::Node#value` method. For example:

```ruby
def value
  {
    vault: vault_value,
    file: file_available? ? file_value : nil,
    token: token
  }.compact
end

private

def file_available?
  ::Gitlab::Ci::Config::FeatureFlags.enabled?(:secret_file_available, type: :beta)
end
```

### Feature Flag Actor

In entry classes, we have no access to the current project or user. However, it's discouraged to use feature flags without [an actor](../feature_flags/_index.md#feature-actors).
To solve this problem, we have three options;

1. Use `Feature.enabled?(:feature_flag, Feature.current_request)`.
1. Use `Config::FeatureFlags.enabled?(:feature_flag)`
1. Do not use feature flags in entry classes and use them in other parts of the code.

## Testing and Validation

When adding or modifying an entry, the corresponding spec file must be either added or updated.
Besides, to have a fully integrated test, it's also important to add/modify tests in the `spec/lib/gitlab/ci/yaml_processor_spec.rb` file or
the files in `spec/lib/gitlab/ci/yaml_processor/test_cases/*` directory.
