---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: concepts, howto
---

# Signing commits and tags with X.509 **(FREE)**

[X.509](https://en.wikipedia.org/wiki/X.509) is a standard format for public key
certificates issued by a public or private Public Key Infrastructure (PKI).
Personal X.509 certificates are used for authentication or signing purposes
such as SMIME, but Git also supports signing of commits and tags
with X.509 certificates in a similar way as with [GPG](../gpg_signed_commits/index.md).
The main difference is the trust anchor which is the PKI for X.509 certificates
instead of a web of trust with GPG.

## How GitLab handles X.509

GitLab uses its own certificate store and therefore defines the trust chain.

For a commit or tag to be *verified* by GitLab:

- The signing certificate email must match a verified email address used by the committer in GitLab.
- The Certificate Authority has to be trusted by the GitLab instance, see also
  [Omnibus install custom public certificates](https://docs.gitlab.com/omnibus/settings/ssl.html#install-custom-public-certificates).
- The signing time has to be within the time range of the [certificate validity](https://www.rfc-editor.org/rfc/rfc5280.html#section-4.1.2.5)
  which is usually up to three years.
- The signing time is equal or later than commit time.

NOTE:
Certificate revocation lists are checked on a daily basis via background worker.

NOTE:
Self signed certificates without `authorityKeyIdentifier`,
`subjectKeyIdentifier`, and `crlDistributionPoints` are not supported. We
recommend using certificates from a PKI that are in line with
[RFC 5280](https://tools.ietf.org/html/rfc5280).

## Obtaining an X.509 key pair

If your organization has Public Key Infrastructure (PKI), that PKI provides
an S/MIME key.

If you do not have an S/MIME key pair from a PKI, you can either create your
own self-signed one, or purchase one. MozillaZine keeps a nice collection
of [S/MIME-capable signing authorities](http://kb.mozillazine.org/Getting_an_SMIME_certificate)
and some of them generate keys for free.

## Associating your X.509 certificate with Git

To take advantage of X.509 signing, you need Git 2.19.0 or later. You can
check your Git version with:

```shell
git --version
```

If you have the correct version, you can proceed to configure Git.

### Linux

Configure Git to use your key for signing:

```shell
signingkey = $( gpgsm --list-secret-keys | egrep '(key usage|ID)' | grep -B 1 digitalSignature | awk '/ID/ {print $2}' )
git config --global user.signingkey $signingkey
git config --global gpg.format x509
```

### Windows and MacOS

Install [S/MIME Sign](https://github.com/github/smimesign) by downloading the
installer or via `brew install smimesign` on MacOS.

Get the ID of your certificate with `smimesign --list-keys` and set your
signing key `git config --global user.signingkey ID`, then configure X.509:

```shell
git config --global gpg.x509.program smimesign
git config --global gpg.format x509
```

## Signing commits

After you have [associated your X.509 certificate with Git](#associating-your-x509-certificate-with-git) you
can start signing your commits:

1. Commit like you used to, the only difference is the addition of the `-S` flag:

   ```shell
   git commit -S -m "feat: x509 signed commits"
   ```

1. Push to GitLab and check that your commits [are verified](#verifying-commits).

If you don't want to type the `-S` flag every time you commit, you can tell Git
to sign your commits automatically:

```shell
git config --global commit.gpgsign true
```

## Verifying commits

To verify that a commit is signed, you can use the `--show-signature` flag:

```shell
git log --show-signature
```

## Signing tags

After you have [associated your X.509 certificate with Git](#associating-your-x509-certificate-with-git) you
can start signing your tags:

1. Tag like you used to, the only difference is the addition of the `-s` flag:

   ```shell
   git tag -s v1.1.1 -m "My signed tag"
   ```

1. Push to GitLab and check that your tags [are verified](#verifying-tags).

If you don't want to type the `-s` flag every time you tag, you can tell Git
to sign your tags automatically:

```shell
git config --global tag.gpgsign true
```

## Verifying tags

To verify that a tag is signed, you can use the `--verify` flag:

```shell
git tag --verify v1.1.1
```
