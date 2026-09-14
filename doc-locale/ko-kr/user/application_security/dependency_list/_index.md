---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 의존성 목록
description: "취약성, 라이선스, 필터링 및 내보내기입니다."
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

종속성 검사를 사용하여 프로젝트 또는 그룹의 의존성과 알려진 취약성을 포함한 해당 의존성에 대한 주요 세부 정보를 검토합니다. 이 목록은 기존 및 새로운 결과를 포함하여 프로젝트의 의존성 모음입니다. 이 정보는 때때로 SBOM(Software Bill of Materials) 또는 BOM으로 불립니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 개요는 [프로젝트 의존성 - 고급 보안 테스트](https://www.youtube.com/watch?v=ckqkn9Tnbw4)를 참조하세요.

## 의존성 목록 설정 {#set-up-the-dependency-list}

프로젝트의 의존성을 나열하려면 프로젝트의 기본 브랜치에서 [종속성 검사](../dependency_scanning/_index.md) 또는 [컨테이너 검사](../container_scanning/_index.md)를 실행합니다.

의존성 목록은 최신 기본 브랜치 파이프라인에서 업로드된 [CycloneDX 보고서](../../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)의 의존성도 표시합니다. CycloneDX 보고서는 [CycloneDX 사양](https://github.com/CycloneDX/specification) 버전 `1.4`, `1.5` 또는 `1.6`을(를) 준수해야 합니다. [CycloneDX 웹 도구](https://cyclonedx.github.io/cyclonedx-web-tool/validate)를 사용하여 CycloneDX 보고서를 검증할 수 있습니다.

> [!note]
> 의존성 목록을 채우기 위해 필수는 아니지만 SBOM 문서는 GitLab CycloneDX 속성 분류를 포함하고 준수하여 일부 속성을 제공하고 일부 보안 기능을 활성화해야 합니다.

## 프로젝트 의존성 보기 {#view-project-dependencies}

{{< history >}}

- GitLab 17.2에서 `location` 필드는 기능 플래그 `skip_sbom_occurrences_update_on_pipeline_id_change`이(가) 활성화된 경우 의존성을 마지막으로 감지한 커밋에 더 이상 링크하지 않습니다. 플래그는 기본적으로 비활성화됩니다.
- GitLab 17.3에서 `location` 필드는 항상 의존성을 처음 감지한 커밋에 링크합니다. `skip_sbom_occurrences_update_on_pipeline_id_change` 기능 플래그가 제거되었습니다.
- 의존성 경로 보기 옵션이 GitLab 17.11 [기능 플래그](../../../administration/feature_flags/_index.md)와 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/519965)되었으며 `dependency_paths`입니다. 기본적으로 비활성화되었습니다.
- GitLab 18.2에서 의존성 경로 보기 옵션이 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/197224)합니다. `dependency_paths` 기능 플래그가 제거되었습니다.

{{< /history >}}

전제 조건:

- 프로젝트 또는 그룹에 대한 Developer, Maintainer 또는 Owner 역할입니다.

프로젝트의 의존성 또는 그룹의 모든 프로젝트의 의존성을 보려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **안전함** > **의존성 목록**을 선택합니다.
1. 선택 사항. 이행 의존성이 있는 경우 모든 의존성 경로도 볼 수 있습니다:
   - 프로젝트의 경우 **위치** 열에서 **의존성 경로 보기**를 선택합니다.
   - 그룹의 경우 **위치** 열에서 위치를 선택한 다음 **의존성 경로 보기**를 선택합니다.

각 의존성의 세부 정보는 취약성의 심각도(있는 경우)를 낮추는 순서로 나열됩니다. 대신 심각도 이름, 패키저 또는 라이선스로 목록을 정렬할 수 있습니다.

