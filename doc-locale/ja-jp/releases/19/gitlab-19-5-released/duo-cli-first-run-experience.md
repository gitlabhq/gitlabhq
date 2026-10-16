---
title: "GitLab Duo CLIのファーストラン体験の改善"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli/use/#startup-cards"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22187
categories: [ Duo CLI ]
level: secondary
weight: 50
---

GitLab Duo CLIは、ターミナルを離れることなく新規ユーザーがすぐに使い始められるよう支援します。

- 初回起動時に、オンボーディングカードが表示され、MCPサーバーへの接続とGitLabプラグインのインストールをガイドします。
- 新しいセッションを開始するたびに、オープン中のマージリクエストやイシューから提案されたプロンプトが表示されます。
  マージリクエストのプロンプトでは、ソースブランチが存在する場合、GitLab Duoが最初にそのブランチをチェックアウトします。
- ステータスバーには、ブランチ、プロジェクト、マージリクエスト、`/goal`の進捗状況、およびMCPのステータスが表示されます。
- セットアップ画面では、トークンの作成ページへのリンクが提供され、保存前にトークンの検証が行われます。
- プロンプト内のヒントと`/whatsnew`コマンドで、新機能を確認できます。

すべての機能を利用するには、GitLab Duo CLI 9.28.0以降にアップデートしてください。
