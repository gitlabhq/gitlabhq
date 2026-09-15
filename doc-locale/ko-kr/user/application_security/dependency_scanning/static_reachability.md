---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 정적 연결성 분석
---

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/14177) (GitLab 17.5에서 [실험](../../../policy/development_stages_support.md)으로)
- [변경됨](https://gitlab.com/groups/gitlab-org/-/epics/15781) (실험에서 베타로, GitLab 17.11)
- [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/502334) (GitLab 18.2 및 종속성 검사 분석기 v0.32.0에서 JavaScript 및 TypeScript 지원)
- [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/17607) (GitLab 18.5 및 종속성 검사 분석기 v0.39.0에서 Java 지원)
- [변경됨](https://gitlab.com/groups/gitlab-org/-/epics/15780) (베타에서 제한적 출시(LA)로, GitLab 18.5)
- [변경됨](https://gitlab.com/groups/gitlab-org/-/epics/19692) (Java 지원이 실험에서 베타로, GitLab 18.8)
- GitLab 19.0에서 [일반적으로 사용 가능](https://gitlab.com/groups/gitlab-org/-/work_items/20456)합니다.

{{< /history >}}

종속성 검사는 프로젝트의 모든 취약한 종속성을 식별합니다. 하지만 모든 취약성이 동등한 위험을 초래하는 것은 아닙니다. 정적 연결성 분석은 취약한 패키지가 연결 가능한지(즉, 애플리케이션에서 가져오는지)를 결정하여 수정 우선 순위를 지정하는 데 도움이 됩니다. 연결 가능한 취약성에 초점을 맞춤으로써, 정적 연결성 분석을 통해 이론적 위험이 아닌 실제 위협 노출을 기반으로 수정 우선 순위를 지정할 수 있습니다.

정적 연결성 분석은 프로젝트의 소스 코드를 분석하여 SBOM에서 어떤 종속성이 연결 가능한지를 결정합니다. 종속성 검사는 모든 구성 요소와 이들의 전이적 종속성을 식별하는 SBOM 보고서를 생성합니다. 정적 연결성 분석은 SBOM의 각 종속성을 확인하고 연결성 값을 추가하여 실제 사용 데이터로 보고서를 풍부하게 합니다. 이 강화된 SBOM은 GitLab에서 수집되어 취약성 결과를 보충합니다.

SBOM은 SBOM 파일과 소스 코드 파일이 모두 동일한 프로젝트 디렉토리 트리에 속할 때만 강화됩니다. 여러 중첩된 프로젝트가 있는 경우 시스템은 가장 가까운(가장 깊은) 프로젝트 경로를 선택하여 강화를 결정합니다. 정적 연결성 분석은 [메타데이터](https://gitlab.com/gitlab-org/security-products/static-reachability-metadata/-/tree/v1?ref_type=heads)에 의존하며, 이는 SBOM의 패키지 이름을 Python 및 Java 패키지에 대한 해당 코드 가져오기 경로로 매핑합니다. 이 메타데이터는 주간 업데이트를 통해 유지됩니다.

[이슈 535498](https://gitlab.com/gitlab-org/gitlab/-/issues/535498)에서 피드백을 공유하세요.

## 정적 연결성 분석 활성화 {#turn-on-static-reachability-analysis}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할이 있어야 합니다.
- 프로젝트가 [지원되는 언어 및 패키지 관리자](#supported-languages-and-package-managers)를 사용합니다.
- [종속성 검사 분석기](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning) 버전 0.39.0 이상(이전 버전은 특정 언어를 지원할 수 있음 - 위의 `History` 참조)
- [SBOM을 사용한 종속성 검사](dependency_scanning_sbom/_index.md#turn-on-dependency-scanning)가 프로젝트에 대해 활성화되어 있습니다. [Gemnasium](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium) 분석기는 지원되지 않습니다.
- 언어별 필수 조건:
  - Python:
    - 종속성 그래프 파일은 `build` 스테이지에서 작업 아티팩트로 제공되어야 합니다. [pip](dependency_scanning_sbom/_index.md#pip) 또는 [pipenv](dependency_scanning_sbom/_index.md#pipenv)의 지침을 참조하세요. 다른 지원되는 Python 패키지 관리자의 경우, [종속성 검사 분석기 문서](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)를 참조하세요.
  - JavaScript 및 TypeScript:
    - 리포지토리는 종속성 검사 분석기에서 [지원](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning#supported-files)하는 잠금 파일을 포함해야 합니다.
  - Java:
    - 종속성 그래프 파일은 `build` 스테이지에서 작업 아티팩트로 제공되어야 합니다. [Maven](dependency_scanning_sbom/_index.md#maven) 또는 [Gradle](dependency_scanning_sbom/_index.md#gradle)의 지침을 참조하세요.

> [!warning]
> 정적 연결성 분석은 작업 기간을 증가시킵니다.

프로젝트에서 정적 연결성 분석을 활성화하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **Code** > **Repository**를 선택합니다.
1. `.gitlab-ci.yml` 파일을 선택합니다.
1. **Edit** > **Edit single file**를 선택합니다.
1. 다음 구성을 추가합니다:

   ```yaml
   include:
   - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

   variables:
     DS_STATIC_REACHABILITY_ENABLED: true
   ```

1. **변경 사항 커밋**을 선택합니다.

종속성 검사가 실행되고 SBOM을 출력하면, 결과는 정적 연결성 분석으로 보충됩니다.

## 연결성 값 {#reachability-values}

종속성은 다음 중 하나의 연결성 값을 가질 수 있습니다. **예**로 표시된 종속성의 분류 및 수정을 우선 순위로 지정하세요. 이는 코드에서 확인된 사용입니다.

예 : 이 취약성과 연결된 패키지는 코드에서 연결 가능함이 확인되었습니다. 직접 종속성이 연결 가능한 것으로 표시되면, 이 종속성의 전이적 종속성도 연결 가능한 것으로 표시됩니다.

찾을 수 없음 : 정적 연결성 분석이 성공적으로 실행되었지만 취약한 패키지의 사용을 감지하지 못했습니다.

사용할 수 없음 : 정적 연결성 분석이 실행되지 않았으므로 연결성 데이터가 없습니다.

취약한 종속성의 연결성 값을 찾으려면:

- 취약성 보고서에서 **심각도** 값 위에 마우스를 올립니다.
- 취약성의 세부 정보 페이지에서 **Reachable** 값을 확인합니다.
- GraphQL 쿼리를 사용하여 연결 가능한 취약성을 나열합니다.

### "찾을 수 없음" 결과 {#not-found-results}

**Not Found** 연결성 값은 정적 연결성 분석이 항상 패키지 사용을 확실히 결정할 수 없기 때문에 종속성이 사용되지 않음을 보장하지 않습니다.

종속성은 다음과 같은 경우에 찾을 수 없음으로 표시됩니다:

- 잠금 파일에는 나타나지만 코드에서는 가져오지 않습니다.
- 제외된 디렉토리에 있습니다(예: `DS_EXCLUDED_PATHS`로 구성).
- 커버리지 테스트 또는 린팅 패키지 같은 로컬 사용만을 위해 포함된 도구입니다.

제외된 디렉토리의 다음 예를 고려합니다. CI/CD 변수 `DS_EXCLUDED_PATHS="test"`을(를) 정의했습니다. 프로젝트의 리포지토리 구조는 다음과 같습니다.

```plaintext
.
├── pipdeptree.json  // contains "requests" dependency
└── test/
    └── app.py       // imports "requests" dependency
```

이 예에서, 그래프 파일 `pipdeptree.json`은(는) 제외된 디렉토리 외부에 있으며, 파일에 나열된 종속성을 식별하기 위해 분석됩니다. 그러나 `requests` 종속성을 가져오는 소스 코드는 제외된 디렉토리에 있으므로, 정적 연결성 분석은 해당 연결성을 확인하지 않습니다. 결과적으로 `requests` 종속성은 **찾을 수 없음**으로 표시됩니다. 즉, 이는 잠금 파일이 제외된 디렉토리 외부에 있지만 종속성을 가져오는 코드가 내부에 있을 때 발생합니다.

## 지원되는 언어 및 패키지 관리자 {#supported-languages-and-package-managers}

지원은 언어 성숙도에 따라 달라지며 각 언어에 대해 특정 패키지 관리자 및 파일 형식을 포함합니다.

| 언어                          | 성숙도 | 지원되는 패키지 관리자                  | 지원되는 파일 형식 |
|-----------------------------------|----------|---------------------------------------------|----------------------|
| Python<sup>1</sup>                | 베타     | `pip`, `pipenv`<sup>2</sup>, `poetry`, `uv` | `.py`                |
| JavaScript/TypeScript<sup>3</sup> | 베타     | `npm`, `pnpm`, `yarn`                       | `.js`, `.ts`         |
| Java<sup>4</sup>                  | 베타     | `maven`<sup>5</sup>, `gradle`<sup>6</sup>   | `.java`              |

**각주**:

1. 종속성 검사를 `pipdeptree`과(와) 함께 사용할 때, [선택적 종속성](https://setuptools.pypa.io/en/latest/userguide/dependency_management.html#optional-dependencies)은 전이적 종속성이 아닌 직접 종속성으로 표시됩니다. 정적 연결성 분석은 이러한 패키지를 사용 중인 것으로 식별하지 못할 수 있습니다. 예를 들어, `passlib[bcrypt]`을(를) 요구하면 `passlib`이(가) `in_use`로 표시되고 `bcrypt`은(는) `not_found`로 표시될 수 있습니다. 자세한 내용은 [pip](dependency_scanning_sbom/_index.md#pip)를 참조하세요.
1. Python `pipenv`의 경우, 정적 연결성 분석은 `Pipfile.lock` 파일을 지원하지 않습니다. 지원은 `pipenv.graph.json`에 대해서만 사용 가능합니다. 이는 종속성 그래프를 지원하기 때문입니다.
1. 프론트엔드 프레임워크는 지원되지 않습니다.
1. Java의 동적 특성은 최신 프레임워크를 사용하는 프로젝트에서 더 높은 거짓 부정률을 초래할 수 있는 다음 문제를 야기합니다:
   - 정적 연결성 분석은 직접 가져오기, Java 리플렉션 패턴, 소스 코드의 Java 데이터베이스 연결 문자열을 통한 명시적 사용을 감지합니다. Spring Boot와 같은 종속성 주입 프레임워크를 사용하는 것처럼 런타임에 동적으로 로드되는 종속성을 식별할 수 없습니다.
   - 적용 범위는 GitLab 권고 데이터베이스의 패키지와 Maven Central에서 가장 널리 의존되는 패키지로 제한됩니다.
1. `maven.graph.json` 파일을 [Maven](dependency_scanning_sbom/_index.md#maven) 지침에 설명된 대로 사용합니다.
1. [Gradle](dependency_scanning_sbom/_index.md#gradle) 지침에 설명된 대로 종속성 잠금 파일을 사용합니다.

## 오프라인 환경 {#offline-environment}

[오프라인 환경](../offline_deployments/_index.md)에서 정적 연결성 분석을 실행하려면 초기 설정을 수행하고 지속적인 유지 보수를 수행해야 합니다.

초기 설정:

- [종속성 검사(SBOM)](dependency_scanning_sbom/_index.md#offline-environment)에 대한 오프라인 환경 요구 사항을 완료합니다.

지속적 유지 보수:

- 새 버전이 릴리스될 때마다 로컬 종속성 검사(SBOM) 이미지를 업데이트합니다.

Python 및 Java 패키지의 경우, 정적 연결성 분석은 메타데이터를 사용하여 SBOM의 패키지 이름을 해당 코드 가져오기 경로로 매핑합니다. 이 메타데이터는 종속성 검사 분석기의 이미지에 포함됩니다. 오래된 메타데이터로 인해 불완전하거나 부정확한 연결성 분석이 발생할 수 있습니다.
