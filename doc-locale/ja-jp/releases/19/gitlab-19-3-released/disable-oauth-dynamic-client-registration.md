---
title: MCPのOAuth動的クライアント登録を無効化
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: "../../../administration/settings/account_and_limit_settings/#oauth-dynamic-client-registration"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/601438
categories: [ System Access ]
level: secondary
weight: 50
---

以前は、MCPクライアントやAIツールが動的クライアント登録（DCR）を通じてインスタンスにOAuthアプリケーションを自動登録できましたが、この機能を無効化する手段がありませんでした。そのため、GitLab Self-ManagedおよびGitLab Dedicatedインスタンスの管理者は、接続を許可するOAuthクライアントを制御することが困難でした。

現在は、アプリケーション設定APIを使用してDCRを完全に無効化できるようになり、インスタンスへのアクセスを許可するOAuthクライアントを完全に制御できます。DCRを無効化すると、クライアントは自動登録の代わりに事前登録済みのOAuthアプリケーションを使用する必要があります。
