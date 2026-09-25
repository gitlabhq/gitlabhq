---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo에서 액세스할 수 있는 정보와 코드 검토 컨텍스트에서 민감한 콘텐츠를 제외하는 방법을 알아봅니다.
title: GitLab Duo 컨텍스트 인식
---

GitLab Duo가 의사결정을 내리고 제안을 제공하는 데 도움이 되는 다양한 정보를 사용할 수 있습니다.

정보는 다음과 같이 사용할 수 있습니다:

- 항상.
- 현재 위치 기반(탐색할 때 컨텍스트가 변경됨).
- 명시적으로 참조될 때. 예를 들어 URL, ID 또는 파일 경로로 정보를 언급합니다.

## 항상 사용 가능 {#always-available}

- GitLab 설명서.
- 일반적인 프로그래밍 지식, 모범 사례 및 언어 특성.
- 보고 있거나 편집 중인 파일의 콘텐츠(커서 앞뒤의 코드 포함).
- GitLab UI에서 Chat을 사용할 때 현재 페이지 제목과 URL.
- `/refactor`, `/fix`, `/tests`, `/explain` 슬래시 명령어는 Code Suggestions의 최신 Repository X-Ray 보고서에 액세스할 수 있습니다.

## 위치 기반 {#based-on-location}

이러한 리소스 중 하나라도 열려 있으면 GitLab Duo는 이를 인식합니다.

- 다음 방법 중 하나로 Chat에 알린 파일:
  - 직접 파일 경로 제공.
  - IDE에서 `/include` 명령어를 포함하여.
- 파일에서 선택한 코드.
- 이슈(GitLab Duo Enterprise만 해당).
- 에픽(GitLab Duo Enterprise만 해당).
- [기타 작업 항목 유형](../work_items/_index.md#work-item-types)(GitLab Duo Enterprise만 해당).

> [!note]
> IDE에서는 알려진 형식과 일치하는 비밀 및 민감한 값이 GitLab Duo Chat으로 전송되기 전에 수정됩니다.

UI에서 머지 리퀘스트를 사용 중인 경우 GitLab Duo는 다음에 대해서도 인식합니다:

- 머지 리퀘스트 자체(GitLab Duo Enterprise만 해당).
- 머지 리퀘스트의 커밋(GitLab Duo Enterprise만 해당).
- 머지 리퀘스트 파이프라인의 CI/CD 작업(GitLab Duo Enterprise만 해당).

### 명시적으로 참조될 때 {#when-referenced-explicitly}

현재 위치 기반으로 사용할 수 있는 모든 리소스는 ID 또는 URL로 명시적으로 참조할 때도 사용할 수 있습니다.

## 코드 검토에서 컨텍스트 제외 {#exclude-context-from-code-review}

{{< details >}}

- 티어:  Premium, Ultimate
- 추가 기능: GitLab Duo Pro 또는 Enterprise

{{< /details >}} {{< history >}}

- `use_duo_context_exclusion`라는 이름의 [기능 플래그](../../administration/feature_flags/_index.md)로 GitLab 18.2에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/17124)되었습니다. 기본적으로 사용 중지됩니다.
- GitLab 18.4에서 베타로 변경되었습니다.
- GitLab 18.5에서 기본적으로 활성화됩니다.

{{< /history >}}

코드 검토에서 컨텍스트로 사용되는 프로젝트 콘텐츠를 제외할 수 있습니다. 컨텍스트를 제외하여 암호 및 구성 파일과 같은 민감한 정보를 보호합니다.

코드 검토에서 제외하는 콘텐츠를 지정하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **GitLab Duo** 아래의 **GitLab Duo 컨텍스트 제외항목** 섹션에서 **제외 관리**를 선택합니다.
1. GitLab Duo 컨텍스트에서 제외할 프로젝트 파일 및 디렉터리를 지정하고 **제외 저장**을 선택합니다.
1. 선택 사항입니다. 기존 제외항목을 삭제하려면 해당 제외항목에 대해 **삭제**({{< icon name="remove" >}})를 선택합니다.
1. **변경 사항 저장**을 선택합니다.
