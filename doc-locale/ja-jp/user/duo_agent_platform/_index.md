---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platform
---

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://www.anthropic.com/claude/sonnet)
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 18.2で[ベータ版](../../policy/development_stages_support.md)として導入されました。
- Self-Managedインスタンス上のGitLab Duo Agent Platform（[セルフホストモデル](../../administration/gitlab_duo_self_hosted/_index.md)およびクラウド接続されたGitLabモデルの両方）では、GitLab 18.4で[実験的機能](../../policy/development_stages_support.md#experiment)として、`self_hosted_agent_platform`[機能フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/19213)されました。デフォルトでは無効になっています。
- GitLab 18.7で機能フラグ`self_hosted_agent_platform`は[有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208951)になりました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

GitLab Duo Agent Platformは、複数のインテリジェントなアシスタント（「エージェント」）をソフトウェア開発ライフサイクル全体に組み込むAIネイティブソリューションです。

- 線形のワークフローに従う代わりに、AIエージェントと非同期的に共同作業を行います。
- コードリファクタリングやセキュリティスキャンから調査まで、ルーチンタスクを専門のAIエージェントに委任します。

エージェントプラットフォームは[いくつかの機能](../gitlab_duo/feature_summary.md)で構成されており、GitLab UIとIDEで利用できます。

<i class="fa-youtube-play" aria-hidden="true"></i>エージェントプラットフォームが従来の時間のかかるワークフローをどのように改善できるかの例については、[GitLab Duo Agent Platformを使用したデベロッパーオンボーディング](https://youtu.be/UD8vAAglkY0?si=7AWWDfd-mLGdkBwT)を参照してください。
<!-- Video published on 2025-11-20 -->

## 前提条件 {#prerequisites}

エージェントプラットフォームを使用するには、次のものが必要です:

- GitLab 18.2以降を使用してください。最高の体験を得るには、最新バージョンのGitLabを使用してください。
- [GitLab Credits](../../subscriptions/gitlab_credits.md)を購入済みであること。
- [GitLab Duo（GitLab Duo Coreとフロー実行を含む）がオンになっている](../gitlab_duo/turn_on_off.md)必要があります。
- ご使用のGitLabバージョンに応じて:
  - GitLab 18.8以降では、[エージェントプラットフォームをオンにする](../gitlab_duo/turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off)必要があります。
  - GitLab 18.7以前では、[ベータ版および実験的機能をオンにする](../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)必要があります。
- GitLab Self-Managedの場合は、[インスタンスが構成されていることを確認する](../../administration/gitlab_duo/configure/gitlab_self_managed.md)必要があり、コンポジットIDがオンになっている必要があります。
- [セルフホストモデルを使用したGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)の場合、[GitLab Duo Agent PlatformサービスでAIゲートウェイをインストールして実行する](../../install/install_ai_gateway.md)必要があります。

さらに、IDEでエージェントプラットフォームを使用するには、次のものが必要です:

- エディタ拡張機能（VS Code用GitLab Workflow拡張機能など）をインストールし、GitLabで認証する必要があります。
- [グループネームスペース](../namespace/_index.md)にプロジェクトがあり、少なくともデベロッパーロールが必要です。

## はじめに {#getting-started}

開始するには、[GitLab Duo Agent Platformの使用を開始する](../get_started/get_started_agent_platform.md)を参照してください。

## 関連トピック {#related-topics}

- [GitLab Duo Chat（エージェント）](../gitlab_duo_chat/agentic_chat.md)
- [AIカタログ](ai_catalog.md)
- [エージェント](agents/_index.md)
- [フロー](flows/_index.md)
