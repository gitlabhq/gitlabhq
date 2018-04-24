# GitLab Runner Helm Chart
> **Note:**
These charts have been tested on Google Kubernetes Engine and Azure Container Service. Other Kubernetes installations may work as well, if not please [open an issue](https://gitlab.com/charts/charts.gitlab.io/issues).

The `gitlab-runner` Helm chart deploys a GitLab Runner instance into your
Kubernetes cluster.

This chart configures the Runner to:

- Run using the GitLab Runner [Kubernetes executor](https://docs.gitlab.com/runner/install/kubernetes.html)
- For each new job it receives from [GitLab CI](https://about.gitlab.com/features/gitlab-ci-cd/), it will provision a
  new pod within the specified namespace to run it.

For more information on available GitLab Helm Charts, please see our [overview](index.md#chart-overview).

## Prerequisites

- Your GitLab Server's API is reachable from the cluster
- Kubernetes 1.4+ with Beta APIs enabled
- The `kubectl` CLI installed locally and authenticated for the cluster
- The [Helm client](https://github.com/kubernetes/helm/blob/master/docs/quickstart.md) installed locally on your machine

## Configuring GitLab Runner using the Helm Chart

Create a `values.yaml` file for your GitLab Runner configuration. See [Helm docs](https://github.com/kubernetes/helm/blob/master/docs/chart_template_guide/values_files.md)
for information on how your values file will override the defaults.

The default configuration can always be found in the [values.yaml](https://gitlab.com/charts/charts.gitlab.io/blob/master/charts/gitlab-runner/values.yaml) in the chart repository.

### Required configuration

In order for GitLab Runner to function, your config file **must** specify the following:

 - `gitlabUrl`  - the GitLab Server URL (with protocol) to register the runner against
 - `runnerRegistrationToken` - The Registration Token for adding new Runners to the GitLab Server. This must be
    retrieved from your GitLab Instance. See the [GitLab Runner Documentation](../../ci/runners/README.md#creating-and-registering-a-runner) for more information.

Unless you need to specify additional configuration, you are [ready to install](#installing-gitlab-runner-using-the-helm-chart).

### Other configuration

The rest of the configuration is [documented in the `values.yaml`](https://gitlab.com/charts/charts.gitlab.io/blob/master/charts/gitlab-runner/values.yaml) in the chart repository.

Here is a snippet of the important settings:

```yaml
## The GitLab Server URL (with protocol) that want to register the runner against
## ref: https://docs.gitlab.com/runner/commands/README.html#gitlab-runner-register
##
gitlabUrl: http://gitlab.your-domain.com/

## The Registration Token for adding new Runners to the GitLab Server. This must
## be retreived from your GitLab Instance.
## ref: https://docs.gitlab.com/ce/ci/runners/README.html#creating-and-registering-a-runner
##
runnerRegistrationToken: ""

## Set the certsSecretName in order to pass custom certficates for GitLab Runner to use
## Provide resource name for a Kubernetes Secret Object in the same namespace,
## this is used to populate the /etc/gitlab-runner/certs directory
## ref: https://docs.gitlab.com/runner/configuration/tls-self-signed.html#supported-options-for-self-signed-certificates
##
#certsSecretName:

## Configure the maximum number of concurrent jobs
## ref: https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section
##
concurrent: 10

## Defines in seconds how often to check GitLab for a new builds
## ref: https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section
##
checkInterval: 30

## For RBAC support:
rbac:
  create: false

  ## Run the gitlab-bastion container with the ability to deploy/manage containers of jobs
  ## cluster-wide or only within namespace
  clusterWideAccess: false

  ## Use the following Kubernetes Service Account name if RBAC is disabled in this Helm chart (see rbac.create)
  ##
  # serviceAccountName: default

## Configuration for the Pods that that the runner launches for each new job
##
runners:
  ## Default container image to use for builds when none is specified
  ##
  image: ubuntu:16.04

  ## Run all containers with the privileged flag enabled
  ## This will allow the docker:stable-dind image to run if you need to run Docker
  ## commands. Please read the docs before turning this on:
  ## ref: https://docs.gitlab.com/runner/executors/kubernetes.html#using-docker-dind
  ##
  privileged: false

  ## Namespace to run Kubernetes jobs in (defaults to 'default')
  ##
  # namespace:

  ## Build Container specific configuration
  ##
  builds:
    # cpuLimit: 200m
    # memoryLimit: 256Mi
    cpuRequests: 100m
    memoryRequests: 128Mi

  ## Service Container specific configuration
  ##
  services:
    # cpuLimit: 200m
    # memoryLimit: 256Mi
    cpuRequests: 100m
    memoryRequests: 128Mi

  ## Helper Container specific configuration
  ##
  helpers:
    # cpuLimit: 200m
    # memoryLimit: 256Mi
    cpuRequests: 100m
    memoryRequests: 128Mi

```

### Enabling RBAC support

If your cluster has RBAC enabled, you can choose to either have the chart create its own sevice account or provide one.

To have the chart create the service account for you, set `rbac.create` to true. 

### Controlling maximum Runner concurrency

A single GitLab Runner deployed on Kubernetes is able to execute multiple jobs in parallel by automatically starting additional Runner pods. The [`concurrent` setting](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section) controls the maximum number of pods allowed at a single time, and defaults to `10`.

```yaml
## Configure the maximum number of concurrent jobs
## ref: https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section
##
concurrent: 10
```

### Running Docker-in-Docker containers with GitLab Runners

See [Running Privileged Containers for the Runners](#running-privileged-containers-for-the-runners) for how to enable it,
and the [GitLab CI Runner documentation](https://docs.gitlab.com/runner/executors/kubernetes.html#using-docker-in-your-builds) on running dind.

### Running privileged containers for the Runners

You can tell the GitLab Runner to run using privileged containers. You may need
this enabled if you need to use the Docker executable within your GitLab CI jobs.

This comes with several risks that you can read about in the
[GitLab CI Runner documentation](https://docs.gitlab.com/runner/executors/kubernetes.html#using-docker-in-your-builds).

If you are okay with the risks, and your GitLab CI Runner instance is registered
against a specific project in GitLab that you trust the CI jobs of, you can
enable privileged mode in `values.yaml`:

```yaml
runners:
  ## Run all containers with the privileged flag enabled
  ## This will allow the docker:stable-dind image to run if you need to run Docker
  ## commands. Please read the docs before turning this on:
  ## ref: https://docs.gitlab.com/runner/executors/kubernetes.html#using-docker-dind
  ##
  privileged: true
```

### Providing a custom certificate for accessing GitLab

You can provide a [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/)
to the GitLab Runner Helm Chart, which will be used to populate the container's
`/etc/gitlab-runner/certs` directory.

Each key name in the Secret will be used as a filename in the directory, with the
file content being the value associated with the key.

More information on how GitLab Runner uses these certificates can be found in the
[Runner Documentation](https://docs.gitlab.com/runner/configuration/tls-self-signed.html#supported-options-for-self-signed-certificates).

 - The key/file name used should be in the format `<gitlab-hostname>.crt`. For example: `gitlab.your-domain.com.crt`.
 - Any intermediate certificates need to be concatenated to your server certificate in the same file.
 - The hostname used should be the one the certificate is registered for.

The GitLab Runner Helm Chart does not create a secret for you. In order to create
the secret, you can prepare your certificate on you local machine, and then run
the `kubectl create secret` command from the directory with the certificate

```bash
kubectl
  --namespace <NAMESPACE>
  create secret generic <SECRET_NAME>
  --from-file=<CERTFICATE_FILENAME>
```

- `<NAMESPACE>` is the Kubernetes namespace where you want to install the GitLab Runner.
- `<SECRET_NAME>` is the Kubernetes Secret resource name. For example: `gitlab-domain-cert`
- `<CERTFICATE_FILENAME>` is the filename for the certificate in your current directory that will be imported into the secret

You then need to provide the secret's name to the GitLab Runner chart.

Add the following to your `values.yaml`

```yaml
## Set the certsSecretName in order to pass custom certficates for GitLab Runner to use
## Provide resource name for a Kubernetes Secret Object in the same namespace,
## this is used to populate the /etc/gitlab-runner/certs directory
## ref: https://docs.gitlab.com/runner/configuration/tls-self-signed.html#supported-options-for-self-signed-certificates
##
certsSecretName: <SECRET NAME>
```

- `<SECRET_NAME>` is the Kubernetes Secret resource name. For example: `gitlab-domain-cert`

## Installing GitLab Runner using the Helm Chart

Add the GitLab Helm repository and initialize Helm:

```bash
helm repo add gitlab https://charts.gitlab.io
helm init
```

Once you [have configured](#configuration) GitLab Runner in your `values.yml` file,
run the following:

```bash
helm install --namespace <NAMESPACE> --name gitlab-runner -f <CONFIG_VALUES_FILE> gitlab/gitlab-runner
```

- `<NAMESPACE>` is the Kubernetes namespace where you want to install the GitLab Runner.
- `<CONFIG_VALUES_FILE>` is the path to values file containing your custom configuration. See the
  [Configuration](#configuration) section to create it.

## Updating GitLab Runner using the Helm Chart

Once your GitLab Runner Chart is installed, configuration changes and chart updates should we done using `helm upgrade`

```bash
helm upgrade --namespace <NAMESPACE> -f <CONFIG_VALUES_FILE> <RELEASE-NAME> gitlab/gitlab-runner
```

Where:
- `<NAMESPACE>` is the Kubernetes namespace where GitLab Runner is installed
- `<CONFIG_VALUES_FILE>` is the path to values file containing your custom configuration. See the
  [Configuration](#configuration) section to create it.
- `<RELEASE-NAME>` is the name you gave the chart when installing it.
  In the [Install section](#installing) we called it `gitlab-runner`.

## Uninstalling GitLab Runner using the Helm Chart

To uninstall the GitLab Runner Chart, run the following:

```bash
helm delete --namespace <NAMESPACE> <RELEASE-NAME>
```

where:

- `<NAMESPACE>` is the Kubernetes namespace where GitLab Runner is installed
- `<RELEASE-NAME>` is the name you gave the chart when installing it.
  In the [Install section](#installing) we called it `gitlab-runner`.
