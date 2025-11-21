---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: シングルテナントSaaSソリューションで利用可能な機能と利点をご覧ください。
title: GitLab Dedicated
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GitLab Dedicatedは、以下のようなシングルテナントSaaSソリューションです:

- 完全に分離されています。
- ご希望のAWSクラウドリージョンにデプロイされます。
- GitLabによってホストおよびメンテナンスされます。

各インスタンスには以下が用意されています:

- ディザスターリカバリーを備えた[高可用性](../../administration/dedicated/create_instance/data_residency_high_availability.md)
- 最新機能を備えた[定期的な更新](../../administration/dedicated/maintenance.md)
- エンタープライズレベルのセキュリティ対策。

GitLab Dedicatedを使用すると、次のことが可能になります:

- 運用効率性の向上。
- インフラストラクチャ管理のオーバーヘッドを削減。
- 組織の俊敏性を向上させます。
- 厳格なコンプライアンス要件を満たします。

## 利用可能な機能 {#available-features}

このセクションでは、GitLab Dedicatedで利用できる主要な機能を紹介します。

### セキュリティ {#security}

GitLab Dedicatedには、データを保護し、インスタンスへのアクセスを制御するための、以下のセキュリティ機能が備わっています。

#### 認証と認可 {#authentication-and-authorization}

GitLab Dedicatedは、シングルサインオン（SSO）用に[SAML](../../administration/dedicated/configure_instance/saml.md)および[OpenID Connect（OIDC）](../../administration/dedicated/configure_instance/openid_connect.md)プロバイダーをサポートしています。

サポートされているプロバイダーを使用して、認証用のシングルサインオン（SSO）を設定できます。お客様のインスタンスはサービスプロバイダーとして機能し、お客様はGitLabがお客様のIDプロバイダー（IdPs）と通信するために必要な設定を提供します。

#### セキュアなネットワーキング {#secure-networking}

以下の2つの接続オプションがあります:

