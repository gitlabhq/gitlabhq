---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Callouts
---

Callouts are a mechanism for presenting notifications to users. Users can dismiss the notifications, and the
notifications can stay dismissed for a predefined duration. Notification dismissal is persistent across page loads and
different user devices.

## Callout contexts

**Global context**: Callouts can be displayed to a user regardless of where they are in the application. For example, we
can show a notification that reminds the user to have two-factor authentication recovery codes stored in a safe place.
Dismissing this type of callout is effective for the particular user across the whole GitLab instance, no matter where
they encountered the callout.

**Group and project contexts**: Callouts can also be displayed to a specific user and have a particular context binding,
like a group or a project context. For example, group owners can be notified that their group is running out of
available seats. Dismissing that callout would be effective for the particular user only in this particular group, while
they would still see the same callout in other groups, if applicable.

Regardless of the context, dismissing a callout is only effective for the given user. Other users still see their
relevant callouts.

## Callout IDs

Callouts use unique names to identify them, and a unique value to store dismissals data. For example:

```ruby
amazing_alert: 42,
```

Here `amazing_alert` is the callout ID, and `42` is a unique number to be used to register dismissals in the database.
Here's how a group callout would be saved:

```plaintext
 id | user_id | group_id | feature_name |         dismissed_at
----+---------+----------+--------------+-------------------------------
  0 |       1 |        4 |           42 | 2025-05-21 00:00:00.000000+00
```

To create a new callout ID, add a new key to the `feature_name` enum in the relevant context type registry file, using a
unique name and a sequential value:

- Global context: `app/models/users/callout.rb`. Callouts are dismissed by a user globally. Related notifications would
  not be displayed anywhere in the GitLab instance for that user.

- Group context: `app/models/users/group_callout.rb`. Callouts are dismissed by a user in a given group. Related
  notifications are still shown to the user in other groups.

- Project context: `app/models/users/project_callout.rb`. Callouts dismissed by a user in a given project. Related
  notifications are still shown to the user in other projects.

**NOTE**: do not reuse old enum values, as it may lead to false-positive dismissals. Instead, create a new sequential
number.

### Deprecating a callout

When we no longer need a callout, we can remove it from the callout ID enums. But since dismissal records in the DB use
the numerical value of the enum, we need to explicitly preserve the deprecated ID from being reused, so that old
dismissals don't affect the new callouts. Thus to remove a callout ID:

1. Remove the key/value pair from the enum hash
1. Leave an inline comment, mentioning the deprecated ID and the MR removing the callout

For example:

```diff
- amazing_alert: 42,
+ # 42 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121920
```

## Dismissible alert components

### Haml

When implementing dismissible alerts in HAML views, use the dismissible alert components. These components
extend `Pajamas::AlertComponent` and provide strong validation, simplified setup, and automatic handling of dismissal
logic.

#### Available components

- `Users::DismissibleAlertComponent` - For user(global) context callouts
- `Users::GroupDismissibleAlertComponent` - For group context callouts
- `Users::ProjectDismissibleAlertComponent` - For project context callouts

All components inherit from `Pajamas::AlertComponent` and support the same interface, with the addition of
`dismiss_options` and optional `wrapper_options` parameters.

#### Basic usage

##### User (global) callouts

```haml
= render Users::DismissibleAlertComponent.new(
    title: _('Alert title'),
    variant: :warning,
    dismiss_options: { user: current_user, feature_id: 'my_user_callout' }
  ) do |c|
  - c.with_body do
    = _('Alert message content goes here.')
```

##### Group callouts

```haml
= render Users::GroupDismissibleAlertComponent.new(
    title: _('Group-specific alert'),
    dismiss_options: { user: current_user, group: @group, feature_id: 'my_group_callout' },
    variant: :info
  ) do |c|
  - c.with_body do
    = _('This alert is specific to the current group.')
```

##### Project callouts

```haml
= render Users::ProjectDismissibleAlertComponent.new(
    title: _('Project notification'),
    dismiss_options: { user: current_user, project: @project, feature_id: 'my_project_callout' },
    variant: :success
  ) do |c|
  - c.with_body do
    = _('This alert is specific to the current project.')
```

#### Additional parameters

##### `dismiss_options` (required)

All dismissible alert components require a `dismiss_options` hash:

- **User callouts**: `{ user: current_user, feature_id: 'callout_name' }`
- **Group callouts**: `{ user: current_user, group: @group, feature_id: 'callout_name' }`
- **Project callouts**: `{ user: current_user, project: @project, feature_id: 'callout_name' }`

##### `ignore_dismissal_earlier_than` (optional)

