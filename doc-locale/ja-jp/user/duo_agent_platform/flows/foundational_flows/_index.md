---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 基本フロー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)

{{< /collapsible >}}

基本フローはGitLabによって構築および管理されており、GitLab管理バッジ（{{< icon name="tanuki-verified" >}}）が表示されます。

各フローは、特定の問題の解決や開発タスクの支援を目的として設計されています。

次の基本フローを利用できます:

- [ソフトウェア開発](software_development.md): ソフトウェア開発ライフサイクル全体にわたって、AI生成ソリューションを作成します。
- [デベロッパー](developer.md): イシューから実行可能なマージリクエストを作成します。
- [CI/CDパイプラインの修正](fix_pipeline.md): 失敗したジョブを診断して修正します。
- [GitLab CI/CD変換](convert_to_gitlab_ci.md): JenkinsパイプラインをCI/CDに移行します。
- [コードレビュー](code_review.md): AIネイティブな分析とフィードバックにより、コードレビューを自動化します。
- [エージェント型SAST脆弱性の修正](agentic_sast_vulnerability_resolution.md): SASTの脆弱性を解決するために、マージリクエストを自動的に生成します。
- [SASTの誤検出判定](sast_false_positive_detection.md): SASTの検出結果における誤検出を自動的に特定し、フィルタリングします。
- [シークレットの誤検出判定](secret_false_positive_detection.md): シークレット検出で誤検出を自動的に識別してフィルタリングします。

## フローの実行CI/CDの詳細を設定する {#configure-flow-execution-cicd-details}

フローがCI/CD経由で実行される環境を設定できます。

例えば、GitLab Self-Managedでは、管理者が基本フローのイメージ用にカスタムコンテナレジストリを設定できます。

詳細については、[フローの実行を設定する](../execution.md)を参照してください。

## 基本フローのセキュリティ {#security-for-foundational-flows}

GitLab UIでは、基本フローは次のGitLab APIにアクセスできます:

- [プロジェクトAPI](../../../../api/projects.md)
- [イシューAPI](../../../../api/issues.md)
- [マージリクエストAPI](../../../../api/merge_requests.md)
- [リポジトリファイルAPI](../../../../api/repository_files.md)
- [ブランチAPI](../../../../api/branches.md)
- [コミットAPI](../../../../api/commits.md)
- [CIパイプラインAPI](../../../../api/pipelines.md)
- [ラベルAPI](../../../../api/labels.md)
- [エピックAPI](../../../../api/epics.md)
- [ノートAPI](../../../../api/notes.md)
- [検索API](../../../../api/search.md)

### サービスアカウント {#service-accounts}

基本フローは、サービスアカウントを使用してタスクを完了します。詳細については、[複合アイデンティティワークフロー](../../composite_identity.md#composite-identity-workflow)を参照してください。

基本フローがマージリクエストを作成すると、そのマージリクエストはサービスアカウントではなく、フローをトリガーした人間ユーザーに帰属します。これは、職務分掌を必要とするコンプライアンスフレームワークに準拠するために行われます。[コンプライアンスに関する考慮事項](../../composite_identity.md#compliance-considerations-for-merge-requests)を参照してください。

## 基本フローのオン/オフを切り替える {#turn-foundational-flows-on-or-off}

基本フローのオン/オフを切り替えることができます:

- GitLab.comの場合: トップレベルグループおよびプロジェクトの場合。
- GitLab Self-Managed: インスタンス、グループ、およびプロジェクトの場合。

また、フローの実行をオンまたはオフにすることで、コンピューティング時間を消費する機能がGitLab UIで実行できるかどうかを制御できます。これらの機能には、外部エージェント、基本フロー、およびカスタムフローが含まれます。

### GitLab.com {#on-gitlabcom}

{{< tabs >}}

{{< tab title="トップレベルグループの場合" >}}

前提条件: 

- トップレベルグループのオーナーロール。

1. 上部のバーで**検索または移動先**を選択し、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **フローの実行**で、**フロー実行を許可**チェックボックスと**基本フローを許可**チェックボックスを選択します。
1. オンにする各基本フローのチェックボックスを選択します。
1. **変更を保存**を選択します。

トップレベルグループの基本フローをオフにすると、そのグループをデフォルトのGitLab Duoネームスペースとして持つユーザーは、どのネームスペースでも基本フローにアクセスできなくなります。

{{< /tab >}}

{{< tab title="プロジェクトの場合" >}}

前提条件: 

- プロジェクトのオーナーまたはメンテナーロール。
- トップレベルグループでフローの実行と基本フローがオンになっていること。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > 一般**を選択します。
1. **GitLab Duo**を展開します。
1. **GitLab Duo**、**フロー実行を許可**、および**基本フローを許可**のトグルをオンにします。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< /tabs >}}

### GitLab Self-Managed {#on-gitlab-self-managed}

{{< tabs >}}

{{< tab title="インスタンスの場合" >}}

前提条件: 

- 管理者アクセス権が必要です。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **フローの実行**で、**フロー実行を許可**チェックボックスと**基本フローを許可**チェックボックスを選択します。
1. オプション。**イメージレジストリ**テキストボックスに、基本フローイメージ用のコンテナレジストリURLを入力します。デフォルトの`registry.gitlab.com`を使用するには、このテキストボックスを空のままにします。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="グループの場合" >}}

前提条件: 

- 管理者アクセス権が必要です。
- インスタンスでフローの実行と基本フローがオンになっていること。

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **フローの実行**で、**フロー実行を許可**チェックボックスと**基本フローを許可**チェックボックスを選択します。
1. オンにする各基本フローのチェックボックスを選択します。
1. **変更を保存**を選択します。

グループでオンにすると、基本フローはすべてのサブグループとプロジェクトで利用可能になります。

{{< /tab >}}

{{< tab title="プロジェクトの場合" >}}

前提条件: 

- プロジェクトのオーナーまたはメンテナーロール。
- インスタンスとグループでフローの実行と基本フローがオンになっていること。

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > 一般**を選択します。
1. **GitLab Duo**を展開します。
1. **GitLab Duo**、**フロー実行を許可**、および**基本フローを許可**のトグルをオンにします。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< /tabs >}}
