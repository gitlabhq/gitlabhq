---
stage: GitLab Dedicated
group: Switchboard
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Switchboard를 사용하여 GitLab Dedicated 인스턴스를 구성합니다.
title: GitLab Dedicated 구성
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab Dedicated

{{< /details >}}

이 페이지의 지침은 [사용 가능한 기능](../../../subscriptions/gitlab_dedicated/_index.md#available-features)을 포함하여 GitLab Dedicated 인스턴스를 구성하고 설정을 활성화 및 업데이트하는 과정을 안내합니다.

관리자는 [**운영자** 영역](../../admin_area.md)을 사용하여 GitLab 애플리케이션에서 추가 설정을 구성할 수 있습니다.

하지만 GitLab Dedicated는 관리형 솔루션이므로 환경 수준 설정으로 제어되는 기능을 변경할 수 없습니다. `gitlab.rb` 구성과 셸, Rails 콘솔, PostgreSQL 콘솔에 대한 액세스가 포함됩니다.

GitLab Dedicated 엔지니어는 [긴급 상황](../../../subscriptions/gitlab_dedicated/_index.md#access-controls)을 제외하고 사용자 환경에 직접 액세스할 수 없습니다.

> [!note]
> 인스턴스는 GitLab Dedicated 배포를 지칭하는 반면, 테넌트는 고객을 지칭합니다.

## Switchboard를 사용하여 인스턴스 구성 {#configure-your-instance-using-switchboard}

Switchboard를 사용하여 GitLab Dedicated 인스턴스에 제한된 구성 변경을 수행할 수 있습니다.

Switchboard에서 사용 가능한 구성 설정은 다음과 같습니다:

- [IP 허용 목록](network_security.md#ip-allowlist)
- [SAML 설정](authentication/saml.md)
- [사용자 지정 인증서 기관](network_security.md#custom-certificate-authorities-for-external-services)
- [아웃바운드 PrivateLink 연결](network_security.md#outbound-privatelink-connections)
- [프라이빗 호스팅 영역](network_security.md#private-hosted-zones)

전제 조건:

- [운영자](users_notifications.md#add-switchboard-users) 역할이 필요합니다.

구성 변경을 수행하려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. 페이지 상단에서 **구성**을 선택합니다.
1. 아래의 관련 섹션에 있는 지침을 따릅니다.

다른 모든 인스턴스 구성의 경우 [구성 변경 요청 정책](_index.md#request-configuration-changes-with-a-support-ticket)에 따라 지원 티켓을 제출합니다.

### Switchboard에서 구성 변경 적용 {#apply-configuration-changes-in-switchboard}

Switchboard에서 수행한 구성 변경을 즉시 적용하거나 다음 예정된 주간 [유지 관리 기간](../maintenance.md#maintenance-windows)까지 연기할 수 있습니다.

변경 사항을 즉시 적용할 때:

- 배포에는 최대 90분이 소요될 수 있습니다.
- 변경 사항은 저장된 순서대로 적용됩니다.
- 여러 변경 사항을 저장하고 한 번에 적용할 수 있습니다.
- 배포 중에도 인스턴스를 사용할 수 있습니다.
- 프라이빗 호스팅 영역에 대한 변경 사항은 최대 5분 동안 종속 서비스를 방해할 수 있습니다.

배포가 완료된 후 테넌트를 보거나 편집할 수 있는 권한이 있는 모든 사용자는 각 변경 사항에 대한 알림을 받습니다. 알림을 켜거나 끄려면 [알림 설정 관리](users_notifications.md#manage-notification-settings)를 참조하세요.

## 구성 변경 로그 {#configuration-change-log}

Switchboard의 **Configuration change log** 페이지는 GitLab Dedicated 인스턴스에 대한 변경 사항을 추적합니다.

각 변경 로그 항목에는 다음 세부 정보가 포함됩니다:

| 필드                | 설명                                                                                                                                   |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| 구성 변경 | 변경된 구성 설정의 이름입니다.                                                                                               |
| 사용자                 | 구성 변경을 수행한 사용자의 이메일 주소입니다. GitLab 운영자가 수행한 변경 사항의 경우 이 값은 `GitLab Operator`로 표시됩니다. |
| IP                   | 구성 변경을 수행한 사용자의 IP 주소입니다. GitLab 운영자가 수행한 변경 사항의 경우 이 값은 `Unavailable`로 표시됩니다.        |
| 상태               | 구성 변경이 시작되었는지, 진행 중인지, 완료되었는지 또는 연기되었는지를 나타냅니다.                                                           |
| 시작 시간           | 구성 변경이 시작된 시작 날짜 및 시간(UTC)입니다.                                                                       |
| 종료 시간             | 구성 변경이 배포된 종료 날짜 및 시간(UTC)입니다.                                                                          |

각 구성 변경은 상태를 가집니다:

| 상태      | 설명 |
|-------------|-------------|
| 시작됨   | 구성 변경은 Switchboard에서 수행되었지만 아직 인스턴스에 배포되지 않았습니다. |
| 진행 중 | 구성 변경이 적극적으로 인스턴스에 배포되고 있습니다. |
| 완료    | 구성 변경이 인스턴스에 배포되었습니다. |
| 연기됨     | 변경 사항을 배포하기 위한 초기 작업이 실패했으며 변경 사항이 아직 새로운 작업에 할당되지 않았습니다. |

### 구성 변경 로그 보기 {#view-the-configuration-change-log}

구성 변경 로그를 보려면:

1. [Switchboard](https://console.gitlab-dedicated.com/)에 로그인합니다.
1. 페이지 상단에서 **Configuration change log**를 선택합니다.

각 구성 변경은 표의 항목으로 표시됩니다. **상세 보기**를 선택하여 각 변경 사항에 대한 자세한 정보를 확인합니다.

## 지원 티켓으로 구성 변경 요청 {#request-configuration-changes-with-a-support-ticket}

특정 구성 변경은 변경 사항을 요청하기 위해 지원 티켓을 제출해야 합니다. 지원 티켓을 만드는 방법에 대한 자세한 내용은 [티켓 만들기](https://about.gitlab.com/support/portal/#creating-a-ticket)를 참조하세요.

[지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)으로 요청한 구성 변경은 다음 정책을 준수합니다:

- 사용자 환경의 주간 4시간 유지 관리 기간 동안 적용됩니다.
- 온보딩 중에 지정한 옵션 또는 이 페이지에 나열된 선택적 기능에 대해 요청할 수 있습니다.
- GitLab이 높은 우선순위의 유지 관리 작업을 수행해야 하는 경우 다음 주로 연기될 수 있습니다.
- [긴급 지원](https://about.gitlab.com/support/#how-to-engage-emergency-support)에 해당하지 않는 한 주간 유지 관리 기간 외에는 적용할 수 없습니다.

> [!note]
> 변경 요청이 최소 대기 시간을 충족하더라도 예정된 유지 관리 기간 동안 적용되지 않을 수 있습니다.
