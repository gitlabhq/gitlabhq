---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, howto
---

# Push Rules **(PREMIUM)**

Gain additional control over what can and can't be pushed to your repository by using
regular expressions to reject pushes based on commit contents, branch names or file details.

GitLab already offers [protected branches](../user/project/protected_branches.md), but there are
cases when you need some specific rules. Some common scenarios: preventing Git tag removal, or
enforcing a special format for commit messages.

Push rules are [pre-receive Git hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) you
can enable in a user-friendly interface. They are defined either:

- Globally if you are an administrator.
- Per project, so you can have different rules applied to different
  projects depending on your needs.

## Use cases

Every push rule could have its own use case, but let's consider some examples.

### Commit messages with a specific reference

Let's assume you have the following requirements for your workflow:

- every commit should reference a Jira issue, for example: `Refactored css. Fixes JIRA-123.`
- users should not be able to remove Git tags with `git push`

Write a regular expression that requires the mention
of a Jira issue in the commit message, like `JIRA\-\d+`.

Now when a user tries to push a commit with a message `Bugfix`, their push is
declined. Only pushing commits with messages like `Bugfix according to JIRA-123`
is accepted.

### Restrict branch names

If your company has a strict policy for branch names, you may want the branches to start
with a certain name. This approach enables different
GitLab CI/CD jobs (such as `feature`, `hotfix`, `docker`, `android`) that rely on the
branch name.

Your developers may not remember that policy, so they might push to
various branches, and CI pipelines might not work as expected. By restricting the
branch names globally in Push Rules, such mistakes are prevented.
Any branch name that doesn't match your push rule is rejected.

