---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: NeovimでGitLab Duoに接続して使用します。
title: Neovim用GitLabプラグイン - `gitlab.vim`
---

[GitLabプラグイン](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim)は、GitLabとNeovimをインテグレーションするLuaベースのプラグインです。

拡張機能をインストールして設定するには、[インストールとセットアップ](setup.md)を参照してください。

## `gitlab.statusline`を無効にする {#disable-gitlabstatusline}

デフォルトでは、このプラグインは`gitlab.statusline`を有効にします。これは、組み込みの`statusline`を使用して、コード提案インテグレーションのステータスを表示します。`gitlab.statusline`を無効にする場合は、これを設定に追加します:

```lua
require('gitlab').setup({
  statusline = {
    enabled = false
  }
})
```

## `Started Code Suggestions LSP Integration`メッセージを無効にする {#disable-started-code-suggestions-lsp-integration-messages}

最小メッセージレベルを変更するには、これを設定に追加します:

```lua
require('gitlab').setup({
  minimal_message_level = vim.log.levels.ERROR,
})
```

## 拡張機能を更新する {#update-the-extension}

`gitlab.vim`プラグインを更新するには、`git pull`または特定のVimプラグインマネージャーを使用します。

## 拡張機能に関するイシューをレポートする {#report-issues-with-the-extension}

[`gitlab.vim`イシュートラッカー](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues)で、イシュー、バグ、または機能リクエストを報告してください。

`gitlab.vim`リポジトリの[issue 22](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/issues/22)でフィードバックを送信してください。

## 関連トピック {#related-topics}

- [Neovimトラブルシューティング](neovim_troubleshooting.md)
- [ソースコードを表示する](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim)
- [GitLab言語サーバードキュメント](../language_server/_index.md)
