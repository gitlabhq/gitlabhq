---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: no
title: LDAP 동기화
description: 사용자 및 그룹에 대해 LDAP 동기화를 구성하는 방법을 알아보고 동기화 일정을 조정합니다.
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

[GitLab에서 작동하도록 LDAP를 구성한](_index.md) 경우 GitLab은 사용자 및 그룹을 자동으로 동기화할 수 있습니다.

LDAP 동기화는 LDAP 식별자가 할당된 기존 GitLab 사용자의 사용자 및 그룹 정보를 업데이트합니다. LDAP를 통해 새로운 GitLab 사용자를 생성하지 않습니다.

동기화가 발생하는 시점을 변경할 수 있습니다.

## 속도 제한이 있는 LDAP 서버 {#ldap-servers-with-rate-limits}

일부 LDAP 서버에는 속도 제한이 구성되어 있습니다.

GitLab은 다음 각각에 대해 LDAP 서버를 한 번 쿼리합니다:

- 예약된 [사용자 동기화](#user-sync) 프로세스 중 사용자
- 예약된 [그룹 동기화](#group-sync) 프로세스 중 그룹

경우에 따라 LDAP 서버에 더 많은 쿼리가 트리거될 수 있습니다. 예를 들어, [그룹 동기화 쿼리가 `memberuid` 속성을 반환](#queries)할 때

LDAP 서버에 속도 제한이 구성되어 있고 해당 제한에 도달하는 경우:

- 사용자 동기화 프로세스에서 LDAP 서버는 오류 코드로 응답하고 GitLab은 해당 사용자를 차단합니다.
- 그룹 동기화 프로세스에서 LDAP 서버는 오류 코드로 응답하고 GitLab은 해당 사용자의 그룹 멤버십을 제거합니다.

원치 않는 사용자 차단 및 그룹 멤버십 제거를 방지하기 위해 LDAP 동기화를 구성할 때 LDAP 서버의 속도 제한을 고려해야 합니다.

## 사용자 동기화 {#user-sync}

{{< history >}}

- LDAP 사용자의 프로필 이름 동기화 방지 GitLab 15.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/11336)됨

{{< /history >}}

하루에 한 번 GitLab은 GitLab 사용자를 확인하고 LDAP에 대해 업데이트하는 워커를 실행합니다.

이 프로세스는 다음 액세스 검사를 실행합니다:

- 사용자가 LDAP에 계속 존재하는지 확인합니다.
- LDAP 서버가 Active Directory인 경우 사용자가 활성화되어 있는지(차단/비활성화 상태가 아님) 확인합니다. 이 검사는 `active_directory: true`이 LDAP 구성에서 설정된 경우에만 수행됩니다.

Active Directory에서 사용자는 사용자 계정 제어 속성(`userAccountControl:1.2.840.113556.1.4.803`)의 비트 2가 설정된 경우 비활성화/차단된 것으로 표시됩니다.

<!-- vale gitlab_base.Spelling = NO -->

자세한 내용은 [LDAP의 비트마스크 검색](https://ctovswild.com/2009/09/03/bitmask-searches-in-ldap/)을 참조하세요.

<!-- vale gitlab_base.Spelling = YES -->

이 프로세스는 또한 다음 사용자 정보를 업데이트합니다:

- 이름 [동기화 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/342598) 때문에 `name`는 [**사용자가 프로필 이름을 변경하지 못하도록 방지**](../../settings/account_and_limit_settings.md#disable-user-profile-name-changes)가 활성화되어 있거나 `sync_name`이(가) `false`으로 설정된 경우 동기화되지 않습니다.
- 이메일 주소
- `sync_ssh_keys`이(가) 설정된 경우 SSH 공개 키
- Kerberos이 활성화된 경우 Kerberos 식별자

> [!note]
> LDAP 서버에 속도 제한이 있으면 사용자 동기화 프로세스 중에 해당 제한에 도달할 수 있습니다. [속도 제한 설명서](#ldap-servers-with-rate-limits)에서 자세한 내용을 확인하세요.

### LDAP 사용자의 프로필 이름 동기화 {#synchronize-ldap-users-profile-name}

기본적으로 GitLab은 LDAP 사용자의 프로필 이름 필드를 동기화합니다.

이 동기화를 방지하려면 `sync_name`을(를) `false`으로 설정할 수 있습니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'sync_name' => false,
       }
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             sync_name: false
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'sync_name' => false,
               }
           }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           sync_name: false
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### 차단된 사용자 {#blocked-users}

다음 중 하나인 경우 사용자가 차단됩니다:

- [액세스 검사 실패](#user-sync)이고 해당 사용자가 GitLab에서 `ldap_blocked` 상태로 설정됩니다.
- LDAP 서버는 해당 사용자가 로그인할 때 사용할 수 없습니다.

사용자가 차단되면 해당 사용자는 로그인하거나 코드를 푸시 또는 풀 할 수 없습니다.

차단된 사용자는 다음 모두가 참이면 LDAP로 로그인할 때 차단이 해제됩니다:

- 모든 액세스 검사 조건이 참입니다.
- LDAP 서버는 사용자가 로그인할 때 사용 가능합니다.

**모든 사용자**는 LDAP 사용자 동기화가 실행될 때 LDAP 서버를 사용할 수 없으면 차단됩니다.

> [!note]
> LDAP 사용자 동기화가 실행될 때 LDAP 서버를 사용할 수 없어서 모든 사용자가 차단되면 이후의 LDAP 사용자 동기화는 해당 사용자를 자동으로 차단 해제하지 않습니다.

## 그룹 동기화 {#group-sync}

LDAP가 `memberof` 속성을 지원하는 경우 사용자가 처음 로그인할 때 GitLab은 사용자가 멤버여야 하는 그룹에 대한 동기화를 트리거합니다. 이렇게 하면 사용자가 시간별 동기화를 기다릴 필요 없이 자신의 그룹 및 프로젝트에 액세스할 수 있습니다.

그룹 동기화 프로세스는 시간마다 정각에 실행되며, `group_base`은(는) 그룹 CN을 기반으로 한 LDAP 동기화가 작동하도록 LDAP 구성에서 설정되어야 합니다. 이를 통해 GitLab 그룹 멤버십을 LDAP 그룹 멤버를 기반으로 자동으로 업데이트할 수 있습니다.

`group_base` 구성은 GitLab에서 사용할 수 있어야 하는 LDAP 그룹을 포함하는 '조직' 또는 '조직 단위'와 같은 기본 LDAP '컨테이너'여야 합니다. 예를 들어 `group_base`은(는) `ou=groups,dc=example,dc=com`일 수 있습니다. 구성 파일에서는 다음과 같이 표시됩니다.

> [!note]
> LDAP 서버에 속도 제한이 있으면 그룹 동기화 프로세스 중에 해당 제한에 도달할 수 있습니다. [속도 제한 설명서](#ldap-servers-with-rate-limits)에서 자세한 내용을 확인하세요.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'group_base' => 'ou=groups,dc=example,dc=com',
       }
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             group_base: ou=groups,dc=example,dc=com
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'group_base' => 'ou=groups,dc=example,dc=com',
               }
           }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           group_base: ou=groups,dc=example,dc=com
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

그룹 동기화를 활용하려면 그룹 소유자 또는 [Maintainer 역할](../../../user/permissions.md) 을 가진 사용자는 [하나 이상의 LDAP 그룹 링크를 생성](../../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap)해야 합니다.

> [!note]
> LDAP 서버와 GitLab 인스턴스 간의 연결 이슈를 자주 경험하는 경우 기본값인 1시간보다 그룹 동기화 워커 간격을 더 크게 설정하여 GitLab에서 LDAP 그룹 동기화를 수행하는 빈도를 줄이세요.

### 그룹 링크 추가 {#add-group-links}

CN 및 필터를 사용하여 그룹 링크를 추가하는 방법에 대한 자세한 내용은 [GitLab 그룹 설명서](../../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap)를 참조하세요.

### LDAP 그룹에 운영자 역할 할당 {#assign-an-admin-role-to-an-ldap-group}

그룹 동기화의 확장으로 전역 GitLab 운영자를 자동으로 관리할 수 있습니다. `admin_group`에 그룹 CN을 지정하면 LDAP 그룹의 모든 멤버에게 운영자 권한이 부여됩니다. 구성은 다음과 같이 표시됩니다.

> [!note]
> 운영자는 `group_base`이(가) `admin_group`과(와) 함께 지정되지 않으면 동기화되지 않습니다. 또한 전체 DN이 아닌 `admin_group`의 CN만 지정하세요. 또한 LDAP 사용자에게 `admin` 역할이 있지만 `admin_group` 그룹의 멤버가 아닌 경우 동기화 시 GitLab은 해당 사용자의 `admin` 역할을 취소합니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'group_base' => 'ou=groups,dc=example,dc=com',
       'admin_group' => 'my_admin_group',
       }
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             group_base: ou=groups,dc=example,dc=com
             admin_group: my_admin_group
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'group_base' => 'ou=groups,dc=example,dc=com',
               'admin_group' => 'my_admin_group',
               }
           }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           group_base: ou=groups,dc=example,dc=com
           admin_group: my_admin_group
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### LDAP 그룹에 사용자 지정 역할 할당 {#assign-a-custom-admin-role-to-an-ldap-group}

