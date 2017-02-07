# Repository mirroring

>[Introduced][ee-51] in GitLab Enterprise Edition 8.2.

There are two kinds of repository mirroring features supported by GitLab:
**push** and **pull**. The **push** method mirrors the repository in GitLab
to another location, whereas the **pull** method mirrors an external repository
in one in GitLab.

By default mirror repositories are updated every hour, and all new branches, tags, and
commits will be visible in the project's activity feed.

Users with at least [developer access][perms] to the project can also force an
immediate update with a click of a button.

A few things/limitations to consider:

- The repository must be accessible over `http://`, `https://` or `git://`.
- If your HTTP repository is not publicly accessible, add authentication
  information to the URL, like: `https://username:password@gitlab.company.com/group/project.git`.
  In some cases, you might need to use a personal access token instead of a
  password, e.g., you want to mirror to GitHub and have 2FA enabled.
- The import will time out after 15 minutes. For repositories that take longer
  use a clone/push combination.
- The Git LFS/Annex objects will not be synced. You'll need to push/pull them
  manually.

## Pulling from a remote repository

You can set up a repository to automatically have its branches, tags, and commits
updated from an upstream repository. This is useful when a repository you're
interested in is located on a different server, and you want to be able to
browse its content and its activity using the familiar GitLab interface.

When creating a new project, you can enable repository mirroring when you choose
to import the repository from "Any repo by URL". Enter the full URL of the Git
repository to pull from and click on the **Mirror repository** checkbox.

![New project](repository_mirroring/repository_mirroring_new_project.png)

For an existing project, you can set up mirror pulling by visiting the
**Mirror repository** page under the wheel icon in the upper right corner.
Check the 'Mirror repository' box and hit **Save changes** at the bottom.
You have a few options to choose from one being the user who will be the author
of all events in the activity feed that are the result of an update. This user
needs to have at least [master access][perms] to the project. Another option is
whether you want to trigger builds for mirror updates.

![Pull settings](repository_mirroring/repository_mirroring_pull_settings.png)

Since the repository on GitLab functions as a mirror of the upstream repository,
you are advised not to push commits directly to the repository on GitLab.
Instead, any commits should be pushed to the upstream repository, and will end
up in the GitLab repository automatically within your project's configured
synchronization time, or when a [forced update](#forcing-an-update) is initiated.

If you do manually update a branch in the GitLab repository, the branch will
become diverged from upstream, and GitLab will no longer automatically update
this branch to prevent any changes from being lost.

![Diverged branch](repository_mirroring/repository_mirroring_diverged_branch.png)

## Pushing to a remote repository

You can set up mirror pushing to an existing GitLab project by visiting the
**Mirror repository** page under the wheel icon in the upper right. Simply
click the "Remote mirror repository" checkbox and fill in the Git URL of the
repository to push to. Hit **Save changes** for the changes to take effect.

![Push settings](repository_mirroring/repository_mirroring_push_settings.png)

Similarly to the pull mirroring, since the upstream repository functions as a
mirror to the repository in GitLab, you are advised not to push commits directly
to the mirrored repository. Instead, any commits should be pushed to GitLab,
and will end up in the mirrored repository automatically within the configured time,
or when a [forced update](#forcing-an-update) is initiated.

In case of a diverged branch, you will see an error indicated at the
**Mirror repository** settings.

![Diverged branch](repository_mirroring/repository_mirroring_diverged_branch_push.png)

## Forcing an update

While mirrors update at a pre-configured time (hourly by default), you can always force an update (either **push** or
**pull**) by using the **Update now** button which is exposed in various places:

- in the commits page
- in the branches page
- in the tags page
- in the **Mirror repository** settings page

## Adjusting synchronization times

Your repository's default synchronization time is hourly.
However, you can adjust it by visiting the **Mirror repository** page
under the wheel icon in the upper right corner.
Check the Synchronization time section where you can choose to have your mirror
be updated once every fifteen minutes, hourly or daily and then hit **Save changes**
at the bottom.

## Using both mirroring methods at the same time

Currently there is no bidirectional support without conflicts. That means that
if you configure a repository to both pull and push to a second one, there is
no guarantee that it will update correctly on both remotes. You could
adjust the synchronization times on the mirror settings page
to a very low value and hope that no conflicts occur during
the pull/push window time, but that is not a solution to consider on a
production environment. Another thing you could try is [configuring custom Git hooks][hooks] on the GitLab server.


[ee-51]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/51
[perms]: ../user/permissions.md
[hooks]: https://docs.gitlab.com/ee/administration/custom_hooks.html
