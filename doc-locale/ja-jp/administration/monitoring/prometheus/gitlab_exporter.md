---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab exporter
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabインスタンスのパフォーマンスメトリクスを[GitLab exporter](https://gitlab.com/gitlab-org/ruby/gems/gitlab-exporter)で監視します。Linuxパッケージインストールの場合は、GitLab exporterがRedisとデータベースからメトリクスを取得し、ボトルネック、リソース消費パターン、および最適化の可能性のある領域に関するインサイトを提供します。

自己コンパイルによるインストール環境では、ユーザー自身がPrometheusをインストールして設定する必要があります。

## GitLab exporterを有効にする {#enable-gitlab-exporter}

LinuxパッケージインスタンスでGitLab exporterを有効にするには:

1. [Prometheusを有効にする](_index.md#configuring-prometheus)。
1. `/etc/gitlab/gitlab.rb`を編集します。
1. 次の行を追加するか、見つけてコメント解除し、`true`に設定されていることを確認します:

   ```ruby
   gitlab_exporter['enable'] = true
   ```

1. ファイルを保存して、[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

Prometheusは、`localhost:9168`で公開されているGitLab exporterからパフォーマンスデータの収集を自動的に開始します。

## 別のRackサーバーを使用する {#use-a-different-rack-server}

デフォルトでは、GitLab exporterは[WEBrick](https://github.com/ruby/webrick)（シングルスレッドのRubyウェブサーバー）で動作します。パフォーマンスのニーズにより適した別のRackサーバーを選択できます。たとえば、多数のPrometheusスクレイパーは含まれるものの、少数のモニタリングノードしか含まれないマルチノードセットアップでは、代わりにPumaのようなマルチスレッドサーバーを実行することを選択できます。

RackサーバーをPumaに変更するには:

1. `/etc/gitlab/gitlab.rb`を編集します。
1. 次の行を追加するか、見つけてコメント解除し、`puma`に設定します:

   ```ruby
   gitlab_exporter['server_name'] = 'puma'
   ```

1. ファイルを保存して、[GitLabを再設定](../../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。

サポートされているRackサーバーは`webrick`と`puma`です。
