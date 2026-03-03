---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Agent Platformのコンテキスト認識
---

GitLab Duoが意思決定を行い、提案を行うのに役立つさまざまな情報が利用可能です。

情報は、以下の状況で利用可能です:

- 常時。
- お客様の場所に基づく（移動するとコンテキストが変化します）。
- 明示的に参照される場合。たとえば、URL、ID、またはパスで情報を記述する場合。

## GitLab Duo Chat（エージェント） {#gitlab-duo-chat-agentic}

{{< history >}}

- GitLab 18.6で現在のページタイトルとURLが[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209186)されました。

{{< /history >}}

以下のコンテキストはGitLab Duo Chat（エージェント）で利用できます。

### 常に利用可能 {#always-available}

- GitLabドキュメント。
- 一般的なプログラミング知識、ベストプラクティス、および言語固有の情報。
- Gitで追跡されているプロジェクト全体とすべてのファイル。
- Chatが関連するイシューまたはマージリクエストを検索するために使用するGitLabの[Search API](../../api/search.md)。
- GitLab UIでChatを使用する場合、現在のページタイトルとURL。

エージェント型Chatは、SDLCデータ、[ナレッジグラフ](../project/repository/knowledge_graph/_index.md) 、[MCP Clients](../gitlab_duo/model_context_protocol/mcp_clients.md) 、[カスタム手順](customize/_index.md)から必要なコンテキストを自動的に取得する。

### 場所に基づく {#based-on-location}

- IDEで開いているファイル。コンテキストに使用したくない場合は、これらのファイルを閉じることができます。
- GitLab UIでは、現在のページコンテキスト（たとえば、マージリクエストまたはイシューを表示している場合）。

### 明示的に参照される場合 {#when-referenced-explicitly}

GitLab Duo Chat（エージェント）は、自律的に取得して使用できます:

- ファイル（プロジェクトを検索するか、ファイルパスを指定する場合）
- エピック
- イシュー
- マージリクエスト
- CI/CDパイプラインとジョブログ。
- コミット
- 作業アイテム

Classic Chatとは異なり、エージェント型Chatは、正確なIDまたはURLを指定しなくても、これらのリソースを検索できます。たとえば、「認証に関するマージリクエストを見つける」と尋ねると、Chatは関連するマージリクエストを検索します。

### 拡張コンテキスト {#extended-context}

- [Model Context Protocol (MCP)](../gitlab_duo/model_context_protocol/_index.md)を使用して、Chatを外部データソースおよびツールに接続します。
- エージェント型Chat、エージェント、およびフローで[カスタムルール](customize/custom_rules.md)または[AGENTS.md](customize/agents_md.md)を使用して、プロジェクト固有のコンテキスト、コーディング標準、およびチームプラクティスを提供します。

## ソフトウェア開発フロー {#software-development-flow}

次のコンテキストは、GitLab Duo Agent Platformのソフトウェア開発フローで使用できます。

### 常に利用可能 {#always-available-1}

- 一般的なプログラミング知識、ベストプラクティス、および言語固有の情報。
- Gitで追跡されているプロジェクト全体とすべてのファイル。
- GitLabの[検索API](../../api/search.md)。これは、関連するイシューまたはマージリクエストを検索するために使用されます。

### 場所に基づく {#based-on-location-1}

- IDEで開いているファイル（コンテキストに使用したくない場合は、ファイルを閉じてください）。

### 明示的に参照される場合 {#when-referenced-explicitly-1}

- ファイル
- エピック
- イシュー
- マージリクエスト
- マージリクエストのパイプライン

## GitLab Duoからコンテキストを除外する {#exclude-context-from-gitlab-duo}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}} {{< history >}}

- GitLab 18.2で`use_duo_context_exclusion`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17124)されました。デフォルトでは無効になっています。
- GitLab 18.4でベータ版に変更されました。
- GitLab 18.5でデフォルトで有効になりました。

{{< /history >}}

GitLab Duoのコンテキストとして除外するプロジェクトコンテンツを制御できます。パスワードや設定ファイルなどの機密情報を保護するには、この機能を使用します。

コンテンツを除外すると、すべてのGitLab Duo Agent Platform機能は、この情報をコンテキストとして除外します。

### GitLab Duoコンテキスト除外を管理する {#manage-gitlab-duo-context-exclusions}

GitLab Duoが除外するコンテンツを指定するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**の**GitLab Duoコンテキスト除外**セクションで、**除外の管理**を選択します。
1. GitLab Duoコンテキストから除外するプロジェクトファイルとディレクトリを指定し、**除外を保存**を選択します。
1. オプション。既存の除外を削除するには、該当する除外の**削除**（{{< icon name="remove" >}}）を選択します。
1. **変更を保存**を選択します。
