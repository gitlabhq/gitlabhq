---
stage: AI-powered
group: Code Creation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
description: Code Suggestions documentation for developers interested in contributing features or bugfixes.
title: Code Suggestions development guidelines
---

## Code Suggestions development setup

The recommended setup for locally developing and debugging Code Suggestions is to have all 3 different components running:

- IDE Extension (for example, GitLab Workflow extension for VS Code).
- Main application configured correctly (for example, GDK).
- [AI gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist).

This should enable everyone to locally see how any change made in an IDE is sent to the main application to be transformed into a prompt before being sent to the respective model.

### Setup instructions

1. Install and locally run the [GitLab Workflow extension for VS Code](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CONTRIBUTING.md#configuring-development-environment):
   1. Add the `"gitlab.debug": true` info to the Code Suggestions development config:
      1. In VS Code, go to the Extensions page and find "GitLab Workflow" in the list.
      1. Open the extension settings by clicking a small cog icon and select "Extension Settings" option.
      1. Check a "GitLab: Debug" checkbox.
   1. If you'd like to test that Code Suggestions is working from inside the GitLab Workflow extension for VS Code, then follow the [authenticate with GitLab steps](../../editor_extensions/visual_studio_code/setup.md#authenticate-with-gitlab) with your GDK inside the new window of VS Code that pops up when you run the "Run and Debug" command.
      - Once you complete the steps below, to test you are hitting your local `/code_suggestions/completions` endpoint and not production, follow these steps:
        1. Inside the new window, in the built in terminal select the "Output" tab then "GitLab Language Server" from the drop down menu on the right.
        1. Open a new file inside of this VS Code window and begin typing to see Code Suggestions in action.
        1. You will see completion request URLs being fetched that match the Git remote URL for your GDK.

### Setup instructions to use GDK with the Code Suggestions

See the [instructions for setting up GitLab Duo features in the local development environment](_index.md)

### Bulk assign users to Duo Pro/Duo Enterprise add-on

After purchasing the Duo add-on, existing eligible users can be assigned/un-assigned to the Duo `add_on_purchase` in bulk. There are a few ways to perform this action, that apply for both GitLab.com and GitLab Self-Managed instances,

1. [Duo users management UI](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats)
1. [GraphQL endpoint](../../api/graphql/assign_gitlab_duo_seats.md)
1. [Rake task](../../administration/raketasks/user_management.md#bulk-assign-users-to-gitlab-duo)

The above methods make use of the [BulkAssignService](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/services/gitlab_subscriptions/duo/bulk_assign_service.rb)/[BulkUnassignService](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/services/gitlab_subscriptions/duo/bulk_unassign_service.rb), which evaluates eligibility criteria preliminarily before assigning/un-assigning the passed users in a single SQL operation.

### Setting up Duo on your staging GitLab.com account

For more information, see [setting up Duo on your GitLab.com staging account](ai_development_license.md#setting-up-gitlab-duo-for-your-staging-gitlabcom-user-account).

### Video demonstrations of installing and using Code Suggestions in IDEs

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For more guidance, see the following video demonstrations of installing
and using Code Suggestions in:

- [VS Code](https://www.youtube.com/watch?v=bJ7g9IEa48I).
  <!-- Video published on 2024-09-03 -->
- [IntelliJ IDEA](https://www.youtube.com/watch?v=WE9agcnGT6A).
  <!-- Video published on 2024-09-03 -->
