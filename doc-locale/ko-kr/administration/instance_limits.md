---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 애플리케이션 제한
description: 인스턴스에서 제한을 구성합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 대부분의 대규모 애플리케이션처럼 최소한의 성능 품질을 유지하기 위해 특정 기능에 제한을 적용합니다. 일부 기능을 무제한으로 허용하면 보안, 성능, 데이터에 영향을 줄 수 있으며 애플리케이션에 할당된 리소스를 소진할 수도 있습니다.

## 인스턴스 구성 {#instance-configuration}

인스턴스 구성 페이지에서 현재 GitLab 인스턴스에서 사용되는 일부 설정에 대한 정보를 찾을 수 있습니다.

구성한 제한에 따라 다음을 볼 수 있습니다:

- SSH 호스트 키 정보
- CI/CD 제한
- GitLab Pages 제한
- 패키지 레지스트리 제한
- 속도 제한
- 크기 제한

이 페이지는 누구나 볼 수 있으므로 인증되지 않은 사용자는 자신과 관련된 정보만 볼 수 있습니다.

인스턴스 구성 페이지를 방문하려면:

1. 왼쪽 사이드바에서 **도움말** ({{< icon name="question-o" >}}) > **도움말**을 선택합니다.
1. 도움말 페이지에서 **Check the current instance configuration**을 선택합니다.

직접 URL은 `<gitlab_url>/help/instance_configuration`입니다. GitLab.com의 경우 <https://gitlab.com/help/instance_configuration>를 방문할 수 있습니다.

## 속도 제한 {#rate-limits}

속도 제한을 사용하여 GitLab의 보안과 안정성을 개선할 수 있습니다.

[속도 제한 구성](../security/rate_limits.md)에 대해 자세히 알아보세요.

### 이슈 생성 {#issue-creation}

이 설정은 이슈 생성 엔드포인트로의 요청 속도 제한을 지정합니다.

[이슈 생성 속도 제한](settings/rate_limit_on_issues_creation.md)에 대해 자세히 알아보세요.

- **Default rate limit**:  기본적으로 비활성화됨.

### 사용자 또는 IP별 {#by-user-or-ip}

이 설정은 사용자 또는 IP당 요청 속도 제한을 지정합니다.

[사용자 및 IP 속도 제한](settings/user_and_ip_rate_limits.md)에 대해 자세히 알아보세요.

- **Default rate limit**:  기본적으로 비활성화됨.

### 원본 엔드포인트별 {#by-raw-endpoint}

이 설정은 원본 엔드포인트에서의 요청 속도 제한을 지정합니다.

[원본 엔드포인트 속도 제한](settings/rate_limits_on_raw_endpoints.md)에 대해 자세히 알아보세요.

- **Default rate limit (authenticated and unauthenticated)**:  분당 300개 요청, 프로젝트 및 파일 경로당.
- **Default rate limit (unauthenticated)**:  분당 800개 요청, 프로젝트당 모든 파일 경로 전체.

### 보호된 경로별 {#by-protected-path}

이 설정은 특정 경로에서의 요청 속도 제한을 지정합니다.

GitLab은 기본적으로 POST 요청에 대해 다음 경로를 속도 제한합니다:

```plaintext
'/users/password',
'/users/sign_in',
'/api/#{API::API.version}/session.json',
'/api/#{API::API.version}/session',
'/users',
'/users/confirmation',
'/unsubscribes/',
'/import/github/personal_access_token',
'/admin/session'
```

GitLab은 기본적으로 GET 요청에 대해 다음 경로를 속도 제한합니다:

```plaintext
'/users/sign_in_path'
```

[보호된 경로 속도 제한](settings/protected_paths.md)에 대해 자세히 알아보세요.

- **Default rate limit**:  10개 요청 후 클라이언트는 다시 시도하기 전에 60초를 기다려야 합니다.

### 패키지 레지스트리 {#package-registry}

이 설정은 패키지 API에서 사용자 또는 IP당 요청 속도 제한을 지정합니다. 자세한 내용은 [패키지 레지스트리 속도 제한](settings/package_registry_rate_limits.md)을 참조하세요.

- **Default rate limit**:  기본적으로 비활성화됨.

### Git LFS {#git-lfs}

이 설정은 사용자당 [Git LFS](../topics/git/lfs/_index.md) 요청에 대한 요청 속도 제한을 지정합니다. 자세한 내용은 [GitLab Git Large File Storage (LFS) 관리](lfs/_index.md)를 읽어보세요.

- **Default rate limit**:  기본적으로 비활성화됨.

### 파일 API {#files-api}

이 설정은 사용자 또는 IP 주소당 파일 API에 대한 요청 속도 제한을 지정합니다. 자세한 내용은 [파일 API 속도 제한](settings/files_api_rate_limits.md)을 읽어보세요.

- **Default rate limit**:  기본적으로 비활성화됨.

### 더 이상 사용되지 않는 API 엔드포인트 {#deprecated-api-endpoints}

이 설정은 사용자 또는 IP 주소당 더 이상 사용되지 않는 API 엔드포인트에 대한 요청 속도 제한을 지정합니다. 자세한 내용은 [더 이상 사용되지 않는 API 속도 제한](settings/deprecated_api_rate_limits.md)을 읽어보세요.

- **Default rate limit**:  기본적으로 비활성화됨.

### 가져오기 및 내보내기 {#import-and-export}

이 설정은 그룹 및 프로젝트에 대한 파일 가져오기 및 내보내기를 제한합니다.

| 한도                   | 기본값(분당 사용자당) |
|:------------------------|:------------------------------|
| 프로젝트 가져오기          | 6개 가져오기 요청             |
| 프로젝트 내보내기          | 6개 내보내기 요청             |
| 프로젝트 내보내기 다운로드 | 1개 다운로드 요청           |
| 그룹 가져오기            | 6개 가져오기 요청             |
| 그룹 내보내기            | 6개 내보내기 요청             |
| 그룹 내보내기 다운로드   | 1개 다운로드 요청           |

이 설정은 [구성할 수 있습니다](settings/import_export_rate_limits.md).

#### 직접 이전 {#direct-transfer-migration}

{{< history >}}

