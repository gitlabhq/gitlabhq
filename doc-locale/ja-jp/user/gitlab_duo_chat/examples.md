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

GitLab Duoチャットは、次のことに役立ちます。:

- コード、エラー、およびGitLabの機能の説明を入手できます。
- コードをリファクタリング、テストの作成、およびバグの修正を行います。
- CI/CD設定を作成し、ジョブの失敗の問題を解決する。
- イシュー、エピック、およびマージリクエストを要約します。
- セキュリティ脆弱性を解決する。

次の例では、Duoチャットの機能について詳しく説明します。

その他の実践的な例については、[GitLab Duoユースケース](../gitlab_duo/use_cases.md)を参照してください。

{{< alert type="note" >}}

[スラッシュコマンド](#gitlab-duo-chat-slash-commands)を含む、このページの質問例は意図的に一般的なものです。現在の目標に特有の質問をすることで、チャットからより役立つ回答を得られる場合があります。たとえば、`clean_missing_data`の`data_cleaning.py`関数は、どの行を削除するかをどのように決定しますか？

{{< /alert >}}

## GitLabについて {#ask-about-gitlab}

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI、Web統合開発環境、VS Code、およびJetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 16.0で[GitLab.com向けに導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117695)されました。
- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/451215) GitLab 17.0のGitLabセルフマネージドでドキュメント関連の質問をする機能（[フラグ付き](../../administration/feature_flags/_index.md)名前付き`ai_gateway_docs_search`）。デフォルトでは有効になっています。
- GitLab 17.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154876)になり、機能フラグは削除されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)。
- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。

{{< /history >}}

GitLabの仕組みについて質問できます。次に例を示します。:

- `Explain the concept of a 'fork' in a concise manner.`
- `Provide step-by-step instructions on how to reset a user's password.`

GitLab Duoチャットは、[GitLabリポジトリ](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc)のGitLabドキュメントをソースとして使用します。

チャットをドキュメントで最新の状態に保つために、ナレッジベースは毎日更新されます。

- GitLab.comでは、ドキュメントの最新バージョンが使用されます。
- GitLabセルフマネージドおよびGitLab Dedicatedでは、インスタンスのバージョンのドキュメントが使用されます。

## 特定イシューについて質問する {#ask-about-a-specific-issue}

{{< details >}}

- アドオン: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI、Web統合開発環境、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 16.0で[GitLab.com向けに導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235)されました。
- GitLab 16.8で[GitLab Self-ManagedおよびGitLab Dedicated向けに導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235)されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

特定のGitLabイシューについて質問できます。次に例を示します: 

- `Generate a summary for the issue identified via this link: <link to your issue>`
- GitLabでイシューを表示しているときに、`Generate a concise summary of the current issue.`を尋ねることができます
- `How can I improve the description of <link to your issue> so that readers understand the value and problems to be solved?`

{{< alert type="note" >}}

イシューに大量のテキスト（40,000語以上）が含まれている場合、GitLab Duoチャットはすべての単語を考慮できない場合があります。AIモデルには、一度に処理できる入力の量に制限があります。

{{< /alert >}}

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> GitLab Duoチャットでイシューとエピックの生産性を向上させる方法のヒントについては、[GitLab Duoチャットで生産性を向上させる](https://youtu.be/RJezT5_V6dI)を参照してください。
<!-- Video published on 2024-04-17 -->

## 特定エピックについて質問する {#ask-about-a-specific-epic}

{{< details >}}

- アドオン: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI、Web統合開発環境、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 16.3で[GitLab.com向けに導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128487)されました。
- GitLab 16.8で[GitLab Self-ManagedおよびGitLab Dedicated向けに導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128487)されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

特定のGitLabエピックについて質問できます。次に例を示します: 

- `Generate a summary for the epic identified via this link: <link to your epic>`
- GitLabでエピックを表示しているときに、`Generate a concise summary of the opened epic.`を尋ねることができます
- `What are the unique use cases raised by commenters in <link to your epic>?`

{{< alert type="note" >}}

エピックに大量のテキスト（40,000語以上）が含まれている場合、GitLab Duoチャットはすべての単語を考慮できない場合があります。AIモデルには、一度に処理できる入力の量に制限があります。

{{< /alert >}}

## 特定のマージリクエストについて質問する {#ask-about-a-specific-merge-request}

{{< details >}}

- アドオン: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 17.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/464587)されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

