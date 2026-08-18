---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 환경
description: "환경, 변수, 대시보드 및 검토 앱."
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 환경은 개발, 스테이징 또는 프로덕션과 같이 애플리케이션의 특정 배포 대상을 나타냅니다. 이를 사용하여 다양한 구성을 관리하고 소프트웨어 수명 주기의 다양한 단계에서 코드를 배포할 수 있습니다.

환경을 사용하면 다음을 할 수 있습니다:

- 배포 프로세스를 일관되고 반복 가능하게 유지
- 어떤 코드가 어디에 배포되는지 추적
- 문제 발생 시 이전 버전으로 롤백
- 민감한 환경을 무단 변경으로부터 보호
- 환경별 배포 변수를 제어하여 보안 경계 유지
- 환경 상태를 모니터링하고 문제 발생 시 경고 받기

## 환경 및 배포 보기 {#view-environments-and-deployments}

전제 조건:

- 비공개 프로젝트에서는 Reporter, Developer, Maintainer 또는 Owner 역할이 있어야 합니다. [환경 권한](#environment-permissions)을 참조하세요.

특정 프로젝트의 환경 목록을 보는 몇 가지 방법이 있습니다:

- 프로젝트 개요 페이지에서 하나 이상의 환경을 사용할 수 있는 경우(즉, 중지되지 않은 경우).

  ![사용 가능한 환경의 수를 증분 카운터로 표시하는 프로젝트 개요 페이지입니다.](img/environments_project_home_v15_9.png)

- 왼쪽 사이드바에서 **운영** > **환경**을 선택합니다. 환경이 표시됩니다.

  ![환경 이름, 상태 및 기타 관련 세부 정보를 표시하는 GitLab 프로젝트의 사용 가능한 환경 목록입니다.](img/environments_list_v14_8.png)

- 환경의 배포 목록을 보려면 환경 이름(예: `staging`)을 선택합니다. 배포 작업이 배포를 생성한 후에만 배포가 이 목록에 표시됩니다.

  ![배포 이력 및 관련 세부 정보를 표시하는 선택한 환경의 배포 목록입니다.](img/deployments_list_v13_10.png)

- 배포 파이프라인의 모든 수동 작업 목록을 보려면 **실행** ({{< icon name="play" >}}) 드롭다운 목록을 선택합니다.

  ![배포 파이프라인에서 수동 작업 보기](img/view_manual_jobs_v17_10.png)

### 환경 URL {#environment-url}

{{< history >}}

- [변경됨](https://gitlab.com/gitlab-org/gitlab/-/issues/337417) \- GitLab 15.2에서 임의의 URL을 유지하도록 [플래그 사용](../../administration/feature_flags/_index.md) `soft_validation_on_external_url`. 기본적으로 비활성화되어 있습니다.
- GitLab 15.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/337417)합니다. [기능 플래그 `soft_validation_on_external_url`](https://gitlab.com/gitlab-org/gitlab/-/issues/367206)이 제거되었습니다.

{{< /history >}}

[환경 URL](../yaml/_index.md#environmenturl)은 GitLab의 여러 위치에 표시됩니다:

- 머지 리퀘스트에 링크로:

  ![머지 리퀘스트의 환경 URL](img/environments_mr_review_app_v11_10.png)

- 환경 보기에 버튼으로:

  ![환경 보기에서 라이브 환경 열기](img/environments_open_live_environment_v14_8.png)

- 배포 보기에 버튼으로:

  ![배포의 환경 URL](img/deployments_view_v11_10.png)

다음 조건을 충족하는 경우 머지 리퀘스트에서 이 정보를 볼 수 있습니다:

- 머지 리퀘스트가 결국 기본 브랜치(보통 `main`)로 병합됩니다.
- 그 브랜치도 환경에 배포됩니다(예: `staging` 또는 `production`).

예를 들어:

![머지 리퀘스트의 환경 URL](img/environments_link_url_mr_v10_1.png)

#### 소스 파일에서 공개 페이지로 이동 {#go-from-source-files-to-public-pages}

GitLab [경로 맵](../review_apps/_index.md#route-maps)을 사용하면 소스 파일에서 검토 앱으로 설정된 환경의 공개 페이지로 직접 이동할 수 있습니다.

## 환경 유형 {#types-of-environments}

환경은 정적 또는 동적입니다.

정적 환경:

- 보통 연속된 배포에 의해 재사용됩니다.
- 정적 이름을 가집니다. 예를 들어, `staging` 또는 `production`.
- 수동으로 또는 CI/CD 파이프라인의 일부로 생성됩니다.

동적 환경:

- 보통 CI/CD 파이프라인에서 생성되며 단일 배포에서만 사용된 다음 중지되거나 삭제됩니다.
- 동적 이름을 가지며, 보통 CI/CD 변수의 값을 기반으로 합니다.
- [검토 앱](../review_apps/_index.md)의 기능입니다.

환경은 [중지 작업](../yaml/_index.md#environmenton_stop)의 실행 여부에 따라 3가지 상태 중 하나를 가집니다:

- `available`: 환경이 존재합니다. 배포가 있을 수 있습니다.
- `stopping`: _중지 작업_이 시작되었습니다. 중지 작업이 정의되지 않은 경우 이 상태는 적용되지 않습니다.
- `stopped`: _중지 작업_이 실행되었거나 사용자가 수동으로 작업을 중지했습니다.

## 정적 환경 생성 {#create-a-static-environment}

UI 또는 `.gitlab-ci.yml` 파일에서 정적 환경을 생성할 수 있습니다.

### UI에서 {#in-the-ui}

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

UI에서 정적 환경을 생성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을 선택합니다.
1. **환경 생성**을 선택합니다.
1. 필드를 완성하세요.
1. **Save**를 선택합니다.

### `.gitlab-ci.yml` 파일에서 {#in-your-gitlab-ciyml-file}

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

정적 환경을 생성하려면 `.gitlab-ci.yml` 파일에서:

1. `deploy` 스테이지에서 작업을 정의합니다.
1. 작업에서 환경 `name`과 `url`를 정의합니다. 파이프라인이 실행될 때 해당 이름의 환경이 존재하지 않으면 생성됩니다.

> [!note]
> 환경 이름에는 일부 문자를 사용할 수 없습니다. `environment` 키워드에 대한 자세한 정보는 [`.gitlab-ci.yml` 키워드 참조](../yaml/_index.md#environment)를 참조하세요.

예를 들어, `staging` 이름의 환경을 생성하려면 URL `https://staging.example.com`:

```yaml
deploy_staging:
  stage: deploy
  script:
    - echo "Deploy to staging server"
  environment:
    name: staging
    url: https://staging.example.com
```

## 동적 환경 생성 {#create-a-dynamic-environment}

동적 환경을 생성하려면 각 파이프라인에 고유한 [CI/CD 변수](#cicd-variables)를 사용합니다.

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

동적 환경을 생성하려면 `.gitlab-ci.yml` 파일에서:

1. `deploy` 스테이지에서 작업을 정의합니다.
1. 작업에서 다음 환경 속성을 정의합니다:
   - `name`: `$CI_COMMIT_REF_SLUG`과 같은 관련 CI/CD 변수를 사용합니다. 선택적으로 환경의 이름에 정적 접두사를 추가합니다. 이는 [UI에서 그룹화](#group-similar-environments)하여 같은 접두사를 가진 모든 환경을 그룹화합니다.
   - `url`: 선택 사항. 호스트명 앞에 `$CI_ENVIRONMENT_SLUG`과 같은 관련 CI/CD 변수를 붙입니다.

> [!note]
> 환경 이름에는 일부 문자를 사용할 수 없습니다. `environment` 키워드에 대한 자세한 정보는 [`.gitlab-ci.yml` 키워드 참조](../yaml/_index.md#environment)를 참조하세요.

다음 예제에서 `deploy_review_app` 작업이 실행될 때마다 환경의 이름과 URL이 고유한 값으로 정의됩니다.

```yaml
deploy_review_app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: never
    - if: $CI_COMMIT_BRANCH
```

### 동적 환경 URL 설정 {#set-a-dynamic-environment-url}

일부 외부 호스팅 플랫폼은 각 배포에 대해 임의의 URL을 생성합니다(예: `https://94dd65b.amazonaws.com/qa-lambda-1234567`). 이렇게 하면 `.gitlab-ci.yml` 파일에서 URL을 참조하기 어렵습니다.

배포 작업을 구성하여 생성된 URL을 dotenv 변수로 캡처하고 `environment:url`에 전달할 수 있습니다. 작업에서 [`artifacts:reports:dotenv`](../variables/dotenv_variables.md)을 지정합니다. 작업이 완료되면 GitLab은 dotenv 보고서를 구문 분석하고 `environment:url`을 변수 값으로 확장합니다. 할당된 URL은 UI에서 볼 수 있습니다.

정적 접두사와 변수를 결합할 수도 있습니다(예: `https://$DYNAMIC_ENVIRONMENT_URL`). `DYNAMIC_ENVIRONMENT_URL`이 `example.com`이면 결과는 `https://example.com`입니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [작업이 완료된 후 동적 URL 설정](https://youtu.be/70jDXtOf4Ig)을 참조하세요.

다음 예제에서 검토 앱은 각 머지 리퀘스트에 대해 새로운 환경을 생성합니다:

- `review` 작업은 모든 푸시로 트리거되며 `review/your-branch-name` 이름의 환경을 생성하거나 업데이트합니다. 환경 URL은 `$DYNAMIC_ENVIRONMENT_URL`로 설정됩니다.
- `review` 작업이 완료되면 GitLab은 `review/your-branch-name` 환경의 URL을 업데이트합니다. `deploy.env` 보고서를 구문 분석하고 변수를 추출한 다음 `environment:url`을 확장하고 설정하는 데 사용합니다.

```yaml
review:
  script:
    - DYNAMIC_ENVIRONMENT_URL=$(deploy-script)                                 # In script, get the environment URL.
    - echo "DYNAMIC_ENVIRONMENT_URL=$DYNAMIC_ENVIRONMENT_URL" >> deploy.env    # Add the value to a dotenv file.
  artifacts:
    reports:
      dotenv: deploy.env                                                       # Report back dotenv file to rails.
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: $DYNAMIC_ENVIRONMENT_URL                                              # and set the variable produced in script to `environment:url`
    on_stop: stop_review

stop_review:
  script:
    - ./teardown-environment
  when: manual
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
```

다음을 참고하세요:

- `stop_review`은 dotenv 보고서 아티팩트를 생성하지 않으므로 `DYNAMIC_ENVIRONMENT_URL` 환경 변수를 인식하지 못합니다. 따라서 `environment:url`을 `stop_review` 작업에서 설정하지 않아야 합니다.
- 환경 URL이 유효하지 않으면(예: URL이 잘못된 형식) 시스템이 환경 URL을 업데이트하지 않습니다.
- `stop_review`에서 실행되는 스크립트가 리포지토리에만 존재하고 따라서 `GIT_STRATEGY: none` 또는 `GIT_STRATEGY: empty`을 사용할 수 없으면 이 작업에 대해 [머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md)을 구성합니다. 이렇게 하면 기능 브랜치가 삭제된 후에도 러너가 리포지토리를 가져올 수 있습니다. 자세한 정보는 [러너용 참조 사양](../pipelines/_index.md#ref-specs-for-runners)을 참조하세요.

> [!note]
> Windows 러너의 경우 PowerShell `Add-Content` 명령을 사용하여 `.env` 파일에 쓰세요.

```powershell
Add-Content -Path deploy.env -Value "DYNAMIC_ENVIRONMENT_URL=$DYNAMIC_ENVIRONMENT_URL"
```

## 환경의 배포 티어 {#deployment-tier-of-environments}

같은 그룹의 프로젝트는 동일한 배포 티어에 대해 서로 다른 환경 이름을 사용할 수 있습니다. 예를 들어 한 프로젝트는 production을 사용하고 다른 프로젝트는 같은 티어에 대해 custom-portal을 사용할 수 있습니다. 그룹 보호 환경은 배포 티어를 사용하여 이러한 차이를 처리합니다.

다음 배포 티어를 사용할 수 있습니다:

- development
- testing
- staging
- production
- other

GitLab은 [환경 이름](../yaml/_index.md#environmentname)에서 배포 티어를 추측합니다(이 패턴을 기반으로):

| Ruby 정규식 패턴                                         | 배포 티어 |
|-------------------------------------------------------------|-----------------|
| `/(dev\|review\|trunk)/i`                                   | development     |
| `/(test\|tst\|int\|ac(ce\|)pt\|qa\|qc\|control\|quality)/i` | testing         |
| `/(st(a\|)g\|mod(e\|)l\|pre\|demo\|non)/i`                  | staging         |
| `/(pr(o\|)d\|live)/i`                                       | production      |

패턴과 일치하지 않는 환경 이름은 `other`로 추측됩니다.

자동 추측을 피하려면 [`deployment_tier` 키워드](../yaml/_index.md#environmentdeployment_tier)를 사용합니다.

UI에서 배포 티어를 설정할 수 없습니다.

### 환경 이름 변경 {#rename-an-environment}

{{< history >}}

- API를 사용한 환경 이름 변경은 GitLab 15.9에서 [더 이상 사용되지 않음](https://gitlab.com/gitlab-org/gitlab/-/issues/338897)입니다.
- API를 사용한 환경 이름 변경은 GitLab 16.0에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/338897)입니다.

{{< /history >}}

환경의 이름을 바꿀 수 없습니다.

환경 이름 변경과 동일한 결과를 달성하려면:

1. [기존 환경 중지](#stop-an-environment-by-using-the-ui).
1. [기존 환경 삭제](#delete-an-environment).
1. [원하는 이름으로 새 환경 생성](#create-a-static-environment).

## CI/CD 변수 {#cicd-variables}

환경 및 배포를 사용자 지정하려면 [사전 정의된 CI/CD 변수](../variables/predefined_variables.md)를 사용하거나 사용자 지정 CI/CD 변수를 정의할 수 있습니다.

### CI/CD 변수의 환경 범위 제한 {#limit-the-environment-scope-of-a-cicd-variable}

기본적으로 모든 [CI/CD 변수](../variables/_index.md)는 파이프라인의 모든 작업에서 사용 가능합니다. 작업의 테스트 도구가 손상되면 도구는 작업에서 사용 가능한 모든 CI/CD 변수를 검색하려고 할 수 있습니다. 이러한 공급망 공격을 완화하려면 민감한 변수의 환경 범위를 해당 변수가 필요한 작업으로만 제한해야 합니다.

CI/CD 변수가 사용할 수 있는 환경을 정의하여 CI/CD 변수의 환경 범위를 제한합니다. 기본 환경 범위는 `*` 와일드카드이므로 모든 작업이 변수에 액세스할 수 있습니다.

특정 일치를 사용하여 특정 환경을 선택할 수 있습니다. 예를 들어, 변수의 환경 범위를 `production`로 설정하여 [환경](../yaml/_index.md#environment)이 `production`인 작업만 변수에 액세스할 수 있도록 합니다.

와일드카드 일치(`*`)를 사용하여 특정 환경 그룹(예: `review/*`를 가진 [검토 앱](../review_apps/_index.md) 모두)을 선택할 수도 있습니다.

예를 들어 이 4가지 환경이 있습니다:

- `production`
- `staging`
- `review/feature-1`
- `review/feature-2`

이 환경 범위는 다음과 같이 일치합니다:

| ↓ 범위 / 환경 → | `production` | `staging` | `review/feature-1` | `review/feature-2` |
|:------------------------|:-------------|:----------|:-------------------|:-------------------|
| `*`                     | 일치        | 일치     | 일치              | 일치              |
| `production`            | 일치        |           |                    |                    |
| `staging`               |              | 일치     |                    |                    |
| `review/*`              |              |           | 일치              | 일치              |
| `review/feature-1`      |              |           | 일치              |                    |

[`rules`](../yaml/_index.md#rules) 또는 [`include`](../yaml/_index.md#include)에서 환경 범위의 변수를 사용하면 안 됩니다. 파이프라인 생성 시 GitLab이 파이프라인 구성을 검증할 때 변수가 정의되지 않을 수 있습니다.

## 환경 검색 {#search-environments}

{{< history >}}

- GitLab 15.5에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/10754).
- [폴더 내 환경 검색](https://gitlab.com/gitlab-org/gitlab/-/issues/373850)은 GitLab 15.7에서 [기능 플래그 `enable_environments_search_within_folder`](https://gitlab.com/gitlab-org/gitlab/-/issues/382108)과 함께 도입되었습니다. 기본적으로 활성화됩니다.
- GitLab 17.4에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/382108)합니다. 기능 플래그 `enable_environments_search_within_folder`이 제거되었습니다.

{{< /history >}}

이름으로 환경을 검색하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을 선택합니다.
1. 검색 표시줄에 검색어를 입력하세요.
   - 검색어의 길이는 **search term should be 3 or more characters**.
   - 일치는 환경 이름의 시작부터 적용됩니다.
     - 예를 들어 `devel`은 환경 이름 `development`과 일치하지만 `elop`은 일치하지 않습니다.
   - 폴더 이름 형식의 환경의 경우 기본 폴더 이름 뒤에 일치가 적용됩니다.
     - 예를 들어 이름이 `review/test-app`일 때 검색어 `test`은 `review/test-app`과 일치합니다.
     - 또한 `review/test`과 같이 폴더 이름을 앞에 붙여서 검색하면 `review/test-app`과 일치합니다.

## 유사한 환경 그룹화 {#group-similar-environments}

환경을 UI의 축소 가능한 섹션으로 그룹화할 수 있습니다.

예를 들어 모든 환경이 `review` 이름으로 시작하면 UI에서 환경이 해당 제목 아래에 그룹화됩니다:

![환경 그룹](img/environments_dynamic_groups_v13_10.png)

다음 예제에서는 환경 이름을 `review`으로 시작하는 방법을 보여 줍니다. `$CI_COMMIT_REF_SLUG` 변수는 런타임에 브랜치 이름으로 채워집니다:

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
```

## 환경 중지 {#stopping-an-environment}

환경을 중지하는 것은 대상 서버에서 배포에 액세스할 수 없다는 의미입니다. 환경을 삭제하기 전에 중지해야 합니다.

`on_stop` 작업을 사용하여 환경을 중지할 때, [아카이브됨](../../administration/settings/continuous_integration.md#archive-pipelines)이 아니면 작업이 실행됩니다.

### UI를 사용하여 환경 중지 {#stop-an-environment-by-using-the-ui}

> [!note]
> `on_stop` 작업을 트리거하고 환경 보기에서 수동으로 환경을 중지하려면 중지 및 배포 작업이 동일한 [`resource_group`](../yaml/_index.md#resource_group)에 있어야 합니다.

GitLab UI에서 환경을 중지하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을 선택합니다.
1. 중지할 환경 옆에서 **중지**를 선택합니다.
1. 확인 대화에서 **중지 환경**을 선택합니다.

### 기본 중지 동작 {#default-stopping-behavior}

GitLab은 관련 브랜치가 삭제되거나 병합될 때 환경을 자동으로 중지합니다. 명시적 `on_stop` CI/CD 작업이 정의되지 않았더라도 이 동작이 유지됩니다.

그러나 [이슈 428625](https://gitlab.com/gitlab-org/gitlab/-/issues/428625)는 명시적 `on_stop` CI/CD 작업이 정의된 경우에만 production 및 staging 환경이 중지되도록 이 동작을 변경할 것을 제안합니다.

환경 API의 [`auto_stop_setting`](../../api/environments.md#update-an-existing-environment) 매개변수를 사용하여 환경의 중지 동작을 구성할 수 있습니다.

### 브랜치 삭제 시 환경 중지 {#stop-an-environment-when-a-branch-is-deleted}

브랜치가 삭제될 때 환경이 중지되도록 구성할 수 있습니다.

다음 예제에서 `deploy_review` 작업은 `stop_review` 작업을 호출하여 환경을 정리하고 중지합니다.

- 두 작업은 동일한 [`rules`](../yaml/_index.md#rules) 또는 [`only/except`](../yaml/deprecated_keywords.md#only--except) 구성을 가져야 합니다. 그렇지 않으면 `stop_review` 작업이 `deploy_review` 작업을 포함하는 모든 파이프라인에 포함되지 않을 수 있으며 `action: stop`을 트리거하여 환경을 자동으로 중지할 수 없습니다.
- [`action: stop` 작업이 실행되지 않을 수 있습니다](#the-job-with-action-stop-doesnt-run). 환경을 시작한 작업보다 이후 스테이지에 있는 경우.
- [머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md)을 사용할 수 없으면 [`GIT_STRATEGY`](../runners/configure_runners.md#git-strategy)을 `none` 또는 `empty`로 설정하세요. `stop_review` 작업에서. 그러면 [러너](https://docs.gitlab.com/runner/)가 브랜치 삭제 후 코드를 체크아웃하려고 시도하지 않습니다.

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com
    on_stop: stop_review

stop_review:
  stage: deploy
  script:
    - echo "Remove review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

### 머지 리퀘스트가 병합되거나 닫힐 때 환경 중지 {#stop-an-environment-when-a-merge-request-is-merged-or-closed}

[머지 리퀘스트 파이프라인](../pipelines/merge_request_pipelines.md) 구성을 사용하면 `stop` 트리거가 자동으로 활성화됩니다.

다음 예제에서 `deploy_review` 작업은 `stop_review` 작업을 호출하여 환경을 정리하고 중지합니다.

- [**파이프라인이 성공해야 함**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge) 설정이 켜져 있으면 [`allow_failure: true`](../yaml/_index.md#allow_failure) 키워드를 `stop_review` 작업에 구성하여 파이프라인 및 머지 리퀘스트 차단을 방지할 수 있습니다.

```yaml
deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    on_stop: stop_review
  rules:
    - if: $CI_MERGE_REQUEST_ID

stop_review:
  stage: deploy
  script:
    - echo "Remove review app"
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  rules:
    - if: $CI_MERGE_REQUEST_ID
      when: manual
```

> [!note]
> 머지 트레인과 함께 이 기능을 사용할 때 `stop` 작업은 [중복 파이프라인을 피하는](../jobs/job_rules.md#avoid-duplicate-pipelines) 경우에만 실행됩니다.

### 일정 시간 후에 환경 중지 {#stop-an-environment-after-a-certain-time-period}

환경이 일정 시간이 지난 후 자동으로 중지되도록 설정할 수 있습니다.

> [!note]
> 리소스 제한으로 인해 환경 중지를 위한 백그라운드 작업이 1시간마다 한 번만 실행됩니다. 이는 환경이 지정된 정확한 시간 후에 중지되지 않을 수 있지만 백그라운드 작업이 만료된 환경을 감지할 때 대신 중지됨을 의미합니다.

`.gitlab-ci.yml` 파일에서 [`environment:auto_stop_in`](../yaml/_index.md#environmentauto_stop_in) 키워드를 지정합니다. 시간 기간을 자연스러운 언어로 지정하세요(예: `1 hour and 30 minutes` 또는 `1 day`). 시간 기간이 경과하면 GitLab은 자동으로 환경을 중지하는 작업을 시작합니다.

다음 예제에서:

- 머지 리퀘스트의 각 커밋은 최신 변경을 환경에 배포하고 만료 기간을 재설정하는 `review_app` 작업을 실행합니다.
- 환경이 1주일 이상 비활성 상태이면 GitLab은 자동으로 `stop_review_app` 작업을 실행하여 환경을 중지합니다.

```yaml
review_app:
  script: deploy-review-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    on_stop: stop_review_app
    auto_stop_in: 1 week
  rules:
    - if: $CI_MERGE_REQUEST_ID

stop_review_app:
  script: stop-review-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  rules:
    - if: $CI_MERGE_REQUEST_ID
      when: manual
```

[`environment:action`](../yaml/_index.md#environmentaction) 키워드를 사용하여 환경이 중지되도록 예약된 시간을 재설정할 수 있습니다. 자세한 정보는 [준비 또는 검증 목적으로 환경에 액세스](#access-an-environment-for-preparation-or-verification-purposes)를 참조하세요.

#### 환경의 예약된 중지 날짜 및 시간 보기 {#view-an-environments-scheduled-stop-date-and-time}

환경이 [지정된 시간 후 중지되도록 예약됨](#stop-an-environment-after-a-certain-time-period)되면 만료 날짜와 시간을 볼 수 있습니다.

환경의 만료 날짜와 시간을 보려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을 선택합니다.
1. 환경의 이름을 선택합니다.

만료 날짜와 시간은 왼쪽 위 모서리에 환경 이름 옆에 표시됩니다.

#### 환경의 예약된 중지 날짜 및 시간 재정의 {#override-an-environments-scheduled-stop-date-and-time}

환경이 [지정된 시간 후 중지되도록 예약됨](#stop-an-environment-after-a-certain-time-period)되면 만료를 재정의할 수 있습니다.

UI에서 환경의 만료를 재정의하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을 선택합니다.
1. 환경 이름을 선택합니다.
1. 오른쪽 위 모서리에서 압정({{< icon name="thumbtack" >}})을 선택합니다.

`.gitlab-ci.yml`에서 환경의 만료를 재정의하려면:

1. 프로젝트의 `.gitlab-ci.yml`을 엽니다.
1. 해당 배포 작업의 `auto_stop_in` 설정을 `auto_stop_in: never`로 업데이트합니다.

`auto_stop_in` 설정이 재정의되고 환경은 수동으로 중지될 때까지 활성 상태로 유지됩니다.

### 오래된 환경 정리 {#clean-up-stale-environments}

{{< history >}}

- GitLab 15.8에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108616) [플래그 사용](../../administration/feature_flags/_index.md) `stop_stale_environments`. 기본적으로 비활성화되어 있습니다.
- GitLab 15.10에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112098)합니다. 기능 플래그 `stop_stale_environments`이 제거되었습니다.

{{< /history >}}

프로젝트에서 오래된 환경을 중지하려는 경우 오래된 환경을 정리합니다.

전제 조건:

- Maintainer 또는 Owner 역할이 있어야 합니다.

오래된 환경을 정리하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을 선택합니다.
1. **환경 정리**를 선택합니다.
1. 오래된 환경을 고려하기 위해 사용할 날짜를 선택합니다.
1. **정리**를 선택합니다.

지정된 날짜 이후로 업데이트되지 않은 활성 환경이 중지됩니다. 보호된 환경은 무시되고 중지되지 않습니다.

### 환경이 중지될 때 파이프라인 작업 실행 {#run-a-pipeline-job-when-environment-is-stopped}

{{< history >}}

- 기능 플래그 `environment_stop_actions_include_all_finished_deployments`은 GitLab 16.9에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/435128). 기본적으로 비활성화되어 있습니다.
- 기능 플래그 `environment_stop_actions_include_all_finished_deployments`은 GitLab 17.0에서 [제거됨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150932).

{{< /history >}}

환경의 배포 작업에서 [`on_stop` 작업](../yaml/_index.md#environmenton_stop)으로 환경의 중지 작업을 정의할 수 있습니다.

환경이 중지되면 최신 완료된 파이프라인의 완료된 배포의 중지 작업이 실행됩니다. 배포 또는 파이프라인은 성공, 취소 또는 실패 상태인 경우 완료됩니다.

전제 조건:

- 배포 및 중지 작업은 동일한 규칙 또는 only/except 구성을 가져야 합니다.
- 중지 작업은 다음 키워드가 정의되어야 합니다:
  - `when` - 다음 중 하나에서 정의:
    - [작업 수준](../yaml/_index.md#when).
    - [규칙 절에서](../yaml/_index.md#rules). `rules` 및 `when: manual`을 사용하는 경우 [`allow_failure: true`](../yaml/_index.md#allow_failure)을 설정하여 작업이 실행되지 않아도 파이프라인이 완료될 수 있도록 해야 합니다.
  - `environment:name`
  - `environment:action`

다음 예제에서:

- `review_app` 작업은 첫 번째 작업이 완료된 후 `stop_review_app` 작업을 호출합니다.
- `stop_review_app`은 `when` 아래에 정의된 것을 기반으로 트리거됩니다. 이 경우 `manual`로 설정되어 있으므로 GitLab UI에서 [수동 작업](../jobs/job_control.md#create-a-job-that-must-be-run-manually)이 필요합니다.
- `GIT_STRATEGY`은 `none`로 설정됩니다. `stop_review_app` 작업이 [자동으로 트리거](#stopping-an-environment)되면 러너가 브랜치 삭제 후 코드를 체크아웃하려고 시도하지 않습니다.

```yaml
review_app:
  stage: deploy
  script: make deploy-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com
    on_stop: stop_review_app

stop_review_app:
  stage: deploy
  variables:
    GIT_STRATEGY: none
  script: make delete-app
  when: manual
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
```

### 환경의 여러 중지 작업 {#multiple-stop-actions-for-an-environment}

{{< history >}}

- GitLab 15.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/358911)합니다. [기능 플래그 `environment_multiple_stop_actions`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86685)이 제거되었습니다.

{{< /history >}}

환경에서 여러 **parallel** 중지 작업을 구성하려면 [`on_stop`](../yaml/_index.md#environmenton_stop) 키워드를 `.gitlab-ci.yml` 파일에 정의된 대로 동일한 `environment`에 대한 여러 [배포 작업](../jobs/_index.md#deployment-jobs)에 걸쳐 지정합니다.

환경이 중지되면 성공한 배포 작업에서만 일치하는 `on_stop` 작업이 병렬로 실행되며 순서는 없습니다.

> [!note]
> 환경의 모든 `on_stop` 작업은 동일한 파이프라인에 속해야 합니다. [다운스트림 파이프라인](../pipelines/downstream_pipelines.md)에서 여러 `on_stop` 작업을 사용하려면 환경 작업을 부모 파이프라인에서 구성해야 합니다. 자세한 정보는 [배포용 다운스트림 파이프라인](../pipelines/downstream_pipelines.md#advanced-example)을 참조하세요.

`test` 환경의 경우 두 가지 배포 작업이 있습니다:

- `deploy-to-cloud-a`
- `deploy-to-cloud-b`

환경이 중지되면 시스템은 `on_stop` 작업 `teardown-cloud-a` 및 `teardown-cloud-b`을 병렬로 실행합니다.

```yaml
deploy-to-cloud-a:
  script: echo "Deploy to cloud a"
  environment:
    name: test
    on_stop: teardown-cloud-a

deploy-to-cloud-b:
  script: echo "Deploy to cloud b"
  environment:
    name: test
    on_stop: teardown-cloud-b

teardown-cloud-a:
  script: echo "Delete the resources in cloud a"
  environment:
    name: test
    action: stop
  when: manual

teardown-cloud-b:
  script: echo "Delete the resources in cloud b"
  environment:
    name: test
    action: stop
  when: manual
```

### `on_stop` 작업을 실행하지 않고 환경 중지 {#stop-an-environment-without-running-the-on_stop-action}

정의된 [`on_stop`](../yaml/_index.md#environmenton_stop) 작업을 실행하지 않고 환경을 중지하려는 경우가 있을 수 있습니다. 예를 들어 [계산 할당량](../pipelines/compute_minutes.md)을 사용하지 않고 많은 환경을 삭제하려고 합니다.

정의된 `on_stop` 작업을 실행하지 않고 환경을 중지하려면 [환경 중지 API](../../api/environments.md#stop-an-environment)를 매개변수 `force=true`으로 실행합니다.

### 환경 삭제 {#delete-an-environment}

환경 및 모든 배포를 제거하려는 경우 환경을 삭제합니다.

전제 조건:

- Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- 환경을 삭제하기 전에 [중지](#stopping-an-environment)해야 합니다.

환경을 삭제하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **운영** > **환경**을 선택합니다.
1. **중지됨** 탭을 선택합니다.
1. 삭제할 환경 옆에서 **환경 삭제**를 선택합니다.
1. 확인 대화에서 **환경 삭제**를 선택합니다.

## 준비 또는 검증 목적으로 환경에 액세스 {#access-an-environment-for-preparation-or-verification-purposes}

{{< history >}}

- GitLab 17.7에서 [업데이트됨](https://gitlab.com/gitlab-org/gitlab/-/issues/437133) - `auto_stop_in`을 `prepare` 및 `access` 작업에 대해 재설정합니다.

{{< /history >}}

검증 또는 준비와 같은 다양한 목적으로 환경에 액세스하는 작업을 정의할 수 있습니다. 이는 배포 생성을 효과적으로 바이패스하므로 CD 워크플로우를 더 정확하게 조정할 수 있습니다.

이렇게 하려면 `action: prepare`, `action: verify` 또는 `action: access`을 작업의 `environment` 섹션에 추가합니다:

```yaml
build:
  stage: build
  script:
    - echo "Building the app"
  environment:
    name: staging
    action: prepare
    url: https://staging.example.com
```

이를 통해 환경 범위 변수에 액세스할 수 있으며 무단 액세스로부터 빌드를 보호하는 데 사용할 수 있습니다. 또한 [오래된 배포 작업 방지](deployment_safety.md#prevent-outdated-deployment-jobs) 기능을 피하는 데 효과적입니다.

환경이 일정 시간 후 중지되도록 구성된 경우 `access` 또는 `prepare` 작업이 있는 작업은 예약된 중지 시간을 재설정합니다. 예약된 시간을 재설정할 때 환경에 대한 가장 최근의 성공한 배포 작업에서 [`environment:auto_stop_in`](../yaml/_index.md#environmentauto_stop_in)을 사용합니다. 예를 들어 가장 최근 배포가 `auto_stop_in: 1 week`을 사용했고 나중에 `action: access`를 가진 작업으로 액세스되면 환경은 액세스 작업이 완료된 후 1주일 후에 중지되도록 다시 예약됩니다.

예약된 중지 시간을 변경하지 않고 환경에 액세스하려면 `verify` 작업을 사용합니다.

## 환경 사고 관리 {#environment-incident-management}

프로덕션 환경은 예기치 않게 중단될 수 있습니다. 이는 제어 범위를 벗어난 이유 때문일 수 있습니다. 예를 들어 외부 의존성, 인프라 또는 인적 오류로 인한 문제로 인해 환경에 심각한 문제가 발생할 수 있습니다. 다음과 같은:

- 종속 클라우드 서비스가 중단됩니다.
- 3rd party 라이브러리가 업데이트되어 애플리케이션과 호환되지 않습니다.
- 누군가 서버의 취약한 끝점에 DDoS 공격을 수행합니다.
- 운영자가 인프라를 잘못 구성합니다.
- 버그가 프로덕션 애플리케이션 코드에 도입됩니다.

[사고 관리](../../operations/incident_management/_index.md)를 사용하여 즉시 주의가 필요한 중요한 문제가 발생할 때 경고를 받을 수 있습니다.

### 환경의 최신 경고 보기 {#view-the-latest-alerts-for-environments}

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[경고 통합을 설정](../../operations/incident_management/integrations.md#configuration)하면 환경 경고가 환경 페이지에 표시됩니다. 심각도가 가장 높은 경고가 표시되므로 즉시 주의가 필요한 환경을 식별할 수 있습니다.

![환경 경고](img/alert_for_environment_v13_4.png)

경고를 트리거한 문제가 해결되면 경고가 제거되고 더 이상 환경 페이지에 표시되지 않습니다.

경고에 [롤백](deployments.md#retry-or-roll-back-a-deployment)이 필요한 경우 환경 페이지에서 배포 탭을 선택하고 롤백할 배포를 선택할 수 있습니다.

### 자동 롤백 {#auto-rollback}

{{< details >}}

- 계층: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

일반적인 지속적 배포 워크플로우에서 CI 파이프라인은 프로덕션에 배포하기 전에 모든 커밋을 테스트합니다. 그러나 문제가 있는 코드가 프로덕션에 도달할 수 있습니다. 예를 들어 논리적으로 올바른 비효율적인 코드도 심각한 성능 저하를 유발하더라도 테스트를 통과할 수 있습니다. 운영자와 SRE는 이러한 문제를 최대한 빨리 포착하기 위해 시스템을 모니터링합니다. 문제가 있는 배포를 찾으면 이전의 안정적인 버전으로 롤백할 수 있습니다.

GitLab 자동 롤백은 [중요 경고](../../operations/incident_management/alerts.md)가 감지될 때 자동으로 롤백을 트리거하여 이 워크플로우를 간소화합니다. GitLab이 롤백에 적절한 환경을 선택하려면 경고에 환경의 이름과 함께 `gitlab_environment_name` 키가 포함되어야 합니다. GitLab은 가장 최근의 성공한 배포를 선택하고 재배포합니다.

GitLab 자동 롤백의 제한 사항:

- 경고가 감지될 때 배포가 실행 중이면 롤백을 건너뜁니다.
- 롤백은 3분마다 한 번만 발생할 수 있습니다. 동시에 여러 경고가 감지되면 롤백은 한 번만 수행됩니다.

GitLab 자동 롤백은 기본적으로 꺼져 있습니다. 이를 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **자동 배포 롤백**을 확장합니다.
1. **자동 롤백 활성화** 확인란을 선택합니다.
1. **변경사항 저장**을 선택합니다.

## 환경 권한 {#environment-permissions}

역할에 따라 공개 및 비공개 프로젝트의 환경과 상호 작용할 수 있습니다.

### 환경 보기 {#view-environments}

- 공개 프로젝트에서는 누구나 비회원을 포함한 환경 목록을 볼 수 있습니다.
- 비공개 프로젝트에서는 환경 목록을 보려면 Reporter, Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

### 환경 생성 및 업데이트 {#create-and-update-environments}

- 새 환경을 생성하거나 기존의 보호되지 않은 환경을 업데이트하려면 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- [보호된 환경](protected_environments.md)의 경우 **배포 허용됨** 목록에 있어야 합니다.

### 환경 중지 및 삭제 {#stop-and-delete-environments}

- 보호되지 않은 환경을 중지하거나 삭제하려면 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- 환경이 보호된 환경이고 액세스 권한이 없으면 환경을 중지하거나 삭제할 수 없습니다.

### 보호된 환경에서 배포 작업 실행 {#run-deployment-jobs-in-protected-environments}

보호된 브랜치에 푸시하거나 병합할 수 있는 경우:

- Reporter, Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

보호된 브랜치에 푸시할 수 없는 경우:

- Reporter 역할의 그룹에 속해야 합니다.

[보호된 환경에 대한 배포 전용 액세스](protected_environments.md#deployment-only-access-to-protected-environments)를 참조하세요.

## 웹 터미널(더 이상 사용되지 않음) {#web-terminals-deprecated}

> [!warning]
> 이 기능은 GitLab 14.5에서 [더 이상 사용되지 않음](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)입니다.

배포 서비스(예: [Kubernetes 통합](../../user/infrastructure/clusters/_index.md))의 도움으로 환경에 배포하는 경우 GitLab이 환경으로 터미널 세션을 열 수 있습니다. 웹 브라우저를 떠나지 않고 문제를 디버깅할 수 있습니다.

웹 터미널은 컨테이너 기반 배포이며, 보통 기본 도구(예: 편집기)가 부족하고 언제든지 중지하거나 다시 시작할 수 있습니다. 이 경우 모든 변경 사항이 손실됩니다. 웹 터미널을 종합적인 온라인 IDE가 아닌 디버깅 도구로 취급합니다.

웹 터미널:

- 프로젝트 Maintainer 및 Owner만 사용할 수 있습니다.
- [활성화되어야 합니다](../../administration/integration/terminal.md).

UI에서 웹 터미널을 보려면 다음 중 하나를 수행하세요:

- **조치** 메뉴에서 **터미널**을 선택합니다:

  ![환경 인덱스의 터미널 버튼](img/environments_terminal_button_on_index_v14_3.png)

- 특정 환경의 페이지에서 오른쪽의 **터미널** ({{< icon name="terminal" >}})을 선택합니다.

버튼을 선택하여 터미널 세션을 설정합니다. 다른 터미널과 같이 작동합니다. 배포로 생성된 컨테이너에 있으므로 다음을 수행할 수 있습니다:

- 셸 명령을 실행하고 실시간으로 응답을 받습니다.
- 로그를 확인합니다.
- 구성 또는 코드 수정을 시도합니다.

동일한 환경에 여러 터미널을 열 수 있습니다. 각각 자신의 셸 세션과 `screen` 또는 `tmux`과 같은 멀티플렉서를 받습니다.

## 관련 항목 {#related-topics}

- [Kubernetes용 대시보드](kubernetes_dashboard.md)
- [배포](deployments.md)
- [보호 환경](protected_environments.md)
- [환경 대시보드](environments_dashboard.md)
- [배포 안정성](deployment_safety.md#restrict-write-access-to-a-critical-environment)

## 문제 해결 {#troubleshooting}

### `action: stop` 작업이 실행되지 않음 {#the-job-with-action-stop-doesnt-run}

경우에 따라 `on_stop` 작업이 구성되어 있음에도 불구하고 환경이 중지되지 않습니다. 이는 `action: stop` 작업이 `stages:` 또는 `needs:` 구성으로 인해 실행 가능한 상태가 아닐 때 발생합니다.

예를 들어:

- 환경은 실패한 작업이 있는 스테이지에서 시작될 수 있습니다. 그러면 이후 스테이지의 작업이 시작되지 않습니다. 환경의 `action: stop` 작업이 이후 스테이지에도 있으면 시작할 수 없고 환경이 삭제되지 않습니다.
- `action: stop` 작업이 아직 완료되지 않은 작업에 종속될 수 있습니다.

`action: stop`을 항상 필요할 때 실행할 수 있도록 보장하려면 다음을 수행할 수 있습니다:

- 두 작업을 동일한 스테이지에 배치합니다:

  ```yaml
  stages:
    - build
    - test
    - deploy

  ...

  deploy_review:
    stage: deploy
    environment:
      name: review/$CI_COMMIT_REF_SLUG
      url: https://$CI_ENVIRONMENT_SLUG.example.com
      on_stop: stop_review

  stop_review:
    stage: deploy
    environment:
      name: review/$CI_COMMIT_REF_SLUG
      action: stop
    when: manual
  ```

- `action: stop` 작업에 [`needs`](../yaml/_index.md#needs) 항목을 추가하여 작업이 스테이지 순서를 벗어나 시작할 수 있도록 합니다:

  ```yaml
  stages:
    - build
    - test
    - deploy
    - cleanup

  ...

  deploy_review:
    stage: deploy
    environment:
      name: review/$CI_COMMIT_REF_SLUG
      url: https://$CI_ENVIRONMENT_SLUG.example.com
      on_stop: stop_review

  stop_review:
    stage: cleanup
    needs:
      - deploy_review
    environment:
      name: review/$CI_COMMIT_REF_SLUG
      action: stop
    when: manual
  ```

### 오류: 작업 `would create an environment with an invalid parameter` {#error-job-would-create-an-environment-with-an-invalid-parameter}

프로젝트가 [동적 환경을 생성](#create-a-dynamic-environment)하도록 구성된 경우 배포 작업에서 이 오류가 발생할 수 있습니다. 동적으로 생성된 매개변수는 환경을 생성하는 데 사용할 수 없기 때문입니다:

```plaintext
This job could not be executed because it would create an environment with an invalid parameter.
```

예를 들어 프로젝트에 다음 `.gitlab-ci.yml`이 있습니다:

```yaml
deploy:
  script: echo
  environment: production/$ENVIRONMENT
```

`$ENVIRONMENT` 변수가 파이프라인에 존재하지 않기 때문에 GitLab은 `production/` 이름의 환경을 생성하려고 시도합니다(이는 [환경 이름 제약 조건](../yaml/_index.md#environmentname)에서 유효하지 않음).

이를 해결하려면 다음 솔루션 중 하나를 사용하세요:

- 배포 작업에서 `environment` 키워드를 제거합니다. GitLab은 이미 유효하지 않은 키워드를 무시하고 있으므로 키워드 제거 후에도 배포 파이프라인은 그대로 유지됩니다.
- 파이프라인에 변수가 존재하는지 확인합니다. [지원되는 변수의 제한](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)을 검토하세요.
- `environment:deployment_tier`이 `.gitlab-ci.yml`에 있으면 값이 지원되는 티어 중 하나인지 확인합니다: `production`, `staging`, `testing`, `development` 또는 `other`.

#### 검토 앱에서 이 오류가 발생하는 경우 {#if-you-get-this-error-on-review-apps}

예를 들어 `.gitlab-ci.yml`에 다음이 있는 경우:

```yaml
review:
  script: deploy review app
  environment: review/$CI_COMMIT_REF_NAME
```

브랜치 이름 `bug-fix!`로 새 머지 리퀘스트를 생성하면 `review` 작업이 `review/bug-fix!` 환경을 생성하려고 합니다. 그러나 `!`은 환경에 대한 유효하지 않은 문자이므로 배포 작업이 환경 없이 실행될 예정이므로 실패합니다.

이를 해결하려면 다음 솔루션 중 하나를 사용하세요:

- `bug-fix`과 같은 유효하지 않은 문자 없이 기능 브랜치를 다시 만듭니다.
- `CI_COMMIT_REF_NAME` [사전 정의된 변수](../variables/predefined_variables.md)를 `CI_COMMIT_REF_SLUG`로 바꿉니다(이는 유효하지 않은 문자를 제거합니다):

  ```yaml
  review:
    script: deploy review app
    environment: review/$CI_COMMIT_REF_SLUG
  ```
