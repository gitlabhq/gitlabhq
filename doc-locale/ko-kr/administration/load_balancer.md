---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 다중 노드 GitLab용 로드 밸런서
description: 다중 노드 인스턴스에서 로드 밸런서를 사용합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

다중 노드 GitLab 구성에서는 애플리케이션 서버로 트래픽을 라우팅하기 위해 로드 밸런서가 필요합니다. 사용할 로드 밸런서나 정확한 구성은 GitLab 문서의 범위 밖입니다. GitLab과 같은 HA 시스템을 관리하고 있다면 이미 선택한 로드 밸런서가 있을 것으로 예상합니다. HAProxy(오픈 소스), F5 Big-IP LTM, Citrix NetScaler 등의 예가 있습니다. 이 문서는 GitLab에서 사용할 포트와 프로토콜을 설명합니다.

## SSL {#ssl}

다중 노드 환경에서 SSL을 어떻게 처리하고 싶습니까? 여러 가지 옵션이 있습니다:

- 각 애플리케이션 노드가 SSL을 종료합니다
- 로드 밸런서가 SSL을 종료하고 로드 밸런서와 애플리케이션 노드 간의 통신이 안전하지 않습니다
- 로드 밸런서가 SSL을 종료하고 로드 밸런서와 애플리케이션 노드 간의 통신이 안전합니다

### 애플리케이션 노드가 SSL을 종료합니다 {#application-nodes-terminate-ssl}

로드 밸런서를 구성하여 포트 443의 연결을 'HTTP(S)' 프로토콜이 아닌 'TCP'로 전달합니다. 이를 통해 애플리케이션 노드 NGINX 서비스에 변경 없이 연결을 전달합니다. NGINX는 SSL 인증서를 가지고 있으며 포트 443에서 수신합니다.

