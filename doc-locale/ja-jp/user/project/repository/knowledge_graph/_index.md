---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AI機能の強化とデベロッパーの生産性向上を目的に、GitLab Knowledge Graphを使用して、コードリポジトリの構造化されたクエリ可能な表現を作成します。
title: GitLab Knowledge Graph
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ版

{{< /details >}}

{{< history >}}

- GitLab 18.3で[導入](https://gitlab.com/groups/gitlab-org/rust/-/epics/11)され、[実験](../../../../policy/development_stages_support.md#experiment)となりました。
- GitLab 18.4で[ベータ](../../../../policy/development_stages_support.md#beta)版に変更されました。

{{< /history >}}

The [GitLab Duo Agent Platform](../../../duo_agent_platform/_index.md)は、[GitLab Knowledge Graph](https://gitlab-org.gitlab.io/rust/knowledge-graph)を使用してAIエージェントの精度を向上させます。知識グラフフレームワークをAIプロジェクトで使用すると、コードベース全体で豊富なコードインテリジェンスを有効にできます。たとえば、Retrieval-Augmented Generation (RAG) アプリケーションをビルドする際、知識グラフはコードベースをAIエージェント用のライブの埋め込み可能なグラフデータベースに変換します。知識グラフは、アーキテクチャの可視化も作成します。これにより、システムの構造と依存関係に関する洞察的な図が提供されます。

知識グラフフレームワークは、1行のスクリプトでインストールできます。ローカルリポジトリを解析し、Model Context Protocol（MCP）を使用してプロジェクトをクエリして接続します。知識グラフは、ファイル、ディレクトリ、クラス、関数などのエンティティとその関係をキャプチャします。この追加されたコンテキストにより、高度なコード理解とAI機能が可能になります。たとえば、これによりGitLab Duoエージェントはローカルワークスペース全体の関係を理解し、複雑な質問に対してより迅速かつ正確な応答を可能にします。

知識グラフは、コードをスキャンして以下を識別します:

- 構造要素: アプリケーションの根幹をなすファイル、ディレクトリ、クラス、関数、およびモジュール。
- コードの関係: 関数呼び出し、継承階層、モジュール依存関係などの複雑な接続。

知識グラフにはCLIも搭載されています。知識グラフCLI（`gkg`）およびフレームワークの詳細については、[知識グラフプロジェクトドキュメント](https://gitlab-org.gitlab.io/rust/knowledge-graph)を参照してください。

## フィードバック {#feedback}

この機能はベータ版です。[イシュー160](https://gitlab.com/gitlab-org/rust/knowledge-graph/-/issues/160)でフィードバックをお寄せください。
