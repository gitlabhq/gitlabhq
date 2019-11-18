# Kubernetes Pod Logs **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/4752) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 11.0.

GitLab makes it easy to view the logs of running pods in [connected Kubernetes clusters](index.md).
By displaying the logs directly in GitLab, developers can avoid having to manage console tools or jump to a different interface.

NOTE: **Kubernetes + GitLab**
Everything you need to build, test, deploy, and run your app at scale.
[Learn more](https://about.gitlab.com/solutions/kubernetes/).

## Overview

[Kubernetes](https://kubernetes.io) pod logs can be viewed directly within GitLab.

![Pod logs](img/kubernetes_pod_logs_v12_5.png)

## Requirements

[Deploying to a Kubernetes environment](../deploy_boards.md#enabling-deploy-boards) is required in order to be able to use Pod Logs.

## Usage

To access pod logs, you must have the right [permissions](../../permissions.md#project-members-permissions).

You can access them in two ways.

### From the project sidebar

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/22011) in GitLab 12.5.

Go to **Operations > Pod logs** on the sidebar menu.

![Sidebar menu](img/sidebar_menu_pod_logs_v12_5.png)

### From Deploy Boards

Logs can be displayed by clicking on a specific pod from [Deploy Boards](../deploy_boards.md):

1. Go to **Operations > Environments** and find the environment which contains the desired pod, like `production`.
1. On the **Environments** page, you should see the status of the environment's pods with [Deploy Boards](../deploy_boards.md).
1. When mousing over the list of pods, a tooltip will appear with the exact pod name and status.
   ![Deploy Boards pod list](img/pod_logs_deploy_board.png)
1. Click on the desired pod to bring up the logs view, which will contain the last 500 lines for that pod.
   You may switch between the following in this view:
   - Pods.
   - [From GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/issues/5769), environments.

   Support for pods with multiple containers is coming [in a future release](https://gitlab.com/gitlab-org/gitlab/issues/6502).
