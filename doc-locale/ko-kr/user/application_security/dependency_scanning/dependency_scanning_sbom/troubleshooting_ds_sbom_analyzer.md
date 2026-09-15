---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 종속성 검사 SBOM 분석기 문제 해결
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

종속성 검사 SBOM 분석기로 작업할 때 다음의 문제가 발생할 수 있습니다.

## `403 Forbidden` 오류(사용자 지정 `CI_JOB_TOKEN` 사용 시) {#403-forbidden-error-when-you-use-a-custom-ci_job_token}

종속성 검사 SBOM API가 스캔 업로드 또는 다운로드 단계에서 `403 Forbidden` 오류를 반환할 수 있습니다.

이 현상은 종속성 검사 SBOM API가 인증을 위해 기본 `CI_JOB_TOKEN`을(를) 요구하기 때문에 발생합니다. `CI_JOB_TOKEN` 변수를 사용자 지정 토큰(프로젝트 액세스 토큰 또는 개인 액세스 토큰 등)으로 재정의하면 사용자 지정 토큰에 `api` 범위가 있더라도 API가 요청을 제대로 인증할 수 없습니다.

이 문제를 해결하려면 다음 중 하나를 수행하세요:

- 권장됨. `CI_JOB_TOKEN` 재정의를 제거하세요. 사전 정의된 변수를 재정의하면 예기치 않은 동작이 발생할 수 있습니다. 자세한 내용은 [CI/CD 변수](../../../../ci/variables/_index.md#use-pipeline-variables)를 참조하세요.
- 다른 변수 이름을 사용하세요. 파이프라인에서 다른 목적으로 사용자 지정 토큰을 사용해야 하는 경우 `CUSTOM_ACCESS_TOKEN`과 같은 다른 CI/CD 변수에 저장하고 `CI_JOB_TOKEN`를 재정의하지 마세요.

GitLab은 종속성 검사 API 엔드포인트에 대한 [세분화된 작업 권한](../../../../ci/jobs/fine_grained_permissions.md)을 지원하지 않지만 [이슈 578850](https://gitlab.com/gitlab-org/gitlab/-/issues/578850)은 이 기능을 추가할 것을 제안합니다.

## 경고: `grep: command not found` {#warning-grep-command-not-found}

분석기 이미지는 이미지의 공격 표면을 줄이기 위해 최소한의 종속성을 포함합니다. 결과적으로 다른 이미지에서 일반적으로 발견되는 `grep` 같은 유틸리티가 이미지에서 누락됩니다. 이로 인해 `/usr/bin/bash: line 3: grep: command not found` 같은 경고가 작업 로그에 나타날 수 있습니다. 이 경고는 분석기의 결과에 영향을 주지 않으며 무시해도 됩니다.

## 규정 준수 프레임워크 호환성 {#compliance-framework-compatibility}

GitLab Self-Managed 인스턴스에서 SBOM 기반 종속성 검사를 사용할 때 규정 준수 프레임워크와의 호환성 고려 사항이 있습니다:

- GitLab.com: GitLab.com: "종속성 검사 실행 중" 규정 준수 제어는 SBOM 기반 종속성 검사에서 올바르게 작동합니다.
- GitLab Self-Managed 18.4부터: "종속성 검사 실행 중" 규정 준수 제어는 SBOM 기반 종속성 검사(`DS_ENFORCE_NEW_ANALYZER: 'true'`)를 사용할 때 기존 `gl-dependency-scanning-report.json` 결과물이 생성되지 않기 때문에 실패할 수 있습니다.

Self-Managed 인스턴스용 해결 방법: "종속성 검사 실행 중" 제어가 필요한 규정 준수 프레임워크 검사를 통과해야 하는 경우 `v2` 템플릿(`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`)을 사용할 수 있으며, 이 템플릿은 SBOM과 종속성 검사 보고서를 모두 생성합니다.

규정 준수 제어에 대한 자세한 내용은 [GitLab 규정 준수 제어](../../../compliance/compliance_frameworks/_index.md#gitlab-compliance-controls)를 참조하세요.

## 확인 작업이 실패하지만 종속성 검사가 계속 실행됨 {#resolution-job-fails-but-dependency-scanning-still-runs}

확인 작업이 자동으로 실행되므로 `allow_failure: true`을(를) 설정합니다. 확인 작업이 실패하면 `dependency-scanning` 작업이 계속 실행됩니다. 잠금 파일이 리포지토리에 커밋되었는지 여부에 따라 스캔이 커밋된 파일을 사용하거나 활성화된 경우 [매니페스트 폴백](_index.md#manifest-fallback)으로 대체됩니다.

사용자의 사용 사례가 지원되는지 확인하려면 [알려진 제한 사항](_index.md#dependency-resolution-limitations)을 참조하세요.

확인 실패를 조사하려면 실패한 확인 작업의 CI/CD 작업 로그를 확인하세요. 작업 로그에는 DS 분석기 서비스 컨테이너 실행의 출력과 빌드 도구 명령의 출력이 포함됩니다. 서비스 작업 로그가 표시되지 않으면 `CI_DEBUG_SERVICES`을(를) `"true"`로 설정하여 [서비스 컨테이너 작업 로그 캡처](../../../../ci/services/_index.md#capturing-service-container-logs)할 수 있습니다.

필요한 경우 [종속성 검사 확인을 비활성화](_index.md#disable-dependency-resolution)하고 수동으로 생성된 잠금 파일을 대신 사용할 수 있습니다.

## 종속성 검사 작업이 성공하지만 보고서를 생성하지 않음 {#dependency-scanning-job-succeeds-but-produces-no-reports}

종속성 검사 작업이 성공적으로 완료되었지만 SBOM 또는 종속성 검사 보고서 결과물을 생성하지 않으면 프로젝트에 [지원되는 파일](_index.md#supported-languages-and-files)이 포함되어 있지 않을 가능성이 높습니다.

CI/CD 작업 로그에서 다음과 유사한 경고 메시지를 확인하세요:

```plaintext
No compatible file found in <directory>.
```

이 문제를 해결하려면 지원되는 잠금 파일 또는 종속성 그래프 내보내기를 프로젝트에 추가하세요. 지침은 [잠금 파일 또는 종속성 그래프 내보내기 수동 생성](_index.md#create-lockfile-or-dependency-graph-export-manually)을 참조하세요.

## `DS_SKIP_IF_NO_SUPPORTED_FILES`이 설정되면 종속성 검사 작업이 실행되지 않음 {#dependency-scanning-job-does-not-run-when-ds_skip_if_no_supported_files-is-set}

`DS_SKIP_IF_NO_SUPPORTED_FILES`이(가) `"true"`로 설정되고 `dependency-scanning` 작업이 파이프라인에 나타나지 않으면 [지원되는 파일](_index.md#supported-languages-and-files)이 프로젝트에서 감지되지 않았습니다.

종속성 검사 [확인](_index.md#dependency-resolution) 작업을 트리거하는 일부 파일은 지원되지 않기 때문에 종속성 검사 작업을 트리거하지 않을 수 있습니다. 예를 들어 `settings.gradle`, `setup.cfg`, `pyproject.toml`, 또는 `requirements.in`는 직접 지원되지 않습니다.

이 문제를 해결하려면 다음 중 하나를 수행하세요:

- `DS_SKIP_IF_NO_SUPPORTED_FILES`을(를) `"false"`로 설정하거나 설정하지 않은 상태로 두어 종속성 검사 작업이 무조건 실행되도록 하세요.
- 리포지토리에 [지원되는 파일](_index.md#supported-languages-and-files)을(를) 커밋하세요(예: 생성된 잠금 파일 또는 종속성 그래프 내보내기).

## 오류: `failed to verify certificate: x509: certificate signed by unknown authority` {#error-failed-to-verify-certificate-x509-certificate-signed-by-unknown-authority}

종속성 검사 분석기가 호스트에 연결할 때 다음 오류가 발생할 수 있습니다. 이 오류의 원인은 종속성 검사 분석기가 사용하는 인증서가 호스트에서 신뢰되지 않기 때문입니다.

```plaintext
failed to verify certificate: x509: certificate signed by unknown authority
```

이 문제를 해결하려면 `ADDITIONAL_CA_CERT_BUNDLE` CI/CD 변수에 자체 서명 인증서를 제공하세요. 이 인증서는 종속성 검사 분석기가 호스트에 연결할 때 사용됩니다.

`ADDITIONAL_CA_CERT_BUNDLE` 환경 변수의 값은 인증서 자체여야 합니다:

```yaml
include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

dependency-scanning:
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      <...>
      -----END CERTIFICATE-----
  before_script:
    - echo "$ADDITIONAL_CA_CERT_BUNDLE" > /tmp/cacert.pem
    - export SSL_CERT_FILE="/tmp/cacert.pem"
```

## 머지 리퀘스트 파이프라인에서만 종속성 검사가 실행되고 다른 작업은 건너뜀으로 표시됨 {#only-dependency-scanning-runs-in-merge-request-pipelines-other-jobs-appear-skipped}

기본적으로 `Dependency-Scanning.v2.gitlab-ci.yml` 템플릿은 머지 리퀘스트 파이프라인에서 종속성 검사 작업을 실행합니다. 프로젝트의 다른 작업에 머지 리퀘스트 파이프라인을 사용하지 않는 경우, 머지 리퀘스트 파이프라인에는 종속성 검사 작업만 표시되고 다른 모든 작업은 별도의 브랜치 파이프라인에서 실행됩니다. 이 동작을 비활성화하려면 [종속성 검사용 MR 파이프라인 비활성화](_index.md#disable-merge-request-pipelines-for-dependency-scanning)를 참조하세요.
