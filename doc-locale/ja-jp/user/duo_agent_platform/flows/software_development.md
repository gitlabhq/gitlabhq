---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ソフトウェア開発フロー
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 17.4で`duo_workflow`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/14153)されました。GitLabチームメンバーのみに有効。この機能は[プライベートベータ](../../../policy/development_stages_support.md)です。
- [名前が変更](https://gitlab.com/gitlab-org/gitlab/-/issues/551382)され、`duo_workflow` [機能フラグが有効化](../../../administration/feature_flags/_index.md)され、GitLab 18.2でステータスがベータに変更されました。
- Self-Managedインスタンス上のGitLab Duo Agent Platform（[セルフホストモデル](../../../administration/gitlab_duo_self_hosted/_index.md)とクラウド接続されたGitLabモデルの両方）の場合、GitLab 18.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/19213)され、`self_hosted_agent_platform`という[機能フラグ](../../../administration/feature_flags/_index.md)による[実験](../../../policy/development_stages_support.md#experiment)として導入されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

ソフトウェア開発フローは、ソフトウェア開発ライフサイクル全体での作業のために、AIによって生成されたソリューションを作成するのに役立ちます。以前はGitLab Duo Workflowと呼ばれていましたが、このフローは次のとおりです:

- IDEで実行されるため、コンテキストやツールを切り替える必要はありません。
- プロンプトに応じて、計画を作成し、実行します。
- プロジェクトのリポジトリに提案された変更をステージングします。提案を受け入れるか、修正するか、拒否するかを制御できます。
- プロジェクト構造、コードベース、履歴のコンテキストを理解します。関連するGitLabイシューまたはマージリクエストなど、独自のコンテキストを追加することもできます。

このフローは、VS Code、Visual Studio、およびJetBrainsで利用できます。

## ソフトウェア開発フローの使用 {#use-the-software-development-flow}

前提要件: 

- IDE用の[エディタ拡張機能](../../../editor_extensions/_index.md)をインストールして構成します。
- [他の前提条件](../../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

フローを使用するには:

1. 左側のサイドバーで、**GitLab Duo Agent Platform (Beta)**（GitLab Duo Agent Platform（ベータ版））（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. **フロー**タブを選択します。
1. テキストボックスに、コードタスクの詳細を指定します。
   - このフローは、プロジェクトブランチ内のGitで利用可能なすべてのファイルを認識します。
   - チャットに[コンテキスト](../../gitlab_duo/context.md#gitlab-duo-chat)を追加できます。
   - このフローは、外部ソースまたはWebにアクセスできません。
1. **開始**を選択します。

タスクを記述すると、計画が生成され、実行されます。計画を一時停止したり、調整するように要求したりできます。

## サポートされている言語 {#supported-languages}

ソフトウェア開発フローは、公式に次の言語をサポートしています:

- CSS
- Go
- HTML
- Java
- JavaScript
- Markdown
- Python
- Ruby
- TypeScript

## フローがアクセスできるAPI {#apis-that-the-flow-has-access-to}

ソリューションを作成し、問題のコンテキストを理解するために、フローはいくつかのGitLab APIにアクセスします。

具体的には、`ai_workflows`スコープを持つOAuthトークンは、次のAPIへのアクセス権を持ちます:

- [プロジェクトAPI](../../../api/projects.md)
- [検索API](../../../api/search.md)
- [CIパイプラインAPI](../../../api/pipelines.md)
- [CIジョブAPI](../../../api/jobs.md)
- [マージリクエストAPI](../../../api/merge_requests.md)
- [エピックAPI](../../../api/epics.md)
- [イシューAPI](../../../api/issues.md)
- [ノートAPI](../../../api/notes.md)
- [使用状況データAPI](../../../api/usage_data.md)

## 監査ログ {#audit-log}

ソフトウェア開発フローによって行われたAPIリクエストごとに監査イベントが作成されます。GitLab Self-Managedインスタンスでは、これらのイベントを[インスタンス監査イベント](../../../administration/compliance/audit_event_reports.md#instance-audit-events)ページで表示できます。

## リスク {#risks}

ソフトウェア開発フローはベータ機能であり、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)の対象となります。このツールは、GitLabアカウントを使用してアクションを実行できるAIエージェントを使用します。大規模言語モデルに基づくAIツールは予測不可能である可能性があるため、使用前に潜在的なリスクを確認してください。

VS Code、JetBrains IDE、およびVisual Studioのソフトウェア開発フローは、ローカルワークステーションでワークフローを実行します。この製品を有効にする前に、ドキュメント化されたすべてのリスクを考慮してください。主なリスクは次のとおりです:

1. ソフトウェア開発フローは、Gitによって追跡されていない、または`.gitignore`で除外されているファイルを含む、プロジェクトのローカルファイルシステム内のファイルにアクセスできます。これには、`.env`ファイル内の認証情報などの機密情報が含まれる場合があります。
1. ソフトウェア開発フローには、ユーザーIDにリンクされた`ai_workflows`スコープを持つ時間制限付きのGitLab OAuthトークンが付与されます。このトークンを使用すると、ワークフローの期間中、指定されたGitLab APIにアクセスできます。デフォルトでは、明示的な承認なしで読み取り操作のみが実行されますが、権限に基づいて書き込み操作も可能です。
1. コードまたはAPIコールで意図せずに使用または公開される可能性があるため、（メッセージや目標などで）追加の認証情報やシークレットをソフトウェア開発フローに提供しないでください。

## フィードバックを提供する {#give-feedback}

ソフトウェア開発フローはベータ版であり、フィードバックはあなたや他の人のために改善するために重要です。問題をレポートしたり、改善を提案したりするには、[この調査にご協力ください](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu)。
