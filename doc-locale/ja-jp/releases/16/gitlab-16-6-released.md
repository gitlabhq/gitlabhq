---
stage: Release Notes
group: Monthly Release
date: 2023-11-16
title: "GitLab 16.6リリースノート"
description: "GitLab 16.6が、GitLab Duo Chatベータ版として利用可能になりました。"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023年11月16日、GitLab 16.6は以下の機能を備えてリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Joe Snyder {#this-months-notable-contributor-joe-snyder}

Joe Snyderは、GitLab全体への継続的なコントリビューションが評価され、GitLab 16.6 MVPに選ばれました。これには、[管理者がRunnerをバージョンでフィルタリングできるようにする](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135025)最近のマージリクエストが含まれます。

JoeはGitLabのスタッフフロントエンドエンジニアである[Miguel Rincon](https://gitlab.com/mrincon)によって指名されました。Miguelは、GitLabの進化するアーキテクチャのために必要とされたいくつかの書き直しを通じてJoeの努力を認め、Joeの「パフォーマンスとユーザービリティに対する思慮深い配慮」についてコメントしました。

[Pedro Pombeiro](https://gitlab.com/pedropombeiro)、シニアGitLabのバックエンドエンジニアは、「Joe Snyderは、以前の同僚から引き継いだ後、問題に関するすべてのコンテキストを学習する必要がある中、この変更を完遂させました。彼はまた、その後のレビューにおいて、私たちのフィードバックに対して非常に迅速かつ忍耐強く対応してくれました。」と付け加えました。

「Joeと仕事ができたことは喜びです」とGitLabのスタッフバックエンドエンジニアである[Terri Chu](https://gitlab.com/terrichu)は述べました。Terriは、前回のマイルストーン（およびそれ以前のマイルストーン）における[`emails_enabled`の変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127899)に関するJoeの継続的な作業を強調しました。

Joe Snyderは[Kitware](https://www.kitware.com/)のシニアR&Dエンジニアであり、2021年からGitLabにコントリビュートしています。GitLabの改善に貢献し続けるJoeに心から感謝します！

## 主要な機能 {#primary-features}

### GitLab Duo Chatベータ版が利用可能 {#gitlab-duo-chat-available-in-beta}

<!-- categories: Duo Chat -->

{{< details >}}

- プラン: Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/gitlab_duo_chat/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10550)

{{< /details >}}

ソフトウェア開発プロセスに関わる誰もが、コード、エピック、イシュー、そして長いディスカッションスレッドに慣れるためにかなりの時間を費やすことがあります。コードの要約、ドキュメント、テストといった日常的なタスクに時間を取られてしまうことがよくあります。判断することなくDevSecOpsの質問に答え、追加の質問にも対応できるエキスパートをそばに置くことで、ソフトウェア開発プロセスを加速させることができます。

GitLab Duo Chatは、これらの課題に積極的に対処し、ワークフローを加速させることを目指しています。その機能には以下が含まれます:

- イシュー、エピック、コードを説明または要約します。
- これらのアーティファクトについて具体的な質問に答えます。例えば、「このイシューで提案されている解決策に関するコメントで提起されたすべての引数を収集してください」といった質問です。
- これらのアーティファクトの情報に基づいてコードまたはコンテンツを生成します。例えば、「このコードのドキュメントを作成できますか？」
- あるいは、「GitLab CI/CDパイプラインでRuby on Railsアプリケーションをテストおよびビルドするための.GitLab-ci.yml設定ファイルを作成してください」のように、ゼロから始めることもできます。
- 初心者でもエキスパートでも、DevSecOps関連のすべての質問に答えます。例えば、「動的アプリケーションセキュリティテストをREST APIに設定するにはどうすればよいですか？」
- 上記のすべてのシナリオを反復的に作業できるように、追加の質問に答えます。

GitLab Duo Chatは、GitLab.comでベータ機能として利用可能です。また、弊社のWeb IDEおよびVS Code用GitLab Workflow拡張機能にも、実験的機能として統合されています。

製品内または弊社の[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/430124)を通じて、Duo Chatの体験に関するフィードバックを提供することで、これらの機能を成熟させるのに協力することもできます。

### エンタープライズユーザーの自動クレーム {#automatic-claims-of-enterprise-users}

<!-- categories: User Management -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/enterprise_user/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9675)

{{< /details >}}

GitLab.comユーザーのプライマリメールアドレスが既存の検証済みドメインと一致する場合、そのユーザーは自動的にエンタープライズユーザーとして登録されます。これにより、オーナーグループはユーザー管理のコントロールとユーザーアカウントへの表示レベルをより多く持つことができます。ユーザーがエンタープライズユーザーになった後、そのユーザーは、検証済みドメインに従って組織が所有するメールにのみプライマリメールを変更できます。

### 最小限のフォーク - デフォルトブランチのみを含める {#minimal-forking---only-include-the-default-branch}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/forking_workflow.md#create-a-fork)

{{< /details >}}

以前のGitLabバージョンでは、リポジトリをフォークする際、そのフォークには常にリポジトリ内のすべてのブランチが含まれていました。現在では、デフォルトブランチのみを含むフォークを作成できるようになり、複雑さを軽減し、ストレージ容量を節約できます。他のブランチで現在作業中の変更が必要ない場合は、最小限のフォークを作成してください。

フォークのデフォルトメソッドは変更されず、リポジトリ内のすべてのブランチが引き続き含まれます。新しいオプションは、どのブランチがデフォルトであるかを示しているため、新しいフォークにどのブランチが含まれるかを正確に把握できます。

### ユーザーがMR承認をコンプライアンスポリシーとして強制できるようにする {#allow-users-to-enforce-mr-approvals-as-a-compliance-policy}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#any_merge_request-rule-type) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9696)

{{< /details >}}

本番環境アプリケーションにコード変更が混入する可能性があり、企業をコンプライアンスリスクとセキュリティ脆弱性にさらすことに対する監視が厳しくなっています。スキャン結果ポリシーを使用すると、すべてのマージリクエストに対して2人による承認を強制することで、一方的な変更が行われることを防ぐことができます。

スキャン結果ポリシーには、`Any merge request`をターゲットとする新しいオプションがあり、定義されたブランチの各MRに対して、特定の役割（オーナー、メンテナー、またはデベロッパー）を持つ2人以上のユーザーによる承認を要求するように、[役割ベースの承認者](../../user/application_security/policies/merge_request_approval_policies.md#require_approval-action-type)の定義と組み合わせることができます。

SaaSでは16.6で利用可能です。Self-managedの場合は、機能フラグ`scan_result_any_merge_request`の背後で利用可能であり、16.7でデフォルトで有効になります。

### GitLab Dedicated用のSwitchboardポータルが一般提供開始 {#switchboard-portal-for-gitlab-dedicated-is-now-generally-available}

<!-- categories: Switchboard, GitLab Dedicated -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/dedicated/_index.md) | [関連イシュー](https://about.gitlab.com/dedicated/)

{{< /details >}}

新しいセルフサービスポータルであるスイッチボードが、顧客とチームメンバーが[GitLab Dedicated](https://about.gitlab.com/dedicated/)インスタンスをオンボーディング、設定、および維持するために利用できるようになりました。

Switchboardを使用すると、[設定変更](../../administration/dedicated/_index.md)をGitLab Dedicatedインスタンスに適用できるようになりました。この機能は将来のリリースで展開されます。

### CI/CDコンポーネントベータリリース {#cicd-components-beta-release}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/components/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/9897)

{{< /details >}}

GitLab 16.1では、[エキサイティングな実験的機能](https://about.gitlab.com/blog/introducing-ci-components/)であるCI/CDコンポーネントのリリースを発表しました。コンポーネントは、今後のCI/CDカタログにリストできるパイプライン構築ブロックです。

本日、CI/CDコンポーネントのベータ版が利用可能になったことを発表できることを嬉しく思います。このリリースでは、初期の実験バージョンからコンポーネントのフォルダー構造も改善しました。すでにCI/CDコンポーネントの実験バージョンをテストしている場合は、[新しいフォルダー構造](../../ci/components/_index.md#directory-structure)に移行することが不可欠です。[こちら](https://gitlab.com/gitlab-components/)でいくつかの例を見ることができます。古いフォルダー構造は非推奨となり、今後数回のリリースで削除される予定です。

CI/CDコンポーネントを試す場合は、現在実験的機能として利用可能な新しいCI/CDカタログもぜひ試してみてください。[グローバルCI/CDカタログ](../../ci/components/_index.md)を検索して、他のユーザーが作成し一般公開しているコンポーネントを探すことができます。さらに、独自のコンポーネントを作成する場合は、それらをカタログに公開することもできます！

### CI/CD変数管理のためのUIの改善 {#improved-ui-for-cicd-variable-management}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/418005)

{{< /details >}}

CI/CD変数はGitLab CI/CDの基本的な部分であり、設定UIから変数を操作するためのより良いエクスペリエンスを提供できると感じました。そのため、今回のリリースでは、UIを更新し、新しいドロワーを使用して、CI/CD変数の追加と編集のフローを改善しました。

たとえば、以前はマスクの検証は、CI/CD変数を保存しようとしたときにのみ発生し、それが失敗した場合は、最初からやり直す必要がありました。しかし、新しいドロワーでは、リアルタイムで検証が行われるため、何もやり直すことなく、その場で調整できます！

この変更に関するお客様の[フィードバック](https://gitlab.com/gitlab-org/gitlab/-/issues/428807)は常に貴重であり、感謝しております。

### Runnerフリートダッシュボード - スターターメトリクス (ベータ) {#runner-fleet-dashboard---starter-metrics-beta}

<!-- categories: Runner Fleet -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../ci/runners/runner_fleet_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/424495)

{{< /details >}}

自己管理Runnerフリートのオペレーターは、可観測性と、Runnerフリートインフラストラクチャに関する重要な質問に一目で迅速に答える能力を必要とします。現在、Runnerフリートダッシュボード - 管理ビュー (ベータ) を使用すると、インスタンスRunnerから始めて、重要なフリート管理とデベロッパーエクスペリエンスの質問に迅速に答えるのに役立つ実用的なインサイトが得られます。これらには、どのRunnerにエラーがあるか、CIジョブ実行のためのRunnerキューのパフォーマンス、どのRunnerが最も活発に使用されているかといった質問への回答が含まれます。Ultimateのお客様はこの機能を個別に有効にできますが、[早期導入プログラム](https://gitlab.com/groups/gitlab-org/-/epics/11180)への参加が推奨されます。

## 規模とデプロイ {#scale-and-deployments}

### デフォルトでアーカイブされたプロジェクトを検索結果で非表示にする {#hide-archived-projects-in-search-results-by-default}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/search/_index.md#include-archived-projects-in-search-results) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10957)

{{< /details >}}

以前は、ユーザーはプロジェクトの検索結果に多くのアーカイブされたプロジェクトが表示されていました。これは、アーカイブされたプロジェクトが上位の多くの結果を占めていたため、問題がありました。現在、アーカイブされたプロジェクトはデフォルトで除外され、ユーザーはすべてのプロジェクトを表示するために**アーカイブを含む**を選択できます。

### プライベートグループ名が未認証ユーザーから非表示になる {#private-group-names-are-hidden-from-unauthorized-users}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/manage.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/415165)

{{< /details >}}

以前は、プロジェクトまたはグループのメンバーページにある**グループ**タブにアクセスすると、プライベートグループの名前がすべてのユーザーに表示されていました。セキュリティを強化するため、共有グループ、共有プロジェクト、または招待されたグループのメンバーではないユーザーに対して、プライベートグループの名前とソースをマスクするようになりました。代わりに、この情報は**非公開**として表示されます。

### インポートに失敗したアイテムの包括的なリスト {#comprehensive-list-of-items-that-failed-to-be-imported}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/import/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/386138)

{{< /details >}}

以前は、GitLabプロジェクトとグループを直接転送で移行し、一部のアイテム（マージリクエストやイシューなど）が正常にインポートされなかった場合、[インポートされたグループとプロジェクトのリストページ](../../user/group/import/_index.md)で**詳細**ボタンを選択すると、関連するエラーを確認できました。

しかし、エラーのリストだけでは、合計でいくつのアイテムが、具体的にどのアイテムがインポートされなかったかを理解するのに役立ちませんでした。この情報は、インポートプロセスの結果を理解するために不可欠です。

このリリースでは、**詳細**ボタンを**See failures**リンクに置き換えました。**See failures**リンクを選択すると、特定のグループまたはプロジェクトでインポートに失敗したすべてのアイテムをリストする新しいページに移動します。インポートされなかった各アイテムについて、以下を確認できます:

- アイテムのタイプ。例えば、マージリクエストまたはイシュー。
- 発生したエラーの種類。
- デバッグ目的に役立つ相関ID。
- ソースインスタンス上のアイテムのURL (利用可能な場合、`iid`を持つアイテム)。
- ソースインスタンス上のアイテムのタイトル (利用可能な場合)。例えば、マージリクエストのタイトルまたはイシューのタイトル。

### すべてのユーザー向けの一貫したナビゲーションエクスペリエンス {#consistent-navigation-experience-for-all-users}

<!-- categories: Navigation & Settings -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../tutorials/left_sidebar/_index.md)

{{< /details >}}

16.0リリースでは新しいナビゲーションエクスペリエンスが導入され、2023年6月2日にすべてのユーザーのデフォルトになりました。その後のマイルストーンでは、豊富なユーザーフィードバックに基づいて多くの改善が行われました。古いナビゲーションに戻る機能は削除されました。ナビゲーションにはさらにエキサイティングな変更が計画されていますが、現在のところ、すべてのユーザーは一貫したナビゲーションエクスペリエンスを利用できます。

まとめとして、新しいGitLabナビゲーションでは、次のことができます:

- 最もよく使うプロジェクトまたはグループのアイテムを上部に保存するためにメニューアイテムをピン留めする
- ナビゲーションを非表示にして「必要に応じて一時的に表示」し、より広い画面を表示する
- キーボードショートカットを使用してメニューアイテムを簡単に検索する
- 以前のナビゲーションで使用していたすべてのテーマを継続して使用する
- DevOpsワークフローに合わせた、より整理されたセクションを使用する

### GitLab Silent Mode {#gitlab-silent-mode}

<!-- categories: Disaster Recovery -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/silent_mode/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9826)

{{< /details >}}

GitLab Silent Modeが有効になっている場合、通知メール、インテグレーション、Webhook、およびミラーリングなどのすべての主要な送信トラフィックがGitLabインスタンスからブロックされます。これにより、ユーザーや他のインテグレーションへのトラフィックを生成することなく、GitLabサイトに対するテストを実行できます。Silent Modeを使用すると、プライマリGitLabサイトやエンドユーザーに影響を与えることなく、復元されたバックアップや昇格されたGeo DRサイトをテストできます。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### GitLab UIでのリアルタイムKubernetesステータス更新 {#real-time-kubernetes-status-updates-in-the-gitlab-ui}

<!-- categories: Deployment Management, Environment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/422945)

{{< /details >}}

GitLab 16.6では、環境ページ上のクラスターUIインテグレーションを使用して、GitLabを離れることなく現在実行中のアプリケーションのステータスを判断できます。以前は、UIがロードされたときにステータスが1回のリクエストで更新されていたため、デプロイの進捗状況を追跡するのが困難でした。現在のGitLabバージョンでは、基盤となる接続をアップグレードして、Flux調整とポッドのステータスにKubernetesウォッチAPIを使用し、GitLab UIでクラスターの状態をほぼリアルタイムで更新します。

### GitLab CLIを使用してKubernetesクラスターに接続する {#connect-to-kubernetes-clusters-with-the-gitlab-cli}

<!-- categories: GitLab CLI, Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/user_access.md#access-a-cluster-with-the-kubernetes-api) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11455)

{{< /details >}}

GitLabバージョン16.4から、Kubernetes用のエージェントとパーソナルアクセストークンを使用して、ローカルターミナルからKubernetesクラスターに接続できます。初期バージョンでは、ローカルクラスター設定をセットアップするには、いくつかのコマンドと長期間有効なアクセストークンが必要でした。先月、GitLab CLIを拡張することで、セットアッププロセスのセキュリティを合理化し、改善しました。

GitLab CLIは、GitLabプロジェクトのチェックアウトディレクトリまたは指定されたプロジェクトから利用可能なエージェント接続をリストできるようになりました。選択したエージェントを介して専用コマンドで接続をセットアップできます。`kubectl`またはその他のツールがクラスターで認証する必要がある場合、GitLab CLIはログインユーザー用の一時的で制限されたトークンを生成します。

### コンプライアンスチームが保護ブランチへのプッシュと強制プッシュを防止できるようにする {#allow-compliance-teams-to-prevent-pushing-and-force-pushing-into-protected-branches}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9706)

{{< /details >}}

[セキュリティポリシーのコンプライアンス施行](https://gitlab.com/groups/gitlab-org/-/epics/9704)を支援するためにスキャン結果ポリシーに追加されるいくつかの新しい設定の1つであり、このコントロールは、ポリシーを回避するためにプロジェクトレベルの設定を利用する機能を制限します。

既存または新規のスキャン結果ポリシーごとに、`Prevent pushing and force pushing`を有効にして、ポリシー内で定義されたブランチに適用し、ユーザーがマージリクエストフローを回避して変更をブランチに直接プッシュするのを防ぐことができます。

SaaSでは16.6で利用可能です。Self-managedの場合は、機能フラグ`scan_result_policies_block_force_push`の背後で利用可能であり、16.7でデフォルトで有効になります。

### グループレベルの監査イベントストリーミングからAWS S3へ {#group-level-audit-event-streaming-to-aws-s3}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

外部ログ記録またはデータ集計ツールとのインテグレーションに基づいて、トップレベルグループの監査イベントストリームの宛先としてAWS S3を選択できるようになりました。この機能は、より簡単でトラブルのないインテグレーションのための関連情報を提供します。

以前は、AWS S3が受け入れるリクエストをビルドするために、カスタムHTTPヘッダーを使用する必要がありました。このメソッドはエラーが発生しやすく、トラブルシューティングを行うのが困難でした。

### 応答しない外部ステータスチェックの処理を改善 {#improved-handling-of-unresponsive-external-status-checks}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/project/merge_requests/status_checks.md#status-checks-widget)

{{< /details >}}

以前は、MRに対する外部ステータスチェックは、成功または失敗した応答を受け取るまで、外部URLをポーリングし続けていました。これにより、一部のステータスチェックが応答しない状態でハングアップしているように見える可能性がありました。

現在、2分間のタイムアウトが組み込まれており、外部システムから応答がない場合、2分後にステータスチェックを手動で再試行できます。

### 脆弱性レポートのツールフィルターへの変更 {#changes-to-the-vulnerability-reports-tool-filter}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11237)

{{< /details >}}

以前は、脆弱性レポートでは、GitLabがサポートするツールタイプの静的リストと、カスタムスキャナーの動的リストでフィルタリングできました。今回のリリースでは、アナライザーごとにグループ化されたツールタイプを選択できるようになりました。

### サービスアカウントはオプションの有効期限を持つ {#service-accounts-have-optional-expiry-dates}

<!-- categories: User Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/personal_access_tokens.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/421420)

{{< /details >}}

GitLab管理者とグループオーナーは、サービスアカウントの有効期限を強制するかどうかを選択できます。以前は、サービスアカウントトークンは、パーソナルアクセストークン、プロジェクトアクセストークン、グループアクセストークンの有効期限制限と同様に、1年以内に期限切れになる必要がありました。これにより、管理者とグループオーナーは、セキュリティと使いやすさのバランスを、目標に最も合致する形で選択できます。

### 重複するNuGetパッケージを防止する {#prevent-duplicate-nuget-packages}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/nuget_repository/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/293748)

{{< /details >}}

GitLabパッケージレジストリを使用して、プロジェクトのNuGetパッケージを公開およびダウンロードできます。デフォルトでは、同じパッケージ名とバージョンを複数回公開できます。

ただし、特にリリースの場合、重複するアップロードを防止したい場合があります。このリリースでは、GitLabがパッケージレジストリのグループ設定を拡張し、重複するパッケージアップロードを許可または拒否できるようになりました。

この設定は、[GitLab API](../../api/graphql/reference/_index.md#packagesettings)またはUIから調整できます。

### 基本HTTP認証を使用してMavenリポジトリにパッケージをアップロードする {#upload-packages-to-the-maven-repository-with-basic-http-authentication}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/maven_repository/_index.md#basic-http-authentication) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/277385)

{{< /details >}}

GitLabパッケージレジストリは、基本HTTP認証を使用したMavenパッケージのアップロードをサポートするようになりました。以前は、基本HTTP認証はMavenパッケージのダウンロードにのみ使用できました。この不整合により、開発者がプロジェクトの認証を設定および維持することが困難でした。

`sbt`でのアーティファクトの公開はサポートされていませんが、[イシュー408479](https://gitlab.com/gitlab-org/gitlab/-/issues/408479)でこの機能の追加が提案されています。

### コンテナスキャン: 修正されない検出結果を除外する {#container-scanning-exclude-findings-which-wont-be-fixed}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/container_scanning/_index.md#available-cicd-variables) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/6846)

{{< /details >}}

コンテナスキャンの結果には、ベンダーが評価し、修正しないと決定した検出結果が含まれる場合があります。実用的な検出結果に焦点を当てるために、そのような検出結果を除外することができるようになりました。設定オプションについては、GitLabドキュメントを参照してください。

### 脆弱性レポートのエクスポートにCVSSベクターを含める {#include-cvss-vectors-in-the-vulnerability-report-export}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/11213)

{{< /details >}}

脆弱性レポートから情報をエクスポートすると、CVSSベクター情報が含まれるようになりました。この追加データは、GitLab以外で脆弱性を分析し、トリアージするのに役立ちます。

### Java 21を使用するSBTプロジェクトのサポートを追加 {#added-support-for-sbt-projects-using-java-21}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/421174)

{{< /details >}}

依存関係スキャンとライセンススキャンは、Java 21を使用するSBTプロジェクトをサポートするようになりました。

### DASTアナライザーの更新 {#dast-analyzer-updates}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/application_security/dast/browser/checks/_index.md#active-checks)

{{< /details >}}

16.6リリースマイルストーン中に、ブラウザベースのDASTに対して以下のアクティブなチェックをデフォルトで有効にしました:

- チェック94.1はZAPチェック90019に置き換わり、サーバー側のコードインジェクション (PHP) を識別します。
- チェック94.2はZAPチェック90019に置き換わり、サーバー側のコードインジェクション (Ruby) を識別します。
- チェック94.3はZAPチェック90019に置き換わり、サーバー側のコードインジェクション (Python) を識別します。
- チェック943.1はZAPチェック40033に置き換わり、データクエリロジックにおける特殊要素の不適切な無効化を識別します。
- チェック74.1はZAPチェック90017に置き換わり、XSLTインジェクションを識別します。

### macOS 14 (Sonoma) およびXcode 15イメージのサポート {#macos-14-sonoma-and-xcode-15-image-support}

<!-- categories: GitLab Runner SaaS -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/macos.md#supported-macos-images) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/431424)

{{< /details >}}

チームは、macOS 14およびXcode 15でAppleエコシステム用のアプリケーションをシームレスに作成、テスト、およびデプロイできるようになりました。

macOS上のSaaS Runnerを使用すると、安全なオンデマンドGitLab Runnerビルド環境で、GitLab CI/CDと統合されたmacOSを必要とするアプリケーションのビルドとデプロイにおける開発チームの開発速度を向上させることができます。

今すぐ.GitLab-ci.ymlファイルで`macos-14-xcode-15`をイメージとして使用して試してください。

### GitLab Runner 16.6 {#gitlab-runner-166}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 16.6もリリースしました！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに送信する、軽量で拡張性の高いエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [GCP Compute Engine向けのGitLab Runner Fleetingプラグイン - ベータ](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29409)
- [Docker executor向けのグレースフルシャットダウンを実装する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6359)
- [Kubernetes向けのストレージクラスを持つPVCボリュームを動的に作成する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27835)
- [Kubernetes executorで`image.entrypoint`を介してコンテナエントリポイントをオーバーライドする](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30713)

#### バグ修正 {#bug-fixes}

- [GitLab Runner 16.5.0へのアップグレード後、ポッドがLiveness Probe失敗エラーで再起動し続ける](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36959)
- [デバッグターミナル - 変数にファイルパスではなくファイルの内容が含まれる](https://gitlab.com/gitlab-org/gitlab/-/issues/399770)
- [Kubernetesにおけるジョブ実行ポッドがシグナルを処理しない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28162)
- [GitLab Runner Docker executorでPodmanを使用するサービスが起動しない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29480)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-6-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.6)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.6)
- [UI改善](https://papercuts.gitlab.com/?milestone=16.6)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
