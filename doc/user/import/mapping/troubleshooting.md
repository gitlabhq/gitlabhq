---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting post-migration contribution and membership mapping
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

During placeholder user reassignment, you might encounter the following issues.

## Source user reassignment failed

There is currently no way to retry reassignment for source users with `failed` status in the UI. See [issue 589632](https://gitlab.com/gitlab-org/gitlab/-/issues/589632).

However, you can manually retry failed source users in the [Rails console](../../../administration/operations/rails_console.md):

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

If the source user fails again, check [`importer.log`](../../../administration/logs/_index.md#importerlog) for any logs with the message `Failed to reassign placeholder user` to begin investigating the root cause.

## Source user reassigned successfully but its placeholder user was not deleted

Placeholder users are deleted after successfully reassigning user contributions. However, some database records that reference the placeholder user's ID might still exist in the database after reassignment, preventing the placeholder user from being deleted. When this happens, administrators can still see placeholder users in the administrator user table. Although placeholder users do not count towards license limits and have no effect on typical GitLab operations, some administrators might prefer to have all placeholder users deleted after migrating.

Users reassigning placeholder users in GitLab 18.5 and earlier are more likely to encounter this scenario. When this happens, the message `Unable to delete placeholder user because it is still referenced in other tables` appears in [`importer.log`](../../../administration/logs/_index.md#importerlog) tied to the placeholder user's ID.

There are two approaches to deleting these users:

- [Delete the placeholder user as an administrator](../../profile/account/delete_account.md#delete-users-and-user-contributions). This approach is best when you're confident any remaining placeholder user contributions can be deleted.
- Upgrade the GitLab instance to GitLab 18.6 or later and retry placeholder reassignment for the placeholder user in the Rails console. This approach is best when reassignment completed on GitLab 18.5 or earlier and you're unsure about what placeholder user contributions remain.

To retry a completed placeholder user's reassignment in the [Rails console](../../../administration/operations/rails_console.md):

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
