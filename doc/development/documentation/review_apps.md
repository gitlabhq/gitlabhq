---
stage: none
group: Documentation Guidelines
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Learn how documentation review apps work.
---

# Documentation review apps

If you're a GitLab team member and your merge request contains documentation changes, you can use a review app to preview
how they would look if they were deployed to the [GitLab Docs site](https://docs.gitlab.com).

Review apps are enabled for the following projects:

- [GitLab](https://gitlab.com/gitlab-org/gitlab)
- [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab)
- [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner)
- [GitLab Charts](https://gitlab.com/gitlab-org/charts/gitlab)

Alternatively, check the [`gitlab-docs` development guide](https://gitlab.com/gitlab-org/gitlab-docs/blob/main/README.md#development-when-contributing-to-gitlab-documentation)
or [the GDK documentation](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/gitlab_docs.md)
to render and preview the documentation locally.

## How to trigger a review app

If a merge request has documentation changes, use the `review-docs-deploy` manual job
to deploy the documentation review app for your merge request.

![Manual trigger a documentation review app](img/manual_build_docs_v14_6.png)

The `review-docs-deploy*` job triggers a cross project pipeline and builds the
docs site with your changes. When the pipeline finishes, the review app URL
appears in the merge request widget. Use it to navigate to your changes.

The `review-docs-cleanup` job is triggered automatically on merge. This job deletes the review app.

You must have the Developer role in the project. Users without the Developer role, such
as external contributors, cannot run the manual job. In that case, ask someone from
the GitLab team to run the job.

## Technical aspects

If you want to know the in-depth details, here's what's really happening:

1. You manually run the `review-docs-deploy` job in a merge request.
1. The job runs the [`scripts/trigger-build.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/trigger-build.rb)
   script with the `docs deploy` flag, which triggers the "Triggered from `gitlab-org/gitlab` 'review-docs-deploy' job"
   pipeline trigger in the `gitlab-org/gitlab-docs` project for the `$DOCS_BRANCH` (defaults to `main`).
1. The preview URL is shown both at the job output and in the merge request
   widget. You also get the link to the remote pipeline.
1. In the `gitlab-org/gitlab-docs` project, the pipeline is created and it
   [skips most test jobs](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/d41ca9323f762132780d2d072f845d28817a5383/.gitlab/ci/rules.gitlab-ci.yml#L101-103)
   to lower the build time.
1. After the docs site is built, the HTML files are uploaded as artifacts to
   a GCP bucket (see [issue `gitlab-com/gl-infra/reliability#11021`](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/11021)
   for the implementation details).

The following GitLab features are used among others:

- [Manual jobs](../../ci/jobs/job_control.md#create-a-job-that-must-be-run-manually)
- [Multi project pipelines](../../ci/pipelines/downstream_pipelines.md#multi-project-pipelines)
- [Review Apps](../../ci/review_apps/index.md)
- [Artifacts](../../ci/yaml/index.md#artifacts)
- [Merge request pipelines](../../ci/pipelines/merge_request_pipelines.md)

## Troubleshooting review apps

### `NoSuchKey The specified key does not exist`

If you see the following message in a review app, either the site is not
yet deployed, or something went wrong with the downstream pipeline in `gitlab-docs`.

```plaintext
NoSuchKeyThe specified key does not exist.No such object: <URL>
```

In that case, you can:

- Wait a few minutes and the review app should appear online.
- Check the `review-docs-deploy` job's log and verify the URL. If the URL shown in the merge
  request UI is different than the job log, try the one from the job log.
- Check the status of the remote pipeline from the link in the merge request's job output.
  If the pipeline failed or got stuck, GitLab team members can ask for help in the `#docs`
  internal Slack channel. Contributors can ping a
  [technical writer](https://about.gitlab.com/handbook/product/ux/technical-writing/#designated-technical-writers)
  in the merge request.
