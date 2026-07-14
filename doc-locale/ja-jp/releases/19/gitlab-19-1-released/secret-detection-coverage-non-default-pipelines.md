---
title: フィーチャーブランチパイプラインにおけるシークレット検出カバレッジの改善
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: application_security_testing
documentation_link: "../../../user/application_security/secret_detection/pipeline/#coverage"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/588910
categories: [ Secret Detection ]
level: primary
---

<!-- categories: Secret Detection -->

GitLab 19.1より前のバージョンでは、フィーチャーブランチパイプラインがブランチ内のすべてのシークレットを検出できるとは限りませんでした。新しいブランチでは最新のコミットのみがスキャンされ、既存のブランチでは直近のプッシュのみがスキャンされていました。そのため、以前のコミットで漏洩した認証情報が検出されないまま、共有ブランチや本番環境に到達してしまう可能性がありました。

GitLab 19.1では、修正コストが最も低い段階でシークレットを検出できるようになりました。シークレット検出がデフォルトブランチとの分岐点から最新のコミットまで、ブランチ上のすべてのコミットをスキャンします。これにより、後の段階へのシークレットの漏洩を減らし、露出した認証情報をあとから交換する手間を省き、すべてのブランチで一貫した予測可能なカバレッジを実現します。
