---
stage: Growth
group: Engagement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 通知設定API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、GitLabの通知設定を管理します。詳細については、[メール通知](../user/profile/notifications.md)を参照してください。

## 通知レベル {#notification-levels}

通知レベルは、`NotificationSetting.level`モデル列挙で定義されています。認識されるレベルは以下のとおりです:

- `disabled`: すべての通知をオフにする
- `participating`: 参加したスレッドの通知を受信します。
- `watch`: ほとんどのアクティビティーに関する通知を受信します。
- `global`: グローバル通知設定
- `mention`: コメントでメンションされた場合に通知を受信します。
- `custom`: 選択したイベントの通知を受信する

`custom`レベルを使用すると、特定のメールイベントを制御できます。利用可能なイベントは`NotificationSetting.email_events`によって返されます。認識されるイベントは以下のとおりです:

| イベント                          | 説明 |
| ------------------------------ | ----------- |
| `approver`                     | 承認可能なマージリクエストが作成された |
| `change_reviewer_merge_request`| マージリクエストのレビュアーが変更された場合 |
| `close_issue`                  | イシューがクローズされた場合 |
| `close_merge_request`          | マージリクエストが完了した場合 |
| `failed_pipeline`              | パイプラインが失敗した場合 |
| `fixed_pipeline`               | 以前に失敗したパイプラインが修正された場合 |
| `issue_due`                    | イシューの期日が明日である場合 |
| `merge_merge_request`          | マージリクエストがマージされた場合 |
| `merge_when_pipeline_succeeds` | マージリクエストが自動マージに設定されている場合 |
| `moved_project`                | プロジェクトが移動された場合 |
| `new_epic`                     | 新しいエピックが作成された場合（PremiumおよびUltimateプラン） |
| `new_issue`                    | 新しいイシューが作成された場合 |
| `new_merge_request`            | 新しいマージリクエストが作成された場合 |
| `new_note`                     | 誰かがコメントを追加した場合 |
| `new_release`                  | 新しいリリースが公開された場合 |
| `push_to_merge_request`        | 誰かがマージリクエストにプッシュした場合 |
| `reassign_issue`               | イシューが再割り当てされた場合 |
| `reassign_merge_request`       | マージリクエストが再割り当てされた場合 |
| `reopen_issue`                 | イシューが再度オープンされた場合 |
| `reopen_merge_request`         | マージリクエストが再開された場合 |
| `success_pipeline`             | パイプラインが正常に完了した場合 |

## グローバル通知設定を取得 {#get-global-notification-settings}

現在の通知設定とメールアドレスを取得します。

```plaintext
GET /notification_settings
```

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/notification_settings"
```

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性            | 型   | 説明 |
| -------------------- | ------ | ----------- |
| `level`              | 文字列 | グローバル通知レベル |
| `notification_email` | 文字列 | 通知が送信されるメールアドレス |

レスポンス例:

```json
{
  "level": "participating",
  "notification_email": "admin@example.com"
}
```

## グローバル通知設定を更新 {#update-global-notification-settings}

通知設定とメールアドレスを更新します。

```plaintext
PUT /notification_settings
```

リクエスト例:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/notification_settings?level=watch"
```

サポートされている属性は以下のとおりです:

