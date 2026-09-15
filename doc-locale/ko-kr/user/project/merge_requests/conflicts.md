---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 병합 충돌에 대해 이해하고 Git 프로젝트에서 해결하는 방법을 알아봅니다.
title: 병합 충돌
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

병합 충돌은 병합 요청의 두 브랜치(소스 브랜치와 대상 브랜치)가 같은 코드 라인에 서로 다른 변경 사항을 가질 때 발생합니다. 대부분의 경우 GitLab이 변경 사항을 함께 병합할 수 있지만, 충돌이 발생하면 어떤 변경 사항을 유지할지 결정해야 합니다.

![병합 충돌로 인해 차단된 병합 요청](img/conflicts_v16_7.png)

충돌이 있는 병합 요청을 해결하려면 다음 중 하나를 수행해야 합니다.

- 병합 커밋을 만듭니다.
- 리베이스를 통해 충돌을 해결합니다.

GitLab은 소스 브랜치에 병합 커밋을 만들어서 충돌을 해결하되, 대상 브랜치에는 병합하지 않습니다. 그런 다음 병합 커밋을 검토하고 테스트하여, 의도하지 않은 변경 사항이 포함되지 않았으며 빌드를 손상시키지 않는지 확인할 수 있습니다.

## 충돌 블록 이해 {#understand-conflict-blocks}

Git에서 사용자의 결정이 필요한 충돌을 탐지하면 충돌 블록의 시작과 끝을 충돌 표시기로 표시합니다.

- `<<<<<<< HEAD`는 충돌 블록의 시작을 표시합니다.
- 사용자의 변경 사항이 표시됩니다.
- `=======`는 사용자 변경 사항의 끝을 표시합니다.
- 대상 브랜치의 최신 변경 사항이 표시됩니다.
- `>>>>>>>`은 충돌의 끝을 표시합니다.

충돌을 해결하려면 다음을 삭제합니다.

1. 유지하지 않으려는 충돌 라인의 버전입니다.
1. 3개의 충돌 표시기(시작, 끝 및 두 버전 사이의 `=======` 라인).

## 사용자 인터페이스에서 해결할 수 있는 충돌 {#conflicts-you-can-resolve-in-the-user-interface}

충돌하는 파일이 다음 조건에 해당하는 경우 GitLab UI에서 병합 충돌을 해결할 수 있습니다.

- 바이너리가 아닌 텍스트 파일입니다.
- 충돌 표시기를 추가한 크기가 200KB 미만입니다.
- UTF-8 호환 인코딩을 사용합니다.
- 충돌 표시기를 포함하지 않습니다.
- 두 브랜치 모두 동일한 경로에 있습니다.

파일이 이러한 기준을 충족하지 않으면 충돌을 수동으로 해결해야 합니다.

## 충돌 해결 방법 {#conflict-resolution-methods}

