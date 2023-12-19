---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Connecting a Kubernetes cluster with GitLab

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/223061) in GitLab 13.4.
> - Support for `grpcs` [introduced](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/7) in GitLab 13.6.
> - Agent server [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/300960) on GitLab.com under `wss://kas.gitlab.com` through an Early Adopter Program in GitLab 13.10.
> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/3834) in GitLab 13.11, the GitLab agent became available on GitLab.com.
> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/6290) from GitLab Premium to GitLab Free in 14.5.
> - [Renamed](https://gitlab.com/groups/gitlab-org/-/epics/7167) from "GitLab Kubernetes Agent" to "GitLab agent for Kubernetes" in GitLab 14.6.
> - Flux [recommended](https://gitlab.com/gitlab-org/gitlab/-/issues/357947#note_1253489000) as GitOps solution in GitLab 15.10.

You can connect your Kubernetes cluster with GitLab to deploy, manage,
and monitor your cloud-native solutions.

To connect a Kubernetes cluster to GitLab, you must first [install an agent in your cluster](install/index.md).

The agent runs in the cluster, and you can use it to:

- Communicate with a cluster, which is behind a firewall or NAT.
- Access API endpoints in a cluster in real time.
- Push information about events happening in the cluster.
- Enable a cache of Kubernetes objects, which are kept up-to-date with very low latency.

For more details about the agent's purpose and architecture, see the [architecture documentation](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md).

## Workflows

You can choose from two primary workflows. The GitOps workflow is recommended.

### GitOps workflow

You should use Flux for GitOps. To get started, see [Tutorial: Set up Flux for GitOps](gitops/flux_tutorial.md)

### GitLab CI/CD workflow

In a [**CI/CD** workflow](ci_cd_workflow.md):

- You configure GitLab CI/CD to use the Kubernetes API to query and update your cluster.

This workflow is considered **push-based**, because GitLab is pushing requests
from GitLab CI/CD to your cluster.

Use this workflow:

- When you have a heavily pipeline-oriented processes.
- When you need to migrate to the agent but the GitOps workflow cannot support the use case you need.

This workflow has a weaker security model and is not recommended for production deployments.

## Supported Kubernetes versions for GitLab features

GitLab supports the following Kubernetes versions. If you want to run
GitLab in a Kubernetes cluster, you might need a different version of Kubernetes:

- For the [Helm Chart](https://docs.gitlab.com/charts/installation/cloud/index.html).
- For [GitLab Operator](https://docs.gitlab.com/operator/installation.html#kubernetes).

You can upgrade your
Kubernetes version to a supported version at any time:

- 1.27 (support ends on July 18, 2024 or when 1.30 becomes supported)
- 1.26 (support ends on March 21, 2024 or when 1.29 becomes supported)
- 1.25 (support ends on October 22, 2023 or when 1.28 becomes supported)

GitLab aims to support a new minor Kubernetes version three months after its initial release. GitLab supports at least three production-ready Kubernetes minor
versions at any given time.

When a new version of Kubernetes is released, we will:

- Update this page with the results of our early smoke tests within approximately
  four weeks.
- If we expect a delay in releasing new version support, we will update this page
  with the expected GitLab support version within approximately eight weeks.

When installing the agent, use a Helm version compatible with your Kubernetes version. Other versions of Helm might not work. For a list of compatible versions, see the [Helm version support policy](https://helm.sh/docs/topics/version_skew/).

Support for deprecated APIs can be removed from the GitLab codebase when we drop support for the Kubernetes version that only supports the deprecated API.

Some GitLab features might work on versions not listed here. [This epic](https://gitlab.com/groups/gitlab-org/-/epics/4827) tracks support for Kubernetes versions.

## Migrate to the agent from the legacy certificate-based integration

Read about how to [migrate to the agent for Kubernetes](../../infrastructure/clusters/migrate_to_gitlab_agent.md) from the certificate-based integration.

## Agent connection

The agent opens a bidirectional channel to KAS for communication.
This channel is used for all communication between the agent and KAS:

- Each agent can maintain up to 500 logical gRPC streams, including active and idle streams.
- The number of TCP connections used by the gRPC streams is determined by gRPC itself.
- Each connection has a maximum lifetime of two hours, with a one-hour grace period.
  - A proxy in front of KAS might influence the maximum lifetime of connections. On GitLab.com, this is [two hours](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/-/blob/68df3484087f0af368d074215e17056d8ab69f1c/attributes/default.rb#L217). The grace period is 50% of the maximum lifetime.

For detailed information about channel routing, see [Routing KAS requests in the agent](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kas_request_routing.md).

## Related topics

- [GitOps workflow](gitops.md)
- [GitOps examples and learning materials](gitops.md#related-topics)
- [GitLab CI/CD workflow](ci_cd_workflow.md)
- [Install the agent](install/index.md)
- [Work with the agent](work_with_agent.md)
- [Troubleshooting](troubleshooting.md)
- [Guided explorations for a production ready GitOps setup](https://gitlab.com/groups/guided-explorations/gl-k8s-agent/gitops/-/wikis/home#gitlab-agent-for-kubernetes-gitops-working-examples)
- [CI/CD for Kubernetes examples and learning materials](ci_cd_workflow.md#related-topics)
- [Contribute to the agent's development](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/doc)
