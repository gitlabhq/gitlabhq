# GitLab Kubernetes / OpenShift integration

GitLab can be configured to interact with Kubernetes, or other systems using the
Kubernetes API (such as OpenShift).

Each project can be configured to connect to a different Kubernetes cluster, see
the [configuration](#configuration) section.

If you have a single cluster that you want to use for all your projects,
you can pre-fill the settings page with a default template. To configure the
template, see the [Services Templates](services_templates.md) document.

## Configuration

Navigate to the [Integrations page](project_services.md#accessing-the-project-services)
of your project and select the **Kubernetes** service to configure it.

![Kubernetes configuration settings](img/kubernetes_configuration.png)

The Kubernetes service takes the following arguments:

1. API URL
1. Custom CA bundle
1. Kubernetes namespace
1. Service token

The API URL is the URL that GitLab uses to access the Kubernetes API. Kubernetes
exposes several APIs - we want the "base" URL that is common to all of them,
e.g., `https://kubernetes.example.com` rather than `https://kubernetes.example.com/api/v1`.

A [namespace] is just a logical grouping of resources. This is mostly for ease of
management, so you can group things together. For example, if you have 50
projects using the same cluster, providing a simple list of all pods would be
really difficult to work with. In that case, you can provide a separate
namespace to group things, as well as reduce name collision issues.

GitLab authenticates against Kubernetes using service tokens, which are
scoped to a particular `namespace`. If you don't have a service token yet,
you can follow the
[Kubernetes documentation](http://kubernetes.io/docs/user-guide/service-accounts/)
to create one. You can also view or create service tokens in the
[Kubernetes dashboard](http://kubernetes.io/docs/user-guide/ui/) - visit
**Config ➔ Secrets**.

Fill in the service token and namespace according to the values you just got.
If the API is using a self-signed TLS certificate, you'll also need to include
the `ca.crt` contents as the `Custom CA bundle`.

[namespace]: https://kubernetes.io/docs/user-guide/namespaces/

## Deployment variables

The Kubernetes service exposes following
[deployment variables](../../../ci/variables/README.md#deployment-variables) in the
GitLab CI build environment:

- `KUBE_URL` - equal to the API URL
- `KUBE_TOKEN`
- `KUBE_NAMESPACE` - The Kubernetes namespace is auto-generated if not specified.
  The default value is `<project_name>-<project_id>`. You can overwrite it to
  use different one if needed, otherwise the `KUBE_NAMESPACE` variable will
  receive the default value.
- `KUBE_CA_PEM_FILE` - only present if a custom CA bundle was specified. Path
  to a file containing PEM data.
- `KUBE_CA_PEM` (deprecated)- only if a custom CA bundle was specified. Raw PEM data.
- `KUBECONFIG` - Path to a file containing kubeconfig for this deployment. CA bundle would be embedded if specified.

## Web terminals

>**NOTE:**
Added in GitLab 8.15. You must be the project owner or have `master` permissions
to use terminals. Support is currently limited to the first container in the
first pod of your environment.

When enabled, the Kubernetes service adds [web terminal](../../../ci/environments.md#web-terminals)
support to your [environments](../../../ci/environments.md). This is based on the `exec` functionality found in
Docker and Kubernetes, so you get a new shell session within your existing
containers. To use this integration, you should deploy to Kubernetes using
the deployment variables above, ensuring any pods you create are labelled with
`app=$CI_ENVIRONMENT_SLUG`. GitLab will do the rest!
