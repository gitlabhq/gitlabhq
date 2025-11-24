---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platformについて
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- [ベータ](../../policy/development_stages_support.md)版としてGitLab 18.2で導入されました。
- Self-Managedインスタンス上のGitLab Duo Agent Platformでは（[セルフホストモデル](../../administration/gitlab_duo_self_hosted/_index.md)とクラウド接続されたGitLabモデルの両方）、[導入](https://gitlab.com/groups/gitlab-org/-/epics/19213) GitLab 18.4で、`self_hosted_agent_platform`という[機能フラグ](../../administration/feature_flags/_index.md)を使用した[実験](../../policy/development_stages_support.md#experiment)として行われました。デフォルトでは無効になっています。

{{< /history >}}

GitLab Duo Agent Platformを使用すると、複数のAIエージェントが並行して動作し、codeを作成したり、結果を調査したり、タスクを同時に実行したりできます。エージェントは、ソフトウェア開発ライフサイクル全体にわたって完全なコンテキストを持ちます。

エージェントプラットフォームは、[GitLab Duo Chat (Agentic)](../gitlab_duo_chat/agentic_chat.md) 、[エージェント](agents/_index.md) 、[フロー](flows/_index.md)で構成されており、GitLabのユーザーインターフェースとIDEで使用できます。

{{< alert type="note" >}}

エージェントプラットフォームのパブリックベータ版を使用するには、GitLab 18.2以降が必要です。最高のエクスペリエンスで最新のエージェントとフローにアクセスするには、最新バージョンのGitLabを使用してください。

{{< /alert >}}

詳細については、次のブログ投稿をご覧ください:

- [インテリジェントDevSecOpsの今後の展望](https://about.gitlab.com/blog/gitlab-duo-agent-platform-what-is-next-for-intelligent-devsecops/)
- [GitLab Duo Agent Platformパブリックベータ: 次世代AIオーケストレーションなど](https://about.gitlab.com/blog/gitlab-duo-agent-platform-public-beta/)
- [GitLab 18.3: ソフトウェアエンジニアリングにおけるAIオーケストレーションの展開](https://about.gitlab.com/blog/gitlab-18-3-expanding-ai-orchestration-in-software-engineering/)

## 前提要件 {#prerequisites}

エージェントプラットフォームを使用するには:

- [GitLab Duo Coreとフローの実行を含むGitLab Duoをオンにする必要があります](../gitlab_duo/turn_on_off.md)。
- [ベータ版および実験的機能をオンにする必要があります](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)。
- Self-Managedインスタンスの場合は、[インスタンスが構成されていることを確認](../../administration/gitlab_duo/setup.md)する必要があります。
- [セルフホストモデル](../../administration/gitlab_duo_self_hosted/_index.md)によるGitLab Duoの場合は、[GitLab Duo Agent PlatformサービスでAIゲートウェイをインストールして実行](../../install/install_ai_gateway.md)する必要があります。

さらに、IDEでエージェントプラットフォームを使用するには:

- VS Code用GitLab Workflow拡張機能などのエディタ拡張機能をインストールし、GitLabで認証する必要があります。
- [グループネームスペース](../namespace/_index.md)にプロジェクトがあり、少なくともデベロッパーロールが必要です。
- [バックエンドサービスへのHTTP/2接続が可能であることを確認](troubleshooting.md#network-issues)する必要があります。
- [セルフホストモデル](../../administration/gitlab_duo_self_hosted/_index.md)によるGitLab Duoの場合、[gRPCの代わりにWebSocket接続を使用](troubleshooting.md#use-websocket-connection-instead-of-grpc)する必要があります。

## 関連トピック {#related-topics}

- [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md)
- [フロー](flows/_index.md)
