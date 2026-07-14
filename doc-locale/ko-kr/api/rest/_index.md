---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab 를 사용하여 GitLab과의 프로그래밍 방식의 상호 작용을 수행할 수 있습니다. 요청, , 페이지 매김, 인코딩, 버전 관리 및 응답 처리를 포함합니다."
title: REST API
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 를 사용하여 워크플로를 자동화하고 통합을 구축합니다:

- 수동 개입 없이 대규모로 GitLab 리소스를 관리하는 사용자 지정 도구를 만듭니다.
- GitLab 데이터를 애플리케이션에 직접 통합하여 협업을 개선합니다.
- 여러 프로젝트에서 CI/CD 프로세스를 정밀하게 관리합니다.
- 프로그래밍 방식으로 사용자 액세스를 제어하여 조직 전체에서 일관된 권한을 유지합니다.

는 기존 도구 및 시스템과의 호환성을 위해 표준 HTTP 방법과 JSON 데이터 형식을 사용합니다.

## 요청 만들기 {#make-a-rest-api-request}

요청을 만들려면:

- 클라이언트를 사용하여 API 엔드포인트에 요청을 제출합니다.
- GitLab 인스턴스가 요청에 응답합니다. 상태 코드와 해당하는 경우 요청된 데이터를 반환합니다. 상태 코드는 요청의 결과를 나타내며 [문제 해결](troubleshooting.md) 시 유용합니다.

요청은 루트 엔드포인트와 경로로 시작해야 합니다.

- 루트 엔드포인트는 GitLab 호스트 이름입니다.
- 경로는 `/api/v4`로 시작해야 하며(`v4`는 API 버전을 나타냅니다).

다음 예제에서는 API 요청이 GitLab 호스트 `gitlab.example.com`에서 모든 프로젝트의 목록을 검색합니다:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects"
```

일부 엔드포인트에 대한 액세스에는 인증이 필요합니다. 자세한 내용은 [인증](authentication.md)을 참조하세요.

## 속도 제한 {#rate-limits}

요청은 설정의 적용을 받습니다. 이 설정은 GitLab 인스턴스가 과부하되는 위험을 줄입니다.

- 자세한 내용은 [속도 제한](../../security/rate_limits.md)을 참조하세요.
- GitLab.com에서 사용하는 설정의 세부 사항을 보려면 [GitLab.com 특정](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom)을 참조하세요.

## 응답 형식 {#response-format}

응답은 JSON 형식으로 반환됩니다. 일부 API 엔드포인트는 일반 텍스트 형식도 지원합니다. 엔드포인트가 지원하는 콘텐츠 유형을 확인하려면 [리소스](../api_resources.md)를 참조하세요.

## 요청 요구 사항 {#request-requirements}

일부 요청에는 사용되는 데이터 형식 및 인코딩을 포함한 특정 요구 사항이 있습니다.

### 요청 페이로드 {#request-payload}

API 요청은 [쿼리 문자열](https://en.wikipedia.org/wiki/Query_string) 또는 [페이로드 본문](https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-p3-payload-14#section-3.2)으로 전송된 매개변수를 사용할 수 있습니다. GET 요청은 일반적으로 쿼리 문자열을 전송하는 반면 PUT 또는 POST 요청은 일반적으로 페이로드 본문을 전송합니다:

- 쿼리 문자열:

  ```shell
  curl --request POST \
    --url "https://gitlab.example.com/api/v4/projects?name=<example-name>&description=<example-description>"
  ```

- 요청 페이로드(JSON):

  ```shell
  curl --request POST \
    --header "Content-Type: application/json" \
    --data '{"name":"<example-name>", "description":"<example-description>"}' "https://gitlab.example.com/api/v4/projects"
  ```

URL 인코딩된 쿼리 문자열의 길이는 제한됩니다. 너무 큰 요청의 경우 `414 Request-URI Too Large` 오류 메시지가 표시됩니다. 이 문제는 대신 페이로드 본문을 사용하여 해결할 수 있습니다.

### 경로 매개변수 {#path-parameters}

엔드포인트에 경로 매개변수가 있으면 설명서에 앞에 콜론이 붙은 형태로 표시됩니다.

예를 들어:

```plaintext
DELETE /projects/:id/share/:group_id
```

`:id` 경로 매개변수를 프로젝트 ID로 바꿔야 하며 `:group_id`는 그룹의 ID로 바꿔야 합니다. 콜론 `:`은 포함되면 안 됩니다.

ID가 `5`인 프로젝트와 그룹 ID가 `17`인 결과 cURL 요청은 다음과 같습니다:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/share/17"
```

