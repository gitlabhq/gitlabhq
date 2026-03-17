---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: シングルテナントのSaaSソリューションの利用可能な機能と利点を発見してください。
title: GitLab Dedicated
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated

{{< /details >}}

GitLab Dedicatedは、以下の特性を持つシングルテナントのSaaSソリューションです:

- 完全に隔離されています。
- ご希望のAWSリージョンにデプロイされます。
- GitLabによってホストおよびメンテナンスされます。

各インスタンスは以下を提供します:

- [高可用性](../../administration/dedicated/create_instance/data_residency_high_availability.md)とディザスターリカバリー。
- 最新機能による[定期的なアップデート](../../administration/dedicated/maintenance.md)。
- エンタープライズレベルのセキュリティ対策。

GitLab Dedicatedを使用すると、以下のことが可能です:

- 運用効率性の向上。
- インフラ管理のオーバーヘッドを削減。
- 組織のアジリティを向上。
- 厳格なコンプライアンス要件を満たします。

## 利用可能な機能 {#available-features}

このセクションでは、GitLab Dedicatedで利用可能な主要機能について説明します。

### セキュリティ {#security}

GitLab Dedicatedは、データを保護し、インスタンスへのアクセス制御を行うための以下のセキュリティ機能を提供します。

#### 認証と認可 {#authentication-and-authorization}

GitLab Dedicatedは、シングルサインオン（SSO）のために[SAML](../../administration/dedicated/configure_instance/authentication/saml.md)と[OpenID Connect（OIDC）](../../administration/dedicated/configure_instance/authentication/openid_connect.md)プロバイダーをサポートしています。

サポートされているプロバイダーを使用して、シングルサインオン（SSO）を認証用に設定できます。あなたのインスタンスがサービスプロバイダーとして機能し、GitLabがIdentity Providers（IdP）と通信するために必要な設定を提供します。

#### セキュアなネットワーキング {#secure-networking}

以下の2つの接続オプションが利用可能です:

