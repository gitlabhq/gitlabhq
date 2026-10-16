---
title: マージリクエストウィジェットがより具体的な情報を表示するようになりました
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_coding
co_create: true
documentation_link: "../../../user/project/merge_requests/widgets/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251657
categories: [ Code Review Workflow ]
level: secondary
weight: 20
---

GitLabがマージリクエストを確認している間、ウィジェットにその状態が表示されるようになりました。確認が完了するまで、**マージコンフリクトを解決する必要があります**という表示が**マージコンフリクトを確認中**に変わります。リベースが拒否された場合は、汎用的な再試行プロンプトではなく、**ソースブランチは強制プッシュから保護されています**のような具体的な理由が表示されます。これにより、マージリクエストの現在の状態に応じて適切な操作を行えます。

マージリクエストのスクロール中も表示され続けるスティッキータイトルバーも、ドラフトまたは準備完了としてマークした際に、ページを更新しなくても即座に更新されるようになりました。

これらのコントリビュートをいただいた以下のユーザーの皆さんに感謝します！

- [Amartya Mishra](https://gitlab.com/Gamezordd) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253806) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251657))
- [Gerardo Navarro](https://gitlab.com/gerardo-navarro) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252050))
- [Mahaveer A](https://gitlab.com/Mahaveer1013) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251290))
