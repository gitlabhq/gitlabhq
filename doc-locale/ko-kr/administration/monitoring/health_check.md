---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
gitlab_dedicated: no
title: 상태 확인
description: "상태, 활성성, 및 준비 상태 확인을 수행합니다."
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 서비스 상태와 필수 서비스에 대한 도달 가능성을 나타내기 위해 활성성 및 준비 상태 프로브를 제공합니다. 이러한 프로브는 데이터베이스 연결, Redis 연결, 및 파일 시스템 액세스의 상태를 보고합니다. 이러한 엔드포인트는 [Kubernetes와 같은 스케줄러에 제공할 수 있으며](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) 시스템이 준비될 때까지 트래픽을 유지하거나 필요에 따라 컨테이너를 다시 시작합니다.

상태 확인 엔드포인트는 일반적으로 로드 밸런서 및 트래픽을 리다이렉트하기 전에 서비스 가용성을 확인해야 하는 다른 Kubernetes 스케줄링 시스템에 사용됩니다.

대규모 Kubernetes 배포에서 효과적인 가동 시간을 결정하기 위해 이러한 엔드포인트를 사용하면 안 됩니다. 이렇게 하면 자동 크기 조정, 노드 장애, 또는 기타 정상적이고 중단이 없는 운영상의 필요로 인해 포드가 제거될 때 거짓 음성을 표시할 수 있습니다.

대규모 Kubernetes 배포에서 가동 시간을 확인하려면 UI로의 트래픽을 확인합니다. 이는 적절하게 조정되고 예약되므로 효과적인 가동 시간의 더 나은 지표입니다. 로그인 페이지 `/users/sign_in` 엔드포인트도 모니터링할 수 있습니다.

<!-- vale gitlab_base.Spelling = NO -->

GitLab.com에서는 [Pingdom](https://www.pingdom.com/) 및 Apdex 측정과 같은 도구를 사용하여 가동 시간을 확인합니다.

<!-- vale gitlab_base.Spelling = YES -->

## IP 허용 목록 {#ip-allowlist}

모니터링 리소스에 액세스하려면 요청하는 클라이언트 IP를 허용 목록에 포함해야 합니다. 자세한 내용은 [모니터링 엔드포인트용 허용 목록에 IP를 추가하는 방법](ip_allowlist.md)을 참조하세요.

## 엔드포인트를 로컬로 사용 {#using-the-endpoints-locally}

기본 허용 목록 설정을 사용하면 다음 URL을 사용하여 localhost에서 프로브에 액세스할 수 있습니다:

```plaintext
GET http://localhost/-/health
```

```plaintext
GET http://localhost/health_check
```

```plaintext
GET http://localhost/-/readiness
```

```plaintext
GET http://localhost/-/liveness
```

## 상태 {#health}

애플리케이션 서버가 실행 중인지 확인합니다. 데이터베이스 또는 다른 서비스가 실행 중인지는 확인하지 않습니다. 이 엔드포인트는 Rails 컨트롤러를 우회하고 `BasicHealthCheck`로 추가 미들웨어로 구현되며 요청 처리 수명 주기의 초기에 실행됩니다.

```plaintext
GET /-/health
```

요청 예시:

```shell
curl "https://gitlab.example.com/-/health"
```

응답 예시:

```plaintext
GitLab OK
```

## 포괄적인 상태 확인 {#comprehensive-health-check}

> [!warning]
> **`/health_check`을(를) 로드 밸런싱 또는 자동 크기 조정에 사용하지 마세요.** 이 엔드포인트는 백엔드 서비스(데이터베이스, Redis)의 유효성을 검사하며 이러한 서비스가 느리거나 사용할 수 없는 경우 애플리케이션이 제대로 작동하더라도 실패합니다. 이로 인해 로드 밸런서에서 정상적인 애플리케이션 노드가 불필요하게 제거될 수 있습니다.

`/health_check` 엔드포인트는 데이터베이스 연결, Redis 가용성 및 기타 백엔드 서비스를 포함한 포괄적인 상태 확인을 수행합니다. `health_check` gem에서 제공하며 전체 애플리케이션 스택의 유효성을 검사합니다.

이 엔드포인트를 다음 용도로 사용합니다:

- 포괄적인 애플리케이션 모니터링
- 백엔드 서비스 상태 유효성 검사
- 연결 문제 해결
- 모니터링 대시보드 및 경고

```plaintext
GET /health_check
GET /health_check/database
GET /health_check/cache
GET /health_check/migrations
```

요청 예시:

```shell
curl "https://gitlab.example.com/health_check"
```

응답 예시 (성공):

```plaintext
success
```

응답 예시 (실패):

```plaintext
health_check failed: Unable to connect to database
```

사용 가능한 확인:

- `database` - 데이터베이스 연결
- `migrations` - 데이터베이스 마이그레이션 상태
- `cache` - Redis 캐시 연결
- `geo` (EE만 해당) - Geo 복제 상태

## 준비 상태 {#readiness}

준비 상태 프로브는 GitLab 인스턴스가 Rails 컨트롤러를 통해 트래픽을 수락할 준비가 되었는지 확인합니다. 확인은 기본적으로 인스턴스 확인만 유효성을 검사합니다.

`all=1` 매개 변수가 지정되면 확인은 종속 서비스(데이터베이스, Redis, Gitaly 등)의 유효성도 검사하고 각각에 대한 상태를 제공합니다.

```plaintext
GET /-/readiness
GET /-/readiness?all=1
```

요청 예시:

```shell
curl "https://gitlab.example.com/-/readiness"
```

응답 예시:

```json
{
   "master_check":[{
      "status":"failed",
      "message": "unexpected Master check result: false"
   }],
   ...
}
```

실패 시 엔드포인트는 `503` HTTP 상태 코드를 반환합니다.

이 확인은 Rack Attack에서 면제됩니다.

## 활성성 {#liveness}

> [!warning]
> GitLab [12.4](https://about.gitlab.com/upcoming-releases/)에서 활성성 확인의 응답 본문이 아래 예시와 일치하도록 변경되었습니다.

애플리케이션 서버가 실행 중인지 확인합니다. 이 프로브는 다중 스레딩으로 인해 Rails 컨트롤러가 교착 상태에 빠지지 않았는지 확인하는 데 사용됩니다.

```plaintext
GET /-/liveness
```

요청 예시:

```shell
curl "https://gitlab.example.com/-/liveness"
```

응답 예시:

성공 시 엔드포인트는 `200` HTTP 상태 코드를 반환하고 아래와 같은 응답을 반환합니다.

```json
{
   "status": "ok"
}
```

실패 시 엔드포인트는 `503` HTTP 상태 코드를 반환합니다.

이 확인은 Rack Attack에서 면제됩니다.

## Sidekiq {#sidekiq}

[Sidekiq 상태 확인](../sidekiq/sidekiq_health_check.md)을 구성하는 방법을 알아봅니다.