- 최대 마이그레이션 수 허용 제한이 [GitLab 15.9에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/386452)되었습니다.
- 구성 가능한 설정이 [GitLab 16.3에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/384976)되었습니다.
- 마이그레이션에 대한 8시간 시간 제한이 [GitLab 16.7에서 제거](https://gitlab.com/gitlab-org/gitlab/-/issues/429867)되었습니다.

{{< /history >}}

다음 제한은 직접 이전 마이그레이션에 적용됩니다.

| 한도                                                                      | 기본값     | 구성 가능 |
|:---------------------------------------------------------------------------|:------------|:-------------|
| 대상 GitLab 인스턴스당 분당 사용자당 마이그레이션 수 | 6           | {{< no >}}   |
| 아카이브 파일 압축 해제 대기 시간                            | 210초 | {{< no >}}   |
| NDJSON 행의 길이                                                   | 50MB       | {{< no >}}   |
| 원본 인스턴스에서 빈 내보내기 상태가 발생할 때까지의 시간            | 5분   | {{< no >}}   |
| 원본 인스턴스에서 다운로드할 수 있는 관계 크기             | 5GiB       | {{< yes >}}  |
| 압축 해제된 아카이브 크기                                            | 10GiB      | {{< yes >}}  |

구성 가능한 제한 변경에 대한 자세한 내용은 [가져오기 및 내보내기 설정](settings/import_and_export_settings.md)을 참조하세요.

### 구성원 초대 {#member-invitations}

그룹 계층당 허용된 최대 일일 구성원 초대를 제한합니다.

- GitLab.com:  무료 구성원은 하루에 20명을 초대할 수 있으며, Premium 평가판 및 Ultimate 평가판 구성원은 하루에 50명을 초대할 수 있습니다.
- GitLab 자체 관리:  초대는 제한되지 않습니다.

### 웹후크 속도 제한 {#webhook-rate-limit}

상위 수준 네임스페이스의 웹후크를 호출할 수 있는 횟수를 분당 제한합니다. 네임스페이스 내의 모든 프로젝트 및 그룹 웹후크는 이 제한을 공유합니다.

속도 제한을 초과하는 호출은 `auth.log`에 기록됩니다.

GitLab 자체 관리 인스턴스에 대해 이 제한을 설정하려면 [패키지 레지스트리 계획 제한 API](../api/plan_limits.md) 를 사용하거나 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(web_hook_calls: 10)
```

제한을 `0`로 설정하여 비활성화합니다.

- **Default rate limit**:  비활성화됨(무제한).

### 검색 속도 제한 {#search-rate-limit}

{{< history >}}

- [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104208)되었으며 GitLab 15.9에서 이슈, 머지 리퀘스트 및 에픽 검색을 속도 제한에 포함합니다.
- [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118525) 되었으며 GitLab 16.0에서 [검색 범위](../user/search/_index.md#disable-global-search-scopes)에 인증된 요청에 대한 속도 제한을 적용합니다.

{{< /history >}}

이 설정은 다음과 같이 검색 요청을 제한합니다:

| 한도                | 기본값(분당 요청 수) |
|----------------------|-------------------------------|
| 인증된 사용자   | 30                            |
| 인증되지 않은 사용자 | 10                            |

분당 검색 속도 제한을 초과하는 검색 요청은 다음 오류를 반환합니다:

```plaintext
This endpoint has been requested too many times. Try again later.
```

### 자동 완성 사용자 속도 제한 {#autocomplete-users-rate-limit}

{{< history >}}

- [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/368926) 되었으며 GitLab 17.10에서 [플래그 포함](feature_flags/_index.md) `autocomplete_users_rate_limit`. 기본적으로 비활성화됨.
- [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/523595)하며 GitLab 18.1에서 사용할 수 있습니다. 기능 플래그 `autocomplete_users_rate_limit` 제거됨.

{{< /history >}}

이 설정은 다음과 같이 자동 완성 사용자 요청을 제한합니다:

| 한도                | 기본값(분당 요청 수) |
|----------------------|-------------------------------|
| 인증된 사용자   | 300                           |
| 인증되지 않은 사용자 | 100                           |

분당 자동 완성 속도 제한을 초과하는 자동 완성 요청은 다음 오류를 반환합니다:

```plaintext
This endpoint has been requested too many times. Try again later.
```

### 파이프라인 생성 속도 제한 {#pipeline-creation-rate-limit}

{{< history >}}

- [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/362475)되었으며 GitLab 15.0에서 사용할 수 있습니다.

{{< /history >}}

이 설정은 파이프라인 생성 엔드포인트로의 요청 속도 제한을 지정합니다.

[파이프라인 생성 속도 제한](settings/rate_limit_on_pipelines_creation.md)에 대해 자세히 알아보세요.

## Gitaly 동시성 제한 {#gitaly-concurrency-limit}

클론 트래픽은 Gitaly 서비스에 큰 부담을 줄 수 있습니다. 이러한 워크로드가 Gitaly 서버를 압도하는 것을 방지하려면 Gitaly 구성 파일에서 동시성 제한을 설정할 수 있습니다.

[Gitaly 동시성 제한](gitaly/concurrency_limiting.md#limit-rpc-concurrency)에 대해 자세히 알아보세요.

- **Default rate limit**:  비활성화됨.

## 이슈, 머지 리퀘스트 또는 커밋당 주석 수 {#number-of-comments-per-issue-merge-request-or-commit}

이슈, 머지 리퀘스트 또는 커밋에 제출할 수 있는 주석 수에 제한이 있습니다. 제한에 도달하면 시스템 노트를 계속 추가하여 이벤트 기록이 손실되지 않도록 할 수 있지만 사용자가 제출한 주석은 실패합니다.

- **Max limit**:  5,000개 주석.

## 이슈, 머지 리퀘스트 및 에픽의 주석 및 설명 크기 {#size-of-comments-and-descriptions-of-issues-merge-requests-and-epics}

이슈, 머지 리퀘스트 및 에픽의 주석 및 설명 크기에 제한이 있습니다. 제한보다 큰 텍스트 본문을 추가하려고 하면 오류가 발생하며 항목도 생성되지 않습니다.

이 제한이 향후 더 낮은 수로 변경될 가능성이 있습니다.

- **Max size**: ~100만 문자 / ~1MB.

## 커밋 제목 및 설명 크기 {#size-of-commit-titles-and-descriptions}

임의로 큰 메시지가 있는 커밋을 GitLab으로 푸시할 수 있지만 다음 표시 제한이 적용됩니다:

- **제목** \- 커밋 메시지의 첫 번째 줄. 1KiB로 제한됨.
- **설명** \- 커밋 메시지의 나머지. 1MiB로 제한됨.

커밋이 푸시되면 GitLab은 제목과 설명을 처리하여 이슈(`#123`) 및 머지 리퀘스트(`!123`) 참조를 이슈 및 머지 리퀘스트로의 링크로 바꿉니다.

많은 수의 커밋이 있는 브랜치가 푸시되면 마지막 100개 커밋만 처리됩니다.

### 리베이스 작업 중 크기 {#size-during-rebase-operations}

커밋을 리베이스하면 크기 제한을 초과하는 커밋 메시지가 잘립니다. 이 제한은 커밋 제목 및 설명의 크기 제한과는 별개입니다.

- **한도**:  10,240바이트(10KB).

## 마일스톤 개요의 이슈 수 {#number-of-issues-in-the-milestone-overview}

마일스톤 개요 페이지에 로드되는 최대 이슈 수는 500입니다. 수가 제한을 초과하면 페이지는 경고를 표시하고 마일스톤의 모든 이슈의 페이지가 매겨진 [이슈 목록](../user/project/issues/managing_issues.md)으로 연결됩니다.

- **한도**:  500개 이슈.

## Git 푸시당 파이프라인 수 {#number-of-pipelines-per-git-push}

여러 태그 또는 브랜치와 같은 단일 Git 푸시로 여러 변경 사항을 푸시할 때 기본적으로 4개의 태그 또는 브랜치 파이프라인만 트리거될 수 있습니다. 이 제한은 `git push --all` 또는 `git push --mirror`를 사용할 때 많은 수의 파이프라인 생성 사고를 방지합니다.

[머지 리퀘스트 파이프라인](../ci/pipelines/merge_request_pipelines.md)은 제한됩니다. Git 푸시가 동시에 여러 머지 리퀘스트를 업데이트하면 제한에 도달하기 전에 업데이트된 모든 머지 리퀘스트에 대해 머지 리퀘스트 파이프라인이 트리거될 수 있습니다.

기본값은 GitLab 자체 관리 및 GitLab.com에 대해 `4`입니다.

GitLab 자체 관리 인스턴스에서 이 제한을 변경하려면 [운영자 영역](settings/continuous_integration.md#pipeline-limit-per-git-push)을 사용합니다.

> [!warning]
> 이 제한을 늘리는 것은 권장되지 않습니다. 많은 변경 사항이 동시에 푸시된 경우 GitLab 인스턴스에 과도한 부하를 유발할 수 있으며, 잠재적으로 파이프라인의 홍수를 야기할 수 있습니다.

## 활동 기록 보존 {#retention-of-activity-history}

프로젝트 및 개인 프로필의 활동 기록은 3년으로 제한됩니다.

## 포함된 메트릭 수 {#number-of-embedded-metrics}

성능상의 이유로 GitLab Flavored Markdown(GLFM)에 메트릭을 포함할 때 제한이 있습니다.

- **Max limit**:  100개 포함.

## HTTP 응답 제한 {#http-response-limits}

### 최대 Gzip 압축 크기 {#maximum-gzip-compressed-size}

{{< history >}}

- GitLab 17.10에서 도입됨.

{{< /history >}}

이 설정은 압축 해제 후 Gzip 압축 HTTP 응답의 최대 허용 크기(MiB)를 제한합니다.

기본 최대 크기는 100MiB입니다. 이 제한을 비활성화하려면 값을 0으로 설정합니다.

GitLab Rails 콘솔을 사용하거나 [애플리케이션 설정 API](../api/settings.md)를 사용하여 이 제한을 변경할 수 있습니다

 ```ruby
 ApplicationSetting.update(max_http_decompressed_size: 50)
 ```

### 아웃바운드 요청의 최대 HTTP 응답 크기 {#maximum-http-responses-size-from-outbound-requests}

{{< history >}}

- GitLab 17.10에서 도입됨.

{{< /history >}}

이 설정은 압축 해제된 HTTP 응답의 최대 허용 크기(MiB)를 제한합니다. 통합, 가져오기 도구 및 웹후크에 적용됩니다.

기본 최대 크기는 100MiB입니다. 이 제한을 비활성화하려면 값을 0으로 설정합니다.

GitLab Rails 콘솔을 사용하거나 [애플리케이션 설정 API](../api/settings.md)를 사용하여 이 제한을 변경할 수 있습니다

 ```ruby
 ApplicationSetting.update(max_http_response_size_limit: 60)
 ```

### 아웃바운드 요청의 JSON HTTP 응답에서 최대 허용 객체 수 {#maximum-allowed-object-count-in-json-http-responses-from-outbound-requests}

{{< history >}}

- GitLab 18.4에서 도입됨.

{{< /history >}}

이 설정은 아웃바운드 요청의 JSON HTTP 응답에서 최대 허용 객체 수를 제한합니다. 객체의 수는 응답에서 `:`, `,`, `{` 및 `[`의 발생 수를 기반으로 추정됩니다.

기본 최대 개수는 1,000,000개 객체입니다. 이 제한을 비활성화하려면 값을 0으로 설정합니다.

GitLab Rails 콘솔을 사용하거나 [애플리케이션 설정 API](../api/settings.md)를 사용하여 이 제한을 변경할 수 있습니다:

```ruby
ApplicationSetting.update(max_http_response_json_structural_chars: 500000)
```

### 아웃바운드 요청의 JSON HTTP 응답에서 최대 허용 중첩 깊이 {#maximum-allowed-nesting-depth-in-json-http-responses-from-outbound-requests}

{{< history >}}

- GitLab 18.4에서 도입됨.

{{< /history >}}

이 설정은 아웃바운드 요청의 JSON HTTP 응답에서 최대 허용 중첩 깊이를 제한합니다.

기본 최대 중첩 깊이는 32입니다.

GitLab Rails 콘솔을 사용하거나 [애플리케이션 설정 API](../api/settings.md)를 사용하여 이 제한을 변경할 수 있습니다:

```ruby
ApplicationSetting.update(max_http_response_json_depth: 100)
```

### 아웃바운드 요청의 XML HTTP 응답에서 최대 허용 객체 수 {#maximum-allowed-object-count-in-xml-http-responses-from-outbound-requests}

{{< history >}}

- GitLab 18.4에서 도입됨.

{{< /history >}}

이 설정은 아웃바운드 요청의 XML HTTP 응답에서 최대 허용 객체 수를 제한합니다. 객체의 수는 응답에서 `<`, `=`의 발생 수를 기반으로 추정됩니다.

기본 최대 개수는 250,000개 객체입니다. 이 제한을 비활성화하려면 값을 0으로 설정합니다.

GitLab Rails 콘솔을 사용하거나 [애플리케이션 설정 API](../api/settings.md)를 사용하여 이 제한을 변경할 수 있습니다:

```ruby
ApplicationSetting.update(max_http_response_xml_structural_chars: 500000)
```

### 아웃바운드 요청의 CSV HTTP 응답에서 최대 허용 객체 수 {#maximum-allowed-object-count-in-csv-http-responses-from-outbound-requests}

{{< history >}}

- GitLab 18.4에서 도입됨.

{{< /history >}}

이 설정은 아웃바운드 요청의 CSV HTTP 응답에서 최대 허용 객체 수를 제한합니다. 객체의 수는 응답에서 `,`, `;`, `\t`, `\r` 및 `\n`의 발생 수를 기반으로 추정됩니다.

기본 최대 개수는 250,000개 객체입니다. 이 제한을 비활성화하려면 값을 0으로 설정합니다.

GitLab Rails 콘솔을 사용하거나 [애플리케이션 설정 API](../api/settings.md)를 사용하여 이 제한을 변경할 수 있습니다:

```ruby
ApplicationSetting.update(max_http_response_csv_structural_chars: 500000)
```

## HTTP 요청 제한 {#http-request-limits}

기본적으로 요청의 JSON 매개 변수가 제한됩니다. 자세한 내용은 [엔드포인트별 JSON 유효성 검사 제한](#json-validation-limits-by-endpoint)을 참조하세요.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

이 확인을 비활성화하려면:

1. `GITLAB_JSON_GLOBAL_VALIDATION_MODE` 환경 변수를 Puma를 실행하는 모든 노드에 설정합니다:

   ```shell
   sudo -e /etc/gitlab/gitlab.rb
   ```

   ```ruby
   gitlab_rails['env'] = { 'GITLAB_JSON_GLOBAL_VALIDATION_MODE' => 'disabled' }
   ```

1. 변경 사항이 적용되도록 업데이트된 노드를 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

이 확인을 비활성화하려면 `--set gitlab.webservice.extraEnv.GITLAB_JSON_GLOBAL_VALIDATION_MODE="disabled"`를 사용하거나 값 파일에서 다음을 지정할 수 있습니다:

```yaml
gitlab:
  webservice:
    extraEnv:
      GITLAB_JSON_GLOBAL_VALIDATION_MODE: "disabled"
```

{{< /tab >}}

{{< /tabs >}}

### 엔드포인트별 JSON 유효성 검사 제한 {#json-validation-limits-by-endpoint}

일부 API 엔드포인트에는 특정 JSON 유효성 검사 제한이 있습니다.

| 엔드포인트                                                                                     | 설명           | 메서드 | 최대 깊이 | 최대 배열 크기 | 최대 해시 크기 | 최대 총 요소 | 최대 JSON 크기 | 모드 |
|:---------------------------------------------------------------------------------------------|:----------------------|:--------|:----------|:---------------|:--------------|:-------------------|:--------------|:-----|
| 다른 모든 경로                                                                              | 기본값               | 모두     | 32        | 50,000         | 50,000        | 100,000            | 0(비활성화됨)  | 적용됨 |
| `/api/v4/projects/{id}/terraform/state/`                                                     | Terraform 상태       | POST    | 64        | 50,000         | 50,000        | 250,000            | 50MB         | 로깅 <sup>1</sup> |
| `/api/v4/packages/npm/-/npm/v1/security/`<br/>`{advisories/bulk\|audits/quick}`               | NPM 인스턴스 패키지 | POST    | 32        | 50,000         | 50,000        | 250,000            | 50MB         | 적용됨 |
| `/api/v4/groups/{id}/-/packages/npm/-/npm/v1/security/`<br/>`{advisories/bulk\|audits/quick}` | NPM 그룹 패키지    | POST    | 32        | 50,000         | 50,000        | 250,000            | 50MB         | 적용됨 |
| `/api/v4/projects/{id}/packages/npm/-/npm/v1/security/`<br/>`{advisories/bulk\|audits/quick}` | NPM 프로젝트 패키지  | POST    | 32        | 50,000         | 50,000        | 250,000            | 50MB         | 적용됨 |
| `/api/v4/internal/*`                                                                         | 내부 API          | POST    | 32        | 50,000         | 50,000        | 0(비활성화됨)       | 10MB         | 적용됨 |
| `/api/v4/ai/duo_workflows/workflows/*`                                                        | GitLab Duo 워크플로우 API      | POST    | 32        | 5,000          | 5,000         | 0(비활성화됨)       | 25MB         | 적용됨 |

**각주**:

1. Terraform 상태 최대 크기 제한은 [애플리케이션 설정 API](../api/settings.md)를 사용하여 `max_terraform_state_size_bytes`를 설정하여 설정할 수 있습니다.

### 환경 변수 구성 {#environment-variable-configuration}

다음 환경 변수는 기본 제한 및 유효성 검사 모드를 수정합니다:

| 환경 변수                 | 목적                     | 기본값      | 범위 |
|:-------------------------------------|:----------------------------|:-------------|:------|
| `GITLAB_JSON_MAX_DEPTH`              | 기본 최대 중첩 깊이   | 32           | 기본 제한만 |
| `GITLAB_JSON_MAX_ARRAY_SIZE`         | 기본 최대 배열 요소  | 50,000       | 기본 제한만 |
| `GITLAB_JSON_MAX_HASH_SIZE`          | 기본 최대 해시 키       | 50,000       | 기본 제한만 |
| `GITLAB_JSON_MAX_TOTAL_ELEMENTS`     | 기본 최대 총 요소  | 100,000      | 기본 제한만 |
| `GITLAB_JSON_MAX_JSON_SIZE_BYTES`    | 기본 최대 본문 크기       | 0(비활성화됨) | 기본 제한만 |
| `GITLAB_JSON_VALIDATION_MODE`        | 기본 유효성 검사 모드     | `enforced`   | 기본 제한만 |
| `GITLAB_JSON_GLOBAL_VALIDATION_MODE` | 모든 엔드포인트 모드 무시 | 설정 안 함      | 모든 엔드포인트(전역 무시) |

`GITLAB_JSON_GLOBAL_VALIDATION_MODE` 환경 변수는 다음 모드 중 하나로 설정할 수 있습니다.

| 모드       | 설명 |
|:-----------|:------------|
| `enforced` | 제한을 초과하는 요청을 유효성 검사하고 차단합니다(HTTP 400 반환). 프로덕션 보호에 사용됩니다. |
| `logging`  | 위반을 유효성 검사하고 기록하지만 요청을 통과시킵니다. 모니터링 및 디버깅에 사용됩니다. 모든 엔드포인트는 로그만 수행하며 이는 `enforced`를 무시합니다. |
| 비활성화됨   | 유효성 검사를 완전히 건너뜁니다. 긴급 우회로 사용됩니다. |

`GITLAB_JSON_GLOBAL_VALIDATION_MODE`를 사용할 때:

- 경로별 구성은 기본 제한을 무시하지만 전역 유효성 검사 모드는 무시하지 않습니다.
- 적용된 모드에서 제한을 초과하면 응답은 JSON 오류 메시지가 포함된 HTTP 400입니다.
- 총 요소 수는 전체 JSON 구조 전체에서 배열 및 해시의 모든 요소를 포함합니다.

## 웹후크 제한 {#webhook-limits}

[웹후크 속도 제한](#webhook-rate-limit)도 참조하세요.

### 웹후크 수 {#number-of-webhooks}

GitLab 자체 관리 인스턴스에 대한 그룹 또는 프로젝트 웹후크의 최대 수를 설정하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

# For project webhooks
Plan.default.actual_limits.update!(project_hooks: 200)

# For group webhooks
Plan.default.actual_limits.update!(group_hooks: 100)
```

제한을 `0`로 설정하여 비활성화합니다.

웹후크의 기본 최대 수는 프로젝트당 `100`, 그룹당 `50`입니다. 하위 그룹의 웹후크는 상위 그룹의 웹후크 제한에 포함되지 않습니다.

GitLab.com의 경우 [GitLab.com용 웹후크 제한](../user/gitlab_com/_index.md#webhooks)을 참조하세요.

### 웹후크 페이로드 크기 {#webhook-payload-size}

최대 웹후크 페이로드 크기는 25MB입니다.

### 웹후크 시간 초과 {#webhook-timeout}

GitLab이 웹후크를 전송한 후 HTTP 응답을 대기하는 시간(초)입니다.

웹후크 시간 초과 값을 변경하려면:

1. `/etc/gitlab/gitlab.rb`을 Sidekiq를 실행하는 모든 GitLab 노드에서 편집합니다:

   ```ruby
   gitlab_rails['webhook_timeout'] = 60
   ```

1. 파일을 저장합니다.
1. 변경 사항이 적용되도록 GitLab을 다시 구성하고 다시 시작합니다:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

[GitLab.com용 웹후크 제한](../user/gitlab_com/_index.md#other-limits)도 참조하세요.

### 재귀 웹후크 {#recursive-webhooks}

GitLab은 재귀이거나 다른 웹후크에서 트리거될 수 있는 웹후크 제한을 초과하는 웹후크를 감지하고 차단합니다. 이를 통해 GitLab은 웹후크를 사용하여 API를 비재귀적으로 호출하거나 합리적이지 않은 수의 다른 웹후크를 트리거하지 않는 워크플로우를 계속 지원할 수 있습니다.

재귀는 웹후크가 자체 GitLab 인스턴스(예: API)에 호출하도록 구성될 때 발생할 수 있습니다. 호출은 동일한 웹후크를 트리거하고 무한 루프를 만듭니다.

다른 웹후크를 트리거하는 웹후크 시리즈에서 인스턴스로 만든 최대 요청 수는 100입니다. 제한에 도달하면 GitLab은 시리즈에 의해 트리거될 추가 웹후크를 차단합니다.

차단된 재귀 웹후크 호출은 `auth.log`에 `"Recursive webhook blocked from executing"` 메시지와 함께 기록됩니다.

## 가져오기 자리 표시자 사용자 제한 {#import-placeholder-user-limits}

{{< history >}}

- [GitLab 17.4에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/455903)되었습니다.

{{< /history >}}

가져오기 중에 생성된 [자리 표시자 사용자](../user/import/mapping/post_migration_mapping.md#placeholder-users) 수는 상위 수준 네임스페이스당 제한될 수 있습니다.

[GitLab 자체 관리](../subscriptions/manage_subscription.md)에 대한 기본 제한은 `0`(무제한)입니다.

GitLab 자체 관리 인스턴스에 대해 이 제한을 변경하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(import_placeholder_user_limit_tier_1: 200)
```

제한을 `0`로 설정하여 비활성화합니다.

## 당겨오기 미러링 간격 {#pull-mirroring-interval}

[당겨오기 새로 고침 간의 최소 대기 시간](../user/project/repository/mirror/_index.md)의 기본값은 300초(5분)입니다. 예를 들어 당겨오기 새로 고침은 얼마나 많은 시간을 트리거하든 관계없이 주어진 300초 기간 동안 한 번만 실행됩니다.

이 설정은 [리포지토리 프로젝트 API](../api/project_pull_mirroring.md#start-the-pull-mirroring-process-for-a-project)를 사용하여 호출된 당겨오기 새로 고침의 컨텍스트에 적용되거나 **지금 업데이트**({{< icon name="retry" >}}) 선택하여 강제 업데이트할 때 **설정** > **리포지토리** > **리포지토리 미러링**에서 선택합니다. 이 설정은 [당겨오기 미러링](../user/project/repository/mirror/pull.md)을 위해 Sidekiq에서 사용하는 자동 30분 간격 일정에 영향을 주지 않습니다.

GitLab 자체 관리 인스턴스에 대해 이 제한을 변경하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(pull_mirror_interval_seconds: 200)
```

## 자동 응답자의 수신 이메일 {#incoming-emails-from-auto-responders}

GitLab은 `X-Autoreply` 헤더를 찾아 자동 응답자에서 보낸 모든 수신 이메일을 무시합니다. 이러한 이메일은 이슈 또는 머지 리퀘스트에 주석을 생성하지 않습니다.

## Sentry를 통해 Error Tracking으로 전송된 데이터 양 {#amount-of-data-sent-from-sentry-through-error-tracking}

{{< history >}}

- [모든 Sentry 응답 제한](https://gitlab.com/gitlab-org/gitlab/-/issues/356448)이 GitLab 15.6에서 도입되었습니다.

{{< /history >}}

GitLab으로 전송된 Sentry 페이로드의 최대 제한은 1MB이며, 보안상의 이유와 메모리 소비를 제한하기 위함입니다.

## 오프셋 기반 페이지 매김을 위해 REST API에서 허용된 최대 오프셋 {#max-offset-allowed-by-the-rest-api-for-offset-based-pagination}

REST API에서 오프셋 기반 페이지 매김을 사용할 때 결과 집합으로의 최대 요청된 오프셋에 제한이 있습니다. 이 제한은 키셋 기반 페이지 매김도 지원하는 엔드포인트에만 적용됩니다. 페이지 매김 옵션에 대한 자세한 내용은 [API 문서의 페이지 매김 섹션](../api/rest/_index.md#pagination)을 참조하세요.

GitLab 자체 관리 인스턴스에 대해 이 제한을 설정하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(offset_pagination_limit: 10000)
```

- **Default offset pagination limit**: `50000`.

제한을 `0`로 설정하여 비활성화합니다.

## CI/CD 제한 {#cicd-limits}

### 활성 파이프라인의 작업 수 {#number-of-jobs-in-active-pipelines}

활성 파이프라인의 총 작업 수는 프로젝트당 제한될 수 있습니다. 이 제한은 새 파이프라인이 생성될 때마다 확인됩니다. 활성 파이프라인은 다음 상태 중 하나에 있는 모든 파이프라인입니다:

- `created`
- `pending`
- `running`

새 파이프라인이 작업 수가 제한을 초과하도록 하면 파이프라인은 `job_activity_limit_exceeded` 오류로 실패합니다.

- GitLab.com에서 제한은 [각 구독 계층에 대해 정의](../user/gitlab_com/_index.md#cicd)되며 이 제한은 해당 계층의 모든 프로젝트에 영향을 줍니다.
- GitLab 자체 관리에서 [Premium 또는 Ultimate](https://about.gitlab.com/pricing/) 구독, 이 제한은 모든 프로젝트에 영향을 주는 `default` 계획에서 정의됩니다. 이 제한은 기본적으로 `0`로 비활성화됩니다.

GitLab 자체 관리 인스턴스에 대해 이 제한을 설정하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(ci_active_jobs: 500)
```

제한을 `0`로 설정하여 비활성화합니다.

### 작업이 실행될 수 있는 최대 시간 {#maximum-time-jobs-can-run}

작업이 실행될 수 있는 기본 최대 시간은 60분입니다. 60분 이상 실행되는 작업은 시간 초과됩니다.

작업이 시간 초과되기 전에 실행할 수 있는 최대 시간을 변경할 수 있습니다:

- 지정된 프로젝트에 대해 [프로젝트의 CI/CD 설정](../ci/pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)의 프로젝트 수준에서. 이 제한은 10분에서 1개월 사이여야 합니다.
- [러너 수준](../ci/runners/configure_runners.md#set-the-maximum-job-timeout)에서. 이 제한은 10분 이상이어야 합니다.

구성된 시간 초과 제한에 관계없이 GitLab은 60분 동안 비활성 상태인 모든 작업을 종료합니다. 비활성 작업은 새로운 로그나 추적 업데이트를 생성하지 않은 작업입니다.

### 파이프라인의 최대 작업 수 {#maximum-number-of-jobs-in-a-pipeline}

파이프라인의 최대 작업 수를 제한할 수 있습니다. 파이프라인의 작업 수는 파이프라인 생성 시와 새 커밋 상태가 생성될 때 확인됩니다. 너무 많은 작업이 있는 파이프라인은 `size_limit_exceeded` 오류로 실패합니다.

- GitLab.com에서 제한은 [각 구독 계층에 대해 정의](../user/gitlab_com/_index.md#cicd)되며 이 제한은 해당 계층의 모든 프로젝트에 영향을 줍니다.
- GitLab 자체 관리에서 [Premium 또는 Ultimate](https://about.gitlab.com/pricing/) 구독, 이 제한은 모든 프로젝트에 영향을 주는 `default` 계획에서 정의됩니다. 이 제한은 기본적으로 `0`로 비활성화됩니다.

GitLab 자체 관리 인스턴스에 대해 제한을 변경하려면 `default` 계획의 제한을 다음 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session) 명령으로 변경합니다:

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(ci_pipeline_size: 500)
```

제한을 `0`로 설정하여 비활성화합니다.

### 파이프라인의 최대 배포 작업 수 {#maximum-number-of-deployment-jobs-in-a-pipeline}

파이프라인의 최대 배포 작업 수를 제한할 수 있습니다. 배포는 [`environment`](../ci/environments/_index.md)가 지정된 모든 작업입니다. 파이프라인의 배포 수는 파이프라인 생성 시 확인됩니다. 너무 많은 배포가 있는 파이프라인은 `deployments_limit_exceeded` 오류로 실패합니다.

기본 제한은 모든 [GitLab 자체 관리 및 GitLab.com 구독](https://about.gitlab.com/pricing/)에 대해 500입니다.

GitLab 자체 관리 인스턴스에 대해 제한을 변경하려면 `default` 계획의 제한을 다음 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session) 명령으로 변경합니다:

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(ci_pipeline_deployments: 500)
```

제한을 `0`로 설정하여 비활성화합니다.

### 파이프라인 계층 구조 크기 제한 {#limit-pipeline-hierarchy-size}

기본적으로 [파이프라인 계층 구조](../ci/pipelines/downstream_pipelines.md)는 최대 1000개의 다운스트림 파이프라인을 포함할 수 있습니다. 이 제한을 초과하면 파이프라인 생성은 오류 `downstream pipeline tree is too large`로 실패합니다.

> [!warning]
> 이 제한을 늘리는 것은 권장되지 않습니다. 기본 제한은 GitLab 인스턴스를 과도한 리소스 소비, 잠재적 파이프라인 재귀 및 데이터베이스 오버로드로부터 보호합니다.
>
> 제한을 늘리는 대신 큰 파이프라인 계층 구조를 더 작은 파이프라인으로 분할하여 CI/CD 구성을 재구성합니다. 작업 간 또는 단일 파이프라인 내 종속 스테이지에 `needs`를 사용하는 것을 고려합니다.

인스턴스에서 이 제한을 수정하려면 [운영자 영역](settings/continuous_integration.md#set-cicd-limits) 의 GitLab UI 또는 [패키지 레지스트리 계획 제한 API](../api/plan_limits.md)를 사용합니다.

GitLab Rails 콘솔에서 다음 명령을 실행할 수도 있습니다:

```ruby
Plan.default.actual_limits.update!(pipeline_hierarchy_size: 500)
```

이 제한은 GitLab.com에서 활성화되어 있으며 변경할 수 없습니다.

### 머지 트레인 병렬 파이프라인 제한 {#merge-train-parallel-pipeline-limit}

{{< history >}}

- [GitLab 19.0에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/374188)되었습니다.

{{< /history >}}

기본적으로 각 [머지 트레인](../ci/pipelines/merge_trains.md)은 최대 20개의 파이프라인을 병렬로 실행할 수 있습니다. 이 제한에 도달하면 파이프라인 슬롯을 사용할 수 있을 때까지 추가 머지 리퀘스트가 대기열에 올라갑니다.

인스턴스에서 이 제한을 수정하려면 **운영자** 영역 > **설정** > **CI/CD** > **CI/CD Limits**으로 이동하거나 [계획 제한 API](../api/plan_limits.md)를 사용합니다.

GitLab Rails 콘솔에서 다음 명령을 실행할 수도 있습니다:

```ruby
Plan.default.actual_limits.update!(max_pipelines_per_merge_train: 10)
```

특정 프로젝트에 대한 낮은 제한을 설정하려면 **설정** > **머지 리퀘스트** > **머지 옵션**으로 이동하거나 [프로젝트 API](../api/projects.md) 또는 [GraphQL API](../api/graphql/reference/_index.md#projectcicdsetting)를 사용합니다. 프로젝트 제한은 인스턴스 제한을 초과할 수 없습니다.

최소값은 `1`입니다. `1`의 값은 머지 리퀘스트를 병렬 처리 없이 순차적으로 처리합니다.

### 프로젝트에 대한 CI/CD 구독 수 {#number-of-cicd-subscriptions-to-a-project}

구독의 총 수는 프로젝트당 제한될 수 있습니다. 이 제한은 새 구독이 생성될 때마다 확인됩니다.

새 구독이 구독의 총 수가 제한을 초과하도록 하면 구독은 유효하지 않은 것으로 간주됩니다.

- GitLab.com에서 제한은 [각 구독 계층에 대해 정의](../user/gitlab_com/_index.md#cicd)되며 이 제한은 해당 계층의 모든 프로젝트에 영향을 줍니다.
- GitLab 자체 관리 [Premium 또는 Ultimate](https://about.gitlab.com/pricing/)에서 이 제한은 모든 프로젝트에 영향을 주는 `default` 계획에서 정의됩니다. 기본적으로 `2` 구독의 제한이 있습니다.

GitLab 자체 관리 인스턴스에 대해 이 제한을 설정하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
Plan.default.actual_limits.update!(ci_project_subscriptions: 500)
```

제한을 `0`로 설정하여 비활성화합니다.

### 파이프라인 트리거 수 제한 {#limit-the-number-of-pipeline-triggers}

프로젝트당 파이프라인 트리거의 최대 수에 제한을 설정할 수 있습니다. 이 제한은 새 트리거가 생성될 때마다 확인됩니다.

새 트리거가 파이프라인 트리거의 총 수가 제한을 초과하도록 하면 트리거는 유효하지 않은 것으로 간주됩니다.

제한을 `0`로 설정하여 비활성화합니다. GitLab 자체 관리에서 기본값 `25000`.

GitLab 자체 관리 인스턴스에서 이 제한을 `100`로 설정하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
Plan.default.actual_limits.update!(pipeline_triggers: 100)
```

이 제한은 [GitLab.com에서 활성화](../user/gitlab_com/_index.md#cicd)됩니다.

### 파이프라인 일정 수 {#number-of-pipeline-schedules}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab 자체 관리, GitLab 전용

{{< /details >}}

프로젝트당 파이프라인 일정의 총 수는 제한될 수 있습니다. 이 제한은 새 파이프라인 일정이 생성될 때마다 확인됩니다. 새 파이프라인 일정이 파이프라인 일정의 총 수가 제한을 초과하도록 하면 파이프라인 일정이 생성되지 않습니다.

GitLab.com에서 제한은 [각 구독 계층에 대해 정의](../user/gitlab_com/_index.md#cicd)되며 이 제한은 해당 계층의 모든 프로젝트에 영향을 줍니다.

GitLab 자체 관리 및 GitLab 전용에서 이 제한은 모든 프로젝트에 영향을 주는 `default` 계획에서 정의됩니다. 기본적으로 `10` 파이프라인 일정의 제한이 있습니다.

이 제한을 설정하려면 [패키지 레지스트리 계획 제한 API](../api/plan_limits.md)를 사용합니다.

GitLab 자체 관리의 경우 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)을 사용할 수도 있습니다. 예를 들어 제한을 100으로 설정하려면:

```ruby
Plan.default.actual_limits.update!(ci_pipeline_schedules: 100)
```

### 파이프라인 일정이 하루에 생성할 수 있는 파이프라인 수 제한 {#limit-the-number-of-pipelines-created-by-a-pipeline-schedule-each-day}

각 개별 파이프라인 일정이 하루에 트리거할 수 있는 파이프라인 수를 제한할 수 있습니다.

제한보다 더 자주 파이프라인을 실행하려는 일정은 최대 빈도로 감속됩니다. 빈도는 1440(하루의 분 수)을 제한 값으로 나누어 계산됩니다. 예를 들어 최대 빈도의 경우:

- 분당 한 번, 제한은 `1440`여야 합니다.
- 10분마다 한 번, 제한은 `144`여야 합니다.
- 60분마다 한 번, 제한은 `24`여야 합니다

최소값은 `24` 또는 60분마다 하나의 파이프라인입니다. 최대값이 없습니다.

GitLab 자체 관리 인스턴스에서 이 제한을 `1440`로 설정하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
Plan.default.actual_limits.update!(ci_daily_pipeline_schedule_triggers: 1440)
```

이 제한은 [GitLab.com에서 활성화](../user/gitlab_com/_index.md#cicd)됩니다.

### 보안 정책 프로젝트에 대해 정의된 일정 규칙 수 제한 {#limit-the-number-of-schedule-rules-defined-for-security-policy-project}

{{< history >}}

- [GitLab 15.1에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/335659)되었습니다.

{{< /history >}}

보안 정책 프로젝트당 일정 규칙의 총 수를 제한할 수 있습니다. 이 제한은 일정 규칙이 있는 정책이 업데이트될 때마다 확인됩니다. 새 일정 규칙이 일정 규칙의 총 수가 제한을 초과하도록 하면 새 일정 규칙이 처리되지 않습니다.

기본적으로 GitLab 자체 관리는 처리 가능한 일정 규칙의 수를 제한하지 않습니다.

GitLab 자체 관리 인스턴스에 대해 이 제한을 설정하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
Plan.default.actual_limits.update!(security_policy_scan_execution_schedules: 100)
```

이 제한은 [GitLab.com에서 활성화](../user/gitlab_com/_index.md#cicd)됩니다.

### CI/CD 변수 제한 {#cicd-variable-limits}

{{< history >}}

- 그룹 및 프로젝트 변수 제한이 [GitLab 15.7에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/362227)되었습니다.

{{< /history >}}

프로젝트, 그룹 및 인스턴스 설정에서 정의할 수 있는 [CI/CD 변수](../ci/variables/_index.md)의 수는 모두 전체 인스턴스에 대해 제한됩니다. 새로운 변수가 생성될 때마다 이러한 제한이 확인됩니다. 새 변수로 인해 변수의 총 개수가 각각의 제한을 초과할 경우, 새 변수는 생성되지 않습니다.

GitLab Self-Managed 인스턴스에서 이러한 제한 중 하나를 업데이트하려면 `default` 계획으로 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음 명령을 실행합니다:

- [인스턴스 수준 CI/CD 변수](../ci/variables/_index.md#for-an-instance) 제한 (기본값: `25`):

  ```ruby
  Plan.default.actual_limits.update!(ci_instance_level_variables: 30)
  ```

- [그룹 수준 CI/CD 변수](../ci/variables/_index.md#for-a-group) 제한 (그룹당 기본값: `30000`):

  ```ruby
  Plan.default.actual_limits.update!(group_ci_variables: 40000)
  ```

- [프로젝트 수준 CI/CD 변수](../ci/variables/_index.md#for-a-project) 제한 (프로젝트당 기본값: `8000`):

  ```ruby
  Plan.default.actual_limits.update!(project_ci_variables: 10000)
  ```

### 아티팩트 유형별 최대 파일 크기 {#maximum-file-size-per-type-of-artifact}

{{< history >}}

- `ci_max_artifact_size_annotations` 제한이 GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/38337)되었습니다.
- `ci_max_artifact_size_jacoco` 제한이 GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159696)되었습니다.
- `ci_max_artifact_size_lsif` 제한이 GitLab 17.8에서 [증가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175684)되었습니다.

{{< /history >}}

[`artifacts:reports`](../ci/yaml/_index.md#artifactsreports)로 정의된 작업 아티팩트는 러너에 의해 업로드되며, 파일 크기가 최대 파일 크기 제한을 초과하면 거부됩니다. 제한은 프로젝트의 [최대 아티팩트 크기 설정](settings/continuous_integration.md#set-maximum-artifacts-size)과 지정된 아티팩트 유형의 인스턴스 제한을 비교하여 더 작은 값을 선택하여 결정됩니다.

제한은 메가바이트 단위로 설정되므로, 정의할 수 있는 가장 작은 값은 `1 MB`입니다.

각 아티팩트 유형에는 설정할 수 있는 크기 제한이 있습니다. `0`의 기본값은 해당 특정 아티팩트 유형에 대한 제한이 없음을 의미하며, 프로젝트의 최대 아티팩트 크기 설정이 사용됩니다:

| 아티팩트 제한 이름                         | 기본값 |
|---------------------------------------------|---------------|
| `ci_max_artifact_size_accessibility`        | 0             |
| `ci_max_artifact_size_annotations`          | 0             |
| `ci_max_artifact_size_api_fuzzing`          | 0             |
| `ci_max_artifact_size_archive`              | 0             |
| `ci_max_artifact_size_browser_performance`  | 0             |
| `ci_max_artifact_size_cluster_applications` | 0             |
| `ci_max_artifact_size_cobertura`            | 0             |
| `ci_max_artifact_size_codequality`          | 0             |
| `ci_max_artifact_size_container_scanning`   | 0             |
| `ci_max_artifact_size_coverage_fuzzing`     | 0             |
| `ci_max_artifact_size_dast`                 | 0             |
| `ci_max_artifact_size_dependency_scanning`  | 0             |
| `ci_max_artifact_size_dotenv`               | 0             |
| `ci_max_artifact_size_jacoco`               | 0             |
| `ci_max_artifact_size_junit`                | 0             |
| `ci_max_artifact_size_license_management`   | 0             |
| `ci_max_artifact_size_license_scanning`     | 0             |
| `ci_max_artifact_size_load_performance`     | 0             |
| `ci_max_artifact_size_lsif`                 | 200 MB        |
| `ci_max_artifact_size_metadata`             | 0             |
| `ci_max_artifact_size_metrics_referee`      | 0             |
| `ci_max_artifact_size_metrics`              | 0             |
| `ci_max_artifact_size_network_referee`      | 0             |
| `ci_max_artifact_size_performance`          | 0             |
| `ci_max_artifact_size_requirements`         | 0             |
| `ci_max_artifact_size_requirements_v2`      | 0             |
| `ci_max_artifact_size_sast`                 | 0             |
| `ci_max_artifact_size_secret_detection`     | 0             |
| `ci_max_artifact_size_terraform`            | 5 MB          |
| `ci_max_artifact_size_trace`                | 0             |
| `ci_max_artifact_size_cyclonedx`            | 5 MB          |

예를 들어, GitLab Self-Managed에서 `ci_max_artifact_size_junit` 제한을 10 MB로 설정하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
Plan.default.actual_limits.update!(ci_max_artifact_size_junit: 10)
```

### GitLab Pages 웹사이트당 파일 수 {#number-of-files-per-gitlab-pages-website}

파일 항목(디렉터리 및 심볼릭 링크 포함)의 총 개수는 GitLab Pages 웹사이트당 `200,000`로 제한됩니다.

이는 [GitLab Self-Managed 및 GitLab.com](https://about.gitlab.com/pricing/)의 기본 제한입니다.

GitLab Self-Managed 인스턴스에서 제한을 업데이트하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)을 사용합니다. 예를 들어, 제한을 `100`로 변경하려면:

```ruby
Plan.default.actual_limits.update!(pages_file_entries: 100)
```

### GitLab Pages 웹사이트당 사용자 정의 도메인 수 {#number-of-custom-domains-per-gitlab-pages-website}

GitLab Pages 웹사이트당 사용자 정의 도메인의 총 개수는 [GitLab.com](../subscriptions/manage_seats.md#gitlabcom-billing-and-usage)의 경우 `150`로 제한됩니다.

[GitLab 자체 관리](../subscriptions/manage_subscription.md)에 대한 기본 제한은 `0`(무제한)입니다. 인스턴스에 대한 제한을 설정하려면 [**운영자** 영역](pages/_index.md#set-maximum-number-of-gitlab-pages-custom-domains-for-a-project)을 사용합니다.

### 병렬 Pages 배포 수 {#number-of-parallel-pages-deployments}

[병렬 Pages 배포](../user/project/pages/parallel_deployments.md)를 사용할 때, 최상위 네임스페이스에 대해 허용되는 병렬 Pages 배포의 총 개수는 1000입니다.

프로젝트에 [고유 도메인](../user/project/pages/_index.md#unique-domains)이 활성화되어 있을 경우, 프로젝트의 고유 도메인은 자체 최상위 네임스페이스로 취급되며 1000개의 배포 제한이 별도로 적용됩니다.

### 각 범위별 등록된 러너 수 {#number-of-registered-runners-for-each-scope}

{{< history >}}

- 러너 부실 타임아웃이 GitLab 17.1에서 3개월에서 7일로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155795)되었습니다.

{{< /history >}}

등록된 러너의 총 개수는 그룹 및 프로젝트에 대해 제한됩니다. 새로운 러너가 등록될 때마다 GitLab은 최근 7일 동안 생성되거나 활성화된 러너에 대해 이러한 제한을 확인합니다. 러너 등록은 러너 등록 토큰으로 결정되는 범위의 제한을 초과하면 실패합니다. 제한값이 0으로 설정된 경우 제한이 비활성화됩니다.

GitLab.com 구독자는 구독별로 정의된 다양한 제한이 있으며, 이는 해당 구독을 사용하는 모든 프로젝트에 영향을 미칩니다.

GitLab Self-Managed의 Premium 및 Ultimate 제한은 모든 프로젝트에 영향을 미치는 기본 계획으로 정의됩니다:

| 러너 범위                    | 기본값 |
|---------------------------------|---------------|
| `ci_registered_group_runners`   | 1000          |
| `ci_registered_project_runners` | 1000          |

이러한 제한을 업데이트하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
# Use ci_registered_group_runners or ci_registered_project_runners
# depending on desired scope
Plan.default.actual_limits.update!(ci_registered_project_runners: 100)
```

### 작업 로그의 최대 파일 크기 {#maximum-file-size-for-job-logs}

GitLab의 작업 로그 파일 크기 제한은 기본적으로 100메가바이트입니다. 제한을 초과하는 모든 작업은 실패로 표시되며 러너에 의해 삭제됩니다.

[GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 제한을 변경할 수 있습니다. `ci_jobs_trace_size_limit`를 메가바이트 단위의 새 값으로 업데이트합니다:

```ruby
Plan.default.actual_limits.update!(ci_jobs_trace_size_limit: 125)
```

GitLab 러너는 [`output_limit` 설정](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section)도 있어서 러너의 최대 로그 크기를 구성합니다. 러너 제한을 초과하는 작업은 계속 실행되지만, 제한에 도달하면 로그가 잘립니다.

### 프로젝트당 활성 DAST 프로필 일정의 최대 수 {#maximum-number-of-active-dast-profile-schedules-per-project}

프로젝트당 활성 DAST 프로필 일정의 수를 제한합니다. DAST 프로필 일정은 활성 또는 비활성일 수 있습니다.

[GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 제한을 변경할 수 있습니다. `dast_profile_schedules`를 새 값으로 업데이트합니다:

```ruby
Plan.default.actual_limits.update!(dast_profile_schedules: 50)
```

### CI 아티팩트 아카이브의 최대 크기 {#maximum-size-of-the-ci-artifacts-archive}

이 설정은 [동적 자식 파이프라인](../ci/pipelines/downstream_pipelines.md#dynamic-child-pipelines)에 대한 YAML 크기를 제한하는 데 사용됩니다.

CI 아티팩트 아카이브의 기본 최대 크기는 5메가바이트입니다.

[GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)을 사용하여 이 제한을 변경할 수 있습니다. CI 아티팩트 아카이브의 최대 크기를 업데이트하려면 `max_artifacts_content_include_size`를 새 값으로 업데이트합니다. 예를 들어, 20 MB로 설정하려면:

```ruby
ApplicationSetting.update(max_artifacts_content_include_size: 20.megabytes)
```

### CI/CD 구성 YAML 파일의 최대 크기 및 깊이 {#maximum-size-and-depth-of-cicd-configuration-yaml-files}

{{< history >}}

- `max_yaml_size_bytes`에 대한 기본값이 GitLab 17.3에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826)되었습니다.

{{< /history >}}

단일 CI/CD 구성 YAML 파일의 기본 최대 크기는 2메가바이트이고 기본 깊이는 100입니다.

이 제한을 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 변경할 수 있습니다:

- 최대 YAML 크기를 업데이트하려면 `max_yaml_size_bytes`을 메가바이트 단위의 새 값으로 업데이트합니다:

  ```ruby
  ApplicationSetting.update(max_yaml_size_bytes: 4.megabytes)
  ```

  `max_yaml_size_bytes` 값은 YAML 파일의 크기와 직접 연결되지 않고 관련 객체에 할당되는 메모리와 연결됩니다.

- 최대 YAML 깊이를 업데이트하려면 `max_yaml_depth`을 줄 수의 새 값으로 업데이트합니다:

  ```ruby
  ApplicationSetting.update(max_yaml_depth: 125)
  ```

### 전체 CI/CD 구성의 최대 크기 {#maximum-size-of-the-entire-cicd-configuration}

{{< history >}}

- `max_yaml_size_bytes`에 대한 기본값이 GitLab 17.3에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826)되었습니다.
- `ci_max_total_yaml_size_bytes`에 대한 기본값이 GitLab 17.3에서 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826)되었습니다.

{{< /history >}}

포함된 모든 YAML 구성 파일과 함께 전체 파이프라인 구성에 할당될 수 있는 최대 메모리 양(바이트)입니다.

기본값은 [`max_yaml_size_bytes`](#maximum-size-and-depth-of-cicd-configuration-yaml-files) (기본값 2 MB)에 [`ci_max_includes`](../api/settings.md#available-settings)(기본값 150)을 곱하여 계산됩니다:

- GitLab 17.2 이상:  1 MB × 150 = `157286400` 바이트 (150 MB).
- GitLab 17.3 이상:  2 MB × 150 = `314572800` 바이트 (314.6 MB).

[GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)을 사용하여 이 제한을 변경할 수 있습니다. CI/CD 구성에 할당할 수 있는 최대 메모리를 업데이트하려면 `ci_max_total_yaml_size_bytes`를 새 값으로 업데이트합니다. 예를 들어, 20 MB로 설정하려면:

```ruby
ApplicationSetting.update(ci_max_total_yaml_size_bytes: 20.megabytes)
```

### dotenv 변수 제한 {#limit-dotenv-variables}

dotenv 아티팩트 내 변수의 최대 개수에 제한을 설정할 수 있습니다. 이 제한은 dotenv 파일이 아티팩트로 내보낼 때마다 확인됩니다.

제한을 `0`로 설정하여 비활성화합니다. GitLab 자체 관리에서 기본값 `20`.

인스턴스에서 이 제한을 `100`로 설정하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음 명령을 실행합니다:

```ruby
Plan.default.actual_limits.update!(dotenv_variables: 100)
```

[GitLab UI](settings/continuous_integration.md#set-cicd-limits) 또는 [계획 제한 API](../api/plan_limits.md)를 사용하여 이 제한을 설정할 수도 있습니다.

이 제한은 [GitLab.com에서 활성화](../user/gitlab_com/_index.md#cicd)됩니다.

### dotenv 파일 크기 제한 {#limit-dotenv-file-size}

dotenv 아티팩트의 최대 크기에 제한을 설정할 수 있습니다. 이 제한은 dotenv 파일이 아티팩트로 내보낼 때마다 확인됩니다.

제한을 `0`로 설정하여 비활성화합니다. 기본값은 5 KB입니다.

GitLab Self-Managed 인스턴스에서 이 제한을 5 KB로 설정하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
Plan.default.actual_limits.update!(dotenv_size: 5.kilobytes)
```

### CI/CD 작업 주석 제한 {#limit-cicd-job-annotations}

{{< history >}}

- GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/38337)되었습니다.

{{< /history >}}

CI/CD 작업당 [주석](../ci/yaml/artifacts_reports.md#artifactsreportsannotations)의 최대 개수에 제한을 설정할 수 있습니다.

제한을 `0`로 설정하여 비활성화합니다. GitLab 자체 관리에서 기본값 `20`.

인스턴스에서 이 제한을 `100`로 설정하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음 명령을 실행합니다:

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_num: 100)
```

### CI/CD 작업 주석 파일 크기 제한 {#limit-cicd-job-annotations-file-size}

{{< history >}}

- GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/38337)되었습니다.

{{< /history >}}

CI/CD 작업 [주석](../ci/yaml/artifacts_reports.md#artifactsreportsannotations)의 최대 크기에 제한을 설정할 수 있습니다.

제한을 `0`로 설정하여 비활성화합니다. 기본값은 80 KB입니다.

GitLab Self-Managed 인스턴스에서 이 제한을 100 KB로 설정하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_size: 100.kilobytes)
```

### CI/CD 테이블의 최대 데이터베이스 파티션 크기 {#maximum-database-partition-size-for-cicd-tables}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189131)되었습니다.
- GitLab 18.11에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/577314)되었습니다.

{{< /history >}}

파티션된 테이블의 파티션이 사용할 수 있는 최대 디스크 공간 양(바이트)으로, 새 파티션이 자동으로 생성되기 전입니다. 기본값은 100 GB입니다.

[GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)을 사용하여 이 제한을 변경할 수 있습니다. 제한을 변경하려면 `ci_partitions_size_limit`를 새 값으로 업데이트합니다. 예를 들어, 20 GB로 설정하려면:

```ruby
ApplicationSetting.update(ci_partitions_size_limit: 20.gigabytes)
```

### CI/CD 파티션의 최대 시간 창 {#maximum-time-window-for-cicd-partitions}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/577314)되었습니다.

{{< /history >}}

새로운 CI 파티션이 생성되고 시스템이 다음 파티션 세트로 전환되기 전의 시간 창(초)입니다. 1개월에서 6개월 사이여야 합니다. 기본값은 1개월(2592000초)입니다.

[GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)을 사용하여 이 제한을 변경할 수 있습니다. 제한을 변경하려면 `ci_partitions_in_seconds_limit`를 새 값으로 업데이트합니다. 예를 들어, 3개월로 설정하려면:

```ruby
ApplicationSetting.update(ci_partitions_in_seconds_limit: ChronicDuration.parse('3 months'))
```

### 자동 파이프라인 정리를 위한 최대 구성값 {#maximum-config-value-for-automatic-pipeline-cleanup}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189191)되었습니다.

{{< /history >}}

[자동 파이프라인 정리](../ci/pipelines/settings.md#automatic-pipeline-cleanup)에 대한 상한을 구성합니다. 기본값은 1년입니다.

[GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)을 사용하여 이 제한을 변경할 수 있습니다. 제한을 변경하려면 `ci_delete_pipelines_in_seconds_limit_human_readable`를 새 값으로 업데이트합니다. 예를 들어, 3년으로 설정하려면:

```ruby
ApplicationSetting.update(ci_delete_pipelines_in_seconds_limit_human_readable: '3 years')
```

## 인스턴스 모니터링 및 메트릭 {#instance-monitoring-and-metrics}

### 인바운드 사건 관리 알림 제한 {#limit-inbound-incident-management-alerts}

이 설정은 일정 기간 동안 인바운드 알림 페이로드의 수를 제한합니다.

[사건 관리 속도 제한](settings/rate_limit_on_pipelines_creation.md)에 대해 자세히 알아봅니다.

### Prometheus 알림 JSON 페이로드 {#prometheus-alert-json-payloads}

`notify.json` 엔드포인트로 전송된 Prometheus 알림 페이로드는 1 MB 크기로 제한됩니다.

### 일반 알림 JSON 페이로드 {#generic-alert-json-payloads}

`notify.json` 엔드포인트로 전송된 알림 페이로드는 1 MB 크기로 제한됩니다.

## 환경 대시보드 제한 {#environment-dashboard-limits}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

표시되는 프로젝트의 최대 개수는 [환경 대시보드](../ci/environments/environments_dashboard.md#adding-a-project-to-the-dashboard)를 참조하세요.

## 배포 보드의 환경 데이터 {#environment-data-on-deploy-boards}

[배포 보드](../user/project/deploy_boards.md)는 Kubernetes에서 Pod 및 배포에 대한 정보를 로드합니다. 그러나 Kubernetes에서 읽은 특정 환경에 대한 10 MB를 초과하는 데이터는 표시되지 않습니다.

## 머지 리퀘스트 {#merge-requests}

### Diff 제한 {#diff-limits}

GitLab은 다음과 같은 제한이 있습니다:

- 단일 파일의 패치 크기입니다. [이는 GitLab Self-Managed에서 구성할 수 있습니다](diff_limits.md).
- 머지 리퀘스트의 모든 diff의 총 크기입니다.

상한과 하한이 각각에 적용됩니다:

- 변경된 파일의 수입니다.
- 변경된 줄의 수입니다.
- 표시된 변경 사항의 누적 크기입니다.

하한으로 인해 추가 diff가 축소됩니다. 상한으로 인해 더 이상의 변경 사항이 렌더링되지 않습니다. 이러한 제한에 대한 자세한 내용은 diff 작업에 관한 GitLab 개발 문서를 참조하세요.

### Diff 버전 제한 {#diff-version-limit}

{{< history >}}

- [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/521970) 되었으며 GitLab 17.10에서 [플래그 포함](feature_flags/_index.md) `merge_requests_diffs_limit`. 기본적으로 비활성화됨.
- GitLab 17.10에서 [GitLab.com에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/521970)되었습니다.
- GitLab 19.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/537447)합니다. 기능 플래그 `merge_requests_diffs_limit` 제거됨.

{{< /history >}}

GitLab은 각 머지 리퀘스트를 1000 [diff 버전](../user/project/merge_requests/versions.md)으로 제한합니다. 이 제한에 도달한 머지 리퀘스트는 더 이상 업데이트할 수 없습니다. 대신, 영향을 받는 머지 리퀘스트를 닫고 새 머지 리퀘스트를 만드세요.

이 제한을 구성하려면 [diff 제한 관리](diff_limits.md)를 참조하세요.

### 머지 리퀘스트 보고서 크기 제한 {#merge-request-reports-size-limit}

20 MB 제한을 초과하는 보고서는 로드되지 않습니다. 영향을 받는 보고서:

- [머지 리퀘스트 보안 보고서](../ci/testing/_index.md#security-reports)
- [CI/CD 매개변수 `artifacts:expose_as`](../ci/yaml/_index.md#artifactsexpose_as)
- [단위 테스트 보고서](../ci/testing/unit_test_reports.md)

## 고급 검색 제한 {#advanced-search-limits}

### 최대 파일 크기 인덱싱됨 {#maximum-file-size-indexed}

Elasticsearch에서 인덱싱되는 리포지토리 파일의 콘텐츠에 대한 제한을 설정할 수 있습니다. 이 제한보다 큰 파일은 파일 이름만 인덱싱합니다. 파일 콘텐츠는 인덱싱되지 않으며 검색할 수 없습니다.

제한을 설정하면 인덱싱 프로세스의 메모리 사용량과 전체 인덱스 크기를 줄일 수 있습니다. 이 값의 기본값은 `1024 KiB`(1 MiB)이며, 이보다 큰 텍스트 파일은 사람이 읽으려고 하지 않을 가능성이 높습니다.

무제한 파일 크기는 지원되지 않으므로 제한을 설정해야 합니다. 이 값을 GitLab Sidekiq 노드의 메모리 양보다 크게 설정하면 인덱싱 중에 이 양의 메모리가 미리 할당되므로 GitLab Sidekiq 노드의 메모리가 부족하게 됩니다.

### 최대 필드 길이 {#maximum-field-length}

고급 검색을 위해 인덱싱된 텍스트 필드의 콘텐츠에 대한 제한을 설정할 수 있습니다. 최대값을 설정하면 인덱싱 프로세스의 부하를 줄일 수 있습니다. 텍스트 필드가 이 제한을 초과하면 텍스트가 이 개수의 문자로 잘립니다. 나머지 텍스트는 인덱싱되지 않으며 검색할 수 없습니다. 이는 별도의 제한이 있는 인덱싱되는 리포지토리 파일을 제외한 모든 인덱싱된 데이터에 적용됩니다. 자세한 내용은 [최대 파일 크기 인덱싱됨](#maximum-file-size-indexed)을 참조하세요.

- GitLab.com에서는 필드 길이 제한이 20,000자입니다.
- GitLab Self-Managed 인스턴스의 경우, 필드 길이는 기본적으로 무제한입니다.

GitLab Self-Managed 인스턴스에 대해 이 제한을 구성할 수 있으며 [Elasticsearch를 활성화](../integration/advanced_search/elasticsearch.md#enable-advanced-search)할 때 구성할 수 있습니다. 제한을 `0`로 설정하여 비활성화합니다.

## 수학 렌더링 제한 {#math-rendering-limits}

{{< history >}}

- GitLab 16.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132939)되었습니다.
- Wiki 및 리포지토리 파일에서 50노드 제한이 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/368009)되었습니다.
- 수학 렌더링 제한을 비활성화하고 GitLab 16.9에서 기본적으로 wiki 및 리포지토리 파일에 대한 수학 제한을 다시 활성화하는 그룹 수준 설정이 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/368009)되었습니다.

{{< /history >}}

GitLab은 Markdown 필드에서 수학을 렌더링할 때 기본 제한을 적용합니다. 이러한 제한은 더 나은 보안 및 성능을 제공합니다.

이슈, 머지 리퀘스트, 에픽, wiki 및 리포지토리 파일에 대한 제한:

- 최대 매크로 확장 수: `1000`.
- [em](https://en.wikipedia.org/wiki/Em_(typography))의 최대 사용자 지정 크기: `20`.
- 렌더링된 노드의 최대 수: `50`.
- 수학 블록의 최대 문자 수: `1000`.
- 최대 렌더링 시간: `2000 ms`.

GitLab Self-Managed를 실행하고 사용자 입력을 신뢰할 때 이 제한을 비활성화할 수 있습니다.

[GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)을 사용합니다:

```ruby
ApplicationSetting.update(math_rendering_limits_enabled: false)
```

이러한 제한은 GraphQL 또는 REST API를 사용하여 그룹별로 비활성화할 수도 있습니다.

제한이 비활성화되면 수학은 이슈, 머지 리퀘스트, 에픽, wiki 및 리포지토리 파일에서 거의 무제한으로 렌더링됩니다. 이는 악의적인 행위자가 브라우저에서 보는 때 DoS를 일으킬 수 있는 수학을 추가할 수 있음을 의미합니다. 신뢰할 수 있는 사람만 콘텐츠를 추가할 수 있는지 확인해야 합니다.

## Wiki 제한 {#wiki-limits}

- [Wiki 페이지 콘텐츠 크기 제한](wikis/_index.md#wiki-page-content-size-limit).
- [파일 및 디렉터리 이름에 대한 길이 제한](../user/project/wiki/_index.md#length-restrictions-for-file-and-directory-names).

## 스니펫 제한 {#snippets-limits}

[스니펫 설정에 대한 문서](snippets/_index.md)를 참조하세요.

## 디자인 관리 제한 {#design-management-limits}

[이슈에 디자인 추가](../user/project/issues/design_management.md#add-a-design-to-an-issue) 섹션에서 제한을 참조하세요.

## 푸시 이벤트 제한 {#push-event-limits}

### 최대 푸시 크기 {#max-push-size}

최대 허용 [푸시 크기](settings/account_and_limit_settings.md#max-push-size)입니다.

GitLab Self-Managed에서는 기본적으로 설정되지 않습니다. GitLab.com의 경우 [계정 및 제한 설정](../user/gitlab_com/_index.md#account-and-limit-settings)을 참조하세요.

### 웹후크 및 프로젝트 서비스 {#webhooks-and-project-services}

단일 푸시에서 변경 사항(브랜치 또는 태그)의 총 개수입니다. 변경 사항이 지정된 제한보다 많으면 후크가 실행되지 않습니다.

자세한 정보는 다음을 참조하세요:

- [웹후크 푸시 이벤트](../user/project/integrations/webhook_events.md#push-events)
- [프로젝트 통합의 푸시 후크 제한](../user/project/integrations/_index.md#push-hook-limit)

### 활동 {#activities}

단일 푸시에서 개별 푸시 이벤트 또는 대량 푸시 이벤트를 생성할지 여부를 결정하기 위한 변경 사항(브랜치 또는 태그)의 총 개수입니다.

자세한 내용은 [푸시 이벤트 활동 제한 및 대량 푸시 이벤트 문서](settings/push_event_activities_limit.md)에서 찾을 수 있습니다.

## 패키지 레지스트리 제한 {#package-registry-limits}

### 파일 크기 제한 {#file-size-limits}

[GitLab 패키지 레지스트리](../user/packages/package_registry/_index.md)로 업로드되는 패키지의 기본 최대 파일 크기는 형식에 따라 다릅니다:

- Conan:  3 GB
- 일반:  5 GB
- Helm:  5 MB
- Maven:  3 GB
- npm:  500 MB
- NuGet:  500 MB
- PyPI:  3 GB
- Terraform:  1 GB

[GitLab.com의 최대 파일 크기](../user/gitlab_com/_index.md#package-registry-limits)는 다를 수 있습니다.

GitLab Self-Managed 인스턴스에 대해 이 제한을 설정하려면 [**운영자** 영역을 통해](settings/continuous_integration.md#set-package-file-size-limits) 수행하거나 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
# File size limit is stored in bytes

# For Conan Packages
Plan.default.actual_limits.update!(conan_max_file_size: 100.megabytes)

# For npm Packages
Plan.default.actual_limits.update!(npm_max_file_size: 100.megabytes)

# For NuGet Packages
Plan.default.actual_limits.update!(nuget_max_file_size: 100.megabytes)

# For Maven Packages
Plan.default.actual_limits.update!(maven_max_file_size: 100.megabytes)

# For PyPI Packages
Plan.default.actual_limits.update!(pypi_max_file_size: 100.megabytes)

# For Debian Packages
Plan.default.actual_limits.update!(debian_max_file_size: 100.megabytes)

# For Helm Charts
Plan.default.actual_limits.update!(helm_max_file_size: 100.megabytes)

# For Generic Packages
Plan.default.actual_limits.update!(generic_packages_max_file_size: 100.megabytes)
```

제한을 `0`로 설정하여 모든 파일 크기를 허용합니다.

### 반환된 패키지 버전 {#package-versions-returned}

지정된 NuGet 패키지 이름의 버전을 요청할 때, GitLab 패키지 레지스트리는 최대 300개의 버전을 반환합니다.

## 종속성 프록시 제한 {#dependency-proxy-limits}

[종속성 프록시](../user/packages/dependency_proxy/_index.md)에 캐시된 이미지의 최대 파일 크기는 파일 유형에 따라 다릅니다:

- 이미지 블롭:  5 GB
- 이미지 매니페스트:  10MB

## 할당자 및 검토자의 최대 개수 {#maximum-number-of-assignees-and-reviewers}

{{< history >}}

- 최대 할당자는 GitLab 15.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/368936)되었습니다.
- 최대 검토자는 GitLab 15.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/366485)되었습니다.

{{< /history >}}

이슈 및 머지 리퀘스트는 다음 최대값을 적용합니다:

- 최대 할당자:  200
- 최대 검토자:  200

## 프로젝트 푸시 미러의 최대 개수 {#maximum-number-of-project-push-mirrors}

{{< history >}}

- GitLab 18.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221965)되었습니다.

{{< /history >}}

각 프로젝트는 최대 10개의 활성화된 푸시 미러를 가질 수 있습니다. 이 제한은 과도한 동시 동기화 작업으로 인한 성능 문제를 방지합니다.

더 많은 미러가 필요한 경우 다음을 수행할 수 있습니다:

- 사용되지 않는 미러를 비활성화합니다.
- 여러 대상을 단일 미러로 결합하여 미러를 통합합니다.

## GitLab.com의 CDN 기반 제한 {#cdn-based-limits-on-gitlabcom}

애플리케이션 기반 제한 외에도 GitLab.com은 Cloudflare의 표준 DDoS 보호 및 SSH를 통한 Git을 보호하기 위해 Spectrum을 사용하도록 구성되어 있습니다. Cloudflare는 클라이언트 TLS 연결을 종료하지만 애플리케이션 인식이 아니며 사용자 또는 그룹에 연결된 제한에 사용할 수 없습니다. Cloudflare 페이지 규칙 및 속도 제한은 Terraform으로 구성됩니다. 이러한 구성은 악의적인 활동을 감지하는 보안 및 악용 구현을 포함하고 있으며 공개하면 해당 작업을 저해하게 되므로 공개되지 않습니다.

## 컨테이너 리포지토리 태그 삭제 제한 {#container-repository-tag-deletion-limit}

컨테이너 리포지토리 태그는 컨테이너 레지스트리에 있으므로 각 태그 삭제는 컨테이너 레지스트리에 대한 네트워크 요청을 트리거합니다. 이 때문에 단일 API 호출이 삭제할 수 있는 태그 수를 20으로 제한합니다.

## 프로젝트 수준 보안 파일 API 제한 {#project-level-secure-files-api-limits}

[보안 파일 API](../api/secure_files.md)는 다음 제한을 적용합니다:

- 파일은 5 MB보다 작아야 합니다.
- 프로젝트는 100개 이상의 보안 파일을 가질 수 없습니다.

## 변경 로그 API 제한 {#changelog-api-limits}

{{< history >}}

- GitLab 15.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89032) 되었으며 [플래그](feature_flags/_index.md)는 `changelog_commits_limitation`입니다. 기본적으로 비활성화됨.
- GitLab 15.3에서 [GitLab.com 및 GitLab Self-Managed에서 기본적으로 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/33893)되었습니다.
- GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/364101)합니다. 기능 플래그 `changelog_commits_limitation` 제거됨.

{{< /history >}}

[변경 로그 API](../api/repositories.md#add-changelog-data-to-file)는 다음 제한을 적용합니다:

- `from`과 `to` 사이의 커밋 범위는 15000 커밋을 초과할 수 없습니다.

## 가치 흐름 분석 제한 {#value-stream-analytics-limits}

- 각 네임스페이스(예: 그룹 또는 프로젝트)는 최대 50개의 가치 흐름을 가질 수 있습니다.
- 각 가치 흐름은 최대 15개의 단계를 가질 수 있습니다.

## 감사 이벤트 스트리밍 대상 제한 {#audit-events-streaming-destination-limits}

### 사용자 정의 HTTP 엔드포인트 {#custom-http-endpoint}

- 각 최상위 그룹은 최대 5개의 사용자 정의 HTTP 스트리밍 대상을 가질 수 있습니다.

### Google Cloud Logging {#google-cloud-logging}

- 각 최상위 그룹은 최대 5개의 Google Cloud Logging 스트리밍 대상을 가질 수 있습니다.

### Amazon S3 {#amazon-s3}

- 각 최상위 그룹은 최대 5개의 Amazon S3 스트리밍 대상을 가질 수 있습니다.

## SBOM을 사용한 종속성 검사 제한 {#dependency-scanning-using-sbom-limits}

[SBOM을 사용한 종속성 검사 기능](../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md)은 다음 제한이 있는 내부 API를 사용합니다:

- 프로젝트당 시간당 최대 업로드 요청 수:  400
- 프로젝트당 시간당 최대 다운로드 요청 수:  6000

GitLab Self-Managed 인스턴스에 대해 [종속성 검사 설정](settings/security_and_compliance.md#sbom-scan-api-limits)을 사용하여 이러한 제한을 구성할 수 있습니다.

## 커밋 및 파일 API 제한 {#commits-and-files-api-limits}

{{< history >}}

- GitLab 18.7에서 도입되었습니다.

{{< /history >}}

커밋 및 파일 API는 다음 엔드포인트에 최대 크기 및 속도 제한을 적용합니다:

- `POST /projects/:id/repository/commits` - [커밋 생성](../api/commits.md#create-a-commit)
- `POST /projects/:id/repository/files/:file_path` - [리포지토리에 파일 생성](../api/repository_files.md#create-a-file-in-a-repository)
- `PUT /projects/:id/repository/files/:file_path` - [리포지토리에서 파일 업데이트](../api/repository_files.md#update-a-file-in-a-repository)
- **Maximum request size**:  이 제한을 초과하는 요청은 `413 Request Entity Too Large` 오류를 수신하며 다음 메시지가 표시됩니다: `RequestBody: upload failed: the upload size <size> is over maximum of 314572800 bytes: entity is too large`. 기본값은 300 MB (314,572,800 바이트)입니다.
- **속도 제한**:  20 MB 이상의 요청에 대해 30초당 3개 요청입니다.

최대 요청 크기는 `GITLAB_COMMITS_MAX_REQUEST_SIZE_BYTES` 환경 변수를 설정하여 GitLab Self-Managed에서 구성할 수 있습니다. 이 변수는 최대 요청 크기를 바이트 단위로 설정합니다. 환경 변수를 설정하는 방법에 대한 지침은 [HTTP 요청 제한](#http-request-limits)에서 찾을 수 있습니다.

## 모든 인스턴스 제한 나열 {#list-all-instance-limits}

모든 인스턴스 제한값을 나열하려면 [GitLab Rails 콘솔](operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행합니다:

```ruby
Plan.default.actual_limits
```

샘플 출력:

```ruby
id: 1,
plan_id: 1,
ci_pipeline_size: 0,
ci_active_jobs: 0,
project_hooks: 100,
group_hooks: 50,
ci_project_subscriptions: 3,
ci_pipeline_schedules: 10,
offset_pagination_limit: 50000,
ci_instance_level_variables: "[FILTERED]",
storage_size_limit: 0,
ci_max_artifact_size_lsif: 200,
ci_max_artifact_size_archive: 0,
ci_max_artifact_size_metadata: 0,
ci_max_artifact_size_trace: "[FILTERED]",
ci_max_artifact_size_junit: 0,
ci_max_artifact_size_sast: 0,
ci_max_artifact_size_dependency_scanning: 350,
ci_max_artifact_size_container_scanning: 150,
ci_max_artifact_size_dast: 0,
ci_max_artifact_size_codequality: 0,
ci_max_artifact_size_license_management: 0,
ci_max_artifact_size_license_scanning: 100,
ci_max_artifact_size_performance: 0,
ci_max_artifact_size_metrics: 0,
ci_max_artifact_size_metrics_referee: 0,
ci_max_artifact_size_network_referee: 0,
ci_max_artifact_size_dotenv: 0,
ci_max_artifact_size_cobertura: 0,
ci_max_artifact_size_terraform: 5,
ci_max_artifact_size_accessibility: 0,
ci_max_artifact_size_cluster_applications: 0,
ci_max_artifact_size_secret_detection: "[FILTERED]",
ci_max_artifact_size_requirements: 0,
ci_max_artifact_size_coverage_fuzzing: 0,
ci_max_artifact_size_browser_performance: 0,
ci_max_artifact_size_load_performance: 0,
ci_needs_size_limit: 2,
conan_max_file_size: 3221225472,
maven_max_file_size: 3221225472,
npm_max_file_size: 524288000,
nuget_max_file_size: 524288000,
pypi_max_file_size: 3221225472,
generic_packages_max_file_size: 5368709120,
golang_max_file_size: 104857600,
debian_max_file_size: 3221225472,
project_feature_flags: 200,
ci_max_artifact_size_api_fuzzing: 0,
ci_pipeline_deployments: 500,
pull_mirror_interval_seconds: 300,
daily_invites: 0,
rubygems_max_file_size: 3221225472,
terraform_module_max_file_size: 1073741824,
helm_max_file_size: 5242880,
ci_registered_group_runners: 1000,
ci_registered_project_runners: 1000,
ci_daily_pipeline_schedule_triggers: 0,
ci_max_artifact_size_cluster_image_scanning: 0,
ci_jobs_trace_size_limit: "[FILTERED]",
pages_file_entries: 200000,
dast_profile_schedules: 1,
external_audit_event_destinations: 5,
dotenv_variables: "[FILTERED]",
dotenv_size: 5120,
pipeline_triggers: 25000,
project_ci_secure_files: 100,
repository_size: 0,
security_policy_scan_execution_schedules: 0,
web_hook_calls_mid: 0,
web_hook_calls_low: 0,
project_ci_variables: "[FILTERED]",
group_ci_variables: "[FILTERED]",
ci_max_artifact_size_cyclonedx: 1,
rpm_max_file_size: 5368709120,
pipeline_hierarchy_size: 1000,
ci_max_artifact_size_requirements_v2: 0,
enforcement_limit: 0,
notification_limit: 0,
dashboard_limit_enabled_at: nil,
web_hook_calls: 0,
project_access_token_limit: 0,
google_cloud_logging_configurations: 5,
ml_model_max_file_size: 10737418240,
limits_history: {},
audit_events_amazon_s3_configurations: 5
```

일부 제한값은 [Rails 콘솔 필터링](operations/rails_console.md#filtered-console-output)으로 인해 목록에서 `[FILTERED]`로 표시됩니다.
