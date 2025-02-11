---
stage: AI-powered
group: AI Framework
description: AI-powered features and functionality.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Get started with GitLab Duo
---

GitLab Duo is your AI-powered assistant. It can help you write, review, and edit code,
along with a variety of other tasks throughout your GitLab workflow.
It can help you troubleshoot your pipeline, write tests, address vulnerabilities, and more.

## Step 1: Ensure you have a subscription

Your organization has purchased a GitLab Duo add-on subscription: either Duo Pro or Duo Enterprise.
Each subscription includes a set of AI-powered features to help improve your workflow.

After your organization purchases a subscription, an administrator must assign seats to users.
You likely received an email that notified you of your seat.

The AI-powered features you have access to use language models to help streamline
your workflow. If you're on GitLab Self-Managed, your administrator can choose to use
GitLab models, or self-host their own models.

If you have issues accessing GitLab Duo features, ask your administrator.
They can check the health of the installation.

For more information, see:

- [Assign seats to users](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).
- [Features included in Duo Pro and Duo Enterprise](https://about.gitlab.com/gitlab-duo/#pricing).
- [List of GitLab Duo features and their language models](../gitlab_duo/_index.md).
- [Self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md).
- [Health check details](../gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo).

## Step 2: Try GitLab Duo Chat in the UI

Confirm that Chat is available in the GitLab UI.

Go to a project and in the upper-right corner, a button named **Ask Duo Chat** should be displayed.
If this button is available, it means everything is configured properly.
Try asking Chat a question or type `/` to see a list of slash commands.

For more information, see:

- [GitLab Duo Chat](../gitlab_duo_chat/_index.md).

## Step 3: Try other GitLab Duo features

GitLab Duo is available in all stages of your workflow. From troubleshooting
CI/CD pipelines to writing test cases and resolving security threats, GitLab Duo can help you
in a variety of ways.

If you want to test a feature, you can go to one of your failed CI/CD jobs and at the bottom
of the page, select **Troubleshoot**.

Or, in an issue that has a lot of comments, in the **Activity** section, select **View summary**.
GitLab Duo summarizes the contents of the issue.

For more information, see:

- [The complete list of GitLab Duo features](../gitlab_duo/_index.md).
- [Turn on GitLab Duo features that are still in development](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).

## Step 4: Prepare to use GitLab Duo in your IDE

To use GitLab Duo, including Code Suggestions, in your IDE:

- Install an extension in your local IDE.
- Authenticate with GitLab from the IDE. You can use either OAuth or a personal access token.

Then you can confirm that GitLab Duo is available in your IDE and test some of the features.

Alternately, you can use the Web IDE, which is included in the GitLab UI and already fully configured.

For more information, see:

- [Set up the extension for VS Code](../../editor_extensions/visual_studio_code/setup.md).
- [Set up the extension for JetBrains](../../editor_extensions/jetbrains_ide/setup.md).
- [Set up the extension for Visual Studio](../../editor_extensions/visual_studio/setup.md).
- [Set up the extension for Neovim](../../editor_extensions/neovim/setup.md).
- [Use the Web IDE](../project/web_ide/_index.md).

## Step 5: Confirm that Code Suggestions is on in your IDE

Finally, go to the settings for the extension and confirm that Code Suggestions is enabled,
as well as the languages you want suggestions for.

You should also confirm that Chat is enabled.

Then test Code Suggestions and Chat in your IDE.

- Code Suggestions recommends code as you type.
- Chat is available to ask questions about your code or anything else you need.

For more information, see:

- [Supported extensions and languages](../project/repository/code_suggestions/supported_extensions.md).
- [Turn on Code Suggestions](../project/repository/code_suggestions/set_up.md#turn-on-code-suggestions).
- [Troubleshoot GitLab Workflow extension for VS Code](../../editor_extensions/visual_studio_code/troubleshooting.md).
- [Troubleshoot GitLab plugin for JetBrains IDEs](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md).
- [Troubleshoot GitLab extension for Visual Studio](../../editor_extensions/visual_studio/visual_studio_troubleshooting.md).
- [Troubleshoot GitLab plugin for Neovim](../../editor_extensions/neovim/neovim_troubleshooting.md).
