---
title: "GitLab Duo CLIの`/goal`コマンドが一般提供開始"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli/use/#slash-commands"
work_item: https://gitlab.com/groups/gitlab-org/ai-powered/-/work_items/10
categories: [ Duo CLI ]
level: secondary
weight: 50
---


GitLab Duo CLIの`/goal`スラッシュコマンドが、GitLab Duo CLI 9.27.0で一般提供を開始しました。

オープンエンドなゴールを記述すると、GitLab Duoがそれをローカルで実行される管理されたゴール駆動型フローに委譲し、実装と検証の両方を処理します。

開始するには、`/goal <タスク>`を実行します。例:

```plaintext
/goal Fix the failing tests in spec/models/user_spec.rb
```

GitLab 19.5（GitLab Duo CLI 9.24.0）では、`/settings`の**提案されたプロンプトを/goalセッションとして実行**設定により、提案されたプロンプトをチャットメッセージではなく`/goal`セッションとして実行できます。

`/goal`を使用するには、GitLab 19.3以降およびGitLab Duo CLI 9.17.0以降が必要です。
