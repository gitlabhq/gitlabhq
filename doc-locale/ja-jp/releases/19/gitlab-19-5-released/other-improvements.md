---
title: その他の改善
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
co_create: true
documentation_link: "../../../user/model_context_protocol/mcp_server_troubleshooting/#error-rate_limited-tool-result"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256657
categories: [ Agent Tools ]
level: secondary
weight: 80
---

このリリースにおけるその他の改善点は以下のとおりです。

- GitLab MCPサーバー: レート制限されたツール結果に制限名と再試行の遅延時間が表示されるようになりました。`add_branch` はブランチの `web_url` を返し、有効化ツールヘッダー内のツールエイリアスが解決され、URLとプロジェクトIDの入力が一致しない場合は拒否されるようになりました。また、`ai_workflows` トークンでバッチ処理でblobを読み取れるようになりました。
- 管理者モードの管理者は、プロジェクトに参加せずに環境にクラスターエージェントを設定できるようになりました。
- `CI_JOB_TAGS` と `CI_RUNNER_TAGS` は各タグをJSONエンコードします。プッシュオプションで重複した変数キーは拒否されます。
- 高度なSAST（Ultimate）: 最大20階層の深さのCおよびC++ファイルがスキャンされ、レポートはアーティファクトの保持設定に従います。
- プレーンテキストのトークンおよびSSHキーのメールが正しいページにリンクされるようになりました。また、`?scopes=` リンクでトークンフォームが事前入力されます。

これらのコントリビュートをいただいた以下のユーザーの皆様に感謝いたします。

- [otutukingsley](https://gitlab.com/otutukingsley) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256657))
- [Jeston Singh](https://gitlab.com/sjestonsingh) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255143) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255111) [MR 3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255142) [MR 4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253823) [MR 5](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254734) [MR 6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254613))
- [ryo-whaletech](https://gitlab.com/ryo-whaletech) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254573) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256563) [MR 3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256718))
- [Mohamed Elsayed](https://gitlab.com/MooSayed11) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256268))
- [Gerardo Navarro](https://gitlab.com/gerardo-navarro) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169626))
- [Torben Buck](https://gitlab.com/torben.buck) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254859) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255638) [MR 3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254871))
