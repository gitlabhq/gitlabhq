---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 머지 충돌을 이해하고 Git 프로젝트에서 이를 해결하는 방법을 알아봅니다.
title: 머지 충돌
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

머지 충돌은 머지 리퀘스트의 두 브랜치(소스 브랜치와 대상 브랜치)가 같은 코드 라인에 다른 변경 사항이 있을 때 발생합니다. 대부분의 경우 GitLab이 변경 사항을 함께 병합할 수 있지만, 충돌이 발생하면 어떤 변경 사항을 유지할지 결정해야 합니다.

![머지 충돌로 인해 차단된 머지 리퀘스트](img/conflicts_v16_7.png)

머지 충돌이 있는 머지 리퀘스트를 해결하려면 다음 중 하나를 수행해야 합니다:

- 머지 커밋을 생성합니다.
- 커밋 리베이스를 통해 충돌을 해결합니다.

GitLab은 소스 브랜치에 머지 커밋을 생성하여 충돌을 해결하되 대상 브랜치에는 병합하지 않습니다. 그 후 머지 커밋을 검토하고 테스트하여 의도하지 않은 변경 사항이 포함되지 않았고 빌드를 손상시키지 않는지 확인할 수 있습니다.

## 충돌 블록 이해 {#understand-conflict-blocks}

Git가 결정이 필요한 충돌을 감지하면 충돌 블록의 시작과 끝을 충돌 표시기로 표시합니다:

- `<<<<<<< HEAD` 충돌 블록의 시작을 표시합니다.
- 변경 사항이 표시됩니다.
- `=======` 변경 사항의 끝을 표시합니다.
- 대상 브랜치의 최신 변경 사항이 표시됩니다.
- `>>>>>>>` 충돌의 끝을 표시합니다.

충돌을 해결하려면 다음을 삭제하세요:

1. 유지하지 않을 충돌하는 라인의 버전입니다.
1. 세 가지 충돌 표시기: 시작, 끝, 그리고 두 버전 사이의 `=======` 라인입니다.

## 사용자 인터페이스에서 해결할 수 있는 충돌 {#conflicts-you-can-resolve-in-the-user-interface}

충돌하는 파일이 다음 조건을 만족하면 GitLab UI에서 머지 충돌을 해결할 수 있습니다:

- 바이너리가 아닌 텍스트 파일입니다.
- 충돌 표시기가 추가되어 크기가 200KB 미만입니다.
- UTF-8 호환 인코딩을 사용합니다.
- 충돌 표시기를 포함하지 않습니다.
- 두 브랜치 모두에서 같은 경로에 있습니다.

파일이 이러한 조건을 충족하지 않으면 충돌을 수동으로 해결해야 합니다.

## 충돌 해결 방법 {#conflict-resolution-methods}

