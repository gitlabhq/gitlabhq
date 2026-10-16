---
title: コミット前に新しいファイルをプレビューする
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: create
co_create: true
documentation_link: "../../../user/project/repository/web_editor/#create-a-file"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253963
categories: [ Source Code Management ]
level: secondary
weight: 40
---

新しいファイルページに**書き込み**タブと**プレビュー**タブが追加されました。これは編集ページに以前から備わっているタブと同じもので、最初のコミットが存在する前にMarkdownまたはAsciiDocファイルがどのようにレンダリングされるかを確認できます。プレビューは編集内容に追従します。編集中にファイルを`.txt`から`.md`に名前変更するとレンダラーが切り替わり、Markdownから別の形式に名前変更するとライブプレビューが停止します。スニペットにもMarkdownライブプレビューが追加され、エディタの右クリックメニューから利用できます。

この貢献をしてくださった[skkzsh](https://gitlab.com/skkzsh)さんに感謝します！
