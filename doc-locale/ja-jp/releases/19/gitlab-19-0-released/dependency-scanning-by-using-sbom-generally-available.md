---
title: SBOMを使用した依存関係スキャンが一般提供開始
stage: software_supply_chain_security
level: primary
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
documentation_link: "../../../user/application_security/dependency_scanning/dependency_scanning_sbom/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/20456"
categories: [ Software Composition Analysis ]
weight: 50
---

GitLabのSBOMベースの依存関係スキャナーが一般提供（GA）になりました。Maven、Gradle、Pythonプロジェクトで、推移的に導入された脆弱なパッケージを含む、依存関係ツリー全体にわたる脆弱性を完全に可視化できるようになりました。直接宣言された依存関係だけでなく、推移的な依存関係も対象となります。

アナライザーにMaven、Gradle、Pythonプロジェクト向けの自動依存関係解決機能が追加されました。ロックファイルや解決済みの依存関係グラフが存在しない場合、アナライザーは自動的にツールを実行して、スキャン前に推移的な依存関係グラフ全体を解決します。依存関係の解決はデフォルトで有効になっており、v2 Dependency Scanningテンプレートを含めるだけで、追加設定はほとんど不要です。

依存関係の解決が不可能なプロジェクトでは、アナライザーはマニフェストスキャンにフォールバックします。`pom.xml`、`requirements.txt`、`build.gradle`、`build.gradle.kts`を解析して直接依存関係を特定します。マニフェストスキャンにより、ロックファイルやビルドファイルが存在しないプロジェクトでも、脆弱性カバレッジの出発点を確保できます。

マニフェストスキャンはデフォルトで有効になっており、直接依存関係のみを返します。推移的な依存関係を完全にカバーするには、依存関係の解決を有効にするか、依存関係のロックファイルまたはグラフエクスポートを手動で提供してください。
