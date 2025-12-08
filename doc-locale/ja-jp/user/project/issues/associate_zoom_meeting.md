---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: イシューにZoomミーティングを関連付けます
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インシデント管理のために同期的に通信するには、Zoomミーティングをイシューに関連付けることができます。緊急対応のためにZoom通話を開始した後、電話会議をイシューに関連付ける方法が必要です。これにより、チームメンバーはリンクをリクエストすることなく、迅速に参加できます。

## イシューへのZoomミーティングの追加 {#adding-a-zoom-meeting-to-an-issue}

イシューにZoomミーティングを関連付けるには、GitLabの[クイックアクション](../quick_actions.md#issues-merge-requests-and-epics)を使用します。

イシューで、`/zoom`クイックアクションを使用し、有効なZoomリンクを続けてコメントを残します:

```shell
/zoom https://zoom.us/j/123456789
```

ZoomミーティングのURLが有効で、少なくともレポーターロールがある場合、システムアラートが正常に追加されたことを通知します。イシューの説明が自動的に編集され、Zoomリンクが含まれ、イシューのタイトルのすぐ下にボタンが表示されます。

![Join Zoom meeting]（Zoomミーティングに参加）ボタンが表示されたGitLabのイシュービュー](img/zoom_quickaction_button_v16_6.png)

1つのZoomミーティングのみをイシューに添付できます。`/zoom`クイックアクションを使用して2回目のZoomミーティングを追加しようとしても、機能しません。最初に[削除](#removing-an-existing-zoom-meeting-from-an-issue)する必要があります。

GitLab PremiumおよびUltimateプランのユーザーは、[インシデントに複数のZoomリンクを追加](../../../operations/incident_management/linked_resources.md#link-zoom-meetings-from-an-incident)することもできます。

## イシューからの既存のZoomミーティングの削除 {#removing-an-existing-zoom-meeting-from-an-issue}

Zoomミーティングの追加と同様に、クイックアクションで削除できます:

```shell
/remove_zoom
```

少なくともレポーターロールがある場合、ミーティングURLが正常に削除されたことを知らせるシステムアラートが表示されます。
