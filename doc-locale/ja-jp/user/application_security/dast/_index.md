---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 動的アプリケーションセキュリティテスト（DAST）
---

{{< details >}}

- プラン:Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

DASTプロキシベースのアナライザーは、GitLab 16.9で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/430966)となり、GitLab 17.3で[削除](https://gitlab.com/groups/gitlab-org/-/epics/11986)されました。この変更は破格の変更です。DASTプロキシベースのアナライザーからDASTバージョン5への移行方法については、[プロキシベースの移行ガイド](proxy_based_to_browser_based_migration_guide.md)を参照してください。DASTバージョン4のブラウザーベースのアナライザーからDASTバージョン5への移行方法については、[ブラウザーベースの移行ガイド](browser_based_4_to_5_migration_guide.md)を参照してください。

{{< /alert >}}

動的アプリケーションセキュリティテスト（DAST）は、WebアプリケーションとAPIの実行中に自動化された侵入テストを実行して、脆弱性を検出します。DASTは、ハッカーのアプローチを自動化し、クロスサイトスクリプティング（XSS）、SQL挿入（SQLi）、クロスサイトリクエストフォージ（CSRF）などの重大な脅威に対する実際の攻撃をシミュレートして、他のセキュリティツールでは検出できない脆弱性や設定ミスを明らかにします。

DASTは完全に言語に依存せず、アプリケーションを外部から検査します。DASTスキャンは、CI/CDパイプラインで実行したり、スケジュールに基づいて実行したり、オンデマンドで手動で実行したりできます。ソフトウェア開発ライフサイクル中にDASTを使用すると、本番環境へのデプロイ前にアプリケーションの脆弱性を検出できます。DASTはソフトウェアセキュリティの基盤となるコンポーネントであり、他のGitLabセキュリティツールと組み合わせて使用​​して、アプリケーションの包括的なセキュリティ評価を提供する必要があります。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> 概要については、[動的アプリケーションセキュリティテスト（DAST）](https://www.youtube.com/watch?v=nbeDUoLZJTo)を参照してください。

## GitLab DAST

GitLab DASTとAPIセキュリティのアナライザーは独自のランタイムツールであり、最新のWebアプリケーションとAPIに幅広いセキュリティカバレッジを提供します。

ニーズに応じてDASTアナライザーを使用してください。

- 既知の脆弱性について、シングルページWebアプリケーションを含むWebベースのアプリケーションをスキャンするには、[DAST](browser/_index.md)アナライザーを使用します。
- 既知の脆弱性についてAPIをスキャンするには、[APIセキュリティ](../api_security_testing/_index.md)アナライザーを使用します。GraphQL、REST、SOAPなどのテクノロジーがサポートされています。

アナライザーは、[アプリケーションの保護](../_index.md)で説明されているアーキテクチャパターンに従います。各アナライザーは、CI/CDテンプレートを使用してパイプラインでConfigureでき、Dockerコンテナでスキャンを実行します。スキャンは[DASTレポートアーティファクト](../../../ci/yaml/artifacts_reports.md#artifactsreportsdast)を出力します。GitLabはこれを使用して、ソースブランチとターゲットブランチのスキャン結果の差に基づいて、検出された脆弱性を判断します。

## スキャン結果の表示

検出された脆弱性は、[マージリクエスト](../detect/security_scan_results.md#merge-request)、[パイプラインセキュリティタブ](../vulnerability_report/pipeline.md)、[脆弱性レポート](../vulnerability_report/_index.md)に表示されます。

{{< alert type="note" >}}

パイプラインは、SASTやDASTスキャンなど、複数のジョブで構成される場合があります。何らかの理由でジョブの完了に失敗した場合、セキュリティダッシュボードにDASTスキャナーの出力は表示されません。たとえば、DASTジョブは完了したが、SASTジョブが失敗した場合、セキュリティダッシュボードにはDASTの結果は表示されません。失敗すると、アナライザーは[終了コード](../../../development/integrations/secure.md#exit-code)を出力します。

{{< /alert >}}

### スキャンされたURLのリスト

DASTがスキャンを完了すると、マージリクエストページにスキャンされたURLの数が表示されます。**詳細を表示**を選択して、スキャンされたURLのリストを含むWebコンソールの出力を表示します。
