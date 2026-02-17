---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: CIベースのデータ収集パイプライン、GraphQL APIクライアント、Duo Analyticsダッシュボードを使用して、GitLab Duoの導入と使用状況を測定および視覚化します。
title: GitLab Duo導入メトリクスと分析
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## GitLab Duo導入メトリクスと分析 {#gitlab-duo-adoption-metrics--analytics}

このプロジェクトでは、次のものを組み合わせて、エンドツーエンドのGitLab Duoの使用状況分析を提供します:

- **Duo GraphQL Data Collection** – GitLab GraphQL APIクライアントによってバックアップされたDuoコレクタースクリプトを呼び出す汎用Pythonオーケストレーター。
- **Duo Usage Metrics Pipeline** – GitLabグループのDuo使用状況データを定期的に収集および集計するCIジョブ。
- **Duo Analytics Dashboard** – Duoの導入、使用強度、エンゲージメントの傾向を示すGitLab Pagesでホストされるダッシュボード。

## はじめに {#getting-started}

これらの**Project CI/CD Variables**を設定して、実行する分析パイプラインを制御できます:

| 変数 | Duoのセットアップ | 説明 |
|----------|-----------|-------------|
| `ENABLE_DUO_METRICS` | `"true"` | Duo AIメトリクスパイプラインを有効または無効にします。 |
| `ENABLE_PROJECT_METRICS` | `"false"` | Duoの導入のみを考慮する場合は、従来のプロジェクト中心のメトリクスを無効にします。 |
| `DUO_TOKEN` | `TOKEN VALUE` | Duoの使用状況収集のための`read_api`および`ai_features`権限を持つパーソナルアクセストークン。 |
| `GROUP_PATH` | `example_group` | Duoメトリクスを収集するためのトップレベルグループまたはサブグループのパス。 |

**Steps for Quick Start**

1. このリポジトリをフォークします。
1. **Project Settings → CI/CD → Variables**の設定 → CI/CD → 変数に移動します。
1. 上記の変数を、ご使用の環境に適した値で追加します。
1. 任意の間隔で**scheduled pipeline**を設定します。Duoの使用状況の収集は負荷が高くなる可能性があるため、**once per day**の実行をお勧めします。
1. スケジュールされたパイプラインを手動で実行するか、スケジュールを待ちます。
1. パイプラインが完了したら、**Deploy → Pages**にある**Pages**アプリケーションを開き、Duo Analyticsダッシュボードにアクセスします。

## GitLab Pagesのデプロイ（Duoメトリクス） {#gitlab-pages-deployment-duo-metrics}

Duoメトリクスが有効になっている場合、Duoパイプラインの完了後にPagesのデプロイが自動的に行われます:

- **Duo Metrics Pipeline** → `https://your-username.gitlab.io/project-name/duo-metrics/`のようなURLにデプロイします。
- **Main Landing Page** → `https://your-username.gitlab.io/project-name/`で使用可能。利用可能なダッシュボードへのリンクがあります。

ランディングページは、どのダッシュボードが存在するかを自動的に検出し、`ENABLE_DUO_METRICS="true"`の場合、Duo関連のリンクを表示します。

## ローカル開発とテスト {#local-development--testing}

Duo分析のローカルテストの場合（CIなし）:

1. Pythonと依存関係がインストールされていることを確認してください（たとえば、リポジトリルートで`poetry install`を使用）。
1. ローカル`.env`またはShellセッションで、必要な環境変数を設定します:
   - `DUO_TOKEN`
   - `GROUP_PATH`
1. 汎用オーケストレータースクリプトを実行して、raw Duoの使用状況データを収集します:

```shell
python ai_raw_data_collection.py
```

1. ローカルの`public/`または`docs/`フォルダー（設定によって異なります）で生成されたメトリクスを開くか、ソリューションコンポーネントプロジェクトのドキュメントに記載されているように、ローカルでダッシュボードを実行します。

## Duoダッシュボードの機能 {#duo-dashboard-features}

Duo Analyticsダッシュボードは、GitLab Duoの導入とAIの使用パターンに焦点を当てています。以下を含みます:

- **License & Adoption Analytics** – Duoアクセスを持つユーザー数と、実際に使用しているユーザー数を追跡します。
- **Code Suggestions Analytics** – AIアシストコーディングの承諾率、提案のボリューム、言語分布を監視します。
- **Duo Chat Analytics** – チャットのやり取り、ユーザーコホート、会話ボリュームを表示します。
- **User Engagement Analytics** – 使用レベル（非アクティブ、実験、通常、ヘビー）でユーザーをセグメント化します。
- **Language & Workflow Performance** – プログラミング言語またはワークフロー別に、Duoの有効性（承諾率、提案の使用状況など）を分析します。

これらのメトリクスは、Duo関連のシグナルからのみ派生しています。このダッシュボードを使用するために、従来のプロジェクトメトリクスは必要ありません。

## Duo使用状況データ収集パイプライン {#duo-usage-data-collection-pipeline}

Duo導入メトリクスは、以下に依存するCI駆動のデータ収集パイプラインによって作成されます:

- **generic Python orchestrator**：`ai_raw_data_collection.py`
- 再利用可能な**GitLab GraphQL API client**：`gitlab_graphql_api`

