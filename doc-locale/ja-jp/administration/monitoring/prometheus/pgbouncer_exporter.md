---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PgBouncer exporter
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

この[PgBouncer exporter](https://github.com/prometheus-community/pgbouncer_exporter)を使用すると、さまざまな[PgBouncer](https://www.pgbouncer.org/)メトリクスを測定できます。

自己コンパイルによるインストール環境では、ユーザー自身がPrometheusをインストールして設定する必要があります。

PgBouncer exporterを有効にするには:

1. [Prometheusを有効にする](_index.md#configuring-prometheus)。
1. `/etc/gitlab/gitlab.rb`を編集します。
1. 次の行を追加（または見つけてコメント解除）し、`true`に設定されていることを確認してください:

   ```ruby
   pgbouncer_exporter['enable'] = true
   ```

1. ファイルを保存して、[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

Prometheusは、`localhost:9188`で公開されているPgBouncer exporterからパフォーマンスデータの収集を開始します。

[`pgbouncer_role`](https://docs.gitlab.com/omnibus/roles/#postgresql-roles)ロールが有効になっている場合、PgBouncer exporterはデフォルトで有効になります。
