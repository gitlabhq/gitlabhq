---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AIゲートウェイ
---

AIゲートウェイは、AIネイティブなGitLab Duo機能へのアクセスを提供するスタンドアロンサービスです。

GitLabは、クラウドベースのAIゲートウェイのインスタンスを運用しています。このインスタンスは、GitLab.com、[GitLab Self-Managed](configure/gitlab_self_managed.md)、GitLab Dedicatedで使用されます。

セルフマネージドGitLabでは、[GitLab Duo Self-Hosted](../gitlab_duo_self_hosted/_index.md)を通じてセルフホスト型のAIゲートウェイインスタンスも使用できます。

## リージョンサポート {#region-support}

### GitLab.com {#gitlabcom}

GitLab.comの場合、ルーティングメカニズムは、ユーザーのインスタンスの場所ではなく、GitLabインスタンスの場所に基づいています。

GitLab.comが`us-east1`でシングルホームであるため、ほとんどの場合、AIゲートウェイへのリクエストは`us-east4`にルーティングされます。そのため、すべてのユーザーが常に最も近いデプロイ先に接続されるとは限りません。

### GitLab Self-ManagedおよびGitLab Dedicatedの場合 {#gitlab-self-managed-and-gitlab-dedicated}

GitLab Self-ManagedおよびGitLab Dedicatedの場合、GitLabがリージョンの選択を管理します。AIゲートウェイのデプロイリージョンを選択することはできません。詳細については、[Runway](https://gitlab.com/gitlab-com/gl-infra/platform/runway)サービスマニフェストの[利用可能なリージョン](https://schemas.runway.gitlab.com/RunwayService/#spec_regions)を参照してください。

RunwayはGitLabの社内デベロッパープラットフォームであり、外部のお客様は利用できません。

## データの自動ルーティング {#automatic-data-routing}

GitLabは、CloudflareとGoogle Cloud Platform（GCP）ロードバランサーを使用して、AIゲートウェイリクエストを最も近い利用可能なデプロイに自動的にルーティングします。このルーティングメカニズムは、低レイテンシーとユーザーリクエストの効率的な処理を優先します。

このルーティングプロセスを手動で制御することはできません。次の要因は、データルーティング先に影響を与えます: 

- ネットワークレイテンシー: 主要なルーティングメカニズムは、レイテンシーを最小限に抑えることに重点を置いています。ネットワークの状態によっては、データが最も近いリージョン以外のリージョンで処理される場合があります。
- サービスの可用性: リージョンの停止またはサービスの中断が発生した場合、サービスを中断しないために、リクエストが自動的に再ルーティングされる場合があります。
- サードパーティの依存関係: GitLabのAIインフラストラクチャは、Google Vertex AIなどのサードパーティモデルプロバイダーに依存しており、これらは独自のデータ処理方法を採用しています。

### ダイレクト接続とインダイレクト接続 {#direct-and-indirect-connections}

IDEはデフォルトでAIゲートウェイと直接通信し、GitLabモノリスをバイパスしています。このダイレクト接続により、ルーティング効率が向上します。

コード提案向けに[直接接続と間接接続](../../user/project/repository/code_suggestions/_index.md#direct-and-indirect-connections)を設定することで、この動作を変更できます。

### 特定のリージョンへのリクエストをトレースする {#tracing-requests-to-specific-regions}

特定のリージョンへのAIリクエストを直接トレースすることはできません。

特定のリクエストのトレーシングについてサポートが必要な場合、GitLabサポートがCloudflareヘッダーとインスタンスのUUIDを含むログにアクセスして分析できます。これらのログは、ルーティングパスに関するインサイトを提供し、リクエストが処理されたリージョンを特定するのに役立ちます。

## データ主権 {#data-sovereignty}

マルチリージョンのAIゲートウェイデプロイは、厳格なデータ主権を強制しません。リクエストが特定のリージョンに移動または留まることは保証されていません。

このサービスは、データレジデンシーソリューションではありません。

### デプロイリージョン {#deployment-regions}

GitLabは、次のリージョンにAIゲートウェイをデプロイしています:

- 北米（`us-east4`）
- ヨーロッパ（`europe-west2`、`europe-west3`、および`europe-west9`）
- アジア太平洋（`asia-northeast1`および`asia-northeast3`）

最新の情報については、[Runway設定ファイル](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/.runway/runway.yml?ref_type=heads#L12)を参照してください。

AIゲートウェイで使用される大規模言語モデルの正確な場所は、サードパーティのモデルプロバイダーによって決定されます。モデルは、AIゲートウェイのデプロイと同じ地理的リージョンに存在することは保証されていません。AIゲートウェイが最初のリクエストを別のリージョンで処理する場合でも、モデルプロバイダーが運用する他のリージョンにデータが流れる可能性があります。データは、パフォーマンスと可用性に基づいて、最適なリージョンにルーティングされます。
