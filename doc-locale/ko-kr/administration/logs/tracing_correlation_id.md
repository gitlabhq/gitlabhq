---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 상관관계 ID를 사용하여 관련 로그 항목 찾기
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab 인스턴스는 대부분의 요청에 대해 고유한 요청 추적 ID("상관관계 ID"라고 함)를 기록합니다. GitLab에 대한 각 개별 요청은 자체 상관관계 ID를 가지며, 이는 해당 요청에 대한 각 GitLab 구성 요소의 로그에 기록됩니다. 이를 통해 분산 시스템에서 동작을 추적하기가 더 쉬워집니다. 이 ID가 없으면 관련된 로그 항목을 일치시키기가 어렵거나 불가능할 수 있습니다.

## 요청의 상관관계 ID 식별 {#identify-the-correlation-id-for-a-request}

상관관계 ID는 `correlation_id` 키 아래의 구조화된 로그에 기록되며, GitLab이 `x-request-id` 헤더 아래로 보내는 모든 응답 헤더에 기록됩니다. 두 위치 중 하나를 검색하여 상관관계 ID를 찾을 수 있습니다.

### 브라우저에서 상관관계 ID 가져오기 {#getting-the-correlation-id-in-your-browser}

브라우저의 개발자 도구를 사용하여 방문 중인 사이트의 네트워크 활동을 모니터링하고 검사할 수 있습니다. 인기 있는 브라우저에 대한 네트워크 모니터링 설명서를 보려면 아래 링크를 참조하세요.

