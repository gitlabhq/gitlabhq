---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Setting up local development for Duo Workflow

## Prerequisites

- Vertex API access
  - You need access to the `ai-enablement-dev-69497ba7` project in
    GCP. This should by available to all engineers at GitLab.
- Docker
  - See which Docker tooling is approved for GitLab team members in the [handbook](https://handbook.gitlab.com/handbook/tools-and-tips/mac/#docker-desktop).

## Set up your local GitLab instance

1. Configure the Duo Workflow Service URL in your local GitLab instance by updating the `config/gitlab.yml` file:

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

## Set up the Duo Workflow Service

1. Clone the [Duo Workflow Service respository](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-service)

   ```shell
     git clone git@gitlab.com:gitlab-org/duo-workflow/duo-workflow-service.git
   ```

1. Navigate to the Duo Workflow Service directory

   ```shell
   cd duo-workflow-service
   ```

1. Install dependencies

   ```shell
   poetry install
   ```

1. Copy the example env file in the Service repo.

   ```shell
   cp .env.example .env
   ```

1. Setup [`gcloud`](https://cloud.google.com/sdk/docs/install) on your system.
1. Login using your GitLab Google account by running:

   ```shell
   gcloud auth login
   ```

1. Set the `ai-enablement-dev-69497ba7` as active project by running:

   ```shell
   gcloud config set project ai-enablement-dev-69497ba7
   ```

1. Create the credentials for the application to use

   ```shell
   gcloud auth application-default login --disable-quota-project
   ```

1. Optional: You can disable auth for local development in the `.env` file. This disables authentication or the gRPC connection between the Duo Workflow Service and Duo Workflow Executor but a token will still be required for requests to your local GitLab instance.

   ```dotenv
   DUO_WORKFLOW_AUTH__ENABLED=false`
   ```

1. Run the Duo Workflow Service server

   ```shell
   poetry run python -m duo_workflow_service.server
   ```

1. If you can correctly connect to vertex, you should see something
   like this in the output

   ```shell
   2024-09-06 17:16:54 [info     ] Connected to model: claude-3-sonnet-20240229: You're talking to Claude, an AI assistant created by Anthropic.
   2024-09-06 17:16:54 [info     ] Starting server on port 50052
   2024-09-06 17:16:54 [info     ] Started server
   ```

## Set up the Duo Workflow Executor

1. Clone the [Duo Workflow Executor repository](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-executor)

   ```shell
     git clone git@gitlab.com:gitlab-org/duo-workflow/duo-workflow-executor.git
   ```

1. Navigate to the Duo Workflow Executor directory

   ```shell
   cd duo-workflow-executor
   ```

1. Create a Dockerfile in the Duo Workflow Executor root directory with the following contents:

   ```Dockerfile
   FROM alpine

   RUN apk add go busybox-extras git bash
   ```

1. Build a development image to use:

   ```shell
   docker build -t alpine-dev-workflow .
   ```

1. Run the executor with your GitLab token and workflow ID

   ```shell
   make && \
   ./bin/duo-workflow-executor \
       --goal='Fix the pipeline for the Merge request 62 in the project 19." \
       --insecure --debug
       --workflow-id=$WORKFLOW_ID \
       --token=$YOUR_GITLAB_PAT \
       --base-url="$GDK_GITLAB_URL" \
       --user-id="1"
   ```

1. Verify that the checkpoints for workflow have been created

   ```shell
   curl --verbose \
     --header "Authorization: Bearer $YOUR_GITLAB_PAT" \
     $GDK_GITLAB_URL/api/v4/ai/duo_workflows/workflows/$WORKFLOW_ID/checkpoints
   ```

## Configure the GitLab Duo Workflow extension for VS Code

The above steps show how to start a workflow directly from the Duo Workflow
Executor.

If you would like to start Duo Workflow with the VS Code extension instead,
follow [these steps](../../user/duo_workflow/index.md#prerequisites).

If you are debugging or making changes to the VSCode extension and need to run the extension in development mode, you can do that following [these instructions](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/main/CONTRIBUTING.md#configuring-development-environment).

## Troubleshooting

### Issues connecting to 50052 port

JAMF may be listening on the `50052` port which will conflict with Duo Workflow Service.

```shell
$ sudo lsof -i -P | grep LISTEN | grep :50052
jamfRemot  <redacted>           root   11u  IPv4 <redacted>      0t0    TCP localhost:50052 (LISTEN)
```

To work around this,run the serveron 50053 with:

```shell
PORT=50053 poetry run duo-workflow-service
```
