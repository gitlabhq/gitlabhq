# Serverless

> Introduced in GitLab 11.5.

CAUTION: **Caution:**
Serverless is currently in [alpha](https://about.gitlab.com/handbook/product/#alpha).

Run serverless workloads on Kubernetes using [Knative](https://cloud.google.com/knative/).

## Overview

Knative extends Kubernetes to provide a set of middleware components that are useful to build modern, source-centric, container-based applications. Knative brings some significant benefits out of the box through its main components:

- [Serving](https://github.com/knative/serving): Request-driven compute that can scale to zero.
- [Eventing](https://github.com/knative/eventing): Management and delivery of events.

For more information on Knative, visit the [Knative docs repo](https://github.com/knative/docs).

With GitLab Serverless, you can deploy both functions-as-a-service (FaaS) and serverless applications.

## Prerequisites

To run Knative on Gitlab, you will need:

1. **Existing GitLab project:** You will need a GitLab project to associate all resources. The simplest way to get started:

    - If you are planning on deploying functions, clone the [functions example project](https://gitlab.com/knative-examples/functions) to get started.
    - If you are planning on deploying a serverless application, clone the sample [Knative Ruby App](https://gitlab.com/knative-examples/knative-ruby-app) to get started.

1. **Kubernetes Cluster:** An RBAC-enabled Kubernetes cluster is required to deploy Knative.
    The simplest way to get started is to add a cluster using [GitLab's GKE integration](../index.md#adding-and-creating-a-new-gke-cluster-via-gitlab).
    The set of minimum recommended cluster specifications to run Knative is 3 nodes, 6 vCPUs, and 22.50 GB memory.
1. **Helm Tiller:** Helm is a package manager for Kubernetes and is required to install
    Knative.
1. **GitLab Runner:** A runner is required to run the CI jobs that will deploy serverless
    applications or functions onto your cluster. You can install the GitLab Runner
    onto the existing Kubernetes cluster. See [Installing Applications](../index.md#installing-applications) for more information.
1. **Domain Name:** Knative will provide its own load balancer using Istio. It will provide an
    external IP address or hostname for all the applications served by Knative. You will be prompted to enter a
    wildcard domain where your applications will be served. Configure your DNS server to use the
    external IP address or hostname for that domain.
1. **`.gitlab-ci.yml`:** GitLab uses [Kaniko](https://github.com/GoogleContainerTools/kaniko)
    to build the application. We also use [gitlabktl](https://gitlab.com/gitlab-org/gitlabktl)
    and [TriggerMesh CLI](https://github.com/triggermesh/tm) CLIs to simplify the
    deployment of services and functions to Knative.
1. **`serverless.yml`** (for [functions only](#deploying-functions)): When using serverless to deploy functions, the `serverless.yml` file
    will contain the information for all the functions being hosted in the repository as well as a reference to the
    runtime being used.
1. **`Dockerfile`** (for [applications only](#deploying-serverless-applications): Knative requires a
    `Dockerfile` in order to build your applications. It should be included at the root of your
    project's repo and expose port `8080`. `Dockerfile` is not require if you plan to build serverless functions
    using our [runtimes](https://gitlab.com/gitlab-org/serverless/runtimes).
1. **Prometheus** (optional): Installing Prometheus allows you to monitor the scale and traffic of your serverless function/application.
    See [Installing Applications](../index.md#installing-applications) for more information.

## Installing Knative via GitLab's Kubernetes integration

NOTE: **Note:**
The minimum recommended cluster size to run Knative is 3-nodes, 6 vCPUs, and 22.50 GB memory. **RBAC must be enabled.**

1. [Add a Kubernetes cluster](../index.md) and [install Helm](../index.md#installing-applications).
1. Once Helm has been successfully installed, scroll down to the Knative app section. Enter the domain to be used with
    your application/functions (e.g. `example.com`) and click **Install**.

    ![install-knative](img/install-knative.png)

1. After the Knative installation has finished, you can wait for the IP address or hostname to be displayed in the
   **Knative Endpoint** field or [retrieve the Istio Ingress Endpoint manually](../#manually-determining-the-external-endpoint).

   NOTE: **Note:**
   Running `kubectl` commands on your cluster requires setting up access to the cluster first.
   For clusters created on GKE, see [GKE Cluster Access](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl),
   for other platforms [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

1. The ingress is now available at this address and will route incoming requests to the proper service based on the DNS
   name in the request. To support this, a wildcard DNS A record should be created for the desired domain name. For example,
   if your Knative base domain is `knative.info` then you need to create an A record or CNAME record with domain `*.knative.info`
   pointing the ip address or hostname of the ingress.

    ![dns entry](img/dns-entry.png)

NOTE: **Note:**
You can deploy either [functions](#deploying-functions) or [serverless applications](#deploying-serverless-applications)
on a given project but not both. The current implementation makes use of a `serverless.yml` file to signal a FaaS project.

## Using an existing installation of Knative

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/issues/58941) in GitLab 12.0.

NOTE: **Note:**
The "invocations" monitoring feature of GitLab serverless will not work when
adding an existing installation of Knative.

It is also possible to use GitLab Serverless with an existing Kubernetes
cluster which already has Knative installed.

Simply:

1. Follow the steps to
   [add an existing Kubernetes cluster](../index.md#adding-an-existing-kubernetes-cluster).
1. Follow the steps to deploy [functions](#deploying-functions)
   or [serverless applications](#deploying-serverless-applications) onto your
   cluster.

## Deploying functions

> Introduced in GitLab 11.6.

Using functions is useful for dealing with independent
events without needing to maintain a complex unified infrastructure. This allows
you to focus on a single task that can be executed/scaled automatically and independently.

Currently the following [runtimes](https://gitlab.com/gitlab-org/serverless/runtimes) are offered:

- ruby
- node.js
- Dockerfile

You can find and import all the files referenced in this doc in the **[functions example project](https://gitlab.com/knative-examples/functions)**.

Follow these steps to deploy a function using the Node.js runtime to your Knative instance (you can skip these steps if you've cloned the example project):

1. Create a directory that will house the function. In this example we will create a directory called `echo` at the root of the project.

1. Create the file that will contain the function code. In this example, our file is called `echo.js` and is located inside the `echo` directory. If your project is:
    - Public, continue to the next step.
    - Private, you will need to [create a GitLab deploy token](../../deploy_tokens/index.md#creating-a-deploy-token) with `gitlab-deploy-token` as the name and the `read_registry` scope.

1. `.gitlab-ci.yml`: this defines a pipeline used to deploy your functions.
   It must be included at the root of your repository:

   ```yaml
   include:
     template: Serverless.gitlab-ci.yml

   functions:build:
     extends: .serverless:build:functions
     environment: production

   functions:deploy:
     extends: .serverless:deploy:functions
     environment: production
   ```

    This `.gitlab-ci.yml` creates jobs that invoke some predefined commands to
    build and deploy your functions to your cluster.

    `Serverless.gitlab-ci.yml` is a template that allows customization.
    You can either import it with `include` parameter and use `extends` to
    customize your jobs, or you can inline the entire template by choosing it
    from **Apply a template** dropdown when editing the `.gitlab-ci.yml` file through
    the user interface.

2. `serverless.yml`: this file contains the metadata for your functions,
   such as name, runtime, and environment.

   It must be included at the root of your repository.
   The following is a sample `echo` function which shows the required structure
   for the file.

   You can find the relevant files for this project in the [functions example project](https://gitlab.com/knative-examples/functions).

   ```yaml
   service: functions
   description: "GitLab Serverless functions using Knative"

   provider:
     name: triggermesh
     environment:
       FOO: value

   functions:
     echo-js:
       handler: echo-js
       source: ./echo-js
       runtime: https://gitlab.com/gitlab-org/serverless/runtimes/nodejs
       description: "node.js runtime function"
       environment:
         MY_FUNCTION: echo-js
   ```

Explanation of the fields used above:

### `service`

| Parameter | Description |
|-----------|-------------|
| `service` | Name for the Knative service which will serve the function. |
| `description` | A short description of the `service`. |

### `provider`

| Parameter | Description |
|-----------|-------------|
| `name` | Indicates which provider is used to execute the `serverless.yml` file. In this case, the TriggerMesh `tm` CLI. |
| `environment` | Includes the environment variables to be passed as part of function execution for **all** functions in the file, where `FOO` is the variable name and `BAR` are he variable contents. You may replace this with you own variables. |

### `functions`

In the `serverless.yml` example above, the function name is `echo` and the subsequent lines contain the function attributes.

| Parameter | Description |
|-----------|-------------|
| `handler` | The function's name. |
| `source` | Directory with sources of a functions. |
| `runtime` | The runtime to be used to execute the function. |
| `description` | A short description of the function. |
| `environment` | Sets an environment variable for the specific function only. |

After the `gitlab-ci.yml` template has been added and the `serverless.yml` file has been
created, pushing a commit to your project will result in a
CI pipeline being executed which will deploy each function as a Knative service.
Once the deploy stage has finished, additional details for the function will
appear under **Operations > Serverless**.

![serverless page](img/serverless-page.png)

This page contains all functions available for the project, the description for
accessing the function, and, if available, the function's runtime information.
The details are derived from the Knative installation inside each of the project's
Kubernetes cluster. Click on each function to obtain detailed scale and invocation data.

The function details can be retrieved directly from Knative on the cluster:

```bash
kubectl -n "$KUBE_NAMESPACE" get services.serving.knative.dev
```

The sample function can now be triggered from any HTTP client using a simple `POST` call:

  1. Using curl (replace the URL on the last line with the URL of your application):

      ```bash
      curl \
      --header "Content-Type: application/json" \
      --request POST \
      --data '{"GitLab":"FaaS"}' \
      http://functions-echo.functions-1.functions.example.com/
      ```
  2. Using a web-based tool (ie. postman, restlet, etc)

      ![function execution](img/function-execution.png)

## Deploying Serverless applications

> Introduced in GitLab 11.5.

NOTE: **Note:**
You can reference and import the sample [Knative Ruby App](https://gitlab.com/knative-examples/knative-ruby-app) to get started.

Add the following `.gitlab-ci.yml` to the root of your repository
(you may skip this step if you've previously cloned the sample [Knative Ruby App](https://gitlab.com/knative-examples/knative-ruby-app) mentioned above):

```yaml
include:
  template: Serverless.gitlab-ci.yml

build:
  extends: .serverless:build:image

deploy:
  extends: .serverless:deploy:image
```

`Serverless.gitlab-ci.yml` is a template that allows customization.
You can either import it with `include` parameter and use `extends` to
customize your jobs, or you can inline the entire template by choosing it
from **Apply a template** dropdown when editing the `.gitlab-ci.yml` file through
the user interface.

### Deploy the application with Knative

With all the pieces in place, the next time a CI pipeline runs, the Knative application will be deployed. Navigate to
**CI/CD > Pipelines** and click the most recent pipeline.

### Obtain the URL for the Knative deployment

Go to the **CI/CD > Pipelines** and click on the pipeline that deployed your app. Once all the stages of the pipeline finish, click the **deploy** stage.

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
Service domain: knative.knative-4342902.example.com
Job succeeded
```

The second to last line, labeled **Service domain** contains the URL for the deployment. Copy and paste the domain into your
browser to see the app live.

![knative app](img/knative-app.png)

## Function details

Go to the **Operations > Serverless** page and click on one of the function
rows to bring up the function details page.

![function_details](img/function-details-loaded.png)

The pod count will give you the number of pods running the serverless function instances on a given cluster.

### Prometheus support

For the Knative function invocations to appear,
[Prometheus must be installed](../index.md#installing-applications).

Once Prometheus is installed, a message may appear indicating that the metrics data _is
loading or is not available at this time._  It will appear upon the first access of the
page, but should go away after a few seconds. If the message does not disappear, then it
is possible that GitLab is unable to connect to the Prometheus instance running on the
cluster.

## Enabling TLS for Knative services

By default, a GitLab serverless deployment will be served over `http`. In order to serve over `https` you
must manually obtain and install TLS certificates.

The simplest way to accomplish this is to 
use [Certbot to manually obtain Let's Encrypt certificates](https://knative.dev/docs/serving/using-a-tls-cert/#using-certbot-to-manually-obtain-let-s-encrypt-certificates). Certbot is a free, open source software tool for automatically using Let’s Encrypt certificates on manually-administrated websites to enable HTTPS.

NOTE: **Note:**
The instructions below relate to installing and running Certbot on a Linux server and may not work on other operating systems.

1. Install Certbot by running the 
   [`certbot-auto` wrapper script](https://certbot.eff.org/docs/install.html#certbot-auto).
   On the command line of your server, run the following commands:

    ```sh
    wget https://dl.eff.org/certbot-auto
    sudo mv certbot-auto /usr/local/bin/certbot-auto
    sudo chown root /usr/local/bin/certbot-auto
    chmod 0755 /usr/local/bin/certbot-auto
    /usr/local/bin/certbot-auto --help
    ```

    To check the integrity of the `certbot-auto` script, run:

      ```sh
      wget -N https://dl.eff.org/certbot-auto.asc
      gpg2 --keyserver ipv4.pool.sks-keyservers.net --recv-key A2CFB51FA275A7286234E7B24D17C995CD9775F2
      gpg2 --trusted-key 4D17C995CD9775F2 --verify certbot-auto.asc /usr/local/bin/certbot-auto
      ```

    The output of the last command should look something like:

      ```sh
      gpg: Signature made Mon 10 Jun 2019 06:24:40 PM EDT
      gpg:                using RSA key A2CFB51FA275A7286234E7B24D17C995CD9775F2
      gpg: key 4D17C995CD9775F2 marked as ultimately trusted
      gpg: checking the trustdb
      gpg: marginals needed: 3  completes needed: 1  trust model: pgp
      gpg: depth: 0  valid:   1  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 1u
      gpg: next trustdb check due at 2027-11-22
      gpg: Good signature from "Let's Encrypt Client Team <letsencrypt-client@eff.org>" [ultimate]
      ```

1. Run the following command to use Certbot to request a certificate
   using DNS challenge during authorization:


    ```sh
    ./certbot-auto certonly --manual --preferred-challenges dns -d '*.<namespace>.example.com'
    ```

    Where `<namespace>` is the namespace created by GitLab for your serverless project (composed of `<projectname+id>`) and
    `example.com` is the domain being used for your project. If you are unsure what the namespace of your project is, navigate
    to the **Operations > Serverless** page of your project and inspect
    the endpoint provided for your function/app.

    ![function_endpoint](img/function-endpoint.png)

    In the above image, the namespace for the project is `node-function-11909507` and the domain is `knative.info`, thus
    certificate request line would look like this:

    ```sh
    ./certbot-auto certonly --manual --preferred-challenges dns -d '*.node-function-11909507.knative.info'
    ```

    The Certbot tool walks you through the steps of validating that you own each domain that you specify by creating TXT records in those domains.
    After this process is complete, the output should look something like this:

    ```sh
    IMPORTANT NOTES:
    - Congratulations! Your certificate and chain have been saved at:
      /etc/letsencrypt/live/namespace.example.com/fullchain.pem
      Your key file has been saved at:
      /etc/letsencrypt/live/namespace.example/privkey.pem
      Your cert will expire on 2019-09-19. To obtain a new or tweaked
      version of this certificate in the future, simply run certbot-auto
      again. To non-interactively renew *all* of your certificates, run
      "certbot-auto renew"
    -----BEGIN PRIVATE KEY-----
    - Your account credentials have been saved in your Certbot
      configuration directory at /etc/letsencrypt. You should make a
      secure backup of this folder now. This configuration directory will
      also contain certificates and private keys obtained by Certbot so
      making regular backups of this folder is ideal.
    ```

1. Create certificate and private key files. Using the contents of the files
   returned by Certbot, we'll create two files in order to create the
   Kubernetes secret:

      Run the following command to see the contents of `fullchain.pem`:

      ```sh
      sudo cat /etc/letsencrypt/live/node-function-11909507.knative.info/fullchain.pem
      ```

      Output should look like this:

      ```sh
      -----BEGIN CERTIFICATE-----
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b4ag==
      -----END CERTIFICATE-----
      -----BEGIN CERTIFICATE-----
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      K2fcb195768c39e9a94cec2c2e30Qg==
      -----END CERTIFICATE-----
      ```

      Create a file with the name `cert.pem` with the contents of the entire output.

      Once `cert.pem` is created, run the following command to see the contents of `privkey.pem`:

      ```sh
      sudo cat /etc/letsencrypt/live/namespace.example/privkey.pem
      ```

      Output should look like this:

      ```sh
      -----BEGIN PRIVATE KEY-----
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      2fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      04f294d1eaca42b8692017b426d53bbc8fe75f827734f0260710b83a556082df
      -----BEGIN CERTIFICATE-----
      fcb195768c39e9a94cec2c2e32c59c0aad7a3365c10892e8116b5d83d4096b6
      4f294d1eaca42b8692017b4262==
      -----END PRIVATE KEY-----
      ```

      Create a new file with the name `cert.pk` with the contents of the entire output.

1. Create a Kubernetes secret to hold your TLS certificate, `cert.pem`, and
   the private key `cert.pk`:

    NOTE: **Note:**
    Running `kubectl` commands on your cluster requires setting up access to the cluster first.
    For clusters created on GKE, see
    [GKE Cluster Access](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl).
    For other platforms, [install `kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/).

    ```sh
    kubectl create --namespace istio-system secret tls istio-ingressgateway-certs \
    --key cert.pk \
    --cert cert.pem
    ```

    Where `cert.pem` and `cert.pk` are your certificate and private key files. Note that the `istio-ingressgateway-certs` secret name is required.

1. Configure Knative to use the new secret that you created for HTTPS
   connections. Run the 
  following command to open the Knative shared `gateway` in edit mode:

    ```sh
    kubectl edit gateway knative-ingress-gateway --namespace knative-serving
    ```

      Update the gateway to include the following tls: section and configuration:

      ```sh
      tls:
        mode: SIMPLE
        privateKey: /etc/istio/ingressgateway-certs/tls.key
        serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      ```

      Example:

      ```sh
      apiVersion: networking.istio.io/v1alpha3
      kind: Gateway
      metadata:
        # ... skipped ...
      spec:
        selector:
          istio: ingressgateway
        servers:
          - hosts:
              - "*"
            port:
              name: http
              number: 80
              protocol: HTTP
          - hosts:
              - "*"
            port:
              name: https
              number: 443
              protocol: HTTPS
            tls:
              mode: SIMPLE
              privateKey: /etc/istio/ingressgateway-certs/tls.key
              serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
      ```

      After your changes are running on your Knative cluster, you can begin using the HTTPS protocol for secure access your deployed Knative services.
      In the event a mistake is made during this process and you need to update the cert, you will need to edit the gateway `knative-ingress-gateway`
      to switch back to `PASSTHROUGH` mode. Once corrections are made, edit the file again so the gateway will use the new certificates.