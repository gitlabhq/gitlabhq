---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ノードexporter
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

The [ノードexporter](https://github.com/prometheus/node_exporter)を使用すると、メモリ、ディスク、CPU使用率などの様々なマシンリソースを測定できます。

自己コンパイルによるインストール環境では、ユーザー自身がPrometheusをインストールして設定する必要があります。

ノードexporterを有効にするには:

1. [Prometheusを有効にする](_index.md#configuring-prometheus)。
1. `/etc/gitlab/gitlab.rb`を編集します。
1. 次の行を追加（または見つけてコメント解除）し、`true`に設定されていることを確認してください:

   ```ruby
   node_exporter['enable'] = true
   ```

1. ファイルを保存し、変更を適用するために[GitLabを再構成します](../../restart_gitlab.md#reconfigure-a-linux-package-installation)。

Prometheusは、`localhost:9100`で公開されているノードexporterからパフォーマンスデータの収集を開始します。
