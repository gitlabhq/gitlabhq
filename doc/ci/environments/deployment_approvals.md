---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: Require approvals prior to deploying to a Protected Environment
---

# Deployment approvals **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/343864) in GitLab 14.7 with a flag named `deployment_approvals`. Disabled by default.

WARNING:
This feature is in an alpha stage and subject to change without prior notice.

It may be useful to require additional approvals before deploying to certain protected environments (for example, production). This pre-deployment approval requirement is useful to accommodate testing, security, or compliance processes that must happen before each deployment.

When a protected environment requires one or more approvals, all deployments to that environment become blocked and wait for the required approvals before running.

NOTE:
See the [epic](https://gitlab.com/groups/gitlab-org/-/epics/6832) for planned features.

## Requirements

- Basic knowledge of [GitLab Environments and Deployments](index.md).
- Basic knowledge of [Protected Environments](protected_environments.md).

## Configure deployment approvals for a project

To configure deployment approvals for a project:

1. [Create a deployment job](#create-a-deployment-job).
1. [Require approvals for a protected environment](#require-approvals-for-a-protected-environment).

### Create a deployment job

Create a deployment job in the `.gitlab-ci.yaml` file of the desired project. The job does **not** need to be manual (`when: manual`).

Example:

   ```yaml
   stages:
     - deploy

   production:
     stage: deploy
     script:
       - 'echo "Deploying to ${CI_ENVIRONMENT_NAME}"'
     environment:
       name: ${CI_JOB_NAME}
   ```

### Require approvals for a protected environment 

NOTE:
At this time, only API-based configuration is available. UI-based configuration is planned for the near future. See [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/344675). 

Use the [Protected Environments API](../../api/protected_environments.md#protect-repository-environments) to create an environment with `required_approval_count` > 0. After this is set, all jobs deploying to this environment automatically go into a blocked state and wait for approvals before running.

Example:

```shell
curl --header 'Content-Type: application/json' --request POST \
     --data '{"name": "production", "deploy_access_levels": [{"group_id": 9899826}], "required_approval_count": 1}' \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/22034114/protected_environments"
```

To protect, update, or unprotect an environment, you must have at least the
[Maintainer role](../../user/permissions.md).

## Approve or reject a deployment

NOTE:
This functionality is currently only available through the API. UI is planned for the near future. See [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/342180/).

A blocked deployment is enqueued as soon as it receives the required number of approvals. A single rejection causes the deployment to fail. The creator of a deployment cannot approve it, even if they have permission to deploy.

Using the [Deployments API](../../api/deployments.md#approve-or-reject-a-blocked-deployment), users who are allowed to deploy to the protected environment can approve or reject a blocked deployment. 

Example:

```shell
curl --data "status=approved" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/deployments/1/approval"
```

### How to see blocked deployments

#### Using the UI

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Deployments > Environments**.
1. Select the environment being deployed to.
1. Look for the `blocked` label.

#### Using the API

Use the [Deployments API](../../api/deployments.md) to see deployments. The `status` field indicates if a deployment is blocked. 

## Related features

For details about other GitLab features aimed at protecting deployments, see [safe deployments](deployment_safety.md).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
