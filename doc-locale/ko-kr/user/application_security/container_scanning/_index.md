---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 컨테이너 검사
description: "이미지 취약성 스캔, 구성, 사용자 지정 및 보고."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

컨테이너 이미지의 보안 취약성은 애플리케이션 수명 주기 전반에 걸쳐 위험을 발생합니다. 컨테이너 스캐닝은 이러한 위험을 본격적인 프로덕션 환경에 도달하기 전에 조기에 감지합니다. 기본 이미지 또는 운영 체제 패키지에 취약성이 나타나면 컨테이너 스캐닝이 이를 식별하고 수정할 수 있는 수정 경로를 제공합니다.

- <i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [컨테이너 스캐닝 - Advanced Security Testing](https://www.youtube.com/watch?v=C0jn2eN5MAs)을 참조하세요.
- <i class="fa-youtube-play" aria-hidden="true"></i> 비디오 연습을 보려면 [GitLab을 사용하여 컨테이너 스캐닝 설정하는 방법](https://youtu.be/h__mcXpil_4?si=w_BVG68qnkL9x4l1)을 참조하세요.
- 소개 자습서는 [취약성에 대한 Docker 컨테이너 검사](../../../tutorials/container_scanning/_index.md)를 참조하세요.

컨테이너 스캐닝은 종종 SCA(Software Composition Analysis)의 일부로 간주됩니다. SCA는 코드가 사용하는 항목을 검사하는 측면을 포함할 수 있습니다. 이러한 항목에는 일반적으로 직접 작성한 코드보다는 외부 소스에서 가져온 애플리케이션 및 시스템 종속성이 포함됩니다.

GitLab은 컨테이너 스캐닝과 종속성 검사를 모두 제공하여 이러한 모든 종속성 유형에 대한 범위를 보장합니다. 위험 영역을 최대한 많이 포함하려면 모든 보안 스캐너를 사용하세요. 이러한 기능의 비교는 [종속성 검사와 컨테이너 검사 비교](../comparison_dependency_and_container_scanning.md)를 참조하세요.

GitLab은 [Trivy](https://github.com/aquasecurity/trivy) 보안 스캐너와 통합하여 컨테이너에서 취약성 정적 분석을 수행합니다.

> [!warning]
> Grype 분석기는 GitLab [지원 현황](https://about.gitlab.com/support/statement-of-support/#version-support)에 설명된 대로 제한된 수정을 제외하고는 더 이상 유지 관리되지 않습니다. Grype 분석기 이미지의 기존 현재 주요 버전은 GitLab 19.0까지 최신 자문 데이터베이스 및 운영 체제 패키지로 계속 업데이트되며, 이후 분석기가 작동 중단됩니다.

## 기능 {#features}

| 기능 | Free 및 Premium에서 | Ultimate |
|----------|---------------------|-------------|
| 설정 사용자 지정([변수](#available-cicd-variables), [재정의](#overriding-the-container-scanning-template), [오프라인 환경 지원](#offline-environment) 등) | {{< yes >}} | {{< yes >}} |
| [JSON 보고서 보기](#reports-json-format)를 CI 작업 아티팩트로 | {{< yes >}} | {{< yes >}} |
| [CycloneDX SBOM JSON 보고서](#cyclonedx-software-bill-of-materials)를 CI 작업 아티팩트로 생성 | {{< yes >}} | {{< yes >}} |
| GitLab UI에서 MR을 통해 컨테이너 스캐닝을 활성화하는 기능 | {{< yes >}} | {{< yes >}} |
| [UBI 이미지 지원](#fips-enabled-images) | {{< yes >}} | {{< yes >}} |
| Trivy 지원 | {{< yes >}} | {{< yes >}} |
| [수명 종료 운영 체제 감지](#end-of-life-operating-system-detection) | {{< yes >}} | {{< yes >}} |
| GitLab 자문 데이터베이스 포함 | GitLab [advisories-communities](https://gitlab.com/gitlab-org/advisories-community/) 프로젝트의 시간 지연 콘텐츠로 제한 | 예 - [Gemnasium DB](https://gitlab.com/gitlab-org/security-products/gemnasium-db)의 모든 최신 콘텐츠 |
| CI 파이프라인 작업의 머지 리퀘스트 및 보안 탭에 보고서 데이터 표시 | {{< no >}} | {{< yes >}} |
| [취약성 솔루션(자동 수정)](#solutions-for-vulnerabilities-auto-remediation) | {{< no >}} | {{< yes >}} |
| [취약성 허용 목록](#vulnerability-allowlisting) 지원 | {{< no >}} | {{< yes >}} |
| [종속성 목록 페이지에 액세스](../dependency_list/_index.md) | {{< no >}} | {{< yes >}} |

## 시작하기 {#getting-started}

CI/CD 파이프라인에서 컨테이너 스캐닝 분석기를 활성화합니다. 파이프라인이 실행되면 애플리케이션이 종속된 이미지가 취약성을 검사합니다. CI/CD 변수를 사용하여 컨테이너 스캐닝을 사용자 지정할 수 있습니다.

전제 조건:

- `.gitlab-ci.yml` 파일에서 테스트 스테이지가 필요합니다.
- 자체 관리형 러너를 사용하는 경우 Linux/amd64에서 `docker` 또는 `kubernetes` 실행기가 있는 러너가 필요합니다. GitLab.com의 인스턴스 러너를 사용하는 경우 기본적으로 활성화됩니다.
- [지원되는 배포](#supported-distributions)와 일치하는 이미지입니다.
- [Docker 이미지 빌드 및 푸시](../../packages/container_registry/build_and_push_images.md#use-gitlab-cicd)를 프로젝트의 컨테이너 레지스트리로 수행합니다.
- 타사 컨테이너 레지스트리를 사용하는 경우 CI/CD 변수 `CS_REGISTRY_USER` 및 `CS_REGISTRY_PASSWORD`를 사용하여 인증 자격 증명을 제공해야 할 수 있습니다. 이러한 변수를 사용하는 방법에 대한 자세한 내용은 [프라이빗 외부 레지스트리 인증](#authenticate-to-private-external-registry)을 참조하세요.

분석기를 활성화하려면 다음 중 하나를 수행합니다:

- Auto DevOps를 활성화합니다. 여기에는 종속성 검사가 포함됩니다.
- 사전 구성된 머지 리퀘스트를 사용합니다.
- 컨테이너 스캐닝을 적용하는 [검사 실행 정책](../policies/scan_execution_policies.md)을 생성합니다.
- `.gitlab-ci.yml` 파일을 수동으로 편집합니다.

### 사전 구성된 머지 리퀘스트 {#use-a-preconfigured-merge-request}

이 방법은 `.gitlab-ci.yml` 파일에 컨테이너 스캐닝 템플릿을 포함하는 머지 리퀘스트를 자동으로 준비합니다. 그런 다음 머지 리퀘스트를 병합하여 컨테이너 스캐닝을 활성화합니다.

> [!note]
> 이 방법은 기존 `.gitlab-ci.yml` 파일이 없거나 최소 구성 파일이 있을 때 가장 잘 작동합니다. 복잡한 GitLab 구성 파일이 있는 경우 구문 분석에 실패하고 오류가 발생할 수 있습니다. 이 경우 수동 방법을 대신 사용하십시오.

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- `test` 스테이지가 `.gitlab-ci.yml` 파일에 있습니다.
- 자체 관리형 러너를 사용하는 경우 Linux/amd64에서 `docker` 또는 `kubernetes` 실행기가 있는 러너입니다. GitLab.com의 인스턴스 러너를 사용하는 경우 기본적으로 활성화됩니다.
- [지원되는 배포](#supported-distributions)와 일치하는 이미지입니다.
- Docker 이미지가 프로젝트의 컨테이너 레지스트리로 [빌드 및 푸시](../../packages/container_registry/build_and_push_images.md#use-gitlab-cicd)됩니다.
- 타사 컨테이너 레지스트리를 사용하는 경우 CI/CD 변수 `CS_REGISTRY_USER` 및 `CS_REGISTRY_PASSWORD`를 사용하여 인증 자격 증명을 제공해야 할 수 있습니다. 자세한 내용은 [프라이빗 외부 레지스트리 인증](#authenticate-to-private-external-registry)을 참조하세요.

컨테이너 스캐닝을 활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **컨테이너 스캐닝** 행에서 **머지 리퀘스트로 설정**을 선택합니다.
1. **머지 리퀘스트 생성**을 선택합니다.
1. 머지 리퀘스트를 검토한 다음 **머지**를 선택합니다.

파이프라인에는 이제 컨테이너 스캐닝 작업이 포함됩니다.

### `.gitlab-ci.yml` 파일을 수동으로 편집 {#edit-the-gitlab-ciyml-file-manually}

이 방법을 사용하려면 기존 `.gitlab-ci.yml` 파일을 수동으로 편집해야 합니다. 복잡한 GitLab 구성 파일이 있거나 기본이 아닌 옵션을 사용해야 하는 경우 이 방법을 사용하세요.

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- `test` 스테이지가 `.gitlab-ci.yml` 파일에 있습니다.
- 자체 관리형 러너를 사용하는 경우 Linux/amd64에서 `docker` 또는 `kubernetes` 실행기가 있는 러너입니다. GitLab.com의 인스턴스 러너를 사용하는 경우 기본적으로 활성화됩니다.
- [지원되는 배포](#supported-distributions)와 일치하는 이미지입니다.
- Docker 이미지가 프로젝트의 컨테이너 레지스트리로 [빌드 및 푸시](../../packages/container_registry/build_and_push_images.md#use-gitlab-cicd)됩니다.
- 타사 컨테이너 레지스트리를 사용하는 경우 CI/CD 변수 `CS_REGISTRY_USER` 및 `CS_REGISTRY_PASSWORD`를 사용하여 인증 자격 증명을 제공해야 할 수 있습니다. 자세한 내용은 [프라이빗 외부 레지스트리 인증](#authenticate-to-private-external-registry)을 참조하세요.

컨테이너 스캐닝을 활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인 편집기**를 선택합니다.
1. `.gitlab-ci.yml` 파일이 없으면 **Configure pipeline**을 선택한 후 예제 콘텐츠를 삭제합니다.
1. 다음을 복사하여 `.gitlab-ci.yml` 파일의 맨 아래에 붙여넣습니다. `include` 줄이 이미 있으면 아래에 `template` 줄만 추가합니다.

   ```yaml
   include:
     - template: Jobs/Container-Scanning.gitlab-ci.yml
   ```

1. **검증** 탭을 선택한 후 **파이프라인 검증**을 선택합니다.

   **시뮬레이션이 성공적으로 완료되었습니다** 메시지는 파일이 유효함을 확인합니다.
1. **편집** 탭을 선택합니다.
1. 필드를 완성하세요. **브랜치** 필드에 기본 브랜치를 사용하지 마세요.
1. **이 변경 사항으로 새로운 머지 리퀘스트 시작** 확인란을 선택한 후 **변경 사항 커밋**을 선택합니다.
1. 표준 워크플로에 따라 필드를 완성한 후 **머지 리퀘스트 생성**을 선택합니다.
1. 머지 리퀘스트를 검토 및 편집합니다. 표준 워크플로우에 따라 파이프라인이 통과될 때까지 기다린 후 **머지**를 선택합니다.

파이프라인에는 이제 컨테이너 스캐닝 작업이 포함됩니다.

## 결과 이해 {#understand-the-results}

전제 조건:

- 프로젝트에 대한 보안 관리자, Developer, Maintainer 또는 Owner 역할.

파이프라인에서 취약성을 검토할 수 있습니다:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. 파이프라인을 선택합니다.
1. **보안** 탭을 선택합니다.
1. 취약성을 선택하면 다음을 포함한 세부 정보를 볼 수 있습니다:
   - 설명:  취약성의 원인, 잠재적 영향 및 권장 수정 단계를 설명합니다.
   - 상태:  취약성이 심사되었는지 또는 해결되었는지 여부를 나타냅니다.
   - 심각도:  영향에 따라 6가지 수준으로 분류됩니다. [심각도 수준에 대해 자세히 알아보기](../vulnerabilities/severities.md).
   - CVSS 점수: 심각도에 매핑되는 숫자 값을 제공합니다.
   - EPSS: 취약성이 실제로 악용될 가능성을 표시합니다.
   - 알려진 익스플로잇 보유(KEV): 주어진 취약성이 악용되었음을 나타냅니다.
   - 프로젝트: 취약성이 식별된 프로젝트를 강조합니다.
   - 보고서 유형: 출력 유형을 설명합니다.
   - 스캐너:  취약성을 감지한 분석기를 식별합니다.
   - 이미지: 취약성에 대한 이미지를 제공합니다.
   - 네임스페이스: 취약성에 대한 워크스페이스를 식별합니다.
   - 링크: 다양한 자문 데이터베이스에서 취약성이 카탈로그된 증거입니다.
   - 식별자:  취약성을 분류하는 데 사용되는 참조 목록(예: CVE 식별자)입니다.

자세한 내용은 [파이프라인 보안 보고서](../detect/security_scanning_results.md)를 참조하세요.

컨테이너 스캐닝 결과를 보는 추가 방법:

- [취약성 보고서](../vulnerability_report/_index.md): 기본 브랜치에서 확인된 취약성을 표시합니다.
- [컨테이너 스캐닝 보고서 아티팩트](../../../ci/yaml/artifacts_reports.md#artifactsreportscontainer_scanning)

## 최적화 {#optimization}

GitLab은 컨테이너 스캐닝을 위한 두 가지 접근 방식을 제공합니다:

- 표준 컨테이너 스캐닝: 작업당 단일 컨테이너 이미지를 검사합니다. 간단한 분산 워크플로우에 최적입니다.
- [다중 컨테이너 스캐닝](multi_container_scanning.md): 단일 구성 파일을 사용하여 여러 이미지를 병렬로 검사합니다. 여러 이미지를 효율적으로 검사하는 데 최적입니다.

## 배포 및 확장 {#roll-out}

단일 프로젝트에 대한 컨테이너 스캐닝 결과에 확신이 있으면 추가 프로젝트로 구현을 확장할 수 있습니다:

- [적용된 검사 실행](../detect/security_configuration.md#create-a-shared-configuration)을 사용하여 그룹 전체에 컨테이너 스캐닝 설정을 적용합니다.
- 고유한 요구 사항이 있으면 컨테이너 스캐닝을 [오프라인 환경](#offline-environment)에서 실행할 수 있습니다.

## 지원되는 배포판 {#supported-distributions}

다음 Linux 배포판이 지원됩니다:

- Alma Linux
- Alpine Linux
- Amazon Linux
- CentOS
- CBL-Mariner
- Debian
- Distroless
- Oracle Linux
- Photon OS
- Red Hat(RHEL)
- Rocky Linux
- SUSE
- Ubuntu

### FIPS 활성화 이미지 {#fips-enabled-images}

GitLab은 또한 [FIPS 지원 Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) 버전의 컨테이너 스캐닝 이미지를 제공합니다. 따라서 표준 이미지를 FIPS 지원 이미지로 바꿀 수 있습니다. 이미지를 구성하려면 `CS_IMAGE_SUFFIX`를 `-fips`로 설정하거나 `CS_ANALYZER_IMAGE` 변수를 표준 태그에 `-fips` 확장자를 더한 값으로 수정합니다.

> [!note]
> `-fips` 플래그는 GitLab 인스턴스에서 FIPS 모드가 활성화되면 자동으로 `CS_ANALYZER_IMAGE`에 추가됩니다.

FIPS 모드가 활성화되면 인증된 레지스트리의 이미지에 대한 컨테이너 스캐닝은 지원되지 않습니다. `CI_GITLAB_FIPS_MODE`이(가) `"true"`이(가) 이고 `CS_REGISTRY_USER` 또는 `CS_REGISTRY_PASSWORD`이(가) 설정되면 분석기가 오류로 종료되고 검사를 수행하지 않습니다.

## 구성 {#configuration}

### 분석기 동작 사용자 정의 {#customizing-analyzer-behavior}

컨테이너 스캐닝을 사용자 지정하려면 [CI/CD 변수](#available-cicd-variables)를 사용하세요.

#### 자세한 출력 활성화 {#enable-verbose-output}

종속성 검사 작업이 수행하는 작업을 자세히 확인해야 할 때(예: 문제 해결 시) 자세한 출력을 활성화합니다.

다음 예제에서는 컨테이너 스캐닝 템플릿이 포함되고 자세한 출력이 활성화됩니다.

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

variables:
    SECURE_LOG_LEVEL: 'debug'
```

#### 언어별 결과 보고 {#report-language-specific-findings}

`CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` CI/CD 변수는 검사가 프로그래밍 언어와 관련된 결과를 보고하는지 여부를 제어합니다. 지원되는 언어에 대한 자세한 내용은 Trivy 설명서에서 [언어별 패키지](https://aquasecurity.github.io/trivy/latest/docs/coverage/language/#supported-languages)를 참조하세요.

기본적으로 보고서는 OS(운영 체제) 패키지 관리자(예: `yum`, `apt`, `apk`, `tdnf`)에서 관리하는 패키지만 포함합니다. 비 OS 패키지의 보안 결과를 보고하려면 `CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN`를 `"false"`로 설정합니다:

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN: "false"
```

이 기능을 활성화하면 프로젝트에 대해 종속성 검사가 활성화된 경우 취약성 보고서에 [중복 결과](../terminology/_index.md#duplicate-finding)가 표시될 수 있습니다. 이는 GitLab이 다양한 스캐닝 도구의 결과를 자동으로 중복 제거할 수 없기 때문입니다. 중복될 가능성이 있는 종속성 유형을 이해하려면 [컨테이너 스캐닝과 비교된 종속성 검사](../comparison_dependency_and_container_scanning.md)를 참조하세요.

#### 머지 리퀘스트 파이프라인에서 작업 실행 {#running-jobs-in-merge-request-pipelines}

[머지 리퀘스트 파이프라인에서 보안 스캐닝 도구 사용](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)을 참조하세요.

#### 사용 가능한 CI/CD 변수 {#available-cicd-variables}

컨테이너 스캐닝을 사용자 지정하려면 CI/CD 변수를 사용합니다. 다음 표는 컨테이너 스캐닝과 관련된 CI/CD 변수를 나열합니다. [사전 정의된 CI/CD 변수](../../../ci/variables/predefined_variables.md)를 사용할 수도 있습니다.

> [!warning]
> 기본 브랜치에 이러한 변경 사항을 병합하기 전에 머지 리퀘스트에서 GitLab 분석기 사용자 지정을 테스트합니다. 테스트를 거치지 않으면 수많은 거짓 양성을 포함하여 예상치 못한 결과가 발생할 수 있습니다.

| CI/CD 변수                           | 기본값                                                                         | 설명                                                                                                                                                                                                                                                                                                                                                                                   |
|------------------------------------------|---------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ADDITIONAL_CA_CERT_BUNDLE`              | `""`                                                                            | 신뢰하려는 CA 인증서 번들입니다. 자세한 내용은 [사용자 지정 SSL CA 인증 기관 사용](#using-a-custom-ssl-ca-certificate-authority)을 참조하세요.                                                                                                                                                                                                                                  |
| `CI_APPLICATION_REPOSITORY`              | `$CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG`                                        | 검사할 이미지의 Docker 리포지토리 URL입니다.                                                                                                                                                                                                                                                                                                                                            |
| `CI_APPLICATION_TAG`                     | `$CI_COMMIT_SHA`                                                                | 검사할 이미지의 Docker 리포지토리 태그입니다.                                                                                                                                                                                                                                                                                                                                            |
| `CS_ANALYZER_IMAGE`                      | `registry.gitlab.com/security-products/container-scanning:8`                    | 분석기의 Docker 이미지입니다. GitLab에서 제공하는 분석기 이미지와 `:latest` 태그를 사용하지 마세요.                                                                                                                                                                                                                                                                                           |
| `CS_DEFAULT_BRANCH_IMAGE`                | `""`                                                                            | 기본 브랜치의 `CS_IMAGE` 이름입니다. 자세한 내용은 [기본 브랜치 이미지 설정](#setting-the-default-branch-image)을 참조하세요.                                                                                                                                                                                                                                                 |
| `CS_DISABLE_DEPENDENCY_LIST`             | `"false"`                                                                       | {{< icon name="warning" >}} **[GitLab 17.0에서 제거됨](https://gitlab.com/gitlab-org/gitlab/-/issues/439782)**.                                                                                                                                                                                                                                                                               |
| `CS_DISABLE_LANGUAGE_VULNERABILITY_SCAN` | `"true"`                                                                        | 검사된 이미지에 설치된 언어별 패키지 검사를 비활성화합니다.                                                                                                                                                                                                                                                                                                               |
| `CS_DOCKER_INSECURE`                     | `"false"`                                                                       | 인증서를 검증하지 않고 HTTPS를 사용하여 보안 Docker 레지스트리에 액세스를 허용합니다.                                                                                                                                                                                                                                                                                                     |
| `CS_DOCKERFILE_PATH`                     | `Dockerfile`                                                                    | 수정 생성에 사용할 `Dockerfile`의 경로입니다. 기본적으로 스캐너는 프로젝트 루트 디렉터리에서 `Dockerfile`라는 파일을 찾습니다. `Dockerfile`이(가) 하위 디렉터리와 같은 비표준 위치에 있는 경우에만 이 변수를 구성해야 합니다. 자세한 내용은 [취약성 솔루션](#solutions-for-vulnerabilities-auto-remediation)을 참조하세요. |
| `CS_INCLUDE_LICENSES`                    | `""`                                                                            | 설정하면 이 변수는 각 구성 요소에 대한 라이선스를 포함합니다. cyclonedx 보고서에만 적용되며 해당 라이선스는 [trivy](https://trivy.dev/v0.60/docs/scanner/license/)에서 제공합니다.                                                                                                                                                                                              |
| `CS_IGNORE_STATUSES`                     | `""`                                                                            | 분석기가 쉼표로 구분된 목록의 지정된 상태를 가진 결과를 무시하도록 합니다. 다음 값이 허용됩니다: `unknown,not_affected,affected,fixed,under_investigation,will_not_fix,fix_deferred,end_of_life`. <sup>1</sup>                                                                                                                                                      |
| `CS_IGNORE_UNFIXED`                      | `"false"`                                                                       | 수정되지 않은 결과를 무시합니다. 무시된 결과는 보고서에 포함되지 않습니다.                                                                                                                                                                                                                                                                                                          |
| `CS_IMAGE`                               | `$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG`                                | 검사할 Docker 이미지입니다. 설정하면 이 변수는 `$CI_APPLICATION_REPOSITORY` 및 `$CI_APPLICATION_TAG` 변수를 재정의합니다.                                                                                                                                                                                                                                                         |
| `CS_IMAGE_SUFFIX`                        | `""`                                                                            | `CS_ANALYZER_IMAGE`에 추가된 접미사입니다. `-fips`로 설정하면 검사에 `FIPS-enabled` 이미지가 사용됩니다. 자세한 내용은 [FIPS 활성화 이미지](#fips-enabled-images)를 참조하세요.                                                                                                                                                                                                                              |
| `CS_QUIET`                               | `""`                                                                            | 설정하면 이 변수는 작업 로그에서 [취약성 테이블](#container-scanning-job-log-format)의 출력을 비활성화합니다.                                                                                                                                    |
| `CS_REGISTRY_INSECURE`                   | `"false"`                                                                       | 비보안 레지스트리(HTTP만)에 액세스를 허용합니다. 로컬로 이미지를 테스트할 때만 `true`로 설정해야 합니다. 모든 스캐너에서 작동하지만 Trivy가 작동하려면 레지스트리가 포트 `80/tcp`에서 수신 대기해야 합니다.                                                                                                                                                                                       |
| `CS_REGISTRY_PASSWORD`                   | `$CI_REGISTRY_PASSWORD`                                                         | 인증이 필요한 Docker 레지스트리에 액세스하기 위한 암호입니다. 기본값은 `$CS_IMAGE`이(가) [`$CI_REGISTRY`](../../../ci/variables/predefined_variables.md)에 있을 때만 설정됩니다. FIPS 모드가 활성화된 경우 지원되지 않습니다.                                                                                                                                                                |
| `CS_REGISTRY_USER`                       | `$CI_REGISTRY_USER`                                                             | 인증이 필요한 Docker 레지스트리에 액세스하기 위한 사용자 이름입니다. 기본값은 `$CS_IMAGE`이(가) [`$CI_REGISTRY`](../../../ci/variables/predefined_variables.md)에 있을 때만 설정됩니다. FIPS 모드가 활성화된 경우 지원되지 않습니다.                                                                                                                                                                |
| `CS_REPORT_OS_EOL`                       | `"false"`                                                                       | EOL 감지 활성화                                                                                                                                                                                                                                                                                                                                                                          |
| `CS_REPORT_OS_EOL_SEVERITY`              | `"Medium"`                                                                      | `CS_REPORT_OS_EOL`이(가) 활성화되면 EOL OS 결과에 할당되는 심각도 수준입니다. EOL 결과는 `CS_SEVERITY_THRESHOLD`와 관계없이 항상 보고됩니다. 지원되는 수준은 `UNKNOWN`, `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`입니다.                                                                                                                                                               |
| `CS_SEVERITY_THRESHOLD`                  | `UNKNOWN`                                                                       | 심각도 수준 임계값입니다. 스캐너는 이 임계값 이상의 심각도 수준으로 취약성을 출력합니다. 지원되는 수준은 `UNKNOWN`, `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`입니다.                                                                                                                                                                                            |
| `CS_TRIVY_JAVA_DB`                       | `"registry.gitlab.com/gitlab-org/security-products/dependencies/trivy-java-db"` | [trivy-java-db](https://github.com/aquasecurity/trivy-java-db) 취약성 데이터베이스의 대체 위치를 지정합니다.                                                                                                                                                                                                                                                                  |
| `CS_TRIVY_DETECTION_PRIORITY`            | `"precise"`                                                                     | 정의된 Trivy [감지 우선 순위](https://trivy.dev/latest/docs/scanner/vulnerability/#detection-priority)를 사용하여 검사합니다. 다음 값이 허용됩니다: `precise` 또는 `comprehensive`.                                                                                                                                                                                                   |
| `SECURE_LOG_LEVEL`                       | `info`                                                                          | 최소 로깅 수준을 설정합니다. 이 로깅 수준 이상의 메시지가 출력됩니다. 가장 높은 것부터 가장 낮은 심각도 순서로 로깅 수준은 다음과 같습니다. `fatal`, `error`, `warn`, `info`, `debug`.                                                                                                                                                                                                       |
| `TRIVY_TIMEOUT`                          | `5m0s`                                                                          | 검사의 시간 제한을 설정합니다.                                                                                                                                                                                                                                                                                                                                                               |
| `TRIVY_PLATFORM`                         | `linux/amd64`                                                                   | 이미지가 다중 플랫폼 가능하면 `os/arch` 형식으로 플랫폼을 설정합니다.                                                                                                                     |

**각주**:

1. 수정 상태 정보는 소프트웨어 공급업체와 컨테이너 이미지 운영 체제 패키지 메타데이터의 정확한 수정 가능성 데이터에 따라 크게 달라집니다. 또한 개별 컨테이너 스캐너의 해석에 따라 달라집니다. 컨테이너 스캐너가 취약성의 수정된 패키지 가용성을 잘못 보고하는 경우 `CS_IGNORE_STATUSES`을(를) 사용하면 이 설정이 활성화된 경우 결과의 거짓 긍정 또는 거짓 부정 필터링이 발생할 수 있습니다.

#### 기본 환경 변수를 사용하여 Trivy를 직접 구성 {#configure-trivy-directly-with-native-environment-variables}

위에 나열된 GitLab별 `CS_*` 변수 외에도 `container_scanning` 작업에서 [기본 환경 변수](https://trivy.dev/docs/v0.69/guide/configuration/#environment-variables) 중 하나를 설정하여 Trivy를 직접 구성할 수 있습니다. GitLab 컨테이너 스캐닝 분석기는 모든 환경 변수를 자동으로 Trivy로 전달합니다.

예를 들어 Trivy가 자동 감지할 수 없는 컨테이너 이미지의 OS 배포판을 수동으로 지정하려면(예: 사용자 지정 기본 이미지):

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    GIT_STRATEGY: fetch
    TRIVY_DISTRO: "alma/10"
```

> [!note]
> `--distro` 플래그가 `TRIVY_DISTRO`에서 사용되는 것은 [Trivy의 실험적](https://trivy.dev/docs/v0.69/guide/references/configuration/cli/trivy_image/)입니다. 결과는 지정된 Trivy 버전 및 배포판에 따라 달라질 수 있습니다.

##### GitLab 래퍼로 관리되는 변수 {#variables-managed-by-the-gitlab-wrapper}

다음 `TRIVY_*` 변수는 GitLab 컨테이너 스캐닝 분석기에서 내부적으로 설정됩니다. 이들은 해당 GitLab CI/CD 변수에 의해 제어되며 직접 재정의할 수 없습니다:

| Trivy 변수      | GitLab CI/CD 변수    |
|---------------------|--------------------------|
| `TRIVY_CACHE_DIR`   | (내부, 노출되지 않음)  |
| `TRIVY_USERNAME`    | `CS_REGISTRY_USER`       |
| `TRIVY_PASSWORD`    | `CS_REGISTRY_PASSWORD`   |
| `TRIVY_DEBUG`       | `SECURE_LOG_LEVEL`       |
| `TRIVY_INSECURE`    | `CS_DOCKER_INSECURE`     |
| `TRIVY_NON_SSL`     | `CS_REGISTRY_INSECURE`   |

##### `TRIVY_DB_REPOSITORY`과(와) 관련된 알려진 문제 {#known-issue-with-trivy_db_repository}

`TRIVY_DB_REPOSITORY`을(를) Trivy의 사용자 정의 취약성 데이터베이스로 지정하는 것은 효과가 없습니다. GitLab 컨테이너 스캐닝 분석기는 취약성 데이터베이스를 분석기 이미지 내에 번들로 제공하고 런타임에 `--skip-db-update`를 Trivy로 전달하므로 Trivy는 이 변수와 관계없이 데이터베이스를 다운로드하지 않습니다. 사용자 정의 데이터베이스 위치를 사용하려면 Java 데이터베이스는 [Trivy Java 데이터베이스 미러 사용](#use-a-trivy-java-database-mirror)을(를) 참조하고 일반 오프라인 설정은 [오프라인 환경](#offline-environment)을(를) 참조하세요.

### 컨테이너 스캐닝 템플릿 재정의 {#overriding-the-container-scanning-template}

작업 정의를 재정의하려는 경우(예: `variables`와 같은 속성을 변경하려면) 템플릿을 포함한 후 작업을 선언하고 재정의한 다음 추가 키를 지정해야 합니다.

이 예제는 `GIT_STRATEGY`를 `fetch`로 설정합니다:

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    GIT_STRATEGY: fetch
```

### 외부 레지스트리에서 이미지 검사 {#scan-image-in-external-registry}

기본적으로 컨테이너 스캐닝은 GitLab 컨테이너 레지스트리의 이미지를 검사합니다. 외부 레지스트리의 이미지도 검사할 수 있습니다.

외부 레지스트리에서 이미지를 검사하려면 이미지의 전체 경로를 사용하여 `CS_IMAGE` 변수를 구성하세요.

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_IMAGE: <example.com>/<user>/<image>:<tag>
```

#### 프라이빗 외부 레지스트리에 인증 {#authenticate-to-private-external-registry}

외부 레지스트리에 인증이 필요한 경우 `CS_REGISTRY_USER` 및 `CS_REGISTRY_PASSWORD` CI/CD 변수를 사용하여 자격 증명을 제공합니다.

> [!note]
> 외부 프라이빗 레지스트리의 이미지 검사는 FIPS 모드가 활성화된 경우 지원되지 않습니다.

예를 들어 Google 컨테이너 레지스트리에서 이미지를 검사하려면:

1. [Google Cloud Platform 컨테이너 레지스트리 설명서](https://cloud.google.com/container-registry/docs/advanced-authentication#json-key)에 설명된 대로 JSON 키가 포함된 `GCP_CREDENTIALS`에 대한 CI/CD 변수를 추가합니다.

   - 변수의 값이 마스크 변수 옵션의 마스킹 요구 사항에 맞지 않을 수 있으므로 값이 작업 로그에 노출될 수 있습니다.
   - 변수 보호 옵션을 선택하면 보호되지 않은 기능 브랜치에서 검사가 실행되지 않을 수 있습니다.
   - 이러한 옵션을 선택하지 않으면 읽기 전용 권한으로 자격 증명을 만들고 정기적으로 회전하는 것을 고려하세요.

1. `.gitlab-ci.yml` 파일에 다음을 추가합니다.

   ```yaml
   include:
     - template: Jobs/Container-Scanning.gitlab-ci.yml

   container_scanning:
     variables:
       CS_REGISTRY_USER: _json_key
       CS_REGISTRY_PASSWORD: "$GCP_CREDENTIALS"
       CS_IMAGE: "gcr.io/<path-to-your-registry>/<image>:<tag>"
   ```

예를 들어 AWS Elastic 컨테이너 레지스트리에서 이미지를 검사하려면:

- `.gitlab-ci.yml` 파일에 다음을 추가합니다:

  ```yaml
  container_scanning:
    before_script:
      - ruby -r open-uri -e "IO.copy_stream(URI.open('https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip'), 'awscliv2.zip')"
      - unzip awscliv2.zip
      - sudo ./aws/install
      - export AWS_ECR_PASSWORD=$(aws ecr get-login-password --region <region>)

  include:
    - template: Jobs/Container-Scanning.gitlab-ci.yml

  variables:
      CS_IMAGE: <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<image>:<tag>
      CS_REGISTRY_USER: AWS
      CS_REGISTRY_PASSWORD: "$AWS_ECR_PASSWORD"
      AWS_DEFAULT_REGION: <region>
  ```

### Trivy Java 데이터베이스 미러 사용 {#use-a-trivy-java-database-mirror}

`trivy` 스캐너를 사용하고 검사 중인 컨테이너 이미지에서 `jar` 파일을 마주치면 `trivy`이(가) 추가 `trivy-java-db` 취약성 데이터베이스를 다운로드합니다. 기본적으로 `trivy-java-db` 데이터베이스는 [OCI 아티팩트](https://oras.land/docs/quickstart/)로 `ghcr.io/aquasecurity/trivy-java-db:1`에서 호스팅됩니다. 이 레지스트리에 [액세스할 수 없거나](#offline-environment) `TOOMANYREQUESTS`으로 응답하면 한 가지 솔루션은 `trivy-java-db`을(를) 더 액세스 가능한 컨테이너 레지스트리로 미러링하는 것입니다:

```yaml
mirror trivy java db:
  image:
    name: ghcr.io/oras-project/oras:v1.1.0
    entrypoint: [""]
  script:
    - oras login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - oras pull ghcr.io/aquasecurity/trivy-java-db:1
    - oras push $CI_REGISTRY_IMAGE:1 --config /dev/null:application/vnd.aquasec.trivy.config.v1+json javadb.tar.gz:application/vnd.aquasec.trivy.javadb.layer.v1.tar+gzip
```

취약성 데이터베이스는 일반 Docker 이미지가 아니므로 `docker pull`을(를) 사용하여 끌어올 수 없습니다. GitLab UI에서 이미지를 보면 오류가 표시됩니다.

컨테이너 레지스트리가 `gitlab.example.com/trivy-java-db-mirror`인 경우 컨테이너 스캐닝 작업을 다음과 같은 방식으로 구성해야 합니다. 끝에 태그 `:1`를 추가하지 마세요. `trivy`에서 추가합니다:

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_TRIVY_JAVA_DB: gitlab.example.com/trivy-java-db-mirror
```

### 기본 브랜치 이미지 설정 {#setting-the-default-branch-image}

기본적으로 컨테이너 스캐닝은 이미지 이름 지정 규칙이 이미지 이름이 아닌 이미지 태그에 브랜치별 식별자를 저장한다고 가정합니다. 이미지 이름이 기본 브랜치와 기본이 아닌 브랜치 간에 다르면 이전에 감지된 취약성이 머지 리퀘스트에서 새로 감지된 것으로 표시됩니다.

같은 이미지가 기본 브랜치와 기본이 아닌 브랜치에서 다른 이름을 가질 때 `CS_DEFAULT_BRANCH_IMAGE` 변수를 사용하여 기본 브랜치의 이미지 이름이 무엇인지 표시할 수 있습니다. GitLab은 기본이 아닌 브랜치에서 검사를 실행할 때 취약성이 이미 존재하는지 올바르게 결정합니다.

예를 들어 다음을 가정합니다:

- 기본이 아닌 브랜치는 명명 규칙 `$CI_REGISTRY_IMAGE/$CI_COMMIT_BRANCH:$CI_COMMIT_SHA`을(를) 사용하여 이미지를 게시합니다.
- 기본 브랜치는 명명 규칙 `$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA`을(를) 사용하여 이미지를 게시합니다.

이 예제에서는 다음 CI/CD 구성을 사용하여 취약성이 중복되지 않도록 할 수 있습니다:

```yaml
include:
  - template: Jobs/Container-Scanning.gitlab-ci.yml

container_scanning:
  variables:
    CS_DEFAULT_BRANCH_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  before_script:
    - export CS_IMAGE="$CI_REGISTRY_IMAGE/$CI_COMMIT_BRANCH:$CI_COMMIT_SHA"
    - |
      if [ "$CI_COMMIT_BRANCH" == "$CI_DEFAULT_BRANCH" ]; then
        export CS_IMAGE="$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA"
      fi
```

`CS_DEFAULT_BRANCH_IMAGE`은(는) 주어진 `CS_IMAGE`에 대해 같아야 합니다. 변경되면 수동으로 해제해야 하는 중복 취약성 세트가 생성됩니다.

Auto DevOps를 사용할 때 `CS_DEFAULT_BRANCH_IMAGE`은(는) 자동으로 `$CI_REGISTRY_IMAGE/$CI_DEFAULT_BRANCH:$CI_APPLICATION_TAG`로 설정됩니다.

### 사용자 정의 SSL CA 인증 기관 사용 {#using-a-custom-ssl-ca-certificate-authority}

`ADDITIONAL_CA_CERT_BUNDLE` CI/CD 변수를 사용하여 사용자 정의 SSL CA 인증 기관을 구성할 수 있으며, 이는 HTTPS를 사용하는 레지스트리에서 Docker 이미지를 가져올 때 피어를 확인하는 데 사용됩니다. `ADDITIONAL_CA_CERT_BUNDLE` 값은 [X.509 PEM 공개 키 인증서의 텍스트 표현](https://www.rfc-editor.org/rfc/rfc7468#section-5.1)을(를) 포함해야 합니다. 예를 들어 `.gitlab-ci.yml` 파일에서 이 값을 구성하려면 다음을 사용합니다:

```yaml
container_scanning:
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
        -----BEGIN CERTIFICATE-----
        MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
        ...
        jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
        -----END CERTIFICATE-----
```

`ADDITIONAL_CA_CERT_BUNDLE` 값은 UI에서 사용자 정의 변수로도 구성할 수 있으며, 인증서의 경로가 필요한 `file` 또는 인증서의 텍스트 표현이 필요한 변수로 구성할 수 있습니다.

### 다중 아키텍처 이미지 검사 {#scanning-a-multi-arch-image}

`TRIVY_PLATFORM` CI/CD 변수를 사용하여 특정 운영 체제 및 아키텍처에 대해 실행되도록 컨테이너 검사를 구성할 수 있습니다. 예를 들어 `.gitlab-ci.yml` 파일에서 이 값을 구성하려면 다음을 사용합니다:

```yaml
container_scanning:
  # Use an arm64 SaaS runner to scan this natively
  tags: ["saas-linux-small-arm64"]
  variables:
    TRIVY_PLATFORM: "linux/arm64"
```

### 취약성 허용 목록 지정 {#vulnerability-allowlisting}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

특정 취약성을 허용 목록에 추가하려면 다음 단계를 따릅니다:

1. `GIT_STRATEGY: fetch`을(를) `.gitlab-ci.yml` 파일에 설정하고 [컨테이너 스캐닝 템플릿 재정의](#overriding-the-container-scanning-template)의 지침을 따릅니다.
1. `vulnerability-allowlist.yml`이라는 YAML 파일에서 허용 목록 취약성을 정의합니다. 이는 [`vulnerability-allowlist.yml` 데이터 형식](#vulnerability-allowlistyml-data-format)에 설명된 형식을 사용해야 합니다.
1. `vulnerability-allowlist.yml` 파일을 프로젝트의 Git 리포지토리의 루트 폴더에 추가합니다.

#### `vulnerability-allowlist.yml` 데이터 형식 {#vulnerability-allowlistyml-data-format}

`vulnerability-allowlist.yml` 파일은 거짓 긍정이거나 적용 가능하지 않기 때문에 존재하도록 **허락**되는 취약성의 CVE ID 목록을 지정하는 YAML 파일입니다.

`vulnerability-allowlist.yml` 파일에서 일치하는 항목을 찾으면 다음이 발생합니다:

- 분석기가 `gl-container-scanning-report.json` 파일을 생성할 때 취약성은 **포함되지 않습니다**.
- 파이프라인의 보안 탭은 취약성을 **표시하지 않습니다**. 보안 탭의 신뢰할 수 있는 원본인 JSON 파일에 포함되지 않습니다.

`vulnerability-allowlist.yml` 파일 예제:

```yaml
generalallowlist:
  CVE-2019-8696:
  CVE-2014-8166: cups
  CVE-2017-18248:
images:
  registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256:
    CVE-2018-4180:
  your.private.registry:5000/centos:
    CVE-2015-1419: libxml2
    CVE-2015-1447:
```

이 예제는 `gl-container-scanning-report.json`에서 제외합니다:

1. CVE ID: `CVE-2019-8696`, `CVE-2014-8166`, `CVE-2017-18248`인 모든 취약성.
1. `registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256` 컨테이너 이미지에서 CVE ID `CVE-2018-4180`로 발견된 모든 취약성.
1. `your.private.registry:5000/centos` 컨테이너에서 CVE ID `CVE-2015-1419`, `CVE-2015-1447`인 모든 취약성.

##### 파일 형식 {#file-format}

- `generalallowlist` 블록을 사용하면 CVE ID를 전역으로 지정할 수 있습니다. 일치하는 CVE ID를 가진 모든 취약성은 검사 보고서에서 제외됩니다.
- `images` 블록을 사용하면 각 컨테이너 이미지에 대해 독립적으로 CVE ID를 지정할 수 있습니다. 주어진 이미지에서 일치하는 CVE ID를 가진 모든 취약성은 검사 보고서에서 제외됩니다. 이미지 이름은 `$CI_APPLICATION_REPOSITORY:$CI_APPLICATION_TAG` 또는 `CS_IMAGE`과(와) 같이 검사할 Docker 이미지를 지정하는 데 사용되는 환경 변수 중 하나에서 검색됩니다. 이 블록에 제공된 이미지는 **반드시** 이 값과 일치해야 하며 태그 값을 포함하지 **않아야 합니다**. 예를 들어 `CS_IMAGE=alpine:3.7`을(를) 사용하여 검사할 이미지를 지정하면 `images` 블록에서 `alpine`을(를) 사용하지만 `alpine:3.7`은(는) 사용할 수 없습니다.

  컨테이너 이미지를 여러 방법으로 지정할 수 있습니다:

  - 이미지 이름만으로(예: `centos`).
  - 레지스트리 호스트 이름이 있는 전체 이미지 이름(예: `your.private.registry:5000/centos`).
  - 레지스트리 호스트 이름 및 sha256 레이블(예: `registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256`)이 있는 전체 이미지 이름.

> [!note]
> CVE ID(`cups` 및 `libxml2`) 다음의 문자열은 선택적 주석 형식입니다. **no impact**. 주석을 포함하여 취약성을 설명할 수 있습니다.

##### 컨테이너 스캐닝 작업 로그 형식 {#container-scanning-job-log-format}

컨테이너 스캐닝 분석기에서 생성한 로그를 확인하여 검사 결과와 `vulnerability-allowlist.yml` 파일의 정확성을 확인할 수 있습니다(작업 `container_scanning` 세부 정보).

로그에는 예를 들어 발견된 취약성 목록이 테이블로 포함됩니다:

```plaintext
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
|   STATUS   |      CVE SEVERITY       |      PACKAGE NAME      |    PACKAGE VERSION    |                            CVE DESCRIPTION                             |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
|  Approved  |   High CVE-2019-3462    |          apt           |         1.4.8         | Incorrect sanitation of the 302 redirect field in HTTP transport metho |
|            |                         |                        |                       | d of apt versions 1.4.8 and earlier can lead to content injection by a |
|            |                         |                        |                       |  MITM attacker, potentially leading to remote code execution on the ta |
|            |                         |                        |                       |                             rget machine.                              |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
| Unapproved |  Medium CVE-2020-27350  |          apt           |         1.4.8         | APT had several integer overflows and underflows while parsing .deb pa |
|            |                         |                        |                       | ckages, aka GHSL-2020-168 GHSL-2020-169, in files apt-pkg/contrib/extr |
|            |                         |                        |                       | acttar.cc, apt-pkg/deb/debfile.cc, and apt-pkg/contrib/arfile.cc. This |
|            |                         |                        |                       |  issue affects: apt 1.2.32ubuntu0 versions prior to 1.2.32ubuntu0.2; 1 |
|            |                         |                        |                       | .6.12ubuntu0 versions prior to 1.6.12ubuntu0.2; 2.0.2ubuntu0 versions  |
|            |                         |                        |                       | prior to 2.0.2ubuntu0.2; 2.1.10ubuntu0 versions prior to 2.1.10ubuntu0 |
|            |                         |                        |                       |                                  .1;                                   |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
| Unapproved |  Medium CVE-2020-3810   |          apt           |         1.4.8         | Missing input validation in the ar/tar implementations of APT before v |
|            |                         |                        |                       | ersion 2.1.2 could result in denial of service when processing special |
|            |                         |                        |                       |                         ly crafted deb files.                          |
+------------+-------------------------+------------------------+-----------------------+------------------------------------------------------------------------+
```

로그의 취약성은 해당 CVE ID가 `vulnerability-allowlist.yml` 파일에 추가될 때 `Approved`로 표시됩니다.

### 오프라인 환경 {#offline-environment}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

[오프라인 환경](../offline_deployments/_index.md)에서 컨테이너 스캐닝을 실행하려면 초기 설정을 수행하고 지속적인 유지 관리를 수행해야 합니다.

초기 설정:

- 러너를 구성합니다(`docker` 또는 `kubernetes` 실행기를 사용할 수 있도록 함).
- 로컬 컨테이너 레지스트리를 설정합니다. 자세한 내용은 [GitLab 컨테이너 레지스트리](../../packages/container_registry/_index.md)를 참조하세요.
- 로컬 컨테이너 레지스트리에 이미지를 복사합니다.
- 컨테이너 스캐닝을 사용하는 각 프로젝트에 대해 CI/CD를 구성합니다.
- 요구 사항에 따라 다음을 선택적으로 구성할 수 있습니다:
  - [외부 레지스트리에서 이미지 검사](#scan-image-in-external-registry).
  - [Trivy Java 데이터베이스 미러 사용](#use-a-trivy-java-database-mirror).

지속적인 유지 관리:

- 새 버전이 릴리스되면 로컬 컨테이너 스캐닝 이미지를 업데이트합니다.

#### 러너 구성 {#configure-runner}

러너를 구성합니다(`docker` 또는 `kubernetes` 실행기를 사용할 수 있도록 함). 자세한 내용은 [시작하기](#getting-started)를 참조하세요.

기본적으로 러너는 로컬 복사본이 있는 경우에도 GitLab 컨테이너 레지스트리에서 컨테이너 이미지를 끌어옵니다. 로컬 컨테이너 이미지만 사용하려면 [`pull_policy`를 `if-not-present`로 설정](https://docs.gitlab.com/runner/executors/docker/#using-the-if-not-present-pull-policy)할 수 있습니다. 그러나 변경할 정당한 이유가 없으면 `pull_policy` 설정을 기본값으로 유지해야 합니다.

#### 컨테이너 이미지 복사 {#copy-container-image}

GitLab.com 컨테이너 레지스트리에서 로컬 컨테이너 레지스트리로 다음 이미지를 가져옵니다. 이 이미지는 오프라인 GitLab 인스턴스에서 액세스할 수 있어야 합니다.

```plaintext
registry.gitlab.com/security-products/container-scanning:8
```

로컬 컨테이너 레지스트리로 이미지를 가져오는 프로세스는 네트워크 보안 정책에 따라 달라집니다. IT 직원과 상담하여 외부 리소스를 가져오거나 일시적으로 액세스할 수 있는 허용되고 승인된 프로세스를 찾습니다.

#### 각 프로젝트에 대해 CI/CD 구성 {#configure-cicd-for-each-project}

> [!note]
> 이러한 구성 변경 사항은 `.gitlab-ci.yml` 파일을 참조하지 않기 때문에 레지스트리 컨테이너 스캐닝에 적용되지 않습니다. 오프라인 환경에서 레지스트리의 자동 컨테이너 스캐닝을 구성하려면 [GitLab UI에서 `CS_ANALYZER_IMAGE` 변수 정의](#use-with-offline-or-air-gapped-environments)를 대신 참조하세요.

컨테이너 스캐닝을 사용하는 모든 프로젝트에 대해 적용되는 모든 위치의 CI/CD 구성을 편집합니다. 여기에는 다음이 포함될 수 있습니다:

- 개별 프로젝트 `.gitlab-ci.yml` 파일
- 파이프라인 실행 정책
- 검사 실행 정책

다음 변수를 사용하여 컨테이너 스캐닝 구성을 업데이트합니다:

1. 선택 사항. 컨테이너 스캐닝 템플릿이 아직 포함되지 않으면 추가합니다.
1. `CS_ANALYZER_IMAGE`을(를) 로컬 컨테이너 레지스트리의 컨테이너 스캐닝 이미지로 설정합니다.
1. 선택 사항. 비 GitLab 컨테이너 레지스트리를 사용하는 경우 `CS_REGISTRY_USER` 및 `CS_REGISTRY_PASSWORD`를 레지스트리 자격 증명과 일치하도록 설정합니다.
1. 선택 사항. 로컬 컨테이너 레지스트리에 자체 서명된 인증서를 사용하는 경우 `CS_DOCKER_INSECURE: "true"`을(를) 설정합니다.

오프라인 환경에 대한 예제 `.gitlab-ci.yml` 구성:

   ```yaml
   include:
     - template: Jobs/Container-Scanning.gitlab-ci.yml

   container_scanning:
     variables:
       # Container scanning-specific variables
       CS_ANALYZER_IMAGE: <hostname>:<port>/analyzers/container-scanning:8
       CS_REGISTRY_USER: <username>
       CS_REGISTRY_PASSWORD: <password>
       CS_DOCKER_INSECURE: "true"
   ```

#### 로컬 컨테이너 이미지 업데이트 {#update-local-container-image}

컨테이너 스캐닝 이미지는 [정기적으로 업데이트](../detect/vulnerability_scanner_maintenance.md)되고 GitLab.com 레지스트리로 푸시됩니다. 오프라인 환경에서는 로컬 컨테이너 레지스트리의 컨테이너 스캐닝 이미지를 자동(권장) 또는 수동으로 업데이트해야 합니다.

- 수동 방법: GitLab.com 레지스트리에 네트워크를 통해 액세스할 수 없으면 로컬 레지스트리에서 컨테이너 스캐닝 이미지를 수동으로 업데이트합니다. [초기 설정을 위해 이미지를 복사할 때](#copy-container-image) 사용한 동일한 방법을 사용하세요.
- 자동 방법: 오프라인 GitLab 인스턴스에서 GitLab.com에 읽기 액세스 권한이 있으면 이미지를 사전 설정 일정으로 자동으로 업데이트하도록 예약된 파이프라인을 설정합니다.

##### 자동 이미지 업데이트 방법 {#automatic-image-update-method}

다음 `.gitlab-ci.yml` 추출은 로컬 레지스트리에서 컨테이너 스캐닝 이미지를 자동으로 업데이트하는 방법을 보여줍니다. 이 방법은 소스 이미지 및 대상 이미지에 대한 변수를 정의한 다음 Docker CLI를 사용하여 GitLab.com 레지스트리에서 이미지를 끌어오고 로컬 레지스트리로 푸시합니다.

비 GitLab 레지스트리를 사용하는 경우 `CI_REGISTRY` 값을 업데이트하고 `CI_REGISTRY_USER` 및 `CI_REGISTRY_PASSWORD` 변수를 로컬 레지스트리 자격 증명과 일치하도록 설정하여 인증을 구성합니다.

```yaml
variables:
  SOURCE_IMAGE: registry.gitlab.com/security-products/container-scanning:8
  TARGET_IMAGE: $CI_REGISTRY/namespace/container-scanning

image: docker:cli

update-scanner-image:
  services:
    - docker:dind
  script:
    - docker pull $SOURCE_IMAGE
    - docker tag $SOURCE_IMAGE $TARGET_IMAGE
    - echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY --username $CI_REGISTRY_USER --password-stdin
    - docker push $TARGET_IMAGE
```

## 아카이브 형식 검사 {#scanning-archive-formats}

{{< history >}}

- tar 파일 검사는 [GitLab 18.0에서 소개](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/merge_requests/3151)되었습니다.

{{< /history >}}

컨테이너 스캐닝은 아카이브 형식(`.tar`, `.tar.gz`)의 이미지를 지원합니다. 예를 들어 `docker save` 또는 `docker buildx build`을(를) 사용하여 생성할 수 있습니다.

아카이브 파일을 검사하려면 환경 변수 `CS_IMAGE`을(를) 형식 `archive://path/to/archive`으로 설정합니다:

- `archive://` 스키마 접두사는 분석기가 아카이브를 검사하도록 지정합니다.
- `path/to/archive`는 절대 경로 또는 상대 경로인지 여부에 관계없이 검사할 아카이브의 경로를 지정합니다.

컨테이너 스캐닝은 [Docker 이미지 사양](https://github.com/moby/docker-image-spec)을 따르는 tar 이미지 파일을 지원합니다. OCI tarball은 지원되지 않습니다. 지원되는 형식에 대한 자세한 내용은 [Trivy tar 파일 지원](https://trivy.dev/v0.48/docs/target/container_image/#tar-files)을 참조하세요.

### 지원되는 tar 파일 빌드 {#building-supported-tar-files}

컨테이너 스캐닝은 tar 파일의 메타데이터를 사용하여 이미지 이름을 지정합니다. tar 이미지 파일을 빌드할 때 이미지에 태그가 지정되어 있는지 확인합니다:

```shell
# Pull or build an image with a name and a tag
docker pull image:latest
# OR
docker build . -t image:latest
# Then export to tar using docker save
docker save image:latest -o image-latest.tar

# Or build an image with a tag using buildx build
docker buildx create --name container --driver=docker-container
docker buildx build -t image:latest --builder=container -o type=docker,dest=- . > image-latest.tar

# With podman
podman build -t image:latest .
podman save -o image-latest.tar image:latest
```

### 이미지 이름 {#image-name}

컨테이너 스캐닝은 먼저 아카이브의 `manifest.json`을(를) 평가하고 `RepoTags`의 첫 번째 항목을 사용하여 이미지 이름을 결정합니다. 이를 찾을 수 없으면 `index.json`이(가) `io.containerd.image.name` 주석을 가져오는 데 사용됩니다. 이를 찾을 수 없으면 아카이브 파일명이 대신 사용됩니다.

- `manifest.json`은(는) [Docker 이미지 사양 v1.1.0](https://github.com/moby/docker-image-spec/blob/v1.1.0/v1.1.md#combined-image-json--filesystem-changeset-format)에 정의되어 있으며 명령 `docker save`을(를) 사용하여 생성됩니다.
- `index.json` 형식은 [OCI 이미지 사양 v1.1.1](https://github.com/opencontainers/image-spec/blob/v1.1.1/spec.md)에 정의되어 있습니다. `io.containerd.image.name`은(는) `ctr image export`을(를) 사용할 때 [containerd v1.3.0 이상에서 사용 가능](https://github.com/containerd/containerd/blob/v1.3.0/images/annotations.go)합니다.

### 이전 작업에서 빌드한 아카이브 검사 {#scanning-archives-built-in-a-previous-job}

CI/CD 작업에서 빌드한 아카이브를 검사하려면 빌드 작업에서 컨테이너 스캐닝 작업으로 아카이브 아티팩트를 전달해야 합니다. [`artifacts:paths`](../../../ci/yaml/_index.md#artifactspaths) 및 [`dependencies`](../../../ci/yaml/_index.md#dependencies) 키워드를 사용하여 한 작업에서 다음 작업으로 아티팩트를 전달합니다:

```yaml
build_job:
  script:
    - docker build . -t image:latest
    - docker save image:latest -o image-latest.tar
  artifacts:
    paths:
      - "image-latest.tar"

container_scanning:
  variables:
    CS_IMAGE: "archive://image-latest.tar"
  dependencies:
    - build_job
```

### 프로젝트 리포지토리에서 아카이브 검사 {#scanning-archives-from-the-project-repository}

프로젝트 리포지토리에서 찾은 아카이브를 검사하려면 [Git 전략](../../../ci/runners/configure_runners.md#git-strategy)이(가) 리포지토리에 액세스할 수 있는지 확인합니다. `GIT_STRATEGY` 키워드를 `container_scanning` 작업에서 `clone` 또는 `fetch`로 설정합니다. 기본적으로 `none`으로 설정되어 있으므로.

```yaml
container_scanning:
  variables:
    GIT_STRATEGY: fetch
```

## 독립 실행형 컨테이너 스캐닝 도구 실행 {#running-the-standalone-container-scanning-tool}

CI 작업의 컨텍스트 내에서 실행할 필요 없이 Docker 컨테이너에 대해 [GitLab 컨테이너 스캐닝 도구](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning)를 실행할 수 있습니다. 직접 이미지를 검사하려면 다음 단계를 따릅니다:

1. Docker Desktop 또는 Docker Machine을 실행합니다.
1. 분석기의 Docker 이미지를 실행하고 `CI_APPLICATION_REPOSITORY` 및 `CI_APPLICATION_TAG` 변수에서 분석하려는 이미지 및 태그를 전달합니다:

   ```shell
   docker run \
     --interactive --rm \
     --volume "$PWD":/tmp/app \
     -e CI_PROJECT_DIR=/tmp/app \
     -e CI_APPLICATION_REPOSITORY=registry.gitlab.com/gitlab-org/security-products/dast/webgoat-8.0@sha256 \
     -e CI_APPLICATION_TAG=bc09fe2e0721dfaeee79364115aeedf2174cce0947b9ae5fe7c33312ee019a4e \
     registry.gitlab.com/security-products/container-scanning
   ```

결과는 `gl-container-scanning-report.json`에 저장됩니다.

## JSON 형식 보고 {#reports-json-format}

컨테이너 스캐닝 도구는 GitLab 러너가 CI/CD 구성 파일의 `artifacts:reports` 키워드를 통해 인식하는 JSON 보고서를 내보냅니다.

CI/CD 작업이 완료되면 러너는 이 보고서를 GitLab에 업로드하므로 CI/CD 작업 아티팩트에서 사용할 수 있습니다. GitLab Ultimate에서는 이 보고서를 해당 파이프라인 및 취약성 보고서에서 볼 수 있습니다.

이러한 보고서는 [컨테이너 스캐닝 보고서 스키마](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/container-scanning-report-format.json)를 준수해야 합니다.

[예제 컨테이너 스캐닝 보고서](https://gitlab.com/gitlab-examples/security/security-reports/-/blob/master/samples/container-scanning.json).

### CycloneDX 소프트웨어 BOM(SBOM) {#cyclonedx-software-bill-of-materials}

JSON 보고서 파일 외에도 컨테이너 스캐닝 도구는 검사된 이미지에 대한 [CycloneDX](https://cyclonedx.org/) 소프트웨어 BOM(자재명세서)을 출력합니다. 이 CycloneDX SBOM의 이름은 `gl-sbom-report.cdx.json`이며 `JSON report file`과(와) 동일한 디렉터리에 저장됩니다. 이 기능은 Trivy 분석기를 사용할 때만 지원됩니다.

이 보고서는 [종속성 목록](../dependency_list/_index.md)에서 볼 수 있습니다.

[다른 작업 아티팩트와 동일한 방식으로](../../../ci/jobs/job_artifacts.md#download-job-artifacts) CycloneDX SBOM을 다운로드할 수 있습니다.

#### CycloneDX 보고서의 라이선스 정보 {#license-information-in-cyclonedx-reports}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/472064)되었습니다.

{{< /history >}}

컨테이너 스캐닝은 CycloneDX 보고서에 라이선스 정보를 포함할 수 있습니다. 이 기능은 기본적으로 비활성화되어 이전 버전과의 호환성을 유지합니다.

컨테이너 스캐닝 결과에서 라이선스 스캐닝을 활성화하려면:

- `CS_INCLUDE_LICENSES` 변수를 `.gitlab-ci.yml` 파일에 설정합니다:

```yaml
container_scanning:
  variables:
    CS_INCLUDE_LICENSES: "true"
```

- 이 기능을 활성화한 후 생성된 CycloneDX 보고서에는 컨테이너 이미지에서 감지된 구성 요소에 대한 라이선스 정보가 포함됩니다.
- 종속성 목록 페이지 또는 다운로드 가능한 CycloneDX 작업 아티팩트의 일부로 이 라이선스 정보를 볼 수 있습니다.

SPDX 라이선스만 지원된다는 점이 중요합니다. 그러나 SPDX를 준수하지 않는 라이선스는 사용자 대면 오류 없이 계속 수집됩니다.

## 수명 종료 운영 체제 감지 {#end-of-life-operating-system-detection}

컨테이너 스캐닝은 컨테이너 이미지가 수명 종료(EOL)에 도달한 운영 체제를 사용하는 시점을 감지하고 보고할 수 있습니다. EOL에 도달한 운영 체제는 더 이상 보안 업데이트를 받지 않으므로 새로 발견된 보안 문제에 취약합니다.

EOL 감지 기능은 Trivy를 사용하여 해당 배포판에서 더 이상 지원하지 않는 운영 체제를 식별합니다. EOL 운영 체제가 감지되면 다른 보안 결과와 함께 컨테이너 스캐닝 보고서의 취약성으로 보고됩니다.

EOL 감지를 활성화하려면 `CS_REPORT_OS_EOL`을(를) `"true"`로 설정합니다.

## 레지스트리 컨테이너 스캐닝 {#container-scanning-for-registry}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.1에서 `enable_container_scanning_for_registry` [기능 플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/groups/gitlab-org/-/epics/2340)되었습니다. 기본적으로 비활성화되었습니다.
- [GitLab 17.2에서 GitLab Self-Managed 및 GitLab Dedicated에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/443827)됨.
- GitLab 17.2에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/443827)합니다. `enable_container_scanning_for_registry` 기능 플래그가 제거되었습니다.

{{< /history >}}

`latest` 태그를 사용하여 컨테이너 이미지를 푸시하면 보안 정책 봇이 기본 브랜치에 대해 새 파이프라인에서 컨테이너 스캐닝 작업을 자동으로 트리거합니다.

일반 컨테이너 스캐닝과 달리 검사 결과에는 보안 보고서가 포함되지 않습니다. 대신 레지스트리 컨테이너 스캐닝은 [지속적인 취약성 검사](../continuous_vulnerability_scanning/_index.md)에 의존하여 검사로 감지된 구성 요소를 검사합니다.

보안 결과가 식별되면 GitLab이 이 결과를 사용하여 취약성 보고서를 채웁니다. 취약성은 취약성 보고서 페이지의 **컨테이너 레지스트리 취약성** 탭에서 볼 수 있습니다.

레지스트리 컨테이너 스캐닝은 새 자문이 [GitLab 자문 데이터베이스](../gitlab_advisory_database/_index.md)에 게시될 때만 취약성 보고서를 채웁니다. 취약성 보고서를 새로 감지된 데이터만이 아닌 현재의 모든 자문 데이터로 채우기 위한 지원은 [에픽 11219](https://gitlab.com/groups/gitlab-org/-/epics/11219)에서 제안됩니다.

> [!warning]
> 레지스트리 컨테이너 스캐닝으로 감지된 취약성은 취약한 구성 요소를 업데이트하거나 제거할 때 자동으로 해결된 것으로 표시될 수 없습니다. 이러한 취약성은 이 기능이 취약성 해결에 필요한 보안 보고서가 아닌 SBOM만 생성하므로 무한정 표시됩니다.

### 레지스트리 컨테이너 스캐닝 켜기 {#turn-on-container-scanning-for-registry}

전제 조건:

- 프로젝트에 대한 보안 관리자, 유지 보수자 또는 소유자 역할.
- 프로젝트는 비어 있으면 안 됩니다. 컨테이너 이미지 저장 전용 빈 프로젝트를 사용하는 경우 이 기능은 의도한 대로 작동하지 않습니다. 해결 방법으로 프로젝트에 기본 브랜치의 초기 커밋이 포함되어 있는지 확인합니다.
- 기본적으로 프로젝트당 하루에 `50` 검사의 제한이 있습니다.
- [컨테이너 레지스트리 알림을 구성](../../../administration/packages/container_registry.md#configure-container-registry-notifications)해야 합니다.
- [패키지 메타데이터 데이터베이스 구성](../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)해야 합니다. GitLab.com에서는 기본적으로 구성되어 있습니다.

GitLab 컨테이너 레지스트리에 대한 컨테이너 스캐닝을 켜려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **레지스트리 컨테이너 스캐닝** 섹션까지 아래로 스크롤한 후 토글을 켭니다.

### 오프라인 또는 격리된 환경에서 사용 {#use-with-offline-or-air-gapped-environments}

인터넷을 통해 외부 리소스에 대한 액세스가 제한되거나 제한적이거나 간헐적인 환경의 인스턴스의 경우 레지스트리 컨테이너 스캐닝을 성공적으로 실행하기 위해 일부 조정을 수행해야 합니다. 자세한 내용은 [오프라인 환경](../offline_deployments/_index.md)을 참조하세요.

레지스트리 컨테이너 스캐닝은 GitLab 보안 정책 봇에서 관리하므로 `.gitlab-ci.yml` 파일을 편집하여 분석기 이미지를 구성할 수 없습니다. 대신 GitLab UI에서 `CS_ANALYZER_IMAGE` CI/CD 변수를 설정하여 기본 스캐너 이미지를 재정의합니다. 동적으로 생성된 스캐닝 작업은 UI에 정의된 변수를 상속합니다. 프로젝트, 그룹 또는 인스턴스 CI/CD 변수를 사용할 수 있습니다.

전제 조건:

- 프로젝트 또는 그룹에 대한 유지 관리자 또는 소유자 역할입니다.
- Docker 또는 Kubernetes 실행기를 사용하는 GitLab 러너입니다.
- 컨테이너 스캐닝 분석기 이미지의 로컬 복사본입니다.
- [패키지 메타데이터 데이터베이스(PMDB)](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)에 액세스합니다.

  컨테이너 이미지에서 감지된 구성 요소에 대한 자문 데이터를 보유해야 합니다. 레지스트리 컨테이너 스캐닝은 [지속적인 취약성 검사](../continuous_vulnerability_scanning/_index.md)에 의존하여 취약성을 채우므로 동기화된 자문 데이터가 필요합니다. PMDB 동기화 없이 레지스트리 컨테이너 스캐닝은 검사가 성공적으로 완료되었더라도 취약성 보고서를 채우지 않습니다.

오프라인 환경에서 컨테이너 스캐닝 분석기를 사용하려면:

1. `registry.gitlab.com`에서 [로컬 컨테이너 레지스트리](../../packages/container_registry/_index.md)로 컨테이너 스캐닝 이미지를 가져옵니다([컨테이너 이미지 복사](#copy-container-image)에 설명된 대로).

   로컬 컨테이너 레지스트리로 이미지를 가져오는 프로세스는 네트워크 보안 정책에 따라 달라집니다. IT 팀과 상담하여 외부 리소스를 가져오거나 일시적으로 액세스할 수 있는 허용되고 승인된 프로세스를 찾습니다.

1. `CS_ANALYZER_IMAGE` CI/CD 변수를 설정하여 로컬 분석기 이미지를 사용하도록 GitLab 보안 정책 봇을 구성합니다:

   1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
   1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
   1. **변수** 섹션을 확장합니다.
   1. **변수 추가**를 선택하고 세부 정보를 입력합니다:
      - 키: `CS_ANALYZER_IMAGE`
      - 값: 미러링된 컨테이너 스캐닝 이미지의 전체 URL입니다. 예를 들어, `my.local.registry:5000/analyzers/container-scanning:8`입니다.
   1. **변수 추가**를 선택합니다.

GitLab 보안 정책 봇은 검사를 트리거할 때 지정된 이미지를 사용합니다.

## 취약성 데이터베이스 {#vulnerabilities-database}

모든 분석기 이미지는 [매일 업데이트](https://gitlab.com/gitlab-org/security-products/analyzers/container-scanning/-/blob/master/README.md#image-updates)됩니다.

이미지는 업스트림 자문 데이터베이스의 데이터를 사용합니다:

- AlmaLinux 보안 자문
- Amazon Linux 보안 센터
- Arch Linux 보안 추적기
- SUSE CVRF
- CWE 자문
- Debian 보안 버그 추적기
- GitHub 보안 자문
- Go 취약성 데이터베이스
- CBL-Mariner 취약성 데이터
- NVD
- OSV
- Red Hat OVAL v2
- Red Hat 보안 데이터 API
- Photon 보안 자문
- Rocky Linux UpdateInfo
- Ubuntu CVE 추적기(2021년 중반 이후의 데이터 소스만)

이러한 스캐너에서 제공하는 소스 외에도 GitLab은 다음 취약성 데이터베이스를 유지 관리합니다:

- 독점 [GitLab 자문 데이터베이스](https://gitlab.com/gitlab-org/security-products/gemnasium-db).
- 오픈 소스 [GitLab 자문 데이터베이스(오픈 소스 에디션)](https://gitlab.com/gitlab-org/advisories-community).

GitLab Ultimate 티어에서는 GitLab 자문 데이터베이스의 데이터가 병합되어 외부 소스의 데이터를 증강합니다. GitLab Premium 및 Free 티어에서 GitLab 자문 데이터베이스(오픈 소스 에디션)의 데이터가 병합되어 외부 소스의 데이터를 증강합니다. 이 증강은 Trivy 스캐너용 분석기 이미지에만 적용됩니다.

다른 분석기의 데이터베이스 업데이트 정보는 [유지 관리 표](../detect/vulnerability_scanner_maintenance.md)에서 확인할 수 있습니다.

## 취약성 솔루션(자동 수정) {#solutions-for-vulnerabilities-auto-remediation}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

일부 취약성은 GitLab이 자동으로 생성하는 솔루션을 적용하여 해결할 수 있습니다.

수정 지원을 활성화하려면 검사 도구가 CI/CD 변수 `CS_DOCKERFILE_PATH`에서 지정한 `Dockerfile`에 액세스해야 합니다. 검사 도구가 이 파일에 액세스할 수 있도록 하려면 이 문서의 [컨테이너 스캐닝 템플릿 재정의](#overriding-the-container-scanning-template) 섹션에 설명된 지침을 따라 `.gitlab-ci.yml` 파일에서 [`GIT_STRATEGY: fetch`](../../../ci/runners/configure_runners.md#git-strategy)을(를) 설정해야 합니다.

[취약성 솔루션](../vulnerabilities/_index.md#resolve-a-vulnerability)에 대해 자세히 알아봅니다.