Add `ignore_dismissal_earlier_than` to make callouts reappear after a certain time period:

```haml
= render Users::DismissibleAlertComponent.new(
    title: _('Recurring alert'),
    dismiss_options: {
      user: current_user,
      feature_id: 'recurring_callout',
      ignore_dismissal_earlier_than: 30.days.ago
    }
  ) do |c|
  - c.with_body do
    = _('This alert will reappear every 30 days.')
```

You can use Time, Date, DateTime objects, or valid date/time strings:

```haml
# Using Time objects (recommended)
ignore_dismissal_earlier_than: 30.days.ago
ignore_dismissal_earlier_than: 1.week.ago

# Using date strings
ignore_dismissal_earlier_than: '2023-01-01'
ignore_dismissal_earlier_than: '2023-01-01 12:00:00'
```

Without this parameter, dismissals are permanent. With it, the alert reappears if it was dismissed before the specified
time.

##### `wrapper_options` (optional)

Use `wrapper_options` to wrap the alert in a custom container:

```haml
= render Users::GroupDismissibleAlertComponent.new(
    title: _('Alert with wrapper'),
    dismiss_options: { user: current_user, group: @group, feature_id: 'wrapped_callout' },
    wrapper_options: { tag: :section, class: 'custom-wrapper' }
  ) do |c|
  - c.with_body do
    = _('This alert is wrapped in a custom container.')
```

#### Benefits of dismissible alert components

1. **Strong validation**: Components verify that feature IDs exist in the appropriate callout model and that required
   parameters are provided
1. **Simplified setup**: No need to manually configure CSS classes, data attributes, or dismissal endpoints
1. **Automatic handling**: Dismissal logic, rendering conditions, and JavaScript integration are handled automatically
1. **Type safety**: Components enforce correct parameter types and catch configuration errors early
1. **Consistent behavior**: All dismissible alerts follow the same patterns and conventions
1. **Full AlertComponent compatibility**: Supports all existing `AlertComponent` parameters and functionality

#### Migration from manual implementation

When migrating from manual `Pajamas::AlertComponent` usage:

**Before:**

```haml
= render Pajamas::AlertComponent.new(
    title: _('Alert title'),
    variant: :warning,
    alert_options: {
      class: 'js-persistent-callout',
      data: {
        feature_id: 'my_callout',
        dismiss_endpoint: callouts_path
      }
    },
    dismissible: true
  ) do |c|
  - c.with_body do
    = _('Alert content')
```

**After:**

```haml
= render Users::DismissibleAlertComponent.new(
    title: _('Alert title'),
    variant: :warning,
    dismiss_options: { user: current_user, feature_id: 'my_callout' }
  ) do |c|
  - c.with_body do
    = _('Alert content')
```

### Vue

This section describes using callouts when they are rendered on the client in `.vue` components.

#### Dismissing the callouts on the client side

For Vue components, we have dismisser wrapper components that integrate with GraphQL API to simplify
dismissing and checking the dismissed state of callouts.

##### User (global) callouts

For global user callouts that should be dismissed across the entire GitLab instance, use `<user-callout-dismisser>`. Use
this component when the callout should be dismissed globally for the user across all groups and projects (e.g., feature
announcements, account security reminders).

```vue
<user-callout-dismisser feature-name="my_user_callout">
  <template #default="{ dismiss, shouldShowCallout }">
    <my-callout-component
      v-if="shouldShowCallout"
      @close="dismiss"
    />
  </template>
</user-callout-dismisser>
```

See `app/assets/javascripts/vue_shared/components/user_callout_dismisser.vue` for more details.

##### Group callouts

For group-specific callouts that should only be dismissed within a particular group context, use
`<user-group-callout-dismisser>`. Use this component when the callout is specific to a group context and should only be
dismissed within that group (e.g., group billing notifications, group-specific feature promotions).

```vue
<user-group-callout-dismisser
  feature-name="my_group_callout"
  :group-id="groupId"
>
  <template #default="{ dismiss, shouldShowCallout }">
    <my-group-callout-component
      v-if="shouldShowCallout"
      @close="dismiss"
    />
  </template>
</user-group-callout-dismisser>
```

The `group-id` prop accepts both numeric IDs (e.g., `123`) and GraphQL IDs (e.g., `'gid://gitlab/Group/123'`). The
component handles the conversion to GraphQL format internally, so you can pass either format.

See `app/assets/javascripts/vue_shared/components/user_group_callout_dismisser.vue` for more details.

##### Available slot props

Both components provide the same slot props:

- `dismiss`: Function to dismiss the callout
- `shouldShowCallout`: Boolean indicating if the callout should be displayed
