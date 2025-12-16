---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: APIセキュリティ
description: 保護、分析、テスト、スキャン、および検出。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

APIセキュリティとは、Web API（Application Programming Interfaces）を不正なアクセス、誤用、攻撃から保護するために講じられる対策のことです。APIは、アプリケーションが相互にやり取りし、データを交換できるようにするため、最新のアプリケーション開発において重要な要素となっています。しかし、適切に保護されていない場合、APIは攻撃者にとって魅力的であり、セキュリティ上の脅威に対して脆弱性を持つことになります。このセクションでは、アプリケーションのWeb APIのセキュリティを確保するために使用できるGitLabの機能について説明します。説明する機能の中には、Web APIに固有のものもあれば、Web APIアプリケーションでも使用されるより一般的なソリューションもあります。

- [SAST](../sast/_index.md)は、アプリケーションのコードベースを分析することで、脆弱性を特定しました。
- [依存関係スキャン](../dependency_scanning/_index.md)は、既知の脆弱性（たとえばCVE）について、プロジェクトのサードパーティの依存関係をレビューします。
- [コンテナスキャン](../container_scanning/_index.md)は、コンテナイメージを分析して、既知のOSパッケージの脆弱性とインストールされている言語の依存関係を特定します。
- [API Discovery](api_discovery/_index.md)は、REST APIを含むアプリケーションを調査し、そのAPIのOpenAPI仕様を推測します。OpenAPI仕様のドキュメントは、他のGitLabセキュリティツールで使用されます。
- [APIセキュリティテストアナライザー](../api_security_testing/_index.md)は、Web APIの動的な解析セキュリティテストを実行します。アプリケーション内のさまざまなセキュリティ脆弱性（OWASP Top 10を含む）を識別できます。
- [APIファジング](../api_fuzzing/_index.md)は、Web APIのファズテストを実行します。ファズテストでは、以前には知られていなかったアプリケーションの問題を検索し、SQLインジェクションなどの従来の脆弱性タイプにマップされません。
