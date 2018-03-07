# Deleting a User Account

- As a user, you can delete your own account by navigating to **Settings** > **Account** and selecting **Delete account**
- As an admin, you can delete a user account by navigating to the **Admin Area**, selecting the **Users** tab, selecting a user, and clicking on **Delete user**

## Associated Records

> Introduced for issues in [GitLab 9.0][ce-7393], and for merge requests, award
  emoji, notes, and abuse reports in [GitLab 9.1][ce-10467].
  Hard deletion from abuse reports and spam logs was introduced in
  [GitLab 9.1][ce-10273], and from the API in [GitLab 9.3][ce-11853].

When a user account is deleted, not all associated records are deleted with it.
Here's a list of things that will not be deleted:

- Issues that the user created
- Merge requests that the user created
- Notes that the user created
- Abuse reports that the user reported
- Award emoji that the user created

Instead of being deleted, these records will be moved to a system-wide
"Ghost User", whose sole purpose is to act as a container for such records.

When a user is deleted from an abuse report or spam log, these associated
records are not ghosted and will be removed, along with any groups the user
is a sole owner of. Administrators can also request this behaviour when
deleting users from the [API](../../../api/users.md#user-deletion) or the
admin area.

[ce-7393]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/7393
[ce-10273]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/10273
[ce-10467]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/10467
[ce-11853]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/11853

