---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 정적 애플리케이션 보안 테스팅(SAST)
description: "스캔, 구성, 분석기, 취약성, 보고, 사용자 정의 및 통합."
---

<style>
table.sast-table tr:nth-child(even) {
    background-color: transparent;
}

table.sast-table td {
    border-left: 1px solid #dbdbdb;
    border-right: 1px solid #dbdbdb;
    border-bottom: 1px solid #dbdbdb;
}

table.sast-table tr td:first-child {
    border-left: 0;
}

table.sast-table tr td:last-child {
    border-right: 0;
}

table.sast-table ul {
    font-size: 1em;
    list-style-type: none;
    padding-left: 0px;
    margin-bottom: 0px;
}

table.no-vertical-table-lines td {
    border-left: none;
    border-right: none;
    border-bottom: 1px solid #f0f0f0;
}

table.no-vertical-table-lines tr {
    border-top: none;
}
</style>

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

정적 애플리케이션 보안 테스팅(SAST)은 소스 코드의 취약성을 프로덕션에 도달하기 전에 발견합니다. CI/CD 파이프라인에 직접 통합된 SAST는 개발 중에 보안 이슈를 식별하며, 이 때 가장 쉽고 비용 효율적으로 수정할 수 있습니다.

개발 후반부에 발견된 보안 취약성은 비용이 많이 드는 지연과 잠재적 침해를 초래합니다. SAST 스캔은 각 커밋과 함께 자동으로 발생하여 워크플로를 방해하지 않으면서 즉시 피드백을 제공합니다.

## GitLab Duo로 거짓 양성 감소 및 취약성 해결 {#reducing-false-positives-and-resolving-vulnerabilities-with-gitlab-duo}

{{< details >}}

- 계층:  Ultimate

{{< /details >}}

SAST 스캐너는 취약성 보고서에 노이즈를 생성하는 거짓 양성을 생성할 수 있습니다. GitLab Duo는 취약성 관리를 지원합니다.

### 거짓 양성 탐지 {#false-positive-detection}

[GitLab Duo 거짓 양성 탐지](../vulnerabilities/false_positive_detection.md)는 중요 및 높은 심각도의 SAST 취약성을 자동으로 분석하여 거짓 양성일 가능성이 있는 것을 식별합니다. 이는 보안 팀이 실제 취약성에 집중하고 수동 심사에 소요되는 시간을 줄이는 데 도움이 됩니다.

GitLab Duo 추가 기능이 있는 Ultimate 계층 고객의 경우, 거짓 양성 탐지가 각 보안 스캔 후에 자동으로 실행되며 각 평가에 대한 신뢰도 점수와 설명을 제공합니다.

### 에이전틱 SAST 취약성 해결 {#agentic-sast-vulnerability-resolution}

[에이전틱 SAST 취약성 해결](../vulnerabilities/agentic_vulnerability_resolution.md)은 높은 심각도 및 중요 심각도의 SAST 취약성에 대해 상황을 고려한 코드 수정으로 머지 리퀘스트를 자동으로 생성합니다. 이 에이전틱 방식은 최소한의 인간 개입으로 취약성을 해결하기 위해 다중 샷 추론을 사용합니다.

Ultimate 계층 고객의 경우, 취약성이 특정 조건을 충족할 때 각 보안 스캔 후에 에이전틱 취약성 해결이 자동으로 실행됩니다.

## 기능 {#features}

다음 표는 각 기능을 사용할 수 있는 GitLab 계층을 나열합니다.

