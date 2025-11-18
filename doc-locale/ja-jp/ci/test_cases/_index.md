---
stage: Plan
group: Product Planning
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのテストケースは、既存の開発プラットフォームでテストシナリオを作成するのに役立ちます。
title: テストケース
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

テストケースは、テスト計画をGitLabのワークフローに直接統合します。チームは次のことができます:

- コードを管理するのと同じプラットフォームでテストシナリオをドキュメント化する。
- 開発タスクとともにテスト要件を追跡する。
- 実装チームとテストチーム間でテスト計画を共有する。
- 非公開設定でテストケースの表示レベルを管理する。
- 必要に応じて、テストケースをアーカイブまたは再オープンする。

チームはテストケースを使用することで、開発チームとテストチーム間のコラボレーションを効率化し、外部のテスト計画ツールが不要になります。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>開発ワークフローと統合しながら、イシューとエピックを使用して要件やテストニーズを管理する方法については、[Streamline Software Development: Integrating Requirements, Testing, and Development Workflows](https://www.youtube.com/watch?v=wbfWM4y2VmM)（ソフトウェア開発の効率化: 要件、テスト、開発ワークフローの統合）を参照してください。
<!-- Video published on 2024-02-21 -->

## テストケースを作成する {#create-a-test-case}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

前提要件:

- プランナー以上のロールが必要です。

GitLabプロジェクトでテストケースを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **テストケース**を選択します。
1. **新規テストケース**を選択します。新しいテストケースのフォームが表示されます。ここでは、新しいケースのタイトルと[説明](../../user/markdown.md)を入力し、ファイルを添付して、[ラベル](../../user/project/labels.md)を割り当てることができます。
1. **テストケースを送信する**を選択します。新しいテストケースが表示されます。

## テストケースを表示する {#view-a-test-case}

プロジェクト内のすべてのテストケースは、テストケースリストで確認できます。ラベルやテストケースのタイトルなど、検索クエリを使用してイシューリストをフィルタリングできます。

前提要件:

- 公開プロジェクト内の非公開でないテストケース: プロジェクトのメンバーである必要はありません。
- プライベートプロジェクト内の非公開でないテストケース: プロジェクトのゲストロール以上が必要です。
- 非公開テストケース（プロジェクトの表示レベルに関係なく）: プロジェクトのプランナーロール以上が必要です。

テストケースを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **テストケース**を選択します。
1. 表示するテストケースのタイトルを選択します。テストケースのページが表示されます。

![テストケースページの例](img/test_case_show_v13_10.png)

## テストケースを編集する {#edit-a-test-case}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

テストケースのタイトルと説明を編集できます。

前提要件:

- プランナー以上のロールが必要です。
- ゲストロールに降格されたユーザーは、より高いレベルのロールで作成したテストケースを引き続き編集できます。

テストケースを編集するには:

1. [テストケースを表示](#view-a-test-case)します。
1. **タイトルと説明を編集**（{{< icon name="pencil" >}}）を選択します。
1. テストケースのタイトルや説明を編集します。
1. **変更を保存**を選択します。

## テストケースを非公開にする {#make-a-test-case-confidential}

{{< history >}}

- GitLab 16.5で、[新しい](https://gitlab.com/gitlab-org/gitlab/-/issues/422121)テストケースと[既存](https://gitlab.com/gitlab-org/gitlab/-/issues/422120)のテストケースに対して導入されました。
- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

個人情報を含むテストケースで作業している場合は、そのテストケースを非公開に設定できます。

前提要件:

- プランナー以上のロールが必要です。

テストケースを非公開にするには:

- [テストケースを作成](#create-a-test-case)するとき: **公開設定**で、**This test case is confidential**（このテストケースは非公開です）チェックボックスを選択します。
- [テストケースを編集](#edit-a-test-case)するとき: 右側のサイドバーの**公開設定**の横にある**編集**を選択し、**有効にする**を選択します。

新しいテストケースを作成する際、または既存のテストケースを編集する際に、`/confidential`[クイックアクション](../../user/project/quick_actions.md)を使用することもできます。

## テストケースをアーカイブする {#archive-a-test-case}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

テストケースの使用を停止する場合は、アーカイブすることができます。後で[アーカイブされたテストケースを再オープンする](#reopen-an-archived-test-case)ことができます。

前提要件:

- プランナー以上のロールが必要です。

テストケースをアーカイブするには、テストケースのページで、**Archive test case**（テストケースをアーカイブ）を選択します。

アーカイブされたテストケースを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **ビルド** > **テストケース**を選択します。
1. **アーカイブ済み**を選択します。

## アーカイブされたテストケースを再オープンする {#reopen-an-archived-test-case}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

アーカイブされたテストケースを再度使用する場合は、再オープンすることができます。

前提要件:

- プランナー以上のロールが必要です。

アーカイブされたテストケースを再オープンするには:

1. [テストケースを表示](#view-a-test-case)します。
1. **Reopen test case**（テストケースを再オープン）を選択します。
