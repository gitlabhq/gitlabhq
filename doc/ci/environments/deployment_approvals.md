---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Require approvals prior to deploying to a Protected Environment
title: Deployment approvals
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can require additional approvals for deployments to protected
environments. Deployments are blocked until all required approvals are
given.

Use deployment approvals to accommodate testing,
security, or compliance processes. For example, you might want to
require approvals for deployments to production environments.

## Configure deployment approvals

You can require approvals for deployments to protected environments in
a project.

Prerequisites:

- To update an environment, you must have at least the Maintainer role.

To configure deployment approvals for a project:

1. Create a deployment job in the `.gitlab-ci.yml` file of your project:

   ```yaml
   stages:
     - deploy

   production:
     stage: deploy
     script:
       - 'echo "Deploying to ${CI_ENVIRONMENT_NAME}"'
     environment:
       name: ${CI_JOB_NAME}
       action: start
   ```

   The job does not need to be manual (`when: manual`).

1. Add the required [approval rules](#add-multiple-approval-rules).

The environments in your project require approval before deployment.

### Add multiple approval rules

> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/345678) in GitLab 15.0. [Feature flag `deployment_approval_rules`](https://gitlab.com/gitlab-org/gitlab/-/issues/345678) removed.
> - UI configuration [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378445) in GitLab 15.11.

Add multiple approval rules to control who can approve and execute deployment jobs.

To configure multiple approval rules, use the [CI/CD settings](protected_environments.md#protecting-environments).
You can [also use the API](../../api/group_protected_environments.md#protect-a-single-environment).

All jobs deploying to the environment are blocked and wait for approvals before running.
Make sure the number of required approvals is less than the number of users allowed to deploy.

After a deployment job is approved, you must [run the job manually](../jobs/job_control.md#run-a-manual-job).

### Allow self-approval

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381418) in GitLab 15.8.
> - Automatic approval [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124638) in GitLab 16.2 due to [usability issues](https://gitlab.com/gitlab-org/gitlab/-/issues/391258).

By default, the user who triggers a deployment pipeline can't also approve the deployment job.

A GitLab administrator can approve or reject all deployments.

To allow self-approval of a deployment job:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Protected environments**.
1. From the **Approval options**, select the **Allow pipeline triggerer to approve deployment** checkbox.

## Approve or reject a deployment

In an environment with multiple approval rules, you can:

- Approve a deployment to allow it to proceed.
- Reject a deployment to prevent it.

Prerequisites:

- You have permission to deploy to the protected environment.

To approve or reject a deployment:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Operate > Environments**.
1. Select the environment's name.
1. Find the deployment and select its **Status badge**.
1. Optional. Add a comment which describes your reason for approving or rejecting the deployment.
1. Select **Approve** or **Reject**.

You can also [use the API](../../api/deployments.md#approve-or-reject-a-blocked-deployment).

The corresponding deployment job does not run automatically after a deployment is approved.

### View the approval details of a deployment

Prerequisites:

- You have permission to deploy to the protected environment.

A deployment to a protected environment can proceed only after all required approvals have been
granted.

To view the approval details of a deployment:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Operate > Environments**.
1. Select the environment's name.
1. Find the deployment and select its **Status badge**.

The approval status details are shown:

- Eligible approvers
- Number of approvals granted, and number of approvals required
- Users who have granted approval
- History of approvals or rejections

## View blocked deployments

Review the status of your deployments, including whether a deployment is blocked.

To view your deployments:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Operate > Environments**.
1. Select the environment being deployed to.

A deployment with the **blocked** label is blocked.

To view your deployments, you can also [use the API](../../api/deployments.md#get-a-specific-deployment).
The `status` field indicates whether a deployment is blocked.

## Related topics

- [Deployment approvals feature epic](https://gitlab.com/groups/gitlab-org/-/epics/6832)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
