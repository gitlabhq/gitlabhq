# Pipelines for merge requests

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/15310) in GitLab 11.6

Usually, when a developer creates a new merge request, a pipeline runs on the
new change and checks if it's qualified to be merged into a target branch. This
pipeline should contain only necessary jobs for checking the new changes.
For example, unit tests, lint checks, and Review Apps are often used in this cycle.

With pipelines for merge requests, you can design a specific pipeline structure
for merge requests. All you need to do is just adding `only: [merge_requests]` to
the jobs that you want it to run for only merge requests.
Every time, when developers create or update merge requests, a pipeline runs on
their new commits at every push to GitLab.

NOTE: **Note**:
If you use both this feature and the [Merge When Pipeline Succeeds](../../user/project/merge_requests/merge_when_pipeline_succeeds.md)
feature, pipelines for merge requests take precendence over the other regular pipelines.

For example, consider a GitLab CI/CD configuration in .gitlab-ci.yml as follows:

```yaml
build:
  stage: build
  script: ./build
  only:
  - branches
  - tags
  - merge_requests

test:
  stage: test
  script: ./test
  only:
  - merge_requests

deploy:
  stage: deploy
  script: ./deploy
```

After a developer updated code in a merge request with whatever methods (e.g. `git push`),
GitLab detects that the code is updated and create a new pipeline for the merge request.
The pipeline fetches the latest code from the source branch and run tests against it.
In this example, the pipeline contains only `build` and `test` jobs.
Since `deploy` job does not have the `only: [merge_requests]` rule,
deployment jobs will not happen in the merge request.

Consider this pipeline list viewed from the **Pipelines** tab in a merge request:

![Merge request page](img/merge_request.png)

Note that pipelines tagged as **merge request** indicate that they were triggered
when a merge request was created or updated.

The same tag is shown on the pipeline's details:

![Pipeline's details](img/pipeline_detail.png)

## Important notes about merge requests from forked projects

Note that the current behavior is subject to change. In the usual contribution
flow, external contributors follow the following steps:

1. Fork a parent project.
1. Create a merge request from the forked project that targets the `master` branch
in the parent project.
1. A pipeline runs on the merge request.
1. A mainatiner from the parent project checks the pipeline result, and merge
into a target branch if the latest pipeline has passed.

Currently, those pipelines are created in a **forked** project, not in the
parent project. This means you cannot completely trust the pipeline result,
because, technically, external contributors can disguise their pipeline results
by tweaking their GitLab Runner in the forked project.

There are multiple reasons about why GitLab doesn't allow those pipelines to be
created in the parent project, but one of the biggest reasons is security concern.
External users could steal secret variables from the parent project by modifying
.gitlab-ci.yml, which could be some sort of credentials. This should not happen.

We're discussing a secure solution of running pipelines for merge requests
that submitted from forked projects,
see [the issue about the permission extension](https://gitlab.com/gitlab-org/gitlab-ce/issues/23902).
