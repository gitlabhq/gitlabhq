---
title: 依存関係スキャンにおける悪意のあるパッケージの検出（ベータ版）
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: application_security_testing
documentation_link: ../../../user/application_security/gitlab_advisory_database/
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/606037
categories: [ Software Composition Analysis ]
level: secondary
---

以前のバージョンのGitLabでは、依存関係スキャンは既知のCVEを持つパッケージのみを検出していました。タイポスクワッティング、メンテナーアカウントの侵害、または埋め込みマルウェアによって害を与えるように作られた悪意のあるパッケージは、検出結果に表示されませんでした。

GitLab 19.4では、悪意のあるパッケージの検出がベータ版として導入されました。依存関係スキャンが[GitLabマルウェアアドバイザリ](../../../user/application_security/gitlab_advisory_database/_index.md#gitlab-malware-advisories)に対して依存関係を確認するようになり、広く知られる前に脅威を検出できます。検出結果は依存関係リストと脆弱性レポートに赤い**マルウェア**バッジで表示され、常にCritical重大度で、CVEではなく`GLAM-` IDで識別されます。

マージリクエスト承認ポリシーの[マルウェアルール](../../../user/application_security/policies/merge_request_approval_policies.md#block-malicious-packages-with-the-malware-rule)を使用して、悪意のあるパッケージがマージされる前にブロックすることもできます。

追加のセットアップは不要です。[サポートされているパッケージタイプ](../../../user/application_security/gitlab_advisory_database/_index.md#supported-package-types)（npm、PyPI、Maven、Go、NuGet、Cargo、RubyGems）に対してカバレッジが適用されます。同じアドバイザリが[継続的な脆弱性スキャン](../../../user/application_security/continuous_vulnerability_scanning/_index.md#malicious-packages)にも使用され、[オフラインインスタンス](../../../topics/offline/quick_start_guide.md)では手動でダウンロードできます。

[イシュー606036](https://gitlab.com/gitlab-org/gitlab/-/work_items/606036)でフィードバックをお寄せください。
