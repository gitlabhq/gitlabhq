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
- [セルフホストモデル](../../../../administration/gitlab_duo_self_hosted/_index.md)対応のGitLab Duoで利用可能:

{{< /collapsible >}}

{{< history >}}

- GitLab 17.4で`duo_workflow`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/14153)されました。GitLabチームのメンバーのみが有効です。この機能は[プライベートベータ](../../../../policy/development_stages_support.md)版です。
- [名前が変更](https://gitlab.com/gitlab-org/gitlab/-/issues/551382)され、`duo_workflow` [フラグが有効](../../../../administration/feature_flags/_index.md)になり、ステータスがGitLab 18.2でベータ版に変更されました。
- Self-Managedインスタンス ([セルフホストモデル](../../../../administration/gitlab_duo_self_hosted/_index.md)とクラウド接続されたGitLabモデルの両方) 上のGitLab Duoエージェントプラットフォームでは、`self_hosted_agent_platform`という[機能フラグ](../../../../administration/feature_flags/_index.md)を使用した[実験](../../../../policy/development_stages_support.md#experiment)として、GitLab 18.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/19213)されました。デフォルトでは無効になっています。
- 機能フラグ`self_hosted_agent_platform`がGitLab 18.7で[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951)になりました。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

ソフトウェア開発は、ソフトウェア開発ライフサイクル全体で、AIによって生成されたソリューションの作成に役立ちます。以前はGitLab Duoワークフローと呼ばれていましたが、このワークフローは以下のとおりです:

- IDEで実行されるため、コンテキストやツールを切り替える必要はありません。
- プロンプトに応じて、計画を作成し、実行します。
- プロジェクトのリポジトリで提案された変更をステージングします。提案を受け入れるか、変更するか、拒否するかを制御できます。
- プロジェクトの構造、コードベース、および履歴のコンテキストを理解します。関連するGitLabイシューまたはマージリクエストなど、独自のコンテキストを追加することもできます。

このワークフローは、VS Code、Visual Studio、およびJetBrainsで使用できます。

## ソフトウェア開発フローを使用する {#use-the-software-development-flow}

前提要件:

- IDE用の[エディタ拡張機能](../../../../editor_extensions/_index.md)をインストールして設定します。
- [その他の前提条件](../../../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

このワークフローを使用するには:

1. 左側のサイドバーで、**GitLab Duo Agent Platform (Beta)**（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. 左側のサイドバーで、**フロー**タブを選択します。
1. テキストボックスに、コードタスクを詳細に指定します。
   - このワークフローは、プロジェクトブランチ内のGitで使用可能なすべてのファイルを認識しています。
   - チャットに[コンテキスト](../../../gitlab_duo/context.md#gitlab-duo-chat)を追加できます。
   - このワークフローは、外部ソースまたはウェブにアクセスできません。
1. **開始**を選択します。

タスクを記述すると、計画が生成され実行されます。計画を一時停止したり、調整するように依頼したりできます。

## サポートされている言語 {#supported-languages}

ソフトウェア開発は、正式には次の言語をサポートしています:

- CSS
- Go
- HTML
- Java
- JavaScript
- Markdown
- Python
- Ruby
- TypeScript

## このワークフローがアクセスできるAPI {#apis-that-the-flow-has-access-to}

ソリューションを作成し、問題のコンテキストを理解するために、このワークフローはいくつかのGitLab APIにアクセスします。

具体的には、`ai_workflows`スコープを持つOAuthトークンは、次のAPIへのアクセス権を持っています:

- [プロジェクトAPI](../../../../api/projects.md)
- [検索API](../../../../api/search.md)
- [CIパイプラインAPI](../../../../api/pipelines.md)
- [CI Jobs API](../../../../api/jobs.md)
- [マージリクエストAPI](../../../../api/merge_requests.md)
- [エピックAPI](../../../../api/epics.md)
- [イシューAPI](../../../../api/issues.md)
- [ノートAPI](../../../../api/notes.md)
- [Usage Data API](../../../../api/usage_data.md)

## 監査ログ {#audit-log}

ソフトウェア開発によって行われたAPIリクエストごとに監査イベントが作成されます。GitLab Self-Managedインスタンスでは、[インスタンス監査イベント](../../../../administration/compliance/audit_event_reports.md#instance-audit-events)ページでこれらのイベントを表示できます。

## リスク {#risks}

ソフトウェア開発はベータ版の機能であり、[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)の対象となります。このツールは、GitLabアカウントを使用してアクションを実行できるAIエージェントを使用します。大規模言語モデルに基づくAIツールは予測できない可能性があるため、使用前に潜在的なリスクをレビューしてください。

VS Code、JetBrains IDE、およびVisual Studioのソフトウェア開発は、ローカルのワークステーションでワークフローを実行します。この製品を有効にする前に、ドキュメント化されているすべてのリスクを考慮してください。主なリスクは次のとおりです:

1. ソフトウェア開発は、Gitによって追跡されていないファイルや`.gitignore`で除外されているファイルなど、プロジェクトのローカルファイルシステム内のファイルにアクセスできます。これには、`.env`ファイル内の認証情報などの機密情報が含まれる場合があります。
1. ソフトウェア開発には、ユーザーIDにリンクされた、`ai_workflows`スコープを持つ時間制限付きのGitLab OAuthトークンが付与されます。このトークンを使用すると、ワークフローの期間中、指定されたGitLab APIにアクセスできます。デフォルトでは、明示的な承認なしで読み取り操作のみが実行されますが、書き込み操作はアクセス許可に基づいて可能です。
1. ソフトウェア開発に追加の認証情報やシークレット（メッセージやゴールなど）を提供しないでください。これらは意図せずに使用されたり、コードやAPIコールで公開されたりする可能性があるためです。

## フィードバックを提供する {#give-feedback}

ソフトウェア開発はベータ版であり、お客様や他のユーザーのために改善するには、お客様からのフィードバックが不可欠です。問題のレポートや改善点の提案を行うには、[このアンケートにご記入ください](https://gitlab.fra1.qualtrics.com/jfe/form/SV_9GmCPTV7oH9KNuu)。
