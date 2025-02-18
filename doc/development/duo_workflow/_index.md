---
stage: AI-powered
group: Duo Workflow
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Development of GitLab Duo Workflow
---

This guide describes how to set up the local development environment for the various projects that make up [GitLab Duo Workflow](../../user/duo_workflow/_index.md).

## Prerequisites

- Vertex API access
  - You need access to the `ai-enablement-dev-69497ba7` project in GCP. This should by available to all engineers at GitLab.
- Docker
  - See which Docker tooling is approved for GitLab team members in the [handbook](https://handbook.gitlab.com/handbook/tools-and-tips/mac/#docker-desktop).

## Set up local development for Workflow

Workflow consists of four separate services:

1. [GitLab instance](https://gitlab.com/gitlab-org/gitlab/)
1. [GitLab Duo Workflow Service](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-service)
1. [GitLab Duo Workflow Executor](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-executor/)
1. [GitLab Duo Workflow Webview](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/webview_duo_workflow/README.md)

### GDK Setup

We recommend [setting up GitLab Duo Workflow directly with the GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/duo_workflow.md?ref_type=heads)
for setting up local versions of GitLab, the GitLab Duo Workflow Service and Executor.

This setup can be used with the [publicly available version of the VS Code Extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).
Follow [these instructions](#gitlab-duo-workflow-ui-in-visual-studio-code-vs-code) to see the GitLab Duo Workflow UI local build in VS Code if you want to actively need to develop it or use an unreleased version.

### Manual Setup

#### GitLab Duo Workflow UI in Visual Studio Code (VS Code)

There is no need for the GDK, Workflow service or Workflow executor local build to test the GitLab Duo Workflow UI.
Only set these up if you are making changes to one of these packages and need to test their integration with the GitLab Duo Workflow UI in VS Code.
Please refer to the [GitLab Duo Workflow README.md](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/webview_duo_workflow/README.md) file in the Language Server project to get started with local development of GitLab Duo Workflow UI.

#### Set up your local GitLab instance

1. Configure the GitLab Duo Workflow Service URL in your local GitLab instance by updating the `config/gitlab.yml` file:

   ```dotenv
   development:
     duo_workflow:
       service_url: 0.0.0.0:50052
       secure: false
   ```

1. Restart the GitLab instance.

   ```shell
   gdk restart rails
   ```

1. In your local GitLab instance, enable the `duo_workflow` feature flag from the Rails console:

   ```ruby
   Feature.enable(:duo_workflow)
   ```

1. Set up [GitLab Runner with GDK](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/runner.md) so you can create CI jobs locally to test Workflow.
1. Create a [personal access token](../../user/profile/personal_access_tokens.md) in your local GitLab instance with the `api` scope. Save this value and use it in the next step.
1. Run GDK with an Ultimate license.
1. If you're running GitLab in SaaS mode, you'll need to turn on the `beta and experimental features` functionality, as they are [turned off by default](../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features). In the group settings for the project you'll run workflow against, ensure that the `Use experiment and beta Duo features` checkbox is checked.
1. Manually create a Workflow using the following `curl` request; the output will be a workflow ID that is referred to as `$WORKFLOW_ID` throughout the rest of these docs:

   ```shell
   curl POST --verbose \
     --header "Authorization: Bearer $YOUR_GITLAB_PAT" \
     --header 'Content-Type: application/json' \
     --data '{
        "project_id": "$PROJECT_ID_FOR_RUNNING_WORKFLOW_AGAINST"
     }' \
     $YOUR_GDK_ROOT_URL/api/v4/ai/duo_workflows/workflows
   ```

#### Set up the GitLab Duo Workflow Service and Executor

Refer to the readme of [GitLab Duo Workflow Service](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-service) and [GitLab Duo Workflow Executor](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-executor/) to set them up individually.

## Troubleshooting

### Issues connecting to 50052 port

JAMF may be listening on the `50052` port which will conflict with GitLab Duo Workflow Service.

```shell
$ sudo lsof -i -P | grep LISTEN | grep :50052
jamfRemot  <redacted>           root   11u  IPv4 <redacted>      0t0    TCP localhost:50052 (LISTEN)
```

To work around this,run the serveron 50053 with:

```shell
PORT=50053 poetry run duo-workflow-service
```
