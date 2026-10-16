---
title: 失効したGPG IDはコミットを検証しなくなりました
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: create
co_create: true
documentation_link: "../../../user/project/repository/signed_commits/gpg/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255300
categories: [ Source Code Management ]
level: secondary
weight: 70
---

GitLabは、GPGが失効済みとして報告したユーザーIDを無視するようになりました。失効したIDは、ユーザー設定の**アクセス** > **GPGキー**に表示されなくなり、署名済みコミットの**検証済み**バッジにおける検証済みメールアドレスとしてもカウントされなくなります。失効したIDで署名されたコミットは「同一ユーザー、異なるメールアドレス」または「他のユーザー」に移行し、すべてのIDが失効しているキーは何も検証しません。有効なキーのもとで既に検証済みの署名は再導出されません。

この貢献に対して[José M. Requena Plens](https://gitlab.com/jmrp)さんに感謝します（[MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255300)）！
