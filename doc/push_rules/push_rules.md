---
type: reference, howto
---

# Push Rules **(STARTER)**

Gain additional control over what can and can't be pushed to your repository by using
regular expressions to reject pushes based on commit contents, branch names or file details.

## Overview

GitLab already offers [protected branches][protected-branches], but there are
cases when you need some specific rules like preventing Git tag removal or
enforcing a special format for commit messages.

Push rules are essentially [pre-receive Git hooks][hooks] that are easy to
enable in a user-friendly interface. They are defined globally if you are an
admin or per project so you can have different rules applied to different
projects depending on your needs.

## Use cases

Every push rule could have its own use case, but let's consider some examples.

### Commit messages with a specific reference

Let's assume you have the following requirements for your workflow:

- every commit should reference a Jira issue, for example: `Refactored css. Fixes JIRA-123.`
- users should not be able to remove Git tags with `git push`

All you need to do is write a simple regular expression that requires the mention
of a Jira issue in the commit message, like `JIRA\-\d+`.

Now when a user tries to push a commit with a message `Bugfix`, their push will
be declined. Only pushing commits with messages like `Bugfix according to JIRA-123`
will be accepted.

### Restrict branch names

Let's assume there's a strict policy for branch names in your company, and
you want the branches to start with a certain name because you have different
GitLab CI jobs (`feature`, `hotfix`, `docker`, `android`, etc.) that rely on the
branch name.

Your developers however, don't always remember that policy, so they push
various branches and CI pipelines do not work as expected. By restricting the
branch names globally in Push Rules, you can now sleep without the anxiety
of your developers' mistakes. Every branch that doesn't match your push rule
will get rejected.

### Custom Push Rules **(CORE ONLY)**

It's possible to create custom push rules rather than the push rules available in
**Admin Area > Push Rules** by using more advanced server-side Git hooks.

See [custom server-side Git hooks](../administration/custom_hooks.md) for more information.

## Enabling push rules

NOTE: **Note:**
GitLab administrators can set push rules globally under
**Admin Area > Push Rules** that all new projects will inherit. You can later
override them in a project's settings.

1. Navigate to your project's **Settings > Repository** and expand **Push Rules**
1. Set the rule you want
1. Click **Save Push Rules** for the changes to take effect

The following options are available.

| Push rule | GitLab version | Description |
| --------- | :------------: | ----------- |
| Removal of tags with `git push` | **Starter** 7.10 | Forbid users to remove Git tags with `git push`. Tags will still be able to be deleted through the web UI. |
| Check whether author is a GitLab user | **Starter** 7.10 | Restrict commits by author (email) to existing GitLab users. |
| Committer restriction | **Premium** 10.2 | GitLab will reject any commit that was not committed by the current authenticated user |
| Check whether commit is signed through GPG | **Premium** 10.1 | Reject commit when it is not signed through GPG. Read [signing commits with GPG][signing-commits]. |
| Prevent committing secrets to Git | **Starter** 8.12 | GitLab will reject any files that are likely to contain secrets. Read [what files are forbidden](#prevent-pushing-secrets-to-the-repository). |
| Restrict by commit message | **Starter** 7.10 | Only commit messages that match this regular expression are allowed to be pushed. Leave empty to allow any commit message. Uses multiline mode, which can be disabled using `(?-m)`. |
| Restrict by commit message (negative match)| **Starter** 11.1 | Only commit messages that do not match this regular expression are allowed to be pushed. Leave empty to allow any commit message. Uses multiline mode, which can be disabled using `(?-m)`. |
| Restrict by branch name | **Starter** 9.3 | Only branch names that match this regular expression are allowed to be pushed. Leave empty to allow any branch name. |
| Restrict by commit author's email | **Starter** 7.10 | Only commit author's email that match this regular expression are allowed to be pushed. Leave empty to allow any email. |
| Prohibited file names | **Starter** 7.10 | Any committed filenames that match this regular expression are not allowed to be pushed. Leave empty to allow any filenames. |
| Maximum file size | **Starter** 7.12 | Pushes that contain added or updated files that exceed this file size (in MB) are rejected. Set to 0 to allow files of any size. Files tracked by Git LFS are exempted. |

TIP: **Tip:**
GitLab uses [RE2 syntax](https://github.com/google/re2/wiki/Syntax) for regular expressions in push rules, and you can test them at the [GoLang regex tester](https://regex-golang.appspot.com/assets/html/index.html).

## Prevent pushing secrets to the repository

> [Introduced][ee-385] in [GitLab Starter][ee] 8.12.

You can turn on a predefined blacklist of files which won't be allowed to be
pushed to a repository.

By selecting the checkbox *Prevent committing secrets to Git*, GitLab prevents
pushes to the repository when a file matches a regular expression as read from
[`files_blacklist.yml`][list] (make sure you are at the right branch
as your GitLab version when viewing this file).

NOTE: **Note:**
Files already committed won't get restricted by this push rule.

Below is an example list of what will be rejected by these regular expressions:

```shell
#####################
# AWS CLI credential blobs
#####################
.aws/credentials
aws/credentials
homefolder/aws/credentials

#####################
# Private RSA SSH keys
#####################
/ssh/id_rsa
/.ssh/personal_rsa
/config/server_rsa
id_rsa
.id_rsa

#####################
# Private DSA SSH keys
#####################
/ssh/id_dsa
/.ssh/personal_dsa
/config/server_dsa
id_dsa
.id_dsa

#####################
# Private ed25519 SSH keys
#####################
/ssh/id_ed25519
/.ssh/personal_ed25519
/config/server_ed25519
id_ed25519
.id_ed25519

#####################
# Private ECDSA SSH keys
#####################
/ssh/id_ecdsa
/.ssh/personal_ecdsa
/config/server_ecdsa
id_ecdsa
.id_ecdsa

#####################
# Any file with .pem or .key extensions
#####################
*.pem
*.key

#####################
# Any file ending with _history or .history extension
#####################
pry.history
bash_history
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

[protected-branches]: ../user/project/protected_branches.md
[signing-commits]: ../user/project/repository/gpg_signed_commits/index.md
[ee-385]: https://gitlab.com/gitlab-org/gitlab/issues/385
[list]: https://gitlab.com/gitlab-org/gitlab/blob/master/ee/lib/gitlab/checks/files_blacklist.yml
[hooks]: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks
[ee]: https://about.gitlab.com/pricing/
