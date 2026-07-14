---
stage: Release Notes
group: Monthly Release
date: 2026-04-16
title: "GitLab 18.11 リリースノート"
description: "GitLab 18.11 がリリースされました。GitLab Duo Agent Platform での脆弱性解決が一般提供開始"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2026年4月16日、GitLab 18.11 が以下の機能とともにリリースされました。

また、今月の注目コントリビューターをはじめ、すべてのコントリビューターの皆様に感謝申し上げます。

## 今月の注目コントリビューター: Rinku C

[Rinku C](https://gitlab.com/therealrinku) さんを表彰できることを嬉しく思います。Rinku さんは 2025年9月に参加して以来、GitLab 全体で 80 件以上の改善をマージしたレベル 4 のコントリビューターです。

Developer Relations チームのシニアフルスタックエンジニアである [Arianna Haradon](https://gitlab.com/aharadon) さんから推薦されたこの賞は、長期にわたる継続的かつ意義深い貢献を称えるものです。Rinku さんは、[プロジェクトおよびグループアクセストークン作成フォームへのスコープ必須化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219236)によってセキュリティに関わるフローを強化し、[ジョブログの次/前ナビゲーション](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217618)、[最近の検索から空の検索を除外](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223570)、[ファイルツリーの整理](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224628)など、日常的な GitLab 体験を向上させる多数の UI 改善を通じて、一般的なワークフローをより明確で使いやすくしました。Rinku さんは誰も手をつけていない作業に取り組み、コードベースの健全性を保ちながら、意義ある永続的な価値を積み重ねています。ご貢献に感謝します！

## 主要機能

### GitLab Duo Agent Platform での脆弱性解決が一般提供開始

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/agentic_vulnerability_resolution.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/585626)

{{< /details >}}

エージェント型 SAST 脆弱性解決が、GitLab Duo Agent Platform 上の GitLab 18.11 で一般提供開始となりました。この機能は SAST スキャンの一部として実行され、SAST 誤検出判定の後、または個々の SAST 脆弱性に対して手動でトリガーした場合に動作します。

エージェント型 SAST 脆弱性解決の機能:

- 検出結果を自律的に分析し、周辺のコードコンテキストを通じて推論します。
- 重大度が「クリティカル」および「高」の SAST 脆弱性に対して、提案されたコード修正を含むレビュー可能なマージリクエストを自動的に作成します。
- レビュアーが提案された修正に対する信頼度を素早く判断できるよう、品質評価を提供します。
- 脆弱性詳細ページから直接解決策を適用できます。

[イシュー 585626](https://gitlab.com/gitlab-org/gitlab/-/issues/585626) でフィードバックをお待ちしています。

### GitLab Data Analyst Foundational Agent が一般提供開始

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20337)

{{< /details >}}

Data Analyst Agent は、GitLab プラットフォーム全体でデータのクエリ、可視化、および表示を支援する特化型 AI チャットアシスタントです。

[GitLab Query Language (GLQL)](../../user/glql/_index.md) を基盤として、Data Analyst はサポートされている各[データソース](../../user/glql/data_sources/_index.md)のデータを取得・分析し、ソフトウェア開発の健全性とエンジニアリング効率に関する明確で実用的なインサイトを提供します。

これらのインサイトはエージェントの出力に直接可視化でき、さらなる評価のためにイシューやエピックに直接埋め込むこともできます。

### CI Expert Agent がベータ版として提供開始

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/ci_expert_agent.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/587460)

{{< /details >}}

AI を活用した CI Expert Agent がベータ版として利用可能になりました。このエージェントは、空の `.gitlab-ci.yml` から始めることなく、GitLab のコードから最初に動作するパイプラインへと移行するチームを支援します。

GitLab Duo Agent Platform を使用して、エージェントはリポジトリを検査し、ビルドおよびテストプロセスについていくつかのガイド付き質問を行い、レビュー、編集、コミットが可能な実行準備済みのパイプラインを生成します。

これにより、パイプラインの作成が会話形式でコンテキスト認識型の体験となり、設定を発展・最適化する準備ができた後は YAML を完全にコントロールできます。

