---
stage: Release Notes
group: Monthly Release
date: 2026-02-19
title: "GitLab 18.9 リリースノート"
description: "GitLab 18.9がリリースされました。クラウドライセンス向けGitLab Duo Agent Platformセルフホストモデルが利用可能になりました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2026年2月19日、GitLab 18.9が以下の機能とともにリリースされました。

また、今月の注目コントリビューターをはじめ、すべてのコントリビューターの皆様に感謝申し上げます。

## 今月の注目コントリビューター: Pooja Ghanghas {#this-months-notable-contributor-pooja-ghanghas}

Poojaさんは、GitLabにおけるレガシードロップダウンコンポーネントをモダンなドロップダウンアーキテクチャへ移行する継続的な取り組みに多大な貢献をしています。これらの移行作業には細部への注意と、新旧両方のコンポーネントシステムへの深い理解が求められます。Poojaさんは[差分ファイルヘッダー](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189621)、[コードブロックバブルメニュー](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/194129)、[オンコールスケジュールローテーション担当者コンポーネント](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186247)、[新しいリソースドロップダウン](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209598)など、複数の移行作業にわたって一貫して高品質な成果を届けてきました。

GitLabのTenant Scale::OrganizationsチームのスタッフフロントエンドエンジニアであるPeter Hegmanさん（[peterhegman](https://gitlab.com/peterhegman)）は、Poojaさんをこの表彰に推薦し、次のようにコメントしています。「これらの移行作業はかなり難しいのですが、彼女は数多くの移行を完了させました。コントリビュートしてくれてありがとう！」

移行作業に加え、Poojaさんは[マイルストーンとイテレーションへのステータス追加](https://gitlab.com/gitlab-org/gitlab/-/issues/524100)など機能開発にも貢献しており、マージに向けて多大な努力を注いだ機能です。GitLabのPlan:Project ManagementチームのスタッフフルスタックエンジニアであるMarc Saleikoさん（[msaleiko](https://gitlab.com/msaleiko)）は彼女の功績を称え、「これは価値あるコントリビュートであり、この機能を見事に実装してくれました！」と述べています。自身の経験を振り返り、Poojaさんは「仕上がりを誇りに思っており、素晴らしい学習経験になりました」と語っています。

また、GitLabコードベース全体にわたって多数のバグ修正とメンテナンス改善にも貢献しています。Poojaさんの取り組みは、GitLabユーザーインターフェースの保守性と一貫性を直接向上させ、コントリビューターとチームメンバーの両方が機能を構築・維持しやすくするとともに、GitLabフロントエンドアーキテクチャの前進に貢献しています。

GitLabコードベースの改善への継続的なコントリビュートと、コントリビューターコミュニティの頼れるメンバーとしての活躍に感謝します、Poojaさん！

Poojaさんのコントリビュートについて詳しく知りたい方は、[GitLabプロフィール](https://gitlab.com/poojaghanghas479)をご覧ください。

## 主要機能 {#primary-features}

### クラウドライセンス向けGitLab Duo Agent Platformセルフホストモデルが利用可能に {#gitlab-duo-agent-platform-self-hosted-models-now-available-for-cloud-licenses}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/_index.md#gitLab-duo-agent-platform) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20949)

{{< /details >}}

GitLab Duo Agent Platformが、クラウドライセンスをお持ちのGitLab Self-Managedのお客様向けに正式提供（GA）となりました。この機能の課金は[使用量ベース](../../subscriptions/gitlab_credits.md)です。

管理者はGitLab Duo Agent Platformで使用する[対応モデル](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models)を設定できます。AWS BedrockまたはAzure OpenAIをご利用の管理者は、Anthropic ClaudeまたはOpenAI GPTモデルも設定できます。

Ultimateをまだご利用でない方は、[Duo Agent Platformを含む無料トライアルを開始](https://docs.gitlab.com/#gitlab-duo-agent-platform-available-in-ultimate-trials)してください。

### GitLab Duo Agent Platformによる脆弱性の修正（ベータ版） {#vulnerability-resolution-with-gitlab-duo-agent-platform-beta}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/duo_agent_platform/flows/foundational_flows/agentic_sast_vulnerability_resolution.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20150)

{{< /details >}}

SASTの脆弱性のトリアージと修正は、アプリケーションセキュリティにおいて最も時間のかかる作業の一つです。実際の脆弱性を特定した後、開発者はその内容を理解し、影響を受けるコードを特定して、適切な修正を記述する必要があります。これらすべてに時間と専門知識が必要です。
GitLab 18.9では、エージェント型SAST脆弱性修正を導入します。SAST脆弱性の修正をトリガーすると、GitLab Duoが自律的に検出内容を分析し、周辺のコードコンテキストを推論して、コンテキスト認識型の修正を生成し、手動介入なしにマージリクエストを作成します。

主な機能は以下のとおりです。

- エージェント型マルチステップ修正: 単一のコード提案を生成するのではなく、GitLab Duo Agent Platformが脆弱性を推論し、コードベースを評価して、十分な情報に基づいた修正を生成します。
- マージリクエストの自動作成: 重大度が「Critical」および「High」のSAST脆弱性に対して、提案されたコード修正を含むレビュー可能なマージリクエストを自動生成します。
- 品質スコアリング: 生成された各修正には品質評価が含まれており、レビュアーは提案された修正の信頼度を素早く判断できます。

SAST脆弱性の修正は、脆弱性レポートおよび個別の脆弱性詳細ページから利用できます。個別の脆弱性詳細ページから直接修正をトリガーできます。

この機能はUltimateのお客様向けに無料ベータとして提供されています。[イシュー585626](https://gitlab.com/gitlab-org/gitlab/-/work_items/585626)でフィードバックをお待ちしています。

### 折りたたみ可能なファイルツリーでリポジトリをナビゲート {#navigate-repositories-with-collapsible-file-tree}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/project/repository/files/file_tree_browser.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17781)

{{< /details >}}

折りたたみ可能なファイルツリーでリポジトリのファイルを閲覧できるようになりました。このツリーはプロジェクト構造の包括的なビューを提供し、ディレクトリをインラインで展開・折りたたんだり、リポジトリの異なる場所にあるファイル間を移動したり、作業中のコンテキストを維持したりできます。

ファイルツリーは、リポジトリのファイルやディレクトリを表示する際にサイズ変更可能なサイドバーとして表示されます。キーボードショートカットで表示を切り替えたり、名前や拡張子でファイルをフィルタリングしたり、複雑なプロジェクト階層をナビゲートしたりできます。ツリーは現在の場所と同期しており、メインコンテンツエリアでファイルを選択すると、ツリーが更新されてそのファイルが表示されます。

既存のリポジトリ構造とファイル整理はそのまま維持されます。ファイル間の移動に必要なページ読み込みが減り、この機能は小規模なプロジェクトから数千のファイルを持つ大規模なコードベースまでスケールします。

### ファイルからCI/CDインプットをインクルードする {#include-cicd-inputs-from-a-file}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../ci/inputs/_index.md#define-pipeline-inputs-in-external-files) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/415636)

{{< /details >}}

以前は、パイプラインのインプットはパイプラインのspecセクション内に直接定義するしかありませんでした。この制限により、複数のプロジェクト間でインプット設定を再利用することが困難でした。

このリリースでは、使い慣れた`include`キーワードを使用して外部ファイルからインプット定義をインクルードできるようになりました。インプットのリストを別の場所で管理できるため、多数のプロジェクトやパイプラインにわたって管理しやすいソリューションを実現できます。集中管理されたインプット設定を維持し、外部ソースからインプット値を動的に管理することも可能です。

### GitLab.comでのWebベースのコミット署名 {#web-based-commit-signing-on-gitlabcom}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/signed_commits/web_commits.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/17775)

{{< /details >}}

コミットが暗号学的に署名されていることを確認することは、コードの整合性を保ちコンプライアンス要件を満たすために不可欠です。以前は、WebベースのコミットはGitLab Self-Managedでのみ利用可能でした。

GitLab.comでもWebベースのコミット署名がサポートされるようになりました。グループまたはプロジェクトで有効にすると、GitLab Webインターフェースを通じて作成されたコミットは自動的にGitLab署名キーで署名され、**検証済み**バッジとともに表示されます。これにより、リポジトリの真正性を暗号学的に証明できます。

主な詳細:

- 要件に応じてグループまたはプロジェクトの設定で有効化できます。
- 有効にすると、すべてのWebベースのコミット（Web IDEの編集、マージ、API操作）が自動的に署名されます。

これにより、GitLab.comのセキュリティ機能がGitLab Self-Managedと同等になり、組織全体での包括的なコミット署名ポリシーの基盤が整います。

### コンテナ仮想レジストリが利用可能に（ベータ版） {#container-virtual-registry-now-available-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/packages/virtual_registry/container/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20820)

{{< /details >}}

モダンなコンテナベースの開発では、Docker Hub、Harbor、Quay、プライベートレジストリなど複数のレジストリからイメージにアクセスする必要があります。コンテナ仮想レジストリがない場合、プラットフォームエンジニアは各プロジェクトとCI/CDパイプラインを個別に設定して、複数のレジストリに対して認証とプルを行う必要があります。これにより設定が複雑になり、順次レジストリクエリによってプルが遅くなり、コンテナソース全体で一貫したセキュリティポリシーを実装することが困難になります。

コンテナ仮想レジストリは、複数のアップストリームコンテナレジストリを単一のエンドポイントの背後に集約することでこれらの課題に対処します。プラットフォームエンジニアは、Docker Hub、Harbor、Quayなどのレジストリを1つのURLで長期間有効なトークン認証を使用して設定できます。インテリジェントなキャッシュによりプルのパフォーマンスが向上し、GitLab認証システムとの統合により集中アクセス制御と監査ログが実現します。

コンテナ仮想レジストリAPIは現在、GitLab PremiumおよびUltimateのお客様向けにベータ版として提供されています。ベータ参加者は[GitLab API](../../api/container_virtual_registries.md)を使用して、コンテナ仮想レジストリの作成、共有可能な設定による複数のアップストリームソースの設定、仮想レジストリを通じたコンテナイメージのプルが可能です。なお、ベータ版ではIAM認証が必要なレジストリはサポートされていません。IAM認証が必要なクラウドプロバイダーレジストリのサポートは[このエピック](https://gitlab.com/groups/gitlab-org/-/work_items/20919)で追跡されています。

GitLab.comでは、この機能は機能フラグの背後にあります。アクセスをリクエストするかフィードバックを共有するには、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/589630)にコメントしてください。

### 新しいセキュリティダッシュボードチャート: 経過時間別脆弱性 {#new-security-dashboard-chart-vulnerabilities-by-age}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md#vulnerabilities-by-age) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/17417)

{{< /details >}}

新しい**経過時間別脆弱性**チャートにより、環境内で脆弱性がどのくらいの期間オープンになっているかを把握できます。

このチャートは、最初に検出されてからの経過時間に基づいて未解決の脆弱性の分布を表示します。脆弱性を重大度またはレポートタイプでグループ化でき、修正作業が必要な箇所を特定するのに役立ちます。

## エージェントコア {#agentic-core}

### Self-ManagedおよびDedicated向けJetBrains IDEでのOAuthサポート {#oauth-support-in-jetbrains-ides-for-self-managed-and-dedicated}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](https://docs.gitlab.com/editor_extensions/jetbrains_ide/setup/#authenticate-with-gitlab) | [関連イシュー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/1337)

{{< /details >}}

JetBrains IDE向けGitLab DuoプラグインがGitLab Self-ManagedおよびGitLab DedicatedでのOAuth認証をサポートするようになりました。これにより、すべてのJetBrainsユーザーがより速く、より安全なサインインを利用できます。パーソナルアクセストークンは不要です。

## スケールとデプロイ {#scale-and-deployments}

### 請求対象外の最小アクセスユーザー {#non-billable-minimal-access-users}

<!-- categories: Seat Cost Management -->

{{< details >}}

- プラン: Premium
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../user/permissions.md#users-with-minimal-access) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/584275)

{{< /details >}}

以前は、GitLab Self-Managed PremiumでIdentity Providerを使用してユーザープロビジョニングを自動化している組織で、潜在的な問題が発生する可能性がありました。Identity Providerの同期がライセンスのシート上限を超えてユーザーを追加しようとすると、管理者はアクティブなアクセスを必要としないユーザーのために追加シートを購入するか、手動で介入して失敗を防ぐ必要がありました。

GitLab Self-Managed Premiumサブスクリプションで最小アクセスロールを持つユーザーは、請求対象シートとしてカウントされなくなりました。これにより、GitLab.com Premium、GitLab.com Ultimate、GitLab Self-Managed Ultimateでの最小アクセスの動作と一致します。
この変更により[制限付きアクセス](../../subscriptions/manage_seats.md#restricted-access)機能が有効になります。この機能は、Identity Providerの同期中にシート上限を超えるユーザーに最小アクセスロールを自動的に割り当てます。これにより、予期しない請求超過や手動介入なしに同期がスムーズに実行されます。

### プライマリサイトでのGeoデータ管理ビュー {#geo-data-management-view-on-primary-site}

<!-- categories: Disaster Recovery, Geo Replication -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../administration/admin_area.md#data-management)

{{< /details >}}

プライマリGeoサイトに詳細な検証ステータス情報をもたらす新しいデータ管理ビューにより、プライマリサイトから直接データの整合性をトラブルシューティングおよび検証できるようになりました。この機能強化により、基本的な検証とトラブルシューティングのためにセカンダリサイトにアクセスする必要がなくなります。

以前は、この検証ステータスはセカンダリサイトのUIからのみアクセス可能でした。プライマリサイトのデータ管理ビューにより、以下が可能になります。

- プライマリサイトですべてのレプリケート可能なデータタイプの詳細な検証ステータスを表示する
- プライマリUIから直接データのサニタイズとトラブルシューティングを実行する
- セカンダリサイトを追加する前にプライマリサイトでGeo設定をセットアップして検証する

この機能強化は、UIによる包括的なセルフサービストラブルシューティングに向けた第一歩であり、定期的なメンテナンスと問題解決のために複数のサイトにアクセスする必要性を軽減します。

### GitLab Duo Agent PlatformがUltimateトライアルで利用可能に {#gitlab-duo-agent-platform-available-in-ultimate-trials}

<!-- categories: Acquisition, Duo Agent Platform -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../subscriptions/free_trials.md#gitlab-duo-agent-platform-trials) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20353)

{{< /details >}}

GitLabを評価中のチームは、複雑な開発ワークフローを自動化し手動タスクを削減するエージェント型AI機能をテストできるようになりました。GitLab Ultimateトライアルに申し込むと、ユーザーあたり24評価クレジットのDuo Agent Platformへのアクセスが付与され、30日間の評価期間中に自律的なタスク実行とマルチステップワークフローオーケストレーションを実際に体験できます。評価クレジットはプロビジョニング日から30日間有効ですので、開始前にチームの準備状況をご確認ください。

[無料トライアルを開始する](https://gitlab.com/-/trial_registrations/new)。現在の有料のお客様は、アカウントチームを通じて評価クレジットにアクセスできます。詳細については[営業チームにお問い合わせ](https://about.gitlab.com/sales/)ください。

### Cloud Native HybridデプロイメントでZero Downtime Upgradesがサポートされるように {#zero-downtime-upgrades-now-supported-for-cloud-native-hybrid-deployments}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](https://docs.gitlab.com/charts/installation/upgrade/#upgrade-with-zero-downtime)

{{< /details >}}

Zero Downtime UpgradesがCloud Native Hybridデプロイメントで正式にサポートされるようになりました。

エンタープライズのお客様はDevSecOpsプラットフォームを常時利用可能な状態に保つことを求めており、アップグレードに伴うダウンタイムは重大な運用上の懸念事項です。
これまでZero Downtime Upgradesは、Linuxパッケージベースの高可用性デプロイメントでのみサポートされており、クラウドネイティブKubernetesデプロイメントの方がインフラストラクチャ戦略に適している場合でも、多くのお客様がVMベースのアーキテクチャを選択せざるを得ませんでした。

私たちは自社のCloud Native Hybrid SaaSインスタンスをゼロダウンタイムでアップグレードしてきた実績があります。
このリリースにより、KubernetesでGitLabを運用しているセルフマネージドのお客様にも同じ運用経験を提供します。

アップグレード手順は包括的にテストされ、完全にドキュメント化されており、バージョンアップグレード中も可用性を維持する自信を持って実施できます。

### グループとそのコンテンツをアーカイブする {#archive-a-group-and-its-content}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/group/manage.md#archive-a-group) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15019)

{{< /details >}}

完了したイニシアチブや放棄されたプロジェクトの管理が容易になりました。
サブグループとプロジェクトをすべて含むグループ全体を1つの操作でアーカイブできるようになり、各プロジェクトを個別に手動でアーカイブする必要がなくなりました。

グループをアーカイブすると:

- ネストされたすべてのサブグループとプロジェクトが自動的にアーカイブされます。
- アーカイブされたコンテンツは、明確なステータスバッジとともに**非アクティブ**タブに移動します。
- グループデータは参照または復元のために読み取り専用モードで完全にアクセス可能なままです。
- アーカイブされたグループとそのコンテンツ全体で書き込み権限が無効になります。

**設定**ページ以外にも、リストビューのアクションメニューからグループとプロジェクトを直接アーカイブできます。単純な管理タスクのために複数の画面を移動する必要はもうありません。
この高い要望を受けた機能は、アクティブな作業と非アクティブな作業を明確に分離してワークスペースを整理しながら、管理オーバーヘッドを大幅に削減します。
[エピック18616](https://gitlab.com/groups/gitlab-org/-/epics/18616)でフィードバックをお寄せください。

### RedisのオプションとしてのValkey（ベータ版） {#valkey-as-replacement-option-for-redis-beta}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/redis/_index.md#use-valkey-instead-of-redis)

{{< /details >}}

GitLab 18.9から、ValkeyがLinuxパッケージにRedisのオプトイン代替として同梱されます。
RedisはライセンスをAGPLv3に変更しましたが、これはオープンソースのお客様には適していません。GitLab Self-Managedのお客様のセキュリティと保守性を保証するため、RedisからValkeyへの移行を進めています。ValkeyはBSDライセンスを維持するコミュニティ主導のフォークです。

移行タイムライン:

- GitLab 18.9（今回のリリース）: Valkeyがオプトイン代替（ベータ版）として同梱されます。都合の良いタイミングでRedisからValkeyに切り替えられます。Valkey Sentinelサポートも含まれています。
- GitLab 19.0（2026年5月）: Valkeyがデフォルトになり、RedisバイナリがLinuxパッケージから削除されます。既存のRedis設定は引き続き機能し、後方互換性のために適用されます。

この移行は、Linuxパッケージに同梱されているRedisにのみ影響します。外部Redisデプロイメントを使用するスケールアーキテクチャのお客様は、引き続きRedisを使用できます。
RedisとValkeyの間の潜在的な機能の差異を監視しており、エコシステムの進化に応じてガイダンスを提供します。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### Java pom.xmlマニフェストファイルのSBOMサポートによる依存関係スキャン {#dependency-scanning-with-sbom-support-for-java-pomxml-manifest-files}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#manifest-fallback) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/585886)

{{< /details >}}

GitLabの[SBOMを使用した依存関係スキャン](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md)がJavaの`pom.xml`マニフェストファイルのスキャンをサポートするようになりました。
以前は、Mavenを使用するJavaプロジェクトの依存関係スキャンにはグラフファイルが必要でした。
グラフファイルが利用できない場合、アナライザーは自動的に`pom.xml`ファイルのスキャンにフォールバックし、脆弱性分析のために直接依存関係のみを抽出してレポートします。
この改善により、グラフファイルなしでJavaプロジェクトの依存関係スキャンを有効にしやすくなりました。

マニフェストフォールバックを有効にするには、`DS_ENABLE_MANIFEST_FALLBACK` CI/CD変数を`"true"`に設定してください。

### Python requirements.txtマニフェストファイルのSBOMサポートによる依存関係スキャン {#dependency-scanning-with-sbom-support-for-python-requirementstxt-manifest-files}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#manifest-fallback) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/586921)

{{< /details >}}

GitLabの[SBOMを使用した依存関係スキャン](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md)がPythonの`requirements.txt`マニフェストファイルのスキャンをサポートするようになりました。
以前は、Pythonプロジェクトの依存関係スキャンにはロックファイルが必要でした。
ロックファイルが利用できない場合、アナライザーは自動的に`requirements.txt`ファイルのスキャンにフォールバックし、脆弱性分析のために直接依存関係のみを抽出してレポートします。
この改善により、ロックファイルなしでPythonプロジェクトの依存関係スキャンを有効にしやすくなりました。

マニフェストフォールバックを有効にするには、`DS_ENABLE_MANIFEST_FALLBACK` CI/CD変数を`"true"`に設定してください。

### エンタープライズユーザーのパーソナルスニペットを制限する {#restrict-personal-snippets-for-enterprise-users}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/manage.md#restrict-personal-snippets-for-enterprise-users)

{{< /details >}}

GitLab.comを使用する組織は、エンタープライズユーザーがパーソナルスニペットを通じて機密コードを誤って公開しないようにする必要があります。
以前は、ユーザーがパーソナルネームスペースにスニペットを作成することを防ぐ方法がなく、スニペットが誤ってパブリックに設定された場合にセキュリティリスクとなる可能性がありました。

グループオーナーはエンタープライズユーザーのパーソナルスニペット作成を制限できるようになり、コードが共有される場所をより厳密に管理できます。
制限が有効な場合、エンタープライズユーザーはパーソナルネームスペースにスニペットを作成できません。

### Rapid Diffsによるコミット変更のパフォーマンス向上 {#rapid-diffs-improves-performance-for-commit-changes}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/project/repository/commits/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/17804)

{{< /details >}}

変更ファイルが多いコミットや大規模な変更のレビューは時間がかかることがあります。
Rapid Diffsテクノロジーがコミットページ（`/-/commits/<SHA>`）に適用され、読み込み時間の短縮、スムーズなスクロール、よりレスポンシブなインタラクションを実現します。

Rapid Diffsにより、以下の改善が得られます。

- ページネーションなしの体験。
- 初期読み込みの高速化により、すぐにコードの作業を開始できます。
- ファイル間のナビゲーションを素早く行える新しいファイルブラウザを備えた刷新されたインターフェース。
- 変更ファイルが多い場合でもレスポンシブなインタラクション。

既存のすべての機能は維持されます。Rapid DiffsがGitLabの他の領域に拡張されるにつれ、同じパフォーマンス上のメリットが引き続き提供されます。

### インポートAPIでのBitbucket Cloud APIトークンのサポート {#support-for-bitbucket-cloud-api-tokens-in-import-api}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../api/import.md#import-repository-from-bitbucket-cloud)

{{< /details >}}

GitLabインポートAPIがBitbucket Cloud APIトークンをサポートするようになり、Bitbucket Cloudからリポジトリをインポートするためのより安全な方法が提供されます。

[AtlassianはアプリパスワードをAPIトークンに移行するため非推奨にしており](https://www.atlassian.com/blog/bitbucket/bitbucket-cloud-transitions-to-api-tokens-enhancing-security-with-app-password-deprecation)、19.0ではアプリパスワードのサポートを削除する予定です。

GitLab UIを通じたBitbucket Cloudからのインポートはこの変更の影響を受けません。

### セキュリティガバナンスと設定の一元化 {#centralized-security-governance-and-configuration}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/configuration/security_configuration_profiles.md)

{{< /details >}}

組織全体のセキュリティスキャナーのカバレッジを管理・可視化できます。このリリースでは、シークレット検出プロファイルを皮切りに、セキュリティ設定プロファイルを導入します。
セキュリティチームは、組織をスケールで保護するためのより強力なコマンドセンターを利用できるようになりました。

**プロファイルベースのセキュリティ設定**

各プロジェクトのYAMLファイルを手動で編集する代わりに、いくつかの利点を提供する事前設定済みのセキュリティ設定プロファイルを使用できるようになりました。

- 標準化されたガバナンス: 事前設定済みプロファイルは、生産性を妨げることなく適切な境界を適用します。カスタムロール設定を必要とせずに、標準化されたセキュリティのベストプラクティスを適用できます。
- スケーラブルな管理: 1つのアクションで数百または数千のプロジェクトに同じプロファイルを適用できます。

シークレット検出プロファイルは最初に利用可能なセキュリティ設定プロファイルです。以下の利点があります。

- リポジトリへのシークレットのコミットを積極的に特定してブロックします。
- 1つのプロファイルで開発ワークフロー全体のシークレット検出を管理します。異なるトリガータイプに対して個別の設定を管理する必要はありません。

**強化されたセキュリティインベントリ**

セキュリティインベントリは、各グループのセキュリティ対策状況を評価するための主要なダッシュボードとして機能するようにアップグレードされました。

- グループとプロジェクトの階層: 明確なアイコンでインベントリ内のサブグループとプロジェクトを簡単に区別できます。
- 一括アクション: 新しい**一括アクション**メニューにより、選択したすべてのプロジェクトとサブグループに対してセキュリティスキャナープロファイルを一括で適用または無効化できます。
- 視覚的なカバレッジステータス: 詳細のツールチップとともに、色分けされたステータスバー（有効、未有効、または失敗）でギャップを素早く特定できます。
- プロファイルステータスインジケーター: プロファイルの詳細で利用可能なトリガータイプを確認できます。

### セキュリティ属性 {#security-attributes}

<!-- categories: Security Asset Inventories -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/attributes/_index.md)

{{< /details >}}

[GitLab 18.6でベータ版として導入された](gitlab-18-6-released.md#security-attributes-beta)セキュリティ属性が正式提供（GA）となりました。

セキュリティ属性により、セキュリティチームはビジネスへの影響、アプリケーション、ビジネスユニット、インターネットへの露出、場所などのビジネスコンテキストをプロジェクトに適用できます。組織の分類体系に合わせたカスタム属性カテゴリを作成することもできます。これらの属性を適用することで、リスク対策状況と組織のコンテキストに基づいてセキュリティインベントリのアイテムをフィルタリングおよび優先順位付けできます。

### セキュリティダッシュボード: 経時的な脆弱性チャートの改善 {#security-dashboards-vulnerabilities-over-time-chart-improvements}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md#vulnerabilities-over-time) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/19780)

{{< /details >}}

**経時的な脆弱性**チャートが更新され、脆弱性インベントリのより正確なビューが提供されるようになりました。

以前のチャートには検出されなくなった脆弱性も含まれており、アクティブな脆弱性の状態を正確に反映しない膨らんだ数値が表示されていました。

一部のケースでカウントがわずかに変わる可能性のある2つの追加イシューを認識しています。更新については[イシュー590022](https://gitlab.com/gitlab-org/gitlab/-/issues/590022)と[イシュー590018](https://gitlab.com/gitlab-org/gitlab/-/issues/590018)をフォローしてください。

### プロジェクトのCI/CDジョブメトリクスを表示する（限定提供） {#view-cicd-job-metrics-for-projects-limited-availability}

<!-- categories: Fleet Visibility -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/analytics/ci_cd_analytics.md#cicd-job-performance-metrics) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18548)

{{< /details >}}

GitLab CI/CDアナリティクスがCI/CDパイプラインとCI/CDジョブのパフォーマンストレンドを組み合わせるようになり、開発者が非効率または問題のあるCI/CDジョブを素早く特定できるようになりました。これらの機能はGitLab UIに直接組み込まれているため、開発者は開発チームの速度と全体的な生産性に大きな影響を与えるCI/CDパフォーマンスの問題を特定して修正するためのツールをコンテキスト内で利用できます。プラットフォーム管理者にとっては、このビューのCI/CDジョブデータにより、エンタープライズ規模でGitLabを運用する際に外部またはカスタムビルドのCI/CD可観測性ソリューションへの依存を減らすことができます。

### CIジョブログにタイムスタンプを追加する {#add-timestamps-to-ci-job-logs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../ci/jobs/job_logs.md#timestamps) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/202293)

{{< /details >}}

各CIジョブログ行にタイムスタンプを表示して、パフォーマンスのボトルネックを特定し、長時間実行されているジョブをデバッグできるようになりました。タイムスタンプはUTC形式で表示されます。タイムスタンプを使用してパフォーマンスの問題をトラブルシューティングし、ボトルネックを特定し、特定のビルドステップの所要時間を測定できます。GitLab Self-ManagedではGitLab Runner 18.7以降が必要です。

### CI/CDカタログコンポーネントアナリティクス {#cicd-catalog-component-analytics}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../ci/components/_index.md#view-cicd-catalog-project-analytics) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/579458)

{{< /details >}}

以前は、チームはCI/CDカタログコンポーネントプロジェクトが組織全体でどのように使用されているかを把握する手段がありませんでした。使用数と採用パターンを高レベルで表示できるようになり、どのコンポーネントプロジェクトが最も価値があるかを把握してカタログへの投資を最適化するのに役立ちます。

### マージリクエストで子パイプラインのセキュリティレポートを表示する {#view-security-reports-from-child-pipelines-in-merge-requests}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../ci/pipelines/downstream_pipelines.md#view-child-pipeline-reports-in-merge-requests) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18377)

{{< /details >}}

マージリクエストウィジェットで子パイプラインのセキュリティおよびコンプライアンスレポートを直接表示できるようになりました。以前は、セキュリティの問題を特定するために複数のパイプラインを手動でナビゲートする必要があり、特にモノレポや複雑なテスト設定では非効率なワークフローが生じていました。

この機能強化により、マージリクエストウィジェットが子パイプラインのレポートを親パイプラインの結果と並べて直接表示し、各子パイプラインのレポートが個別に表示され、アーティファクトをダウンロードできます。これにより、すべてのセキュリティチェックの統合ビューが提供され、親子パイプラインを使用する際の障害調査にかかる時間が大幅に削減され、マージリクエストのレビューが迅速化されます。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.9)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.9)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.9)
- [非推奨と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
