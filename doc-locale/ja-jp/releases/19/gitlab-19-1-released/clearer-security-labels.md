---
title: 脆弱性詳細のより明確なセキュリティ業界標準ラベル
stage: application_security_testing
level: secondary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/application_security/vulnerabilities/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/21978"
categories: [ Vulnerability Management ]
---

<!-- categories: Vulnerability Management -->

GitLab 19.1では、脆弱性の結果の詳細ページで、スキャン結果に対して一貫性があり、わかりやすく、セキュリティ業界標準に準拠した用語が使用されるようになりました:

| 変更前                    | 変更後                                 | 日本語                          |
| ---------------------- | ----------------------------------- | ---------------------------- |
| Scanner                | Detected by                         | 検出元                          |
| EPSS                   | Exploit Probability（EPSS）           | 悪用可能性スコア（EPSS）               |
| Has Known Exploit（KEV） | Known Exploited（CISA KEV）           | 既知の悪用（CISA KEV）              |
| Reachable              | Reachability                        | 到達可能性                        |
| Image                  | Container Image（Container Scanning） | コンテナイメージ（コンテナスキャン）           |
| Location               | Affected Location                   | 影響を受ける場所                     |
| URL                    | Affected Endpoint（DAST、APIファジング）    | 影響を受けるエンドポイント（DAST、APIファジング） |
| Method                 | HTTP Method（DAST、APIファジング）          | HTTPメソッド（DAST、APIファジング）      |
| Solution               | Remediation Guidance                | 修正ガイダンス                      |
| Links                  | References                          | 参考情報                         |
