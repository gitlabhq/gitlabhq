---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 파이프라인 편집기
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

파이프라인 편집기는 리포지토리의 루트에 있는 `.gitlab-ci.yml` 파일에서 GitLab CI/CD 구성을 편집하는 주요 위치입니다. 편집기에 액세스하려면 **빌드** > **파이프라인 편집기**로 이동합니다.

파이프라인 편집기 페이지에서 다음을 수행할 수 있습니다:

- 작업할 브랜치를 선택합니다.
- 파일을 편집하는 동안 구성 구문을 [검증](#validate-cicd-syntax)합니다.
- 구성을 [더 깊이 검증](#validate-cicd-configuration)하여 [`include`](../yaml/_index.md#include) 키워드로 추가된 구성과 검증합니다.
- [`include` 키워드로 추가된 CI/CD 구성의 목록](#view-included-cicd-configuration)을 봅니다.
- 현재 구성의 [시각화](#visualize-ci-configuration)를 봅니다.
- [전체 구성](#view-full-configuration)을 보고 `include`에서 추가된 모든 구성을 표시합니다.
- 변경 사항을 특정 [브랜치에 커밋](#commit-changes-to-ci-configuration)합니다.

## CI/CD 구문 검증 {#validate-cicd-syntax}

파이프라인 편집기를 사용하면 파이프라인 구성 구문이 GitLab CI/CD 파이프라인 스키마에 대해 지속적으로 검증됩니다. CI/CD YAML 구문과 몇 가지 기본 논리 검증이 확인됩니다.

이 검증의 결과는 편집기 페이지의 맨 위에 표시됩니다. 검증이 실패하면 이 섹션에는 문제를 해결하는 데 도움이 되는 팁이 표시됩니다.

## CI/CD 구성 검증 {#validate-cicd-configuration}

{{< history >}}

- 다른 [브랜치를 선택하는 옵션이 GitLab 18.4에 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/482676)되었습니다.

{{< /history >}}

변경 사항을 커밋하기 전에 GitLab CI/CD 구성의 유효성을 테스트하려면 파이프라인 편집기 검증 도구를 사용합니다. 이 도구는 Git 푸시 이벤트로 인한 파이프라인 생성을 시뮬레이션하고 `rules` 및 `needs` 작업 종속성을 포함한 논리 이슈를 해결하는 데 도움이 될 수 있습니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인 편집기**를 선택합니다.
1. **검증** 탭을 선택합니다.
1. 선택 사항. **파이프라인 실행 소스** 드롭다운 목록을 사용하여 시뮬레이션된 푸시 이벤트에 사용할 다른 브랜치를 선택합니다.
1. **파이프라인 유효성 검증**을 선택합니다.

시뮬레이션된 파이프라인은 **편집** 탭의 기존 파이프라인 구성을 사용합니다.

**편집** 탭에 추가하지 않고 CI/CD YAML 스니펫을 검증하려면 대신 [CI Lint 도구](../yaml/lint.md#simulate-a-pipeline)를 사용합니다.

## 포함된 CI/CD 구성 보기 {#view-included-cicd-configuration}

{{< history >}}

- GitLab 15.0에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/7064)되었으며 `pipeline_editor_file_tree`이라는 [플래그 사용](../../administration/feature_flags/_index.md)입니다. 기본적으로 비활성화되어 있습니다.
- GitLab 15.1에서 [기능 플래그가 제거](https://gitlab.com/gitlab-org/gitlab/-/issues/357219)되었습니다.

{{< /history >}}

파이프라인 편집기에서 [`include`](../yaml/_index.md#include) 키워드로 추가된 구성을 검토할 수 있습니다. 오른쪽 위 모서리에서 파일 트리({{< icon name="file-tree" >}})를 선택하여 포함된 모든 구성 파일의 목록을 봅니다. 선택된 파일은 검토를 위해 새 탭에서 열립니다.

## CI 구성 시각화 {#visualize-ci-configuration}

`.gitlab-ci.yml` 구성을 시각화하려면 프로젝트에서 **빌드** > **파이프라인 편집기**로 이동한 후 **시각화** 탭을 선택합니다. 시각화는 모든 스테이지와 작업을 표시합니다. 모든 [`needs`](../yaml/_index.md#needs) 관계는 작업을 함께 연결하는 선으로 표시되어 실행의 계층 구조를 보여줍니다.

작업을 마우스로 가리켜 `needs` 관계를 강조합니다:

![마우스 오버 시 CI/CD 구성 시각화](img/ci_config_visualization_hover_v17_9.png)

구성에 `needs` 관계가 없으면 각 작업이 이전 스테이지가 성공적으로 완료된 경우에만 의존하므로 선이 그려지지 않습니다.

## 전체 구성 보기 {#view-full-configuration}

{{< history >}}

- **View merged YAML** 탭이 GitLab 16.0에서 [**전체 구성**으로 이름 변경](https://gitlab.com/gitlab-org/gitlab/-/issues/377404)되었습니다.

{{< /history >}}

완전히 확장된 CI/CD 구성을 하나의 파일로 보려면 파이프라인 편집기의 **전체 구성** 탭으로 이동합니다. 이 탭은 다음과 같은 확장 구성을 표시합니다:

- [`include`](../yaml/_index.md#include)로 가져온 구성이 뷰로 복사됩니다.
- [`extends`](../yaml/_index.md#extends)를 사용하는 작업은 [작업에 병합된 확장 구성](../yaml/yaml_optimization.md#merge-details)을 표시합니다.
- [YAML 앵커](../yaml/yaml_optimization.md#anchors)는 연결된 구성으로 교체됩니다.
- [YAML `!reference` 태그](../yaml/yaml_optimization.md#reference-tags)도 연결된 구성으로 교체됩니다.
- 조건부 규칙은 기본 브랜치 푸시 이벤트를 가정하여 평가됩니다.

`!reference` 태그를 사용하면 확장된 뷰의 줄 시작 부분에 여러 하이픈(`-`)으로 표시되는 중첩 구성이 발생할 수 있습니다. 이 동작은 예상된 것이며 추가 하이픈은 작업의 실행에 영향을 주지 않습니다. 예를 들어 이 구성과 완전히 확장된 버전은 모두 유효합니다:

- `.gitlab-ci.yml` 파일:

  ```yaml
  .python-req:
    script:
      - pip install pyflakes

  .rule-01:
    rules:
      - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/
        when: manual
        allow_failure: true
      - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME

  .rule-02:
    rules:
      - if: $CI_COMMIT_BRANCH == "main"
        when: manual
        allow_failure: true

  lint-python:
    image: python:latest
    script:
      - !reference [.python-req, script]
      - pyflakes python/
    rules:
      - !reference [.rule-01, rules]
      - !reference [.rule-02, rules]
  ```

- **전체 구성** 탭의 확장 구성:

  ```yaml
  ".python-req":
    script:
    - pip install pyflakes
  ".rule-01":
    rules:
    - if: "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/"
      when: manual
      allow_failure: true
    - if: "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"
  ".rule-02":
    rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
      allow_failure: true
  lint-python:
    image: python:latest
    script:
    - - pip install pyflakes                                     # <- The extra hyphens do not affect the job's execution.
    - pyflakes python/
    rules:
    - - if: "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/" # <- The extra hyphens do not affect the job's execution.
        when: manual
        allow_failure: true
      - if: "$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME"               # <- No extra hyphen but aligned with previous rule
    - - if: $CI_COMMIT_BRANCH == "main"                          # <- The extra hyphens do not affect the job's execution.
        when: manual
        allow_failure: true
  ```

## CI 구성에 변경 사항 커밋 {#commit-changes-to-ci-configuration}

커밋 양식은 편집기의 각 탭 하단에 표시되므로 언제든지 변경 사항을 커밋할 수 있습니다.

변경 사항이 만족스러우면 설명적인 커밋 메시지를 추가하고 브랜치를 입력합니다. 브랜치 필드의 기본값은 프로젝트의 기본 브랜치입니다.

새 브랜치 이름을 입력하면 **Start a new merge request with these changes** 확인란이 나타납니다. 이를 선택하여 변경 사항을 커밋한 후 새 머지 리퀘스트를 시작합니다.

![커밋 메시지, 브랜치 및 머지 리퀘스트 확인란을 보여주는 커밋 양식입니다.](img/pipeline_editor_commit_v18_8.png)

## 편집기 접근성 옵션 {#editor-accessibility-options}

파이프라인 편집기는 [Monaco Editor](https://github.com/microsoft/monaco-editor)를 기반으로 하며 다음을 포함한 여러 [접근성 기능](https://github.com/microsoft/monaco-editor/wiki/Monaco-Editor-Accessibility-Guide)이 있습니다:

| 기능                          | Windows 또는 Linux의 단축키      | macOS의 단축키                                    | 세부 정보 |
|----------------------------------|-----------------------------------|------------------------------------------------------|---------|
| 키보드 탐색 명령 목록 | <kbd>F1</kbd>                     | <kbd>F1</kbd>                                        | 마우스 없이 편집기를 더 쉽게 사용할 수 있게 해주는 [명령 목록](https://github.com/microsoft/monaco-editor/wiki/Monaco-Editor-Accessibility-Guide#keyboard-navigation)입니다. |
| 탭 트래핑                     | <kbd>Control</kbd>+<kbd>m</kbd> | <kbd>Control</kbd>+<kbd>Shift</kbd>+<kbd>m</kbd> | 탭 문자를 삽입하는 대신 페이지의 다음 포커스 가능한 요소로 이동하려면 [탭 트래핑](https://github.com/microsoft/monaco-editor/wiki/Monaco-Editor-Accessibility-Guide#tab-trapping)을 활성화합니다. |

## 문제 해결 {#troubleshooting}

### `Unable to validate CI/CD configuration.` 메시지 {#unable-to-validate-cicd-configuration-message}

이 메시지는 파이프라인 편집기에서 구문을 검증하는 문제로 인해 발생합니다. GitLab이 구문을 검증하는 서비스와 통신할 수 없을 때 발생할 수 있습니다.

다음 섹션의 정보가 제대로 표시되지 않을 수 있습니다:

- **편집** 탭의 구문 상태(유효 또는 무효)입니다.
- **시각화** 탭입니다.
- **Lint** 탭입니다.
- **전체 구성** 탭입니다.

CI/CD 구성을 계속 작업하고 이슈 없이 변경 사항을 커밋할 수 있습니다. 서비스를 다시 사용할 수 있으면 구문 검증이 즉시 표시되어야 합니다.
