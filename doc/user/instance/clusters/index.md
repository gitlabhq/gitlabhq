# Instance-level Kubernetes clusters

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/39840) in GitLab 11.11.

## Overview

Similar to [project-level](../../project/clusters/index.md)
and [group-level](../../group/clusters/index.md) Kubernetes clusters,
instance-level Kubernetes clusters allow you to connect a Kubernetes cluster to
the GitLab instance, which enables you to use the same cluster across multiple
projects.

## Cluster precedence

GitLab will try [to match](../../../ci/environments.md#scoping-environments-with-specs) clusters in
the following order:

- Project-level clusters.
- Group-level clusters.
- Instance-level clusters.

To be selected, the cluster must be enabled and
match the [environment selector](../../../ci/environments.md#scoping-environments-with-specs).

## Cluster environments **(PREMIUM)**

For a consolidated view of which CI [environments](../../../ci/environments.md)
are deployed to the Kubernetes cluster, see the documentation for
[cluster environments](../../clusters/environments.md).

## More information

For information on integrating GitLab and Kubernetes, see
[Kubernetes clusters](../../project/clusters/index.md).
