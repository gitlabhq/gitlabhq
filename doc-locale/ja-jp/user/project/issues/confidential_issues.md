---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 非公開イシュー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[十分な権限](#who-can-see-confidential-issues)を持つプロジェクトのメンバーのみが表示できる[イシュー](_index.md)です。機密イシューは、オープンソースプロジェクトや企業が、セキュリティ脆弱性を非公開にしたり、サプライズが漏洩するのを防ぐために利用できます。

## イシューを機密にする {#make-an-issue-confidential}

{{< history >}}

- イシューを機密にするための最小ロールが、GitLab 17.7でレポーターからプランナーに[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)。

{{< /history >}}

イシューの作成時または編集時に、イシューを機密にすることができます。

前提要件: 

- 既存のイシューを機密に変換するには、プロジェクトのプランナーロール以上が必要です。
- 機密にしたいイシューに子[タスク](../../tasks.md)がある場合は、まずすべての子タスクを機密にする必要があります。非公開イシューには、非公開の子イシューのみを含めることができます。

### 新しいイシューの場合 {#in-a-new-issue}

新しいイシューを作成する際、テキストエリアのすぐ下に、イシューを非公開としてマークするためのチェックボックスが表示されます。そのチェックボックスをオンにして、**イシューの作成**を選択してイシューを作成します。

プロジェクトで機密イシューを作成すると、**コントリビュートしたプロジェクト**セクションにプロジェクトが表示されます。[プロファイル](../../profile/_index.md)。**コントリビュートしたプロジェクト**には、機密イシューに関する情報は表示されません。プロジェクト名のみが表示されます。

機密イシューを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択します。
1. ドロップダウンリストから**新規イシュー**を選択します。
1. [フィールド](create_issues.md#fields-in-the-new-issue-form)に入力します。
   - **非公開に設定**チェックボックスを選択します。
1. **イシューの作成**を選択します。

### 既存のイシューの場合 {#in-an-existing-issue}

既存のイシューの公開設定を変更するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択します。
1. イシューのタイトルを選択して表示します。
1. 右上隅で、**Issue actions**（{{< icon name="ellipsis_v" >}}）を選択し、次に**非公開に設定**（またはイシューを非機密にする場合は**公開に設定する**）を選択します。

または、`/confidential`[クイックアクション](../quick_actions.md#issues-merge-requests-and-epics)を使用することもできます。

## 非公開イシューを表示できるユーザー {#who-can-see-confidential-issues}

{{< history >}}

- 機密イシューを表示するための最小ロールが、GitLab 17.7でレポーターからプランナーに[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)。

{{< /history >}}

イシューが非公開に設定されている場合、プロジェクトのプランナーロール以上のユーザーのみがイシューにアクセスできます。ゲストロールまたは[最小](../../permissions.md#users-with-minimal-access)ロールを持つユーザーは、変更前に積極的に参加していたとしても、イシューにアクセスできません。

ただし、**Guest role**（ゲストロール）を持つユーザーは非公開イシューを作成できますが、自分で作成したイシューのみを表示できます。

ゲストロールを持つユーザーまたは非メンバーは、イシューに割り当てられている場合、非公開イシューを読み取りできます。ゲストユーザーまたは非メンバーが非公開イシューから割り当てを解除されると、そのイシューを表示できなくなります。

必要な権限を持たないユーザーの検索結果には、非公開イシューは表示されません。

## 機密イシューインジケーター {#confidential-issue-indicators}

機密イシューは、いくつかの点で通常のイシューとは視覚的に異なります。**イシュー**および**イシューボード**ページでは、機密としてマークされたイシューの横に機密（{{< icon name="eye-slash" >}}）アイコンが表示されます。

[十分な権限](#who-can-see-confidential-issues)がない場合、非公開イシューは一切表示できません。

同様に、イシュー内では、イシュー番号のすぐ横に非公開（{{< icon name="eye-slash" >}}）アイコンが表示されます。コメントしているイシューが機密であることを示すインジケーターもコメント領域にあります。

サイドバーにも機密性を示すインジケーターがあります。

標準から非公開へ、またはその逆へのすべての変更は、イシューのコメントのシステムノートに表示されます。例:

- {{< icon name="eye-slash" >}} Jo Garciaが5分前にイシューを非公開にしました
- {{< icon name="eye" >}} Jo Garciaがたった今、イシューを全員に公開しました

## 機密イシューのマージリクエスト {#merge-requests-for-confidential-issues}

公開プロジェクトで機密イシューを作成（および既存のイシューを機密にする）できますが、機密マージリクエストは作成できません。プライベートデータの漏洩を防ぐ[機密イシューのマージリクエスト](../merge_requests/confidential.md)を作成する方法について説明します。

## 関連トピック {#related-topics}

- [機密イシューのマージリクエスト](../merge_requests/confidential.md)
- [エピックを非公開にする](../../group/epics/manage_epics.md#make-an-epic-confidential)
- [内部メモを追加する](../../discussions/_index.md#add-an-internal-note)
- GitLabの[機密マージリクエストのセキュリティプラクティス](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/engineer.md#security-releases-critical-non-critical-as-a-developer)
