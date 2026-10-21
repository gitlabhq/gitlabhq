---
stage: Agent Foundations
group: Agent Developer
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ソフトウェア開発フロー
---

{{< details >}}

- プラン: [Free](../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- [セルフホストモデル対応のGitLab Duo](../administration/gitlab_duo_self_hosted/_index.md)で利用できます

{{< /collapsible >}}

{{< history >}}

- GitLab 17.4で、`duo_workflow`という名前の[機能フラグを使用した](../administration/feature_flags/_index.md)プライベートベータとして[導入](https://gitlab.com/groups/gitlab-org/-/epics/14153)されました。GitLabチームメンバーのみに対して有効化されました。
- GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効になり、GitLab 18.2でベータに変更されました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。機能フラグ`duo_workflow`は削除されました。
- GitLab 18.10で、GitLab.comのFreeプランにおいてGitLabクレジットを使用して利用できるようになりました。

{{< /history >}}

ソフトウェア開発フローは、ソフトウェア開発ライフサイクル全体にわたって、業務に活用できるAI生成ソリューションの作成に役立ちます。以前はGitLab Duo Workflowと呼ばれていたこのフローには、次の特長があります:

- IDEで実行されるため、コンテキストやツールを切り替える必要はありません。
- プロンプトに応じて計画を作成し、その計画に基づいて作業を進めます。
- 提案された変更をプロジェクトのリポジトリ内でステージングします。提案を受け入れるか、修正するか、却下するかはユーザーが制御できます。
- プロジェクトの構造、コードベース、履歴のコンテキストを理解します。関連するGitLabイシューやマージリクエストなど、独自のコンテキストを追加することもできます。

このフローは、VS Code、Visual Studio、JetBrainsで使用できます。

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platformの前提条件](../user/duo_agent_platform/_index.md#prerequisites)を満たしていること。
- IDE用に[エディタ拡張機能](_index.md)をインストールして設定してください:
  - GitLab for VS Code 6.85.0以降
  - GitLab Duo plugin for JetBrains IDEs 3.40.0以降
  - GitLab for Visual Studio 0.79.0以降
- VS CodeおよびJetBrains IDEでは、[クラシックレイアウト](../user/gitlab_duo_chat/agentic_chat.md#change-the-layout-in-your-ide)を使用してください。新しいレイアウトにはフローが含まれていません。

## フローとチャットの比較 {#flow-and-chat-comparison}

ソフトウェア開発フローとGitLab Duo Chatは、どちらもIDEで利用できます。クラシックレイアウトでは、これらは別々のタブに表示されます。

複雑な開発タスクには、ソフトウェア開発フローを使用してください。

- フローは包括的なコンテキストを収集し、レビュー用の詳細な計画を作成し、タスクを体系的に進めます。
- フローは構造化されたアプローチを使用しており、大きなコンテキストウィンドウが必要な長時間かつ深いセッションに適しており、反復が必要なコード生成でより良い結果を生み出します。
- 各フローには開始と終了があります。新しいフローを開始すると、再度コンテキストを収集し、プロジェクトの現在の状態に基づいて新しい計画を作成します。

方向性を自分で導く会話形式のやり取りには、GitLab Duo Chatを使用してください。

- Chatは質問に答えるための情報を収集し、提案を提供し、プロンプトに応じて自律的にアクションを実行できます。
- Chatは継続的な会話を維持するため、進行中のディスカッションに戻り、中断したところから続けることができます。

どちらも同様のタスクに役立ちますが、動作は異なります。フローは事前に包括的なコンテキストを収集し、人の関与を最小限に抑えて実行します。Chatはユーザーとの継続的なフィードバックループとして動作し、会話中に必要に応じてコンテキストを収集します。たとえば、フローはアプローチを提案する前に異なる解決策を検討しますが、Chatはすぐに実行可能な最初の方法に進み、迅速な結果を提供します。

## ソフトウェア開発フローを使用する {#use-the-software-development-flow}

このフローを使用するには:

1. IDEで、**GitLab Duo Agent Platform**（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. **フロー**タブを選択します。
1. テキストボックスに、コードタスクを詳細に指定します。
   - このフローは、プロジェクトブランチに含まれる、Git管理下のすべてのファイルを認識しています。
   - チャットに[コンテキスト](../user/duo_agent_platform/context.md#gitlab-duo-agentic-chat)を追加できます。
   - このフローは、外部ソースやWebにはアクセスできません。
   - 例: 

     ```plaintext
     I have a large Ruby class that is used in a few places and I want to break it down.
     Analyze this class and see what sub-methods or properties can be delegated to a
     separate class. Then, propose a transition plan to implement this new sub-class
     and update all of the required tests.
     ```

1. **開始**を選択します。

タスクを説明すると、フローは計画を生成して実行します。フローを一時停止したり、計画の調整を依頼したりできます。

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

- [プロジェクトAPI](../api/projects.md)
- [検索API](../api/search.md)
- [CIパイプラインAPI](../api/pipelines.md)
- [CIジョブAPI](../api/jobs.md)
- [ジョブアーティファクトAPI](../api/job_artifacts.md)
- [デプロイAPI](../api/deployments.md)
- [マージリクエストAPI](../api/merge_requests.md)
- [エピックAPI](../api/epics.md)
- [イシューAPI](../api/issues.md)
- [ノートAPI](../api/notes.md)
- [使用量データAPI](../api/usage_data.md)
- [メタデータAPI](../api/metadata.md)（非推奨の`/version`エンドポイントを含む）

## 監査ログ {#audit-log}

ソフトウェア開発フローは、APIリクエストごとに監査イベントを生成します。GitLab Self-Managedインスタンスでは、[インスタンス監査イベント](../administration/compliance/audit_event_reports.md#instance-audit-events)ページでこれらのイベントを確認できます。

## リスク {#risks}

ソフトウェア開発フローは、GitLabアカウントを使用してアクションを実行できるAIエージェントを使用します。大規模言語モデルに基づくAIツールは、予測不可能な場合があります。使用する前に、潜在的なリスクを確認してください。

VS Code、JetBrains IDE、Visual Studioにおけるソフトウェア開発フローは、ローカルワークステーションでワークフローを実行します。この製品を有効にする前に、記載されているすべてのリスクを考慮してください。主なリスクは次のとおりです:

- ソフトウェア開発フローは、Gitで追跡されていないファイルや`.gitignore`で除外されているファイルを含め、プロジェクトのローカルファイルシステム内のファイルにアクセスできます。これには、`.env`ファイル内の認証情報などの機密情報が含まれる場合があります。
- ソフトウェア開発フローには、`ai_workflows`スコープを持つ、ユーザーIDに関連付けられた有効期限付きのGitLab OAuthトークンが付与されます。このトークンを使用すると、ワークフローの実行期間中、指定されたGitLab APIへのアクセスが可能になります。デフォルトでは、明示的な承認なしで実行されるのは読み取り操作のみですが、権限に応じて書き込み操作が行われる可能性があります。
- ソフトウェア開発フローに追加の認証情報やシークレットを（メッセージや目標などで）提供しないでください。意図せず使用されたり、コードやAPI呼び出しで公開されたりする可能性があります。
