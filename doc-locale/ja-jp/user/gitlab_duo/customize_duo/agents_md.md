---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Agentのカスタマイズファイル
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7でGitLab Duo Chatの`AGENTS.md`のサポートが[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2597)されました。
- エージェント型フローでの`AGENTS.md`のサポートは、GitLab 18.8で[導入](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1509)されました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

GitLab Duoは、AIコーディングアシスタントにコンテキストと指示を提供するための新しい標準である[`AGENTS.md`仕様](https://agents.md/)をサポートしています。

`AGENTS.md`ファイルを使用して、リポジトリ構造、コーディング規則、スタイルガイドライン、ビルドとテストの手順、およびプロジェクトのコンテキストを文書化します。`AGENTS.md`ファイルを指定すると、これらの詳細は、仕様をサポートするGitLab Duoやその他のAIツールで使用できます。

GitLab Duoで使用する`AGENTS.md`ファイルを指定します:

- IDEのGitLab Duo Chat。
- Foundationalおよびカスタムルール。

## GitLab Duoによる`AGENTS.md`ファイルの使用方法 {#how-gitlab-duo-uses-agentsmd-files}

`AGENTS.md`ファイルは、複数のレベルで作成できます:

- ユーザーレベル: すべてのプロジェクトとワークスペースに適用されます。
- ワークスペースレベル: 特定のプロジェクトまたはワークスペースにのみ適用されます。
- サブディレクトリレベル: モノレポ内の特定のプロジェクト、または明確なコンポーネントを持つプロジェクト内の特定のプロジェクトにのみ適用します。

GitLab Duo Chatは、ユーザーレベルおよびワークスペースレベルの`AGENTS.md`ファイルから利用可能な指示をすべての会話に組み込みます。タスクで追加の`AGENTS.md`ファイルを含むディレクトリ内のファイルを操作する必要がある場合、チャットはそれらの指示も適用します。

## GitLab Duoで`AGENTS.md`を使用する {#use-agentsmd-with-gitlab-duo}

> [!note] `AGENTS.md`ファイルを追加または更新した後に作成された新しい会話とフローのみが、新しい指示に従います。以前に存在した会話は対象外です。

### 前提条件 {#prerequisites}

- IDEのGitLab Duo Chatの場合、サポートされているプラグインをインストールします:

  - VS Codeの場合、[VS Code用GitLab Workflow拡張機能6.60以降をインストールして設定します。](../../../editor_extensions/visual_studio_code/setup.md)
  - JetBrains IDEの場合は、[JetBrains用GitLabプラグイン](../../../editor_extensions/jetbrains_ide/setup.md) 3.26.0以降をインストールして設定します。

- カスタムルールの場合は、executorから渡される`user_rule`コンテキストにアクセスするように、フローの設定ファイルを更新します:

  ```yaml
  components:
  - name: "my_agent"
     type: AgentComponent
     prompt_id: "my_prompt"
     inputs:
     - from: "context:inputs.user_rule"
        as: "agents_dot_md"
      optional: true
  ```

  `optional: true`を設定することにより、フローは`AGENTS.md`ファイルが存在しない場合でも正常に処理できます。エージェントは、追加のコンテキストの有無にかかわらず動作します。

### ユーザーレベルの`AGENTS.md`ファイルを作成する {#create-user-level-agentsmd-files}

ユーザーレベルの`AGENTS.md`ファイルは、すべてのプロジェクトとワークスペースに適用されます。

1. ユーザー設定ディレクトリに、`AGENTS.md`ファイルを作成します:
   - `GLAB_CONFIG_DIR`環境変数を設定している場合は、`$GLAB_CONFIG_DIR/AGENTS.md`にファイルを作成します。
   - それ以外の場合は、プラットフォームのデフォルトの設定ディレクトリにファイルを作成します:
     - macOSまたはLinux:
       - `XDG_CONFIG_HOME`環境変数を使用している場合は、`$XDG_CONFIG_HOME/gitlab/duo/AGENTS.md`にファイルを作成します。
       - それ以外の場合は、ホームディレクトリ内の`~/.gitlab/duo/AGENTS.md`にファイルを作成します。
     - Windows: `%APPDATA%\GitLab\duo\AGENTS.md`
1. ファイルに手順を追加します。例: 

   {{< tabs >}}

   {{< tab title="個人的な好み" >}}

   ```markdown
   # My personal coding preferences

   - Always explain code changes in simple terms for beginners
   - Use descriptive variable names
   - Add comments for complex logic
   - Prefer functional programming patterns when appropriate
   ```

   {{< /tab >}}

   {{< tab title="チーム標準" >}}

   ```markdown
   # Team coding standards

   - Follow our company's style guide for all code
   - Use TypeScript strict mode
   - Write unit tests for all new functions
   - Document all public APIs with JSDoc
   ```

   {{< /tab >}}

   {{< tab title="モノレポコンテキスト" >}}

   ```markdown
   # Monorepo context

   - This is a monorepo with multiple services
   - Frontend code is in /apps/web
   - Backend services are in /services
   - Shared libraries are in /packages
   - Follow the architecture decision records in /docs/adr
   ```

   {{< /tab >}}

   {{< tab title="セキュリティガイドライン" >}}

   ```markdown
   # Security review guidelines

   - Always validate user input
   - Use parameterized queries for database operations
   - Implement proper authentication and authorization
   - Follow OWASP security best practices
   - Never log sensitive information
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. ファイルを保存します。
1. 指示を適用するには、新しい会話またはフローを開始します。`AGENTS.md`ファイルを変更するたびにこれを行う必要があります。

### ワークスペースレベルの`AGENTS.md`ファイルを作成する {#create-workspace-level-agentsmd-files}

ワークスペースレベルの`AGENTS.md`ファイルは、特定のプロジェクトまたはワークスペースにのみ適用されます。

1. プロジェクトのワークスペースのルートで、`AGENTS.md`ファイルを作成します。
1. ファイルに手順を追加します。例: 

   ```markdown
   # Project-specific guidelines

   - This project uses React with TypeScript
   - Follow the component structure in /src/components
   - Use our custom hooks from /src/hooks
   - State management uses Redux Toolkit
   ```

1. ファイルを保存します。
1. 指示を適用するには、新しい会話またはフローを開始します。`AGENTS.md`ファイルを変更するたびにこれを行う必要があります。

### モノレポおよびサブディレクトリに`AGENTS.md`ファイルを作成する {#create-agentsmd-files-in-monorepos-and-subdirectories}

モノレポまたは明確なコンポーネントを持つプロジェクトの場合は、サブディレクトリに`AGENTS.md`ファイルを配置して、コードベースのさまざまな部分にコンテキスト固有の指示を提供できます。

GitLab Duo Chatがサブディレクトリに追加の`AGENTS.md`ファイルを検出すると、そのディレクトリ内のファイルを編集する前に、関連ファイルを読み取ります。例: 

```plaintext
/my-project
  AGENTS.md              # Root instructions (included in all conversations)
  /frontend
    AGENTS.md            # Frontend-specific instructions
  /backend
    AGENTS.md            # Backend-specific instructions
```

この例では: 

- ルート`AGENTS.md`は常に会話に含まれます。
- GitLab Duoが`/frontend`内のファイルを編集する場合、最初に`/frontend/AGENTS.md`を読み取ります。
- GitLab Duoが`/backend`内のファイルを編集する場合、最初に`/backend/AGENTS.md`を読み取ります。

このアプローチは、GitLab Duoがプロジェクトの各部分に適切な規則に確実に従うのに役立ちます。

サブディレクトリで`AGENTS.md`を使用するには:

1. プロジェクトのサブディレクトリに、`AGENTS.md`ファイルを作成します。
1. そのディレクトリに固有の指示を追加します。たとえば、バックエンドサービスの場合:

   ```markdown
   # Backend service guidelines

   - This service uses Node.js with Express
   - Follow RESTful API conventions
   - Use async/await for asynchronous operations
   - Validate all inputs with Joi schemas
   ```

1. ファイルを保存します。
1. 指示を適用するには、そのディレクトリ内のファイルを含む新しい会話を開始します。`AGENTS.md`ファイルを変更するたびにこれを行う必要があります。

## 関連トピック {#related-topics}

- [カスタムルール](custom_rules.md)
