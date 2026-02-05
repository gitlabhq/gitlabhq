---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AGENTS.mdカスタマイズファイル
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.7でGitLab Duo Chatにおける`AGENTS.md`のサポートが[導入](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2597)されました。
- GitLab 18.8でエージェント型フローにおける`AGENTS.md`のサポートが[導入](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1509)されました。
- GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273)になりました。

{{< /history >}}

GitLab Duoは、AIコーディングアシスタントにコンテキストや指示を提供するための新たな標準である[`AGENTS.md`仕様](https://agents.md/)をサポートしています。

`AGENTS.md`ファイルを使用して、リポジトリ構造、コーディング規約、スタイルガイドライン、ビルドおよびテストの手順、プロジェクトのコンテキストを文書化します。`AGENTS.md`ファイルを指定すると、これらの詳細は、この仕様をサポートするGitLab Duoやその他のAIツールで使用できるようになります。

GitLab Duoで使用する`AGENTS.md`ファイルは、次を対象に指定します:

- IDEのGitLab Duo Chat。
- 基本フローおよびカスタムフロー。

## GitLab Duoで`AGENTS.md`ファイルを使用する方法 {#how-gitlab-duo-uses-agentsmd-files}

`AGENTS.md`ファイルは、複数のレベルで作成できます:

- ユーザーレベル: すべてのプロジェクトとワークスペースに適用されます。
- ワークスペースレベル: 特定のプロジェクトまたはワークスペースにのみ適用されます。
- サブディレクトリレベル: モノレポ内の特定のプロジェクトのディレクトリ、または特定のコンポーネントを含むプロジェクト内のディレクトリにのみ適用します。

GitLab Duo Chatは、ユーザーレベルおよびワークスペースレベルの`AGENTS.md`ファイルに含まれる指示を、すべての会話に適用します。タスクの実行にあたって、追加の`AGENTS.md`ファイルを含むディレクトリ内のファイルを操作する必要がある場合、そのファイルに記載された指示も適用します。

## GitLab Duoで`AGENTS.md`を使用する {#use-agentsmd-with-gitlab-duo}

> [!note] `AGENTS.md`ファイルを追加または更新した後に作成された新しい会話およびフローのみが、新しい指示に従います。それ以前に存在していた会話は対象外です。

### 前提条件 {#prerequisites}

- IDEのGitLab Duo Chatの場合、サポートされている拡張機能をインストールします:

  - VS Codeの場合は、6.60以降の[VS Code用GitLab Workflow拡張機能をインストールして設定](../../../editor_extensions/visual_studio_code/setup.md)します。
  - JetBrains IDEの場合は、3.26.0以降の[JetBrains用GitLabプラグインをインストールして設定](../../../editor_extensions/jetbrains_ide/setup.md)します。

- カスタムルールの場合は、executorから渡される`user_rule`コンテキストにアクセスできるよう、フローの設定ファイルを更新します:

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

  `optional: true`を設定することにより、`AGENTS.md`ファイルが存在しない場合でもフローは正常に処理されます。エージェントは、追加のコンテキストの有無にかかわらず動作します。

### ユーザーレベルの`AGENTS.md`ファイルを作成する {#create-user-level-agentsmd-files}

ユーザーレベルの`AGENTS.md`ファイルは、すべてのプロジェクトとワークスペースに適用されます。

1. ユーザー設定ディレクトリに`AGENTS.md`ファイルを作成します:
   - Linux/macOSでは、ホームディレクトリに`~/.gitlab/duo/AGENTS.md`ファイルを作成するか、Windowsでは`%APPDATA%\GitLab\duo\AGENTS.md`ファイルを作成します。
   - `GLAB_CONFIG_DIR`環境変数を設定している場合は、次の場所にファイルを作成します: `$GLAB_CONFIG_DIR/AGENTS.md`
   - `XDG_CONFIG_HOME`環境変数を使用している場合は、次の場所にファイルを作成します: `$XDG_CONFIG_HOME/gitlab/duo/AGENTS.md`
1. ファイルに指示を追加します。例: 

   {{< tabs >}}

   {{< tab title="個人の設定" >}}

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
1. 指示を適用するには、新しい会話またはフローを開始します。`AGENTS.md`ファイルを変更するたびに、これを行う必要があります。

### ワークスペースレベルの`AGENTS.md`ファイルを作成する {#create-workspace-level-agentsmd-files}

ワークスペースレベルの`AGENTS.md`ファイルは、特定のプロジェクトまたはワークスペースにのみ適用されます。

1. プロジェクトのワークスペースのルートで、`AGENTS.md`ファイルを作成します。
1. ファイルに指示を追加します。例: 

   ```markdown
   # Project-specific guidelines

   - This project uses React with TypeScript
   - Follow the component structure in /src/components
   - Use our custom hooks from /src/hooks
   - State management uses Redux Toolkit
   ```

1. ファイルを保存します。
1. 指示を適用するには、新しい会話またはフローを開始します。`AGENTS.md`ファイルを変更するたびに、これを行う必要があります。

### モノレポおよびサブディレクトリに`AGENTS.md`ファイルを作成する {#create-agentsmd-files-in-monorepos-and-subdirectories}

モノレポまたは特定のコンポーネントを含むプロジェクトでは、サブディレクトリに`AGENTS.md`ファイルを配置することで、コードベースのさまざまな部分に応じたコンテキスト固有の指示を提供できます。

GitLab Duo Chatが、サブディレクトリにある追加の`AGENTS.md`ファイルを検出すると、そのディレクトリ内のファイルを編集する前に、関連ファイルを読み取ります。例: 

```plaintext
/my-project
  AGENTS.md              # Root instructions (included in all conversations)
  /frontend
    AGENTS.md            # Frontend-specific instructions
  /backend
    AGENTS.md            # Backend-specific instructions
```

この例では: 

- ルートの`AGENTS.md`は、常に会話に含まれます。
- GitLab Duoが`/frontend`内のファイルを編集する際、最初に`/frontend/AGENTS.md`を読み取ります。
- GitLab Duoが`/backend`内のファイルを編集する際、最初に`/backend/AGENTS.md`を読み取ります。

このアプローチにより、GitLab Duoはプロジェクトの各部分に適した規則に従うようになります。

サブディレクトリで`AGENTS.md`を使用するには:

1. プロジェクトのサブディレクトリに`AGENTS.md`ファイルを作成します。
1. そのディレクトリに固有の指示を追加します。たとえば、バックエンドサービスの場合は次のようになります:

   ```markdown
   # Backend service guidelines

   - This service uses Node.js with Express
   - Follow RESTful API conventions
   - Use async/await for asynchronous operations
   - Validate all inputs with Joi schemas
   ```

1. ファイルを保存します。
1. 指示を適用するには、そのディレクトリ内のファイルが関係する新しい会話を開始します。`AGENTS.md`ファイルを変更するたびに、これを行う必要があります。

## 関連トピック {#related-topics}

- [カスタムルール](custom_rules.md)
