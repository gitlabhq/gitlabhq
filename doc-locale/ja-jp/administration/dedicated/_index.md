---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Dedicatedのスタートガイド
title: GitLab Dedicatedを管理する
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

AWSでホストされているフルマネージドのシングルテナントインスタンスでGitLabを実行するには、GitLab Dedicatedを使用します。GitLabが基盤となるインフラストラクチャを管理する一方で、GitLab Dedicated管理ポータルであるスイッチボードを通じて、インスタンスの設定を制御します。

このサービスの詳細については、[サブスクリプションページ](../../subscriptions/gitlab_dedicated/_index.md)を参照してください。

## アーキテクチャの概要 {#architecture-overview}

GitLab Dedicatedは、以下の機能を提供するセキュアなインフラストラクチャ上で動作します:

- AWS内の完全に分離されたテナント環境
- 自動フェイルオーバーによる高可用性
- Geoベースのディザスターリカバリー
- 定期的な更新とメンテナンス
- エンタープライズグレードのセキュリティ制御

詳細については、[GitLab Dedicatedアーキテクチャ](architecture.md)を参照してください。

## インフラストラクチャの設定 {#configure-infrastructure}

| 機能 | 説明 | セットアップ方法 |
|------------|-------------|---------------------|
| [AWSリージョン](create_instance/data_residency_high_availability.md#region-selection) | プライマリ運用、ディザスターリカバリー、およびバックアップのリージョンを選択します。GitLabはこれらのリージョン間でデータをレプリケートします。 | オンボーディング |
| [メンテナンスウィンドウ](maintenance.md#maintenance-windows) | 週4時間のメンテナンスウィンドウを選択します。この期間中、GitLabは更新、設定変更、およびセキュリティパッチを実行します。 | オンボーディング |
| [リリースマネージメント](releases.md#release-rollout-schedule) | GitLabは、新機能とセキュリティパッチでインスタンスを毎月更新します。 | 利用可能 <br>デフォルト |
| [Geoディザスターリカバリー](disaster_recovery.md) | オンボーディング中にセカンダリリージョンを選択します。GitLabは、Geoを使用して、選択したリージョンにレプリケートされたセカンダリサイトを維持します。 | オンボーディング |
| [自動バックアップ](disaster_recovery.md#automated-backups) | GitLabは、選択したAWSリージョンにデータをバックアップします。 | 利用可能 <br>デフォルト |

## インスタンスを保護する {#secure-your-instance}

| 機能 | 説明 | セットアップ方法 |
|------------|-------------|-----------------|
| [データ暗号化](encryption.md) | GitLabは、AWSが提供するインフラストラクチャを介して、データを保存時と転送時の両方で暗号化します。 | 利用可能 <br>デフォルト |
| [顧客管理の暗号化キー](encryption.md#customer-managed-encryption) | GitLab管理のAWS KMSキーを使用する代わりに、独自のAWS KMSキーを暗号化のために提供できます。GitLabはこれらのキーをインスタンスと統合し、データを保存時に暗号化します。 | オンボーディング |
| [SAML SSO](configure_instance/authentication/saml.md) | SAMLIdentity Providerへの接続を設定します。GitLabが認証フローを処理します。 | スイッチボード |
| [IP許可リスト](configure_instance/network_security.md#ip-allowlist) | 承認されたIPアドレスを指定します。GitLabは不正なアクセス試行をブロックします。 | スイッチボード |
| [カスタム証明書](configure_instance/network_security.md#custom-certificate-authorities-for-external-services) | SSL証明書をインポートします。GitLabはプライベートサービスへのセキュアな接続を維持します。 | スイッチボード |
| [コンプライアンスフレームワーク](../../subscriptions/gitlab_dedicated/_index.md#monitoring) | GitLabは、SOC 2、ISO 27001、およびその他のフレームワークに準拠しています。[トラストセンター](https://trust.gitlab.com/?product=gitlab-dedicated)を通じてレポートにアクセスできます。 | 利用可能 <br>デフォルト |
| [緊急アクセスプロトコル](../../subscriptions/gitlab_dedicated/_index.md#access-controls) | GitLabは緊急事態のための制御されたブレークグラス手順を提供します。 | 利用可能 <br>デフォルト |

## ネットワーキングのセットアップ {#set-up-networking}

| 機能 | 説明 | セットアップ方法 |
|------------|-------------|-----------------|
| [カスタムドメイン](configure_instance/network_security.md#custom-domains) | ドメイン名を提供し、DNSレコードを設定します。GitLabはLet's Encryptを介してSSL証明書を管理します。 | サポートチケット |
| [受信プライベートリンク](configure_instance/network_security.md#inbound-private-link) | GitLabはエンドポイントサービスを作成します。GitLabインスタンスに接続するために、AWSアカウントでVPCエンドポイントを作成します。 | スイッチボード |
| [送信プライベートリンク](configure_instance/network_security.md#outbound-private-link) | AWSアカウントでエンドポイントサービスを作成します。GitLabはサービスに接続するためにVPCエンドポイントを作成します。 | スイッチボード |
| [プライベートホステッドゾーン](configure_instance/network_security.md#private-hosted-zones) | 内部DNS要件を定義します。GitLabは、インスタンスネットワーク内のDNS解決を設定します。 | スイッチボード |

## プラットフォームツールを使用する {#use-platform-tools}

| 機能 | 説明 | セットアップ方法 |
|------------|-------------|-----------------|
| [GitLab Pages](../../subscriptions/gitlab_dedicated/_index.md#gitlab-pages) | GitLabは、専用ドメインで静的ウェブサイトをホストします。リポジトリからサイトを公開できます。 | 利用可能 <br>デフォルト |
| [高度な検索](../../integration/advanced_search/elasticsearch.md) | GitLabは検索インフラストラクチャを維持します。codeコード、イシュー、およびマージリクエストを検索できます。 | 利用可能 <br>デフォルト |
| [ホスト型Runner（ベータ版）](hosted_runners.md) | サブスクリプションを購入し、ホスト型Runnerを設定します。GitLabは自動スケーリングCI/CDインフラストラクチャを管理します。 | スイッチボード |
| [ClickHouse](../../integration/clickhouse.md) | GitLabはClickHouseインフラストラクチャとインテグレーションを維持します。[GitLab DuoとSDLCのトレンド](../../user/analytics/duo_and_sdlc_trends.md)や[CI/CDアナリティクス](../../ci/runners/runner_fleet_dashboard.md)など、すべての高度な分析機能にアクセスできます。 | 利用可能 <br>[対象となる顧客](../../subscriptions/gitlab_dedicated/_index.md#clickhouse-cloud)向けのデフォルト |

## 日常業務を管理する {#manage-daily-operations}

| 機能 | 説明 | セットアップ方法 |
|------------|-------------|-----------------|
| [アプリケーションログ](monitor.md) | GitLabは、モニタリングとトラブルシューティングのために、ログをAWSのS3バケットに配信します。ログにアクセスできるユーザーとロールを管理します。 | スイッチボード |
| [メールサービス](configure_instance/users_notifications.md#smtp-email-service) | GitLabは、GitLab Dedicatedインスタンスからメールを送信するために、デフォルトでAWS SESを提供します。独自のSMTPメールサービスを設定することもできます。 | サポートチケット（提供元:  <br/>カスタムサービス）  |
| [スイッチボードアクセスと <br>通知](configure_instance/users_notifications.md) | スイッチボードのパーミッションと通知設定を管理します。GitLabはスイッチボードインフラストラクチャを維持します。 | スイッチボード |
| [スイッチボードSSO](configure_instance/authentication/_index.md#configure-switchboard-sso) | 組織のIdentity Providerを設定し、必要な詳細をGitLabに提供します。GitLabは、スイッチボードのSSO（SSO）を設定します。 | サポートチケット |

## 始める {#get-started}

GitLab Dedicatedの使用を開始するには:

1. [独自のGitLab Dedicatedインスタンスを作成する](create_instance/_index.md)。
1. [独自のGitLab Dedicatedインスタンスを設定する](configure_instance/_index.md)。
1. [ホスト型Runnerを作成する](hosted_runners.md)。
