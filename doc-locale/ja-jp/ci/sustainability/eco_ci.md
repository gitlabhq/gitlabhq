---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: CI/CDパイプラインのエネルギー消費量と炭素排出量をEco CIで測定します。
title: Eco CI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!note]
> Eco CIは、GitLab CI/CDパイプラインと連携するサードパーティ製のツールです。GitLabはこのツールを保守またはサポートせず、このツールがいかなる規制またはコンプライアンス要件も満たすことも表明しません。

[Eco CI](https://www.green-coding.io/products/eco-ci/)は、オープンソースのツールで、CI/CDパイプラインのエネルギー消費量と炭素排出量を測定します。これは、パイプラインジョブ内で軽量なbashスクリプトとして実行され、個別のサーバーやデータベースは必要ありません。

パイプラインジョブ内のコマンドの前後で測定スクリプトを配置します。このツールは、コマンド実行中のCPU使用率を監視し、SPECpowerデータベースからの事前計算された電力曲線を使用してエネルギー消費量を計算します。すべての測定結果はテキストファイルとして保存され、ダウンロードして表示するためにジョブアーティファクトとして保存できます。結果を外部ダッシュボードに送信して、履歴分析を行うこともできます。

## Eco CIをパイプラインに追加します {#add-eco-ci-to-your-pipeline}

Eco CIをパイプラインに追加して、ジョブ実行中のエネルギー消費と炭素排出量を測定します。

Eco CIは`ECO_CI_LABEL`変数を使用して測定値を識別しグループ化するため、プロジェクトまたはパイプラインステージを表す記述的な名前を選択してください。デフォルトでは、測定データは分析のためにGreen Coding Solutionsダッシュボードに送信されますが、`ECO_CI_SEND_DATA`を`false`に設定すると、結果をローカルにのみ保存できます。

前提条件: 

- bashをサポートするRunnerで実行されるパイプラインジョブ。
- Runner環境で`curl`、`jq`、`awk`、`bash`、`git`、および`coreutils`ユーティリティが利用できること。

Eco CIをパイプラインに追加するには:

1. `.gitlab-ci.yml`ファイルにEco CIテンプレートを含め、プロジェクトの識別子を設定します:

   ```yaml
   variables:
     ECO_CI_LABEL: "my-project-pipeline"
     ECO_CI_SEND_DATA: "false"

   include:
     - remote: 'https://raw.githubusercontent.com/green-coding-solutions/eco-ci-energy-estimation/main/eco-ci-gitlab.yml'
   ```

1. ジョブに測定スクリプトを追加します:

   ```yaml
   build-job:
     image: node:alpine
     before_script:
       - apk add --no-cache curl jq gawk bash git coreutils
     script:
       - !reference [.start_measurement, script]
       - npm install
       - npm run build
       - npm test
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]
     artifacts:
       paths:
         - eco-ci-output.txt
         - metrics.txt
       expire_in: 1 week
   ```

1. オプション。コマンドを個別に測定するには、各コマンドに測定スクリプトを使用します:

   ```yaml
   build-job:
     image: node:alpine
     before_script:
       - apk add --no-cache curl jq gawk bash git coreutils
     script:
       - !reference [.start_measurement, script]
       - npm install
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]

       - !reference [.start_measurement, script]
       - npm run build
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]

       - !reference [.start_measurement, script]
       - npm test
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]
     artifacts:
       paths:
         - eco-ci-output.txt
         - metrics.txt
       expire_in: 1 week
   ```

## 測定結果を表示する {#view-measurement-results}

Eco CIは、GitLabインターフェースを介してアクセスできるジョブアーティファクトに測定結果を保存します。測定結果には以下が含まれます:

- エネルギー消費量: ジュールおよびワットで表示されます。
- 炭素排出量: CO₂換算グラム（gCO₂eq）での推定排出量。
- 期間: 測定期間の長さ（秒単位）。
- CPU使用率: 測定中の平均CPU使用率。
- ソフトウェア炭素強度（SCI）: パイプライン実行あたりの炭素排出量。

測定結果を表示するには:

1. パイプラインに移動します。
1. Eco CIの測定値を含むジョブを選択します。
1. ジョブの詳細で、**ジョブのアーティファクト**の下にある**閲覧**を選択します。
1. `eco-ci-output.txt`ファイルを開きます。

出力例: 

```plaintext
"build-job: Label: my-project-pipeline: Energy Used [Joules]:" 5.82
"build-job: Label: my-project-pipeline: Avg. CPU Utilization:" 22.69
"build-job: Label: my-project-pipeline: Avg. Power [Watts]:" 1.91
"build-job: Label: my-project-pipeline: Duration [seconds]:" 3.04
----------------
"build-job: Energy [Joules]:" 5.82
"build-job: Avg. CPU Utilization:" 22.69
"build-job: Avg. Power [Watts]:" 1.91
"build-job: Duration [seconds]:" 3.04
----------------
🌳 CO2 Data:
CO₂ from energy is: 0.001944 g
CO₂ from manufacturing (embodied carbon) is: 0.000442 g
Carbon Intensity for this location: 334 gCO₂eq/kWh
SCI: 0.002386 gCO₂eq / pipeline run emitted
```

## ダッシュボードインテグレーション {#dashboard-integration}

`ECO_CI_SEND_DATA`を`true`に設定すると、測定データは自動的に[Eco CIメトリクスダッシュボード](https://metrics.green-coding.io/ci-index.html)に送信されます。ダッシュボードは、過去の記録、トレンド分析、およびパイプライン実行間の比較を提供します。デフォルトでは、ダッシュボードは公開されており、誰でも閲覧できます。

時間経過に伴うエネルギー消費トレンド、炭素排出パターンを表示し、異なるブランチ、コミット、または期間全体の測定値を比較できます。プロジェクトの`ECO_CI_LABEL`識別子を使用してダッシュボードにアクセスします。

### プロジェクトにバッジを追加する {#add-a-badge-to-your-project}

プロジェクトの`README.md`ファイルにEco CIバッジを表示して、エネルギー消費メトリクスを表示できます。

前提条件: 

- `ECO_CI_SEND_DATA`は`true`に設定する必要があります。
- 少なくとも1つのパイプラインが、Eco CIを有効にして正常に実行されている必要があります。

`README.md`ファイルにバッジを追加するには:

1. 次のコードを`README.md`ファイルにコピーして貼り付けます:

   ```markdown
   [![Eco CI](https://api.green-coding.io/v1/ci/badge/get?repo=<namespace>/<project>&branch=<branch>&workflow=<project-id>)](https://metrics.green-coding.io/ci.html?repo=<namespace>/<project>&branch=<branch>&workflow=<project-id>)
   ```

1. プレースホルダーを置き換えます:

   - `<namespace>/<project>`をプロジェクトのパスに置き換えます（例: `mygroup/myproject`）。
   - `<branch>`をブランチ名に置き換えます（例: `main`）。
   - `<project-id>`をプロジェクトIDに置き換えます（例: `52215136`）。

例: 

```markdown
[![Eco CI](https://api.green-coding.io/v1/ci/badge/get?repo=lyspin/eco-ci-demo&branch=main&workflow=52215136)](https://metrics.green-coding.io/ci.html?repo=lyspin/eco-ci-demo&branch=main&workflow=52215136)
```

## トラブルシューティング {#troubleshooting}

Eco CIを使用しているときに、次の問題に遭遇する可能性があります。

### エラー: Dateがマイクロ秒単位で正確でないタイムスタンプを返しました {#error-date-has-returned-a-timestamp-that-is-not-accurate-to-microseconds}

エラーメッセージが表示されることがあります:

```shell
ERROR: Date has returned a timestamp that is not accurate to microseconds! You may need to install `coreutils`.
```

この問題は、alpine LinuxまたはGNU `coreutils`がデフォルトで含まれていないその他の最小限のディストリビューションを使用している場合に発生します。

この問題を解決するには、`coreutils`をインストールします。例えば、alpineの場合:

```yaml
before_script:
  - apk add --no-cache coreutils
```

### アーティファクトに測定データが表示されない {#no-measurement-data-appears-in-artifacts}

ジョブアーティファクトに`eco-ci-output.txt`ファイルが表示されません。

この問題は、アーティファクトの設定が不足していることが原因である可能性があります。そのため、ジョブに正しい`artifacts`設定が含まれていることを確認してください:

```yaml
artifacts:
  paths:
    - eco-ci-output.txt
    - metrics.txt
```

### 測定値がゼロのエネルギー消費量を示す {#measurements-show-zero-energy-consumption}

`eco-ci-output.txt`ファイルに`Energy [Joules]: 0.00`のような値が表示されます。

この問題は、測定スクリプトが誤って配置された場合に発生します。

この問題を解決するには、測定スクリプトがCPU負荷の高いコマンドを囲むようにしてください:

```yaml
script:
  - !reference [.start_measurement, script]
  - npm install  # CPU-intensive command
  - npm run build  # CPU-intensive command
  - !reference [.get_measurement, script]
  - !reference [.display_results, script]
```