| 属性                      | 型    | 必須 | 説明 |
| ------------------------------ | ------- | -------- | ----------- |
| `approver`                     | ブール値 | いいえ       | 承認できるマージリクエストが作成された場合に、通知をオンにします |
| `change_reviewer_merge_request`| ブール値 | いいえ       | マージリクエストのレビュアーが変更された場合に、通知をオンにします |
| `close_issue`                  | ブール値 | いいえ       | イシューがクローズされた場合に、通知をオンにします |
| `close_merge_request`          | ブール値 | いいえ       | マージリクエストがクローズされた場合に、通知をオンにします |
| `failed_pipeline`              | ブール値 | いいえ       | パイプラインが失敗した場合に、通知をオンにします |
| `fixed_pipeline`               | ブール値 | いいえ       | 以前に失敗したパイプラインが修正された場合に、通知をオンにします |
| `issue_due`                    | ブール値 | いいえ       | イシューの期日が明日である場合に、通知をオンにします |
| `level`                        | 文字列  | いいえ       | グローバル通知レベル |
| `merge_merge_request`          | ブール値 | いいえ       | マージリクエストがマージされた場合に、通知をオンにします |
| `merge_when_pipeline_succeeds` | ブール値 | いいえ       | マージリクエストが自動マージに設定されている場合に、通知をオンにします |
| `moved_project`                | ブール値 | いいえ       | プロジェクトが移動された場合に、通知をオンにします |
| `new_epic`                     | ブール値 | いいえ       | 新しいエピックが作成された場合に、通知をオンにします（PremiumおよびUltimateプラン） |
| `new_issue`                    | ブール値 | いいえ       | 新しいイシューが作成された場合に、通知をオンにします |
| `new_merge_request`            | ブール値 | いいえ       | 新しいマージリクエストが作成された場合に、通知をオンにします |
| `new_note`                     | ブール値 | いいえ       | 新しいコメントが追加された場合に、通知をオンにします |
| `new_release`                  | ブール値 | いいえ       | 新しいリリースが公開された場合に、通知をオンにします |
| `notification_email`           | 文字列  | いいえ       | 通知が送信されるメールアドレス |
| `push_to_merge_request`        | ブール値 | いいえ       | 誰かがマージリクエストにプッシュした場合に、通知をオンにします |
| `reassign_issue`               | ブール値 | いいえ       | イシューが再割り当てされた場合に、通知をオンにします |
| `reassign_merge_request`       | ブール値 | いいえ       | マージリクエストが再割り当てされた場合に、通知をオンにします |
| `reopen_issue`                 | ブール値 | いいえ       | イシューが再度オープンされた場合に、通知をオンにします |
| `reopen_merge_request`         | ブール値 | いいえ       | マージリクエストが再度オープンされた場合に、通知をオンにします |
| `success_pipeline`             | ブール値 | いいえ       | パイプラインが正常に完了した場合に、通知をオンにします |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性            | 型   | 説明 |
| -------------------- | ------ | ----------- |
| `level`              | 文字列 | グローバル通知レベル |
| `notification_email` | 文字列 | 通知が送信されるメールアドレス |

レスポンス例:

```json
{
  "level": "watch",
  "notification_email": "admin@example.com"
}
```

## グループまたはプロジェクトの通知設定を取得 {#get-group-or-project-notification-settings}

グループまたはプロジェクトの通知設定を取得します。

