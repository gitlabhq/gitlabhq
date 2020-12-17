---
stage: Monitor
group: Health
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Prometheus integration

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/8935) in GitLab 9.0.

GitLab offers powerful integration with [Prometheus](https://prometheus.io) for monitoring key metrics of your apps, directly within GitLab.
Metrics for each environment are retrieved from Prometheus, and then displayed
within the GitLab interface.

![Environment Dashboard](img/prometheus_dashboard.png)

There are two ways to set up Prometheus integration, depending on where your apps are running:

- For deployments on Kubernetes, GitLab can automatically [deploy and manage Prometheus](#managed-prometheus-on-kubernetes).
- For other deployment targets, simply [specify the Prometheus server](#manual-configuration-of-prometheus).

Once enabled, GitLab detects metrics from known services in the [metric library](prometheus_library/index.md). You can also [add your own metrics](../../../operations/metrics/index.md#adding-custom-metrics) and create
[custom dashboards](../../../operations/metrics/dashboards/index.md).

## Enabling Prometheus Integration

### Managed Prometheus on Kubernetes

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/28916) in GitLab 10.5.

GitLab can seamlessly deploy and manage Prometheus on a [connected Kubernetes cluster](../clusters/index.md), making monitoring of your apps easy.

#### Requirements

- A [connected Kubernetes cluster](../clusters/index.md)

#### Getting started

Once you have a connected Kubernetes cluster, deploying a managed Prometheus is as easy as a single click.

1. Go to the **Operations > Kubernetes** page to view your connected clusters
1. Select the cluster you would like to deploy Prometheus to
1. Click the **Install** button to deploy Prometheus to the cluster

![Managed Prometheus Deploy](img/prometheus_deploy.png)

#### About managed Prometheus deployments

Prometheus is deployed into the `gitlab-managed-apps` namespace, using the [official Helm chart](https://github.com/helm/charts/tree/master/stable/prometheus). Prometheus is only accessible within the cluster, with GitLab communicating through the [Kubernetes API](https://kubernetes.io/docs/concepts/overview/kubernetes-api/).

The Prometheus server [automatically detects and monitors](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config) nodes, pods, and endpoints. To configure a resource to be monitored by Prometheus, simply set the following [Kubernetes annotations](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/):

- `prometheus.io/scrape` to `true` to enable monitoring of the resource.
- `prometheus.io/port` to define the port of the metrics endpoint.
- `prometheus.io/path` to define the path of the metrics endpoint. Defaults to `/metrics`.

CPU and Memory consumption is monitored, but requires [naming conventions](prometheus_library/kubernetes.md#specifying-the-environment) in order to determine the environment. If you are using [Auto DevOps](../../../topics/autodevops/index.md), this is handled automatically.

The [NGINX Ingress](../clusters/index.md#installing-applications) that is deployed by GitLab to clusters, is automatically annotated for monitoring providing key response metrics: latency, throughput, and error rates.

##### Example of Kubernetes service annotations and labels

As an example, to activate Prometheus monitoring of a service:

1. Add at least this annotation: `prometheus.io/scrape: 'true'`.
1. Add two labels so GitLab can retrieve metrics dynamically for any environment:
   - `application: ${CI_ENVIRONMENT_SLUG}`
   - `release: ${CI_ENVIRONMENT_SLUG}`
1. Create a dynamic PromQL query. For example, a query like
   `temperature{application="{{ci_environment_slug}}",release="{{ci_environment_slug}}"}` to either:
   - Add [custom metrics](../../../operations/metrics/index.md#adding-custom-metrics).
   - Add [custom dashboards](../../../operations/metrics/dashboards/index.md).

The following is a service definition to accomplish this:

```yaml
---
# Service
apiVersion: v1
kind: Service
metadata:
  name: service-${CI_PROJECT_NAME}-${CI_COMMIT_REF_SLUG}
  # === Prometheus annotations ===
  annotations:
    prometheus.io/scrape: 'true'
  labels:
    application: ${CI_ENVIRONMENT_SLUG}
    release: ${CI_ENVIRONMENT_SLUG}
  # === End of Prometheus ===
spec:
  selector:
    app: ${CI_PROJECT_NAME}
  ports:
    - port: ${EXPOSED_PORT}
      targetPort: ${CONTAINER_PORT}
```

#### Access the UI of a Prometheus managed application in Kubernetes

You can connect directly to Prometheus, and view the Prometheus user interface, when
using a Prometheus managed application in Kubernetes:

1. Find the name of the Prometheus pod in the user interface of your Kubernetes
   provider, such as GKE, or by running the following `kubectl` command in your
   terminal:

   ```shell
   kubectl get pods -n gitlab-managed-apps | grep 'prometheus-prometheus-server'
   ```

   The command should return a result like the following example, where
   `prometheus-prometheus-server-55b4bd64c9-dpc6b` is the name of the Prometheus pod:

   ```plaintext
   gitlab-managed-apps  prometheus-prometheus-server-55b4bd64c9-dpc6b  2/2  Running  0  71d
   ```

1. Run a `kubectl port-forward` command. In the following example, `9090` is the
   Prometheus server's listening port:

   ```shell
    kubectl port-forward prometheus-prometheus-server-55b4bd64c9-dpc6b 9090:9090 -n gitlab-managed-apps
   ```

   The `port-forward` command forwards all requests sent to your system's `9090` port
   to the `9090` port of the Prometheus pod. If the `9090` port on your system is used
   by another application, you can change the port number before the colon to your
   desired port. For example, to forward port `8080` of your local system, change the
   command to:

   ```shell
   kubectl port-forward prometheus-prometheus-server-55b4bd64c9-dpc6b 8080:9090 -n gitlab-managed-apps
   ```

1. Open `localhost:9090` in your browser to display the Prometheus user interface.

#### Script access to Prometheus

You can script the access to Prometheus, extracting the name of the pod automatically like this:

```shell
POD_INFORMATION=$(kubectl get pods -n gitlab-managed-apps | grep 'prometheus-prometheus-server')
POD_NAME=$(echo $POD_INFORMATION | awk '{print $1;}')
kubectl port-forward $POD_NAME 9090:9090 -n gitlab-managed-apps
```

### Manual configuration of Prometheus

#### Requirements

Integration with Prometheus requires the following:

1. GitLab 9.0 or higher
1. Prometheus must be configured to collect one of the [supported metrics](prometheus_library/index.md)
1. Each metric must be have a label to indicate the environment
1. GitLab must have network connectivity to the Prometheus server

#### Getting started

Installing and configuring Prometheus to monitor applications is fairly straightforward.

1. [Install Prometheus](https://prometheus.io/docs/prometheus/latest/installation/)
1. Set up one of the [supported monitoring targets](prometheus_library/index.md)
1. Configure the Prometheus server to [collect their metrics](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config)

#### Configuration in GitLab

The actual configuration of Prometheus integration within GitLab
requires the domain name or IP address of the Prometheus server you'd like
to integrate with. If the Prometheus resource is secured with Google's Identity-Aware Proxy (IAP),
additional information like Client ID and Service Account credentials can be passed which
GitLab can use to access the resource. More information about authentication from a
service account can be found at Google's documentation for
[Authenticating from a service account](https://cloud.google.com/iap/docs/authentication-howto#authenticating_from_a_service_account).

1. Navigate to the [Integrations page](overview.md#accessing-integrations) at
   **Settings > Integrations**.
1. Click the **Prometheus** service.
1. For **API URL**, provide the domain name or IP address of your server, such as
   `http://prometheus.example.com/` or `http://192.0.2.1/`.
1. (Optional) In **Google IAP Audience Client ID**, provide the Client ID of the
   Prometheus OAuth Client secured with Google IAP.
1. (Optional) In **Google IAP Service Account JSON**, provide the contents of the
   Service Account credentials file that is authorized to access the Prometheus resource.
1. Click **Save changes**.

![Configure Prometheus Service](img/prometheus_manual_configuration_v13_2.png)

#### Thanos configuration in GitLab

You can configure [Thanos](https://thanos.io/) as a drop-in replacement for Prometheus
with GitLab, using the domain name or IP address of the Thanos server you'd like
to integrate with.

1. Navigate to the [Integrations page](overview.md#accessing-integrations).
1. Click the **Prometheus** service.
1. Provide the domain name or IP address of your server, for example `http://thanos.example.com/` or `http://192.0.2.1/`.
1. Click **Save changes**.

### Precedence with multiple Prometheus configurations

12345678901234567890123456789012345678901234567890123456789012345678901234567890
Although you can enable both a [manual configuration](#manual-configuration-of-prometheus)
and [auto configuration](#managed-prometheus-on-kubernetes) of Prometheus, you
can use only one:

- If you have enabled a
  [Prometheus manual configuration](#manual-configuration-of-prometheus)
  and a [managed Prometheus on Kubernetes](#managed-prometheus-on-kubernetes),
  the manual configuration takes precedence and is used to run queries from
  [custom dashboards](../../../operations/metrics/dashboards/index.md) and
  [custom metrics](../../../operations/metrics/index.md#adding-custom-metrics).
- If you have managed Prometheus applications installed on Kubernetes clusters
  at **different** levels (project, group, instance), the order of precedence is described in
  [Cluster precedence](../../instance/clusters/index.md#cluster-precedence).
- If you have managed Prometheus applications installed on multiple Kubernetes
  clusters at the **same** level, the Prometheus application of a cluster with a
  matching [environment scope](../../../ci/environments/index.md#scoping-environments-with-specs) is used.

## Determining the performance impact of a merge

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10408) in GitLab 9.2.
> - GitLab 9.3 added the [numeric comparison](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/27439) of the 30 minute averages.

Developers can view the performance impact of their changes within the merge
request workflow. This feature requires [Kubernetes](prometheus_library/kubernetes.md) metrics.

When a source branch has been deployed to an environment, a sparkline and
numeric comparison of the average memory consumption displays. On the
sparkline, a dot indicates when the current changes were deployed, with up to 30 minutes of
performance data displayed before and after. The comparison shows the difference
between the 30 minute average before and after the deployment. This information
is updated after each commit has been deployed.

Once merged and the target branch has been redeployed, the metrics switches
to show the new environments this revision has been deployed to.

Performance data is available for the duration it is persisted on the
Prometheus server.

![Merge Request with Performance Impact](img/merge_request_performance.png)
