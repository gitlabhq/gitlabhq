---
stage: Release Notes
group: Monthly Release
date: 2026-01-15
title: "GitLab 18.8 リリースノート"
description: "GitLab 18.8がリリースされました。GitLab Duo Agent Platformが正式リリース（GA）になりました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2026年1月15日、GitLab 18.8が以下の機能とともにリリースされました。

また、今月の注目コントリビューターをはじめ、すべてのコントリビューターの皆様に感謝申し上げます。

## 今月の注目コントリビューター: Wesley Yarde

今月の注目コントリビューターは、[Wesley Yarde](https://gitlab.com/WYarde)さんです。エンタープライズユーザーのSSHキーを無効化できる、組織向けの基盤となる新機能を構築してくださいました。

Wesleyさんのコントリビュートが際立っている理由はいくつかあります。

- **セキュリティとコンプライアンス**: この機能により、組織はSSHキーの要件を強制し、エンタープライズ全体のセキュリティを強化できます。
- **基盤となる作業**: 既存の実装がない状態から、GitLabチームと緊密に連携して要件とアーキテクチャをゼロから定義する必要がありました。
- **初めてのコントリビュート**: 驚くべきことに、これはWesleyさんのGitLabへの初めてのコントリビュートでした。複雑なコードベースをナビゲートし、難しい機能に取り組む卓越した能力を示してくれました。
- **将来の開発の基盤**: この作業は、インスタンスレベルのSSHキー無効化やサービスアカウント制御など、類似機能の基盤を確立します。

実装は複数のマージリクエスト（[!205020](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205020)、[!210482](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210482)）にわたり、徹底したレビューサイクルを経ました。複雑さにもかかわらず、Wesleyさんはプロセス全体を通じて優れたコラボレーションと忍耐力を発揮してくれました。

「この機能リクエストでWesleyさんと協力できたことは大変光栄でした！コントリビューターもレビュアーもレビュープロセスが大変だと感じたかもしれませんが、双方が理解を示し、実装が確実で完全なものになるよう素晴らしいコラボレーションを発揮してくれました。」— Wesleyさんをこの表彰に推薦した[Bogdan Denkovych](https://gitlab.com/bdenkovych)

Wesleyさん、おめでとうございます。そして、GitLabへのこの貴重なコントリビュートに感謝します！

## 主要機能

### GitLab Duo Agent Platformが正式リリース（GA）

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/585273)

{{< /details >}}

GitLab Duo Agent Platformが正式リリース（GA）となり、ソフトウェア開発ライフサイクル全体にわたるエージェント型AIオーケストレーションを提供します。個々のタスクを単独で高速化するAIツールとは異なり、Agent Platformはチームが計画、構築、セキュリティ確保、ソフトウェアのリリースにわたってAIエージェントを連携させるのを支援し、個人の作業の高速化とソフトウェアデリバリーの協調的・多段階的な現実との間のギャップを埋めます。

このプラットフォームは、チームが組織全体でエージェントとフローを発見、管理、共有できる中央AIカタログを提供します。Planner、Security Analyst、Data Analystなどの組み込み基盤エージェントが主要な意思決定ポイントで構造化された作業を処理し、カスタマイズ可能なフローがイシューからマージリクエスト、CI/CDの移行、パイプラインのトラブルシューティング、コードレビューまで、開発ワークフローにおける複数ステップのエージェントとタスクを自動化します。

ガバナンス制御、使用状況の可視性、オフライン環境向けのセルフホストモデルを含む柔軟なデプロイオプションにより、組織は必要な透明性と制御を維持しながらAIを大規模に導入できます。

GitLab PremiumおよびUltimateユーザーは、プロモーション用の[GitLabクレジット](../../subscriptions/gitlab_credits.md)を使用して、GitLab.comおよびGitLab Self-ManagedインスタンスでAgent Platformを今すぐ使い始めることができます。

### GitLab Duo Planner Agentが正式リリース（GA）

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/planner.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/583008)

{{< /details >}}

