---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Rake 작업을 사용하여 대량 사용자 작업을 수행하고 인증 설정을 관리합니다.
title: 사용자 관리 Rake 작업
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 사용자 관리를 위한 Rake 작업을 제공합니다. 관리자는 **운영자** 영역을 사용하여 [사용자 관리](../admin_area.md#administering-users)를 할 수도 있습니다.

## 모든 프로젝트에 개발자로 사용자 추가 {#add-user-as-a-developer-to-all-projects}

모든 프로젝트에 개발자로 사용자를 추가하려면 다음을 실행합니다:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_projects[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_projects[username@domain.tld] RAILS_ENV=production
```

## 모든 프로젝트에 모든 사용자 추가 {#add-all-users-to-all-projects}

모든 프로젝트에 모든 사용자를 추가하려면 다음을 실행합니다:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_projects

# installation from source
bundle exec rake gitlab:import:all_users_to_all_projects RAILS_ENV=production
```

관리자는 유지관리자로 추가되고 다른 모든 사용자는 개발자로 추가됩니다.

## 모든 그룹에 개발자로 사용자 추가 {#add-user-as-a-developer-to-all-groups}

모든 그룹에 개발자로 사용자를 추가하려면 다음을 실행합니다:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_groups[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_groups[username@domain.tld] RAILS_ENV=production
```

## 모든 그룹에 모든 사용자 추가 {#add-all-users-to-all-groups}

모든 그룹에 모든 사용자를 추가하려면 다음을 실행합니다:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_groups

# installation from source
bundle exec rake gitlab:import:all_users_to_all_groups RAILS_ENV=production
```

관리자는 소유자로 추가되므로 그룹에 추가 사용자를 추가할 수 있습니다.

## 주어진 그룹의 모든 사용자를 `project_limit:0`과(와) `can_create_group: false`으로 업데이트 {#update-all-users-in-a-given-group-to-project_limit0-and-can_create_group-false}

주어진 그룹의 모든 사용자를 `project_limit: 0`과(와) `can_create_group: false`으로 업데이트하려면 다음을 실행합니다:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:user_management:disable_project_and_group_creation\[:group_id\]

# installation from source
bundle exec rake gitlab:user_management:disable_project_and_group_creation\[:group_id\] RAILS_ENV=production
```

주어진 그룹, 해당 하위 그룹 및 이 그룹 네임스페이스의 프로젝트에 있는 모든 사용자를 지정된 제한 사항으로 업데이트합니다.

## 청구 가능한 사용자 수 제어 {#control-the-number-of-billable-users}

이 설정을 활성화하여 관리자가 승인할 때까지 새 사용자를 차단 상태로 유지합니다. 기본값은 `false`입니다:

```plaintext
block_auto_created_users: false
```

## 모든 사용자를 위한 2단계 인증 비활성화 {#disable-two-factor-authentication-for-all-users}

이 작업은 활성화된 모든 사용자를 위한 2단계 인증(2FA)을 비활성화합니다. GitLab `config/secrets.yml` 파일이 손실되어 사용자가 로그인할 수 없는 경우 유용할 수 있습니다.

모든 사용자를 위한 2단계 인증을 비활성화하려면 다음을 실행합니다:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:two_factor:disable_for_all_users

# installation from source
bundle exec rake gitlab:two_factor:disable_for_all_users RAILS_ENV=production
```

## 2단계 인증 암호화 키 회전 {#rotate-two-factor-authentication-encryption-key}

GitLab은 암호화된 데이터베이스 열에 2단계 인증(2FA)에 필요한 비밀 데이터를 저장합니다. 이 데이터의 암호화 키는 `otp_key_base`으로 알려져 있으며 `config/secrets.yml`에 저장됩니다.

해당 파일이 유출되었지만 개별 2FA 비밀은 유출되지 않은 경우 새 암호화 키로 해당 비밀을 다시 암호화할 수 있습니다. 이를 통해 모든 사용자가 2FA 세부 정보를 변경하도록 강요하지 않고 유출된 키를 변경할 수 있습니다.

2단계 인증 암호화 키를 회전하려면:

1. `config/secrets.yml` 파일에서 이전 키를 찾되, **make sure you're working with the production section**하세요. 찾고 있는 줄은 다음과 같습니다:

   ```yaml
   production:
     otp_key_base: fffffffffffffffffffffffffffffffffffffffffffffff
   ```

1. 새로운 비밀을 생성합니다:

   ```shell
   # omnibus-gitlab
   sudo gitlab-rake secret

   # installation from source
   bundle exec rake secret RAILS_ENV=production
   ```

1. GitLab 서버를 중지하고, 기존 비밀 파일을 백업한 후 데이터베이스를 업데이트합니다:

   ```shell
   # omnibus-gitlab
   sudo gitlab-ctl stop
   sudo cp config/secrets.yml config/secrets.yml.bak
   sudo gitlab-rake gitlab:two_factor:rotate_key:apply filename=backup.csv old_key=<old key> new_key=<new key>

   # installation from source
   sudo /etc/init.d/gitlab stop
   cp config/secrets.yml config/secrets.yml.bak
   bundle exec rake gitlab:two_factor:rotate_key:apply filename=backup.csv old_key=<old key> new_key=<new key> RAILS_ENV=production
   ```

   `<old key>` 값은 `config/secrets.yml`에서 읽을 수 있습니다(`<new key>`은 앞서 생성됨). 사용자 2FA 비밀의 **encrypted** 값은 지정된 `filename`에 기록됩니다. 오류가 발생한 경우 이를 사용하여 롤백할 수 있습니다.

1. `config/secrets.yml`을(를) 변경하여 `otp_key_base`을(를) `<new key>`으로 설정하고 다시 시작합니다. 다시 말해, **production** 섹션에서 작업 중인지 확인하세요.

   ```shell
   # omnibus-gitlab
   sudo gitlab-ctl start

   # installation from source
   sudo /etc/init.d/gitlab start
   ```

문제가 있으면(`old_key`에 대해 잘못된 값을 사용한 경우) `config/secrets.yml`의 백업을 복원하고 변경 사항을 롤백할 수 있습니다:

```shell
# omnibus-gitlab
sudo gitlab-ctl stop
sudo gitlab-rake gitlab:two_factor:rotate_key:rollback filename=backup.csv
sudo cp config/secrets.yml.bak config/secrets.yml
sudo gitlab-ctl start

# installation from source
sudo /etc/init.d/gitlab start
bundle exec rake gitlab:two_factor:rotate_key:rollback filename=backup.csv RAILS_ENV=production
cp config/secrets.yml.bak config/secrets.yml
sudo /etc/init.d/gitlab start

```

## GitLab Duo에 사용자 대량 할당 {#bulk-assign-users-to-gitlab-duo}

CSV 파일을 사용하여 사용자를 GitLab Duo에 대량으로 할당할 수 있습니다. CSV 파일은 `username`이라는 헤더를 가져야 하며, 그 다음 각 행에 사용자 이름을 입력해야 합니다.

```plaintext
username
user1
user2
user3
user4
```

### GitLab Duo Pro {#gitlab-duo-pro}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.9에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142189).

{{< /history >}}

GitLab Duo Pro를 위한 대량 사용자 할당을 수행하려면 다음 Rake 작업을 사용할 수 있습니다:

```shell
bundle exec rake duo_pro:bulk_user_assignment DUO_PRO_BULK_USER_FILE_PATH=path/to/your/file.csv
```

파일 경로에서 대괄호를 사용하려면 대괄호를 이스케이프하거나 큰 따옴표를 사용할 수 있습니다:

```shell
bundle exec rake duo_pro:bulk_user_assignment\['path/to/your/file.csv'\]
# or
bundle exec rake "duo_pro:bulk_user_assignment[path/to/your/file.csv]"
```

### GitLab Duo Pro 및 Enterprise {#gitlab-duo-pro-and-enterprise}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.0에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187230).

{{< /history >}}

#### GitLab Self-Managed {#gitlab-self-managed}

이 Rake 작업은 사용 가능한 구매한 추가 기능을 기반으로 CSV 파일의 사용자 목록에 인스턴스 수준에서 GitLab Duo Pro 또는 Enterprise 사용자를 대량으로 할당합니다.

GitLab Self-Managed 인스턴스의 대량 사용자 할당을 수행하려면:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment DUO_BULK_USER_FILE_PATH=path/to/your/file.csv
```

파일 경로에서 대괄호를 사용하려면 대괄호를 이스케이프하거나 큰 따옴표를 사용할 수 있습니다:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment\['path/to/your/file.csv'\]
# or
bundle exec rake "gitlab_subscriptions:duo:bulk_user_assignment[path/to/your/file.csv]"
```

#### GitLab.com {#gitlabcom}

GitLab.com 관리자는 이 Rake 작업을 사용하여 해당 그룹에 사용 가능한 구매한 추가 기능을 기반으로 GitLab.com 그룹에 대한 GitLab Duo Pro 또는 Enterprise 사용자를 대량으로 할당할 수도 있습니다.

GitLab.com 그룹의 대량 사용자 할당을 수행하려면:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment DUO_BULK_USER_FILE_PATH=path/to/your/file.csv NAMESPACE_ID=<namespace_id>
```

파일 경로에서 대괄호를 사용하려면 대괄호를 이스케이프하거나 큰 따옴표를 사용할 수 있습니다:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment\['path/to/your/file.csv','<namespace_id>'\]
# or
bundle exec rake "gitlab_subscriptions:duo:bulk_user_assignment[path/to/your/file.csv,<namespace_id>]"
```

## 문제 해결 {#troubleshooting}

### 대량 사용자 할당 중 오류 {#errors-during-bulk-user-assignment}

대량 사용자 할당을 위한 Rake 작업을 사용할 때 다음 오류가 발생할 수 있습니다:

- `User is not found`:  지정된 사용자를 찾을 수 없습니다. 제공된 사용자 이름이 기존 사용자와 일치하는지 확인하세요.
- `ERROR_NO_SEATS_AVAILABLE`:  사용자 할당을 위해 더 이상 사용 가능한 사용자가 없습니다. [할당된 GitLab Duo 사용자 보기](../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users) 방법을 참조하여 현재 사용자 할당을 확인하세요.
- `ERROR_INVALID_USER_MEMBERSHIP`:  사용자가 비활성, 봇 또는 고스트 상태여서 할당 대상이 아닙니다. 사용자가 활성 상태이고, GitLab.com에 있는 경우 제공된 네임스페이스의 구성원인지 확인하세요.

## 관련 항목 {#related-topics}

- [사용자 비밀번호 재설정](../../security/reset_user_password.md#use-a-rake-task)
