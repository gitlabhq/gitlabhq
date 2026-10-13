---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 監査イベントAPIのレート制限
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 19.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/605428)されました。

{{< /history >}}

インスタンス[監査イベントAPI](../../api/audit_events.md#instance-audit-events)へのリクエストに対して、ユーザーごとの1分あたりのレート制限を設定できます。デフォルトは200です。

レート制限を超過したリクエストは、`auth.log`ファイルにログが記録されます。

この制限は`GET /audit_events`と`GET /audit_events/:id`の両方に適用されます。たとえば、制限を200に設定した場合、1分以内にレートが200を超えるこれらのエンドポイントへのリクエストはブロックされます。1分後にアクセスは復元されます。

## レート制限を変更する {#change-the-rate-limit}

前提条件: 

- 管理者アクセス権。

レート制限を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **ネットワーク**を選択します。
1. **監査イベントAPIレート制限**を展開します。
1. レート制限の値を変更します。レート制限はユーザーごとに1分あたりの制限です。レート制限を無効にするには、値を`0`に設定します。
1. **変更を保存**を選択します。
