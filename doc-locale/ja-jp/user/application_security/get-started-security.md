---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: アプリケーションをテストし、脆弱性を解決します。
title: アプリケーションの保護を始める
---

アプリケーションのソースコード内の脆弱性を特定し、修正します。コードを自動的にスキャンして潜在的なセキュリティ上の問題を検出することで、ソフトウェア開発ライフサイクルにセキュリティテストを組み込みます。

さまざまなプログラミング言語とフレームワークをスキャンして、SQLインジェクション、クロスサイトスクリプティング（XSS）、脆弱な依存関係などの脆弱性を検出できます。セキュリティスキャンの結果はGitLab UIに表示され、そこで結果を確認して対処できます。

これらの機能は、マージリクエストやパイプラインなどのGitLabの他の機能と統合することもでき、開発プロセス全体を通してセキュリティを優先的に確保できます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[Adopting GitLab application security](https://www.youtube.com/watch?v=5QlxkiKR04k)を参照してください

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [インタラクティブな読み物とハウツーデモのプレイリストをご覧ください](https://www.youtube.com/playlist?list=PL05JrBw4t0KrUrjDoefSkgZLx5aJYFaF9)

このプロセスは、以下に示すより大きなワークフローの一部です。

![ワークフロー](img/get_started_app_sec_v16_11.png)

## ステップ1: スキャンについて学習する {#step-1-learn-about-scanning}

シークレット検出は、リポジトリをスキャンして、シークレットが流出するのを防ぎます。すべてのプログラミング言語で動作します。

依存関係スキャンは、アプリケーションの依存関係を分析し、既知の脆弱性を検出します。特定の言語とパッケージマネージャーで動作します。

詳細については、以下を参照してください。

- [シークレット検出](secret_detection/_index.md)
- [依存関係スキャン](dependency_scanning/_index.md)

## ステップ2: テストするプロジェクトを選択する {#step-2-choose-a-project-to-test}

GitLabセキュリティスキャンを初めて設定する場合は、まず1つのプロジェクトから始めることをおすすめします。プロジェクトは次の条件を満たしている必要があります。

- 組織で一般的に使用しているプログラミング言語とテクノロジーを採用していること。一部のスキャン機能は言語によって動作が異なるためです。
- チームの日常業務を妨げることなく、必須の承認など、新しい設定を試せること。トラフィックの多いプロジェクトをコピーするか、アクティビティーが少ないプロジェクトを選択するとよいでしょう。

## ステップ3: スキャンを有効にする {#step-3-enable-scanning}

プロジェクト内の流出したシークレットや脆弱なパッケージを特定するには、シークレット検出と依存関係スキャンを有効にするマージリクエストを作成します。

このマージリクエストでは、`.gitlab-ci.yml`ファイルを更新し、プロジェクトのCI/CDパイプラインの一部としてスキャンが実行されるようにします。

このマージリクエストの一部として、プロジェクトのレイアウトや設定に合わせて設定を変更することもできます。たとえば、サードパーティのコードのディレクトリを除外できます。

このマージリクエストをデフォルトブランチにマージすると、ベースラインスキャンが作成されます。このスキャンでは、デフォルトブランチにすでに存在する脆弱性を特定します。その後、マージリクエストでは新たに導入された問題が強調表示されます。

ベースラインスキャンがない場合、マージリクエストにはブランチ内のすべての脆弱性が表示され、デフォルトブランチにすでに存在する脆弱性も含まれます。

詳細については、以下を参照してください。

- [シークレット検出を有効にする](secret_detection/pipeline/_index.md#getting-started)
- [シークレット検出の設定](secret_detection/pipeline/configure.md)
- [依存関係スキャンを有効にする](dependency_scanning/_index.md#getting-started)
- [依存関係スキャンの設定](dependency_scanning/_index.md#available-cicd-variables)

## ステップ4: スキャン結果をレビューする {#step-4-review-scan-results}

チームがマージリクエストと脆弱性レポートでセキュリティ検出結果をスムーズに確認できるようにしましょう。

脆弱性のトリアージワークフローを確立します。脆弱性から作成されたイシューを管理しやすくするため、ラベルとイシューボードを作成することを検討してください。イシューボードを使用すると、関係者全員がすべてのイシューを共通のビューで確認でき、修正の進捗状況を追跡できます。

セキュリティダッシュボードの傾向を監視して、既存の脆弱性の修正や新たな脆弱性の導入防止の成果を評価します。

詳細については、以下を参照してください。

- [脆弱性レポートを表示する](vulnerability_report/_index.md)
- [マージリクエストでセキュリティ検出結果を表示する](detect/security_scanning_results.md)
- [セキュリティダッシュボードを表示する](security_dashboard/_index.md)
- [ラベル](../project/labels.md)
- [イシューボード](../project/issue_board.md)

## ステップ5: 将来のスキャンジョブをスケジュールする {#step-5-schedule-future-scanning-jobs}

スキャン実行ポリシーを使用して、スケジュールされたセキュリティスキャンジョブを適用します。これらのスケジュールされたジョブは、コンプライアンスフレームワークパイプラインや、プロジェクトの`.gitlab-ci.yml`ファイルで定義されている場合がある他のセキュリティスキャンとは独立して実行されます。

スケジュールされたスキャンは、開発アクティビティーが少なく、パイプラインスキャンの頻度が低いプロジェクトや重要なブランチで特に有用です。

詳細については、以下を参照してください。

- [スキャン実行ポリシー](policies/scan_execution_policies.md)
- [コンテナスキャン](container_scanning/_index.md)
- [運用コンテナスキャン（OCS）](../clusters/agent/vulnerabilities.md)

## ステップ6: 新しい脆弱性を制限する {#step-6-limit-new-vulnerabilities}

必要なスキャンタイプを適用し、セキュリティチームとエンジニアリングチーム間の職務分離を確保するには、スキャン実行ポリシーを使用します。

新しい脆弱性がデフォルトブランチにマージされるのを防ぐには、マージリクエスト承認ポリシーを作成します。

スキャンの仕組みを理解したら、次のような対応を選択できます。

- 同じ手順に従って、より多くのプロジェクトでスキャンを有効にする。
- より多くのプロジェクトに対して一括でスキャンを適用する。

詳細については、以下を参照してください。

- [スキャン実行ポリシー](policies/scan_execution_policies.md)
- [マージリクエスト承認ポリシー](policies/_index.md)

## ステップ7: 新たな脆弱性を継続的にスキャンする {#step-7-continue-scanning-for-new-vulnerabilities}

時間の経過とともに、新たな脆弱性が導入されないようにする必要があります。

- リポジトリ内にすでに存在する新たに検出された脆弱性を明らかにするには、依存関係スキャンとコンテナスキャンを定期的に実行します。
- 本番環境クラスター内のコンテナイメージに対してセキュリティ脆弱性をスキャンするには、運用コンテナスキャンを有効にします。
- SAST、DAST、ファズテストなど、他のスキャンタイプを有効にします。
- 一時的なテスト環境でDASTやWeb APIファジングを実行できるようにするには、レビューアプリの有効化を検討してください。

詳細については、以下を参照してください。

- [SAST](sast/_index.md)
- [DAST](dast/_index.md)
- [ファズテスト](coverage_fuzzing/_index.md)
- [Web APIファジング](api_fuzzing/_index.md)
- [レビューアプリ](../../ci/review_apps/_index.md)
