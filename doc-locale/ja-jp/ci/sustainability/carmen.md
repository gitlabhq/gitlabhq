---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: クラウドインフラストラクチャとアプリケーションからの炭素排出量をCarmenで測定します。
title: Carmen
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

> [!warning]
> Carmenは、Green Software Foundationによって承認または採用されていないドラフトソフトウェアです。Carmenは、開発の現状を確認する以外の目的で使用しないでください。GitLabは本ツールを保守またはサポートせず、本ツールがいかなる規制またはコンプライアンス要件も満たすことを表明しません。Carmenは、企業のESGレポート、コンプライアンス開示、またはマーケティング資料には適していません。

[Carmen](https://github.com/Green-Software-Foundation/if-carmen)（Carbon Measurement Engine）は、クラウドインフラストラクチャとアプリケーションからの炭素排出量を測定するオープンソースツールです。

Carmenは、2つのソースから炭素排出量を測定します:

- インフラストラクチャ: 仮想マシンとクラウドワークロードからのエネルギー消費と炭素排出量を、VM使用状況データ（CSV形式）を使用して測定します。
- アプリケーション: Kubernetesクラスターで実行されている個々のワークロードとポッドからの炭素排出量を、Prometheusメトリクスを使用して測定します。

Carmenは、Grafana、FinOpsダッシュボード、または独自のツールで使用できるCSVレポートを出力します。

## 入力データ形式 {#input-data-format}

Carmenデーモンは、VM使用状況データをCSV形式で予期しています。ローカルファイルの場合は、`config.yaml`をCSVがあるパスに指定します。Azure Blob Storageを使用する場合は、`config.yaml`でストレージアカウントを設定すると、Carmenがデータを直接読み取ります。

必須フィールドは次のとおりです:

| フィールド                  | 説明                                                    | 例 |
| ---------------------- | -------------------------------------------------------------- | ------- |
| `Time`                 | ISO 8601形式のタイムスタンプ。                                  | `2024-10-15T14:30:00Z` |
| `Id`                   | VMの固有識別子（レポートの粒度を制御します）。    | `vm-a1b2c3d4` |
| `Size`                 | VMインスタンスサイズ。                                              | `Standard_D4s_v3` |
| `Region`               | VMがデプロイされているリージョン。                               | `eastus` |
| `Service`              | クラウドサービスまたは製品カテゴリ。                             | `Compute` |
| `Component`            | VMが提供するアプリケーションレイヤー。                               | `api-gateway` |
| `Subscription`         | クラウドサブスクリプション識別子。                                 | `prod-subscription-001` |
| `Name`                 | 人間が判読できるVM名。                                        | `production-web-01` |
| `Instance`             | デプロイグループ内のVMのインスタンス識別子。            | `web-server-03` |
| `Environment`          | デプロイ環境。                                        | `production` |
| `Partition`            | 論理パーティションまたはテナント。                                   | `team-finance` |
| `AverageCpuPercentage` | 測定期間中の平均CPU使用率（0-100）。 | `45.7`  |
| `DiskSizeGb`           | プロビジョニングされたディスクストレージの合計容量（ギガバイト単位）。                   | `128`   |

`Id`フィールドはレポートの粒度を制御します。`Id`の一意の値ごとに、出力で1つのコンポーネントが生成されます。VMごとの設定が一般的ですが、必要なインサイトに応じて、より粗い識別子（サービスごと）またはより細かい識別子を使用できます。

## Carmenをパイプラインに追加する {#add-carmen-to-your-pipeline}

CarmenをCI/CDジョブとして実行し、VM使用状況データから炭素排出量レポートを生成し、パイプラインアーティファクトとして保存できます。

前提条件: 

- お使いのRunner環境にPython 3.12、Pip、NPM、Git、`lsb-release`、およびbashがインストールされていること。
- 必要な形式のローカルCSVファイルとしてのVM使用状況データ。CarmenはAzure Blob Storageからの読み取りもサポートしています。
- 既知のパスにある`config.yaml`ファイル。

Carmenをパイプラインに追加するには:

1. お使いの`.gitlab-ci.yml`ファイルに、Carmenをインストールし、Carmenに同梱されているサンプルデータに対してデーモンを実行するジョブを追加します:

   ```yaml
   carbon-report:
     image: python:3.12
     before_script:
       - apt-get update && apt-get install -y nodejs npm git lsb-release
       - git clone https://github.com/Green-Software-Foundation/if-carmen.git
       - npm install -g "@grnsft/if@1.0.0" "@grnsft/if-plugins@0.3.2" "@grnsft/if-unofficial-plugins@0.3.1"
       - pip install --upgrade pip && pip install -e $CI_PROJECT_DIR/if-carmen
     script:
       - cd $CI_PROJECT_DIR/if-carmen/example-data && carbon-daemon
     artifacts:
       paths:
         - if-carmen/example-data/output/
       expire_in: 1 week
   ```

1. パイプラインを実行し、ジョブがアーティファクトに`CO2_<date>.csv`ファイルと、`EnergykWh`および`TotalCarbonGramsCO2eq`列にゼロ以外の値を生成することを確認します。
1. ローカルのCSVデータを指す`config.yaml`をリポジトリに追加します:

   ```yaml
   carmen_daemon:
     source:
       type: local
       file_names:
         - "vm_metrics.csv"
       local:
         source_path: "data/vm-metrics"
     upload:
       type: local
       local:
         upload_path: "./output"
   ```

   Azure Blob Storageの場合、`source.type`を`azure`に設定し、Azureストレージアカウントの設定と認証情報を追加します。すべてのオプションについては、[Carmen設定](https://github.com/Green-Software-Foundation/if-carmen/blob/dev/docs/configuration.md)を参照してください。

1. お使いのジョブの`script`セクションと`artifacts`セクションを置き換えます:

   ```yaml
   script:
     - mkdir -p $CI_PROJECT_DIR/output
     - cd $CI_PROJECT_DIR && carbon-daemon
   artifacts:
     paths:
       - output/
     expire_in: 1 week
   ```

1. パイプラインを再度実行し、出力`CO2_<date>.csv`に独自のデータが含まれていることを確認します。

## 結果の表示 {#view-results}

Carmenは、コンポーネント（VM）ごとに1行のCSVレポートを日別に生成します。出力ファイルは`CO2_<date>.csv`の命名パターンに従い、`upload.local.upload_path`で設定されたパスに保存されます。

結果を表示するには:

1. お使いのパイプラインに移動します。
1. `carbon-report`ジョブを選択します。
1. **ジョブのアーティファクト**の下で、**閲覧**を選択します。
1. `CO2_<date>.csv`ファイルを開きます。

このレポートには、次のフィールドが含まれています:

| フィールド                         | 説明 |
| ----------------------------- | ----------- |
| `Date`                        | 24時間のレポートバケット。 |
| `Id`                          | コンポーネント（VM）の固有識別子。 |
| `Name`                        | VMの人間が判読できる名前。 |
| `EnergykWh`                   | 消費された総エネルギー量（キロワット時）。 |
| `OperationalCarbonGramsCO2eq` | 稼働中のエネルギー消費による炭素排出量。 |
| `EmbodiedCarbonGramsCO2eq`    | ハードウェアの製造、輸送、廃棄による炭素排出量。 |
| `TotalCarbonGramsCO2eq`       | 稼働中と組み込みの炭素排出量の合計。 |
| `CarbonIntensity`             | 地域の電力網の炭素強度（gCO2eq/kWh）。 |

## アプリケーション測定 {#application-measurement}

Kubernetesクラスター内の個々のワークロードの炭素排出量測定には、CarmenをサイドカーAPIサービスとしてPrometheusとともにデプロイできます。このモードでは、設定可能な間隔でポッドごとのCPUおよびメモリメトリクスをプルすることができます。

このデプロイには、Helm、Prometheus、kube-state-metrics、およびcAdvisorがインストールされたKubernetesクラスターが必要です。詳細については、Carmenリポジトリの[Carmen as a Service](https://github.com/Green-Software-Foundation/if-carmen/blob/dev/docs/carmen-as-a-service.md)を参照してください。

## トラブルシューティング {#troubleshooting}

Carmenを使用する際、次の問題に遭遇する可能性があります。

### 最初のレポート出力が正しくないように見える {#first-report-output-looks-incorrect}

炭素排出量の値が予想外に高いか低いように見えます。

この問題は、実際のVM仕様が提供されなかったため、Carmenがデフォルトのベンチマークハードウェア設定にフォールバックしたときに発生します。

この問題を解決するには、クラウドプロバイダーのAPIから実際のVM仕様を提供してください。

### 出力にVMごとに1行しか含まれていない {#output-contains-only-one-row-per-vm}

お使いのレポートの行数が予想より少ないです。

この問題は、複数のレコードが同じ`Id`値を共有している場合に発生します。

この問題を解決するには、入力CSVの`Id`列を確認してください。`Id`の一意の値ごとに、出力で1つのコンポーネントが生成されます。

### Carmenが出力を生成しない {#carmen-produces-no-output}

`carbon-daemon`の実行後、出力ディレクトリが空です。

この問題は、Impact Frameworkがグローバルにインストールされていないか、または`config.yaml`パスが`carbon-daemon`を実行するディレクトリから解決できない場合に発生する可能性があります。

この問題を解決するには、次の手順に従います:

- `@grnsft/if`がインストールされており、アクセス可能であることを確認します: `if-run --version`
- `config.yaml`内のパスが作業ディレクトリから解決することを確認します。

### 測定値は日次合計のみに集計される {#measurements-aggregate-to-daily-totals-only}

時間ごとまたは日中の炭素排出量が必要です。

Carmenは日次合計のみに集計します。時間単位の解像度は既知の制限事項です。
