---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Best practices for using the GitLab integration with Kubernetes

The agent for Kubernetes and Flux together offer the best experience when deploying to Kubernetes through GitOps.
GitLab recommends using GitOps (also known as pull-based deployment) for deployments.
However, your company might not be able to transition to GitOps, or you might have certain (typically non-production) reasons to use
a pipeline-based approach. This page describes best practices for using GitOps for enterprise, with some considerations for pipeline-based deployments.

For a description of the advantages of GitOps, see [the OpenGitOps initiative](https://opengitops.dev/about).

## GitOps

- Although [Get started connecting a Kubernetes cluster to GitLab](getting_started.md) shows how to install Flux using the Flux CLI, to scale and automate Flux deployments you should do either of the following:
  - Use the [Flux Operator](https://github.com/controlplaneio-fluxcd/flux-operator).
  - Install with [Terraform](https://registry.terraform.io/providers/fluxcd/flux/latest/docs) or [OpenTofu](https://search.opentofu.org/provider/fluxcd/flux/latest).
- Configure Flux with [multi-tenancy lockdown](https://fluxcd.io/flux/installation/configuration/multitenancy/).
- For scaling, Flux supports [vertical](https://fluxcd.io/flux/installation/configuration/vertical-scaling/) and [horizontal sharding](https://fluxcd.io/flux/installation/configuration/sharding/).
- For Flux-specific guidance, see the [Flux guides](https://fluxcd.io/flux/guides/) in the Flux documentation.
- To simplify maintenance, you should run a single GitLab agent for Kubernetes installation per cluster. You can share the agent connection with impersonation features across the GitLab domain.
- Consider using the Flux `OCIRepository` for storing and retrieving manifests. 
  You can use GitLab pipelines to build and push the OCI images to the container registry.
- To shorten the feedback loop, trigger an immediate GitOps reconciliation from the related GitLab pipeline.
- You should sign generated OCI images, and deploy only images signed and verified by Flux.
- Be sure to regularly rotate the keys used by Flux to access the manifests. You should also regularly rotate your agent-registration token.

### OCI containers

When you use OCI containers instead of Git repositories, the source of truth for the manifests is still the Git repository. 
You can think of the OCI container as a caching layer between the Git repository and the cluster.

There are several benefits to using OCI containers:

- OCI was designed for scalability. Although the GitLab Git repositories scale well, they were not designed for this use case.
- A single Git repository can be the source of several OCI containers, each packaging a small set of manifests.
  This way, if you need to retrieve a set of manifests, you don't need to download the whole Git repository.
- OCI repositories can follow a well-known versioning scheme, and Flux can be configured to auto-update following that scheme. 
  For example, if you use semantic versioning, Flux can deploy all the minor and patch changes automatically, while major versions require a manual update.
- OCI images can be signed, and the signature can be verified by Flux.
- OCI repositories can be scanned by the container registry, even after the image is built.
- The job that builds the OCI container enables using well-known release management features that regular GitOps tools doesn't support, like [protected environments](../../../ci/environments/protected_environments.md), [deployment approvals](../../../ci/environments/deployment_approvals.md), and [deployment freeze windows](../../project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze).

## Pipeline-based deployments

If you need to use a pipeline-based deployment, follow these best practices:

- To reduce the number of agent deployed per cluster, share the agent connection across your groups and projects.
  If possible, use only one agent deployment per cluster.
- Use impersonation, and minimize the access CI/CD jobs in the cluster using regular Kubernetes RBAC.
