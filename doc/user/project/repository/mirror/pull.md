---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/repository_mirroring.html'
---

# Pull from a remote repository **(PREMIUM)**

> - [Added Git LFS support](https://gitlab.com/gitlab-org/gitlab/-/issues/10871) in GitLab 11.11.
> - Moved to GitLab Premium in 13.9.

You can set up a repository to automatically have its branches, tags, and commits updated from an
upstream repository.

If a repository you're interested in is located on a different server, and you want
to browse its content and its activity using the GitLab interface, you can configure
mirror pulling:

1. If your remote repository is on GitHub and you have
   [two-factor authentication (2FA) configured](https://docs.github.com/en/github/authenticating-to-github/securing-your-account-with-two-factor-authentication-2fa),
   create a [personal access token for GitHub](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token).
   with the `repo` scope. If 2FA is enabled, this personal access
   token serves as your GitHub password.
1. In your project, go to **Settings > Repository**, and then expand the
   **Mirroring repositories** section.
1. In the **Git repository URL** field, enter a repository URL. Include the username
   in the URL if required: `https://MYUSERNAME@github.com/group/PROJECTNAME.git`
1. In the **Mirror direction** dropdown, select **Pull**.
1. In the **Authentication method** dropdown, select your authentication method.
1. Select from the following checkboxes, if needed:
   - **Overwrite diverged branches**
   - **Trigger pipelines for mirror updates**
   - **Only mirror protected branches**
1. Select **Mirror repository** to save the configuration.

Because GitLab is now set to pull changes from the upstream repository, you should not push commits
directly to the repository on GitLab. Instead, any commits should be pushed to the remote repository.
Changes pushed to the remote repository are pulled into the GitLab repository, either:

- Automatically in a certain period of time.
- When a [forced update](index.md#force-an-update) is initiated.

WARNING:
If you do manually update a branch in the GitLab repository, the branch becomes diverged from
upstream, and GitLab no longer automatically updates this branch to prevent any changes from being lost.
Deleted branches and tags in the upstream repository are not reflected in the GitLab repository.

## How it works

After the pull mirroring feature has been enabled for a repository, the repository is added to a queue.

Once per minute, a Sidekiq cron job schedules repository mirrors to update, based on:

- The capacity available. This is determined by Sidekiq settings. For GitLab.com, see [GitLab.com Sidekiq settings](../../../gitlab_com/index.md#sidekiq).
- The number of repository mirrors already in the queue that are due to be updated. Being due depends on when the repository mirror was last updated and how many times it's been retried.

Repository mirrors are updated as Sidekiq becomes available to process them. If the process of updating the repository mirror:

- **Succeeds**: An update is enqueued again with at least a 30 minute wait.
- **Fails**: (For example, a branch diverged from upstream.), The update attempted again later. Mirrors can fail
  up to 14 times before they are no longer enqueued for updates.

## Overwrite diverged branches

> Moved to GitLab Premium in 13.9.

You can choose to always update your local branches with remote versions, even if they have
diverged from the remote.

WARNING:
For mirrored branches, enabling this option results in the loss of local changes.

To use this option, check the **Overwrite diverged branches** box when creating a repository mirror.

## Trigger pipelines for mirror updates

> Moved to GitLab Premium in 13.9.

If this option is enabled, pipelines trigger when branches or tags are
updated from the remote repository. Depending on the activity of the remote
repository, this may greatly increase the load on your CI runners. Only enable
this if you know they can handle the load. CI uses the credentials
assigned when you set up pull mirroring.

## Hard failure

> Moved to GitLab Premium in 13.9.

After 14 consecutive unsuccessful retries, the mirroring process is marked as a hard failure
and mirroring attempts stop. This failure is visible in either the:

- Project's main dashboard.
- Pull mirror settings page.

You can resume the project mirroring again by [forcing an update](index.md#force-an-update).

## Trigger an update using the API

> Moved to GitLab Premium in 13.9.

Pull mirroring uses polling to detect new branches and commits added upstream, often minutes
afterwards. If you notify GitLab by [API](../../../../api/projects.md#start-the-pull-mirroring-process-for-a-project),
updates are pulled immediately.

For more information, see [Start the pull mirroring process for a Project](../../../../api/projects.md#start-the-pull-mirroring-process-for-a-project).