### 脆弱性の重大度の自動オーバーライド

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/vulnerability_management_policy.md#severity-override-policies) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15839)

{{< /details >}}

デフォルトの脆弱性の重大度は、組織の実際のリスクを必ずしも反映しているわけではありません。内部専用サービスにおけるクリティカルな CVE は、公開向けアプリケーションのものと同じ緊急性を必要としない場合がありますが、チームはリスクモデルに合わない検出結果のトリアージに多大な時間を費やしています。

脆弱性管理ポリシーで、CVE ID、CWE ID、ファイルパス、ディレクトリなどの条件に基づいて脆弱性の重大度を自動的に調整できるようになりました。適用されると、ポリシーはデフォルトブランチ上の条件に一致する脆弱性の重大度を更新します。手動オーバーライドは引き続き優先され、すべての変更は脆弱性の履歴と監査イベントに記録されます。

これによりトリアージ作業が軽減され、開発者がビジネスにとって最も重要な検出結果に集中できるようになります。

### サブグループおよびプロジェクトでのサービスアカウント作成

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/profile/service_accounts.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{< /details >}}

チームはサブグループおよびプロジェクトでサービスアカウントを作成できるようになりました。広範なトップレベルグループのボットの代わりに、単一のサブグループまたはプロジェクトに専用のサービスアカウントを紐付け、そのネームスペースの他のメンバーと同様にアクセスを管理できます。グループおよびサブグループのサービスアカウントは、作成されたグループまたは任意の子孫サブグループおよびプロジェクトに招待できます。プロジェクトのサービスアカウントは自身のプロジェクトのみに限定されます。

### GitLab Free でサービスアカウントが利用可能に

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/profile/service_accounts.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20439)

{{< /details >}}

サービスアカウントがすべてのプランで GitLab.com にて利用可能になりました。以前は Premium および Ultimate に限定されていましたが、サービスアカウントを使用することで、認証情報を個々のチームメンバーに紐付けることなく、自動化されたアクションの実行、データへのアクセス、またはスケジュールされたプロセスの実行が可能になります。チームの変更に関わらず認証情報を安定させる必要があるパイプラインやサードパーティインテグレーションで一般的に使用されます。GitLab Free では、サブグループやプロジェクトで作成されたものを含め、トップレベルグループごとに最大 100 件のサービスアカウントを作成できます。

### パーソナルアクセストークンのきめ細かい権限が利用可能に（ベータ版）

<!-- categories: Permissions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../auth/tokens/fine_grained_access_tokens.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/18555)

{{< /details >}}

きめ細かいパーソナルアクセストークン（PAT）がベータ版として利用可能になりました。所属するすべてのプロジェクトとグループへのアクセスを付与する従来の PAT とは異なり、きめ細かい PAT では各トークンを特定のリソースとアクションに限定できます。これにより、漏洩または不正なトークンによる潜在的な影響を軽減できます。

既存の PAT は引き続き従来通り機能し、きめ細かい権限なしで従来の PAT を作成することもできます。

このベータ版リリースは GitLab REST API の約 75% をカバーしています。完全な REST API カバレッジ、GraphQL の適用、および管理者ポリシーコントロールは GA リリースで予定されています。

フィードバックを共有するには、[エピック 18555](https://gitlab.com/groups/gitlab-org/-/epics/18555) をご覧ください。

### セキュリティダッシュボードのトップ CWE チャート

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md#top-10-cwes) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17422)

{{< /details >}}

新しいセキュリティダッシュボードでトップ CWE チャートが利用可能になりました。プロジェクトまたはインスタンス全体で最も一般的な CWE を特定し、トレーニング、改善、またはプログラム最適化の機会を見つけることができます。ユーザーはダッシュボードデータを重大度でグループ化し、重大度、プロジェクト、レポートタイプでフィルタリングできます。

### Kubernetes への Gitaly のデプロイ

<!-- categories: Gitaly -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../administration/gitaly/kubernetes.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/work_items/6127)

{{< /details >}}

