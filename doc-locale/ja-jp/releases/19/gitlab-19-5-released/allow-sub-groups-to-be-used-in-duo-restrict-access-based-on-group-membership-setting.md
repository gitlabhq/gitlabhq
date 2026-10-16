---
title: サブグループメンバーシップによるGitLab Duoアクセスの制限
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: security_governance
documentation_link: "../../../administration/gitlab_duo/configure/access_control"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/633488
categories: [ AI Governance ]
level: primary
weight: 50
---

管理者は、GitLab Duoの[**グループメンバーシップに基づいてアクセスを制限**](../../../administration/gitlab_duo/configure/access_control.md)の設定において、トップレベルグループだけでなく、任意のサブグループを選択できるようになりました。グループ階層を再構成することなく、GitLab Duo Agent Platformのアクセスを特定のチームやパイロットグループに限定できます。

以前は、この設定はトップレベルグループのみを受け付けていました。そのため、すべてのユーザーが単一のトップレベルグループに属している組織では、GitLab Duo Agent Platformのアクセスを一部のユーザーに限定するサポートされた方法がありませんでした。

サブグループを選択すると、そのサブグループの直接メンバーがアクセス権を取得します。これにより、GitLab Self-ManagedおよびGitLab DedicatedでGitLab Duo Agent Platformのパイロットを実施したり、部門ごとに段階的にアクセスを展開したりすることが容易になります。
