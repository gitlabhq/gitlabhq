# Webhooks administration **(CORE ONLY)**

## Add a webhook for **ALL** projects:

```sh
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook"
# source installations
bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" RAILS_ENV=production
```

## Add a webhook for projects in a given **NAMESPACE**:

```sh
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=acme
# source installations
bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=acme RAILS_ENV=production
```

## Remove a webhook from **ALL** projects using:

```sh
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook"
# source installations
bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" RAILS_ENV=production
```

## Remove a webhook from projects in a given **NAMESPACE**:

```sh
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=acme
# source installations
bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=acme RAILS_ENV=production
```

## List **ALL** webhooks:

```sh
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:list
# source installations
bundle exec rake gitlab:web_hook:list RAILS_ENV=production
```

## List the webhooks from projects in a given **NAMESPACE**:

```sh
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:list NAMESPACE=acme
# source installations
bundle exec rake gitlab:web_hook:list NAMESPACE=acme RAILS_ENV=production
```

## Local requests in webhooks

[Requests to local network by webhooks](../security/webhooks.md) can be allowed
or blocked by an administrator.
