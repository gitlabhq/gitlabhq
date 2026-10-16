---
title: REST APIからの自動マージのキャンセル
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
co_create: true
documentation_link: "../../../api/merge_requests/#cancel-auto-merge"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255702
categories: [ Code Review Workflow ]
level: secondary
weight: 20
---

`cancel_auto_merge` APIエンドポイントを使用して、アクティブな自動マージをキャンセルできるようになりました。
マージリクエストがマージトレインに含まれている場合、この呼び出しによってマージトレインからも削除されます。
従来の`cancel_merge_when_pipeline_succeeds`エンドポイントは非推奨となりました。

また、ターゲットブランチにマージできない場合、`git push -o merge_request.auto_merge`はリモートメッセージとともに拒否されるようになりました。以前のバージョンのGitLabでは、自動マージが記録されたまま残り、キャンセルするまでマージリクエストがマージ不可の状態になっていました。

これらのコントリビュートをいただいた以下のユーザーの皆さんに感謝します！

- [José M. Requena Plens](https://gitlab.com/jmrp) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255702) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255704))
- [Bobby Nandigam](https://gitlab.com/bobby-nandigam) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251960))
