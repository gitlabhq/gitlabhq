---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Sign commits and tags with X.509 certificates **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/17773) in GitLab 12.8.

[X.509](https://en.wikipedia.org/wiki/X.509) is a standard format for public key
certificates issued by a public or private Public Key Infrastructure (PKI).
Personal X.509 certificates are used for authentication or signing purposes
such as S/MIME (Secure/Multipurpose Internet Mail Extensions).
However, Git also supports signing of commits and tags with X.509 certificates in a
similar way as with [GPG (GnuPG, or GNU Privacy Guard)](../gpg_signed_commits/index.md).
The main difference is the way GitLab determines whether or not the developer's signature is trusted:

- For X.509, a root certificate authority is added to the GitLab trust store.
  (A trust store is a repository of trusted security certificates.) Combined with
  any required intermediate certificates in the signature, the developer's certificate
  can be chained back to a trusted root certificate.
- For GPG, developers [add their GPG key](../gpg_signed_commits/index.md#add-a-gpg-key-to-your-account)
  to their account.

GitLab uses its own certificate store and therefore defines the
[trust chain](https://www.ssl.com/faqs/what-is-a-certificate-authority/).
For a commit or tag to be *verified* by GitLab:

- The signing certificate email must match a verified email address in GitLab.
- The GitLab instance must be able to establish a full trust chain
  from the certificate in the signature to a trusted certificate in the GitLab certificate store.
  This chain may include intermediate certificates supplied in the signature. You may
  need to add certificates, such as Certificate Authority root certificates,
  [to the GitLab certificate store](https://docs.gitlab.com/omnibus/settings/ssl/index.html#install-custom-public-certificates).
- The signing time must be in the time range of the
  [certificate validity](https://www.rfc-editor.org/rfc/rfc5280.html#section-4.1.2.5),
  which is usually up to three years.
- The signing time is equal to, or later than, the commit time.

If a commit's status has already been determined and stored in the database,
use the Rake task [to re-check the status](../../../../raketasks/x509_signatures.md).
Refer to the [Troubleshooting section](#troubleshooting).
GitLab checks certificate revocation lists on a daily basis with a background worker.

## Limitations

- Self-signed certificates without `authorityKeyIdentifier`,
  `subjectKeyIdentifier`, and `crlDistributionPoints` are not supported. We
  recommend using certificates from a PKI that are in line with
  [RFC 5280](https://www.rfc-editor.org/rfc/rfc5280).
- If you have more than one email in the Subject Alternative Name list in
  your signing certificate,
  [only the first one is used to verify commits](https://gitlab.com/gitlab-org/gitlab/-/issues/336677).
- The `X509v3 Subject Key Identifier` (SKI) in the issuer certificate and the
  signing certificate
  [must be 40 characters long](https://gitlab.com/gitlab-org/gitlab/-/issues/332503).
  If your SKI is shorter, commits don't show as verified in GitLab, and
  short subject key identifiers may also
  [cause errors when accessing the project](https://gitlab.com/gitlab-org/gitlab/-/issues/332464),
  such as 'An error occurred while loading commit signatures' and
  `HTTP 422 Unprocessable Entity` errors.

## Configure for signed commits

To sign your commits, tags, or both, you must:

1. [Obtain an X.509 key pair](#obtain-an-x509-key-pair).
1. [Associate your X.509 certificate with Git](#associate-your-x509-certificate-with-git).
1. [Sign and verify commits](#sign-and-verify-commits).
1. [Sign and verify tags](#sign-and-verify-tags).

### Obtain an X.509 key pair

If your organization has Public Key Infrastructure (PKI), that PKI provides
an S/MIME key. If you do not have an S/MIME key pair from a PKI, you can either
create your own self-signed pair, or purchase a pair.

### Associate your X.509 certificate with Git

To take advantage of X.509 signing, you need Git 2.19.0 or later. You can
check your Git version with the command `git --version`.

If you have the correct version, you can proceed to configure Git.

### Linux

Configure Git to use your key for signing:

```shell
signingkey=$( gpgsm --list-secret-keys | egrep '(key usage|ID)' | grep -B 1 digitalSignature | awk '/ID/ {print $2}' )
git config --global user.signingkey $signingkey
git config --global gpg.format x509
```

#### Windows and macOS

To configure Windows or macOS:

1. Install [S/MIME Sign](https://github.com/github/smimesign) by either:
   - Downloading the installer.
   - Running `brew install smimesign` on macOS.
1. Get the ID of your certificate by running `smimesign --list-keys`.
1. Set your signing key by running `git config --global user.signingkey <ID>`, replacing `<ID>` with the certificate ID.
1. Configure X.509 with this command:

   ```shell
   git config --global gpg.x509.program smimesign
   git config --global gpg.format x509
   ```

### Sign and verify commits

After you have [associated your X.509 certificate with Git](#associate-your-x509-certificate-with-git) you
can sign your commits:

1. When you create a Git commit, add the `-S` flag:

   ```shell
   git commit -S -m "feat: x509 signed commits"
   ```

1. Push to GitLab, and check that your commits are verified with the `--show-signature` flag:

   ```shell
   git log --show-signature
   ```

1. *If you don't want to type the `-S` flag every time you commit,* run this command
   for Git to sign your commits every time:

   ```shell
   git config --global commit.gpgsign true
   ```

### Sign and verify tags

After you have [associated your X.509 certificate with Git](#associate-your-x509-certificate-with-git) you
can start signing your tags:

1. When you create a Git tag, add the `-s` flag:

   ```shell
   git tag -s v1.1.1 -m "My signed tag"
   ```

1. Push to GitLab and verify your tags are signed with this command:

   ```shell
   git tag --verify v1.1.1
   ```

1. *If you don't want to type the `-s` flag every time you tag,* run this command
   for Git to sign your tags each time:

   ```shell
   git config --global tag.gpgsign true
   ```

## Related topics

- [Rake task for X.509 signatures](../../../../raketasks/x509_signatures.md)
- [Sign commits with GPG](../gpg_signed_commits/index.md)
- [Sign commits with SSH keys](../ssh_signed_commits/index.md)

## Troubleshooting

For committers without administrator access, review the list of
[verification problems with signed commits](../gpg_signed_commits/index.md#fix-verification-problems-with-signed-commits)
for possible fixes. The other troubleshooting suggestions on this page require
administrator access.

### Re-verify commits

GitLab stores the status of any checked commits in the database. You can use a
Rake task to [check the status of any previously checked commits](../../../../raketasks/x509_signatures.md).

After you make any changes, run this command:

```shell
sudo gitlab-rake gitlab:x509:update_signatures
```

### Main verification checks

The code performs
[these key checks](https://gitlab.com/gitlab-org/gitlab/-/blob/v14.1.0-ee/lib/gitlab/x509/signature.rb#L33),
which all must return `verified`:

- `x509_certificate.nil?` should be false.
- `x509_certificate.revoked?` should be false.
- `verified_signature` should be true.
- `user.nil?` should be false.
- `user.verified_emails.include?(@email)` should be true.
- `certificate_email == @email` should be true.

To investigate why a commit shows as `Unverified`:

1. [Start a Rails console](../../../../administration/operations/rails_console.md#starting-a-rails-console-session):

   ```shell
   sudo gitlab-rails console
   ```

1. Identify the project (either by path or ID) and full commit SHA that you're investigating.
   Use this information to create `signature` to run other checks against:

   ```ruby
   project = Project.find_by_full_path('group/subgroup/project')
   project = Project.find_by_id('121')
   commit = project.repository.commit_by(oid: '87fdbd0f9382781442053b0b76da729344e37653')
   signedcommit=Gitlab::X509::Commit.new(commit)
   signature=Gitlab::X509::Signature.new(signedcommit.signature_text, signedcommit.signed_text, commit.committer_email, commit.created_at)
   ```

   If you make changes to address issues identified running through the checks, restart the
   Rails console and run though the checks again from the start.

1. Check the certificate on the commit:

   ```ruby
   signature.x509_certificate.nil?
   signature.x509_certificate.revoked?
   ```

   Both checks should return `false`:

   ```ruby
   > signature.x509_certificate.nil?
   => false
   > signature.x509_certificate.revoked?
   => false
   ```

   A [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/332503) causes
   these checks to fail with `Validation failed: Subject key identifier is invalid`.

1. Run a cryptographic check on the signature. The code must return `true`:

   ```ruby
   signature.verified_signature
   ```

   If it returns `false` then [investigate this check further](#cryptographic-verification-checks).

1. Confirm the email addresses match on the commit and the signature:

   - The Rails console displays the email addresses being compared.
   - The final command must return `true`:

   ```ruby
   sigemail=signature.__send__:certificate_email
   commitemail=commit.committer_email
   sigemail == commitemail
   ```

   A [known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/336677) exists:
   only the first email in the `Subject Alternative Name` list is compared. To
   display the `Subject Alternative Name` list, run:

   ```ruby
   signature.__send__ :get_certificate_extension,'subjectAltName'
   ```

   If the developer's email address is not the first one in the list, this check
   fails, and the commit is marked `unverified`.

1. The email address on the commit must be associated with an account in GitLab.
   This check should return `false`:

   ```ruby
   signature.user.nil?
   ```

1. Check the email address is associated with a user in GitLab. This check should
   return a user, such as `#<User id:1234 @user_handle>`:

   ```ruby
   User.find_by_any_email(commit.committer_email)
   ```

   If it returns `nil`, the email address is not associated with a user, and the check fails.

1. Confirm the developer's email address is verified. This check must return true:

   ```ruby
   signature.user.verified_emails.include?(commit.committer_email)
   ```

   If the previous check returned `nil`, this command displays an error:

   ```plaintext
   NoMethodError (undefined method `verified_emails' for nil:NilClass)
   ```

1. The verification status is stored in the database. To display the database record:

   ```ruby
   pp CommitSignatures::X509CommitSignature.by_commit_sha(commit.sha);nil
   ```

   If all the previous checks returned the correct values:

   - `verification_status: "unverified"` indicates the database record needs
     updating. [Use the Rake task](#re-verify-commits).

   - `[]` indicates the database doesn't have a record yet. Locate the commit
     in GitLab to check the signature and store the result.

#### Cryptographic verification checks

If GitLab determines that `verified_signature` is `false`, investigate the reason
in the Rails console. These checks require `signature` to exist. Refer to the `signature`
step of the previous [main verification checks](#main-verification-checks).

1. Check the signature, without checking the issuer, returns `true`:

   ```ruby
   signature.__send__ :valid_signature?
   ```

1. Check the signing time and date. This check must return `true`:

   ```ruby
   signature.__send__ :valid_signing_time?
   ```

   - The code allows for code signing certificates to expire.
   - A commit must be signed during the validity period of the certificate,
     and at or after the commit's datestamp. Display the commit time and
     certificate details including `not_before`, `not_after` with:

     ```ruby
     commit.created_at
     pp signature.__send__ :cert; nil
     ```

1. Check the signature, including that TLS trust can be established. This check must return `true`:

   ```ruby
   signature.__send__(:p7).verify([], signature.__send__(:cert_store), signature.__send__(:signed_text))
   ```

   1. If this fails, add the missing certificates required to establish trust
      [to the GitLab certificate store](https://docs.gitlab.com/omnibus/settings/ssl/index.html#install-custom-public-certificates).

   1. After adding more certificates, (if these troubleshooting steps then pass)
      run the Rake task to [re-verify commits](#re-verify-commits).

   1. Display the certificates, including in the signature:

      ```ruby
      pp signature.__send__(:p7).certificates ; nil
      ```

Ensure any additional intermediate certificates and the root certificate are added
to the certificate store. For consistency with how certificate chains are built on
web servers:

- Git clients that are signing commits should include the certificate
  and all intermediate certificates in the signature.
- The GitLab certificate store should only contain the root.

If you remove a root certificate from the GitLab
trust store, such as when it expires, commit signatures which chain back to that
root display as `unverified`.
