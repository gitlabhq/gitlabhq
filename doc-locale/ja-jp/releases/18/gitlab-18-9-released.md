---
stage: Release Notes
group: Monthly Release
date: 2026-02-19
title: "GitLab 18.9リリースノート"
description: "GitLab 18.9は、GitLab Duo Agent Platformのセルフホストモデルがクラウドライセンスで利用可能になりリリースされました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2026年2月19日に、GitLab 18.9が次の機能を備えてリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Pooja Ghanghas {#this-months-notable-contributor-pooja-ghanghas}

Poojaは、GitLabにおけるレガシーなドロップダウンコンポーネントを最新のドロップダウンアーキテクチャに移行するという継続的な取り組みに大きくコントリビュートしてきました。これらの移行には、細部への注意と、古いコンポーネントシステムと新しいコンポーネントシステムの両方への理解が必要です。Poojaは、複数の移行にわたり一貫して高品質な作業を提供してきました。これには、[diff file header](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189621) 、[code block bubble menu](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194129) 、[oncall schedules rotation assignee component](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186247) 、[new resource dropdown](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209598)へのアップデートが含まれます。

[Peter Hegman](https://gitlab.com/peterhegman)氏（GitLabテナントスケール組織部門スタッフフロントエンドエンジニア）は、Poojaをこの表彰に推薦し、次のように述べました: 「これらの移行はかなり厄介なものになることがありますが、彼女は多くの移行を完了させました。コントリビュートしていただきありがとうございます！」

これらの移行の取り組みに加えて、Poojaは機能開発にもコントリビュートしており、[adding statuses to milestones and iterations](https://gitlab.com/gitlab-org/gitlab/-/issues/524100)を含みます。これは彼女がマージさせるために多大な努力を払った機能です。[Marc Saleiko](https://gitlab.com/msaleiko)氏（GitLab Plan:Project Management部門スタッフフルスタックエンジニア）は、彼女の仕事について次のように評価しました: 「これは貴重なコントリビュートであり、この機能を優れた方法で提供しました！」自身の経験を振り返り、Poojaは次のように述べました: 「結果に満足しており、私にとって素晴らしい学習経験となりました。」

彼女はまた、GitLabのコードベース全体にわたって、数多くのバグ修正とメンテナンスの改善にもコントリビュートしてきました。Poojaの作業は、GitLabUIの保守性と一貫性を直接改善し、コントリビューターとチームメンバーの両方にとって機能の構築と維持を容易にし、GitLabフロントエンドアーキテクチャの前進に貢献しています。

Poojaさん、GitLabのコードベースの改善への継続的なコントリビュート、そしてコントリビューターコミュニティの信頼できるメンバーであることに感謝します！

Poojaのコントリビュートについて詳しく知りたいですか？彼女の[GitLab profile](https://gitlab.com/poojaghanghas479)をご覧ください。

## 主要な機能 {#primary-features}

### クラウドライセンスでGitLab Duo Agent Platformのセルフホストモデルが利用可能に {#gitlab-duo-agent-platform-self-hosted-models-now-available-for-cloud-licenses}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/_index.md#gitLab-duo-agent-platform) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20949)

{{< /details >}}

GitLab Duo Agent Platformは、クラウドライセンスを持つGitLab Self-Managedのお客様が一般利用できるようになりました。この機能の請求は[使用量ベース](../../subscriptions/gitlab_credits.md)です。

管理者は、GitLab Duo Agent Platformで使用するための[互換性のあるモデル](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models)を設定することができます。AWS BedrockまたはAzure OpenAIを使用する管理者は、Anthropic ClaudeまたはOpenAI GPTモデルも設定することができます。

Ultimateプランをまだご利用でないですか？[無料トライアルにDuo Agent Platformが含まれています。](https://docs.gitlab.com/#gitlab-duo-agent-platform-available-in-ultimate-trials)

### 脆弱性の修正 (GitLab Duo Agent Platform) (ベータ) {#vulnerability-resolution-with-gitlab-duo-agent-platform-beta}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/duo_agent_platform/flows/foundational_flows/agentic_sast_vulnerability_resolution.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20150)

{{< /details >}}

SAST脆弱性のトリアージと修正は、アプリケーションセキュリティにおいて最も時間のかかるタスクの1つです。実際の脆弱性を特定した後、開発者はその発見を理解し、影響を受けるコードを特定し、適切な修正を記述する必要があります。これらのすべてに時間と専門知識が必要です。GitLab 18.9では、エージェント型SAST脆弱性の修正を導入します。SAST脆弱性の修正をトリガーすると、GitLab Duoは自動的に発見を分析し、周囲のコードのコンテキストを推論し、コンテキスト認識型修正を生成し、手動介入なしにマージリクエストを作成します。

主な機能は次のとおりです:

- エージェント型の多段階修正: 単一のコード提案を生成するのではなく、GitLab Duo Agent Platformは脆弱性を推論し、コードベースを評価し、情報に基づいた修正を生成します。
- 自動マージリクエスト作成: 重大および高重大度のSAST脆弱性に対して、提案されたコード修正を含む、すぐにレビューできるマージリクエストを生成します。
- 品質スコアリング: 生成された各修正には品質評価が含まれており、レビュアーは提案された修正への信頼度を迅速に評価できます。

SAST脆弱性の修正は、脆弱性レポートおよび個別の脆弱性詳細ページから利用できます。個別の脆弱性詳細ページから直接トリガーすることができます。

この機能は、Ultimateのお客様向けにFreeベータ版として利用できます。[issue 585626](https://gitlab.com/gitlab-org/gitlab/-/work_items/585626)で皆様のフィードバックをお待ちしております。

### 折りたたみ可能なファイルツリーでリポジトリをナビゲート {#navigate-repositories-with-collapsible-file-tree}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/repository/files/file_tree_browser.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17781)

{{< /details >}}

折りたたみ可能なファイルツリーでリポジトリファイルを閲覧できるようになりました。このツリーはプロジェクト構造の包括的なビューを提供するため、ディレクトリをインラインで展開したり折りたたむしたり、リポジトリの異なる部分のファイル間を移動したり、作業中にコンテキストを維持したりできます。

リポジトリファイルまたはディレクトリを表示すると、ファイルツリーがサイズ変更可能なサイドバーとして表示されます。キーボードショートカットで表示レベルを切り替える、ファイル名または拡張子でファイルをフィルタリングする、複雑なプロジェクト階層をナビゲートすることができます。ツリーは現在の場所と同期するため、メインコンテンツ領域でファイルを選択すると、ツリーはそのファイルを表示するように更新されます。

既存のリポジトリ構造とファイル編成は変更されません。ファイル間の移動に必要なページロードが少なくなるため、この機能は小規模なプロジェクトから数千のファイルを抱える大規模なコードベースまでスケールします。

### ファイルからCI/CDインプットを含める {#include-cicd-inputs-from-a-file}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/inputs/_index.md#define-pipeline-inputs-in-external-files) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/415636)

{{< /details >}}

以前は、パイプラインの入力はパイプラインのスペックセクション内で直接定義することしかできませんでした。この制限により、複数のプロジェクト間で入力設定を再利用することが困難でした。

このリリースでは、おなじみの`include`キーワードを使用して、外部ファイルから入力定義を含めることができるようになりました。入力リストを別の場所で管理できることで、多くのプロジェクトやパイプラインにわたって管理しやすいソリューションを持つことができます。一元化された入力設定を維持し、外部ソースから入力値を動的に管理することもできます。

### GitLab.comでのWebベースのコミット署名 {#web-based-commit-signing-on-gitlabcom}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/signed_commits/web_commits.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/17775)

{{< /details >}}

コミットが暗号学的に署名されていることを確認することは、コードの整合性を保ち、コンプライアンス要件を満たす上で不可欠です。以前は、Webベースのコミット署名はGitLab Self-Managedでのみ利用可能でした。

GitLab.comはWebベースのコミット署名に対応しました。グループまたはプロジェクトで有効にすると、GitLab Webインターフェースを通じて作成されたコミットは、GitLab署名キーで自動的に署名され、**検証済み**バッジとともに表示され、リポジトリの暗号学的な信頼性証明を提供します。

主な詳細:

- 要件に基づいてグループまたはプロジェクトの設定で有効にします。
- すべてのWebベースのコミット（Web IDEの編集、マージ、API操作）は、有効にすると自動的に署名されます。

これにより、GitLab.comのセキュリティ機能がGitLab Self-Managedと連携し、組織全体の包括的なコミット署名ポリシーの基盤が提供されます。

### コンテナ仮想レジストリが利用可能になりました (ベータ) {#container-virtual-registry-now-available-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/packages/virtual_registry/container/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20820)

{{< /details >}}

現代のコンテナベースの開発では、Docker Hub、Harbor、Quay、プライベートレジストリなど、複数のレジストリからイメージにアクセスする必要があります。仮想レジストリがない場合、プラットフォームエンジニアは各プロジェクトとCI/CDパイプラインを個別に複数のレジストリに認証するように設定する必要があります。これにより、設定の複雑さが増し、連続的なレジストリクエリによるプルが遅くなり、コンテナソース全体で一貫したセキュリティポリシーを実装することが困難になります。

コンテナ仮想レジストリは、複数のアップストリームコンテナレジストリを単一のエンドポイントの背後で集約することにより、これらの課題に対処します。プラットフォームエンジニアは、Docker Hub、Harbor、Quay、その他のレジストリを、単一のURLを通じて有効期間の長いトークン認証で設定することができます。インテリジェントなキャッシュはプルパフォーマンスを向上させるとともに、GitLab認証システムと統合して一元化されたアクセス制御と監査ログを提供します。

コンテナ仮想レジストリAPIは現在、GitLab PremiumおよびUltimateのお客様向けにベータ版で利用可能です。ベータ版参加者は、[GitLab API](../../api/container_virtual_registries.md)を使用してコンテナ仮想レジストリを作成し、共有可能な設定で複数のアップストリームソースを設定することができます。また、仮想レジストリを通じてコンテナイメージをプルできます。ベータ版では、IAM認証を必要とするレジストリはサポートされていないことに注意してください。IAM認証を必要とするクラウドプロバイダーレジストリのサポートは、[このエピック](https://gitlab.com/groups/gitlab-org/-/work_items/20919)で追跡されています。

GitLab.comでは、この機能は機能フラグの背後にあります。アクセスをリクエストしたり、フィードバックを共有したりするには、[feedback issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/589630)にコメントしてください。

### 新しいセキュリティダッシュボードチャート: 経過時間ごとの脆弱性 {#new-security-dashboard-chart-vulnerabilities-by-age}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md#vulnerabilities-by-age) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/17417)

{{< /details >}}

新しい**経過時間ごとの脆弱性**チャートは、環境内で脆弱性がどのくらい開かれているかを理解するのに役立ちます。

このチャートは、最初に検出されてからの時間に基づいて、未解決の脆弱性の分布を示します。重大度またはレポートタイプ別に脆弱性をグループ化して、修正アクティビティが必要な場所を特定できます。

## エージェント型コア {#agentic-core}

### JetBrains IDEでのSelf-ManagedおよびDedicated向けOAuthサポート {#oauth-support-in-jetbrains-ides-for-self-managed-and-dedicated}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](https://docs.gitlab.com/editor_extensions/jetbrains_ide/setup/#authenticate-with-gitlab) | [関連イシュー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/1337)

{{< /details >}}

JetBrains IDE向けのGitLab Duoプラグインは、GitLab Self-ManagedおよびGitLab Dedicated向けのOAuth認証をサポートするようになりました。これにより、すべてのJetBrainsユーザーがより速く、より安全なサインインエクスペリエンスを享受できるようになります。パーソナルアクセストークンは不要です。

## 規模とデプロイ {#scale-and-deployments}

### 非請求対象の最小アクセスユーザー {#non-billable-minimal-access-users}

<!-- categories: Seat Cost Management -->

{{< details >}}

- プラン: Premium
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../user/permissions.md#users-with-minimal-access) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/584275)

{{< /details >}}

以前は、Identity Providerを使用してGitLab Self-Managed Premiumでのユーザープロビジョニングを自動化する組織は、潜在的な問題に直面する可能性がありました。Identity Providerの同期がライセンスされたシート制限を超えるユーザーを追加しようとすると、管理者は、アクティブなアクセスを必要としないユーザーのために追加のシートを購入するか、手動で介入して失敗を防ぐ必要があります。

現在、GitLab Self-Managed Premiumサブスクリプションの最小アクセスロールを持つユーザーは、請求対象シートとしてカウントされなくなり、GitLab.comPremium、GitLab.comUltimate、およびGitLab Self-Managed Ultimateでの最小アクセスの機能に合致するようになりました。この変更により、[制限付きアクセス](../../administration/settings/sign_up_restrictions.md#restricted-access)機能がアンロックされ、Identity Providerの同期中にシート制限を超えるユーザーに最小アクセスロールが自動的に割り当てられます。この変更により、予期しない課金超過や手動介入なしに同期がスムーズに実行されます。

### プライマリサイトでのGeoデータ管理ビュー {#geo-data-management-view-on-primary-site}

<!-- categories: Disaster Recovery, Geo Replication -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../administration/admin_area.md#data-management)

{{< /details >}}

新しいデータ管理ビューにより、詳細な検証ステータス情報がプライマリGeoサイトにもたらされ、プライマリサイトから直接データ整合性のトラブルシューティングを行うおよび検証ができるようになりました。この強化により、基本的な検証やトラブルシューティングタスクのためにセカンダリサイトにアクセスする必要がなくなります。

以前は、この検証ステータスはセカンダリサイトUIからのみアクセス可能でした。現在、プライマリサイトのデータ管理ビューでは、次のことができます:

- プライマリサイト上のすべてのレプリケーション可能なデータ型に対する詳細な検証ステータスを表示
- プライマリUIから直接データサニタイズおよびトラブルシューティングタスクを実行
- セカンダリサイトを追加する前に、プライマリサイトでGeo設定をセットアップおよび検証する

この強化は、UIを使用した包括的なセルフサービストラブルシューティングへの第一歩であり、ルーチンのメンテナンスやイシュー解決のために複数のサイトにアクセスする必要性を低減します。

### GitLab Duo Agent PlatformがUltimateトライアルで利用可能に {#gitlab-duo-agent-platform-available-in-ultimate-trials}

<!-- categories: Acquisition, Duo Agent Platform -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../subscriptions/free_trials.md#gitlab-duo-agent-platform-trials) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20353)

{{< /details >}}

GitLabを評価しているチームは、複雑な開発ワークフローを自動化し、手動タスクを削減するエージェント型AI機能をテストできるようになりました。GitLab Ultimateトライアルにサインアップすると、ユーザーあたり24の評価クレジット付きでDuo Agent Platformにアクセスでき、30日間の評価期間中に自律的なタスク実行と多段階ワークフローのオーケストレーションを体験できます。評価クレジットはプロビジョニング日から30日間有効です。開始前にチームの準備状況を考慮してください。

[無料トライアルを開始する](https://gitlab.com/-/trial_registrations/new)。現在の有料顧客は、アカウントチームを通じて評価クレジットにアクセスできます。詳細については、[営業担当者にお問い合わせください](https://about.gitlab.com/sales/)。

### クラウドネイティブハイブリッドデプロイでゼロダウンタイムアップグレードがサポートされました {#zero-downtime-upgrades-now-supported-for-cloud-native-hybrid-deployments}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](https://docs.gitlab.com/charts/installation/upgrade/#upgrade-with-zero-downtime)

{{< /details >}}

ゼロダウンタイムアップグレードは、クラウドネイティブハイブリッドデプロイで正式にサポートされました。

エンタープライズ顧客は、DevSecOpsプラットフォームが常に利用可能であることを要求しており、アップグレードに関連するダウンタイムは運用上の大きな懸念事項です。これまで、ゼロダウンタイムアップグレードはLinuxパッケージベースの高可用性デプロイのみでサポートされており、クラウドネイティブKubernetesデプロイの方がインフラ戦略に適している場合でも、多くのお客様がVMベースのアーキテクチャを選択していました。

当社は長年、独自のクラウドネイティブハイブリッドSaaSインスタンスをゼロダウンタイムでアップグレードしてきました。このリリースにより、Kubernetes上でGitLabを実行するSelf-Managedのお客様に同じ運用体験を提供します。

アップグレード手順は徹底的にテストされ、完全に文書化されているため、バージョンアップグレード中も可用性を維持する自信を持っていただけます。

### グループとそのコンテンツをアーカイブする {#archive-a-group-and-its-content}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/group/manage.md#archive-a-group) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15019)

{{< /details >}}

完了したイニシアチブと放棄されたプロジェクトの管理が容易になりました。すべてのサブグループとプロジェクトを含むグループ全体を1つのアクションでアーカイブできるようになり、各プロジェクトを個別に手動でアーカイブする必要がなくなりました。

グループをアーカイブすると:

- すべてのネストされたサブグループとプロジェクトは自動的にアーカイブされます。
- アーカイブされたコンテンツは、明確なステータスバッジとともに**非アクティブ**タブに移動します。
- グループデータは、参照または復元のために読み取り専用モードで完全にアクセス可能です。
- アーカイブされたグループとそのコンテンツ全体で書き込み権限が無効になります。

**設定**ページを超えて、リストビューのアクションメニューから直接グループとプロジェクトをアーカイブできます。単純な管理タスクのために複数の画面をナビゲートする必要はありません。この非常に要望の多かった機能は、管理上のオーバーヘッドを劇的に削減し、アクティブな作業と非アクティブな作業を明確に区別してワークスペースを整理します。[epic 18616](https://gitlab.com/groups/gitlab-org/-/epics/18616)で皆様のフィードバックを共有してください。

### Redisの代替オプションとしてのValkey (ベータ) {#valkey-as-replacement-option-for-redis-beta}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/redis/_index.md#use-valkey-instead-of-redis)

{{< /details >}}

GitLab 18.9から、ValkeyはLinuxパッケージ内のRedisのオプトイン代替品としてバンドルされています。RedisはライセンスをAGPLv3に変更しましたが、これはオープンソースの顧客には適していません。GitLab Self-Managedのお客様のセキュリティと保守性を保証するため、当社はRedisからValkeyへ移行しています。Valkeyは、許諾されたBSDライセンスを維持するコミュニティ主導のフォークです。

移行タイムライン:

- GitLab 18.9（このリリース）: Valkeyはオプトインの代替品としてバンドルされています（ベータ版）。都合の良いときにRedisからValkeyに切り替えることができます。Valkey Sentinelのサポートが含まれています。
- GitLab 19.0（2026年5月）: Valkeyがデフォルトになり、RedisバイナリはLinuxパッケージから削除されます。既存のRedis設定設定は引き続き機能し、後方互換性のために尊重されます。

この移行は、Linuxパッケージ内のバンドルされたRedisのみに影響します。外部Redisデプロイを使用するスケールされたアーキテクチャの顧客は、引き続きRedisを使用できます。RedisとValkey間の潜在的な機能の相違をモニタリングしており、エコシステムが進化するにつれてガイダンスを提供します。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### Java pom.xmlマニフェストファイルのSBOMサポート付き依存関係スキャン {#dependency-scanning-with-sbom-support-for-java-pomxml-manifest-files}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#manifest-fallback) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/585886)

{{< /details >}}

GitLab [依存関係スキャン（SBOMを使用）](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md)は、Java `pom.xml`マニフェストファイルのスキャンをサポートするようになりました。以前は、Mavenを使用するJavaプロジェクトの依存関係スキャンには、グラフファイルが存在する必要がありました。現在、グラフファイルが利用できない場合、アナライザーは自動的に`pom.xml`ファイルをスキャンするフォールバックし、脆弱性分析のために直接的な依存関係のみを抽出し報告します。この改善により、Javaプロジェクトはグラフファイルを必要とせずに依存関係スキャンを有効にするのが容易になります。

マニフェストフォールバックを有効にするには、`DS_ENABLE_MANIFEST_FALLBACK`CI/CD変数を`"true"`に設定します。

### Python requirements.txtマニフェストファイルのSBOMサポート付き依存関係スキャン {#dependency-scanning-with-sbom-support-for-python-requirementstxt-manifest-files}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#manifest-fallback) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/586921)

{{< /details >}}

GitLab [依存関係スキャン（SBOMを使用）](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md)は、Python `requirements.txt`マニフェストファイルのスキャンをサポートするようになりました。以前は、Pythonプロジェクトの依存関係スキャンにはロックファイルが存在する必要がありました。現在、ロックファイルが利用できない場合、アナライザーは自動的に`requirements.txt`ファイルをスキャンするフォールバックし、脆弱性分析のために直接的な依存関係のみを抽出報告します。この改善により、Pythonプロジェクトはロックファイルを必要とせずに依存関係スキャンを有効にするのが容易になります。

マニフェストフォールバックを有効にするには、`DS_ENABLE_MANIFEST_FALLBACK`CI/CD変数を`"true"`に設定します。

### エンタープライズユーザーの個人のスニペットを制限する {#restrict-personal-snippets-for-enterprise-users}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/manage.md#restrict-personal-snippets-for-enterprise-users)

{{< /details >}}

GitLab.comを使用する組織は、エンタープライズユーザーがスニペットを通じて機密コードを誤って公開しないようにする必要があります。以前は、ユーザーが個人のネームスペースにスニペットを作成することを防ぐ方法がなく、スニペットが誤って公開に設定された場合、セキュリティリスクとなる可能性がありました。

グループオーナーは、エンタープライズユーザーによるスニペットの作成を制限できるようになり、コードが共有される場所に対するより厳格な制御を維持するのに役立ちます。制限されている場合、エンタープライズユーザーは個人のネームスペースにスニペットを作成できません。

### Rapid Diffsはコミット変更のパフォーマンスを向上させる {#rapid-diffs-improves-performance-for-commit-changes}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/repository/commits/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/17804)

{{< /details >}}

多くの変更されたファイルや大幅な変更を含むコミットのレビューは遅くなることがあります。Rapid Diffsテクノロジーは現在、コミットページ（`/-/commits/<SHA>`）を強化し、より速い読み込み時間、スムーズなスクロール、そしてより応答性の高いインタラクションを提供します。

Rapid Diffsを使用すると、次の点が改善されます:

- ページネーション不要のエクスペリエンス。
- 初期読み込みが高速化され、より早くコードを操作し始めることができます。
- 新しいファイルブラウザを備えた刷新されたインターフェースで、ファイル間の迅速なナビゲーションが可能になります。
- 多数の変更されたファイルでも応答性の高いインタラクション。

既存のすべての機能は維持されます。Rapid DiffsがGitLabの他の領域に拡大するにつれて、同じパフォーマンス上の利点がもたらされます。

### Bitbucket CloudAPIトークンのインポートAPIサポート {#support-for-bitbucket-cloud-api-tokens-in-import-api}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../api/import.md#import-repository-from-bitbucket-cloud)

{{< /details >}}

GitLabインポートAPIは、Bitbucket CloudAPIトークンをサポートするようになり、Bitbucket Cloudからリポジトリをインポートするより安全な方法を提供します。

[Atlassianはアプリパスワードを非推奨としました](https://www.atlassian.com/blog/bitbucket/bitbucket-cloud-transitions-to-api-tokens-enhancing-security-with-app-password-deprecation)（APIトークンを推奨）が、GitLabでは19.0でアプリパスワードのサポートを削除する予定です。

Bitbucket CloudからGitLab UIを介したインポートは、この変更の影響を受けません。

### 一元化されたセキュリティガバナンスと設定 {#centralized-security-governance-and-configuration}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/configuration/security_configuration_profiles.md)

{{< /details >}}

組織全体でセキュリティスキャナーのカバレッジを管理および可視化します。このリリースでは、シークレット検出プロファイルから始まるセキュリティ設定プロファイルが導入されます。セキュリティチームは、組織を大規模に保護するための、より強力なコマンドセンターを手に入れました。

**Profile-based security configuration**

各プロジェクトのYAMLファイルを手動で編集する代わりに、いくつかの利点を提供する事前設定済みのセキュリティ設定プロファイルを使用できるようになりました:

- 標準化されたガバナンス: 事前設定済みプロファイルは、生産性を中断することなく適切な境界を適用します。標準化されたセキュリティのベストプラクティスを、カスタムロール設定を必要とせずに適用できます。
- スケーラブルな管理: 何百、何千ものプロジェクトに同じプロファイルを単一のアクションで適用します。

シークレット検出プロファイルは、利用可能な最初のセキュリティ設定プロファイルです。次の利点があります:

- シークレットがリポジトリにコミットされるのを積極的に識別し、ブロックします。
- 1つのプロファイルで開発ワークフロー全体のシークレット検出を管理します。異なるトリガータイプごとに個別の設定を管理する必要はありません。

**Enhanced security inventory**

セキュリティインベントリは、各グループのセキュリティ対策状況を評価するための主要なダッシュボードとして機能するようにアップグレードされました:

- グループとプロジェクトの階層: 明確なアイコン表示により、インベントリ内のサブグループとプロジェクトを簡単に区別できます。
- 一括アクション: 新しい**Bulk Action**メニューを使用すると、選択したすべてのプロジェクトとサブグループにセキュリティスキャナープロファイルを同時に適用または無効にすることができます。
- ビジュアルカバレッジステータス: 色分けされたステータスバー（有効、無効、または失敗）と詳細なツールチップで、ギャップを迅速に特定します。
- プロファイルステータスインジケーター: プロファイルの詳細でどのトリガータイプが利用可能かを確認します。

### セキュリティ属性 {#security-attributes}

<!-- categories: Security Asset Inventories -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/attributes/_index.md)

{{< /details >}}

セキュリティ属性は、[GitLab 18.6でベータ版として導入](gitlab-18-6-released.md#security-attributes-beta)され、一般に利用可能になりました。

セキュリティ属性により、セキュリティチームはビジネスへの影響、アプリケーション、ビジネスユニット、インターネットへの露出、場所など、ビジネスコンテキストをプロジェクトに適用できます。組織の分類法に一致するカスタム属性カテゴリを作成することもできます。これらの属性を適用することで、リスク状況と組織のコンテキストに基づいてセキュリティインベントリ内の項目をフィルタリングし、優先順位を付けることができます。

### セキュリティダッシュボード: 時間経過による脆弱性の推移チャートの改善 {#security-dashboards-vulnerabilities-over-time-chart-improvements}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md#vulnerabilities-over-time) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/19780)

{{< /details >}}

**時間経過による脆弱性の推移**チャートは、脆弱性インベントリのより正確なビューを提供するために更新されました。

このチャートは以前、もはや検出されていない脆弱性を含んでおり、アクティブな脆弱性の状態を正確に表さない水増しされた数値につながっていました。

いくつかのケースでカウントをわずかに変更する可能性のある2つの追加のイシューを認識しています。アップデートについては、[issue 590022](https://gitlab.com/gitlab-org/gitlab/-/issues/590022)および[issue 590018](https://gitlab.com/gitlab-org/gitlab/-/issues/590018)をフォローしてください。

### プロジェクトのCI/CDジョブメトリクスを表示（利用可能範囲が限定されています） {#view-cicd-job-metrics-for-projects-limited-availability}

<!-- categories: Fleet Visibility -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/analytics/ci_cd_analytics.md#cicd-job-performance-metrics) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18548)

{{< /details >}}

GitLab CI/CD分析は、CI/CDパイプラインとCI/CDジョブのパフォーマンス動向を組み合わせることで、開発者が非効率的または問題のあるCI/CDジョブを迅速に特定できるようになります。これらの機能はGitLab UIに直接含まれているため、開発者は開発チームの開発速度と全体的な生産性に大きな影響を与える可能性のあるCI/CDパフォーマンスの問題を特定し、修正するために必要なツールをコンテキスト内で手に入れることができます。プラットフォーム管理者にとって、このビューのCI/CDジョブデータは、エンタープライズ規模でGitLabを運用する際に、外部またはカスタム構築のCI/CD可観測性ソリューションに依存する必要性を低減します。

### CIジョブログにタイムスタンプを追加 {#add-timestamps-to-ci-job-logs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/jobs/job_logs.md#timestamps) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/202293)

{{< /details >}}

各CIジョブログ行にタイムスタンプを表示できるようになり、パフォーマンスのボトルネックを特定し、長時間実行されるジョブをデバッグできます。タイムスタンプはUTC形式で表示されます。タイムスタンプを使用して、パフォーマンスの問題のトラブルシューティングを行う、ボトルネックを特定する、特定のビルドステップの期間を測定します。GitLab Self-Managedの場合、GitLab Runner 18.7以降が必要です。

### CI/CDカタログコンポーネントアナリティクス {#cicd-catalog-component-analytics}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/components/_index.md#view-catalog-resource-analytics) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/579458)

{{< /details >}}

以前は、チームは組織全体でCI/CDカタログコンポーネントプロジェクトがどのように使用されているかについての表示レベルが不足していました。これで、使用状況のカウントと採用パターンを高いレベルで表示できるようになり、どのコンポーネントプロジェクトが最も価値があり、カタログ投資を最適化できるかを理解するのに役立ちます。

### マージリクエストで子パイプラインからのセキュリティレポートを表示 {#view-security-reports-from-child-pipelines-in-merge-requests}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/pipelines/downstream_pipelines.md#view-child-pipeline-reports-in-merge-requests) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18377)

{{< /details >}}

子パイプラインからのセキュリティおよびコンプライアンスレポートを、マージリクエストウィジェットで直接表示できるようになりました。以前は、複数のパイプラインを手動でナビゲートしてセキュリティ問題（モノレポや複雑なテスト設定では特に非効率なワークフローを作成していました）を特定する必要がありました。

この強化により、マージリクエストウィジェットは、子パイプラインからのレポートを親パイプラインの結果と並んで直接表示し、各子パイプラインのレポートは個別に提示され、アーティファクトはダウンロード可能になります。これにより、すべてのセキュリティチェックの統合ビューが提供され、失敗の調査に費やす時間が大幅に短縮され、親子パイプラインを使用する際のマージリクエストレビューが高速化されます。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.9)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.9)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.9)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
