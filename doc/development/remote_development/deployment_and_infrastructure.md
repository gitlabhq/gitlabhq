---
stage: Create
group: Remote Development
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Install GitLab for workspace testing
---

Deploy GitLab with workspace support to test your workspace changes end-to-end (E2E).
You can deploy using either Cloud Native GitLab (CNG) with Helm charts or Linux packages.

## Prerequisites

- [CNG prerequisites](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/doc/quickstart/_index.md?ref_type=heads#prerequisites)
- [AWS CLI configured](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html)
- Access to the [Sandbox Cloud](https://gitlabsandbox.cloud/login)

## Test workspace changes with CNG

Use this method to test workspace changes with a cloud-native GitLab deployment. The instructions
are AWS-focused.

### Set up cloud infrastructure

1. Access the [GitLab cloud sandbox](https://gitlabsandbox.cloud/cloud) and sign in to an AWS account.
1. In the AWS Management Console, go to Route 53 and register a domain.
1. In the Route 53 dashboard, create a public hosted DNS zone with the domain.
1. Set up a Kubernetes cluster in EKS and grant your user an `AmazonEKSClusterAdminPolicy` policy.
1. Add a `kubeconfig` entry to your local shell:

   ```shell
   aws eks update-kubeconfig --name <eks-cluster> --region <region>
   kubectl config use-context <context-name>
   ```

### Install GitLab with Helm chart

1. Create a namespace for the GitLab Helm chart:

   ```shell
   kubectl create namespace <gitlab-helm-chart-namespace>
   ```

1. Create a generic secret containing your GitLab license:

   ```shell
    kubectl create secret generic <gitlab-license-secret-name> \
        --from-file=license=<path-to-license> \
        --namespace=<gitlab-helm-chart-namespace>
   ```

1. Follow the [CNG quickstart guide](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/doc/quickstart/_index.md?ref_type=heads#install-gitlab) to install GitLab with these modifications:

   1. Set your GitLab domain to a subdomain based on the domain you registered.
      For example, if your domain is `workspace-test.com`, use `mygitlab.workspaces-test.com`.
   1. Add these CLI options to configure the license:

      ```shell
      --set global.extraEnv.GITLAB_LICENSE_MODE=test \
      --set global.extraEnv.CUSTOMER_PORTAL_URL=https://customers.staging.gitlab.com \
      --set global.gitlab.license.secret=<gitlab-license-secret-name>
      ```

1. Extract the publicly reachable IP by inspecting the Ingress resource:

   ```shell
    kubectl get ingress -n <gitlab-helm-chart-namespace>
   ```

1. In the AWS hosted zones dashboard, create an `ALIAS` record of type `A` with your subdomain pointing
   to the extracted address.
1. Access your GitLab deployment.

For other GitLab-specific configuration and setup, see the
[CNG repository](https://gitlab.com/gitLab-org/charts/gitlab/-/blob/master/).

### Verify the Helm deployment

After installation, verify that:

- You can access the GitLab deployment.
- KAS pod logs show messages relevant to your changes:

  ```shell
  kubectl logs -f deployment/gitlab-kas -n <gitlab-helm-chart-namespace>
  ```

### Clean up cloud resources

When you finish testing:

1. Remove DNS records from Route 53.
1. Uninstall the Helm release:

   ```shell
    helm uninstall <release-name> -n <gitlab-helm-chart-namespace>
   ```

## Test workspace changes with Linux packages

Use this method to test workspace changes with a Linux package GitLab installation. The instructions
are AWS-focused.

### Set up E2C infrastructure

1. Access the [GitLab cloud sandbox](https://gitlabsandbox.cloud/cloud) and sign in to an AWS account.
1. Provision an E2C instance that meets the Linux package requirements.
1. Save the key pair for SSH access.
1. Optional. Acquire a subdomain and map the E2C instance's public IP to it to expose GitLab over a
   public domain name.

### Install GitLab with Linux package

1. Forward your GitLab license to the VM using a tool like `scp`.
1. Trigger an `ee-package` build on the merge request containing the changes you want to test.
1. Download the built package to the VM and install it:

   ```shell
   # Download the package for your OS/architecture
   wget <package-url>

   # Install the package (example for Ubuntu/Debian)
   sudo dpkg -i <package-file>
   ```

1. Configure your GitLab instance following the CLI instructions. Pay attention to:

   - External URLs
   - License file location
   - [Staging customer platform for license validation](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/doc/development/setup.md?ref_type=heads#use-customers-portal-staging-in-gitlab)
   - KAS configuration
   - Workspace-related KAS configuration

1. Complete the installation and access your GitLab deployment.

### Verify the package installation

After installation, verify that:

- You can access the GitLab deployment.
- All services are running:

  ```shell
  sudo gitlab-ctl status
  ```

- KAS logs show expected behavior:

  ```shell
  sudo gitlab-ctl tail gitlab-kas
  ```

### Clean up E2C resources

When you finish testing:

1. Remove DNS records from Route 53.
1. Stop or delete the E2C instance.

## Troubleshooting

### Timing errors

- CNG deployments: If KAS attempts to call agent endpoints but errors out, restart the KAS deployment:

  ```shell
  kubectl rollout restart deployment/gitlab-kas -n <gitlab-helm-chart-namespace>
  ```

- Linux package deployments: If KAS attempts to call agent endpoints but errors out because the GitLab web service cannot be reached, restart the KAS service:

  ```shell
  sudo gitlab-ctl restart gitlab-kas
  ```

### Domain reuse issues

If you reuse a domain name and encounter a `422` error on your GitLab deployment, delete cookies associated with that domain.

### Testing dependent services

If you're testing against other services, like GitLab Rails, with an unmerged merge request, inspect
the merge request's pipeline for the CNG image build and update your CNG chart to use that image.
