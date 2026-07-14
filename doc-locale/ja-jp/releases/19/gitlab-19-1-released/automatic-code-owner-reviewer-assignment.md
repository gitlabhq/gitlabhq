---
title: コードオーナーをレビュアーとして自動的に割り当て
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
stage: create
documentation_link: "../../../user/project/merge_requests/reviews/automatic_reviewer_assignment"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/20708
categories: [ Code Review Workflow ]
level: primary
---

<!-- categories: Code Review Workflow -->

これまでは、`CODEOWNERS`ファイルで各ファイルのレビュー担当者がすでに定義されている場合でも、マージリクエストごとにレビュアーを手動で選択する必要がありました。

プロジェクトを設定することで、コードオーナーをレビュアーとして自動的に割り当てられるようになりました。GitLabは、変更されたファイルに一致するすべてのコードオーナーを割り当てます。この割り当ては、マージリクエストが準備完了状態で作成されたとき、またはドラフトが準備完了としてマークされたときに行われます。すでにレビュアーを割り当てている場合、GitLabは自動割り当てをスキップし、その選択を維持します。

レビュアーの自動割り当てを有効にするには、**設定** > **マージリクエスト** > **レビュアーの自動割り当て**に移動し、**すべてのコードオーナーをレビュアーとして自動的に割り当てる**を選択します。
