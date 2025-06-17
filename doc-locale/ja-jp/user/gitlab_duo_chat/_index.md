---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chat
---

{{< details >}}

- プラン: GitLab Duo Proを含む Premium、GitLab Duo Proを含むUltimate、またはEnterprise - [トライアルを開始](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- LLM: Anthropic [Claude 3.7 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-7-sonnet)、Anthropic [Claude 3.5 Sonnet V2](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet-v2)、Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)、Anthropic [Claude 3.5 Haiku](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-haiku)、および[Vertex AI Search](https://cloud.google.com/enterprise-search)。LLMは、尋ねられた質問によって異なります。

{{< /details >}}

{{< history >}}

- GitLab 16.0のSaaSの[実験](../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117695)。
- GitLab 16.6でSaaSの[ベータ](../../policy/development_stages_support.md#beta)に変更。
- GitLab 16.8でGitLab Self-Managedの[ベータ](../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/groups/gitlab-org/-/epics/11251)。
- GitLab 16.9で、[ベータ](../../policy/development_stages_support.md#beta)期間中である一方でUltimateから[Premium](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142808)プランに変更。
- GitLab 16.11で[一般提供](../../policy/development_stages_support.md#generally-available)。
- GitLab 17.6以降では、GitLab Duoアドオンが必須となりました。

{{< /history >}}

GitLab Duo Chatは、コンテキストに応じた会話型AIによって開発を加速する、AI搭載のアシスタントです。Duo Chatを使用すると、以下が可能です。

- コードを説明し、開発環境で直接改善を提案します。
- コード、マージリクエスト、イシュー、その他のGitLabアーティファクトを分析します。
- 要件とコードベースに基づいて、コード、テスト、ドキュメントを生成します。
- GitLab UI、Web IDE、VS Code、JetBrains IDE、Visual Studioに直接統合します。
- リポジトリおよびプロジェクトからの情報を含めて、的を絞った改善を提供できます。

## サポートされているエディタ拡張機能

GitLab Duo Chatは、以下で使用できます。

- GitLab UI
- [GitLab Web IDE(クラウド上のVS Code)](../project/web_ide/_index.md)
- VS Code（[VS Code用GitLabワークフロー拡張機能](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)を使用）
- JetBrains IDE（[JetBrains用GitLab Duoプラグイン](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)を使用）
- Visual Studio for Windows（[Visual Studio用GitLab拡張機能](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio)を使用）

{{< alert type="note" >}}

GitLab Self-Managedを使用している場合、GitLab Duoで最高のユーザーエクスペリエンスと結果を得るには、GitLab 17.2以降が必要です。以前のバージョンでも引き続き動作する可能性はありますが、エクスペリエンスが低下するおそれがあります。

{{< /alert >}}

## Chatが認識するコンテキスト

GitLab Duo Chatは、作業中のコンテキストを認識することがあります。認識しない場合は、リクエストをより具体的にする必要があります。

Chatが認識するコンテキストは、次のとおりご使用のサブスクリプションプランによっても異なります。

- GitLab UIの場合:
  - Premium(GitLab Duo Proアドオン付き)またはUltimate(GitLab Duo ProまたはEnterpriseアドオン付き)のいずれかのプランをお使いの場合、Chatはコードファイルを認識します。
  - 他すべてのエリアを認識させるには、GitLab Duo Enterpriseを含むUltimateが必要です。
- IDEの場合:
  - Premium（GitLab Duo Proアドオン付き）、またはUltimate（GitLab Duo ProまたはEnterpriseアドオン付き）のいずれかをお持ちの場合、Chatはエディタで選択された行を認識します。
  - 他すべてのエリアを認識させるには、GitLab Duo Enterpriseを含むUltimateが必要です。

GitLab UIでは、GitLab Duo Chatは次のエリアを認識します。

| エリア           | Chatへの質問方法 |
|----------------|-----------------|
| エピック          | エピックから、`this epic`、`this`、またはURLについて質問します。任意のUIエリアから、URLについて質問します。 |
| イシュー         | イシューから、`this issue`、`this`、またはURLについて質問します。任意のUIエリアから、URLについて質問します。 |
| コードファイル     | 単一のファイルから、`this code`または`this file`について質問します。 |
| マージリクエスト | マージリクエストから、`this merge request`、`this`、またはURLについて質問します。詳細については、[特定のマージリクエストについて質問する](examples.md#ask-about-a-specific-merge-request)を参照してください。 |
| コミット        | コミットから、`this commit`または`this`について質問します。任意のUIエリアから、URLについて質問します。 |
| パイプラインジョブ  | パイプラインジョブから、`this pipeline job`または`this`について質問します。任意のUIエリアから、URLについて質問します。 |

IDEでは、GitLab Duo Chatは次のエリアを認識します。

| エリア                         | Chatへの質問方法 |
|------------------------------|-----------------|
| エディタで選択された行 | 行を選択した状態で、`this code`または`this file`について質問します。Chatはファイルを認識しません。質問したい行を選択する必要があります。 |
| エピック                        | URLについて質問します。 |
| イシュー                       | URLについて質問します。 |
| ファイル                        | `/include`コマンドを使用して、Duo Chatのコンテキストに追加するプロジェクトファイルを検索します。ファイルを追加したら、そのファイルの内容に関する質問をDuo Chatにできるようになります。VS CodeおよびJetBrains IDEで利用できます。詳細については、[特定のファイルについて質問する](examples.md#ask-about-specific-files-in-the-ide)を参照してください。 |

さらに、IDEでは、`/explain`、`/refactor`、`/fix`、`/tests,`などのスラッシュ(/)コマンドを使用すると、Duo Chatは選択したコードにアクセスできます。

Duo Chatは、以下へのアクセスが常に可能です。

- GitLabドキュメント。
- 一般的なプログラミングおよびコーディングの知識。

当社では、Chatのコンテキスト認識を拡張してより多くの種類のコンテンツを認識できるように、改善を継続的に行っています。

### 追加機能

[リポジトリX-Ray](../project/repository/code_suggestions/repository_xray.md)を使用すると、[GitLab Duoコード提案](../project/repository/code_suggestions/_index.md)のコード生成リクエストを自動的に充実させることができます。プロジェクトがコード提案にアクセスできる場合、`/refactor`、`/fix`、および`/tests`スラッシュコマンドも最新のリポジトリX-Rayレポートにアクセス可能となり、Duoのコンテキストとしてそのレポートを含めます。

GitLab Duoの拡張機能は、既知の形式に一致するシークレットと機密性の高い値をスキャンします。拡張機能は、この機密性の高いコンテンツをDuo Chatに送信する前、またはコード生成に使用する前にローカルで削除します。これは、`/include`を介して追加されたファイル、およびすべての生成コマンドに適用されます。

## GitLab UIでGitLab Duo Chatを使用する

1. 右上隅で、**GitLab Duo Chat**を選択します。画面の右側にdrawerが開きます。

   > **GitLab Duo Chat**ボタンは、次のセクションでは**表示されません**。
   >
   > - [To Do](../todos.md)リストといった、**ご自身の作業に関する**ページ。
   > - [**ユーザープロファイル**](../profile/_index.md)。
   > - **ヘルプ**。

1. チャットテキストボックスに質問を入力し、**Enter**キーを押すか、**送信**を選択します。インタラクティブなAIチャットからの回答の生成には、数秒要することがあります。
1. （オプション）フォローアップの質問をします。

以前の会話とは関係のない新しい質問をする際は、`/reset`または`/clear`と入力してコンテキストをクリアし、**送信**を選択することで、より適切な回答が得られる場合があります。

{{< alert type="note" >}}

チャット履歴に保持されるのは、最後の25件のメッセージのみです。

{{< /alert >}}

### Chatで複数の会話を行う

{{< details >}}

- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- `duo_chat_multi_thread`という名前の[フラグ](../../administration/feature_flags.md)を使用して、GitLab 17.10で[導入](https://gitlab.com/groups/gitlab-org/-/epics/16108)。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab 17.10以降では、Chatと複数の同時会話を行うことができます。

1. 右上隅で、**GitLab Duo Chat**を選択します。画面の右側にdrawerが開きます。
1. チャットテキストボックスに質問を入力し、**Enter**キーを押すか、**送信**を選択します。
1. Chatとの新しい会話を作成するには、次のいずれかを実行します。
   - Chat drawerの左上隅で、**New Chat**を選択します。
   - テキストボックスに`/new`と入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。新しいChat drawerが表示され、以前のChat drawerが置き換えられます。

   Chatで同時に行える会話の数に制限はありません。

   {{< alert type="note" >}}

   複数の会話を使用する場合、`/new`スラッシュコマンドは、`/reset`または`/clear`スラッシュコマンドを置き換えます。

   {{< /alert >}}

1. すべての会話を表示するには、Chat drawerの左上隅で、**チャット履歴**を選択します。

   複数の会話機能が有効になる前に作成された会話は、チャット履歴には表示されません。

1. 会話を切り替えるには、チャット履歴で適切な会話を選択します。

   すべての会話で、無制限にメッセージが保持されます。ただし、LLMのコンテキストウィンドウにコンテンツを収めるために、最後の25件のメッセージのみがLLMに送信されます。

#### 会話を削除する

会話を削除するには、次の手順に従います。

1. Chat drawerの左上隅で、**チャット履歴**を選択します。
1. チャット履歴で、**会話を削除**を選択します。

> 個々の会話は、30日間操作がないと自動的に削除されます。
>
> ユーザーの権限またはロールがプロジェクトまたはグループ内で変更されると、そのユーザーのすべてのチャット会話が削除されます。

## Web IDEでGitLab Duo Chatを使用する

{{< history >}}

- GitLab 16.6で[実験](../../policy/development_stages_support.md#experiment)として導入。
- GitLab 16.11で一般提供に変更。

{{< /history >}}

GitLabのWeb IDEでGitLab Duo Chatを使用するには、次の手順に従います。

1. 次の手順でWeb IDEを開きます。
   1. GitLab UIで、左側のサイドバーで**検索または移動**を選択し、プロジェクトを見つけます。
   1. ファイルを選択します。次に、右上隅で**編集 > Web IDE で開く**を選択します。
1. 次に、下記のいずれかの方法でChatを開きます。
   - 左側のサイドバーで、**GitLab Duo Chat**を選択します。
   - エディタで開いているファイルで、コードを選択します。
     1. 右クリックして、**GitLab Duo Chat**を選択します。
     1. **Explain selected code**、**Generate Tests**、または**Refactor**を選択します。
   - キーボードショートカットを使用します。WindowsおよびLinuxの場合は<kbd>ALT</kbd>+<kbd>d</kbd>、Macの場合は<kbd>Option</kbd>+<kbd>d</kbd>を使用します。
1. メッセージボックスに質問を入力し、**Enter**キーを押すか、**送信**を選択します。

エディタでコードを選択している場合、この選択は質問とともにAIに送信されます。これにより、このコード選択に関する質問をできるようになります。たとえば、`Could you simplify this?`などです。

## VS CodeでGitLab Duo Chatを使用する

{{< history >}}

- GitLab 16.6で[実験](../../policy/development_stages_support.md#experiment)として導入。
- GitLab 16.11で一般提供に変更。
- VS Code用GitLabワークフロー拡張機能5.29.0でステータスが[追加](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1712)。

{{< /history >}}

前提条件:

- [VS Code拡張機能をインストールして設定](../../editor_extensions/visual_studio_code/setup.md)済みである。

VS Code用GitLabワークフロー拡張機能でGitLab Duo Chatを使用するには、以下の手順に従います。

1. VS Codeでファイルを開きます。これは、Gitリポジトリ内のファイルである必要はありません。
1. 左側のサイドバーで、**GitLab Duo Chat**({{< icon name="duo-chat" >}})を選択します。
1. メッセージボックスに質問を入力し、**Enter**キーを押すか、**送信**を選択します。
1. チャットペインの右上隅で、**Show Status**を選択して、コマンドパレットに情報を表示します。

### コードを選択してDuo Chatを使用する

コードのサブセットを操作しているときに、Duo Chatと対話できます。

1. VS Codeでファイルを開きます。これは、Gitリポジトリ内のファイルである必要はありません。
1. ファイルで、コードを選択します。
1. 右クリックして、**GitLab Duo Chat**を選択します。
1. オプションを選択するか、**クイックチャットを開く**を選択し、`Can you simplify this code?`などの質問をして、<kbd>Enter</kbd>キーを押します。

### Duo Chatを閉じる

Duo Chatを閉じるには、以下の手順に従います。

- 左側のサイドバーのDuo Chatの場合は、**GitLab Duo Chat** ({{< icon name="duo-chat" >}})を選択します。
- ファイルに埋め込まれているクイックチャットウィンドウの場合は、右上隅で**折りたたむ**({{< icon name="chevron-lg-up" >}})を選択します。

### エディタウィンドウ内

{{< history >}}

- VS Code用GitLabワークフロー拡張機能5.15.0で[一般提供](https://gitlab.com/groups/gitlab-org/-/epics/15218)として導入。
- VS Code用GitLabワークフロー拡張機能5.25.0で、[スニペットの挿入](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/2150)が追加。

{{< /history >}}

エディタウィンドウでGitLab Duo Chatを開くには、次のいずれかの方法を使用します。

- 次のキーボードショートカットを押します。
  - MacOSの場合: <kbd>Option</kbd> + <kbd>c</kbd>
  - WindowsまたはLinuxの場合: <kbd>ALT</kbd> + <kbd>c</kbd>
- IDEで現在開いているファイルを右クリックし、**GitLab Duo Chat > Open Quick Chat**を選択します。必要に応じて、コードを選択して追加のコンテキストを提供します。
- [コマンドパレット](https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette)を開き、**GitLab Duo Chat: Open Quick Chat**を選択します。

Quick Chatを開いたら、次の手順を実行します。

1. メッセージボックスに質問を入力します。次のようにテキストを入力すると、使用可能なコマンドが表示されます。
   - `/`と入力して、使用可能なすべてのコマンドを表示します。
   - `/re`と入力して、`/refactor`を表示します。
1. 質問を送信するには、**送信**を選択するか、<kbd>Command</kbd> + <kbd>Enter</kbd>キーを押します。
1. 応答のコードブロックの上にある**スニペットをコピー**リンクと**スニペットを挿入**リンクを使用して、チャットと対話します。
1. チャットを終了するには、ガターでチャットアイコンを選択するか、チャットにフォーカスしているときに**Escape**キーを押します。

## Windows用Visual StudioでGitLab Duo Chatを使用する

前提条件:

- [Visual Studio用GitLab拡張機能のインストールと設定](../../editor_extensions/visual_studio/setup.md)が完了している。

Visual Studio用GitLab拡張機能でGitLab Duo Chatを使用するには、以下の手順を実行します。

1. Visual Studioで、ファイルを開きます。これは、Gitリポジトリ内のファイルである必要はありません。
1. 次のいずれかの方法でChatを開きます。
   - 上部のメニューバーで、**Extensions**をクリックし、**Open Duo Chat**を選択します。
   - エディタで開いているファイルで、コードを選択します。
     1. 右クリックして、**GitLab Duo Chat**を選択します。
     1. **Explain selected code**または**Generate Tests**を選択します。
1. メッセージボックスに質問を入力し、**Enter**キーを押すか、**送信**を選択します。

エディタでコードを選択している場合、この選択は質問とともにAIに送信されます。これにより、このコード選択に関する質問をできるようになります。たとえば、`Could you refactor this?`などです。

## JetBrains IDEでGitLab Duo Chatを使用する

{{< history >}}

- GitLab 16.11で一般提供として導入。

{{< /history >}}

前提条件:

- [JetBrains IDE用GitLabプラグインのインストールと設定](../../editor_extensions/jetbrains_ide/setup.md)が完了している。

JetBrains IDE用GitLabプラグインでGitLab Duo Chatを使用するには、以下の手順に従います。

1. JetBrains IDEで、プロジェクトを開きます。
1. チャットウィンドウまたはエディタウィンドウでGitLab Duo Chatを開きます。

### チャットウィンドウ内

チャットウィンドウでGitLab Duo Chatを開くには、次のいずれかの方法を使用します。

- 右側のツールウィンドウバーで、**GitLab Duo Chat**を選択します。
- 次のキーボードショートカットを押します。
  - MacOSの場合: <kbd>Option</kbd> + <kbd>d</kbd>
  - WindowsまたはLinuxの場合: <kbd>ALT</kbd> + <kbd>d</kbd>
- エディタで開いているファイルで、次を行います。
  1. （オプション）コードを選択します。
  1. 右クリックして、**GitLab Duo Chat**を選択します。
  1. **Open Chat Window**を選択します。
  1. **Explain Code**、**Generate Tests**、または **リファクタコード**を選択します。
- **設定**の**Keymap**で、各アクションのキーボードまたはマウスショートカットを追加します。

GitLab Duo Chatを開いた後に、次を実行します。

1. メッセージボックスに質問を入力します。次のようにテキストを入力すると、使用可能なコマンドが表示されます。
   - `/`と入力して、使用可能なすべてのコマンドを表示します。
   - `/re` を入力して、`/refactor` および `/reset` を表示します。
1. 質問を送信するには、**Enter**を押すか、**送信**を選択します。
1. 応答のコードブロック内のボタンを使用して、操作します。

### エディタビューのGitLab Duo Quick Chat内

{{< history >}}

- [JetBrains用GitLab Duoプラグイン3.0.0](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/80)および[VS Code用GitLabワークフロー拡張機能5.14.0](https://gitlab.com/groups/gitlab-org/-/epics/15218)で、一般提供として導入。

{{< /history >}}

エディタウィンドウでGitLab Duo Chat Quick Chatを開くには、次のいずれかの方法を使用します。

- 次のキーボードショートカットを押します。
  - MacOSの場合: <kbd>Option</kbd> + <kbd>c</kbd>
  - WindowsまたはLinuxの場合: <kbd>ALT</kbd> + <kbd>c</kbd>
- IDEで現在開いているファイルで、コードを選択し、フローティングツールバーで**GitLab Duo Quick Chat**({{< icon name="tanuki-ai" >}})を選択します。
- 右クリックし、**GitLab Duo Chat > Quick Chat を開く**を選択します。

Quick Chatを開いたら、次の手順を実行します。

1. メッセージボックスに質問を入力します。次のようにテキストを入力すると、使用可能なコマンドが表示されます。
   - `/`と入力して、使用可能なすべてのコマンドを表示します。
   - `/re` を入力して、`/refactor` および `/reset` を表示します。
1. 質問を送信するには、**Enter**を押します。
1. 応答のコードブロックの周りのボタンを使用して、操作します。
1. チャットを終了するには、**Escape to close**を選択するか、チャットにフォーカスがある状態で**Escape**を押します。

<div class="video-fallback">
  <a href="https://youtu.be/5JbAM5g2VbQ">GitLab Duo Quick Chatの使用方法を見る</a>。
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/5JbAM5g2VbQ?si=pm7bTRDCR5we_1IX" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2024-10-15 -->

## デモを見てヒントを得る

<div class="video-fallback">
  <a href="https://youtu.be/l6vsd1HMaYA?si=etXpFbj1cBvWyj3_">GitLab Duo Chat の設定方法と使用方法については、こちらからご覧ください</a>。
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/l6vsd1HMaYA?si=etXpFbj1cBvWyj3_" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2023-11-10 -->

GitLab Duo ChatをAI搭載のDevSecOpsワークフローに統合する際のヒントとコツについては、[AI搭載のGitLab Duo Chatを使用するための10のベストプラクティス](https://about.gitlab.com/blog/2024/04/02/10-best-practices-for-using-ai-powered-gitlab-duo-chat/)をご覧ください。

[GitLab Duo Chatの使用方法の例は、こちらからご覧いただけます](examples.md)。

## フィードバックを提供する

GitLab Duo Chatのエクスペリエンスを継続的に強化する上で、皆様からのフィードバックが重要です。フィードバックをお寄せいただくことで、お客様のニーズに合わせてチャットをカスタマイズしたり、すべての方のパフォーマンスを向上させたりできます。

特定の応答に関するフィードバックをお寄せいただくには、応答メッセージのフィードバックボタンを使用してください。または、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/430124)にコメントを追加することもできます。
