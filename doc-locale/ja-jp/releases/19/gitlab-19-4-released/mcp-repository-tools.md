---
title: MCPサーバーリポジトリツール
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/627598
categories: [ Agent Tools ]
level: secondary
weight: 50
---

新しいリポジトリツールにより、エージェントはGitLab MCPサーバーを通じてプロジェクトの構造を参照し、コミット履歴を確認し、変更を提案できるようになりました:

- `list_repository_tree` はファイルツリーを探索します。
- `list_branches` と `list_tags` はrefsを列挙します。
- `list_releases` は公開済みリリースを確認します。
- `get_commit` はコミットのメタデータ、差分、またはノートを取得します。
- `list_commits` はブランチの履歴をページングします。
- `add_commit` は1回の呼び出しで1つ以上のファイル操作をコミットします。特定の開始refまたはソースプロジェクトから新しいブランチへのコミットも可能です。
- `fork_repository` はプロジェクトをフォークします。これにより、エージェントはクライアントを離れることなく、アップストリームリポジトリの探索から変更の提案までをシームレスに行えます。
