---
title: 脆弱性の詳細における、より明確でセキュリティ業界標準に準拠したラベル
stage: application_security_testing
weight:  
level: secondary
tier: ultimate
offering: [ gitlab_com, self_managed, gitlab_dedicated ] 
documentation_link: "../../../user/application_security/vulnerabilities/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/21978"
---

<!-- categories: Vulnerability Management -->

GitLab 19.1では、脆弱性の結果の詳細ページで、スキャン結果について、一貫性があり、わかりやすく、セキュリティ業界標準に準拠した用語が使用されるようになりました:

- **スキャナー**は**検出元**になりました
- **EPSS**は**悪用される可能性（EPSS）**になりました
- **既知の悪用された脆弱性（KEV）**は**悪用が確認済み（CISA KEV）**になりました
- **到達可能**は**到達可能性**になりました
- **イメージ**は**コンテナイメージ**（コンテナスキャン）になりました
- **場所**は**影響を受ける場所**になりました
- **URL**は**影響を受けるエンドポイント**（DAST、APIファジング）になりました
- **メソッド**は**HTTPメソッド**（DAST、APIファジング）になりました
- **解決策**は**修正ガイダンス**になりました
- **リンク**は**参照**になりました
