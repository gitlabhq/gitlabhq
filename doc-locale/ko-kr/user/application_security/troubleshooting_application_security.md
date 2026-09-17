---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 애플리케이션 보안 문제 해결
description: 더 자세한 로깅을 포함하여 GitLab 애플리케이션 보안 기능을 문제 해결하는 방법입니다.
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

애플리케이션 보안 기능을 사용할 때 다음과 같은 문제가 발생할 수 있습니다.

## 로깅 수준 {#logging-level}

GitLab 분석기에서 출력하는 로그의 상세도는 `SECURE_LOG_LEVEL` 환경 변수에 의해 결정됩니다. 이 로깅 수준 이상의 메시지가 출력됩니다.

심각도가 가장 높은 것부터 낮은 것까지, 로깅 수준은 다음과 같습니다:

- `fatal`
- `error`
- `warn`
- `info` (기본값)
- `debug`

### 디버그 수준 로깅 활성화 {#turn-on-debug-level-logging}

> [!warning]
> 디버그 로깅은 심각한 보안 위험이 될 수 있습니다. 출력에는 환경 변수 및 작업에 사용할 수 있는 기타 비밀의 내용이 포함될 수 있습니다. 출력은 GitLab 서버에 업로드되며 작업 로그에 표시됩니다.

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.

디버그 수준 로깅을 활성화하려면 `.gitlab-ci.yml` 파일에 다음을 추가합니다:

```yaml
variables:
  SECURE_LOG_LEVEL: "debug"
```

