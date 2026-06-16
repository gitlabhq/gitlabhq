---
stage: Production Engineering
group: Networking and Incident Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 사용자 및 IP 속도 제한
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

속도 제한은 웹 애플리케이션의 보안 및 내구성을 개선하는 데 사용되는 일반적인 기술입니다. 자세한 내용은 [속도 제한](../../security/rate_limits.md)을 참조하세요.

다음 제한은 기본적으로 비활성화됩니다:

- [인증되지 않은 API 요청(IP당)](#enable-unauthenticated-api-request-rate-limit).
- [인증되지 않은 웹 요청(IP당)](#enable-unauthenticated-web-request-rate-limit).
- [인증된 API 요청(사용자당)](#enable-authenticated-api-request-rate-limit).
- [인증된 웹 요청(사용자당)](#enable-authenticated-web-request-rate-limit).

> [!note]
> 기본적으로 모든 Git 작업은 먼저 인증되지 않은 상태에서 시도됩니다. 이 때문에 HTTP Git 작업은 인증되지 않은 요청에 대해 구성된 속도 제한을 트리거할 수 있습니다.

API 요청의 속도 제한은 프론트엔드에서 만든 요청에는 영향을 주지 않습니다. 이러한 요청은 항상 웹 트래픽으로 계산되기 때문입니다.

## 전제 조건 {#prerequisites}

관리자 액세스 권한이 있어야 합니다.

## 인증되지 않은 API 요청 속도 제한 활성화 {#enable-unauthenticated-api-request-rate-limit}

인증되지 않은 API 요청 속도 제한을 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택하세요.
1. **사용자 및 IP 속도 제한**을 확장하세요.
1. **인증되지 않은 API 요청 속도 제한 활성화**를 선택하세요.

   - 선택사항. **IP당 속도 제한 기간당 최대 인증되지 않은 API 요청** 값을 업데이트하세요. `3600`로 기본 설정됩니다.
   - 선택사항. **Unauthenticated rate limit period in seconds** 값을 업데이트하세요. `3600`로 기본 설정됩니다.

## 인증되지 않은 웹 요청 속도 제한 활성화 {#enable-unauthenticated-web-request-rate-limit}

인증되지 않은 요청 속도 제한을 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택하세요.
1. **사용자 및 IP 속도 제한**을 확장하세요.
1. **인증되지 않은 웹 요청 속도 제한 활성화**를 선택하세요.

   - 선택사항. **IP당 속도 제한 기간당 최대 인증되지 않은 웹 요청** 값을 업데이트하세요. `3600`로 기본 설정됩니다.
   - 선택사항. **Unauthenticated rate limit period in seconds** 값을 업데이트하세요. `3600`로 기본 설정됩니다.

## 인증된 API 요청 속도 제한 활성화 {#enable-authenticated-api-request-rate-limit}

인증된 API 요청 속도 제한을 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택하세요.
1. **사용자 및 IP 속도 제한**을 확장하세요.
1. **인증된 API 요청 속도 제한 활성화**를 선택하세요.

   - 선택사항. **사용자당 속도 제한 기간당 인증된 최대 API 요청** 값을 업데이트하세요. `7200`로 기본 설정됩니다.
   - 선택사항. **인증된 API 속도 제한 기간(초)** 값을 업데이트하세요. `3600`로 기본 설정됩니다.

## 인증된 웹 요청 속도 제한 활성화 {#enable-authenticated-web-request-rate-limit}

인증된 요청 속도 제한을 활성화하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택하세요.
1. **사용자 및 IP 속도 제한**을 확장하세요.
1. **인증된 웹 요청 속도 제한 활성화**를 선택하세요.

   - 선택사항. **사용자당 비율 제한 기간당 인증된 최대 웹 요청** 값을 업데이트하세요. `7200`로 기본 설정됩니다.
   - 선택사항. **인증된 웹 속도 제한 기간(초)** 값을 업데이트하세요. `3600`로 기본 설정됩니다.

## 사용자 정의 속도 제한 응답 사용 {#use-a-custom-rate-limit-response}

속도 제한을 초과하는 요청은 `429` 응답 코드와 일반 텍스트 본문을 반환하며, 기본적으로 `Retry later`입니다.

사용자 정의 응답을 사용하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택하세요.
1. **사용자 및 IP 속도 제한**을 확장하세요.
1. **속도 제한에 도달한 클라이언트에 보낼 일반 텍스트 응답** 텍스트 상자에 일반 텍스트 응답 메시지를 추가하세요.

## `project/:id/jobs`에 대한 분당 최대 인증된 요청 {#maximum-authenticated-requests-to-projectidjobs-per-minute}

{{< history >}}

- GitLab 16.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129319)되었습니다.

{{< /history >}}

타임아웃을 줄이기 위해 `project/:id/jobs` 엔드포인트는 인증된 사용자당 600개 호출의 기본 [속도 제한](../../security/rate_limits.md#project-jobs-api-endpoint)을 가집니다.

최대 요청 수를 수정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택하세요.
1. **사용자 및 IP 속도 제한**을 확장하세요.
1. **`project/:id/jobs`에 대한 분당 최대 인증된 요청** 값을 업데이트하세요.

## 응답 헤더 {#response-headers}

응답 헤더에는 모든 요청에 대한 속도 제한 정보가 포함됩니다. 이러한 헤더를 사용하여 사용량을 사전에 모니터링하고 요청 패턴을 조정하여 제한을 피하세요.

### 여러 속도 제한 시스템 {#multiple-rate-limiting-systems}

속도 제한은 두 개의 독립적인 시스템을 통해 적용됩니다:

- `Rack::Attack` 미들웨어 속도 제한:  HTTP 계층에서 적용됩니다. 예를 들어 사용자당 인증된 API 요청 또는 IP당 인증되지 않은 웹 요청이 포함됩니다. 이러한 제한은 응답 헤더에 반영됩니다.
- 애플리케이션 속도 제한:  애플리케이션 수준에서 적용됩니다. 예를 들어 사용자당 이슈 생성 또는 사용자당 프로젝트 내보내기가 포함됩니다. 이러한 제한은 응답 헤더에 포함되지 않습니다.

단일 요청은 두 가지 유형의 속도 제한 모두에 동시에 계산될 수 있습니다. 응답 헤더는 가장 제한적인 `Rack::Attack` 속도 제한 상태만 표시합니다.

> [!note]
> 애플리케이션 속도 제한은 응답 헤더에 포함되지 않습니다.

#### 예제 {#example}

API를 통해 이슈를 생성하는 요청은 다음에 계산됩니다:

- 인증된 API 요청 속도 제한(`Rack::Attack`). 응답 헤더에 포함됩니다.
- 이슈 생성 속도 제한(애플리케이션 수준). 응답 헤더에 포함되지 않습니다.

이슈 생성 제한을 초과하면 이전 응답 헤더에서 충분한 남은 인증된 API 요청을 나타낼 때에도 `429` 응답이 반환됩니다.

### 모든 요청에 대해 반환된 헤더 {#headers-returned-for-all-requests}

다음 헤더는 모든 응답에 포함되어 클라이언트가 속도 제한 상태를 추적하는 데 도움이 됩니다:

| 헤더                | 예제                      | 설명                                                                                                                                                                                                      |
|:----------------------|:-----------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `RateLimit-Limit`     | `60`                         | 클라이언트의 분당 요청 할당량입니다. **운영자** 영역에 설정된 속도 제한 기간이 1분과 다른 경우, 이 헤더의 값은 약 60분 기간으로 조정됩니다. |
| `RateLimit-Name`      | `throttle_authenticated_api` | 요청에 적용된 제한의 이름입니다.                                                                                                                                                                     |
| `RateLimit-Observed`  | `67`                         | 시간 창에서 클라이언트와 연결된 요청의 수입니다.                                                                                                                                                  |
| `RateLimit-Remaining` | `33`                         | 시간 창에서 남은 할당량입니다. `RateLimit-Limit` - `RateLimit-Observed`의 결과입니다.                                                                                                                     |
| `RateLimit-Reset`     | `1609844400`                 | [Unix 시간](https://en.wikipedia.org/wiki/Unix_time) 형식의 요청 할당량이 재설정되는 시간입니다.                                                                                                             |

### 제한된 요청에 대한 추가 헤더 {#additional-headers-for-throttled-requests}

클라이언트가 속도 제한을 초과하면(HTTP 상태 `429`), 다음의 추가 헤더가 포함됩니다:

| 헤더                | 예제                         | 설명                                                                                                                                                   |
|:----------------------|:--------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `RateLimit-ResetTime` | `Tue, 05 Jan 2021 11:00:00 GMT` | [RFC2616](https://www.rfc-editor.org/rfc/rfc2616#section-3.3.1) 형식의 요청 할당량이 재설정되는 날짜 및 시간입니다.                                     |
| `Retry-After`         | `30`                            | 할당량이 재설정될 때까지 남은 시간(초)입니다. 이것은 [표준 HTTP 헤더](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After)입니다. |

## HTTP 헤더를 사용하여 속도 제한 무시 {#use-an-http-header-to-bypass-rate-limiting}

조직의 필요에 따라 속도 제한을 활성화하되 일부 요청이 속도 제한을 무시하도록 할 수 있습니다.

사용자 정의 헤더로 속도 제한을 무시해야 하는 요청을 표시하여 이를 수행할 수 있습니다. 이를 GitLab 앞의 로드 밸런서 또는 역방향 프록시의 어딘가에서 수행해야 합니다. 예를 들어:

1. 무시 헤더의 이름을 선택하세요. 예를 들어, `Gitlab-Bypass-Rate-Limiting`.
1. GitLab 속도 제한을 무시해야 하는 요청에 `Gitlab-Bypass-Rate-Limiting: 1`를 설정하도록 로드 밸런서를 구성하세요.
1. 로드 밸런서를 다음 중 하나로 구성하세요:
   - `Gitlab-Bypass-Rate-Limiting`를 제거하세요.
   - 속도 제한의 영향을 받아야 하는 모든 요청에 대해 `Gitlab-Bypass-Rate-Limiting`를 `1` 이외의 값으로 설정하세요.
1. 환경 변수 `GITLAB_THROTTLE_BYPASS_HEADER`을 설정하세요.
   - [Linux 패키지 설치](https://docs.gitlab.com/omnibus/settings/environment-variables/)의 경우 `'GITLAB_THROTTLE_BYPASS_HEADER' => 'Gitlab-Bypass-Rate-Limiting'`를 `gitlab_rails['env']`에 설정하세요.
   - 자체 컴파일 설치의 경우 `export GITLAB_THROTTLE_BYPASS_HEADER=Gitlab-Bypass-Rate-Limiting`를 `/etc/default/gitlab`에 설정하세요.

로드 밸런서가 모든 들어오는 트래픽에서 무시 헤더를 제거하거나 덮어쓰는 것이 중요합니다. 그렇지 않으면 사용자가 해당 헤더를 설정하지 않도록 신뢰하고 GitLab 속도 제한을 무시할 수 없습니다.

무시는 헤더가 `1`로 설정된 경우에만 작동합니다.

무시 헤더로 인해 속도 제한을 무시한 요청은 `"throttle_safelist":"throttle_bypass_header"`로 [`production_json.log`](../logs/_index.md#production_jsonlog)에서 표시됩니다.

무시 메커니즘을 비활성화하려면 환경 변수 `GITLAB_THROTTLE_BYPASS_HEADER`이 설정되지 않았거나 비어 있는지 확인하세요.

## 특정 사용자가 인증된 요청 속도 제한을 무시하도록 허용 {#allow-specific-users-to-bypass-authenticated-request-rate-limiting}

이전에 설명한 무시 헤더와 유사하게, 특정 사용자 집합이 속도 제한을 무시하도록 허용할 수 있습니다. 이는 인증된 요청에만 적용됩니다. 인증되지 않은 요청의 경우 정의상 GitLab은 사용자가 누구인지 알 수 없습니다.

허용 목록은 `GITLAB_THROTTLE_USER_ALLOWLIST` 환경 변수의 쉼표로 구분된 사용자 ID 목록으로 구성됩니다. 사용자 1, 53 및 217이 인증된 요청 속도 제한을 무시하도록 하려면 허용 목록 구성이 `1,53,217`입니다.

- [Linux 패키지 설치](https://docs.gitlab.com/omnibus/settings/environment-variables/)의 경우 `'GITLAB_THROTTLE_USER_ALLOWLIST' => '1,53,217'`를 `gitlab_rails['env']`에 설정하세요.
- 자체 컴파일 설치의 경우 `export GITLAB_THROTTLE_USER_ALLOWLIST=1,53,217`를 `/etc/default/gitlab`에 설정하세요.

사용자 허용 목록으로 인해 속도 제한을 무시한 요청은 `"throttle_safelist":"throttle_user_allowlist"`로 [`production_json.log`](../logs/_index.md#production_jsonlog)에서 표시됩니다.

애플리케이션 시작 시 허용 목록이 [`auth.log`](../logs/_index.md#authlog)에 기록됩니다.

## 적용하기 전에 제한 설정 시도 {#try-out-throttling-settings-before-enforcing-them}

`GITLAB_THROTTLE_DRY_RUN` 환경 변수를 제한 이름의 쉼표로 구분된 목록으로 설정하여 제한 설정을 시도할 수 있습니다.

가능한 이름은:

- `throttle_unauthenticated`
  - GitLab 14.3에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/335300). 대신 `throttle_unauthenticated_api` 또는 `throttle_unauthenticated_web`를 사용하세요. `throttle_unauthenticated`는 여전히 지원되며 둘 다 선택합니다.
- `throttle_unauthenticated_api`
- `throttle_unauthenticated_web`
- `throttle_authenticated_api`
- `throttle_authenticated_web`
- `throttle_unauthenticated_protected_paths`
- `throttle_authenticated_protected_paths_api`
- `throttle_authenticated_protected_paths_web`
- `throttle_unauthenticated_packages_api`
- `throttle_authenticated_packages_api`
- `throttle_authenticated_git_lfs`
- `throttle_unauthenticated_files_api`
- `throttle_authenticated_files_api`
- `throttle_unauthenticated_deprecated_api`
- `throttle_authenticated_deprecated_api`
- `throttle_unauthenticated_git_http`
- `throttle_authenticated_git_http`

예를 들어, 보호되지 않은 경로에 대한 모든 인증된 요청에 대한 제한을 시도하려면 `GITLAB_THROTTLE_DRY_RUN='throttle_authenticated_web,throttle_authenticated_api'`를 설정하면 됩니다.

모든 제한에 대해 드라이 실행 모드를 활성화하려면 변수를 `*`로 설정할 수 있습니다.

제한을 드라이 실행 모드로 설정하면 [`auth.log`](../logs/_index.md#authlog)에 메시지가 기록되고 요청은 계속됩니다. 로그 메시지에는 `env` 필드가 `track`로 설정되어 있습니다. `matched` 필드에는 히트한 제한의 이름이 포함됩니다.

설정에서 속도 제한을 활성화하기 전에 환경 변수를 설정하는 것이 중요합니다. **운영자** 영역의 설정은 즉시 적용되지만 환경 변수를 설정하려면 모든 Puma 프로세스를 다시 시작해야 합니다.

## 문제 해결 {#troubleshooting}

### 실수로 관리자를 잠금 해제한 후 제한 비활성화 {#disable-throttling-after-accidentally-locking-administrators-out}

많은 사용자가 동일한 프록시 또는 네트워크 게이트웨이를 통해 GitLab에 연결하는 경우, 속도 제한이 너무 낮으면 해당 제한으로 인해 관리자도 잠길 수 있습니다. GitLab이 제한을 트리거한 요청과 동일한 IP를 사용하는 것으로 보기 때문입니다.

관리자는 [Rails 콘솔](../operations/rails_console.md) 을 사용하여 [`GITLAB_THROTTLE_DRY_RUN` 변수](#try-out-throttling-settings-before-enforcing-them)에 대해 나열된 것과 동일한 제한을 비활성화할 수 있습니다. 예를 들어:

```ruby
Gitlab::CurrentSettings.update!(throttle_authenticated_web_enabled: false)
```

이 예제에서 `throttle_authenticated_web` 매개 변수는 `_enabled` 이름 접미사를 가집니다.

제한에 대한 숫자 값을 설정하려면 `_enabled` 이름 접미사를 `_period_in_seconds` 및 `_requests_per_period` 접미사로 바꾸세요.
