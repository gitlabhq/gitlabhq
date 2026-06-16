---
stage: Release Notes
group: Monthly Release
date: 2023-09-22
title: "GitLab 16.4リリースノート"
description: "GitLab 16.4がカスタマイズ可能なロールとともにリリースされました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023年9月22日、GitLab 16.4が以下の機能とともにリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Kik {#this-months-notable-contributor-kik}

Kikは、GitLabにおけるActivityPubサポートの設計と実装開始において重要な役割を担ってきました。彼の深く詳細な元々のアーキテクチャ計画は、当社の製品チームに受け入れられ、現在[エピックとして](https://gitlab.com/groups/gitlab-org/-/epics/11247) GitLabプロジェクトに存在しています。このコードを実装する[最初のMR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127023)は最近マージされ、その後[ドキュメントが追加されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130960)。

この大規模な機能のサポートが拡大するにつれて、Kikはコラボレーション、イテレーション、そして透明性という[GitLabの価値観](https://handbook.gitlab.com/handbook/values/)を体現していることを示しました！

Kikは長年GitLabコミュニティの一員であり、7年以上前に[最初のイシュー](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/4037#note_4651432)を記録しました。彼はここ数か月、もう少し積極的に活動するようになりました。彼のコントリビュートについて尋ねられた際、彼は次のように述べました:

> 何か強調すべき点があるとすれば、おそらくGitLabがいかに可能にし、そのソースコードを見ていじることができるか、そしてどんなに意欲的なコントリビュートでも歓迎しているか、ということでしょう。 :)

彼はまた、記念品を選ぶ代わりに、彼の名前で[木を植えてもらう](https://tree-nation.com/trees/view/5119567)ことを選択することで、私たちの持続可能性の取り組みを開拓する手助けをすることを選びました。🌳

Kikさん、GitLabの構築に協力し、素晴らしいコミュニティの一員となってくれてありがとうございます！ 🙌

## 主要な機能 {#primary-features}

### カスタマイズ可能なロール {#customizable-roles}

<!-- categories: User Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/permissions.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/393235)

{{< /details >}}

グループオーナーまたは管理者は、ロールと権限メニューのUIを使用して、カスタムロールを作成および削除できるようになりました。カスタムロールを作成するには、既存の[ベースロール](../../user/permissions.md#roles)に[権限](../../user/permissions.md)を追加します。現在、ベースロールに追加できる権限の数には限りがあり、これには[きめ細やかなセキュリティ権限](https://docs.gitlab.com/#granular-security-permissions)、マージリクエストを承認する機能、およびコードを表示する機能が含まれます。各マイルストーンで、既存の権限に追加してカスタムロールを作成できる新しい権限がリリースされます。

### プライベートプロジェクト用のワークスペースを作成 {#create-workspaces-for-private-projects}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/workspace/_index.md#personal-access-token)

{{< /details >}}

以前は、プライベートプロジェクト用の[ワークスペースを作成](../../user/workspace/configuration.md)することはできませんでした。プライベートプロジェクトをクローンするには、ワークスペースを作成した後にのみ自身を認証することができました。

GitLab 16.4では、公開またはプライベートプロジェクトのワークスペースを作成できます。ワークスペースを作成すると、ワークスペースで使用するパーソナルアクセストークンを取得できます。このトークンを使用すると、追加の設定や認証なしで、プライベートプロジェクトをクローンし、Git操作を実行できます。

### 自身のGitLabユーザーIDを使用してローカルでクラスターにアクセス {#access-clusters-locally-using-your-gitlab-user-identity}

<!-- categories: Environment Management, User Profile -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/user_access.md#access-a-cluster-with-the-kubernetes-api) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11235)

{{< /details >}}

デベロッパーがKubernetesクラスターにアクセスできるようにするには、デベロッパークラウドアカウントまたはサードパーティの認証ツールが必要です。これにより、クラウドのアイデンティティおよびアクセス管理の複雑さが増します。現在、デベロッパーが自身のGitLabアイデンティティとKubernetes用のエージェントのみを使用してKubernetesクラスターにアクセスできるように付与できます。従来のKubernetes RBACを使用して、クラスター内の認可を管理します。

GitLabパイプラインにおける[OIDCクラウド認証](../../ci/cloud_services/_index.md)とともに、これらの機能によりGitLabユーザーは、専用のクラウドアカウントなしでクラウドのリソースにアクセスでき、セキュリティとコンプライアンスを危険にさらすことはありません。

クラスターアクセスのこの最初のイテレーションでは、[Kubernetesの設定を手動で管理](../../user/clusters/agent/user_access.md)する必要があります。[エピック11455](https://gitlab.com/groups/gitlab-org/-/epics/11455)は、関連するコマンドでGitLab CLIを拡張することにより、セットアップを簡素化することを提案しています。

### グループ/サブグループレベルの依存関係リスト {#groupsub-group-level-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/8090)

{{< /details >}}

依存関係のリストをレビューする際には、全体像を把握することが重要です。プロジェクトレベルで依存関係を管理することは、すべてのプロジェクトの依存関係を監査したい大規模な組織にとって問題です。このリリースにより、サブグループを含むプロジェクトまたはグループレベルで、すべての依存関係を確認できます。この機能は現在デフォルトで利用可能です。

### 脆弱性の一括ステータス更新 {#vulnerability-bulk-status-updates}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/4649)

{{< /details >}}

一部の脆弱性は一括で対処する必要があります。それらが誤検出であるか、検出されなくなったかに関わらず、ノイズを最小限に抑えるし、脆弱性を簡単にトリアージすることが重要です。このリリースにより、グループまたはプロジェクトの脆弱性レポートから複数の脆弱性のステータスを一括で変更し、コメントを付けることができます。

### きめ細やかなセキュリティ権限 {#granular-security-permissions}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/permissions.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10684)

{{< /details >}}

一部の組織は、セキュリティチームに最小限のアクセス権限のみを与え、[最小権限の原則](https://en.wikipedia.org/wiki/Principle_of_least_privilege)を遵守したいと考えています。セキュリティチームはコード更新を書き込むアクセス権限を持つべきではありませんが、マージリクエストを承認し、脆弱性を表示し、脆弱性のステータスを更新できる必要があります。

GitLabは現在、[レポーター](../../user/permissions.md)ロールのアクセス権限に基づいて[カスタムロールを作成](../../user/permissions.md)することをユーザーに許可していますが、以下の追加の権限が含まれています:

- 依存関係リストの表示 (`read_dependency`)。
- セキュリティダッシュボードおよび脆弱性レポートの表示 (`read_vulnerability`)。
- マージリクエストの承認 (`admin_merge_request`)。
- 脆弱性のステータス変更 (`admin_vulnerability`)。

この[非推奨エントリ](../../update/deprecations.md#deprecate-change-vulnerability-status-from-the-developer-role)に記載されているように、17.0でデベロッパーロールからすべてのティアの脆弱性のステータスを変更する機能を削除する予定です。この提案された変更に関するフィードバックは、[イシュー424688](https://gitlab.com/gitlab-org/gitlab/-/issues/424668)で共有できます。

### 早送りマージのマージトレインサポート {#fast-forward-merge-support-for-merge-trains}

<!-- categories: Merge Trains -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/pipelines/merge_trains.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/4911)

{{< /details >}}

[早送りマージ](../../user/project/merge_requests/methods/_index.md#fast-forward-merge)は、マージコミットを回避しますが、より多くのリベースを必要とする一般的で人気のあるマージ方法です。別途、マージトレインは、mainブランチへの頻繁なマージに関連するいくつかの大きな課題を解決するのに役立つ強力なツールです。残念ながら、このリリース以前は、マージトレインと早送りマージを一緒に使用することはできませんでした。

このリリースでは、セルフマネージド管理者は同じプロジェクトで早送りマージとマージトレインの両方を有効にできるようになりました。マージトレインのすべての利点を得ることができます。マージトレインは、マージする前にすべてのコミットが連携して機能することを確認し、早送りマージのよりクリーンなコミット履歴を実現します！

早送りマージトレインを有効にするには、デフォルトで無効になっている機能フラグ`fast_forward_merge_trains_support`を見つけて有効にします。

### `id_token`をグローバルに設定し、個々のジョブの設定を排除 {#set-id_token-globally-and-eliminate-configuration-for-individual-jobs}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/yaml/_index.md#id_tokens) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/419750)

{{< /details >}}

GitLab 15.9では、`id_token`を優先して[以前のJSON Webトークンバージョンの非推奨化](../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated)を発表しました。残念ながら、この変更に対応するためにジョブを個別に変更する必要がありました。`id_token`へのスムーズな移行を可能にするため、GitLab 16.4以降、`id_tokens`を`.gitlab-ci.yml`でグローバルデフォルト値として設定できます。この機能は、すべてのジョブの`id_token`設定を自動的に設定します。OpenID Connect (OIDC) 認証を使用するジョブでは、個別の`id_token`を設定する必要がなくなりました。

[`id_token`とOIDCを使用してサードパーティサービスで認証する](../../ci/secrets/id_token_authentication.md)。JSON Webトークンの`aud`クレームを設定するために、必須のサブキーワード`aud`を使用します。

## 規模とデプロイ {#scale-and-deployments}

### Elasticsearchインデックスの整合性が一般提供開始 {#elasticsearch-index-integrity-now-generally-available}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../integration/advanced_search/elasticsearch.md#index-integrity) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/214601)

{{< /details >}}

GitLab 16.4では、Elasticsearchインデックスの整合性がすべてのGitLabユーザーに一般提供されるようになりました。インデックスの整合性は、欠落しているリポジトリデータを検出して修正するのに役立ちます。この機能は、グループまたはプロジェクトにスコープされたコード検索で結果が返されない場合に自動的に使用されます。

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.4には、[OpenSUSE 15.5](https://en.opensuse.org/Release_announcement_15.5)用のパッケージが含まれています。

### 追加または失効された絵文字リアクション用のWebhookを追加 {#add-webhooks-for-added-or-revoked-emoji-reactions}

<!-- categories: Webhooks -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/webhook_events.md#emoji-events) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/290773)

{{< /details >}}

可能な限り多くの自動化とサードパーティシステムとのインテグレーションの機会を提供するために、ユーザーが絵文字リアクションを追加または失効したときにトリガーするWebhookの作成サポートを追加しました。

たとえば、ユーザーがイシューやマージリクエストに絵文字で反応したときに、新しいWebhookを使用してメールを送信できます。

### カスタムロールの名前と説明をAPIを使用して作成 {#create-custom-role-name-and-description-using-api}

<!-- categories: System Access -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/member_roles.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/416751)

{{< /details >}}

カスタムロールを作成する際、メンバーロールAPIを使用して名前（必須）と説明（オプション）を追加できるようになりました。既存のすべてのカスタムロールには`Custom`という名前が付けられており、APIを使用してカスタムロールの名前を任意の名前に変更できます。

### グループメンションのSlack通知をトリガーする {#trigger-slack-notifications-for-group-mentions}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/gitlab_slack_application.md#trigger-notifications-for-group-mentions) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/417751)

{{< /details >}}

GitLabは、特定のGitLabイベントに対してSlackワークスペースチャンネルにメッセージを送信できます。このリリースにより、以下で公開およびプライベートコンテキストにおけるグループメンションの[Slack通知](../../user/project/integrations/gitlab_slack_application.md#notification-events)をトリガーすることができるようになりました:

- イシューとマージリクエストの説明
- イシュー、マージリクエスト、コミットのコメント

### アプリケーション設定で利用可能な構成可能なインポート制限を展開する {#expand-configurable-import-limits-available-in-application-settings}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/settings/import_and_export_settings.md#timeout-for-decompressing-archived-files) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/421432)

{{< /details >}}

最近、いくつかのハードコードされたインポート制限を構成可能なアプリケーション設定に変更し、セルフマネージドGitLab管理者がニーズに応じてこれらの制限を調整できるようにしました。

このリリースでは、アーカイブファイルの解凍するためのタイムアウトを構成可能なアプリケーション設定として追加しました。

この制限は210秒にハードコードされていました。GitLab.comおよびデフォルトでセルフマネージドインストールの場合、この制限を210秒に設定しました。セルフマネージドGitLabとGitLab.comの管理者は、必要に応じてこの制限を調整できます。

### サービスデスク用のカスタムメールアドレス {#custom-email-address-for-service-desk}

<!-- categories: Service Desk -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/service_desk/configure.md#custom-email-address) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/329990)

{{< /details >}}

サービスデスクは、お客様のビジネスと顧客との間で最も意味のあるつながりの1つです。これで、独自のカスタムメールアドレスを使用して、サービスデスクのメールを送受信できます。この変更により、ブランドアイデンティティを維持し、顧客が正しいエンティティとコミュニケーションしているという信頼を植え付けることがはるかに簡単になります。

この機能はベータ版です。ユーザーの皆様には、ベータ機能をお試しいただき、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/416637)でフィードバックを提供していただくことをお勧めします。

### GeoはCloud Native Hybridサイトでの統合URLをサポート {#geo-supports-unified-urls-on-cloud-native-hybrid-sites}

<!-- categories: Disaster Recovery, Geo-replication -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/geo/secondary_proxy/_index.md#set-up-a-unified-url-for-geo-sites) | [関連エピック](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3522)

{{< /details >}}

Geoは現在、[Cloud Native Hybrid](../../administration/reference_architectures/_index.md#cloud-native-hybrid)サイトでの統合URLをサポートしており、Cloud Native Hybridサイトはプライマリサイトと単一の外部URLを共有できます。これにより、単一の共通URLを使用して、所在地に基づいて最適なGeoセカンダリサイトに自動的に誘導できるリモートチームに、シームレスなGitLab UIとGitデベロッパーエクスペリエンスが提供されます。この更新により、統合URLはすべてのGitLabリファレンスアーキテクチャでサポートされるようになりました。

### Geoはオブジェクトストレージを検証します {#geo-verifies-object-storage}

<!-- categories: Geo-replication, Disaster Recovery -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/geo/replication/object_storage.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/8056)

{{< /details >}}

Geoは、[オブジェクトストレージのレプリケーションがGitLabによって管理される](../../administration/geo/replication/object_storage.md#enabling-gitlab-managed-object-storage-replication)場合に、オブジェクトストレージを検証する機能を追加します。オブジェクトストレージデータを破損から保護するため、Geoはプライマリサイトとセカンダリサイト間でファイルサイズを比較します。Geoがお客様のディザスターリカバリー戦略の一部であり、GitLab管理のオブジェクトストレージのレプリケーションを有効にしている場合、これはデータ損失から保護します。さらに、セカンダリサイトに既に存在する可能性のあるデータをコピーする必要性を減らします。たとえば、古いプライマリをセカンダリサイトとして再度追加する場合です。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### ダウンストリームパイプラインにおける`environment`キーワードのサポート {#support-for-environment-keyword-in-downstream-pipelines}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/pipelines/downstream_pipelines.md#downstream-pipelines-for-deployments) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/369061)

{{< /details >}}

CI/CDパイプラインジョブからダウンストリームパイプラインをトリガーする必要がある場合、`trigger`キーワードを使用できます。デプロイ管理を強化するため、`trigger`を使用する際に`environment`キーワードで環境を指定できるようになりました。たとえば、`/web-app`プロジェクトの`main`ブランチに対して、環境名`dev`と指定された環境URLを持つダウンストリームパイプラインをトリガーすることができます。

以前は、CIとCDで別々のパイプラインを実行し、`trigger`キーワードを使用してCDパイプラインを開始した場合、環境の詳細を指定することはできませんでした。これにより、CIプロジェクトからのデプロイを追跡することが困難でした。環境のサポートを追加することで、プロジェクト間のデプロイの追跡が簡素化されます。

### ユーザーが適用されるセキュリティポリシーに対するブランチ例外を定義できるようにする {#allow-users-to-define-branch-exceptions-to-enforced-security-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9567)

{{< /details >}}

セキュリティポリシーは、GitLabプロジェクトでスキャナーを実行するだけでなく、セキュリティとコンプライアンスを確保するためにMRチェック/承認を強制します。ブランチ例外を使用すると、ポリシーをよりきめ細かく適用し、スコープ外の任意のブランチに対する適用を除外することができます。デベロッパーが、意図せず厳格な適用によって影響を受ける開発またはテストブランチを作成した場合、セキュリティチームと協力してセキュリティポリシー内でそのブランチを免除することができます。

スキャン実行ポリシーの場合、[パイプライン](../../user/application_security/policies/scan_execution_policies.md#pipeline-rule-type)または[スケジュール](../../user/application_security/policies/scan_execution_policies.md#schedule-rule-type)ルールタイプに対して例外を設定できます。スキャン結果ポリシーの場合、[スキャン結果](../../user/application_security/policies/merge_request_approval_policies.md#scan_finding-rule-type)または[ライセンス結果](../../user/application_security/policies/merge_request_approval_policies.md#license_finding-rule-type)ルールタイプに対してブランチ例外を指定できます。

### アクセストークンの有効期限切れ通知 {#notifications-for-expiring-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../security/tokens/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/367705)

{{< /details >}}

グループおよびプロジェクトのアクセストークンは自動化によく使用されます。管理者およびグループオーナーは、これらのトークンのいずれかが有効期限に近づいているときに通知を受け取り、中断を回避することが重要です。管理者およびグループオーナーは、トークンの有効期限まで7日以内になると通知メールを受け取るようになりました。

### アクセス有効期限切れのメール通知 {#email-notification-when-access-expires}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/group/_index.md#add-users-to-a-group) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/12704)

{{< /details >}}

ユーザーは、グループまたはプロジェクトへのアクセス有効期限が切れる7日前にメール通知を受け取ります。これは、アクセス有効期限日が設定されている場合にのみ適用されます。以前は、アクセスが有効期限切れになった場合の通知はありませんでした。事前通知により、GitLab管理者に連絡して継続的なアクセスを確保できます。

### ブラウザベースDASTアクティブチェック22.1がデフォルトで有効化されました {#browser-based-dast-active-check-221-is-enabled-by-default}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dast/browser/checks/_index.md#active-checks) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/392718)

{{< /details >}}

ブラウザベースDASTアクティブチェック22.1がデフォルトで有効になりました。これは、無効になっているZAPチェック6を置き換えます。チェック22.1は、「制限されたディレクトリへのパス名の不適切な制限（パストラバーサル）」を特定します。これは、URLエンドポイントのパラメータにペイロードを挿入することで悪用され、任意のファイルを読み取りできるようにします。

### オペレーショナルコンテナスキャンのプライベートレジストリサポート {#private-registry-support-for-operational-container-scanning}

<!-- categories: Container Scanning -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/vulnerabilities.md#scanning-private-images) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/415451)

{{< /details >}}

[オペレーショナルコンテナスキャン](../../user/clusters/agent/vulnerabilities.md)は、プライベートコンテナレジストリからイメージにアクセスしてスキャンできるようになりました。OCSはイメージプルシークレットを使用してプライベートレジストリコンテナにアクセスします。

### 依存関係とライセンススキャンのpnpmロックファイルv6.1サポート {#dependency-and-license-scanning-support-for-pnpm-lockfile-v61}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/413903)

{{< /details >}}

[Weyert de Boer](https://gitlab.com/weyert-tapico)氏からのコミュニティコントリビュートのおかげで、GitLab依存関係およびライセンススキャンは、v6.1ロックファイル形式を使用するpnpmプロジェクトの分析をサポートするようになりました。

### SASTアナライザーの更新 {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/analyzers.md) | [関連イシュー](../../user/application_security/_index.md)

{{< /details >}}

GitLab SASTには、GitLab静的な解析チームが積極的に保守、更新、サポートする[多くのセキュリティアナライザー](../../user/application_security/sast/_index.md#supported-languages-and-frameworks)が含まれています。16.4リリースマイルストーン中に以下の更新を公開しました:

- KICSベースのアナライザーをKICSスキャナーのバージョン1.7.7に更新しました。詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md?ref_type=heads#v415)を参照してください。
- SobelowベースのアナライザーをSobelowスキャナーのバージョン0.13.0に更新しました。また、より新しいElixirリリースとの互換性を向上させるため、アナライザーのベースイメージをElixir 1.13に更新しました。[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow/-/blob/master/CHANGELOG.md?ref_type=heads#v421)を参照してください
- PMD ApexベースのアナライザーをPMDスキャナーのバージョン6.55.0に更新しました。詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex/-/blob/master/CHANGELOG.md?ref_type=heads#v413)を参照してください。
- PHPCS Security Auditベースのアナライザーを変更し、`Security.Misc.IncludeMismatch`ルールを削除しました。詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit/-/blob/master/CHANGELOG.md?ref_type=heads#v411)を参照してください。
- Semgrepベースのアナライザーで使用されるルールを更新し、ルールエラーを修正し、ルール説明の破損したリンクを修正し、同じルールIDを持つJavaとScalaのルール間の競合を解決しました。また、カスタムルールファイルの最大サイズを10 MBに増やしました。詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md?ref_type=heads#v4412)を参照してください。

[GitLab管理のSASTテンプレート](../../user/application_security/sast/_index.md) （[`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)）を含め、GitLab 16.0以降を実行している場合、これらの更新を自動的に受け取ります。特定のアナライザーのバージョンを維持し、自動更新を防ぐには、[そのバージョンを固定](../../user/application_security/sast/_index.md)できます。

以前の変更については、[先月の更新](https://about.gitlab.com/releases/2023/08/22/gitlab-16-3-released/#sast-analyzer-updates)を参照してください。

### SASTの脆弱性追跡機能の改善 {#improved-sast-vulnerability-tracking}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/373921)

{{< /details >}}

GitLab SAST [高度な脆弱性追跡](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking)は、コードが移動しても発見を追跡し続けることで、トリアージをより効率的にします。

GitLab 16.4では、新しい言語とアナライザーに対して高度な脆弱性追跡を有効にしました。その[既存のカバレッジ](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking)に加えて、高度な追跡が以下で利用可能になりました:

- Java、SpotBugsベースのSASTアナライザー。
- PHP、PHPCS Security AuditベースのSASTアナライザー。

これは、[GitLab 16.3でリリースされた](https://about.gitlab.com/releases/2023/08/22/gitlab-16-3-released/#improved-sast-vulnerability-tracking)以前の拡張機能と改善に基づいています。[エピック5144](https://gitlab.com/groups/gitlab-org/-/epics/5144)でさらなる改善を追跡しています。

これらの変更は、GitLab SAST [アナライザー](../../user/application_security/sast/analyzers.md)の[更新されたバージョン](https://docs.gitlab.com/#sast-analyzer-updates)に含まれています。プロジェクトの脆弱性発見は、更新されたアナライザーでプロジェクトがスキャンされた後、新しい追跡シグネチャで更新されます。[SASTアナライザーを特定のバージョンにピン留め](../../user/application_security/sast/_index.md)していない限り、この更新を受け取るためにアクションを実行する必要はありません。

### パイプライン固有のCycloneDX SBOMエクスポート {#pipeline-specific-cyclonedx-sbom-exports}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/dependency_list_export.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/333463)

{{< /details >}}

CIパイプラインで検出されたすべてのコンポーネントをリストするCycloneDX SBOMをダウンロードできるAPIを追加しました。これには、アプリケーションレベルの依存関係とシステムレベルの依存関係の両方が含まれます。

### メンテナーロールを持つユーザーは、Runnerの詳細を表示できます {#users-with-the-maintainer-role-can-view-runner-details}

<!-- categories: Runner Fleet -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/permissions.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/384179)

{{< /details >}}

グループのメンテナーロールを持つユーザーは、グループRunnerの詳細を表示できるようになりました。このロールを持つユーザーは、グループRunnerを表示して、どのRunnerが利用可能か、または自動的に作成されたRunnerがグループネームスペースに正常に登録されたことを検証するかを迅速に判断できます。

### macOS上のSaaS Runner用のmacOS 13 (Ventura) イメージ {#macos-13-ventura-image-for-saas-runners-on-macos}

<!-- categories: GitLab Runner SaaS -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/macos.md#supported-macos-images) | [関連イシュー](https://gitlab.com/gitlab-org/ci-cd/shared-runners/infrastructure/-/issues/101)

{{< /details >}}

チームはmacOS 13でAppleエコシステム向けアプリケーションをシームレスに作成、テスト、デプロイできるようになりました。

macOS上のSaaS Runnerを使用すると、安全なオンデマンドGitLab Runnerビルド環境で、GitLab CI/CDと統合されたmacOSを必要とするアプリケーションのビルドとデプロイにおける開発チームの開発速度を向上させることができます。

### GitLab Runner 16.4 {#gitlab-runner-164}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 16.4もリリースします！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに送信する、軽量で拡張性の高いエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

-  [Runner Prometheusメトリクスエンドポイントにキュー期間ヒストグラムメトリクスを追加](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36627)

#### バグ修正 {#bug-fixes}

-  [GitLab Runner 16.3.0でKubernetes Runnerポッドがクリーンアップされない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36803)
-  [`gitlab-runner-helper`がキャッシュのダウンロード中に終了しました](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27984)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-4-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.4)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.4)
- [UI改善](https://papercuts.gitlab.com/?milestone=16.4)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