이는 모든 GitLab 분석기에 모든 메시지를 출력하도록 지시합니다. 자세한 내용은 [로깅 수준](#logging-level)을 참조합니다.

<!--
The below subsection(`### Secure job failing with exit code 1`) documentation URL is referred
in the [`/gitlab-org/security-products/analyzers/command`](https://gitlab.com/gitlab-org/security-products/analyzers/command/-/blob/main/command.go#L19)
repository. If this section/subsection changes, ensure to update the corresponding URL in the mentioned
repository.
-->

## 종료 코드 1로 인한 보안 작업 실패 {#secure-job-failing-with-exit-code-1}

보안 작업이 실패하고 원인이 불명확한 경우:

1. [디버그 수준 로깅](#turn-on-debug-level-logging)을 활성화합니다.
1. 작업을 실행합니다.
1. 작업의 출력을 검토합니다.
1. `debug` 로그 수준을 제거하여 기본 `info` 값으로 돌아갑니다.

## 오래된 보안 보고서 {#outdated-security-reports}

머지 리퀘스트에 대해 생성된 보안 보고서가 오래되면, 머지 리퀘스트는 보안 스캔 보고서에 경고 메시지를 표시하고 적절한 조치를 취하도록 요청합니다.

이는 두 가지 시나리오에서 발생할 수 있습니다:

- [소스 브랜치가 대상 브랜치보다 뒤에 있습니다](#source-branch-is-behind-the-target-branch).
- [대상 브랜치 보안 보고서가 최신이 아닙니다](#target-branch-security-report-is-out-of-date).

### 소스 브랜치가 대상 브랜치보다 뒤에 있음 {#source-branch-is-behind-the-target-branch}

보안 보고서는 대상 브랜치와 소스 브랜치 사이의 가장 최근 공통 선조 커밋이 대상 브랜치의 가장 최근 커밋이 아닐 때 오래될 수 있습니다.

이 문제를 해결하려면 대상 브랜치의 변경 사항을 포함하기 위해 리베이스하거나 병합합니다.

### 대상 브랜치 보안 보고서가 최신이 아님 {#target-branch-security-report-is-out-of-date}

이는 실패한 작업이나 새로운 권고안을 포함한 여러 이유로 발생할 수 있습니다. 머지 리퀘스트에서 보안 보고서가 최신이 아님을 보여주면, 대상 브랜치에서 새 파이프라인을 실행해야 합니다. **new pipeline**을 선택하여 새 파이프라인을 실행합니다.

## 경고 메시지 `… report.json: no matching files` 받기 {#getting-warning-messages--reportjson-no-matching-files}

> [!warning]
> 디버그 로깅은 심각한 보안 위험이 될 수 있습니다. 출력에는 환경 변수 및 작업에 사용할 수 있는 기타 비밀의 내용이 포함될 수 있습니다. 출력은 GitLab 서버에 업로드되며 작업 로그에 표시됩니다.

이 메시지는 종종 [`No files to upload` 오류](../../ci/jobs/job_artifacts_troubleshooting.md#error-message-no-files-to-upload)로 뒤따르며, JSON 보고서가 생성되지 않은 이유를 나타내는 다른 오류 또는 경고 앞에 있습니다. 이러한 메시지에 대해 전체 작업 로그를 확인합니다. 이러한 메시지를 찾을 수 없으면, `SECURE_LOG_LEVEL: "debug"`을(를) [사용자 정의 CI/CD 변수](../../ci/variables/_index.md#for-a-project)로 설정한 후 실패한 작업을 다시 시도합니다. 이는 추가 정보를 제공하여 추가 조사를 할 수 있습니다.

## 오류 메시지 `sast job: config key may not be used with 'rules': only/except` 받기 {#getting-error-message-sast-job-config-key-may-not-be-used-with-rules-onlyexcept}

[포함](../../ci/yaml/_index.md#includetemplate)할 때 `.gitlab-ci.yml` 템플릿(예: [`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml))을 사용하면, GitLab CI/CD 구성에 따라 다음 오류가 발생할 수 있습니다:

```plaintext
Unable to run pipeline

    jobs:sast config key may not be used with `rules`: only/except
```

이 오류는 포함된 작업의 `rules` 구성이 [재정의](sast/_index.md#override-sast-jobs)되었을 때 나타나며, [`only` 또는 `except` 구문과 함께 더 이상 사용되지 않습니다.](../../ci/yaml/deprecated_keywords.md#only--except) 이 문제를 해결하려면 다음 중 하나를 수행해야 합니다:

- [`only/except` 구문을 `rules`로 전환합니다](#transitioning-your-onlyexcept-syntax-to-rules).
- (임시로) [템플릿을 더 이상 사용되지 않는 버전으로 고정합니다](#pin-your-templates-to-the-deprecated-versions)

자세한 내용은 [SAST 작업 재정의](sast/_index.md#override-sast-jobs)를 참조합니다.

### `only/except` 구문을 `rules`로 전환 {#transitioning-your-onlyexcept-syntax-to-rules}

템플릿을 재정의하여 작업 실행을 제어할 때, [`only` 또는 `except`](../../ci/yaml/deprecated_keywords.md#only--except)의 이전 인스턴스는 더 이상 호환되지 않으며 [`rules` 구문](../../ci/yaml/_index.md#rules)으로 전환해야 합니다.

재정의가 작업을 `main`에서만 실행하도록 제한하려는 경우, 이전 구문은 다음과 유사합니다:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is only executed on main or merge requests
spotbugs-sast:
  only:
    refs:
      - main
      - merge_requests
```

이전 구성을 새 `rules` 구문으로 전환하려면, 재정의는 다음과 같이 작성됩니다:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is only executed on main or merge requests
spotbugs-sast:
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_MERGE_REQUEST_ID
```

재정의가 작업을 브랜치에서만 실행하도록 제한하려는 경우, 태그는 아닙니다. 이전 구문은 다음과 유사합니다:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is not executed on tags
spotbugs-sast:
  except:
    - tags
```

새 `rules` 구문으로 전환하려면, 재정의는 다음과 같이 다시 작성됩니다:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

# Ensure that the scanning is not executed on tags
spotbugs-sast:
  rules:
    - if: $CI_COMMIT_TAG == null
```

자세한 내용은 [`rules`](../../ci/yaml/_index.md#rules)를 참조하세요.

### 템플릿을 더 이상 사용되지 않는 버전으로 고정 {#pin-your-templates-to-the-deprecated-versions}

최신 지원을 보장하려면 [`rules`](../../ci/yaml/_index.md#rules)로 마이그레이션합니다.

CI/CD 구성을 즉시 업데이트할 수 없으면, 이전 템플릿 버전으로 고정하는 것과 관련된 여러 해결 방법이 있습니다. 예를 들어:

  ```yaml
  include:
    remote: 'https://gitlab.com/gitlab-org/gitlab/-/raw/12-10-stable-ee/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml'
  ```

또한 버전이 지정된 레거시 템플릿을 포함하는 전용 프로젝트를 사용할 수 있습니다. 이는 오프라인 설정에서 사용하거나 [Auto DevOps](../../topics/autodevops/_index.md)를 사용하려는 모든 사용자에게 사용할 수 있습니다.

지침은 [레거시 템플릿 프로젝트](https://gitlab.com/gitlab-org/auto-devops-v12-10)에서 확인할 수 있습니다.

### 취약성이 발견되지만 작업이 성공합니다. 대신 파이프라인이 실패하도록 하려면 어떻게 해야 합니까? {#vulnerabilities-are-found-but-the-job-succeeds-how-can-you-have-a-pipeline-fail-instead}

이러한 경우, 작업이 성공하는 것이 기본 동작입니다. 작업의 상태는 분석기 자체의 성공 또는 실패를 나타냅니다. 분석기 결과는 [작업 로그](../../ci/jobs/job_logs.md#expand-and-collapse-job-log-sections), [머지 리퀘스트 보고서](../project/merge_requests/reports.md) 또는 [보안 대시보드](security_dashboard/_index.md)에 표시됩니다.

## 오류: 작업 `is used for configuration only, and its script should not be executed` {#error-job-is-used-for-configuration-only-and-its-script-should-not-be-executed}

`Security/Dependency-Scanning.gitlab-ci.yml` 및 `Security/SAST.gitlab-ci.yml` 템플릿은 `sast` 또는 `dependency_scanning` 작업을 `rules` 속성을 설정하여 활성화하면, `(job) is used for configuration only, and its script should not be executed` 오류로 실패합니다.

`sast` 또는 `dependency_scanning` 스탠자는 `variables` 또는 `stage`을(를) 변경하는 것과 같이 모든 SAST 또는 종속성 검사를 변경하는 데 사용할 수 있지만, 공유 `rules`을(를) 정의하는 데는 사용할 수 없습니다.

[확장성 개선을 위해 열려 있는 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/218444)가 있습니다. 이슈를 투표하여 우선순위 결정을 지원할 수 있으며, [기여는 환영합니다](https://about.gitlab.com/community/contribute/).

## 빈 취약성 보고서, 종속성 목록 페이지 {#empty-vulnerability-report-dependency-list-pages}

파이프라인에 `allow_failure: false` 옵션이 있는 작업과 함께 수동 단계가 있으며, 이 작업이 완료되지 않으면, GitLab은 보안 보고서의 데이터로 나열된 페이지를 채울 수 없습니다. 이 경우, [취약성 보고서](vulnerability_report/_index.md) 및 [종속성 목록](dependency_list/_index.md) 페이지가 비어 있습니다. 이러한 보안 페이지는 파이프라인의 수동 단계에서 작업을 실행하여 채울 수 있습니다.

[이 시나리오를 처리하기 위해 열려 있는 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/346843)가 있습니다. 이슈를 투표하여 우선순위 결정을 지원할 수 있으며, [기여는 환영합니다](https://about.gitlab.com/community/contribute/).
