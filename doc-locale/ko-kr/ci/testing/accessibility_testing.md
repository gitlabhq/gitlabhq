---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 접근성 테스트
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

애플리케이션이 웹 인터페이스를 제공하는 경우 [GitLab CI/CD](../_index.md)를 사용하여 보류 중인 코드 변경의 접근성 영향을 확인할 수 있습니다.

[Pa11y](https://pa11y.org/)는 웹 사이트의 접근성을 측정하기 위한 무료 오픈 소스 도구입니다. GitLab은 Pa11y를 [CI/CD 작업 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Verify/Accessibility.gitlab-ci.yml)에 통합합니다. `a11y` 작업은 정의된 웹 페이지 세트를 분석하고 접근성 위반, 경고 및 공지사항을 `accessibility`이라는 파일에 보고합니다.

Pa11y는 [WCAG 2.1 규칙](https://www.w3.org/TR/WCAG21/#new-features-in-wcag-2-1)을 사용합니다.

## 접근성 머지 리퀘스트 위젯 {#accessibility-merge-request-widget}

GitLab은 머지 리퀘스트 위젯 영역에 **Accessibility Report**를 표시합니다:

![접근성 머지 리퀘스트 위젯](img/accessibility_mr_widget_v13_0.png)

## 접근성 테스트 구성 {#configure-accessibility-testing}

GitLab CI/CD를 사용하여 [GitLab 접근성 Docker 이미지](https://gitlab.com/gitlab-org/ci-cd/accessibility)로 Pa11y를 실행할 수 있습니다.

`a11y` 작업을 정의하려면:

1. GitLab 설치에서 [`Accessibility.gitlab-ci.yml` 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Verify/Accessibility.gitlab-ci.yml)을 [포함](../yaml/_index.md#includetemplate)합니다.
1. 다음 구성을 `.gitlab-ci.yml` 파일에 추가합니다.

   ```yaml
   stages:
     - accessibility

   variables:
     a11y_urls: "https://about.gitlab.com https://gitlab.com/users/sign_in"

   include:
     - template: "Verify/Accessibility.gitlab-ci.yml"
   ```

1. `a11y_urls` 변수를 사용자 지정하여 Pa11y로 테스트할 웹 페이지의 URL 목록을 작성합니다.

CI/CD 파이프라인의 `a11y` 작업은 다음 파일을 생성합니다:

- `a11y_urls` 변수에 나열된 각 URL당 하나의 HTML 보고서입니다.
- 수집된 보고서 데이터를 포함하는 하나의 파일입니다. 이 파일의 이름은 `gl-accessibility.json`입니다.

[브라우저에서 작업 아티팩트를 볼 수 있습니다](../jobs/job_artifacts.md#download-job-artifacts).

> [!note]
> 템플릿에서 제공하는 작업 정의는 Kubernetes를 지원하지 않습니다.

CI 구성을 통해 Pa11y에 구성을 전달할 수 없습니다. 구성을 변경하려면 CI 파일에서 템플릿의 복사본을 편집합니다.
