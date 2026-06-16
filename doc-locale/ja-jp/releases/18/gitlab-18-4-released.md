---
stage: Release Notes
group: Monthly Release
date: 2025-09-18
title: "GitLab 18.4リリースノート"
description: "GitLab 18.4、GitLab Duoモデル選択の一般提供を開始"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年9月18日に、GitLab 18.4が次の機能とともにリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Patrick Rice {#this-months-notable-contributor-patrick-rice}

Patrick Riceは、GitLabのオープンソースコミュニティに対するコントリビューター、メンテナー、メンターとしての並外れた献身を続けています。この1年間で[トップ5のコントリビューター](https://contributors.gitlab.com/leaderboard?fromDate=2025-01-01&toDate=2025-09-18&search=&communityOnly=true)であるPatrickは、[GitLab Terraform Provider](https://gitlab.com/gitlab-org/terraform-provider-gitlab)と[client-go](https://gitlab.com/gitlab-org/api/client-go)のプロジェクトを維持管理し、機能追加、リリース、イシュートリアージ、コミュニティオンボーディングを担当しています。彼は、コントリビューターからプロジェクトメンテナーへと昇り詰めることで、誰もがコントリビュートできるというGitLabのミッションを体現しています。

Patrickの影響は、codeのコントリビュートに留まらず、コミュニティ構築やコーチングにも及び、新しいコントリビューターがプロジェクトに参加し成長するのを支援しています。Patrickは以前、[17.11 Notable Contributor award](https://about.gitlab.com/releases/2025/04/17/gitlab-17-11-released/#notable-contributor)を受賞したHeidi Berryを推薦し、支援しました。彼はまた、次世代のデベロッパーの育成を支援するため、GitLabを学ぶ学生たちとの連携について[GitLab for Education](https://about.gitlab.com/solutions/education/)チームとインサイトを共有しました。

「新しいコントリビューターがTerraform Providerとclient-goプロジェクトでのコラボレーションに参加してくれることを願っています」とPatrickは言います。「私たちのコミュニティには、いつでももっと多くのフレンドリーな顔ぶれが必要です。」

「PatrickはGitLabチームと顧客を絶えず支援し続けています」と、Patrickをこの賞に推薦したGitLabのスタッフフルスタックエンジニアである[Lee Tickett](https://gitlab.com/leetickett-gitlab)は述べています。GitLabのシニアバックエンドエンジニアである[Timo Furrer](https://gitlab.com/timofurrer)が、その推薦を支持しました。「Terraform Providerとclient-goへの日々のコントリビュートとは別に、彼はGitLab Terraform Providerで何ができるかを示すことで、GitLabのお客様のIaCの道のりを直接支援しています」とTimoは付け加えます。

PatrickはKinglandのエンタープライズアーキテクトであり、[GitLab Community Core Team](https://about.gitlab.com/community/core-team/)のメンバーです。これは彼の2度目のNotable Contributor賞であり、[以前は2023年1月にGitLab 15.8で受賞](https://about.gitlab.com/releases/2023/01/22/gitlab-15-8-released/#mvp)しています。

GitLabのお客様をサポートし、オープンソースコミュニティを成長させるための、Patrickの継続的なコントリビュートと献身に感謝いたします！

## 主要な機能 {#primary-features}

### GitLab Duoモデル選択の一般提供を開始 {#gitlab-duo-model-selection-now-generally-available}

<!-- categories: Model Personalization -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18818)

{{< /details >}}

GitLab Duoモデル選択が一般提供開始となり、組織は、開発ワークフローを動かすAIモデルをより細かく制御できるようになりました。

GitLab.comのトップレベルグループのオーナーと、Self-ManagedおよびDedicatedの管理者は、GitLabがホストするAIゲートウェイを通じてアクセスするGitLab Duo機能で使用する特定のモデルを、さまざまなGitLab AIベンダーのモデルから選択できるようになりました。

GitLab.com上の複数のネームスペースに属するGitLabユーザーは、すべての開発コンテキストで一貫したAIモデルの環境設定を確実にするために、デフォルトネームスペースを設定することもできるようになりました。GitLab Duoモデル選択の詳細については、[ブログをご覧ください](https://about.gitlab.com/blog/speed-meets-governance-model-selection-comes-to-gitlab-duo/)。

### GitLabナレッジグラフ {#gitlab-knowledge-graph}

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions, Vulnerability Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](https://gitlab-org.gitlab.io/rust/knowledge-graph/) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17514)

{{< /details >}}

GitLabナレッジグラフは、コードベース全体にわたる豊富なコードインテリジェンスを提供します。デベロッパーは、より多くのコンテキストでプロジェクトを理解しナビゲートできるため、変更の計画、影響分析の実行、GitLab Duoエージェントとの連携による開発タスクの加速が容易になります。

GitLab Duo Agent Platformは、Knowledge Graphを活用してAIエージェントの精度を高めます。コードベース全体でファイルと定義をマッピングすることで、Knowledge Graphは、Duoエージェントがローカルワークスペース全体の関係を理解できるような強化されたコンテキストを提供し、複雑な質問に対するより迅速で正確な回答を可能にします。

Knowledge Graphの今回のリリースは、ローカルcodeインデックス作成に焦点を当てており、CLIがコードベースをRAG用のライブの埋め込みグラフデータベースに変換します。簡単なワンラインスクリプトでインストールでき、ローカルリポジトリを解析し、MCP経由で接続してワークスペースをクエリすることができます。

Knowledge Graphプロジェクトの私たちのビジョンは2つあります。1つは、デベロッパーが今日ローカルで実行できる活気あるコミュニティエディションを構築すること。もう1つは、それが将来的にGitLab.comとSelf-Managedインスタンス内で完全に統合されたKnowledge Graph Serviceの基盤となることです。

この機能はベータ版です。[イシュー160](https://gitlab.com/gitlab-org/rust/knowledge-graph/-/issues/160)でフィードバックをお寄せください。

### GitLab Duoでエンドユーザーのモデル選択が可能に {#end-user-model-selection-now-available-with-gitlab-duo}

<!-- categories: Model Personalization -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19251)

{{< /details >}}

エンドユーザー向けのGitLab Duoモデル選択が、GitLab.comでパブリックベータ版として利用可能になりました。ユーザーは、GitLab Duo Agentic Chatで好みのモデルをGitLab UIで直接選択できるようになり、デベロッパーはAIアシスタンスエクスペリエンスをパーソナライズして制御できます。

GitLab.comのネームスペースのオーナーによって許可されている場合、エンドユーザーは、利用可能なGitLab AIベンダーのモデルから選択して、GitLab Duo Agentic Chatで使用できます。ネームスペースのオーナーは、ネームスペース設定を通じて組織全体のモデル設定を引き続き行ったり、エンドユーザーのモデル選択を許可したりできます。

始めるには、GitLab Duo Agentic Chatのモデルドロップダウンで希望のモデルを選択してください。モデルを変更すると、新しい会話が開始され、設定は今後のセッションで記憶されることに注意してください。

### CI/CDジョブトークンでGitプッシュリクエストを認証できるように {#cicd-job-tokens-can-authenticate-git-push-requests}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../ci/jobs/ci_job_token.md#allow-git-push-requests-to-your-project-repository) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/389060)

{{< /details >}}

プロジェクトで生成されたCI/CDジョブトークンで、プロジェクトのリポジトリへのGitプッシュリクエストを認証できるようになりました。UIのジョブトークン権限設定でこれを有効にするか、プロジェクトのREST APIエンドポイントで`[ci_push_repository_for_job_token_allowed](../../api/projects.md#edit-a-project)`パラメータを使用します。

### GitLab Duoのコンテキスト除外 {#gitlab-duo-context-exclusion}

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions, Vulnerability Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/context.md#exclude-context-from-code-review) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17124)

{{< /details >}}

GitLab Duoのコンテキスト除外により、どのプロジェクトコンテンツをGitLab Duoのコンテキストとして除外するかを制御できます。これは、パスワードファイルや設定ファイルなどの機密情報を保護するのに役立ちます。個別のファイル、特定のディレクトリ、特定のファイルタイプ、またはそれらを組み合わせたものを除外することができます。

この機能は現在ベータ版です。[イシュー566244](https://gitlab.com/gitlab-org/gitlab/-/issues/566244)でGitLab Duoのコンテキスト除外に関するフィードバックをお寄せください。

### GitLab DedicatedのAWSリージョンサポートを展開 {#expanded-aws-region-support-for-gitlab-dedicated}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/dedicated/create_instance/data_residency_high_availability.md#supported-regions)

{{< /details >}}

GitLab Dedicatedは、すべてのAWSリージョンへのデプロイをサポートするようになり、プライマリ、セカンダリ、およびバックアップのデプロイ場所として[拡張されたリージョンリスト](../../administration/dedicated/create_instance/data_residency_high_availability.md#supported-regions)から選択できるようになりました。

この展開は、すべてのリージョンにおけるAWSのio2ディスクのロールアウトによって可能になり、これはGitLab Dedicatedの高可用性とディザスターリカバリーの標準を満たしています。

新しく利用可能なすべてのリージョンは、スイッチボードでGitLab Dedicatedインスタンスをプロビジョニングする際に選択できます。

### 異なるブランチに対するCI/CDパイプラインのシミュレート {#simulate-cicd-pipelines-against-different-branch}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../ci/pipeline_editor/_index.md#validate-cicd-configuration) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/482676)

{{< /details >}}

これまで、パイプラインエディタを使用し、検証タブで変更を検証する場合、デフォルトブランチのシミュレーションしか実行できませんでした。このリリースでは、この機能を拡張しました。任意のブランチを選択してパイプラインをシミュレートできるようになりました。この改善により、パイプラインのテストと検証の柔軟性が向上します。安定したブランチやフィーチャーブランチなど、さまざまなケースで期待どおりに動作することを確認できます。

## エージェント型コア {#agentic-core}

### グループとアプリケーション向けの自動Duoコードレビュー {#automatic-duo-code-review-for-groups-and-applications}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/merge_requests/duo_in_merge_requests.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)

{{< /details >}}

グループまたはアプリケーションの設定を使用して、複数のプロジェクトで自動Duoコードレビューを有効にできるようになりました。これにより、特定のプロジェクトを個別に有効にするのではなく、グループ内のすべてのプロジェクトでDuoコードレビューを迅速に有効にできます。

この機能は現在GitLab.comで利用可能であり、今後のリリースでGitLab Self-Managedでも利用できるようにする予定です。[イシュー517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)でフィードバックをお寄せください。

### GitLab Duo Self-Hostedの追加サポートモデル {#additional-supported-models-for-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16742)

{{< /details >}}

GitLab Self-Managedのお客様は、GitLab Duo Enterpriseを使用することで、GitLab Duoで追加のサポートモデルを利用できるようになりました。OpenAI GPT-5は、Azure OpenAIでサポートされるようになりました。オープンソースのOpenAI GPT OSS 20Bおよび120Bも、vLLMとAzure OpenAIでサポートされるようになりました。これらのモデルをGitLab Duo Self-Hostedで使用することに関するフィードバックは、[イシュー523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918)をご覧ください。

### GitLab Duo Self-HostedのDuoコードレビューが一般提供開始 {#duo-code-review-on-gitlab-duo-self-hosted-is-generally-available}

<!-- categories: Code Suggestions, Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/_index.md#gitlab-duo) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/548975)

{{< /details >}}

GitLab Duo Self-HostedのGitLab Duoコードレビューが一般提供開始となりました。データ主権を損なうことなく開発プロセスを加速するために、GitLab Duo Self-HostedでGitLab Duoコードレビューを使用してください。GitLab DuoコードレビューがMRをレビューする際、潜在的なバグを特定し、直接適用できる改善策を提案します。人間がレビューを依頼する前に、GitLab Duoコードレビューを使用して変更をイテレーションし、改善してください。この機能は、Mistral、Meta Llama、Anthropic Claude、およびOpenAI GPTの各モデルファミリーをサポートしています。

GitLab Duoコードレビューに関するフィードバックは、[イシュー517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)でお寄せください。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### パイプラインのシークレット検出が、デフォルトで特定のファイルとディレクトリを除外するように {#pipeline-secret-detection-now-excludes-certain-files-and-directories-by-default}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/secret_detection/pipeline/_index.md#excluded-items) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/560147)

{{< /details >}}

パイプラインのシークレット検出は、シークレットを含む可能性が低い[特定のファイルタイプとディレクトリ](../../user/application_security/secret_detection/pipeline/_index.md#excluded-items)を自動的に除外し、スキャンパフォーマンスを向上させます。これらの変更は、アナライザー[バージョン7.11.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.11.0)でリリースされています。

### シークレット検出アナライザーのGitフェッチの改善 {#secret-detection-analyzer-git-fetching-improvements}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/secret_detection/pipeline/_index.md#how-the-analyzer-fetches-commits) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17315)

{{< /details >}}

シークレット検出アナライザーのバージョン[7.12.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v[7.12.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.12.0))では、Gitコミットのフェッチ方法が大幅に改善されました。アナライザーは、`SECRET_DETECTION_LOG_OPTIONS`から渡される`--depth`および`--since`オプションを解析するようになり、スキャンするコミット数をさらに指定できます。アナライザーはまた、コンテキストに基づいて適切なフェッチ戦略を選択します。これにより、シャローデプス設定であっても、潜在的に数百万ものコミットが不必要にフェッチされる既知のイシューが防止されます。

この強化により、ジョブタイムアウトが短縮され、リソース消費が削減され、より予測可能なスキャンパフォーマンスが提供されます。大規模なリポジトリでは特に、実際のフェッチ動作に一致するより明確なロギングにより、より高速なシークレット検出スキャンを体験できます。

### 大幅に高速化された高度なSASTスキャン {#significantly-faster-advanced-sast-scanning}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16561)

{{< /details >}}

マージリクエストやパイプラインでセキュリティスキャンを有効にする場合、1分1秒が重要です。私たちは、エンジンと検出ルールの両方を対象とした高度なSASTのパフォーマンス改善を定期的に出荷しています。

今回のリリースでは、ベンチマークおよび実世界テストでスキャンランタイムを最大78%短縮する具体的な改善点に焦点を当てています。スキャンプロセスのパフォーマンスに影響する部分にキャッシュを追加したことで、大規模なリポジトリでのスキャンが大幅に高速化されました。

この改善は、高度なSASTアナライザーバージョン2.9.6以降で自動的に有効になります。[スキャンジョブログを確認する](../../user/application_security/sast/gitlab_advanced_sast.md)ことで、使用しているアナライザーバージョンを確認できます。

### 運用コンテナスキャンの重大度しきい値設定 {#operational-container-scanning-severity-threshold-configuration}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/clusters/agent/vulnerabilities.md#configure-trivy-severity-threshold-filter) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/559278)

{{< /details >}}

運用コンテナスキャン (OCS) を設定して、特定の重大度レベル以上の脆弱性のみを返すことができるようになりました。重大度しきい値を設定すると、選択した重大度を下回る脆弱性は、脆弱性レポート、APIペイロード、およびその他の報告メカニズムで返されなくなります。これにより、修正したい脆弱性に集中できます。

このフィルタリングを有効にするには、OCS設定で[`severity_threshold`を設定します](../../user/clusters/agent/vulnerabilities.md#configure-trivy-severity-threshold-filter)。

[John Walsh](https://gitlab.com/mjohnw)からのこのコミュニティコントリビュートに心から感謝いたします。GitLabへのコントリビュートについて詳しく知るには、[コミュニティコントリビュートプログラム](https://about.gitlab.com/community/contribute/)を確認してください。

### OpenTofuモジュールとプロバイダーをCI/CDテンプレートでGitLabコンテナレジストリに公開 {#publish-opentofu-modules-and-providers-to-the-gitlab-container-registry-with-cicd-templates}

<!-- categories: Infrastructure as Code -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](https://gitlab.com/components/opentofu#publish-providers-to-the-gitlab-oci-registry) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/562715)

{{< /details >}}

GitLabコンテナレジストリが、OpenTofuモジュールとプロバイダーをホストするためのメディアタイプをサポートするようになりました。

[OpenTofu CI/CDコンポーネント](https://gitlab.com/components/opentofu)のバージョン[3.1.0](https://gitlab.com/components/opentofu/-/releases/[3.1.0](https://gitlab.com/components/opentofu/-/releases/3.1.0))は、`provider-release`テンプレートをサポートしており、OCI形式を使用してOpenTofuプロバイダーをGitLabレジストリにデプロイできます。これで、GitLabでプライベートなOpenTofuプロバイダーを直接ホストできます。

さらに、`module-release`テンプレートは、OCI形式を使用してGitLabレジストリにOpenTofuモジュールをデプロイするために、`type`入力を`oci`に設定できる新しい入力をサポートするようになりました。

### プレースホルダーを再割り当てする際のエンタープライズユーザーの確認をバイパス {#bypass-confirmation-for-enterprise-users-when-reassigning-placeholders}

<!-- categories: Importers -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/import/mapping/reassignment.md#bypass-confirmation-when-reassigning-placeholder-users) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17871)

{{< /details >}}

グループのオーナーロールを持つユーザーは、そのグループのアクティブなエンタープライズユーザーにプレースホルダーを再割り当てする際に、ユーザー確認をバイパスできるようになりました。これにより、エンタープライズユーザーは再割り当てを確認するためにメールを常にチェックし続ける必要がありません。設定の制限時間に達すると、すべての新しい再割り当てに対してメール確認リクエストが再び送信されます。

再割り当て完了後もエンタープライズユーザーには通知メールが送信され、プロセス全体の透明性が確保されます。

### イシューページからイシューを表示する方法を設定 {#configure-how-to-view-issues-from-the-issues-page}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/issues/managing_issues.md#open-issues-in-a-panel) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/570776)

{{< /details >}}

リストページビューを完全に制御し、表示されるメタデータや、作業アイテムをドロワーで開くかどうかを選択できるため、最も重要な情報に集中しやすくなります。

以前は、すべてのメタデータフィールドが常に表示レベルで、作業アイテムをスキャンするのが大変でした。現在、割り当て、ラベル、日付、マイルストーンなどの特定のフィールドをオンまたはオフに切替えることで、ビューをカスタマイズできます。

新しい切替により、ドロワービューとフルページナビゲーションを切り替えることで、リストのコンテキストを維持しながら詳細を迅速にレビューしたり、詳細な編集や包括的なナビゲーションのために広い画面スペースが必要なときにフルページを開いたりすることができます。

### エピックおよびイシューリストの親フィルタリングを強化 {#enhanced-parent-filtering-for-epic-and-issue-lists}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/issues/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/556200)

{{< /details >}}

イシューページとエピックページにあった「エピック」フィルターを、より柔軟な「親」フィルターに置き換えました。この変更により、エピックだけでなく、任意の親作業アイテムでフィルターできるようになります。親イシューでフィルターして子タスクを簡単に見つけたり、親エピックでフィルターしてイシューを見つけたりできるようになり、イシューとエピックの両方のリストで作業階層の表示レベルが向上します。

### イシューボードに完全なエピック階層が表示されるように {#issue-boards-now-show-complete-epic-hierarchies}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/issue_board.md#filter-issues) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/358416)

{{< /details >}}

イシューボードで親エピックによってフィルターすると、子エピックのすべてのイシューを表示できるようになり、イシューページがすでに機能している方法との一貫性がもたらされます。この改善により、子エピックにネストされたイシューを見落とすことなく、完全なエピック階層をよりよく追跡し視覚化できるようになり、プロジェクト管理ワークフローがより効率的で信頼性の高いものになります。

### テキストエディタのツールバーの同等性 {#text-editors-toolbar-parity}

<!-- categories: Markdown -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/rich_text_editor.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/507377)

{{< /details >}}

GitLabのプレーンテキストエディタが、リッチテキストエディタと同じ書式設定オプションを含むようになりました。プレーンテキストエディタのツールバーは、「その他のオプション」メニューで更新され、次のような高度な書式設定ツールにアクセスできるようになりました:

- コードブロック
- 詳細ブロック
- 水平線
- Mermaidダイアグラム
- PlantUMLダイアグラム
- 目次

両方のエディタでボタンの配置と区切りが統一され、使い慣れた書式設定オプションへのアクセスを維持しながら編集モードを切り替えるのが容易になりました。

### 脆弱性の詳細に自動解決パイプラインIDを表示 {#vulnerability-details-shows-the-auto-resolve-pipeline-id}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/vulnerability_management_policy.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/566392)

{{< /details >}}

自動的に解決され、その後再検出された脆弱性をトラブルシューティングする場合、現在のパイプラインを脆弱性が解決されたパイプラインと比較することが役立つ場合があります。

脆弱性が自動的に解決された場合、脆弱性詳細ページの脆弱性ノートに、それが検出されたパイプラインIDが含まれるようになりました。

### ジョブアーティファクトをダウンロードできるユーザーの制御を強化 {#enhanced-controls-for-who-can-download-job-artifacts}

<!-- categories: Artifact Security -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../ci/yaml/_index.md#artifactsaccess) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/454398)

{{< /details >}}

GitLab 16.11では、`artifacts:access`キーワードを追加しました。これにより、ユーザーは、パイプラインへのアクセス権を持つすべてのユーザー、デベロッパーロール以上のユーザーのみ、またはどのユーザーもアーティファクトをダウンロードできるかどうかを制御できます。

今回のリリースでは、アーティファクトをダウンロードできるユーザーをメンテナーロール以上のみに制限できるようになり、ジョブアーティファクトをダウンロードできるユーザーを制御するためのもう1つの選択肢が提供されます。

### GitLab Runner 18.4 {#gitlab-runner-184}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.4もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### バグ修正 {#bug-fixes}

- [FIPS RunnerがGitLab Runner 18.2.1でジョブの開始に失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38963)
- [カスタムConfigMapおよびセキュリティコンテキスト制約 (SCC) を持つRunner向けの`chown`コマンドが、OpenShift 4.16.27でのOperator v1.37.0アップグレード後に失敗する](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/246)
- [17.2での早期削除のため、GitLab 17.x.xリリースで`FF_RETRIEVE_POD_WARNING_EVENTS`を復活させる](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38851)
- [すべてのGitLab Runnerジョブがファイルシステム権限エラーにより失敗する](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/214)
- [ビルドジョブが権限拒否エラーで散発的に失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37464)
- [GitLab Runner Helmチャートのアップグレードにより変数が壊れる](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30851)
- [`FF_USE_FASTZIP`を有効にしてもfastzipが有効にならない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28989)
- [GitLab Runnerが、ワンタイムリクエストで作成されたSpotインスタンスを停止しようとすると`UnsupportedOperation`エラーが発生する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28865)
- [GitLab Runnerのロングポーリングが、Kubernetesがデプロイされた環境で適切に機能しない](https://gitlab.com/gitlab-org/gitlab/-/issues/331460)
- [管理者がimage:Kubernetes:userの値をオーバーライドできるようにする](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38894)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-4-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-4-stable/CHANGELOG.md).md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.4)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.4)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.4)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
