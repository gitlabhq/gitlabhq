---
type: reference, howto
---

# Broadcast Messages **(CORE ONLY)**

GitLab can display broadcast messages to all users of a GitLab instance. There are two types of broadcast messages:

- banners
- notifications

You can style a message's content using the `a` and `br` HTML tags. The `br` tag inserts a line break. The `a` HTML tag accepts `class` and `style` attributes with the following CSS properties:

- `color`
- `border`
- `background`
- `padding`
- `margin`
- `text-decoration`

## Banners

Banners are shown on the top of a page and in Git remote responses.

![Broadcast Message Banner](img/broadcast_messages_banner_v12_10.png)

```shell
$ git push
...
remote:
remote: **Welcome** to GitLab :wave:
remote:
...
```

## Notifications

Notifications are shown on the bottom right of a page and can contain placeholders. A placeholder is replaced with an attribute of the active user. Placeholders must be surrounded by curly braces, for example `{{name}}`.
The available placeholders are:

- `{{email}}`
- `{{name}}`
- `{{user_id}}`
- `{{username}}`
- `{{instance_id}}`

If the user is not signed in, user related values will be empty.

![Broadcast Message Notification](img/broadcast_messages_notification_v12_10.png)

Broadcast messages can be managed using the [broadcast messages API](../../api/broadcast_messages.md).

NOTE: **Note:**
If more than one banner message is active at one time, they are displayed in a stack in order of creation.
If more than one notification message is active at one time, only the newest is shown.

## Adding a broadcast message

To display messages to users on your GitLab instance, add broadcast message.

To add a broadcast message:

1. Navigate to the **Admin Area > Messages** page.
1. Add the text for the message to the **Message** field. Markdown and emoji are supported.
1. If required, click the **Customize colors** link to edit the background color and font color of the message.
1. If required, add a **Target Path** to only show the broadcast message on URLs matching that path. You can use the wildcard character `*` to match multiple URLs, for example `/users/*/issues`.
1. Select a date for the message to start and end.
1. Click the **Add broadcast message** button.

NOTE: **Note:**
Once a broadcast message has expired, it is no longer displayed in the UI but is still listed in the
list of broadcast messages. User can also dismiss a broadcast message if the option **Dismissable** is set.

## Editing a broadcast message

If changes are required to a broadcast message, they can be edited.

To edit a broadcast message:

1. Navigate to the **Admin Area > Messages** page.
1. From the list of broadcast messages, click the appropriate button to edit the message.
1. After making the required changes, click the **Update broadcast message** button.

TIP: **Tip:**
Expired messages can be made active again by changing their end date.

## Deleting a broadcast message

Broadcast messages that are no longer required can be deleted.

To delete a broadcast message:

1. Navigate to the **Admin Area > Messages** page.
1. From the list of broadcast messages, click the appropriate button to delete the message.

Once deleted, the broadcast message is removed from the list of broadcast messages.

NOTE: **Note:**
Broadcast messages can be deleted while active.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
