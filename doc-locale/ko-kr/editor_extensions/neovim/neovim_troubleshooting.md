---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Neovim에서 GitLab Duo를 연결하고 사용합니다.
title: Neovim 문제 해결
---

{{< details >}}

- 티어:  [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab plugin for Neovim 문제를 해결할 때 다른 Neovim plugin 및 설정과 독립적으로 이슈가 발생하는지 확인해야 합니다. 먼저 Neovim [테스트 단계](#test-your-neovim-configuration)를 실행한 다음 GitLab Duo Code Suggestions 문제 해결 단계를 실행합니다.

이 페이지의 단계가 문제를 해결하지 못하면 Neovim plugin의 프로젝트에서 [열린 이슈 목록](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/?sort=created_date&state=opened&first_page_size=100)을 확인합니다. 이슈가 문제와 일치하면 해당 이슈를 업데이트하세요. 일치하는 이슈가 없으면 [새로운 이슈를 생성](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/new)하세요.

## Neovim 구성 테스트 {#test-your-neovim-configuration}

Neovim plugin의 유지 관리자는 문제 해결의 일부로 이러한 확인 결과를 자주 요청합니다:

1. [도움말 태그를 생성했는지](#generate-help-tags) 확인합니다.
1. [`:checkhealth`](#run-checkhealth)를 실행합니다.
1. [디버그 로그](#enable-debug-logs)를 활성화합니다.
1. [최소 프로젝트에서 문제를 재현](#reproduce-the-problem-in-a-minimal-project)해 봅니다.

### 도움말 태그 생성 {#generate-help-tags}

`E149: Sorry, no help for gitlab.txt` 오류가 나타나면 Neovim에서 도움말 태그를 생성해야 합니다. 이 이슈를 해결하려면:

- 다음 명령 중 하나를 실행합니다:
  - `:helptags ALL`
  - plugin의 루트 디렉터리에서 `:helptags doc/`를 실행합니다.

### `:checkhealth`를 실행합니다 {#run-checkhealth}

`:checkhealth gitlab*`를 실행하여 현재 세션 구성에 대한 진단을 가져옵니다. 이러한 확인은 구성 문제를 식별하고 해결하는 데 도움이 됩니다.

## 디버그 로그 활성화 {#enable-debug-logs}

디버그 로그를 활성화하여 문제에 대한 자세한 정보를 캡처합니다. 디버그 로그에는 민감한 구성 세부 정보가 포함될 수 있으므로 다른 사람과 공유하기 전에 출력을 검토합니다.

추가 로깅을 활성화하려면:

- 현재 버퍼에서 `vim.lsp` 로그 수준을 설정합니다:

  ```lua
  :lua vim.lsp.set_log_level('debug')
  ```

## 최소 프로젝트에서 문제 재현 {#reproduce-the-problem-in-a-minimal-project}

프로젝트 유지 관리자가 이슈를 이해하고 해결하도록 돕기 위해 이슈를 재현하는 샘플 구성 또는 프로젝트를 만듭니다. 예를 들어 Code Suggestions 관련 문제를 해결할 때:

1. 샘플 프로젝트를 만듭니다:

   ```plaintext
   mkdir issue-25
   cd issue-25
   echo -e "def hello(name)\n\nend" > hello.rb
   ```

1. `minimal.lua` 이름의 새 파일을 만들고 다음 내용을 추가합니다:

   ```lua
   -- NOTE: Do not set this in your usual configuration, as this log level
   -- could include sensitive configuration details.
   vim.lsp.set_log_level('debug')

   vim.opt.rtp:append('$HOME/.local/share/nvim/site/pack/gitlab/start/gitlab.vim')

   vim.cmd('runtime plugin/gitlab.lua')

   -- gitlab.config options overrides:
   local minimal_user_options = {}
   require('gitlab').setup(minimal_user_options)
   ```

1. 최소 Neovim 세션에서 `hello.rb`를 편집합니다:

   ```shell
   nvim --clean -u minimal.lua hello.rb
   ```

1. 경험한 동작을 재현해 봅니다. `minimal.lua` 또는 다른 프로젝트 파일을 필요에 따라 조정합니다.
1. `~/.local/state/nvim/lsp.log`의 최근 항목을 보고 관련 출력을 캡처합니다.
1. `glpat-`로 시작하는 토큰과 같은 민감한 정보에 대한 모든 참조를 수정합니다.
1. Vim 레지스터 또는 로그 파일에서 민감한 정보를 제거합니다.

### 오류: `GCS:unavailable` {#error-gcsunavailable}

이 오류는 로컬 프로젝트가 `.git/config`에서 원격을 설정하지 않았을 때 발생합니다.

이 문제를 해결하려면 [`git remote add`](../../topics/git/commands.md#git-remote-add)를 사용하여 로컬 프로젝트에 Git 원격을 추가합니다.
