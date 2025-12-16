---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: コメントで頻繁に使用されるテキストのテンプレートをビルドし、それらのテンプレートをプロジェクトまたはグループと共有します。
title: コメントテンプレート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 機能フラグ`saved_replies`は、GitLab 16.0の[GitLab.comとGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119468)。
- GitLab 16.6で[機能フラグ`saved_replies`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123363)は削除されました。
- グループの保存済み返信は、GitLab 16.11で[導入](https://gitlab.com/groups/gitlab-org/-/epics/12669)され、`group_saved_replies_flag`という名前の[フラグ付き](../../administration/feature_flags/_index.md)で提供されました。デフォルトでは無効になっています。
- グループの保存済み返信は、GitLab 16.11のGitLab.comおよびGitLab Self-Managedで[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/440817)になりました。
- グループの保存済み返信は、GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/504028)されました。機能フラグ`group_saved_replies_flag`は削除されました。
- プロジェクトの保存済み返信は、GitLab 17.0で[導入](https://gitlab.com/groups/gitlab-org/-/epics/12669)され、`project_saved_replies_flag`という名前の[フラグ付き](../../administration/feature_flags/_index.md)で提供されました。デフォルトでは有効になっています。
- GitLab 17.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/504028)になりました。機能フラグ`project_saved_replies_flag`は削除されました。

{{< /history >}}

コメントテンプレートを使用すると、次のテキスト領域のテキストを作成および再利用できます:

- マージリクエスト（差分を含む）。
- イシュー（設計管理コメントを含む）。
- エピック。
- 作業アイテム

コメントテンプレートは、マージリクエストを承認して自分自身を割り当て解除するような小さなものから、頻繁に使用するボイラープレートテキストのチャンクのような大きなものまであります:

![コメントテンプレートのドロップダウンリスト](img/group_comment_templates_v16_11.png)

## テキスト領域でコメントテンプレートを使用する {#use-comment-templates-in-a-text-area}

コメントテンプレートのテキストをコメントに含めるには、次の手順に従います:

1. コメントのエディタツールバーで、**コメントテンプレート**（{{< icon name="comment-lines" >}}）を選択します。
1. 目的のコメントテンプレートを選択します。

## コメントテンプレートを作成する {#create-comment-templates}

コメントテンプレートを作成して、自分自身で使用したり、グループのすべてのメンバーと共有したりできます。

自分自身で使用するコメントテンプレートを作成するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. ドロップダウンリストから、**設定**を選択します。
1. 左側のサイドバーで、**コメントテンプレート**（{{< icon name="comment-lines" >}}）を選択します。
1. **新規を追加**を選択します。
1. コメントテンプレートの**名前**を入力します。
1. 返信の**コンテンツ**を入力します。他のGitLabテキスト領域で使用する任意の書式を使用できます。
1. **保存**を選択すると、コメントテンプレートが表示された状態でページがリロードされます。

### グループの場合 {#for-a-group}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

グループのすべてのメンバーと共有されるコメントテンプレートを作成するには、次の手順に従います:

1. コメントのエディタツールバーで、**コメントテンプレート**（{{< icon name="comment-lines" >}}）を選択し、**Manage group comment templates**（グループコメントテンプレート）を管理を選択します。
1. **新規を追加**を選択します。
1. コメントテンプレートの**名前**を入力します。
1. 返信の**コンテンツ**を入力します。他のGitLabテキスト領域で使用する任意の書式を使用できます。
1. **保存**を選択すると、コメントテンプレートが表示された状態でページがリロードされます。

### プロジェクトの場合 {#for-a-project}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

プロジェクトのすべてのメンバーと共有されるコメントテンプレートを作成するには、次の手順に従います:

1. コメントのエディタツールバーで、**コメントテンプレート**（{{< icon name="comment-lines" >}}）を選択し、**Manage project comment templates**（プロジェクトコメントテンプレート）を管理を選択します。
1. **新規を追加**を選択します。
1. コメントテンプレートの**名前**を入力します。
1. 返信の**コンテンツ**を入力します。他のGitLabテキスト領域で使用する任意の書式を使用できます。
1. **保存**を選択すると、コメントテンプレートが表示された状態でページがリロードされます。

## コメントテンプレート {#view-comment-templates}

既存のコメントテンプレートを表示するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. ドロップダウンリストから、**設定**を選択します。
1. 左側のサイドバーで、**コメントテンプレート**（{{< icon name="comment-lines" >}}）を選択します。
1. **コメントテンプレート**までスクロールします。

### グループの場合 {#for-a-group-1}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

1. コメントのエディタツールバーで、**コメントテンプレート**（{{< icon name="comment-lines" >}}）を選択します。
1. **Manage group comment templates**（グループコメントテンプレート）を管理を選択します。

### プロジェクトの場合 {#for-a-project-1}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

1. コメントのエディタツールバーで、**コメントテンプレート**（{{< icon name="comment-lines" >}}）を選択します。
1. **Manage project comment templates**（プロジェクトコメントテンプレート）を管理を選択します。

## コメントテンプレートを編集または削除する {#edit-or-delete-comment-templates}

既存のコメントテンプレートを編集または削除するには、次の手順に従います:

1. 左側のサイドバーで、自分のアバターを選択します。
1. ドロップダウンリストから、**設定**を選択します。
1. 左側のサイドバーで、**コメントテンプレート**（{{< icon name="comment-lines" >}}）を選択します。
1. **コメントテンプレート**までスクロールし、編集するコメントテンプレートを特定します。
1. 編集するには、**編集**（{{< icon name="pencil" >}}）を選択します。
1. 削除するには、**削除**（{{< icon name="remove" >}}）を選択し、ダイアログで再度**削除**を選択します。

### グループの場合 {#for-a-group-2}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

1. コメントのエディタツールバーで、**コメントテンプレート**（{{< icon name="comment-lines" >}}）を選択し、**Manage group comment templates**（グループコメントテンプレート）を管理を選択します。
1. 編集するには、**編集**（{{< icon name="pencil" >}}）を選択します。
1. 削除するには、**削除**（{{< icon name="remove" >}}）を選択し、ダイアログで再度**削除**を選択します。

### プロジェクトの場合 {#for-a-project-2}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

1. コメントのエディタツールバーで、**コメントテンプレート**（{{< icon name="comment-lines" >}}）を選択し、**Manage project comment templates**（プロジェクトコメントテンプレート）を管理を選択します。
1. 編集するには、**編集**（{{< icon name="pencil" >}}）を選択します。
1. 削除するには、**削除**（{{< icon name="remove" >}}）を選択し、ダイアログで再度**削除**を選択します。
