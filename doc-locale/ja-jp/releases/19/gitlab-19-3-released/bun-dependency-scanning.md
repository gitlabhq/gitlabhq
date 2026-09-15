---
title: "Bunへの依存関係スキャンサポート"
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: application_security_testing
documentation_link: "../../../user/application_security/dependency_scanning/dependency_scanning_sbom/#supported-languages-and-files"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/592701
categories: [ Software Composition Analysis ]
level: secondary
---

以前のバージョンのGitLabでは、BunのJavaScriptランタイムおよびパッケージマネージャーを使用するプロジェクトには依存関係スキャンのカバレッジがありませんでした。

今回のリリースで、GitLabの依存関係スキャンが`bun.lock`ファイル（Bun 1.2で導入されたテキストベースのJSONCフォーマット）を解析することでBunプロジェクトを分析できるようになりました。

Bunパッケージはnpmレジストリから取得されるため、GitLabのアドバイザリデータベースはすでにこれらの依存関係をカバーしており、追加の設定は不要です。npm、yarn、またはpnpmの代替としてBunを使用しているチームは、標準のCI/CDパイプラインの一部としてプロジェクトの既知の脆弱性をスキャンできるようになりました。対象となる検出結果は、依存関係スキャンの自動修正もサポートされています。
