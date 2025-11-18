---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duoチャット（エージェント型）
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- LLM: Anthropic [Claude Sonnet 4](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- [GitLab Duoセルフホストモデル](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- VS CodeがGitLab 18.1で[GitLab.comで導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/540917)された[実験](../../policy/development_stages_support.md)として、`duo_agentic_chat`という名前の[FF](../../administration/feature_flags/_index.md)があります。デフォルトでは無効になっています。
- [GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196688)でVS Codeが有効になったのはGitLab 18.2です。
- GitLab UIがGitLab 18.2で[GitLab.comとGitLab Self-Managedで導入](https://gitlab.com/gitlab-org/gitlab/-/issues/546140)され、`duo_workflow_workhorse`と`duo_workflow_web_chat_mutation_tools`という名前の[FF](../../administration/feature_flags/_index.md)があります。どちらの機能フラグもデフォルトで有効になっています。
- 機能フラグ`duo_agentic_chat`は、GitLab 18.2でデフォルトで有効になっています。
- JetBrains IDEがGitLab 18.2で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/1077)されました。
- GitLab 18.2でベータ版に変更されました。
- Visual Studio for WindowsがGitLab 18.3で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/issues/245)されました。
- GitLab 18.3でGitLab Duo Coreに[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)されました。
- 機能フラグ`duo_workflow_workhorse`と`duo_workflow_web_chat_mutation_tools`は、GitLab 18.4で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198487)されました。
- [セルフホストモデル](../../administration/gitlab_duo_self_hosted/_index.md)のGitLab Duoの場合、GitLab 18.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/19213)された[実験](../../policy/development_stages_support.md#experiment)として、`self_hosted_agent_platform`という名前の[機能フラグ](../../administration/feature_flags/_index.md)があります。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab Duoチャット（エージェント型）は、GitLab Duoチャット（クラシック）の拡張バージョンです。この新しいチャットは、複雑な質問に対しより包括的に回答できるよう、お客様に代わって自律的にアクションを実行できます。

従来のチャットが単一のコンテキストに基づいて質問に回答するのに対し、エージェント型のチャットは、GitLabプロジェクト全体の複数のソースから情報を検索、取得する、組み合わせることで、より徹底的で関連性の高い回答を提供します。エージェント型のチャットでは、ファイルの作成や編集も可能です。

「エージェント型」とは、チャットが以下のことを意味します。:

- 大規模言語モデルを自律的に使用して、必要な情報を判断します。
- 一連の操作を実行して、その情報を収集します。
- 質問への回答を作成します。
- ローカルファイルを作成および変更できます。

より大きな問題、たとえばコードベースの理解や実装計画の作成には、[Duo Agent Platformのソフトウェア開発フロー](../duo_agent_platform/_index.md)を使用してください。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[GitLab Duoチャット（エージェント型）](https://youtu.be/uG9-QLAJrrg?si=c25SR7DoRAep7jvQ)を参照してください。
<!-- Video published on 2025-06-02 -->

## GitLab Duoチャットを使用する {#use-gitlab-duo-chat}

GitLab Duo Chatは、以下で使用できます: 

- GitLab UI。
- VS Code。
- JetBrains IDE。
- Visual Studio for Windows。

### GitLab UIでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-the-gitlab-ui}

{{< history >}}

- チャットが最新の会話を記憶する機能が、GitLab 18.4で[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203653)されました。

{{< /history >}}

前提要件: 

- [前提条件](../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

GitLab UIでチャットを使用するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 右上隅で、**GitLab Duo Chatを開く**（{{< icon name="duo-chat" >}}）を選択します。ドロワーが画面の右側に開きます。画面の右側にドロワーが開きます。
1. チャットテキストボックスの下で、**エージェントモード(ベータ版)**切替をオンにします。
1. チャットテキストボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。回答を得るまでに数秒かかる場合があります。
1. オプション。フォローアップの質問をします。

アクセスしているウェブページをリロードするか、別のウェブページに移動すると、チャットが最新の会話を記憶し、その会話はチャットドロワーで引き続きアクティブになります。

### VS CodeでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-vs-code}

前提要件: 

- [VS Code用GitLab Workflow拡張機能](../../editor_extensions/visual_studio_code/setup.md)バージョン6.15.1以降をインストールして設定します。
- [その他の前提条件](../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

GitLab Duoチャットをオンにする:
<!-- markdownlint-disable MD044 -->
1. VS Codeで、**設定** > **設定**に移動します。
1. `agent platform`を検索します。
1. **Gitlab › Duo Agent Platformの下: 有効にすると**、**Enable GitLab Duo Agent Platform**（GitLab Duo Agent Platformを有効にする）チェックボックスを選択します。
<!-- markdownlint-enable MD044 -->

次に、GitLab Duoチャットを使用するには:

1. 左側のサイドバーで、**GitLab Duo Agent Platform (Beta)**（GitLab Duo Agent Platform（ベータ版））（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. **チャット**タブを選択します。
1. プロンプトが表示されたら、**Refresh page**（ページを更新）を選択します。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

### JetBrains IDEでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-jetbrains-ides}

前提要件: 

- [JetBrains用GitLabプラグインをインストールして設定する](../../editor_extensions/jetbrains_ide/setup.md)バージョン3.11.1以降。
- [その他の前提条件](../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

GitLab Duoチャットをオンにする:

1. JetBrains IDEで、**設定** > **ツール** > **GitLab Duo**に移動します。
1. **GitLab Duo Agent Platform (Beta)**（GitLab Duo Agent Platform（ベータ版））で、**Enable GitLab Duo Agent Platform**（GitLab Duo Agent Platformを有効にする）チェックボックスを選択します。
1. プロンプトが表示されたら、IDEを再起動します。

次に、GitLab Duoチャットを使用するには:

1. 左側のサイドバーで、**GitLab Duo Agent Platform (Beta)**（GitLab Duo Agent Platform（ベータ版））（{{< icon name="duo-agentic-chat" >}}）を選択します。
1. **チャット**タブを選択します。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

### Visual Studio for WindowsでGitLab Duoチャットを使用する {#use-gitlab-duo-chat-in-visual-studio}

前提要件: 

- [Visual Studio用GitLab拡張機能をインストールして設定する](../../editor_extensions/visual_studio/setup.md)バージョン0.60.0以降。
- [その他の前提条件](../duo_agent_platform/_index.md#prerequisites)を満たしていることを確認してください。

GitLab Duoチャットをオンにする:

1. Visual Studioで、**ツール** > **オプション** > **GitLab**に移動します。
1. **GitLab**で、**一般**を選択します。
1. **Enable Agentic Duo Chat (experimental)**（Agentic Duoチャット（試験的）を有効にする）には、**true**を選択し、次に**OK**を選択します。

次に、GitLab Duoチャットを使用するには:

1. **Extensions**（拡張機能） > **GitLab** > **Open Agentic Chat**（Agenticチャットを開く）を選択します。
1. メッセージボックスに質問を入力し、Enterキーを押すか、**Enter**を選択します。

### チャットの履歴を表示する {#view-the-chat-history}

{{< history >}}

- チャットの履歴がGitLab 18.2のIDEに[導入](https://gitlab.com/groups/gitlab-org/-/epics/17922)されました。
- GitLab UI用にGitLab 18.3で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/556875)。

{{< /history >}}

チャットの履歴を表示するには:

- GitLab UIの場合: Chatドロワーの右上隅で、**Chat history**（Chat履歴）（{{< icon name="history" >}}）を選択します。
- IDEで: メッセージボックスの右上隅で、**Chat history**（チャット履歴）（{{< icon name="history" >}}）を選択します。

GitLab UIでは、チャット履歴内のすべての会話が表示されます。

IDEでは、最後の20件の会話が表示されます。[issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1308) 1308では、この変更が提案されています。

### 複数の会話をする {#have-multiple-conversations}

{{< history >}}

- 複数の会話がGitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/556875)されました。

{{< /history >}}

GitLab Duoチャットでは、同時に無制限の数の会話が可能です。

会話は、GitLab UIおよびIDEのGitLab Duoチャット全体で同期されます。

1. GitLab UIまたはIDEでGitLab Duoチャットを開きます。
1. 質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. 新しい会話を作成します:

   - GitLab UIの場合: ドロワーの右上隅で、**New chat**（新規chat）（{{< icon name="duo-chat-new" >}}）を選択します。
   - IDEで: メッセージボックスの右上隅で、**New chat**（新しいチャット）（{{< icon name="plus" >}}）を選択します。

1. 質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. すべての会話を表示するには、[チャット履歴](#view-the-chat-history)をご覧ください。
1. 会話を切り替えるには、チャットの履歴で適切な会話を選択します。
1. IDEのみ: チャット履歴内の特定の会話を検索するには、**Search chats**（チャットを検索）テキストボックスに検索語句を入力します。

LLMコンテキストウィンドウの制限により、会話はそれぞれ200,000トークン（約800,000文字）に切り詰められます。

### 会話を削除する {#delete-a-conversation}

{{< history >}}

- 会話を削除する機能がGitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/545289)されました。

{{< /history >}}

1. GitLab UIまたはIDEで、[チャット履歴](#view-the-chat-history)を選択します。
1. 履歴で、**Delete this chat**（このチャットを削除）（{{< icon name="remove" >}}）を選択します。

個々の会話は期限切れとなり、30日間操作がないと自動的に削除されます。

### カスタムルールを作成 {#create-custom-rules}

{{< history >}}

- カスタムルールがGitLab 18.2で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/550743)されました。

{{< /history >}}

IDEで、すべての会話でGitLab Duoチャットに従わせたい特定の指示がある場合は、カスタムルールを作成できます。

前提要件: 

- VS Codeの場合は、[VS Code用GitLab Workflow拡張機能](../../editor_extensions/visual_studio_code/setup.md)バージョン6.32.2以降をインストールして設定します。
- JetBrains IDEの場合は、[JetBrains用GitLabプラグインをインストールして設定する](../../editor_extensions/jetbrains_ide/setup.md)バージョン3.12.2以降。
- Visual Studioの場合は、[Visual Studio用GitLab拡張機能をインストールして設定する](../../editor_extensions/visual_studio/setup.md)バージョン0.60.0以降。

{{< alert type="note" >}}

カスタムルールを作成する前に存在していた会話は、これらのルールに従いません。

{{< /alert >}}

1. IDEワークスペースで、カスタムルールファイル`.gitlab/duo/chat-rules.md`を作成します。
1. カスタムルールをファイルに入力します。次に例を示します: 

   ```markdown
   - don't put comments in the generated code
   - be brief in your explanations
   - always use single quotes for JavaScript strings
   ```

1. ファイルを保存します。
1. GitLab Duoチャットに新しいカスタムルールに従わせるには、新しい会話を開始します。

   カスタムルールを変更するたびに、これを行う必要があります。

詳細については、[GitLab Duoエージェント型チャットブログのカスタムルール](https://about.gitlab.com/blog/custom-rules-duo-agentic-chat-deep-dive/)を参照してください。

### モデルを選択 {#select-a-model}

{{< details >}}

- 提供形態: GitLab.com
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- `ai_user_model_switching`という名前の[FF](../../administration/feature_flags/_index.md)で[ベータ](../../policy/development_stages_support.md#beta)機能としてGitLab 18.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/19251)。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab UIでチャットを使用する場合、会話に使用するモデルを選択できます。チャット履歴から以前のチャットを開き、会話を続行すると、チャットは現在選択されているモデルを使用します。

IDEでのモデル選択はサポートされていません。

前提要件: 

- トップレベルグループのオーナーが、GitLab Duo Agent Platform機能用に選択したモデルはありません。グループ用にモデルが選択されている場合、チャットのモデルを変更することはできません。

モデルを選択するには:

1. チャットテキストボックスの下で、**エージェントモード(ベータ版)**切替をオンにします。
1. ドロップダウンリストからモデルを選択します。

### エージェントを選択 {#select-an-agent}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/562708)されましたGitLab UIのGitLab 18.4用、[実験](../../policy/development_stages_support.md#experiment)として。

{{< /history >}}

GitLab UIのプロジェクトでチャットを使用する場合、使用する特定のエージェントをチャットに選択できます。

前提要件: 

- AIカタログから[プロジェクトにエージェントを追加](../duo_agent_platform/agents/_index.md#add-an-agent-to-a-project)する必要があります。

エージェントを選択するには:

1. GitLab UIで、GitLab Duoチャットを開きます。
1. ドロワーの右上隅で、**New chat**（新しいチャット）（）を選択します。
1. ドロップダウンリストで、カスタムエージェントを選択します。カスタムエージェントを設定していない場合、ドロップダウンリストはなく、チャットはデフォルトのGitLab Duoエージェントを使用します。
1. 質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

カスタムエージェントとの会話を作成した後:

- 会話は、選択したカスタムエージェントを記憶します。
- チャット履歴を使用して同じ会話に戻る場合、同じエージェントを使用します。

## GitLab Duoチャットの機能 {#gitlab-duo-chat-capabilities}

GitLab Duoチャット（エージェント型）は、次の機能でGitLab Duoチャット（クラシック）の機能を拡張します。:

- **Project search**（プロジェクト検索）: プロジェクトを検索して、キーワードに基づく検索を使用して、関連するイシュー、マージリクエスト、その他のアーティファクトを見つけることができます。エージェント型のチャットには、セマンティック検索機能はありません。
- **File access**（ファイルアクセス）: ファイルパスを手動で指定しなくても、ローカルプロジェクト内のファイルを読み取って一覧表示できます。
- **Create and edit files**（ファイルを作成および編集）: ファイルを作成し、複数の場所にある複数のファイルを編集できます。これはローカルファイルに影響します。
- **Resource retrieval**（リソース取得）: 現在のプロジェクトのイシュー、マージリクエスト、パイプラインログに関する詳細情報を自動的に取得することができます。
- **Multi-source analysis**（マルチソース分析）: 複数のソースからの情報を組み合わせて、複雑な質問に対するより完全な回答を提供できます。[Model Context Protocol](../gitlab_duo/model_context_protocol/_index.md)を使用して、GitLab Duoチャットを外部データソースおよびツールに接続できます。
- **Custom rules**（カスタムルール）: 会話は、指定したカスタマイズされたルールに従うことができます。
- GitLab UIでのGitLab Duoチャット（エージェント型）のみ - **Commit creation**（コミットの作成）: コミットを作成してプッシュできます。

### チャット機能の比較 {#chat-feature-comparison}

| 機能                                              | GitLab Duo Chat（クラシック） |                                                         GitLab Duoチャット（エージェント型）                                                                                                          |
| ------------                                            |------|                                                         -------------                                                                                                          |
| 一般的なプログラミングの質問をする |                       はい  |                                                          はい                                                                                                                   |
| エディタで開いているファイルに関する回答を得る |     はい  |                                                          はい。質問でファイルのパスを指定してください。                                                                   |
| 指定されたファイルに関するコンテキストを提供する |                   はい。会話にファイルを追加するには、`/include`を使用します。 |        はい。質問でファイルのパスを指定してください。                                                                   |
| プロジェクトコンテンツを自律的に検索 |                    いいえ |                                                            はい                                                                                                                   |
| ファイルを自律的に作成および変更する |              いいえ |                                                            はい。ファイルを変更するように依頼してください。ただし、手動で行ったまだコミットしていない変更は上書きされる可能性があります。  |
| IDを指定せずにイシューとマージリクエストを取得する |          いいえ |                                                            はい。他の条件で検索します。たとえば、マージリクエストまたはイシューのタイトルまたは担当者などです。                                       |
| 複数のソースからの情報を組み合わせる |               いいえ |                                                            はい                                                                                                                   |
| パイプラインログを分析する |                                   はい。Duo Enterpriseアドオンが必要です。 |                          はい                                                                                                                   |
| 会話を再開する |                                  はい。`/new`または`/reset`を使用します。 |                             はい。`/new`を使用するか、UIの場合は`/reset`を使用します。                                                                                       |
| 会話を削除する |                                   はい、チャット履歴にあります。|                                             はい、チャット履歴にあります                                                                                                            |
| イシューとマージリクエストを作成する |                                   いいえ |                                                            はい                                                                                                                   |
| Gitの読み取り専用コマンドを使用する |                                                 いいえ |                                                            はい                                                  |
| Gitの書き込みコマンドを使用する |                                                 いいえ |                                                            はい、UIのみ                                                  |
| Shellコマンドを実行する |                                      いいえ |                                                            はい、IDEのみ                                                                                                        |
| MCPツールを実行する |                                      いいえ |                                                            はい、IDEのみ                                                                                                          |

## ユースケース {#use-cases}

GitLab Duoチャットが特に役立つのは、次のような場合です。:

- 複数のファイルまたはGitLabリソースからの情報を必要とする回答が必要です。
- 正確なファイルパスを指定せずに、コードベースに関する質問をしたい。
- プロジェクト全体のイシューまたはマージリクエストのステータスを理解しようとしている。
- ファイルを作成または編集してもらいたい。

### プロンプトの例 {#example-prompts}

GitLab Duoチャットは、自然言語の質問で最も効果的です。次に例を示します。:

- `Read the project structure and explain it to me`、または`Explain the project`。
- `Find the API endpoints that handle user authentication in this codebase`。
- `Please explain the authorization flow for <application name>`。
- `How do I add a GraphQL mutation in this repository?`
- `Show me how error handling is implemented across our application`。
- `Component <component name> has methods for <x> and <y>. Could you split it up into two components?`
- `Could you add in-line documentation for all Java files in <directory>?`
- `Do merge request <MR URL> and merge request <MR URL> fully address this issue <issue URL>?`

## トラブルシューティング {#troubleshooting}

GitLab Duoチャットを使用する場合、次の問題が発生する可能性があります。

### 接続または表示に関するトラブルシューティング {#trouble-connecting-or-viewing}

正しく接続され、チャットを表示できることを確認するには、[トラブルシューティング](../duo_agent_platform/troubleshooting.md)を参照してください。

### 応答時間が遅い {#slow-response-times}

チャットには、リクエストの処理時に大きなレイテンシーが発生します。

この問題が発生するのは、チャットが複数のAPIコールを実行して情報を収集するため、応答にはチャットよりもはるかに時間がかかることがよくあるためです。

### 制限付きのアクセス許可 {#limited-permissions}

チャットは、GitLabユーザーがアクセス許可を持っている同じリソースにアクセスできます。

### 検索の制限 {#search-limitations}

チャットは、セマンティック検索ではなく、キーワードに基づく検索を使用します。つまり、チャットは、検索で使用される正確なキーワードを含まない関連コンテンツを見逃す可能性があります。

## フィードバック {#feedback}

これはベータ機能であるため、皆様からのフィードバックは改善に役立ちます。[issue 542198](https://gitlab.com/gitlab-org/gitlab/-/issues/542198)で、ご意見、ご提案、または問題を共有してください。

## 関連トピック {#related-topics}

- [GitLab Duoチャットブログ: GitLab Duoチャットにエージェント型AIの変革が加わりました](https://about.gitlab.com/blog/2025/05/29/gitlab-duo-chat-gets-agentic-ai-makeover/)
