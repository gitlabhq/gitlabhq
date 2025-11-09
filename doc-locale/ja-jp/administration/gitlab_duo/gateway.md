---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AIゲートウェイ
---

AIゲートウェイは、AIネイティブのGitLab Duo機能へのアクセスを提供するスタンドアロンサービスです。

GitLabは、クラウドを拠点とするAIゲートウェイのインスタンスを運用しています。このインスタンスは、以下で使用されます:

- GitLab.com
- GitLab Self-Managed。詳細については、[Self-ManagedインスタンスでGitLab Duoを設定する](setup.md)方法を参照してください。
- GitLab Dedicated

自己ホスト型のAIゲートウェイインスタンスもあります。[GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/_index.md)を使用して、GitLab Self-Managedインスタンスでこのインスタンスを使用できます。

このページでは、AIゲートウェイがどこにデプロイされているかについて説明し、リージョンの選択、データルーティング、データのデータレジデンシーに関する質問に答えます。

## リージョンのサポート {#region-support}

### GitLab Self-ManagedとGitLab Dedicatedのお客様の場合 {#gitlab-self-managed-and-gitlab-dedicated}

GitLab Self-ManagedおよびGitLab Dedicatedのお客様の場合、リージョンの選択はGitLabによって内部で管理されます。

[Runway](https://gitlab.com/gitlab-com/gl-infra/platform/runway)サービスマニフェストで、[利用可能なリージョンを表示](https://gitlab-com.gitlab.io/gl-infra/platform/runway/runwayctl/manifest.schema.html#spec_regions)します。

Runwayは、GitLabの内部デベロッパープラットフォームです。外部のお客様は利用できません。GitLab Self-Managedインスタンスの改善のサポートは、[エピック1330](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1330)で提案されています。

### GitLab.com {#gitlabcom}

GitLab.comのお客様の場合、ルーティングメカニズムは、ユーザーのインスタンスの場所ではなく、GitLabのインスタンスの場所に基づいています。

GitLab.comは`us-east1`にシングルホームであるため、AIゲートウェイへのリクエストは、ほとんどの場合`us-east4`にルーティングされます。これは、ルーティングがすべてのユーザーにとって、常に絶対に最も近いデプロイになるわけではない可能性があることを意味します。

### ダイレクト接続とインダイレクト接続 {#direct-and-indirect-connections}

IDEは、デフォルトでAIゲートウェイと直接通信し、GitLabモノリスを回避します。この直接接続により、ルーティングの効率性が向上します。これを変更するには、[直接接続と間接接続を構成](../../user/project/repository/code_suggestions/_index.md#direct-and-indirect-connections)できます。

### 自動ルーティング {#automatic-routing}

GitLabは、CloudflareとGoogle Cloud Platform（GCP）ロードバランサーを活用して、AIゲートウェイリクエストを最寄りの利用可能なデプロイに自動的にルーティングします。このルーティングメカニズムは、低レイテンシーとユーザーリクエストの効率性の高い処理を優先します。

このルーティング処理を手動で制御することはできません。システムは、ネットワークの状態やサーバーの負荷などの要因に基づいて、最適なリージョンを動的に選択します。

### 特定のリージョンへのトレーシングリクエスト {#tracing-requests-to-specific-regions}

現時点では、特定のリージョンへのAIリクエストを直接トレーシングすることはできません。

特定のリクエストのトレーシングに関する支援が必要な場合は、GitLabサポートがCloudflareヘッダーとインスタンスUUIDを含むログにアクセスして分析できます。これらのログは、ルーティングパスに関するインサイトを提供し、リクエストが処理されたリージョンを特定するのに役立ちます。

## データのデータソブリンティ {#data-sovereignty}

マルチリージョンのAIゲートウェイデプロイにおける厳格なデータのデータソブリンティの実施に関する現在の制限事項を認識することが重要です。現在、リクエストが特定のリージョンに移動またはそのリージョン内にとどまることを保証することはできません。したがって、これはデータレジデンシーソリューションではありません。

### データのルーティングに影響を与える要因 {#factors-that-influence-data-routing}

次の要因は、データのルーティング先に影響を与えます。

- **ネットワークレイテンシー**: 主要なルーティングメカニズムはレイテンシーを最小限に抑えることに重点を置いており、ネットワークの状態によって、最も近いリージョン以外のリージョンでデータが処理される可能性があることを意味します。
- **サービスの可用性**: 地域での停止またはサービスの中断が発生した場合、中断のないサービスを確保するために、リクエストが自動的に再ルーティングされる場合があります。
- **サードパーティの依存関係**: GitLab AIインフラストラクチャは、Google Vertex AIなどのサードパーティのモデルプロバイダーに依存しており、独自のデータ処理方法を持っています。

### AIゲートウェイデプロイリージョン {#ai-gateway-deployment-regions}

AIゲートウェイデプロイリージョンに関する最新情報については、[AIアシストRunway設定ファイル](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/.runway/runway.yml?ref_type=heads#L12)を参照してください。

最終更新日（2023-11-21）の時点で、GitLabはAIゲートウェイを次のリージョンにデプロイしています:

- 北米（`us-east4`）
- ヨーロッパ（`europe-west2`、`europe-west3`、`europe-west9`）
- アジア太平洋（`asia-northeast1`、`asia-northeast3`）

デプロイリージョンは頻繁に変更される可能性があります。最新情報については、常に上記でリンクされている設定ファイルを確認してください。

AIゲートウェイで使用されるLLMモデルの正確な場所は、サードパーティのモデルプロバイダーによって決定されます。モデルがAIゲートウェイのデプロイと同じ地理的リージョンに存在するという保証はありません。これは、AIゲートウェイが別のリージョンで最初のリクエストを処理する場合でも、モデルプロバイダーが運営している米国または他のリージョンにデータが送信される可能性があることを意味します。

### データフローとLLMモデルの場所 {#data-flow-and-llm-model-locations}

GitLabは、地域のデータ処理方法を完全に理解するために、LLMプロバイダーと緊密に連携しています。前のセクションで説明した要因により、ユーザーに最も近いリージョン以外のリージョンにデータが送信されるインスタンスが発生する可能性があります。

### 今後の機能拡張 {#future-enhancements}

GitLabは、お客様が将来、データのデータレジデンシー要件をより詳細に指定できるように積極的に取り組んでいます。提案されている機能により、データ処理場所をより詳細に制御できるようになり、特定のコンプライアンスのニーズを満たすのに役立ちます。

## 特定の地域に関する質問 {#specific-regional-questions}

### ブレグジット後のデータルーティング {#data-routing-post-brexit}

英国のEU離脱は、AIゲートウェイのデータルーティングの優先順位または決定に直接影響を与えません。データは、パフォーマンスと可用性に基づいて、最も最適なリージョンにルーティングされます。データは引き続きEUと英国の間を自由に流れることができます。
