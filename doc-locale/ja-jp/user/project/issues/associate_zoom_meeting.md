---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Zoomミーティングをイシューに関連付ける
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インシデント管理のため同期的にコミュニケーションをとるには、Zoomミーティングをイシューに関連付けることができます。緊急対応のためにZoom通話を開始した後、電話会議をイシューに関連付ける方法が必要です。これにより、チームメンバーはリンクをリクエストすることなく、迅速に参加できます。

## Zoomミーティングをイシューに追加する {#adding-a-zoom-meeting-to-an-issue}

Zoomミーティングをイシューに関連付けるには、[`/zoom`クイックアクション](../quick_actions.md#zoom)を使用できます。

イシューで、`/zoom`クイックアクションの後に有効なZoomリンクを付けてコメントを残します:

```shell
/zoom https://zoom.us/j/123456789
```

ZoomミーティングのURLが有効で、レポーター、デベロッパー、メンテナー、またはオーナーのロールを持っている場合、システムアラートが正常な追加を通知します。イシューの説明は、Zoomリンクを含むように自動的に編集され、イシューのタイトルのすぐ下にボタンが表示されます。

![GitLabのイシュー表示で、Join Zoom meeting button](img/zoom_quickaction_button_v16_6.png)

1つのイシューに添付できるZoomミーティングは1つだけです。`/zoom`クイックアクションを使用して2つ目のZoomミーティングを追加しようとすると、機能しません。まず、[削除する](#removing-an-existing-zoom-meeting-from-an-issue)必要があります。

GitLab PremiumおよびUltimateのユーザーは、[インシデントに複数のZoomリンクを追加する](../../../operations/incident_management/linked_resources.md#link-zoom-meetings-from-an-incident)こともできます。

## 既存のZoomミーティングをイシューから削除する {#removing-an-existing-zoom-meeting-from-an-issue}

Zoomミーティングを追加するのと同様に、クイックアクションで削除できます:

```shell
/remove_zoom
```

[`/remove_zoom`クイックアクション](../quick_actions.md#remove_zoom)も使用できます。

レポーター、デベロッパー、メンテナー、またはオーナーのロールを持っている場合、システムアラートがミーティングURLが正常に削除されたことを通知します。
