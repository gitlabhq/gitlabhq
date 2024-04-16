---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "When you push commits from the command line, use push rules to pass CI/CD variables and set values for merge request fields."
---

# Push options

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

When you push changes to a branch, you can use client-side
[Git push options](https://git-scm.com/docs/git-push#Documentation/git-push.txt--oltoptiongt).
In Git 2.10 and later, use Git push options to:

- [Skip CI jobs](#push-options-for-gitlab-cicd)
- [Push to merge requests](#push-options-for-merge-requests)

In Git 2.18 and later, you can use either the long format (`--push-option`) or the shorter `-o`:

```shell
git push -o <push_option>
```

In Git 2.10 to 2.17, you must use the long format:

```shell
git push --push-option=<push_option>
```

For server-side controls and enforcement of best practices, see
[push rules](repository/push_rules.md) and [server hooks](../../administration/server_hooks.md).

## Push options for GitLab CI/CD

You can use push options to skip a CI/CD pipeline, or pass CI/CD variables.

NOTE:
Push options are not available for merge request pipelines. For more information,
see [issue 373212](https://gitlab.com/gitlab-org/gitlab/-/issues/373212).

| Push option                    | Description | Example |
|--------------------------------|-------------|---------|
| `ci.skip`                      | Do not create a CI/CD pipeline for the latest push. Skips only branch pipelines and not [merge request pipelines](../../ci/pipelines/merge_request_pipelines.md). This does not skip pipelines for CI/CD integrations, such as Jenkins. | `git push -o ci.skip` |
| `ci.variable="<name>=<value>"` | Provide [CI/CD variables](../../ci/variables/index.md) to the CI/CD pipeline, if one is created due to the push. Passes variables only to branch pipelines and not [merge request pipelines](../../ci/pipelines/merge_request_pipelines.md). | `git push -o ci.variable="MAX_RETRIES=10" -o ci.variable="MAX_TIME=600"` |
| `integrations.skip_ci`         | Skip push events for CI/CD integrations, such as Atlassian Bamboo, Buildkite, Drone, Jenkins, and JetBrains TeamCity. Introduced in [GitLab 16.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123837). | `git push -o integrations.skip_ci` |

## Push options for merge requests

Git push options can perform actions for merge requests while pushing changes:

| Push option                                  | Description |
|----------------------------------------------|-------------|
| `merge_request.create`                       | Create a new merge request for the pushed branch. |
| `merge_request.target=<branch_name>`         | Set the target of the merge request to a particular branch, such as: `git push -o merge_request.target=branch_name`. |
| `merge_request.target_project=<project>`     | Set the target of the merge request to a particular upstream project, such as: `git push -o merge_request.target_project=path/to/project`. Introduced in [GitLab 16.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132475). |
| `merge_request.merge_when_pipeline_succeeds` | Set the merge request to [merge when its pipeline succeeds](merge_requests/merge_when_pipeline_succeeds.md). |
| `merge_request.remove_source_branch`         | Set the merge request to remove the source branch when it's merged. |
| `merge_request.title="<title>"`              | Set the title of the merge request. For example: `git push -o merge_request.title="The title I want"`. |
| `merge_request.description="<description>"`  | Set the description of the merge request. For example: `git push -o merge_request.description="The description I want"`. |
| `merge_request.draft`                        | Mark the merge request as a draft. For example: `git push -o merge_request.draft`. Introduced in [GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/296673). |
| `merge_request.milestone="<milestone>"`      | Set the milestone of the merge request. For example: `git push -o merge_request.milestone="3.0"`. Introduced in [GitLab 14.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63960). |
| `merge_request.label="<label>"`              | Add labels to the merge request. If the label does not exist, it is created. For example, for two labels: `git push -o merge_request.label="label1" -o merge_request.label="label2"`. |
| `merge_request.unlabel="<label>"`            | Remove labels from the merge request. For example, for two labels: `git push -o merge_request.unlabel="label1" -o merge_request.unlabel="label2"`. |
| `merge_request.assign="<user>"`              | Assign users to the merge request. Accepts username or user ID. For example, for two users: `git push -o merge_request.assign="user1" -o merge_request.assign="user2"`. Support for usernames added in [GitLab 15.5](https://gitlab.com/gitlab-org/gitlab/-/issues/344276). |
| `merge_request.unassign="<user>"`            | Remove assigned users from the merge request. Accepts username or user ID. For example, for two users: `git push -o merge_request.unassign="user1" -o merge_request.unassign="user2"`. Support for usernames added in [GitLab 15.5](https://gitlab.com/gitlab-org/gitlab/-/issues/344276). |

## Formats for push options

If your push option requires text containing spaces, enclose the text in
double quotes (`"`). You can omit the quotes if there are no spaces. Some examples:

```shell
git push -o merge_request.label="Label with spaces"
git push -o merge_request.label=Label-with-no-spaces
```

To combine push options to accomplish multiple tasks at once, use
multiple `-o` (or `--push-option`) flags. This command creates a
new merge request, targets a branch (`my-target-branch`), and sets auto-merge:

```shell
git push -o merge_request.create -o merge_request.target=my-target-branch -o merge_request.merge_when_pipeline_succeeds
```

## Create Git aliases for common commands

Adding push options to Git commands can create very long commands. If
you use the same push options frequently, create Git aliases for them.
Git aliases are command-line shortcuts for longer Git commands.

To create and use a Git alias for the
[merge when pipeline succeeds Git push option](#push-options-for-merge-requests):

1. In your terminal window, run this command:

   ```shell
   git config --global alias.mwps "push -o merge_request.create -o merge_request.target=main -o merge_request.merge_when_pipeline_succeeds"
   ```

1. To use the alias to push a local branch that targets the default branch (`main`)
   and auto-merges, run this command:

   ```shell
   git mwps origin <local-branch-name>
   ```

## Related topics

- [Git aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases) in the Git documentation
