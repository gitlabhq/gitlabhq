---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Deprecated keywords
---

Some CI/CD keywords are deprecated and no longer recommended for use.

{{< alert type="warning" >}}

These keywords are still usable to ensure backwards compatibility,
but could be scheduled for removal in a future major milestone.

{{< /alert >}}

### Globally-defined `image`, `services`, `cache`, `before_script`, `after_script`

Defining `image`, `services`, `cache`, `before_script`, and `after_script` globally is deprecated.
Use [`default`](_index.md#default) instead.

For example:

```yaml
default:
  image: ruby:3.0
  services:
    - docker:dind
  cache:
    paths: [vendor/]
  before_script:
    - bundle config set path vendor/bundle
    - bundle install
  after_script:
    - rm -rf tmp/
```

### `only` / `except`

{{< alert type="note" >}}

`only` and `except` are deprecated. To control when to add jobs to pipelines, use [`rules`](_index.md#rules) instead.

{{< /alert >}}

You can use `only` and `except` to control when to add jobs to pipelines.

- Use `only` to define when a job runs.
- Use `except` to define when a job **does not** run.

#### `only:refs` / `except:refs`

{{< alert type="note" >}}

`only:refs` and `except:refs` are deprecated. To use refs, regular expressions, or variables
to control when to add jobs to pipelines, use [`rules:if`](_index.md#rulesif) instead.

{{< /alert >}}

You can use the `only:refs` and `except:refs` keywords to control when to add jobs to a
pipeline based on branch names or pipeline types.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Supported values**: An array including any number of:

- Branch names, for example `main` or `my-feature-branch`.
- Regular expressions that match against branch names, for example `/^feature-.*/`.
- The following keywords:

  | **Value**                | **Description** |
  | -------------------------|-----------------|
  | `api`                    | For pipelines triggered by the [pipelines API](../../api/pipelines.md#create-a-new-pipeline). |
  | `branches`               | When the Git reference for a pipeline is a branch. |
  | `chat`                   | For pipelines created by using a [GitLab ChatOps](../chatops/_index.md) command. |
  | `external`               | When you use CI services other than GitLab. |
  | `external_pull_requests` | When an external pull request on GitHub is created or updated (See [Pipelines for external pull requests](../ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests)). |
  | `merge_requests`         | For pipelines created when a merge request is created or updated. Enables [merge request pipelines](../pipelines/merge_request_pipelines.md), [merged results pipelines](../pipelines/merged_results_pipelines.md), and [merge trains](../pipelines/merge_trains.md). |
  | `pipelines`              | For [multi-project pipelines](../pipelines/downstream_pipelines.md#multi-project-pipelines) created by [using the API with `CI_JOB_TOKEN`](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api), or the [`trigger`](_index.md#trigger) keyword. |
  | `pushes`                 | For pipelines triggered by a `git push` event, including for branches and tags. |
  | `schedules`              | For [scheduled pipelines](../pipelines/schedules.md). |
  | `tags`                   | When the Git reference for a pipeline is a tag. |
  | `triggers`               | For pipelines created by using a [trigger token](../triggers/_index.md#configure-cicd-jobs-to-run-in-triggered-pipelines). |
  | `web`                    | For pipelines created by selecting **New pipeline** in the GitLab UI, from the project's **Build > Pipelines** section. |

**Example of `only:refs` and `except:refs`**:

```yaml
job1:
  script: echo
  only:
    - main
    - /^issue-.*$/
    - merge_requests

job2:
  script: echo
  except:
    - main
    - /^stable-branch.*$/
    - schedules
```

**Additional details**:

- Scheduled pipelines run on specific branches, so jobs configured with `only: branches`
  run on scheduled pipelines too. Add `except: schedules` to prevent jobs with `only: branches`
  from running on scheduled pipelines.
- `only` or `except` used without any other keywords are equivalent to `only: refs`
  or `except: refs`. For example, the following two jobs configurations have the same
  behavior:

  ```yaml
  job1:
    script: echo
    only:
      - branches

  job2:
    script: echo
    only:
      refs:
        - branches
  ```

- If a job does not use `only`, `except`, or [`rules`](_index.md#rules), then `only` is set to `branches`
  and `tags` by default.

  For example, `job1` and `job2` are equivalent:

  ```yaml
  job1:
    script: echo "test"

  job2:
    script: echo "test"
    only:
      - branches
      - tags
  ```

#### `only:variables` / `except:variables`

{{< alert type="note" >}}

`only:variables` and `except:variables` are deprecated. To use refs, regular expressions, or variables
to control when to add jobs to pipelines, use [`rules:if`](_index.md#rulesif) instead.

{{< /alert >}}

You can use the `only:variables` or `except:variables` keywords to control when to add jobs
to a pipeline, based on the status of [CI/CD variables](../variables/_index.md).

**Keyword type**: Job keyword. You can use it only as part of a job.

**Supported values**:

- An array of [CI/CD variable expressions](../jobs/job_rules.md#cicd-variable-expressions).

**Example of `only:variables`**:

```yaml
deploy:
  script: cap staging deploy
  only:
    variables:
      - $RELEASE == "staging"
      - $STAGING
```

#### `only:changes` / `except:changes`

{{< alert type="note" >}}

`only:changes` and `except:changes` are deprecated. To use changed files to control
when to add a job to a pipeline, use [`rules:changes`](_index.md#ruleschanges) instead.

{{< /alert >}}

Use the `changes` keyword with `only` to run a job, or with `except` to skip a job,
when a Git push event modifies a file.

Use `changes` in pipelines with the following refs:

- `branches`
- `external_pull_requests`
- `merge_requests`

**Keyword type**: Job keyword. You can use it only as part of a job.

**Supported values**: An array including any number of:

- Paths to files.
- Wildcard paths for:
  - Single directories, for example `path/to/directory/*`.
  - A directory and all its subdirectories, for example `path/to/directory/**/*`.
- Wildcard [glob](https://en.wikipedia.org/wiki/Glob_(programming)) paths for all files
  with the same extension or multiple extensions, for example `*.md` or `path/to/directory/*.{rb,py,sh}`.
- Wildcard paths to files in the root directory, or all directories, wrapped in double quotes.
  For example `"*.json"` or `"**/*.json"`.

**Example of `only:changes`**:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  only:
    refs:
      - branches
    changes:
      - Dockerfile
      - docker/scripts/*
      - dockerfiles/**/*
      - more_scripts/*.{rb,py,sh}
      - "**/*.json"
```

**Additional details**:

- `changes` resolves to `true` if any of the matching files are changed (an `OR` operation).
- Glob patterns are interpreted with Ruby's [`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)
  with the [flags](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29)
  `File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`.
- If you use refs other than `branches`, `external_pull_requests`, or `merge_requests`,
  `changes` can't determine if a given file is new or old and always returns `true`.
- If you use `only: changes` with other refs, jobs ignore the changes and always run.
- If you use `except: changes` with other refs, jobs ignore the changes and never run.

**Related topics**:

- [Jobs or pipelines can run unexpectedly when using `only: changes`](../jobs/job_troubleshooting.md#jobs-or-pipelines-run-unexpectedly-when-using-changes).

#### `only:kubernetes` / `except:kubernetes`

{{< alert type="note" >}}

`only:kubernetes` and `except:kubernetes` are deprecated. To control if jobs are added to the pipeline
when the Kubernetes service is active in the project, use [`rules:if`](_index.md#rulesif) with the
[`CI_KUBERNETES_ACTIVE`](../variables/predefined_variables.md) predefined CI/CD variable instead.

{{< /alert >}}

Use `only:kubernetes` or `except:kubernetes` to control if jobs are added to the pipeline
when the Kubernetes service is active in the project.

**Keyword type**: Job-specific. You can use it only as part of a job.

**Supported values**:

- The `kubernetes` strategy accepts only the `active` keyword.

**Example of `only:kubernetes`**:

```yaml
deploy:
  only:
    kubernetes: active
```

In this example, the `deploy` job runs only when the Kubernetes service is active
in the project.

### `publish` keyword and `pages` job name for GitLab Pages

The job-level `publish` keyword and the `pages` job name for GitLab Pages deployment jobs are deprecated.

To control the pages deployment, use the [`pages`](_index.md#pages) and [`pages.publish`](_index.md#pagespublish)
keywords instead.
