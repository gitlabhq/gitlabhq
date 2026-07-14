---
title: UIのスタックマージリクエスト
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Free, Premium, Ultimate ]
stage: create
documentation_link: "../../../user/project/merge_requests/reviews/stacked_merge_requests"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22211
categories: [ Code Review Workflow ]
level: secondary
---

<!-- categories: Code Review Workflow -->

これまで、大きな変更を相互に依存する小さなマージリクエストに分割した場合、UIにはそれらの関連性を示す情報が表示されませんでした。作成者とレビュアーは、順序を手動で追跡する必要がありました。

GitLabはスタックされたマージリクエストを自動的に検出し、マージリクエストのヘッダーに表示するようになりました。マージリクエストが別のオープン中のマージリクエストのソースブランチをターゲットにしている場合、またはオープン中の別のマージリクエストがそのソースブランチをターゲットにしている場合、そのマージリクエストはスタックに追加されます。ソースブランチの横にあるスタックコントロールには現在の位置（例: **2件中1件目**）が表示され、スタック内の任意のマージリクエストにジャンプできます。

コマンドラインからスタックされたマージリクエストを作成するには、GitLab CLIのスタックされた差分を使用してください。
