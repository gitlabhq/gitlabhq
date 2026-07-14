---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 通知設定API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、GitLabの通知設定を管理します。詳細については、[通知メール](../user/profile/notifications.md)を参照してください。

## 通知レベル {#notification-levels}

通知レベルは、`NotificationSetting.level`モデルの列挙で定義されています。認識されているレベルは次のとおりです:

- `disabled`: すべての通知をオフにする
- `participating`: 参加したスレッドの通知を受け取る
- `watch`: ほとんどのアクティビティの通知を受け取る
- `global`: グローバル通知設定を使用する
- `mention`: コメントでメンションされたときに通知を受け取る
- `custom`: 選択したイベントの通知を受け取る

`custom`レベルを使用すると、特定のメールイベントを制御できます。利用可能なイベントは`NotificationSetting.email_events`によって返されます。認識されているイベントは次のとおりです:

| イベント                          | 説明 |
| ------------------------------ | ----------- |
| `approver`                     | 承認資格のあるマージリクエストが作成されたとき |
| `change_reviewer_merge_request`| マージリクエストのレビュアーが変更されたとき |
| `close_issue`                  | イシューがクローズされたとき |
| `close_merge_request`          | マージリクエストがクローズされたとき |
| `failed_pipeline`              | パイプラインが失敗したとき |
| `fixed_pipeline`               | 以前に失敗したパイプラインが修正されたとき |
| `issue_due`                    | イシューの期限が明日であるとき |
| `merge_merge_request`          | マージリクエストがマージされたとき |
| `merge_when_pipeline_succeeds` | マージリクエストが自動マージに設定されたとき |
| `moved_project`                | プロジェクトが移動されたとき |
| `new_epic`                     | 新しいエピックが作成されたとき（PremiumおよびUltimate階層の場合） |
| `new_issue`                    | 新しいイシューが作成されたとき |
| `new_merge_request`            | 新しいマージリクエストが作成されたとき |
| `new_note`                     | 誰かがコメントを追加したとき |
| `new_release`                  | 新しいリリースが公開されたとき |
| `push_to_merge_request`        | 誰かがマージリクエストにプッシュしたとき |
| `reassign_issue`               | イシューが再割り当てされたとき |
| `reassign_merge_request`       | マージリクエストが再割り当てされたとき |
| `reopen_issue`                 | イシューが再オープンされたとき |
| `reopen_merge_request`         | マージリクエストが再オープンされたとき |
| `success_pipeline`             | パイプラインが正常に完了したとき |

## グローバル通知設定を取得する {#retrieve-global-notification-settings}

グローバル通知レベルとメールアドレスを取得します。

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
| `notification_email` | 文字列 | 通知の送信先メールアドレス |

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
| `approver`                     | ブール値 | いいえ       | 承認資格のあるマージリクエストが作成されたときに通知をオンにする |
| `change_reviewer_merge_request`| ブール値 | いいえ       | マージリクエストのレビュアーが変更されたときに通知をオンにする |
| `close_issue`                  | ブール値 | いいえ       | イシューがクローズされたときに通知をオンにする |
| `close_merge_request`          | ブール値 | いいえ       | マージリクエストがクローズされたときに通知をオンにする |
| `failed_pipeline`              | ブール値 | いいえ       | パイプラインが失敗したときに通知をオンにする |
| `fixed_pipeline`               | ブール値 | いいえ       | 以前に失敗したパイプラインが修正されたときに通知をオンにする |
| `issue_due`                    | ブール値 | いいえ       | イシューの期限が明日であるときに通知をオンにする |
| `level`                        | 文字列  | いいえ       | グローバル通知レベル |
| `merge_merge_request`          | ブール値 | いいえ       | マージリクエストがマージされたときに通知をオンにする |
| `merge_when_pipeline_succeeds` | ブール値 | いいえ       | マージリクエストが自動マージに設定されたときに通知をオンにする |
| `moved_project`                | ブール値 | いいえ       | プロジェクトが移動されたときに通知をオンにする |
| `new_epic`                     | ブール値 | いいえ       | 新しいエピックが作成されたときに通知をオンにする（PremiumおよびUltimate階層の場合） |
| `new_issue`                    | ブール値 | いいえ       | 新しいイシューが作成されたときに通知をオンにする |
| `new_merge_request`            | ブール値 | いいえ       | 新しいマージリクエストが作成されたときに通知をオンにする |
| `new_note`                     | ブール値 | いいえ       | 新しいコメントが追加されたときに通知をオンにする |
| `new_release`                  | ブール値 | いいえ       | 新しいリリースが公開されたときに通知をオンにする |
| `notification_email`           | 文字列  | いいえ       | 通知の送信先メールアドレス |
| `push_to_merge_request`        | ブール値 | いいえ       | 誰かがマージリクエストにプッシュしたときに通知をオンにする |
| `reassign_issue`               | ブール値 | いいえ       | イシューが再割り当てされたときに通知をオンにする |
| `reassign_merge_request`       | ブール値 | いいえ       | マージリクエストが再割り当てされたときに通知をオンにする |
| `reopen_issue`                 | ブール値 | いいえ       | イシューが再オープンされたときに通知をオンにする |
| `reopen_merge_request`         | ブール値 | いいえ       | マージリクエストが再オープンされたときに通知をオンにする |
| `success_pipeline`             | ブール値 | いいえ       | パイプラインが正常に完了したときに通知をオンにする |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性            | 型   | 説明 |
| -------------------- | ------ | ----------- |
| `level`              | 文字列 | グローバル通知レベル |
| `notification_email` | 文字列 | 通知の送信先メールアドレス |

