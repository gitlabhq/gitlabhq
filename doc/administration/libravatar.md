---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Using the Libravatar service with GitLab **(FREE SELF)**

GitLab by default supports the [Gravatar](https://gravatar.com) avatar service.

Libravatar is another service that delivers your avatar (profile picture) to
other websites. The Libravatar API is
[heavily based on gravatar](https://wiki.libravatar.org/api/), so you can
easily switch to the Libravatar avatar service or even your own Libravatar
server.

## Configuration

In the [`gitlab.yml` gravatar section](https://gitlab.com/gitlab-org/gitlab/-/blob/672bd3902d86b78d730cea809fce312ec49d39d7/config/gitlab.yml.example#L122), set
the configuration options as follows:

### For HTTP

```yaml
  gravatar:
    enabled: true
    # gravatar URLs: possible placeholders: %{hash} %{size} %{email} %{username}
    plain_url: "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
```

### For HTTPS

```yaml
  gravatar:
    enabled: true
    # gravatar URLs: possible placeholders: %{hash} %{size} %{email} %{username}
    ssl_url: "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
```

### Your own Libravatar server

If you are [running your own Libravatar service](https://wiki.libravatar.org/running_your_own/),
the URL is different in the configuration, but you must provide the same
placeholders so GitLab can parse the URL correctly.

For example, you host a service on `http://libravatar.example.com` and the
`plain_url` you need to supply in `gitlab.yml` is

`http://libravatar.example.com/avatar/%{hash}?s=%{size}&d=identicon`

### Omnibus GitLab example

In `/etc/gitlab/gitlab.rb`:

#### For HTTP

```ruby
gitlab_rails['gravatar_enabled'] = true
gitlab_rails['gravatar_plain_url'] = "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
```

#### For HTTPS

```ruby
gitlab_rails['gravatar_enabled'] = true
gitlab_rails['gravatar_ssl_url'] = "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
```

Then run `sudo gitlab-ctl reconfigure` for the changes to take effect.

## Default URL for missing images

[Libravatar supports different sets](https://wiki.libravatar.org/api/) of
missing images for user email addresses that are not found on the Libravatar
service.

To use a set other than `identicon`, replace the `&d=identicon` portion of the
URL with another supported set. For example, you can use the `retro` set, in
which case the URL would look like: `plain_url: "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=retro"`

## Usage examples for Microsoft Office 365

If your users are Office 365 users, the `GetPersonaPhoto` service can be used.
Note that this service requires a login, so this use case is most useful in a
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

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
