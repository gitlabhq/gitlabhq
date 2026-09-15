---
title: LDAPグループ同期で監査担当者ロールを管理
tier: [ Premium, Ultimate ]
offering: [ self_managed ]
stage: software_supply_chain_security
co_create: true
documentation_link: "../../../administration/auth/ldap/ldap_synchronization/#assign-an-auditor-role-to-an-ldap-group"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247042
categories: [ System Access ]
level: secondary
---

GitLab Self-ManagedインスタンスのLDAPグループ同期を使用して、監査担当者ロールの付与と失効を自動化できるようになりました。新しい`audit_group`設定でLDAPグループを監査担当者にマップでき、管理者向けの`admin_group`と同様の仕組みで動作します。これにより、監査担当者のアクセス権をディレクトリのメンバーシップに基づいて管理でき、手動での維持が不要になります。

このコントリビュートをいただいた[Sergey Pechenko](https://gitlab.com/tnt4brain)さんに感謝します！
