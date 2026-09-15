---
title: GitLab Duo Developerによるマージリクエストワークフローの強化
stage: ai-powered
level: primary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/developer/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228817"
categories: [ Duo Agent Platform ]
weight: 40
---

GitLab Duo Developerは、複数のトリガー方法をサポートするようになりました。イシューへの割り当て、**MRを生成**の選択、またはイシューやMRのディスカッションスレッドへの`@mention`を通じて、フィードバック、To-doアイテム、設計上の質問をコード変更、フォローアップMR、またはリサーチサマリーに変換できます。

`AGENTS.md`と`agent-config.yml`を設定することで、GitLab Duo Developerはコミット前にテストとチェックを実行します。トップレベルのグループまたはインスタンスの管理者がデベロッパーフローを有効にすると、GitLabは対象プロジェクトにメンションと割り当てトリガーを自動的に追加します。
