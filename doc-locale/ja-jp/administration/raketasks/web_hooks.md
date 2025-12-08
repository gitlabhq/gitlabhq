---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: WebhookのRakeタスク管理
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは、Webhook管理用のRakeタスクを提供します。

管理者は、[webhookによるローカルネットワークへの](../../security/webhooks.md)リクエストを許可またはブロックできます。

## すべてのプロジェクトにWebhookを追加 {#add-a-webhook-to-all-projects}

すべてのプロジェクトにWebhookを追加するには、次を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook"

# source installations
bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" RAILS_ENV=production
```

## ネームスペース内のプロジェクトにWebhookを追加 {#add-a-webhook-to-projects-in-a-namespace}

特定のネームスペース内のすべてのプロジェクトにWebhookを追加するには、次を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=<namespace>

# source installations
bundle exec rake gitlab:web_hook:add URL="http://example.com/hook" NAMESPACE=<namespace> RAILS_ENV=production
```

## プロジェクトからWebhookを削除 {#remove-a-webhook-from-projects}

すべてのプロジェクトからWebhookを削除するには、次を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook"

# source installations
bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" RAILS_ENV=production
```

## ネームスペース内のプロジェクトからWebhookを削除 {#remove-a-webhook-from-projects-in-a-namespace}

特定のネームスペース内のプロジェクトからWebhookを削除するには、次を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=<namespace>

# source installations
bundle exec rake gitlab:web_hook:rm URL="http://example.com/hook" NAMESPACE=<namespace> RAILS_ENV=production
```

## すべてのWebhookをリスト {#list-all-webhooks}

すべてのWebhookをリストするには、次を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:list

# source installations
bundle exec rake gitlab:web_hook:list RAILS_ENV=production
```

## ネームスペース内のプロジェクトのWebhookをリスト {#list-webhooks-for-projects-in-a-namespace}

指定されたネームスペース内のプロジェクトのすべてのWebhookをリストするには、次を実行します:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:web_hook:list NAMESPACE=<namespace>

# source installations
bundle exec rake gitlab:web_hook:list NAMESPACE=<namespace> RAILS_ENV=production
```
