---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Extend the features of GitLab to Visual Studio Code, JetBrains IDEs, Visual Studio, and Neovim."
title: Editor Extensions
---

GitLab Editor Extensions bring the power of GitLab and GitLab Duo directly into your preferred
development environments. Use GitLab features and GitLab Duo AI capabilities to handle everyday tasks
without leaving your editor. For example:

- Manage your projects.
- Write and review code.
- Track issues.
- Optimize pipelines.

Our extensions boost your productivity and elevate your development process by bridging the gap
between your coding environment and GitLab.

## Available extensions

GitLab offers extensions for the following development environments:

- [GitLab Workflow extension for VS Code](visual_studio_code/_index.md): Bring GitLab Duo,
  and other GitLab features, into Visual Studio Code.
- [GitLab Duo for JetBrains IDEs](jetbrains_ide/_index.md): Bring GitLab Duo AI capabilities
  to IntelliJ IDEA, PyCharm, WebStorm, and other JetBrains IDEs.
- [GitLab Extension for Visual Studio](visual_studio/_index.md): Bring GitLab Duo Code Suggestions to Visual Studio.

If you prefer a command-line interface, try:

- [`glab`](gitlab_cli/_index.md) the GitLab CLI.
- [GitLab.nvim for Neovim](neovim/_index.md): Bring GitLab Duo Code Suggestions directly to Neovim in your terminal window.

## Features

Our editor extensions offer powerful GitLab Duo integration, with Visual Studio Code and `glab` featuring
an integrated GitLab workflow experience.

### GitLab Duo Code Suggestions

[GitLab Duo Code Suggestions](../user/project/repository/code_suggestions/_index.md) provide AI-assisted coding capabilities:

- **Code completion**: Suggests completions to the current line you are typing.
  Use it to complete one or a few lines of code.
- **Code generation**: Generates code based on a natural language code comment block.
  Write a comment, then press <kbd>Enter</kbd> to generate code based on the context of your
  comment, and the rest of your code.
- **Context-aware suggestions**: Uses open files in your IDE, content before and after the cursor,
  filename, and extension type to provide relevant suggestions.
- **Support for multiple languages**: Works with various programming languages supported by your development environment.

### GitLab Duo Chat

Use [GitLab Duo Chat](../user/gitlab_duo_chat/_index.md) to interact with an AI assistant directly in your development environment.

- **Ask about GitLab**: Get answers about how GitLab works, concepts, and step-by-step instructions.
- **Code-related queries**: Ask for explanations of code snippets, generate tests, or refactor selected code in your IDE.

## Feedback and contributions

We value your input on both the traditional and AI-powered features. If you have suggestions, encounter issues,
or want to contribute to the development of our extensions:

- Report issues in their GitLab projects.
- Submit feature requests by creating a new issue in the
  [Editor Extensions project](https://gitlab.com/gitlab-org/editor-extensions/product/-/issues/).
- Submit merge requests in the respective GitLab projects.

## Related topics

- [How we created a GitLab Workflow Extension for VS Code](https://about.gitlab.com/blog/2020/07/31/use-gitlab-with-vscode/)
- [GitLab for Visual Studio](https://about.gitlab.com/blog/2023/06/29/gitlab-visual-studio-extension/)
- [GitLab for JetBrains and Neovim](https://about.gitlab.com/blog/2023/07/25/gitlab-jetbrains-neovim-plugins/)
- [Put `glab` at your fingertips with the GitLab CLI](https://about.gitlab.com/blog/2022/12/07/introducing-the-gitlab-cli/)
