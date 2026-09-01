---
title: ブランチ名に作成者名を追加可能に
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: create
co_create: true
documentation_link: "../../../user/project/repository/branches/#configure-default-pattern-for-branch-names-from-issues"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247356
categories: [ Source Code Management ]
level: secondary
---

新しい `%{branch_creator}` 変数をブランチ名テンプレートに含めることができるようになりました。これにより、イシューから作成されたブランチに作成者を識別する情報を含めることができ、汎用的な名前にフォールバックする必要がなくなります。

このコントリビュートをいただいた [Radek Antoniuk](https://gitlab.com/rantoniuk) さんに感謝します！
