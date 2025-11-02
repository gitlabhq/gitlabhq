---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 自己コンパイルインスタンスのアップグレード
description: 自己コンパイルインスタンスをアップグレードします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

セルフコンパイルインストールされたインスタンスを、より新しいバージョンのGitLabにアップグレードします。

セルフコンパイルインストールされたGitLabインスタンスをアップグレードするには、次の手順を実行します:

1. [バックアップ](#create-a-backup)を作成します。
1. [GitLabを停止](#stop-gitlab)。
1. [Rubyを更新](#update-ruby)。
1. [Node.jsを更新](#update-nodejs)。
1. [Goを更新](#update-go)。
1. [Gitを更新](#update-git)。
1. [PostgreSQLを更新](#update-postgresql)。
1. [GitLabコードベースを更新](#update-the-gitlab-codebase)。
1. [設定ファイル](#update-configuration-files)を更新します。
1. [ライブラリをインストールして移行を実行](#install-libraries-and-run-migrations)。
1. [GitLab Shellを更新](#update-gitlab-shell)。
1. [GitLab Workhorseを更新](#update-gitlab-workhorse)。
1. [Gitalyを更新](#update-gitaly)。
1. [GitLab Pagesを更新](#update-gitlab-pages)。
1. [アップグレード後の手順](#post-upgrade-steps)を実行します。

## 前提要件 {#prerequisites}

アップグレードする前に:

- [アップグレードする前に必要な情報](plan_your_upgrade.md)を確認してください。
- Ruby、Node.js、Go、PostgreSQLの[ソフトウェア要件](../install/self_compiled/_index.md#software-requirements)を確認してください。

## バックアップを作成します {#create-a-backup}

前提要件:

- `rsync`がインストールされていることを確認してください。

バックアップを作成するには:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

## GitLabを停止 {#stop-gitlab}

GitLabを停止するには:

```shell
# For systems running systemd
sudo systemctl stop gitlab.target

# For systems running SysV init
sudo service gitlab stop
```

## Rubyを更新 {#update-ruby}

より新しいバージョンのRubyが必要な場合は、Rubyを更新する必要があります:

1. お使いのRubyのバージョンを確認するには、次を実行します:

   ```shell
   ruby -v
   ```

1. より新しいバージョンのRubyに更新する方法については、[Rubyインストール手順](https://www.ruby-lang.org/en/documentation/installation/)を参照してください。

## Node.jsを更新 {#update-nodejs}

より新しいバージョンのNode.jsが必要な場合は、Node.jsを更新する必要があります:

1. お使いのNode.jsのバージョンを確認するには、次を実行します:

   ```shell
   node -v
   ```

1. より新しいバージョンのNode.jsに更新する方法については、[Node.jsダウンロード手順](https://nodejs.org/en/download)を参照してください。

GitLabは、JavaScriptの依存関係を管理するためにYarn `>= v1.10.0`も必要とします。詳細については、[Yarnのウェブサイト](https://classic.yarnpkg.com/en/docs/install)を参照してください。

## Goを更新 {#update-go}

より新しいバージョンのGoが必要な場合は、Goを更新する必要があります:

1. お使いのGoのバージョンを確認するには、次を実行します:

   ```shell
   go version
   ```

1. より新しいバージョンのGoに更新する方法については、[Goインストール手順](https://go.dev/doc/install)を参照してください。

## Gitを更新 {#update-git}

Gitalyが提供するGitバージョンを使用する必要があります。詳細については、[Git用GitLabインストール手順](../install/self_compiled/_index.md#git)を参照してください。

## PostgreSQLを更新 {#update-postgresql}

より新しいバージョンのPostgreSQLが必要な場合は、PostgreSQLを更新する必要があります:

1. お使いのPostgreSQLのバージョンを確認するには、次を実行します:

   ```shell
   pg_ctl --version
   ```

1. より新しいバージョンのPostgreSQLに更新する方法については、[PostgreSQLのアップグレードドキュメント](https://www.postgresql.org/docs/16/upgrading.html)を参照してください。
1. 必要な[PostgreSQL拡張機能](../install/requirements.md#postgresql)があることを確認してください。

## GitLabコードベースを更新 {#update-the-gitlab-codebase}

GitLabコードベースのクローンを更新するには:

1. リポジトリメタデータをフェッチします:

   ```shell
   cd /home/git/gitlab

   sudo -u git -H git fetch --all --prune
   sudo -u git -H git checkout -- Gemfile.lock db/structure.sql locale
   ```

1. アップグレードするバージョンのブランチをチェックアウトします:

   {{< tabs >}}

   {{< tab title="GitLab Enterprise Edition" >}}

   ```shell
   cd /home/git/gitlab

   sudo -u git -H git checkout <BRANCH-ee>
   ```

   {{< /tab >}}

   {{< tab title="GitLab Community Edition" >}}

   ```shell
   cd /home/git/gitlab

   sudo -u git -H git checkout <BRANCH>
   ```

   {{< /tab >}}

   {{< /tabs >}}

## 設定ファイルを更新します。 {#update-configuration-files}

GitLabのアップグレードでは、次の設定の更新が必要になる場合があります:

- `gitlab.yml`
- `database.yml`
- NGINX（またはApache）
- SMTP
- systemd
- SysV

次のセクションでは、設定の更新が必要かどうかを判断する方法について説明します。

### `gitlab.yml`の新しい設定 {#new-configuration-for-gitlabyml}

[`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)で使用できる新しい設定オプションがあるかもしれません。

1. 利用可能な新しい設定を表示します:

   ```shell
   cd /home/git/gitlab
   git diff origin/PREVIOUS_BRANCH:config/gitlab.yml.example origin/BRANCH:config/gitlab.yml.example
   ```

1. 現在の`gitlab.yml`に新しい設定を手動で適用します。

### `database.yml`の新しい設定 {#new-configuration-for-databaseyml}

{{< history >}}

- `ci:`セクションが`config/database.yml.postgresql`にあるように、GitLab 16.0で[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119139)されました。

{{< /history >}}

[`database.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/database.yml.postgresql)で使用できる新しい設定オプションがあるかもしれません。

1. 利用可能な新しい設定を表示します:

   ```shell
   cd /home/git/gitlab
   git diff origin/PREVIOUS_BRANCH:config/database.yml.postgresql origin/BRANCH:config/database.yml.postgresql
   ```

1. 現在の`database.yml`に新しい設定を手動で適用します。

### NGINXまたはApacheの新しい設定 {#new-configuration-for-nginx-or-apache}

最新のNGINX設定の変更で、まだ最新の状態になっていることを確認します:

```shell
cd /home/git/gitlab

# For HTTPS configurations
git diff origin/PREVIOUS_BRANCH:lib/support/nginx/gitlab-ssl origin/BRANCH:lib/support/nginx/gitlab-ssl

# For HTTP configurations
git diff origin/PREVIOUS_BRANCH:lib/support/nginx/gitlab origin/BRANCH:lib/support/nginx/gitlab
```

GitLabアプリケーションは、インストール時にStrict-Transport-Securityを設定しなくなりました。引き続き使用するには、NGINX設定で有効にする必要があります。

NGINXの代わりにApacheを使用している場合は、更新された[Apacheテンプレート](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache)を参照してください。ApacheはUnixソケットの背後にあるアップストリームをサポートしていないため、[`/etc/default/gitlab`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/support/init.d/gitlab.default.example#L38)を使用して、GitLab WorkhorseにTCPポートでリッスンさせ必要があります。

### SMTP設定 {#smtp-configuration}

SMTPを使用してメールを配信する場合は、次の行を`config/initializers/smtp_settings.rb`に追加する必要があります:

```ruby
ActionMailer::Base.delivery_method = :smtp
```

例については、[`smtp_settings.rb.sample`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/smtp_settings.rb.sample#L13)を参照してください。

### systemdユニットを設定する {#configure-systemd-units}

1. systemdユニットが更新されたかどうかを確認します:

   ```shell
   cd /home/git/gitlab

   git diff origin/PREVIOUS_BRANCH:lib/support/systemd origin/BRANCH:lib/support/systemd
   ```

1. それらをコピーします:

   ```shell
   sudo mkdir -p /usr/local/lib/systemd/system
   sudo cp lib/support/systemd/* /usr/local/lib/systemd/system/
   sudo systemctl daemon-reload
   ```

### SysV initスクリプトを設定する {#configure-sysv-init-script}

[`gitlab.default.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/support/init.d/gitlab.default.example)で使用できる新しい設定オプションがあるかもしれません。

1. 利用可能な新しい設定を表示します:

   ```shell
   cd /home/git/gitlab

   git diff origin/PREVIOUS_BRANCH:lib/support/init.d/gitlab.default.example origin/BRANCH:lib/support/init.d/gitlab.default.example
   ```

1. 現在の`/etc/default/gitlab`に手動で適用します。

最新のinitスクリプトの変更で、まだ最新の状態になっていることを確認します:

```shell
cd /home/git/gitlab

sudo cp lib/support/init.d/gitlab /etc/init.d/gitlab
```

ネイティブのsystemdユニットにまだ切り替えていないため、initとしてsystemdを実行しているシステムでinitスクリプトを使用している場合は、次を実行します:

```shell
sudo systemctl daemon-reload
```

## ライブラリをインストールして移行を実行する {#install-libraries-and-run-migrations}

ライブラリをインストールして移行を実行するには:

1. 必要なライブラリをインストールします:

   ```shell
   cd /home/git/gitlab

   # If you haven't done so during installation or a previous upgrade already
   sudo -u git -H bundle config set --local deployment 'true'
   sudo -u git -H bundle config set --local without 'development test kerberos'

   # Update gems
   sudo -u git -H bundle install

   # Optional: clean up old gems
   sudo -u git -H bundle clean
   ```

1. 移行を実行します:

   ```shell
   # Run database migrations
   sudo -u git -H bundle exec rake db:migrate RAILS_ENV=production

   # Update node dependencies and recompile assets
   sudo -u git -H bundle exec rake yarn:install gitlab:assets:clean gitlab:assets:compile RAILS_ENV=production NODE_ENV=production NODE_OPTIONS="--max_old_space_size=4096"

   # Clean up cache
   sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
   ```

## GitLab Shellを更新 {#update-gitlab-shell}

GitLab Shellを更新するには、次のコマンドを実行します:

```shell
cd /home/git/gitlab-shell

sudo -u git -H git fetch --all --tags --prune
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_SHELL_VERSION)
sudo -u git -H make build
```

## GitLab Workhorseを更新 {#update-gitlab-workhorse}

GitLab Workhorseをインストールしてビルドするには、次のコマンドを実行します:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
```

## Gitalyを更新 {#update-gitaly}

アプリケーションサーバーをアップグレードする前に、Gitalyサーバーを新しいバージョンにアップグレードします。これにより、アプリケーションサーバー上のgRPCクライアントが、古いGitalyバージョンがサポートしていないRPCsを送信するのを防ぎます。

Gitalyが独自のサーバーにある場合、またはGitalyクラスター（Praefect）を使用する場合は、[ゼロダウンタイムアップグレード](zero_downtime.md)を参照してください。

ビルドプロセス中に、Gitalyは[Gitバイナリをコンパイルして埋め込み](https://gitlab.com/gitlab-org/gitaly/-/issues/6089)ますが、これには追加の依存関係が必要です。

```shell
# Install dependencies
sudo apt-get install -y libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev libpcre2-dev build-essential

# Fetch Gitaly source with Git and compile with Go
cd /home/git/gitlab
sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories]" RAILS_ENV=production
```

## GitLab Pagesを更新 {#update-gitlab-pages}

GitLab Pagesをインストールしてビルドするには:

```shell
cd /home/git/gitlab-pages

sudo -u git -H git fetch --all --tags --prune
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
sudo -u git -H make
```

## アップグレード後の手順 {#post-upgrade-steps}

アップグレード後:

1. [GitLabとNGINXを起動](#start-gitlab-and-nginx)。
1. [GitLabステータスをチェック](#check-gitlab-status)。

### GitLabとNGINXを起動 {#start-gitlab-and-nginx}

GitLabとNGINXを起動するには:

```shell
# For systems running systemd
sudo systemctl start gitlab.target
sudo systemctl restart nginx.service

# For systems running SysV init
sudo service gitlab start
sudo service nginx restart
```

### GitLabステータスをチェック {#check-gitlab-status}

GitLabのステータスをチェックするには:

1. GitLabとその環境が正しく設定されているかどうかを検証します:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
   ```

1. 何か見落としがないか確認するために、より徹底的なチェックを実行するには、次のコマンドを実行します:

   ```shell
   cd /home/git/gitlab

   sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
   ```

すべての項目が緑色の場合は、おめでとうございます。アップグレードは完了です。

## トラブルシューティング {#troubleshooting}

アップグレード中に問題が発生した場合は、次のセクションの手順を試してください。

### コードを以前のバージョンにロールバック {#revert-the-code-to-the-previous-version}

以前のバージョンにロールバックするには、以前のバージョンのアップグレードガイドに従う必要があります。

たとえば、GitLab 16.6にアップグレードし、16.5にロールバックする場合は、16.4から16.5へのアップグレードのガイドに従ってください。

ロールバックする場合:

- **データベース移行**ガイドに従うべきではありません。これは、バックアップがすでに以前のバージョンに移行されているためです。
- データベース移行を実行した場合は、ダウングレード後にバックアップを復元する必要があります。コードのバージョンは、使用されているスキーマのバージョンと互換性がある必要があります。古いスキーマはバックアップにあります。

### バックアップから復元する {#restore-from-a-backup}

バックアップから復元するには:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production
```

複数のバックアップ`*.tar`ファイルがある場合は、前のコードブロックに`BACKUP=timestamp_of_backup`を追加します。
