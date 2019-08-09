---
type: reference
---

# Group-level Kubernetes clusters

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/34758) in GitLab 11.6.

## Overview

Similar to [project-level](../../project/clusters/index.md) and
[instance-level](../../instance/clusters/index.md) Kubernetes clusters,
group-level Kubernetes clusters allow you to connect a Kubernetes cluster to
your group, enabling you to use the same cluster across multiple projects.

## Installing applications

GitLab can install and manage some applications in your group-level
cluster. For more information on installing, upgrading, uninstalling,
and troubleshooting applications for your group cluster, see
[Gitlab Managed Apps](../../clusters/applications.md).

## RBAC compatibility

For each project under a group with a Kubernetes cluster, GitLab will
create a restricted service account with [`edit`
privileges](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)
in the project namespace.

NOTE: **Note:**
RBAC support was introduced in
[GitLab 11.4](https://gitlab.com/gitlab-org/gitlab-ce/issues/29398), and
Project namespace restriction was introduced in
[GitLab 11.5](https://gitlab.com/gitlab-org/gitlab-ce/issues/51716).

## Cluster precedence

GitLab will use the project's cluster before using any cluster belonging
to the group containing the project if the project's cluster is available and not disabled.

In the case of sub-groups, GitLab will use the cluster of the closest ancestor group
to the project, provided the cluster is not disabled.

## Multiple Kubernetes clusters **(PREMIUM)**

With GitLab Premium, you can associate more than one Kubernetes clusters to your
group. That way you can have different clusters for different environments,
like dev, staging, production, etc.

Add another cluster similar to the first one and make sure to
[set an environment scope](#environment-scopes-premium) that will
differentiate the new cluster from the rest.

## GitLab-managed clusters

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/22011) in GitLab 11.5.
> Became [optional](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/26565) in GitLab 11.11.

You can choose to allow GitLab to manage your cluster for you. If your cluster is
managed by GitLab, resources for your projects will be automatically created. See the
[Access controls](../../project/clusters/index.md#access-controls) section for details on which resources will
be created.

If you choose to manage your own cluster, project-specific resources will not be created
automatically. If you are using [Auto DevOps](../../../topics/autodevops/index.md), you will
need to explicitly provide the `KUBE_NAMESPACE` [deployment variable](../../project/clusters/index.md#deployment-variables)
that will be used by your deployment jobs.

NOTE: **Note:**
If you [install applications](#installing-applications) on your cluster, GitLab will create
the resources required to run these even if you have chosen to manage your own cluster.

## Base domain

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/24580) in GitLab 11.8.

Domains at the cluster level permit support for multiple domains
per [multiple Kubernetes clusters](#multiple-kubernetes-clusters-premium). When specifying a domain,
this will be automatically set as an environment variable (`KUBE_INGRESS_BASE_DOMAIN`) during
the [Auto DevOps](../../../topics/autodevops/index.md) stages.

The domain should have a wildcard DNS configured to the Ingress IP address.

## Environment scopes **(PREMIUM)**

When adding more than one Kubernetes cluster to your project, you need to differentiate
them with an environment scope. The environment scope associates clusters with
[environments](../../../ci/environments.md) similar to how the
[environment-specific variables](../../../ci/variables/README.md#limiting-environment-scopes-of-environment-variables)
work.

While evaluating which environment matches the environment scope of a
cluster, [cluster precedence](#cluster-precedence) will take
effect. The cluster at the project level will take precedence, followed
by the closest ancestor group, followed by that groups' parent and so
on.

For example, let's say we have the following Kubernetes clusters:

| Cluster    | Environment scope   | Where     |
| ---------- | ------------------- | ----------|
| Project    | `*`                 | Project   |
| Staging    | `staging/*`         | Project   |
| Production | `production/*`      | Project   |
| Test       | `test`              | Group     |
| Development| `*`                 | Group     |

And the following environments are set in [`.gitlab-ci.yml`](../../../ci/yaml/README.md):

```yaml
stages:
- test
- deploy

test:
  stage: test
  script: sh test

deploy to staging:
  stage: deploy
  script: make deploy
  environment:
    name: staging/$CI_COMMIT_REF_NAME
    url: https://staging.example.com/

deploy to production:
  stage: deploy
  script: make deploy
  environment:
    name: production/$CI_COMMIT_REF_NAME
    url: https://example.com/
```

The result will then be:

- The Project cluster will be used for the `test` job.
- The Staging cluster will be used for the `deploy to staging` job.
- The Production cluster will be used for the `deploy to production` job.

## Security of Runners

For important information about securely configuring GitLab Runners, see
[Security of
Runners](../../project/clusters/index.md#security-of-gitlab-runners)
documentation for project-level clusters.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
