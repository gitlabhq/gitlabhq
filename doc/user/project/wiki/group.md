---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Group wikis **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/13195) in GitLab 13.5.

If you use GitLab groups to manage multiple projects, some of your documentation
might span multiple groups. You can create group wikis, instead of [project wikis](index.md),
to ensure all group members have the correct access permissions to contribute.
Group wikis are similar to [project wikis](index.md), with a few limitations:

- [Git LFS](../../../topics/git/lfs/index.md) is not supported.
- Group wikis are not included in [global search](../../search/advanced_search.md).
- Changes to group wikis don't show up in the [group's activity feed](../../group/manage.md#group-activity-analytics).

For updates, follow [the epic that tracks feature parity with project wikis](https://gitlab.com/groups/gitlab-org/-/epics/2782).

Similar to project wikis, group members with at least the Developer role
can edit group wikis. Group wiki repositories can be moved using the
[Group repository storage moves API](../../../api/group_repository_storage_moves.md).

## View a group wiki

To access a group wiki:

1. On the top bar, select **Main menu > Groups** and find your group.
1. To display the wiki, either:
   - On the left sidebar, select **Wiki**.
   - On any page in the project, use the <kbd>g</kbd> + <kbd>w</kbd>
     [wiki keyboard shortcut](../../shortcuts.md).

## Export a group wiki

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/53247) in GitLab 13.9.

Users with the Owner role in a group can
[import or export a group wiki](../../group/import/index.md#migrate-groups-by-uploading-an-export-file-deprecated) when they
import or export a group.

Content created in a group wiki is not deleted when an account is downgraded or a
GitLab trial ends. The group wiki data is exported whenever the group owner of
the wiki is exported.

To access the group wiki data from the export file if the feature is no longer
available, you have to:

1. Extract the [export file tarball](../../group/import/index.md#migrate-groups-by-uploading-an-export-file-deprecated)
   with this command, replacing `FILENAME` with your file's name:
   `tar -xvzf FILENAME.tar.gz`
1. Browse to the `repositories` directory. This directory contains a
   [Git bundle](https://git-scm.com/docs/git-bundle) with the extension `.wiki.bundle`.
1. Clone the Git bundle into a new repository, replacing `FILENAME` with
   your bundle's name: `git clone FILENAME.wiki.bundle`

All files in the wiki are available in this Git repository.

## Configure group wiki visibility

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/208412) in GitLab 15.0.

Wikis are enabled by default in GitLab. Group [administrators](../../permissions.md)
can enable or disable a group wiki through the group settings.

To open group settings:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. Expand **Permissions and group features**.
1. Scroll to **Wiki** and select one of these options:
   - **Enabled**: For public groups, everyone can access the wiki. For internal groups, only authenticated users can access the wiki.
   - **Private**: Only group members can access the wiki.
   - **Disabled**: The wiki isn't accessible, and cannot be downloaded.
1. Select **Save changes**.

## Related topics

- [Wiki settings for administrators](../../../administration/wikis/index.md)
- [Project wikis API](../../../api/wikis.md)
- [Group repository storage moves API](../../../api/group_repository_storage_moves.md)
- [Group wikis API](../../../api/group_wikis.md)
- [Wiki keyboard shortcuts](../../shortcuts.md#wiki-pages)
- [Epic: Feature parity with project wikis](https://gitlab.com/groups/gitlab-org/-/epics/2782)
