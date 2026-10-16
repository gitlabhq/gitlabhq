---
title: LDAPでブロックされたユーザーをオンデマンドで再同期する
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: security_platform
co_create: true
documentation_link: "../../../administration/moderate_users/#resync-a-user-blocked-by-ldap"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255974
categories: [ System Access ]
level: secondary
weight: 10
---

管理者は、管理者エリアの**ユーザー**ページから、LDAPでブロックされた単一のユーザーを再同期できるようになりました。
新しい**LDAPと再同期**アクションはLDAPアクセスチェックを実行し、LDAPがアクセスを許可する場合はユーザーのブロックを解除し、許可しない場合はユーザーをブロックしたままにします。ユーザーにLDAPのIDがない場合、アクションはメッセージとともに拒否されます。以前のバージョンのGitLabでは、LDAPでブロックされたアカウントは、日次ユーザー同期が実行されるか、ユーザーがサインインするまでブロックされたままでした。サービスアカウントはサインインできないため、この制限が問題となっていました。

この機能への貢献に対して、[Sergey Pechenko](https://gitlab.com/tnt4brain)さんに感謝します（[MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255974)）。
