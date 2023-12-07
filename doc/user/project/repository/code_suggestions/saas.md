---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Suggestions on GitLab SaaS **(FREE SAAS BETA)**

> - [Introduced](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#code-suggestions-available-in-closed-beta) in GitLab 15.9 as [Beta](../../../../policy/experiment-beta-support.md#beta) for early access Ultimate customers on GitLab.com.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/408104) as opt-in with GitLab 15.11 as [Beta](../../../../policy/experiment-beta-support.md#beta).
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/408158) from GitLab Ultimate to GitLab Premium in 16.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/410801) from GitLab Premium to GitLab Free in 16.0.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121079) in GitLab 16.1.

Write code more efficiently by using generative AI to suggest code while you're developing.

Usage of GitLab Duo Code Suggestions is governed by the [GitLab Testing Agreement](https://about.gitlab.com/handbook/legal/testing-agreement/).
Learn about [data usage when using Code Suggestions](index.md#code-suggestions-data-usage).

## Enable Code Suggestions

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121079) in GitLab 16.1 as [Beta](../../../../policy/experiment-beta-support.md#beta).

You must enable Code Suggestions for both your user account and your top-level group:

- [Enable Code Suggestions for your top-level group](../../../group/manage.md#enable-code-suggestions) (you must be a group owner).
- [Enable Code Suggestions for your own account](../../../profile/preferences.md#enable-code-suggestions).

NOTE:
If you are having issues enabling Code Suggestions, view the
[troubleshooting guide](troubleshooting.md#code-suggestions-arent-displayed).

## Use Code Suggestions

Prerequisites:

- You must have a [supported IDE editor extension](index.md#supported-editor-extensions).
- Code Suggestions must be enabled for:
  - [The top-level group](../../../group/manage.md#enable-code-suggestions).
  - [Your own account](../../../profile/preferences.md#enable-code-suggestions).

To use Code Suggestions:

1. Author your code. As you type, suggestions are displayed.
   Code Suggestions provide code snippets or complete the current line, depending on the cursor position.
1. Describe the requirements in natural language. Be concise and specific. Code Suggestions generates functions and code snippets as appropriate.
1. To accept a suggestion, press <kbd>Tab</kbd>.
1. To ignore a suggestion, keep typing as you usually would.
1. To explicitly reject a suggestion, press <kbd>Esc</kbd>.

Things to remember:

- AI is non-deterministic, so you may not get the same suggestion every time with the same input.
- Just like product requirements, writing clear, descriptive, and specific tasks results in quality generated code.
