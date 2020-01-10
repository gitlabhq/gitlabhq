---
type: reference
---

# GitLab CI/CD Pipeline Configuration Reference

GitLab CI/CD [pipelines](../pipelines.md) are configured using a YAML file called `.gitlab-ci.yml` within each project.

The `.gitlab-ci.yml` file defines the structure and order of the pipelines and determines:

- What to execute using [GitLab Runner](https://docs.gitlab.com/runner/).
- What decisions to make when specific conditions are encountered. For example, when a process succeeds or fails.

This topic covers CI/CD pipeline configuration. For other CI/CD configuration information, see:

- [GitLab CI/CD Variables](../variables/README.md), for configuring the environment the pipelines run in.
- [GitLab Runner advanced configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration.html), for configuring GitLab Runner.

We have complete examples of configuring pipelines:

- For a quick introduction to GitLab CI, follow our [quick start guide](../quick_start/README.md).
- For a collection of examples, see [GitLab CI/CD Examples](../examples/README.md).
- To see a large `.gitlab-ci.yml` file used in an enterprise, see the [`.gitlab-ci.yml` file for `gitlab`](https://gitlab.com/gitlab-org/gitlab/blob/master/.gitlab-ci.yml).

NOTE: **Note:**
If you have a [mirrored repository where GitLab pulls from](../../user/project/repository/repository_mirroring.md#pulling-from-a-remote-repository-starter),
you may need to enable pipeline triggering in your project's
**Settings > Repository > Pull from a remote repository > Trigger pipelines for mirror updates**.

## Introduction

Pipeline configuration begins with jobs. Jobs are the most fundamental element of a `.gitlab-ci.yml` file.

Jobs are:

- Defined with constraints stating under what conditions they should be executed.
- Top-level elements with an arbitrary name and must contain at least the [`script`](#script) clause.
- Not limited in how many can be defined.

For example:

```yaml
job1:
  script: "execute-script-for-job1"

job2:
  script: "execute-script-for-job2"
```

The above example is the simplest possible CI/CD configuration with two separate
jobs, where each of the jobs executes a different command.
Of course a command can execute code directly (`./configure;make;make install`)
or run a script (`test.sh`) in the repository.

Jobs are picked up by [Runners](../runners/README.md) and executed within the
environment of the Runner. What is important, is that each job is run
independently from each other.

### Validate the `.gitlab-ci.yml`

Each instance of GitLab CI has an embedded debug tool called Lint, which validates the
content of your `.gitlab-ci.yml` files. You can find the Lint under the page `ci/lint` of your
project namespace. For example, `https://gitlab.example.com/gitlab-org/project-123/-/ci/lint`.

### Unavailable names for jobs

Each job must have a unique name, but there are a few **reserved `keywords` that
cannot be used as job names**:

- `image`
- `services`
- `stages`
- `types`
- `before_script`
- `after_script`
- `variables`
- `cache`
- `include`

### Using reserved keywords

If you get validation error when using specific values (for example, `true` or `false`), try to:

- Quote them.
- Change them to a different form. For example, `/bin/true`.

## Configuration parameters

A job is defined as a list of parameters that define the job's behavior.

The following table lists available parameters for jobs:

| Keyword                                            | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
|:---------------------------------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`script`](#script)                                | Shell script which is executed by Runner.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| [`image`](#image)                                  | Use docker images. Also available: `image:name` and `image:entrypoint`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| [`services`](#services)                            | Use docker services images. Also available: `services:name`, `services:alias`, `services:entrypoint`, and `services:command`.                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| [`before_script`](#before_script-and-after_script) | Override a set of commands that are executed before job.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| [`after_script`](#before_script-and-after_script)  | Override a set of commands that are executed after job.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| [`stages`](#stages)                                | Define stages in a pipeline.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| [`stage`](#stage)                                  | Defines a job stage (default: `test`).                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| [`only`](#onlyexcept-basic)                        | Limit when jobs are created. Also available: [`only:refs`, `only:kubernetes`, `only:variables`, and `only:changes`](#onlyexcept-advanced).                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| [`except`](#onlyexcept-basic)                      | Limit when jobs are not created. Also available: [`except:refs`, `except:kubernetes`, `except:variables`, and `except:changes`](#onlyexcept-advanced).                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| [`rules`](#rules)                                  | List of conditions to evaluate and determine selected attributes of a job, and whether or not it is created. May not be used alongside `only`/`except`.                                                                                                                                                                                                                                                                                                                                                                                                                                |
| [`tags`](#tags)                                    | List of tags which are used to select Runner.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| [`allow_failure`](#allow_failure)                  | Allow job to fail. Failed job doesn't contribute to commit status.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| [`when`](#when)                                    | When to run job. Also available: `when:manual` and `when:delayed`.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| [`environment`](#environment)                      | Name of an environment to which the job deploys. Also available: `environment:name`, `environment:url`, `environment:on_stop`, and `environment:action`.                                                                                                                                                                                                                                                                                                                                                                                                                                |
| [`cache`](#cache)                                  | List of files that should be cached between subsequent runs. Also available: `cache:paths`, `cache:key`, `cache:untracked`, and `cache:policy`.                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| [`artifacts`](#artifacts)                          | List of files and directories to attach to a job on success. Also available: `artifacts:paths`, `artifacts:expose_as`, `artifacts:name`, `artifacts:untracked`, `artifacts:when`, `artifacts:expire_in`, `artifacts:reports`, and `artifacts:reports:junit`.<br><br>In GitLab [Enterprise Edition](https://about.gitlab.com/pricing/), these are available: `artifacts:reports:codequality`, `artifacts:reports:sast`, `artifacts:reports:dependency_scanning`, `artifacts:reports:container_scanning`, `artifacts:reports:dast`, `artifacts:reports:license_management`, `artifacts:reports:performance` and `artifacts:reports:metrics`. |
| [`dependencies`](#dependencies)                    | Restrict which artifacts are passed to a specific job by providing a list of jobs to fetch artifacts from.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
| [`coverage`](#coverage)                            | Code coverage settings for a given job.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| [`retry`](#retry)                                  | When and how many times a job can be auto-retried in case of a failure.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| [`timeout`](#timeout)                              | Define a custom job-level timeout that takes precedence over the project-wide setting.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| [`parallel`](#parallel)                            | How many instances of a job should be run in parallel.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| [`trigger`](#trigger-premium)                      | Defines a downstream pipeline trigger.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| [`include`](#include)                              | Allows this job to include external YAML files. Also available: `include:local`, `include:file`, `include:template`, and `include:remote`.                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| [`extends`](#extends)                              | Configuration entries that this job is going to inherit from.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| [`pages`](#pages)                                  | Upload the result of a job to use with GitLab Pages.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| [`variables`](#variables)                          | Define job variables on a job level.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| [`interruptible`](#interruptible)                  | Defines if a job can be canceled when made redundant by a newer run.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| [`resource_group`](#resource_group)                | Limit job concurrency.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |

NOTE: **Note:**
Parameters `types` and `type` are [deprecated](#deprecated-parameters).

## Setting default parameters

Some parameters can be set globally as the default for all jobs using the
`default:` keyword. Default parameters can then be overridden by job-specific
configuration.

The following job parameters can be defined inside a `default:` block:

- [`image`](#image)
- [`services`](#services)
- [`before_script`](#before_script-and-after_script)
- [`after_script`](#before_script-and-after_script)
- [`tags`](#tags)
- [`cache`](#cache)
- [`artifacts`](#artifacts)
- [`retry`](#retry)
- [`timeout`](#timeout)
- [`interruptible`](#interruptible)

In the following example, the `ruby:2.5` image is set as the default for all
jobs except the `rspec 2.6` job, which uses the `ruby:2.6` image:

```yaml
default:
  image: ruby:2.5

rspec:
  script: bundle exec rspec

rspec 2.6:
  image: ruby:2.6
  script: bundle exec rspec
```

## Parameter details

The following are detailed explanations for parameters used to configure CI/CD pipelines.

### `script`

`script` is the only required keyword that a job needs. It's a shell script
which is executed by the Runner. For example:

```yaml
job:
  script: "bundle exec rspec"
```

This parameter can also contain several commands using an array:

```yaml
job:
  script:
    - uname -a
    - bundle exec rspec
```

NOTE: **Note:**
Sometimes, `script` commands will need to be wrapped in single or double quotes.
For example, commands that contain a colon (`:`) need to be wrapped in quotes so
that the YAML parser knows to interpret the whole thing as a string rather than
a "key: value" pair. Be careful when using special characters:
`:`, `{`, `}`, `[`, `]`, `,`, `&`, `*`, `#`, `?`, `|`, `-`, `<`, `>`, `=`, `!`, `%`, `@`, `` ` ``.

If any of the script commands return an exit code different from zero, the job
will fail and further commands will not be executed. This behavior can be avoided by
storing the exit code in a variable:

```yaml
job:
  script:
    - false && true; exit_code=$?
    - if [ $exit_code -ne 0 ]; then echo "Previous command failed"; fi;
```

#### YAML anchors for `script`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/23005) in GitLab 12.5.

You can use [YAML anchors](#anchors) with scripts, which makes it possible to
include a predefined list of commands in multiple jobs.

For example:

```yaml
.something: &something
- echo 'something'

job_name:
  script:
    - *something
    - echo 'this is the script'
```

### `image`

Used to specify [a Docker image](../docker/using_docker_images.md#what-is-an-image) to use for the job.

For:

- Simple definition examples, see [Define `image` and `services` from `.gitlab-ci.yml`](../docker/using_docker_images.md#define-image-and-services-from-gitlab-ciyml).
- Detailed usage information, refer to [Docker integration](../docker/README.md) documentation.

#### `image:name`

An [extended docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `image`](../docker/using_docker_images.md#available-settings-for-image).

#### `image:entrypoint`

An [extended docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `image`](../docker/using_docker_images.md#available-settings-for-image).

### `services`

Used to specify a [service Docker image](../docker/using_docker_images.md#what-is-a-service), linked to a base image specified in [`image`](#image).

For:

- Simple definition examples, see [Define `image` and `services` from `.gitlab-ci.yml`](../docker/using_docker_images.md#define-image-and-services-from-gitlab-ciyml).
- Detailed usage information, refer to [Docker integration](../docker/README.md) documentation.
- For example services, see [GitLab CI Services](../services/README.md).

#### `services:name`

An [extended docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see see [Available settings for `services`](../docker/using_docker_images.md#available-settings-for-services).

#### `services:alias`

An [extended docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see see [Available settings for `services`](../docker/using_docker_images.md#available-settings-for-services).

#### `services:entrypoint`

An [extended docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see see [Available settings for `services`](../docker/using_docker_images.md#available-settings-for-services).

#### `services:command`

An [extended docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see see [Available settings for `services`](../docker/using_docker_images.md#available-settings-for-services).

### `before_script` and `after_script`

> Introduced in GitLab 8.7 and requires GitLab Runner v1.2.

`before_script` is used to define a command that should be run before each
job, including deploy jobs, but after the restoration of any [artifacts](#artifacts).
This must be an array.

Scripts specified in `before_script` are concatenated with any scripts specified
in the main [`script`](#script), and executed together in a single shell.

`after_script` is used to define the command that will be run after each
job, including failed ones. This must be an array.

Scripts specified in `after_script` are executed in a new shell, separate from any
`before_script` or `script` scripts. As a result, they:

- Have a current working directory set back to the default.
- Have no access to changes done by scripts defined in `before_script` or `script`, including:
  - Command aliases and variables exported in `script` scripts.
  - Changes outside of the working tree (depending on the Runner executor), like
    software installed by a `before_script` or `script` script.
- Have a separate timeout, which is hard coded to 5 minutes. See
  [related issue](https://gitlab.com/gitlab-org/gitlab-runner/issues/2716) for details.
- Do not affect the job's exit code. If the `script` section succeeds and the
  `after_script` times out or fails, the job will exit with code `0` (`Job Succeeded`).

It's possible to overwrite a globally defined `before_script` or `after_script`
if you set it per-job:

```yaml
default:
  before_script:
    - global before script

job:
  before_script:
    - execute this instead of global before script
  script:
    - my command
  after_script:
    - execute this after my script
```

#### YAML anchors for `before_script` and `after_script`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/23005) in GitLab 12.5.

You can use [YAML anchors](#anchors) with `before_script` and `after_script`,
which makes it possible to include a predefined list of commands in multiple
jobs.

Example:

```yaml
.something_before: &something_before
- echo 'something before'

.something_after: &something_after
- echo 'something after'


job_name:
  before_script:
    - *something_before
  script:
    - echo 'this is the script'
  after_script:
    - *something_after
```

### `stages`

`stages` is used to define stages that can be used by jobs and is defined
globally.

The specification of `stages` allows for having flexible multi stage pipelines.
The ordering of elements in `stages` defines the ordering of jobs' execution:

1. Jobs of the same stage are run in parallel.
1. Jobs of the next stage are run after the jobs from the previous stage
   complete successfully.

Let's consider the following example, which defines 3 stages:

```yaml
stages:
  - build
  - test
  - deploy
```

1. First, all jobs of `build` are executed in parallel.
1. If all jobs of `build` succeed, the `test` jobs are executed in parallel.
1. If all jobs of `test` succeed, the `deploy` jobs are executed in parallel.
1. If all jobs of `deploy` succeed, the commit is marked as `passed`.
1. If any of the previous jobs fails, the commit is marked as `failed` and no
   jobs of further stage are executed.

There are also two edge cases worth mentioning:

1. If no `stages` are defined in `.gitlab-ci.yml`, then the `build`,
   `test` and `deploy` are allowed to be used as job's stage by default.
1. If a job doesn't specify a `stage`, the job is assigned the `test` stage.

#### `.pre` and `.post`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/31441) in GitLab 12.4.

The following stages are available to every pipeline:

- `.pre`, which is guaranteed to always be the first stage in a pipeline.
- `.post`, which is guaranteed to always be the last stage in a pipeline.

User-defined stages are executed after `.pre` and before `.post`.

The order of `.pre` and `.post` cannot be changed, even if defined out of order in `.gitlab-ci.yml`.
For example, the following are equivalent configuration:

- Configured in order:

  ```yml
  stages:
    - .pre
    - a
    - b
    - .post
  ```

- Configured out of order:

  ```yml
  stages:
    - a
    - .pre
    - b
    - .post
  ```

- Not explicitly configured:

  ```yml
  stages:
    - a
    - b
  ```

### `stage`

`stage` is defined per-job and relies on [`stages`](#stages) which is defined
globally. It allows to group jobs into different stages, and jobs of the same
`stage` are executed in parallel (subject to [certain conditions](#using-your-own-runners)). For example:

```yaml
stages:
  - build
  - test
  - deploy

job 0:
  stage: .pre
  script: make something useful before build stage

job 1:
  stage: build
  script: make build dependencies

job 2:
  stage: build
  script: make build artifacts

job 3:
  stage: test
  script: make test

job 4:
  stage: deploy
  script: make deploy

job 5:
  stage: .post
  script: make something useful at the end of pipeline
```

#### Using your own Runners

When using your own Runners, GitLab Runner runs only one job at a time by default (see the
`concurrent` flag in [Runner global settings](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section)
for more information).

Jobs will run on your own Runners in parallel only if:

- Run on different Runners.
- The Runner's `concurrent` setting has been changed.

### `only`/`except` (basic)

NOTE: **Note:**
The [`rules`](#rules) syntax is now the preferred method of setting job policies.
`only` and `except` are [candidates for deprecation](https://gitlab.com/gitlab-org/gitlab/issues/27449),
and may be removed in the future.

`only` and `except` are two parameters that set a job policy to limit when
jobs are created:

1. `only` defines the names of branches and tags for which the job will run.
1. `except` defines the names of branches and tags for which the job will
    **not** run.

There are a few rules that apply to the usage of job policy:

- `only` and `except` are inclusive. If both `only` and `except` are defined
   in a job specification, the ref is filtered by `only` and `except`.
- `only` and `except` allow the use of regular expressions ([supported regexp syntax](#supported-onlyexcept-regexp-syntax)).
- `only` and `except` allow to specify a repository path to filter jobs for
   forks.

In addition, `only` and `except` allow the use of special keywords:

| **Value** |  **Description**  |
| --------- |  ---------------- |
| `branches`       | When a Git reference of a pipeline is a branch.  |
| `tags`           | When a Git reference of a pipeline is a tag.  |
| `api`            | When pipeline has been triggered by a second pipelines API (not triggers API).  |
| `external`       | When using CI services other than GitLab. |
| `pipelines`      | For multi-project triggers, created using the API with `CI_JOB_TOKEN`. |
| `pushes`         | Pipeline is triggered by a `git push` by the user. |
| `schedules`      | For [scheduled pipelines][schedules]. |
| `triggers`       | For pipelines created using a trigger token. |
| `web`            | For pipelines created using **Run pipeline** button in GitLab UI (under your project's **Pipelines**). |
| `merge_requests` | When a merge request is created or updated (See [pipelines for merge requests](../merge_request_pipelines/index.md)). |
| `external_pull_requests`| When an external pull request on GitHub is created or updated (See [Pipelines for external pull requests](../ci_cd_for_external_repos/index.md#pipelines-for-external-pull-requests)). |
| `chat`          | For jobs created using a [GitLab ChatOps](../chatops/README.md) command. |

In the example below, `job` will run only for refs that start with `issue-`,
whereas all branches will be skipped:

```yaml
job:
  # use regexp
  only:
    - /^issue-.*$/
  # use special keyword
  except:
    - branches
```

Pattern matching is case-sensitive by default. Use `i` flag modifier, like
`/pattern/i` to make a pattern case-insensitive:

```yaml
job:
  # use regexp
  only:
    - /^issue-.*$/i
  # use special keyword
  except:
    - branches
```

In this example, `job` will run only for refs that are tagged, or if a build is
explicitly requested via an API trigger or a [Pipeline Schedule][schedules]:

```yaml
job:
  # use special keywords
  only:
    - tags
    - triggers
    - schedules
```

The repository path can be used to have jobs executed only for the parent
repository and not forks:

```yaml
job:
  only:
    - branches@gitlab-org/gitlab
  except:
    - master@gitlab-org/gitlab
    - /^release/.*$/@gitlab-org/gitlab
```

The above example will run `job` for all branches on `gitlab-org/gitlab`,
except `master` and those with names prefixed with `release/`.

If a job does not have an `only` rule, `only: ['branches', 'tags']` is set by
default. If it doesn't have an `except` rule, it is empty.

For example,

```yaml
job:
  script: echo 'test'
```

is translated to:

```yaml
job:
  script: echo 'test'
  only: ['branches', 'tags']
```

#### Regular expressions

Because `@` is used to denote the beginning of a ref's repository path,
matching a ref name containing the `@` character in a regular expression
requires the use of the hex character code match `\x40`.

Only the tag or branch name can be matched by a regular expression.
The repository path, if given, is always matched literally.

If a regular expression shall be used to match the tag or branch name,
the entire ref name part of the pattern has to be a regular expression,
and must be surrounded by `/`.
(With regular expression flags appended after the closing `/`.)
So `issue-/.*/` won't work to match all tag names or branch names
that begin with `issue-`.

TIP: **Tip**
Use anchors `^` and `$` to avoid the regular expression
matching only a substring of the tag name or branch name.
For example, `/^issue-.*$/` is equivalent to `/^issue-/`,
while just `/issue/` would also match a branch called `severe-issues`.

### Supported `only`/`except` regexp syntax

CAUTION: **Warning:**
This is a breaking change that was introduced with GitLab 11.9.4.

In GitLab 11.9.4, GitLab begun internally converting regexp used
in `only` and `except` parameters to [RE2](https://github.com/google/re2/wiki/Syntax).

This means that only subset of features provided by [Ruby Regexp](https://ruby-doc.org/core/Regexp.html)
is supported. [RE2](https://github.com/google/re2/wiki/Syntax) limits the set of features
provided due to computational complexity, which means some features became unavailable in GitLab 11.9.4.
For example, negative lookaheads.

For GitLab versions from 11.9.7 and up to GitLab 12.0, GitLab provides a feature flag that can be
enabled by administrators that allows users to use unsafe regexp syntax. This brings compatibility
with previously allowed syntax version and allows users to gracefully migrate to the new syntax.

```ruby
Feature.enable(:allow_unsafe_ruby_regexp)
```

### `only`/`except` (advanced)

CAUTION: **Warning:**
This is an _alpha_ feature, and it is subject to change at any time without
prior notice!

GitLab supports both simple and complex strategies, so it's possible to use an
array and a hash configuration scheme.

Four keys are available:

- `refs`
- `variables`
- `changes`
- `kubernetes`

If you use multiple keys under `only` or `except`, the keys will be evaluated as a
single conjoined expression. That is:

- `only:` means "include this job if all of the conditions match".
- `except:` means "exclude this job if any of the conditions match".

With `only`, individual keys are logically joined by an AND:

> (any of refs) AND (any of variables) AND (any of changes) AND (if Kubernetes is active)

`except` is implemented as a negation of this complete expression:

> NOT((any of refs) AND (any of variables) AND (any of changes) AND (if Kubernetes is active))

This, more intuitively, means the keys join by an OR. A functionally equivalent expression:

> (any of refs) OR (any of variables) OR (any of changes) OR (if Kubernetes is active)

#### `only:refs`/`except:refs`

> `refs` policy introduced in GitLab 10.0.

The `refs` strategy can take the same values as the
[simplified only/except configuration](#onlyexcept-basic).

In the example below, the `deploy` job is going to be created only when the
pipeline has been [scheduled][schedules] or runs for the `master` branch:

```yaml
deploy:
  only:
    refs:
      - master
      - schedules
```

#### `only:kubernetes`/`except:kubernetes`

> `kubernetes` policy introduced in GitLab 10.0.

The `kubernetes` strategy accepts only the `active` keyword.

In the example below, the `deploy` job is going to be created only when the
Kubernetes service is active in the project:

```yaml
deploy:
  only:
    kubernetes: active
```

#### `only:variables`/`except:variables`

> `variables` policy introduced in GitLab 10.7.

The `variables` keyword is used to define variables expressions. In other words,
you can use predefined variables / project / group or
environment-scoped variables to define an expression GitLab is going to
evaluate in order to decide whether a job should be created or not.

Examples of using variables expressions:

```yaml
deploy:
  script: cap staging deploy
  only:
    refs:
      - branches
    variables:
      - $RELEASE == "staging"
      - $STAGING
```

Another use case is excluding jobs depending on a commit message:

```yaml
end-to-end:
  script: rake test:end-to-end
  except:
    variables:
      - $CI_COMMIT_MESSAGE =~ /skip-end-to-end-tests/
```

Learn more about [variables expressions](../variables/README.md#environment-variables-expressions).

#### `only:changes`/`except:changes`

> `changes` policy [introduced][ce-19232] in GitLab 11.4.

Using the `changes` keyword with `only` or `except` makes it possible to define if
a job should be created based on files modified by a Git push event.

This means the `only:changes` policy is useful for pipelines where:

- `$CI_PIPELINE_SOURCE == 'push'`
- `$CI_PIPELINE_SOURCE == 'merge_request_event'`
- `$CI_PIPELINE_SOURCE == 'external_pull_request_event'`

If there is no Git push event, such as for pipelines with
[sources other than the three above](../variables/predefined_variables.html#variables-reference),
`changes` cannot determine if a given file is new or old, and will always
return true.

A basic example of using `only: changes`:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  only:
    changes:
      - Dockerfile
      - docker/scripts/*
      - dockerfiles/**/*
      - more_scripts/*.{rb,py,sh}
```

In the scenario above, when pushing commits to an existing branch in GitLab,
it creates and triggers the `docker build` job, provided that one of the
commits contains changes to any of the following:

- The `Dockerfile` file.
- Any of the files inside `docker/scripts/` directory.
- Any of the files and subdirectories inside the `dockerfiles` directory.
- Any of the files with `rb`, `py`, `sh` extensions inside the `more_scripts` directory.

CAUTION: **Warning:**
If using `only:changes` with [only allow merge requests to be merged if the pipeline succeeds](../../user/project/merge_requests/merge_when_pipeline_succeeds.md#only-allow-merge-requests-to-be-merged-if-the-pipeline-succeeds),
undesired behavior could result if you do not [also use `only:merge_requests`](#using-onlychanges-with-pipelines-for-merge-requests).

You can also use glob patterns to match multiple files in either the root directory
of the repo, or in _any_ directory within the repo, but they must be wrapped
in double quotes or GitLab will fail to parse the `.gitlab-ci.yml`. For example:

```yaml
test:
  script: npm run test
  only:
    changes:
      - "*.json"
      - "**/*.sql"
```

The following example will skip the `build` job if a change is detected in any file
in the root directory of the repo with a `.md` extension:

```yaml
build:
  script: npm run build
  except:
    changes:
      - "*.md"
```

CAUTION: **Warning:**
There are some points to be aware of when
[using this feature with new branches or tags *without* pipelines for merge requests](#using-onlychanges-without-pipelines-for-merge-requests).

##### Using `only:changes` with pipelines for merge requests

With [pipelines for merge requests](../merge_request_pipelines/index.md),
it is possible to define a job to be created based on files modified
in a merge request.

In order to deduce the correct base SHA of the source branch, we recommend combining
this keyword with `only: [merge_requests]`. This way, file differences are correctly
calculated from any further commits, thus all changes in the merge requests are properly
tested in pipelines.

For example:

```yaml
docker build service one:
  script: docker build -t my-service-one-image:$CI_COMMIT_REF_SLUG .
  only:
    refs:
      - merge_requests
    changes:
      - Dockerfile
      - service-one/**/*
```

In the scenario above, if a merge request is created or updated that changes
either files in `service-one` directory or the `Dockerfile`, GitLab creates
and triggers the `docker build service one` job.

Note that if [pipelines for merge requests](../merge_request_pipelines/index.md) is
combined with `only: [change]`, but `only: [merge_requests]` is omitted, there could be
unwanted behavior.

For example:

```yaml
docker build service one:
  script: docker build -t my-service-one-image:$CI_COMMIT_REF_SLUG .
  only:
    changes:
      - Dockerfile
      - service-one/**/*
```

In the example above, a pipeline could fail due to changes to a file in `service-one/**/*`.
A later commit could then be pushed that does not include any changes to this file,
but includes changes to the `Dockerfile`, and this pipeline could pass because it is only
testing the changes to the `Dockerfile`. GitLab checks the **most recent pipeline**,
that **passed**, and will show the merge request as mergeable, despite the earlier
failed pipeline caused by a change that was not yet corrected.

With this configuration, care must be taken to check that the most recent pipeline
properly corrected any failures from previous pipelines.

##### Using `only:changes` without pipelines for merge requests

Without [pipelines for merge requests](../merge_request_pipelines/index.md), pipelines
run on branches or tags that don't have an explicit association with a merge request.
In this case, a previous SHA is used to calculate the diff, which equivalent to `git diff HEAD~`.
This could result in some unexpected behavior, including:

- When pushing a new branch or a new tag to GitLab, the policy always evaluates to true.
- When pushing a new commit, the changed files are calculated using the previous commit
  as the base SHA.

### `rules`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/29011) in GitLab 12.3.

`rules` allows for a list of individual rule objects to be evaluated
*in order*, until one matches and dynamically provides attributes to the job.

Available rule clauses include:

- [`if`](#rulesif)
  (similar to [`only:variables`](#onlyvariablesexceptvariables)).
- [`changes`](#ruleschanges)
  (same as [`only:changes`](#onlychangesexceptchanges)).
- [`exists`](#rulesexists)

For example, using `if`. This configuration specifies that `job` should be built
and run for every pipeline on merge requests targeting `master`, regardless of
the status of other builds:

```yaml
job:
  script: "echo Hello, Rules!"
  rules:
    - if: '$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == "master"'
      when: always
    - if: '$VAR =~ /pattern/'
      when: manual
    - when: on_success
```

In this example, if the first rule:

- Matches, the job will be given the `when:always` attribute.
- Does not match, the second and third rules will be evaluated sequentially
  until a match is found. That is, the job will be given either the:
  - `when: manual` attribute if the second rule matches.
  - `when: on_success` attribute if the second rule does not match. The third
    rule will always match when reached because it has no conditional clauses.

#### `rules:if`

`rules:if` differs slightly from `only:variables` by accepting only a single
expression string, rather than an array of them. Any set of expressions to be
evaluated should be conjoined into a single expression using `&&` or `||`. For example:

```yaml
job:
  script: "echo Hello, Rules!"
  rules:
    - if: '$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/ && $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == "master"' # This rule will be evaluated
      when: always
    - if: '$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/' # This rule will only be evaluated if the target branch is not "master"
      when: manual
    - if: '$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME' # If neither of the first two match but the simple presence does, we set to "on_success" by default
```

If none of the provided rules match, the job will be set to `when:never`, and
not included in the pipeline. If `rules:when` is not included in the configuration
at all, the behavior defaults to `job:when`, which continues to default to
`on_success`.

#### `rules:changes`

`rules: changes` works exactly the same way as `only: changes` and `except: changes`,
accepting an array of paths. Similarly, it will always return true if there is no
Git push event. See [`only/except: changes`](#onlychangesexceptchanges) for more information.

For example:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - changes: # Will include the job and set to when:manual if any of the follow paths match a modified file.
      - Dockerfile
      when: manual
    - if: '$VAR == "string value"'
      when: manual # Will include the job and set to when:manual if the expression evaluates to true, after the `changes:` rule fails to match.
    - when: on_success # If neither of the first rules match, set to on_success

```

In this example, a job either set to:

- Run manually if `Dockerfile` has changed OR `$VAR == "string value"`.
- `when:on_success` by the last rule, where no earlier clauses evaluate to true.

#### `rules:exists`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/16574) in GitLab 12.4.

`exists` accepts an array of paths and will match if any of these paths exist
as files in the repository.

For example:

```yaml
job:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - exists:
      - Dockerfile
```

You can also use glob patterns to match multiple files in any directory within
the repository.

For example:

```yaml
job:
  script: bundle exec rspec
  rules:
    - exists:
      - spec/**.rb
```

NOTE: **Note:**
For performance reasons, using `exists` with patterns is limited to 10000
checks. After the 10000th check, rules with patterned globs will always match.

#### Complex rule clauses

To conjoin `if`, `changes`, and `exists` clauses with an AND, use them in the
same rule.

In the following example:

- We run the job manually if `Dockerfile` or any file in `docker/scripts/`
  has changed AND `$VAR == "string value"`.
- Otherwise, the job will not be included in the pipeline.

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: '$VAR == "string value"'
      changes: # Will include the job and set to when:manual if any of the follow paths match a modified file.
      - Dockerfile
      - docker/scripts/*
      when: manual
  # - when: never would be redundant here, this is implied any time rules are listed.
```

The only clauses currently available are:

- `if`
- `changes`
- `exists`

Keywords such as `branches` or `refs` that are currently available for
`only`/`except` are not yet available in `rules` as they are being individually
considered for their usage and behavior in this context.

#### Permitted attributes

The only job attributes currently set by `rules` are:

- `when`.
- `start_in`, if `when` is set to `delayed`.

A job will be included in a pipeline if `when` is evaluated to any value
except `never`.

Delayed jobs require a `start_in` value, so rule objects do as well. For
example:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - changes: # Will include the job and delay 3 hours when the Dockerfile has changed
      - Dockerfile
      when: delayed
      start_in: '3 hours'
    - when: on_success # Otherwise include the job and set to run normally
```

Additional job configuration may be added to rules in the future. If something
useful isn't available, please
[open an issue](https://gitlab.com/gitlab-org/gitlab/issues).

### `workflow:rules`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/29654) in GitLab 12.5

The top-level `workflow:` key applies to the entirety of a pipeline, and will
determine whether or not a pipeline is created. It currently accepts a single
`rules:` key that operates similarly to [`rules:` defined within jobs](#rules),
enabling dynamic configuration of the pipeline.

The configuration options currently available for `workflow:rules` are:​

- [`if`](#rulesif): Define a rule.
- [`when`](#when): May be set to `always` or `never` only. If not provided, the default value is `always`​.

The list of `if` rules is evaluated until a single one is matched. If none
match, the last `when` will be used:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_REF_NAME =~ /-wip$/
      when: never
    - if: $CI_COMMIT_TAG
      when: never
    - when: always
```

### `tags`

`tags` is used to select specific Runners from the list of all Runners that are
allowed to run this project.

During the registration of a Runner, you can specify the Runner's tags, for
example `ruby`, `postgres`, `development`.

`tags` allow you to run jobs with Runners that have the specified tags
assigned to them:

```yaml
job:
  tags:
    - ruby
    - postgres
```

The specification above, will make sure that `job` is built by a Runner that
has both `ruby` AND `postgres` tags defined.

Tags are also a great way to run different jobs on different platforms, for
example, given an OS X Runner with tag `osx` and Windows Runner with tag
`windows`, the following jobs run on respective platforms:

```yaml
windows job:
  stage:
    - build
  tags:
    - windows
  script:
    - echo Hello, %USERNAME%!

osx job:
  stage:
    - build
  tags:
    - osx
  script:
    - echo "Hello, $USER!"
```

### `allow_failure`

`allow_failure` allows a job to fail without impacting the rest of the CI
suite.
The default value is `false`, except for [manual](#whenmanual) jobs.

When enabled and the job fails, the job will show an orange warning in the UI.
However, the logical flow of the pipeline will consider the job a
success/passed, and is not blocked.

Assuming all other jobs are successful, the job's stage and its pipeline will
show the same orange warning. However, the associated commit will be marked
"passed", without warnings.

In the example below, `job1` and `job2` will run in parallel, but if `job1`
fails, it will not stop the next stage from running, since it's marked with
`allow_failure: true`:

```yaml
job1:
  stage: test
  script:
    - execute_script_that_will_fail
  allow_failure: true

job2:
  stage: test
  script:
    - execute_script_that_will_succeed

job3:
  stage: deploy
  script:
    - deploy_to_staging
```

### `when`

`when` is used to implement jobs that are run in case of failure or despite the
failure.

`when` can be set to one of the following values:

1. `on_success` - execute job only when all jobs from prior stages
    succeed (or are considered succeeding because they are marked
    `allow_failure`). This is the default.
1. `on_failure` - execute job only when at least one job from prior stages
    fails.
1. `always` - execute job regardless of the status of jobs from prior stages.
1. `manual` - execute job manually (added in GitLab 8.10). Read about
    [manual actions](#whenmanual) below.
1. `delayed` - execute job after a certain period (added in GitLab 11.14).
    Read about [delayed actions](#whendelayed) below.

For example:

```yaml
stages:
  - build
  - cleanup_build
  - test
  - deploy
  - cleanup

build_job:
  stage: build
  script:
    - make build

cleanup_build_job:
  stage: cleanup_build
  script:
    - cleanup build when failed
  when: on_failure

test_job:
  stage: test
  script:
    - make test

deploy_job:
  stage: deploy
  script:
    - make deploy
  when: manual

cleanup_job:
  stage: cleanup
  script:
    - cleanup after jobs
  when: always
```

The above script will:

1. Execute `cleanup_build_job` only when `build_job` fails.
1. Always execute `cleanup_job` as the last step in pipeline regardless of
   success or failure.
1. Allow you to manually execute `deploy_job` from GitLab's UI.

#### `when:manual`

> - Introduced in GitLab 8.10.
> - Blocking manual actions were introduced in GitLab 9.0.
> - Protected actions were introduced in GitLab 9.2.

Manual actions are a special type of job that are not executed automatically,
they need to be explicitly started by a user. An example usage of manual actions
would be a deployment to a production environment. Manual actions can be started
from the pipeline, job, environment, and deployment views. Read more at the
[environments documentation](../environments.md#configuring-manual-deployments).

Manual actions can be either optional or blocking. Blocking manual actions will
block the execution of the pipeline at the stage this action is defined in. It's
possible to resume execution of the pipeline when someone executes a blocking
manual action by clicking a _play_ button.

When a pipeline is blocked, it will not be merged if Merge When Pipeline Succeeds
is set. Blocked pipelines also do have a special status, called _manual_.
Manual actions are non-blocking by default. If you want to make manual action
blocking, it is necessary to add `allow_failure: false` to the job's definition
in `.gitlab-ci.yml`.

Optional manual actions have `allow_failure: true` set by default and their
Statuses do not contribute to the overall pipeline status. So, if a manual
action fails, the pipeline will eventually succeed.

Manual actions are considered to be write actions, so permissions for
[protected branches](../../user/project/protected_branches.md) are used when
a user wants to trigger an action. In other words, in order to trigger a manual
action assigned to a branch that the pipeline is running for, the user needs to
have the ability to merge to this branch. It is possible to use protected environments
to more strictly [protect manual deployments](#protecting-manual-jobs-premium) from being
run by unauthorized users.

NOTE: **Note:**
Using `when:manual` and `trigger` together results in the error `jobs:#{job-name} when
should be on_success, on_failure or always`, because `when:manual` prevents triggers
being used.

##### Protecting manual jobs **(PREMIUM)**

It's possible to use [protected environments](../environments/protected_environments.md)
to define a precise list of users authorized to run a manual job. By allowing only
users associated with a protected environment to trigger manual jobs, it is possible
to implement some special use cases, such as:

- More precisely limiting who can deploy to an environment.
- Enabling a pipeline to be blocked until an approved user "approves" it.

To do this, you must:

1. Add an `environment` to the job. For example:

   ```yaml
   deploy_prod:
     stage: deploy
     script:
       - echo "Deploy to production server"
     environment:
       name: production
       url: https://example.com
     when: manual
     only:
       - master
   ```

1. In the [protected environments settings](../environments/protected_environments.md#protecting-environments),
   select the environment (`production` in the example above) and add the users, roles or groups
   that are authorized to trigger the manual job to the **Allowed to Deploy** list. Only those in
   this list will be able to trigger this manual job, as well as GitLab administrators
   who are always able to use protected environments.

Additionally, if a manual job is defined as blocking by adding `allow_failure: false`,
the next stages of the pipeline will not run until the manual job is triggered. This
can be used as a way to have a defined list of users allowed to "approve" later pipeline
stages by triggering the blocking manual job.

#### `when:delayed`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/21767) in GitLab 11.4.

Delayed job are for executing scripts after a certain period.
This is useful if you want to avoid jobs entering `pending` state immediately.

You can set the period with `start_in` key. The value of `start_in` key is an elapsed time in seconds, unless a unit is
provided. `start_in` key must be less than or equal to one week. Examples of valid values include:

- `'5'`
- `10 seconds`
- `30 minutes`
- `1 day`
- `1 week`

When there is a delayed job in a stage, the pipeline will not progress until the delayed job has finished.
This means this keyword can also be used for inserting delays between different stages.

The timer of a delayed job starts immediately after the previous stage has completed.
Similar to other types of jobs, a delayed job's timer will not start unless the previous stage passed.

The following example creates a job named `timed rollout 10%` that is executed 30 minutes after the previous stage has completed:

```yaml
timed rollout 10%:
  stage: deploy
  script: echo 'Rolling out 10% ...'
  when: delayed
  start_in: 30 minutes
```

You can stop the active timer of a delayed job by clicking the **Unschedule** button.
This job will never be executed in the future unless you execute the job manually.

You can start a delayed job immediately by clicking the **Play** button.
GitLab Runner will pick your job soon and start the job.

### `environment`

> - Introduced in GitLab 8.9.
> - You can read more about environments and find more examples in the
>   [documentation about environments][environment].

`environment` is used to define that a job deploys to a specific environment.
If `environment` is specified and no environment under that name exists, a new
one will be created automatically.

In its simplest form, the `environment` keyword can be defined like:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:master
  environment:
    name: production
```

In the above example, the `deploy to production` job will be marked as doing a
deployment to the `production` environment.

#### `environment:name`

> - Introduced in GitLab 8.11.
> - Before GitLab 8.11, the name of an environment could be defined as a string like
>   `environment: production`. The recommended way now is to define it under the
>   `name` keyword.
> - The `name` parameter can use any of the defined CI variables,
>   including predefined, secure variables and `.gitlab-ci.yml` [`variables`](#variables).
>   You however cannot use variables defined under `script`.

The `environment` name can contain:

- letters
- digits
- spaces
- `-`
- `_`
- `/`
- `$`
- `{`
- `}`

Common names are `qa`, `staging`, and `production`, but you can use whatever
name works with your workflow.

Instead of defining the name of the environment right after the `environment`
keyword, it is also possible to define it as a separate value. For that, use
the `name` keyword under `environment`:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:master
  environment:
    name: production
```

#### `environment:url`

> - Introduced in GitLab 8.11.
> - Before GitLab 8.11, the URL could be added only in GitLab's UI. The
>   recommended way now is to define it in `.gitlab-ci.yml`.
> - The `url` parameter can use any of the defined CI variables,
>   including predefined, secure variables and `.gitlab-ci.yml` [`variables`](#variables).
>   You however cannot use variables defined under `script`.

This is an optional value that when set, it exposes buttons in various places
in GitLab which when clicked take you to the defined URL.

In the example below, if the job finishes successfully, it will create buttons
in the merge requests and in the environments/deployments pages which will point
to `https://prod.example.com`.

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:master
  environment:
    name: production
    url: https://prod.example.com
```

#### `environment:on_stop`

> - [Introduced][ce-6669] in GitLab 8.13.
> - Starting with GitLab 8.14, when you have an environment that has a stop action
>   defined, GitLab will automatically trigger a stop action when the associated
>   branch is deleted.

Closing (stopping) environments can be achieved with the `on_stop` keyword defined under
`environment`. It declares a different job that runs in order to close
the environment.

Read the `environment:action` section for an example.

#### `environment:action`

> [Introduced][ce-6669] in GitLab 8.13.

The `action` keyword is to be used in conjunction with `on_stop` and is defined
in the job that is called to close the environment.

Take for instance:

```yaml
review_app:
  stage: deploy
  script: make deploy-app
  environment:
    name: review
    on_stop: stop_review_app

stop_review_app:
  stage: deploy
  variables:
    GIT_STRATEGY: none
  script: make delete-app
  when: manual
  environment:
    name: review
    action: stop
```

In the above example we set up the `review_app` job to deploy to the `review`
environment, and we also defined a new `stop_review_app` job under `on_stop`.
Once the `review_app` job is successfully finished, it will trigger the
`stop_review_app` job based on what is defined under `when`. In this case we
set it up to `manual` so it will need a [manual action](#whenmanual) via
GitLab's web interface in order to run.

Also in the example, `GIT_STRATEGY` is set to `none` so that GitLab Runner won’t
try to check out the code after the branch is deleted when the `stop_review_app`
job is [automatically triggered](../environments.md#automatically-stopping-an-environment).

NOTE: **Note:**
The above example overwrites global variables. If your stop environment job depends
on global variables, you can use [anchor variables](#yaml-anchors-for-variables) when setting the `GIT_STRATEGY`
to change it without overriding the global variables.

The `stop_review_app` job is **required** to have the following keywords defined:

- `when` - [reference](#when)
- `environment:name`
- `environment:action`
- `stage` should be the same as the `review_app` in order for the environment
  to stop automatically when the branch is deleted

#### `environment:kubernetes`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/27630) in GitLab 12.6.

The `kubernetes` block is used to configure deployments to a
[Kubernetes cluster](../../user/project/clusters/index.md) that is associated with your project.

For example:

```yaml
deploy:
  stage: deploy
  script: make deploy-app
  environment:
    name: production
    kubernetes:
      namespace: production
```

This will set up the `deploy` job to deploy to the `production`
environment, using the `production`
[Kubernetes namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/).

For more information, see
[Available settings for `kubernetes`](../environments.md#configuring-kubernetes-deployments).

NOTE: **Note:**
Kubernetes configuration is not supported for Kubernetes clusters
that are [managed by GitLab](../../user/project/clusters/index.md#gitlab-managed-clusters).
To follow progress on support for GitLab-managed clusters, see the
[relevant issue](https://gitlab.com/gitlab-org/gitlab/issues/38054).

#### Dynamic environments

> - [Introduced][ce-6323] in GitLab 8.12 and GitLab Runner 1.6.
> - The `$CI_ENVIRONMENT_SLUG` was [introduced][ce-7983] in GitLab 8.15.
> - The `name` and `url` parameters can use any of the defined CI variables,
>   including predefined, secure variables and `.gitlab-ci.yml` [`variables`](#variables).
>   You however cannot use variables defined under `script`.

For example:

```yaml
deploy as review app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: https://$CI_ENVIRONMENT_SLUG.example.com/
```

The `deploy as review app` job will be marked as deployment to dynamically
create the `review/$CI_COMMIT_REF_NAME` environment, where `$CI_COMMIT_REF_NAME`
is an [environment variable][variables] set by the Runner. The
`$CI_ENVIRONMENT_SLUG` variable is based on the environment name, but suitable
for inclusion in URLs. In this case, if the `deploy as review app` job was run
in a branch named `pow`, this environment would be accessible with an URL like
`https://review-pow.example.com/`.

This of course implies that the underlying server which hosts the application
is properly configured.

The common use case is to create dynamic environments for branches and use them
as Review Apps. You can see a simple example using Review Apps at
<https://gitlab.com/gitlab-examples/review-apps-nginx/>.

### `cache`

> - Introduced in GitLab Runner v0.7.0.
> - `cache` can be set globally and per-job.
> - From GitLab 9.0, caching is enabled and shared between pipelines and jobs
>   by default.
> - From GitLab 9.2, caches are restored before [artifacts](#artifacts).

TIP: **Learn more:**
Read how caching works and find out some good practices in the
[caching dependencies documentation](../caching/index.md).

`cache` is used to specify a list of files and directories which should be
cached between jobs. You can only use paths that are within the local working
copy.

If `cache` is defined outside the scope of jobs, it means it is set
globally and all jobs will use that definition.

#### `cache:paths`

Use the `paths` directive to choose which files or directories will be cached. Paths
are relative to the project directory (`$CI_PROJECT_DIR`) and cannot directly link outside it.
Wildcards can be used that follow the [glob](https://en.wikipedia.org/wiki/Glob_(programming))
patterns and [filepath.Match](https://golang.org/pkg/path/filepath/#Match).

Cache all files in `binaries` that end in `.apk` and the `.config` file:

```yaml
rspec:
  script: test
  cache:
    paths:
      - binaries/*.apk
      - .config
```

Locally defined cache overrides globally defined options. The following `rspec`
job will cache only `binaries/`:

```yaml
cache:
  paths:
    - my/files

rspec:
  script: test
  cache:
    key: rspec
    paths:
      - binaries/
```

Note that since cache is shared between jobs, if you're using different
paths for different jobs, you should also set a different **cache:key**
otherwise cache content can be overwritten.

#### `cache:key`

> Introduced in GitLab Runner v1.0.0.

Since the cache is shared between jobs, if you're using different
paths for different jobs, you should also set a different `cache:key`
otherwise cache content can be overwritten.

The `key` directive allows you to define the affinity of caching between jobs,
allowing to have a single cache for all jobs, cache per-job, cache per-branch
or any other way that fits your workflow. This way, you can fine tune caching,
allowing you to cache data between different jobs or even different branches.

The `cache:key` variable can use any of the
[predefined variables](../variables/README.md), and the default key, if not
set, is just literal `default` which means everything is shared between each
pipelines and jobs by default, starting from GitLab 9.0.

NOTE: **Note:**
The `cache:key` variable cannot contain the `/` character, or the equivalent
URI-encoded `%2F`; a value made only of dots (`.`, `%2E`) is also forbidden.

For example, to enable per-branch caching:

```yaml
cache:
  key: "$CI_COMMIT_REF_SLUG"
  paths:
    - binaries/
```

If you use **Windows Batch** to run your shell scripts you need to replace
`$` with `%`:

```yaml
cache:
  key: "%CI_COMMIT_REF_SLUG%"
  paths:
    - binaries/
```

##### `cache:key:files`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/18986) in GitLab v12.5.

The `cache:key:files` keyword extends the `cache:key` functionality by making it easier
to reuse some caches, and rebuild them less often, which will speed up subsequent pipeline
runs.

When you include `cache:key:files`, you must also list the project files that will be used to generate the key, up to a maximum of two files.
The cache `key` will be a SHA checksum computed from the most recent commits (up to two, if two files are listed)
that changed the given files. If neither file was changed in any commits,
the fallback key will be `default`.

```yaml
cache:
  key:
    files:
      - Gemfile.lock
      - package.json
  paths:
    - vendor/ruby
    - node_modules
```

In this example we are creating a cache for Ruby and Nodejs dependencies that
is tied to current versions of the `Gemfile.lock` and `package.json` files. Whenever one of
these files changes, a new cache key is computed and a new cache is created. Any future
job runs using the same `Gemfile.lock` and `package.json`  with `cache:key:files` will
use the new cache, instead of rebuilding the dependencies.

##### `cache:key:prefix`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/18986) in GitLab v12.5.
The `prefix` parameter adds extra functionality to `key:files` by allowing the key to
be composed of the given `prefix` combined with the SHA computed for `cache:key:files`.
For example, adding a `prefix` of `test`, will cause keys to look like: `test-feef9576d21ee9b6a32e30c5c79d0a0ceb68d1e5`.
If neither file was changed in any commits, the prefix is added to `default`, so the
key in the example would be `test-default`.

Like `cache:key`, `prefix` can use any of the [predefined variables](../variables/README.md),
but the following are not allowed:

- the `/` character (or the equivalent URI-encoded `%2F`)
- a value made only of `.` (or the equivalent URI-encoded `%2E`)

```yaml
cache:
  key:
    files:
      - Gemfile.lock
    prefix: ${CI_JOB_NAME}
  paths:
    - vendor/ruby

rspec:
  script:
    - bundle exec rspec
```

For example, adding a `prefix` of `$CI_JOB_NAME` will
cause the key to look like: `rspec-feef9576d21ee9b6a32e30c5c79d0a0ceb68d1e5` and
the job cache is shared across different branches. If a branch changes
`Gemfile.lock`, that branch will have a new SHA checksum for `cache:key:files`. A new cache key
will be generated, and a new cache will be created for that key.
If `Gemfile.lock` is not found, the prefix is added to
`default`, so the key in the example would be `rspec-default`.

#### `cache:untracked`

Set `untracked: true` to cache all files that are untracked in your Git
repository:

```yaml
rspec:
  script: test
  cache:
    untracked: true
```

Cache all Git untracked files and files in `binaries`:

```yaml
rspec:
  script: test
  cache:
    untracked: true
    paths:
      - binaries/
```

#### `cache:policy`

> Introduced in GitLab 9.4.

The default behaviour of a caching job is to download the files at the start of
execution, and to re-upload them at the end. This allows any changes made by the
job to be persisted for future runs, and is known as the `pull-push` cache
policy.

If you know the job doesn't alter the cached files, you can skip the upload step
by setting `policy: pull` in the job specification. Typically, this would be
twinned with an ordinary cache job at an earlier stage to ensure the cache
is updated from time to time:

```yaml
stages:
  - setup
  - test

prepare:
  stage: setup
  cache:
    key: gems
    paths:
      - vendor/bundle
  script:
    - bundle install --deployment

rspec:
  stage: test
  cache:
    key: gems
    paths:
      - vendor/bundle
    policy: pull
  script:
    - bundle exec rspec ...
```

This helps to speed up job execution and reduce load on the cache server,
especially when you have a large number of cache-using jobs executing in
parallel.

Additionally, if you have a job that unconditionally recreates the cache without
reference to its previous contents, you can use `policy: push` in that job to
skip the download step.

### `artifacts`

> - Introduced in GitLab Runner v0.7.0 for non-Windows platforms.
> - Windows support was added in GitLab Runner v.1.0.0.
> - From GitLab 9.2, caches are restored before artifacts.
> - Not all executors are [supported](https://docs.gitlab.com/runner/executors/#compatibility-chart).
> - Job artifacts are only collected for successful jobs by default.

`artifacts` is used to specify a list of files and directories which should be
attached to the job when it [succeeds, fails, or always](#artifactswhen).

The artifacts will be sent to GitLab after the job finishes and will
be available for download in the GitLab UI.

[Read more about artifacts](../../user/project/pipelines/job_artifacts.md).

#### `artifacts:paths`

Paths are relative to the project directory (`$CI_PROJECT_DIR`) and cannot directly
link outside it. Wildcards can be used that follow the [glob](https://en.wikipedia.org/wiki/Glob_(programming))
patterns and [filepath.Match](https://golang.org/pkg/path/filepath/#Match).

To restrict which jobs a specific job will fetch artifacts from, see [dependencies](#dependencies).

Send all files in `binaries` and `.config`:

```yaml
artifacts:
  paths:
    - binaries/
    - .config
```

To disable artifact passing, define the job with empty [dependencies](#dependencies):

```yaml
job:
  stage: build
  script: make build
  dependencies: []
```

You may want to create artifacts only for tagged releases to avoid filling the
build server storage with temporary build artifacts.

Create artifacts only for tags (`default-job` will not create artifacts):

```yaml
default-job:
  script:
    - mvn test -U
  except:
    - tags

release-job:
  script:
    - mvn package -U
  artifacts:
    paths:
      - target/*.war
  only:
    - tags
```

#### `artifacts:expose_as`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/15018) in GitLab 12.5.

The `expose_as` keyword can be used to expose [job artifacts](../../user/project/pipelines/job_artifacts.md)
in the [merge request](../../user/project/merge_requests/index.md) UI.

For example, to match a single file:

```yml
test:
  script: [ 'echo 1' ]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['path/to/file.txt']
```

With this configuration, GitLab will add a link **artifact 1** to the relevant merge request
that points to `file1.txt`.

An example that will match an entire directory:

```yml
test:
  script: [ 'echo 1' ]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['path/to/directory/']
```

Note the following:

- A maximum of 10 job artifacts per merge request can be exposed.
- Glob patterns are unsupported.
- If a directory is specified, the link will be to the job [artifacts browser](../../user/project/pipelines/job_artifacts.md#browsing-artifacts) if there is more than
  one file in the directory.
- For exposed single file artifacts with `.html`, `.htm`, `.txt`, `.json`, `.xml`,
  and `.log` extensions, if [GitLab Pages](../../administration/pages/index.md) is:
  - Enabled, GitLab will automatically render the artifact.
  - Not enabled, you will see the file in the artifacts browser.

#### `artifacts:name`

> Introduced in GitLab 8.6 and GitLab Runner v1.1.0.

The `name` directive allows you to define the name of the created artifacts
archive. That way, you can have a unique name for every archive which could be
useful when you'd like to download the archive from GitLab. The `artifacts:name`
variable can make use of any of the [predefined variables](../variables/README.md).
The default name is `artifacts`, which becomes `artifacts.zip` when downloaded.

NOTE: **Note:**
If your branch-name contains forward slashes
(e.g. `feature/my-feature`) it is advised to use `$CI_COMMIT_REF_SLUG`
instead of `$CI_COMMIT_REF_NAME` for proper naming of the artifact.

To create an archive with a name of the current job:

```yaml
job:
  artifacts:
    name: "$CI_JOB_NAME"
    paths:
      - binaries/
```

To create an archive with a name of the current branch or tag including only
the binaries directory:

```yaml
job:
  artifacts:
    name: "$CI_COMMIT_REF_NAME"
    paths:
      - binaries/
```

To create an archive with a name of the current job and the current branch or
tag including only the binaries directory:

```yaml
job:
  artifacts:
    name: "$CI_JOB_NAME-$CI_COMMIT_REF_NAME"
    paths:
      - binaries/
```

To create an archive with a name of the current [stage](#stages) and branch name:

```yaml
job:
  artifacts:
    name: "$CI_JOB_STAGE-$CI_COMMIT_REF_NAME"
    paths:
      - binaries/
```

---

If you use **Windows Batch** to run your shell scripts you need to replace
`$` with `%`:

```yaml
job:
  artifacts:
    name: "%CI_JOB_STAGE%-%CI_COMMIT_REF_NAME%"
    paths:
      - binaries/
```

If you use **Windows PowerShell** to run your shell scripts you need to replace
`$` with `$env:`:

```yaml
job:
  artifacts:
    name: "$env:CI_JOB_STAGE-$env:CI_COMMIT_REF_NAME"
    paths:
      - binaries/
```

#### `artifacts:untracked`

`artifacts:untracked` is used to add all Git untracked files as artifacts (along
to the paths defined in `artifacts:paths`).

NOTE: **Note:**
`artifacts:untracked` ignores configuration in the repository's `.gitignore` file.

Send all Git untracked files:

```yaml
artifacts:
  untracked: true
```

Send all Git untracked files and files in `binaries`:

```yaml
artifacts:
  untracked: true
  paths:
    - binaries/
```

#### `artifacts:when`

> Introduced in GitLab 8.9 and GitLab Runner v1.3.0.

`artifacts:when` is used to upload artifacts on job failure or despite the
failure.

`artifacts:when` can be set to one of the following values:

1. `on_success` - upload artifacts only when the job succeeds. This is the default.
1. `on_failure` - upload artifacts only when the job fails.
1. `always` - upload artifacts regardless of the job status.

To upload artifacts only when job fails:

```yaml
job:
  artifacts:
    when: on_failure
```

#### `artifacts:expire_in`

> Introduced in GitLab 8.9 and GitLab Runner v1.3.0.

`expire_in` allows you to specify how long artifacts should live before they
expire and therefore deleted, counting from the time they are uploaded and
stored on GitLab. If the expiry time is not defined, it defaults to the
[instance wide setting](../../user/admin_area/settings/continuous_integration.md#default-artifacts-expiration-core-only)
(30 days by default, forever on GitLab.com).

You can use the **Keep** button on the job page to override expiration and
keep artifacts forever.

After their expiry, artifacts are deleted hourly by default (via a cron job),
and are not accessible anymore.

The value of `expire_in` is an elapsed time in seconds, unless a unit is
provided. Examples of parsable values:

- '42'
- '3 mins 4 sec'
- '2 hrs 20 min'
- '2h20min'
- '6 mos 1 day'
- '47 yrs 6 mos and 4d'
- '3 weeks and 2 days'

To expire artifacts 1 week after being uploaded:

```yaml
job:
  artifacts:
    expire_in: 1 week
```

#### `artifacts:reports`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/20390) in
GitLab 11.2. Requires GitLab Runner 11.2 and above.

The `reports` keyword is used for collecting test reports from jobs and
exposing them in GitLab's UI (merge requests, pipeline views). Read how to use
this with [JUnit reports](#artifactsreportsjunit).

NOTE: **Note:**
The test reports are collected regardless of the job results (success or failure).
You can use [`artifacts:expire_in`](#artifactsexpire_in) to set up an expiration
date for their artifacts.

NOTE: **Note:**
If you also want the ability to browse the report output files, include the
[`artifacts:paths`](#artifactspaths) keyword.

##### `artifacts:reports:junit`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/20390) in
GitLab 11.2. Requires GitLab Runner 11.2 and above.

The `junit` report collects [JUnit XML files](https://www.ibm.com/support/knowledgecenter/en/SSQ2R2_14.1.0/com.ibm.rsar.analysis.codereview.cobol.doc/topics/cac_useresults_junit.html)
as artifacts. Although JUnit was originally developed in Java, there are many
[third party ports](https://en.wikipedia.org/wiki/JUnit#Ports) for other
languages like JavaScript, Python, Ruby, etc.

See [JUnit test reports](../junit_test_reports.md) for more details and examples.
Below is an example of collecting a JUnit XML file from Ruby's RSpec test tool:

```yaml
rspec:
  stage: test
  script:
  - bundle install
  - rspec --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
```

The collected JUnit reports will be uploaded to GitLab as an artifact and will
be automatically shown in merge requests.

NOTE: **Note:**
In case the JUnit tool you use exports to multiple XML files, you can specify
multiple test report paths within a single job and they will be automatically
concatenated into a single file. Use a filename pattern (`junit: rspec-*.xml`),
an array of filenames (`junit: [rspec-1.xml, rspec-2.xml, rspec-3.xml]`), or a
combination thereof (`junit: [rspec.xml, test-results/TEST-*.xml]`).

##### `artifacts:reports:codequality` **(STARTER)**

> Introduced in GitLab 11.5. Requires GitLab Runner 11.5 and above.

The `codequality` report collects [CodeQuality issues](../../user/project/merge_requests/code_quality.md)
as artifacts.

The collected Code Quality report will be uploaded to GitLab as an artifact and will
be automatically shown in merge requests.

##### `artifacts:reports:sast` **(ULTIMATE)**

> Introduced in GitLab 11.5. Requires GitLab Runner 11.5 and above.

The `sast` report collects [SAST vulnerabilities](../../user/application_security/sast/index.md)
as artifacts.

The collected SAST report will be uploaded to GitLab as an artifact and will
be automatically shown in merge requests, pipeline view and provide data for security
dashboards.

##### `artifacts:reports:dependency_scanning` **(ULTIMATE)**

> Introduced in GitLab 11.5. Requires GitLab Runner 11.5 and above.

The `dependency_scanning` report collects [Dependency Scanning vulnerabilities](../../user/application_security/dependency_scanning/index.md)
as artifacts.

The collected Dependency Scanning report will be uploaded to GitLab as an artifact and will
be automatically shown in merge requests, pipeline view and provide data for security
dashboards.

##### `artifacts:reports:container_scanning` **(ULTIMATE)**

> Introduced in GitLab 11.5. Requires GitLab Runner 11.5 and above.

The `container_scanning` report collects [Container Scanning vulnerabilities](../../user/application_security/container_scanning/index.md)
as artifacts.

The collected Container Scanning report will be uploaded to GitLab as an artifact and will
be automatically shown in merge requests, pipeline view and provide data for security
dashboards.

##### `artifacts:reports:dast` **(ULTIMATE)**

> Introduced in GitLab 11.5. Requires GitLab Runner 11.5 and above.

The `dast` report collects [DAST vulnerabilities](../../user/application_security/dast/index.md)
as artifacts.

The collected DAST report will be uploaded to GitLab as an artifact and will
be automatically shown in merge requests, pipeline view and provide data for security
dashboards.

##### `artifacts:reports:license_management` **(ULTIMATE)**

> Introduced in GitLab 11.5. Requires GitLab Runner 11.5 and above.

The `license_management` report collects [Licenses](../../user/application_security/license_compliance/index.md)
as artifacts.

The collected License Compliance report will be uploaded to GitLab as an artifact and will
be automatically shown in merge requests, pipeline view and provide data for security
dashboards.

##### `artifacts:reports:performance` **(PREMIUM)**

> Introduced in GitLab 11.5. Requires GitLab Runner 11.5 and above.

The `performance` report collects [Performance metrics](../../user/project/merge_requests/browser_performance_testing.md)
as artifacts.

The collected Performance report will be uploaded to GitLab as an artifact and will
be automatically shown in merge requests.

##### `artifacts:reports:metrics` **(PREMIUM)**

> Introduced in GitLab 11.10.

The `metrics` report collects [Metrics](../../ci/metrics_reports.md)
as artifacts.

The collected Metrics report will be uploaded to GitLab as an artifact and will
be automatically shown in merge requests.

### `dependencies`

> Introduced in GitLab 8.6 and GitLab Runner v1.1.1.

By default, all [`artifacts`](#artifacts) from all previous [stages](#stages)
are passed, but you can use the `dependencies` parameter to define a limited
list of jobs (or no jobs) to fetch artifacts from.

To use this feature, define `dependencies` in context of the job and pass
a list of all previous jobs from which the artifacts should be downloaded.
You can only define jobs from stages that are executed before the current one.
An error will be shown if you define jobs from the current stage or next ones.
Defining an empty array will skip downloading any artifacts for that job.
The status of the previous job is not considered when using `dependencies`, so
if it failed or it is a manual job that was not run, no error occurs.

In the following example, we define two jobs with artifacts, `build:osx` and
`build:linux`. When the `test:osx` is executed, the artifacts from `build:osx`
will be downloaded and extracted in the context of the build. The same happens
for `test:linux` and artifacts from `build:linux`.

The job `deploy` will download artifacts from all previous jobs because of
the [stage](#stages) precedence:

```yaml
build:osx:
  stage: build
  script: make build:osx
  artifacts:
    paths:
      - binaries/

build:linux:
  stage: build
  script: make build:linux
  artifacts:
    paths:
      - binaries/

test:osx:
  stage: test
  script: make test:osx
  dependencies:
    - build:osx

test:linux:
  stage: test
  script: make test:linux
  dependencies:
    - build:linux

deploy:
  stage: deploy
  script: make deploy
```

#### When a dependent job will fail

> Introduced in GitLab 10.3.

If the artifacts of the job that is set as a dependency have been
[expired](#artifactsexpire_in) or
[erased](../../user/project/pipelines/job_artifacts.md#erasing-artifacts), then
the dependent job will fail.

NOTE: **Note:**
You can ask your administrator to
[flip this switch](../../administration/job_artifacts.md#validation-for-dependencies)
and bring back the old behavior.

### `needs`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/47063) in GitLab 12.2.
> - In GitLab 12.3, maximum number of jobs in `needs` array raised from five to 50.

The `needs:` keyword enables executing jobs out-of-order, allowing you to implement
a [directed acyclic graph](../directed_acyclic_graph/index.md) in your `.gitlab-ci.yml`.

This lets you run some jobs without waiting for other ones, disregarding stage ordering
so you can have multiple stages running concurrently.

Let's consider the following example:

```yaml
linux:build:
  stage: build

mac:build:
  stage: build

linux:rspec:
  stage: test
  needs: ["linux:build"]

linux:rubocop:
  stage: test
  needs: ["linux:build"]

mac:rspec:
  stage: test
  needs: ["mac:build"]

mac:rubocop:
  stage: test
  needs: ["mac:build"]

production:
  stage: deploy
```

This example creates three paths of execution:

- Linux path: the `linux:rspec` and `linux:rubocop` jobs will be run as soon
  as the `linux:build` job finishes without waiting for `mac:build` to finish.

- macOS path: the `mac:rspec` and `mac:rubocop` jobs will be run as soon
  as the `mac:build` job finishes, without waiting for `linux:build` to finish.

- The `production` job will be executed as soon as all previous jobs
  finish; in this case: `linux:build`, `linux:rspec`, `linux:rubocop`,
  `mac:build`, `mac:rspec`, `mac:rubocop`.

#### Requirements and limitations

- If `needs:` is set to point to a job that is not instantiated
  because of `only/except` rules or otherwise does not exist, the
  pipeline will be created with YAML error.
- We are temporarily limiting the maximum number of jobs that a single job can
  need in the `needs:` array:
  - For GitLab.com, the limit is ten. For more information, see our
    [infrastructure issue](https://gitlab.com/gitlab-com/gl-infra/infrastructure/issues/7541).
  - For self-managed instances, the limit is:
    - 10, if the `ci_dag_limit_needs` feature flag is enabled (default).
    - 50, if the `ci_dag_limit_needs` feature flag is disabled.
- It is impossible for now to have `needs: []` (empty needs), the job always needs to
  depend on something, unless this is the job in the first stage. However, support for
  an empty needs array [is planned](https://gitlab.com/gitlab-org/gitlab/issues/30631).
- If `needs:` refers to a job that is marked as `parallel:`.
  the current job will depend on all parallel jobs created.
- `needs:` is similar to `dependencies:` in that it needs to use jobs from prior stages,
  meaning it is impossible to create circular dependencies. Depending on jobs in the
  current stage is not possible either, but support [is planned](https://gitlab.com/gitlab-org/gitlab/issues/30632).
- Related to the above, stages must be explicitly defined for all jobs
  that have the keyword `needs:` or are referred to by one.

##### Changing the `needs:` job limit

The maximum number of jobs that can be defined within `needs:` defaults to 10, but
can be changed to 50 via a feature flag. To change the limit to 50,
[start a Rails console session](https://docs.gitlab.com/omnibus/maintenance/#starting-a-rails-console-session)
and run:

```ruby
Feature::disable(:ci_dag_limit_needs)
```

To set it back to 10, run the opposite command:

```ruby
Feature::enable(:ci_dag_limit_needs)
```

#### Artifact downloads with `needs`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/14311) in GitLab v12.6.

When using `needs`, artifact downloads are controlled with `artifacts: true` or `artifacts: false`.
The `dependencies` keyword should not be used with `needs`, as this is deprecated since GitLab 12.6.

In the example below, the `rspec` job will download the `build_job` artifacts, while the
`rubocop` job will not:

```yaml
build_job:
  stage: build
  artifacts:
    paths:
      - binaries/

rspec:
  stage: test
  needs:
    - job: build_job
      artifacts: true

rubocop:
  stage: test
  needs:
    - job: build_job
      artifacts: false
```

Additionally, in the three syntax examples below, the `rspec` job will download the artifacts
from all three `build_jobs`, as `artifacts` is true for `build_job_1`, and will
**default** to true for both `build_job_2` and `build_job_3`.

```yaml
rspec:
  needs:
    - job: build_job_1
      artifacts: true
    - job: build_job_2
    - build_job_3
```

### `coverage`

> [Introduced][ce-7447] in GitLab 8.17.

`coverage` allows you to configure how code coverage will be extracted from the
job output.

Regular expressions are the only valid kind of value expected here. So, using
surrounding `/` is mandatory in order to consistently and explicitly represent
a regular expression string. You must escape special characters if you want to
match them literally.

A simple example:

```yaml
job1:
  script: rspec
  coverage: '/Code coverage: \d+\.\d+/'
```

### `retry`

> - [Introduced][ce-12909] in GitLab 9.5.
> - [Behaviour expanded](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/21758) in GitLab 11.5 to control on which failures to retry.

`retry` allows you to configure how many times a job is going to be retried in
case of a failure.

When a job fails and has `retry` configured, it is going to be processed again
up to the amount of times specified by the `retry` keyword.

If `retry` is set to 2, and a job succeeds in a second run (first retry), it won't be retried
again. `retry` value has to be a positive integer, equal or larger than 0, but
lower or equal to 2 (two retries maximum, three runs in total).

A simple example to retry in all failure cases:

```yaml
test:
  script: rspec
  retry: 2
```

By default, a job will be retried on all failure cases. To have a better control
on which failures to retry, `retry` can be a hash with the following keys:

- `max`: The maximum number of retries.
- `when`: The failure cases to retry.

To retry only runner system failures at maximum two times:

```yaml
test:
  script: rspec
  retry:
    max: 2
    when: runner_system_failure
```

If there is another failure, other than a runner system failure, the job will
not be retried.

To retry on multiple failure cases, `when` can also be an array of failures:

```yaml
test:
  script: rspec
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
```

Possible values for `when` are:

<!--
  Please make sure to update `RETRY_WHEN_IN_DOCUMENTATION` array in
  `spec/lib/gitlab/ci/config/entry/retry_spec.rb` if you change any of
  the documented values below. The test there makes sure that all documented
  values are really valid as a config option and therefore should always
  stay in sync with this documentation.
 -->

- `always`: Retry on any failure (default).
- `unknown_failure`: Retry when the failure reason is unknown.
- `script_failure`: Retry when the script failed.
- `api_failure`: Retry on API failure.
- `stuck_or_timeout_failure`: Retry when the job got stuck or timed out.
- `runner_system_failure`: Retry if there was a runner system failure (e.g. setting up the job failed).
- `missing_dependency_failure`: Retry if a dependency was missing.
- `runner_unsupported`: Retry if the runner was unsupported.

### `timeout`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/14887) in GitLab 12.3.

`timeout` allows you to configure a timeout for a specific job. For example:

```yaml
build:
  script: build.sh
  timeout: 3 hours 30 minutes

test:
  script: rspec
  timeout: 3h 30m
```

The job-level timeout can exceed the
[project-level timeout](../../user/project/pipelines/settings.md#timeout) but can not
exceed the Runner-specific timeout.

### `parallel`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/22631) in GitLab 11.5.

`parallel` allows you to configure how many instances of a job to run in
parallel. This value has to be greater than or equal to two (2) and less than or equal to 50.

This creates N instances of the same job that run in parallel. They're named
sequentially from `job_name 1/N` to `job_name N/N`.

For every job, `CI_NODE_INDEX` and `CI_NODE_TOTAL` [environment variables](../variables/README.md#predefined-environment-variables) are set.

Marking a job to be run in parallel requires adding `parallel` to your configuration
file. For example:

```yaml
test:
  script: rspec
  parallel: 5
```

TIP: **Tip:**
Parallelize tests suites across parallel jobs.
Different languages have different tools to facilitate this.

A simple example using [Semaphore Test Boosters](https://github.com/renderedtext/test-boosters) and RSpec to run some Ruby tests:

```ruby
# Gemfile
source 'https://rubygems.org'

gem 'rspec'
gem 'semaphore_test_boosters'
```

```yaml
test:
  parallel: 3
  script:
    - bundle
    - bundle exec rspec_booster --job $CI_NODE_INDEX/$CI_NODE_TOTAL
```

CAUTION: **Caution:**
Please be aware that semaphore_test_boosters reports usages statistics to the author.

You can then navigate to the **Jobs** tab of a new pipeline build and see your RSpec
job split into three separate jobs.

### `trigger` **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/8997) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.8.

`trigger` allows you to define downstream pipeline trigger. When a job created
from `trigger` definition is started by GitLab, a downstream pipeline gets
created.

Learn more about [multi-project pipelines](../multi_project_pipelines.md#creating-multi-project-pipelines-from-gitlab-ciyml).

NOTE: **Note:**
Using a `trigger` with `when:manual` together results in the error `jobs:#{job-name}
when should be on_success, on_failure or always`, because `when:manual` prevents
triggers being used.

#### Simple `trigger` syntax

The simplest way to configure a downstream trigger is to use `trigger` keyword
with a full path to a downstream project:

```yaml
rspec:
  stage: test
  script: bundle exec rspec

staging:
  stage: deploy
  trigger: my/deployment
```

#### Complex `trigger` syntax

It is possible to configure a branch name that GitLab will use to create
a downstream pipeline with:

```yaml
rspec:
  stage: test
  script: bundle exec rspec

staging:
  stage: deploy
  trigger:
    project: my/deployment
    branch: stable
```

It is possible to mirror the status from a triggered pipeline:

```yaml
trigger_job:
  trigger:
    project: my/project
    strategy: depend
```

It is possible to mirror the status from an upstream pipeline:

```yaml
upstream_bridge:
  stage: test
  needs:
    pipeline: other/project
```

### `interruptible`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/23464) in GitLab 12.3.

`interruptible` is used to indicate that a job should be canceled if made redundant by a newer pipeline run. Defaults to `false`.
This value will only be used if the [automatic cancellation of redundant pipelines feature](../../user/project/pipelines/settings.md#auto-cancel-pending-pipelines)
is enabled.

When enabled, a pipeline on the same branch will be canceled when:

- It is made redundant by a newer pipeline run.
- Either all jobs are set as interruptible, or any uninterruptible jobs have not started.

Pending jobs are always considered interruptible.

TIP: **Tip:**
Set jobs as interruptible that can be safely canceled once started (for instance, a build job).

Here is a simple example:

```yaml
stages:
  - stage1
  - stage2
  - stage3

step-1:
  stage: stage1
  script:
    - echo "Can be canceled."
  interruptible: true

step-2:
  stage: stage2
  script:
    - echo "Can not be canceled."

step-3:
  stage: stage3
  script:
    - echo "Because step-2 can not be canceled, this step will never be canceled, even though set as interruptible."
  interruptible: true
```

In the example above, a new pipeline run will cause an existing running pipeline to be:

- Canceled, if only `step-1` is running or pending.
- Not canceled, once `step-2` starts running.

NOTE: **Note:**
Once an uninterruptible job is running, the pipeline will never be canceled, regardless of the final job's state.

### `resource_group`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/15536) in GitLab 12.7.

Sometimes running multiples jobs or pipelines at the same time in an environment
can lead to errors during the deployment.

To avoid these errors, the `resource_group` attribute can be used to ensure that
the Runner will not run certain jobs simultaneously.

When the `resource_group` key is defined in a job in `.gitlab-ci.yml`,
job runs are mutually exclusive across different pipelines in the same project.
If multiple jobs belonging to the same resource group are enqueued simultaneously,
only one of them will be picked by the Runner, and the other jobs will wait until the
`resource_group` is free.

Here is a simple example:

```yaml
deploy-to-production:
  script: deploy
  resource_group: production
```

In this case, if a `deploy-to-production` job is running in a pipeline, and a new
`deploy-to-production` job is created in a different pipeline, it will not run until
the currently running/pending `deploy-to-production` job is finished. As a result,
you can ensure that concurrent deployments will never happen to the production environment.

There can be multiple `resource_group`s defined per environment. A good use case for this
is when deploying to physical devices. You may have more than one physical device, and each
one can be deployed to, but there can be only one deployment per device at any given time.

### `include`

> - Introduced in [GitLab Premium](https://about.gitlab.com/pricing/) 10.5.
> - Available for Starter, Premium and Ultimate since 10.6.
> - [Moved](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/21603) to GitLab Core in 11.4.

Using the `include` keyword, you can allow the inclusion of external YAML files.
`include` requires the external YAML file to have the extensions `.yml` or `.yaml`,
otherwise the external file will not be included.

The files defined in `include` are:

- Deep merged with those in `.gitlab-ci.yml`.
- Always evaluated first and merged with the content of `.gitlab-ci.yml`,
  regardless of the position of the `include` keyword.

TIP: **Tip:**
Use merging to customize and override included CI/CD configurations with local
definitions.

NOTE: **Note:**
Using YAML aliases across different YAML files sourced by `include` is not
supported. You must only refer to aliases in the same file. Instead
of using YAML anchors, you can use the [`extends` keyword](#extends).

`include` supports four include methods:

- [`local`](#includelocal)
- [`file`](#includefile)
- [`template`](#includetemplate)
- [`remote`](#includeremote)

See [usage examples](#include-examples).

NOTE: **Note:**
`.gitlab-ci.yml` configuration included by all methods is evaluated at pipeline creation.
The configuration is a snapshot in time and persisted in the database. Any changes to
referenced `.gitlab-ci.yml` configuration will not be reflected in GitLab until the next pipeline is created.

#### `include:local`

`include:local` includes a file from the same repository as `.gitlab-ci.yml`.
It's referenced using full paths relative to the root directory (`/`).

You can only use files that are currently tracked by Git on the same branch
your configuration file is on. In other words, when using a `include:local`, make
sure that both `.gitlab-ci.yml` and the local file are on the same branch.

All [nested includes](#nested-includes) will be executed in the scope of the same project,
so it is possible to use local, project, remote or template includes.

NOTE: **Note:**
Including local files through Git submodules paths is not supported.

Example:

```yaml
include:
  - local: '/templates/.gitlab-ci-template.yml'
```

#### `include:file`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/53903) in GitLab 11.7.

To include files from another private project under the same GitLab instance,
use `include:file`. This file is referenced using full  paths relative to the
root directory (`/`). For example:

```yaml
include:
  - project: 'my-group/my-project'
    file: '/templates/.gitlab-ci-template.yml'
```

You can also specify `ref`, with the default being the `HEAD` of the project:

```yaml
include:
  - project: 'my-group/my-project'
    ref: master
    file: '/templates/.gitlab-ci-template.yml'

  - project: 'my-group/my-project'
    ref: v1.0.0
    file: '/templates/.gitlab-ci-template.yml'

  - project: 'my-group/my-project'
    ref: 787123b47f14b552955ca2786bc9542ae66fee5b # Git SHA
    file: '/templates/.gitlab-ci-template.yml'
```

All [nested includes](#nested-includes) will be executed in the scope of the target project,
so it is possible to use local (relative to target project), project, remote
or template includes.

#### `include:template`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/53445) in GitLab 11.7.

`include:template` can be used to include `.gitlab-ci.yml` templates that are
[shipped with GitLab](https://gitlab.com/gitlab-org/gitlab/tree/master/lib/gitlab/ci/templates).

For example:

```yaml
# File sourced from GitLab's template collection
include:
  - template: Auto-DevOps.gitlab-ci.yml
```

Multiple `include:template` files:

```yaml
include:
  - template: Android-Fastlane.gitlab-ci.yml
  - template: Auto-DevOps.gitlab-ci.yml
```

All [nested includes](#nested-includes) will be executed only with the permission of the user,
so it is possible to use project, remote or template includes.

#### `include:remote`

`include:remote` can be used to include a file from a different location,
using HTTP/HTTPS, referenced by using the full URL. The remote file must be
publicly accessible through a simple GET request as authentication schemas
in the remote URL is not supported. For example:

```yaml
include:
  - remote: 'https://gitlab.com/awesome-project/raw/master/.gitlab-ci-template.yml'
```

All nested includes will be executed without context as public user, so only another remote,
or public project, or template is allowed.

#### Nested includes

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/56836) in GitLab 11.9.

Nested includes allow you to compose a set of includes.
A total of 100 includes is allowed.
Duplicate includes are considered a configuration error.

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/28212) in GitLab 12.4.

A hard limit of 30 seconds was set for resolving all files.

#### `include` examples

Here are a few more `include` examples.

##### Single string or array of multiple values

You can include your extra YAML file(s) either as a single string or
an array of multiple values. The following examples are all valid.

Single string with the `include:local` method implied:

```yaml
include: '/templates/.after-script-template.yml'
```

Array with `include` method implied:

```yaml
include:
  - 'https://gitlab.com/awesome-project/raw/master/.before-script-template.yml'
  - '/templates/.after-script-template.yml'
```

Single string with `include` method specified explicitly:

```yaml
include:
  remote: 'https://gitlab.com/awesome-project/raw/master/.before-script-template.yml'
```

Array with `include:remote` being the single item:

```yaml
include:
  - remote: 'https://gitlab.com/awesome-project/raw/master/.before-script-template.yml'
```

Array with multiple `include` methods specified explicitly:

```yaml
include:
  - remote: 'https://gitlab.com/awesome-project/raw/master/.before-script-template.yml'
  - local: '/templates/.after-script-template.yml'
  - template: Auto-DevOps.gitlab-ci.yml
```

Array mixed syntax:

```yaml
include:
  - 'https://gitlab.com/awesome-project/raw/master/.before-script-template.yml'
  - '/templates/.after-script-template.yml'
  - template: Auto-DevOps.gitlab-ci.yml
  - project: 'my-group/my-project'
    ref: master
    file: '/templates/.gitlab-ci-template.yml'
```

##### Re-using a `before_script` template

In the following example, the content of `.before-script-template.yml` will be
automatically fetched and evaluated along with the content of `.gitlab-ci.yml`.

Content of `https://gitlab.com/awesome-project/raw/master/.before-script-template.yml`:

```yaml
before_script:
  - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
  - gem install bundler --no-document
  - bundle install --jobs $(nproc)  "${FLAGS[@]}"
```

Content of `.gitlab-ci.yml`:

```yaml
include: 'https://gitlab.com/awesome-project/raw/master/.before-script-template.yml'

rspec:
  script:
    - bundle exec rspec
```

##### Overriding external template values

The following example shows specific YAML-defined variables and details of the
`production` job from an include file being customized in `.gitlab-ci.yml`.

Content of `https://company.com/autodevops-template.yml`:

```yaml
variables:
  POSTGRES_USER: user
  POSTGRES_PASSWORD: testing_password
  POSTGRES_DB: $CI_ENVIRONMENT_SLUG

production:
  stage: production
  script:
    - install_dependencies
    - deploy
  environment:
    name: production
    url: https://$CI_PROJECT_PATH_SLUG.$KUBE_INGRESS_BASE_DOMAIN
  only:
    - master
```

Content of `.gitlab-ci.yml`:

```yaml
include: 'https://company.com/autodevops-template.yml'

image: alpine:latest

variables:
  POSTGRES_USER: root
  POSTGRES_PASSWORD: secure_password

stages:
  - build
  - test
  - production

production:
  environment:
    url: https://domain.com
```

In this case, the variables `POSTGRES_USER` and `POSTGRES_PASSWORD` along
with the environment url of the `production` job defined in
`autodevops-template.yml` have been overridden by new values defined in
`.gitlab-ci.yml`.

The merging lets you extend and override dictionary mappings, but
you cannot add or modify items to an included array. For example, to add
an additional item to the production job script, you must repeat the
existing script items:

Content of `https://company.com/autodevops-template.yml`:

```yaml
production:
  stage: production
  script:
    - install_dependencies
    - deploy
```

Content of `.gitlab-ci.yml`:

```yaml
include: 'https://company.com/autodevops-template.yml'

stages:
  - production

production:
  script:
    - install_dependencies
    - deploy
    - notify_owner
```

In this case, if `install_dependencies` and `deploy` were not repeated in
`.gitlab-ci.yml`, they would not be part of the script for the `production`
job in the combined CI configuration.

##### Using nested includes

The examples below show how includes can be nested from different sources
using a combination of different methods.

In this example, `.gitlab-ci.yml` includes local the file `/.gitlab-ci/another-config.yml`:

```yaml
include:
  - local: /.gitlab-ci/another-config.yml
```

The `/.gitlab-ci/another-config.yml` includes a template and the `/templates/docker-workflow.yml` file
from another project:

```yaml
include:
  - template: Bash.gitlab-ci.yml
  - project: group/my-project
    file: /templates/docker-workflow.yml
```

The `/templates/docker-workflow.yml` present in `group/my-project` includes two local files
of the `group/my-project`:

```yaml
include:
  - local: /templates/docker-build.yml
  - local: /templates/docker-testing.yml
```

Our `/templates/docker-build.yml` present in `group/my-project` adds a `docker-build` job:

```yaml
docker-build:
  script: docker build -t my-image .
```

Our second `/templates/docker-test.yml` present in `group/my-project` adds a `docker-test` job:

```yaml
docker-test:
  script: docker run my-image /run/tests.sh
```

### `extends`

> Introduced in GitLab 11.3.

`extends` defines entry names that a job that uses `extends` is going to
inherit from.

It is an alternative to using [YAML anchors](#anchors) and is a little
more flexible and readable:

```yaml
.tests:
  script: rake test
  stage: test
  only:
    refs:
      - branches

rspec:
  extends: .tests
  script: rake rspec
  only:
    variables:
      - $RSPEC
```

In the example above, the `rspec` job inherits from the `.tests` template job.
GitLab will perform a reverse deep merge based on the keys. GitLab will:

- Merge the `rspec` contents into `.tests` recursively.
- Not merge the values of the keys.

This results in the following `rspec` job:

```yaml
rspec:
  script: rake rspec
  stage: test
  only:
    refs:
      - branches
    variables:
      - $RSPEC
```

NOTE: **Note:**
Note that `script: rake test` has been overwritten by `script: rake rspec`.

If you do want to include the `rake test`, see [`before_script` and `after_script`](#before_script-and-after_script).

`.tests` in this example is a [hidden key](#hidden-keys-jobs), but it's
possible to inherit from regular jobs as well.

`extends` supports multi-level inheritance, however it is not recommended to
use more than three levels. The maximum nesting level that is supported is 10.
The following example has two levels of inheritance:

```yaml
.tests:
  only:
    - pushes

.rspec:
  extends: .tests
  script: rake rspec

rspec 1:
  variables:
    RSPEC_SUITE: '1'
  extends: .rspec

rspec 2:
  variables:
    RSPEC_SUITE: '2'
  extends: .rspec

spinach:
  extends: .tests
  script: rake spinach
```

In GitLab 12.0 and later, it's also possible to use multiple parents for
`extends`.  The algorithm used for merge is "closest scope wins", so
keys from the last member will always shadow anything defined on other
levels.  For example:

```yaml
.only-important:
  only:
    - master
    - stable
  tags:
    - production

.in-docker:
  tags:
    - docker
  image: alpine

rspec:
  extends:
    - .only-important
    - .in-docker
  script:
    - rake rspec
```

This results in the following `rspec` job:

```yaml
rspec:
  only:
    - master
    - stable
  tags:
    - docker
  image: alpine
  script:
    - rake rspec
```

### Using `extends` and `include` together

`extends` works across configuration files combined with `include`.

For example, if you have a local `included.yml` file:

```yaml
.template:
  script:
    - echo Hello!
```

Then, in `.gitlab-ci.yml` you can use it like this:

```yaml
include: included.yml

useTemplate:
  image: alpine
  extends: .template
```

This will run a job called `useTemplate` that runs `echo Hello!` as defined in
the `.template` job, and uses the `alpine` Docker image as defined in the local job.

### `pages`

`pages` is a special job that is used to upload static content to GitLab that
can be used to serve your website. It has a special syntax, so the two
requirements below must be met:

- Any static content must be placed under a `public/` directory.
- `artifacts` with a path to the `public/` directory must be defined.

The example below simply moves all files from the root of the project to the
`public/` directory. The `.public` workaround is so `cp` doesn't also copy
`public/` to itself in an infinite loop:

```yaml
pages:
  stage: deploy
  script:
    - mkdir .public
    - cp -r * .public
    - mv .public public
  artifacts:
    paths:
      - public
  only:
    - master
```

Read more on [GitLab Pages user documentation](../../user/project/pages/index.md).

### `variables`

> Introduced in GitLab Runner v0.5.0.

NOTE: **Note:**
Integers (as well as strings) are legal both for variable's name and value.
Floats are not legal and cannot be used.

GitLab CI/CD allows you to define variables inside `.gitlab-ci.yml` that are
then passed in the job environment. They can be set globally and per-job.
When the `variables` keyword is used on a job level, it overrides the global
YAML variables and predefined ones.

They are stored in the Git repository and are meant to store non-sensitive
project configuration, for example:

```yaml
variables:
  DATABASE_URL: "postgres://postgres@postgres/my_database"
```

These variables can be later used in all executed commands and scripts.
The YAML-defined variables are also set to all created service containers,
thus allowing to fine tune them.

Except for the user defined variables, there are also the ones [set up by the
Runner itself](../variables/README.md#predefined-environment-variables).
One example would be `CI_COMMIT_REF_NAME` which has the value of
the branch or tag name for which project is built. Apart from the variables
you can set in `.gitlab-ci.yml`, there are also the so called
[Variables](../variables/README.md#gitlab-cicd-environment-variables)
which can be set in GitLab's UI.

Learn more about [variables and their priority][variables].

#### YAML anchors for variables

[YAML anchors](#anchors) can be used with `variables`, to easily repeat assignment
of variables across multiple jobs. It can also enable more flexibility when a job
requires a specific `variables` block that would otherwise override the global variables.

In the example below, we will override the `GIT_STRATEGY` variable without affecting
the use of the `SAMPLE_VARIABLE` variable:

```yaml
# global variables
variables: &global-variables
  SAMPLE_VARIABLE: sample_variable_value

# a job that needs to set the GIT_STRATEGY variable, yet depend on global variables
job_no_git_strategy:
  stage: cleanup
  variables:
    <<: *global-variables
    GIT_STRATEGY: none
  script: echo $SAMPLE_VARIABLE
```

#### Git strategy

> Introduced in GitLab 8.9 as an experimental feature. May change or be removed
> completely in future releases. `GIT_STRATEGY=none` requires GitLab Runner
> v1.7+.

You can set the `GIT_STRATEGY` used for getting recent application code, either
globally or per-job in the [`variables`](#variables) section. If left
unspecified, the default from project settings will be used.

There are three possible values: `clone`, `fetch`, and `none`.

`clone` is the slowest option. It clones the repository from scratch for every
job, ensuring that the local working copy is always pristine.

```yaml
variables:
  GIT_STRATEGY: clone
```

`fetch` is faster as it re-uses the local working copy (falling back to `clone`
if it doesn't exist). `git clean` is used to undo any changes made by the last
job, and `git fetch` is used to retrieve commits made since the last job ran.

```yaml
variables:
  GIT_STRATEGY: fetch
```

`none` also re-uses the local working copy, but skips all Git operations
(including GitLab Runner's pre-clone script, if present). It is mostly useful
for jobs that operate exclusively on artifacts (e.g., `deploy`). Git repository
data may be present, but it is certain to be out of date, so you should only
rely on files brought into the local working copy from cache or artifacts.

```yaml
variables:
  GIT_STRATEGY: none
```

NOTE: **Note:** `GIT_STRATEGY` is not supported for
[Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes.html),
but may be in the future. See the [support Git strategy with Kubernetes executor feature proposal](https://gitlab.com/gitlab-org/gitlab-runner/issues/3847)
for updates.

#### Git submodule strategy

> Requires GitLab Runner v1.10+.

The `GIT_SUBMODULE_STRATEGY` variable is used to control if / how Git
submodules are included when fetching the code before a build. You can set them
globally or per-job in the [`variables`](#variables) section.

There are three possible values: `none`, `normal`, and `recursive`:

- `none` means that submodules will not be included when fetching the project
  code. This is the default, which matches the pre-v1.10 behavior.

- `normal` means that only the top-level submodules will be included. It is
  equivalent to:

  ```shell
  git submodule sync
  git submodule update --init
  ```

- `recursive` means that all submodules (including submodules of submodules)
  will be included. This feature needs Git v1.8.1 and later. When using a
  GitLab Runner with an executor not based on Docker, make sure the Git version
  meets that requirement. It is equivalent to:

  ```shell
  git submodule sync --recursive
  git submodule update --init --recursive
  ```

Note that for this feature to work correctly, the submodules must be configured
(in `.gitmodules`) with either:

- the HTTP(S) URL of a publicly-accessible repository, or
- a relative path to another repository on the same GitLab server. See the
  [Git submodules](../git_submodules.md) documentation.

#### Git checkout

> Introduced in GitLab Runner 9.3.

The `GIT_CHECKOUT` variable can be used when the `GIT_STRATEGY` is set to either
`clone` or `fetch` to specify whether a `git checkout` should be run. If not
specified, it defaults to true. You can set them globally or per-job in the
[`variables`](#variables) section.

If set to `false`, the Runner will:

- when doing `fetch` - update the repository and leave working copy on
  the current revision,
- when doing `clone` - clone the repository and leave working copy on the
  default branch.

Having this setting set to `true` will mean that for both `clone` and `fetch`
strategies the Runner will checkout the working copy to a revision related
to the CI pipeline:

```yaml
variables:
  GIT_STRATEGY: clone
  GIT_CHECKOUT: "false"
script:
  - git checkout -B master origin/master
  - git merge $CI_COMMIT_SHA
```

#### Git clean flags

> Introduced in GitLab Runner 11.10

The `GIT_CLEAN_FLAGS` variable is used to control the default behavior of
`git clean` after checking out the sources. You can set it globally or per-job in the
[`variables`](#variables) section.

`GIT_CLEAN_FLAGS` accepts all possible options of the [`git clean`](https://git-scm.com/docs/git-clean)
command.

`git clean` is disabled if `GIT_CHECKOUT: "false"` is specified.

If `GIT_CLEAN_FLAGS` is:

- Not specified, `git clean` flags default to `-ffdx`.
- Given the value `none`, `git clean` is not executed.

For example:

```yaml
variables:
  GIT_CLEAN_FLAGS: -ffdx -e cache/
script:
  - ls -al cache/
```

#### Job stages attempts

> Introduced in GitLab, it requires GitLab Runner v1.9+.

You can set the number for attempts the running job will try to execute each
of the following stages:

| Variable                        | Description |
|-------------------------------- |-------------|
| **GET_SOURCES_ATTEMPTS**        | Number of attempts to fetch sources running a job |
| **ARTIFACT_DOWNLOAD_ATTEMPTS**  | Number of attempts to download artifacts running a job |
| **RESTORE_CACHE_ATTEMPTS**      | Number of attempts to restore the cache running a job |

The default is one single attempt.

Example:

```yaml
variables:
  GET_SOURCES_ATTEMPTS: 3
```

You can set them globally or per-job in the [`variables`](#variables) section.

#### Shallow cloning

> Introduced in GitLab 8.9 as an experimental feature. May change in future
releases or be removed completely.

You can specify the depth of fetching and cloning using `GIT_DEPTH`. This allows
shallow cloning of the repository which can significantly speed up cloning for
repositories with a large number of commits or old, large binaries. The value is
passed to `git fetch` and `git clone`.

NOTE: **Note:**
If you use a depth of 1 and have a queue of jobs or retry
jobs, jobs may fail.

Since Git fetching and cloning is based on a ref, such as a branch name, Runners
can't clone a specific commit SHA. If there are multiple jobs in the queue, or
you are retrying an old job, the commit to be tested needs to be within the
Git history that is cloned. Setting too small a value for `GIT_DEPTH` can make
it impossible to run these old commits. You will see `unresolved reference` in
job logs. You should then reconsider changing `GIT_DEPTH` to a higher value.

Jobs that rely on `git describe` may not work correctly when `GIT_DEPTH` is
set since only part of the Git history is present.

To fetch or clone only the last 3 commits:

```yaml
variables:
  GIT_DEPTH: "3"
```

You can set it globally or per-job in the [`variables`](#variables) section.

## Deprecated parameters

The following parameters are deprecated.

### Globally-defined `types`

CAUTION: **Deprecated:**
`types` is deprecated, and could be removed in a future release.
Use [`stages`](#stages) instead.

### Job-defined `type`

CAUTION: **Deprecated:**
`type` is deprecated, and could be removed in one of the future releases.
Use [`stage`](#stage) instead.

### Globally-defined `image`, `services`, `cache`, `before_script`, `after_script`

Defining `image`, `services`, `cache`, `before_script`, and
`after_script` globally is deprecated. Support could be removed
from a future release.

Use [`default:`](#setting-default-parameters) instead. For example:

```yaml
default:
  image: ruby:2.5
  services:
    - docker:dind
  cache:
    paths: [vendor/]
  before_script:
    - bundle install --path vendor/
  after_script:
    - rm -rf tmp/
```

## Custom build directories

> [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/merge_requests/1267) in GitLab Runner 11.10

NOTE: **Note:**
This can only be used when `custom_build_dir` is enabled in the [Runner's
configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runnerscustom_build_dir-section).
This is the default configuration for `docker` and `kubernetes` executor.

By default, GitLab Runner clones the repository in a unique subpath of the
`$CI_BUILDS_DIR` directory. However, your project might require the code in a
specific directory (Go projects, for example). In that case, you can specify
the `GIT_CLONE_PATH` variable to tell the Runner in which directory to clone the
repository:

```yml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/project-name

test:
  script:
    - pwd
```

The `GIT_CLONE_PATH` has to always be within `$CI_BUILDS_DIR`. The directory set in `$CI_BUILDS_DIR`
is dependent on executor and configuration of [runners.builds_dir](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)
setting.

### Handling concurrency

An executor using a concurrency greater than `1` might lead
to failures because multiple jobs might be working on the same directory if the `builds_dir`
is shared between jobs.
GitLab Runner does not try to prevent this situation. It is up to the administrator
and developers to comply with the requirements of Runner configuration.

To avoid this scenario, you can use a unique path within `$CI_BUILDS_DIR`, because Runner
exposes two additional variables that provide a unique `ID` of concurrency:

- `$CI_CONCURRENT_ID`: Unique ID for all jobs running within the given executor.
- `$CI_CONCURRENT_PROJECT_ID`: Unique ID for all jobs running within the given executor and project.

The most stable configuration that should work well in any scenario and on any executor
is to use `$CI_CONCURRENT_ID` in the `GIT_CLONE_PATH`. For example:

```yml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/$CI_CONCURRENT_ID/project-name

test:
  script:
    - pwd
```

The `$CI_CONCURRENT_PROJECT_ID` should be used in conjunction with `$CI_PROJECT_PATH`
as the `$CI_PROJECT_PATH` provides a path of a repository. That is, `group/subgroup/project`. For example:

```yml
variables:
  GIT_CLONE_PATH: $CI_BUILDS_DIR/$CI_CONCURRENT_ID/$CI_PROJECT_PATH

test:
  script:
    - pwd
```

### Nested paths

The value of `GIT_CLONE_PATH` is expanded once and nesting variables
within it is not supported.

For example, you define both the variables below in your
`.gitlab-ci.yml` file:

```yml
variables:
  GOPATH: $CI_BUILDS_DIR/go
  GIT_CLONE_PATH: $GOPATH/src/namespace/project
```

The value of `GIT_CLONE_PATH` is expanded once into
`$CI_BUILDS_DIR/go/src/namespace/project`, and results in failure
because `$CI_BUILDS_DIR` is not expanded.

## Special YAML features

It's possible to use special YAML features like anchors (`&`), aliases (`*`)
and map merging (`<<`), which will allow you to greatly reduce the complexity
of `.gitlab-ci.yml`.

Read more about the various [YAML features](https://learnxinyminutes.com/docs/yaml/).

### Hidden keys (jobs)

> Introduced in GitLab 8.6 and GitLab Runner v1.1.1.

If you want to temporarily 'disable' a job, rather than commenting out all the
lines where the job is defined:

```yaml
#hidden_job:
#  script:
#    - run test
```

you can instead start its name with a dot (`.`) and it will not be processed by
GitLab CI. In the following example, `.hidden_job` will be ignored:

```yaml
.hidden_job:
  script:
    - run test
```

Use this feature to ignore jobs, or use the
[special YAML features](#special-yaml-features) and transform the hidden keys
into templates.

### Anchors

> Introduced in GitLab 8.6 and GitLab Runner v1.1.1.

YAML has a handy feature called 'anchors', which lets you easily duplicate
content across your document. Anchors can be used to duplicate/inherit
properties, and is a perfect example to be used with [hidden keys](#hidden-keys-jobs)
to provide templates for your jobs.

The following example uses anchors and map merging. It will create two jobs,
`test1` and `test2`, that will inherit the parameters of `.job_template`, each
having their own custom `script` defined:

```yaml
.job_template: &job_definition  # Hidden key that defines an anchor named 'job_definition'
  image: ruby:2.6
  services:
    - postgres
    - redis

test1:
  <<: *job_definition           # Merge the contents of the 'job_definition' alias
  script:
    - test1 project

test2:
  <<: *job_definition           # Merge the contents of the 'job_definition' alias
  script:
    - test2 project
```

`&` sets up the name of the anchor (`job_definition`), `<<` means "merge the
given hash into the current one", and `*` includes the named anchor
(`job_definition` again). The expanded version looks like this:

```yaml
.job_template:
  image: ruby:2.6
  services:
    - postgres
    - redis

test1:
  image: ruby:2.6
  services:
    - postgres
    - redis
  script:
    - test1 project

test2:
  image: ruby:2.6
  services:
    - postgres
    - redis
  script:
    - test2 project
```

Let's see another one example. This time we will use anchors to define two sets
of services. This will create two jobs, `test:postgres` and `test:mysql`, that
will share the `script` directive defined in `.job_template`, and the `services`
directive defined in `.postgres_services` and `.mysql_services` respectively:

```yaml
.job_template: &job_definition
  script:
    - test project

.postgres_services:
  services: &postgres_definition
    - postgres
    - ruby

.mysql_services:
  services: &mysql_definition
    - mysql
    - ruby

test:postgres:
  <<: *job_definition
  services: *postgres_definition

test:mysql:
  <<: *job_definition
  services: *mysql_definition
```

The expanded version looks like this:

```yaml
.job_template:
  script:
    - test project

.postgres_services:
  services:
    - postgres
    - ruby

.mysql_services:
  services:
    - mysql
    - ruby

test:postgres:
  script:
    - test project
  services:
    - postgres
    - ruby

test:mysql:
  script:
    - test project
  services:
    - mysql
    - ruby
```

You can see that the hidden keys are conveniently used as templates.

NOTE: **Note:**
You can't use YAML anchors across multiple files when leveraging the [`include`](#include)
feature. Anchors are only valid within the file they were defined in.

## Triggers

Triggers can be used to force a rebuild of a specific branch, tag or commit,
with an API call when a pipeline gets created using a trigger token.

Not to be confused with [`trigger`](#trigger-premium).

[Read more in the triggers documentation.](../triggers/README.md)

## Processing Git pushes

GitLab will create at most 4 branch and tags pipelines when
doing pushing multiple changes in single `git push` invocation.

This limitation does not affect any of the updated Merge Request pipelines,
all updated Merge Requests will have a pipeline created when using
[pipelines for merge requests](../merge_request_pipelines/index.md).

## Skipping jobs

If your commit message contains `[ci skip]` or `[skip ci]`, using any
capitalization, the commit will be created but the pipeline will be skipped.

Alternatively, one can pass the `ci.skip` [Git push option](../../user/project/push_options.md#push-options-for-gitlab-cicd)
if using Git 2.10 or newer.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

[ce-6323]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/6323
[ce-6669]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/6669
[ce-7983]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/7983
[ce-7447]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/7447
[ce-12909]: https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/12909
[ce-19232]: https://gitlab.com/gitlab-org/gitlab-foss/issues/19232
[environment]: ../environments.md "CI/CD environments"
[schedules]: ../../user/project/pipelines/schedules.md "Pipelines schedules"
[variables]: ../variables/README.md "CI/CD variables"
[push-option]: https://git-scm.com/docs/git-push#Documentation/git-push.txt--oltoptiongt
