---
stage: Developer Experience
group: Performance Enablement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 성능 표시줄
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

성능 표시줄은 실시간 메트릭을 브라우저에 직접 표시하여 로그를 확인하거나 별도의 프로파일링 도구를 실행할 필요 없이 인사이트를 제공합니다.

개발 팀의 경우 성능 표시줄은 어디에 집중해야 하는지 정확히 보여줌으로써 디버깅을 간소화합니다.

![성능 표시줄](img/performance_bar_v14_4.png)

## 사용 가능한 정보 {#available-information}

{{< history >}}

- Rugged 호출이 GitLab 16.6에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/421591)되었습니다.

{{< /history >}}

왼쪽에서 오른쪽으로 성능 표시줄은 다음을 표시합니다:

- **Current Host**: 페이지를 제공하는 현재 호스트입니다.
- **Database queries**: 소요 시간(밀리초)과 데이터베이스 쿼리의 총 개수이며, `00ms / 00 (00 cached) pg` 형식으로 표시됩니다. 더 많은 세부정보를 표시하려면 선택하세요. 이를 사용하여 각 쿼리에 대한 다음 세부정보를 확인할 수 있습니다:
  - **In a transaction**: 트랜잭션의 컨텍스트에서 실행되었을 경우 쿼리 아래에 표시됩니다.
  - **역할**: [Database Load Balancing](../../postgresql/database_load_balancing.md)이 활성화되어 있을 때 표시됩니다. 쿼리에 사용된 서버 역할을 표시합니다. "Primary"는 쿼리가 읽기/쓰기 기본 서버로 전송되었음을 의미합니다. "Replica"는 읽기 전용 복제본으로 전송되었음을 의미합니다.
  - **Configuration name**: 다양한 GitLab 기능을 위해 구성된 서로 다른 데이터베이스를 구분하는 데 사용됩니다. 표시되는 이름은 GitLab에서 데이터베이스 연결을 구성하는 데 사용된 이름과 동일합니다.
