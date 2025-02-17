---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Learn how documentation review apps work.
title: Documentation review apps
---

GitLab team members can deploy a [review app](../../ci/review_apps/_index.md) for merge requests with documentation
changes. The review app helps you preview what the changes would look like if they were deployed to either:

- The [GitLab Docs site](https://docs.gitlab.com).

Review apps deployments are available for these projects:

- [GitLab](https://gitlab.com/gitlab-org/gitlab) (configuration: <https://gitlab.com/gitlab-org/gitlab/-/blob/b4f30955e41aeab862c59f7102529e1a5a2659d1/.gitlab/ci/docs.gitlab-ci.yml#L1-40>)
- [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab) (configuration: <https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/bae935d36ea9296941c20233b637d780847c443a/gitlab-ci-config/gitlab-com.yml#L304-328>)
- [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner) (configuration: <https://gitlab.com/gitlab-org/gitlab-runner/-/blob/69d2416333df4712cbd95d90214b10f100183df3/.gitlab/ci/docs.gitlab-ci.yml#L64-110>)
- [GitLab Charts](https://gitlab.com/gitlab-org/charts/gitlab) (configuration: <https://gitlab.com/gitlab-org/charts/gitlab/-/blob/8222a7c3cf28d8ad3f454784a04cad8921b6638b/.gitlab/ci/review-docs.yml#L2-49>)
- [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator) (configuration: <https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/blob/56200465a5c8f8857f3aef2c309bdf2ca9e4b672/.gitlab-ci.yml#L210-257>)

## Deploy a review app and preview changes

Prerequisites:

- You must have the Developer role for the project. External contributors cannot run these jobs and
should ask a GitLab team member to run the jobs for them.

For merge requests with documentation changes, you can manually trigger the following deploy job:

- `review-docs-hugo-deploy`: Creates a review app to preview your documentation changes using the Hugo static site generation from
  [`docs-gitlab-com`](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com). This site replaced the previous site built with Nanoc.

To deploy a review app and preview changes:

1. [Manually run](../../ci/jobs/job_control.md#run-a-manual-job) either (or both) of these jobs. These jobs trigger a
   [multi project pipelines](../../ci/pipelines/downstream_pipelines.md#multi-project-pipelines), build the
   documentation site with your changes, and deploy a site with your changes.
1. When the pipeline finishes, select **View app** on either deployment to open a browser and review the
   changes introduced by the merge request.

The `review-docs-hugo-cleanup` job is triggered automatically on merge. This job deletes
the review app.

## How documentation review apps work

Documentation review apps follow this process:

1. You manually run the `review-docs-hugo-deploy` job in a merge request.
1. The job downloads (if outside of `gitlab` project) and runs the
   [`scripts/trigger-build.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/trigger-build.rb) script with
   the `docs-hugo deploy` flag, which triggers a pipeline in the `gitlab-org/technical-writing/docs-gitlab-com`
   project.

   The `DOCS_BRANCH` environment variable determines which branch of the
   `gitlab-org/technical-writing/docs-gitlab-com` project to use. If not set, the `main` branch is used.
1. After the documentation preview site is built, it is [deployed in parallel to other review apps](../../user/project/pages/_index.md#parallel-deployments).

## Troubleshooting

When working with review apps, you might encounter the following issues.

### Error: `401 Unauthorized` in documentation review app deployment jobs

You might get an error in a review app deployment job that states:

```plaintext
Server responded with code 401, message: 401 Unauthorized.
```

This issue occurs when the `DOCS_HUGO_PROJECT_API_TOKEN` has either:

- Expired or been revoked and must be regenerated.
- Been recreated, but the CI/CD variable in the projects that use it wasn't updated.

These conditions result in the deployment job for the documentation review app being unable to query the downstream project for
the status of the downstream pipeline.

To resolve this issue, contact the [Technical Writing team](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#contact-us). For more information on documentation review app tokens,
see [GitLab docs site maintenance](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/maintenance.md).
