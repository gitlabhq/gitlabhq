---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Setting up local development for Duo Workflow

## Prerequisites

- Docker
  - NOTE: We aren't allowed to use [Docker Desktop](https://handbook.gitlab.com/handbook/tools-and-tips/mac/#docker-desktop).
- [AI Gateway](../ai_features/index.md)

## Setting up Duo Workflow

### Set up Duo Workflow Service

1. Clone the [Duo Workflow Service](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-service)

  ```shell
    git clone git@gitlab.com:gitlab-org/duo-workflow/duo-workflow-service.git
  ```

1. Navigate to the Duo Workflow Service directory

1. Install dependencies

  ```shell
  poetry install
  ```

1. Copy the example env file in the Service repo. Enter your Anthropic API key.

  ```shell
  cp .env.example .env
  ```

  ```dotenv
  ANTHROPIC_API_KEY=<YOUR_API_KEY>
  ```

  You can disable auth for local development by setting DUO_WORKFLOW_AUTH__ENABLED=false in `.env`

1. Run Duo Workflow Service

  ```shell
  poetry run python -m duo_workflow_service.server
  ```

1. In your local GitLab instance enable the `duo_workflow` feature flag from the rails console:

  ```ruby
  Feature.enable(:duo_workflow)
  ```

1. Create a [personal access token](../../user/profile/personal_access_tokens.md) in your local GitLab instance with `api` scope

1. Generate a workflow ID. Replace `$GITLAB_TOKEN` with a PAT from your local GitLab instance.

  ```shell
  curl POST --verbose \
    --header "Authorization: Bearer $GITLAB_TOKEN" \
    --header 'Content-Type: application/json' \
    --data '{
        "project_id": "7"
    }' \
    http://<GDK_HOST>:3000/api/v4/ai/duo_workflows/workflows
  ```

### Set up the Duo Workflow Executor

1. Clone the [Duo Workflow Executor](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-executor)

1. Navigate to the Duo Workflow Executor directory

1. Create a Dockerfile

  ```Dockerfile
  FROM alpine

  RUN apk add go busybox-extras git bash
  ```

1. Run the executor with your GitLab token and workflow ID. Below is an example prompt goal

  ```shell
  make && \
  ./bin/duo-workflow-executor \
      --goal='Can you fix the pipeline for the Merge request: 1 in the project 60003631.
  You will have to clone the repository if you need to fix files. You can use the `run_command` tool to do so."
  Please also checkout the right branch before making the changes.
  You can fetch the repository name from the `get_project` tool.

  Once you have fixed the pipeline please push the code to the same branch.' \
      --workflow-id=$WORKFLOW_ID \
      --token=$GITLAB_TOKEN \
      --base-url="http://<GDK_HOST>:3000" \
      --realm="saas" \
      --userID="777"
  ```

  You can also find more instructions to [run the executor locally in a Docker container](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-executor/-/blob/9dbe47ce3c61e1274af184f595ae5af1417d7a39/README.md).

1. Verify that the checkpoints for workflow have been created

  ```shell
  curl --verbose \
    --header "Authorization: Bearer $GITLAB_TOKEN" \
    http://<GDK_HOST>/api/v4/ai/duo_workflows/workflows/<workflow_id>/checkpoints
  ```

## Optional: Testing the Auth flow via GitLab

Please note that this work is in progress and only half-implemented. These instructions are left here in case they are useful for testing purposes.

1. Generate a Cloud Connector token and grab your GitLab instance ID from the rails console

  ```shell
  cd <GDK-root>
  gdk start
  gdk rails console
  ```

  To grab your Cloud Connector token:

  ```ruby
  ::Gitlab::CloudConnector::SelfIssuedToken.new(
  audience: "gitlab-duo-workflow-service",
  subject: Gitlab::CurrentSettings.uuid,
  scopes: ["duo_workflow_generate_token"]).encoded
  ```

  To grab your GitLab instance ID:

  <!-- markdownlint-disable MD044 -->
  ```ruby
  Gitlab::CurrentSettings.uuid
  ```
  <!-- markdownlint-enable MD044 -->

1. Navigate to the [client.py file](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-service/-/blob/83b62846cad3cfb633c31c0c9aa02e4535f44941/duo_workflow_service/client.py#L32-38) and replace the values in this file with the token and instance ID from the previous step.

  ```python
  token = "<set-your-local-gdk-token>"

  # To get your gitlab_instance_id, run in gdk rails console:
  # ```
  # puts Gitlab::CurrentSettings.uuid
  # ```
  gitlab_instance_id = "<set-your-local-gdk-instance-id>"
  ```

1. Update the metadata in the [client.py file](https://gitlab.com/gitlab-org/duo-workflow/duo-workflow-service/-/blob/83b62846cad3cfb633c31c0c9aa02e4535f44941/duo_workflow_service/client.py#L40-46) to the following:

  ```python
  metadata = [
      ("authorization", f"Bearer {token}"),
      ("x-gitlab-authentication-type", "oidc"),
      ("x-gitlab-realm", "saas"),
      ("x-gitlab-instance-id", gitlab_instance_id),
      ("x-gitlab-global-user-id", "777"),
  ]
  ```

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
