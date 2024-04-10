---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Get started with Git

If you're new to Git and want to learn by working in your own project,
[learn how to make your first commit](../../tutorials/make_first_git_commit/index.md).

For a quick reference of Git commands, download a [Git Cheat Sheet](https://about.gitlab.com/images/press/git-cheat-sheet.pdf).

Learn how [GitLab became the backbone of the Worldline](https://about.gitlab.com/customers/worldline/) development environment.

To help you visualize what you're doing locally, you can install a
[Git GUI app](https://git-scm.com/downloads/guis).

## Choose a repository

Before you begin, choose the repository you want to work in. You can use any project you have permission to
access on GitLab.com or any other GitLab instance.

To use the repository in the examples on this page:

1. Go to [https://gitlab.com/gitlab-tests/sample-project/](https://gitlab.com/gitlab-tests/sample-project/).
1. In the upper-right corner, select **Fork**.
1. Choose a namespace for your fork.

The project becomes available at `https://gitlab.com/<your-namespace>/sample-project/`.

You can [fork](../../user/project/repository/forking_workflow.md#create-a-fork) any project you have access to.

## Cloning Git repositories

When you clone a repository, the files from the remote repository are downloaded to your computer,
and a connection is created.

This connection requires you to add credentials. You can either use SSH or HTTPS. SSH is recommended.

### Clone with SSH

Clone with SSH when you want to authenticate only one time.

1. Authenticate with GitLab by following the instructions in the [SSH documentation](../../user/ssh.md).
1. On the left sidebar, select **Search or go to** and find the project you want to clone.
1. On the project's overview page, in the upper-right corner, select **Code**, then copy the URL for **Clone with SSH**.
1. Open a terminal and go to the directory where you want to clone the files.
   Git automatically creates a folder with the repository name and downloads the files there.
1. Run this command:

   ```shell
   git clone git@gitlab.com:gitlab-tests/sample-project.git
   ```

1. To view the files, go to the new directory:

   ```shell
   cd sample-project
   ```

You can also
[clone a repository and open it directly in Visual Studio Code](../../user/project/repository/index.md#clone-and-open-in-visual-studio-code).

### Clone with HTTPS

Clone with HTTPS when you want to authenticate each time you perform an operation between your computer and GitLab.
[OAuth credential helpers](../../user/profile/account/two_factor_authentication.md#oauth-credential-helpers) can decrease
the number of times you must manually authenticate, making HTTPS a seamless experience.

1. On the left sidebar, select **Search or go to** and find the project you want to clone.
1. On the project's overview page, in the upper-right corner, select **Code**, then copy the URL for **Clone with HTTPS**.
1. Open a terminal and go to the directory where you want to clone the files.
1. Run the following command. Git automatically creates a folder with the repository name and downloads the files there.

   ```shell
   git clone https://gitlab.com/gitlab-tests/sample-project.git
   ```

1. GitLab requests your username and password.

   If you have enabled two-factor authentication (2FA) on your account, you cannot use your account password. Instead, you can do one of the following:

   - [Clone using a token](#clone-using-a-token) with `read_repository` or `write_repository` permissions.
   - Install an [OAuth credential helper](../../user/profile/account/two_factor_authentication.md#oauth-credential-helpers).

   If you have not enabled 2FA, use your account password.

1. To view the files, go to the new directory:

   ```shell
   cd sample-project
   ```

NOTE:
On Windows, if you enter your password incorrectly multiple times and an `Access denied` message appears,
add your namespace (username or group) to the path:
`git clone https://namespace@gitlab.com/gitlab-org/gitlab.git`.

#### Clone using a token

Clone with HTTPS using a token if:

- You want to use 2FA.
- You want to have a revocable set of credentials scoped to one or more repositories.

You can use any of these tokens to authenticate when cloning over HTTPS:

- [Personal access tokens](../../user/profile/personal_access_tokens.md).
- [Deploy tokens](../../user/project/deploy_tokens/index.md).
- [Project access tokens](../../user/project/settings/project_access_tokens.md).
- [Group access tokens](../../user/group/settings/group_access_tokens.md).

```shell
git clone https://<username>:<token>@gitlab.example.com/tanuki/awesome_project.git
```

## Using Git branches

A **branch** is a copy of the files in the repository at the time you create the branch.
You can work in your branch without affecting other branches. When
you're ready to add your changes to the main codebase, you can merge your branch into
the default branch, for example, `main`.

Use branches when you:

- Want to add code to a project but you're not sure if it works properly.
- Are collaborating on the project with others, and don't want your work to get mixed up.

A new branch is often called **feature branch** to differentiate from the
[default branch](../../user/project/repository/branches/default.md).

### Create a branch

To create a feature branch:

```shell
git checkout -b <name-of-branch>
```

GitLab enforces [branch naming rules](../../user/project/repository/branches/index.md#name-your-branch)
to prevent problems, and provides
[branch naming patterns](../../user/project/repository/branches/index.md#prefix-branch-names-with-issue-numbers)
to streamline merge request creation.

### Switch to a branch

All work in Git is done in a branch.
You can switch between branches to see the state of the files and work in that branch.

To switch to an existing branch:

```shell
git checkout <name-of-branch>
```

For example, to change to the `main` branch:

```shell
git checkout main
```

## Common terms

If you're new to Git, start by reviewing some of the most commonly used terms.

### Repository

Files are stored in a **repository**. A repository is similar to how you
store files in a folder or directory on your computer.

- A **remote repository** refers to the files in GitLab.
- A **local copy** refers to the files on your computer.

The word **repository** is often shortened to **repo**.

In GitLab, a repository is part of a **project**.

**Get started:**

- [Learn more about repositories](../../user/project/repository/index.md).
- [Tutorial: Make your first Git commit](../../tutorials/make_first_git_commit/index.md).

### Clone

To create a copy of a remote repository's files on your computer, you **clone** it.
When you clone a repository, you can sync the repository with the remote repository in GitLab.
You can modify the files locally and upload the changes to the remote repository on GitLab.

### Pull

When the remote repository changes, your local copy is behind. You can update your local copy with the new
changes in the remote repository.
This action is known as **pulling** from the remote, because you use the command `git pull`.

**Get started**:

- [Download the latest changes in the project](../../gitlab-basics/start-using-git.md#download-the-latest-changes-in-the-project).

### Push

After you save a local copy of a repository and modify the files on your computer, you can upload the
changes to GitLab. This action is known as **pushing** to the remote, because you use the command
`git push`.

**Get started**:

- [Send changes to GitLab](../../gitlab-basics/add-file.md#send-changes-to-gitlab).

### Fork

When you want to contribute to someone else's repository, you make a copy of it.
This copy is called a **fork**.

When you create a fork of a repository, you create a copy of the project in your own
namespace in the remote repository.
You then have write permissions to modify the project files and settings.

For example, you can fork this project in to your namespace:

- <https://gitlab.com/gitlab-tests/sample-project/>

You now have your own copy of the repository. You can view the namespace in the URL, for example:

- `https://gitlab.com/your-namespace/sample-project/`

Then you can clone the repository to your local machine, work on the files, and submit changes back to the
original repository.

**Get started**

- [Learn more about forks](../../user/project/repository/forking_workflow.md).
- [Learn more about namespaces](../../user/namespace/index.md).
