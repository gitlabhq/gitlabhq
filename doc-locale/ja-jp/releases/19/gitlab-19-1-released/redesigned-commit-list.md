---
title: リポジトリのコミットリストを再設計
stage: create
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/project/repository/commits/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/17482"
categories: [ Source Code Management ]
---

<!-- categories: Source Code Management -->

これまで、リポジトリのコミットリストはフィルタリング機能が限られており、長い履歴の中から特定のコミットを見つけることが困難でした。

再設計されたコミットリストには、以下の機能が含まれています。

- 作成者、コミットメッセージ、または日付範囲によるコミットのフィルタリングと検索
- ブランチ、タグ、コミットSHAなどのGitリビジョンによるリストのフィルタリング
- 日付ごとにグループ化されたコミット表示による視認性の向上
- 大規模リポジトリに対するパフォーマンスとページネーションの改善
