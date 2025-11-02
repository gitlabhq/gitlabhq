---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: セルフコンパイルインストールのCEインスタンスをEEに変換
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

既存のセルフコンパイルインストールのインスタンスをCommunity Edition（CE）からEnterprise Edition（EE）に移行できます。

これらの手順は、GitLab Community Editionの正しく構成されテスト済みのセルフコンパイルインストールがあることを前提としています。

## CEからEEへの変換 {#convert-from-ce-to-ee}

以下の手順では、以下を置き換えます:

- `EE_BRANCH`を、使用しているバージョンのEEブランチに置き換えます。EEブランチ名は、`major-minor-stable-ee`の形式を使用します。たとえば`17-7-stable-ee`などです。
- `CE_BRANCH`をCommunity Editionブランチに置き換えます。CEブランチ名は、`major-minor-stable`の形式を使用します。たとえば`17-7-stable`などです。

### バックアップ {#backup}

GitLabをバックアップするには、次の手順に従います:

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

### GitLabサーバーを停止 {#stop-gitlab-server}

GitLabサーバーを停止するには:

```shell
sudo service gitlab stop
```

### EEコードを入手 {#get-the-ee-code}

EEコードを入手するには:

```shell
cd /home/git/gitlab
sudo -u git -H git remote add -f ee https://gitlab.com/gitlab-org/gitlab.git
sudo -u git -H git checkout EE_BRANCH
```

### ライブラリをインストールして移行を実行する {#install-libraries-and-run-migrations}

ライブラリをインストールして移行を実行するには:

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

# Update node dependencies and recompile assets
sudo -u git -H bundle exec rake yarn:install gitlab:assets:clean gitlab:assets:compile RAILS_ENV=production NODE_ENV=production NODE_OPTIONS="--max_old_space_size=4096"

# Clean up cache
sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
```

### `gitlab-elasticsearch-indexer`をインストール {#install-gitlab-elasticsearch-indexer}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`gitlab-elasticsearch-indexer`をインストールするには、[インストール手順](../../integration/advanced_search/elasticsearch.md#install-an-elasticsearch-or-aws-opensearch-cluster)に従ってください。

### アプリケーションを起動します {#start-the-application}

アプリケーションを起動するには:

```shell
sudo service gitlab start
sudo service nginx restart
```

### アプリケーションのステータスを確認します {#check-application-status}

GitLabとその環境が正しく設定されているかどうかを検証します:

```shell
sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
```

何か見落としがないか確認するために、より徹底的なチェックを実行するには、次のコマンドを実行します:

```shell
sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```

すべての項目が緑色の場合、おめでとうございます。移行が完了しました。

## CEに戻す {#revert-back-to-ce}

EEへの変換で問題が発生し、CEにリバートする場合は:

1. コードを以前のバージョンにリバートします:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H git checkout CE_BRANCH
   ```

1. バックアップから復元する:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production
   ```

EEインスタンスをCEに復元する方法については、[EEからCEに復元する方法](revert.md)）を参照してください。
