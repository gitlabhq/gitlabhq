---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: concepts, howto
---

# Signing commits with GPG **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/9546) in GitLab 9.5.
> - Subkeys support was added in GitLab 10.1.

You can use a GPG key to sign Git commits made in a GitLab repository. Signed
commits are labeled **Verified** if the identity of the committer can be
verified. To verify the identity of a committer, GitLab requires their public
GPG key.

NOTE:
The term GPG is used for all OpenPGP/PGP/GPG related material and
implementations.

GPG verified tags are not supported yet.

See the [further reading](#further-reading) section for more details on GPG.

## How GitLab handles GPG

GitLab uses its own keyring to verify the GPG signature. It does not access any
public key server.

For a commit to be verified by GitLab:

- The committer must have a GPG public/private key pair.
- The committer's public key must have been uploaded to their GitLab
  account.
- One of the emails in the GPG key must match a **verified** email address
  used by the committer in GitLab.
- The committer's email address must match the verified email address from the
  GPG key.

## Generating a GPG key

If you don't already have a GPG key, the following steps can help you get
started:

1. [Install GPG](https://www.gnupg.org/download/index.html) for your operating system.
   If your operating system has `gpg2` installed, replace `gpg` with `gpg2` in
   the following commands.
1. Generate the private/public key pair with the following command, which will
   spawn a series of questions:

   ```shell
   gpg --full-gen-key
   ```

   NOTE:
   In some cases like Gpg4win on Windows and other macOS versions, the command
   here may be `gpg --gen-key`.

1. The first question is which algorithm can be used. Select the kind you want
   or press <kbd>Enter</kbd> to choose the default (RSA and RSA):

   ```plaintext
   Please select what kind of key you want:
      (1) RSA and RSA (default)
      (2) DSA and Elgamal
      (3) DSA (sign only)
      (4) RSA (sign only)
   Your selection? 1
   ```

1. The next question is key length. We recommend you choose `4096`:

   ```plaintext
   RSA keys may be between 1024 and 4096 bits long.
   What keysize do you want? (2048) 4096
   Requested keysize is 4096 bits
   ```

1. Specify the validity period of your key. This is something
   subjective, and you can use the default value, which is to never expire:

   ```plaintext
   Please specify how long the key should be valid.
            0 = key does not expire
         <n>  = key expires in n days
         <n>w = key expires in n weeks
         <n>m = key expires in n months
         <n>y = key expires in n years
   Key is valid for? (0) 0
   Key does not expire at all
   ```

1. Confirm that the answers you gave were correct by typing `y`:

   ```plaintext
   Is this correct? (y/N) y
   ```

1. Enter your real name, the email address to be associated with this key
   (should match a verified email address you use in GitLab) and an optional
   comment (press <kbd>Enter</kbd> to skip):

   ```plaintext
   GnuPG needs to construct a user ID to identify your key.

   Real name: Mr. Robot
   Email address: <your_email>
   Comment:
   You selected this USER-ID:
       "Mr. Robot <your_email>"

   Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
   ```

1. Pick a strong password when asked and type it twice to confirm.
1. Use the following command to list the private GPG key you just created:

   ```shell
   gpg --list-secret-keys --keyid-format LONG <your_email>
   ```

   Replace `<your_email>` with the email address you entered above.

1. Copy the GPG key ID that starts with `sec`. In the following example, that's
   `30F2B65B9246B6CA`:

   ```plaintext
   sec   rsa4096/30F2B65B9246B6CA 2017-08-18 [SC]
         D5E4F29F3275DC0CDA8FFC8730F2B65B9246B6CA
   uid                   [ultimate] Mr. Robot <your_email>
   ssb   rsa4096/B7ABC0813E4028C0 2017-08-18 [E]
   ```

1. Export the public key of that ID (replace your key ID from the previous step):

   ```shell
   gpg --armor --export 30F2B65B9246B6CA
   ```

1. Finally, copy the public key and [add it in your user settings](#adding-a-gpg-key-to-your-account)

## Adding a GPG key to your account

NOTE:
After you add a key, you cannot edit it, only remove it. In case the paste
didn't work, you have to remove the offending key and re-add it.

You can add a GPG key in your user settings:

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **GPG Keys**.
1. Paste your _public_ key in the **Key** text box.

   ![Paste GPG public key](img/profile_settings_gpg_keys_paste_pub.png)

1. Select **Add key** to add it to GitLab. You can see the key's fingerprint, the corresponding
   email address, and creation date.

   ![GPG key single page](img/profile_settings_gpg_keys_single_key.png)

## Associating your GPG key with Git

After you have [created your GPG key](#generating-a-gpg-key) and [added it to
your account](#adding-a-gpg-key-to-your-account), it's time to tell Git which
key to use.

1. Use the following command to list the private GPG key you just created:

   ```shell
   gpg --list-secret-keys --keyid-format LONG <your_email>
   ```

   Replace `<your_email>` with the email address you entered above.

1. Copy the GPG key ID that starts with `sec`. In the following example, that's
   `30F2B65B9246B6CA`:

   ```plaintext
   sec   rsa4096/30F2B65B9246B6CA 2017-08-18 [SC]
         D5E4F29F3275DC0CDA8FFC8730F2B65B9246B6CA
   uid                   [ultimate] Mr. Robot <your_email>
   ssb   rsa4096/B7ABC0813E4028C0 2017-08-18 [E]
   ```

1. Tell Git to use that key to sign the commits:

   ```shell
   git config --global user.signingkey 30F2B65B9246B6CA
   ```

   Replace `30F2B65B9246B6CA` with your GPG key ID.

1. (Optional) If Git is using `gpg` and you get errors like `secret key not available`
   or `gpg: signing failed: secret key not available`, run the following command to
   change to `gpg2`:

   ```shell
   git config --global gpg.program gpg2
   ```

## Signing commits

After you have [created your GPG key](#generating-a-gpg-key) and [added it to
your account](#adding-a-gpg-key-to-your-account), you can start signing your
commits:

1. Commit like you used to, the only difference is the addition of the `-S` flag:

   ```shell
   git commit -S -m "My commit msg"
   ```

1. Enter the passphrase of your GPG key when asked.
1. Push to GitLab and check that your commits [are verified](#verifying-commits).

If you don't want to type the `-S` flag every time you commit, you can tell Git
to sign your commits automatically:

```shell
git config --global commit.gpgsign true
```

## Verifying commits

1. Within a project or [merge request](../../merge_requests/index.md), navigate to
   the **Commits** tab. Signed commits show a badge containing either
   **Verified** or **Unverified**, depending on the verification status of the GPG
   signature.

   ![Signed and unsigned commits](img/project_signed_and_unsigned_commits.png)

1. By clicking on the GPG badge, details of the signature are displayed.

   ![Signed commit with verified signature](img/project_signed_commit_verified_signature.png)

   ![Signed commit with verified signature](img/project_signed_commit_unverified_signature.png)

## Revoking a GPG key

Revoking a key **unverifies** already signed commits. Commits that were
verified by using this key changes to an unverified state. Future commits
stay unverified after you revoke this key. This action should be used
in case your key has been compromised.

To revoke a GPG key:

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **GPG Keys**.
1. Select **Revoke** next to the GPG key you want to delete.

## Removing a GPG key

Removing a key **does not unverify** already signed commits. Commits that were
verified by using this key stay verified. Only unpushed commits stay
unverified after you remove this key. To unverify already signed commits, you need
to [revoke the associated GPG key](#revoking-a-gpg-key) from your account.

To remove a GPG key from your account:

1. In the top-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **GPG Keys**.
1. Select the trash icon (**{remove}**) next to the GPG key you want to delete.

## Rejecting commits that are not signed **(PREMIUM)**

You can configure your project to reject commits that aren't GPG-signed
via [push rules](../../../../push_rules/push_rules.md).

## GPG signing API

Learn how to [get the GPG signature from a commit via API](../../../../api/commits.md#get-gpg-signature-of-a-commit).

## Further reading

For more details about GPG, see:

- [Git Tools - Signing Your Work](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)
- [Managing OpenPGP Keys](https://riseup.net/en/security/message-security/openpgp/gpg-keys)
- [OpenPGP Best Practices](https://riseup.net/en/security/message-security/openpgp/best-practices)
- [Creating a new GPG key with subkeys](https://www.void.gr/kargig/blog/2013/12/02/creating-a-new-gpg-key-with-subkeys/) (advanced)
- [Review existing GPG keys in your instance](../../../admin_area/credentials_inventory.md#review-existing-gpg-keys)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