SSL 인증서 관리 및 NGINX 구성에 대한 자세한 내용은 [HTTPS 문서](https://docs.gitlab.com/omnibus/settings/ssl/)를 참조하세요.

### 로드 밸런서가 백엔드 SSL 없이 SSL을 종료합니다 {#load-balancers-terminate-ssl-without-backend-ssl}

로드 밸런서를 구성하여 `HTTP(S)` 프로토콜을 사용하도록 `TCP` 대신 설정합니다. 로드 밸런서는 SSL 인증서를 관리하고 SSL을 종료할 책임이 있습니다.

로드 밸런서와 GitLab 간의 통신이 안전하지 않으므로 추가 구성이 필요합니다. 자세한 내용은 [프록시 SSL 문서](https://docs.gitlab.com/omnibus/settings/ssl/#configure-a-reverse-proxy-or-load-balancer-ssl-termination)를 참조하세요.

### 로드 밸런서가 백엔드 SSL을 사용하여 SSL을 종료합니다 {#load-balancers-terminate-ssl-with-backend-ssl}

로드 밸런서를 구성하여 `HTTP(S)` 프로토콜을 사용하도록 `TCP` 대신 설정합니다. 로드 밸런서는 최종 사용자가 보는 SSL 인증서를 관리할 책임이 있습니다.

이 시나리오에서 로드 밸런서와 NGINX 간의 트래픽은 안전합니다. 연결이 완전히 안전하므로 프록시 SSL에 대한 구성을 추가할 필요가 없습니다. 그러나 SSL 인증서를 구성하려면 GitLab에 구성을 추가해야 합니다. SSL 인증서 관리 및 NGINX 구성에 대한 자세한 내용은 [HTTPS 문서](https://docs.gitlab.com/omnibus/settings/ssl/)를 참조하세요.

## 포트 {#ports}

### 기본 포트 {#basic-ports}

| LB 포트 | 백엔드 포트 | 프로토콜                 |
| ------- | ------------ | ------------------------ |
| 80      | 80           | HTTP (*1*)               |
| 443     | 443          | TCP 또는 HTTPS (*1*) (*2*) |
| 22      | 22           | TCP                      |

- (*1*):  로드 밸런서는 [GitLab Duo Non-Agentic Chat](../user/gitlab_duo_chat/_index.md) , 이슈와 머지 리퀘스트의 실시간 레이블 업데이트, [웹 터미널](../ci/environments/_index.md#web-terminals-deprecated)과 같은 기능을 위해 WebSocket 연결을 지원해야 합니다. WebSocket을 지원하지 않는 로드 밸런서(예: AWS Classic Load Balancer)는 이러한 기능에 대해 GitLab과 호환되지 않습니다. HTTP 또는 HTTPS 프록시를 사용할 때 로드 밸런서는 `Connection`와 `Upgrade` 홉별 헤더를 백엔드 서버로 전달하도록 구성되어야 합니다. 이는 HTTP 헤더 전달을 의미하며 DSR(Direct Server Return) 모드가 아닙니다.
- (*2*):  포트 443에 HTTPS 프로토콜을 사용할 때 로드 밸런서에 SSL 인증서를 추가해야 합니다. 대신 GitLab 애플리케이션 서버에서 SSL을 종료하려면 TCP 프로토콜을 사용합니다.

### GitLab Pages 포트 {#gitlab-pages-ports}

GitLab Pages를 사용자 지정 도메인 지원과 함께 사용하는 경우 일부 추가 포트 구성이 필요합니다. GitLab Pages는 별도의 가상 IP 주소가 필요합니다. DNS를 구성하여 `pages_external_url`을 `/etc/gitlab/gitlab.rb`에서 새 가상 IP 주소로 지정합니다. 자세한 내용은 [GitLab Pages 문서](pages/_index.md)를 참조하세요.

| LB 포트 | 백엔드 포트  | 프로토콜  |
| ------- | ------------- | --------- |
| 80      | 다양함 (*1*)  | HTTP      |
| 443     | 다양함 (*1*)  | TCP (*2*) |

- (*1*):  GitLab Pages의 백엔드 포트는 `gitlab_pages['external_http']`와 `gitlab_pages['external_https']` 설정에 따라 다릅니다. [GitLab Pages 문서](pages/_index.md)를 참조하여 자세한 내용을 확인하세요.
- (*2*):  GitLab Pages의 포트 443은 항상 TCP 프로토콜을 사용해야 합니다. 사용자는 사용자 지정 SSL을 사용하여 사용자 지정 도메인을 구성할 수 있으며, 이는 로드 밸런서에서 SSL이 종료된 경우 불가능할 것입니다.

### 대체 SSH 포트 {#alternate-ssh-port}

일부 조직은 SSH 포트 22를 열지 않는 정책을 가지고 있습니다. 이 경우 사용자가 포트 443에서 SSH를 사용할 수 있는 대체 SSH 호스트명을 구성하는 것이 도움이 될 수 있습니다. 대체 SSH 호스트명은 이전에 문서화된 다른 GitLab HTTP 구성과 비교하여 새로운 가상 IP 주소가 필요합니다.

`altssh.gitlab.example.com`와 같은 대체 SSH 호스트명에 대해 DNS를 구성합니다.

| LB 포트 | 백엔드 포트 | 프로토콜 |
| ------- | ------------ | -------- |
| 443     | 22           | TCP      |

## 준비 상태 확인 {#readiness-check}

다중 노드 배포에서는 로드 밸런서를 구성하여 [준비 상태 확인](monitoring/health_check.md#readiness)을 사용하여 노드가 트래픽을 수락할 준비가 되었는지 확인하고 트래픽을 라우팅하기 전에 확인하는 것을 강력히 권장합니다. Puma를 사용할 때 재시작하는 동안 Puma가 요청을 수락하지 않는 짧은 기간이 있으므로 이것이 특히 중요합니다.

> [!warning]
> `all=1` 매개변수를 준비 상태 확인과 함께 GitLab 버전 15.4에서 15.8에 사용하면 [Praefect 메모리 사용량이 증가](https://gitlab.com/gitlab-org/gitaly/-/issues/4751)할 수 있으며 메모리 오류가 발생할 수 있습니다.

## 문제 해결 {#troubleshooting}

### 상태 확인이 로드 밸런서를 통해 `408` HTTP 코드를 반환하고 있습니다 {#the-health-check-is-returning-a-408-http-code-via-the-load-balancer}

GitLab 15.0 이상에서 [AWS Classic Load Balancer](https://docs.aws.amazon.com/en_en/elasticloadbalancing/latest/classic/elb-ssl-security-policy.html#ssl-ciphers)를 사용하는 경우 NGINX에서 `AES256-GCM-SHA384` 암호를 활성화해야 합니다. 자세한 내용은 [AES256-GCM-SHA384 SSL 암호는 더 이상 NGINX에서 기본적으로 허용되지 않습니다](../update/versions/gitlab_15_changes.md#1500)를 참조하세요.

GitLab 버전의 기본 암호는 [`files/gitlab-cookbooks/gitlab/attributes/default.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/attributes/default.rb) 파일에서 볼 수 있으며 대상 GitLab 버전과 관련된 Git 태그를 선택합니다(예: `15.0.5+ee.0`). 로드 밸런서에서 필요한 경우 NGINX에 대해 [사용자 지정 SSL 암호](https://docs.gitlab.com/omnibus/settings/ssl/#use-custom-ssl-ciphers)를 정의할 수 있습니다.

### 일부 페이지 및 링크가 브라우저에서 렌더링되지 않고 다운로드됨 {#some-pages-and-links-are-downloaded-instead-of-rendered-in-the-browser}

일부 GitLab 기능은 WebSocket 사용이 필요합니다. 로드 밸런서에서 WebSocket 지원을 사용하지 않는 일부 시나리오에서는 일부 링크나 페이지가 브라우저에서 렌더링되지 않고 다운로드될 수 있습니다. 다운로드한 파일에는 다음과 같은 내용이 포함될 수 있습니다:

```plaintext
One or more reserved bits are on: reserved1 = 1, reserved2 = 0, reserved3 = 0
```

로드 밸런서는 HTTP WebSocket 요청을 지원할 수 있어야 합니다. 이런 방식으로 링크를 다운로드하는 경우 로드 밸런서 구성을 확인하고 HTTP WebSocket 요청이 활성화되었는지 확인하세요.
