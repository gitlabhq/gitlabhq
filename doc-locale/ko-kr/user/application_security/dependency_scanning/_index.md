---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 종속성 검사
description: "취약성, 수정, 구성, 분석기 및 보고서."
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

종속성 검사는 런타임, 개발 및 전이(중첩) 패키지를 포함한 프로젝트의 종속성에서 알려진 보안 취약성을 식별합니다. GitLab은 각각 다른 워크플로우에 적합한 여러 종속성 검사 방법을 제공합니다. 아래 요약을 사용하여 프로젝트에 맞는 방법을 선택하세요.

## 사용 가능한 스캔 방법 {#available-scanning-methods}

### SBOM을 사용한 종속성 검사 {#dependency-scanning-using-sbom}

{{< history >}}

- GitLab 19.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249853)된 악성코드 권고사항 비교 [기능 플래그](../../../administration/feature_flags/_index.md)(`sbom_scan_malware_findings`)를 사용합니다. 기본적으로 사용으로 설정됩니다.

{{< /history >}}

> [!flag]
> 악성코드 권고사항 비교의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

파이프라인에서 종속성 검사 분석기로 생성한 CycloneDX SBOM 아티팩트를 [GitLab 권고사항 데이터베이스](../gitlab_advisory_database/_index.md) 및 [GitLab 악성코드 권고사항](../gitlab_advisory_database/_index.md#gitlab-malware-advisories)과 비교합니다. 이는 새로운 프로젝트에 권장되는 방법이며 GitLab에서 종속성 검사의 장기적 방향입니다.

자세한 내용은 [SBOM을 사용한 종속성 검사](dependency_scanning_sbom/_index.md)를 참조하세요.

### 지속적 종속성 검사 {#continuous-dependency-scanning}

{{< history >}}

- GitLab 19.4에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/21156)된 악성코드 권고사항 비교 [기능 플래그](../../../administration/feature_flags/_index.md)(`cvs_malware_advisories`)를 사용합니다. 기본적으로 사용으로 설정됩니다.

{{< /history >}}

> [!flag]
> 악성코드 권고사항 비교의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요.

[GitLab 권고사항 데이터베이스](../gitlab_advisory_database/_index.md) 또는 [GitLab 악성코드 권고사항](../gitlab_advisory_database/_index.md#gitlab-malware-advisories)이 업데이트될 때마다 기본 브랜치의 최신 성공한 파이프라인에서 SBOM 구성요소를 지속적으로 다시 검사하므로, 파이프라인을 다시 실행하지 않아도 새로 공개된 취약점이 표시됩니다.

자세한 내용은 [지속적 종속성 검사](continuous_dependency_scanning/_index.md)를 참조하세요.

### Gemnasium을 사용한 종속성 검사 {#dependency-scanning-with-gemnasium}

CI/CD 작업에서 종속성을 감지하고 GitLab 권고 데이터베이스와 일치시키는 원본 파이프라인 기반 분석기입니다.

> [!warning]
> Gemnasium 분석기를 기반으로 하는 종속성 검사는 GitLab 17.9에서 더 이상 사용되지 않으며 GitLab 20.0에서 제거될 예정입니다. 마이그레이션 지침은 [마이그레이션 가이드](migration_guide_to_sbom_based_scans.md)를 참조하세요. 자세한 내용은 [에픽 15961](https://gitlab.com/groups/gitlab-org/-/epics/20456)을 참조하세요.

자세한 내용은 [레거시 종속성 검사 페이지](legacy_dependency_scanning/_index.md)를 참조하세요.

### 종속성의 동작 분석(Libbehave) {#analyze-dependencies-for-behaviors-libbehave}

알려진 CVE를 넘어서는 의심스럽거나 악의적인 활동을 표시하기 위해 종속성의 런타임 동작을 분석하는 실험 기능입니다.

자세한 내용은 [종속성의 동작 분석](experiment_libbehave_dependency.md)을 참조하세요.

## 스캔 방법 비교 {#comparison-of-scanning-methods}

| 메서드                             | 상태               | 트리거            | 최적 사용                                                   |
| ---------------------------------- | -------------------- | ------------------ | ---------------------------------------------------------- |
| SBOM을 사용한 종속성 검사      | 일반 가용성 | 파이프라인           | 새로운 프로젝트, SBOM 우선 워크플로우                         |
| 지속적 종속성 검사     | 일반 가용성 | 권고 데이터베이스 업데이트 | 파이프라인을 다시 실행하지 않고 새로 공개된 CVE 포착 |
| Gemnasium을 사용한 종속성 검사 | 더 이상 사용되지 않음(17.9)    | 파이프라인           | 마이그레이션 대기 중인 기존 프로젝트                        |
| 종속성의 동작 분석 | 실험적 기능           | 파이프라인           | 악의적인 패키지 동작 감지                       |

## AI 네이티브 기능 {#ai-native-features}

### 에이전트 기반 주요 변경 사항 해결 {#agentic-breaking-change-resolution}

가 종속성을 업그레이드하고 이 실패한 경우, GitLab Duo는 실패를 분석하고 해결할 수정 사항을 제공할 수 있습니다.

자세한 내용은 [에이전트 기반 주요 변경 사항 해결(종속성 업그레이드용)](agentic-breaking-change-resolution.md)을 참조하세요.

## 취약성 데이터베이스에 기여 {#contributing-to-the-vulnerability-database}

취약성을 찾으려면 [`GitLab advisory database`](https://advisories.gitlab.com/)를 검색할 수 있습니다. 새로운 취약성을 [제출](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md)할 수도 있습니다.
