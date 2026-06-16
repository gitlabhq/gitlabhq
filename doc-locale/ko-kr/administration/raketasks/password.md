---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 비밀번호 관리 Rake 작업
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 비밀번호를 관리하기 위한 Rake 작업을 제공합니다.

## 비밀번호 재설정 {#reset-passwords}

Rake 작업을 사용하여 비밀번호를 재설정하려면 [사용자 비밀번호 재설정](../../security/reset_user_password.md#use-a-rake-task)을 참고하세요.

## 비밀번호 해시 확인 {#check-password-hashes}

GitLab 17.11부터 FIPS 인스턴스의 비밀번호 해시 솔트는 사용자가 로그인할 때 증가합니다.

FIPS가 아닌 인스턴스는 GitLab 17.9에서 업데이트된 bcrypt 작업 인수를 사용하기 시작했습니다.

마이그레이션되지 않은 비밀번호 해시를 가진 사용자가 몇 명인지 확인할 수 있습니다:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:password:check_hashes:[true]

# installation from source
bundle exec rake gitlab:password:check_hashes:[true] RAILS_ENV=production
```

> [!note]
> GitLab 18.6 이전에는 이 작업을 `gitlab:password:fips_check_salts`(으)로 사용할 수 있었으며 FIPS/PBKDF2 해시 유효성 검사로 제한되었습니다. 작업의 이름이 `:check_hashes`(으)로 변경되었으며, 이제 모든 비밀번호 마이그레이션을 확인합니다. 기존 이름은 별칭으로 유지됩니다.
