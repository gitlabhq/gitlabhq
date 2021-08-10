---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Cluster access controls (RBAC or ABAC)

> Restricted service account for deployment was [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/51716) in GitLab 11.5.

When creating a cluster in GitLab, you are asked if you would like to create either:

- A [Role-based access control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
  cluster, which is the GitLab default and recommended option.
- An [Attribute-based access control (ABAC)](https://kubernetes.io/docs/reference/access-authn-authz/abac/) cluster.

When GitLab creates the cluster,
a `gitlab` service account with `cluster-admin` privileges is created in the `default` namespace
to manage the newly created cluster.

Helm also creates additional service accounts and other resources for each
installed application. Consult the documentation of the Helm charts for each application
for details.

If you are [adding an existing Kubernetes cluster](add_remove_clusters.md#add-existing-cluster),
ensure the token of the account has administrator privileges for the cluster.

The resources created by GitLab differ depending on the type of cluster.

## Important notes

Note the following about access controls:

- Environment-specific resources are only created if your cluster is
  [managed by GitLab](index.md#gitlab-managed-clusters).
- If your cluster was created before GitLab 12.2, it uses a single namespace for all project
  environments.

## RBAC cluster resources

GitLab creates the following resources for RBAC clusters.

| Name                  | Type                 | Details                                                                                                    | Created when           |
|:----------------------|:---------------------|:-----------------------------------------------------------------------------------------------------------|:-----------------------|
| `gitlab`              | `ServiceAccount`     | `default` namespace                                                                                        | Creating a new cluster |
| `gitlab-admin`        | `ClusterRoleBinding` | [`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) roleRef | Creating a new cluster |
| `gitlab-token`        | `Secret`             | Token for `gitlab` ServiceAccount                                                                          | Creating a new cluster |
| Environment namespace | `Namespace`          | Contains all environment-specific resources                                                                | Deploying to a cluster |
| Environment namespace | `ServiceAccount`     | Uses namespace of environment                                                                              | Deploying to a cluster |
| Environment namespace | `Secret`             | Token for environment ServiceAccount                                                                       | Deploying to a cluster |
| Environment namespace | `RoleBinding`        | [`admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) roleRef         | Deploying to a cluster |

The environment namespace `RoleBinding` was
[updated](https://gitlab.com/gitlab-org/gitlab/-/issues/31113) in GitLab 13.6
to `admin` roleRef. Previously, the `edit` roleRef was used.

## ABAC cluster resources

GitLab creates the following resources for ABAC clusters.

| Name                  | Type                 | Details                              | Created when               |
|:----------------------|:---------------------|:-------------------------------------|:---------------------------|
| `gitlab`              | `ServiceAccount`     | `default` namespace                         | Creating a new cluster |
| `gitlab-token`        | `Secret`             | Token for `gitlab` ServiceAccount           | Creating a new cluster |
| Environment namespace | `Namespace`          | Contains all environment-specific resources | Deploying to a cluster |
| Environment namespace | `ServiceAccount`     | Uses namespace of environment               | Deploying to a cluster |
| Environment namespace | `Secret`             | Token for environment ServiceAccount        | Deploying to a cluster |

## Security of runners

Runners have the [privileged mode](https://docs.gitlab.com/runner/executors/docker.html#the-privileged-mode)
enabled by default, which allows them to execute special commands and run
Docker in Docker. This functionality is needed to run some of the
[Auto DevOps](../../../topics/autodevops/index.md)
jobs. This implies the containers are running in privileged mode and you should,
therefore, be aware of some important details.

The privileged flag gives all capabilities to the running container, which in
turn can do almost everything that the host can do. Be aware of the
inherent security risk associated with performing `docker run` operations on
arbitrary images as they effectively have root access.

If you don't want to use a runner in privileged mode, either:

- Use shared runners on GitLab.com. They don't have this security issue.
- Set up your own runners that use [`docker+machine`](https://docs.gitlab.com/runner/executors/docker_machine.html).
