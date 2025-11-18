---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chatのトラブルシューティング
---

GitLab Duo Chatを使用する場合、次の問題が発生する可能性があります。

## **GitLab Duo Chat**ボタンが表示されない {#the-gitlab-duo-chat-button-is-not-displayed}

UIの右上隅にボタンが表示されない場合は、GitLab Duo Chatが[有効になっている](turn_on_off.md)ことを確認してください。

**GitLab Duo Chat**ボタンは、[GitLab Duoの機能が無効になっているグループとプロジェクト](turn_on_off.md)には表示されません。

GitLab Duo Chatを有効にした後、ボタンが表示されるまでに数分かかる場合があります。

これで問題が解決しない場合は、以下のトラブルシューティングドキュメントも確認してください:

- [コード提案](../project/repository/code_suggestions/troubleshooting.md)。
- [VS Code](../../editor_extensions/visual_studio_code/troubleshooting.md)。
- [Microsoft Visual Studio](../../editor_extensions/visual_studio/visual_studio_troubleshooting.md)。
- [JetBrains](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md) IDE。
- [Neovim](../../editor_extensions/neovim/neovim_troubleshooting.md)。
- [Eclipse](../../editor_extensions/eclipse/troubleshooting.md)。
- [トラブルシューティングGitLab Duo](../gitlab_duo/troubleshooting.md)。
- [Troubleshooting GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/troubleshooting.md)。

## `Error M2000` {#error-m2000}

`I'm sorry, I couldn't find any documentation to answer your question. Error code: M2000`というエラーが表示されることがあります。

このエラーは、チャットが質問に答えるための関連ドキュメントを見つけられない場合に発生します。これは、検索クエリが利用可能なドキュメントと一致しない場合、またはドキュメント検索機能に問題がある場合に発生する可能性があります。

質問を絞り込むには、もう一度試すか、[GitLab Duo Chatのベストプラクティスドキュメント](best_practices.md)を参照してください。

## `Error M3002` {#error-m3002}

`I am sorry, I cannot access the information you are asking about. A group or project owner has turned off Duo features in this group or project. Error code: M3002`というエラーが表示されることがあります。

このエラーは、GitLab Duoが[オフ](turn_on_off.md)になっているプロジェクトまたはグループに属する項目について質問した場合に発生します。

GitLab Duoがオンになっていない場合、グループまたはプロジェクト内の項目（イシュー、エピック、マージリクエストなど）に関する情報をGitLab Duo Chatで処理できません。

## `Error M3003` {#error-m3003}

`I'm sorry, I can't generate a response. You might want to try again. You could also be getting this error because the items you're asking about either don't exist, you don't have access to them, or your session has expired. Error code: M3003`というエラーが表示されることがあります。

このエラーは、以下の場合に発生します:

- アクセス権のない項目（イシュー、エピック、マージリクエストなど）、または存在しない項目についてGitLab Duo Chatに質問します。
- セッションがタイムアウトしました。

アクセスできる項目について、もう一度質問してみてください。問題が解決しない場合は、セッションのタイムアウトが原因である可能性があります。GitLab Duo Chatの使用を続行するには、再度サインインしてください。詳細については、[GitLab Duoの可用性の制御](../gitlab_duo/turn_on_off.md)を参照してください。

## `Error M3004` {#error-m3004}

`I'm sorry, I can't generate a response. You do not have access to GitLab Duo Chat. Error code: M3004`というエラーが表示されることがあります。

このエラーは、GitLab Duo Chatにアクセスしようとしたが、必要なアクセス権がない場合に発生します。

[GitLab Duo Chatを使用するためのアクセス権](../gitlab_duo/turn_on_off.md)があることを確認してください。

## `Error M3005` {#error-m3005}

`I'm sorry, this question is not supported in your Duo Pro subscription. You might consider upgrading to Duo Enterprise. Error code: M3005`というエラーが表示されることがあります。

このエラーは、GitLab Duo Chatのツールにアクセスしようとしたが、そのツールがGitLab Duoのサブスクリプションティアにバンドルされていない場合に発生します。

