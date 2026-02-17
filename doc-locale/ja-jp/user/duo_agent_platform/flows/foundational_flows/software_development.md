---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ソフトウェア開発フロー
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

この機能は、[GitLabクレジット](../../../../subscriptions/gitlab_credits.md)を使用します。

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- [セルフホストモデル対応のGitLab Duo](../../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 17.4で`duo_workflow`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/14153)されました。GitLabチームメンバーのみに対して有効化されました。この機能は[プライベートベータ版](../../../../policy/development_stages_support.md)です。
- GitLab 18.2で[名称が変更](https://gitlab.com/gitlab-org/gitlab/-/issues/551382)され、`duo_workflow`[フラグが有効化](../../../../administration/feature_flags/_index.md)され、ステータスがベータ版に変更されました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

ソフトウェア開発フローは、ソフトウェア開発ライフサイクル全体にわたって、業務に活用できるAI生成ソリューションの作成に役立ちます。以前はGitLab Duo Workflowと呼ばれていたこのフローには、次の特長があります:

- IDEで実行されるため、コンテキストやツールを切り替える必要はありません。
- プロンプトに応じて計画を作成し、その計画に基づいて作業を進めます。
- 提案された変更をプロジェクトのリポジトリ内でステージングします。提案を受け入れるか、修正するか、却下するかはユーザーが制御できます。
- プロジェクトの構造、コードベース、履歴のコンテキストを理解します。関連するGitLabイシューやマージリクエストなど、独自のコンテキストを追加することもできます。

このフローは、VS Code、Visual Studio、JetBrainsで使用できます。

## ソフトウェア開発フローを使用する {#use-the-software-development-flow}

前提条件: 

- IDE用の[エディタ拡張機能](../../../../editor_extensions/_index.md)をインストールして設定します。
- [その他の前提条件](../../../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

このフローを使用するには:

1. 左側のサイドバーで、**GitLab Duo Agent Platform (Beta)**（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. **フロー**タブを選択します。
1. テキストボックスに、コードタスクを詳細に指定します。
   - このフローは、プロジェクトブランチに含まれる、Git管理下のすべてのファイルを認識しています。
   - チャットに[コンテキスト](../../../gitlab_duo/context.md#gitlab-duo-chat)を追加できます。
   - このフローは、外部ソースやWebにはアクセスできません。
1. **開始**を選択します。

タスクを記述すると、計画が生成され実行されます。計画を一時停止したり、計画の調整を依頼したりすることもできます。

## サポートされている言語 {#supported-languages}

ソフトウェア開発フローは、次の言語を正式にサポートしています:

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

ソリューションを作成し、問題のコンテキストを理解するために、このフローはいくつかのGitLab APIにアクセスします。

具体的には、`ai_workflows`スコープを持つOAuthトークンは、次のAPIにアクセスできます:

- [プロジェクトAPI](../../../../api/projects.md)
- [検索API](../../../../api/search.md)
- [CIパイプラインAPI](../../../../api/pipelines.md)
- [CIジョブAPI](../../../../api/jobs.md)
- [マージリクエストAPI](../../../../api/merge_requests.md)
- [エピックAPI](../../../../api/epics.md)
- [イシューAPI](../../../../api/issues.md)
- [ノートAPI](../../../../api/notes.md)
- [使用状況データAPI](../../../../api/usage_data.md)

## 監査ログ {#audit-log}

ソフトウェア開発フローによって実行されるAPIリクエストごとに、監査イベントが作成されます。GitLab Self-Managedインスタンスでは、[インスタンス監査イベント](../../../../administration/compliance/audit_event_reports.md#instance-audit-events)ページでこれらのイベントを確認できます。

## リスク {#risks}

ソフトウェア開発フローはベータ版の機能であり、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)の対象となります。このツールは、GitLabアカウントを使用してアクションを実行できるAIエージェントを使用します。大規模言語モデルに基づくAIツールは予測できない挙動を示す可能性があるため、使用する前に潜在的なリスクを確認してください。

VS Code、JetBrains IDE、Visual Studioにおけるソフトウェア開発フローは、ローカルワークステーションでワークフローを実行します。この製品を有効にする前に、記載されているすべてのリスクを考慮してください。主なリスクは次のとおりです:

1. ソフトウェア開発フローは、Gitによって追跡されていないファイルや`.gitignore`で除外されているファイルなど、プロジェクトのローカルファイルシステム内のファイルにアクセスできます。これには、`.env`ファイル内の認証情報などの機密情報が含まれる場合があります。
1. ソフトウェア開発フローには、`ai_workflows`スコープを持つ、ユーザーIDに関連付けられた有効期限付きのGitLab OAuthトークンが付与されます。このトークンを使用すると、ワークフローの実行期間中、指定されたGitLab APIへのアクセスが可能になります。デフォルトでは、明示的な承認なしで実行されるのは読み取り操作のみですが、権限に応じて書き込み操作が行われる可能性があります。
1. たとえばメッセージや目的を通じて、追加の認証情報やシークレットをソフトウェア開発フローに提供しないでください。これらは意図せず使用されたり、コードやAPIコール内で公開されたりする可能性があります。

## フィードバックを提供する {#give-feedback}

ソフトウェア開発フローはベータ版です。皆様からのフィードバックは、本機能を改善し、すべてのユーザーにとって有用なものにするために不可欠です。問題の報告または改善点の提案を行うには、[こちらのアンケートにご記入ください](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu)。
