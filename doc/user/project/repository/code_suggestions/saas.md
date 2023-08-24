---
stage: AI-powered
group: AI Model Validation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, reference
---

# Code Suggestions on GitLab SaaS (Beta) **(FREE SAAS)**

> - [Introduced](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#code-suggestions-available-in-closed-beta) in GitLab 15.9 as [Beta](../../../../policy/experiment-beta-support.md#beta) for early access Ultimate customers on GitLab.com.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/408104) as opt-in with GitLab 15.11 as [Beta](../../../../policy/experiment-beta-support.md#beta).
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/408158) from GitLab Ultimate to GitLab Premium in 16.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/410801) from GitLab Premium to GitLab Free in 16.0.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121079) in GitLab 16.1.

Write code more efficiently by using generative AI to suggest code while you're developing.

Usage of Code Suggestions is governed by the [GitLab Testing Agreement](https://about.gitlab.com/handbook/legal/testing-agreement/).
Learn about [data usage when using Code Suggestions](index.md#code-suggestions-data-usage).

## Enable Code Suggestions for a group

You can enable Code Suggestions [for all members of a group](../../../group/manage.md#enable-code-suggestions).

## Enable Code Suggestions for an individual user

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121079) in GitLab 16.1 as [Beta](../../../../policy/experiment-beta-support.md#beta).

If Code Suggestions is not enabled for the group, each user can still enable Code Suggestions for themselves:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. In the **Code Suggestions** section, select the **Enable Code Suggestions** checkbox.
1. Select **Save changes**.

If Code Suggestions is enabled for the group, the group setting overrides the user setting.

NOTE:
This setting controls Code Suggestions for all IDEs. Support for [more granular control per IDE](https://gitlab.com/groups/gitlab-org/-/epics/10624) is proposed.

## Use Code Suggestions

Prerequisites:

- Code Suggestions must be enabled [for the top-level group](../../../group/manage.md#enable-code-suggestions) and [for your user account](#enable-code-suggestions-for-an-individual-user).
- You must have installed and configured a [supported IDE editor extension](index.md#supported-editor-extensions).

To use Code Suggestions:

1. Author your code. As you type, suggestions are displayed. Depending on the cursor position, the extension either:

   - Provides entire code snippets, like generating functions.
   - Completes the current line.

1. To accept a suggestion, press <kbd>Tab</kbd>.

Suggestions are best when writing new code. Editing existing functions or 'fill in the middle' of a function may not perform as expected.

GitLab is making improvements to the Code Suggestions to improve the quality. AI is non-deterministic, so you may not get the same suggestion every time with the same input.

This feature is currently in [Beta](../../../../policy/experiment-beta-support.md#beta).
Code Suggestions depends on both Google Vertex AI Codey APIs and the GitLab Code Suggestions service. We have built this feature to gracefully degrade and have controls in place to allow us to
mitigate abuse or misuse. GitLab may disable this feature for any or all customers at any time at our discretion.
