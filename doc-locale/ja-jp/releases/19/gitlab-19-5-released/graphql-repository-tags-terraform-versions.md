---
title: GraphQLにおけるリポジトリタグとTerraformステート
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: create
co_create: true
documentation_link: "../../../api/graphql/reference/#repositorytags"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255229
categories: [ Source Code Management ]
level: secondary
weight: 40
---

GraphQLに`Repository.tags`が追加されました。前方ページネーション、検索、および名前・更新日時・バージョン順の並び替えに対応した`TagSort` enumをサポートし、1ページあたり最大100件のタグを取得できます。`Repository.tags`はGitLab 19.5における実験的機能です。`TerraformState.versions`はステートのバージョン一覧を新しい順に返します。マージリクエストREST APIは、単一レスポンスおよびリストレスポンスの両方で`author.bot`を返すようになりました。これにより、Users APIへの追加呼び出しなしに、ボットとサービスアカウントの作成者を区別できます。

以下のユーザーのコントリビュートに感謝します！

- [Jeston Singh](https://gitlab.com/sjestonsingh) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255229) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255230))
- [Ivane Gkomarteli](https://gitlab.com/ivane_gkomarteli) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256381))