GitLab은 사용자 인터페이스에 [해결 가능한 충돌](#conflicts-you-can-resolve-in-the-user-interface)을 표시하며, 다음 방법을 사용하여 충돌을 해결할 수도 있습니다.

- GitLab Duo:  자동화된 엔드투엔드 충돌 해결에 가장 적합합니다.
- 대화형 모드:  유지할 라인의 버전을 선택하기만 하면 되는 충돌에 가장 적합합니다.
- 인라인 편집기:  변경 사항을 조합하기 위해 수동 편집이 필요한 복잡한 충돌에 적합합니다.
- 명령줄:  복잡한 충돌에 대한 완전한 제어 권한을 제공합니다. 자세한 내용은 [명령줄에서 충돌 해결](../../../topics/git/git_rebase.md#resolve-conflicts-from-the-command-line)을 참조하세요.

### GitLab Duo로 충돌 해결 {#resolve-conflicts-with-gitlab-duo}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `mr_ai_resolve_conflicts`라는 이름의 [기능 플래그](../../../administration/feature_flags/_index.md)로 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235919)되었습니다. 기본적으로 사용으로 설정되어 있습니다.
- GitLab 19.3에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/work_items/596465)되었습니다.
- GitLab 19.4에서 기능 플래그 `mr_ai_resolve_conflicts`가  [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251062/)되었습니다.

{{< /history >}}

GitLab Duo는 병합 충돌을 자동으로 분석하고 충돌하는 파일을 편집하여 커밋을 만들고 소스 브랜치로 푸시할 수 있습니다.

사전 요구 사항:

- 개발자, 유지 관리자 또는 소유자 역할이 있어야 합니다.
- 소스 브랜치에 대한 푸시 액세스 권한이 있어야 합니다.
- [GitLab Duo Agent Platform 사전 요구 사항](../../duo_agent_platform/_index.md#prerequisites)을 충족해야 합니다.
- [사용자 인터페이스에서 해결할 수 있는](#conflicts-you-can-resolve-in-the-user-interface) 충돌이 포함된 병합 요청입니다.

GitLab Duo로 충돌을 해결하려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모드** > **병합 요청**을 선택하고 병합 요청을 찾습니다.
1. **개요**를 선택합니다.
1. 병합 충돌 세부 정보를 확인하고 GitLab Duo에 충돌을 해결하도록 명령합니다.
   - 병합 요청 보고서 섹션에서 **충돌 해결**을 선택한 다음 **GitLab Duo로 해결**을 선택합니다.
   - 병합 위젯에서 충돌 확인 행을 찾고 **GitLab Duo으로 해결**을 선택합니다.

GitLab Duo는 충돌을 분석하고 해결하며 변경 사항을 커밋하고 소스 브랜치로 푸시합니다. 완료되면 GitLab Duo에 병합 요청에 요약 댓글을 게시합니다.

GitLab Duo는 브랜치 보호 규칙을 준수하며 보호된 브랜치에 강제 푸시하지 않습니다.

### 대화형 모드 {#interactive-mode}

대화형 모드는 사용자가 선택한 변경 사항을 적용하여 대상 브랜치를 소스 브랜치에 병합합니다.

대화형 모드로 병합 충돌을 해결하려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모드** > **병합 요청**을 선택하고 병합 요청을 찾습니다.
1. **개요**를 선택한 다음 병합 요청 보고서 섹션으로 스크롤합니다.
1. 병합 충돌 메시지를 찾고 **충돌 해결**을 선택합니다. GitLab에서 병합 충돌이 있는 파일 목록을 표시합니다. 충돌하는 라인이 강조 표시됩니다.

1. 각 충돌에 대해 **우리 버전 사용** 또는 **상대 버전 사용**을 선택하여 유지할 충돌 라인의 버전을 지정합니다. 이 결정을 ‘충돌 해결’이라고 합니다.
1. 모든 충돌을 해결했으면 **커밋 메시지**를 입력합니다.
1. **소스 브랜치에 커밋**을 선택합니다.

### 인라인 편집기 {#inline-editor}

일부 병합 충돌은 더 복잡하므로 라인을 수동으로 편집하여 해결해야 합니다.

병합 충돌 해결 편집기는 GitLab에서 이러한 충돌을 해결하는 데 도움이 됩니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모드** > **병합 요청**을 선택하고 병합 요청을 찾습니다.
1. **개요**를 선택한 다음 병합 요청 보고서 섹션으로 스크롤합니다.
1. 병합 충돌 메시지를 찾고 **충돌 해결**을 선택합니다. GitLab에서 병합 충돌이 있는 파일 목록을 표시합니다.
1. 수동으로 편집할 파일을 찾고 충돌 블록으로 스크롤합니다.
1. 해당 파일의 헤더에서 **인라인 편집**을 선택하여 편집기를 엽니다. 이 예제에서 충돌 블록은 라인 1350에서 시작하여 라인 1356에서 끝납니다.

   ![병합 충돌 편집기](img/merge_conflict_editor_v16_7.png)

1. 충돌을 해결한 후 **커밋 메시지**를 입력합니다.
1. **소스 브랜치에 커밋**을 선택합니다.

## 리베이스 {#rebase}

병합 요청이 `Checking ability to merge automatically` 메시지에서 멈춰 있다면 다음을 수행할 수 있습니다.

- 병합 요청의 댓글에서 [`/rebase` 빠른 작업](../quick_actions.md#rebase)을 실행합니다.
- 병합 위젯에서 **소스 브랜치 리베이스**를 선택합니다.
- [Git으로 리베이스](../../../topics/git/git_rebase.md#rebase)합니다.

CI/CD 파이프라인 이슈를 해결하려면 [CI/CD 파이프라인 디버깅](../../../ci/debugging.md)을 참조하세요.

반선형 또는 빠른 전달 병합 방법을 사용하는 프로젝트의 경우, [병합 전 자동 리베이스](methods/_index.md#automatic-rebase-before-merge)를 활성화하여 수동 리베이스 단계를 건너뛸 수도 있습니다.

### GitLab UI에서 리베이스 {#rebase-in-the-gitlab-ui}

GitLab UI에서 리베이스를 트리거하려면 [`/rebase` 빠른 작업](../quick_actions.md#rebase)을 사용하거나 병합 요청 위젯의 리베이스 옵션을 사용합니다.

사전 요구 사항:

- 병합 충돌이 없어야 합니다.
- 소스 프로젝트에 대해 최소한 [개발자 역할](../../permissions.md)이 있어야 합니다.
- 병합 요청이 포크에 있는 경우, 포크는 [업스트림 프로젝트 구성원](allow_collaboration.md)의 커밋을 허용해야 합니다.

GitLab UI에서 병합 요청의 브랜치를 리베이스하려면 다음을 수행합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **모드** > **병합 요청**을 선택하고 병합 요청을 찾습니다.
1. 다음 중 하나를 수행합니다.
   - **개요** 탭에서 병합 요청 위젯으로 스크롤한 다음 **소스 브랜치 리베이스**를 선택합니다.
   - 댓글에 `/rebase`를 입력하고 **커밋**을 선택합니다.

GitLab은 기본 브랜치에 대해 해당 브랜치의 리베이스를 예약한 다음 실행합니다. GitLab은 완료된 리베이스를 시스템 노트로 표시합니다.

> [!note]
> GitLab UI를 통해 생성된 커밋에 대해 커밋 서명을 설정한 경우, [UI를 통해 리베이스될 때](../repository/signed_commits/web_commits.md#web-commits-become-unsigned-after-rebase) 웹 커밋은 커밋 서명을 잃게 됩니다.

## 관련 항목 {#related-topics}

- [리베이스 및 충돌 해결](../../../topics/git/git_rebase.md)
- [Git 리베이스 및 강제 푸시 소개](../../../topics/git/git_rebase.md)
- [Git 워크플로우를 시각화하기 위한 Git 애플리케이션](https://git-scm.com/downloads/guis)
- [`git rerere`로 자동 충돌 해결](https://git-scm.com/book/en/v2/Git-Tools-Rerere)
