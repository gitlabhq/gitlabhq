---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# CI/CD YAML reference style guide **(FREE)**

The CI/CD YAML reference uses a standard style to make it easier to use and update.

The reference information should be kept as simple as possible, and expanded details
and examples documented in a separate page.

## YAML reference structure

Every YAML keyword must have its own section in the reference. The sections should
be nested so that the keywords follow a logical tree structure. For example:

```plaintext
### `artifacts`
#### `artifacts:name`
#### `artifacts:paths`
#### `artifacts:reports`
##### `artifacts:reports:dast`
##### `artifacts:reports:sast`
```

## YAML reference style

Each keyword entry in the reference should use the following style:

````markdown
### `keyword-name`

> Version information

Keyword description and main details.

**Keyword type**:

**Possible inputs**:

**Example of `keyword-name`**:

(optional) In this example...

(optional) **Additional details**:

- List of extra details.

(optional) **Related topics**:

- List of links to topics related to the keyword.
````

- ``### `keyword-name` ``: The keyword name must always be in backticks.
  If it is a subkey of another keyword, write out all the keywords, with each separated
  by `:`, for example: `artifacts:reports:dast`.

- ``> Version information``: The [version history details](../documentation/styleguide/index.md#version-text-in-the-version-history).
  If the keyword is feature flagged, see the [feature flag documentation guide](../documentation/feature_flags.md)
  as well.

- `Keyword description and main details.`: A simple description of the keyword, and
  how to use it. Additional use cases and benefits should be added to a page outside
  the reference document. Link to that document in this section.

- `**Keyword type**:`: Most keywords are defined at the job level, like `script`,
  or at the pipeline level, like `stages`. Add the appropriate line:

  - `**Keyword type**: Job keyword. You can use it only as part of a job.`
  - `**Keyword type**: Pipeline keyword. You cannot use it as part of a job.`

  If a keyword can be used at both the job and pipeline level, like `variables`,
  explain it in detail instead of using the pre-written lines above.

- `**Possible inputs**:`: Explain in detail which inputs the keyword can accept.
  You can add the details in a sentence, paragraph, or list.

- ``**Example of `keyword-name`**:``: An example configuration that uses the keyword.
  Do not add extra keywords that are not required to understand the behavior.

- (optional) `In this example...`: If the example needs extra details,
  add the clarification text below the example.

- (optional) `**Additional details**:` If there are any caveats or extra details you
  want to document along with the keyword, add each one as a list item here.

- (optional) `**Related topics**:` If there are any other keywords or pages that
  relate to this keyword, add these links as list items here.

### YAML reference style example

See the [`only:changes` / `except:changes`](../../ci/yaml/index.md#onlychanges--exceptchanges)
documentation for an example of the YAML reference style. The following example is a
shortened version of that documentation's Markdown:

````markdown
#### `only:changes` / `except:changes`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/19232) in GitLab 11.4.

Use the `changes` keyword with `only` to run a job, or with `except` to skip a job,
when a Git push event modifies a file.

Use `changes` in pipelines with the following refs:

- `branches`
- `external_pull_requests`
- `merge_requests` (see additional details about [using `only:changes` with pipelines for merge requests](../jobs/job_control.md#use-onlychanges-with-pipelines-for-merge-requests))

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: An array including any number of:

- Paths to files.
- Wildcard paths for single directories, for example `path/to/directory/*`, or a directory
  and all its subdirectories, for example `path/to/directory/**/*`.

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
```

In this example, `docker build` only runs in branch pipelines, and only if at least one of
these files changed:

- `Dockerfile`.
- Any file in `docker/scripts`
- Any file in `dockerfiles/` or any of its subdirectories.

**Additional details**:

- If you use refs other than `branches`, `external_pull_requests`, or `merge_requests`,
  `changes` can't determine if a given file is new or old and always returns `true`.
- If you use `only: changes` with other refs, jobs ignore the changes and always run.
- If you use `except: changes` with other refs, jobs ignore the changes and never run.

**Related topics**:

- [`only: changes` and `except: changes` examples](../jobs/job_control.md#onlychanges--exceptchanges-examples).
- If you use `changes` with [only allow merge requests to be merged if the pipeline succeeds](../../user/project/merge_requests/merge_when_pipeline_succeeds.md#only-allow-merge-requests-to-be-merged-if-the-pipeline-succeeds),
  you should [also use `only:merge_requests`](../jobs/job_control.md#use-onlychanges-with-pipelines-for-merge-requests).
- Use `changes` with [scheduled pipelines](../jobs/job_control.md#use-onlychanges-with-scheduled-pipelines).
````
