---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: AI人工知能機能を強化し、デベロッパーの生産性を高めるために、コードリポジトリの構造化されたクエリ可能な表現をGitLab Knowledge Graphで作成します。
title: GitLab Knowledge Graph
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 18.3で[実験](../../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/groups/gitlab-org/rust/-/epics/11)されました。
- GitLab 18.4で[ベータ](../../../../policy/development_stages_support.md#beta)に移行しました。

{{< /history >}}

[GitLab Duo Agent Platform](../../../duo_agent_platform/_index.md)は、[GitLab Knowledge Graph](https://gitlab-org.gitlab.io/rust/knowledge-graph)を使用して、AIエージェントの精度を高めます。AIプロジェクトでKnowledge Graphフレームワークを使用して、コードベース全体の豊富なコードインテリジェンスを実現できます。たとえば、Retrieval-Augmented Generation（RAG）アプリケーションを構築する場合、Knowledge Graphはコードベースを、AIエージェント用のライブで埋め込み可能なグラフデータベースに変えます。Knowledge Graphは、アーキテクチャの視覚化も作成します。これにより、システムの構造と依存関係に関する洞察に満ちた図が提供されます。

Knowledge Graphフレームワークは、1行のスクリプトでインストールできます。ローカルリポジトリを解析し、Model Context Protocol（MCP）を使用して接続し、プロジェクトをクエリします。Knowledge Graphは、ファイル、ディレクトリ、クラス、関数などのエンティティとその関係をキャプチャします。この追加されたコンテキストにより、高度なコード理解とAI機能が実現します。たとえば、これにより、GitLab Duoエージェントがローカルワークスペース全体の関係を理解し、複雑な質問に対してより迅速かつ正確な回答をすることが可能になります。

Knowledge Graphはコードをスキャンして、以下を識別します:

- 構造要素: アプリケーションのバックボーンを形成するファイル、ディレクトリ、クラス、関数、モジュール。
- コードの関係: 関数の呼び出し、継承階層、モジュールの依存関係のような複雑な接続。

Knowledge GraphにはCLIも搭載されています。Knowledge Graph CLI（`gkg`）およびフレームワークの詳細については、[Knowledge Graphプロジェクトのドキュメント](https://gitlab-org.gitlab.io/rust/knowledge-graph)を参照してください。

## フィードバック {#feedback}

この機能はベータステータスです。[イシュー160](https://gitlab.com/gitlab-org/rust/knowledge-graph/-/issues/160)でフィードバックをお寄せください。
