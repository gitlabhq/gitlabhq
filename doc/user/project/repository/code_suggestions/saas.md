---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Suggestions on GitLab SaaS **(FREE SAAS)**

> - [Introduced](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#code-suggestions-available-in-closed-beta) in GitLab 15.9 as [Beta](../../../../policy/experiment-beta-support.md#beta) for early access Ultimate customers on GitLab.com.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/408104) as opt-in with GitLab 15.11 as [Beta](../../../../policy/experiment-beta-support.md#beta).
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/408158) from GitLab Ultimate to GitLab Premium in 16.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/410801) from GitLab Premium to GitLab Free in 16.0.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121079) in GitLab 16.1.

Write code more efficiently by using generative AI to suggest code while you're developing.

Usage of GitLab Duo Code Suggestions is governed by the [GitLab Testing Agreement](https://about.gitlab.com/handbook/legal/testing-agreement/).
Learn about [data usage when using Code Suggestions](index.md#code-suggestions-data-usage).

## Enable Code Suggestions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121079) in GitLab 16.1 as [Beta](../../../../policy/experiment-beta-support.md#beta).
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139916) in GitLab 16.8. Available to a percentage of users.

A group owner must
[enable Code Suggestions for your top-level group](../../../group/manage.md#enable-code-suggestions-for-a-group).

NOTE:
If you are having issues enabling Code Suggestions, view the
[troubleshooting guide](troubleshooting.md#code-suggestions-arent-displayed).

## Use Code Suggestions

Prerequisites:

- You must have configured Code Suggestions in a
  [supported IDE editor extension](index.md#supported-editor-extensions).
- Code Suggestions must be enabled for:
  - [The top-level group](../../../group/manage.md#enable-code-suggestions-for-a-group).
  - [Your own account](../../../profile/preferences.md#enable-code-suggestions), if your
    account is not part of the percentage rollout.

To use Code Suggestions:

1. Determine if your user account is part of the percentage rollout. See
   [Enable Code Suggestions](../../../profile/preferences.md#enable-code-suggestions)
   for more information.
1. Author your code. As you type, suggestions are displayed.
   Code Suggestions provide code snippets or complete the current line, depending on the cursor position.
1. Describe the requirements in natural language. Be concise and specific. Code Suggestions generates functions and code snippets as appropriate.
1. To accept a suggestion, press <kbd>Tab</kbd>.
1. To ignore a suggestion, keep typing as you usually would.
1. To explicitly reject a suggestion, press <kbd>Esc</kbd>.

Things to remember:

- AI is non-deterministic, so you may not get the same suggestion every time with the same input.
- Just like product requirements, writing clear, descriptive, and specific tasks results in quality generated code.

## Disable Code Suggestions

Individual users can disable Code Suggestions by disabling the feature in their
[installed IDE editor extension](index.md#supported-editor-extensions).
