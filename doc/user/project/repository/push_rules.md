---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Use push rules to control the content and format of Git commits your repository will accept. Set standards for commit messages, and block secrets or credentials from being added accidentally."
title: Push rules
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Maximum regular expression length for push rules [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/411901) from 255 to 511 characters in GitLab 16.3.

Push rules are [`pre-receive` Git hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks#:~:text=pre%2Dreceive,with%20the%20push.) you
can enable in a user-friendly interface. Push rules give you more control over what
can and can't be pushed to your repository. While GitLab offers
[protected branches](branches/protected.md), you may need more specific rules, such as:

- Evaluating the contents of a commit.
- Confirming commit messages match expected formats.
- Enforcing [branch name rules](branches/_index.md#name-your-branch).
- Evaluating the details of files.
- Preventing Git tag removal.

GitLab uses [RE2 syntax](https://github.com/google/re2/wiki/Syntax) for regular expressions
in push rules. You can test them at the [regex101 regex tester](https://regex101.com/).
Each regular expression is limited to 511 characters.

For custom push rules use [server hooks](../../../administration/server_hooks.md).

## Enable global push rules

You can create push rules for all new projects to inherit, but they can be overridden
in a project or [group](../../group/access_and_permissions.md#group-push-rules).
All projects created after you configure global push rules inherit this
configuration. However, each existing project must be updated manually, using the
process described in [Override global push rules per project](#override-global-push-rules-per-project).

Prerequisites:

- You must be an administrator.

To create global push rules:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Push rules**.
1. Expand **Push rules**.
1. Set the rule you want.
1. Select **Save push rules**.

## Override global push rules per project

The push rule of an individual project overrides the global push rule.
To override global push rules for a specific project, or to update the rules
for an existing project to match new global push rules:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Repository**.
1. Expand **Push rules**.
1. Set the rule you want.
1. Select **Save push rules**.

## Verify users

Use these rules to validate users who make commits.

NOTE:
These push rules apply only to commits and not [tags](tags/_index.md).

- **Reject unverified users**: Users must have a [confirmed email address](../../../security/user_email_confirmation.md).
- **Check whether the commit author is a GitLab user**: The commit author and committer must have an email address that's been verified by GitLab.
- **Commit author's email**: Both the author and committer email addresses must match the regular expression.
  To allow any email address, leave empty.

## Validate commit messages

Use these rules for your commit messages.

- **Require expression in commit messages**: Messages must match the
  expression. To allow any commit message, leave empty.
  Uses multiline mode, which can be disabled by using `(?-m)`. Some validation examples:

  - `JIRA\-\d+` requires every commit to reference a Jira issue, like `Refactored css. Fixes JIRA-123`.
  - `[[:^punct:]]\b$` rejects a commit if the final character is a punctuation mark.
    The word boundary character (`\b`) prevents false negatives, because Git adds a
    newline character (`\n`) to the end of the commit message.

  Commit messages created in GitLab UI set `\r\n` as a newline character.
  Use `(\r\n?|\n)` instead of `\n` in your regular expression to correctly match
  it.

  For example, given the following multi-line commit description:

  ```plaintext
  JIRA:
  Description
  ```

  You can validate it with this regular expression: `JIRA:(\r\n?|\n)\w+`.

- **Reject expression in commit messages**: Commit messages must not match
  the expression. To allow any commit message, leave empty.
  Uses multiline mode, which can be disabled by using `(?-m)`.

## Reject commits that aren't signed-off

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98810) in GitLab 15.5.

Commits signed with the [Developer Certificate of Origin](https://developercertificate.org/) (DCO)
certify the contributor wrote, or has the right to submit, the code contributed in that commit.
You can require all commits to your project to comply with the DCO. This push rule requires a
`Signed-off-by:` trailer in every commit message, and rejects any commits that lack it.

## Validate branch names

To validate your branch names, enter a regular expression for **Branch name**.
To allow any branch name, leave empty. Your [default branch](branches/default.md)
is always allowed. Certain formats of branch names are restricted by default for
security purposes. Names with 40 hexadecimal characters, similar to Git commit hashes,
are prohibited.

Some validation examples:

- Branches must start with `JIRA-`.

  ```plaintext
  ^JIRA-
  ```

- Branches must end with `-JIRA`.

  ```plaintext
  -JIRA$
  ```

- Branches must be between `4` and `15` characters long,
  accepting only lowercase letters, numbers and dashes.

  ```plaintext
  ^[a-z0-9\\-]{4,15}$
  ```

## Prevent unintended consequences

Use these rules to prevent unintended consequences.

- **Reject unsigned commits**: Commit [must be signed](signed_commits/_index.md). This rule
  can block some legitimate commits [created in the Web IDE](#reject-unsigned-commits-push-rule-disables-web-ide),
  and allow [unsigned commits created in the GitLab UI](#unsigned-commits-created-in-the-gitlab-ui).
- **Do not allow users to remove Git tags with `git push`**: Users cannot use `git push` to remove Git tags.
  Users can still delete tags in the UI.

## Validate files

Use these rules to validate files contained in the commit.

- **Prevent pushing secret files**: Files must not contain [secrets](#prevent-pushing-secrets-to-the-repository).
- **Prohibited filenames**: Files that do not exist in the repository
  must not match the regular expression. To allow all filenames, leave empty. See [common examples](#prohibit-files-by-name).
- **Maximum file size**: Added or updated files must not exceed this
  file size (in MB). To allow files of any size, set to `0`. Files tracked by Git LFS are exempted.

### Prevent pushing secrets to the repository

Never commit secrets, such as credential files and SSH private keys, to a version control
system. In GitLab, you can use a predefined list of files to block those files from a
repository. Merge requests that contain a file that matches the list are blocked.
This push rule does not restrict files already committed to the repository.
You must update the configuration of existing projects to use the rule, using the
process described in [Override global push rules per project](#override-global-push-rules-per-project).

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

- Private ECDSA_SK SSH keys:

  - `/ssh/id_ecdsa_sk`
  - `/.ssh/personal_ecdsa_sk`
  - `/config/server_ecdsa_sk`
  - `id_ecdsa_sk`
  - `.id_ecdsa_sk`

- Private ED25519_SK SSH keys:

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

### Prohibit files by name

In Git, filenames include both the file's name, and all directories preceding the name.
When you `git push`, each filename in the push is compared to the regular expression
in **Prohibited filenames**.

NOTE:
This feature uses [RE2 syntax](https://github.com/google/re2/wiki/Syntax),
which does not support positive or negative lookaheads.

The regular expression can:

- Match file names in any location in your repository.
- Match file names in specific locations.
- Match partial file names.
- Exclude specific file types by extension.
- Combine multiple expressions to exclude several patterns.

#### Regular expression examples

These examples use common regex string boundary patterns:

- `^`: Matches the beginning of a string.
- `$`: Matches the end of a string.
- `\.`: Matches a literal period character. The backslash escapes the period.
- `\/`: Matches a literal forward slash. The backslash escapes the forward slash.

##### Prevent specific file types

- To prevent pushing `.exe` files to any location in the repository:

  ```plaintext
  \.exe$
  ```

##### Prevent specific files

- To prevent pushing a specific configuration file:

  - In the repository root:

    ```plaintext
    ^config\.yml$
    ```

  - In a specific directory:

    ```plaintext
    ^directory-name\/config\.yml$
    ```

- In any location - This example prevents pushing any file named `install.exe`:

  ```plaintext
  (^|\/)install\.exe$
  ```

##### Combine patterns

You can combine multiple patterns into one expression. This example combines all the previous expressions:

```plaintext
(\.exe|^config\.yml|^directory-name\/config\.yml|(^|\/)install\.exe)$
```

## Related topics

- [Git server hooks](../../../administration/server_hooks.md) (previously called server hooks), to create complex custom push rules
- [Signing commits with GPG](signed_commits/gpg.md)
- [Signing commits with SSH](signed_commits/ssh.md)
- [Signing commits with X.509](signed_commits/x509.md)
- [Protected branches](branches/protected.md)
- [Secret detection](../../application_security/secret_detection/_index.md)

## Troubleshooting

### Reject unsigned commits push rule disables Web IDE

If a project has the **Reject unsigned commits** push rule, the user cannot
create commits through the GitLab Web IDE.

To allow committing through the Web IDE on a project with this push rule, a GitLab administrator
must disable the feature flag `reject_unsigned_commits_by_gitlab` [with a flag](../../../administration/feature_flags.md).

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

### Bulk update push rules for _all_ projects

To update the push rules to be the same for all projects,
use the [Rails console](../../../administration/operations/rails_console.md#starting-a-rails-console-session),
or write a script to update each project using the [push rules API endpoint](../../../api/project_push_rules.md).

For example, to enable **Check whether the commit author is a GitLab user** and **Do not allow users to remove Git tags with `git push`** checkboxes,
and create a filter for allowing commits from a specific email domain only through rails console:

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

``` ruby
Project.find_each do |p|
  pr = p.push_rule || PushRule.new(project: p)
  # Check whether the commit author is a GitLab user
  pr.member_check = true
  # Do not allow users to remove Git tags with `git push`
  pr.deny_delete_tag = true
  # Commit author's email
  pr.author_email_regex = '@domain\.com$'
  pr.save!
end
```
