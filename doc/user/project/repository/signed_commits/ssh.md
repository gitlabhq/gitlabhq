---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Sign commits and tags in your GitLab repository with SSH keys.
title: Sign commits and tags with SSH keys
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When you sign commits or tags with SSH keys, GitLab uses the SSH public keys
associated with your GitLab account to cryptographically verify the signature.
If successful, GitLab displays a **Verified** label on the commit or tag.

For GitLab to consider a commit verified:

- You must add the SSH key used to sign the commit to your GitLab account
  with a [usage type](../../../ssh.md#add-an-ssh-key-to-your-gitlab-account)
  of **Authentication & Signing** or **Signing**.
- The committer email address in your Git configuration must match a
  [verified email address](../../../profile/_index.md#change-your-primary-email)
  associated with your GitLab account.

If the signature is valid but the committer email does not match a verified
email on your account, the commit is marked **Unverified**.

You may use the same SSH keys for `git+ssh` authentication to GitLab
and signing commit signatures as long as their usage type is **Authentication & Signing**.
It can be verified on the page for [adding an SSH key to your GitLab account](../../../ssh.md#add-an-ssh-key-to-your-gitlab-account).

For more information about managing the SSH keys associated with your GitLab account, see
[use SSH keys to communicate with GitLab](../../../ssh.md).

## Configure Git to sign commits and tags with your SSH key

After you [create an SSH key](../../../ssh.md#generate-an-ssh-key-pair) and
[add it to your GitLab account](../../../ssh.md#add-an-ssh-key-to-your-gitlab-account)
configure Git to begin using the key.

Prerequisites:

- Git 2.34.0 or later.
- OpenSSH 8.1 or later.

  > [!note]
  > OpenSSH 8.7 has broken signing functionality. If you are on OpenSSH 8.7, upgrade to OpenSSH 8.8.

- An SSH key with the **Usage type** `Authentication & Signing` or `Signing`.
  The following SSH key types are supported:
  - ED25519
  - ED25519_SK
  - RSA
  - ECDSA
  - ECDSA_SK

To configure Git to use your key:

1. Configure Git to use SSH for commit signing:

   ```shell
   git config --global gpg.format ssh
   ```

1. Specify which public SSH key to use as the signing key and change the filename (`~/.ssh/examplekey.pub`) to the location of your key. The filename might
   differ, depending on how you generated your key:

   ```shell
   git config --global user.signingkey ~/.ssh/examplekey.pub
   ```

## Sign commits with your SSH key

Prerequisites:

- You've [created an SSH key](../../../ssh.md#generate-an-ssh-key-pair).
- You've [added the key](../../../ssh.md#add-an-ssh-key-to-your-gitlab-account) to your GitLab account.
- You've [configured Git to sign commits](#configure-git-to-sign-commits-and-tags-with-your-ssh-key) with your SSH key.
- Your Git `user.email` matches a [verified email address](../../../profile/_index.md#change-your-primary-email)
  associated with your GitLab account.

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
1. Check that your commits [are verified](#verify-commits).
   Signature verification uses the `allowed_signers` file to associate emails and SSH keys.
   For help configuring this file, see [verify commits locally](#verify-commits-locally).

## Sign and verify tags

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/384473) in GitLab 18.3 [with a flag](../../../../administration/feature_flags/_index.md) named `render_ssh_signed_tags_verification_status`. Disabled by default.
- [Enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/561452) in GitLab 18.11.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

After you [configure Git to sign commits and tags](#configure-git-to-sign-commits-and-tags-with-your-ssh-key)
with your SSH key, you can sign your tags:

1. When you create a Git tag, add the `-s` flag:

   ```shell
   git tag -s v1.1.1 -m "My signed tag"
   ```

1. Push to GitLab and verify your tags are signed with this command:

   ```shell
   git tag --verify v1.1.1
   ```

1. Optional. To sign tags automatically without the `-s` flag, run:

   ```shell
   git config --global tag.gpgsign true
   ```

## Verify commits

You can verify all types of signed commits
[in the GitLab UI](_index.md#verify-commits). Commits signed
with an SSH key can also be verified locally.

### Verify commits locally

To verify commits locally, create an
[allowed signers file](https://man7.org/linux/man-pages/man1/ssh-keygen.1.html#ALLOWED_SIGNERS)
for Git to associate SSH public keys with users.
This example uses `~/.ssh/allowed_signers`, but you can specify a different path.
Use the same path in the following steps.

1. Create an SSH directory:

   ```shell
   mkdir -p ~/.ssh
   ```

1. Create an allowed signers file.

   ```shell
   touch ~/.ssh/allowed_signers
   ```

1. Configure Git to use the file:

   ```shell
   git config gpg.ssh.allowedSignersFile "$HOME/.ssh/allowed_signers"
   ```

1. Add your entry to the allowed signers file. Replace `<MY_KEY>` with the name of your key.
   If you chose a different path in step 1, replace `~/.ssh/allowed_signers` with that path:

   ```shell
   # Declaring the `git` namespace helps prevent cross-protocol attacks.
   echo "$(git config --get user.email) namespaces=\"git\" $(cat ~/.ssh/<MY_KEY>.pub)" >> ~/.ssh/allowed_signers
   ```

   The resulting entry contains your email address, key type, and key contents:

   ```plaintext
   example@gitlab.com namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAmaTS47vRmsKyLyK1jlIFJn/i8wdGQ3J49LYyIYJ2hv
   ```

1. Repeat this step for each additional user you want to verify.
   If you collaborate with other contributors, consider checking this file into your Git repository.

1. Use `git log --show-signature` to view the signature status for commits:

   ```shell
   $ git log --show-signature

   commit e2406b6cd8ebe146835ceab67ff4a5a116e09154 (HEAD -> main, origin/main, origin/HEAD)
   Good "git" signature for johndoe@example.com with ED25519 key SHA256:Ar44iySGgxic+U6Dph4Z9Rp+KDaix5SFGFawovZLAcc
   Author: John Doe <johndoe@example.com>
   Date:   Tue Nov 29 06:54:15 2022 -0600

       SSH signed commit
   ```

## Signed commits with removed SSH keys

You can revoke or delete your SSH keys used to sign commits. For more information, see [remove an SSH key](../../../ssh.md#remove-an-ssh-key).

Removing your SSH key can impact any commits signed with the key:

- Revoking your SSH key marks your previous commits as **Unverified**. Until you add a new SSH key, any new commits are also marked as **Unverified**.
- Deleting your SSH key doesn't impact your previous commits. Until you add a new SSH key, any new commits are marked as **Unverified**.

## Related topics

- [Sign commits and tags with X.509 certificates](x509.md)
- [Sign commits with GPG](gpg.md)
- [Commits API](../../../../api/commits.md)
