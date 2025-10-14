---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Connect and use GitLab Duo in Neovim.
title: GitLab plugin for Neovim - `gitlab.vim`
---

The [GitLab plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim) is a Lua-based plugin
that integrates GitLab with Neovim.

To install and configure the extension, see [Install and set up](setup.md).

## Disable `gitlab.statusline`

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

## Disable `Started Code Suggestions LSP Integration` messages

To change the minimal message level, add this to your configuration:

```lua
require('gitlab').setup({
  minimal_message_level = vim.log.levels.ERROR,
})
```

## Update the extension

To update the `gitlab.vim` plugin, use `git pull` or your specific Vim plugin manager.

## Report issues with the extension

Report any issues, bugs, or feature requests in the
[`gitlab.vim` issue tracker](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues).

Submit your feedback in [issue 22](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/22)
in the `gitlab.vim` repository.

## Related topics

- [Neovim troubleshooting](neovim_troubleshooting.md)
- [View source code](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim)
- [GitLab Language Server documentation](../language_server/_index.md)
