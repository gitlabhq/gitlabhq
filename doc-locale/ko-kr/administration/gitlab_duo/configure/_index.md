---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab 인스턴스용 GitLab Duo를 구성합니다.
title: GitLab Duo 구성
---

{{< details >}}

- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab Duo는 소프트웨어 개발 생애 주기 전반에서 도움을 주는 AI 기반 어시스턴트입니다.

GitLab Duo를 다음과 같이 구성할 수 있습니다:

- 클라우드 기반 AI Gateway(기본값):  GitLab에서 호스팅하는 AI Gateway와 공급업체 언어 모델입니다.
- 자체 호스팅 모델:  데이터와 보안에 대한 완전한 제어를 위해 자신의 AI Gateway와 언어 모델을 사용합니다.
- 하이브리드 구성:  일부 기능은 자체 호스팅 모델을 사용하고 다른 기능은 클라우드 기반 모델을 사용합니다.

## 필수 요구 사항 {#prerequisites}

- Silent Mode는 [해제](../../silent_mode/_index.md#turn-off-silent-mode)되어 있습니다.
- [인스턴스가 활성화 코드로 활성화됨](../../license.md#activate-gitlab-ee).
  - 라이센스 키를 사용할 수 없습니다.
  - [GitLab Duo Self-Hosted](../../gitlab_duo_self_hosted/_index.md) 예외를 제외하고는 오프라인 라이센스로 GitLab Duo를 사용할 수 없습니다.

## GitLab 인스턴스에서 GitLab Duo로의 아웃바운드 연결 허용 {#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo}

- GitLab 애플리케이션 노드는 `https://duo-workflow-svc.runway.gitlab.net`에서 GitLab Duo Workflow에 HTTP/2로 연결해야 합니다. 애플리케이션과 서비스는 gRPC로 통신합니다.
- GitLab Duo Agent Platform 기능의 경우 방화벽 및 HTTP/S 프록시 서버는 `duo-workflow-svc.runway.gitlab.net`에 대한 아웃바운드 연결을 `443` 포트에서 `https://`로 허용하고 HTTP/2 트래픽을 지원해야 합니다.

## 클라이언트에서 GitLab 인스턴스로의 인바운드 연결 허용 {#allow-inbound-connections-from-clients-to-the-gitlab-instance}

GitLab 인스턴스는 IDE 클라이언트에서의 인바운드 연결을 허용해야 합니다.

1. 다음 헤더를 포함한 WebSocket Protocol 업그레이드 요청을 허용합니다:
   - `Connection: upgrade`
   - `Upgrade: websocket`
   - `HTTP/2` 프로토콜 지원
   - 표준 WebSocket 보안 헤더: `Sec-WebSocket-*`
1. `wss://`(WebSocket Secure) 프로토콜 지원을 활성화합니다.
1. 허용할 특정 엔드포인트를 추가합니다:
   - 주요 엔드포인트: `wss://<customer-instance>/-/cable`
   - `HTTP/2` 프로토콜이 `HTTP/1.1`로 다운그레이드되지 않도록 합니다.
   - 포트:  `443`(HTTPS/WSS)

문제가 있으면:

- `wss://gitlab.example.com/-/cable`에 대한 WebSocket 트래픽 제한과 다른 `.com` 도메인을 확인합니다.
- Apache와 같은 역방향 프록시를 사용하는 경우 로그에서 **WebSocket connection to .... failures**와 같은 GitLab Duo Chat 연결 문제가 나타날 수 있습니다.

이 문제를 해결하려면 프록시 설정을 편집합니다:

```apache
# Enable WebSocket reverse Proxy
# Needs proxy_wstunnel enabled
  RewriteCond %{HTTP:Upgrade} websocket [NC]
  RewriteCond %{HTTP:Connection} upgrade [NC]
  RewriteRule ^/?(.*) "ws://127.0.0.1:8181/$1" [P,L]
```

## 러너에서의 연결 허용 {#allow-connections-from-the-runner}

플로우와 같이 러너를 활용하는 GitLab Duo Agent Platform 기능의 경우 러너는 GitLab 인스턴스에 연결할 수 있어야 합니다.

동일한 [클라이언트에서 GitLab 인스턴스로의 인바운드 연결](#allow-inbound-connections-from-clients-to-the-gitlab-instance)을 러너에서 GitLab 인스턴스로의 아웃바운드 연결로 허용해야 합니다.

또한 러너는 다음에 연결할 수 있어야 합니다:

| 대상 | 포트 | 목적 |
|-------------|------|---------|
| `registry.npmjs.org` | `443` | 런타임에 Duo CLI 패키지 다운로드 |
| `registry.gitlab.com` | `443` | 기본 Docker 이미지 다운로드([사용자 지정 이미지](../../../user/duo_agent_platform/flows/execution.md#change-the-default-docker-image) 사용 제외) |

조직에서 공개 npm 레지스트리에 대한 액세스를 허용할 수 없으면 필요한 종속성이 이미 설치된 [사용자 지정 Docker 이미지](../../../user/duo_agent_platform/flows/execution.md#change-the-default-docker-image)를 사용할 수 있습니다.

## GitLab과 사용량 데이터 공유 {#share-usage-data-with-gitlab}

{{< history >}}

- GitLab 18.9.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/587976)됨.

{{< /history >}}

서비스 품질을 개선하기 위해 GitLab Duo Agent Platform 기능에 대한 사용량 데이터를 GitLab과 공유할 수 있습니다.

데이터 수집을 켜면 GitLab은 GitLab Duo 기능 사용에 대한 정보를 기록합니다. 이 데이터는 서비스 개선 및 디버깅에만 사용되며 AI 모델 학습에는 사용되지 않습니다.

수집된 데이터에 대한 자세한 내용은 [Agent Platform 사용량 데이터](../../../user/gitlab_duo/data_usage.md#agent-platform-usage-data)를 참조하세요.

전제 조건:

- GitLab 18.9.1 이상 필요

확장 로깅을 켜려면:

1. 오른쪽 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **사용량 데이터 수집** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### 자체 호스팅 모델의 데이터 사용 {#data-usage-with-self-hosted-models}

자체 호스팅 AI Gateway 및 자체 호스팅 모델을 사용하면 상세 로그는 인프라에 저장되며 GitLab과 공유되지 않습니다. GitLab과 데이터를 공유하려면 자체 호스팅 AI Gateway를 구성하여 외부 관찰성 서비스로 추적을 전송해야 합니다.

[Service Ping](../../settings/usage_statistics.md#service-ping)을 사용하여 GitLab에 사용량 데이터를 전송할 수 있습니다. 이 데이터는 [원격 측정 데이터](../../../user/gitlab_duo/data_usage.md#telemetry)와 다릅니다.

## GitLab Duo에 대한 헬스 체크 실행 {#run-a-health-check-for-gitlab-duo}

{{< details >}}

- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161997)됨.
- GitLab 17.5에서 [헬스 체크 보고서 다운로드 추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165032).

{{< /history >}}

인스턴스가 GitLab Duo를 사용하기 위한 요구 사항을 충족하는지 확인할 수 있습니다. 헬스 체크가 완료되면 통과 또는 실패 결과와 문제 유형을 표시합니다. 헬스 체크가 테스트 중 하나라도 실패하면 사용자가 인스턴스에서 GitLab Duo 기능을 사용하지 못할 수 있습니다.

이것은 [베타](../../../policy/development_stages_support.md) 기능입니다.

전제 조건:

- 관리자여야 합니다.

헬스 체크를 실행하려면:

1. 오른쪽 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. 우측 상단 모서리에서 **헬스 체크 실행**을 선택합니다.
1. 선택사항. GitLab 17.5 이상에서 헬스 체크가 완료된 후 **보고서 다운로드**를 선택하여 헬스 체크 결과의 상세 보고서를 저장할 수 있습니다.

다음 테스트가 수행됩니다:

| 테스트                      | 설명 |
|---------------------------|-------------|
| AI Gateway                | GitLab Duo Self-Hosted 모델만 해당합니다. AI Gateway URL이 환경 변수로 구성되어 있는지 테스트합니다. 이 연결은 AI Gateway를 사용하는 자체 호스팅 모델 배포에 필요합니다. |
| 네트워크                   | 인스턴스가 `customers.gitlab.com`와 `cloud.gitlab.com`에 연결할 수 있는지 테스트합니다.<br><br>인스턴스가 어느 대상에도 연결할 수 없으면 방화벽 또는 프록시 서버 설정이 [연결을 허용](#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo)하는지 확인합니다. |
| 동기화           | 구독이 다음 요건을 충족하는지 테스트합니다: <br>\- 활성화 코드로 활성화되었으며 `customers.gitlab.com`과 동기화할 수 있습니다.<br>\- 올바른 액세스 자격 증명이 있습니다.<br>\- 최근에 동기화되었습니다. 그렇지 않거나 액세스 자격 증명이 누락되었거나 만료된 경우 [수동으로 동기화](../../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)할 수 있습니다. |
| Code Suggestions          | GitLab Duo Self-Hosted 모델만 해당합니다. Code Suggestions를 사용할 수 있는지 테스트합니다: <br>\- 라이센스에 Code Suggestions에 대한 액세스가 포함되어 있습니다.<br>\- 기능을 사용할 수 있는 필요한 권한이 있습니다. |
| GitLab Duo AI 에이전트 플랫폼 | 백엔드 서비스가 운영 중이고 액세스 가능한지 테스트합니다. 이 서비스는 Agent Platform 및 GitLab Duo Agentic Chat과 같은 에이전트 기능에 필요합니다. |
| 시스템 교환           | Code Suggestions을 인스턴스에서 사용할 수 있는지 테스트합니다. 시스템 교환 평가에 실패하면 사용자가 인스턴스에서 GitLab Duo 기능을 사용하지 못할 수 있습니다. |

GitLab 버전 17.10 이전의 인스턴스에서 헬스 체크에 문제가 있는 경우 [문제 해결 페이지](../../../user/gitlab_duo/troubleshooting.md)를 참조하세요.

## 기타 호스팅 옵션 {#other-hosting-options}

기본적으로 GitLab Duo는 지원되는 AI 공급업체 언어 모델을 사용하고 GitLab에서 호스팅하는 클라우드 기반 AI Gateway를 통해 데이터를 전송합니다.

자신의 언어 모델이나 AI Gateway를 호스팅하려는 경우:

- [GitLab Duo Self-Hosted를 사용하여 AI Gateway를 호스팅하고 지원되는 자체 호스팅 모델을 사용](../../gitlab_duo_self_hosted/_index.md#self-hosted-ai-gateway-and-llms)할 수 있습니다. 이 옵션은 데이터 및 보안에 대한 완전한 제어를 제공합니다.
- [하이브리드 구성](../../gitlab_duo_self_hosted/_index.md#hybrid-ai-gateway-and-model-configuration)을 사용합니다. 여기서 일부 기능에 대해 자신의 AI Gateway 및 모델을 호스팅하지만 다른 기능은 GitLab AI Gateway 및 공급업체 모델을 사용하도록 구성합니다.

## 관련 항목 {#related-topics}

- [GitLab Duo 기능 요약](../../../user/gitlab_duo/feature_summary.md)
- [GitLab Duo 가용성 제어](../../../user/gitlab_duo/turn_on_off.md)
- [GitLab Duo 문제 해결](../../../user/gitlab_duo/troubleshooting.md)
