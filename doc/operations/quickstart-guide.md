---
stage: Monitor
group: Observability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Observability Quickstart

You can try GitLab Observability by [cloning or forking the project](https://gitlab.com/gitlab-org/opstrace/opstrace.git) and creating a local installation.

## Prerequisites and dependencies

To install GitLab Observability Platform (GOP), install and configure the following third-party dependencies. You can do this manually, or [automatically by using asdf](#install-dependencies-using-asdf):

- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) for creating a local Kubernetes cluster.
- [Docker](https://docs.docker.com/install)
  - [Docker Compose](https://docs.docker.com/compose/compose-v2/) is now part of the `docker` distribution.
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl) for interacting with GitLab Observability.
- [Telepresence](https://www.telepresence.io/) allows you to code and test microservices locally against a remote Kubernetes cluster.
- [jq](https://stedolan.github.io/jq/download/) for some Makefile utilities.
- [Go 1.19](https://go.dev/doc/install).

The current versions of these dependencies are pinned in the `.tool-versions` file in the project.

You can run the following commands to check the availability and versions of these dependencies on your machine:

```shell
kind --version
docker --version
kubectl version
telepresence version
jq --version
go version
```

### Run GOP on macOS

If you're running GOP on macOS, ensure you have enough resources dedicated to Docker Desktop. The recommended minimum is:

- CPUs: 4+
- Memory: 8 GB+
- Swap: 1 GB+

It's possible to run GOP with fewer resources, but this specification works.

### Install dependencies using asdf

If you install dependencies using [`asdf`](https://asdf-vm.com/#/core-manage-asdf), GOP manages them for you automatically.

1. If you have not already done so, clone the `opstrace` repository into your preferred location:

   ```shell
   git clone https://gitlab.com/gitlab-org/opstrace/opstrace.git
   ```

1. Change into the project directory:

   ```shell
   cd opstrace
   ```

1. Optional. If you need to install `asdf`, run:

   ```shell
   make install-asdf
   ```

1. Install dependencies using `asdf`:

   ```shell
   make bootstrap
   ```

## Step 1: Create a local Kubernetes cluster with kind

Make sure Docker Desktop is running. In the `opstrace` project you cloned, run the following command:

```shell
make kind
```

Wait a few minutes while kind creates your Kubernetes cluster. When it's finished, you should see the following message:

```plaintext
Traffic Manager installed successfully
```

Now deploy the scheduler by running the following command in the `opstrace` project:

```shell
make deploy
```

This takes around 1 minute.

## Step 2: Create a GitLab application for authentication

You must create a GitLab application to use for authentication.

In the GitLab instance you'd like to connect with GOP, [create an OAuth application](../integration/oauth_provider.md).
This application can be a user-owned, group-owned or instance-wide application.
In production, you would create a trusted instance-wide application so that users are explicitly authorized without the consent screen.
The following example shows how to configure the application.

1. Select the API scope and enter `http://localhost/v1/auth/callback` as the redirect URI.

1. Run the following command to create the secret that holds the authentication data:

   ```shell
   kubectl create secret generic \
       --from-literal=gitlab_oauth_client_id=<gitlab_application_client_id> \
       --from-literal=gitlab_oauth_client_secret=<gitlab_application_client_secret> \
       --from-literal=internal_endpoint_token=<error_tracking_internal_endpoint_token> \
        dev-secret
   ```

1. Replace `<gitlab_application_client_id>` and `<gitlab_application_client_secret>` with the values from the GitLab application you just created.
Replace `<error_tracking_internal_endpoint_token>` with any string if you do not plan to use error tracking.

You can also view [this MR on how to get the token to test error tracking](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91928).
You must specify all the parameters when creating the secret.

## Step 3: Create the cluster definition

1. In your `opstrace` project, run the following command to create a `Cluster.yaml` manifest file:

   ```shell
   cat <<EOF > Cluster.yaml
   apiVersion: opstrace.com/v1alpha1
   kind: Cluster
   metadata:
     name: dev-cluster
   spec:
     target: kind
     goui:
       image: "registry.gitlab.com/gitlab-org/opstrace/opstrace-ui/   gitlab-observability-ui:c9fb6e70"
     dns:
       acmeEmail: ""
       dns01Challenge: {}
       externalDNSProvider: {}
     gitlab:
       groupAllowedAccess: '*'
       groupAllowedSystemAccess: "6543"
       instanceUrl: https://gitlab.com
       authSecret:
         name: dev-secret
   EOF
   ```

1. Apply the file you just created with the following command:

   ```shell
   kubectl apply -f Cluster.yaml
   ```

1. Run the following command to wait for the cluster to be ready:

   ```shell
   kubectl wait --for=condition=ready cluster/dev-cluster --timeout=600s
   ```

After the previous command exits, the cluster is ready.

## Step 4: Enable Observability on a GitLab namespace you own

Go to a namespace you own in the connected GitLab instance and copy the Group ID below the group name.

GOP can only be enabled for groups you own.
To list all the groups that your user owns, in the upper-left corner, select **Groups > View all Groups**. You then see the **Your groups** tab.

In your browser, go to `http://localhost/-/{GroupID}`. For example, `http://localhost/-/14485840`.

Follow the on-screen instructions to enable observability for the namespace.
This can take a couple of minutes if it's the first time observability has been enabled for the root level namespace (GitLab.org in the previous example.)

Once your namespace has been enabled and is ready, the page automatically redirects you to the GitLab Observability UI.

## Step 5: Send traces to GOP

[Follow this guide to send traces to your namespace and monitor them in the UI](https://gitlab.com/gitlab-org/opstrace/opstrace/-/blob/main/docs/guides/user/sending-traces-locally.md).

## Step 6: Clean up your local GOP

To tear down your locally running GOP instance, run the following command:

```shell
make destroy
```

## Known issues

### Incorrect architecture for `kind/node` image

If your machine has an Apple silicon (M1/M2) chip, you might encounter an architecture problem with the `kind/node` image when running the `make kind` command. For more details, see [issue 1802](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/1802).

To fix this problem, you first need to create a Dockerfile. Then build and deploy the image:

1. Create a new Dockerfile (without a file extension) and paste the following commands:

   ```Dockerfile
   FROM --platform=arm64 kindest/node:v1.23.13
   RUN arch
   ```

1. Save your Dockerfile, then build the image with the following command:

   ```shell
   docker build -t tempkind .
   ```

   Do not forget the period at the end.

1. Create a cluster using your new image with the following command:

   ```shell
   kind create cluster --image tempkind
   ```

### scheduler-controller-manager pod cannot start due to ImagePullBackOff

If while executing `make deploy` in step 1, the `scheduler-controller-manager` pod cannot start due to `ImagePullBackOff`, you must set the `CI_COMMIT_TAG` to a non-dirty state. By setting the commit tag to the latest commit, you ensure the Docker image can be pulled from the container registry.

Run the following command to set the commit tag:

```shell
make kind
export CI_COMMIT_TAG=0.2.0-e1206acf
make deploy
```
