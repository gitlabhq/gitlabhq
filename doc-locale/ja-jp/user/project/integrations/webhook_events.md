---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Webhookイベント
description: "GitLabのWebhookイベントとペイロードのリスト。JSONの例が含まれます。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabを外部アプリケーションに接続し、Webhookを使用してワークフローを自動化します。GitLabで特定のイベントが発生すると、Webhookは詳細情報を含むHTTP POSTリクエストを設定済みのエンドポイントに送信します。手動での介入なしで、コード変更、デプロイ、コメント、その他のアクティビティに反応する自動化されたプロセスをビルドします。

このページには、[プロジェクトWebhook](webhooks.md)と[グループWebhook](webhooks.md#group-webhooks)に対してトリガーされるイベントのリストがあります。

システムWebhookに対してトリガーされるイベントのリストについては、[システムWebhook](../../../administration/system_hooks.md)を参照してください。

## プロジェクトWebhookとグループWebhookの両方に対してトリガーされるイベント {#events-triggered-for-both-project-and-group-webhooks}

| イベントタイプ                                                                    | トリガー |
|-------------------------------------------------------------------------------|---------|
| [コメントイベント](#comment-events)                                              | コミット、マージリクエスト、イシュー、コードスニペットに対して新しいコメントが作成または編集されます。<sup>1</sup> |
| [デプロイメントイベント](#deployment-events)                                        | デプロイメントが開始、成功、失敗、またはキャンセルされます。 |
| [絵文字イベント](#emoji-events)                                                  | 絵文字リアクションが追加または削除されます。 |
| [機能フラグイベント](#feature-flag-events)                                    | 機能フラグがオンまたはオフになります。 |
| [ジョブイベント](#job-events)                                                      | ジョブの状態が変更されます。 |
| [マージリクエストイベント](#merge-request-events)                                  | マージリクエストが作成、編集、マージ、またはクローズされるか、コミットがソースブランチに追加されます。 |
| [マイルストーンイベント](#milestone-events)                                          | マイルストーンが作成、クローズ、再オープン、または削除されました。 |
| [パイプラインイベント](#pipeline-events)                                            | パイプラインの状態が変化します。 |
| [プロジェクトアクセストークンイベントまたはグループアクセストークンイベント](#project-and-group-access-token-events) | プロジェクトアクセストークンまたはグループアクセストークンの有効期限が7日後に切れます。 |
| [プッシュイベント](#push-events)                                                    | プッシュがリポジトリに対して行われます。 |
| [リリースイベント](#release-events)                                              | リリースが作成、編集、または削除されます。 |
| [タグイベント](#tag-events)                                                      | リポジトリでタグが作成または削除されます。 |
| [脆弱性イベント](#vulnerability-events)                                  | 脆弱性が作成または更新されます。 |
| [Wikiページイベント](#wiki-page-events)                                          | Wikiページが作成、編集、または削除されます。 |
| [作業アイテムイベント](#work-item-events)                                          | 新しい作業アイテムが作成されるか、既存の作業アイテムが編集、完了、または再度オープンされます。 |

補足説明:

1. コメントが編集されたときにトリガーされる[コメントイベント](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/127169)は、GitLab 16.11で導入されました。

## グループWebhookに対してのみトリガーされるイベント {#events-triggered-for-group-webhooks-only}

| イベントタイプ                                 | トリガー |
|--------------------------------------------|---------|
| [グループメンバーイベント](#group-member-events) | ユーザーがグループに追加または削除されるか、ユーザーのアクセスレベルまたはアクセスの有効期限が変更されます。 |
| [プロジェクトイベント](#project-events)           | グループ内でプロジェクトが作成または削除されます。 |
| [サブグループイベント](#subgroup-events)         | グループ内でサブグループが作成または削除されます。 |

> [!note]
> 作成者の[GitLabプロフィール](https://gitlab.com/-/user_settings/profile)に公開メールがリストされていない場合、Webhookペイロードの`email`属性には`[REDACTED]`の値が表示されます。

## プッシュイベント {#push-events}

プッシュイベントはリポジトリへのプッシュ時にトリガーされます。ただし、次の場合を除きます。

- タグをプッシュする場合。
- 1回の[`push_event_hooks_limit`](../../../api/settings.md#available-settings)に、デフォルトで4つ以上のブランチの変更が含まれている場合（設定によって異なります）。

一度に20個を超えるコミットをプッシュすると、ペイロードの`commits`属性には、最新の20個のコミットに関する情報のみが含まれます。詳細なコミットデータの読み込み操作はコストがかかるため、パフォーマンス上の理由からこの制限が存在します。`total_commits_count`属性に実際のコミットの数が含まれています。

> [!note]
> 個別のプッシュイベントを作成するか、アクティビティフィードで一括プッシュイベントを作成するかは、個別の設定`push_event_activities_limit`によってGitLabが制御します。詳細については、[プッシュイベントアクティビティ制限](../../../administration/settings/push_event_activities_limit.md)を参照してください。

新しいコミットなしでブランチを作成してプッシュすると、ペイロードの`commits`属性は空になります。

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Push Hook
```

ペイロードの例:

```json
{
  "object_kind": "push",
  "event_name": "push",
  "before": "95790bf891e76fee5e1747ab589903a6a1f80f22",
  "after": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
  "ref": "refs/heads/master",
  "ref_protected": true,
  "checkout_sha": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
  "message": "Hello World",
  "user_id": 4,
  "user_name": "John Smith",
  "user_username": "jsmith",
  "user_email": "john@example.com",
  "user_avatar": "https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80",
  "project_id": 15,
  "project": {
    "id": 15,
    "name": "Diaspora",
    "description": "",
    "web_url": "http://example.com/mike/diaspora",
    "avatar_url": null,
    "git_ssh_url": "git@example.com:mike/diaspora.git",
    "git_http_url": "http://example.com/mike/diaspora.git",
    "namespace": "Mike",
    "visibility_level": 0,
    "path_with_namespace": "mike/diaspora",
    "default_branch": "master",
    "ci_config_path": null,
    "homepage": "http://example.com/mike/diaspora",
    "url": "git@example.com:mike/diaspora.git",
    "ssh_url": "git@example.com:mike/diaspora.git",
    "http_url": "http://example.com/mike/diaspora.git"
  },
  "commits": [
    {
      "id": "b6568db1bc1dcd7f8b4d5a946b0b91f9dacd7327",
      "message": "Update Catalan translation to e38cb41.\n\nSee https://gitlab.com/gitlab-org/gitlab for more information",
      "title": "Update Catalan translation to e38cb41.",
      "timestamp": "2011-12-12T14:27:31+02:00",
      "url": "http://example.com/mike/diaspora/commit/b6568db1bc1dcd7f8b4d5a946b0b91f9dacd7327",
      "author": {
        "name": "Jordi Mallach",
        "email": "jordi@softcatala.org"
      },
      "added": ["CHANGELOG"],
      "modified": ["app/controller/application.rb"],
      "removed": []
    },
    {
      "id": "da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
      "message": "fixed readme",
      "title": "fixed readme",
      "timestamp": "2012-01-03T23:36:29+02:00",
      "url": "http://example.com/mike/diaspora/commit/da1560886d4f094c3e6c9ef40349f7d38b5d27d7",
      "author": {
        "name": "GitLab dev user",
        "email": "gitlabdev@dv6700.(none)"
      },
      "added": ["CHANGELOG"],
      "modified": ["app/controller/application.rb"],
      "removed": []
    }
  ],
  "total_commits_count": 4,
  "push_options": {},
  "repository": {
    "name": "Diaspora",
    "url": "git@example.com:mike/diaspora.git",
    "description": "",
    "homepage": "http://example.com/mike/diaspora",
    "git_http_url": "http://example.com/mike/diaspora.git",
    "git_ssh_url": "git@example.com:mike/diaspora.git",
    "visibility_level": 0
  }
}
```

## タグイベント {#tag-events}

タグイベントは、リポジトリでタグを作成または削除するとトリガーされます。

デフォルトでは、単一のプッシュに3つ以上のタグに対する変更が含まれる場合、このフックは実行されません。この制限は、タグとブランチの両方に適用される`push_event_hooks_limit`設定（デフォルト：`3`）によって制御されます。これを超過した場合、そのプッシュイベントに対してWebhookは一切トリガーされません。

GitLab Self-Managedインスタンスの場合、管理者は[アプリケーション設定API](../../../api/settings.md#available-settings)を使用してこの制限を変更できます。

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Tag Push Hook
```

ペイロードの例:

```json
{
  "object_kind": "tag_push",
  "event_name": "tag_push",
  "before": "0000000000000000000000000000000000000000",
  "after": "82b3d5ae55f7080f1e6022629cdb57bfae7cccc7",
  "ref": "refs/tags/v1.0.0",
  "ref_protected": true,
  "checkout_sha": "82b3d5ae55f7080f1e6022629cdb57bfae7cccc7",
  "message": "Tag message",
  "user_id": 1,
  "user_name": "John Smith",
  "user_username": "jsmith",
  "user_email": "john@example.com",
  "user_avatar": "https://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=8://s.gravatar.com/avatar/d4c74594d841139328695756648b6bd6?s=80",
  "project_id": 1,
  "project": {
    "id": 1,
    "name": "Example",
    "description": "",
    "web_url": "http://example.com/jsmith/example",
    "avatar_url": null,
    "git_ssh_url": "git@example.com:jsmith/example.git",
    "git_http_url": "http://example.com/jsmith/example.git",
    "namespace": "Jsmith",
    "visibility_level": 0,
    "path_with_namespace": "jsmith/example",
    "default_branch": "master",
    "ci_config_path": null,
    "homepage": "http://example.com/jsmith/example",
    "url": "git@example.com:jsmith/example.git",
    "ssh_url": "git@example.com:jsmith/example.git",
    "http_url": "http://example.com/jsmith/example.git"
  },
  "commits": [],
  "total_commits_count": 0,
  "push_options": {},
  "repository": {
    "name": "Example",
    "url": "ssh://git@example.com/jsmith/example.git",
    "description": "",
    "homepage": "http://example.com/jsmith/example",
    "git_http_url": "http://example.com/jsmith/example.git",
    "git_ssh_url": "git@example.com:jsmith/example.git",
    "visibility_level": 0
  }
}
```

## 作業アイテムイベント {#work-item-events}

{{< history >}}

- `object_attributes`の`type`属性は、GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467415)されました。
- エピックのサポートは、GitLab 17.3で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13056)されました。[エピックの新しい外観](../../group/epics/_index.md#epics-as-work-items)を有効にする必要があります。
- エピックのサポートはGitLab 18.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/468310)されました。

{{< /history >}}

作業アイテムイベントは、作業アイテムが作成、編集、完了、または再度オープンされるとトリガーされます。サポートされている作業アイテムのタイプは次のとおりです。

- [エピック](../../group/epics/_index.md)
- [イシュー](../issues/_index.md)
- [タスク](../../tasks.md)
- [インシデント](../../../operations/incident_management/incidents.md)
- [テストケース](../../../ci/test_cases/_index.md)
- [要件](../requirements/_index.md)
- [目標と主な成果（OKR）](../../okrs.md)

イシューと[サービスデスク](../service_desk/_index.md)イシューの場合、`object_kind`は`issue`で、`type`は`Issue`です。他のすべての作業アイテムの場合、`object_kind`フィールドは`work_item`で、`type`は作業アイテムのタイプです。

作業アイテムのタイプが`Epic`の場合、変更のイベントを取得するには、Webhookをグループに登録する必要があります。

ペイロードの`object_attributes.action`に使用できる値は次のとおりです。

- `open`
- `close`
- `reopen`
- `update`

`assignee`キーと`assignee_id`キーは非推奨です。これらのキーには最初の担当者のみが含まれています。

`escalation_status`フィールドと`escalation_policy`フィールドは、[エスカレーション](../../../operations/incident_management/paging.md#paging)をサポートするイシュータイプ（インシデントなど）でのみ使用できます。

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Issue Hook
```

ペイロードの例:

```json
{
  "object_kind": "issue",
  "event_type": "issue",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon",
    "email": "admin@example.com"
  },
  "project": {
    "id": 1,
    "name":"Gitlab Test",
    "description":"Aut reprehenderit ut est.",
    "web_url":"http://example.com/gitlabhq/gitlab-test",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:gitlabhq/gitlab-test.git",
    "git_http_url":"http://example.com/gitlabhq/gitlab-test.git",
    "namespace":"GitlabHQ",
    "visibility_level":20,
    "path_with_namespace":"gitlabhq/gitlab-test",
    "default_branch":"master",
    "ci_config_path": null,
    "homepage":"http://example.com/gitlabhq/gitlab-test",
    "url":"http://example.com/gitlabhq/gitlab-test.git",
    "ssh_url":"git@example.com:gitlabhq/gitlab-test.git",
    "http_url":"http://example.com/gitlabhq/gitlab-test.git"
  },
  "object_attributes": {
    "id": 301,
    "title": "New API: create/update/delete file",
    "assignee_ids": [51],
    "assignee_id": 51,
    "author_id": 51,
    "project_id": 14,
    "created_at": "2013-12-03T17:15:43Z",
    "updated_at": "2013-12-03T17:15:43Z",
    "updated_by_id": 1,
    "last_edited_at": null,
    "last_edited_by_id": null,
    "relative_position": 0,
    "description": "Create new API for manipulations with repository",
    "milestone_id": null,
    "state_id": 1,
    "confidential": false,
    "discussion_locked": true,
    "due_date": null,
    "moved_to_id": null,
    "duplicated_to_id": null,
    "time_estimate": 0,
    "total_time_spent": 0,
    "time_change": 0,
    "human_total_time_spent": null,
    "human_time_estimate": null,
    "human_time_change": null,
    "weight": null,
    "health_status": "at_risk",
    "type": "Issue",
    "iid": 23,
    "url": "http://example.com/diaspora/issues/23",
    "state": "opened",
    "action": "open",
    "severity": "high",
    "escalation_status": "triggered",
    "escalation_policy": {
      "id": 18,
      "name": "Engineering On-call"
    },
    "labels": [{
        "id": 206,
        "title": "API",
        "color": "#ffffff",
        "project_id": 14,
        "created_at": "2013-12-03T17:15:43Z",
        "updated_at": "2013-12-03T17:15:43Z",
        "template": false,
        "description": "API related issues",
        "type": "ProjectLabel",
        "group_id": 41
      }]
  },
  "repository": {
    "name": "Gitlab Test",
    "url": "http://example.com/gitlabhq/gitlab-test.git",
    "description": "Aut reprehenderit ut est.",
    "homepage": "http://example.com/gitlabhq/gitlab-test"
  },
  "assignees": [{
    "name": "User1",
    "username": "user1",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon"
  }],
  "assignee": {
    "name": "User1",
    "username": "user1",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon"
  },
  "labels": [{
    "id": 206,
    "title": "API",
    "color": "#ffffff",
    "project_id": 14,
    "created_at": "2013-12-03T17:15:43Z",
    "updated_at": "2013-12-03T17:15:43Z",
    "template": false,
    "description": "API related issues",
    "type": "ProjectLabel",
    "group_id": 41
  }],
  "changes": {
    "updated_by_id": {
      "previous": null,
      "current": 1
    },
    "updated_at": {
      "previous": "2017-09-15 16:50:55 UTC",
      "current": "2017-09-15 16:52:00 UTC"
    },
    "labels": {
      "previous": [{
        "id": 206,
        "title": "API",
        "color": "#ffffff",
        "project_id": 14,
        "created_at": "2013-12-03T17:15:43Z",
        "updated_at": "2013-12-03T17:15:43Z",
        "template": false,
        "description": "API related issues",
        "type": "ProjectLabel",
        "group_id": 41
      }],
      "current": [{
        "id": 205,
        "title": "Platform",
        "color": "#123123",
        "project_id": 14,
        "created_at": "2013-12-03T17:15:43Z",
        "updated_at": "2013-12-03T17:15:43Z",
        "template": false,
        "description": "Platform related issues",
        "type": "ProjectLabel",
        "group_id": 41
      }]
    }
  }
}
```

## コメントイベント {#comment-events}

{{< history >}}

- `object_attributes.action`プロパティは、GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147856)されました。

{{< /history >}}

コメントイベントは、コミット、マージリクエスト、イシュー、コードスニペットに対して新しいコメントが作成されるか、これらのコメントが編集されるとトリガーされます。

ノートデータは`object_attributes`（`note`や`noteable_type`など）に保存されます。ペイロードには、コメント対象に関する情報が含まれています。たとえば、イシューに関するコメントでは、`issue`キーの下に特定のイシュー情報が含まれています。

使用可能なターゲットの種類は次のとおりです。

- `commit`
- `merge_request`
- `issue`
- `snippet`

ペイロードの`object_attributes.action`に使用できる値は次のとおりです。

- `create`
- `update`

### コミットに関するコメント {#comment-on-a-commit}

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Note Hook
```

ペイロードの例:

```json
{
  "object_kind": "note",
  "event_type": "note",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon",
    "email": "admin@example.com"
  },
  "project_id": 5,
  "project":{
    "id": 5,
    "name":"Gitlab Test",
    "description":"Aut reprehenderit ut est.",
    "web_url":"http://example.com/gitlabhq/gitlab-test",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:gitlabhq/gitlab-test.git",
    "git_http_url":"http://example.com/gitlabhq/gitlab-test.git",
    "namespace":"GitlabHQ",
    "visibility_level":20,
    "path_with_namespace":"gitlabhq/gitlab-test",
    "default_branch":"master",
    "homepage":"http://example.com/gitlabhq/gitlab-test",
    "url":"http://example.com/gitlabhq/gitlab-test.git",
    "ssh_url":"git@example.com:gitlabhq/gitlab-test.git",
    "http_url":"http://example.com/gitlabhq/gitlab-test.git"
  },
  "repository":{
    "name": "Gitlab Test",
    "url": "http://example.com/gitlab-org/gitlab-test.git",
    "description": "Aut reprehenderit ut est.",
    "homepage": "http://example.com/gitlab-org/gitlab-test"
  },
  "object_attributes": {
    "id": 1243,
    "internal": false,
    "note": "This is a commit comment. How does this work?",
    "noteable_type": "Commit",
    "author_id": 1,
    "created_at": "2015-05-17 18:08:09 UTC",
    "updated_at": "2015-05-17 18:08:09 UTC",
    "project_id": 5,
    "attachment":null,
    "line_code": "bec9703f7a456cd2b4ab5fb3220ae016e3e394e3_0_1",
    "commit_id": "cfe32cf61b73a0d5e9f13e774abde7ff789b1660",
    "noteable_id": null,
    "system": false,
    "st_diff": {
      "diff": "--- /dev/null\n+++ b/six\n@@ -0,0 +1 @@\n+Subproject commit 409f37c4f05865e4fb208c771485f211a22c4c2d\n",
      "new_path": "six",
      "old_path": "six",
      "a_mode": "0",
      "b_mode": "160000",
      "new_file": true,
      "renamed_file": false,
      "deleted_file": false
    },
    "action": "create",
    "url": "http://example.com/gitlab-org/gitlab-test/commit/cfe32cf61b73a0d5e9f13e774abde7ff789b1660#note_1243"
  },
  "commit": {
    "id": "cfe32cf61b73a0d5e9f13e774abde7ff789b1660",
    "message": "Add submodule\n\nSigned-off-by: Example User \u003cuser@example.com.com\u003e\n",
    "timestamp": "2014-02-27T10:06:20+02:00",
    "url": "http://example.com/gitlab-org/gitlab-test/commit/cfe32cf61b73a0d5e9f13e774abde7ff789b1660",
    "author": {
      "name": "Example User",
      "email": "user@example.com"
    }
  }
}
```

### マージリクエストに関するコメント {#comment-on-a-merge-request}

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Note Hook
```

ペイロードの例:

```json
{
  "object_kind": "note",
  "event_type": "note",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon",
    "email": "admin@example.com"
  },
  "project_id": 5,
  "project":{
    "id": 5,
    "name":"Gitlab Test",
    "description":"Aut reprehenderit ut est.",
    "web_url":"http://example.com/gitlab-org/gitlab-test",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:gitlab-org/gitlab-test.git",
    "git_http_url":"http://example.com/gitlab-org/gitlab-test.git",
    "namespace":"Gitlab Org",
    "visibility_level":10,
    "path_with_namespace":"gitlab-org/gitlab-test",
    "default_branch":"master",
    "homepage":"http://example.com/gitlab-org/gitlab-test",
    "url":"http://example.com/gitlab-org/gitlab-test.git",
    "ssh_url":"git@example.com:gitlab-org/gitlab-test.git",
    "http_url":"http://example.com/gitlab-org/gitlab-test.git"
  },
  "repository":{
    "name": "Gitlab Test",
    "url": "http://localhost/gitlab-org/gitlab-test.git",
    "description": "Aut reprehenderit ut est.",
    "homepage": "http://example.com/gitlab-org/gitlab-test"
  },
  "object_attributes": {
    "id": 1244,
    "internal": false,
    "note": "This MR needs work.",
    "noteable_type": "MergeRequest",
    "author_id": 1,
    "created_at": "2015-05-17 18:21:36 UTC",
    "updated_at": "2015-05-17 18:21:36 UTC",
    "project_id": 5,
    "attachment": null,
    "line_code": null,
    "commit_id": "",
    "noteable_id": 7,
    "system": false,
    "st_diff": null,
    "action": "create",
    "url": "http://example.com/gitlab-org/gitlab-test/merge_requests/1#note_1244"
  },
  "merge_request": {
    "id": 7,
    "target_branch": "markdown",
    "source_branch": "master",
    "source_project_id": 5,
    "author_id": 8,
    "assignee_id": 28,
    "title": "Tempora et eos debitis quae laborum et.",
    "created_at": "2015-03-01 20:12:53 UTC",
    "updated_at": "2015-03-21 18:27:27 UTC",
    "milestone_id": 11,
    "state": "opened",
    "merge_status": "cannot_be_merged",
    "target_project_id": 5,
    "iid": 1,
    "description": "Et voluptas corrupti assumenda temporibus. Architecto cum animi eveniet amet asperiores. Vitae numquam voluptate est natus sit et ad id.",
    "position": 0,
    "labels": [
      {
        "id": 25,
        "title": "Afterpod",
        "color": "#3e8068",
        "project_id": null,
        "created_at": "2019-06-05T14:32:20.211Z",
        "updated_at": "2019-06-05T14:32:20.211Z",
        "template": false,
        "description": null,
        "type": "GroupLabel",
        "group_id": 4
      },
      {
        "id": 86,
        "title": "Element",
        "color": "#231afe",
        "project_id": 4,
        "created_at": "2019-06-05T14:32:20.637Z",
        "updated_at": "2019-06-05T14:32:20.637Z",
        "template": false,
        "description": null,
        "type": "ProjectLabel",
        "group_id": null
      }
    ],
    "source":{
      "name":"Gitlab Test",
      "description":"Aut reprehenderit ut est.",
      "web_url":"http://example.com/gitlab-org/gitlab-test",
      "avatar_url":null,
      "git_ssh_url":"git@example.com:gitlab-org/gitlab-test.git",
      "git_http_url":"http://example.com/gitlab-org/gitlab-test.git",
      "namespace":"Gitlab Org",
      "visibility_level":10,
      "path_with_namespace":"gitlab-org/gitlab-test",
      "default_branch":"master",
      "homepage":"http://example.com/gitlab-org/gitlab-test",
      "url":"http://example.com/gitlab-org/gitlab-test.git",
      "ssh_url":"git@example.com:gitlab-org/gitlab-test.git",
      "http_url":"http://example.com/gitlab-org/gitlab-test.git"
    },
    "target": {
      "name":"Gitlab Test",
      "description":"Aut reprehenderit ut est.",
      "web_url":"http://example.com/gitlab-org/gitlab-test",
      "avatar_url":null,
      "git_ssh_url":"git@example.com:gitlab-org/gitlab-test.git",
      "git_http_url":"http://example.com/gitlab-org/gitlab-test.git",
      "namespace":"Gitlab Org",
      "visibility_level":10,
      "path_with_namespace":"gitlab-org/gitlab-test",
      "default_branch":"master",
      "homepage":"http://example.com/gitlab-org/gitlab-test",
      "url":"http://example.com/gitlab-org/gitlab-test.git",
      "ssh_url":"git@example.com:gitlab-org/gitlab-test.git",
      "http_url":"http://example.com/gitlab-org/gitlab-test.git"
    },
    "last_commit": {
      "id": "562e173be03b8ff2efb05345d12df18815438a4b",
      "message": "Merge branch 'another-branch' into 'master'\n\nCheck in this test\n",
      "timestamp": "2015-04-08T21: 00:25-07:00",
      "url": "http://example.com/gitlab-org/gitlab-test/commit/562e173be03b8ff2efb05345d12df18815438a4b",
      "author": {
        "name": "John Smith",
        "email": "john@example.com"
      }
    },
    "work_in_progress": false,
    "draft": false,
    "assignee": {
      "name": "User1",
      "username": "user1",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon"
    },
    "detailed_merge_status": "checking"
  }
}
```

### イシューに関するコメント {#comment-on-an-issue}

- `assignee_id`フィールドは非推奨です。このフィールドには最初の担当者のみが表示されます。
- 機密情報イシューの場合は、`event_type`が`confidential_note`に設定されます。

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Note Hook
```

ペイロードの例:

```json
{
  "object_kind": "note",
  "event_type": "note",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon",
    "email": "admin@example.com"
  },
  "project_id": 5,
  "project":{
    "id": 5,
    "name":"Gitlab Test",
    "description":"Aut reprehenderit ut est.",
    "web_url":"http://example.com/gitlab-org/gitlab-test",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:gitlab-org/gitlab-test.git",
    "git_http_url":"http://example.com/gitlab-org/gitlab-test.git",
    "namespace":"Gitlab Org",
    "visibility_level":10,
    "path_with_namespace":"gitlab-org/gitlab-test",
    "default_branch":"master",
    "homepage":"http://example.com/gitlab-org/gitlab-test",
    "url":"http://example.com/gitlab-org/gitlab-test.git",
    "ssh_url":"git@example.com:gitlab-org/gitlab-test.git",
    "http_url":"http://example.com/gitlab-org/gitlab-test.git"
  },
  "repository":{
    "name":"diaspora",
    "url":"git@example.com:mike/diaspora.git",
    "description":"",
    "homepage":"http://example.com/mike/diaspora"
  },
  "object_attributes": {
    "id": 1241,
    "internal": false,
    "note": "Hello world",
    "noteable_type": "Issue",
    "author_id": 1,
    "created_at": "2015-05-17 17:06:40 UTC",
    "updated_at": "2015-05-17 17:06:40 UTC",
    "project_id": 5,
    "attachment": null,
    "line_code": null,
    "commit_id": "",
    "noteable_id": 92,
    "system": false,
    "st_diff": null,
    "action": "create",
    "url": "http://example.com/gitlab-org/gitlab-test/issues/17#note_1241"
  },
  "issue": {
    "id": 92,
    "title": "test",
    "assignee_ids": [],
    "assignee_id": null,
    "author_id": 1,
    "project_id": 5,
    "created_at": "2015-04-12 14:53:17 UTC",
    "updated_at": "2015-04-26 08:28:42 UTC",
    "position": 0,
    "branch_name": null,
    "description": "test",
    "milestone_id": null,
    "state": "closed",
    "iid": 17,
    "labels": [
      {
        "id": 25,
        "title": "Afterpod",
        "color": "#3e8068",
        "project_id": null,
        "created_at": "2019-06-05T14:32:20.211Z",
        "updated_at": "2019-06-05T14:32:20.211Z",
        "template": false,
        "description": null,
        "type": "GroupLabel",
        "group_id": 4
      },
      {
        "id": 86,
        "title": "Element",
        "color": "#231afe",
        "project_id": 4,
        "created_at": "2019-06-05T14:32:20.637Z",
        "updated_at": "2019-06-05T14:32:20.637Z",
        "template": false,
        "description": null,
        "type": "ProjectLabel",
        "group_id": null
      }
    ]
  }
}
```

### コードスニペットに関するコメント {#comment-on-a-code-snippet}

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Note Hook
```

ペイロードの例:

```json
{
  "object_kind": "note",
  "event_type": "note",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=40\u0026d=identicon",
    "email": "admin@example.com"
  },
  "project_id": 5,
  "project":{
    "id": 5,
    "name":"Gitlab Test",
    "description":"Aut reprehenderit ut est.",
    "web_url":"http://example.com/gitlab-org/gitlab-test",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:gitlab-org/gitlab-test.git",
    "git_http_url":"http://example.com/gitlab-org/gitlab-test.git",
    "namespace":"Gitlab Org",
    "visibility_level":10,
    "path_with_namespace":"gitlab-org/gitlab-test",
    "default_branch":"master",
    "homepage":"http://example.com/gitlab-org/gitlab-test",
    "url":"http://example.com/gitlab-org/gitlab-test.git",
    "ssh_url":"git@example.com:gitlab-org/gitlab-test.git",
    "http_url":"http://example.com/gitlab-org/gitlab-test.git"
  },
  "repository":{
    "name":"Gitlab Test",
    "url":"http://example.com/gitlab-org/gitlab-test.git",
    "description":"Aut reprehenderit ut est.",
    "homepage":"http://example.com/gitlab-org/gitlab-test"
  },
  "object_attributes": {
    "id": 1245,
    "internal": false,
    "note": "Is this snippet doing what it's supposed to be doing?",
    "noteable_type": "Snippet",
    "author_id": 1,
    "created_at": "2015-05-17 18:35:50 UTC",
    "updated_at": "2015-05-17 18:35:50 UTC",
    "project_id": 5,
    "attachment": null,
    "line_code": null,
    "commit_id": "",
    "noteable_id": 53,
    "system": false,
    "st_diff": null,
    "action": "create",
    "url": "http://example.com/gitlab-org/gitlab-test/-/snippets/53#note_1245"
  },
  "snippet": {
    "id": 53,
    "title": "test",
    "description": "A snippet description.",
    "content": "puts 'Hello world'",
    "author_id": 1,
    "project_id": 5,
    "created_at": "2015-04-09 02:40:38 UTC",
    "updated_at": "2015-04-09 02:40:38 UTC",
    "file_name": "test.rb",
    "type": "ProjectSnippet",
    "visibility_level": 0,
    "url": "http://example.com/gitlab-org/gitlab-test/-/snippets/53"
  }
}
```

## マージリクエストイベント {#merge-request-events}

マージリクエストイベントは、次の場合にトリガーされます。

- 新しいマージリクエストが作成された場合。
- 既存のマージリクエストが更新、（必要なすべての承認者により）承認、承認解除、マージ、またはクローズされた場合。
- 個々のユーザーが既存のマージリクエストへの承認を追加または削除した場合。
- レビュアーがマージリクエストの再レビューをリクエストされました。
- コミットがソースブランチに追加された場合。
- マージリクエストですべてのスレッドが解決された場合。

マージリクエストイベントは、`changes`フィールドが空の場合でもトリガーできます。Webhookレシーバーは、常に`changes`フィールドの内容を調べてマージリクエストの実際の変更を確認する必要があります。

### ペイロード構造 {#payload-structure}

WebhookペイロードのJSON構造は、すべてのアクションタイプで一貫しています。違いは、どのフィールドにデータが含まれるか、また`oldrev`、`system`、`system_action`などの条件付きフィールドが存在するかどうかにあります。

ペイロードの`object_attributes.action`に使用できる値は次のとおりです。

- `open`: マージリクエストが作成されます。
- `close`: マージリクエストがクローズされました。
- `reopen`: クローズされたマージリクエストが再オープンされました。
- `update`: マージリクエストが更新されました。これには、一般的な更新および再リクエストされたレビューアクションが含まれます。更新の特定の種類を判断するには、`changes`フィールドを確認してください。
- `approval`: ユーザーが承認を追加します。
- `approved`: マージリクエストは、必要なすべての承認者によって完全に承認されました。
- `unapproval`: ユーザーが、手動またはシステムによって承認を取り消しました。
- `unapproved`: 以前に承認されたマージリクエストは、手動またはシステムによって承認ステータスを失います。
- `merge`: マージリクエストがマージされました。

マージリクエストWebhookペイロードには、これらのトップレベルフィールドが含まれています:

| フィールド               | 種類   | 説明 |
|---------------------|--------|-------------|
| `object_kind`       | 文字列 | `"merge_request"` |
| `event_type`        | 文字列 | `"merge_request"` |
| `user`              | オブジェクト | イベントをトリガーしたユーザー。 |
| `project`           | オブジェクト | ターゲットプロジェクト。 |
| `object_attributes` | オブジェクト | マージリクエストデータ。 |
| `changes`           | オブジェクト | アクション中に変更された属性が含まれています。 |
| `assignees`         | 配列  | 現在割り当てられているユーザー。 |
| `reviewers`         | 配列  | 現在割り当てられているレビュアー。 |
| `labels`            | 配列  | ラベルオブジェクト。 |
| `repository`        | オブジェクト | 非推奨。代わりに`project`を使用してください。リポジトリ情報。 |

### 非推奨のフィールド {#deprecated-fields}

以下のフィールドは非推奨であり、下位互換性のためのみに含まれています。代わりに推奨される代替を使用してください:

| 非推奨フィールド                     | 推奨される代替 |
|--------------------------------------|-------------------------|
| `object_attributes.assignee_id`      | `object_attributes.assignee_ids` |
| `object_attributes.work_in_progress` | `object_attributes.draft` |
| `project.http_url`                   | `project.git_http_url`  |
| `project.homepage`                   | `project.web_url`       |
| `project.ssh_url`                    | `project.git_ssh_url`   |
| `project.url`                        | `project.git_ssh_url`または`project.git_http_url` |
| `repository`                         | `project`               |

### `object_attributes`フィールド {#object_attributes-field}

{{< history >}}

- `actioned_at`はGitLab 18.10で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224849)。

{{< /history >}}

`object_attributes`フィールドには、マージリクエストの現在の状態が含まれています。以下のフィールドが含まれています:

| フィールド                           | 種類    | 説明 |
|---------------------------------|---------|-------------|
| `action`                        | 文字列  | Webhookをトリガーしたアクション。たとえば、`open`、`update`、`merge`などです。 |
| `actioned_at`                   | 文字列  | Webhookをトリガーしたアクションが発生した日時。 |
| `approval_rules`                | 配列   | 承認ルールオブジェクトの配列（EEのみ）。 |
| `assignee_ids`                  | 配列   | 割り当てられたユーザーIDの配列。 |
| `author_id`                     | 整数 | マージリクエスト作成者のID。 |
| `blocking_discussions_resolved` | ブール値 | ブロックしているディスカッションが解決されたかどうか。 |
| `created_at`                    | 文字列  | マージリクエストが作成された日時。 |
| `description`                   | 文字列  | マージリクエストの説明。 |
| `detailed_merge_status`         | 文字列  | 詳細なマージステータス情報。潜在的な値のリストについては、[マージステータス](../../../api/merge_requests.md#merge-status)を参照してください。 |
| `draft`                         | ブール値 | マージリクエストがドラフトであるかどうか。 |
| `first_contribution`            | ブール値 | これが作成者の最初のコントリビュートであるかどうか。 |
| `head_pipeline_id`              | 整数 | HEADパイプラインのID。 |
| `human_time_change`             | 文字列  | 人間が判読できる時間の変更。 |
| `human_time_estimate`           | 文字列  | 人間が判読できる時間見積もり。 |
| `human_total_time_spent`        | 文字列  | 人間が判読できる総所要時間。 |
| `id`                            | 整数 | マージリクエストID。 |
| `iid`                           | 整数 | マージリクエストの内部ID。 |
| `labels`                        | 配列   | ラベルオブジェクトの配列。 |
| `last_commit`                   | オブジェクト  | 詳細を含む最後のコミットオブジェクト。 |
| `last_edited_at`                | 文字列  | マージリクエストが最後に編集された日時。 |
| `last_edited_by_id`             | 整数 | 最後に編集したユーザーのID。 |
| `merge_commit_sha`              | 文字列  | マージコミットのSHA。 |
| `merge_error`                   | 文字列  | マージエラーメッセージ。 |
| `merge_params`                  | オブジェクト  | マージパラメータ。 |
| `merge_status`                  | 文字列  | マージリクエストの状態。 |
| `merge_user_id`                 | 整数 | それをマージしたユーザーのID。 |
| `merge_when_pipeline_succeeds`  | ブール値 | 自動マージが有効になっているかどうか。 |
| `milestone_id`                  | 整数 | マイルストーンのID。 |
| `oldrev`                        | 文字列  | 古いコミットSHA（プッシュ関連イベントの場合にのみ存在）。 |
| `prepared_at`                   | 文字列  | マージリクエストが準備されたときのタイムスタンプ。このフィールドは、すべての[準備手順](../../../api/merge_requests.md#preparation-steps)が完了した後に1回だけ入力され、それ以上の変更が加えられても更新されません。 |
| `reviewer_ids`                  | 配列   | レビュアーIDの配列。 |
| `source_branch`                 | 文字列  | ソースブランチ名。 |
| `source`                        | オブジェクト  | ソースプロジェクトの詳細。たとえば、名前と説明。 |
| `source_project_id`             | 整数 | ソースプロジェクトのID。 |
| `state_id`                      | 整数 | 状態ID（`1`: オープン済み、`2`: クローズ済み、`3`: マージ済み、`4`: ロック済み）。 |
| `state`                         | 文字列  | マージリクエストの状態（`opened`、`closed`、`merged`、`locked`）。 |
| `system_action`                 | 文字列  | システムアクション（`system`が`true`の場合にのみ存在）。 |
| `system`                        | ブール値 | イベントがシステムによって開始されたかどうか。 |
| `target_branch`                 | 文字列  | ターゲットブランチ名。 |
| `target`                        | オブジェクト  | ターゲットプロジェクトの詳細。たとえば、名前と説明。 |
| `target_project_id`             | 整数 | ターゲットプロジェクトのID。 |
| `time_change`                   | 整数 | 費やされた時間の秒単位での変更。 |
| `time_estimate`                 | 整数 | 秒単位での時間見積もり。 |
| `title`                         | 文字列  | マージリクエストのタイトル。 |
| `total_time_spent`              | 整数 | 合計経過時間 (秒)。 |
| `updated_at`                    | 文字列  | マージリクエストが最後に更新された日時。 |
| `updated_by_id`                 | 整数 | 最後に更新したユーザーのID。 |
| `url`                           | 文字列  | マージリクエストへのURL。 |

### `changes`フィールド {#changes-field}

`changes`フィールドには、アクション中に変更されたフィールドのみが含まれます。`object_attributes`のすべてのフィールドが`changes`に表示されるわけではありません。

各変更されたフィールドは次の形式に従います:

```json
{
  "field_name": {
    "previous": "old_value",
    "current": "new_value"
  }
}
```

#### 属性 {#attributes}

- `assignees`
- `blocking_discussions_resolved`
- `description`
- `draft`
- `head_pipeline_id`
- `labels`
- `last_edited_at`
- `last_edited_by_id`
- `merge_commit_sha`
- `merge_error`
- `merge_params`
- `merge_status`
- `merge_user_id`
- `merge_when_pipeline_succeeds`
- `milestone_id`
- `prepared_at`
- `reviewer_ids`
- `reviewers`
- `state_id`
- `target_branch`
- `time_change`
- `time_estimate`
- `title`
- `total_time_spent`
- `updated_at`
- `updated_by_id`

### マージリクエストのアクション固有のフィールド {#merge-request-action-specific-fields}

`object_attributes.oldrev`フィールドは、`update`アクションが実際にコード変更がある場合にのみ使用できます。たとえば、次のとおりです:

- 新しいコードがソースブランチにプッシュされます。
- [提案](../merge_requests/reviews/suggestions.md)が適用された場合。

次の例は、`update`イベントと`oldrev`（部分的なペイロード）を示しています:

```json
{
  "object_kind": "merge_request",
  "event_type": "merge_request",
  "object_attributes": {
    "action": "update",
    "oldrev": "e59094b8de0f2f91abbe4760a52d9137260252d8"
  }
}
```

### システムによって開始されたマージリクエストイベント {#system-initiated-merge-request-events}

新しいコミットのプッシュによって承認がリセットされるなど、一部のマージリクエストイベントはシステムによって自動的にトリガーされます。これらのシステムによって開始されたWebhookイベントは、プッシュイベントによってのみトリガーされ、ペイロードにはより多くのフィールドが含まれます:

- `object_attributes.system`: ブール型フィールド。`true`の場合、イベントはシステムによってトリガーされました。`false`の場合、ユーザーアクションがイベントをトリガーしました。
- `object_attributes.system_action`: 文字列フィールドで、`system`が`true`の場合にのみ存在します。システムアクションに関するより多くのコンテキストを提供します。使用可能な値は次のとおりです:

  - `approvals_reset_on_push`: プロジェクトで**プッシュ時の承認リセット**が有効になっており、新しいコミットがプッシュされました。
  - `code_owner_approvals_reset_on_push`: プロジェクトで**Selective code owner removals**が有効になっており、CODEOWNERSルールに一致するファイルの変更により、コードオーナー承認がリセットされました。

その他の承認リセットシナリオはWebhookをトリガーしません。

次の例は、システムによって開始されたイベント（部分的なペイロード）を示しています:

```json
{
  "object_kind": "merge_request",
  "event_type": "merge_request",
  "object_attributes": {
    "action": "update",
    "system": true,
    "system_action": "approvals_reset_on_push"
  }
}
```

### レビュアーの状態追跡 {#reviewer-state-tracking}

マージリクエストWebhookペイロードの`reviewers`配列には、各レビュアーの`state`フィールドが含まれています。`state`フィールドは、レビュアーの現在のレビュー状態を示します:

- `unreviewed`: レビュアーはまだマージリクエストをレビューしていません。
- `review_started`: レビュアーはレビューを開始しましたが、完了していません。
- `reviewed`: レビュアーはレビューを完了しました。
- `requested_changes`: レビュアーが変更のリクエストを行いました。
- `approved`: レビュアーがマージリクエストを承認しました。
- `unapproved`: レビュアーは以前に承認しましたが、その承認が削除されました。

次の例は、レビュアー配列（部分的なペイロード）を示しています:

```json
{
  "reviewers": [
    {
      "id": 6,
      "name": "User1",
      "username": "user1",
      "state": "unreviewed",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "email": "user1@example.com"
    }
  ]
}
```

### 再リクエストされたレビューイベント {#re-request-review-events}

レビュアーがマージリクエストの再リクエストをされた場合、Webhookが`action: "update"`でトリガーされ、`changes`オブジェクトに拡張情報が含まれます。変更ペイロードには以下が含まれます:

- **Previous state** (最初の配列): 再リクエスト前のレビュアーの状態を`re_requested: false`で表示します。
- **Current state** (2番目の配列): 再リクエスト後のレビュアーの更新された状態を、再リクエストされたレビュアーに対して`re_requested: true`で表示します。
- **State transitions**: レビュアーの状態がどのように変更されたかを示します（例：`approved`から`unreviewed`へ）。

次の例は、再リクエストされたレビューの変更点（部分的なペイロード）を示しています:

```json
{
  "object_kind": "merge_request",
  "event_type": "merge_request",
  "object_attributes": {
    "action": "update"
  },
  "changes": {
    "reviewers": [
      [
        {
          "id": 6,
          "name": "User1",
          "username": "user1",
          "state": "approved",
          "re_requested": false,
          "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
          "email": "user1@example.com"
        }
      ],
      [
        {
          "id": 6,
          "name": "User1",
          "username": "user1",
          "state": "unreviewed",
          "re_requested": true,
          "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
          "email": "user1@example.com"
        }
      ]
    ]
  }
}
```

### 完全なペイロードの例 {#complete-payload-example}

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Merge Request Hook
```

次の例は、`open`アクションの完全なマージリクエストWebhookペイロードです。非推奨フィールドは明確にするために省略されています。非推奨フィールドとその推奨される代替のリストについては、[非推奨フィールド](#deprecated-fields)を参照してください。

```json
{
  "object_kind": "merge_request",
  "event_type": "merge_request",
  "user": {
    "id": 1,
    "name": "Alex Garcia",
    "username": "agarcia",
    "avatar_url": "https://www.gravatar.com/avatar/1a29da0ccd099482194440fac762f5ccb4ec53227761d1859979367644a889a5?s=80&d=identicon",
    "email": "agarcia@example.com"
  },
  "project": {
    "id": 2,
    "name": "Flight Management",
    "description": "Flight management application for tracking aircraft status.",
    "web_url": "http://gitlab.example.com/flightjs/flight-management",
    "avatar_url": null,
    "git_ssh_url": "ssh://git@gitlab.example.com:flightjs/flight-management.git",
    "git_http_url": "http://gitlab.example.com/flightjs/flight-management.git",
    "namespace": "Flightjs",
    "visibility_level": 0,
    "path_with_namespace": "flightjs/flight-management",
    "default_branch": "main",
    "ci_config_path": null
  },
  "object_attributes": {
    "author_id": 1,
    "created_at": "2026-01-16 05:56:22 UTC",
    "description": "This merge request adds input validation to the booking form.",
    "draft": false,
    "head_pipeline_id": null,
    "id": 93,
    "iid": 16,
    "last_edited_at": null,
    "last_edited_by_id": null,
    "merge_commit_sha": null,
    "merge_error": null,
    "merge_params": {
      "force_remove_source_branch": "1"
    },
    "merge_status": "checking",
    "merge_user_id": null,
    "merge_when_pipeline_succeeds": false,
    "milestone_id": 8,
    "source_branch": "feature/booking-validation",
    "source_project_id": 2,
    "state_id": 1,
    "target_branch": "main",
    "target_project_id": 2,
    "time_estimate": 0,
    "title": "Add input validation to booking form",
    "updated_at": "2026-01-16 05:56:25 UTC",
    "updated_by_id": null,
    "prepared_at": "2026-01-16 05:56:25 UTC",
    "assignee_ids": [
      1
    ],
    "blocking_discussions_resolved": true,
    "detailed_merge_status": "checking",
    "first_contribution": true,
    "human_time_change": null,
    "human_time_estimate": null,
    "human_total_time_spent": null,
    "labels": [
      {
        "id": 19,
        "title": "enhancement",
        "color": "#adb21a",
        "project_id": null,
        "created_at": "2026-01-07 00:03:52 UTC",
        "updated_at": "2026-01-07 00:03:52 UTC",
        "template": false,
        "description": null,
        "type": "GroupLabel",
        "group_id": 24
      }
    ],
    "last_commit": {
      "id": "e59094b8de0f2f91abbe4760a52d9137260252d8",
      "message": "Add email format validation",
      "title": "Add email format validation",
      "timestamp": "2026-01-16T05:01:10+00:00",
      "url": "http://gitlab.example.com/flightjs/flight-management/-/commit/e59094b8de0f2f91abbe4760a52d9137260252d8",
      "author": {
        "name": "Alex Garcia",
        "email": "agarcia@example.com"
      }
    },
    "reviewer_ids": [
      25
    ],
    "source": {
      "id": 2,
      "name": "Flight Management",
      "description": "Flight management application for tracking aircraft status.",
      "web_url": "http://gitlab.example.com/flightjs/flight-management",
      "avatar_url": null,
      "git_ssh_url": "ssh://git@gitlab.example.com:flightjs/flight-management.git",
      "git_http_url": "http://gitlab.example.com/flightjs/flight-management.git",
      "namespace": "Flightjs",
      "visibility_level": 0,
      "path_with_namespace": "flightjs/flight-management",
      "default_branch": "main",
      "ci_config_path": null
    },
    "state": "opened",
    "system": false,
    "target": {
      "id": 2,
      "name": "Flight Management",
      "description": "Flight management application for tracking aircraft status.",
      "web_url": "http://gitlab.example.com/flightjs/flight-management",
      "avatar_url": null,
      "git_ssh_url": "ssh://git@gitlab.example.com:flightjs/flight-management.git",
      "git_http_url": "http://gitlab.example.com/flightjs/flight-management.git",
      "namespace": "Flightjs",
      "visibility_level": 0,
      "path_with_namespace": "flightjs/flight-management",
      "default_branch": "main",
      "ci_config_path": null
    },
    "time_change": 0,
    "total_time_spent": 0,
    "url": "http://gitlab.example.com/flightjs/flight-management/-/merge_requests/16",
    "approval_rules": [
      {
        "id": 4,
        "approvals_required": 0,
        "name": "All Members",
        "rule_type": "any_approver",
        "report_type": null,
        "merge_request_id": 93,
        "section": null,
        "modified_from_project_rule": false,
        "orchestration_policy_idx": null,
        "vulnerabilities_allowed": 0,
        "scanners": [],
        "severity_levels": [],
        "vulnerability_states": [
          "new_needs_triage",
          "new_dismissed"
        ],
        "security_orchestration_policy_configuration_id": null,
        "scan_result_policy_id": null,
        "applicable_post_merge": null,
        "project_id": 2,
        "approval_policy_rule_id": null,
        "updated_at": "2026-01-16 05:56:22 UTC",
        "created_at": "2026-01-16 05:56:22 UTC"
      }
    ],
    "action": "open",
    "actioned_at": "2026-01-16 05:56:26 UTC"
  },
  "labels": [
    {
      "id": 19,
      "title": "enhancement",
      "color": "#adb21a",
      "project_id": null,
      "created_at": "2026-01-07 00:03:52 UTC",
      "updated_at": "2026-01-07 00:03:52 UTC",
      "template": false,
      "description": null,
      "type": "GroupLabel",
      "group_id": 24
    }
  ],
  "changes": {
    "merge_status": {
      "previous": "preparing",
      "current": "checking"
    },
    "updated_at": {
      "previous": "2026-01-16 05:56:22 UTC",
      "current": "2026-01-16 05:56:25 UTC"
    },
    "prepared_at": {
      "previous": null,
      "current": "2026-01-16 05:56:25 UTC"
    }
  },
  "assignees": [
    {
      "id": 1,
      "name": "Alex Garcia",
      "username": "agarcia",
      "avatar_url": "https://www.gravatar.com/avatar/1a29da0ccd099482194440fac762f5ccb4ec53227761d1859979367644a889a5?s=80&d=identicon",
      "email": "[REDACTED]"
    }
  ],
  "reviewers": [
    {
      "id": 25,
      "name": "Sidney Jones",
      "username": "sjones",
      "avatar_url": "https://www.gravatar.com/avatar/1be419860e7f852e20ca2691e6b55949f7809177e7765181da42e4448491e367?s=80&d=identicon",
      "email": "[REDACTED]",
      "state": "unreviewed",
      "re_requested": false
    }
  ]
}
```

> [!note]
> フィールド`assignee_id`と`merge_status`は[非推奨](../../../api/merge_requests.md)です。

## Wikiページイベント {#wiki-page-events}

Wikiページイベントは、Wikiページが作成、更新、または削除されるとトリガーされます。

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Wiki Page Hook
```

ペイロードの例:

```json
{
  "object_kind": "wiki_page",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80\u0026d=identicon",
    "email": "admin@example.com"
  },
  "project": {
    "id": 1,
    "name": "awesome-project",
    "description": "This is awesome",
    "web_url": "http://example.com/root/awesome-project",
    "avatar_url": null,
    "git_ssh_url": "git@example.com:root/awesome-project.git",
    "git_http_url": "http://example.com/root/awesome-project.git",
    "namespace": "root",
    "visibility_level": 0,
    "path_with_namespace": "root/awesome-project",
    "default_branch": "master",
    "homepage": "http://example.com/root/awesome-project",
    "url": "git@example.com:root/awesome-project.git",
    "ssh_url": "git@example.com:root/awesome-project.git",
    "http_url": "http://example.com/root/awesome-project.git"
  },
  "wiki": {
    "web_url": "http://example.com/root/awesome-project/-/wikis/home",
    "git_ssh_url": "git@example.com:root/awesome-project.wiki.git",
    "git_http_url": "http://example.com/root/awesome-project.wiki.git",
    "path_with_namespace": "root/awesome-project.wiki",
    "default_branch": "master"
  },
  "object_attributes": {
    "title": "Awesome",
    "content": "awesome content goes here",
    "format": "markdown",
    "message": "adding an awesome page to the wiki",
    "slug": "awesome",
    "url": "http://example.com/root/awesome-project/-/wikis/awesome",
    "action": "create",
    "diff_url": "http://example.com/root/awesome-project/-/wikis/home/diff?version_id=78ee4a6705abfbff4f4132c6646dbaae9c8fb6ec",
    "version_id": "3ad67c972065298d226dd80b2b03e0fc2421e731"
  }
}
```

## パイプラインイベント {#pipeline-events}

パイプラインイベントは、パイプラインの状態が変更されるとトリガーされます。

[GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89546)以降では、ブロックされたユーザーによってトリガーされたパイプラインWebhookは処理されません。

[GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123639)以降では、パイプラインWebhookが`object_attributes.name`を公開し始めました。

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Pipeline Hook
```

ペイロードの例:

```json
{
  "object_kind": "pipeline",
  "object_attributes": {
    "id": 31,
    "iid": 3,
    "name": "Pipeline for branch: master",
    "ref": "master",
    "tag": false,
    "sha": "bcbb5ec396a2c0f828686f14fac9b80b780504f2",
    "before_sha": "bcbb5ec396a2c0f828686f14fac9b80b780504f2",
    "source": "merge_request_event",
    "status": "success",
    "detailed_status": "passed",
    "stages": [
      "build",
      "test",
      "deploy"
    ],
    "created_at": "2016-08-12 15:23:28 UTC",
    "finished_at": "2016-08-12 15:26:29 UTC",
    "duration": 63,
    "queued_duration": 10,
    "variables": [
      {
        "key": "NESTOR_PROD_ENVIRONMENT",
        "value": "us-west-1"
      }
    ],
    "url": "http://example.com/gitlab-org/gitlab-test/-/pipelines/31"
  },
  "merge_request": {
    "id": 1,
    "iid": 1,
    "title": "Test",
    "source_branch": "test",
    "source_project_id": 1,
    "target_branch": "master",
    "target_project_id": 1,
    "state": "opened",
    "merge_status": "can_be_merged",
    "detailed_merge_status": "mergeable",
    "url": "http://192.168.64.1:3005/gitlab-org/gitlab-test/merge_requests/1"
  },
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon",
    "email": "user_email@gitlab.com"
  },
  "project": {
    "id": 1,
    "name": "Gitlab Test",
    "description": "Atque in sunt eos similique dolores voluptatem.",
    "web_url": "http://192.168.64.1:3005/gitlab-org/gitlab-test",
    "avatar_url": null,
    "git_ssh_url": "git@192.168.64.1:gitlab-org/gitlab-test.git",
    "git_http_url": "http://192.168.64.1:3005/gitlab-org/gitlab-test.git",
    "namespace": "Gitlab Org",
    "visibility_level": 20,
    "path_with_namespace": "gitlab-org/gitlab-test",
    "default_branch": "master",
    "ci_config_path": null
  },
  "commit": {
    "id": "bcbb5ec396a2c0f828686f14fac9b80b780504f2",
    "message": "test\n",
    "title": "test",
    "timestamp": "2016-08-12T17:23:21+02:00",
    "url": "http://example.com/gitlab-org/gitlab-test/commit/bcbb5ec396a2c0f828686f14fac9b80b780504f2",
    "author": {
      "name": "User",
      "email": "user@gitlab.com"
    }
  },
  "builds": [
    {
      "id": 380,
      "stage": "deploy",
      "name": "production",
      "status": "skipped",
      "created_at": "2016-08-12 15:23:28 UTC",
      "started_at": null,
      "finished_at": null,
      "duration": null,
      "queued_duration": null,
      "failure_reason": null,
      "when": "manual",
      "manual": true,
      "allow_failure": false,
      "user": {
        "id": 1,
        "name": "Administrator",
        "username": "root",
        "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon",
        "email": "admin@example.com"
      },
      "runner": null,
      "artifacts_file": {
        "filename": null,
        "size": null
      },
      "environment": {
        "name": "production",
        "action": "start",
        "deployment_tier": "production"
      }
    },
    {
      "id": 377,
      "stage": "test",
      "name": "test-image",
      "status": "success",
      "created_at": "2016-08-12 15:23:28 UTC",
      "started_at": "2016-08-12 15:26:12 UTC",
      "finished_at": "2016-08-12 15:26:29 UTC",
      "duration": 17.0,
      "queued_duration": 196.0,
      "failure_reason": null,
      "when": "on_success",
      "manual": false,
      "allow_failure": false,
      "user": {
        "id": 1,
        "name": "Administrator",
        "username": "root",
        "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon",
        "email": "admin@example.com"
      },
      "runner": {
        "id": 380987,
        "description": "shared-runners-manager-6.gitlab.com",
        "runner_type": "instance_type",
        "active": true,
        "is_shared": true,
        "tags": [
          "linux",
          "docker",
          "shared-runner"
        ]
      },
      "artifacts_file": {
        "filename": null,
        "size": null
      },
      "environment": null
    },
    {
      "id": 378,
      "stage": "test",
      "name": "test-build",
      "status": "failed",
      "created_at": "2016-08-12 15:23:28 UTC",
      "started_at": "2016-08-12 15:26:12 UTC",
      "finished_at": "2016-08-12 15:26:29 UTC",
      "duration": 17.0,
      "queued_duration": 196.0,
      "failure_reason": "script_failure",
      "when": "on_success",
      "manual": false,
      "allow_failure": false,
      "user": {
        "id": 1,
        "name": "Administrator",
        "username": "root",
        "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon",
        "email": "admin@example.com"
      },
      "runner": {
        "id": 380987,
        "description": "shared-runners-manager-6.gitlab.com",
        "runner_type": "instance_type",
        "active": true,
        "is_shared": true,
        "tags": [
          "linux",
          "docker"
        ]
      },
      "artifacts_file": {
        "filename": null,
        "size": null
      },
      "environment": null
    },
    {
      "id": 376,
      "stage": "build",
      "name": "build-image",
      "status": "success",
      "created_at": "2016-08-12 15:23:28 UTC",
      "started_at": "2016-08-12 15:24:56 UTC",
      "finished_at": "2016-08-12 15:25:26 UTC",
      "duration": 17.0,
      "queued_duration": 196.0,
      "failure_reason": null,
      "when": "on_success",
      "manual": false,
      "allow_failure": false,
      "user": {
        "id": 1,
        "name": "Administrator",
        "username": "root",
        "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon",
        "email": "admin@example.com"
      },
      "runner": {
        "id": 380987,
        "description": "shared-runners-manager-6.gitlab.com",
        "runner_type": "instance_type",
        "active": true,
        "is_shared": true,
        "tags": [
          "linux",
          "docker"
        ]
      },
      "artifacts_file": {
        "filename": null,
        "size": null
      },
      "environment": null
    },
    {
      "id": 379,
      "stage": "deploy",
      "name": "staging",
      "status": "created",
      "created_at": "2016-08-12 15:23:28 UTC",
      "started_at": null,
      "finished_at": null,
      "duration": null,
      "queued_duration": null,
      "failure_reason": null,
      "when": "on_success",
      "manual": false,
      "allow_failure": false,
      "user": {
        "id": 1,
        "name": "Administrator",
        "username": "root",
        "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon",
        "email": "admin@example.com"
      },
      "runner": null,
      "artifacts_file": {
        "filename": null,
        "size": null
      },
      "environment": {
        "name": "staging",
        "action": "start",
        "deployment_tier": "staging"
      }
    }
  ],
  "source_pipeline": {
    "project": {
      "id": 41,
      "web_url": "https://gitlab.example.com/gitlab-org/upstream-project",
      "path_with_namespace": "gitlab-org/upstream-project"
    },
    "pipeline_id": 30,
    "job_id": 3401
  }
}
```

## ジョブイベント {#job-events}

ジョブイベントは、ジョブの状態が変更されるとトリガーされます。トリガージョブは除外されます。

ペイロードの`commit.id`は、コミットのIDではなくパイプラインのIDです。

[GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89546)以降では、ブロックされたユーザーによってトリガーされたジョブイベントは処理されません。

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Job Hook
```

ペイロードの例:

```json
{
  "object_kind": "build",
  "ref": "gitlab-script-trigger",
  "tag": false,
  "before_sha": "2293ada6b400935a1378653304eaf6221e0fdb8f",
  "sha": "2293ada6b400935a1378653304eaf6221e0fdb8f",
  "retries_count": 2,
  "build_id": 1977,
  "build_name": "test",
  "build_stage": "test",
  "build_status": "created",
  "build_created_at": "2021-02-23T02:41:37.886Z",
  "build_started_at": null,
  "build_finished_at": null,
  "build_created_at_iso": "2021-02-23T02:41:37Z",
  "build_started_at_iso": null,
  "build_finished_at_iso": null,
  "build_duration": null,
  "build_queued_duration": 1095.588715,
  "build_allow_failure": false,
  "build_failure_reason": "unknown_failure",
  "pipeline_id": 2366,
  "runner": {
    "id": 380987,
    "description": "shared-runners-manager-6.gitlab.com",
    "runner_type": "project_type",
    "active": true,
    "is_shared": false,
    "tags": [
      "linux",
      "docker"
    ]
  },
  "project_id": 380,
  "project_name": "gitlab-org/gitlab-test",
  "user": {
    "id": 3,
    "name": "User",
    "username": "user",
    "avatar_url": "http://www.gravatar.com/avatar/e32bd13e2add097461cb96824b7a829c?s=80\u0026d=identicon",
    "email": "user@gitlab.com"
  },
  "commit": {
    "id": 2366,
    "name": "Build pipeline",
    "sha": "2293ada6b400935a1378653304eaf6221e0fdb8f",
    "message": "test\n",
    "author_name": "User",
    "author_email": "user@gitlab.com",
    "author_url": "http://192.168.64.1:3005/user",
    "status": "created",
    "duration": null,
    "started_at": null,
    "finished_at": null,
    "started_at_iso": null,
    "finished_at_iso": null
  },
  "repository": {
    "name": "gitlab_test",
    "url": "http://192.168.64.1:3005/gitlab-org/gitlab-test",
    "description": "Atque in sunt eos similique dolores voluptatem.",
    "homepage": "http://192.168.64.1:3005/gitlab-org/gitlab-test",
    "git_ssh_url": "git@192.168.64.1:gitlab-org/gitlab-test.git",
    "git_http_url": "http://192.168.64.1:3005/gitlab-org/gitlab-test.git",
    "visibility_level": 20
  },
  "project": {
    "id": 380,
    "name": "Gitlab Test",
    "description": "Atque in sunt eos similique dolores voluptatem.",
    "web_url": "http://192.168.64.1:3005/gitlab-org/gitlab-test",
    "avatar_url": null,
    "git_ssh_url": "git@192.168.64.1:gitlab-org/gitlab-test.git",
    "git_http_url": "http://192.168.64.1:3005/gitlab-org/gitlab-test.git",
    "namespace": "Gitlab Org",
    "visibility_level": 20,
    "path_with_namespace": "gitlab-org/gitlab-test",
    "default_branch": "master",
    "ci_config_path": null
  },
  "environment": null,
  "source_pipeline": {
    "project": {
      "id": 41,
      "web_url": "https://gitlab.example.com/gitlab-org/upstream-project",
      "path_with_namespace": "gitlab-org/upstream-project"
    },
    "pipeline_id": 30,
    "job_id": 3401
  }
}
```

### 再試行回数 {#number-of-retries}

{{< history >}}

- `retries_count`は、GitLab 15.6で`job_webhook_retries_count`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/382046)されました。デフォルトでは無効になっています。
- `retries_count`は、GitLab 16.2の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/382046)になりました。

{{< /history >}}

`retries_count`は、ジョブが再試行であるかどうかを示す整数です。`0`は、ジョブが再試行されていないことを意味します。`1`は、最初の再試行であることを意味します。

### パイプライン名 {#pipeline-name}

{{< history >}}

- `commit.name`は、GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107963)されました。

{{< /history >}}

[`workflow:name`](../../../ci/yaml/_index.md#workflowname)を使用して、パイプラインのカスタム名を設定できます。パイプラインに名前が付いている場合、その名前は`commit.name`の値です。

## デプロイメントイベント {#deployment-events}

デプロイメントイベントは、デプロイメントが次の状態になるとトリガーされます。

- 開始
- 成功
- 失敗
- キャンセルされます

ペイロードの`deployable_id`と`deployable_url`は、デプロイメントを実行したCI/CDジョブを表します。[API](../../../ci/environments/external_deployment_tools.md)または[`trigger`ジョブ](../../../ci/pipelines/downstream_pipelines.md)によってデプロイイベントが発生した場合、`deployable_url`は`null`です。

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Deployment Hook
```

ペイロードの例:

```json
{
  "object_kind": "deployment",
  "status": "success",
  "status_changed_at":"2021-04-28 21:50:00 +0200",
  "deployment_id": 15,
  "deployable_id": 796,
  "deployable_url": "http://10.126.0.2:3000/root/test-deployment-webhooks/-/jobs/796",
  "environment": "staging",
  "environment_tier": "staging",
  "environment_slug": "staging",
  "environment_external_url": "https://staging.example.com",
  "project": {
    "id": 30,
    "name": "test-deployment-webhooks",
    "description": "",
    "web_url": "http://10.126.0.2:3000/root/test-deployment-webhooks",
    "avatar_url": null,
    "git_ssh_url": "ssh://vlad@10.126.0.2:2222/root/test-deployment-webhooks.git",
    "git_http_url": "http://10.126.0.2:3000/root/test-deployment-webhooks.git",
    "namespace": "Administrator",
    "visibility_level": 0,
    "path_with_namespace": "root/test-deployment-webhooks",
    "default_branch": "master",
    "ci_config_path": "",
    "homepage": "http://10.126.0.2:3000/root/test-deployment-webhooks",
    "url": "ssh://vlad@10.126.0.2:2222/root/test-deployment-webhooks.git",
    "ssh_url": "ssh://vlad@10.126.0.2:2222/root/test-deployment-webhooks.git",
    "http_url": "http://10.126.0.2:3000/root/test-deployment-webhooks.git"
  },
  "short_sha": "279484c0",
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "email": "admin@example.com"
  },
  "user_url": "http://10.126.0.2:3000/root",
  "commit_url": "http://10.126.0.2:3000/root/test-deployment-webhooks/-/commit/279484c09fbe69ededfced8c1bb6e6d24616b468",
  "commit_title": "Add new file"
}
```

## グループメンバーイベント {#group-member-events}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

{{< history >}}

- アクセスリクエストイベントは、GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163094)されました。

{{< /history >}}

これらのイベントは、[グループWebhook](webhooks.md#group-webhooks)に対してのみトリガーされます。

メンバーイベントは、次の場合にトリガーされます。

- ユーザーがグループメンバーとして追加された場合。
- ユーザーのアクセスレベルが変更された場合。
- ユーザーアクセスの有効期限が更新された場合。
- ユーザーがグループから削除された場合。
- ユーザーがグループへのアクセスをリクエストした場合。
- アクセスリクエストが拒否された場合。

### グループにメンバーを追加する {#add-member-to-group}

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Member Hook
```

ペイロードの例:

```json
{
  "created_at": "2020-12-11T04:57:22Z",
  "updated_at": "2020-12-11T04:57:22Z",
  "group_name": "webhook-test",
  "group_path": "webhook-test",
  "group_id": 100,
  "user_username": "test_user",
  "user_name": "Test User",
  "user_email": "testuser@webhooktest.com",
  "user_id": 64,
  "group_access": "Guest",
  "group_plan": null,
  "expires_at": "2020-12-14T00:00:00Z",
  "event_name": "user_add_to_group"
}
```

### メンバーのアクセスレベルまたは有効期限を更新する {#update-member-access-level-or-expiration-date}

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Member Hook
```

ペイロードの例:

```json
{
  "created_at": "2020-12-11T04:57:22Z",
  "updated_at": "2020-12-12T08:48:19Z",
  "group_name": "webhook-test",
  "group_path": "webhook-test",
  "group_id": 100,
  "user_username": "test_user",
  "user_name": "Test User",
  "user_email": "testuser@webhooktest.com",
  "user_id": 64,
  "group_access": "Developer",
  "group_plan": null,
  "expires_at": "2020-12-20T00:00:00Z",
  "event_name": "user_update_for_group"
}
```

### グループからメンバーを削除する {#remove-member-from-group}

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Member Hook
```

ペイロードの例:

```json
{
  "created_at": "2020-12-11T04:57:22Z",
  "updated_at": "2020-12-12T08:52:34Z",
  "group_name": "webhook-test",
  "group_path": "webhook-test",
  "group_id": 100,
  "user_username": "test_user",
  "user_name": "Test User",
  "user_email": "testuser@webhooktest.com",
  "user_id": 64,
  "group_access": "Guest",
  "group_plan": null,
  "expires_at": "2020-12-14T00:00:00Z",
  "event_name": "user_remove_from_group"
}
```

### ユーザーがアクセスをリクエストする {#a-user-requests-access}

{{< history >}}

- GitLab 17.4で`group_access_request_webhooks`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163094)されました。デフォルトでは無効になっています。
- GitLab 17.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/479877)になりました。機能フラグ`group_access_request_webhooks`は削除されました。

{{< /history >}}

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Member Hook
```

ペイロードの例:

```json
{
  "created_at": "2020-12-11T04:57:22Z",
  "updated_at": "2020-12-12T08:52:34Z",
  "group_name": "webhook-test",
  "group_path": "webhook-test",
  "group_id": 100,
  "user_username": "test_user",
  "user_name": "Test User",
  "user_email": "testuser@webhooktest.com",
  "user_id": 64,
  "group_access": "Guest",
  "group_plan": null,
  "expires_at": "2020-12-14T00:00:00Z",
  "event_name": "user_access_request_to_group"
}
```

### アクセスリクエストが拒否される {#an-access-request-is-denied}

{{< history >}}

- GitLab 17.4で`group_access_request_webhooks`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163094)されました。デフォルトでは無効になっています。
- GitLab 17.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/479877)になりました。機能フラグ`group_access_request_webhooks`は削除されました。

{{< /history >}}

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Member Hook
```

ペイロードの例:

```json
{
  "created_at": "2020-12-11T04:57:22Z",
  "updated_at": "2020-12-12T08:52:34Z",
  "group_name": "webhook-test",
  "group_path": "webhook-test",
  "group_id": 100,
  "user_username": "test_user",
  "user_name": "Test User",
  "user_email": "testuser@webhooktest.com",
  "user_id": 64,
  "group_access": "Guest",
  "group_plan": null,
  "expires_at": "2020-12-14T00:00:00Z",
  "event_name": "user_access_request_denied_for_group"
}
```

## プロジェクトイベント {#project-events}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/359044)されました。

{{< /history >}}

これらのイベントは、[グループWebhook](webhooks.md#group-webhooks)に対してのみトリガーされます。

プロジェクトイベントは、次の場合にトリガーされます。

- [プロジェクトがグループで作成された](#create-a-project-in-a-group)場合。
- [プロジェクトがグループで削除された](#delete-a-project-in-a-group)場合。

### グループでプロジェクトを作成する {#create-a-project-in-a-group}

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Project Hook
```

ペイロードの例:

```json
{
  "event_name": "project_create",
  "created_at": "2024-10-07T10:43:48Z",
  "updated_at": "2024-10-07T10:43:48Z",
  "name": "project1",
  "path": "project1",
  "path_with_namespace": "group1/project1",
  "project_id": 22,
  "project_namespace_id": 32,
  "owners": [{
    "name": "John",
    "email": "user1@example.com"
  }],
  "project_visibility": "private"
}
```

### グループでプロジェクトを削除する {#delete-a-project-in-a-group}

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Project Hook
```

ペイロードの例:

```json
{
  "event_name": "project_destroy",
  "created_at": "2024-10-07T10:43:48Z",
  "updated_at": "2024-10-07T10:43:48Z",
  "name": "project1",
  "path": "project1",
  "path_with_namespace": "group1/project1",
  "project_id": 22,
  "project_namespace_id": 32,
  "owners": [{
    "name": "John",
    "email": "user1@example.com"
  }],
  "project_visibility": "private"
}
```

## サブグループイベント {#subgroup-events}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

これらのイベントは、[グループWebhook](webhooks.md#group-webhooks)に対してのみトリガーされます。

サブグループイベントは、次の場合にトリガーされます。

- [グループ内にサブグループが作成された](#create-a-subgroup-in-a-group)場合。
- [グループからサブグループが削除された](#remove-a-subgroup-from-a-group)場合。

### グループ内にサブグループを作成する {#create-a-subgroup-in-a-group}

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Subgroup Hook
```

ペイロードの例:

```json
{

  "created_at": "2021-01-20T09:40:12Z",
  "updated_at": "2021-01-20T09:40:12Z",
  "event_name": "subgroup_create",
  "name": "subgroup1",
  "path": "subgroup1",
  "full_path": "group1/subgroup1",
  "group_id": 10,
  "parent_group_id": 7,
  "parent_name": "group1",
  "parent_path": "group1",
  "parent_full_path": "group1"

}
```

### グループからサブグループを削除する {#remove-a-subgroup-from-a-group}

このWebhookは、[サブグループが新しい親グループに転送された](../../group/manage.md#transfer-a-group)ときにトリガーされません。

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Subgroup Hook
```

ペイロードの例:

```json
{

  "created_at": "2021-01-20T09:40:12Z",
  "updated_at": "2021-01-20T09:40:12Z",
  "event_name": "subgroup_destroy",
  "name": "subgroup1",
  "path": "subgroup1",
  "full_path": "group1/subgroup1",
  "group_id": 10,
  "parent_group_id": 7,
  "parent_name": "group1",
  "parent_path": "group1",
  "parent_full_path": "group1"

}
```

## 機能フラグイベント {#feature-flag-events}

機能フラグイベントは、機能フラグがオンまたはオフになるとトリガーされます。

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Feature Flag Hook
```

ペイロードの例:

```json
{
  "object_kind": "feature_flag",
  "project": {
    "id": 1,
    "name":"Gitlab Test",
    "description":"Aut reprehenderit ut est.",
    "web_url":"http://example.com/gitlabhq/gitlab-test",
    "avatar_url":null,
    "git_ssh_url":"git@example.com:gitlabhq/gitlab-test.git",
    "git_http_url":"http://example.com/gitlabhq/gitlab-test.git",
    "namespace":"GitlabHQ",
    "visibility_level":20,
    "path_with_namespace":"gitlabhq/gitlab-test",
    "default_branch":"master",
    "ci_config_path": null,
    "homepage":"http://example.com/gitlabhq/gitlab-test",
    "url":"http://example.com/gitlabhq/gitlab-test.git",
    "ssh_url":"git@example.com:gitlabhq/gitlab-test.git",
    "http_url":"http://example.com/gitlabhq/gitlab-test.git"
  },
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "email": "admin@example.com"
  },
  "user_url": "http://example.com/root",
  "object_attributes": {
    "id": 6,
    "name": "test-feature-flag",
    "description": "test-feature-flag-description",
    "active": true
  }
}
```

## リリースイベント {#release-events}

{{< history >}}

- リリース削除イベントは、GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/418113)されました。

{{< /history >}}

リリースイベントは、リリースが作成、更新、または削除されるとトリガーされます。

ペイロードの`object_attributes.action`に使用できる値は次のとおりです。

- `create`
- `update`
- `delete`

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Release Hook
```

ペイロードの例:

```json
{
  "id": 1,
  "created_at": "2020-11-02 12:55:12 UTC",
  "description": "v1.1 has been released",
  "name": "v1.1",
  "released_at": "2020-11-02 12:55:12 UTC",
  "tag": "v1.1",
  "object_kind": "release",
  "project": {
    "id": 2,
    "name": "release-webhook-example",
    "description": "",
    "web_url": "https://example.com/gitlab-org/release-webhook-example",
    "avatar_url": null,
    "git_ssh_url": "ssh://git@example.com/gitlab-org/release-webhook-example.git",
    "git_http_url": "https://example.com/gitlab-org/release-webhook-example.git",
    "namespace": "Gitlab",
    "visibility_level": 0,
    "path_with_namespace": "gitlab-org/release-webhook-example",
    "default_branch": "master",
    "ci_config_path": null,
    "homepage": "https://example.com/gitlab-org/release-webhook-example",
    "url": "ssh://git@example.com/gitlab-org/release-webhook-example.git",
    "ssh_url": "ssh://git@example.com/gitlab-org/release-webhook-example.git",
    "http_url": "https://example.com/gitlab-org/release-webhook-example.git"
  },
  "url": "https://example.com/gitlab-org/release-webhook-example/-/releases/v1.1",
  "action": "create",
  "assets": {
    "count": 5,
    "links": [
      {
        "id": 1,
        "link_type": "other",
        "name": "Changelog",
        "url": "https://example.net/changelog"
      }
    ],
    "sources": [
      {
        "format": "zip",
        "url": "https://example.com/gitlab-org/release-webhook-example/-/archive/v1.1/release-webhook-example-v1.1.zip"
      },
      {
        "format": "tar.gz",
        "url": "https://example.com/gitlab-org/release-webhook-example/-/archive/v1.1/release-webhook-example-v1.1.tar.gz"
      },
      {
        "format": "tar.bz2",
        "url": "https://example.com/gitlab-org/release-webhook-example/-/archive/v1.1/release-webhook-example-v1.1.tar.bz2"
      },
      {
        "format": "tar",
        "url": "https://example.com/gitlab-org/release-webhook-example/-/archive/v1.1/release-webhook-example-v1.1.tar"
      }
    ]
  },
  "commit": {
    "id": "ee0a3fb31ac16e11b9dbb596ad16d4af654d08f8",
    "message": "Release v1.1",
    "title": "Release v1.1",
    "timestamp": "2020-10-31T14:58:32+11:00",
    "url": "https://example.com/gitlab-org/release-webhook-example/-/commit/ee0a3fb31ac16e11b9dbb596ad16d4af654d08f8",
    "author": {
      "name": "Example User",
      "email": "user@example.com"
    }
  }
}
```

## マイルストーンイベント {#milestone-events}

{{< history >}}

- GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/14213)されました。

{{< /history >}}

マイルストーンイベントは、マイルストーンが作成、クローズ、再オープン、または削除されたときにトリガーされます。

ペイロードの`object_attributes.action`に使用できる値は次のとおりです。

- `create`
- `close`
- `reopen`

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Milestone Hook
```

ペイロードの例:

```json
{
  "object_kind": "milestone",
  "event_type": "milestone",
  "project": {
    "id": 1,
    "name": "Gitlab Test",
    "description": "Aut reprehenderit ut est.",
    "web_url": "http://example.com/gitlabhq/gitlab-test",
    "avatar_url": null,
    "git_ssh_url": "git@example.com:gitlabhq/gitlab-test.git",
    "git_http_url": "http://example.com/gitlabhq/gitlab-test.git",
    "namespace": "GitlabHQ",
    "visibility_level": 20,
    "path_with_namespace": "gitlabhq/gitlab-test",
    "default_branch": "master",
    "ci_config_path": null,
    "homepage": "http://example.com/gitlabhq/gitlab-test",
    "url": "http://example.com/gitlabhq/gitlab-test.git",
    "ssh_url": "git@example.com:gitlabhq/gitlab-test.git",
    "http_url": "http://example.com/gitlabhq/gitlab-test.git"
  },
  "object_attributes": {
    "id": 61,
    "iid": 10,
    "title": "v1.0",
    "description": "First stable release",
    "state": "active",
    "created_at": "2025-06-16 14:10:57 UTC",
    "updated_at": "2025-06-16 14:10:57 UTC",
    "due_date": "2025-06-30",
    "start_date": "2025-06-16",
    "group_id": null,
    "project_id": 1
  },
  "action": "create"
}
```

## 絵文字イベント {#emoji-events}

{{< history >}}

- GitLab 16.2で`emoji_webhooks`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123952)されました。デフォルトでは無効になっています。
- GitLab 16.3の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/417288)。
- GitLab 16.4で[デフォルトで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/417288)。
- GitLab 17.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/417288)になりました。機能フラグ`emoji_webhooks`は削除されました。

{{< /history >}}

絵文字イベントは、[絵文字リアクション](../../emoji_reactions.md)が以下のものに追加または削除されたときにトリガーされます。

- イシュー
- マージリクエスト
- プロジェクトスニペット
- 次に対するコメント:
  - イシュー
  - マージリクエスト
  - プロジェクトスニペット
  - コミット

ペイロードの`object_attributes.action`に使用できる値は次のとおりです。

- `award`（リアクションを追加する）
- `revoke`（リアクションを削除する）

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Emoji Hook
```

ペイロードの例:

```json
{
  "object_kind": "emoji",
  "event_type": "award",
  "user": {
    "id": 1,
    "name": "Blake Bergstrom",
    "username": "root",
    "avatar_url": "http://example.com/uploads/-/system/user/avatar/1/avatar.png",
    "email": "[REDACTED]"
  },
  "project_id": 6,
  "project": {
    "id": 6,
    "name": "Flight",
    "description": "Velit fugit aperiam illum deleniti odio sequi.",
    "web_url": "http://example.com/flightjs/Flight",
    "avatar_url": null,
    "git_ssh_url": "ssh://git@example.com/flightjs/Flight.git",
    "git_http_url": "http://example.com/flightjs/Flight.git",
    "namespace": "Flightjs",
    "visibility_level": 20,
    "path_with_namespace": "flightjs/Flight",
    "default_branch": "master",
    "ci_config_path": null,
    "homepage": "http://example.com/flightjs/Flight",
    "url": "ssh://git@example.com/flightjs/Flight.git",
    "ssh_url": "ssh://git@example.com/flightjs/Flight.git",
    "http_url": "http://example.com/flightjs/Flight.git"
  },
  "object_attributes": {
    "user_id": 1,
    "created_at": "2023-07-04 20:44:11 UTC",
    "id": 1,
    "name": "thumbsup",
    "awardable_type": "Note",
    "awardable_id": 363,
    "updated_at": "2023-07-04 20:44:11 UTC",
    "action": "award",
    "awarded_on_url": "http://example.com/flightjs/Flight/-/issues/42#note_363"
  },
  "note": {
    "attachment": null,
    "author_id": 1,
    "change_position": null,
    "commit_id": null,
    "created_at": "2023-07-04 15:09:55 UTC",
    "discussion_id": "c3d97fd471f210a5dc8b97a409e3bea95ee06c14",
    "id": 363,
    "line_code": null,
    "note": "Testing 123",
    "noteable_id": 635,
    "noteable_type": "Issue",
    "original_position": null,
    "position": null,
    "project_id": 6,
    "resolved_at": null,
    "resolved_by_id": null,
    "resolved_by_push": null,
    "st_diff": null,
    "system": false,
    "type": null,
    "updated_at": "2023-07-04 19:58:46 UTC",
    "updated_by_id": null,
    "description": "Testing 123",
    "url": "http://example.com/flightjs/Flight/-/issues/42#note_363"
  },
  "issue": {
    "author_id": 1,
    "closed_at": null,
    "confidential": false,
    "created_at": "2023-07-04 14:59:43 UTC",
    "description": "Issue description!",
    "discussion_locked": null,
    "due_date": null,
    "id": 635,
    "iid": 42,
    "last_edited_at": null,
    "last_edited_by_id": null,
    "milestone_id": null,
    "moved_to_id": null,
    "duplicated_to_id": null,
    "project_id": 6,
    "relative_position": 18981,
    "state_id": 1,
    "time_estimate": 0,
    "title": "New issue!",
    "updated_at": "2023-07-04 15:09:55 UTC",
    "updated_by_id": null,
    "weight": null,
    "health_status": null,
    "url": "http://example.com/flightjs/Flight/-/issues/42",
    "total_time_spent": 0,
    "time_change": 0,
    "human_total_time_spent": null,
    "human_time_change": null,
    "human_time_estimate": null,
    "assignee_ids": [
      1
    ],
    "assignee_id": 1,
    "labels": [

    ],
    "state": "opened",
    "severity": "unknown"
  }
}
```

## プロジェクトアクセストークンイベントとグループアクセストークンイベント {#project-and-group-access-token-events}

{{< history >}}

- GitLab 16.10で`access_token_webhooks`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141907)されました。デフォルトでは無効になっています。
- GitLab 16.11の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/439379)。
- GitLab 16.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/454642)になりました。機能フラグ`access_token_webhooks`は削除されました。
- GitLab 17.4で`full_path`属性が[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/465421)されました。
- GitLab 17.7で60日前の通知と30日前の通知が[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173792)になりました。

{{< /history >}}

アクセストークンの有効期限イベントは、[アクセストークン](../../../security/tokens/_index.md)が有効期限切れになる前にトリガーされます。これらのイベントは、次の場合にトリガーされます。

- トークンの有効期限の1日前
- トークンの有効期限の7日前
- トークンの有効期限が切れる30日前（設定が必要）。
- トークンの有効期限が切れる60日前（設定が必要）。

30日間および60日間の通知の設定に関する情報については、以下を参照してください:

- [プロジェクトアクセストークン有効期限の追加Webhookトリガー](../settings/_index.md#add-additional-webhook-triggers-for-project-access-token-expiration)を追加します。
- [グループアクセストークン有効期限の追加Webhookトリガー](../../group/manage.md#add-additional-webhook-triggers-for-group-access-token-expiration)を追加します。

ペイロードの`event_name`に使用できる値は次のとおりです。

- `expiring_access_token`

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Resource Access Token Hook
```

プロジェクトのペイロードの例:

```json
{
  "object_kind": "access_token",
  "project": {
    "id": 7,
    "name": "Flight",
    "description": "Eum dolore maxime atque reprehenderit voluptatem.",
    "web_url": "https://example.com/flightjs/Flight",
    "avatar_url": null,
    "git_ssh_url": "ssh://git@example.com/flightjs/Flight.git",
    "git_http_url": "https://example.com/flightjs/Flight.git",
    "namespace": "Flightjs",
    "visibility_level": 0,
    "path_with_namespace": "flightjs/Flight",
    "default_branch": "master",
    "ci_config_path": null,
    "homepage": "https://example.com/flightjs/Flight",
    "url": "ssh://git@example.com/flightjs/Flight.git",
    "ssh_url": "ssh://git@example.com/flightjs/Flight.git",
    "http_url": "https://example.com/flightjs/Flight.git"
  },
  "object_attributes": {
    "user_id": 90,
    "created_at": "2024-01-24 16:27:40 UTC",
    "id": 25,
    "name": "acd",
    "expires_at": "2024-01-26",
    "last_used_at": "2024-01-20 10:15:30 UTC"
  },
  "event_name": "expiring_access_token"
}
```

グループのペイロードの例:

```json
{
  "object_kind": "access_token",
  "group": {
    "group_name": "Twitter",
    "group_path": "twitter",
    "group_id": 35,
    "full_path": "twitter"
  },
  "object_attributes": {
    "user_id": 90,
    "created_at": "2024-01-24 16:27:40 UTC",
    "id": 25,
    "name": "acd",
    "expires_at": "2024-01-26",
    "last_used_at": "2024-01-20 10:15:30 UTC"
  },
  "event_name": "expiring_access_token"
}
```

## プロジェクトおよびグループデプロイトークンイベント {#project-and-group-deploy-token-events}

{{< history >}}

- GitLab 18.4で`project_deploy_token_expiring_notifications`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196804)されました。デフォルトでは無効になっています。

{{< /history >}}

デプロイトークンの有効期限イベントは、[デプロイトークン](../../../security/tokens/_index.md)の有効期限が切れる前にトリガーされます。これらのイベントは、次の場合にトリガーされます。

- トークンの有効期限が切れる7日前。
- トークンの有効期限が切れる30日前。
- トークンの有効期限が切れる60日前。

ペイロードの`event_name`に使用できる値は次のとおりです。

- `expiring_deploy_token`

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Resource Deploy Token Hook
```

プロジェクトのペイロードの例:

```json
{
  "object_kind": "deploy_token",
  "project": {
    "id": 2,
    "name": "Gitlab Test",
    "description": "Voluptates sit architecto quos distinctio.",
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test",
    "avatar_url": null,
    "git_ssh_url": "ssh://git@gitlab.example.com:2222/gitlab-org/gitlab-test.git",
    "git_http_url": "https://gitlab.example.com/gitlab-org/gitlab-test.git",
    "namespace": "Gitlab Org",
    "visibility_level": 10,
    "path_with_namespace": "gitlab-org/gitlab-test",
    "default_branch": "master",
    "ci_config_path": null,
    "homepage": "https://gitlab.example.com/gitlab-org/gitlab-test",
    "url": "ssh://git@gitlab.example.com:2222/gitlab-org/gitlab-test.git",
    "ssh_url": "ssh://git@gitlab.example.com:2222/gitlab-org/gitlab-test.git",
    "http_url": "https://gitlab.example.com/gitlab-org/gitlab-test.git"
  },
  "object_attributes": {
    "id": 79,
    "name": "seven-days-6days",
    "expires_at": "2025-08-03 07:57:25 UTC",
    "created_at": "2025-07-28 07:57:25 UTC",
    "revoked": false,
    "deploy_token_type": "project_type"
  },
  "event_name": "expiring_deploy_token"
}
```

## 脆弱性イベント {#vulnerability-events}

{{< history >}}

- GitLab 17.7で`vulnerabilities_as_webhook_events`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169701)されました。デフォルトでは無効になっています。
- GitLab 17.8で、脆弱性の作成時またはイシューが脆弱性にリンクされたときのイベント作成が[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176064)されました。
- GitLab 17.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/528397)になりました。機能フラグ`vulnerabilities_as_webhook_events`は削除されました。

{{< /history >}}

脆弱性イベントは、次の場合にトリガーされます。

- 脆弱性が作成された場合。
- 脆弱性の[状態が変更された](../../application_security/vulnerabilities/_index.md#vulnerability-status-values)場合。
- イシューが脆弱性にリンクされ場合。

リクエストヘッダー:

```plaintext
X-Gitlab-Event: Vulnerability Hook
```

ペイロードの例:

```json
{
  "object_kind": "vulnerability",
  "object_attributes": {
    "url": "https://example.com/flightjs/Flight/-/security/vulnerabilities/1",
    "title": "REXML DoS vulnerability",
    "state": "confirmed",
    "project_id": 50,
    "location": {
      "file": "Gemfile.lock",
      "dependency": {
        "package": {
          "name": "rexml"
        },
        "version": "3.3.1"
      }
    },
    "cvss": [
      {
        "vector": "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H",
        "vendor": "NVD"
      }
    ],
    "severity": "high",
    "severity_overridden": false,
    "identifiers": [
      {
        "name": "Gemnasium-29dce398-220a-4315-8c84-16cd8b6d9b05",
        "external_id": "29dce398-220a-4315-8c84-16cd8b6d9b05",
        "external_type": "gemnasium",
        "url": "https://gitlab.com/gitlab-org/security-products/gemnasium-db/-/blob/master/gem/rexml/CVE-2024-41123.yml"
      },
      {
        "name": "CVE-2024-41123",
        "external_id": "CVE-2024-41123",
        "external_type": "cve",
        "url": "https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2024-41123"
      }
    ],
    "issues": [
      {
        "title": "REXML ReDoS vulnerability",
        "url": "https://example.com/flightjs/Flight/-/issues/1",
        "created_at": "2025-01-08T00:46:14.429Z",
        "updated_at": "2025-01-08T00:46:14.429Z"
      }
    ],
    "report_type": "dependency_scanning",
    "confidence": "unknown",
    "confidence_overridden": false,
    "confirmed_at": "2025-01-08T00:46:14.413Z",
    "confirmed_by_id": 1,
    "dismissed_at": null,
    "dismissed_by_id": null,
    "resolved_at": null,
    "resolved_by_id": null,
    "auto_resolved": false,
    "resolved_on_default_branch": false,
    "created_at": "2025-01-08T00:46:14.413Z",
    "updated_at": "2025-01-08T00:46:14.413Z"
  }
}
```
