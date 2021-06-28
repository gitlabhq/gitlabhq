---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: index, reference
---

# Merge request widgets **(FREE)**

The **Overview** page of a merge request displays status updates from services
that perform actions on your merge request. All subscription levels display a
widgets area, but the content of the area depends on your subscription level
and the services you configure for your project.

## Pipeline information

If you've set up [GitLab CI/CD](../../../ci/index.md) in your project,
a [merge request](index.md) displays pipeline information in the widgets area
of the **Overview** tab:

- Both pre-merge and post-merge pipelines, and the environment information, if any.
- Which deployments are in progress.

If an application is successfully deployed to an
[environment](../../../ci/environments/index.md), the deployed environment and the link to the
[review app](https://about.gitlab.com/stages-devops-lifecycle/review-apps/) are both shown.

NOTE:
When the pipeline fails in a merge request but it can still be merged,
the **Merge** button is colored red.

## Post-merge pipeline status

When a merge request is merged, you can see the post-merge pipeline status of
the branch the merge request was merged into. For example, when a merge request
is merged into the [default branch](../repository/branches/default.md) and then triggers a deployment to the staging
environment.

Ongoing deployments are shown, and the state (deploying or deployed)
for environments. If it's the first time the branch is deployed, the link
returns a `404` error until done. During the deployment, the stop button is
disabled. If the pipeline fails to deploy, the deployment information is hidden.

![Merge request pipeline](img/merge_request_pipeline.png)

For more information, [read about pipelines](../../../ci/pipelines/index.md).

## Merge when pipeline succeeds (MWPS)

Set a merge request that looks ready to merge to
[merge automatically when CI pipeline succeeds](merge_when_pipeline_succeeds.md).

## Live preview with Review Apps

If you configured [Review Apps](https://about.gitlab.com/stages-devops-lifecycle/review-apps/) for your project,
you can preview the changes submitted to a feature branch through a merge request
on a per-branch basis. You don't need to checkout the branch, install, and preview locally.
All your changes are available to preview by anyone with the Review Apps link.

With GitLab [Route Maps](../../../ci/review_apps/index.md#route-maps) set, the
merge request widget takes you directly to the pages changed, making it easier and
faster to preview proposed modifications.

[Read more about Review Apps](../../../ci/review_apps/index.md).

## External status checks **(ULTIMATE)**

If you have configured [external status checks](status_checks.md) you can
see the status of these checks in merge requests
[in a specific widget](status_checks.md#status-checks-widget).
