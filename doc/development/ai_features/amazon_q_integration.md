---
stage: AI Platform
group: AI Model Services
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Amazon Q integration for testing and evaluation
---

This guide combines and builds on the following guides and sources. It describes Amazon Q set-up for testing and evaluation purposes:

- [Set up GitLab Duo with Amazon Q](../../user/duo_amazon_q/setup.md)
- [code-suggestions development guide](code_suggestions.md)

This guide describes how to set up Amazon Q in a GitLab Linux package running in a VM, using the staging AI Gateway. The reason we need a GitLab Linux package instance instead of GDK is that the GitLab instance needs an HTTPS URL that can be accessed by Amazon Q.

## Install and configure a GitLab Linux package on a virtual machine

1. Create a VM in AWS

   1. Go to [cloud sandbox](https://gitlabsandbox.cloud/cloud), and login with OKTA
   1. Click "Create Individual Account", and choose `aws-***` (not `aws-services-***` or `aws-dedicated-***`). This will create a AWS sandbox and display login credentials
   1. Configure an EC2 machine

   A few things to note:
   - Need to enable both HTTP and HTTPS traffic under firewall setting.
   - Copy the external IP of the VM instance created.

1. Install GitLab
   1. Follow this [guide](https://about.gitlab.com/install/#ubuntu) on how to install GitLab Linux package.
      We need to set up the external URL and an initial password. Install GitLab using the following command:

      ```shell
      sudo GITLAB_ROOT_PASSWORD="your_password" EXTERNAL_URL="https://<vm-instance-external-ip>.nip.io" apt install gitlab-ee
      ```

      This will use nip.io as the DNS service so the GitLab instance can be accessed through HTTPs

1. Config the newly installed GitLab instance
   1. SSH into the VM, and add the following config into `/etc/gitlab/gitlab.rb`

      ```ruby
      gitlab_rails['env'] = {
        "GITLAB_LICENSE_MODE" => "test",
        "CUSTOMER_PORTAL_URL" => "https://customers.staging.gitlab.com",
        "CLOUD_CONNECTOR_BASE_URL" => "https://cloud.staging.gitlab.com"
      }
      ```

   1. Apply the config changes by `sudo gitlab-ctl reconfigure`
1. Obtain and activate a **Self-Managed - Ultimate & Duo with Amazon Q** license

   > [!note]
   > Amazon Q requires a GitLab Duo with Amazon Q subscription. An Ultimate subscription is not
   > sufficient, and GitLab Duo with Amazon Q is a distinct subscription type, not an add-on.

   1. GitLab team members cannot create this license themselves. Request one in the
      `#s_fulfillment_engineering` Slack channel.
   1. After you receive an activation code (by email, or from the [Customers Portal](https://customers.gitlab.com/)), go to the GitLab instance created earlier
      (`https://<vm-instance-external-ip>.nip.io`) and sign in with the root account. In the left sidebar,
      go to **Admin** > **Subscription**, and enter the activation code.

## Create and configure an AWS sandbox

1. Follow the [same step](#install-and-configure-a-gitlab-linux-package-on-a-virtual-machine) described above on how to create an AWS sandbox if you haven't had one already.
1. Login into the newly created AWS account and create an **Identity Provider** following this [instruction](../../user/duo_amazon_q/setup.md#create-an-iam-identity-provider) with slight modifications:

   - Provider URL: `https://glgo.staging.runway.gitlab.net/cc/oidc/<your_gitlab_instance_id>`
   - Audience: `gitlab-cc-<your_gitlab_instance_id>`

   The GitLab instance ID can be found at `<gitlab_url>/admin/ai/amazon_q_settings`
1. Create a new role using the identity provider. For this, we can follow [this section](../../user/duo_amazon_q/setup.md#create-an-iam-role) exactly.

## Add Amazon Q to GitLab

1. Follow [Enter the ARN in GitLab and enable Amazon Q](../../user/duo_amazon_q/setup.md#enter-the-arn-in-gitlab-and-enable-amazon-q) exactly.
1. Amazon Q is now configured. You can test it using any of the [documented capabilities](../../user/duo_amazon_q/_index.md).
