---
stage: Release Notes
group: Monthly Release
date: 2025-09-18
title: "GitLab 18.4 リリースノート"
description: "GitLab 18.4がリリースされました。GitLab Duo Model Selectionが一般提供開始"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年9月18日、GitLab 18.4が以下の機能とともにリリースされました。

また、今月の注目コントリビューターをはじめ、すべてのコントリビューターの皆様に感謝申し上げます。

## 今月の注目コントリビューター: Patrick Rice

Patrick Riceは、コントリビューター、メンテナー、メンターとして、GitLabのオープンソースコミュニティへの卓越した貢献を続けています。
過去1年間で[トップ5のコントリビューター](https://contributors.gitlab.com/leaderboard?fromDate=2025-01-01&toDate=2025-09-18&search=&communityOnly=true)として、Patrickは[GitLab Terraform Provider](https://gitlab.com/gitlab-org/terraform-provider-gitlab)と[client-go](https://gitlab.com/gitlab-org/api/client-go)プロジェクトをメンテナンスし、機能追加、リリース、イシューのトリアージ、コミュニティのオンボーディングを担当しています。
コントリビューターからプロジェクトメンテナーへと着実にステップアップしてきた彼は、「誰もがコントリビュートできる」というGitLabのミッションを体現しています。

Patrickの影響はコードのコントリビューションにとどまらず、コミュニティの構築やコーチングにも及んでいます。新しいコントリビューターが参加し、プロジェクト内で成長できるよう支援しています。
Patrickはかつて、[17.11 Notable Contributor賞](https://about.gitlab.com/releases/2025/04/17/gitlab-17-11-released/#notable-contributor)を受賞したHeidi Berryを推薦し、サポートしました。
また、[GitLab for Education](https://about.gitlab.com/solutions/education/)チームに対し、GitLabを学ぶ学生との関わり方についての知見を共有し、次世代の開発者育成に貢献しています。

「Terraform ProviderとClient-goプロジェクトへのコラボレーションに、新しいコントリビューターの皆さんにもぜひ参加していただきたいです」とPatrickは語ります。
「私たちのコミュニティには、いつでも新しい仲間を歓迎しています。」

「Patrickは、GitLabチームとお客様を絶え間なくサポートし続けています」と、Patrickを推薦したGitLabのスタッフフルスタックエンジニアである[Lee Tickett](https://gitlab.com/leetickett-gitlab)は述べています。
GitLabのシニアバックエンドエンジニアである[Timo Furrer](https://gitlab.com/timofurrer)も推薦を支持しました。
「Terraform ProviderとClient-goへの日々のコントリビューションに加え」とTimoは付け加えます。
「GitLab Terraform Providerで何が実現できるかを示すことで、GitLabのお客様のIaCの取り組みを直接支援しています。」

PatrickはKinglandのエンタープライズアーキテクトであり、[GitLab Community Core Team](https://about.gitlab.com/community/core-team/)のメンバーです。
これは彼にとって2度目のNotable Contributor賞であり、2023年1月の[GitLab 15.8での受賞](https://about.gitlab.com/releases/2023/01/22/gitlab-15-8-released/#mvp)に続くものです。

Patrickの継続的なコントリビューションと、GitLabのお客様のサポートおよびオープンソースコミュニティの発展への献身に感謝します！

## 主要機能

### GitLab Duo Model Selectionが一般提供開始 {#gitlab-duo-model-selection-now-generally-available}

<!-- categories: Model Personalization -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18818)

{{< /details >}}

GitLab Duo Model Selectionが一般提供開始となり、組織は開発ワークフローを支えるAIモデルをより細かく制御できるようになりました。

GitLab.comのトップレベルグループのオーナー、およびSelf-ManagedとDedicatedの管理者は、GitLab-hosted AIゲートウェイを通じてアクセスするGitLab Duo機能に使用するモデルを、さまざまなGitLab AIモデルベンダーの中から選択できるようになりました。

GitLab.com上で複数のネームスペースに所属するGitLabユーザーは、デフォルトのネームスペースを設定することで、すべての開発コンテキストにわたって一貫したAIモデルの設定を維持できるようになりました。GitLab Duo Model Selectionの詳細については、[ブログをご覧ください](https://about.gitlab.com/blog/speed-meets-governance-model-selection-comes-to-gitlab-duo/)。

### GitLab Knowledge Graph {#gitlab-knowledge-graph}

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions, Vulnerability Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](https://gitlab-org.gitlab.io/rust/knowledge-graph/) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17514)

{{< /details >}}

GitLab Knowledge Graphは、コードベース全体にわたる豊富なコードインテリジェンスを提供します。開発者はより多くのコンテキストを持ってプロジェクトを理解・ナビゲートできるようになり、変更の計画、影響分析、GitLab Duoエージェントとの連携による開発タスクの加速が容易になります。

GitLab Duo Agent Platformは、Knowledge Graphを活用してAIエージェントの精度を向上させます。コードベース全体のファイルと定義をマッピングすることで、Knowledge GraphはDuoエージェントがローカルワークスペース全体の関係性を理解するための強化されたコンテキストを提供し、複雑な質問に対してより迅速かつ正確な回答を実現します。

今回のKnowledge Graphのリリースでは、ローカルコードのインデックス作成に焦点を当てています。CLIがコードベースをRAG用のライブで埋め込み可能なグラフデータベースに変換します。シンプルなワンラインスクリプトでインストールし、ローカルリポジトリを解析し、MCPを介してワークスペースをクエリできます。

Knowledge Graphプロジェクトのビジョンは二つあります。開発者が今日からローカルで実行できる活発なコミュニティエディションを構築すること、そしてそれをGitLab.comおよびSelf-Managedインスタンス内の将来の完全統合型Knowledge Graph Serviceの基盤とすることです。

この機能はベータ版です。[イシュー160](https://gitlab.com/gitlab-org/rust/knowledge-graph/-/issues/160)でフィードバックをお寄せください。

### GitLab Duoでエンドユーザーによるモデル選択が可能に {#end-user-model-selection-now-available-with-gitlab-duo}

<!-- categories: Model Personalization -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19251)

{{< /details >}}

エンドユーザー向けのGitLab Duoモデル選択機能が、GitLab.comでパブリックベータとして提供開始されました。ユーザーはGitLab UI上でGitLab Duo Agentic Chat用の優先モデルを直接選択できるようになり、開発者はAIアシスタンス体験をパーソナライズして制御できます。

GitLab.comのネームスペースオーナーが許可した場合、エンドユーザーはGitLab Duo Agentic Chatで使用するGitLab AIベンダーモデルを利用可能なものの中から選択できます。ネームスペースオーナーは引き続きネームスペース設定を通じて組織全体のモデル設定を行うか、エンドユーザーによるモデル選択を許可するかを選べます。

開始するには、GitLab Duo Agentic Chatのモデルドロップダウンから優先モデルを選択してください。モデルを変更すると新しい会話が始まり、設定は今後のセッションでも記憶されます。

### CI/CDジョブトークンによるGitプッシュリクエストの認証 {#cicd-job-tokens-can-authenticate-git-push-requests}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../ci/jobs/ci_job_token.md#allow-git-push-requests-to-your-project-repository) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/389060)

{{< /details >}}

プロジェクトで生成されたCI/CDジョブトークンを使用して、そのプロジェクトのリポジトリへのGitプッシュリクエストを認証できるようになりました。
UIのジョブトークン権限設定で有効化するか、プロジェクトのREST APIエンドポイントの`[ci_push_repository_for_job_token_allowed](../../api/projects.md#edit-a-project)`パラメーターを使用して設定できます。

### GitLab Duoコンテキスト除外 {#gitlab-duo-context-exclusion}

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions, Vulnerability Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- アドオン: Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/context.md#exclude-context-from-code-review) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17124)

{{< /details >}}

GitLab Duoコンテキスト除外機能により、GitLab Duoのコンテキストとして除外するプロジェクトコンテンツを制御できます。パスワードファイルや設定ファイルなどの機密情報を保護するのに役立ちます。個別のファイル、特定のディレクトリ、特定のファイルタイプ、またはこれらの組み合わせを除外できます。

この機能は現在ベータ版です。GitLab Duoコンテキスト除外に関するフィードバックは[イシュー566244](https://gitlab.com/gitlab-org/gitlab/-/issues/566244)でお寄せください。

### GitLab DedicatedのAWSリージョンサポートを拡大 {#expanded-aws-region-support-for-gitlab-dedicated}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/dedicated/create_instance/data_residency_high_availability.md#supported-regions)

{{< /details >}}

GitLab DedicatedがすべてのAWSリージョンへのデプロイをサポートするようになりました。プライマリ、セカンダリ、バックアップのデプロイ場所として[拡大されたリージョンリスト](../../administration/dedicated/create_instance/data_residency_high_availability.md#supported-regions)から選択できます。

この拡大は、AWSがすべてのリージョンにio2ディスクを展開したことで実現しました。io2ディスクはGitLab Dedicatedの高可用性とディザスターリカバリーの基準を満たしています。

新たに利用可能になったすべてのリージョンは、SwitchboardでGitLab Dedicatedインスタンスをプロビジョニングする際に選択できます。

### 異なるブランチに対するCI/CDパイプラインのシミュレーション {#simulate-cicd-pipelines-against-different-branch}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../ci/pipeline_editor/_index.md#validate-cicd-configuration) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/482676)

{{< /details >}}

以前は、パイプラインエディタを使用して「検証」タブで変更を検証する際、デフォルトブランチに対してのみシミュレーションを実行できました。今回のリリースでこの機能が拡張され、シミュレーション対象として任意のブランチを選択できるようになりました。この改善により、パイプラインのテストと検証の柔軟性が向上します。安定したブランチやフィーチャーブランチなど、さまざまなケースで期待通りに動作するかを確認できます。

## Agentic Core

### グループおよびアプリケーション向けの自動Duo Code Review {#automatic-duo-code-review-for-groups-and-applications}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/merge_requests/duo_in_merge_requests.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/554070)

{{< /details >}}

グループまたはアプリケーションの設定を使用して、複数のプロジェクトに対して自動Duo Code Reviewを有効化できるようになりました。これにより、個別のプロジェクトを一つずつ有効化するのではなく、グループ内のすべてのプロジェクトに対してDuo Code Reviewを素早く有効化できます。

この機能は現在GitLab.comで利用可能であり、将来のリリースでGitLab Self-Managedでも利用可能にする予定です。フィードバックは[イシュー517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)でお寄せください。

### GitLab Duo Self-Hostedでサポートされるモデルが追加 {#additional-supported-models-for-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16742)

{{< /details >}}

GitLab Duo Enterpriseをご利用のGitLab Self-Managedのお客様は、GitLab Duoで追加のサポートモデルを使用できるようになりました。
OpenAI GPT-5がAzure OpenAIでサポートされるようになりました。また、オープンソースのOpenAI GPT OSS 20Bおよび120BがvLLMとAzure OpenAIでサポートされるようになりました。
これらのモデルをGitLab Duo Self-Hostedで使用する際のフィードバックは、[イシュー523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918)をご覧ください。

### GitLab Duo Self-HostedのDuo Code Reviewが一般提供開始 {#duo-code-review-on-gitlab-duo-self-hosted-is-generally-available}

<!-- categories: Code Suggestions, Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/_index.md#gitlab-duo) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/548975)

{{< /details >}}

GitLab Duo Self-HostedのDuo Code Reviewが一般提供開始となりました。GitLab Duo Self-HostedのCode Reviewを使用することで、データ主権を損なうことなく開発プロセスを加速できます。Code Reviewがマージリクエストをレビューする際、潜在的なバグを特定し、直接適用できる改善提案を行います。人間によるレビューを依頼する前に、Code Reviewを使用して変更を反復・改善してください。この機能はMistral、Meta Llama、Anthropic Claude、OpenAI GPTモデルファミリーをサポートしています。

Code Reviewに関するフィードバックは[イシュー517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)でお寄せください。

## 統合DevOpsとセキュリティ

### パイプラインのシークレット検出で特定のファイルとディレクトリをデフォルトで除外 {#pipeline-secret-detection-now-excludes-certain-files-and-directories-by-default}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/secret_detection/pipeline/_index.md#excluded-items) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/560147)

{{< /details >}}

パイプラインのシークレット検出で、シークレットが含まれる可能性が低い[特定のファイルタイプとディレクトリ](../../user/application_security/secret_detection/pipeline/_index.md#excluded-items)が自動的に除外されるようになり、スキャンのパフォーマンスが向上しました。これらの変更はアナライザー[バージョン7.11.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.11.0)でリリースされています。

### シークレット検出アナライザーのGitフェッチ改善 {#secret-detection-analyzer-git-fetching-improvements}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/secret_detection/pipeline/_index.md#how-the-analyzer-fetches-commits) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17315)

{{< /details >}}

シークレット検出アナライザーのバージョン[7.12.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v[7.12.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.12.0))では、Gitコミットのフェッチ方法に大幅な改善が加えられました。アナライザーが`SECRET_DETECTION_LOG_OPTIONS`から渡される`--depth`および`--since`オプションを解析するようになり、スキャンするコミット数をより細かく指定できます。また、コンテキストに基づいて適切なフェッチ戦略を選択するようになり、シャロークローン設定を使用していても数百万件のコミットが不必要にフェッチされるという既知の問題を防ぎます。

この改善により、ジョブのタイムアウトが減少し、リソース消費が削減され、より予測可能なスキャンパフォーマンスが実現します。特に大規模なリポジトリでシークレット検出スキャンが高速化され、実際のフェッチ動作に合致した明確なログが出力されます。

### 高度なSASTスキャンの大幅な高速化 {#significantly-faster-advanced-sast-scanning}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16561)

{{< /details >}}

マージリクエストやパイプラインでセキュリティスキャンを有効化する際、1分1秒が重要です。
私たちはエンジンと検出ルールの両方を対象に、高度なSASTのパフォーマンス改善を継続的にリリースしています。

今回のリリースでは、ベンチマークおよび実際のテストでスキャン実行時間を最大78%削減する特定の改善を紹介します。
スキャンプロセスのパフォーマンスに敏感な部分にキャッシュを追加し、大規模なリポジトリでのスキャンを大幅に高速化しました。

この改善は高度なSASTアナライザーバージョン2.9.6以降で自動的に有効化されます。
使用しているアナライザーのバージョンは[スキャンジョブログを確認する](../../user/application_security/sast/gitlab_advanced_sast.md)ことで確認できます。

### Operational Container Scanningの重大度しきい値設定 {#operational-container-scanning-severity-threshold-configuration}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/clusters/agent/vulnerabilities.md#configure-trivy-severity-threshold-filter) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/559278)

{{< /details >}}

Operational Container Scanning（OCS）を設定して、特定の重大度レベル以上の脆弱性のみを返すようにできるようになりました。
重大度しきい値を設定すると、選択した重大度を下回る脆弱性は脆弱性レポート、APIペイロード、その他のレポートメカニズムに返されなくなります。
これにより、修正したい脆弱性に集中できます。

このフィルタリングを有効化するには、OCS設定で[`severity_threshold`を設定](../../user/clusters/agent/vulnerabilities.md#configure-trivy-severity-threshold-filter)してください。

このコミュニティコントリビューションを提供してくださった[John Walsh](https://gitlab.com/mjohnw)氏に感謝します。
GitLabへのコントリビューションについて詳しくは、[コミュニティコントリビューションプログラム](https://about.gitlab.com/community/contribute/)をご覧ください。

### CI/CDテンプレートを使用してOpenTofuモジュールとプロバイダーをGitLabコンテナレジストリに公開 {#publish-opentofu-modules-and-providers-to-the-gitlab-container-registry-with-cicd-templates}

<!-- categories: Infrastructure as Code -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](https://gitlab.com/components/opentofu#publish-providers-to-the-gitlab-oci-registry) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/562715)

{{< /details >}}

GitLabコンテナレジストリがOpenTofuモジュールとプロバイダーをホストするためのメディアタイプをサポートするようになりました。

[OpenTofu CI/CDコンポーネント](https://gitlab.com/components/opentofu)のバージョン[3.1.0](https://gitlab.com/components/opentofu/-/releases/[3.1.0](https://gitlab.com/components/opentofu/-/releases/3.1.0))では、OCIフォーマットを使用してOpenTofuプロバイダーをGitLabレジストリにデプロイするための新しい`provider-release`テンプレートをサポートしています。これにより、プライベートなOpenTofuプロバイダーをGitLab上で直接ホストできるようになりました。

また、`module-release`テンプレートに新しい`type`入力が追加され、`oci`に設定することでOCIフォーマットを使用してOpenTofuモジュールをGitLabレジストリにデプロイできます。

### エンタープライズユーザーのプレースホルダー再割り当て時の確認をバイパス {#bypass-confirmation-for-enterprise-users-when-reassigning-placeholders}

<!-- categories: Importers -->

{{< details >}}

- プラン: Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/import/mapping/reassignment.md#bypass-confirmation-when-reassigning-placeholder-users) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17871)

{{< /details >}}

グループのオーナーロールを持つユーザーは、そのグループのアクティブなエンタープライズユーザーにプレースホルダーを再割り当てする際、ユーザー確認をバイパスできるようになりました。これにより、エンタープライズユーザーは再割り当ての確認のためにメールを繰り返し確認する必要がなくなります。設定の制限時間に達すると、新しいすべての再割り当てに対して再びメール確認リクエストが送信されます。

エンタープライズユーザーは再割り当て完了後も通知メールを受け取り、プロセス全体の透明性が確保されます。

### イシューページからイシューの表示方法を設定 {#configure-how-to-view-issues-from-the-issues-page}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/issues/managing_issues.md#open-issues-in-a-panel) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/570776)

{{< /details >}}

リスティングページのビューを完全に制御できるようになりました。表示するメタデータを選択し、作業アイテムをドロワーで開くかどうかを設定することで、最も重要な情報に集中しやすくなります。

以前は、すべてのメタデータフィールドが常に表示されており、作業アイテムを確認する際に情報過多になることがありました。担当者、ラベル、日付、マイルストーンなどの特定のフィールドのオン/オフを切り替えることで、ビューをカスタマイズできるようになりました。

ドロワービューとフルページナビゲーションを切り替える新しいトグルにより、リストのコンテキストを維持しながら詳細をすばやく確認したり、詳細な編集や包括的なナビゲーションのためにより多くの画面スペースが必要な場合はフルページを開いたりできます。

### エピックとイシューリストの親フィルタリングを強化 {#enhanced-parent-filtering-for-epic-and-issue-lists}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/issues/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/556200)

{{< /details >}}

イシューページとエピックページの「エピック」フィルターを、より柔軟な「親」フィルターに置き換えました。この変更により、エピックだけでなく任意の親作業アイテムでフィルタリングできるようになりました。親イシューでフィルタリングして子タスクを簡単に見つけたり、親エピックでフィルタリングしてイシューを見つけたりできるようになり、イシューリストとエピックリストの両方で作業階層の可視性が向上します。

### イシューボードで完全なエピック階層を表示 {#issue-boards-now-show-complete-epic-hierarchies}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/issue_board.md#filter-issues) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/358416)

{{< /details >}}

イシューボードで親エピックでフィルタリングする際に、子エピックのすべてのイシューを表示できるようになりました。これはイシューページの既存の動作との一貫性をもたらします。この改善により、子エピックにネストされたイシューを見逃すことなく、完全なエピック階層を追跡・可視化できるようになり、プロジェクト管理ワークフローがより効率的で信頼性の高いものになります。

### テキストエディタのツールバーの同等性 {#text-editors-toolbar-parity}

<!-- categories: Markdown -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/rich_text_editor.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/507377)

{{< /details >}}

GitLabのプレーンテキストエディタに、リッチテキストエディタと同じフォーマットオプションが追加されました。プレーンテキストエディタのツールバーが「その他のオプション」メニューで更新され、以下のような高度なフォーマットツールにアクセスできるようになりました。

- コードブロック
- 詳細ブロック
- 水平線
- Mermaidダイアグラム
- PlantUMLダイアグラム
- 目次

両エディタのボタン配置とセパレーターが統一され、使い慣れたフォーマットオプションへのアクセスを維持しながら編集モードを切り替えやすくなりました。

### 脆弱性の詳細に自動解決パイプラインIDを表示 {#vulnerability-details-shows-the-auto-resolve-pipeline-id}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/vulnerability_management_policy.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/566392)

{{< /details >}}

自動的に解決され、その後再検出された脆弱性のトラブルシューティングを行う際、現在のパイプラインと脆弱性が解決されたパイプラインを比較することが役立ちます。

脆弱性が自動的に解決された場合、脆弱性詳細ページの脆弱性ノートに、解決が発生したパイプラインIDが含まれるようになりました。

### ジョブアーティファクトのダウンロード権限の強化 {#enhanced-controls-for-who-can-download-job-artifacts}

<!-- categories: Artifact Security -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../ci/yaml/_index.md#artifactsaccess) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/454398)

{{< /details >}}

GitLab 16.11では、`artifacts:access`キーワードを追加し、パイプラインへのアクセス権を持つすべてのユーザー、デベロッパーロール以上のユーザー、またはいずれのユーザーもアーティファクトをダウンロードできないように制御できるようにしました。

今回のリリースでは、アーティファクトのダウンロードをメンテナーロール以上のユーザーのみに制限できるようになり、ジョブアーティファクトのダウンロード権限をより細かく制御できるオプションが追加されました。

### GitLab Runner 18.4 {#gitlab-runner-184}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.4もリリースします！GitLab Runnerは、CI/CDジョブを実行してGitLabインスタンスに結果を送信する高スケーラブルなビルドエージェントです。GitLab RunnerはGitLab CI/CDと連携して動作します。GitLab CI/CDはGitLabに含まれるオープンソースの継続的インテグレーションサービスです。

#### バグ修正

- [FIPSランナーがGitLab Runner 18.2.1でジョブの開始に失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38963)
- [カスタムConfigMapとセキュリティコンテキスト制約（SCC）を使用するRunnerの`chown`コマンドが、OpenShift 4.16.27でのOperator v1.37.0アップグレード後に失敗する](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/246)
- [17.2での早期削除によりGitLab 17.x.xリリースで`FF_RETRIEVE_POD_WARNING_EVENTS`を復元する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38851)
- [ファイルシステムの権限エラーによりすべてのGitLab Runnerジョブが失敗する](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/214)
- [ビルドジョブが権限拒否エラーで断続的に失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37464)
- [GitLab Runner Helmチャートのアップグレードで変数が壊れた](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30851)
- [`FF_USE_FASTZIP`を有効化してもfastzipが有効にならない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28989)
- [GitLab Runnerが、ワンタイムリクエストで作成されたスポットインスタンスを停止しようとすると`UnsupportedOperation`エラーが発生する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28865)
- [GitLab RunnerのロングポーリングがKubernetesデプロイ環境で正常に動作しない](https://gitlab.com/gitlab-org/gitlab/-/issues/331460)
- [管理者がimage:Kubernetes:userの値をオーバーライドできるようにする](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38894)

すべての変更のリストはGitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-4-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-4-stable/CHANGELOG.md).md)に記載されています。

## 関連トピック

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.4)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.4)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.4)
- [非推奨と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
