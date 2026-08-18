---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 그룹 생성 및 사용자명 변경 같은 인스턴스 전체 사용자 설정을 구성합니다.
title: 전역 사용자 설정 수정
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab 인스턴스의 모든 사용자에 대한 설정을 수정할 수 있습니다.

전제 조건:

- 인스턴스의 관리자여야 합니다.

## 사용자가 최상위 그룹을 만들지 못하도록 방지 {#prevent-users-from-creating-top-level-groups}

사용자가 최상위 그룹을 만들지 못하도록 방지할 수 있습니다.

그룹 생성이 방지된 경우:

- 사용자는 최상위 그룹을 만들 수 없습니다.
- 사용자는 Maintainer 또는 Owner 역할이 있는 그룹에서 서브그룹을 만들 수 있으며, 이는 그룹에 대한 [서브그룹 생성 권한](../user/group/subgroups/_index.md#change-who-can-create-subgroups)에 따라 달라집니다.

사용자가 최상위 그룹을 만들지 못하도록 방지하려면 다음 방법 중 하나를 사용합니다:

| 방법        | 새 사용자의 경우                                                                                                         | 기존 사용자의 경우 |
| ------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------ |
| UI            | [계정 및 한도 설정](settings/account_and_limit_settings.md#prevent-new-users-from-creating-top-level-groups) | [관리자 영역의 사용자 설정](admin_area.md#prevent-a-user-from-creating-top-level-groups) |
| API           | [애플리케이션 설정 API](../api/settings.md#update-application-settings)를 사용하여 `can_create_group` 설정을 수정합니다   | [Users API](../api/users.md#modify-a-user)를 사용하여 `can_create_group` 설정을 수정합니다 |
| Rails console | 없음                                                                                                                  | [Rails console 사용](#use-the-rails-console) |

### Rails console 사용 {#use-the-rails-console}

Rails console을 사용하여 기존 사용자가 최상위 그룹을 만들지 못하도록 방지할 수 있습니다. 여러 사용자를 일괄 업데이트할 때 이 방법을 사용합니다.

기존 사용자가 최상위 그룹을 만들지 못하도록 방지하려면:

1. [Rails console 세션](operations/rails_console.md#starting-a-rails-console-session)을 시작합니다.
1. 다음 명령 중 하나를 실행합니다:

   - 관리자를 제외한 모든 기존 사용자에 대해 그룹 생성을 방지하려면:

     ```ruby
     User.where.not(admin: true).update_all(can_create_group: false)
     ```

   - 특정 사용자에 대해 그룹 생성을 방지하려면:

     ```ruby
     User.find_by(username: 'someuser').update(can_create_group: false)
     ```

1. console을 종료합니다:

   ```ruby
   exit
   ```

## 사용자가 사용자 이름을 변경하지 못하도록 방지 {#prevent-users-from-changing-their-usernames}

기본적으로 사용자는 사용자 이름을 변경할 수 있습니다. 사용자가 사용자 이름을 변경하지 못하도록 방지하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['gitlab_username_changing_enabled'] = false
   ```

1. [GitLab을 재구성하고 다시 시작합니다](restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. `config/gitlab.yml`을 편집하고 다음 줄의 주석을 제거합니다:

   ```yaml
   # username_changing_enabled: false # default: true - User can change their username/namespace
   ```

1. [GitLab을 다시 시작합니다](restart_gitlab.md#self-compiled-installations).

{{< /tab >}}

{{< /tabs >}}

## Guest 사용자가 더 높은 역할로 승격되지 못하도록 방지 {#prevent-guest-users-from-promoting-to-a-higher-role}

GitLab Ultimate에서 Guest 사용자는 유료 사용자에 포함되지 않습니다. 하지만 Guest 사용자가 프로젝트와 네임스페이스를 만들면 Guest보다 높은 역할로 자동으로 승격되어 유료 사용자를 차지합니다.

Guest 사용자가 더 높은 역할로 승격되어 유료 사용자를 차지하지 못하도록 방지하려면 사용자를 [외부 사용자](external_users.md)로 설정합니다.

외부 사용자는 개인 프로젝트나 네임스페이스를 만들 수 없습니다. Guest 역할을 가진 사용자가 다른 사용자에 의해 더 높은 역할로 승격된 경우, 외부 사용자 설정을 제거해야 개인 프로젝트나 네임스페이스를 만들 수 있습니다. 외부 사용자에 대한 제한 사항의 전체 목록은 [외부 사용자](external_users.md)를 참조합니다.
