---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: k6ロードテストを使用して、ロード時の応答時間とスループットを評価し、コードの変更がアプリケーションのパフォーマンスにどのように影響するかを測定します。
title: ロードパフォーマンステスト
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ロードパフォーマンステストを使用すると、保留中のコード変更が、アプリケーションのバックエンドに与える影響を[GitLab CI/CD](../_index.md)でテストできます。

GitLabでは、[k6](https://k6.io/)（無償のオープンソースツール）を使用して、ロード時のアプリケーションのシステムパフォーマンスを測定します。

Webサイトがクライアントブラウザでどのようにパフォーマンスを発揮するかを測定するために使用される[ブラウザパフォーマンステスト](browser_performance_testing.md)とは異なり、ロードパフォーマンステストは、API、Webコントローラーなどのアプリケーションエンドポイントに対して、さまざまな種類の[負荷テスト](https://k6.io/docs/#use-cases)を実行するために使用できます。これは、バックエンドまたはサーバーがスケール時にどのようにパフォーマンスを発揮するかをテストするために使用できます。

たとえば、ロードパフォーマンステストを使用して、アプリケーション内の一般的なAPIエンドポイントに対して多くの同時GET呼び出しを実行し、そのパフォーマンスを確認できます。

## ロードパフォーマンステストの仕組み {#how-load-performance-testing-works}

まず、`.gitlab-ci.yml`ファイルで、[Load Performance reportアーティファクト](../yaml/artifacts_reports.md#artifactsreportsload_performance)を生成するジョブを定義します。GitLabはこのレポートをチェックし、ソースブランチとターゲットブランチ間のキーとなるロードパフォーマンステストのメトリクスを比較し、マージリクエストウィジェットに情報を表示します:

![Load Performanceウィジェット](img/load_performance_testing_v13_2.png)

次に、テスト環境を設定し、k6テストを作成する必要があります。

テスト完了後、マージリクエストウィジェットに表示されるキーとなるパフォーマンスメトリクスは次のとおりです:

- チェック: k6テストで設定された[チェック](https://k6.io/docs/using-k6/checks)の合格率（パーセント）。
- TTFB P90: 応答の受信開始にかかった時間（つまり、[Time to First Byte](https://en.wikipedia.org/wiki/Time_to_first_byte)（TTFB））の90パーセンタイル。
- TTFB P95: TTFBの95パーセンタイル。
- RPS: テストで達成できた1秒あたりの平均リクエスト数（RPS）レート。

{{< alert type="note" >}}

ロードパフォーマンストレポートに比較するデータがない場合（たとえば、`.gitlab-ci.yml`にロードパフォーマンスジョブを初めて追加した場合など）、ロードパフォーマンストレポートウィジェットは表示されません。そのブランチをターゲットとするマージリクエストに表示する前に、ターゲットブランチ（`main`など）で少なくとも1回は実行されている必要があります。

{{< /alert >}}

## ロードパフォーマンステストジョブを設定する {#configure-the-load-performance-testing-job}

ロードパフォーマンステストジョブの設定は、いくつかの異なる部分に分類できます:

- スループットなどのテストパラメータを決定します。
- ロードパフォーマンステストのターゲットテスト環境をセットアップします。
- k6テストを設計および作成します。

### テストパラメータを決定する {#determine-the-test-parameters}

最初に、実行する[負荷テストのタイプ](https://grafana.com/load-testing/types-of-load-testing/)と、その実行方法（たとえば、ユーザー数、スループットなど）を決定する必要があります。

ガイダンスについては、[k6ドキュメント](https://k6.io/docs/) 、特に[k6テストガイド](https://k6.io/docs/testing-guides)を参照してください。

### テスト環境のセットアップ {#test-environment-setup}

ロードパフォーマンステストに関する作業の大部分は、高負荷に対応できるようにターゲットテスト環境を準備することです。テスト対象の[throughput](https://k6.io/blog/monthly-visits-concurrent-users)スループットを処理できることを確認してください。

通常、ロードパフォーマンステストで使用するために、ターゲット環境に代表的なテストデータを含める必要もあります。

[本番環境に対してこれらのテストを実行しない](https://k6.io/our-beliefs#load-test-in-a-pre-production-environment)ことを強くお勧めします。

### 負荷パフォーマンステストの作成 {#write-the-load-performance-test}

環境を準備したら、k6テスト自体を作成できます。k6は柔軟なツールであり、[多くの種類のパフォーマンステスト](https://grafana.com/load-testing/types-of-load-testing/)を実行するために使用できます。テストの作成方法の詳細については、[k6ドキュメント](https://k6.io/docs/)を参照してください。

### GitLab CI/CDでのテストの設定 {#configure-the-test-in-gitlab-cicd}

k6テストの準備ができたら、次のステップは、GitLab CI/CDで負荷パフォーマンステストジョブを設定することです。これを行う最も簡単な方法は、GitLabに含まれている[`Verify/Load-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Verify/Load-Performance-Testing.gitlab-ci.yml)テンプレートを使用することです。

{{< alert type="note" >}}

大規模なk6テストの場合、実際のテストを実行するGitLab Runnerインスタンスが、テストの実行を処理できることを確認する必要があります。仕様の詳細については、[k6のガイダンス](https://k6.io/docs/testing-guides/running-large-tests#hardware-considerations)を参照してください。[デフォルト](../runners/hosted_runners/linux.md)の共有GitLab.comランナーは、ほとんどの大規模なk6テストを処理するには、仕様が不十分である可能性があります。

{{< /alert >}}

このテンプレートは、ジョブで[k6 Dockerコンテナ](https://hub.docker.com/r/loadimpact/k6/)を実行し、ジョブをカスタマイズするためのいくつかの方法を提供します。

設定のワークフローの例:

1. [Docker-in-Docker](../docker/using_docker_build.md#use-docker-in-docker)ワークフローのように、Dockerコンテナを実行するようにGitLab Runnerをセットアップします。
1. `.gitlab-ci.yml`ファイルで、デフォルトのロードパフォーマンステストCI/CDジョブを設定します。テンプレートを含め、CI/CD変数で設定する必要があります:

   ```yaml
   include:
     template: Verify/Load-Performance-Testing.gitlab-ci.yml

   load_performance:
     variables:
       K6_TEST_FILE: <PATH TO K6 TEST FILE IN PROJECT>
   ```

前の例では、k6テストを実行するCI/CDパイプラインに`load_performance`ジョブが作成されます。

{{< alert type="note" >}}

Kubernetesのセットアップでは、別のテンプレートを使用する必要があります: [`Jobs/Load-Performance-Testing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Load-Performance-Testing.gitlab-ci.yml)。

{{< /alert >}}

k6には、実行するスループット（RPS）など、テストの実行方法を設定するための[さまざまなオプション](https://k6.io/docs/using-k6/k6-options/reference/)があります。テストの実行時間などです。ほとんどすべてのオプションはテスト自体で設定できますが、`K6_OPTIONS`変数を介してコマンドラインオプションを渡すこともできます。

たとえば、CLIオプションを使用して、テストの期間をオーバーライドできます:

```yaml
  include:
    template: Verify/Load-Performance-Testing.gitlab-ci.yml

  load_performance:
    variables:
      K6_TEST_FILE: <PATH TO K6 TEST FILE IN PROJECT>
      K6_OPTIONS: '--duration 30s'
```

GitLabは、k6の結果が[サマリーエクスポート](https://k6.io/docs/results-output/real-time/json/#summary-export)として[Load Performance reportアーティファクト](../yaml/artifacts_reports.md#artifactsreportsload_performance)として保存されている場合にのみ、MRウィジェットにキーとなるパフォーマンスメトリクスを表示します。利用可能な最新のロードパフォーマンスアーティファクトは常に使用され、テストからのサマリー値が使用されます。

[GitLab Pages](../../user/project/pages/_index.md)が有効になっている場合は、ブラウザでレポートを直接表示できます。

### レビューアプリでのロードパフォーマンステストテスト {#load-performance-testing-in-review-apps}

前のCI/CD YAML設定の例は、静的環境に対するテストで機能しますが、いくつかの追加手順で[レビューアプリ](../review_apps/_index.md)または[動的環境](../environments/_index.md)で動作するように拡張できます。

最適なアプローチは、共有されるジョブアーティファクトとして[`.env`ファイル](https://docs.docker.com/compose/environment-variables/env-file/)に動的URLを取り込み、ファイルを使用するようにk6 Dockerコンテナを設定するために、提供されたカスタムCI/CD変数`K6_DOCKER_OPTIONS`を使用することです。これにより、k6は、`.env`ファイルの環境変数を標準のJavaScriptを使用したスクリプトで使用できます（例: ``http.get(`${__ENV.ENVIRONMENT_URL}`)``）。

例: 

1. `review`ジョブ内:
   1. 動的URLを取り込み、`.env`ファイルに保存します（例: `echo "ENVIRONMENT_URL=$CI_ENVIRONMENT_URL" >> review.env`）。
   1. `.env`ファイルを[ジョブアーティファクト](../jobs/job_artifacts.md)として設定します。
1. `load_performance`ジョブ内:
   1. レビュージョブに依存するように設定して、環境ファイルを継承します。
   1. `K6_DOCKER_OPTIONS`変数を、[環境変数のDocker CLIオプション](https://docs.docker.com/reference/cli/docker/container/run/#env)で設定します（例: `--env-file review.env`）。
1. 環境変数を使用するようにk6テストスクリプトを設定します。

お使いの`.gitlab-ci.yml`ファイルは次のようになります:

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
