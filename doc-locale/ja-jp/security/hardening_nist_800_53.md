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

このページは、該当するNIST 800-53コントロールを満たすようにGitLab Self-Managedインスタンスを構成したいGitLab管理者を対象としたリファレンスです。管理者が持つ可能性のあるさまざまな要件があるため、GitLabは特定の設定ガイダンスを提供していません。NIST 800-53セキュリティコントロールを満たすGitLabインスタンスをデプロイする前に、技術的な詳細について顧客ソリューションアーキテクトと協力する必要があります。

## スコープ {#scope}

このページは、NIST 800-53コントロールファミリーの構成に従っています。このページのスコープは、主にGitLab自体に対して行われた構成に限定されているため、すべてのコントロールファミリーが適用されるわけではありません。構成の詳細は、プラットフォームに依存しないように意図されています。

GitLabのガイダンスは、完全にコンプライアンスなシステムを構成するものではありません。政府のデータを処理する前に、以下を行う必要があります:

- テクノロジースタック全体の追加の構成と強化を計画します。
- セキュリティ構成の独立した評価を検討します。
- [サポートされているクラウドプロバイダー](../install/cloud_providers.md)間のデプロイの違いを理解し、利用可能な場合は特定のガイダンスに従ってください。

## コンプライアンス機能 {#compliance-features}

GitLabは、GitLabで重要なコントロールとワークフローを自動化するために使用できる、いくつかの[コンプライアンス機能](../administration/compliance/compliance_features.md)を提供しています。NIST 800-53に準拠した構成を行う前に、これらの基本的な機能を有効にする必要があります。

## コントロールファミリー別の構成 {#configuration-by-control-family}

### システムおよびサービス取得（SA） {#system-and-service-acquisition-sa}

GitLabは、開発ライフサイクル全体でセキュリティを統合する[DevSecOpsプラットフォーム](../devsecops.md)です。そのコアにおいて、GitLabを使用して、SAコントロールファミリーの広範なコントロールに対応できます。

#### システム開発ライフサイクル {#system-development-lifecycle}

GitLabを使用して、この要件の中核を満たすことができます。GitLabは、作業を[整理](../user/project/organize_work_with_projects.md)し、[計画および追跡](../topics/plan_and_track.md)できるプラットフォームを提供します。NIST 800-53では、アプリケーションの開発にセキュリティを組み込む必要があります。[CI/CDパイプライン](../topics/build_your_application.md)を構成して、コードの出荷中に継続的にテストし、セキュリティポリシーを同時に適用できます。GitLabには、以下を含むがこれらに限定されない、顧客アプリケーションの開発に組み込むことができる一連のセキュリティツールが含まれています:

- [セキュリティ設定](../user/application_security/detect/security_configuration.md)
- [コンテナスキャン](../user/application_security/container_scanning/_index.md)
- [依存関係スキャン](../user/application_security/dependency_scanning/_index.md)
- [静的アプリケーションセキュリティテスト](../user/application_security/sast/_index.md)
- [Infrastructure as Code（IaC）スキャン](../user/application_security/iac_scanning/_index.md)
- [シークレット検出](../user/application_security/secret_detection/_index.md)
- [動的アプリケーションセキュリティテスト（DAST）](../user/application_security/dast/_index.md)
- [APIファジング](../user/application_security/api_fuzzing/_index.md)
- [カバレッジガイドファズテスト](../user/application_security/coverage_fuzzing/_index.md)

