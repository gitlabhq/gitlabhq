---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: 'Tutorial: Update Git remote URLs'
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Update your Git remote URLs if:

- You imported an existing project from another Git repository host.
- Your organization has moved your projects to a new GitLab instance with a new domain name.
- The project was renamed to a new path in the same GitLab instance.

NOTE:
If you don't have an existing local working copy from the old remote, then you don't need this tutorial.
You can instead clone the project from the new GitLab URL.

This tutorial explains how to update the remote URL for your local repository without:

- Losing any of your local changes that are incomplete.
- Losing changes that are not yet published to GitLab.
- Creating a new cloned working copy of the repository from the new URL.

This tutorial uses the `git-remote` command to
[manage remote and tracked repositories](https://git-scm.com/docs/git-remote).

To update Git remote URLs:

- [Determine existing and new URLs](#determine-existing-and-new-urls)
- [Update Git remote URLs](#update-git-remote-urls)
- [(Optional) Keep original remote URLs](#optional-keep-original-remote-urls)

## Before you begin

You must have:

- A GitLab project with a Git repository and a new GitLab URL.
- A cloned local working copy of the project that you are migrating to the new GitLab URL.
- Git [installed on your local machine](../../topics/git/how_to_install_git/_index.md).
- Access to your local machine's command-line interface (CLI). In macOS,
  you can use Terminal. In Windows, you can use PowerShell. Linux users are probably
  already familiar with their system's CLI.
- Authentication credentials for GitLab:
  - You must authenticate with GitLab to update Git remote URLs. If your GitLab account uses
  basic username and password authentication, you must have [two factor authentication (2FA)](../../user/profile/account/two_factor_authentication.md)
  disabled to authenticate from the CLI. Alternatively, you can [use an SSH key to authenticate with GitLab](../../user/ssh.md).

## Determine existing and new URLs

To update the Git remote URL, determine the existing and new URLs for your repository:

1. Open a terminal or command prompt.

1. Go to your local repository working copy. To change directory, use `cd`:

   ```shell
   cd <repository-name>
   ```

1. Each repository has a default remote named `origin`. To view the current remote _fetch_ and _push_ URLs
for your remote repository, run:

   ```shell
   git remote -v
   ```

1. Copy and keep note of the returned URLs. They are usually identical.

1. Get the new URL:
   1. Go to GitLab.
   1. On the left sidebar, select **Search or go to** and find your project.
   1. On the left sidebar, select **Code** > **Repository**, to go to the project's **Repository** page
   1. In the upper-right corner, select **Code**
   1. Depending on which method you use for authentication and cloning with `git`,
   copy either the HTTPS or SSH URL. If you're not sure, use the same method as the `origin` URL from the previous step.
   1. Keep note of the copied URL.

## Update Git remote URLs

To update the Git remote URL:

1. Open a terminal or command prompt.

1. Go to your local repository working copy. To change directory, use `cd`:

   ```shell
   cd <repository-name>
   ```

1. Update the remote URL, replacing `<new_url>` with the new repository URL you copied:

   ```shell
   git remote set-url origin <new_url>
   ```

1. Verify that the remote URL update is successful.
The following command displays the new URL for both fetch and push operations,
lists the local branches, and confirms that they are tracked to GitLab:

   ```shell
   git remote show origin
   ```

   - If the update was unsuccessful, go back to the previous step, ensure you
   have the correct `<new_url>`, and try again.

To update the remote URLs for multiple repositories:

1. Use the `git remote set-url` command. Replace `origin` with the name of the
remote you want to update. For example:

   ```shell
   git remote set-url <remote_name> <new_url>
   ```

1. Verify each remote URL update:

   ```shell
   git remote show <remote_name>
   ```

After updating the remote URL, you can continue to use Git commands as usual.
Your next `git fetch`, `git pull`, or `git push` uses the new URL from GitLab.

Congratulations, you have successfully updated the remote URL for your repository.

## (Optional) Keep original remote URLs

Your project might have more than one remote location.
For example, you have a forked repository from a project hosted on GitHub,
but you want to work on your fork in GitLab before you make a pull request to GitHub.

To keep the original remote URL in addition to updating it, and maintain both new and old
remote URLs, you can add a new remote instead of modifying the existing one.

With this approach, you can gradually transition to the new URL while still maintaining
access to the original repository.

To add a new remote URL:

1. Open a terminal or command prompt.

1. Go to your local repository working copy.

1. Add a new remote URL. Replace `<new_remote_name>` with a name for the new remote,
for example, `new-origin`, and `<new_url>` with the new repository URL:

   ```shell
   git remote add <new_remote_name> <new_url>
   ```

1. Verify that the new remote was added:

   ```shell
   git remote -v
   ```

Now you can use both the original and new remotes. For example:

- To push to the original remote: `git push origin main`
- To push to the new remote: `git push <new_remote_name> main`
