---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 웹후크
description: "GitLab에서 프로젝트 및 그룹 웹후크를 구성하고 관리합니다."
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

웹후크는 실시간 알림을 통해 GitLab을 다른 도구 및 시스템과 연결합니다. GitLab에서 중요한 이벤트가 발생하면 웹후크는 해당 정보를 외부 애플리케이션으로 직접 전송합니다. 머지 리퀘스트, 코드 푸시 및 이슈 업데이트에 대응하여 자동화 워크플로우를 빌드합니다.

웹후크를 사용하면 변경 사항이 발생할 때 팀이 동기화된 상태를 유지합니다:

- GitLab 이슈가 변경될 때 외부 이슈 추적 도구가 자동으로 업데이트됩니다.
- 채팅 애플리케이션이 파이프라인 완료에 대해 팀원에게 알립니다.
- 사용자 지정 스크립트는 코드가 메인 브랜치에 도달할 때 애플리케이션을 배포합니다.
- 모니터링 시스템은 전체 조직의 개발 활동을 추적합니다.

## 웹후크 이벤트 {#webhook-events}

GitLab의 다양한 이벤트가 웹후크를 트리거할 수 있습니다. 예를 들어:

- 리포지토리에 코드 푸시.
- 이슈에 댓글 게시.
- 머지 리퀘스트 생성.

## 웹후크 제한 {#webhook-limits}

