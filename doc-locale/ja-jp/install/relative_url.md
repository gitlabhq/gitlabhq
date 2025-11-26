---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 相対URLでGitLabをインストール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabは専用の（サブ）ドメインにインストールする必要がありますが、さまざまな理由により、それが不可能な場合があります。その場合、GitLabは相対URL（例: `https://example.com/gitlab`）でインストールすることもできます。

このドキュメントでは、ソースからインストールする場合の、相対URLでGitLabを実行する方法について説明します。公式のLinuxパッケージを使用している場合は、[手順が異なります](https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-a-relative-url-for-gitlab)。GitLabを初めてインストールする場合は、このガイドを[インストールガイド](self_compiled/_index.md)と併せて使用してください。

相対URLのネストされた深さに制限はありません。たとえば、問題なく`/foo/bar/gitlab/git`でGitLabを提供できます。

既存のGitLabインストールでURLを変更すると、すべてのリモートURLが変更されるため、GitLabインスタンスを指すローカルリポジトリで手動で編集する必要があります。

相対URLからGitLabを提供するために変更する必要がある設定ファイルのリストは次のとおりです:

- `/home/git/gitlab/config/initializers/relative_url.rb`
- `/home/git/gitlab/config/gitlab.yml`
- `/home/git/gitlab/config/puma.rb`
- `/home/git/gitlab-shell/config.yml`
- `/etc/default/gitlab`

すべての変更後、アセットを再コンパイルし、[GitLabを再起動](../administration/restart_gitlab.md#self-compiled-installations)する必要があります。

## 相対URLの要件 {#relative-url-requirements}

相対URLでGitLabを設定すると、アセット（JavaScript、CSS、フォント、画像など）を再コンパイルする必要があり、CPUとメモリのリソースを大量に消費する可能性があります。メモリ不足エラーを回避するには、コンピューターで少なくとも2 GBのRAMを使用できるようにする必要があります。4 GBのRAMと、4つまたは8つのCPUコアをお勧めします。

詳細については、[ドキュメントの要件](requirements.md)を参照してください。

## GitLabで相対URLを有効にする {#enable-relative-url-in-gitlab}

{{< alert type="note" >}}

相対URLに関するWebサーバーの設定ファイルは変更しないでください。相対URLのサポートは、GitLab Workhorseによって実装されています。

{{< /alert >}}

---

このプロセスは以下を想定しています:

- GitLabは`/gitlab`で提供されます
- GitLabがインストールされているディレクトリは`/home/git/`です

GitLabで相対URLを有効にするには:

1. オプション。リソースが不足している場合は、次のコマンドを使用してGitLabサービスをシャットダウンすることにより、一時的にメモリを解放できます:

   ```shell
   sudo service gitlab stop
   ```

1. `/home/git/gitlab/config/initializers/relative_url.rb`を作成します

   ```shell
   cp /home/git/gitlab/config/initializers/relative_url.rb.sample \
      /home/git/gitlab/config/initializers/relative_url.rb
   ```

   そして、次の行を変更します:

   ```ruby
   config.relative_url_root = "/gitlab"
   ```

1. `/home/git/gitlab/config/gitlab.yml`を編集し、次の行のコメントを解除するか、変更します:

   ```yaml
   relative_url_root: /gitlab
   ```

1. `/home/git/gitlab/config/puma.rb`を編集し、次の行のコメントを解除するか、変更します:

   ```ruby
   ENV['RAILS_RELATIVE_URL_ROOT'] = "/gitlab"
   ```

1. `/home/git/gitlab-shell/config.yml`を編集し、次の行に相対パスを追加します:

   ```yaml
   gitlab_url: http://127.0.0.1/gitlab
   ```

1. [インストールガイド](self_compiled/_index.md#install-the-service)に記載されているように、提供されたsystemdサービス、またはinitスクリプトとデフォルトファイルをコピーしたことを確認してください。次に、`/etc/default/gitlab`を編集し、`gitlab_workhorse_options`で、次のように読み取るように`-authBackend`設定を設定します:

   ```shell
   -authBackend http://127.0.0.1:8080/gitlab
   ```

   {{< alert type="note" >}}

   カスタムinitスクリプトを使用している場合は、必要に応じて上記のGitLab Workhorse設定を編集してください。

   {{< /alert >}}

1. 変更を反映させるため、[GitLabを再起動](../administration/restart_gitlab.md#self-compiled-installations)します。

## GitLabで相対URLを無効にする {#disable-relative-url-in-gitlab}

相対URLを無効にするには:

1. `/home/git/gitlab/config/initializers/relative_url.rb`を削除します

1. 手順2から始まる上記の手順に従い、相対パスを含まないGitLab URLをセットアップします。
