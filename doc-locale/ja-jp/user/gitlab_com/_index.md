---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab.com の設定
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

このページでは、[GitLab SaaS](https://about.gitlab.com/pricing/)をご利用のお客様が利用できる、GitLab.comで使用されている設定について説明します。

これらの設定の一部については、GitLab.com の[インスタンス設定ページ](https://gitlab.com/help/instance_configuration)を参照してください。

## アカウントと制限の設定

GitLab.comでは、次のアカウント制限が有効になっています。設定がリストにない場合、デフォルト値は[Self-Managedインスタンスと同じ](../../administration/settings/account_and_limit_settings.md)です。

| 設定                                                                                                                                                                                                            | GitLab.comのデフォルト |
|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------|
| [LFSを含むリポジトリサイズ](../../administration/settings/account_and_limit_settings.md#repository-size-limit)                                                                                                 | 10 GB              |
| [最大インポートサイズ](../project/settings/import_export.md#import-a-project-and-its-data)                                                                                                                          | 5 GiB              |
| [最大エクスポートサイズ](../project/settings/import_export.md#export-a-project-and-its-data)                                                                                                                          | 40 GiB              |
| [外部オブジェクトストレージからのインポートの最大リモートファイルサイズ](../../administration/settings/import_and_export_settings.md#maximum-remote-file-size-for-imports)                                             | 10 GiB             |
| [ダイレクト転送によるソースGitLabインスタンスからのインポート時の最大ダウンロードファイルサイズ](../../administration/settings/import_and_export_settings.md#maximum-download-file-size-for-imports-by-direct-transfer) | 5 GiB              |
| 添付ファイルの最大サイズ                                                                                                                                                                                            | 100 MiB            |
| [インポートされたアーカイブの最大解凍ファイルサイズ](../../administration/settings/import_and_export_settings.md#maximum-decompressed-file-size-for-imported-archives)                                           | 25 GiB             |
| [最大プッシュサイズ](../../administration/settings/account_and_limit_settings.md#max-push-size)                                                                                                                     | 5 GiB              |

リポジトリのサイズ制限に近い場合、または制限を超えている場合は、次のいずれかを実行できます。

- [Gitでリポジトリのサイズを縮小](../project/repository/repository_size.md#methods-to-reduce-repository-size)する。
- [ストレージを追加購入](https://about.gitlab.com/pricing/licensing-faq/#can-i-buy-more-storage)する。

{{< alert type="note" >}}

`git push`とGitLabプロジェクトのインポートは、Cloudflareを介したリクエストごとに5 GiBに制限されています。ファイルアップロード以外のインポートは、この制限の影響を受けません。リポジトリの制限は、パブリックプロジェクトとプライベートプロジェクトの両方に適用されます。

{{< /alert >}}

## バックアップ

[バックアップ戦略を参照してください](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/#backups)。

GitLab.comでプロジェクト全体をバックアップするには、次のいずれかの方法でエクスポートできます。

- [UI経由](../project/settings/import_export.md)。
- [API経由](../../api/project_import_export.md#schedule-an-export)。APIを使用して、エクスポートをAmazon S3などのストレージプラットフォームにプログラムでアップロードすることもできます。

エクスポートでは、プロジェクトのエクスポートに[何が含まれ、何が含まれない](../project/settings/import_export.md#project-items-that-are-exported)かに注意してください。

GitLabはGit上にビルドされているため、別のコンピューターにプロジェクトのリポジトリのクローンを作成することで、リポジトリのみをバックアップできます。同様に、プロジェクトのWikiのクローンを作成してバックアップできます。[2020年8月22日以降にアップロードされた](../project/wiki/_index.md#create-a-new-wiki-page)ファイルはすべて、クローン作成時に含まれます。

## CI/CD

以下は、[GitLab CI/CD](../../ci/_index.md)に関する現在の設定です。ここに記載されていない設定または機能制限はすべて、関連ドキュメントに記載されているデフォルトを使用しています。

| 設定                                                                          | GitLab.com                                                                                                 | デフォルト（GitLab Self-Managed） |
|----------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|------------------------|
| アーティファクトの最大サイズ（圧縮）                                              | 1 GB                                                                                                       | [アーティファクトの最大サイズ](../../administration/settings/continuous_integration.md#maximum-artifacts-size)を参照してください。 |
| アーティファクトの[有効期限](../../ci/yaml/_index.md#artifactsexpire_in)               | 特に指定がない限り30日間                                                                         | [アーティファクトのデフォルトの有効期限](../../administration/settings/continuous_integration.md#default-artifacts-expiration)を参照してください。2020年6月22日より前に作成されたアーティファクトには、有効期限はありません。 |
| スケジュールされたパイプラインCron                                                          | `*/5 * * * *`                                                                                              | [パイプラインスケジュールの詳細設定](../../administration/cicd/_index.md#change-maximum-scheduled-pipeline-frequency)を参照してください。 |
| アクティブなパイプラインの最大ジョブ数                                                 | Freeプランの場合は`500`、すべてのトライアルプランの場合は`1000`、Premiumの場合は`20000`、Ultimateの場合は`100000`           | 「[アクティブなパイプライン内のジョブ数](../../administration/instance_limits.md#number-of-jobs-in-active-pipelines)」を参照してください。 |
| プロジェクトに対するCI/CDサブスクリプションの最大数                                         | `2`                                                                                                        | 「[プロジェクトに対するCI/CDサブスクリプションの数](../../administration/instance_limits.md#number-of-cicd-subscriptions-to-a-project)」を参照してください。 |
| プロジェクト内のパイプライントリガーの最大数                                 | `25000`                                                                                                    | 「[パイプライントリガー数を制限する](../../administration/instance_limits.md#limit-the-number-of-pipeline-triggers)」を参照してください。 |
| プロジェクト内のパイプラインスケジュールの最大数                                           | Freeプランの場合は`10`、すべての有料プランの場合は`50`                                                                | 「[パイプラインスケジュール数](../../administration/instance_limits.md#number-of-pipeline-schedules)」を参照してください。 |
| 各スケジュールに対するパイプラインの最大数                                                   | Freeプランの場合は`24`、すべての有料プランの場合は`288`                                                               | 「[1日にパイプラインスケジュールによって作成できるパイプラインの数を制限する](../../administration/instance_limits.md#limit-the-number-of-pipelines-created-by-a-pipeline-schedule-each-day)」を参照してください。 |
| 各セキュリティポリシープロジェクトに対して定義されたスケジュールルールの最大数        | すべての有料プランで無制限                                                                               | [セキュリティポリシープロジェクトに対して定義されたスケジュールルールの数](../../administration/instance_limits.md#limit-the-number-of-schedule-rules-defined-for-security-policy-project)を参照してください。 |
| スケジュールされたジョブのアーカイブ                                                          | 3か月                                                                                                   | なし。2020年6月22日より前に作成されたジョブは、2020年9月22日以降にアーカイブされました。 |
| 各[単体試験レポート](../../ci/testing/unit_test_reports.md)の最大テストケース数 | `500000`                                                                                                   | 無制限。             |
| 登録済みRunnerの最大数                                                       | Freeプラン: 各グループに対して`50`、各プロジェクトに対して`50`<br/>すべての有料プラン: 各グループに対して`1000`、各プロジェクトに対して`1000` | 「[スコープごとの登録Runner数](../../administration/instance_limits.md#number-of-registered-runners-for-each-scope)」を参照してください。 |
| dotenv変数の制限                                                        | Freeプラン: `50`<br>Premiumプラン: `100`<br>Ultimateプラン: `150`                                             | 「[dotenv変数を制限する](../../administration/instance_limits.md#limit-dotenv-variables)」を参照してください。 |
| ダウンストリームパイプラインの最大トリガーレート（特定のプロジェクト、ユーザー、コミットの場合） | 毎分`350`                                                                                           | [ダウンストリームパイプラインの最大トリガーレート](../../administration/settings/continuous_integration.md#maximum-downstream-pipeline-trigger-rate)を参照してください。 |

## コンテナレジストリ

| 設定                                | GitLab.com                       | デフォルト（Self-Managed） |
|:---------------------------------------|:---------------------------------|------------------------|
| ドメイン名                            | `registry.gitlab.com`            |                        |
| IPアドレス                             | `35.227.35.254`                  |                        |
| CDNドメイン名                        | `cdn.registry.gitlab-static.net` |                        |
| CDN IPアドレス                         | `34.149.22.116`                  |                        |
| 認証トークンの有効期間（分） | `15`                             | [コンテナレジストリトークンの有効期間の延長](../../administration/packages/container_registry.md#increase-token-duration)を参照してください。 |

GitLabコンテナレジストリを使用するには、Dockerクライアントが以下にアクセスできる必要があります。

- 認証用のレジストリエンドポイントとGitLab.com
- イメージをダウンロードするためのGoogle Cloud StorageまたはGoogle Cloud Content Delivery Network

GitLab.comはCloudflareによって保護されています。GitLab.comへの受信接続については、CloudflareのCIDRブロック（[IPv4](https://www.cloudflare.com/ips-v4/)および[IPv6](https://www.cloudflare.com/ips-v6/)）を許可する必要がある場合があります。

## メール

メール設定、IPアドレス、エイリアス

### 確認設定

GitLab.comでは、次のメール確認設定が使用されます。

- [`email_confirmation_setting`](../../administration/settings/sign_up_restrictions.md#confirm-user-email)は**Hard**に設定されています。
- [`unconfirmed_users_delete_after_days`](../../administration/moderate_users.md#automatically-delete-unconfirmed-users)は3日に設定されています。

### IPアドレス

GitLab.comは、`mg.gitlab.com`ドメインからメールを送信するために[Mailgun](https://www.mailgun.com/)を使用しており、独自の専用IPアドレスを持っています。

- `23.253.183.236`
- `69.72.35.190`
- `69.72.44.107`
- `159.135.226.146`
- `161.38.202.219`
- `192.237.158.143`
- `192.237.159.239`
- `198.61.254.136`
- `198.61.254.160`
- `209.61.151.122`

`mg.gitlab.com`のIPアドレスは、いつでも変更される可能性があります。

### サービスデスクのエイリアス

GitLab.comには、メールアドレス`contact-project+%{key}@incoming.gitlab.com`を持つサービスデスク用に設定されたメールボックスがあります。このメールボックスを使用するには、プロジェクト設定で[カスタムサフィックス](../project/service_desk/configure.md#configure-a-suffix-for-service-desk-alias-email)を設定します。

## GitLab.comにおけるGitaly RPCの並行処理の制限

リポジトリごとのGitaly RPCの並行処理およびキューイングの制限は、`git clone`などのさまざまな種類のGit操作に対して設定されています。これらの制限を超えると、`fatal: remote error: GitLab is currently unable to handle this request due to load`メッセージがクライアントに返されます。

管理者向けドキュメントについては、「[RPCの並行処理を制限する](../../administration/gitaly/concurrency_limiting.md#limit-rpc-concurrency)」を参照してください。

## GitLab Pages

[GitLab Pages](../project/pages/_index.md)の一部の設定は、[Self-Managedインスタンスのデフォルト](../../administration/pages/_index.md)とは異なります。

| 設定                                           | GitLab.com             |
|:--------------------------------------------------|:-----------------------|
| ドメイン名                                       | `gitlab.io`            |
| IPアドレス                                        | `35.185.44.232`        |
| カスタムドメインのサポート                        | {{< icon name="check-circle" >}} 可 |
| TLS証明書のサポート                      | {{< icon name="check-circle" >}} 可 |
| サイトの最大サイズ                                 | 1 GB                   |
| GitLab Pages Webサイトごとのカスタムドメインの数 | 150                    |

Pagesサイトの最大サイズは、[GitLab CI/CD](#cicd)の一部であるアーティファクトの最大サイズによって異なります。

[レート制限](#rate-limits-on-gitlabcom)はGitLab Pagesにも存在します。

## 大規模なGitLab.com

GitLab.comでは、GitLab EnterpriseエディションのLinuxパッケージのインストールに加えて、次のアプリケーションと設定を使用してスケールを実現しています。すべての設定は、[Kubernetesの設定](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com)または[Chef Cookbook](https://gitlab.com/gitlab-cookbooks)として公開されています。

### Consul

サービスディスカバリ:

- [`gitlab-cookbooks` / `gitlab_consul` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab_consul)

### Elasticクラスター

ElasticsearchとKibanaをモニタリングソリューションの一部として使用しています。

- [`gitlab-cookbooks` / `gitlab-elk` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-elk)
- [`gitlab-cookbooks` / `gitlab_elasticsearch` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab_elasticsearch)

### Fluentd

Fluentdを使用してGitLabログを統合しています。

- [`gitlab-cookbooks` / `gitlab_fluentd` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab_fluentd)

### Grafana

モニタリングデータの視覚化:

- [`gitlab-cookbooks` / `gitlab-grafana` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-grafana)

### HAProxy

高性能TCP/HTTPロードバランサー:

- [`gitlab-cookbooks` / `gitlab-haproxy` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy)

### Prometheus

Prometheusはモニタリングスタックを完了します。

- [`gitlab-cookbooks` / `gitlab-prometheus` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-prometheus)

### Sentry

オープンソースのエラートラッキング:

- [`gitlab-cookbooks` / `gitlab-sentry` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-sentry)

## GitLabでホストされるRunner

GitLabでホストされるRunnerを使用して、GitLab.comおよびGitLab DedicatedでCI/CDジョブを実行し、さまざまな環境でアプリケーションをシームレスにビルド、テスト、デプロイできます。

詳細については、[GitLabでホストされるRunner](../../ci/runners/_index.md)を参照してください。

## ホスト名リスト

ローカルHTTP（S）プロキシまたはエンドユーザーのコンピューターを管理するその他のWebブロックソフトウェアで許可リストを設定する際は、次のホスト名を追加してください。GitLab.comのPagesは、次のホスト名からコンテンツを読み込みます。

- `gitlab.com`
- `*.gitlab.com`
- `*.gitlab-static.net`
- `*.gitlab.io`
- `*.gitlab.net`

`docs.gitlab.com`および`about.gitlab.com`経由で提供されるドキュメントおよび企業ページも、一般的なパブリックCDNホスト名から特定のページコンテンツを直接読み込みます。

## インポート

GitLabへのデータのインポートに関する設定。

### デフォルトのインポートソース

デフォルトで使用できる[インポートソース](../project/import/_index.md#supported-import-sources)は、使用するGitLabによって異なります。

- GitLab.com: デフォルトでは、使用可能なすべてのインポートソースが有効になっています。
- GitLab Self-Managed: デフォルトでは、インポートソースは有効になっていないため、[有効にする](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)必要があります。

### インポートプレースホルダーユーザーの制限

GitLab.comでのインポート時に作成される[プレースホルダーユーザー](../project/import/_index.md#placeholder-users)の数は、トップレベルのネームスペースごとに制限されています。制限は、プランとシート数によって異なります。詳細については、[GitLab.comのプレースホルダーユーザー制限の表](../project/import/_index.md#placeholder-user-limits)を参照してください。

## IP範囲

GitLab.comは、Web/APIフリートからのトラフィックにIP範囲`34.74.90.64/28`および`34.74.226.0/24`を使用します。この範囲全体がGitLabにのみ割り当てられています。Webhookまたはリポジトリのミラーリングからの接続はこれらのIPから送信されることが予想されるため、許可してください。

GitLab.comはCloudflareによって保護されています。GitLab.comへの受信接続の場合、CloudflareのCIDRブロック（[IPv4](https://www.cloudflare.com/ips-v4/)および[IPv6](https://www.cloudflare.com/ips-v6/)）を許可する必要がある場合があります。

CI/CD Runnerからの発信接続については、静的IPアドレスを提供していません。ほとんどのGitLab.comインスタンスrunnerは、`us-east1`のGoogle Cloudにデプロイされますが、_Linux GPU対応_および_Linux Arm64_は`us-central1`でホストされます。IPベースのファイアウォールを設定するには、[GCPのIPアドレス範囲またはCIDRブロック](https://cloud.google.com/compute/docs/faq#find_ip_range)を調べてください。macOS Runnerは、`us-east-1`リージョンのAWSでホストされ、RunnerマネージャーはGoogle Cloudでホストされます。IPベースのファイアウォールを設定するには、[AWS IPアドレス範囲](https://docs.aws.amazon.com/vpc/latest/userguide/aws-ip-ranges.html)と[Google Cloud](https://cloud.google.com/compute/docs/faq#find_ip_range)の両方を許可する必要があります。

## GitLab.comのログ

ログの解析には[Fluentd](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#fluentd)を使用します。Fluentdはログを[Stackdriver Logging](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#stackdriver)と[Cloud Pub/Sub](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#cloud-pubsub)に送信します。Stackdriverは、ログをGoogle Cold Storage（GCS）に長期保存するために使用されます。Cloud Pub/Subは、[`pubsubbeat`](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#pubsubbeat-vms)を使用してログを[Elasticクラスター](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#elastic)に転送するために使用されます。

手順書では、次の詳細情報を確認できます。

- [ログに記録している内容の詳細なリスト](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#what-are-we-logging)
- [現在のログ保持ポリシー](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#retention)
- [ログインフラストラクチャの図](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#logging-infrastructure-overview)

### ジョブログ

デフォルトでは、GitLabはジョブログに有効期限を設定しません。ジョブログは無期限に保持され、期限切れになるようにGitLab.comで設定することはできません。[Jobs APIを使用して手動でジョブログを消去](../../api/jobs.md#erase-a-job)するか、[パイプラインを削除](../../ci/pipelines/_index.md#delete-a-pipeline)することができます。

## レビュアーと担当者の最大数

{{< history >}}

- GitLab 15.6で、担当者の最大数が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/368936)されました。
- GitLab 15.9で、レビュアーの最大数が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/366485)されました。

{{< /history >}}

マージリクエストでは、次の最大数が適用されます。

- 担当者の最大数: 200
- レビュアーの最大数: 200

## マージリクエストの制限

{{< history >}}

- GitLab 17.10で、`merge_requests_diffs_limit`という名前の[フラグとともに](../../administration/feature_flags.md)[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/521970)されました。デフォルトでは無効になっています。
- GitLab 17.10の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/521970)。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLabでは、各マージリクエストを1,000件の[差分バージョン](../project/merge_requests/versions.md)に制限しています。この制限に達したマージリクエストは、それ以上更新できません。代わりに、影響を受けたマージリクエストをクローズし、新しいマージリクエストを作成してください。

## パスワードの要件

GitLab.comでは、新規アカウントおよびパスワード変更時のパスワードについて、次の要件があります。

- 最小文字数8文字
- 最大文字数128文字
- すべての文字が使用可能（例: `~`、`!`、`@`、`#`、`$`、`%`、`^`、`&`、`*`、`()`、`[]`、`_`、`+`、`=`、`-`）

## プロジェクトとグループの削除

プロジェクトとグループの削除に関連する設定

### グループの遅延削除

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

2023年5月8日以降、デフォルトですべてのグループで遅延削除が有効になっています。

グループは7日間の遅延後、完全に削除されます。

Freeプランをご利用の場合、グループはすぐに削除され、復元できません。

[削除対象としてマークされたグループを表示および復元](../group/_index.md#restore-a-group)できます。

### プロジェクトの遅延削除

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

2023年5月8日以降、デフォルトですべてのグループでプロジェクトの遅延削除が有効になっています。

プロジェクトは7日間の遅延後、完全に削除されます。

Freeプランをご利用の場合、プロジェクトはすぐに削除され、復元できません。

[削除対象としてマークされたプロジェクトを表示および復元](../project/working_with_projects.md#restore-a-project)できます。

### 無効なプロジェクトの削除

GitLab.comで、[無効なプロジェクトの削除](../../administration/inactive_project_deletion.md)は無効になっています。

## パッケージレジストリの制限

[GitLabパッケージレジストリ](../packages/package_registry/_index.md)にアップロードされるパッケージの[最大ファイルサイズ](../../administration/instance_limits.md#file-size-limits)は、形式によって異なります。

| パッケージの種類           | GitLab.com                         |
|------------------------|------------------------------------|
| Conan                  | 5 GB                               |
| 汎用                | 5 GB                               |
| Helm                   | 5 MB                               |
| Maven                  | 5 GB                               |
| NPM                    | 5 GB                               |
| NuGet                  | 5 GB                               |
| PyPi                   | 5 GB                               |
| Terraform              | 1 GB                               |
| 機械学習モデル | 10 GB（アップロードは5 GBに制限） |

## Puma

GitLab.comでは、[Pumaリクエストタイムアウト](../../administration/operations/puma.md#change-the-worker-timeout)のデフォルトである60秒を使用しています。

## GitLab.comのレート制限

{{< alert type="note" >}}

管理者ドキュメントについては、「[レート制限](../../security/rate_limits.md)」を参照してください。

{{< /alert >}}

リクエストがレート制限されている場合、GitLab は`429`ステータスコードで応答します。クライアントは、リクエストを再度試行する前に待機する必要があります。また、「[レート制限の応答](#rate-limiting-responses)」で詳しく説明されているこの応答には、情報ヘッダーもあります。

次の表は、GitLab.comのレート制限について説明しています。

| レート制限                                                       | 設定                       |
|:-----------------------------------------------------------------|:------------------------------|
| IPアドレスの保護されたパス                                | 毎分10件のリクエスト        |
| プロジェクト、コミット、またはファイルパスのrawエンドポイントトラフィック         | 毎分300件のリクエスト       |
| IPアドレスからの認証されていないトラフィック                       | 毎分500件のリクエスト       |
| ユーザーの認証済みAPIトラフィック                             | 毎分2,000件のリクエスト     |
| ユーザーの認証済み非API HTTPトラフィック                    | 毎分1,000件のリクエスト     |
| IPアドレスからのすべてのトラフィック                                   | 毎分2,000件のリクエスト     |
| イシューの作成                                                   | 毎分200件のリクエスト       |
| イシューおよびマージリクエストに関するノートの作成                       | 毎分60件のリクエスト        |
| IPアドレスの高度な検索、プロジェクト検索、またはグループ検索のAPI         | 毎分10件のリクエスト        |
| IPアドレスのGitLab Pagesリクエスト                          | 50秒ごとに1,000件のリクエスト |
| GitLab PagesドメインのGitLab Pagesリクエスト                  | 10秒ごとに5,000件のリクエスト |
| IPアドレスのGitLab Pages TLS接続                   | 50秒ごとに1,000件のリクエスト |
| GitLab PagesドメインのGitLab Pages TLS接続           | 10秒ごとに400件のリクエスト   |
| プロジェクト、ユーザー、またはコミットのパイプライン作成リクエスト        | 毎分25件のリクエスト        |
| プロジェクトのアラートインテグレーションエンドポイントのリクエスト                | 1時間あたり3,600件のリクエスト       |
| GitLab Duo `aiAction`のリクエスト                                  | 8時間ごとに160件のリクエスト      |
| [プルミラーリング](../project/repository/mirror/pull.md)の間隔 | 5分                     |
| ユーザーから`/api/v4/users/:id`へのAPIリクエスト                  | 10分ごとに300件のリクエスト   |
| IPアドレスのGitLabパッケージクラウドのリクエスト（GitLab 16.11で[導入](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/24083)） | 毎分3,000件のリクエスト |
| GitLabリポジトリファイル | 毎分500件のリクエスト |
| ユーザーフォロワーのリクエスト（`/api/v4/users/:id/followers`）            | 毎分100件のリクエスト       |
| ユーザーのフォローリクエスト（`/api/v4/users/:id/following`）            | 毎分100件のリクエスト       |
| ユーザーステータスのリクエスト（`/api/v4/users/:user_id/status`）             | 毎分240件のリクエスト       |
| ユーザーSSH鍵のリクエスト（`/api/v4/users/:user_id/keys`）             | 毎分120件のリクエスト       |
| 単一SSH鍵のリクエスト（`/api/v4/users/:id/keys/:key_id`）         | 毎分120件のリクエスト       |
| ユーザーGPGキーリクエスト（`/api/v4/users/:id/gpg_keys`）              | 毎分120件のリクエスト       |
| 単一のGPGキーリクエスト（`/api/v4/users/:id/gpg_keys/:key_id`）     | 毎分120件のリクエスト       |
| ユーザープロジェクトリクエスト（`/api/v4/users/:user_id/projects`）         | 毎分300件のリクエスト       |
| ユーザーがコントリビュートしたプロジェクトのリクエスト（`/api/v4/users/:user_id/contributed_projects`） | 毎分100件のリクエスト |
| ユーザーのお気に入りプロジェクトのリクエスト（`/api/v4/users/:user_id/starred_projects`） | 毎分100件のリクエスト      |
| プロジェクトリストのリクエスト（`/api/v4/projects`）                        | 10分ごとに2,000件のリクエスト |
| グループプロジェクトのリクエスト（`/api/v4/groups/:id/projects`）            | 毎分600件のリクエスト       |
| 単一プロジェクトのリクエスト（`/api/v4/projects/:id`）                   | 毎分400件のリクエスト       |
| グループリストのリクエスト（`/api/v4/groups`）                            | 毎分200件のリクエスト       |
| 単一グループのリクエスト（`/api/v4/groups/:id`）                       | 毎分400件のリクエスト       |

[保護パス](#protected-paths-throttle)および[rawエンドポイント](../../administration/settings/rate_limits_on_raw_endpoints.md)のレート制限の詳細については、リンク先をご覧ください。

GitLabは、いくつかのレイヤーでリクエストのレート制限を行うことができます。ここにリストされているレート制限は、アプリケーションで設定されています。これらの制限は、各IPアドレスに対して最も制限の厳しいものです。GitLab.comのレート制限の詳細については、[ハンドブックのドキュメント](https://handbook.gitlab.com/handbook/engineering/infrastructure/rate-limiting)を参照してください。

### エクスポートファイルをアップロードすることによるグループとプロジェクトのインポート

不正利用を防ぐため、以下はレート制限されています。

- プロジェクトとグループのインポート
- ファイルを使用するグループおよびプロジェクトのエクスポート
- エクスポートのダウンロード

詳細については、以下を参照してください。

- [プロジェクトのインポート/エクスポートのレート制限](../project/settings/import_export.md#rate-limits)
- [グループのインポート/エクスポートのレート制限](../project/settings/import_export.md#rate-limits-1)

### IPブロック

IPブロックは、GitLab.comが単一のIPアドレスからシステムが潜在的に悪意のあるものと見なす異常なトラフィックを受信した場合に発生する可能性があります。これは、レート制限の設定に基づく可能性があります。異常なトラフィックが停止すると、次のセクションで説明するように、ブロックの種類に応じてIPアドレスが自動的に解放されます。

GitLab.comへのすべてのリクエストに対して`403 Forbidden`エラーが表示される場合は、ブロックをトリガーしている可能性のある自動プロセスがないか確認してください。サポートが必要な場合は、影響を受けているIPアドレスなどの詳細を添えて[GitLabサポート](https://support.gitlab.com)にお問い合わせください。

#### Gitおよびコンテナレジストリの認証失敗によるBAN

単一のIPアドレスから1分間に300件の認証失敗リクエストを受信した場合、GitLab.comは15分間HTTPステータスコード`403`を返します。

これは、Gitリクエストおよびコンテナレジストリ（`/jwt/auth`）リクエスト（結合）にのみ適用されます。

この制限は、次のようになります。

- 認証に成功したリクエストでリセットされます。たとえば、299件の認証失敗リクエストの後に1件の成功リクエストがあり、その後に299件の認証失敗リクエストが続いても、BANはトリガーされません。
- `gitlab-ci-token`で認証されたJWTリクエストには適用されません。

応答ヘッダーは提供されません。

`git`リクエストは`https`経由で常に最初に認証されていないリクエストを送信します。これにより、プライベートリポジトリでは`401`エラーが発生します。`git`は次に、ユーザー名、パスワード、またはアクセストークン（利用可能な場合）を使用して認証されたリクエストを試行します。これらのリクエストでは、同時にあまりに多くのリクエストが送信されると、一時的なIPブロックにつながる可能性があります。この問題を解決するには、[SSH鍵を使用してGitLabと通信します](../ssh.md)。

### 設定できない制限

設定できないレート制限で、GitLab.comでも使用されているレート制限については、「[設定できない制限](../../security/rate_limits.md#non-configurable-limits)」を参照してください。

### ページネーション応答ヘッダー

パフォーマンス上の理由から、クエリが10,000件を超えるレコードを返す場合、[GitLabは一部のヘッダーを除外](../../api/rest/_index.md#pagination-response-headers)します。

### 保護パスのスロットル

同じIPアドレスが1分間に10件を超えるPOSTリクエストを保護パスに送信すると、GitLab.comは`429` HTTPステータスコードを返します。

どのパスが保護されているかについては、以下のソースを参照してください。これには、ユーザーの作成、ユーザーの確認、ユーザーのサインイン、パスワードのリセットが含まれます。

[ユーザーとIPのレート制限](../../administration/settings/user_and_ip_rate_limits.md#response-headers)には、ブロックされたリクエストに応答するヘッダーのリストが含まれています。

詳細については、「[保護パス](../../administration/settings/protected_paths.md)」を参照してください。

### レート制限の応答

レート制限の応答については、以下を参照してください。

- [ブロックされたリクエストに対する応答のヘッダーリスト](../../administration/settings/user_and_ip_rate_limits.md#response-headers)
- [カスタマイズ可能な応答テキスト](../../administration/settings/user_and_ip_rate_limits.md#use-a-custom-rate-limit-response)

### SSHの最大接続数

GitLab.com は、[MaxStartups設定](https://man.openbsd.org/sshd_config.5#MaxStartups)を使用して、同時実行される認証されていないSSH接続の最大数を定義します。許可されている最大数を超える接続が同時に発生した場合、それらの接続はドロップされ、ユーザーに[`ssh_exchange_identification`エラー](../../topics/git/troubleshooting_git.md#ssh_exchange_identification-error)が表示されます。

### 表示レベル設定

プロジェクト、グループ、スニペットには、GitLab.comで[無効になっている](https://gitlab.com/gitlab-org/gitlab/-/issues/12388)[内部表示レベル](../public_access.md#internal-projects-and-groups)設定があります。

## Sidekiq

GitLab.comは、Rubyジョブのスケジュール設定のために、[Sidekiq](https://sidekiq.org)を[外部プロセス](../../administration/sidekiq/_index.md)として実行します。

現在の設定は、[GitLab.com Kubernetesポッド設定](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/gprd.yaml.gotmpl)にあります。

## SSH鍵と認証

SSHでの認証に関連する設定。最大接続数については、「[SSHの最大接続数](#ssh-maximum-number-of-connections)」を参照してください。

### 代替SSHポート

GitLab.comには、`git+ssh`に対して[別のSSHポート](https://about.gitlab.com/blog/2016/02/18/gitlab-dot-com-now-supports-an-alternate-git-plus-ssh-port/)を使用してアクセスできます。

| 設定    | 値               |
|------------|---------------------|
| `Hostname` | `altssh.gitlab.com` |
| `Port`     | `443`               |

次に、`~/.ssh/config`の例を示します。

```plaintext
Host gitlab.com
  Hostname altssh.gitlab.com
  User git
  Port 443
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/gitlab
```

### SSHホストキーのフィンガープリント

現在のインスタンス設定に移動して、GitLab.comのSSHホストキーのフィンガープリントを確認します。

1. GitLabにサインインします。
1. 左側のサイドバーで、**ヘルプ**（{{< icon name="question-o" >}}）>**ヘルプ**を選択します。
1. ヘルプページで、**現在のインスタンス設定を確認する**を選択します。

インスタンス設定では、**SSHホストキーのフィンガープリント**が表示されます。

| アルゴリズム        | MD5（非推奨） | SHA256  |
|------------------|------------------|---------|
| ECDSA            | `f1:d0:fb:46:73:7a:70:92:5a:ab:5d:ef:43:e2:1c:35` | `SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw` |
| ED25519          | `2e:65:6a:c8:cf:bf:b2:8b:9a:bd:6d:9f:11:5c:12:16` | `SHA256:eUXGGm1YGsMAS7vkcx6JOJdOGHPem5gQp4taiCfCLB8` |
| RSA              | `b6:03:0e:39:97:9e:d0:e7:24:ce:a3:77:3e:01:42:09` | `SHA256:ROQFvPThGrW4RuWLoL9tq9I9zJ42fK4XywyRtbOz/EQ` |

GitLab.comリポジトリに初めて接続するとき、これらのキーのいずれかが出力に表示されます。

### SSH鍵の制限

GitLab.comは、デフォルトの[SSH鍵制限](../../security/ssh_keys_restrictions.md)を使用します。

### SSH`known_hosts`エントリ

SSHで手動フィンガープリントの確認をスキップするには、以下を`.ssh/known_hosts`に追加します。

```plaintext
gitlab.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf
gitlab.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9
gitlab.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY=
```

## Webhook

次の制限が[Webhook](../project/integrations/webhooks.md)に適用されます。

### レート制限

トップレベルのネームスペースごとに、Webhookを呼び出すことができる1分あたりの回数は制限されます。この制限は、プランとサブスクリプションのシート数によって異なります。

| プラン              | GitLab.comのデフォルト  |
|----------------------|-------------------------|
| Free    | `500` |
| Premium | `99`シート以下: `1,600`<br>`100-399`シート: `2,800`<br>`400`シート以上: `4,000` |
| Ultimateとオープンソース |`999`シート以下: `6,000`<br>`1,000-4,999`シート: `9,000`<br>`5,000`シート以上: `13,000` |

### その他の制限

| 設定                                                             | GitLab.comのデフォルト |
|:--------------------------------------------------------------------|:-----------------------|
| Webhookの数                                                  | プロジェクトごとに100件、グループごとに50件（サブグループのWebhookは親グループの制限にはカウントされません） |
| 最大ペイロードサイズ                                                | 25 MB                  |
| タイムアウト                                                             | 10秒             |
| [Pagesの並列デプロイ](../project/pages/parallel_deployments.md#limits) | 100件の追加のデプロイ（Premiumプラン）、500件の追加のデプロイ（Ultimateプラン） |

GitLab Self-Managedインスタンスの制限については、以下を参照してください。

- [Webhookのレート制限](../../administration/instance_limits.md#webhook-rate-limit)
- [Webhookの数](../../administration/instance_limits.md#number-of-webhooks)
- [Webhookのタイムアウト](../../administration/instance_limits.md#webhook-timeout)
- [Pagesの並列デプロイ](../../administration/instance_limits.md#number-of-parallel-pages-deployments)
