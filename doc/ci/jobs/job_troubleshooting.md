---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting jobs
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

When working with jobs, you might encounter the following issues.

## Jobs or pipelines run unexpectedly when using `changes:`

You might have jobs or pipelines that run unexpectedly when using [`rules: changes`](../yaml/_index.md#ruleschanges)
or [`only: changes`](../yaml/_index.md#onlychanges--exceptchanges) without
[merge request pipelines](../pipelines/merge_request_pipelines.md).

Pipelines on branches or tags that don't have an explicit association with a merge request
use a previous SHA to calculate the diff. This calculation is equivalent to `git diff HEAD~`
and can cause unexpected behavior, including:

- The `changes` rule always evaluates to true when pushing a new branch or a new tag to GitLab.
- When pushing a new commit, the changed files are calculated by using the previous commit
  as the base SHA.

Additionally, rules with `changes` always evaluate as true in [scheduled pipelines](../pipelines/schedules.md).
All files are considered to have changed when a scheduled pipeline runs, so jobs
might always be added to scheduled pipelines that use `changes`.

## File paths in CI/CD variables

Be careful when using file paths in CI/CD variables. A trailing slash can appear correct
in the variable definition, but can become invalid when expanded in `script:`, `changes:`,
or other keywords. For example:

```yaml
docker_build:
  variables:
    DOCKERFILES_DIR: 'path/to/files/'  # This variable should not have a trailing '/' character
  script: echo "A docker job"
  rules:
    - changes:
        - $DOCKERFILES_DIR/*
```

When the `DOCKERFILES_DIR` variable is expanded in the `changes:` section, the full
path becomes `path/to/files//*`. The double slashes might cause unexpected behavior
depending on factors like the keyword used, or the shell and OS of the runner.

## `You are not allowed to download code from this project.` error message

You might see pipelines fail when a GitLab administrator runs a protected manual job
in a private project.

CI/CD jobs usually clone the project when the job starts, and this uses [the permissions](../../user/permissions.md#cicd)
of the user that runs the job. All users, including administrators, must be direct members
of a private project to clone the source of that project. [An issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/23130)
to change this behavior.

To run protected manual jobs:

- Add the administrator as a direct member of the private project (any role)
- [Impersonate a user](../../administration/admin_area.md#user-impersonation) who is a
  direct member of the project.

## A CI/CD job does not use newer configuration when run again

The configuration for a pipeline is only fetched when the pipeline is created.
When you rerun a job, uses the same configuration each time. If you update configuration files,
including separate files added with [`include`](../yaml/_index.md#include), you must
start a new pipeline to use the new configuration.

## `Job may allow multiple pipelines to run for a single action` warning

When you use [`rules`](../yaml/_index.md#rules) with a `when` clause without an `if`
clause, multiple pipelines may run. Usually this occurs when you push a commit to
a branch that has an open merge request associated with it.

To [prevent duplicate pipelines](job_rules.md#avoid-duplicate-pipelines), use
[`workflow: rules`](../yaml/_index.md#workflow) or rewrite your rules to control
which pipelines can run.

## `This GitLab CI configuration is invalid` for variable expressions

You might receive one of several `This GitLab CI configuration is invalid` errors
when working with [CI/CD variable expressions](job_rules.md#cicd-variable-expressions).
These syntax errors can be caused by incorrect usage of quote characters.

In variable expressions, strings should be quoted, while variables should not be quoted.
For example:

```yaml
variables:
  ENVIRONMENT: production

job:
  script: echo
  rules:
    - if: $ENVIRONMENT == "production"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

In this example, both `if:` clauses are valid because the `production` string is quoted,
and the CI/CD variables are unquoted.

On the other hand, these `if:` clauses are all invalid:

```yaml
variables:
  ENVIRONMENT: production

job:
  script: echo
  rules:       # These rules all cause YAML syntax errors:
    - if: ${ENVIRONMENT} == "production"
    - if: "$ENVIRONMENT" == "production"
    - if: $ENVIRONMENT == production
    - if: "production" == "production"
```

In this example:

- `if: ${ENVIRONMENT} == "production"` is invalid, because `${ENVIRONMENT}` is not valid
  formatting for CI/CD variables in `if:`.
- `if: "$ENVIRONMENT" == "production"` is invalid, because the variable is quoted.
- `if: $ENVIRONMENT == production` is invalid, because the string is not quoted.
- `if: "production" == "production"` is invalid, because there is no CI/CD variable to compare.

## `get_sources` job section fails because of an HTTP/2 problem

Sometimes, jobs fail with the following cURL error:

```plaintext
++ git -c 'http.userAgent=gitlab-runner <version>' fetch origin +refs/pipelines/<id>:refs/pipelines/<id> ...
error: RPC failed; curl 16 HTTP/2 send again with decreased length
fatal: ...
```

You can work around this problem by configuring Git and `libcurl` to
[use HTTP/1.1](https://git-scm.com/docs/git-config#Documentation/git-config.txt-httpversion).
The configuration can be added to:

- A job's [`pre_get_sources_script`](../yaml/_index.md#hookspre_get_sources_script):

  ```yaml
  job_name:
    hooks:
      pre_get_sources_script:
        - git config --global http.version "HTTP/1.1"
  ```

- The [runner's `config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)
  with [Git configuration environment variables](https://git-scm.com/docs/git-config#ENVIRONMENT):

  ```toml
  [[runners]]
  ...
  environment = [
    "GIT_CONFIG_COUNT=1",
    "GIT_CONFIG_KEY_0=http.version",
    "GIT_CONFIG_VALUE_0=HTTP/1.1"
  ]
  ```

## Job using `resource_group` gets stuck

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

If a job using [`resource_group`](../yaml/_index.md#resource_group) gets stuck, a
GitLab administrator can try run the following commands from the [rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session):

```ruby
# find resource group by name
resource_group = Project.find_by_full_path('...').resource_groups.find_by(key: 'the-group-name')
busy_resources = resource_group.resources.where('build_id IS NOT NULL')

# identify which builds are occupying the resource
# (I think it should be 1 as of today)
busy_resources.pluck(:build_id)

# it's good to check why this build is holding the resource.
# Is it stuck? Has it been forcefully dropped by the system?
# free up busy resources
busy_resources.update_all(build_id: nil)
```

## `You are not authorized to run this manual job` message

You can receive this message and have a disabled **Run** button when trying to run a manual job if:

- The target environment is a [protected environment](../environments/protected_environments.md)
  and your account is not included in the **Allowed to deploy** list.
- The setting to [prevent outdated deployment jobs](../environments/deployment_safety.md#prevent-outdated-deployment-jobs)
  is enabled and running the job would overwrite the latest deployment.
