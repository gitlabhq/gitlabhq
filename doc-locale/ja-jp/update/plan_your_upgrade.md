---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アップグレード前に
description: アップグレードの前に実行する手順。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabインスタンスをアップグレードする前に、以下を実行する必要があります:

1. アップグレードに備えるために、アップグレード前の情報を収集します。
1. GitLab自体をアップグレードする前に、アップグレード前の手順を実行します。

## アップグレード前の情報を収集する {#gather-pre-upgrade-information}

アップグレードを計画する際は、以下を行います:

1. [GitLabのリリースおよびメンテナンスポリシー](../policy/maintenance.md)を確認してください。
1. 互換性を確保するため、アップグレード前に、さまざまなバージョンのGitLabに関する[GitLabのリリースノート](versions/_index.md)を参照してください。
1. 該当する場合は、[GitLab対象バージョンとのOSの互換性](../install/package/_index.md)を確認してください。
1. Geoを使用している場合:
   - [Geoアップグレードドキュメント](../administration/geo/replication/upgrading_the_geo_sites.md)を確認します。
   - [GitLabのアップグレードに関する注記](versions/_index.md)で、Geo固有の情報を確認します。
   - [データベースをアップグレード](https://docs.gitlab.com/omnibus/settings/database.html#upgrading-a-geo-instance)する場合は、Geo固有の手順を確認してください。
   - 各Geoサイト（プライマリおよび各セカンダリ）のアップグレードおよびロールバック計画を作成します。
1. 必要なアップグレード停止を含め、インスタンスに適した[アップグレードパス](upgrade_paths.md)を決定します。アップグレードストップにより、複数のアップグレードを実行するよう求められる場合があります。
1. 以下を記述したアップグレード計画を作成します:
   - 可能な場合、[ゼロダウンタイムアップグレード](zero_downtime.md)を含め、インスタンスをアップグレードするために実行する手順。
   - 必要な場合に[GitLabをロールバックする方法](#create-a-rollback-plan-and-backup)を含め、アップグレードがスムーズに進まない場合に実行する手順。

アップグレード前の情報をすべて収集したら、アップグレード前の手順の実行に進むことができます。

### ロールバック計画とバックアップを作成する {#create-a-rollback-plan-and-backup}

アップグレード中に問題が発生する可能性があるため、ロールバック計画を立てることが重要です。適切なロールバック計画を作成することで、インスタンスを最後に動作していた状態に戻すための明確な道筋ができます:

- インスタンスをバックアップするプロセス。
- インスタンスを復元するプロセス。

ロールバックプランは、実際に必要になる前にテストする必要があります。ロールバックに必要な手順の概要については、[以前のGitLabのバージョンにロールバックする](package/downgrade.md)を参照してください。

#### GitLabのバックアップを作成します。 {#create-a-gitlab-backup}

アップグレードで問題が発生した場合に、GitLabをロールバックできるようにするには、次のいずれかの操作を行います:

- [GitLabのバックアップ](../administration/backup_restore/_index.md)を作成します。インストールの方法に基づいて指示に従い、[シークレットと設定ファイル](../administration/backup_restore/backup_gitlab.md#storing-configuration-files)を必ずバックアップしてください。
- インスタンスのスナップショットを作成します。インスタンスがマルチノードインストールされている場合は、すべてのノードのスナップショットを作成する必要があります。**このプロセスは、GitLabサポートの範囲外です。**

#### GitLabをロールバックする {#roll-back-gitlab}

本番環境を模倣したテスト環境がある場合は、復元をテストして、すべてが期待どおりに動作することを確認してください。

GitLabのバックアップを復元するには:

1. [復元の前提条件](../administration/backup_restore/restore_gitlab.md#restore-prerequisites)を参照してください。最も重要なことは、バックアップされたGitLabインスタンスと新しいGitLabインスタンスのバージョンが同じである必要があります。
1. インストールの方法に基づいて指示に従って、[GitLabを復元します](../administration/backup_restore/_index.md#restore-gitlab)。
1. [シークレットと設定ファイル](../administration/backup_restore/backup_gitlab.md#storing-configuration-files)も復元されていることを確認してください。

スナップショットから復元する場合は、その方法をすでに知っている必要があります。**このプロセスは、GitLabサポートの範囲外です。**

## アップグレードを行う前に、事前アップグレード手順を実行します。 {#perform-pre-upgrade-steps}

アップグレードを実行する直前に、以下を行います:

1. 最初にテスト環境でアップグレードをテストし、計画外の停止や長期ダウンタイムのリスクを軽減するためにロールバック計画を立ててください。
1. [アップグレードヘルスチェック](#run-upgrade-health-checks)を実行します。
1. 使用する[オプション機能のアップグレード](#upgrades-for-optional-features)を実行します。

### アップグレードヘルスチェックを実行する {#run-upgrade-health-checks}

アップグレードの直前と直後に、GitLabの主要コンポーネントが動作していることを確認するために、アップグレードヘルスチェックを実行します:

1. [一般的な設定を確認します](../administration/raketasks/maintenance.md#check-gitlab-configuration):

   ```shell
   sudo gitlab-rake gitlab:check
   ```

1. [すべてのバックグラウンドデータベース移行のステータス](background_migrations.md)を確認します。すべての移行は、各アップグレードの前に完了する必要があります。バックグラウンド移行を完了する時間を確保するために、メジャーリリースとマイナーリリースの間でアップグレードを分散させる必要があります。
1. 暗号化されたデータベース値が[復号化できる](../administration/raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)ことを確認します:

   ```shell
   sudo gitlab-rake gitlab:doctor:secrets
   ```

1. GitLabのUIで、以下を確認します:
   - ユーザーがサインインできる。
   - プロジェクトリストが表示される。
   - プロジェクトのイシューとマージリクエストにアクセスできる。
   - ユーザーがGitLabからリポジトリを複製できる。
   - ユーザーがGitLabにコミットをプッシュできる。

1. GitLab CI/CDでは、以下を確認します:
   - Runnerがジョブを取得する。
   - Dockerイメージをレジストリからプッシュおよびプルできる。

1. Geoを使用している場合は、プライマリサイトと各セカンダリサイトで関連するチェックを実行します:

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

1. Elasticsearchを使用している場合は、検索が成功したことを確認します。

問題が発生した場合は、[サポートにお問い合わせください](#get-support)。

### オプション機能のアップグレード {#upgrades-for-optional-features}

GitLabインスタンスの設定方法によっては、GitLabをアップグレードする前に、これらの追加手順を実行する必要がある場合があります:

1. 外部Gitalyサーバーを使用している場合は、GitLab自体をアップグレードする前に、Gitalyサーバーを新しいバージョンにアップグレードします。これにより、アプリケーションサーバー上のgRPCクライアントが、古いGitalyバージョンがサポートしていないRPCsを送信するのを防ぎます。
1. KubernetesクラスターがGitLabに接続されている場合は、新しいGitLabバージョンに合わせて[Kubernetes向けGitLabエージェントをアップグレード](../user/clusters/agent/install/_index.md#update-the-agent-version)します。
1. 高度な検索（Elasticsearch）を使用している場合は、[保留中の移行の確認](background_migrations.md#check-for-pending-advanced-search-migrations)によって、高度な検索移行が完了したことを確認します。

   GitLabをアップグレードした後、新しいバージョンが互換性を損なう場合は、[Elasticsearch](../integration/advanced_search/elasticsearch.md#version-requirements)をアップグレードする必要があるかもしれません。Elasticsearchの更新は**GitLabサポートの対象外**です。

## CI/CDパイプラインとジョブを一時停止する {#pause-cicd-pipelines-and-jobs}

ほとんどの種類のGitLabインスタンスのアップグレード中は、CI/CDパイプラインとジョブを一時停止する必要があります。

GitLab Runnerがジョブを処理している間にGitLabインスタンスをアップグレードすると、トレーシングの更新が失敗します。GitLabがオンラインに戻ると、トレース更新は自動修復されるはずです。トレースの更新が自己修復しない場合、エラーに応じて、GitLab Runnerはジョブ処理を再試行するか、終了します。

GitLab Runnerはジョブアーティファクトのアップロードを3回試行し、その後ジョブが失敗します。

CI/CDパイプラインとジョブを一時停止するには、次のようにします:

1. Runnerを一時停止します。
1. 次の内容を`/etc/gitlab/gitlab.rb`ファイルに追加して、新しいジョブが開始されないようにブロックします:

   ```ruby
   nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n deny all;\n return 503;\n}\n"
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. すべてのジョブが完了するまで待ちます。

GitLabのアップグレードが完了したら、次のようにします:

1. Runnerの一時停止を解除します。
1. 以前の`/etc/gitlab/gitlab.rb`の変更を元に戻して、新しいジョブが開始されないようにブロックします。

## サポートと連携する {#working-with-support}

[サポートと連携](https://about.gitlab.com/support/scheduling-upgrade-assistance/)してアップグレードプランをレビューする場合は、レビューと次の質問への回答を文書化して共有してください:

- GitLabはどのようにインストールされていますか？
- ノードのオペレーティングシステムは何ですか？[サポートされているプラットフォーム](../install/package/_index.md#supported-platforms)をチェックして、新しい更新が利用できることを確認してください。
- シングルノードのセットアップですか、それともマルチノードのセットアップですか？マルチノードの場合は、各ノードに関するアーキテクチャの詳細を文書化して共有してください。どの外部コンポーネントが使用されていますか？たとえば、Gitaly、PostgreSQL、またはRedisですか？
- [Geo](../administration/geo/_index.md)を使用していますか？使用している場合は、各セカンダリサイトに関するアーキテクチャの詳細を文書化して共有してください。
- セットアップで他にどのようなユニークな点または興味深い点が重要になる可能性がありますか？
- 現在のバージョンのGitLabで既知の問題が発生していますか？

## サポートを受ける {#get-support}

アップグレード中に問題が発生した場合は、次のようにします:

1. エラーをコピーして、後で分析するためにログを収集します。データの収集には次のツールが役立ちます:
   - [`gitlabsos`](https://gitlab.com/gitlab-com/support/toolbox/gitlabsos): LinuxパッケージまたはDockerを使用してGitLabをインストールした場合。
   - [`kubesos`](https://gitlab.com/gitlab-com/support/toolbox/kubesos/): Helm Chartを使用してGitLabをインストールした場合。
1. 最後に動作していたバージョンにロールバックします。

サポート:

- [GitLabサポート](https://support.gitlab.com/hc/en-us)にお問い合わせください。担当のカスタマーサクセスマネージャーがいる場合は、そちらにもお問い合わせください。
- [問題の状態が対象となる](https://about.gitlab.com/support/#definitions-of-support-impact) 、かつ[プランに緊急サポートが含まれている](https://about.gitlab.com/support/#priority-support)場合は、緊急チケットを作成してください。
