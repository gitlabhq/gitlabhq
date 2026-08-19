---
title: GitLab Duoのグループレベルのカスタムレビュー指示
stage: ai-powered
level: primary
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/gitlab_duo/customize_duo/review_instructions/#configure-custom-review-instructions-for-a-group"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/21504"
categories: [ Duo Code Review ]
add_ons: [ GitLab Duo Enterprise ]
weight: 10
---

以前のバージョンのGitLabでは、GitLab Duoのカスタムレビュー指示はプロジェクトレベルでのみ定義できました。同じグループ内の複数のプロジェクトにまたがって作業するチームは、すべてのプロジェクトに同じ指示を重複して設定する必要がありました。

グループ全体とそのサブグループに対して、共有カスタムレビュー指示を設定できるようになりました。

グループ内のプロジェクトをテンプレートとして選択します。GitLab Duoがコードレビューを実行する際、グループレベルの`.gitlab/duo/mr-review-instructions.yaml`ファイルと個々のプロジェクトで定義された指示が組み合わされます。

コードレビューフローとGitLab Duoコードレビューの両方で、グループレベルのカスタム指示をサポートしています。
