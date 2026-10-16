---
title: AIフローがデフォルト以外のブランチでサポートされるようになりました
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/application_security/vulnerability_report/#tracked-ref-filter"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/23297
categories: [ Vulnerability Management ]
---

以前のバージョンのGitLabでは、SAST誤検出判定フロー、SAST脆弱性の修正フロー、およびシークレット誤検出判定フローは、デフォルトブランチの脆弱性に対してのみ実行できました。

今回のリリースで、脆弱性レポートから他のトラッキング対象ブランチの脆弱性に対してもこれらのフローを実行できるようになりました。マージ前に脆弱性を分析・解決するために活用できます。