表示しているマージリクエストについてGitLabに質問できます。質問できる内容は次のとおりです。:

- タイトルまたは説明。
- コメントとスレッド。
- **変更**タブのコンテンツ。
- ラベル、ソースブランチ、作成者、マイルストーンなどのメタデータ。

マージリクエストで、チャットを開いて質問を入力します。次に例を示します: 

- `Why was the .vue file changed?`
- `What do the reviewers say about this merge request?`
- `How can this merge request be improved?`
- `Which files and changes should I review first?`

## 特定のコミットについて質問する {#ask-about-a-specific-commit}

{{< details >}}

- アドオン: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/468460)されました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

特定のGitLabコミットについて質問できます。次に例を示します: 

- `Generate a summary for the commit identified with this link: <link to your commit>`
- `How can I improve the description of this commit?`
- GitLabでコミットを表示しているときに、`Generate a summary of the current commit.`を尋ねることができます

## 特定のパイプラインジョブについて質問する {#ask-about-a-specific-pipeline-job}

{{< details >}}

- アドオン: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/468461)されました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

特定のGitLabパイプラインジョブについて質問できます。次に例を示します: 

- `Generate a summary for the pipeline job identified via this link: <link to your pipeline job>`
- `Can you suggest ways to fix this failed pipeline job?`
- `What are the main steps executed in this pipeline job?`
- GitLabでパイプラインジョブを表示しているときに、`Generate a summary of the current pipeline job.`を尋ねることができます

## 特定の作業アイテムについて質問する {#ask-about-a-specific-work-item}

{{< details >}}

- アドオン: GitLab Duo Enterprise

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI、Web統合開発環境、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194302)されました。

{{< /history >}}

特定のGitLab作業アイテムについて質問できます。次に例を示します: 

- `Generate a summary for the work item identified via this link: <link to your work item>`
- GitLabで作業アイテムを表示しているときに、`Generate a concise summary of the current work item.`を尋ねることができます
- `How can I improve the description of <link to your work item> so that readers understand the value and problems to be solved?`

{{< alert type="note" >}}

作業アイテムに大量のテキスト（40,000語以上）が含まれている場合、GitLab Duoチャットはすべての単語を考慮できない場合があります。AIモデルには、一度に処理できる入力の量に制限があります。

{{< /alert >}}