レスポンス例: 

```json
{
  "level": "watch",
  "notification_email": "admin@example.com"
}
```

## 通知設定を取得する {#retrieve-notification-settings}

指定されたグループまたはプロジェクトの通知レベルを取得します。

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
| `id`      | 整数または文字列 | はい      | グループまたはプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |

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

カスタム通知レベルを持つグループの応答例:

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

- `true`は通知がオンであることを示します。
- `false`は通知がオフであることを示します。
- `null`は通知がデフォルトの設定を使用していることを示します。

> [!note]
> `new_epic`属性は、PremiumおよびUltimate階層でのみ利用可能です。

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
| `approver`                     | ブール値           | いいえ       | 承認資格のあるマージリクエストが作成されたときに通知をオンにする |
| `change_reviewer_merge_request`| ブール値           | いいえ       | マージリクエストのレビュアーが変更されたときに通知をオンにする |
| `close_issue`                  | ブール値           | いいえ       | イシューがクローズされたときに通知をオンにする |
| `close_merge_request`          | ブール値           | いいえ       | マージリクエストがクローズされたときに通知をオンにする |
| `failed_pipeline`              | ブール値           | いいえ       | パイプラインが失敗したときに通知をオンにする |
| `fixed_pipeline`               | ブール値           | いいえ       | 以前に失敗したパイプラインが修正されたときに通知をオンにする |
| `id`                           | 整数または文字列 | はい      | グループまたはプロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `issue_due`                    | ブール値           | いいえ       | イシューの期限が明日であるときに通知をオンにする |
| `level`                        | 文字列            | いいえ       | このグループまたはプロジェクトの通知レベル |
| `merge_merge_request`          | ブール値           | いいえ       | マージリクエストがマージされたときに通知をオンにする |
| `merge_when_pipeline_succeeds` | ブール値           | いいえ       | マージリクエストのパイプラインが成功したときにマージするように設定された場合に通知をオンにする |
| `moved_project`                | ブール値           | いいえ       | プロジェクトが移動されたときに通知をオンにする |
| `new_epic`                     | ブール値           | いいえ       | 新しいエピックが作成されたときに通知をオンにする（PremiumおよびUltimate階層の場合） |
| `new_issue`                    | ブール値           | いいえ       | 新しいイシューが作成されたときに通知をオンにする |
| `new_merge_request`            | ブール値           | いいえ       | 新しいマージリクエストが作成されたときに通知をオンにする |
| `new_note`                     | ブール値           | いいえ       | 新しいコメントが追加されたときに通知をオンにする |
| `new_release`                  | ブール値           | いいえ       | 新しいリリースが公開されたときに通知をオンにする |
| `push_to_merge_request`        | ブール値           | いいえ       | 誰かがマージリクエストにプッシュしたときに通知をオンにする |
| `reassign_issue`               | ブール値           | いいえ       | イシューが再割り当てされたときに通知をオンにする |
| `reassign_merge_request`       | ブール値           | いいえ       | マージリクエストが再割り当てされたときに通知をオンにする |
| `reopen_issue`                 | ブール値           | いいえ       | イシューが再オープンされたときに通知をオンにする |
| `reopen_merge_request`         | ブール値           | いいえ       | マージリクエストが再オープンされたときに通知をオンにする |
| `success_pipeline`             | ブール値           | いいえ       | パイプラインが正常に完了したときに通知をオンにする |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と、以下のいずれかの応答形式が返されます。

カスタムではない通知レベルの場合:

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

- `true`は通知がオンであることを示します。
- `false`は通知がオフであることを示します。
- `null`は通知がデフォルトの設定を使用していることを示します。

> [!note]
> `new_epic`属性は、PremiumおよびUltimate階層でのみ利用可能です。
