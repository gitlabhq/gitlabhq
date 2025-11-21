---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 利用可能な機能とメリット
title: 政府機関向けGitLab Dedicated
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

政府機関向けGitLab Dedicatedは、完全に分離されたシングルテナントSaaSソリューションであり、以下の特徴があります:

- GitLab, Inc.がホストおよび管理します。
- 米国西部リージョンの[AWS GovCloud](https://docs.aws.amazon.com/govcloud-us/latest/UserGuide/whatis.html)にデプロイされます。

政府機関向けGitLab Dedicatedは、プラットフォーム管理のオーバーヘッドをなくし、運用効率性、リスクの軽減、組織のスピードと俊敏性を向上させます。政府機関向けGitLab Dedicatedの各インスタンスは、高可用性を備えたディザスターリカバリーを提供します。GitLabチームは、分離された各インスタンスのメンテナンスと運用を完全に管理し、お客様は最新の製品改善にアクセスしながら、最も複雑なコンプライアンス基準を満たすことができます。これは、GitLab Dedicatedと同じ技術スタック上に構築され、米国の政府機関での使用に適応されています。

FedRAMPコンプライアンスなどの政府標準を満たす必要のある政府機関および関連組織にとって、最適なソリューションです。

## 利用可能な機能 {#available-features}

### データレジデンシー {#data-residency}

政府機関向けGitLab DedicatedはAWS GovCloudで利用でき、米国のデータレジデンシー要件を満たしています。

### 高度な検索 {#advanced-search}

{{< details >}}

- ステータス: ベータ

{{< /details >}}

政府機関向けGitLab Dedicatedは、[高度な検索](../../user/search/advanced_search.md)を使用します。

### 可用性とスケーラビリティ {#availability-and-scalability}

政府機関向けGitLab Dedicatedは、高可用性が有効になっている、修正版の[クラウドネイティブハイブリッドリファレンスアーキテクチャ](../../administration/reference_architectures/_index.md#cloud-native-hybrid)を活用します。[オンボーディング](../../administration/dedicated/create_instance/_index.md#step-2-create-your-gitlab-dedicated-instance)の際、GitLabはお客様のユーザー数に基づいて、最も近いリファレンスアーキテクチャのサイズに適合させます。

{{< alert type="note" >}}

公開されている[リファレンスアーキテクチャ](../../administration/reference_architectures/_index.md)は、政府機関向けGitLab Dedicated環境内にデプロイされるクラウドリソースを定義する際の出発点として機能しますが、包括的なものではありません。GitLab Dedicatedは、環境のセキュリティと安定性を強化するために、標準のリファレンスアーキテクチャに含まれるもの以外にも、追加のクラウドプロバイダーサービスを活用します。したがって、政府機関向けGitLab Dedicatedのコストは、標準のリファレンスアーキテクチャのコストとは異なります。

{{< /alert >}}

#### ディザスターリカバリー {#disaster-recovery}

GitLab Dedicatedは、データベースやGitリポジトリを含む、すべてのデータストアを定期的にバックアップします。これらのバックアップはテストされ、安全に保管されます。冗長性を高めるために、別のクラウドリージョンにバックアップコピーを保存できます。

### セキュリティ {#security}

#### 認証と認可 {#authentication-and-authorization}

{{< details >}}

- ステータス: ベータ

{{< /details >}}

GitLab Dedicatedは、シングルサインオン（SSO）用に[SAML](../../administration/dedicated/configure_instance/saml.md)および[OpenID Connect（OIDC）](../../administration/dedicated/configure_instance/openid_connect.md)プロバイダーをサポートしています。

サポートされているプロバイダーを使用して、認証用のシングルサインオン（SSO）を設定できます。お客様のインスタンスはサービスプロバイダーとして機能し、お客様はGitLabがお客様のIDプロバイダー（IdPs）と通信するために必要な設定を提供します。

#### 暗号化 {#encryption}

データは、最新の暗号化標準を使用して、保存時および転送時に暗号化されます。

#### SMTP {#smtp}

{{< details >}}

- ステータス: ベータ

{{< /details >}}

GitLab Dedicatedから送信されるメールは、[Amazon Simple Email Service（Amazon SES）](https://aws.amazon.com/ses/)を使用します。Amazon SESへの接続は暗号化された状態です。

Amazon SESの代わりにSMTPサーバーを使用してアプリケーションメールを送信するには、[独自のメールサービスを設定する](../../administration/dedicated/configure_instance/users_notifications.md#smtp-email-service)ことができます。

#### 分離 {#isolation}

シングルテナントSaaSソリューションとして、政府機関向けGitLab Dedicatedは、GitLab環境のインフラストラクチャレベルの分離を提供します。お客様の環境は、他のテナントとは別のAWSアカウントに配置されます。このAWSアカウントには、GitLabアプリケーションをホストするために必要なすべての基盤となるインフラストラクチャが含まれており、お客様のデータはこのアカウントの境界内に留まります。お客様がアプリケーションを管理し、GitLabが基盤となるインフラストラクチャを管理します。テナント環境は、GitLab.comからも完全に分離されています。

#### アクセス制御 {#access-controls}

政府機関向けGitLab Dedicatedは、お客様の環境を保護するために、厳格なアクセス制御を実装しています:

- 必要な最小限の権限のみを付与する最小特権の原則に従います。
- テナントAWSアカウントを、トップレベルの政府機関向けGitLab DedicatedAWSの親組織の傘下に置きます。
- AWS組織へのアクセスを、選択されたGitLabチームメンバーに制限します。
- ユーザーアカウントに対する包括的なセキュリティポリシーとリクエストを実装します。
- 自動化されたアクションと緊急アクセスのために、単一のHubアカウントを使用します。
- HubアカウントでGitLab Dedicatedコントロールプレーンを使用して、テナントアカウントに対して自動化されたアクションを実行します。

GitLab Dedicatedのエンジニアは、お客様のテナント環境に直接アクセスできません。[緊急](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/team/-/blob/main/engineering/breaking_glass.md)の場合、テナント環境内のリソースへのアクセスが、重大度の高いイシューに対処するために必要な場合、GitLabのエンジニアは、それらのリソースを管理するためにHubアカウントを経由する必要があります。これは承認プロセスで行われ、許可が付与された後、エンジニアは一時的にIAMロールを引き受けて、Hubアカウントを介してテナントリソースにアクセスします。Hubアカウントとテナントアカウント内のすべてのアクションは、CloudTrailに記録されます。

テナントアカウント内では、GitLabはAWS GuardDutyからの侵入検知およびマルウェアスキャン機能を活用しています。インフラストラクチャログは、GitLab SecurityインシデントResponse Teamによって監視され、異常なイベントを検出します。

### メンテナンス {#maintenance}

GitLabは、お客様のインスタンスを最新の状態に保ち、セキュリティ上のイシューを修正し、環境全体の信頼性とパフォーマンスを確保するために、週1回のメンテナンス時間を利用します。

#### アップグレード {#upgrades}

GitLabは、お客様が希望する[メンテナンス時間](../../administration/dedicated/maintenance.md#maintenance-windows)中に最新のパッチリリースで、お客様のインスタンスを毎月アップグレードし、最新のGitLabリリースより1つ前のリリースを追跡します。たとえば、利用可能な最新バージョンのGitLabが16.8の場合、GitLab Dedicatedは16.7で実行されます。

#### 予定外のメンテナンス {#unscheduled-maintenance}

GitLabは、お客様のインスタンスのセキュリティ、可用性、または信頼性に影響を与える重大度の高いイシューに対処するために、[予定外のメンテナンス](../../administration/dedicated/maintenance.md#emergency-maintenance)を実施する場合があります。

### アプリケーション {#application}

政府機関向けGitLab Dedicatedには、以下に示す[サポートされていない機能](#unavailable-features)を除き、GitLab自己管理型[Ultimate機能セット](https://about.gitlab.com/pricing/feature-comparison/)が付属しています。

## 利用できない機能 {#unavailable-features}

### アプリケーション機能 {#application-features}

次のGitLabアプリケーション機能は利用できません:

- LDAP、スマートカード、またはKerberos認証
- 複数のログインプロバイダー
- FortiAuthenticator、またはFortiToken 2FA
- メールで返信する
- サービスデスク
- 一部のGitLab Duo AI機能
  - サポートされているAI機能を確認するには、[AI機能の一覧](../../user/gitlab_duo/_index.md)をご覧ください。
  - 詳細については、[カテゴリの方向性-GitLab Dedicated](https://about.gitlab.com/direction/gitlab_dedicated/#supporting-ai-features-on-gitlab-dedicated)をご覧ください。
- GitLabユーザーインターフェースの外部で設定する必要がある[利用可能な機能](#available-features)以外の機能
- `off`がデフォルトで切り替えられている機能フラグの背後にある機能または機能。

以下の機能はサポートされません:

- Mattermost
- [サーバー側のGitフック](../../administration/server_hooks.md)。政府機関向けGitLab Dedicatedは、SaaSサービスであり、基盤となるインフラストラクチャへのアクセスはGitLab, Inc.のチームメンバーのみが利用できます。サーバー側の設定の性質上、Dedicatedサービスで任意のコードを実行することによるセキュリティ上の懸念や、サービスのSLAに影響を与える可能性があります。代わりに、代替の[プッシュルール](../../user/project/repository/push_rules.md)または[Webhook](../../user/project/integrations/webhooks.md)を使用してください。

### 運用機能 {#operational-features}

以下の運用機能は利用できません:

- Geo
- セルフサービスによる購入と設定
- 複数のログインプロバイダー
- GCPやAzureなど、AWS以外のクラウドプロバイダーへのデプロイのサポート
- スイッチボード
- プレ本番環境インスタンス

### 機能フラグ {#feature-flags}

GitLabは、新しい機能や試験的な機能の開発とロールアウトをサポートするために、[機能フラグ](../../administration/feature_flags/_index.md)を使用します。政府機関向けGitLab Dedicated:

- 機能フラグの背後にある、**既定で有効**になっている機能が利用可能です。
- 機能フラグの背後にある、**既定で無効**になっている機能は利用できず、管理者が有効にすることもできません。

デフォルトで無効になっている機能フラグの背後にある機能は、本番環境での使用準備ができていないため、政府機関向けGitLab Dedicatedには安全ではありません。

機能が一般的に利用可能になり、フラグが有効になるか削除されると、同じGitLabバージョンの政府機関向けGitLab Dedicatedでその機能が利用可能になります。

## サービスレベル契約 {#service-level-agreement}

次のサービスレベル契約（SLA）の目標は、政府機関向けGitLab Dedicated向けに定義されています:

- 目標リカバリー時点（RPO）の目標値: 4時間。
- 目標リカバリー時間（RTO）の目標値: RTOの目標はありません。サービスは、可能な範囲で復元するされます。
- サービスレベル目標（SLO）の目標: SLOの目標はありません。

## お問い合わせ {#contact-sales}

政府機関向けGitLab Dedicatedの詳細については、[営業にお問い合わせ](https://about.gitlab.com/dedicated/)いただき、専門家にご相談ください。
