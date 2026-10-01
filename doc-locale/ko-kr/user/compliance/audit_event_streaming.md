---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 최상위 그룹을 위한 감사 이벤트 스트리밍
---

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [하위 그룹 이벤트 기록](https://gitlab.com/gitlab-org/gitlab/-/issues/366878)이 GitLab 15.2에서 수정되었습니다.
- 사용자 정의 HTTP 헤더 UI가 GitLab 15.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/361630)되었으며 [플래그](../../administration/feature_flags/list.md) `custom_headers_streaming_audit_events_ui`를 사용합니다. 기본적으로 비활성화되어 있습니다.
- 사용자 정의 HTTP 헤더 UI가 GitLab 15.3에서 [일반적으로 제공](https://gitlab.com/gitlab-org/gitlab/-/issues/365259)됩니다. [기능 플래그 `custom_headers_streaming_audit_events_ui`](https://gitlab.com/gitlab-org/gitlab/-/issues/365259)가 제거되었습니다.
- [사용자 환경 개선](https://gitlab.com/gitlab-org/gitlab/-/issues/367963)이 GitLab 15.3에서 이루어졌습니다.
- HTTP 대상 **이름** 필드가 GitLab 16.3에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/411357)되었습니다.
- **활성** 확인란의 기능이 GitLab 16.5에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/415268)되었습니다.

{{< /history >}}

최상위 그룹에 대한 감사 이벤트 스트리밍을 통해 그룹 소유자는 다음을 수행할 수 있습니다:

- 최상위 그룹에 대한 스트리밍 대상을 설정하여 그룹, 하위 그룹 및 프로젝트에 대한 모든 감사 이벤트를 구조화된 JSON으로 수신합니다.
- 타사 시스템에서 감사 로그를 관리합니다. 구조화된 JSON 데이터를 받을 수 있는 모든 서비스를 스트리밍 대상으로 사용할 수 있습니다.

각 스트리밍 대상:

- 스트리밍된 각 이벤트에 최대 20개의 사용자 정의 HTTP 헤더를 포함할 수 있습니다.
- GitLab.com의 경우 [GitLab.com IP 주소 범위](../gitlab_com/_index.md#ip-range)의 트래픽을 허용해야 합니다.

GitLab은 동일한 대상에 단일 이벤트를 여러 번 스트리밍할 수 있습니다. 페이로드의 `id` 키를 사용하여 들어오는 데이터를 중복 제거합니다.

감사 이벤트는 HTTP에서 지원하는 POST 요청 방법 프로토콜을 사용하여 전송됩니다.

> [!warning]
> 스트리밍 대상은 모든 감사 이벤트 데이터를 수신하므로 민감한 정보가 포함될 수 있습니다. 스트리밍 대상을 신뢰하는지 확인하세요.

## HTTP 대상 {#http-destinations}

전제 조건:

- 보안 강화를 위해 대상 URL에서 SSL 인증서를 사용해야 합니다.

최상위 그룹의 HTTP 스트리밍 대상을 관리합니다.

### 새 HTTP 대상 추가 {#add-a-new-http-destination}

최상위 그룹에 새 HTTP 스트리밍 대상을 추가합니다.

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

최상위 그룹에 스트리밍 대상을 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. **스트리밍 대상 추가**를 선택하고 **HTTP endpoint**를 선택하여 대상 추가 섹션을 표시합니다.
1. **이름** 및 **대상 URL** 필드에서 대상 이름과 URL을 추가합니다.
1. 선택 사항. **Custom HTTP headers** 테이블을 찾습니다.
1. 헤더를 활성화하려면 **활성** 확인란을 선택합니다. 헤더는 감사 이벤트와 함께 전송됩니다.
1. **헤더 추가**를 선택하여 새 이름과 값 쌍을 만듭니다. 필요한 만큼 이름과 값 쌍을 입력합니다. 스트리밍 대상당 최대 20개의 헤더를 추가할 수 있습니다.
1. 모든 헤더를 입력한 후 **추가**를 선택하여 새 스트리밍 대상을 추가합니다.

### HTTP 대상 업데이트 {#update-an-http-destination}

전제 조건:

- 그룹의 소유자 역할입니다.

스트리밍 대상의 이름을 업데이트하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. 스트림을 선택하여 확장합니다.
1. **이름** 필드에서 업데이트할 대상 이름을 추가합니다.
1. **저장**을 선택하여 스트리밍 대상을 업데이트합니다.

스트리밍 대상의 사용자 정의 HTTP 헤더를 업데이트하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. 스트림을 선택하여 확장합니다.
1. **Custom HTTP headers** 테이블을 찾습니다.
1. 업데이트할 헤더를 찾습니다.
1. 헤더를 활성화하려면 **활성** 확인란을 선택합니다. 헤더는 감사 이벤트와 함께 전송됩니다.
1. **헤더 추가**를 선택하여 새 이름과 값 쌍을 만듭니다. 필요한 만큼 이름과 값 쌍을 입력합니다. 스트리밍 대상당 최대 20개의 헤더를 추가할 수 있습니다.
1. **저장**을 선택하여 스트리밍 대상을 업데이트합니다.

### 이벤트 진정성 확인 {#verify-event-authenticity}

{{< history >}}

- GitLab 15.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/360814)되었습니다.

