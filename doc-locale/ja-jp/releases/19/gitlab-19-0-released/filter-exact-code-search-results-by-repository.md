---
title: 完全一致コードの検索結果をリポジトリでフィルタリング
stage: ai-powered
level: secondary
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed ]
documentation_link: "../../../user/search/exact_code_search/#syntax"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/488467"
categories: [ Global Search ]
weight: 20
---

完全一致コードの検索結果をリポジトリでフィルタリングできるようになりました。`repo:` 構文を使用することで、個々のプロジェクトに移動することなく、特定のリポジトリやリポジトリのパターンに直接検索クエリのスコープを絞り込めます。

たとえば、`def authenticate repo:my-group/my-project` と検索すると、そのリポジトリのみの結果が返されます。また、パスの一部やパターンを使用して、複数のリポジトリに一致させることもできます。