| 필드                       | 설명 |
|-----------------------------|-------------|
| 구성 요소                   | 의존성의 이름과 버전입니다. |
| 패키저                    | 의존성을 설치하는 데 사용되는 패키지 관리자입니다. 지원되지 않는 패키지 관리자의 경우 "unknown"으로 표시됩니다. |
| 위치                    | 시스템 의존성의 경우 이 필드는 스캔한 이미지를 나열합니다. 애플리케이션 의존성의 경우 이 필드는 의존성을 선언한 프로젝트의 패키저별 잠금 파일에 대한 링크를 표시합니다. 또한 직접 [종속](#dependency-paths)이 있으면 이를 표시합니다. 이행 의존성이 있는 경우 **의존성 경로 보기**를 선택하면 모든 종속의 전체 경로가 표시됩니다. 이행 의존성은 직접 종속을 조상으로 가지는 간접 종속입니다. |
| 라이선스(프로젝트만 해당) | 의존성의 소프트웨어 라이선스에 링크합니다. 의존성에서 감지된 취약성 수를 포함하는 경고 배지입니다. |
| 프로젝트(그룹만 해당)  | 의존성이 있는 프로젝트에 링크합니다. 여러 프로젝트가 동일한 의존성을 가진 경우 이러한 프로젝트의 총 개수가 표시됩니다. 이 의존성이 있는 프로젝트로 이동하려면 **프로젝트** 수를 선택한 다음 검색하여 해당 이름을 선택합니다. |

## 의존성 목록 필터링 {#filter-dependency-list}

{{< history >}}

- [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/513320)된 GitLab 17.9의 프로젝트에 대한 의존성 필터링은 [`project_component_filter`](../../../administration/feature_flags/_index.md) 이름의 플래그입니다. 기본적으로 활성화되었습니다.
- GitLab 17.10에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/513321)합니다. `project_component_filter` 기능 플래그가 제거되었습니다.
- 의존성 버전 필터링이 GitLab 18.0에서 [프로젝트](https://gitlab.com/gitlab-org/gitlab/-/issues/520771)와 [그룹](https://gitlab.com/gitlab-org/gitlab/-/issues/523061)을 위해 [기능 플래그](../../../administration/feature_flags/_index.md) `version_filtering_on_project_level_dependency_list` 및 `version_filtering_on_group_level_dependency_list`로 도입되었습니다. 기본적으로 비활성화되었습니다.
- 의존성 버전 필터링이 GitLab 18.1에서 GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192291)되었습니다.
- `version_filtering_on_project_level_dependency_list` 및 `version_filtering_on_group_level_dependency_list` 기능 플래그가 제거되었습니다.

{{< /history >}}

의존성 목록을 필터링하여 의존성의 부분 집합만 집중할 수 있습니다. 의존성 목록은 그룹 및 프로젝트에서 사용할 수 있습니다.

그룹의 경우 다음을 기준으로 필터링할 수 있습니다:

- 프로젝트
- 라이선스
- 구성 요소
- 구성 요소 버전

프로젝트의 경우 다음을 기준으로 필터링할 수 있습니다:

- 구성 요소
- 구성 요소 버전

구성 요소 버전으로 필터링하려면 먼저 정확히 하나의 구성 요소로 필터링해야 합니다.

전제 조건:

- 프로젝트 또는 그룹에 대한 Developer, Maintainer 또는 Owner 역할입니다.

의존성 목록을 필터링하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **안전함** > **의존성 목록**을 선택합니다.
1. 필터 표시줄을 선택합니다.
1. 필터를 선택한 다음 드롭다운 목록에서 하나 이상의 기준을 선택합니다. 드롭다운 목록을 닫으려면 외부를 선택합니다. 필터를 더 추가하려면 이 단계를 반복합니다.
1. 선택한 필터를 적용하려면 <kbd>Enter</kbd> 키를 누릅니다.

의존성 목록은 필터와 일치하는 의존성만 표시합니다.

## 취약성 {#vulnerabilities}

{{< history >}}

- GitLab 17.9에서 `update_sbom_occurrences_vulnerabilities_on_cvs` [기능 플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/500551)되었습니다. 기본적으로 비활성화되었습니다.
- GitLab 17.9에서 [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/514223)되었습니다.
- 의존성 목록이 GitLab 18.5에 도입된 `detected` 및 `confirmed` 상태만 표시하도록 하기 위한 변경입니다.

{{< /history >}}

> [!flag]
> [SBOM 기반 종속성 검사](../dependency_scanning/dependency_scanning_sbom/_index.md)와 연결된 취약성에 대한 지원의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 이력을 참조하세요.

의존성에 알려진 취약성이 있는 경우 의존성 이름 옆의 화살표를 선택하거나 알려진 취약성이 몇 개 있는지 표시하는 배지를 선택하여 이를 봅니다. 각 취약성에 대해 그 심각도와 설명이 아래에 나타납니다. 취약성에 대한 자세한 내용을 보려면 취약성의 설명을 선택합니다. [취약점의 세부 정보](../vulnerabilities/_index.md) 페이지가 열립니다. 의존성 목록은 `detected` 및 `confirmed` 상태의 취약성만 표시합니다. 취약성의 상태가 변경되면 기본 브랜치에서 SBoM을 포함하는 새 파이프라인이 실행될 때까지 의존성 목록에 변경 사항이 반영되지 않습니다.

## 의존성 경로 {#dependency-paths}

{{< history >}}

- CycloneDX SBOM의 의존성 경로 정보가 GitLab 16.9에서 [기능 플래그](../../../administration/feature_flags/_index.md)로 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/393061)되었습니다`project_level_sbom_occurrences`. 기본적으로 비활성화되었습니다.
- CycloneDX SBOM의 의존성 경로 정보가 GitLab 17.0에서 GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 [활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/434371)되었습니다.
- CycloneDX SBOM의 의존성 경로 정보가 GitLab 17.4에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/457633)합니다. `project_level_sbom_occurrences` 기능 플래그가 제거되었습니다.

{{< /history >}}

의존성 경로는 구성 요소가 일시적이고 지원되는 패키지 관리자에 속하는 경우 나열된 구성 요소의 직접 종속을 표시합니다. 의존성 경로는 취약성이 있는 의존성에 대해서만 표시됩니다.

