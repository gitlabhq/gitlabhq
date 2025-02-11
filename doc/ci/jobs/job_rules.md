---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Specify when jobs run with `rules`
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use [`rules`](../yaml/_index.md#rules) to include or exclude jobs in pipelines.

Rules are evaluated in order until the first match. When a match is found, the job
is either included or excluded from the pipeline, depending on the configuration.

You cannot use dotenv variables created in job scripts in rules, because rules are evaluated before any jobs run.

Future keyword improvements are being discussed in our [epic for improving `rules`](https://gitlab.com/groups/gitlab-org/-/epics/2783),
where anyone can add suggestions or requests.

## `rules` examples

The following example uses `if` to define that the job runs in only two specific cases:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
      allow_failure: true
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

- If the pipeline is for a merge request, the first rule matches, and the job
  is added to the [merge request pipeline](../pipelines/merge_request_pipelines.md)
  with attributes of:
  - `when: manual` (manual job)
  - `allow_failure: true` (the pipeline continues running even if the manual job is not run)
- If the pipeline is **not** for a merge request, the first rule doesn't match, and the
  second rule is evaluated.
- If the pipeline is a scheduled pipeline, the second rule matches, and the job
  is added to the scheduled pipeline. No attributes were defined, so it is added
  with:
  - `when: on_success` (default)
  - `allow_failure: false` (default)
- In **all other cases**, no rules match, so the job is **not** added to any other pipeline.

Alternatively, you can define a set of rules to exclude jobs in a few cases, but
run them in all other cases:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: never
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - when: on_success
```

- If the pipeline is for a merge request, the job is **not** added to the pipeline.
- If the pipeline is a scheduled pipeline, the job is **not** added to the pipeline.
- In **all other cases**, the job is added to the pipeline, with `when: on_success`.

WARNING:
If you use a `when` clause as the final rule (not including `when: never`), two
simultaneous pipelines may start. Both push pipelines and merge request pipelines can
be triggered by the same event (a push to the source branch for an open merge request).
See how to [prevent duplicate pipelines](#avoid-duplicate-pipelines)
for more details.

### Run jobs for scheduled pipelines

You can configure a job to be executed only when the pipeline has been
scheduled. For example:

```yaml
job:on-schedule:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
  script:
    - make world

job:
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
  script:
    - make build
```

In this example, `make world` runs in scheduled pipelines, and `make build`
runs in branch and tag pipelines.

### Skip jobs if the branch is empty

Use [`rules:changes:compare_to`](../yaml/_index.md#ruleschangescompare_to) to
skip a job when the branch is empty, which saves CI/CD resources. The configuration compares the
branch to the default branch, and if the branch:

- Doesn't have changed files, the job doesn't run.
- Has changed files, the job runs.

For example, in a project with `main` as the default branch:

```yaml
job:
  script:
    - echo "This job only runs for branches that are not empty"
  rules:
    - if: $CI_COMMIT_BRANCH
      changes:
        compare_to: 'refs/heads/main'
        paths:
          - '**/*'
```

The rule for this job compares all files and paths in the current branch
recursively (`**/*`) against the `main` branch. The rule matches and the
job runs only when there are changes to the files in the branch.

## Common `if` clauses with predefined variables

`rules:if` clauses are commonly used with [predefined CI/CD variables](../variables/predefined_variables.md),
especially the [`CI_PIPELINE_SOURCE` predefined variable](#ci_pipeline_source-predefined-variable).

The following example runs the job as a manual job in scheduled pipelines or in push
pipelines (to branches or tags), with `when: on_success` (default). It does not
add the job to any other pipeline type.

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: manual
      allow_failure: true
    - if: $CI_PIPELINE_SOURCE == "push"
```

The following example runs the job as a `when: on_success` job in [merge request pipelines](../pipelines/merge_request_pipelines.md)
and scheduled pipelines. It does not run in any other pipeline type.

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

Other commonly used `if` clauses:

- `if: $CI_COMMIT_TAG`: If changes are pushed for a tag.
- `if: $CI_COMMIT_BRANCH`: If changes are pushed to any branch.
- `if: $CI_COMMIT_BRANCH == "main"`: If changes are pushed to `main`.
- `if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH`: If changes are pushed to the default
  branch. Use when you want to have the same configuration in multiple
  projects with different default branches.
- `if: $CI_COMMIT_BRANCH =~ /regex-expression/`: If the commit branch matches a regular expression.
- `if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH && $CI_COMMIT_TITLE =~ /Merge branch.*/`:
  If the commit branch is the default branch and the commit message title matches a regular expression.
  For example, the default commit message for a merge commit starts with `Merge branch`.
- `if: $CUSTOM_VARIABLE == "value1"`: If the custom variable `CUSTOM_VARIABLE` is
  exactly `value1`.

### Run jobs only in specific pipeline types

You can use [predefined CI/CD variables](../variables/predefined_variables.md) with
[`rules`](../yaml/_index.md#rules) to choose which pipeline types jobs should run for.

The following table lists some of the variables that you can use, and the pipeline
types the variables can control for:

- Branch pipelines that run for Git `push` events to a branch, like new commits or tags.
- Tag pipelines that run only when a new Git tag is pushed to a branch.
- [Merge request pipelines](../pipelines/merge_request_pipelines.md) that run for changes
  to a merge request, like new commits or selecting **Run pipeline**
  in a merge request's pipelines tab.
- [Scheduled pipelines](../pipelines/schedules.md).

| Variables                                  | Branch | Tag | Merge request | Scheduled |
|--------------------------------------------|--------|-----|---------------|-----------|
| `CI_COMMIT_BRANCH`                         | Yes    |     |               | Yes       |
| `CI_COMMIT_TAG`                            |        | Yes |               | Yes, if the scheduled pipeline is configured to run on a tag. |
| `CI_PIPELINE_SOURCE = push`                | Yes    | Yes |               |           |
| `CI_PIPELINE_SOURCE = schedule`            |        |     |               | Yes       |
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
    - if: $CI_PIPELINE_SOURCE == "schedule"
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
```

### `CI_PIPELINE_SOURCE` predefined variable

Use the `CI_PIPELINE_SOURCE` variable to control when to add jobs for these pipeline types:

| Value                           | Description |
|---------------------------------|-------------|
| `api`                           | For pipelines triggered by the [pipelines API](../../api/pipelines.md#create-a-new-pipeline). |
| `chat`                          | For pipelines created by using a [GitLab ChatOps](../chatops/_index.md) command. |
| `external`                      | When you use CI services other than GitLab. |
| `external_pull_request_event`   | When an [external pull request on GitHub](../ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests) is created or updated. |
| `merge_request_event`           | For pipelines created when a merge request is created or updated. Required to enable [merge request pipelines](../pipelines/merge_request_pipelines.md), [merged results pipelines](../pipelines/merged_results_pipelines.md), and [merge trains](../pipelines/merge_trains.md). |
| `ondemand_dast_scan`            | For [DAST on-demand scan](../../user/application_security/dast/on-demand_scan.md) pipelines. |
| `ondemand_dast_validation`      | For [DAST on-demand validation](../../user/application_security/dast/on-demand_scan.md#site-profile-validation) pipelines |
| `parent_pipeline`               | For pipelines triggered by a [parent/child pipeline](../pipelines/downstream_pipelines.md#parent-child-pipelines). Use this pipeline source in the child pipeline configuration so that it can be triggered by the parent pipeline. |
| `pipeline`                      | For [multi-project pipelines](../pipelines/downstream_pipelines.md#multi-project-pipelines) created by [using the API with `CI_JOB_TOKEN`](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api), or the [`trigger`](../yaml/_index.md#trigger) keyword. |
| `push`                          | For pipelines triggered by a Git push event, including for branches and tags. |
| `schedule`                      | For [scheduled pipelines](../pipelines/schedules.md). |
| `security_orchestration_policy` | For [security orchestration policy](../../user/application_security/policies/_index.md) pipelines. |
| `trigger`                       | For pipelines created by using a [trigger token](../triggers/_index.md#configure-cicd-jobs-to-run-in-triggered-pipelines). |
| `web`                           | For pipelines created by selecting **New pipeline** in the GitLab UI, from the project's **Build > Pipelines** section. |
| `webide`                        | For pipelines created by using the [Web IDE](../../user/project/web_ide/_index.md). |

These values are the same as returned for the `source` parameter when using the
[pipelines API endpoint](../../api/pipelines.md#list-project-pipelines).

## Complex rules

You can use all `rules` keywords, like `if`, `changes`, and `exists`, in the same
rule. The rule evaluates to true only when all included keywords evaluate to true.

For example:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $VAR == "string value"
      changes:  # Include the job and set to when:manual if any of the follow paths match a modified file.
        - Dockerfile
        - docker/scripts/**/*
      when: manual
      allow_failure: true
```

If the `Dockerfile` file or any file in `/docker/scripts` has changed **and** `$VAR` == "string value",
then the job runs manually and is allowed to fail.

You can use [parentheses](#join-variable-expressions-together) with `&&` and `||` to build more complicated variable expressions.

```yaml
job1:
  script:
    - echo This rule uses parentheses.
  rules:
    - if: ($CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH || $CI_COMMIT_BRANCH == "develop") && $MY_VARIABLE
```

## Avoid duplicate pipelines

If a job uses `rules`, a single action, like pushing a commit to a branch, can trigger
multiple pipelines. You don't have to explicitly configure rules for multiple types
of pipeline to trigger them accidentally.

Some configurations that have the potential to cause duplicate pipelines cause a
[pipeline warning](../debugging.md#pipeline-warnings) to be displayed.

For example:

```yaml
job:
  script: echo "This job creates double pipelines!"
  rules:
    - if: $CUSTOM_VARIABLE == "false"
      when: never
    - when: always
```

This job does not run when `$CUSTOM_VARIABLE` is false, but it *does* run in **all**
other pipelines, including **both** push (branch) and merge request pipelines. With
this configuration, every push to an open merge request's source branch
causes duplicated pipelines.

To avoid duplicate pipelines, you can:

- Use [`workflow`](../yaml/_index.md#workflow) to specify which types of pipelines
  can run.
- Rewrite the rules to run the job only in very specific cases,
  and avoid a final `when` rule:

  ```yaml
  job:
    script: echo "This job does NOT create double pipelines!"
    rules:
      - if: $CUSTOM_VARIABLE == "true" && $CI_PIPELINE_SOURCE == "merge_request_event"
  ```

You can also avoid duplicate pipelines by changing the job rules to avoid either push (branch)
pipelines or merge request pipelines. However, if you use a `- when: always` rule without
`workflow: rules`, GitLab still displays a [pipeline warning](../debugging.md#pipeline-warnings).

For example, the following does not trigger double pipelines, but is not recommended
without `workflow: rules`:

```yaml
job:
  script: echo "This job does NOT create double pipelines!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always
```

You should not include both push and merge request pipelines in the same job without
[`workflow:rules` that prevent duplicate pipelines](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines):

```yaml
job:
  script: echo "This job creates double pipelines!"
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

Also, do not mix `only/except` jobs with `rules` jobs in the same pipeline.
It may not cause YAML errors, but the different default behaviors of `only/except`
and `rules` can cause issues that are difficult to troubleshoot:

```yaml
job-with-no-rules:
  script: echo "This job runs in branch pipelines."

job-with-rules:
  script: echo "This job runs in merge request pipelines."
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

For every change pushed to the branch, duplicate pipelines run. One
branch pipeline runs a single job (`job-with-no-rules`), and one merge request pipeline
runs the other job (`job-with-rules`). Jobs with no rules default
to [`except: merge_requests`](../yaml/_index.md#only--except), so `job-with-no-rules`
runs in all cases except merge requests.

## Reuse rules in different jobs

Use [`!reference` tags](../yaml/yaml_optimization.md#reference-tags) to reuse rules in different
jobs. You can combine `!reference` rules with regular job-defined rules. For example:

```yaml
.default_rules:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
      when: never
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

job1:
  rules:
    - !reference [.default_rules, rules]
  script:
    - echo "This job runs for the default branch, but not schedules."

job2:
  rules:
    - !reference [.default_rules, rules]
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - echo "This job runs for the default branch, but not schedules."
    - echo "It also runs for merge requests."
```

## CI/CD variable expressions

Use variable expressions with [`rules:if`](../yaml/_index.md#rules) to control
when jobs should be added to a pipeline.

You can use the equality operators `==` and `!=` to compare a variable with a
string. Both single quotes and double quotes are valid. The variable has to be on the left side of the comparison. For example:

- `if: $VARIABLE == "some value"`
- `if: $VARIABLE != "some value"`

You can compare the values of two variables. For example:

- `if: $VARIABLE_1 == $VARIABLE_2`
- `if: $VARIABLE_1 != $VARIABLE_2`

You can compare a variable to the `null` keyword to see if it is defined. For example:

- `if: $VARIABLE == null`
- `if: $VARIABLE != null`

You can check if a variable is defined but empty. For example:

- `if: $VARIABLE == ""`
- `if: $VARIABLE != ""`

You can check if a variable is both defined and not empty by using just the variable name in
the expression. For example:

- `if: $VARIABLE`

### Compare a variable to a regular expression

You can do regular expression matching on variable values with the `=~` and `!~` operators.
Variable pattern matching with regular expressions uses the
[RE2 regular expression syntax](https://github.com/google/re2/wiki/Syntax).

Expressions evaluate as `true` if:

- Matches are found when using `=~`.
- Matches are *not* found when using `!~`.

For example:

- `if: $VARIABLE =~ /^content.*/`
- `if: $VARIABLE !~ /^content.*/`

Additionally:

- Single-character regular expressions, like `/./`, are not supported and
  produce an `invalid expression syntax` error.
- Pattern matching is case-sensitive by default. Use the `i` flag modifier to make a
  pattern case-insensitive. For example: `/pattern/i`.
- Only the tag or branch name can be matched by a regular expression.
  The repository path, if given, is always matched literally.
- The entire pattern must be surrounded by `/`. For example, you can't use `issue-/.*/`
  to match all tag names or branch names that begin with `issue-`, but you can use `/issue-.*/`.
- The `@` symbol denotes the beginning of a ref's repository path.
  To match a ref name that contains the `@` character in a regular expression,
  you must use the hex character code match `\x40`.
- Use anchors `^` and `$` to avoid the regular expression matching only a substring
  of the tag name or branch name. For example, `/^issue-.*$/` is equivalent to `/^issue-/`,
  while just `/issue/` would also match a branch called `severe-issues`.

### Store a regular expression in a variable

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/35438) in GitLab 15.0 [with a flag](../../administration/feature_flags.md) named `ci_fix_rules_if_comparison_with_regexp_variable`, disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/359740) and feature flag `ci_fix_rules_if_comparison_with_regexp_variable` removed in GitLab 15.1.

Variables on the right side of `=~` and `!~` expressions are evaluated as regular expressions.
The regular expression must be enclosed in forward slashes (`/`). For example:

```yaml
variables:
  pattern: '/^ab.*/'

regex-job1:
  variables:
    teststring: 'abcde'
  script: echo "This job will run, because 'abcde' matches the /^ab.*/ pattern."
  rules:
    - if: '$teststring =~ $pattern'

regex-job2:
  variables:
    teststring: 'fghij'
  script: echo "This job will not run, because 'fghi' does not match the /^ab.*/ pattern."
  rules:
    - if: '$teststring =~ $pattern'
```

Variables in a regular expression are **not resolved**. For example:

```yaml
variables:
  string1: 'regex-job1'
  string2: 'regex-job2'
  pattern: '/$string2/'

regex-job1:
  script: echo "This job will NOT run, because the 'string1' variable inside the regex pattern is not resolved."
  rules:
    - if: '$CI_JOB_NAME =~ /$string1/'

regex-job2:
  script: echo "This job will NOT run, because the 'string2' variable inside the 'pattern' variable is not resolved."
  rules:
    - if: '$CI_JOB_NAME =~ $pattern'
```

### Join variable expressions together

You can join multiple expressions using `&&` (and) or `||` (or), for example:

- `$VARIABLE1 =~ /^content.*/ && $VARIABLE2 == "something"`
- `$VARIABLE1 =~ /^content.*/ && $VARIABLE2 =~ /thing$/ && $VARIABLE3`
- `$VARIABLE1 =~ /^content.*/ || $VARIABLE2 =~ /thing$/ && $VARIABLE3`

The precedence of operators follows the [Ruby 2.5 standard](https://ruby-doc.org/core-2.5.0/doc/syntax/precedence_rdoc.html),
so `&&` evaluates before `||`.

You can use parentheses to group expressions together. Parentheses take precedence over
`&&` and `||`, so expressions enclosed in parentheses evaluate first, and the
result is used for the rest of the expression.

Nest parentheses to create complex conditions, and the inner-most expressions
in parentheses evaluate first. For example:

- `($VARIABLE1 =~ /^content.*/ || $VARIABLE2) && ($VARIABLE3 =~ /thing$/ || $VARIABLE4)`
- `($VARIABLE1 =~ /^content.*/ || $VARIABLE2 =~ /thing$/) && $VARIABLE3`
- `$CI_COMMIT_BRANCH == "my-branch" || (($VARIABLE1 == "thing" || $VARIABLE2 == "thing") && $VARIABLE3)`

## Troubleshooting

### Unexpected behavior from regular expression matching with `=~`

When using the `=~` character, make sure the right side of the comparison always contains
a valid regular expression.

If the right side of the comparison is not a valid regular expression enclosed with `/` characters,
the expression evaluates in an unexpected way. In that case, the comparison checks
if the left side is a substring of the right side. For example, `"23" =~ "1234"` evaluates to true,
which is the opposite of `"23" =~ /1234/`, which evaluates to false.

You should not configure your pipeline to rely on this behavior.