{{< /history >}}

각 스트리밍 대상에는 이벤트의 진정성을 확인하는 데 사용할 수 있는 고유한 인증 토큰(`verificationToken`)이 있습니다. 이 토큰은 소유자가 지정하거나 이벤트 대상이 생성될 때 자동으로 생성되며 변경할 수 없습니다.

`verificationToken` 매개변수는 [GraphQL API](../../api/graphql/audit_event_streaming_groups.md#add-a-new-streaming-destination)를 사용하여만 설정할 수 있습니다.

각 스트리밍된 이벤트는 `X-Gitlab-Event-Streaming-Token` HTTP 헤더에 인증 토큰을 포함하며, 이는 스트리밍 대상을 나열할 때 대상의 값에 대해 확인할 수 있습니다.

전제 조건:

- 그룹의 소유자 역할입니다.

스트리밍 대상을 나열하고 인증 토큰을 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. 스트림을 선택하여 확장합니다.
1. **인증 토큰** 입력을 찾습니다.

### 이벤트 필터 업데이트 {#update-event-filters}

{{< history >}}

- UI의 이벤트 유형 필터링이 정의된 감사 이벤트 유형 목록과 함께 GitLab 16.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/413581)되었습니다.

{{< /history >}}

이 기능이 그룹에 대해 활성화되면 사용자가 대상별로 스트리밍된 감사 이벤트를 필터링할 수 있습니다. 기능이 필터 없이 활성화되면 대상은 모든 감사 이벤트를 수신합니다.

이벤트 유형 필터가 설정된 스트리밍 대상에는 **필터링됨**({{< icon name="filter" >}}) 레이블이 있습니다.

스트리밍 대상의 이벤트 필터를 업데이트하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. 스트림을 선택하여 확장합니다.
1. **감사 이벤트 유형으로 필터링** 드롭다운 목록을 찾습니다.
1. 드롭다운 목록을 선택하고 필요한 이벤트 유형을 선택하거나 선택 해제합니다.
1. **저장**을 선택하여 이벤트 필터를 업데이트합니다.

### 네임스페이스 필터 업데이트 {#update-namespace-filters}

{{< history >}}

- UI의 네임스페이스 필터링이 GitLab 16.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/390133)되었습니다.

{{< /history >}}

이 기능이 그룹에 대해 활성화되면 사용자가 대상별로 스트리밍된 감사 이벤트를 필터링할 수 있습니다. 기능이 필터 없이 활성화되면 대상은 모든 감사 이벤트를 수신합니다.

네임스페이스 필터가 설정된 스트리밍 대상에는 **필터링됨**({{< icon name="filter" >}}) 레이블이 있습니다.

스트리밍 대상의 네임스페이스 필터를 업데이트하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. 스트림을 선택하여 확장합니다.
1. **그룹 또는 프로젝트별로 필터링** 드롭다운 목록을 찾습니다.
1. 드롭다운 목록을 선택하고 필요한 네임스페이스를 선택하거나 선택 해제합니다.
1. **저장**을 선택하여 네임스페이스 필터를 업데이트합니다.

### 기본 content type 헤더 재정의 {#override-default-content-type-header}

기본적으로 스트리밍 대상은 `content-type` 헤더의 `application/x-www-form-urlencoded`를 사용합니다. 그러나 `content-type` 헤더를 다른 것으로 설정하려고 할 수 있습니다. 예를 들어, `application/json`입니다.

최상위 그룹 스트리밍 대상에 대한 `content-type` 헤더 기본값을 재정의하려면 다음 중 하나를 사용합니다:

