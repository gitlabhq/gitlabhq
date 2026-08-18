---
title: セキュリティレビューフロー（ベータ版）
stage: ai-powered
level: primary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/security_review/"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/600477"
categories: [ DAP Code Review ]
---

<!-- DAP Code Review -->

セキュリティレビューフローは、マージリクエスト内のビジネスロジックの脆弱性を直接検出します。既知のパターンをスキャンする静的解析ツールとは異なり、セキュリティレビューフローはコードの意図を推論し、パターンベースのスキャナーが見落としがちな認可のバイパス、データの露出、ロジックエラーを特定します。

レビューをリクエストするには、マージリクエストのレビュアーとして **Duo Security Review** サービスアカウントを割り当てます。フローは差分を分析し、脆弱性が発生している正確な行にスレッド形式のコメントとして結果を投稿します。各コメントには、Common Weakness Enumeration（CWE）の分類、重大度の評価、および可能な場合はマージリクエストを離れることなく適用できるインラインの修正候補が含まれます。

各レビューは、マージリクエストの差分の複雑さに基づいてGitLabクレジットを消費します。
