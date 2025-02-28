---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Learn how documentation review apps work.
title: Documentation review apps
---

GitLab team members can deploy a [review app](../../ci/review_apps/_index.md) for merge requests with documentation
changes. The review app lets you preview how your changes appear on the [GitLab Docs site](https://docs.gitlab.com) before merging.

Review app deployments are available for these projects:

| Project                                                                       | Configuration file |
| ----------------------------------------------------------------------------- | ------------------ |
| [GitLab](https://gitlab.com/gitlab-org/gitlab)                                | [`.gitlab/ci/docs.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/066d02834ef51ff7647672d1d9cc323256177580/.gitlab/ci/docs.gitlab-ci.yml#L1-34) |
| [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab)                | [`gitlab-ci-config/gitlab-com.yml`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/49ab057ecf75396a453e1e2981e0889a3818842b/gitlab-ci-config/gitlab-com.yml#L328-347) |
| [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner)                  | [`.gitlab/ci/docs.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab-runner/-/blob/8e2e3b7ace350a8889ff0143a9a0ad3c46322786/.gitlab/ci/docs.gitlab-ci.yml) |
| [GitLab Charts](https://gitlab.com/gitlab-org/charts/gitlab)                  | [`.gitlab/ci/review-docs.yml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/6e8270d0e7c51bdc3de8f8f1429ad68625621eb1/.gitlab/ci/review-docs.yml) |
| [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator) | [`.gitlab-ci.yml`](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/blob/bbf52c863ce4b712369214474e47b3f989e52d48/.gitlab-ci.yml#L234-281) |

## Deploy a review app

You can deploy a review app by manually triggering the `review-docs-deploy` job in your merge request.

This job creates a preview of your documentation changes using the Hugo static site generation from
the [`docs-gitlab-com`](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com) project.

Prerequisites:

- You must have the Developer role for the project.

External contributors cannot run this job. If you're an external contributor,
ask a GitLab team member to run it for you.

To deploy a review app:

1. From your merge request, [manually run](../../ci/jobs/job_control.md#run-a-manual-job) the `review-docs-deploy` job.
   This job triggers a [multi-project pipeline](../../ci/pipelines/downstream_pipelines.md#multi-project-pipelines)
   that builds and deploys the documentation site with your changes.
1. When the pipeline finishes, select **View app** to open the review app in your browser.

The `review-docs-cleanup` job is triggered automatically on merge. This job deletes
the review app.

## How documentation review apps work

Documentation review apps follow this process:

1. You manually run the `review-docs-deploy` job in a merge request.
1. The job downloads (if outside of `gitlab` project) and runs the
   [`scripts/trigger-build.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/trigger-build.rb) script with
   the `docs deploy` flag, which triggers a pipeline in the `gitlab-org/technical-writing/docs-gitlab-com`
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

To resolve this issue, contact the [Technical Writing team](https://handbook.gitlab.com/handbook/product/ux/technical-writing/#contact-us).
For more information on documentation review app tokens,
see [GitLab docs site maintenance](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/blob/main/doc/maintenance.md).