Gitaly を Kubernetes に完全サポートされたデプロイ方法としてデプロイできるようになりました。これにより、スケーリング、高可用性、リソース管理のための Kubernetes オーケストレーション機能を使用して、GitLab インフラストラクチャの管理における柔軟性が向上します。以前は、Kubernetes へのデプロイにはカスタム設定が必要で公式にサポートされていなかったため、コンテナ化された環境で信頼性の高い Gitaly デプロイを維持することが困難でした。

### MR パイプラインを手動実行する際の入力の再設定

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../ci/pipelines/merge_request_pipelines.md#run-a-merge-request-pipeline-with-custom-inputs) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/547861)

{{< /details >}}

CI/CD 入力の強力な側面の一つは、ランタイムのカスタマイズのために新しい値で新しいパイプラインを手動実行できることです。
以前はマージリクエスト（MR）パイプラインでは利用できませんでしたが、このリリースで MR パイプラインでも入力をカスタマイズできるようになりました。

MR パイプラインの入力を設定した後、マージリクエストの新しいパイプラインを実行するたびに、それらの入力を任意で変更してパイプラインの動作を変えることができます。

## エージェントコア

### GitLab Duo Agentic Chat のデフォルトモデルが Haiku 4.5 から Sonnet 4.6 に更新

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/model_selection.md#default-models) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/595042)

{{< /details >}}

GitLab での Agentic Chat 体験を向上させるための更新を行いました。Agentic Chat のデフォルトモデルが、Vertex AI でホストされている Claude Haiku 4.5 から Claude Sonnet 4.6 にアップグレードされました。Claude Sonnet 4.6 は推論と応答品質が向上していますが、Haiku 4.5 よりも高い GitLab クレジット乗算を使用します。

[モデル選択](../../user/duo_agent_platform/model_selection.md#select-a-model-for-a-feature)設定を使用して、Haiku を含む代替モデルを選択できます。既に特定のモデルを選択している場合、その選択は保持されます。この更新はデフォルトにのみ影響し、既存の選択をオーバーライドすることはありません。モデル別のクレジット乗算については、[GitLab クレジットのドキュメント](../../subscriptions/gitlab_credits.md)をご覧ください。

### カスタムフロー定義でのツールの設定

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/flows/custom.md#create-a-flow) | [関連イシュー](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/work_items/2147)

{{< /details >}}

カスタムフロー定義でツールオプションとパラメータ値を直接設定して、LLM のデフォルト値を上書きできるようになりました。これにより、カスタムフロー内でのツールの動作をより正確かつ一貫してコントロールでき、そのフロー全体でガードレールと特定のパラメータ値を適用しやすくなります。

### GitLab Duo Agent Platform でセルフホストモデルとして Mistral AI がサポートされるように

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms.md#cloud-hosted-model-deployments) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/587872)

{{< /details >}}

GitLab Duo Agent Platform がセルフホストモデルのデプロイ向け LLM プラットフォームとして Mistral AI をサポートするようになりました。GitLab Self-Managed のお客様は、AWS Bedrock、Google Vertex AI、Azure OpenAI、Anthropic、OpenAI などの既存のサポート済みプラットフォームと並行して Mistral AI を設定できます。これにより、AI を活用した機能の実行方法についてチームの選択肢が広がります。

## スケールとデプロイ

### GitLab クレジットダッシュボードでの過去の月の表示

<!-- categories: Consumables Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#view-the-gitlab-credits-dashboard) | [関連イシュー](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15910)

{{< /details >}}

カスタマーポータルの GitLab クレジットダッシュボードで過去の月のナビゲーションがサポートされるようになりました。請求管理者は過去の請求月を参照して、日次使用傾向の確認、期間をまたいだ消費パターンの比較、および請求書との使用量の照合ができます。以前はダッシュボードに現在の請求月のみが表示されていました。この改善により、管理者はクレジット配分についてより情報に基づいた意思決定を行い、過去のデータに基づいて将来のニーズを予測できます。

### GitLab クレジットのサブスクリプションレベルの使用上限の設定

<!-- categories: Consumables Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#usage-control-status)

{{< /details >}}

管理者はサブスクリプションレベルでオンデマンドクレジットの月次使用上限を設定できるようになりました。オンデマンドクレジットの総消費量が設定された上限に達すると、次の請求期間が始まるか管理者が上限を調整するまで、そのサブスクリプションのすべてのユーザーに対して GitLab Duo Agent Platform へのアクセスが自動的に停止されます。この設定により、組織は予期しない超過請求に対するハードなガードレールを設けることができ、Agent Platform の広範な展開における主要な障壁を取り除きます。上限は各請求期間に自動的にリセットされ、上限に達すると管理者にメール通知が送信されます。

### ユーザーごとの GitLab クレジット上限の設定

<!-- categories: Consumables Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#usage-control-status)

{{< /details >}}

管理者は請求期間ごとに GitLab クレジットのオプションのユーザーごとの使用上限を設定できるようになりました。個々のユーザーのクレジット総消費量が設定された上限に達すると、そのユーザーのみ GitLab Duo Agent Platform へのアクセスが停止され、他のユーザーは影響を受けません。これにより、単一のユーザーが組織のクレジットプールの不均衡な割合を消費することを防ぎ、管理者が使用量の分配をきめ細かくコントロールできます。ユーザーごとの使用上限はサブスクリプションレベルの使用上限と連携して機能し、先に達した上限が適用されます。

### Linux パッケージの改善

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server) | [関連イシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9734)

