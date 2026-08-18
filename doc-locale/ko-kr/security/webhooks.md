---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 아웃바운드 요청 필터링
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

데이터 손실 및 노출의 위험으로부터 보호하기 위해 GitLab 관리자는 이제 아웃바운드 요청 필터링 컨트롤을 사용하여 GitLab 인스턴스에서 수행하는 특정 아웃바운드 요청을 제한할 수 있습니다.

## 웹후크 및 통합 보호 {#secure-webhooks-and-integrations}

유지 관리자 또는 소유자 역할을 가진 사용자는 프로젝트 또는 그룹에서 특정 변경사항이 발생할 때 트리거되는 [웹후크](../user/project/integrations/webhooks.md)를 설정할 수 있습니다. 트리거되면 `POST` HTTP 요청이 URL로 전송됩니다. 웹후크는 일반적으로 데이터를 특정 외부 웹 서비스로 전송하도록 구성되며, 해당 서비스가 데이터를 적절한 방식으로 처리합니다.

그러나 웹후크를 외부 웹 서비스 대신 내부 웹 서비스의 URL로 구성할 수 있습니다. 웹후크가 트리거되면 GitLab 서버 또는 해당 로컬 네트워크에서 실행되는 비-GitLab 웹 서비스가 악용될 수 있습니다.

웹후크 요청은 GitLab 서버 자체에서 수행되며 인증을 위해 후크당 단일 선택 비밀 토큰을 사용합니다:

- 사용자 토큰.
- 리포지토리 특정 토큰.

결과적으로 이러한 요청은 의도한 것보다 더 넓은 액세스 권한을 가질 수 있으며, 웹후크를 호스팅하는 서버에서 실행되는 모든 것에 대한 액세스를 포함합니다:

- GitLab 서버.
- API 자체.
- 일부 웹후크의 경우, 해당 웹후크 서버의 로컬 네트워크에 있는 다른 서버에 대한 네트워크 액세스입니다. 이러한 서비스가 다른 방식으로 보호되고 외부 세계에서 액세스할 수 없더라도 마찬가지입니다.

웹후크를 사용하여 인증이 필요하지 않은 웹 서비스를 사용하여 파괴적인 명령을 트리거할 수 있습니다. 이러한 웹후크는 GitLab 서버에 `POST` HTTP 요청을 리소스를 삭제하는 엔드포인트로 만들 수 있습니다.

### 웹후크 및 통합에서 로컬 네트워크에 대한 요청 허용 {#allow-requests-to-the-local-network-from-webhooks-and-integrations}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

안전하지 않은 내부 웹 서비스의 악용을 방지하기 위해 다음 로컬 네트워크 주소에 대한 모든 웹후크 및 통합 요청은 허용되지 않습니다:

