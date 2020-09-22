---
stage: Monitor
group: APM
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Working with Prometheus

For more information on working with [Prometheus metrics](prometheus_metrics.md), see
the documentation.

## Access the UI of a Prometheus managed application in Kubernetes

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

## Script access to Prometheus

You can script the access to Prometheus, extracting the name of the pod automatically like this:

```shell
POD_INFORMATION=$(kubectl get pods -n gitlab-managed-apps | grep 'prometheus-prometheus-server')
POD_NAME=$(echo $POD_INFORMATION | awk '{print $1;}')
kubectl port-forward $POD_NAME 9090:9090 -n gitlab-managed-apps
```
