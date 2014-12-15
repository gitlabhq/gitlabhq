# Kerberos integration

GitLab can be configured to allow your users to sign with their Kerberos credentials.
Kerberos integration can be enabled as a regular omniauth provider, edit [gitlab.rb (omnibus-gitlab)`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md#omniauth-google-twitter-github-login) or [gitlab.yml (source installations)](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/gitlab.yml.example) on your GitLab server and restart GitLab. You only need to specify the provider name. For example:

```
{ name: 'kerberos'}
```

You still need to configure your system for Kerberos usage, such as specifying realms. GitLab will make use of the system's Kerberos settings.

The first time a user signs in with Kerberos credentials, GitLab will create a new GitLab user associated with the email, which is built from the kerberos username and realm. This also means that the system realm you want to use and the email addresses of existing GitLab users should match, meaning the domain part of the email addresses and the realm should match. Existing GitLab users can go to profile > account and attach a Kerberos account. If the email and realm match, the Kerberos account will be linked to the user.

## HTTP git access

A linked Kerberos account enables you to `git pull` and `git push` using your Kerberos account, as well as your standard GitLab credentials.