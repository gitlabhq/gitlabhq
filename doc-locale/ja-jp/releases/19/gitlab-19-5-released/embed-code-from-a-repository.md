---
title: Markdownでリポジトリのコードを埋め込む
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: plan
documentation_link: "../../../user/markdown/#embed-code-from-a-repository"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/300855
categories: [ Markdown ]
level: secondary
weight: 50
---

以前のバージョンのGitLabでは、ファイルの行への[permalink](../../../user/project/repository/files/_index.md#create-permalinks)はプレーンなURLとして表示されていたため、参照先のコードを確認するにはマージリクエスト、イシュー、またはWikiページから離れる必要がありました。

今回のリリースで、permalinkはファイルパスとコミット情報付きのシンタックスハイライト済みスニペットとして表示されるようになりました。これにより、ページを離れることなくコードを確認できます。なお、埋め込みスニペットを表示するには、対象リポジトリへの読み取りアクセス権が必要です。