GitLab은 사용자 인터페이스에서 [해결 가능한 충돌](#conflicts-you-can-resolve-in-the-user-interface)을 표시하며, 다음 방법으로도 충돌을 해결할 수 있습니다:

- GitLab Duo:  자동 엔드투엔드 충돌 해결에 최적입니다.
- 대화형 모드:  라인의 버전을 선택하기만 하면 되는 충돌에 최적입니다.
- 인라인 편집기:  변경 사항을 혼합하기 위해 수동 편집이 필요한 복잡한 충돌에 적합합니다.
- 명령줄:  복잡한 충돌을 완전히 제어할 수 있습니다. 자세한 내용은 [명령줄에서 충돌 해결](../../../topics/git/git_rebase.md#resolve-conflicts-from-the-command-line)을 참조하세요.

### GitLab Duo로 충돌 해결 {#resolve-conflicts-with-gitlab-duo}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/235919) 되었으며 [기능 플래그](../../../administration/feature_flags/_index.md) `mr_ai_resolve_conflicts`로 명명되었습니다. 기본적으로 활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그에 의해 제어됩니다. 자세한 내용은 기록을 참조하세요.

GitLab Duo는 머지 충돌을 자동으로 분석하고, 충돌하는 파일을 편집하고, 커밋을 생성하고, 소스 브랜치로 푸시할 수 있습니다.

전제 조건:

- Developer, Maintainer 또는 Owner 역할입니다.
- 소스 브랜치에 대한 푸시 액세스입니다.
- [GitLab Duo Agent Platform 필수 조건](../../duo_agent_platform/_index.md#prerequisites)입니다.
- [베타 및 실험용 기능](../../duo_agent_platform/turn_on_off.md#turn-on-beta-and-experimental-features)이 켜져 있습니다.
- 사용자 인터페이스에서 [해결할 수 있는](#conflicts-you-can-resolve-in-the-user-interface) 충돌이 있는 머지 리퀘스트입니다.

GitLab Duo로 충돌을 해결하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. **개요**를 선택합니다.
1. 머지 충돌 세부 사항을 찾고 GitLab Duo에 충돌 해결을 지시합니다:
   - 머지 리퀘스트 보고서 섹션에서 **충돌 해결**을 선택한 다음 **Resolve with GitLab Duo**을 선택합니다.
   - 머지 리퀘스트 위젯에서 충돌 확인 행을 찾고 **Resolve with GitLab Duo**을 선택합니다.

GitLab Duo는 충돌을 분석하고 해결하며, 변경 사항을 커밋하고 소스 브랜치로 푸시합니다. 완료되면 GitLab Duo는 머지 리퀘스트에 요약 댓글을 게시합니다.

GitLab Duo는 브랜치 보호 규칙을 준수하며 보호된 브랜치로 강제 푸시하지 않습니다.

### 대화형 모드 {#interactive-mode}

대화형 모드는 대상 브랜치를 소스 브랜치로 병합하고 선택한 변경 사항을 적용합니다.

대화형 모드로 머지 충돌을 해결하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. **개요**를 선택한 다음 머지 리퀘스트 보고서 섹션으로 스크롤합니다.
1. 머지 충돌 메시지를 찾고 **충돌 해결**을 선택합니다. GitLab은 머지 충돌이 있는 파일 목록을 표시합니다. 충돌하는 라인이 강조 표시됩니다.

1. 각 충돌에 대해 **내 변경사항 사용** 또는 **상대방 변경사항 사용**을 선택하여 유지할 충돌하는 라인의 버전을 표시합니다. 이 결정을 "충돌 해결"이라고 합니다.
1. 모든 충돌을 해결했으면 **커밋 메시지**를 입력합니다.
1. **소스 브랜치에 커밋**을 선택합니다.

### 인라인 편집기 {#inline-editor}

일부 머지 충돌은 더 복잡하므로 라인을 수동으로 편집하여 해결해야 합니다.

머지 충돌 해결 편집기는 GitLab에서 이러한 충돌을 해결하는 데 도움을 줍니다:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. **개요**를 선택한 다음 머지 리퀘스트 보고서 섹션으로 스크롤합니다.
1. 머지 충돌 메시지를 찾고 **충돌 해결**을 선택합니다. GitLab은 머지 충돌이 있는 파일 목록을 표시합니다.
1. 수동으로 편집할 파일을 찾고 충돌 블록으로 스크롤합니다.
1. 해당 파일의 헤더에서 **인라인 편집**을 선택하여 편집기를 엽니다. 이 예에서 충돌 블록은 라인 1350에서 시작하여 라인 1356에서 끝납니다:

   ![머지 충돌 편집기](img/merge_conflict_editor_v16_7.png)

1. 충돌을 해결한 후 **커밋 메시지**를 입력합니다.
1. **소스 브랜치에 커밋**을 선택합니다.

## 리베이스 {#rebase}

머지 리퀘스트가 `Checking ability to merge automatically` 메시지로 막혀 있으면 다음을 수행할 수 있습니다:

- 머지 리퀘스트의 댓글에서 [`/rebase` 빠른 작업](../quick_actions.md#rebase)을 실행합니다.
- 머지 리퀘스트 위젯에서 **리베이스 소스 브랜치**를 선택합니다.
- [Git으로 리베이스](../../../topics/git/git_rebase.md#rebase)합니다.

CI/CD 파이프라인 이슈를 해결하려면 [CI/CD 파이프라인 디버깅](../../../ci/debugging.md)을 참조하세요.

반선형 또는 빠른 전달 병합 방법을 사용하는 프로젝트의 경우 [병합 전 자동 리베이스](methods/_index.md#automatic-rebase-before-merge)를 켜서 수동 리베이스 단계를 건너뛸 수 있습니다.

### GitLab UI에서 리베이스 {#rebase-in-the-gitlab-ui}

GitLab UI에서 리베이스를 트리거하려면 [`/rebase` 빠른 작업](../quick_actions.md#rebase)을 사용하거나 머지 리퀘스트 위젯의 리베이스 옵션을 사용합니다.

전제 조건:

- 머지 충돌이 없습니다.
- 소스 프로젝트에 대해 최소한 [Developer 역할](../../permissions.md)이 있어야 합니다.
- 머지 리퀘스트가 포크에 있는 경우 포크는 [업스트림 프로젝트의 구성원으로부터 커밋](allow_collaboration.md)을 허용해야 합니다.

GitLab UI에서 머지 리퀘스트 브랜치를 리베이스하려면:

1. 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾으세요.
1. 왼쪽 사이드바에서 **코드** > **머지 리퀘스트**를 선택하고 머지 리퀘스트를 찾습니다.
1. 다음 중 하나를 수행합니다:
   - **개요** 탭에서 머지 리퀘스트 위젯으로 스크롤한 다음 **리베이스 소스 브랜치**를 선택합니다.
   - 댓글에서 `/rebase`을(를) 입력한 다음 **댓글**을 선택합니다.

GitLab은 기본 브랜치에 대해 브랜치의 리베이스를 예약한 다음 실행합니다. GitLab은 완료된 리베이스를 시스템 노트로 표시합니다.

> [!note]
> GitLab UI를 통해 만든 커밋에 대해 커밋 서명을 설정한 경우 웹 커밋은 [UI를 통해 리베이스될 때](../repository/signed_commits/web_commits.md#web-commits-become-unsigned-after-rebase) 커밋 서명을 잃습니다.

## 관련 항목 {#related-topics}

- [리베이스 및 충돌 해결](../../../topics/git/git_rebase.md)
- [Git 리베이스 및 강제 푸시 소개](../../../topics/git/git_rebase.md)
- [Git 워크플로우를 시각화하기 위한 Git 애플리케이션](https://git-scm.com/downloads/guis)
- [`git rerere`을(를) 사용한 자동 충돌 해결](https://git-scm.com/book/en/v2/Git-Tools-Rerere)
