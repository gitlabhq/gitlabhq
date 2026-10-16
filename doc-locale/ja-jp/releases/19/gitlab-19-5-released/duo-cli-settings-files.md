---
title: "設定ファイルを使用してGitLab Duo CLIを設定する"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli/settings/"
work_item: https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/work_items/2126
categories: [ Duo CLI ]
level: secondary
weight: 50
---

設定ファイルを使用して、自分自身または組織全体のためにGitLab Duo CLIを設定できるようになりました。

設定ファイルには、`/settings`パネルで行った選択内容が保存されます。ファイルを直接編集したり、コンテナイメージ内などに事前に作成したりすることも可能です。

システム管理者は、モバイルデバイス管理ツールやグループポリシーを使用して、管理対象の設定ファイルを各マシンにデプロイできます。管理対象ファイルの設定は、通常の設定ファイル、コマンドラインオプション、および環境変数よりも優先されるため、ユーザーはこれらの設定を変更できません。管理対象ファイルに含まれていない設定は、引き続きユーザーが管理できます。

設定ファイルを使用するにはGitLab Duo CLI 9.26.0以降が必要で、管理対象の設定ファイルを使用するにはGitLab Duo CLI 9.27.0以降が必要です。
