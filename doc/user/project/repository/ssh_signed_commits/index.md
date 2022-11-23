---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Sign commits with SSH keys **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/343879) in GitLab 15.7 [with a flag](../../../../administration/feature_flags.md) named `ssh_commit_signatures`. Disabled by default.

Use SSH keys to sign Git commits in the same manner as
[GPG signed commits](../gpg_signed_commits/index.md). When you sign commits
with SSH keys, GitLab uses the SSH public keys associated with your
GitLab account to cryptographically verify the commit signature.
If successful, GitLab displays a **Verified** label on the commit.

You may use the same SSH keys for `git+ssh` authentication to GitLab
and signing commit signatures.

To learn more about managing the SSH keys associated with your GitLab account, read
[use SSH keys to communicate with GitLab](../../../ssh.md).

## Configure Git to sign commits with your SSH key

After you have [created an SSH key](../../../ssh.md#generate-an-ssh-key-pair) and
[added it to your GitLab account](../../../ssh.md#add-an-ssh-key-to-your-gitlab-account),
you need to configure Git to begin using it.

Prerequisites:

- Git 2.34.0 or newer.
- OpenSSH 8.0 or newer.

  NOTE:
  OpenSSH 8.7 has broken signing functionality. If you are on OpenSSH 8.7, upgrade to OpenSSH 8.8.

- A SSH key of one of these types:
  - [ED25519](../../../ssh.md#ed25519-ssh-keys) (recommended)
  - [RSA](../../../ssh.md#rsa-ssh-keys)

To configure Git:

1. Configure Git to use SSH for commit signing:

   ```shell
   git config --global gpg.format ssh
   ```

1. Specify which SSH key should be used as the signing key, changing the filename
   (here, `~/.ssh/examplekey`) to the location of your key. The filename may
   differ, depending on how you generated your key:

   ```shell
   git config --global user.signingkey ~/.ssh/examplekey
   ```

## Sign commits with your SSH key

Prerequisites:

- You've [created an SSH key](../../../ssh.md#generate-an-ssh-key-pair).
- You've [added the key](../../../ssh.md#add-an-ssh-key-to-your-gitlab-account) to your GitLab account.
- You've [configured Git to sign commits](#configure-git-to-sign-commits-with-your-ssh-key) with your SSH key.

To sign a commit:

1. Use the `-S` flag when signing your commits:

   ```shell
   git commit -S -m "My commit msg"
   ```

1. Optional. If you don't want to type the `-S` flag every time you commit, tell
   Git to sign your commits automatically:

   ```shell
   git config --global commit.gpgsign true
   ```

1. If your SSH key is protected, Git prompts you to enter your passphrase.
1. Push to GitLab.
1. Check that your commits [are verified](../gpg_signed_commits/index.md#verify-commits).

## Verify commits

You can review commits for a merge request, or for an entire project, to confirm
they are signed:

1. To review commits for a project:
   1. On the top bar, select **Main menu > Projects** and find your project.
   1. On the left sidebar, select **Repository > Commits**.
1. To review commits for a merge request:
   1. On the top bar, select **Main menu > Projects** and find your project.
   1. On the left sidebar, select **Merge requests**, then select your merge request.
   1. Select **Commits**.
1. Identify the commit you want to review. Signed commits show either a **Verified**
   or **Unverified** badge, depending on the verification status of the signature.
   Unsigned commits do not display a badge.

1. To display the signature details for a commit, select **Verified**. GitLab shows
   the SSH key's fingerprint.

## Revoke an SSH key for signing commits

You can't revoke an SSH key used for signing commits. To learn more, read
[Add revocation for SSH keys](https://gitlab.com/gitlab-org/gitlab/-/issues/382984).

## Related topics

- [Sign commits and tags with X.509 certificates](../x509_signed_commits/index.md)
- [Sign commits with GPG](../gpg_signed_commits/index.md)
- [Commits API](../../../../api/commits.md)
