---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: 脆弱性データのエクスポートからSplunk、CI/CDパイプラインのセットアップ、ダッシュボードの設定、ベストプラクティスなど、GitLab Security Metrics and KPIsソリューションのデプロイに関するガイド。
title: セキュリティメトリクスとKPI
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このドキュメントでは、GitLab Security Metrics and KPIsソリューションコンポーネントのインストール、設定、およびユーザーガイドについて説明します。このセキュリティソリューションコンポーネントは、ビジネスユニット、期間、脆弱性の重大度、およびセキュリティタイプ別に表示できるメトリクスとKPIを提供します。PDFドキュメントで、月単位または四半期単位でセキュリティ対策状況のスナップショットを提供できます。データはSplunkのダッシュボードを使用して可視化されます。

![セキュリティメトリクスとKPI](img/security_metrics_kpi_v17_9.png)

このソリューションは、GraphQL APIを使用してGitLabプロジェクトまたはグループから脆弱性データをエクスポートし、HTTP Event Collector（HEC）を介してSplunkに送信し、すぐに使用できるセキュリティ指標の可視化のためのダッシュボードが含まれています。エクスポートプロセスは、スケジュールに基づいてGitLab CDパイプラインとして実行するように設計されています。

## はじめに {#getting-started}

### ソリューションコンポーネントのダウンロード {#download-the-solution-component}

