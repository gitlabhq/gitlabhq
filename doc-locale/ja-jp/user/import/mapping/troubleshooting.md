---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 翻訳移行後のコントリビューションとメンバーシップマッピングに関するトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プレースホルダユーザーの再割り当て中に、次の問題が発生する可能性があります。

## ソースユーザーの再割り当てに失敗しました {#source-user-reassignment-failed}

現在、UIで`failed`ステータスのソースユーザーの再割り当てを再試行する方法はありません。[イシュー589632](https://gitlab.com/gitlab-org/gitlab/-/issues/589632)を参照してください。

ただし、[Railsコンソール](../../../administration/operations/rails_console.md)で失敗したソースユーザーを手動で再試行できます:

```ruby
# Find by the source user's placeholder user ID because placeholder user IDs are easy to fetch from the UI
placeholder_user_id = <PLACEHOLDER_USER_ID>
import_source_user = Import::SourceUser.find_by(placeholder_user_id: placeholder_user_id)

if import_source_user.failed?
  import_source_user.update!(status: Import::SourceUser::STATUSES[:reassignment_in_progress])
  Import::ReassignPlaceholderUserRecordsWorker.perform_async(import_source_user.id)
  puts "Reassignment retry queued"
else
  puts "Import source user status: #{import_source_user.status} (expected 'failed')"
end
```

ソースユーザーが再び失敗する場合は、[`importer.log`](../../../administration/logs/_index.md#importerlog)でメッセージ`Failed to reassign placeholder user`のログを確認して、根本原因の調査を開始してください。

## ソースユーザーは正常に再割り当てされましたが、プレースホルダユーザーが削除されませんでした {#source-user-reassigned-successfully-but-its-placeholder-user-was-not-deleted}

プレースホルダユーザーは、ユーザーのコントリビューションの再割り当てが成功した後に削除されます。ただし、プレースホルダユーザーのIDを参照する一部のデータベースレコードは、再割り当て後もデータベースに存在する可能性があり、プレースホルダユーザーが削除されない場合があります。この場合、管理者は、管理者ユーザーテーブルでプレースホルダユーザーを表示できます。プレースホルダユーザーはライセンス制限にはカウントされず、通常のGitLab操作には影響しませんが、一部の管理者は、移行後にすべてのプレースホルダユーザーを削除することを希望する場合があります。

GitLab 18.5以前にプレースホルダユーザーを再割り当てするユーザーは、このシナリオに遭遇する可能性が高くなります。この場合、`Unable to delete placeholder user because it is still referenced in other tables`というメッセージが、プレースホルダユーザーのIDに関連付けられた[`importer.log`](../../../administration/logs/_index.md#importerlog)に表示されます。

これらのユーザーを削除するには、2つの方法があります:

- [管理者としてプレースホルダユーザーを削除](../../profile/account/delete_account.md#delete-users-and-user-contributions)。この方法は、残りのプレースホルダユーザーのコントリビューションを削除できると確信できる場合に最適です。
- GitLabインスタンスをGitLab 18.6以降にアップグレードし、Railsコンソールでプレースホルダユーザーの再割り当てを再試行します。この方法は、GitLab 18.5以前に再割り当てが完了し、残りのプレースホルダユーザーのコントリビューションが不明な場合に最適です。

[Railsコンソール](../../../administration/operations/rails_console.md)で、完了したプレースホルダユーザーの再割り当てを再試行するには:

```ruby
# Find the placeholder user's source user
placeholder_user_id = <PLACEHOLDER_USER_ID>
import_source_user = Import::SourceUser.find_by(placeholder_user_id: placeholder_user_id)

if import_source_user.completed?
  import_source_user.update!(status: Import::SourceUser::STATUSES[:reassignment_in_progress])
  Import::ReassignPlaceholderUserRecordsWorker.perform_async(import_source_user.id)
  puts "Reassignment retry queued"
else
  puts "Import source user status: #{import_source_user.status} (expected 'completed')"
end
```
