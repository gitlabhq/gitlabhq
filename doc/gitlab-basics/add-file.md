---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Add, commit, and push a file to your Git repository using the command line."
---

# Add files to your branch

You can use Git to add files, make changes to existing files, and stash changes you don't need yet.

## Add files to a Git repository

To add a new file from the command line:

1. Open a terminal.
1. Change directories until you are in your project's folder.

   ```shell
   cd my-project
   ```

1. Choose a Git branch to work in.
   - To create a branch: `git checkout -b <branchname>`
   - To switch to an existing branch: `git checkout <branchname>`

1. Copy the file you want to add into the directory where you want to add it.
1. Confirm that your file is in the directory:
   - Windows: `dir`
   - All other operating systems: `ls`

   The filename should be displayed.
1. Check the status of the file:

   ```shell
   git status
   ```

   The filename should be in red. The file is in your file system, but Git isn't tracking it yet.
1. Tell Git to track the file:

   ```shell
   git add <filename>
   ```

1. Check the status of the file again:

   ```shell
   git status
   ```

   The filename should be green. The file is tracked locally by Git, but
   has not been committed and pushed.
1. Commit the file to your local copy of the project's Git repository:

   ```shell
   git commit -m "Describe the reason for your commit here"
   ```

1. Push your changes from your copy of the repository to GitLab.
   In this command, `origin` refers to the remote copy of the repository.
   Replace `<branchname>` with the name of your branch:

   ```shell
   git push origin <branchname>
   ```

1. Git prepares, compresses, and sends the data. Lines from the remote repository
   start with `remote:`:

   ```plaintext
   Enumerating objects: 9, done.
   Counting objects: 100% (9/9), done.
   Delta compression using up to 10 threads
   Compressing objects: 100% (5/5), done.
   Writing objects: 100% (5/5), 1.84 KiB | 1.84 MiB/s, done.
   Total 5 (delta 3), reused 0 (delta 0), pack-reused 0
   remote:
   remote: To create a merge request for <branchname>, visit:
   remote:   https://gitlab.com/gitlab-org/gitlab/-/merge_requests/new?merge_request%5Bsource_branch%5D=<branchname>
   remote:
   To https://gitlab.com/gitlab-org/gitlab.git
    * [new branch]                <branchname> -> <branchname>
   branch '<branchname>' set up to track 'origin/<branchname>'.
   ```

Your file is copied from your local copy of the repository to the remote
repository.

To create a merge request, copy the link sent back from the remote
repository and paste it into a browser window.

### Add a file to the last commit

```shell
git add <filename>
git commit --amend
```

Append `--no-edit` to the `commit` command if you do not want to edit the commit
message.

## Make changes to existing files

When you make changes to files in a repository, Git tracks the changes
against the most recent version of the checked out branch. You can use
Git commands to review and commit your changes to the branch, and push
your work to GitLab.

### Add and commit local changes

When you're ready to write your changes to the branch, you can commit
them. A commit includes a comment that records information about the
changes, and usually becomes the new tip of the branch.

Git doesn't automatically include any files you move, change, or
delete in a commit. This prevents you from accidentally including a
change or file, like a temporary directory. To include changes in a
commit, stage them with `git add`.

To stage and commit your changes:

1. From your repository, for each file or directory you want to add, run `git add <file name or path>`.

   To stage all files in the current working directory, run `git add .`.

1. Confirm that the files have been added to staging:

   ```shell
   git status
   ```

   The files are displayed in green.

1. To commit the staged files:

   ```shell
   git commit -m "<comment that describes the changes>"
   ```

The changes are committed to the branch.

### Commit all changes

You can stage all your changes and commit them with one command:

```shell
git commit -a -m "<comment that describes the changes>"
```

Be careful your commit doesn't include files you don't want to record
to the remote repository. As a rule, always check the status of your
local repository before you commit changes.

### Send changes to GitLab

To push all local changes to the remote repository:

```shell
git push <remote> <name-of-branch>
```

For example, to push your local commits to the `main` branch of the `origin` remote:

```shell
git push origin main
```

