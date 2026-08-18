---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 통합 오류 추적
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com

{{< /details >}}

이 가이드는 다양한 언어의 예제를 사용하여 프로젝트에 대한 통합 오류 추적을 설정하는 방법에 대한 기본 정보를 제공합니다.

GitLab Observability에서 제공하는 오류 추적은 [Sentry SDK](https://docs.sentry.io/)를 기반으로 합니다. Sentry SDK를 애플리케이션에서 사용하는 방법에 대한 추가 정보 및 예제는 [Sentry SDK 문서](https://docs.sentry.io/platforms/)를 참조하세요.

## 프로젝트에 대한 오류 추적 활성화 {#enable-error-tracking-for-a-project}

사용하는 프로그래밍 언어에 관계없이 먼저 GitLab 프로젝트에 대한 오류 추적을 활성화해야 합니다. 이 가이드는 `GitLab.com` 인스턴스를 사용합니다.

전제 조건:

- 오류 추적을 활성화하려는 프로젝트가 있어야 합니다. [프로젝트 생성](../user/project/_index.md) 방법을 참조하세요.

GitLab을 백엔드로 사용하여 오류 추적을 활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **설정** > **모니터링**으로 이동합니다.
1. **오류 추적**을 확장합니다.
1. **오류 추적 활성화**에서 **활성**을 선택합니다.
1. **오류 추적 백엔드**에서 **GitLab**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.
1. **Data Source Name (DSN)** 문자열을 복사합니다. SDK 구현을 구성하려면 이 값이 필요합니다.

## 사용자 추적 구성 {#configure-user-tracking}

오류의 영향을 받는 사용자 수를 추적하려면:

- 계측 코드에서 각 사용자가 고유하게 식별되는지 확인합니다. 사용자 ID, 이름, 이메일 주소 또는 IP 주소를 사용하여 사용자를 식별할 수 있습니다.

예를 들어 [Python](https://docs.sentry.io/platforms/python/enriching-events/identify-user/)을 사용하는 경우 이메일로 사용자를 식별할 수 있습니다:

```python
sentry_sdk.set_user({ email: "john.doe@example.com" });
```

사용자 식별에 대한 자세한 정보는 [Sentry 문서](https://docs.sentry.io/)를 참조하세요.

## 추적된 오류 보기 {#view-tracked-errors}

애플리케이션이 Sentry SDK를 통해 오류를 오류 추적 API로 전송한 후 해당 오류는 GitLab UI에서 사용할 수 있습니다. 이를 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **모니터링** > **오류 추적**으로 이동하여 열린 오류 목록을 봅니다:

   ![MonitorListErrors](img/list_errors_v16_0.png)

1. 오류를 선택하여 **Error details** 보기를 확인합니다:

   ![MonitorDetailErrors](img/detail_errors_v16_0.png)

   이 페이지에는 다음을 포함하여 예외에 대한 추가 세부 정보가 표시됩니다:

   - 총 발생 횟수입니다.
   - 영향을 받은 총 사용자 수입니다.
   - 처음 확인된 날짜 및 커밋 ({{< icon name="commit" >}})입니다.
   - 마지막으로 확인된 날짜(상대 날짜로 표시)입니다. 타임스탬프를 보려면 날짜 위에 마우스를 올립니다.
   - 시간당 오류 빈도를 나타내는 막대 그래프입니다. 특정 시간의 총 오류 수를 보려면 막대 위에 마우스를 올립니다.
   - 스택 추적입니다.

### 오류로부터 이슈 생성 {#create-an-issue-from-an-error}

오류와 관련된 작업을 추적하려면 오류로부터 직접 이슈를 생성할 수 있습니다:

- **Error details** 보기에서 **이슈 생성**을 선택합니다.

이슈가 생성되었습니다. 이슈 설명에는 오류 스택 추적이 포함되어 있습니다.

### 오류 상세 정보 분석 {#analyze-an-errors-details}

오류의 전체 타임스탬프를 보려면:

- **Error details** 페이지에서 **마지막으로 확인됨** 날짜 위에 마우스를 올립니다.

다음 예제에서 오류는 11:41 CEST에 발생했습니다:

![MonitorDetailErrors](img/last_seen_v16_10.png)

**최근 24시간** 그래프는 이 오류가 시간당 몇 번 발생했는지를 측정합니다. `11 am` 막대를 가리키면 대화상자에 오류가 239번 표시되었다는 것이 표시됩니다:

![MonitorDetailErrors](img/error_bucket_v16_10.png)

**마지막으로 확인됨** 필드는 전체 시간이 완료될 때까지 업데이트되지 않습니다. 호출에 사용되는 라이브러리 [`import * as timeago from 'timeago.js'`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/lib/utils/datetime/timeago_utility.js#L1) 때문입니다.

## 오류 발생 {#emit-errors}

### 지원되는 언어 SDK 및 Sentry 유형 {#supported-language-sdks--sentry-types}

GitLab 오류 추적은 다음 이벤트 유형을 지원합니다:

| 언어 | 테스트된 SDK 클라이언트 및 버전   | 엔드포인트   | 지원되는 항목 유형              |
| -------- | ------------------------------- | ---------- | --------------------------------- |
| Go       | `sentry-go/0.20.0`              | `store`    | `exception`, `message`            |
| Java     | `sentry.java:6.18.1`            | `envelope` | `exception`, `message`            |
| NodeJS   | `sentry.javascript.node:7.38.0` | `envelope` | `exception`, `message`            |
| PHP      | `sentry.php/3.18.0`             | `store`    | `exception`, `message`            |
| Python   | `sentry.python/1.21.0`          | `envelope` | `exception`, `message`, `session` |
| Ruby     | `sentry.ruby:5.9.0`             | `envelope` | `exception`, `message`            |
| Rust     | `sentry.rust/0.31.0`            | `envelope` | `exception`, `message`, `session` |

이 테이블의 자세한 버전은 [이슈 1737](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/1737)을 참조하세요.

해당 SDK를 사용하여 예외, 이벤트 또는 메시지를 캡처하는 방법을 보여주는 [지원되는 언어 SDK의 작동 예제](https://gitlab.com/gitlab-org/opstrace/opstrace/-/tree/main/test/sentry-sdk/testdata/supported-sdk-clients)도 참조하세요. 자세한 정보는 특정 언어에 대한 [Sentry SDK 문서](https://docs.sentry.io/)를 참조하세요.

## 생성된 DSN 회전 {#rotate-generated-dsn}

> [!warning]
> Sentry에 따르면 [DSN을 공개로 유지하는 것은 안전합니다](https://docs.sentry.io/concepts/key-terms/dsn-explainer/#dsn-utilization). 하지만 악의적인 사용자가 Sentry로 정크 이벤트를 보낼 수 있는 가능성이 있습니다. 따라서 가능하면 DSN을 비밀로 유지해야 합니다. 이는 DSN이 로드되어 사용자의 디바이스에 저장될 클라이언트 측 애플리케이션에는 적용되지 않습니다.

전제 조건:

- 프로젝트에 대한 숫자 [프로젝트 ID](../user/project/working_with_projects.md#find-the-project-id)가 필요합니다.

Sentry DSN을 회전하려면:

1. [액세스 토큰 생성](../user/profile/personal_access_tokens.md#create-a-personal-access-token) 시 `api` 범위를 사용합니다. 이 값을 복사하십시오. 향후 단계에서 필요합니다.
1. [오류 추적 API](../api/error_tracking.md)를 사용하여 새 Sentry DSN을 생성하고 `<your_access_token>` 및 `<your_project_number>`을 값으로 바꿉니다:

   ```shell
   curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_number>/error_tracking/client_keys"
   ```

1. 사용 가능한 클라이언트 키(Sentry DSN)를 가져옵니다. 새로 생성한 Sentry DSN이 준비되었는지 확인합니다. 이전 클라이언트 키의 키 ID를 사용하여 다음 명령을 실행하고 `<your_access_token>` 및 `<your_project_number>`을 값으로 바꿉니다:

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_number>/error_tracking/client_keys"
   ```

1. 이전 클라이언트 키를 삭제합니다:

   ```shell
   curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_number>/error_tracking/client_keys/<key_id>"
   ```

## SDK 이슈 디버그 {#debug-sdk-issues}

Sentry에서 지원하는 대부분의 언어는 초기화의 일부로 `debug` 옵션을 노출합니다. `debug` 옵션은 오류 전송 이슈를 디버그할 때 도움이 될 수 있습니다. API로 데이터를 전송하기 전에 JSON을 출력하는 다른 옵션이 있습니다.

## 데이터 보존 {#data-retention}

GitLab은 모든 오류에 대해 90일의 보존 기간 제한이 있습니다.

오류 추적 버그 또는 기능에 대한 피드백을 남기려면 [피드백 이슈](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2362)에 댓글을 달거나 [새로운 이슈](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/new)를 여세요.