- IP許可リストを使用したパブリック接続: デフォルトでは、お使いのインスタンスは公開されています。[IP許可リストを設定](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist)して、指定されたIPアドレスへのアクセスを制限できます。
- AWS PrivateLinkを使用したプライベート接続: [AWS PrivateLink](https://aws.amazon.com/privatelink/)を設定して、[受信](../../administration/dedicated/configure_instance/network_security.md#inbound-private-link)および[送信](../../administration/dedicated/configure_instance/network_security.md#outbound-private-link)接続に使用できます。

非公開証明書を使用する内部リソースへのプライベート接続の場合、[信頼された証明書を指定](../../administration/dedicated/configure_instance/network_security.md#custom-certificate-authorities-for-external-services)することもできます。

##### Webhookとインテグレーションのためのプライベート接続 {#private-connectivity-for-webhooks-and-integrations}

あなたのWebhookとインテグレーションが、パブリックインターネットからアクセスできないサービスに接続する必要がある場合、プライベート接続のためにAWS PrivateLinkを使用できます。GitLab DedicatedはSaaSサービスであるため、ネットワーク内のローカルIPアドレスに直接接続することはできません。

内部サービスのためにプライベート接続を設定するには:

1. 内部サービスにホスト名を割り当てます。
1. Private Hosted Zone（PHZ）レコードを設定して、これらのホスト名に送信プライベートリンク経由でルーティングします。
1. 送信プライベートリンクの10エンドポイント制限を考慮して計画してください。

10以上のエンドポイントに接続する必要がある場合、インフラストラクチャにリバースプロキシまたはTLSパススルーを実装してください。このアプローチにより、より少ないプライベートリンク接続で複数のサービスをルーティングできます。

#### データ暗号化 {#data-encryption}

データは、最新の暗号化標準を使用して保存時および転送時に暗号化された状態です。

オプションで、保存時データの暗号化キーとして独自のAWS Key Management Service（KMS）を使用できます。このオプションにより、GitLabに保存するデータを完全に制御できます。

詳細については、[GitLab Dedicatedの暗号化](../../administration/dedicated/encryption.md)を参照してください。

#### メールサービス {#email-service}

デフォルトでは、[Amazon Simple Email Service（Amazon SES）](https://aws.amazon.com/ses/)を使用して安全にメールを送信します。代替として、SMTPを使用して[独自のメールサービスを設定](../../administration/dedicated/configure_instance/users_notifications.md#smtp-email-service)できます。

#### Webアプリケーションファイアウォール {#web-application-firewall}

{{< details >}}

- ステータス: 利用制限

{{< /details >}}

Cloudflareは、分散型サービス拒否（DDoS保護）および関連するセキュリティ機能のためのWebアプリケーションファイアウォール（WAF）として実装されています。WAFの実装と設定は、GitLabのSREチームによって管理されます。WAFの設定またはログへの直接アクセスは利用できません。

### コンプライアンス {#compliance}

GitLab Dedicatedは、データのセキュリティと信頼性を確保するために、さまざまな規制、認証、およびコンプライアンスフレームワークに準拠しています。

#### コンプライアンスと認証の詳細を表示 {#view-compliance-and-certification-details}

コンプライアンスおよび認証の詳細を表示し、コンプライアンスアーティファクトを[GitLab Dedicated Trust Center](https://trust.gitlab.com/?product=gitlab-dedicated)からダウンロードできます。

#### アクセス制御 {#access-controls}

GitLab Dedicatedは、環境を保護するために厳格なアクセス制御を実装しています:

- 最小権限の原則に従い、必要最小限の権限のみを付与します。
- AWS組織へのアクセスを、選択されたGitLabチームメンバーに制限します。
- 包括的なセキュリティポリシーとユーザーアカウントへのアクセスリクエストを実装します。
- 自動化されたアクションおよび緊急時のアクセスのために、単一のHubアカウントを使用します。
- GitLab Dedicatedのエンジニアは、顧客環境への直接アクセスを持ちません。

[緊急事態](https://gitlab.com/gitlab-com/gl-infra/gitlab-dedicated/incident-management/-/blob/main/procedures/break-glass.md#break-glass-procedure)において、GitLabのエンジニアは以下を行う必要があります:

1. Hubアカウントを使用して顧客リソースにアクセスします。
1. 承認プロセスを通じてアクセスをリクエストします。
1. Hubアカウントを通じて一時的なIAMロールを引き受けます。

HubおよびテナントアカウントでのすべてのアクションはCloudTrailにログ記録されます。

#### モニタリング {#monitoring}

テナントアカウントでは、GitLab Dedicatedは以下を使用します:

- 侵入検知およびマルウェアスキャンのためのAWS GuardDuty。
- GitLabセキュリティインシデント対応チームによるインフラストラクチャログモニタリングにより、異常なイベントを検出します。

#### 監査と可観測性 {#audit-and-observability}

監査および可観測性のために[アプリケーションログ](../../administration/dedicated/monitor.md)にアクセスできます。これらのログは、システムアクティビティとユーザーアクションに関するインサイトを提供し、インスタンスのモニタリングとコンプライアンス要件の維持に役立ちます。

### カスタムドメイン {#custom-domains}

デフォルトでは、GitLab Dedicatedインスタンスは`tenant_name.gitlab-dedicated.com`でアクセスできます。代わりに、`gitlab.company.com`のような独自のドメイン名を使用するようにカスタムドメインを設定できます。

カスタムドメインを使用して以下を実行できます:

- GitLab Self-Managedから移行する際に、既存のURLを維持します。
- すべてのツールで組織のドメインを維持します。
- 既存の証明書管理またはドメインポリシーと統合します。

カスタムドメインを設定できる対象:

- あなたのmain GitLabインスタンス
- コンテナレジストリ（例: `registry.company.com`）
- Kubernetes向けGitLabエージェントサーバー（例: `kas.company.com`）

詳細については、[カスタムドメイン](../../administration/dedicated/configure_instance/network_security.md#custom-domains)を参照してください。

> [!note] 
> 
> GitLab Pagesはカスタムドメインをサポートしていません。GitLab Dedicatedインスタンス用に設定されたカスタムドメインに関係なく、Pagesサイトは`tenant_name.gitlab-dedicated.site`でのみアクセス可能です。

### オブジェクトストレージのダウンロード {#object-storage-downloads}

デフォルトでは、GitLab Dedicatedは最適なパフォーマンスのためにS3からの直接ダウンロードを有効にしています（`proxy_download = false`）。直接ダウンロードをサポートするオブジェクトタイプには以下が含まれます:

- [CI/CDジョブアーティファクト](../../administration/cicd/job_artifacts.md)
- [依存プロキシファイル](../../administration/packages/dependency_proxy.md)
- [マージリクエストの差分](../../administration/merge_request_diffs.md)
- [Git Large File Storage（LFS）オブジェクト](../../administration/lfs/_index.md)
- [プロジェクトパッケージ（例: PyPI、Maven、NuGet）](../../administration/packages/_index.md)
- [コンテナレジストリコンテナ](../../administration/packages/container_registry.md)
- [ユーザーアップロード](../../administration/uploads.md)

上記のオブジェクトタイプのいずれかをダウンロードすると、ブラウザまたはクライアントはGitLabインフラストラクチャを介してルーティングするのではなく、Amazon S3に直接接続します。

ネットワークセキュリティポリシーによってS3エンドポイントへの直接アクセスが妨げられている場合、GitLabインフラストラクチャを介したプロキシダウンロードをリクエストできます。この設定（`proxy_download = true`）により、すべてのダウンロードがGitLab Dedicatedインスタンスを介してルーティングされることが保証されます。

#### プロキシダウンロードをリクエスト {#request-proxied-downloads}

プロキシダウンロードをリクエストするには:

1. ユースケースの詳細を添えてアカウントエグゼクティブに連絡してください。
1. ネットワークセキュリティ要件に関する情報を含めます。
1. プロキシアクセスが必要なオブジェクトタイプを指定します。

> [!note]
> プロキシダウンロードは、S3への直接アクセスと比較してパフォーマンスに影響を与えます。

詳細については、[プロキシダウンロード](../../administration/object_storage.md#proxy-download)を参照してください。

### アプリケーション {#application}

GitLab Dedicatedには、自己管理型[Ultimate機能セット](https://about.gitlab.com/pricing/feature-comparison/)が付属していますが、いくつかの例外があります。詳細については、[利用できない機能](#unavailable-features)を参照してください。

#### 高度な検索 {#advanced-search}

GitLab Dedicatedは、[高度な検索機能](../../integration/advanced_search/elasticsearch.md)を使用します。

#### ClickHouse Cloud {#clickhouse-cloud}

資格のある顧客の場合、デフォルトで有効になっているClickHouse Cloudインテグレーションを通じて[高度な分析機能](../../integration/clickhouse.md)にアクセスできます。以下の条件を満たす場合、資格があります:

- あなたのGitLab Dedicatedテナントが商用AWSリージョンにデプロイされていること。政府機関向けGitLab Dedicatedはサポートされていません。
- ClickHouse Cloudは、サポートされているリージョンでのみ利用可能です。詳細については、[サポートされているリージョン](../../administration/dedicated/create_instance/data_residency_high_availability.md#supported-regions)を参照してください。

#### GitLab Pages {#gitlab-pages}

GitLab Dedicatedで[GitLab Pages](../../user/project/pages/_index.md)を使用して静的ウェブサイトをホストできます。Pagesはデフォルトで有効になっています。

あなたのウェブサイトはドメイン`tenant_name.gitlab-dedicated.site`を使用し、ここで`tenant_name`はあなたのインスタンスURLと一致します。

> [!note]
> カスタムドメインはサポートされていません。`gitlab.my-company.com`のようなカスタムドメインを追加しても、`tenant_name.gitlab-dedicated.site`でウェブサイトにアクセスします。

あなたのウェブサイトへのアクセスを以下で制御します:

- [GitLab Pagesアクセス制御](../../user/project/pages/pages_access_control.md)
- [IP許可リスト](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist)

既存のIP許可リストは、Pagesウェブサイトに適用されます。

ディザスターリカバリー中にフェイルオーバーが発生した場合、サイトはセカンダリリージョンから引き続き機能します。

#### ホスト型Runner {#hosted-runners}

[GitLab Dedicated用のホスト型Runner](../../administration/dedicated/hosted_runners.md)は、メンテナンスのオーバーヘッドなしにCI/CDワークロードをスケールすることを可能にします。

#### Self-Managed Runner {#self-managed-runners}

ホスト型Runnerを使用する代わりに、GitLab Dedicatedインスタンスのために独自のRunnerを使用できます。

自己管理型Runnerを使用するには、所有または管理するインフラストラクチャに[GitLab Runner](https://docs.gitlab.com/runner/install/)をインストールします。

#### OpenID ConnectとSCIM {#openid-connect-and-scim}

[SCIM](../../api/scim.md)を使用してユーザー管理を行うか、[GitLabをOpenID Connect Identity Providerとして](../../integration/openid_connect_provider.md)使用し、インスタンスへのIP制限を維持できます。

これらの機能をIP許可リストとともに使用するには:

- [IP許可リストのSCIMプロビジョニングを有効にする](../../administration/dedicated/configure_instance/network_security.md#enable-scim-provisioning-for-your-ip-allowlist)
- [IP許可リストのOpenID Connectを有効にする](../../administration/dedicated/configure_instance/network_security.md#enable-openid-connect-for-your-ip-allowlist)

### プレ本番環境 {#pre-production-environments}

GitLab Dedicatedは、本番環境の設定と一致するプレ本番環境をサポートしています。プレ本番環境を使用して以下を実行できます:

- 新機能を本番環境で実装する前にテストします。
- 設定の変更を本番環境に適用する前にテストします。

プレ本番環境は、GitLab Dedicatedサブスクリプションのアドオンとして購入する必要があり、追加のライセンスは不要です。

以下の機能が利用可能です:

- 柔軟なサイジング: 本番環境のサイズと合わせるか、より小さいリファレンスアーキテクチャを使用します。
- バージョンの一貫性: 本番環境と同じGitLabバージョンを実行します。

制限事項:

- シングルリージョンデプロイのみ。
- SLAのコミットメントなし。
- 本番環境よりも新しいバージョンは実行できません。

## GitLabが管理する設定 {#settings-managed-by-gitlab}

ほとんどの設定は管理者エリアを通じて変更できますが、GitLabはシステム安定性とセキュリティを確保するために特定の設定を自動的に管理します。

### レート制限 {#rate-limits}

GitLabは、インスタンスサイズに基づいてレート制限を設定し、最適なパフォーマンスを確保するために、メンテナンス期間中にこれらをデフォルトに自動的にリセットします。これらの制限により、単一のユーザーまたは自動化がインスタンス上の他のユーザーのパフォーマンスを低下させることを防ぎます。

GitLab Dedicatedでのレート制限の動作に関する詳細については、[認証済みユーザーレート制限](../../administration/dedicated/user_rate_limits.md)を参照してください。

## 利用できない機能 {#unavailable-features}

このセクションでは、GitLab Dedicatedで利用できない機能について説明します。

### 認証、セキュリティ、およびネットワーキング {#authentication-security-and-networking}

| 機能                                       | 説明                                                           | 影響                                                       |
| --------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------ |
| LDAP認証                           | 企業LDAP/Active Directoryの認証情報を使用した認証。     | 代わりにGitLab固有のパスワードまたはアクセストークンを使用する必要があります。 |
| スマートカード認証                     | スマートカードを使用した強化されたセキュリティのための認証。               | 既存のスマートカードインフラストラクチャは使用できません。               |
| Kerberos認証                       | Kerberosプロトコルを使用したシングルサインオン認証。                | GitLabに個別に認証する必要があります。                      |
| FortiAuthenticator/FortiToken 2FA             | Fortinetセキュリティソリューションを使用した2FA。          | 既存のFortinet 2FAインフラストラクチャは統合できません。       |
| ユーザー名/パスワードを使用したHTTPSでのGitクローン  | ユーザー名とパスワードの認証を使用したHTTPS経由のGit操作。 | Git操作にはアクセストークンを使用する必要があります。                   |
| SSH証明書認証                   | CA発行の証明書を使用したSSH認証。                      | SSH認証の別の方法、例えばSSHキーを使用する必要があります。    |
| [Sigstore](../../ci/yaml/signing_examples.md) | ソフトウェアサプライチェーンセキュリティのためのキーレス署名および検証。  | 従来のコード署名方法を使用する必要があります。                   |
| ポート再マッピング                                | SSH（ポート22）のようなポートを異なる受信ポートに再マッピングします。                 | GitLab Dedicatedは、デフォルトの通信ポートのみを使用します。      |

### コミュニケーションとコラボレーション {#communication-and-collaboration}

| 機能        | 説明                                                         | 影響                                                     |
| -------------- | ------------------------------------------------------------------- | ---------------------------------------------------------- |
| メールで返信する | GitLabの通知やディスカッションにメールで返信します。      | 返信するにはGitLabウェブインターフェースを使用する必要があります。                  |
| サービスデスク   | 外部ユーザーがメールを通じてイシューを作成するためのチケットシステム。 | 外部ユーザーはイシューを作成するためにGitLabアカウントを持っている必要があります。 |

### 開発とAI機能 {#development-and-ai-features}

| 機能                                | 説明                                                                          | 影響                                       |
| -------------------------------------- | ------------------------------------------------------------------------------------ | -------------------------------------------- |
| 一部のGitLab Duo AI機能        | AIを活用したコード提案、脆弱性検出、および生産性向上機能。 | 開発タスクに対する限定的なAIアシスタンス。 |
| 無効な機能フラグの背後にある機能 | 開発中の実験的機能およびベータ機能。                              | 実験的機能またはベータ機能へのアクセスはありません。       |

AI機能に関する詳細については、[GitLab Duo](../../user/gitlab_duo/_index.md)を参照してください。

#### 機能フラグ {#feature-flags}

機能フラグは、新しい機能、[実験的機能、およびベータ機能](../../development/documentation/experiment_beta.md)の開発とロールアウトをサポートするために使用されます。GitLab Dedicatedでは:

- 機能フラグを変更することはできません。
- デフォルトで有効になっている機能は利用可能です。
- デフォルトで無効になっている機能は利用できず、有効にすることもできません。

機能が一般公開されると、デプロイの[リリーススケジュール](../../administration/dedicated/maintenance.md)に従って同じバージョンで利用可能になります。

### GitLab Pages {#gitlab-pages-1}

| 機能                | 説明                                                     | 影響 |
| ---------------------- | --------------------------------------------------------------- | ------ |
| カスタムドメイン         | カスタムドメイン名でGitLab Pagesサイトをホストします。                 | Pagesサイトは`tenant_name.gitlab-dedicated.site`を使用した場合のみアクセス可能です。 |
| PrivateLinkアクセス     | AWS PrivateLinkを介したGitLab Pagesへのプライベートネットワークアクセス。 | Pagesサイトは、パブリックインターネット経由でのみアクセス可能です。IP許可リストを設定して、特定のIPアドレスへのアクセスを制限できます。 |
| URLパス内のネームスペース | ネームスペースベースのURL構造でPagesサイトを整理します。        | 限定されたURL整理オプション。 |

### 運用機能 {#operational-features}

以下の運用機能は利用できません:

- デフォルトのセカンダリリージョンを超えるGeoレプリケーション用の複数のセカンダリリージョン
- [Geoプロキシ](../../administration/geo/secondary_proxy/_index.md)と統合されたURLの使用
- セルフサービスでの購入と設定
- GCPやAzureなどの非AWSクラウドプロバイダーへのデプロイのサポート
- スイッチボードにおける可観測性ダッシュボード（例: GrafanaやOpenSearch）

### サーバーアクセスを必要とする機能 {#features-that-require-server-access}

以下の機能は直接サーバーアクセスを必要とし、設定できません:

| 機能                                                       | 説明                                                        | 影響                                                                                                                    |
| ------------------------------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| [Mattermost](../../integration/mattermost/_index.md)          | 統合されたチームチャットおよびコラボレーションプラットフォーム。                   | 外部チャットソリューションを使用します。                                                                                              |
| サーバーサイドGit [フック](../../administration/server_hooks.md) | Gitイベント（pre-receive、post-receive）で実行されるカスタムスクリプト。 | [プッシュルール](../../user/project/repository/push_rules.md)または[Webhook](../../user/project/integrations/webhooks.md)を使用します。 |

> [!note]
> セキュリティとパフォーマンス上の理由により、サーバーサイドGitフックはサポートされていません。代わりに、リポジトリポリシーを適用するには[プッシュルール](../../user/project/repository/push_rules.md)を使用するか、Gitイベントで外部アクションをトリガーするには[Webhook](../../user/project/integrations/webhooks.md)を使用します。

## サービスレベル可用性 {#service-level-availability}

GitLab Dedicatedは、月間99.9%の可用性というサービスレベル目標を維持します。

サービスレベル可用性は、暦月中にGitLab Dedicatedが使用可能な時間の割合を測定します。GitLabは、以下のコアサービスに基づいて可用性を計算します:

| サービス領域       | 含まれる機能                                                                 |
| ------------------ | --------------------------------------------------------------------------------- |
| Webインターフェース      | GitLabイシュー、マージリクエスト、GitLab API、HTTPS経由のGit操作 |
| コンテナレジストリ | レジストリHTTPSリクエスト                                                           |
| Git操作     | プッシュ、プル、およびSSH経由のクローン操作                                     |

### サービスレベルの除外 {#service-level-exclusions}

サービスレベル可用性の計算には、以下は含まれません:

- 顧客の設定ミスによって引き起こされるサービス中断
- GitLabの制御外にある顧客またはクラウドプロバイダーのインフラストラクチャに関するイシュー
- スケジュールされたメンテナンス期間
- 重要なセキュリティまたはデータイシューに関する緊急メンテナンス
- 自然災害、広範囲にわたるインターネット停止、データセンター障害、またはGitLabの制御外のその他のイベントによって引き起こされるサービス中断。

### ディザスターリカバリー {#disaster-recovery}

ディザスターリカバリーの目標を含むディザスターリカバリーの詳細については、[GitLab Dedicatedのディザスターリカバリー](../../administration/dedicated/disaster_recovery.md)を参照してください。

## GitLab Dedicatedに移行する {#migrate-to-gitlab-dedicated}

データをGitLab Dedicatedに移行するには:

- 別のGitLabインスタンスから:
  - [直接転送](../../user/group/import/_index.md)を使用します。
  - [直接転送API](../../api/bulk_imports.md)を使用します。
- サードパーティサービスから:
  - [インポート元](../../user/import/_index.md)（移行ツール）を使用します。
- 複雑な移行の場合:
  - [Professional Services](../../user/import/_index.md#migrate-by-engaging-professional-services)を利用します。

## 期限切れのサブスクリプション {#expired-subscriptions}

サブスクリプションの有効期限が切れる前に、終了日が近づいていることを示す通知が届きます。

サブスクリプションの有効期限が切れると、30日間インスタンスにアクセスできます。

データを保持するには、有効期限から15日以内にアカウントチームまたはサポートにメールで連絡し、データ保持をリクエストしてください。

この30日間で、あなたは以下のことができます:

- サポートにメールで連絡し、データを取得するための追加時間をリクエストします。
- 移行支援またはオフボーディングサポートのためにProfessional Servicesを利用します。

30日後、データがアーカイブされていないか、別のインスタンスに移行されていない場合、インスタンスは終了され、すべての顧客コンテンツが削除されます。これには、すべてのプロジェクト、リポジトリ、イシュー、マージリクエスト、およびその他のデータが含まれます。

インスタンス終了から90日後にアカウント削除の確認をリクエストできます。アカウントがクローズされたことを示すAWSからのメールとして確認が提供されます。

## 始める {#get-started}

GitLab Dedicatedに関する詳細情報またはデモのリクエストについては、[GitLab Dedicated](https://about.gitlab.com/dedicated/)を参照してください。

GitLab Dedicatedインスタンスの設定に関する詳細については、[GitLab Dedicatedインスタンスの作成](../../administration/dedicated/create_instance/_index.md)を参照してください。
