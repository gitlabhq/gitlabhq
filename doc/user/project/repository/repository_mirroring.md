---
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/repository_mirroring.html'
---

# Repository mirroring

Repository mirroring allows for mirroring of repositories to and from external sources. It can be
used to mirror branches, tags, and commits between repositories.

A repository mirror at GitLab will be updated automatically. You can also manually trigger an update
at most once every 5 minutes.

## Overview

Repository mirroring is useful when you want to use a repository outside of GitLab.

There are two kinds of repository mirroring supported by GitLab:

- Push: for mirroring a GitLab repository to another location.
- Pull: for mirroring a repository from another location to GitLab. **(STARTER)**

When the mirror repository is updated, all new branches, tags, and commits will be visible in the
project's activity feed.

Users with at least [Developer access](../../permissions.md) to the project can also force an
immediate update, unless:

- The mirror is already being updated.
- 5 minutes haven't elapsed since its last update.

## Use cases

The following are some possible use cases for repository mirroring:

- You migrated to GitLab but still need to keep your project in another source. In that case, you
  can simply set it up to mirror to GitLab (pull) and all the essential history of commits, tags,
  and branches will be available in your GitLab instance. **(STARTER)**
- You have old projects in another source that you don't use actively anymore, but don't want to
  remove for archiving purposes. In that case, you can create a push mirror so that your active
  GitLab repository can push its changes to the old location.

## Pushing to a remote repository **(CORE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/249) in GitLab Enterprise Edition 8.7.
> - [Moved to GitLab Core](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/18715) in 10.8.

For an existing project, you can set up push mirroring as follows:

1. Navigate to your project's **Settings > Repository** and expand the **Mirroring repositories** section.
1. Enter a repository URL.
1. Select **Push** from the **Mirror direction** dropdown.
1. Select an authentication method from the **Authentication method** dropdown, if necessary.
1. Check the **Only mirror protected branches** box, if necessary.
1. Click the **Mirror repository** button to save the configuration.

![Repository mirroring push settings screen](img/repository_mirroring_push_settings.png)

When push mirroring is enabled, only push commits directly to the mirrored repository to prevent the
mirror diverging. All changes will end up in the mirrored repository whenever:

