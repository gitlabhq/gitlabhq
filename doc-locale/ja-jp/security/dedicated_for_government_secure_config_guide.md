---
stage: GitLab Dedicated
group: US Public Sector Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>.
title: 政府機関向けGitLab Dedicatedセキュア設定ガイド 
---

{{< details >}}

- プラン: Ultimate
- 提供形態: 政府機関向けGitLab Dedicated

{{< /details >}}

FedRAMPは、クラウドサービスプロバイダーに対し、[セキュア設定ガイド](https://www.fedramp.gov/docs/rev5/balance/secure-configuration-guide/)を作成、維持、公開することを求めています。この指令には、必須要件と推奨要件の両方が含まれています。このページを使用して、政府機関向けGitLab Dedicatedのインスタンスを強化し、最新のFedRAMPガイダンスに合わせることができます。

必須要件:

- クラウドサービス製品全体への企業アクセスを制御する最上位の管理者アカウントへのセキュアなアクセス、設定、運用、および廃止の方法に関する説明。
- 最上位の管理者アカウントのみが操作できるセキュリティ関連の設定と、そのセキュリティへの影響に関する説明。

推奨要件:

- 特権アカウントのみが操作できるセキュリティ関連の設定と、そのセキュリティへの影響に関する説明。
- 最初にプロビジョニングされた際の、最上位の管理者アカウントおよび特権アカウントのセキュアなデフォルト。

GitLabは、米国の連邦機関および公共部門にサービスを提供する組織向けに、幅広い設定ガイダンスを提供しています。コアバリューとしての[透明性](https://handbook.gitlab.com/handbook/values/#transparency)により、[GitLabドキュメント](https://docs.gitlab.com)にはセキュア設定ガイドの必須要素がすでに詳細に記載されています。

## アーキテクチャ {#architecture}

[政府機関向けGitLab Dedicated](../subscriptions/gitlab_dedicated_for_government/_index.md)は、政府機関向けに特別に構築されたシングルテナントのSaaSソリューションです。これは[FedRAMP Moderate Authority to Operate (ATO)](https://marketplace.fedramp.gov/products/FR2411959145)を保持し、AWS GovCloudで実行され、インフラストラクチャレベルの完全な分離を提供します。各顧客環境は、他のテナントから分離された専用のAWSアカウント内に存在します。

アーキテクチャには、2つの異なる管理レイヤーがあります:

インフラストラクチャ管理レイヤー: GitLabによって管理されます。

アプリケーション管理レイヤー: 顧客管理者によって制御されます。

このガイドの設定を確認する前に、政府機関向けGitLab Dedicatedの[共有責任モデル](dedicated_for_government_shared_responsibility_model.md)を確認してください。共有責任モデルは、連邦機関の管理者が適用しなければならない強化を理解するための基盤となります。

## 要件1: 最上位の管理者アカウントのライフサイクル {#requirement-1-top-level-administrator-account-lifecycle}

このセクションでは、最上位の管理者アカウントのセキュアなセットアップから日常的な運用、安全な廃止までの完全なライフサイクルについて説明します。

FedRAMPの要件: クラウドサービス製品全体への企業アクセスを制御する最上位の管理者アカウントへのセキュアなアクセス、設定、運用、および廃止の方法を説明します。

### アクセスライフサイクル {#access-lifecycle}

政府機関向けGitLab Dedicatedインスタンスを購入すると、GitLab Dedicatedチームが最初の最上位管理者アカウントをプロビジョニングします。その後、Dedicatedのエンジニアが、アイデンティティ管理ソリューションとのインテグレーションを設定するのを支援します。一度設定されると、インスタンスへのアクセスを管理する完全な制御権が得られます。

政府機関向けGitLab Dedicatedは、[SAMLとOpenID Connect (OIDC)](../subscriptions/gitlab_dedicated_for_government/_index.md#authentication-and-authorization)によるシングルサインオンをサポートしており、既存の政府アイデンティティ管理インフラストラクチャを介して管理認証をルーティングできます。FedRAMPの関連するすべてのPIV/CAC要件を満たすために、Identity Providerを統合する責任があります。

完全なアクセスライフサイクルについては、以下を参照してください:

- [ユーザーを追加する](../user/profile/account/create_accounts.md#create-a-user-with-an-authentication-integration)
- [ユーザーを削除する](../user/profile/account/delete_account.md#delete-users-and-user-contributions)

管理者は、必要に応じて他の管理者を追加および削除できます。GitLabでは、専用の管理者アカウントを作成するか、または管理者が管理者エリアにアクセスする前にセッションを明示的に昇格させる必要がある組み込みのセキュリティ制御である[管理者モード](../administration/settings/sign_in_restrictions.md#admin-mode)をオンにすることを推奨します。どちらのアプローチでも、特権アカウントは対応する特権機能にのみ使用されることが保証されます。

アイデンティティ管理プラットフォームが統合されると、最上位の管理者はユーザーをプロビジョニングして初期ユーザーベースを構築できます。すべてのユーザーアカウントに対して最小特権の原則を適用します。プロジェクトが確立されると、以下のプロジェクトレベルのロールを通じて特定のユーザーにアクセスを割り当てることができます:

- 最小アクセス
- ゲスト
- プランナー
- レポーター
- デベロッパー
- メンテナー
- オーナー

GitLabは、ユニークなユースケースのために以下のユーザータイプもサポートしています:

- [監査担当者ユーザー](../administration/auditor_users.md): 管理者エリアとプロジェクトまたはグループの設定を除くすべてのグループ、プロジェクト、およびその他のリソースへの読み取り専用アクセスを提供します。特定のプロセスを検証するために特定のプロジェクトへのアクセスを必要とする第三者の監査担当者と関わる際に、監査担当者ロールを使用します。
- [外部ユーザー](../administration/external_users.md): 請負業者やその他の第三者など、組織外のユーザーに制限付きアクセスを提供します。IA-4(4)などの制御では、非組織ユーザーを企業ポリシーに従って識別および管理する必要があります。外部ユーザーを設定することで、プロジェクトへのアクセスをデフォルトで制限し、管理者が組織に雇用されていないユーザーを特定するのに役立つため、リスクを軽減できます。
- [サービスアカウント](../user/profile/service_accounts.md): 自動化されたタスクに対応します。サービスアカウントはライセンスのシートを使用しません。

GitLabは、ユニークな権限要件のために[カスタムロール](../user/custom_roles/_index.md)をサポートしています。詳細については、[プロジェクト権限](../user/permissions.md#project-permissions)および[グループ権限](../user/permissions.md#group-permissions)を参照してください。

管理者がプロビジョニングされたユーザー構造がアイデンティティ管理プラットフォームで確立されると、最上位の管理者アカウントはブレイクグラスアカウントとして扱われ、他のすべての管理アクティビティは標準のIdentity Providerを介して行われます。

## 要件2 {#requirement-2}

FedRAMPの要件: 最上位の管理者アカウントのみが操作できるセキュリティ関連の設定と、そのセキュリティへの影響に関する説明を提供します。

このセクションでは、政府機関向けGitLab Dedicatedで特に利用可能な設定を列挙し、[GitLabを管理する](../administration/_index.md)ための既存の広範なドキュメントをお客様に案内します。 

### 最上位管理者によるインフラストラクチャの設定 {#infrastructure-configurations-by-top-level-administrators}

政府機関向けGitLab Dedicatedでは、最上位の顧客管理者が、GitLabサポートチームへのリクエストを通じて、特定のインフラストラクチャレベルのセキュリティおよびアーキテクチャ設定を要求できます。 

これらの設定には以下が含まれます: 

- テナント外のリソースとのネットワーク接続の確立（PrivateLink経由など）。 
- 顧客提供キーの持ち込み (Bring-Your-Own-Key) - 顧客は、GitLabテナントが顧客提供のキーを使用するようにリクエストできます。 
- カスタムドメインの設定 - 顧客は、標準の政府機関向けGitLab Dedicatedドメインではなく、GitLabテナントが顧客提供のドメインを使用するようにリクエストできます。提供されたドメインがDNSSECのすべての関連する指令を満たしていることを確認するのは、顧客の責任です。 
- リファレンスアーキテクチャの選択
- 総リポジトリ容量の選択
- テナント名の選択
- アベイラビリティゾーンの選択
- ライセンスキーの受領
- ルートユーザーパスワードの設定
- リリースロールアウト/メンテナンススケジュールの選択
- 受信および送信IP/ドメイン許可リストの設定

## 推奨1 {#recommendation-1}

FedRAMPの推奨: 特権アカウントのみが操作できるセキュリティ関連の設定と、そのセキュリティへの影響に関する説明を提供します。

## 要件2: 最上位の管理者アカウントのセキュリティ設定 {#requirement-2-security-settings-for-top-level-administrator-accounts}

最上位の管理者のみが利用できるセキュリティ設定は、インスタンス全体のセキュリティ対策状況に直接的な影響を及ぼします。

FedRAMPの要件: 最上位の管理者アカウントのみが操作できるセキュリティ関連の設定と、そのセキュリティへの影響に関する説明を提供します。

### 最上位管理者のためのインフラストラクチャ設定 {#infrastructure-configurations-for-top-level-administrators}

政府機関向けGitLab Dedicatedは、GitLabサポートチームを通じてリクエストできる特定のインフラストラクチャレベルのセキュリティおよびアーキテクチャ設定をサポートしています。

これらの設定には以下が含まれます:

- テナント外のリソースとのネットワーク接続（PrivateLink経由など）
- 顧客管理の暗号化: GitLabテナントが顧客提供の暗号化キーを使用するようにリクエストします。KMSキーとキーポリシーの作成と管理は、お客様の責任です。
- カスタムドメイン: 標準の政府機関向けGitLab Dedicatedドメインではなく、顧客提供のドメインをリクエストします。提供されたドメインがDNSSECのすべての関連する指令を満たしていることを確認するのは、お客様の責任です。
- リファレンスアーキテクチャの選択
- 総リポジトリ容量
- テナント名
- アベイラビリティゾーン
- ライセンスキー
- ルートユーザーパスワード
- リリースロールアウトおよびメンテナンススケジュール
- 受信および送信IPとドメイン許可リスト

## 推奨1: 特権アカウントのセキュリティ設定 {#recommendation-1-security-settings-for-privileged-accounts}

最上位の管理者よりも下の特権アカウントは、インスタンスとそのデータのセキュリティに大きく影響する可能性のある設定にアクセスできます。

FedRAMPの推奨: 特権アカウントのみが操作できるセキュリティ関連の設定と、そのセキュリティへの影響に関する説明を提供します。

最上位の管理者アカウントと、Identity Providerを介してプロビジョニングされた管理者アカウントは、機能的に同等です。初期セットアップにのみ最上位アカウントを使用します。それ以降のすべてのセキュリティ設定および設定には、Identity Providerを介してプロビジョニングされた管理者アカウントを使用します。利用可能なすべての設定については、[GitLabを管理する](../administration/_index.md)を参照してください。

### システム開発ライフサイクルおよび変更管理 {#system-development-lifecycle-and-change-management}

管理者は、ソフトウェア開発ライフサイクル (SDLC) をセキュアにし、変更管理プラクティスを確立するための幅広いツールスイートを持っています。詳細については、[ビルドおよびCI/CDでコードを管理する](../topics/build_your_application.md)を参照してください。

セキュリティを念頭に置いたCI/CDパイプラインを設計する方法を理解するために、[パイプラインセキュリティ](../ci/pipeline_security/_index.md)のドキュメントを確認してください。[NIST 800-53コンプライアンスガイド](hardening_nist_800_53.md#configuration-management-cm)には、変更管理とセキュアなブランチを確立する方法の詳細が記載されています。利用可能な変更管理設定を確認して、承認された変更のみがコードベースに適用されるようにしてください。

### リスク評価およびシステムと情報インテグリティ {#risk-assessment-and-system-and-information-integrity}

コードをセキュアにするためのツールを確立する責任があります。GitLabには、アプリケーションの開発に組み込むことができる[検出ツール](../user/application_security/detect/_index.md)のスイートが含まれています:

- [セキュリティ設定](../user/application_security/detect/security_configuration.md)
- [コンテナスキャン](../user/application_security/container_scanning/_index.md)
- [依存関係スキャン](../user/application_security/dependency_scanning/_index.md)
- [静的アプリケーションセキュリティテスト（SAST）](../user/application_security/sast/_index.md)
- [Infrastructure as Code（IaC）スキャン](../user/application_security/iac_scanning/_index.md)
- [シークレット検出](../user/application_security/secret_detection/_index.md)
- [動的アプリケーションセキュリティテスト (DAST)](../user/application_security/dast/_index.md)
- [APIファジング](../user/application_security/api_fuzzing/_index.md)
- [カバレッジガイドファズテスト](../user/application_security/coverage_fuzzing/_index.md)

コードがマージされる前に脆弱性について評価されるように、特定のCIジョブを適用できます。

### アクセス管理 {#access-management}

以下のロールは、標準的なユーザーアクセスを超える特権機能を持っています:

- メンテナー
- オーナー

これらのロールには[広範な権限ドキュメント](../user/permissions.md)があり、プロジェクトやグループにユーザーをプロビジョニングする際には注意深く確認する必要があります。

#### 管理者エリアでのアクセス管理 {#access-management-in-the-admin-area}

管理者エリアでは、管理者は[権限をエクスポートする](../administration/admin_area.md#user-permission-export) 、[ユーザーIDをレビューする](../administration/admin_area.md#user-identities) 、[グループを管理する](../administration/admin_area.md#administering-groups)などを行うことができます。FedRAMPおよびNIST 800-53の要件を満たすのに役立つ機能は次のとおりです:

- 侵害が疑われる場合に[ユーザーパスワードをリセット](reset_user_password.md)します。
- [ユーザーのロックを解除する](unlock_user.md)。デフォルトでは、GitLabは10回のサインイン失敗後にユーザーをロックします。ユーザーは10分間ロックされたままか、または管理者がロックを解除するまでロックされます。AC-7のガイダンスに従い、FedRAMPはアカウントロックアウトのパラメータ定義に関してNIST 800-63Bに準拠しており、これはデフォルトの設定で満たされています。
- [不正利用レポート](../administration/review_abuse_reports.md)または[スパムログ](../administration/review_spam_logs.md)を確認します。FedRAMPは、組織が異常な使用（AC-2(12)）のためにアカウントを監視することを要求します。ユーザーは不正利用レポートで不正利用を報告でき、管理者は調査が終了するまでアクセスを削除できます。スパムログは、管理者エリアの**スパムログ**セクションに統合されています。管理者は、そのエリアでフラグが付けられたユーザーを削除、ブロック、または信頼できます。
- [認証情報インベントリ](../administration/credentials_inventory.md): GitLabインスタンスで使用されるすべてのシークレットを一か所で確認します。認証情報、トークン、およびキーの統合ビューは、パスワードの確認や認証情報のローテーションなどの要件を満たすのに役立ちます。
- [デフォルトセッション期間](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration): FedRAMPでは、非アクティブなユーザーは設定された期間後にログアウトされることを要求しています。FedRAMPは期間を特定していませんが、特権ユーザーは標準的な勤務期間の終わりにログアウトされるべきであることを明確にしています。
- [新規ユーザーをプロビジョニングする](../user/profile/account/create_accounts.md): 管理者エリアUIを通じてユーザーを作成します。IA-5に準拠して、GitLabは新規ユーザーに初回ログイン時にパスワードを変更することを要求します。
- ユーザーのプロビジョニングを解除する: [管理者エリアUIを通じてユーザーを削除します](../user/profile/account/delete_account.md#delete-users-and-user-contributions)。あるいは、[ユーザーをブロック](../administration/moderate_users.md#block-a-user)してすべてのアクセスを削除し、リポジトリ内のデータを維持します。ブロックされたユーザーはシート数に影響しません。
- ユーザーを非アクティブ化する: アカウントレビュー中に特定された非アクティブなユーザーは、[一時的に非アクティブ化できます](../administration/moderate_users.md#deactivate-a-user)。ブロックとは異なり、ユーザーを非アクティブ化してもGitLab UIへのサインインは妨げられません。非アクティブ化されたユーザーは、サインインすることで再びアクティブになることができます。非アクティブ化されたユーザー:
  - リポジトリまたはAPIにアクセスできません。
  - スラッシュコマンドを使用できません。
  - シートを占有しません。

### SSHキー {#ssh-keys}

GitLabは、Gitと認証して通信するためにSSHキーを設定する方法に関する[指示を提供します](../user/ssh.md)。[コミットに署名できます](../user/project/repository/signed_commits/ssh.md)。これにより、公開キーを持つ誰にでも追加の検証が提供されます。管理者は[最小限のキー技術とキー長を確立できます](ssh_keys_restrictions.md)。

SSHキーがFIPS検証済みの暗号学的モジュールで生成されていることを確認する責任があります。

### トークン管理 {#token-management}

GitLabは、パーソナルアクセストークンを設定および管理する方法に関する[指示を提供します](../user/profile/personal_access_tokens.md)。GitLabは[きめ細かい権限](../auth/tokens/fine_grained_access_tokens.md)をサポートしており、これを使用して、該当するユースケースに必要な権限のみにトークンのスコープを設定できます。ユーザーおよびサービストークンには、最小限の特権のみをプロビジョニングし、不正なトークンの影響を制限します。

### 監査ログおよびインシデント管理 {#audit-logging-and-incident-management}

アプリケーションログを消費する責任があります。テナントのS3バケット内の特定のログにアクセスするには、GitLabサポートチームに連絡してください。基盤となるインフラストラクチャログは、政府機関向けGitLab Dedicatedのエンジニアによって管理され、GitLabセキュリティによって監視されます。

### メール {#email}

GitLabは、[メール通知を送信する](../administration/email_from_gitlab.md)ことと、インスタンスの[アプリケーション通知メールを設定する](../user/profile/notifications.md)ことをサポートしています。DHS Binding Operational Directive 18-01は、DMARC（Domain-based Message Authentication, Reporting and Conformance）が迷惑メール対策として送信メッセージに設定されることを要求しています。政府機関向けGitLab Dedicatedは、この設定をデフォルトで提供します。その機能が必要ない場合は、メール通知をオフにできます。

### GitLab Runner {#gitlab-runners}

政府機関向けGitLab Dedicatedの顧客は、テナント外で独自の[セルフマネージドRunner](../ci/runners/_index.md)を構築および管理する必要があります。設定ガイダンスについては、[Runnerを設定する](../ci/runners/configure_runners.md)を参照してください。提供されているFIPSバージョンを使用してRunnerをビルドし、FedRAMP要件への準拠を確実にします。

Runnerは、FedRAMP境界に接続された重要なインフラストラクチャの拡張です。設定が誤っている、または侵害されたRunnerは、CI/CDパイプラインおよびダウンストリームアーティファクトにサプライチェーンリスクをもたらす可能性があります。Dedicated境界外の分離された強化された環境にRunnerをデプロイします。Runner認証トークンへのアクセスをゼロトラスト原則に従って安全に管理し、定期的にローテーションしてください。Runnerアクティビティの監査ログを設定および監視します。

## 推奨2: 管理者アカウントのセキュアなデフォルト {#recommendation-2-secure-defaults-for-administrator-accounts}

アカウントが最初にプロビジョニングされた際にセキュアなデフォルトを設定することで、設定ミスのリスクを軽減し、最初から強力なセキュリティベースラインを確立できます。

FedRAMPの推奨: 最初にプロビジョニングされた際に、すべての設定を最上位の管理者アカウントおよび特権アカウントの推奨されるセキュアなデフォルトに設定します。

最上位の管理者アカウントは、初回ログイン時に強力なパスワードを設定できるようにプロビジョニングされます。FedRAMP要件に従って、ルートユーザーの[2要素認証 (2FA)](../user/profile/account/two_factor_authentication.md)を登録する必要があります。GitLabは、FIPS準拠でフィッシング耐性のあるWebAuthnデバイスを含む、幅広い要素をサポートしています。

ゼロトラストセキュリティ原則に沿うために、以下を行う必要があります:

- ルートユーザーだけでなく、すべての特権アカウントに2FAを要求します。
- 管理アクセスを付与する前に、デバイスの状態とユーザーコンテキストを検証する条件付きアクセスポリシーを実装します。
- セッションタイムアウトを強制し、機密性の高い操作には再認証を要求します。
- すべての認証メカニズムに、FIPS検証済みの暗号学的モジュールを使用します。
- 必要な管理特権のみが付与されていることを定期的に監査および検証します。

統合されたIdentity Providerを通じてプロビジョニングされた追加の管理者は、次のような組織的制御を満たす必要があります:

- パスワードの長さと複雑さの強制
- ログイン失敗によるロックアウト
- PIV/CAC認証
- 組織的に管理された2要素認証
- 非アクティブユーザーのロックアウト

## 追加リソース {#additional-resources}

GitLabは、管理者向けの強化の決定を導くための[CISベンチマーク](https://about.gitlab.com/blog/gitlab-introduces-new-cis-benchmark-for-improved-security/)を公開しています。これを開始点として、インスタンス内でセキュアなプロジェクトとアプリケーションリソースをビルドするために使用してください。
