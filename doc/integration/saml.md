---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SAML SSO for GitLab Self-Managed
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

This page describes how to set up instance-wide SAML single sign on (SSO) for
GitLab Self-Managed.

You can configure GitLab to act as a SAML service provider (SP). This allows
GitLab to consume assertions from a SAML identity provider (IdP), such as
Okta, to authenticate users.

To set up SAML on GitLab.com, see [SAML SSO for GitLab.com groups](../user/group/saml_sso/_index.md).

For more information on:

- OmniAuth provider settings, see the [OmniAuth documentation](omniauth.md).
- Commonly-used terms, see the [glossary](#glossary).

## Configure SAML support in GitLab

::Tabs

:::TabTitle Linux package (Omnibus)

1. Make sure GitLab is [configured with HTTPS](https://docs.gitlab.com/omnibus/settings/ssl/).
1. Configure the [common settings](omniauth.md#configure-common-settings)
   to add `saml` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.
1. To allow your users to use SAML to sign up without having to manually create
   an account first, edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
   gitlab_rails['omniauth_block_auto_created_users'] = false
   ```

1. Optional. You should automatically link a first-time SAML sign-in with existing GitLab users if their
   email addresses match. To do this, add the following setting in `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_auto_link_saml_user'] = true
   ```

   Only the GitLab account's primary email address is matched against the email in the SAML response.

   Alternatively, a user can manually link their SAML identity to an existing GitLab
   account by [enabling OmniAuth for an existing user](omniauth.md#enable-omniauth-for-an-existing-user).

1. Configure the following attributes so your SAML users cannot change them:

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - `Email` when used with `omniauth_auto_link_saml_user`.

   If users can change these attributes, they can sign in as other authorized users.
   See your SAML IdP documentation for information on how to make these attributes
   unchangeable.

1. Edit `/etc/gitlab/gitlab.rb` and add the provider configuration:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "saml",
       label: "Provider name", # optional label for login button, defaults to "Saml"
       args: {
         assertion_consumer_service_url: "https://gitlab.example.com/users/auth/saml/callback",
         idp_cert_fingerprint: "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8",
         idp_sso_target_url: "https://login.example.com/idp",
         issuer: "https://gitlab.example.com",
         name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
       }
     }
   ]
   ```

   Where:

   - `assertion_consumer_service_url`: The GitLab HTTPS endpoint
     (append `/users/auth/saml/callback` to the HTTPS URL of your GitLab installation).
   - `idp_cert_fingerprint`: Your IdP value. It must be a SHA1 fingerprint.
     For more information on these values, see the
     [OmniAuth SAML documentation](https://github.com/omniauth/omniauth-saml).
     For more information on other configuration settings, see
     [configuring SAML on your IdP](#configure-saml-on-your-idp).
   - `idp_sso_target_url`: Your IdP value.
   - `issuer`: Change to a unique name, which identifies the application to the IdP.
   - `name_identifier_format`: Your IdP value.

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Make sure GitLab is [configured with HTTPS](https://docs.gitlab.com/charts/installation/tls.html).
1. Configure the [common settings](omniauth.md#configure-common-settings)
   to add `saml` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.
1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. To allow your users to use SAML to sign up without having to manually create
   an account first, edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         enabled: true
         allowSingleSignOn: ['saml']
         blockAutoCreatedUsers: false
   ```

1. Optional. You can automatically link SAML users with existing GitLab users if their
   email addresses match by adding the following setting in `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         autoLinkSamlUser: true
   ```

   Alternatively, a user can manually link their SAML identity to an existing GitLab
   account by [enabling OmniAuth for an existing user](omniauth.md#enable-omniauth-for-an-existing-user).

1. Configure the following attributes so your SAML users cannot change them:

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - `Email` when used with `omniauth_auto_link_saml_user`.

   If users can change these attributes, they can sign in as other authorized users.
   See your SAML IdP documentation for information on how to make these attributes
   unchangeable.

1. Put the following content in a file named `saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

   ```yaml
   name: 'saml'
   label: 'Provider name' # optional label for login button, defaults to "Saml"
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

   Where:

   - `assertion_consumer_service_url`: The GitLab HTTPS endpoint
     (append `/users/auth/saml/callback` to the HTTPS URL of your GitLab installation).
   - `idp_cert_fingerprint`: Your IdP value. It must be a SHA1 fingerprint.
     For more information on these values, see the
     [OmniAuth SAML documentation](https://github.com/omniauth/omniauth-saml).
     For more information on other configuration settings, see
     [configuring SAML on your IdP](#configure-saml-on-your-idp).
   - `idp_sso_target_url`: Your IdP value.
   - `issuer`: Change to a unique name, which identifies the application to the IdP.
   - `name_identifier_format`: Your IdP value.

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Edit `gitlab_values.yaml` and add the provider configuration:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Make sure GitLab is [configured with HTTPS](https://docs.gitlab.com/omnibus/settings/ssl/).
1. Configure the [common settings](omniauth.md#configure-common-settings)
   to add `saml` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.
1. To allow your users to use SAML to sign up without having to manually create
   an account first, edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
           gitlab_rails['omniauth_block_auto_created_users'] = false
   ```

1. Optional. You can automatically link SAML users with existing GitLab users if their
   email addresses match by adding the following setting in `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_auto_link_saml_user'] = true
   ```

   Alternatively, a user can manually link their SAML identity to an existing GitLab
   account by [enabling OmniAuth for an existing user](omniauth.md#enable-omniauth-for-an-existing-user).

1. Configure the following attributes so your SAML users cannot change them:

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - `Email` when used with `omniauth_auto_link_saml_user`.

   If users can change these attributes, they can sign in as other authorized users.
   See your SAML IdP documentation for information on how to make these attributes
   unchangeable.

1. Edit `docker-compose.yml` and add the provider configuration:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
             {
               name: "saml",
               label: "Provider name", # optional label for login button, defaults to "Saml"
               args: {
                 assertion_consumer_service_url: "https://gitlab.example.com/users/auth/saml/callback",
                 idp_cert_fingerprint: "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8",
                 idp_sso_target_url: "https://login.example.com/idp",
                 issuer: "https://gitlab.example.com",
                 name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
               }
             }
           ]
   ```

   Where:

   - `assertion_consumer_service_url`: The GitLab HTTPS endpoint
     (append `/users/auth/saml/callback` to the HTTPS URL of your GitLab installation).
   - `idp_cert_fingerprint`: Your IdP value. It must be a SHA1 fingerprint.
     For more information on these values, see the
     [OmniAuth SAML documentation](https://github.com/omniauth/omniauth-saml).
     For more information on other configuration settings, see
     [configuring SAML on your IdP](#configure-saml-on-your-idp).
   - `idp_sso_target_url`: Your IdP value.
   - `issuer`: Change to a unique name, which identifies the application to the IdP.
   - `name_identifier_format`: Your IdP value.

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Make sure GitLab is [configured with HTTPS](../install/installation.md#using-https).
1. Configure the [common settings](omniauth.md#configure-common-settings)
   to add `saml` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.
1. To allow your users to use SAML to sign up without having to manually create
   an account first, edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       enabled: true
       allow_single_sign_on: ["saml"]
       block_auto_created_users: false
   ```

1. Optional. You can automatically link SAML users with existing GitLab users if their
   email addresses match by adding the following setting in `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       auto_link_saml_user: true
   ```

   Alternatively, a user can manually link their SAML identity to an existing GitLab
   account by [enabling OmniAuth for an existing user](omniauth.md#enable-omniauth-for-an-existing-user).

1. Configure the following attributes so your SAML users cannot change them:

   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - `Email` when used with `omniauth_auto_link_saml_user`.

   If users can change these attributes, they can sign in as other authorized users.
   See your SAML IdP documentation for information on how to make these attributes
   unchangeable.

1. Edit `/home/git/gitlab/config/gitlab.yml` and add the provider configuration:

   ```yaml
   omniauth:
     providers:
       - {
         name: 'saml',
         label: 'Provider name', # optional label for login button, defaults to "Saml"
         args: {
           assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
           idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
           idp_sso_target_url: 'https://login.example.com/idp',
           issuer: 'https://gitlab.example.com',
           name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
         }
       }
   ```

   Where:

   - `assertion_consumer_service_url`: The GitLab HTTPS endpoint
     (append `/users/auth/saml/callback` to the HTTPS URL of your GitLab installation).
   - `idp_cert_fingerprint`: Your IdP value. It must be a SHA1 fingerprint.
     For more information on these values, see the
     [OmniAuth SAML documentation](https://github.com/omniauth/omniauth-saml).
     For more information on other configuration settings, see
     [configuring SAML on your IdP](#configure-saml-on-your-idp).
   - `idp_sso_target_url`: Your IdP value.
   - `issuer`: Change to a unique name, which identifies the application to the IdP.
   - `name_identifier_format`: Your IdP value.

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### Register GitLab in your SAML IdP

1. Register the GitLab SP in your SAML IdP, using the application name specified in `issuer`.

1. To provide configuration information to the IdP, build a metadata URL for the
   application. To build the metadata URL for GitLab, append `users/auth/saml/metadata`
   to the HTTPS URL of your GitLab installation. For example:

   ```plaintext
   https://gitlab.example.com/users/auth/saml/metadata
   ```

   At a minimum the IdP **must** provide a claim containing the user's email address
   using `email` or `mail`. For more information on other available claims, see
   [configuring assertions](#configure-assertions).

1. On the sign in page there should now be a SAML icon below the regular sign in form.
   Select the icon to begin the authentication process. If authentication is successful,
   you are returned to GitLab and signed in.

### Configure SAML on your IdP

To configure a SAML application on your IdP, you need at least the following information:

- Assertion consumer service URL.
- Issuer.
- [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
- [Email address claim](#configure-assertions).

For an example configuration, see [set up identity providers](#set-up-identity-providers).

Your IdP may need additional configuration. For more information, see
[additional configuration for SAML apps on your IdP](#additional-configuration-for-saml-apps-on-your-idp).

### Configure GitLab to use multiple SAML IdPs

You can configure GitLab to use multiple SAML IdPs if:

- Each provider has a unique name set that matches a name set in `args`.
- The providers' names are used:
  - In OmniAuth configuration for properties based on the provider name. For example,
    `allowBypassTwoFactor`, `allowSingleSignOn`, and `syncProfileFromProvider`.
  - For association to each existing user as an additional identity.
- The `assertion_consumer_service_url` matches the provider name.
- The `strategy_class` is explicitly set because it cannot be inferred from provider
  name.

NOTE:
When you configure multiple SAML IdPs, to ensure that SAML Group Links work, you must configure all SAML IdPs to contain group attributes in the SAML response. For more information, see [SAML Group Links](../user/group/saml_sso/group_sync.md).

To set up multiple SAML IdPs:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: 'saml', # This must match the following name configuration parameter
       label: 'Provider 1' # Differentiate the two buttons and providers in the UI
       args: {
               name: 'saml', # This is mandatory and must match the provider name
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback', # URL must match the name of the provider
               strategy_class: 'OmniAuth::Strategies::SAML',
               ... # Put here all the required arguments similar to a single provider
             },
     },
     {
       name: 'saml_2', # This must match the following name configuration parameter
       label: 'Provider 2' # Differentiate the two buttons and providers in the UI
       args: {
               name: 'saml_2', # This is mandatory and must match the provider name
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback', # URL must match the name of the provider
               strategy_class: 'OmniAuth::Strategies::SAML',
               ... # Put here all the required arguments similar to a single provider
             },
     }
   ]
   ```

   To allow your users to use SAML to sign up without having to manually create an
   account from either of the providers, add the following values to your configuration:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'saml_2']
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)
   for the first SAML provider:

   ```yaml
   name: 'saml' # At least one provider must be named 'saml'
   label: 'Provider 1' # Differentiate the two buttons and providers in the UI
   args:
     name: 'saml' # This is mandatory and must match the provider name
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback' # URL must match the name of the provider
     strategy_class: 'OmniAuth::Strategies::SAML' # Mandatory
     ... # Put here all the required arguments similar to a single provider
   ```

1. Put the following content in a file named `saml_2.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers)
   for the second SAML provider:

   ```yaml
   name: 'saml_2'
   label: 'Provider 2' # Differentiate the two buttons and providers in the UI
   args:
     name: 'saml_2' # This is mandatory and must match the provider name
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback' # URL must match the name of the provider
     strategy_class: 'OmniAuth::Strategies::SAML' # Mandatory
     ... # Put here all the required arguments similar to a single provider
   ```

1. Optional. Set additional SAML providers by following the same steps.
1. Create the Kubernetes Secrets:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml \
      --from-file=saml=saml.yaml \
      --from-file=saml_2=saml_2.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
             key: saml
           - secret: gitlab-saml
             key: saml_2
   ```

   To allow your users to use SAML to sign up without having to manually create an
   account from either of the providers, add the following values to your configuration:

   ```yaml
   global:
     appConfig:
       omniauth:
         allowSingleSignOn: ['saml', 'saml_2']
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'saml1']
           gitlab_rails['omniauth_providers'] = [
             {
               name: 'saml', # This must match the following name configuration parameter
               label: 'Provider 1' # Differentiate the two buttons and providers in the UI
               args: {
                       name: 'saml', # This is mandatory and must match the provider name
                       assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback', # URL must match the name of the provider
                       strategy_class: 'OmniAuth::Strategies::SAML',
                       ... # Put here all the required arguments similar to a single provider
                     },
             },
             {
               name: 'saml_2', # This must match the following name configuration parameter
               label: 'Provider 2' # Differentiate the two buttons and providers in the UI
               args: {
                       name: 'saml_2', # This is mandatory and must match the provider name
                       assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback', # URL must match the name of the provider
                       strategy_class: 'OmniAuth::Strategies::SAML',
                       ... # Put here all the required arguments similar to a single provider
                     },
             }
           ]
   ```

   To allow your users to use SAML to sign up without having to manually create an
   account from either of the providers, add the following values to your configuration:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'saml_2']
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
         - {
           name: 'saml', # This must match the following name configuration parameter
           label: 'Provider 1' # Differentiate the two buttons and providers in the UI
           args: {
             name: 'saml', # This is mandatory and must match the provider name
             assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback', # URL must match the name of the provider
             strategy_class: 'OmniAuth::Strategies::SAML',
             ... # Put here all the required arguments similar to a single provider
           },
         }
         - {
           name: 'saml_2', # This must match the following name configuration parameter
           label: 'Provider 2' # Differentiate the two buttons and providers in the UI
           args: {
             name: 'saml_2', # This is mandatory and must match the provider name
             strategy_class: 'OmniAuth::Strategies::SAML',
             assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml_2/callback', # URL must match the name of the provider
             ... # Put here all the required arguments similar to a single provider
           },
         }
   ```

   To allow your users to use SAML to sign up without having to manually create an
   account from either of the providers, add the following values to your configuration:

   ```yaml
   production: &base
     omniauth:
       allow_single_sign_on: ["saml", "saml_2"]
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

## Set up identity providers

GitLab support of SAML means you can sign in to GitLab through a wide range
of IdPs.

GitLab provides the following content on setting up the Okta and Google Workspace
IdPs for guidance only. If you have any questions on configuring either of these
IdPs, contact your provider's support.

### Set up Okta

1. In the Okta administrator section choose **Applications**.
1. On the app screen, select **Create App Integration** and then select
   **SAML 2.0** on the next screen.
1. Optional. Choose and add a logo from [GitLab Press](https://about.gitlab.com/press/press-kit/).
   You must crop and resize the logo.
1. Complete the SAML general configuration. Enter:
   - `"Single sign-on URL"`: Use the assertion consumer service URL.
   - `"Audience URI"`: Use the issuer.
   - [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - [Assertions](#configure-assertions).
1. In the feedback section, enter that you're a customer and creating an
   app for internal use.
1. At the top of your new app's profile, select **SAML 2.0 configuration instructions**.
1. Note the **Identity Provider Single Sign-On URL**. Use this URL for the
   `idp_sso_target_url` on your GitLab configuration file.
1. Before you sign out of Okta, make sure you add your user and groups if any.

### Set up Google Workspace

Prerequisites:

- Make sure you have access to a
  [Google Workspace Super Admin account](https://support.google.com/a/answer/2405986#super_admin).

To set up a Google Workspace:

1. Use the following information, and follow the instructions in
   [Set up your own custom SAML application in Google Workspace](https://support.google.com/a/answer/6087519?hl=en).

   |                  | Typical value                                      | Description                                                                                   |
   |:-----------------|:---------------------------------------------------|:----------------------------------------------------------------------------------------------|
   | Name of SAML App | GitLab                                             | Other names OK.                                                                               |
   | ACS URL          | `https://<GITLAB_DOMAIN>/users/auth/saml/callback` | Assertion Consumer Service URL.                                                               |
   | `GITLAB_DOMAIN`  | `gitlab.example.com`                               | Your GitLab instance domain.                                                                  |
   | Entity ID        | `https://gitlab.example.com`                       | A value unique to your SAML application. Set it to the `issuer` in your GitLab configuration. |
   | Name ID format   | `EMAIL`                                            | Required value. Also known as `name_identifier_format`.                                       |
   | Name ID          | Primary email address                              | Your email address. Make sure someone receives content sent to that address.                  |
   | First name       | `first_name`                                       | First name. Required value to communicate with GitLab.                                        |
   | Last name        | `last_name`                                        | Last name. Required value to communicate with GitLab.                                         |

1. Set up the following SAML attribute mappings:

   | Google Directory attributes       | App attributes |
   |-----------------------------------|----------------|
   | Basic information > Email         | `email`        |
   | Basic Information > First name    | `first_name`   |
   | Basic Information > Last name     | `last_name`    |

   You might use some of this information when you
   [configure SAML support in GitLab](#configure-saml-support-in-gitlab).

When configuring the Google Workspace SAML application, record the following information:

|             | Value        | Description                                                                       |
|-------------|--------------|-----------------------------------------------------------------------------------|
| SSO URL     | Depends      | Google Identity Provider details. Set to the GitLab `idp_sso_target_url` setting. |
| Certificate | Downloadable | Run `openssl x509 -in <your_certificate.crt> -noout -fingerprint -sha1` to generate the SHA1 fingerprint that can be used in the `idp_cert_fingerprint` setting.                         |

Google Workspace Administrator also provides the IdP metadata, Entity ID, and SHA-256
fingerprint. However, GitLab does not need this information to connect to the
Google Workspace SAML application.

### Set up Microsoft Entra ID

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com/).
1. [Create a non-gallery application](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/overview-application-gallery#create-your-own-application).
1. [Configure SSO for that application](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal-setup-sso).

   The following settings in your `gitlab.rb` file correspond to the Microsoft Entra ID fields:

   | `gitlab.rb` setting                 | Microsoft Entra ID field                       |
   | ------------------------------------| ---------------------------------------------- |
   | `issuer`                           | **Identifier (Entity ID)**                     |
   | `assertion_consumer_service_url`   | **Reply URL (Assertion Consumer Service URL)** |
   | `idp_sso_target_url`               | **Login URL**                                  |
   | `idp_cert_fingerprint`             | **Thumbprint**                                 |

1. Set the following attributes:
   - **Unique User Identifier (Name ID)** to `user.objectID`.
      - **Name identifier format** to `persistent`. For more information, see how to [manage user SAML identity](../user/group/saml_sso/_index.md#manage-user-saml-identity).
   - **Additional claims** to [supported attributes](#configure-assertions).

For more information, see an [example configuration page](../user/group/saml_sso/example_saml_config.md#azure-active-directory).

### Set up other IdPs

Some IdPs have documentation on how to use them as the IdP in SAML configurations.
For example:

- [Active Directory Federation Services (ADFS)](https://learn.microsoft.com/en-us/previous-versions/windows-server/it-pro/windows-server-2012/identity/ad-fs/operations/Create-a-Relying-Party-Trust)
- [Auth0](https://auth0.com/docs/authenticate/single-sign-on/outbound-single-sign-on/configure-auth0-saml-identity-provider)

If you have any questions on configuring your IdP in a SAML configuration, contact
your provider's support.

### Configure assertions

DETAILS:
**Offering:** GitLab.com, GitLab Self-Managed

> - Microsoft Azure/Entra ID attribute support [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/420766) in GitLab 16.7.

NOTE:
These attributes are case-sensitive.

| Field           | Supported default keys                                                                                                                                                         |
|-----------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Email (required)| `email`, `mail`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/emailaddress`                  |
| Full Name       | `name`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/name`                                           |
| First Name      | `first_name`, `firstname`, `firstName`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/givenname` |
| Last Name       | `last_name`, `lastname`, `lastName`, `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname`, `http://schemas.microsoft.com/ws/2008/06/identity/claims/surname`   |

When GitLab receives a SAML response from a SAML SSO provider, GitLab looks for the following values in the attribute `name` field:

- `"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"`
- `"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"`
- `"http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"`
- `firstname`
- `lastname`
- `email`

You must include these values correctly in the attribute `Name` field so that GitLab can parse the SAML response. For example, GitLab can parse the following SAML response snippets:

- This is accepted because the `Name` attribute is set to one of the required values from the previous table.

  ```xml
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname">
               <AttributeValue>Alvin</AttributeValue>
           </Attribute>
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname">
               <AttributeValue>Test</AttributeValue>
           </Attribute>
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress">
               <AttributeValue>alvintest@example.com</AttributeValue>
           </Attribute>
  ```

- This is accepted because the `Name` attribute matches one of the values from the previous table.

  ```xml
           <Attribute Name="firstname">
               <AttributeValue>Alvin</AttributeValue>
           </Attribute>
           <Attribute Name="lastname">
               <AttributeValue>Test</AttributeValue>
           </Attribute>
           <Attribute Name="email">
               <AttributeValue>alvintest@example.com</AttributeValue>
           </Attribute>
  ```

However, GitLab cannot parse the following SAML response snippets:

- This will not be accepted because value in the `Name` attribute is not one of the supported
  values in the previous table.

  ```xml
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/firstname">
               <AttributeValue>Alvin</AttributeValue>
           </Attribute>
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/lastname">
               <AttributeValue>Test</AttributeValue>
           </Attribute>
           <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/mail">
               <AttributeValue>alvintest@example.com</AttributeValue>
           </Attribute>
  ```

- This will fail because, even though the `FriendlyName` has a supported value, the `Name` attribute does not.

  ```xml
           <Attribute FriendlyName="firstname" Name="urn:oid:2.5.4.42">
               <AttributeValue>Alvin</AttributeValue>
           </Attribute>
           <Attribute FriendlyName="lastname" Name="urn:oid:2.5.4.4">
               <AttributeValue>Test</AttributeValue>
           </Attribute>
           <Attribute FriendlyName="email" Name="urn:oid:0.9.2342.19200300.100.1.3">
               <AttributeValue>alvintest@example.com</AttributeValue>
           </Attribute>
  ```

See [`attribute_statements`](#map-saml-response-attribute-names) for:

- Custom assertion configuration examples.
- How to configure custom username attributes.

For a full list of supported assertions, see the [OmniAuth SAML gem](https://github.com/omniauth/omniauth-saml/blob/master/lib/omniauth/strategies/saml.rb)

## Configure users based on SAML group membership

You can:

- Require users to be members of a certain group.
- Assign users [external](../administration/external_users.md), administrator or [auditor](../administration/auditor_users.md) roles based on group membership.

GitLab checks these groups on each SAML sign in and updates user attributes as necessary.
This feature **does not** allow you to automatically add users to GitLab
[Groups](../user/group/_index.md).

Support for these groups depends on:

- Your [subscription](https://about.gitlab.com/pricing/).
- Whether you've installed [GitLab Enterprise Edition (EE)](https://about.gitlab.com/install/).

| Group                        | Tier               | GitLab Enterprise Edition (EE) Only? |
|------------------------------|--------------------|--------------------------------------|
| [Required](#required-groups) | Free, Premium, Ultimate | Yes                                  |
| [External](#external-groups) | Free, Premium, Ultimate | No                                   |
| [Admin](#administrator-groups) | Free, Premium, Ultimate | Yes                                  |
| [Auditor](#auditor-groups)   | Premium, Ultimate | Yes                                  |

Prerequisites:

- You must tell GitLab where to look for group information. To do this, make sure
  that your IdP server sends a specific `AttributeStatement` along with the regular
  SAML response. For example:

  ```xml
  <saml:AttributeStatement>
    <saml:Attribute Name="Groups">
      <saml:AttributeValue xsi:type="xs:string">Developers</saml:AttributeValue>
      <saml:AttributeValue xsi:type="xs:string">Freelancers</saml:AttributeValue>
      <saml:AttributeValue xsi:type="xs:string">Admins</saml:AttributeValue>
      <saml:AttributeValue xsi:type="xs:string">Auditors</saml:AttributeValue>
    </saml:Attribute>
  </saml:AttributeStatement>
  ```

  The name of the attribute must contain the groups that a user belongs to.
  To tell GitLab where to find these groups, add a `groups_attribute:`
  element to your SAML settings.

### Required groups

Your IdP passes group information to GitLab in the SAML response. To use this
response, configure GitLab to identify:

- Where to look for the groups in the SAML response, using the `groups_attribute` setting.
- Information about a group or user, using a group setting.

Use the `required_groups` setting to configure GitLab to identify which group
membership is required to sign in.

If you do not set `required_groups` or leave the setting empty, anyone with proper
authentication can use the service.

If the attribute specified in `groups_attribute` is incorrect or missing then all users will be blocked.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### External groups

Your IdP passes group information to GitLab in the SAML response. To use this
response, configure GitLab to identify:

- Where to look for the groups in the SAML response, using the `groups_attribute` setting.
- Information about a group or user, using a group setting.

SAML can automatically identify a user as an
[external user](../administration/external_users.md), based on the `external_groups`
setting.

**NOTE**:
If the attribute specified in `groups_attribute` is incorrect or missing then the user will
access as a standard user.

Example configuration:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [

     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       external_groups: ['Freelancers'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   external_groups: ['Freelancers']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
             { name: 'saml',
               label: 'Our SAML Provider',
               groups_attribute: 'Groups',
               external_groups: ['Freelancers'],
               args: {
                       assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                       idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                       idp_sso_target_url: 'https://login.example.com/idp',
                       issuer: 'https://gitlab.example.com',
                       name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
               }
             }
           ]
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
          - { name: 'saml',
              label: 'Our SAML Provider',
              groups_attribute: 'Groups',
              external_groups: ['Freelancers'],
              args: {
                      assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                      idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                      idp_sso_target_url: 'https://login.example.com/idp',
                      issuer: 'https://gitlab.example.com',
                      name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
              }
            }
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### Administrator groups

Your IdP passes group information to GitLab in the SAML response. To use this
response, configure GitLab to identify:

- Where to look for the groups in the SAML response, using the `groups_attribute` setting.
- Information about a group or user, using a group setting.

Use the `admin_groups` setting to configure GitLab to identify which groups grant
the user administrator access.

If the attribute specified in `groups_attribute` is incorrect or missing then users will lose their administrator access.

Example configuration:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       admin_groups: ['Admins'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   admin_groups: ['Admins']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                admin_groups: ['Admins'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             admin_groups: ['Admins'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### Auditor groups

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Your IdP passes group information to GitLab in the SAML response. To use this
response, configure GitLab to identify:

- Where to look for the groups in the SAML response, using the `groups_attribute` setting.
- Information about a group or user, using a group setting.

Use the `auditor_groups` setting to configure GitLab to identify which groups include
users with [auditor access](../administration/auditor_users.md).

If the attribute specified in `groups_attribute` is incorrect or missing then users will lose their auditor access.

Example configuration:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       auditor_groups: ['Auditors'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   auditor_groups: ['Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                auditor_groups: ['Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             auditor_groups: ['Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

## Automatically manage SAML Group Sync

For information on automatically managing GitLab group membership, see [SAML Group Sync](../user/group/saml_sso/group_sync.md).

## Bypass two-factor authentication

> - Bypass 2FA enforcement [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122109) in GitLab 16.1 [with a flag](../administration/feature_flags.md) named `by_pass_two_factor_current_session`.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/416535) in GitLab 17.8.

To configure a SAML authentication method to count as two-factor authentication
(2FA) on a per session basis, register that method in the `upstream_two_factor_authn_contexts`
list.

1. Make sure that your IdP is returning the `AuthnContext`. For example:

   ```xml
   <saml:AuthnStatement>
       <saml:AuthnContext>
           <saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:MediumStrongCertificateProtectedTransport</saml:AuthnContextClassRef>
       </saml:AuthnContext>
   </saml:AuthnStatement>
   ```

1. Edit your installation configuration to register the SAML authentication method
   in the `upstream_two_factor_authn_contexts` list. You must enter the `AuthnContext` from your SAML response.

   ::Tabs

   :::TabTitle Linux package (Omnibus)

   1. Edit `/etc/gitlab/gitlab.rb`:

      ```ruby
      gitlab_rails['omniauth_providers'] = [
        { name: 'saml',
          label: 'Our SAML Provider',
          args: {
                  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                  idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                  idp_sso_target_url: 'https://login.example.com/idp',
                  issuer: 'https://gitlab.example.com',
                  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                  upstream_two_factor_authn_contexts:
                    %w(
                      urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport
                      urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS
                      urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN
                    ),
          }
        }
      ]
      ```

   1. Save the file and reconfigure GitLab:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   :::TabTitle Helm chart (Kubernetes)

   1. Put the following content in a file named `saml.yaml` to be used as a
      [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

      ```yaml
      name: 'saml'
      label: 'Our SAML Provider'
      args:
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8'
        idp_sso_target_url: 'https://login.example.com/idp'
        issuer: 'https://gitlab.example.com'
        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
        upstream_two_factor_authn_contexts:
          - 'urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport'
          - 'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS'
          - 'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN'
      ```

   1. Create the Kubernetes Secret:

      ```shell
      kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
      ```

   1. Export the Helm values:

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. Edit `gitlab_values.yaml`:

      ```yaml
      global:
        appConfig:
          omniauth:
            providers:
              - secret: gitlab-saml
      ```

   1. Save the file and apply the new values:

      ```shell
      helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
      ```

   :::TabTitle Docker

   1. Edit `docker-compose.yml`:

      ```yaml
      version: "3.6"
      services:
        gitlab:
          environment:
            GITLAB_OMNIBUS_CONFIG: |
              gitlab_rails['omniauth_providers'] = [
                 { name: 'saml',
                   label: 'Our SAML Provider',
                   args: {
                           assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                           idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                           idp_sso_target_url: 'https://login.example.com/idp',
                           issuer: 'https://gitlab.example.com',
                           name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                           upstream_two_factor_authn_contexts:
                             %w(
                               urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport
                               urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS
                               urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN
                             )
                   }
                 }
              ]
      ```

   1. Save the file and restart GitLab:

      ```shell
      docker compose up -d
      ```

   :::TabTitle Self-compiled (source)

   1. Edit `/home/git/gitlab/config/gitlab.yml`:

      ```yaml
      production: &base
        omniauth:
          providers:
            - { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                        upstream_two_factor_authn_contexts:
                          [
                            'urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport',
                            'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS',
                            'urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN'
                          ]
                }
              }
      ```

   1. Save the file and restart GitLab:

      ```shell
      # For systems running systemd
      sudo systemctl restart gitlab.target

      # For systems running SysV init
      sudo service gitlab restart
      ```

   ::EndTabs

## Validate response signatures

IdPs must sign SAML responses to ensure that the assertions are not tampered with.

This prevents user impersonation and privilege escalation when specific group
membership is required.

### Using `idp_cert_fingerprint`

You configure the response signature validation using `idp_cert_fingerprint`.
An example configuration:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### Using `idp_cert`

If your IdP does not support configuring this using `idp_cert_fingerprint`, you
can instead configure GitLab directly using `idp_cert`.
An example configuration:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert: '-----BEGIN CERTIFICATE-----
                 <redacted>
                 -----END CERTIFICATE-----',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       }
     }
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert: |
       -----BEGIN CERTIFICATE-----
       <redacted>
       -----END CERTIFICATE-----
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert: '-----BEGIN CERTIFICATE-----
                          <redacted>
                          -----END CERTIFICATE-----',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
                }
              }
           ]
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert: '-----BEGIN CERTIFICATE-----
                       <redacted>
                       -----END CERTIFICATE-----',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

If you have configured the response signature validation incorrectly, you might see
error messages such as:

- A key validation error.
- Digest mismatch.
- Fingerprint mismatch.

For more information on solving these errors, see the [troubleshooting SAML guide](../user/group/saml_sso/troubleshooting.md).

## Customize SAML settings

### Redirect users to SAML server for authentication

You can add the `auto_sign_in_with_provider` setting to your GitLab configuration
to automatically redirect you to your SAML server for authentication. This removes
the requirement to select an element before actually signing in.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         autoSignInWithProvider: 'saml'
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       auto_sign_in_with_provider: 'saml'
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

Every sign in attempt redirects to the SAML server, so you cannot sign in using
local credentials. Make sure at least one of the SAML users has administrator access.

NOTE:
To bypass the auto sign-in setting, append `?auto_sign_in=false` in the sign in
URL, for example: `https://gitlab.example.com/users/sign_in?auto_sign_in=false`.

### Map SAML response attribute names

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

You can use `attribute_statements` to map attribute names in a SAML response to entries
in the OmniAuth [`info` hash](https://github.com/omniauth/omniauth/wiki/Auth-Hash-Schema#schema-10-and-later).

NOTE:
Only use this setting to map attributes that are part of the OmniAuth `info` hash schema.

For example, if your `SAMLResponse` contains an Attribute called `EmailAddress`,
specify `{ email: ['EmailAddress'] }` to map the Attribute to the
corresponding key in the `info` hash. URI-named Attributes are also supported, for example,
`{ email: ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] }`.

Use this setting to tell GitLab where to look for certain attributes required
to create an account. For example, if your IdP sends the user's email address as `EmailAddress`
instead of `email`, let GitLab know by setting it on your configuration:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               attribute_statements: { email: ['EmailAddress'] }
       }
     }
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     attribute_statements:
       email: ['EmailAddress']
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        attribute_statements: { email: ['EmailAddress'] }
                }
              }
           ]
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     attribute_statements: { email: ['EmailAddress'] }
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

#### Set a username

By default, the local part of the email address in the SAML response is used to
generate the user's GitLab username.

Configure [`username` or `nickname`](omniauth.md#per-provider-configuration) in `attribute_statements` to specify one or more attributes that contain a user's desired username:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               attribute_statements: { nickname: ['username'] }
       }
     }
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     attribute_statements:
       nickname: ['username']
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        attribute_statements: { nickname: ['username'] }
                }
              }
           ]
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     attribute_statements: { nickname: ['username'] }
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

This also sets the `username` attribute in your SAML Response to the username in GitLab.

### Allow for clock drift

The clock of the IdP may drift slightly ahead of your system clocks.
To allow for a small amount of clock drift, use `allowed_clock_drift` in
your settings. You must enter the parameter's value in a number and fraction of seconds.
The value given is added to the current time at which the response is validated.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               allowed_clock_drift: 1  # for one second clock drift
       }
     }
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     allowed_clock_drift: 1  # for one second clock drift
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        allowed_clock_drift: 1  # for one second clock drift
                }
              }
           ]
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     allowed_clock_drift: 1  # for one second clock drift
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

### Designate a unique attribute for the `uid` (optional)

By default, the users `uid` is set as the `NameID` attribute in the SAML response. To designate
a different attribute for the `uid`, you can set the `uid_attribute`.

Before setting the `uid` to a unique attribute, make sure that you have configured
the following attributes so your SAML users cannot change them:

- [`NameID`](../user/group/saml_sso/_index.md#manage-user-saml-identity).
- `Email` when used with `omniauth_auto_link_saml_user`.

If users can change these attributes, they can sign in as other authorized users.
See your SAML IdP documentation for information on how to make these attributes
unchangeable.
In the following example, the value of `uid` attribute in the SAML response is set as the `uid_attribute`.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               uid_attribute: 'uid'
       }
     }
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     uid_attribute: 'uid'
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        uid_attribute: 'uid'
                }
              }
           ]
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     uid_attribute: 'uid'
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

## Assertion encryption (optional)

GitLab requires the use of TLS encryption with SAML 2.0. Sometimes, GitLab needs
additional assertion encryption. For example, if you:

- Terminate TLS encryption early at a load balancer.
- Include sensitive details in assertions that you do not want appearing in logs.

Most organizations should not need additional encryption at this layer.

Your IdP encrypts the assertion with the public certificate of GitLab.
GitLab decrypts the `EncryptedAssertion` with its private key.

NOTE:
This integration uses the `certificate` and `private_key` settings for both
assertion encryption and request signing.

The SAML integration supports `EncryptedAssertion`. To encrypt your assertions,
define the private key and the public certificate of your GitLab instance in the
SAML settings.

When you define the key and certificate, replace all line feeds in the key file with `\n`.
This makes the key file one long string with no line feeds.

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     { name: 'saml',
       label: 'Our SAML Provider',
       groups_attribute: 'Groups',
       required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
       args: {
               assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
               idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
               idp_sso_target_url: 'https://login.example.com/idp',
               issuer: 'https://gitlab.example.com',
               name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
               certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
               private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----'
       }
     }
   ]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Put the following content in a file named `saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

   ```yaml
   name: 'saml'
   label: 'Our SAML Provider'
   groups_attribute: 'Groups'
   required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors']
   args:
     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8'
     idp_sso_target_url: 'https://login.example.com/idp'
     issuer: 'https://gitlab.example.com'
     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
     certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----'
     private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----'
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml`:

   ```yaml
   global:
     appConfig:
       omniauth:
         providers:
           - secret: gitlab-saml
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Edit `docker-compose.yml`:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_providers'] = [
              { name: 'saml',
                label: 'Our SAML Provider',
                groups_attribute: 'Groups',
                required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
                        private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----'
                }
              }
           ]
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Edit `/home/git/gitlab/config/gitlab.yml`:

   ```yaml
   production: &base
     omniauth:
       providers:
         - { name: 'saml',
             label: 'Our SAML Provider',
             groups_attribute: 'Groups',
             required_groups: ['Developers', 'Freelancers', 'Admins', 'Auditors'],
             args: {
                     assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                     idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                     idp_sso_target_url: 'https://login.example.com/idp',
                     issuer: 'https://gitlab.example.com',
                     name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                     certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
                     private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----'
             }
           }
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

## Sign SAML authentication requests (optional)

You can configure GitLab to sign SAML authentication requests. This configuration
is optional because GitLab SAML requests use the SAML redirect binding.

To implement signing:

1. Create a private key and public certificate pair for your GitLab instance to
   use for SAML.
1. Configure the signing settings in the `security` section of the configuration.
   For example:

   ::Tabs

   :::TabTitle Linux package (Omnibus)

   1. Edit `/etc/gitlab/gitlab.rb`:

      ```ruby
      gitlab_rails['omniauth_providers'] = [
        { name: 'saml',
          label: 'Our SAML Provider',
          args: {
                  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                  idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                  idp_sso_target_url: 'https://login.example.com/idp',
                  issuer: 'https://gitlab.example.com',
                  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                  certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
                  private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----',
                  security: {
                    authn_requests_signed: true,  # enable signature on AuthNRequest
                    want_assertions_signed: true,  # enable the requirement of signed assertion
                    want_assertions_encrypted: false,  # enable the requirement of encrypted assertion
                    metadata_signed: false,  # enable signature on Metadata
                    signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
                    digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
                  }
          }
        }
      ]
      ```

   1. Save the file and reconfigure GitLab:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   :::TabTitle Helm chart (Kubernetes)

   1. Put the following content in a file named `saml.yaml` to be used as a
      [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

      ```yaml
      name: 'saml'
      label: 'Our SAML Provider'
      args:
        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8'
        idp_sso_target_url: 'https://login.example.com/idp'
        issuer: 'https://gitlab.example.com'
        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
        certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----'
        private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----'
        security:
          authn_requests_signed: true  # enable signature on AuthNRequest
          want_assertions_signed: true  # enable the requirement of signed assertion
          want_assertions_encrypted: false  # enable the requirement of encrypted assertion
          metadata_signed: false  # enable signature on Metadata
          signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'
          digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256'
      ```

   1. Create the Kubernetes Secret:

      ```shell
      kubectl create secret generic -n <namespace> gitlab-saml --from-file=provider=saml.yaml
      ```

   1. Export the Helm values:

      ```shell
      helm get values gitlab > gitlab_values.yaml
      ```

   1. Edit `gitlab_values.yaml`:

      ```yaml
      global:
        appConfig:
          omniauth:
            providers:
              - secret: gitlab-saml
      ```

   1. Save the file and apply the new values:

      ```shell
      helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
      ```

   :::TabTitle Docker

   1. Edit `docker-compose.yml`:

      ```yaml
      version: "3.6"
      services:
        gitlab:
          environment:
            GITLAB_OMNIBUS_CONFIG: |
              gitlab_rails['omniauth_providers'] = [
                 { name: 'saml',
                   label: 'Our SAML Provider',
                   args: {
                           assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                           idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                           idp_sso_target_url: 'https://login.example.com/idp',
                           issuer: 'https://gitlab.example.com',
                           name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                           certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
                           private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----',
                           security: {
                             authn_requests_signed: true,  # enable signature on AuthNRequest
                             want_assertions_signed: true,  # enable the requirement of signed assertion
                             want_assertions_encrypted: false,  # enable the requirement of encrypted assertion
                             metadata_signed: false,  # enable signature on Metadata
                             signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
                             digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
                           }
                   }
                 }
              ]
      ```

   1. Save the file and restart GitLab:

      ```shell
      docker compose up -d
      ```

   :::TabTitle Self-compiled (source)

   1. Edit `/home/git/gitlab/config/gitlab.yml`:

      ```yaml
      production: &base
        omniauth:
          providers:
            - { name: 'saml',
                label: 'Our SAML Provider',
                args: {
                        assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback',
                        idp_cert_fingerprint: '43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8',
                        idp_sso_target_url: 'https://login.example.com/idp',
                        issuer: 'https://gitlab.example.com',
                        name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
                        certificate: '-----BEGIN CERTIFICATE-----\n<redacted>\n-----END CERTIFICATE-----',
                        private_key: '-----BEGIN PRIVATE KEY-----\n<redacted>\n-----END PRIVATE KEY-----',
                        security: {
                          authn_requests_signed: true,  # enable signature on AuthNRequest
                          want_assertions_signed: true,  # enable the requirement of signed assertion
                          want_assertions_encrypted: false,  # enable the requirement of encrypted assertion
                          metadata_signed: false,  # enable signature on Metadata
                          signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256',
                          digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256',
                        }
                }
              }
      ```

   1. Save the file and restart GitLab:

      ```shell
      # For systems running systemd
      sudo systemctl restart gitlab.target

      # For systems running SysV init
      sudo service gitlab restart
      ```

   ::EndTabs

GitLab then:

- Signs the request with the provided private key.
- Includes the configured public x500 certificate in the metadata for your IdP
  to validate the signature of the received request with.

For more information on this option, see the
[Ruby SAML gem documentation](https://github.com/SAML-Toolkits/ruby-saml/tree/v1.7.0).

The Ruby SAML gem is used by the
[OmniAuth SAML gem](https://github.com/omniauth/omniauth-saml) to implement the
client side of the SAML authentication.

NOTE:
The SAML redirect binding is different to the SAML POST binding. In the POST binding,
signing is required to prevent intermediaries from tampering with the requests.

## Password generation for users created through SAML

GitLab [generates and sets passwords for users created through SAML](../security/passwords_for_integrated_authentication_methods.md).

Users authenticated with SSO or SAML must not use a password for Git operations
over HTTPS. These users can instead:

- Set up a [personal](../user/profile/personal_access_tokens.md), [project](../user/project/settings/project_access_tokens.md), or [group](../user/group/settings/group_access_tokens.md) access token.
- Use an [OAuth credential helper](../user/profile/account/two_factor_authentication.md#oauth-credential-helpers).

## Link SAML identity for an existing user

An administrator can configure GitLab to automatically link SAML users with existing GitLab users.
For more information, see [Configure SAML support in GitLab](#configure-saml-support-in-gitlab).

A user can manually link their SAML identity to an existing GitLab account. For more information,
see [Enable OmniAuth for an existing user](omniauth.md#enable-omniauth-for-an-existing-user).

## Configure group SAML SSO on GitLab Self-Managed

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

Use group SAML SSO if you have to allow access through multiple SAML IdPs on your
GitLab Self-Managed instance.

To configure group SAML SSO:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Make sure GitLab is [configured with HTTPS](https://docs.gitlab.com/omnibus/settings/ssl/).
1. Edit `/etc/gitlab/gitlab.rb` to enable OmniAuth and the `group_saml` provider:

   ```ruby
   gitlab_rails['omniauth_enabled'] = true
   gitlab_rails['omniauth_providers'] = [{ name: 'group_saml' }]
   ```

1. Save the file and reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

:::TabTitle Helm chart (Kubernetes)

1. Make sure GitLab is [configured with HTTPS](https://docs.gitlab.com/charts/installation/tls.html).
1. Put the following content in a file named `group_saml.yaml` to be used as a
   [Kubernetes Secret](https://docs.gitlab.com/charts/charts/globals.html#providers):

   ```yaml
   name: 'group_saml'
   ```

1. Create the Kubernetes Secret:

   ```shell
   kubectl create secret generic -n <namespace> gitlab-group-saml --from-file=provider=group_saml.yaml
   ```

1. Export the Helm values:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Edit `gitlab_values.yaml` to enable OmniAuth and the `group_saml` provider:

   ```yaml
   global:
     appConfig:
       omniauth:
         enabled: true
         providers:
           - secret: gitlab-group-saml
   ```

1. Save the file and apply the new values:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

:::TabTitle Docker

1. Make sure GitLab is [configured with HTTPS](https://docs.gitlab.com/omnibus/settings/ssl/).
1. Edit `docker-compose.yml` to enable OmniAuth and the `group_saml` provider:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['omniauth_enabled'] = true
           gitlab_rails['omniauth_providers'] = [{ name: 'group_saml' }]
   ```

1. Save the file and restart GitLab:

   ```shell
   docker compose up -d
   ```

:::TabTitle Self-compiled (source)

1. Make sure GitLab is [configured with HTTPS](../install/installation.md#using-https).
1. Edit `/home/git/gitlab/config/gitlab.yml` to enable OmniAuth and the `group_saml` provider:

   ```yaml
   production: &base
     omniauth:
       enabled: true
       providers:
         - { name: 'group_saml' }
   ```

1. Save the file and restart GitLab:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

::EndTabs

As a multi-tenant solution, group SAML on GitLab Self-Managed is limited compared
to the recommended [instance-wide SAML](saml.md). Use
instance-wide SAML to take advantage of:

- [LDAP compatibility](../administration/auth/ldap/_index.md).
- [LDAP Group Sync](../user/group/access_and_permissions.md#manage-group-memberships-with-ldap).
- [Required groups](#required-groups).
- [Administrator groups](#administrator-groups).
- [Auditor groups](#auditor-groups).

## Additional configuration for SAML apps on your IdP

When configuring a SAML app on the IdP, your IdP may need additional configuration,
such as the following:

| Field | Value | Notes |
|-------|-------|-------|
| SAML profile | Web browser SSO profile | GitLab uses SAML to sign users in through their browser. No requests are made directly to the IdP. |
| SAML request binding | HTTP Redirect | GitLab (the SP) redirects users to your IdP with a base64 encoded `SAMLRequest` HTTP parameter. |
| SAML response binding | HTTP POST | Specifies how the SAML token is sent by your IdP. Includes the `SAMLResponse`, which a user's browser submits back to GitLab. |
| Sign SAML response | Required | Prevents tampering. |
| X.509 certificate in response | Required | Signs the response and checks the response against the provided fingerprint. |
| Fingerprint algorithm | SHA-1 | GitLab uses a SHA-1 hash of the certificate to sign the SAML Response. |
| Signature algorithm | SHA-1/SHA-256/SHA-384/SHA-512 | Determines how a response is signed. Also known as the digest method, this can be specified in the SAML response. |
| Encrypt SAML assertion | Optional | Uses TLS between your identity provider, the user's browser, and GitLab. |
| Sign SAML assertion | Optional | Validates the integrity of a SAML assertion. When active, signs the whole response. |
| Check SAML request signature | Optional | Checks the signature on the SAML response. |
| Default RelayState | Optional | Specifies the sub-paths of the base URL that users should end up on after successfully signing in through SAML at your IdP. |
| NameID format | Persistent | See [NameID format details](../user/group/saml_sso/_index.md#manage-user-saml-identity). |
| Additional URLs | Optional | May include the issuer, identifier, or assertion consumer service URL in other fields on some providers. |

For example configurations, see the [notes on specific providers](#set-up-identity-providers).

## Configure SAML with Geo

To configure Geo with SAML, see [Configuring instance-wide SAML](../administration/geo/replication/single_sign_on.md#configuring-instance-wide-saml).

For more information, see [Geo with Single Sign On (SSO)](../administration/geo/replication/single_sign_on.md).

## Glossary

| Term                           | Description |
|--------------------------------|-------------|
| Identity provider (IdP)        | The service that manages your user identities, such as Okta or OneLogin. |
| Service provider (SP)          | Consumes assertions from a SAML IdP, such as Okta, to authenticate users. You can configure GitLab as a SAML 2.0 SP. |
| Assertion                      | A piece of information about a user's identity, such as their name or role. Also known as a claim or an attribute. |
| Single Sign-On (SSO)           | Name of the authentication scheme. |
| Assertion consumer service URL | The callback on GitLab where users are redirected after successfully authenticating with the IdP. |
| Issuer                         | How GitLab identifies itself to the IdP. Also known as a "Relying party trust identifier". |
| Certificate fingerprint        | Confirms that communications over SAML are secure by checking that the server is signing communications with the correct certificate. Also known as a certificate thumbprint. |

## Troubleshooting

See our [troubleshooting SAML guide](../user/group/saml_sso/troubleshooting.md).
