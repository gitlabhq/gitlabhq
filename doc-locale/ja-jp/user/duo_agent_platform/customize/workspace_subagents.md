---
stage: Agent Foundations
group: Agent Developer
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Developer Flowがタスクを委任する専用のサブエージェントをリポジトリ内に定義します。
title: ワークスペースサブエージェント
---

{{< details >}}

- プラン: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 19.5で、`dap_workspace_agents`という名前の[機能フラグを使用した](../../../administration/feature_flags/_index.md) [実験](../../../policy/development_stages_support.md#experiment)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/259664)されました。デフォルトでは有効になっています。

{{< /history >}}

ワークスペースサブエージェントは、プロジェクトリポジトリ内にMarkdownファイルとして定義する専用エージェントです。この機能は、GitLab UIとGitLab Duo CLIの両方でDeveloper Flowに対してのみ使用できます。

Developer Flowは、サブエージェントの`description`に基づいて、タスクをサブエージェントに委任するかどうかを決定します。また、名前を指定してDeveloper Flowにサブエージェントを使用させることもできます。たとえば、イシューやマージリクエストコメントで[Developer Flowにメンション](../../project/merge_requests/developer.md#mention-duo-developer-in-a-discussion)し、サブエージェントの名前を指定します:

```plaintext
@duo-developer-<namespace> delegate the review of these changes to the reviewer subagent.
```

`<namespace>`をご自身のGitLabネームスペースパスに置き換えてください。サブエージェントに名前を指定すると委任される可能性は高くなりますが、タスクを委任するかどうかはDeveloper Flowが決定します。

ワークスペースサブエージェントは、他のGitLab Duo Agent Platformの機能と同様にGitLabクレジットを消費します。

## ワークスペースサブエージェントを使用するタイミング {#when-to-use-workspace-subagents}

ワークスペースサブエージェントは、Developer Flowとコンテキストを共有しません。タスクによってDeveloper Flowに不要な詳細が生成される場合は、サブエージェントを使用して、その詳細をDeveloper Flowのメインコンテキストから除外します。

たとえば、`run_command`ツールと`edit_file`ツールを備えたlinterサブエージェントは、プロジェクトのlinterを実行してlintエラーを修正できます。linterの出力と個々の修正内容は、サブエージェントの会話内にとどまります。Developer Flowは、修正内容の要約などの結果のみを受け取ります。サブエージェントのプロンプトで要求されている場合、結果には、次回避けるべき典型的なlinterの問題点を記載することもできます。その他の例としては、変更のレビュー、アプローチの調査、セキュリティなどの特定の領域のチェックなどがあります。

Developer Flowがタスクをサブエージェントに委任すると、サブエージェントは次のように動作します:

- Developer Flowから与えられたタスクから始まる、独自の会話の中で動作します。結果のみがDeveloper Flowに返されます。
- Developer Flowの指示ではなく、独自のプロンプトに従います。
- `tools`フィールドに記載されているツールのみを使用できます。たとえば、`read_file`と`grep`のみを持つレビューサブエージェントは、ファイルを変更できません。

次の表は、ワークスペースサブエージェントと、GitLab Duo Developerをカスタマイズする他の方法を比較したものです。

| カスタマイズ | 機能 | 使用する場面 |
|---------------|--------------|-------------|
| `AGENTS.md` | 作業を行うエージェントのコンテキストに、構造、コーディング規約、ビルドおよびテストの手順など、プロジェクトのコンテキストと規約を追加します。リポジトリ内のすべての作業に適用されます。 | リポジトリ内のすべてのタスクが同じ規約に従うようにしたい場合。 |
| Agent Skills | タスクがスキルの説明と一致した場合に、エージェントが自動的に読み込む知識またはワークフローを提供します。スキルを読み込んだエージェントが、同じ会話内で同じツールを使用して作業自体を行います。 | タスクが一致した場合に、エージェントに特定のワークフローに従わせたり、特定の知識を使用させたりしたい場合。 |
| ワークスペースサブエージェント | 独自のプロンプトとツールを持つ別のエージェントでタスクを実行し、結果のみを返します。 | linterの出力などのタスクの詳細をDeveloper Flowのコンテキストから除外したい場合、または独自の指示と限定されたツールを持つ別のエージェントを使用したい場合。 |

## サブエージェント定義 {#subagent-definitions}

各ワークスペースサブエージェントは、リポジトリのルートにある`.agents/agents/`ディレクトリ内のMarkdownファイルです。ファイルは`---`の行で囲まれたYAMLフロントマターで始まり、その後にプロンプトが続きます。プロンプトは、ファイルのMarkdown本文です。

次の表は、フロントマターのフィールドとプロンプトについて説明しています。

| フィールド | 必須 | 説明 |
|-------|----------|-------------|
| `name` | いいえ | Developer Flowがサブエージェントを識別するために使用する名前です。デフォルトでは、`.md`拡張子を除いたファイル名が使用されます。プロジェクト内で一意である必要があります。最大64文字です。 |
| `description` | はい | サブエージェントが何を行うかを示します。Developer Flowは、これを使用してサブエージェントに委任するタイミングを判断します。最大1,024文字です。 |
| `tools` | いいえ | サブエージェントが使用できるツールを、カンマ区切りのリストまたはYAMLリストとして指定します。[使用可能なツールの一覧](../agents/tools.md)のツール名を使用してください。`tools`を省略した場合、サブエージェントはツールを使用できません。サブエージェントは、提供された情報のみを使ってタスクについて推論できます。 |
| プロンプト | はい | フロントマターの後にある、サブエージェントへの指示です。最大10,000文字です。 |

### ファイル要件 {#file-requirements}

ワークスペースサブエージェントは、そのファイルが次の要件をすべて満たしている場合にのみ使用されます:

- ファイルが`.agents/agents/`ディレクトリに直接存在していること。サブディレクトリ内のファイルは無視されます。
- ファイル名が`.md`で終わっていること。
- ファイルがUTF-8テキストであること。
- ファイルが`---`の行で囲まれたYAMLフロントマターで始まっていること。
- フロントマターに`description`があること。
- フロントマターの後にプロンプトがあること。
- ファイルのサイズが64KB以下であること。

ファイルがこれらの要件を満たしていない場合、そのファイルはスキップされます。

### 数とサイズの制限 {#number-and-size-limits}

次の制限は、プロジェクト内のすべてのサブエージェントに適用されます。

| 制限 | GitLabでのセッション | GitLab Duo CLIセッション |
|-------|--------------------|-------------------------|
| サブエージェントの数 | ファイル名順で最初の10個の`.md`ファイルが読み込まれます。 | 最大10個のサブエージェント。要件を満たすすべてのサブエージェントが送信されます。 |
| 合計サイズ | 最大112KB。サイズには、各サブエージェントの名前、説明、ツール、プロンプトが含まれます。合計がこれを超える場合、一部のサブエージェントはDeveloper Flowで使用できなくなります。 | gRPCメッセージの最大サイズによって制限されます。 |

### セッションの開始を妨げるエラー {#errors-that-prevent-a-session-from-starting}

次の場合、Developer Flowセッションの開始に失敗します:

- 2つのサブエージェントが同じ名前を持っている。
- サブエージェントが、Developer Flowで使用できないツールを一覧に記載している。
- `name`、`description`、またはプロンプトが、それぞれの最大値を超えている。
- GitLab Duo CLIセッションで、要件を満たすサブエージェントが10個を超えている。

## ワークスペースサブエージェントの作成 {#create-a-workspace-subagent}

Developer Flowにタスクを委任するための専用エージェントを提供するために、ワークスペースサブエージェントを作成します。

前提条件: 

- [ベータ版機能と実験的機能](../turn_on_off.md#turn-on-beta-and-experimental-features)をオンにします。この設定は、単一のプロジェクトに対してオンにすることはできません:
  - GitLab.comでは、オーナーロールを持つユーザーがトップレベルグループでこの設定を変更します。トップレベルグループ内のすべてのサブグループとプロジェクトは、この設定を継承します。
  - GitLab Self-ManagedおよびGitLab Dedicatedでは、管理者がインスタンスに対してこの設定を変更します。インスタンス内のすべてのグループとプロジェクトは、この設定を継承します。
- [Developer Flowの前提条件](../../project/merge_requests/developer.md#prerequisites)を満たしてください。
- マージする前にサブエージェントをテストするには、[GitLab Duo CLI](../../gitlab_duo_cli/_index.md)のバージョン9.21.0以降をインストールしてください。

ワークスペースサブエージェントを作成するには、以下の手順に従います:

1. プロジェクトのブランチで、`.agents/agents/`ディレクトリにMarkdownファイルを作成します。例: `.agents/agents/reviewer.md`。
1. フロントマターとプロンプトを追加します。例: 

   ```markdown
   ---
   name: reviewer
   description: Reviews code changes and reports a short list of findings.
   tools: read_file, grep
   ---

   You are a meticulous code reviewer. When delegated a task, read the files it
   names and report a short list of findings. Do not modify any file.
   ```

1. マージする前にサブエージェントをテストします。GitLabでのセッションはデフォルトブランチからのみサブエージェントを読み込みますが、GitLab Duo CLIはローカルの作業ディレクトリからファイルを読み込みます。
   1. プロジェクトのルートディレクトリで、GitLab Duo CLIを使用してDeveloper Flowセッションを開始します。
   1. Developer Flowにサブエージェントへのタスクの委任を依頼するか、サブエージェントの説明と一致するタスクを与えます。
   1. セッションに`Delegated to workspace/agents/<subagent-name>`が表示され、続いてサブエージェントの結果が表示されることを確認します。サブエージェントが行ったことを確認するには、<kbd>Control</kbd>+<kbd>T</kbd>を押します。

1. ファイルをデフォルトブランチにコミットまたはマージします。
1. GitLabで、サブエージェントを使用するために新しいDeveloper Flowセッションを開始します。結果を確認するには、Developer Flowが投稿したリンクからセッションを開くか、左側のサイドバーで**AI** > **セッション**を選択します。Developer Flowがタスクを委任すると、セッションには**サブエージェントに継承した**が表示され、続いてサブエージェントの結果とともに**エージェントに戻されました**が表示されます。

GitLabでは、新しいセッションのみがサブエージェント設定の変更を反映します。既存のセッションは、再開した場合でも変更を反映しません。

## プロジェクトでワークスペースサブエージェントを禁止する {#prevent-workspace-subagents-in-a-project}

単一のプロジェクトに対してワークスペースサブエージェントをオフにすることはできません。サブエージェント定義をリポジトリに含めないようにするには、次のいずれかまたは両方の方法を使用します:

- プロジェクトの`.gitignore`ファイルに`.agents/agents/`を追加し、ファイルが誤ってコミットされないようにします。
- 正規表現`^\.agents\/agents\/`を使用して[名前でファイルを禁止するプッシュルール](../../project/repository/push_rules.md#prohibit-files-by-name)を作成します。GitLabは、それらのファイルを含むプッシュを拒否します。

## 関連トピック {#related-topics}

- [AGENTS.mdカスタマイズファイル](agents_md.md)
- [Agent Skills](agent_skills.md)
- [カスタムルール](custom_rules.md)

## トラブルシューティング {#troubleshooting}

ワークスペースサブエージェントが期待どおりに動作しない場合は、次の手順を実行します:

1. ベータ版機能と実験的機能がオンになっていることを確認します。
1. ファイルが[ファイル要件](#file-requirements)を満たしているか確認します。要件を満たしていないファイルはスキップされます。
1. GitLabでのセッションでは、ファイルがデフォルトブランチにあることを確認します。
1. セッションの開始に失敗した場合は、[セッションの開始を妨げるエラー](#errors-that-prevent-a-session-from-starting)を確認してください。
