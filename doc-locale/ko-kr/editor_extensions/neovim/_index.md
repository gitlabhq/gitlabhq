---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Neovim에서 GitLab Duo를 연결하고 사용합니다.
title: Neovim용 GitLab 플러그인 - `gitlab.vim`
---

{{< details >}}

- 티어:  [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[GitLab 플러그인](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim)은 GitLab을 Neovim과 통합하는 Lua 기반 플러그인입니다.

이 플러그인을 사용하면 명령줄에서 [GitLab Duo 코드 제안](../../user/project/repository/code_suggestions/_index.md)을 사용할 수 있습니다.

확장 프로그램을 설치하고 구성하려면 [설치 및 설정](setup.md)을 참조하세요.

## `gitlab.statusline` 사용 안 함 {#disable-gitlabstatusline}

기본적으로 이 플러그인은 `gitlab.statusline`을 활성화하며, GitLab Duo 코드 제안 통합의 상태를 표시하기 위해 기본 제공 `statusline`을 사용합니다. `gitlab.statusline` 사용을 비활성화하려면 다음을 구성에 추가하세요:

```lua
require('gitlab').setup({
  statusline = {
    enabled = false
  }
})
```

## `Started Code Suggestions LSP Integration` 메시지 사용 안 함 {#disable-started-code-suggestions-lsp-integration-messages}

최소 메시지 수준을 변경하려면 다음을 구성에 추가하세요:

```lua
require('gitlab').setup({
  minimal_message_level = vim.log.levels.ERROR,
})
```

## 확장 업데이트 {#update-the-extension}

`gitlab.vim` 플러그인을 업데이트하려면 `git pull`을 사용하거나 특정 Vim 플러그인 관리자를 사용합니다.

## 확장 프로그램 관련 문제 보고 {#report-issues-with-the-extension}

[`gitlab.vim` 이슈 추적기](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues)에서 문제, 버그 또는 기능 요청을 보고합니다.

[이슈 22](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/22)에서 `gitlab.vim` 리포지토리에 피드백을 제출하세요.

## 관련 항목 {#related-topics}

- [Neovim용 GitLab 플러그인 릴리스](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/releases)
- [에디터 확장에 대한 보안 고려 사항](../security_considerations.md)
- [Neovim 문제 해결](neovim_troubleshooting.md)
- [소스 코드 보기](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim)
- [GitLab 언어 서버 설명서](../language_server/_index.md)
