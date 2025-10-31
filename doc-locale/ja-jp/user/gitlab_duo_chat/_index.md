---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chat（クラシック）
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- LLM: Anthropic ClaudeおよびVertex AI Search。LLMは、質問内容によって異なります。
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /details >}}

{{< history >}}

- GitLab 16.0のSaaSの[実験的機能](../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117695)されました。
- GitLab 16.6でSaaSの[ベータ](../../policy/development_stages_support.md#beta)に変更されました。
- GitLab 16.8でGitLab Self-Managedのベータ版として[導入](https://gitlab.com/groups/gitlab-org/-/epics/11251)されました。
- GitLab 16.9でベータ版のまま、UltimateプランからPremiumプランに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142808)されました。
- GitLab 16.11で[一般提供](../../policy/development_stages_support.md#generally-available)になりました。
- GitLab 17.6以降では、GitLab Duoアドオンが必須となりました。
- GitLab 18.3で、名前がGitLab Duo Chat（クラシック）に更新されました。
- GitLab 18.3でGitLab Duo Coreに[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)されました。

{{< /history >}}

GitLab Duo Chat（クラシック）は、コンテキストに応じた会話型AIで開発を加速するAIアシスタントです。チャットは:

- 開発環境で直接コードを説明し、改善を提案します。
- コード、マージリクエスト、イシュー、その他のGitLabアーティファクトを分析します。
- 要件とコードベースに基づいて、コード、テスト、ドキュメントを生成します。
- GitLab UI、Web IDE、VS Code、JetBrains IDE、Visual Studioに直接統合します。
- リポジトリおよびプロジェクトからの情報を含めて、的を絞った改善を提供できます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[概要を見る](https://www.youtube.com/watch?v=ZQBAuf-CTAY)
<!-- Video published on 2024-04-18 -->

新しい[GitLab Duo Chat (エージェント型)](agentic_chat.md)について説明します。

## サポートされているエディタ拡張機能 {#supported-editor-extensions}

GitLab Duo Chatは、以下で使用できます:

- GitLab UI
- [GitLab Web IDE（クラウド上のVS Code）](../project/web_ide/_index.md)

また、エディタ拡張機能をインストールすることで、以下のIDEでもGitLab Duo Chatを使用できます:

- [VS Code](../../editor_extensions/visual_studio_code/setup.md)
- [JetBrains](../../editor_extensions/jetbrains_ide/setup.md)
- [Eclipse](../../editor_extensions/eclipse/setup.md)
- [Visual Studio](../../editor_extensions/visual_studio/setup.md)

{{< alert type="note" >}}

GitLab Self-Managedを使用している場合: 最適なユーザーエクスペリエンスと結果を得るには、GitLab 17.2以降を使用してください。以前のバージョンでも動作する可能性がありますが、ユーザーエクスペリエンスが低下する可能性があります。

{{< /alert >}}

## GitLab UIでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-the-gitlab-ui}

前提要件:

- GitLab Duo Chatにアクセスできる必要があり、GitLab Duoがオンになっている必要があります。
- Chatが利用可能な場所にいる必要があります。以下では利用できません:
  - **マイワーク**ページ（To-Doリストなど）。
  - **ユーザー設定**ページ。
  - **ヘルプ**メニュー。

GitLab UIでGitLab Duo Chatを使用するには:

1. 右上隅で、**GitLab Duo Chat**を選択します。画面の右側にドロワーが開きます。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
   - チャットに[コンテキスト](../gitlab_duo/context.md#gitlab-duo-chat)を追加できます。
   - インタラクティブなAIチャットが回答の生成するまで、数秒かかる場合があります。
1. オプション。フォローアップの質問をします。

新しい無関係な質問をするには、`/reset`または`/clear`と入力して**送信**を選択し、コンテキストをクリアします。

### Chat履歴を表示する {#view-the-chat-history}

最新の25件のメッセージがChat履歴に保持されます。

履歴を表示するには:

- Chatドロワーの右上隅で、**Chat履歴**（{{< icon name="history" >}}）を選択します。

### 複数の会話をする {#have-multiple-conversations}

{{< history >}}

- GitLab 17.10で`duo_chat_multi_thread`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/16108)されました。デフォルトでは無効になっています。
- GitLab 17.11の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187443)になりました。
- GitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190042)になりました。機能フラグ`duo_chat_multi_thread`は削除されました。

{{< /history >}}

GitLab 17.10以降では、Chatとの同時会話を無制限に行えます。

1. 右上隅で、**GitLab Duo Chat**を選択します。画面の右側にドロワーが開きます。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。
1. 次のいずれかを選択して、Chatで新しい会話を作成します:
   - ドロワーの右上隅で、**新しいチャット**（{{< icon name="duo-chat-new" >}}）を選択します。
   - メッセージボックスに`/new`と入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。新しいChatドロワーが前のものと置き換わります。
1. 別の新しい会話を作成します。
1. すべての会話を表示するには、Chatドロワーの右上隅で、**Chat履歴**（{{< icon name="history" >}}）を選択します。
1. 会話を切り替えるには、Chat履歴で適切な会話を選択します。

すべての会話で、無制限にメッセージが保持されます。ただし、LLMのコンテキストウィンドウにコンテンツを収めるために、最後の25件のメッセージのみがLLMに送信されます。

この機能が有効になる前に作成された会話は、Chat履歴には表示されません。

### 会話を削除する {#delete-a-conversation}

会話を削除するには、次の手順に従います:

1. Chatドロワーの右上隅で、**Chat履歴**（{{< icon name="history" >}}）を選択します。
1. 履歴で、**会話を削除する**（{{< icon name="remove" >}}）を選択します。

デフォルトでは、個々の会話は期限切れとなり、30日間操作がないと自動的に削除されます。ただし、管理者は[この有効期限を変更できます](#configure-chat-conversation-expiration)。

## Web IDEでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-the-web-ide}

{{< history >}}

- GitLab 16.6で[実験的機能](../../policy/development_stages_support.md#experiment)として導入されました。
- GitLab 16.11で一般提供に変更されました。

{{< /history >}}

GitLabのWeb IDEでGitLab Duo Chatを使用するには、次の手順に従います:

1. Web IDEを開きます:
   1. GitLab UIの左側のサイドバーで**検索または移動先**を選択して、プロジェクトを見つけます。
   1. ファイルを選択します。次に、右上隅で**編集** > **Web IDEで開く**を選択します。
1. 次のいずれかの方法でChatを開きます:
   - 左側のサイドバーで、**GitLab Duo Chat**を選択します。
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
- VS Code用GitLab Workflow拡張機能5.29.0でステータス機能が[追加](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1712)されました。

{{< /history >}}

前提要件:

- [VS Code拡張機能のインストールと設定](../../editor_extensions/visual_studio_code/setup.md)が完了していること。

VS Code用GitLab Workflow拡張機能でGitLab Duo Chatを使用するには、次の手順に従います:

1. VS Codeでファイルを開きます。これは、Gitリポジトリ内のファイルである必要はありません。
1. 左側のサイドバーで、**GitLab Duo Chat**（{{< icon name="duo-chat" >}}）を選択します。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

エディタでコードを選択した場合、この選択はGitLab Duo Chatへの質問に含まれます。たとえば、コードを選択して、Chatに`Can you simplify this?`と質問できます。

### エディタウィンドウでの作業中にChatを使用する {#use-chat-while-working-in-the-editor-window}

{{< history >}}

- VS Code用GitLab Workflow拡張機能5.15.0で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/15218)として導入されました。
- VS Code用GitLab Workflow拡張機能5.25.0で、Insert Snippetが[追加](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/2150)されました。

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
   - `/re`と入力して、`/refactor`を表示します。
1. 質問を送信するには、**送信**を選択するか、<kbd>コマンド</kbd> + <kbd>Enter</kbd>キーを押します。
1. 応答に含まれるコードを使用するには、コードブロックの上にある**Copy Snippet**リンクと**Insert Snippet**リンクを使用します。
1. チャットを終了するには、ガターでチャットアイコンを選択するか、チャットにフォーカスしているときに**Escape**キーを押します。

### Chatのステータスを確認する {#check-the-status-of-chat}

GitLab Duo設定のヘルスチェックを行うには:

- Chatペインの右上隅にある**ステータス**を選択します。

### Chatを閉じる {#close-chat}

GitLab Duo Chatを閉じるには:

- Duo Chatの場合、左側のサイドバーで**GitLab Duo Chat**（{{< icon name="duo-chat" >}}）を選択します。
- ファイルに埋め込まれているクイックチャットウィンドウの場合は、右上隅で**折りたたむ**({{< icon name="chevron-lg-up" >}})を選択します。

## Windows用Visual StudioでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-visual-studio-for-windows}

前提要件:

- [Visual Studio用GitLab拡張機能のインストールと設定](../../editor_extensions/visual_studio/setup.md)が完了していること。

Visual Studio用GitLab拡張機能でGitLab Duo Chatを使用するには、以下の手順を実行します:

1. Visual Studioで、ファイルを開きます。これは、Gitリポジトリ内のファイルである必要はありません。
1. 次のいずれかの方法でChatを開きます:
   - 上部のメニューバーで、**Extensions**をクリックし、**Open Duo Chat**を選択します。
   - エディタで開いているファイルで、コードを選択します。
     1. 右クリックして、**GitLab Duo Chat**を選択します。
     1. **Explain selected code**または**Generate Tests**を選択します。
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

エディタでコードを選択している場合、この選択は質問とともにAIに送信されます。これにより、このコード選択に関する質問をできるようになります。たとえば、`Could you refactor this?`などです。

## JetBrains IDEでGitLab Duo Chatを使用する {#use-gitlab-duo-chat-in-jetbrains-ides}

{{< history >}}

- GitLab 16.11で一般提供として導入されました。

{{< /history >}}

前提要件:

- [JetBrains IDE用GitLabプラグインのインストールと設定](../../editor_extensions/jetbrains_ide/setup.md)が完了していること。

JetBrains IDE用GitLabプラグインでGitLab Duo Chatを使用するには、次の手順を実行します:

1. JetBrains IDEでプロジェクトを開きます。
1. チャットウィンドウまたはエディタウィンドウでGitLab Duo Chatを開きます。

### チャットウィンドウ内 {#in-a-chat-window}

チャットウィンドウでGitLab Duo Chatを開くには、次のいずれかの方法を使用します:

- 右側のツールウィンドウバーで、**GitLab Duo Chat**を選択します。
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

- [JetBrains用GitLab Duoプラグイン3.0.0](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/80)および[VS Code用GitLab Workflow拡張機能5.14.0](https://gitlab.com/groups/gitlab-org/-/epics/15218)で一般提供として導入されました。

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

- GitLab 17.11で実験的機能からベータに[変更](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163)されました。

{{< /history >}}

前提要件:

- [GitLab for Eclipseプラグインのインストールと設定](../../editor_extensions/eclipse/setup.md)が完了していること。

GitLab for EclipseプラグインでGitLab Duo Chatを使用するには:

1. Eclipseでプロジェクトを開きます。
1. **GitLab Duo Chat**（{{< icon name="duo-chat" >}}）を選択するか、キーボードショートカットを使用します:
   - WindowsおよびLinuxの場合: <kbd>ALT</kbd> + <kbd>d</kbd>
   - macOSの場合: <kbd>Option</kbd> + <kbd>d</kbd>
1. メッセージボックスに質問を入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

## Chatの会話の有効期限を設定する {#configure-chat-conversation-expiration}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161997)されました。

{{< /history >}}

会話を有効期限切れとみなし、自動的に削除するまでの、会話の継続期間を設定できます。

前提要件:

- 管理者である必要があります。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. 右下隅で、**設定の変更**を選択します。
1. **GitLab Duo Chatの会話の有効期限**セクションで、次のいずれかのオプションを選択します:
   - **会話の最終更新日から換算して有効期限を設定する**。
   - **会話の作成日から換算して有効期限を設定する**。
1. **変更を保存**を選択します。

## 利用可能な言語モデル {#available-language-models}

異なる言語モデルをGitLab Duo Chatのソースにすることができます。

- GitLab.comまたはGitLab Self-Managedでは、GitLabがホストするデフォルトのGitLab AIベンダーモデルとクラウドベースのAIゲートウェイを使用します。
- GitLab Self-Managedでは、GitLab 17.9以降の場合、[サポートされているセルフホストモデルを使用したGitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md)が利用できます。セルフホストモデルは、外部モデルに何も送信されないようにすることで、セキュリティとプライバシーを最大限に高めます。GitLab AIベンダーモデル、サポートされているその他の言語モデルを使用するか、独自の互換性のあるモデルを使用できます。

## 入力と出力の長さ {#input-and-output-length}

Chatの各会話では、入力と出力の長さが制限されています。

- 入力は20万トークン（約68万文字）に制限されています。入力トークンには以下が含まれます: 
  - [Chatが認識する](../gitlab_duo/context.md#gitlab-duo-chat)すべてのコンテキスト。
  - その会話内のすべての過去の質問と回答。
- 出力は8,192トークン（約28,600文字）に制限されています。

## フィードバックを提供する {#give-feedback}

GitLab Duo Chatエクスペリエンスを継続的に向上させるために、皆様からのフィードバックをお待ちしております。フィードバックをお寄せいただくことで、お客様のニーズに合わせてチャットをカスタマイズし、すべての人のパフォーマンスを向上させることができます。

特定の応答に関するフィードバックをお寄せいただくには、応答メッセージのフィードバックボタンを使用してください。または、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/430124)にコメントを追加することもできます。
