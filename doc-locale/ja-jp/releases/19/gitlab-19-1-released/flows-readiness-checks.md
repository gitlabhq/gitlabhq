---
title: 基本フローの準備状況チェック
offering: [ self_managed, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../../administration/gitlab_duo/configure/#run-a-health-check-for-gitlab-duo"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/599536
categories: [ Duo Agent Platform ]
level: secondary
---

<!-- categories: Duo Agent Platform  -->

GitLab Duoのヘルスチェックに、基本フローの準備状況チェックが追加されました。このチェックでは、以下の項目を確認します。

- インスタンスレベルのフロー実行設定が有効になっているか。
- インスタンスレベルの基本フロー設定が有効になっているか。
- `gitlab--duo` タグが付与されたアクティブなインスタンスRunnerが少なくとも1つ登録・接続されており、Docker互換のexecutorを使用しているか。
