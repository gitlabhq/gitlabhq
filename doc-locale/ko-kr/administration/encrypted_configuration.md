---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 암호화된 설정
description: 특정 기능에 대해 암호화된 설정을 활성화합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab은 암호화된 설정 파일에서 특정 기능에 대한 설정을 읽을 수 있습니다. 지원되는 기능은 다음과 같습니다:

- [수신 이메일 `user` 및 `password`](incoming_email.md#use-encrypted-credentials).
- [LDAP `bind_dn` 및 `password`](auth/ldap/_index.md#use-encrypted-credentials).
- [서비스 데스크 이메일 `user` 및 `password`](../user/project/service_desk/configure.md#use-encrypted-credentials).
- [SMTP `user_name` 및 `password`](raketasks/smtp.md#secrets).

암호화된 설정을 활성화하려면 `encrypted_settings_key_base`에 대한 새로운 기본 키를 생성해야 합니다. 비밀번호는 다음과 같은 방법으로 생성할 수 있습니다:

- Linux 패키지 설치의 경우, 새로운 비밀번호가 자동으로 생성되지만 `/etc/gitlab/gitlab-secrets.json`에 모든 노드에서 동일한 값이 포함되어 있는지 확인해야 합니다.
- Helm 차트 설치의 경우, `shared-secrets` 차트가 활성화되어 있으면 새로운 비밀번호가 자동으로 생성됩니다. 그렇지 않으면 [비밀번호 추가에 대한 가이드](https://docs.gitlab.com/charts/installation/secrets/#gitlab-rails-secret)를 따라야 합니다.
- 자체 컴파일 설치의 경우, 다음을 실행하여 새로운 비밀번호를 생성할 수 있습니다:

  ```shell
  bundle exec rake gitlab:env:info RAILS_ENV=production GITLAB_GENERATE_ENCRYPTED_SETTINGS_KEY_BASE=true
  ```

  이것은 GitLab 인스턴스에 대한 일반 정보를 출력하고 `<path-to-gitlab-rails>/config/secrets.yml`에서 키를 생성합니다.
