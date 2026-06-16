---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 무음 모드
description: GitLab의 아웃바운드 통신을 음소거합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.11에서 [도입되었습니다](https://gitlab.com/groups/gitlab-org/-/epics/9826). 이 기능은 [실험](../../policy/development_stages_support.md#experiment)이었습니다.
- 웹 UI를 통한 무음 모드 활성화 및 비활성화는 GitLab 16.4에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131090).
- GitLab 16.6에서 [일반적으로 사용 가능](../../policy/development_stages_support.md#generally-available)합니다.

{{< /history >}}

무음 모드를 사용하면 GitLab의 이메일 등 아웃바운드 통신을 음소거할 수 있습니다. 무음 모드는 사용 중인 환경에서 사용하도록 의도되지 않았습니다.

## 무음 모드를 사용해야 하는 경우 {#when-to-use-silent-mode}

무음 모드는 특정 테스트 및 검증 시나리오를 위해 설계되었으며 프로덕션 환경용 범용 기능으로 사용하면 안 됩니다.

무음 모드는 다음 시나리오용으로 설계되었습니다:

- Geo 사이트 프로모션 테스트:  주 사이트가 활성 상태로 유지되는 동안 보조 Geo 사이트를 프로모션하여 재해 복구 절차를 검증할 때입니다.
  - 예를 들어, [재해 복구](../geo/disaster_recovery/_index.md) 솔루션의 일부로 보조 Geo 사이트가 있다고 가정합니다. 재해 복구 계획이 실제로 작동하도록 보장하기 위해 보조 Geo 사이트를 주 사이트로 프로모션하는 것을 정기적으로 테스트하려고 합니다. 그러나 주 사이트가 사용자에게 가장 낮은 지연 시간을 제공하는 지역에 있기 때문에 전체 장애 조치를 실제로 수행하고 싶지 않습니다. 또한 매 정기 테스트 중에 다운타임을 취하고 싶지 않습니다. 따라서 주 사이트를 계속 실행하면서 보조 사이트를 프로모션합니다. 프로모션된 사이트에서 스모크 테스팅을 시작합니다. 하지만 프로모션된 사이트가 사용자에게 이메일을 보내기 시작하고, 푸시 미러가 외부 Git 리포지토리로 변경 사항을 푸시하는 등의 작업을 수행합니다. 여기서 무음 모드가 도움이 됩니다. 사이트 프로모션의 일부로 이 이슈를 방지하기 위해 활성화할 수 있습니다.
- GitLab 백업 검증:  백업이 작동하도록 하기 위해 별도의 테스트 인스턴스에서 백업 복원을 테스트할 때입니다. 무음 모드를 사용하여 사용자에게 잘못된 이메일을 보내는 것을 방지할 수 있습니다.
- 스테이징 환경 테스팅:  사용자 또는 외부 시스템에 영향을 미칠 수 있는 아웃바운드 통신을 트리거하지 않고 GitLab 기능을 테스트해야 할 때입니다. 특히 스테이징 환경을 프로덕션 데이터로 시드한 경우입니다.

무음 모드는 다음용으로 설계되지 않았습니다:

- 프로덕션 환경:  무음 모드는 의도적으로 [많은 GitLab 기능을 중단시킵니다](#behavior-of-gitlab-features-in-silent-mode). 무음 모드는 특히 새로운 기능에서 예기치 않은 오류를 발생시킬 수 있습니다. 무음 모드는 기본적으로 새로운 통신을 차단하여 신중함을 기해야 합니다.

## 무음 모드 켜기 {#turn-on-silent-mode}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

무음 모드를 켜는 방법은 여러 가지입니다:

- **웹 UI**

  1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
  1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
  1. **Silent Mode**를 확장하고 **Enable Silent Mode** 토글을 켭니다.
  1. 변경 사항이 즉시 저장됩니다.

- [**API**](../../api/settings.md):

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?silent_mode_enabled=true"
  ```

- [**Rails console**](../operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ::Gitlab::CurrentSettings.update!(silent_mode_enabled: true)
  ```

적용되는 데 최대 1분이 걸릴 수 있습니다. [이슈 405433](https://gitlab.com/gitlab-org/gitlab/-/issues/405433)에서 이 지연을 제거할 것을 제안합니다.

## 무음 모드 끄기 {#turn-off-silent-mode}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

무음 모드를 비활성화하는 방법은 여러 가지입니다:

- **웹 UI**

  1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
  1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
  1. **Silent Mode**를 확장하고 **Enable Silent Mode** 토글을 끕니다.
  1. 변경 사항이 즉시 저장됩니다.

- [**API**](../../api/settings.md):

  ```shell
  curl --request PUT --header "PRIVATE-TOKEN:$ADMIN_TOKEN" "<gitlab-url>/api/v4/application/settings?silent_mode_enabled=false"
  ```

- [**Rails console**](../operations/rails_console.md#starting-a-rails-console-session):

  ```ruby
  ::Gitlab::CurrentSettings.update!(silent_mode_enabled: false)
  ```

적용되는 데 최대 1분이 걸릴 수 있습니다. [이슈 405433](https://gitlab.com/gitlab-org/gitlab/-/issues/405433)에서 이 지연을 제거할 것을 제안합니다.

## 무음 모드의 GitLab 기능 동작 {#behavior-of-gitlab-features-in-silent-mode}

이 섹션에서는 무음 모드가 활성화되었을 때 GitLab의 현재 동작을 설명합니다. 무음 모드의 첫 번째 반복 작업은 [에픽 9826](https://gitlab.com/groups/gitlab-org/-/epics/9826)으로 추적됩니다.

무음 모드가 활성화되면 페이지 상단에 모든 사용자를 위해 설정이 활성화되었으며 **All outbound communications are blocked**라는 배너가 표시됩니다.

### 음소거되는 아웃바운드 통신 {#outbound-communications-that-are-silenced}

다음 기능의 아웃바운드 통신은 무음 모드에 의해 음소거됩니다.

| 기능                                                                   | 메모                                                                                                                                                                                                                                                   |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [GitLab Duo](../../user/gitlab_duo/feature_summary.md)                         | GitLab Duo 기능은 외부 언어 모델 공급자에 연결할 수 없습니다. |
| [프로젝트 및 그룹 웹후크](../../user/project/integrations/webhooks.md) | UI를 통한 웹후크 테스트 트리거는 HTTP 상태 500 응답을 초래합니다.                                                                                                                                                                               |
| [시스템 웹후크](../system_hooks.md)                                        |                                                                                                                                                                                                                                                         |
| [원격 미러](../../user/project/repository/mirror/_index.md)           | 원격 미러로의 푸시가 건너뜁니다. 원격 미러에서의 풀이 건너뜁니다.                                                                                                                                                                             |
| [실행 가능한 통합](../../user/project/integrations/_index.md)       | 통합이 실행되지 않습니다.                                                                                                                                                                                                                      |
| [서비스 데스크](../../user/project/service_desk/_index.md)                  | 수신 이메일은 여전히 이슈를 발생시키지만 서비스 데스크로 이메일을 보낸 사용자는 이슈 생성 또는 자신의 이슈에 대한 댓글 알림을 받지 않습니다.                                                                                                   |
| 아웃바운드 이메일                                                           | GitLab에서 이메일을 보내야 할 때 대신 삭제됩니다. 어디에도 대기 중이 아닙니다.                                                                                                                                                 |
| 아웃바운드 HTTP 요청                                                    | 많은 HTTP 요청은 기능이 명시적으로 차단되거나 건너뜬 경우가 아닌 곳에서 차단됩니다. 이로 인해 `SilentModeBlockedError` 클래스의 오류가 발생할 수 있습니다. 특정 오류가 무음 모드 중에 테스트하기 위해 문제가 되는 경우 [GitLab 지원팀](https://about.gitlab.com/support/)에 문의하세요. 일반적으로 호출자는 HTTP 요청을 시도하기보다는 무음 모드가 활성화되었을 때 종료해야 합니다. 모든 예외는 [무음 모드의 의도된 용도](#when-to-use-silent-mode)와 일치해야 합니다. |

### 음소거되지 않는 아웃바운드 통신 {#outbound-communications-that-are-not-silenced}

다음 기능의 아웃바운드 통신은 무음 모드에 의해 음소거되지 않습니다.

| 기능                                                                                                     | 메모                                                                                                                                                                                                                                           |
| ----------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [종속성 프록시](../packages/dependency_proxy.md)                                                         | 캐시되지 않은 이미지를 끌어오면 평소대로 소스에서 가져옵니다. 풀 속도 제한을 고려하세요.                                                                                                                                              |
| [파일 웹후크](../file_hooks.md)                                                                              |                                                                                                                                                                                                                                                 |
| [서버 웹후크](../server_hooks.md)                                                                          |                                                                                                                                                                                                                                                 |
| [고급 검색](../../integration/advanced_search/elasticsearch.md)                                       | 두 GitLab 인스턴스가 동일한 고급 검색 인스턴스를 사용하면 모두 검색 데이터를 수정할 수 있습니다. 이는 주 Geo 사이트가 활성 상태인 동안 보조 Geo 사이트를 프로모션한 후 발생할 수 있는 스플릿 브레인 시나리오입니다. |
| [ClickHouse 호출](../../integration/clickhouse.md)                                                         | ClickHouse 요청은 사이트 내부로 간주되기 때문에 음소거되지 않습니다.                                                                                                                                                            |
| Snowplow                                                                                                    | [이슈 409661](https://gitlab.com/gitlab-org/gitlab/-/issues/409661)에서 이러한 요청을 음소거할 것을 제안합니다.                                                                                                                                          |
| [지원 중단된 Kubernetes 연결](../../user/clusters/agent/_index.md)                                    | 이러한 요청을 음소거하기 위한 [제안](https://gitlab.com/gitlab-org/gitlab/-/issues/396470)이 있습니다.                                                                                                                                          |
| [컨테이너 레지스트리 웹후크](../packages/container_registry.md#configure-container-registry-notifications) | 이러한 요청을 음소거하기 위한 [제안](https://gitlab.com/gitlab-org/gitlab/-/issues/409682)이 있습니다.                                                                                                                                          |
