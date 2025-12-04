---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chatに質問する
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Duo Chatは以下をサポートします:

- コード、エラー、GitLab機能の説明を入手できます。
- コードの生成やリファクタリング、テストの作成、問題の修正を行います。
- CI/CD設定の作成、ジョブ失敗のトラブルシューティングを行います。
- イシュー、エピック、およびマージリクエストを要約します。
- セキュリティ脆弱性を解決します。

次の例では、Duo Chatの機能について詳しく説明します。

その他の実践的な例については、[GitLab Duoのユースケース](../gitlab_duo/use_cases.md)を参照してください。

{{< alert type="note" >}}

[スラッシュコマンド](#gitlab-duo-chat-slash-commands)を含むこのページの質問例は、意図的に一般的なものになっています。現在の目標に特化した質問をすることで、Chatからより有用な回答を得られる場合があります。例「`clean_missing_data`の`data_cleaning.py`関数は、どの行を削除するかをどのように決定しますか？」。

{{< /alert >}}

## GitLabについて質問する {#ask-about-gitlab}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI、Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 16.0でGitLab.com向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117695)されました。
- GitLab Self-Managedでドキュメント関連の質問をする機能は、`ai_gateway_docs_search`[フラグ](../../administration/feature_flags/_index.md)とともに、GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/451215)されました。デフォルトでは有効になっています。
- GitLab 17.1で[一般提供になり、機能フラグは削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154876)されました。
- GitLab 17.6で、GitLab Duoアドオンが必須となりました。
- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 18.0でGitLab Duo Coreアドオンを含むように変更されました。

{{< /history >}}

GitLabの動作方法について質問できます。例:

- `Explain the concept of a 'fork' in a concise manner.`
- `Provide step-by-step instructions on how to reset a user's password.`

GitLab Duo Chatは、[GitLabリポジトリ](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc)のGitLabドキュメントをソースとして使用します。

Chatをドキュメントで最新の状態に保つために、ナレッジベースは毎日更新されます。

- GitLab.comでは、ドキュメントの最新バージョンが使用されます。
- GitLab Self-ManagedおよびGitLab Dedicatedでは、インスタンスのバージョンに対応するドキュメントが使用されます。

## 特定のイシューについて質問する {#ask-about-a-specific-issue}

{{< details >}}

- アドオン: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI、Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 16.0でGitLab.com向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235)されました。
- GitLab 16.8でGitLab Self-ManagedおよびGitLab Dedicated向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235)されました。
- GitLab 17.6で、GitLab Duoアドオンが必須となりました。
- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

特定のGitLabイシューについて質問できます。例: 

- `Generate a summary for the issue identified via this link: <link to your issue>`
- GitLabでイシューを表示しているときに、`Generate a concise summary of the current issue.`と尋ねることができます
- `How can I improve the description of <link to your issue> so that readers understand the value and problems to be solved?`

{{< alert type="note" >}}

イシューに大量のテキスト（40,000語以上）が含まれている場合、GitLab Duo Chatはすべての単語を考慮できない場合があります。AIモデルには、一度に処理できる入力量に制限があります。

{{< /alert >}}

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>GitLab Duo Chatでイシューとエピックの生産性を向上させる方法のヒントについては、[GitLab Duo Chatで生産性を向上させる](https://youtu.be/RJezT5_V6dI)を参照してください。
<!-- Video published on 2024-04-17 -->

## 特定エピックについて質問する {#ask-about-a-specific-epic}

{{< details >}}

- アドオン: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI、Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 16.3でGitLab.com向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128487)されました。
- GitLab 16.8でGitLab Self-ManagedおよびGitLab Dedicated向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128487)されました。
- GitLab 17.6で、GitLab Duoアドオンが必須となりました。
- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

特定のGitLabエピックについて質問できます。例: 

- `Generate a summary for the epic identified via this link: <link to your epic>`
- GitLabでエピックを表示しているときに、`Generate a concise summary of the opened epic.`と尋ねることができます
- `What are the unique use cases raised by commenters in <link to your epic>?`

{{< alert type="note" >}}

エピックに大量のテキスト（40,000語以上）が含まれている場合、GitLab Duo Chatはすべての単語を考慮できない場合があります。AIモデルには、一度に処理できる入力量に制限があります。

{{< /alert >}}

## 特定のマージリクエストについて質問する {#ask-about-a-specific-merge-request}

{{< details >}}

- アドオン: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/464587)されました。
- GitLab 17.6で、GitLab Duoアドオンが必須となりました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

