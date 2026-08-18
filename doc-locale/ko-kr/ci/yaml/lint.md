---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab CI Lint 도구를 사용하여 CI/CD 구성을 검증하고 파이프라인을 시뮬레이션하여 작업이 실행되기 전에 오류를 찾습니다.
title: GitLab CI/CD 구성 검증
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI Lint 도구를 사용하여 GitLab CI/CD 구성의 유효성을 확인합니다. `.gitlab-ci.yml` 파일 또는 다른 CI/CD 구성 샘플에서 구문을 검증할 수 있습니다. 이 도구는 구문 및 논리 오류를 확인하고 파이프라인 생성을 시뮬레이션하여 더 복잡한 구성 문제를 찾을 수 있습니다.

[파이프라인 편집기](../pipeline_editor/_index.md)를 사용하면 구성 구문이 자동으로 검증됩니다.

또는 다음을 사용하여 CI/CD 구성을 검증할 수 있습니다:

- [VS Code용 GitLab 확장](../../editor_extensions/visual_studio_code/_index.md)
- [GitLab CLI (`glab`)](https://docs.gitlab.com/cli/ci/lint/)
- [CI Lint API 엔드포인트](../../api/lint.md)

## CI/CD 구문 확인 {#check-cicd-syntax}

CI Lint 도구는 [`includes` 키워드](_index.md#include)로 추가된 구성을 포함하여 GitLab CI/CD 구성의 구문을 확인합니다.

CI Lint 도구로 CI/CD 구성을 확인하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인 편집기**를 선택합니다.
1. **검증** 탭을 선택합니다.
1. **Lint CI/CD sample**을 선택합니다.
1. 확인하려는 CI/CD 구성의 사본을 텍스트 상자에 붙여넣습니다.
1. **검증**을 선택합니다.

## 파이프라인 시뮬레이션 {#simulate-a-pipeline}

GitLab CI/CD 파이프라인 생성을 시뮬레이션하여 [`needs`](_index.md#needs) 및 [`rules`](_index.md#rules) 구성의 문제를 포함한 더 복잡한 문제를 찾을 수 있습니다. 시뮬레이션은 기본 브랜치에서 Git `push` 이벤트로 실행됩니다.

전제 조건:

- 시뮬레이션으로 검증하기 위해 이 브랜치에서 파이프라인을 생성할 수 있는 [권한](../../user/permissions.md#project-permissions)이 필요합니다.

파이프라인을 시뮬레이션하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **빌드** > **파이프라인 편집기**를 선택합니다.
1. **검증** 탭을 선택합니다.
1. **Lint CI/CD sample**을 선택합니다.
1. 확인하려는 CI/CD 구성의 사본을 텍스트 상자에 붙여넣습니다.
1. **Simulate pipeline creation for the default branch**을 선택합니다.
1. **검증**을 선택합니다.