{{< details >}}

- 계층:  Ultimate

{{< /details >}}

외부 LDAP 그룹에서 동기화된 모든 사용자에게 사용자 지정 역할을 할당할 수 있습니다. 이 옵션은 SAML 그룹에는 사용할 수 없습니다.

사용자가 다양한 할당된 사용자 지정 역할을 가진 여러 LDAP 그룹에 속하는 경우 GitLab은 먼저 연결된 LDAP 그룹과 연결된 역할을 할당합니다.

> [!note]
> 사용자 지정 역할을 가진 LDAP 사용자가 동기화를 구성한 후 LDAP 그룹에서 제거되면 다음 동기화까지 사용자 지정 역할이 제거되지 않습니다.

전제 조건:

- 인스턴스와 통합된 LDAP 서버
- 운영자 액세스

{{< tabs >}}

{{< tab title="LDAP CN으로 할당" >}}

LDAP CN을 사용하여 사용자 지정 역할을 할당하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **역할 및 권한**을 선택합니다.
1. **LDAP 동기화** 탭에서 **LDAP Server**를 선택합니다.
1. **동기화 방법** 필드에서 `Group cn`을(를) 선택합니다.
1. **그룹 cn** 필드에 그룹의 CN을 입력하기 시작합니다. 구성된 `group_base`에서 일치하는 CN이 포함된 드롭다운 목록이 나타납니다.
1. 드롭다운 목록에서 CN을 선택합니다.
1. **사용자 정의 운영자 역할** 필드에서 사용자 지정 역할을 선택합니다.
1. **추가**를 선택합니다.

