---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Using the Libravatar service with GitLab
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab by default supports the [Gravatar](https://gravatar.com) avatar service.

Libravatar is another service that delivers your avatar (profile picture) to
other websites. The Libravatar API is
[heavily based on Gravatar](https://wiki.libravatar.org/api/), so you can
switch to the Libravatar avatar service or even your own Libravatar
server.

## Change the Libravatar service to your own service

In the [`gitlab.yml` gravatar section](https://gitlab.com/gitlab-org/gitlab/-/blob/68dac188ec6b1b03d53365e7579422f44cbe7a1c/config/gitlab.yml.example#L469-476), set
the configuration options as follows:

For Linux package installations:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['gravatar_enabled'] = true
   #### For HTTPS
   gitlab_rails['gravatar_ssl_url'] = "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
   #### Use this line instead for HTTP
   # gitlab_rails['gravatar_plain_url'] = "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
   ```

1. To apply the changes, run `sudo gitlab-ctl reconfigure`.

For self-compiled installations:

1. Edit `config/gitlab.yml`:

   ```yaml
     gravatar:
       enabled: true
       # default: https://www.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon
       plain_url: "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
       # default: https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon
       ssl_url: https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
   ```

1. Save the file, and then [restart](restart_gitlab.md#self-compiled-installations)
   GitLab for the changes to take effect.

## Set the Libravatar service to default (Gravatar)

For Linux package installations:

1. Delete `gitlab_rails['gravatar_ssl_url']` or `gitlab_rails['gravatar_plain_url']` from `/etc/gitlab/gitlab.rb`.
1. To apply the changes, run `sudo gitlab-ctl reconfigure`.

For self-compiled installations:

1. Remove `gravatar:` section from `config/gitlab.yml`.
1. Save the file, then [restart](restart_gitlab.md#self-compiled-installations)
   GitLab to apply the changes.

## Disable Gravatar service

To disable Gravatar, for example, to prohibit third-party services, complete the following steps:

For Linux package installations:

1. Edit `/etc/gitlab/gitlab.rb`:

   ```ruby
   gitlab_rails['gravatar_enabled'] = false
   ```

1. To apply the changes, run `sudo gitlab-ctl reconfigure`.

For self-compiled installations:

1. Edit `config/gitlab.yml`:

   ```yaml
     gravatar:
       enabled: false
   ```

1. Save the file, then [restart](restart_gitlab.md#self-compiled-installations)
   GitLab to apply the changes.

### Your own Libravatar server

If you are [running your own Libravatar service](https://wiki.libravatar.org/running_your_own/),
the URL is different in the configuration, but you must provide the same
placeholders so GitLab can parse the URL correctly.

For example, you host a service on `https://libravatar.example.com` and the
`ssl_url` you must supply in `gitlab.yml` is:

`https://libravatar.example.com/avatar/%{hash}?s=%{size}&d=identicon`

## Default URL for missing images

[Libravatar supports different sets](https://wiki.libravatar.org/api/) of
missing images for user email addresses that are not found on the Libravatar
service.

To use a set other than `identicon`, replace the `&d=identicon` portion of the
URL with another supported set. For example, you can use the `retro` set, in
which case the URL would look like: `ssl_url: "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=retro"`

## Usage examples for Microsoft Office 365

If your users are Office 365 users, the `GetPersonaPhoto` service can be used.
This service requires a login, so this use case is most useful in a
corporate installation where all users have access to Office 365.

```ruby
gitlab_rails['gravatar_plain_url'] = 'http://outlook.office.com/owa/service.svc/s/GetPersonaPhoto?email=%{email}&size=HR120x120'
gitlab_rails['gravatar_ssl_url'] = 'https://outlook.office.com/owa/service.svc/s/GetPersonaPhoto?email=%{email}&size=HR120x120'
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
