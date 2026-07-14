---
title: GitLab Duoの常時オン可用性モード
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: software_supply_chain_security
documentation_link: "../../../user/gitlab_duo/turn_on_off/#lock-gitlab-duo-on-for-all-users"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/22382
categories: [ AI Abstraction Layer ]
level: primary
---

<!-- categories: AI Abstraction Layer -->

管理者は、インスタンス全体またはトップレベルグループのすべてのプロジェクトに対して、GitLab Duoを常時オンに設定できるようになりました。GitLab Duoを常時オンに設定すると、グループ、サブグループ、およびプロジェクトのオーナーはGitLab Duoをオフにできなくなり、コンプライアンスや規制対象環境に向けた一元的なAIガバナンスを企業に提供します。

この新しい設定は、既存の[常にオフ](../../../user/gitlab_duo/turn_on_off.md)設定と対称的な関係にあり、GitLab Duoをロックオフできてもロックオンできなかったというギャップを解消します。この設定は特に、ビジネス全体で一貫したAIツールの利用を保証する必要がある、自律的な部門や子会社を持つ組織にとって有用です。

GitLab Duoを常時オンに設定するには、インスタンスまたはトップレベルグループのGitLab Duo設定に移動し、**GitLab Duoの可用性**を**常にオン**に設定してください。