Planner Agentが正式リリース（GA）となりました！Planner Agentは、GitLab内でプロダクトマネージャーを直接支援するために構築された基盤エージェントです。

Planner Agentを使用して、GitLabの作業アイテムを作成、編集、分析できます。手動でアップデートを追いかけたり、作業の優先順位を付けたり、計画データを要約したりする代わりに、Planner Agentがバックログの分析、RICEやMoSCoWなどのフレームワークの適用、本当に注意が必要なことの表面化を支援します。計画ワークフローを理解し、より良く効率的な意思決定を行うために協力してくれる積極的なチームメンバーのような存在です。

フィードバックは[イシュー583008](https://gitlab.com/gitlab-org/gitlab/-/work_items/583008)にお寄せください。

### GitLab Duo Security Analyst Agentが正式リリース（GA）

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/security_analyst_agent.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

[GitLab 18.5でベータ版として導入された](https://about.gitlab.com/releases/2025/10/16/gitlab-18-5-released/#gitlab-security-analyst-agent-for-duo-agent-catalog-beta)GitLab Duo Security Analyst Agentが、GitLab 18.8で正式リリース（GA）となりました。

Security Analyst Agentにより、エンジニアはGitLab Duo Agentic Chatの自然言語コマンドを通じて脆弱性を管理できます。脆弱性ダッシュボードを手動でクリックしたり、一括操作のカスタムスクリプトを作成したりする代わりに、セキュリティチームはChatの会話で脆弱性のトリアージ、評価、ガイダンスの提供を行えます。

基盤エージェントとして、Security Analyst AgentはGitLab Duo Agentic Chatでデフォルトで利用可能であり、手動セットアップは不要です。

### 脆弱性管理ポリシーによる無関係な脆弱性の自動却下

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/policies/vulnerability_management_policy.md#auto-dismiss-policies) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10894)

{{< /details >}}

セキュリティチームは、脆弱性管理ポリシーを使用して、組織に適用されない脆弱性を自動的に却下できるようになりました。組織に関連しない脆弱性を却下することで、ノイズが減り、実際のリスクをもたらす脆弱性に開発者が集中できるようになります。

以下に基づいて脆弱性を自動却下するポリシーを作成できます。

- ファイルパス
- ディレクトリ
- 識別子（CVE、CWE、またはOWASP）

自動却下された脆弱性は、マージリクエストのセキュリティウィジェットに**自動却下済み**ラベルとともに表示され、監査目的で却下理由とともに脆弱性レポートのアクティビティに記録されます。

## エージェントコア

### GitLab Duo Agent Platformのオン/オフ切り替え

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/583980)

{{< /details >}}

GitLab Duo Chat（Agentic）、エージェント、フローを含むGitLab Duo Agent Platformを、トップレベルグループまたはインスタンス全体でオン/オフできるようになりました。この設定がオフになると、これらの機能は利用できなくなります。

### GitLab Duo機能のグループアクセス制御

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../administration/gitlab_duo/configure/access_control.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/585355)

{{< /details >}}

GitLab Duo機能を使用できるユーザーを制御するグループアクセスルールを定義できるようになりました。即時の組織全体へのアクセスから段階的なロールアウトまで、柔軟な導入戦略を実現します。

この機能は、セキュリティとコンプライアンスを維持しながら自分のペースで導入を拡大できる、きめ細かなガバナンス制御を提供します。

### GitLab Duo Self-Hosted向けGitLab Duo Agent Platform（オフラインライセンス）が正式リリース（GA）

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/19125)

{{< /details >}}

GitLab Duo Agent PlatformがDuo Self-Hostedで正式リリース（GA）となりました。この機能は、オフラインライセンスを持つGitLab Self-Managedのお客様が利用でき、シートベースの料金体系を採用しています。

Self-Managedの管理者は、GitLab Duo Agent Platformで使用する[互換モデル](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models)を設定できます。AWS BedrockまたはAzure OpenAIを使用している管理者は、Anthropic ClaudeまたはOpenAI GPTモデルも設定できます。

## 統合されたDevOpsとセキュリティ

