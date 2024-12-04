---
stage: AI-powered
group: AI Framework
description: AI-powered features and functionality.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Get started with GitLab Duo

GitLab Duo is your AI-powered assistant. It can help you write, review, and edit code,
along with a variety of other tasks throughout your GitLab workflow.
It can help you troubleshoot your pipeline, write tests, address vulnerabilities, and more.

## Step 1: Ensure you have a subscription

Your organization has purchased a GitLab Duo add-on subscription: either Duo Pro or Duo Enterprise.
Each subscription includes a set of AI-powered features to help improve your workflow.

After your organization purchases a subscription, an administrator must assign seats to users.
You likely received an email that notified you of your seat.

The AI-powered features you have access to use language models to help streamline
your workflow. If you're on self-managed GitLab, your administrator can choose to use
GitLab models, or self-host their own models.

If you have issues accessing GitLab Duo features, ask your administrator.
They can check the health of the installation.

For more information, see:

- [Assign seats to users](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).
- [Features included in Duo Pro and Duo Enterprise](https://about.gitlab.com/gitlab-duo/#pricing).
- [List of GitLab Duo features and their language models](../gitlab_duo/index.md).
- [Self-hosted models](../../administration/self_hosted_models/index.md).
- [Health check details](../gitlab_duo/turn_on_off.md#run-a-health-check-for-gitlab-duo).

## Step 2: Try Duo Chat in the UI

Confirm that Duo Chat is available in the GitLab UI.

Go to a project and in the upper-right corner, a button named **Ask Duo Chat** should be displayed.
If this button is available, it means everything is configured properly.
Try asking Duo Chat a question or type `/` to see a list of slash commands.

For more information, see:

- [GitLab Duo Chat](../gitlab_duo_chat/index.md).

## Step 3: Try other GitLab Duo features

GitLab Duo is available at different points in your workflow. From troubleshooting
CI/CD pipelines to writing test cases and reviewing code, GitLab Duo can help you
in a variety of ways.

If you want to test a feature, you can go to a failed CI/CD job and at the bottom
of the page, select **Troubleshoot**.

Or, in an issue that has a lot of comments, in the **Activity** section, select **View summary**.
GitLab Duo summarizes the contents of the issue.

For more information, see:

- [The complete list of GitLab Duo features](../gitlab_duo/index.md).
- [Turn on GitLab Duo features that are still in development](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features).

## Step 4: Prepare to use GitLab Duo in your IDE

To use GitLab Duo, including Code Suggestions, in your IDE, you must:

- Install an extension in your IDE.
- Authenticate with GitLab from the IDE. You can use either OAuth or a personal access token.

Then you can confirm that GitLab Duo is available in your IDE and test some of the features.

For more information, see:

- [Set up the extension for VS Code](../../editor_extensions/visual_studio_code/index.md).
- [Set up the extension for JetBrains](../../editor_extensions/jetbrains_ide/index.md).
- [Set up the extension for Visual Studio](../../editor_extensions/visual_studio/index.md).
- [Set up the extension for Neovim](../../editor_extensions/neovim/index.md).

## Step 5: Turn on Code Suggestions in your IDE

Finally, go to the settings for the extension and confirm that Code Suggestions is enabled,
as well as the languages you want suggestions for.

You should also confirm that Duo Chat is enabled.

Then test Code Suggestions and Duo Chat in your IDE.

- Code Suggestions recommends code as you type.
- Duo Chat is available to ask questions about your code or anything else you need.

For more information, see:

- [Supported extensions and languages](../project/repository/code_suggestions/supported_extensions.md).
- [Code Suggestions](../project/repository/code_suggestions/index.md#use-code-suggestions).