- **Gitaly 호출**: 소요 시간(밀리초)과 [Gitaly](../../gitaly/_index.md) 호출의 총 개수입니다. 더 많은 세부정보를 표시하려면 선택하세요.
- **Redis 호출**: 소요 시간(밀리초)과 Redis 호출의 총 개수입니다. 더 많은 세부정보를 표시하려면 선택하세요.
- **Elasticsearch 호출**: 소요 시간(밀리초)과 Elasticsearch 호출의 총 개수입니다. 더 많은 세부정보를 표시하려면 선택하세요.
- **External HTTP calls**: 소요 시간(밀리초)과 다른 시스템에 대한 외부 호출의 총 개수입니다. 더 많은 세부정보를 표시하려면 선택하세요.
- 페이지의 **Load timings**: 브라우저가 로드 타이밍을 지원하는 경우 슬래시로 구분된 밀리초 단위의 여러 값입니다. 더 많은 세부정보를 표시하려면 선택하세요. 값은 왼쪽에서 오른쪽으로 다음과 같습니다:
  - **백엔드**: 기본 페이지를 로드하는 데 필요한 시간입니다.
  - [**First Contentful Paint**](https://developer.chrome.com/docs/lighthouse/performance/first-contentful-paint/):  사용자가 무언가를 볼 때까지의 시간입니다. 브라우저가 이 기능을 지원하지 않는 경우 `NaN`을 표시합니다.
  - [**DomContentLoaded**](https://web.dev/articles/critical-rendering-path/measure-crp) 이벤트입니다.
  - 페이지가 로드한 **Total number of requests**입니다.
- **메모리**: 선택한 요청 중에 사용된 메모리 양과 할당된 객체입니다. 더 많은 세부정보를 표시하는 창을 보려면 선택하세요.
- **추적**: Jaeger가 통합된 경우 **추적**은 현재 요청의 `correlation_id`이 포함된 Jaeger 추적 페이지로 연결됩니다.
- **+**: 성능 표시줄에 요청의 세부정보를 추가하는 링크입니다. 요청은 전체 URL(현재 사용자로 인증됨)이나 `X-Request-Id` 헤더의 값으로 추가할 수 있습니다.
- **다운로드**: 성능 표시줄 보고서를 생성하는 데 사용된 원본 JSON을 다운로드하는 링크입니다.
- **Memory Report**: 현재 URL의 메모리 프로파일링 보고서를 생성하는 링크입니다.
- **Flamegraph** 모드 포함: 선택한 [Stackprof 모드](https://github.com/tmm1/stackprof#sampling)로 현재 URL의 flamegraph를 생성하는 링크입니다:
  - **Wall** 모드는 벽의 시계 시간의 모든 간격을 샘플링합니다. 간격은 `10100` 마이크로초로 설정됩니다.
  - **CPU** 모드는 CPU 활동의 모든 간격을 샘플링합니다. 간격은 `10100` 마이크로초로 설정됩니다.
  - **객체** 모드는 모든 간격을 샘플링합니다. 간격은 `100` 할당으로 설정됩니다.
- **Request Selector**: 성능 표시줄의 오른쪽에 표시되는 선택 상자로, 현재 페이지가 열려 있는 동안 생성된 모든 요청에 대한 이러한 메트릭을 볼 수 있도록 합니다. 고유한 URL당 처음 두 개의 요청만 캡처됩니다.
- **통계** (선택 사항): `GITLAB_PERFORMANCE_BAR_STATS_URL` 환경 변수가 설정되어 있으면 이 URL이 표시줄에 표시됩니다. GitLab.com에서만 사용됩니다.

> [!note]
> 모든 지표가 모든 환경에서 사용 가능한 것은 아닙니다. 예를 들어 메모리 보기는 Ruby를 [특정 패치](https://gitlab.com/gitlab-org/gitlab-build-images/-/blob/master/patches/ruby/2.7.4/thread-memory-allocations-2.7.patch)가 적용된 상태로 실행해야 합니다. [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit)를 사용하여 GitLab을 로컬로 실행할 때는 일반적으로 그렇지 않으며 메모리 보기를 사용할 수 없습니다.

## 키보드 단축키 {#keyboard-shortcut}

[<kbd>p</kbd> + <kbd>b</kbd> 키보드 단축키](../../../user/shortcuts.md)를 눌러 성능 표시줄을 표시하고 다시 누르면 숨깁니다.

운영자가 아닌 사용자가 성능 표시줄을 표시하려면 [사용자에 대해 활성화](#enable-the-performance-bar-for-non-administrators)되어야 합니다.

## 요청 경고 {#request-warnings}

미리 정의된 제한을 초과하는 요청은 경고 {{< icon name="warning" >}} 아이콘과 메트릭 옆의 설명을 표시합니다. 이 예에서 Gitaly 호출 지속 시간이 임계값을 초과했습니다.

![Gitaly 호출 지속 시간이 임계값을 초과함](img/performance_bar_gitaly_threshold_v12_4.png)

## 운영자가 아닌 사용자를 위해 성능 표시줄 활성화 {#enable-the-performance-bar-for-non-administrators}

성능 표시줄은 기본적으로 운영자가 아닌 사용자에 대해 비활성화됩니다. 특정 그룹에 대해 활성화하려면:

1. 관리자 액세스 권한이 있는 사용자로 로그인하세요.
1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **측정항목 및 프로파일링**을 선택합니다.
1. **프로파일링 - 성능 표시줄**을 확장합니다.
1. **운영자가 아닌 사용자가 성능 표시줄에 액세스할 수 있도록 허용**을 선택합니다.
1. **다음 그룹의 구성원에 대한 액세스 허용** 필드에서 성능에 액세스할 수 있는 그룹의 전체 경로를 제공합니다.
1. **변경 사항 저장**을 선택합니다.