URL 인코딩되어야 하는 경로 매개변수를 따라야 합니다. 따르지 않으면 API 엔드포인트와 일치하지 않으며 404로 응답합니다. API 앞에 뭔가가 있으면(예: Apache) URL 인코딩된 경로 매개변수를 디코딩하지 않는지 확인합니다.

### `id` 대 `iid` {#id-vs-iid}

일부 API 리소스에는 유사하게 명명된 두 개의 필드가 있습니다. 예를 들어 [이슈](../issues.md) , [머지 리퀘스트](../merge_requests.md) 및 [프로젝트 마일스톤](../milestones.md)입니다. 필드는 다음과 같습니다:

- `id`:  모든 프로젝트에서 고유한 ID입니다.
- `iid`:  추가 내부 ID(웹 UI에 표시됨)는 단일 프로젝트의 범위 내에서 고유합니다.

리소스에 `iid` 필드와 `id` 필드가 모두 있으면 `iid` 필드가 리소스를 가져오기 위해 `id` 대신 사용됩니다.

예를 들어 `id: 42`인 프로젝트에 `id: 46`과(와) `iid: 5`인 가 있다고 가정합니다. 이 경우:

- 를 검색하는 유효한 API 요청은 `GET /projects/42/issues/5`입니다.
- 를 검색하는 유효하지 않은 API 요청은 `GET /projects/42/issues/46`입니다.

`iid` 필드를 가진 모든 리소스가 `iid`로 검색되지는 않습니다. 사용할 필드에 대한 지침을 보려면 특정 리소스의 설명서를 참조하세요.

### 인코딩 {#encoding}

요청을 할 때 특수 문자와 데이터 구조를 고려하여 일부 콘텐츠를 인코딩해야 합니다.

#### 네임스페이스 경로 {#namespaced-paths}

네임스페이스 API 요청을 사용하는 경우 `NAMESPACE/PROJECT_PATH`이(가) URL 인코딩되었는지 확인합니다.

예를 들어 `/`은(는) `%2F`로 표현됩니다:

```plaintext
GET /api/v4/projects/diaspora%2Fdiaspora
```

프로젝트의 경로는 반드시 이름과 같지는 않습니다. 프로젝트의 경로는 프로젝트의 URL 또는 프로젝트 설정에서 **일반** > **고급** > **경로 변경**에서 찾을 수 있습니다.

#### 파일 경로, 및 이름 {#file-path-branches-and-tags-name}

파일 경로, 또는 에 `/`이(가) 포함되면 URL 인코딩되었는지 확인합니다.

예를 들어 `/`은(는) `%2F`로 표현됩니다:

```plaintext
GET /api/v4/projects/1/repository/files/src%2FREADME.md?ref=master
GET /api/v4/projects/1/branches/my%2Fbranch/commits
GET /api/v4/projects/1/repository/tags/my%2Ftag
```

#### 배열 및 해시 유형 {#array-and-hash-types}

`array` 및 `hash` 유형 매개변수로 API를 요청할 수 있습니다:

##### `array` {#array}

`import_sources`은(는) `array` 유형의 매개변수입니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  -d "import_sources[]=github" \
  -d "import_sources[]=bitbucket" \
  --url "https://gitlab.example.com/api/v4/some_endpoint"
