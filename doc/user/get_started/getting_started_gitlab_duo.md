---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: AI-native features and functionality.
title: Get started with GitLab Duo
---

GitLab Duo is your AI-native assistant. It can help you write, review, and edit code,
along with a variety of other tasks throughout your GitLab workflow.
It can help you troubleshoot your pipeline, write tests, address vulnerabilities, and more.

## Step 1: Ensure you have access to GitLab Duo

To get started with GitLab Duo, your organization must have a Premium or Ultimate subscription
and a GitLab Duo add-on.

Your add-on determines the GitLab Duo features you have access to.

- The GitLab Duo Core add-on comes with all Premium and Ultimate subscriptions.
- The GitLab Duo Pro and GitLab Duo Enterprise add-ons are available for purchase.

For GitLab Duo features, your organization can use the GitLab default language models
or host their own models by using GitLab Duo Self-Hosted.

If you have issues accessing GitLab Duo features, your administrators
can check the health of the installation.

For more information, see:

- [GitLab Duo features by add-on](../gitlab_duo/_index.md#summary-of-gitlab-duo-features).
- [How to purchase an add-on](../../subscriptions/subscription-add-ons.md).
- [GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md).
- [Health check details](../gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo).

## Step 2: Try GitLab Duo Chat in the UI

If your organization has either the GitLab Duo Pro or Enterprise add-on,
you can try using Chat in the GitLab UI.

Go to a project and in the upper-right corner, a button named **GitLab Duo Chat** should be displayed.
If this button is available, it means everything is configured properly.
Try asking Chat a question or type `/` to see a list of slash commands.

For more information, see:

- [GitLab Duo Chat](../gitlab_duo_chat/_index.md).

## Step 3: Try other GitLab Duo features

GitLab Duo is available in all stages of your workflow. From troubleshooting
CI/CD pipelines to writing test cases and resolving security threats, GitLab Duo can help you
in a variety of ways.

The features you have access to differ depending on your subscription tier, add-on, and offering.

For example, if you have access to:

- Root Cause Analysis, you can go to one of your failed CI/CD jobs and at the bottom
  of the page, select **Troubleshoot**.

- Discussion Summary, in the **Activity** section of an issue with a lot of comments,
  select **View summary**. GitLab Duo summarizes the contents of the issue.

For more information, see:

- [The complete list of GitLab Duo features](../gitlab_duo/_index.md).
- [Turn on GitLab Duo features that are still in development](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).

## Step 4: Prepare to use GitLab Duo in your IDE

Now you can try GitLab Duo features, like GitLab Duo Chat and Code Suggestions, in your IDE.

To use GitLab Duo Chat in your IDE, you'll install an extension and authenticate with GitLab.

- In GitLab 17.11 and earlier, you'll need the GitLab Duo Pro or Enterprise add-on.
- In 18.0 and later, you'll need to turn on GitLab Duo,
  and have the GitLab Duo Core, Pro, or Enterprise add-on.
  GitLab Duo Core is included with all Premium and Ultimate subscriptions.

Alternatively, if you have GitLab Duo Pro or Enterprise, you can use the Web IDE,
which is included in the GitLab UI and already fully configured.

For more information, see:

- [Turn on GitLab Duo](../gitlab_duo/turn_on_off.md).
- [Set up the extension for VS Code](../../editor_extensions/visual_studio_code/setup.md).
- [Set up the extension for JetBrains](../../editor_extensions/jetbrains_ide/setup.md).
- [Set up the extension for Visual Studio](../../editor_extensions/visual_studio/setup.md).
- [Set up the extension for Neovim](../../editor_extensions/neovim/setup.md).
- [Use the Web IDE](../project/web_ide/_index.md).

## Step 5: Start using Code Suggestions and Chat in your IDE

Finally, test Code Suggestions and Chat in your IDE.

- Code Suggestions recommends code as you type.
- Chat is available to ask questions about your code or anything else you need.

You can choose the languages you want suggestions for.

For more information, see:

- [Supported extensions and languages](../project/repository/code_suggestions/supported_extensions.md).
- [Turn on Code Suggestions](../project/repository/code_suggestions/set_up.md#turn-on-code-suggestions).
- [Troubleshoot GitLab Workflow extension for VS Code](../../editor_extensions/visual_studio_code/troubleshooting.md).
- [Troubleshoot GitLab plugin for JetBrains IDEs](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md).
- [Troubleshoot GitLab extension for Visual Studio](../../editor_extensions/visual_studio/visual_studio_troubleshooting.md).
- [Troubleshoot GitLab plugin for Neovim](../../editor_extensions/neovim/neovim_troubleshooting.md).
