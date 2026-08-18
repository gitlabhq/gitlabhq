---
title: GitLab Duo CLIが一般提供開始
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/19717
categories: [ Duo CLI ]
level: primary
weight: 10
---

GitLab Duo CLIは、GitLab Duo Agent Platformをターミナルから直接利用できるツールです。

CLIを使用して、コードベースに関する複雑な質問を行ったり、ユーザーに代わって自律的にアクションを実行したりできます。
外部ツールとは異なり、CLIはGitLabプロジェクト、パイプライン、エージェント設定に関するコンテキストを保持しています。

主な機能は次のとおりです。

- 2つのモード: インタラクティブチャットモードとCI/CD向けヘッドレスモード
- GitLab Self-ManagedおよびGitLab Dedicated向けの管理者によるオン/オフ制御
- モデルの選択と共有セッション
- ツールの承認
- Model Context Protocol（MCP）接続
- スラッシュコマンド（コンテキストの使用状況確認やコンテキストのコンパクションコマンドを含む）
- スキルおよび`AGENTS.md`カスタマイズファイルのサポート

GitLab Duo CLIは、GitLab CLI（`glab`）経由またはスタンドアロンツールとしてインストールできます。
