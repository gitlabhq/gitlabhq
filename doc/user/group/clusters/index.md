---
type: reference
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Group-level Kubernetes clusters **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/34758) in GitLab 11.6.

Similar to [project-level](../../project/clusters/index.md) and
[instance-level](../../instance/clusters/index.md) Kubernetes clusters,
group-level Kubernetes clusters allow you to connect a Kubernetes cluster to
your group, enabling you to use the same cluster across multiple projects.

To view your group level Kubernetes clusters, navigate to your project and select
**Kubernetes** from the left-hand menu.

## Cluster management project

Attach a [cluster management project](../../clusters/management_project.md)
to your cluster to manage shared resources requiring `cluster-admin` privileges for
installation, such as an Ingress controller.

## RBAC compatibility

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/29398) in GitLab 11.4.
> - [Project namespace restriction](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/51716) was introduced in GitLab 11.5.

For each project under a group with a Kubernetes cluster, GitLab creates a restricted
service account with [`edit` privileges](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)
in the project namespace.

## Cluster precedence

If the project's cluster is available and not disabled, GitLab uses the
project's cluster before using any cluster belonging to the group containing
the project.
In the case of subgroups, GitLab uses the cluster of the closest ancestor group
to the project, provided the cluster is not disabled.

## Multiple Kubernetes clusters

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35094) in GitLab Free 13.2.

You can associate more than one Kubernetes cluster to your group, and maintain different clusters
for different environments, such as development, staging, and production.

When adding another cluster,
[set an environment scope](#environment-scopes) to help
differentiate the new cluster from your other clusters.

## GitLab-managed clusters

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22011) in GitLab 11.5.
> - Became [optional](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/26565) in GitLab 11.11.

You can choose to allow GitLab to manage your cluster for you. If GitLab manages
your cluster, resources for your projects are automatically created. See the
[Access controls](../../project/clusters/add_remove_clusters.md#access-controls)
section for details on which resources GitLab creates for you.

For clusters not managed by GitLab, project-specific resources aren't created
automatically. If you're using [Auto DevOps](../../../topics/autodevops/index.md)
for deployments with a cluster not managed by GitLab, you must ensure:

- The project's deployment service account has permissions to deploy to
  [`KUBE_NAMESPACE`](../../project/clusters/deploy_to_cluster.md#deployment-variables).
- `KUBECONFIG` correctly reflects any changes to `KUBE_NAMESPACE`
  (this is [not automatic](https://gitlab.com/gitlab-org/gitlab/-/issues/31519)). Editing
  `KUBE_NAMESPACE` directly is discouraged.

### Clearing the cluster cache

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31759) in GitLab 12.6.

If you choose to allow GitLab to manage your cluster for you, GitLab stores a cached
version of the namespaces and service accounts it creates for your projects. If you
modify these resources in your cluster manually, this cache can fall out of sync with
your cluster, which can cause deployment jobs to fail.

To clear the cache:

1. Navigate to your group's **Kubernetes** page,
   and select your cluster.
1. Expand the **Advanced settings** section.
1. Click **Clear cluster cache**.

## Base domain

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/24580) in GitLab 11.8.

Domains at the cluster level permit support for multiple domains
per [multiple Kubernetes clusters](#multiple-kubernetes-clusters) When specifying a domain,
this is automatically set as an environment variable (`KUBE_INGRESS_BASE_DOMAIN`) during
the [Auto DevOps](../../../topics/autodevops/index.md) stages.

The domain should have a wildcard DNS configured to the Ingress IP address. [More details](../../project/clusters/gitlab_managed_clusters.md#base-domain).

## Environment scopes **(PREMIUM)**

When adding more than one Kubernetes cluster to your project, you need to differentiate
them with an environment scope. The environment scope associates clusters with
[environments](../../../ci/environments/index.md) similar to how the
[environment-specific CI/CD variables](../../../ci/variables/index.md#limit-the-environment-scope-of-a-cicd-variable)
work.

While evaluating which environment matches the environment scope of a
cluster, [cluster precedence](#cluster-precedence) takes
effect. The cluster at the project level takes precedence, followed
by the closest ancestor group, followed by that groups' parent and so
on.

For example, if your project has the following Kubernetes clusters:

| Cluster    | Environment scope   | Where     |
| ---------- | ------------------- | ----------|
| Project    | `*`                 | Project   |
| Staging    | `staging/*`         | Project   |
| Production | `production/*`      | Project   |
| Test       | `test`              | Group     |
| Development| `*`                 | Group     |

And the following environments are set in [`.gitlab-ci.yml`](../../../ci/yaml/index.md):

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

The result is:

- The Project cluster is used for the `test` job.
- The Staging cluster is used for the `deploy to staging` job.
- The Production cluster is used for the `deploy to production` job.

## Cluster environments **(PREMIUM)**

For a consolidated view of which CI [environments](../../../ci/environments/index.md)
are deployed to the Kubernetes cluster, see the documentation for
[cluster environments](../../clusters/environments.md).

## Security of runners

For important information about securely configuring runners, see
[Security of runners](../../project/clusters/cluster_access.md#security-of-runners)
documentation for project-level clusters.

## More information

For information on integrating GitLab and Kubernetes, see
[Kubernetes clusters](../../project/clusters/index.md).

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
