---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: NeovimでGitLab Duoを接続して使用します。
title: Neovimのトラブルシューティング
---

Neovim用GitLabプラグインのトラブルシューティングを行う際は、他のNeovimプラグインや設定から切り離して問題が発生することを確認する必要があります。まず、Neovimの[テスト手順](#test-your-neovim-configuration)を実行し、次に[GitLab Duoコード提案](../../user/duo_agent_platform/code_suggestions/troubleshooting.md)または[GitLab Duoコード提案 (Classic)](../../user/project/repository/code_suggestions/troubleshooting.md)のトラブルシューティング手順を実行してください。

このページの手順で問題が解決するしない場合は、Neovimプラグインのプロジェクトで[オープンなイシューのリスト](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/?sort=created_date&state=opened&first_page_size=100)を確認してください。イシューが問題と一致する場合は、そのイシューを更新してください。問題に一致するイシューがない場合は、[新しいイシューを作成](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/new)してください。

## Neovimの設定をテストする {#test-your-neovim-configuration}

Neovimプラグインのメンテナーは、トラブルシューティングの一環として、これらのチェックの結果を求めることがよくあります:

1. [ヘルプタグを生成](#generate-help-tags)していることを確認してください。
1. [`:checkhealth`](#run-checkhealth)を実行してください。
1. [デバッグログ](#enable-debug-logs)を有効にしてください。
1. 最小限のプロジェクトで[問題を再現](#reproduce-the-problem-in-a-minimal-project)してみてください。

### ヘルプタグを生成する {#generate-help-tags}

エラー`E149: Sorry, no help for gitlab.txt`が表示される場合は、Neovimでヘルプタグを生成する必要があります。この問題を解決するには:

- 以下のいずれかのコマンドを実行してください:
  - `:helptags ALL`
  - プラグインのルートディレクトリから`:helptags doc/`。

### `:checkhealth`を実行する {#run-checkhealth}

`:checkhealth gitlab*`を実行して、現在のセッション設定に関する診断情報を取得します。これらのチェックは、設定の問題を自分で特定し、解決するのに役立ちます。

## デバッグログを有効にする {#enable-debug-logs}

デバッグログを有効にして、問題に関する詳細情報を取得します。デバッグログには機密情報となるワークスペースの設定が含まれる可能性があるため、他のユーザーと共有する前に出力を確認してください。

追加のログを有効にするには:

- 現在のバッファで`vim.lsp`のログレベルを設定します:

  ```lua
  :lua vim.lsp.set_log_level('debug')
  ```

## 最小限のプロジェクトで問題を再現する {#reproduce-the-problem-in-a-minimal-project}

プロジェクトメンテナーがイシューを理解し解決するのを助けるために、イシューを再現するサンプル設定またはプロジェクトを作成してください。たとえば、コード提案に関する問題のトラブルシューティングを行う場合:

1. サンプルプロジェクトを作成します:

   ```plaintext
   mkdir issue-25
   cd issue-25
   echo -e "def hello(name)\n\nend" > hello.rb
   ```

1. `minimal.lua`という名前の新しいファイルを以下の内容で作成します:

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

1. 最小限のNeovimセッションで、`hello.rb`を編集します:

   ```shell
   nvim --clean -u minimal.lua hello.rb
   ```

1. 発生した現象を再現してみてください。必要に応じて`minimal.lua`または他のプロジェクトファイルを調整します。
1. `~/.local/state/nvim/lsp.log`の最近のエントリを表示し、関連する出力をキャプチャします。
1. `glpat-`で始まるトークンなど、機密情報への参照を削除する。
1. Vimレジスタまたはログファイルから機密情報を削除します。

### エラー: `GCS:unavailable` {#error-gcsunavailable}

このエラーは、ローカルプロジェクトが`.git/config`にリモートを設定していない場合に発生します。

このイシューを解決するには、[`git remote add`](../../topics/git/commands.md#git-remote-add)を使用してローカルプロジェクトにGitリモートを追加します。
