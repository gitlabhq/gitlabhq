---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Package Signatures
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Linux packages produced by GitLab are created using [Omnibus](https://github.com/chef/omnibus), for which GitLab
has added DEB signing using `debsigs` in [our own fork](https://gitlab.com/gitlab-org/omnibus).

Combined with the existing functionality of RPM signing, this addition allows GitLab to provide signed packages for all
supported distributions using DEB or RPM.

These packages are produced by the GitLab CI process, as found in the
[`omnibus-gitlab` project](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.gitlab-ci.yml),
prior to their delivery to <https://packages.gitlab.com> to provide assurance that the packages are not altered prior
to delivery to our community.

## GnuPG Public Keys

All packages are signed with [GnuPG](https://www.gnupg.org/), in a method appropriate for their format. The key used to
sign these packages can be found on [MIT PGP Public Key Server](https://pgp.mit.edu) at
[`0x3cfcf9baf27eab47`](https://pgp.mit.edu/pks/lookup?op=vindex&search=0x3CFCF9BAF27EAB47).

## Verifying Signatures

Information on how to verify GitLab package signatures can be found in [Package Signatures](https://docs.gitlab.com/omnibus/update/package_signatures.html).

## GPG Signature Management

Information on how GitLab manages GPG keys for package signing can be found in [the runbooks](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/packaging/manage-package-signing-keys.md).
