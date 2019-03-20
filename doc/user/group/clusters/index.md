# Group-level Kubernetes clusters

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/34758) in GitLab 11.6.
> Group Cluster integration is currently in [Beta](https://about.gitlab.com/handbook/product/#alpha-beta-ga).

## Overview

Similar to [project Kubernetes
clusters](../../project/clusters/index.md), Group-level Kubernetes
clusters allow you to connect a Kubernetes cluster to your group,
enabling you to use the same cluster across multiple projects.

## Installing applications

GitLab provides a one-click install for various applications that can be
added directly to your cluster.

NOTE: **Note:**
Applications will be installed in a dedicated namespace called
`gitlab-managed-apps`. If you have added an existing Kubernetes cluster
with Tiller already installed, you should be careful as GitLab cannot
detect it. In this event, installing Tiller via the applications will
result in the cluster having it twice. This can lead to confusion during
deployments.

| Application                                                                | GitLab version | Description | Helm Chart |
| -----------                                                                | -------------- | ----------- | ---------- |
| [Helm Tiller](https://docs.helm.sh)                                        | 11.6+          | Helm is a package manager for Kubernetes and is required to install all the other applications. It is installed in its own pod inside the cluster which can run the `helm` CLI in a safe environment. | n/a |
| [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress) | 11.6+          | Ingress can provide load balancing, SSL termination, and name-based virtual hosting. It acts as a web proxy for your applications and is useful if you want to use [Auto DevOps](../../../topics/autodevops/index.md) or deploy your own web apps. | [stable/nginx-ingress](https://github.com/helm/charts/tree/master/stable/nginx-ingress) |
| [Cert-Manager](https://docs.cert-manager.io/en/latest/) | 11.6+ | Cert-Manager is a native Kubernetes certificate management controller that helps with issuing certificates. Installing Cert-Manager on your cluster will issue a certificate by [Let's Encrypt](https://letsencrypt.org/) and ensure that certificates are valid and up-to-date. | [stable/cert-manager](https://github.com/helm/charts/tree/master/stable/cert-manager) |

NOTE: **Note:**
Some [cluster
applications](../../project/clusters/index.md#installing-applications)
are installable only for a project-level cluster. Support for installing these
applications in a group-level cluster is planned for future releases. For updates, see:

- Support installing [Runner in group-level
  clusters](https://gitlab.com/gitlab-org/gitlab-ce/issues/51988)
- Support installing [JupyterHub in group-level
  clusters](https://gitlab.com/gitlab-org/gitlab-ce/issues/51989)
- Support installing [Prometheus in group-level
  clusters](https://gitlab.com/gitlab-org/gitlab-ce/issues/51963)

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

## Multiple Kubernetes clusters **[PREMIUM]**

With GitLab Premium, you can associate more than one Kubernetes clusters to your
group. That way you can have different clusters for different environments,
like dev, staging, production, etc.

Add another cluster similar to the first one and make sure to
[set an environment scope](#environment-scopes-premium) that will
differentiate the new cluster from the rest.

## Base domain

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/24580) in GitLab 11.8.

Domains at the cluster level permit support for multiple domains
per [multiple Kubernetes clusters](#multiple-kubernetes-clusters-premium). When specifying a domain,
this will be automatically set as an environment variable (`KUBE_INGRESS_BASE_DOMAIN`) during
the [Auto DevOps](../../../topics/autodevops/index.md) stages.

The domain should have a wildcard DNS configured to the Ingress IP address.

## Environment scopes **[PREMIUM]**

When adding more than one Kubernetes cluster to your project, you need to differentiate
them with an environment scope. The environment scope associates clusters with
[environments](../../../ci/environments.md) similar to how the
[environment-specific variables](https://docs.gitlab.com/ee/ci/variables/README.html#limiting-environment-scopes-of-variables-premium)
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

## Unavailable features

The following features are not currently available for group-level clusters:

1. Terminals (see [related issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/55487)).
1. Pod logs (see [related issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/55488)).
1. Deployment boards (see [related issue](https://gitlab.com/gitlab-org/gitlab-ce/issues/55489)).
