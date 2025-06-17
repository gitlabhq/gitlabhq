---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrating to the new runner registration workflow
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< alert type="disclaimer" />}}

In GitLab 16.0, we introduced a new runner creation workflow that uses runner authentication tokens to register
runners. The legacy workflow that uses registration tokens is deprecated and is planned for removal in GitLab 20.0.
Use the [runner creation workflow](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token) instead.

For information about the current development status of the new workflow, see [epic 7663](https://gitlab.com/groups/gitlab-org/-/epics/7663).

For information about the technical design and reasons for the new architecture, see Next GitLab Runner Token Architecture.

If you experience problems or have concerns about the new runner registration workflow,
or need more information, let us know in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/387993).

## The new runner registration workflow

For the new runner registration workflow, you:

1. [Create a runner](runners_scope.md) directly in the GitLab UI or [programmatically](#creating-runners-programmatically).
1. Receive a runner authentication token.
1. Use the runner authentication token instead of the registration token when you register
   a runner with this configuration. Runner managers registered in multiple hosts appear
   under the same runner in the GitLab UI, but with an identifying system ID.

The new runner registration workflow has the following benefits:

- Preserved ownership records for runners, and minimized impact on users.
- The addition of a unique system ID ensures that you can reuse the same authentication token across
  multiple runners. For more information, see [Reusing a GitLab Runner configuration](https://docs.gitlab.com/runner/fleet_scaling/#reusing-a-gitlab-runner-configuration).

## Estimated time frame for planned changes

- In GitLab 15.10 and later, you can use the new runner registration workflow.
- In GitLab 20.0, we plan to disable runner registration tokens.

## Prevent your runner registration workflow from breaking

In GitLab 16.11 and earlier, you can use the legacy runner registration workflow.

In GitLab 17.0, the legacy runner registration workflow is disabled by default. You can temporarily re-enable the legacy runner registration workflow. For more information, see [Using registration tokens after GitLab 17.0](#using-registration-tokens-after-gitlab-170).

If you don't migrate to the new workflow when you upgrade to GitLab 17.0, the runner registration breaks and the `gitlab-runner register` command returns a `410 Gone - runner registration disallowed` error.

To avoid a broken workflow, you must:

1. [Create a runner](runners_scope.md) and obtain the authentication token.
1. Replace the registration token in your runner registration workflow with the
   authentication token.

{{< alert type="warning" >}}

In GitLab 17.0 and later, runner registration tokens are disabled.
To use stored runner registration tokens to register new runners,
you must [enable the tokens](../../administration/settings/continuous_integration.md#control-runner-registration).

{{< /alert >}}

## Using registration tokens after GitLab 17.0

To continue using registration tokens after GitLab 17.0:

- On GitLab.com, you can manually [enable the legacy runner registration process](runners_scope.md#enable-use-of-runner-registration-tokens-in-projects-and-groups)
  in the top-level group settings.
- On GitLab Self-Managed, you can manually [enable the legacy runner registration process](../../administration/settings/continuous_integration.md#control-runner-registration)
  in the **Admin** area settings.

## Impact on existing runners

Existing runners will continue to work as usual after upgrading to GitLab 17.0. This change only affects registration of new runners.

The [GitLab Runner Helm chart](https://docs.gitlab.com/runner/install/kubernetes.html) generates new runner pods every time a job is executed.
For these runners, [enable legacy runner registration](#using-registration-tokens-after-gitlab-170) to use registration tokens.
In GitLab 20.0 and later, you must migrate to the [new runner registration workflow](#the-new-runner-registration-workflow).

## Changes to the `gitlab-runner register` command syntax

The `gitlab-runner register` command accepts runner authentication tokens instead of registration tokens.
You can generate tokens from the **Runners** page in the **Admin** area.
The runner authentication tokens are recognizable by their `glrt-` prefix.

When you create a runner in the GitLab UI, you specify configuration values that were previously command-line options
prompted by the `gitlab-runner register` command.
These command-line options will be deprecated in the future.

If you specify a runner authentication token with:

- the `--token` command-line option, the `gitlab-runner register` command does not accept the configuration values.
- the `--registration-token` command-line option, the `gitlab-runner register` command ignores the configuration values.

| Token                                  | Registration command |
|----------------------------------------|----------------------|
| Runner authentication token            | `gitlab-runner register --token $RUNNER_AUTHENTICATION_TOKEN` |
| Runner registration token (deprecated) | `gitlab-runner register --registration-token $RUNNER_REGISTRATION_TOKEN <runner configuration arguments>` |

Authentication tokens have the prefix, `glrt-`.

To ensure minimal disruption to your automation workflow,
[legacy-compatible registration processing](https://docs.gitlab.com/runner/register/#legacy-compatible-registration-process)
triggers if a runner authentication token is specified in the legacy parameter `--registration-token`.

Example command for GitLab 15.9:

```shell
gitlab-runner register \
    --non-interactive \
    --executor "shell" \
    --url "https://gitlab.com/" \
    --tag-list "shell,mac,gdk,test" \
    --run-untagged "false" \
    --locked "false" \
    --access-level "not_protected" \
    --registration-token "REDACTED"
```

In GitLab 15.10 and later, you can create the runner and set attributes in the UI, like
tag list, locked status, and access level.
In GitLab 15.11 and later, these attributes are no longer accepted as arguments to `register` when a runner authentication token with the `glrt-` prefix is specified.

The following example shows the new command:

```shell
gitlab-runner register \
    --non-interactive \
    --executor "shell" \
    --url "https://gitlab.com/" \
    --token "REDACTED"
```

## Impact on autoscaling

In autoscaling scenarios such as GitLab Runner Operator or GitLab Runner Helm Chart, the
runner authentication token generated from the UI replaces the registration token.
This means that the same runner configuration is reused across jobs, instead of creating a runner
for each job.
The specific runner can be identified by the unique system ID that is generated when the runner
process is started.

## Creating runners programmatically

In GitLab 15.11 and later, you can use the [POST /user/runners REST API](../../api/users.md#create-a-runner-linked-to-a-user)
to create a runner as an authenticated user. This should only be used if the runner configuration is dynamic
or not reusable. If the runner configuration is static, you should reuse the runner authentication token of
an existing runner.

For instructions about how to automate runner creation and registration, see the tutorial,
[Automate runner creation and registration](../../tutorials/automate_runner_creation/_index.md).

## Installing GitLab Runner with Helm chart

Several runner configuration options cannot be set during runner registration. These options can only be configured:

- When you create a runner in the UI.
- With the `user/runners` REST API endpoint.

The following configuration options are no longer supported in [`values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/main/values.yaml):

```yaml
## All these fields are DEPRECATED and the runner WILL FAIL TO START with GitLab Runner 20.0 and later if you specify them.
## If a runner authentication token is specified in runnerRegistrationToken, the registration will succeed, however the
## other values will be ignored.
runnerRegistrationToken: ""
locked: true
tags: ""
maximumTimeout: ""
runUntagged: true
protected: true
```

For GitLab Runner on Kubernetes, Helm deploy passes the runner authentication token to the runner worker pod and creates the runner configuration.
In GitLab 17.0 and later, if you use the `runnerRegistrationToken` token field on Kubernetes hosted runners attached to GitLab.com, the runner worker pod tries to use the unsupported Registration API method during creation.

Replace the invalid `runnerRegistrationToken` field with the `runnerToken` field. You must also modify the runner authentication token stored in `secrets`.

In the legacy runner registration workflow, fields were specified with:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-runner-secret
type: Opaque
data:
  runner-registration-token: "REDACTED" # DEPRECATED, set to ""
  runner-token: ""
```

In the new runner registration workflow, you must use `runner-token` instead:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-runner-secret
type: Opaque
data:
  runner-registration-token: "" # need to leave as an empty string for compatibility reasons
  runner-token: "REDACTED"
```

{{< alert type="note" >}}

If your secret management solution doesn't allow you to set an empty string for `runner-registration-token`,
you can set it to any string. This value is ignored when `runner-token` is present.

{{< /alert >}}

## Known issues

### Pod name is not visible in runner details page

When you use the new registration workflow to register your runners with Helm chart, the pod name doesn't appear
on the runner details page.
For more information, see [issue 423523](https://gitlab.com/gitlab-org/gitlab/-/issues/423523).

### Runner authentication token does not update when rotated

#### Token rotation with the same runner registered in multiple runner managers

When you register runners on multiple host machines through the new workflow with
automatic token rotation, only the first runner manager receives the new token.
The remaining runner managers continue to use the invalid token and become disconnected.
You must update these managers manually to use the new token.

#### Token rotation in GitLab Operator

During runner registration with GitLab Operator through the new workflow,
the runner authentication token in the Custom Resource Definition doesn't update
during token rotation.
This occurs when:

- You're using a runner authentication token (prefixed with `glrt-`) in a secret
  [referenced by a Custom Resource Definition](https://docs.gitlab.com/runner/install/operator.html#install-gitlab-runner).
- The runner authentication token is due to expire.
  For more information about runner authentication token expiration,
  see [Authentication token security](configure_runners.md#authentication-token-security).

For more information, see [issue 186](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/186).
