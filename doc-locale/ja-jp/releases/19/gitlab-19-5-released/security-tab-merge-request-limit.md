---
title: マージリクエストのセキュリティレポート比較の精度向上
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: security_risk_management
documentation_link: "../../../user/project/merge_requests/reports/#security-scan-report"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/628421
categories: [ Vulnerability Management ]
---

以前のバージョンのGitLabでは、スキャンで特定の重大度の検出結果が25件を超えた場合、セキュリティレポートは各パイプラインから25件のみを比較していました。そのため、変更のない検出結果が新規または修正済みとして表示されることがありました。

今回のリリースで、レポートは重大度ごとに最大1,000件の検出結果を比較できるようになり、新規および修正済みのリストの精度が向上しました。
