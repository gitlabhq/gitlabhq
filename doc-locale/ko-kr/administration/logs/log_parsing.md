---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "`jq`로 GitLab 로그 분석하기"
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

가능하면 Kibana 및 Splunk와 같은 로그 수집 및 검색 도구를 사용하는 것을 권장하지만, 이러한 도구를 사용할 수 없으면  를 [`jq`](https://stedolan.github.io/jq/)를 사용하여 JSON 형식으로[GitLab 로그](_index.md)를 빠르게 분석할 수 있습니다.

> [!note]
> 특히 오류 이벤트 요약 및 기본 사용 통계를 위해 GitLab Support Team은 전문화된 [`fast-stats` 도구](https://gitlab.com/gitlab-com/support/toolbox/fast-stats/#when-to-use-it)를 제공합니다. 일반적으로 `jq`보다 더 빠르게 큰 로그를 처리할 수 있으며, 더 많은 통계 정보를 출력합니다.

## JQ란? {#what-is-jq}

[설명서](https://stedolan.github.io/jq/manual/)에 명시된 대로 `jq`는 명령줄 JSON 프로세서입니다. 다음 예제들은 GitLab 로그 파일 분석을 대상으로 하는 사용 사례를 포함합니다.

## 로그 분석 {#parsing-logs}

아래 나열된 예제들은 각각의 상대 Linux 패키지 설치 경로 및 기본 파일 이름으로 해당 로그 파일을 다룹니다. [GitLab 로그 섹션](_index.md#production_jsonlog)에서 각각의 전체 경로를 찾습니다.

### 압축된 로그 {#compressed-logs}

[로그 파일이 회전](https://smarden.org/runit/svlogd.8)될 때, Unix 타임스탬프 형식으로 이름이 변경되고 `gzip`로 압축됩니다. 결과 파일 이름은 `@40000000624492fa18da6f34.s`처럼 보입니다. 이 파일들은 최근 로그 파일보다 분석하기 전에 다르게 처리해야 합니다:

- 파일의 압축을 해제하려면 `gunzip -S .s @40000000624492fa18da6f34.s`를 사용하고, 압축된 로그 파일의 이름으로 파일 이름을 바꿉니다.
- 파일을 직접 읽거나 파이프하려면 `zcat` 또는 `zless`를 사용합니다.
- 파일 내용을 검색하려면 `zgrep`를 사용합니다.

### 일반 명령 {#general-commands}

#### 컬러화된 `jq` 출력을 `less`로 파이프 {#pipe-colorized-jq-output-into-less}

```shell
jq . <FILE> -C | less -R
```

#### 용어를 검색하고 일치하는 모든 라인을 예쁘게 인쇄 {#search-for-a-term-and-pretty-print-all-matching-lines}

```shell
grep <TERM> <FILE> | jq .
```

#### JSON의 잘못된 라인 건너뛰기 {#skip-invalid-lines-of-json}

```shell
jq -cR 'fromjson?' file.json | jq <COMMAND>
```

기본적으로 `jq`는 유효하지 않은 JSON인 라인을 만나면 오류가 발생합니다. 이는 모든 잘못된 라인을 건너뛰고 나머지를 분석합니다.

#### JSON 로그의 시간 범위 인쇄 {#print-a-json-logs-time-range}

```shell
cat log.json | (head -1; tail -1) | jq '.time'
```

파일이 회전되어 압축된 경우 `zcat`을 사용합니다:

```shell
zcat @400000006026b71d1a7af804.s | (head -1; tail -1) | jq '.time'

zcat some_json.log.25.gz | (head -1; tail -1) | jq '.time'
```

#### 여러 JSON 로그에서 시간 순서대로 상관 ID에 대한 활동 가져오기 {#get-activity-for-correlation-id-across-multiple-json-logs-in-chronological-order}

```shell
grep -hR <correlationID> | jq -c -R 'fromjson?' | jq -C -s 'sort_by(.time)'  | less -R
```

### `gitlab-rails/production_json.log` 및 `gitlab-rails/api_json.log` 분석 {#parsing-gitlab-railsproduction_jsonlog-and-gitlab-railsapi_jsonlog}

#### 5XX 상태 코드를 가진 모든 요청 찾기 {#find-all-requests-with-a-5xx-status-code}

```shell
jq 'select(.status >= 500)' <FILE>
```

#### 상위 10개의 가장 느린 요청 {#top-10-slowest-requests}

```shell
jq -s 'sort_by(-.duration_s) | limit(10; .[])' <FILE>
```

#### 프로젝트와 관련된 모든 요청 찾기 및 예쁘게 인쇄 {#find-and-pretty-print-all-requests-related-to-a-project}

```shell
grep <PROJECT_NAME> <FILE> | jq .
```

#### 총 지속 시간이 5초 이상인 모든 요청 찾기 {#find-all-requests-with-a-total-duration--5-seconds}

```shell
jq 'select(.duration_s > 5000)' <FILE>
```

#### Gitaly 호출이 5개 이상인 모든 프로젝트 요청 찾기 {#find-all-project-requests-with-more-than-5-gitaly-calls}

```shell
grep <PROJECT_NAME> <FILE> | jq 'select(.gitaly_calls > 5)'
```

#### Gitaly 지속 시간이 10초 이상인 모든 요청 찾기 {#find-all-requests-with-a-gitaly-duration--10-seconds}

```shell
jq 'select(.gitaly_duration_s > 10000)' <FILE>
```

#### 큐 지속 시간이 10초 이상인 모든 요청 찾기 {#find-all-requests-with-a-queue-duration--10-seconds}

```shell
jq 'select(.queue_duration_s > 10000)' <FILE>
```

#### Gitaly 호출 수 기준 상위 10개 요청 {#top-10-requests-by--of-gitaly-calls}

```shell
jq -s 'map(select(.gitaly_calls != null)) | sort_by(-.gitaly_calls) | limit(10; .[])' <FILE>
```

#### 특정 시간 범위 출력 {#output-a-specific-time-range}

```shell
jq 'select(.time >= "2023-01-10T00:00:00Z" and .time <= "2023-01-10T12:00:00Z")' <FILE>
```

### `gitlab-rails/production_json.log` 분석 {#parsing-gitlab-railsproduction_jsonlog}

#### 요청 볼륨별 상위 3개 컨트롤러 메서드 및 3개의 가장 긴 지속 시간 인쇄 {#print-the-top-three-controller-methods-by-request-volume-and-their-three-longest-durations}

```shell
jq -s -r 'group_by(.controller+.action) | sort_by(-length) | limit(3; .[]) | sort_by(-.duration_s) | "CT: \(length)\tMETHOD: \(.[0].controller)#\(.[0].action)\tDURS: \(.[0].duration_s),  \(.[1].duration_s),  \(.[2].duration_s)"' production_json.log
```

**Example output**

```plaintext
CT: 2721   METHOD: SessionsController#new  DURS: 844.06,  713.81,  704.66
CT: 2435   METHOD: MetricsController#index DURS: 299.29,  284.01,  158.57
CT: 1328   METHOD: Projects::NotesController#index DURS: 403.99,  386.29,  384.39
```

또는 [`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats)를 사용합니다:

```shell
fast-stats --verbose --limit=3 production_json.log
```

### `gitlab-rails/api_json.log` 분석 {#parsing-gitlab-railsapi_jsonlog}

#### 요청 수별 상위 3개 경로 및 3개의 가장 긴 지속 시간 인쇄 {#print-top-three-routes-with-request-count-and-their-three-longest-durations}

```shell
jq -s -r 'group_by(.route) | sort_by(-length) | limit(3; .[]) | sort_by(-.duration_s) | "CT: \(length)\tROUTE: \(.[0].route)\tDURS: \(.[0].duration_s),  \(.[1].duration_s),  \(.[2].duration_s)"' api_json.log
```

**Example output**

```plaintext
CT: 2472 ROUTE: /api/:version/internal/allowed   DURS: 56402.65,  38411.43,  19500.41
CT: 297  ROUTE: /api/:version/projects/:id/repository/tags       DURS: 731.39,  685.57,  480.86
CT: 190  ROUTE: /api/:version/projects/:id/repository/commits    DURS: 1079.02,  979.68,  958.21
```

또는 [`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats)를 사용합니다:

```shell
fast-stats --verbose --limit=3 api_json.log
```

#### 상위 API 사용자 에이전트 인쇄 {#print-top-api-user-agents}

```shell
jq --raw-output '
  select(.remote_ip != "127.0.0.1") | [
    (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H…")),
    ."meta.caller_id", .username, .ua
  ] | @tsv' api_json.log | sort | uniq -c \
  | grep --invert-match --extended-regexp '^\s+\d{1,3}\b'
```

**Example output**:

```plaintext
 1234 …01-12T01…  GET /api/:version/projects/:id/pipelines  some_user  # plus browser details; OK
54321 …01-12T01…  POST /api/:version/projects/:id/repository/files/:file_path/raw  some_bot
 5678 …01-12T01…  PATCH /api/:version/jobs/:id/trace gitlab-runner     # plus version details; OK
```

이 예시는 예상치 못한 높은 [요청 속도(>15 RPS)](../reference_architectures/_index.md#available-reference-architectures)를 야기하는 사용자 지정 도구 또는 스크립트를 보여줍니다. 이 상황에서 사용자 에이전트는 전문화된 [타사 클라이언트](../../api/rest/third_party_clients.md)이거나 `curl`과 같은 일반 도구일 수 있습니다.

시간별 집계는 다음을 지원합니다:

- [Prometheus](../monitoring/prometheus/_index.md)와 같은 모니터링 도구의 데이터에 봇 또는 사용자 활동의 스파이크를 연관시킵니다.
- [속도 제한 설정](../settings/user_and_ip_rate_limits.md)을 평가합니다.

`jq`과 함께, [`fast-stats top`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats/-/blob/main/README.md#top)를 사용하여 이러한 사용자 및 봇의 성능 영향을 검토합니다:

```shell
fast-stats top --display=percentage --sort-by=cpu-s api_json.log
```

높은 요청 빈도만으로는 자동으로 문제가 되지 않지만, 모든 리소스의 큰 비율을 사용하는 것은 문제입니다.

### `gitlab-rails/importer.log` 분석 {#parsing-gitlab-railsimporterlog}

[프로젝트 임포트](../raketasks/project_import_export.md) 또는 [마이그레이션](../../user/import/_index.md)을 문제 해결하려면 이 명령을 실행합니다:

```shell
jq 'select(.project_path == "<namespace>/<project>").error_messages' importer.log
```

일반적인 문제는 [문제 해결](../raketasks/import_export_rake_tasks_troubleshooting.md)을 참조합니다.

### `gitlab-workhorse/current` 분석 {#parsing-gitlab-workhorsecurrent}

#### 상위 Workhorse 사용자 에이전트 인쇄 {#print-top-workhorse-user-agents}

```shell
jq --raw-output '
  select(.remote_ip != "127.0.0.1") | [
    (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H…")),
    .remote_ip, .uri, .user_agent
  ] | @tsv' current |
  sort | uniq -c
```

[API `ua` 예시](#print-top-api-user-agents)와 유사하게, 이 출력의 많은 예상치 못한 사용자 에이전트는 최적화되지 않은 스크립트를 나타냅니다. 예상 사용자 에이전트는 `gitlab-runner`, `GitLab-Shell`, 및 브라우저를 포함합니다.

새 작업을 확인하는 러너의 성능 영향은 [`check_interval` 설정](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-global-section)을 늘려서 줄일 수 있습니다(예시).

### `gitlab-rails/geo.log` 분석 {#parsing-gitlab-railsgeolog}

#### 가장 일반적인 Geo 동기화 오류 찾기 {#find-most-common-geo-sync-errors}

[`gitlab:geo:status` Rake 작업](../geo/replication/troubleshooting/common.md#sync-status-rake-task)이 일부 항목이 절대 100%에 도달하지 않는다고 반복적으로 보고하면, 다음 명령은 가장 일반적인 오류에 초점을 맞추는 데 도움이 됩니다.

```shell
jq --raw-output 'select(.severity == "ERROR") | [
  (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H:%M…")),
  .class, .id, .message, .error
  ] | @tsv' geo.log \
  | sort | uniq -c
```

특정 오류 메시지에 대한 조언은 [Geo 문제 해결 페이지](../geo/replication/troubleshooting/_index.md)를 참조합니다.

### `gitaly/current` 분석 {#parsing-gitalycurrent}

다음 예제를 사용하여 [Gitaly 문제 해결](../gitaly/troubleshooting.md)합니다.

#### Web UI에서 보낸 모든 Gitaly 요청 찾기 {#find-all-gitaly-requests-sent-from-web-ui}

```shell
jq 'select(."grpc.meta.client_name" == "gitlab-web")' current
```

#### 실패한 모든 Gitaly 요청 찾기 {#find-all-failed-gitaly-requests}

```shell
jq 'select(."grpc.code" != null and ."grpc.code" != "OK")' current
```

#### 30초 이상 소요된 모든 요청 찾기 {#find-all-requests-that-took-longer-than-30-seconds}

```shell
jq 'select(."grpc.time_ms" > 30000)' current
```

#### 요청 볼륨별 상위 10개 프로젝트 및 3개의 가장 긴 지속 시간 인쇄 {#print-top-ten-projects-by-request-volume-and-their-three-longest-durations}

```shell
jq --raw-output --slurp '
  map(
    select(
      ."grpc.request.glProjectPath" != null
      and ."grpc.request.glProjectPath" != ""
      and ."grpc.time_ms" != null
    )
  )
  | group_by(."grpc.request.glProjectPath")
  | sort_by(-length)
  | limit(10; .[])
  | sort_by(-."grpc.time_ms")
  | [
      length,
      .[0]."grpc.time_ms",
      .[1]."grpc.time_ms",
      .[2]."grpc.time_ms",
      .[0]."grpc.request.glProjectPath"
    ]
  | @sh' current |
  awk 'BEGIN { printf "%7s %10s %10s %10s\t%s\n", "CT", "MAX DURS", "", "", "PROJECT" }
  { printf "%7u %7u ms, %7u ms, %7u ms\t%s\n", $1, $2, $3, $4, $5 }'
```

**Example output**

```plaintext
   CT    MAX DURS                              PROJECT
  206    4898 ms,    1101 ms,    1032 ms      'groupD/project4'
  109    1420 ms,     962 ms,     875 ms      'groupEF/project56'
  663     106 ms,      96 ms,      94 ms      'groupABC/project123'
  ...
```

또는 [`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats)를 사용합니다:

```shell
fast-stats top --sort-by=duration current
```

#### 사용자 및 프로젝트 활동 유형 개요 {#types-of-user-and-project-activity-overview}

```shell
jq --raw-output '[
    (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H…")),
    .username, ."grpc.method", ."grpc.request.glProjectPath"
  ] | @tsv' current | sort | uniq -c \
  | grep --invert-match --extended-regexp '^\s+\d{1,3}\b'
```

**Example output**:

```plaintext
 5678 …01-12T01…     ReferenceTransactionHook  # Praefect operation; OK
54321 …01-12T01…  some_bot   GetBlobs    namespace/subgroup/project
 1234 …01-12T01…  some_user  FindCommit  namespace/subgroup/project
```

이 예시는 Gitaly에서 예상치 못한 높은 [요청 속도(>15 RPS)](../reference_architectures/_index.md#available-reference-architectures)를 야기하는 사용자 지정 도구 또는 스크립트를 보여줍니다. 시간별 집계는 다음을 지원합니다:

- [Prometheus](../monitoring/prometheus/_index.md)와 같은 모니터링 도구의 데이터에 봇 또는 사용자 활동의 스파이크를 연관시킵니다.
- [속도 제한 설정](../settings/user_and_ip_rate_limits.md)을 평가합니다.

`jq`과 함께, [`fast-stats top`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats/-/blob/main/README.md#top)를 사용하여 이러한 사용자 및 봇의 성능 영향을 검토합니다:

```shell
fast-stats top --display=percentage --sort-by=cpu-s current
```

높은 요청 빈도만으로는 자동으로 문제가 되지 않지만, 모든 리소스의 큰 비율을 사용하는 것은 문제입니다.

#### 치명적인 Git 문제의 영향을 받는 모든 프로젝트 찾기 {#find-all-projects-affected-by-a-fatal-git-problem}

```shell
grep "fatal: " current |
  jq '."grpc.request.glProjectPath"' |
  sort | uniq
```

### `gitlab-shell/gitlab-shell.log` 분석 {#parsing-gitlab-shellgitlab-shelllog}

SSH를 통한 Git 호출 조사 중입니다.

프로젝트 및 사용자별로 상위 20개 호출 찾기:

```shell
jq --raw-output --slurp '
  map(
    select(
      .username != null and
      .gl_project_path !=null
    )
  )
  | group_by(.username+.gl_project_path)
  | sort_by(-length)
  | limit(20; .[])
  | "count: \(length)\tuser: \(.[0].username)\tproject: \(.[0].gl_project_path)" ' \
  gitlab-shell.log
```

프로젝트, 사용자, 명령별로 상위 20개 호출 찾기:

```shell
jq --raw-output --slurp '
  map(
    select(
      .command  != null and
      .username != null and
      .gl_project_path !=null
    )
  )
  | group_by(.username+.gl_project_path+.command)
  | sort_by(-length)
  | limit(20; .[])
  | "count: \(length)\tcommand: \(.[0].command)\tuser: \(.[0].username)\tproject: \(.[0].gl_project_path)" ' \
  gitlab-shell.log
```