```

##### `hash` {#hash}

`override_params`은(는) `hash` 유형의 매개변수입니다:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "namespace=email" \
  --form "path=impapi" \
  --form "file=@/path/to/somefile.txt" \
  --form "override_params[visibility]=private" \
  --form "override_params[some_other_param]=some_value" \
  --url "https://gitlab.example.com/api/v4/projects/import"
```

##### 해시 배열 {#array-of-hashes}

`variables`은(는) 해시 키/값 쌍 `[{ 'key': 'UPLOAD_TO_S3', 'value': 'true' }]`을(를) 포함하는 `array` 유형의 매개변수입니다:

```shell
curl --globoff --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/169/pipeline?ref=master&variables[0][key]=VAR1&variables[0][value]=hello&variables[1][key]=VAR2&variables[1][value]=world"

curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{ "ref": "master", "variables": [ {"key": "VAR1", "value": "hello"}, {"key": "VAR2", "value": "world"} ] }' \
  --url "https://gitlab.example.com/api/v4/projects/169/pipeline"
```

#### ISO 8601 날짜에서 `+` 인코딩 {#encoding--in-iso-8601-dates}

쿼리 매개변수에 `+`을(를) 포함해야 하는 경우 `%2B`을(를) 대신 사용해야 할 수도 있습니다. `+`이(가) 공백으로 해석되도록 하는 [W3 권장 사항](https://www.w3.org/Addressing/URL/4_URI_Recommentations.html) 때문입니다. 예를 들어 ISO 8601 날짜에는 다음과 같은 ISO 8601 형식의 특정 시간을 포함할 수 있습니다:

```plaintext
2017-10-17T23:11:13.000+05:30
```

쿼리 매개변수의 올바른 인코딩은 다음과 같습니다:

```plaintext
2017-10-17T23:11:13.000%2B05:30
```

## 응답 평가 {#evaluating-a-response}

어떤 경우에는 API 응답이 예상과 다를 수 있습니다. 문제에는 null 값 및 리디렉션이 포함될 수 있습니다. 응답에서 숫자 상태 코드를 받으면 [상태 코드](troubleshooting.md#status-codes)를 참조하세요.

### `null` 대 `false` {#null-vs-false}

API 응답에서 일부 부울 필드는 `null` 값을 가질 수 있습니다. `null` 부울은 기본값이 없으며 `true` 또는 `false` 중 어느 것도 아닙니다. GitLab은 부울 필드의 `null` 값을 `false`과(와) 동일하게 처리합니다.

부울 인수에서는 `true` 또는 `false` 값만 설정해야 하며(`null`은 아님) 설정해야 합니다.

### 리디렉션 {#redirects}

{{< history >}}

- GitLab 16.4에서 [플래그](../../administration/feature_flags/_index.md) `api_redirect_moved_projects`로 도입되었습니다. 기본적으로 비활성화됨.
- GitLab 16.7에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137578)합니다. 기능 플래그 `api_redirect_moved_projects` 제거됨.

{{< /history >}}

[경로 변경](../../user/project/repository/_index.md#repository-path-changes) 후 는 엔드포인트가 이동했음을 나타내는 메시지로 응답할 수 있습니다. 이 경우 `Location` 헤더에 지정된 엔드포인트를 사용하세요.

다른 경로로 이동한 프로젝트의 예:

```shell
curl --request GET \
  --verbose \
  --url "https://gitlab.example.com/api/v4/projects/gitlab-org%2Fold-path-project"
```

응답은 다음과 같습니다:

```plaintext
...
< Location: http://gitlab.example.com/api/v4/projects/81
...
This resource has been moved permanently to https://gitlab.example.com/api/v4/projects/81
```

## 페이지 매김 {#pagination}

GitLab은 다음 페이지 매김 방법을 지원합니다:

- 오프셋 기반 페이지 매김입니다. 기본 방법이며 GitLab 16.5 이상에서 `users` 엔드포인트를 제외한 모든 엔드포인트에서 사용 가능합니다.
- 키셋 기반 페이지 매김입니다. 선택된 엔드포인트에 추가되었지만 [점진적으로 롤아웃 중](https://gitlab.com/groups/gitlab-org/-/epics/2039)입니다.

대규모 컬렉션의 경우 성능상의 이유로 오프셋 페이지 매김 대신 키셋 페이지 매김(사용 가능한 경우)을 사용해야 합니다.

### 오프셋 기반 페이지 매김 {#offset-based-pagination}

{{< history >}}

- `users` 엔드포인트는 GitLab 16.5에서 오프셋 기반 페이지 매김에 대해 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/426547)이며 17.0에서 제거할 예정입니다. 이것은 호환성이 깨지는 변경입니다. 대신 이 엔드포인트에 키셋 기반 페이지 매김을 사용하세요.
- GitLab 17.0에서 요청된 레코드 수가 50,000보다 많을 때 `users` 엔드포인트는 키셋 기반 페이지 매김을 강제합니다.

{{< /history >}}

때로는 반환된 결과가 많은 페이지에 걸쳐 있습니다. 리소스를 나열할 때 다음 매개변수를 전달할 수 있습니다:

| 매개변수  | 설명                                                   |
|:-----------|:--------------------------------------------------------------|
| `page`     | 페이지 번호(기본값: `1`).                                   |
| `per_page` | 페이지당 나열할 항목 수(기본값: `20`, 최대: `100`). |

다음 예제는 페이지당 50개의 [네임스페이스](../namespaces.md)를 나열합니다:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/namespaces?per_page=50"
```

> [!note]
> 오프셋 페이지 매김에 대한 [최대 오프셋 허용 제한](../../administration/instance_limits.md#max-offset-allowed-by-the-rest-api-for-offset-based-pagination)이 있습니다. GitLab 자체 관리 인스턴스에서 제한을 변경할 수 있습니다.

#### 페이지 매김 `Link` 헤더 {#pagination-link-header}

[`Link` 헤더](https://www.w3.org/wiki/LinkHeader)는 각 응답과 함께 반환됩니다. `rel`이(가) `prev`, `next`, `first` 또는 `last`로 설정되며 관련 URL을 포함합니다. 사용자 지정 URL을 생성하는 대신 이 링크를 사용해야 합니다.

GitLab.com 사용자의 경우 [일부 페이지 매김 헤더가 반환되지 않을 수 있습니다](../../user/gitlab_com/_index.md#pagination-response-headers).

다음 cURL 예제는 출력을 페이지당 3개 항목(`per_page=3`)으로 제한하고 ID `8`인 의 ID `9`인 프로젝트에 속하는 [댓글](../notes.md)의 두 번째 페이지(`page=2`)를 요청합니다:

```shell
curl --request GET \
  --head \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/9/issues/8/notes?per_page=3&page=2"
```

응답은 다음과 같습니다:

```http
HTTP/2 200 OK
cache-control: no-cache
content-length: 1103
content-type: application/json
date: Mon, 18 Jan 2016 09:43:18 GMT
link: <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=1&per_page=3>; rel="prev", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=3&per_page=3>; rel="next", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=1&per_page=3>; rel="first", <https://gitlab.example.com/api/v4/projects/8/issues/8/notes?page=3&per_page=3>; rel="last"
status: 200 OK
vary: Origin
x-next-page: 3
x-page: 2
x-per-page: 3
x-prev-page: 1
x-request-id: 732ad4ee-9870-4866-a199-a9db0cde3c86
x-runtime: 0.108688
x-total: 8
x-total-pages: 3
```

#### 기타 페이지 매김 헤더 {#other-pagination-headers}

GitLab은 다음 추가 페이지 매김 헤더도 반환합니다:

| 헤더          | 설명 |
|:----------------|:------------|
| `x-next-page`   | 다음 페이지의 인덱스입니다. |
| `x-page`        | 현재 페이지의 인덱스(1부터 시작). |
| `x-per-page`    | 페이지당 항목 수입니다. |
| `x-prev-page`   | 이전 페이지의 인덱스입니다. |
| `x-total`       | 총 항목 수입니다. |
| `x-total-pages` | 총 페이지 수입니다. |

GitLab.com 사용자의 경우 [일부 페이지 매김 헤더가 반환되지 않을 수 있습니다](../../user/gitlab_com/_index.md#pagination-response-headers).

### 키셋 기반 페이지 매김 {#keyset-based-pagination}

키셋 페이지 매김을 사용하면 페이지를 더 효율적으로 검색할 수 있으며, 오프셋 기반 페이지 매김과 달리 런타임은 컬렉션의 크기와 무관합니다.

이 방법은 다음 매개변수에 의해 제어됩니다. `order_by` 및 `sort`는 모두 필수입니다.

| 매개변수    | 필수 | 설명 |
|--------------|----------|-------------|
| `pagination` | 예      | `keyset`(키셋 페이지 매김을 활성화하려면). |
| `per_page`   | 아니요       | 페이지당 나열할 항목 수(기본값: `20`, 최대: `100`). |
| `order_by`   | 예      | 정렬 기준 열입니다. |
| `sort`       | 예      | 정렬 순서(`asc` 또는 `desc`) |

다음 예제는 페이지당 50개의 [프로젝트](../projects.md)를 `id` 오름차순으로 정렬하여 나열합니다.

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects?pagination=keyset&per_page=50&order_by=id&sort=asc"
```

응답 헤더에 다음 페이지로의 링크가 포함됩니다. 예를 들어:

```http
HTTP/1.1 200 OK
...
Link: <https://gitlab.example.com/api/v4/projects?pagination=keyset&per_page=50&order_by=id&sort=asc&id_after=42>; rel="next"
Status: 200 OK
...
```

다음 페이지의 링크에는 이미 검색한 레코드를 제외하는 추가 필터 `id_after=42`이(가) 포함됩니다.

또 다른 예로 다음 요청은 키셋 페이지 매김을 사용하여 `name` 오름차순으로 정렬된 페이지당 50개의 [그룹](../groups.md)을 나열합니다:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups?pagination=keyset&per_page=50&order_by=name&sort=asc"
```

응답 헤더에 다음 페이지로의 링크가 포함됩니다:

```http
HTTP/1.1 200 OK
...
Link: <https://gitlab.example.com/api/v4/groups?pagination=keyset&per_page=50&order_by=name&sort=asc&cursor=eyJuYW1lIjoiRmxpZ2h0anMiLCJpZCI6IjI2IiwiX2tkIjoibiJ9>; rel="next"
Status: 200 OK
...
```

다음 페이지의 링크에는 이미 검색한 레코드를 제외하는 추가 필터 `cursor=eyJuYW1lIjoiRmxpZ2h0anMiLCJpZCI6IjI2IiwiX2tkIjoibiJ9`이(가) 포함됩니다.

`X-NEXT-CURSOR` 헤더는 다음 페이지의 레코드를 검색하기 위한 커서 값을 포함하는 반면 `X-PREV-CURSOR` 헤더는 사용 가능한 경우 이전 페이지를 검색하기 위한 커서 값을 포함합니다.

필터의 유형은 사용된 `order_by` 옵션에 따라 다르며 둘 이상의 추가 필터를 가질 수 있습니다.

> [!warning]
> `Links` 헤더는 [W3C `Link` 사양](https://www.w3.org/wiki/LinkHeader)과 정렬되도록 제거되었습니다. `Link` 헤더를 대신 사용해야 합니다.

컬렉션의 끝에 도달하고 검색할 추가 레코드가 없으면 `Link` 헤더가 없고 결과 배열이 비어 있습니다.

사용자 지정 URL을 구축하는 대신 주어진 링크만 사용하여 다음 페이지를 검색해야 합니다. 표시된 헤더 외에 추가 페이지 매김 헤더는 노출되지 않습니다.

#### 지원되는 리소스 {#supported-resources}

키셋 기반 페이지 매김은 선택된 리소스 및 정렬 옵션에만 지원됩니다:

| 리소스                                                                       | 옵션                                                                                                                                                                               | 가용성 |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ |
| [감사 이벤트](../audit_events.md#list-all-group-audit-events)       | `order_by=id`, `sort=desc`만                                                                                                                                                       | 인증된 사용자만 해당합니다. |
| [그룹](../groups.md#list-groups)                                             | `order_by=name`, `sort=asc`만                                                                                                                                                      | 인증되지 않은 사용자만 해당합니다. |
| [인스턴스 감사 이벤트](../audit_events.md#list-all-instance-audit-events) | `order_by=id`, `sort=desc`만                                                                                                                                                       | 인증된 사용자만 해당합니다. |
| [패키지](../packages.md#list-package-pipelines)                     | `order_by=id`, `sort=desc`만                                                                                                                                                       | 인증된 사용자만 해당합니다. |
| [프로젝트 작업](../jobs.md#list-all-jobs-for-a-project)                         | `order_by=id`, `sort=desc`만                                                                                                                                                       | 인증된 사용자만 해당합니다. |
| [감사 이벤트](../audit_events.md#list-all-project-audit-events)   | `order_by=id`, `sort=desc`만                                                                                                                                                       | 인증된 사용자만 해당합니다. |
| [프로젝트](../projects.md)                                                     | `order_by=id`만                                                                                                                                                                    | 인증된 사용자 및 인증되지 않은 사용자입니다. |
| [사용자](../users.md)                                                           | `order_by=id`, `order_by=name`, `order_by=username`, `order_by=created_at` 또는 `order_by=updated_at`.                                                                                 | 인증된 사용자 및 인증되지 않은 사용자입니다. GitLab 16.5에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/419556). |
| [레지스트리](../container_registry.md)                           | `order_by=name`, `sort=asc` 또는 `sort=desc`만.                                                                                                                                     | 인증된 사용자만 해당합니다. |
| [트리 나열](../repositories.md#list-all-repository-trees-in-a-project)                | 해당 없음                                                                                                                                                                                   | 인증된 사용자 및 인증되지 않은 사용자입니다. GitLab 17.1에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154897). |
| [프로젝트 이슈](../issues.md#list-all-project-issues)                             | `order_by=created_at`, `order_by=updated_at`, `order_by=title`, `order_by=id`, `order_by=weight`, `order_by=due_date`, `order_by=relative_position`, `sort=asc` 또는 `sort=desc`만. | 인증된 사용자 및 인증되지 않은 사용자입니다. GitLab 18.3에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199887/). |

### 페이지 매김 응답 헤더 {#pagination-response-headers}

성능상의 이유로 쿼리에서 10,000개 이상의 레코드를 반환하면 GitLab은 다음 헤더를 반환하지 않습니다:

- `x-total`.
- `x-total-pages`.
- `rel="last"` `link`

## 버전 관리 및 사용 중단 {#versioning-and-deprecations}

버전은 시멘틱 버전 관리 사양을 준수합니다. 주요 버전 번호는 `4`입니다. 호환성이 깨지는 변경에는 이 버전 번호가 변경되어야 합니다.

- 부 버전이 명시적이지 않아 안정적인 API 엔드포인트가 가능합니다.
- 새로운 기능이 동일한 버전 번호로 API에 추가됩니다.
- 주요 API 버전 변경 및 전체 API 버전 제거는 주요 GitLab 릴리스와 함께 진행됩니다.
- 모든 사용 중단 및 버전 간 변경 사항은 설명서에 기록됩니다.

다음은 사용 중단 프로세스에서 제외되며 예고 없이 언제든지 제거할 수 있습니다:

- [리소스](../api_resources.md) 에 [실험적 또는 베타](../../policy/development_stages_support.md)로 표시된 요소입니다.
- 뒤에 있고 기본적으로 비활성화된 필드입니다.

GitLab 자체 관리의 경우 EE 인스턴스에서 CE로 [되돌리기](../../update/convert_to_ee/revert.md)하면 호환성이 깨지는 변경을 일으킵니다.