- IP許可リストによるパブリック接続: デフォルトでは、インスタンスはパブリックにアクセス可能です。指定されたIP許可リストへのアクセスを制限するために、[IP許可リストを構成](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist)できます。
- AWS PrivateLinkによるプライベート接続: [AWS PrivateLink](https://aws.amazon.com/privatelink/)を[受信](../../administration/dedicated/configure_instance/network_security.md#inbound-private-link)および[送信](../../administration/dedicated/configure_instance/network_security.md#outbound-private-link)接続用に構成できます。

パブリックでない証明書を使用した内部リソースへのプライベート接続の場合は、[信頼できる証明書を指定](../../administration/dedicated/configure_instance/network_security.md#custom-certificate-authority)することもできます。

##### Webhookとインテグレーションのためのプライベート接続 {#private-connectivity-for-webhooks-and-integrations}

Webhookとインテグレーションがパブリックインターネットからアクセスできないサービスに接続する必要がある場合は、AWS PrivateLinkをプライベート接続に使用できます。GitLab DedicatedはSaaSサービスであるため、ネットワーク内のローカルIP許可リストアドレスに直接接続することはできません。

内部サービスのプライベート接続を設定するには:

1. 内部サービスにホスト名を割り当てます。
1. 送信プライベートリンクを介してこれらのホスト名にルーティングするように、プライベートホストゾーン（PHZ）レコードを構成します。
1. 送信プライベートリンクの10エンドポイント制限を計画します。

10個を超えるエンドポイントに接続する必要がある場合は、インフラストラクチャにリバースプロキシまたはTLSパススルーを実装します。このアプローチでは、複数のサービスをより少ないプライベートリンク接続でルーティングします。

#### データの暗号化 {#data-encryption}

データは、最新の暗号化標準を使用して、保存時および転送時に暗号化されます。

オプションで、保存時のデータに独自のAWS Key Management Service（AWS KMS）暗号化キーを使用できます。このオプションを使用すると、GitLabに保存するデータを完全に制御できます。

詳細については、[保存時の暗号化されたデータ（BYOK）](../../administration/dedicated/encryption.md#encrypted-data-at-rest)を参照してください。

#### メールサービス {#email-service}

デフォルトでは、[Amazon SimpleメールService（Amazon SES）](https://aws.amazon.com/ses/)は、メールを安全に送信するために使用されます。代替として、SMTPを使用して[独自のメールサービスを構成](../../administration/dedicated/configure_instance/users_notifications.md#smtp-email-service)できます。

#### ウェブアプリケーションファイアウォール {#web-application-firewall}

{{< details >}}

- ステータス: 利用制限

{{< /details >}}

Cloudflareは、分散型サービス拒否（DDoS）保護および関連するセキュリティ機能のためのWebアプリケーションファイアウォール（WAF）として実装されています。WAFの実装と構成は、GitLab SREチームによって管理されます。WAFの構成またはログへの直接アクセスはできません。

### コンプライアンス {#compliance}

GitLab Dedicatedは、データのセキュリティと信頼性を確保するために、さまざまな規制、認証、コンプライアンスフレームワークを遵守しています。

#### コンプライアンスと認証の詳細を表示 {#view-compliance-and-certification-details}

コンプライアンスと認証の詳細を表示し、[GitLab Dedicatedトラストセンター](https://trust.gitlab.com/?product=gitlab-dedicated)からコンプライアンスアーティファクトをダウンロードできます。

#### アクセス制御 {#access-controls}

GitLab Dedicatedは、環境を保護するために厳格なアクセス制御を実装しています:

- 必要な最小限の権限のみを付与する最小特権の原則に従います。
- AWS組織へのアクセスを、選択されたGitLabチームメンバーに制限します。
- ユーザーアカウントに対する包括的なセキュリティポリシーとリクエストを実装します。
- 自動化されたアクションと緊急アクセスのために、単一のHubアカウントを使用します。
- GitLab Dedicatedのエンジニアは、顧客環境に直接アクセスできません。

[緊急時](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/incident-management/-/blob/main/procedures/break-glass.md#break-glass-procedure)、GitLabエンジニアは次のことを行う必要があります:

1. Hubアカウントを使用して顧客リソースにアクセスします。
1. 承認プロセスを通じてアクセスをリクエストします。
1. Hubアカウントを介して一時的なIAMロールを引き受けます。

Hubアカウントとテナントアカウントのすべてのアクションは、CloudTrailにログ記録されます。

#### モニタリング {#monitoring}

テナントアカウントでは、GitLab Dedicatedは以下を使用します:

- 侵入検出およびマルウェアスキャン用のAWS GuardDuty。
- 異常なイベントを検出するためのGitLabセキュリティインシデント対応チームによるインフラストラクチャログのモニタリング。

#### 監査と可観測性 {#audit-and-observability}

監査と可観測性のために、[アプリケーションログ](../../administration/dedicated/monitor.md)にアクセスできます。これらのログは、システムのアクティビティーとユーザーアクションに関するインサイトを提供し、インスタンスのモニタリングとコンプライアンス要件の維持に役立ちます。

### 独自のドメインの使用 {#bring-your-own-domain}

デフォルトの`tenant_name.gitlab-dedicated.com` URLの代わりに、独自のカスタムドメインを使用してGitLab Dedicatedインスタンスにアクセスできます。たとえば、`gitlab.company.com`を使用してインスタンスにアクセスできます。

カスタムドメインは、次のような場合に使用します:

- URLを変更せずに、既存のSelf-Managedインスタンスから移行する。
- 組織のツール全体で一貫したブランドを維持します。
- 既存の証明書管理またはドメインポリシーと統合します。

Kubernetes用メインGitLabインスタンス、バンドルされたコンテナレジストリ、およびKubernetes向けGitLabエージェントサーバーにカスタムドメインを構成できます。

詳細については、[独自のドメインの使用（BYOD）](../../administration/dedicated/configure_instance/network_security.md#bring-your-own-domain-byod)を参照してください。

{{< alert type="note" >}}

GitLab Pagesは、カスタムドメインをサポートしていません。GitLab Dedicatedインスタンスに構成されているカスタムドメインに関係なく、`tenant_name.gitlab-dedicated.site`でのみGitLab Pagesサイトにアクセスできます。

{{< /alert >}}

### オブジェクトストレージのダウンロード {#object-storage-downloads}

デフォルトでは、GitLab Dedicatedは、最適なパフォーマンスを得るために、S3からの直接ダウンロードを有効にします（`proxy_download = false`）。直接ダウンロードをサポートするオブジェクトタイプは次のとおりです:

- [CI/CDジョブアーティファクト](../../administration/cicd/job_artifacts.md)
- [依存プロキシファイル](../../administration/packages/dependency_proxy.md)
- [マージリクエストの差分](../../administration/merge_request_diffs.md)
- [Git Large File Storage (LFS)オブジェクト](../../administration/lfs/_index.md)
- [プロジェクトパッケージ（例: PyPI、Maven、NuGet）](../../administration/packages/_index.md)
- [コンテナレジストリコンテナ](../../administration/packages/container_registry.md)
- [ユーザーアップロード](../../administration/uploads.md)

上記のオブジェクトタイプのいずれかをダウンロードすると、ブラウザまたはクライアントは、GitLabインフラストラクチャを経由するのではなく、Amazon S3に直接接続します。

ネットワークセキュリティポリシーでS3エンドポイントへの直接アクセスが禁止されている場合は、GitLabインフラストラクチャを介してプロキシされたダウンロードをリクエストできます。この構成（`proxy_download = true`）により、すべてのダウンロードがGitLab Dedicatedインスタンスを経由してルーティングされるようになります。

#### プロキシされたダウンロードをリクエスト {#request-proxied-downloads}

プロキシされたダウンロードをリクエストするには:

1. ユースケースの詳細を添えて、アカウントエグゼクティブに連絡してください。
1. ネットワークセキュリティ要件に関する情報を記載してください。
1. プロキシアクセスが必要なオブジェクトタイプを指定します。

{{< alert type="note" >}}

プロキシされたダウンロードは、直接S3アクセスと比較してパフォーマンスに影響を与えます。

{{< /alert >}}

詳細については、[プロキシダウンロード](../../administration/object_storage.md#proxy-download)を参照してください。

### アプリケーション {#application}

GitLab Dedicatedには、例外が少数あるSelf-Managedインスタンスの[Ultimate機能セット](https://about.gitlab.com/pricing/feature-comparison/)が付属しています。詳細については、[利用できない機能](#unavailable-features)を参照してください。

#### 高度な検索 {#advanced-search}

GitLab Dedicatedは、[高度な検索機能](../../integration/advanced_search/elasticsearch.md)を使用します。

#### ClickHouse {#clickhouse}

ClickHouseインテグレーションを介して、[高度な分析機能](../../integration/clickhouse.md)にアクセスできます。これは、対象となる顧客に対してデフォルトで有効になっています。次の場合は対象となります:

- GitLab Dedicatedテナントが商用AWSリージョンにデプロイされている。政府機関向けGitLab Dedicatedはサポートされていません。
- テナントのプライマリリージョンがClickHouse Cloudでサポートされている。サポートされているリージョンのリストについては、[ClickHouse Cloudでサポートされているリージョン](https://clickhouse.com/docs/cloud/reference/supported-regions#aws-regions)を参照してください。

ClickHouseは、GitLab Dedicatedインスタンスのセカンダリデータストアとして機能し、高度な分析機能を有効にします。

GitLab Dedicatedインスタンスには、テナントのプライマリリージョンにデプロイされたClickHouse Cloudデータベースが含まれています。データベースはパブリックにアクセスできず、AWS PrivateLinkを介して接続します。データは、クラウドプロバイダー管理のAES 256キーと透過的なデータ暗号化を使用して、転送時および保存時に暗号化されます。GitLab Dedicatedインスタンスを構成して[送信リクエストをフィルタリング](../../security/webhooks.md#allow-outbound-requests-to-certain-ip-addresses-and-domains)すると、ClickHouseエンドポイントアドレスが自動的に許可リストに追加されます。

GitLab DedicatedのClickHouseには、次の制限があります:

- [独自のキー（BYOK）の使用](../../administration/dedicated/encryption.md#bring-your-own-key-byok)はサポートされていません。
- SLAは適用されません。目標リカバリー時間（RTO）と目標リカバリー時点（RPO）は、ベストエフォートです。

#### GitLab Pages {#gitlab-pages}

GitLab Dedicatedで[GitLab Pages](../../user/project/pages/_index.md)を使用して、静的Webサイトをホストできます。GitLab Pagesはデフォルトで有効になっています。

Webサイトはドメイン`tenant_name.gitlab-dedicated.site`を使用します。`tenant_name`はインスタンスのURLと一致します。

{{< alert type="note" >}}

カスタムドメインはサポートされていません。`gitlab.my-company.com`のようなカスタムドメインを追加しても、`tenant_name.gitlab-dedicated.site`でWebサイトにアクセスできます。

{{< /alert >}}

以下を使用して、Webサイトへのアクセスを制御します:

- [GitLab Pagesアクセス制御](../../user/project/pages/pages_access_control.md)
- [IP許可リスト](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist)

既存のIP許可リストがGitLab PagesWebサイトに適用されます。

ディザスターリカバリー中にフェイルオーバーが発生した場合、サイトはセカンダリリージョンから引き続き動作します。

#### ホストされるRunner {#hosted-runners}

[GitLab Dedicated用ホストランナー](../../administration/dedicated/hosted_runners.md)を使用すると、メンテナンスのオーバーヘッドなしでCI/CDワークロードをスケールできます。

#### Self-Managed Runner {#self-managed-runners}

ホストランナーを使用する代わりに、GitLab Dedicatedインスタンスに独自のランナーを使用できます。

セルフマネージドランナーを使用するには、所有または管理するインフラストラクチャに[GitLab Runner](https://docs.gitlab.com/runner/install/)をインストールします。

#### OpenID ConnectとSCIM {#openid-connect-and-scim}

インスタンスへのIP許可リスト制限を維持しながら、[ユーザー管理にSCIMを使用](../../api/scim.md)したり、[OpenID ConnectIDプロバイダーとしてのGitLab](../../integration/openid_connect_provider.md)を使用したりできます。

IP許可リストでこれらの機能を使用するには:

- [IP許可リストのSCIMプロビジョニングを有効にする](../../administration/dedicated/configure_instance/network_security.md#enable-scim-provisioning-for-your-ip-allowlist)
- [IP許可リストのOpenID Connectを有効にする](../../administration/dedicated/configure_instance/network_security.md#enable-openid-connect-for-your-ip-allowlist)

### プレ本番環境 {#pre-production-environments}

GitLab Dedicatedは、本番環境の設定に一致するプレ本番環境をサポートしています。プレ本番環境を使用して、次のことができます:

- 本番環境に実装する前に、新機能をテストします。
- 本番環境に適用する前に、設定の変更をテストします。

プレ本番環境は、追加のライセンスを必要とせずに、GitLab Dedicatedサブスクリプションのアドオンとして購入する必要があります。

次の機能を使用できます:

- 柔軟なサイジング: 本番環境のサイズに一致させるか、より小さいリファレンスアーキテクチャを使用します。
- バージョンの一貫性: 本番環境と同じGitLabのバージョンを実行します。

制限事項:

- シングルリージョンデプロイのみ。
- SLAのコミットメントはありません。
- 本番環境よりも新しいバージョンを実行できません。

## 利用できない機能 {#unavailable-features}

このセクションでは、GitLab Dedicatedで使用できない機能を示します。

### 認証、セキュリティ、およびネットワーキング {#authentication-security-and-networking}

| 機能                                       | 説明                                                           | 影響                                                       |
| --------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------ |
| LDAP認証                           | 企業のLDAP/Active Directory認証情報を使用した認証。     | GitLab固有のパスワードまたはアクセストークンを代わりに使用する必要があります。 |
| スマートカード認証                     | セキュリティが強化されたスマートカードを使用した認証。               | 既存のスマートカードインフラストラクチャは使用できません。               |
| Kerberos認証                       | Kerberosプロトコルを使用したシングルサインオン認証。                | GitLabに対して個別に認証する必要があります。                      |
| 複数のログインプロバイダー                      | 複数のOAuth/SAMLプロバイダー（Google、GitHub）の構成。      | 単一のIDプロバイダーに制限されます。                       |
| FortiAuthenticator/FortiToken 2要素認証             | Fortinetセキュリティソリューションを使用した2要素認証。          | 既存のFortinet 2要素認証インフラストラクチャを統合できません。       |
| ユーザー名/パスワードによるHTTPSを使用したGitクローン  | HTTPS経由のユーザー名とパスワード認証を使用したGit操作。 | Git操作にはアクセストークンを使用する必要があります。                   |
| [Sigstore](../../ci/yaml/signing_examples.md) | ソフトウェアサプライチェーンセキュリティのためのキーレス署名と検証。  | 従来のコード署名方式を使用する必要があります。                   |
| ポートのリマッピング                                | SSH (22) などのポートを、別の受信ポートにリマップします。                 | GitLab Dedicatedは、デフォルトの通信ポートのみを使用します。      |

### コミュニケーションとコラボレーション {#communication-and-collaboration}

| 機能        | 説明                                                         | 影響                                                     |
| -------------- | ------------------------------------------------------------------- | ---------------------------------------------------------- |
| メールで返信する | メールでGitLabの通知とディスカッションに応答します。      | 応答するには、GitLabのウェブインターフェースを使用する必要があります。                  |
| サービスデスク   | メールでイシューを作成するための外部ユーザー向けチケットシステム。 | 外部ユーザーがイシューを作成するには、GitLabアカウントが必要です。 |

### 開発およびAI機能 {#development-and-ai-features}

| 機能                                | 説明                                                                          | 影響                                       |
| -------------------------------------- | ------------------------------------------------------------------------------------ | -------------------------------------------- |
| 一部のGitLab Duo AI機能        | コード提案、脆弱性検出、および生産性を実現するAI搭載機能。 | 開発タスクに対する限定的なAIアシスタンス。 |
| 無効になっている機能フラグの背後にある機能 | デフォルトで無効になっている試験的または未リリースの機能。                             | 開発中の機能にはアクセスできません。       |

AI機能の詳細については、[GitLab Duo](../../user/gitlab_duo/_index.md)を参照してください。

#### 機能フラグ {#feature-flags}

GitLabは、新しい機能や試験的な機能の開発とロールアウトをサポートするために、[機能フラグ](../../administration/feature_flags/_index.md)を使用します。GitLab Dedicated:

- デフォルトで有効になっている機能フラグの背後にある機能は使用できます。
- デフォルトで無効になっている機能フラグの背後にある機能は使用できず、管理者が有効にすることもできません。

デフォルトで無効になっているフラグの背後にある機能は、本番環境での使用準備ができていないため、GitLab Dedicatedでは安全ではありません。

機能が一般的に使用可能になり、フラグが有効になるか削除されると、その機能は同じバージョンのGitLab Dedicatedで使用できるようになります。GitLab Dedicatedは、バージョンのデプロイに関する独自の[リリーススケジュール](maintenance.md)に従います。

### GitLab Pages {#gitlab-pages-1}

| 機能                | 説明                                                     | 影響 |
| ---------------------- | --------------------------------------------------------------- | ------ |
| カスタムドメイン         | カスタムドメイン名でGitLab Pagesサイトをホストします。                 | `tenant_name.gitlab-dedicated.site`を使用してのみアクセスできるページサイト。 |
| PrivateLinkアクセス     | AWS PrivateLinkを介したGitLab Pagesへのプライベートネットワーキングアクセス。 | ページサイトには、パブリックインターネット経由でのみアクセスできます。特定のIPアドレスへのアクセスを制限するために、IP許可リストを設定できます。 |
| URLパスのネームスペース | ネームスペースベースのURL構造でページサイトを整理します。        | URLの整理オプションは限られています。 |

### 運用機能 {#operational-features}

以下の運用機能は利用できません:

- デフォルトのセカンダリリージョンを超えるGeoレプリケーション用の複数のセカンダリリージョン
- [Geoプロキシ](../../administration/geo/secondary_proxy/_index.md)と統合URLの使用
- セルフサービスによる購入と設定
- GCPやAzureなど、AWS以外のクラウドプロバイダーへのデプロイのサポート
- スイッチボードの可観測性ダッシュボード（GrafanaやOpenSearchなど）

### サーバーアクセスを必要とする機能 {#features-that-require-server-access}

次の機能は、サーバーへの直接アクセスが必要であり、設定できません:

| 機能                                                       | 説明                                                        | 影響                                                                                                                    |
| ------------------------------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| [Mattermost](../../integration/mattermost/_index.md)          | 統合されたチームチャットおよびコラボレーションプラットフォーム。                   | 外部チャットソリューションを使用します。                                                                                              |
| [サーバー側のGitフック](../../administration/server_hooks.md) | Gitイベント（pre-receive、post-receive）で実行されるカスタムスクリプト。 | [プッシュルール](../../user/project/repository/push_rules.md)または[Webhook](../../user/project/integrations/webhooks.md)を使用します。 |

{{< alert type="note" >}}

セキュリティとパフォーマンス上の理由から、サーバー側のGitフックはサポートされていません。代わりに、[プッシュルール](../../user/project/repository/push_rules.md)を使用してリポジトリポリシーを適用するか、[Webhook](../../user/project/integrations/webhooks.md)を使用してGitイベントで外部アクションをトリガーします。

{{< /alert >}}

## サービスレベルの可用性 {#service-level-availability}

GitLab Dedicatedは、月間サービスレベル目標99.5%の可用性を維持します。

サービスレベルの可用性は、GitLab Dedicatedが1か月間に使用できる時間の割合を測定します。GitLabは、次のコアサービスに基づいて可用性を計算します:

| サービスエリア       | 含まれる機能                                                                 |
| ------------------ | --------------------------------------------------------------------------------- |
| ウェブインターフェース      | GitLabのイシュー、マージリクエスト、CIジョブログ、GitLab API、HTTPS経由のGit操作 |
| コンテナレジストリ | レジストリHTTPSリクエスト                                                           |
| Git操作     | SSH経由でのGitプッシュ、プル、およびクローン操作                                     |

### サービスレベルの除外 {#service-level-exclusions}

以下は、サービスレベルの可用性の計算には含まれていません:

- 顧客の設定ミスが原因で発生したサービスの停止
- GitLabの制御外にある顧客またはクラウドプロバイダーのインフラストラクチャに関するイシュー
- スケジュールされたメンテナンス期間
- 重大なセキュリティまたはデータのイシューに対する緊急メンテナンス
- 自然災害、広範囲にわたるインターネット停止、データセンターの故障、またはGitLabの制御外にあるその他のイベントによって発生したサービスの停止。

## GitLab Dedicatedへの移行 {#migrate-to-gitlab-dedicated}

データをGitLab Dedicatedに移行するには:

- 別のGitLabインスタンスから:
  - [直接転送](../../user/group/import/_index.md)を使用します。
  - [ダイレクト転送API](../../api/bulk_imports.md)を使用します。
- サードパーティサービスから:
  - [インポート元](../../user/project/import/_index.md#supported-import-sources)を使用します。
- 複雑な移行の場合:
  - [プロフェッショナルサービス](../../user/project/import/_index.md#migrate-by-engaging-professional-services)を利用します。

## 期限切れのサブスクリプション {#expired-subscriptions}

サブスクリプションの有効期限が切れる前に、終了日が近づいているという通知が届きます。

サブスクリプションの有効期限が切れると、30日間インスタンスにアクセスできます。

データを保持するには、アカウントチームに連絡するか、有効期限から15日以内にサポートにメールで連絡して、データの保持をリクエストしてください。

この30日間の期間中に、次のことができます:

- メールサポートに連絡して、データを取得するための追加時間をリクエストします。
- プロフェッショナルサービスを利用して、移行の支援やオフボーディングのサポートを受けます。

30日後、データがアーカイブされていない場合、または別のインスタンスに移行されていない場合、インスタンスは終了し、すべてのお客様コンテンツが削除されます。これには、すべてのプロジェクト、リポジトリ、イシュー、マージリクエスト、およびその他のデータが含まれます。

インスタンスの終了後90日後に、アカウント削除の確認をリクエストできます。確認は、アカウントが閉じられたことを示すAWSからのメールとして提供されます。

## 始める {#get-started}

GitLab Dedicatedの詳細、またはデモをリクエストするには、[GitLab Dedicated](https://about.gitlab.com/dedicated/)を参照してください。

GitLab Dedicatedインスタンスの設定の詳細については、[GitLab Dedicatedインスタンスの作成](../../administration/dedicated/create_instance/_index.md)を参照してください。
