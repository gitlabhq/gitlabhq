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

In GitLab 16.0 we introduced a new runner creation workflow,
the previous workflow that uses registration tokens is deprecated
and will be removed in GitLab 17.0.

For more information about the implementation for the new workflow, see the:

- [Next GitLab Runner Token Architecture](../../architecture/blueprints/runner_tokens/index.md) for information about the technical design and reasons for the new token architecture.
- [Development epic](https://gitlab.com/groups/gitlab-org/-/epics/7663) for the most accurate information about the current development status.

## Feedback

If you experience problems with the new runner registration workflow,
and the following information is not sufficient,
or if you have concerns about it,
you can reach out to us in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387993).

## Will my runner registration workflow break?

If no action is taken before your GitLab instance is upgraded to 16.6, then your runner registration
workflow will break.
Until then, both the new and the old workflow will coexist side-by-side.

To avoid a broken workflow, you must:

1. [Create a shared runner](register_runner.md#for-a-shared-runner) and obtain the authentication token.
1. Replace the registration token in your runner registration workflow with the
authentication token.

## Can I use the old runner registration process after 16.6?

- On GitLab.com, you'll be able to manually re-enable the previous runner registration process in the top-level group settings until GitLab 16.8.
- On GitLab self-managed, you'll be able manually re-enable the previous runner registration process in the Admin Area settings until GitLab 17.0.

## What is the new runner registration process?

When the new runner registration process is introduced, you will:

1. Create a runner directly in the GitLab UI.
1. Receive an authentication token in return.
1. Use the authentication token instead of the registration token, whenever you need to register a runner with this
   configuration. Runner managers registered in multiple hosts will appear under the same runner in the GitLab UI,
   but with an identifying system ID.

This has added benefits such as preserved ownership records for runners, and minimizes
impact on users.
The addition of a unique system ID ensures that you can reuse the same authentication token across
multiple runners.
For example, in an auto-scaling scenario where a runner manager spawns a runner process with a
fixed authentication token.
This ID generates once at the runner's startup, persists in a sidecar file, and is sent to the
GitLab instance when requesting jobs.
This allows the GitLab instance to display which system executed a given job.

## What is the estimated timeframe for the planned changes?

- In GitLab 15.10, we plan to implement runner creation directly in the runners administration page,
  and prepare the runner to follow the new workflow.
- In GitLab 16.6, we plan to disable registration tokens.
- In GitLab 17.0, we plan to completely remove support for runner registration tokens.

## How will the `gitlab-runner register` command syntax change?

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

In GitLab 16.0, the runner will be created in the UI where some of its attributes can be
pre-configured by the creator.
Examples are the tag list, locked status, or access level. These are no longer accepted as arguments
to `register`. The following example shows the new command:

```shell
gitlab-runner register
    --non-interactive \
    --executor "shell" \
    --url "https://gitlab.com/" \
    --token "glrt-2CR8_eVxiioB1QmzPZwa"
```

## How does this change impact auto-scaling scenarios?

In auto-scaling scenarios such as GitLab Runner Operator or GitLab Runner Helm Chart, the
registration token is replaced with the authentication token generated from the UI.
This means that the same runner configuration is reused across jobs, instead of creating a runner
for each job.
The specific runner can be identified by the unique system ID that is generated when the runner
process is started.

## Will existing runners continue to work?

Yes, existing runners will continue to work as usual. This change only affects registration of new runners.

## Can runners still be created programmatically?

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
