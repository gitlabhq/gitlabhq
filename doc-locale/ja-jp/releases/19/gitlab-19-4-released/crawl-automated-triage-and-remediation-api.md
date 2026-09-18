---
title: 自動トリアージおよび修正プロファイル（GraphQL API）
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/configuration/security_configuration_profiles/#automated-triage-and-remediation-profile"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/23191
categories: [ Vulnerability Management ]
weight: 50
---

以前のバージョンのGitLabでは、SASTの誤検出検知、GitLab Duoの脆弱性の修正、シークレット検出の誤検出検知、依存関係スキャンの自動修正をプロジェクトごとに個別に有効化する必要がありました。今回のリリースで、自動トリアージおよび修正プロファイルをグループまたはプロジェクトに適用し、重大度と実行モードを一度の操作でまとめて設定できるようになりました。プリセットから始めることも、各フローを個別に設定することも可能です。

- Conservative: オンデマンド、高重大度。
- Standard: 自動、中重大度以上。
- Proactive: 自動、すべての重大度。

プロファイルはGraphQL APIでのみ利用可能で、トップレベルグループでファウンデーショナルフローが有効になっているGitLab Duo Agent Platformが必要です。ほとんどのフローはGitLabクレジットを消費します。