- [Network Monitor - Firefox Developer Tools](https://firefox-source-docs.mozilla.org/devtools-user/network_monitor/index.html)
- [Inspect Network Activity In Chrome DevTools](https://developer.chrome.com/docs/devtools/network/)
- [Safari Web Development Tools](https://developer.apple.com/safari/tools/)
- [Microsoft Edge Network panel](https://learn.microsoft.com/en-us/microsoft-edge/devtools-guide-chromium/network/)

관련 요청을 찾고 상관관계 ID를 보려면 다음을 수행합니다:

1. 네트워크 모니터에서 지속적 로깅을 활성화합니다. GitLab의 일부 작업은 양식을 제출한 후 빠르게 리다이렉트되므로 이를 통해 모든 관련 활동을 캡처할 수 있습니다.
1. 찾고 있는 요청을 격리하는 데 도움이 되도록 `document` 요청으로 필터링할 수 있습니다.
1. 관심 있는 요청을 선택하여 추가 세부 정보를 봅니다.
1. **헤더** 섹션으로 이동하고 **Response Headers**를 찾습니다. 여기서 요청에 대해 GitLab이 임의로 생성한 값을 가진 `x-request-id` 헤더를 찾을 수 있습니다.

다음 예시를 참고하세요:

![네트워크 요청 세부 정보의 헤더 섹션의 상관관계 ID 예시(HTML 문서용)](img/network_monitor_xid_v13_6.png)

### 로그에서 상관관계 ID 가져오기 {#getting-the-correlation-id-from-your-logs}

올바른 상관관계 ID를 찾는 또 다른 방법은 로그를 검색하거나 관찰하고 감시 중인 로그 항목의 `correlation_id` 값을 찾는 것입니다.

예를 들어, GitLab에서 작업을 재현할 때 발생하거나 중단되는 상황을 알고 싶다면 GitLab 로그를 추적하고, 사용자의 요청으로 필터링한 다음, 관심 있는 내용을 볼 때까지 요청을 감시할 수 있습니다.

### curl에서 상관관계 ID 가져오기 {#getting-the-correlation-id-from-curl}

`curl`를 사용 중이면 상세 옵션을 사용하여 요청 및 응답 헤더와 기타 디버그 정보를 표시할 수 있습니다.

```shell
➜  ~ curl --verbose "https://gitlab.example.com/api/v4/projects"
# look for a line that looks like this
< x-request-id: 4rAMkV3gof4
```

#### jq 사용 {#using-jq}

이 예시는 [jq](https://stedolan.github.io/jq/)를 사용하여 결과를 필터링하고 관심 있을 가능성이 높은 값을 표시합니다.

```shell
sudo gitlab-ctl tail gitlab-rails/production_json.log | jq 'select(.username == "bob") | "User: \(.username), \(.method) \(.path), \(.controller)#\(.action), ID: \(.correlation_id)"'
```

```plaintext
"User: bob, GET /root/linux, ProjectsController#show, ID: U7k7fh6NpW3"
"User: bob, GET /root/linux/commits/master/signatures, Projects::CommitsController#signatures, ID: XPIHpctzEg1"
"User: bob, GET /root/linux/blob/master/README, Projects::BlobController#show, ID: LOt9hgi1TV4"
```

#### grep 사용 {#using-grep}

이 예시는 `grep`과 `tr`만 사용하며, `jq`보다 설치될 가능성이 더 높습니다.

```shell
sudo gitlab-ctl tail gitlab-rails/production_json.log | grep '"username":"bob"' | tr ',' '\n' | egrep 'method|path|correlation_id'
```

```plaintext
{"method":"GET"
"path":"/root/linux"
"username":"bob"
"correlation_id":"U7k7fh6NpW3"}
{"method":"GET"
"path":"/root/linux/commits/master/signatures"
"username":"bob"
"correlation_id":"XPIHpctzEg1"}
{"method":"GET"
"path":"/root/linux/blob/master/README"
"username":"bob"
"correlation_id":"LOt9hgi1TV4"}
```

## 상관관계 ID에 대한 로그 검색 {#searching-your-logs-for-the-correlation-id}

상관관계 ID를 확인한 후에는 관련 로그 항목 검색을 시작할 수 있습니다. 상관관계 ID 자체로 줄을 필터링할 수 있습니다. `find`와 `grep`를 조합하면 찾고 있는 항목을 찾을 수 있을 정도로 충분합니다.

```shell
# find <gitlab log directory> -type f -mtime -0 exec grep '<correlation ID>' '{}' '+'
find /var/log/gitlab -type f -mtime 0 -exec grep 'LOt9hgi1TV4' '{}' '+'
```

```plaintext
/var/log/gitlab/gitlab-workhorse/current:{"correlation_id":"LOt9hgi1TV4","duration_ms":2478,"host":"gitlab.domain.tld","level":"info","method":"GET","msg":"access","proto":"HTTP/1.1","referrer":"https://gitlab.domain.tld/root/linux","remote_addr":"68.0.116.160:0","remote_ip":"[filtered]","status":200,"system":"http","time":"2019-09-17T22:17:19Z","uri":"/root/linux/blob/master/README?format=json\u0026viewer=rich","user_agent":"Mozilla/5.0 (Mac) Gecko Firefox/69.0","written_bytes":1743}
/var/log/gitlab/gitaly/current:{"correlation_id":"LOt9hgi1TV4","grpc.code":"OK","grpc.meta.auth_version":"v2","grpc.meta.client_name":"gitlab-web","grpc.method":"FindCommits","grpc.request.deadline":"2019-09-17T22:17:47Z","grpc.request.fullMethod":"/gitaly.CommitService/FindCommits","grpc.request.glProjectPath":"root/linux","grpc.request.glRepository":"project-1","grpc.request.repoPath":"@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b.git","grpc.request.repoStorage":"default","grpc.request.topLevelGroup":"@hashed","grpc.service":"gitaly.CommitService","grpc.start_time":"2019-09-17T22:17:17Z","grpc.time_ms":2319.161,"level":"info","msg":"finished streaming call with code OK","peer.address":"@","span.kind":"server","system":"grpc","time":"2019-09-17T22:17:19Z"}
/var/log/gitlab/gitlab-rails/production_json.log:{"method":"GET","path":"/root/linux/blob/master/README","format":"json","controller":"Projects::BlobController","action":"show","status":200,"duration":2448.77,"view":0.49,"db":21.63,"time":"2019-09-17T22:17:19.800Z","params":[{"key":"viewer","value":"rich"},{"key":"namespace_id","value":"root"},{"key":"project_id","value":"linux"},{"key":"id","value":"master/README"}],"remote_ip":"[filtered]","user_id":2,"username":"bob","ua":"Mozilla/5.0 (Mac) Gecko Firefox/69.0","queue_duration":3.38,"gitaly_calls":1,"gitaly_duration":0.77,"rugged_calls":4,"rugged_duration_ms":28.74,"correlation_id":"LOt9hgi1TV4"}
```

### 분산 아키텍처에서 검색 {#searching-in-distributed-architectures}

GitLab 인프라에서 일부 수평 확장을 수행한 경우, GitLab 노드 전체를 검색해야 합니다. Loki, ELK, Splunk 또는 기타와 같은 로그 집계 소프트웨어를 사용하여 이를 수행할 수 있습니다.

Ansible 또는 PSSH(병렬 SSH)와 같은 도구를 사용하여 서버 전체에서 동일한 명령을 병렬로 실행하거나 자신의 솔루션을 작성할 수 있습니다.

### Performance Bar에서 요청 보기 {#viewing-the-request-in-the-performance-bar}

[performance bar](../monitoring/performance/performance_bar.md)를 사용하여 SQL 및 Gitaly에 대한 호출을 포함한 흥미로운 데이터를 볼 수 있습니다.

데이터를 보려면 요청의 상관관계 ID가 performance bar를 보는 사용자와 동일한 세션과 일치해야 합니다. API 요청의 경우 인증된 사용자의 세션 쿠키를 사용하여 요청을 수행해야 합니다.

예를 들어, 다음 API 끝점에 대해 실행된 데이터베이스 쿼리를 보려면:

```shell
https://gitlab.com/api/v4/groups/2564205/projects?with_security_reports=true&page=1&per_page=1
```

먼저 **Developer Tools** 패널을 활성화합니다. 이를 수행하는 방법에 대한 세부 정보는 [브라우저에서 상관관계 ID 가져오기](#getting-the-correlation-id-in-your-browser)를 참조하세요.

개발자 도구를 활성화한 후 다음과 같이 세션 쿠키를 가져옵니다:

1. 로그인 상태에서 <https://gitlab.com>를 방문합니다.
1. 선택사항. **Developer Tools** 패널에서 **Fetch/XHR** 요청 필터를 선택합니다. 이 단계는 Google Chrome 개발자 도구에 대해 설명되며 반드시 필요한 것은 아니지만 올바른 요청을 찾기가 더 쉬워집니다.
1. 왼쪽 측에서 `results?request_id=<some-request-id>` 요청을 선택합니다.
1. 세션 쿠키는 `Headers` 패널의 `Request Headers` 섹션 아래에 표시됩니다. 쿠키 값을 마우스 오른쪽 단추로 클릭하고 `Copy value`을 선택합니다.

![브라우저의 Developer Tools 패널에서 세션 쿠키 보기](img/obtaining-a-session-cookie-for-request_v14_3.png)

클립보드에 복사한 세션 쿠키의 값을 보유하고 있으며, 예를 들면:

```shell
experimentation_subject_id=<subject-id>; _gitlab_session=<session-id>; event_filter=all; visitor_id=<visitor-id>; perf_bar_enabled=true; sidebar_collapsed=true; diff_view=inline; sast_entry_point_dismissed=true; auto_devops_settings_dismissed=true; cf_clearance=<cf-clearance>; collapsed_gutter=false
```

세션 쿠키의 값을 사용하여 `curl` 요청의 사용자 정의 헤더에 붙여넣어 API 요청을 작성합니다:

```shell
$ curl --include "https://gitlab.com/api/v4/groups/2564205/projects?with_security_reports=true&page=1&per_page=1" \
--header 'cookie: experimentation_subject_id=<subject-id>; _gitlab_session=<session-id>; event_filter=all; visitor_id=<visitor-id>; perf_bar_enabled=true; sidebar_collapsed=true; diff_view=inline; sast_entry_point_dismissed=true; auto_devops_settings_dismissed=true; cf_clearance=<cf-clearance>; collapsed_gutter=false'

  date: Tue, 28 Sep 2021 03:55:33 GMT
  content-type: application/json
  ...
  x-request-id: 01FGN8P881GF2E5J91JYA338Y3
  ...
  [
    {
      "id":27497069,
      "description":"Analyzer for images used on live K8S containers based on Starboard"
    },
    "container_registry_image_prefix":"registry.gitlab.com/gitlab-org/security-products/analyzers/cluster-image-scanning",
    "..."
  ]
```

응답은 API 끝점의 데이터와 `x-request-id` 헤더에 반환된 `correlation_id` 값을 포함하며, 이는 [요청의 상관관계 ID 식별](#identify-the-correlation-id-for-a-request) 섹션에 설명되어 있습니다.

그러면 이 요청에 대한 데이터베이스 세부 정보를 볼 수 있습니다:

1. `x-request-id` 값을 [performance bar](../monitoring/performance/performance_bar.md)의 `request details` 필드에 붙여넣고 <kbd>Enter/Return</kbd> 키를 누릅니다. 이 예시는 이전 응답에서 반환된 `x-request-id` 값 `01FGN8P881GF2E5J91JYA338Y3`을 사용합니다:

   ![예시 값을 포함하는 performance bar의 요청 세부 정보 필드](img/paste-request-id-into-progress-bar_v14_3.png)

1. 새 요청이 Performance Bar의 오른쪽 측의 `Request Selector` 드롭다운 목록에 삽입됩니다. 새 요청을 선택하여 API 요청의 메트릭을 봅니다:

   ![열린 Request Selector 드롭다운 목록의 강조 표시된 예시 요청](img/select-request-id-from-request-selector-drop-down-menu_v14_3.png)

1. Progress Bar의 `pg` 링크를 선택하여 API 요청에서 실행한 데이터베이스 쿼리를 봅니다:

   ![GitLab API 데이터베이스 세부 정보: 29ms / 34쿼리](img/view-pg-details_v14_3.png)

   데이터베이스 쿼리 대화 상자가 표시됩니다:

   ![34개의 SQL 쿼리, 29ms 지속 시간, 34개 복제본, 4개 캐시 및 정렬 옵션을 포함하는 데이터베이스 쿼리 대화 상자](img/database-query-dialog_v14_3.png)