의존성 경로는 다음 패키지 관리자에서 지원됩니다:

- [Conan](https://conan.io)
- [NuGet](https://www.nuget.org/)
- [sbt](https://www.scala-sbt.org)
- [Yarn 1.x](https://classic.yarnpkg.com/lang/en/)

의존성 경로는 [`dependency-scanning`](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main) 구성 요소를 사용할 때만 다음 패키지 관리자에서 지원됩니다:

- [Gradle](https://gradle.org/)
- [Maven](https://maven.apache.org/)
- [NPM](https://www.npmjs.com/)
- [Pipenv](https://pipenv.pypa.io/en/latest/)
- [pip-tools](https://pip-tools.readthedocs.io/en/latest/)
- [pnpm](https://pnpm.io/)
- [Poetry](https://python-poetry.org/)

### 라이선스 {#licenses}

[종속성 검사](../dependency_scanning/_index.md) CI/CD 작업이 구성된 경우 [발견된 라이선스](../../compliance/license_scanning_of_cyclonedx_files/_index.md)가 이 페이지에 표시됩니다.

## 내보내기 {#export}

의존성 목록을 다음과 같이 내보낼 수 있습니다:

- JSON
- CSV
- CycloneDX 형식(프로젝트만 해당)

전제 조건:

- 프로젝트 또는 그룹에 대한 Developer, Maintainer 또는 Owner 역할입니다.

의존성 목록을 내보내려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **안전함** > **의존성 목록**을 선택합니다.
1. **내보내기**를 선택한 다음 파일 형식을 선택합니다.

의존성 목록은 이메일 주소로 전송됩니다. 의존성 목록을 다운로드하려면 이메일의 링크를 선택합니다.

## 문제 해결 {#troubleshooting}

의존성 목록을 작업할 때 다음 문제가 발생할 수 있습니다.

### 라이선스가 'unknown'으로 표시됨 {#license-appears-as-unknown}

특정 의존성의 라이선스는 몇 가지 가능한 이유로 `unknown`로 표시될 수 있습니다. 이 섹션에서는 특정 의존성의 라이선스가 알려진 이유로 `unknown`로 표시되는지 여부를 확인하는 방법을 설명합니다.

#### 라이선스가 'unknown' upstream {#license-is-unknown-upstream}

의존성에 지정된 라이선스를 upstream에서 확인합니다:

- C/C++ 패키지의 경우 [Conancenter](https://conan.io/center)를 확인합니다.
- npm 패키지의 경우 [npmjs.com](https://www.npmjs.com/)을 확인합니다.
- Python 패키지의 경우 [PyPI](https://pypi.org/)를 확인합니다.
- NuGet 패키지의 경우 [NuGet](https://www.nuget.org/packages)을 확인합니다.
- Go 패키지의 경우 [pkg.go.dev](https://pkg.go.dev/)를 확인합니다.

라이선스가 upstream에서 `unknown`로 표시되면 GitLab이 해당 의존성의 **라이선스**도 `unknown`로 표시할 것으로 예상됩니다.

#### 라이선스에 SPDX 라이선스 표현식 포함 {#license-includes-spdx-license-expression}

[SPDX 라이선스 표현식](https://spdx.github.io/spdx-spec/v2.3/SPDX-license-expressions/)은 지원되지 않습니다. SPDX 라이선스 표현식이 있는 의존성은 `unknown`인 **라이선스**로 표시됩니다. SPDX 라이선스 표현식의 예는 `(MIT OR CC0-1.0)`입니다. [이슈 336878](https://gitlab.com/gitlab-org/gitlab/-/issues/336878)에서 자세히 알아보기를 참조하세요.

#### 패키지 메타데이터 DB에 없는 패키지 버전 {#package-version-not-in-package-metadata-db}

의존성 패키지의 특정 버전은 [패키지 메타데이터 데이터베이스](../../../topics/offline/quick_start_guide.md#enabling-the-package-metadata-database)에 있어야 합니다. 그렇지 않으면 해당 의존성의 **라이선스**가 `unknown`로 표시됩니다. Go 모듈에 대한 [이슈 440218](https://gitlab.com/gitlab-org/gitlab/-/issues/440218)에서 자세히 알아보기를 참조하세요.

#### 패키지 이름에 특수 문자 포함 {#package-name-contains-special-characters}

의존성 패키지의 이름에 하이픈(`-`)이 포함되어 있으면 **라이선스**가 `unknown`로 표시될 수 있습니다. 이는 패키지를 수동으로 `requirements.txt`에 추가하거나 `pip-compile`를 사용할 때 발생할 수 있습니다. 이는 GitLab이 의존성에 대한 정보를 수집할 때 [PEP 503의 정규화된 이름](https://peps.python.org/pep-0503/#normalized-names)에 대한 지침에 따라 Python 패키지 이름을 정규화하지 않기 때문입니다. [이슈 440391](https://gitlab.com/gitlab-org/gitlab/-/issues/440391)에서 자세히 알아보기를 참조하세요.
