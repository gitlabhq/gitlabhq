---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Dedicatedのスタートガイド
title: GitLab Dedicatedを管理する
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GitLab Dedicatedを使用して、AWSでホストされているフルマネージドのシングルテナントインスタンス上でGitLabを実行します。GitLabが基盤となるインフラストラクチャを管理する一方で、スイッチボード（GitLab Dedicated管理ポータル）を通じて、インスタンスの設定を制御できます。

このオファリングの詳細については、[サブスクリプションページ](../../subscriptions/gitlab_dedicated/_index.md)を参照してください。

## GitLabアーキテクチャの概要 {#architecture-overview}

GitLab Dedicatedは、以下を提供する安全なインフラストラクチャ上で実行されます:

- AWS内の完全に分離されたテナント環境
- 自動フェイルオーバーによる高可用性
- Geoベースのディザスターリカバリー
- 定期的なアップデートとメンテナンス
- エンタープライズグレードのセキュリティ制御

詳細については、[GitLab Dedicatedのアーキテクチャ](architecture.md)を参照してください。

## インフラストラクチャの設定 {#configure-infrastructure}

| 機能 | 説明 | 設定up with |
|------------|-------------|---------------------|
| [インスタンスのサイジング](create_instance/data_residency_high_availability.md#availability-and-scalability) | ユーザー数に基づいてインスタンスサイズを選択します。GitLabはインフラストラクチャをプロビジョニングし、維持します。 | オンボーディング |
| [AWSデータリージョン](create_instance/data_residency_high_availability.md#primary-regions) | プライマリ運用、ディザスターリカバリー、バックアップのリージョンを選択します。GitLabは、これらのリージョン全体でデータをレプリケートします。 | オンボーディング |
| [メンテナンス時間枠](maintenance.md#maintenance-windows) | 毎週4時間のメンテナンス時間を選択します。GitLabは、この時間中にアップデート、設定変更、およびセキュリティパッチを実行します。 | オンボーディング |
| [リリースマネージメント](releases.md#release-rollout-schedule) | GitLabは、新しい機能とセキュリティパッチで、インスタンスを毎月アップデートします。 | 利用可能 <br>がデフォルト |
| [ディザスターリカバリー](disaster_recovery.md) | オンボーディング中にセカンダリリージョンを選択します。GitLabは、Geoを使用して、選択したリージョンにレプリケートされたセカンダリサイトを維持します。 | オンボーディング |
| [自動バックアップ](disaster_recovery.md#automated-backups) | GitLabは、選択したAWSリージョンにデータをバックアップします。 | 利用可能 <br>がデフォルト |

## インスタンスを保護する {#secure-your-instance}

| 機能 | 説明 | 設定up with |
|------------|-------------|-----------------|
| [データ暗号化](encryption.md) | GitLabは、AWSが提供するインフラストラクチャを介して、保存時と転送時の両方でデータを暗号化します。 | 利用可能 <br>がデフォルト |
| [Bring your own key (BYOK)](encryption.md#bring-your-own-key-byok) | GitLabが管理するAWS KMSキーを使用する代わりに、独自のAWS KMSキーを暗号化に提供できます。GitLabは、これらのキーをインスタンスと統合して、保存時にデータを暗号化します。 | オンボーディング |
| [SAML SSO](configure_instance/saml.md) | SAMLアイデンティティプロバイダーへの接続を設定します。GitLabは、認証フローを処理します。 | スイッチボード |
| [IP許可リスト](configure_instance/network_security.md#ip-allowlist) | 承認済みのIPアドレスを指定します。GitLabは、不正なアクセス試行をブロックします。 | スイッチボード |
| [カスタム証明書](configure_instance/network_security.md#custom-certificate-authority) | SSL証明書をインポートします。GitLabは、プライベートサービスへの安全な接続を維持します。 | スイッチボード |
| [コンプライアンスフレームワーク](../../subscriptions/gitlab_dedicated/_index.md#monitoring) | GitLabは、SOC 2、ISO 27001、およびその他のフレームワークへのコンプライアンスを維持します。[トラストセンター](https://trust.gitlab.com/?product=gitlab-dedicated)からレポートにアクセスできます。 | 利用可能 <br>がデフォルト |
| [緊急アクセスプロトコル](../../subscriptions/gitlab_dedicated/_index.md#access-controls) | GitLabは、緊急事態のための制御されたブレイクグラス手順を提供します。 | 利用可能 <br>がデフォルト |

## ネットワーキングを設定する {#set-up-networking}

| 機能 | 説明 | 設定up with |
|------------|-------------|-----------------|
| [カスタムホスト名（BYOD）](configure_instance/network_security.md#bring-your-own-domain-byod) | ドメイン名を提供し、DNSレコードを設定します。GitLabは、Let's Encryptを介してSSL証明書を管理します。 | サポートチケット |
| [受信プライベートリンク](configure_instance/network_security.md#inbound-private-link) | 安全なAWS VPC接続をリクエストします。GitLabは、VPCにPrivateLinkエンドポイントを設定します。 | サポートチケット |
| [送信プライベートリンク](configure_instance/network_security.md#outbound-private-link) | AWSアカウントにエンドポイントサービスを作成します。GitLabは、サービスエンドポイントを使用して接続を確立します。 | スイッチボード |
| [プライベートホストゾーン](configure_instance/network_security.md#private-hosted-zones) | 内部DNS要件を定義します。GitLabは、インスタンスネットワークでDNS解決を設定します。 | スイッチボード |

## プラットフォームツールを使用する {#use-platform-tools}

| 機能 | 説明 | 設定up with |
|------------|-------------|-----------------|
| [GitLab Pages](../../subscriptions/gitlab_dedicated/_index.md#gitlab-pages) | GitLabは、専用ドメイン名で静的Webサイトをホストします。リポジトリからサイトを公開できます。 | 利用可能 <br>がデフォルト |
| [高度な検索](../../integration/advanced_search/elasticsearch.md) | GitLabは検索インフラストラクチャを維持します。コード、イシュー、およびマージリクエスト全体で検索できます。 | 利用可能 <br>がデフォルト |
| [ホストされたRunner（ベータ）](hosted_runners.md) | サブスクリプションを購入し、ホストされたRunnerを設定します。GitLabは、自動スケーリングCI/CDインフラストラクチャを管理します。 | スイッチボード |
| [ClickHouse](../../integration/clickhouse.md) | GitLabは、ClickHouseインフラストラクチャとインテグレーションを維持します。[GitLab DuoとSDLCトレンド](../../user/analytics/duo_and_sdlc_trends.md)や[CI分析](../../ci/runners/runner_fleet_dashboard.md#enable-more-ci-analytics-features-with-clickhouse)など、すべての高度な分析機能にアクセスできます。 | 利用可能 <br>デフォルト（[対象となるお客様](../../subscriptions/gitlab_dedicated/_index.md#clickhouse)） |

## 日々の運用を管理する {#manage-daily-operations}

| 機能 | 説明 | 設定up with |
|------------|-------------|-----------------|
| [アプリケーションログ](monitor.md) | GitLabは、ログをAWS S3バケットに配信します。これらのログを介してインスタンスアクティビティーを監視するためのアクセスをリクエストできます。 | サポートチケット |
| [メールサービス](configure_instance/users_notifications.md#smtp-email-service) | GitLabは、GitLab Dedicatedインスタンスからメールを送信するために、デフォルトでAWS SESを提供します。独自のSMTPメールサービスを設定することもできます。 | のサポートチケット <br/>カスタムサービス  |
| [スイッチボードへのアクセスと <br>通知](configure_instance/users_notifications.md) | スイッチボードの権限と通知設定を管理します。GitLabは、スイッチボードインフラストラクチャを維持します。 | スイッチボード |
| [スイッチボードSSO](configure_instance/authentication/_index.md#configure-switchboard-sso) | 組織のアイデンティティプロバイダーを設定し、必要な詳細をGitLabに提供します。GitLabは、スイッチボードのシングルサインオン（SSO）を設定します。 | サポートチケット |

## 始める {#get-started}

GitLab Dedicatedのスタートガイド:

1. [GitLab Dedicatedインスタンス](create_instance/_index.md)を作成します。
1. [GitLab Dedicatedインスタンス](configure_instance/_index.md)を構成します。
1. [ホストされたRunnerを作成](hosted_runners.md)します。
