---
title: レビューを送信してレビュアーになる
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
co_create: true
documentation_link: "../../../user/project/merge_requests/reviews/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250880
categories: [ Code Review Workflow ]
level: secondary
weight: 60
---

まだレビュアーになっていないマージリクエストに対して、**コメント**、**承認**、または**変更をリクエスト**でレビューを送信すると、GitLabが自動的に**レビュアー**リストに追加するようになりました。レビュードロワーには事前に「レビュアーとして追加されます」と表示されます。これにより、レビュアーリストと実際にレビューに参加したメンバーが乖離することがなくなります。この動作は、機能フラグが削除されたGitLab 19.4から利用可能です。

このコントリビュートをいただいた[Michael Fischer](https://gitlab.com/mfischer5)さんに感謝します（[MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250880)）。
