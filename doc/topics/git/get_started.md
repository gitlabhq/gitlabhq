---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Get started with Git

You can use Git from a command line to interact with GitLab.

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

**Get started:**

- [Clone a repository from GitLab to your local machine](../../gitlab-basics/start-using-git.md#clone-a-repository).

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

- [Send changes to GitLab](../../gitlab-basics/start-using-git.md#send-changes-to-gitlab).

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
