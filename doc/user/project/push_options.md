---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, howto
---

# Push Options **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/15643) in GitLab 11.7.

GitLab supports using client-side [Git push options](https://git-scm.com/docs/git-push#Documentation/git-push.txt--oltoptiongt)
to perform various actions at the same time as pushing changes. Additionally, [Push Rules](../../push_rules/push_rules.md) offer server-side control and enforcement options.

Currently, there are push options available for:

- [Skipping CI jobs](#push-options-for-gitlab-cicd)
- [Merge requests](#push-options-for-merge-requests)

NOTE:
Git push options are only available with Git 2.10 or newer.

For Git versions 2.10 to 2.17 use `--push-option`:

```shell
git push --push-option=<push_option>
```

For version 2.18 and later, you can use the above format, or the shorter `-o`:

```shell
git push -o <push_option>
```

## Push options for GitLab CI/CD

You can use push options to skip a CI/CD pipeline, or pass CI/CD variables.

| Push option                    | Description                                                                                 | Introduced in version |
| ------------------------------ | ------------------------------------------------------------------------------------------- |---------------------- |
| `ci.skip`                      | Do not create a CI pipeline for the latest push.                                            | [11.7](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/15643) |
| `ci.variable="<name>=<value>"` | Provide [CI/CD variables](../../ci/variables/index.md) to be used in a CI pipeline, if one is created due to the push. | [12.6](https://gitlab.com/gitlab-org/gitlab/-/issues/27983) |

An example of using `ci.skip`:

```shell
git push -o ci.skip
```

An example of passing some CI/CD variables for a pipeline:

```shell
git push -o ci.variable="MAX_RETRIES=10" -o ci.variable="MAX_TIME=600"
```

## Push options for merge requests

You can use Git push options to perform certain actions for merge requests at the same
time as pushing changes:

| Push option                                  | Description                                                                                                     | Introduced in version |
| -------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | --------------------- |
| `merge_request.create`                       | Create a new merge request for the pushed branch.                                                               | [11.10](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/26752) |
| `merge_request.target=<branch_name>`         | Set the target of the merge request to a particular branch.                                                     | [11.10](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/26752) |
| `merge_request.merge_when_pipeline_succeeds` | Set the merge request to [merge when its pipeline succeeds](merge_requests/merge_when_pipeline_succeeds.md).    | [11.10](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/26752) |
| `merge_request.remove_source_branch`         | Set the merge request to remove the source branch when it's merged.                                             | [12.2](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/64320)          |
| `merge_request.title="<title>"`              | Set the title of the merge request. Ex: `git push -o merge_request.title="The title I want"`.                   | [12.2](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/64320)          |
| `merge_request.description="<description>"`  | Set the description of the merge request. Ex: `git push -o merge_request.description="The description I want"`. | [12.2](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/64320)          |
| `merge_request.milestone="<milestone>"`      | Set the milestone of the merge request. Ex: `git push -o merge_request.milestone="3.0"`.                        | [14.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63960)       |
| `merge_request.label="<label>"`              | Add labels to the merge request. If the label does not exist, it is created. For example, for two labels: `git push -o merge_request.label="label1" -o merge_request.label="label2"`. | [12.3](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/31831) |
| `merge_request.unlabel="<label>"`            | Remove labels from the merge request. For example, for two labels: `git push -o merge_request.unlabel="label1" -o merge_request.unlabel="label2"`. | [12.3](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/31831) |
| `merge_request.assign="<user>"`              | Assign users to the merge request. For example, for two users: `git push -o merge_request.assign="user1" -o merge_request.assign="user2"`. | [13.10](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25904) |
| `merge_request.unassign="<user>"`            | Remove assigned users from the merge request. For example, for two users: `git push -o merge_request.unassign="user1" -o merge_request.unassign="user2"`. | [13.10](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25904) |

If you use a push option that requires text with spaces in it, you need to enclose it
in quotes (`"`). You can omit the quotes if there are no spaces. Some examples:

```shell
git push -o merge_request.label="Label with spaces"
git push -o merge_request.label=Label-with-no-spaces
```

You can combine push options to accomplish multiple tasks at once, by using
multiple `-o` (or `--push-option`) flags. For example, if you want to create a new
merge request, and target a branch named `my-target-branch`:

```shell
git push -o merge_request.create -o merge_request.target=my-target-branch
```

Additionally if you want the merge request to merge as soon as the pipeline succeeds you can do:

```shell
git push -o merge_request.create -o merge_request.target=my-target-branch -o merge_request.merge_when_pipeline_succeeds
```

## Useful Git aliases

As shown above, Git push options can cause Git commands to grow very long. If
you use the same push options frequently, it's useful to create [Git
aliases](https://git-scm.com/book/en/v2/Git-Basics-Git-Aliases). Git aliases
are command line shortcuts for Git which can significantly simplify the use of
long Git commands.

### Merge when pipeline succeeds alias

To set up a Git alias for the [merge when pipeline succeeds Git push
option](#push-options-for-merge-requests):

```shell
git config --global alias.mwps "push -o merge_request.create -o merge_request.target=master -o merge_request.merge_when_pipeline_succeeds"
```

Then to quickly push a local branch that targets the default branch and merges when the
pipeline succeeds:

```shell
git mwps origin <local-branch-name>
```
