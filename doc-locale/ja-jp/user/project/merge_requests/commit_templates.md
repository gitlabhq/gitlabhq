---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabプロジェクトへのコミットに必要なすべての情報が含まれ、正しくフォーマットされるように、コミットメッセージテンプレートを使用します。
title: コミットメッセージテンプレート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、特定の種類のコミットのデフォルトメッセージを作成するためにコミットテンプレートを使用します。これらのテンプレートは、コミットメッセージが特定のフォーマットに従うこと、または特定の情報を含むことを奨励します。ユーザーは、マージリクエストをマージする際にこれらのテンプレートをオーバーライドできます。

コミットテンプレートの構文は、[レビューの提案](reviews/suggestions.md#configure-the-commit-message-for-applied-suggestions)の構文に似ています。

GitLab Duoは、テンプレートを設定しなくても[マージコミットメッセージ](duo_in_merge_requests.md#generate-a-merge-commit-message)の生成に役立ちます。

## コミットテンプレートを設定する {#configure-commit-templates}

デフォルトのコミットテンプレートに必要な情報が含まれていない場合は、プロジェクトのコミットテンプレートを変更します。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールを持っている必要があります。

これを行うには、次の手順を実行します:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **マージリクエスト**を選択します。
1. 作成したいテンプレートのタイプに応じて、[**マージコミットのメッセージテンプレート**](#default-template-for-merge-commits)または[**スカッシュコミットのメッセージテンプレート**](#default-template-for-squash-commits)のいずれかにスクロールしてください。
1. 希望するコミットタイプに、デフォルトメッセージを入力します。静的テキストと[変数](#supported-variables-in-commit-templates)の両方を使用できます。各テンプレートは500文字に制限されていますが、データでテンプレートを置き換えた後、最終的なメッセージは長くなる可能性があります。
1. **変更を保存**を選択します。

## マージコミットのデフォルトテンプレート {#default-template-for-merge-commits}

マージコミットメッセージのデフォルトテンプレートは次のとおりです:

```plaintext
Merge branch '%{source_branch}' into '%{target_branch}'

%{title}

%{issues}

See merge request %{reference}
```

## スカッシュコミットのデフォルトテンプレート {#default-template-for-squash-commits}

プロジェクトを[コミットをスカッシュしてマージ](squash_and_merge.md)するように設定している場合、GitLabはこのテンプレートでスカッシュコミットメッセージを作成します:

```plaintext
%{title}
```

## コミットテンプレートでサポートされている変数 {#supported-variables-in-commit-templates}

{{< history >}}

- GitLab 16.1で`local_reference`変数が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/199823)されました。
- GitLab 16.3で`source_project_id`変数が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128553)されました。
- GitLab 17.1で`merge_request_author`変数が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152510)されました。

{{< /history >}}

コミットメッセージテンプレートは次の変数をサポートします:

| 変数                                | 説明                                                                                                                                                                                                                                   | 出力例                                                                                                                                                                                   |
|-----------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `%{source_branch}`                      | マージするブランチ名。                                                                                                                                                                                                              | `my-feature-branch`                                                                                                                                                                              |
| `%{target_branch}`                      | 変更を適用するブランチの名前。                                                                                                                                                                                               | `main`                                                                                                                                                                                           |
| `%{title}`                              | マージリクエストのタイトル。                                                                                                                                                                                                                   | `Fix tests and translations`                                                                                                                                                                     |
| `%{issues}`                             | `Closes <issue numbers>`という句を含む文字列。マージリクエストの説明で言及されているすべてのイシューを、[イシューのクローズパターン](../issues/managing_issues.md#closing-issues-automatically)に一致する形で含みます。イシューが言及されていない場合は空です。 | `Closes #465, #190 and #400`                                                                                                                                                                     |
| `%{description}`                        | マージリクエストの説明。                                                                                                                                                                                                             | `Merge request description.`<br>`Can be multiline.`                                                                                                                                              |
| `%{reference}`                          | マージリクエストへの参照。                                                                                                                                                                                                               | `group-name/project-name!72359`                                                                                                                                                                  |
| `%{local_reference}`                    | マージリクエストへのローカル参照。                                                                                                                                                                                                         | `!72359`                                                                                                                                                                                         |
| `%{source_project_id}`                  | マージリクエストのソースプロジェクトのID。                                                                                                                                                                                                     | `123`                                                                                                                                                                                            |
| `%{first_commit}`                       | マージリクエストの差分の、最初のコミットのメッセージ全体。                                                                                                                                                                                       | `Update README.md`                                                                                                                                                                               |
| `%{first_multiline_commit}`             | マージコミットではなく、メッセージ本文に複数の行が含まれる最初のコミットのメッセージ全体。すべてのコミットが複数行でない場合のマージリクエストのタイトル。                                                                                   | `Update README.md`<br><br>`Improved project description in readme file.`                                                                                                                         |
| `%{first_multiline_commit_description}` | マージコミットではなく、メッセージ本文に複数行がある最初のコミットの説明（最初の行/タイトルなし）。                                                                                                          | `Improved project description in readme file.`                                                                                                                                                   |
| `%{url}`                                | マージリクエストへの完全なURL。                                                                                                                                                                                                                | `https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1`                                                                                                                                        |
| `%{reviewed_by}`                        | バッチコメントを使用してレビューを提出したユーザーに基づいた、マージリクエストのレビュアーの行区切りリスト。`Reviewed-by` Gitコミットトレーラー形式。                                                                                 | `Reviewed-by: Sidney Jones <sjones@example.com>`<br> `Reviewed-by: Zhang Wei <zwei@example.com>`                                                                                                |
| `%{approved_by}`                        | `Approved-by` Gitコミットトレーラー形式のマージリクエスト承認者の行区切りリスト。                                                                                                                                              | `Approved-by: Sidney Jones <sjones@example.com>`<br> `Approved-by: Zhang Wei <zwei@example.com>`                                                                                                |
| `%{merged_by}`                          | マージリクエストをマージしたユーザー。                                                                                                                                                                                                            | `Alex Garcia <agarcia@example.com>`                                                                                                                                                              |
| `%{merge_request_author}`               | マージリクエスト作成者の名前とメールアドレス。                                                                                                                                                                                                   | `Zane Doe <zdoe@example.com>`                                                                                                                                                                    |
| `%{co_authored_by}`                     | `Co-authored-by` Gitコミットトレーラー形式のコミット作成者の名前とメール。マージリクエストの最新の100件のコミットの作成者に制限されています。                                                                                           | `Co-authored-by: Zane Doe <zdoe@example.com>`<br> `Co-authored-by: Blake Smith <bsmith@example.com>`                                                                                            |
| `%{all_commits}`                        | マージリクエスト内のすべてのコミットからのメッセージ。最新の100件のコミットに制限されています。100 KiBを超えるコミット本文とマージコミットメッセージはスキップされます。                                                                                          | `* Feature introduced`<br><br> `This commit implements feature`<br> `Changelog:added`<br><br> `* Bug fixed`<br><br> `* Documentation improved`<br><br>`This commit introduced better docs.` |

空の変数のみを含む行は削除されます。削除された行の前後に空行がある場合、先行する空行も削除されます。

開いているマージリクエストでコミットメッセージを編集すると、GitLabはコミットメッセージを自動的に再度更新します。コミットメッセージをプロジェクトテンプレートに復元するには、ページを再読み込みします。

## 関連トピック {#related-topics}

- [スカッシュしてマージ](squash_and_merge.md)。
