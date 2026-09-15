---
title: エージェントプラットフォームのリモートフローに対する管理者定義のネットワークアクセス制御
stage: ai-powered
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/duo_agent_platform/environment_sandbox/#configure-a-network-policy"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/593149"
categories: [ Duo Agent Platform ]
weight: 110
---

管理者は、GitLab Duo Agent Platformのリモートフローに対する一元的なネットワークポリシーを、設定画面から直接定義できるようになりました。GitLab.comのトップレベルグループ管理者、およびGitLab Self-ManagedとDedicatedのインスタンス管理者は、組織全体のドメイン拒否リストと許可リストを設定でき、プロジェクトはこれらを自動的に継承します。また、プロジェクトがカスタムエントリで承認済みドメインリストを拡張できるかどうかを制御する追加設定も用意されています。ポリシーはすべてのリモートフローにわたってランタイムで適用されるため、セキュリティチームとプラットフォームチームはエージェントのネットワークエグレスに対して一貫したガバナンスレイヤーを確保できます。