```plaintext
GET /groups/:id/notification_settings
GET /projects/:id/notification_settings
```

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/notification_settings"
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/8/notification_settings"
```

サポートされている属性は以下のとおりです:

| 属性 | 型              | 必須 | 説明 |
| --------- | ----------------- | -------- | ----------- |
| `id`      | 整数または文字列 | はい      | グループまたはプロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性 | 型   | 説明 |
| --------- | ------ | ----------- |
| `level`   | 文字列 | 通知レベル |

標準通知レベルの応答例:

```json
{
  "level": "global"
}
```

カスタム通知レベルのグループの応答例:

```json
{
  "level": "custom",
  "events": {
    "new_release": null,
    "new_note": null,
    "new_issue": null,
    "reopen_issue": null,
    "close_issue": null,
    "reassign_issue": null,
    "issue_due": null,
    "new_merge_request": null,
    "push_to_merge_request": null,
    "reopen_merge_request": null,
    "close_merge_request": null,
    "reassign_merge_request": null,
    "change_reviewer_merge_request": null,
    "merge_merge_request": null,
    "failed_pipeline": null,
    "fixed_pipeline": null,
    "success_pipeline": null,
    "moved_project": true,
    "merge_when_pipeline_succeeds": false,
    "new_epic": null
  }
}
```

この応答では:

- `true`は、通知がオンになっていることを示します。
- `false`は、通知がオフになっていることを示します。
- `null`は、通知がデフォルト設定を使用していることを示します。

{{< alert type="note" >}}

`new_epic`属性は、PremiumおよびUltimateプランでのみ利用可能です。

{{< /alert >}}

## グループまたはプロジェクトの通知設定を更新 {#update-group-or-project-notification-settings}

グループまたはプロジェクトの通知設定を更新します。

```plaintext
PUT /groups/:id/notification_settings
PUT /projects/:id/notification_settings
```

リクエストの例:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/notification_settings?level=watch"
```

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/8/notification_settings?level=custom&new_note=true"
```

サポートされている属性は以下のとおりです:

| 属性                      | 型              | 必須 | 説明 |
| ------------------------------ | ----------------- | -------- | ----------- |
| `approver`                     | ブール値           | いいえ       | 承認できるマージリクエストが作成された場合に、通知をオンにします |
| `change_reviewer_merge_request`| ブール値           | いいえ       | マージリクエストのレビュアーが変更された場合に、通知をオンにします |
| `close_issue`                  | ブール値           | いいえ       | イシューがクローズされた場合に、通知をオンにします |
| `close_merge_request`          | ブール値           | いいえ       | マージリクエストがクローズされた場合に、通知をオンにします |
| `failed_pipeline`              | ブール値           | いいえ       | パイプラインが失敗した場合に、通知をオンにします |
| `fixed_pipeline`               | ブール値           | いいえ       | 以前に失敗したパイプラインが修正された場合に、通知をオンにします |
| `id`                           | 整数または文字列 | はい      | グループまたはプロジェクトのID、または[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_due`                    | ブール値           | いいえ       | イシューの期日が明日である場合に、通知をオンにします |
| `level`                        | 文字列            | いいえ       | このグループまたはプロジェクトの通知レベル |
| `merge_merge_request`          | ブール値           | いいえ       | マージリクエストがマージされた場合に、通知をオンにします |
| `merge_when_pipeline_succeeds` | ブール値           | いいえ       | マージリクエストのパイプラインが成功した場合にマージされるように設定されている場合に、通知をオンにします |
| `moved_project`                | ブール値           | いいえ       | プロジェクトが移動された場合に、通知をオンにします |
| `new_epic`                     | ブール値           | いいえ       | 新しいエピックが作成された場合に、通知をオンにします（PremiumおよびUltimateプラン） |
| `new_issue`                    | ブール値           | いいえ       | 新しいイシューが作成された場合に、通知をオンにします |
| `new_merge_request`            | ブール値           | いいえ       | 新しいマージリクエストが作成された場合に、通知をオンにします |
| `new_note`                     | ブール値           | いいえ       | 新しいコメントが追加された場合に、通知をオンにします |
| `new_release`                  | ブール値           | いいえ       | 新しいリリースが公開された場合に、通知をオンにします |
| `push_to_merge_request`        | ブール値           | いいえ       | 誰かがマージリクエストにプッシュした場合に、通知をオンにします |
| `reassign_issue`               | ブール値           | いいえ       | イシューが再割り当てされた場合に、通知をオンにします |
| `reassign_merge_request`       | ブール値           | いいえ       | マージリクエストが再割り当てされた場合に、通知をオンにします |
| `reopen_issue`                 | ブール値           | いいえ       | イシューが再度オープンされた場合に、通知をオンにします |
| `reopen_merge_request`         | ブール値           | いいえ       | マージリクエストが再度オープンされた場合に、通知をオンにします |
| `success_pipeline`             | ブール値           | いいえ       | パイプラインが正常に完了した場合に、通知をオンにします |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、次のいずれかのレスポンス形式を返します。

カスタム以外の通知レベルの場合:

```json
{
  "level": "watch"
}
```

カスタム通知レベルの場合、応答には各通知のステータスを示す`events`オブジェクトが含まれます:

```json
{
  "level": "custom",
  "events": {
    "new_release": null,
    "new_note": true,
    "new_issue": false,
    "reopen_issue": null,
    "close_issue": null,
    "reassign_issue": null,
    "issue_due": null,
    "new_merge_request": null,
    "push_to_merge_request": null,
    "reopen_merge_request": null,
    "close_merge_request": null,
    "reassign_merge_request": null,
    "change_reviewer_merge_request": null,
    "merge_merge_request": null,
    "failed_pipeline": false,
    "fixed_pipeline": null,
    "success_pipeline": null,
    "moved_project": false,
    "merge_when_pipeline_succeeds": false,
    "new_epic": null
  }
}
```

この応答では:

- `true`は、通知がオンになっていることを示します。
- `false`は、通知がオフになっていることを示します。
- `null`は、通知がデフォルト設定を使用していることを示します。

{{< alert type="note" >}}

`new_epic`属性は、PremiumおよびUltimateプランでのみ利用可能です。

{{< /alert >}}
