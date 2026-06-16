---
stage: Release Notes
group: Monthly Release
date: 2026-04-16
title: "GitLab 18.11リリースノート"
description: "GitLab 18.11脆弱性の修正がGitLab Duo Agent Platformで一般提供開始されました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2026年4月16日、GitLab 18.11が以下の機能を搭載してリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Rinku C {#this-months-notable-contributor-rinku-c}

[Rinku C](https://gitlab.com/therealrinku)氏は、2025年9月の参加以来、GitLab全体で80件以上のマージされた改善をもたらしたレベル4のコントリビューターであり、これを称えることを大変嬉しく思います。

[Arianna Haradon](https://gitlab.com/aharadon)氏 (デベロッパーリレーションズチームのシニアフルスタックエンジニア) が指名したこの賞は、彼の継続的かつ有意義な貢献を称えるものです。Rinku氏は、[プロジェクトおよびグループアクセストークン作成フォームでのスコープの要求](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219236)によってセキュリティに配慮したフローを強化し、[ジョブログでの次/前ナビゲーション](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217618) 、[最近の検索結果からの空の検索の除外](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223570) 、および[ファイルツリーの煩雑さの軽減](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224628)といった数々の更新により、日常的なGitLabエクスペリエンスを向上させました。これにより、思慮深いUIの改善を通じて、一般的なワークフローがより明確でナビゲートしやすくなっています。Rinku氏は、あまり注目されない作業にも取り組み、コードベースを健全に保ち、有意義で永続的な価値を積み上げています。あなたのコントリビュートに感謝いたします！

## 主要な機能 {#primary-features}

### 脆弱性の修正がGitLab Duo Agent Platformで一般提供開始 {#vulnerability-resolution-generally-available-on-gitlab-duo-agent-platform}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/agentic_vulnerability_resolution.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/585626)

{{< /details >}}

エージェント型SAST脆弱性の修正が、GitLab 18.11のGitLab Duo Agent Platformで一般提供されるようになりました。これは、SASTスキャンの一部として、SAST誤検出判定の実行後、または個々のSAST脆弱性に対して手動でトリガーされたときに実行されます。

エージェント型SAST脆弱性の修正:

- 発見を自律的に分析し、周囲のコードコンテキストに基づいて推論します。
- 重大重大度および高重大度のSAST脆弱性に対して、提案されたコード修正を含むレビュー準備が整ったマージリクエストを自動的に作成します。
- レビュアーが提案された修正に対する確信度を素早く評価できるように、品質評価を提供します。
- 脆弱性詳細ページから直接修正を適用できます。

[issue 585626](https://gitlab.com/gitlab-org/gitlab/-/issues/585626)で皆様のフィードバックをお待ちしております。

### GitLabデータアナリスト基本エージェントが一般提供開始 {#gitlab-data-analyst-foundational-agent-now-generally-available}

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20337)

{{< /details >}}

データアナリストエージェントは、GitLabプラットフォーム全体でデータをクエリ、可視化し、表示するのに役立つ専門的なAIチャットアシスタントです。

[GitLab Query Language (GLQL)](../../user/glql/_index.md)に支えられたデータアナリストは、サポートされている各[データソース](../../user/glql/data_sources/_index.md)に関するデータを取得および分析し、ソフトウェア開発の健全性とエンジニアリングの効率性に関する明確で実用的なインサイトを提供できます。

これらのインサイトは、エージェントの出力で直接視覚化でき、さらなる評価のためにイシューやエピックに直接埋め込むことができます。

### CIエキスパートエージェントがベータ版でリリース {#ci-expert-agent-launches-in-beta}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/ci_expert_agent.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/587460)

{{< /details >}}

AIを活用したCIエキスパートエージェントが、ベータ版で利用可能になりました。このエージェントは、チームが空白の`.gitlab-ci.yml`から始めることなく、GitLabコードから最初の動作するパイプラインを構築するのに役立ちます。

GitLab Duo Agent Platformを使用することで、エージェントはリポジトリを検査し、ビルドおよびテストプロセスについていくつかの質問をし、レビュー、編集、コミットできるすぐに実行可能なパイプラインを生成します。

これにより、パイプラインの作成が会話的でコンテキスト認識型のエクスペリエンスに変わり、設定を開発および最適化する準備ができた後でも、YAMLを完全に制御できます。

### 自動化された脆弱性の重大度のオーバーライド {#automated-vulnerability-severity-overrides}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/policies/vulnerability_management_policy.md#severity-override-policies) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15839)

{{< /details >}}

デフォルトの脆弱性の重大度は、組織の実際のリスクを常に反映しているわけではありません。内部サービスにおける致命的なCVEは、公開アプリケーションにおけるものと同じ緊急性を保証しない可能性がありますが、チームは自身のリスクモデルと一致しない調査結果をトリアージするのにかなりの時間を費やしています。

脆弱性管理ポリシーは、CVE ID、CWE ID、ファイルパス、ディレクトリなどの条件に基づいて脆弱性の重大度を自動的に調整できるようになりました。適用されると、ポリシーはデフォルトブランチの基準に一致するすべての脆弱性の重大度を更新します。手動オーバーライドは引き続き優先され、すべての変更は脆弱性の履歴および監査イベントにログ記録されます。

これにより、トリアージ作業が削減され、開発者はビジネスにとって最も重要な発見に集中できるようになります。

### サービスアカウントをサブグループおよびプロジェクトに作成 {#create-service-account-in-subgroups-and-projects}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/profile/service_accounts.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{< /details >}}

チームは、サブグループおよびプロジェクトでサービスアカウントを作成できるようになりました。広範なトップレベルグループのボットの代わりに、専用のサービスアカウントを単一のサブグループまたはプロジェクトにアタッチし、そのネームスペースの他のメンバーと同様にそのアクセスを管理できます。グループおよびサブグループのサービスアカウントは、作成されたグループ、または任意の子孫サブグループおよびプロジェクトに招待できます。プロジェクトサービスアカウントは、自身のプロジェクトに限定されます。

### GitLab Freeで利用可能なサービスアカウント {#service-accounts-available-on-gitlab-free}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/profile/service_accounts.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20439)

{{< /details >}}

サービスアカウントが、すべてのティアのGitLab.comで利用できるようになりました。これまでPremiumおよびUltimateに限定されていたサービスアカウントを使用すると、認証情報を個々のチームメンバーに紐付けることなく、自動化されたアクションの実行、データへのアクセス、またはスケジュールされたプロセスの実行が可能です。これらは、チームの変更に関わらず認証情報が安定している必要があるパイプラインやサードパーティのインテグレーションで一般的に使用されます。Freeでは、サブグループまたはプロジェクトで作成されたものを含め、トップレベルグループごとに最大100個のサービスアカウントを作成できます。

### 詳細権限パーソナルアクセストークンが利用可能になりました（ベータ） {#fine-grained-permissions-for-personal-access-tokens-now-available-beta}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../auth/tokens/fine_grained_access_tokens.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/18555)

{{< /details >}}

詳細権限パーソナルアクセストークン (PAT) がベータ版で利用可能になりました。所属するすべてのプロジェクトとグループへのアクセスを許可する従来のPATとは異なり、詳細権限PATを使用すると、各トークンを特定のリソースとアクションに限定できます。これにより、漏洩または不正なトークンの潜在的な影響が軽減されます。

既存のPATはこれまでどおり機能し、詳細権限なしで従来のPATを作成することもできます。

このベータ版リリースは、GitLab REST APIの約75%をカバーしています。フルREST APIのカバレッジ、GraphQLの強制、および管理者ポリシーの制御は、GAリリースで計画されています。

フィードバックを共有するには、[エピック18555](https://gitlab.com/groups/gitlab-org/-/epics/18555)を参照してください。

### セキュリティダッシュボードのトップCWEチャート {#top-cwe-chart-in-security-dashboards}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md#top-10-cwes) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17422)

{{< /details >}}

新しいセキュリティダッシュボードで、トップCWEチャートが利用可能になりました。プロジェクトまたはインスタンス全体の最も一般的なCWEを特定し、トレーニング、改善、またはプログラム最適化の機会を見つけます。ユーザーは、重大度でダッシュボードデータをグループ化し、重大度、プロジェクト、およびレポートタイプでダッシュボードをフィルタリングできます。

### デプロイGitaly on Kubernetes {#deploy-gitaly-on-kubernetes}

<!-- categories: Gitaly -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../administration/gitaly/kubernetes.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/work_items/6127)

{{< /details >}}

完全にサポートされているデプロイ方法として、GitalyをKubernetesにデプロイできるようになりました。これにより、Kubernetesのオーケストレーション機能を使用して、スケール、HA、およびリソース管理を行うことで、GitLabインフラストラクチャをより柔軟に管理できます。これまで、Kubernetesのデプロイはカスタム設定を必要とし、公式にはサポートされていなかったため、コンテナ化された環境で信頼性の高いGitalyのデプロイを維持することが困難でした。

### MRパイプラインを手動で実行する際の入力の再設定 {#reconfigure-inputs-when-manually-running-mr-pipelines}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/pipelines/merge_request_pipelines.md#run-a-merge-request-pipeline-with-custom-inputs) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/547861)

{{< /details >}}

CI/CDインプットの強力な側面は、ランタイムカスタマイズのために新しい値で新しいパイプラインを手動で実行できることです。これは以前はマージリクエスト (MR) パイプラインでは利用できませんでしたが、このリリースではMRパイプラインでも入力をカスタマイズできるようになりました。

MRパイプラインの入力を設定した後、オプションでそれらの入力を変更し、マージリクエストのために新しいパイプラインを実行するたびにパイプラインの動作を変更できます。

## エージェント型コア {#agentic-core}

### GitLab Duo Agentic ChatのデフォルトモデルがHaiku 4.5からSonnet 4.6に更新 {#default-model-for-gitlab-duo-agentic-chat-updated-from-haiku-45-to-sonnet-46}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/model_selection.md#default-models) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/595042)

{{< /details >}}

GitLabでのAgentic Chatエクスペリエンスを向上させるための更新を行いました。Agentic Chatのデフォルトモデルが、Claude Haiku 4.5からVertex AIでホストされているClaude Sonnet 4.6にアップグレードされました。Claude Sonnet 4.6は、推論と応答の品質が向上していますが、Haiku 4.5よりも高いGitLabクレジットの乗算係数を使用します。

[モデル選択](../../user/duo_agent_platform/model_selection.md#select-a-model-for-a-feature)設定を使用して、Haikuを含む代替モデルを選択できます。すでに特定のモデルを選択している場合、その選択は維持されます。この更新はデフォルトにのみ影響し、既存の選択をオーバーライドすることはありません。モデルごとのクレジット乗数に関する情報は、[GitLabクレジットのドキュメント](../../subscriptions/gitlab_credits.md)を参照してください。

### カスタムフロー定義でのツールの設定 {#configure-tools-in-custom-flow-definitions}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/duo_agent_platform/flows/custom.md#create-a-flow) | [関連イシュー](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/work_items/2147)

{{< /details >}}

カスタムフロー定義でツールオプションとパラメータ値を直接設定し、LLMのデフォルト値を上書きできるようになりました。これにより、カスタムフロー内でのツールの動作をより正確かつ一貫して制御できるようになり、そのフロー全体でガードレールと特定のパラメータ値を適用しやすくなります。

### Mistral AIがGitLab Duo Agent Platformでセルフホストモデルとしてサポートされるようになりました {#mistral-ai-now-supported-as-a-self-hosted-model-in-gitlab-duo-agent-platform}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms.md#cloud-hosted-model-deployments) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/587872)

{{< /details >}}

GitLab Duo Agent Platformが、セルフホストモデルのデプロイ用にLLMプラットフォームとしてMistral AIをサポートするようになりました。GitLab Self-Managedの顧客は、既存のサポートされているプラットフォーム（AWS Bedrock、Google Vertex AI、Azure OpenAI、Anthropic、OpenAIなど）と並行してMistral AIを設定できます。これにより、チームはAIを活用した機能をどのように実行するかにおいて、より多くの選択肢を得られます。

## 規模とデプロイ {#scale-and-deployments}

### GitLabクレジットダッシュボードで過去の月を表示 {#view-historical-months-in-gitlab-credits-dashboard}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#view-the-gitlab-credits-dashboard) | [関連イシュー](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15910)

{{< /details >}}

カスタマーポータルのGitLabクレジットダッシュボードが、過去の月のナビゲーションをサポートするようになりました。請求管理者は、過去の請求月を閲覧して日々の使用量トレンドをレビューし、期間ごとの消費パターンを比較し、請求書と使用量を照合できます。以前は、ダッシュボードには現在の請求月のみが表示されていました。この改善により、管理者はクレジット割り当てについてより情報に基づいた決定を下し、履歴データに基づいて将来のニーズを予測できるようになります。

### サブスクリプションレベルでのGitLabクレジットの使用上限を設定 {#set-subscription-level-usage-cap-for-gitlab-credits}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#usage-control-status)

{{< /details >}}

管理者は、サブスクリプションレベルでオンデマンドクレジットの月間使用上限を設定できるようになりました。オンデマンドクレジットの合計消費量が設定された上限に達すると、GitLab Duo Agent Platformへのアクセスは、次回の請求期間が開始されるか、管理者が上限を調整するまで、そのサブスクリプションのすべてのユーザーに対して自動的に停止されます。この設定により、組織は予期せぬ過剰請求に対する厳格なガードレールを得ることができ、より広範なエージェントプラットフォームのロールアウトに対する主要な障壁が取り除かれます。上限は各請求期間に自動的にリセットされ、上限に達すると管理者にメール通知が送信されます。

### Set per-user GitLab Credits cap {#set-per-user-gitlab-credits-cap}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#usage-control-status)

{{< /details >}}

管理者は、請求期間ごとにGitLabクレジットのオプションのユーザーごとの使用上限を設定できるようになりました。個々のユーザーの合計クレジット消費量が設定された制限に達すると、GitLab Duo Agent Platformへのアクセスはそのユーザーのみ停止され、他のユーザーは影響を受けずに継続できます。これにより、単一のユーザーが組織のクレジットプールの不均衡なシェアを消費するのを防ぎ、管理者は使用量の配分をきめ細かく制御できます。ユーザーごとの使用上限は、サブスクリプションレベルの使用上限と連携し、最初に達した上限を適用します。

### Linuxパッケージの改善 {#linux-package-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server) | [関連イシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9734)

{{< /details >}}

GitLab 19.0では、PostgreSQLの最小サポートバージョンはバージョン17になります。この変更に備えるため、[PostgreSQLクラスター](../../administration/postgresql/replication_and_failover.md)を使用しないインスタンスでは、GitLab 18.11へのアップグレード時にPostgreSQLをバージョン17に自動的にアップグレードしようとします。

[PostgreSQLクラスター](../../administration/postgresql/replication_and_failover.md)を使用している場合、または[この自動アップグレードをオプトアウト](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades)する場合は、GitLab 19.0にアップグレードできるよう[手動でPostgreSQL 17にアップグレード](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server)する必要があります。

### コンテナレジストリメタデータデータベースのバックアップおよび復元のサポート {#backup-and-restore-support-for-container-registry-metadata-database}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/backup_restore/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-com/gl-infra/data-access/durability/-/work_items/45)

{{< /details >}}

Linuxパッケージインストール用のGitLab `backup` Rakeタスクおよびクラウドネイティブ (Helm) インストール用の`[backup-utility](https://docs.gitlab.com/charts/backup-restore/)`が、[コンテナレジストリメタデータデータベース](../../administration/packages/container_registry_metadata_database.md)をサポートするようになりました。メタデータデータベースに保存されているblob、マニフェスト、タグ、およびその他のデータへの参照をバックアップできるようになり、悪意のあるデータ破損または偶発的なデータ破損が発生した場合のリカバリーが可能になります。

### 検索内のグループ向けの新しいナビゲーションエクスペリエンス {#new-navigation-experience-for-groups-in-explore}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/group/_index.md#explore-groups) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/13791)

{{< /details >}}

**検索**のグループリストの改善を発表できることを嬉しく思います。これにより、GitLabインスタンス全体でグループをより簡単に見つけられるようになります。再設計されたインターフェースでは、2つのビューを持つタブ形式のレイアウトが導入されています:

- **アクティブ**タブ: アクセス可能なすべてのグループを参照し、関連するコミュニティやプロジェクトを見つけるのに役立ちます。
- **非アクティブ**タブ: アーカイブされたグループや削除待ちのグループを表示し、グループのライフサイクルステータスに関する表示レベルを確認します。

これらの変更により、グループの発見が効率化され、参加可能なグループの表示レベルがより明確になります。

### プロジェクトの非同期転送 {#asynchronous-transfer-of-projects}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/group/manage.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20521)

{{< /details >}}

以前のバージョンのGitLabでは、大規模なグループおよびプロジェクトの転送がタイムアウトすることがありました。転送、アーカイブ、削除などの操作に統合された状態モデルを使用するようにグループとプロジェクトを移行するにつれて、より一貫性のある動作、状態履歴と監査詳細へのより良い表示レベル、および特に長期実行される転送操作におけるタイムアウトの減少が、非同期処理を通じて得られます。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### ClickHouseがSelf-Managedデプロイ向けに一般提供開始 {#clickhouse-is-generally-available-for-self-managed-deployments}

<!-- categories: DevOps Reports -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../integration/clickhouse.md#set-up-clickhouse) | [関連イシュー](https://gitlab.com/groups/gitlab-org/architecture/gitlab-data-analytics/-/work_items/51)

{{< /details >}}

GitLab Self-Managedインスタンスの場合、GitLab [ClickHouseインテグレーション](../../integration/clickhouse.md)に関する改善された推奨事項と設定ガイドが提供されるようになりました。顧客は、独自のクラスターを持ち込むか、ClickHouse Cloud (推奨) のセットアップオプションを使用することができます。このインテグレーションは複数のダッシュボードを強化し、分析スペース内のさまざまなAPIエンドポイントへのアクセスを可能にします。

このスケール可能で高性能なデータベースは、GitLab分析インフラストラクチャのために計画されている大規模なアーキテクチャ改善の一部です。

### GitLab Duo Agent Platform分析の強化、GitLab DuoとSDLCのトレンドダッシュボードに表示 {#enhanced-gitlab-duo-agent-platform-analytics-on-duo-and-sdlc-trends-dashboard}

<!-- categories: DevOps Reports -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/analytics/duo_and_sdlc_trends.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20540)

{{< /details >}}

GitLab DuoとSDLCのトレンドダッシュボードは、GitLab Duoがソフトウェアデリバリーに与える影響を測定するための分析機能を強化します。このダッシュボードには、月間エージェントプラットフォームのユニークユーザー数とAgentic Chatセッションの新しい単一統計パネルが含まれるようになりました。さらに、以前はシート割り当てと比較した使用率（％）として表示されていたメトリクスは、厳密に使用カウントを報告するように更新されました。この変更により、新しい使用量課金モデルで管理されているエージェントプラットフォームの使用量でカウントが不足していた[イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/590326)が解決されます。

### GLQLがプロジェクト、パイプライン、およびジョブのデータソースにアクセスできるようになりました {#glql-now-has-access-to-projects-pipelines-and-jobs-data-sources}

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/glql/data_sources/_index.md)

{{< /details >}}

[GitLab Query Language (GLQL)](../../user/glql/_index.md)が、プロジェクト、パイプライン、およびジョブという3つの新しいデータソースにアクセスできるようになりました。これらの新しいデータソースは埋め込みビューとしても利用でき、チームはパイプラインの結果、ジョブステータス、プロジェクトの概要をWiki、イシューおよびマージリクエストの説明、リポジトリのMarkdownファイルに直接表示できます。GLQLは、[データアナリストエージェント](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md)も強化します。

これらの新しいタイプにより、エージェントはCI/CDジョブの結果を検査し、失敗をデバッグし、パイプライン実行の詳細な概要を提供できるだけでなく、ネームスペース内のプロジェクトの正確な概要も提供できます。

### MavenおよびPython SBOMスキャンにおける依存関係の解決 {#dependency-resolution-for-maven-and-python-sbom-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#dependency-resolution) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20461)

{{< /details >}}

依存関係スキャンでSBOMを使用するGitLabは、MavenおよびPythonプロジェクト向けに依存関係グラフを自動的に生成できるようになりました。以前は、依存関係スキャンでは、正確な依存関係分析を得るために、ユーザーがロックファイルまたはグラフファイルを提供する必要がありました。現在、ロックファイルまたはグラフファイルが利用できない場合、アナライザーは自動的にそれを生成しようとします。この改善により、MavenおよびPythonプロジェクトは、ロックファイルを必要とせずに依存関係スキャンを有効にすることが容易になります。

### 高度なSAST向けのインクリメンタルスキャン {#incremental-scanning-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md#incremental-scanning) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20508)

{{< /details >}}

GitLab高度なSASTを使用して、コードベースの変更された部分のみを分析するインクリメンタルスキャンを実行できるようになり、完全なリポジトリスキャンと比較してスキャン時間を大幅に短縮できます。この機能は、コードベースに対して完全な結果を生成するため、差分ベースのスキャンのさらなるイテレーションです。

コードベース全体ではなく、変更されたコードのみをスキャンすることで、チームは速度を犠牲にしたり摩擦を加えたりすることなく、セキュリティテストを開発ワークフローにseamlessly統合できます。

### 未検証の脆弱性（ベータ） {#unverified-vulnerabilities-beta}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md#report-unverified-vulnerabilities) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/15649)

{{< /details >}}

高度なSASTは、未検証の脆弱性（ソースからシンクまで完全にトレースできない発見）を脆弱性レポートに直接表示できるようになりました。この機能は、false negativesよりも誤検出に対する許容度が高い場合に有効にしてください。

この機能はベータ版です。[イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/596512) 596512でフィードバックを提供してください。

### Kubernetes 1.35のサポート {#kubernetes-135-support}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/584225)

{{< /details >}}

GitLabは、Kubernetesバージョン1.35を完全にサポートするようになりました。アプリケーションをKubernetesにデプロイし、すべての機能にアクセスするには、接続されているクラスターを最新バージョンにアップグレードしてください。詳細については、[GitLab機能でサポートされているKubernetesバージョン](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)を参照してください。

### コンテナレジストリメタデータデータベースのプリファレンスモード {#prefer-mode-for-the-container-registry-metadata-database}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/packages/container_registry_metadata_database.md#prefer-mode) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/595480)

{{< /details >}}

既存の`true`および`false`の値と並行して、コンテナレジストリメタデータデータベースを`prefer`モードに設定できるようになりました。プリファレンスモードでは、レジストリは、メタデータデータベースを使用すべきか、インストールの現在の状態に基づいてレガシーストレージにフォールバックすべきかを自動的に検出します。

あなたのレジストリにまだデータベースにインポートされていない既存のファイルシステムメタデータがある場合、メタデータのインポートを完了するまで、レジストリは従来のストレージを使用し続けます。データベースがすでに使用されている場合、または新規インストールの場合、レジストリはデータベースを直接使用します。

以降のリリースでは、`prefer`モードが新しいLinuxパッケージインストールのデフォルトになります。既存のインストールは影響を受けません。詳細については、[イシュー595480](https://gitlab.com/gitlab-org/gitlab/-/work_items/595480)を参照してください。

### パッケージ保護ルールがTerraformモジュールをサポート {#package-protection-rules-now-support-terraform-modules}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/packages/package_registry/package_protection_rules.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/592761)

{{< /details >}}

組み込みのGitLab Terraformモジュールレジストリを通じてTerraformモジュールを公開するチームは、新しいモジュールバージョンをプッシュできるユーザーを制限する方法がありませんでした。パッケージ保護ルールは、いくつかのパッケージ形式をサポートしていましたが、`terraform_module`を含んでいなかったため、インフラストラクチャチームはプロジェクトレベルのプッシュ制御を持っていませんでした。

これで、`terraform_module`にスコープされたパッケージ保護ルールを作成し、最小ロールに基づいてプッシュアクセスを制限できます。UIパッケージタイプドロップダウン、REST API、GraphQL API、およびGitLab Terraform Providerリソースでサポートが利用可能です。

### リリースエビデンスにパッケージが含まれるようになりました {#release-evidence-now-includes-packages}

<!-- categories: Package Registry, Release Evidence -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/releases/release_evidence.md#include-packages-as-release-evidence) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/283995)

{{< /details >}}

GitLabリリースの作成時、パッケージレジストリに公開されたパッケージは自動的にそれに関連付けられていませんでした。チームは、APIまたはパイプラインスクリプトを通じてパッケージURLを手動で構築し、リリースリンクとして添付する必要があり、これが摩擦を生み、不完全なリリースレコードのリスクを高めていました。

GitLabは、パッケージのバージョンがリリースタグと一致する場合、リリースエビデンスに自動的にパッケージを含めるようになりました。これにより、リリースとその関連パッケージ間の検証可能で監査可能なリンクが手動の手順なしで作成され、ソースコード、アーティファクト、およびパッケージが1つの完全なリリーススナップショットにまとめられます。

### Wikiサイドバーの切替がアクセスしやすいように再配置されました {#wiki-sidebar-toggle-repositioned-for-easier-access}

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/wiki/_index.md#sidebar) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/580569)

{{< /details >}}

Wikiサイドバーの切替が、制御するサイドバーのすぐ左側に配置されるようになりました。

サイドバーが折りたたむまれると、切替はフローティングコントロールとして表示されたままになるため、ページの上部までスクロールし直すことなく再度開くことができます。

### Wikiページのスティッキーアクションバー {#sticky-action-bar-on-wiki-pages}

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/wiki/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/590255)

{{< /details >}}

Wikiページのアクションバーはスティッキーになり、ページをスクロールしても表示されたままになります。以前は、編集、ページ履歴の表示、またはテンプレートの管理などのアクションにアクセスするには、上部までスクロールし直す必要がありました。これで、ページタイトルと主要なアクション（編集、新規ページ、テンプレート、ページ履歴など）は、ページをどれだけスクロールしても常に手の届くところにあります。

### エピックのウェイト {#epic-weights}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/work_items/weight.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/12273)

{{< /details >}}

エピックがウェイトをサポートするようになり、計画中の大規模なイニシアチブをより簡単に推定および優先順位付けできるようになりました。

エピックを子イシューに分解する前に、最初の見積もりを表す暫定ウェイトを割り当てることができます。エピックを分解すると、ウェイトはすべての子イシューからのロールアップされた合計を反映するように自動的に更新されます。これは、ウェイトのロールアップがイシューとタスクで機能する方法と一貫しています。

エピックの詳細ページでは、暫定ウェイトと子イシューからのロールアップされたウェイトの両方を確認でき、時間の経過とともに見積もりを改善するために必要なインサイトが得られます。

### 悪用可能性リスクが高いマージリクエストをブロック {#block-merge-requests-with-high-exploitability-risk}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#vulnerability_attributes-object) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16311)

{{< /details >}}

以前は、マージリクエスト (MR) の承認ポリシーは脆弱性の重大度に基づいてMRをブロックできましたが、すべての脆弱性が同じリスクを持つわけではありません。CVSSの重大度だけでは、CVEが悪用されているか、悪用される可能性がどの程度あるかを判断することはできません。これにより、煩雑な承認ポリシーとなり、デベロッパーやセキュリティチームの時間が無駄になります。

既知の悪用された脆弱性 (KEV) とExploit Prediction Scoring System (EPSS) のデータを使用して、MR承認ポリシーを設定できるようになりました。発見がKEVカタログにある場合（実際に悪用されている場合）、またはそのEPSSスコアがしきい値を超えている場合に、ブロックするか承認を要求します。MRにおけるポリシーの違反には、KEVおよびEPSSのコンテキストが含まれているため、デベロッパーはセキュリティゲートがトリガーされた理由を理解できます。

これにより、セキュリティチームはどの発見をブロックまたは警告するかを正確に制御し、アラートの疲労を軽減し、現在の脅威状況に沿った強制を維持できます。

### CVSS 4.0スコアを脆弱性に割り当てる {#assign-cvss-40-scores-to-vulnerabilities}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/severities.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18697)

{{< /details >}}

CVSS 4.0は、脆弱性の重大度を評価および格付けするために使用される業界標準の最新バージョンです。これで、脆弱性詳細ページや脆弱性レポートを含むUIでCVSS 4.0スコアを表示およびアクセスできます。APIを使用してスコアをクエリすることもできます。

### 脆弱性レポートでの行インタラクションの改善 {#improved-row-interaction-in-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/561414)

{{< /details >}}

以前は、脆弱性レポートから脆弱性詳細ページに移動するには、行の説明を選択する必要がありました。

これで、行のどこでも選択して詳細に直接移動できます。脆弱性の説明とファイルパスのリンクスタイルは、各リンクにカーソルを合わせるときにのみ表示され、キーボードナビゲーションが改善されました。

これらの変更により、脆弱性レポートはより直感的でアクセスしやすくなります。

### PDFとしてセキュリティダッシュボードをエクスポートする {#export-a-security-dashboard-as-a-pdf}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md#export-as-pdf) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18203)

{{< /details >}}

セキュリティダッシュボードをPDFとしてエクスポートし、レポートやプレゼンテーションで使用できます。エクスポートは、ダッシュボード内のすべてのチャートとパネルの現在の状態（アクティブなフィルターを含む）をキャプチャします。

### セキュリティ設定プロファイルにおけるSASTスキャン {#sast-scanning-in-security-configuration-profiles}

<!-- categories: Security Testing Configuration -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/configuration/security_configuration_profiles.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/19951)

