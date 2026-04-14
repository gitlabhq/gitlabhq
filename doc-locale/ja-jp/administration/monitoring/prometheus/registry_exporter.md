---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: レジストリexporter
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

レジストリexporterを使用すると、さまざまなレジストリメトリクスを測定できます。有効にするには、次の手順に従います。

1. [Prometheusを有効にする](_index.md#configuring-prometheus)。
1. `/etc/gitlab/gitlab.rb`を編集し、レジストリの[デバッグモード](https://docs.docker.com/registry/#debug)を有効にします:

   ```ruby
   registry['debug_addr'] = "localhost:5001"  # localhost:5001/metrics
   ```

1. ファイルを保存して、[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

Prometheusは、`localhost:5001/metrics`で公開されているレジストリのexporterからパフォーマンスデータの収集を自動的に開始します。

[← Prometheusのメインページに戻る](_index.md)
