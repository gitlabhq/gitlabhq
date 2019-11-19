# Kubernetes integration - development guidelines

This document provides various guidelines when developing for GitLab's
[Kubernetes integration](../user/project/clusters/index.md).

## Development

### Architecture

Some Kubernetes operations, such as creating restricted project
namespaces are performed on the GitLab Rails application. These
operations are performed using a [client library](#client-library).
These operations will carry an element of risk as the operations will be
run as the same user running the GitLab Rails application, see the
[security](#security) section below.

Some Kubernetes operations, such as installing cluster applications are
performed on one-off pods on the Kubernetes cluster itself. These
installation pods are currently named `install-<application_name>` and
are created within the `gitlab-managed-apps` namespace.

In terms of code organization, we generally add objects that represent
Kubernetes resources in
[`lib/gitlab/kubernetes`](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/lib/gitlab/kubernetes).

### Client library

We use the [`kubeclient`](https://rubygems.org/gems/kubeclient) gem to
perform Kubernetes API calls. As the `kubeclient` gem does not support
different API Groups (e.g. `apis/rbac.authorization.k8s.io`) from a
single client, we have created a wrapper class,
[`Gitlab::Kubernetes::KubeClient`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/kubernetes/kube_client.rb)
that will enable you to achieve this.

Selected Kubernetes API groups are currently supported. Do add support
for new API groups or methods to
[`Gitlab::Kubernetes::KubeClient`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/kubernetes/kube_client.rb)
if you need to use them. New API groups or API group versions can be
added to `SUPPORTED_API_GROUPS` - internally, this will create an
internal client for that group. New methods can be added as a delegation
to the relevant internal client.

### Performance considerations

All calls to the Kubernetes API must be in a background process. Do not
perform Kubernetes API calls within a web request as this will block
Unicorn and can easily lead to a Denial Of Service (DoS) attack in GitLab as
the Kubernetes cluster response times are outside of our control.

The easiest way to ensure your calls happen a background process is to
delegate any such work to happen in a [Sidekiq worker](sidekiq_style_guide.md).

There are instances where you would like to make calls to Kubernetes and
return the response and as such a background worker does not seem to be
a good fit. For such cases you should make use of [reactive
caching](https://gitlab.com/gitlab-org/gitlab/blob/master/app/models/concerns/reactive_caching.rb).
For example:

```ruby
  def calculate_reactive_cache!
    { pods: cluster.platform_kubernetes.kubeclient.get_pods }
  end

  def pods
    with_reactive_cache do |data|
      data[:pods]
    end
  end
```

### Testing

We have some Webmock stubs in
[`KubernetesHelpers`](https://gitlab.com/gitlab-org/gitlab/blob/master/spec/support/helpers/kubernetes_helpers.rb)
which can help with mocking out calls to Kubernetes API in your tests.

### Amazon EKS integration

This section outlines the process for allowing a GitLab instance to create EKS clusters.

The following prerequisites are required:

A `Customer` AWS account. This is the account in which the
EKS cluster will be created. The following resources must be present:

- A provisioning role that has permissions to create the cluster
  and associated resources. It must list the `GitLab` AWS account
  as a trusted entity.
- A VPC, management role, security group, and subnets for use by the cluster.

A `GitLab` AWS account. This is the account which performs
the provisioning actions. The following resources must be present:

- A service account with permissions to assume the provisioning
  role in the `Customer` account above.
- Credentials for this service account configured in GitLab via
  the `kubernetes` section of `gitlab.yml`.

The process for creating a cluster is as follows:

1. Using the `:provision_role_external_id`, GitLab assumes the role provided
   by `:provision_role_arn` and stores a set of temporary credentials on the
   provider record. By default these credentials are valid for one hour.
1. A CloudFormation stack is created, based on the
   [`AWS CloudFormation EKS template`](https://gitlab.com/gitlab-org/gitlab/blob/master/vendor/aws/cloudformation/eks_cluster.yaml).
   This triggers creation of all resources required for an EKS cluster.
1. GitLab polls the status of the stack until all resources are ready,
   which takes somewhere between 10 and 15 minutes in most cases.
1. When the stack is ready, GitLab stores the cluster details and generates
   another set of temporary credentials, this time to allow connecting to
   the cluster via Kubeclient. These credentials are valid for one minute.
1. GitLab configures the worker nodes so that they are able to authenticate
   to the cluster, and creates a service account for itself for future operations.
1. Credentials that are no longer required are removed. This deletes the following
   attributes:

   - `access_key_id`
   - `secret_access_key`
   - `session_token`

## Security

### SSRF

As URLs for Kubernetes clusters are user controlled it is easily
susceptible to Server Side Request Forgery (SSRF) attacks. You should
understand the mitigation strategies if you are adding more API calls to
a cluster.

Mitigation strategies include:

1. Not allowing redirects to attacker controller resources:
   [`Kubeclient::KubeClient`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/kubernetes/kube_client.rb#)
   can be configured to disallow any redirects by passing in
   `http_max_redirects: 0` as an option.
1. Not exposing error messages: by doing so, we
   prevent attackers from triggering errors to expose results from
   attacker controlled requests. For example, we do not expose (or store)
   raw error messages:

   ```ruby
   rescue Kubernetes::HttpError => e
     # bad
     # app.make_errored!("Kubernetes error: #{e.message}")

     # good
     app.make_errored!("Kubernetes error: #{e.error_code}")
   ```

## Debugging

Logs related to the Kubernetes integration can be found in
[`kubernetes.log`](../administration/logs.md#kuberneteslog). On a local
GDK install, this will be present in `log/kubernetes.log`.

Some services such as
[`Clusters::Applications::InstallService`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/services/clusters/applications/install_service.rb#L18)
rescues `StandardError` which can make it harder to debug issues in an
development environment. The current workaround is to temporarily
comment out the `rescue` in your local development source.

You can also follow the installation pod logs to debug issues related to
installation. Once the installation/upgrade is underway, wait for the
pod to be created. Then run the following to obtain the pods logs as
they are written:

```bash
kubectl logs <pod_name> --follow -n gitlab-managed-apps
```

## GitLab Managed Apps

GitLab provides [GitLab Managed Apps](../user/clusters/applications.html), a one-click install for various applications which can be added directly to your configured cluster.

**<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of how to add a new GitLab-mananged app, see [How to add GitLab-managed-apps to Kubernetes integration](https://youtu.be/mKm-jkranEk).**
