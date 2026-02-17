---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Gateway between GitLab and large language models.
title: Install the GitLab AI Gateway
---

The [AI Gateway](../administration/gitlab_duo/gateway.md)
is a combination of two services that give access to AI-native GitLab Duo features:

- AI Gateway service
- [GitLab Duo Agent Platform service](../user/duo_agent_platform/_index.md)

## Install by using Docker

The GitLab AI Gateway Docker image contains all necessary code and dependencies
in a single container.

Prerequisites:

- Install a Docker container engine, like [Docker](https://docs.docker.com/engine/install/#server).
- Use a valid hostname that is accessible in your network. Do not use `localhost`.
- Ensure you have approximately 340 MB (compressed) for the `linux/amd64` architecture and
  a minimum of 512 MB of RAM.
- Ensure the container has access to at least two CPUs for
  the `ai_gateway` and `duo-workflow-service` services.
- Generate a JWT signing key for GitLab Duo Agent Platform functionality:

  ```shell
  openssl genrsa -out duo_workflow_jwt.key 2048
  ```

  > [!warning]
  > Keep the `duo_workflow_jwt.key` file secure and do not share it publicly. This key is used for signing JWT tokens and must be treated as a sensitive credential.

To ensure better performance, especially under heavy usage, consider allocating
more disk space, memory, and resources than the minimum requirements.
Higher RAM and disk capacity can enhance the AI Gateway's efficiency during peak loads.

A GPU is not needed for the GitLab AI Gateway.

### Find the AI Gateway image

The GitLab official Docker image is available:

- In the container registry:
  - [Stable](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284?orderBy=PUBLISHED_AT&search%5B%5D=self-hosted)
  - [Nightly](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/8086262)
- On DockerHub:
  - [Stable](https://hub.docker.com/r/gitlab/model-gateway/tags)
  - [Nightly](https://hub.docker.com/r/gitlab/model-gateway-self-hosted/tags)

[View the release process for the self-hosted AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/release.md).

If your GitLab version is `vX.Y.*-ee`, use the AI Gateway Docker image with the latest `self-hosted-vX.Y.*-ee` tag. For example, if GitLab is on version `v18.2.1-ee`, and the AI Gateway Docker image has:

- Versions `self-hosted-v18.2.0-ee`, `self-hosted-v18.2.1-ee`, and `self-hosted-v18.2.2-ee`, use `self-hosted-v18.2.2-ee`.
- Versions `self-hosted-v18.2.0-ee` and `self-hosted-v18.2.1-ee`, use `self-hosted-v18.2.1-ee`.
- Only one version, `self-hosted-v18.2.0-ee`, use `self-hosted-v18.2.0-ee`.

Newer features are available from nightly builds, but backwards compatibility is not guaranteed.

> [!note]
> Using the nightly version is **not recommended** because it can cause incompatibility if your GitLab version is behind or ahead of the AI Gateway release. Always use an explicit version tag.

### Start a container from the image

1. Run the following command to start the container:

   ```shell
   docker run -d -p 5052:5052 -p 50052:50052 \
    -e AIGW_GITLAB_URL=<your_gitlab_instance> \
    -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
    -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat duo_workflow_jwt.key)" \
    registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag>
   ```

   Replace the following placeholders:

   - `<your_gitlab_instance>`: Your GitLab instance URL (for example, `https://gitlab.example.com`).
   - `<your_gitlab_domain>`: Your domain (for example, `gitlab.example.com`).
   - `<ai-gateway-tag>`: Version matching your GitLab instance. If your GitLab version is `vX.Y.0`, use `self-hosted-vX.Y.0-ee`.

   From the container host, accessing `http://localhost:5052` should return `{"error":"No authorization header presented"}`.

1. Ensure that ports `5052` and `50052` are forwarded to the container from the host.
   Port `5052` handles HTTP communication for the AI Gateway. Port `50052` handles gRPC
   communication for the GitLab Duo Agent Platform Service.
1. For GitLab instances that use an offline license, in the AIGW container,
   set `-e DUO_WORKFLOW_AUTH__OIDC_CUSTOMER_PORTAL_URL=` (empty string).
   This configuration:
   - Forces the GitLab Duo Workflow Service to authenticate
     exclusively against the local GitLab instance.
   - Eliminates the 20-second delay caused by unreachable CustomersDot calls.
1. Configure the [AI gateway URL](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-local-ai-gateway) and the [GitLab Duo Agent Platform service URL](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform).
1. Configure the `DUO_AGENT_PLATFORM_SERVICE_SECURE` environment variable based on your model setup:
   - If you are using a self-hosted model without TLS, set the `DUO_AGENT_PLATFORM_SERVICE_SECURE` environment variable to `false` in your GitLab instance:

     - For Linux package installations: In `gitlab_rails['env']`, set `'DUO_AGENT_PLATFORM_SERVICE_SECURE' => false`.
     - For self-compiled installations: In `/etc/default/gitlab`, set `export DUO_AGENT_PLATFORM_SERVICE_SECURE=false`.

   - If you are using a [GitLab AI vendor model](../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#gitlab-ai-vendor-models), do not set the `DUO_AGENT_PLATFORM_SERVICE_SECURE` environment variable.

## Set up Docker with NGINX and SSL

> [!note]
> This method of deploying NGINX or Caddy as a reverse proxy is a temporary workaround to support SSL
> until [issue 455854](https://gitlab.com/gitlab-org/gitlab/-/issues/455854)
> is implemented.

To use SSL for an AI Gateway instance, use:

- Docker
- NGINX as a reverse proxy
- Let's Encrypt for SSL certificates

NGINX manages the secure connection with external clients. It decrypts incoming HTTPS requests before
it passes them to the AI Gateway.

Prerequisites:

- Docker and Docker Compose installed
- Registered and configured domain name

### Create configuration files

Start by creating the following files in your working directory.

1. `nginx.conf`:

   ```nginx
   user  nginx;
   worker_processes  auto;
   error_log  /var/log/nginx/error.log warn;
   pid        /var/run/nginx.pid;
   events {
       worker_connections  1024;
   }
   http {
       include       /etc/nginx/mime.types;
       default_type  application/octet-stream;
       log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                         '$status $body_bytes_sent "$http_referer" '
                         '"$http_user_agent" "$http_x_forwarded_for"';
       access_log  /var/log/nginx/access.log  main;
       sendfile        on;
       keepalive_timeout  65;
       include /etc/nginx/conf.d/*.conf;
   }
   ```

1. `default.conf`:

   ```nginx
   # nginx/conf.d/default.conf
   server {
       listen 80;
       server_name _;

       # Forward all requests to the AI Gateway
       location / {
           proxy_pass http://gitlab-ai-gateway:5052;
           proxy_read_timeout 300s;
           proxy_connect_timeout 75s;
           proxy_buffering off;
       }
   }

   server {
       listen 443 ssl;
       server_name _;

       # SSL configuration
       ssl_certificate /etc/nginx/ssl/server.crt;
       ssl_certificate_key /etc/nginx/ssl/server.key;

       # Configuration for self-signed certificates
       ssl_verify_client off;
       ssl_protocols TLSv1.2 TLSv1.3;
       ssl_ciphers HIGH:!aNULL:!MD5;
       ssl_prefer_server_ciphers on;
       ssl_session_cache shared:SSL:10m;
       ssl_session_timeout 10m;

       # Proxy headers
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
       proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
       proxy_set_header X-Forwarded-Proto $scheme;

       # WebSocket support (if needed)
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";

       # Forward all requests to the AI Gateway
       location / {
           proxy_pass http://gitlab-ai-gateway:5052;
           proxy_read_timeout 300s;
           proxy_connect_timeout 75s;
           proxy_buffering off;
       }
   }
   ```

1. `grpc-nginx.conf`:

```nginx
# Configuration for Duo Agent Platform with TLS
events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log debug;

    upstream grpcservers {
        server gitlab-ai-gateway:50052;
    }

    server {
        listen 8443 ssl;
        http2 on;

        ssl_certificate /etc/nginx/ssl/server.crt;
        ssl_certificate_key /etc/nginx/ssl/server.key;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        location / {
            grpc_pass grpc://grpcservers;
            grpc_set_header Host $host;
        }
    }
}
```

### Set up SSL certificate by using Let's Encrypt

To set up an SSL certificate:

- For Docker-based NGINX servers, Certbot
  [provides an automated way to implement Let's Encrypt certificates](https://phoenixnap.com/kb/letsencrypt-docker).
- Alternatively, you can use the [Certbot manual installation](https://eff-certbot.readthedocs.io/en/stable/using.html#manual).

### Create an environment file

Create a `.env` file to store the JWT signing key:

```shell
echo "DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY=\"$(cat duo_workflow_jwt.key)\"" > .env
```

### Create a Docker Compose file

Now create a `docker-compose.yaml` file.

```yaml
services:
  nginx-proxy:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /path/to/nginx.conf:/etc/nginx/nginx.conf:ro
      - /path/to/default.conf:/etc/nginx/conf.d/default.conf:ro
      - /path/to/fullchain.pem:/etc/nginx/ssl/server.crt:ro
      - /path/to/privkey.pem:/etc/nginx/ssl/server.key:ro
    networks:
      - proxy-network
    depends_on:
      - gitlab-ai-gateway

grpc-proxy:
    image: nginx:alpine
    ports:
      - "8443:8443"
    volumes:
      - /path/to/grpc-nginx.conf:/etc/nginx/nginx.conf:ro
      - /path/to/fullchain.pem:/etc/nginx/ssl/server.crt:ro
      - /path/to/privkey.pem:/etc/nginx/ssl/server.key:ro
    networks:
      - proxy-network
    depends_on:
      - gitlab-ai-gateway
    restart: always

  gitlab-ai-gateway:
    image: registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag>
    ports:
      - "50052:50052" # Agent Platform gRPC exposed to the host
    expose:
      - "5052" # Only exposed internally to the proxy network
    environment:
      - AIGW_GITLAB_URL=<your_gitlab_instance>
      - AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/
    env_file:
      - .env
    networks:
      - proxy-network
    restart: always

networks:
  proxy-network:
    driver: bridge
```

### Deploy and validate

To deploy and validate the solution:

1. Start the `nginx` and `AIGW` containers and verify that they're running:

   ```shell
   docker compose up
   docker ps
   ```

1. Configure your [GitLab instance to access the AI Gateway](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-local-ai-gateway).

1. Configure your GitLab instance to access the URL for the [GitLab Duo Agent Platform service](../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform).

1. Perform the health check and confirm that the AI Gateway and Agent Platform are both accessible.

## Install by using Helm chart

Prerequisites:

- You must have a:
  - Domain you own, to which you can add a DNS record.
  - Kubernetes cluster.
  - Working installation of `kubectl`.
  - Working installation of Helm, version v3.11.0 or later.

For more information, see [Test the GitLab chart on GKE or EKS](https://docs.gitlab.com/charts/quickstart/).

### Add the AI Gateway Helm repository

Add the AI Gateway Helm repository to the Helm configuration:

```shell
helm repo add ai-gateway \
https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
```

### Install the AI Gateway

1. Create the `ai-gateway` namespace:

   ```shell
   kubectl create namespace ai-gateway
   ```

1. Generate the certificate for the domain where you plan to expose the AI Gateway.
1. Create the TLS secret in the previously created namespace:

   ```shell
   kubectl -n ai-gateway create secret tls ai-gateway-tls --cert="<path_to_cert>" --key="<path_to_cert_key>"
   ```

1. Get version number of the latest package in the [chart's Package Registry](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/packages).

1. For the AI Gateway to access the API, it must know where the GitLab instance
   is located. To do this, set the `gitlab.url` and `gitlab.apiUrl` together with
   the `ingress.hosts` and `ingress.tls` values as follows:

   ```shell
   helm repo add ai-gateway \
     https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
   helm repo update

   helm upgrade --install ai-gateway \
     ai-gateway/ai-gateway \
     --version <latest-package-in-registery> \
     --namespace=ai-gateway \
     --set="image.tag=<ai-gateway-image-version>" \
     --set="gitlab.url=https://<your_gitlab_domain>" \
     --set="gitlab.apiUrl=https://<your_gitlab_domain>/api/v4/" \
     --set "ingress.enabled=true" \
     --set "ingress.hosts[0].host=<your_gateway_domain>" \
     --set "ingress.hosts[0].paths[0].path=/" \
     --set "ingress.hosts[0].paths[0].pathType=ImplementationSpecific" \
     --set "ingress.tls[0].secretName=ai-gateway-tls" \
     --set "ingress.tls[0].hosts[0]=<your_gateway_domain>" \
     --set="ingress.className=nginx" \
     --set "extraEnvironmentVariables[0].name=DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY" \
     --set "extraEnvironmentVariables[0].value=$(cat duo_workflow_jwt.key)" \
     --timeout=300s --wait --wait-for-jobs
   ```

You can find the list of AI Gateway versions that can be used as `image.tag` in the [container registry](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284?orderBy=PUBLISHED_AT&search%5B%5D=self-hosted).

This step can take a few seconds in order for all resources to be allocated
and the AI Gateway to start.

You might need to set up your own **Ingress Controller** for the AI Gateway if your existing `nginx` Ingress controller does not serve services in a different namespace. Make sure Ingress is set up correctly for multi-namespace deployments.

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

## Connect to a GitLab instance or model endpoint with a self-signed SSL certificate

If your GitLab instance or model endpoint is configured with a self-signed certificate, you must add your root certificate authority (CA) certificate to the AI Gateway's certificate bundle.

To do this, you can either:

- Pass the root CA certificate to the AI Gateway, so authentication succeeds.
- Add the root CA certificate to the AI Gateway container's CA bundle.

### Pass the root CA certificate to the AI Gateway

To pass the root CA certificate to the AI Gateway and make sure that authentication succeeds, set the `REQUESTS_CA_BUNDLE` environment variable. Because GitLab uses [Certifi](https://pypi.org/project/certifi/) for the base trusted CA list, you configure a custom CA bundle as follows:

1. Download the Certifi `cacert.pem` file:

   ```shell
   curl "https://raw.githubusercontent.com/certifi/python-certifi/2024.07.04/certifi/cacert.pem" --output cacert.pem
   ```

1. Append your self-signed root CA certificate to the file. For example, if you used `mkcert` to create your certificate:

   ```shell
   cat "$(mkcert -CAROOT)/rootCA.pem" >> path/to/your/cacert.pem
   ```

1. Set `REQUESTS_CA_BUNDLE` to the path of your `cacert.pem` file. For example, in GDK, add the following to your `$GDK_ROOT/env.runit`:

   ```shell
   export REQUESTS_CA_BUNDLE=/path/to/your/cacert.pem
   ```

### Add the root CA certificate to the AI Gateway container's CA bundle

To allow the AI Gateway to trust a GitLab Self-Managed instance's certificate that is signed by a custom CA, add the root CA certificate to the AI Gateway container's CA bundle.

This method does not allow for changes made to the root CA bundle in later versions of the chart.

To do this for a Helm chart deployment of the AI Gateway:

1. Append the custom root CA certificate to a local file:

   ```shell
   cat customCA-root.crt >> ca-certificates.crt
   ```

1. Copy the `/etc/ssl/certs/ca-certificates.crt` bundle file from the AI Gateway container to the local file:

   ```shell
   kubectl cp -n gitlab ai-gateway-55d697ff9d-j9pc6:/etc/ssl/certs/ca-certificates.crt ca-certificates.crt.
   ```

1. Create a new secret from the local file:

   ```shell
   kubectl create secret generic ca-certificates -n gitlab --from-file=cacertificates.crt=ca-certificates.crt
   ```

1. Use the secret in the chat `values.yml` to define a `volume` and `volumeMount`. This creates the `/tmp/ca-certificates.crt` file in the container:

   ```shell
   volumes:
     - name: cacerts
       secret:
         secretName: ca-certificates
         optional: false

   volumeMounts:
     - name: cacerts
       mountPath: "/tmp"
       readOnly: true
   ```

1. Set the `REQUESTS_CA_BUNDLE` and `SSL_CERT_FILE` environment variables to point to the mounted file:

   ```shell
   extraEnvironmentVariables:
     - name: REQUESTS_CA_BUNDLE
       value: /tmp/ca-certificates.crt
     - name: SSL_CERT_FILE
       value: /tmp/ca-certificates.crt
   ```

1. Redeploy the chart.

[Issue 3](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/issues/3) exists to support this natively in the Helm chart.

#### For a Docker deployment

For a Docker deployment, use the same method. The only difference is that, to mount the local file in the container, use `--volume /root/ca-certificates.crt:/tmp/ca-certificates.crt`.

## Upgrade the AI Gateway Docker image

To upgrade the AI Gateway, download the newest Docker image tag.

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

## Extra installation steps for GitLab Dedicated instances

To access a Self-hosted AI Gateway, see [Self-hosted AI Gateway for GitLab Dedicated instances](../administration/dedicated/configure_instance/_index.md#self-hosted-ai-gateway-for-gitlab-dedicated-instances).

## Security updates and image verification

To ensure you're running the latest security patches, follow these guidelines based on your deployment method.

### For Kubernetes or Helm deployments

The [charts versions](https://gitlab.com/gitlab-org/charts/ai-gateway-helm-chart/-/packages) before 0.7.0 and Kubernetes uses `imagePullPolicy: IfNotPresent` by default, which won't pull updated images if the tag hasn't changed. This means you might miss security patches released under the same version tag.

You should use the following approach that uses image digests:

```shell
# Find the image digest from the container registry
# Use this digest in your Helm install/upgrade command

helm upgrade --install ai-gateway \
  ai-gateway/ai-gateway \
  --set="image.tag=self-hosted-v18.2.1-ee@sha256:abc123..." \
  # ... other flags
```

Alternatively, you can use the `imagePullPolicy` with either of the following approaches:

- Set the `imagePullPolicy` to always:

  ```shell
  helm upgrade --install ai-gateway \
    ai-gateway/ai-gateway \
    --set="image.pullPolicy=Always" \
    # ... other flags
  ```

- Add the `pullPolicy` to your `values.yaml`:

  ```yaml
  image:
    pullPolicy: Always
  ```

To force pulling updates:

```shell
kubectl rollout restart deployment/ai-gateway -n ai-gateway
```

### For Docker deployments

When upgrading, verify that you're pulling the latest image:

```shell
# Check current image digest
docker images --digests | grep ai-assist

# Pull latest version explicitly
docker pull registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:<ai-gateway-tag>

# Verify digest changed
docker images --digests | grep ai-assist
```

To use image digests for immutable deployments:

```shell
docker run -d -p 5052:5052 -p 50052:50052 \
 -e AIGW_GITLAB_URL=<your_gitlab_instance> \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 -e DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat duo_workflow_jwt.key)" \
 registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v18.2.1-ee@sha256:abc123...
```

## Alternative installation methods

For information on alternative ways to install the AI Gateway, see
[issue 463773](https://gitlab.com/gitlab-org/gitlab/-/issues/463773).

## Health check and debugging

To debug issues with your GitLab Duo Self-Hosted installation, run the following command:

```shell
sudo gitlab-rake gitlab:duo:verify_self_hosted_setup
```

Ensure that:

- The AI Gateway URL is correctly configured (through `Ai::Setting.instance.ai_gateway_url`).
- GitLab Duo access has been explicitly enabled for the root user through `/admin/code_suggestions`.

If access issues persist, check that authentication is correctly configured, and that the health check passes.

In case of persistent issues, the error message may suggest bypassing authentication with `AIGW_AUTH__BYPASS_EXTERNAL=true`, but only do this for troubleshooting.

You can also run a [health check](../administration/gitlab_duo/configure/gitlab_self_managed.md#run-a-health-check-for-gitlab-duo) by going to **Admin** > **GitLab Duo**.

These tests are performed for offline environments:

| Test | Description |
|-----------------|-------------|
| Network | Tests whether: <br>- The AI Gateway URL has been properly configured in the database through the `ai_settings` table.<br> - Your instance can connect to the configured URL.<br><br>If your instance cannot connect to the URL, ensure that your firewall or proxy server settings [allow connection](../administration/gitlab_duo/configure/gitlab_self_managed.md). Although the environment variable `AI_GATEWAY_URL` is still supported for legacy compatibility, configuring the URL through the database is recommended for better manageability. |
| License | Tests whether your license has the ability to access Code Suggestions feature. |
| System exchange | Tests whether Code Suggestions can be used in your instance. If the system exchange assessment fails, users might not be able to use GitLab Duo features. |

## Monitor the AI Gateway

Use Prometheus to gather metrics about your AI Gateway usage and performance.

### Set up Prometheus metrics for the AI Gateway

To set up Prometheus metrics:

1. Set the required environment variables and open port `8082`:

   ```shell
   -e AIGW_FASTAPI__METRICS_HOST=0.0.0.0
   -e AIGW_FASTAPI__METRICS_PORT=8082
   ```

### Set up Prometheus for the GitLab Duo Workflow service

To set up Prometheus metrics on the GitLab Duo Workflow service:

1. Set the required environment variables and open port `8083`:

   ```shell
   -e PROMETHEUS_METRICS__ADDR=0.0.0.0
   -e PROMETHEUS_METRICS__PORT=8083
   ```

1. Expose the metrics ports from the `gitlab-ai-gateway` container to the host:

   - For Docker CLI:

     ```shell
     -p 8082:8082 \
     -p 8083:8083 \
     ```

   - For Docker Compose, add to the `gitlab-ai-gateway` service:

     ```shell
     ports:
       - "8082:8082"
       - "8083:8083"
     ```

   This exposes the AI Gateway metrics endpoint on port `8082` and the GitLab Duo Workflow Service metrics endpoint on port `8083`.

1. Restart the AI Gateway container

### Configure Prometheus to scrape metrics

To collect metrics from the AI Gateway and GitLab Duo Workflow service, add the following
`prometheus.yml` configuration to your Prometheus instance. In this configuration, Prometheus
scrapes metrics from both services every 15 seconds.

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'ai-gateway'
    static_configs:
      - targets: ['<your_AIGW_domain>:8082']
    scheme: 'http'
    metrics_path: '/metrics'

  - job_name: 'duo-agent-platform-service'
    static_configs:
      - targets: ['<your_duo_agent_platform_service_domain>:8083']
    scheme: 'http'
    metrics_path: '/metrics'
```

### Verify metrics collection

To verify that the targets for AI Gateway and GitLab Duo Workflow service are being collected:

1. In the Prometheus UI, go to **Status > Targets**.
1. Go to the **Alerts** or **Graph** tabs to query metrics. The AI Gateway and GitLab Duo Workflow service
   expose metrics at the following endpoints:

   - AI Gateway: `http://<your_AIGW_domain>:8082/metrics`
   - GitLab Duo Workflow service: `http://<your_duo_agent_platform_service_domain>:8083/metrics`

## Does the AI Gateway need to autoscale?

Autoscaling is not mandatory but is recommended for environments with variable workloads, high concurrency requirements, or unpredictable usage patterns. In the GitLab production environment:

- Baseline setup: A single AI Gateway instance with 2 CPU cores and 8 GB RAM can handle approximately 40 concurrent requests.
- Scaling guidelines: For larger setups, such as an AWS t3.2xlarge instance (8 vCPUs, 32 GB RAM), the gateway can handle up to 160 concurrent requests, equivalent to 4x the baseline setup.
- Request throughput: GitLab.com's observed usage suggests that 7 RPS (requests per second) per 1000 active users is a reasonable metric for planning.
- Autoscaling options: Use Kubernetes Horizontal Pod Autoscalers (HPA) or similar mechanisms to dynamically adjust the number of instances based on metrics like CPU, memory utilization, or request latency thresholds.

## Configuration examples by deployment size

- Small deployment:
  - Single instance with 2 vCPUs and 8 GB RAM.
  - Handles up to 40 concurrent requests.
  - Teams or organizations with up to 50 users and predictable workloads.
  - Fixed instances may suffice; autoscaling can be disabled for cost efficiency.
- Medium deployment:
  - Single AWS t3.2xlarge instance with 8 vCPUs and 32 GB RAM.
  - Handles up to 160 concurrent requests.
  - Organizations with 50-200 users and moderate concurrency requirements.
  - Implement Kubernetes HPA with thresholds for 50% CPU utilization or request latency above 500ms.
- Large deployment:
  - Cluster of multiple AWS t3.2xlarge instances or equivalent.
  - Each instance handles 160 concurrent requests, scaling to thousands of users with multiple instances.
  - Enterprises with over 200 users and variable, high-concurrency workloads.
  - Use HPA to scale pods based on real-time demand, combined with node autoscaling for cluster-wide resource adjustments.

## What specs does the AI Gateway container have access to, and how does resource allocation affect performance?

The AI Gateway operates effectively under the following resource allocations:

- 2 CPU cores and 8 GB of RAM per container.
- Containers typically utilize about 7.39% CPU and proportionate memory in the GitLab production environment, leaving room for growth or handling burst activity.

## Mitigation strategies for resource contention

- Use Kubernetes resource requests and limits to ensure AI Gateway containers receive guaranteed CPU and memory allocations. For example:

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

## Scaling strategies

- Use Kubernetes HPA to scale pods based on real-time metrics like:
  - Average CPU utilization exceeding 50%.
  - Request latency consistently above 500ms.
  - Enable node autoscaling to scale infrastructure resources dynamically as pods increase.

## Scaling recommendations

| Deployment size | Instance type      | Resources             | Capacity (concurrent requests) | Scaling recommendations                     |
|------------------|--------------------|------------------------|---------------------------------|---------------------------------------------|
| Small            | 2 vCPUs, 8 GB RAM | Single instance        | 40                              | Fixed deployment; no autoscaling.           |
| Medium           | AWS t3.2xlarge    | Single instance     | 160                             | HPA based on CPU or latency thresholds.     |
| Large            | Multiple t3.2xlarge | Clustered instances   | 160 per instance               | HPA + node autoscaling for high demand.     |

## Support multiple GitLab instances

You can deploy a single AI Gateway to support multiple GitLab instances, or deploy separate AI Gateways per instance or geographic region. To help decide which is appropriate, consider:

- Expected traffic of approximately seven requests per second per 1,000 billable users.
- Resource requirements based on total concurrent requests across all instances.
- Best practice authentication configuration for each GitLab instance.

## Co-locate your AI Gateway and instance

The AI Gateway is available in multiple regions globally to ensure optimal performance for users regardless of location, through:

- Improved response times for GitLab Duo features.
- Reduced latency for geographically distributed users.
- Data sovereignty requirements compliance.

You should locate your AI Gateway in the same geographic region as your GitLab instance to help provide a frictionless developer experience, particularly for latency-sensitive features like Code Suggestions.

## Troubleshooting

When working with the AI Gateway, you might encounter the following issues.

### OpenShift permission issues

When deploying the AI Gateway on OpenShift, you might encounter permission errors due to the OpenShift security model.

#### Read-only filesystem at `/tmp`

The AI Gateway needs to write to `/tmp`. However, based on the OpenShift environment, which is security-restricted,
`/tmp` might be read-only.

To resolve this issue, create a new `EmptyDir` volume and mount it at `/tmp`.
You can do this in either of the following ways:

- From the command line:

  ```shell
  oc set volume <object_type>/<name> --add --name=tmpVol --type=emptyDir --mountPoint=/tmp
  ```

- Added to your `values.yaml`:

  ```yaml
  volumes:
  - name: tmp-volume
    emptyDir: {}

  volumeMounts:
  - name: tmp-volume
    mountPath: "/tmp"
  ```

#### HuggingFace models

By default, the AI Gateway uses `/home/aigateway/.hf` for caching HuggingFace models, which may not be writable in OpenShift's
security-restricted environment. This can result in permission errors like:

```shell
[Errno 13] Permission denied: '/home/aigateway/.hf/...'
```

To resolve this, set the `HF_HOME` environment variable to a writable location. You can use `/var/tmp/huggingface` or any other directory that is writable by the container.

You can configure this in either of the following ways:

- Add to your `values.yaml`:

  ```yaml
  extraEnvironmentVariables:
    - name: HF_HOME
      value: /var/tmp/huggingface  # Use any writable directory
  ```

- Or include in your Helm upgrade command:

  ```shell
  --set "extraEnvironmentVariables[0].name=HF_HOME" \
  --set "extraEnvironmentVariables[0].value=/var/tmp/huggingface"  # Use any writable directory
  ```

This configuration ensures the AI Gateway can properly cache HuggingFace models while respecting the OpenShift security constraints. The exact directory you choose may depend on your specific OpenShift configuration and security policies.

### Self-signed certificate error

A `[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: self-signed certificate in certificate chain` error is logged by the AI Gateway
when the AI Gateway tries to connect to a GitLab instance or model endpoint using either a certificate signed by a custom certificate authority (CA), or a self-signed certificate.

To resolve this, see [Connect to a GitLab instance or model endpoint with a self-signed SSL certificate](#connect-to-a-gitlab-instance-or-model-endpoint-with-a-self-signed-ssl-certificate).

### SSL certificate errors when loading PEM files

If you get an error that says `JWKError` while loading the PEM file into the Docker container,
you might need to resolve an SSL certificate error.

To fix this issue, use the following environment variables to set the appropriate
certificate bundle path in the Docker container:

- `SSL_CERT_FILE=/path/to/ca-bundle.pem`
- `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

Replace `/path/to/ca-bundle.pem` with the path to your certificate bundle.
