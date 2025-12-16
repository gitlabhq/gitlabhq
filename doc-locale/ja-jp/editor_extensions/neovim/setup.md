---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: NeovimでGitLab Duoを接続して使用します。
title: Neovim用GitLabプラグインをインストールして設定する
---

前提要件: 

- GitLab.comとGitLabセルフマネージドの両方で、GitLabバージョン16.1以降が必要です。多くの拡張機能は以前のバージョンでも動作する可能性がありますが、サポートされていません。
  - GitLab Duoコード提案機能を使用するには、GitLabバージョン16.8以降が必要です。
- [Neovim](https://neovim.io/)バージョン0.9以降が必要です。
- [NPM](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)がインストールされている必要があります。コード提案のインストールにはNPMが必要です。

プラグインをインストールするには、選択したプラグインマネージャーのインストール手順に従ってください:

{{< tabs >}}

{{< tab title="プラグインマネージャーなし" >}}

このジョブを起動時に[`packadd`](https://neovim.io/doc/user/repeat.html#%3Apackadd)に含めるには、次のコマンドを実行します:

```shell
git clone https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim.git ~/.local/share/nvim/site/pack/gitlab/start/gitlab.vim
```

{{< /tab >}}

{{< tab title="`lazy.nvim`" >}}

このプラグインを[lazy.nvim](https://github.com/folke/lazy.nvim)設定に追加します:

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

[packer.nvim](https://github.com/wbthomason/packer.nvim)設定でプラグインを宣言します:

```lua
use {
  "git@gitlab.com:gitlab-org/editor-extensions/gitlab.vim.git",
}
```

{{< /tab >}}

{{< /tabs >}}

## GitLabに対して認証する {#authenticate-with-gitlab}

この拡張機能をGitLabアカウントに接続するには、環境変数を設定します:

| 環境変数 | デフォルト              | 説明 |
|----------------------|----------------------|-------------|
| `GITLAB_TOKEN`       | 該当なし       | 認証されたリクエストに使用するデフォルトのGitLabパーソナルアクセストークン。指定されている場合は、インタラクティブな認証をスキップします。 |
| `GITLAB_VIM_URL`     | `https://gitlab.com` | 接続するGitLabインスタンスをオーバーライドします。`https://gitlab.com`がデフォルトです。 |

環境変数の完全なリストは、拡張機能のヘルプテキスト（[`doc/gitlab.txt`](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/doc/gitlab.txt)）にあります。

## 拡張機能を設定する {#configure-the-extension}

この拡張機能を設定するには:

1. 目的のファイルタイプを設定します。たとえば、このプラグインはRubyをサポートしているため、`FileType ruby`の自動コマンドを追加します。この動作をより多くのファイルタイプに設定するには、`code_suggestions.auto_filetypes`セットアップオプションにファイルタイプをさらに追加します:

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

1. [Omni Completion](#configure-omni-completion)を設定して、コード提案をトリガーするためのキーマッピングをセットアップします。
1. オプション。[`<Plug>`キーマッピングを設定する](#configure-plug-key-mappings)。
1. オプション。[`:help gitlab.txt`](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/doc/gitlab.txt)にアクセスするには、`:helptags ALL`を使用してhelptagsをセットアップします。

### Omni Completionの設定 {#configure-omni-completion}

コード提案で[Omni Completion](https://neovim.io/doc/user/insert.html#compl-omni-filetypes)を有効にするには:

1. `api`スコープを持つ[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md#create-a-personal-access-token)を作成してください。
1. `GITLAB_TOKEN`環境変数としてShellにトークンを追加します。
1. `:GitLabCodeSuggestionsInstallLanguageServer` vimコマンドを実行して、コード提案[言語サーバー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp)をインストールします。
1. `:GitLabCodeSuggestionsStart` vimコマンドを実行して、言語サーバーを起動します。オプションで、言語サーバーを切り替えるには、[`<Plug>`キーマッピングを設定します](#configure-plug-key-mappings)。
1. オプション。単一の提案の場合でも、Omni Completionのダイアログを設定することを検討してください:

   ```lua
   vim.o.completeopt = 'menu,menuone'
   ```

サポートされているファイルタイプで作業している場合は、<kbd>Control</kbd>+<kbd>x</kbd>、次に<kbd>Control</kbd>+<kbd>o</kbd>を押して、Omni Completionメニューを開きます。

## `<Plug>`キーマッピングを設定する {#configure-plug-key-mappings}

便宜上、このプラグインは`<Plug>`キーマッピングを提供します。`<Plug>(GitLab...)`キーマッピングを使用するには、それを参照する独自のキーマッピングを含める必要があります:

```lua
-- Toggle Code Suggestions on/off with Control-G in normal mode:
vim.keymap.set('n', '<C-g>', '<Plug>(GitLabToggleCodeSuggestions)')
```

## プラグインをアンインストール {#uninstall-the-extension}

プラグインをアンインストールするには、次のコマンドを使用して、このプラグインと言語サーバーバイナリを削除します:

```shell
rm -r ~/.local/share/nvim/site/pack/gitlab/start/gitlab.vim
rm ~/.local/share/nvim/gitlab-code-suggestions-language-server-*
```
