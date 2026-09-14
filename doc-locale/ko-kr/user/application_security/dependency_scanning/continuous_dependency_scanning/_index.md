---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 지속적인 종속성 검사
description: GitLab이 CI/CD 파이프라인 외부에서 애플리케이션 종속성에 대한 새로운 취약성을 감지하는 방법입니다.
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

종속성 검사를 위한 지속적인 취약성 스캐닝(CVS)은 새 파이프라인을 실행할 필요 없이 최신 [보안 권고사항](#security-advisories)의 정보와 비교하여 프로젝트의 종속성의 구성 요소 이름과 버전을 조회하여 보안 취약성을 찾습니다. 파이프라인은 CycloneDX SBOM을 통해 프로젝트 구성 요소를 등록하기 위해 기본 브랜치에서 최소한 한 번은 실행되어야 합니다. 그 후 CVS는 종속성이 변경될 때까지 추가 파이프라인 실행 없이 권고사항이 게시되면 실행됩니다.

[새로운 취약성이 발생할 수 있습니다](#checking-new-vulnerabilities). 지속적인 취약성 스캐닝이 [지원되는 패키지 유형](#supported-package-types)이 포함된 모든 프로젝트에서 스캔을 트리거할 때입니다.

종속성 검사를 위한 지속적인 취약성 스캐닝으로 만든 취약성은 스캐너 이름으로 `GitLab SBoM Vulnerability Scanner`을 사용하고 취약성 유형으로 `Dependency Scanning`을 사용합니다.

CI/CD 기반 보안 스캔과 달리 지속적인 취약성 스캐닝은 CI/CD 파이프라인 대신 백그라운드 작업(Sidekiq)을 통해 실행되며 보안 보고서 아티팩트가 생성되지 않습니다.

## 전제 조건 {#prerequisites}

- [CycloneDX SBOM 보고서](#how-to-generate-a-cyclonedx-sbom-report).
- GitLab 인스턴스에 동기화된 [보안 권고사항](#security-advisories).

## 지원되는 패키지 유형 {#supported-package-types}

지속적인 취약성 스캐닝은 종속성 검사를 위해 다음 [PURL 유형](https://github.com/package-url/purl-spec/blob/346589846130317464b677bc4eab30bf5040183a/PURL-TYPES.rst)을 포함하는 구성 요소를 지원합니다:

- `cargo`
- `conan`
- `go`
- `maven`
- `npm`
- `nuget`
- `packagist`
- `pub`
- `pypi`
- `rubygem`
- `swift`

Go 의사 버전은 지원되지 않습니다. Go 의사 버전을 참조하는 프로젝트 종속성은 거짓 부정으로 이어질 수 있으므로 영향을 받는 것으로 간주되지 않습니다.

## CycloneDX SBOM 보고서 생성 방법 {#how-to-generate-a-cyclonedx-sbom-report}

[CycloneDX SBOM 보고서](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)를 사용하여 프로젝트 구성 요소를 GitLab에 등록합니다.

CycloneDX 보고서는 다음을 준수해야 합니다:

- [CycloneDX 사양](https://github.com/CycloneDX/specification) 버전 `1.4`, `1.5` 또는 `1.6`.
- [종속성 검사를 위한 GitLab CycloneDX 속성 분류](../../../../development/sec/cyclonedx_property_taxonomy.md#gitlabdependency_scanning-namespace-taxonomy).

GitLab은 GitLab과 호환되는 보고서를 생성할 수 있는 보안 분석기를 제공합니다:

- [종속성 검사 분석기](../dependency_scanning_sbom/_index.md#turn-on-dependency-scanning)
- [Gemnasium 분석기(더 이상 사용되지 않음)](../legacy_dependency_scanning/_index.md)

## 지속적인 취약성 스캐닝 켜기 또는 끄기 {#turn-on-or-off-continuous-vulnerability-scanning}

{{< history >}}

- GitLab 19.0에서 `cvs_per_scanner_type_settings` [플래그](../../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/500716)되었습니다. 기본적으로 비활성화되었습니다.
- GitLab 19.2에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243130)하게 되었습니다. `cvs_per_scanner_type_settings` 기능 플래그가 제거되었습니다.

{{< /history >}}

지속적인 취약성 스캐닝은 기본적으로 모든 수집된 CycloneDX SBOM 파일에서 실행됩니다. 각 프로젝트에 대해 끌 수 있습니다. 끈 상태일 때 새로운 보안 권고사항이 수집되면 종속성에 대해 취약성 레코드가 생성되지 않습니다.

전제 조건:

- 프로젝트에 대해 관리자, 소유자 또는 보안 관리자 역할이 있어야 합니다.

지속적인 취약성 스캐닝을 켜거나 끄려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **의존성 스캔을 위한 지속적인 취약점 스캐닝** 아래에서 토글을 켜거나 끕니다.

## 새로운 취약성 확인 {#checking-new-vulnerabilities}

지속적인 취약성 스캐닝으로 감지된 새로운 취약성은 [취약성 보고서](../../vulnerability_report/_index.md)에 표시됩니다. 그러나 영향을 받는 SBOM 구성 요소가 감지된 파이프라인에는 나열되지 않습니다.

취약성은 [보안 권고사항](#security-advisories)이 추가되거나 업데이트된 후에 생성되며, 코드베이스가 변경되지 않으면 해당 취약성이 프로젝트에 추가되는 데 몇 시간이 걸릴 수 있습니다. 지난 14일 이내에 게시된 권고사항만 지속적인 취약성 스캐닝에 고려됩니다.

## 더 이상 취약성이 감지되지 않을 때 {#when-vulnerabilities-are-no-longer-detected}

지속적인 취약성 스캐닝은 새 권고사항이 게시될 때 자동으로 취약성을 생성하지만 취약성이 프로젝트에 더 이상 없을 때를 알 수 없습니다. 이를 위해 GitLab은 여전히 기본 브랜치의 파이프라인에서 [종속성 검사](../_index.md) 스캔을 실행하고 최신 정보를 포함하는 해당 보안 보고서 아티팩트를 생성해야 합니다. 이러한 보고서가 처리되고 일부 취약성을 더 이상 포함하지 않으면 지속적인 취약성 스캐닝으로 생성된 경우에도 이러한 보고서는 그렇게 표시됩니다.

## 보안 권고사항 {#security-advisories}

지속적인 취약성 스캐닝은 GitLab이 관리하는 서비스인 패키지 메타데이터 데이터베이스를 사용하며, 라이선스 및 보안 권고사항 데이터를 집계하고 GitLab.com 및 GitLab Self-Managed 인스턴스에서 사용하는 업데이트를 정기적으로 게시합니다.

GitLab.com에서 동기화는 GitLab에서 관리하며 모든 프로젝트에서 사용할 수 있습니다.

GitLab Self-Managed에서는 GitLab 인스턴스의 **운영자** 영역에서 [동기화할 패키지 레지스트리 메타데이터를 선택](../../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)할 수 있습니다.

### 데이터 원본 {#data-sources}

보안 권고사항의 현재 데이터 원본은 다음을 포함합니다:

- [GitLab 권고사항 데이터베이스](https://advisories.gitlab.com/) ([`gemnasium-db`](https://gitlab.com/gitlab-org/security-products/gemnasium-db) 리포지토리에 호스팅, 레거시 이름)

### 취약성 데이터베이스에 기여 {#contributing-to-the-vulnerability-database}

취약성을 찾으려면 [`GitLab advisory database`](https://advisories.gitlab.com/)를 검색할 수 있습니다. [새로운 취약성을 제출](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md)할 수도 있습니다.
