---
type: concepts, howto
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Amazon Web Services Cognito **(FREE SELF)**

Amazon Cognito lets you add user sign-up, sign-in, and access control to your GitLab instance.
The following documentation enables Cognito as an OAuth2 provider.

## Configure AWS Cognito

To enable the [AWS Cognito](https://aws.amazon.com/cognito/) OAuth2 OmniAuth provider, register your application with Cognito,
where it will generate a Client ID and Client Secret for your application.
Any settings you configure in the following procedure can be modified later.
The following steps enable AWS Cognito as an authentication provider:

1. Sign in to the [AWS console](https://console.aws.amazon.com/console/home).
1. Select **Cognito** from the **Services** menu.
1. Select **Manage User Pools**, and click the **Create a user pool** button in the top right corner.
1. Enter the pool name and then click the **Step through settings** button.
1. Under **How do you want your end users to sign in?**, select **Email address or phone number** and **Allow email addresses**.
1. Under **Which standard attributes do you want to require?**, select **email**.
1. Go to the next steps of configuration and set the rest of the settings to suit your needs - in the basic setup they are not related to GitLab configuration.
1. In the **App clients** settings, click **Add an app client**, add **App client name** and select the **Enable username password based authentication** check box.
1. Click **Create app client**.
1. In the next step, you can set up AWS Lambda functions for sending emails. You can then finish creating the pool.
1. After creating the user pool, go to **App client settings** and provide the required information:

   - **Enabled Identity Providers** - select all
   - **Callback URL** - `https://gitlab.example.com/users/auth/cognito/callback`
     - Substitute the URL of your GitLab instance for `gitlab.example.com`
   - **Allowed OAuth Flows** - Authorization code grant
   - **Allowed OAuth2 Scopes** - `email`, `openid`, and `profile`

1. Save changes for the app client settings.
1. Under **Domain name** include the AWS domain name for your AWS Cognito application.
1. Under **App Clients**, find your app client ID and app client secret. These values correspond to the OAuth2 Client ID and Client Secret. Save these values.

## Configure GitLab

1. See [Initial OmniAuth Configuration](../../integration/omniauth.md#initial-omniauth-configuration) for initial settings.
1. On your GitLab server, open the configuration file.

   **For Omnibus installations**

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

1. In the following code block, substitute the Client ID (`app_id`), Client Secret (`app_secret`), and the Amazon domain name (`site`) for your AWS Cognito application.
Include the code block in the `/etc/gitlab/gitlab.rb` file:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['cognito']
   gitlab_rails['omniauth_providers'] = [
     {
       "name" => "cognito",
       # "label" => "Cognito",
       # "icon" => nil,   # Optional icon URL
       "app_id" => "CLIENT ID",
       "app_secret" => "CLIENT SECRET",
       "args" => {
         "scope" => "openid profile email",
         client_options: {
           'site' => 'https://your_domain.auth.your_region.amazoncognito.com',
           'authorize_url' => '/oauth2/authorize',
           'token_url' => '/oauth2/token',
           'user_info_url' => '/oauth2/userInfo'
         },
         user_response_structure: {
           root_path: [],
           id_path: ['sub'],
           attributes: { nickname: 'email', name: 'email', email: 'email' }
         },
         name: 'cognito',
         strategy_class: "OmniAuth::Strategies::OAuth2Generic"
       }
     }
   ]
   ```

1. Save the configuration file.
1. Save the file and [reconfigure](../restart_gitlab.md#omnibus-gitlab-reconfigure) GitLab for the changes to take effect.

Your sign-in page should now display a Cognito button below the regular sign-in form.
To begin the authentication process, click the icon, and AWS Cognito will ask the user to sign in and authorize the GitLab application.
If successful, the user will be redirected and signed in to your GitLab instance.

For more information, see the [Initial OmniAuth Configuration](../../integration/omniauth.md#initial-omniauth-configuration).
