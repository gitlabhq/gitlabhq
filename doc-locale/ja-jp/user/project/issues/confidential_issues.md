---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 非公開イシュー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

機密[イシュー](_index.md)は、[十分な権限](#who-can-see-confidential-issues)を持つプロジェクトメンバーにのみ表示されます。機密イシューは、オープンソースプロジェクトや企業がセキュリティの脆弱性を非公開に保ったり、予期せぬ情報漏洩を防いだりするために使用できます。

## イシューを非公開にする {#make-an-issue-confidential}

{{< history >}}

- イシューを非公開にするための最小ロールが、レポーターからプランナーにGitLab 17.7で[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

イシューを作成または編集する際に、イシューを非公開にできます。

前提条件: 

- 既存のイシューを非公開にするには、プロジェクトのプランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。
- 機密に設定したいイシューに子[タスク](../../tasks.md)がある場合は、まずすべての子タスクを機密に設定する必要があります。機密イシューには、機密の子イシューのみを含めることができます。

### 新規イシューで {#in-a-new-issue}

新規イシューを作成する際、テキストエリアのすぐ下にあるチェックボックスでイシューを非公開としてマークできます。そのボックスをチェックし、**イシューの作成**を選択してイシューを作成します。

プロジェクトで機密イシューを作成すると、そのプロジェクトはあなたの[プロフィール](../../profile/_index.md)にある**コントリビュートしたプロジェクト**セクションにリストされます。**コントリビュートしたプロジェクト**には、機密イシューに関する情報は表示されず、プロジェクト名のみが表示されます。

機密イシューを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 右上隅で**新規作成**（{{< icon name="plus" >}}）を選択します。
1. ドロップダウンリストから**新規イシュー**を選択します。
1. [フィールド](create_issues.md#fields-in-the-new-issue-form)に入力します。
   - **非公開に設定**チェックボックスを選択します。
1. **イシューを作成**を選択します。

### 既存のイシューで {#in-an-existing-issue}

既存のイシューの機密性を変更するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **計画** > **イシュー**を選択します。
1. イシューのタイトルを選択して表示します。
1. 右上隅で**Issue actions**（{{< icon name="ellipsis_v" >}}）を選択し、次に**非公開に設定**（またはイシューを非機密にする場合は**公開に設定する**）を選択します。

または、[`/confidential`クイックアクション](../quick_actions.md#confidential)を使用することもできます。

## 機密イシューを閲覧できるユーザー {#who-can-see-confidential-issues}

{{< history >}}

- 機密イシューを閲覧するための最小ロールが、レポーターからプランナーにGitLab 17.7で[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

イシューが非公開に設定されると、プロジェクトのプランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールを持つユーザーのみがイシューにアクセスできます。ゲストまたは[Minimal](../../permissions.md#users-with-minimal-access)ロールを持つユーザーは、変更前に積極的に参加していた場合でも、イシューにアクセスできません。

ただし、**Guest role**を持つユーザーは機密イシューを作成できますが、自分が作成したイシューのみを表示できます。

ゲストロールを持つユーザーまたは非メンバーは、イシューに割り当てられている場合、機密イシューを閲覧できます。ゲストユーザーまたは非メンバーが機密イシューから割り当てを解除されると、そのイシューを閲覧できなくなります。

機密イシューは、必要な権限を持たないユーザーの検索結果には表示されません。

## 機密イシューのインジケーター {#confidential-issue-indicators}

機密イシューは、いくつかの点で通常のイシューとは視覚的に異なります。**イシュー**および**イシューボード**のページでは、非公開としてマークされたイシューの横に機密（{{< icon name="eye-slash" >}}）アイコンが表示されます。

[十分な権限](#who-can-see-confidential-issues)がない場合、機密イシューをまったく閲覧できません。

同様に、イシュー内では、イシュー番号のすぐ横に機密（{{< icon name="eye-slash" >}}）アイコンが表示されます。コメントエリアには、コメントしているイシューが非公開であることを示すインジケーターも表示されます。

サイドバーにも機密性を示すインジケーターがあります。

通常のイシューから非公開イシューへの、あるいはその逆のすべての変更は、イシューのコメントにあるシステムノートに示されます。例:

- {{< icon name="eye-slash" >}} Jo Garciaが5分前にイシューを非公開にしました
- {{< icon name="eye" >}} Jo Garciaがたった今、イシューを全員に公開しました

## 機密イシューのマージリクエスト {#merge-requests-for-confidential-issues}

公開プロジェクトで機密イシューを作成（および既存のイシューを機密化）することはできますが、機密マージリクエストを作成することはできません。機密データの漏洩を防ぐ[機密イシューのマージリクエスト](../merge_requests/confidential.md)の作成方法を学びましょう。

## 関連トピック {#related-topics}

- [機密イシューのマージリクエスト](../merge_requests/confidential.md)
- [エピックを非公開にする](../../group/epics/manage_epics.md#make-an-epic-confidential)
- [内部メモを追加する](../../discussions/_index.md#add-an-internal-note)
- GitLabでの[機密マージリクエストに関するセキュリティプラクティス](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/engineer.md#security-releases-critical-non-critical-as-a-developer)
