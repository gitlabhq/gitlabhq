---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 지속적인 컨테이너 스캔
description: GitLab이 CI/CD 파이프라인 외부에서 이미지 종속성의 새로운 취약성을 감지하는 방법입니다.
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 지속적인 컨테이너 스캔이 GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/435435)되었으며 [기능 플래그](../../../../administration/feature_flags/_index.md) 명명된 `container_scanning_continuous_vulnerability_scans`입니다. 기본적으로 비활성화되었습니다.
- 지속적인 컨테이너 스캔이 GitLab 16.10에서 [GitLab Self-Managed 및 GitLab Dedicated에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/437162)되었습니다.
- GitLab 17.0에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/443712)합니다. `container_scanning_continuous_vulnerability_scans` 기능 플래그가 제거되었습니다.

{{< /history >}}

컨테이너 스캔을 위한 지속적인 취약성 스캔(CVS)은 새로운 파이프라인을 실행할 필요 없이 최신 [보안 권고](#security-advisories) 정보와 비교하여 프로젝트의 이미지 종속성에서 보안 취약성을 찾습니다. CVS는 기본 브랜치에 저장된 CycloneDX SBOM 보고서를 통해 프로젝트에서 사용하는 구성 요소를 파악합니다. 이 SBOM을 생성하려면 컨테이너 스캔 작업이 기본 브랜치에서 최소 한 번 실행되어야 합니다. 그 이후로 CVS는 추가 파이프라인 실행이 필요 없이 해당 구성 요소에 대해 새로 발행된 권고를 자동으로 감지합니다. 이미지 내용이 변경되면 CVS가 업데이트된 구성 요소 집합을 평가할 수 있도록 기본 브랜치에서 새로운 파이프라인을 실행하여 SBOM을 새로 고쳐야 합니다. 대부분의 프로젝트에서는 일반적인 워크플로우의 일부로 이가 발생합니다. 종속성 변경은 일반적으로 이미 파이프라인을 트리거하는 코드 변경을 포함하기 때문입니다.

[새로운 취약성이 발생할 수 있습니다](#checking-new-vulnerabilities). 지속적인 취약성 스캔이 [지원되는 패키지 유형](#supported-package-types)이 포함된 모든 프로젝트에서 스캔을 트리거할 때입니다.

지속적인 취약성 스캔으로 인해 생성된 취약성은 스캐너 이름으로 `GitLab SBoM Vulnerability Scanner`을 사용하고 취약성 유형으로 `Container Scanning`을 사용합니다.

CI/CD 기반 보안 스캔과 달리 지속적인 취약성 스캔은 CI/CD 파이프라인보다는 백그라운드 작업(Sidekiq)을 통해 실행되며 보안 보고서 아티팩트는 생성되지 않습니다.

## 전제 조건 {#prerequisites}

- [CycloneDX SBOM 보고서](#how-to-generate-a-cyclonedx-sbom-report)입니다.
- GitLab 인스턴스로 동기화된 [보안 권고](#security-advisories)입니다.

## 지원되는 패키지 유형 {#supported-package-types}

지속적인 취약성 스캔은 다음 [PURL 유형](https://github.com/package-url/purl-spec/blob/346589846130317464b677bc4eab30bf5040183a/PURL-TYPES.rst)의 구성 요소를 지원합니다:

- `apk`
- `deb`
- `rpm`

알려진 제한 사항:

- 선행 0이 포함된 APK 버전은 지원되지 않습니다. 이러한 버전 지원 작업은 [이슈 471509](https://gitlab.com/gitlab-org/gitlab/-/issues/471509)에서 추적됩니다.
- `^`을 포함하는 RPM 버전은 지원되지 않습니다. 이러한 버전 지원 작업은 [이슈 459969](https://gitlab.com/gitlab-org/gitlab/-/issues/459969)에서 추적됩니다.
- Red Hat 배포판의 RPM 패키지는 지원되지 않습니다. 이 사용 사례 지원 작업은 [에픽 12980](https://gitlab.com/groups/gitlab-org/-/epics/12980)에서 추적됩니다.

## CycloneDX SBOM 보고서를 생성하는 방법 {#how-to-generate-a-cyclonedx-sbom-report}

[CycloneDX SBOM 보고서](../../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)를 사용하여 프로젝트 구성 요소를 GitLab에 등록합니다.

CycloneDX 보고서는 다음을 준수해야 합니다:

- [CycloneDX 사양](https://github.com/CycloneDX/specification) 버전 `1.4`, `1.5` 또는 `1.6`입니다.
- [컨테이너 스캔용 GitLab CycloneDX 속성 분류법](../../../../development/sec/cyclonedx_property_taxonomy.md#gitlabcontainer_scanning-namespace-taxonomy)입니다.

GitLab은 GitLab과 호환되는 보고서를 생성할 수 있는 보안 분석 도구를 제공합니다:

- [컨테이너 검사](../_index.md#getting-started)
- [레지스트리용 컨테이너 스캔](../_index.md#container-scanning-for-registry)

## 지속적인 취약성 스캔을 켜거나 끄기 {#turn-on-or-off-continuous-vulnerability-scanning}

{{< history >}}

- GitLab 19.0에서 `cvs_per_scanner_type_settings` [플래그](../../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/500716)되었습니다. 기본적으로 비활성화되었습니다.
- GitLab 19.2에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243130)하게 되었습니다. `cvs_per_scanner_type_settings` 기능 플래그가 제거되었습니다.

{{< /history >}}

지속적인 취약성 스캔은 기본적으로 수집된 모든 CycloneDX SBOM 파일에서 실행됩니다. 각 프로젝트에 대해 이를 끌 수 있습니다. 꺼져 있는 동안 새로운 보안 권고가 수집될 때 이미지 종속성에 대한 취약성 기록이 생성되지 않습니다.

전제 조건:

- 프로젝트에 대해 유지 관리자, 소유자 또는 보안 관리자 역할이 있어야 합니다.

지속적인 취약성 스캔을 켜거나 끄려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. **컨테이너 스캔을 위한 지속적인 취약성 검사** 아래에서 토글을 켜거나 끕니다.

## 새로운 취약성 확인 {#checking-new-vulnerabilities}

지속적인 취약성 검사로 감지된 새로운 취약성은 [취약성 보고서](../../vulnerability_report/_index.md)에서 볼 수 있습니다. 하지만 영향을 받는 SBOM 구성 요소가 감지된 파이프라인에는 나열되지 않습니다.

[보안 권고](#security-advisories)가 추가되거나 업데이트된 후 취약성이 생성되며, 코드베이스가 변경되지 않은 상태에서 해당 취약성이 프로젝트에 추가되는 데 몇 시간이 걸릴 수 있습니다. 지난 14일 이내에 게시된 권고만 지속적인 취약성 스캔 대상으로 간주됩니다.

## 취약성이 더 이상 감지되지 않을 때 {#when-vulnerabilities-are-no-longer-detected}

지속적인 취약성 스캔은 새로운 권고가 게시되면 자동으로 취약성을 생성하지만 프로젝트에서 취약성이 더 이상 존재하지 않을 때를 알 수 없습니다. 이를 위해 GitLab은 여전히 기본 브랜치에 대한 파이프라인에서 실행되는 [컨테이너 스캔](../_index.md) 스캔과 최신 정보로 생성된 해당 보안 보고서 아티팩트가 있어야 합니다. 이러한 보고서가 처리되고 더 이상 일부 취약성이 포함되지 않으면 지속적인 취약성 스캔으로 생성되었더라도 이러한 것이 플래그 표시됩니다.

> [!warning]
> 레지스트리용 컨테이너 스캔을 통해 감지된 취약성은 이 방법으로 해결할 수 없으며 이미지에서 수정한 후에도 계속 표시됩니다. 이는 레지스트리용 컨테이너 스캔이 보안 보고서(필요한 취약성을 해결된 것으로 표시)가 아닌 SBOM만 생성하기 때문입니다.

## 보안 권고 {#security-advisories}

지속적인 취약성 스캔은 GitLab에서 관리하고 라이선스 및 보안 권고 데이터를 집계하며 GitLab.com 및 GitLab Self-Managed 인스턴스에서 사용하는 업데이트를 정기적으로 게시하는 서비스인 패키지 메타데이터 데이터베이스를 사용합니다.

GitLab.com에서는 동기화가 GitLab에서 관리되며 모든 프로젝트에서 사용할 수 있습니다.

GitLab Self-Managed에서는 GitLab 인스턴스에 대한 **운영자** 영역에서 [패키지 레지스트리 메타데이터 동기화를 선택](../../../../administration/settings/security_and_compliance.md#choose-package-registry-metadata-to-sync)할 수 있습니다.

### 데이터 소스 {#data-sources}

보안 권고의 현재 데이터 소스는 다음을 포함합니다:

- [Trivy DB](https://github.com/aquasecurity/trivy-db)는 Aqua security의 [`vuln-list repository`](https://github.com/aquasecurity/vuln-list)에서 빌드됩니다.

### 취약성 데이터베이스에 기여 {#contributing-to-the-vulnerability-database}

취약성을 찾으려면 원본 데이터가 포함된 Aqua security의 [`vuln-list repository`](https://github.com/aquasecurity/vuln-list)를 검색할 수 있습니다. Trivy-DB에 [기여](https://github.com/aquasecurity/vuln-list-update/blob/main/CONTRIBUTING.md)할 수도 있습니다.
