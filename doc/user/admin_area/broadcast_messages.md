---
type: reference, howto
---

# Broadcast Messages **(CORE ONLY)**

GitLab can display messages to all users of a GitLab instance in a banner that appears in the UI.

![Broadcast Message](img/broadcast_messages.png)

Broadcast messages can be managed using the [broadcast messages API](../../api/broadcast_messages.md).

NOTE: **Note:**
If more than one banner message is active at one time, they are displayed in a stack in order of creation.

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
list of broadcast messages.

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
