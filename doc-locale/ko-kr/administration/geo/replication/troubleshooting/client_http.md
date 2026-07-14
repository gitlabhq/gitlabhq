---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo 클라이언트 및 HTTP 응답 코드 오류 문제 해결
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

## 클라이언트 오류 해결 {#fixing-client-errors}

### LFS HTTP(S) 클라이언트 요청의 인증 오류 {#authorization-errors-from-lfs-https-client-requests}

2.4.2 이전 버전의 [Git LFS](https://git-lfs.com/)를 실행 중인 경우 문제가 발생할 수 있습니다. [이 인증 문제](https://github.com/git-lfs/git-lfs/issues/3025)에서 언급한 대로 세컨더리에서 프라이머리 사이트로 리디렉션된 요청이 Authorization 헤더를 제대로 전송하지 않습니다. 이로 인해 무한 `Authorization <-> Redirect` 루프 또는 Authorization 오류 메시지가 발생할 수 있습니다.

### 오류: Geo 세컨더리에서 SSH를 통해 푸시할 때 `Net::ReadTimeout` {#error-netreadtimeout-when-pushing-through-ssh-on-a-geo-secondary}

Geo 세컨더리 사이트에서 SSH를 통해 큰 리포지토리를 푸시하면 타임아웃이 발생할 수 있습니다. Rails가 푸시를 프라이머리로 프록시하며 기본 타임아웃이 60초이기 때문입니다. [이 Geo 문제에서 설명된 대로](https://gitlab.com/gitlab-org/gitlab/-/issues/7405)

현재 사용 가능한 해결 방법은 다음과 같습니다:

- 대신 HTTP를 통해 푸시합니다. 여기서 Workhorse는 요청을 프라이머리로 프록시합니다(또는 Geo 프록싱이 활성화되지 않은 경우 프라이머리로 리디렉션됨).
- 프라이머리로 직접 푸시합니다.

예제 로그(`gitlab-shell.log`):

```plaintext
Failed to contact primary https://primary.domain.com/namespace/push_test.git\\nError: Net::ReadTimeout\",\"result\":null}" code=500 method=POST pid=5483 url="http://127.0.0.1:3000/api/v4/geo/proxy_git_push_ssh/push"
```

### Geo 사이트 간 OAuth 인증 복구 {#repair-oauth-authorization-between-geo-sites}

Geo 사이트를 업그레이드할 때 OAuth만을 인증으로 사용하는 세컨더리 사이트에 로그인하지 못할 수 있습니다. 이 경우 프라이머리 사이트에서 [Rails 콘솔](../../../operations/rails_console.md) 세션을 시작하고 다음 단계를 수행합니다:

1. 영향을 받은 노드를 찾으려면 먼저 보유한 모든 Geo 노드를 나열합니다:

   ```ruby
   GeoNode.all
   ```

1. 영향을 받은 Geo 노드를 ID를 지정하여 복구합니다:

   ```ruby
   GeoNode.find(<id>).repair
   ```

## HTTP 응답 코드 오류 {#http-response-code-errors}

### Geo 프록싱으로 세컨더리 사이트가 502 오류를 반환 {#secondary-site-returns-502-errors-with-geo-proxying}

[세컨더리 사이트에 대한 Geo 프록싱](../../secondary_proxy/_index.md)이 활성화되고 세컨더리 사이트 사용자 인터페이스가 502 오류를 반환하는 경우 프라이머리 사이트에서 프록시된 응답 헤더가 너무 클 수 있습니다.

이 예제와 유사한 오류가 있는지 NGINX 로그를 확인합니다:

```plaintext
2022/01/26 00:02:13 [error] 26641#0: *829148 upstream sent too big header while reading response header from upstream, client: 10.0.2.2, server: geo.staging.gitlab.com, request: "POST /users/sign_in HTTP/2.0", upstream: "http://unix:/var/opt/gitlab/gitlab-workhorse/sockets/socket:/users/sign_in", host: "geo.staging.gitlab.com", referrer: "https://geo.staging.gitlab.com/users/sign_in"
```

이 문제를 해결하려면:

1. 세컨더리 사이트의 모든 웹 노드에서 `/etc/gitlab.rb`의 `nginx['proxy_custom_buffer_size'] = '8k'`를 설정합니다.
1. **세컨더리**를 `sudo gitlab-ctl reconfigure`를 사용하여 재구성합니다.

이 오류가 계속 발생하면 이전 단계를 반복하고 `8k` 크기를 변경하여 버퍼 크기를 더 늘릴 수 있습니다. 예를 들어 `16k`로 2배로 늘릴 수 있습니다.

### Geo 운영자 영역이 상태 상태에 대해 `Unknown`을(를) 표시하고 'Request failed with status code 401' {#geo-admin-area-shows-unknown-for-health-status-and-request-failed-with-status-code-401}

로드 밸런서를 사용하는 경우 로드 밸런서의 URL이 로드 밸런서 뒤의 노드의 `/etc/gitlab/gitlab.rb`에서 `external_url`로 설정되었는지 확인합니다.

프라이머리 사이트에서 **운영자** > **Geo** > **설정**으로 이동하고 **허용된 Geo IP** 필드를 찾습니다. 세컨더리 사이트의 IP 주소가 나열되어 있는지 확인합니다.

### 프라이머리 사이트가 `/admin/geo/replication/projects`에 액세스할 때 500 오류를 반환 {#primary-site-returns-500-error-when-accessing-admingeoreplicationprojects}

프라이머리 Geo 사이트에서 **운영자** > **Geo** > **Replication**(또는 `/admin/geo/replication/projects`)로 이동하면 500 오류가 표시되는 반면, 세컨더리의 동일한 링크는 정상 작동합니다. 프라이머리의 `production.log`에 다음과 유사한 항목이 있습니다:

```plaintext
Geo::TrackingBase::SecondaryNotConfigured: Geo secondary database is not configured
  from ee/app/models/geo/tracking_base.rb:26:in `connection'
  [..]
  from ee/app/views/admin/geo/projects/_all.html.haml:1
```

Geo 프라이머리 사이트에서는 이 오류를 무시할 수 있습니다.

이는 GitLab이 [Geo 추적 데이터베이스](../../_index.md#geo-tracking-database)에서 레지스트리를 표시하려고 시도하기 때문에 발생합니다. 이 데이터베이스는 프라이머리 사이트에는 없습니다(프라이머리에는 원본 프로젝트만 존재하고, 복제된 프로젝트가 없으므로 추적 데이터베이스가 없음).

### 세컨더리 사이트가 400 오류 `Request header or cookie too large`을(를) 반환 {#secondary-site-returns-400-error-request-header-or-cookie-too-large}

이 오류는 프라이머리 사이트의 내부 URL이 잘못된 경우 발생할 수 있습니다.

예를 들어 통합 URL을 사용하고 프라이머리 사이트의 내부 URL도 외부 URL과 같을 때입니다. 이는 세컨더리 사이트가 프라이머리 사이트의 내부 URL에 요청을 프록시할 때 루프를 발생시킵니다.

이 문제를 해결하려면 프라이머리 사이트의 내부 URL을 다음과 같은 URL로 설정합니다:

- 프라이머리 사이트에 고유합니다.
- 모든 세컨더리 사이트에서 액세스 가능합니다.

1. 프라이머리 사이트를 방문합니다.
1. [내부 URL 설정](../../../geo_sites.md#set-up-the-internal-urls)

### Geo 운영자 영역이 세컨더리 사이트에 대해 404 오류를 반환 {#geo-admin-area-returns-404-error-for-a-secondary-site}

때로 `sudo gitlab-rake gitlab:geo:check`은(는) **Rails nodes of the secondary**가 정상이지만 **세컨더리** 사이트에 대한 404 Not Found 오류 메시지가 **프라이머리** 사이트의 웹 인터페이스에서 Geo **운영자** 영역으로 반환됨을 나타냅니다.

이 문제를 해결하려면:

- **each Rails, Sidekiq and Gitaly nodes on your secondary site**를 `sudo gitlab-ctl restart`를 사용하여 다시 시작해 봅니다.
- Sidekiq 노드에서 `/var/log/gitlab/gitlab-rails/geo.log`을(를) 확인하여 **세컨더리** 사이트가 IPv6을 사용하여 **프라이머리** 사이트에 상태를 전송하는지 확인합니다. 그렇다면 `/etc/hosts` 파일에서 IPv4를 사용하여 **프라이머리** 사이트에 항목을 추가합니다. 또는 [**프라이머리** 사이트에서 IPv6을 활성화](https://docs.gitlab.com/omnibus/settings/nginx/#setting-the-nginx-listen-address-or-addresses)해야 합니다.

## Geo 세컨더리 사이트에서 WebSocket 요청이 실패 {#websocket-requests-fail-on-geo-secondary-sites}

WebSocket을 사용하는 기능(예: GitLab Duo Chat, 라이브 이슈 업데이트 또는 기타 실시간 기능)을 사용할 때 Geo 세컨더리 사이트에서 404 오류와 함께 연결이 실패할 수 있습니다.

이는 WebSocket 요청이 세컨더리에서 프라이머리로 프록시되기 때문에 발생합니다. 프라이머리 사이트에서 ActionCable은 모든 Geo 사이트의 WebSocket 요청을 허용하도록 구성해야 합니다. 기본적으로 ActionCable은 로컬 사이트의 요청만 허용합니다.

이 문제를 해결하려면 설치 유형에 따라 `action_cable_allowed_origins`을(를) 구성합니다:

- [Linux 패키지에 대한 Geo 문서](../configuration.md#add-primary-and-secondary-urls-as-allowed-actioncable-origins)
- [Helm 차트에 대한 Geo 문서](https://docs.gitlab.com/charts/advanced/geo/#configure-primary-database)