[GitLab Duoのサブスクリプションティア](https://about.gitlab.com/gitlab-duo/#pricing)に、選択したツールが含まれていることを確認してください。

## `Error M3006` {#error-m3006}

`I'm sorry, you don't have the GitLab Duo subscription required to use Duo Chat. Please contact your administrator. Error code: M3006`というエラーが表示されることがあります。

このエラーは、GitLab Duo ChatがGitLab Duoのサブスクリプションに含まれていない場合に発生します。

[GitLab Duoのサブスクリプションティア](https://about.gitlab.com/gitlab-duo/#pricing)に、GitLab Duo Chatが含まれていることを確認してください。

## `Error M4000` {#error-m4000}

`I'm sorry, I can't generate a response. Please try again. Error code: M4000`というエラーが表示されることがあります。

このエラーは、スラッシュコマンドリクエストの処理中に予期しない問題が発生した場合に発生します。もう一度リクエストしてください。問題が解決しない場合は、コマンドの構文が正しいことを確認してください。

スラッシュコマンドの詳細については、次のドキュメントを参照してください:

- [/tests](examples.md#write-tests-in-the-ide)
- [/refactor](examples.md#refactor-code-in-the-ide)
- [/fix](examples.md#fix-code-in-the-ide)
- [/explain](examples.md#explain-selected-code)

## `Error M4001` {#error-m4001}

`I'm sorry, I can't generate a response. Please try again. Error code: M4001`というエラーが表示されることがあります。

このエラーは、リクエストを完了するために必要な情報が見つからない場合に発生します。もう一度リクエストしてください。

## `Error M4002` {#error-m4002}

`I'm sorry, I can't generate a response. Please try again. Error code: M4002`というエラーが表示されることがあります。

このエラーは、[CI/CD](examples.md#ask-about-cicd)に関連する質問に回答する際に問題が発生した場合に発生します。もう一度リクエストしてください。

## `Error M4003` {#error-m4003}

`This command is used for explaining vulnerabilities and can only be invoked from a vulnerability detail page.`または`Vulnerability Explanation currently only supports vulnerabilities reported by SAST. Error code: M4003`というエラーが表示されることがあります。

このエラーは、[`Explain Vulnerability`](examples.md#explain-a-vulnerability)機能を使用する際に問題が発生した場合に発生します。

## `Error M4004` {#error-m4004}

`This resource has no comments to summarize`というエラーが表示されることがあります。

このエラーは、`Summarize Discussion`機能を使用する際に問題が発生した場合に発生します。

## `Error M4005` {#error-m4005}

`There is no job log to troubleshoot.`または`This command is used for troubleshooting jobs and can only be invoked from a failed job log page.`というエラーが表示されることがあります。

このエラーは、[`Troubleshoot job`](examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)機能を使用する際に問題が発生した場合に発生します。

## `Error M5000` {#error-m5000}

`I'm sorry, I can't generate a response. Please try again. Error code: M5000`というエラーが表示されることがあります。

このエラーは、項目（イシュー、エピック、マージリクエストなど）に関連するコンテンツの処理中に問題が発生した場合に発生します。もう一度リクエストしてください。

## `Error A1000` {#error-a1000}

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1000`というエラーが表示されることがあります。

このエラーは、処理中にタイムアウトが発生した場合に発生します。もう一度リクエストしてください。

## `Error A1001` {#error-a1001}

`I'm sorry, I can't generate a response. Please try again. Error code: A1001`というエラーが表示されることがあります。

このエラーは、リクエストを処理したAIサービスで問題が発生した場合に発生します。

考えられる理由を以下に示します:

- GitLabコード内のバグが原因のクライアント側のエラー。
- Anthropicコード内のバグが原因のサーバー側のエラー。
- AIゲートウェイに到達しなかったHTTPリクエスト。

エラーの理由をより明確にするための[イシューが存在](https://gitlab.com/gitlab-org/gitlab/-/issues/479465)します。

問題を解決するには、もう一度リクエストしてください。

エラーが解決しない場合は、`/new`または`/reset`コマンドを使用して、新しい会話を開始してください。問題が解決しない場合は、GitLabサポートチームに問題をレポートしてください。

## `Error A1002` {#error-a1002}

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1002`というエラーが表示されることがあります。

このエラーは、AIゲートウェイからイベントが返されないか、GitLabがイベントの解析中に失敗した場合に発生します。もう一度リクエストしてください。

## `Error A1003` {#error-a1003}

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1003`というエラーが表示されることがあります。

このエラーは、AIゲートウェイからのストリーミング出力が失敗した場合に発生します。もう一度リクエストしてください。

## `Error A1004` {#error-a1004}

`I'm sorry, I couldn't respond in time. Please try again. Error code: A1004`というエラーが表示されることがあります。

このエラーは、AIゲートウェイ処理でエラーが発生した場合に発生します。もう一度リクエストしてください。

## `Error A1005` {#error-a1005}

`I'm sorry, you've entered too many prompts. Please run /clear or /reset before asking the next question. Error code: A1005`というエラーが表示されることがあります。

このエラーは、プロンプトの長さがLLMの最大トークン制限を超えた場合に発生します。`/new`コマンドで新しい会話を開始し、もう一度リクエストしてください。

## `Error A1006` {#error-a1006}

`I'm sorry, Duo Chat agent reached the limit before finding an answer for your question. Please try a different prompt or clear your conversation history with /clear. Error code: A1006`というエラーが表示されることがあります。

このエラーは、ReActエージェントがクエリに対するソリューションを見つけられなかった場合に発生します。別のプロンプトを試すか、`/new`または`/reset`で新しい会話を開始してください。

## `Error A1007` {#error-a1007}

`There was an error processing your request. Please try again or contact support if the issue persists. Error code: A1007`というエラーが表示されることがあります。

このエラーは、GitLab Duo Agent Platformでリクエストを処理中に予期しないエラーが発生した場合に発生します。

## `Error A1008` {#error-a1008}

`There was an error processing your request. Please try again or contact support if the issue persists. Error code: A1008`というエラーが表示されることがあります。

このエラーは、GitLab Duo Agent Platformで使用されているアップストリームのLLMプロバイダーにリクエストが送信された場合に発生します。

## `Error A6000` {#error-a6000}

`I'm sorry, I couldn't respond in time. Please try a more specific request or enter /clear to start a new chat. Error code: A6000`というエラーが表示されることがあります。

これは、GitLab Duo Chatに問題が発生した場合に発生するフォールバックエラーです。より具体的なリクエストを試すか、`/new`を入力して新しいチャットを開始するか、改善に役立つフィードバックをお寄せください。

## `Error A9999` {#error-a9999}

`I'm sorry, I couldn't respond in time. Please try again. Error code: A9999`というエラーが表示されることがあります。

このエラーは、ReActエージェントで不明なエラーが発生した場合に発生します。もう一度リクエストしてください。

## `Error G3001` {#error-g3001}

`I'm sorry, but answering this question requires a different Duo subscription. Please contact your administrator.`というエラーが表示されることがあります。

このエラーは、GitLab Duo Chatがサブスクリプションで利用できない場合に発生します。別のリクエストを試して、管理者に連絡してください。

## `Error G3002` {#error-g3002}

`I'm sorry, you have not selected a default GitLab Duo namespace. Please select a default GitLab Duo namespace in your user preferences.`というエラーが表示されることがあります。

このエラーは、複数のGitLab Duoネームスペースに所属していて、デフォルトのネームスペースを選択していない場合に発生します。

これを解決するには、次のいずれかを実行します:

- [既定のGitLab Duoネームスペースを割り当てます](../gitlab_duo/model_selection.md#assign-a-default-gitlab-duo-namespace)。
- モデル選択機能がベータ版である間にこの要件をオプトアウトするには、[GitLabサポート](https://about.gitlab.com/support/)に`ai_user_default_duo_namespace`機能フラグを無効にするように依頼してください。

## ヘッダーの不一致の問題 {#header-mismatch-issue}

特定のエラーコードなしで、`I'm sorry, I can't generate a response. Please try again`というエラーが表示される場合があります。

Sidekiqログをチェックして、次のエラーコードが見つかるかどうかを確認してください: `Header mismatch 'X-Gitlab-Instance-Id'`。

このエラーが表示された場合は、それを解決するために、GitLabサポートチームに連絡して、ライセンスの新しいアクティベーションコードを送信するように依頼してください。

詳細については、[イシュー103](https://gitlab.com/gitlab-com/enablement-sub-department/section-enable-request-for-help/-/issues/103)を参照してください。

## Cloud Connectorのヘルスチェック {#check-the-health-of-the-cloud-connector}

Cloud Connectorに関連するさまざまなコンポーネントのステータスを検証するスクリプトを作成しました。次に例を示します:

- アクセスデータ
- トークン
- ライセンス
- ホスト接続
- 機能フラグのアクセシビリティ

このスクリプトをデバッグモードで実行して、より詳細な出力を表示し、レポートファイルを生成できます。

1. 単一ノードインスタンスにSSHで接続し、スクリプトをダウンロードします:

   ```shell
   wget https://gitlab.com/gitlab-org/gitlab/-/snippets/3734617/raw/main/health_check.rb
   ```

1. Railsランナーを使用して、スクリプトを実行します。

   スクリプトへのフルパスを使用していることを確認してください。

   ```ruby
   Usage: gitlab-rails runner full_path/to/health_check.rb
          --debug                     Enable debug mode
          --output-file <file_path>   Write a report to a specified file
          --username <username>       Provide a username to test seat assignments
          --skip [CHECK]              Skip specific checks (options: access_data, token, license, host, features, end_to_end)
   ```
