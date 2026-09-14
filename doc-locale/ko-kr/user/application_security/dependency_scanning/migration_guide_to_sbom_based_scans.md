---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SBOM을 사용한 종속성 검사로 마이그레이션
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Gemnasium 분석기 기반의 종속성 검사 기능은 GitLab 17.9에서 더 이상 사용되지 않으며 GitLab 20.0에서 제거될 것으로 예정되어 있습니다. 그러나 제거 일정은 확정되지 않았으며 필요에 따라 Gemnasium을 계속 사용할 수 있습니다.

{{< /history >}}

종속성 검사 기능이 GitLab SBOM 취약성 스캐너로 업그레이드되고 있습니다. 이 변경의 일환으로 [SBOM을 사용한 종속성 검사](dependency_scanning_sbom/_index.md) 기능 및 [새로운 종속성 검사 분석기](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)가 [Gemnasium 분석기](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium)를 기반으로 하는 레거시 종속성 검사 기능을 대체합니다. 그러나 이 전환에 도입된 중대한 변경 사항으로 인해 기존 프로젝트는 자동으로 마이그레이션되지 않습니다.

GitLab 종속성 검사를 사용하고 다음 조건 중 하나 이상이 적용되는 경우 이 마이그레이션 가이드를 따르세요:

- 종속성 검사 CI/CD 작업이 종속성 검사 CI/CD 템플릿 중 하나를 포함하여 구성되어 있습니다.

  ```yaml
    include:
      - template: Jobs/Dependency-Scanning.gitlab-ci.yml
      - template: Jobs/Dependency-Scanning.latest.gitlab-ci.yml
  ```

- 종속성 검사 CI/CD 작업이 [검사 실행 정책](../policies/scan_execution_policies.md)을 사용하여 구성되어 있습니다.
- 종속성 검사 CI/CD 작업이 [파이프라인 실행 정책](../policies/pipeline_execution_policies.md)을 사용하여 구성되어 있습니다.

## 마이그레이션 준비 {#prepare-for-migration}

마이그레이션 노력을 평가하고, 경로를 파악하고, 전제 조건을 확인하고, 영향을 받는 프로젝트를 파악합니다.

### 마이그레이션 노력 예상 {#estimate-migration-effort}

