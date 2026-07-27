---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Eclipse에서 GitLab Duo를 연결하고 사용합니다.
title: Eclipse용 GitLab
---

{{< details >}}

- 티어:  [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

{{< history >}}

- [GitLab 17.11에서 실험에서 베타로 변경되었습니다](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163).
- GitLab 19.0의 일부로 2026년 5월 21일부터 GitLab Duo Core 고객을 대상으로 GitLab Duo Non-Agentic Chat 액세스가 제거됨(`no_duo_classic_for_duo_core_users` 기능 플래그 사용). 기본적으로 활성화됨.

{{< /history >}}

> [!disclaimer]

Eclipse용 GitLab 플러그인은 GitLab Duo와 통합되어 다음 기능을 제공합니다:

- [GitLab Duo Code Suggestions](../../user/project/repository/code_suggestions/_index.md)
- [GitLab Duo Non-Agentic Chat](../../user/gitlab_duo_chat/_index.md). GitLab Duo Pro 또는 Enterprise, 또는 Amazon Q 사용자를 포함한 GitLab Duo에서만 사용 가능합니다.

플러그인을 설치하고 구성하려면 [설치 및 설정](setup.md)을 참조하세요.

## 플러그인 업데이트 {#update-the-plugin}

플러그인 버전을 업데이트하려면 다음 단계를 따르세요:

1. Eclipse IDE에서 **도움말** > **Check for Updates**으로 이동합니다.
1. **Available Updates** 대화 상자에서 **GitLab for Eclipse**이 선택되었는지 확인합니다.
1. **다음**을 선택한 후 **Finish**을 선택하여 플러그인을 업데이트합니다.

## 플러그인 문제 보고 {#report-issues-with-the-plugin}

[`gitlab-eclipse-plugin` 이슈 추적기](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues)에서 모든 이슈, 버그 또는 기능 요청을 보고할 수 있습니다. `Bug` 또는 `Feature Proposal` 템플릿을 사용합니다.

## 관련 항목 {#related-topics}

- [Eclipse용 GitLab 릴리스](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/releases)
- [에디터 확장에 대한 보안 고려 사항](../security_considerations.md)
- [Eclipse 문제 해결](troubleshooting.md)
- [GitLab 언어 서버 설명서](../language_server/_index.md)
- [이 플러그인에 대한 이슈 열기](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/)
- [소스 코드 보기](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin)
