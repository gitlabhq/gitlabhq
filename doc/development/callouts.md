---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Callouts
---

Callouts are a mechanism for presenting notifications to users. Users can dismiss the notifications, and the notifications can stay dismissed for a predefined duration. Notification dismissal is persistent across page loads and different user devices.

## Callout contexts

**Global context:** Callouts can be displayed to a user regardless of where they are in the application. For example, we can show a notification that reminds the user to have two-factor authentication recovery codes stored in a safe place. Dismissing this type of callout is effective for the particular user across the whole GitLab instance, no matter where they encountered the callout.

**Group and project contexts:** Callouts can also be displayed to a specific user and have a particular context binding, like a group or a project context. For example, group owners can be notified that their group is running out of available seats. Dismissing that callout would be effective for the particular user only in this particular group, while they would still see the same callout in other groups, if applicable.

Regardless of the context, dismissing a callout is only effective for the given user. Other users still see their relevant callouts.

## Callout IDs

Callouts use unique names to identify them, and a unique value to store dismissals data. For example:

```ruby
amazing_alert: 42,
```

Here `amazing_alert` is the callout ID, and `42` is a unique number to be used to register dismissals in the database. Here's how a group callout would be saved:

```plaintext
 id | user_id | group_id | feature_name |         dismissed_at
----+---------+----------+--------------+-------------------------------
  0 |       1 |        4 |           42 | 2025-05-21 00:00:00.000000+00
```

To create a new callout ID, add a new key to the `feature_name` enum in the relevant context type registry file, using a unique name and a sequential value: 

- Global context: `app/models/users/callout.rb`. Callouts are dismissed by a user globally. Related notifications would not be displayed anywhere in the GitLab instance for that user.

- Group context: `app/models/users/group_callout.rb`. Callouts are dismissed by a user in a given group. Related notifications are still shown to the user in other groups.

- Project context: `app/models/users/project_callout.rb`. Callouts dismissed by a user in a given project. Related notifications are still shown to the user in other projects.

**NOTE:** do not reuse old enum values, as it may lead to false-positive dismissals. Instead, create a new sequential number.

### Deprecating a callout

When we no longer need a callout, we can remove it from the callout ID enums. But since dismissal records in the DB use the numerical value of the enum, we need to explicitly preserve the deprecated ID from being reused, so that old dismissals don't affect the new callouts. Thus to remove a callout ID:

1. Remove the key/value pair from the enum hash
1. Leave an inline comment, mentioning the deprecated ID and the MR removing the callout

For example:

```diff
- amazing_alert: 42,
+ # 42 removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121920
```

## Server-side rendered callouts

This section describes using callouts when they are rendered on the server in `.haml` views, partials, or components.

### Dismissing the callouts on the client side

JavaScript helpers for callouts rely on certain selectors and data attributes to be present on the HTML of the notification, to properly call dismissal API endpoints, and hide the notification in the runtime. The wrapper of the notification needs to have a `.js-persistent-callout` CSS class with the following data-attributes:

```javascript
{
  featureId,        // Unique callout ID
  dismissEndpoint,  // Dismiss endpoint, unique for each callout context type
  groupId,          // optional, required for the group context
  projectId,        // optional, required for the project context
  deferLinks,       // optional, allows executing certain action alongside the dismissal
}
```

For the dismissal trigger, the wrapper needs to contain at least one `.js-close` element and optionally `.deferred-link` links (if `deferLinks` is `true`). See `app/assets/javascripts/persistent_user_callout.js` for more details.

#### Defining the dismissal endpoint

For the JS to properly register the dismissal — apart from the `featureId`, we need to provide the `dismissEndpoint` URL, different for each context. Here are path helpers to use for each context:

- Global context: `callouts_path`

- Group context: `group_callouts_path`

- Project context: `project_callouts_path`

### Detecting the dismissal on the server side

Usually before rendering the callout, we check if it has been dismissed. `User` model on the Backend has helpers to detect dismissals in different contexts:

- Global context: `user.dismissed_callout?(feature_name:, ignore_dismissal_earlier_than: nil)`

- Group context: `user.dismissed_callout_for_group?(feature_name:, group:, ignore_dismissal_earlier_than: nil)`

- Project context: `user.dismissed_callout_for_project?(feature_name:, project:, ignore_dismissal_earlier_than: nil)`

**NOTE:** `feature_name` is the Callout ID, described above. In our example, it would be `amazing_alert`

#### Setting expiration for dismissals using `ignore_dismissal_earlier_than` parameter

Some callouts can be displayed once and after the dismissal should never appear again. Others need to pop-up repeatedly, even if dismissed.

Without the `ignore_dismissal_earlier_than` parameter callout dismissals will stay effective indefinitely. Once the user has dismissed the callout, it would stay dismissed.

If we pass `ignore_dismissal_earlier_than` a value, for example, `30.days.ago`, the dismissed callout would re-appear after this duration.

**NOTE:** expired or deprecated dismissals are not automatically removed from the database. This parameter only checks if the callout has been dismissed within the defined period.

### Example usage

Here's an example `.haml` file:

```haml
- return if amazing_alert_callout_dismissed?(group)

= render Pajamas::AlertComponent.new(title: s_('AmazingAlert|Amazing title'),
  variant: :warning,
  alert_options: { class: 'js-persistent-callout', data: amazing_alert_callout_data(group) }) do |c|
  - c.with_body do
    = s_('AmazingAlert|This is an amazing alert body.')
```

With a corresponding `.rb` helper:

```ruby
# frozen_string_literal: true

module AmazingAlertHelper
  def amazing_alert_callout_dismissed?(group)
    user_dismissed_for_group("amazing_alert", group.root_ancestor, 30.days.ago)
  end

  def amazing_alert_callout_data(group)
    {
      feature_id: "amazing_alert",
      dismiss_endpoint: group_callouts_path,
      group_id: group.root_ancestor.id
    }
  end
end
```

## Client-side rendered callouts

This section describes using callouts when they are rendered on the client in `.vue` components.

### Dismissing the callouts on the client side

For Vue components, we have a `<user-callout-dismisser>` wrapper, that integrates with GraphQL API to simplify dismissing and checking the dismissed state of a callout. Here's an example usage:

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