- [GitLab UI](#update-an-http-destination)
- [GraphQL API](../../api/graphql/audit_event_streaming_groups.md#update-streaming-destinations)

## Google 클라우드 로깅 대상 {#google-cloud-logging-destinations}

{{< history >}}

- GitLab 16.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124384)되었습니다.

{{< /history >}}

최상위 그룹의 Google 클라우드 로깅 대상을 관리합니다.

### 전제 조건 {#prerequisites}

Google 클라우드 로깅 스트리밍 감사 이벤트를 설정하기 전에 다음을 수행해야 합니다:

1. Google Cloud 프로젝트에서 [Cloud Logging API](https://console.cloud.google.com/marketplace/product/google/logging.googleapis.com)를 활성화합니다.
1. 적절한 자격 증명과 권한을 가진 Google Cloud의 서비스 계정을 만듭니다. 이 계정은 감사 로그 스트리밍 인증을 구성하는 데 사용됩니다. 자세한 내용은 [Google Cloud 설명서에서 서비스 계정 생성 및 관리](https://cloud.google.com/iam/docs/service-accounts-create#creating)를 참조하세요.
1. Google Cloud에서 로깅을 활성화하기 위해 서비스 계정에 대해 **Logs Writer** 역할을 활성화합니다. 자세한 내용은 [IAM을 사용한 액세스 제어](https://cloud.google.com/logging/docs/access-control#logging.logWriter)를 참조하세요.
1. 서비스 계정에 대한 JSON 키를 만듭니다. 자세한 내용은 [서비스 계정 키 생성](https://cloud.google.com/iam/docs/keys-create-delete#creating)을 참조하세요.

### 새 Google 클라우드 로깅 대상 추가 {#add-a-new-google-cloud-logging-destination}

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

최상위 그룹에 Google 클라우드 로깅 스트리밍 대상을 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. **스트리밍 대상 추가**를 선택하고 **Google 클라우드 로깅**을 선택하여 대상 추가 섹션을 표시합니다.
1. 새 대상의 이름으로 사용할 임의의 문자열을 입력합니다.
1. 이전에 생성한 Google Cloud 서비스 계정 키에서 Google 프로젝트 ID, Google 클라이언트 이메일 및 Google 프라이빗 키를 입력하여 새 대상에 추가합니다.
1. 새 대상의 로그 ID로 사용할 임의의 문자열을 입력합니다. 나중에 이를 사용하여 Google Cloud의 로그 결과를 필터링할 수 있습니다.
1. **추가**를 선택하여 새 스트리밍 대상을 추가합니다.

### Google 클라우드 로깅 대상 업데이트 {#update-a-google-cloud-logging-destination}

{{< history >}}

- 프라이빗 키를 추가하는 버튼이 GitLab 16.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/419675)되었습니다.

{{< /history >}}

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

최상위 그룹에 Google 클라우드 로깅 스트리밍 대상을 업데이트하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. Google 클라우드 로깅 스트림을 선택하여 확장합니다.
1. 대상의 이름으로 사용할 임의의 문자열을 입력합니다.
1. 이전에 생성한 Google Cloud 서비스 계정 키에서 Google 프로젝트 ID 및 Google 클라이언트 이메일을 입력하여 대상을 업데이트합니다.
1. 대상의 로그 ID를 업데이트할 임의의 문자열을 입력합니다. 나중에 이를 사용하여 Google Cloud의 로그 결과를 필터링할 수 있습니다.
1. **새 프라이비트 키 추가**를 선택하고 Google 프라이빗 키를 입력하여 프라이빗 키를 업데이트합니다.
1. **저장**을 선택하여 스트리밍 대상을 업데이트합니다.

## AWS S3 대상 {#aws-s3-destinations}

{{< history >}}

- GitLab 16.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132603)되었으며 [플래그](../../administration/feature_flags/list.md) `allow_streaming_audit_events_to_amazon_s3`를 사용합니다. 기본적으로 활성화됩니다.
- [기능 플래그 `allow_streaming_audit_events_to_amazon_s3`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137391)가 GitLab 16.7에서 제거되었습니다.

{{< /history >}}

최상위 그룹의 AWS S3 대상을 관리합니다.

### 전제 조건 {#prerequisites-1}

AWS S3 스트리밍 감사 이벤트를 설정하기 전에 다음을 수행해야 합니다:

1. 적절한 자격 증명과 권한을 가진 AWS의 액세스 키를 만듭니다. 이 계정은 감사 로그 스트리밍 인증을 구성하는 데 사용됩니다. 자세한 내용은 [액세스 키 관리](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html?icmpid=docs_iam_console#Using_CreateAccessKey)를 참조하세요.
1. AWS S3 버킷을 만듭니다. 이 버킷은 감사 로그 스트리밍 데이터를 저장하는 데 사용됩니다. 자세한 내용은 [버킷 만들기](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html)를 참조하세요.

### 새 AWS S3 대상 추가 {#add-a-new-aws-s3-destination}

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

최상위 그룹에 AWS S3 스트리밍 대상을 추가하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. **스트리밍 대상 추가**를 선택하고 **AWS S3**를 선택하여 대상 추가 섹션을 표시합니다.
1. 새 대상의 이름으로 사용할 임의의 문자열을 입력합니다.
1. 이전에 생성한 AWS 액세스 키 및 버킷에서 **액세스 키 ID**, **비밀 액세스 키**, **버킷 이름** 및 **AWS Region**을 입력하여 새 대상에 추가합니다.
1. **추가**를 선택하여 새 스트리밍 대상을 추가합니다.

### AWS S3 대상 업데이트 {#update-an-aws-s3-destination}

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

최상위 그룹에 AWS S3 스트리밍 대상을 업데이트하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. AWS S3 스트림을 선택하여 확장합니다.
1. 대상의 이름으로 사용할 임의의 문자열을 입력합니다.
1. 대상을 업데이트하려면 이전에 생성한 AWS 액세스 키 및 버킷에서 **액세스 키 ID**, **비밀 액세스 키**, **버킷 이름** 및 **AWS Region**을 입력합니다.
1. 비밀 액세스 키를 업데이트하려면 **Add a new Secret Access Key**를 선택하고 AWS 비밀 액세스 키를 입력합니다.
1. **Save**를 선택합니다.

## 스트리밍 대상 나열 {#list-streaming-destinations}

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

최상위 그룹의 스트리밍 대상을 나열하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. 스트림을 선택하여 확장합니다.

## 스트리밍 대상 활성화 또는 비활성화 {#activate-or-deactivate-streaming-destinations}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/537096)되었습니다.

{{< /history >}}

대상 구성을 삭제하지 않고 대상으로의 감사 이벤트 스트리밍을 임시로 비활성화할 수 있습니다. 스트리밍 대상이 비활성화되면:

- 감사 이벤트가 해당 대상으로 즉시 스트리밍되지 않습니다.
- 대상 구성이 유지됩니다.
- 언제든지 대상을 다시 활성화할 수 있습니다.
- 다른 활성 대상은 계속해서 이벤트를 수신합니다.

### 스트리밍 대상 비활성화 {#deactivate-a-streaming-destination}

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

스트리밍 대상을 비활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. 스트림을 선택하여 확장합니다.
1. **활성** 확인란을 선택 해제합니다.
1. **Save**를 선택합니다.

대상이 감사 이벤트 수신을 중지합니다.

### 스트리밍 대상 활성화 {#activate-a-streaming-destination}

이전에 비활성화된 스트리밍 대상을 다시 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. 스트림을 선택하여 확장합니다.
1. **활성** 확인란을 선택합니다.
1. **Save**를 선택합니다.

대상이 즉시 감사 이벤트 수신을 재개합니다.

## 스트리밍 대상 삭제 {#delete-streaming-destinations}

최상위 그룹의 스트리밍 대상을 삭제합니다. 마지막 대상이 성공적으로 삭제되면 최상위 그룹에 대해 스트리밍이 비활성화됩니다.

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

최상위 그룹의 스트리밍 대상을 삭제하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. 스트림을 선택하여 확장합니다.
1. **대상 삭제**를 선택합니다.
1. 확인하려면 **대상 삭제**를 선택합니다.

### 사용자 정의 HTTP 헤더만 삭제 {#delete-only-custom-http-headers}

전제 조건:

- 최상위 그룹의 소유자 역할입니다.

스트리밍 대상의 사용자 정의 HTTP 헤더만 삭제하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **감사 이벤트**를 선택합니다.
1. 주 영역에서 **스트림** 탭을 선택합니다.
1. 스트림을 선택하여 확장합니다.
1. **Custom HTTP headers** 테이블을 찾습니다.
1. 제거할 헤더를 찾습니다.
1. 헤더의 오른쪽에서 **삭제**({{< icon name="remove" >}})를 선택합니다.
1. **Save**를 선택합니다.

## 관련 항목 {#related-topics}

- [인스턴스의 감사 이벤트 스트리밍](../../administration/compliance/audit_event_streaming.md)
