---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Connecting a Kubernetes cluster with GitLab
---

> - Flux [recommended](https://gitlab.com/gitlab-org/gitlab/-/issues/357947#note_1253489000) as GitOps solution in GitLab 15.10.

You can connect your Kubernetes cluster with GitLab to deploy, manage,
and monitor your cloud-native solutions.

To connect a Kubernetes cluster to GitLab, you must first [install an agent in your cluster](install/_index.md).

The agent runs in the cluster, and you can use it to:

- Communicate with a cluster, which is behind a firewall or NAT.
- Access API endpoints in a cluster in real time.
- Push information about events happening in the cluster.
- Enable a cache of Kubernetes objects, which are kept up-to-date with very low latency.

For more details about the agent's purpose and architecture, see the [architecture documentation](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md).

You must deploy a separate agent to every cluster you want to connect to GitLab.
The agent was designed with strong multi-tenancy support. To simplify maintenance and operations you should run only one agent per cluster.

An agent is always registered in a GitLab project.
After an agent is registered and installed, the agent connection to the cluster can be shared with other projects, groups, and users.
This approach means you can manage and configure your agent instances from GitLab itself,
and you can scale a single installation to multiple tenants.

## Receptive agents

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12180) in GitLab 17.4.

Receptive agents allow GitLab to integrate with Kubernetes clusters that cannot establish a network connection
to the GitLab instance, but can be connected to by GitLab. For example, this can occur when:

1. GitLab runs in a private network or behind a firewall, and is only accessible only through VPN.
1. The Kubernetes cluster is hosted by a cloud provider, but is exposed to the internet or is reachable from the private network.

When this feature is enabled, GitLab connects to the agent with the provided URL.
You can use agents and receptive agents simultaneously.

## Supported Kubernetes versions for GitLab features

GitLab supports the following Kubernetes versions. If you want to run
GitLab in a Kubernetes cluster, you might need a different version of Kubernetes:

- For the [Helm Chart](https://docs.gitlab.com/charts/installation/cloud/index.html).
- For [GitLab Operator](https://docs.gitlab.com/operator/installation.html).

You can upgrade your
Kubernetes version to a supported version at any time:

- 1.31 (support ends when GitLab version 18.7 is released or when 1.34 becomes supported)
- 1.30 (support ends when GitLab version 18.2 is released or when 1.33 becomes supported)
- 1.29 (support ends when GitLab version 17.10 is released or when 1.32 becomes supported)

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

## Kubernetes deployment workflows

You can choose from two primary workflows. The GitOps workflow is recommended.

### GitOps workflow

GitLab recommends using [Flux for GitOps](gitops.md). To get started, see [Tutorial: Set up Flux for GitOps](gitops/flux_tutorial.md).

### GitLab CI/CD workflow

In a [**CI/CD** workflow](ci_cd_workflow.md), you configure GitLab CI/CD to use the Kubernetes API to query and update your cluster.

This workflow is considered **push-based**, because GitLab pushes requests
from GitLab CI/CD to your cluster.

Use this workflow:

- When you have pipeline-driven processes.
- When you need to migrate to the agent, but the GitOps workflow doesn't support your use case.

This workflow has a weaker security model. You should not use a CI/CD workflow for production deployments.

## Agent connection technical details

The agent opens a bidirectional channel to KAS for communication.
This channel is used for all communication between the agent and KAS:

- Each agent can maintain up to 500 logical gRPC streams, including active and idle streams.
- The number of TCP connections used by the gRPC streams is determined by gRPC itself.
- Each connection has a maximum lifetime of two hours, with a one-hour grace period.
  - A proxy in front of KAS might influence the maximum lifetime of connections. On GitLab.com, this is [two hours](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/-/blob/68df3484087f0af368d074215e17056d8ab69f1c/attributes/default.rb#L217). The grace period is 50% of the maximum lifetime.

For detailed information about channel routing, see [Routing KAS requests in the agent](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kas_request_routing.md).

## Kubernetes integration glossary

This glossary provides definitions for terms related to the GitLab Kubernetes integration.

| Term | Definition | Scope |
| --- | --- | --- |
| GitLab agent for Kubernetes | The overall offering, including related features and the underlying components `agentk` and `kas`. | GitLab, Kubernetes, Flux |
| `agentk` | The cluster-side component that maintains a secure connection to GitLab for Kubernetes management and deployment automation. | GitLab |
| GitLab agent server for Kubernetes (`kas`) | The GitLab-side component of GitLab that handles operations and logic for the Kubernetes agent integration. Manages the connection and communication between GitLab and Kubernetes clusters. | GitLab |
| Pull-based deployment | A deployment method where Flux checks for changes in a Git repository and automatically applies these changes to the cluster. | GitLab, Kubernetes |
| Push-based deployment | A deployment method where updates are sent from GitLab CI/CD pipelines to the Kubernetes cluster. | GitLab |
| Flux | An open-source GitOps tool that integrates with the agent for pull-based deployments. | GitOps, Kubernetes |
| GitOps | A set of practices that involve using Git for version control and collaboration in the management and automation of cloud and Kubernetes resources. | DevOps, Kubernetes |
| Kubernetes namespace | A logical partition in a Kubernetes cluster that divides cluster resources between multiple users or environments. | Kubernetes |

## Related topics

- [GitOps workflow](gitops.md)
- [GitOps examples and learning materials](gitops.md#related-topics)
- [GitLab CI/CD workflow](ci_cd_workflow.md)
- [Install the agent](install/_index.md)
- [Work with the agent](work_with_agent.md)
- [Migrate to the agent for Kubernetes from the legacy certificate-based integration](../../infrastructure/clusters/migrate_to_gitlab_agent.md)
- [Troubleshooting](troubleshooting.md)
- [Guided explorations for a production ready GitOps setup](https://gitlab.com/groups/guided-explorations/gl-k8s-agent/gitops/-/wikis/home#gitlab-agent-for-kubernetes-gitops-working-examples)
- [CI/CD for Kubernetes examples and learning materials](ci_cd_workflow.md#related-topics)
- [Contribute to the agent's development](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/doc)
