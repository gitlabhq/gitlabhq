---
stage: Configure
group: Configure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Add a cluster using cluster certificates (DEPRECATED) **(FREE)**

> [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/327908) in GitLab 14.0.

WARNING:
Creating a new cluster or adding an existing cluster to GitLab through the certificate-based method
is deprecated and no longer recommended. Kubernetes cluster, similar to any other
infrastructure, should be created, updated, maintained using [Infrastructure as Code](../../infrastructure/index.md).
GitLab is developing a built-in capability to create clusters with Terraform.
You can follow along in this [epic](https://gitlab.com/groups/gitlab-org/-/epics/6049).

NOTE:
Every new Google Cloud Platform (GCP) account receives
[$300 in credit upon sign up](https://console.cloud.google.com/freetrial).
In partnership with Google, GitLab is able to offer an additional $200 for new GCP
accounts to get started with the GitLab integration with Google Kubernetes Engine.
[Follow this link](https://cloud.google.com/partners/partnercredit/?pcn_code=0014M00001h35gDQAQ#contact-form)
to apply for credit.

NOTE:
Watch the webcast [Scalable app deployment with GitLab and Google Cloud Platform](https://about.gitlab.com/webcast/scalable-app-deploy/)
and learn how to spin up a Kubernetes cluster managed by Google Cloud Platform (GCP)
in a few clicks.

## Create new cluster

> The certificate-based method for creating clusters from GitLab was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/327908) in GitLab 14.0.

As of GitLab 14.0, use [Infrastructure as Code](../../infrastructure/index.md)
to **safely create your new cluster from GitLab**.

The certificate-based method is **deprecated** and scheduled for removal in
GitLab 15.0. However, you can still use it until then. Through
this method, you can host your cluster in EKS, GKE, on premises, and with other
providers. To host them on premises and with other providers,
use either the EKS or GKE method to guide you through and enter your cluster's
settings manually:

- [New cluster hosted on Google Kubernetes Engine (GKE)](add_eks_clusters.md).
- [New cluster hosted on Amazon Elastic Kubernetes Service (EKS)](add_gke_clusters.md).

## Add existing cluster

If you already have a cluster and want to integrate it with GitLab, see how to
[add an existing cluster](add_existing_cluster.md).

## Configure your cluster

As of GitLab 14.0, use the [GitLab Kubernetes Agent](../../clusters/agent/index.md) to configure your cluster.

## Disable a cluster

When you successfully create a new Kubernetes cluster or add an existing
one to GitLab, the cluster connection to GitLab becomes enabled. To disable it:

1. Go to your:
   - Project's **{cloud-gear}** **Infrastructure > Kubernetes clusters** page, for a project-level cluster.
   - Group's **{cloud-gear}** **Kubernetes** page, for a group-level cluster.
   - **Menu >** **{admin}** **Admin >** **{cloud-gear}** **Kubernetes** page, for an instance-level cluster.
1. Select the name of the cluster you want to disable.
1. Toggle **GitLab Integration** off (in gray).
1. Click **Save changes**.

## Remove a cluster

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/26815) in GitLab 12.6, you can remove cluster integrations and resources.

When you remove a cluster integration, you only remove the cluster relationship
to GitLab, not the cluster. To remove the cluster itself, visit your cluster's
GKE or EKS dashboard to do it from their UI or use `kubectl`.

You need at least Maintainer [permissions](../../permissions.md) to your
project or group to remove the integration with GitLab.

When removing a cluster integration, you have two options:

- **Remove integration**: remove only the Kubernetes integration.
- **Remove integration and resources**: remove the cluster integration and
all GitLab cluster-related resources such as namespaces, roles, and bindings.

To remove the Kubernetes cluster integration:

1. Go to your cluster details page.
1. Select the **Advanced Settings** tab.
1. Select either **Remove integration** or **Remove integration and resources**.

## Access controls

See [cluster access controls (RBAC or ABAC)](cluster_access.md).

## Troubleshooting

### There was a problem authenticating with your cluster. Please ensure your CA Certificate and Token are valid

If you encounter this error while adding a Kubernetes cluster, ensure you're
properly pasting the service token. Some shells may add a line break to the
service token, making it invalid. Ensure that there are no line breaks by
pasting your token into an editor and removing any additional spaces.

You may also experience this error if your certificate is not valid. To check that your certificate's
subject alternative names contain the correct domain for your cluster's API, run this:

```shell
echo | openssl s_client -showcerts -connect kubernetes.example.com:443 2>/dev/null |
openssl x509 -inform pem -noout -text
```

Note that the `-connect` argument expects a `host:port` combination. For example, `https://kubernetes.example.com` would be `kubernetes.example.com:443`.
