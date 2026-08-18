---
title: CI/CDパイプライン修正フローによるターゲットを絞った修正の提案
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/fix_pipeline"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21837
categories: [ Continuous Integration (CI) ]
level: secondary
weight: 10
---

GitLab DuoのCI/CDパイプライン修正フローに、2つの主要な改善が加わりました。

- マージリクエストの差分に関連ファイルが既に含まれている場合、そのマージリクエストに対してコード提案として直接修正が提示されます。
- フローがパイプラインの失敗を分類してから対処するため、より的を絞った診断が得られます。

また、フローはパイプライン階層全体にわたって子パイプラインの失敗を分析し、`AGENTS.md`ファイルを使用してプロジェクトに合わせた動作のカスタマイズが可能になりました。さらに、マージリクエストのコメントをすっきり保つため、AIの推論プロセスはデフォルトで折りたたまれて表示されます。

フィードバックは[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/601991)にお寄せください。
