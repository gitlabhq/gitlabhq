---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Package Signatures **(FREE SELF)**

Omnibus GitLab packages produced by GitLab are created via the [Omnibus](https://github.com/chef/omnibus) tool, for which GitLab has added DEB signing via `debsigs` in [our own fork](https://gitlab.com/gitlab-org/omnibus). This addition, combined with the existing functionality of RPM signing, allows GitLab to provide signed packages for all supported distributions using DEB or RPM.

These packages are produced by the GitLab CI process, as found in the  [Omnibus GitLab project](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.gitlab-ci.yml), prior to their delivery to <https://packages.gitlab.com> to ensure provide assurance that the packages are not altered prior to delivery to our community.

## GnuPG Public Keys

All packages are signed with [GnuPG](https://www.gnupg.org/), in a method appropriate for their format. The key used to sign these packages can be found on [MIT PGP Public Key Server](https://pgp.mit.edu) at [0x3cfcf9baf27eab47](https://pgp.mit.edu/pks/lookup?op=vindex&search=0x3CFCF9BAF27EAB47)

## Verifying Signatures

Information on how to verify GitLab package signatures can be found in [Package Signatures](https://docs.gitlab.com/omnibus/update/package_signatures.html).

## GPG Signature Management

Information on how GitLab manages GPG keys for package signing can be found in [the runbooks](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/packaging/manage-package-signing-keys.md).
