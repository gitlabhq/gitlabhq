---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: k6ロードテストを使用して、コードの変更がアプリケーションのパフォーマンスにどのように影響するかを測定し、負荷時の応答時間とスループットを評価します。
title: ロードパフォーマンステスト
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ロードパフォーマンステストを使用すると、アプリケーションのバックエンドに対する保留中のコード変更の影響を[GitLab CI/CD](../_index.md)でテストできます。

GitLabは、アプリケーションのシステムパフォーマンスを測定するために、[k6](https://k6.io/)というオープンソースの無料ツールを使用しています。

クライアントブラウザでウェブサイトがどのように動作するかを測定するために使用される[Browser Performance Testing](browser_performance_testing.md)とは異なり、ロードパフォーマンステストは、API、Webコントローラーなどのアプリケーションエンドポイントに対して様々な種類の[ロードテスト](https://k6.io/docs/#use-cases)を実行するために使用できます。これは、バックエンドまたはサーバーが大規模にどのように動作するかをテストするために使用できます。

例えば、ロードパフォーマンステストを使用して、アプリケーション内の人気のあるAPIエンドポイントに多くの同時GET呼び出しを実行し、そのパフォーマンスを確認できます。

## ロードパフォーマンステストの仕組み {#how-load-performance-testing-works}

まず、`.gitlab-ci.yml`ファイルで、[ロードパフォーマンスレポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportsload_performance)を生成するジョブを定義します。GitLabはこのレポートをチェックし、ソースとターゲットブランチ間の主要なパフォーマンスメトリクスを比較して、マージリクエストのウィジェットに情報を表示します:

![TTFB値が低下したパフォーマンスメトリクスを表示するマージリクエスト。](img/load_performance_testing_v13_2.png)

次に、テスト環境を設定し、k6テストを作成する必要があります。

テスト完了後にマージリクエストのウィジェットが表示する主要なパフォーマンスメトリクスは次のとおりです:

- チェック: k6テストで設定された[チェック](https://k6.io/docs/using-k6/checks)の合格率（パーセンテージ）。
- TTFB P90: 応答の受信を開始するまでにかかった時間の90パーセンタイル値、別名[Time to First Byte](https://en.wikipedia.org/wiki/Time_to_first_byte)（TTFB）。
- TTFB P95: TTFBの95パーセンタイル値。
- RPS: テストで達成できた平均1秒あたりのリクエスト数（RPS）です。

> [!note]
> 
> ロードパフォーマンステストレポートに比較データがない場合、例えば`.gitlab-ci.yml`にロードパフォーマンステストジョブを初めて追加した場合、ロードパフォーマンステストレポートのウィジェットは表示されません。そのブランチをターゲットとするマージリクエストに表示される前に、ターゲットブランチ（`main`など）で少なくとも一度実行されている必要があります。

## ロードパフォーマンステストジョブを設定する {#configure-the-load-performance-testing-job}

あなたのロードパフォーマンステストジョブの構成は、いくつかの異なる部分に分けられます:

- スループットなどのテストパラメータを決定します。
- ロードパフォーマンステスト用のターゲットテスト環境をセットアップします。
- k6テストを設計し、作成します。

### テストパラメータを決定する {#determine-the-test-parameters}

まず、実行したい[ロードテストの種類](https://grafana.com/load-testing/types-of-load-testing/)と、その実行方法（例えば、ユーザー数、スループットなど）を決定する必要があります。

ガイダンスについては、[k6ドキュメント](https://k6.io/docs/) 、特に[k6テストガイド](https://k6.io/docs/testing-guides)を参照してください。

### テスト環境のセットアップ {#test-environment-setup}

ロードパフォーマンステストの取り組みの大部分は、ターゲットテスト環境を高負荷に対応できるよう準備することです。テスト対象となる[スループット](https://k6.io/blog/monthly-visits-concurrent-users)を処理できることを確認する必要があります。

ロードパフォーマンステストが使用する代表的なテストデータをターゲット環境に用意することも通常必要です。

これらのテストを本番環境に対して実行すべきではありません。代わりに、[プリプロダクション環境](https://k6.io/our-beliefs#load-test-in-a-pre-production-environment)でテストを実行してください。

### ロードパフォーマンステストを作成する {#write-the-load-performance-test}

環境が準備できたら、k6テスト自体を作成できます。k6は柔軟なツールであり、[様々な種類のパフォーマンステスト](https://grafana.com/load-testing/types-of-load-testing/)を実行するために使用できます。テストの作成方法に関する詳細については、[k6ドキュメント](https://k6.io/docs/)を参照してください。

### GitLab CI/CDでテストを設定する {#configure-the-test-in-gitlab-cicd}

k6テストの準備ができたら、次のステップはGitLab CI/CDでロードパフォーマンステストジョブを設定することです。これを行う最も簡単な方法は、GitLabに付属の[`Verify/Load-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Verify/Load-Performance-Testing.gitlab-ci.yml)テンプレートを使用することです。

> [!note]
> 大規模なk6テストの場合、実際のテストを実行するGitLab Runnerインスタンスがテストの実行を処理できることを確認する必要があります。仕様の詳細については、[k6のガイダンス](https://k6.io/docs/testing-guides/running-large-tests#hardware-considerations)を参照してください。The [デフォルトの共有GitLab.com Runner](../runners/hosted_runners/linux.md)は、ほとんどの大規模なk6テストを処理するには仕様が不十分である可能性があります。

このテンプレートは、ジョブで[k6 Dockerコンテナ](https://hub.docker.com/r/loadimpact/k6/)を実行し、ジョブをカスタマイズするいくつかの方法を提供します。

設定ワークフローの例:

1. GitLab Runnerをセットアップして、[Docker-in-Dockerワークフロー](../docker/using_docker_build.md#use-docker-in-docker)のようにDockerコンテナを実行します。
1. あなたの`.gitlab-ci.yml`ファイルで、デフォルトのロードパフォーマンステストCI/CDジョブを設定します。テンプレートを含め、CI/CD変数で設定する必要があります:

   ```yaml
   include:
     template: Verify/Load-Performance-Testing.gitlab-ci.yml

   load_performance:
     variables:
       K6_TEST_FILE: <PATH TO K6 TEST FILE IN PROJECT>
   ```

前の例では、k6テストを実行するCI/CDパイプラインに`load_performance`ジョブを作成します。

> [!note] 
> 
> Kubernetesのセットアップの場合、異なるテンプレートを使用する必要があります: [`Jobs/Load-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Load-Performance-Testing.gitlab-ci.yml)。

k6には、テストの実行方法を設定するための[様々なオプション](https://k6.io/docs/using-k6/k6-options/reference/)があります。例えば、どのスループット（RPS）で実行するか、テストの実行時間などです。ほとんどすべてのオプションはテスト自体で設定できますが、`K6_OPTIONS`変数を介してコマンドラインオプションを渡すこともできます。

例えば、CLIオプションを使用してテストの期間をオーバーライドできます:

```yaml
  include:
    template: Verify/Load-Performance-Testing.gitlab-ci.yml

  load_performance:
    variables:
      K6_TEST_FILE: <PATH TO K6 TEST FILE IN PROJECT>
      K6_OPTIONS: '--duration 30s'
```

GitLabは、k6の結果が[サマリーエクスポート](https://k6.io/docs/results-output/real-time/json/#summary-export)によって[ロードパフォーマンステストレポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportsload_performance)として保存された場合にのみ、MRのウィジェットに主要なパフォーマンスメトリクスを表示します。利用可能な最新のロードパフォーマンスアーティファクトが常に使用され、テストからのサマリー値が用いられます。

If [GitLab Pages](../../user/project/pages/_index.md)が有効になっている場合、レポートをブラウザで直接表示できます。

### レビューアプリにおけるロードパフォーマンステスト {#load-performance-testing-in-review-apps}

以前のCI/CD YAML設定の例は静的環境に対するテストで機能しますが、いくつかの追加ステップで[レビューアプリ](../review_apps/_index.md)または[動的環境](../environments/_index.md)で機能するように拡張できます。

最良のアプローチは、動的なURLを共有するジョブアーティファクトとして[`.env`ファイル](https://docs.docker.com/compose/environment-variables/env-file/)にキャプチャし、次に`K6_DOCKER_OPTIONS`という名前のカスタムCI/CD変数を使用してk6 Dockerコンテナを設定してファイルを使用することです。これにより、k6は標準JavaScriptを使用するスクリプトで`.env`ファイルからの任意の環境変数を使用できます。例: ``http.get(`${__ENV.ENVIRONMENT_URL}`)``。

例: 

1. `review`ジョブで:
   1. 動的なURLをキャプチャし、`.env`ファイルに保存します。例えば、`echo "ENVIRONMENT_URL=$CI_ENVIRONMENT_URL" >> review.env`です。
   1. `.env`ファイルを[ジョブアーティファクト](../jobs/job_artifacts.md)として設定します。
1. `load_performance`ジョブで:
   1. レビュージョブに依存するように設定して、環境ファイルを継承させます。
   1. `K6_DOCKER_OPTIONS`変数を[環境ファイル用Docker CLIオプション](https://docs.docker.com/reference/cli/docker/container/run/#env)（例: `--env-file review.env`）で設定します。
1. k6テストスクリプトを設定して、そのステップで環境変数を使用するようにします。

あなたの`.gitlab-ci.yml`ファイルは次のようになるでしょう:

```yaml
stages:
  - deploy
  - performance

include:
  template: Verify/Load-Performance-Testing.gitlab-ci.yml

review:
  stage: deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: http://$CI_ENVIRONMENT_SLUG.example.com
  script:
    - run_deploy_script
    - echo "ENVIRONMENT_URL=$CI_ENVIRONMENT_URL" >> review.env
  artifacts:
    paths:
      - review.env
  rules:
    - if: $CI_COMMIT_BRANCH  # Modify to match your pipeline rules, or use `only/except` if needed.

load_performance:
  dependencies:
    - review
  variables:
    K6_DOCKER_OPTIONS: '--env-file review.env'
  rules:
    - if: $CI_COMMIT_BRANCH  # Modify to match your pipeline rules, or use `only/except` if needed.
```
