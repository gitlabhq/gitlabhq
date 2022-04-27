---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
---

# Push rules **(PREMIUM)**

Push rules are [pre-receive Git hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) you
can enable in a user-friendly interface. Push rules give you more control over what
can and can't be pushed to your repository. While GitLab offers
[protected branches](../protected_branches.md), you may need more specific rules, such as:

- Evaluating the contents of a commit.
- Confirming commit messages match expected formats.
- Enforcing branch name rules.
- Evaluating the details of files.
- Preventing Git tag removal.

You can define push rules:

- [Globally](#enable-global-push-rules), if you are an administrator.
- [Per project](#override-global-push-rules-per-project), to create push rules that
  meet each project's needs.

These push rules are available by default:

- **Reject unverified users** - GitLab rejects any commit that was not committed
  by the same user as the user who pushed it, or if the committer's email address
  is [not confirmed](../../../security/user_email_confirmation.md).
- **Reject unsigned commits** - Reject commit when it is not signed through GPG.
  Read [signing commits with GPG](gpg_signed_commits/index.md). This push rule
  can block some legitimate commits [created in the Web IDE](#reject-unsigned-commits-push-rule-disables-web-ide),
  and allow [unsigned commits created in the GitLab UI](#unsigned-commits-created-in-the-gitlab-ui).
- **Do not allow users to remove Git tags with** `git push` - Forbid users to remove Git tags with `git push`.
  Tags can be deleted through the web UI.
- **Check whether the commit author is a GitLab user** - Restrict commits to existing
  GitLab users (checked against their email addresses). Checks both the commit author and committer.
- **Prevent pushing secret files** - GitLab rejects any files that are
  [likely to contain secrets](#prevent-pushing-secrets-to-the-repository).

These push rules are also available by default, but require you to create a
regular expression for the rule to evaluate:

- **Require expression in commit messages** - Only commit messages that match this
  regular expression can be pushed. To allow any commit message, leave empty.
  Uses multiline mode, which can be disabled using `(?-m)`.

  For example, if every commit should reference a Jira issue
  (like `Refactored css. Fixes JIRA-123.`) your regular expression would be
  `JIRA\-\d+`. Pushes with commit messages not matching this string are declined.
- **Reject expression in commit messages** - Only commit messages that do not match
  this regular expression can be pushed. To allow any commit message, leave empty.
  Uses multiline mode, which can be disabled using `(?-m)`.
- **Restrict by branch name** - Only branch names that match this regular expression
  can be pushed. To allow any branch name, leave empty. The name of your
  [default branch](branches/default.md) is always allowed, because many merges
  target this branch. Include any other target branches in your regex.

  Some examples:

  - You may want all branches to start with a certain name (such as
    `feature`, `hotfix`, `docker`, `android`) in support of GitLab CI/CD jobs that
    rely on the branch name.
  - `^JIRA-` Branches must start with `JIRA-`.
  - `-JIRA$` Branches must end with `-JIRA`.
  - `^[a-z0-9\\-]{4,15}$` Branches must be between `4` and `15` characters long,
    accepting only lowercase letters, numbers and dashes.

  NOTE:
  In GitLab 12.10 and later, certain formats of branch names are restricted by
  default for security purposes. 40-character hexadecimal names, similar to Git
  commit hashes, are prohibited.
- **Restrict by commit author's email** - Only the commit author's email address that matches this
  regular expression can be pushed. Checks both the commit author and committer.
  To allow any email address, leave empty.
- **Prohibited file names** - Any committed file names that match this regular expression
  and do not already exist in the repository can't be pushed. To allow all file names,
  leave empty. See [common examples](#prohibit-files-by-name).
- **Maximum file size** - Pushes that contain added or updated files that exceed this
  file size (in MB) are rejected. To allow files of any size, set to `0`.
  Files tracked by Git LFS are exempted.

GitLab uses [RE2 syntax](https://github.com/google/re2/wiki/Syntax) for regular expressions
in push rules, and you can test them at the [regex101 regex tester](https://regex101.com/).

## Enable global push rules

You can create push rules for all new projects to inherit, but they can be overridden
at the project level or the [group level](../../group/index.md#group-push-rules).

To create global push rules:

1. On the top bar, select **Menu > Admin**.
1. On the left sidebar, select **Push Rules**.
1. Expand **Push rules**.
1. Set the rule you want.
1. Select **Save push rules**.

## Override global push rules per project

The push rule of an individual project overrides the global push rule.
To override global push rules for a specific project:

1. On the top bar, select **Menu > Projects** and find your project.
1. On the left sidebar, select **Settings > Repository**.
1. Expand **Push rules**.
1. Set the rule you want.
1. Select **Save push rules**.

## Create custom push rules **(PREMIUM SELF)**

You can create custom, more complex push rules with [server hooks](../../../administration/server_hooks.md).

## Prevent pushing secrets to the repository

> Moved to GitLab Premium in 13.9.

Never commit secrets, such as credential files and SSH private keys, to a version control
system. In GitLab, you can use a predefined list of files to block those files from a
repository. Merge requests containing a file matching the list are blocked, and can't merge.
Files already committed to the repository are not restricted by this push rule.

Files blocked by this rule are listed below. For a complete list of criteria, refer to
[`files_denylist.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/gitlab/checks/files_denylist.yml).

- AWS CLI credential blobs:

  - `.aws/credentials`
  - `aws/credentials`
  - `homefolder/aws/credentials`

- Private RSA SSH keys:

  - `/ssh/id_rsa`
  - `/.ssh/personal_rsa`
  - `/config/server_rsa`
  - `id_rsa`
  - `.id_rsa`

- Private DSA SSH keys:

  - `/ssh/id_dsa`
  - `/.ssh/personal_dsa`
  - `/config/server_dsa`
  - `id_dsa`
  - `.id_dsa`

- Private ED25519 SSH keys:

  - `/ssh/id_ed25519`
  - `/.ssh/personal_ed25519`
  - `/config/server_ed25519`
  - `id_ed25519`
  - `.id_ed25519`

- Private ECDSA SSH keys:

  - `/ssh/id_ecdsa`
  - `/.ssh/personal_ecdsa`
  - `/config/server_ecdsa`
  - `id_ecdsa`
  - `.id_ecdsa`

- Private ECDSA_SK SSH keys (GitLab 14.8 and later):

  - `/ssh/id_ecdsa_sk`
  - `/.ssh/personal_ecdsa_sk`
  - `/config/server_ecdsa_sk`
  - `id_ecdsa_sk`
  - `.id_ecdsa_sk`

- Private ED25519_SK SSH keys (GitLab 14.8 and later):

  - `/ssh/id_ed25519_sk`
  - `/.ssh/personal_ed25519_sk`
  - `/config/server_ed25519_sk`
  - `id_ed25519_sk`
  - `.id_ed25519_sk`

- Any files ending with these suffixes:

  - `*.pem`
  - `*.key`
  - `*.history`
  - `*_history`

## Prohibit files by name

> Moved to GitLab Premium in 13.9.

In Git, filenames include both the file's name, and all directories preceding the name.
When you `git push`, each filename in the push is compared to the regular expression
in **Prohibited file names**.

The regular expression in your **Prohibited file names** push rule can contain multiple,
independent matches to exclude. You can match file names broadly to any location in
your repository, or restrict only in certain locations. Filename matches can also
be partial, and exclude file types by extension.

These examples use regex (regular expressions) string boundary characters to match
the beginning of a string (`^`), and its end (`$`). They also include instances
where either the directory path or the filename can include `.` or `/`. Both of
these special regex characters must be escaped with a backslash `\\` if you want
to use them as normal characters in a match condition.

- **Prevent pushing `.exe` files to any location in the repository** - This regex
  matches any filename that contains `.exe` at the end:

  ```plaintext
  \.exe$
  ```

- **Prevent pushing a specific configuration file in the repository root**

  ```plaintext
  ^config\.yml$
  ```

- **Prevent pushing a specific configuration file in a known directory**

  ```plaintext
  ^directory-name\/config\.yml$
  ```

- **Prevent pushing a specific file to any location in the repository** - This example tests
  for any file named `install.exe`. The parenthesized expression `(^|\/)` matches either
  a file following a directory separator, or a file in the root directory of the repository:

  ```plaintext
  (^|\/)install\.exe$
  ```

- **Combine all previous expressions into one expression** - The preceding expressions rely
  on the end-of-string character `$`. We can move that part of each expression to the
  end of the grouped collection of match conditions, where it is appended to all matches:

  ```plaintext
  (\.exe|^config\.yml|^directory-name\/config\.yml|(^|\/)install\.exe)$
  ```

## Related topics

- [Server hooks](../../../administration/server_hooks.md), to create complex custom push rules
- [Signing commits with GPG](gpg_signed_commits/index.md)
- [Protected branches](../protected_branches.md)

## Troubleshooting

### Reject unsigned commits push rule disables Web IDE

In GitLab 13.10, if a project has the **Reject unsigned commits** push rule, the user cannot
create commits through the GitLab Web IDE.

To allow committing through the Web IDE on a project with this push rule, a GitLab administrator
must disable the feature flag `reject_unsigned_commits_by_gitlab`. [with a flag](../../../administration/feature_flags.md)

```ruby
Feature.disable(:reject_unsigned_commits_by_gitlab)
```

### Unsigned commits created in the GitLab UI

The **Reject unsigned commits** push rule ignores commits that are authenticated
and created by GitLab (either through the UI or API). When this push rule is
enabled, unsigned commits may still appear in the commit history if a commit was
created in GitLab itself. As expected, commits created outside GitLab and
pushed to the repository are rejected. For more information about this issue,
read [issue #19185](https://gitlab.com/gitlab-org/gitlab/-/issues/19185).
