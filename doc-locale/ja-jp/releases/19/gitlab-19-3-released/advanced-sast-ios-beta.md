---
title: iOSの高度なSASTがベータ版として提供開始
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: application_security_testin
documentation_link: "../../../user/application_security/sast/gitlab_advanced_sast"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/22353"
categories: [ SAST ]
level: secondary
---

<!-- Category: SAST -->

GitLab高度なSASTがObjective-CとSwiftをサポートし、他の言語向けに提供してきた手続き間テイント解析をiOS開発にも適用できるようになりました。このベータ版は、GitLab 19.3よりすべてのGitLab Ultimateのお客様にご利用いただけます。

ベータ版では、脆弱なデータストレージ、不正な暗号化、脆弱な通信、認証および認可の欠陥など、OWASP Mobile Top 10の主要な脆弱性クラスを検出します。脆弱性が一方の言語で始まり、もう一方の言語のシンクに到達する場合も、高度なSASTはSwiftとObjective-Cの言語境界をまたぐパスを含む完全なテイントパスを検出します。

有効にするには、パイプラインで`GITLAB_ADVANCED_SAST_ENABLED: 'true'`を設定してください。プロジェクトにObjective-CまたはSwiftのファイルが含まれている場合、`gitlab-advanced-sast-ext`ジョブが自動的に実行されます。セットアップの詳細については、[高度なSASTドキュメント](../../../user/application_security/sast/gitlab_advanced_sast.md)を参照してください。

フィードバックは[ベータ版フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/607091)にてお寄せください。
