---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: URLとZoom会議のクイックアクションの使用方法など、GitLabインシデントでリンクされたリソースを表示および更新します。
title: インシデントでリンクされたリソース
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.3で`incident_resource_links_widget`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/230852)されました。デフォルトでは無効になっています。
- GitLab 15.3の[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/364755)で有効になりました。
- GitLab 15.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/364755)になりました。機能フラグ`incident_resource_links_widget`は削除されました。

{{< /history >}}

チームメンバーが多くのコメントを検索しなくても重要なリンクを見つけられるように、リンクされたリソースをインシデントイシューに追加できます。

リンクしたいリソース:

- インシデントSlackチャンネル
- Zoom会議
- インシデントを解決するためのリソース

## インシデントのリンクされたリソースを表示する {#view-linked-resources-of-an-incident}

インシデントにリンクされたリソースは、**サマリー**タブに表示されます。

![リンクされたリソースリスト](img/linked_resources_list_v15_3.png)

インシデントのリンクされたリソースを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **インシデント**を選択します。
1. インシデントを選択します。

## リンクされたリソースを追加 {#add-a-linked-resource}

インシデントからリンクされたリソースを手動で追加します。

前提要件:

- プロジェクトのレポーターロール以上が必要です。

リンクされたリソースを追加するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **インシデント**を選択します。
1. インシデントを選択します。
1. **リンクされたリソース**セクションで、プラスアイコン（{{< icon name="plus-square" >}}）を選択します。
1. 必要なフィールドをすべて入力します。
1. **追加**を選択します。

### クイックアクションを使用する {#using-a-quick-action}

{{< history >}}

- GitLab 15.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/374964)。

{{< /history >}}

複数のリンクをインシデントに追加するには、`/link` [クイックアクション](../../user/project/quick_actions.md)を使用します:

```plaintext
/link https://example.link.us/j/123456789
```

リンクと一緒に短い説明を送信することもできます。説明は、インシデントの**リンクされたリソース**セクションのURLの代わりに表示されます:

```plaintext
/link https://example.link.us/j/123456789 multiple alerts firing
```

### インシデントからZoom会議をリンクする {#link-zoom-meetings-from-an-incident}

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/230853)されました。

{{< /history >}}

`/zoom` [クイックアクション](../../user/project/quick_actions.md)を使用して、複数のZoomリンクをインシデントに追加します:

```plaintext
/zoom https://example.zoom.us/j/123456789
```

リンクと一緒に短いオプションの説明を送信することもできます。説明は、インシデントイシューの**リンクされたリソース**セクションのURLの代わりに表示されます:

```plaintext
/zoom https://example.zoom.us/j/123456789 Low on memory incident
```

## リンクされたリソースを削除 {#remove-a-linked-resource}

リンクされたリソースを削除することもできます。

前提要件:

- プロジェクトのレポーターロール以上が必要です。

リンクされたリソースを削除するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **インシデント**を選択します。
1. インシデントを選択します。
1. **リンクされたリソース**セクションで、**削除**（{{< icon name="close" >}}）を選択します。
