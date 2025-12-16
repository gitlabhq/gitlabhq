---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chat（エージェント）
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- VS Codeは、[実験的機能](../../policy/development_stages_support.md)として`duo_agentic_chat`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.1の[GitLab.comで導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/540917)されました。デフォルトでは無効になっています。
- VS Codeは、GitLab 18.2の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196688)になりました。
- GitLab UIは、`duo_workflow_workhorse`および`duo_workflow_web_chat_mutation_tools`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.2の[GitLab.comとGitLab Self-Managedで導入](https://gitlab.com/gitlab-org/gitlab/-/issues/546140)されました。どちらのフラグもデフォルトで有効になっています。
- 機能フラグ`duo_agentic_chat`は、GitLab 18.2でデフォルトで有効になっています。
- JetBrains IDEがGitLab 18.2で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/1077)されました。
- GitLab 18.2でベータ版に変更されました。
- Visual Studio for WindowsがGitLab 18.3で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/245)されました。
- GitLab 18.3でGitLab Duo Coreに[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)されました。
- 機能フラグ`duo_workflow_workhorse`および`duo_workflow_web_chat_mutation_tools`は、GitLab 18.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198487)されました。
- [セルフホストモデル対応のGitLab Duo向けに](../../administration/gitlab_duo_self_hosted/_index.md)、[実験的機能](../../policy/development_stages_support.md#experiment)として`self_hosted_agent_platform`[機能フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 18.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/19213)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab Duo Chat（エージェント）は、GitLab Duo Chat（クラシック）の拡張バージョンです。この新しいChatは、複雑な質問に対しより包括的に回答できるよう、ユーザーに代わって自律的にアクションを実行できます。

クラシックモードのChatが単一のコンテキストに基づいて質問に回答するのに対し、エージェントモードのChatは、GitLabプロジェクト全体の複数のソースから情報を検索、取得、統合することで、より徹底的で関連性の高い回答を提供します。エージェントモードのChatでは、ファイルの作成や編集も可能です。

「エージェントモード」とは、Chatが以下を行うことを意味します:

- 大規模言語モデルを使用して必要な情報を自律的に判断します。
- 一連の操作を実行して、その情報を収集します。
- 質問への回答を作成します。
- ローカルファイルを作成および変更できます。

コードベースの理解や実装計画の作成など、より大きな問題については、[Duo Agent Platformのソフトウェア開発フロー](../duo_agent_platform/_index.md)を使用してください。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[GitLab Duo Chat（エージェント）](https://youtu.be/uG9-QLAJrrg?si=c25SR7DoRAep7jvQ)を参照してください。
<!-- Video published on 2025-06-02 -->

## GitLab Duo Chatを使用する {#use-gitlab-duo-chat}

GitLab Duo Chatは、以下で使用できます:

- GitLab UI。
- VS Code。
- JetBrains IDE。
- Visual Studio for Windows。

### GitLab UIでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-the-gitlab-ui}

{{< history >}}

- Chatが最新の会話を記憶する機能は、GitLab 18.4で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203653)されました。

{{< /history >}}

前提要件: 

- [前提条件](../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

GitLab UIでChatを使用するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 右上隅で、**GitLab Duo Chatを開く**（{{< icon name="duo-chat" >}}）を選択します。画面の右側にドロワーが開きます。
1. チャットテキストボックスの下で、**Agentic mode (Beta)**の切り替えをオンにします。
1. チャットテキストボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。回答を得るまでに数秒かかる場合があります。
1. オプション。フォローアップの質問をします。

Webページをリロードしたり別のWebページに移動したりしても、Chatは最新の会話を記憶し、その会話はChatドロワーでアクティブなままです。

### VS CodeでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-vs-code}

前提要件: 

- バージョン6.15.1以降の[VS Code用GitLab Workflow拡張機能をインストールして設定](../../editor_extensions/visual_studio_code/setup.md)します。
- [その他の前提条件](../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

GitLab Duo Chatをオンにする:
<!-- markdownlint-disable MD044 -->
1. VS Codeで、**Settings** > **Settings**に移動します。
1. `agent platform`を検索します。
1. **Gitlab › Duo Agent Platform: Enabled**で、**Enable GitLab Duo Agent Platform**チェックボックスを選択します。
<!-- markdownlint-enable MD044 -->

その後、GitLab Duo Chatを使用するには:

1. 左側のサイドバーで、**GitLab Duo Agent Platform (Beta)**（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. **Chat**タブを選択します。
1. プロンプトが表示されたら、**Refresh page**を選択します。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

### JetBrains IDEでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-jetbrains-ides}

前提要件: 

- バージョン3.11.1以降の[JetBrains用GitLabプラグインをインストールして設定](../../editor_extensions/jetbrains_ide/setup.md)します。
- [その他の前提条件](../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

GitLab Duo Chatをオンにする:

1. JetBrains IDEで、**Settings** > **Tools** > **GitLab Duo**に移動します。
1. **GitLab Duo Agent Platform (Beta)**で、**Enable GitLab Duo Agent Platform**チェックボックスを選択します。
1. プロンプトが表示されたら、IDEを再起動します。

その後、GitLab Duo Chatを使用するには:

1. 左側のサイドバーで、**GitLab Duo Agent Platform (Beta)**（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. **Chat**タブを選択します。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

### Visual StudioでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-visual-studio}

前提要件: 

- バージョン0.60.0以降の[Visual Studio用GitLab拡張機能をインストールして設定](../../editor_extensions/visual_studio/setup.md)します。
- [その他の前提条件](../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

GitLab Duo Chatをオンにする:

1. Visual Studioで、**Tools** > **Options** > **GitLab**に移動します。
1. **GitLab**で、**General**を選択します。
1. **Enable Agentic Duo Chat (experimental)**で**True**を選択し、**OK**を選択します。

その後、GitLab Duo Chatを使用するには:

1. **Extensions** > **GitLab** > **Open Agentic Chat**を選択します。
1. メッセージボックスに質問を入力し、**Enter**キーを押します。

### チャット履歴を表示する {#view-the-chat-history}

{{< history >}}

- Chat履歴がGitLab 18.2のIDEに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17922)されました。
- GitLab UIにGitLab 18.3で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/556875)されました。

{{< /history >}}

チャット履歴を表示するには:

- GitLab UIの場合: Chatドロワーの右上隅で、**Chat履歴**（{{< icon name="history" >}}）を選択します。
- IDEの場合: メッセージボックスの右上隅で、**Chat history**（{{< icon name="history" >}}）を選択します。

GitLab UIでは、チャット履歴内のすべての会話が表示されます。

IDEでは、最新の20件の会話が表示されます。[イシュー1308](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1308)では、この仕様の変更が提案されています。

### 複数の会話を行う {#have-multiple-conversations}

{{< history >}}

- 複数の会話機能がGitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/556875)されました。

{{< /history >}}

GitLab Duo Chatと無制限の数の同時会話を行うことができます。

会話は、GitLab UIのGitLab Duo ChatとIDE間で同期されます。

1. GitLab UIまたはIDEでGitLab Duo Chatを開きます。
1. 質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. 新しい会話を作成します:

   - GitLab UIの場合: ドロワーの右上隅で、**あたらしいチャット**（{{< icon name="duo-chat-new" >}}）を選択します。
   - IDEの場合: メッセージボックスの右上隅で、**New chat**（{{< icon name="plus" >}}）を選択します。

1. 質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. すべての会話を表示するには、[チャット履歴](#view-the-chat-history)を確認します。
1. 会話を切り替えるには、チャット履歴で適切な会話を選択します。
1. IDEのみ: チャット履歴内の特定の会話を検索するには、**Search chats**テキストボックスに検索語句を入力します。

LLMコンテキストウィンドウの制限により、会話はそれぞれ200,000トークン（約800,000文字）に切り詰められます。

### 会話を削除する {#delete-a-conversation}

{{< history >}}

- 会話を削除する機能がGitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/545289)されました。

{{< /history >}}

1. GitLab UIまたはIDEで、[チャット履歴](#view-the-chat-history)を選択します。
1. 履歴で、**Delete this chat**（{{< icon name="remove" >}}）を選択します。

個々の会話は、30日間の非アクティブ状態後に有効期限が切れ、自動的に削除されます。

### カスタムルールを作成する {#create-custom-rules}

{{< history >}}

- カスタムルールがGitLab 18.2で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/550743)されました。

{{< /history >}}

IDEで、すべての会話でGitLab Duo Chatに従わせたい特定の指示がある場合は、カスタムルールを作成できます。

前提要件: 

- VS Codeの場合は、バージョン6.32.2以降の[VS Code用GitLab Workflow拡張機能をインストールして設定](../../editor_extensions/visual_studio_code/setup.md)します。
- JetBrains IDEの場合は、バージョン3.12.2以降の[JetBrains用GitLabプラグインをインストールして設定](../../editor_extensions/jetbrains_ide/setup.md)します。
- Visual Studioの場合は、バージョン0.60.0以降の[Visual Studio用GitLab拡張機能をインストールして設定](../../editor_extensions/visual_studio/setup.md)します。

{{< alert type="note" >}}

カスタムルールを作成する前に存在していた会話は、これらのルールに従いません。

{{< /alert >}}

1. IDEワークスペースで、カスタムルールファイルを作成します: `.gitlab/duo/chat-rules.md`。
1. カスタムルールをファイルに入力します。例: 

   ```markdown
   - don't put comments in the generated code
   - be brief in your explanations
   - always use single quotes for JavaScript strings
   ```

1. ファイルを保存します。
1. GitLab Duo Chatに新しいカスタムルールに従わせるには、新しい会話を開始します。

   カスタムルールを変更するたびに、これを行う必要があります。

詳細については、[Custom rules in GitLab Duo Agentic Chatのブログ](https://about.gitlab.com/blog/custom-rules-duo-agentic-chat-deep-dive/)を参照してください。

### モデルを選択する {#select-a-model}

{{< details >}}

- 提供形態: GitLab.com
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- `ai_user_model_switching`[フラグ](../../administration/feature_flags/_index.md)とともに[ベータ版](../../policy/development_stages_support.md#beta)機能として、GitLab 18.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/19251)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab UIでChatを使用する場合、会話に使用するモデルを選択できます。チャット履歴から以前のチャットを開いて会話を続ける場合、Chatは現在選択されているモデルを使用します。

IDEでのモデル選択はサポートされていません。

前提要件: 

- トップレベルグループのオーナーによってGitLab Duo Agent Platform機能のモデルが選択されていないこと。グループに対してモデルが選択されている場合、Chatのモデルを変更することはできません。

モデルを選択するには:

1. チャットテキストボックスの下で、**Agentic mode (Beta)**の切り替えをオンにします。
1. ドロップダウンリストからモデルを選択します。

### エージェントを選択する {#select-an-agent}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab UI向けに[実験的機能](../../policy/development_stages_support.md#experiment)としてGitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/562708)されました。

{{< /history >}}

GitLab UIのプロジェクトでChatを使用する場合、Chatが使用する特定のエージェントを選択できます。

前提要件: 

- AIカタログから[プロジェクトにエージェントを追加](../duo_agent_platform/agents/_index.md#add-an-agent-to-a-project)する必要があります。

エージェントを選択するには:

1. GitLab UIで、GitLab Duo Chatを開きます。
1. ドロワーの右上隅で、**新しいチャット**を選択します。
1. ドロップダウンリストで、カスタムエージェントを選択します。カスタムエージェントを設定していない場合、ドロップダウンリストはなく、ChatはデフォルトのGitLab Duoエージェントを使用します。
1. 質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

カスタムエージェントとの会話を作成した後:

- 会話は、選択したカスタムエージェントを記憶します。
- チャット履歴を使用して同じ会話に戻ると、同じエージェントが使用されます。

## GitLab Duo Chatの機能 {#gitlab-duo-chat-capabilities}

GitLab Duo Chat（エージェント）は、GitLab Duo Chat（クラシック）を拡張し、以下の機能を追加しています:

- **プロジェクト検索**: キーワードベースの検索を使用して、プロジェクト内の関連するイシュー、マージリクエスト、その他のアーティファクトを検索できます。Agentic Chatには、セマンティック検索機能はありません。
- **ファイルアクセス**: ファイルパスを手動で指定しなくても、ローカルプロジェクト内のファイルを読み取って一覧表示できます。
- **ファイルを作成および編集**: 複数の場所で、複数のファイルを作成および編集できます。これはローカルファイルに影響します。
- **リソース取得**: 現在のプロジェクトのイシュー、マージリクエスト、パイプラインログに関する詳細情報を自動的に取得することができます。
- **マルチソース分析**: 複数のソースからの情報を統合して、複雑な質問に対するより完全な回答を提供できます。[Model Context Protocol](../gitlab_duo/model_context_protocol/_index.md)を使用して、GitLab Duo Chat（エージェント）を外部データソースおよびツールに接続できます。
- **カスタムルール**: 指定したカスタマイズされたルールに会話を従わせることができます。
- GitLab UIのGitLab Duo Chat（エージェント）のみ - **コミットの作成**: コミットを作成してプッシュできます。

### Chat機能の比較 {#chat-feature-comparison}

| 機能                                              | GitLab Duo Chat（クラシック） |                                                         GitLab Duo Chat（エージェント）                                                                                                          |
| ------------                                            |------|                                                         -------------                                                                                                          |
| 一般的なプログラミングの質問をする |                       はい  |                                                          はい                                                                                                                   |
| エディタで開いているファイルに関する回答を得る |     はい  |                                                          はい。ただし、質問内でファイルのパスを指定する必要があります。                                                                   |
| 指定されたファイルに関するコンテキストを提供する |                   はい。`/include`を使用して会話にファイルを追加します。 |        はい。ただし、質問内でファイルのパスを指定する必要があります。                                                                   |
| プロジェクトコンテンツを自律的に検索する |                    いいえ |                                                            はい                                                                                                                   |
| ファイルを自律的に作成および変更する |              いいえ |                                                            はい。ファイルを変更するように依頼する必要があります。ただし、手動で行ったまだコミットしていない変更は上書きされる可能性があります。  |
| IDを指定せずにイシューとMRを取得する |          いいえ |                                                            はい。他の条件で検索します。たとえば、MR、イシューのタイトル、担当者などです。                                       |
| 複数のソースからの情報を統合する |               いいえ |                                                            はい                                                                                                                   |
| パイプラインログを分析する |                                   はい。Duo Enterpriseアドオンが必要です。 |                          はい                                                                                                                   |
| 会話を再開する |                                  はい。`/new`または`/reset`を使用します。 |                             はい。`/new`を使用するか、UIの場合は`/reset`を使用します。                                                                                       |
| 会話を削除する |                                   はい、チャット履歴から削除できます。|                                             はい、チャット履歴から削除できます。                                                                                                            |
| イシューとMRを作成する |                                   いいえ |                                                            はい                                                                                                                   |
| Git読み取り専用コマンドを使用する |                                                 いいえ |                                                            はい                                                  |
| Git書き込みコマンドを使用する |                                                 いいえ |                                                            はい、UIのみ                                                  |
| Shellコマンドを実行する |                                      いいえ |                                                            はい、IDEのみ                                                                                                        |
| MCPツールを実行する |                                      いいえ |                                                            はい、IDEのみ                                                                                                          |

## ユースケース {#use-cases}

GitLab Duo Chatが特に役立つのは、次のような場合です:

- 複数のファイルまたはGitLabリソースからの情報を必要とする回答が必要な場合。
- 正確なファイルパスを指定せずに、コードベースに関する質問をしたい場合。
- プロジェクト全体のイシューまたはマージリクエストのステータスを把握しようとしている場合。
- ファイルを作成または編集してもらいたい場合。

### プロンプトの例 {#example-prompts}

GitLab Duo Chatは、自然言語の質問でよく機能します。次に例を示します:

- `Read the project structure and explain it to me`、または`Explain the project`。
- `Find the API endpoints that handle user authentication in this codebase`。
- `Please explain the authorization flow for <application name>`。
- `How do I add a GraphQL mutation in this repository?`
- `Show me how error handling is implemented across our application`。
- `Component <component name> has methods for <x> and <y>. Could you split it up into two components?`
- `Could you add in-line documentation for all Java files in <directory>?`
- `Do merge request <MR URL> and merge request <MR URL> fully address this issue <issue URL>?`

## トラブルシューティング {#troubleshooting}

GitLab Duo Chatを使用する場合、次の問題が発生する可能性があります。

### 接続または表示に関する問題 {#trouble-connecting-or-viewing}

正しく接続され、Chatを表示できることを確認するには、[トラブルシューティング](../duo_agent_platform/troubleshooting.md)を参照してください。

### 応答時間が遅い {#slow-response-times}

Chatには、リクエストの処理時に大きなレイテンシーが発生します。

この問題は、Chatが情報を収集するために複数のAPIコールを行うために発生します。そのため、応答時間がクラシックモードのChatと比較して大幅に長くなることがよくあります。

### 権限の制限 {#limited-permissions}

Chatは、GitLab ユーザーがアクセス権限を持っているリソースと同じリソースにアクセスできます。

### 検索の制限 {#search-limitations}

Chatは、セマンティック検索ではなく、キーワードベースの検索を使用します。つまり、検索で使用される正確なキーワードを含まない関連コンテンツをChatが見逃す可能性があります。

## フィードバック {#feedback}

これはベータ機能です。皆様からのフィードバックが改善に役立ちます。[イシュー542198](https://gitlab.com/gitlab-org/gitlab/-/issues/542198)で、ご意見、ご提案、または問題を共有してください。

## 関連トピック {#related-topics}

- [ブログ: GitLab Duo Chat gets agentic AI makeover](https://about.gitlab.com/blog/2025/05/29/gitlab-duo-chat-gets-agentic-ai-makeover/)