{{< /details >}}

GitLab 19.0 では、PostgreSQL の最小サポートバージョンがバージョン 17 になります。この変更に備えて、[PostgreSQL クラスター](../../administration/postgresql/replication_and_failover.md)を使用していないインスタンスでは、GitLab 18.11 へのアップグレード時に PostgreSQL をバージョン 17 に自動アップグレードしようとします。

[PostgreSQL クラスター](../../administration/postgresql/replication_and_failover.md)を使用している場合、または[この自動アップグレードをオプトアウト](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades)した場合は、GitLab 19.0 にアップグレードするために[PostgreSQL 17 に手動でアップグレード](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server)する必要があります。

### コンテナレジストリメタデータデータベースのバックアップと復元のサポート

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/backup_restore/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-com/gl-infra/data-access/durability/-/work_items/45)

{{< /details >}}

Linux パッケージインストール向けの GitLab `backup` Rake タスクと、Cloud Native（Helm）インストール向けの `[backup-utility](https://docs.gitlab.com/charts/backup-restore/)` が[コンテナレジストリメタデータデータベース](../../administration/packages/container_registry_metadata_database.md)をサポートするようになりました。
メタデータデータベースに保存されている blob、マニフェスト、タグ、その他のデータへの参照をバックアップできるようになり、悪意のあるまたは偶発的なデータ破損が発生した場合の復元が可能になります。

### Explore でのグループの新しいナビゲーション体験

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/group/_index.md#explore-groups) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/13791)

{{< /details >}}

**Explore** のグループリストの改善をお知らせします。GitLab インスタンス全体でグループを見つけやすくなりました。
再設計されたインターフェースでは、2 つのビューを持つタブ付きレイアウトが導入されています:

- **アクティブ**タブ: アクセス可能なすべてのグループを参照し、関連するコミュニティやプロジェクトを見つけるのに役立ちます。
- **非アクティブ**タブ: アーカイブされたグループと削除保留中のグループを表示し、グループのライフサイクル状態を把握できます。

これらの変更によりグループの検索が効率化され、参加可能なグループをより明確に把握できるようになります。

### プロジェクトの非同期転送

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/group/manage.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20521)

{{< /details >}}

以前のバージョンの GitLab では、大規模なグループやプロジェクトの転送がタイムアウトすることがありました。転送、アーカイブ、削除などの操作に統一された状態モデルを使用するようグループとプロジェクトを移行するにあたり、より一貫した動作、状態履歴と監査詳細のより良い可視性、そして特に非同期処理による長時間実行の転送操作でのタイムアウトの減少が実現します。

## 統合された DevOps とセキュリティ

### Self-Managed デプロイ向け ClickHouse が一般提供開始

<!-- categories: DevOps Reports -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../integration/clickhouse.md#set-up-clickhouse) | [関連イシュー](https://gitlab.com/groups/gitlab-org/architecture/gitlab-data-analytics/-/work_items/51)

{{< /details >}}

