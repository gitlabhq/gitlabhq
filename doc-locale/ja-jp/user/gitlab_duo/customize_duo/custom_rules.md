---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: カスタムルール
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- カスタムルールがGitLab 18.2で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/550743)されました。
- GitLab 18.7でユーザーレベルのカスタムルールが[追加](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2452)されました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

カスタムルールを使用して、IDEでのすべての会話でGitLab Duo Chatが従う指示を指定します。カスタムルールは、GitLab Duo Chatでのみ使用できます。

## カスタムルールを作成する {#create-custom-rules}

カスタムルールは、次の2つのレベルで作成できます:

- ユーザーレベルのルール: すべてのプロジェクトとワークスペースに適用されます。
- ワークスペースレベルのルール: 特定のプロジェクトまたはワークスペースにのみ適用されます。

ユーザーレベルとワークスペースレベルの両方のルールが存在する場合、GitLab Duo Chatは両方を会話に適用します。

前提条件: 

- VS Codeの場合は、バージョン6.32.2以降の[VS Code用GitLab Workflow拡張機能をインストールして設定](../../../editor_extensions/visual_studio_code/setup.md)します。
- JetBrains IDEの場合は、バージョン3.12.2以降の[JetBrains用GitLabプラグインをインストールして設定](../../../editor_extensions/jetbrains_ide/setup.md)します。
- Visual Studioの場合は、バージョン0.60.0以降の[Visual Studio用GitLab拡張機能をインストールして設定](../../../editor_extensions/visual_studio/setup.md)します。

> [!note]カスタムルールを作成する前に存在していた会話は、これらのルールに従いません。

### ユーザーレベルのカスタムルールを作成する {#create-user-level-custom-rules}

ユーザーレベルのカスタムルールは、すべてのプロジェクトとワークスペースに適用されます。

1. ユーザー設定ディレクトリにカスタムルールファイルを作成します:
   - `GLAB_CONFIG_DIR`環境変数を設定している場合は、`$GLAB_CONFIG_DIR/chat-rules.md`にファイルを作成します。
   - それ以外の場合は、プラットフォームのデフォルトの設定ディレクトリにファイルを作成します:
     - macOSまたはLinux:
       - `XDG_CONFIG_HOME`環境変数を使用している場合は、`$XDG_CONFIG_HOME/gitlab/duo/chat-rules.md`にファイルを作成します。
       - それ以外の場合は、ホームディレクトリ内の`~/.gitlab/duo/chat-rules.md`にファイルを作成します。
     - Windows: `%APPDATA%\GitLab\duo\chat-rules.md`
1. カスタムルールをファイルに追加します。例: 

   ```markdown
   - Don't put comments in the generated code
   - Be brief in your explanations
   - Always use single quotes for JavaScript strings
   ```

1. ファイルを保存します。
1. 新しいカスタムルールを適用するには、新しいGitLab Duoの会話を開始します。

   カスタムルールを変更するたびに、これを行う必要があります。

### ワークスペースレベルのカスタムルールを作成する {#create-workspace-level-custom-rules}

ワークスペースレベルのカスタムルールは、特定のプロジェクトまたはワークスペースにのみ適用されます。

1. IDEワークスペースで、カスタムルールファイルを作成します: `.gitlab/duo/chat-rules.md`。
1. カスタムルールをファイルに追加します。例: 

   ```markdown
   - Don't put comments in the generated code
   - Be brief in your explanations
   - Always use single quotes for JavaScript strings
   ```

1. ファイルを保存します。
1. 新しいカスタムルールを適用するには、新しいGitLab Duoの会話を開始します。

   カスタムルールを変更するたびに、これを行う必要があります。

詳細については、[Custom rules in GitLab Duo Agentic Chatのブログ](https://about.gitlab.com/blog/custom-rules-duo-agentic-chat-deep-dive/)を参照してください。

## カスタムルールを更新する {#update-custom-rules}

カスタムルールを更新するには、カスタムルールファイルを編集して保存します。次に、新しいGitLab Duoの会話を開始して、更新されたルールを適用します。

チャットを使用してカスタムルールファイルを直接編集することはできません。

カスタムルールへの変更を承認する必要があるユーザーを管理するには、[コードオーナー](../../project/codeowners/_index.md)を使用します。

## 関連トピック {#related-topics}

- [Agentのカスタマイズファイル](agents_md.md)