{{< /details >}}

GitLab 18.9では、**Secret Detection - Default**プロファイルを含むセキュリティ設定プロファイルを導入しました。GitLab 18.11では、プロファイルが**Static Application Security Testing (SAST) - Default**プロファイルとともにSASTに拡張され、単一のCI/CD設定ファイルに触れることなく、すべてのプロジェクトにわたって標準化された静的な解析カバレッジを適用するための統一されたコントロールサーフェスを提供します。

このプロファイルは2つのスキャントリガーを有効にします:

- **マージリクエストパイプライン**: 新しいコミットがオープンなマージリクエストのあるブランチにプッシュされるたびに、自動的にSASTスキャンを実行します。結果には、マージリクエストによって導入された新しい脆弱性のみが含まれます。
- **ブランチパイプライン(デフォルトのみ)**: 変更がデフォルトブランチにマージまたはプッシュされると自動的に実行され、デフォルトブランチのSASTの姿勢を完全に表示します。

### グループセキュリティダッシュボードにおけるセキュリティ属性フィルター {#security-attribute-filters-in-group-security-dashboards}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md#filter-the-entire-dashboard) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18201)

{{< /details >}}

グループセキュリティダッシュボードの結果を、そのグループのプロジェクトに適用したセキュリティ属性に基づいてフィルタリングできるようになりました。

