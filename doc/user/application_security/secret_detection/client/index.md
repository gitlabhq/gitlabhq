---
stage: Secure
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Client-side secret detection

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368434) in GitLab 15.11.
> - Detection of personal access tokens with a custom prefix was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/411146) in GitLab 16.1. GitLab self-managed only.

When you create an issue or epic, propose a merge request, or write a comment, you might accidentally post a sensitive value.
For example, you might paste in the details of an API request or an environment variable that contains an authentication token.

When you edit the description or comment in an issue, epic, or merge request, GitLab checks if it contains a sensitive token.
If a token is found, a warning message is displayed. You can then edit your description or comment before posting it.
This check happens in your browser before the message is sent to the server.
The check is always on; you don't have to set it up.

Your text is checked for the following secret types:

- GitLab [personal access tokens](../../../../security/token_overview.md#personal-access-tokens)
  - If a [personal access token prefix](../../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix) has been configured, a token using this prefix is checked.
- GitLab [feed tokens](../../../../security/token_overview.md#feed-token)

## Related topics

- [Push rules](../../../project/repository/push_rules.md)