- 현재 GitLab 인스턴스 서버 주소.
- `127.0.0.1`, `::1`, `0.0.0.0`, `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, 및 IPv6 사이트-로컬 (`ffc0::/10`) 주소를 포함한 사설 네트워크 주소.

이러한 주소에 대한 액세스를 허용하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **아웃바운드 요청**을 확장합니다.
1. **웹후크 및 통합에서 로컬 네트워크에 대한 요청 허용** 확인란을 선택합니다.

### 시스템 후크에서 로컬 네트워크로의 요청 방지 {#prevent-requests-to-the-local-network-from-system-hooks}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

[시스템 후크](../administration/system_hooks.md)는 기본적으로 로컬 네트워크에 대한 요청을 수행할 수 있습니다. 시스템 후크 요청을 로컬 네트워크로 방지하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **아웃바운드 요청**을 확장합니다.
1. **시스템 후크에서 로컬 네트워크로의 요청 허용** 확인란을 해제합니다.

### DNS 리바인딩 공격 보호 적용 {#enforce-dns-rebinding-attack-protection}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

[DNS 리바인딩](https://en.wikipedia.org/wiki/DNS_rebinding)은 악의적인 도메인 이름이 로컬 네트워크 액세스 제한을 우회하기 위해 내부 네트워크 리소스로 확인되도록 하는 기술입니다. GitLab은 기본적으로 이 공격에 대한 보호가 활성화되어 있습니다. 이 보호를 비활성화하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **아웃바운드 요청**을 확장합니다.
1. **DNS 리바인딩 공격 보호 적용** 확인란을 해제합니다.

## 요청 필터링 {#filter-requests}

{{< history >}}

- [GitLab 15.10에서 도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/377371).

{{< /history >}}

전제 조건:

- GitLab 인스턴스에 대한 관리자(administrator) 액세스 권한이 있어야 합니다.

많은 요청을 차단하여 요청을 필터링하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **아웃바운드 요청**을 확장합니다.
1. **허용 목록에 정의된 IP 주소, IP 범위 및 도메인 이름을 제외한 모든 요청 차단** 확인란을 선택합니다.

이 확인란을 선택하면 다음에 대한 요청은 여전히 차단되지 않습니다:

- Git, GitLab Shell, Gitaly, PostgreSQL 및 Redis와 같은 핵심 서비스.
- 객체 스토리지.
- [허용 목록](#allow-outbound-requests-to-certain-ip-addresses-and-domains)의 IP 주소 및 도메인.

이 설정이 활성화되면 GitLab은 릴리스 링크와 같은 다른 개체에 포함된 URL에 대해 DNS 해석을 수행할 수 있습니다. DNS 해석이 실패하면 요청이 실패합니다. 이 문제를 해결하려면 호스트 이름을 [허용 목록](#allow-outbound-requests-to-certain-ip-addresses-and-domains)에 추가합니다. GitLab이 해당 호스트에 대한 아웃바운드 연결을 수행할 필요가 없더라도 마찬가지입니다.

이 설정은 주 GitLab 애플리케이션에서만 준수되므로 Gitaly와 같은 다른 서비스는 여전히 규칙을 위반하는 요청을 수행할 수 있습니다. 또한 [GitLab의 일부 영역](https://gitlab.com/groups/gitlab-org/-/epics/8029)은 아웃바운드 필터링 규칙을 준수하지 않습니다.

## 특정 IP 주소 및 도메인에 대한 아웃바운드 요청 허용 {#allow-outbound-requests-to-certain-ip-addresses-and-domains}

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

특정 IP 주소 및 도메인에 대한 아웃바운드 요청을 허용하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **네트워크**를 선택합니다.
1. **아웃바운드 요청**을 확장합니다.
1. **후크 및 통합이 액세스할 수 있는 로컬 IP 주소 및 도메인 이름**에 IP 주소 및 도메인을 입력합니다.

항목은 다음과 같을 수 있습니다:

- 세미콜론, 쉼표 또는 공백(줄바꿈 포함)으로 구분됩니다.
- 호스트 이름, IP 주소, IP 주소 범위와 같은 다양한 형식일 수 있습니다. IPv6이 지원됩니다. 유니코드 문자를 포함하는 호스트 이름은 [Internationalized Domain Names in Applications](https://www.icann.org/en/icann-acronyms-and-terms/internationalized-domain-names-in-applications-en) (IDNA) 인코딩을 사용해야 합니다.
- 포트를 포함합니다. 예를 들어 `127.0.0.1:8080`은 `127.0.0.1`의 포트 8080에 대한 연결만 허용합니다. 포트를 지정하지 않으면 해당 IP 주소 또는 도메인의 모든 포트가 허용됩니다. IP 주소 범위는 해당 범위의 모든 IP 주소에 대한 모든 포트를 허용합니다.
- 각 항목에 대해 1000개 이하의 255자 이하 항목을 포함합니다.
- 와일드카드를 포함하지 않습니다(예: `*.example.com`).

예를 들어:

```plaintext
example.com;gitlab.example.com
127.0.0.1,1:0:0:0:0:0:0:1
127.0.0.0/8 1:0:0:0:0:0:0:0/124
[1:0:0:0:0:0:0:1]:8080
127.0.0.1:8080
example.com:8080
```

## 문제 해결 {#troubleshooting}

아웃바운드 요청을 필터링할 때 다음과 같은 문제가 발생할 수 있습니다.

### 구성된 URL이 차단됨 {#configured-urls-are-blocked}

**허용 목록에 정의된 IP 주소, IP 범위 및 도메인 이름을 제외한 모든 요청 차단** 확인란을 선택하려면 구성된 URL이 차단되지 않아야 합니다. 그렇지 않으면 URL이 차단되었다는 오류 메시지가 표시될 수 있습니다.

이 설정을 활성화할 수 없으면 다음 중 하나를 수행합니다:

- URL 설정을 비활성화합니다.
- 다른 URL을 구성하거나 URL 설정을 비워둡니다.
- 구성된 URL을 [허용 목록](#allow-requests-to-the-local-network-from-webhooks-and-integrations)에 추가합니다.

### 공용 러너 릴리스 URL이 차단됨 {#public-runner-releases-url-is-blocked}

대부분의 GitLab 인스턴스는 `public_runner_releases_url`이 `https://gitlab.com/api/v4/projects/gitlab-org%2Fgitlab-runner/releases`로 설정되어 있으며, 이는 [요청 필터링](#filter-requests)을 방지할 수 있습니다.

이 문제를 해결하려면 [GitLab이 더 이상 GitLab.com에서 러너 릴리스 버전 데이터를 가져오지 않도록 구성](../administration/settings/continuous_integration.md#control-runner-version-management)합니다.

### GitLab 구독 관리가 차단됨 {#gitlab-subscription-management-is-blocked}

[요청을 필터링](#filter-requests)할 때 [GitLab 구독 관리](../subscriptions/manage_subscription.md)가 차단됩니다.

이 문제를 해결하려면 `customers.gitlab.com:443`을 [허용 목록](#allow-outbound-requests-to-certain-ip-addresses-and-domains)에 추가합니다.

### GitLab 설명서가 차단됨 {#gitlab-documentation-is-blocked}

[요청을 필터링](#filter-requests)할 때 `Help page documentation base url is blocked: Requests to hosts and IP addresses not on the Allow List are denied` 오류가 표시될 수 있습니다. 이 오류를 해결하려면:

1. 변경사항을 되돌려 `Help page documentation base url is blocked` 오류 메시지가 더 이상 표시되지 않도록 합니다.
1. `docs.gitlab.com` 또는 [리다이렉트 도움말 설명서 페이지 URL](../administration/settings/help_page.md#redirect-help-pages)을 [허용 목록](#allow-outbound-requests-to-certain-ip-addresses-and-domains)에 추가합니다.
1. **변경 사항 저장**을 선택합니다.

### GitLab Duo 기능이 차단됨 {#gitlab-duo-functionality-is-blocked}

[요청을 필터링](#filter-requests)할 때 [GitLab Duo 기능](../user/gitlab_duo/_index.md)을 사용하려고 할 때 `401` 오류가 표시될 수 있습니다.

이 오류는 GitLab 클라우드 서버에 대한 아웃바운드 요청이 허용되지 않을 때 발생할 수 있습니다. 이 오류를 해결하려면:

1. `https://cloud.gitlab.com:443`을 [허용 목록](#allow-outbound-requests-to-certain-ip-addresses-and-domains)에 추가합니다.
1. **변경 사항 저장**을 선택합니다.
1. GitLab이 [클라우드 서버](../user/gitlab_duo/_index.md)에 액세스한 후 [라이선스를 수동으로 동기화](../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)합니다.
