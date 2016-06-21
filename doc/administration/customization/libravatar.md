# Use Libravatar service with GitLab

GitLab by default supports [Gravatar](https://gravatar.com) avatar service.
Libravatar is a service which delivers your avatar (profile picture) to other websites and their API is
[heavily based on gravatar](https://wiki.libravatar.org/api/).

This means that it is not complicated to switch to Libravatar avatar service or even self hosted Libravatar server.

# Configuration

In [gitlab.yml gravatar section](https://gitlab.com/gitlab-org/gitlab-ce/blob/672bd3902d86b78d730cea809fce312ec49d39d7/config/gitlab.yml.example#L122) set
the configuration options as follows:

## For HTTP

```yml
  gravatar:
    enabled: true
    # gravatar URLs: possible placeholders: %{hash} %{size} %{email}
    plain_url: "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
```

## For HTTPS

```yml
  gravatar:
    enabled: true
    # gravatar URLs: possible placeholders: %{hash} %{size} %{email}
    ssl_url: "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
```

## Self-hosted

If you are [running your own libravatar service](https://wiki.libravatar.org/running_your_own/) the URL will be different in the configuration
but the important part is to provide the same placeholders so GitLab can parse the URL correctly.

For example, you host a service on `http://libravatar.example.com` the `plain_url` you need to supply in `gitlab.yml` is

`http://libravatar.example.com/avatar/%{hash}?s=%{size}&d=identicon`


## Omnibus-gitlab example

In `/etc/gitlab/gitlab.rb`:

#### For http

```ruby
gitlab_rails['gravatar_enabled'] = true
gitlab_rails['gravatar_plain_url'] = "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
```

#### For https

```ruby
gitlab_rails['gravatar_enabled'] = true
gitlab_rails['gravatar_ssl_url'] = "https://seccdn.libravatar.org/avatar/%{hash}?s=%{size}&d=identicon"
```


Run `sudo gitlab-ctl reconfigure` for changes to take effect.


## Default URL for missing images

[Libravatar supports different sets](https://wiki.libravatar.org/api/) of `missing images` for emails not found on the Libravatar service.

In order to use a different set other than `identicon`, replace `&d=identicon` portion of the URL with another supported set.
For example, you can use `retro` set in which case the URL would look like: `plain_url: "http://cdn.libravatar.org/avatar/%{hash}?s=%{size}&d=retro"`


## Usage examples

#### For Microsoft Office 365

If your users are Office 365-users, the "GetPersonaPhoto" service can be used. Note that this service requires login, so this use case is
most useful in a corporate installation, where all users have access to Office 365.

```ruby
gitlab_rails['gravatar_plain_url'] = 'http://outlook.office365.com/owa/service.svc/s/GetPersonaPhoto?email=%{email}&size=HR120x120'
gitlab_rails['gravatar_ssl_url'] = 'https://outlook.office365.com/owa/service.svc/s/GetPersonaPhoto?email=%{email}&size=HR120x120'
```
