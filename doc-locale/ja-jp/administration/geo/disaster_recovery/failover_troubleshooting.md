---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Geoフェイルオーバーのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## フェイルオーバー中、またはセカンダリをプライマリサイトにプロモートする際のエラーのトラブルシューティング {#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site}

以下は、フェイルオーバー中、またはセカンダリをプライマリサイトにプロモートする際に発生する可能性のあるエラーメッセージと、それらを解決するための対策です。

### メッセージ：`ActiveRecord::RecordInvalid: Validation failed: Name has already been taken` {#message-activerecordrecordinvalid-validation-failed-name-has-already-been-taken}

[**セカンダリ**サイトをプロモートする](_index.md#step-3-promoting-a-secondary-site)場合、次のエラーメッセージが表示されることがあります:

```plaintext
Running gitlab-rake geo:set_secondary_as_primary...

rake aborted!
ActiveRecord::RecordInvalid: Validation failed: Name has already been taken
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:236:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:221:in `block (2 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Tasks: TOP => geo:set_secondary_as_primary
(See full trace by running task with --trace)

You successfully promoted this node!
```

`gitlab-rake geo:set_secondary_as_primary`または`gitlab-ctl promote-to-primary-node`の実行時にこのメッセージが表示された場合は、Railsコンソールを起動して次を実行します:

  ```ruby
  Rails.application.load_tasks; nil
  Gitlab::Geo.expire_cache!
  Rake::Task['geo:set_secondary_as_primary'].invoke
  ```

### メッセージ：``NoMethodError: undefined method `secondary?' for nil:NilClass`` {#message-nomethoderror-undefined-method-secondary-for-nilnilclass}

[**セカンダリ**サイトをプロモートする](_index.md#step-3-promoting-a-secondary-site)場合、次のエラーメッセージが表示されることがあります:

```plaintext
sudo gitlab-rake geo:set_secondary_as_primary

rake aborted!
NoMethodError: undefined method `secondary?' for nil:NilClass
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:232:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/ee/lib/tasks/geo.rake:221:in `block (2 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Tasks: TOP => geo:set_secondary_as_primary
(See full trace by running task with --trace)
```

このコマンドはセカンダリサイトでのみ実行されることを想定しており、このコマンドをプライマリサイトで実行しようとすると、このエラーメッセージが表示されます。

### 期限切れのアーティファクト {#expired-artifacts}

何らかの理由で、Geoの**セカンダリ**サイトに、Geoの**プライマリ**サイトよりも多くのアーティファクトがある場合は、Rakeタスクを使用して[orphanアーティファクトファイル](../../raketasks/cleanup.md#remove-orphan-artifact-files)をクリーンアップします

Geoの**セカンダリ**サイトでは、このコマンドはディスク上の孤立ファイルに関連するすべてのGeoレジストリレコードもクリーンアップします。

### サインインエラーの修正 {#fixing-sign-in-errors}

#### メッセージ: 含まれているリダイレクトURIが無効です {#message-the-redirect-uri-included-is-not-valid}

**プライマリ**サイトのWebインターフェースにサインインできるのに、**セカンダリ** Webインターフェースにサインインしようとするとこのエラーメッセージが表示される場合は、GeoサイトのURLが外部のURLと一致していることを確認する必要があります。

**プライマリ**サイトで以下を実行します:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **Geo** > **サイト**を選択します。
1. 影響を受ける**セカンダリ**サイトを見つけて、**編集**を選択します。
1. **URL**フィールドが、**Rails nodes of the secondary**（セカンダリ）サイトのRailsノードの`/etc/gitlab/gitlab.rb`にある`external_url "https://gitlab.example.com"`の値と一致することを確認します。

#### セカンダリサイトでのSAMLでの認証は、常にプライマリサイトに着地します {#authenticating-with-saml-on-the-secondary-site-always-lands-on-the-primary-site}

この[問題は通常、GitLab 15.1へのアップグレード時に発生します](../../../update/versions/gitlab_15_changes.md#1510)。この問題を修正するには、[Geoでシングルサインオンを使用してインスタンス全体のSAMLを設定する](../replication/single_sign_on.md#configuring-instance-wide-saml)を参照してください。

## 部分的なフェイルオーバーからの回復 {#recovering-from-a-partial-failover}

セカンダリGeoサイトへの部分的なフェイルオーバーは、一時的/ 一時的な問題の結果である可能性があります。したがって、最初にプロモートコマンドを再度実行してみてください。

1. **セカンダリ**サイトのすべてのSidekiq、PostgreSQL、Gitaly、およびRailsノードにSSHで接続し、次のいずれかのコマンドを実行します:

   - セカンダリサイトをプライマリサイトにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - セカンダリサイトを**without any further confirmation**（さらに確認せずに）プライマリにプロモートするには:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. **セカンダリ**サイトに以前使用したURLを使用して、新しくプロモートされた**プライマリ**サイトに接続できることを確認します。
1. **successful**（成功した場合）、**セカンダリ**サイトが**プライマリ**サイトにプロモートされました。

前の手順が**not successful**（成功しなかった）場合は、次の手順に進みます:

1. **セカンダリ**サイトのすべてのSidekiq、PostgreSQL、Gitaly、およびRailsノードにSSHで接続し、次の操作を実行します:

   - 次の内容で`/etc/gitlab/gitlab-cluster.json`ファイルを作成します:

     ```shell
     {
       "primary": true,
       "secondary": false
     }
     ```

   - 変更を有効にするには、GitLabを再構成します:

     ```shell
     sudo gitlab-ctl reconfigure
     ```

1. **セカンダリ**サイトに以前使用したURLを使用して、新しくプロモートされた**プライマリ**サイトに接続できることを確認します。
1. 成功した場合、**セカンダリ**サイトが**プライマリ**サイトにプロモートされました。
