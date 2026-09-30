---
stage: AI Coding
group: DAP Repository Flows
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Set up Code Suggestions in your IDE.
title: Set up Code Suggestions
---

GitLab Duo Code Suggestions is available for use through an editor extension in your IDE.

## Prerequisites

- GitLab Duo Core [turned on](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off).
- A [supported language and IDE](supported_extensions.md).
- A [default GitLab Duo namespace](../../../profile/preferences.md#namespace-resolution-in-your-local-environment)
  set, or a project open that has GitLab Duo access.

## Configure an editor extension

To use Code Suggestions, install the extension for your IDE, then authenticate and configure it for
GitLab Duo. Code Suggestions is on by default.

- [Visual Studio Code](../../../../editor_extensions/visual_studio_code/setup.md)
- [GitLab Duo plugin for JetBrains IDEs](../../../../editor_extensions/jetbrains_ide/setup.md)
- [Visual Studio](../../../../editor_extensions/visual_studio/setup.md)
- [`gitlab.vim` plugin for Neovim](../../../../editor_extensions/neovim/setup.md)
- [GitLab for Eclipse](../../../../editor_extensions/eclipse/setup.md)

In the GitLab Web IDE, Code Suggestions does not require additional configuration.
You can [start using Code Suggestions](_index.md#use-code-suggestions) right away.

## Verify that Code Suggestions is on

All editor extensions from GitLab, except Neovim, add an icon to your IDE's status bar. Check the icon to verify that suggestions are working.

For example, in Visual Studio:

![The status bar in Visual Studio.](img/visual_studio_status_bar_v17_4.png)

| Icon | Status | Meaning |
| :--- | :----- | :------ |
| {{< icon name="tanuki-ai" >}} | **Ready** | You've configured and enabled GitLab Duo, and you're using a language that supports Code Suggestions. |
| {{< icon name="tanuki-ai-off" >}} | **Not configured** | You haven't entered a personal access token, or you're using a language that Code Suggestions doesn't support. |
| ![The status icon for fetching Code Suggestions.](img/code_suggestions_loading_v17_4.svg) | **Loading suggestion** | GitLab Duo is fetching Code Suggestions for you. |
| ![The status icon for a Code Suggestions error.](img/code_suggestions_error_v17_4.svg) | **Error** | GitLab Duo has encountered an error. |
