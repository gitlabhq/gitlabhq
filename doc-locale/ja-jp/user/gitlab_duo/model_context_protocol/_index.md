---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Model Context Protocolとその使用方法について説明します。
title: Model Context Protocol
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Model Context Protocol（MCP）は、AIアシスタントを既存のツールやデータソースに接続するオープンスタンダードです。MCPは、ユニバーサルアダプターとして機能します。ソフトウェアプラットフォームごとに個別のカスタム接続を作成する代わりに、システム通信に単一の標準化されたプロトコルを使用できます。

たとえば、AIアシスタントは、CRMから顧客データをプルし、GitLabのプロジェクトステータスを確認し、同じプロトコルを介してWikiのドキュメントを参照できます。このアプローチにより、デベロッパーの設定が軽減され、必要なコンテキストにアクセスできる、より強力なAIアシスタントが作成されます。

GitLabは、MCPを2つの方法でサポートしています:

- [MCPクライアント](mcp_clients.md): GitLab Duo Chat（エージェント型）のようなGitLab Duo機能を外部MCPサーバーに接続して、他のシステムからのデータやツールにアクセスし、より包括的な支援を提供します。

- [MCPサーバー](mcp_server.md): 外部AIツールをGitLabインスタンスに接続します。接続されたツールは、プロジェクト、イシュー、マージリクエスト、その他のGitLabデータに安全にアクセスできます。
