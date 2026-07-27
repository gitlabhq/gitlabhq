---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Neovim에서 GitLab Duo를 연결하고 사용합니다.
title: Neovim용 GitLab 플러그인 설치 및 설정
---

{{< details >}}

- 티어:  [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

전제 조건:

- GitLab.com 및 GitLab Self-Managed 모두의 경우 GitLab 버전 16.1 이상이 필요합니다. 많은 확장 기능이 이전 버전에서 작동할 수 있지만 지원되지 않습니다.
  - GitLab Duo Code Suggestions 기능은 GitLab 버전 16.8 이상이 필요합니다.
- [Neovim](https://neovim.io/) 버전 0.9 이상이 있습니다.
- [NPM](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)이 설치되어 있습니다. NPM은 Code Suggestions 설치에 필요합니다.

확장을 설치하려면 선택한 플러그인 관리자의 설치 단계를 따릅니다:

{{< tabs >}}

{{< tab title="플러그인 관리자 없음" >}}

이 명령을 실행하여 [`packadd`](https://neovim.io/doc/user/repeat.html#%3Apackadd)를 사용해 이 프로젝트를 포함합니다:

```shell
git clone https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim.git ~/.local/share/nvim/site/pack/gitlab/start/gitlab.vim
```

{{< /tab >}}

{{< tab title="`lazy.nvim`" >}}

[lazy.nvim](https://github.com/folke/lazy.nvim) 구성에 이 플러그인을 추가합니다:

```lua
{
  'https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim.git',
  -- Activate when a file is created/opened
  event = { 'BufReadPre', 'BufNewFile' },
  -- Activate when a supported filetype is open
  ft = { 'go', 'javascript', 'python', 'ruby' },
  cond = function()
    -- Only activate if token is present in environment variable.
    -- Remove this line to use the interactive workflow.
    return vim.env.GITLAB_TOKEN ~= nil and vim.env.GITLAB_TOKEN ~= ''
  end,
  opts = {
    statusline = {
      -- Hook into the built-in statusline to indicate the status
      -- of the GitLab Duo Code Suggestions integration
      enabled = true,
    },
  },
}
```

{{< /tab >}}

{{< tab title="`packer.nvim`" >}}

[packer.nvim](https://github.com/wbthomason/packer.nvim) 구성에서 플러그인을 선언합니다:

```lua
use {
  "git@gitlab.com:gitlab-org/editor-extensions/gitlab.vim.git",
}
```

{{< /tab >}}

{{< /tabs >}}

## GitLab으로 인증 {#authenticate-with-gitlab}

이 확장을 GitLab 계정에 연결하려면 환경 변수를 구성합니다:

| 환경 변수 | 기본값              | 설명 |
|----------------------|----------------------|-------------|
| `GITLAB_TOKEN`       | 해당 없음       | 인증된 요청에 사용할 기본 GitLab 개인 액세스 토큰입니다. 제공된 경우 대화형 인증을 건너뜁니다. |
| `GITLAB_VIM_URL`     | `https://gitlab.com` | 연결할 GitLab 인스턴스를 재정의합니다. 기본값은 `https://gitlab.com`입니다. |

환경 변수의 전체 목록은 [`doc/gitlab.txt`](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/doc/gitlab.txt)의 확장 도움말에서 사용 가능합니다.

## 확장 구성 {#configure-the-extension}

이 확장을 구성하려면:

1. 원하는 파일 형식을 구성합니다. 예를 들어, 이 플러그인이 Ruby를 지원하므로 `FileType ruby` 자동 명령을 추가합니다. 더 많은 파일 형식에 대해 이 동작을 구성하려면 `code_suggestions.auto_filetypes` 설정 옵션에 더 많은 파일 형식을 추가합니다:

   ```lua
   require('gitlab').setup({
     statusline = {
       enabled = false
     },
     code_suggestions = {
       -- For the full list of default languages, see the 'auto_filetypes' array in
       -- https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/lua/gitlab/config/defaults.lua
       auto_filetypes = { 'ruby', 'javascript' }, -- Default is { 'ruby' }
       ghost_text = {
         enabled = false, -- ghost text is an experimental feature
         toggle_enabled = "<C-h>",
         accept_suggestion = "<C-l>",
         clear_suggestions = "<C-k>",
         stream = true,
       },
     }
   })
   ```

1. [Omni Completion 구성](#configure-omni-completion)하여 Code Suggestions를 트리거하는 키 매핑을 설정합니다.
1. 선택 사항. [`<Plug>` 키 매핑 구성](#configure-plug-key-mappings)합니다.
1. 선택 사항. `:helptags ALL`을 사용하여 [`:help gitlab.txt`](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/doc/gitlab.txt)에 액세스하기 위해 helptags를 설정합니다.

### Omni Completion 구성 {#configure-omni-completion}

Code Suggestions와 함께 [Omni Completion](https://neovim.io/doc/user/insert.html#compl-omni-filetypes)을 활성화하려면:

1. `api` 범위를 사용하여 [개인 액세스 토큰](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)을 만듭니다.
1. 토큰을 `GITLAB_TOKEN` 환경 변수로 셸에 추가합니다.
1. `:GitLabCodeSuggestionsInstallLanguageServer` vim 명령을 실행하여 Code Suggestions [언어 서버](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp)를 설치합니다.
1. `:GitLabCodeSuggestionsStart` vim 명령을 실행하여 Language Server를 시작합니다. 선택 사항으로 언어 서버를 토글하기 위해 [`<Plug>` 키 매핑을 구성합니다](#configure-plug-key-mappings).
1. 선택 사항. 단일 제안이라도 Omni Completion의 대화 상자를 구성하는 것을 고려합니다:

   ```lua
   vim.o.completeopt = 'menu,menuone'
   ```

지원되는 파일 형식으로 작업할 때 <kbd>Control</kbd>+<kbd>x</kbd>를 누른 다음 <kbd>Control</kbd>+<kbd>o</kbd>를 눌러 Omni Completion 메뉴를 엽니다.

## `<Plug>` 키 매핑 구성 {#configure-plug-key-mappings}

편의상 이 플러그인은 `<Plug>` 키 매핑을 제공합니다. `<Plug>(GitLab...)` 키 매핑을 사용하려면 이를 참조하는 자신의 키 매핑을 포함해야 합니다:

```lua
-- Toggle Code Suggestions on/off with Control-G in normal mode:
vim.keymap.set('n', '<C-g>', '<Plug>(GitLabToggleCodeSuggestions)')
```

## 확장 제거 {#uninstall-the-extension}

확장을 제거하려면 다음 명령으로 이 플러그인 및 모든 언어 서버 바이너리를 제거합니다:

```shell
rm -r ~/.local/share/nvim/site/pack/gitlab/start/gitlab.vim
rm ~/.local/share/nvim/gitlab-code-suggestions-language-server-*
```