表示中のマージリクエストについてGitLabに質問できます。質問できる内容は次のとおりです:

- タイトルまたは説明。
- コメントとスレッド。
- **変更**タブの内容。
- ラベル、ソースブランチ、作成者、マイルストーンなどのメタデータ。

マージリクエストでChatを開き、質問を入力します。例: 

- `Why was the .vue file changed?`
- `What do the reviewers say about this merge request?`
- `How can this merge request be improved?`
- `Which files and changes should I review first?`

## 特定のコミットについて質問する {#ask-about-a-specific-commit}

{{< details >}}

- アドオン: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/468460)されました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

特定のGitLabコミットについて質問できます。例: 

- `Generate a summary for the commit identified with this link: <link to your commit>`
- `How can I improve the description of this commit?`
- GitLabでコミットを表示しているときに、`Generate a summary of the current commit.`と尋ねることができます

## 特定のパイプラインジョブについて質問する {#ask-about-a-specific-pipeline-job}

{{< details >}}

- アドオン: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/468461)されました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

特定のGitLabパイプラインジョブについて質問できます。例: 

- `Generate a summary for the pipeline job identified via this link: <link to your pipeline job>`
- `Can you suggest ways to fix this failed pipeline job?`
- `What are the main steps executed in this pipeline job?`
- GitLabでパイプラインジョブを表示しているときに、`Generate a summary of the current pipeline job.`と尋ねることができます

## 特定の作業アイテムについて質問する {#ask-about-a-specific-work-item}

{{< details >}}

- アドオン: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI、Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194302)されました。

{{< /history >}}

特定のGitLab作業アイテムについて質問できます。例: 

- `Generate a summary for the work item identified via this link: <link to your work item>`
- GitLabで作業アイテムを表示しているときに、`Generate a concise summary of the current work item.`と尋ねることができます
- `How can I improve the description of <link to your work item> so that readers understand the value and problems to be solved?`

{{< alert type="note" >}}

作業アイテムに大量のテキスト（40,000語以上）が含まれている場合、GitLab Duo Chatはすべての単語を考慮できない場合があります。AIモデルには、一度に処理できる入力量に制限があります。

{{< /alert >}}

## 選択したコードについて説明する {#explain-selected-code}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI、Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 16.7でGitLab.com向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 16.8でGitLab Self-ManagedおよびGitLab Dedicated向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 17.6で、GitLab Duoアドオンが必須となりました。
- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 18.0でGitLab Duo Coreアドオンを含むように変更されました。

{{< /history >}}

GitLab Duo Chatに、選択したコードの説明を依頼できます:

1. IDEでコードを選択します。
1. Duo Chatで、`/explain`と入力します。

   ![コードを選択し、/explainスラッシュコマンドを使用して説明するようにGitLab Duo Chatに依頼する。](img/code_selection_duo_chat_v17_4.png)

考慮すべき追加の指示を含めることもできます。例: 

- `/explain the performance`
- `/explain focus on the algorithm`
- `/explain the performance gains or losses using this code`
- `/explain the object inheritance`（クラス、オブジェクト指向）
- `/explain why a static variable is used here`（C++）
- `/explain how this function would cause a segmentation fault`（C）
- `/explain how concurrency works in this context`（Go）
- `/explain how the request reaches the client`（REST API、データベース）

詳細については、以下を参照してください:

- [VS CodeでGitLab Duo Chatを使用する](_index.md#use-gitlab-duo-chat-in-vs-code)。
- <i class="fa-youtube-play" aria-hidden="true"></i> [Application modernization with GitLab Duo (C++ to Java)](https://youtu.be/FjoAmt5eeXA?si=SLv9Mv8eSUAVwW5Z)。
  <!-- Video published on 2025-03-18 -->

GitLab UIでは、以下でもコードを説明できます:

- [ファイル](../project/repository/code_explain.md)。
- [マージリクエスト](../project/merge_requests/changes.md#explain-code-in-a-merge-request)。

## コードについて質問または生成する {#ask-about-or-generate-code}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise。

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI、Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 16.1でGitLab.com向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235)されました。
- GitLab 16.8でGitLab Self-ManagedおよびGitLab Dedicated向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235)されました。
- GitLab 17.6で、GitLab Duoアドオンが必須となりました。
- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 18.0でGitLab Duo Coreアドオンを含むように変更されました。

{{< /history >}}

GitLab Duo Chatのウィンドウにコードを貼り付けて、コードに関する質問ができます。例: 

```plaintext
Provide a clear explanation of this Ruby code: def sum(a, b) a + b end.
Describe what this code does and how it works.
```

Chatにコードの生成を依頼することもできます。例: 

- `Write a Ruby function that prints 'Hello, World!' when called.`
- `Develop a JavaScript program that simulates a two-player Tic-Tac-Toe game. Provide both game logic and user interface, if applicable.`
- `Create a regular expression for parsing IPv4 and IPv6 addresses in Python.`
- `Generate code for parsing a syslog log file in Java. Use regular expressions when possible, and store the results in a hash map.`
- `Create a product-consumer example with threads and shared memory in C++. Use atomic locks when possible.`
- `Generate Rust code for high performance gRPC calls. Provide a source code example for a server and client.`

## フォローアップの質問をする {#ask-follow-up-questions}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise。

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI、Web IDE、VS Code、JetBrains IDE
- GitLab Self-Managed、GitLab DedicatedのLLM: Anthropic [Claude 3.5 Sonnet V2](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet-v2)
- GitLab.comのLLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 18.0でGitLab Duo Coreアドオンを含むように変更されました。

{{< /history >}}

フォローアップの質問をして、トピックやタスクをより深く掘り下げることができます。これにより、さらなる明確化、詳細化、または追加の支援が必要な場合でも、特定のニーズに合わせて調整された、より詳細かつ正確な回答を得ることができます。

質問`Write a Ruby function that prints 'Hello, World!' when called`へのフォローアップは次のようになります:

- `Can you also explain how I can call and execute this Ruby function in a typical Ruby environment, such as the command line?`

質問`How to start a C# project?`へのフォローアップは次のようになります:

- `Can you also explain how to add a .gitignore and .gitlab-ci.yml file for C#?`

## エラーについて質問する {#ask-about-errors}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise。

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI、Web IDE、VS Code、JetBrains IDE
- GitLab Self-Managed、GitLab DedicatedのLLM: Anthropic [Claude 3.5 Sonnet V2](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet-v2)
- GitLab.comのLLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 18.0でGitLab Duo Coreアドオンを含むように変更されました。

{{< /history >}}

ソースコードのコンパイルを必要とするプログラミング言語は、わかりにくいエラーメッセージをスローする場合があります。同様に、スクリプトまたはWebアプリケーションはスタックトレースをスローする可能性があります。コピーしたエラーメッセージの前に、たとえば`Explain this error message:`のようなプレフィックスを付けて、GitLab Duo Chatに質問できます。プログラミング言語などの具体的なコンテキストを追加します。

- `Explain this error message in Java: Int and system cannot be resolved to a type`
- `Explain when this C function would cause a segmentation fault: sqlite3_prepare_v2()`
- `Explain what would cause this error in Python: ValueError: invalid literal for int()`
- `Why is "this" undefined in VueJS? Provide common error cases, and explain how to avoid them.`
- `How to debug a Ruby on Rails stacktrace? Share common strategies and an example exception.`

## IDE内の特定のファイルについて質問する {#ask-about-specific-files-in-the-ide}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise。

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 17.7で`duo_additional_context`および`duo_include_context_file`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/477258)されました。デフォルトでは無効になっています。
- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 17.9の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/groups/gitlab-org/-/epics/15183)になりました。
- GitLab 18.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188613)になりました。すべての機能フラグが削除されました。
- GitLab 18.0でGitLab Duo Coreアドオンを含むように変更されました。

{{< /history >}}

`/include`と入力してファイルを選択することで、VS CodeまたはJetBrains IDEでDuo Chatの会話にリポジトリファイルを追加します。

前提要件: 

- ファイルはリポジトリの一部である必要があります。
- ファイルはテキストベースである必要があります。PDFや画像のようなバイナリファイルはサポートされていません。

手順:

1. IDEのGitLab Duo Chatで`/include`と入力します。
1. ファイルを追加するには、次のいずれかを実行します:
   - リストからファイルを選択します。
   - ファイルパスを入力します。

たとえば、eコマースアプリを開発している場合は、`cart_service.py`ファイルと`checkout_flow.js`ファイルをChatのコンテキストに追加して、次のように質問できます:

- `How does checkout_flow.js interact with cart_service.py? Generate a sequence diagram using Mermaid.`
- `Can you extend the checkout process by showing products related to the ones in the user's cart? I want to move the checkout logic to the backend before proceeding. Generate the Python backend code and change the frontend code to work with the new backend.`

