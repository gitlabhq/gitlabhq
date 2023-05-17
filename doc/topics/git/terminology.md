---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Git concepts

The following are commonly-used Git concepts.

## Repository

In GitLab, files are stored in a **repository**. A repository is similar to how you
store files in a folder or directory on your computer.

- A **remote repository** refers to the files in GitLab.
- A **local copy** refers to the files on your computer.

<!-- vale gitlab.Spelling = NO -->
<!-- vale gitlab.SubstitutionWarning = NO -->
Often, the word "repository" is shortened to "repo".
<!-- vale gitlab.Spelling = YES -->
<!-- vale gitlab.SubstitutionWarning = YES -->

In GitLab, a repository is contained in a **project**.

## Fork

When you want to contribute to someone else's repository, you make a copy of it.
This copy is called a [**fork**](../../user/project/repository/forking_workflow.md#create-a-fork).
The process is called "creating a fork."

When you fork a repository, you create a copy of the project in your own
[namespace](../../user/namespace/index.md). You then have write permissions to modify the project files
and settings.

For example, you can fork this project, <https://gitlab.com/gitlab-tests/sample-project/>, into your namespace.
You now have your own copy of the repository. You can view the namespace in the URL, for example
`https://gitlab.com/your-namespace/sample-project/`.
Then you can clone the repository to your local machine, work on the files, and submit changes back to the
original repository.

## Difference between download and clone

To create a copy of a remote repository's files on your computer, you can either
**download** or **clone** the repository. If you download it, you cannot sync the repository with the
remote repository on GitLab.

[Cloning](../../gitlab-basics/start-using-git.md#clone-a-repository) a repository is the same as downloading, except it preserves the Git connection
with the remote repository. You can then modify the files locally and
upload the changes to the remote repository on GitLab.

## Pull and push

After you save a local copy of a repository and modify the files on your computer, you can upload the
changes to GitLab. This action is known as **pushing** to the remote, because you use the command
[`git push`](../../gitlab-basics/start-using-git.md#send-changes-to-gitlabcom).

When the remote repository changes, your local copy is behind. You can update your local copy with the new
changes in the remote repository.
This action is known as **pulling** from the remote, because you use the command
[`git pull`](../../gitlab-basics/start-using-git.md#download-the-latest-changes-in-the-project).