GitLab은 일치하는 LDAP 사용자에게 역할을 연결하기 시작합니다. 이 프로세스는 1시간 이상 걸릴 수 있습니다.

{{< /tab >}}

{{< tab title="LDAP 필터로 할당" >}}

LDAP 필터를 사용하여 사용자 지정 역할을 할당하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **역할 및 권한**을 선택합니다.
1. **LDAP 동기화** 탭에서 **LDAP Server**를 선택합니다.
1. **동기화 방법** 필드에서 `User filter`을(를) 선택합니다.
1. **사용자 필터** 텍스트 상자에 필터를 입력합니다. 자세한 내용은 [LDAP 사용자 필터 설정](_index.md#set-up-ldap-user-filter)을 참조하세요.
1. **사용자 정의 운영자 역할** 필드에서 사용자 지정 역할을 선택합니다.
1. **추가**를 선택합니다.

GitLab은 일치하는 LDAP 사용자에게 역할을 연결하기 시작합니다. 이 프로세스는 1시간 이상 걸릴 수 있습니다.

{{< /tab >}}

{{< /tabs >}}

### 전역 LDAP 그룹 멤버십 잠금 {#global-ldap-group-memberships-lock}

GitLab 운영자는 LDAP와 동기화된 멤버십을 가진 하위 그룹에 새 멤버를 초대하는 것을 그룹 멤버가 방지할 수 있습니다.

전역 그룹 멤버십 잠금은 LDAP 동기화가 구성된 최상위 그룹의 하위 그룹에만 적용됩니다. 어떤 사용자도 LDAP 동기화에 대해 구성된 최상위 그룹의 멤버십을 수정할 수 없습니다.

전역 그룹 멤버십 잠금이 활성화된 경우:

- 그룹 또는 하위 그룹을 코드 소유자로 설정할 수 없습니다. 자세한 내용은 [전역 그룹 멤버십 잠금과의 비호환성](../../../user/project/codeowners/troubleshooting.md#incompatibility-with-global-group-memberships-locks)을 참조하세요.
- 운영자만 액세스 수준을 포함하여 모든 그룹의 멤버십을 관리할 수 있습니다.
- 사용자는 다른 그룹과 프로젝트를 공유하거나 그룹에서 생성한 프로젝트에 멤버를 초대할 수 없습니다.

전역 그룹 멤버십 잠금을 활성화하려면:

1. [LDAP 구성](_index.md#configure-ldap)
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **LDAP 동기화에 대한 멤버쉽 잠금** 확인란이 선택되었는지 확인합니다.

### LDAP 그룹 동기화 설정 관리 변경 {#change-ldap-group-synchronization-settings-management}

기본적으로 소유자 역할을 가진 그룹 멤버는 [LDAP 그룹 동기화 설정](../../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap)을 관리할 수 있습니다.

GitLab 운영자는 그룹 소유자로부터 이 권한을 제거할 수 있습니다:

1. [LDAP 구성](_index.md#configure-ldap)
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **공개 범위 및 액세스 설정**을 확장합니다.
1. **그룹 소유자가 LDAP 관련 설정을 관리하도록 허용** 확인란이 선택되지 않았는지 확인합니다.

**그룹 소유자가 LDAP 관련 설정을 관리하도록 허용**이(가) 비활성화된 경우:

- 그룹 소유자는 최상위 그룹 및 하위 그룹에 대한 LDAP 동기화 설정을 변경할 수 없습니다.
- 인스턴스 운영자는 인스턴스의 모든 그룹에 대한 LDAP 그룹 동기화 설정을 관리할 수 있습니다.

### 외부 그룹 {#external-groups}

`external_groups` 설정을 사용하면 이러한 그룹에 속하는 모든 사용자를 [외부 사용자](../../external_users.md)로 표시할 수 있습니다. 그룹 멤버십은 `LdapGroupSync` 백그라운드 작업을 통해 주기적으로 확인됩니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'external_groups' => ['interns', 'contractors'],
       }
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             external_groups: ['interns', 'contractors']
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
               'external_groups' => ['interns', 'contractors'],
             }
           }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           external_groups: ['interns', 'contractors']
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### 그룹용 GitLab Duo 추가 기능 {#gitlab-duo-add-on-for-groups}

`duo_add_on_groups` 설정은 LDAP를 통해 인증하는 사용자에 대해 [GitLab Duo 추가 기능 사용자 관리](../../duo_add_on_seat_management_with_ldap.md)를 자동으로 수행합니다. 이 기능은 조직이 LDAP 그룹 멤버십에 따라 **GitLab Duo** 사용자 할당 프로세스를 간소화하는 데 도움이 됩니다.

GitLab Duo 사용자 동기화는 두 가지 방식으로 발생합니다:

- **On user sign-in**:  사용자가 LDAP를 통해 로그인하면 GitLab은 즉시 해당 사용자의 그룹 멤버십을 확인합니다.
- **Scheduled sync**:  GitLab은 모든 LDAP 사용자를 매일 오전 02:00(서버 시간)에 자동으로 동기화하여 사용자 로그인이 없어도 사용자 할당이 최신 상태로 유지되도록 합니다.

그룹에 대한 추가 기능 사용자 관리를 활성화하려면 GitLab 인스턴스에서 `duo_add_on_groups` 설정을 구성해야 합니다:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_servers'] = {
     'main' => {
       'duo_add_on_groups' => ['duo_group_1', 'duo_group_2'],
       }
   }
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       ldap:
         servers:
           main:
             duo_add_on_groups: ['duo_group_1', 'duo_group_2']
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_servers'] = {
             'main' => {
                 'duo_add_on_groups' => ['duo_group_1', 'duo_group_2'],
             }
           }
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ldap:
       servers:
         main:
           duo_add_on_groups: ['duo_group_1', 'duo_group_2']
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### 그룹 동기화 기술 세부 사항 {#group-sync-technical-details}

