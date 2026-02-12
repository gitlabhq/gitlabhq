---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Extend the features of GitLab to Visual Studio Code, JetBrains IDEs, Visual Studio, Eclipse, and Neovim.
title: Editor extensions
---

GitLab editor extensions bring the power of GitLab and GitLab Duo directly into your preferred
development environments. Use GitLab features and GitLab Duo AI capabilities to handle everyday tasks
without leaving your editor. For example:

- Manage your projects.
- Write and review code.
- Track issues.
- Optimize pipelines.

Our extensions boost your productivity and elevate your development process by bridging the gap
between your coding environment and GitLab.

## Available extensions

GitLab offers the following IDE extensions with access to GitLab Duo and other GitLab features used
to manage projects and applications.

| Extension                                                       | GitLab Duo Chat       | Code Suggestions | Software Development<br>Flow | Other GitLab features |
|-----------------------------------------------------------------|-----------------------|-----------------------------|-----------------------|---------------------------|
| [GitLab for VS Code](visual_studio_code/_index.md)              | {{< yes >}}           | {{< yes >}}                 | {{< yes >}}               | {{< yes >}}           |
| [GitLab Duo plugin for JetBrains IDEs](jetbrains_ide/_index.md) | {{< yes >}}           | {{< yes >}}                 | {{< yes >}}               | {{< no >}}            |
| [GitLab extension for Visual Studio](visual_studio/_index.md)   | {{< yes >}}           | {{< yes >}}                 | {{< yes >}}               | {{< no >}}            |
| [GitLab for Eclipse plugin](eclipse/_index.md)                  | {{< yes >}} (Classic) | {{< yes >}}                 | {{< no >}}                | {{< no >}}            |

If you prefer a command-line interface, try the following:

| Extension                                                      | GitLab Duo Chat       | Code Suggestions | Software Development<br>Flow | Other GitLab features |
|----------------------------------------------------------------|-----------------------|-----------------------------|-----------------------|---------------------------|
| [The GitLab CLI (`glab`)](gitlab_cli/_index.md)                | {{< yes >}} (Classic) | {{< no >}}                  | {{< no >}}                | {{< yes >}}           |
| [The GitLab Duo CLI (`duo`)](../user/gitlab_duo_cli/_index.md) | {{< yes >}} (Agentic) | {{< no >}}                  | {{< no >}}                | {{< no >}}            |
| [GitLab.nvim for Neovim](neovim/_index.md)                     | {{< no >}}            | {{< yes >}}                 | {{< no >}}                | {{< no >}}            |

## Security considerations

To learn about the security risks of running agents locally in editor extensions and how to protect
your local development environment, see [security considerations for editor extensions](security_considerations.md).

## Editor extensions team runbook

Use the [editor extensions team runbook](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/editor-extensions)
to learn more about debugging all supported editor extensions. For internal users, this runbook contains instructions
for requesting internal help.

## Feedback and contributions

We value your input on both the traditional and AI-native features. If you have suggestions, encounter issues,
or want to contribute to the development of our extensions:

- Report issues in their GitLab projects.
- Submit feature requests by creating a new issue in the
  [`editor-extensions` project](https://gitlab.com/gitlab-org/editor-extensions/product/-/issues/).
- Submit merge requests in the respective GitLab projects.

## Related topics

- [GitLab Duo Agent Platform](../user/duo_agent_platform/_index.md)
- [GitLab Duo (Classic)](../user/gitlab_duo/feature_summary.md)
- [How we created a GitLab Workflow Extension for VS Code](https://about.gitlab.com/blog/use-gitlab-with-vscode/)
- [GitLab for Visual Studio](https://about.gitlab.com/blog/gitlab-visual-studio-extension/)
- [GitLab for JetBrains and Neovim](https://about.gitlab.com/blog/gitlab-jetbrains-neovim-plugins/)
- [Put `glab` at your fingertips with the GitLab CLI](https://about.gitlab.com/blog/introducing-the-gitlab-cli/)
