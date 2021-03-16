---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# CAS OmniAuth Provider **(FREE)**

To enable the CAS OmniAuth provider you must register your application with your CAS instance. This requires the service URL GitLab supplies to CAS. It should be something like: `https://gitlab.example.com:443/users/auth/cas3/callback?url`. By default handling for SLO is enabled, you only need to configure CAS for back-channel logout.

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

1. See [Initial OmniAuth Configuration](omniauth.md#initial-omniauth-configuration) for initial settings.

1. Add the provider configuration:

   For Omnibus package:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
         "name"=> "cas3",
         "label"=> "cas",
         "args"=> {
             "url"=> 'CAS_SERVER',
             "login_url"=> '/CAS_PATH/login',
             "service_validate_url"=> '/CAS_PATH/p3/serviceValidate',
             "logout_url"=> '/CAS_PATH/logout'
         }
     }
   ]
   ```

   For installations from source:

   ```yaml
   - { name: 'cas3',
       label: 'cas',
       args: {
         url: 'CAS_SERVER',
         login_url: '/CAS_PATH/login',
         service_validate_url: '/CAS_PATH/p3/serviceValidate',
         logout_url: '/CAS_PATH/logout' } }
   ```

1. Change 'CAS_PATH' to the root of your CAS instance (such as `cas`).

1. If your CAS instance does not use default TGC lifetimes, update the `cas3.session_duration` to at least the current TGC maximum lifetime. To explicitly disable SLO, regardless of CAS settings, set this to 0.

1. Save the configuration file.

1. [Reconfigure](../administration/restart_gitlab.md#omnibus-gitlab-reconfigure) or
   [restart GitLab](../administration/restart_gitlab.md#installations-from-source) for the changes to
   take effect if you installed GitLab via Omnibus or from source respectively.

On the sign in page there should now be a CAS tab in the sign in form.
