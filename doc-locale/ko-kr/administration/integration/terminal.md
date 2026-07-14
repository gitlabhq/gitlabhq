---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 웹 터미널(더 이상 사용되지 않음)
description: 웹 터미널에 대한 정보입니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- 이 기능은 GitLab 14.5에서 [더 이상 사용되지 않습니다](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).
- [GitLab Self-Managed에서 비활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/353410)(GitLab 15.0).

{{< /history >}}

> [!flag]
> GitLab Self-Managed에서는 기본적으로 이 기능을 사용할 수 없습니다. 이를 사용 가능하게 하려면 관리자가 [기능 플래그 활성화](../feature_flags/_index.md)(`certificate_based_clusters`)를 수행할 수 있습니다.

- [Web IDE를 통해 액세스할 수 있는 웹 터미널](../../user/project/web_ide/_index.md)에 대해 자세히 알아보세요.
- 실행 중인 작업에서 액세스할 수 있는 [웹 터미널](../../ci/interactive_web_terminal/_index.md)에 대해 자세히 알아보세요.

---

[Kubernetes 통합](../../user/infrastructure/clusters/_index.md) 도입으로 GitLab은 Kubernetes 클러스터의 자격 증명을 저장하고 사용할 수 있습니다. GitLab은 이러한 자격 증명을 사용하여 환경에 대한 [웹 터미널](../../ci/environments/_index.md#web-terminals-deprecated) 액세스를 제공합니다.

> [!note]
> 프로젝트의 [유지보수자 역할](../../user/permissions.md) 이상 권한을 가진 사용자만 웹 터미널에 액세스할 수 있습니다.

## 웹 터미널의 작동 방식 {#how-web-terminals-work}

웹 터미널의 아키텍처 및 작동 방식에 대한 자세한 개요는 [이 문서](https://gitlab.com/gitlab-org/gitlab-workhorse/blob/master/doc/channel.md)에서 확인할 수 있습니다. 요약하면 다음과 같습니다:

- GitLab은 사용자가 자신의 Kubernetes 자격 증명을 제공하고 배포 시 생성한 Pod에 적절하게 레이블을 지정하도록 합니다.
- 사용자가 환경의 터미널 페이지로 이동하면 GitLab으로 WebSocket 연결을 설정하는 JavaScript 애플리케이션이 제공됩니다.
- WebSocket은 Rails 애플리케이션 서버가 아닌 [Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse)에서 처리됩니다.
- Workhorse는 연결 세부 정보 및 사용자 권한에 대해 Rails에 쿼리합니다. Rails는 [Sidekiq](../sidekiq/sidekiq_troubleshooting.md)를 사용하여 백그라운드에서 Kubernetes에 쿼리합니다.
- Workhorse는 사용자의 브라우저와 Kubernetes API 사이의 프록시 서버 역할을 하며 두 대상 간에 WebSocket 프레임을 전달합니다.
- Workhorse는 정기적으로 Rails를 폴링하여 사용자가 더 이상 터미널에 액세스할 권한이 없거나 연결 세부 정보가 변경된 경우 WebSocket 연결을 종료합니다.

## 보안 {#security}

GitLab 및 [러너](https://docs.gitlab.com/runner/)는 대화형 웹 터미널 데이터를 암호화하고 권한 부여 가드로 모든 것을 보호하기 위해 몇 가지 예방 조치를 취합니다. 자세한 내용은 다음과 같습니다.

- 대화형 웹 터미널은 [`[session_server]`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-session_server-section)이 구성되지 않은 경우 완전히 비활성화됩니다.
- 러너가 시작될 때마다 `x509` 인증서를 생성하며, 이는 `wss`(Web Socket Secure) 연결에 사용됩니다.
- 생성된 모든 작업에 대해 임의의 URL이 생성되며, 이는 작업 종료 시 삭제됩니다. 이 URL은 웹 소켓 연결을 설정하는 데 사용됩니다. 세션의 URL 형식은 `(IP|HOST):PORT/session/$SOME_HASH`이며, 여기서 `IP/HOST` 및 `PORT`은 구성된 [`listen_address`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-session_server-section)입니다.
- 생성된 모든 세션 URL에는 `wss` 연결을 설정하기 위해 전송해야 하는 권한 부여 헤더가 있습니다.
- 세션 URL은 어떤 방식으로도 사용자에게 노출되지 않습니다. GitLab은 모든 상태를 내부적으로 유지하고 그에 따라 프록시합니다.

## 터미널 지원 활성화 및 비활성화 {#enabling-and-disabling-terminal-support}

> [!note]
> AWS Classic Load Balancer는 웹 소켓을 지원하지 않습니다. 웹 터미널이 작동하도록 하려면 AWS Network Load Balancer를 사용하세요. 자세한 내용은 [AWS Elastic Load Balancing Product Comparison](https://aws.amazon.com/elasticloadbalancing/features/#compare)을(를) 참조하세요.

웹 터미널은 WebSocket을 사용하므로 Workhorse 앞의 모든 HTTP/HTTPS 역방향 프록시는 `Connection` 및 `Upgrade` 헤더를 체인의 다음 헤더로 전달하도록 구성되어야 합니다. GitLab은 기본적으로 그렇게 구성됩니다.

그러나 GitLab 앞에 [로드 밸런서](../load_balancer.md)를 실행하는 경우 구성을 일부 변경해야 할 수 있습니다. 이 가이드에서는 인기 있는 역방향 프록시에 대한 필요한 단계를 설명합니다:

- [Apache](https://httpd.apache.org/docs/2.4/mod/mod_proxy_wstunnel.html)
- [NGINX](https://www.f5.com/company/blog/nginx/websocket-nginx/)
- [HAProxy](https://www.haproxy.com/blog/websockets-load-balancing-with-haproxy)
- [Varnish](https://varnish-cache.org/docs/4.1/users-guide/vcl-example-websockets.html)

Workhorse는 WebSocket 요청이 non-WebSocket 엔드포인트로 통과하지 않도록 하므로 이러한 헤더에 대한 지원을 전역적으로 활성화하는 것이 안전합니다. 더 좁은 규칙 집합을 선호하는 경우 `/terminal.ws`로 끝나는 URL로 제한할 수 있습니다. 이 방법은 여전히 몇 가지 거짓 긍정을 초래할 수 있습니다.

직접 설치를 컴파일한 경우 구성을 일부 변경해야 할 수 있습니다. [소스에서 Community Edition 및 Enterprise Edition 업그레이드](../../update/upgrading_from_source.md#new-configuration-for-nginx-or-apache)를 참조하여 자세한 내용을 확인하세요.

GitLab에서 웹 터미널 지원을 비활성화하려면 체인의 첫 번째 HTTP 역방향 프록시에서 `Connection` 및 `Upgrade` hop-by-hop 헤더 전달을 중지하세요. 대부분의 사용자의 경우 이는 Linux 패키지 설치와 함께 번들로 제공되는 NGINX 서버입니다. 이 경우 다음을 수행해야 합니다:

- `nginx['proxy_set_headers']` 섹션을 `gitlab.rb` 파일에서 찾습니다
- 전체 블록이 주석 처리되지 않았는지 확인한 다음 `Connection` 및 `Upgrade` 줄을 주석 처리하거나 제거합니다.

자신의 로드 밸런서의 경우 이전에 나열된 가이드에서 권장하는 구성 변경 사항을 취소하면 됩니다.

이러한 헤더가 전달되지 않으면 Workhorse는 웹 터미널 사용을 시도하는 사용자에게 `400 Bad Request` 응답을 반환합니다. 그 결과 사용자는 `Connection failed` 메시지를 받습니다.

## WebSocket 연결 시간 제한 {#limiting-websocket-connection-time}

기본적으로 터미널 세션은 만료되지 않습니다.

전제 조건:

- 관리자 액세스

GitLab 인스턴스에서 터미널 세션 수명을 제한하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을(를) 선택합니다.
1. **웹 터미널**을(를) 확장합니다.
1. `max session time`을(를) 설정합니다.
