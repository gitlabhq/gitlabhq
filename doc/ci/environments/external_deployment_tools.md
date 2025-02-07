---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Track deployments of an external deployment tool
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

While GitLab offers a [built-in deployment solution](_index.md), you might prefer to use an external deployment tool, such as Heroku or ArgoCD.
GitLab can receive deployment events from these external tools and allows you to track the deployments within GitLab.
For example, the following features are available by setting up tracking:

- [See when an merge request has been deployed, and to which environment](../../user/project/merge_requests/widgets.md#post-merge-pipeline-status).
- [Filter merge requests by environment or deployment date](../../user/project/merge_requests/_index.md#by-environment-or-deployment-date).
- [DevOps Research and Assessment (DORA) metrics](../../user/analytics/dora_metrics.md).
- [View environments and deployments](_index.md#view-environments-and-deployments).
- [Track newly included merge requests per deployment](deployments.md#track-newly-included-merge-requests-per-deployment).

NOTE:
Some of the features are not available because GitLab can't authorize and leverage those external deployments, including
[Protected Environments](protected_environments.md), [Deployment Approvals](deployment_approvals.md), [Deployment safety](deployment_safety.md), and [Deployment rollback](deployments.md#deployment-rollback).

## How to set up deployment tracking

External deployment tools usually offer a [webhook](https://en.wikipedia.org/wiki/Webhook) to execute an additional API request when deployment state is changed.
You can configure your tool to make a request to the GitLab [Deployment API](../../api/deployments.md). Here is an overview of the event and API request flow:

- When a deployment starts running, [create a deployment with `running` status](../../api/deployments.md#create-a-deployment).
- When a deployment succeeds, [update the deployment status to `success`](../../api/deployments.md#update-a-deployment).
- When a deployment fails, [update the deployment status to `failed`](../../api/deployments.md#update-a-deployment).

NOTE:
You can create a [project access token](../../user/project/settings/project_access_tokens.md) for the GitLab API authentication.

### Example: Track deployments of ArgoCD

You can use [ArgoCD webhook](https://argocd-notifications.readthedocs.io/en/stable/services/webhook/) to send deployment events to GitLab Deployment API.
Here is an example setup that creates a `success` deployment record in GitLab when ArgoCD successfully deploys a new revision:

1. Create a new webhook. You can save the following manifest file and apply it by `kubectl apply -n argocd -f <manifiest-file-path>`:

   ```yaml
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: argocd-notifications-cm
   data:
     trigger.on-deployed: |
       - description: Application is synced and healthy. Triggered once per commit.
         oncePer: app.status.sync.revision
         send:
         - gitlab-deployment-status
         when: app.status.operationState.phase in ['Succeeded'] and app.status.health.status == 'Healthy'
     template.gitlab-deployment-status: |
       webhook:
         gitlab:
           method: POST
           path: /projects/<your-project-id>/deployments
           body: |
             {
               "status": "success",
               "environment": "production",
               "sha": "{{.app.status.operationState.operation.sync.revision}}",
               "ref": "main",
               "tag": "false"
             }
     service.webhook.gitlab: |
       url: https://gitlab.com/api/v4
       headers:
       - name: PRIVATE-TOKEN
         value: <your-access-token>
       - name: Content-type
         value: application/json
   ```

1. Create a new subscription in your application:

   ```shell
   kubectl patch app <your-app-name> -n argocd -p '{"metadata": {"annotations": {"notifications.argoproj.io/subscribe.on-deployed.gitlab":""}}}' --type merge
   ```

NOTE:
If a deployment wasn't created as expected, you can troubleshoot with [`argocd-notifications` tool](https://argocd-notifications.readthedocs.io/en/stable/troubleshooting/).
For example, `argocd-notifications template notify gitlab-deployment-status <your-app-name> --recipient gitlab:argocd-notifications`
triggers API request immediately and renders an error message from GitLab API server if any.
