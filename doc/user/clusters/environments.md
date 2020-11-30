---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Cluster Environments **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13392) for group-level clusters in [GitLab Premium](https://about.gitlab.com/pricing/) 12.3.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14809) for instance-level clusters in [GitLab Premium](https://about.gitlab.com/pricing/) 12.4.

Cluster environments provide a consolidated view of which CI [environments](../../ci/environments/index.md) are
deployed to the Kubernetes cluster and it:

- Shows the project and the relevant environment related to the deployment.
- Displays the status of the pods for that environment.

## Overview

With cluster environments, you can gain insight into:

- Which projects are deployed to the cluster.
- How many pods are in use for each project's environment.
- The CI job that was used to deploy to that environment.

![Cluster environments page](img/cluster_environments_table_v12_3.png)

Access to cluster environments is restricted to [group maintainers and
owners](../permissions.md#group-members-permissions)

## Usage

In order to:

- Track environments for the cluster, you must
  [deploy to a Kubernetes cluster](../project/clusters/index.md#deploying-to-a-kubernetes-cluster)
  successfully.
- Show pod usage correctly, you must
  [enable Deploy Boards](../project/deploy_boards.md#enabling-deploy-boards).

Once you have successful deployments to your group-level or instance-level cluster:

1. Navigate to your group's **Kubernetes** page.
1. Click on the **Environments** tab.

Only successful deployments to the cluster are included in this page.
Non-cluster environments aren't included.