| 기능                                                                                                                          | Free 및 Premium | Ultimate |
|:---------------------------------------------------------------------------------------------------------------------------------|:------------------|:------------|
| [오픈 소스 분석기](#supported-languages-and-frameworks)를 사용한 기본 스캔                                                 | {{< yes >}}       | {{< yes >}} |
| 다운로드 가능한 [SAST JSON 보고서](#download-a-sast-report)                                                                         | {{< yes >}}       | {{< yes >}} |
| [GitLab Advanced SAST](gitlab_advanced_sast.md)를 사용한 파일 간, 함수 간 스캔                                         | {{< no >}}        | {{< yes >}} |
| [머지 리퀘스트 위젯](#merge-request-widget)의 새 결과                                                                    | {{< no >}}        | {{< yes >}} |
| [머지 리퀘스트 변경사항 보기](#merge-request-changes-view)의 새 결과                                                        | {{< no >}}        | {{< yes >}} |
| [취약성 관리](../vulnerabilities/_index.md)                                                                         | {{< no >}}        | {{< yes >}} |
| [GitLab Duo 거짓 양성 탐지](../vulnerabilities/false_positive_detection.md)(GitLab Duo 추가 기능 필요)               | {{< no >}}        | {{< yes >}} |
| [에이전틱 SAST 취약성 해결](../vulnerabilities/agentic_vulnerability_resolution.md) | {{< no >}}        | {{< yes >}} |
| [UI 기반 스캐너 구성](#enable-sast-by-using-the-ui)                                                                   | {{< no >}}        | {{< yes >}} |
| [규칙 집합 사용자 정의](customize_rulesets.md)                                                                                   | {{< no >}}        | {{< yes >}} |
| [고급 취약성 추적](#advanced-vulnerability-tracking)                                                              | {{< no >}}        | {{< yes >}} |

## 시작하기 {#getting-started}

UI를 사용하거나 프로젝트의 GitLab CI/CD 구성 파일을 편집하여 프로젝트에서 SAST를 활성화합니다.

> [!note]
> 기본적으로 SAST는 브랜치 파이프라인에서만 실행됩니다. SAST를 머지 리퀘스트 파이프라인에서 실행하려면 [머지 리퀘스트 파이프라인과 함께 보안 스캔 도구 사용](../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)을 참조하세요.

### UI를 사용하여 SAST 활성화 {#enable-sast-by-using-the-ui}

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.2에서 UI에서 개별 SAST 분석기 구성 옵션을 [제거](https://gitlab.com/gitlab-org/gitlab/-/issues/410013)했습니다.

{{< /history >}}

기본 설정 또는 사용자 정의를 사용하여 UI를 사용하여 SAST를 활성화하고 구성할 수 있습니다. 사용할 수 있는 방법은 GitLab 라이선스 계층에 따라 다릅니다.

> [!note]
> UI 구성 방법은 기존 `.gitlab-ci.yml` 파일이 없거나 최소일 때 가장 잘 작동합니다. 복잡한 구성이 있으면 도구가 구문을 분석하지 못할 수 있습니다. 그 경우 대신 [CI/CD 파일 편집](#enable-sast-by-editing-the-cicd-file)하세요.

#### 사용자 정의를 통해 SAST 활성화 {#enable-sast-with-customizations}

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.
- Docker 또는 Kubernetes 실행기가 있는 Linux 기반 러너. GitLab.com에서 호스팅되는 러너를 사용하는 경우 Docker 또는 Kubernetes 실행기가 기본적으로 활성화됩니다.
  - Windows Runners에서의 러너는 지원되지 않습니다.
  - AMD64 이외의 CPU 아키텍처는 지원되지 않습니다.
- GitLab CI/CD 구성(`.gitlab-ci.yml`)은 기본적으로 포함된 `test` 스테이지를 포함해야 합니다. `.gitlab-ci.yml` 파일에서 스테이지를 재정의하면 `test` 스테이지가 필요합니다.

사용자 정의를 통해 SAST를 활성화하고 구성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. 프로젝트의 기본 브랜치의 최신 파이프라인이 완료되었으며 유효한 SAST 아티팩트를 생성했다면 **SAST 구성**을 선택하고, 그렇지 않으면 정적 애플리케이션 보안 테스팅(SAST) 행에서 **SAST 활성화**를 선택합니다.
1. 사용자 정의 SAST 값을 입력합니다.

   사용자 정의 값은 `.gitlab-ci.yml` 파일에 저장됩니다. SAST 구성 페이지에 없는 CI/CD 변수의 경우, 해당 값은 GitLab SAST 템플릿에서 상속됩니다.
1. **머지 리퀘스트 생성**을 선택합니다.
1. 머지 리퀘스트를 검토하고 병합합니다.

파이프라인에는 이제 SAST 작업이 포함됩니다. 지원되는 소스 코드가 있으면 파이프라인이 실행될 때 적절한 분석기와 기본 규칙이 자동으로 취약성을 스캔합니다. 해당 작업은 프로젝트의 파이프라인에서 `test` 스테이지 아래에 나타납니다.

#### 기본 설정만으로 SAST 활성화 {#enable-sast-with-default-settings-only}

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.
- Docker 또는 Kubernetes 실행기가 있는 Linux 기반 러너. GitLab.com에서 호스팅되는 러너를 사용하는 경우 Docker 또는 Kubernetes 실행기가 기본적으로 활성화됩니다.
  - Windows Runners에서의 러너는 지원되지 않습니다.
  - AMD64 이외의 CPU 아키텍처는 지원되지 않습니다.
- GitLab CI/CD 구성(`.gitlab-ci.yml`)은 기본적으로 포함된 `test` 스테이지를 포함해야 합니다. `.gitlab-ci.yml` 파일에서 스테이지를 재정의하면 `test` 스테이지가 필요합니다.

기본 설정으로 SAST를 활성화하고 구성하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **보안** > **보안 구성**을 선택합니다.
1. SAST 섹션에서 **머지 리퀘스트로 구성**을 선택합니다.

   머지 리퀘스트 페이지가 열립니다.
1. 필드를 완성하세요.
1. **머지 리퀘스트 생성**을 선택합니다.
1. 머지 리퀘스트를 검토하고 병합하여 SAST를 활성화합니다.

파이프라인에는 이제 SAST 작업이 포함됩니다. 지원되는 소스 코드가 있으면 파이프라인이 실행될 때 적절한 분석기와 기본 규칙이 자동으로 취약성을 스캔합니다. 해당 작업은 프로젝트의 파이프라인에서 `test` 스테이지 아래에 나타납니다.

### CI/CD 파일을 편집하여 SAST 활성화 {#enable-sast-by-editing-the-cicd-file}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할.
- Docker 또는 Kubernetes 실행기가 있는 Linux 기반 러너. GitLab.com에서 호스팅되는 러너를 사용하는 경우 Docker 또는 Kubernetes 실행기가 기본적으로 활성화됩니다.
  - Windows Runners에서의 러너는 지원되지 않습니다.
  - AMD64 이외의 CPU 아키텍처는 지원되지 않습니다.
- GitLab CI/CD 구성(`.gitlab-ci.yml`)은 기본적으로 포함된 `test` 스테이지를 포함해야 합니다. `.gitlab-ci.yml` 파일에서 스테이지를 재정의하면 `test` 스테이지가 필요합니다.

프로젝트에서 SAST를 활성화하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. **빌드** > **파이프라인** 편집기로 이동합니다.
1. SAST CI/CD 템플릿 또는 구성 요소를 추가합니다.

   템플릿을 사용하려면 다음 줄을 추가합니다:

   ```yaml
   include:
     - template: Jobs/SAST.gitlab-ci.yml
   ```

   CI/CD 구성 요소를 사용하려면 다음 줄을 추가합니다:

   ```yaml
   include:
     - component: gitlab.com/components/sast/sast@main
   ```

1. **검증** 탭을 선택한 후 **파이프라인 검증**을 선택합니다.

   **시뮬레이션이 성공적으로 완료되었습니다** 메시지는 파일이 유효함을 확인합니다.
1. **편집** 탭을 선택합니다.
1. 필드를 완성합니다:
   - 커밋 메시지.
   - 브랜치. 예를 들어, `add-sast`.
1. **이 변경 사항으로 새로운 머지 리퀘스트 시작** 확인란을 선택한 후 **변경 사항 커밋**을 선택합니다.

   머지 리퀘스트 페이지가 열립니다.
1. 표준 워크플로에 따라 필드를 완성한 후 **머지 리퀘스트 생성**을 선택합니다.
1. 표준 워크플로에 따라 머지 리퀘스트를 검토하고 편집한 후 **머지**를 선택합니다.

파이프라인에는 이제 SAST 작업이 포함됩니다. 지원되는 소스 코드가 있으면 파이프라인이 실행될 때 적절한 분석기와 기본 규칙이 자동으로 취약성을 스캔합니다. 해당 작업은 프로젝트의 파이프라인에서 `test` 스테이지 아래에 나타납니다.

[SAST 예제 프로젝트](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/semgrep/sast-getting-started)에서 작동하는 예제를 볼 수 있습니다.

### 다음 단계 {#next-steps}

SAST를 활성화한 후 다음을 수행할 수 있습니다:

- [결과 이해](#understanding-the-results) 방법에 대해 자세히 알아보세요.
- [최적화 팁](#optimization)을 검토합니다.
- [더 많은 프로젝트로의 롤아웃](#roll-out)을 계획합니다.

## 결과 이해 {#understanding-the-results}

전제 조건:

- 프로젝트에 대한 보안 관리자, Developer, Maintainer 또는 Owner 역할.

파이프라인에서 취약성을 검토할 수 있습니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. 파이프라인을 선택합니다.
1. **보안** 탭을 선택합니다.
1. 결과를 다운로드하거나 취약성을 선택하여 다음을 포함한 세부 정보(Ultimate 전용)를 확인합니다:
   - 설명:  취약성의 원인, 잠재적 영향 및 권장 수정 단계를 설명합니다.
   - 상태:  취약성이 심사되었는지 또는 해결되었는지 여부를 나타냅니다.
   - 심각도:  영향에 따라 6가지 수준으로 분류됩니다. [심각도 수준에 대해 자세히 알아보기](../vulnerabilities/severities.md).
   - 위치:  이슈를 발견한 파일 이름과 줄 번호를 표시합니다. 파일 경로를 선택하면 코드 보기에서 해당 줄이 열립니다.
   - 스캐너:  취약성을 감지한 분석기를 식별합니다.
   - 식별자:  취약성을 분류하는 데 사용되는 참조 목록(예: CWE 식별자 및 이를 감지한 규칙의 ID).

SAST 취약성은 발견된 취약성에 대한 기본 공통 약점 열거형(CWE) 식별자에 따라 이름이 지정됩니다. 스캐너가 감지한 특정 이슈에 대해 자세히 알아보려면 각 취약성 결과의 설명을 읽어보세요. SAST 커버리지에 대한 자세한 내용은 [SAST 규칙](rules.md)을 참조하세요.

Ultimate에서는 보안 스캔 결과를 다운로드할 수도 있습니다:

전제 조건:

- 프로젝트에 대한 보안 관리자, Developer, Maintainer 또는 Owner 역할.

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인**을 선택합니다.
1. 파이프라인을 선택합니다.
1. **보안** 탭을 선택합니다.
1. 파이프라인의 **보안** 탭에서 **결과 다운로드**를 선택합니다.

자세한 내용은 [파이프라인 보안 보고서](../detect/security_scanning_results.md)를 참조하세요.

> [!note]
> 결과는 기능 브랜치에서 생성됩니다. 결과가 기본 브랜치에 병합되면 취약성이 됩니다. 이 구분은 보안 태세를 평가할 때 중요합니다.

SAST 결과를 보는 추가 방법:

- 머지 리퀘스트 위젯:  새로 도입되었거나 해결된 결과를 표시합니다.
- 머지 리퀘스트 변경사항 보기:  변경된 줄에 대한 인라인 주석을 표시합니다.
- 취약성 보고서:  기본 브랜치에서 확인된 취약성을 표시합니다.

파이프라인은 SAST 및 DAST 스캔을 포함한 여러 작업으로 구성됩니다. 어떤 이유로든 작업이 완료되지 않으면 보안 대시보드에 SAST 스캐너 출력이 표시되지 않습니다. 예를 들어, SAST 작업은 완료되었으나 DAST 작업이 실패하면 보안 대시보드에 SAST 결과가 표시되지 않습니다. 실패 시 분석기는 종료 코드를 출력합니다.

### 머지 리퀘스트 위젯 {#merge-request-widget}

{{< details >}}

- 계층:  Ultimate

{{< /details >}}

대상 브랜치의 보고서를 비교할 수 있는 경우 SAST 결과가 머지 리퀘스트 위젯 영역에 표시됩니다. 머지 리퀘스트 위젯은 다음을 표시합니다:

- 머지 리퀘스트에 의해 도입된 새로운 SAST 결과입니다.
- 머지 리퀘스트에 의해 해결된 기존 결과입니다.

결과는 가능할 때마다 고급 취약성 추적을 사용하여 비교됩니다.

![보안 머지 리퀘스트 위젯](img/sast_mr_widget_v16_7.png)

### 머지 리퀘스트 변경사항 보기 {#merge-request-changes-view}

{{< details >}}

- 계층:  Ultimate

{{< /details >}}

{{< history >}}

- GitLab 16.6에서 이름이 `sast_reports_in_inline_diff`인 [플래그](../../../administration/feature_flags/_index.md)와 함께 [도입](https://gitlab.com/groups/gitlab-org/-/epics/10959)되었습니다. 기본적으로 비활성화됨.
- GitLab 16.8에서 기본적으로 활성화됩니다.
- GitLab 16.9에서 [기능 플래그가 제거](https://gitlab.com/gitlab-org/gitlab/-/issues/410191)되었습니다.

{{< /history >}}

SAST 결과는 머지 리퀘스트 **변경사항** 보기에 표시됩니다. SAST 이슈가 있는 줄은 거터 옆에 기호로 표시됩니다. 기호를 선택하여 이슈 목록을 확인한 후 이슈를 선택하여 세부 정보를 확인합니다.

![SAST 인라인 표시기](img/sast_inline_indicator_v16_7.png)

## 최적화 {#optimization}

요구 사항에 따라 SAST를 최적화하려면 다음을 수행할 수 있습니다:

- 규칙을 비활성화합니다.
- 스캔에서 파일 또는 경로를 제외합니다.

### 규칙 비활성화 {#disable-a-rule}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할.

예를 들어 거짓 양성이 너무 많이 생성되어 규칙을 비활성화하려는 경우:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 아직 존재하지 않으면 프로젝트 루트에 `.gitlab/sast-ruleset.toml` 파일을 만듭니다.
1. 취약성 세부 정보에서 결과를 트리거한 규칙의 ID를 찾으세요.
1. 규칙 ID를 사용하여 규칙을 비활성화합니다. 예를 들어, `gosec.G107-1`을 비활성화하려면 `.gitlab/sast-ruleset.toml`에 다음을 추가합니다:

   ```toml
   [semgrep]
     [[semgrep.ruleset]]
       disable = true
       [semgrep.ruleset.identifier]
         type = "semgrep_id"
         value = "gosec.G107-1"
   ```

규칙 집합 사용자 정의에 대한 자세한 내용은 [규칙 집합 사용자 정의](customize_rulesets.md)를 참조하세요.

### 스캔에서 파일 또는 경로 제외 {#exclude-files-or-paths-from-being-scanned}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할.

테스트 또는 임시 코드와 같이 스캔에서 파일 또는 경로를 제외하려면 `SAST_EXCLUDED_PATHS` 변수를 설정합니다. 예를 들어, `rule-template-injection.go`를 건너뛰려면 `.gitlab-ci.yml`에 다음을 추가합니다:

```yaml
variables:
  SAST_EXCLUDED_PATHS: "rule-template-injection.go"
```

구성 옵션에 대한 자세한 내용은 [사용 가능한 CI/CD 변수](#available-cicd-variables)를 참조하세요.

## 롤아웃 {#roll-out}

단일 프로젝트의 SAST 결과에 확신이 있으면 구현을 추가 프로젝트로 확장할 수 있습니다:

- [강제 스캔 실행](../detect/security_configuration.md#create-a-shared-configuration)을 사용하여 SAST 설정을 그룹 전체에 적용합니다.
- [원격 구성 파일 지정](customize_rulesets.md#use-a-remote-ruleset-file)으로 중앙 규칙 집합을 공유하고 재사용합니다.
- 고유한 요구 사항이 있으면 SAST를 오프라인 환경에서 실행하거나 SELinux 제약 조건에서 실행할 수 있습니다.

## 지원되는 언어 및 프레임워크 {#supported-languages-and-frameworks}

GitLab SAST는 다음 언어 및 프레임워크 스캔을 지원합니다.

사용 가능한 스캔 옵션은 GitLab 계층에 따라 다릅니다:

- Ultimate에서 GitLab Advanced SAST는 더 정확한 결과를 제공합니다. 지원되는 언어에 이를 사용해야 합니다.
- 모든 계층에서 GitLab 제공 분석기(오픈 소스 스캐너 기반)를 사용하여 코드를 스캔할 수 있습니다.

SAST의 언어 지원 계획에 대한 자세한 내용은 [범주 방향 페이지](https://about.gitlab.com/direction/application_security_testing/static-analysis/sast/#language-support)를 참조하세요.

### 전체 지원 언어 {#languages-with-full-support}

{{< history >}}

- C/C++ 지원이 [GitLab 18.6에서 도입](https://gitlab.com/groups/gitlab-org/-/epics/14271)되었습니다.

{{< /history >}}

이러한 언어는 GitLab Advanced SAST(Ultimate)와 표준 분석기(모든 계층) 모두에서 지원됩니다:

| 언어               | GitLab Advanced SAST<sup>1</sup> | 표준 분석기<sup>2</sup> |
|------------------------|----------------------------------|-------------------------------|
| C                      | {{< yes >}}                      | {{< yes >}}                   |
| C++                    | {{< yes >}}                      | {{< yes >}}                   |
| C#                     | {{< yes >}}                      | {{< yes >}}                   |
| Go                     | {{< yes >}}                      | {{< yes >}}                   |
| Java<sup>3</sup>       | {{< yes >}}                      | {{< yes >}}                   |
| Java Properties        | {{< yes >}}                      | {{< yes >}}                   |
| JavaScript<sup>4</sup> | {{< yes >}}                      | {{< yes >}}                   |
| PHP                    | {{< yes >}}                      | {{< yes >}}                   |
| Python                 | {{< yes >}}                      | {{< yes >}}                   |
| Ruby<sup>5</sup>       | {{< yes >}}                      | {{< yes >}}                   |
| TypeScript             | {{< yes >}}                      | {{< yes >}}                   |
| YAML<sup>6</sup>       | {{< yes >}}                      | {{< yes >}}                   |

**각주**:

<!-- Disable ordered list rule <https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md#md029---ordered-list-item-prefix> -->
<!-- markdownlint-disable MD029 -->

1. [GitLab Advanced SAST](gitlab_advanced_sast.md) \- Ultimate 계층만 해당.
2. 모든 계층. 별도로 지정하지 않는 한 [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) 분석기와 [GitLab 관리 규칙](rules.md#semgrep-based-analyzer)을 사용합니다.
3. Java Server Pages(JSP) 및 Android 포함.
4. Node.js 및 React 포함.
5. Ruby on Rails 포함.
6. YAML 지원은 다음 파일 패턴으로 제한됩니다:
   - `application*.yml`
   - `application*.yaml`
   - `bootstrap*.yml`
   - `bootstrap*.yaml`

<!-- markdownlint-enable MD029 -->

### 표준 분석기 지원만 제공되는 언어 {#languages-with-standard-analyzer-support-only}

이러한 언어는 표준 분석기(모든 계층)에서 지원되지만 GitLab Advanced SAST에서는 지원되지 않습니다:

| 언어           | 표준 분석기<sup>1</sup>                                                                           | 제안된 지원<sup>2</sup> |
|--------------------|---------------------------------------------------------------------------------------------------------|------------------------------|
| Apex(Salesforce)  | {{< yes >}} [PMD-Apex](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex)              | 없음                         |
| Elixir(Phoenix)   | {{< yes >}} [Sobelow](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow)                | 없음                         |
| Groovy             | {{< yes >}} [SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)<sup>3</sup>  | 없음                         |
| Kotlin<sup>4</sup> | {{< yes >}}                                                                                             | [에픽 15173](https://gitlab.com/groups/gitlab-org/-/epics/15173) |
| Objective-C(iOS)  | {{< yes >}}                                                                                             | [에픽 16318](https://gitlab.com/groups/gitlab-org/-/epics/16318) |
| Scala              | {{< yes >}}                                                                                             | [에픽 15174](https://gitlab.com/groups/gitlab-org/-/epics/15174) |
| Swift(iOS)        | {{< yes >}}                                                                                             | [에픽 16318](https://gitlab.com/groups/gitlab-org/-/epics/16318) |

**각주**:

1. 모든 계층. 별도로 지정하지 않는 한 [Semgrep](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep) 분석기와 [GitLab 관리 규칙](rules.md#semgrep-based-analyzer)을 사용합니다.
1. 참조된 에픽은 이러한 언어에 대한 GitLab Advanced SAST 지원을 제안합니다.
1. find-sec-bugs 플러그인이 포함된 SpotBugs. Gradle, Maven 및 SBT를 지원합니다. Gradle wrapper, Grails 및 Maven wrapper와 같은 변형과도 함께 사용할 수 있습니다. 그러나 SpotBugs는 Ant 기반 프로젝트에 사용할 때 [제한 사항](https://gitlab.com/gitlab-org/gitlab/-/issues/350801)이 있습니다. Ant 기반 Java 또는 Scala 프로젝트의 경우 GitLab Advanced SAST 또는 Semgrep 기반 분석기를 사용해야 합니다.
1. Android 포함.

SAST CI/CD 템플릿에는 Kubernetes 매니페스트 및 Helm 차트를 스캔할 수 있는 분석기 작업도 포함되어 있습니다. 이 작업은 기본적으로 꺼져 있습니다. [Kubesec 분석기 활성화](#enabling-kubesec-analyzer)를 참조하거나 추가 플랫폼을 지원하는 [IaC 스캔](../iac_scanning/_index.md)을 대신 고려하세요.

더 이상 지원되지 않는 SAST 분석기에 대해 자세히 알아보려면 [지원 종료에 도달한 분석기](analyzers.md#analyzers-that-have-reached-end-of-support)를 참조하세요.

## 고급 취약성 추적 {#advanced-vulnerability-tracking}

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

소스 코드는 가변적입니다. 개발자가 변경 사항을 적용함에 따라 소스 코드가 동일한 파일 내에서 이동하거나 파일 간에 이동할 수 있습니다. 보안 분석기는 이미 취약성 보고서에서 추적 중인 취약성을 보고했을 수 있습니다. 이러한 취약성은 발견 및 수정을 위해 특정 문제 코드 조각에 연결됩니다. 코드 조각이 이동할 때 안정적으로 추적되지 않으면 동일한 취약성이 다시 보고될 수 있어 취약성 관리가 더 어려워집니다.

GitLab SAST는 고급 취약성 추적 알고리즘을 사용하여 리팩토링이나 관련 없는 변경으로 인해 동일한 취약성이 동일한 파일 내에서 이동한 경우를 더 정확하게 식별합니다.

고급 취약성 추적 지원 여부는 사용된 언어 및 분석기에 따라 다릅니다.

GitLab Advanced SAST 분석기와 Semgrep 기반 분석기 모두에서 지원되는 언어:

- C
- C++
- C#
- Go
- Java
- JavaScript
- Python

Semgrep 기반 분석기에서만 지원되는 언어:

- PHP
- Ruby

더 많은 언어 및 분석기에 대한 지원은 [에픽 5144](https://gitlab.com/groups/gitlab-org/-/epics/5144)에서 추적됩니다.

자세한 내용은 기밀 프로젝트 `https://gitlab.com/gitlab-org/security-products/post-analyzers/tracking-calculator`를 참조하세요. 이 프로젝트의 콘텐츠는 GitLab 팀 멤버만 사용할 수 있습니다.

## 자동 취약성 해결 {#automatic-vulnerability-resolution}

{{< history >}}

- GitLab 15.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/368284)되었으며 `sec_mark_dropped_findings_as_resolved`라는 이름의 [프로젝트 플래그](../../../administration/feature_flags/_index.md)가 지정되었습니다.
- GitLab 15.10에서 기본적으로 활성화되었습니다.
- GitLab 16.2에서 [기능 플래그가 제거](https://gitlab.com/gitlab-org/gitlab/-/issues/375128)되었습니다.

{{< /history >}}

여전히 관련 있는 취약성에 집중하도록 GitLab SAST는 다음과 같은 경우 자동으로 취약성을 [해결](../vulnerabilities/_index.md#vulnerability-status-values)합니다:

- 사용자가 [사전 정의된 규칙을 비활성화](customize_rulesets.md#disable-default-rules)한 경우.
- 기본 규칙 집합에서 규칙이 제거된 경우.

자동 해결은 [Semgrep 기반 분석기](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)의 결과에 대해서만 사용할 수 있습니다. 취약성 관리 시스템은 자동으로 해결된 취약성에 댓글을 남기므로 취약성에 대한 이력 기록을 확인할 수 있습니다.

나중에 규칙을 다시 활성화하면 결과를 다시 심사할 수 있도록 다시 열립니다.

## 지원되는 배포판 {#supported-distributions}

기본 스캐너 이미지는 크기와 유지 관리 편의성을 위해 Alpine 기본 이미지를 기반으로 구축됩니다.

### FIPS 활성화 이미지 {#fips-enabled-images}

GitLab은 [Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) 기본 이미지를 기반으로 하며 FIPS 140 검증을 받은 암호화 모듈을 사용하는 이미지 버전을 제공합니다. FIPS 활성화 이미지를 사용하려면 다음 중 하나를 수행할 수 있습니다:

- `SAST_IMAGE_SUFFIX`를 `-fips`로 설정합니다.
- 기본 이미지 이름에 `-fips` 확장자를 추가합니다.

예를 들어:

```yaml
variables:
  SAST_IMAGE_SUFFIX: '-fips'

include:
  - template: Jobs/SAST.gitlab-ci.yml
```

FIPS 준수 이미지는 GitLab Advanced SAST 및 Semgrep 기반 분석기에서만 사용할 수 있습니다.

> [!warning]
> FIPS 준수 방식으로 SAST를 사용하려면 [다른 분석기가 실행되지 않도록 제외](analyzers.md#customize-analyzers)해야 합니다. [root가 아닌 사용자가 있는 러너](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/#run-with-non-root-user)에서 Advanced SAST 또는 Semgrep을 실행하기 위해 FIPS 활성화 이미지를 사용하는 경우, `runners.kubernetes.pod_security_context` 아래의 `run_as_user` 속성을 업데이트하여 [이미지에서 생성된](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/a5d822401014f400b24450c92df93467d5bbc6fd/Dockerfile.fips#L58) `gitlab` 사용자의 ID(여기서는 `1000`)를 사용하도록 해야 합니다.

## SAST 보고서 다운로드 {#download-a-sast-report}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할.

각 SAST 분석기는 작업 아티팩트로 JSON 보고서를 출력합니다. 파일에는 감지된 모든 취약성의 세부 정보가 포함됩니다. GitLab 외부에서 처리하기 위해 파일을 다운로드할 수 있습니다.

자세한 정보는 다음을 참조하세요:

- [SAST 보고서 파일 스키마](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/dist/sast-report-format.json)
- [SAST 보고서 파일 예제](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/qa/expect/js/default/gl-sast-report.json)

## 구성 {#configuration}

GitLab SAST는 기본 구성으로 사용하도록 설계되었습니다. 하지만 필요에 따라 [구성 변수를 변경](#available-cicd-variables)하거나 [탐지 규칙을 사용자 정의](customize_rulesets.md)할 수 있습니다.

### 안정적 대 최신 SAST 템플릿 {#stable-vs-latest-sast-templates}

SAST는 프로덕션 환경에서 기본적으로 사용되는 [`stable`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml) 템플릿과 최신 기능을 테스트하기 위한 [`latest`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.latest.gitlab-ci.yml) 템플릿을 제공합니다. 각 템플릿의 차이점과 사용 시기에 대한 자세한 내용은 [템플릿 에디션](../detect/security_configuration.md#template-editions)을 참조하세요.

### SAST 작업 재정의 {#override-sast-jobs}

`variables`, `dependencies` 및 [`rules`](../../../ci/yaml/_index.md#rules)와 같은 속성을 사용자 정의하려면 SAST 작업을 재정의하세요.

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할.

작업 정의를 재정의하려면:

- 재정의할 SAST 작업과 동일한 이름의 작업을 선언합니다.

  템플릿 포함 선언 뒤에 이 새 작업을 배치하고 그 아래에 추가 키를 지정합니다.

다음 예제에서는 `spotbugs` 분석기에 대해 CI/CD 변수 `FAIL_NEVER`가 활성화되었습니다.

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

spotbugs-sast:
  variables:
    FAIL_NEVER: 1
```

### 분석기 이미지 버전 고정 {#pin-analyzer-image-version}

파이프라인에서 특정 분석기 이미지 버전을 사용하려면 이미지 버전을 고정하세요. GitLab 관리 CI/CD 템플릿은 주 버전을 지정하고 해당 주 버전 내에서 최신 분석기 릴리스를 자동으로 가져옵니다. 경우에 따라 특정 버전을 사용해야 할 수도 있습니다. 예를 들어, 이후 릴리스에서의 회귀를 피해야 할 때가 있습니다.

태그를 다음 옵션 중 하나로 설정할 수 있습니다:

- 주 버전(예: `3`). 파이프라인은 이 주 버전 내에서 릴리스되는 모든 부 버전 또는 패치 업데이트를 사용합니다.
- 부 버전(예: `3.7`). 파이프라인은 이 부 버전 내에서 릴리스되는 모든 패치 업데이트를 사용합니다.
- 패치 버전(예: `3.7.0`). 파이프라인은 어떠한 업데이트도 받지 않습니다.

이 변수는 특정 작업 내에서만 설정하세요. [최상위 수준](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)에서 설정하면 설정한 버전이 모든 SAST 분석기에 사용됩니다.

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할.

분석기 이미지를 특정 버전으로 고정하려면:

- 프로젝트의 `.gitlab-ci.yml` 파일에서 `SAST_ANALYZER_IMAGE_TAG` CI/CD 변수를 설정합니다. 이 CI/CD 변수는 `SAST.gitlab-ci.yml` 템플릿을 포함한 후에 나열되어야 합니다.

다음 예제에서는 `semgrep` 분석기의 특정 부 버전과 `brakeman` 분석기의 특정 패치 버전이 설정됩니다:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

semgrep-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "3.7"

brakeman-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "3.1.1"
```

### 비공개 리포지토리의 자격 증명을 전달하기 위해 CI/CD 변수 사용 {#using-cicd-variables-to-pass-credentials-for-private-repositories}

일부 분석기는 분석을 수행하기 위해 프로젝트의 종속성을 다운로드해야 합니다. 이러한 종속성은 비공개 Git 리포지토리에 있을 수 있으며 이를 다운로드하려면 사용자 이름 및 암호와 같은 자격 증명이 필요합니다. 분석기에 따라 [사용자 정의 CI/CD 변수](#available-cicd-variables)를 사용하여 이러한 자격 증명을 제공할 수 있습니다.

#### 비공개 Maven 리포지토리에 사용자 이름 및 암호를 전달하기 위해 CI/CD 변수 사용 {#using-a-cicd-variable-to-pass-username-and-password-to-a-private-maven-repository}

비공개 Maven 리포지토리에 로그인 자격 증명이 필요한 경우 `MAVEN_CLI_OPTS`CI/CD 변수를 사용할 수 있습니다.

자세한 내용은 [비공개 Maven 리포지토리를 사용하는 방법](../dependency_scanning/legacy_dependency_scanning/_index.md#authenticate-with-a-private-maven-repository)을 참조하세요.

### Kubesec 분석기 활성화 {#enabling-kubesec-analyzer}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할.

Kubesec 분석기를 활성화하려면 `SCAN_KUBERNETES_MANIFESTS`를 `"true"`로 설정해야 합니다. `.gitlab-ci.yml`에서 다음을 정의합니다:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SCAN_KUBERNETES_MANIFESTS: "true"
```

### Semgrep 기반 분석기를 사용하여 다른 언어 스캔 {#scan-other-languages-with-the-semgrep-based-analyzer}

GitLab 관리 규칙 집합에서 지원되지 않는 언어를 스캔하도록 Semgrep 기반 SAST 분석기를 사용자 정의할 수 있습니다. 그러나 GitLab이 이러한 다른 언어에 대한 규칙 집합을 제공하지 않으므로 이를 포함하도록 [기본 규칙을 교체하거나 추가](customize_rulesets.md#replace-or-add-to-the-default-rules)해야 합니다. 또한 `semgrep-sast` CI/CD 작업의 `rules`을 수정하여 관련 파일이 수정될 때 작업이 실행되도록 해야 합니다.

#### Rust 애플리케이션 스캔 {#scan-a-rust-application}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할.

Rust 애플리케이션을 스캔하려면 다음 단계를 완료합니다:

1. Rust에 대한 사용자 정의 규칙 집합을 제공합니다. `.gitlab/` 디렉터리의 리포지토리 루트에 `sast-ruleset.toml`이라는 파일을 만듭니다.

   다음 예제는 Rust의 Semgrep 레지스트리 기본 규칙 집합을 사용합니다:

   ```toml
   [semgrep]
     description = "Rust ruleset for Semgrep"
     targetdir = "/sgrules"
     timeout = 60

     [[semgrep.passthrough]]
       type  = "url"
       value = "https://semgrep.dev/c/p/rust"
       target = "rust.yml"
   ```

   자세한 내용은 [사전 정의된 규칙을 교체하거나 추가](customize_rulesets.md#replace-or-add-to-the-default-rules)를 참조하세요.
1. `semgrep-sast` 작업을 재정의하여 Rust(`.rs`) 파일을 감지하는 규칙을 추가합니다.

   `.gitlab-ci.yml` 파일에서 다음을 정의합니다:

   ```yaml
   include:
     - template: Jobs/SAST.gitlab-ci.yml

   semgrep-sast:
     rules:
       - if: $CI_COMMIT_BRANCH
         exists:
           - '**/*.rs'
           # include any other file extensions you need to scan from the semgrep-sast template: Jobs/SAST.gitlab-ci.yml
   ```

### SpotBugs 분석기에 대한 JDK21 지원 {#jdk21-support-for-spotbugs-analyzer}

SpotBugs 분석기의 버전 `6`은 JDK21에 대한 지원을 추가하고 JDK11을 제거합니다. 기본 버전은 `5`로 유지됩니다([이슈 517169](https://gitlab.com/gitlab-org/gitlab/-/issues/517169)에서 논의됨).

버전 `6`을 사용하려면 분석기 버전을 고정합니다. 자세한 내용은 [분석기 이미지 버전 고정](#pin-analyzer-image-version)을 참조하세요.

```yaml
spotbugs-sast:
  variables:
    SAST_ANALYZER_IMAGE_TAG: "6"
```

### SpotBugs 분석기와 함께 사전 컴파일 사용 {#using-pre-compilation-with-spotbugs-analyzer}

SpotBugs 기반 분석기는 Groovy 프로젝트에 대해 컴파일된 바이트코드를 스캔합니다. 기본적으로 스캔할 수 있도록 종속성을 가져오고 코드를 컴파일하려고 자동으로 시도합니다.

자동 컴파일은 다음 중 하나인 경우 실패할 수 있습니다:

- 프로젝트에 사용자 정의 빌드 구성이 필요합니다.
- 분석기에 내장되지 않은 언어 버전을 사용합니다.

이러한 이슈를 해결하려면 분석기의 컴파일 단계를 건너뛰고 대신 파이프라인의 이전 스테이지에서 아티팩트를 직접 제공합니다. 이 전략을 사전 컴파일이라고 합니다.

#### 사전 컴파일된 아티팩트 공유 {#share-pre-compiled-artifacts}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할.

사전 컴파일된 아티팩트를 공유하려면 프로젝트의 `.gitlab-ci.yml` 파일을 다음과 같이 변경합니다:

1. 컴파일 작업(일반적으로 `build`라고 함)을 사용하여 프로젝트를 컴파일하고 컴파일된 출력을 `job artifact`로 저장합니다(CI/CD `artifacts: paths` 변수 사용).

   - Maven 프로젝트의 경우 출력 폴더는 일반적으로 `target` 디렉터리입니다.
   - Gradle 프로젝트의 경우 일반적으로 `build` 디렉터리입니다.
   - 프로젝트에서 사용자 정의 출력 위치를 사용하는 경우 아티팩트 경로를 적절하게 설정합니다.

1. `COMPILE: "false"` CI/CD 변수를 `spotbugs-sast` 작업에 설정하여 자동 컴파일을 비활성화합니다.
1. `dependencies` 키워드를 설정하여 `spotbugs-sast` 작업이 컴파일 작업에 종속되도록 합니다. 이를 통해 `spotbugs-sast` 작업이 컴파일 작업에서 만든 아티팩트를 다운로드하고 사용할 수 있습니다.

다음 예제는 Gradle 프로젝트를 사전 컴파일하고 컴파일된 바이트코드를 분석기에 제공합니다:

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/SAST.gitlab-ci.yml

build:
  image: gradle:7.6-jdk8
  stage: build
  script:
    - gradle build
  artifacts:
    paths:
      - build/

spotbugs-sast:
  dependencies:
    - build
  variables:
    COMPILE: "false"
    SECURE_LOG_LEVEL: debug
```

### 종속성 지정(Maven만 해당) {#specify-dependencies-maven-only}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할.

프로젝트에서 분석기가 인식할 외부 종속성이 필요하고 Maven을 사용하는 경우 `MAVEN_REPO_PATH` 변수를 사용하여 로컬 리포지토리의 위치를 지정할 수 있습니다.

종속성 지정은 Maven 기반 프로젝트에서만 지원됩니다. 다른 빌드 도구(예: Gradle)는 종속성을 지정하기 위한 동등한 메커니즘이 없습니다. 그 경우 컴파일된 아티팩트에 모든 필요한 종속성이 포함되어 있는지 확인하세요.

Maven 종속성을 지정하려면 프로젝트의 `.gitlab-ci.yml` 파일을 다음과 같이 변경합니다:

1. `MAVEN_REPO_PATH` 변수를 설정하여 로컬 Maven 리포지토리를 가리킵니다.
1. 빌드 작업이 해당 경로에 리포지토리를 만드는지 확인합니다(예: `mvn package
   -Dmaven.repo.local=./.m2/repository` 실행).
1. `spotbugs-sast` 작업을 구성하여 빌드 작업에 종속되고 컴파일을 비활성화합니다.

다음 예제는 Maven 프로젝트를 사전 컴파일하고 종속성과 함께 컴파일된 바이트코드를 분석기에 제공합니다:

```yaml
stages:
  - build
  - test

include:
  - template: Jobs/SAST.gitlab-ci.yml

build:
  image: maven:3.6-jdk-8-slim
  stage: build
  script:
    - mvn package -Dmaven.repo.local=./.m2/repository
  artifacts:
    paths:
      - .m2/
      - target/

spotbugs-sast:
  dependencies:
    - build
  variables:
    MAVEN_REPO_PATH: $CI_PROJECT_DIR/.m2/repository
    COMPILE: "false"
    SECURE_LOG_LEVEL: debug
```

분석기는 이제 스캔 중에 프로젝트의 종속성을 인식합니다.

### 사용 가능한 CI/CD 변수 {#available-cicd-variables}

SAST는 `.gitlab-ci.yml`에서 `variables` 매개변수를 사용하여 구성할 수 있습니다.

GitLab SAST 템플릿을 사용하면 모든 표준 SAST 구성 CI/CD 변수 및 [사용자 정의 변수](../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)가 기본 SAST 분석기 이미지로 전파됩니다.

> [!warning]
> GitLab 보안 스캔 도구의 모든 사용자 정의는 이러한 변경 사항을 기본 브랜치에 병합하기 전에 머지 리퀘스트에서 테스트해야 합니다. 그렇지 않으면 많은 거짓 양성을 포함한 예상치 못한 결과가 발생할 수 있습니다.

다음 예제는 SAST 템플릿을 포함하여 `SEARCH_MAX_DEPTH` 변수를 모든 작업에서 `10`으로 재정의합니다. 템플릿은 파이프라인 구성 전에 평가되므로 변수의 마지막 언급이 우선합니다.

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SEARCH_MAX_DEPTH: 10
```

#### 사용자 정의 인증 기관 {#custom-certificate-authority}

사용자 정의 인증 기관(CA)에 대한 지원이 다음 분석기 버전에 도입되었습니다.

| 분석기   | 버전                                                                                        |
|------------|------------------------------------------------------------------------------------------------|
| `kubesec`  | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/kubesec/-/releases/v2.1.0)  |
| `pmd-apex` | [v2.1.0](https://gitlab.com/gitlab-org/security-products/analyzers/pmd-apex/-/releases/v2.1.0) |
| `semgrep`  | [v0.0.1](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/releases/v0.0.1)  |
| `sobelow`  | [v2.2.0](https://gitlab.com/gitlab-org/security-products/analyzers/sobelow/-/releases/v2.2.0)  |
| `spotbugs` | [v2.7.1](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs/-/releases/v2.7.1) |

##### 사용자 정의 인증 기관 사용 {#use-a-custom-certificate-authority}

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Developer 역할.
- [X.509 PEM 공개 키 인증서의 텍스트 표현](https://www.rfc-editor.org/rfc/rfc7468#section-5.1).

  다음 방법 중 하나를 통해 인증서를 제공할 수 있습니다:

  - 프로젝트의 `.gitlab-ci.yml` 파일에 직접 인증서를 추가합니다.
  - 인증서 경로를 제공하는 `file` CI/CD 변수를 만듭니다.
  - 인증서의 텍스트 표현을 포함하는 [UI의 사용자 정의 변수](../../../ci/variables/_index.md#for-a-project)를 설정합니다.

사용자 정의 CA 인증서를 신뢰하려면:

- `ADDITIONAL_CA_CERT_BUNDLE` 변수를 SAST 환경에서 신뢰하려는 CA 인증서 번들로 설정합니다.

예를 들어, 프로젝트의 `.gitlab-ci.yml` 파일에서 이 값을 구성하려면 다음을 사용합니다:

```yaml
variables:
  ADDITIONAL_CA_CERT_BUNDLE: |
      -----BEGIN CERTIFICATE-----
      MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
      ...
      jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
      -----END CERTIFICATE-----
```

#### Docker 이미지 {#docker-images}

다음은 Docker 이미지 관련 CI/CD 변수입니다.

| CI/CD 변수            | 설명                                                                                                                                                   |
|---------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `SECURE_ANALYZERS_PREFIX` | 기본 이미지를 제공하는 Docker 레지스트리의 이름을 무시합니다(프록시). 자세한 내용은 [분석기 사용자 정의](analyzers.md)를 참조하세요.                   |
| `SAST_EXCLUDED_ANALYZERS` | 실행되면 안 될 기본 이미지의 이름. 자세한 내용은 [분석기 사용자 정의](analyzers.md)를 참조하세요.                                                     |
| `SAST_ANALYZER_IMAGE_TAG` | 분석기 이미지의 기본 버전을 무시합니다. 자세한 내용은 [분석기 이미지 버전 고정](#pin-analyzer-image-version)을 참조하세요.                          |
| `SAST_IMAGE_SUFFIX`       | 이미지 이름에 추가된 접미사. `-fips`로 설정하면 `FIPS-enabled` 이미지가 스캔에 사용됩니다. 자세한 내용은 [FIPS 활성화 이미지](#fips-enabled-images)를 참조하세요. |

#### 취약성 필터 {#vulnerability-filters}

SAST는 파일 경로 및 검색 깊이에 따라 코드를 제외하도록 구성할 수 있습니다. 다음 CI/CD 변수는 스캔될 파일과 분석기가 코드베이스를 검색하는 방식을 제어합니다.

<table class="sast-table">
  <thead>
    <tr>
      <th>CI/CD 변수</th>
      <th>설명</th>
      <th>기본값</th>
      <th>분석기</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="3">
        <code>SAST_EXCLUDED_PATHS</code>
      </td>
      <td rowspan="3">
        취약성을 제외하기 위한 경로의 쉼표로 구분된 목록. 이 변수의 정확한 처리는 사용되는 분석기에 따라 다릅니다.<sup><b><a href="#sast-excluded-paths-description">1</a></b></sup>
      </td>
      <td rowspan="3">
        <code> <a href="https://gitlab.com/gitlab-org/gitlab/blob/v17.3.0-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml#L13">spec, test, tests, tmp</a> </code>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/semgrep">Semgrep</a><sup><b><a href="#sast-excluded-paths-semgrep">2</a></b>,</sup><sup><b><a href="#sast-excluded-paths-all-other-sast-analyzers">3</a></b></sup>
      </td>
    </tr>
    <tr>
      <td>
        <a href="https://docs.gitlab.com/user/application_security/sast/gitlab_advanced_sast/">GitLab Advanced SAST</a><sup><b><a href="#sast-excluded-paths-semgrep">2</a></b>,</sup><sup><b><a href="#sast-excluded-paths-all-other-sast-analyzers">3</a></b></sup>
      </td>
    </tr>
    <tr>
      <td>
        모든 다른 SAST 분석기<sup><b><a href="#sast-excluded-paths-all-other-sast-analyzers">3</a></b></sup>
      </td>
    </tr>
    <tr>
      <td>
        <code>SAST_SEMGREP_EXCLUDED_PATHS</code>
      </td>
      <td>
        GitLab Advanced SAST 분석기가 동시에 실행될 때 Semgrep 분석기에만 적용되는 쉼표로 구분된 경로 목록입니다. 이는 GitLab Advanced SAST에서 이미 스캔한 파일을 제외하여 중복 취약성을 방지합니다. 이 목록은 <code>SAST_EXCLUDED_PATHS</code>와 병합됩니다.
      </td>
      <td>없음</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/semgrep">Semgrep</a>
      </td>
    </tr>
    <tr>
      <td>
        <!-- markdownlint-disable MD044 --> <code>SAST_SPOTBUGS_EXCLUDED_BUILD_PATHS</code> <!-- markdownlint-enable MD044 -->
      </td>
      <td>
        빌드 및 스캔에서 제외할 디렉터리의 쉼표로 구분된 경로 목록입니다.
      </td>
      <td>없음</td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs">SpotBugs</a><sup><b><a href="#sast-spotbugs-excluded-build-paths-description">4</a></b></sup>
      </td>
    </tr>
    <tr>
      <td rowspan="3">
        <code>SEARCH_MAX_DEPTH</code>
      </td>
      <td rowspan="3">
        분석기가 스캔할 일치하는 파일을 검색할 때 내려가는 디렉터리 수준의 개수입니다.<sup><b><a href="#search-max-depth-description">5</a></b></sup>
      </td>
      <td rowspan="2">
        <code> <a href="https://gitlab.com/gitlab-org/gitlab/-/blob/v17.3.0-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml#L54">20</a> </code>
      </td>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/semgrep">Semgrep</a>
      </td>
    </tr>
    <tr>
      <td>
        <a href="https://docs.gitlab.com/user/application_security/sast/gitlab_advanced_sast/">GitLab Advanced SAST</a>
      </td>
    </tr>
    <tr>
      <td>
        <code> <a href="https://gitlab.com/gitlab-org/gitlab/blob/v17.3.0-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml#L26">4</a> </code>
      </td>
      <td>
        모든 기타 SAST 분석기
      </td>
    </tr>
  </tbody>
</table>

**각주**:

1. <a id="sast-excluded-paths-description"></a>빌드 도구에서 사용하는 임시 디렉터리를 제외해야 할 수 있으며, 이는 거짓 긍정을 생성할 수 있습니다. 경로를 제외하려면 기본 제외 경로를 복사하여 붙여넣은 다음 제외할 고유의 경로를 **추가**합니다. 기본 제외 경로를 지정하지 않으면 기본값이 재정의되고 SAST 스캔에서 지정된 경로만 제외됩니다.
1. <a id="sast-excluded-paths-semgrep"></a>이 분석기들의 경우 `SAST_EXCLUDED_PATHS`는 **pre-filter**로 구현되며, 이는 스캔이 실행되기 전에 적용됩니다.

   분석기는 쉼표로 구분된 패턴 중 하나와 일치하는 경로를 가진 파일이나 디렉터리를 건너뜁니다.

   예를 들어, `SAST_EXCLUDED_PATHS`가 `*.py,tests`로 설정된 경우:

   - `*.py`는 다음을 무시합니다:
     - `foo.py`
     - `src/foo.py`
     - `foo.py/bar.sh`
   - `tests`는 다음을 무시합니다:
     - `tests/foo.py`
     - `a/b/tests/c/foo.py`

   각 패턴은 [gitignore](https://git-scm.com/docs/gitignore#_pattern_format)와 동일한 구문을 사용하는 글로브 스타일 패턴입니다.
1. <a id="sast-excluded-paths-all-other-sast-analyzers"></a>이 분석기들의 경우 `SAST_EXCLUDED_PATHS`는 **post-filter**로 구현되며, 이는 스캔이 실행된 후에 적용됩니다.

   패턴은 글로브(지원되는 패턴은 [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) 참조)이거나 파일 또는 폴더 경로(예: `doc,spec`)일 수 있습니다. 부모 디렉터리도 패턴과 일치합니다.

   `SAST_EXCLUDED_PATHS`의 사후 필터 구현은 모든 SAST 분석기에서 사용할 수 있습니다. [상첨자 `2`](#sast-excluded-paths-semgrep)가 있는 것과 같은 일부 SAST 분석기는 `SAST_EXCLUDED_PATHS`를 사전 필터와 사후 필터 모두로 구현합니다. 사전 필터가 더 효율적이므로 스캔할 파일 수를 줄입니다.

   `SAST_EXCLUDED_PATHS`를 사전 필터와 사후 필터 모두로 지원하는 분석기의 경우, 사전 필터가 먼저 적용된 다음 사후 필터가 남은 취약성에 적용됩니다.
1. <a id="sast-spotbugs-excluded-build-paths-description"></a> 이 변수의 경우, 경로 패턴은 글로브(지원되는 패턴은 [`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match) 참조)일 수 있습니다. 경로 패턴이 지원되는 빌드 파일과 일치하면 빌드 프로세스에서 디렉터리가 제외됩니다:

   - `build.sbt`
   - `grailsw`
   - `gradlew`
   - `build.gradle`
   - `mvnw`
   - `pom.xml`
   - `build.xml`

   예를 들어, `project/subdir/pom.xml` 경로를 가진 빌드 파일을 포함하는 `maven` 프로젝트의 구축 및 스캔을 제외하려면 `project/*/*.xml` 또는 `**/*.xml`과 같이 빌드 파일과 명시적으로 일치하는 글로브 패턴을 전달하거나 `project/subdir/pom.xml`와 같은 정확한 일치 항목을 전달합니다.

   `project` 또는 `project/subdir`과 같은 패턴에 대해 부모 디렉터리를 전달하면 디렉터리가 구축에서 제외되지 않습니다. 이 경우 빌드 파일이 패턴과 명시적으로 일치하지 않기 때문입니다.
1. <a id="search-max-depth-description"></a>[SAST CI/CD 템플릿](https://gitlab.com/gitlab-org/gitlab/blob/v17.4.1-ee/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)은 리포지토리를 검색하여 사용된 프로그래밍 언어를 감지하고 일치하는 분석기를 선택합니다. 그런 다음 각 분석기는 코드베이스를 검색하여 스캔해야 할 특정 파일 또는 디렉터리를 찾습니다. `SEARCH_MAX_DEPTH`의 값을 설정하여 분석기의 검색 단계가 탐색할 디렉터리 수준 수를 지정합니다.

#### 분석기 설정 {#analyzer-settings}

일부 분석기는 CI/CD 변수를 사용하여 사용자 지정할 수 있습니다.

| CI/CD 변수                      | 분석기             | 기본값                                  | 설명 |
|-------------------------------------|----------------------|------------------------------------------|-------------|
| `GITLAB_ADVANCED_SAST_ENABLED`      | GitLab Advanced SAST | `false`                                  | `true`로 설정하여 GitLab Advanced SAST 스캔을 활성화합니다(GitLab Ultimate에서만 사용 가능). |
| `SCAN_KUBERNETES_MANIFESTS`         | Kubesec              | `"false"`                                | `"true"`로 설정하여 Kubernetes 매니페스트를 스캔합니다. |
| `KUBESEC_HELM_CHARTS_PATH`          | Kubesec              |                                          | `helm`이 Kubernetes 매니페스트를 생성하는 데 사용하고 `kubesec`이 스캔하는 Helm 차트에 대한 선택적 경로입니다. 종속성이 정의된 경우 `helm dependency build`를 `before_script`에서 실행하여 필요한 종속성을 가져와야 합니다. |
| `KUBESEC_HELM_OPTIONS`              | Kubesec              |                                          | `helm` 실행 파일에 대한 추가 인수입니다. |
| `COMPILE`                           | SpotBugs             | `true`                                   | `false`로 설정하여 프로젝트 컴파일 및 종속성 가져오기를 비활성화합니다. |
| `ANT_HOME`                          | SpotBugs             |                                          | `ANT_HOME` 변수입니다. |
| `ANT_PATH`                          | SpotBugs             | `ant`                                    | `ant` 실행 파일의 경로입니다. |
| `GRADLE_PATH`                       | SpotBugs             | `gradle`                                 | `gradle` 실행 파일의 경로입니다. |
| `JAVA_OPTS`                         | SpotBugs             | `-XX:MaxRAMPercentage=80`                | `java` 실행 파일에 대한 추가 인수입니다. |
| `JAVA_PATH`                         | SpotBugs             | `java`                                   | `java` 실행 파일의 경로입니다. |
| `SAST_JAVA_VERSION`                 | SpotBugs             | `17`                                     | 사용되는 Java 버전입니다. 지원되는 버전은 `17` 및 `11`입니다. |
| `MAVEN_CLI_OPTS`                    | SpotBugs             | `--batch-mode -DskipTests=true`          | `mvn` 또는 `mvnw` 실행 파일에 대한 추가 인수입니다. |
| `MAVEN_PATH`                        | SpotBugs             | `mvn`                                    | `mvn` 실행 파일의 경로입니다. |
| `MAVEN_REPO_PATH`                   | SpotBugs             | `$HOME/.m2/repository`                   | Maven 로컬 리포지토리의 경로(`maven.repo.local` 속성의 바로 가기)입니다. |
| `SBT_PATH`                          | SpotBugs             | `sbt`                                    | `sbt` 실행 파일의 경로입니다. |
| `FAIL_NEVER`                        | SpotBugs             | `false`                                  | `true` 또는 `1`로 설정하여 컴파일 실패를 무시합니다. |
| `SAST_SEMGREP_METRICS`              | Semgrep              | `true`                                   | `false`로 설정하여 `r2c`로 익명화된 스캔 메트릭 전송을 비활성화합니다. |
| `SAST_SCANNER_ALLOWED_CLI_OPTS`     | Semgrep              | `--max-target-bytes=1000000 --timeout=5` | 스캔 작업을 실행할 때 기본 보안 스캐너로 전달되는 CLI 옵션(값 또는 플래그가 있는 인수)입니다. 제한된 [옵션](#security-scanner-configuration) 세트만 허용됩니다. CLI 옵션과 해당 값을 공백 또는 등호(`=`) 문자로 구분합니다. 예: `name1 value1` 또는 `name1=value1`. 여러 옵션은 공백으로 구분되어야 합니다. 예: `name1 value1 name2 value2`. |
| `SAST_RULESET_GIT_REFERENCE`        | 모두                  |                                          | 사용자 지정 규칙 집합 구성의 경로를 정의합니다. 프로젝트에 `.gitlab/sast-ruleset.toml` 파일이 커밋된 경우, 해당 로컬 구성이 우선하고 `SAST_RULESET_GIT_REFERENCE`의 파일은 사용되지 않습니다. 이 변수는 Ultimate 계층에서만 사용할 수 있습니다. |
| `SECURE_ENABLE_LOCAL_CONFIGURATION` | 모두                  | `false`                                  | 사용자 지정 규칙 집합 구성을 사용하는 옵션을 활성화합니다. `SECURE_ENABLE_LOCAL_CONFIGURATION`이 `false`로 설정되면, `.gitlab/sast-ruleset.toml`의 프로젝트 사용자 지정 규칙 집합 구성 파일이 무시되고 `SAST_RULESET_GIT_REFERENCE` 또는 기본 구성의 파일이 우선합니다. |

#### 보안 스캐너 구성 {#security-scanner-configuration}

SAST 분석기는 분석을 수행하기 위해 내부적으로 OSS 보안 스캐너를 사용합니다. GitLab은 보안 스캐너에 대한 권장 구성을 설정하므로 튜닝에 대해 걱정할 필요가 없습니다. 그러나 기본 스캐너 구성이 요구 사항에 맞지 않는 드문 경우가 있을 수 있습니다.

스캐너 동작을 일부 사용자 지정할 수 있도록 기본 스캐너에 제한된 플래그 세트를 추가할 수 있습니다. `SAST_SCANNER_ALLOWED_CLI_OPTS` CI/CD 변수에 플래그를 지정합니다. 이 플래그는 스캐너의 CLI 옵션에 추가됩니다.

<table class="sast-table">
  <thead>
    <tr>
      <th>분석기</th>
      <th>CLI 옵션</th>
      <th>설명</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td rowspan="2">
        GitLab Advanced SAST
      </td>
      <td>
        <code>--include-propagator-files</code>
      </td>
      <td>
        경고:  이 플래그로 인해 상당한 성능 저하가 발생할 수 있습니다. <br> 이 옵션을 사용하면 소스나 싱크 자체를 포함하지 않으면서 소스 및 싱크 파일을 연결하는 중간 파일의 스캔이 활성화됩니다. 작은 리포지토리의 포괄적인 분석에는 유용하지만, 대규모 리포지토리에 대해 이 기능을 활성화하면 성능에 상당한 영향을 미칩니다.
      </td>
    </tr>
    <tr>
      <td>
        <code>--multi-core</code>
      </td>
      <td>
        멀티 코어 스캔은 기본적으로 활성화되어 있으며 사용 가능한 CPU 코어를 자동으로 감지합니다(자체 호스팅 러너에서 4개로 제한됨). <code>--multi-core &lt;코어 수></code>로 재정의합니다(예: <code>--multi-core 12</code>). 멀티 코어 실행에는 비례적으로 더 많은 메모리가 필요합니다. 코어당 4GB를 할당해야 합니다. 비활성화하려면 <code>DISABLE_MULTI_CORE</code>를 설정합니다. 사용 가능한 리소스를 초과하면 성능 이슈가 발생할 수 있습니다.
      </td>
    </tr>
    <tr>
      <td rowspan="3">
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/semgrep">Semgrep</a>
      </td>
      <td>
        <code>--max-memory</code>
      </td>
      <td>
        단일 파일에서 규칙을 실행할 때 사용할 최대 시스템 메모리(MB)를 설정합니다.
      </td>
    </tr>
    <tr>
      <td>
        <code>--max-target-bytes</code>
      </td>
      <td>
        <p>
          스캔할 파일의 최대 크기입니다. 이보다 큰 입력 프로그램은 무시됩니다. <code>0</code> 또는 음수 값으로 설정하여 이 필터를 비활성화합니다. 바이트는 측정 단위의 유무에 관계없이 지정할 수 있습니다. 예:  <code>12.5kb</code>, <code>1.5MB</code> 또는 <code>123</code>. 기본값은 <code>1000000</code> 바이트입니다.
        </p>
        <p>
          <b>참고:</b> 이 플래그는 기본값으로 유지해야 합니다. 또한 축소된 JavaScript를 스캔하기 위해 이 플래그를 변경하지 마세요. 이는 제대로 작동할 가능성이 낮으며, <code>DLL</code>, <code>JAR</code> 또는 기타 바이너리 파일은 스캔되지 않습니다.
        </p>
      </td>
    </tr>
    <tr>
      <td>
        <code>--timeout</code>
      </td>
      <td>
        단일 파일에서 규칙을 실행하는 데 소요되는 최대 시간(초)입니다. 시간 제한을 없애려면 <code>0</code>으로 설정합니다. 시간 초과 값은 정수여야 합니다. 예:  <code>10</code> 또는 <code>15</code>. 기본값은 <code>5</code>입니다.
      </td>
    </tr>
    <tr>
      <td>
        <a href="https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs">SpotBugs</a>
      </td>
      <td>
        <code>-effort</code>
      </td>
      <td>
        분석 노력 수준을 설정합니다. 유효한 값은 정확도와 더 많은 취약성을 감지하는 능력의 증가 순서대로 <code>min</code>, <code>less</code>, <code>more</code> 및 <code>max</code>입니다. 기본값은 <code>max</code>이며, 프로젝트 크기에 따라 스캔을 완료하는 데 더 많은 메모리와 시간이 필요할 수 있습니다. 메모리 또는 성능 이슈가 발생하면 분석 노력 수준을 더 낮은 값으로 줄일 수 있습니다. 예: <code>-effort less</code>.
      </td>
    </tr>
  </tbody>
</table>

### 분석에서 코드 제외 {#exclude-code-from-analysis}

코드의 개별 줄 또는 블록을 표시하여 취약성 분석에서 제외할 수 있습니다. 이 개별 주석 표기 방법을 사용하기 전에 취약성 관리를 통해 모든 취약성을 관리하거나 `SAST_EXCLUDED_PATHS`를 사용하여 스캔된 파일 경로를 조정해야 합니다.

Semgrep 기반 분석기를 사용할 때 다음 옵션도 사용할 수 있습니다:

- 코드 줄 무시 - 줄의 끝에 `// nosemgrep:` 주석을 추가합니다(접두사는 개발 언어에 따라 다름).

  Java 예제:

  ```java
  vuln_func(); // nosemgrep
  ```

  Python 예제:

  ```python
  vuln_func(); # nosemgrep
  ```

- 특정 규칙에 대한 코드 줄 무시 - 줄 끝에 `// nosemgrep: RULE_ID` 주석을 추가합니다(접두사는 개발 언어에 따라 다름).
- `//nosemgrep` 주석은 감지 바로 앞 줄에 추가할 수도 있습니다. 무시 주석과 감지된 코드 사이에 다른 줄(다른 주석 포함)이 없어야 합니다.
- 파일 또는 디렉터리 무시 - 리포지토리의 루트 디렉터리 또는 프로젝트의 작업 디렉터리에 `.semgrepignore` 파일을 만들고 파일 및 폴더 패턴을 추가합니다. GitLab Semgrep 분석기는 자동으로 사용자 지정 `.semgrepignore` 파일을 [GitLab 내장 무시 패턴](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/abcea7419961320f9718a2f24fe438cc1a7f8e08/semgrepignore)과 병합합니다.

> [!note]
> Semgrep 분석기는 `.gitignore` 파일을 인식하지 않습니다. `.gitignore`에 나열된 파일은 `.semgrepignore` 또는 `SAST_EXCLUDED_PATHS`를 사용하여 명시적으로 제외되지 않는 한 분석됩니다.

자세한 내용은 [Semgrep 설명서](https://semgrep.dev/docs/ignoring-files-folders-code)를 참조하세요.

## 오프라인 환경에서 SAST 실행 {#running-sast-in-an-offline-environment}

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

인터넷을 통한 외부 리소스 액세스가 제한되거나 간헐적인 환경의 인스턴스의 경우, SAST 작업이 성공적으로 실행되도록 일부 조정이 필요합니다. 자세한 내용은 [오프라인 환경](../offline_deployments/_index.md)을(를) 참조하세요.

### 오프라인 SAST에 대한 요구 사항 {#requirements-for-offline-sast}

오프라인 환경에서 SAST를 사용하려면 다음이 필요합니다:

- [`docker`](https://docs.gitlab.com/runner/executors/docker/) 또는 [`kubernetes`](https://docs.gitlab.com/runner/install/kubernetes/) 실행기가 있는 러너입니다. 자세한 내용은 [필수 조건](#getting-started)을 참조하세요.
- SAST [분석기](https://gitlab.com/gitlab-org/security-products/analyzers) 이미지의 로컬 복사본이 있는 Docker 컨테이너 레지스트리입니다.
- 패키지 인증서 확인 구성(선택 사항).

러너는 [`pull_policy`의 기본값이 `always`](https://docs.gitlab.com/runner/executors/docker/#using-the-always-pull-policy)이며, 이는 로컬 복본이 있더라도 러너가 GitLab 컨테이너 레지스트리에서 Docker 이미지를 가져오려고 시도함을 의미합니다. 로컬에서 사용 가능한 Docker 이미지만 사용하는 것을 선호하는 경우, 오프라인 환경에서 러너 [`pull_policy`를 `if-not-present`](https://docs.gitlab.com/runner/executors/docker/#using-the-if-not-present-pull-policy)로 설정할 수 있습니다. 그러나 오프라인 환경이 아닌 경우 pull 정책 설정을 `always`로 유지합니다. 이 설정을 사용하면 CI/CD 파이프라인에서 업데이트된 스캐너를 사용할 수 있습니다.

### Docker 레지스트리 내에서 GitLab SAST 분석기 이미지 사용 가능하게 만들기 {#make-gitlab-sast-analyzer-images-available-inside-your-docker-registry}

지원되는 모든 언어 및 프레임워크에 대한 SAST를 위해, `registry.gitlab.com`에서 다음 기본 SAST 분석기 이미지를 [로컬 Docker 컨테이너 레지스트리](../../packages/container_registry/_index.md)로 가져옵니다:

```plaintext
registry.gitlab.com/security-products/gitlab-advanced-sast:2
registry.gitlab.com/security-products/kubesec:6
registry.gitlab.com/security-products/pmd-apex:6
registry.gitlab.com/security-products/semgrep:6
registry.gitlab.com/security-products/sobelow:6
registry.gitlab.com/security-products/spotbugs:5
```

로컬 오프라인 Docker 레지스트리로 Docker 이미지를 가져오는 프로세스는 **네트워크 보안 정책**에 따라 다릅니다. IT 직원에게 외부 리소스를 가져오거나 일시적으로 액세스할 수 있는 승인된 프로세스를 확인하도록 요청하세요. 이 스캐너는 [정기적으로 업데이트되며](../detect/vulnerability_scanner_maintenance.md), 새로운 정의가 나오면 자체적으로 가끔 업데이트할 수 있습니다.

Docker 이미지를 파일로 저장하고 전송하는 방법에 대한 자세한 내용은 다음 Docker 문서를 참조하세요:

- `docker save`
- `docker load`
- `docker export`
- `docker import`

### 로컬 SAST 분석기 사용 {#use-local-sast-analyzers}

전제 조건:

- 프로젝트에 대한 Developer, Maintainer 또는 Owner 역할.

로컬 SAST 분석기를 사용하려면:

- 프로젝트의 `.gitlab-ci.yml` 파일에서 CI/CD 변수 `SECURE_ANALYZERS_PREFIX`를 정의하여 로컬 Docker 컨테이너 레지스트리를 참조합니다.

예를 들어:

```yaml
variables:
  SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
```

이제 SAST 작업은 인터넷 액세스 없이 로컬 SAST 분석기 복사본을 사용하여 코드를 스캔하고 보안 보고서를 생성합니다.

### 패키지 인증서 확인 구성 {#configure-certificate-checking-of-packages}

SAST 작업이 패키지 관리자를 호출하는 경우, 해당 인증서 확인을 구성해야 합니다. 오프라인 환경에서는 외부 소스로의 인증서 확인이 불가능합니다. 자체 서명된 인증서를 사용하거나 인증서 확인을 비활성화합니다. 지침은 패키지 관리자의 설명서를 참조하세요.

## SELinux에서 SAST 실행 {#running-sast-in-selinux}

기본적으로 SAST 분석기는 SELinux에서 호스팅되는 GitLab 인스턴스에서 지원됩니다. SELinux에서 호스팅되는 러너는 권한이 제한되어 있으므로 `before_script`를 [재정의된 SAST 작업](#override-sast-jobs)에 추가하면 작동하지 않을 수 있습니다.
