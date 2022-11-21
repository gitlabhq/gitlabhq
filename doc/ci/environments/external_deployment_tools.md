---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# Track deployments of an external deployment tool **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22513) in GitLab 12.5.

While GitLab offers a [built-in deployment solution](index.md), you might prefer to use an external deployment tool, such as Heroku or ArgoCD.
GitLab can receive deployment events from these external tools and allows you to track the deployments within GitLab.
For example, the following features are available by setting up tracking:

- [See when an merge request has been deployed, and to which environment](../../user/project/merge_requests/widgets.md#post-merge-pipeline-status).
- [Filter merge requests by environment or deployment date](../../user/project/merge_requests/index.md#filter-merge-requests-by-environment-or-deployment-date).
- [DevOps Research and Assessment (DORA) metrics](../../user/analytics/dora_metrics.md).
- [View environments and deployments](index.md#view-environments-and-deployments).
- [Track newly included merge requests per deployment](index.md#track-newly-included-merge-requests-per-deployment).

NOTE:
Some of the features are not available because GitLab can't authorize and leverage those external deployments, including
[Protected Environments](protected_environments.md), [Deployment Approvals](deployment_approvals.md), [Deployment safety](deployment_safety.md), and [Environment rollback](index.md#environment-rollback).

## How to set up deployment tracking

External deployment tools usually offer a [webhook](https://en.wikipedia.org/wiki/Webhook) to execute an additional API request when deployment state is changed.
You can configure your tool to make a request to the GitLab [Deployment API](../../api/deployments.md). Here is an overview of the event and API request flow:

- When a deployment starts running, [create a deployment with `running` status](../../api/deployments.md#create-a-deployment).
- When a deployment succeeds, [update the deployment status to `success`](../../api/deployments.md#update-a-deployment).
- When a deployment fails, [update the deployment status to `failed`](../../api/deployments.md#update-a-deployment).

NOTE:
You can create a [project access token](../../user/project/settings/project_access_tokens.md) for the GitLab API authentication.

NOTE:
If you don't have an environment yet, you can [create a new environment](index.md#create-a-static-environment) in the UI or with the [Environment API](../../api/environments.md#create-a-new-environment).