GitLab Self-Managed インスタンス向けに、GitLab [ClickHouse インテグレーション](../../integration/clickhouse.md)の推奨事項と設定ガイダンスが改善されました。お客様は独自のクラスターを持ち込むか、ClickHouse Cloud（推奨）のセットアップオプションを使用するかを選択できます。このインテグレーションは複数のダッシュボードを動かし、アナリティクス領域内のさまざまな API エンドポイントへのアクセスを解放します。

このスケーラブルで高性能なデータベースは、GitLab アナリティクスインフラストラクチャに計画されているより大きなアーキテクチャ改善の一部です。

### Duo および SDLC トレンドダッシュボードでの GitLab Duo Agent Platform アナリティクスの強化

<!-- categories: DevOps Reports -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/analytics/duo_and_sdlc_trends.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20540)

{{< /details >}}

GitLab Duo および SDLC トレンドダッシュボードは、ソフトウエアデリバリーへの GitLab Duo の影響を測定するためのアナリティクス機能が強化されました。ダッシュボードには、月次 Agent Platform ユニークユーザーと Agentic Chat セッションの新しいシングルスタットパネルが追加されました。
また、シート割り当てに対する使用率（%）として表示されていたメトリクスが、使用数のみを報告するように更新されました。
この変更により、新しい使用量課金モデルで管理される Agent Platform の使用量がカウントに含まれていなかった[イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/590326)が解決されます。

### GLQL でプロジェクト、パイプライン、ジョブのデータソースにアクセス可能に

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/glql/data_sources/_index.md)

{{< /details >}}

[GitLab Query Language (GLQL)](../../user/glql/_index.md) で、プロジェクト、パイプライン、ジョブの 3 つの新しいデータソースにアクセスできるようになりました。
これらの新しいデータソースは埋め込みビューとしても利用可能で、チームはパイプライン結果、ジョブステータス、プロジェクト概要を Wiki、イシューおよびマージリクエストの説明、リポジトリの Markdown ファイルに直接表示できます。
GLQL は [Data Analyst Agent](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md) も動かしています。

これらの新しいタイプにより、エージェントは CI/CD ジョブ結果の検査、失敗のデバッグ、パイプライン実行の詳細な概要の提供、およびネームスペース内のプロジェクトの正確な概要の提供が可能になります。

### Maven および Python SBOM スキャンの依存関係解決

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#dependency-resolution) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20461)

{{< /details >}}

SBOM を使用した GitLab 依存関係スキャンで、Maven および Python プロジェクトの依存関係グラフの自動生成がサポートされるようになりました。
以前は、依存関係スキャンで正確な依存関係分析を行うには、ユーザーがロックファイルまたはグラフファイルを提供する必要がありました。
ロックファイルまたはグラフファイルが利用できない場合、アナライザーが自動的に生成を試みるようになりました。
この改善により、Maven および Python プロジェクトでロックファイルなしで依存関係スキャンを有効にしやすくなります。

### 高度な SAST のインクリメンタルスキャン

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md#incremental-scanning) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20508)

{{< /details >}}

GitLab Advanced SAST でコードベースの変更された部分のみを分析するインクリメンタルスキャンを実行できるようになり、フルリポジトリスキャンと比較してスキャン時間が大幅に短縮されます。この機能はコードベースの完全な結果を生成するため、差分ベーススキャンのさらなる反復です。

コードベース全体ではなく変更されたコードのみをスキャンすることで、チームはスピードを犠牲にしたり摩擦を加えたりすることなく、開発ワークフローにセキュリティテストをよりシームレスに統合できます。

### 未検証の脆弱性（ベータ版）

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md#report-unverified-vulnerabilities) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/15649)

{{< /details >}}

高度な SAST で、未検証の脆弱性（ソースからシンクまで完全にトレースできない検出結果）を脆弱性レポートに直接表示できるようになりました。誤検出よりも見逃しに対する許容度が高い場合は、この機能を有効にしてください。

この機能はベータ版です。[イシュー 596512](https://gitlab.com/gitlab-org/gitlab/-/work_items/596512) でフィードバックをお寄せください。

### Kubernetes 1.35 のサポート

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/584225)