利用可能なセキュリティ属性は以下のとおりです:

- ビジネスインパクト
- アプリケーション
- ビジネスユニット
- インターネット公開
- 場所

### セキュリティマネージャーロール（ベータ） {#security-manager-role-beta}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/permissions.md)

{{< /details >}}

セキュリティマネージャーロールは、セキュリティ専門家向けに特別に設計された新しいデフォルトの権限セットを提供するベータ機能として利用可能になりました。セキュリティチームは、セキュリティ機能にアクセスするためにデベロッパーまたはメンテナーロールを必要とせず、過剰な権限付与の懸念を排除しつつ、職務分離を維持します。

セキュリティマネージャーロールを持つユーザーは、以下のアクセス権を持っています:

- **脆弱性管理**: グループおよびプロジェクト全体の脆弱性の表示、トリアージ、管理（脆弱性レポートおよびセキュリティダッシュボードを含む）。
- **セキュリティインベントリ**: グループのセキュリティインベントリを表示して、すべてのプロジェクトにわたるスキャナーのカバレッジを理解します。
- **Security configuration profiles**: グループのセキュリティ設定プロファイルを表示します。
- **Compliance tools**: グループまたはプロジェクトの監査イベント、コンプライアンスセンター、コンプライアンスフレームワーク、および依存関係リストを表示します。
- **シークレットプッシュ保護**: グループのシークレットプッシュ保護を有効にします。
- **On-demand DAST**: グループのオンデマンドDASTスキャンを作成して実行します。

