---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: GitLabセキュリティメトリクスおよびKPIソリューションをデプロイするためのガイド。脆弱性データのエクスポートからSplunkへのエクスポート、CI/CDパイプラインの設定、ダッシュボードの設定、ベストプラクティスが含まれます。
title: セキュリティメトリクスとKPI
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このドキュメントは、GitLabセキュリティメトリクスおよびKPIソリューションコンポーネントのインストール、設定、およびユーザーガイドを説明します。このセキュリティソリューションコンポーネントは、ビジネスユニット、時間範囲、脆弱性の重大度、およびセキュリティタイプ別に表示できるメトリクスとKPIを提供します。PDFドキュメントを使用して、月次または四半期ベースでセキュリティ対策状況のスナップショットを提供できます。データはSplunkのダッシュボードを使用して可視化されます。

![セキュリティメトリクスとKPI](img/security_metrics_kpi_v17_9.png)

このソリューションは、GitLabプロジェクトまたはグループからGraphQL APIを使用して脆弱性データをエクスポートし、HTTP Event Collector（HEC）を介してSplunkに送信し、セキュリティメトリクスの可視化のためにすぐに使えるダッシュボードを含みます。エクスポート処理は、GitLab CI/CDパイプラインとして定期的に実行されるように設計されています。

## はじめに {#getting-started}

### ソリューションコンポーネントをダウンロードする {#download-the-solution-component}