[종속성 검사 마이그레이션 평가기](https://dependency-scanning-migration-evaluator-cb84d1.gitlab.io/)는 프로젝트에서 종속성 검사가 구성된 방식을 기반으로 맞춤형 마이그레이션 체크리스트를 생성합니다. 활성화 경로, 언어 생태계, CI/CD 사용자 지정 및 (셀프 호스팅 인스턴스의 경우) 패키지 메타데이터 데이터베이스 동기화 상태에 대해 묻습니다. 평가기는 다음을 생성합니다:

- 노력 예상(최소, 중간, 상당함 또는 복잡함).
- 설정에 적용되는 마이그레이션 단계의 체크리스트(이 가이드의 관련 섹션으로 직접 링크 포함).
- 추가 주의가 필요한 상황에 대한 플래그(예: 검사 실행 정책에서 파이프라인 실행 정책으로 이동해야 하는 프로젝트).

평가기는 브라우저에서 완전히 실행되며 어디에도 데이터를 전송하지 않습니다.

### 마이그레이션 경로 파악 {#identify-your-migration-path}

기존 구성은 자동으로 마이그레이션되지 않습니다. 새로운 기능을 채택하려면 구성을 업데이트해야 합니다.

다음 목록을 사용하여 적용되는 마이그레이션 경로를 찾으세요:

- 안정적인 템플릿(`Jobs/Dependency-Scanning.gitlab-ci.yml`): `v2` 템플릿으로 전환하려면 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 따르세요. 그런 다음 프로젝트에서 사용되는 생태계에 대해 [언어별 지침](#language-specific-instructions)을 적용하세요.
- 최신 템플릿(`Jobs/Dependency-Scanning.latest.gitlab-ci.yml`): 안정적인 템플릿과 동일합니다. `v2` 템플릿으로 전환하려면 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 따르세요. 그런 다음 [언어별 지침](#language-specific-instructions)을 적용하세요.
- CI/CD 구성 요소: [주요 구성 요소](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main)는 이미 새로운 분석기를 사용하지만 이전 버전(v0 및 v1)은 분석기 버전 및 지원되는 입력에서 뒤떨어져 있습니다. 포함을 `v2` 버전으로 업그레이드하고 [언어별 지침](#language-specific-instructions)을 적용하세요. Android, Rust, Swift 또는 CocoaPods 전문 구성 요소를 사용 중인 경우 주요 구성 요소로 마이그레이션하세요.
- 검사 실행 정책(SEP) 또는 파이프라인 실행 정책(PEP): 정책을 편집하여 `v2` 템플릿을 참조하고, [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)와 범위 내 프로젝트에 대한 [언어별 지침](#language-specific-instructions)을 따르세요. SEP 및 PEP는 CI/CD 템플릿 위에 구축되므로 템플릿 변경 사항이 SEP 업데이트 후 범위 내 모든 프로젝트에 자동으로 전파됩니다. PEP의 경우 정책의 CI/CD 구성을 직접 업데이트하여 `v2` 템플릿을 참조하세요.

### 전제 조건 확인: 패키지 메타데이터 데이터베이스 동기화 {#verify-prerequisites-package-metadata-database-synchronization}

새로운 종속성 검사 분석기는 프로젝트에서 사용하는 패키지 유형에 대해 [패키지 메타데이터 데이터베이스(PMDB)](../../../administration/settings/security_and_compliance.md#package-metadata-database-synchronization)가 동기화되어야 합니다. GitLab.com에서는 인스턴스가 이미 지원되는 모든 패키지 유형에 대한 데이터를 동기화합니다. GitLab Self-Managed 및 GitLab Dedicated에서는 관리자가 동기화를 구성합니다.

마이그레이션하기 전에 관리자는 다음을 수행해야 합니다:

- PMDB 동기화가 활성화되어 있고 프로젝트에서 사용하는 패키지 유형이 선택되어 있는지 확인하세요. 자세한 내용은 [동기화할 패키지 레지스트리 메타데이터 선택](../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)을 참조하세요.
- 오프라인 또는 방화벽이 있는 인스턴스의 경우 [패키지 메타데이터 데이터베이스 활성화](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)를 따르세요.

프로젝트에서 사용하는 패키지 유형에 대해 PMDB 동기화가 완료되지 않은 경우 새 분석기는 해당 구성 요소에 대한 권고사항을 해결할 수 없으며 마이그레이션 후 보안 결과가 누락될 수 있습니다.

### 영향을 받는 프로젝트 파악 {#identify-affected-projects}

레거시 종속성 검사 기능을 사용하는 프로젝트를 파악합니다. [보안 인벤토리](../security_inventory/_index.md)는 그룹 및 프로젝트 전체의 스캐너 범위를 표시합니다. 이 단계가 권장되는 시작점입니다.

CI/CD 구성에서도 레거시 사용을 찾을 수 있습니다:

- `Jobs/Dependency-Scanning.gitlab-ci.yml` 또는 `Jobs/Dependency-Scanning.latest.gitlab-ci.yml` 레거시 템플릿을 `.gitlab-ci.yml` 파일에 포함시킵니다.
- 검사 실행 정책 및 파이프라인 실행 정책에서 동일한 템플릿에 대한 참조입니다.
- 레거시 분석기의 작업 이름(`gemnasium-dependency_scanning`, `gemnasium-maven-dependency_scanning`, `gemnasium-python-dependency_scanning`)을 `.gitlab-ci.yml` 파일, 정책 YAML이나 `needs:` 또는 `dependencies:`에서 사용하는 다운스트림 작업에 포함시킵니다.

## 변경 사항 이해 {#understand-the-changes}

Gemnasium 분석기에서 새로운 종속성 검사 분석기로의 전환은 중대한 기술적 진화입니다. 대부분의 프로젝트는 [SBOM을 사용한 종속성 검사로 마이그레이션](#migrate-to-dependency-scanning-using-sbom)에 설명된 CI/CD 구성 전환 외에는 변경할 필요가 없습니다. 이 섹션에 설명된 변경 사항은 일부 프로젝트(특히 Gradle, Maven 및 잠금 파일이 없는 Python)에서 추가 단계가 필요한 이유를 이해하는 데 도움이 됩니다.

주요 변경 사항:

- 향상된 언어 지원 및 파일 범위: 새 분석기는 Gemnasium 분석기가 지원하는 Python 및 Java 버전으로 제한되지 않으며 증가된 [파일 범위](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)의 이점을 누립니다.
- 향상된 성능: 새 분석기는 기존 잠금 파일 또는 종속성 그래프 내보내기를 선호하고 이들이 없는 프로젝트의 경우에만 생태계별 [해결 작업](dependency_scanning_sbom/_index.md#dependency-resolution)을 실행합니다.
- 더 작은 공격 표면 및 더 유연한 구성: 분석기 이미지는 잠금 파일 및 그래프 내보내기만 구문 분석합니다. 생태계별 설정(프라이빗 레지스트리, 사용자 지정 CA 번들, JVM 옵션)은 관련 종속성 해결 작업에만 적용됩니다. 빌드 환경과 일치하도록 해결 이미지를 재정의할 수 있습니다.

### 보안 스캔에 대한 새로운 접근 방식 {#a-new-approach-to-security-scanning}

레거시 종속성 검사 기능을 사용할 때 모든 스캔 작업이 CI/CD 파이프라인에서 발생합니다. 스캔을 실행할 때 Gemnasium 분석기는 두 가지 중요한 작업을 동시에 처리합니다. 프로젝트의 종속성을 파악하고 GitLab 권고 데이터베이스의 로컬 복사본 및 특정 보안 스캔 엔진을 사용하여 이러한 종속성에 대한 보안 분석을 즉시 수행합니다. 그런 다음 결과를 다양한 보고서(CycloneDX SBOM 및 종속성 검사 보안 보고서)로 출력합니다.

반면 SBOM을 사용한 종속성 검사 기능은 종속성 감지를 정적 도달성 또는 취약성 스캔 같은 다른 분석과 분리하는 분해된 종속성 분석 접근 방식에 의존합니다. 이러한 작업은 여전히 같은 CI/CD 작업에서 실행되지만 분리된 재사용 가능한 구성 요소로 기능합니다. 예를 들어 취약성 스캔 분석은 GitLab 지속적 취약성 스캔 기능도 지원하는 GitLab SBOM 취약성 스캐너인 통합 엔진을 재사용합니다. 이는 또한 향후 통합 지점에 대한 기회를 열어 더욱 유연한 취약성 스캔 워크플로우를 가능하게 합니다.

SBOM을 사용한 종속성 검사가 [애플리케이션을 스캔하는](dependency_scanning_sbom/_index.md#how-it-scans-an-application) 방식에 대해 자세히 알아보세요.

### Gradle, Maven 및 Python의 종속성 감지 {#dependency-detection-for-gradle-maven-and-python}

새 분석기는 Gradle, Maven 및 Python 프로젝트의 종속성 발견 방식을 변경합니다. 응용 프로그램을 빌드하여 종속성을 결정하는 대신 분석기는 "정확성은 조정 가능"이라는 원칙을 따르는 다계층 감지 모델을 사용합니다:

1. 잠금 파일 또는 종속성 그래프 내보내기: 지원되는 파일이 리포지토리에 커밋되거나 작업 아티팩트로 전달되는 경우(예: `maven.graph.json`, `dependencies.lock`, `requirements.txt`, `Pipfile.lock`) 분석기는 이를 직접 사용합니다. 이는 가장 정확한 옵션입니다.
1. [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution): Maven, Gradle 또는 Python 프로젝트에 대해 지원되는 파일이 없는 경우 분석기는 자동으로 파일을 생성하려고 시도합니다. 해결 작업은 `.pre` 스테이지에서 최소한의 생태계 이미지 및 기본 명령(예: `mvn dependency:tree`, `pip-compile`, `gradle dependencies`)으로 실행됩니다. `dependency-scanning` 작업은 생성된 아티팩트를 사용합니다.
1. [매니페스트 폴백](dependency_scanning_sbom/_index.md#manifest-fallback): 잠금 파일이나 종속성 그래프 파일이 없는 경우 분석기는 지원되는 매니페스트 파일(예: `pom.xml`, `requirements.txt`, `build.gradle`, `build.gradle.kts`)을 구문 분석하여 직접 종속성만 추출합니다. 전이적 종속성은 감지되지 않으며 정확한 해결된 버전을 결정할 수 없습니다.

GitLab 19.0 이상에서는 종속성 해결 및 매니페스트 폴백이 기본적으로 활성화됩니다.

가장 정확한 결과를 원하면 잠금 파일 또는 종속성 그래프 내보내기를 리포지토리에 커밋하거나 프로젝트의 실제 빌드 환경을 사용하여 선행 CI/CD 작업에서 생성하세요. 다음 섹션에서는 각 언어 및 패키지 관리자에 사용 가능한 옵션을 설명합니다.

### 스캔 결과 액세스 {#accessing-scan-results}

`v2` 템플릿은 레거시 템플릿과 동일한 [`gl-dependency-scanning-report.json`](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning) 작업 아티팩트를 생성합니다. 이 아티팩트를 사용하는 다운스트림 작업(`needs:` 또는 `dependencies:` 포함)은 마이그레이션 후에도 계속 작동하지만 생성 작업 이름이 `gemnasium-dependency_scanning`(및 해당 Maven 및 Python 변형)에서 `dependency-scanning`로 변경됩니다.

## SBOM을 사용한 종속성 검사로 마이그레이션 {#migrate-to-dependency-scanning-using-sbom}

마이그레이션 방식은 프로젝트에서 종속성 검사가 활성화된 방식에 따라 달라집니다. 각 소단원에서는 제거할 사용자 지정 설정, 업데이트할 참조 및 최소한의 전후 예제를 다룹니다.

적용되는 소단원을 찾으려면 [마이그레이션 경로 파악](#identify-your-migration-path)을 참조하세요. 다중 언어 프로젝트의 경우 [언어별 지침](#language-specific-instructions)에서 각 언어에 대한 단계를 완료하세요.

### 안정적인 CI/CD 템플릿을 사용한 마이그레이션 {#migrate-using-the-stable-cicd-template}

기존 파이프라인을 중단하지 않도록 안정적인 템플릿(`Jobs/Dependency-Scanning.gitlab-ci.yml`)은 레거시 Gemnasium 분석기를 실행하며 새 분석기를 사용하도록 업데이트되지 않습니다. 새 분석기를 채택하려면 `include`를 `v2` 템플릿(`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`)으로 전환하세요.

안정적인 템플릿과 비교하여 `v2` 템플릿은:

- 레거시 `gemnasium-dependency_scanning`, `gemnasium-maven-dependency_scanning` 및 `gemnasium-python-dependency_scanning` 작업 대신 새로운 `dependency-scanning` 작업을 실행합니다.
- 레거시 작업 이름을 사전 정의하지 않습니다. `gemnasium-*` 작업을 재정의하는 사용자 지정 설정(예: `.gitlab-ci.yml`에서 확장)은 더 이상 적용되지 않으며 제거하거나 다시 작성해야 합니다.
- `gl-dependency-scanning-report.json` [작업 아티팩트](../../../ci/yaml/artifacts_reports.md#artifactsreportsdependency_scanning)를 계속 생성합니다. `needs:` 또는 `dependencies:`를 통해 이 아티팩트를 사용하는 다운스트림 작업은 마이그레이션 후에도 계속 작동하지만 레거시 `gemnasium-*` 작업 이름 대신 새로운 `dependency-scanning` 작업 이름을 참조해야 합니다.
- 동일한 CI/CD 변수를 수용하며 [CI/CD 변수 변경 사항](#changes-to-cicd-variables)에 설명된 일부 변경 사항이 있습니다.

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

안정적인 CI/CD 템플릿을 사용하여 마이그레이션하려면:

1. 레거시 `gemnasium-*` 작업을 재정의하는 사용자 지정 설정을 `.gitlab-ci.yml` 또는 포함된 파일에서 제거합니다. `v2` 템플릿은 이러한 작업 이름을 정의하지 않으므로 오버라이드로 인해 CI/CD 구성이 잘못되어 파이프라인이 실패할 수 있습니다.
1. `include` 문을 업데이트하여 `v2` 템플릿을 참조하세요.
1. `needs:` 또는 `dependencies:`에서 레거시 작업 이름을 참조하는 다운스트림 작업을 `dependency-scanning`를 사용하도록 업데이트하세요.
1. 프로젝트의 생태계에 대한 [언어별 지침](#language-specific-instructions)을 적용하세요.

이전:

```yaml
include:
  - template: Jobs/Dependency-Scanning.gitlab-ci.yml

# Customization that targets the legacy job name.
gemnasium-dependency_scanning:
  variables:
    SECURE_LOG_LEVEL: debug

# Downstream job that consumes the legacy report.
export-security-report:
  stage: deploy
  needs:
    - job: gemnasium-dependency_scanning
      artifacts: true
  script:
    - ./publish.sh gl-dependency-scanning-report.json
```

이후:

```yaml
include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
    inputs:
      analyzer_log_level: debug

export-security-report:
  stage: deploy
  needs:
    - job: dependency-scanning
      artifacts: true
  script:
    - ./publish.sh gl-dependency-scanning-report.json
```

파이프라인이 종속성 해결 전에 사용자 정의 작업을 실행해야 하는 경우(예: 프라이빗 레지스트리에 인증하거나 빌드 캐시 준비) [해결 작업 순서 조정](#adjust-resolution-job-ordering)을 참조하세요.

### 최신 CI/CD 템플릿을 사용한 마이그레이션 {#migrate-using-the-latest-cicd-template}

최신 템플릿(`Jobs/Dependency-Scanning.latest.gitlab-ci.yml`)은 기본적으로 레거시 Gemnasium 분석기를 실행합니다. 과도적 단계로서 `DS_ENFORCE_NEW_ANALYZER` CI/CD 변수를 통해 새 분석기에 옵트인할 수 있지만 새 분석기의 `v1` 버전에서만 [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution) 작업 없이만 가능합니다.

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

Maven, Gradle 및 Python 프로젝트의 경우 다음 중 하나를 수행해야 합니다:

- [잠금 파일 또는 종속성 그래프 내보내기](dependency_scanning_sbom/_index.md#supported-languages-and-files)를 리포지토리에 커밋하거나 선행 CI/CD 작업으로 생성합니다.
- [매니페스트 폴백](dependency_scanning_sbom/_index.md#manifest-fallback)을 활성화합니다.

`v2` 템플릿(`v2` 분석기, 종속성 해결, 매니페스트 폴백)과 완전히 동일하게 하려면 [안정적인 템플릿 단계](#migrate-using-the-stable-cicd-template)를 따라 `v2` 템플릿으로 전환하세요. 마이그레이션 작업은 동일합니다. 레거시 `gemnasium-*` 작업을 대상으로 하는 사용자 지정 설정을 제거하고, `include` 문을 업데이트하고, 다운스트림 작업을 업데이트하세요.

`DS_ENFORCE_NEW_ANALYZER`을 통해 새로운 DS 분석기를 사용하도록 이미 옵트인한 경우 전환이 더 간단합니다. 마이그레이션을 완료하기 전에 새 템플릿이 도입하는 변경 사항을 검토하세요.

파이프라인이 종속성 해결 전에 사용자 정의 작업을 실행해야 하는 경우(예: 프라이빗 레지스트리에 인증하거나 빌드 캐시 준비) [해결 작업 순서 조정](#adjust-resolution-job-ordering)을 참조하세요.

### CI/CD 구성 요소를 사용한 마이그레이션 {#migrate-using-the-cicd-component}

> [!note]
> GitLab Self-Managed에서 GitLab.com CI/CD 구성 요소 사용에 대한 [현재 제한 사항](../../../ci/components/_index.md#use-a-gitlabcom-component-on-gitlab-self-managed)을 검토하세요.

`v2` 릴리스의 [주요 종속성 검사 CI/CD 구성 요소](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main)는 `v2` 템플릿과 동일합니다. 새 분석기의 `v2` 버전을 실행하며 동일한 입력을 지원합니다. 이전 릴리스(`v0` 및 `v1`)는 분석기 버전 및 지원되는 기능에서 뒤떨어져 있으므로 `v0` 또는 `v1`를 포함하는 프로젝트는 `v2`로 업그레이드해야 합니다.

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

CI/CD 구성 요소를 사용하여 마이그레이션하려면:

1. 구성 요소 `include` 문을 업데이트하여 주요 구성 요소의 버전 `2`를 참조하세요.
1. `v2`에서 이름이 바뀌거나 제거된 입력을 모두 바꾸세요. 주요 구성 요소의 `v2` 릴리스는 `v2` CI/CD 템플릿과 동일한 입력 집합을 노출합니다. 전체 목록은 [사용 가능한 사양 입력](dependency_scanning_sbom/_index.md#available-spec-inputs) 참조를 참조하세요.
1. 프로젝트의 생태계에 대한 [언어별 지침](#language-specific-instructions)을 적용하세요.

Android, Rust, Swift 또는 CocoaPods 전문 구성 요소를 사용하는 경우 주요 구성 요소로 마이그레이션하세요. 주요 구성 요소는 이제 지원되는 모든 언어 및 패키지 관리자를 다룹니다. 전문 구성 요소가 더 이상 필요하지 않습니다.

이전:

```yaml
include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@1
```

이후:

```yaml
include:
  - component: $CI_SERVER_FQDN/components/dependency-scanning/main@2
```

파이프라인이 종속성 해결 전에 사용자 정의 작업을 실행해야 하는 경우(예: 프라이빗 레지스트리에 인증하거나 빌드 캐시 준비) [해결 작업 순서 조정](#adjust-resolution-job-ordering)을 참조하세요.

### 검사 실행 정책을 사용한 마이그레이션 {#migrate-using-scan-execution-policies}

검사 실행 정책은 정책이 대상으로 하는 프로젝트 전체에 CI/CD 템플릿을 적용합니다. 종속성 검사의 경우 정책의 `template` 필드가 실행할 템플릿을 선택합니다. 새 분석기는 `v2` 템플릿 에디션을 통해 사용할 수 있습니다.

정책의 각 대상 프로젝트에서의 동작은 해당 CI/CD 템플릿을 직접 포함하는 프로젝트의 동작과 같습니다. 정책이 `v2`을 참조하도록 업데이트된 후 범위 내 각 프로젝트에 대해 [안정적인 CI/CD 템플릿](#migrate-using-the-stable-cicd-template)의 단계가 적용됩니다. 레거시 `gemnasium-*` 작업을 대상으로 하는 사용자 지정 설정을 제거하고 이를 사용하는 다운스트림 작업을 업데이트합니다.

전제 조건:

- 그룹의 소유자 역할 또는 `manage_security_policy_link` 권한이 있는 사용자 지정 역할.

검사 실행 정책을 사용하여 마이그레이션하려면:

1. 검사 실행 정책을 편집하고 `dependency_scanning` 작업에 대해 `template: v2`를 설정합니다.
1. 정책이 적용되는 각 프로젝트에서 레거시 `gemnasium-*` 작업을 재정의하는 사용자 지정 설정을 제거하고 이를 참조하는 다운스트림 작업을 업데이트합니다.
1. 정책이 적용되는 프로젝트의 생태계에 대한 [언어별 지침](#language-specific-instructions)을 적용합니다.

이전:

```yaml
scan_execution_policy:
  - name: Enforce dependency scanning
    enabled: true
    rules:
      - type: pipeline
        branch_type: all
    actions:
      - scan: dependency_scanning
```

이후:

```yaml
scan_execution_policy:
  - name: Enforce dependency scanning
    enabled: true
    rules:
      - type: pipeline
        branch_type: all
    actions:
      - scan: dependency_scanning
        template: v2
```

#### 종속성 해결 또는 매니페스트 폴백에 포함되지 않는 프로젝트 {#projects-not-covered-by-dependency-resolution-or-manifest-fallback}

검사 실행 정책은 레거시 Gemnasium 분석기의 `build support` 기능을 사용하여 기본 빌드 환경을 제공합니다. 새 분석기는 [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution) 또는 [매니페스트 폴백](dependency_scanning_sbom/_index.md#manifest-fallback)에 의존하여 커밋된 잠금 파일 또는 종속성 그래프 내보내기가 없는 프로젝트에 대한 종속성을 감지합니다.

이러한 메커니즘은 이전에 `build support`에 의존했던 대부분의 프로젝트를 다룹니다. 파이프라인 실행 정책의 추가 유연성이 여전히 유용한 몇 가지 상황이 있습니다:

- 프로젝트의 생태계가 종속성 해결 및 매니페스트 폴백의 현재 범위를 벗어났습니다(예: Scala/sbt).
- 종속성 해결은 사용 가능한 CI/CD 변수를 초과하는 설정 단계가 필요합니다(예: 비표준 자격 증명을 사용하여 프라이빗 레지스트리에 대해 인증).

이러한 프로젝트의 경우 [파이프라인 실행 정책](#migrate-using-pipeline-execution-policies)을 사용합니다. 여기서 CI/CD 작업을 더욱 자유롭게 사용자 정의할 수 있으며 [잠금 파일 또는 종속성 그래프 내보내기를 수동으로 생성](dependency_scanning_sbom/_index.md#create-lockfile-or-dependency-graph-export-manually)할 수 있습니다.

### 파이프라인 실행 정책을 사용한 마이그레이션 {#migrate-using-pipeline-execution-policies}

파이프라인 실행 정책은 종속성 검사 템플릿 또는 CI/CD 구성 요소(일반적으로 프로젝트별 사용자 지정 설정과 함께)를 포함하는 완전한 CI/CD 구성을 적용합니다. 적용되는 마이그레이션 단계는 정책의 CI/CD 구성이 포함하는 내용에 따라 달라집니다.

전제 조건:

- 그룹의 소유자 역할 또는 `manage_security_policy_link` 권한이 있는 사용자 지정 역할.

파이프라인 실행 정책을 사용하여 마이그레이션하려면:

1. 정책이 사용하는 템플릿 또는 구성 요소를 결정합니다:
   - 정책이 안정적인 CI/CD 템플릿을 포함하는 경우 [안정적인 CI/CD 템플릿을 사용한 마이그레이션](#migrate-using-the-stable-cicd-template)을 따르세요.
   - 정책이 최신 CI/CD 템플릿을 포함하는 경우 [최신 CI/CD 템플릿을 사용한 마이그레이션](#migrate-using-the-latest-cicd-template)을 따르세요.
   - 정책이 CI/CD 구성 요소를 포함하는 경우 [CI/CD 구성 요소를 사용한 마이그레이션](#migrate-using-the-cicd-component)을 따르세요.

1. 이 단계를 정책의 CI/CD 구성에 적용합니다.
1. 정책이 적용되는 프로젝트의 생태계에 대한 [언어별 지침](#language-specific-instructions)을 적용합니다.

프로젝트, 그룹 또는 인스턴스에 대해 설정된 CI/CD 변수(및 정책 자체의 `variables:` 블록에 정의된 변수)는 새로운 `dependency-scanning` 작업과 이 작업 전에 실행되는 해결 작업에 계속 적용됩니다. `v2`에서 상태가 변경된 변수의 경우 [CI/CD 변수 변경 사항](#changes-to-cicd-variables)을 참조하세요.

파이프라인이 종속성 해결 전에 사용자 정의 작업을 실행해야 하는 경우(예: 프라이빗 레지스트리에 인증하거나 빌드 캐시 준비) [해결 작업 순서 조정](#adjust-resolution-job-ordering)을 참조하세요.

## 기타 고려 사항 {#other-considerations}

다음 사용자 지정 설정은 프로젝트에서 종속성 검사를 활성화하는 방식에 관계없이 적용됩니다.

### 해결 작업 순서 조정 {#adjust-resolution-job-ordering}

기본적으로 종속성 해결 작업은 `.pre` 스테이지에서 실행됩니다. 파이프라인에 종속성 스캔이 실행되기 전에 완료해야 하는 사용자 정의 작업이 있는 경우(예: 프라이빗 레지스트리에 인증하거나 빌드 캐시를 준비하는 `.pre` 작업) 해결 작업은 이러한 사용자 정의 작업과 병렬로 실행되지 않습니다. 해결 작업은 사용자 정의 작업이 생성하는 아티팩트를 볼 수 없습니다.

의도한 순서를 유지하려면 `resolution_jobs_stage` 입력을 `v2` 템플릿 또는 구성 요소에 사용하여 해결 작업을 나중 스테이지로 이동합니다:

```yaml
stages:
  - .pre
  - prepare
  - test

include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml
    inputs:
      resolution_jobs_stage: prepare

private-registry-cache-build:
  stage: .pre
  script:
    - ./scripts/login-private-registry.sh
    - ./scripts/build-dependency-cache.sh
```

그러면 해결 작업이 `prepare` 스테이지에서 실행되며 사용자 정의 `.pre` 작업이 완료된 후에 실행됩니다. 해결 작업 동작을 제어하는 입력의 전체 목록은 [사용 가능한 CI/CD 입력](dependency_scanning_sbom/_index.md#available-spec-inputs)을 참조하세요.

## 언어별 지침 {#language-specific-instructions}

새 종속성 검사 분석기로 마이그레이션하면 프로젝트의 프로그래밍 언어 및 패키지 관리자를 기반으로 특정 조정을 수행해야 합니다. 이 지침은 새 종속성 검사 분석기를 사용할 때마다 적용되며 구성 방식(CI/CD 템플릿, 검사 실행 정책 또는 종속성 검사 CI/CD 구성 요소)에 관계없이 적용됩니다. 다음 섹션에서는 지원되는 각 언어 및 패키지 관리자에 대한 자세한 지침을 찾을 수 있습니다. 각 지침에는 다음에 대한 설명이 있습니다:

- 종속성 감지가 어떻게 변경되는지
- 제공해야 할 특정 파일
- 워크플로우에 아직 포함되지 않은 경우 이러한 파일을 생성하는 방법

새로운 종속성 검사 분석기에 대한 피드백을 이 [피드백 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/523458)에서 공유해 주세요.

### Bundler {#bundler}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-dependency_scanning` CI/CD 작업을 사용하는 Bundler 프로젝트를 지원하며 `Gemfile.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출할 수 있습니다(`gems.locked` 대체 파일 이름도 지원됨). 지원되는 Bundler 버전 조합과 `Gemfile.lock` 파일은 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)에 자세히 설명되어 있습니다.

**New behavior**: 새 종속성 검사 분석기도 `Gemfile.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출하고(`gems.locked` 대체 파일 이름도 지원됨) `dependency-scanning` CI/CD 작업으로 CycloneDX SBOM 보고서 아티팩트를 생성합니다.

#### Bundler 프로젝트 마이그레이션 {#migrate-a-bundler-project}

Bundler 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

Bundler 프로젝트를 종속성 검사 분석기로 마이그레이션하는 데 추가 단계는 필요하지 않습니다.

### CocoaPods {#cocoapods}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 CI/CD 템플릿 또는 검사 실행 정책을 사용할 때 CocoaPods 프로젝트를 지원하지 않습니다. CocoaPods 지원은 실험용 CocoaPods CI/CD 구성 요소에서만 사용할 수 있습니다.

**New behavior**: 새 종속성 검사 분석기는 `Podfile.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출하고 `dependency-scanning` CI/CD 작업으로 CycloneDX SBOM 보고서 아티팩트를 생성합니다.

#### CocoaPods 프로젝트 마이그레이션 {#migrate-a-cocoapods-project}

CocoaPods 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

CocoaPods 프로젝트를 종속성 검사 분석기로 마이그레이션하는 데 추가 단계는 필요하지 않습니다.

### Composer {#composer}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-dependency_scanning` CI/CD 작업을 사용하는 Composer 프로젝트를 지원하며 `composer.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출할 수 있습니다. 지원되는 Composer 버전 조합과 `composer.lock` 파일은 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)에 자세히 설명되어 있습니다.

**New behavior**: 새 종속성 검사 분석기도 `composer.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출하고 `dependency-scanning` CI/CD 작업으로 CycloneDX SBOM 보고서 아티팩트를 생성합니다.

#### Composer 프로젝트 마이그레이션 {#migrate-a-composer-project}

Composer 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

Composer 프로젝트를 종속성 검사 분석기로 마이그레이션하는 데 추가 단계는 필요하지 않습니다.

### Conan {#conan}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-dependency_scanning` CI/CD 작업을 사용하는 Conan 프로젝트를 지원하며 `conan.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출할 수 있습니다. 지원되는 Conan 버전 조합과 `conan.lock` 파일은 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)에 자세히 설명되어 있습니다.

**New behavior**: 새 종속성 검사 분석기도 `conan.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출하고 `dependency-scanning` CI/CD 작업으로 CycloneDX SBOM 보고서 아티팩트를 생성합니다.

#### Conan 프로젝트 마이그레이션 {#migrate-a-conan-project}

Conan 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

Conan 프로젝트를 종속성 검사 분석기로 마이그레이션하는 데 추가 단계는 필요하지 않습니다.

### Go {#go}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-dependency_scanning` CI/CD 작업을 사용하는 Go 프로젝트를 지원하며 `go.mod` 및 `go.sum` 파일을 사용하여 프로젝트 종속성을 추출할 수 있습니다. 이 분석기는 `go list` 명령을 실행하여 감지된 종속성의 정확성을 높이려고 시도하며 이를 위해서는 기능하는 Go 환경이 필요합니다. 실패하는 경우 `go.sum` 파일을 구문 분석하도록 폴백합니다. 지원되는 Go 버전, `go.mod` 및 `go.sum` 파일의 조합은 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)에 자세히 설명되어 있습니다.

**New behavior**: 새 종속성 검사 분석기는 프로젝트에서 `go list` 명령을 실행하여 종속성을 추출하려고 시도하지 않으며 더 이상 `go.sum` 파일을 구문 분석하도록 폴백하지 않습니다. 대신 프로젝트는 최소한 `go.mod` 파일을 제공해야 하며 이상적으로는 Go 도구 체인의 [`go mod graph` 명령](https://go.dev/ref/mod#go-mod-graph)으로 생성된 `go.graph` 파일을 제공해야 합니다. `go.graph` 파일은 감지된 구성 요소의 정확성을 높이고 [종속성 경로](../dependency_list/_index.md#dependency-paths)와 같은 기능을 활성화하기 위해 종속성 그래프를 생성해야 합니다. 이 파일들은 `dependency-scanning` CI/CD 작업으로 처리되어 CycloneDX SBOM 보고서 아티팩트를 생성합니다. 이 접근 방식은 GitLab이 특정 버전의 Go를 지원할 필요가 없습니다. [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution)은 Go 프로젝트에서 지원되지 않습니다.

#### Go 프로젝트 마이그레이션 {#migrate-a-go-project}

Go 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

Go 프로젝트를 마이그레이션하려면:

- 프로젝트가 `go.mod` 및 `go.graph` 파일을 제공하는지 확인하세요. 선행 CI/CD 작업(예: `build`)에서 Go 도구 체인의 [`go mod graph` 명령](https://go.dev/ref/mod#go-mod-graph)을 구성하여 `go.graph` 파일을 동적으로 생성하고 종속성 검사 작업을 실행하기 전에 [아티팩트](../../../ci/jobs/job_artifacts.md)로 내보냅니다.

자세한 내용과 예제는 [Go에 대한 활성화 지침](dependency_scanning_sbom/_index.md#go)을 참조하세요.

### Gradle {#gradle}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-maven-dependency_scanning` CI/CD 작업을 사용하는 Gradle 프로젝트를 지원하며 `build.gradle` 및 `build.gradle.kts` 파일에서 응용 프로그램을 빌드하여 프로젝트 종속성을 추출할 수 있습니다. Java, Kotlin 및 Gradle 지원 버전의 조합은 복잡하며 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)에 자세히 설명되어 있습니다.

**New behavior**: 새 종속성 검사 분석기는 종속성을 추출하기 위해 프로젝트를 빌드하지 않습니다. 대신 다계층 감지 모델을 사용합니다:

- [지원되는 잠금 파일 또는 그래프 내보내기](dependency_scanning_sbom/_index.md#supported-languages-and-files)가 리포지토리 또는 작업 아티팩트(예: `gradle.lockfile`)에 있으면 분석기가 이를 직접 사용합니다.
- 지원되는 잠금 파일 또는 그래프 내보내기가 감지되지 않았지만 지원되는 빌드 파일이 있으면(예: `build.gradle`) [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution) 작업이 `.pre` 스테이지에서 실행됩니다. 이는 `gradle dependencies`를 자동으로 실행하여 `dependency-scanning` 작업에 대한 종속성 그래프 내보내기를 생성합니다.
- 종속성 해결이 사용 불가하거나 실패하면 [매니페스트 폴백](dependency_scanning_sbom/_index.md#manifest-fallback)이 `build.gradle` 및 `build.gradle.kts`을 직접 구문 분석하여 직접 종속성만 추출합니다. 매니페스트 폴백 정확성은 `gradle.properties` 또는 `gradle/libs.versions.toml`를 통해 종속성을 선언하는 프로젝트의 경우 감소합니다. 버전 변수가 항상 해결되지 않기 때문입니다.

#### Gradle 프로젝트 마이그레이션 {#migrate-a-gradle-project}

Gradle 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

Gradle 프로젝트를 마이그레이션하려면 다음 옵션 중 하나를 선택합니다:

- 가장 정확한 결과를 원하면 프로젝트가 종속성 그래프 내보내기 파일을 제공하는지 확인하세요. 선행 CI/CD 작업(예: `build`)에서 [Gradle 종속성 작업](https://docs.gradle.org/current/userguide/viewing_debugging_dependencies.html)을 구성하여 `gradle.graph.txt` 파일을 동적으로 생성하고 종속성 검사 작업을 실행하기 전에 [아티팩트](../../../ci/jobs/job_artifacts.md)로 내보냅니다. 또는 다른 [지원되는 잠금 파일 또는 그래프 내보내기](dependency_scanning_sbom/_index.md#supported-languages-and-files)를 선택할 수 있습니다. 잠금 파일 또는 그래프 내보내기를 동적으로 생성할 때 `DS_DISABLED_RESOLUTION_JOBS` CI/CD 변수 값에 `gradle`를 추가하여 자동 종속성 해결을 비활성화합니다.
- [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution)을 사용하여 `gradle.graph.txt` 파일을 자동으로 생성합니다. 해결 이미지가 그래프 내보내기를 성공적으로 생성할 수 있는지 확인하세요.
- [매니페스트 폴백](dependency_scanning_sbom/_index.md#manifest-fallback)을 사용하여 `build.gradle` 또는 `build.gradle.kts`에서 선언된 직접 종속성을 기본 범위로 사용합니다.

자세한 내용과 예제는 [Gradle에 대한 활성화 지침](dependency_scanning_sbom/_index.md#gradle)을 참조하세요.

### Maven {#maven}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-maven-dependency_scanning` CI/CD 작업을 사용하는 Maven 프로젝트를 지원하며 `pom.xml` 파일에서 응용 프로그램을 빌드하여 프로젝트 종속성을 추출할 수 있습니다. Java, Kotlin 및 Maven 지원 버전의 조합은 복잡하며 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)에 자세히 설명되어 있습니다.

**New behavior**: 새 종속성 검사 분석기는 종속성을 추출하기 위해 프로젝트를 빌드하지 않습니다. 대신 다계층 감지 모델을 사용합니다:

- [Maven 종속성 플러그인](https://maven.apache.org/plugins/maven-dependency-plugin/index.html)으로 생성된 `maven.graph.json` 그래프 내보내기 파일이 리포지토리 또는 작업 아티팩트에 있으면 분석기가 이를 직접 사용합니다.
- 그래프 내보내기가 감지되지 않았지만 지원되는 `pom.xml` 파일이 있으면 [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution) 작업이 `.pre` 스테이지에서 실행됩니다. 이는 `mvn dependency:tree`를 자동으로 실행하여 `dependency-scanning` 작업에 대한 종속성 그래프 내보내기를 생성합니다.
- 종속성 해결이 사용 불가하거나 실패하면 [매니페스트 폴백](dependency_scanning_sbom/_index.md#manifest-fallback)이 `pom.xml`를 직접 구문 분석하여 직접 종속성만 추출합니다.

#### Maven 프로젝트 마이그레이션 {#migrate-a-maven-project}

Maven 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

Maven 프로젝트를 마이그레이션하려면 다음 옵션 중 하나를 선택합니다:

- 가장 정확한 결과를 원하면 프로젝트가 `maven.graph.json` 파일을 제공하는지 확인하세요. 선행 CI/CD 작업(예: `build`)에서 [Maven 종속성 플러그인](https://maven.apache.org/plugins/maven-dependency-plugin/index.html)을 구성하여 `maven.graph.json` 파일을 동적으로 생성하고 종속성 검사 작업을 실행하기 전에 [아티팩트](../../../ci/jobs/job_artifacts.md)로 내보냅니다. 그래프 내보내기를 동적으로 생성할 때 `DS_DISABLED_RESOLUTION_JOBS` CI/CD 변수 값에 `maven`를 추가하여 자동 종속성 해결을 비활성화합니다.
- [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution)을 사용하여 `maven.graph.json` 파일을 자동으로 생성합니다. 해결 이미지가 그래프 내보내기를 성공적으로 생성할 수 있는지 확인하세요.
- [매니페스트 폴백](dependency_scanning_sbom/_index.md#manifest-fallback)을 사용하여 `pom.xml`에서 선언된 직접 종속성을 기본 범위로 사용합니다.

자세한 내용과 예제는 [Maven에 대한 활성화 지침](dependency_scanning_sbom/_index.md#maven)을 참조하세요.

### npm {#npm}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-dependency_scanning` CI/CD 작업을 사용하는 npm 프로젝트를 지원하며 `package-lock.json` 또는 `npm-shrinkwrap.json.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출할 수 있습니다. 지원되는 npm 버전 조합과 `package-lock.json` 또는 `npm-shrinkwrap.json.lock` 파일은 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)에 자세히 설명되어 있습니다. 이 분석기는 `Retire.JS` 스캐너를 사용하여 npm 프로젝트에서 벤더링된 JavaScript 파일을 스캔할 수 있습니다.

**New behavior**: 새 종속성 검사 분석기도 `package-lock.json` 또는 `npm-shrinkwrap.json.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출하고 `dependency-scanning` CI/CD 작업으로 CycloneDX SBOM 보고서 아티팩트를 생성합니다. 이 분석기는 벤더링된 JavaScript 파일을 스캔하지 않습니다. 자세한 내용은 컨텍스트 및 사용 가능한 조치는 [JavaScript 벤더링 라이브러리에 대한 종속성 검사 사용 중단 공지](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries)를 참조하세요. 교체 기능 지원은 [에픽 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186)에서 제안됩니다.

#### npm 프로젝트 마이그레이션 {#migrate-an-npm-project}

npm 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

npm 프로젝트를 종속성 검사 분석기로 마이그레이션하는 데 추가 단계는 필요하지 않습니다.

### NuGet {#nuget}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-dependency_scanning` CI/CD 작업을 사용하는 NuGet 프로젝트를 지원하며 `packages.lock.json` 파일을 구문 분석하여 프로젝트 종속성을 추출할 수 있습니다. 지원되는 NuGet 버전 조합과 `packages.lock.json` 파일은 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)에 자세히 설명되어 있습니다.

**New behavior**: 새 종속성 검사 분석기도 `packages.lock.json` 파일을 구문 분석하여 프로젝트 종속성을 추출하고 `dependency-scanning` CI/CD 작업으로 CycloneDX SBOM 보고서 아티팩트를 생성합니다.

#### NuGet 프로젝트 마이그레이션 {#migrate-a-nuget-project}

NuGet 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

NuGet 프로젝트를 종속성 검사 분석기로 마이그레이션하는 데 추가 단계는 필요하지 않습니다.

### pip {#pip}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-python-dependency_scanning` CI/CD 작업을 사용하는 pip 프로젝트를 지원하며 `requirements.txt` 파일에서 응용 프로그램을 빌드하여 프로젝트 종속성을 추출할 수 있습니다(`requirements.pip` 및 `requires.txt` 대체 파일 이름도 지원됨). `PIP_REQUIREMENTS_FILE` 환경 변수를 사용하여 사용자 정의 파일 이름을 지정할 수도 있습니다. Python 및 pip 지원 버전의 조합은 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)에 자세히 설명되어 있습니다.

**New behavior**: 새 종속성 검사 분석기는 종속성을 추출하기 위해 프로젝트를 빌드하지 않습니다. 대신 다계층 감지 모델을 사용합니다:

- [지원되는 잠금 파일 또는 그래프 내보내기](dependency_scanning_sbom/_index.md#supported-languages-and-files)가 리포지토리 또는 작업 아티팩트에 있으면(예: pip-compile으로 생성된 `requirements.txt`) 분석기가 이를 직접 사용합니다.
- 지원되는 잠금 파일 또는 그래프 내보내기가 감지되지 않았지만 지원되는 빌드 파일이 있으면(예: `requirements.in`) [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution) 작업이 `.pre` 스테이지에서 실행됩니다. 이는 `pip-compile`를 자동으로 실행하여 `dependency-scanning` 작업에 대한 잠금 파일을 생성합니다.
- 종속성 해결이 사용 불가하거나 실패하면 [매니페스트 폴백](dependency_scanning_sbom/_index.md#manifest-fallback)이 `requirements.txt` 파일을 직접 구문 분석하여 직접 종속성만 추출합니다.

#### pip 프로젝트 마이그레이션 {#migrate-a-pip-project}

pip 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

pip 프로젝트를 마이그레이션하려면 다음 옵션 중 하나를 선택합니다:

- 가장 정확한 결과를 원하면 프로젝트가 잠금 파일을 제공하는지 확인하세요. 프로젝트에서 [pip-compile 명령줄 도구](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/)를 구성하고 `requirements.txt` 잠금 파일을 리포지토리에 커밋하거나 선행 CI/CD 작업(예: `build`)에서 사용하여 `requirements.txt` 파일을 동적으로 생성하고 종속성 검사 작업을 실행하기 전에 [아티팩트](../../../ci/jobs/job_artifacts.md)로 내보냅니다. 또는 다른 [지원되는 잠금 파일 또는 그래프 내보내기](dependency_scanning_sbom/_index.md#supported-languages-and-files)를 선택할 수 있습니다. 잠금 파일 또는 그래프 내보내기를 동적으로 생성할 때 `DS_DISABLED_RESOLUTION_JOBS` CI/CD 변수 값에 `python`를 추가하여 자동 종속성 해결을 비활성화합니다.
- [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution)을 사용하여 `pipcompile.lock.txt` 파일을 자동으로 생성합니다. 해결 이미지가 잠금 파일을 성공적으로 생성할 수 있는지 확인하세요.
- [매니페스트 폴백](dependency_scanning_sbom/_index.md#manifest-fallback)을 사용하여 `requirements.txt`에서 선언된 직접 종속성을 기본 범위로 사용합니다.

자세한 내용과 예제는 [pip에 대한 활성화 지침](dependency_scanning_sbom/_index.md#pip)을 참조하세요.

### Pipenv {#pipenv}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-python-dependency_scanning` CI/CD 작업을 사용하는 Pipenv 프로젝트를 지원하며 `Pipfile` 파일에서 응용 프로그램을 빌드하여 프로젝트 종속성을 추출할 수 있습니다. 또는 존재하는 경우 `Pipfile.lock` 파일에서도 추출할 수 있습니다. Python 및 Pipenv 지원 버전의 조합은 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)에 자세히 설명되어 있습니다.

**New behavior**: 새 종속성 검사 분석기는 Pipenv 프로젝트를 빌드하여 종속성을 추출하지 않습니다. 대신 프로젝트는 최소한 `Pipfile.lock` 파일을 제공해야 하며 이상적으로는 [`pipenv graph` 명령](https://pipenv.pypa.io/en/latest/cli.html#graph)으로 생성된 `pipenv.graph.json` 파일을 제공해야 합니다. `pipenv.graph.json` 파일은 종속성 그래프를 생성하고 [종속성 경로](../dependency_list/_index.md#dependency-paths)와 같은 기능을 활성화해야 합니다. 이 파일들은 `dependency-scanning` CI/CD 작업으로 처리되어 CycloneDX SBOM 보고서 아티팩트를 생성합니다. 이 접근 방식은 GitLab이 특정 버전의 Python 및 Pipenv를 지원할 필요가 없습니다. [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution)은 `Pipfile` 없이 `Pipfile.lock` 파일을 사용하는 프로젝트에서 지원되지 않습니다.

#### Pipenv 프로젝트 마이그레이션 {#migrate-a-pipenv-project}

Pipenv 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

Pipenv 프로젝트를 마이그레이션하려면:

- 프로젝트가 `Pipfile.lock` 파일을 제공하는지 확인하세요. 프로젝트에서 [`pipenv lock` 명령](https://pipenv.pypa.io/en/latest/cli.html#graph)을 구성하고 `Pipfile.lock` 파일을 리포지토리에 커밋하거나 선행 CI/CD 작업(예: `build`)에서 사용하여 `Pipfile.lock` 파일을 동적으로 생성하고 종속성 검사 작업을 실행하기 전에 [아티팩트](../../../ci/jobs/job_artifacts.md)로 내보냅니다. 또는 다른 [지원되는 잠금 파일 또는 그래프 내보내기](dependency_scanning_sbom/_index.md#supported-languages-and-files)를 선택할 수 있습니다.

### Poetry {#poetry}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-python-dependency_scanning` CI/CD 작업을 사용하는 Poetry 프로젝트를 지원하며 `poetry.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출할 수 있습니다. 지원되는 Poetry 버전 조합과 `poetry.lock` 파일은 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)에 자세히 설명되어 있습니다.

**New behavior**: 새 종속성 검사 분석기도 `poetry.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출하고 `dependency-scanning` CI/CD 작업으로 CycloneDX SBOM 보고서 아티팩트를 생성합니다.

#### Poetry 프로젝트 마이그레이션 {#migrate-a-poetry-project}

Poetry 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

Poetry 프로젝트를 종속성 검사 분석기로 마이그레이션하는 데 추가 단계는 필요하지 않습니다.

### pnpm {#pnpm}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-dependency_scanning` CI/CD 작업을 사용하는 pnpm 프로젝트를 지원하며 `pnpm-lock.yaml` 파일을 구문 분석하여 프로젝트 종속성을 추출할 수 있습니다. 지원되는 pnpm 버전 조합과 `pnpm-lock.yaml` 파일은 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)에 자세히 설명되어 있습니다. 이 분석기는 `Retire.JS` 스캐너를 사용하여 npm 프로젝트에서 벤더링된 JavaScript 파일을 스캔할 수 있습니다.

**New behavior**: 새 종속성 검사 분석기도 `pnpm-lock.yaml` 파일을 구문 분석하여 프로젝트 종속성을 추출하고 `dependency-scanning` CI/CD 작업으로 CycloneDX SBOM 보고서 아티팩트를 생성합니다. 이 분석기는 벤더링된 JavaScript 파일을 스캔하지 않습니다. 자세한 내용은 컨텍스트 및 사용 가능한 조치는 [JavaScript 벤더링 라이브러리에 대한 종속성 검사 사용 중단 공지](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries)를 참조하세요. 교체 기능 지원은 [에픽 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186)에서 제안됩니다.

#### pnpm 프로젝트 마이그레이션 {#migrate-a-pnpm-project}

pnpm 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

pnpm 프로젝트를 종속성 검사 분석기로 마이그레이션하는 데 추가 단계는 필요하지 않습니다.

### sbt {#sbt}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-maven-dependency_scanning` CI/CD 작업을 사용하는 sbt 프로젝트를 지원하며 `build.sbt` 파일에서 응용 프로그램을 빌드하여 프로젝트 종속성을 추출할 수 있습니다. Java, Scala 및 sbt 지원 버전의 조합은 복잡하며 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)에 자세히 설명되어 있습니다.

**New behavior**: 새 종속성 검사 분석기는 종속성을 추출하기 위해 프로젝트를 빌드하지 않습니다. 대신 프로젝트는 [sbt-dependency-graph 플러그인](https://github.com/sbt/sbt-dependency-graph)([sbt >= 1.4.0에 포함됨](https://www.scala-sbt.org/1.x/docs/sbt-1.4-Release-Notes.html#sbt-dependency-graph+is+in-sourced))으로 생성된 `dependencies-compile.dot` 파일을 제공해야 합니다. 이 파일은 `dependency-scanning` CI/CD 작업으로 처리되어 CycloneDX SBOM 보고서 아티팩트를 생성합니다. 이 접근 방식은 GitLab이 Java, Scala 및 sbt의 특정 버전을 지원할 필요가 없습니다. [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution)은 sbt 프로젝트에서 지원되지 않습니다.

#### sbt 프로젝트 마이그레이션 {#migrate-an-sbt-project}

sbt 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

sbt 프로젝트를 마이그레이션하려면:

- 프로젝트가 `dependencies-compile.dot` 파일을 제공하는지 확인하세요. 선행 CI/CD 작업(예: `build`)에서 [sbt-dependency-graph 플러그인](https://github.com/sbt/sbt-dependency-graph)을 구성하여 `dependencies-compile.dot` 파일을 동적으로 생성하고 종속성 검사 작업을 실행하기 전에 [아티팩트](../../../ci/jobs/job_artifacts.md)로 내보냅니다.

자세한 내용과 예제는 [sbt에 대한 활성화 지침](dependency_scanning_sbom/_index.md#sbt)을 참조하세요.

### setuptools {#setuptools}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-python-dependency_scanning` CI/CD 작업을 사용하는 setuptools 프로젝트를 지원하며 `setup.py` 파일에서 응용 프로그램을 빌드하여 프로젝트 종속성을 추출할 수 있습니다. Python 및 setuptools 지원 버전의 조합은 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-running-a-package-manager-to-generate-a-parsable-file)에 자세히 설명되어 있습니다.

**New behavior**: 새 종속성 검사 분석기는 setuptools 프로젝트를 빌드하여 종속성을 추출하지 않습니다. 대신 다계층 감지 모델을 사용합니다:

- [지원되는 잠금 파일 또는 그래프 내보내기](dependency_scanning_sbom/_index.md#supported-languages-and-files)가 리포지토리 또는 작업 아티팩트에 있으면(예: pip-compile으로 생성된 `requirements.txt`) 분석기가 이를 직접 사용합니다.
- 지원되는 잠금 파일 또는 그래프 내보내기가 감지되지 않았지만 지원되는 빌드 파일이 있으면(예: `setup.py`) [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution) 작업이 `.pre` 스테이지에서 실행됩니다. 이는 `pip-compile`를 자동으로 실행하여 `dependency-scanning` 작업에 대한 잠금 파일을 생성합니다.

#### setuptools 프로젝트 마이그레이션 {#migrate-a-setuptools-project}

setuptools 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

setuptools 프로젝트를 마이그레이션하려면 다음 옵션 중 하나를 선택합니다:

- 가장 정확한 결과를 원하면 프로젝트가 `requirements.txt` 잠금 파일을 제공하는지 확인하세요. 프로젝트에서 [pip-compile 명령줄 도구](https://pip-tools.readthedocs.io/en/latest/cli/pip-compile/)를 구성하고:
  - 명령줄 도구를 개발 워크플로우에 영구적으로 통합합니다. 이는 `requirements.txt` 파일을 리포지토리에 커밋하고 프로젝트 종속성을 변경할 때 업데이트하는 것을 의미합니다.
  - `build` CI/CD 작업에서 명령줄 도구를 사용하여 `requirements.txt` 파일을 동적으로 생성하고 종속성 검사 작업을 실행하기 전에 [아티팩트](../../../ci/jobs/job_artifacts.md)로 내보냅니다.
- [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution)을 활성화하여 매니페스트 파일에서 `requirements.txt` 잠금 파일을 자동으로 생성합니다.

자세한 내용과 예제는 [pip에 대한 활성화 지침](dependency_scanning_sbom/_index.md#pip)을 참조하세요.

### Swift {#swift}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 CI/CD 템플릿 또는 검사 실행 정책을 사용할 때 Swift 프로젝트를 지원하지 않습니다. Swift 지원은 실험용 Swift CI/CD 구성 요소에서만 사용할 수 있습니다.

**New behavior**: 새 종속성 검사 분석기도 `Package.resolved` 파일을 구문 분석하여 프로젝트 종속성을 추출하고 `dependency-scanning` CI/CD 작업으로 CycloneDX SBOM 보고서 아티팩트를 생성합니다.

#### Swift 프로젝트 마이그레이션 {#migrate-a-swift-project}

Swift 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

Swift 프로젝트를 종속성 검사 분석기로 마이그레이션하는 데 추가 단계는 필요하지 않습니다.

### uv {#uv}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-dependency_scanning` CI/CD 작업을 사용하는 uv 프로젝트를 지원하며 `uv.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출할 수 있습니다. 지원되는 uv 버전 조합과 `uv.lock` 파일은 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)에 자세히 설명되어 있습니다.

**New behavior**: 새 종속성 검사 분석기도 `uv.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출하고 `dependency-scanning` CI/CD 작업으로 CycloneDX SBOM 보고서 아티팩트를 생성합니다.

#### uv 프로젝트 마이그레이션 {#migrate-a-uv-project}

uv 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

uv 프로젝트를 종속성 검사 분석기로 마이그레이션하는 데 추가 단계는 필요하지 않습니다.

### Yarn {#yarn}

**Previous behavior**: Gemnasium 분석기 기반 종속성 검사는 `gemnasium-dependency_scanning` CI/CD 작업을 사용하는 Yarn 프로젝트를 지원하며 `yarn.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출할 수 있습니다. 지원되는 Yarn 버전 조합과 `yarn.lock` 파일은 [종속성 검사(Gemnasium 기반) 설명서](legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles)에 자세히 설명되어 있습니다. 이 분석기는 Yarn 종속성에 대해 [머지 리퀘스트를 통한 취약성 해결](../vulnerabilities/_index.md#resolve-a-vulnerability)에 수정 데이터를 제공할 수 있습니다. 이 분석기는 `Retire.JS` 스캐너를 사용하여 Yarn 프로젝트에서 벤더링된 JavaScript 파일을 스캔할 수 있습니다.

**New behavior**: 새 종속성 검사 분석기도 `yarn.lock` 파일을 구문 분석하여 프로젝트 종속성을 추출하고 `dependency-scanning` CI/CD 작업으로 CycloneDX SBOM 보고서 아티팩트를 생성합니다. 이 분석기는 Yarn 종속성에 대한 수정 데이터를 제공하지 않습니다. 자세한 내용은 [Yarn 프로젝트의 종속성 검사에서 취약성 해결 사용 중단 공지](../../../update/deprecations.md#resolve-a-vulnerability-for-dependency-scanning-on-yarn-projects)를 참조하세요. 교체 기능 지원은 [에픽 759](https://gitlab.com/groups/gitlab-org/-/epics/759)에서 제안됩니다. 이 분석기는 벤더링된 JavaScript 파일을 스캔하지 않습니다. 자세한 내용은 컨텍스트 및 사용 가능한 조치는 [JavaScript 벤더링 라이브러리에 대한 종속성 검사 사용 중단 공지](../../../update/deprecations.md#dependency-scanning-for-javascript-vendored-libraries)를 참조하세요. 교체 기능 지원은 [에픽 7186](https://gitlab.com/groups/gitlab-org/-/epics/7186)에서 제안됩니다.

#### Yarn 프로젝트 마이그레이션 {#migrate-a-yarn-project}

Yarn 프로젝트를 마이그레이션하여 새 종속성 검사 분석기를 사용합니다.

전제 조건:

- 모든 프로젝트에 필요한 [일반 마이그레이션 단계](#migrate-to-dependency-scanning-using-sbom)를 완료합니다.
- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

Yarn 프로젝트를 종속성 검사 분석기로 마이그레이션하는 데 추가 단계는 필요하지 않습니다. 이전에 머지 리퀘스트를 통한 취약성 해결 기능이나 벤더링된 JavaScript 스캔에 의존했다면 **New behavior** 위의 사용 중단 공지를 참조하여 컨텍스트 및 사용 가능한 조치를 확인하세요.

## CI/CD 변수 변경 사항 {#changes-to-cicd-variables}

다음 표는 Gemnasium 분석기 기반의 레거시 종속성 검사 기능과 함께 사용되던 CI/CD 변수 및 새 종속성 검사 분석기의 상태를 나열합니다:

| 레거시 변수                  | 새 분석기의 상태                                                                                    |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `ADDITIONAL_CA_CERT_BUNDLE`      | 유지됨. `additional_ca_cert_bundle` 사양 입력을 선호합니다.                                                            |
| `AST_ENABLE_MR_PIPELINES`        | 유지됨.                                                                                                           |
| `DEPENDENCY_SCANNING_DISABLED`   | 유지됨.                                                                                                           |
| `DS_ANALYZER_IMAGE`              | 유지됨.                                                                                                           |
| `DS_EXCLUDED_ANALYZERS`          | 제거됨.                                                                                                        |
| `DS_EXCLUDED_PATHS`              | 유지됨. `excluded_paths` 사양 입력을 선호합니다.                                                                       |
| `DS_GRADLE_RESOLUTION_POLICY`    | 제거됨.                                                                                                        |
| `DS_IMAGE_SUFFIX`                | 제거됨.                                                                                                        |
| `DS_INCLUDE_DEV_DEPENDENCIES`    | 유지됨. `include_dev_dependencies` 사양 입력을 선호합니다.                                                             |
| `DS_JAVA_VERSION`                | 제거됨.                                                                                                        |
| `DS_MAX_DEPTH`                   | 유지됨. `max_scan_depth` 사양 입력을 선호합니다.                                                                       |
| `DS_PIP_DEPENDENCY_PATH`         | 유지됨. [Python 종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution)에만 적용됩니다. |
| `DS_PIP_VERSION`                 | 제거됨.                                                                                                        |
| `DS_REMEDIATE`                   | 제거됨.                                                                                                        |
| `DS_REMEDIATE_TIMEOUT`           | 제거됨.                                                                                                        |
| `GEMNASIUM_DB_LOCAL_PATH`        | 제거됨.                                                                                                        |
| `GEMNASIUM_DB_REF_NAME`          | 제거됨.                                                                                                        |
| `GEMNASIUM_DB_REMOTE_URL`        | 제거됨.                                                                                                        |
| `GEMNASIUM_DB_UPDATE_DISABLED`   | 제거됨.                                                                                                        |
| `GEMNASIUM_IGNORED_SCOPES`       | 제거됨.                                                                                                        |
| `GEMNASIUM_LIBRARY_SCAN_ENABLED` | 제거됨.                                                                                                        |
| `GOARCH`                         | 제거됨.                                                                                                        |
| `GOFLAGS`                        | 제거됨.                                                                                                        |
| `GOOS`                           | 제거됨.                                                                                                        |
| `GOPRIVATE`                      | 제거됨.                                                                                                        |
| `GRADLE_CLI_OPTS`                | 유지됨. [Gradle 종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution)에만 적용됩니다. |
| `GRADLE_PLUGIN_INIT_PATH`        | 제거됨.                                                                                                        |
| `MAVEN_CLI_OPTS`                 | `MAVEN_ARGS`로 대체되었습니다.                                                                                       |
| `PIP_EXTRA_INDEX_URL`            | 유지됨. [Python 종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution)에만 적용됩니다. |
| `PIP_INDEX_URL`                  | 유지됨. [Python 종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution)에만 적용됩니다. |
| `PIP_REQUIREMENTS_FILE`          | `DS_PIP_MANIFEST_FILE_NAME_PATTERN`로 대체되었습니다.                                                                |
| `PIPENV_PYPI_MIRROR`             | 제거됨.                                                                                                        |
| `SBT_CLI_OPTS`                   | 제거됨.                                                                                                        |
| `SEARCH_IGNORE_HIDDEN_DIRS`      | 유지됨.                                                                                                           |
| `SECURE_ANALYZERS_PREFIX`        | 유지됨. `analyzer_image_prefix` 스펙 입력을 선호합니다.                                                                |
| `SECURE_LOG_LEVEL`               | 유지됨. `analyzer_log_level` 스펙 입력을 선호합니다.                                                                   |

**제거됨**으로 표시된 변수는 새 분석기에서 무시됩니다. 다른 작업에서도 사용되지 않는 한 CI/CD 구성에서 제거하세요.

**`<new-name>`로 대체됨**으로 표시된 변수는 계속 작동하지만 더 이상 사용되지 않습니다. 다음 주요 GitLab 버전에서 제거될 예정입니다. CI/CD 구성을 업데이트하여 새 변수 이름을 사용하세요.

**Kept**으로 표시된 변수는 새 분석기에서 허용되며 [사용 가능한 CI/CD 변수 참조](dependency_scanning_sbom/_index.md#available-cicd-variables)에 설명된 대로 작동합니다. 일부 유지되는 변수는 이제 종속성 해결 작업에만 적용되며 표에 명시되어 있습니다.

기존 사용자 구성(예: 스캔 실행 정책)의 마이그레이션을 용이하게 하기 위해 `v2` 템플릿은 이러한 CI/CD 변수와 하위 호환됩니다. 설정되면 이 새 템플릿에 도입된 해당 `spec:inputs`보다 우선합니다.

`v2` CI/CD 템플릿을 `.gitlab-ci.yml`에서 직접 사용할 때 분석기를 구성하려면 CI/CD 변수보다 [스펙 입력](dependency_scanning_sbom/_index.md#available-spec-inputs)을 선호합니다. 스펙 입력은 파이프라인 생성 시 유효성이 검사되며 더 명확한 오류 메시지를 제공하고 템플릿 포함으로 범위가 지정됩니다. 스펙 입력을 아직 사용할 수 없는 스캔 실행 정책 또는 보안 구성 프로필을 통해 종속성 검사를 구성할 때 CI/CD 변수를 사용하세요.

### v2 템플릿에 도입된 새 CI/CD 변수 {#new-cicd-variables-introduced-with-the-v2-template}

`v2` 템플릿은 다음 변수를 추가합니다. 자세한 내용은 [사용 가능한 스펙 입력](dependency_scanning_sbom/_index.md#available-spec-inputs) 및 [사용 가능한 CI/CD 변수](dependency_scanning_sbom/_index.md#available-cicd-variables) 참조를 확인하세요.

| 변수                                   | 스펙 입력 동등값                   | 목적                                                                                                                                                  |
| ------------------------------------------ | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ANALYZER_ARTIFACT_DIR`                    | _(없음)_                                | CycloneDX SBOM 보고서가 저장되는 디렉토리입니다.                                                                                                        |
| `DS_API_SCAN_DOWNLOAD_DELAY`               | `api_scan_download_delay`               | 취약성 스캔 결과를 다운로드하기 전의 초기 지연입니다.                                                                                             |
| `DS_API_TIMEOUT`                           | `api_timeout`                           | 종속성 검사 SBOM 스캔 API의 제한 시간입니다.                                                                                                       |
| `DS_DISABLED_RESOLUTION_JOBS`              | `disabled_resolution_jobs`              | 비활성화할 [종속성 해결](dependency_scanning_sbom/_index.md#dependency-resolution) 작업의 쉼표로 구분된 목록(`maven`, `gradle`, `python`)입니다. |
| `DS_ENABLE_MANIFEST_FALLBACK`              | `enable_manifest_fallback`              | 잠금 파일 또는 종속성 그래프 내보내기를 사용할 수 없을 때 [매니페스트 폴백](dependency_scanning_sbom/_index.md#manifest-fallback)을 활성화합니다.               |
| `DS_ENABLE_VULNERABILITY_SCAN`             | `enable_vulnerability_scan`             | 생성된 SBOM의 취약성 스캔을 전환합니다.                                                                                                        |
| `DS_FF_LINK_COMPONENTS_TO_GIT_FILES`       | _(없음)_                                | (베타) 종속성 목록의 구성 요소를 동적으로 생성된 파일 대신 리포지토리에 커밋된 파일에 연결합니다.                               |
| `DS_GRADLE_RESOLUTION_IMAGE`               | `gradle_resolution_image`               | Gradle 종속성 해결 작업에서 사용하는 이미지입니다.                                                                                                      |
| `DS_MAVEN_RESOLUTION_IMAGE`                | `maven_resolution_image`                | Maven 종속성 해결 작업에서 사용하는 이미지입니다.                                                                                                       |
| `DS_MAVEN_DEPENDENCY_PLUGIN_VERSION`       | `maven_dependency_plugin_version`       | Maven 종속성 해결 중 사용하는 `maven-dependency-plugin`의 버전입니다.                                                                        |
| `DS_PIP_MANIFEST_FILE_NAME_PATTERN`        | `pip_manifest_file_name_pattern`        | pip 매니페스트 파일의 glob 패턴입니다.                                                                                                                     |
| `DS_PIPCOMPILE_LOCKFILE_FILE_NAME_PATTERN` | `pipcompile_lockfile_file_name_pattern` | `pip-compile` 잠금 파일의 glob 패턴입니다.                                                                                                                |
| `DS_PYTHON_RESOLUTION_IMAGE`               | `python_resolution_image`               | Python 종속성 해결 작업에서 사용하는 이미지입니다.                                                                                                      |
| `DS_STATIC_REACHABILITY_ENABLED`           | `enable_static_reachability`            | [정적 도달 가능성](static_reachability.md)을 활성화합니다.                                                                                                    |
