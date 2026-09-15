---
title: GitLab Duo CLIプラグインとマーケットプレイス（実験的機能）
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli/customize/#plugins"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22497
categories: [ Duo CLI ]
level: secondary
weight: 50
---

GitLab Duo CLIは、GitLab Duo CLI 9.10.0で導入された実験的機能として、プラグインとプラグインマーケットプレイスをサポートするようになりました。プラグインは、エージェントスキル、カスタムスラッシュコマンド、およびModel Context Protocol（MCP）サーバーを1つのディレクトリにまとめたものです。マーケットプレイスは、Gitリポジトリまたはローカルディレクトリでホストされる、利用可能なプラグインのカタログです。

GitLab Duo CLIは、プラグインを初めて使用する際に、公式の`gitlab-duo-plugins`マーケットプレイスを自動的に登録します。

マーケットプレイスには、一般的なGitLabワークフロー向けの3つのスキルが含まれています。

- `mr-review`: マージリクエストをレビューし、コメントを投稿します。
- `stack-changes`: 大規模なローカル変更をスタックされたマージリクエストチェーンに分割します。
- `create-issue`: 自然言語による説明からGitLabイシューの下書きを作成します。

スキルをインストールするには、セットアップに応じて`glab duo cli plugin install <plugin>@gitlab-duo-plugins`または`duo plugin install <plugin>@gitlab-duo-plugins`を実行してください。

既存のコミュニティプラグインエコシステムとの互換性を確保するため、GitLab Duo CLIは`.claude-plugin/marketplace.json`ファイルも読み込みます。これにより、既存のClaude Codeプラグインマーケットプレイスは変更なしでGitLab Duo CLIと連携できます。
