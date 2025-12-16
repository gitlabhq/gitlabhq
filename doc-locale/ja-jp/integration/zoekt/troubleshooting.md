---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Zoektのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ

{{< /details >}}

Zoektを使用しているときに、以下の問題が発生する可能性があります。予備的なデバッグ:

- Zoektインフラストラクチャのステータスを理解するには、[ヘルスチェックを実行](_index.md#run-a-health-check)します。
- `gitlab-rake gitlab:zoekt:info` Rakeタスクで、[インデックス作成ステータスを確認](_index.md#check-indexing-status)します。

## ネームスペースがインデックスされていません {#namespace-is-not-indexed}

[設定を有効](_index.md#index-root-namespaces-automatically)にすると、新しいネームスペースは自動的にインデックスされます。ネームスペースが自動的にインデックスされない場合は、Sidekiqログを調べて、ジョブが処理されているかどうかを確認します。`Search::Zoekt::SchedulingWorker`は、ネームスペースのインデックス作成を担当します。

[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)で、以下を確認できます:

- Zoektが有効になっていないネームスペース:

  ```ruby
  Namespace.group_namespaces.root_namespaces_without_zoekt_enabled_namespace
  ```

- Zoektインデックスのステータス:

  ```ruby
  Search::Zoekt::Index.all.pluck(:state, :namespace_id)
  ```

ネームスペースを手動でインデックス作成するには、[設定アップ](https://docs.gitlab.com/charts/charts/gitlab/gitlab-zoekt/#configure-zoekt-in-gitlab)を参照してください。

## エラー: `SilentModeBlockedError` {#error-silentmodeblockederror}

完全一致コードの検索を実行しようとすると、`SilentModeBlockedError`が表示されることがあります。このイシューは、[サイレントモード](../../administration/silent_mode)がGitLabインスタンスで有効になっている場合に発生します。

このイシューを解決するには、サイレントモードが無効になっていることを確認してください。

## エラー: `connections to all backends failing` {#error-connections-to-all-backends-failing}

`application_json.log`で、次のエラーが発生する可能性があります:

```plaintext
connections to all backends failing; last error: UNKNOWN: ipv4:1.2.3.4:5678: Trying to connect an http1.x server
```

このイシューを解決するには、プロキシを使用しているかどうかを確認してください。使用している場合は、GitLabサーバーのIPアドレスを`no_proxy`に設定します:

```ruby
gitlab_rails['env'] = {
  "http_proxy" => "http://proxy.domain.com:1234",
  "https_proxy" => "http://proxy.domain.com:1234",
  "no_proxy" => ".domain.com,IP_OF_GITLAB_INSTANCE,127.0.0.1,localhost"
}
```

`proxy.domain.com:1234`は、プロキシインスタンスのドメインとポートです。`IP_OF_GITLAB_INSTANCE`は、GitLabインスタンスのパブリックIPアドレスを指します。

この情報を取得するには、`ip a`を実行して、次のいずれかを確認します:

- 適切なネットワークインターフェースのIPアドレス
- 使用しているロードバランサーのパブリックIPアドレス

## Zoektノード接続を確認する {#verify-zoekt-node-connections}

Zoektノードが適切に構成され、接続されていることを確認するには、[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)で、以下を実行します:

- 構成されているZoektノードの総数を確認します:

  ```ruby
  Search::Zoekt::Node.count
  ```

- オンラインのノード数を確認します:

  ```ruby
  Search::Zoekt::Node.online.count
  ```

または、`gitlab:zoekt:info` Rakeタスクを使用することもできます。

オンラインノードの数が、構成されているノードの数より少ない場合、またはノードが構成されている場合にゼロである場合は、GitLabとZoektノードの間に接続の問題がある可能性があります。

## エラー: `TaskRequest responded with [401]` {#error-taskrequest-responded-with-401}

Zoekt Indexerログに、`TaskRequest responded with [401]`が表示されることがあります。このエラーは、Zoekt IndexerがGitLabでの認証に失敗していることを示しています。

このイシューを解決するには、`gitlab-shell-secret`が正しく構成され、GitLabインスタンスとZoekt Indexerの間で一致することを確認します。たとえば、次のコマンドの出力は、`gitlab.rb`の`gitlab-shell-secret`と一致する必要があります:

```shell
kubectl get secret gitlab-shell-secret -o jsonpath='{.data.secret}' -n your_zoekt_namespace | base64 -d
```
