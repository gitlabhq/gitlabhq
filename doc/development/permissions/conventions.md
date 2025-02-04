---
stage: Software Supply Chain Security
group: Authorization
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Permissions Conventions
---

## Historical Context

We utilize the [`DeclarativePolicy` framework for authorization in GitLab](../policies.md), making it straightforward to add new permissions. Until 2024, there was no clear guidance on when to introduce new permissions and how to name them. This lack of direction is a significant reason why the number of permissions has become unmanageable.

The purpose of this document is to provide guidance on:

- When to introduce a new permission and when to reuse an existing one
- How to name new permissions
- What should be included in the `Policy` classes and what should not

### Introducing New Permissions

Introduce a new permission only when absolutely necessary. Always try to use an existing one first. For example, there's no need for a `read_issue_description` permission when we already have `read_issue`, and both require the same role. Similarly, with `create_pipeline` available, we don't need `create_build`.

When introducing a new permission, always attempt to follow the naming conventions. Try to create a general permission, not a specific one. For example, it is better to add a permission `create_member_role` than `create_member_role_name`. If you're unsure, consult a Backend Engineer from the [Govern:Authorization team](https://handbook.gitlab.com/handbook/engineering/development/sec/govern/authorization/) for advice or approval for exceptions.

### Naming Permissions

Our goal is for all permissions to follow a consistent pattern: `verb-feature(-subfeature)`. The feature and subfeature should always be in the singular. Additionally, we aim to limit the verbs used to ensure clarity. The preferred verbs are:

- `create` - for creating an object. For example, `create_issue`.
- `read` - for reading an object. For example, `read_issue`.
- `update` - for updating an object. For example, `update_issue`.
- `delete` - for deleting an object. For example, `delete_issue`.
- `push` and `download` - these are specific verbs for file-related permissions. Other industry terms can be permitted after a justification.

We recognize that this set of verbs is limited and not applicable to every feature. Here are some verbs that, while necessary, could potentially be rephrased to align with the above conventions:

- `approve` - For example, `approve_merge_request`. Though `approve` suggests a lower role than `manage`, it could be rephrased as `create_merge_request_approval`.

#### Preferred Verbs

- `create` is preferred over `build` or `import`
- `read` is preferred over `access`
- `push` is preferred over `upload`

#### Exceptions

If you believe a new permission is needed that does not follow these conventions, consult the [Govern:Authorization team](https://handbook.gitlab.com/handbook/engineering/development/sec/govern/authorization/). We're always open to discussion, these guidelines are meant to make the work of Engineers easier, not to complicate it.

### What to Include in Policy Classes

#### Role

Policy classes should include checks for both predefined and custom roles.

Examples:

```ruby
rule { developer } # Static role check
rule { can?(:developer_access) } # Another approach used in some classes
rule { custom_role_enables_read_dependency } # Custom role check
```

#### Checks Related to the Current User

Include checks that vary based on the current user's relationship with the object, such as being an assignee or author.

Examples:

```ruby
rule { is_author }.policy do
  enable :read_note
  enable :update_note
  enable :delete_note
end
```