Note that the name of your default branch is always allowed, regardless of the branch naming
regular expression (regex) specified. GitLab is configured this way
because merges typically have the default branch as their target.
If you have other target branches, include them in your regex. (See [Enabling push rules](#enabling-push-rules)).

The default branch also defaults to being a [protected branch](../user/project/protected_branches.md),
which already limits users from pushing directly.

Some example regular expressions you can use in push rules:

- `^JIRA-` Branches must start with `JIRA-`.
- `-JIRA$` Branches must end with `-JIRA`.
- `^[a-z0-9\\-]{4,15}$` Branches must be between `4` and `15` characters long,
  accepting only lowercase letters, numbers and dashes.

#### Default restricted branch names

> Introduced in GitLab 12.10.

By default, GitLab restricts certain formats of branch names for security purposes.
40-character hexadecimal names, similar to Git commit hashes, are prohibited.

### Custom Push Rules **(FREE SELF)**

It's possible to create custom push rules rather than the push rules available in
**Admin Area > Push Rules** by using more advanced server hooks.

See [server hooks](../administration/server_hooks.md) for more information.

## Enabling push rules

You can create push rules for all new projects to inherit, but they can be overridden
at the project level or the [group level](../user/group/index.md#group-push-rules).

To create global push rules:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Push rules**.

To override global push rules in a project's settings:

1. Navigate to your project's **Settings > Repository** and expand **Push rules**.
1. Set the rule you want.
1. Select **Save Push Rules** for the changes to take effect.

The following options are available:

| Push rule                       | Description |
|---------------------------------|-------------|
| Removal of tags with `git push` | Forbid users to remove Git tags with `git push`. Tags can be deleted through the web UI. |
| Check whether the commit author is a GitLab user | Restrict commits to existing GitLab users (checked against their emails). |
| Reject unverified users **(PREMIUM)** | GitLab rejects any commit that was not committed by an authenticated user. |
| Check whether commit is signed through GPG **(PREMIUM)** | Reject commit when it is not signed through GPG. Read [signing commits with GPG](../user/project/repository/gpg_signed_commits/index.md). |
| Prevent pushing secret files | GitLab rejects any files that are likely to contain secrets. See the [forbidden file names](#prevent-pushing-secrets-to-the-repository). |
| Require expression in commit messages | Only commit messages that match this regular expression are allowed to be pushed. Leave empty to allow any commit message. Uses multiline mode, which can be disabled using `(?-m)`. |
| Reject expression in commit messages | Only commit messages that do not match this regular expression are allowed to be pushed. Leave empty to allow any commit message. Uses multiline mode, which can be disabled using `(?-m)`. |
| Restrict by branch name | Only branch names that match this regular expression are allowed to be pushed. Leave empty to allow any branch name. |
| Restrict by commit author's email | Only commit author's email that match this regular expression are allowed to be pushed. Leave empty to allow any email. |
| Prohibited file names | Any committed filenames that match this regular expression and do not already exist in the repository are not allowed to be pushed. Leave empty to allow any filenames. See [common examples](#prohibited-file-names). |
| Maximum file size | Pushes that contain added or updated files that exceed this file size (in MB) are rejected. Set to 0 to allow files of any size. Files tracked by Git LFS are exempted. |

NOTE:
GitLab uses [RE2 syntax](https://github.com/google/re2/wiki/Syntax) for regular expressions in push rules, and you can test them at the [regex101 regex tester](https://regex101.com/).

### Caveat to "Reject unsigned commits" push rule **(PREMIUM)**

This push rule ignores commits that are authenticated and created by GitLab
(either through the UI or API). When the **Reject unsigned commits** push rule is
enabled, unsigned commits may still show up in the commit history if a commit was
created **within** GitLab itself. As expected, commits created outside GitLab and
pushed to the repository are rejected. For more information about how GitLab
plans to fix this issue, read [issue #19185](https://gitlab.com/gitlab-org/gitlab/-/issues/19185).

#### "Reject unsigned commits" push rule disables Web IDE

In 13.10, if a project has the "Reject unsigned commits" push rule, the user will not be allowed to
commit through GitLab Web IDE.

To allow committing through the Web IDE on a project with this push rule, a GitLab administrator will
need to disable the feature flag `reject_unsigned_commits_by_gitlab`. This can be done through a
[rails console](../administration/operations/rails_console.md) and running:

```ruby
Feature.disable(:reject_unsigned_commits_by_gitlab)
```

## Prevent pushing secrets to the repository

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385) in GitLab 8.12.
> - Moved to GitLab Premium in 13.9.

Secrets such as credential files, SSH private keys, and other files containing secrets should never be committed to source control.
GitLab enables you to turn on a predefined denylist of files which can't be
pushed to a repository. The list stops those commits from reaching the remote repository.

By selecting the checkbox *Prevent committing secrets to Git*, GitLab prevents
pushes to the repository when a file matches a regular expression as read from
[`files_denylist.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml) (make sure you are at the right branch
as your GitLab version when viewing this file).

NOTE:
Files already committed aren't restricted by this push rule.

Below is an example list of what GitLab rejects with these regular expressions:

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
*.history
*_history
```

## Prohibited file names

> - Introduced in GitLab 7.10.
> - Moved to GitLab Premium in 13.9.

Each filename contained in a Git push is compared to the regular expression in this field. Filenames in Git consist of both the file's name and any directory that may precede it. A singular regular expression can contain multiple independent matches used as exclusions. File names can be broadly matched to any location in the repository, or restricted to specific locations. Filenames can also be partial matches used to exclude file types by extension.

The following examples make use of regex string boundary characters which match the beginning of a string (`^`), and the end (`$`). They also include instances where either the directory path or the filename can include `.` or `/`. Both of these special regex characters have to be escaped with a backslash `\\` to be used as normal characters in a match condition.

Example: prevent pushing any `.exe` files to any location in the repository. This is an example of a partial match, which can match any filename that contains `.exe` at the end:

```plaintext
\.exe$
```

Example: prevent a specific configuration file in the repository root from being pushed:

```plaintext
^config\.yml$
```

Example: prevent a specific configuration file in a known directory from being pushed:

```plaintext
^directory-name\/config\.yml$
```

Example: prevent the specific file named `install.exe` from being pushed to any
location in the repository. The parenthesized expression `(^|\/)` matches either
a file following a directory separator or a file in the root directory of the repository:

```plaintext
(^|\/)install\.exe$
```

Example: combining all of the above in a single expression. The preceding expressions rely
on the end-of-string character `$`. We can move that part of each expression to the
end of the grouped collection of match conditions where it is appended to all matches:

```plaintext
(\.exe|^config\.yml|^directory-name\/config\.yml|(^|\/)install\.exe)$
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