1. アカウントチームから招待コードを入手してください。
1. 招待コードを使用して、[ソリューションコンポーネントのWebストア](https://cloud.gitlab-accelerator-marketplace.com)からソリューションコンポーネントをダウンロードします。

### ソリューションコンポーネントプロジェクトのセットアップ {#set-up-the-solution-component-project}

1. このエクスポーターをホストする新しいGitLabプロジェクトを作成します。
1. 提供されたファイルをプロジェクトにコピーします:
   - `export_vulns.py`
   - `send_to_splunk.py`
   - `requirements.txt`
   - `.gitlab-ci.yml`
1. プロジェクトの設定で、必須のCI/CD変数を設定します。
1. パイプラインスケジュールを設定します（たとえば、毎日または毎週）。

## 仕組み {#how-it-works}

このソリューションは、主に2つのコンポーネントで構成されています:

1. GitLabセキュリティダッシュボードからデータをフェッチする脆弱性エクスポーター

1. エクスポートされたデータを処理してSplunk HECに送信するSplunk取り込みツール

パイプラインは2つのステージで実行されます:

1. `extract`: 脆弱性をフェッチし、CSVに保存します

1. `ingest`: 脆弱性データをSplunkに送信します

## 設定 {#configuration}

### 必須CI/CD変数 {#required-cicd-variables}

| 変数 | 説明 | 値の例 |
|----------|-------------|---------------|
| `SCOPE` | 脆弱性スキャンのターゲットスコープ | `group:security/appsec`または`security/my-project` |
| `GRAPHQL_API_TOKEN` | APIアクセスを持つGitLabパーソナルアクセストークン | `glpat-XXXXXXXXXXXXXXXX` |
| `GRAPHQL_API_URL` | GitLab GraphQL API URL | `https://gitlab.com/api/graphql` |
| `SPLUNK_HEC_TOKEN` | Splunk HTTP Event Collectorトークン | `11111111-2222-3333-4444-555555555555` |
| `SPLUNK_HEC_URL` | Splunk HECエンドポイントAPI URL | `https://splunk.company.com:8088/services/collector` |

### オプションのCI/CD変数 {#optional-cicd-variables}

| 変数 | 説明 | 値の例 | デフォルト |
|----------|-------------|---------------|---------|
| `SEVERITY_FILTER` | カンマ区切りの重大度レベルのリスト | `CRITICAL,HIGH,MEDIUM` | すべての重大度 |
| `VULN_TIME_WINDOW` | 脆弱性収集の期間 | `24h`、`7d`、または`all` | `24h` |

### スコープの設定 {#scope-configuration}

`SCOPE`変数は、スキャンするプロジェクトまたはグループを決定します:

- プロジェクトの場合: `mygroup/myproject`
- グループの場合: `group:mygroup/subgroup`
- インスタンス全体の場合: `instance`

### 重大度フィルターの例 {#severity-filter-examples}

有効な重大度レベル:

- `CRITICAL`
- `HIGH`
- `MEDIUM`
- `LOW`
- `UNKNOWN`

組み合わせの例:

- `CRITICAL,HIGH`
- `CRITICAL,HIGH,MEDIUM`
- すべての重大度を含めるには、空のままにします

### 期間の設定 {#time-window-configuration}

`VULN_TIME_WINDOW`変数は、脆弱性をどこまで遡って検索するかを制御します:

- 形式: `<number><unit>`。各設定項目の意味は次のとおりです。
  - `number`: 任意の正の整数
  - `unit`: 時間の場合は`h`、日の場合は`d`
- 例: 
  - `24h`: 過去24時間
  - `7h`: 過去7時間
  - `15d`: 過去15日間
  - `30d`: 過去30日間
  - `all`: すべての脆弱性（初回実行に役立ちます）

デフォルト値: `24h`

パイプライン構成の例:

```yaml
# For 12-hour window
variables:
  VULN_TIME_WINDOW: "12h"

# For 3-day window
variables:
  VULN_TIME_WINDOW: "3d"

# For all vulnerabilities
variables:
  VULN_TIME_WINDOW: "all"
```

選択した期間に基づいてパイプラインをスケジュールします。例: 

- 12時間の場合: 1日に2回スケジュールします
- 3日間の場合: 3日ごとにスケジュールします
- 脆弱性が見落とされないように、スケジュールに多少のオーバーラップを追加します

## パイプラインのセットアップ {#pipeline-setup}

1. **First Run**（初回実行）:

   - すべての履歴脆弱性を収集するために`VULN_TIME_WINDOW: "all"`を設定します
   - パイプラインを一度実行します。

1. **Ongoing Collection**（継続的な収集）:

   - `VULN_TIME_WINDOW`を目的の期間（`24h`または`7d`）に設定します
   - パイプラインスケジュールを設定します:
     - `24h`の場合: 毎日スケジュールします
     - `7d`の場合: 毎週スケジュールします

## Splunkインテグレーション {#splunk-integration}

このスクリプトは、脆弱性をイベントとしてSplunkに送信します。

### インデックスの設定 {#index-configuration}

1. Splunkに`gitlab_vulns`という名前の新しいインデックスを作成します

1. HECトークンを作成する場合:
   - デフォルトの**インデックス**を`gitlab_vulns`に設定します（このインデックスは、提供されているSplunkダッシュボードの基本検索で参照されます）
   - このインデックスに書き込む権限がトークンにあることを確認します
   - トークンに、イベントデータがJSONとして正しく解析されるようにする**sourcetype**があることを確認してください

各イベントには以下が含まれます:

- 検出時間
- 脆弱性のタイトルと説明
- 重大度レベル
- スキャナー情報
- プロジェクト詳細
- プロジェクトと脆弱性両方のURL

## ダッシュボードのセットアップ {#dashboard-setup}

提供されているダッシュボードは、次の可視化により、GitLab脆弱性データへの包括的な可視性を提供します:

- 重大な脆弱性と高重大度の脆弱性のP95 Ageメトリクス（ラジアルゲージ）
- 重大な脆弱性と高重大度の脆弱性の経過時間バケット（0〜30日、31〜90日、91〜180日、180日以上）にわたる分布を示す経過時間分析
- 発生数が多い上位10個のCVE
- プロジェクトパスと重大度別の脆弱性の分布
- すべてのメトリクスは、ビジネスユニットと期間でフィルタリングできます

ダッシュボードを設定するには:

1. **Business Unit Mapping**（ビジネスユニットのマッピング）:
   1. 2つの列を持つCSVファイルを作成します:

     ```shell
     project_url,business_unit
     ```

   1. 各GitLabプロジェクトURLを対応するビジネスユニットにマップします。
   1. ルックアップテーブルとして、ファイルをSplunkにアップロードします:
      1. **設定** > **Lookups**（ルックアップ） > **Lookup table files**（ルックアップテーブルファイル）に移動します。
      1. **New Lookup Table File**（新しいルックアップテーブルファイル）を選択します。
      1. CSVファイルをアップロードします。
      1. **Destination filename**（宛先ファイル名）を`business_unit_mapping.csv`に設定します。
      1. 権限を設定します:
         1. `<splunk_dir>/etc/apps/search/lookups/business_unit_mapping.csv`というラベルの付いた行を見つけます。
         1. **権限**を選択します。
         1. 権限を次のいずれかに設定します:
            - インスタンス全体のアクセスには、**グローバル**に設定します。
            - 必要に応じて、特定のアプリまたはロールと共有します。
         1. **保存**を選択します。

1. **Dashboard Installation**（ダッシュボードのインストール）:
   1. 提供されている`vuln_metrics_dashboard.xml`ファイルを保存します。
   1. Splunkで:
      1. 検索アプリに移動します。
      1. **Dashboards**（ダッシュボード） > **Create New Dashboard**（新しいダッシュボードを作成）をクリックします。
      1. 編集ビューで**ソース**を選択します。
      1. デフォルトのXMLを`vuln_metrics_dashboard.xml`の内容に置き換えます。
      1. ダッシュボードを保存します。

## 出力形式 {#output-format}

中間CSVファイルには、以下が含まれます:

- `detectedAt`: 検出タイムスタンプ
- `title`: 脆弱性タイトル
- `severity`: 重大度レベル
- `primaryIdentifier`: 脆弱性識別子
- `exporter`: スキャナー名
- `projectPath`: GitLabプロジェクトパス
- `projectUrl`: プロジェクトURL
- `description`: 脆弱性の説明
- `webUrl`: 脆弱性の詳細URL

## エラー処理 {#error-handling}

このソリューションには、以下が含まれています:

- 指数バックオフによるレート制限処理
- Splunk取り込みのバッチ処理
- 適切なエラー報告
- タイムアウト処理
- UTF-8エンコードのサポート

## ベストプラクティス {#best-practices}

1. **Token Permissions**（トークン）権限:

   - GRAPHQL_API_TOKENに必要なもの:
     - ターゲットグループ/プロジェクトへの読み取りアクセス
     - セキュリティダッシュボードアクセス
   - SPLUNK_HEC_TOKENに必要なもの:
     - ターゲットインデックスへのイベント送信権限

1. **Schedule Frequency**（パイプラインスケジュール頻度）:

   - スケジュールを`VULN_TIME_WINDOW`に一致させます
   - 脆弱性の見落としを防ぐために、オーバーラップを含めます
   - 組織のSLAを検討してください

1. **モニタリング**: 

   - パイプラインの成功/失敗を監視します
   - エクスポートされた脆弱性の数を追跡します
   - Splunk取り込みの成功を監視します

## トラブルシューティング {#troubleshooting}

一般的な問題と解決策:

1. **No vulnerabilities exported**（脆弱性がエクスポートされない）:

   - スコープ設定を確認します
   - トークン権限を確認してください
   - セキュリティダッシュボードアクセスを確認します

1. **Splunk ingestion fails**（Splunk取り込みが失敗する）:

   - HEC URLとトークンを確認します
   - ネットワーク接続を確認してください
   - インデックスの権限を確認します
