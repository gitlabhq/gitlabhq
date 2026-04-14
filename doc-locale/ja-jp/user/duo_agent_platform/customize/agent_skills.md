---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Agent Skills
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- ワークスペースレベルのAgent SkillsのサポートはGitLab 18.10で[追加されました](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/merge_requests/2951)。
- ワークスペースレベルのAgent SkillsのサポートはGitLab for VS Code 6.71.4で追加されました。

{{< /history >}}

GitLab Duoは、[Agent Skills specification](https://agentskills.io/specification)をサポートしています。これはエージェントに新しい機能と専門知識を与えるための新しい仕様です。

Agent Skillsを使用して、特定のフレームワークでテストを作成するなど、特定のタスクに対する特別な知識とワークフローをエージェントに与えます。エージェントは、タスクに遭遇すると関連するスキルを自動的に読み込み、作業中にその情報を使用します。

`SKILL.md`ファイルを指定すると、スキルはGitLab Duo Agent Platformおよびその仕様をサポートする他のすべてのAIツールで利用できるようになります。

GitLab Duoで使用するAgent Skillsを指定します:

- ローカル環境でのGitLab Duo Chat。
- 基本フローおよびカスタムフロー。

## GitLab DuoがAgent Skillsを使用する方法 {#how-gitlab-duo-uses-agent-skills}

エージェントが作業を開始すると、GitLab Duoは利用可能なすべてのスキルのメタデータをエージェントのコンテキストに追加します。エージェントがスキルの説明に一致するタスクに遭遇すると、そのスキルを自動的に読み込み、タスクを完了するために使用します。

GitLab Duoにスキルを使用させるには、名前、ファイルパス、またはスラッシュコマンドで手動で指示することもできます。

## GitLab DuoでAgent Skillsを使用する {#use-agent-skills-with-gitlab-duo}

> [!note]
> 既存の会話とワークフローは、新規または更新されたスキルに自動的にアクセスできません。新しい会話を開始するか、GitLab Duoに名前または相対パスでスキルを読み込むように依頼してください。

### 前提条件 {#prerequisites}

- [Agent Platformの前提条件](../_index.md#prerequisites)を満たしてください。
- ローカル環境のGitLab Duo Chatの場合は、[GitLab for VS Code](../../../editor_extensions/visual_studio_code/setup.md) 6.71.4以降をインストールして設定します。
- カスタムルールの場合は、executorから渡される`workspace_agent_skills`コンテキストにアクセスできるよう、フローの設定ファイルを更新します:

  ```yaml
  components:
  - name: "my_agent"
     type: AgentComponent
     prompt_id: "my_prompt"
     inputs:
     - from: "context:inputs.workspace_agent_skills"
        as: "workspace_agent_skills"
      optional: true
  ```

  `optional: true`を設定することで、ワークフローはエージェントスキルが存在しないケースを適切に処理します。エージェントは、追加のコンテキストの有無にかかわらず動作します。

### ワークスペースレベルのスキルを作成する {#create-workspace-level-skills}

ワークスペースレベルのスキルは、特定のプロジェクトまたはワークスペースに適用されます。それらは、プロジェクトの`skills/<skill-name>/`ディレクトリにある`SKILL.md`ファイルで定義します。

ワークスペースレベルのスキルを作成するには:

1. プロジェクトのワークスペースのルートに、`skills`ディレクトリを作成します。
1. 新しいディレクトリ内に、特定のスキル用の別のディレクトリを作成します。スキル名をディレクトリ名として使用します。
1. `SKILL.md`ファイルを作成し、以下の形式で手順を含めます。`name`および`description`のYAMLフロントマターフィールドは必須です。

   ```markdown
   ---
   name: <skill_name>
   description: <skill_description>
   ---

   <your_instructions_and_context_for_the_skill>
   ```

    例えば、`skills/cosign-blob/SKILL.md`で[cosignを使用してアーティファクトに署名する](../../../ci/yaml/signing_examples.md)スキルです:

    ````markdown
    ---
    name: cosign-blob
    description: Sign artifacts using cosign with local keypairs and Sigstore v3 bundles. Integrate with 1Password for secure key management.
    ---

    ## Cosign Blob Signing

    Sign artifacts locally using cosign with Sigstore v3 bundles for artifact verification and integrity.

    ### Generate a Local Keypair

    Generate a new cosign keypair:

    ```shell
    cosign generate-key-pair
    ```

    This creates two files:
    - `cosign.key` - Private key (encrypted)
    - `cosign.pub` - Public key

    Store the private key securely, preferably in a password manager like 1Password.

    ### Store Private Key in 1Password

    1. Create a new login item in 1Password with:
      - Title: "Duo Skills cosign"
      - Username: (optional)
      - Password: Your cosign private key password

    2. Save the secret reference path (for example, `op://Employee/Duo Skills cosign/password`)

    ### Sign Artifacts with Cosign

    Sign a file and generate a Sigstore v3 bundle:

    ```shell
    COSIGN_PASSWORD=$(op read "op://Employee/Duo Skills cosign/password") \
      timeout -v 4 cosign sign-blob \
        --key ~/.gitlab/duo/cosign.key \
        --bundle <filename>.bundle \
        --new-bundle-format \
        --yes \
        <filename>
    ```

    Replace:
    - `<filename>` with the file to sign (for example, `SKILL.md`)
    - The bundle output will be saved as `<filename>.bundle`

    ### Key Points

    - Use timeout to fail-fast and report the error back to the user.
    - Use `--bundle` with `$file.bundle` format for Sigstore v3 bundles
    - Use `--yes` to skip interactive prompts
    - Use `--new-bundle-format` to output a v3 Sigstore bundle rather than the legacy format
    - Set `COSIGN_PASSWORD` environment variable to avoid password prompts
    - Integrate with 1Password CLI for secure credential management
    - The bundle file contains the signature and can be verified later
    ````

1. ファイルを保存します。
1. 新しい会話またはワークフローを開始します。エージェントのコンテキストの混乱を避けるため、`SKILL.md`ファイルを変更または追加するたびにこれを行う必要があります。

#### スラッシュコマンドとしてスキルを公開する {#expose-skills-as-slash-commands}

カスタムスラッシュコマンドとしてスキルを有効にするには、`SKILL.md`ファイルのYAMLフロントマターのメタデータに`slash-command: enabled`を追加します:

```yaml
---
name: <skill_name>
description: <skill_description>
metadata:
  slash-command: enabled
---
```

メタデータを追加すると、新しいセッションで`/<skill_name>`を使用して、GitLab Duoにスキルを使用するように指示できます。例: `/fix-bugs`。

### スキルを手動で使用する {#use-a-skill-manually}

GitLab Duoに特定のスキルを使用させるには、以下のいずれかの方法を使用します:

- GitLab Duoに、プロンプト内で名前またはファイルパスでスキルを使用するように指示します。
- スキル用のスラッシュコマンドでプロンプトを開始します。

現在のセッションのコンテキストで利用可能なすべてのスキルを一覧表示するには、`/skills`を使用します。

## 関連トピック {#related-topics}

- [カスタムルール](custom_rules.md)
