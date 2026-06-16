---
stage: Release Notes
group: Monthly Release
date: 2026-01-15
title: "GitLab 18.8リリースノート"
description: "GitLab 18.8がリリースされました。GitLab Duo Agent Platformが一般提供を開始"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2026年1月15日にGitLab 18.8が次の機能を搭載してリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Wesley Yarde {#this-months-notable-contributor-wesley-yarde}

今月の注目すべきコントリビューターは、組織がエンタープライズユーザーのSSHキーを無効にできる基本的な新機能を構築した[Wesley Yarde](https://gitlab.com/WYarde)です。

Wesleyのコントリビュートは、いくつかの理由で際立っています:

- **セキュリティとコンプライアンス**: この機能により、組織はSSHキーの要件を強制し、企業全体のセキュリティを強化できます。
- **Foundational work**: 既存の実装がなかったため、WesleyはGitLabチームと広範囲に協力して、要件とアーキテクチャを一から定義する必要がありました。
- **First contribution**: 注目すべきは、これがWesleyにとってGitLabへの最初のコントリビュートであり、複雑なコードベースを操作し、困難な機能に取り組む並外れた能力を示したことです。
- **Enables future development**: この作業は、インスタンスレベルのSSHキー無効化やサービスアカウント制御などの類似機能の基盤を確立します。

実装は、徹底的なレビューサイクルを持つ複数のマージリクエスト（[!205020](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205020) 、[!210482](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210482)）に及びました。複雑さにもかかわらず、Wesleyはプロセス全体を通して卓越したコラボレーションと忍耐力を示しました。

「この機能リクエストに関してWesleyと協力できたことは、喜びでした！コントリビューターとレビュアーの両方が、レビュープロセスが圧倒的だと感じたかもしれませんが、両者は実装が堅実で完全であることを確実にするために、理解と素晴らしいコラボレーションを示しました。」 — Wesleyをこの表彰に推薦した[Bogdan Denkovych](https://gitlab.com/bdenkovych)。

Wesley、おめでとうございます。GitLabへのこの貴重なコントリビュートに感謝いたします！

## 主要な機能 {#primary-features}

### GitLab Duo Agent Platformが一般提供開始 {#gitlab-duo-agent-platform-now-generally-available}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/585273)

{{< /details >}}

GitLab Duo Agent Platformが一般提供開始され、エージェント型AIオーケストレーションがソフトウェア開発ライフサイクル全体で利用可能になりました。個々のタスクを単独で加速するAIツールとは異なり、エージェントプラットフォームは、プランニング、ビルド、保護、およびソフトウェアの出荷全体でAIエージェントを調整するのに役立ち、より速い個別作業とソフトウエアデリバリーの共同的で多段階的な現実との間のギャップを埋めます。

このプラットフォームは、チームが組織全体でAIカタログを見つけ、管理し、エージェントとフローを共有できる中央AIカタログを提供します。プランナー、セキュリティ分析エージェント、データアナリストなどの組み込み基本エージェントは、主要な決定ポイントで構造化された作業を処理し、カスタマイズ可能なフローは、イシューからマージリクエスト、CI/CDの移行、パイプラインのトラブルシューティング、コードレビューに至る開発ワークフローにおける多段階のエージェントとタスクを自動化します。

ガバナンス制御、使用表示レベル、およびオフライン環境用のセルフホストモデルを含む柔軟なデプロイオプションにより、組織は必要な透明性と制御をもってAIをスケールして採用できます。

PremiumおよびUltimateのユーザーは、本日よりGitLab.comおよびSelf-Managedインスタンスで[GitLabクレジット](../../subscriptions/gitlab_credits.md)を使用してエージェントプラットフォームの使用を開始できます。

### GitLab Duoプランナーエージェントが一般提供開始 {#gitlab-duo-planner-agent-now-generally-available}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/planner.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/583008)

{{< /details >}}

プランナーエージェントが一般提供開始されました！プランナーエージェントは、GitLabでプロダクトマネージャーを直接サポートするために構築された基本エージェントです。

プランナーエージェントを使用して、GitLab作業アイテムを作成、編集、分析します。手動で更新を追跡したり、作業の優先順位を付けたり、計画データを要約したりする代わりに、プランナーエージェントは、バックログの分析、RICEやMoSCoWのようなフレームワークの適用、そして本当に注意を必要とするものを表面化するのに役立ちます。これは、あなたのプランニングワークフローを理解し、より良く、より効率的な意思決定を行うために協力してくれる、積極的なチームメイトがいるようなものです。

フィードバックを[issue 583008](https://gitlab.com/gitlab-org/gitlab/-/work_items/583008)にご提供ください。

### GitLab Duoセキュリティ分析エージェントが一般提供開始 {#gitlab-duo-security-analyst-agent-now-generally-available}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/security_analyst_agent.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

GitLab Duoセキュリティ分析エージェントは、[ベータ版としてGitLab 18.5で導入](https://about.gitlab.com/releases/2025/10/16/gitlab-18-5-released/#gitlab-security-analyst-agent-for-duo-agent-catalog-beta)され、GitLab 18.8で一般提供開始されました。

セキュリティ分析エージェントを使用すると、エンジニアはGitLab Duo Agentic Chatで自然言語コマンドを通じて脆弱性を管理できます。脆弱性ダッシュボードを手動でクリックしたり、一括操作のためにカスタムスクリプトを記述したりする代わりに、セキュリティチームはチャットの会話で脆弱性をトリアージ、評価し、ガイダンスを提供できるようになりました。

基本エージェントとして、セキュリティ分析エージェントはGitLab Duo Agentic Chatでデフォルトで利用可能であり、手動設定は不要です。

### 関連性のない脆弱性を脆弱性管理ポリシーで自動却下 {#auto-dismiss-irrelevant-vulnerabilities-with-vulnerability-management-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/policies/vulnerability_management_policy.md#auto-dismiss-policies) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10894)

{{< /details >}}

セキュリティチームは、脆弱性管理ポリシーを使用して、組織に適用されない脆弱性を自動的に無視することができるようになりました。組織に関連のない脆弱性を無視することで、ノイズが減り、開発者は実際の危険をもたらす脆弱性に集中できます。

脆弱性を自動却下するためのポリシーを、以下に基づいて作成できます:

- ファイルパス
- ディレクトリ
- 識別子 (CVE、CWE、またはOWASP)

自動却下された脆弱性は、マージリクエストのセキュリティウィジェットに**Auto-dismissed**というラベル付きで表示され、監査目的の却下理由とともに脆弱性レポートのアクティビティで追跡されます。

## エージェント型コア {#agentic-core}

### GitLab Duo Agent Platformの有効化または無効化 {#turn-the-gitlab-duo-agent-platform-on-or-off}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-agent-platform-on-or-off) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/583980)

{{< /details >}}

GitLab Duo Agent Platformを、GitLab Duo Chat（エージェント型）、エージェント、およびフローを含め、トップレベルグループまたはインスタンス全体で有効または無効にできるようになりました。この設定が無効になっている場合、これらの機能は利用できません。

### GitLab Duo機能のグループアクセス制御 {#group-access-control-for-gitlab-duo-features}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../administration/gitlab_duo/configure/access_control.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/585355)

{{< /details >}}

グループアクセスルールを定義して、GitLab Duo機能を使用できるユーザーを制御できるようになりました。これにより、即時の組織全体でのアクセスから段階的なロールアウトまで、柔軟な導入戦略が可能になります。

この機能はきめ細かいガバナンス制御を提供するため、セキュリティとコンプライアンスを維持しながら、自身のペースで導入をスケールすることができます。

### GitLab Duo Agent Platform for GitLab Duo Self-Hosted (オフラインライセンス) が一般提供開始 {#gitlab-duo-agent-platform-for-gitlab-duo-self-hosted-offline-licensing-now-generally-available}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/19125)

{{< /details >}}

GitLab Duo Agent PlatformがDuo Self-Hosted向けに一般提供開始されました。この機能は、オフラインライセンスを持つGitLab Self-Managedのお客様が利用でき、シートベースの価格設定を使用します。

Self-Managedの管理者は、GitLab Duo Agent Platformで使用する[compatible models](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models)を設定できます。AWS BedrockまたはAzure OpenAIを使用する管理者は、Anthropic ClaudeまたはOpenAI GPTモデルも設定することができます。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### C/C++サポートが高度なSASTで一般提供開始 {#cc-support-in-advanced-sast-now-generally-available}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/sast/advanced_sast_cpp.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/18369)

{{< /details >}}

クロスファイル、クロスファンクションのスキャンサポートが、GitLab高度なSASTでC/C++向けに一般提供開始されました。

### 複数のコンテナスキャン {#multiple-container-scanning}

<!-- categories: Container Scanning -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/container_scanning/multi_container_scanning.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/3139)

{{< /details >}}

GitLab 18.8で、マルチコンテナスキャンのベータ版をリリースしました。

ユーザーは、多くのコンテナスキャンジョブの一部として、スキャンされる画像の配列を渡せるようになりました。

### グループオーナー向けの一元化された認証情報管理API {#centralized-credential-management-api-for-group-owners}

<!-- categories: System Access -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/groups.md#credentials-inventory-management) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16343)

{{< /details >}}

認証情報インベントリAPIが、GitLab.comのエンタープライズユーザー向けに利用可能になりました。これにより、以前はセルフホストインスタンスでのみ利用可能だった認証情報管理機能が追加され、組織は認証トークンとキーをより適切に管理し、保護できるようになります。

認証情報インベントリAPIは、組織全体で認証情報を表示するためのプログラムによるアクセスを提供します。これには以下が含まれます:

- パーソナルアクセストークン (PAT)
- グループアクセストークン (GrATs)
- プロジェクトアクセストークン (PrATs)
- SSHキー
- GPGキー

このAPIは、既存の認証情報インベントリUIを補完し、エンタープライズ管理者が以前は手動での介入が必要だった認証情報管理タスクを自動化できるようにします。認証情報インベントリAPIを使用すると、次のことができます:

- セキュリティワークフローを自動化: 構築されたプロセスで、認証情報を監視、監査、および失効する。
- 認証情報ポリシーを適用: 未使用または期限切れのトークンを特定し、失効する。
- セキュリティ対策状況を改善: 定期的な監査を通じて、認証情報の誤用リスクを軽減します。
- 操作を効率化: 認証情報管理を既存のセキュリティツールとワークフローに統合します。

### グループオーナーはエンタープライズユーザーのSSHキーを無効にできます {#group-owners-can-disable-ssh-keys-for-enterprise-users}

<!-- categories: System Access -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/ssh_advanced.md#disable-ssh-keys-for-enterprise-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/30343)

{{< /details >}}

グループオーナーは、グループ内のすべてのエンタープライズユーザーのSSHキーを無効にできるようになりました。無効にすると、ユーザーは新しいSSHキーを追加できなくなり、既存のキーは非アクティブ化されます。これは、オーナーロールを持つユーザーを含む、グループ内のすべてのエンタープライズユーザーに適用されます。

この機能の構築にご協力いただいた[Wesley Yarde](https://gitlab.com/WYarde)に感謝いたします！

### GitLab Runner 18.8 {#gitlab-runner-188}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.8もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [ジョブインプットの補間エラーに関するエラーメッセージを改善](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39163)

#### バグ修正 {#bug-fixes}

- [`WaitForServicesTimeout`でタイムアウトを無効にするための`-1`のサポートを終了](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39172)
- [カスタムURLにより`insteadOf`ルールを使用したサブモジュール認証が機能しなくなる](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39170)
- [Windows 2025のカスタムRunnerでショートトークンが8文字ではなく9文字として扱われる](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39122)
- [GitLab Runner 17.8.3でDocker executor用のPowerShellのデフォルトヘルパーイメージが見つからない](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/38669)
- [Docker Autoscalerを使用するGitLab Runnerが利用可能なキャッシュボリュームを再利用しない](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37906)
- [ジョブがキャンセルされた際にVirtualBoxのVMが削除されずに残る](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37344)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-8-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-8-stable/CHANGELOG.md).md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.8)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.8)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.8)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
