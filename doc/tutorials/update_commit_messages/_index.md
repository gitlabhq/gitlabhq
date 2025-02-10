---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: 'Tutorial: Update Git commit messages'
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Occasionally, after you've made a few commits to your branch, you realize you need
to update one or more commit messages. Perhaps you found a typo, or some automation warned you
that your commit message didn't completely align with a project's
[commit message guidelines](../../development/contributing/merge_request_workflow.md#commit-messages-guidelines).

Updating the message can be tricky if you don't have much practice using Git
from the command-line interface (CLI). But don't worry, even if you have only ever worked in
the GitLab UI, you can follow these steps to use the CLI.

This tutorial explains how to rewrite commit messages in both cases:

- If you work in the GitLab UI only, start at step 1.
- If you already have your repository cloned locally, you can skip to step 2.

To rewrite any number of commit messages:

1. [Clone your project's repository to your local machine](#clone-your-repository-to-your-local-machine).
1. [Fetch and check out your branch locally](#fetch-and-check-out-your-branch).
1. [Update the commit messages](#update-the-commit-messages).
1. [Push the changes up to GitLab](#push-the-changes-up-to-gitlab).

## Before you begin

You must have:

- A GitLab project with a Git branch containing commits that you want to update.
- Git [installed on your local machine](../../topics/git/how_to_install_git/_index.md).
- Access to your local machine's command-line interface (CLI). In macOS,
  you can use Terminal. In Windows, you can use PowerShell. Linux users are probably
  already familiar with their system's CLI.
- Familiarity with your system's default editor. This tutorial assumes your editor is Vim,
  but any text editor should work. If you are unfamiliar with Vim, step 1 to 2 of
  [Getting started with Vim](https://opensource.com/article/19/3/getting-started-vim)
  explains all the commands used later in this tutorial.
- Permission to overwrite the commit messages. If you are working with multiple people in the same branch,
  you should first verify with them that it's OK to update the commits. Some organizations might
  have rules against rewriting commits, as it is considered a destructive change.

You must authenticate with GitLab to overwrite the commit messages in the final step.
If your GitLab account uses basic username and password authentication, you must have
[two factor authentication (2FA)](../../user/profile/account/two_factor_authentication.md)
disabled to authenticate from the CLI. Alternatively, you can [use an SSH key to authenticate with GitLab](../../user/ssh.md).

## Clone your repository to your local machine

The first step is to get a clone of the repository on your local machine:

1. In GitLab, on your project's overview page, in the upper-right corner, select **Code**.
1. In the dropdown list, copy the URL for your repository by selecting **{copy-to-clipboard}** next to:
   - **Clone with HTTPS** if your GitLab account uses basic username and password authentication.
   - **Clone with SSH** if you use SSH to authenticate with GitLab.
1. Now switch to the CLI (Terminal, PowerShell, or similar) on your local machine, and go to
   the directory where you want to clone the repository. For example, `/users/my-username/my-projects/`.
1. Run `git clone` and paste the URL you copied earlier, for example:

   ```shell
   git clone https://gitlab.com/my-username/my-awesome-project.git
   ```

   This clones the repository into a new directory called `my-awesome-project/`.

Now your repository is on your computer, ready for your Git CLI commands!

## Fetch and check out your branch

Next, you need to check out the branch that contains the commits to update.

1. Assuming you are still at the same place in the CLI as the previous step,
   change to your project directory with `cd`:

   ```shell
   cd my-awesome-project
   ```

1. Optional. If you've just cloned the repository, your branch should already be
   on your computer too. But if you've previously cloned the repository and skipped
   to this step, you might need to fetch your branch with:

   ```shell
   git fetch origin my-branch-name
   ```

1. Now that you know for sure that the branch is on your local system, switch to it:

   ```shell
   git checkout my-branch-name
   ```

1. Verify that it's the correct branch with `git log` and check that the most recent commits
   match the commits in your branch on GitLab. To exit the log, use `q`.

## Update the commit messages

Now you are ready to update the commit messages:

1. In GitLab, check how far back in the commit history you need to go:

   - If you already have a merge request open for your branch, you can check the
     **Commits** tab and use the total number of commits.
   - If you are working from a branch only:
     1. Go to **Code > Commits**.
     1. Select the dropdown list in the top left and find your branch.
     1. Find the oldest commit you want to update, and count how far back that commit is.
        For example, if you want to update the second and fourth commit, the count would be 4.

1. From the CLI, start an interactive rebase, which is the Git process to update commits.
   Add the count of commits from the previous step to the end of `HEAD~`, for example:

   ```shell
   git rebase -i HEAD~4
   ```

   In this example, Git selects the four most recent commits in the branch to update.

1. Git launches a text editor and lists the selected commits.
   For example, it should look similar to:

   ```shell
   pick a0cea50 Fix broken link
   pick bb84712 Update milestone-plan.md
   pick ce11fad Add list of maintainers
   pick d211d03 update template.md

   # Rebase 1f5ec88..d211d03 onto 1f5ec88 (4 commands)
   #
   # Commands:
   # p, pick <commit> = use commit
   # r, reword <commit> = use commit, but edit the commit message
   # e, edit <commit> = use commit, but stop for amending
   # s, squash <commit> = use commit, but meld into previous commit
   # f, fixup [-C | -c] <commit> = like "squash" but keep only the previous
   #                    commit's log message, unless -C is used, in which case
   # [and so on...]
   ```

1. The `pick` command tells Git to use the commits without change. You must change
   the command from `pick` to `reword` for the commits you want to update.
   Type `i` to enter `INSERT` mode, and then start editing the text.

   For example, to update the text of the second and fourth commits in the sample above,
   edit it to look like:

   ```shell
   pick a0cea50 Fix broken link
   reword bb84712 Update milestone-plan.md
   pick ce11fad Add list of maintainers
   reword d211d03 update template.md
   ```

1. Save the edited text. Press <kbd>Escape</kbd> to exit `INSERT` mode,
   then type `:wq` and <kbd>Enter</kbd> to save and exit.

1. Git now goes through each commit one at a time and applies the commands you selected.
   Any commits with `pick` are added back to the branch unchanged. When Git reaches a commit
   with `reword`, it stops and again opens up the text editor. Now it's time to finally update
   the text of the commit message!

   - If you only need a one line commit message, update the text as needed. For example:

     ```plaintext
     Update the monthly milestone plan
     ```

   - If the commit message needs a title and a body, separate these with a blank line. For example:

     ```plaintext
     Update the monthly milestone plan

     Make the milestone plan clearer by listing the responsibilities
     of each maintainer.
     ```

   After you save and exit, Git updates the commit message, and processes the next
   commits in order. You should see the message `Successfully rebased and update refs/heads/my-branch-name`
   when finished.

1. Optional. To verify that the commit messages were updated, you can run `git log`
   and scroll down to see the commit messages.

## Push the changes up to GitLab

Now all that's left is to push these changes up to GitLab:

1. From the CLI, push the changes back to GitLab. You must use the `-f` "force push" option,
   because the commits were updated and a force push overwrites the old commits in GitLab.

   ```shell
   git push -f origin
   ```

   Your terminal might prompt you for your username and password before overwriting
   the commit messages in GitLab.

1. In your project in GitLab, verify that the commits have been updated:

   - If you already have a merge request open for your branch, check the **Commits** tab.
   - If you are working from a branch only:
     1. Go to **Code > Commits**.
     1. Select the dropdown list in the top left and find your branch.
     1. Verify that the relevant commits in the list are now updated.

Congratulations, you have successfully updated your commit messages and pushed them to GitLab!
