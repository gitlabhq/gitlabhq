---
title: OAuthアクセストークンのカスタム有効期間
tier: [ Free, Premium, Ultimate ]
offering: [ self_managed, gitlab_dedicated ]
stage: software_supply_chain_security
documentation_link: ../../../administration/settings/account_and_limit_settings/#limit-the-lifetime-of-oauth-access-tokens
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/595570
categories: [ System Access ]
level: secondary
weight: 50
---


<!-- categories: System Access -->

デフォルトでは、GitLabのOAuthアクセストークンは2時間後に有効期限が切れます。GitLab 19.1では、GitLab Self-ManagedおよびGitLab Dedicatedのインスタンス管理者が、新しいOAuthアクセストークンのカスタム有効期間を設定できるようになりました。300秒から7200秒の範囲で任意の値を設定できます。これにより、既存のトークンの動作を変更することなく、MCPクライアントを含むセキュリティ上重要なOAuthインテグレーションに対して、有効期間の短いトークンを適用できます。
