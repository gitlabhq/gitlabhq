---
stage: none
group: Engineering Productivity
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# CI configuration internals

## Workflow rules

Pipelines for the GitLab project are created using the [`workflow:rules` keyword](../../ci/yaml/index.md#workflow)
feature of the GitLab CI/CD.

Pipelines are always created for the following scenarios:

- `main` branch, including on schedules, pushes, merges, and so on.
- Merge requests.
- Tags.
- Stable, `auto-deploy`, and security branches.

Pipeline creation is also affected by the following CI/CD variables:

- If `$FORCE_GITLAB_CI` is set, pipelines are created. Not recommended to use.
  See [Avoid `$FORCE_GITLAB_CI`](#avoid-force_gitlab_ci).
- If `$GITLAB_INTERNAL` is not set, pipelines are not created.

No pipeline is created in any other cases (for example, when pushing a branch with no
MR for it).

The source of truth for these workflow rules is defined in [`.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab-ci.yml).

### Avoid `$FORCE_GITLAB_CI`

The pipeline is very complex and we need to clearly understand the kind of
pipeline we want to trigger. We need to know which jobs we should run and
which ones we shouldn't.

If we use `$FORCE_GITLAB_CI` to force trigger a pipeline,
we don't really know what kind of pipeline it is. The result can be that we don't
run the jobs we want, or we run too many jobs we don't care about.

Some more context and background can be found at:
[Avoid blanket changes to avoid unexpected run](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/102881)

Here's a list of where we're using this right now, and should try to move away
from using `$FORCE_GITLAB_CI`.

- [JiHu validation pipeline](https://about.gitlab.com/handbook/ceo/chief-of-staff-team/jihu-support/jihu-validation-pipelines.html)
- [Gitaly downstream GitLab pipeline](https://gitlab.com/gitlab-org/gitaly/-/issues/4615)

## Default image

The default image is defined in [`.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab-ci.yml).

<!-- vale gitlab.Spelling = NO -->

It includes Ruby, Go, Git, Git LFS, Chrome, Node, Yarn, PostgreSQL, and Graphics Magick.

<!-- vale gitlab.Spelling = YES -->

The images used in our pipelines are configured in the
[`gitlab-org/gitlab-build-images`](https://gitlab.com/gitlab-org/gitlab-build-images)
project, which is push-mirrored to [`gitlab/gitlab-build-images`](https://dev.gitlab.org/gitlab/gitlab-build-images)
for redundancy.

The current version of the build images can be found in the
["Used by GitLab section"](https://gitlab.com/gitlab-org/gitlab-build-images/blob/master/.gitlab-ci.yml).

## Default variables

In addition to the [predefined CI/CD variables](../../ci/variables/predefined_variables.md),
each pipeline includes default variables defined in
[`.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab-ci.yml).

## Stages

The current stages are:

- `sync`: This stage is used to synchronize changes from [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) to
  [`gitlab-org/gitlab-foss`](https://gitlab.com/gitlab-org/gitlab-foss).
- `prepare`: This stage includes jobs that prepare artifacts that are needed by
  jobs in subsequent stages.
- `build-images`: This stage includes jobs that prepare Docker images
  that are needed by jobs in subsequent stages or downstream pipelines.
- `fixtures`: This stage includes jobs that prepare fixtures needed by frontend tests.
- `lint`: This stage includes linting and static analysis jobs.
- `test`: This stage includes most of the tests, and DB/migration jobs.
- `post-test`: This stage includes jobs that build reports or gather data from
  the `test` stage's jobs (for example, coverage, Knapsack metadata, and so on).
- `review`: This stage includes jobs that build the CNG images, deploy them, and
  run end-to-end tests against Review Apps (see [Review Apps](../testing_guide/review_apps.md) for details).
  It also includes Docs Review App jobs.
- `qa`: This stage includes jobs that perform QA tasks against the Review App
  that is deployed in stage `review`.
- `post-qa`: This stage includes jobs that build reports or gather data from
  the `qa` stage's jobs (for example, Review App performance report).
- `pages`: This stage includes a job that deploys the various reports as
  GitLab Pages (for example, [`coverage-ruby`](https://gitlab-org.gitlab.io/gitlab/coverage-ruby/),
  and `webpack-report` (found at `https://gitlab-org.gitlab.io/gitlab/webpack-report/`, but there is
  [an issue with the deployment](https://gitlab.com/gitlab-org/gitlab/-/issues/233458)).
- `notify`: This stage includes jobs that notify various failures to Slack.

## Dependency Proxy

Some of the jobs are using images from Docker Hub, where we also use
`${GITLAB_DEPENDENCY_PROXY_ADDRESS}` as a prefix to the image path, so that we pull
images from our [Dependency Proxy](../../user/packages/dependency_proxy/index.md).
By default, this variable is set from the value of `${GITLAB_DEPENDENCY_PROXY}`.

`${GITLAB_DEPENDENCY_PROXY}` is a group CI/CD variable defined in
[`gitlab-org`](https://gitlab.com/gitlab-org) as
`${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/`. This means when we use an image
defined as:

```yaml
image: ${GITLAB_DEPENDENCY_PROXY_ADDRESS}alpine:edge
```

Projects in the `gitlab-org` group pull from the Dependency Proxy, while
forks that reside on any other personal namespaces or groups fall back to
Docker Hub unless `${GITLAB_DEPENDENCY_PROXY}` is also defined there.

### Work around for when a pipeline is started by a Project access token user

When a pipeline is started by a Project access token user (for example, the `release-tools approver bot` user which
automatically updates the Gitaly version used in the main project),
[the Dependency proxy isn't accessible](https://gitlab.com/gitlab-org/gitlab/-/issues/332411#note_1130388163)
and the job fails at the `Preparing the "docker+machine" executor` step.
To work around that, we have a special workflow rule, that overrides the
`${GITLAB_DEPENDENCY_PROXY_ADDRESS}` variable so that Dependency proxy isn't used in that case:

```yaml
- if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH && $GITLAB_USER_LOGIN =~ /project_\d+_bot\d*/'
  variables:
    GITLAB_DEPENDENCY_PROXY_ADDRESS: ""
```

NOTE:
We don't directly override the `${GITLAB_DEPENDENCY_PROXY}` variable because group-level
variables have higher precedence over `.gitlab-ci.yml` variables.

## Common job definitions

Most of the jobs [extend from a few CI definitions](../../ci/yaml/index.md#extends)
defined in [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml)
that are scoped to a single [configuration keyword](../../ci/yaml/index.md#job-keywords).

| Job definitions  | Description |
|------------------|-------------|
| `.default-retry` | Allows a job to [retry](../../ci/yaml/index.md#retry) upon `unknown_failure`, `api_failure`, `runner_system_failure`, `job_execution_timeout`, or `stuck_or_timeout_failure`. |
| `.default-before_script` | Allows a job to use a default `before_script` definition suitable for Ruby/Rails tasks that may need a database running (for example, tests). |
| `.setup-test-env-cache` | Allows a job to use a default `cache` definition suitable for setting up test environment for subsequent Ruby/Rails tasks. |
| `.ruby-cache` | Allows a job to use a default `cache` definition suitable for Ruby tasks. |
| `.static-analysis-cache` | Allows a job to use a default `cache` definition suitable for static analysis tasks. |
| `.coverage-cache` | Allows a job to use a default `cache` definition suitable for coverage tasks. |
| `.qa-cache` | Allows a job to use a default `cache` definition suitable for QA tasks. |
| `.yarn-cache` | Allows a job to use a default `cache` definition suitable for frontend jobs that do a `yarn install`. |
| `.assets-compile-cache` | Allows a job to use a default `cache` definition suitable for frontend jobs that compile assets. |
| `.use-pg13` | Allows a job to use the `postgres` 13, `redis`, and `rediscluster` services (see [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml) for the specific versions of the services). |
| `.use-pg13-ee` | Same as `.use-pg13` but also use an `elasticsearch` service (see [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml) for the specific version of the service). |
| `.use-pg14` | Allows a job to use the `postgres` 14, `redis`, and `rediscluster` services (see [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml) for the specific versions of the services). |
| `.use-pg14-ee` | Same as `.use-pg14` but also use an `elasticsearch` service (see [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml) for the specific version of the service). |
| `.use-pg15` | Allows a job to use the `postgres` 15, `redis`, and `rediscluster` services (see [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml) for the specific versions of the services). |
| `.use-pg15-ee` | Same as `.use-pg15` but also use an `elasticsearch` service (see [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml) for the specific version of the service). |
| `.use-kaniko` | Allows a job to use the `kaniko` tool to build Docker images. |
| `.as-if-foss` | Simulate the FOSS project by setting the `FOSS_ONLY='1'` CI/CD variable. |
| `.use-docker-in-docker` | Allows a job to use Docker in Docker. |

## `rules`, `if:` conditions and `changes:` patterns

We're using the [`rules` keyword](../../ci/yaml/index.md#rules) extensively.

All `rules` definitions are defined in
[`rules.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/rules.gitlab-ci.yml),
then included in individual jobs via [`extends`](../../ci/yaml/index.md#extends).

The `rules` definitions are composed of `if:` conditions and `changes:` patterns,
which are also defined in
[`rules.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/rules.gitlab-ci.yml)
and included in `rules` definitions via [YAML anchors](../../ci/yaml/yaml_optimization.md#anchors)

### `if:` conditions

<!-- vale gitlab.Substitutions = NO -->

| `if:` conditions | Description | Notes |
|------------------|-------------|-------|
| `if-not-canonical-namespace`                                 | Matches if the project isn't in the canonical (`gitlab-org/` and `gitlab-cn/`) or security (`gitlab-org/security`) namespace. | Use to create a job for forks (by using `when: on_success` or `when: manual`), or **not** create a job for forks (by using `when: never`). |
| `if-not-ee`                                                  | Matches if the project isn't EE (that is, project name isn't `gitlab` or `gitlab-ee`). | Use to create a job only in the FOSS project (by using `when: on_success` or `when: manual`), or **not** create a job if the project is EE (by using `when: never`). |
| `if-not-foss`                                                | Matches if the project isn't FOSS (that is, project name isn't `gitlab-foss`, `gitlab-ce`, or `gitlabhq`). | Use to create a job only in the EE project (by using `when: on_success` or `when: manual`), or **not** create a job if the project is FOSS (by using `when: never`). |
| `if-default-refs`                                            | Matches if the pipeline is for `master`, `main`, `/^[\d-]+-stable(-ee)?$/` (stable branches), `/^\d+-\d+-auto-deploy-\d+$/` (auto-deploy branches), `/^security\//` (security branches), merge requests, and tags. | Note that jobs aren't created for branches with this default configuration. |
| `if-master-refs`                                             | Matches if the current branch is `master` or `main`. | |
| `if-master-push`                                             | Matches if the current branch is `master` or `main` and pipeline source is `push`. | |
| `if-master-schedule-maintenance`                                | Matches if the current branch is `master` or `main` and pipeline runs on a 2-hourly schedule. | |
| `if-master-schedule-nightly`                                 | Matches if the current branch is `master` or `main` and pipeline runs on a nightly schedule. | |
| `if-auto-deploy-branches`                                    | Matches if the current branch is an auto-deploy one. | |
| `if-master-or-tag`                                           | Matches if the pipeline is for the `master` or `main` branch or for a tag. | |
| `if-merge-request`                                           | Matches if the pipeline is for a merge request. | |
| `if-merge-request-title-as-if-foss`                          | Matches if the pipeline is for a merge request and the MR has label ~"pipeline:run-as-if-foss" | |
| `if-merge-request-title-update-caches`                       | Matches if the pipeline is for a merge request and the MR has label ~"pipeline:update-cache". | |
| `if-merge-request-title-run-all-rspec`                       | Matches if the pipeline is for a merge request and the MR has label ~"pipeline:run-all-rspec". | |
| `if-security-merge-request`                                  | Matches if the pipeline is for a security merge request. | |
| `if-security-schedule`                                       | Matches if the pipeline is for a security scheduled pipeline. | |
| `if-nightly-master-schedule`                                 | Matches if the pipeline is for a `master` scheduled pipeline with `$NIGHTLY` set. | |
| `if-dot-com-gitlab-org-schedule`                             | Limits jobs creation to scheduled pipelines for the `gitlab-org` group on GitLab.com. | |
| `if-dot-com-gitlab-org-master`                               | Limits jobs creation to the `master` or `main` branch for the `gitlab-org` group on GitLab.com. | |
| `if-dot-com-gitlab-org-merge-request`                        | Limits jobs creation to merge requests for the `gitlab-org` group on GitLab.com. | |
| `if-dot-com-gitlab-org-and-security-tag`                     | Limits job creation to tags for the `gitlab-org` and `gitlab-org/security` groups on GitLab.com. | |
| `if-dot-com-gitlab-org-and-security-merge-request`           | Limit jobs creation to merge requests for the `gitlab-org` and `gitlab-org/security` groups on GitLab.com. | |
| `if-dot-com-gitlab-org-and-security-tag`                     | Limit jobs creation to tags for the `gitlab-org` and `gitlab-org/security` groups on GitLab.com. | |
| `if-dot-com-ee-schedule`                                     | Limits jobs to scheduled pipelines for the `gitlab-org/gitlab` project on GitLab.com. | |

<!-- vale gitlab.Substitutions = YES -->

### `changes:` patterns

| `changes:` patterns          | Description                                                              |
|------------------------------|--------------------------------------------------------------------------|
| `ci-patterns`                | Only create job for CI configuration-related changes.                    |
| `ci-build-images-patterns`   | Only create job for CI configuration-related changes related to the `build-images` stage. |
| `ci-review-patterns`         | Only create job for CI configuration-related changes related to the `review` stage. |
| `ci-qa-patterns`             | Only create job for CI configuration-related changes related to the `qa` stage. |
| `yaml-lint-patterns`         | Only create job for YAML-related changes.                                |
| `docs-patterns`              | Only create job for docs-related changes.                                |
| `frontend-dependency-patterns` | Only create job when frontend dependencies are updated (for example, `package.json`, and `yarn.lock`) changes. |
| `frontend-patterns-for-as-if-foss`  | Only create job for frontend-related changes that have impact on FOSS. |
| `backend-patterns`           | Only create job for backend-related changes.                           |
| `db-patterns`                | Only create job for DB-related changes. |
| `backstage-patterns`         | Only create job for backstage-related changes (that is, Danger, fixtures, RuboCop, specs). |
| `code-patterns`              | Only create job for code-related changes.                                |
| `qa-patterns`                | Only create job for QA-related changes.                                  |
| `code-backstage-patterns`    | Combination of `code-patterns` and `backstage-patterns`.                 |
| `code-qa-patterns`           | Combination of `code-patterns` and `qa-patterns`.                        |
| `code-backstage-qa-patterns` | Combination of `code-patterns`, `backstage-patterns`, and `qa-patterns`. |
| `static-analysis-patterns`   | Only create jobs for Static Analytics configuration-related changes.     |

## Best Practices

### When to use `extends:`, `<<: *xyz` (YAML anchors), or `!reference`

[Reference](../../ci/yaml/yaml_optimization.md)

#### Key takeaways

- If you need to **extend a hash**, you should use `extends`
- If you need to **extend an array**, you'll need to use `!reference`, or `YAML anchors` as last resort
- For more complex cases (for example, extend hash inside array, extend array inside hash, ...), you'll have to use `!reference` or `YAML anchors`

#### What can `extends` and `YAML anchors` do?

##### `extends`

- Deep merge for hashes
- NO merge for arrays. It overwrites ([source](../../ci/yaml/yaml_optimization.md#merge-details))

##### YAML anchors

- NO deep merge for hashes, BUT it can be used to extend a hash (see the example below)
- NO merge for arrays, BUT it can be used to extend an array (see the example below)

#### A great example

This example shows how to extend complex YAML data structures with `!reference` and `YAML anchors`:

```yaml
.strict-ee-only-rules:
  # `rules` is an array of hashes
  rules:
    - if: '$CI_PROJECT_NAME !~ /^gitlab(-ee)?$/ '
      when: never

# `if-security-merge-request` is a hash
.if-security-merge-request: &if-security-merge-request
  if: '$CI_PROJECT_NAMESPACE == "gitlab-org/security"'

# `code-qa-patterns` is an array
.code-qa-patterns: &code-qa-patterns
  - "{package.json,yarn.lock}"
  - ".browserslistrc"
  - "babel.config.js"
  - "jest.config.{base,integration,unit}.js"

.qa:rules:as-if-foss:
  rules:
    # We extend the `rules` array with an array of hashes directly
    - !reference [".strict-ee-only-rules", rules]
    # We extend a single array entry with a hash
    - <<: *if-security-merge-request
      # `changes` is an array, so we pass it an entire array
      changes: *code-qa-patterns

qa:selectors-as-if-foss:
  # We include the rules from .qa:rules:as-if-foss in this job
  extends:
    - .qa:rules:as-if-foss
```

### Extend the `.fast-no-clone-job` job

Downloading the branch for the canonical project takes between 20 and 30 seconds.

Some jobs only need a limited number of files, which we can download via the GitLab API.

You can skip a job `git clone`/`git fetch` by adding the following pattern to a job.

#### Scenario 1: no `before_script` is defined in the job

You can just extend the `.fast-no-clone-job`:

```yaml
  extends:
    - .fast-no-clone-job
  variables:
    FILES_TO_DOWNLOAD: >
      scripts/rspec_helpers.sh
      scripts/slack
```

#### Scenario 2: a `before_script` block is already defined in the job

You have to include the `.fast-no-clone-job` via a `!reference` as well:

```yaml
  extends:
    - .fast-no-clone-job
  variables:
    FILES_TO_DOWNLOAD: >
      scripts/rspec_helpers.sh
      scripts/slack
  before_script:
    - !reference [".fast-no-clone-job", before_script]
    - # [...]
```

- The job sets the `GIT_STRATEGY` to `none`.
- The files are downloaded from current project, on the current `CI_COMMIT_SHA`
- We use the `PROJECT_TOKEN_FOR_CI_SCRIPTS_API_USAGE` to fetch files from the repository (particularly important if we are in a private project)

Below is an example on how to convert a job using this pattern:

```yaml
# Before
my-job:
  image: ruby
  stage: prepare
  script: # This job requires two files to function
    - source ./scripts/rspec_helpers.sh
    - source ./scripts/slack
    - echo "The files were successfully sourced!"

# After
my-job:
  extends:
    - .fast-no-clone-job
  image: ruby
  stage: prepare
  variables:
    FILES_TO_DOWNLOAD: >
      scripts/rspec_helpers.sh
      scripts/slack
  script: # This job requires two files to function
    - source ./scripts/rspec_helpers.sh
    - source ./scripts/slack
    - echo "The files were successfully sourced!"
```

#### Caveats

- This pattern does not work if a script relies on `git` to access the repository, because we don't have the repository without cloning or fetching.
- The job using this pattern needs to have `curl` available.

#### Where is this pattern used?

- For now, we use this pattern for the following jobs, and those do not block private repositories:
  - `review-build-cng-env` for:
    - `GITALY_SERVER_VERSION`
    - `GITLAB_ELASTICSEARCH_INDEXER_VERSION`
    - `GITLAB_KAS_VERSION`
    - `GITLAB_METRICS_EXPORTER_VERSION`
    - `GITLAB_PAGES_VERSION`
    - `GITLAB_SHELL_VERSION`
    - `scripts/trigger-build.rb`
    - `VERSION`
  - `review-deploy` for:
    - `GITALY_SERVER_VERSION`
    - `GITLAB_SHELL_VERSION`
    - `scripts/review_apps/review-apps.sh`
    - `scripts/review_apps/seed-dast-test-data.sh`
    - `VERSION`

Additionally, `scripts/utils.sh` is always downloaded from the API when this pattern is used (this file contains the code for `.fast-no-clone-job`).
