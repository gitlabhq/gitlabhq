---
type: reference
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Authentiq OmniAuth Provider **(FREE SELF)**

To enable the Authentiq OmniAuth provider for passwordless authentication, you must register an application with Authentiq.

Authentiq generates a Client ID and the accompanying Client Secret for you to use.

1. Get your Client credentials (Client ID and Client Secret) at [Authentiq](https://www.authentiq.com/developers).

1. On your GitLab server, open the configuration file:

   For omnibus installation

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For installations from source:

   ```shell
   sudo -u git -H editor /home/git/gitlab/config/gitlab.yml
   ```

1. Edit the [common configuration file settings](../../integration/omniauth.md#configure-common-settings)
   to add `authentiq` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.

1. Add the provider configuration for Authentiq:

   For Omnibus packages:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "authentiq",
       # label: "Provider name", # optional label for login button, defaults to "Authentiq"
       app_id: "<your_client_id>",
       app_secret: "<your_client_secret>",
       args: {
         "scope": 'aq:name email~rs address aq:push'
       }
     }
   ]
   ```

   For installations from source:

   ```yaml
   - { name: 'authentiq',
       # label: 'Provider name', # optional label for login button, defaults to "Authentiq"
       app_id: '<your_client_id>',
       app_secret: '<your_client_secret>',
       args: {
              scope: 'aq:name email~rs address aq:push'
             }
     }
   ```

1. The `scope` is set to request the:
   - User's name.
   - Required and signed email.
   - Permission to send push notifications to sign in on subsequent visits.

   See [OmniAuth Authentiq strategy](https://github.com/AuthentiqID/omniauth-authentiq/wiki/Scopes,-callback-url-configuration-and-responses) for more information on scopes and modifiers.

1. Change `<your_client_id>` and `<your_client_secret>` to the Client credentials you received from Authentiq.

1. Save the configuration file.

1. For the changes to take effect:
   - [Reconfigure GitLab](../restart_gitlab.md#omnibus-gitlab-reconfigure) if you installed GitLab using Omnibus.
   - [Restart GitLab](../restart_gitlab.md#installations-from-source) if you installed GitLab from source.

On the sign in page there should now be an Authentiq icon below the regular sign in form. Select the
icon to begin the authentication process. If the user:

- Has the Authentiq ID app installed in their iOS or Android device, they can:
  1. Scan the QR code.
  1. Decide what personal details to share.
  1. Sign in to your GitLab installation.
- Does not have the app installed, they are prompted to download the app and then follow the
  previous procedure.

If everything works, the user is returned to GitLab and is signed in.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
