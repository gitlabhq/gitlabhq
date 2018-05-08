# Repository mirroring

Repository Mirroring is a way to mirror repositories from external sources.
It can be used to mirror all branches, tags, and commits that you have
in your repository.

Your mirror at GitLab will be updated automatically. You can
also manually trigger an update at most once every 5 minutes.

## Overview

Repository mirroring is very useful when, for some reason, you must use a
project from another source.

There are two kinds of repository mirroring features supported by GitLab:
**push** and **pull**, the latter being only available in GitLab Enterprise Edition.
The **push** method mirrors the repository in GitLab to another location.

Once the mirror repository is updated, all new branches,
tags, and commits will be visible in the project's activity feed.
Users with at least [developer access][perms] to the project can also force an
immediate update with the click of a button. This button will not be available if
the mirror is already being updated or 5 minutes still haven't passed since its last update.

A few things/limitations to consider:

- The repository must be accessible over `http://`, `https://`, `ssh://` or `git://`.
- If your HTTP repository is not publicly accessible, add authentication
  information to the URL, like: `https://username@gitlab.company.com/group/project.git`.
  In some cases, you might need to use a personal access token instead of a
  password, e.g., you want to mirror to GitHub and have 2FA enabled.
- The import will time out after 15 minutes. For repositories that take longer
  use a clone/push combination.
- The Git LFS objects will not be synced. You'll need to push/pull them
  manually.

## Use-case

- You have old projects in another source that you don't use actively anymore,
  but don't want to remove for archiving purposes. In that case, you can create
  a push mirror so that your active GitLab repository can push its changes to the
  old location.

## Pushing to a remote repository **[STARTER]**

>[Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/249) in
GitLab Enterprise Edition 8.7. [Moved to GitLab Community Edition][ce-18715] in 10.8.

For an existing project, you can set up push mirror from your project's
**Settings ➔ Repository** and searching for the "Push to a remote repository"
section. Check the "Remote mirror repository" box and fill in the Git URL of
the repository to push to. Click **Save changes** for the changes to take
effect.

![Push settings](repository_mirroring/repository_mirroring_push_settings.png)

When push mirroring is enabled, you are advised not to push commits directly
to the mirrored repository to prevent the mirror diverging.
All changes will end up in the mirrored repository whenever commits
are pushed to GitLab, or when a [forced update](#forcing-an-update) is
initiated.

Pushes into GitLab are automatically pushed to the remote mirror at least once
every 5 minutes after they are received or once every minute if **push only
protected branches** is enabled.

In case of a diverged branch, you will see an error indicated at the **Mirror
repository** settings.

![Diverged branch](
repository_mirroring/repository_mirroring_diverged_branch_push.png)

### Push only protected branches

>[Introduced][ee-3350] in GitLab Enterprise Edition 10.3. [Moved to GitLab Community Edition][ce-18715] in 10.8.

You can choose to only push your protected branches from GitLab to your remote repository.

To use this option go to your project's repository settings page under push mirror.

## Setting up a push mirror from GitLab to GitHub

To set up a mirror from GitLab to GitHub, you need to follow these steps:

1. Create a [GitHub personal access token](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/) with the "public_repo" box checked:
    
    ![edit personal access token GitHub](repository_mirroring/repository_mirroring_github_edit_personal_access_token.png)

1. Fill in the "Git repository URL" with the personal access token replacing the password `https://GitHubUsername:GitHubPersonalAccessToken@github.com/group/project.git`:

    ![push to remote repo](repository_mirroring/repository_mirroring_gitlab_push_to_a_remote_repository.png)

1. Save
1. And either wait or trigger the "Update Now" button:

    ![update now](repository_mirroring/repository_mirroring_gitlab_push_to_a_remote_repository_update_now.png)
    
## Forcing an update

While mirrors are scheduled to update automatically, you can always force an update
by using the **Update now** button which is exposed in various places:

- in the commits page
- in the branches page
- in the tags page
- in the **Mirror repository** settings page

[ee-3350]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/3350
[ce-18715]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/18715
[perms]: ../user/permissions.md

