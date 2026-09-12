---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: DAST 프로필
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

DAST 사이트 및 스캐너 프로필은 애플리케이션 및 평가에 사용하는 스캐너와 관련된 정보를 저장합니다. 프로필을 정의한 후 파이프라인 및 온디맨드 DAST 작업에 사용할 수 있습니다.

DAST 프로필, DAST 스캐너 프로필, DAST 사이트 프로필의 생성, 업데이트 및 삭제는 [감사 로그](../../../administration/compliance/audit_event_reports.md)에 포함됩니다.

## 사이트 프로필 {#site-profile}

{{< history >}}

- 사이트 프로필 기능, 스캔 방법 및 파일 URL은 GitLab 15.6에서 [GitLab.com 및 GitLab Self-Managed에 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/345837)되었습니다.
- GraphQL 엔드포인트 경로 기능은 GitLab 15.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/378692)되었습니다.
- 추가 변수는 GitLab 17.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/177703)되었습니다.

{{< /history >}}

사이트 프로필은 DAST에서 스캔할 배포된 애플리케이션, 웹 사이트 또는 API의 속성 및 구성 세부 정보를 정의합니다.

사이트 프로필에는 다음이 포함됩니다:

- **프로필 이름**: 스캔할 사이트에 할당하는 이름입니다. 사이트 프로필이 `.gitlab-ci.yml` 또는 온디맨드 스캔에서 참조되는 경우 이름을 바꿀 수 **없습니다**.
- **사이트 유형**: 스캔할 대상의 유형으로 웹 사이트 또는 API 스캔입니다.
- **타겟 URL**: DAST가 실행되는 URL입니다.
- **제외된 URL**: 스캔에서 제외할 URL의 쉼표로 구분된 목록입니다. [RE2 스타일 정규식](https://github.com/google/re2/wiki/Syntax)을 사용할 수 있습니다. 정규식은 유효한 URL 문자이기 때문에 물음표(`?`) 문자를 포함할 수 없습니다.
- **헤더 요청**: 이름과 값을 포함하는 HTTP 요청 헤더의 쉼표로 구분된 목록입니다. 이 헤더는 DAST에서 수행한 모든 요청에 추가됩니다.
- **인증**: 
  - **Authenticated URL**: 대상 웹 사이트의 로그인 HTML 양식을 포함하는 페이지의 URL입니다. 사용자명과 비밀번호는 인증된 스캔을 생성하기 위해 로그인 양식과 함께 제출됩니다.
  - **사용자명**: 웹 사이트에 인증하는 데 사용되는 사용자명입니다.
  - **비밀번호**: 웹 사이트에 인증하는 데 사용되는 비밀번호입니다.
  - **사용자명 양식 필드**: 로그인 HTML 양식의 사용자명 필드 이름입니다.
  - **비밀번호 양식 필드**: 로그인 HTML 양식의 비밀번호 필드 이름입니다.
  - **Submit form field**: 선택하면 로그인 HTML 양식을 제출하는 요소의 `id` 또는 `name`입니다.
- **스캔 방법**: API 테스트를 수행하는 방법의 유형입니다. 지원되는 방법은 OpenAPI, Postman Collections, HTTP Archive(HAR) 또는 GraphQL입니다.
  - **GraphQL 엔드포인트 경로**: GraphQL 엔드포인트의 경로입니다. 이 경로는 대상 URL과 연결되어 스캔이 테스트할 URI를 제공합니다. GraphQL 엔드포인트는 내성 쿼리를 지원해야 합니다.
  - **File URL**: OpenAPI, Postman Collection 또는 HTTP Archive 파일의 URL입니다.
- **추가 변수**: 특정 스캔 동작을 구성하는 환경 변수의 목록입니다. 이 변수는 파이프라인 기반 DAST 스캔과 동일한 구성 옵션을 제공합니다(예: 시간 제한 설정, 인증 성공 URL 추가 또는 고급 스캔 기능 활성화).

API 사이트 유형을 선택하면 호스트 재정의가 스캔할 API가 대상과 동일한 호스트에 있는지 확인하는 데 사용됩니다. 이는 잘못된 API에 대해 활성 스캔을 실행할 위험을 줄이기 위해 수행됩니다.

구성된 경우 요청 헤더 및 비밀번호 필드는 데이터베이스에 저장되기 전에 [`aes-256-gcm`](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)를 사용하여 암호화됩니다. 이 데이터는 유효한 secrets 파일로만 읽고 해독할 수 있습니다.

`.gitlab-ci.yml` 및 온디맨드 스캔에서 사이트 프로필을 참조할 수 있습니다.

```yaml
stages:
  - dast

include:
  - template: DAST.gitlab-ci.yml

dast:
  stage: dast
  dast_configuration:
    site_profile: "<profile name>"
```

### 사이트 프로필 검증 {#site-profile-validation}

사이트 프로필 검증은 잘못된 웹 사이트에 대해 활성 스캔을 실행할 위험을 줄입니다. 사이트에 대해 온디맨드 스캔을 실행하려면 사이트를 검증해야 합니다.

사이트 프로필 검증은 보안 기능이 아닙니다. 필요한 경우 [파이프라인 스캔](browser/configuration/enabling_the_analyzer.md)을 사용하여 검증되지 않은 사이트에 대해 DAST를 실행할 수 있습니다.

각 사이트 검증 방법은 기능이 동등하므로 가장 적합한 방법을 사용하세요:

- **텍스트 파일 유효성 검증**: 대상 사이트에 업로드할 텍스트 파일이 필요합니다. 텍스트 파일에는 프로젝트에 고유한 이름과 내용이 할당됩니다. 검증 프로세스는 파일의 내용을 확인합니다.
- **헤더 유효성 검증**: 헤더 `Gitlab-On-Demand-DAST`를 대상 사이트에 추가해야 하며, 프로젝트에 고유한 값이 있어야 합니다. 검증 프로세스는 헤더가 있는지 확인하고 그 값을 확인합니다.
- **메타 태그 유효성 검증**: `gitlab-dast-validation` 메타 태그를 대상 사이트에 추가해야 하며, 프로젝트에 고유한 값이 있어야 합니다. 페이지의 `<head>` 섹션에 추가해야 합니다. 검증 프로세스는 메타 태그가 있는지 확인하고 그 값을 확인합니다.

### 사이트 프로필 생성 {#create-a-site-profile}

사이트 프로필을 생성하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **동적 애플리케이션 보안 테스트 (DAST)** 섹션에서 **프로필 관리**를 선택합니다.
1. **신규** > **사이트 프로필**을 선택합니다.
1. 필드를 완성한 후 **프로필 저장**을 선택합니다.

사이트 프로필이 저장되어 온디맨드 스캔에서 사용할 수 있습니다.

### 사이트 프로필 편집 {#edit-a-site-profile}

스캔 전에 사이트 프로필을 편집하여 설정을 변경합니다.

사이트 프로필이 보안 정책과 연결되어 있으면 이 페이지에서 프로필을 편집할 수 없습니다. 자세한 내용은 [스캔 실행 정책](../policies/scan_execution_policies.md)을 참조하세요.

사이트 검증 파이프라인을 활성화하려면 `dast-validation-runner` 태그를 사용하여 러너를 정의하거나 태그가 없는 작업을 실행할 수 있는 러너를 정의해야 합니다.

전제 조건:

- DAST 스캔이 프로필을 사용하는 경우 스캔과 연결된 브랜치에 푸시할 수 있어야 합니다.

사이트 프로필을 편집하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **동적 애플리케이션 보안 테스트 (DAST)** 섹션에서 **프로필 관리**를 선택합니다.
1. **Site Profiles** 탭을 선택합니다.
1. 프로필 행에서 **추가 작업**({{< icon name="ellipsis_v" >}}) 메뉴를 선택한 후 **편집**을 선택합니다.
1. 필드를 편집한 후 **프로필 저장**을 선택합니다.

사이트 프로필의 대상 또는 인증된 URL이 업데이트되면 해당 프로필과 연결된 요청 헤더 및 비밀번호 필드가 지워집니다.

### 사이트 프로필 삭제 {#delete-a-site-profile}

> [!note]
> 사이트 프로필이 보안 정책과 연결되어 있으면 사용자가 이 페이지에서 프로필을 삭제할 수 없습니다. 자세한 내용은 [스캔 실행 정책](../policies/scan_execution_policies.md)을 참조하세요.
> 사이트 프로필이 [온디맨드 스캔](on-demand_scan.md)과 연결되어 있고 삭제되면 온디맨드 스캔도 삭제됩니다.

사이트 프로필을 삭제하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **동적 애플리케이션 보안 테스트 (DAST)** 섹션에서 **프로필 관리**를 선택합니다.
1. **Site Profiles** 탭을 선택합니다.
1. 프로필 행에서 **추가 작업**({{< icon name="ellipsis_v" >}}) 메뉴를 선택한 후 **삭제**를 선택합니다.
1. 삭제를 확인하려면 **삭제**를 선택합니다.

### 사이트 프로필 검증 {#validate-a-site-profile}

활성 스캔을 실행하려면 사이트를 검증해야 합니다.

전제 조건:

- 검증 작업을 실행하려면 프로젝트에서 러너를 사용할 수 있어야 합니다.

사이트 프로필을 검증하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **동적 애플리케이션 보안 테스트 (DAST)** 섹션에서 **프로필 관리**를 선택합니다.
1. **Site Profiles** 탭을 선택합니다.
1. 프로필 행에서 **검증**을 선택합니다.
1. 검증 방법을 선택합니다.
   1. **텍스트 파일 유효성 검증**의 경우:
      1. **2 단계**에 나열된 검증 파일을 다운로드합니다.
      1. 검증 파일을 호스트에 업로드하여 **Step 3** 또는 원하는 다른 위치에 업로드합니다.
      1. 필요한 경우 **Step 3**에서 파일 위치를 편집합니다.
      1. **검증**을 선택합니다.
   1. **헤더 유효성 검증**의 경우:
      1. **2 단계**에서 클립보드 아이콘을 선택합니다.
      1. 검증할 사이트의 헤더를 편집하고 클립보드 내용을 붙여넣습니다.
      1. **Step 3**의 입력 필드를 선택하고 헤더의 위치를 입력합니다.
      1. **검증**을 선택합니다.
   1. **메타 태그 유효성 검증**의 경우:
      1. **2 단계**에서 클립보드 아이콘을 선택합니다.
      1. 검증할 사이트의 내용을 편집하고 클립보드 내용을 붙여넣습니다.
      1. **Step 3**의 입력 필드를 선택하고 메타 태그의 위치를 입력합니다.
      1. **검증**을 선택합니다.

사이트가 검증되고 활성 스캔을 실행할 수 있습니다. 사이트 프로필의 검증 상태는 수동으로 해지되거나 파일, 헤더 또는 메타 태그가 편집될 때만 해지됩니다.

### 실패한 검증 재시도 {#retry-a-failed-validation}

실패한 사이트 검증 시도는 **프로필 관리** 페이지의 **사이트 프로필** 탭에 나열됩니다.

사이트 프로필의 실패한 검증을 재시도하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **동적 애플리케이션 보안 테스트 (DAST)** 섹션에서 **프로필 관리**를 선택합니다.
1. **Site Profiles** 탭을 선택합니다.
1. 프로필 행에서 **유효성 검증 재시도**를 선택합니다.

### 사이트 프로필의 검증 상태 해지 {#revoke-a-site-profiles-validation-status}

> [!warning]
> 사이트 프로필의 검증 상태가 해지되면 동일한 URL을 공유하는 모든 사이트 프로필도 검증 상태가 해지됩니다.

사이트 프로필의 검증 상태를 해지하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **동적 애플리케이션 보안 테스트 (DAST)** 섹션에서 **프로필 관리**를 선택합니다.
1. 검증된 프로필 옆에서 **유효성 검증 해지**를 선택합니다.

사이트 프로필의 검증 상태가 해지됩니다.

### 검증된 사이트 프로필 헤더 {#validated-site-profile-headers}

다음은 애플리케이션에서 필요한 사이트 프로필 헤더를 제공하는 방법의 코드 샘플입니다.

#### 온디맨드 스캔을 위한 Ruby on Rails 예제 {#ruby-on-rails-example-for-on-demand-scan}

Ruby on Rails 애플리케이션에서 사용자 정의 헤더를 추가하는 방법은 다음과 같습니다:

```ruby
class DastWebsiteTargetController < ActionController::Base
  def dast_website_target
    response.headers['Gitlab-On-Demand-DAST'] = '0dd79c9a-7b29-4e26-a815-eaaf53fcab1c'
    head :ok
  end
end
```

#### 온디맨드 스캔을 위한 Django 예제 {#django-example-for-on-demand-scan}

[Django에서 사용자 정의 헤더를 추가](https://docs.djangoproject.com/en/2.2/ref/request-response/#setting-header-fields)하는 방법은 다음과 같습니다:

```python
class DastWebsiteTargetView(View):
    def head(self, *args, **kwargs):
      response = HttpResponse()
      response['Gitlab-On-Demand-DAST'] = '0dd79c9a-7b29-4e26-a815-eaaf53fcab1c'

      return response
```

#### 온디맨드 스캔을 위한 Node (Express 포함) 예제 {#node-with-express-example-for-on-demand-scan}

[Node (Express 포함)에서 사용자 정의 헤더를 추가](https://expressjs.com/en/5x/api.html#res.append)하는 방법은 다음과 같습니다:

```javascript
app.get('/dast-website-target', function(req, res) {
  res.append('Gitlab-On-Demand-DAST', '0dd79c9a-7b29-4e26-a815-eaaf53fcab1c')
  res.send('Respond to DAST ping')
})
```

## 스캐너 프로필 {#scanner-profile}

{{< history >}}

- GitLab 17.0에서 브라우저 기반 온디맨드 DAST 스캔이 도입되면서 더 이상 사용되지 않는 AJAX Spider 옵션입니다.
- GitLab 17.0에서 브라우저 기반 온디맨드 DAST 스캔이 도입되면서 Spider 시간 초과의 이름을 크롤링 시간 초과로 변경했습니다.

{{< /history >}}

스캐너 프로필은 보안 스캐너의 구성 세부 정보를 정의합니다.

스캐너 프로필에는 다음이 포함됩니다:

- **프로필 이름**: 스캐너 프로필에 제공하는 이름입니다. 예를 들어 "Spider_15"입니다. 스캐너 프로필이 `.gitlab-ci.yml` 또는 온디맨드 스캔에서 참조되는 경우 이름을 바꿀 수 **없습니다**.
- **모드 스캔**: 수동 스캔은 대상으로 전송된 모든 HTTP 메시지(요청 및 응답)를 모니터링합니다. 활성 스캔은 대상을 공격하여 잠재적 취약성을 찾습니다.
- **크롤링 시간 초과**: 크롤러가 사이트를 통과할 수 있는 최대 분 수입니다.
- **대상 시간 초과**: DAST가 스캔을 시작하기 전에 사이트를 사용할 수 있을 때까지 대기하는 최대 초 수입니다.
- **디버그 메시지**: DAST 콘솔 출력에 디버그 메시지를 포함합니다.

`.gitlab-ci.yml` 및 온디맨드 스캔에서 스캐너 프로필을 참조할 수 있습니다.

```yaml
stages:
  - dast

include:
  - template: DAST.gitlab-ci.yml

dast:
  stage: dast
  dast_configuration:
    scanner_profile: "<profile name>"
```

### 스캐너 프로필 생성 {#create-a-scanner-profile}

스캐너 프로필을 생성하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **동적 애플리케이션 보안 테스트 (DAST)** 섹션에서 **프로필 관리**를 선택합니다.
1. **신규** > **스캐너 프로필**을 선택합니다.
1. 양식을 완성합니다. 각 필드의 세부 정보는 [스캐너 프로필](#scanner-profile)을 참조하세요.
1. **프로필 저장**을 선택합니다.

### 스캐너 프로필 편집 {#edit-a-scanner-profile}

전제 조건:

- DAST 스캔이 프로필을 사용하는 경우 스캔과 연결된 브랜치에 푸시할 수 있어야 합니다.

> [!note]
> 스캐너 프로필이 보안 정책과 연결되어 있으면 이 페이지에서 프로필을 편집할 수 없습니다. 자세한 내용은 [스캔 실행 정책](../policies/scan_execution_policies.md)을 참조하세요.

스캐너 프로필을 편집하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **동적 애플리케이션 보안 테스트 (DAST)** 섹션에서 **프로필 관리**를 선택합니다.
1. **스캐너 프로필** 탭을 선택합니다.
1. 스캐너 행에서 **추가 작업**({{< icon name="ellipsis_v" >}}) 메뉴를 선택한 후 **편집**을 선택합니다.
1. 양식을 편집합니다.
1. **프로필 저장**을 선택합니다.

### 스캐너 프로필 삭제 {#delete-a-scanner-profile}

> [!note]
> 스캐너 프로필이 보안 정책과 연결되어 있으면 사용자가 이 페이지에서 프로필을 삭제할 수 없습니다. 자세한 내용은 [스캔 실행 정책](../policies/scan_execution_policies.md)을 참조하세요. 스캐너 프로필이 [온디맨드 스캔](on-demand_scan.md)과 연결되어 있고 삭제되면 온디맨드 스캔도 삭제됩니다.

스캐너 프로필을 삭제하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **동적 애플리케이션 보안 테스트 (DAST)** 섹션에서 **프로필 관리**를 선택합니다.
1. **스캐너 프로필** 탭을 선택합니다.
1. 스캐너 행에서 **추가 작업**({{< icon name="ellipsis_v" >}}) 메뉴를 선택한 후 **삭제**를 선택합니다.
1. **삭제**를 선택합니다.
