---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab-managed clusters

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/22011) in GitLab 11.5.
> - Became [optional](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/26565) in GitLab 11.11.

You can choose to allow GitLab to manage your cluster for you. If your cluster
is managed by GitLab, resources for your projects are automatically created. See
the [Access controls](add_remove_clusters.md#access-controls) section for
details about the created resources.

If you choose to manage your own cluster, project-specific resources aren't created
automatically. If you are using [Auto DevOps](../../../topics/autodevops/index.md), you must
explicitly provide the `KUBE_NAMESPACE` [deployment variable](deploy_to_cluster.md#deployment-variables)
for your deployment jobs to use. Otherwise, a namespace is created for you.

WARNING:
Be aware that manually managing resources that have been created by GitLab, like
namespaces and service accounts, can cause unexpected errors. If this occurs, try
[clearing the cluster cache](#clearing-the-cluster-cache).

## Clearing the cluster cache

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31759) in GitLab 12.6.

If you allow GitLab to manage your cluster, GitLab stores a cached
version of the namespaces and service accounts it creates for your projects. If you
modify these resources in your cluster manually, this cache can fall out of sync with
your cluster. This can cause deployment jobs to fail.

To clear the cache:

1. Navigate to your project's **Infrastructure > Kubernetes clusters** page, and select your cluster.
1. Expand the **Advanced settings** section.
1. Click **Clear cluster cache**.

## Base domain

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/24580) in GitLab 11.8.

Specifying a base domain automatically sets `KUBE_INGRESS_BASE_DOMAIN` as an deployment variable.
If you are using [Auto DevOps](../../../topics/autodevops/index.md), this domain is used for the different
stages. For example, Auto Review Apps and Auto Deploy.

The domain should have a wildcard DNS configured to the Ingress IP address.
You can either:

- Create an `A` record that points to the Ingress IP address with your domain provider.
- Enter a wildcard DNS address using a service such as `nip.io` or `xip.io`. For example, `192.168.1.1.xip.io`.

To determine the external Ingress IP address, or external Ingress hostname:

- *If the cluster is on GKE*:
  1. Click the **Google Kubernetes Engine** link in the **Advanced settings**,
     or go directly to the [Google Kubernetes Engine dashboard](https://console.cloud.google.com/kubernetes/).
  1. Select the proper project and cluster.
  1. Click **Connect**
  1. Execute the `gcloud` command in a local terminal or using the **Cloud Shell**.

- *If the cluster is not on GKE*: Follow the specific instructions for your
  Kubernetes provider to configure `kubectl` with the right credentials.
  The output of the following examples show the external endpoint of your
  cluster. This information can then be used to set up DNS entries and forwarding
  rules that allow external access to your deployed applications.

Depending an your Ingress, the external IP address can be retrieved in various ways.
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