CI/CDパイプラインを超えて、GitLabは[リリースの構成方法に関する詳細なガイダンス](../user/project/releases/_index.md)を提供します。リリースはCI/CDパイプラインで作成でき、リポジトリ内のソースブランチのスナップショットを取得できます。リリースの作成手順は、[リリースの作成](../user/project/releases/_index.md#create-a-release)に含まれています。NIST 800-53またはFedRAMPコンプライアンスに関する重要な考慮事項は、リリースされたコードが署名されてコードの信頼性を検証し、システムおよび情報完全性（SI）コントロールファミリーの要件を満たす必要がある場合があることです。

### アクセス制御（AC）およびIDと認証（IA） {#access-control-ac-and-identification-and-authentication-ia}

GitLabデプロイでのアクセス管理は、顧客ごとに異なります。GitLabは、Identity ProviderとGitLabネイティブの認証構成を使用したデプロイを対象とするさまざまなドキュメントを提供します。GitLabインスタンスへの認証へのアプローチを決定する前に、組織の要件を検討することが重要です。

#### Identity Provider {#identity-providers}

GitLabへのアクセスは、UIを使用するか、既存のIdentity Providerと統合することで管理できます。FedRAMP要件を満たすには、既存のIdentity Providerが[FedRAMP Marketplace](https://marketplace.fedramp.gov/products)でFedRAMPの認可を受けていることを確認してください。PIVなどの要件を満たすには、GitLab Self-Managedインスタンスでネイティブ認証を使用するのではなく、PIV対応のIdentity Providerを活用する必要があります。

GitLabは、以下を含む、さまざまなIdentity Providerとプロトコルを構成するためのリソースを提供します。

- [LDAP](../administration/auth/ldap/_index.md)

- [SAML](../integration/saml.md)

- Identity Providerの詳細については、[GitLabの認証と認可](../administration/auth/_index.md)を参照してください。

#### ネイティブGitLabユーザー認証の構成 {#native-gitlab-user-authentication-configurations}

**Account management and classification**（アカウント管理と分類） - 管理者は、GitLabを使用して、機密性とアクセスの要件が異なるユーザーを追跡できます。GitLabは、きめ細かいアクセスを提供することで、最小限の特権とロールベースのアクセスの概念をサポートします。プロジェクトレベルでは、次のロールがサポートされています

- ゲスト

- レポーター

- デベロッパー

- メンテナー

- オーナー

[プロジェクトレベルの権限](../user/permissions.md#project-members-permissions)の詳細については、ドキュメントを参照してください。GitLabは、独自の権限要件を持つ顧客向けに[カスタムロール](../user/custom_roles/_index.md)もサポートしています。

GitLabは、独自のユースケースに合わせて、次のユーザータイプもサポートしています:

- [監査担当者ユーザー](../administration/auditor_users.md) \- 監査担当者ロールは、**管理者**エリアとプロジェクト/グループ設定を除く、すべてのグループ、プロジェクト、その他のリソースへの読み取り専用アクセスを提供します。プロセスを検証するために特定のプロジェクトへのアクセスを必要とするサードパーティの監査担当者と連携する場合は、監査担当者ロールを使用できます。

- [外部ユーザー](../administration/external_users.md) \- 外部ユーザーは、組織の一部ではない可能性のあるユーザーに制限付きアクセスを提供するように設定できます。通常、これは、コントラクターまたはその他のサードパーティのアクセスを管理するために使用できます。IA-4（4）などのコントロールでは、組織外のユーザーを会社のポリシーに従って識別および管理する必要があります。外部ユーザーを設定すると、デフォルトでプロジェクトへのアクセスが制限され、組織に雇用されていないユーザーを管理者が識別できるようになるため、組織のリスクを軽減できます。

- [サービスアカウント](../user/profile/service_accounts.md) \- 自動化されたタスクに対応するために、サービスアカウントを追加できます。サービスアカウントは、ライセンスに基づいてシートを使用しません。

**管理者**エリア - **管理者**エリアでは、管理者は、[権限をエクスポートする](../administration/admin_area.md#user-permission-export) 、[ユーザーIDを確認する](../administration/admin_area.md#user-identities) 、[グループを管理する](../administration/admin_area.md#administering-groups)など、さまざまなことができます。FedRAMP / NIST 800-53要件を満たすために使用できる機能:

- 侵害の疑いがある場合は、[ユーザーパスワードをリセット](reset_user_password.md)します。

- [ユーザーのロックを解除](unlock_user.md)します。デフォルトでは、GitLabはサインインの試行が10回失敗するとユーザーをロックします。ユーザーは10分間ロックされたままになるか、管理者がユーザーのロックを解除するまでロックされたままになります。GitLab 16.5以降では、管理者は[APIを使用](../api/settings.md#available-settings)して、ログイン試行の最大回数とロックアウトされたままになる期間を構成できます。AC-7の指針に従い、FedRAMPはアカウントロックアウトのパラメータ定義についてNIST 800-63Bに委ねており、デフォルト設定がその要件を満たしています。

- [不正行為レポート](../administration/review_abuse_reports.md)または[スパムログ](../administration/review_spam_logs.md)を確認します。FedRAMPでは、組織はアカウントの非定型的な使用状況をモニタリングする必要があります（AC-2（12））。GitLabを使用すると、ユーザーは不正行為レポートで不正使用にフラグを立てることができ、管理者は調査が保留されているアクセス権を削除できます。スパムログは、**スパムログ**セクションの**管理者**エリアに統合されています。管理者は、そのエリアでフラグが設定されたユーザーを削除、ブロック、または信頼できます。

- [パスワードストレージパラメータを設定](password_storage.md)します。保存されたシークレットは、SC-13で概説されているように、FIPS 140-2または140-3を満たす必要があります。FIPSモードが有効になっている場合、PBKDF2 + SHA512は、FIPSコンプライアンスの暗号化方式でサポートされます。

- [認証情報インベントリ](../administration/credentials_inventory.md)を使用すると、管理者は、GitLab Self-Managedインスタンスで使用されているすべてのシークレットを1か所で確認できます。認証情報、トークン、およびキーの統合されたビューは、パスワードの確認や認証情報をローテーションするなどの要件を満たすのに役立ちます。

- [パスワード長の制限を設定](password_length_limits.md)します。FedRAMPは、IA-5のNIST 800-63Bに委ねてパスワード長の要件を確立します。GitLabは8〜128文字のパスワードをサポートしており、デフォルトでは8文字が設定されています。GitLabは、[最小パスワード長を更新する手順](password_length_limits.md#modify-minimum-password-length)をGitLab UIで提供しており、より長いパスワードの適用に関心のある組織はこれを使用できます。さらに、GitLab Self-Managedインスタンスの顧客は、[複雑さの要件を構成](../administration/settings/sign_up_restrictions.md#password-complexity-requirements)することがあります**管理者**エリアUIを使用します。

- [デフォルトのセッション期間](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration) \- FedRAMPでは、設定された期間非アクティブだったユーザーはログアウトさせる必要があると定めています。FedRAMPはこの期間を明示的に指定していませんが、特権ユーザーについては標準的な作業期間の終了時にログアウトさせる必要があるとしています。管理者は、[デフォルトのセッション期間](../administration/settings/account_and_limit_settings.md#customize-the-default-session-duration)を確立できます。

- [新しいユーザーのプロビジョニング](../user/profile/account/create_accounts.md) \- 管理者は、**管理者**エリアUIを使用して、GitLabアカウントの新しいユーザーを作成できます。IA-5に準拠して、GitLabでは、新しいユーザーは最初のログイン時にパスワードを変更する必要があります。

- ユーザーのデプロビジョニング - 管理者は、[**管理者**エリアUIを使用してユーザーを削除](../user/profile/account/delete_account.md#delete-users-and-user-contributions)できます。ユーザーを削除する代わりに、[ユーザーをブロックする](../administration/moderate_users.md#block-a-user)して、すべてのアクセス権を削除することもできます。ユーザーをブロックすると、すべてのアクセス権を削除しながら、リポジトリにデータが保持されます。ブロックされたユーザーは、シート数に影響しません。

- ユーザーの非アクティブ化 - アカウントレビュー中に識別された非アクティブなユーザーは、[一時的に非アクティブ化される](../administration/moderate_users.md#deactivate-a-user)可能性があります。非アクティブ化はブロックに似ていますが、いくつかの重要な違いがあります。ユーザーを非アクティブ化しても、ユーザーがGitLab UIにサインインすることが禁止されるわけではありません。非アクティブ化されたユーザーは、サインインすることで再びアクティブになることができます。非アクティブ化されたユーザー:
  - リポジトリまたはAPIにアクセスできません。

  - スラッシュコマンドを使用できません。詳細については、スラッシュコマンドを参照してください。

  - シートを占有しません。

#### 追加の識別方法 {#additional-identification-methods}

**2要素認証** - [GitLabは、次のセカンドファクタをサポートしています](../user/profile/account/two_factor_authentication.md):

- ワンタイムパスワード認証アプリ

- WebAuthnデバイス

[2要素認証を有効にする手順](../user/profile/account/two_factor_authentication.md#enable-two-factor-authentication)は、ドキュメントに記載されています。FedRAMPへの対応を進める顧客は、FedRAMPの認可を受けており、かつFIPS要件をサポートしている2要素認証プロバイダーを検討する必要があります。FedRAMPの認可を受けたプロバイダーは、[FedRAMP Marketplace](https://marketplace.fedramp.gov/products)で確認できます。NISTおよびFedRAMPは現在、第2要素の選択にあたって、WebAuthnなどのフィッシング耐性のある認証方式を使用する必要があることを示しています（IA-2）。

**SSHキー**

- GitLabは、SSHキーを構成してGitと認証および通信する方法について[手順を提供します](../user/ssh.md)。[コミットは署名](../user/project/repository/signed_commits/ssh.md)でき、公開キーを持つ人に追加の検証を提供します。

- キーは、FIPS 140-2およびFIPS 140-3で検証された暗号を使用して、該当する強度と複雑さの要件を満たすように構成する必要があります。管理者は、[最小キーテクノロジーとキー長を制限](ssh_keys_restrictions.md)できます。さらに、管理者は[侵害されたキーをブロックまたはBAN](ssh_keys_restrictions.md#block-banned-or-compromised-keys)できます。

**パーソナルアクセストークン**

ユーザーアクセス用のパーソナルアクセストークンは、FIPSが有効なインスタンスではデフォルトで無効になっています。

#### その他のアクセス制御ファミリーの概念 {#other-access-control-family-concepts}

**System Use Notifications**（システム使用通知）

連邦政府の要件では、多くの場合、ログイン時にバナーが必要であることが概説されています。これは、Identity Providerと[GitLabバナー機能](../administration/broadcast_messages.md)を使用して構成できます。

**External Connections**（外部接続）

すべての外部接続をドキュメント化し、それらがコンプライアンス要件を満たしていることを確認することが重要です。たとえば、サードパーティとのAPIインテグレーションを設定すると、そのサードパーティが顧客データを保護する方法によっては、データ処理要件に違反する可能性があります。すべての外部接続を確認し、有効にする前にセキュリティへの影響を理解することが重要です。FedRAMPなどの認証取得を目指す顧客は、FedRAMPの認可を受けていない他のサービスや、より低いデータ影響レベルのサービスに接続すると、認可境界に違反する可能性があります。

**Personal Identity Verification (PIV)**（個人識別検証（PIV））

個人識別検証カードは、連邦政府の要件を満たす組織の要件である可能性があります。PIV要件を満たすために、GitLabでは、顧客がPIV対応のIDソリューションをSAMLに接続する必要があります。SAMLのドキュメントへのリンクは、このガイドの前半に記載されています。

### 監査と責任（AU） {#audit-and-accountability-au}

NIST 800-53では、組織はセキュリティ関連イベントをモニタリングし、それらのイベントを分析し、アラートを生成し、アラートの重大度に応じてアラートを調査する必要があります。GitLabは、セキュリティ情報およびイベント管理（SIEM）ソリューションにルーティングできるモニタリング用の幅広いセキュリティイベントを提供します。

#### イベントタイプ {#event-types}

GitLabは、[構成可能な監査イベントログタイプ](../administration/compliance/audit_event_streaming.md)の概要を示しており、ストリーミングしたり、データベースに保存したりできます。管理者は、GitLabインスタンスに対してキャプチャするイベントを構成できます。

**Log System**（ログシステム）

GitLabには、すべてをログに記録できる高度なログシステムが含まれています。GitLabは、広範な出力を含む[ログシステムのガイダンス](../administration/logs/_index.md#importerlog)ログタイプを提供しています。詳細については、リンクされたガイダンスを確認してください。

イベントのストリーミング

GitLab管理者は、[イベントストリーミング機能](../user/compliance/audit_event_streaming.md)を使用して、監査イベントをSIEMまたはその他のストレージの場所にストリーミングできます。管理者は、複数の宛先を構成し、イベントヘッダーを設定できます。GitLabは、HTTPおよびHTTPSイベントのヘッダー、ペイロードなどを概説する、イベントストリーミングの[例を提供](../user/compliance/audit_event_schema.md)します。

管理者は、FedRAMPまたはNIST 800-53 AU-2の要件を確認し、必要な監査イベントタイプにマップする監査イベントを実装することが重要です。AU-2は、次のイベントバケットを識別します:

- アカウントログオンイベントの成功と失敗

- アカウント管理イベント

- オブジェクトアクセス

- ポリシー変更

- 特権機能

- プロセスの追跡

- システムイベント

- Webアプリケーションの場合:

  - すべてのアドミニストレーターアクティビティー

  - 認証チェック

  - 認可チェック

  - データの削除

  - データアクセス

  - データ変更

  - 許可の変更

管理者は、必要なイベントタイプと、GitLabでイベントを有効にする際の追加の組織要件の両方を考慮する必要があります。

**メトリクス**

セキュリティイベント以外にも、管理者はアプリケーションのパフォーマンスを可視化して、アップタイムをサポートしたい場合があります。GitLabには、[メトリクスに関する堅牢なドキュメントセット](../administration/monitoring/_index.md)があり、GitLabインスタンスでサポートされています。

**ストレージ**

お客様は、コンプライアンス要件を満たす長期的なストレージソリューションにログが保存されていることを確認する責任があります。FedRAMPでは、たとえば、ログを1年間保存する必要があります。収集されたデータの影響によっては、顧客組織は米国国立公文書記録管理局の要件を満たす必要もあります。収集された記録の影響を確認し、適用されるコンプライアンス要件を理解することが重要です。

### インシデント対応（IR） {#incident-response-ir}

監査イベントが構成されると、これらのイベントをモニタリングする必要があります。GitLabは、SIEMまたはその他のセキュリティツールからのシステムアラートのコンパイル、アラートとインシデントのトリアージ、および関係者への通知を行うための一元化された管理インターフェースを提供します。[インシデント管理ドキュメント](../operations/incident_management/_index.md)では、セキュリティインシデント対応組織で前述のアクティビティーを実行するためにGitLabをどのように使用できるかを概説します。

**Incident Response Lifecycle**（インシデント対応ライフサイクル）

GitLabは、組織のインシデント対応ライフサイクル全体を管理できます。インシデント対応要件を満たすのに役立つ可能性のある次のリソースを確認してください:

- [アラート](../operations/incident_management/alerts.md)

- [インシデント](../operations/incident_management/incidents.md)

- [オンコールスケジュール](../operations/incident_management/oncall_schedules.md)

- [ステータスページ](../operations/incident_management/status_page.md)

### 構成管理（CM） {#configuration-management-cm}

**Change Control**（変更管理）

GitLabは、そのコアにおいて、変更管理に関連する構成管理要件を満たすことができます。イシューとマージリクエストは、変更をサポートするための主要な方法です。

イシューは、変更を実装する前にメタデータと承認をキャプチャするための柔軟なプラットフォームです。GitLab機能を使用して構成管理コントロールを満たす方法を完全に理解するには、[作業の計画と追跡](../topics/plan_and_track.md)に関するGitLabドキュメントを確認してください。

マージリクエストは、ソースブランチからターゲットブランチへの変更を標準化するための方法を提供します。NIST 800-53のコンテキストでは、コードをマージする前に承認を収集する方法と、組織内でコードをマージする権限を持つユーザーを検討することが重要です。GitLabは、[マージリクエストでの承認に利用できるさまざまな設定](../user/project/merge_requests/approvals/_index.md)に関するガイダンスを提供します。必要なレビューが完了した後、適切なロールにのみ承認とマージの権限を割り当てることを検討してください。検討すべき追加のマージ設定:

- コミットが追加されたときにすべての承認を削除 - 新しいコミットがマージリクエストに対して行われたときに、承認が引き継がれないようにします。

- コード変更レビューを却下できる個人を制限します。

- [コードオーナー](../user/project/codeowners/_index.md#codeowners-file)を割り当てて、機密性の高いコードまたは構成がマージリクエストを介して変更されたときに通知されるようにします。

- [コード変更のマージを許可する前に、開いているすべてのコメントが解決されていることを確認してください](../user/project/merge_requests/_index.md#prevent-merge-unless-all-threads-are-resolved)。

- [プッシュルールを構成する](../user/project/repository/push_rules.md) \- 署名付きコードのレビュー、ユーザーの検証など、要件を満たすようにプッシュルールを構成できます。

**Testing and Validation of Changes**（変更のテストと検証）

[CI/CDパイプライン](../topics/build_your_application.md)は、変更のテストと検証の重要なコンポーネントです。特定のユースケースに対して十分なテストと検証パイプラインを実装するのは、お客様の責任です。サービスを選択するときは、そのパイプラインがどこで実行されるかを検討してください。外部サービスに接続すると、連邦データの保存と処理が許可されている確立された認可境界に違反する可能性があります。GitLabは、FIPS対応システムで実行するように構成されたRunnerコンテナイメージを提供します。GitLabは、[保護ブランチを構成](../user/project/repository/branches/protected.md)する方法や[パイプラインセキュリティを実装](../ci/pipelines/_index.md#pipeline-security-on-protected-branches)する方法など、パイプラインの強化ガイダンスを提供します。さらに、コードをマージする前に[必要なチェック](../user/project/merge_requests/status_checks.md)を割り当てて、コードを更新する前にすべてのチェックが完了していることを確認することを検討してください。

**Component Inventory**（コンポーネントインベントリ）

NIST 800-53では、クラウドサービスプロバイダーがコンポーネントインベントリを維持する必要があります。GitLabは基盤となるハードウェアを直接追跡できませんが、コンテナスキャンと依存関係スキャンを通じてソフトウェアインベントリを生成できます。GitLabは、[コンテナスキャンと依存関係スキャンが検出できる依存関係](../user/application_security/comparison_dependency_and_container_scanning.md)を概説します。GitLabは、[ソフトウェアコンポーネントインベントリ](../user/application_security/dependency_list/_index.md)で使用できる依存関係リストの生成に関する追加ドキュメントを提供します。ソフトウェア部品表のサポートについては、サプライチェーンリスク管理で、このドキュメントの後半で説明します。

**Container Registry**（コンテナレジストリ）

GitLabは、GitLabプロジェクトのコンテナイメージを保存するための一体型レジストリを提供します。これは、高度に仮想化されたスケーラブルな環境でコンテナをデプロイするための信頼できるリポジトリとして使用できます。[コンテナレジストリ管理ガイダンス](../administration/packages/container_registry.md)を確認できます。

### 緊急時計画（CP） {#contingency-planning-cp}

GitLabは、主要な緊急時計画要件を満たすのに役立つガイダンスとサービスを提供します。含まれているドキュメントを確認し、それに応じて計画を立てて、緊急時計画アクティビティーに関する組織の要件を満たすことが重要です。緊急時計画は組織ごとに異なるため、緊急時計画を策定する前に、組織のニーズを考慮することが重要です。

**Selecting a GitLab Architecture**（GitLabアーキテクチャの選択）

GitLabは、GitLab Self-Managedインスタンスでサポートされているアーキテクチャに関する広範なドキュメントを提供します。GitLabは、次のクラウドサービスプロバイダーをサポートしています:

- [Azure](../install/azure/_index.md)

- [Google Cloud Platform](../install/google_cloud_platform/_index.md)

- [Amazon Web Services](../install/aws/_index.md)

GitLabは、[お客様が参照アーキテクチャと可用性モデルを選択するのを支援するためのディシジョンツリー](../administration/reference_architectures/_index.md#decision-tree)を提供します。ほとんどのクラウドサービスプロバイダーは、マネージドサービスのリージョンで回復性を提供します。アーキテクチャを選択するときは、組織のダウンタイムの許容度とデータの重要性を考慮することが重要です。追加のレプリケーションとフェイルオーバー機能については、GitLab Geoを検討できます。

**Identify Critical Assets**（重要な資産の特定）

NIST 800-53では、停止時に優先的に復元できるように、重要な資産を特定する必要があります。検討すべき重要な資産には、GitalyノードとPostgreSQLデータベースが含まれます。お客様は、必要に応じて、バックアップまたはレプリケーションが必要な追加の資産を特定する必要があります。

**Backups**（バックアップ）

このドキュメントでは、次の重要なコンポーネントのバックアップ戦略について概説します:

- [PostgreSQLデータベース](../administration/backup_restore/backup_gitlab.md#postgresql-databases)

- [Gitリポジトリ](../administration/backup_restore/backup_gitlab.md#git-repositories)

- [blob](../administration/backup_restore/backup_gitlab.md#blobs)

- [コンテナレジストリ](../administration/backup_restore/backup_gitlab.md#container-registry)

- [Redis](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/#backing-up-redis-data)

- [設定ファイル](../administration/backup_restore/backup_gitlab.md#storing-configuration-files)

- [Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html)

GitLab Geo

GitLab Geoは、NIST 800-53に準拠した実装を追求する上で重要なコンポーネントとなる可能性があります。各ユースケースに合わせてGeoが適切に構成されていることを確認するには、[利用可能なドキュメント](../administration/geo/_index.md)をレビューすることが重要です。

Geoを実装すると、次の利点があります:

- 分散したデベロッパーが大規模なリポジトリやプロジェクトをクローンおよびフェッチするのにかかる時間を、数分から数秒に短縮します。

- 開発者は、地域全体でアイデアをコントリビュートし、並行して作業できます。

- プライマリサイトとセカンダリサイト間で読み取り専用の負荷を分散します。

- GitLab Webインターフェースで利用可能なデータの読み取りに加えて、プロジェクトのクローン作成とフェッチに使用できます（制限事項を参照）。

- 遠隔オフィス間の低速な接続を克服し、分散チームの速度を向上させることで時間を節約します。

- 自動化されたタスク、カスタムインテグレーション、内部ワークフローの読み込む時間を短縮します。

- ディザスターリカバリーシナリオで、セカンダリサイトにすばやくフェイルオーバーできます。

- セカンダリサイトへの計画されたフェイルオーバーが可能です。

Geoは、次のコア機能を提供します:

- 読み取り専用セカンダリサイト: 分散チームのために読み取り専用セカンダリサイトを有効にしたままで、1つのプライマリGitLabサイトを維持します。

- 認証システムフック: セカンダリサイトは、プライマリインスタンスからすべての認証データ（ユーザーアカウントやログインなど）を受信します。

- 直感的なユーザーインターフェース: セカンダリサイトは、プライマリサイトと同じWebインターフェースを使用します。さらに、書き込み操作をブロックし、ユーザーがセカンダリサイトにいることを明確にするビジュアル通知があります。

Geoの追加リソース:

- [Geoをセットアップする](../administration/geo/setup/_index.md)

- [Geoを実行するための要件](../administration/geo/_index.md#requirements-for-running-geo)

- [Geoの制限](../administration/geo/_index.md)

- [Geoディザスターリカバリー手順](../administration/geo/disaster_recovery/_index.md)

**PostgreSQL**

GitLabは、[レプリケーションとフェイルオーバーを使用してPostgreSQLクラスターを構成する方法](../administration/postgresql/replication_and_failover.md)に関するガイダンスを提供します。データの重要性とGitLabインスタンスの最大許容ダウンタイムに応じて、レプリケーションとフェイルオーバーを有効にしてPostgreSQLを構成することを検討してください。

**Gitaly**

Gitalyを構成するときは、可用性、リカバリー性、および回復力のトレードオフを考慮してください。GitLabは、NIST 800-53要件を満たすための適切な構成を決定するのに役立つ[Gitaly機能](../administration/gitaly/gitaly_geo_capabilities.md)に関する広範なドキュメントを提供します。

### 計画（PL） {#planning-pl}

計画管理ファミリーには、ポリシー、手順、およびその他の管理されたドキュメントのメンテナンスが含まれます。GitLabを活用して、管理されたドキュメントのライフサイクルを管理することを検討してください。たとえば、管理されたドキュメントは、[Markdown](../user/markdown.md)にバージョン管理された状態で保存できます。ドキュメントへの変更は、組織の承認ルールを適用するマージリクエストを介して行う必要があります。マージリクエストは、管理されたドキュメントに加えられた変更の明確な履歴を提供します。これは、監査中に、ドキュメントオーナーなどの適切な担当者による年次レビューと承認を示すために使用できます。

### リスク評価とシステムおよび情報保全性（RA） {#risk-assessment-and-system-and-information-integrity-ra}

#### スキャン {#scanning}

NIST 800-53では、脆弱性の継続的なモニタリングと欠陥の修正が必要です。インフラストラクチャのスキャンに加えて、FedRAMPなどのコンプライアンスフレームワークでは、コンテナとDASTスキャンを毎月のレポート要件に含めるスコープがあります。GitLabは、[コンテナスキャンをサポートできるツール](../user/application_security/container_scanning/_index.md) 、[Trivy](https://github.com/aquasecurity/trivy)および[Grype](https://github.com/anchore/grype)スキャナーを提供します。さらに、GitLabは[依存関係スキャン機能](../user/application_security/dependency_scanning/_index.md)を提供します。GitLabの動的アプリケーションセキュリティテスト（DAST）を使用して、Webアプリケーションのスキャン要件を満たすことができます。[GitLab DAST](../user/application_security/dast/_index.md)は、パイプラインで実行するように構成でき、実行中のWebアプリケーションの脆弱性レポートを作成できます。

アプリケーションコードを保護および管理するために使用できる追加のセキュリティ機能には、次のものがあります:

- [静的アプリケーションセキュリティテスト（SAST）](../user/application_security/sast/_index.md)

- [シークレット検出](../user/application_security/secret_detection/_index.md)

- [APIセキュリティ](../user/application_security/api_security/_index.md)

#### パッチ管理 {#patch-management}

GitLabは、[リリースおよびメンテナンスポリシー](../policy/maintenance.md)をドキュメントにドキュメント化します。GitLabインスタンスをアップグレードする前に、利用可能なガイダンスをレビューしてください。これは、[アップグレードの計画](../update/plan_your_upgrade.md) 、[ダウンタイムなしのアップグレード](../update/zero_downtime.md) 、およびその他の[アップグレードパス](../update/upgrade_paths.md)に役立ちます。

[セキュリティダッシュボード](../user/application_security/security_dashboard/_index.md)は、長期にわたって脆弱性データを追跡するように構成できます。これは、脆弱性管理プログラムの傾向を特定するために使用できます。

### サプライチェーンリスク管理（SR） {#supply-chain-risk-management-sr}

#### ソフトウェア部品表 {#software-bill-of-materials}

GitLabの依存関係とコンテナスキャナーは、SBOMの生成をサポートしています。コンテナスキャンと依存関係スキャンでSBOMレポートを有効にすると、顧客組織はソフトウェアサプライチェーンと、ソフトウェアコンポーネントに関連する固有のリスクを理解できるようになります。GitLabスキャナーは、[CycloneDX形式のレポートをサポート](../ci/yaml/artifacts_reports.md#artifactsreportsdotenv)します。

### システムおよび通信保護（SC） {#system-and-communication-protection-sc}

#### FIPSコンプライアンス {#fips-compliance}

FedRAMPなどのNIST 800-53に基づくコンプライアンスプログラムでは、適用可能なすべての暗号学的モジュールに対してFIPSコンプライアンスが必要です。GitLabは、コンテナイメージのFIPSバージョンをリリースし、FIPSコンプライアンス標準を満たすようにGitLabを構成する方法に関するガイダンスを提供します。特定の機能は、FIPSモードでは利用できないか、サポートされていません。

GitLabはFIPSコンプライアンス準拠のイメージを提供しますが、基盤となるインフラストラクチャを構成し、環境を評価して、FIPS検証済みの暗号が適用されていることを確認するのは、お客様の責任です。

### システムおよび情報保全性（SI） {#system-and-information-integrity-si}

#### セキュリティアラート、勧告、および指示 {#security-alerts-advisories-and-directives}

GitLabは、ソフトウェアと依存関係に関連するセキュリティ脆弱性を追跡するための[勧告データベース](../user/application_security/gitlab_advisory_database/_index.md)を管理しています。GitLabは、CVE番号付与機関（CNA）です。[CVE IDリクエスト](../user/application_security/cve_id_request.md)を生成するには、このページに従ってください。

#### メール {#email}

GitLabは、GitLabアプリケーションインスタンスからユーザーへの[メール通知の送信](../administration/email_from_gitlab.md#sending-emails-to-users-from-gitlab)をサポートしています。DHS BOD 18-01ガイダンスは、スパム保護として送信メッセージに対してドメインベースのメッセージ認証、レポート、および準拠（DMARC）を構成する必要があることを示しています。GitLabは、[幅広いメールプロバイダーにわたるSMTPの構成ガイダンス](https://docs.gitlab.com/omnibus/settings/smtp.html)を提供しており、これはこの要件を満たすのに役立ちます。

### その他のサービスと概念 {#other-services-and-concepts}

#### Runner {#runners}

Runnerは、あらゆるGitLabデプロイの幅広いタスクとツールに必要です。データ境界要件を維持するために、お客様は[自己管理Runner](https://docs.gitlab.com/runner/)を認可境界にデプロイする必要がある場合があります。GitLabは、[Runnerの構成](../ci/runners/configure_runners.md)に関する詳細情報を提供します。これには、次のような概念が含まれます:

- ジョブの最大タイムアウト

- 機密情報を保護する

- ロングポーリングを設定する

- 認証トークンセキュリティとトークンローテーション

- 機密情報の開示の防止

- Runner変数

#### APIの活用 {#leveraging-apis}

GitLabは、アプリケーションをサポートするための堅牢なAPIセットを提供します。これには、[REST](../api/rest/_index.md)および[GraphQL](../api/graphql/_index.md) APIが含まれます。APIの保護は、APIエンドポイントを呼び出すユーザーとジョブの認証を適切に構成することから始まります。GitLabは、アクセスを制御するために、アクセストークン（FIPSでサポートされていないパーソナルアクセストークン）とOAuth 2.0トークンを構成することをお勧めします。

#### 拡張機能 {#extensions}

[拡張機能](../editor_extensions/_index.md)は、確立されているインテグレーションに応じて、NIST 800-53の要件を満たす場合があります。たとえば、エディタおよびIDEの拡張機能は許可される場合がありますが、サードパーティとのインテグレーションは認可境界の要件に違反する可能性があります。お客様の認可境界外にデータが送信される場所を理解するために、すべての拡張機能を検証する責任はお客様にあります。

### その他のリソース {#additional-resources}

GitLabは、次のようなトピックを網羅したGitLab Self-Managedのお客様向けの[強化ガイド](hardening.md)を提供しています:

- [アプリケーション強化の推奨事項](hardening_application_recommendations.md)

- [CI/CD強化に関する推奨事項](hardening_cicd_recommendations.md)

- [設定](hardening_configuration_recommendations.md)の推奨事項

- [オペレーティングシステムの推奨事項](hardening_operating_system_recommendations.md)

GitLab CISベンチマークガイド - GitLabは、アプリケーションの強化の決定を導くための[CISベンチマーク](https://about.gitlab.com/blog/2024/04/17/gitlab-introduces-new-cis-benchmark-for-improved-security/)を公開しました。これは、NIST 800-53コントロールに準拠して環境を強化するために、本ガイドと連携して使用できます。CISベンチマークのすべての提案がNIST 800-53コントロールに直接対応しているわけではありませんが、GitLabインスタンスを維持するためのベストプラクティスとして役立ちます。
