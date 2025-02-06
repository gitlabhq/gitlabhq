---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use Salesforce as an OAuth 2.0 authentication provider
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can integrate your GitLab instance with [Salesforce](https://www.salesforce.com/) to enable users to sign in to your GitLab instance with their Salesforce account.

## Create a Salesforce Connected App

To enable Salesforce OmniAuth provider, you must use the Salesforce credentials for your GitLab instance.
To get the credentials (a pair of Client ID and Client Secret), you must [create a Connected App](https://help.salesforce.com/s/articleView?language=en_US&id=sf.connected_app_create.htm&type=5) on Salesforce.

1. Sign in to [Salesforce](https://login.salesforce.com/).

1. In Setup, enter `App Manager` in the Quick Find box, select **App Manager**, then select **New Connected App**.

1. Fill in the application details into the following fields:
   - **Connected App Name** and **API Name**: Set to any value but consider something like `<Organization>'s GitLab`, `<Your Name>'s GitLab`, or something else that is descriptive.
   - **Contact Email**: Enter the contact email for Salesforce to use when contacting you or your support team.
   - **Description**: Description for the application.

   ![Salesforce App Details](img/salesforce_app_details_v11_11.png)

1. Select **API (Enable OAuth Settings)** and select **Enable OAuth Settings**.
1. Fill in the application details into the following fields:
   - **Callback URL**: The callback URL of your GitLab installation. For example, `https://gitlab.example.com/users/auth/salesforce/callback`.
   - **Selected OAuth Scopes**: Move `Access your basic information (id, profile, email, address, phone)` and `Allow access to your unique identifier (openid)` to the right column.

   ![Salesforce OAuth App Details](img/salesforce_oauth_app_details_v11_11.png)

1. Select **Save**.

1. On your GitLab server, open the configuration file.

   For Linux package installations:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For self-compiled installations:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H editor config/gitlab.yml
   ```

1. Configure the [common settings](omniauth.md#configure-common-settings)
   to add `salesforce` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.

1. Add the provider configuration.

   For Linux package installations:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "salesforce",
       # label: "Provider name", # optional label for login button, defaults to "Salesforce"
       app_id: "SALESFORCE_CLIENT_ID",
       app_secret: "SALESFORCE_CLIENT_SECRET"
     }
   ]
   ```

   For self-compiled installations:

   ```yaml
   - { name: 'salesforce',
       # label: 'Provider name', # optional label for login button, defaults to "Salesforce"
       app_id: 'SALESFORCE_CLIENT_ID',
       app_secret: 'SALESFORCE_CLIENT_SECRET'
   }
   ```

1. Change `SALESFORCE_CLIENT_ID` to the Consumer Key from the Salesforce connected application page.
1. Change `SALESFORCE_CLIENT_SECRET` to the Consumer Secret from the Salesforce connected application page.

   ![Salesforce App Secret Details](img/salesforce_app_secret_details_v11_11.png)

1. Save the configuration file.

1. For the changes to take effect:
   - If you installed using the Linux package, [reconfigure GitLab](../administration/restart_gitlab.md#reconfigure-a-linux-package-installation).
   - If you self-compiled your installation, [restart GitLab](../administration/restart_gitlab.md#self-compiled-installations).

On the sign in page, there should now be a Salesforce icon below the regular sign in form.
Select the icon to begin the authentication process. Salesforce asks the user to sign in and authorize the GitLab application.
If everything goes well, the user is returned to GitLab and is signed in.

NOTE:
GitLab requires the email address of each new user. After the user is signed in
using Salesforce, GitLab redirects the user to the profile page where they must
provide the email and verify the email.