이 섹션에서는 실행되는 LDAP 쿼리 및 그룹 동기화에서 예상할 수 있는 동작을 설명합니다.

사용자의 LDAP 그룹 멤버십이 변경되면 해당 사용자의 그룹 액세스 수준이 다운그레이드될 수 있습니다. 예를 들어 사용자가 그룹에서 소유자 역할을 가지고 있고 다음 그룹 동기화에서 해당 사용자가 개발자 역할만 가져야 함을 알 수 있으면 액세스가 그에 따라 조정됩니다. 유일한 예외는 사용자가 그룹의 마지막 소유자인 경우입니다. 그룹은 관리 업무를 수행하기 위해 최소 한 명의 소유자가 필요합니다.

#### 최소 액세스 역할 할당 제한된 액세스 {#minimal-access-role-assignment-with-restricted-access}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206932) GitLab 18.6 [플래그 포함](../../feature_flags/_index.md) `bso_minimal_access_fallback` 기본적으로 비활성화됨.
- [기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225777) GitLab 18.10

{{< /history >}}

[제한된 액세스](../../../user/group/manage.md#restricted-access)가 활성화되고 구독 사용자가 없으면 LDAP 그룹 동기화 중에 사용자에게 최소 액세스 역할이 할당됩니다.

자세한 내용은 [SAML, SCIM 및 LDAP를 사용한 프로비저닝 동작](../../../user/group/manage.md#provisioning-behavior-with-saml-scim-and-ldap)을 참조하세요.

#### 지원되는 LDAP 그룹 유형/속성 {#supported-ldap-group-typesattributes}

GitLab은 멤버 속성을 사용하는 LDAP 그룹을 지원합니다:

- `member`
- `submember`
- `uniquemember`
- `memberof`
- `memberuid`

이는 그룹 동기화가 다음 객체 클래스를 사용하는 (최소한) LDAP 그룹을 지원함을 의미합니다:

- `groupOfNames`
- `posixGroup`
- `groupOfUniqueNames`

멤버가 언급된 속성 중 하나로 정의된 경우 다른 객체 클래스도 작동해야 합니다.

Active Directory는 중첩 그룹을 지원합니다. 구성 파일에서 `active_directory: true`이(가) 설정되면 그룹 동기화는 멤버십을 재귀적으로 확인합니다.

##### 중첩 그룹 멤버십 {#nested-group-memberships}

중첩 그룹 멤버십은 중첩 그룹이 구성된 `group_base`에서 발견된 경우에만 확인됩니다. 예를 들어 GitLab이 DN `cn=nested_group,ou=special_groups,dc=example,dc=com`을(를) 사용하는 중첩 그룹을 표시하지만 구성된 `group_base`이(가) `ou=groups,dc=example,dc=com`인 경우 `cn=nested_group`은(는) 무시됩니다.

#### 쿼리 {#queries}

- 각 LDAP 그룹은 base `group_base` 및 filter `(cn=<cn_from_group_link>)`으로 최대 한 번 쿼리됩니다.
- LDAP 그룹에 `memberuid` 속성이 있으면 GitLab은 각 멤버당 하나의 추가 LDAP 쿼리를 실행하여 각 사용자의 전체 DN을 가져옵니다. 이러한 쿼리는 base `base`, scope `baseObject` 및 `user_filter`이(가) 설정되었는지 여부에 따라 달라지는 필터로 실행됩니다. 필터는 `(uid=<uid_from_group>)` 또는 `user_filter`의 조합일 수 있습니다.

#### 벤치마크 {#benchmarks}

그룹 동기화는 가능한 한 성능이 우수하도록 작성되었습니다. 데이터는 캐시되고 데이터베이스 쿼리는 최적화되며 LDAP 쿼리는 최소화됩니다. 마지막 벤치마크 실행은 다음 메트릭을 공개했습니다:

20,000 LDAP 사용자, 11,000 LDAP 그룹 및 각각 10개의 LDAP 그룹 링크가 있는 1,000 GitLab 그룹의 경우:

- 초기 동기화(GitLab에 할당된 기존 멤버 없음)는 1.8시간이 소요됨
- 후속 동기화(멤버십 확인, 쓰기 없음)는 15분 소요

이러한 메트릭은 기준선을 제공하기 위한 것이며 여러 요인에 따라 성능이 달라질 수 있습니다. 이 벤치마크는 극단적이었으며 대부분의 인스턴스는 이 정도의 사용자 또는 그룹을 갖지 않습니다. 디스크 속도, 데이터베이스 성능, 네트워크 및 LDAP 서버 응답 시간이 이러한 메트릭에 영향을 미칩니다.

## LDAP 동기화 일정 조정 {#adjust-ldap-sync-schedule}

LDAP가 사용자, 그룹 및 GitLab Duo 추가 기능 사용자를 동기화하는 시간과 간격을 변경할 수 있습니다.

### 사용자의 경우 {#for-users}

기본적으로 GitLab은 매일 오전 1시 30분(서버 시간)에 워커를 실행하여 GitLab 사용자를 확인하고 LDAP에 대해 업데이트합니다.

> [!warning]
> 동기화 프로세스를 너무 자주 실행하지 마세요. 이는 동기화가 동시에 여러 개 실행되는 것으로 이어질 수 있습니다. 대부분의 설치에서는 동기화 일정을 수정할 필요가 없습니다. 자세한 내용은 [LDAP 보안 설명서](_index.md#security)를 참조하세요.

cron 형식으로 다음 구성 값을 설정하여 LDAP 사용자 동기화 시간을 수동으로 구성할 수 있습니다. 필요한 경우 [crontab 생성기](https://it-tools.tech/crontab-generator)를 사용할 수 있습니다. 아래 예는 LDAP 사용자 동기화를 12시간마다 시간 정각에 실행하도록 설정하는 방법을 보여줍니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       cron_jobs:
         ldap_sync_worker:
           cron: "0 */12 * * *"
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ee_cron_jobs:
       ldap_sync_worker:
         cron: "0 */12 * * *"
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### 그룹의 경우 {#for-groups}

기본적으로 GitLab은 시간마다 정각에 그룹 동기화 프로세스를 실행합니다. 표시된 값은 cron 형식입니다. 필요한 경우 [crontab 생성기](https://it-tools.tech/crontab-generator)를 사용할 수 있습니다.

> [!warning]
> 동기화 프로세스를 너무 자주 시작하지 마세요. 이는 동기화가 동시에 여러 개 실행되는 것으로 이어질 수 있습니다. 대부분의 설치에서는 동기화 일정을 수정할 필요가 없습니다.

다음 구성 값을 설정하여 LDAP 그룹 동기화 시간을 수동으로 구성할 수 있습니다. 아래 예는 그룹 동기화를 2시간마다 시간 정각에 실행하도록 설정하는 방법을 보여줍니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_group_sync_worker_cron'] = "0 */2 * * *"
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       cron_jobs:
         ldap_group_sync_worker:
           cron: "*/30 * * * *"
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_group_sync_worker_cron'] = "0 */2 * * *"
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ee_cron_jobs:
       ldap_group_sync_worker:
         cron: "*/30 * * * *"
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### GitLab Duo 추가 기능 사용자의 경우 {#for-gitlab-duo-add-on-seats}

기본적으로 GitLab은 GitLab Duo 추가 기능 사용자 동기화 프로세스를 매일 오전 2시 00분(서버 시간)에 실행하여 LDAP 그룹 멤버십을 확인하고 GitLab Duo 추가 기능 사용자를 할당하거나 제거합니다.

> [!warning]
> 동기화 프로세스를 너무 자주 시작하지 마세요. 이는 동기화가 동시에 여러 개 실행되는 것으로 이어질 수 있습니다. 대부분의 설치에서는 동기화 일정을 수정할 필요가 없습니다.

구성 값을 설정하여 LDAP GitLab Duo 추가 기능 사용자 동기화 시간을 수동으로 구성할 수 있습니다. 다음 예는 동기화를 4시간마다 실행하도록 설정하는 방법을 보여줍니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['ldap_add_on_seat_sync_worker_cron'] = "0 */4 * * *"
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을(를) 편집합니다:

   ```yaml
   global:
     appConfig:
       cron_jobs:
         ldap_add_on_seat_sync_worker:
           cron: "0 */4 * * *"
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['ldap_add_on_seat_sync_worker_cron'] = "0 */4 * * *"
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을(를) 편집합니다:

   ```yaml
   production: &base
     ee_cron_jobs:
       ldap_add_on_seat_sync_worker:
         cron: "0 */4 * * *"
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}