## 選択したコードについて説明する {#explain-selected-code}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI、Web統合開発環境、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon QのLLM: Amazon Q Developer
- [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 16.7で[GitLab.com向けに導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 16.8で[GitLab Self-ManagedおよびGitLab Dedicated向けに導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)。
- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。

{{< /history >}}

GitLab Duoチャットに、選択したコードの説明を依頼できます。:

1. IDEでコードを選択します。
1. Duoチャットで、`/explain`と入力します。

   ![コードを選択し、/explainスラッシュコマンドを使用して説明するようにGitLab Duoチャットに依頼する。](img/code_selection_duo_chat_v17_4.png)

検討される追加の指示を追加することもできます。次に例を示します: 

- `/explain the performance`
- `/explain focus on the algorithm`
- `/explain the performance gains or losses using this code`
- `/explain the object inheritance` (クラス、オブジェクト指向)
- `/explain why a static variable is used here` (C++)
- `/explain how this function would cause a segmentation fault` (C)
- `/explain how concurrency works in this context` (Go)
- `/explain how the request reaches the client` (REST API、データベース)

詳細については、以下を参照してください: 

- [VS CodeでGitLab Duoチャットを使用する](_index.md#use-gitlab-duo-chat-in-vs-code)。
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duoによるアプリケーションのモダナイゼーション（C++からJava）](https://youtu.be/FjoAmt5eeXA?si=SLv9Mv8eSUAVwW5Z)。
  <!-- Video published on 2025-03-18 -->

GitLab UIでは、次のコードについても説明できます。:

- [ファイル](../project/repository/code_explain.md)。
- [マージリクエスト](../project/merge_requests/changes.md#explain-code-in-a-merge-request)。

## コードについて質問または生成する {#ask-about-or-generate-code}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise。

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI、Web統合開発環境、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 16.1で[GitLab.com向けに導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235)されました。
- GitLab 16.8で[GitLab Self-ManagedおよびGitLab Dedicated向けに導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235)されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)。
- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。

{{< /history >}}

コードをチャットウィンドウに貼り付けることで、コードに関するGitLab Duoチャットの質問をすることができます。次に例を示します: 

```plaintext
Provide a clear explanation of this Ruby code: def sum(a, b) a + b end.
Describe what this code does and how it works.
```

チャットにコードの生成を依頼することもできます。次に例を示します: 

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

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI、Web統合開発環境、VS Code、JetBrains IDE
- GitLab Self-Managed、GitLab DedicatedのLLM: Anthropic [Claude 3.5 Sonnet V2](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet-v2)
- GitLab.comのLLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)。
- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。

{{< /history >}}

トピックまたはタスクをより深く掘り下げるために、フォローアップの質問をすることができます。これにより、さらなる明確化、詳細化、または追加の支援が必要な場合でも、特定のニーズに合わせて調整された、より詳細かつ正確な回答を得ることができます。

質問`Write a Ruby function that prints 'Hello, World!' when called`へのフォローアップは次のようになります。:

- `Can you also explain how I can call and execute this Ruby function in a typical Ruby environment, such as the command line?`

質問`How to start a C# project?`へのフォローアップは次のようになります。:

- `Can you also explain how to add a .gitignore and .gitlab-ci.yml file for C#?`

## エラーについて質問する {#ask-about-errors}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise。

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI、Web統合開発環境、VS Code、JetBrains IDE
- GitLab Self-Managed、GitLab DedicatedのLLM: Anthropic [Claude 3.5 Sonnet V2](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet-v2)
- GitLab.comのLLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)。
- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。

{{< /history >}}

ソースコードのコンパイルを必要とするプログラミング言語は、不可解なエラーメッセージをスローする場合があります。同様に、スクリプトまたはWebアプリケーションはスタックトレースをスローする可能性があります。たとえば、`Explain this error message:`を先頭に追加して、コピーしたエラーメッセージをGitLab Duoチャットに尋ねることができます。プログラミング言語のような特定のコンテキストを追加します。

- `Explain this error message in Java: Int and system cannot be resolved to a type`
- `Explain when this C function would cause a segmentation fault: sqlite3_prepare_v2()`
- `Explain what would cause this error in Python: ValueError: invalid literal for int()`
- `Why is "this" undefined in VueJS? Provide common error cases, and explain how to avoid them.`
- `How to debug a Ruby on Rails stacktrace? Share common strategies and an example exception.`

## IDE内の特定のファイルについて質問する {#ask-about-specific-files-in-the-ide}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise。

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/477258)されました（[フラグ](../../administration/feature_flags/_index.md)名は`duo_additional_context`と`duo_include_context_file`）。デフォルトでは無効になっています。
- GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)。
- GitLab 17.9の[GitLab.comおよびGitLab Self-Managedで有効になりました](https://gitlab.com/groups/gitlab-org/-/epics/15183)。
- GitLab 18.0[で一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188613)になりました。すべての機能フラグが削除されました。
- GitLab 18.0にGitLab Duo Coreアドオンを含めるように変更しました。

{{< /history >}}

`/include`と入力してファイルを選択し、VS CodeまたはJetBrains IDEでDuoチャットの会話にリポジトリファイルを追加します。

前提要件: 

- ファイルはリポジトリの一部である必要があります。
- ファイルはテキストベースである必要があります。PDFや画像のようなバイナリファイルはサポートされていません。

これを行うには、次の手順を実行します。:

1. IDEで、GitLab Duoチャットで、`/include`と入力します。
1. ファイルを追加するには、次のいずれかを実行します。:
   - リストからファイルを選択します。
   - ファイルパスを入力します。

たとえば、eコマースアプリを開発している場合は、`cart_service.py`ファイルと`checkout_flow.js`ファイルをチャットのコンテキストに追加して、次のように質問できます。:

- `How does checkout_flow.js interact with cart_service.py? Generate a sequence diagram using Mermaid.`
- `Can you extend the checkout process by showing products related to the ones in the user's cart? I want to move the checkout logic to the backend before proceeding. Generate the Python backend code and change the frontend code to work with the new backend.`

{{< alert type="note" >}}

チャットのコンテキストに追加されたファイルについて、ファイルを追加したり質問したりするために[クイックチャット](_index.md#in-an-editor-window)を使用することはできません。

{{< /alert >}}

## IDEでコードをリファクタリングする {#refactor-code-in-the-ide}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon QのLLM: Amazon Q Developer
- [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 16.7で[GitLab.com向けに導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 16.8で[GitLab Self-ManagedおよびGitLab Dedicated向けに導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)。
- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。

{{< /history >}}

GitLab Duoチャットに、選択したコードのリファクタリングを依頼できます。:

1. IDEでコードを選択します。
1. Duoチャットで、`/refactor`と入力します。

検討される追加の指示を含めることができます。次に例を示します: 

- 特定のコードパターンを使用します。たとえば、`/refactor with ActiveRecord`または`/refactor into a class providing static functions`などです。
- 特定のライブラリを使用します。たとえば、`/refactor using mysql`などです。
- 特定の関数/アルゴリズムを使用します。たとえば、C++の`/refactor into a stringstream with multiple lines`などです。
- 別のプログラミング言語にリファクタリングします。たとえば、`/refactor to TypeScript`などです。
- パフォーマンスに焦点を当てます。たとえば、`/refactor improving performance`などです。
- 潜在的な脆弱性に焦点を当てます。たとえば、`/refactor avoiding memory leaks and exploits`などです。

`/refactor`は、[リポジトリX-Ray](../project/repository/code_suggestions/repository_xray.md)を使用して、より正確なコンテキスト認識型の提案を提供します。

詳細については、以下を参照してください: 

- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duoによるアプリケーションのモダナイゼーション（C++からJava）](https://youtu.be/FjoAmt5eeXA?si=SLv9Mv8eSUAVwW5Z)。
  <!-- Video published on 2025-03-18 -->
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[概要を見る](https://youtu.be/oxziu7_mWVk?si=fS2JUO-8doARS169)

## IDEでコードを修正する {#fix-code-in-the-ide}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon QのLLM: Amazon Q Developer
- [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 17.3で[GitLab.com、GitLab Self-Managed、GitLab Dedicated向けに導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)。
- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。

{{< /history >}}

GitLab Duoチャットに、選択したコードの修正を依頼できます。:

1. IDEでコードを選択します。
1. Duoチャットで、`/fix`と入力します。

検討される追加の指示を含めることができます。次に例を示します: 

- 文法とタイプミスに焦点を当てます。たとえば、`/fix grammar mistakes and typos`などです。
- 具体的なアルゴリズムまたは問題の説明に焦点を当てます。たとえば、`/fix duplicate database inserts`や`/fix race conditions`などです。
- 直接表示されない潜在的なバグに焦点を当てます。たとえば、`/fix potential bugs`などです。
- コードのパフォーマンスの問題に焦点を当てます。たとえば、`/fix performance problems`などです。
- コードがコンパイルされない場合にビルドの修正に焦点を当てます。たとえば、`/fix the build`などです。

`/fix`は、[リポジトリX-Ray](../project/repository/code_suggestions/repository_xray.md)を使用して、より正確なコンテキスト認識型の提案を提供します。

## IDEでテストを作成する {#write-tests-in-the-ide}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon QのLLM: Amazon Q Developer
- [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 16.7で[GitLab.com向けに導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 16.8で[GitLab Self-ManagedおよびGitLab Dedicated向けに導入](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)されました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)と[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)に対して[有効](https://gitlab.com/groups/gitlab-org/-/epics/15227)。
- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。

{{< /history >}}

選択したコードのテストを作成するようにGitLab Duoチャットに依頼できます。:

1. IDEでコードをいくつか選択します。
1. チャットで、`/tests`と入力します。

考慮される追加の指示を含めることができます。次に例を示します: 

- 特定のテストケースフレームワークを使用します（例：`/tests using the Boost.test framework`（C ++）または`/tests using Jest`（JavaScript））。
- 極端なテストケースに焦点を当てます（例： `/tests focus on extreme cases, force regression testing`）。
- パフォーマンスに焦点を当てます（例：`/tests focus on performance`）。
- リグレッションと潜在的なエクスプロイトに焦点を当てます（例： `/tests focus on regressions and potential exploits`）。

`/tests`はより正確なコンテキスト認識型の提案を提供するために、[リポジトリX-Ray](../project/repository/code_suggestions/repository_xray.md)を使用します。

詳細については、[VS CodeでのGitLab Duoチャットの使用](_index.md#use-gitlab-duo-chat-in-vs-code)を参照してください。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>[概要を見る](https://www.youtube.com/watch?v=zWhwuixUkYU)

## CI/CDについて質問する {#ask-about-cicd}

{{< details >}}

- アドオン: GitLab Duo ProまたはEnterprise

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI、Web IDE、VS Code、JetBrains IDE
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)

{{< /collapsible >}}

{{< history >}}

- GitLab 16.7で[GitLab.com向けに導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423524)されました。
- GitLab 16.8で[GitLab Self-ManagedおよびGitLab Dedicated向けに導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423524)されました。
- [LLMを更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149619) GitLab 17.2のClaude 2.1からClaude 3 Sonnetへ。
- [LLMを更新](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/157696) GitLab 17.2のClaude 3 SonnetからClaude 3.5 Sonnetへ。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- [有効](https://gitlab.com/groups/gitlab-org/-/epics/15227) GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) 、および[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)。
- [LLMを更新](https://gitlab.com/gitlab-org/gitlab/-/issues/521034) GitLab 17.10のClaude 3.5 SonnetからClaude 4.0 Sonnetへ。

{{< /history >}}

GitLab DuoチャットにCI/CD設定の作成を依頼できます:

- `Create a .gitlab-ci.yml configuration file for testing and building a Ruby on Rails application in a GitLab CI/CD pipeline.`
- `Create a CI/CD configuration for building and linting a Python application.`
- `Create a CI/CD configuration to build and test Rust code.`
- `Create a CI/CD configuration for C++. Use gcc as compiler, and cmake as build tool.`
- `Create a CI/CD configuration for VueJS. Use npm, and add SAST security scanning.`
- `Generate a security scanning pipeline configuration, optimized for Java.`

特定ジョブエラーの説明を依頼することもできます。エラーメッセージをコピーして貼り付け、`Explain this CI/CD job error message, in the context of <language>:`を先頭に付けます。:

- `Explain this CI/CD job error message in the context of a Go project: build.sh: line 14: go command not found`

または、GitLab Duoチャットの根本原因分析を使用して、[失敗したCI/CDジョブの問題を解決](#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)できます。

## 根本原因分析で失敗したCI/CDジョブのトラブルシューティングを行う {#troubleshoot-failed-cicd-jobs-with-root-cause-analysis}

{{< details >}}

- アドオン: GitLab Duo Enterprise、GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon QのLLM: Amazon Q Developer
- [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123692) GitLab 16.2でGitLab.comの[実験](../../policy/development_stages_support.md#experiment)として導入されました。
- [一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/441681)となり、GitLab 17.3のGitLab Duoチャットに移動しました。
- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。
- マージリクエストの失敗したジョブウィジェットがGitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174586)されました。
- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

GitLab DuoチャットでGitLab Duo根本原因分析を使用すると、CI/CDジョブの失敗を迅速に特定して修正できます。これは、失敗の原因を特定するためにジョブログの最後の100,000文字を分析し、修正例を提供します。

この機能には、マージリクエストの**パイプライン**タブから、またはジョブログから直接アクセスできます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [概要を見る](https://www.youtube.com/watch?v=MLjhVbMjFAY&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

根本原因分析は、以下をサポートしていません:

- トリガージョブ
- ダウンストリームパイプライン

この機能に関するフィードバックは、[エピック13872](https://gitlab.com/groups/gitlab-org/-/epics/13872)でお送りください。

前提要件: 

- CI/CDジョブを表示する権限が必要です。
- 有料のGitLab Duo Enterpriseシートが必要です。

### マージリクエストから {#from-a-merge-request}

マージリクエストから失敗したCI/CDジョブのトラブルシューティングを行うには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. マージリクエストに移動します。
1. **パイプライン**タブを選択します。
1. [失敗したジョブ] ウィジェットから、次のいずれかの操作を行います:
   - ジョブログに移動するには、ジョブIDを選択します。
   - 直接失敗を分析するには、**トラブルシューティングを行う**を選択します。

### ジョブログから {#from-the-job-log}

ジョブログから失敗したCI/CDジョブのトラブルシューティングを行うには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **ジョブ**を選択します。
1. 失敗したCI/CDジョブを選択します。
1. ジョブログの下で、次のいずれかを行います:
   - **トラブルシューティングを行う**を選択します。
   - GitLab Duoチャットを開き、`/troubleshoot`と入力します。

## 脆弱性について説明する {#explain-a-vulnerability}

{{< details >}}

- プラン: Ultimate
- アドオン: GitLab Duo Enterprise、GitLab Duo with Amazon Q

{{< /details >}}

{{< collapsible title="Editor and model information" >}}

- エディタ: GitLab UI
- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Amazon QのLLM: Amazon Q Developer
- [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)で利用可能: はい

{{< /collapsible >}}

{{< history >}}

- GitLab 17.6以降、GitLab Duoアドオンが必須となりました。

{{< /history >}}

SAST脆弱性レポートを表示しているときに、GitLab Duoチャットに脆弱性について説明するように依頼できます。

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

- Chatドロワーの左上隅で、**New Chat**（New Chat）を選択します。
- テキストボックスに`/new`と入力し、<kbd>Enter</kbd>キーを押すか、**送信**を選択します。

## 会話を削除または新規開始する {#delete-or-start-a-new-conversation}

会話を削除するには、[チャットの履歴](_index.md#delete-a-conversation)を使用します。

チャットウィンドウをクリアし、同じ会話スレッドで新しい会話を開始するには、`/reset`と入力し、**送信**を選択します。

どちらの場合も、新しい質問をするときに会話履歴は考慮されません。Duoチャットは無関係な会話に混乱しないため、新しい会話を開始すると、コンテキストを切り替えるときに回答が改善される可能性があります。

## GitLab Duoチャットスラッシュコマンド {#gitlab-duo-chat-slash-commands}

Duoチャットには、ユニバーサル、GitLab UI、およびIDEコマンドのリストがあり、それぞれスラッシュ（`/`）が前に付いています。

コマンドを使用すると、特定のタスクをすばやく実行できます。

### ユニバーサル {#universal}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- エディタ: GitLab UI、Web IDE、VS Code、JetBrains IDE

{{< /details >}}

{{< history >}}

- [有効](https://gitlab.com/groups/gitlab-org/-/epics/15227) GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) 、および[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)。
- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。

{{< /history >}}

| コマンド | 目的                                                                                                                       |
|---------|-------------------------------------------------------------------------------------------------------------------------------|
| /new    | [新しい会話を開始しますが、以前の会話はチャットの履歴に保持します](#delete-or-start-a-new-conversation)      |
| /reset  | [チャットウィンドウをクリアして、会話をリセットします](#delete-or-start-a-new-conversation)                                       |
| /help   | Duoチャットの仕組みについて詳しくは、こちらをご覧ください                                                                                           |

{{< alert type="note" >}}

GitLab.comでは、GitLab 17.10 以降で、[複数の会話](_index.md#have-multiple-conversations)を行っている場合、`/clear`および`/reset`スラッシュコマンドは、[`/new`スラッシュコマンド](#gitlab-ui)に置き換えられます。

{{< /alert >}}

### GitLab UI {#gitlab-ui}

{{< details >}}

- アドオン: GitLab Duo Enterprise
- エディタ: GitLab UI

{{< /details >}}

{{< history >}}

- GitLab 18.0で、Premiumに含まれるようになりました。

{{< /history >}}

これらのコマンドは動的であり、Duoチャットの使用時にGitLab UIでのみ使用できます:

| コマンド                | 目的                                                                                                            | エリア |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------ | ---- |
| /summarize_comments    | 現在のイシューのすべてのコメントの概要を生成します                                                            | イシュー |
| /troubleshoot          | [根本原因分析で失敗したCI/CDジョブのトラブルシューティングを行う](#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | ジョブ |
| /vulnerability_explain | [現在の脆弱性について説明する](../application_security/vulnerabilities/_index.md#vulnerability-explanation)      | 脆弱性 |

### IDE {#ide}

{{< details >}}

- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- エディタ: Web IDE、VS Code、JetBrains IDE

{{< /details >}}

{{< history >}}

- [有効](https://gitlab.com/groups/gitlab-org/-/epics/15227) GitLab 17.9の[セルフホストモデル設定](../../administration/gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms) 、および[デフォルトのGitLab外部AIベンダー設定](../../administration/gitlab_duo_self_hosted/_index.md#gitlabcom-ai-gateway-with-default-gitlab-external-vendor-llms)。
- GitLab 18.0でGitLab Duo Coreを含めるように変更しました。

{{< /history >}}

これらのコマンドは、サポートされているIDEでDuoチャットを使用する場合にのみ機能します:

| コマンド   | 目的                                           |
|-----------|---------------------------------------------------|
| /tests    | [テストケースを作成](#write-tests-in-the-ide)            |
| /explain  | [コードを説明する](#explain-selected-code)            |
| /refactor | [コード](#refactor-code-in-the-ide)をリファクタリングする    |
| /fix      | [コードを修正する](#fix-code-in-the-ide)              |
| /include  | [ファイルのコンテキストを含める](#ask-about-specific-files-in-the-ide) |
