---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo非エージェンティックチャット
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- [デフォルトLLM](../gitlab_duo/model_selection.md#default-models)
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 16.0で、GitLab.com向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117695)されました（[実験](../../policy/development_stages_support.md#experiment)として）。
- GitLab 16.6で、GitLab.com向けに[ベータ](../../policy/development_stages_support.md#beta)版に変更されました。
- GitLab 16.8でGitLab Self-Managedのベータ版として[導入](https://gitlab.com/groups/gitlab-org/-/epics/11251)されました。
- GitLab 16.9でベータ版のまま、UltimateプランからPremiumプランに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142808)されました。
- GitLab 16.11で[一般提供](../../policy/development_stages_support.md#generally-available)になりました。
- GitLab 17.6以降、GitLab Duoアドオンが必須になりました。
- GitLab 18.3でGitLab Duo Coreに[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)されました。
- GitLab 18.6で[デフォルトLLMが更新](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1541)され、Claude Sonnet 4.5になりした。

{{< /history >}}

GitLab Duo Chatは、コンテキストに基づいた対話型のAIを活用して、開発を加速するAIアシスタントです。この非エージェント型のチャットは次のとおりです:

- 開発環境で直接コードを説明し、改善を提案します。
- コード、マージリクエスト、イシュー、その他のGitLabアーティファクトを分析します。
- 要件とコードベースに基づいて、コード、テスト、ドキュメントを生成します。
- GitLab UI、Web IDE、VS Code、JetBrains IDE、Visual Studioに直接統合します。
- リポジトリおよびプロジェクトからの情報を含めて、的を絞った改善を提供できます。

<i class="fa-youtube-play" aria-hidden="true"></i> [概要を見る](https://www.youtube.com/watch?v=ZQBAuf-CTAY)
<!-- Video published on 2024-04-18 -->

新しい[GitLab Duo Agentic Chat](agentic_chat.md)について学びます。

## サポートされているエディタ拡張機能 {#supported-editor-extensions}

GitLab Duo Chatは、以下で使用できます:

- GitLab UI
- [GitLab Web IDE（クラウド上のVS Code）](../project/web_ide/_index.md)

また、エディタ拡張機能をインストールすることで、以下のIDEでもGitLab Duo Chatを使用できます:

- [VS Code](../../editor_extensions/visual_studio_code/setup.md)
- [JetBrains](../../editor_extensions/jetbrains_ide/setup.md)
- [Eclipse](../../editor_extensions/eclipse/setup.md)
- [Visual Studio](../../editor_extensions/visual_studio/setup.md)

> [!note]
> GitLab Self-Managedをお使いの場合: 最適なユーザーエクスペリエンスと結果を得るには、GitLab 17.2以降を使用してください。以前のバージョンでも動作する可能性がありますが、ユーザーエクスペリエンスが低下する可能性があります。

## GitLab UIでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-the-gitlab-ui}

{{< history >}}

- GitLab 18.5では、GitLab.comのGitLab UIのすべてのページで利用できるように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/562168)されました。
- GitLab 18.6でGitLab.comに新しいナビゲーションとGitLab Duoサイドバーが`paneled_view`[フラグ](../../administration/feature_flags/_index.md)とともに導入されました。デフォルトでは有効になっています。
- 以前のナビゲーション手順はGitLab 18.7で削除されました。
- GitLab 18.8で新しいナビゲーションとGitLab Duoサイドバーが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/574049)になりました。機能フラグ`paneled_view`は削除されました。

{{< /history >}}

前提条件: 

- GitLab Duo Chatにアクセスできる必要があり、GitLab Duoがオンになっている必要があります。
- GitLab Self-Managedでは、Chatが利用可能な場所にユーザーがいる必要があります。以下では利用できません:
  - **マイワーク**ページ（To-Doリストなど）。
  - **ユーザー設定**ページ。
  - **ヘルプ**メニュー。

GitLab UIでChatを使用するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. GitLab Duoのサイドバーで、**新しいGitLab Duo Chat**（{{< icon name="pencil-square" >}}）または**現在のGitLab Duo Chat**（{{< icon name="duo-chat" >}}）を選択します。画面右側のGitLab Duoサイドバーに、Chatの会話が表示されます。
1. Chatのテキストボックスの下にある**エージェント**切替をオフにします。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
   - チャットに[コンテキスト](../gitlab_duo/context.md)を追加できます。
   - インタラクティブなAIチャットが回答を生成するまで、数秒かかる場合があります。
1. オプション。次のことが可能です。
   - フォローアップの質問をします。
   - [別の会話](#have-multiple-conversations)を開始します。

新しい無関係な質問をするには、`/reset`と入力し、**送信**を選択してコンテキストをクリアします。

### Chat履歴を表示する {#view-the-chat-history}

最新の25件のメッセージがチャット履歴に保持されます。

GitLab Duoサイドバーで、**GitLab Duo Chat履歴**（{{< icon name="history" >}}）を選択します。

### 複数の会話を行う {#have-multiple-conversations}

{{< history >}}

- GitLab 17.10で`duo_chat_multi_thread`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/16108)されました。デフォルトでは無効になっています。
- GitLab 17.11の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187443)になりました。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190042)になりました。機能フラグ`duo_chat_multi_thread`は削除されました。
- GitLab UIにおけるチャット履歴の検索機能は、[GitLab 18.9](https://gitlab.com/gitlab-org/gitlab/-/work_items/582513)で導入されました。

{{< /history >}}

GitLab 17.10以降では、Chatとの同時会話を無制限に行えます。

1. 次のいずれかの方法で新しいChatの会話を作成します:

   - GitLab Duoサイドバーで、**新しいGitLab Duo Chat**（{{< icon name="pencil-square" >}}）を選択します。
   - メッセージボックスに`/new`と入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

   新しいChatの会話が前の会話を置き換えます。
1. Chatのテキストボックスの下にある**エージェント**切替をオフにします。
1. すべての会話を確認するには、[Chat履歴](#view-the-chat-history)を表示します。
1. 会話を切り替えるには、Chat履歴で適切な会話を選択します。
1. GitLab UIで、チャット履歴内の特定の会話を検索するには、**Search for a thread**テキストボックスに検索語を入力します。

すべての会話で、無制限にメッセージが保持されます。ただし、LLMのコンテキストウィンドウにコンテンツを収めるために、最後の25件のメッセージのみがLLMに送信されます。

この機能が有効になる前に作成された会話は、Chat履歴には表示されません。

### 会話を削除する {#delete-a-conversation}

会話を削除するには、次の手順に従います:

1. [Chat履歴](#view-the-chat-history)を選択します。
1. 履歴で、**Delete this chat**（{{< icon name="remove" >}}）を選択します。

デフォルトでは、個々の会話は期限切れとなり、30日間操作がないと自動的に削除されます。

ただし、管理者は[この有効期限を変更できます](#configure-chat-conversation-expiration)。

## Web IDEでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-the-web-ide}

{{< history >}}

- GitLab 16.6で[実験的機能](../../policy/development_stages_support.md#experiment)として導入されました。
- GitLab 16.11で一般提供に変更されました。

{{< /history >}}

GitLabのWeb IDEでGitLab Duo Chatを使用するには、次の手順に従います:

1. Web IDEを開きます:
   1. GitLab UIのトップバーで、**検索または移動先**を選択し、プロジェクトを見つけます。
   1. ファイルを選択します。次に、右上隅で**編集** > **Web IDEで開く**を選択します。
1. 次のいずれかの方法でChatを開きます:
   - 左サイドバーで、**GitLab Duo Chat**を選択します。
   - エディタで開いているファイルで、コードを選択します。
     1. 右クリックして、**GitLab Duo Chat**を選択します。
     1. **Explain selected snippet**、**Fix**、**Generate tests**、**Open Quick Chat**または**Refactor**を選択します。
   - キーボードショートカットを使用します: 
     - WindowsまたはLinuxの場合: <kbd>ALT</kbd> + <kbd>d</kbd>
     - macOSの場合: <kbd>Option</kbd> + <kbd>d</kbd>
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

エディタでコードを選択した場合、この選択はGitLab Duo Chatへの質問に含まれます。たとえば、コードを選択して、Chatに`Can you simplify this?`と質問できます。

### 設定の診断を確認する {#check-configuration-diagnostics}

システムのバージョニング、機能の状態管理、機能フラグなど、GitLab Duoの設定診断とシステム設定を確認するには:

- Chatペインの右上隅にある**ステータス**を選択します。

## VS CodeでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-vs-code}

{{< history >}}

- GitLab 16.6で[実験的機能](../../policy/development_stages_support.md#experiment)として導入されました。
- GitLab 16.11で一般提供に変更されました。
- GitLab for VS Code extension 5.29.0でステータスが[追加](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1712)されました。

{{< /history >}}

前提条件: 

- [VS Code拡張機能のインストールと設定](../../editor_extensions/visual_studio_code/setup.md)が完了していること。

GitLab for VS Code extensionでGitLab Duo Chatを使用するには:

1. VS Codeでファイルを開きます。Gitリポジトリ内のファイルである必要はありません。
1. 左サイドバーで、**GitLab Duo Chat** ({{< icon name="duo-chat" >}}) を選択します。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

エディタでコードを選択した場合、この選択はGitLab Duo Chatへの質問に含まれます。たとえば、コードを選択して、Chatに`Can you simplify this?`と質問できます。

### エディタウィンドウでの作業中にChatを使用する {#use-chat-while-working-in-the-editor-window}

{{< history >}}

- GitLab for VS Code extension 5.15.0で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/15218)が開始されました。
- スニペット挿入機能がGitLab for VS Code extension 5.25.0で[追加](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/2150)されました。

{{< /history >}}

エディタウィンドウでGitLab Duo Chatを開くには、次のいずれかの方法を使用します:

- キーボードショートカットから:
  - WindowsおよびLinuxの場合: <kbd>ALT</kbd> + <kbd>c</kbd>
  - macOSの場合: <kbd>Option</kbd> + <kbd>c</kbd>
- IDEで現在開いているファイルで右クリックし、**GitLab Duo Chat** > **Open Quick Chat**を選択します。必要に応じて、コードを選択して追加のコンテキストを提供します。
- コマンドパレットを開き、**GitLab Duo Chat: Open Quick Chat**を選択します。

Quick Chatを開いたら、次の手順を実行します:

1. メッセージボックスに質問を入力します。次の方法も使用できます:
   - `/`と入力して、使用可能なすべてのコマンドを表示します。
   - `/re`と入力して、`/refactor`および`/reset`を表示します。
1. 質問を送信するには、**送信**を選択するか、<kbd>Command</kbd> + <kbd>Enter</kbd>キーを押します。
1. 応答に含まれるコードを使用するには、コードブロックの上にある**Copy Snippet**リンクと**Insert Snippet**リンクを使用します。
1. チャットを終了するには、ガターでチャットアイコンを選択するか、チャットにフォーカスしているときに**Escape**キーを押します。

### Chatのステータスを確認する {#check-the-status-of-chat}

GitLab Duo設定のヘルスチェックを行うには:

- Chatペインの右上隅にある**ステータス**を選択します。

### Chatを閉じる {#close-chat}

GitLab Duo Chatを閉じるには:

- 左サイドバーのGitLab Duo Chatの場合は、**GitLab Duo Chat** ({{< icon name="duo-chat" >}}) を選択します。
- ファイルに埋め込まれているクイックチャットウィンドウの場合は、右上隅で**折りたたむ**({{< icon name="chevron-lg-up" >}})を選択します。

## Windows用Visual StudioでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-visual-studio-for-windows}

前提条件: 

- [GitLab for Visual Studio extension](../../editor_extensions/visual_studio/setup.md)をインストールし、設定済みであること。

GitLab for Visual Studio extensionでGitLab Duo Chatを使用するには:

1. Visual Studioで、ファイルを開きます。Gitリポジトリ内のファイルである必要はありません。
1. 次のいずれかの方法でChatを開きます:
   - 上部のメニューバーで、**Extensions**を選択し、次に**Open Duo Chat**を選択します。
   - エディタで開いているファイルで、コードを選択します。
     1. 右クリックして、**GitLab Duo Chat**を選択します。
     1. **Explain selected code**または**Generate Tests**を選択します。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

エディタでコードを選択している場合、この選択は質問とともにAIに送信されます。これにより、このコード選択に関する質問をできるようになります。たとえば、`Could you refactor this?`などです。

## JetBrains IDEでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-jetbrains-ides}

{{< history >}}

- GitLab 16.11で一般提供として導入されました。

{{< /history >}}

前提条件: 

- GitLab DuoプラグインをJetBrains IDE向けに[インストールして構成済み](../../editor_extensions/jetbrains_ide/setup.md)であること。

JetBrains IDE向けのGitLab DuoプラグインでGitLab Duo Chatを使用するには:

1. JetBrains IDEでプロジェクトを開きます。
1. チャットウィンドウまたはエディタウィンドウでGitLab Duo Chatを開きます。

### チャットウィンドウ内 {#in-a-chat-window}

チャットウィンドウでGitLab Duo Chatを開くには、次のいずれかの方法を使用します:

- 右のツールウィンドウバーで、**GitLab Duo Non-Agentic Chat**を選択します。
- キーボードショートカットから:
  - WindowsおよびLinuxの場合: <kbd>ALT</kbd> + <kbd>d</kbd>
  - macOSの場合: <kbd>Option</kbd> + <kbd>d</kbd>
- 開いているエディタファイルから:
  1. 右クリックして、**GitLab Duo Chat**を選択します。
  1. **Open Chat Window**を選択します。
- 選択したコードで:
  1. コマンドに含めるコードをエディタで選択します。
  1. 右クリックして、**GitLab Duo Chat**を選択します。
  1. **Explain Code**、**Fix Code**、**Generate Tests**または**Refactor Code**を選択します。
- 強調表示されたコードイシューから:
  1. 右クリックして**Show Context Actions**を選択します。
  1. **Fix with Duo**を選択します。
- GitLab Duoアクション用のキーボードまたはマウスのショートカットを使用します。これは**Settings** > **Keymap**で設定できます。

GitLab Duo Chatを開いた後:

1. メッセージボックスに質問を入力します。次の方法も使用できます:
   - `/`と入力して、使用可能なすべてのコマンドを表示します。
   - `/re`と入力して、`/refactor`および`/reset`を表示します。
1. 質問を送信するには、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. 応答のコードブロック内のボタンを使用して操作します。

### エディタウィンドウ内 {#in-an-editor-window}

{{< history >}}

- [GitLab Duoプラグインfor JetBrains 3.0.0](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/80)および[GitLab for VS Code extension 5.14.0](https://gitlab.com/groups/gitlab-org/-/epics/15218)で一般提供が開始されました。

{{< /history >}}

エディタウィンドウでGitLab Duo Chatを開くには、次のいずれかの方法を使用します:

- キーボードショートカットから:
  - WindowsおよびLinuxの場合: <kbd>ALT</kbd> + <kbd>c</kbd>
  - macOSの場合: <kbd>Option</kbd> + <kbd>c</kbd>
- IDEで開いているファイルでコードを選択し、フローティングツールバーで**GitLab Duo Quick Chat**（{{< icon name="tanuki-ai" >}}）を選択します。
- 右クリックして**GitLab Duo Chat** > **Open Quick Chat**を選択します。

Quick Chatを開いたら、次の手順を実行します:

1. メッセージボックスに質問を入力します。次の方法も使用できます:
   - `/`と入力して、使用可能なすべてのコマンドを表示します。
   - `/re`と入力して、`/refactor`および`/reset`を表示します。
1. 質問を送信するには、<kbd>Enter</kbd>を押します。
1. 応答に含まれるコードを使用するには、コードブロックの周りのボタンを使用します。
1. チャットを終了するには、**Escape to close**を選択するか、チャットにフォーカスがある状態で<kbd>Escape</kbd>キーを押します。

<div class="video-fallback">
  <a href="https://youtu.be/5JbAM5g2VbQ">GitLab Duo Quick Chatの使用方法を見る</a>。
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/5JbAM5g2VbQ?si=pm7bTRDCR5we_1IX" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2024-10-15 -->

## EclipseでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-eclipse}

{{< history >}}

- GitLab 17.11で実験的機能からベータ版に[変更](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163)されました。

{{< /history >}}

前提条件: 

- [GitLab for Eclipseプラグインのインストールと設定](../../editor_extensions/eclipse/setup.md)が完了していること。

GitLab for EclipseプラグインでGitLab Duo Chatを使用するには:

1. Eclipseでプロジェクトを開きます。
1. 右上隅で、**GitLab Duo Chat** ({{< icon name="duo-chat" >}}) を選択するか、キーボードショートカットを使用します:
   - WindowsおよびLinuxの場合: <kbd>Alt</kbd>+<kbd>D</kbd>
   - macOSの場合: <kbd>Option</kbd>+<kbd>D</kbd>
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

## Chatの会話の有効期限を設定する {#configure-chat-conversation-expiration}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161997)されました。

{{< /history >}}

会話を有効期限切れとみなし、自動的に削除するまでの、会話の継続期間を設定できます。

前提条件: 

- 管理者である必要があります。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duo Chatの会話**で、次のいずれかのオプションを選択します:
   - **会話の最終更新後**。
   - **会話作成後**。
1. **変更を保存**を選択します。

## IDEショートカット {#ide-shortcuts}

サポートされているIDEでチャットを使用する場合、[キーボードショートカット](../shortcuts.md#gitlab-duo-chat)を使用できます。

## 利用可能な言語モデル {#available-language-models}

異なる言語モデルをGitLab Duo Chatのソースにすることができます。

- GitLab.comまたはGitLab Self-Managedでは、デフォルトのGitLabマネージドモデルと、GitLabがホストするクラウドベースのAIゲートウェイが使用されます。
- GitLab Self-Managedでは、GitLab 17.9以降の場合、[サポートされているセルフホストモデルを使用したGitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md)が利用できます。セルフホストモデルは、外部モデルに何も送信されないようにすることで、セキュリティとプライバシーを最大限に高めます。GitLabが管理するモデル、その他のサポートされている言語モデル、または独自の互換性のあるモデルを使用できます。

## 入力と出力の長さ {#input-and-output-length}

Chatの各会話では、入力と出力の長さが制限されています。

- 入力は20万トークン（約68万文字）に制限されています。入力トークンには以下が含まれます: 
  - [Chatが認識するコンテキスト](../gitlab_duo/context.md)すべて。
  - その会話内のすべての過去の質問と回答。
- 出力は8,192トークン（約28,600文字）に制限されています。

## フィードバックを提供する {#give-feedback}

GitLab Duo Chatエクスペリエンスを継続的に向上させるために、GitLabでは皆様からのフィードバックをお待ちしております。フィードバックにより、お客様のニーズに合わせてチャットをカスタマイズし、すべての人のパフォーマンスを向上させることができます。

特定の応答に関するフィードバックをお寄せいただくには、応答メッセージのフィードバックボタンを使用してください。または、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/430124)にコメントを追加することもできます。
