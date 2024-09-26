---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and use GitLab Duo in Neovim."
---

# GitLab plugin for Neovim - `gitlab.vim`

The [GitLab plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim)
integrates GitLab with Neovim, and is built in Lua.

GitLab for Neovim supports [GitLab Duo Code Suggestions](../../user/project/repository/code_suggestions/index.md).
Code Suggestions provides a LSP (Language Server Protocol) server, to support the built-in
<kbd>Control</kbd>+<kbd>x</kbd>, <kbd>Control</kbd>+<kbd>o</kbd> Omni Completion key mapping:

| Mode     | Key mappings                          | Type      | Description |
|----------|---------------------------------------|-----------|-------------|
| `INSERT` | <kbd>Control</kbd>+<kbd>x</kbd>, <kbd>Control</kbd>+<kbd>o</kbd> | Built-in | Requests completions from GitLab Duo Code Suggestions through the language server. |
| `NORMAL` | `<Plug>(GitLabToggleCodeSuggestions)` | `<Plug>`  | Toggles Code Suggestions on or off for the current buffer. Requires [configuration](#configure-plug-key-mappings). |

## Install the extension

Prerequisites:

- For both GitLab.com and self-managed, you have GitLab version 16.1 or later.
  While many extension features might work with earlier versions, they are unsupported.
  - The GitLab Duo Code Suggestions feature requires GitLab version 16.8 or later.
- You have [Neovim](https://neovim.io/) version 0.9 or later.

To install the extension, follow the installation steps for your chosen plugin manager:

::Tabs

:::TabTitle No plugin manager

Run this command to include this project with
[`packadd`](https://neovim.io/doc/user/repeat.html#%3Apackadd) on startup:

```shell
git clone https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim.git ~/.local/share/nvim/site/pack/gitlab/start/gitlab.vim
```

:::TabTitle `lazy.nvim`

Add this plugin to your [lazy.nvim](https://github.com/folke/lazy.nvim) configuration:

```lua
{
  'git@gitlab.com:gitlab-org/editor-extensions/gitlab.vim.git',
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

:::TabTitle `packer.nvim`

Declare the plugin in your [packer.nvim](https://github.com/wbthomason/packer.nvim) configuration:

```lua
use {
  "git@gitlab.com:gitlab-org/editor-extensions/gitlab.vim.git",
}
```

::EndTabs

## Configure the extension

1. Configure environment variables. While these are the most common, a full list is available in this
   plugin's help text at [`doc/gitlab.txt`](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/doc/gitlab.txt):

   | Environment variable | Default              | Description |
   |----------------------|----------------------|-------------|
   | `GITLAB_TOKEN`.      | not applicable       | The default GitLab personal access token to use for authenticated requests. If provided, skips interactive authentication. |
   | `GITLAB_VIM_URL`.    | `https://gitlab.com` | Override the GitLab instance to connect with. Defaults to `https://gitlab.com`. |

1. Configure your desired file types. For example, because this plugin supports Ruby, it adds a `FileType ruby` auto-command.
   To configure this behavior for additional file types, add more file types to the `code_suggestions.auto_filetypes` setup option:

   ```lua
   require('gitlab').setup({
     statusline = {
       enabled = false
     },
     code_suggestions = {
       # For the full list of default languages, see the 'auto_filetypes' array in
       # https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/lua/gitlab/config/defaults.lua 
       auto_filetypes = { 'ruby', 'javascript' }, -- Default is { 'ruby' }
     }
   })
   ```

1. Optional. [Configure Omni Completion](#configure-omni-completion).
1. Optional. [Configure `<Plug>` key mappings](#configure-plug-key-mappings).
1. Optional. Set up helptags using `:helptags ALL` for access to
   [`:help gitlab.txt`](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/doc/gitlab.txt).

### Configure Omni Completion

To enable [Omni Completion](https://neovim.io/doc/user/insert.html#compl-omni-filetypes)
with Code Suggestions:

1. Create a [personal access token](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) with the `api` scope.
1. Install the Code Suggestions [language server](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp).
1. Optional. Consider configuring Omni Completion's dialog even for a single suggestion:

   ```lua
   vim.o.completeopt = 'menu,menuone'
   ```

When working in a supported file type, open the Omni Completion menu by pressing <kbd>Ctrl</kbd>+<kbd>x</kbd>
then <kbd>Ctrl</kbd>+<kbd>o</kbd>.

### Configure `<Plug>` key mappings

For convenience, this plugin provides `<Plug>` key mappings. To use the `<Plug>(GitLab...)` key mapping,
you must include your own key mapping that references it:

```lua
-- Toggle Code Suggestions on/off with CTRL-g in normal mode:
vim.keymap.set('n', '<C-g>', '<Plug>(GitLabToggleCodeSuggestions)')
```

### Disable `gitlab.statusline`

By default, this plugin enables `gitlab.statusline`, which uses the built-in `statusline`
to show the status of the Code Suggestions integration. If you want to disable `gitlab.statusline`,
add this to your configuration:

```lua
require('gitlab').setup({
  statusline = {
    enabled = false
  }
})
```

## Report issues with the extension

Report any issues, bugs, or feature requests in the
[`gitlab.vim` issue queue](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues).

Submit your feedback in [issue 22](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/22)
in the `gitlab.vim` repository.

## Uninstall the extension

To uninstall the extension, remove this plugin and any language server binaries with these commands:

```shell
rm -r ~/.local/share/nvim/site/pack/gitlab/start/gitlab.vim
rm ~/.local/share/nvim/gitlab-code-suggestions-language-server-*
```

## Related topics

- [View source code](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim)
