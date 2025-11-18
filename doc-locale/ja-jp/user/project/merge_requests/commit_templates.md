---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コミットメッセージテンプレートを使用して、GitLabプロジェクトへのコミットに、必要なすべての情報が含まれ、正しくフォーマットされていることを確認します。
title: コミットメッセージテンプレート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabでは、コミットテンプレートを使用して、特定のタイプのコミットのデフォルトのメッセージを作成します。これらのテンプレートは、コミットメッセージが特定の形式に従うように促したり、特定の情報を含めるように促したりします。マージマージリクエストのマージ時に、ユーザーはこれらのテンプレートをオーバーライドできます。

コミットテンプレートの構文は、[レビューの提案](reviews/suggestions.md#configure-the-commit-message-for-applied-suggestions)の構文に似ています。

GitLab Duoは、テンプレートを設定していなくても、[マージコミットメッセージ](duo_in_merge_requests.md#generate-a-merge-commit-message)の生成を支援できます。

## コミットテンプレートを設定する {#configure-commit-templates}

デフォルトのテンプレートに必要な情報が含まれていない場合は、プロジェクトのコミットテンプレートを変更してください。

前提要件: 

- プロジェクトのメンテナーロール以上が必要です。

これを行うには、次の手順に従います。: 

1. 左側のサイドバーで、**Search or go to**（検索または移動先）を選択して、プロジェクトを見つけます。
1. **設定** > **マージリクエスト**を選択します。
1. 作成するテンプレートの種類に応じて、[**マージコミットのメッセージテンプレート**](#default-template-for-merge-commits)または[**スカッシュコミットのメッセージテンプレート**](#default-template-for-squash-commits)までスクロールします。
1. 目的のコミットタイプに対して、デフォルトのメッセージを入力します。静的なテキストと[変数](#supported-variables-in-commit-templates)の両方を使用できます。各テンプレートは500文字に制限されていますが、テンプレートをデータに置き換えた後、最終的なメッセージはより長くなる可能性があります。
1. **Save changes**（変更を保存）を選択します。

## マージコミットのデフォルトテンプレート {#default-template-for-merge-commits}

マージコミットメッセージのデフォルトテンプレートは次のとおりです。: 

```plaintext
Merge branch '%{source_branch}' into '%{target_branch}'

%{title}

%{issues}

See merge request %{reference}
```

## スカッシュコミットのデフォルトテンプレート {#default-template-for-squash-commits}

マージ時に[コミットをスカッシュする](squash_and_merge.md)ようにプロジェクトを設定している場合、GitLabはこのテンプレートを使用してスカッシュコミットメッセージを作成します。:

```plaintext
%{title}
```

## コミットテンプレートでサポートされる変数 {#supported-variables-in-commit-templates}

{{< history >}}

- `local_reference`変数はGitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/199823)されました。
- `source_project_id`変数はGitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128553)されました。
- `merge_request_author`変数はGitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152510)されました。

{{< /history >}}

コミットメッセージテンプレートは、次の変数をサポートしています。:

| 変数                                | 説明                                                                                                                                                                                                                                   | 出力例                                                                                                                                                                                   |
|-----------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `%{source_branch}`                      | マージするブランチの名前。                                                                                                                                                                                                              | `my-feature-branch`                                                                                                                                                                              |
| `%{target_branch}`                      | 変更を適用するブランチの名前。                                                                                                                                                                                               | `main`                                                                                                                                                                                           |
| `%{title}`                              | マージリクエストのタイトル。                                                                                                                                                                                                                   | `Fix tests and translations`                                                                                                                                                                     |
| `%{issues}`                             | 語句`Closes <issue numbers>`を含む文字列。[イシューのクローズパターン](../issues/managing_issues.md#closing-issues-automatically)に一致する、マージリクエストの説明で言及されているすべてのイシューが含まれています。イシューが言及されていない場合は空です。 | `Closes #465, #190 and #400`                                                                                                                                                                     |
| `%{description}`                        | マージリクエストの説明。                                                                                                                                                                                                             | `Merge request description.`<br>`Can be multiline.`                                                                                                                                              |
| `%{reference}`                          | マージリクエストへの参照。                                                                                                                                                                                                               | `group-name/project-name!72359`                                                                                                                                                                  |
| `%{local_reference}`                    | マージリクエストへのローカル参照。                                                                                                                                                                                                         | `!72359`                                                                                                                                                                                         |
| `%{source_project_id}`                  | マージリクエストのソースプロジェクトのID。                                                                                                                                                                                                     | `123`                                                                                                                                                                                            |
| `%{first_commit}`                       | マージリクエストの差分の、最初のコミットのメッセージ全体。                                                                                                                                                                                       | `Update README.md`                                                                                                                                                                               |
| `%{first_multiline_commit}`             | マージコミットではなく、メッセージ本文に複数の行が含まれる最初のコミットのメッセージ全体。すべてのコミットが複数行でない場合のマージリクエストのタイトル。                                                                                   | `Update README.md`<br><br>`Improved project description in readme file.`                                                                                                                         |
| `%{first_multiline_commit_description}` | マージコミットではなく、メッセージ本文に複数行が含まれている最初のコミットの説明（最初の行/タイトルなし）。                                                                                                          | `Improved project description in readme file.`                                                                                                                                                   |
| `%{url}`                                | マージリクエストへの完全なURL。                                                                                                                                                                                                                | `https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1`                                                                                                                                        |
| `%{reviewed_by}`                        | `Reviewed-by` Gitコミットトレーラー形式で、バッチコメントを使用してレビューを送信するユーザーに基づいて、マージリクエストレビュアーの行区切りリスト。                                                                                 | `Reviewed-by: Sidney Jones <sjones@example.com>`<br> `Reviewed-by: Zhang Wei <zwei@example.com>`                                                                                                |
| `%{approved_by}`                        | `Approved-by` Gitコミットトレーラー形式のマージリクエスト承認者の行区切りリスト。                                                                                                                                              | `Approved-by: Sidney Jones <sjones@example.com>`<br> `Approved-by: Zhang Wei <zwei@example.com>`                                                                                                |
| `%{merged_by}`                          | マージリクエストをマージしたユーザー。                                                                                                                                                                                                            | `Alex Garcia <agarcia@example.com>`                                                                                                                                                              |
| `%{merge_request_author}`               | マージリクエストの作成者の名前とメール。                                                                                                                                                                                                   | `Zane Doe <zdoe@example.com>`                                                                                                                                                                    |
| `%{co_authored_by}`                     | `Co-authored-by` Gitコミットトレーラー形式のコミット作成者の名前とメール。マージリクエストの最新の100件のコミットの作成者に制限されています。                                                                                           | `Co-authored-by: Zane Doe <zdoe@example.com>`<br> `Co-authored-by: Blake Smith <bsmith@example.com>`                                                                                            |
| `%{all_commits}`                        | マージリクエスト内のすべてのコミットからのメッセージ。最新の100件のコミットに制限されています。100 KiBを超えるコミット本文とマージコミットメッセージはスキップされます。                                                                                          | `* Feature introduced`<br><br> `This commit implements feature`<br> `Changelog:added`<br><br> `* Bug fixed`<br><br> `* Documentation improved`<br><br>`This commit introduced better docs.` |

空の変数のみを含む行は削除されます。削除された行の前後に空の行がある場合、前の空の行も削除されます。

オープンなマージリクエストでコミットメッセージを編集すると、GitLabはコミットメッセージを自動的に再度更新します。コミットメッセージをプロジェクトテンプレートに復元するには、ページをリロードします。

## 関連トピック {#related-topics}

- [スカッシュとマージ](squash_and_merge.md)。
