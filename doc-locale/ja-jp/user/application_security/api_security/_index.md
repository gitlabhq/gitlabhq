---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: APIセキュリティ
description: 保護、分析、テスト、スキャン、検出。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

APIセキュリティとは、ウェブApplication Programming Interfaces（APIs）を不正なアクセス、誤用、攻撃から保護し、セキュリティを確保するために講じられる対策を指します。APIは、アプリケーションが相互に連携し、データを交換することを可能にするため、最新のアプリケーション開発において重要な要素です。しかし、適切に保護されていない場合、攻撃者にとって魅力的であり、セキュリティ上の脅威に対して脆弱になります。このセクションでは、GitLabの機能のうち、アプリケーションにおけるWeb APIのセキュリティを確保するために使用できるものについて説明します。議論されている機能の一部はWeb APIに特化しており、その他の機能はWeb APIアプリケーションでも使用される一般的なソリューションです。

- [SAST](../sast/_index.md)は、アプリケーションのコードベースを分析することで、脆弱性を特定します。
- [依存関係スキャン](../dependency_scanning/_index.md)は、既知の脆弱性（例えばCVE）について、プロジェクトのサードパーティ依存関係をレビューします。
- [コンテナスキャン](../container_scanning/_index.md)は、コンテナイメージを分析して、既知のOSパッケージの脆弱性とインストールされている言語の依存関係を特定します。
- [API Discovery](api_discovery/_index.md)は、REST APIを含むアプリケーションを調査し、そのAPIに対するOpenAPI仕様を推測します。OpenAPI仕様ドキュメントは、他のGitLabセキュリティツールによって使用されます。
- [APIセキュリティテストアナライザー](../api_security_testing/_index.md)は、Web APIの動的な解析セキュリティテストを実行します。これは、OWASP Top 10を含む、アプリケーション内のさまざまなセキュリティ脆弱性を特定できます。
- [APIファジング](../api_fuzzing/_index.md)は、Web APIのファズテストを実行します。ファズテストは、以前は知られていなかったアプリケーション内の問題、およびSQLインジェクションのような従来の脆弱性タイプにマップされない問題を検出します。
