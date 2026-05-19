---
stage: none
group: Tutorials
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'チュートリアル: Webエディタを使用してファイルを編集する'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[プロジェクト](../../user/project/organize_work_with_projects.md)ファイルは、[適切なアクセス権](../../user/project/members/_index.md)を持つチームメンバーが編集できます。

Webエディタを使用して、GitLab UIで個々のファイルを直接編集する方法を学びましょう。

## 編集するファイルを選択する {#select-the-file-you-wish-to-edit}

まず、プロジェクトのホームページに移動し、プロジェクト内のファイルのリストを取得します。

![プロジェクトのホームページのファイルリスト。「Company Handbook」というプロジェクトと「break-room.md」などのファイルが表示されています。](img/project_file_listing_v18_9.png)

ファイルを選択して詳細を表示します。

![「break-room.md」ファイルの詳細が表示されます。その内容には、カード、ビデオゲーム、プールテーブルなどのアメニティが表示されます。](img/file_in_detail_v18_9.png)

## ファイルを編集する {#edit-the-file}

**編集**ドロップダウンリストを選択し、**単一のファイルを編集**を選択します。

![編集ボタンが展開され、「Web IDEで開く」と「単一ファイル編集」のドロップダウンリストオプションが表示されます。](img/edit_dropdown_v18_9.png)

エディタで、必要に応じてファイルを編集します。

![ファイルが編集可能なテキストフィールドに再表示され、閲覧者がその内容を変更できるようになります。](img/edit_file_v18_9.png)

## 変更をコミットしてマージリクエストを作成する {#commit-your-changes-and-create-a-merge-request}

変更をファイルに直接コミット（保存）することも可能です。ただし、ほとんどのチームでは推奨されません。変更をチームメンバーにレビューしてもらうのが良い習慣だからです。このステップでは、新しい変更を含むブランチとマージリクエストを作成します。

編集を終えたら、以下を実行します:

1. **変更をコミットする**を選択します。
1. **コミットメッセージ**テキストボックスに、変更の説明を入力します。
1. **ブランチ**で、**新しいブランチにコミットする**を選択します。
1. **新しいブランチにコミットする**で、新しいブランチの名前を入力するか、自動的に生成された名前をそのまま使用します。
1. **この変更に対するマージリクエストを作成**が選択されていることを確認してください。

![例の値が入力されたコミット変更フォーム。コミットメッセージは「Remove mention of the ping-pong table」、「新しいブランチにコミット」が選択され、ブランチ名は「ping-pong-table-removal」です。](img/commit_changes_v18_9.png)

最後に、**変更をコミットする**を選択して、変更を新しいブランチにコミットします。新しいマージリクエストフォームが表示されます。リクエストを作成するには、以下を実行します:

1. **タイトル**に変更の適切な要約を設定します。
1. **説明**フィールドに変更に関する詳細情報を入力します。
1. **担当者**を自分に設定します。
1. 変更をレビューする必要がある人が分かっている場合は、**レビュアー**を設定します。
1. オプション。マージリクエストの[マイルストーン](../../user/project/milestones/_index.md)を設定します。
1. オプション。マージリクエストにラベルを設定して、より適切に分類します。
1. マージリクエストを作成するには、**マージリクエストを作成**を選択します。

![新しいマージリクエストのフォーム。タイトルは「Remove mention of the ping-pong table」、説明は「This merge request removes the ping-pong table from the break room page since we no longer have one.」と設定されています。](img/merge_request_v18_9.png)

変更はマージリクエストに組み込まれ、他のコントリビューターによるレビューの準備ができています。

## 次の手順 {#next-steps}

次に、以下を実行できます:

- 他の人のマージリクエストをレビューする
- [既存のプロジェクトにイシューを作成](../create_issue_in_existing_project/_index.md)
