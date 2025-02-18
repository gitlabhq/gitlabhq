---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Remove a secret from your commits'
---

If your application uses external resources, you usually need to authenticate your
application with a **secret**, like a token or key. If a secret is pushed to a
remote repository, anyone with access to the repository can impersonate you or your
application. If you accidentally commit a secret, you can still remove it before you push.

In this tutorial, you'll commit a fake secret, then remove the secret from your
commit history before you push it to a project. You'll also learn what to do when
a secret is pushed to a repository.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
This tutorial is adapted from the GitLab Unfiltered video [Remove a secret from your commits](https://www.youtube.com/watch?v=2jBC3uBUlyU).
<!-- Video published on 2024-06-12 -->

## Before you begin

Make sure you have the following before you complete this tutorial:

- A test project. You can use any project you like, but consider creating a test project specifically for this tutorial.
- Some familiarity with command-line Git.

## Commit a secret

GitLab identifies secrets by matching specific patterns of letters, digits, and symbols. These patterns
are also used to identify the type of secret. For example, the fake secret `glpat-12345678901234567890` <!-- gitleaks:allow -->
is a personal access token because it begins with the string `glpat-`.

Although many secrets can be identified by format, you might accidentally commit a secret while you're working in a repository.
Let's simulate accidentally committing a secret:

1. In your test repository, check out a new branch:

   ```shell
   git checkout -b secret-tutorial
   ```

1. Create a new text file with the following content, removing the spaces before and after
   the `-` to match the exact format of a personal access token:

   ```txt
   fake-secret: glpat - 12345678901234567890
   message: hello, world!
   ```

1. Commit the file to your branch:

   ```shell
   git add .
   git commit -m "Add fake secret"
   ```

We've created a problematic situation: if we push our changes, the personal access token we committed to our text file
will be leaked! We need to remove the secret from the commit history before we can proceed.

## Remove the secret from the history

If the only commit that contains a secret is the most recent commit in the Git history,
you can amend the history to remove it:

1. Open the text file and remove the fake secret:

   ```txt
   fake-secret:
   message: hello, world!
   ```

1. Overwrite the old commit with the changes:

   ```shell
   git add .
   git commit --amend
   ```

The secret is removed from the file and the commit history, and you can safely push your changes.

### Amending multiple commits

Sometimes, you only notice that a secret was added after you make several additional commits.
When this happens, it's not enough to delete the secret from the most recent commit. You need to make changes
to every commit after the secret was added:

1. Add the fake secret to your file and commit it to the branch.
1. Make at least one additional commit. When you inspect the history, you should see something like this:

   ```shell
   $ git log
   commit 456def

       Do other things

   commit 123abc

       Add fake secret

   ...
   ```

   Even if we remove the secret from commit `456def`, it still exists in the history and will be exposed if we push our changes now.

1. To fix the history, start an interactive rebase from the commit that introduced the secret:

   ```shell
   git rebase -i 123abc~1
   ```

1. In the edit window, for every commit that includes the secret, change `pick` to `edit`:

   ```txt
   edit 456def Do other things
   edit 123abc Add fake secret
   ```

1. Open your text file and remove the fake secret.
1. Commit your changes:

   ```shell
   git add .
   git commit --amend
   ```

1. Optional. When you delete the secret, you might remove the only diff in the commit. If this happens, Git displays this message:

   ```shell
   No changes
   You asked to amend the most recent commit, but doing so would make it empty.
   ```

   Remove the empty commit:

   ```shell
   git reset HEAD^
   ```

1. Continue the rebase:

   ```shell
   git rebase --continue
   ```

1. Remove the secret from the next commit and continue the rebase. Repeat this process until the rebase is complete:

   ```shell
   Successfully rebased and updated refs/heads/secret-tutorial
   ```

The secret is removed and you can safely push your changes to the remote.

## What to do when you push a secret

Sometimes, people push changes before they notice the changes include a secret. If secret push protection is enabled in the project,
the push is blocked automatically and the offending commits are displayed.

However, if a secret is successfully pushed to a remote repository, it is no longer secure and you should revoke it immediately.
Even if you don't think many people have access to the secret, you should replace it. Exposed secrets are a substantial security risk.

## Next steps

To improve your application security, consider enabling at least one of the [secret detection](_index.md) methods in your project.
