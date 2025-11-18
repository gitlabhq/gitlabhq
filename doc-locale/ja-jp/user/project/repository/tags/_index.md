---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Gitタグを使用して、リポジトリの履歴の重要なポイントをマークし、CI/CDパイプラインをトリガーします。
title: タグ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Gitでは、タグはリポジトリの履歴における重要なポイントを示します。Gitは、次の2種類のタグをサポートしています:

- 軽量タグは特定のコミットを指し、他の情報は含まれません。ソフトタグとも呼ばれています。必要に応じて作成したり削除したりできます。
- 注釈付きタグにはメタデータが含まれており、検証のために署名できますが、変更はできません。

タグの作成や削除は、以下を含む自動化のトリガーとして使用できます:

- [Webhook](../../integrations/webhook_events.md#tag-events)を使用して、Slack通知などのアクションを自動化する。
- [リポジトリミラー](../mirror/_index.md)を更新するように通知する。
- [`if: $CI_COMMIT_TAG`](../../../../ci/jobs/job_rules.md#common-if-clauses-with-predefined-variables)でCI/CDパイプラインを実行する。

[リリースを作成](../../releases/_index.md)すると、GitLabはリリースのポイントを示すタグも作成します。多くのプロジェクトでは、注釈付きリリースタグと安定したブランチを組み合わせます。デプロイまたはリリースタグを自動的に設定することを検討してください。

GitLab UIでは、各タグに以下が表示されます:

![単一タグの例](img/tag-display_v18_3.png)

- タグ名（{{< icon name="tag" >}}）
- タグ名をコピー ({{< icon name="copy-to-clipboard" >}})。
- オプション。タグが[保護](../../protected_tags.md)されている場合は、**保護**バッジ。
- コミットSHA（{{< icon name="commit" >}}）。コミットの内容にリンクしています。
- コミットのタイトルと作成日。
- オプション。リリースへのリンク（{{< icon name="rocket" >}}）。
- オプション。パイプラインを実行している場合、現在のパイプラインの状態。
- タグにリンクするソースコードとアーティファクトへのダウンロードリンク。
- [**リリースを作成**](../../releases/_index.md#create-a-release)（{{< icon name="pencil" >}}）リンク。
- タグを削除するためのリンク。

## プロジェクトのタグを表示する {#view-tags-for-a-project}

プロジェクトの既存のタグをすべて表示するには、以下を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **タグ**を選択します。

## コミットリストでタグ付けされたコミットを表示する {#view-tagged-commits-in-the-commits-list}

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **コミット**を選択します。
1. タグ付けされたコミットには、タグアイコン（{{< icon name="tag" >}}）とタグの名前がラベル付けされています。この例は、`v1.26.0`でタグ付けされたコミットを示しています:

   ![コミットビューでタグ付けされたコミット](img/tags_commits_view_v15_10.png)

このタグのコミットのリストを表示するには、タグ名を選択します。

## タグを作成する {#create-a-tag}

タグは、コマンドラインまたはGitLab UIから作成できます。

### コマンドラインから {#from-the-command-line}

コマンドラインから軽量タグまたは注釈付きタグを作成し、アップストリームにプッシュするには、以下を実行します:

1. 軽量タグを作成するには、コマンド`git tag TAG_NAME`を実行し、`TAG_NAME`を希望するタグ名に変更します。
1. 注釈付きタグを作成するには、コマンドラインから`git tag`のいずれかのバージョンを実行します:

   ```shell
   # In this short version, the annotated tag's name is "v1.0",
   # and the message is "Version 1.0".
   git tag -a v1.0 -m "Version 1.0"

   # Use this version to write a longer tag message
   # for annotated tag "v1.0" in your text editor.
   git tag -a v1.0
   ```

1. `git push origin --tags`を使用して、タグをアップストリームにプッシュします。

### UIから作成する {#from-the-ui}

GitLab UIからタグを作成するには、以下を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **タグ**を選択します。
1. **新しいタグ**を選択します。
1. **タグ名**を入力します。
1. **作成元**で、既存のブランチ名、タグ、またはコミットSHAを選択します。
1. オプション。**メッセージ**を追加して注釈付きタグを作成するか、空白のままにして軽量タグを作成します。
1. **タグを作成**を選択します。

## タグに名前を付ける {#name-your-tag}

Gitは[タグ名のルール](https://git-scm.com/docs/git-check-ref-format)を適用して、タグ名が他のツールとの互換性を維持できるようにします。GitLabはタグ名に追加の要件を設定し、適切に構造化されたタグ名に対してメリットを提供しています。

GitLabは、すべてのタグに対して次の追加のルールを適用します:

- タグ名にはスペースを使用できません。
- 40または64の16進文字で始まるタグ名は、Gitのコミットハッシュと似ているため禁止されています。
- タグ名を`-`、`refs/heads/`、`refs/tags/`、`refs/remotes/`で始めることはできません
- タグ名では、大文字と小文字が区別されます。

## タグ名をコピー {#copy-a-tag-name}

クリップボードにタグ名をコピーするには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **コード** > **タグ**を選択します。
1. タグ名の横にある**Tagの名前をコピー** ({{< icon name="copy-to-clipboard" >}}) を選択します。

## タグを削除できないようにする {#prevent-tag-deletion}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザーが`git push`でタグを削除できないようにするには、[プッシュルール](../push_rules.md)を作成します。

## タグからパイプラインをトリガーする {#trigger-pipelines-from-a-tag}

GitLab CI/CDは、パイプライン設定でタグを識別するための定義済み変数[`CI_COMMIT_TAG`](../../../../ci/variables/predefined_variables.md)を提供しています。この変数をジョブのルールやワークフローのルールで使用して、パイプラインがタグによってトリガーされたかどうかをテストできます。

デフォルトでは、CI/CDジョブに特定のルールが設定されていない場合、それらのルールは新しく作成されたタグのタグパイプラインに含まれます。

プロジェクトのCI/CDパイプライン設定用の`.gitlab-ci.yml`ファイルでは、`CI_COMMIT_TAG`変数を使用して、新しいタグのパイプラインを制御できます:

- [`rules:if`](../../../../ci/yaml/_index.md#rulesif)を使用したジョブレベル。
- [`workflow`](../../../../ci/yaml/workflow.md)キーワードを使用したパイプラインレベル。

## タグパイプラインでセキュリティスキャンをトリガーする {#trigger-security-scans-in-tag-pipelines}

デフォルトでは、スキャン実行ポリシーはブランチでのみ実行され、タグでは実行されません。ただし、パイプライン実行ポリシーを設定して、タグでセキュリティスキャンを実行できます。

タグでセキュリティスキャンを実行するには:

1. カスタムジョブが含まれたCI/CD設定YAMLファイルを作成します。このカスタムジョブは、セキュリティスキャナーテンプレートを拡張し、タグで実行するルールを含んでいます。
1. この設定をパイプラインに挿入するパイプライン実行ポリシーを作成します。

### パイプライン実行ポリシーの例 {#example-pipeline-execution-policy}

この例は、依存関係スキャンとSASTスキャンをタグで実行するパイプライン実行ポリシーを作成する方法を示しています:

```yaml
pipeline_execution_policy:
- name: Pipeline Execution Policy
  description: Run security scans on tags
  enabled: true
  pipeline_config_strategy: inject_policy
  content:
    include:
    - project: <Project path to YAML>
      file: tag-security-scans.yml
  skip_ci:
    allowed: false
```

### CI/CD設定の例 {#example-cicd-configuration}

この例は、セキュリティスキャナージョブを拡張してタグで実行する方法を示しています:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml
  - template: Jobs/SAST.gitlab-ci.yml

# Extend dependency scanning to run on tags
gemnasium-python-dependency_scanning_tags:
  extends: gemnasium-python-dependency_scanning
  rules:
    - if: $CI_COMMIT_TAG

# Extend SAST scanning to run on tags
semgrep-sast_tags:
  extends: semgrep-sast
  rules:
    - if: $CI_COMMIT_TAG

# Example of a custom job that runs only on tags
policy_job_for_tags:
  script:
    - echo "This job runs only on tags"
  rules:
    - if: $CI_COMMIT_TAG

# Example of a job that runs on all pipelines
policy_job_always:
  script:
    - echo "This policy job runs always."
```

## 関連トピック {#related-topics}

- [タグ付け（Gitリファレンスページ）](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
- [保護タグ](../../protected_tags.md)
- [リビジョンを比較する](../compare_revisions.md)
- [タグAPI](../../../../api/tags.md)
