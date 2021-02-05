---
type: reference
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Google Workspace SSO provider

Google Workspace (formerly G Suite) is a [Single Sign-on provider](https://support.google.com/a/answer/60224?hl=en) that can be used to authenticate
with GitLab.

The following documentation enables Google Workspace as a SAML provider for GitLab.

## Configure the Google Workspace SAML app

The following guidance is based on this Google Workspace article, on how to [Set up your own custom SAML application](https://support.google.com/a/answer/6087519?hl=en):

Make sure you have access to a Google Workspace [Super Admin](https://support.google.com/a/answer/2405986#super_admin) account.
   Follow the instructions in the linked Google Workspace article, where you'll need the following information:

|                  | Typical value                                    | Description                                              |
|------------------|--------------------------------------------------|----------------------------------------------------------|
| Name of SAML App | GitLab                                           | Other names OK.                                          |
| ACS URL          | `https://<GITLAB_DOMAIN>/users/auth/saml/callback` | ACS is short for Assertion Consumer Service.             |
| GITLAB_DOMAIN    | `gitlab.example.com`                             | Set to the domain of your GitLab instance.               |
| Entity ID        | `https://gitlab.example.com`                     | A value unique to your SAML app, you'll set it to the `issuer` in your GitLab configuration.                         |
| Name ID format   | EMAIL                                            | Required value. Also known as `name_identifier_format`                    |
| Name ID          | Primary email address                            | Make sure someone receives content sent to that address                |
| First name       | `first_name`                                     | Required value to communicate with GitLab.               |
| Last name        | `last_name`                                      | Required value to communicate with GitLab.               |

You will also need to setup the following SAML attribute mappings:

| Google Directory attributes       | App attributes |
|-----------------------------------|----------------|
| Basic information > Email         | `email`        |
| Basic Information > First name    | `first_name`   |
| Basic Information > Last name     | `last_name`    |

You may also use some of this information when you [Configure GitLab](#configure-gitlab).

When configuring the Google Workspace SAML app, be sure to record the following information:

|             | Value        | Description                                                                       |
|-------------|--------------|-----------------------------------------------------------------------------------|
| SSO URL     | Depends      | Google Identity Provider details. Set to the GitLab `idp_sso_target_url` setting. |
| Certificate | Downloadable | Run `openssl x509 -in <your_certificate.crt> -noout -fingerprint` to generate the SHA1 fingerprint that can be used in the `idp_cert_fingerprint` setting.                         |

While the Google Workspace Admin provides IDP metadata, Entity ID and SHA-256 fingerprint,
GitLab does not need that information to connect to the Google Workspace SAML app.

---

Now that the Google Workspace SAML app is configured, it's time to enable it in GitLab.

## Configure GitLab

1. See [Initial OmniAuth Configuration](../integration/omniauth.md#initial-omniauth-configuration)
   for initial settings.

1. To allow people to register for GitLab, through their Google accounts, add the following
   values to your configuration:

   **For Omnibus GitLab installations**

   Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
   gitlab_rails['omniauth_block_auto_created_users'] = false
   ```

   ---

   **For installations from source**

   Edit `config/gitlab.yml`:

   ```yaml
   allow_single_sign_on: ["saml"]
   block_auto_created_users: false
   ```

1. If an existing GitLab user has the same email address as a Google Workspace user, the registration
   process automatically links their accounts, if you add the following setting:
   their email addresses match by adding the following setting:

   **For Omnibus GitLab installations**

   Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['omniauth_auto_link_saml_user'] = true
   ```

   ---

   **For installations from source**

   Edit `config/gitlab.yml`:

   ```yaml
   auto_link_saml_user: true
   ```

1. Add the provider configuration.

For guidance on how to set up these values, see the [SAML General Setup steps](saml.md#general-setup).
Pay particular attention to the values for:

- `assertion_consumer_service_url`
- `idp_cert_fingerprint`
- `idp_sso_target_url`
- `issuer`
- `name_identifier_format`

   **For Omnibus GitLab installations**

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: 'saml',
       args: {
                assertion_consumer_service_url: 'https://<GITLAB_DOMAIN>/users/auth/saml/callback',
                idp_cert_fingerprint: '00:00:00:00:00:00:0:00:00:00:00:00:00:00:00:00',
                idp_sso_target_url: 'https://accounts.google.com/o/saml2/idp?idpid=00000000',
                issuer: 'https://<GITLAB_DOMAIN>',
                name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:emailAddress'
              },
       label: 'Google Workspace' # optional label for SAML log in button, defaults to "Saml"
     }
   ]
   ```

   **For installations from source**

   ```yaml
   - {
       name: 'saml',
       args: {
              assertion_consumer_service_url: 'https://<GITLAB_DOMAIN>/users/auth/saml/callback',
              idp_cert_fingerprint: '00:00:00:00:00:00:0:00:00:00:00:00:00:00:00:00',
              idp_sso_target_url: 'https://accounts.google.com/o/saml2/idp?idpid=00000000',
              issuer: 'https://<GITLAB_DOMAIN>',
              name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:emailAddress'
            },
       label: 'Google Workspace' # optional label for SAML log in button, defaults to "Saml"
     }
   ```

1. [Reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) or [restart](../administration/restart_gitlab.md#installations-from-source) GitLab for Omnibus and installations
   from source respectively for the changes to take effect.

To avoid caching issues, test the result on an incognito or private browser window.

## Troubleshooting

The Google Workspace documentation on [SAML app error messages](https://support.google.com/a/answer/6301076?hl=en) is helpful for debugging if you are seeing an error from Google while signing in.
Pay particular attention to the following 403 errors:

- `app_not_configured`
- `app_not_configured_for_user`
