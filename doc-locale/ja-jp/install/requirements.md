---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: インストールに必要な前提要件。
title: GitLabのインストール要件
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabには、固有のインストール要件があります。

## ストレージ {#storage}

必要とされるストレージ容量は、主にGitLabに格納するリポジトリのサイズによって異なります。ガイドラインとして、最低でも、すべてのリポジトリの合計と同じくらいの空き容量が必要です。

Linuxパッケージのインストールには、約2.5 GBのストレージ容量が必要です。ストレージの柔軟性を高めるには、論理ボリューム管理を通じてハードドライブをマウントすることを検討してください。応答時間を短縮するために、7,200 RPM以上のハードドライブ、またはソリッドステートドライブが必要です。

ファイルシステムのパフォーマンスはGitLabの全体的なパフォーマンスに影響を与える可能性があるため、[ストレージにクラウドベースのファイルシステムを使用することは避けて](../administration/nfs.md#avoid-using-cloud-based-file-systems)ください。

## CPU {#cpu}

CPU要件は、ユーザー数と予想されるワークロードによって異なります。ワークロードには、ユーザーのアクティビティー、自動化とミラーリングの使用、リポジトリのサイズが含まれます。

最大で1秒あたり20リクエストまたは1,000ユーザーの場合、8 vCPUが必要です。それ以上のユーザー数またはワークロードについては、[リファレンスアーキテクチャ](../administration/reference_architectures/_index.md)を参照してください。

## メモリ {#memory}

メモリ要件は、ユーザー数と予想されるワークロードによって異なります。ワークロードには、ユーザーのアクティビティー、自動化とミラーリングの使用、リポジトリのサイズが含まれます。

最大で1秒あたり20リクエストまたは1,000ユーザーの場合、16 GBのメモリが必要です。それ以上のユーザー数またはワークロードについては、[リファレンスアーキテクチャ](../administration/reference_architectures/_index.md)を参照してください。

場合によっては、GitLabは最低8 GBのメモリで実行できます。詳細については、[メモリ制約のある環境でGitLabを実行する](https://docs.gitlab.com/omnibus/settings/memory_constrained_envs.html)を参照してください。

## PostgreSQL {#postgresql}

[PostgreSQL](https://www.postgresql.org/)は、サポートされている唯一のデータベースであり、Linuxパッケージにバンドルされています。[外部のPostgreSQLデータベース](https://docs.gitlab.com/omnibus/settings/database.html#using-a-non-packaged-postgresql-database-management-server)も使用できますが、その場合は[正しく設定する必要があります](#postgresql-settings)。

[ユーザー数](../administration/reference_architectures/_index.md)に応じて、PostgreSQLサーバーには以下が必要です。

- ほとんどのGitLabインスタンスでは、最低5～10 GBのストレージ
- GitLab Ultimateの場合、最低12 GBのストレージ（1 GBの脆弱性データをインポートする必要があります）

次のバージョンのGitLabでは、対応するPostgreSQLバージョンを使用してください。

| GitLabバージョン | Helmチャートバージョン | PostgreSQLの最小バージョン | PostgreSQLの最大バージョン |
| -------------- | ------------------ | -------------------------- | -------------------------- |
| 18.x           | 9.x                | [16.5](https://gitlab.com/gitlab-org/gitlab/-/issues/508672) | 未定           |
| 17.x           | 8.x                | [14.14](https://gitlab.com/gitlab-org/gitlab/-/issues/508672) | 16.x（[GitLab 16.10以降に対してテスト済み](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145298)） |
| 16.x           | 7.x                | 13.6                       | 15.x（[GitLab 16.1以降に対してテスト済み](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119344)） |
| 15.x           | 6.x                | 12.10                      | 14.x（[GitLab 15.11に対してのみテスト済み](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114624)）、13.x |

PostgreSQLのマイナーリリースには、[バグとセキュリティの修正のみが含まれます](https://www.postgresql.org/support/versioning/)。PostgreSQLで既知のイシューを回避するため、常に最新のマイナーバージョンを使用してください。詳細については、[イシュー364763](https://gitlab.com/gitlab-org/gitlab/-/issues/364763)を参照してください。

指定されているバージョンよりも新しいPostgreSQLのメジャーバージョンを使用するには、[新しいバージョンがLinuxパッケージにバンドルされているかどうか](http://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html)を確認してください。

また、一部の拡張機能をすべてのGitLabデータベースに読み込む必要があります。詳細については、[PostgreSQL拡張機能を管理する](postgresql_extensions.md)を参照してください。

### GitLab Geo {#gitlab-geo}

[GitLab Geo](../administration/geo/_index.md)は、Linuxパッケージまたは[検証済みのクラウドプロバイダー](../administration/reference_architectures/_index.md#recommended-cloud-providers-and-services)を使用してGitLabをインストールする必要があります。他の外部データベースとの互換性は保証されていません。

詳細については、[Geoの実行要件](../administration/geo/_index.md#requirements-for-running-geo)を参照してください。

### ロケールの互換性 {#locale-compatibility}

`glibc`でロケールデータを変更すると、PostgreSQLデータベースファイルは、異なるオペレーティングシステム間では完全な互換性がなくなります。インデックスの破損を回避するには、以下の場合に[ロケールの互換性を確認](../administration/geo/replication/troubleshooting/common.md#check-os-locale-data-compatibility)してください。

- サーバー間でバイナリPostgreSQLデータを移動する。
- Linuxディストリビューションをアップグレードする。
- サードパーティのコンテナイメージを更新または変更する。

詳細については、[PostgreSQLのオペレーティングシステムのアップグレード](../administration/postgresql/upgrading_os.md)を参照してください。

### GitLabスキーマ {#gitlab-schemas}

GitLab、[Geo](../administration/geo/_index.md) 、[Gitaly Cluster (Praefect)](../administration/gitaly/praefect/_index.md)、またはその他のコンポーネント専用のデータベースを作成または使用する必要があります。以下に従う場合を除き、データベース、スキーマ、ユーザー、またはその他のプロパティを作成または変更しないでください。

- GitLabドキュメントの手順
- GitLabサポートまたはエンジニアの指示

主なGitLabアプリケーションは、3つのスキーマを使用します。

- デフォルトの`public`スキーマ
- `gitlab_partitions_static`（自動作成）
- `gitlab_partitions_dynamic`（自動作成）

Railsデータベースの移行中に、GitLabはスキーマまたはテーブルを作成または変更する場合があります。データベースの移行は、GitLabコードベースのスキーマ定義に対してテストされます。スキーマを変更すると、[GitLabのアップグレード](../update/_index.md)が失敗する可能性があります。

### PostgreSQLの設定 {#postgresql-settings}

外部で管理されるPostgreSQLインスタンスに必要な設定を次に示します。

| 調整可能な設定        | 必要な値 | 詳細情報 |
|:-----------------------|:---------------|:-----------------|
| `work_mem`             | 最小`8 MB`  | この値は、Linuxパッケージのデフォルトです。大規模なデプロイメントで、クエリが一時ファイルを作成する場合は、この設定を増やす必要があります。 |
| `maintenance_work_mem` | 最小`64 MB` | [大規模なデータベースサーバーの場合は、より多くの容量](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8377#note_1728173087)が必要です。 |
| `max_connections`      | 最小`400`   | お使いのGitLabコンポーネントに基づいて計算します。詳細なガイダンスについては、[Tune PostgreSQL](../administration/postgresql/tune.md)ページを参照してください。 |
| `shared_buffers`       | 最小`2 GB`  | 大規模なデータベースサーバーの場合は、より多くの容量が必要です。Linuxパッケージのデフォルトは、サーバーRAMの25%に設定されています。 |
| `statement_timeout`    | 最大1分  | ステートメントのタイムアウトにより、ロックによる制御不能イシューや、データベースが新しいクライアントを拒否するのを回避できます。1分は、Pumaラックのタイムアウト設定と一致します。 |

サーバー上のすべてのデータベースではなく、特定のデータベースに対して一部のPostgreSQL設定を設定できます。

- 同じサーバー上で複数のデータベースをホスティングする場合、特定のデータベースに設定を制限できます。
- 設定の適用場所に関するガイダンスについては、データベース管理者またはベンダーにお問い合わせください。
- GCP Cloud SQLの場合、特定のデータベースまたはユーザーに対して`statement_timeout`を設定できますが、[as a database flag](https://cloud.google.com/sql/docs/postgres/flags#list-flags-postgres)（データベースフラグとして）は設定できません。例: `ALTER DATABASE gitlab SET statement_timeout = '60s';`。

## Puma {#puma}

推奨される[Puma](https://puma.io/)設定は、[インストール](install_methods.md)によって異なります。デフォルトでは、Linuxパッケージは推奨設定を使用します。

Pumaの設定を調整するには: 

- Linuxパッケージについては、[Puma設定](../administration/operations/puma.md)を参照してください。
- GitLab Helmチャートについては、[`webservice`チャート](https://docs.gitlab.com/charts/charts/gitlab/webservice/)を参照してください。

### ワーカー {#workers}

推奨されるPumaワーカーの数は、主にCPUとメモリの容量によって異なります。デフォルトでは、Linuxパッケージは推奨される数のワーカーを使用します。この数の計算方法について詳しくは、[`puma.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/libraries/puma.rb?ref_type=heads#L46-69)を参照してください。

ノードのPumaワーカー数は2つ以上でなければなりません。たとえば、ノードには以下が必要です。

- 2 CPUコアと8 GBのメモリに対して2個のワーカー
- 4 CPUコアと4 GBのメモリに対して2個のワーカー
- 4 CPUコアと8 GBのメモリに対して4個のワーカー
- 8 CPUコアと8 GBのメモリに対して6個のワーカー
- 8 CPUコアと16 GBのメモリに対して8個のワーカー

デフォルトでは、各Pumaワーカーは1.2 GBのメモリに制限されています。`/etc/gitlab/gitlab.rb`で[この設定を調整](../administration/operations/puma.md#reducing-memory-use)できます。

十分なCPUおよびメモリ容量がある場合は、Pumaワーカーの数を増やすこともできます。ワーカー数を増やすと、応答時間が短縮され、並列リクエストを処理する能力が向上します。テストを実行して、[インストール](install_methods.md)に最適なワーカーの数を確認します。

### スレッド {#threads}

推奨されるPumaスレッド数は、システムメモリの合計によって異なります。ノードは以下を使用する必要があります。

- 最大2 GBのメモリを持つオペレーティングシステムの場合は1つのスレッド
- 2 GBを超えるメモリを持つオペレーティングシステムの場合は4つのスレッド

スレッドをそれ以上増やすと、過度のスワップが発生し、パフォーマンスが低下します。

## Redis {#redis}

[Redis](https://redis.io/)は、すべてのユーザーセッションとバックグラウンドタスクを保存し、平均してユーザーあたり約25 kBを必要とします。

GitLab 16.0以降では、Redis 6.xまたは7.xが必要です。サポート終了日について詳しくは、[Redisドキュメント](https://redis.io/docs/latest/operate/rs/installing-upgrading/product-lifecycle/)を参照してください。

Redisでは: 

- スタンドアロンインスタンスを使用します（高可用性の有無にかかわらず）。Redisクラスターはサポートされていません。
- 必要に応じて[削除ポリシー](../administration/redis/replication_and_failover_external.md#setting-the-eviction-policy)を設定します。

## Sidekiq {#sidekiq}

[Sidekiq](https://sidekiq.org/)は、バックグラウンドジョブにマルチスレッドプロセスを使用します。このプロセスでは、最初は200 MB以上のメモリを消費し、メモリリークが原因で時間とともに増加する可能性があります。

請求対象ユーザーが10,000人を超える非常にアクティブなサーバーでは、Sidekiqプロセスで1 GB以上のメモリを消費する可能性があります。

## Prometheus {#prometheus}

デフォルトでは、[Prometheus](https://prometheus.io)とその関連exporterはGitLabをモニタリングするために有効になっています。これらのプロセスは、約200 MBのメモリを消費します。

詳細については、[Prometheusを使用したGitLabのモニタリング](../administration/monitoring/prometheus/_index.md)を参照してください。

## サポートされているWebブラウザ {#supported-web-browsers}

GitLabは、次のWebブラウザをサポートしています。

- [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/new/)
- [Google Chrome](https://www.google.com/chrome/)
- [Chromium](https://www.chromium.org/getting-involved/dev-channel/)
- [Apple Safari](https://www.apple.com/safari/)
- [Microsoft Edge](https://www.microsoft.com/en-us/edge?form=MA13QK)

GitLabがサポートするもの: 

- これらのブラウザの最新の2つのメジャーバージョン
- サポートされているメジャーバージョンの現在のマイナーバージョン

これらのブラウザでJavaScriptを無効にしてGitLabを実行することはサポートされていません。

## 関連トピック {#related-topics}

- [GitLab Runnerをインストールする](https://docs.gitlab.com/runner/install/)
- [インストールのセキュリティ保護](../security/_index.md)
