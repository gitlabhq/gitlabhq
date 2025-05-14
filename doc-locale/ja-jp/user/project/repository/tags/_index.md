---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use Git tags to mark important points in a repository's history, and trigger CI/CD pipelines.
title: タグ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Gitでは、タグはリポジトリの履歴における重要なポイントを示します。Gitは、次の2種類のタグをサポートしています。

- **軽量タグ**は特定のコミットを指し、他の情報は含まれません。ソフトタグとも呼ばれています。必要に応じて作成したり削除したりできます。
- **注釈付きタグ**にはメタデータが含まれており、検証のために署名できますが、変更はできません。

タグの作成や削除は、以下を含む自動化のトリガーとして使用できます。

- [Webhook](../../integrations/webhook_events.md#tag-events)を使用して、Slack通知などのアクションを自動化する。
- [リポジトリミラー](../mirror/_index.md)を更新するように通知する。
- [`if: $CI_COMMIT_TAG`](../../../../ci/jobs/job_rules.md#common-if-clauses-with-predefined-variables)でCI/CDパイプラインを実行する。

[リリースを作成](../../releases/_index.md)すると、GitLabはリリースのポイントを示すタグも作成します。多くのプロジェクトでは、注釈付きリリースタグと安定したブランチを組み合わせます。デプロイまたはリリースタグを自動的に設定することを検討してください。

GitLab UIでは、各タグに以下が表示されます。

![単一タグの例](img/tag-display_v15_9.png)

- タグ名（{{< icon name="tag" >}}）
- （オプション）タグが[保護](../../protected_tags.md)されている場合は、**保護**バッジ。
- コミットSHA（{{< icon name="commit" >}}）。コミットの内容にリンクしています。
- コミットのタイトルと作成日。
- （オプション）リリースへのリンク（{{< icon name="rocket" >}}）。
- （オプション）パイプラインを実行している場合、現在のパイプラインの状態。
- タグにリンクするソースコードとアーティファクトへのダウンロードリンク。
- [**リリースを作成**](../../releases/_index.md#create-a-release)（{{< icon name="pencil" >}}）リンク。
- タグを削除するためのリンク。

## プロジェクトのタグを表示する

プロジェクトの既存のタグをすべて表示するには、以下を実行します。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを検索します。
1. **コード > タグ**を選択します。

## コミットリストでタグ付けされたコミットを表示する

{{< history >}}

- GitLab 15.10[で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/18795)。

{{< /history >}}

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを検索します。
1. **コード > コミット**を選択します。
1. タグ付けされたコミットには、タグアイコン（{{< icon name="tag" >}}）とタグの名前がラベル付けされています。この例は、`v1.26.0`でタグ付けされたコミットを示しています。

   ![コミットビューでタグ付けされたコミット](img/tags_commits_view_v15_10.png)

このタグのコミットのリストを表示するには、タグ名を選択します。

## タグを作成する

タグは、コマンドラインまたはGitLab UIから作成できます。

### コマンドラインから作成する

コマンドラインから軽量タグまたは注釈付きタグを作成し、アップストリームにプッシュするには、以下を実行します。

1. 軽量タグを作成するには、コマンド`git tag TAG_NAME`を実行し、`TAG_NAME`を希望するタグ名に変更します。
1. 注釈付きタグを作成するには、コマンドラインから`git tag`のいずれかのバージョンを実行します。

   ```shell
   # In this short version, the annotated tag's name is "v1.0",
   # and the message is "Version 1.0".
   git tag -a v1.0 -m "Version 1.0"

   # Use this version to write a longer tag message
   # for annotated tag "v1.0" in your text editor.
   git tag -a v1.0
   ```

1. `git push origin --tags`を使用して、タグをアップストリームにプッシュします。

### UIから作成する

GitLab UIからタグを作成するには、以下を実行します。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを検索します。
1. **コード > タグ**を選択します。
1. **新しいタグ**を選択します。
1. **タグ名**を入力します。
1. **作成元**で、既存のブランチ名、タグ、またはコミットSHAを選択します。
1. （オプション）**メッセージ**を追加して注釈付きタグを作成するか、空白のままにして軽量タグを作成します。
1. **タグを作成**を選択します。

## タグに名前を付ける

Gitは[タグ名のルール](https://git-scm.com/docs/git-check-ref-format)を適用して、タグ名が他のツールとの互換性を維持できるようにします。GitLabはタグ名に追加の要件を設定し、適切に構造化されたタグ名に対してメリットを提供しています。

GitLabは、すべてのタグに対して次の追加のルールを適用します。

- タグ名にはスペースを使用できません。
- 40または64の16進文字で始まるタグ名は、Gitのコミットハッシュと似ているため禁止されています。
- タグ名を`-`、`refs/heads/`、`refs/tags/`、`refs/remotes/`で始めることはできません
- タグ名では、大文字と小文字が区別されます。

## タグを削除できないようにする

{{< details >}}

- プラン: Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザーが`git push`でタグを削除できないようにするには、[プッシュルール](../push_rules.md)を作成します。

## タグからパイプラインをトリガーする

GitLab CI/CDは、パイプライン設定でタグを識別するための定義済みの変数[`CI_COMMIT_TAG`](../../../../ci/variables/predefined_variables.md)を提供しています。この変数をジョブのルールやワークフローのルールで使用して、パイプラインがタグによってトリガーされたかどうかをテストできます。

デフォルトでは、CI/CDジョブに特定のルールが設定されていない場合、それらのルールは新しく作成されたタグのタグパイプラインに含まれます。

プロジェクトのCI/CDパイプライン設定用の`.gitlab-ci.yml`ファイルでは、`CI_COMMIT_TAG`変数を使用して、新しいタグのパイプラインを制御できます。

- [`rules:if`](../../../../ci/yaml/_index.md#rulesif)を使用したジョブレベル。
- [`workflow`](../../../../ci/yaml/workflow.md)キーワードを使用したパイプラインレベル。

## 関連トピック

- [タグ付け（Gitリファレンスページ）](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
- [保護タグ](../../protected_tags.md)
- [タグAPI](../../../../api/tags.md)