### Advanced SASTにおけるC/C++サポートが正式リリース（GA）

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/sast/advanced_sast_cpp.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/18369)

{{< /details >}}

GitLab Advanced SASTにおけるC/C++のクロスファイル・クロスファンクションスキャンサポートが正式リリース（GA）となりました。

### 複数コンテナスキャン

<!-- categories: Container Scanning -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/container_scanning/multi_container_scanning.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/3139)

{{< /details >}}

GitLab 18.8では、複数コンテナスキャンをベータ版としてリリースしました。

ユーザーは、多くのコンテナスキャンジョブの一部としてスキャンするイメージの配列を渡せるようになりました。

### グループオーナー向け一元化された認証情報管理API

<!-- categories: System Access -->

{{< details >}}

- プラン: Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/groups.md#credentials-inventory-management) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16343)

{{< /details >}}

認証情報インベントリAPIがGitLab.comのエンタープライズユーザー向けに利用可能になりました。これにより、以前はセルフホストインスタンスでのみ利用可能だった認証情報管理機能が追加され、組織が認証トークンとキーをより適切に管理・保護できるようになります。

認証情報インベントリAPIは、以下を含む組織全体の認証情報をプログラムでアクセスして表示する機能を提供します。

- パーソナルアクセストークン（PAT）
- グループアクセストークン（GrAT）
- プロジェクトアクセストークン（PrAT）
- SSHキー
- GPGキー

このAPIは既存の認証情報インベントリUIを補完し、エンタープライズ管理者が以前は手動介入が必要だった認証情報管理タスクを自動化できるようにします。認証情報インベントリAPIを使用すると、以下が可能になります。

- セキュリティワークフローの自動化: 認証情報の監視、監査、失効を行う自動化プロセスを構築します。
- 認証情報ポリシーの適用: 未使用または期限切れのトークンを特定して失効させます。
- セキュリティ対策状況の改善: 定期的な監査を通じて認証情報の不正使用リスクを低減します。
- 運用の効率化: 認証情報管理を既存のセキュリティツールとワークフローに統合します。

### グループオーナーがエンタープライズユーザーのSSHキーを無効化可能に

<!-- categories: System Access -->

{{< details >}}

- プラン: Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/ssh_advanced.md#disable-ssh-keys-for-enterprise-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/30343)

{{< /details >}}

グループオーナーは、グループ内のすべてのエンタープライズユーザーのSSHキーを無効化できるようになりました。無効化すると、ユーザーは新しいSSHキーを追加できなくなり、既存のキーは無効化されます。これは、オーナーロールを持つユーザーを含む、グループ内のすべてのエンタープライズユーザーに適用されます。

この機能の構築にご協力いただいた[Wesley Yarde](https://gitlab.com/WYarde)さんに感謝します！

### GitLab Runner 18.8

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.8もリリースします！GitLab Runnerは、CI/CDジョブを実行してGitLabインスタンスに結果を送り返す、高いスケーラビリティを持つビルドエージェントです。GitLab RunnerはGitLab CI/CDと連携して動作します。GitLab CI/CDはGitLabに含まれるオープンソースの継続的インテグレーションサービスです。

#### 新機能

- [ジョブ入力補間エラーのエラーメッセージを改善](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39163)

#### バグ修正

- [`WaitForServicesTimeout`がタイムアウトを無効化する`-1`をサポートしなくなった](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39172)
- [カスタムURLが`insteadOf`ルールでサブモジュール認証を破壊する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39170)
- [Windows 2025のカスタムRunnerショートトークンが8文字ではなく9文字を使用する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39122)
- [GitLab Runner 17.8.3のDockerエグゼキューターでPowerShellデフォルトヘルパーイメージが見つからない](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/38669)
- [Docker AutoscalerのGitLab Runnerが利用可能なキャッシュボリュームを再利用しない](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37906)
- [ジョブがキャンセルされるとVirtualBoxがVMを残したままにする](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37344)

すべての変更のリストは、GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-8-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-8-stable/CHANGELOG.md).md)にあります。

## 関連トピック

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.8)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.8)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.8)
- [非推奨と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
