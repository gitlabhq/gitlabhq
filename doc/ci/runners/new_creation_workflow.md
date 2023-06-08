---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Migrating to the new runner registration workflow **(FREE)**

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
As with all projects, the items mentioned on this page are subject to change or delay.
The development, release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.

In GitLab 16.0, we introduced a new runner creation workflow that uses authentication tokens to register
runners. The legacy workflow that uses registration tokens is deprecated and will be removed in GitLab 17.0.

For information about the current development status of the new workflow, see [epic 7663](https://gitlab.com/groups/gitlab-org/-/epics/7663).

For information about the technical design and reasons for the new architecture, see [Next GitLab Runner Token Architecture](../../architecture/blueprints/runner_tokens/index.md).

## Feedback

If you experience problems or have concerns about the new runner registration workflow,
or if the following information is not sufficient,
you can let us know in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387993).

## The new runner registration workflow

For the new runner registration workflow, you:

1. [Create a runner](register_runner.md) directly in the GitLab UI.
1. Receive an authentication token.
1. Use the authentication token instead of the registration token when you register
   a runner with this configuration. Runner managers registered in multiple hosts appear
   under the same runner in the GitLab UI, but with an identifying system ID.

The new runner registration workflow has the following benefits:

- Preserved ownership records for runners, and minimized impact on users.
- The addition of a unique system ID ensures that you can reuse the same authentication token across
multiple runners. For more information, see [Reusing a GitLab Runner configuration](https://docs.gitlab.com/runner/fleet_scaling/#reusing-a-gitlab-runner-configuration).

## Estimated time frame for planned changes

- In GitLab 15.10 and later, you can use the new runner registration workflow.
- In GitLab 16.6, we plan to disable registration tokens.
- In GitLab 17.0, we plan to completely remove support for runner registration tokens.

## Prevent your runner registration workflow from breaking

Until GitLab 16.6, you can still use the legacy runner registration workflow.

In GitLab 16.6, the legacy runner registration workflow will be disabled automatically. You will be able to manually re-enable the legacy runner registration workflow for a limited time. For more information, see
[Using registration tokens after GitLab 16.6](#using-registration-tokens-after-gitlab-166).

If no action is taken before your GitLab instance is upgraded to GitLab 16.6, then your runner registration
workflow will break.

To avoid a broken workflow, you must:

1. [Create a shared runner](register_runner.md#for-a-shared-runner) and obtain the authentication token.
1. Replace the registration token in your runner registration workflow with the
authentication token.

## Using registration tokens after GitLab 16.6

To continue using registration tokens after GitLab 16.6:

- On GitLab.com, you can manually re-enable the legacy runner registration process in the top-level group settings until GitLab 16.8.
- On GitLab self-managed, you can manually re-enable the legacy runner registration process in the Admin Area settings until GitLab 17.0.

Plans to implement a UI setting to re-enable registration tokens are proposed in [issue 411923](https://gitlab.com/gitlab-org/gitlab/-/issues/411923)

## Changes to the `gitlab-runner register` command syntax

The `gitlab-runner register` command will stop accepting registration tokens and instead accept new
authentication tokens generated in the GitLab runners administration page.
These authentication tokens are recognizable by their `glrt-` prefix.

Example command for GitLab 15.9:

```shell
gitlab-runner register
    --non-interactive \
    --executor "shell" \
    --url "https://gitlab.com/" \
    --tag-list "shell,mac,gdk,test" \
    --run-untagged "false" \
    --locked "false" \
    --access-level "not_protected" \
    --registration-token "GR1348941C6YcZVddc8kjtdU-yWYD"
```

In GitLab 15.10 and later, you create the runner and some of the attributes in the UI, like the
tag list, locked status, and access level.
In GitLab 15.11 and later, these attributes are no longer accepted as arguments to `register`.

The following example shows the new command:

```shell
gitlab-runner register
    --non-interactive \
    --executor "shell" \
    --url "https://gitlab.com/" \
    --token "glrt-2CR8_eVxiioB1QmzPZwa"
```

## Impact on autoscaling

In autoscaling scenarios such as GitLab Runner Operator or GitLab Runner Helm Chart, the
registration token is replaced with the authentication token generated from the UI.
This means that the same runner configuration is reused across jobs, instead of creating a runner
for each job.
The specific runner can be identified by the unique system ID that is generated when the runner
process is started.

## Impact on existing runners

Existing runners will continue to work as usual. This change only affects registration of new runners.

## Creating runners programmatically

A new [POST /user/runners REST API](../../api/users.md#create-a-runner) was introduced in
GitLab 15.11, which allows a runner to be created in the context of an authenticated user. This should only be used in
scenarios where the runner configuration is dynamic, or not reusable. If the runner configuration is static, it is
preferable to reuse the authentication token of an existing runner.

The following snippet shows how a group runner could be created and registered with a
[Group Access Token](../../user/group/settings/group_access_tokens.md) using the new creation flow.
The process is very similar when using [Project Access Tokens](../../user/project/settings/project_access_tokens.md)
or [Personal Access Tokens](../../user/profile/personal_access_tokens.md):

```shell
# `GROUP_ID` contains the numerical ID of the group where the runner will be created
# `GITLAB_TOKEN` can be a Personal Access Token for a group owner, or a Group Access Token on the respective group
#   created with `owner` access and `api` scope.
#
# The output will be parsed by `jq` to extract the token of the newly created runner
RUNNER_TOKEN=$(curl --silent --method POST "https://gitlab.com/api/v4/user/runners" \
    --header "private-token: $GITLAB_TOKEN" \
    --header 'content-type: application/json' \
    --data "{\"runner_type\":\"group_type\",\"group_id\":\"$GROUP_ID\",\"description\":\"My runner\",\"tag-list\":\"java,linux\"}" \
  | jq -r '.token')

gitlab-runner register
    --non-interactive \
    --executor "shell" \
    --url "https://gitlab.com/" \
    --token "$RUNNER_TOKEN"
```
