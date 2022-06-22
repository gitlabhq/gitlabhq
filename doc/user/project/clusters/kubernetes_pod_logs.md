---
stage: Monitor
group: Respond
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Kubernetes Logs (DEPRECATED) **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/4752) in GitLab 11.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/26383) from GitLab Ultimate to GitLab Free 12.9.
> - [Deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/360182) behind a [feature flag](../../../administration/feature_flags.md) named `monitor_logging` in GitLab 15.0. Disabled by default.
> - [Disabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/353410) in GitLab 15.0.

WARNING:
This feature is in its end-of-life process.
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.
It will be [removed completely](https://gitlab.com/gitlab-org/gitlab/-/issues/346485) in GitLab 15.2.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named `monitor_logging` and the one named `certificate_based_clusters`.
On GitLab.com, this feature is not available.
This feature is not recommended for production use.

GitLab makes it easy to view the logs of running pods in
[connected Kubernetes clusters](index.md). By displaying the logs directly in GitLab
in the **Log Explorer**, developers can avoid managing console tools or jumping
to a different interface. The **Log Explorer** interface provides a set of filters
above the log file data, depending on your configuration:

![Pod logs](img/kubernetes_pod_logs_v12_10.png)

- **Namespace** - Select the environment to display. Users with Maintainer or
  greater [permissions](../../permissions.md) can also see pods in the
  `gitlab-managed-apps` namespace.
- **Scroll to bottom** **{scroll_down}** - Scroll to the end of the displayed logs.
- **Refresh** **{retry}** - Reload the displayed logs.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
To learn more about the Log Explorer, see [APM - Log Explorer](https://www.youtube.com/watch?v=hWclZHA7Dgw).

[Learn more about Kubernetes + GitLab](https://about.gitlab.com/solutions/kubernetes/).
Everything you need to build, test, deploy, and run your application at scale.

## Requirements

[Deploying to a Kubernetes environment](../deploy_boards.md#enabling-deploy-boards)
is required to use Logs.

## Accessing the log explorer

To access the **Log explorer**, select the **More actions** **{ellipsis_v}** menu on
a [metrics dashboard](../../../operations/metrics/index.md) and select **View logs**, or:

1. Sign in as a user with the _View pod logs_
   [permissions](../../permissions.md#project-members-permissions) in the project.
1. To navigate to the **Log Explorer** from the sidebar menu, go to **Monitor > Logs**
   ([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22011) in GitLab 12.5.).
1. To navigate to the **Log Explorer** from a specific pod on a [deploy board](../deploy_boards.md):

   1. Go to **Deployments > Environments** and find the environment
      which contains the desired pod, like `production`.
   1. On the **Environments** page, you should see the status of the environment's
      pods with [deploy boards](../deploy_boards.md).
   1. When mousing over the list of pods, GitLab displays a tooltip with the exact pod name
      and status.
      ![deploy boards pod list](img/pod_logs_deploy_board.png)
   1. Select the desired pod to display the **Log Explorer**.

### Logs view

The **Log Explorer** lets you filter the logs by:

- Pods.
- [From GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/issues/5769), environments.
- [From GitLab 12.8](https://gitlab.com/gitlab-org/gitlab/-/issues/197879), dates.
- [From GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/issues/208790), managed apps.

Loading more than 500 log lines is possible from
[GitLab 12.9](https://gitlab.com/gitlab-org/gitlab/-/issues/198050) onward.

Support for pods with multiple containers is coming
[in a future release](https://gitlab.com/gitlab-org/gitlab/-/issues/13404).

Support for historical data is coming
[in a future release](https://gitlab.com/gitlab-org/gitlab/-/issues/196191).
