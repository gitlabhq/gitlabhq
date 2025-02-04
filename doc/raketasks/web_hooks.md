---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Webhook administration Rake tasks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab provides Rake tasks for webhooks management.

Requests to the [local network by webhooks](../security/webhooks.md) can be allowed or blocked by an
administrator.

## Add a webhook to all projects

To add a webhook to all projects, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook"

# source installations
bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" RAILS_ENV=production
```

## Add a webhook to projects in a namespace

To add a webhook to all projects in a specific namespace, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=<namespace>

# source installations
bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=<namespace> RAILS_ENV=production
```

## Remove a webhook from projects

To remove a webhook from all projects, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook"

# source installations
bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" RAILS_ENV=production
```

## Remove a webhook from projects in a namespace

To remove a webhook from projects in a specific namespace, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=<namespace>

# source installations
bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=<namespace> RAILS_ENV=production
```

## List all webhooks

To list all webhooks, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:list

# source installations
bundle exec rake gitlab:web_hook:list RAILS_ENV=production
```

## List webhooks for projects in a namespace

To list all webhook for projects in a specified namespace, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:list NAMESPACE=<namespace>

# source installations
bundle exec rake gitlab:web_hook:list NAMESPACE=<namespace> RAILS_ENV=production
```