{{< /details >}}

GitLab で Kubernetes バージョン 1.35 が完全にサポートされるようになりました。アプリケーションを Kubernetes にデプロイしてすべての機能にアクセスするには、接続されているクラスターを最新バージョンにアップグレードしてください。
詳細については、[GitLab 機能でサポートされている Kubernetes バージョン](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)をご覧ください。

### コンテナレジストリメタデータデータベースの prefer モード

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/packages/container_registry_metadata_database.md#prefer-mode) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/595480)

{{< /details >}}

コンテナレジストリメタデータデータベースを `prefer` モードに設定できるようになりました。これは既存の `true` および `false` 値に加わる新しい設定オプションです。prefer モードでは、レジストリはインストールの現在の状態に基づいて、メタデータデータベースを使用するかレガシーストレージにフォールバックするかを自動的に検出します。

レジストリにデータベースにインポートされていない既存のファイルシステムメタデータがある場合、メタデータのインポートが完了するまでレジストリはレガシーストレージを使用し続けます。データベースがすでに使用中の場合、または新規インストールの場合は、レジストリはデータベースを直接使用します。

今後のリリースで、`prefer` モードが新しい Linux パッケージインストールのデフォルトになります。既存のインストールには影響しません。詳細については、[イシュー 595480](https://gitlab.com/gitlab-org/gitlab/-/work_items/595480) をご覧ください。

### パッケージ保護ルールで Terraform モジュールがサポートされるように

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/packages/package_registry/package_protection_rules.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/592761)

{{< /details >}}

組み込みの GitLab Terraform モジュールレジストリを通じて Terraform モジュールを公開しているチームには、新しいモジュールバージョンをプッシュできるユーザーを制限する方法がありませんでした。パッケージ保護ルールはいくつかのパッケージ形式をサポートしていましたが、`terraform_module` は含まれておらず、インフラチームにはプロジェクトレベルのプッシュコントロールがありませんでした。

最小ロールに基づいてプッシュアクセスを制限する `terraform_module` にスコープされたパッケージ保護ルールを作成できるようになりました。UI のパッケージタイプドロップダウン、REST API、GraphQL API、および GitLab Terraform プロバイダーリソースでサポートされています。

### リリースエビデンスにパッケージが含まれるように

<!-- categories: Package Registry, Release Evidence -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/project/releases/release_evidence.md#include-packages-as-release-evidence) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/283995)

{{< /details >}}

GitLab リリースを作成する際、パッケージレジストリに公開されたパッケージは自動的に関連付けられていませんでした。チームは手動でパッケージ URL を構築し、API またはパイプラインスクリプトを通じてリリースリンクとして添付する必要があり、摩擦が生じ不完全なリリース記録のリスクがありました。

パッケージバージョンがリリースタグと一致する場合、GitLab はリリースエビデンスにパッケージを自動的に含めるようになりました。これにより、手動の手順なしにリリースと関連パッケージの間に検証可能で監査可能なリンクが作成され、ソースコード、アーティファクト、パッケージが 1 つの完全なリリーススナップショットにまとめられます。

### Wiki サイドバートグルがアクセスしやすい位置に移動

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/project/wiki/_index.md#sidebar) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/580569)

{{< /details >}}

Wiki サイドバートグルが左側、制御するサイドバーのすぐ隣に配置されるようになりました。

サイドバーが折りたたまれている場合、トグルはフローティングコントロールとして表示されたままになるため、ページの先頭までスクロールしなくても再度開くことができます。

### Wiki ページのスティッキーアクションバー

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/project/wiki/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/590255)

{{< /details >}}

Wiki ページのアクションバーがスティッキーになり、ページをスクロールしても表示され続けるようになりました。以前は、編集、ページ履歴の表示、テンプレートの管理などのアクションにアクセスするためにページの先頭までスクロールする必要がありました。ページタイトルと主要なアクション（編集、新規ページ、テンプレート、ページ履歴など）が、ページのどこまでスクロールしても手の届く範囲に表示されます。

### エピックのウェイト

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/work_items/weight.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/12273)

{{< /details >}}

