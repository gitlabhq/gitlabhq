---
type: reference, howto
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 분석기 활성화
---

스캔을 실행하려면:

- 스캔을 실행하기 위한 [요구 사항](../_index.md) 조건을 읽으세요.
- CI/CD 파이프라인에서 [DAST 작업](#create-a-dast-cicd-job)을 생성합니다.
- 응용 프로그램이 필요한 경우 [인증](authentication.md)을 사용자로 수행합니다.

작업은 CI/CD 템플릿 파일의 `image` 키워드로 정의된 Docker 컨테이너에서 실행됩니다. 작업을 실행하면 는 `DAST_TARGET_URL` 변수로 지정된 대상 응용 프로그램에 연결되고 포함된 브라우저를 사용하여 사이트를 크롤링합니다.

## CI/CD 작업 생성 {#create-a-dast-cicd-job}

{{< history >}}

- 이 템플릿이 DAST_VERSION으로 업데이트되었습니다: GitLab 16.0의 4입니다.
- 이 템플릿이 [업데이트되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151910) DAST_VERSION: GitLab 17.0의 5입니다.
- 이 템플릿이 [업데이트되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188703) DAST_VERSION: GitLab 18.0의 6입니다.

{{< /history >}}

응용 프로그램에 스캔을 추가하려면 GitLab CI/CD 템플릿 파일에 정의된 작업을 사용합니다. 템플릿에 대한 업데이트는 GitLab 업그레이드와 함께 제공되어 개선 사항 및 추가 사항을 활용할 수 있습니다.

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

CI/CD 작업을 생성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인 편집기**를 선택합니다.

   `.gitlab-ci.yml` 파일이 없으면 **Configure pipeline**을 선택한 다음 예제 콘텐츠를 삭제합니다.
1. 적절한 CI/CD 템플릿을 포함합니다:

   - [`DAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.gitlab-ci.yml): CI/CD 템플릿의 안정적인 버전입니다.
   - [`DAST.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.latest.gitlab-ci.yml): 템플릿의 최신 버전입니다.

   > [!warning]
   > 템플릿의 최신 버전에는 주요 변경 사항이 포함될 수 있습니다. 최신 템플릿에서만 제공되는 기능이 필요하지 않으면 안정적인 템플릿을 사용합니다.

1. GitLab CI/CD 스테이지 구성에 `dast` 스테이지를 추가합니다.
1. 다음 방법 중 하나를 사용하여 에서 스캔할 URL을 정의합니다:

   - `DAST_TARGET_URL` [CI/CD 변수](../../../../../ci/yaml/_index.md#variables)를 설정합니다. 설정된 경우 이 값이 우선입니다.

   - 프로젝트의 루트에서 `environment_url.txt` 파일에 URL을 추가하는 것은 동적 환경에서 테스트하기에 좋습니다. 를 GitLab CI/CD 파이프라인 중에 동적으로 생성된 응용 프로그램에 대해 실행하려면 응용 프로그램 URL을 `environment_url.txt` 파일에 작성합니다. 는 자동으로 URL을 읽어 스캔 대상을 찾습니다.

     Auto DevOps CI YAML의 [이 예제](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)를 볼 수 있습니다.

예를 들어:

```yaml
stages:
  - dast

include:
  - template: Security/DAST.gitlab-ci.yml

dast:
  variables:
    DAST_TARGET_URL: "https://example.com"
    DAST_AUTH_USERNAME: "test_user"
    DAST_AUTH_USERNAME_FIELD: "name:user[login]"
    DAST_AUTH_PASSWORD_FIELD: "name:user[password]"
```

`DAST_TARGET_URL`을 정의하거나 작업이 성공적으로 실행되도록 `environment_url.txt` 파일을 생성해야 합니다.

### 네트워크 연결 {#network-connectivity}

러너는 대상 응용 프로그램 URL에 연결되어야 합니다. 응용 프로그램이 비표준 포트를 사용하는 경우 URL에 포함시킵니다.

## 분석기를 활성화한 후 {#after-you-enable-the-analyzer}

파이프라인이 실행되면 작업은:

1. 응용 프로그램에 연결합니다.
1. Chromium 브라우저를 시작하여 사이트를 크롤링합니다.
1. 검색된 페이지에서 보안 검사를 수행합니다.

### 인증 구성 {#configure-authentication}

응용 프로그램이 사용자를 로그인하도록 요구하는 경우 스캔 전에 를 인증하도록 구성합니다. 인증 없이는 는 공개적으로 접근 가능한 페이지만 스캔할 수 있습니다.

인증을 구성하려면 [인증](authentication.md)을 참조하세요.

### 크롤 범위 확인 {#verify-crawl-coverage}

첫 스캔이 완료된 후 가 응용 프로그램 페이지를 올바르게 검색하고 있는지 확인합니다.

크롤 결과를 시각화하려면:

- `DAST_CRAWL_GRAPH` [변수](variables.md)를 사용하여 크롤 그래프를 활성화합니다.
- 그래프를 검토하여 누락된 페이지 또는 탐색 경로를 식별합니다.
- 페이지가 누락된 경우 [스캔 범위](customize_settings.md#managing-scope)를 조정합니다.

### 문제 해결 {#troubleshooting}

문제가 발생하면:

- 설정 문제는 [DAST 설정](../troubleshooting.md#setting-up-dast)을 참조하세요.
- 자세한 진단 정보는 [진단 로그](../troubleshooting.md#diagnostic-logs)를 참조하세요.
- 연결 문제 해결은 [러너가 대상 응용 프로그램에 연결할 수 없음](../troubleshooting.md#runner-cannot-connect-to-target-application)을 참조하세요.
