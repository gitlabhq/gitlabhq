---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>.
title: 政府機関向けGitLab Dedicated共有責任モデル
---

{{< details >}}

- プラン: Ultimate
- 提供形態: 政府機関向けGitLab Dedicated

{{< /details >}}

政府機関向けGitLab Dedicatedは、連邦機関との共有責任モデルを含むFedRAMP Moderate承認を維持しています。連邦機関は、政府機関向けGitLab Dedicatedのインスタンスを運用する際に負う責任と、GitLabの認可から継承できる責任を理解する必要があります。このドキュメントは、以下の点を理解するのに役立ちます:

- 認可境界とハイレベルなコンポーネント。
- GitLabインスタンス内のセキュリティとコンプライアンスを管理する責任。
- 共有責任モデルに影響を与える可能性のあるオプション機能。

## リソース {#resources}

NIST 800-53コントロールに紐づく顧客責任の詳細については、[FedRAMP package request form](https://www.fedramp.gov/resources/documents/Agency_Package_Request_Form.pdf)を使用して、政府機関向けGitLab DedicatedのFedRAMPパッケージをリクエストしてください。GitLabパッケージのIDは`FR2411959145`です。Connect.govのFedRAMPパッケージで利用可能なControl Implementation Summary/Customer Responsibility Matrix Excelテンプレートは、連邦機関が自らの責任を理解するために不可欠です。

このGitLabドキュメントは、[政府機関向けGitLab Dedicatedセキュア設定ガイド](dedicated_for_government_secure_config_guide.md)で特定の設定ガイダンスとマッピングを使用して責任ガイドを作成します。

## 認可境界 {#authorization-boundary}

![認可境界図](img/gdg_boundary_diagram_v18_9.png)

## 責任の概要 {#responsibility-overview}

以下のセクションは、標準的な政府機関向けGitLab Dedicatedのデプロイにおいて、顧客とGitLabが負う幅広い責任を連邦機関が理解するのに役立つことを目的としています。これらのセクションは、顧客とGitLabがそれぞれ負う責任を概説する機能セクションに分けられます。連邦機関は、特定のデプロイに適用される責任を検証するために、GitLabパートナーと協力することが重要です。顧客の責任に影響を与える可能性のあるオプション機能とカスタマイズ:

1. [カスタムドメイン](../subscriptions/gitlab_dedicated/_index.md#custom-domains) - 顧客はデフォルトドメインではなく、カスタムドメインを設定できます。
1. [セルフマネージドRunner](../subscriptions/gitlab_dedicated/_index.md#self-managed-runners) - 顧客はRunnerを接続してCI/CDワークロードをサポートできます。 
1. 連邦機関Identity Provider - GitLabは、SSOのためにSAMLおよびOpenID Connect (OIDC) Identity Providerの使用をサポートしています。PIV/CAC認証をサポートするには、顧客は独自のIdentity Providerを使用する必要があります。 
1. [強化されたネットワーク接続](../subscriptions/gitlab_dedicated/_index.md#secure-networking) - 顧客は、アプリケーション設定またはインフラストラクチャ設定のいずれかを通じて、GitLabエンジニアの支援を受けてIP許可リストを設定することを選択できます。プライベート接続は、受信および送信接続のためにPrivateLink経由でサポートされています。 
1. [顧客管理の暗号化](../administration/dedicated/encryption.md#customer-managed-encryption) - 顧客は独自の暗号化キーを提供することを選択できます。

### インフラストラクチャ管理 {#infrastructure-management}

GitLabは以下の責任を負います:

- 仮想マシンとK8sのパッチ適用 - 政府機関向けGitLab Dedicatedエンジニアは、各顧客テナントのAWS上の基盤となるインフラストラクチャを管理します。基盤となるインフラストラクチャを最新のセキュリティパッチで更新するために、毎週メンテナンスが予定されています。 
- STIG/CISベンチマークの適用を含むインフラストラクチャの強化。 
- FIPS検証済み暗号による保存時および転送時データの暗号化。
- プラットフォームアップタイム - 政府機関向けGitLab Dedicatedは、環境のRTOとRPOを検証するためのバックアップ、フェイルオーバー、およびあらゆるテストの管理に責任を負います。
- AWSネットワークインフラストラクチャ内のIP許可リストの維持。顧客は、GitLabインスタンスへの接続が明示的に許可されるべきドメインと顧客IPリストを提供できます。GitLabは、リクエストされ次第、それらの許可リストを設定する責任を負います。 
- Cloudflare Web Application FirewallとDNSの維持。
- BYOKの使用を選択した場合、GitLabはAWSアカウントIDを提供する必要があります。
- GitLabアプリケーションによって生成される送信メールのためのDMARCとスパム保護の設定。

顧客は以下の責任を負います:

- 政府機関向けGitLab Dedicated境界に接続されたあらゆるインフラストラクチャの維持。
- アプリケーション内のIP許可リストの設定。
- Bring Your Own Domain機能を使用することを選択した場合、ドメインはDNSSECなどのFedRAMP要件に準拠して設定する必要があります。 
- BYOKの使用を選択した場合、KMSキーとキーポリシーの作成および管理、GitLabが提供するAWSアカウントIDへのアクセス許可。
- イシューを介した特定のインフラストラクチャ設定のリクエスト。以下に例を示します:
  - リファレンスアーキテクチャ
  - 総リポジトリ容量
  - テナント名
  - アベイラビリティゾーン
  - ライセンスキー

## 責任 {#responsibilities}

以下のセクションは、標準的な政府機関向けGitLab Dedicatedのデプロイにおいて、顧客とGitLabが負う幅広い責任を連邦機関が理解するのに役立ちます。各セクションは、機能領域別に整理され、顧客とGitLabがそれぞれ負う責任を概説しています。特定のデプロイに適用される責任を検証するために、GitLabパートナーと協力してください。

顧客の責任に影響を与える可能性のあるオプション機能とカスタマイズ:

- [カスタムドメイン](../subscriptions/gitlab_dedicated/_index.md#custom-domains): デフォルトドメインではなく、カスタムドメインを設定します。
- [セルフマネージドRunner](../subscriptions/gitlab_dedicated/_index.md#self-managed-runners): Runnerを接続してCI/CDワークロードをサポートします。
- 連邦機関Identity Provider: GitLabは、シングルサインオンのためにSAMLとOpenID Connect (OIDC) をサポートしています。PIV/CAC認証をサポートするには、独自のIdentity Providerを使用する必要があります。
- [強化されたネットワーク接続](../subscriptions/gitlab_dedicated/_index.md#secure-networking): アプリケーション設定またはインフラストラクチャ設定のいずれかを通じて、GitLabエンジニアの支援を受けてIP許可リストを設定します。プライベート接続は、受信および送信接続のためにPrivateLink経由でサポートされています。
- [顧客管理の暗号化](../administration/dedicated/encryption.md#customer-managed-encryption): 独自の暗号化キーを提供します。

### インフラストラクチャ管理 {#infrastructure-management-1}

GitLabは以下の責任を負います:

- 仮想マシンとKubernetesのパッチ適用 - 政府機関向けGitLab Dedicatedエンジニアは、AWS上で各顧客テナントの仮想マシンおよびKubernetesのパッチ適用を管理します。基盤となるインフラストラクチャを最新のセキュリティパッチで更新するために、毎週メンテナンスが予定されています。
- インフラストラクチャはSTIGおよびCISベンチマークが適用されて強化されます。
- 保存時および転送時のデータは、FIPS検証済み暗号で暗号化されたものです。
- プラットフォームアップタイム - 政府機関向けGitLab Dedicatedは、環境のRTOとRPOを検証するためのバックアップ、フェイルオーバー、およびテストを管理します。
- IP許可リストはAWSネットワークインフラストラクチャ内で維持されます。GitLabインスタンスへの接続が明示的に許可されるドメインとIPリストを提供できます。GitLabは、リクエスト後にそれらの許可リストを設定します。
- Cloudflare Web Application FirewallとDNSはGitLabによって維持されます。
- BYOKの使用を選択した場合、GitLabはAWSアカウントIDを提供します。
- GitLabアプリケーションによって生成される送信メールのために、DMARCとスパム保護が設定されます。

顧客は以下の責任を負います:

- 政府機関向けGitLab Dedicated境界に接続されたあらゆるインフラストラクチャの維持。
- アプリケーション内のIP許可リストの設定。
- Bring Your Own Domain機能を使用する場合、DNSSECなどのFedRAMP要件に準拠してドメインを設定します。
- BYOKを使用する場合、KMSキーとキーポリシーを作成および管理し、GitLabが提供するAWSアカウントIDへのアクセスを許可します。
- サポートチケットを介した特定のインフラストラクチャ設定のリクエスト。以下に例を示します:
  - リファレンスアーキテクチャ
  - 総リポジトリ容量
  - テナント名
  - アベイラビリティゾーン
  - ライセンスキー
  - ルートユーザーパスワード
  - リリースロールアウトおよびメンテナンススケジュール

### GitLabアプリケーション {#gitlab-application}

GitLabは以下の責任を負います:

- GitLabアプリケーションは、毎週のメンテナンス期間中にアップグレードされます。

顧客は以下の責任を負います:

- CI/CD、グループおよびプロジェクトレベルの設定を含むGitLabアプリケーションの設定。
- 顧客が管理するワークロードで実行される可能性のある、GitLabが提供する最新のコンテナをプルすること。

### モニタリング {#monitoring}

GitLabは以下の責任を負います:

- AWSインフラストラクチャとセキュリティツールによって生成されたセキュリティイベントは、GitLabによってモニタリングされます。
- アップタイムやプラットフォーム安定性メトリクスを含むインフラストラクチャメトリクスは、GitLabによってモニタリングされます。
- 監査ログは、規制要件に準拠して保持されます。
- GitLabは、認可境界内の基盤となるインフラストラクチャコンポーネントからのセキュリティインシデントに対応し、影響を受ける顧客とUS-CERTにNIST 800-61に準拠してレポートします。

顧客は以下の責任を負います:

- アプリケーションログの利用。GitLabサポートチケットを通じてS3のログアクセスをリクエストします。
- セルフマネージドインフラストラクチャのモニタリング。
- 顧客インスタンスに接続されたセルフマネージドインフラストラクチャによって生成されたすべての監査ログを保持すること。
- GitLabアプリケーションログまたはセルフマネージドインフラストラクチャ内で検出された、FedRAMP境界に影響を与える可能性のあるインシデントのレポート。
  
### 脆弱性管理 {#vulnerability-management}

GitLabは以下のスキャンとパッチ適用に責任を負います:

- Webアプリケーション。GitLabは代表的なWebアプリケーションをGitLab DASTでスキャンし、特定された脆弱性にパッチを適用します。
- コンテナ。GitLabは、AWS Amazon Elastic Container Registry内のすべてのコンテナイメージをスキャンしてパッチを適用します。これらは本番環境ワークロード内で実行されるコンテナをビルドするために使用されます。GitLabはまた、以下のコンテナイメージをスキャンしてパッチを適用します。これらはGitLabからプルして独自のインフラストラクチャやCI/CDワークロードで実行できます:
  - GitLab動的アプリケーションセキュリティテストイメージ
  - GitLabコンテナスキャナーイメージ
  - GitLab APIセキュリティイメージ
  - GitLab静的アプリケーションセキュリティテストイメージ
  - GitLab Infrastructure as Codeアナライザーイメージ
  - GitLabシークレット検出イメージ
  - GitLab RunnerおよびRunnerヘルパーイメージ
  - GitLab依存関係スキャンイメージ
- インフラストラクチャ。GitLabは、政府機関向けGitLab Dedicatedの認可境界内で使用されているすべてのVMとAMIをスキャンします。

顧客は以下の責任を負います:

- 認可境界外にデプロイされているが、これに接続されているアセットのスキャンとパッチ適用。
- デプロイされたイメージ内の脆弱性を検出して修正するプロセスを確立すること。
- GitLabインスタンス内で管理されるコード、またはCI/CDワークロードから生成された脆弱性のトリアージと修正すること。
- 独自のインフラストラクチャでプルして実行するGitLab提供のイメージをスキャンすること。
- GitLab提供のイメージに脆弱性が見つかった場合、GitLabと連携してパッチ適用タイムラインを決定すること。
  
### アイデンティティおよびアクセス管理 {#identity-and-access-management}

GitLabは以下の責任を負います:

- SAMLとOIDCを通じたインテグレーションのサポート。
- GitLabインスタンスの最初の管理者のプロビジョニング。
- 認可境界内のインフラストラクチャへのアクセス管理。

顧客は以下の責任を負います:

- 独自のアイデンティティおよびアクセス管理ソリューションの管理。
- FIPS準拠およびフィッシング耐性のある第二要素を含む、従業員への認証器の配布。
- GitLabインスタンス内のユーザーアクセス管理。

### コンプライアンス {#compliance}

GitLabは以下の責任を負います:

- 認可境界の年次監査およびペネトレーションテストの実施。
- 重要な変更リクエストの提出。
- Plan of Actionsおよびマイルストーンを含む継続的なモニタリングのアーティファクトの維持。
- システムセキュリティプランと添付資料の維持。

顧客は以下の責任を負います:

- 政府機関向けGitLab Dedicatedの認可境界に接続されたあらゆるインフラストラクチャを含む、機関認可書類および資料の提出。
- GitLab Information System Security Officer (ISSO)との月次継続モニタリング提出物のレビュー。
