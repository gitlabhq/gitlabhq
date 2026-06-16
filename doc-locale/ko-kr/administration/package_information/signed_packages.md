---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 패키지 서명
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

<!-- vale gitlab_base.SubstitutionWarning = NO -->

GitLab에서 생성한 Linux 패키지는 [Omnibus](https://github.com/chef/omnibus) 를 사용하여 만들어지며, GitLab은 [자체 포크](https://gitlab.com/gitlab-org/omnibus)에서 `debsigs`를 사용하여 DEB 서명을 추가했습니다.

<!-- vale gitlab_base.SubstitutionWarning = YES -->

기존 RPM 서명 기능과 함께, 이 추가 기능을 통해 GitLab은 DEB 또는 RPM을 사용하는 모든 지원되는 배포판에 대해 서명된 패키지를 제공할 수 있습니다.

이러한 패키지는 [`omnibus-gitlab` 프로젝트](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/.gitlab-ci.yml)에 있는 GitLab CI 프로세스에 의해 생성되며, <https://packages.gitlab.com>으로 전달하기 전에 패키지가 커뮤니티에 전달되기 전에 변경되지 않았음을 보장하기 위해 생성됩니다.

## GnuPG 공개 키 {#gnupg-public-keys}

모든 패키지는 [GnuPG](https://www.gnupg.org/)로 서명되며, 형식에 적합한 방식으로 서명됩니다. 이 패키지에 서명하는 데 사용된 키는 [MIT PGP 공개 키 서버](https://pgp.mit.edu) 의 [`0x3cfcf9baf27eab47`](https://pgp.mit.edu/pks/lookup?op=vindex&search=0x3CFCF9BAF27EAB47)에서 찾을 수 있습니다.

## 서명 확인 {#verifying-signatures}

GitLab 패키지 서명을 확인하는 방법에 대한 정보는 [패키지 서명](https://docs.gitlab.com/omnibus/update/package_signatures/)에서 찾을 수 있습니다.

## GPG 서명 관리 {#gpg-signature-management}

GitLab이 패키지 서명을 위한 GPG 키를 관리하는 방법에 대한 정보는 [런북](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/packaging/manage-package-signing-keys.md)에서 찾을 수 있습니다.