エピックでウェイトがサポートされるようになり、計画時に大規模なイニシアチブの見積もりと優先順位付けが容易になりました。

エピックを子イシューに分解する前に、初期見積もりを表す予備ウェイトを割り当てることができます。
エピックを分解するにつれて、ウェイトはすべての子イシューからのロールアップ合計を反映するように自動的に更新されます。
これはイシューとタスクのウェイトロールアップの動作と一致しています。

エピック詳細ページでは、予備ウェイトと子イシューからのロールアップウェイトの両方を確認でき、時間をかけて見積もりを精緻化するために必要なインサイトが得られます。

### 高い悪用可能性リスクを持つマージリクエストのブロック

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#vulnerability_attributes-object) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16311)

{{< /details >}}

以前は、マージリクエスト（MR）承認ポリシーで脆弱性の重大度に基づいて MR をブロックできましたが、すべての脆弱性が同じリスクを持つわけではありません。CVSS の重大度だけでは、CVE が悪用されているかどうか、または悪用される可能性がどの程度かはわかりません。これにより、ノイズの多い承認ポリシーが生まれ、開発者とセキュリティチームの時間が無駄になっていました。

Known Exploited Vulnerability（KEV）および Exploit Prediction Scoring System（EPSS）データを使用して MR 承認ポリシーを設定できるようになりました。検出結果が KEV カタログに含まれている（実際に悪用されている）場合、または EPSS スコアが閾値を超えている場合にブロックまたは承認を要求できます。MR のポリシー違反には KEV と EPSS のコンテキストが含まれるため、開発者はセキュリティゲートがトリガーされた理由を理解できます。

これにより、セキュリティチームはどの検出結果がブロックまたは警告するかを正確にコントロールでき、アラート疲れを軽減し、現在の脅威状況に合わせた適用を維持できます。

### 脆弱性への CVSS 4.0 スコアの割り当て

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/severities.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18697)

{{< /details >}}

CVSS 4.0 は、脆弱性の重大度を評価・評定するために使用される業界標準の最新バージョンです。脆弱性詳細ページや脆弱性レポートを含む UI で CVSS 4.0 スコアを表示・アクセスできるようになりました。API を使用してスコアをクエリすることもできます。

### 脆弱性レポートの行インタラクションの改善

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/561414)

{{< /details >}}

以前は、脆弱性レポートから脆弱性詳細ページに移動するには、行の説明を選択する必要がありました。

行のどこでも選択して詳細に直接移動できるようになりました。脆弱性の説明とファイルの場所のリンクスタイルは、各リンクにカーソルを合わせたときのみ表示され、キーボードナビゲーションも改善されました。

これらの変更により、脆弱性レポートがより直感的でアクセスしやすくなります。

### セキュリティダッシュボードを PDF としてエクスポート

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md#export-as-pdf) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18203)

{{< /details >}}

レポートやプレゼンテーションで使用するためにセキュリティダッシュボードを PDF としてエクスポートできます。エクスポートにはアクティブなフィルターを含む、ダッシュボード内のすべてのチャートとパネルの現在の状態が反映されます。

### セキュリティ設定プロファイルでの SAST スキャン

<!-- categories: Security Testing Configuration -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/configuration/security_configuration_profiles.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/19951)

{{< /details >}}

GitLab 18.9 では、**シークレット検出 - デフォルト**プロファイルとともにセキュリティ設定プロファイルを導入しました。GitLab 18.11 では、プロファイルが**静的アプリケーションセキュリティテスト（SAST）- デフォルト**プロファイルで SAST にも拡張され、単一の CI/CD 設定ファイルに触れることなく、すべてのプロジェクトに標準化された静的解析カバレッジを適用するための統一されたコントロールサーフェスが提供されます。

プロファイルは 2 つのスキャントリガーを有効にします:

- **マージリクエストパイプライン**: オープンなマージリクエストのあるブランチに新しいコミットがプッシュされるたびに SAST スキャンを自動的に実行します。結果にはマージリクエストによって導入された新しい脆弱性のみが含まれます。
- **ブランチパイプライン（デフォルトのみ）**: 変更がデフォルトブランチにマージまたはプッシュされたときに自動的に実行され、デフォルトブランチの SAST 状態の完全なビューを提供します。

