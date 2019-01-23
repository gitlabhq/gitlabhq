# Serverless

> Introduced in GitLab 11.5.
> Serverless is currently in [alpha](https://about.gitlab.com/handbook/product/#alpha).

Run serverless workloads on Kubernetes using [Knative](https://cloud.google.com/knative/).

## Overview

Knative extends Kubernetes to provide a set of middleware components that are useful to build modern, source-centric, container-based applications. Knative brings some significant benefits out of the box through its main components:

- [Build](https://github.com/knative/build): Source-to-container build orchestration.
- [Eventing](https://github.com/knative/eventing): Management and delivery of events.
- [Serving](https://github.com/knative/serving): Request-driven compute that can scale to zero.

For more information on Knative, visit the [Knative docs repo](https://github.com/knative/docs).

With GitLab serverless, you can deploy both functions-as-a-service (FaaS) and serverless applications.

## Requirements

To run Knative on Gitlab, you will need:

1. **Kubernetes Cluster:** An RBAC-enabled Kubernetes cluster is required to deploy Knative.
    The simplest way to get started is to add a cluster using [GitLab's GKE integration](../index.md#adding-and-creating-a-new-gke-cluster-via-gitlab).
1. **Helm Tiller:** Helm is a package manager for Kubernetes and is required to install
    Knative.
1. **Domain Name:** Knative will provide its own load balancer using Istio. It will provide an
    external IP address for all the applications served by Knative. You will be prompted to enter a
    wildcard domain where your applications will be served. Configure your DNS server to use the
    external IP address for that domain.
1. **`.gitlab-ci.yml`:** GitLab uses [Kaniko](https://github.com/GoogleContainerTools/kaniko)
    to build the application and the [TriggerMesh CLI](https://github.com/triggermesh/tm) to simplify the
    deployment of knative services and functions.
1. **`serverless.yml`** (for [functions only](#deploying-functions)): When using serverless to deploy functions, the `serverless.yml` file
    will contain the information for all the functions being hosted in the repository as well as a reference to the
    runtime being used.
1. **`Dockerfile`** (for [applications only](#deploying-serverless-applications): Knative requires a `Dockerfile` in order to build your application. It should be included
    at the root of your project's repo and expose port `8080`.

## Installing Knative via GitLab's Kubernetes integration

NOTE: **Note:**
The minimum recommended cluster size to run Knative is 3-nodes, 6 vCPUs, and 22.50 GB memory. **RBAC must be enabled.**

1. [Add a Kubernetes cluster](../index.md) and install Helm.
1. Once Helm has been successfully installed, on the Knative app section, enter the domain to be used with
    your application and click "Install".

    ![install-knative](img/install-knative.png)

1. After the Knative installation has finished, you can wait for the IP address to be displayed in the
   **Knative IP Address** field or retrieve the Istio Ingress IP address by running the following command:

   ```bash
   kubectl get svc --namespace=istio-system knative-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip} '
   ```

   Output:

   ```bash
   35.161.143.124 my-machine-name:~ my-user$
   ```

1. The ingress is now available at this address and will route incoming requests to the proper service based on the DNS
   name in the request. To support this, a wildcard DNS A record should be created for the desired domain name. For example,
   if your Knative base domain is `knative.info` then you need to create an A record with domain `*.knative.info`
   pointing the ip address of the ingress.

    ![dns entry](img/dns-entry.png)

## Deploying Functions

> Introduced in GitLab 11.6.

Using functions is useful for dealing with independent
events without needing to maintain a complex unified infrastructure. This allows
you to focus on a single task that can be executed/scaled automatically and independently.

Currently the following [runtimes](https://gitlab.com/triggermesh/runtimes) are offered:

- node.js
- kaniko

In order to deploy functions to your Knative instance, the following files must be present:

1. `.gitlab-ci.yml`: This template allows to define the stage, environment, and
   image to be used for your functions. It must be included at the root of your repository:

   ```yaml
   stages:
     - deploy

   functions:
     stage: deploy
     environment: test
     image: gcr.io/triggermesh/tm:v0.0.7
     script:
       - tm -n "$KUBE_NAMESPACE" set registry-auth gitlab-registry --registry "$CI_REGISTRY" --username "$CI_REGISTRY_USER" --password "$CI_JOB_TOKEN"
       - tm -n "$KUBE_NAMESPACE" --registry-host "$CI_REGISTRY_IMAGE" deploy --wait
   ```

    The `gitlab-ci.yml` template creates a `Deploy` stage with a `functions` job that invokes the `tm` CLI with the required parameters.

2. `serverless.yml`: This file contains the metadata for your functions,
   such as name, runtime, and environment. It must be included at the root of your repository. The following is a sample `echo` function which shows the required structure for the file. You can find the relevant files for this project in the [functions example project](https://gitlab.com/knative-examples/functions).

   ```yaml
   service: my-functions
   description: "Deploying functions from GitLab using Knative"

   provider:
     name: triggermesh
     registry-secret: gitlab-registry
     environment:
       FOO: BAR

   functions:
     echo:
       handler: echo
       runtime: https://gitlab.com/triggermesh/runtimes/raw/master/nodejs.yaml
       description: "echo function using node.js runtime"
       buildargs:
        - DIRECTORY=echo
       environment:
        FUNCTION: echo
   ```


The `serverless.yml` file is referencing both an `echo` directory (under `buildargs`) and an `echo` file (under `handler`) which is a reference to `echo.js` in the [repository](https://gitlab.com/knative-examples/functions). Additionally, it contains three sections with distinct parameters:

### `service`

| Parameter | Description |
|-----------|-------------|
| `service` | Name for the Knative service which will serve the function. |
| `description` | A short description of the `service`. |


### `provider`

| Parameter | Description |
|-----------|-------------|
| `name` | Indicates which provider is used to execute the `serverless.yml` file. In this case, the TriggerMesh `tm` CLI. |
| `registry-secret` | Indicates which registry will be used to store docker images. The sample function is using the GitLab Registry (`gitlab-registry`). A different registry host may be specified using `registry` key in the `provider` object. If changing the default, update the permission and the secret value on the `gitlab-ci.yml` file |
| `environment` | Includes the environment variables to be passed as part of function execution for **all** functions in the file, where `FOO` is the variable name and `BAR` are he variable contents. You may replace this with you own variables. |

### `functions`

In the `serverless.yml` example above, the function name is `echo` and the subsequent lines contain the function attributes.


| Parameter | Description |
|-----------|-------------|
| `handler` | The function's file name. In the example above, both the function name and the handler are the same. |
| `runtime` | The runtime to be used to execute the function. |
| `description` | A short description of the function. |
| `buildargs` | Pointer to the function file in the repo. In the sample the function is located in the `echo` directory. |
| `environment` | Sets an environment variable for the specific function only. |

After the `gitlab-ci.yml` template has been added and the `serverless.yml` file has been 
created, each function must be defined as a single file in your repository. Committing a 
function to your project will result in a
CI pipeline being executed which will deploy each function as a Knative service.
Once the deploy stage has finished, additional details for the function will
appear under **Operations > Serverless**.

![serverless page](img/serverless-page.png)

This page contains all functions available for the project, the description for
accessing the function, and, if available, the function's runtime information.
The details are derived from the Knative installation inside each of the project's
Kubernetes cluster.

The function details can be retrieved directly from Knative on the cluster:

```bash
kubectl -n "$KUBE_NAMESPACE" get services.serving.knative.dev
```

The sample function can now be triggered from any HTTP client using a simple `POST` call.

![function exection](img/function-execution.png)

Currently, the Serverless page presents all functions available in all clusters registered for the project with Knative installed.

Clicking on the function name will provide additional details such as the
function's URL as well as runtime statistics such as the number of active pods
available to service the request based on load.

![serverless function details](img/serverless-details.png)

## Deploying Serverless applications

> Introduced in GitLab 11.5.

NOTE: **Note:**
You can reference the sample [Knative Ruby App](https://gitlab.com/knative-examples/knative-ruby-app) to get started.

Add the following `.gitlab-ci.yml` to the root of your repository
(you may skip this step if using the sample [Knative Ruby App](https://gitlab.com/knative-examples/knative-ruby-app) mentioned above):

```yaml
stages:
  - build
  - deploy

build:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  only:
    - master
  script:
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > /kaniko/.docker/config.json
    - /kaniko/executor --context $CI_PROJECT_DIR --dockerfile $CI_PROJECT_DIR/Dockerfile --destination $CI_REGISTRY_IMAGE

deploy:
  stage: deploy
  image: gcr.io/triggermesh/tm@sha256:e3ee74db94d215bd297738d93577481f3e4db38013326c90d57f873df7ab41d5
  only:
    - master
  environment: production
  script:
    - echo "$CI_REGISTRY_IMAGE"
    - tm -n "$KUBE_NAMESPACE" --config "$KUBECONFIG" deploy service "$CI_PROJECT_NAME" --from-image "$CI_REGISTRY_IMAGE" --wait
```

## Deploy the application with Knative

With all the pieces in place, the next time a CI pipeline runs, the Knative application will be deployed. Navigate to
**CI/CD > Pipelines** and click the most recent pipeline.

## Obtain the URL for the Knative deployment

Use the CI/CD deployment job output to obtain the deployment URL. Once all the stages of the pipeline finish, click the **deploy** stage.

![deploy stage](img/deploy-stage.png)

The output will look like this:

```bash
Running with gitlab-runner 11.5.0~beta.844.g96d88322 (96d88322)
  on docker-auto-scale 72989761
Using Docker executor with image gcr.io/triggermesh/tm@sha256:e3ee74db94d215bd297738d93577481f3e4db38013326c90d57f873df7ab41d5 ...
Pulling docker image gcr.io/triggermesh/tm@sha256:e3ee74db94d215bd297738d93577481f3e4db38013326c90d57f873df7ab41d5 ...
Using docker image sha256:6b3f6590a9b30bd7aafb9573f047d930c70066e43955b4beb18a1eee175f6de1 for gcr.io/triggermesh/tm@sha256:e3ee74db94d215bd297738d93577481f3e4db38013326c90d57f873df7ab41d5 ...
Running on runner-72989761-project-4342902-concurrent-0 via runner-72989761-stg-srm-1541795796-27929c96...
Cloning repository...
Cloning into '/builds/danielgruesso/knative'...
Checking out 8671ad20 as master...
Skipping Git submodules setup
$ echo "$CI_REGISTRY_IMAGE"
registry.staging.gitlab.com/danielgruesso/knative
$ tm -n "$KUBE_NAMESPACE" --config "$KUBECONFIG" deploy service "$CI_PROJECT_NAME" --from-image "$CI_REGISTRY_IMAGE" --wait
Deployment started. Run "tm -n knative-4342902 describe service knative" to see the details
Waiting for ready state.......
Service domain: knative.knative-4342902.knative.info
Job succeeded
```

The second to last line, labeled **Service domain** contains the URL for the deployment. Copy and paste the domain into your
browser to see the app live.

![knative app](img/knative-app.png)
