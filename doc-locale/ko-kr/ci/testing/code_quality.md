---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 코드 품질 스캔 도구와 린터를 CI/CD 파이프라인에 통합하기 위한 문서
title: 코드 품질
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

코드 품질은 유지 보수성 이슈가 기술 부채가 되기 전에 식별합니다. 코드 검토 중에 발생하는 자동화된 피드백은 팀이 더 나은 코드를 작성하는 데 도움이 될 수 있습니다. 발견 사항은 머지 리퀘스트에 직접 나타나므로 수정하기 가장 비용 효율적인 시점에 문제가 보입니다.

코드 품질은 여러 프로그래밍 언어와 함께 작동하며 일반적인 린터, 스타일 검사기 및 복잡도 분석기와 통합됩니다. 기존 도구를 코드 품질 워크플로우에 연결할 수 있으므로 팀의 선호도를 유지하면서 결과 표시 방식을 표준화할 수 있습니다.

## 티어별 기능 {#features-per-tier}

다양한 [GitLab 티어](https://about.gitlab.com/pricing/)에서 다양한 기능을 사용할 수 있으며, 다음 표에서 확인할 수 있습니다:

| 기능                                                                                     | Free에서     | Premium에서  | Ultimate |
|:--------------------------------------------------------------------------------------------|:------------|:------------|:------------|
| [CI/CD 작업에서 코드 품질 결과 가져오기](#import-code-quality-results-from-a-cicd-job) | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [CodeClimate 기반 스캔 사용](#use-the-built-in-code-quality-cicd-template-deprecated)   | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [머지 리퀘스트 리포트에서 발견 사항 보기](#merge-request-reports)                             | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| [파이프라인 리포트에서 발견 사항 보기](#pipeline-details-view)                                 | {{< no >}}  | {{< yes >}} | {{< yes >}} |
| [머지 리퀘스트 변경사항 보기에서 발견 사항 보기](#merge-request-changes-view)               | {{< no >}}  | {{< no >}}  | {{< yes >}} |
| [프로젝트 품질 요약 보기에서 전체 상태 분석](#project-quality-view)           | {{< no >}}  | {{< no >}}  | {{< yes >}} |

## 품질 위반에 대한 코드 스캔 {#scan-code-for-quality-violations}

코드 품질은 많은 스캔 도구의 결과 가져오기를 지원하는 개방형 시스템입니다. 위반을 찾아 표시하려면 다음을 할 수 있습니다:

- 스캔 도구를 직접 사용하고 [결과를 가져옵니다](#import-code-quality-results-from-a-cicd-job). _(권장됨.)_
- [기본 제공 CI/CD 템플릿을 사용](#use-the-built-in-code-quality-cicd-template-deprecated)하여 스캔을 활성화합니다. 템플릿은 일반적인 오픈 소스 도구를 래핑하는 CodeClimate 엔진을 사용합니다. _(사용 중단됨.)_

단일 파이프라인에서 여러 도구의 결과를 캡처할 수 있습니다. 예를 들어 코드 린터를 실행하여 코드를 스캔하고 언어 린터를 실행하여 문서를 스캔하거나, 독립 실행형 도구를 CodeClimate 기반 스캔과 함께 사용할 수 있습니다. 코드 품질은 모든 리포트를 결합하므로 [결과를 볼 때](#view-code-quality-results) 모두 볼 수 있습니다.

### CI/CD 작업에서 코드 품질 결과 가져오기 {#import-code-quality-results-from-a-cicd-job}

많은 개발팀이 이미 CI/CD 파이프라인에서 린터, 스타일 검사기 또는 기타 도구를 사용하여 코딩 표준 위반을 자동으로 감지합니다. 코드 품질과 통합하여 이러한 도구의 발견 사항을 더 쉽게 보고 수정할 수 있습니다.

도구가 이미 문서화된 통합이 있는지 확인하려면 [코드 품질과 일반적인 도구 통합](#integrate-common-tools-with-code-quality)을 참조하세요.

다른 도구를 코드 품질과 통합하려면:

1. 도구를 CI/CD 파이프라인에 추가합니다.
1. 도구를 구성하여 리포트를 파일로 출력합니다.
   - 이 파일은 [특정 JSON 형식](#code-quality-report-format)을 사용해야 합니다.
   - 많은 도구가 이 출력 형식을 기본적으로 지원합니다. "CodeClimate 리포트", "GitLab 코드 품질 리포트" 또는 다른 유사한 이름으로 부를 수 있습니다.
   - 다른 도구는 때때로 사용자 지정 JSON 형식이나 템플릿을 사용하여 JSON 출력을 만들 수 있습니다. [리포트 형식](#code-quality-report-format)에는 몇 가지 필수 필드만 있으므로 이 출력 유형을 사용하여 코드 품질 리포트를 만들 수 있을 수도 있습니다.
1. [`codequality` 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportscodequality)를 선언하여 이 파일과 일치시킵니다.

이제 파이프라인이 실행된 후 품질 도구의 결과는 [처리되고 표시됩니다](#view-code-quality-results).

### 기본 제공 코드 품질 CI/CD 템플릿 사용(사용 중단됨) {#use-the-built-in-code-quality-cicd-template-deprecated}

> [!warning]
> 이 기능은 GitLab 17.3에서 [사용 중단됨](../../update/deprecations.md#codeclimate-based-code-quality-scanning-will-be-removed)되었으며 19.0에서 제거할 예정입니다. [지원되는 도구의 결과를 직접 통합](#import-code-quality-results-from-a-cicd-job)하세요.

코드 품질에는 기본 제공 CI/CD 템플릿 `Code-Quality.gitlab-ci.yaml`도 포함되어 있습니다. 이 템플릿은 오픈 소스 CodeClimate 스캔 엔진을 기반으로 한 스캔을 실행합니다.

CodeClimate 엔진이 실행됩니다:

- [지원되는 언어 집합](https://docs.codeclimate.com/docs/supported-languages-for-maintainability)에 대한 기본 유지 보수성 검사를 수행합니다.
- 오픈 소스 스캐너를 래핑하는 구성 가능한 [플러그인](https://docs.codeclimate.com/docs/list-of-engines) 세트로 소스 코드를 분석합니다.

자세한 내용은 [CodeClimate 기반 코드 품질 스캔 구성](code_quality_codeclimate_scanning.md)을 참조하세요.

#### CodeClimate 기반 스캔에서 마이그레이션 {#migrate-from-codeclimate-based-scanning}

CodeClimate 엔진은 구성 가능한 [분석 플러그인](code_quality_codeclimate_scanning.md#configure-codeclimate-analysis-plugins) 세트를 사용합니다. 일부는 기본적으로 활성화되어 있고, 다른 일부는 명시적으로 활성화해야 합니다. 기본 제공 플러그인을 대체하는 데 사용할 수 있는 통합은 다음과 같습니다:

| 플러그인       | 기본적으로 켜짐                    | 대체 항목 |
|--------------|----------------------------------|-------------|
| 중복  | {{< yes >}}                      | [PMD Copy/Paste Detector 통합](#pmd-copypaste-detector)합니다. |
| ESLint       | {{< yes >}}                      | [ESLint 통합](#eslint)합니다. |
| gofmt        | {{< no >}}                       | [golangci-lint 통합](#golangci-lint)하고 [gofmt 린터](https://golangci-lint.run/usage/linters#gofmt)를 활성화합니다. |
| golint       | {{< no >}}                       | [golangci-lint 통합](#golangci-lint)하고 golint를 대체하는 포함된 린터 중 하나를 활성화합니다. golint는 [사용 중단되고 고정됨](https://github.com/golang/go/issues/38968)입니다. |
| govet        | {{< no >}}                       | [golangci-lint 통합](#golangci-lint)합니다. golangci-lint는 [기본적으로 govet을 포함](https://golangci-lint.run/usage/linters#enabled-by-default)합니다. |
| markdownlint | {{< no >}}(커뮤니티 지원) | [markdownlint-cli2 통합](#markdownlint-cli2)합니다. |
| pep8         | {{< no >}}                       | [Flake8](#flake8), [Pylint](#pylint) 또는 [Ruff](#ruff)와 같은 대체 Python 린터를 통합합니다. |
| RuboCop      | {{< yes >}}                      | [RuboCop 통합](#rubocop)합니다. |
| SonarPython  | {{< no >}}                       | [Flake8](#flake8), [Pylint](#pylint) 또는 [Ruff](#ruff)와 같은 대체 Python 린터를 통합합니다. |
| Stylelint    | {{< no >}}(커뮤니티 지원) | [Stylelint 통합](#stylelint)합니다. |
| SwiftLint    | {{< no >}}                       | [SwiftLint 통합](#swiftlint)합니다. |

## 코드 품질 결과 보기 {#view-code-quality-results}

코드 품질 결과는 다음에 표시됩니다:

- [머지 리퀘스트 보고서](#merge-request-reports)
- [머지 리퀘스트 변경사항 보기](#merge-request-changes-view)
- [파이프라인 세부 정보 보기](#pipeline-details-view)
- [프로젝트 품질 보기](#project-quality-view)

### 머지 리퀘스트 리포트 {#merge-request-reports}

코드 품질 분석 결과는 머지 리퀘스트 **리포트** 탭에 표시됩니다. 동일한 지문을 가진 여러 코드 품질 발견 사항은 단일 항목으로 표시됩니다.

자세한 내용은 [머지 리퀘스트 리포트](../../user/project/merge_requests/reports.md)를 참조하세요.

### 머지 리퀘스트 변경사항 보기 {#merge-request-changes-view}

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

코드 품질 결과는 머지 리퀘스트 **변경사항** 보기에 표시됩니다. 코드 품질 이슈가 있는 행은 여백 옆에 기호로 표시됩니다. 기호를 선택하여 이슈 목록을 확인한 후 이슈를 선택하여 세부 정보를 확인합니다.

![코드 품질 이슈를 나타내기 위해 기호로 표시된 머지 리퀘스트의 변경사항 탭의 행](img/code_quality_changes_view_v18_2.png)

### 파이프라인 세부 정보 보기 {#pipeline-details-view}

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

파이프라인으로 생성된 코드 품질 위반의 전체 목록은 파이프라인의 세부 정보 페이지의 **코드 품질** 탭에 표시됩니다. 파이프라인 세부 정보 보기는 실행된 브랜치에서 발견된 모든 코드 품질 발견 사항을 표시합니다.

![심각도 감소 순서로 정렬된 브랜치의 모든 이슈 목록](img/code_quality_pipeline_details_view_v18_2.png)

### 프로젝트 품질 보기 {#project-quality-view}

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 14.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/72724)되었으며 [플래그](../../administration/feature_flags/_index.md) 이름은 `project_quality_summary_page`입니다. 이 기능은 [베타](../../policy/development_stages_support.md) 단계입니다. 기본적으로 비활성화되어 있습니다.

{{< /history >}}

프로젝트 품질 보기는 코드 품질 발견 사항의 개요를 표시합니다. 보기는 **분석** > **CI/CD 분석**에서 찾을 수 있으며, 이 특정 프로젝트에 대해 [`project_quality_summary_page`](../../administration/feature_flags/_index.md) 기능 플래그를 활성화해야 합니다.

![전체 이슈 수(위반이라고 함) 다음에 각 심각도의 이슈 수](img/code_quality_summary_v15_9.png)

## 코드 품질 리포트 형식 {#code-quality-report-format}

다음 형식으로 리포트를 출력할 수 있는 모든 도구에서 [코드 품질 결과를 가져올](#import-code-quality-results-from-a-cicd-job) 수 있습니다. 이 형식은 더 적은 수의 필드를 포함하는 [CodeClimate 리포트 형식](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types)의 버전입니다.

[코드 품질 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportscodequality)로 제공하는 파일에는 단일 JSON 배열이 포함되어야 합니다. 해당 배열의 각 개체에는 최소한 다음 속성이 있어야 합니다:

| 이름                                                      | 형식    | 설명 |
|-----------------------------------------------------------|---------|-------------|
| `description`                                             | 문자열  | 코드 품질 위반에 대한 인간이 읽을 수 있는 설명입니다. |
| `check_name`                                              | 문자열  | 이 위반과 연관된 검사 또는 규칙을 나타내는 고유한 이름입니다. |
| `fingerprint`                                             | 문자열  | 이 특정 코드 품질 위반을 식별하는 고유한 지문(예: 내용의 해시)입니다. |
| `location.path`                                           | 문자열  | 코드 품질 위반을 포함하는 파일이며, 리포지토리의 상대 경로로 표현됩니다. `./`로 접두사를 붙이지 마세요. |
| `location.lines.begin` 또는 `location.positions.begin.line` | 정수 | 코드 품질 위반이 발생한 줄입니다. |
| `severity`                                                | 문자열  | 위반의 심각도는 `info`, `minor`, `major`, `critical` 또는 `blocker` 중 하나일 수 있습니다. |

형식은 다음과 같은 방식으로 [CodeClimate 리포트 형식](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types)과 다릅니다:

- [CodeClimate 리포트 형식](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md#data-types)에서 더 많은 속성을 지원하지만, 코드 품질은 이전에 나열한 필드만 처리합니다.
- GitLab 파서는 파일의 시작 부분에 [바이트 순서 표시](https://en.wikipedia.org/wiki/Byte_order_mark)를 허용하지 않습니다.

예를 들어 다음은 규정을 준수하는 리포트입니다:

```json
[
  {
    "description": "'unused' is assigned a value but never used.",
    "check_name": "no-unused-vars",
    "fingerprint": "7815696ecbf1c96e6894b779456d330e",
    "severity": "minor",
    "location": {
      "path": "lib/index.js",
      "lines": {
        "begin": 42
      }
    }
  }
]
```

## 코드 품질과 일반적인 도구 통합 {#integrate-common-tools-with-code-quality}

많은 도구가 기본적으로 필요한 [리포트 형식](#code-quality-report-format)을 지원하여 코드 품질과 결과를 통합합니다. "CodeClimate 리포트", "GitLab 코드 품질 리포트" 또는 다른 유사한 이름으로 부를 수 있습니다.

다른 도구는 사용자 지정 템플릿이나 형식 사양을 제공하여 JSON 출력을 만들도록 구성할 수 있습니다. [리포트 형식](#code-quality-report-format)에는 몇 가지 필수 필드만 있으므로 이 출력 유형을 사용하여 코드 품질 리포트를 만들 수 있을 수도 있습니다.

CI/CD 파이프라인에서 이미 도구를 사용하고 있다면 코드 품질 리포트를 추가하도록 기존 작업을 조정해야 합니다. 기존 작업을 조정하면 개발자를 혼동시킬 수 있는 별도의 작업을 실행하는 것을 방지하고 파이프라인을 더 빨리 실행할 수 있습니다.

도구를 아직 사용하고 있지 않다면 CI/CD 작업을 처음부터 작성하거나 [CI/CD 카탈로그](../components/_index.md#cicd-catalog)의 구성 요소를 사용하여 도구를 채택할 수 있습니다.

### 코드 스캔 도구 {#code-scanning-tools}

#### ESLint {#eslint}

CI/CD 파이프라인에서 이미 [ESLint](https://eslint.org/) 작업이 있다면 코드 품질에 출력을 보내는 리포트를 추가해야 합니다. 출력을 통합하려면:

1. [`eslint-formatter-gitlab`](https://www.npmjs.com/package/eslint-formatter-gitlab)를 프로젝트의 개발 종속성으로 추가합니다.
1. ESLint를 실행하는 데 사용하는 명령에 `--format gitlab` 옵션을 추가합니다.
1. 리포트 파일의 위치를 가리키는 [`codequality` 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportscodequality)를 선언합니다.
   - 기본적으로 포매터는 CI/CD 구성을 읽고 리포트를 저장해야 하는 파일 이름을 추론합니다. 포매터가 아티팩트 선언에서 사용한 파일 이름을 추론할 수 없다면 CI/CD 변수 `ESLINT_CODE_QUALITY_REPORT`를 아티팩트에 지정한 파일 이름(예: `gl-code-quality-report.json`)으로 설정합니다.

[ESLint CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)를 사용하거나 조정하여 스캔을 실행하고 코드 품질과 출력을 통합할 수도 있습니다.

#### Stylelint {#stylelint}

CI/CD 파이프라인에서 이미 [Stylelint](https://stylelint.io/) 작업이 있다면 코드 품질에 출력을 보내는 리포트를 추가해야 합니다. 출력을 통합하려면:

1. [`@studiometa/stylelint-formatter-gitlab`](https://www.npmjs.com/package/@studiometa/stylelint-formatter-gitlab)를 프로젝트의 개발 종속성으로 추가합니다.
1. Stylelint를 실행하는 데 사용하는 명령에 `--custom-formatter=@studiometa/stylelint-formatter-gitlab` 옵션을 추가합니다.
1. 리포트 파일의 위치를 가리키는 [`codequality` 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportscodequality)를 선언합니다.
   - 기본적으로 포매터는 CI/CD 구성을 읽고 리포트를 저장해야 하는 파일 이름을 추론합니다. 포매터가 아티팩트 선언에서 사용한 파일 이름을 추론할 수 없다면 CI/CD 변수 `STYLELINT_CODE_QUALITY_REPORT`를 아티팩트에 지정한 파일 이름(예: `gl-code-quality-report.json`)으로 설정합니다.

자세한 내용과 CI/CD 작업 정의 예제는 [`@studiometa/stylelint-formatter-gitlab`의 문서](https://www.npmjs.com/package/@studiometa/stylelint-formatter-gitlab#usage)를 참조하세요.

#### MyPy {#mypy}

CI/CD 파이프라인에서 이미 [MyPy](https://mypy-lang.org/) 작업이 있다면 코드 품질에 출력을 보내는 리포트를 추가해야 합니다. 출력을 통합하려면:

1. [`mypy-gitlab-code-quality`](https://pypi.org/project/mypy-gitlab-code-quality/)를 프로젝트의 종속성으로 설치합니다.
1. `mypy` 명령을 변경하여 출력을 파일로 보냅니다.
1. `mypy-gitlab-code-quality`를 사용하여 파일을 필요한 형식으로 다시 처리하도록 작업 `script`에 단계를 추가합니다. 예를 들어:

   ```yaml
   - mypy $(find -type f -name "*.py" ! -path "**/.venv/**") --no-error-summary > mypy-out.txt || true  # "|| true" is used for preventing job failure when mypy find errors
   - mypy-gitlab-code-quality < mypy-out.txt > gl-code-quality-report.json
   ```

1. 리포트 파일의 위치를 가리키는 [`codequality` 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportscodequality)를 선언합니다.

[MyPy CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)를 사용하거나 조정하여 스캔을 실행하고 코드 품질과 출력을 통합할 수도 있습니다.

#### Flake8 {#flake8}

CI/CD 파이프라인에서 이미 [Flake8](https://flake8.pycqa.org/) 작업이 있다면 코드 품질에 출력을 보내는 리포트를 추가해야 합니다. 출력을 통합하려면:

1. [`flake8-gl-codeclimate`](https://github.com/awelzel/flake8-gl-codeclimate)를 프로젝트의 종속성으로 설치합니다.
1. Flake8을 실행하는 데 사용하는 명령에 `--format gl-codeclimate --output-file gl-code-quality-report.json` 인수를 추가합니다.
1. 리포트 파일의 위치를 가리키는 [`codequality` 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportscodequality)를 선언합니다.

[Flake8 CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)를 사용하거나 조정하여 스캔을 실행하고 코드 품질과 출력을 통합할 수도 있습니다.

#### Pylint {#pylint}

CI/CD 파이프라인에서 이미 [Pylint](https://pypi.org/project/pylint/) 작업이 있다면 코드 품질에 출력을 보내는 리포트를 추가해야 합니다. 출력을 통합하려면:

1. [`pylint-gitlab`](https://pypi.org/project/pylint-gitlab/)를 프로젝트의 종속성으로 설치합니다.
1. Pylint를 실행하는 데 사용하는 명령에 `--output-format=pylint_gitlab.GitlabCodeClimateReporter` 인수를 추가합니다.
1. `pylint` 명령을 변경하여 출력을 파일로 보냅니다.
1. 리포트 파일의 위치를 가리키는 [`codequality` 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportscodequality)를 선언합니다.

[Pylint CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)를 사용하거나 조정하여 스캔을 실행하고 코드 품질과 출력을 통합할 수도 있습니다.

#### Ruff {#ruff}

CI/CD 파이프라인에서 이미 [Ruff](https://docs.astral.sh/ruff/) 작업이 있다면 코드 품질에 출력을 보내는 리포트를 추가해야 합니다. 출력을 통합하려면:

1. Ruff를 실행하는 데 사용하는 명령에 `--output-format=gitlab` 인수를 추가합니다.
1. `ruff check` 명령을 변경하여 출력을 파일로 보냅니다.
1. 리포트 파일의 위치를 가리키는 [`codequality` 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportscodequality)를 선언합니다.

[코드 품질과 출력을 통합하고 스캔을 실행하도록 문서화된 Ruff GitLab CI/CD 통합](https://docs.astral.sh/ruff/integrations/#gitlab-cicd)을 사용하거나 조정할 수도 있습니다.

#### golangci-lint {#golangci-lint}

CI/CD 파이프라인에서 이미 [`golangci-lint`](https://golangci-lint.run/) 작업이 있다면 코드 품질에 출력을 보내는 리포트를 추가해야 합니다. 출력을 통합하려면:

1. `golangci-lint`를 실행하는 데 사용하는 명령에 인수를 추가합니다.

   - v1의 경우 `--out-format code-climate:gl-code-quality-report.json,line-number`을 추가합니다.
   - v2의 경우 `--output.code-climate.path=gl-code-quality-report.json`을 추가합니다.

1. 리포트 파일의 위치를 가리키는 [`codequality` 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportscodequality)를 선언합니다.

[golangci-lint CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)를 사용하거나 조정하여 스캔을 실행하고 코드 품질과 출력을 통합할 수도 있습니다.

#### PMD Copy/Paste Detector {#pmd-copypaste-detector}

[PMD Copy/Paste Detector (CPD)](https://pmd.github.io/pmd/pmd_userdocs_cpd.html)는 기본 출력이 필요한 형식을 준수하지 않기 때문에 추가 구성이 필요합니다.

[PMD CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)를 사용하거나 조정하여 스캔을 실행하고 코드 품질과 출력을 통합할 수 있습니다.

#### SwiftLint {#swiftlint}

[SwiftLint](https://realm.github.io/SwiftLint/) 사용은 기본 출력이 필요한 형식을 준수하지 않기 때문에 추가 구성이 필요합니다.

[Swiftlint CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)를 사용하거나 조정하여 스캔을 실행하고 코드 품질과 출력을 통합할 수 있습니다.

#### RuboCop {#rubocop}

[RuboCop](https://rubocop.org/) 사용은 기본 출력이 필요한 형식을 준수하지 않기 때문에 추가 구성이 필요합니다.

[RuboCop CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)를 사용하거나 조정하여 스캔을 실행하고 코드 품질과 출력을 통합할 수 있습니다.

#### Roslynator {#roslynator}

[Roslynator](https://josefpihrt.github.io/docs/roslynator/) 사용은 기본 출력이 필요한 형식을 준수하지 않기 때문에 추가 구성이 필요합니다.

[Roslynator CI/CD 구성 요소](https://gitlab.com/explore/catalog/components/code-quality-oss/codequality-os-scanners-integration)를 사용하거나 조정하여 스캔을 실행하고 코드 품질과 출력을 통합할 수 있습니다.

### 문서 스캔 도구 {#documentation-scanning-tools}

코드 품질을 사용하여 리포지토리에 저장된 코드가 아닌 파일도 스캔할 수 있습니다.

#### Vale {#vale}

CI/CD 파이프라인에서 이미 [Vale](https://vale.sh/) 작업이 있다면 코드 품질에 출력을 보내는 리포트를 추가해야 합니다. 출력을 통합하려면:

1. 필요한 형식을 정의하는 리포지토리에 Vale 템플릿 파일을 만듭니다.
   - 오픈 소스 [GitLab 문서를 확인하는 데 사용되는 템플릿](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/.vale/vale-json.tmpl)을 복사할 수 있습니다.
   - 커뮤니티 [`gitlab-ci-utils` Vale 프로젝트](https://gitlab.com/gitlab-ci-utils/container-images/vale/-/blob/main/vale/vale-glcq.tmpl)에서 사용되는 것과 같은 다른 오픈 소스 변형을 사용할 수도 있습니다. 이 커뮤니티 프로젝트는 또한 [사전 제작된 컨테이너 이미지](https://gitlab.com/gitlab-ci-utils/container-images/vale)를 제공하므로 파이프라인에서 직접 사용할 수 있습니다.
1. Vale를 실행하는 데 사용하는 명령에 `--output="$VALE_TEMPLATE_PATH" --no-exit` 인수를 추가합니다.
1. `vale` 명령을 변경하여 출력을 파일로 보냅니다.
1. 리포트 파일의 위치를 가리키는 [`codequality` 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportscodequality)를 선언합니다.

오픈 소스 작업 정의를 사용하거나 조정하여 스캔을 실행하고 코드 품질과 출력을 통합할 수도 있습니다. 예를 들어:

- GitLab 문서를 확인하는 데 사용되는 [Vale 린팅 단계](https://gitlab.com/gitlab-org/gitlab/-/blob/94f870b8e4b965a41dd2ad576d50f7eeb271f117/.gitlab/ci/docs.gitlab-ci.yml#L71-87)입니다.
- 커뮤니티 [`gitlab-ci-utils` Vale 프로젝트](https://gitlab.com/gitlab-ci-utils/container-images/vale#usage)입니다.

#### markdownlint-cli2 {#markdownlint-cli2}

CI/CD 파이프라인에서 이미 [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) 작업이 있다면 코드 품질에 출력을 보내는 리포트를 추가해야 합니다. 출력을 통합하려면:

1. [`markdownlint-cli2-formatter-codequality`](https://www.npmjs.com/package/markdownlint-cli2-formatter-codequality)를 프로젝트의 개발 종속성으로 추가합니다.
1. 아직 없으면 리포지토리 상단 수준에 `.markdownlint-cli2.jsonc` 파일을 만듭니다.
1. `.markdownlint-cli2.jsonc`에 `outputFormatters` 지시문을 추가합니다:

   ```json
   {
     "outputFormatters": [
       [ "markdownlint-cli2-formatter-codequality" ]
     ]
   }
   ```

1. 리포트 파일의 위치를 가리키는 [`codequality` 리포트 아티팩트](../yaml/artifacts_reports.md#artifactsreportscodequality)를 선언합니다. 기본적으로 리포트 파일의 이름은 `markdownlint-cli2-codequality.json`입니다.
   1. 권장됨. 리포지토리의 `.gitignore` 파일에 리포트의 파일 이름을 추가합니다.

자세한 내용과 CI/CD 작업 정의 예제는 [`markdownlint-cli2-formatter-codequality`의 문서](https://www.npmjs.com/package/markdownlint-cli2-formatter-codequality)를 참조하세요.
