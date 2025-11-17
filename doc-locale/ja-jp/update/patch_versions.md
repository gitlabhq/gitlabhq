---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッチバージョンでセルフコンパイルインストールをアップデート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

パッチバージョンでセルフコンパイルインストールをアップデート。

前提要件:

- セルフコンパイルインストールの[バックアップ](../administration/backup_restore/_index.md)。

## GitLabサーバーを停止 {#stop-gitlab-server}

GitLabサーバーを停止するには:

```shell
# For systems running systemd
sudo systemctl stop gitlab.target

# For systems running SysV init
sudo service gitlab stop
```

## 安定したブランチの最新コードを入手 {#get-latest-code-for-the-stable-branch}

次のコマンドで、アップデート先のGitLabタグに`LATEST_TAG`を置き換えます。たとえば`v8.0.3`などです。

1. 現在のバージョンを確認します:

   ```shell
   cat VERSION
   ```

1. 利用可能なすべてのタグのリストを取得します:

   ```shell
   git tag -l 'v*.[0-9]' --sort='v:refname'
   ```

1. 現在のメジャーおよびマイナーバージョンのパッチバージョンを選択します。
1. 使用するパッチバージョンのコードをチェックアウトします:

   ```shell
   cd /home/git/gitlab

   sudo -u git -H git fetch --all
   sudo -u git -H git checkout -- Gemfile.lock db/structure.sql locale
   sudo -u git -H git checkout LATEST_TAG -b LATEST_TAG
   ```

## ライブラリをインストールして移行を実行 {#install-libraries-and-run-migrations}

ライブラリをインストールして移行を実行するには、次のコマンドを実行します:

```shell
cd /home/git/gitlab

# If you haven't done so during installation or a previous upgrade already
sudo -u git -H bundle config set --local deployment 'true'
sudo -u git -H bundle config set --local without 'development test kerberos'

# Update gems
sudo -u git -H bundle install

# Optional: clean up old gems
sudo -u git -H bundle clean

# Run database migrations
sudo -u git -H bundle exec rake db:migrate RAILS_ENV=production

# Clean up assets and cache
sudo -u git -H bundle exec rake yarn:install gitlab:assets:clean gitlab:assets:compile cache:clear RAILS_ENV=production NODE_ENV=production NODE_OPTIONS="--max_old_space_size=4096"
```

## 新しいパッチバージョンにGitLab Workhorseをアップデート {#update-gitlab-workhorse-to-the-new-patch-version}

新しいパッチバージョンにGitLab Workhorseをアップデートするには:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
```

## 新しいパッチバージョンにGitalyをアップデート {#update-gitaly-to-the-new-patch-version}

新しいパッチバージョンにGitalyをアップデートするには:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories]" RAILS_ENV=production
```

## 新しいパッチバージョンにGitLab Shellをアップデート {#update-gitlab-shell-to-the-new-patch-version}

新しいパッチバージョンにGitLab Shellをアップデートするには:

```shell
cd /home/git/gitlab-shell

sudo -u git -H git fetch --all --tags
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_SHELL_VERSION) -b v$(</home/git/gitlab/GITLAB_SHELL_VERSION)
sudo -u git -H make build
```

## （必要な場合）新しいパッチバージョンにGitLab Pagesをアップデート {#update-gitlab-pages-to-the-new-patch-version-if-required}

GitLab Pagesを使用している場合は、新しいパッチバージョンにGitLab Pagesをアップデートします:

```shell
cd /home/git/gitlab-pages

sudo -u git -H git fetch --all --tags
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
sudo -u git -H make
```

## `gitlab-elasticsearch-indexer`をインストールまたはアップデート {#install-or-update-gitlab-elasticsearch-indexer}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`gitlab-elasticsearch-indexer`をインストールまたはアップデートするには、[インストール手順](../integration/advanced_search/elasticsearch.md#install-an-elasticsearch-or-aws-opensearch-cluster)に従ってください。

## GitLabを開始 {#start-gitlab}

GitLabを開始するには、次のコマンドを実行します:

```shell
# For systems running systemd
sudo systemctl start gitlab.target
sudo systemctl restart nginx.service

# For systems running SysV init
sudo service gitlab start
sudo service nginx restart
```

## GitLabとその環境をチェック {#check-gitlab-and-its-environment}

GitLabとその環境が正しく設定されているかどうかを検証するには、次を実行します:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
```

何か見落としがないか確認するには、次のコマンドでより徹底的なチェックを実行します:

```shell
sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```

すべての項目が緑色の場合、アップグレードは完了しています。

## バックグラウンド移行が完了したことを確認 {#make-sure-background-migrations-are-finished}

[バックグラウンド移行のステータスを確認](background_migrations.md)し、完了していることを確認してください。