- Commits are pushed to GitLab.
- A [forced update](#forcing-an-update-core) is initiated.

Changes pushed to files in the repository are automatically pushed to the remote mirror at least:

- Within five minutes of being received.
- Within one minute if **Only mirror protected branches** is enabled.

In the case of a diverged branch, you will see an error indicated at the **Mirroring repositories**
section.

### Push only protected branches **(CORE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/3350) in [GitLab Starter](https://about.gitlab.com/pricing/) 10.3.
> - [Moved to GitLab Core](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/18715) in 10.8.

You can choose to only push your protected branches from GitLab to your remote repository.

To use this option, check the **Only mirror protected branches** box when creating a repository
mirror.

## Setting up a push mirror from GitLab to GitHub **(CORE)**

To set up a mirror from GitLab to GitHub, you need to follow these steps:

1. Create a [GitHub personal access token](https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line) with the `public_repo` box checked.
1. Fill in the **Git repository URL** field using this format: `https://<your_github_username>@github.com/<your_github_group>/<your_github_project>.git`.
1. Fill in **Password** field with your GitHub personal access token.
1. Click the **Mirror repository** button.

The mirrored repository will be listed. For example, `https://*****:*****@github.com/<your_github_group>/<your_github_project>.git`.

The repository will push soon. To force a push, click the appropriate button.

## Setting up a push mirror to another GitLab instance with 2FA activated

1. On the destination GitLab instance, create a [personal access token](../../profile/personal_access_tokens.md) with `API` scope.
1. On the source GitLab instance:
   1. Fill in the **Git repository URL** field using this format: `https://oauth2@<destination host>/<your_gitlab_group_or_name>/<your_gitlab_project>.git`.
   1. Fill in **Password** field with the GitLab personal access token created on the destination GitLab instance.
   1. Click the **Mirror repository** button.

## Pulling from a remote repository **(STARTER)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/51) in GitLab Enterprise Edition 8.2.
> - [Added Git LFS support](https://gitlab.com/gitlab-org/gitlab/issues/10871) in [GitLab Starter](https://about.gitlab.com/pricing/) 11.11.

NOTE: **Note:** This feature [is available for free](https://gitlab.com/gitlab-org/gitlab/issues/10361) to
GitLab.com users until March 22nd, 2020.

You can set up a repository to automatically have its branches, tags, and commits updated from an
upstream repository.

This is useful when a repository you're interested in is located on a different server, and you want
to be able to browse its content and its activity using the familiar GitLab interface.

To configure mirror pulling for an existing project:

1. Navigate to your project's **Settings > Repository** and expand the **Mirroring repositories**
   section.
1. Enter a repository URL.
1. Select **Pull** from the **Mirror direction** dropdown.
1. Select an authentication method from the **Authentication method** dropdown, if necessary.
1. If necessary, check the following boxes:
   - **Overwrite diverged branches**.
   - **Trigger pipelines for mirror updates**.
   - **Only mirror protected branches**.
1. Click the **Mirror repository** button to save the configuration.

![Repository mirroring pull settings screen - upper part](img/repository_mirroring_pull_settings_upper.png)

---

![Repository mirroring pull settings screen - lower part](img/repository_mirroring_pull_settings_lower.png)

Because GitLab is now set to pull changes from the upstream repository, you should not push commits
directly to the repository on GitLab. Instead, any commits should be pushed to the upstream repository.
Changes pushed to the upstream repository will be pulled into the GitLab repository, either:

- Automatically within a certain period of time.
- When a [forced update](#forcing-an-update-core) is initiated.

CAUTION: **Caution:**
If you do manually update a branch in the GitLab repository, the branch will become diverged from
upstream and GitLab will no longer automatically update this branch to prevent any changes from being lost.
Also note that deleted branches and tags in the upstream repository will not be reflected in the GitLab repository.

### How it works

Once the pull mirroring feature has been enabled for a repository, the repository is added to a queue.

Once per minute, a Sidekiq cron job schedules repository mirrors to update, based on:

- The capacity available. This is determined by Sidekiq settings. For GitLab.com, see [GitLab.com Sidekiq settings](../../gitlab_com/index.md#sidekiq).
- The number of repository mirrors already in the queue that are due to be updated. Being due depends on when the repository mirror was last updated and how many times it's been retried.

Repository mirrors are updated as Sidekiq becomes available to process them. If the process of updating the repository mirror:

- Succeeds, an update will be enqueued again with at least a 30 minute wait.
- Fails (for example, a branch diverged from upstream), it will be attempted again later. Mirrors can fail
  up to 14 times before they will not be enqueued for update again.

### SSH authentication

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/2551) for Pull mirroring in [GitLab Starter](https://about.gitlab.com/pricing/) 9.5.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/22982) for Push mirroring in [GitLab Core](https://about.gitlab.com/pricing/) 11.6

SSH authentication is mutual:

- You have to prove to the server that you're allowed to access the repository.
- The server also has to prove to *you* that it's who it claims to be.

You provide your credentials as a password or public key. The server that the
other repository resides on provides its credentials as a "host key", the
fingerprint of which needs to be verified manually.

If you're mirroring over SSH (that is, using an `ssh://` URL), you can authenticate using:

- Password-based authentication, just as over HTTPS.
- Public key authentication. This is often more secure than password authentication,
  especially when the other repository supports [Deploy Keys](../../../ssh/README.md#deploy-keys).

To get started:

1. Navigate to your project's **Settings > Repository** and expand the **Mirroring repositories** section.
1. Enter an `ssh://` URL for mirroring.

NOTE: **Note:**
SCP-style URLs (that is, `git@example.com:group/project.git`) are not supported at this time.

Entering the URL adds two buttons to the page:

- **Detect host keys**.
- **Input host keys manually**.

If you click the:

- **Detect host keys** button, GitLab will fetch the host keys from the server and display the fingerprints.
- **Input host keys manually** button, a field is displayed where you can paste in host keys.

Assuming you used the former, you now need to verify that the fingerprints are
those you expect. GitLab.com and other code hosting sites publish their
fingerprints in the open for you to check:

- [AWS CodeCommit](https://docs.aws.amazon.com/codecommit/latest/userguide/regions.html#regions-fingerprints)
- [Bitbucket](https://confluence.atlassian.com/bitbucket/ssh-keys-935365775.html)
- [GitHub](https://help.github.com/en/articles/githubs-ssh-key-fingerprints)
- [GitLab.com](../../gitlab_com/index.md#ssh-host-keys-fingerprints)
- [Launchpad](https://help.launchpad.net/SSHFingerprints)
- [Savannah](http://savannah.gnu.org/maintenance/SshAccess/)
- [SourceForge](https://sourceforge.net/p/forge/documentation/SSH%20Key%20Fingerprints/)

Other providers will vary. If you're running self-managed GitLab, or otherwise
have access to the server for the other repository, you can securely gather the
key fingerprints:

```sh
$ cat /etc/ssh/ssh_host*pub | ssh-keygen -E md5 -l -f -
256 MD5:f4:28:9f:23:99:15:21:1b:bf:ed:1f:8e:a0:76:b2:9d root@example.com (ECDSA)
256 MD5:e6:eb:45:8a:3c:59:35:5f:e9:5b:80:12:be:7e:22:73 root@example.com (ED25519)
2048 MD5:3f:72:be:3d:62:03:5c:62:83:e8:6e:14:34:3a:85:1d root@example.com (RSA)
```

NOTE: **Note:**
You may need to exclude `-E md5` for some older versions of SSH.

When mirroring the repository, GitLab will now check that at least one of the
stored host keys matches before connecting. This can prevent malicious code from
being injected into your mirror, or your password being stolen.

### SSH public key authentication

To use SSH public key authentication, you'll also need to choose that option
from the **Authentication method** dropdown. When the mirror is created,
GitLab generates a 4096-bit RSA key that can be copied by clicking the **Copy SSH public key** button.

![Repository mirroring copy SSH public key to clipboard button](img/repository_mirroring_copy_ssh_public_key_button.png)

You then need to add the public SSH key to the other repository's configuration:

- If the other repository is hosted on GitLab, you should add the public SSH key
  as a [Deploy Key](../../../ssh/README.md#deploy-keys).
- If the other repository is hosted elsewhere, you may need to add the key to
  your user's  `authorized_keys` file. Paste the entire public SSH key into the
  file on its own line and save it.

If you need to change the key at any time, you can remove and re-add the mirror
to generate a new key. You'll have to update the other repository with the new
key to keep the mirror running.

NOTE: **Note:**
The generated keys are stored in the GitLab database, not in the filesystem. Therefore,
SSH public key authentication for mirrors cannot be used in a pre-receive hook.

### Overwrite diverged branches **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/4559) in [GitLab Starter](https://about.gitlab.com/pricing/) 10.6.

You can choose to always update your local branches with remote versions, even if they have
diverged from the remote.

CAUTION: **Caution:**
For mirrored branches, enabling this option results in the loss of local changes.

To use this option, check the **Overwrite diverged branches** box when creating a repository mirror.

### Only mirror protected branches **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/3326) in [GitLab Starter](https://about.gitlab.com/pricing/) 10.3.

You can choose to pull mirror only the protected branches from your remote repository to GitLab.
Non-protected branches are not mirrored and can diverge.

To use this option, check the **Only mirror protected branches** box when creating a repository mirror.

### Hard failure **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/3117) in [GitLab Starter](https://about.gitlab.com/pricing/) 10.2.

Once the mirroring process is unsuccessfully retried 14 times in a row, it will get marked as hard
failed. This will become visible in either the:

- Project's main dashboard.
- Pull mirror settings page.

When a project is hard failed, it will no longer get picked up for mirroring. A user can resume the
project mirroring again by [Forcing an update](#forcing-an-update-core).

### Trigger update using API **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/3453) in [GitLab Starter](https://about.gitlab.com/pricing/) 10.3.

Pull mirroring uses polling to detect new branches and commits added upstream, often minutes
afterwards. If you notify GitLab by [API](../../../api/projects.md#start-the-pull-mirroring-process-for-a-project-starter),
updates will be pulled immediately.

For more information, see [Start the pull mirroring process for a Project](../../../api/projects.md#start-the-pull-mirroring-process-for-a-project-starter).

## Forcing an update **(CORE)**

While mirrors are scheduled to update automatically, you can always force an update by using the
update button which is available on the **Mirroring repositories** section of the **Repository Settings** page.

![Repository mirroring force update user interface](img/repository_mirroring_force_update.png)

## Bidirectional mirroring **(STARTER)**

CAUTION: **Caution:**
Bidirectional mirroring may cause conflicts.

If you configure a GitLab repository to both pull from, and push to, the same remote source, there
is no guarantee that either repository will update correctly. If you set up a repository for
bidirectional mirroring, you should prepare for the likely conflicts by deciding who will resolve
them and how they will be resolved.

Rewriting any mirrored commit on either remote will cause conflicts and mirroring to fail. This can
be prevented by:

- [Pulling only protected branches](#only-mirror-protected-branches-starter).
- [Pushing only protected branches](#push-only-protected-branches-core).

You should [protect the branches](../protected_branches.md) you wish to mirror on both
remotes to prevent conflicts caused by rewriting history.

Bidirectional mirroring also creates a race condition where commits made close together to the same
branch causes conflicts. The race condition can be mitigated by reducing the mirroring delay by using
a [Push event webhook](../integrations/webhooks.md#push-events) to trigger an immediate
pull to GitLab. Push mirroring from GitLab is rate limited to once per minute when only push mirroring
protected branches.

### Preventing conflicts using a `pre-receive` hook

CAUTION: **Warning:**
The solution proposed will negatively impact the performance of
Git push operations because they will be proxied to the upstream Git
repository.

A server-side `pre-receive` hook can be used to prevent the race condition
described above by only accepting the push after first pushing the commit to
the upstream Git repository. In this configuration one Git repository acts as
the authoritative upstream, and the other as downstream. The `pre-receive` hook
will be installed on the downstream repository.

Read about [configuring custom Git hooks](../../../administration/custom_hooks.md) on the GitLab server.

A sample `pre-receive` hook is provided below.

```bash
#!/usr/bin/env bash

# --- Assume only one push mirror target
# Push mirroring remotes are named `remote_mirror_<id>`, this finds the first remote and uses that.
TARGET_REPO=$(git remote | grep -m 1 remote_mirror)

proxy_push()
{
  # --- Arguments
  OLDREV=$(git rev-parse $1)
  NEWREV=$(git rev-parse $2)
  REFNAME="$3"

  # --- Pattern of branches to proxy pushes
  whitelisted=$(expr "$branch" : "\(master\)")

  case "$refname" in
    refs/heads/*)
      branch=$(expr "$refname" : "refs/heads/\(.*\)")

      if [ "$whitelisted" = "$branch" ]; then
        unset GIT_QUARANTINE_PATH # handle https://git-scm.com/docs/git-receive-pack#_quarantine_environment
        error="$(git push --quiet $TARGET_REPO $NEWREV:$REFNAME 2>&1)"
        fail=$?

        if [ "$fail" != "0" ]; then
          echo >&2 ""
          echo >&2 " Error: updates were rejected by upstream server"
          echo >&2 "   This is usually caused by another repository pushing changes"
          echo >&2 "   to the same ref. You may want to first integrate remote changes"
          echo >&2 ""
          return
        fi
      fi
      ;;
  esac
}

# Allow dual mode: run from the command line just like the update hook, or
# if no arguments are given then run as a hook script
if [ -n "$1" -a -n "$2" -a -n "$3" ]; then
  # Output to the terminal in command line mode - if someone wanted to
  # resend an email; they could redirect the output to sendmail
  # themselves
  PAGER= proxy_push $2 $3 $1
else
  # Push is proxied upstream one ref at a time. Because of this it is possible
  # for some refs to succeed, and others to fail. This will result in a failed
  # push.
  while read oldrev newrev refname
  do
    proxy_push $oldrev $newrev $refname
  done
fi
```

Note that this sample has a few limitations:

- This example may not work verbatim for your use case and might need modification.
  - It does not regard different types of authentication mechanisms for the mirror.
  - It does not work with forced updates (rewriting history).
  - Only branches that match the `whitelisted` patterns will be proxy pushed.
- The script circumvents the Git hook quarantine environment because the update of `$TARGET_REPO`
  is seen as a ref update and Git will complain about it.

### Mirroring with Perforce Helix via Git Fusion **(STARTER)**

CAUTION: **Warning:**
Bidirectional mirroring should not be used as a permanent configuration. Refer to
[Migrating from Perforce Helix](../import/perforce.md) for alternative migration approaches.

[Git Fusion](https://www.perforce.com/manuals/git-fusion/#Git-Fusion/section_avy_hyc_gl.html) provides a Git interface
to [Perforce Helix](https://www.perforce.com/products) which can be used by GitLab to bidirectionally
mirror projects with GitLab. This may be useful in some situations when migrating from Perforce Helix
to GitLab where overlapping Perforce Helix workspaces cannot be migrated simultaneously to GitLab.

If using mirroring with Perforce Helix, you should only mirror protected branches. Perforce Helix
will reject any pushes that rewrite history. Only the fewest number of branches should be mirrored
due to the performance limitations of Git Fusion.

When configuring mirroring with Perforce Helix via Git Fusion, the following Git Fusion
settings are recommended:

- `change-pusher` should be disabled. Otherwise, every commit will be rewritten as being committed
  by the mirroring account, rather than being mapped to existing Perforce Helix users or the `unknown_git` user.
- `unknown_git` user will be used as the commit author if the GitLab user does not exist in
  Perforce Helix.

Read about [Git Fusion settings on Perforce.com](https://www.perforce.com/manuals/git-fusion/Content/Git-Fusion/section_vss_bdw_w3.html#section_zdp_zz1_3l).

## Troubleshooting

Should an error occur during a push, GitLab will display an "Error" highlight for that repository. Details on the error can then be seen by hovering over the highlight text.

### 13:Received RST_STREAM with error code 2 with GitHub

If you receive an "13:Received RST_STREAM with error code 2" while mirroring to a GitHub repository, your GitHub settings might be set to block pushes that expose your email address used in commits. Either set your email address on GitHub to be public, or disable the [Block command line pushes that expose my email](https://github.com/settings/emails) setting.
