---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and use GitLab Duo in Neovim."
title: Install and set up the GitLab plugin for Neovim
---

Prerequisites:

- For both GitLab.com and GitLab Self-Managed, you have GitLab version 16.1 or later.
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

:::TabTitle `packer.nvim`

Declare the plugin in your [packer.nvim](https://github.com/wbthomason/packer.nvim) configuration:

```lua
use {
  "git@gitlab.com:gitlab-org/editor-extensions/gitlab.vim.git",
}
```

::EndTabs

## Authenticate with GitLab

To connect this extension to your GitLab account, configure your environment variables:

| Environment variable | Default              | Description |
|----------------------|----------------------|-------------|
| `GITLAB_TOKEN`       | not applicable       | The default GitLab personal access token to use for authenticated requests. If provided, skips interactive authentication. |
| `GITLAB_VIM_URL`     | `https://gitlab.com` | Override the GitLab instance to connect with. Defaults to `https://gitlab.com`. |

A full list of environment variables is available in the extension's help text at
[`doc/gitlab.txt`](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/blob/main/doc/gitlab.txt).

## Configure the extension

To configure this extension:

1. Configure your desired file types. For example, because this plugin supports Ruby, it adds a `FileType ruby` auto-command.
   To configure this behavior for more file types, add more file types to the `code_suggestions.auto_filetypes` setup option:

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

1. [Configure Omni Completion](#configure-omni-completion) to set up the key mapping to trigger Code Suggestions.
1. Optional. [Configure `<Plug>` key mappings](_index.md#configure-plug-key-mappings).
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

## Uninstall the extension

To uninstall the extension, remove this plugin and any language server binaries with these commands:

```shell
rm -r ~/.local/share/nvim/site/pack/gitlab/start/gitlab.vim
rm ~/.local/share/nvim/gitlab-code-suggestions-language-server-*
```
