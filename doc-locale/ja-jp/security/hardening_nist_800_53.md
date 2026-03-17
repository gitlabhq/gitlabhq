---
stage: GitLab Dedicated
group: US Public Sector Services
info: All material changes to this page must be approved by the [FedRAMP Compliance team](https://handbook.gitlab.com/handbook/security/security-assurance/security-compliance/fedramp-compliance/#gitlabs-fedramp-initiative). To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments.
title: NIST 800-53コンプライアンス
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このページは、該当するNIST 800-53コントロールを満たすようにGitLab Self-Managedインスタンスを設定したいGitLabの管理者向けのリファレンスです。GitLabは、管理者が持つ可能性のある様々な要件があるため、特定の設定ガイダンスを提供していません。NIST 800-53セキュリティコントロールを満たすGitLabインスタンスをデプロイする前に、技術的な詳細については顧客のソリューションアーキテクトと協力してください。

## スコープ {#scope}

このページは、NIST 800-53コントロールファミリーの構成に従っています。このページのスコープは主にGitLab自体への設定に限定されているため、すべてのコントロールファミリーが適用されるわけではありません。設定の詳細はプラットフォームに依存しないように意図されています。

GitLabのガイダンスは、完全に準拠したシステムを構成するものではありません。政府データを扱う前に、以下のことを行う必要があります:

- 追加の設定と技術スタック全体の強化を計画してください。
- セキュリティ設定の独立した評価を検討してください。
- [サポートされているクラウドプロバイダー](../install/cloud_providers.md)全体でのデプロイの違いを理解し、利用可能な場合は特定のガイダンスに従ってください。

## コンプライアンス機能 {#compliance-features}

GitLabは、GitLabで重要なコントロールとワークフローを自動化するために使用できるいくつかの[コンプライアンス機能](../administration/compliance/compliance_features.md)を提供しています。NIST 800-53に合わせた設定を行う前に、これらの基本的な機能を有効にする必要があります。

## コントロールファミリーごとの設定 {#configuration-by-control-family}

### システムおよびサービス取得 (SA) {#system-and-service-acquisition-sa}

GitLabは、開発ライフサイクル全体にセキュリティを統合する[DevSecOpsプラットフォーム](../devsecops.md)です。その核となる部分では、GitLabを使用してSAコントロールファミリーの幅広いコントロールに対応できます。

#### システム開発ライフサイクル {#system-development-lifecycle}

この要件の核となる部分を満たすためにGitLabを使用できます。GitLabは、作業を[整理](../user/project/organize_work_with_projects.md)し、[計画し、追跡できる](../topics/plan_and_track.md)プラットフォームを提供します。NIST 800-53では、アプリケーションの開発にセキュリティを組み込むことを義務付けています。[CI/CDパイプライン](../topics/build_your_application.md)を設定して、出荷時にコードを継続的にテストし、同時にセキュリティポリシーを適用できます。GitLabには、顧客アプリケーションの開発に組み込むことができるセキュリティツールスイートが含まれており、以下のようなものがあります:

- [セキュリティ設定](../user/application_security/detect/security_configuration.md)
- [コンテナスキャン](../user/application_security/container_scanning/_index.md)
- [依存関係スキャン](../user/application_security/dependency_scanning/_index.md)
- [静的アプリケーションセキュリティテスト](../user/application_security/sast/_index.md)
- [Infrastructure as Code（IaC）スキャン](../user/application_security/iac_scanning/_index.md)
- [シークレット検出](../user/application_security/secret_detection/_index.md)
- [DAST](../user/application_security/dast/_index.md)
- [APIファジング](../user/application_security/api_fuzzing/_index.md)
- [カバレッジガイドファズテスト](../user/application_security/coverage_fuzzing/_index.md)

CI/CDパイプラインに加えて、GitLabは[リリースを設定する方法に関する詳細なガイダンス](../user/project/releases/_index.md)を提供します。リリースはCI/CDパイプラインで作成でき、リポジトリ内の任意のソースコードブランチのスナップショットを取得します。リリース作成の指示は、[リリースを作成](../user/project/releases/_index.md#create-a-release)に含まれています。NIST 800-53またはFedRAMPのコンプライアンスにとって重要な考慮事項は、リリースされたコードの信頼性を検証し、システムおよび情報整合性 (SI) コントロールファミリーの要件を満たすために、コードに署名する必要がある場合があることです。

### アクセス制御 (AC) および識別と認証 (IA) {#access-control-ac-and-identification-and-authentication-ia}

GitLabデプロイにおけるアクセス管理は、顧客ごとに異なります。GitLabは、Identity Providerを使用したデプロイとGitLabネイティブの認証設定をカバーする幅広いドキュメントを提供しています。GitLabインスタンスへの認証のアプローチを決定する前に、組織の要件を考慮することが重要です。

#### Identity Provider {#identity-providers}

GitLabでのアクセスは、UIまたは既存のIdentity Providerとの統合によって管理できます。FedRAMPの要件を満たすには、既存のIdentity Providerが[FedRAMP Marketplace](https://marketplace.fedramp.gov/products)でFedRAMPによって承認されていることを確認してください。PIVなどの要件を満たすには、GitLab Self-Managedでネイティブ認証を使用するのではなく、Identity Providerを活用する必要があります。

GitLabは、様々なIdentity Providerとプロトコルを設定するためのリソースを提供しており、以下を含みます。

- [LDAP](../administration/auth/ldap/_index.md)

- [SAML](../integration/saml.md)

- Identity Providerの詳細については、[GitLabの認証と認可](../administration/auth/_index.md)を参照してください。

#### ネイティブGitLabユーザー認証設定 {#native-gitlab-user-authentication-configurations}

**Account management and classification** \- GitLabは、管理者が様々な機密性とアクセス要件を持つユーザーを追跡できるようにします。GitLabは、最小権限の原則とロールベースアクセスをサポートし、詳細なアクセスオプションを提供します。プロジェクトレベルでは、以下のロールがサポートされています。

- ゲスト

- レポーター

- デベロッパー

- メンテナー

- オーナー

[プロジェクトレベルの権限](../user/permissions.md#project-permissions)に関する追加の詳細は、ドキュメントで確認できます。GitLabは、独自の権限要件を持つ顧客向けに[カスタムロール](../user/custom_roles/_index.md)もサポートしています。

GitLabは、独自のユースケース向けに以下のユーザータイプもサポートしています:

- [監査担当者ユーザー](../administration/auditor_users.md) \- 監査担当者ユーザーロールは、**管理者**エリアとプロジェクト/グループ設定を除くすべてのグループ、プロジェクト、およびその他のリソースへの読み取り専用アクセスを提供します。プロセスを検証するために特定のプロジェクトへのアクセスを必要とするサードパーティの監査担当者と連携する場合に、監査担当者ロールを使用できます。

- [外部ユーザー](../administration/external_users.md) \- 外部ユーザーは、組織の一部ではない可能性のあるユーザーに限定的なアクセスを提供するように設定できます。通常、これは契約者やその他のサードパーティのアクセスを管理するために使用できます。IA-4(4)のようなコントロールでは、組織外のユーザーを会社の方針に従って識別し管理する必要があります。外部ユーザーを設定することで、デフォルトでプロジェクトへのアクセスを制限し、組織に雇用されていないユーザーを管理者が特定するのを支援することで、組織へのリスクを軽減できます。

- [サービスアカウント](../user/profile/service_accounts.md) \- サービスアカウントは、自動化されたタスクに対応するために追加できます。サービスアカウントは、ライセンスの下でシートを使用しません。

**管理者**エリア - **管理者**エリアでは、管理者は[権限をエクスポート](../administration/admin_area.md#user-permission-export)したり、[ユーザーIDをレビュー](../administration/admin_area.md#user-identities)したり、[グループを管理](../administration/admin_area.md#administering-groups)したり、その他多くのことができます。FedRAMP / NIST 800-53要件を満たすために使用できる機能は以下のとおりです:

- 侵害が疑われる場合に[ユーザーパスワードをリセット](reset_user_password.md)します。

- [ユーザーをロック解除](unlock_user.md)します。デフォルトでは、GitLabはサインイン失敗10回後にユーザーをロックします。ユーザーは10分間ロックされたままになるか、管理者がユーザーのロックを解除するまでロックされます。GitLab 16.5以降では、管理者は[API](../api/settings.md#available-settings)を使用して、最大ログイン試行回数とロックアウト状態が維持される期間を設定できます。AC-7のガイダンスによると、FedRAMPはアカウントロックアウトのパラメータを定義するためにNIST 800-63Bに準拠しており、これはデフォルト設定で満たされています。

- [不正使用レポート](../administration/review_abuse_reports.md)または[スパムログ](../administration/review_spam_logs.md)をレビューします。FedRAMPは、組織が異常な使用状況 (AC-2(12)) のアカウントをモニタリングすることを義務付けています。GitLabは、管理者が調査が保留されているアクセスを削除できる不正使用レポートで、ユーザーが不正使用を報告できるようにします。スパムログは、**スパムログ**セクションの**管理者**エリアに統合されています。管理者は、そのエリアでフラグが付けられたユーザーを削除、ブロック、または信頼できます。

- [パスワードストレージパラメータを設定](password_storage.md)します。保存されたシークレットは、SC-13で概説されているようにFIPS 140-2または140-3を満たす必要があります。FIPSモードが有効になっている場合、PBKDF2+SHA512はFIPS準拠した暗号でサポートされます。

- [認証情報インベントリ](../administration/credentials_inventory.md)を使用すると、管理者はGitLab Self-Managedインスタンスで使用されているすべてのシークレットを1か所でレビューできます。認証情報、トークン、およびキーの統合ビューは、パスワードのレビューや認証情報をローテーションするなどの要件を満たすのに役立ちます。

- [パスワードの複雑さの要件を変更](../administration/settings/sign_up_restrictions.md#modify-password-complexity-requirements)します。FedRAMPは、パスワード長要件を確立するためにIA-5のNIST 800-63Bに準拠しています。GitLabは8～128文字のパスワードをサポートしており、8文字がデフォルトとして設定されています。

- [デフォルトのセッション期間](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration) \- FedRAMPは、設定された期間非アクティブであったユーザーはログアウトされるべきであると定めています。FedRAMPは期間を特定していませんが、特権ユーザーについては標準的な作業期間の終わりにログアウトされるべきであると明確にしています。管理者は[デフォルトのセッション期間](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration)を確立できます。

- [新規ユーザーのプロビジョニング](../user/profile/account/create_accounts.md) \- 管理者は、**管理者**エリアUIを使用して、GitLabアカウントの新規ユーザーを作成できます。IA-5のコンプライアンスに基づき、GitLabは新規ユーザーに初回ログイン時にパスワードを変更するよう要求します。

- ユーザーの廃止 - 管理者は、[**管理者**エリアUIを使用してユーザーを削除](../user/profile/account/delete_account.md#delete-users-and-user-contributions)できます。ユーザーを削除する代わりに、[ユーザーをブロック](../administration/moderate_users.md#block-a-user)してすべてのアクセスを削除できます。ユーザーをブロックすると、すべてのアクセスが削除される一方で、リポジトリ内のデータは保持されます。ブロックされたユーザーはシート数に影響しません。

- ユーザーの非アクティブ化 - アカウントレビュー中に特定された非アクティブなユーザーは[一時的に非アクティブ化される](../administration/moderate_users.md#deactivate-a-user)場合があります。非アクティブ化はブロックに似ていますが、いくつかの重要な違いがあります。ユーザーを非アクティブ化しても、ユーザーがGitLabUIにサインインすることは禁止されません。非アクティブ化されたユーザーは、サインインすることで再びアクティブになれます。非アクティブ化されたユーザーは以下のとおりです:
  - リポジトリまたはAPIにアクセスできません。

  - スラッシュコマンドを使用できません。詳細については、スラッシュコマンドを参照してください。

  - シートを占有しません。

#### 追加の識別方法 {#additional-identification-methods}

**2要素認証** - [GitLabは以下の第2要素をサポート](../user/profile/account/two_factor_authentication.md)します:

- ワンタイムパスワード認証器

- WebAuthnデバイス

[2要素認証](../user/profile/account/two_factor_authentication.md#enable-two-factor-authentication)を有効にするための指示は、ドキュメントで提供されています。FedRAMPを追求する顧客は、FedRAMPの承認を受け、FIPS要件をサポートする2要素プロバイダーを考慮する必要があります。FedRAMPの承認を受けたプロバイダーは、[FedRAMP Marketplace](https://marketplace.fedramp.gov/products)でFedRAMPによって承認されていることを確認できます。第2要素を選択する際、NISTとFedRAMPは現在、WebAuthnのようなフィッシング耐性のある認証を使用する必要があることを示しています (IA-2)。

**SSHキー**

- GitLabは、Gitと認証して通信するためのSSHキーを設定する方法に関する[指示](../user/ssh.md)を提供します。[コミットは署名](../user/project/repository/signed_commits/ssh.md)でき、公開キーを持つ人に追加の検証を提供します。

- キーは、FIPS 140-2およびFIPS 140-3検証済み暗号の使用など、該当する強度および複雑さの要件を満たすように設定する必要があります。管理者は[最小キー技術とキー長を制限](ssh_keys_restrictions.md)できます。さらに、GitLabは[侵害されたキーをブロック](../user/ssh.md#add-an-ssh-key-to-your-gitlab-account)します。

**パーソナルアクセストークン**

GitLabは、パーソナルアクセストークンを設定および管理する方法に関する[指示](../user/profile/personal_access_tokens.md)を提供します。GitLabは[きめ細やかな権限](../auth/tokens/fine_grained_access_tokens.md)をサポートしており、これにより該当するユースケースに必要な権限のみにトークンのスコープを設定できます。

#### その他のアクセス制御ファミリーの概念 {#other-access-control-family-concepts}

**System Use Notifications**

連邦政府の要件では、多くの場合、ログイン時にバナーが必要であると概説されています。これは、Identity Providerと[GitLabバナー機能](../administration/broadcast_messages.md)を通じて設定できます。

**External Connections**

すべての外部接続をドキュメント化し、コンプライアンス要件を満たしていることを確認することが重要です。たとえば、サードパーティとのAPIインテグレーションを設定すると、そのサードパーティが顧客データをどのように保護するかによって、データ処理要件に違反する可能性があります。すべての外部接続をレビューし、有効にする前にそれらのセキュリティ上の影響を理解することが重要です。FedRAMPまたは同様の認証を追求する顧客の場合、他のFedRAMPによって承認されていないサービスや、データ影響レベルの低いサービスに接続すると、認可境界に違反する可能性があります。

**Personal Identity Verification (PIV)**

個人識別検証カードは、連邦政府の要件を満たす組織にとって必要となる場合があります。PIV要件を満たすために、GitLabは顧客がPIV対応のIDソリューションをSAMLと接続することを要求します。SAMLドキュメントへのリンクは、このガイドの以前のセクションで提供されています。

### 監査と責任 (AU) {#audit-and-accountability-au}

NIST 800-53は、セキュリティ関連イベントをモニタリングし、それらのイベントを分析し、アラートを生成し、アラートの重要度に応じてアラートを調査することを組織に義務付けています。GitLabは、セキュリティ情報およびイベント管理 (SIEM) ソリューションにルーティングできる、幅広い配列のセキュリティイベントをモニタリングのために提供します。

#### イベントタイプ {#event-types}

GitLabは、[設定可能な監査イベントログタイプ](../administration/compliance/audit_event_streaming.md)を概説しており、これらはデータベースにストリーミングおよび/または保存できます。管理者は、GitLabインスタンス用にキャプチャしたいイベントを設定できます。

**Log System**

GitLabには、すべてをログに記録できる高度なログシステムが含まれています。GitLabは、広範囲の出力を含む[ログシステム](../administration/logs/_index.md#importerlog)のログタイプに関するガイダンスを提供します。詳細については、リンクされたガイダンスをレビューしてください。

ストリーミングイベント

GitLab管理者は、[イベントストリーミング機能](../user/compliance/audit_event_streaming.md)を使用して、監査イベントをSIEMまたはその他のストレージ場所にストリーミングできます。管理者は、複数の宛先を設定し、イベントヘッダーを設定できます。GitLabは、HTTPおよびHTTPSイベントのヘッダー、ペイロードなどを概説するイベントストリーミングの[例](../user/compliance/audit_event_schema.md)を提供します。

管理者がFedRAMPまたはNIST 800-53 AU-2要件をレビューし、必要な監査イベントタイプにマップする監査イベントを実装することが重要です。AU-2は以下のイベントバケットを識別します:

- アカウントログオンの成功および失敗イベント

- アカウント管理イベント

- オブジェクトアクセス

- ポリシー変更

- 特権機能

- プロセス追跡

- システムイベント

- ウェブアプリケーションの場合:

  - すべての管理者アクティビティ

  - 認証チェック

  - 認可チェック

  - データ削除

  - データアクセス

  - データ変更

  - 権限変更

管理者は、GitLabでイベントを有効にする際に、必要なイベントタイプと追加の組織要件の両方を考慮する必要があります。

**メトリクス**

セキュリティイベントとは別に、管理者はアップタイムをサポートするためにアプリケーションのパフォーマンスへの可視性を必要とする場合もあります。GitLabは、GitLabインスタンスでサポートされている[メトリクスに関する堅牢なドキュメントセット](../administration/monitoring/_index.md)を提供します。

**ストレージ**

顧客は、ログがコンプライアンス要件を満たす長期ストレージソリューションに保存されることを確認する責任があります。たとえば、FedRAMPでは、ログを1年間保存することを義務付けています。顧客組織は、収集されたデータの影響に応じて、国立公文書館および記録管理局の要件を満たす必要もあるかもしれません。収集された記録の影響をレビューし、適用されるコンプライアンス要件を理解することが重要です。

### インシデント対応 (IR) {#incident-response-ir}

監査イベントが設定されると、それらのイベントはモニタリングされる必要があります。GitLabは、SIEMまたはその他のセキュリティツールからのシステムアラートをコンパイルし、アラートとインシデントをトリアージし、利害関係者に情報を提供する一元化された管理インターフェースを提供します。[インシデント管理ドキュメント](../operations/incident_management/_index.md)は、セキュリティインシデント対応組織で前述の活動を実行するためにGitLabをどのように使用できるかを概説しています。

**Incident Response Lifecycle**

GitLabは、組織のインシデント対応ライフサイクル全体を管理できます。インシデント対応要件を満たすのに役立つ可能性のある以下のリソースをレビューしてください:

- [アラート](../operations/incident_management/alerts.md)

- [インシデント](../operations/incident_management/incidents.md)

- [オンコールスケジュール](../operations/incident_management/oncall_schedules.md)

- [ステータスページ](../operations/incident_management/status_page.md)

### 設定管理 (CM) {#configuration-management-cm}

**Change Control**

GitLabは、その核となる部分で、変更管理に関連する設定管理要件を満たすことができます。イシューとマージリクエストは、変更をサポートするための主要な方法です。

イシューは、変更を実装する前にメタデータと承認をキャプチャするための柔軟なプラットフォームです。GitLabの機能が設定管理コントロールを満たすためにどのように使用できるかを完全に理解するために、[作業の計画と追跡](../topics/plan_and_track.md)に関するGitLabドキュメントをレビューすることを検討してください。

マージリクエストは、ソースブランチからターゲットブランチへの変更を標準化する方法を提供します。NIST 800-53のコンテキストでは、コードをマージする前に承認をどのように収集すべきか、および組織内で誰がコードをマージする能力を持っているかを考慮することが重要です。GitLabは、[マージリクエストの承認で利用可能な様々な設定](../user/project/merge_requests/approvals/_index.md)に関するガイダンスを提供します。必要なレビューが完了した後、承認およびマージ権限を適切なロールにのみ割り当てることを検討してください。考慮すべき追加のマージ設定は以下のとおりです:

- コミットが追加された場合にすべての承認を削除する - 新しいコミットがマージリクエストに対して行われたときに承認が引き継がれないようにします。

- コード変更レビューを無視することができる個人を制限します。

- 機密情報コードまたは設定がマージリクエストを通じて変更されたときに通知されるように[コードオーナー](../user/project/codeowners/_index.md#codeowners-file)を割り当てます。

- [すべてのオープンなコメントがコード変更のマージを許可する前に解決されていることを確認](../user/project/merge_requests/_index.md#prevent-merge-unless-all-threads-are-resolved)します。

- [プッシュルールを設定](../user/project/repository/push_rules.md)する - プッシュルールは、署名されたコードのレビュー、ユーザーの検証などの要件を満たすように設定できます。

**Testing and Validation of Changes**

[CI/CDパイプライン](../topics/build_your_application.md)は、変更のテストと検証の重要なコンポーネントです。特定のユースケースに対して十分なテストおよび検証パイプラインを実装する責任は顧客にあります。サービスを選択する際には、そのパイプラインがどこで実行されるかを考慮してください。外部サービスに接続すると、連邦データが保存および処理されることが許可されている確立された認可境界に違反する可能性があります。GitLabは、FIPS対応システムで実行するように設定されたRunnerコンテナイメージを提供します。GitLabは、[保護ブランチを設定](../user/project/repository/branches/protected.md)する方法や[パイプラインセキュリティを実装](../ci/pipelines/_index.md#pipeline-security-on-protected-branches)する方法など、パイプラインの強化ガイダンスを提供します。さらに、顧客はコードを更新する前に、すべてのチェックがパスしたことを確認するために、コードをマージする前に[必須チェックを割り当て](../user/project/merge_requests/status_checks.md)ることを検討するかもしれません。

**Component Inventory**

NIST 800-53は、クラウドプロバイダーがコンポーネントインベントリを維持することを義務付けています。GitLabは基盤となるハードウェアを直接追跡することはできませんが、コンテナスキャンと依存関係スキャンを通じてソフトウェアインベントリを生成できます。GitLabは、[コンテナスキャンと依存関係スキャンが検出できる依存関係](../user/application_security/comparison_dependency_and_container_scanning.md)を概説しています。GitLabは、依存関係リストの生成に関する追加のドキュメントを提供しており、これは[ソフトウェアコンポーネントインベントリ](../user/application_security/dependency_list/_index.md)で使用できます。ソフトウェア部品表は、このドキュメントの後半の「サプライチェーンリスク管理」の下でカバーされています。

**コンテナレジストリ**

GitLabは、GitLabプロジェクト用のコンテナイメージを保存するための統合されたコンテナレジストリを提供します。これは、高度に仮想化されたスケーラブルな環境でコンテナをデプロイするための信頼できるリポジトリとして使用できます。[コンテナレジストリの管理ガイダンス](../administration/packages/container_registry.md)はレビューできます。

### 緊急時計画 (CP) {#contingency-planning-cp}

GitLabは、コアの緊急時計画要件を満たすのに役立つガイダンスとサービスを提供します。含まれているドキュメントをレビューし、緊急時計画活動の組織要件を満たすために適切に計画することが重要です。緊急時計画は各組織に固有のものであるため、緊急時計画を確立する前に組織のニーズを考慮することが重要です。

**Selecting a GitLab Architecture**

GitLabは、GitLab Self-Managedインスタンスでサポートされているアーキテクチャに関する広範なドキュメントを提供しています。GitLabは以下のクラウドプロバイダーをサポートしています:

- [Azure](../install/azure/_index.md)

- [Google Cloud Platform](../install/google_cloud_platform/_index.md)

- [Amazon Web Services](../install/aws/_index.md)

GitLabは、[顧客がリファレンスアーキテクチャと可用性モデルを選択するのを支援するための意思決定ツリー](../administration/reference_architectures/_index.md#decision-tree)を提供します。ほとんどのクラウドプロバイダーは、マネージドサービス向けにリージョンで回復性を提供します。アーキテクチャを選択する際には、組織のダウンタイム許容度とデータの重要性を考慮することが重要です。追加のレプリケーションおよびフェイルオーバー機能のためにGitLab Geoを検討できます。

**Identify Critical Assets**

NIST 800-53は、停止中の優先的な復元を確実にするために、重要な資産の識別を要求します。考慮すべき重要な資産には、GitalyノードとPostgreSQLデータベースが含まれます。顧客は、必要に応じてバックアップまたはレプリケーションが必要な追加の資産を特定する必要があります。

**バックアップ**

ドキュメントは、以下を含む重要なコンポーネントのバックアップ戦略を概説しています:

- [PostgreSQLデータベース](../administration/backup_restore/backup_gitlab.md#postgresql-databases)

- [Gitリポジトリ](../administration/backup_restore/backup_gitlab.md#git-repositories)

- [blob](../administration/backup_restore/backup_gitlab.md#blobs)

- [コンテナレジストリ](../administration/backup_restore/backup_gitlab.md#container-registry)

- [Redis](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/#backing-up-redis-data)

- [設定ファイル](../administration/backup_restore/backup_gitlab.md#storing-configuration-files)

- [Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html)

GitLab Geo

GitLab Geoは、NIST 800-53のコンプライアンスを追求する実装の重要なコンポーネントとなるでしょう。各ユースケースに対してGeoが適切に設定されていることを確認するために、[利用可能なドキュメント](../administration/geo/_index.md)をレビューすることが重要です。

Geoを実装すると、以下の利点が得られます:

- 分散開発者が大規模なリポジトリとプロジェクトをクローンおよびフェッチするのにかかる時間を数分から数秒に短縮します。

- 開発者が地域を越えてアイデアをコントリビュートするし、並行して作業できるようにします。

- プライマリサイトとセカンダリサイト間の読み取り専用負荷のバランスを取ります。

- プロジェクトのクローン作成とフェッチ、およびGitLabウェブインターフェースで利用可能なデータの読み取りに使用できます (制限事項を参照)。

- 遠隔地のオフィス間の遅い接続を克服し、分散チームの速度を向上させることで時間を節約します。

- 自動化されたタスク、カスタムインテグレーション、および内部ワークフローの読み込み時間を短縮するのに役立ちます。

- ディザスターリカバリーシナリオで、セカンダリサイトに迅速にフェイルオーバーできます。

- 計画的なセカンダリサイトへのフェイルオーバーを可能にします。

Geoは以下のコア機能を提供します:

- 読み取り専用セカンダリサイト: 分散チーム向けに読み取り専用セカンダリサイトを有効にしながら、1つのプライマリGitLabサイトを維持します。

- 認証システムフック: セカンダリサイトは、すべての認証データ（ユーザーアカウントやログインなど）をプライマリインスタンスから受け取ります。

- 直感的なUI: セカンダリサイトは、プライマリサイトと同じウェブインターフェースを使用します。さらに、書き込み操作をブロックし、ユーザーがセカンダリサイトにいることを明確にする視覚的な通知があります。

追加のGeoリソース:

- [Geoをセットアップする](../administration/geo/setup/_index.md)

- [Geoを実行するための要件](../administration/geo/_index.md#requirements-for-running-geo)

- [Geoの制限](../administration/geo/_index.md)

- [Geoのディザスターリカバリー手順](../administration/geo/disaster_recovery/_index.md)

**PostgreSQL**

GitLabは、[レプリケーションとフェイルオーバーを使用してPostgreSQLクラスターを設定する方法に関するガイダンス](../administration/postgresql/replication_and_failover.md)を提供します。データの重要性とGitLabインスタンスの最大許容ダウンタイムに応じて、レプリケーションとフェイルオーバーを有効にしたPostgreSQLの設定を検討してください。

**Gitaly**

Gitalyを設定する際には、可用性、回復性、および弾力性の間のトレードオフを考慮してください。GitLabは、NIST 800-53要件を満たす正しい設定を決定するのに役立つ[Gitaly機能](../administration/gitaly/gitaly_geo_capabilities.md)に関する広範なドキュメントを提供します。

### 計画 (PL) {#planning-pl}

計画コントロールファミリーには、ポリシー、手順、その他の管理されたドキュメントの維持が含まれます。管理されたドキュメントのライフサイクルを管理するためにGitLabを活用することを検討してください。たとえば、管理されたドキュメントは、バージョン管理された状態で[Markdown](../user/markdown.md)に保存できます。ドキュメントへの変更はすべて、組織の承認ルールを強制するマージリクエストを通じて行われる必要があります。マージリクエストは、管理されたドキュメントに対して行われた変更の明確な履歴を提供します。これは、ドキュメントオーナーなどの適切な担当者による年次レビューと承認を実証するために、監査中に使用できます。

### リスク評価およびシステムと情報整合性 (RA) {#risk-assessment-and-system-and-information-integrity-ra}

#### スキャン {#scanning}

NIST 800-53は、脆弱性の継続的なモニタリングと欠陥の修正を義務付けています。インフラストラクチャスキャンに加えて、FedRAMPのようなコンプライアンスフレームワークは、コンテナとDASTスキャンを月次報告要件のスコープに含めています。GitLabは、[コンテナスキャンをサポートできるセキュリティツール](../user/application_security/container_scanning/_index.md)を提供しており、[Trivy](https://github.com/aquasecurity/trivy)や[Grype](https://github.com/anchore/grype)スキャナーが含まれます。さらに、GitLabは[依存関係スキャン機能](../user/application_security/dependency_scanning/_index.md)を提供します。GitLabのDASTは、ウェブアプリケーションスキャン要件を満たすために使用できます。[GitLabDAST](../user/application_security/dast/_index.md)は、パイプラインで実行され、実行中のウェブアプリケーションの脆弱性レポートを生成するように設定できます。

アプリケーションコードを保護および管理するために使用できる追加のセキュリティ機能は以下のとおりです:

- [静的アプリケーションセキュリティテスト（SAST）](../user/application_security/sast/_index.md)

- [シークレット検出](../user/application_security/secret_detection/_index.md)

- [APIセキュリティ](../user/application_security/api_security/_index.md)

#### パッチ管理 {#patch-management}

GitLabは、[リリースおよびメンテナンスポリシー](../policy/maintenance.md)をドキュメントに記載しています。GitLabインスタンスをアップグレードする前に、利用可能なガイダンスをレビューしてください。これは[アップグレードの計画](../update/plan_your_upgrade.md) 、[ダウンタイムなしでのアップグレード](../update/zero_downtime.md) 、およびその他の[アップグレードパス](../update/upgrade_paths.md)に役立ちます。

[セキュリティダッシュボード](../user/application_security/security_dashboard/_index.md)は、脆弱性データを経時的に追跡するように設定でき、脆弱性管理プログラムのトレンドを特定するために使用できます。

### サプライチェーンリスク管理 (SR) {#supply-chain-risk-management-sr}

#### ソフトウェア部品表 {#software-bill-of-materials}

GitLab依存関係スキャナーとコンテナスキャナーは、SBOMの生成をサポートします。コンテナおよび依存関係スキャンでSBOMレポートを有効にすると、顧客組織は自身のソフトウェアサプライチェーンとソフトウェアコンポーネントに関連する固有のリスクを理解できるようになります。GitLabスキャナーは[CycloneDX形式のレポートをサポート](../ci/yaml/artifacts_reports.md#artifactsreportsdotenv)します。

### システムおよび通信保護 (SC) {#system-and-communication-protection-sc}

#### FIPSコンプライアンス {#fips-compliance}

NIST 800-53に基づくコンプライアンスプログラム（FedRAMPなど）では、適用されるすべての暗号学的モジュールにFIPSコンプライアンスが要求されます。GitLabは、FIPSバージョンのコンテナイメージをリリースし、FIPSコンプライアンス標準を満たすようにGitLabを設定する方法に関するガイダンスを提供しています。特定の機能はFIPSモードでは利用できないか、サポートされていません。

GitLabはFIPS準拠したイメージを提供していますが、基盤となるインフラストラクチャを設定し、FIPS検証済み暗号が強制されていることを確認するために環境を評価する責任は顧客にあります。

### システムおよび情報整合性 (SI) {#system-and-information-integrity-si}

#### セキュリティアラート、アドバイザリ、および指令 {#security-alerts-advisories-and-directives}

GitLabは、ソフトウェアと依存関係に関連するセキュリティ脆弱性を追跡するための[アドバイザリデータベース](../user/application_security/gitlab_advisory_database/_index.md)を維持しています。GitLabはCVE採番機関 (CNA) です。[CVE IDリクエスト](../user/application_security/cve_id_request.md)の生成については、このページを参照してください。

#### メール {#email}

GitLabは、GitLabアプリケーションインスタンスからユーザーへの[メール通知の送信](../administration/email_from_gitlab.md#sending-emails-to-users-from-gitlab)をサポートしています。DHS BOD 18-01ガイダンスは、スパム保護として送信メッセージ用にドメインベースのメッセージ認証、レポート、および適合性 (DMARC) を設定する必要があることを示しています。GitLabは、幅広いメールプロバイダーにわたる[SMTPの設定ガイダンス](https://docs.gitlab.com/omnibus/settings/smtp/)を提供しており、これはこの要件を満たすのに役立つ可能性があります。

### その他のサービスと概念 {#other-services-and-concepts}

#### Runner {#runners}

どのようなGitLabデプロイにおいても、様々なタスクとツールのためにRunnerが必要です。データ境界要件を維持するために、顧客は認可境界内に[セルフマネージドRunner](https://docs.gitlab.com/runner/)をデプロイする必要があるかもしれません。GitLabは、[Runnerの設定](../ci/runners/configure_runners.md)に関する詳細情報を提供しており、以下のような概念が含まれます:

- 最大ジョブタイムアウト

- 機密情報の保護

- 長時間のポーリングの設定

- 認証トークンセキュリティとトークンローテーション

- 機密情報の漏洩防止

- Runner変数

#### APIの活用 {#leveraging-apis}

GitLabは、アプリケーションをサポートするために堅牢なAPIセットを提供しており、[REST](../api/rest/_index.md) APIと[GraphQL](../api/graphql/_index.md)APIが含まれます。APIの保護は、APIエンドポイントを呼び出すユーザーとジョブの認証の適切な設定から始まります。GitLabは、アクセスを制御するためにアクセストークン（FIPSでサポートされていないパーソナルアクセストークン）とOAuth 2.0トークンを設定することを推奨します。

#### 拡張機能 {#extensions}

確立されているインテグレーションに応じて、[拡張機能](../editor_extensions/_index.md)はNIST 800-53要件を満たす場合があります。たとえば、エディタとIDEの拡張機能は許容される可能性がありますが、サードパーティとのインテグレーションは認可境界要件に違反する可能性があります。顧客の認可境界外にデータがどこに送信されているかを理解するために、すべての拡張機能を検証する責任は顧客にあります。

### 追加リソース {#additional-resources}

GitLabは、GitLab Self-Managed顧客向けに[強化ガイド](hardening.md)を提供しており、以下のようなトピックをカバーしています:

- [アプリケーションの強化に関する推奨事項](hardening_application_recommendations.md)

- [CI/CDの強化に関する推奨事項](hardening_cicd_recommendations.md)

- [設定に関する推奨事項](hardening_configuration_recommendations.md)

- [オペレーティングシステムの推奨事項](hardening_operating_system_recommendations.md)

GitLabCISベンチマークガイド - GitLabは、アプリケーションにおける強化の決定を導くために[CISベンチマーク](https://about.gitlab.com/blog/gitlab-introduces-new-cis-benchmark-for-improved-security/)を公開しています。これは、このガイドと連携して環境をNIST 800-53コントロールに準拠して強化するために使用できます。CISベンチマークのすべての提案がNIST 800-53コントロールに直接一致するわけではありませんが、GitLabインスタンスを維持するためのベストプラクティスとして機能します。
