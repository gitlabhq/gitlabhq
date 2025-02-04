---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Connect and use GitLab Duo in Neovim."
title: Neovim troubleshooting
---

When troubleshooting the GitLab plugin for Neovim, you should confirm if an issue still occurs
in isolation from other Neovim plugins and settings. First, run the Neovim [testing steps](#test-your-neovim-configuration),
then the [GitLab Duo Code Suggestions troubleshooting steps](../../user/project/repository/code_suggestions/troubleshooting.md).

If the steps on this page don't solve your problem, check the
[list of open issues](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/?sort=created_date&state=opened&first_page_size=100)
in the Neovim plugin's project. If an issue matches your problem, update the issue.
If no issues match your problem, [create a new issue](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/new).

For troubleshooting the extension for GitLab Duo Code Suggestions,
see [Troubleshooting Code Suggestions](../../user/project/repository/code_suggestions/troubleshooting.md#neovim-troubleshooting).

## Test your Neovim configuration

The maintainers of the Neovim plugin often ask for the results of these checks as part of troubleshooting:

1. Ensure you have [generated help tags](#generate-help-tags).
1. Run [`:checkhealth`](#run-checkhealth).
1. Enable [debug logs](#enable-debug-logs).
1. Try to [reproduce the problem in a minimal project](#reproduce-the-problem-in-a-minimal-project).

### Generate help tags

If you see the error `E149: Sorry, no help for gitlab.txt`, you need to generate help tags in Neovim.
To resolve this issue:

- Run either of these commands:
  - `:helptags ALL`
  - `:helptags doc/` from the root directory of the plugin.

### Run `:checkhealth`

Run `:checkhealth gitlab*` to get diagnostics on your current session configuration.
These checks help you identify and resolve configuration issues on your own.

## Enable debug logs

Enable debug logs to capture more information about problems. Debug logs can
contain sensitive workspace configuration, so review the output before sharing
it with others.

To enable extra logging:

- Set the `vim.lsp` log level in your current buffer:

  ```lua
  :lua vim.lsp.set_log_level('debug')
  ```

## Reproduce the problem in a minimal project

To help project maintainers understand and resolve your issue, create a sample
configuration or project that reproduces your issue. For example, when troubleshooting
a problem with Code Suggestions:

1. Create a sample project:

   ```plaintext
   mkdir issue-25
   cd issue-25
   echo -e "def hello(name)\n\nend" > hello.rb
   ```

1. Create a new file named `minimal.lua`, with these contents:

   ```lua
   -- NOTE: Do not set this in your usual configuration, as this log level
   -- could include sensitive workspace configuration.
   vim.lsp.set_log_level('debug')

   vim.opt.rtp:append('$HOME/.local/share/nvim/site/pack/gitlab/start/gitlab.vim')

   vim.cmd('runtime plugin/gitlab.lua')

   -- gitlab.config options overrides:
   local minimal_user_options = {}
   require('gitlab').setup(minimal_user_options)
   ```

1. In a minimal Neovim session, edit `hello.rb`:

   ```shell
   nvim --clean -u minimal.lua hello.rb
   ```

1. Attempt to reproduce the behavior you experienced. Adjust `minimal.lua` or other project files as needed.
1. View recent entries in `~/.local/state/nvim/lsp.log` and capture relevant output.
1. Redact any references to sensitive information, such as tokens beginning with `glpat-`.
1. Remove sensitive information from any Vim registers or log files.

### Error: `GCS:unavailable`

This error happens when your local project has not set a remote in `.git/config`.

To resolve this issue: add a Git remote in your local project using
[`git remote add`](../../topics/git/commands.md#git-remote-add).
