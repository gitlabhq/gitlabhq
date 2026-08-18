---
title: Filter exact code search results by repository
stage: ai-powered
level: secondary
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed ]
documentation_link: "../../../user/search/exact_code_search/#syntax"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/488467"
categories: [ Global Search ]
weight: 20
---

You can now filter exact code search results by repository. With the `repo:` syntax,
you can directly scope your search query to specific repositories or repository patterns
without having to go to individual projects.

For example, searching for `def authenticate repo:my-group/my-project` returns results
only from that repository. You can also use partial paths or patterns to match multiple repositories.
