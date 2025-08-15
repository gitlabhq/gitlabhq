---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platform authentication and authorization
---

GitLab Duo Agent Platform uses a service account to perform actions on behalf of a user.

The token that authenticates requests is a composite of two identities:

- The primary author, which is the Duo Agent Platform [service account](../profile/service_accounts.md).
  This service account is instance-wide and has the Developer role
  on the project where the Duo Agent Platform was used. The service account is the owner of the token.
- The secondary author, which is the human user who submitted the quick action.
  This user's `id` is included in the scopes of the token.

This composite identity ensures that any activities authored by Duo Agent Platform are
correctly attributed to the Duo Agent Platform service account.
At the same time, the composite identity ensures that there is no
[privilege escalation](https://en.wikipedia.org/wiki/Privilege_escalation) for the human user.

This [dynamic scope](https://github.com/doorkeeper-gem/doorkeeper/pull/1739)
is checked during the authorization of the API request.
When authorization is requested, GitLab validates that both the service account
and the user who originated the quick action have sufficient permissions.