Sometimes Git does not allow you to push to a repository. Instead,
you must [force an update](../topics/git/git_rebase.md#force-pushing).

## Push options

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

When you push changes to a branch, you can use client-side
[Git push options](https://git-scm.com/docs/git-push#Documentation/git-push.txt--oltoptiongt).
In Git 2.10 and later, use Git push options to:

- [Skip CI jobs](#push-options-for-gitlab-cicd)
- [Push to merge requests](#push-options-for-merge-requests)

In Git 2.18 and later, you can use either the long format (`--push-option`) or the shorter `-o`:

```shell
git push -o <push_option>
```

In Git 2.10 to 2.17, you must use the long format:

```shell
git push --push-option=<push_option>
```

For server-side controls and enforcement of best practices, see
[push rules](../user/project/repository/push_rules.md) and [server hooks](../administration/server_hooks.md).

### Push options for GitLab CI/CD

You can use push options to skip a CI/CD pipeline, or pass CI/CD variables.

NOTE:
Push options are not available for merge request pipelines. For more information,
see [issue 373212](https://gitlab.com/gitlab-org/gitlab/-/issues/373212).

| Push option                    | Description | Example |
|--------------------------------|-------------|---------|
| `ci.skip`                      | Do not create a CI/CD pipeline for the latest push. Skips only branch pipelines and not [merge request pipelines](../ci/pipelines/merge_request_pipelines.md). This does not skip pipelines for CI/CD integrations, such as Jenkins. | `git push -o ci.skip` |
| `ci.variable="<name>=<value>"` | Provide [CI/CD variables](../ci/variables/index.md) to the CI/CD pipeline, if one is created due to the push. Passes variables only to branch pipelines and not [merge request pipelines](../ci/pipelines/merge_request_pipelines.md). | `git push -o ci.variable="MAX_RETRIES=10" -o ci.variable="MAX_TIME=600"` |
| `integrations.skip_ci`         | Skip push events for CI/CD integrations, such as Atlassian Bamboo, Buildkite, Drone, Jenkins, and JetBrains TeamCity. Introduced in [GitLab 16.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123837). | `git push -o integrations.skip_ci` |

### Push options for merge requests

Git push options can perform actions for merge requests while pushing changes:

| Push option                                  | Description |
|----------------------------------------------|-------------|
| `merge_request.create`                       | Create a new merge request for the pushed branch. |
| `merge_request.target=<branch_name>`         | Set the target of the merge request to a particular branch, such as: `git push -o merge_request.target=branch_name`. |
| `merge_request.target_project=<project>`     | Set the target of the merge request to a particular upstream project, such as: `git push -o merge_request.target_project=path/to/project`. Introduced in [GitLab 16.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132475). |
| `merge_request.merge_when_pipeline_succeeds` | Set the merge request to [merge when its pipeline succeeds](../user/project/merge_requests/merge_when_pipeline_succeeds.md). |
| `merge_request.remove_source_branch`         | Set the merge request to remove the source branch when it's merged. |
| `merge_request.squash`                       | Set the merge request to squash all commits into a single commit on merge. Introduced in [GitLab 17.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158778). |
| `merge_request.title="<title>"`              | Set the title of the merge request. For example: `git push -o merge_request.title="The title I want"`. |
| `merge_request.description="<description>"`  | Set the description of the merge request. For example: `git push -o merge_request.description="The description I want"`. |
| `merge_request.draft`                        | Mark the merge request as a draft. For example: `git push -o merge_request.draft`. Introduced in [GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/296673). |
| `merge_request.milestone="<milestone>"`      | Set the milestone of the merge request. For example: `git push -o merge_request.milestone="3.0"`. |
| `merge_request.label="<label>"`              | Add labels to the merge request. If the label does not exist, it is created. For example, for two labels: `git push -o merge_request.label="label1" -o merge_request.label="label2"`. |
| `merge_request.unlabel="<label>"`            | Remove labels from the merge request. For example, for two labels: `git push -o merge_request.unlabel="label1" -o merge_request.unlabel="label2"`. |
| `merge_request.assign="<user>"`              | Assign users to the merge request. Accepts username or user ID. For example, for two users: `git push -o merge_request.assign="user1" -o merge_request.assign="user2"`. Support for usernames added in [GitLab 15.5](https://gitlab.com/gitlab-org/gitlab/-/issues/344276). |
| `merge_request.unassign="<user>"`            | Remove assigned users from the merge request. Accepts username or user ID. For example, for two users: `git push -o merge_request.unassign="user1" -o merge_request.unassign="user2"`. Support for usernames added in [GitLab 15.5](https://gitlab.com/gitlab-org/gitlab/-/issues/344276). |

### Push options for secret push protection

You can use push options to skip [secret push protection](../user/application_security/secret_detection/secret_push_protection/index.md).

| Push option                    | Description | Example |
|--------------------------------|-------------|---------|
| `secret_push_protection.skip_all` | Do not perform secret push protection for any commit in this push. | `git push -o secret_push_protection.skip_all` |

### Push options for GitGuardian integration

You can use the same [push option for Secret push protection](#push-options-for-secret-push-protection) to skip GitGuardian secret detection.

| Push option                    | Description | Example |
|--------------------------------|-------------|---------|
| `secret_detection.skip_all` | Deprecated in GitLab 17.2. Use `secret_push_protection.skip_all` instead. | `git push -o secret_detection.skip_all` |
| `secret_push_protection.skip_all` | Do not perform GitGuardian secret detection. | `git push -o secret_push_protection.skip_all` |

### Formats for push options

If your push option requires text containing spaces, enclose the text in
double quotes (`"`). You can omit the quotes if there are no spaces. Some examples:

```shell
git push -o merge_request.label="Label with spaces"
git push -o merge_request.label=Label-with-no-spaces
```

To combine push options to accomplish multiple tasks at once, use
multiple `-o` (or `--push-option`) flags. This command creates a
new merge request, targets a branch (`my-target-branch`), and sets auto-merge:

```shell
git push -o merge_request.create -o merge_request.target=my-target-branch -o merge_request.merge_when_pipeline_succeeds
```

### Create Git aliases for pushing

Adding push options to Git commands can create very long commands. If
you use the same push options frequently, create Git aliases for them.
Git aliases are command-line shortcuts for longer Git commands.

To create and use a Git alias for the
[merge when pipeline succeeds Git push option](#push-options-for-merge-requests):

1. In your terminal window, run this command:

   ```shell
   git config --global alias.mwps "push -o merge_request.create -o merge_request.target=main -o merge_request.merge_when_pipeline_succeeds"
   ```

1. To use the alias to push a local branch that targets the default branch (`main`)
   and auto-merges, run this command:

   ```shell
   git mwps origin <local-branch-name>
   ```

## Related topics

- [Add file from the UI](../user/project/repository/index.md#add-a-file-from-the-ui)
- [Add file from the Web IDE](../user/project/repository/web_editor.md#upload-a-file)
- [Sign commits](../user/project/repository/signed_commits/gpg.md)
