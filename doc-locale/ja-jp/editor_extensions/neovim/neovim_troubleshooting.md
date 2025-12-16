---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: NeovimでGitLab Duoに接続して使用します。
title: Neovimのトラブルシューティング
---

Neovim用のGitLabプラグインのトラブルシューティングを行う場合、イシューが他のNeovimプラグインや設定とは切り離して発生するかどうかを確認する必要があります。まず、Neovimの[テスト手順](#test-your-neovim-configuration)を実行し、次に[GitLab Duoコード提案のトラブルシューティング手順](../../user/project/repository/code_suggestions/troubleshooting.md)を実行します。

このページのステップで問題が解決しない場合は、Neovimプラグインのプロジェクトにある[オープンなイシューのリスト](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/?sort=created_date&state=opened&first_page_size=100)を確認してください。イシューが問題と一致する場合は、そのイシューを更新してください。お客様の問題と一致するイシューがない場合は、[新しいイシューを作成](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/new)してください。

GitLab Duoコード提案の拡張機能のトラブルシューティングについては、[コード提案のトラブルシューティング](../../user/project/repository/code_suggestions/troubleshooting.md#neovim-troubleshooting)を参照してください。

## Neovimの設定をテストする {#test-your-neovim-configuration}

Neovimプラグインのメンテナーは、トラブルシューティングの一環として、これらのチェックの結果を求めることがよくあります:

1. [ヘルプタグが生成されている](#generate-help-tags)ことを確認してください。
1. [`:checkhealth`](#run-checkhealth)を実行します。
1. [デバッグログ](#enable-debug-logs)を有効にします。
1. [最小限のプロジェクトで問題を再現](#reproduce-the-problem-in-a-minimal-project)してみてください。

### ヘルプタグを生成する {#generate-help-tags}

エラー`E149: Sorry, no help for gitlab.txt`が表示された場合は、Neovimでヘルプタグを生成する必要があります。この問題を解決するには、以下を実行します:

- 次のいずれかのコマンドを実行します:
  - `:helptags ALL`
  - プラグインのルートディレクトリから`:helptags doc/`。

### `:checkhealth`を実行する {#run-checkhealth}

`:checkhealth gitlab*`を実行して、現在のセッション設定の診断を取得します。これらのチェックは、設定に関する問題を特定し、自分で解決するのに役立ちます。

## デバッグログを有効にする {#enable-debug-logs}

デバッグログファイルを有効にして、問題に関する詳細な情報をキャプチャします。デバッグログファイルには機密情報を含むワークスペースの設定が含まれている可能性があるため、出力を確認してから他のユーザーと共有してください。

追加のロギングを有効にするには:

- 現在のバッファで、`vim.lsp`ログレベルを設定します:

  ```lua
  :lua vim.lsp.set_log_level('debug')
  ```

## 最小限のプロジェクトで問題を再現する {#reproduce-the-problem-in-a-minimal-project}

プロジェクトのメンテナーがお客様の問題を理解して解決できるように、お客様の問題を再現するサンプル設定またはプロジェクトを作成してください。たとえば、コード提案に関する問題をトラブルシューティングする場合:

1. サンプルプロジェクトを作成する:

   ```plaintext
   mkdir issue-25
   cd issue-25
   echo -e "def hello(name)\n\nend" > hello.rb
   ```

1. 次の内容で、`minimal.lua`という名前の新しいファイルを作成します:

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

1. 発生した動作を再現してみてください。必要に応じて、`minimal.lua`またはその他のプロジェクトファイルを調整します。
1. `~/.local/state/nvim/lsp.log`で最近のエントリを表示し、関連する出力をキャプチャします。
1. `glpat-`で始まるトークンなど、機密情報への参照を削除します。
1. Vimのレジスタまたはログファイルから機密情報を削除します。

### エラー: `GCS:unavailable` {#error-gcsunavailable}

このエラーは、ローカルプロジェクトが`.git/config`でリモートを設定していない場合に発生します。

この問題を解決するには、[`git remote add`](../../topics/git/commands.md#git-remote-add)を使用して、ローカルプロジェクトにGitリモートを追加します。
