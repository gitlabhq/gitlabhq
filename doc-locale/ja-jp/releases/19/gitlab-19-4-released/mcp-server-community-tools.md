---
title: コミュニティによるGitLab MCPサーバーツール
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
co_create: true
documentation_link: "../../../user/model_context_protocol/mcp_server_tools/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248155
categories: [ Agent Tools ]
level: secondary
weight: 30
---

コミュニティコントリビューターがGitLab MCPサーバーに新しいツールを追加しました。エージェントは、`get_project`と`list_project_members`を使用してプロジェクトのメタデータとメンバーを取得したり、`list_branches`でリポジトリのブランチを一覧表示したり、`list_merge_requests`でグループ全体のマージリクエストを一覧表示できるようになりました。`get_duo_session`はGitLab Duoセッションをフェッチするため、以前の実行内容を確認できます。

これらのツールは19.4の他の新しいGitLab MCPサーバーツールと合わせて提供され、同じツールガバナンスのもとで動作します。そのため、これらのツールを使用するエージェントは、チームがすでに設定したルールに従います。

以下のユーザーのコントリビュートに感謝します！

- [Dhairya Majmudar](https://gitlab.com/DhairyaMajmudar) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248155) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250316))
- [Giannis Kepas](https://gitlab.com/gkepas) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250430) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251379))
- [Mahaveer A](https://gitlab.com/Mahaveer1013) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252619))
