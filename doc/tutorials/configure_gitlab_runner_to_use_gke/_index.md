---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Configure GitLab Runner to use the Google Kubernetes Engine'
---

This tutorial describes how to configure GitLab Runner to use the Google Kubernetes Engine (GKE)
to run jobs.

In this tutorial, you configure GitLab Runner to run jobs in the [Standard cluster mode](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters).

To configure GitLab Runner to use the GKE:

1. [Set up your environment](#set-up-your-environment).
1. [Create and connect to a cluster](#create-and-connect-to-a-cluster).
1. [Install and configure the Kubernetes Operator](#install-and-configure-the-kubernetes-operator).
1. Optional. [Verify that the configuration was successful](#verify-your-configuration).

## Before you begin

Before you can configure GitLab Runner to use the GKE you must:

- Have a project where you have the Maintainer or Owner role. If you don't have a project, you can [create it](../../user/project/_index.md).
- [Obtain the project runner authentication token](../../ci/runners/runners_scope.md#create-a-project-runner-with-a-runner-authentication-token).
- Install GitLab Runner.

## Set up your environment

Install the tools to configure and use GitLab Runner in the GKE.

1. [Install and configure Google Cloud CLI](https://cloud.google.com/sdk/docs/install). You use Google Cloud CLI to connect to the cluster.
1. [Install and configure kubectl](https://kubernetes.io/docs/tasks/tools/). You use kubectl to communicate with the remote cluster from your local environment.

## Create and connect to a cluster

This step describes how to create a cluster and connect to it. After you connect to the cluster, you use kubectl to interact with it.

1. In the Google Cloud Platform, create a [standard](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-zonal-cluster) cluster.

1. Install the kubectl authentication plugin:

   ```shell
   gcloud components install gke-gcloud-auth-plugin
   ```

1. Connect to the cluster:

   ```shell
   gcloud container clusters get-credentials CLUSTER_NAME --zone=CLUSTER_LOCATION
   ```

1. View the cluster configuration:

   ```shell
   kubectl config view
   ```

1. Verify that you are connected to the cluster:

   ```shell
   kubectl config current-context
   ```

## Install and configure the Kubernetes Operator

Now that you have a cluster, you're ready to install and configure the Kubernetes Operator.

1. Install `cert-manager`. Skip this step if you already have a certificate manager installed:

   ```shell
   kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.7.1/cert-manager.yaml
   ```

1. Install the Operator Lifecycle Manager (OLM), a tool that manages the Kubernetes Operators that
   run on the cluster:

   ```shell
   curl --silent --location "https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.24.0/install.sh" \
    | bash -s v0.24.0
   ```

1. Install the Kubernetes Operator:

   ```shell
   kubectl create -f https://operatorhub.io/install/gitlab-runner-operator.yaml
   ```

1. Operator Lifecycle Manager v0.25.0 and later only. Add your own certificate manager or use `cert-manager`.

   - To add your own certificate provider:

     1. In the `gitlab-runner-operator.yaml`, define the certificate namespace and certificate name in the `env` setting:

        ```shell
        cat > gitlab-runner-operator.yaml << EOF
        apiVersion: operators.coreos.com/v1alpha1
        kind: Subscription
        metadata:
        name: gitlab-runner-operator
        namespace: gitlab-ns
        spec:
        channel: stable
        name: gitlab-runner-operator
        source: operatorhubio-catalog
        ca: webhook-server-cert
        sourceNamespace: olm
        config:
        env:
           - name: CERTIFICATE_NAMESPACE
           value: cert_namespace_desired_value
           - name: CERTIFICATE_NAME
           value: cert_name_desired_value
        EOF
        ```

     1. Apply the `gitlab-runner-operator.yaml` to the Kubernetes cluster:

        ```shell
        kubectl apply -f gitlab-runner-operator.yaml
        ```

   - To use the `cert-manager`:

     1. Use the `certificate-issuer-install.yaml` to install a `Certificate` and `Issuer` in the default namespace, in addition
        to the operator installation:

        ```shell
        cat > certificate-issuer-install.yaml << EOF
        apiVersion: v1
        kind: Namespace
        metadata:
        labels:
           app.kubernetes.io/component: controller-manager
           app.kubernetes.io/managed-by: olm
           app.kubernetes.io/name: gitlab-runner-operator
        name: gitlab-runner-system
        ---
        apiVersion: cert-manager.io/v1
        kind: Certificate
        metadata:
        name: gitlab-runner-serving-cert
        namespace: gitlab-runner-system
        spec:
        dnsNames:
        - gitlab-runner-webhook-service.gitlab-runner-system.svc
        - gitlab-runner-webhook-service.gitlab-runner-system.svc.cluster.local
        issuerRef:
          kind: Issuer
          name: gitlab-runner-selfsigned-issuer
        secretName: webhook-server-cert
        ---
        apiVersion: cert-manager.io/v1
        kind: Issuer
        metadata:
        name: gitlab-runner-selfsigned-issuer
        namespace: gitlab-runner-system
        spec:
        selfSigned: {}
        EOF
        ```

     1. Apply the `certificate-issuer-install.yaml` to the Kubernetes cluster:

        ```shell
        kubectl create -f certificate-issuer-install.yaml
        ```

1. Create a secret that contains the `runner-registration-token` from your
   GitLab project:

   ```shell
    cat > gitlab-runner-secret.yml << EOF
    apiVersion: v1
    kind: Secret
    metadata:
      name: gitlab-runner-secret
    type: Opaque
    stringData:
      runner-token: YOUR_RUNNER_AUTHENTICATION_TOKEN
    EOF
   ```

1. Apply the secret:

   ```shell
   kubectl apply -f gitlab-runner-secret.yml
   ```

1. Create the custom resource definition file and include the following information:

   ```shell
    cat > gitlab-runner.yml << EOF
    apiVersion: apps.gitlab.com/v1beta2
    kind: Runner
    metadata:
      name: gitlab-runner
    spec:
      gitlabUrl: https://gitlab.example.com
      buildImage: alpine
      token: gitlab-runner-secret
    EOF
   ```

1. Apply the custom resource definition file:

   ```shell
   kubectl apply -f gitlab-runner.yml
   ```

That's it! You've configured GitLab Runner to use the GKE.
In the next step, you can check if your configuration is working.

## Verify your configuration

To check if runners are running in the GKE cluster, you can either:

- Use the following command:

  ```shell
  kubectl get pods
  ```

  You should see the following output. This shows that your runners
  are running in the GKE cluster:

  ```plaintext
  NAME                             READY   STATUS    RESTARTS   AGE
  gitlab-runner-hash-short_hash    1/1     Running   0          5m
  ```

- Check the job log in GitLab:
  1. On the left sidebar, select **Search or go to** and find your project.
  1. Select **Build > Jobs** and find the job.
  1. To view the job log, select the job status.
