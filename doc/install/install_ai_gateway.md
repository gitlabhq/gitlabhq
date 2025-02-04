---
stage: AI-Powered
group: AI Framework
description: Set up your self-hosted model GitLab AI gateway
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Install the GitLab AI gateway
---

The [AI gateway](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_gateway/) is a standalone service that gives access to AI-powered GitLab Duo features.

## Install using Docker

Prerequisites:

- Install a Docker container engine, such as [Docker](https://docs.docker.com/engine/install/#server).
- Use a valid hostname accessible within your network. Do not use `localhost`.

The GitLab AI gateway Docker image contains all necessary code and dependencies
in a single container.

The Docker image for the AI gateway is around 340 MB (compressed) for the `linux/amd64` architecture and requires a minimum of 512 MB of RAM to operate. A GPU is not needed for the GitLab AI gateway. To ensure better performance, especially under heavy usage, consider allocating more disk space, memory, and resources than the minimum requirements. Higher RAM and disk capacity can enhance the AI gateway's efficiency during peak loads.

### Find the AI Gateway Release

Find the GitLab official Docker image at:

- AI Gateway Docker image on Container Registry:
  - [Stable](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284)
  - [Nightly](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/8086262)
- AI Gateway Docker image on DockerHub:
  - [Stable](https://hub.docker.com/r/gitlab/model-gateway/tags)
  - [Nightly](https://hub.docker.com/r/gitlab/model-gateway-self-hosted/tags)
- [Release process for self-hosted AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/release.md).

Use the image tag that corresponds to your GitLab version. For example, if your GitLab version is `v17.6.0`, use the `self-hosted-17.6.0-ee` tag. It is critical to ensure that the image version matches your GitLab version to avoid compatibility issues. Nightly builds are available to have access to newer features, but backwards compatibility is not guaranteed.

NOTE:
Using the `:latest` tag is **not recommended** as it can cause incompatibility if your GitLab version lags behind or jumps ahead of the AI Gateway release. Always use an explicit version tag.

### Start a Container from the Image

1. For Docker images with version `self-hosted-v17.6.0-ee` and later, run the following command, replacing `<your_gitlab_instance>` and `<your_gitlab_domain>` with your GitLab instance's URL and domain:

   ```shell
   docker run -d -p 5052:5052 \
    -e AIGW_GITLAB_URL=<your_gitlab_instance> \
    -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
    registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v17.6.0-ee \
    ```

   Replace `self-hosted-v17.6.0-ee` with the version that matches your GitLab instance. For example, if your GitLab version is `v17.7.0`, use `self-hosted-v17.7.0-ee`.
   From the container host, accessing `http://localhost:5052/docs` should open the AI gateway API documentation.

1. Ensure that port `5052` is forwarded to the container from the host and is included in the `AI_GATEWAY_URL` environment variable.

If you encounter issues loading the PEM file, resulting in errors like `JWKError`, you may need to resolve an SSL certificate error.

To fix this, set the appropriate certificate bundle path in the Docker container by using the following environment variables:

- `SSL_CERT_FILE=/path/to/ca-bundle.pem`
- `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

Replace `/path/to/ca-bundle.pem` with the actual path to your certificate bundle.

## Install using the AI gateway Helm chart

Prerequisites:

- You must have a:
  - Domain you own, to which you can add a DNS record.
  - Kubernetes cluster.
  - Working installation of `kubectl`.
  - Working installation of Helm, version v3.11.0 or later.

For more information, see [Test the GitLab chart on GKE or EKS](https://docs.gitlab.com/charts/quickstart/index.html).

### Add the AI gateway Helm repository

Add the AI gateway Helm repository to Helm’s configuration:

```shell
helm repo add ai-gateway \
https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
```

### Install the AI gateway

1. Create the `ai-gateway` namespace:

   ```shell
   kubectl create namespace ai-gateway
   ```

1. Generate the certificate for the domain where you plan to expose the AI gateway.
1. Create the TLS secret in the previously created namespace:

   ```shell
   kubectl -n ai-gateway create secret tls ai-gateway-tls --cert="<path_to_cert>" --key="<path_to_cert_key>"
   ```

1. For the AI gateway to access the API, it must know where the GitLab instance
   is located. To do this, set the `gitlab.url` and `gitlab.apiUrl` together with
   the `ingress.hosts` and `ingress.tls` values as follows:

   ```shell
   helm repo add ai-gateway \
     https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
   helm repo update

   helm upgrade --install ai-gateway \
     ai-gateway/ai-gateway \
     --version 0.2.0 \
     --namespace=ai-gateway \
     --set="image.tag=<ai-gateway-image>" \
     --set="gitlab.url=https://<your_gitlab_domain>" \
     --set="gitlab.apiUrl=https://<your_gitlab_domain>/api/v4/" \
     --set "ingress.enabled=true" \
     --set "ingress.hosts[0].host=<your_gateway_domain>" \
     --set "ingress.hosts[0].paths[0].path=/" \
     --set "ingress.hosts[0].paths[0].pathType=ImplementationSpecific" \
     --set "ingress.tls[0].secretName=ai-gateway-tls" \
     --set "ingress.tls[0].hosts[0]=<your_gateway_domain>" \
     --set="ingress.className=nginx" \
     --timeout=300s --wait --wait-for-jobs
   ```

This step can take will take a few seconds in order for all resources to be allocated
and the AI gateway to start.

You might need to set up your own **Ingress Controller** for the AI gateway if your existing `nginx` Ingress controller does not serve services in a different namespace. Make sure Ingress is set up correctly for multi-namespace deployments.

For versions of the `ai-gateway` Helm chart, use `helm search repo ai-gateway --versions` to find the appropriate chart version.

Wait for your pods to get up and running:

```shell
kubectl wait pod \
  --all \
  --for=condition=Ready \
  --namespace=ai-gateway \
  --timeout=300s
```

When your pods are up and running, you can set up your IP ingresses and DNS records.

## Upgrade the AI gateway Docker image

To upgrade the AI gateway, download the newest Docker image tag.

1. Stop the running container:

   ```shell
   sudo docker stop gitlab-aigw
   ```

1. Remove the existing container:

   ```shell
   sudo docker rm gitlab-aigw
   ```

1. Pull and [run the new image](#start-a-container-from-the-image).

1. Ensure that the environment variables are all set correctly.

## Alternative installation methods

For information on alternative ways to install the AI gateway, see
[issue 463773](https://gitlab.com/gitlab-org/gitlab/-/issues/463773).

## Health Check and Debugging

To debug issues with your self-hosted Duo installation, run the following command:

```shell
sudo gitlab-rake gitlab:duo:verify_self_hosted_setup
```

Ensure that:

- The environment variable `AI_GATEWAY_URL` is correctly set.
- Duo access has been explicitly enabled for the root user through `/admin/code_suggestions`.

If access issues persist, check that authentication is correctly configured, and that the health check passes.

In case of persistent issues, the error message may suggest bypassing authentication with `AIGW_AUTH__BYPASS_EXTERNAL=true`, but only do this for troubleshooting.

You can also run a [health check](../user/gitlab_duo/setup.md#run-a-health-check-for-gitlab-duo) by going to **Admin > GitLab Duo**.

These tests are performed for offline environments:

| Test | Description |
|-----------------|-------------|
| Network | Tests whether: <br>- The environment variable `AI_GATEWAY_URL` has been set to a valid URL.<br> - Your instance can connect to the URL specified by `AI_GATEWAY_URL`.<br><br>If your instance cannot connect to the URL, ensure that your firewall or proxy server settings [allow connection](../user/gitlab_duo/setup.md). |
| License | Tests whether your license has the ability to access Code Suggestions feature. |
| System exchange | Tests whether Code Suggestions can be used in your instance. If the system exchange assessment fails, users might not be able to use GitLab Duo features. |

## Does the AIGW need to autoscale?

Autoscaling is not mandatory but is recommended for environments with variable workloads, high concurrency requirements, or unpredictable usage patterns. In GitLab’s production environment:

- Baseline Setup: A single AI Gateway instance with 2 CPU cores and 8 GB RAM can handle approximately 40 concurrent requests.
- Scaling Guidelines: For larger setups, such as an AWS t3.2xlarge instance (8 vCPUs, 32 GB RAM), the gateway can handle up to 160 concurrent requests, equivalent to 4x the baseline setup.
- Request Throughput: GitLab.com’s observed usage suggests that 7 RPS (requests per second) per 1000 active users is a reasonable metric for planning.
- Autoscaling Options: Use Kubernetes Horizontal Pod Autoscalers (HPA) or similar mechanisms to dynamically adjust the number of instances based on metrics like CPU, memory utilization, or request latency thresholds.

## Configuration Examples by Deployment Size

- Small Deployment:
  - Single instance with 2 vCPUs and 8 GB RAM.
  - Handles up to 40 concurrent requests.
  - Teams or organizations with up to 50 users and predictable workloads.
  - Fixed instances may suffice; autoscaling can be disabled for cost efficiency.
- Medium Deployment:
  - Single AWS t3.2xlarge instance with 8 vCPUs and 32 GB RAM.
  - Handles up to 160 concurrent requests.
  - Organizations with 50-200 users and moderate concurrency requirements.
  - Implement Kubernetes HPA with thresholds for 50% CPU utilization or request latency above 500ms.
- Large Deployment:
  - Cluster of multiple AWS t3.2xlarge instances or equivalent.
  - Each instance handles 160 concurrent requests, scaling to thousands of users with multiple instances.
  - Enterprises with over 200 users and variable, high-concurrency workloads.
  - Use HPA to scale pods based on real-time demand, combined with node autoscaling for cluster-wide resource adjustments.

## What specs does the AIGW container have access to, and how does resource allocation affect performance?

The AI Gateway operates effectively under the following resource allocations:

- 2 CPU cores and 8 GB of RAM per container.
- Containers typically utilize about 7.39% CPU and proportionate memory in GitLab’s production environment, leaving room for growth or handling burst activity.

## Mitigation Strategies for Resource Contention

- Use Kubernetes resource requests and limits to ensure AIGW containers receive guaranteed CPU and memory allocations. For example:

```yaml
resources:
  requests:
    memory: "16Gi"
    cpu: "4"
  limits:
    memory: "32Gi"
    cpu: "8"
```

- Implement tools like Prometheus and Grafana to track resource utilization (CPU, memory, latency) and detect bottlenecks early.
- Dedicate nodes or instances exclusively to the AI Gateway to prevent resource competition with other services.

## Scaling Strategies

- Use Kubernetes HPA to scale pods based on real-time metrics like:
  - Average CPU utilization exceeding 50%.
  - Request latency consistently above 500ms.
  - Enable node autoscaling to scale infrastructure resources dynamically as pods increase.

## Scaling Recommendations

| Deployment Size | Instance Type      | Resources             | Capacity (Concurrent Requests) | Scaling Recommendations                     |
|------------------|--------------------|------------------------|---------------------------------|---------------------------------------------|
| Small            | 2 vCPUs, 8 GB RAM | Single instance        | 40                              | Fixed deployment; no autoscaling.           |
| Medium           | AWS t3.2xlarge    | Single instance     | 160                             | HPA based on CPU or latency thresholds.     |
| Large            | Multiple t3.2xlarge | Clustered instances   | 160 per instance               | HPA + node autoscaling for high demand.     |
