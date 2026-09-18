---
title: 高度なSASTにKotlin、Dart、Scalaの言語サポートが追加されました
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: application_security_testing
documentation_link: ../../../user/application_security/sast/gitlab_advanced_sast/#supported-languages
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/23383
categories: [ SAST ]
level: primary
---

高度なSASTは、Java、Python、その他のサポート対象言語と同様の深いテイント解析を、Kotlin、Dart、Scalaのコードベースにも適用できるようになりました。いずれも、言語ごとのフロントエンドとフレームワーク対応のルールゲーティングを備えたソフトウェアファクトリーアーキテクチャを通じて提供されます。

- Kotlinの検出は、Android APIを対象に、SQLインジェクション、安全でないWebViewの使用、OSコマンドインジェクション、ハードコードされた認証情報、および脆弱な暗号化を検出します。
- Dartの検出には、FlutterおよびDioフレームワーク検出器が含まれており、SSRF、パストラバーサル、コマンドインジェクション、および平文HTTPを対象とします。
- Scalaの検出は、Play、Slick、AkkaフレームワークにおけるSQLインジェクション、SSRF、オープンリダイレクト、パストラバーサル、コマンドインジェクション、およびXSSをカバーします。

これら3つの追加機能はいずれも、意図的に脆弱化された実際のコードリポジトリを使用して検証されており、検出結果はソースからシンクへのコードフローとして報告されます。
