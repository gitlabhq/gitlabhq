---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パフォーマンスの調整とテスト速度
---

APIファジングなどのAPIファズテストを実行するセキュリティツールは、実行中のアプリケーションのインスタンスにリクエストを送信することでテストを実行します。リクエストは、アプリケーションに存在する可能性のある予期しない動作をトリガーするために、当社のファジングエンジンによって変更されます。APIファジングテストの速度は、以下に依存します:

- 当社のツールによって、アプリケーションに1秒あたりに送信できるリクエストの数
- アプリケーションがリクエストに応答する速さ
- アプリケーションをテストするために送信する必要があるリクエストの数
  - APIがいくつのオペレーションで構成されているか
  - 各オペレーションにいくつのフィールドがあるか（JSONボディ、ヘッダー、クエリ文字列、Cookieなどを考慮してください）

このパフォーマンスガイドのアドバイスに従っても、APIファジングテストジョブの時間が予想よりも長くなる場合は、サポートに連絡して支援を求めてください。

## パフォーマンスイシューの診断 {#diagnosing-performance-issues}

パフォーマンスイシューを解決するための最初のステップは、予想よりも遅いテスト時間に何が影響しているかを理解することです。よく見られるイシューは次のとおりです:

- APIファジングが低仮想CPUのRunner上で実行されている
- アプリケーションが低速/シングルCPUインスタンスにデプロイされ、テストの負荷に対応できていない
- アプリケーションに、テスト全体の速度に影響を与える低速なオペレーションが含まれている（1/2秒超）
- アプリケーションに、大量のデータを返すオペレーションが含まれている（500K超）
- アプリケーションに多数のオペレーションが含まれている（40超）

### アプリケーションに、テスト全体の速度に影響を与える低速なオペレーションが含まれている（1/2秒超） {#the-application-contains-a-slow-operation-that-impacts-the-overall-test-speed--12-second}

APIファジングジョブ出力には、テストの速度、テスト対象の各オペレーションの応答速度、および概要に関する役立つ情報が含まれています。いくつかのサンプル出力を見て、パフォーマンスイシューの追跡にどのように使用できるかを見てみましょう:

```shell
API Fuzzing: Loaded 10 operations from: assets/har-large-response/large_responses.har
API Fuzzing:
API Fuzzing: Testing operation [1/10]: 'GET http://target:7777/api/large_response_json'.
API Fuzzing:  - Parameters: (Headers: 4, Query: 0, Body: 0)
API Fuzzing:  - Request body size: 0 Bytes (0 bytes)
API Fuzzing:
API Fuzzing: Finished testing operation 'GET http://target:7777/api/large_response_json'.
API Fuzzing:  - Excluded Parameters: (Headers: 0, Query: 0, Body: 0)
API Fuzzing:  - Performed 767 requests
API Fuzzing:  - Average response body size: 130 MB
API Fuzzing:  - Average call time: 2 seconds and 82.69 milliseconds (2.082693 seconds)
API Fuzzing:  - Time to complete: 14 minutes, 8 seconds and 788.36 milliseconds (848.788358 seconds)
```

このジョブコンソール出力のスニペットは、検出されたオペレーションの数（10）を示し、特定のオペレーションでテストが開始されたという通知と、オペレーションの概要が完了したことを示しています。概要は、このログ出力の中で最も興味深い部分です。概要では、APIファジングがこのオペレーションとその関連フィールドを完全にテストするために767件のリクエストを必要としたことがわかります。また、平均応答時間が2秒であり、この1つのオペレーションを完了するのに14分かかったこともわかります。

平均応答時間が2秒というのは、この特定のオペレーションのテストに時間がかかることを示す良い初期指標です。さらに、応答本文のサイズが非常に大きいことがわかります。本文サイズが大きいことが原因であり、各リクエストでそれだけのデータを転送することが、その2秒の大半を占めています。

このイシューについて、チームは次のように決定する可能性があります:

