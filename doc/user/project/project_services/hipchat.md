# Atlassian HipChat

GitLab provides a way to send HipChat notifications upon a number of events,
such as when a user pushes code, creates a branch or tag, adds a comment, and
creates a merge request.

## Setup

GitLab requires the use of a HipChat v2 API token to work. v1 tokens are
not supported at this time. Note the differences between v1 and v2 tokens:

HipChat v1 API (legacy) supports "API Auth Tokens" in the Group API menu. A v1
token is allowed to send messages to *any* room.

HipChat v2 API has tokens that are can be created using the Integrations tab
in the Group or Room admin page. By design, these are lightweight tokens that
allow GitLab to send messages only to *one* room.

### Complete these steps in HipChat:

1. Go to: https://admin.hipchat.com/admin
1. Click on "Group Admin" -> "Integrations".
1. Find "Build Your Own!" and click "Create".
1. Select the desired room, name the integration "GitLab", and click "Create".
1. In the "Send messages to this room by posting this URL" column, you should
see a URL in the format:

```
    https://api.hipchat.com/v2/room/<room>/notification?auth_token=<token>
```

HipChat is now ready to accept messages from GitLab. Next, set up the HipChat
service in GitLab.

### Complete these steps in GitLab:

1. Navigate to the project you want to configure for notifications.
1. Select "Settings" in the top navigation.
1. Select "Services" in the left navigation.
1. Click "HipChat".
1. Select the "Active" checkbox.
1. Insert the `token` field from the URL into the `Token` field on the Web page.
1. Insert the `room` field from the URL into the `Room` field on the Web page.
1. Save or optionally click "Test Settings".

## Troubleshooting

If you do not see notifications, make sure you are using a HipChat v2 API
token, not a v1 token.

Note that the v2 token is tied to a specific room. If you want to be able to
specify arbitrary rooms, you can create an API token for a specific user in
HipChat under "Account settings" and "API access". Use the `XXX` value under
`auth_token=XXX`.
