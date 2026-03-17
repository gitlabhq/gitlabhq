---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 政府機関や規制対象業界向けのシングルテナントSaaSソリューション。
title: 政府機関向けGitLab Dedicated
---

{{< details >}}

- プラン: Ultimate
- 提供形態: 政府機関向けGitLab Dedicated

{{< /details >}}

政府機関向けGitLab Dedicatedは、政府機関や規制対象業界の組織向けに設計されたシングルテナントSaaSソリューションです。

以下を提供します:

- [FedRAMP Moderate認定済み](https://marketplace.fedramp.gov/products/FR2411959145?cache=true)（Authority to Operate（ATO）取得済み）
- 専用のAWSアカウント内の隔離されたインフラストラクチャは、US-Westリージョンの[AWS GovCloud](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/whatis.html)にデプロイされています。
- GitLabは、政府に特化したチームとプロセスによって、すべての運用とコンプライアンス要件を管理します。
- DevSecOpsプラットフォームの全機能へのアクセスを可能にし、FedRAMPコンプライアンスを維持します。

このサービスは、コンプライアンスインフラストラクチャ管理の複雑さを解消し、チームが開発に集中できるようにします。

## セキュリティアーキテクチャ {#security-architecture}

あなたのインスタンスには、以下のセキュリティ管理機能が含まれています:

- 連邦要件に沿った継続的なモニタリングを備えたFedRAMP Moderateコンプライアンス
- 米国西部地域のAWS GovCloudインフラストラクチャを通じて保証されるデータ主権
- 他のすべてのテナントから分離された、専用のAWSアカウント内の隔離されたインフラストラクチャ
- FIPS要件を満たす暗号化標準（データ保存時および転送時）
- 最小特権の原則に従ったアクセス制御と包括的な監査証跡

### データレジデンシーとインフラストラクチャの分離 {#data-residency-and-infrastructure-isolation}

米国のデータレジデンシー要件を満たすため、あなたのインスタンスはUS-Westリージョンの[AWS GovCloud](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/whatis.html)にデプロイされています。

リポジトリ、データベース、アーティファクト、バックアップを含むすべての顧客データは、AWS GovCloudの境界内に保持されます。あなたの環境には、GitLabアプリケーションをホストするために必要なすべてのインフラストラクチャが含まれており、GitLab.comから完全に分離されています。

データは保存時と転送時にFIPS準拠の暗号化標準を使用して暗号化された状態で保護されます。

### アクセス制御 {#access-controls}

あなたの環境は、複数のセキュリティレイヤーで保護されています:

- エンジニアはテナント環境に直接アクセスできず、それぞれの役割に必要な最小限の権限で操作します。
- インフラストラクチャは、セキュリティ上の脅威や異常がないか、24時間365日監視されます。
- すべてのアクセスと変更は、GitLabセキュリティインシデント対応チームによって記録およびレビューされます。
- アクセスリクエストは、政府のコンプライアンス要件に合わせた正式なセキュリティポリシーと承認ワークフローに従います。

## 利用可能な機能 {#available-features}

政府機関向けGitLab Dedicatedは、[利用できない機能](#unavailable-features)を除き、完全なUltimateの機能セットを提供します。

これらの機能は、FedRAMPコンプライアンスおよび政府のセキュリティフレームワーク内で機能するように設計されています。

### 可用性とスケーラビリティ {#availability-and-scalability}

あなたのインスタンスは、[クラウドネイティブハイブリッドリファレンスアーキテクチャ](../../administration/reference_architectures/_index.md#cloud-native-hybrid)の修正バージョンとHAを有効にして利用しています。

[オンボーディング](../../administration/dedicated/create_instance/_index.md#create-your-instance)時に、GitLabはユーザー数に基づいて最適なリファレンスアーキテクチャサイズを提示します。

> [!note]
> 公開されている[リファレンスアーキテクチャ](../../administration/reference_architectures/_index.md)は基盤として機能します。政府機関向けGitLab Dedicatedは、強化されたセキュリティとコンプライアンスのために、これらを追加のAWSサービスで拡張しています。これは、標準のリファレンスアーキテクチャの見積もりとはコストが異なることを意味します。

### ディザスターリカバリー {#disaster-recovery}

GitLabは、データベースやGitリポジトリを含むすべてのデータストアのバックアップを取ります。これらのバックアップはテストされ、追加の冗長性のためにデフォルトで別のクラウドリージョンに安全に保存されます。

### 認証と認可 {#authentication-and-authorization}

SSO（SSO）は以下を使用して設定できます:

- [SAML](../../administration/dedicated/configure_instance/authentication/saml.md)
- [OpenID Connect（OIDC）](../../administration/dedicated/configure_instance/authentication/openid_connect.md)

あなたのインスタンスはサービスプロバイダーとして機能し、GitLabがあなたのIdentity Provider（IdP）と通信するための必要な設定を提供します。

あなたのインスタンスに複数のIdentity Providerを設定できます。

### メール配信 {#email-delivery}

メールは[Amazon Simple Email Service（Amazon SES）](https://aws.amazon.com/ses/)を使用して送信されます。Amazon SESへの接続は暗号化された状態です。

Amazon SESの代わりにSMTPサーバーを使用してアプリケーションメールを送信するには、独自の[メールサービスを構成する](../../administration/dedicated/configure_instance/users_notifications.md#smtp-email-service)ことができます。

### 高度な検索 {#advanced-search}

[高度な検索](../../user/search/advanced_search.md)機能が含まれています。GitLabインスタンス全体で、codeコード、作業アイテム、マージリクエストなどを検索できます。

## 利用できない機能 {#unavailable-features}

FedRAMP認証を維持し、政府のセキュリティ要件を満たすため、一部のGitLab機能は政府機関向けGitLab Dedicatedでは利用できません。

### 認証、セキュリティ、およびネットワーキング {#authentication-security-and-networking}

| 機能                              | 代替 |
| ------------------------------------ | ----------- |
| LDAPまたはKerberos認証      | SAMLまたはOIDCをIdentity Providerとともに使用します |
| FortiAuthenticatorまたはFortiToken 2要素認証 | Identity Provider MFAを使用します |

### コミュニケーションとコラボレーション {#communication-and-collaboration}

| 機能        | 代替 |
| -------------- | ----------- |
| メールによる返信 | Webインターフェースを使用します |
| サービスデスク   | イシュートラッキングを使用します |
| Mattermost     | 外部チャットツールを使用します |

### 開発とAI機能 {#development-and-ai-features}

| 機能                                                            | 代替 |
| ------------------------------------------------------------------ | ----------- |
| 一部の[GitLab Duo AI機能](../../user/gitlab_duo/_index.md) | [サポートされているAI機能](../../user/gitlab_duo/_index.md)を参照してください |
| サーバーサイドGit [フック](../../administration/server_hooks.md)      | [プッシュルール](../../user/project/repository/push_rules.md)または[Webhook](../../user/project/integrations/webhooks.md)を使用します |
| GitLabユーザーインターフェース外で設定された機能           | サポートに連絡 |

### 運用機能 {#operational-features}

以下の運用機能は利用できません:

- Geo
- セルフサービスでの購入と設定
- GCPやAzureなどの非AWSクラウドプロバイダーへのデプロイのサポート
- プレ本番環境

### 機能フラグ {#feature-flags}

FFは、あなたのインスタンスで利用可能な機能を制御します:

- デフォルトで有効になっているFFを持つ機能のみが利用可能です
- デフォルトで無効になっているFFを持つ機能は利用できません
- FFを修正することはできません

## サービス運用 {#service-operations}

GitLabは、政府固有の運用プロセスを使用して、あなたのインスタンスのすべての保守、モニタリング、およびサポートを管理します。これらのプロセスは、すべての保守およびサポート活動において、コンプライアンス、セキュリティ、および安定性を優先します。

### メンテナンス {#maintenance}

あなたのインスタンスは定期的なメンテナンスを受けます:

- 希望する週次期間中に、最新のパッチリリースによる月次アップグレード
- 重要なセキュリティイシューに対する緊急メンテナンス

### リリースとバージョン {#releases-and-versions}

あなたのインスタンスは、最新のGitLabバージョンより1つ前のリリースを実行します。たとえば、最新のバージョンが16.8の場合、あなたのインスタンスは16.7を実行します。

このアプローチにより、緊急メンテナンスを通じて重要なセキュリティパッチを受け取りながら、安定性が提供されます。機能は、コンプライアンスおよび変更レビュープロセス後に展開されます。

### SLA {#service-level-agreement}

あなたのインスタンスは、月間稼働率99.9%のSLA（SLA）を維持します。GitLabは、このSLAコミットメントの提供をサポートするために、内部のサービスレベル目標（SLO）を使用します。

以下の目標が適用されます:

- 目標リカバリー時点（RPO）目標: ディザスターリカバリーシナリオにおける最大4時間のデータ損失期間
- 目標リカバリー時間（RTO）目標: サービス復旧は、インシデントの重大度と影響によって優先順位が付けられます

GitLabは、データの整合性とセキュリティを確保しながら、可能な限り迅速にサービスを復元するよう努めます。

## 営業へのお問い合わせ {#contact-sales}

開始する準備はできていますか？要件について話し合い、組織のコンプライアンスとセキュリティのニーズをサポートする方法について知るには、[弊社の営業チームにお問い合わせください](https://about.gitlab.com/sales/dedicated/)。
