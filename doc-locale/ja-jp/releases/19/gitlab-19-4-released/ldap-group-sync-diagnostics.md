---
title: LDAPグループ同期の失敗を診断する
tier: [ Premium, Ultimate ]
offering: [ self_managed ]
stage: software_supply_chain_security
co_create: true
documentation_link: "../../../administration/auth/ldap/#ldap-sync-configuration-settings"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250622
categories: [ System Access ]
level: secondary
weight: 10
---

LDAPグループの同期が失敗した場合、その原因が通知されるようになりました。失敗はグループに対して記録され、原因となったメンバーが（最大5名まで）表示されます。また、グループメンバーページに危険アラートが表示されるため、メールドメイン制限によってブロックされた同期もUIから診断できます。新しい`group_filter`設定により、LDAPエントリのうちグループとして扱う対象を絞り込めるようになりました。監査ログでも、これまで1つのエントリとして記録されていた原因が区別されるようになりました。具体的には、LDAPグループリンクの作成・削除、およびLDAP同期によってブロックされたユーザーが、それぞれ独自の監査イベントタイプとして記録されます。

これらのコントリビュートをいただいた[Sergey Pechenko](https://gitlab.com/tnt4brain)さんに感謝します
（[MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/250622) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253816) [MR 3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/252957) [MR 4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247146)）！
