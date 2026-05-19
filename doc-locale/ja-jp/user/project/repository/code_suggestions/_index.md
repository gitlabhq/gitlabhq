---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duoコード提案を使用すると、入力時にAIがコードを提案するため、GitLabでより効率的にコードを作成できます。
title: コード提案
---

{{< details >}}

- プラン: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- [デフォルトLLM](../../../gitlab_duo/model_selection.md#default-models)
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 16.1で[Google Vertex AI Codey APIのサポートが導入](https://gitlab.com/groups/gitlab-org/-/epics/10562)されました。
- GitLab 16.2で[GitLabネイティブモデルのサポートが終了](https://gitlab.com/groups/gitlab-org/-/epics/10752)しました。
- GitLab 16.3で[コード生成のサポートが導入](https://gitlab.com/gitlab-org/gitlab/-/issues/415583)されました。
- GitLab 16.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/435271)になりました。
- 2024年2月15日にGitLab Duo Proアドオンが必須となるように[変更](https://gitlab.com/gitlab-org/fulfillment/meta/-/issues/2031)されました。この機能は以前、PremiumおよびUltimateサブスクリプションに含まれていました。
- 2024年10月17日以降、サポートされているすべてのGitLabバージョンでGitLab Duo ProまたはGitLab Duo Enterpriseアドオンが必須となるように[変更](https://gitlab.com/gitlab-org/fulfillment/meta/-/issues/2031)されました。
- GitLab 17.6で`fireworks_qwen_code_completion`フラグとともに[Fireworks AIでホストされるQwen2.5コード補完モデルのサポートが導入](https://gitlab.com/groups/gitlab-org/-/epics/15850)されました。
- GitLab 17.11でQwen2.5コード補完モデルのサポートが[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187397)されました。
- GitLab 17.11で`use_fireworks_codestral_code_completion`機能フラグを介して、Fireworksでホストされる`Codestral`をデフォルトで有効にしました。
- GitLab 18.0でGitLab Duo Coreを含むように変更されました。
- GitLab 18.1でFireworksでホストされる`Codestral`をデフォルトモデルとして有効にしました。
- GitLab 18.2でコード生成のデフォルトモデルがClaude Sonnet 4に[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/545489)されました。
- 機能フラグ`code_suggestions_context`はGitLab 18.6で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/462750)されました。
- GitLab 18.10では、GitLab.comのFreeティアでGitLabクレジットとともに利用できます。

{{< /history >}}

> [!note]
> コード提案は以下で利用可能です:
>
> - GitLab Duo Agent Platform。課金は[利用量に基づいています](../../../../subscriptions/gitlab_credits.md)。
> - GitLab Duo Core、Pro、またはEnterprise、GitLab Duo with Amazon Q。課金はアドオンに基づきます。

GitLab Duoコード提案を使用すると、開発中に生成AIを使用してコードを提案することにより、より効率的にコードを作成できます。

- <i class="fa-youtube-play" aria-hidden="true"></i> [クリックスルーデモを見る](https://gitlab.navattic.com/code-suggestions)。
  <!-- Video published on 2023-12-09 --> <!-- Demo published on 2024-02-01 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [概要を見る](https://youtu.be/ds7SG1wgcVM)

## 前提条件 {#prerequisites}

コード提案を使用するには、以下の手順に従います:

- GitLab Duo Coreをお持ちの場合は、[IDE機能をオン](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off)にします。
- [コード提案をセットアップ](set_up.md)します。

> [!note]
> GitLab DuoにはGitLab 17.2以降が必要です。GitLab Duo Coreにアクセスして、最高のユーザーエクスペリエンスと結果を得るには、[GitLab 18.0以降にアップグレード](../../../../update/_index.md)してください。以前のバージョンでも引き続き動作する可能性はありますが、エクスペリエンスが低下するおそれがあります。

## コード提案を使用する {#use-code-suggestions}

コード提案を使用するには、以下の手順に従います:

1. [サポートされているIDE](supported_extensions.md#supported-editor-extensions)でGitプロジェクトを開きます。
1. [`git remote add`](../../../../topics/git/commands.md#git-remote-add)を使用して、ローカルリポジトリのリモートとしてプロジェクトを追加します。
1. 隠し`.git/`フォルダーを含むプロジェクトディレクトリを、IDEワークスペースまたはプロジェクトに追加します。
1. コードを作成します。入力すると、提案が表示されます。コード提案は、カーソルの位置に応じてコードスニペットを提示するか、現在の行を補完します。

1. 要件を自然言語で記述します。コード提案は、提供されたコンテキストに基づいて関数やコードスニペットを生成します。

1. 提案を受け取ったら、次のいずれかを実行できます:
   - 提案を受け入れるには、<kbd>Tab</kbd>を押します。
   - 部分的な提案を受け入れるには、<kbd>Control</kbd>+<kbd>右矢印</kbd>または<kbd>Command</kbd>+<kbd>右矢印</kbd>を押します。
   - 提案を拒否するには、<kbd>Esc</kbd>を押します。Neovimでメニューを終了するには、<kbd>Control</kbd>+<kbd>E</kbd>を押します。
   - 提案を無視するには、通常どおり入力を続けます。

## 複数のコード提案を表示する {#view-multiple-code-suggestions}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1325)されました。

{{< /history >}}

VS Codeのコード補完候補では、複数の候補オプションを利用できる場合があります。利用可能なすべての候補を表示するには、以下の手順に従います:

1. コード補完候補にカーソルを合わせます。
1. 代替案をスクロールします。次のいずれかの操作を行います:
   - キーボードショートカットを使用します:
     - Macでは、<kbd>Option</kbd>+<kbd>[</kbd>を押して前の候補を表示し、<kbd>Option</kbd>+<kbd>]</kbd>を押して次の候補を表示します。
     - LinuxとWindowsでは、<kbd>Alt</kbd>+<kbd>[</kbd>を押して前の候補を表示し、<kbd>Alt</kbd>+<kbd>]</kbd>を押して次の候補を表示します。
   - 表示されるダイアログで、右矢印または左矢印を選択して、次または前のオプションを表示します。
1. <kbd>Tab</kbd>を押して、希望する候補を適用します。

## コード補完と生成 {#code-completion-and-generation}

コード提案は、次のようなコード補完とコード生成を使用します:

|  | コード補完 | コード生成 |
| :---- | :---- | :---- |
| 目的 | 現在のコード行を補完するための候補を提供します。  | 自然言語のコメントに基づいて新しいコードを生成します。 |
| トリガー | 入力中にトリガーされます。通常、短い遅延が発生します。  | 特定のキーワードを含むコメントを記述した後、<kbd>Enter</kbd>を押すとトリガーされます。 |
| スコープ | 現在の行または小さなコードブロックに制限されます。  | コンテキストに基づいて、メソッド、関数、またはクラス全体を生成できます。 |
| 精度 | 小規模なタスクや短いコードブロックの場合に、より正確です。  | より大きな大規模言語モデル（LLM）が使用され、追加のコンテキスト（たとえば、プロジェクトで使用されるライブラリ）がリクエストで送信され、指示がLLMに渡されるため、複雑なタスクや大きなコードブロックの場合により正確です。 |
| 使い方 | コード補完が、入力中の行の補完を自動的に提案します。 | コメントを記述して<kbd>Enter</kbd>を押すか、空の関数またはメソッドを入力します。 |
| 使用すべき時 | 1行または数行のコードをすばやく完成させたい場合に、コード補完を使用します。 | より複雑なタスク、より大きなコードベース、自然言語の説明に基づいてゼロから新しいコードを書きたい場合、または編集するファイルが5行未満のコードしかない場合に、コード生成を使用します。 |

コード提案は常にこれらの両方の機能を使用します。コード生成のみ、またはコード補完のみを使用することはできません。

<i class="fa-youtube-play" aria-hidden="true"></i> [コード補完とコード生成の比較デモを見る](https://www.youtube.com/watch?v=9dsyqMt9yg4)。
<!-- Video published on 2024-09-26 -->

### コード生成のベストプラクティス {#best-practices-for-code-generation}

コード生成で最良の結果を得るには、次を参考にしてください:

- シンプルさを保った上で、できるだけ具体的にしてください。
- 生成する結果（関数など）を記述し、何を達成したいかについて詳しく説明してください。
- 使用するフレームワークやライブラリなど、詳細な情報を追加してください。
- 各コメントの後にスペースまたは改行を追加してください。こうしたスペースにより、指示が完了したことをコードジェネレーターに伝えられます。
- レビューを行い、[コード提案に利用できるコンテキスト](context.md)を調整します。

たとえば、特定の要件を持つPython Webサービスを作成するには、次のように記述します:

```plaintext
# Create a web service using Tornado that allows a user to sign in, run a security scan, and review the scan results.
# Each action (sign in, run a scan, and review results) should be its own resource in the web service
...
```

AIは決定的ではないため、同じ入力を使用しても毎回同じ候補が得られるとは限りません。高品質なコードを生成するには、明確かつ記述的で具体的なタスクを記述してください。

ユースケースとベストプラクティスについては、[GitLab Duoの例のドキュメント](../../../gitlab_duo/use_cases.md)に従ってください。

## 利用可能な言語モデル {#available-language-models}

異なる言語モデルをコード提案のソースにすることができます。

- GitLab.comの場合: GitLabがモデルをホストし、クラウドベースのAIゲートウェイを介してモデルに接続します。
- GitLab Self-Managedの場合、次の2つのオプションがあります:
  - GitLabは、[モデルをホストし、クラウドベースのAIゲートウェイを介してモデルに接続できます](set_up.md)。
  - 組織は[セルフホストモデル](../../../../administration/gitlab_duo_self_hosted/_index.md)を使用できます。これは、AIゲートウェイと言語モデルをホストすることを意味します。GitLabが管理するモデル、その他のサポートされている言語モデル、または独自の互換性のあるモデルを使用できます。

## パフォーマンス {#performance}

コード提案のデフォルトの応答時間、およびストリーミング、プロンプトキャッシュ、接続設定のオプションについて学習します。

### 応答時間 {#response-time}

コード提案は、生成AIモデルによって強化されています。

- コード補完の場合、通常、提案は低レイテンシーです。1秒未満で完了します。
- コード生成の場合、アルゴリズムまたは大きなコードブロックの生成に5秒以上かかる場合があります。

パーソナルアクセストークンを使用すると、GitLab.comまたはGitLabインスタンスへの安全なAPI接続が可能になります。このAPI接続により、IDE/エディタから[GitLab AIゲートウェイ](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist)（GitLabホストサービス）にコンテキストウィンドウを安全に送信できます。ゲートウェイは大規模言語モデルAPIを呼び出し、生成された候補がIDE/エディタに送り返されます。

### ストリーミング {#streaming}

コード生成応答のストリーミングはJetBrainsとVisual Studioでサポートされており、認識される応答時間が短縮されます。その他のサポートされているIDEは、生成されたコードを単一のブロックで返します。

コード補完では、ストリーミングは有効になっていません。

### プロンプトキャッシュ {#prompt-caching}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/535651)されました。

{{< /history >}}

プロンプトキャッシュは、コード提案のレイテンシーを改善するために、すべてのFireworksホストモデルでデフォルトで有効になっています。

プロンプトキャッシュが有効になっている場合、コード補完プロンプトデータは、モデルベンダーによって一時的にメモリに保存されます。

プロンプトキャッシュは、キャッシュされたプロンプトと入力データの再処理を回避することで、レイテンシーを大幅に改善します。キャッシュされたデータは、永続ストレージに記録されません。

#### プロンプトキャッシュをオフにする {#turn-off-prompt-caching}

GitLab Duo設定で、トップレベルグループのプロンプトキャッシュをオフにすることができます。これにより、[GitLab Duo Agentic Chat](../../../gitlab_duo_chat/agentic_chat.md#prompt-caching)のプロンプトキャッシュもオフになります。

前提条件: 

- GitLab Self-Managedインスタンスの管理者アクセス権。

GitLab.comの場合: 

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **プロンプトキャッシュ**切替を無効にします。
1. **変更を保存**を選択します。

GitLab Self-Managed: 

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **プロンプトキャッシュ**で、**プロンプトキャッシュを有効にする**チェックボックスをオフにします。
1. **変更を保存**を選択します。

### ダイレクト接続とインダイレクト接続 {#direct-and-indirect-connections}

{{< history >}}

- GitLab 17.2で`code_suggestions_direct_access`[フラグ](../../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/462791)されました。デフォルトでは無効になっています。

{{< /history >}}

デフォルトでは、レイテンシーを最小限に抑えるため、コード補完リクエストはIDEからAIゲートウェイに直接送信されます。このダイレクト接続を機能させるには、IDEが`https://cloud.gitlab.com:443`に接続可能な状態である必要があります。これが不可能な場合は（たとえば、ネットワーク制限のため）、すべてのユーザーに対してダイレクト接続を無効にできます。この場合、コード補完リクエストはGitLab Self-Managedインスタンスを介して間接的に送信され、次にリクエストがAIゲートウェイに送信されます。これにより、リクエストのレイテンシーが高くなる可能性があります。

#### ダイレクト接続またはインダイレクト接続を設定する {#configure-direct-or-indirect-connections}

前提条件: 

- GitLab Self-Managedインスタンスの管理者である必要があります。

{{< tabs >}}

{{< tab title="17.4以降" >}}

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **接続方法**で、オプションを選択します:
   - コード補完リクエストのレイテンシーを最小限に抑えるには、**ダイレクト接続**を選択します。
   - すべてのユーザーに対してダイレクト接続を無効にするには、**GitLab Self-Managedを介した間接的接続**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **AIネイティブ機能**を展開します。
1. オプションを選択します:
   - ダイレクト接続を有効にし、コード補完リクエストのレイテンシーを最小限に抑えるには、**コード提案のダイレクト接続を無効にする**チェックボックスをオフにします。
   - ダイレクト接続を無効にするには、**コード提案のダイレクト接続を無効にする**チェックボックスをオンにします。

{{< /tab >}}

{{< /tabs >}}

## 制限 {#limitations}

### ファイルコンテンツの切り捨て {#truncation-of-file-content}

LLMの制限とパフォーマンス上の理由により、現在開いているファイルのコンテンツは次のトークン以降で切り捨てられます:

- コード補完の場合: 32,000トークン（約128,000文字）まで。
- コード生成の場合: 80,000トークン（約320,000文字）まで。

カーソルより上のコンテンツは、カーソルより下のコンテンツよりも優先されます。カーソルより上のコンテンツは左側から切り捨てられ、カーソルより下のコンテンツは右側から切り捨てられます。これらの数値は、コード提案の最大入力コンテキストサイズを表しています。

コード生成の制限を引き上げるサポートは、[イシュー585841](https://gitlab.com/gitlab-org/gitlab/-/issues/585841)で提案されています。

### 出力の長さ {#output-length}

LLMの制限とパフォーマンス上の理由から、コード提案の出力は次のように制限されています:

- コード補完の場合: 64トークン（約256文字）まで。
- コード生成の場合: 2048トークン（約7168文字）まで。

### 結果の精度 {#accuracy-of-results}

当社では、生成されたコンテンツ全体の精度を向上させるため、継続的に改善を行っています。ただし、コード提案では、次のような提案が生成される可能性があります:

- 無関係なもの。
- 不完全なもの。
- パイプラインで失敗する可能性が高いもの。
- 潜在的に脆弱なもの。
- 不快または配慮のないもの。

コード提案を使用する場合でも、コードレビューのベストプラクティスが引き続き適用されます。

## フィードバック {#feedback}

[イシュー435783](https://gitlab.com/gitlab-org/gitlab/-/issues/435783)で、コード提案のエクスペリエンスに関するフィードバックをお寄せください。
