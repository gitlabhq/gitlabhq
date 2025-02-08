---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Create bidirectional mirrors to push and pull changes between two Git repositories."
title: Bidirectional mirroring
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Moved to GitLab Premium in 13.9.

WARNING:
Bidirectional mirroring may cause conflicts.

Bidirectional [mirroring](_index.md) configures two repositories to both pull from,
and push to, each other. There is no guarantee that either repository can update
without errors.

## Reduce conflicts in bidirectional mirroring

If you configure bidirectional mirroring, prepare your repositories for
conflicts. Configure them to reduce conflicts, and how to settle them when they occur:

- [Mirror only protected branches](_index.md#mirror-only-protected-branches). Rewriting
  any mirrored commit on either remote causes conflicts and mirroring to fail.
- [Protect the branches](../branches/protected.md) you want to mirror on both
  remotes to prevent conflicts caused by rewriting history.
- Reduce mirroring delay with a [push event webhook](../../integrations/webhook_events.md#push-events).
  Bidirectional mirroring creates a race condition where commits made close together
  to the same branch cause conflicts. Push event webhooks can help mitigate the race
  condition. Push mirroring from GitLab is rate limited to once per minute when only
  push mirroring protected branches.
- Prevent conflicts [using a pre-receive hook](#prevent-conflicts-by-using-a-pre-receive-hook).

## Configure a webhook to trigger an immediate pull to GitLab

A [push event webhook](../../integrations/webhook_events.md#push-events) in the downstream
instance can help reduce race conditions by syncing changes more frequently.

Prerequisites:

- You have configured the [push](push.md#set-up-a-push-mirror-to-another-gitlab-instance-with-2fa-activated)
  and [pull](pull.md) mirrors in the upstream GitLab instance.

To create the webhook in the downstream instance:

1. Create a [personal access token](../../../profile/personal_access_tokens.md) with `API` scope.
1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Webhooks**.
1. Add the webhook **URL**, which (in this case) uses the
   [Pull Mirror API](../../../../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project)
   request to trigger an immediate pull after a repository update:

   ```plaintext
   https://gitlab.example.com/api/v4/projects/:id/mirror/pull?private_token=<your_access_token>
   ```

1. Select **Push Events**.
1. Select **Add Webhook**.

To test the integration, select **Test** and confirm GitLab doesn't return an error message.

## Prevent conflicts by using a pre-receive hook

WARNING:
This solution negatively affects the performance of Git push operations, because
they are proxied to the upstream Git repository.

In this configuration, one Git repository acts as the authoritative upstream, and
the other as downstream. This server-side `pre-receive` hook accepts a push only
after first pushing the commit to the upstream repository. Install this hook on
your downstream repository.

For example:

```shell
#!/usr/bin/env bash

# --- Assume only one push mirror target
# Push mirroring remotes are named `remote_mirror_<id>`.
# This line finds the first remote and uses that.
TARGET_REPO=$(git remote | grep -m 1 remote_mirror)

proxy_push()
{
  # --- Arguments
  OLDREV=$(git rev-parse $1)
  NEWREV=$(git rev-parse $2)
  REFNAME="$3"

  # --- Pattern of branches to proxy pushes
  allowlist=$(expr "$branch" : "\(master\)")

  case "$refname" in
    refs/heads/*)
      branch=$(expr "$refname" : "refs/heads/\(.*\)")

      if [ "$allowlist" = "$branch" ]; then
        # handle https://git-scm.com/docs/git-receive-pack#_quarantine_environment
        unset GIT_QUARANTINE_PATH
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
# if no arguments are given, then run as a hook script:
if [ -n "$1" -a -n "$2" -a -n "$3" ]; then
  # Output to the terminal in command line mode. If someone wanted to
  # resend an email, they could redirect the output to sendmail themselves
  PAGER= proxy_push $2 $3 $1
else
  # Push is proxied upstream one ref at a time. It is possible for some refs
  # to succeed, and others to fail. This results in a failed push.
  while read oldrev newrev refname
  do
    proxy_push $oldrev $newrev $refname
  done
fi
```

This sample has a few limitations:

- It may not work for your use case without modification:
  - It doesn't regard different types of authentication mechanisms for the mirror.
  - It doesn't work with forced updates (rewriting history).
  - Only branches that match the `allowlist` patterns are proxy pushed.
- The script circumvents the Git hook quarantine environment because the update of `$TARGET_REPO`
  is seen as a ref update, and Git displays warnings about it.

## Mirror with Perforce Helix with Git Fusion

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Moved to GitLab Premium in 13.9.

WARNING:
Bidirectional mirroring should not be used as a permanent configuration. Refer to
[Migrating from Perforce Helix](../../import/perforce.md) for alternative migration approaches.

[Git Fusion](https://www.perforce.com/manuals/git-fusion/#Git-Fusion/section_avy_hyc_gl.html) provides a Git interface
to [Perforce Helix](https://www.perforce.com/products). GitLab can use the Perforce Helix
interface to bidirectionally mirror projects. It can help when migrating from Perforce Helix
to GitLab, if overlapping Perforce Helix workspaces cannot be migrated simultaneously.

If you mirror with Perforce Helix, mirror only protected branches. Perforce Helix
rejects any pushes that rewrite history. Only the fewest number of branches should be mirrored
due to the performance limitations of Git Fusion.

When you configure mirroring with Perforce Helix by using Git Fusion, you should use
these Git Fusion settings:

- Disable `change-pusher`. Otherwise, every commit is rewritten as being committed
  by the mirroring account, rather than mapping to existing Perforce Helix users or the `unknown_git` user.
- Use the `unknown_git` user as the commit author, if the GitLab user doesn't exist in
  Perforce Helix.

## Related topics

- [Troubleshooting](troubleshooting.md) for repository mirroring.
- [Configure server hooks](../../../../administration/server_hooks.md)
