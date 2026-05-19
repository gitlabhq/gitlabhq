---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: カスタムエージェントをAIカタログの外部データソースおよびサードパーティサービスにMCPサーバーを使用して接続します。
title: AIカタログ内のMCPサーバー
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/590708)（`ai_catalog_mcp_servers`という[フラグ付き](../../../administration/feature_flags/_index.md)）。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

AIカタログのカスタムエージェントは、[Model Context Protocol](https://modelcontextprotocol.io/)（MCP）を介して、外部データソースやサードパーティサービス（JiraやGoogle Driveなど）に接続できます。

これは[実験的機能](../../../policy/development_stages_support.md#experiment)です。[イシュー593219](https://gitlab.com/gitlab-org/gitlab/-/work_items/593219)でフィードバックを共有してください。

AIカタログのMCPサーバーで、次のことができます:

- 組織のカタログにMCPサーバーを追加できます（名前、URL、トランスポートタイプ）。
- MCPサーバーをカスタムエージェントに関連付けます。
- 各エージェントに接続されているMCPサーバーを表示します。
- OAuth対応のMCPサーバーで認証する。

AIカタログナビゲーションの**エージェント**と**フロー**の横に、専用の**MCP**タブが表示されます。ネームスペースで有効になっているエージェントに関連付けられたMCPサーバーは、グループレベルとプロジェクトレベルの両方で**自動化** > **MCPサーバー**でも利用できます。

## 前提条件 {#prerequisites}

- [GitLab Duo Agent Platform](../../duo_agent_platform/_index.md#prerequisites)の前提条件を満たしている必要があります。
- [GitLab Duoの実験機能とベータ機能を有効にしている](../turn_on_off.md#on-gitlabcom-2)トップレベルグループのメンバーであること。
- MCPサーバーを追加または編集するには、インスタンス管理者である必要があります。
- MCPサーバーは次のいずれかである必要があります:
  - 審査済みの、またはパートナーのMCPサーバー。不特定のURLは許可されません。
  - リモートMCPサーバー。

## AIカタログにMCPサーバーを追加する {#add-an-mcp-server-to-the-ai-catalog}

AIカタログにMCPサーバーを追加するには:

1. 左サイドバーで、**検索または移動先**を選択し、グループを見つけます。
1. **ビルド** > **AIカタログ**を選択します。
1. **MCP**タブを選択します。
1. **新しいMCPサーバー**を選択します。
1. フィールドに入力します:
   - **Name**: MCPサーバーの説明的な名前（例: `Jira`）。
   - **説明**: サーバーが提供する内容の簡単な説明。
   - **URL**: MCPサーバーのHTTPエンドポイント。
   - **ホームページのURL**: MCPサーバーのホームページまたはドキュメントのURL。
   - **トランスポート**: **HTTP**を選択します。HTTPトランスポートのみがサポートされています。SSEおよびstdioトランスポートは利用できません。
   - **認証タイプ**: 次のいずれかを選択します。
     - **なし**: 認証は不要です。
     - **OAuth**: OAuth 2.0で認証する。サーバーが[OAuth 2.0 Dynamic Client Registration](https://tools.ietf.org/html/rfc7591)をサポートしている場合、GitLabは最初の接続時に自動的にOAuthクライアントとして自身を登録します。
1. **MCPサーバーの作成**を選択します。

MCPサーバーは組織のカタログで利用可能になり、エージェントと関連付けることができます。

## MCPサーバーを編集する {#edit-an-mcp-server}

MCPサーバーを編集するには:

1. 左サイドバーで、**検索または移動先**を選択し、グループを見つけます。
1. **ビルド** > **AIカタログ**を選択します。
1. **MCP**タブを選択します。
1. 編集したいMCPサーバーを選択します。
1. **編集**を選択します。
1. 必要に応じてフィールドを更新します。
1. **変更を保存**を選択します。

## カスタムエージェントにMCPサーバーを接続する {#connect-an-mcp-server-to-a-custom-agent}

カスタムエージェントにMCPサーバーを接続するには:

1. 左サイドバーで、**検索または移動先**を選択し、グループを見つけます。
1. **ビルド** > **AIカタログ**を選択します。
1. **エージェント**タブを選択します。
1. 設定したいエージェントを選択し、**編集**を選択します。
1. **MCPサーバー**セクションで、このエージェントに関連付けるMCPサーバーを選択します。
1. **変更を保存**を選択します。

これで、エージェントは実行中に、関連するMCPサーバーが提供するすべてのツールを使用できます。

エージェントが特定のMCPサーバーツールを使用することを制限することはできません。

## カスタムエージェントに接続されているMCPサーバーを表示する {#view-mcp-servers-connected-to-a-custom-agent}

カスタムエージェントに接続されているMCPサーバーを表示するには:

1. 左サイドバーで、**検索または移動先**を選択し、グループを見つけます。
1. **ビルド** > **AIカタログ**を選択します。
1. **エージェント**タブを選択します。
1. エージェントを選択します。

エージェントの詳細ページには、接続されているすべてのMCPサーバーが一覧表示されます。

## MCPサーバーをカスタムエージェントから切断する {#disconnect-an-mcp-server-from-custom-agents}

{{< history >}}

- GitLab 18.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227157)されました。

{{< /history >}}

接続されているすべてのカスタムエージェントからMCPサーバーを切断できます。特定のエージェントからMCPサーバーを切断することはできません。

切断後も、既存のカスタムエージェントのチャットは、MCPサーバーからすでに取得されたコンテンツを参照できます。しかし、エージェントは新しいコンテンツをフェッチすることや、アクションを実行することはできなくなります。

1. 左サイドバーで、**検索または移動先**を選択し、グループを見つけます。
1. **ビルド** > **AIカタログ**を選択します。
1. **MCP**タブを選択します。
1. 切断したいMCPサーバーで、**切断**を選択します。
1. 確認ダイアログで、**切断**を選択します。

## ネームスペースのMCPサーバーを表示する {#view-mcp-servers-for-a-namespace}

**自動化** > **MCPサーバー**ページには、ネームスペースで有効になっているエージェントに関連付けられているすべてのMCPサーバーが表示されます。各サーバーには、それを使用するエージェントの数が表示され、エージェント名はホバー時にツールチップで表示されます。

このページは、グループレベルとプロジェクトレベルの両方で利用できます:

- **Group level**では、グループ全体でエージェントに関連付けられているMCPサーバーが表示されます。
- **Project level**では、プロジェクトで設定されたエージェントに関連付けられているMCPサーバーが表示されます。

グループレベルまたはプロジェクトレベルでMCPサーバーを表示するには:

1. 左サイドバーで**検索または移動先**を選択し、グループまたはプロジェクトを検索します。
1. **自動化** > **MCPサーバー**を選択します。

まだ認証していないOAuth対応サーバーの場合は、**接続**オプションが表示されます。

## MCPサーバーで認証する {#authenticate-with-an-mcp-server}

OAuth対応のMCPサーバーで認証するには:

1. 左サイドバーで**検索または移動先**を選択し、グループまたはプロジェクトを検索します。
1. **自動化** > **MCPサーバー**を選択します。
1. MCPサーバーを見つけて**接続**を選択します。
1. MCPサーバーの認可ページで認可リクエストを確認して承認します。
1. GitLabは将来のリクエストのためにアクセストークンを安全に保存します。

サーバーが[OAuth 2.0 Dynamic Client Registration](https://tools.ietf.org/html/rfc7591)をサポートしている場合、GitLabは最初の接続時に自動的にOAuthクライアントとして自身を登録します。OAuthの認証情報を手動で提供する必要はありません。

## 利用可能なMCPサーバー {#available-mcp-servers}

次のMCPサーバーをAIカタログに追加できます。カタログに提案されているその他のサーバーについては、[イシュー591969](https://gitlab.com/gitlab-org/gitlab/-/work_items/591969)を参照してください。

### Linear {#linear}

Linear MCPサーバーを使用すると、AIエージェントとワークフローが、イシュー、プロジェクト、コメントの検索、作成、更新など、Linearデータとリアルタイムでやり取りできます。

| プロパティ | 値 |
|---|---|
| URL | `https://mcp.linear.app/mcp` |
| トランスポート | HTTP |
| 認証 | OAuth |

### Atlassian {#atlassian}

Atlassian MCPサーバーを使用すると、AIエージェントとワークフローが、JiraおよびConfluenceデータとリアルタイムでやり取りでき、イシュー、ページ、プロジェクトコンテンツの検索、作成、更新などが含まれます。

| プロパティ | 値 |
|---|---|
| URL | `https://mcp.atlassian.com/v1/mcp` |
| トランスポート | HTTP |
| 認証 | OAuth |

接続する前に、Atlassianインスタンスを構成して、GitLabを認証済みドメインとして信頼するようにします:

1. Atlassianで、管理者ページに移動します。
1. **Apps** > **AI Settings** > **Rovo MCP Server**を選択します。
1. `https://gitlab.com/**`を信頼できるドメインのリストに追加します。

### Context7 {#context7}

Context7 MCPは、最新のバージョン固有のドキュメントとコードの例をソースからプルし、プロンプトに追加します。

| プロパティ | 値 |
|---|---|
| URL | `https://mcp.context7.com/mcp` |
| トランスポート | HTTP |
| 認証 | なし |

## 関連トピック {#related-topics}

- [GitLab MCPサーバー](mcp_server.md)
