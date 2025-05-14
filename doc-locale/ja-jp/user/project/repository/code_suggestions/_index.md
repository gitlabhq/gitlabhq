---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Code Suggestions helps you write code in GitLab more efficiently by using AI to suggest code as you type.
title: コード提案
---

{{< details >}}

- プラン: GitLab Duo Proを含む Premium、GitLab Duo Proを含むUltimate、またはEnterprise - [トライアルを開始](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- LLM: コード補完の場合、Fireworks AIホストの [`Qwen2.5 7B`](https://fireworks.ai/models/fireworks/qwen2p5-coder-7b) とVertex AI Codey[`code-gecko`](https://console.cloud.google.com/vertex-ai/publishers/google/model-garden/code-gecko)。コード生成の場合、Anthropic [Claude 3.7 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-7-sonnet)。

{{< /details >}}

{{< history >}}

- GitLab 16.1で、[Google Vertex AI Codey APIのサポートが導入](https://gitlab.com/groups/gitlab-org/-/epics/10562)。
- [GitLab 16.2で、GitLabネイティブモデルのサポートが終了](https://gitlab.com/groups/gitlab-org/-/epics/10752)。
- GitLab 16.3で[コード生成のサポートが導入](https://gitlab.com/gitlab-org/gitlab/-/issues/415583)。
- GitLab 16.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/435271)。
- 2024年2月15日に、サブスクリプションでGitLab Duo Proが必須となりました。
- GitLab 17.6以降では、GitLab Duoアドオンが必須となりました。
- GitLab 17.6で、[Fireworks AIホストのQwen2.5コード補完モデルのサポートが導入](https://gitlab.com/groups/gitlab-org/-/epics/15850)。`fireworks_qwen_code_completion`という名前のフラグが付きます。

{{< /history >}}

GitLab Duoコード提案を使用すると、開発中に生成AIを使用してコードを提案することにより、より効率的にコードを作成できます。

コード提案を使い始める前に、コード提案リクエストの管理にどの方法を使用するのか、次から決める必要があります。

- GitLab.comまたはGitLab Self-Managedでは、GitLabがホストするデフォルトのGitLab AIベンダーモデルとクラウドベースのAIゲートウェイを使用します。
- GitLab Self-Managedでは、GitLab 17.9以降の場合、[サポートされているSelf-Managedモデルを使用したGitLab Duoセルフホスト](../../../../administration/gitlab_duo_self_hosted/_index.md)を使用します。Self-Managedモデルは、外部モデルに何も送信されないようにすることで、セキュリティとプライバシーを最大限担保できます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [クリックスルーデモについては、こちらをご覧ください](https://gitlab.navattic.com/code-suggestions)。
<!-- Video published on 2023-12-09 --> <!-- Demo published on 2024-02-01 -->

{{< alert type="note" >}}

GitLab Duoで最高のユーザーエクスペリエンスと結果を得るには、GitLab 17.2以降が必要です。以前のバージョンでも引き続き動作する可能性はありますが、エクスペリエンスが低下するおそれがあります。最高のエクスペリエンスを得るには、[GitLabの最新バージョンにアップグレード](../../../../update/_index.md#upgrade-gitlab)する必要があります。

{{< /alert >}}

## コード提案を使用する

前提条件:

- [コード提案を設定](set_up.md)している必要があります。

コード提案を使用するには、以下の手順に従います。

1. [サポートされているIDE](supported_extensions.md#supported-editor-extensions)でGitプロジェクトを開きます。
1. [`git remote add`](../../../../topics/git/commands.md#git-remote-add)を使用して、ローカルリポジトリのリモートとしてプロジェクトを追加します。
1. 非表示の`.git/`フォルダを含むプロジェクトディレクトリを、IDEワークスペースまたはプロジェクトに追加します。
1. コードを作成します。入力すると、候補が表示されます。コード提案は、カーソルの位置に応じて、コードスニペットを提供するか、現在の行を完了します。

1. 要件を自然言語で記述します。コード提案は、提供されたコンテキストに基づいて関数とコードスニペットを生成します。

1. 候補を受け取ったら、次のいずれかを実行できます。
   - 候補に賛成の場合は、<kbd>Tab</kbd>キーを押します。
   - 部分的な候補に賛成の場合は、<kbd>Control</kbd>+<kbd>右矢印</kbd>または<kbd>Command</kbd>+<kbd>右矢印</kbd>を押します。
   - 候補に賛成しない場合は、<kbd>Esc</kbd>キーを押します。
   - 候補を無視するには、通常どおり入力を続けます。

## 複数のコード提案を表示する

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1325)。

{{< /history >}}

VS Codeのコード補完候補では、複数の候補オプションを利用できる場合があります。利用可能なすべての候補を表示するには、以下の手順に従います。

1. コード補完候補にカーソルを合わせます。
1. 代替案をスクロールします。次のいずれかの操作を行います。
   - キーボードショートカットを使用します。
     - Macでは、<kbd>Option</kbd> + <kbd>]</kbd>を押して次の候補を表示し、<kbd>Option</kbd> + <kbd>\[</kbd>を押して前の候補を表示します。
     - Windowsでは、<kbd>Alt</kbd> + <kbd>]</kbd>を押して次の候補を表示し、<kbd>Alt</kbd> + <kbd>\[</kbd>を押して前の候補を表示します。
   - 表示されるダイアログで、右矢印または左矢印を選択して、次または前のオプションを表示します。
1. <kbd>Tab</kbd>を押して、希望する候補を適用します。

## コード補完と生成

コード提案は、次のようなコード補完とコード生成を使用します。

|  | コード補完 | コード生成 |
| :---- | :---- | :---- |
| 目的 | 現在のコード行を完成させるための提案を提供します。  | 自然言語のコメントに基づいて新しいコードを生成します。 |
| トリガー | 入力時にトリガーします。通常、短い遅延が発生します。  | 特定のキーワードを含むコメントを記述した後、<kbd>Enter</kbd>キーを押すとトリガーします。 |
| スコープ | 現在の行または小さなコードブロックに制限されます。  | コンテキストに基づいて、メソッド、関数、またはクラス全体を生成できます。 |
| 精度 | 小規模なタスクや短いコードブロックの場合に、より正確です。  | 大規模言語モデル(LLM)が使用され、追加のコンテキスト(たとえば、プロジェクトで使用されるライブラリ)がリクエストで送信され、指示がLLMに渡されることから、複雑なタスクや大きなコードブロックの場合により正確です。 |
| 使い方 | コード補完が、入力している行の補完を自動的に提案します。 | コメントを記述して<kbd>Enter</kbd>キーを押すか、空の関数またはメソッドを入力します。 |
| 使用すべき時 | 1行または数行のコードをすばやく完成させたい場合に、コード補完を使用します。 | より複雑なタスク、より大きなコードベース、自然言語の説明に基づいて最初から新しいコードを作成する場合、または編集するファイルが5行未満のコードしかない場合に、コード生成を使用します。 |

コード提案は常にこれらの両方の機能を使用します。コード生成のみ、またはコード補完のみを使用することはできません。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [コード補完とコード生成の比較デモを見る](https://www.youtube.com/watch?v=9dsyqMt9yg4)。
<!-- Video published on 2024-09-26 -->

### コード生成のベストプラクティス

コード生成で最良の結果を得るには、次を参考にしてください。

- シンプルさを保った上で、できるだけ具体的にしてください。
- 生成する結果(関数など)を記述し、何を達成したいかについて詳しく説明してください。
- 使用するフレームワークやライブラリなど、詳細な情報を追加してください。
- 各コメントの後にスペースまたは改行を追加してください。こうしたスペースにより、指示が完了したことをコードジェネレーターに伝えられます。
- GitLab 17.2以降で、`advanced_context_resolver`および`code_suggestions_context`機能フラグが有効になっている場合は、他のタブで関連ファイルを開き、[コード提案が認識しているコンテキスト](#use-files-open-in-tabs-as-context)を拡大してください。

たとえば、特定の要件を持つPython Webサービスを作成するには、次のように記述します。

```plaintext
# Create a web service using Tornado that allows a user to sign in, run a security scan, and review the scan results.
# Each action (sign in, run a scan, and review results) should be its own resource in the web service
...
```

AIは決定的ではないため、同じ入力を使用しても毎回同じ候補が得られるとは限りません。高品質なコードを生成するには、明確かつ記述的で具体的なタスクを記述してください。

ユースケースとベストプラクティスについては、[GitLab Duoの例のドキュメント](../../../gitlab_duo_examples.md)に従ってください。

## コード提案が認識するコンテキスト

コード提案は、提案を充実させるためのコンテキストとして、開発環境に関する次の情報を使用します。

- IDEで開いているファイル。そのファイル内のカーソルの前後のコンテンツを含みます。
- ファイル名と拡張子。
- (オプション) IDEのタブで開いているファイル。これらのファイルは、コードプロジェクトの標準とプラクティスに関する詳細情報をGitLab Duoに提供します。デフォルトで有効になっています。タブをコンテキストとして管理するには、[開いているファイルをコンテキストとして使用する](#using-open-files-as-context)を参照してください。
- (オプション) 現在開いているファイルにインポートされたファイル。これらのインポートされたファイルは、現在のファイルで使用されているクラスとメソッドに関する詳細情報をGitLab Duoに提供します。デフォルトで無効になっています。インポートされたファイルをコンテキストとして管理するには、[インポートされたファイルをコンテキストとして使用する](#using-imported-files-as-context)を参照してください。
- コード提案機能は、[サポートされている言語](supported_extensions.md#supported-languages)のコンテンツを使用します。
- コード生成機能は、次の言語のコンテンツを使用します。
  - Go
  - Java
  - JavaScript
  - Kotlin
  - Python
  - Ruby
  - Rust
  - TypeScript(`.ts`および`.tsx`ファイル)
  - Vue
  - YAML

詳細については、[epic 57](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/57)を参照してください。

### 開いているファイルをコンテキストとして使用する

{{< history >}}

- GitLab 17.1で、`advanced_context_resolver`という名前の[フラグ](../../../../administration/feature_flags.md)付きで[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/464767)。デフォルトでは無効になっています。
- GitLab 17.1で、`code_suggestions_context`という名前の[フラグ](../../../../administration/feature_flags.md)付きで[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462750)。デフォルトでは無効になっています。
- VS Code用GitLabワークフロー4.20.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/276)。
- JetBrains用GitLab Duo 2.7.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/462)。
- 2024年7月16日にGitLab Neovimプラグインに[追加](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/merge_requests/152)。
- GitLab 17.2のGitLab.comで、機能フラグ`advanced_context_resolver`と`code_suggestions_context`が有効化。
- GitLab 17.4で、機能フラグ`advanced_context_resolver`と`code_suggestions_context`が[GitLab Self-Managedで有効化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161538)。

{{< /history >}}

{{< alert type="flag" >}}

この機能の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

{{< alert type="note" >}}

GitLabは最近、Duoコード提案の\[開いているタブ]の内部ロジックをリファクタリングしました。開いているタブを使用するユーザーは、機能を復元するためにエディタ拡張機能のバージョンを7.17.1以降に更新する必要があります。

{{< /alert >}}

タブをコンテキストとして使用する場合、コード提案はIDEのタブで開いているファイルをコンテキストとして使用します。これらのファイルは、コードプロジェクトの標準とプラクティスに関する詳細情報をGitLab Duoに提供します。

#### コンテキストとして開いているファイルをオンにする

デフォルトでは、コード提案は、提案を行う際にIDEで開いているファイルをコンテキストとして使用します。

前提条件:

- GitLab 17.2以降が必要です。コード提案をサポートする以前のバージョンのGitLabでは、開いているタブのコンテンツをプロジェクト内の他のファイルよりも重視することはできません。
- GitLab Duoコード提案がプロジェクトで有効になっている必要があります。
- [サポートされているコード言語](#the-context-code-suggestions-is-aware-of)を使用する必要があります。
- Visual Studio Codeの場合、GitLabワークフロー拡張機能バージョン4.14.2以降が必要です。

タブで開いているファイルがコンテキストとして使用されていることを確認するには、以下の手順に従います。

{{< tabs >}}

{{< tab title="Visual Studio Code" >}}

1. 上部のバーで、**コード > 設定 > Extensions**に移動します。
1. リストでGitLabワークフローを検索し、歯車アイコンを選択します。
1. **Extension Settings**を選択します。
1. **ユーザー**設定の**GitLab › Duo Code Suggestions: Open Tabs Context**内にある、**Use the contents of open tabs as context**を選択します。

{{< /tab >}}

{{< tab title="JetBrains IDE" >}}

1. IDEの上部のメニューバーに移動し、**設定**を選択します。
1. 左側のサイドバーで、**Tools**を展開し、**GitLab Duo**を選択します。
1. **GitLab言語サーバー**を展開します。
1. **コード補完**で、**Send open tabs as contex**を選択します。
1. **OK**または**保存**を選択します。

{{< /tab >}}

{{< /tabs >}}

#### コンテキストとして開いているファイルを使用する

タブで開いているファイルがコンテキストとして使用されていることを確認した後、コンテキストに提供するファイルを開きます。

- コード提案は、最近開いたファイルまたは変更されたファイルを最もよく使用します。
- ファイルを追加のコンテキストとして使用したくない場合は、そのファイルを閉じます。

ファイルでの作業を開始すると、GitLab Duoは[truncation limits](#truncation-of-file-content)内で、開いているファイルを補助コンテキストとして使用します。

コード生成の結果を調整するには、作成する内容を説明するコードコメントをファイルに追加します。

- コード生成は、コードコメントをチャットのように扱います。
- コードコメントは`user_instruction`を更新し、次に受け取る結果を改善します。

### インポートされたファイルをコンテキストとして使用する

{{< history >}}

- GitLab 17.9で、`code_suggestions_include_context_imports`という名前の[フラグ](../../../../administration/feature_flags.md)付きで[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/514124)。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

IDEでインポートしたファイルを使用して、コードプロジェクトに関するコンテキストを提供します。インポートされたファイルコンテキストは、`.js`、`.jsx`、`.ts`、`.tsx`、および`.vue`ファイルタイプを含む、JavaScriptおよびTypeScriptファイルでサポートされています。

## ファイルコンテンツの切り捨て

LLMの制限とパフォーマンス上の理由により、現在開いているファイルのコンテンツは次のトークン以降で切り捨てられます。

- コード補完の場合:
  - GitLab 17.5以前では、2,048トークン(約8,192文字)まで。
  - GitLab 17.6以降では、32,000トークン(約128,000文字)まで。
- コード生成の場合は、最大142,856 トークン(約500,000文字)まで。

カーソルより上のコンテンツは、カーソルより下のコンテンツよりも優先されます。カーソルより上のコンテンツは左側から切り捨てられ、カーソルより下のコンテンツは右側から切り捨てられます。これらの数値は、コード提案の最大入力コンテキストサイズを表しています。

## 出力の長さ

LLMの制限とパフォーマンス上の理由から、コード提案の出力は次のように制限されています。

- コード補完の場合は、最大64 トークン(約256文字)まで。
- コード生成の場合は、最大2048トークン(約7168文字)まで。

## 結果の精度

当社では、生成されたコンテンツ全体の精度を向上させるため、継続的に改善を行っています。ただし、コード提案では、次のような提案が生成される可能性があります。

- 無関係なもの。
- 不完全なもの。
- パイプラインで失敗するもの。
- 潜在的に安全ではないもの。
- 不快または配慮のないもの。

コード提案を使用する場合でも、[コードレビューのベストプラクティス](../../../../development/code_review.md)は引き続き有効です。

## プロンプトの作成方法

プロンプトを作成するコードについては、次のファイルを参照してください。

- **コード生成**: [`ee/lib/api/code_suggestions.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/api/code_suggestions.rb#L76)（`gitlab`リポジトリ内）。
- **コード補完**: [`ai_gateway/code_suggestions/processing/completions.py`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/fcb3f485a8f047a86a8166aad81f93b6d82106a7/ai_gateway/code_suggestions/processing/completions.py#L273)（`modelops`リポジトリ内）。

## 応答時間

コード提案は、生成AIモデルによって強化されています。

- コード補完の場合、通常、提案は低レイテンシーです。1秒未満で完了します。
- コード生成の場合、アルゴリズムまたは大きなコードブロックの生成に5秒以上かかる場合があります。

パーソナルアクセストークンを使用すると、GitLab.comまたはGitLabインスタンスへの安全なAPI接続が可能になります。このAPI接続により、IDE/エディタから[GitLab AIゲートウェイ](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)（GitLabホストサービス）にコンテキストウィンドウを安全に送信できます。[ゲートウェイ](../../../../development/ai_architecture.md)は大規模言語モデルAPIを呼び出し、生成された候補がIDE/エディタに送り返されます。

### ストリーミング

コード生成応答のストリーミングはJetBrainsとVisual Studioでサポートされています。それにより、応答時間が短くなっています。その他のサポートされているIDEは、生成されたコードを単一のブロックで返します。

### ダイレクト接続とインダイレクト接続

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462791): GitLab 17.2。[フラグ](../../../../administration/feature_flags.md)名: `code_suggestions_direct_access`。デフォルトでは無効になっています。

{{< /history >}}

デフォルトでは、レイテンシーを最小限に抑えるため、コード補完リクエストはIDEからAIゲートウェイに直接送信されます。この直接接続を機能させるには、IDEが`https://cloud.gitlab.com:443`に接続可能な状態である必要があります。これが不可能な場合は（たとえば、ネットワーク制限のため）、すべてのユーザーに対してダイレクト接続を無効にできます。この場合、コード補完リクエストはGitLab Self-Managedインスタンスを介して間接的に送信され、次にリクエストがAIゲートウェイに送信されます。これにより、リクエストのレイテンシーが高くなる可能性があります。

#### ダイレクト接続またはインダイレクト接続の設定

前提条件:

- GitLab Self-Managedインスタンスの管理者である必要があります。

{{< tabs >}}

{{< tab title="17.4以降" >}}

1. 左側のサイドバーの下部にある**管理者**を選択します。
1. **設定 > 一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **接続方法**で、オプションを選択します。
   - コード補完リクエストのレイテンシーを最小限に抑えるには、**ダイレクト接続**を選択します。
   - すべてのユーザーに対してダイレクト接続を無効にするには、**Indirect connections through the GitLab Self-Managed instance**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

1. 左側のサイドバーの下部にある**管理者**を選択します。
1. **設定 > 一般**を選択します。
1. **AI搭載機能**を展開します。
1. 次のオプションを選択します。
   - ダイレクト接続を有効にし、コード補完リクエストのレイテンシーを最小限に抑えるには、**Disable direct connections for code suggestions**チェックボックスをオフにします。
   - ダイレクト接続を無効にするには、**Disable direct connections for code suggestions**チェックボックスをオンにします。

{{< /tab >}}

{{< /tabs >}}

## フィードバック

[issue 435783](https://gitlab.com/gitlab-org/gitlab/-/issues/435783)で、Code Suggestionsのエクスペリエンスに関するフィードバックをお寄せください。
