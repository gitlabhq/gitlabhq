---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab-managed clusters (deprecated)
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Disabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/353410) in GitLab 15.0.

{{< /history >}}

{{< alert type="warning" >}}

This feature was [deprecated](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) in GitLab 14.5.
To connect your cluster to GitLab, use the [GitLab agent for Kubernetes](../../clusters/agent/_index.md).
To manage applications, use the [Cluster Project Management Template](../../clusters/management_project_template.md).

{{< /alert >}}

{{< alert type="flag" >}}

On GitLab Self-Managed, by default this feature is not available. To make it available, an administrator can [enable the feature flag](../../../administration/feature_flags/_index.md) named `certificate_based_clusters`.

{{< /alert >}}

You can choose to allow GitLab to manage your cluster for you. If your cluster
is managed by GitLab, resources for your projects are automatically created. See
the [Access controls](cluster_access.md) section for
details about the created resources.

If you choose to manage your own cluster, project-specific resources aren't created
automatically. If you are using [Auto DevOps](../../../topics/autodevops/_index.md), you must
explicitly provide the `KUBE_NAMESPACE` [deployment variable](deploy_to_cluster.md#deployment-variables)
for your deployment jobs to use. Otherwise, a namespace is created for you.

{{< alert type="warning" >}}

Be aware that manually managing resources that have been created by GitLab, like
namespaces and service accounts, can cause unexpected errors. If this occurs, try
[clearing the cluster cache](#clearing-the-cluster-cache).

{{< /alert >}}

## Clearing the cluster cache

If you allow GitLab to manage your cluster, GitLab stores a cached
version of the namespaces and service accounts it creates for your projects. If you
modify these resources in your cluster manually, this cache can fall out of sync with
your cluster. This can cause deployment jobs to fail.

To clear the cache:

1. Go to your project's **Operate > Kubernetes clusters** page, and select your cluster.
1. Expand the **Advanced settings** section.
1. Select **Clear cluster cache**.

## Base domain

Specifying a base domain automatically sets `KUBE_INGRESS_BASE_DOMAIN` as a deployment variable.
If you are using [Auto DevOps](../../../topics/autodevops/_index.md), this domain is used for the different
stages. For example, Auto Review Apps and Auto Deploy.

The domain should have a wildcard DNS configured to the Ingress IP address.
You can either:

- Create an `A` record that points to the Ingress IP address with your domain provider.
- Enter a wildcard DNS address using a service such as `nip.io` or `xip.io`. For example, `192.168.1.1.xip.io`.

To determine the external Ingress IP address, or external Ingress hostname:

- If the cluster is on GKE:
  1. Select the **Google Kubernetes Engine** link in the **Advanced settings**,
     or go directly to the [Google Kubernetes Engine dashboard](https://console.cloud.google.com/kubernetes/).
  1. Select the proper project and cluster.
  1. Select **Connect**.
  1. Execute the `gcloud` command in a local terminal or using the **Cloud Shell**.

- If the cluster is not on GKE: Follow the specific instructions for your
  Kubernetes provider to configure `kubectl` with the right credentials.
  The output of the following examples show the external endpoint of your
  cluster. This information can then be used to set up DNS entries and forwarding
  rules that allow external access to your deployed applications.

Depending on your Ingress, the external IP address can be retrieved in various ways.
This list provides a generic solution, and some GitLab-specific approaches:

- In general, you can list the IP addresses of all load balancers by running:

  ```shell
  kubectl get svc --all-namespaces -o jsonpath='{range.items[?(@.status.loadBalancer.ingress)]}{.status.loadBalancer.ingress[*].ip} '
  ```

- If you installed Ingress using the **Applications**, run:

  ```shell
  kubectl get service --namespace=gitlab-managed-apps ingress-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
  ```

- Some Kubernetes clusters return a hostname instead, like
  [Amazon EKS](https://aws.amazon.com/eks/). For these platforms, run:

  ```shell
  kubectl get service --namespace=gitlab-managed-apps ingress-nginx-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
  ```

  If you use EKS, an [Elastic Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/)
  is also created, which incurs additional AWS costs.

- Istio/Knative uses a different command. Run:

  ```shell
  kubectl get svc --namespace=istio-system istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip} '
  ```

If you see a trailing `%` on some Kubernetes versions, do not include it.
