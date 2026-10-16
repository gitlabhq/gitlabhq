---
title: GitLab Duoでレビュアーを推薦する
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
documentation_link: "../../../user/project/merge_requests/reviews/automatic_reviewer_assignment/#recommend-reviewers-flow"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/20711
categories: [ DAP Code Review ]
level: secondary
weight: 50
---

以前のバージョンのGitLabでは、各承認ルールを確認してマージリクエストをレビューする時間がある人を推測する必要がありました。あるいは、グループ全体を割り当てて誰かが対応してくれることを期待するしかありませんでした。

Recommend Reviewers Flowを使用することで、レビュアーを提案できるようになりました。このフローは一般提供（GA）となっています。

各承認ルールに対して、空き状況、ワークロード、タイムゾーン、最近のアクティビティに基づき、必要な最小人数のレビュアーが推薦されます。

推薦されたレビュアーはマージリクエストのサイドバーの**推薦**セクションに表示されます。ユーザーにカーソルを合わせると、推薦された理由を確認できます。

開始するには、トップレベルグループでフローを有効にしてください。フローはマージリクエストの作成時に実行されます。また、ドラフトが準備完了としてマークされたときに実行されるトリガーを作成することもできます。新しい推薦を取得するには、**更新**を選択してください。
