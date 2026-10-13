---
title: "GitLab Duo CLIの/goalコマンド"
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli/use/#slash-commands"
work_item: https://gitlab.com/groups/gitlab-org/ai-powered/-/work_items/10
categories: [ Duo CLI ]
level: secondary
weight: 50
---

GitLab Duo CLIに`/goal`スラッシュコマンドが追加されました。このコマンドは、オープンエンドな目標をローカルで実行される管理された目標駆動型フローに委任します。

目標を記述すると、GitLab Duoが実装と検証を担当します。独立した判定機能により、目標が達成されたか、またはイテレーション上限に達したかを判断します。一時停止、目標の更新、エージェントの方向転換など、常にユーザーが主導権を持ちます。

`/goal`スラッシュコマンドを使用するには、GitLab 19.3以降およびGitLab Duo CLI 9.17.0以降が必要です。

使い始めるには、`/goal <task>`を実行してください。

例:

```plaintext
/goal Fix the failing tests in spec/models/user_spec.rb
```