- より多くの仮想CPUを搭載したRunnerを使用する。これにより、APIファジングが実行される作業を並行して実行できるようになるため。これにより、テスト時間を短縮できますが、オペレーションのテストに時間がかかるため、CPUの高いマシンに移行しないと、テストを10分未満に抑えるのは難しい場合があります。大規模なRunnerはコストがかかりますが、ジョブの実行が速ければ、支払う時間も少なくなります。
- [このオペレーションを](#excluding-slow-operations)APIファジングテストから除外する。これは最も簡単ですが、セキュリティのテストカバレッジにギャップが生じるという欠点があります。
- [フィーチャーブランチのAPIファジングテストからオペレーションを除外するが、デフォルトブランチテストに含める](#excluding-operations-in-feature-branches-but-not-default-branch)。
- [APIファジングテストを複数のジョブに分割する](#splitting-a-test-into-multiple-jobs)。

チームの要件が5〜7分の範囲内であると仮定すると、おそらくこれらのソリューションを組み合わせて、許容できるテスト時間に到達するのが妥当なソリューションでしょう。

## パフォーマンスイシューへの対処 {#addressing-performance-issues}

以下のセクションでは、APIファジングのパフォーマンスイシューに対処するためのさまざまなオプションについて説明します:

- [大規模なRunnerの使用](#using-a-larger-runner)
- [低速なオペレーションの除外](#excluding-slow-operations)
- [APIファジングテストを複数のジョブに分割する](#splitting-a-test-into-multiple-jobs)
- [フィーチャーブランチのオペレーションを除外するが、デフォルトブランチは除外しない](#excluding-operations-in-feature-branches-but-not-default-branch)

### 大規模なRunnerの使用 {#using-a-larger-runner}

最も簡単なパフォーマンス向上策の1つは、APIファジングで[大規模なRunner](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64)を使用することです。この表は、Java Spring Boot REST APIのベンチマーク中に収集された統計を示しています。このベンチマークでは、ターゲットとAPIファジングは1つのRunnerインスタンスを共有します。

| Linuxタグ上のホストされたRunner           | 1秒あたりのリクエスト数（RPS） |
|------------------------------------|-----------|
| `saas-linux-small-amd64`（デフォルト） | 255 |
| `saas-linux-medium-amd64`          | 400 |

この表からわかるように、Runnerと仮想CPUのサイズを大きくすると、テスト速度/パフォーマンスに大きな影響を与える可能性があります。

これは、Linux上のメディアムSaaS Runnerを使用するために`tags`セクションを追加するAPIファジングのジョブ定義の例です。ジョブは、APIファジングテンプレートを介して含まれるジョブ定義を拡張します。

```yaml
apifuzzer_fuzz:
  tags:
  - saas-linux-medium-amd64
```

`gl-api-security-scanner.log`ファイルで、文字列`Starting work item processor`を検索して、レポートされた最大DOP（並列度）を調べることができます。最大DOPは、Runnerに割り当てられた仮想CPU数以上である必要があります。イシューを特定できない場合は、サポートに割り当てて支援を求めてください。

ログエントリの例:

`17:00:01.084 [INF] <Peach.Web.Core.Services.WebRunnerMachine> Starting work item processor with 4 max DOP`

### 低速なオペレーションの除外 {#excluding-slow-operations}

1つまたは2つの低速なオペレーションの場合、チームはオペレーションのテストをスキップすることを決定する場合があります。オペレーションの除外は、`FUZZAPI_EXCLUDE_PATHS`[このセクションで説明されているように変数を使用](configuration/customizing_analyzer_settings.md#exclude-paths)して行われます。

この例では、大量のデータを返すオペレーションがあります。オペレーションは`GET http://target:7777/api/large_response_json`です。これを除外するために、オペレーションURLのパス部分`/api/large_response_json`を持つ`FUZZAPI_EXCLUDE_PATHS`変数を設定に指定します。

オペレーションが除外されていることを確認するには、APIファジングジョブを実行し、ジョブコンソールの出力をレビューします。テストの最後に、含まれているオペレーションと除外されているオペレーションのリストが含まれています。

```yaml
apifuzzer_fuzz:
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/large_response_json
```

{{< alert type="warning" >}}

テストからオペレーションを除外すると、一部の脆弱性が検出されないままになる可能性があります。

{{< /alert >}}

### テストを複数のジョブに分割する {#splitting-a-test-into-multiple-jobs}

テストを複数のジョブに分割することは、[`FUZZAPI_EXCLUDE_PATHS`](configuration/customizing_analyzer_settings.md#exclude-paths)と[`FUZZAPI_EXCLUDE_URLS`](configuration/customizing_analyzer_settings.md#exclude-urls)を使用することで、APIファジングでサポートされています。テストを分割する場合、適切なパターンは、`apifuzzer_fuzz`ジョブを無効にして、識別名を持つ2つのジョブに置き換えることです。この例では、2つのジョブがあり、各ジョブはAPIのバージョンをテストしているため、名前はそれを反映しています。ただし、この手法は、APIのバージョンだけでなく、あらゆる状況に適用できます。

`apifuzzer_v1`ジョブと`apifuzzer_v2`ジョブで使用しているルールは、[APIファジングテンプレート](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/DAST-API.gitlab-ci.yml)からコピーされたものです。

```yaml
# Disable the main apifuzzer_fuzz job
apifuzzer_fuzz:
  rules:
    - if: $CI_COMMIT_BRANCH
      when: never

apifuzzer_v1:
  extends: apifuzzer_fuzz
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/v1/**
  rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH == 'true' &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH == '1' &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH

apifuzzer_v2:
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/v2/**
  rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH
```

### フィーチャーブランチのオペレーションを除外するが、デフォルトブランチは除外しない {#excluding-operations-in-feature-branches-but-not-default-branch}

1つまたは2つの低速なオペレーションの場合、チームはオペレーションのテストをスキップするか、フィーチャーブランチテストから除外することを決定する場合がありますが、デフォルトブランチテストには含めます。オペレーションの除外は、`FUZZAPI_EXCLUDE_PATHS`[このセクションで説明されているように変数を使用](configuration/customizing_analyzer_settings.md#exclude-paths)して行われます。

この例では、大量のデータを返すオペレーションがあります。オペレーションは`GET http://target:7777/api/large_response_json`です。これを除外するために、オペレーションURLのパス部分`/api/large_response_json`を持つ`FUZZAPI_EXCLUDE_PATHS`変数を設定に指定します。当社の設定では、メインの`apifuzzer_fuzz`ジョブを無効にし、2つの新しいジョブ`apifuzzer_main`と`apifuzzer_branch`を作成します。`apifuzzer_branch`は、時間がかかるオペレーションを除外し、デフォルト以外のブランチ（たとえば、フィーチャーブランチ）でのみ実行するように設定されています。`apifuzzer_main`ブランチは、デフォルトブランチ（この例では`main`）でのみ実行するように設定されています。`apifuzzer_branch`ジョブは高速に実行されるため、迅速な開発サイクルが可能になりますが、デフォルトブランチビルドでのみ実行される`apifuzzer_main`ジョブの実行には時間がかかります。

オペレーションが除外されていることを確認するには、APIファジングジョブを実行し、ジョブコンソールの出力をレビューします。テストの最後に、含まれているオペレーションと除外されているオペレーションのリストが含まれています。

```yaml
# Disable the main job so we can create two jobs with
# different names
apifuzzer_fuzz:
  rules:
    - if: $CI_COMMIT_BRANCH
      when: never

# API fuzzing for feature branch work, excludes /api/large_response_json
apifuzzer_branch:
  extends: apifuzzer_fuzz
  variables:
    FUZZAPI_EXCLUDE_PATHS: /api/large_response_json
  rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: never
    - if: $CI_COMMIT_BRANCH

# API fuzzing for default branch (main in our case)
# Includes the long running operations
apifuzzer_main:
  extends: apifuzzer_fuzz
  rules:
    - if: $API_FUZZING_DISABLED == 'true' || $API_FUZZING_DISABLED == '1'
      when: never
    - if: $API_FUZZING_DISABLED_FOR_DEFAULT_BRANCH &&
            $CI_DEFAULT_BRANCH == $CI_COMMIT_REF_NAME
      when: never
    - if: $CI_COMMIT_BRANCH &&
          $CI_GITLAB_FIPS_MODE == "true"
      variables:
          FUZZAPI_IMAGE_SUFFIX: "-fips"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```