### グループセキュリティダッシュボードのセキュリティ属性フィルター

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md#filter-the-entire-dashboard) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18201)

{{< /details >}}

グループセキュリティダッシュボードの結果を、そのグループのプロジェクトに適用したセキュリティ属性に基づいてフィルタリングできるようになりました。

利用可能なセキュリティ属性は以下のとおりです:

- ビジネスへの影響
- アプリケーション
- ビジネスユニット
- インターネットへの公開
- 場所

### セキュリティマネージャーロール（ベータ版）

<!-- categories: Permissions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/permissions.md)

{{< /details >}}

セキュリティマネージャーロールがベータ機能として利用可能になりました。セキュリティ専門家向けに特別に設計された新しいデフォルト権限セットを提供します。セキュリティチームはセキュリティ機能にアクセスするために Developer または Maintainer ロールを必要とせず、職務分離を維持しながら過剰な権限付与の懸念を解消します。

セキュリティマネージャーロールを持つユーザーは以下のアクセス権を持ちます:

- **脆弱性管理**: 脆弱性レポートとセキュリティダッシュボードを含む、グループおよびプロジェクト全体の脆弱性の表示、トリアージ、管理。
- **セキュリティインベントリ**: グループのセキュリティインベントリを表示して、すべてのプロジェクトのスキャナーカバレッジを把握。
- **セキュリティ設定プロファイル**: グループのセキュリティ設定プロファイルを表示。
- **コンプライアンスツール**: グループまたはプロジェクトの監査イベント、コンプライアンスセンター、コンプライアンスフレームワーク、依存関係リストを表示。
- **シークレットプッシュ保護**: グループのシークレットプッシュ保護を有効化。
- **オンデマンド DAST**: グループのオンデマンド DAST スキャンを作成および実行。

開始するには、グループに移動して**管理** > **メンバー**を選択し、メンバーをセキュリティマネージャーロールに招待・割り当てます。

### 脆弱性レポートの識別子リストポップオーバー

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/564939)

{{< /details >}}

脆弱性レポートの各行に、プライマリ CVE 識別子がクリック可能なリンクとして表示されるようになりました。複数の識別子が存在する場合、`"+N more"` ポップオーバーにすべての識別子が一覧表示されます。リスト内の各識別子は外部参照（例: CVE、CWE、WASC データベース）にリンクしているため、レポートを離れることなく詳細情報に素早くアクセスできます。

### GitLab Runner 18.11

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.11 もリリースします！GitLab Runner は、CI/CD ジョブを実行して結果を GitLab インスタンスに送信する高スケーラブルなビルドエージェントです。GitLab Runner は、GitLab に含まれるオープンソースの継続的インテグレーションサービスである GitLab CI/CD と連携して動作します。

#### 新機能

- [バンドルされた依存関係を持つ `concrete` ヘルパーイメージの作成](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39286)
- [環境変数の代わりに Runner 設定からジョブルーター機能フラグを読み取る](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39280)

#### バグ修正

- [リファクタリング後の Runner バイナリパスが正しくない](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39329)
- [キャッシュ操作でパイプラインがハングする](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39279)
- [GitLab Runner 18.9.0 の `docker-machine` バイナリが CVE-2025-68121 を参照している](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39276)
- [認証情報ヘルパーバイナリが `DOCKER_AUTH_CONFIG` にない場合、Runner がジョブペイロードの認証情報にサイレントフォールバックする](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39201)
- [`CONCURRENT_PROJECT_ID` が異なるジョブで一意でなく、ビルドディレクトリで競合が発生する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/38307)
- [レスポンスヘッダー待機のタイムアウトでアーティファクトのアップロードが失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37220)
- [ユーザー定義の `after_script` が失敗した `pre_build_script` の後に実行され、`post_build_script` を回避する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/3116)

すべての変更のリストは GitLab Runner の [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-11-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-11-stable/CHANGELOG.md).md) にあります。

## 関連トピック

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.11)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.11)
- [UI 改善](https://papercuts.gitlab.com/?milestone=18.11)
- [非推奨と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
