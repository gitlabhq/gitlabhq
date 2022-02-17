---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Connecting a Kubernetes cluster with GitLab

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/223061) in GitLab 13.4.
> - Support for `grpcs` [introduced](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/7) in GitLab 13.6.
> - Agent Server [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/300960) on GitLab.com under `wss://kas.gitlab.com` through an Early Adopter Program in GitLab 13.10.
> - The agent became available to every project on GitLab.com in GitLab 13.11.
> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/6290) from GitLab Premium to GitLab Free in 14.5.
> - [Renamed](https://gitlab.com/groups/gitlab-org/-/epics/7167) from "GitLab Kubernetes Agent" to "GitLab agent for Kubernetes" in GitLab 14.6.

You can connect your Kubernetes cluster with GitLab to deploy, manage,
and monitor your cloud-native solutions. You can choose from two primary workflows.

In a [**GitOps** workflow](gitops.md), you keep your Kubernetes manifests in GitLab. You install a GitLab agent in your cluster, and
any time you update your manifests, the agent updates the cluster. This workflow is fully driven with Git and is considered pull-based,
because the cluster is pulling updates from your GitLab repository.

In a [**CI/CD** workflow](ci_cd_tunnel.md), you use GitLab CI/CD to query and update your cluster by using the Kubernetes API.
This workflow is considered push-based, because GitLab is pushing requests from GitLab CI/CD to your cluster.

Both of these workflows require you to [install an agent in your cluster](install/index.md).

## Supported cluster versions

GitLab supports the following Kubernetes versions. You can upgrade your
Kubernetes version to a supported version at any time:

- 1.20 (support ends on July 22, 2022)
- 1.19 (support ends on February 22, 2022)
- 1.18 (support ends on November 22, 2021)
- 1.17 (support ends on September 22, 2021)

GitLab supports at least two production-ready Kubernetes minor
versions at any given time. GitLab regularly reviews the supported versions and
provides a three-month deprecation period before removing support for a specific
version. The list of supported versions is based on:

- The versions supported by major managed Kubernetes providers.
- The versions [supported by the Kubernetes community](https://kubernetes.io/releases/version-skew-policy/#supported-versions).

[This epic](https://gitlab.com/groups/gitlab-org/-/epics/4827) tracks support for other Kubernetes versions.

Some GitLab features might work on versions not listed here.

## Migrate to the agent from the legacy certificate-based integration

Read about how to [migrate to the agent for Kubernetes](../../infrastructure/clusters/migrate_to_gitlab_agent.md) from the certificate-based integration.

## Related topics

- [GitOps workflow](gitops.md)
- [GitLab CI/CD workflow](ci_cd_tunnel.md)
- [Install the agent](install/index.md)
- [Work with the agent](repository.md)
- [Troubleshooting](troubleshooting.md)
- [Contribute to the agent's development](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/doc)
