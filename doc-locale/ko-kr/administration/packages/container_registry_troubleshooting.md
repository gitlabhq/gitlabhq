---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 컨테이너 레지스트리 문제 해결
description: GitLab 컨테이너 레지스트리의 일반적인 문제를 해결합니다.
---

특정 문제를 조사하기 전에 다음 문제 해결 단계를 시도하세요:

1. Docker 클라이언트와 GitLab 서버의 시스템 시계가 동기화되어 있는지 확인합니다(예: NTP를 통해).
1. S3 기반 레지스트리의 경우, IAM 권한과 S3 자격 증명(지역 포함)이 올바른지 확인합니다. 자세한 내용은 [샘플 IAM 정책](https://distribution.github.io/distribution/storage-drivers/s3/)을 참조하세요.
1. 작업 로그(예: `/var/log/gitlab/registry/current`) 및 GitLab 프로덕션 로그(예: `/var/log/gitlab/gitlab-rails/production.log`)에서 오류를 확인합니다.
1. 컨테이너 레지스트리 NGINX 구성 파일(예: `/var/opt/gitlab/nginx/conf/gitlab-registry.conf`)을 검토하여 어떤 포트가 요청을 수신하는지 확인합니다.
1. 요청이 컨테이너 레지스트리로 올바르게 전달되었는지 확인합니다:

   ```shell
   curl --verbose --noproxy "*" https://<hostname>:<port>/v2/_catalog
   ```

   응답에는 `Www-Authenticate: Bearer`이 포함된 줄이 포함되어야 하며, `service="container_registry"`이 포함되어야 합니다. 예를 들어:

   ```plaintext
   < HTTP/1.1 401 Unauthorized
   < Server: nginx
   < Date: Fri, 07 Mar 2025 08:24:43 GMT
   < Content-Type: application/json
   < Content-Length: 162
   < Connection: keep-alive
   < Docker-Distribution-Api-Version: registry/2.0
   < Www-Authenticate: Bearer realm="https://<hostname>/jwt/auth",service="container_registry",scope="registry:catalog:*"
   < X-Content-Type-Options: nosniff
   <
   {"errors":[{"code":"UNAUTHORIZED","message":"authentication required","detail":
   [{"Type":"registry","Class":"","Name":"catalog","ProjectPath":"","Action":"*"}]}]}
   * Connection #0 to host <hostname> left intact
   ```

## 오류: `... x509: certificate signed by unknown authority` {#error--x509-certificate-signed-by-unknown-authority}

컨테이너 레지스트리에서 자체 서명 인증서를 사용할 때 CI/CD 파이프라인 작업에서 유사한 오류가 발생할 수 있습니다:

```plaintext
Error response from daemon: Get registry.example.com/v1/users/: x509: certificate signed by unknown authority
```

이 오류는 명령을 실행하는 Docker 데몬이 자체 서명 인증서가 아닌 인정된 인증 기관에서 서명한 인증서를 예상하기 때문에 발생합니다.

이 오류를 해결하려면 Docker를 구성하여 자체 서명 인증서를 신뢰하도록 합니다. Docker 구성에 대한 도움은 [자체 서명 인증서 구성](container_registry.md#configure-self-signed-certificates)을 참조하세요.

자세한 내용은 [이슈 18239](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/18239)를 참조하세요.

## Docker 로그인 시도 실패: 'token signed by untrusted key' {#docker-login-attempt-fails-with-token-signed-by-untrusted-key}

[레지스트리는 GitLab에 의존하여 자격 증명을 검증합니다](container_registry.md#container-registry-architecture) 레지스트리가 유효한 로그인 시도를 인증하지 못하면 다음 오류 메시지가 표시됩니다:

```shell
# docker login gitlab.company.com:4567
Username: user
Password:
Error response from daemon: login attempt to https://gitlab.company.com:4567/v2/ failed with status: 401 Unauthorized
```

더 구체적으로, `/var/log/gitlab/registry/current` 로그 파일에 다음과 같이 나타납니다:

```plaintext
level=info
msg="token signed by untrusted key with ID: "TOKE:NL6Q:7PW6:EXAM:PLET:OKEN:BG27:RCIB:D2S3:EXAM:PLET:OKEN""
level=warning msg="error authorizing context: invalid token" go.version=go1.12.7 http.request.host="gitlab.company.com:4567"
http.request.id=74613829-2655-4f96-8991-1c9fe33869b8 http.request.method=GET http.request.remoteaddr=10.72.11.20
http.request.uri="/v2/" http.request.useragent="docker/19.03.2 go/go1.12.8 git-commit/6a30dfc
kernel/3.10.0-693.2.2.el7.x86_64 os/linux arch/amd64 UpstreamClient(Docker-Client/19.03.2 \(linux\))"
```

(가독성을 위해 줄 바꿈을 추가했습니다.)

GitLab은 인증서 키 쌍의 양쪽 내용을 사용하여 컨테이너 레지스트리의 인증 토큰을 암호화합니다. 이 메시지는 해당 내용이 일치하지 않음을 의미합니다.

사용 중인 파일을 확인합니다:

- `grep -A6 'auth:' /var/opt/gitlab/registry/config.yml`

  ```yaml
  ## Container registry certificate
     auth:
       token:
         realm: https://gitlab.my.net/jwt/auth
         service: container_registry
         issuer: omnibus-gitlab-issuer
    -->  rootcertbundle: /var/opt/gitlab/registry/gitlab-registry.crt
         autoredirect: false
  ```

- `grep -A9 'Container Registry' /var/opt/gitlab/gitlab-rails/etc/gitlab.yml`

  ```yaml
  ## Container registry key
     registry:
       enabled: true
       host: gitlab.company.com
       port: 4567
       api_url: http://127.0.0.1:5000 # internal address to the registry, is used by GitLab to directly communicate with API
       path: /var/opt/gitlab/gitlab-rails/shared/registry
  -->  key: /var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key
       issuer: omnibus-gitlab-issuer
       notification_secret:
  ```

다음 `openssl` 명령의 출력이 일치해야 하며, 이는 cert-key 쌍이 일치함을 증명합니다:

```shell
/opt/gitlab/embedded/bin/openssl x509 -noout -modulus -in /var/opt/gitlab/registry/gitlab-registry.crt | /opt/gitlab/embedded/bin/openssl sha256
/opt/gitlab/embedded/bin/openssl rsa -noout -modulus -in /var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key | /opt/gitlab/embedded/bin/openssl sha256
```

인증서의 두 부분이 일치하지 않으면 파일을 제거하고 `gitlab-ctl reconfigure`을 실행하여 쌍을 다시 생성합니다. 쌍은 `/etc/gitlab/gitlab-secrets.json` 내의 기존 값을 사용하여 다시 생성됩니다(있는 경우). 새 쌍을 생성하려면 `registry` 섹션을 `/etc/gitlab/gitlab-secrets.json`에서 삭제하고 `gitlab-ctl reconfigure`을 실행합니다.

자동으로 생성된 자체 서명 쌍을 자신의 인증서로 재정의했으며 해당 내용이 일치하는지 확인했다면 `/etc/gitlab/gitlab-secrets.json`에서 'registry' 섹션을 삭제하고 `gitlab-ctl reconfigure`을 실행할 수 있습니다.

## AWS S3과 GitLab 컨테이너 레지스트리 오류(큰 이미지 푸시 시) {#aws-s3-with-the-gitlab-registry-error-when-pushing-large-images}

AWS S3과 GitLab 컨테이너 레지스트리를 사용할 때 큰 이미지를 푸시할 때 오류가 발생할 수 있습니다. 레지스트리 로그에서 다음 오류를 찾습니다:

```plaintext
level=error msg="response completed with error" err.code=unknown err.detail="unexpected EOF" err.message="unknown error"
```

오류를 해결하려면 레지스트리 구성에서 `chunksize` 값을 지정합니다. `25000000`(25MB)에서 `50000000`(50MB) 사이의 값부터 시작합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   registry['storage'] = {
     's3' => {
       'accesskey' => 'AKIAKIAKI',
       'secretkey' => 'secret123',
       'bucket'    => 'gitlab-registry-bucket-AKIAKIAKI',
       'chunksize' => 25000000
     }
   }
   ```

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. `config/gitlab.yml`을 편집합니다:

   ```yaml
   storage:
     s3:
       accesskey: 'AKIAKIAKI'
       secretkey: 'secret123'
       bucket: 'gitlab-registry-bucket-AKIAKIAKI'
       chunksize: 25000000
   ```

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab 재시작](../restart_gitlab.md#self-compiled-installations)합니다.

{{< /tab >}}

{{< /tabs >}}

## 오래된 Docker 클라이언트 지원 {#supporting-older-docker-clients}

GitLab과 함께 제공되는 Docker 컨테이너 레지스트리는 기본적으로 schema1 매니페스트를 비활성화합니다. 여전히 오래된 Docker 클라이언트(1.9 이상)를 사용하는 경우 이미지를 푸시할 때 오류가 발생할 수 있습니다. 자세한 내용은 [이슈 4145](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4145)를 참조하세요.

역호환성에 대한 구성 옵션을 추가할 수 있습니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   registry['compatibility_schema1_enabled'] = true
   ```

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. 레지스트리를 배포할 때 생성한 YAML 구성 파일을 편집합니다. 다음 코드 조각을 추가합니다:

   ```yaml
   compatibility:
       schema1:
           enabled: true
   ```

1. 변경 사항을 적용하려면 레지스트리를 재시작합니다.

{{< /tab >}}

{{< /tabs >}}

## Docker 연결 오류 {#docker-connection-error}

그룹, 프로젝트 또는 브랜치 이름에 특수 문자가 있으면 Docker 연결 오류가 발생할 수 있습니다. 특수 문자에는 다음이 포함될 수 있습니다:

- 선행 밑줄
- 후행 하이픈/대시
- 이중 하이픈/대시

이를 해결하려면 [그룹 경로 변경](../../user/group/manage.md#change-a-groups-path) , [프로젝트 경로 변경](../../user/project/working_with_projects.md#rename-a-repository) 또는 브랜치 이름을 변경할 수 있습니다. 또 다른 옵션은 [푸시 규칙](../../user/project/repository/push_rules.md)을 생성하여 전체 인스턴스에서 이 오류를 방지하는 것입니다.

## 이미지 푸시 오류 {#image-push-errors}

`docker login`이 성공해도 Docker 이미지를 푸시할 때 재시도 루프에 갇힐 수 있습니다.

이 문제는 NGINX가 레지스트리로 헤더를 제대로 전달하지 않을 때 발생하며, 일반적으로 SSL이 타사 역방향 프록시로 오프로드되는 사용자 정의 설정에서 발생합니다.

자세한 내용은 [Docker push through NGINX proxy fails trying to send a 32B layer #970](https://github.com/docker/distribution/issues/970)을 참조하세요.

이 문제를 해결하려면 NGINX 구성을 업데이트하여 레지스트리에서 상대 URL을 활성화합니다:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   registry['env'] = {
     "REGISTRY_HTTP_RELATIVEURLS" => true
   }
   ```

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. 레지스트리를 배포할 때 생성한 YAML 구성 파일을 편집합니다. 다음 코드 조각을 추가합니다:

   ```yaml
   http:
       relativeurls: true
   ```

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab 재시작](../restart_gitlab.md#self-compiled-installations)합니다.

{{< /tab >}}

{{< tab title="Docker Compose" >}}

1. `docker-compose.yaml` 파일을 편집합니다:

   ```yaml
   GITLAB_OMNIBUS_CONFIG: |
     registry['env'] = {
       "REGISTRY_HTTP_RELATIVEURLS" => true
     }
   ```

1. 문제가 지속되면 두 URL 모두 HTTPS를 사용하는지 확인합니다:

   ```yaml
   GITLAB_OMNIBUS_CONFIG: |
     external_url 'https://git.example.com'
     registry_external_url 'https://git.example.com:5050'
   ```

1. 파일을 저장하고 컨테이너를 재시작합니다:

   ```shell
   sudo docker restart gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

## 레지스트리 디버그 서버 활성화 {#enable-the-registry-debug-server}

컨테이너 레지스트리 디버그 서버를 사용하여 문제를 진단할 수 있습니다. 디버그 엔드포인트는 메트릭 및 상태를 모니터링하고 프로파일링을 수행할 수 있습니다.

> [!warning]
> 디버그 엔드포인트에서 민감한 정보를 사용할 수 있습니다. 디버그 엔드포인트에 대한 액세스는 프로덕션 환경에서 잠금 해제되어야 합니다.

선택적 디버그 서버는 `gitlab.rb` 구성에서 레지스트리 디버그 주소를 설정하여 활성화할 수 있습니다.

```ruby
registry['debug_addr'] = "localhost:5001"
```

설정을 추가한 후 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

curl을 사용하여 디버그 서버에서 디버그 출력을 요청합니다:

```shell
curl "localhost:5001/debug/health"
curl "localhost:5001/debug/vars"
```

### Prometheus 메트릭 {#prometheus-metrics}

Prometheus는 컨테이너 레지스트리의 성능 문제를 모니터링하고 문제를 해결하는 데 사용할 수 있는 메트릭을 제공합니다.

다음 섹션:

- Prometheus 메트릭을 활성화하는 방법을 보여줍니다
- 컨테이너 레지스트리에서 내보낸 모든 Prometheus 메트릭을 나열하고 구성 요소별로 정리합니다

#### Prometheus 메트릭 활성화 {#enable-prometheus-metrics}

전제 조건:

- [레지스트리 디버그 서버를 활성화](#enable-the-registry-debug-server)해야 합니다.

Prometheus 메트릭을 활성화하려면 `gitlab.rb`에 다음 구성을 추가합니다:

```ruby
# Enable Prometheus metrics
registry['debug'] = {
  'prometheus' => {
    'enabled' => true,
    'path' => '/metrics'
  }
}
```

변경 사항을 적용하려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

curl을 사용하여 디버그 서버에서 메트릭을 요청합니다:

```shell
curl "localhost:5001/metrics"
```

#### 알림 메트릭 {#notifications-metrics}

#### 카운터 {#counters}

| 메트릭 이름 | 설명 | 레이블 | 레이블 값 |
|-------------|-------------|--------|--------------|
| `registry_notifications_events_total` | 이벤트의 총 개수입니다. | `type`, `action`, `artifact`, `endpoint` | `type`: `Successes`, `Failures`, `Events`, `Dropped` |
| `registry_notifications_status_total` | 알림 엔드포인트에서 수신한 상태 코드당 HTTP 응답의 개수입니다. | `code`, `endpoint` | `code`:  HTTP 상태 코드(예: `200 OK` 또는 `404 Not Found`) |
| `registry_notifications_errors_total` | 전송 중에 오류가 발생한 이벤트의 개수입니다. 요청 전송이 다시 시도될 수 있습니다. | `endpoint` | 문자열: `'...'` |
| `registry_notifications_delivery_total` | 전달되거나 손실된 이벤트의 개수입니다. 재시도 횟수가 소진되면 이벤트가 손실됩니다. | `endpoint`, `delivery_type` | `delivery_type`: `delivered`, `lost` |

#### 게이지 {#gauges}

| 메트릭 이름 | 설명 | 레이블 | 레이블 값 |
|-------------|-------------|--------|--------------|
| `registry_notifications_pending` | 대기열에 있는 보류 중인 이벤트의 게이지(대기열 길이로 표현됨)입니다. | `endpoint` | 문자열: `'...'` |

#### 히스토그램 {#histograms}

| 메트릭 이름 | 설명 | 레이블 | 버킷 |
|-------------|-------------|--------|---------|
| `registry_notifications_retries_count` | 누적 배달 재시도의 히스토그램입니다. | `endpoint` | `[0, 1, 2, 3, 5, 10, 15, 20, 30, 50]` |
| `registry_notifications_http_latency_seconds` | HTTP 배달 지연 시간의 히스토그램입니다. | `endpoint` | `[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100]` (초) |
| `registry_notifications_total_latency_seconds` | 총 배달 지연 시간의 히스토그램입니다. | `endpoint` | `[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100]` (초) |

#### 배치 배경 마이그레이션(BBM) 메트릭 {#batched-background-migration-bbm-metrics}

##### 카운터 {#counters-1}

| 메트릭 이름 | 설명 | 레이블 | 레이블 값 |
|-------------|-------------|--------|--------------|
| `registry_bbm_runs_total` | 배치 마이그레이션 작업 실행의 카운터입니다. | 없음 | 없음 |
| `registry_bbm_migrated_tuples_total` | 마이그레이션된 배치 마이그레이션 레코드 총 개수의 카운터입니다. | `migration_name`, `migration_id` | 문자열: `'...'` |

##### 게이지 {#gauges-1}

| 메트릭 이름 | 설명 | 레이블 | 레이블 값 |
|-------------|-------------|--------|--------------|
| `registry_bbm_job_batch_size` | 배치 마이그레이션 작업의 배치 크기에 대한 게이지입니다. | `migration_name`, `migration_id` | 문자열: `'...'` |
| `registry_database_bbm_progress_percent` | 배경 마이그레이션 진행률(0-100)입니다. | `migration_id`, `migration_name`, `status` | 문자열: `'...'` |

##### 히스토그램 {#histograms-1}

| 메트릭 이름 | 설명 | 레이블 | 버킷 |
|-------------|-------------|--------|---------|
| `registry_bbm_run_duration_seconds` | 배치 마이그레이션 작업 실행의 지연 시간 히스토그램입니다. | 없음 | `[0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600]` (0.5초에서 1시간) |
| `registry_bbm_job_duration_seconds` | 배치 마이그레이션 작업의 지연 시간 히스토그램입니다. | `migration_name`, `migration_id` | `[0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600]` (0.5초에서 1시간) |
| `registry_bbm_query_duration_seconds` | 배치 마이그레이션 데이터베이스 쿼리의 지연 시간 히스토그램입니다. | `migration_name`, `migration_id` | `[0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600]` (0.5초에서 1시간) |
| `registry_bbm_sleep_duration_seconds` | BBM 작업 실행 사이의 절전 시간 히스토그램입니다. | `worker` | `[0.5, 1, 5, 15, 30, 60, 300, 600, 900, 1800, 3600, 7200, 10800, 21600, 43200, 86400]` (500ms에서 24시간) |

#### 데이터베이스 메트릭 {#database-metrics}

##### 카운터 {#counters-2}

| 메트릭 이름 | 설명 | 레이블 | 레이블 값 |
|-------------|-------------|--------|--------------|
| `registry_database_queries_total` | 데이터베이스 쿼리의 카운터입니다. | `name` | 문자열: `'...'` |
| `registry_database_lb_lsn_cache_hits_total` | 데이터베이스 로드 밸런싱 LSN 캐시 히트 및 미스의 카운터입니다. | `result` | `result`: `hit`, `miss` |
| `registry_database_lb_pool_events_total` | 데이터베이스 로드 밸런서 풀에서 추가되거나 제거된 복제본의 카운터입니다. | `event`, `reason` | `event`: `replica_added`, `replica_removed`, `replica_quarantined`, `replica_reintegrated`<br>`reason`: `replication_lag`, `connectivity`, `removed_from_dns`, `discovered` |
| `registry_database_lb_targets_total` | 데이터베이스 로드 밸런싱 중 기본 및 복제본 대상 선택의 카운터입니다. | `target_type`, `fallback`, `reason` | `target_type`: `primary`, `replica`<br>`fallback`: `true`, `false`<br>`reason`: `selected`, `no_cache`, `no_replica`, `error`, `not_up_to_date`, `all_quarantined` |

##### 게이지 {#gauges-2}

| 메트릭 이름 | 설명 | 레이블 | 레이블 값 |
|-------------|-------------|--------|--------------|
| `registry_database_lb_pool_size` | 로드 밸런서 풀의 현재 복제본 수에 대한 게이지입니다. | 없음 | 없음 |
| `registry_database_lb_pool_status` | 로드 밸런서 풀의 각 복제본의 현재 상태에 대한 게이지입니다. | `replica`, `status` | `status`: `online`, `quarantined` |
| `registry_database_lb_lag_bytes` | 각 복제본에 대한 복제 지연(바이트)의 게이지입니다. | `replica` | 문자열: `'...'` |
| `registry_database_migrations_total` | 데이터베이스 마이그레이션의 총 개수(적용됨 + 보류 중)의 게이지입니다. | `migration_type` | `migration_type`: `pre_deployment`, `post_deployment` |
| `registry_database_rows` | `query_name` 레이블로 정의된 데이터베이스 테이블의 행 수에 대한 게이지입니다. | `query_name` | `query_name`: `gc_blob_review_queue`, `gc_manifest_review_queue`, `gc_blob_review_queue_overdue`, `gc_manifest_review_queue_overdue`, `applied_pre_migrations`, `applied_post_migrations` |

##### 히스토그램 {#histograms-2}

| 메트릭 이름 | 설명 | 레이블 | 버킷 |
|-------------|-------------|--------|---------|
| `registry_database_query_duration_seconds` | 데이터베이스 쿼리의 지연 시간 히스토그램입니다. | `name` | Prometheus 기본 버킷입니다. <sup>1</sup> |
| `registry_database_lb_lsn_cache_operation_duration_seconds` | 데이터베이스 로드 밸런싱 LSN 캐시 작업의 지연 시간 히스토그램입니다. | `operation`, `error` | `operation`: `set`, `get`<br>`error`: `true`, `false`<br>Prometheus 기본 버킷입니다. <sup>1</sup> |
| `registry_database_lb_lookup_seconds` | 데이터베이스 로드 밸런싱 DNS 조회의 지연 시간 히스토그램입니다. | `lookup_type`, `error` | `lookup_type`: `srv`, `host`<br>`error`: `true`, `false`<br>Prometheus 기본 버킷입니다. <sup>1</sup>  |
| `registry_database_lb_lag_seconds` | 각 복제본에 대한 복제 지연(초)의 히스토그램입니다. | `replica` | `[0.001, 0.01, 0.1, 0.5, 1, 5, 10, 20, 30, 60]` (1ms에서 60초) |
| `registry_database_row_count_collection_duration_seconds` | 단일 실행에서 모든 데이터베이스 행 개수 쿼리를 수집하기 위한 총 기간의 히스토그램입니다. | 없음 | `[0.1, 0.5, 1, 2, 5, 10, 30, 60]` (100ms에서 60초) |

**각주**:

1. Prometheus 기본 버킷 값: `[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]` (초)

#### 가비지 수집(GC) 메트릭 {#garbage-collection-gc-metrics}

##### 카운터 {#counters-3}

| 메트릭 이름 | 설명 | 레이블 | 레이블 값 |
|-------------|-------------|--------|--------------|
| `registry_gc_runs_total` | 온라인 GC 작업 실행의 카운터입니다. | `worker`, `noop`, `error`, `dangling`, `event` | `noop`: `true`, `false`<br>`error`: `true`, `false`<br>`dangling`: `true`, `false` |
| `registry_gc_deletes_total` | 온라인 GC 중에 삭제된 아티팩트의 카운터입니다. | `backend`, `artifact` | `backend`: `storage`, `database`<br>`artifact`: `blob`, `manifest` |
| `registry_gc_storage_deleted_bytes_total` | 온라인 GC 중에 저장소에서 삭제된 바이트의 카운터입니다. | `media_type` | 문자열: `'...'` |
| `registry_gc_postpones_total` | 온라인 GC 검토 연기의 카운터입니다. | `worker` | 문자열: `'...'` |

##### 히스토그램 {#histograms-3}

| 메트릭 이름 | 설명 | 레이블 | 버킷 |
|-------------|-------------|--------|---------|
| `registry_gc_run_duration_seconds` | 온라인 GC 작업 실행의 지연 시간 히스토그램입니다. | `worker`, `noop`, `error`, `dangling`, `event` | `noop`: `true`, `false`<br>`error`: `true`, `false`<br>`dangling`: `true`, `false`<br>Prometheus 기본 버킷입니다. <sup>1</sup> |
| `registry_gc_delete_duration_seconds` | 온라인 GC 중 아티팩트 삭제의 지연 시간 히스토그램입니다. | `backend`, `artifact`, `error` | `backend`: `storage`, `database`<br>`artifact`: `blob`, `manifest`<br>`error`: `true`, `false`<br>Prometheus 기본 버킷입니다. <sup>1</sup> |
| `registry_gc_sleep_duration_seconds` | 온라인 GC 작업 실행 사이의 절전 시간 히스토그램입니다. | `worker` | `[0.5, 1, 5, 15, 30, 60, 300, 600, 900, 1800, 3600, 7200, 10800, 21600, 43200, 86400]` (500ms에서 24시간) |

**각주**:

1. Prometheus 기본 버킷 값: `[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]` (초)

#### 스토리지 메트릭 {#storage-metrics}

##### 카운터 {#counters-4}

| 메트릭 이름 | 설명 | 레이블 | 레이블 값 |
|-------------|-------------|--------|--------------|
| `registry_storage_cdn_redirects_total` | Blob 다운로드의 CDN 리다이렉션 카운터입니다. | `backend`, `bypass`, `bypass_reason` | `bypass`: `true`, `false` |
| `registry_storage_rate_limit_total` | 속도 제한에 도달한 저장소 드라이버에 대한 요청의 카운터입니다. | 없음 | 없음 |
| `registry_storage_storage_backend_retries_total` | 저장소 백엔드와 통신할 때 발생한 재시도의 카운터입니다. | `retry_type` | `retry_type`: `native`, `custom` |
| `registry_storage_urlcache_requests_total` | URL 캐시 미들웨어 요청의 카운터입니다. | `result`, `reason` | `result`: `hit`, `miss` |
| `registry_storage_access_tracker_dropped_events` | 시간 초과로 인해 액세스 추적기에서 삭제된 이벤트의 카운터입니다. | 없음 | 없음 |

##### 게이지 {#gauges-3}

| 메트릭 이름 | 설명 | 레이블 | 레이블 값 |
|-------------|-------------|--------|--------------|
| `registry_storage_object_accesses_topn` | 가장 자주 액세스되는 상위 N개 개체의 총 액세스입니다. | `top_n` | `top_n`: `1`, `10`, `100`, `1000`, `10000`, `all` |

##### 히스토그램 {#histograms-4}

| 메트릭 이름 | 설명 | 레이블 | 버킷 |
|-------------|-------------|--------|---------|
| `registry_storage_blob_download_bytes` | 저장소 백엔드의 Blob 다운로드 크기 히스토그램입니다. | `redirect` | `redirect`: `true`, `false`<br>`[524288, 1048576, 67108864, 134217728, 268435456, 536870912, 1073741824, 2147483648, 3221225472, 4294967296, 5368709120, 6442450944, 7516192768, 8589934592, 9663676416, 10737418240, 21474836480, 32212254720, 42949672960, 53687091200]` (512KiB에서 50GiB) |
| `registry_storage_blob_upload_bytes` | 저장소 백엔드의 새로운 Blob 업로드 바이트 히스토그램입니다. | 없음 | `[524288, 1048576, 67108864, 134217728, 268435456, 536870912, 1073741824, 2147483648, 3221225472, 4294967296, 5368709120, 6442450944, 7516192768, 8589934592, 9663676416, 10737418240, 21474836480, 32212254720, 42949672960, 53687091200]` (512KiB에서 50GiB) |
| `registry_storage_urlcache_object_size` | URL 캐시의 개체 크기 히스토그램입니다. | 없음 | `[100, 250, 500, 750, 1000, 1500, 2048, 3072, 5120, 10240]` (100바이트에서 10KiB) |
| `registry_storage_object_accesses_distribution` | 모든 개체 간의 액세스 개수 분포입니다. | 없음 | 지수 버킷: `[10, 20, 40, 80, 160, 320, 640, 1280, 2560, 5120, 10240]` |

## 레지스트리 디버그 로그 활성화 {#enable-registry-debug-logs}

컨테이너 레지스트리의 문제 해결을 위해 디버그 로그를 활성화할 수 있습니다.

> [!warning]
> 디버그 로그에는 인증 세부 정보, 토큰 또는 리포지토리 정보와 같은 민감한 정보가 포함될 수 있습니다. 필요한 경우에만 디버그 로그를 활성화하고, 문제 해결이 완료되면 비활성화합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/var/opt/gitlab/registry/config.yml`을 편집합니다:

   ```yaml
   level: debug
   ```

1. 파일을 저장하고 레지스트리를 재시작합니다:

   ```shell
   sudo gitlab-ctl restart registry
   ```

이 구성은 임시이며 `gitlab-ctl reconfigure`을 실행할 때 삭제됩니다.

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다:

   ```yaml
   registry:
     log:
       level: debug
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab --namespace <namespace>
   ```

{{< /tab >}}

{{< /tabs >}}

### 레지스트리 Prometheus 메트릭 활성화 {#enable-registry-prometheus-metrics}

디버그 서버가 활성화되면 Prometheus 메트릭도 활성화할 수 있습니다. 이 엔드포인트는 거의 모든 레지스트리 작업과 관련된 매우 자세한 원격 분석을 노출합니다.

```ruby
registry['debug'] = {
  'prometheus' => {
    'enabled' => true,
    'path' => '/metrics'
  }
}
```

curl을 사용하여 Prometheus에서 디버그 출력을 요청합니다:

```shell
curl "localhost:5001/debug/metrics"
```

## 빈 이름의 태그 {#tags-with-an-empty-name}

[AWS DataSync](https://aws.amazon.com/datasync/)를 사용하여 컨테이너 레지스트리 데이터를 S3 버킷으로 복사하거나 S3 버킷 간에 복사하면, 대상 버킷의 각 컨테이너 레지스트리 리포지토리의 루트 경로에 빈 메타데이터 개체가 생성됩니다. 이로 인해 레지스트리가 이러한 파일을 GitLab UI 및 API에서 이름이 없는 태그로 해석하게 됩니다. 자세한 내용은 [이 이슈](https://gitlab.com/gitlab-org/container-registry/-/issues/341)를 참조하세요.

이를 해결하기 위해 두 가지 중 하나를 수행할 수 있습니다:

- AWS CLI [`rm`](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3/rm.html) 명령을 사용하여 영향을 받는 각 리포지토리의 루트에서 빈 개체를 제거합니다. 후행 `/`에 특별히 주의하고 `--recursive` 옵션을 사용하지 않도록 하세요:

  ```shell
  aws s3 rm s3://<bucket>/docker/registry/v2/repositories/<path to repository>/
  ```

- AWS CLI [`sync`](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3/sync.html) 명령을 사용하여 컨테이너 레지스트리 데이터를 새 버킷으로 복사하고 레지스트리를 사용하도록 구성합니다. 이렇게 하면 빈 개체가 뒤에 남겨집니다.

## 고급 문제 해결 {#advanced-troubleshooting}

S3 설정 문제를 진단하는 방법을 설명하기 위해 구체적인 예를 사용합니다.

### 정리 정책 조사 {#investigate-a-cleanup-policy}

정리 정책이 태그를 삭제한 이유나 삭제하지 않은 이유가 불확실한 경우, [Rails 콘솔](../operations/rails_console.md)에서 다음 스크립트를 실행하여 줄 단위로 정책을 실행합니다. 이는 정책의 문제를 진단하는 데 도움이 될 수 있습니다.

```ruby
repo = ContainerRepository.find(<repository_id>)
policy = repo.project.container_expiration_policy

tags = repo.tags
tags.map(&:name)

tags.reject!(&:latest?)
tags.map(&:name)

regex_delete = ::Gitlab::UntrustedRegexp.new("\\A#{policy.name_regex}\\z")
regex_retain = ::Gitlab::UntrustedRegexp.new("\\A#{policy.name_regex_keep}\\z")

tags.select! { |tag| regex_delete.match?(tag.name) && !regex_retain.match?(tag.name) }

tags.map(&:name)

now = DateTime.current
tags.sort_by! { |tag| tag.created_at || now }.reverse! # Lengthy operation

tags = tags.drop(policy.keep_n)
tags.map(&:name)

older_than_timestamp = ChronicDuration.parse(policy.older_than).seconds.ago

tags.select! { |tag| tag.created_at && tag.created_at < older_than_timestamp }

tags.map(&:name)
```

- 스크립트는 삭제할 태그의 목록을 작성합니다(`tags`).
- `tags.map(&:name)`은 제거할 태그의 목록을 인쇄합니다. 이는 긴 작업일 수 있습니다.
- 각 필터 후에 `tags`의 목록을 확인하여 삭제할 의도된 태그가 포함되어 있는지 확인합니다.

### 푸시 중 예상치 못한 403 오류 {#unexpected-403-error-during-push}

사용자가 S3 기반 레지스트리를 활성화하려고 했습니다. `docker login` 단계는 정상적으로 진행되었습니다. 그러나 이미지를 푸시할 때 출력은 다음과 같이 표시되었습니다:

```plaintext
The push refers to a repository [s3-testing.myregistry.com:5050/root/docker-test/docker-image]
dc5e59c14160: Pushing [==================================================>] 14.85 kB
03c20c1a019a: Pushing [==================================================>] 2.048 kB
a08f14ef632e: Pushing [==================================================>] 2.048 kB
228950524c88: Pushing 2.048 kB
6a8ecde4cc03: Pushing [==>                                                ] 9.901 MB/205.7 MB
5f70bf18a086: Pushing 1.024 kB
737f40e80b7f: Waiting
82b57dbc5385: Waiting
19429b698a22: Waiting
9436069b92a3: Waiting
error parsing HTTP 403 response body: unexpected end of JSON input: ""
```

403이 GitLab Rails 애플리케이션, Docker 레지스트리 또는 다른 곳에서 오는지 명확하지 않기 때문에 이 오류는 모호합니다. 이 경우 로그인이 성공했다는 것을 알고 있으므로 클라이언트와 레지스트리 간의 통신을 살펴봐야 합니다.

Docker 클라이언트와 레지스트리 간의 REST API는 [Docker 설명서](https://distribution.github.io/distribution/spec/api/)에 설명되어 있습니다. 일반적으로 Wireshark 또는 tcpdump를 사용하여 트래픽을 캡처하고 문제가 발생한 위치를 확인하면 됩니다. 그러나 Docker 클라이언트와 서버 간의 모든 통신이 HTTPS를 통해 이루어지므로 개인 키를 알고 있어도 트래픽을 빠르게 해독하기는 어렵습니다. 대신 무엇을 할 수 있을까요?

HTTPS를 비활성화하고 [보안되지 않은 레지스트리](https://distribution.github.io/distribution/about/insecure/)를 설정하는 한 가지 방법이 있습니다. 이는 보안 허점을 만들 수 있으며 로컬 테스트에만 권장됩니다. 프로덕션 시스템이 있고 이를 수행할 수 없거나 원하지 않는 경우, 다른 방법이 있습니다. Man-in-the-Middle 프록시를 의미하는 mitmproxy를 사용합니다.

### mitmproxy {#mitmproxy}

[mitmproxy](https://mitmproxy.org/)를 사용하면 클라이언트와 서버 사이에 프록시를 배치하여 모든 트래픽을 검사할 수 있습니다. 한 가지 주의할 점은 시스템이 mitmproxy SSL 인증서를 신뢰해야 한다는 것입니다.

다음 설치 지침은 Ubuntu를 실행 중이라고 가정합니다:

1. [mitmproxy 설치](https://docs.mitmproxy.org/stable/overview-installation/)합니다.
1. `mitmproxy --port 9000`을 실행하여 인증서를 생성합니다. <kbd>Control</kbd>-<kbd>C</kbd>를 눌러 종료합니다.
1. `~/.mitmproxy`에서 인증서를 시스템으로 설치합니다:

   ```shell
   sudo cp ~/.mitmproxy/mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitmproxy-ca-cert.crt
   sudo update-ca-certificates
   ```

성공한 경우 출력에 인증서가 추가되었음을 표시해야 합니다:

```shell
Updating certificates in /etc/ssl/certs... 1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d....done.
```

인증서가 제대로 설치되었는지 확인하려면 다음을 실행합니다:

```shell
mitmproxy --listen-port 9000
```

이 명령은 포트 `9000`에서 mitmproxy를 실행합니다. 다른 창에서 다음을 실행합니다:

```shell
curl --proxy "http://localhost:9000" "https://httpbin.org/status/200"
```

모든 것이 올바르게 설정되면 mitmproxy 창에 정보가 표시되고 curl 명령으로 오류가 생성되지 않습니다.

### 프록시를 사용하여 Docker 데몬 실행 {#running-the-docker-daemon-with-a-proxy}

Docker가 프록시를 통해 연결하려면 적절한 환경 변수로 Docker 데몬을 시작해야 합니다. 가장 쉬운 방법은 Docker를 종료하고(예: `sudo initctl stop docker`) 수동으로 Docker를 실행하는 것입니다. 루트로 다음을 실행합니다:

```shell
export HTTP_PROXY="http://localhost:9000"
export HTTPS_PROXY="http://localhost:9000"
docker daemon --debug # or dockerd --debug
```

이 명령은 Docker 데몬을 시작하고 모든 연결을 mitmproxy를 통해 프록시합니다.

### Docker 클라이언트 실행 {#running-the-docker-client}

이제 mitmproxy와 Docker가 실행 중이므로 로그인하고 컨테이너 이미지를 푸시할 수 있습니다. 이를 수행하려면 루트로 실행해야 할 수 있습니다. 예를 들어:

```shell
docker login example.s3.amazonaws.com:5050
docker push example.s3.amazonaws.com:5050/root/docker-test/docker-image
```

이전 예에서는 mitmproxy 창에서 다음 추적을 볼 수 있습니다:

```plaintext
PUT https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/uploads/(UUID)/(QUERYSTRING)
    ← 201 text/plain [no content] 661ms
HEAD https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/sha256:(SHA)
    ← 307 application/octet-stream [no content] 93ms
HEAD https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/sha256:(SHA)
    ← 307 application/octet-stream [no content] 101ms
HEAD https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/sha256:(SHA)
    ← 307 application/octet-stream [no content] 87ms
HEAD https://amazonaws.example.com/docker/registry/vs/blobs/sha256/dd/(UUID)/data(QUERYSTRING)
    ← 403 application/xml [no content] 80ms
HEAD https://amazonaws.example.com/docker/registry/vs/blobs/sha256/dd/(UUID)/data(QUERYSTRING)
    ← 403 application/xml [no content] 62ms
```

이 출력은 다음을 보여줍니다:

- 초기 PUT 요청이 `201` 상태 코드로 정상 통과했습니다.
- `201`은 클라이언트를 Amazon S3 버킷으로 리다이렉트했습니다.
- AWS 버킷에 대한 HEAD 요청이 `403 Unauthorized`을 보고했습니다.

이것이 무엇을 의미합니까? 이는 S3 사용자가 [HEAD 요청을 수행할 수 있는 올바른 권한](https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html)이 없음을 강력히 시사합니다. 해결책: [IAM 권한을 다시 확인](https://distribution.github.io/distribution/storage-drivers/s3/)합니다. 올바른 권한이 설정된 후 오류가 사라졌습니다.

## 누락된 `gitlab-registry.key`로 인해 컨테이너 레지스트리 리포지토리 삭제 불가 {#missing-gitlab-registrykey-prevents-container-repository-deletion}

GitLab 인스턴스의 컨테이너 레지스트리를 비활성화하고 컨테이너 레지스트리 리포지토리가 있는 프로젝트를 제거하려고 하면 다음 오류가 발생합니다:

```plaintext
Errno::ENOENT: No such file or directory @ rb_sysopen - /var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key
```

이 경우 다음 단계를 따릅니다:

1. 컨테이너 레지스트리에 대한 인스턴스 전체 설정을 `gitlab.rb`에서 임시로 활성화합니다:

   ```ruby
   gitlab_rails['registry_enabled'] = true
   ```

1. 파일을 저장하고 변경 사항을 적용하려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.
1. 제거를 다시 시도합니다.

일반적인 방법을 사용하여 리포지토리를 여전히 제거할 수 없는 경우, [GitLab Rails 콘솔](../operations/rails_console.md)을 사용하여 프로젝트를 강제로 제거할 수 있습니다:

```ruby
# Path to the project you'd like to remove
prj = Project.find_by_full_path(<project_path>)

# The following will delete the project's container registry, so be sure to double-check the path beforehand!
if prj.has_container_registry_tags?
  prj.container_repositories.each { |p| p.destroy }
end
```

## 레지스트리 서비스가 IPv4 대신 IPv6 주소에서 수신 {#registry-service-listens-on-ipv6-address-instead-of-ipv4}

`localhost` 호스트 이름이 GitLab 서버에서 IPv6 루프백 주소(`::1`)로 확인되고 GitLab이 레지스트리 서비스가 IPv4 루프백 주소(`127.0.0.1`)에서 사용 가능하기를 예상하는 경우 다음 오류가 표시될 수 있습니다:

```plaintext
request: "GET /v2/ HTTP/1.1", upstream: "http://[::1]:5000/v2/", host: "registry.example.com:5005"
[error] 1201#0: *13442797 connect() failed (111: Connection refused) while connecting to upstream, client: x.x.x.x, server: registry.example.com, request: "GET /v2/<path> HTTP/1.1", upstream: "http://[::1]:5000/v2/<path>", host: "registry.example.com:5005"
```

오류를 해결하려면 `registry['registry_http_addr']`을 `/etc/gitlab/gitlab.rb`의 IPv4 주소로 변경합니다. 예를 들어:

```ruby
registry['registry_http_addr'] = "127.0.0.1:5000"
```

자세한 내용은 [이슈 5449](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5449)를 참조하세요.

## Google Cloud Storage(GCS)를 사용하는 경우 푸시 실패 및 높은 CPU 사용률 {#push-failures-and-high-cpu-usage-with-google-cloud-storage-gcs}

GCS를 백엔드로 사용하는 레지스트리로 컨테이너 이미지를 푸시할 때 `502 Bad Gateway` 오류가 발생할 수 있습니다. 레지스트리는 큰 이미지를 푸시할 때 CPU 사용률 급증을 경험할 수도 있습니다.

이 문제는 레지스트리가 HTTP/2 프로토콜을 사용하여 GCS와 통신할 때 발생합니다.

해결책은 `GODEBUG` 환경 변수를 `http2client=0`로 설정하여 레지스트리 배포에서 HTTP/2를 비활성화하는 것입니다.

자세한 내용은 [이슈 1425](https://gitlab.com/gitlab-org/container-registry/-/issues/1425)를 참조하세요.
