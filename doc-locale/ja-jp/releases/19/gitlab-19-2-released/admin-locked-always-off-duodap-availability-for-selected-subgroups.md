---
title: サブグループへのGitLab Duo利用可否の選択的設定
tier: [ Ultimate ]
offering: [ gitlab_dedicated, gitlab_dedicated_for_government ]
stage: software_supply_chain_security
documentation_link: "../../../user/gitlab_duo/turn_on_off/#lock-gitlab-duo-off-for-selected-subgroups"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22389
categories: [ AI Agents ]
level: primary
weight: 50
---

GitLab Dedicatedインスタンスの管理者は、特定のサブグループに対してGitLab DuoおよびGitLab Duo Agent Platformを利用不可に設定しながら、他のサブグループでは引き続き有効化できるようにすることが可能です。

これまでは、インスタンス全体でGitLab DuoとAgent Platformを無効化するか、すべてのサブグループで利用可能にするかのいずれかしか選択できませんでした。

今回のリリースで、デフォルト拒否のサブグループ単位の許可リストを適用できるようになりました。特定のサブグループを**常にオフ（ロック済み）**に設定すると、その子孫グループおよびプロジェクトではGitLab DuoとAgent Platformを有効化できなくなります。一方、他のサブグループについてはオーナーロールを持つユーザーの判断に委ねることができます。ロックの適用・解除は管理者のみが行え、影響を受けるオーナーには、GitLab Duoが親グループによってロックされている旨のメッセージが明確に表示されます。

この機能は、コンプライアンスおよびプラットフォームガバナンスチームが厳格なデータ分類要件を満たすうえで役立ちます。