{{< alert type="note" >}}

[Quick Chat](_index.md#in-an-editor-window)を使用して、ファイルを追加したり、Chatのコンテキストに追加したファイルについて質問したりすることはできません。

{{< /alert >}}

## IDEでコードをリファクタリングする {#refactor-code-in-the-ide}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 16.7でGitLab.com向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 16.8でGitLab Self-ManagedおよびGitLab Dedicated向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 17.6で、GitLab Duoアドオンが必須となりました。
- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 18.0でGitLab Duo Coreアドオンを含むように変更されました。

{{< /history >}}

GitLab Duo Chatに、選択したコードのリファクタリングを依頼できます:

1. IDEでコードを選択します。
1. Duo Chatで、`/refactor`と入力します。

考慮すべき追加の指示を含めることができます。例: 

- 特定のコードパターンを使用します。例: `/refactor with ActiveRecord`、`/refactor into a class providing static functions`。
- 特定のライブラリを使用します。例: `/refactor using mysql`。
- 特定の関数/アルゴリズムを使用します。例: C++で`/refactor into a stringstream with multiple lines`。
- 別のプログラミング言語にリファクタリングします。例: `/refactor to TypeScript`。
- パフォーマンスに焦点を当てます。例: `/refactor improving performance`。
- 潜在的な脆弱性に焦点を当てます。例: `/refactor avoiding memory leaks and exploits`。

`/refactor`は、[Repository X-Ray](../project/repository/code_suggestions/repository_xray.md)を使用して、より正確なコンテキスト認識型の提案を提供します。

詳細については、以下を参照してください:

- <i class="fa-youtube-play" aria-hidden="true"></i> [Application modernization with GitLab Duo (C++ to Java)](https://youtu.be/FjoAmt5eeXA?si=SLv9Mv8eSUAVwW5Z)。
  <!-- Video published on 2025-03-18 -->
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [概要を見る](https://youtu.be/oxziu7_mWVk?si=fS2JUO-8doARS169)

## IDEでコードを修正する {#fix-code-in-the-ide}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 17.3でGitLab.com、GitLab Self-Managed、GitLab Dedicated向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 17.6で、GitLab Duoアドオンが必須となりました。
- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 18.0でGitLab Duo Coreアドオンを含むように変更されました。

{{< /history >}}

GitLab Duo Chatに、選択したコードの修正を依頼できます:

1. IDEでコードを選択します。
1. Duo Chatで、`/fix`と入力します。

考慮すべき追加の指示を含めることができます。例: 

- 文法とタイプミスに焦点を当てます。例: `/fix grammar mistakes and typos`。
- 具体的なアルゴリズムまたは問題の説明に焦点を当てます。例: `/fix duplicate database inserts`、`/fix race conditions`。
- 直接表示されない潜在的なバグに焦点を当てます。例: `/fix potential bugs`。
- コードのパフォーマンスの問題に焦点を当てます。例: `/fix performance problems`。
- コードがコンパイルされない場合のビルドの修正に焦点を当てます。例: `/fix the build`。

`/fix`は、[Repository X-Ray](../project/repository/code_suggestions/repository_xray.md)を使用して、より正確なコンテキスト認識型の提案を提供します。

## IDEでテストを作成する {#write-tests-in-the-ide}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 16.7でGitLab.com向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 16.8でGitLab Self-ManagedおよびGitLab Dedicated向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 17.6で、GitLab Duoアドオンが必須となりました。
- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 18.0でGitLab Duo Coreアドオンを含むように変更されました。

{{< /history >}}

GitLab Duo Chatに、選択したコードのテストを作成するよう依頼できます:

1. IDEでコードを選択します。
1. Duo Chatで、`/tests`と入力します。

考慮すべき追加の指示を含めることができます。例: 

- 特定のテストケースフレームワークを使用します。例: `/tests using the Boost.test framework`（C ++）、`/tests using Jest`（JavaScript）。
- 極端なテストケースに焦点を当てます。例: `/tests focus on extreme cases, force regression testing`。
- パフォーマンスに焦点を当てます。例: `/tests focus on performance`。
- リグレッションと潜在的なエクスプロイトに焦点を当てます。例: `/tests focus on regressions and potential exploits`。

`/tests`は、[Repository X-Ray](../project/repository/code_suggestions/repository_xray.md)を使用して、より正確なコンテキスト認識型の提案を提供します。

詳細については、[VS CodeでGitLab Duo Chatを使用する](_index.md#use-gitlab-duo-chat-in-vs-code)を参照してください。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [概要を見る](https://www.youtube.com/watch?v=zWhwuixUkYU)

## CI/CDについて質問する {#ask-about-cicd}

{{< details >}}

- アドオン: GitLab Duo ProまたはEnterprise

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI、Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 16.7でGitLab.com向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423524)されました。
- GitLab 16.8でGitLab Self-ManagedおよびGitLab Dedicated向けに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423524)されました。
- GitLab 17.2で、Claude 2.1からClaude 3 Sonnetへ[LLMを更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149619)しました。
- GitLab 17.2で、Claude 3 SonnetからClaude 3.5 Sonnetへ[LLMを更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157696)しました。
- GitLab 17.6で、GitLab Duoアドオンが必須となりました。
- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 17.10で、Claude 3.5 SonnetからClaude 4.0 Sonnetへ[LLMを更新](https://gitlab.com/gitlab-org/gitlab/-/issues/521034)しました。

{{< /history >}}

GitLab Duo ChatにCI/CD設定の作成を依頼できます:

- `Create a .gitlab-ci.yml configuration file for testing and building a Ruby on Rails application in a GitLab CI/CD pipeline.`
- `Create a CI/CD configuration for building and linting a Python application.`
- `Create a CI/CD configuration to build and test Rust code.`
- `Create a CI/CD configuration for C++. Use gcc as compiler, and cmake as build tool.`
- `Create a CI/CD configuration for VueJS. Use npm, and add SAST security scanning.`
- `Generate a security scanning pipeline configuration, optimized for Java.`

エラーメッセージをコピーして貼り付け、`Explain this CI/CD job error message, in the context of <language>:`のようにプレフィックスを付けることで、特定のジョブエラーの説明を依頼することもできます:

- `Explain this CI/CD job error message in the context of a Go project: build.sh: line 14: go command not found`

または、GitLab Duo根本原因分析を使用して、[失敗したCI/CDジョブのトラブルシューティングを行う](#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)こともできます。

## 根本原因分析を使用して失敗したCI/CDジョブのトラブルシューティングを行う {#troubleshoot-failed-cicd-jobs-with-root-cause-analysis}

{{< details >}}

- アドオン: GitLab Duo Enterprise、GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 16.2のGitLab.comで[実験的機能](../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123692)されました。
- GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/441681)となり、GitLab Duo Chatに移動しました。
- GitLab 17.6で、GitLab Duoアドオンが必須となりました。
- マージリクエストの失敗したジョブウィジェットは、GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174586)されました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

GitLab Duo ChatでGitLab Duo根本原因分析を使用して、CI/CDジョブの失敗を迅速に特定して修正できます。ジョブログの最後の100,000文字を分析して失敗の原因を特定し、修正例を提供します。

この機能には、マージリクエストの**パイプライン**タブから、またはジョブログから直接アクセスできます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [概要を見る](https://www.youtube.com/watch?v=MLjhVbMjFAY&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

根本原因分析は、以下をサポートしていません:

- トリガージョブ
- ダウンストリームパイプライン

[エピック13872](https://gitlab.com/groups/gitlab-org/-/epics/13872)で、この機能に関するフィードバックをお寄せください。

前提要件: 

- CI/CDジョブを表示する権限が必要です。
- 有料のGitLab Duo Enterpriseシートが必要です。

### マージリクエストから {#from-a-merge-request}

マージリクエストから失敗したCI/CDジョブのトラブルシューティングを行うには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. マージリクエストに移動します。
1. **パイプライン**タブを選択します。
1. 失敗したジョブウィジェットから、次のいずれかを行います:
   - ジョブIDを選択してジョブログに移動します。
   - **トラブルシューティングを行う**を選択して、失敗を直接分析します。

### ジョブログから {#from-the-job-log}

ジョブログから失敗したCI/CDジョブのトラブルシューティングを行うには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **ジョブ**を選択します。
1. 失敗したCI/CDジョブを選択します。
1. ジョブログの下で、次のいずれかを行います:
   - **トラブルシューティングを行う**を選択します。
   - GitLab Duo Chatを開き、`/troubleshoot`と入力します。

## 脆弱性について説明する {#explain-a-vulnerability}

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo Enterprise、GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="エディタとモデルの情報" >}}

- エディタ: GitLab UI
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6で、GitLab Duoアドオンが必須となりました。

{{< /history >}}

SAST脆弱性レポートを表示しているときに、GitLab Duo Chatに脆弱性について説明するように依頼できます。

詳細については、[脆弱性の説明](../application_security/vulnerabilities/_index.md#vulnerability-explanation)を参照してください。

## 新しい会話を作成する {#create-a-new-conversation}

{{< details >}}

- アドオン: GitLab Duo ProまたはEnterprise
- 提供形態: GitLab.com
- エディタ: GitLab UI

{{< /details >}}

{{< history >}}

- GitLab 17.10で`duo_chat_multi_thread`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/16108)されました。デフォルトでは無効になっています。
- GitLab 18.1で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190042)になりました。機能フラグ`duo_chat_multi_thread`は削除されました。

{{< /history >}}

GitLab 17.10以降では、Chatと複数の同時会話を行うことができます。

- Chatドロワーの左上隅で、**新しいチャット**を選択します。
- テキストボックスに`/new`と入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

## 会話を削除または新しい会話を開始する {#delete-or-start-a-new-conversation}

会話を削除するには、[チャット履歴](_index.md#delete-a-conversation)を使用します。

チャットウィンドウをクリアして同じ会話スレッドで新しい会話を開始するには、`/reset`と入力し、**送信**を選択します。

どちらの場合も、新しい質問をするときに会話履歴は考慮されません。コンテキストを切り替えるときに新しい会話を開始すると、Duo Chatが無関係な会話によって混乱することがないため、回答の改善に役立つ場合があります。

## GitLab Duo Chatスラッシュコマンド {#gitlab-duo-chat-slash-commands}

Duo Chatには、ユニバーサル、GitLab UI、IDEコマンドのリストがあり、それぞれの前にスラッシュ（`/`）が付きます。

コマンドを使用すると、特定のタスクをすばやく実行できます。

### ユニバーサル {#universal}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- エディタ: GitLab UI、Web IDE、VS Code、JetBrains IDE

{{< /details >}}

{{< history >}}

- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 18.0でGitLab Duo Coreアドオンを含むように変更されました。

{{< /history >}}

| コマンド | 目的                                                                                                                       |
|---------|-------------------------------------------------------------------------------------------------------------------------------|
| /new    | [新しい会話を開始するが、以前の会話はチャットの履歴に保持する](#delete-or-start-a-new-conversation)      |
| /reset  | [チャットウィンドウをクリアして、会話をリセットする](#delete-or-start-a-new-conversation)                                       |
| /help   | Duo Chatの動作について詳しく学ぶ                                                                                           |

{{< alert type="note" >}}

GitLab.comでは、GitLab 17.10 以降、[複数の会話](_index.md#have-multiple-conversations)を行っている場合、`/clear`および`/reset`スラッシュコマンドは[`/new`スラッシュコマンド](#gitlab-ui)に置き換えられます。

{{< /alert >}}

### GitLab UI {#gitlab-ui}

{{< details >}}

- アドオン: GitLab Duo Enterprise
- エディタ: GitLab UI

{{< /details >}}

{{< history >}}

- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

これらのコマンドは動的であり、Duo Chat使用時にGitLab UIでのみ使用できます:

| コマンド                | 目的                                                                                                            | エリア |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------ | ---- |
| /summarize_comments    | 現在のイシューに関するすべてのコメントの要約を生成する                                                            | イシュー |
| /troubleshoot          | [根本原因分析を使用して失敗したCI/CDジョブのトラブルシューティングを行う](#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | ジョブ |
| /vulnerability_explain | [現在の脆弱性について説明する](../application_security/vulnerabilities/_index.md#vulnerability-explanation)      | 脆弱性 |

### IDE {#ide}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- エディタ: Web IDE、VS Code、JetBrains IDE

{{< /details >}}

{{< history >}}

- GitLab 17.9で、[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)になりました。
- GitLab 18.0でGitLab Duo Coreアドオンを含むように変更されました。

{{< /history >}}

これらのコマンドは、サポートされているIDEでDuo Chatを使用する場合にのみ機能します:

| コマンド   | 目的                                           |
|-----------|---------------------------------------------------|
| /tests    | [テストケースを作成する](#write-tests-in-the-ide)            |
| /explain  | [コードを説明する](#explain-selected-code)            |
| /refactor | [コード](#refactor-code-in-the-ide)をリファクタリングする    |
| /fix      | [コードを修正する](#fix-code-in-the-ide)              |
| /include  | [ファイルのコンテキストを含める](#ask-about-specific-files-in-the-ide) |
