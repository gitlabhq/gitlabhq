---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duoエージェントプラットフォームを使い始める
---

GitLab Duo Agent Platformは、複数のインテリジェントなアシスタント（「エージェント」）をソフトウェア開発ライフサイクル全体に組み込む、AIネイティブソリューションです。

- 線形のワークフローに従う代わりに、AIエージェントと非同期的にコラボレーションします。
- コードリファクタリングやセキュリティスキャンから調査まで、ルーチンタスクを特化型AIエージェントに委任します。

エージェントプラットフォームは、いくつかの機能で構成されており、GitLab UIとIDEで使用できます。

## ステップ1: GitLab Duo Chatにアクセスする {#step-1-access-gitlab-duo-chat}

UIまたはIDEのGitLab Duo Chat（エージェント）は、質問をしたり、エージェントとやり取りするためのインターフェースです。アドバイスを提供するだけでなく、ソリューションを提案して実装することもできます。

Chatは、イシュー、マージリクエスト、コミット、CI/CDパイプラインなどのプロジェクトにアクセスでき、Chatは会話全体でコンテキストを維持します。複雑さを徐々に高め、以前の応答を参照し、目的の結果に達するまでイテレーションを行うことができます。

GitLab Duo Chatは、GitLab UIとさまざまなIDEで利用できます。

詳細については、以下を参照してください: 

- [GitLab Duo Chat（エージェント）](../gitlab_duo_chat/agentic_chat.md)。

## ステップ2: エージェントを操作する {#step-2-work-with-agents}

エージェントは、特定のワークフロー向けに設計された、特殊なAIアシスタントです。

- 基盤となるエージェントはデフォルトで使用可能で、一般的な開発タスクを処理します。GitLab Duoエージェントは、質問、説明、コードナビゲーションに関する一般的な支援を提供します。他の基盤となるエージェントは、リリースの計画やコードの保護などを支援します。
- カスタムエージェントは、組織がチーム固有のワークフローに対応するために作成します。コードレビュー標準、コンプライアンスチェック、デプロイの自動化、またはチームに固有のワークフローのためのエージェントをビルドできます。
- 外部エージェントは、既に使用しているAIモデルプロバイダーとGitLabを統合します。イシュー、エピック、およびマージリクエストから外部エージェントをトリガーします。

詳細については、以下を参照してください: 

- [エージェントの概要](../duo_agent_platform/agents/_index.md)。
- [基盤エージェント](../duo_agent_platform/agents/foundational_agents/_index.md)。
- [カスタムエージェント](../duo_agent_platform/agents/custom.md)。
- [外部エージェント](../duo_agent_platform/agents/external.md)。

## ステップ3: フローで複数のエージェントをまとめて使用する {#step-3-use-multiple-agents-together-in-a-flow}

フローとは、1つ以上のエージェントが連携してタスクを完了する組み合わせのことです。フローは、通常、ツールまたはチームメンバー間の手動による調整が必要となる複数ステップのワークフローを自動化するのに役立ちます。

たとえば、マージリクエストからフローをトリガーすると、フローはセキュリティスキャンの実行、コードのレビュー、テストの生成、およびドキュメントのドラフト作成を行うことができます。

GitLabは、IDEのソフトウェア開発フローや、CI/CDパイプラインの変換や修正などの処理を行うUIのフローなどの、基盤となるフローを提供します。独自のカスタムフローを作成することもできます。

AIカタログは、エージェントとフローを見つけて作成し、プロジェクトで使用できるようにする中心的な場所です。

詳細については、以下を参照してください: 

- [フロー](../duo_agent_platform/flows/_index.md)。
- [AIカタログ](../duo_agent_platform/ai_catalog.md)。
- [トリガー](../duo_agent_platform/triggers/_index.md)。

## ステップ4: エージェントアクティビティーを監視およびレビューする {#step-4-monitor-and-review-agent-activity}

エージェントが実行するアクションは、ログを含むセッションで追跡されます。セッションは、デバッグの支援、学習の促進、および監査要件のサポートに役立ちます。

セッションを表示するには、プロジェクトに移動し、**自動化** > **セッション**を選択します。

詳細については、以下を参照してください: 

- [セッション](../duo_agent_platform/sessions/_index.md)。

## ステップ5: インテグレーションで機能を拡張する {#step-5-extend-capabilities-with-integrations}

AIエージェントの知識を増やすには、ナレッジグラフを使用します。これは、コードリポジトリの構造化された表現を作成し、エージェントとチームがファイル、関数、および依存関係間の関係をより良く理解するのに役立ちます。

外部ツールおよびデータソースと接続することにより、GitLab以外のプラットフォームを拡張することもできます。

- GitLab Duo Chat（エージェント）のようなGitLab Duo機能と外部MCPサーバーを接続して、他のMCPクライアントがより包括的な支援を提供できるようにします。
- MCPサーバーは反対方向に動作します。Claude DesktopやCursorのような外部AIツールはGitLabインスタンスに安全に接続でき、これらのツールにGitLabデータへのアクセスを提供します。

詳細については、以下を参照してください: 

- [ナレッジグラフ](../project/repository/knowledge_graph/_index.md)。
- [MCPクライアント](../gitlab_duo/model_context_protocol/mcp_clients.md)。
- [MCPサーバー](../gitlab_duo/model_context_protocol/mcp_server.md)。

## リソース {#resources}

- 8部構成のチュートリアル: [GitLab Duoエージェントプラットフォームを使い始める: 完全ガイド](https://about.gitlab.com/blog/gitlab-duo-agent-platform-complete-getting-started-guide/)
- ブログ: [GitLabエンジニア: AIでオンボーディング体験をどのように改善したか](https://about.gitlab.com/blog/gitlab-engineer-how-i-improved-my-onboarding-experience-with-ai/)
- 講演録音: [GitLab Duo Agent PlatformにおけるAgentic AI | ユースケースとベストプラクティス | DACHロードショーウィーン2025](https://www.youtube.com/watch?v=amJQkKhe5ys) （[スライド](https://docs.google.com/presentation/d/e/2PACX-1vTX-DcBV9Rw6HQ7vNew8EWRv1NMGtKfRbb5eATRb9tENrOUbnbPdZJwXnub2OMnqv-nIV_v0hIQB6Ew/pub?start=false&loop=false&delayms=3000&slide=id.g38ddaede31e_0_36)）
<!-- Video published on 2025-12-09 -->
