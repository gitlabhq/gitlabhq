---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 유지보수 모드
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

유지보수 모드를 사용하면 관리자가 유지보수 작업을 수행하는 동안 쓰기 작업을 최소화할 수 있습니다. 주요 목표는 내부 상태를 변경하는 모든 외부 작업을 차단하는 것입니다. 내부 상태에는 PostgreSQL 데이터베이스가 포함되지만, 특히 파일, Git 리포지토리 및 컨테이너 레지스트리가 포함됩니다.

유지보수 모드가 활성화되면 새로운 작업이 들어오지 않고 내부 상태 변경이 최소화되므로 진행 중인 작업이 상대적으로 빠르게 완료됩니다. 이 상태에서는 다양한 유지보수 작업이 더 쉬워집니다. 서비스를 완전히 중지하거나 필요한 것보다 더 짧은 시간 동안 성능을 저하시킬 수 있습니다. 예를 들어, cron 작업을 중지하고 큐를 비우는 것이 상대적으로 빨라야 합니다.

유지보수 모드는 내부 상태를 변경하지 않는 대부분의 외부 작업을 허용합니다. 개략적으로 HTTP `POST`, `PUT`, `PATCH` 및 `DELETE` 요청이 차단되며, [특수한 경우가 처리되는 방식](#rest-api)에 대한 자세한 개요를 확인할 수 있습니다.

## 유지보수 모드 활성화 {#enable-maintenance-mode}

관리자는 다음 방법 중 하나로 유지보수 모드를 활성화할 수 있습니다:

- **웹 UI**:
  1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
  1. 왼쪽 사이드바에서 **설정** > **일반**을(를) 선택합니다.
  1. **Maintenance Mode**를 펼치고 **Enable Maintenance Mode**를 토글합니다. 필요에 따라 배너에 메시지를 추가할 수 있습니다.
  1. **변경 사항 저장**을 선택합니다.

- **API**:

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?maintenance_mode=true"
  ```

## 유지보수 모드 비활성화 {#disable-maintenance-mode}

다음 세 가지 방법 중 하나로 유지보수 모드를 비활성화합니다:

- **웹 UI**:
  1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
  1. 왼쪽 사이드바에서 **설정** > **일반**을(를) 선택합니다.
  1. **Maintenance Mode**를 펼치고 **Enable Maintenance Mode**를 토글합니다. 필요에 따라 배너에 메시지를 추가할 수 있습니다.
  1. **변경 사항 저장**을 선택합니다.

- **API**:

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?maintenance_mode=false"
  ```

## 유지보수 모드에서 GitLab 기능의 동작 {#behavior-of-gitlab-features-in-maintenance-mode}

유지보수 모드가 활성화되면 페이지 상단에 배너가 표시됩니다. 배너는 특정 메시지로 사용자 지정할 수 있습니다.

사용자가 허용되지 않는 쓰기 작업을 수행하려고 하면 오류가 표시됩니다.

![유지보수 모드 배너 및 오류 메시지](img/maintenance_mode_error_message_v17_6.png)

> [!note]
> 경우에 따라 작업의 시각적 피드백이 오도할 수 있습니다. 예를 들어 프로젝트에 **별표**를 표시할 때 **별표 해제** 작업을 표시하도록 버튼이 변경됩니다. 그러나 이는 UI만 업데이트하고 POST 요청의 상태를 고려하지 않습니다.

### 관리자 기능 {#administrator-functions}

시스템 관리자는 애플리케이션 설정을 편집할 수 있습니다. 이를 통해 유지보수 모드가 활성화된 후 비활성화할 수 있습니다.

### 인증 {#authentication}

모든 사용자는 GitLab 인스턴스에 로그인하고 로그아웃할 수 있지만 새로운 사용자는 만들 수 없습니다.

해당 시간에 [LDAP 동기화](../auth/ldap/_index.md)가 예약되어 있으면 사용자 생성이 비활성화되어 실패합니다. 마찬가지로 [SAML 기반 사용자 생성](../../integration/saml.md#configure-saml-support-in-gitlab)은 실패합니다.

### Git 작업 {#git-actions}

모든 읽기 전용 Git 작업은 계속 작동합니다. 예를 들어 `git clone` 및 `git pull`입니다. 모든 쓰기 작업은 CLI 및 웹 IDE를 통해 실패하며 오류 메시지가 표시됩니다: `Git push is not allowed because this GitLab instance is currently in (read-only) maintenance mode.`

Geo가 활성화되면 주 서버와 보조 서버 모두에 대한 Git 푸시가 실패합니다.

### 머지 리퀘스트, 이슈, 에픽 {#merge-requests-issues-epics}

이전에 언급된 것을 제외한 모든 쓰기 작업이 실패합니다. 예를 들어 사용자는 머지 리퀘스트 또는 이슈를 업데이트할 수 없습니다.

### 들어오는 이메일 {#incoming-email}

새로운 이슈 답변, 이슈 (새로운 Service Desk 이슈 포함), 머지 리퀘스트를 [이메일로](../incoming_email.md) 생성하는 작업이 실패합니다.

### 나가는 이메일 {#outgoing-email}

알림 이메일은 계속 도착하지만, 비밀번호 재설정과 같이 데이터베이스 쓰기가 필요한 이메일은 도착하지 않습니다.

### REST API {#rest-api}

대부분의 JSON 요청의 경우 `POST`, `PUT`, `PATCH` 및 `DELETE`가 차단되며, API는 `503` 응답을 반환하고 오류 메시지는 `GitLab Maintenance: system is in maintenance mode`입니다. 다음 요청만 허용됩니다:

|HTTP 요청 | 허용된 경로 |  참고 |
|:----:|:--------------------------------------:|:----:|
| `POST` | `/admin/application_settings/general` | 관리자 UI에서 애플리케이션 설정을 업데이트할 수 있도록 합니다 |
| `PUT`  | `/api/v4/application/settings` | API를 통해 애플리케이션 설정을 업데이트할 수 있도록 합니다 |
| `POST` | `/users/sign_in` | 사용자가 로그인할 수 있도록 합니다. |
| `POST` | `/users/sign_out`| 사용자가 로그아웃할 수 있도록 합니다. |
| `POST` | `/oauth/token` | 사용자가 처음으로 Geo 보조 서버에 로그인할 수 있도록 합니다. |
| `POST` | `/admin/session`, `/admin/session/destroy` | [GitLab 관리자를 위한 관리자 모드](https://gitlab.com/groups/gitlab-org/-/epics/2158)를 허용합니다 |
| `POST` | `/compare`로 끝나는 경로| Git 리비전 경로입니다. |
| `POST` | `.git/git-upload-pack` | Git 풀/클론을 허용합니다. |
| `POST` | `/api/v4/internal` | 내부 API 경로 |
| `POST` | `/admin/sidekiq` | **운영자** 영역에서 백그라운드 작업 관리를 허용합니다 |
| `POST` | `/admin/geo` | 관리자 UI에서 Geo 노드를 업데이트할 수 있도록 합니다 |
| `POST` | `/api/v4/geo_replication`| 보조 사이트에서 특정 Geo 관련 관리자 UI 작업을 허용합니다 |

### GraphQL API {#graphql-api}

{{< history >}}

- `GeoRegistriesUpdate` 뮤테이션 추가가 허용 목록에 GitLab 16.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124259)되었습니다.

{{< /history >}}

`POST /api/graphql` 요청은 허용되지만 뮤테이션은 오류 메시지 `You cannot perform write operations on a read-only instance`로 차단됩니다.

허용되는 유일한 뮤테이션은 `GeoRegistriesUpdate`으로, 레지스트리를 다시 동기화하고 재검증하는 데 사용됩니다.

### 지속적 통합 {#continuous-integration}

- 새로운 작업 또는 파이프라인이 시작되지 않습니다. 예약되었거나 그렇지 않습니다.
- 이미 실행 중인 작업은 GitLab 러너에서 실행을 완료해도 GitLab UI에서 `running` 상태를 계속 유지합니다.
- `running` 상태의 작업이 프로젝트의 시간 제한보다 오래 지속되면 시간 초과되지 않습니다.
- 파이프라인을 시작하거나 다시 시도하거나 취소할 수 없습니다. 새로운 작업도 생성할 수 없습니다.
- `/admin/runners`의 러너 상태가 업데이트되지 않습니다.
- `gitlab-runner verify`은 오류 `ERROR: Verifying runner... is removed`를 반환합니다.

유지보수 모드가 비활성화되면 새로운 작업이 다시 수집됩니다. 유지보수 모드를 활성화하기 전에 `running` 상태였던 작업이 재개되고 로그 업데이트가 다시 시작됩니다.

> [!note]
> 유지보수 모드를 해제한 후 이전 `running` 파이프라인을 다시 시작해야 합니다.

### 배포 {#deployments}

파이프라인이 완료되지 않아서 배포가 진행되지 않습니다.

유지보수 모드 중에 자동 배포를 비활성화하고 비활성화될 때 활성화해야 합니다.

#### Terraform 통합 {#terraform-integration}

Terraform 통합은 CI 파이프라인을 실행하는 것에 따라 달라지므로 차단됩니다.

### 컨테이너 레지스트리 {#container-registry}

`docker push`은 이 오류로 실패합니다: `denied: requested access to the resource is denied`, 그러나 `docker pull`는 작동합니다.

### 패키지 레지스트리 {#package-registry}

패키지 레지스트리를 통해 패키지를 설치할 수 있지만 발행할 수는 없습니다.

### 백그라운드 작업 {#background-jobs}

백그라운드 작업 (cron 작업, Sidekiq)은 백그라운드 작업이 자동으로 비활성화되지 않으므로 그대로 계속 실행됩니다. 백그라운드 작업이 인스턴스의 내부 상태를 변경할 수 있는 작업을 수행하므로, 유지보수 모드가 활성화된 동안 일부 또는 전체를 비활성화할 수 있습니다.

[계획된 Geo 장애 조치 중에](../geo/disaster_recovery/planned_failover.md#prevent-updates-to-the-primary-site) Geo 관련 작업을 제외한 모든 cron 작업을 비활성화해야 합니다.

큐를 모니터링하고 작업을 비활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **모니터링** > **백그라운드 작업**을 선택합니다.
1. Sidekiq 대시보드에서 **Cron**을 선택하고 **Disable All**를 선택하여 작업을 개별적으로 또는 한 번에 비활성화합니다.

### 인시던트 관리 {#incident-management}

[인시던트 관리](../../operations/incident_management/_index.md) 기능은 제한됩니다. [경고](../../operations/incident_management/alerts.md) 및 [인시던트](../../operations/incident_management/manage_incidents.md#create-an-incident) 생성이 완전히 일시 중지됩니다. 따라서 경고 및 인시던트에 대한 알림과 페이징이 비활성화됩니다.

### 기능 플래그 {#feature-flags}

- 개발 기능 플래그는 API를 통해 켜거나 끌 수 없지만 Rails 콘솔을 통해 토글할 수 있습니다.
- [기능 플래그 서비스](../../operations/feature_flags.md)는 기능 플래그 확인에 응답하지만 기능 플래그를 토글할 수 없습니다

### Geo 보조 {#geo-secondaries}

주 서버가 유지보수 모드에 있으면 보조 서버도 자동으로 유지보수 모드로 전환됩니다.

유지보수 모드를 활성화하기 전에 복제를 비활성화하지 않는 것이 중요합니다.

복제, 검증 및 관리자 UI를 통한 레지스트리 재동기화 및 재검증을 위한 수동 작업은 계속 작동하지만 주 서버로의 프록시된 Git 푸시는 작동하지 않습니다.

### 보안 기능 {#secure-features}

이슈 생성 또는 머지 리퀘스트 생성 또는 승인에 따라 달라지는 기능은 작동하지 않습니다.

취약성 보고서 페이지에서 취약성 목록을 내보내기가 작동하지 않습니다.

UI에 오류가 표시되지 않더라도 검색 결과 또는 취약성 개체의 상태를 변경하는 것은 작동하지 않습니다.

SAST 및 시크릿 검색은 아티팩트를 생성하기 위해 CI/CD 작업을 전달하는 것에 따라 달라지므로 시작할 수 없습니다.

## 사용 사례 예: 계획된 장애 조치 {#an-example-use-case-a-planned-failover}

[계획된 장애 조치](../geo/disaster_recovery/planned_failover.md)의 사용 사례에서 주 데이터베이스에 몇 가지 쓰기는 허용되는데, 이는 빠르게 복제되고 수에 있어 중요하지 않기 때문입니다.

같은 이유로 유지보수 모드가 활성화될 때 백그라운드 작업을 자동으로 차단하지 않습니다.

결과 데이터베이스 쓰기는 허용됩니다. 여기서 트레이드오프는 더 많은 서비스 성능 저하와 복제 완료 사이입니다.

그러나 계획된 장애 조치 중에 [사용자에게 Geo와 관련이 없는 cron 작업을 수동으로 해제하도록 요청](../geo/disaster_recovery/planned_failover.md#prevent-updates-to-the-primary-site)합니다. 새로운 데이터베이스 쓰기 및 Geo가 아닌 cron 작업이 없으면 새로운 백그라운드 작업은 생성되지 않거나 최소한으로 생성됩니다.
