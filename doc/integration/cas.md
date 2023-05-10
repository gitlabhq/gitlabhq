---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
remove_date: '2023-08-15'
redirect_to: '../administration/auth/index.md'
---

# CAS OmniAuth provider (removed) **(FREE SELF)**

WARNING:
This feature was
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/369127) in GitLab
15.3 and [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/369128) in 16.0.

To enable the CAS OmniAuth provider you must register your application with your
CAS instance. This requires the service URL GitLab supplies to CAS. It should be
something like: `https://gitlab.example.com:443/users/auth/cas3/callback?url`.
Handling for Single Logout (SLO) is enabled by default, so you only have to
configure CAS for back-channel logout.

1. On your GitLab server, open the configuration file.

   For Omnibus package:

   ```shell
   sudo editor /etc/gitlab/gitlab.rb
   ```

   For installations from source:

   ```shell
   cd /home/git/gitlab

   sudo -u git -H editor config/gitlab.yml
   ```

1. Configure the [common settings](omniauth.md#configure-common-settings)
   to add `cas3` as a single sign-on provider. This enables Just-In-Time
   account provisioning for users who do not have an existing GitLab account.

1. Add the provider configuration:

   For Omnibus package:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "cas3",
       label: "Provider name", # optional label for login button, defaults to "Cas3"
       args: {
           url: "CAS_SERVER",
           login_url: "/CAS_PATH/login",
           service_validate_url: "/CAS_PATH/p3/serviceValidate",
           logout_url: "/CAS_PATH/logout"
       }
     }
   ]
   ```

   For installations from source:

   ```yaml
   - { name: 'cas3',
       label: 'Provider name', # optional label for login button, defaults to "Cas3"
       args: {
         url: 'CAS_SERVER',
         login_url: '/CAS_PATH/login',
         service_validate_url: '/CAS_PATH/p3/serviceValidate',
         logout_url: '/CAS_PATH/logout' } }
   ```

1. Change 'CAS_PATH' to the root of your CAS instance (such as `cas`).

1. If your CAS instance does not use default TGC lifetimes, update the `cas3.session_duration` to at least the current TGC maximum lifetime. To explicitly disable SLO, regardless of CAS settings, set this to 0.

1. Save the configuration file.

1. For the changes to take effect:
   - If you installed via Omnibus, [reconfigure GitLab](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure).
   - If you installed from source, [restart GitLab](../administration/restart_gitlab.md#installations-from-source).

On the sign in page there should now be a CAS tab in the sign in form.
