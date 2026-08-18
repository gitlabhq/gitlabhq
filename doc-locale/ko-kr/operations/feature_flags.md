---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 애플리케이션을 위한 사용자 지정 기능 플래그를 만들고 유지합니다.
title: 기능 플래그
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

기능 플래그를 사용하면 애플리케이션의 새로운 기능을 프로덕션에 더 작은 배치로 배포할 수 있습니다. 기능을 켜고 끌 수 있어 사용자의 부분 집합에 대해 지속적 배포를 달성할 수 있습니다. 기능 플래그는 위험을 줄이고 제어된 테스트를 수행하며 기능 전달과 고객 출시를 분리할 수 있게 해줍니다.

[GitLab의 기능 플래그 전체 목록](../administration/feature_flags/list.md)도 사용할 수 있습니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 기능 플래그의 실제 사용 예는 [기능 플래그를 사용한 위험 제거](https://www.youtube.com/watch?v=U9WqoK9froI)를 참조하세요.
<!-- Video published on 2024-02-01 -->

클릭스루 데모는 [기능 플래그](https://tech-marketing.gitlab.io/static-demos/feature-flags/feature-flags-html.html)를 참조하세요.
<!-- Demo published on 2023-07-13 -->

## 기능 플래그 사용 {#using-feature-flags}

GitLab은 [Unleash](https://github.com/Unleash/unleash)와 호환되는 API를 기능 플래그에 제공합니다.

GitLab에서 플래그를 활성화하거나 비활성화하면 애플리케이션은 활성화하거나 비활성화할 기능을 결정할 수 있습니다.

GitLab에서 기능 플래그를 만들고 애플리케이션의 API를 사용하여 기능 플래그 목록과 해당 상태를 가져올 수 있습니다. 애플리케이션은 GitLab과 통신하도록 구성되어야 하므로 개발자가 호환되는 클라이언트 라이브러리를 사용하고 [애플리케이션에 기능 플래그를 통합](#integrate-feature-flags-with-your-application)해야 합니다.

## 기능 플래그 생성 {#create-a-feature-flag}

기능 플래그를 만들고 활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **배포** > **기능 플래그**를 선택합니다.
1. **새 기능 플래그**를 선택합니다.
1. 문자로 시작하고 소문자, 숫자, 언더스코어(`_`), 또는 대시(`-`)만 포함하며 대시(`-`) 또는 언더스코어(`_`)로 끝나지 않는 이름을 입력합니다.
1. 선택 사항. 설명을 입력합니다(최대 255자).
1. 기능 플래그 [**전략**](#feature-flag-strategies)을 추가하여 플래그를 적용하는 방식을 정의합니다. 각 전략에 대해 **유형**(기본값 [**모든 사용자**](#all-users))과 **환경**(기본값 모든 환경)을 포함합니다.
1. **기능 플래그 생성**을 선택합니다.

이 설정을 변경하려면 목록의 기능 플래그 옆에서 **편집**({{< icon name="pencil" >}})을 선택합니다.

## 기능 플래그의 최대 개수 {#maximum-number-of-feature-flags}

GitLab Self-Managed의 프로젝트당 기능 플래그의 최대 개수는 200개입니다. GitLab.com의 경우 최대 개수는 [티어](https://about.gitlab.com/pricing/)에 따라 결정됩니다:

| 티어     | 프로젝트당 기능 플래그(GitLab.com) | 프로젝트당 기능 플래그(GitLab Self-Managed) |
|----------|----------------------------------|------------------------------------------|
| Free     | 50                               | 200                                      |
| Premium  | 150                              | 200                                      |
| Ultimate | 200                              | 200                                      |

## 기능 플래그 전략 {#feature-flag-strategies}

전략을 여러 번 정의하지 않고도 여러 환경에 기능 플래그 전략을 적용할 수 있습니다.

GitLab 기능 플래그는 [Unleash](https://docs.getunleash.io/)를 기반으로 합니다. Unleash에는 세분화된 기능 플래그 제어를 위한 [전략](https://docs.getunleash.io/reference/activation-strategies)이 있습니다. GitLab 기능 플래그는 여러 전략을 가질 수 있으며 지원되는 전략은 다음과 같습니다:

- [모든 사용자](#all-users)
- [사용자 백분율](#percent-of-users)
- [사용자 ID](#user-ids)
- [사용자 목록](#user-list)

전략을 기능 플래그에 추가할 때 [기능 플래그 생성](#create-a-feature-flag)하거나 **배포** > **기능 플래그**로 이동하고 **편집**({{< icon name="pencil" >}})을 선택하여 생성 후 기존 기능 플래그를 편집할 때 전략을 추가할 수 있습니다.

### 모든 사용자 {#all-users}

모든 사용자에 대해 기능을 활성화합니다. 표준(`default`) Unleash 활성화 [전략](https://docs.getunleash.io/reference/activation-strategies#standard)을 사용합니다.

### 백분율 롤아웃 {#percent-rollout}

구성 가능한 동작 일관성으로 페이지 뷰의 백분율에 대해 기능을 활성화합니다. 이 일관성을 스티키니스라고도 합니다. 점진적 롤아웃(`flexibleRollout`) Unleash 활성화 [전략](https://docs.getunleash.io/reference/activation-strategies#gradual-rollout)을 사용합니다.

다음을 기반으로 일관성을 구성할 수 있습니다:

- **사용자 ID**: 각 사용자 ID는 세션 ID를 무시하고 일관된 동작을 합니다.
- **Session IDs**: 각 세션 ID는 사용자 ID를 무시하고 일관된 동작을 합니다.
- **랜덤**: 일관된 동작이 보장되지 않습니다. 기능은 선택한 페이지 뷰의 백분율에 대해 임의로 활성화됩니다. 사용자 ID 및 세션 ID는 무시됩니다.
- **사용 가능한 ID**: 사용자의 상태를 기반으로 일관된 동작을 시도합니다:
  - 사용자가 로그인한 경우 사용자 ID를 기반으로 동작을 일관되게 합니다.
  - 사용자가 익명인 경우 세션 ID를 기반으로 동작을 일관되게 합니다.
  - 사용자 ID 또는 세션 ID가 없으면 기능이 선택한 페이지 뷰의 백분율에 대해 임의로 활성화됩니다.

예를 들어 **사용 가능한 ID**를 기반으로 15% 값을 설정하여 페이지 뷰의 15%에 대해 기능을 활성화합니다. 인증된 사용자의 경우 사용자 ID를 기반으로 합니다. 세션 ID가 있는 익명 사용자의 경우 사용자 ID가 없기 때문에 대신 세션 ID를 기반으로 합니다. 그런 다음 세션 ID가 제공되지 않으면 임의 선택으로 대체됩니다.

롤아웃 백분율은 0%에서 100% 사이일 수 있습니다.

사용자 ID를 기반으로 일관성을 선택하면 [사용자 백분율](#percent-of-users) 롤아웃과 동일하게 작동합니다.

> [!warning]
> **랜덤**을 선택하면 개별 사용자에 대해 일관성 없는 애플리케이션 동작을 제공합니다.

### 사용자 백분율 {#percent-of-users}

인증된 사용자의 백분율에 대해 기능을 활성화합니다. Unleash 활성화 전략 [`gradualRolloutUserId`](https://docs.getunleash.io/reference/activation-strategies#gradual-rollout)을 사용합니다.

예를 들어 15% 값을 설정하여 인증된 사용자의 15%에 대해 기능을 활성화합니다.

롤아웃 백분율은 0%에서 100% 사이일 수 있습니다.

스티키니스(같은 사용자에 대한 일관된 애플리케이션 동작)는 인증된 사용자에게 보장되지만 익명 사용자에게는 보장되지 않습니다.

[백분율 롤아웃](#percent-rollout)은 **사용자 ID**를 기반으로 일관성을 가지므로 동일한 동작을 합니다. 사용자 백분율보다 더 유연하기 때문에 백분율 롤아웃을 사용해야 합니다

> [!warning]
> 사용자 백분율 전략을 선택하면 기능을 활성화하기 위해 Unleash 클라이언트에 **must** 사용자 ID를 제공해야 합니다. [Ruby 예제](#ruby-application-example)를 참조하세요.

### 사용자 ID {#user-ids}

대상 사용자 목록에 대해 기능을 활성화합니다. Unleash UserID(`userWithId`) 활성화 [전략](https://docs.getunleash.io/reference/activation-strategies#userids)을 사용하여 구현됩니다.

사용자 ID를 쉼표로 구분된 값 목록으로 입력합니다(예: `user@example.com, user2@example.com`, 또는 `username1,username2,username3`, 등등). 사용자 ID는 애플리케이션 사용자의 식별자입니다. GitLab 사용자일 필요는 없습니다.

> [!warning]
> 대상 사용자에 대해 기능을 활성화하려면 Unleash 클라이언트에 **must** 사용자 ID를 제공해야 합니다. [Ruby 예제](#ruby-application-example)를 참조하세요.

### 사용자 목록 {#user-list}

기능 플래그 UI에서 [만든](#create-a-user-list) 사용자 목록에 대해 기능을 활성화하거나 [기능 플래그 사용자 목록 API](../api/feature_flag_user_lists.md)를 사용하여 활성화합니다. [사용자 ID](#user-ids)와 유사하게 Unleash UserID(`userWithId`) 활성화 [전략](https://docs.getunleash.io/reference/activation-strategies#userids)을 사용합니다.

특정 사용자에 대해 기능을 비활성화할 수 없지만 사용자 목록에 대해 활성화하여 유사한 결과를 얻을 수 있습니다.

예를 들어:

- `Full-user-list` = `User1A, User1B, User2A, User2B, User3A, User3B, ...`
- `Full-user-list-excluding-B-users` = `User1A, User2A, User3A, ...`

#### 사용자 목록 생성 {#create-a-user-list}

사용자 목록을 만들려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **배포** > **기능 플래그**를 선택합니다.
1. **사용자 목록 보기**를 선택합니다
1. **새 사용자 목록**을 선택합니다.
1. 목록의 이름을 입력합니다.
1. **생성**을 선택합니다.

옆에서 **편집**({{< icon name="pencil" >}})을 선택하여 목록의 사용자 ID를 볼 수 있습니다. 목록을 볼 때 **편집**({{< icon name="pencil" >}})을 선택하여 이름을 바꿀 수 있습니다.

#### 사용자 목록에 사용자 추가 {#add-users-to-a-user-list}

사용자 목록에 사용자를 추가하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **배포** > **기능 플래그**를 선택합니다.
1. 사용자를 추가할 목록 옆에서 **편집**({{< icon name="pencil" >}})을 선택합니다.
1. **사용자 추가**를 선택합니다.
1. 사용자 ID를 쉼표로 구분된 값 목록으로 입력합니다. 예를 들어 `user@example.com, user2@example.com`, 또는 `username1,username2,username3`, 등등입니다.
1. **추가**를 선택합니다.

#### 사용자 목록에서 사용자 제거 {#remove-users-from-a-user-list}

사용자 목록에서 사용자를 제거하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **배포** > **기능 플래그**를 선택합니다.
1. 변경할 목록 옆에서 **편집**({{< icon name="pencil" >}})을 선택합니다.
1. 제거할 ID 옆에서 **삭제**({{< icon name="remove" >}})을 선택합니다.

## 코드 참조 검색 {#search-for-code-references}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

정리 중에 코드에서 기능 플래그를 제거하려면 프로젝트에 대한 모든 참조를 찾습니다.

기능 플래그의 코드 참조를 검색하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **배포** > **기능 플래그**를 선택합니다.
1. 제거할 기능 플래그를 편집합니다.
1. **추가 작업**({{< icon name="ellipsis_v" >}})을 선택합니다.
1. **참조 코드 검색**을 선택합니다.

## 특정 환경에 대해 기능 플래그 비활성화 {#disable-a-feature-flag-for-a-specific-environment}

특정 환경에 대해 기능 플래그를 비활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **배포** > **기능 플래그**를 선택합니다.
1. 비활성화할 기능 플래그에 대해 **편집**({{< icon name="pencil" >}})을 선택합니다.
1. 플래그를 비활성화하려면:
   - 적용되는 각 전략에 대해 **환경** 아래에서 환경을 삭제합니다.
1. **변경 사항 저장**을 선택합니다.

## 모든 환경에 대해 기능 플래그 비활성화 {#disable-a-feature-flag-for-all-environments}

모든 환경에 대해 기능 플래그를 비활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **배포** > **기능 플래그**를 선택합니다.
1. 비활성화할 기능 플래그에 대해 상태 토글을 **비활성화됨**으로 슬라이드합니다.

기능 플래그가 **비활성화됨** 탭에 표시됩니다.

## 애플리케이션과 기능 플래그 통합 {#integrate-feature-flags-with-your-application}

애플리케이션과 함께 기능 플래그를 사용하려면 GitLab에서 액세스 자격 증명을 가져옵니다. 그런 다음 클라이언트 라이브러리를 사용하여 애플리케이션을 준비합니다.

### 액세스 자격 증명 가져오기 {#get-access-credentials}

애플리케이션이 GitLab과 통신하는 데 필요한 액세스 자격 증명을 가져오려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **배포** > **기능 플래그**를 선택합니다.
1. **구성**을 선택하여 다음을 봅니다:
   - **API URL**: 클라이언트(애플리케이션)가 기능 플래그 목록을 가져오기 위해 연결하는 URL입니다.
   - **인스턴스 ID**: 기능 플래그의 검색을 승인하는 고유 토큰입니다.
   - **Application name**: 애플리케이션이 실행되는 환경의 이름입니다(애플리케이션 자체의 이름이 아님).

     예를 들어 애플리케이션이 프로덕션 서버를 위해 실행되면 **Application name**은 `production` 또는 유사한 값일 수 있습니다. 이 값은 환경 사양 평가에 사용됩니다.

이 필드의 의미는 시간이 지남에 따라 변할 수 있습니다. 예를 들어 **인스턴스 ID**는 단일 토큰이거나 **환경**에 할당된 여러 토큰일 수 있습니다. 또한 **Application name**은 실행 중인 환경 대신 애플리케이션 버전을 설명할 수 있습니다.

### 클라이언트 라이브러리 선택 {#choose-a-client-library}

GitLab은 Unleash 클라이언트와 호환되는 단일 백엔드를 구현합니다.

Unleash 클라이언트를 사용하면 개발자는 애플리케이션 코드에서 플래그의 기본값을 정의할 수 있습니다. 각 기능 플래그 평가는 제공된 구성 파일에 플래그가 없는 경우 원하는 결과를 표현할 수 있습니다.

Unleash는 현재 [다양한 언어 및 프레임워크에 대한 많은 SDK를 제공](https://github.com/Unleash/unleash#unleash-sdks)합니다.

### 기능 플래그 API 정보 {#feature-flags-api-information}

API 콘텐츠는 다음을 참조하세요:

- [기능 플래그 API](../api/feature_flags.md)
- [기능 플래그 사용자 목록 API](../api/feature_flag_user_lists.md)

### Go 애플리케이션 예제 {#go-application-example}

Go 애플리케이션에서 기능 플래그를 통합하는 방법의 예입니다:

```go
package main

import (
    "io"
    "log"
    "net/http"

    "github.com/Unleash/unleash-client-go/v3"
)

type metricsInterface struct {
}

func init() {
    unleash.Initialize(
        unleash.WithUrl("https://gitlab.com/api/v4/feature_flags/unleash/42"),
        unleash.WithInstanceId("29QmjsW6KngPR5JNPMWx"),
        unleash.WithAppName("production"), // Set to the running environment of your application
        unleash.WithListener(&metricsInterface{}),
    )
}

func helloServer(w http.ResponseWriter, req *http.Request) {
    if unleash.IsEnabled("my_feature_name") {
        io.WriteString(w, "Feature enabled\n")
    } else {
        io.WriteString(w, "hello, world!\n")
    }
}

func main() {
    http.HandleFunc("/", helloServer)
    log.Fatal(http.ListenAndServe(":8080", nil))
}
```

### Ruby 애플리케이션 예제 {#ruby-application-example}

Ruby 애플리케이션에서 기능 플래그를 통합하는 방법의 예입니다.

Unleash 클라이언트에는 **Percent rollout (logged in users)** 롤아웃 전략 또는 **Target Users** 목록과 함께 사용할 사용자 ID가 제공됩니다.

```ruby
#!/usr/bin/env ruby

require 'unleash'
require 'unleash/context'

unleash = Unleash::Client.new({
  url: 'http://gitlab.com/api/v4/feature_flags/unleash/42',
  app_name: 'production', # Set to the running environment of your application
  instance_id: '29QmjsW6KngPR5JNPMWx'
})

unleash_context = Unleash::Context.new
# Replace "123" with the ID of an authenticated user.
# The context's user ID must be a string:
# https://unleash.github.io/docs/unleash_context
unleash_context.user_id = "123"

if unleash.is_enabled?("my_feature_name", unleash_context)
  puts "Feature enabled"
else
  puts "hello, world!"
end
```

### Unleash Proxy 예제 {#unleash-proxy-example}

[Unleash Proxy](https://docs.getunleash.io/reference/unleash-proxy) 버전 0.2부터 프록시는 기능 플래그와 호환됩니다.

GitLab.com의 프로덕션을 위해 Unleash Proxy를 사용해야 합니다. 자세한 내용은 [성능 참고 사항](#maximum-supported-clients-in-application-nodes)을 참조하세요.

프로젝트의 기능 플래그에 연결하는 Docker 컨테이너를 실행하려면 다음 명령을 실행합니다:

```shell
docker run \
  -e UNLEASH_PROXY_SECRETS=<secret> \
  -e UNLEASH_URL=<project feature flags URL> \
  -e UNLEASH_INSTANCE_ID=<project feature flags instance ID> \
  -e UNLEASH_APP_NAME=<project environment> \
  -e UNLEASH_API_TOKEN=<tokenNotUsed> \
  -p 3000:3000 \
  unleashorg/unleash-proxy
```

| 변수                    | 값                                                                                                                                |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `UNLEASH_PROXY_SECRETS`      | [Unleash Proxy 클라이언트](https://docs.getunleash.io/reference/unleash-proxy#how-to-connect-to-the-proxy)를 구성하는 데 사용되는 공유 암호입니다. |
| `UNLEASH_URL`         | 프로젝트의 API URL입니다. 자세한 내용은 [액세스 자격 증명 가져오기](#get-access-credentials)를 읽으세요. |
| `UNLEASH_INSTANCE_ID` | 프로젝트의 인스턴스 ID입니다. 자세한 내용은 [액세스 자격 증명 가져오기](#get-access-credentials)를 읽으세요. |
| `UNLEASH_APP_NAME`    | 애플리케이션이 실행되는 환경의 이름입니다. 자세한 내용은 [액세스 자격 증명 가져오기](#get-access-credentials)를 읽으세요. |
| `UNLEASH_API_TOKEN`   | Unleash Proxy를 시작하는 데 필요하지만 GitLab에 연결하는 데 사용되지 않습니다. 모든 값으로 설정할 수 있습니다. |

Unleash Proxy를 사용할 때 각 프록시 인스턴스는 `UNLEASH_APP_NAME`에 명명된 환경에만 대해 플래그를 요청할 수 있다는 제한이 있습니다. 프록시는 클라이언트를 대신하여 이를 GitLab으로 전송합니다. 즉, 클라이언트가 재정의할 수 없습니다.

## 기능 플래그 관련 이슈 {#feature-flag-related-issues}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이슈를 기능 플래그에 연결할 수 있습니다. 기능 플래그 **연결된 이슈** 섹션에서 `+` 버튼을 선택하고 이슈 참조 번호 또는 이슈의 전체 URL을 입력합니다. 이슈는 관련 기능 플래그 및 반대 방향에 표시됩니다.

이 기능은 [연결된 이슈](../user/project/issues/related_issues.md) 기능과 유사합니다.

## 성능 요소 {#performance-factors}

GitLab 기능 플래그는 모든 애플리케이션에서 사용할 수 있습니다. 대규모 애플리케이션은 사전 구성이 필요할 수 있습니다. 이 섹션에서는 기능을 사용하기 전에 수행할 작업을 식별하는 데 도움이 되는 성능 요소를 설명합니다. 자세한 내용은 [기능 플래그 사용](#using-feature-flags)을 참조하세요.

### 애플리케이션 노드에서 지원되는 최대 클라이언트 수 {#maximum-supported-clients-in-application-nodes}

GitLab은 [속도 제한](../security/rate_limits.md)에 도달할 때까지 가능한 많은 클라이언트 요청을 수락합니다. 기능 플래그 API는 **Unauthenticated traffic (from a given IP address)**으로 간주됩니다. GitLab.com의 경우 [GitLab.com 특정 한계](../user/gitlab_com/_index.md)를 참조하세요.

폴링 속도는 SDK에서 구성할 수 있습니다. 모든 클라이언트가 동일한 IP에서 요청한다고 가정하면:

- 분당 1개 요청에서 약 500개 클라이언트(8 RPS)를 지원합니다.
- 15초마다 1개 요청에서 약 125개 클라이언트를 지원합니다.

더 확장 가능한 솔루션을 찾는 애플리케이션의 경우 [Unleash Proxy](#unleash-proxy-example)를 사용해야 합니다. GitLab.com에서는 Unleash Proxy를 사용하여 엔드포인트 전체에서 속도 제한될 수 있는 기회를 줄여야 합니다. 이 프록시 서버는 서버와 클라이언트 사이에 있습니다. 클라이언트 그룹을 대신하여 서버에 요청을 하므로 아웃바운드 요청의 수를 크게 줄일 수 있습니다. 여전히 `429` 응답을 받으면 Unleash Proxy의 `UNLEASH_FETCH_INTERVAL` 값을 증가시킵니다.

현재 속도 제한에 더 많은 용량을 제공하기 위한 [이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/295472)도 있습니다.

### 네트워크 오류에서 복구 {#recovering-from-network-errors}

일반적으로 [Unleash 클라이언트](https://github.com/Unleash/unleash#unleash-sdks)는 서버가 오류 코드를 반환할 때 폴백 메커니즘이 있습니다. 예를 들어 `unleash-ruby-client`는 로컬 백업에서 플래그 데이터를 읽어 애플리케이션이 현재 상태에서 계속 실행될 수 있도록 합니다.

자세한 내용은 SDK 프로젝트의 설명서를 참조하세요.

### GitLab Self-Managed {#gitlab-self-managed}

기능상 차이는 없습니다. GitLab.com과 GitLab Self-Managed 모두 동일하게 작동합니다.

확장성 측면에서 GitLab 인스턴스의 사양에 따라 달라집니다. GitLab.com은 많은 동시 요청을 처리하기 위해 고도로 확장된 아키텍처를 사용합니다.

그러나 [참조 아키텍처](../administration/reference_architectures/_index.md#additional-workloads)를 기반으로 용량이 부족한 GitLab Self-Managed 인스턴스는 비교할 수 있는 성능을 제공하지 못하며 기능 플래그 트래픽으로 오버로드될 수도 있습니다. 배포된 애플리케이션의 사용자 수를 _추가로_ GitLab 사용자 수를 고려합니다.