開始するには、グループに移動し、**管理** > **メンバー**を選択して、メンバーをセキュリティマネージャーロールに招待し、割り当てます。

### 脆弱性レポート内の識別子リストポップオーバー {#identifier-list-popover-in-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/564939)

{{< /details >}}

脆弱性レポートには、各行にクリック可能なリンクとして主要なCVE識別子が表示されるようになりました。複数の識別子が存在する場合、`"+N more"`ポップオーバーにすべての識別子がリストされます。リスト内の各識別子は、その外部参照（たとえば、CVE、CWE、またはWASCデータベース）にリンクしているため、レポートを離れることなく詳細に素早くアクセスできます。

### GitLab Runner 18.11 {#gitlab-runner-1811}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.11もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [`concrete`ヘルパーイメージをバンドルされた依存関係とともに作成](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39286)
- [ジョブルーター機能フラグを環境変数ではなくRunnerの設定から読み取る](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39280)

#### バグ修正 {#bug-fixes}

- [リファクタリング後のRunnerバイナリパスの誤り](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39329)
- [パイプラインがキャッシュ操作でハングアップする](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39279)
- [GitLab Runner 18.9.0の`docker-machine`バイナリがCVE-2025-68121を参照する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39276)
- [Runnerが`DOCKER_AUTH_CONFIG`から認証情報ヘルパーバイナリが欠落している場合、ジョブペイロード認証情報にサイレントにフォールバックする](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39201)
- [`CONCURRENT_PROJECT_ID `が異なるジョブで一意ではなく、ビルドディレクトリで競合を引き起こす](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/38307)
- [アーティファクトのアップロードが、応答ヘッダー待ちでタイムアウトして失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37220)
- [ユーザー定義の`after_script`が失敗した`pre_build_script`の後に実行され、`post_build_script`をバイパスする](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/3116)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-11-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-11-stable/CHANGELOG.md).md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.11)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.11)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.11)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