### オーケストレーター：`ai_raw_data_collection.py` {#orchestrator-ai_raw_data_collectionpy}

スクリプト`ai_raw_data_collection.py`は、次の役割を担います:

- 環境/CI変数（`GROUP_PATH`、`DUO_TOKEN`、パイプライン構成など）の読み取り。
- 具体的なDuo使用状況クエリを実装する1つ以上の**collector scripts**の呼び出し。
- 調整:
  - グループおよびプロジェクト全体のページネーション。
  - Duoの使用状況イベントの日時ウィンドウまたはサンプリング戦略。
  - 一貫性のある分析に適した形式（例：CSV / JSON）への結果の正規化。
- Duoダッシュボードとダウンストリームの集計手順が消費する場所への収集されたデータの書き込み。

これは、raw Duo使用状況データを収集するための**generic entry point**として機能するため、次のことが可能です:

- CI設定を変更せずに、Duo関連の新しいコレクターを追加します。
- 環境変数またはCIジョブを介して、実行するコレクターを制御します。

### GitLab GraphQL APIクライアントとコレクション {#gitlab-graphql-api-client--collections}

Duo関連のすべてのGraphQLロジックは、`gitlab_graphql_api` Pythonパッケージ、特に以下にカプセル化されています:

- `gitlab_graphql_api > collections`

キーとなるアイデア:

- **GraphQL client abstraction** – 中央クライアントは、GitLab GraphQLエンドポイントに対する認証、ページネーション、およびエラー処理を処理します。
- **コレクションクラス** – `collections`モジュールは、構造化されたデータを取得するためのメソッドを公開する、より高レベルの抽象化（「プロジェクトコレクション」や「ユーザーコレクション」など）を提供します。Duoコレクターはこれらを使用して、:
  - 特定の`GROUP_PATH`のグループとプロジェクトをフェッチします。
  - Duoの使用状況フィールドとAI関連のアクティビティーをクエリします。
- **Versioned API usage** – オーケストレーターを変更せずに、GitLabがDuo関連のGraphQLフィールドを改善または拡張するにつれて、同じコレクションAPIを拡張できます。

Duoコレクターはこれらのコレクションクラスをインポートし、必要な特定のクエリを定義します（たとえば、AIコードの提案、チャットの使用状況イベント、またはユーザーレベルの導入統計の数をフェッチするなど）。

> **注:** Duoの使用状況に関するGraphQLのスキーマとフィールド名は、`gitlab_graphql_api > collections`のコレクションクラスとともにドキュメント化されています。Duoメトリクスのために収集されたデータを拡張またはカスタマイズするときは、それらのドキュメントを使用してください。

## Duoデータ収集の設定 {#configuring-duo-data-collection}

パイプラインはカスタマイズできますが、一般的なDuoのみのセットアップには、次のものが必要です:

- **Minimal CI configuration**:
  - `ENABLE_DUO_METRICS="true"`を設定して、Duoパイプラインを有効にします。
  - オプションで、`ENABLE_PROJECT_METRICS="false"`を設定して、Duo以外のパイプラインを無効にします。
- `ai_raw_data_collection.py`で使用される**Environment variables**:

| 変数 | 説明 | 例 |
|----------|-------------|---------|
| `DUO_TOKEN` | `read_api` + `ai_features`を持つトークン。Duo GraphQLクエリに使用されます。 | `glpat-xxxx` |
| `GROUP_PATH` | Duoの使用状況を測定するグループまたはサブグループ。 | `"gitlab-org/your-group"` |
| `DUO_METRICS_OUTPUT_DIR` | raw Duo使用状況データのオプションの出力ディレクトリ。 | `"duo-metrics/raw"` |

これらを設定すると、`ai_raw_data_collection.py`を実行するCIジョブは次のようになります:

1. `gitlab_graphql_api`コレクションを使用して、指定されたグループのDuo使用状況データをクエリします。
1. 書き込むことができるraw Duo使用状況アーティファクト:
   - レポートに集計。
   - Duoダッシュボードによって直接読み込む。

## Duoメトリクスの拡張 {#extending-duo-metrics}

Duo導入メトリクスを追加または改善するには、:

1. 新しいDuoシグナルに関連するGitLab GraphQLフィールド（たとえば、追加の使用状況カウンターまたは新しいAI機能）を**Identify**します。
1. 次のコレクタースクリプトを**Update or add**します:
   - `gitlab_graphql_api > collections`の抽象化を使用します。
   - 既存のDuoコレクターと一貫性のある形式でデータを書き込みます。
1. **Wire the collector**して`ai_raw_data_collection.py`に接続します（または、環境変数を介して制御します）。
1. 必要に応じて、新しいフィールドを使用および視覚化するように**Update the dashboard**します。

GraphQLアクセスとページネーションロジックが`gitlab_graphql_api`内にカプセル化されているため、Duoメトリクスを拡張するということは、通常、:

- オーケストレーターの変更は最小限です。
- 新しいメトリクスのモデリングとダッシュボードの更新に焦点を当てます。

## リソース {#resources}

- [GitLab Duo導入メトリクスソリューションコンポーネントプロジェクト](https://gitlab.com/gitlab-com/product-accelerator/work-streams/packaging/gitlab-graphql-api)
- `gitlab_graphql_api`パッケージと`collections`モジュール（Duo GraphQLの使用パターン用）
