---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 로그 시스템
description: 포괄적인 로깅 및 모니터링 기능에 액세스합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab의 로그 시스템은 GitLab 인스턴스를 분석하기 위한 포괄적인 로깅 및 모니터링 기능을 제공합니다. 로그를 사용하여 시스템 문제를 파악하고, 보안 이벤트를 조사하며, 애플리케이션 성능을 분석할 수 있습니다. 모든 작업에 대해 로그 항목이 존재하므로, 문제가 발생하면 이러한 로그는 문제를 신속하게 진단하고 해결하는 데 필요한 데이터를 제공합니다.

로그 시스템:

- 구조화된 로그 파일에서 GitLab 구성 요소 전체의 모든 애플리케이션 활동을 추적합니다.
- 표준화된 형식으로 성능 메트릭, 오류 및 보안 이벤트를 기록합니다.
- JSON 로깅을 통해 Elasticsearch 및 Splunk와 같은 로그 분석 도구와 통합됩니다.
- 다양한 GitLab 서비스 및 구성 요소에 대해 별도의 로그 파일을 유지합니다.
- 전체 시스템에서 요청을 추적하기 위한 상관관계 ID를 포함합니다.

시스템 로그 파일은 일반적으로 표준 로그 파일 형식의 일반 텍스트입니다.

로그 시스템은 [감사 이벤트](../compliance/audit_event_reports.md)와 유사합니다. 자세한 내용은 다음을 참조하십시오:

- [Linux 패키지 설치에서 로깅 사용자 지정](https://docs.gitlab.com/omnibus/settings/logs/)
- [JSON 형식의 GitLab 로그 구문 분석 및 분석](log_parsing.md)

## 로그 수준 {#log-levels}

각 로그 메시지에는 중요도와 자세한 정도를 나타내는 할당된 로그 수준이 있습니다. 각 로거에는 할당된 최소 로그 수준이 있습니다. 로거는 로그 수준이 최소 로그 수준 이상일 경우에만 로그 메시지를 내보냅니다.

다음 로그 수준이 지원됩니다:

| 수준 | 이름      |
|:------|:----------|
| 0     | `DEBUG`   |
| 1     | `INFO`    |
| 2     | `WARN`    |
| 3     | `ERROR`   |
| 4     | `FATAL`   |
| 5     | `UNKNOWN` |

GitLab 로거는 기본적으로 `DEBUG`로 설정되어 있으므로 모든 로그 메시지를 내보냅니다.

### 기본 로그 수준 재정의 {#override-default-log-level}

`GITLAB_LOG_LEVEL` 환경 변수를 사용하여 GitLab 로거의 최소 로그 수준을 재정의할 수 있습니다. 유효한 값은 `0`에서 `5` 사이의 값이거나 로그 수준의 이름입니다.

예:

```shell
GITLAB_LOG_LEVEL=info
```

일부 서비스의 경우 이 설정의 영향을 받지 않는 다른 로그 수준이 있습니다. 이러한 서비스 중 일부에는 로그 수준을 재정의할 자체 환경 변수가 있습니다. 예를 들어:

| 서비스                   | 로그 수준 | 환경 변수 |
|:--------------------------|:----------|:---------------------|
| GitLab Cleanup            | `INFO`    | `DEBUG`              |
| GitLab Doctor             | `INFO`    | `VERBOSE`            |
| GitLab Export             | `INFO`    | `EXPORT_DEBUG`       |
| GitLab Import             | `INFO`    | `IMPORT_DEBUG`       |
| GitLab QA Runtime         | `INFO`    | `QA_LOG_LEVEL`       |
| GitLab Product Usage Data | `INFO`    |                      |
| Google APIs               | `INFO`    |                      |
| Rack Timeout              | `ERROR`   |                      |
| Snowplow Tracker          | `FATAL`   |                      |
| gRPC Client (Gitaly)      | `WARN`    | `GRPC_LOG_LEVEL`     |
| LLM                       | `INFO`    | `LLM_DEBUG`          |

## 로그 회전 {#log-rotation}

주어진 서비스의 로그는 다음에 의해 관리 및 회전될 수 있습니다:

- `logrotate`
- `svlogd` (`runit`의 서비스 로깅 데몬)
- `logrotate` 및 `svlogd`
- 또는 전혀 회전하지 않음

다음 표는 어느 데몬이 포함된 서비스에 대한 로그 관리 및 회전을 담당하는지에 대한 정보를 포함합니다:

- [`svlogd`에 의해 관리되는](https://docs.gitlab.com/omnibus/settings/logs/#runit-logs) 로그는 `current`이라는 파일에 기록됩니다. 보관된 버전은 `@<hexadecimal-ID>.s` 파일로 압축됩니다.
- GitLab에 내장된 `logrotate` 서비스는 [다른 모든 로그를 관리합니다](https://docs.gitlab.com/omnibus/settings/logs/#logrotate). 보관된 버전은 `<original-name>.<number>.gz` 파일로 압축됩니다.

| 로그 유형                                        | logrotate로 관리됨    | svlogd/runit로 관리됨 |
|:------------------------------------------------|:------------------------|:------------------------|
| [Alertmanager 로그](#alertmanager-logs)         | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [Consul 로그](#consul-logs)                     | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [crond 로그](#crond-logs)                       | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [Gitaly](#gitaly-logs)                          | {{< icon name="check-circle" >}} 예  | {{< icon name="check-circle" >}} 예  |
| [Linux 패키지 설치용 GitLab Exporter](#gitlab-exporter-logs) | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [GitLab Pages 로그](#pages-logs)                | {{< icon name="check-circle" >}} 예  | {{< icon name="check-circle" >}} 예  |
| GitLab Rails                                    | {{< icon name="check-circle" >}} 예  | {{< icon name="dotted-circle" >}} 아니오  |
| [GitLab Shell 로그](#gitlab-shelllog)           | {{< icon name="check-circle" >}} 예  | {{< icon name="dotted-circle" >}} 아니오  |
| [Grafana 로그](#grafana-logs)                   | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [LogRotate 로그](#logrotate-logs)               | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [Mailroom](#mail_room_jsonlog-default)          | {{< icon name="check-circle" >}} 예  | {{< icon name="check-circle" >}} 예  |
| [NGINX](#nginx-logs)                            | {{< icon name="check-circle" >}} 예  | {{< icon name="check-circle" >}} 예  |
| [Patroni 로그](#patroni-logs)                   | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [PgBouncer 로그](#pgbouncer-logs)               | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [PostgreSQL 로그](#postgresql-logs)             | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [Praefect 로그](#praefect-logs)                 | {{< icon name="dotted-circle" >}} 예 | {{< icon name="check-circle" >}} 예  |
| [Prometheus 로그](#prometheus-logs)             | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [Puma](#puma-logs)                              | {{< icon name="check-circle" >}} 예  | {{< icon name="check-circle" >}} 예  |
| [Redis 로그](#redis-logs)                       | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [레지스트리 로그](#registry-logs)                 | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [Sentinel 로그](#sentinel-logs)                 | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [Sidekiq 로그](#sidekiq-logs)                   | {{< icon name="dotted-circle" >}} 아니오  | {{< icon name="check-circle" >}} 예  |
| [Workhorse 로그](#workhorse-logs)               | {{< icon name="check-circle" >}} 예  | {{< icon name="check-circle" >}} 예  |

이러한 로그를 생성하는 서비스에 대한 자세한 내용은 [GitLab 아키텍처 개요](../../development/architecture.md)를 참조하세요.

## Helm 차트 설치에서 로그에 액세스 {#accessing-logs-on-helm-chart-installations}

Helm 차트 설치에서 GitLab 구성 요소는 로그를 `stdout`에 보내며, `kubectl logs`를 사용하여 액세스할 수 있습니다. 로그는 포드의 수명 동안 `/var/log/gitlab`의 포드에서도 사용할 수 있습니다.

### 구조화된 로그가 있는 포드(하위 구성 요소 필터링) {#pods-with-structured-logs-subcomponent-filtering}

일부 포드에는 특정 로그 유형을 식별하는 `subcomponent` 필드가 포함되어 있습니다:

```shell
# Webservice pod logs (Rails application)
kubectl logs -l app=webservice -c webservice | jq 'select(."subcomponent"=="<subcomponent-key>")'

# Sidekiq pod logs (background jobs)
kubectl logs -l app=sidekiq | jq 'select(."subcomponent"=="<subcomponent-key>")'
```

다음 로그 섹션은 해당하는 적절한 포드 및 하위 구성 요소 키를 나타냅니다.

### 기타 포드 {#other-pods}

하위 구성 요소가 있는 구조화된 로그를 사용하지 않는 다른 GitLab 구성 요소의 경우 로그에 직접 액세스할 수 있습니다.

사용 가능한 포드 선택기를 찾으려면:

```shell
# List all unique app labels in use
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.labels.app}{"\n"}{end}' | grep -v '^$' | sort | uniq

# For pods with app labels
kubectl logs -l app=<pod-selector>

# For specific pods (when app labels aren't available)
kubectl get pods
kubectl logs <pod-name>
```

Kubernetes 문제 해결 명령에 대한 자세한 내용은 [Kubernetes 치트 시트](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet/)를 참조하세요.

## `production_json.log` {#production_jsonlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/production_json.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/production_json.log` 파일에 있습니다.
- Helm 차트 설치의 Webservice 포드 아래 `subcomponent="production_json"` 키 아래에 있습니다.

[Lograge](https://github.com/roidrage/lograge/) 덕분에 GitLab에서 수신한 Rails 컨트롤러 요청에 대한 구조화된 로그를 포함합니다. API의 요청은 `api_json.log`의 별도 파일에 기록됩니다.

각 줄에는 Elasticsearch 및 Splunk와 같은 서비스에서 수집할 수 있는 JSON이 포함되어 있습니다. 읽기 쉽도록 줄 바꿈이 예제에 추가되었습니다:

```json
{
  "method":"GET",
  "path":"/gitlab/gitlab-foss/issues/1234",
  "format":"html",
  "controller":"Projects::IssuesController",
  "action":"show",
  "status":200,
  "time":"2017-08-08T20:15:54.821Z",
  "params":[{"key":"param_key","value":"param_value"}],
  "remote_ip":"18.245.0.1",
  "user_id":1,
  "username":"admin",
  "queue_duration_s":0.0,
  "gitaly_calls":16,
  "gitaly_duration_s":0.16,
  "redis_calls":115,
  "redis_duration_s":0.13,
  "redis_read_bytes":1507378,
  "redis_write_bytes":2920,
  "correlation_id":"O1SdybnnIq7",
  "cpu_s":17.50,
  "db_duration_s":0.08,
  "view_duration_s":2.39,
  "duration_s":20.54,
  "pid": 81836,
  "worker_id":"puma_0"
}
```

이 예제는 특정 이슈에 대한 GET 요청이었습니다. 각 줄에는 성능 데이터도 포함되어 있으며, 시간은 초 단위입니다:

- `duration_s`:  요청을 검색하는 데 걸린 총 시간
- `queue_duration_s`:  GitLab Workhorse 내에 요청이 대기열에 있던 총 시간
- `view_duration_s`:  Rails 뷰 내에 있던 총 시간
- `db_duration_s`:  PostgreSQL에서 데이터를 검색하는 데 걸린 총 시간
- `cpu_s`:  CPU에 소비된 총 시간
- `gitaly_duration_s`:  Gitaly 호출의 총 시간
- `gitaly_calls`:  Gitaly에 수행된 호출의 총 개수
- `redis_calls`:  Redis에 수행된 호출의 총 개수
- `redis_cross_slot_calls`:  Redis에 수행된 교차 슬롯 호출의 총 개수
- `redis_allowed_cross_slot_calls`:  Redis에 수행된 허용된 교차 슬롯 호출의 총 개수
- `redis_duration_s`:  Redis에서 데이터를 검색하는 데 걸린 총 시간
- `redis_read_bytes`:  Redis에서 읽은 총 바이트
- `redis_write_bytes`:  Redis에 쓴 총 바이트
- `redis_<instance>_calls`:  Redis 인스턴스에 수행된 호출의 총 개수
- `redis_<instance>_cross_slot_calls`:  Redis 인스턴스에 수행된 교차 슬롯 호출의 총 개수
- `redis_<instance>_allowed_cross_slot_calls`:  Redis 인스턴스에 수행된 허용된 교차 슬롯 호출의 총 개수
- `redis_<instance>_duration_s`:  Redis 인스턴스에서 데이터를 검색하는 데 걸린 총 시간
- `redis_<instance>_read_bytes`:  Redis 인스턴스에서 읽은 총 바이트
- `redis_<instance>_write_bytes`:  Redis 인스턴스에 쓴 총 바이트
- `pid`:  워커의 Linux 프로세스 ID(워커가 다시 시작되면 변경됨)
- `worker_id`:  워커의 논리적 ID(워커가 다시 시작되어도 변경되지 않음)

HTTP 전송을 사용한 사용자 복제 및 페치 활동은 로그에 `action: git_upload_pack`로 표시됩니다.

또한 로그에는 원본 IP 주소(`remote_ip`), 사용자의 ID(`user_id`) 및 사용자 이름(`username`)이 포함되어 있습니다.

`/search`과 같은 일부 엔드포인트는 [고급 검색](../../user/search/advanced_search.md)을 사용하는 경우 Elasticsearch에 요청을 수행할 수 있습니다. 이들은 추가로 `elasticsearch_calls` 및 `elasticsearch_call_duration_s`를 기록하며, 이는 다음과 같습니다:

- `elasticsearch_calls`:  Elasticsearch에 대한 호출의 총 개수
- `elasticsearch_duration_s`:  Elasticsearch 호출이 소요된 총 시간
- `elasticsearch_timed_out_count`:  시간 초과되고 따라서 부분 결과를 반환한 Elasticsearch에 대한 호출의 총 개수

ActionCable 연결 및 구독 이벤트도 이 파일에 기록되며, 이전 형식을 따릅니다. `method`, `path` 및 `format` 필드는 적용할 수 없으며 항상 비어 있습니다. ActionCable 연결 또는 채널 클래스는 `controller`로 사용됩니다.

```json
{
  "method":null,
  "path":null,
  "format":null,
  "controller":"IssuesChannel",
  "action":"subscribe",
  "status":200,
  "time":"2020-05-14T19:46:22.008Z",
  "params":[{"key":"project_path","value":"gitlab/gitlab-foss"},{"key":"iid","value":"1"}],
  "remote_ip":"127.0.0.1",
  "user_id":1,
  "username":"admin",
  "ua":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:76.0) Gecko/20100101 Firefox/76.0",
  "correlation_id":"jSOIEynHCUa",
  "duration_s":0.32566
}
```

> [!note]
> 오류가 발생하면 `exception` 필드가 `class`, `message` 및 `backtrace`와 함께 포함됩니다. 이전 버전에는 `exception.class` 및 `exception.message` 대신 `error` 필드가 포함되었습니다. 예를 들어:

```json
{
  "method": "GET",
  "path": "/admin",
  "format": "html",
  "controller": "Admin::DashboardController",
  "action": "index",
  "status": 500,
  "time": "2019-11-14T13:12:46.156Z",
  "params": [],
  "remote_ip": "127.0.0.1",
  "user_id": 1,
  "username": "root",
  "ua": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:70.0) Gecko/20100101 Firefox/70.0",
  "queue_duration": 274.35,
  "correlation_id": "KjDVUhNvvV3",
  "queue_duration_s":0.0,
  "gitaly_calls":16,
  "gitaly_duration_s":0.16,
  "redis_calls":115,
  "redis_duration_s":0.13,
  "correlation_id":"O1SdybnnIq7",
  "cpu_s":17.50,
  "db_duration_s":0.08,
  "view_duration_s":2.39,
  "duration_s":20.54,
  "pid": 81836,
  "worker_id": "puma_0",
  "exception.class": "NameError",
  "exception.message": "undefined local variable or method `adsf' for #<Admin::DashboardController:0x00007ff3c9648588>",
  "exception.backtrace": [
    "app/controllers/admin/dashboard_controller.rb:11:in `index'",
    "ee/app/controllers/ee/admin/dashboard_controller.rb:14:in `index'",
    "ee/lib/gitlab/ip_address_state.rb:10:in `with'",
    "ee/app/controllers/ee/application_controller.rb:43:in `set_current_ip_address'",
    "lib/gitlab/session.rb:11:in `with_session'",
    "app/controllers/application_controller.rb:450:in `set_session_storage'",
    "app/controllers/application_controller.rb:444:in `set_locale'",
    "ee/lib/gitlab/jira/middleware.rb:19:in `call'"
  ]
}
```

## `production.log` {#productionlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/production.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/production.log` 파일에 있습니다.

모든 수행된 요청에 대한 정보를 포함합니다. 요청의 URL 및 유형, IP 주소 및 이 특정 요청을 처리하는 데 관련된 코드 부분을 볼 수 있습니다. 또한 수행된 모든 SQL 요청과 각각 소요된 시간을 볼 수 있습니다. 이 작업은 GitLab 기여자 및 개발자에게 더 유용합니다. 버그를 보고할 때 이 로그 파일의 일부를 사용하세요. 예를 들어:

```plaintext
Started GET "/gitlabhq/yaml_db/tree/master" for 168.111.56.1 at 2015-02-12 19:34:53 +0200
Processing by Projects::TreeController#show as HTML
  Parameters: {"project_id"=>"gitlabhq/yaml_db", "id"=>"master"}

  ... [CUT OUT]

  Namespaces"."created_at" DESC, "namespaces"."id" DESC LIMIT 1 [["id", 26]]
  CACHE (0.0ms) SELECT  "members".* FROM "members"  WHERE "members"."source_type" = 'Project' AND "members"."type" IN ('ProjectMember') AND "members"."source_id" = $1 AND "members"."source_type" = $2 AND "members"."user_id" = 1  ORDER BY "members"."created_at" DESC, "members"."id" DESC LIMIT 1  [["source_id", 18], ["source_type", "Project"]]
  CACHE (0.0ms) SELECT  "members".* FROM "members"  WHERE "members"."source_type" = 'Project' AND "members".
  (1.4ms) SELECT COUNT(*) FROM "merge_requests"  WHERE "merge_requests"."target_project_id" = $1 AND ("merge_requests"."state" IN ('opened','reopened')) [["target_project_id", 18]]
  Rendered layouts/nav/_project.html.haml (28.0ms)
  Rendered layouts/_collapse_button.html.haml (0.2ms)
  Rendered layouts/_flash.html.haml (0.1ms)
  Rendered layouts/_page.html.haml (32.9ms)
Completed 200 OK in 166ms (Views: 117.4ms | ActiveRecord: 27.2ms)
```

이 예제에서 서버는 IP `168.111.56.1`의 URL `/gitlabhq/yaml_db/tree/master`로 `2015-02-12 19:34:53 +0200`에 HTTP 요청을 처리했습니다. 요청은 `Projects::TreeController`에 의해 처리되었습니다.

## `api_json.log` {#api_jsonlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/api_json.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/api_json.log` 파일에 있습니다.
- Helm 차트 설치의 Webservice 포드 아래 `subcomponent="api_json"` 키 아래에 있습니다.

API에 직접 수행된 요청을 볼 수 있습니다. 예를 들어:

```json
{
  "time":"2018-10-29T12:49:42.123Z",
  "severity":"INFO",
  "duration":709.08,
  "db":14.59,
  "view":694.49,
  "status":200,
  "method":"GET",
  "path":"/api/v4/projects",
  "params":[{"key":"action","value":"git-upload-pack"},{"key":"changes","value":"_any"},{"key":"key_id","value":"secret"},{"key":"secret_token","value":"[FILTERED]"}],
  "host":"localhost",
  "remote_ip":"::1",
  "ua":"Ruby",
  "route":"/api/:version/projects",
  "user_id":1,
  "username":"root",
  "queue_duration":100.31,
  "gitaly_calls":30,
  "gitaly_duration":5.36,
  "pid": 81836,
  "worker_id": "puma_0",
  ...
}
```

이 항목은 관련 SSH 키가 `git fetch` 또는 `git clone`를 사용하여 문제의 프로젝트를 다운로드할 수 있는지 확인하기 위해 액세스된 내부 엔드포인트를 보여줍니다. 이 예제에서 우리는 다음을 봅니다:

- `duration`:  요청을 검색하는 데 걸린 총 시간(밀리초)
- `queue_duration`:  GitLab Workhorse 내에 요청이 대기열에 있던 총 시간(밀리초)
- `method`:  요청을 수행하는 데 사용된 HTTP 메서드
- `path`:  쿼리의 상대 경로
- `params`:  쿼리 문자열 또는 HTTP 본문에 전달된 키-값 쌍(비밀번호 및 토큰과 같은 민감한 매개변수는 필터링됨)
- `ua`:  요청자의 사용자 에이전트

> [!note]
> [`Grape Logging`](https://github.com/aserafin/grape_logging) v1.8.4에서 `view_duration_s`는 [`duration_s - db_duration_s`](https://github.com/aserafin/grape_logging/blob/v1.8.4/lib/grape_logging/middleware/request_logger.rb#L117-L119)에 의해 계산됩니다. 따라서 `view_duration_s`는 Redis 또는 외부 HTTP의 읽기/쓰기 프로세스와 같은 다양한 요인뿐만 아니라 직렬화 프로세스에만 의해 영향을 받을 수 있습니다.

## `application.log` (더 이상 사용되지 않음) {#applicationlog-deprecated}

{{< history >}}

- GitLab 15.10에서 [더 이상 사용되지 않습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111046).

{{< /history >}}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/application.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/application.log` 파일에 있습니다.

[`application_json.log`](#application_jsonlog)의 덜 구조화된 버전의 로그를 포함하며, 다음은 한 예입니다:

```plaintext
October 06, 2014 11:56: User "Administrator" (admin@example.com) was created
October 06, 2014 11:56: Documentcloud created a new project "Documentcloud / Underscore"
October 06, 2014 11:56: Gitlab Org created a new project "Gitlab Org / Gitlab Ce"
October 07, 2014 11:25: User "Claudie Hodkiewicz" (nasir_stehr@olson.co.uk)  was removed
October 07, 2014 11:25: Project "project133" was removed
```

## `application_json.log` {#application_jsonlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/application_json.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/application_json.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="application_json"` 키 아래에 있습니다.

사용자 생성 및 프로젝트 삭제와 같이 인스턴스에서 발생하는 이벤트를 발견하는 데 도움이 됩니다. 예를 들어:

```json
{
  "severity":"INFO",
  "time":"2020-01-14T13:35:15.466Z",
  "correlation_id":"3823a1550b64417f9c9ed8ee0f48087e",
  "message":"User \"Administrator\" (admin@example.com) was created"
}
{
  "severity":"INFO",
  "time":"2020-01-14T13:35:15.466Z",
  "correlation_id":"78e3df10c9a18745243d524540bd5be4",
  "message":"Project \"project133\" was removed"
}
```

## `integrations_json.log` {#integrations_jsonlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/integrations_json.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/integrations_json.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="integrations_json"` 키 아래에 있습니다.

Jira, Asana 및 irker 서비스와 같은 [통합](../../user/project/integrations/_index.md) 활동에 대한 정보를 포함합니다. JSON 형식을 사용하며, 다음은 한 예입니다:

```json
{
  "severity":"ERROR",
  "time":"2018-09-06T14:56:20.439Z",
  "service_class":"Integrations::Jira",
  "project_id":8,
  "project_path":"h5bp/html5-boilerplate",
  "message":"Error sending message",
  "client_url":"http://jira.gitlab.com:8080",
  "error":"execution expired"
}
{
  "severity":"INFO",
  "time":"2018-09-06T17:15:16.365Z",
  "service_class":"Integrations::Jira",
  "project_id":3,
  "project_path":"namespace2/project2",
  "message":"Successfully posted",
  "client_url":"http://jira.example.com"
}
```

## `kubernetes.log` (더 이상 사용되지 않음) {#kuberneteslog-deprecated}

{{< history >}}

- GitLab 14.5에서 [더 이상 사용되지 않습니다](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).

{{< /history >}}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/kubernetes.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/kubernetes.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 포드 아래 `subcomponent="kubernetes"` 키 아래에 있습니다.

연결 오류와 같은 [인증서 기반 클러스터](../../user/project/clusters/_index.md)와 관련된 정보를 기록합니다. 각 줄에는 Elasticsearch 및 Splunk와 같은 서비스에서 수집할 수 있는 JSON이 포함되어 있습니다.

## `git_json.log` {#git_jsonlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/git_json.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/git_json.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 포드 아래 `subcomponent="git_json"` 키 아래에 있습니다.

GitLab은 Git 리포지토리와 상호 작용해야 하지만 드문 경우이지만 문제가 발생할 수 있습니다. 이 경우 정확히 무엇이 일어났는지 알아야 합니다. 이 로그 파일에는 GitLab에서 Git 로의 실패한 모든 요청이 포함됩니다. 대부분의 경우 이 파일은 개발자에게만 유용합니다. 예를 들어:

```json
{
   "severity":"ERROR",
   "time":"2019-07-19T22:16:12.528Z",
   "correlation_id":"FeGxww5Hj64",
   "message":"Command failed [1]: /usr/bin/git --git-dir=/Users/vsizov/gitlab-development-kit/gitlab/tmp/tests/gitlab-satellites/group184/gitlabhq/.git --work-tree=/Users/vsizov/gitlab-development-kit/gitlab/tmp/tests/gitlab-satellites/group184/gitlabhq merge --no-ff -mMerge branch 'feature_conflict' into 'feature' source/feature_conflict\n\nerror: failed to push some refs to '/Users/vsizov/gitlab-development-kit/repositories/gitlabhq/gitlab_git.git'"
}
```

## `audit_json.log` {#audit_jsonlog}

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> GitLab Free는 다양한 감사 의 작은 수를 추적합니다. GitLab Premium은 훨씬 더 많은 것을 추적합니다.

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/audit_json.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/audit_json.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="audit_json"` 키 아래에 있습니다.

그룹 또는 프로젝트 설정 및 멤버십(`target_details`)에 대한 변경 사항이 이 파일에 기록됩니다. 예를 들어:

```json
{
  "severity":"INFO",
  "time":"2018-10-17T17:38:22.523Z",
  "author_id":3,
  "entity_id":2,
  "entity_type":"Project",
  "change":"visibility",
  "from":"Private",
  "to":"Public",
  "author_name":"John Doe4",
  "target_id":2,
  "target_type":"Project",
  "target_details":"namespace2/project2"
}
```

## Sidekiq 로그 {#sidekiq-logs}

Linux 패키지 설치의 경우 일부 Sidekiq 로그는 `/var/log/gitlab/sidekiq/current`에 있으며 다음과 같습니다.

### `sidekiq.log` {#sidekiqlog}

{{< history >}}

- Helm 차트 설치의 기본 로그 형식이 GitLab 16.0 이상에서 [`text`에서 `json`로 변경되었습니다](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3169).

{{< /history >}}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/sidekiq/current` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/sidekiq.log` 파일에 있습니다.

GitLab은 오랜 시간이 걸릴 수 있는 을 처리하기 위해 백그라운드 을 사용합니다. 이러한 처리에 대한 모든 정보가 이 파일에 기록됩니다. 예를 들어:

```json
{
  "severity":"INFO",
  "time":"2018-04-03T22:57:22.071Z",
  "queue":"cronjob:update_all_mirrors",
  "args":[],
  "class":"UpdateAllMirrorsWorker",
  "retry":false,
  "queue_namespace":"cronjob",
  "jid":"06aeaa3b0aadacf9981f368e",
  "created_at":"2018-04-03T22:57:21.930Z",
  "enqueued_at":"2018-04-03T22:57:21.931Z",
  "pid":10077,
  "worker_id":"sidekiq_0",
  "message":"UpdateAllMirrorsWorker JID-06aeaa3b0aadacf9981f368e: done: 0.139 sec",
  "job_status":"done",
  "duration":0.139,
  "completed_at":"2018-04-03T22:57:22.071Z",
  "db_duration":0.05,
  "db_duration_s":0.0005,
  "gitaly_duration":0,
  "gitaly_calls":0
}
```

JSON 로그 대신, Sidekiq의 텍스트 로그를 생성하도록 선택할 수 있습니다. 예를 들어:

```plaintext
2023-05-16T16:08:55.272Z pid=82525 tid=23rl INFO: Initializing websocket
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: Booted Rails 6.1.7.2 application in production environment
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: Running in ruby 3.0.5p211 (2022-11-24 revision ba5cf0f7c5) [arm64-darwin22]
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: See LICENSE and the LGPL-3.0 for licensing details.
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: Upgrade to Sidekiq Pro for more features and support: https://sidekiq.org
2023-05-16T16:08:55.286Z pid=82525 tid=7p4t INFO: Cleaning working queues
2023-05-16T16:09:06.043Z pid=82525 tid=7p7d class=ScheduleMergeRequestCleanupRefsWorker jid=efcc73f169c09a514b06da3f INFO: start
2023-05-16T16:09:06.050Z pid=82525 tid=7p7d class=ScheduleMergeRequestCleanupRefsWorker jid=efcc73f169c09a514b06da3f INFO: arguments: []
2023-05-16T16:09:06.065Z pid=82525 tid=7p81 class=UserStatusCleanup::BatchWorker jid=e279aa6409ac33031a314822 INFO: start
2023-05-16T16:09:06.066Z pid=82525 tid=7p81 class=UserStatusCleanup::BatchWorker jid=e279aa6409ac33031a314822 INFO: arguments: []
```

Linux 패키지 설치의 경우 구성 옵션을 추가합니다:

```ruby
sidekiq['log_format'] = 'text'
```

자체 컴파일된 설치의 경우 `gitlab.yml`를 편집하고 Sidekiq `log_format` 구성 옵션을 설정합니다:

```yaml
  ## Sidekiq
  sidekiq:
    log_format: text
```

### `sidekiq_client.log` {#sidekiq_clientlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/sidekiq_client.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/sidekiq_client.log` 파일에 있습니다.
- Helm 차트 설치의 Webservice 포드 아래 `subcomponent="sidekiq_client"` 키 아래에 있습니다.

이 파일에는 Sidekiq이 대기열에 추가되기 전과 같이 처리를 시작하기 전의 에 대한 로깅 정보가 포함되어 있습니다.

이 로그 파일은 [`sidekiq.log`](#sidekiqlog)와 동일한 구조를 따르므로, Sidekiq에 대해 이를 구성한 경우 JSON으로 구조화됩니다.

## `gitlab-shell.log` {#gitlab-shelllog}

GitLab Shell은 Git 명령 실행 및 Git 에 SSH 액세스를 제공하는 데 GitLab에서 사용됩니다.

`git-{upload-pack,receive-pack}` 요청을 포함하는 정보는 `/var/log/gitlab/gitlab-shell/gitlab-shell.log`에 있습니다. Gitaly의 GitLab Shell에 대한 후크 정보는 `/var/log/gitlab/gitaly/current`에 있습니다.

`/var/log/gitlab/gitlab-shell/gitlab-shell.log`의 예제 로그 항목:

```json
{
  "duration_ms": 74.104,
  "level": "info",
  "method": "POST",
  "msg": "Finished HTTP request",
  "time": "2020-04-17T20:28:46Z",
  "url": "http://127.0.0.1:8080/api/v4/internal/allowed"
}
{
  "command": "git-upload-pack",
  "git_protocol": "",
  "gl_project_path": "root/example",
  "gl_repository": "project-1",
  "level": "info",
  "msg": "executing git command",
  "time": "2020-04-17T20:28:46Z",
  "user_id": "user-1",
  "username": "root"
}
```

`/var/log/gitlab/gitaly/current`의 예제 로그 항목:

```json
{
  "method": "POST",
  "url": "http://127.0.0.1:8080/api/v4/internal/allowed",
  "duration": 0.058012959,
  "gitaly_embedded": true,
  "pid": 16636,
  "level": "info",
  "msg": "finished HTTP request",
  "time": "2020-04-17T20:29:08+00:00"
}
{
  "method": "POST",
  "url": "http://127.0.0.1:8080/api/v4/internal/pre_receive",
  "duration": 0.031022552,
  "gitaly_embedded": true,
  "pid": 16636,
  "level": "info",
  "msg": "finished HTTP request",
  "time": "2020-04-17T20:29:08+00:00"
}
```

## Gitaly 로그 {#gitaly-logs}

이 파일은 `/var/log/gitlab/gitaly/current`에 있으며 [runit](https://smarden.org/runit/)에 의해 생성됩니다. `runit`는 Linux 패키지와 함께 패키지되며, 그 목적에 대한 간단한 설명은 [Linux 패키지 문서](https://docs.gitlab.com/omnibus/architecture/#runit)에서 사용할 수 있습니다.

### `grpc.log` {#grpclog}

이 파일은 Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/grpc.log`에 있습니다. Gitaly에서 사용되는 네이티브 [gRPC](https://grpc.io/) 로깅입니다.

### `gitaly_hooks.log` {#gitaly_hookslog}

이 파일은 `/var/log/gitlab/gitaly/gitaly_hooks.log`에 있으며 `gitaly-hooks` 명령으로 생성됩니다. GitLab API의 응답 처리 중에 수신된 실패에 대한 기록도 포함합니다.

## Puma 로그 {#puma-logs}

### `puma_stdout.log` {#puma_stdoutlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/puma/puma_stdout.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/puma_stdout.log` 파일에 있습니다.

### `puma_stderr.log` {#puma_stderrlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/puma/puma_stderr.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/puma_stderr.log` 파일에 있습니다.

## `repocheck.log` {#repochecklog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/repocheck.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/repocheck.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 포드 아래 `subcomponent="repocheck"` 키 아래에 있습니다.

프로젝트에서 [검사가 실행될](../repository_checks.md) 때마다 정보를 기록합니다.

## `importer.log` {#importerlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/importer.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/importer.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 포드 아래 `subcomponent="importer"` 키 아래에 있습니다.

이 파일은 [가져오기 및 마이그레이션](../../user/import/_index.md)의 진행 상황을 기록합니다.

## `exporter.log` {#exporterlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/exporter.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/exporter.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="exporter"` 키 아래에 있습니다.

내보내기 프로세스의 진행 상황을 기록합니다.

## `features_json.log` {#features_jsonlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/features_json.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/features_json.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="features_json"` 키 아래에 있습니다.

GitLab 개발에서 의 수정 이벤트가 이 파일에 기록됩니다. 예를 들어:

```json
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable","extra.thing":"true"}
{"severity":"INFO","time":"2020-11-24T02:31:29.108Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable","extra.thing":"true"}
{"severity":"INFO","time":"2020-11-24T02:31:29.129Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable","extra.thing":"false"}
{"severity":"INFO","time":"2020-11-24T02:31:29.177Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable","extra.thing":"Project:1"}
{"severity":"INFO","time":"2020-11-24T02:31:29.183Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable","extra.thing":"Project:1"}
{"severity":"INFO","time":"2020-11-24T02:31:29.188Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable_percentage_of_time","extra.percentage":"50"}
{"severity":"INFO","time":"2020-11-24T02:31:29.193Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable_percentage_of_time"}
{"severity":"INFO","time":"2020-11-24T02:31:29.198Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable_percentage_of_actors","extra.percentage":"50"}
{"severity":"INFO","time":"2020-11-24T02:31:29.203Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable_percentage_of_actors"}
{"severity":"INFO","time":"2020-11-24T02:31:29.329Z","correlation_id":null,"key":"cd_auto_rollback","action":"remove"}
```

## `ci_resource_groups_json.log` {#ci_resource_groups_jsonlog}

{{< history >}}

- GitLab 15.9에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/384180).

{{< /history >}}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/ci_resource_groups_json.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/ci_resource_group_json.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="ci_resource_groups_json"` 키 아래에 있습니다.

[그룹](../../ci/resource_groups/_index.md) 획득에 대한 정보를 포함합니다. 예를 들어:

```json
{"severity":"INFO","time":"2023-02-10T23:02:06.095Z","correlation_id":"01GRYS10C2DZQ9J1G12ZVAD4YD","resource_group_id":1,"processable_id":288,"message":"attempted to assign resource to processable","success":true}
{"severity":"INFO","time":"2023-02-10T23:02:08.945Z","correlation_id":"01GRYS138MYEG32C0QEWMC4BDM","resource_group_id":1,"processable_id":288,"message":"attempted to release resource from processable","success":true}
```

예제는 각 항목에 대한 `resource_group_id`, `processable_id`, `message` 및 `success` 필드를 보여줍니다.

## `auth.log` {#authlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/auth.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/auth.log` 파일에 있습니다.

이 로그는 다음을 기록합니다:

- 원본 엔드포인트의 [제한](../settings/rate_limits_on_raw_endpoints.md)을 초과하는 요청입니다.
- [보호된 경로](../settings/protected_paths.md) 남용 요청입니다.
- 사용자 ID 및 사용자 이름(사용 가능한 경우)입니다.

## `auth_json.log` {#auth_jsonlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/auth_json.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/auth_json.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="auth_json"` 키 아래에 있습니다.

이 파일에는 `auth.log`의 JSON 버전 로그가 포함되며, 예를 들어:

```json
{
    "severity":"ERROR",
    "time":"2023-04-19T22:14:25.893Z",
    "correlation_id":"01GYDSAKAN2SPZPAMJNRWW5H8S",
    "message":"Rack_Attack",
    "env":"blocklist",
    "remote_ip":"x.x.x.x",
    "request_method":"GET",
    "path":"/group/project.git/info/refs?service=git-upload-pack"
}
```

## `graphql_json.log` {#graphql_jsonlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/graphql_json.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/graphql_json.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="graphql_json"` 키 아래에 있습니다.

GraphQL 쿼리가 파일에 기록됩니다. 예를 들어:

```json
{"query_string":"query IntrospectionQuery{__schema {queryType { name },mutationType { name }}}...(etc)","variables":{"a":1,"b":2},"complexity":181,"depth":1,"duration_s":7}
```

## `clickhouse.log` {#clickhouselog}

{{< history >}}

- GitLab 16.5에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133371).

{{< /history >}}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/clickhouse.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/clickhouse.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="clickhouse"` 키 아래에 있습니다.

`clickhouse.log` 파일은 GitLab의 [ClickHouse 데이터베이스 클라이언트](../../integration/clickhouse.md)와 관련된 정보를 기록합니다.

## `migrations.log` {#migrationslog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/migrations.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/migrations.log` 파일에 있습니다.

이 파일은 [데이터베이스 마이그레이션](../raketasks/maintenance.md#display-status-of-database-migrations)의 진행 상황을 기록합니다.

## `mail_room_json.log` (기본값) {#mail_room_jsonlog-default}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/mailroom/current` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/mail_room_json.log` 파일에 있습니다.

이 구조화된 로그 파일은 `mail_room` gem의 내부 활동을 기록합니다. 이름과 경로는 구성 가능하므로 이름과 경로가 이전에 문서화된 것과 일치하지 않을 수 있습니다.

## `web_hooks.log` {#web_hookslog}

{{< history >}}

- GitLab 16.3에서 도입되었습니다.

{{< /history >}}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/web_hooks.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/web_hooks.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 포드 아래 `subcomponent="web_hooks"` 키 아래에 있습니다.

Webhook의 백오프, 비활성화 및 재활성화 이벤트가 이 파일에 기록됩니다. 예를 들어:

```json
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","hook_id":12,"action":"backoff","disabled_until":"2020-11-24T04:30:59.860Z","recent_failures":2}
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","hook_id":12,"action":"disable","disabled_until":null,"recent_failures":100}
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","hook_id":12,"action":"enable","disabled_until":null,"recent_failures":0}
```

## 재구성 로그 {#reconfigure-logs}

재구성 로그 파일은 Linux 패키지 설치의 `/var/log/gitlab/reconfigure`에 있습니다. 자체 컴파일된 설치에는 재구성 로그가 없습니다. `gitlab-ctl reconfigure`를 수동으로 실행하거나 업그레이드의 일부로 실행할 때마다 재구성 로그가 채워집니다.

재구성 로그 파일은 재구성이 시작된 시간의 UNIX 타임스탬프에 따라 이름이 지정되며, 예: `1509705644.log`

## `sidekiq_exporter.log` 및 `web_exporter.log` {#sidekiq_exporterlog-and-web_exporterlog}

Prometheus 메트릭 및 Sidekiq Exporter가 모두 활성화된 경우 Sidekiq은 웹 서버를 시작하고 정의된 포트(기본값: `8082`)에서 수신 대기합니다. 기본적으로 Sidekiq Exporter 액세스 로그는 비활성화되어 있지만 활성화할 수 있습니다:

- Linux 패키지 설치의 `/etc/gitlab/gitlab.rb`에서 `sidekiq['exporter_log_enabled'] = true` 옵션을 사용합니다.
- 자체 컴파일된 설치의 `gitlab.yml`에서 `sidekiq_exporter.log_enabled` 옵션을 사용합니다.

활성화된 경우 설치 방법에 따라 이 파일은 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/sidekiq_exporter.log`.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/sidekiq_exporter.log`.

Prometheus 메트릭 및 웹 Exporter가 모두 활성화된 경우 Puma는 웹 서버를 시작하고 정의된 포트(기본값: `8083`)에서 수신 대기하며, 액세스 로그는 설치 방법에 따라 위치에서 생성됩니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/web_exporter.log`.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/web_exporter.log`.

## `database_load_balancing.log` {#database_load_balancinglog}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab [로드 밸런싱](../postgresql/database_load_balancing.md)의 세부 정보를 포함합니다.

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/database_load_balancing.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/database_load_balancing.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="database_load_balancing"` 키 아래에 있습니다.

## `zoekt.log` {#zoektlog}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.9에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110980).

{{< /history >}}

이 파일은 [정확한 코드 검색](../../user/search/exact_code_search.md)과 관련된 정보를 기록합니다.

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/zoekt.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/zoekt.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="zoekt"` 키 아래에 있습니다.

## `elasticsearch.log` {#elasticsearchlog}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 파일은 Elasticsearch 통합과 관련된 정보를 기록하며, Elasticsearch를 인덱싱하거나 검색할 때의 오류를 포함합니다.

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/elasticsearch.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/elasticsearch.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="elasticsearch"` 키 아래에 있습니다.

각 줄에는 Elasticsearch 및 Splunk와 같은 서비스에서 수집할 수 있는 JSON이 포함되어 있습니다. 명확성을 위해 다음 예제 줄에 줄 바꿈이 추가되었습니다:

```json
{
  "severity":"DEBUG",
  "time":"2019-10-17T06:23:13.227Z",
  "correlation_id":null,
  "message":"redacted_search_result",
  "class_name":"Milestone",
  "id":2,
  "ability":"read_milestone",
  "current_user_id":2,
  "query":"project"
}
```

## `exceptions_json.log` {#exceptions_jsonlog}

이 파일은 `Gitlab::ErrorTracking`에 의해 추적 중인 예외에 대한 정보를 기록하며, 구조화되고 일관된 구조 예외 처리 방식을 제공합니다.

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/exceptions_json.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/exceptions_json.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="exceptions_json"` 키 아래에 있습니다.

각 줄에는 Elasticsearch에서 수집할 수 있는 JSON이 포함되어 있습니다. 예를 들어:

```json
{
  "severity": "ERROR",
  "time": "2019-12-17T11:49:29.485Z",
  "correlation_id": "AbDVUrrTvM1",
  "extra.project_id": 55,
  "extra.relation_key": "milestones",
  "extra.relation_index": 1,
  "exception.class": "NoMethodError",
  "exception.message": "undefined method `strong_memoize' for #<Gitlab::ImportExport::RelationFactory:0x00007fb5d917c4b0>",
  "exception.backtrace": [
    "lib/gitlab/import_export/relation_factory.rb:329:in `unique_relation?'",
    "lib/gitlab/import_export/relation_factory.rb:345:in `find_or_create_object!'"
  ]
}
```

## `service_measurement.log` {#service_measurementlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/service_measurement.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/service_measurement.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="service_measurement"` 키 아래에 있습니다.

각 서비스 실행에 대한 측정을 포함하는 단일 구조화된 로그만 포함합니다. SQL 호출 수, `execution_time`, `gc_stats` 및 `memory usage`와 같은 측정을 포함합니다.

예를 들어:

```json
{ "severity":"INFO", "time":"2020-04-22T16:04:50.691Z","correlation_id":"04f1366e-57a1-45b8-88c1-b00b23dc3616","class":"Projects::ImportExport::ExportService","current_user":"John Doe","project_full_path":"group1/test-export","file_path":"/path/to/archive","gc_stats":{"count":{"before":127,"after":127,"diff":0},"heap_allocated_pages":{"before":10369,"after":10369,"diff":0},"heap_sorted_length":{"before":10369,"after":10369,"diff":0},"heap_allocatable_pages":{"before":0,"after":0,"diff":0},"heap_available_slots":{"before":4226409,"after":4226409,"diff":0},"heap_live_slots":{"before":2542709,"after":2641420,"diff":98711},"heap_free_slots":{"before":1683700,"after":1584989,"diff":-98711},"heap_final_slots":{"before":0,"after":0,"diff":0},"heap_marked_slots":{"before":2542704,"after":2542704,"diff":0},"heap_eden_pages":{"before":10369,"after":10369,"diff":0},"heap_tomb_pages":{"before":0,"after":0,"diff":0},"total_allocated_pages":{"before":10369,"after":10369,"diff":0},"total_freed_pages":{"before":0,"after":0,"diff":0},"total_allocated_objects":{"before":24896308,"after":24995019,"diff":98711},"total_freed_objects":{"before":22353599,"after":22353599,"diff":0},"malloc_increase_bytes":{"before":140032,"after":6650240,"diff":6510208},"malloc_increase_bytes_limit":{"before":25804104,"after":25804104,"diff":0},"minor_gc_count":{"before":94,"after":94,"diff":0},"major_gc_count":{"before":33,"after":33,"diff":0},"remembered_wb_unprotected_objects":{"before":34284,"after":34284,"diff":0},"remembered_wb_unprotected_objects_limit":{"before":68568,"after":68568,"diff":0},"old_objects":{"before":2404725,"after":2404725,"diff":0},"old_objects_limit":{"before":4809450,"after":4809450,"diff":0},"oldmalloc_increase_bytes":{"before":140032,"after":6650240,"diff":6510208},"oldmalloc_increase_bytes_limit":{"before":68537556,"after":68537556,"diff":0}},"time_to_finish":0.12298400001600385,"number_of_sql_calls":70,"memory_usage":"0.0 MiB","label":"process_48616"}
```

## `geo.log` {#geolog}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/geo.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/geo.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="geo"` 키 아래에 있습니다.

이 파일에는 Geo가 리포지토리 및 파일을 동기화하려고 시도할 때에 대한 정보가 포함되어 있습니다. 파일의 각 줄에는 (예: Elasticsearch 또는 Splunk로) 수집할 수 있는 별도의 JSON 항목이 포함되어 있습니다.

예를 들어:

```json
{"severity":"INFO","time":"2017-08-06T05:40:16.104Z","message":"Repository update","project_id":1,"source":"repository","resync_repository":true,"resync_wiki":true,"class":"Gitlab::Geo::LogCursor::Daemon","cursor_delay_s":0.038}
```

이 메시지는 Geo가 `1`에 필요한 업데이트를 감지했음을 보여줍니다.

## `update_mirror_service_json.log` {#update_mirror_service_jsonlog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/update_mirror_service_json.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/update_mirror_service_json.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 포드 아래 `subcomponent="update_mirror_service_json"` 키 아래에 있습니다.

이 파일에는 미러링 중에 발생한 LFS 오류에 대한 정보가 포함되어 있습니다. 다른 미러링 오류를 이 로그로 이동하기 위해 작업하는 동안 [일반 로그](#productionlog)를 사용할 수 있습니다.

```json
{
   "severity":"ERROR",
   "time":"2020-07-28T23:29:29.473Z",
   "correlation_id":"5HgIkCJsO53",
   "user_id":"x",
   "project_id":"x",
   "import_url":"https://mirror-source/group/project.git",
   "error_message":"The LFS objects download list couldn't be imported. Error: Unauthorized"
}
```

## `llm.log` {#llmlog}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.0에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120506).

{{< /history >}}

`llm.log` 파일은 [AI 기능](../../user/gitlab_duo/_index.md)과 관련된 정보를 기록합니다. 로깅에는 AI 이벤트에 대한 정보가 포함됩니다.

### LLM 입력 및 출력 로깅 {#llm-input-and-output-logging}

{{< history >}}

- GitLab 17.2에서 [도입되었으며](https://gitlab.com/groups/gitlab-org/-/epics/13401) [플래그](../feature_flags/_index.md) `expanded_ai_logging`라는 이름의 이름을 가지고 있습니다. 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 플래그에 의해 제어됩니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트용으로 사용 가능하지만 프로덕션 사용을 위한 준비가 되어 있지 않습니다.

LLM 프롬프트 입력 및 응답 출력을 기록하려면 `expanded_ai_logging` 플래그를 활성화합니다. 이 플래그는 GitLab Self-Managed 인스턴스가 아닌 GitLab.com에서만 사용하기 위한 것입니다.

이 플래그는 기본적으로 비활성화되어 있으며 다음과 같이만 활성화할 수 있습니다:

- GitLab.com의 경우, GitLab [지원 티켓](https://about.gitlab.com/support/portal/)을 통해 동의를 제공할 때입니다.

기본적으로 로그에는 AI 데이터의 [데이터 보존 정책](../../user/gitlab_duo/data_usage.md#data-retention)을 지원하기 위해 LLM 프롬프트 입력 및 응답 출력이 포함되지 않습니다.

로그 파일은 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/llm.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/llm.log` 파일에 있습니다.
- Helm 차트 설치의 Webservice 포드 아래 `subcomponent="llm"` 키 아래에 있습니다.

## `epic_work_item_sync.log` {#epic_work_item_synclog}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.9에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120506).

{{< /history >}}

`epic_work_item_sync.log` 파일은 을 항목으로 동기화 및 마이그레이션하는 것과 관련된 정보를 기록합니다.

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/epic_work_item_sync.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/epic_work_item_sync.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 및 Webservice 포드 아래 `subcomponent="epic_work_item_sync"` 키 아래에 있습니다.

## `secret_push_protection.log` {#secret_push_protectionlog}

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab.com, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.7에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137812).

{{< /history >}}

`secret_push_protection.log` 파일은 [비밀 푸시 보호](../../user/application_security/secret_detection/secret_push_protection/_index.md) 과 관련된 정보를 기록합니다.

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/secret_push_protection.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/secret_push_protection.log` 파일에 있습니다.
- Helm 차트 설치의 Webservice 포드 아래 `subcomponent="secret_push_protection"` 키 아래에 있습니다.

## `active_context.log` {#active_contextlog}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 18.3에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/work_items/554925).

{{< /history >}}

`active_context.log` 파일은 [`ActiveContext` 레이어](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_context_abstraction_layer/)를 통한 임베딩 과 관련된 정보를 기록합니다.

GitLab은 `ActiveContext` 코드 임베딩을 지원합니다. 이 은 코드 파일의 임베딩 생성을 처리합니다. 자세한 내용은 [아키텍처 설계](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/codebase_as_chat_context/code_embeddings/)를 참조하세요.

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/active_context.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/active_context.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 포드 아래 `subcomponent="activecontext"` 키 아래에 있습니다.

## `ai_catalog.log` {#ai_cataloglog}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.8에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/576627).

{{< /history >}}

`ai_catalog.log` 파일은 [카탈로그](../../user/duo_agent_platform/ai_catalog.md)와 관련된 정보를 기록하며, 카탈로그 및 에이전트가 실행될 때를 포함합니다.

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/ai_catalog.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/ai_catalog.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 포드 아래 `subcomponent="ai_catalog"` 키 아래에 있습니다.

## `user_experience_slis.log` {#user_experience_slislog}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/user_experience_slis.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/user_experience_slis.log` 파일에 있습니다.
- Helm 차트 설치의 Webservice 포드 아래 `subcomponent="user_experience_slis"` 키 아래에 있습니다.

사용자 경험 SLI와 일치하는 사용자 경험 SLI에 대한 JSON 구조화 로그를 포함합니다.

각 줄에는 Elasticsearch와 같은 서비스에서 수집할 수 있는 JSON이 포함되어 있습니다.

예:

```json
{
  "checkpoint": "start",
  "component": "gitlab",
  "correlation_id": "3823a1550b64417f9c9ed8ee0f48087e",
  "covered_experience": "create_merge_request",
  "elapsed_time_s": 0,
  "environment": "gprd",
  "feature_category": "code_review_workflow",
  "logtag": "F",
  "meta": {
    "caller_id": "Projects::MergeRequests::CreationsController#create",
    "client_id": "user/123",
    "feature_category": "code_review_workflow",
    "gl_user_id": 123,
    "organization_id": 456,
    "project": "project/path/here",
    "remote_ip": "x.x.x.x",
    "root_namespace": "project",
    "subscription_plan": "ultimate",
    "user": "a_username"
  },
  "severity": "INFO",
  "shard": "default",
  "stage": "cny",
  "start_time": "2025-10-31 15:21:40 UTC",
  "subcomponent": "user_experience_slis",
  "tag": "web-cny-rails.var.log.containers.gitlab-cny-webservice-web-123-abc_gitlab-cny_webservice-4567890.log",
  "tier": "sv",
  "time": "2025-10-31T15:21:40.333Z",
  "type": "web",
  "urgency": "async_fast",
  "urgency_threshold_s": 15
}
```

사용 가능한 필드는 [사용자 경험 SLI의 설계 문서](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/user_experience_slis/#sdk-requirements)에서 설명합니다.

## 레지스트리 로그 {#registry-logs}

Linux 패키지 설치의 경우 로그는 `/var/log/gitlab/registry/current`에 있습니다.

## NGINX 로그 {#nginx-logs}

Linux 패키지 설치의 경우 NGINX 로그는 다음에 있습니다:

- `/var/log/gitlab/nginx/gitlab_access.log`:  GitLab에 수행된 요청의 로그
- `/var/log/gitlab/nginx/gitlab_error.log`:  GitLab의 NGINX 오류 로그
- `/var/log/gitlab/nginx/gitlab_pages_access.log`:  Pages 정적 사이트에 대한 요청 로그
- `/var/log/gitlab/nginx/gitlab_pages_error.log`:  Pages 정적 사이트의 NGINX 오류 로그
- `/var/log/gitlab/nginx/gitlab_registry_access.log`:  컨테이너 레지스트리에 대한 요청 로그
- `/var/log/gitlab/nginx/gitlab_registry_error.log`:  컨테이너 레지스트리의 NGINX 오류 로그
- `/var/log/gitlab/nginx/gitlab_mattermost_access.log`:  Mattermost에 대한 요청 로그
- `/var/log/gitlab/nginx/gitlab_mattermost_error.log`:  Mattermost의 NGINX 오류 로그

다음은 기본 GitLab NGINX 액세스 로그 형식입니다:

```plaintext
'$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"'
```

`$request`과 `$http_referer`은 비밀 토큰 같은 민감한 쿼리 문자열 매개변수에 대해 [필터링됩니다](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/support/nginx/gitlab).

## Pages 로그 {#pages-logs}

Linux 패키지 설치의 경우 Pages 로그는 `/var/log/gitlab/gitlab-pages/current`에 있습니다.

예를 들어:

```json
{
  "level": "info",
  "msg": "GitLab Pages Daemon",
  "revision": "52b2899",
  "time": "2020-04-22T17:53:12Z",
  "version": "1.17.0"
}
{
  "level": "info",
  "msg": "URL: https://gitlab.com/gitlab-org/gitlab-pages",
  "time": "2020-04-22T17:53:12Z"
}
{
  "gid": 998,
  "in-place": false,
  "level": "info",
  "msg": "running the daemon as unprivileged user",
  "time": "2020-04-22T17:53:12Z",
  "uid": 998
}
```

## 제품 사용 데이터 로그 {#product-usage-data-log}

> [!note]
> 데이터 품질이 아직 정확성으로 인증되지 않았으므로 기능 사용 분석을 위해 원본 로그를 사용하지 않는 것이 좋습니다.
>
> 이벤트 목록은 새로운 기능이나 기존 기능의 변경에 따라 각 버전에서 변경될 수 있습니다. 인증된 제품 내 채택 보고서는 분석 준비가 완료된 후 사용할 수 있습니다.

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/product_usage_data.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/product_usage_data.log` 파일에 있습니다.
- Helm 차트 설치의 Webservice 포드 아래 `subcomponent="product_usage_data"` 키 아래에 있습니다.

Snowplow를 통해 추적된 제품 사용 이벤트의 JSON 형식 로그를 포함합니다. 파일의 각 줄에는 Elasticsearch 또는 Splunk 같은 서비스로 수집할 수 있는 별도의 JSON 항목이 포함됩니다. 읽기 쉽도록 줄 바꿈이 예제에 추가되었습니다:

```json
{
  "severity":"INFO",
  "time":"2025-04-09T13:43:40.254Z",
  "message":"sending event",
  "payload":"{
  \"e\":\"se\",
  \"se_ca\":\"projects:merge_requests:diffs\",
  \"se_ac\":\"i_code_review_user_searches_diff\",
  \"cx\":\"eyJzY2hlbWEiOiJpZ2x1OmNvbS5zbm93cGxvd2FuYWx5dGljcy5zbm93cGxvdy9jb250ZXh0cy9qc29uc2NoZW1hLzEtMC0xIiwiZGF0YSI6W3sic2NoZW1hIjoiaWdsdTpjb20uZ2l0bGFiL2dpdGxhYl9zdGFuZGFyZC9qc29uc2NoZW1hLzEtMS0xIiwiZGF0YSI6eyJlbnZpcm9ubWVudCI6ImRldmVsb3BtZW50Iiwic291cmNlIjoiZ2l0bGFiLXJhaWxzIiwiY29ycmVsYXRpb25faWQiOiJlNDk2NzNjNWI2MGQ5ODc0M2U4YWI0MjZiMTZmMTkxMiIsInBsYW4iOiJkZWZhdWx0IiwiZXh0cmEiOnt9LCJ1c2VyX2lkIjpudWxsLCJnbG9iYWxfdXNlcl9pZCI6bnVsbCwiaXNfZ2l0bGFiX3RlYW1fbWVtYmVyIjpudWxsLCJuYW1lc3BhY2VfaWQiOjMxLCJwcm9qZWN0X2lkIjo2LCJmZWF0dXJlX2VuYWJsZWRfYnlfbmFtZXNwYWNlX2lkcyI6bnVsbCwicmVhbG0iOiJzZWxmLW1hbmFnZWQiLCJpbnN0YW5jZV9pZCI6IjJkMDg1NzBkLWNmZGItNDFmMy1iODllLWM3MTM5YmFjZTI3NSIsImhvc3RfbmFtZSI6ImpsYXJzZW4tLTIwMjIxMjE0LVBWWTY5IiwiaW5zdGFuY2VfdmVyc2lvbiI6IjE3LjExLjAiLCJjb250ZXh0X2dlbmVyYXRlZF9hdCI6IjIwMjUtMDQtMDkgMTM6NDM6NDAgVVRDIn19LHsic2NoZW1hIjoiaWdsdTpjb20uZ2l0bGFiL2dpdGxhYl9zZXJ2aWNlX3BpbmcvanNvbnNjaGVtYS8xLTAtMSIsImRhdGEiOnsiZGF0YV9zb3VyY2UiOiJyZWRpc19obGwiLCJldmVudF9uYW1lIjoiaV9jb2RlX3Jldmlld191c2VyX3NlYXJjaGVzX2RpZmYifX1dfQ==\",
  \"p\":\"srv\",
  \"dtm\":\"1744206220253\",
  \"tna\":\"gl\",
  \"tv\":\"rb-0.8.0\",
  \"eid\":\"4f067989-d10d-40b0-9312-ad9d7355be7f\"
}
```

이 로그를 검사하려면 [Rake 작업](../raketasks/_index.md) `product_usage_data:format`을 사용할 수 있습니다. 이는 JSON 출력의 형식을 지정하고 더 나은 가독성을 위해 base64로 인코딩된 컨텍스트 데이터를 디코딩합니다:

```shell
gitlab-rake "product_usage_data:format[log/product_usage_data.log]"
# or pipe the logs directly
cat log/product_usage_data.log | gitlab-rake product_usage_data:format
# or tail the logs in real-time
tail -f log/product_usage_data.log | gitlab-rake product_usage_data:format
```

`GITLAB_DISABLE_PRODUCT_USAGE_EVENT_LOGGING` 환경 변수를 임의의 값으로 설정하여 이 로그를 비활성화할 수 있습니다.

## Let's Encrypt 로그 {#lets-encrypt-logs}

Linux 패키지 설치의 경우 Let's Encrypt [자동 갱신](https://docs.gitlab.com/omnibus/settings/ssl/#renew-the-certificates-automatically) 로그는 `/var/log/gitlab/lets-encrypt/`에 있습니다.

## Mattermost 로그 {#mattermost-logs}

Linux 패키지 설치의 경우 Mattermost 로그는 다음 위치에 있습니다:

- `/var/log/gitlab/mattermost/mattermost.log`
- `/var/log/gitlab/mattermost/current`

## Workhorse 로그 {#workhorse-logs}

Linux 패키지 설치의 경우 Workhorse 로그는 `/var/log/gitlab/gitlab-workhorse/current`에 있습니다.

## Patroni 로그 {#patroni-logs}

Linux 패키지 설치의 경우 Patroni 로그는 `/var/log/gitlab/patroni/current`에 있습니다.

## PgBouncer 로그 {#pgbouncer-logs}

Linux 패키지 설치의 경우 PgBouncer 로그는 `/var/log/gitlab/pgbouncer/current`에 있습니다.

## PostgreSQL 로그 {#postgresql-logs}

Linux 패키지 설치의 경우 PostgreSQL 로그는 `/var/log/gitlab/postgresql/current`에 있습니다.

Patroni를 사용 중인 경우 PostgreSQL 로그는 [Patroni 로그](#patroni-logs)에 저장됩니다.

## Prometheus 로그 {#prometheus-logs}

Linux 패키지 설치의 경우 Prometheus 로그는 `/var/log/gitlab/prometheus/current`에 있습니다.

## Redis 로그 {#redis-logs}

Linux 패키지 설치의 경우 Redis 로그는 `/var/log/gitlab/redis/current`에 있습니다.

## Sentinel 로그 {#sentinel-logs}

Linux 패키지 설치의 경우 Sentinel 로그는 `/var/log/gitlab/sentinel/current`에 있습니다.

## Alertmanager 로그 {#alertmanager-logs}

Linux 패키지 설치의 경우 Alertmanager 로그는 `/var/log/gitlab/alertmanager/current`에 있습니다.

## Consul 로그 {#consul-logs}

Linux 패키지 설치의 경우 Consul 로그는 `/var/log/gitlab/consul/current`에 있습니다.

<!-- vale gitlab_base.Spelling = NO -->

## crond 로그 {#crond-logs}

Linux 패키지 설치의 경우 crond 로그는 `/var/log/gitlab/crond/`에 있습니다.

<!-- vale gitlab_base.Spelling = YES -->

## Grafana 로그 {#grafana-logs}

Linux 패키지 설치의 경우 Grafana 로그는 `/var/log/gitlab/grafana/current`에 있습니다.

## LogRotate 로그 {#logrotate-logs}

Linux 패키지 설치의 경우 `logrotate` 로그는 `/var/log/gitlab/logrotate/current`에 있습니다.

## GitLab Monitor 로그 {#gitlab-monitor-logs}

Linux 패키지 설치의 경우 GitLab Monitor 로그는 `/var/log/gitlab/gitlab-monitor/`에 있습니다.

## GitLab Exporter 로그 {#gitlab-exporter-logs}

Linux 패키지 설치의 경우 GitLab Exporter 로그는 `/var/log/gitlab/gitlab-exporter/current`에 있습니다.

## Kubernetes용 GitLab 에이전트 서버 로그 {#gitlab-agent-server-for-kubernetes-logs}

Linux 패키지 설치의 경우 Kubernetes용 GitLab 에이전트 서버 로그는 `/var/log/gitlab/gitlab-kas/current`에 있습니다.

## Praefect 로그 {#praefect-logs}

Linux 패키지 설치의 경우 Praefect 로그는 `/var/log/gitlab/praefect/`에 있습니다.

GitLab은 또한 [Gitaly 클러스터(Praefect)에 대한 Prometheus 메트릭](../gitaly/praefect/monitoring.md)을 추적합니다.

## 백업 로그 {#backup-log}

Linux 패키지 설치의 경우 백업 로그는 `/var/log/gitlab/gitlab-rails/backup_json.log`에 위치합니다.

Helm 차트 설치의 경우 백업 로그는 Toolbox 포드의 `/var/log/gitlab/backup_json.log`에 저장됩니다.

이 로그는 [GitLab 백업이 생성될](../backup_restore/_index.md) 때 채워집니다. 이 로그를 사용하여 백업 프로세스가 어떻게 수행되었는지 이해할 수 있습니다.

## 성능 표시줄 통계 {#performance-bar-stats}

이 로그는 다음 위치에 있습니다:

- Linux 패키지 설치의 `/var/log/gitlab/gitlab-rails/performance_bar_json.log` 파일에 있습니다.
- 자체 컴파일된 설치의 `/home/git/gitlab/log/performance_bar_json.log` 파일에 있습니다.
- Helm 차트 설치의 Sidekiq 포드 아래 `subcomponent="performance_bar_json"` 키 아래에 있습니다.

성능 표시줄 통계(현재 SQL 쿼리의 기간만 해당)는 해당 파일에 기록됩니다. 예를 들어:

```json
{"severity":"INFO","time":"2020-12-04T09:29:44.592Z","correlation_id":"33680b1490ccd35981b03639c406a697","filename":"app/models/ci/pipeline.rb","method_path":"app/models/ci/pipeline.rb:each_with_object","request_id":"rYHomD0VJS4","duration_ms":26.889,"count":2,"query_type": "active-record"}
```

이 통계는 .com에서만 기록되며 자체 배포에서는 비활성화됩니다.

## 로그 수집 {#gathering-logs}

이전에 나열된 구성 요소 중 하나에 국한되지 않은 [문제 해결](../troubleshooting/_index.md) 시 GitLab 인스턴스에서 여러 로그와 통계를 동시에 수집하는 것이 좋습니다.

> [!note]
> GitLab 지원팀은 이 중 하나를 요청하는 경우가 많으며 필요한 도구를 유지합니다.

### 주 로그 간단히 조회 {#briefly-tail-the-main-logs}

버그 또는 오류를 쉽게 재현할 수 있으면 [파일에 저장](../troubleshooting/linux_cheat_sheet.md#files-and-directories)하면서 문제를 여러 번 재현하여 주 GitLab 로그를 저장합니다:

```shell
sudo gitlab-ctl tail | tee /tmp/<case-ID-and-keywords>.log
```

로그 수집을 <kbd>Control</kbd> + <kbd>C</kbd>로 마칩니다.

### SOS 로그 수집 {#gathering-sos-logs}

성능 저하 또는 계단식 오류가 발생하여 이전에 나열된 GitLab 구성 요소 중 하나로 쉽게 추적할 수 없으면 [SOS 스크립트를 사용](../troubleshooting/diagnostics_tools.md#sos-scripts)합니다.

### Fast-stats {#fast-stats}

[Fast-stats](https://gitlab.com/gitlab-com/support/toolbox/fast-stats)는 GitLab 로그에서 성능 통계를 작성하고 비교하는 도구입니다. 자세한 내용 및 실행 지침은 [fast-stats 설명서](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#usage)를 읽습니다.

## 상관 ID를 사용하여 관련 로그 항목 찾기 {#find-relevant-log-entries-with-a-correlation-id}

대부분의 요청에는 [관련 로그 항목을 찾는](tracing_correlation_id.md) 데 사용할 수 있는 로그 ID가 있습니다.