1. アカウントチームから招待コードを取得します。
1. 招待コードを使用して、[ソリューションコンポーネントのウェブストア](https://cloud.gitlab-accelerator-marketplace.com)からソリューションコンポーネントをダウンロードしてください。

### ソリューションコンポーネントプロジェクトをセットアップする {#set-up-the-solution-component-project}

1. このexporterをホストする新しいGitLabプロジェクトを作成します。
1. 提供されたファイルをプロジェクトにコピーします:
   - `export_vulns.py`
   - `send_to_splunk.py`
   - `requirements.txt`
   - `.gitlab-ci.yml`
1. プロジェクトの設定で必要なCI/CD変数を設定します。
1. パイプラインスケジュールを設定します（例: 毎日または毎週）。

## 仕組み {#how-it-works}

このソリューションは、2つの主要なコンポーネントで構成されています:

1. GitLabセキュリティダッシュボードからデータをフェッチする脆弱性exporter
1. エクスポートされたデータを処理し、Splunk HECに送信するSplunkインジェスター

パイプラインは2つのパイプラインステージで実行されます:

1. `extract`: 脆弱性をフェッチし、CSVに保存します
1. `ingest`: 脆弱性データをSplunkに送信します

## 設定 {#configuration}

### 必須CI/CD変数 {#required-cicd-variables}

| 変数 | 説明 | 例の値 |
|----------|-------------|---------------|
| `SCOPE` | 脆弱性スキャンのターゲットスコープ | `group:security/appsec`または`security/my-project` |
| `GRAPHQL_API_TOKEN` | APIアクセス権を持つGitLabパーソナルアクセストークン | `glpat-XXXXXXXXXXXXXXXX` |
| `GRAPHQL_API_URL` | GitLab GraphQL API URL | `https://gitlab.com/api/graphql` |
| `SPLUNK_HEC_TOKEN` | Splunk HTTP Event Collectorトークン | `11111111-2222-3333-4444-555555555555` |
| `SPLUNK_HEC_URL` | Splunk HECエンドポイントURL | `https://splunk.company.com:8088/services/collector` |

### オプションのCI/CD変数 {#optional-cicd-variables}

| 変数 | 説明 | 例の値 | デフォルト |
|----------|-------------|---------------|---------|
| `SEVERITY_FILTER` | カンマ区切りの重大度レベルのリスト | `CRITICAL,HIGH,MEDIUM` | すべての重大度 |
| `VULN_TIME_WINDOW` | 脆弱性収集の時間枠 | `24h`、`7d`、または`all` | `24h` |

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
- すべての重大度を含めるには空のままにします

### タイムウィンドウの設定 {#time-window-configuration}

`VULN_TIME_WINDOW`変数は、脆弱性を検索する期間を制御します:

- 形式: `<number><unit>`ここで:
  - `number`: 任意の正の整数
  - `unit`: 時間の場合は`h`、日の場合は`d`
- 例: 
  - `24h`: 過去24時間
  - `7h`: 過去7時間
  - `15d`: 過去15日
  - `30d`: 過去30日
  - `all`: すべての脆弱性（初回実行時に役立ちます）

デフォルト値: `24h`

パイプライン設定の例:

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

- 12時間の場合: 毎日2回スケジュールする
- 3日間の場合: 3日ごとにスケジュールする
- 脆弱性を見逃さないように、スケジューリングに重複を追加します。

## パイプラインのセットアップ {#pipeline-setup}

1. **初回実行時**:

   - すべての過去の脆弱性を収集するために`VULN_TIME_WINDOW: "all"`を設定します
   - パイプラインを1回実行します

1. **継続的な収集**:

   - `VULN_TIME_WINDOW`を希望する期間（`24h`または`7d`）に設定します
   - パイプラインスケジュールを設定します:
     - `24h`の場合: 毎日スケジュールする
     - `7d`の場合: 毎週スケジュールする

## Splunkインテグレーション {#splunk-integration}

スクリプトは脆弱性をイベントとしてSplunkに送信します。

### インデックスの設定 {#index-configuration}

1. Splunkで`gitlab_vulns`という名前の新しいインデックスを作成します
1. HECトークンを作成する際:
   - デフォルトの**インデックス**を`gitlab_vulns`に設定します（このインデックスは、提供されるSplunkダッシュボードのベース検索で参照されます）
   - トークンにこのインデックスへの書き込み権限があることを確認します
   - トークンに、イベントデータをJSONとして正しく解析できる**sourcetype**があることを確認します

各イベントには以下が含まれます:

- 検出時間
- 脆弱性のタイトルと説明
- 重大度レベル
- スキャナー情報
- プロジェクトの詳細
- プロジェクトと脆弱性の両方のURL

## ダッシュボードのセットアップ {#dashboard-setup}

提供されたダッシュボードは、以下の可視化によりGitLabの脆弱性データに関する包括的な表示レベルを提供します:

- 致命的および高重大度の脆弱性に対するP95経年メトリクス（ラジアルゲージ）
- 致命的および高重大度の脆弱性の経年バケット（0〜30日、31〜90日、91〜180日、180日以上）にわたる分布を示す経年分析
- 発生数を含む上位10の最も頻繁なCVE
- プロジェクトパスと重大度による脆弱性分布
- すべてのメトリクスは、ビジネスユニットと時間範囲でフィルターできます。

ダッシュボードを設定するには:

1. **ビジネスユニットのマッピング**:
   1. 2つの列を持つCSVファイルを作成します:

      ```shell
      project_url,business_unit
      ```

   1. 各GitLabプロジェクトURLを対応するビジネスユニットにマップします。
   1. ファイルをルックアップテーブルとしてSplunkにアップロードします:
      1. **設定** > **Lookups** > **Lookup table files**に進みます。
      1. **New Lookup Table File**を選択します。
      1. CSVファイルをアップロードします。
      1. **Destination filename**を`business_unit_mapping.csv`に設定します。
      1. 権限を設定します:
         1. `<splunk_dir>/etc/apps/search/lookups/business_unit_mapping.csv`というラベルの行を見つけます。
         1. **権限**を選択します。
         1. 権限を次のいずれかに設定します:
            - インスタンス全体でのアクセスを許可するために**グローバル**に設定します。
            - 必要に応じて特定のアプリまたはロールと共有します。
         1. **保存**を選択します。

1. **ダッシュボードのインストール**:
   1. 提供されている`vuln_metrics_dashboard.xml`ファイルを保存します。
   1. Splunkで:
      1. Searchアプリに移動します。
      1. **ダッシュボード** > **Create New Dashboard**をクリックします。
      1. 編集ビューで**ソース**を選択します。
      1. デフォルトのXMLを`vuln_metrics_dashboard.xml`の内容で置き換えます。
      1. ダッシュボードを保存します。

## 出力形式 {#output-format}

中間CSVファイルには以下が含まれます:

- `detectedAt`: 検出タイムスタンプ
- `title`: 脆弱性のタイトル
- `severity`: 重大度レベル
- `primaryIdentifier`: 脆弱性識別子
- `exporter`: スキャナー名
- `projectPath`: GitLabプロジェクトパス
- `projectUrl`: プロジェクトURL
- `description`: 脆弱性の説明
- `webUrl`: 脆弱性の詳細URL

## エラー処理 {#error-handling}

このソリューションには以下が含まれます:

- 指数関数的バックオフによるレート制限処理
- Splunkへの取り込みのためのバッチ処理
- 適切なエラーレポート
- タイムアウト処理
- UTF-8エンコードのサポート

## ベストプラクティス {#best-practices}

1. **トークン権限**:

   - GRAPHQL_API_トークンに必要なもの:
     - ターゲットグループ/プロジェクトへの読み取りアクセス
     - セキュリティダッシュボードへのアクセス
   - SPLUNK_HEC_トークンに必要なもの:
     - ターゲットインデックスへのイベント送信権限

1. **パイプラインスケジュール頻度**:

   - スケジュールを`VULN_TIME_WINDOW`と一致させます
   - 脆弱性を見逃さないように重複を含めます
   - 組織のSLAを考慮します

1. **モニタリング**: 

   - パイプラインの成功/失敗を監視します
   - エクスポートされた脆弱性の数を追跡します
   - Splunkへの取り込みの成功を監視します

## トラブルシューティング {#troubleshooting}

一般的な問題と解決策:

1. **脆弱性がエクスポートされない**:

   - スコープの設定を確認します
   - トークンの権限を確認します
   - セキュリティダッシュボードへのアクセスを確認します

1. **Splunk取り込みが失敗する**:

   - HEC URLとトークンを確認します
   - ネットワーク接続を確認します
   - インデックスの権限を確認します
