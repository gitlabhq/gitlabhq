---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Suggestions on GitLab SaaS

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** SaaS

> - [Introduced](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#code-suggestions-available-in-closed-beta) in GitLab 15.9 as [Beta](../../../../policy/experiment-beta-support.md#beta) for early access Ultimate customers on GitLab.com.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/408104) as opt-in with GitLab 15.11 as [Beta](../../../../policy/experiment-beta-support.md#beta).
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/408158) from GitLab Ultimate to GitLab Premium in 16.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/410801) from GitLab Premium to GitLab Free in 16.0.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121079) in GitLab 16.1.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/435271) in GitLab 16.7.

Get started using Code Suggestions in your IDE. These instructions apply to users
of GitLab SaaS.

Prerequisites:

- You must be using [one of the supported IDE extensions](index.md#supported-editor-extensions).
- Code Suggestions must be enabled [for the top-level group](#enable-code-suggestions).

To use Code Suggestions:

1. Author your code.
   As you type, suggestions are displayed. Code Suggestions provide code snippets
   or completes the current line, depending on the cursor position.

1. Describe the requirements in natural language.
   Code Suggestions generates functions and code snippets based on the context provided.

1. To accept a suggestion, press <kbd>Tab</kbd>. To reject a suggestion, press <kbd>Esc</kbd>.
1. To ignore a suggestion, keep typing as you usually would.

## Best practices

To get the best results from code generation:

- Be as specific as possible while remaining concise.
- State the outcome you want to generate (for example, a function)
  and provide details on what you want to achieve.
- Add additional information, like the framework or library you want to use.
- Add a space or new line after each comment.
  This space tells the code generator that you have completed your instructions.

For example, to create a Python web service with some specific requirements,
you might write something like:

```plaintext
# Create a web service using Tornado that allows a user to log in, run a security scan, and review the scan results.
# Each action (log in, run a scan, and review results) should be its own resource in the web service
...
```

AI is non-deterministic, so you may not get the same suggestion every time with the same input.
To generate quality code, write clear, descriptive, specific tasks.

## Enable Code Suggestions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/405126) in GitLab 15.11.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/408158) from GitLab Ultimate to GitLab Premium in 16.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/410801) from GitLab Premium to GitLab Free in 16.0.

Code Suggestions are enabled by default at the group level.
This setting cascades to all subgroups and projects in the group.

To update this setting:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **Code Suggestions**, select the **Projects in this group can use Code Suggestions** checkbox.
1. Select **Save changes**.

If you have issues enabling Code Suggestions, view the
[troubleshooting guide](troubleshooting.md#code-suggestions-are-not-displayed).

## Disable Code Suggestions for an individual user

To disable Code Suggestions, you can disable the feature in your IDE editor extension.
