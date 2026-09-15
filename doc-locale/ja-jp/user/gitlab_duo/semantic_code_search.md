---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: キーワードのマッチングではなく、意味に基づいてリポジトリ内の関連するコードスニペットを検索します。
title: セマンティックコード検索
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.7で[ベータ版](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/groups/gitlab-org/-/work_items/16910)されました。
- GitLab 18.8でGitLab Duo Coreに[追加](https://gitlab.com/gitlab-org/gitlab/-/work_items/588259)されました。
- GitLab 18.9でPremiumに[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/590394)されました。

{{< /history >}}

> [!note]
> 管理者向けドキュメントについては、[セマンティックコード検索管理](../../administration/semantic_code_search.md)を参照してください。

キーワード一致ではなく意味に基づいて、リポジトリ内の関連するコードスニペットを検索するには、セマンティックコード検索を使用します。

セマンティックコード検索は、コードベースをベクターデータベースに保存されたベクター埋め込みに変換します。検索すると、あなたのクエリは埋め込みに変換され、あなたのコード埋め込みと比較されて、意味的に類似した結果が検索されます。このアプローチにより、キーワードが一致しない場合でも関連するコードを見つけることができます。

## 前提条件 {#prerequisites}

- GitLab Self-Managedでは、セマンティックコード検索を[インスタンス](../../administration/semantic_code_search.md)に対して有効にします。GitLab.comでは、セマンティックコード検索はデフォルトで有効になっています。
- ベータ機能と実験的機能を有効にします:
  - GitLab.comでは、[トップレベルグループ](../duo_agent_platform/turn_on_off.md#on-gitlabcom-3)に対して有効にします。
  - GitLab Self-Managedでは、[インスタンス](../duo_agent_platform/turn_on_off.md#on-gitlab-self-managed-3)に対して有効にします。
- GitLab Duoを[プロジェクト](../duo_agent_platform/turn_on_off.md)に対して有効にします。

## セマンティックコード検索を使用する {#use-semantic-code-search}

セマンティックコード検索は、複数のインターフェースから利用できます:

- REST API: プログラムでコードベースを検索するには、[`GET /api/v4/projects/:id/search/semantic`エンドポイント](../../api/search.md#semantic-search)を使用します。
- Model Context Protocol（MCP）サーバーツール: エージェント型ワークフローで[`semantic_code_search`](../model_context_protocol/mcp_server_tools.md#semantic_code_search)ツールを使用します。
- CLI: コマンドラインアクセスには、[`glab search semantic`](https://docs.gitlab.com/cli/search/semantic/)コマンドを使用します。

## アドホックな初回インデックス作成 {#ad-hoc-initial-indexing}

GitLabプロジェクトでセマンティックコード検索を初めて使用する場合:

- リポジトリ内のコードのインデックスが作成され、ベクター埋め込みに変換されます。
- これらの埋め込みは、設定済みのベクターストアに保存されます。
- コードがデフォルトブランチにプッシュされると、更新は増分的に処理されます。

大規模なリポジトリの初回インデックス作成には時間がかかる場合があります。