GitLab.com은 [웹후크 제한](../../gitlab_com/_index.md#webhooks)을 적용합니다:

- 프로젝트 또는 그룹당 최대 웹후크 수.
- 분당 웹후크 호출 수.
- 웹후크 시간 제한 기간.

GitLab Self-Managed의 경우 관리자가 이 제한을 수정할 수 있습니다.

### 푸시 이벤트 제한 {#push-event-limits}

GitLab은 여러 변경 사항을 포함하는 푸시 이벤트에 대한 웹후크 트리거를 제한합니다:

- 기본 제한:  푸시당 3개의 브랜치 또는 태그.
- 초과 시 동작:  전체 푸시 이벤트에 대해 웹후크가 트리거되지 않습니다.
- 적용 대상:  프로젝트 웹후크 및 시스템 훅 모두.
- 구성:  GitLab Self-Managed 관리자는 애플리케이션 설정 API를 통해 `push_event_hooks_limit` 설정을 수정할 수 있습니다.

자주 여러 태그 또는 브랜치를 동시에 푸시하고 웹후크 알림이 필요한 경우 GitLab 관리자에게 문의하여 이 제한을 높이세요.

## 그룹 웹후크 {#group-webhooks}

{{< details >}}

- 계층:  Premium, Ultimate

{{< /details >}}

그룹 웹후크는 그룹 및 해당 부분군의 모든 프로젝트에서 이벤트에 대한 알림을 보내는 사용자 지정 HTTP 콜백입니다.

### 그룹 웹후크 이벤트의 유형 {#types-of-group-webhook-events}

그룹 웹후크를 구성하여 다음을 수신하도록 할 수 있습니다:

- 그룹 및 부분군의 프로젝트에서 발생하는 모든 이벤트
- 그룹 멤버 이벤트, 프로젝트 이벤트 및 부분군 이벤트를 포함한 그룹별 이벤트

### 프로젝트 및 그룹 모두에서 웹후크 {#webhooks-in-both-a-project-and-a-group}

그룹과 해당 그룹의 프로젝트 모두에 동일한 웹후크를 구성하면 해당 프로젝트의 이벤트에 대해 두 웹후크가 트리거됩니다. 이를 통해 GitLab 조직의 다양한 수준에서 유연한 이벤트 처리가 가능합니다.

## 웹후크 구성 {#configure-webhooks}

GitLab에서 웹후크를 생성하고 구성하여 프로젝트 워크플로우와 통합합니다. 이 기능을 사용하여 특정 요구 사항을 충족하는 웹후크를 설정합니다.

### 웹후크 생성 {#create-a-webhook}

{{< history >}}

- **이름**과 **설명** [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141977) GitLab 16.9에서.
- **Signing token** 텍스트 상자 [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19367) GitLab 19.0에서 [with a flag](../../../administration/feature_flags/_index.md) `webhook_signing_token`라는 이름으로. 기본적으로 활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

새 웹후크의 경우 비밀 토큰 대신 서명 토큰을 사용합니다. 서명 토큰은 페이로드에 대한 HMAC-SHA256 서명을 계산하므로 엔드포인트가 요청의 진정성과 무결성을 모두 확인할 수 있습니다. 비밀 토큰은 헤더에 평문 값만 제공하며 보안 보장이 약합니다. 비밀 토큰은 새 웹후크에는 권장되지 않습니다.

웹후크를 생성하여 프로젝트 또는 그룹의 이벤트에 대한 알림을 보냅니다.

전제 조건:

- 프로젝트 웹후크의 경우 프로젝트에 대한 유지보수자 또는 소유자 역할이 있어야 합니다.
- 그룹 웹후크의 경우 그룹에 대한 소유자 역할이 있어야 합니다.

웹후크를 생성하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **Webhooks**를 선택합니다.
1. **새 webhook 추가**를 선택합니다.
1. **URL**에서 웹후크 엔드포인트의 URL을 입력합니다. 특수 문자에 대해 퍼센트 인코딩을 사용합니다.
1. 선택 사항. 웹후크에 대해 **이름**과 **설명**을 입력합니다.
1. 선택 사항. 요청 인증을 구성합니다. 더 강력한 보안을 위해 서명 토큰을 사용합니다:
   - **Signing token** (권장):  **Generate signing token**을 선택합니다. 지금 토큰을 복사하여 저장합니다. 한 번만 표시되기 때문입니다. 웹후크 엔드포인트는 이 토큰을 사용하여 [HMAC-SHA256 서명 확인](#verify-the-signature)할 수 있습니다.
   - **비밀 토큰** (권장되지 않음):  **비밀 토큰** 필드에 토큰을 입력합니다. 이 토큰은 `X-Gitlab-Token` HTTP 헤더에 평문으로 전송되며 서명 토큰보다 보안 보장이 약합니다. 새 웹후크의 경우 서명 토큰을 대신 사용합니다.
1. **트리거** 섹션에서 웹후크를 트리거할 이벤트를 선택합니다.
1. 선택 사항. SSL 검증을 비활성화하려면 **SSL 검증 활성화** 확인란을 취소합니다.
1. **webhook 추가**를 선택합니다.

### 서명 토큰 {#signing-tokens}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19367) GitLab 19.0에서 [with a flag](../../../administration/feature_flags/_index.md) `webhook_signing_token`라는 이름으로. 기본적으로 활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

웹후크 페이로드가 GitLab에서 시작되었고 변조되지 않았는지 확인하려면 서명 토큰을 사용합니다. 비밀 토큰과 달리 서명 토큰은 페이로드에 대한 HMAC-SHA256 서명을 계산하는 데 사용됩니다. 이는 받는 사람이 받은 페이로드의 진정성과 무결성을 독립적으로 확인할 수 있음을 의미합니다.

GitLab 웹후크 배달은 [Standard Webhooks](https://www.standardwebhooks.com/) 사양을 따릅니다. 모든 웹후크 요청에는 `webhook-id` 및 `webhook-timestamp` 헤더가 포함됩니다. 서명 토큰이 구성되면 GitLab은 HMAC-SHA256 서명과 함께 `webhook-signature` 헤더도 포함합니다. 각 서명의 형식은 `v1,{base64_signature}`입니다. 헤더는 여러 개의 공백으로 구분된 서명을 포함할 수 있습니다. GitLab은 현재 하나의 서명을 보내지만 향후 변경될 수 있습니다. 서명은 문자열 `{message_id}.{timestamp}.{body}`을 통해 계산되며:

- `{message_id}`은 `webhook-id` 헤더의 값입니다.
- `{timestamp}`은 `webhook-timestamp` 헤더의 값입니다.
- `{body}`은 원본 JSON 요청 본문입니다.

#### 서명 확인 {#verify-the-signature}

웹후크 엔드포인트에서 서명을 확인하려면:

1. `webhook-id`, `webhook-timestamp` 및 `webhook-signature` 헤더 값을 검색합니다.
1. `webhook-signature` 값을 공백으로 분할하여 서명 목록을 가져옵니다.
1. 메시지 문자열을 구성합니다: `"{message_id}.{timestamp}.{body}"`.
1. 서명 토큰 디코드: `whsec_` 접두사를 제거한 다음 base64로 디코드합니다.
1. 디코드된 키를 사용하여 HMAC-SHA256 다이제스트를 계산합니다.
1. 다이제스트를 base64로 인코드하고 `v1,`을 접두사로 붙입니다.
1. 계산된 서명이 서명 목록의 항목과 일치하는지 확인합니다. 타이밍 공격을 방지하기 위해 상수 시간 비교를 사용합니다.

Ruby의 예:

```ruby
require 'base64'
require 'openssl'

def valid_signature?(signing_token, message_id, timestamp, body, received_signatures)
  raw_key = Base64.strict_decode64(signing_token.delete_prefix('whsec_'))
  message = "#{message_id}.#{timestamp}.#{body}"
  digest = OpenSSL::HMAC.digest('sha256', raw_key, message)
  expected = "v1,#{Base64.strict_encode64(digest)}"
  received_signatures.split(' ').any? do |sig|
    ActiveSupport::SecurityUtils.secure_compare(expected, sig)
  end
end
```

Python의 예:

```python
import base64
import hashlib
import hmac

def valid_signature(signing_token, message_id, timestamp, body, received_signatures):
    raw_key = base64.b64decode(signing_token.removeprefix('whsec_'))
    message = f"{message_id}.{timestamp}.{body}".encode('utf-8')
    digest = hmac.new(raw_key, message, hashlib.sha256).digest()
    expected = "v1," + base64.b64encode(digest).decode('utf-8')
    return any(
        hmac.compare_digest(expected, sig)
        for sig in received_signatures.split(' ')
    )
```

#### 이전 버전과의 호환성 {#backward-compatibility}

서명 토큰은 기존 비밀 토큰과 함께 작동합니다. 같은 웹후크에서 둘 다 구성할 수 있습니다:

- `X-Gitlab-Token` 헤더는 비밀 토큰이 구성되면 계속 전송됩니다.
- `webhook-signature` 및 `webhook-id` 헤더는 서명 토큰이 구성되면 전송됩니다.

비밀 토큰을 사용하는 기존 웹후크를 서명 토큰으로 다운타임 없이 마이그레이션하려면 전환 중에 같은 웹후크에서 두 토큰을 구성합니다. `webhook-signature`이 있을 때 서명을 확인하고 그렇지 않으면 비밀 토큰으로 돌아가도록 수신기를 업데이트합니다.

수신기가 서명을 올바르게 처리하면 웹후크 설정에서 비밀 토큰을 제거할 수 있습니다.

#### 보안 고려사항 {#security-considerations}

재생 공격을 방지하려면 페이로드를 처리하기 전에 `webhook-timestamp`의 타임스탬프가 최근인지 확인합니다.

서명 토큰은 API에서 절대 반환되지 않습니다.

### 웹후크 URL의 민감한 부분 마스킹 {#mask-sensitive-portions-of-webhook-urls}

보안을 강화하기 위해 웹후크 URL의 민감한 부분을 마스킹합니다. 마스킹된 부분은 웹후크가 실행될 때 구성된 값으로 바뀌고, 로깅되지 않으며, 데이터베이스에서 암호화되어 저장됩니다.

웹후크 URL의 민감한 부분을 마스킹하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **Webhooks**를 선택합니다.
1. **URL**에 웹후크의 전체 URL을 입력합니다.
1. 마스킹된 부분을 정의하려면 **Add URL masking**을 선택합니다.
1. **URL의 민감한 부분**에서 마스킹할 URL 부분을 입력합니다.
1. **UI에서 보이는 방식**에서 마스킹된 부분 대신 표시할 값을 입력합니다. 변수 이름은 소문자(`a-z`), 숫자(`0-9`) 또는 밑줄(`_`)만 포함해야 합니다.
1. **변경사항 저장**을 선택합니다.

마스킹된 값은 UI에서 숨겨진 상태로 나타납니다. 예를 들어 `path` 및 `value` 변수를 정의한 경우 웹후크 URL은 다음과 같이 보일 수 있습니다:

```plaintext
https://webhook.example.com/{path}?key={value}
```

### 사용자 정의 헤더 {#custom-headers}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146702) GitLab 16.11에서 [with a flag](../../../administration/feature_flags/_index.md) `custom_webhook_headers`라는 이름으로. 기본적으로 활성화됨.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/448604) GitLab 17.0에서. 기능 플래그 `custom_webhook_headers` 제거됨.

{{< /history >}}

외부 서비스 인증을 위해 웹후크 요청에 사용자 정의 헤더를 추가합니다. 웹후크당 최대 20개의 사용자 정의 헤더를 구성할 수 있습니다.

사용자 정의 헤더는 다음을 충족해야 합니다:

- 배달 헤더의 값을 재정의하지 않습니다.
- 영숫자 문자, 마침표, 대시 또는 밑줄만 포함합니다.
- 문자로 시작하고 문자 또는 숫자로 끝나야 합니다.
- 연속된 마침표, 대시 또는 밑줄이 없습니다.

사용자 정의 헤더는 **최근 이벤트**에 마스킹된 값으로 표시됩니다.

### 사용자 정의 웹후크 템플릿 {#custom-webhook-template}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142738) GitLab 16.10에서 [with a flag](../../../administration/feature_flags/_index.md) `custom_webhook_template`라는 이름으로. 기본적으로 활성화됨.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/439610) GitLab 17.0에서. 기능 플래그 `custom_webhook_template` 제거됨.
- 보간된 필드 값의 JSON 직렬화 [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197992) GitLab 18.4에서 [with a flag](../../../administration/feature_flags/_index.md) `custom_webhook_template_serialization`라는 이름으로. 기본적으로 비활성화됨.
- 보간된 필드 값의 JSON 직렬화 [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212407) GitLab 18.6에서. 기능 플래그 `custom_webhook_template_serialization` 기본적으로 활성화됨.
- 기능 플래그 `custom_webhook_template_serialization` [removed](https://gitlab.com/gitlab-org/gitlab/-/work_items/580460) GitLab 18.10에서.

{{< /history >}}

요청 본문에 전송되는 데이터를 제어하기 위해 웹후크에 대한 사용자 정의 페이로드 템플릿을 생성합니다.

#### 사용자 정의 웹후크 템플릿 생성 {#create-a-custom-webhook-template}

- 프로젝트 웹후크의 경우 프로젝트에 대한 유지보수자 또는 소유자 역할이 있어야 합니다.
- 그룹 웹후크의 경우 그룹에 대한 소유자 역할이 있어야 합니다.

사용자 정의 웹후크 템플릿을 생성하려면:

1. 웹후크 구성으로 이동합니다.
1. 사용자 정의 웹후크 템플릿을 설정합니다.
1. 템플릿이 유효한 JSON으로 렌더링되는지 확인합니다.

템플릿의 이벤트 페이로드에서 필드를 사용합니다. 예를 들어:

- 작업 이벤트에 `{{build_name}}`
- 배포 이벤트에 `{{deployable_url}}`

중첩된 속성에 액세스하려면 마침표를 사용하여 경로 세그먼트를 분리합니다.

#### 사용자 정의 웹후크 템플릿 예제 {#example-custom-webhook-template}

이 사용자 정의 페이로드 템플릿의 경우:

```json
{
  "event": "{{object_kind}}",
  "project_name": "{{project.name}}"
}
```

`push` 이벤트에 대한 결과 요청 페이로드는:

```json
{
  "event": "push",
  "project_name": "Example"
}
```

사용자 정의 웹후크 템플릿은 배열의 속성에 액세스할 수 없습니다.

### 브랜치별로 푸시 이벤트 필터링 {#filter-push-events-by-branch}

`push` 이벤트를 브랜치 이름으로 웹후크 엔드포인트로 보낸 것을 필터링합니다. 다음 필터링 옵션 중 하나를 사용합니다:

- **모든 브랜치**:  모든 브랜치에서 푸시 이벤트를 수신합니다.
- **와일드카드 패턴**:  와일드카드 패턴과 일치하는 브랜치에서 푸시 이벤트를 수신합니다.
- **정규식**:  정규식(regex)과 일치하는 브랜치에서 푸시 이벤트를 수신합니다.

#### 와일드카드 패턴 사용 {#use-a-wildcard-pattern}

와일드카드 패턴을 사용하여 필터링하려면:

1. 웹후크 구성에서 **와일드카드 패턴**을 선택합니다.
1. 패턴을 입력합니다. 예를 들어:
   - `*-stable`은(는) `-stable`로 끝나는 브랜치와 일치합니다.
   - `production/*`은(는) `production/` 네임스페이스의 브랜치와 일치합니다.

#### 정규식 사용 {#use-a-regular-expression}

정규식을 사용하여 필터링하려면:

1. 웹후크 구성에서 **정규식**을 선택합니다.
1. [RE2 syntax](https://github.com/google/re2/wiki/Syntax)를 따르는 정규식 패턴을 입력합니다.

예를 들어, `main` 브랜치를 제외하려면 다음을 사용합니다:

```plaintext
\b(?:m(?!ain\b)|ma(?!in\b)|mai(?!n\b)|[a-l]|[n-z])\w*|\b\w{1,3}\b|\W+
```

### 웹후크에서 상호 TLS 지원 {#configure-webhooks-to-support-mutual-tls}

{{< details >}}

- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27450) GitLab 16.9에서.

{{< /history >}}

PEM 형식의 글로벌 클라이언트 인증서를 설정하여 웹후크가 상호 TLS를 지원하도록 구성합니다.

전제 조건:

- GitLab 관리자여야 합니다.

웹후크에 대해 상호 TLS를 구성하려면:

1. PEM 형식의 클라이언트 인증서를 준비합니다.
1. 선택 사항. 인증서를 PEM 암호문으로 보호합니다.
1. GitLab을 구성하여 인증서를 사용합니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 편집합니다:

   ```ruby
   gitlab_rails['http_client']['tls_client_cert_file'] = '<PATH TO CLIENT PEM FILE>'
   gitlab_rails['http_client']['tls_client_cert_password'] = '<OPTIONAL PASSWORD>'
   ```

1. 파일을 저장하고 GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을(를) 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       image: 'gitlab/gitlab-ee:latest'
       restart: always
       hostname: 'gitlab.example.com'
       environment:
         GITLAB_OMNIBUS_CONFIG: |
            gitlab_rails['http_client']['tls_client_cert_file'] = '<PATH TO CLIENT PEM FILE>'
            gitlab_rails['http_client']['tls_client_cert_password'] = '<OPTIONAL PASSWORD>'
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
     http_client:
       tls_client_cert_file: '<PATH TO CLIENT PEM FILE>'
       tls_client_cert_password: '<OPTIONAL PASSWORD>'
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

구성 후 GitLab은 웹후크 연결의 TLS 핸드셰이크 중에 이 인증서를 서버에 제시합니다.

### 웹후크 트래픽을 위한 방화벽 구성 {#configure-firewalls-for-webhook-traffic}

GitLab이 웹후크를 보내는 방식에 따라 웹후크 트래픽을 위한 방화벽을 구성합니다:

- Sidekiq 노드에서 비동기적으로 (가장 일반적)
- Rails 노드에서 동기적으로 (특정 경우)

UI에서 웹후크를 테스트하거나 재시도할 때 웹후크는 Rails 노드에서 동기적으로 전송됩니다.

방화벽을 구성할 때 Sidekiq 및 Rails 노드가 모두 웹후크 트래픽을 보낼 수 있는지 확인합니다.

## 웹후크 관리 {#manage-webhooks}

GitLab에서 구성된 웹후크를 모니터링하고 유지관리합니다.

### 웹후크 요청 기록 보기 {#view-webhook-request-history}

웹후크 요청의 기록을 보아 성능을 모니터링하고 문제를 해결합니다.

전제 조건:

- 프로젝트 웹후크의 경우 프로젝트에 대한 유지보수자 또는 소유자 역할이 있어야 합니다.
- 그룹 웹후크의 경우 그룹에 대한 소유자 역할이 있어야 합니다.

웹후크의 요청 기록을 보려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **Webhooks**를 선택합니다.
1. 웹후크에 대해 **편집**을 선택합니다.
1. **최근 이벤트** 섹션으로 이동합니다.

**최근 이벤트** 섹션은 지난 2일 동안 웹후크에 대한 모든 요청을 표시합니다. 표에는 다음이 포함됩니다:

- HTTP 상태 코드:
  - `200`-`299` 코드의 경우 녹색
  - 다른 코드의 경우 빨간색
  - 실패한 배달의 경우 `internal error`
- 트리거된 이벤트
- 요청의 경과 시간
- 요청이 이루어진 상대 시간

![웹후크 이벤트 로그 - 상태 코드 및 응답 시간 표시](img/webhook_logs_v14_4.png)

#### 요청 및 응답 세부정보 검사 {#inspect-request-and-response-details}

전제 조건:

- 프로젝트 웹후크의 경우 프로젝트에 대한 유지보수자 또는 소유자 역할이 있어야 합니다.
- 그룹 웹후크의 경우 그룹에 대한 소유자 역할이 있어야 합니다.

**최근 이벤트**의 각 웹후크 요청에는 **세부정보 요청** 페이지가 있습니다. 이 페이지에는 다음의 본문과 헤더가 포함됩니다:

- GitLab이 웹후크 수신자 엔드포인트에서 받은 응답
- GitLab이 보낸 웹후크 요청

웹후크 이벤트의 요청 및 응답 세부정보를 검사하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **Webhooks**를 선택합니다.
1. 웹후크에 대해 **편집**을 선택합니다.
1. **최근 이벤트** 섹션으로 이동합니다.
1. 이벤트에 대해 **상세 보기**를 선택합니다.

같은 데이터와 같은 `Idempotency-Key` 헤더로 요청을 다시 보내려면 **요청 재전송**을 선택합니다. 웹후크 URL이 변경된 경우 요청을 재전송할 수 없습니다. 프로젝트 웹후크 API를 통해 프로그래밍 방식으로 요청을 재전송할 수도 있습니다.

### 웹후크 테스트 {#test-a-webhook}

웹후크가 제대로 작동하는지 확인하거나 비활성화된 웹후크를 다시 활성화하려면 웹후크를 테스트합니다.

전제 조건:

- 프로젝트 웹후크의 경우 프로젝트에 대한 유지보수자 또는 소유자 역할이 있어야 합니다.
- 그룹 웹후크의 경우 그룹에 대한 소유자 역할이 있어야 합니다.
- `push events`를 테스트하려면 프로젝트에 최소 한 개의 커밋이 있어야 합니다.

웹후크를 테스트하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **Webhooks**를 선택하여 이 프로젝트의 모든 웹후크를 봅니다.
1. 구성된 웹후크 목록에서 직접 웹후크를 테스트하려면:
   1. 테스트할 웹후크를 찾습니다.
   1. **테스트** 드롭다운 목록에서 테스트할 이벤트 유형을 선택합니다.
1. 웹후크를 편집하면서 테스트하려면:
   1. 테스트할 웹후크를 찾고 **편집**을 선택합니다.
   1. 웹후크를 변경합니다.
   1. **테스트** 드롭다운 목록을 선택한 다음 테스트할 이벤트 유형을 선택합니다.

프로젝트 및 그룹 웹후크의 일부 이벤트 유형에는 테스트가 지원되지 않습니다. 자세한 내용은 [이슈 379201](https://gitlab.com/gitlab-org/gitlab/-/issues/379201)을 참조하세요.

## 웹후크 참조 {#webhook-reference}

이 기술 참조를 사용하여:

- GitLab 웹후크가 작동하는 방식을 이해합니다.
- 시스템과 웹후크를 통합합니다.
- 웹후크 구성을 설정, 문제 해결 및 최적화합니다.

### 웹후크 수신자 요구 사항 {#webhook-receiver-requirements}

안정적인 웹후크 배달을 보장하기 위해 빠르고 안정적인 웹후크 수신자 엔드포인트를 구현합니다.

느리거나 불안정하거나 잘못 구성된 수신자는 자동으로 비활성화될 수 있습니다. 잘못된 HTTP 응답은 실패한 요청으로 간주됩니다.

웹후크 수신자를 최적화하려면:

1. `200` 또는 `201` 상태로 빠르게 응답합니다:
   - 같은 요청에서 웹후크 처리를 피합니다.
   - 웹후크를 수신한 후 처리하기 위해 큐를 사용합니다.
   - GitLab.com에서 자동 비활성화를 방지하기 위해 시간 제한 전에 응답합니다.
1. 잠재적 중복 이벤트 처리:
   - 웹후크 시간 초과 시 중복 이벤트에 대비합니다.
   - 엔드포인트가 일관되게 빠르고 안정적인지 확인합니다.
1. 응답 헤더 및 본문 최소화:
   - GitLab은 나중에 검사하기 위해 응답 헤더 및 본문을 저장합니다.
   - 반환된 헤더의 수 및 크기를 제한합니다.
   - 빈 본문으로 응답하는 것을 고려합니다.
1. 적절한 상태 코드를 사용합니다:
   - 클라이언트 오류 상태 응답(`4xx` 범위)을 잘못 구성된 웹후크에만 반환합니다.
   - 지원되지 않는 이벤트의 경우 `400`을 반환하거나 페이로드를 무시합니다.
   - 처리된 이벤트에 대해 `500` 서버 오류 응답을 피합니다.

### 자동 비활성화 웹후크 {#auto-disabled-webhooks}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385902) GitLab 15.10에서 그룹 웹후크용.
- [Disabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/390157) GitLab 15.10에서 프로젝트 웹후크용 [with a flag](../../../administration/feature_flags/_index.md) `auto_disabling_web_hooks`라는 이름으로.
- **Fails to connect** 및 **Failing to connect** [renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166329) **비활성화됨** 및 **일시적으로 비활성됨** GitLab 17.11에서.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166329) GitLab 17.11에서 40번의 연속 실패 후 영구적으로 비활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

GitLab은 4번의 연속 실패가 발생한 프로젝트 또는 그룹 웹후크를 자동으로 비활성화합니다.

자동 비활성화 웹후크를 보려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **Webhooks**를 선택합니다.

웹후크 목록에서 자동 비활성화 웹후크는 다음과 같이 표시됩니다:

- 4번의 연속 실패 시 **일시적으로 비활성됨**
- 40번의 연속 실패 시 **비활성화됨**

![웹후크 목록 - 비활성화됨 및 일시적으로 비활성됨 상태 배지 표시.](img/failed_badges_v17_11.png)

#### 일시적으로 비활성화된 웹후크 {#temporarily-disabled-webhooks}

웹후크는 4번의 연속 실패 시 일시적으로 비활성화됩니다. 웹후크가 40번의 연속 실패 시 영구적으로 비활성화됩니다.

다음의 경우 실패가 발생합니다:

- 웹후크 수신자가 `4xx` 또는 `5xx` 범위의 응답 코드를 반환합니다.
- 웹후크가 웹후크 수신자에 연결을 시도할 때 시간 초과가 발생합니다.
- 웹후크에 다른 HTTP 오류가 발생합니다.

일시적으로 비활성화된 웹후크는 처음에 1분 동안 비활성화되며 이후 실패 시 최대 24시간까지 기간이 연장됩니다. 이 기간이 경과한 후 이러한 웹후크는 자동으로 다시 활성화됩니다.

#### 영구적으로 비활성화된 웹후크 {#permanently-disabled-webhooks}

웹후크는 40번의 연속 실패 시 영구적으로 비활성화됩니다. 일시적으로 비활성화된 웹후크와 달리 이러한 웹후크는 자동으로 다시 활성화되지 않습니다.

GitLab 17.10 이전에 영구적으로 비활성화된 웹후크는 데이터 마이그레이션을 거쳤습니다. 이러한 웹후크는 UI가 40번의 실패를 나타낼 수 있지만 **최근 이벤트**에 4번의 실패를 표시할 수 있습니다.

#### 비활성화된 웹후크 다시 활성화 {#re-enable-disabled-webhooks}

비활성화된 웹후크를 다시 활성화하려면 테스트 요청을 보냅니다. 테스트 요청이 `2xx` 범위의 응답 코드를 반환하면 웹후크가 다시 활성화됩니다.

### 배달 헤더 {#delivery-headers}

{{< history >}}

- `X-Gitlab-Webhook-UUID` 헤더 [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/230830) GitLab 16.2에서.
- `Idempotency-Key` 헤더 [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/388692) GitLab 17.4에서.
- `webhook-id` 및 `webhook-timestamp` 헤더 [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19367) GitLab 19.0에서.
- `webhook-signature` 헤더 [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19367) GitLab 19.0에서 [with a flag](../../../administration/feature_flags/_index.md) `webhook_signing_token`라는 이름으로. 기본적으로 활성화됨.

{{< /history >}}

GitLab은 엔드포인트에 대한 웹후크 요청에 다음 헤더를 포함합니다.

> [!flag]
> `webhook-signature` 헤더의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

| 헤더                   | 설명                                                                                                                                                     | 예제 |
|:-------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------|:--------|
| `Idempotency-Key`        | 웹후크 재시도 간 일관된 고유 ID. 이전 버전 호환성을 위해 사용 가능합니다. `webhook-id`을 권장합니다.                                                                 | `"f5e5f430-f57b-4e6e-9fac-d9128cd7232f"` |
| `User-Agent`             | `"Gitlab/<VERSION>"` 형식의 사용자 에이전트.                                                                                                                  | `"GitLab/15.5.0-pre"` |
| `webhook-id`             | 웹후크 재시도 간 일관된 고유 메시지 ID. `Idempotency-Key`과(와) 같습니다.                                                                                | `"f5e5f430-f57b-4e6e-9fac-d9128cd7232f"` |
| `webhook-signature`      | 각각 `v1,{base64_signature}` 형식의 HMAC-SHA256 서명의 공백으로 분리된 목록. [서명 토큰](#signing-tokens)이 구성될 때만 포함됩니다. | `"v1,abc123def456=="` |
| `webhook-timestamp`      | 요청이 생성된 시간의 Unix 타임스탬프 (에포크 이후 초).                                                                                            | `"1744578123"` |
| `X-Gitlab-Event-UUID`    | 재귀적이지 않은 웹후크에 대한 고유 ID. 재귀적 웹후크 (이전 웹후크에 의해 트리거됨)는 같은 값을 공유합니다.                                                  | `"13792a34-cac6-4fda-95a8-c58e00a3954e"` |
| `X-Gitlab-Event`         | 웹후크 유형 이름. `"<EVENT> Hook"` 형식의 이벤트 유형과 해당합니다.                                                                                   | `"Push Hook"` |
| `X-Gitlab-Instance`      | 웹후크를 보낸 GitLab 인스턴스의 호스트 이름.                                                                                                          | `"https://gitlab.com"` |
| `X-Gitlab-Token`         | 웹후크에 대한 비밀 토큰 - 평문으로 전송됨. 비밀 토큰이 구성될 때만 포함됩니다.                                                              | `"my-secret-token"` |
| `X-Gitlab-Webhook-UUID`  | 각 웹후크에 대한 고유 ID.                                                                                                                                     | `"02affd2d-2cba-4033-917d-ec22d5dc4b38"` |

### 웹후크 본문에서 이미지 URL 표시 {#image-url-display-in-webhook-body}

GitLab은 웹후크 본문에서 상대 이미지 참조를 절대 URL로 다시 씁니다.

#### 이미지 URL 다시 쓰기 예제 {#image-url-rewriting-example}

머지 리퀘스트, 댓글 또는 위키 페이지의 원본 이미지 참조가 다음인 경우:

```markdown
![A Markdown image with a relative URL.](/uploads/$sha/image.png)
```

웹후크 본문의 다시 작성된 이미지 참조는:

```markdown
![A Markdown image with an absolute URL.](https://gitlab.example.com/-/project/:id/uploads/<SHA>/image.png)
```

이 예제는 다음을 가정합니다:

- GitLab은 `gitlab.example.com`에 설치됩니다.
- 프로젝트 ID는 `123`입니다.

#### 이미지 URL 다시 쓰기의 예외 {#exceptions-to-image-url-rewriting}

GitLab은 다음의 경우 이미지 URL을 다시 쓰지 않습니다:

- 이미 HTTP, HTTPS 또는 프로토콜 상대 URL을 사용합니다.
- 링크 레이블과 같은 고급 Markdown 기능을 사용합니다.

## 관련 항목 {#related-topics}

- [웹후크 이벤트 및 JSON 페이로드](webhook_events.md)
- [웹후크 제한](../../gitlab_com/_index.md#webhooks)
- [프로젝트 웹후크 API](../../../api/project_webhooks.md)
- [그룹 웹후크 API](../../../api/group_webhooks.md)
- [시스템 훅 API](../../../api/system_hooks.md)
- [웹후크 문제 해결](webhooks_troubleshooting.md)
- [Twilio를 사용하여 웹후크로 SMS 경고 보내기](https://www.datadoghq.com/blog/send-alerts-sms-customizable-webhooks-twilio/)
- [GitLab 레이블 자동 적용](https://about.gitlab.com/blog/applying-gitlab-labels-automatically/)
