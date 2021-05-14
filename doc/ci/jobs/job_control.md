---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Choose when to run jobs **(FREE)**

When a new pipeline starts, GitLab checks the pipeline configuration to determine
which jobs should run in that pipeline. You can configure jobs to run depending on
the status of variables, the pipeline type, and so on.

To configure a job to be included or excluded from certain pipelines, you can use:

- [`rules`](../yaml/README.md#rules)
- [`only`](../yaml/README.md#only--except)
- [`except`](../yaml/README.md#only--except)

Use [`needs`](../yaml/README.md#needs) to configure a job to run as soon as the
earlier jobs it depends on finish running.

## Specify when jobs run with `only` and `except`

You can use [`only`](../yaml/README.md#only--except) and [`except`](../yaml/README.md#only--except)
to control when to add jobs to pipelines.

- Use `only` to define when a job runs.
- Use `except` to define when a job **does not** run.

### `only:refs` / `except:refs` examples

`only` or `except` used without `refs` is the same as
[`only:refs` / `except/refs`](../yaml/README.md#onlyrefs--exceptrefs)

In the following example, `job` runs only for:

- Git tags
- [Triggers](../triggers/README.md#trigger-token)
- [Scheduled pipelines](../pipelines/schedules.md)

```yaml
job:
  # use special keywords
  only:
    - tags
    - triggers
    - schedules
```

To execute jobs only for the parent repository and not forks:

```yaml
job:
  only:
    - branches@gitlab-org/gitlab
  except:
    - main@gitlab-org/gitlab
    - /^release/.*$/@gitlab-org/gitlab
```

This example runs `job` for all branches on `gitlab-org/gitlab`,
except `main` and branches that start with `release/`.

### `only: variables` / `except: variables` examples

You can use [`except:variables`](../yaml/README.md#onlyvariables--exceptvariables) to exclude jobs based on a commit message:

```yaml
end-to-end:
  script: rake test:end-to-end
  except:
    variables:
      - $CI_COMMIT_MESSAGE =~ /skip-end-to-end-tests/
```

You can use [parentheses](../variables/README.md#parentheses) with `&&` and `||`
to build more complicated variable expressions:

```yaml
job1:
  script:
    - echo This rule uses parentheses.
  only:
    variables:
      - ($CI_COMMIT_BRANCH == "master" || $CI_COMMIT_BRANCH == "develop") && $MY_VARIABLE
```

### `only:changes` / `except:changes` examples

You can skip a job if a change is detected in any file with a
`.md` extension in the root directory of the repository:

```yaml
build:
  script: npm run build
  except:
    changes:
      - "*.md"
```

If you change multiple files, but only one file ends in `.md`,
the `build` job is still skipped. The job does not run for any of the files.

Read more about how to use `only:changes` and `except:changes`:

- [New branches or tags *without* pipelines for merge requests](#use-onlychanges-without-pipelines-for-merge-requests).
- [Scheduled pipelines](#use-onlychanges-with-scheduled-pipelines).

#### Use `only:changes` with pipelines for merge requests

With [pipelines for merge requests](../merge_request_pipelines/index.md),
it's possible to define a job to be created based on files modified
in a merge request.

Use this keyword with `only: [merge_requests]` so GitLab can find the correct base
SHA of the source branch. File differences are correctly calculated from any further
commits, and all changes in the merge requests are properly tested in pipelines.

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

In this scenario, if a merge request changes
files in the `service-one` directory or the `Dockerfile`, GitLab creates
the `docker build service one` job.

For example:

```yaml
docker build service one:
  script: docker build -t my-service-one-image:$CI_COMMIT_REF_SLUG .
  only:
    changes:
      - Dockerfile
      - service-one/**/*
```

In this example, the pipeline might fail because of changes to a file in `service-one/**/*`.

A later commit that doesn't have changes in `service-one/**/*`
but does have changes to the `Dockerfile` can pass. The job
only tests the changes to the `Dockerfile`.

GitLab checks the **most recent pipeline** that **passed**. If the merge request is mergeable,
it doesn't matter that an earlier pipeline failed because of a change that has not been corrected.

When you use this configuration, ensure that the most recent pipeline
properly corrects any failures from previous pipelines.

#### Use `only:changes` without pipelines for merge requests

Without [pipelines for merge requests](../merge_request_pipelines/index.md), pipelines
run on branches or tags that don't have an explicit association with a merge request.
In this case, a previous SHA is used to calculate the diff, which is equivalent to `git diff HEAD~`.
This can result in some unexpected behavior, including:

- When pushing a new branch or a new tag to GitLab, the policy always evaluates to true.
- When pushing a new commit, the changed files are calculated by using the previous commit
  as the base SHA.

#### Use `only:changes` with scheduled pipelines

`only:changes` always evaluates as true in [Scheduled pipelines](../pipelines/schedules.md).
All files are considered to have changed when a scheduled pipeline runs.

### Combine multiple keywords with `only` or `except`

If you use multiple keywords with `only` or `except`, the keywords are evaluated
as a single conjoined expression. That is:

- `only:` includes the job if **all** of the keys have at least one condition that matches.
- `except:` excludes the job if **any** of the keys have at least one condition that matches.

With `only`, individual keys are logically joined by an `AND`. A job is added to
the pipeline if the following is true:

- `(any listed refs are true) AND (any listed variables are true) AND (any listed changes are true) AND (any chosen Kubernetes status matches)`

In the following example, the `test` job is only created when **all** of the following are true:

- The pipeline is [scheduled](../pipelines/schedules.md) **or** runs for `main`.
- The `variables` keyword matches.
- The `kubernetes` service is active on the project.

```yaml
test:
  script: npm run test
  only:
    refs:
      - main
      - schedules
    variables:
      - $CI_COMMIT_MESSAGE =~ /run-end-to-end-tests/
    kubernetes: active
```

With `except`, individual keys are logically joined by an `OR`. A job is **not**
added if the following is true:

- `(any listed refs are true) OR (any listed variables are true) OR (any listed changes are true) OR (a chosen Kubernetes status matches)`

In the following example, the `test` job is **not** created when **any** of the following are true:

- The pipeline runs for the `main` branch.
- There are changes to the `README.md` file in the root directory of the repository.

```yaml
test:
  script: npm run test
  except:
    refs:
      - main
    changes:
      - "README.md"
```

## Use predefined CI/CD variables to run jobs only in specific pipeline types

You can use [predefined CI/CD variables](../variables/predefined_variables.md) to choose
which pipeline types jobs run in, with:

- [`rules`](../yaml/README.md#rules)
- [`only:variables`](../yaml/README.md#onlyvariables--exceptvariables)
- [`except:variables`](../yaml/README.md#onlyvariables--exceptvariables)

The following table lists some of the variables that you can use, and the pipeline
types the variables can control for:

- Branch pipelines that run for Git `push` events to a branch, like new commits or tags.
- Tag pipelines that run only when a new Git tag is pushed to a branch.
- [Merge request pipelines](../merge_request_pipelines/index.md) that run for changes
  to a merge request, like new commits or selecting the **Run pipeline** button
  in a merge request's pipelines tab.
- [Scheduled pipelines](../pipelines/schedules.md).

| Variables                                  | Branch | Tag | Merge request | Scheduled |
|--------------------------------------------|--------|-----|---------------|-----------|
| `CI_COMMIT_BRANCH`                         | Yes    |     |               | Yes       |
| `CI_COMMIT_TAG`                            |        | Yes |               | Yes, if the scheduled pipeline is configured to run on a tag. |
| `CI_PIPELINE_SOURCE = push`                | Yes    | Yes |               |           |
| `CI_PIPELINE_SOURCE = scheduled`           |        |     |               | Yes       |
| `CI_PIPELINE_SOURCE = merge_request_event` |        |     | Yes           |           |
| `CI_MERGE_REQUEST_IID`                     |        |     | Yes           |           |

For example, to configure a job to run for merge request pipelines and scheduled pipelines,
but not branch or tag pipelines:

```yaml
job1:
  script:
    - echo
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "scheduled"
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
```

## Regular expressions

The `@` symbol denotes the beginning of a ref's repository path.
To match a ref name that contains the `@` character in a regular expression,
you must use the hex character code match `\x40`.

Only the tag or branch name can be matched by a regular expression.
The repository path, if given, is always matched literally.

To match the tag or branch name,
the entire ref name part of the pattern must be a regular expression surrounded by `/`.
For example, you can't use `issue-/.*/` to match all tag names or branch names
that begin with `issue-`, but you can use `/issue-.*/`.

Regular expression flags must be appended after the closing `/`. Pattern matching
is case-sensitive by default. Use the `i` flag modifier, like `/pattern/i`, to make
a pattern case-insensitive:

```yaml
job:
  # use regexp
  only:
    - /^issue-.*$/i
  # use special keyword
  except:
    - branches
```

Use anchors `^` and `$` to avoid the regular expression
matching only a substring of the tag name or branch name.
For example, `/^issue-.*$/` is equivalent to `/^issue-/`,
while just `/issue/` would also match a branch called `severe-issues`.

### `only` / `except` regex syntax

In GitLab 11.9.4, GitLab began internally converting the regexp used
in `only` and `except` keywords to [RE2](https://github.com/google/re2/wiki/Syntax).

[RE2](https://github.com/google/re2/wiki/Syntax) limits the set of available features
due to computational complexity, and some features, like negative lookaheads, became unavailable.
Only a subset of features provided by [Ruby Regexp](https://ruby-doc.org/core/Regexp.html)
are now supported.

From GitLab 11.9.7 to GitLab 12.0, GitLab provided a feature flag to
let you use unsafe regexp syntax. After migrating to safe syntax, you should disable
this feature flag again:

```ruby
Feature.enable(:allow_unsafe_ruby_regexp)
```
