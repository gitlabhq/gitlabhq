---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 動的アプリケーションセキュリティテスト
description: 自動ペネトレーションテスト、脆弱性検出、Webアプリケーションスキャン、セキュリティ評価、CI/CDインテグレーション。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!warning]
> 
> DASTプロキシベースのアナライザーは、GitLab 16.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/430966)になり、GitLab 17.3で[削除](https://gitlab.com/groups/gitlab-org/-/epics/11986)されました。これは破壊的な変更です。DASTプロキシベースのアナライザーからDASTバージョン5への移行方法については、[プロキシベースの移行ガイド](proxy_based_to_browser_based_migration_guide.md)を参照してください。DASTバージョン4のブラウザベースのアナライザーからDASTバージョン5への移行方法については、[ブラウザベースの移行ガイド](browser_based_4_to_5_migration_guide.md)を参照してください。

動的アプリケーションセキュリティテスト（DAST）は、稼働中のウェブアプリケーションやAPIの脆弱性を発見するために、自動化された侵入テストを実行します。DASTは、クロスサイトスクリプティング（XSS）、SQLインジェクション（SQLi）、クロスサイトリクエストフォージェリ（CSRF）などの重大な脅威に対して、ハッカーの手法を自動化し、実際の攻撃をシミュレートすることで、他のセキュリティツールでは検出できない脆弱性や設定ミスを明らかにします。

DASTは完全に言語に依存せず、アプリケーションを外部から検査します。DASTスキャンは、CI/CDパイプラインで実行したり、スケジュールに基づいて実行したり、オンデマンドで手動で実行したりできます。ソフトウェア開発ライフサイクルの中でDASTを使用すると、本番環境にデプロイする前にアプリケーションの脆弱性を検出できます。DASTはソフトウェアセキュリティの基盤となるコンポーネントであり、他のGitLabセキュリティツールと組み合わせて使用して、アプリケーションの包括的なセキュリティ評価を提供する必要があります。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[DAST - 高度なセキュリティテスト](https://www.youtube.com/watch?v=nbeDUoLZJTo)を参照してください。

## GitLab DAST {#gitlab-dast}

GitLab DASTアナライザーとAPIセキュリティアナライザーは独自のランタイムツールであり、最新のWebアプリケーションとAPIに対して幅広いセキュリティカバレッジを提供します。

ニーズに応じてDASTアナライザーを使用してください。

- 既知の脆弱性について、シングルページWebアプリケーションを含むWebベースのアプリケーションをスキャンするには、[DAST](browser/_index.md)アナライザーを使用します。
- 既知の脆弱性についてAPIをスキャンするには、[APIセキュリティ](../api_security_testing/_index.md)アナライザーを使用します。GraphQL、REST、SOAPなどのテクノロジーがサポートされています。

アナライザーは、[アプリケーションを保護する](../_index.md)で説明されているアーキテクチャパターンに従います。各アナライザーは、CI/CDテンプレートを使用してパイプラインで設定でき、Dockerコンテナでスキャンを実行します。スキャンは[DASTレポートアーティファクト](../../../ci/yaml/artifacts_reports.md#artifactsreportsdast)を出力します。GitLabはこれを使用して、ソースブランチとターゲットブランチのスキャン結果の差に基づいて、検出された脆弱性を判断します。

## スキャン結果を表示する {#view-scan-results}

検出された脆弱性は、[マージリクエスト](../detect/security_scanning_results.md)、[パイプラインセキュリティタブ](../detect/security_scanning_results.md)、[脆弱性レポート](../vulnerability_report/_index.md)に表示されます。

> [!note]
> 
> 1つのパイプラインは、SASTおよびDASTスキャンを含む複数のジョブで構成される場合があります。何らかの理由でジョブの完了に失敗した場合、セキュリティダッシュボードにDASTスキャナーの出力は表示されません。たとえば、DASTジョブが完了してもSASTジョブが失敗した場合、セキュリティダッシュボードにはDASTの結果は表示されません。失敗すると、アナライザーは終了コードを出力します。

### スキャンされたURLの一覧を表示する {#list-urls-scanned}

DASTのスキャンが完了すると、マージリクエストページにスキャンされたURLの数が表示されます。**詳細を表示**を選択すると、スキャンされたURLの一覧を含むWebコンソールの出力が表示されます。
