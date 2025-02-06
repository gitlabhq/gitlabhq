---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use AliCloud as an OmniAuth authentication provider
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed

You can enable the AliCloud OAuth 2.0 OmniAuth provider and sign in to
GitLab using your AliCloud account.

## Create an AliCloud application

Sign in to the AliCloud platform and create an application on it. AliCloud generates a client ID and secret key for you to use.

1. Sign in to the [AliCloud platform](https://account.aliyun.com/login/login.htm).

1. Go to the [OAuth application management page](https://ram.console.aliyun.com/applications).

1. Select **Create Application**.

1. Fill in the application details:

   - **Application Name**: This can be anything.
   - **Display Name**: This can be anything.
   - **Callback URL**: This URL should be formatted as `'GitLab instance URL' + '/users/auth/alicloud/callback'`. For example, `http://test.gitlab.com/users/auth/alicloud/callback`.

   Select **Save**.

1. Add OAuth scopes in the application details page:

   1. Under the **Application Name** column, select the name of the application you created. The application's details page opens.
   1. Under the **Application OAuth Scopes** tab, select **Add OAuth Scopes**.
   1. Select the **aliuid** and **profile** checkboxes.
   1. Select **OK**.

   ![AliCloud OAuth scope](img/alicloud_scope_v14_10.png)

1. Create a secret in the application details page:

   1. Under the **App Secrets** tab, select **Create Secret**.
   1. Copy the SecretValue generated.

## Enable AliCloud OAuth in GitLab

1. On your GitLab server, open the configuration file.

   - For Linux package installations:

     ```shell
     sudo editor /etc/gitlab/gitlab.rb
     ```

   - For self-compiled installations:

     ```shell
     cd /home/git/gitlab

     sudo -u git -H editor config/gitlab.yml
     ```

1. Configure the [common settings](omniauth.md#configure-common-settings)
   to add `alicloud` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.

1. Add the provider configuration. Replace `YOUR_APP_ID` with the ID on the application details page
   and `YOUR_APP_SECRET` with the **SecretValue** you got when you registered the AliCloud application.

   - For Linux package installations:

     ```ruby
       gitlab_rails['omniauth_providers'] = [
         {
           name: "alicloud",
           app_id: "YOUR_APP_ID",
           app_secret: "YOUR_APP_SECRET"
         }
       ]
     ```

   - For self-compiled installations:

     ```yaml
     - { name: 'alicloud',
         app_id: 'YOUR_APP_ID',
         app_secret: 'YOUR_APP_SECRET' }
     ```

1. Save the configuration file.

1. [Reconfigure GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation)
   if you installed using the Linux package, or [restart GitLab](../administration/restart_gitlab.md#self-compiled-installations)
   if you installed from source.
