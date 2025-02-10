---
stage: none
group: Engineering Productivity
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: CI configuration internals
---

## Workflow rules

Pipelines for the GitLab project are created using the [`workflow:rules` keyword](../../ci/yaml/_index.md#workflow)
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

- [JiHu validation pipeline](https://handbook.gitlab.com/handbook/ceo/chief-of-staff-team/jihu-support/jihu-validation-pipelines/)

See the next section for how we can enable pipelines without using
`$FORCE_GITLAB_CI`.

#### Alternative to `$FORCE_GITLAB_CI`

Essentially, we use different variables to enable different pipelines.
An example doing this is `$START_AS_IF_FOSS`. When we want to trigger a
cross project FOSS pipeline, we set `$START_AS_IF_FOSS`, along with a set of
other variables like `$ENABLE_RSPEC_UNIT`, `$ENABLE_RSPEC_SYSTEM`, and so on
so forth to enable each jobs we want to run in the as-if-foss cross project
downstream pipeline.

The advantage of this over `$FORCE_GITLAB_CI` is that we have full control
over how we want to run the pipeline because `$START_AS_IF_FOSS` is only used
for this purpose, and changing how the pipeline behaves under this variable
will not affect other types of pipelines, while using `$FORCE_GITLAB_CI` we
do not know what exactly the pipeline is because it's used for multiple
purposes.

## Default image

The default image is defined in [`.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab-ci.yml).

<!-- vale gitlab_base.Spelling = NO -->

It includes Ruby, Go, Git, Git LFS, Chrome, Node, Yarn, PostgreSQL, and Graphics Magick.

<!-- vale gitlab_base.Spelling = YES -->

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
  run end-to-end tests against review apps (see [review apps](../testing_guide/review_apps.md) for details).
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
images from our [Dependency Proxy](../../user/packages/dependency_proxy/_index.md).
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

Most of the jobs [extend from a few CI definitions](../../ci/yaml/_index.md#extends)
defined in [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml)
that are scoped to a single [configuration keyword](../../ci/yaml/_index.md#job-keywords).

| Job definitions  | Description |
|------------------|-------------|
| `.default-retry` | Allows a job to [retry](../../ci/yaml/_index.md#retry) upon `unknown_failure`, `api_failure`, `runner_system_failure`, `job_execution_timeout`, or `stuck_or_timeout_failure`. |
| `.default-before_script` | Allows a job to use a default `before_script` definition suitable for Ruby/Rails tasks that may need a database running (for example, tests). |
| `.repo-from-artifacts` | Allows a job to fetch the repository from artifacts in `clone-gitlab-repo` instead of cloning. This should reduce GitLab.com Gitaly load and also slightly improve the speed because downloading from artifacts is faster than cloning. Note that this should be avoided to be used with jobs having `needs: []` because otherwise it'll start later and we normally want all jobs to start as soon as possible. Use this only on jobs which has other dependencies so that we don't wait longer than just cloning. Note that this behavior can be controlled via `CI_FETCH_REPO_GIT_STRATEGY`. See [Fetch repository via artifacts instead of cloning/fetching from Gitaly](performance.md#fetch-repository-via-artifacts-instead-of-cloningfetching-from-gitaly) for more details. |
| `.setup-test-env-cache` | Allows a job to use a default `cache` definition suitable for setting up test environment for subsequent Ruby/Rails tasks. |
| `.ruby-cache` | Allows a job to use a default `cache` definition suitable for Ruby tasks. |
| `.static-analysis-cache` | Allows a job to use a default `cache` definition suitable for static analysis tasks. |
| `.ruby-gems-coverage-cache` | Allows a job to use a default `cache` definition suitable for coverage tasks. |
| `.qa-cache` | Allows a job to use a default `cache` definition suitable for QA tasks. |
| `.yarn-cache` | Allows a job to use a default `cache` definition suitable for frontend jobs that do a `yarn install`. |
| `.assets-compile-cache` | Allows a job to use a default `cache` definition suitable for frontend jobs that compile assets. |
| `.use-pg14` | Allows a job to use the `postgres` 14, `redis`, and `rediscluster` services (see [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml) for the specific versions of the services). |
| `.use-pg14-ee` | Same as `.use-pg14` but also use an `elasticsearch` service (see [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml) for the specific version of the service). |
| `.use-pg15` | Allows a job to use the `postgres` 15, `redis`, and `rediscluster` services (see [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml) for the specific versions of the services). |
| `.use-pg15-ee` | Same as `.use-pg15` but also use an `elasticsearch` service (see [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml) for the specific version of the service). |
| `.use-pg16` | Allows a job to use the `postgres` 16, `redis`, and `rediscluster` services (see [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml) for the specific versions of the services). |
| `.use-pg16-ee` | Same as `.use-pg16` but also use an `elasticsearch` service (see [`.gitlab/ci/global.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml) for the specific version of the service). |
| `.use-kaniko` | Allows a job to use the `kaniko` tool to build Docker images. |
| `.as-if-foss` | Simulate the FOSS project by setting the `FOSS_ONLY='1'` CI/CD variable. |
| `.use-docker-in-docker` | Allows a job to use Docker in Docker. For more details, see the [handbook about CI/CD configuration](https://handbook.gitlab.com/handbook/engineering/gitlab-repositories/#cicd-configuration). |

## `rules`, `if:` conditions and `changes:` patterns

We're using the [`rules` keyword](../../ci/yaml/_index.md#rules) extensively.

All `rules` definitions are defined in
[`rules.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/rules.gitlab-ci.yml),
then included in individual jobs via [`extends`](../../ci/yaml/_index.md#extends).

The `rules` definitions are composed of `if:` conditions and `changes:` patterns,
which are also defined in
[`rules.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/rules.gitlab-ci.yml)
and included in `rules` definitions via [YAML anchors](../../ci/yaml/yaml_optimization.md#anchors)

### `if:` conditions

<!-- vale gitlab_base.Substitutions = NO -->

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
| `if-merge-request-labels-run-all-rspec`                      | Matches if the pipeline is for a merge request and the MR has label ~"pipeline:run-all-rspec". | |
| `if-merge-request-labels-run-cs-evaluation`                  | Matches if the pipeline is for a merge request and the MR has label ~"pipeline:run-CS-evaluation". | |
| `if-security-merge-request`                                  | Matches if the pipeline is for a security merge request. | |
| `if-security-schedule`                                       | Matches if the pipeline is for a security scheduled pipeline. | |
| `if-nightly-master-schedule`                                 | Matches if the pipeline is for a `master` scheduled pipeline with `$NIGHTLY` set. | |
| `if-dot-com-gitlab-org-schedule`                             | Limits jobs creation to scheduled pipelines for the `gitlab-org` group on GitLab.com. | |
| `if-dot-com-gitlab-org-master`                               | Limits jobs creation to the `master` or `main` branch for the `gitlab-org` group on GitLab.com. | |
| `if-dot-com-gitlab-org-merge-request`                        | Limits jobs creation to merge requests for the `gitlab-org` group on GitLab.com. | |
| `if-dot-com-ee-schedule`                                     | Limits jobs to scheduled pipelines for the `gitlab-org/gitlab` project on GitLab.com. | |

<!-- vale gitlab_base.Substitutions = YES -->

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

## Custom exit codes

GitLab CI uses custom exit codes to categorize different types of job failures. This helps with automated failure tracking and retry logic. To see which exit codes trigger automatic retries, check the retry rules in [GitLab global CI configuration](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/global.gitlab-ci.yml).

The table below lists current exit codes and their meanings:

| exit code |                         Description   |
|-----------|---------------------------------------|
|110        | network connection error              |
|111        | low disk space                        |
|112        | known flaky test failure              |
|160        | failed to upload/download job artifact|
|161        | 5XX server error                      |
|162        | Gitaly spawn failure                  |
|163        | RSpec job timeout                     |
|164        | Redis cluster error                   |
|165        | segmentation fault                    |
|166        | EEXIST: file already exists           |
|167        | `gitlab.com` overloaded               |

This list can be expanded as new failure patterns emerge. To avoid conflicts with standard Bash exit codes, new custom codes must be 160 or higher.

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

This applies to the parent sections the job extends from as well.

You can just extend the `.fast-no-clone-job`:

**Before:**

```yaml
  # Note: No `extends:` is present in the job
  a-job:
    script:
      - source scripts/rspec_helpers.sh scripts/slack
      - echo "No need for a git clone!"
```

**After:**

```yaml
  # Note: No `extends:` is present in the job
  a-job:
    extends:
      - .fast-no-clone-job
    variables:
      FILES_TO_DOWNLOAD: >
        scripts/rspec_helpers.sh
        scripts/slack
    script:
      - source scripts/rspec_helpers.sh scripts/slack
      - echo "No need for a git clone!"
```

#### Scenario 2: a `before_script` block is already defined in the job (or in jobs it extends)

For this scenario, you have to:

1. Extend the `.fast-no-clone-job` as in the first scenario (this will merge the `FILES_TO_DOWNLOAD` variable with the other variables)
1. Make sure the `before_script` section from `.fast-no-clone-job` is referenced in the `before_script` we use for this job.

**Before:**

```yaml
  .base-job:
    before_script:
      echo "Hello from .base-job"

  a-job:
    extends:
      - .base-job
    script:
      - source scripts/rspec_helpers.sh scripts/slack
      - echo "No need for a git clone!"
```

**After:**

```yaml
  .base-job:
    before_script:
      echo "Hello from .base-job"

  a-job:
    extends:
      - .base-job
      - .fast-no-clone-job
    variables:
      FILES_TO_DOWNLOAD: >
        scripts/rspec_helpers.sh
        scripts/slack
    before_script:
      - !reference [".fast-no-clone-job", before_script]
      - !reference [".base-job", before_script]
    script:
      - source scripts/rspec_helpers.sh scripts/slack
      - echo "No need for a git clone!"
```

#### Caveats

- This pattern does not work if a script relies on `git` to access the repository, because we don't have the repository without cloning or fetching.
- The job using this pattern needs to have `curl` available.
- If you need to run `bundle install` in the job (even using `BUNDLE_ONLY`), you need to:
  - Download the gems that are stored in the `gitlab-org/gitlab` project.
    - You can use the `download_local_gems` shell command for that purpose.
  - Include the `Gemfile`, `Gemfile.lock` and `Gemfile.checksum` (if applicable)

#### Where is this pattern used?

- For now, we use this pattern for the following jobs, and those do not block private repositories:
  - `review-build-cng-env` for:
    - `GITALY_SERVER_VERSION`
    - `GITLAB_ELASTICSEARCH_INDEXER_VERSION`
    - `GITLAB_KAS_VERSION`
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
  - `rspec:coverage` for:
    - `config/bundler_setup.rb`
    - `Gemfile`
    - `Gemfile.checksum`
    - `Gemfile.lock`
    - `scripts/merge-simplecov`
    - `spec/simplecov_env_core.rb`
    - `spec/simplecov_env.rb`
  - `prepare-as-if-foss-env` for:
    - `scripts/setup/generate-as-if-foss-env.rb`

Additionally, `scripts/utils.sh` is always downloaded from the API when this pattern is used (this file contains the code for `.fast-no-clone-job`).

### Runner tags

On GitLab.com, both unprivileged and privileged runners are
available. For projects in the `gitlab-org` group and forks of those
projects, only one of the following tags should be added to a job:

- `gitlab-org`: Jobs randomly use privileged and unprivileged runners.
- `gitlab-org-docker`: Jobs must use a privileged runner. If you need [Docker-in-Docker support](../../ci/docker/using_docker_build.md#use-docker-in-docker),
  use `gitlab-org-docker` instead of `gitlab-org`.

The `gitlab-org-docker` tag is added by the `.use-docker-in-docker` job
definition above.

To ensure compatibility with forks, avoid using both `gitlab-org` and
`gitlab-org-docker` simultaneously. No instance runners
have both `gitlab-org` and `gitlab-org-docker` tags. For forks of
`gitlab-org` projects, jobs will get stuck if both tags are supplied because
no matching runners are available.

See [the GitLab Repositories handbook page](https://handbook.gitlab.com/handbook/engineering/gitlab-repositories/#cicd-configuration)
for more information.

### Using the `gitlab` Ruby gem in the canonical project

When calling `require 'gitlab'` in the canonical project, it will require the `lib/gitlab.rb` file when `$LOAD_PATH` has `lib`, which happens when we're loading the application (`config/application.rb`) or tests (`spec/spec_helper.rb`).

This means we're not able to load the `gitlab` gem under the above conditions and even if we can, the constant name will conflict, breaking internal assumptions and causing random errors.
If you are working on a script that is using [the `gitlab` Ruby gem](https://github.com/NARKOZ/gitlab), you will need to take a few precautions:

#### 1 - Conditional require of the gem

To avoid potential conflicts, only require the `gitlab` gem if the `Gitlab` constant isn't defined:

```ruby
# Bad
require 'gitlab'

# Good
if Object.const_defined?(:RSpec)
  # Ok, we're testing, we know we're going to stub `Gitlab`, so we just ignore
else
  require 'gitlab'

  if Gitlab.singleton_class.method_defined?(:com?)
    abort 'lib/gitlab.rb is loaded, and this means we can no longer load the client and we cannot proceed'
  end
end
```

#### 2 - Mock the `gitlab` gem entirely in your specs

In your specs, `require 'gitlab'` will reference the `lib/gitlab.rb` file:

```ruby
# Bad
allow(GitLab).to receive(:a_method).and_return(...)

# Good
client = double('GitLab')
# In order to easily stub the client, consider using a method to return the client.
# We can then stub the method to return our fake client, which we can further stub its methods.
#
# This is the pattern followed below
let(:instance) { described_class.new }

allow(instance).to receive(:gitlab).and_return(client)
allow(client).to receive(:a_method).and_return(...)
```

In case you need to query jobs for instance, the following snippet will be useful:

```ruby
# Bad
allow(GitLab).to receive(:pipeline_jobs).and_return(...)

# Good
#
# rubocop:disable RSpec/VerifiedDoubles -- We do not load the Gitlab client directly
client = double('GitLab')
allow(instance).to receive(:gitlab).and_return(client)

jobs = ['job1', 'job2']
allow(client).to yield_jobs(:pipeline_jobs, jobs)

def yield_jobs(api_method, jobs)
  messages = receive_message_chain(api_method, :auto_paginate)

  jobs.inject(messages) do |stub, job_name|
    stub.and_yield(double(name: job_name))
  end
end
# rubocop:enable RSpec/VerifiedDoubles
```

#### 3 - Do not call your script with `bundle exec`

Executing with `bundle exec` will change the `$LOAD_PATH` for Ruby, and it will load `lib/gitlab.rb` when calling `require 'gitlab'`:

```shell
# Bad
bundle exec scripts/my-script.rb

# Good
scripts/my-script.rb
```

## CI Configuration Testing

We now have RSpec tests to verify changes to the CI configuration by simulating pipeline creation with the updated YAML files. You can find these tests and a documentation of the current test coverage in [`spec/dot_gitlab_ci/job_dependency_spec.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/dot_gitlab_ci/job_dependency_spec.rb).

### How Do the Tests Work

With the help of `Ci::CreatePipelineService`, we are able to simulate pipeline creation with different attributes such as branch name, MR labels, pipeline source (scheduled v.s push), pipeline type (merge train v.s merged results), etc. This is the same service utilized by the GitLab CI Lint API for validating CI/CD configurations.

These tests will automatically run for merge requests that update CI configurations. However, team members can opt to skip these tests by adding the label ~"pipeline:skip-ci-validation" to their merge requests.

Running these tests locally is encouraged, as it provides the fastest feedback.
