---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting Zoekt
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

When working with Zoekt, you might encounter the following issues.
For preliminary debugging:

- [Run a health check](_index.md#run-a-health-check) to understand
  the status of your Zoekt infrastructure.
- [Check indexing status](_index.md#check-indexing-status) with the
  `gitlab-rake gitlab:zoekt:info` Rake task.

## Namespace is not indexed

When you [enable the setting](_index.md#index-root-namespaces-automatically), new namespaces get indexed automatically.
If a namespace is not indexed automatically, inspect the Sidekiq logs to see if the jobs are being processed.
`Search::Zoekt::SchedulingWorker` is responsible for indexing namespaces.

In a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session), you can check:

- Namespaces where Zoekt is not enabled:

  ```ruby
  Namespace.group_namespaces.root_namespaces_without_zoekt_enabled_namespace
  ```

- The status of Zoekt indices:

  ```ruby
  Search::Zoekt::Index.all.pluck(:state, :namespace_id)
  ```

To index a namespace manually, see [set up indexing](https://docs.gitlab.com/charts/charts/gitlab/gitlab-zoekt/#configure-zoekt-in-gitlab).

## Error: `SilentModeBlockedError`

You might get a `SilentModeBlockedError` when you try to run exact code search.
This issue occurs when [Silent Mode](../../administration/silent_mode) is enabled on the GitLab instance.

To resolve this issue, ensure Silent Mode is disabled.

## Error: `connections to all backends failing`

In `application_json.log`, you might get the following error:

```plaintext
connections to all backends failing; last error: UNKNOWN: ipv4:1.2.3.4:5678: Trying to connect an http1.x server
```

To resolve this issue, check if you're using any proxies.
If you are, set the IP address of the GitLab server to `no_proxy`:

```ruby
gitlab_rails['env'] = {
  "http_proxy" => "http://proxy.domain.com:1234",
  "https_proxy" => "http://proxy.domain.com:1234",
  "no_proxy" => ".domain.com,IP_OF_GITLAB_INSTANCE,127.0.0.1,localhost"
}
```

`proxy.domain.com:1234` is the domain of the proxy instance and the port.
`IP_OF_GITLAB_INSTANCE` points to the public IP address of the GitLab instance.

You can get this information by running `ip a` and checking one of the following:

- The IP address of the appropriate network interface
- The public IP address of any load balancer you're using

## Verify Zoekt node connections

To verify that your Zoekt nodes are properly configured and connected,
in a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session):

- Check the total number of configured Zoekt nodes:

  ```ruby
  Search::Zoekt::Node.count
  ```

- Check how many nodes are online:

  ```ruby
  Search::Zoekt::Node.online.count
  ```

Alternatively, you can use the `gitlab:zoekt:info` Rake task.

If the number of online nodes is lower than the number of configured nodes or is zero when nodes are configured,
you might have connectivity issues between GitLab and your Zoekt nodes.

## Error: `TaskRequest responded with [401]`

In your Zoekt indexer logs, you might see `TaskRequest responded with [401]`.
This error indicates that the Zoekt indexer is failing to authenticate with GitLab.

To resolve this issue, verify that `gitlab-shell-secret` is correctly configured
and matches between your GitLab instance and Zoekt indexer.
For example, the output of the following command must match
`gitlab-shell-secret` in your `gitlab.rb`:

```shell
kubectl get secret gitlab-shell-secret -o jsonpath='{.data.secret}' -n your_zoekt_namespace | base64 -d
```
