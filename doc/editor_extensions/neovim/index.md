---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and use GitLab Duo in Neovim."
---

# GitLab plugin for Neovim - `gitlab.vim`

The [GitLab plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim)
integrates GitLab with Neovim, and is built in Lua.

[Install and configure the extension](setup.md).

## Configure `<Plug>` key mappings

For convenience, this plugin provides `<Plug>` key mappings. To use the `<Plug>(GitLab...)` key mapping,
you must include your own key mapping that references it:

```lua
-- Toggle Code Suggestions on/off with CTRL-g in normal mode:
vim.keymap.set('n', '<C-g>', '<Plug>(GitLabToggleCodeSuggestions)')
```

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

## Report issues with the extension

Report any issues, bugs, or feature requests in the
[`gitlab.vim` issue queue](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues).

Submit your feedback in [issue 22](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/22)
in the `gitlab.vim` repository.

## Related topics

- [Neovim troubleshooting](neovim_troubleshooting.md)
- [View source code](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim)
- [GitLab Language Server documentation](../language_server/index.md)
