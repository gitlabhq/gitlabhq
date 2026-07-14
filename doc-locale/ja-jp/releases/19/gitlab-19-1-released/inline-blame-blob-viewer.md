---
title: blobビューアーのインラインblame
stage: create
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/project/repository/files/git_blame/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/11471"
categories: [ Source Code Management ]
---

<!-- categories: Source Code Management -->

これまでは、blame情報を確認するには別のページに移動する必要があり、コードレビュー中の作業フローが中断されていました。

今回のリリースで、ファイルビューから直接blame情報を切り替えられるようになりました。各行には最終に変更したユーザーが表示され、ホバーするとコミットのポップオーバーで詳細を確認できます。**この変更前のblameを表示**を選択してさらに履歴をたどったり、**特定のリビジョンを無視**を選択してblameビューから特定のコミットを除外したりできます。
