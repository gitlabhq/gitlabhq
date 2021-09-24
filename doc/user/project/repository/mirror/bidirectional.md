---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
disqus_identifier: 'https://docs.gitlab.com/ee/workflow/repository_mirroring.html'
---

# Bidirectional mirroring **(PREMIUM)**

> Moved to GitLab Premium in 13.9.

WARNING:
Bidirectional mirroring may cause conflicts.

If you configure a GitLab repository to both pull from, and push to, the same remote source, there
is no guarantee that either repository updates correctly. If you set up a repository for
bidirectional mirroring, you should prepare for the likely conflicts by deciding who resolves
them and how.

Rewriting any mirrored commit on either remote causes conflicts and mirroring to fail. This can
be prevented by [mirroring only protected branches](index.md#mirror-only-protected-branches).

You should [protect the branches](../../protected_branches.md) you wish to mirror on both
remotes to prevent conflicts caused by rewriting history.

Bidirectional mirroring also creates a race condition where commits made close together to the same
branch causes conflicts. The race condition can be mitigated by reducing the mirroring delay by using
a [Push event webhook](../../integrations/webhooks.md#push-events) to trigger an immediate
pull to GitLab. Push mirroring from GitLab is rate limited to once per minute when only push mirroring
protected branches.

## Configure a webhook to trigger an immediate pull to GitLab

Assuming you have already configured the [push](push.md#set-up-a-push-mirror-to-another-gitlab-instance-with-2fa-activated)
and [pull](pull.md#pull-from-a-remote-repository) mirrors in the upstream GitLab instance, to trigger an
immediate pull as suggested above, you must configure a [Push Event Web Hook](../../integrations/webhooks.md#push-events)
in the downstream instance.

To do this:

1. Create a [personal access token](../../../profile/personal_access_tokens.md) with `API` scope.
1. In your project, go to **Settings > Webhooks**.
1. Add the webhook URL which (in this case) uses the [Pull Mirror API](../../../../api/projects.md#start-the-pull-mirroring-process-for-a-project)
   request to trigger an immediate pull after updates to the repository.

   ```plaintext
   https://gitlab.example.com/api/v4/projects/:id/mirror/pull?private_token=<your_access_token>
   ```

1. Ensure the **Push Events** checkbox is selected.
1. Select **Add Webhook** to save the webhook.

To test the integration, select the **Test** button and confirm GitLab doesn't return an error message.

## Prevent conflicts using a pre-receive hook

WARNING:
The solution proposed negatively affects the performance of
Git push operations because they are proxied to the upstream Git
repository.

A server-side `pre-receive` hook can be used to prevent the race condition
described above by only accepting the push after first pushing the commit to
the upstream Git repository. In this configuration one Git repository acts as
the authoritative upstream, and the other as downstream. The `pre-receive` hook
is installed on the downstream repository.

Read about [configuring Server hooks](../../../../administration/server_hooks.md) on the GitLab server.

A sample `pre-receive` hook is provided below.

```shell
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
  allowlist=$(expr "$branch" : "\(master\)")

  case "$refname" in
    refs/heads/*)
      branch=$(expr "$refname" : "refs/heads/\(.*\)")

      if [ "$allowlist" = "$branch" ]; then
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
  - It doesn't regard different types of authentication mechanisms for the mirror.
  - It doesn't work with forced updates (rewriting history).
  - Only branches that match the `allowlist` patterns are proxy pushed.
- The script circumvents the Git hook quarantine environment because the update of `$TARGET_REPO`
  is seen as a ref update, and Git displays warnings about it.

## Mirror with Perforce Helix via Git Fusion **(PREMIUM)**

> Moved to GitLab Premium in 13.9.

WARNING:
Bidirectional mirroring should not be used as a permanent configuration. Refer to
[Migrating from Perforce Helix](../../import/perforce.md) for alternative migration approaches.

[Git Fusion](https://www.perforce.com/manuals/git-fusion/#Git-Fusion/section_avy_hyc_gl.html) provides a Git interface
to [Perforce Helix](https://www.perforce.com/products) which can be used by GitLab to bidirectionally
mirror projects with GitLab. This can help you in some situations when migrating from Perforce Helix
to GitLab where overlapping Perforce Helix workspaces cannot be migrated simultaneously to GitLab.

If using mirroring with Perforce Helix, you should only mirror protected branches. Perforce Helix
rejects any pushes that rewrite history. Only the fewest number of branches should be mirrored
due to the performance limitations of Git Fusion.

When configuring mirroring with Perforce Helix via Git Fusion, the following Git Fusion
settings are recommended:

- `change-pusher` should be disabled. Otherwise, every commit is rewritten as being committed
  by the mirroring account, rather than being mapped to existing Perforce Helix users or the `unknown_git` user.
- `unknown_git` user is used as the commit author if the GitLab user doesn't exist in
  Perforce Helix.

Read about [Git Fusion settings on Perforce.com](https://www.perforce.com/manuals/git-fusion/Content/Git-Fusion/section_vss_bdw_w3.html#section_zdp_zz1_3l).
