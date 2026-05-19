---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: カスタムルール
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.2でカスタムルールが[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/550743)されました。
  - GitLab for VS Code 6.32.2で[導入](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/releases/v6.32.2)。
  - JetBrains IDE用GitLab Duoプラグイン3.12.2で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/releases/v3.12.2)。
  - GitLab for Visual Studio 0.60.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-visual-studio-extension/-/releases/v0.60.0)。
  - GitLab Duo CLI 8.43.0で[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.43.0)。
- GitLab 18.7でユーザーレベルのカスタムルールが[追加](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2452)されました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。
- GitLab UIのサポートはGitLab 18.11で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/work_items/593279)。

{{< /history >}}

GitLab Duo Agent Platformでカスタムルールを使用すると、生成された出力（例えば、コードやドキュメント）が特定の指示や、開発スタイルガイドなどのその他の要件に合致していることを確認できます。

次のAgent Platform機能はカスタムルールをサポートしています:

- [GitLab Duo Agentic Chat](../../gitlab_duo_chat/agentic_chat.md)
- [基本的なエージェントとカスタムエージェント](../agents/_index.md)
- [基本的なフローとカスタムフロー](../flows/_index.md)

## カスタムルールを作成する {#create-custom-rules}

GitLab Duoの使用方法に応じて、カスタムルールは2つのレベルで作成できます:

| レベル                                                           | GitLab UIでのAgentic Chat | エディター拡張機能 | GitLab Duo CLI |
|-----------------------------------------------------------------|--------------------------|------------------|--------------|
| ユーザーレベル: すべてのプロジェクトとワークスペースに適用        | {{< no >}}  |  {{< yes >}}    | {{< yes >}} |
| ワークスペースレベル: 特定のプロジェクトまたはワークスペースにのみ適用  | {{< yes >}} | {{< yes >}}         | {{< yes >}} |

ユーザーレベルとワークスペースレベルの両方のルールが存在する場合、GitLab Duo Chatは両方を会話に適用します。

前提条件: 

- [Agent Platformの前提条件](../_index.md#prerequisites)を満たしてください。
- ローカル環境でGitLab Duoを使用する場合、次のいずれかをインストールして設定してください:
  - [GitLab for VS Code](../../../editor_extensions/visual_studio_code/setup.md) 6.32.2以降。
  - [GitLab Duoプラグインfor JetBrains IDE](../../../editor_extensions/jetbrains_ide/setup.md) 3.12.2以降。
  - [GitLab for Visual Studio](../../../editor_extensions/visual_studio/setup.md) 0.60.0以降。
  - [GitLab Duo CLI](../../gitlab_duo_cli/_index.md#set-up-the-gitlab-duo-cli) 8.43.0以降。

> [!note]
> カスタムルールを作成する前に存在していた会話は、これらのルールに従いません。

### ユーザーレベルのカスタムルールを作成する {#create-user-level-custom-rules}

ユーザーレベルのカスタムルールは、ローカル環境（IDE）のすべてのプロジェクトとワークスペースに適用されます。

1. ホームディレクトリにカスタムルールファイルを作成します:
   - LinuxまたはmacOSでは、`~/.gitlab/duo/chat-rules.md`にファイルを作成します。
   - Windowsでは、`%APPDATA%\GitLab\duo\chat-rules.md`にファイルを作成します。
1. カスタムルールをファイルに追加します。例: 

   ```markdown
   - Don't put comments in the generated code
   - Be brief in your explanations
   - Always use single quotes for JavaScript strings
   ```

1. ファイルを保存します。
1. 新しいカスタムルールを適用するには、状況に応じて次のいずれかを実行します:
   - 新しいGitLab Duo Chatのディスカッションを開始します。
   - Chatのディスカッション、イシュー、またはマージリクエストでエージェントを使用します。
   - フローをトリガーします。

特定の環境変数を設定している場合、カスタムルールファイルは別の場所に作成します:

- `GLAB_CONFIG_DIR`環境変数を設定している場合、`$GLAB_CONFIG_DIR/chat-rules.md`にファイルを作成します。
- `XDG_CONFIG_HOME`環境変数を設定している場合、`$XDG_CONFIG_HOME/gitlab/duo/chat-rules.md`にファイルを作成します。

### ワークスペースレベルのカスタムルールを作成する {#create-workspace-level-custom-rules}

ワークスペースレベルのカスタムルールは、特定のプロジェクトまたはワークスペースにのみ適用されます。この方法を使用すると、チームのプロジェクトに一連のカスタムルールを適用できます。例えば、チームが使用する開発スタイルガイドのセットを適用できます。

1. IDEワークスペースで、カスタムルールファイル`.gitlab/duo/chat-rules.md`を作成します。
1. カスタムルールをファイルに追加します。例: 

   ```markdown
   - Don't put comments in the generated code
   - Be brief in your explanations
   - Always use single quotes for JavaScript strings
   ```

1. ファイルを保存します。
1. プロジェクトの場合: `.gitlab/duo/chat-rules.md`ファイルをGitリポジトリに追加します。Chat、エージェント、およびフローは、リポジトリからコンテキストにカスタムルールを自動的に読み込みます。
1. 新しいカスタムルールを適用するには、GitLab Duoの新しい会話を開始します。

   カスタムルールを変更するたびに、これを行う必要があります。

詳細については、[GitLab Duo Chatでのカスタムルールチュートリアルブログ](https://about.gitlab.com/blog/custom-rules-duo-agentic-chat-deep-dive/)を参照してください。

## カスタムルールを更新する {#update-custom-rules}

カスタムルールを更新するには、カスタムルールファイルを編集して保存します。次に、新しいGitLab Duoの会話を開始して、更新されたルールを適用します。

Chatを使用してカスタムルールファイルを直接編集することはできません。

カスタムルールへの変更を承認する必要があるユーザーを管理するには、[コードオーナー](../../project/codeowners/_index.md)を使用します。

## 関連トピック {#related-topics}

- [AGENTS.mdカスタマイズファイル](agents_md.md)
- [Agent Skills](agent_skills.md)
