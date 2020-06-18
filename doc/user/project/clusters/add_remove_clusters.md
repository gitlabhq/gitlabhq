---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Adding and removing Kubernetes clusters

GitLab offers integrated cluster creation for the following Kubernetes providers:

- Google Kubernetes Engine (GKE).
- Amazon Elastic Kubernetes Service (EKS).

GitLab can also integrate with any standard Kubernetes provider, either on-premise or hosted.

TIP: **Tip:**
Every new Google Cloud Platform (GCP) account receives [$300 in credit upon sign up](https://console.cloud.google.com/freetrial),
and in partnership with Google, GitLab is able to offer an additional $200 for new GCP accounts to get started with GitLab's
Google Kubernetes Engine Integration. All you have to do is [follow this link](https://cloud.google.com/partners/partnercredit/?pcn_code=0014M00001h35gDQAQ#contact-form) and apply for credit.

## Before you begin

Before [adding a Kubernetes cluster](#create-new-cluster) using GitLab, you need:

- GitLab itself. Either:
  - A GitLab.com [account](https://about.gitlab.com/pricing/#gitlab-com).
  - A [self-managed installation](https://about.gitlab.com/pricing/#self-managed) with GitLab version
    12.5 or later. This will ensure the GitLab UI can be used for cluster creation.
- The following GitLab access:
  - [Maintainer access to a project](../../permissions.md#project-members-permissions) for a
    project-level cluster.
  - [Maintainer access to a group](../../permissions.md#group-members-permissions) for a
    group-level cluster.
  - [Admin Area access](../../admin_area/index.md) for a self-managed instance-level
    cluster. **(CORE ONLY)**

## Access controls

When creating a cluster in GitLab, you will be asked if you would like to create either:

- A [Role-based access control (RBAC)](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) cluster.
- An [Attribute-based access control (ABAC)](https://kubernetes.io/docs/reference/access-authn-authz/abac/) cluster.

NOTE: **Note:**
[RBAC](#rbac-cluster-resources) is recommended and the GitLab default.

GitLab creates the necessary service accounts and privileges to install and run
[GitLab managed applications](index.md#installing-applications). When GitLab creates the cluster,
a `gitlab` service account with `cluster-admin` privileges is created in the `default` namespace
to manage the newly created cluster.

NOTE: **Note:**
Restricted service account for deployment was [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/51716) in GitLab 11.5.

When you install Helm into your cluster, the `tiller` service account
is created with `cluster-admin` privileges in the `gitlab-managed-apps`
namespace.

This service account will be:

- Added to the installed Helm Tiller.
- Used by Helm to install and run [GitLab managed applications](index.md#installing-applications).

Helm will also create additional service accounts and other resources for each
installed application. Consult the documentation of the Helm charts for each application
for details.

If you are [adding an existing Kubernetes cluster](add_remove_clusters.md#add-existing-cluster),
ensure the token of the account has administrator privileges for the cluster.

The resources created by GitLab differ depending on the type of cluster.

### Important notes

Note the following about access controls:

- Environment-specific resources are only created if your cluster is
  [managed by GitLab](index.md#gitlab-managed-clusters).
- If your cluster was created before GitLab 12.2, it will use a single namespace for all project
  environments.

### RBAC cluster resources

GitLab creates the following resources for RBAC clusters.

| Name                  | Type                 | Details                                                                                                    | Created when           |
|:----------------------|:---------------------|:-----------------------------------------------------------------------------------------------------------|:-----------------------|
| `gitlab`              | `ServiceAccount`     | `default` namespace                                                                                        | Creating a new cluster |
| `gitlab-admin`        | `ClusterRoleBinding` | [`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) roleRef | Creating a new cluster |
| `gitlab-token`        | `Secret`             | Token for `gitlab` ServiceAccount                                                                          | Creating a new cluster |
| `tiller`              | `ServiceAccount`     | `gitlab-managed-apps` namespace                                                                            | Installing Helm Tiller |
| `tiller-admin`        | `ClusterRoleBinding` | `cluster-admin` roleRef                                                                                    | Installing Helm Tiller |
| Environment namespace | `Namespace`          | Contains all environment-specific resources                                                                | Deploying to a cluster |
| Environment namespace | `ServiceAccount`     | Uses namespace of environment                                                                              | Deploying to a cluster |
| Environment namespace | `Secret`             | Token for environment ServiceAccount                                                                       | Deploying to a cluster |
| Environment namespace | `RoleBinding`        | [`edit`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles) roleRef          | Deploying to a cluster |

### ABAC cluster resources

GitLab creates the following resources for ABAC clusters.

| Name                  | Type                 | Details                              | Created when               |
|:----------------------|:---------------------|:-------------------------------------|:---------------------------|
| `gitlab`              | `ServiceAccount`     | `default` namespace                         | Creating a new cluster |
| `gitlab-token`        | `Secret`             | Token for `gitlab` ServiceAccount           | Creating a new cluster |
| `tiller`              | `ServiceAccount`     | `gitlab-managed-apps` namespace             | Installing Helm Tiller |
| `tiller-admin`        | `ClusterRoleBinding` | `cluster-admin` roleRef                     | Installing Helm Tiller |
| Environment namespace | `Namespace`          | Contains all environment-specific resources | Deploying to a cluster |
| Environment namespace | `ServiceAccount`     | Uses namespace of environment               | Deploying to a cluster |
| Environment namespace | `Secret`             | Token for environment ServiceAccount        | Deploying to a cluster |

### Security of GitLab Runners

GitLab Runners have the [privileged mode](https://docs.gitlab.com/runner/executors/docker.html#the-privileged-mode)
enabled by default, which allows them to execute special commands and running
Docker in Docker. This functionality is needed to run some of the
[Auto DevOps](../../../topics/autodevops/index.md)
jobs. This implies the containers are running in privileged mode and you should,
therefore, be aware of some important details.

The privileged flag gives all capabilities to the running container, which in
turn can do almost everything that the host can do. Be aware of the
inherent security risk associated with performing `docker run` operations on
arbitrary images as they effectively have root access.

If you don't want to use GitLab Runner in privileged mode, either:

- Use shared Runners on GitLab.com. They don't have this security issue.
- Set up your own Runners using configuration described at
  [Shared Runners](../../gitlab_com/index.md#shared-runners). This involves:
  1. Making sure that you don't have it installed via
     [the applications](index.md#installing-applications).
  1. Installing a Runner
     [using `docker+machine`](https://docs.gitlab.com/runner/executors/docker_machine.html).

## Create new cluster

New clusters can be created using GitLab for:

- [Google Kubernetes Engine (GKE)](add_gke_clusters.md).
- [Amazon Elastic Kubernetes Service (EKS)](add_eks_clusters.md).

## Add existing cluster

If you have an existing Kubernetes cluster, you can add it to a project, group, or instance.

For more information, see information for adding an:

- [Existing Kubernetes cluster](#existing-kubernetes-cluster), including GKE clusters.
- [Existing EKS cluster](add_eks_clusters.md#existing-eks-cluster).

NOTE: **Note:**
Kubernetes integration is not supported for arm64 clusters. See the issue
[Helm Tiller fails to install on arm64 cluster](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/64044) for details.

### Existing Kubernetes cluster

To add a Kubernetes cluster to your project, group, or instance:

1. Navigate to your:
   1. Project's **{cloud-gear}** **Operations > Kubernetes** page, for a project-level cluster.
   1. Group's **{cloud-gear}** **Kubernetes** page, for a group-level cluster.
   1. **{admin}** **Admin Area >** **{cloud-gear}** **Kubernetes** page, for an instance-level cluster.
1. Click **Add Kubernetes cluster**.
1. Click the **Add existing cluster** tab and fill in the details:
   1. **Kubernetes cluster name** (required) - The name you wish to give the cluster.
   1. **Environment scope** (required) - The
      [associated environment](index.md#setting-the-environment-scope-premium) to this cluster.
   1. **API URL** (required) -
      It's the URL that GitLab uses to access the Kubernetes API. Kubernetes
      exposes several APIs, we want the "base" URL that is common to all of them.
      For example, `https://kubernetes.example.com` rather than `https://kubernetes.example.com/api/v1`.

      Get the API URL by running this command:

      ```shell
      kubectl cluster-info | grep 'Kubernetes master' | awk '/http/ {print $NF}'
      ```

   1. **CA certificate** (required) - A valid Kubernetes certificate is needed to authenticate to the cluster. We will use the certificate created by default.
      1. List the secrets with `kubectl get secrets`, and one should be named similar to
         `default-token-xxxxx`. Copy that token name for use below.
      1. Get the certificate by running this command:

         ```shell
         kubectl get secret <secret name> -o jsonpath="{['data']['ca\.crt']}" | base64 --decode
         ```

         NOTE: **Note:**
         If the command returns the entire certificate chain, you need copy the *root ca*
         certificate at the bottom of the chain.

   1. **Token** -
      GitLab authenticates against Kubernetes using service tokens, which are
      scoped to a particular `namespace`.
      **The token used should belong to a service account with
      [`cluster-admin`](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#user-facing-roles)
      privileges.** To create this service account:
      1. Create a file called `gitlab-admin-service-account.yaml` with contents:

         ```yaml
         apiVersion: v1
         kind: ServiceAccount
         metadata:
           name: gitlab-admin
           namespace: kube-system
         ---
         apiVersion: rbac.authorization.k8s.io/v1beta1
         kind: ClusterRoleBinding
         metadata:
           name: gitlab-admin
         roleRef:
           apiGroup: rbac.authorization.k8s.io
           kind: ClusterRole
           name: cluster-admin
         subjects:
         - kind: ServiceAccount
           name: gitlab-admin
           namespace: kube-system
         ```

      1. Apply the service account and cluster role binding to your cluster:

         ```shell
         kubectl apply -f gitlab-admin-service-account.yaml
         ```

         You will need the `container.clusterRoleBindings.create` permission
         to create cluster-level roles. If you do not have this permission,
         you can alternatively enable Basic Authentication and then run the
         `kubectl apply` command as an admin:

         ```shell
         kubectl apply -f gitlab-admin-service-account.yaml --username=admin --password=<password>
         ```

         NOTE: **Note:**
         Basic Authentication can be turned on and the password credentials
         can be obtained using the Google Cloud Console.

         Output:

         ```shell
         serviceaccount "gitlab-admin" created
         clusterrolebinding "gitlab-admin" created
         ```

      1. Retrieve the token for the `gitlab-admin` service account:

         ```shell
         kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep gitlab-admin | awk '{print $1}')
         ```

         Copy the `<authentication_token>` value from the output:

         ```yaml
         Name:         gitlab-admin-token-b5zv4
         Namespace:    kube-system
         Labels:       <none>
         Annotations:  kubernetes.io/service-account.name=gitlab-admin
                      kubernetes.io/service-account.uid=bcfe66ac-39be-11e8-97e8-026dce96b6e8

         Type:  kubernetes.io/service-account-token

         Data
         ====
         ca.crt:     1025 bytes
         namespace:  11 bytes
         token:      <authentication_token>
         ```

      NOTE: **Note:**
      For GKE clusters, you will need the
      `container.clusterRoleBindings.create` permission to create a cluster
      role binding. You can follow the [Google Cloud
      documentation](https://cloud.google.com/iam/docs/granting-changing-revoking-access)
      to grant access.

   1. **GitLab-managed cluster** - Leave this checked if you want GitLab to manage namespaces and service accounts for this cluster.
      See the [Managed clusters section](index.md#gitlab-managed-clusters) for more information.
   1. **Project namespace** (optional) - You don't have to fill it in; by leaving
      it blank, GitLab will create one for you. Also:
      - Each project should have a unique namespace.
      - The project namespace is not necessarily the namespace of the secret, if
        you're using a secret with broader permissions, like the secret from `default`.
      - You should **not** use `default` as the project namespace.
      - If you or someone created a secret specifically for the project, usually
        with limited permissions, the secret's namespace and project namespace may
        be the same.

1. Finally, click the **Create Kubernetes cluster** button.

After a couple of minutes, your cluster will be ready to go. You can now proceed
to install some [pre-defined applications](index.md#installing-applications).

#### Disable Role-Based Access Control (RBAC) (optional)

When connecting a cluster via GitLab integration, you may specify whether the
cluster is RBAC-enabled or not. This will affect how GitLab interacts with the
cluster for certain operations. If you **did not** check the "RBAC-enabled cluster"
checkbox at creation time, GitLab will assume RBAC is disabled for your cluster
when interacting with it. If so, you must disable RBAC on your cluster for the
integration to work properly.

![rbac](img/rbac.png)

NOTE: **Note**: Disabling RBAC means that any application running in the cluster,
or user who can authenticate to the cluster, has full API access. This is a
[security concern](index.md#security-implications), and may not be desirable.

To effectively disable RBAC, global permissions can be applied granting full access:

```shell
kubectl create clusterrolebinding permissive-binding \
  --clusterrole=cluster-admin \
  --user=admin \
  --user=kubelet \
  --group=system:serviceaccounts
```

## Enabling or disabling integration

After you have successfully added your cluster information, you can enable the
Kubernetes cluster integration:

1. Click the **Enabled/Disabled** switch
1. Hit **Save** for the changes to take effect

To disable the Kubernetes cluster integration, follow the same procedure.

## Removing integration

To remove the Kubernetes cluster integration from your project, either:

- Select **Remove integration**, to remove only the Kubernetes integration.
- [From GitLab 12.6](https://gitlab.com/gitlab-org/gitlab/-/issues/26815), select
  **Remove integration and resources**, to also remove all related GitLab cluster resources (for
  example, namespaces, roles, and bindings) when removing the integration.

When removing the cluster integration, note:

- You need Maintainer [permissions](../../permissions.md) and above to remove a Kubernetes cluster
  integration.
- When you remove a cluster, you only remove its relationship to GitLab, not the cluster itself. To
  remove the cluster, you can do so by visiting the GKE or EKS dashboard, or using `kubectl`.

## Learn more

To learn more on automatically deploying your applications,
read about [Auto DevOps](../../../topics/autodevops/index.md).
