---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Managing Kubernetes secrets in a GitOps workflow (deprecated)

WARNING:
This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/406545) in GitLab 16.2.
To manage cluster resources with GitOps, you should use the [Flux integration](../../../clusters/agent/gitops.md).

You should never store Kubernetes secrets in unencrypted form in a `git` repository. If you use a GitOps workflow, you can follow these steps to securely manage your secrets.

1. Set up the Sealed Secrets controller to manage secrets.
1. Deploy Docker credentials so the cluster can pull images from the GitLab container registry.

## Prerequisites

This setup requires:

- A [GitLab agent for Kubernetes configured for the GitOps workflow](../gitops.md).
- Access to the cluster to finish the setup.

## Set up the Sealed Secrets controller to manage secrets

You can use the [Sealed Secrets controller](https://github.com/bitnami-labs/sealed-secrets) to store encrypted secrets securely in a `git` repository. The controller decrypts the secret into a standard Kubernetes `Secret` kind resource.

1. Go to [the Sealed Secrets release page](https://github.com/bitnami-labs/sealed-secrets/releases) and download the most recent `controller.yaml` file.
1. In GitLab, go to the project that contains your Kubernetes manifests and upload the `controller.yaml` file.
1. Open the agent configuration file (`config.yaml`) and if needed, update the `paths.glob` pattern to match the Sealed Secrets manifest.
1. Commit and push the changes to GitLab.
1. Confirm that the Sealed Secrets controller was installed successfully:

   ```shell
   kubectl get pods -lname=sealed-secrets-controller -n kube-system
   ```

1. Install the `kubeseal` command line utility by following [the Sealed Secrets instructions](https://github.com/bitnami-labs/sealed-secrets#homebrew).
1. Get the public key you need to encrypt secrets without direct access to the cluster:

   ```shell
   kubeseal --fetch-cert > public.pem
   ```

1. Commit the public key to the repository.

For more details on how the Sealed Secrets controller works, view [the usage instructions](https://github.com/bitnami-labs/sealed-secrets/blob/main/README.md#usage).

## Deploy Docker credentials

To deploy containers from the GitLab container registry, you must configure the cluster with the proper Docker registry credentials. You can achieve this by deploying a `docker-registry` type secret.

1. Generate a GitLab token with at least `read-registry` rights. The token can be either a Personal or a Project Access Token.
1. Create a Kubernetes secret manifest YAML file. Update the values as needed:

   ```shell
   kubectl create secret docker-registry gitlab-credentials --docker-server=registry.gitlab.example.com --docker-username=<gitlab-username> --docker-password=<gitlab-token> --docker-email=<gitlab-user-email> -n <namespace> --dry-run=client -o yaml > gitlab-credentials.yaml
   ```

1. Encrypt the secret into a `SealedSecret` manifest:

   ```shell
   kubeseal --format=yaml --cert=public.pem < gitlab-credentials.yaml > gitlab-credentials.sealed.yaml
   ```
