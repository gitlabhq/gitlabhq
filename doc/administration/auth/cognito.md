---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use AWS Cognito as an OAuth 2.0 authentication provider
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Amazon Web Services (AWS) Cognito lets you add user sign-up, sign-in, and access control to your GitLab instance.
The following documentation enables AWS Cognito as an OAuth 2.0 provider.

## Configure AWS Cognito

To enable the [AWS Cognito](https://aws.amazon.com/cognito/) OAuth 2.0 OmniAuth provider, register your application with Cognito. This process generates a Client ID and Client Secret for your application.
To enable AWS Cognito as an authentication provider, complete the following steps. You can modify any settings you configure later.

1. Sign in to the [AWS console](https://console.aws.amazon.com/console/home).
1. From the **Services** menu, select **Cognito**.
1. Select **Manage User Pools** and then in the upper-right corner, select **Create a user pool**.
1. Enter the user pool name and then select **Step through settings**.
1. Under **How do you want your end users to sign in?**, select **Email address or phone number** and **Allow email addresses**.
1. Under **Which standard attributes do you want to require?**, select **email**.
1. Configure the remaining settings to suit your needs. In the basic setup, these settings do not affect GitLab configuration.
1. In the **App clients** settings:
   1. Select **Add an app client**.
   1. Add the **App client name**.
   1. Select the **Enable username password based authentication** checkbox.
1. Select **Create app client**.
1. Set up the AWS Lambda functions for sending emails and finish creating the user pool.
1. After creating the user pool, go to **App client settings** and provide the required information:

   - **Enabled Identity Providers** - select all
   - **Callback URL** - `https://<your_gitlab_instance_url>/users/auth/cognito/callback`
   - **Allowed OAuth Flows** - Authorization code grant
   - **Allowed OAuth 2.0 Scopes** - `email`, `openid`, and `profile`

1. Save changes for the app client settings.
1. Under **Domain name**, include the AWS domain name for your AWS Cognito application.
1. Under **App Clients**, find your app client ID. Select **Show details** to display the app client secret. These values correspond to the OAuth 2.0 Client ID and Client Secret. Save these values.

## Configure GitLab

1. Configure the [common settings](../../integration/omniauth.md#configure-common-settings)
   to add `cognito` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.
1. On your GitLab server, open the configuration file. For Linux package installations:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

1. In the following code block, enter your AWS Cognito application information in the following parameters:

   - `app_id`: Your client ID.
   - `app_secret`: Your client secret.
   - `site`: Your Amazon domain and region.

   Include the code block in the `/etc/gitlab/gitlab.rb` file:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['cognito']
   gitlab_rails['omniauth_providers'] = [
     {
       name: "cognito",
       label: "Provider name", # optional label for login button, defaults to "Cognito"
       icon: nil,   # Optional icon URL
       app_id: "<client_id>",
       app_secret: "<client_secret>",
       args: {
         scope: "openid profile email",
         client_options: {
           site: "https://<your_domain>.auth.<your_region>.amazoncognito.com",
           authorize_url: "/oauth2/authorize",
           token_url: "/oauth2/token",
           user_info_url: "/oauth2/userInfo"
         },
         user_response_structure: {
           root_path: [],
           id_path: ["sub"],
           attributes: { nickname: "email", name: "email", email: "email" }
         },
         name: "cognito",
         strategy_class: "OmniAuth::Strategies::OAuth2Generic"
       }
     }
   ]
   ```

1. Save the configuration file.
1. Save the file and [reconfigure](../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab for the changes to take effect.

Your sign-in page should now display a Cognito option below the regular sign-in form.
Select this option to begin the authentication process.
AWS Cognito then asks you to sign in and authorize the GitLab application.
If the authorization is successful, you're redirected and signed in to your GitLab instance.

For more information, see [Configure common settings](../../integration/omniauth.md#configure-common-settings).
