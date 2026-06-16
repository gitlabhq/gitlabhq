---
stage: Release Notes
group: Monthly Release
date: 2025-01-16
title: "GitLab 17.8リリースノート"
description: "GitLab 17.8は、保護されたコンテナリポジトリでセキュリティを強化してリリースされました。"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年1月16日、GitLab 17.8は次の機能とともにリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター {#this-months-notable-contributor}

誰もがGitLabコミュニティのコントリビューターを[推薦](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)できます！活躍中の候補者を支援するか、新しい推薦を追加してください！ 🙌

共同開発プログラムを通じて、[Océane Legrand](https://gitlab.com/oceane_scania)はJuan Pablo Gonzalezと協力して、Conanパッケージレジストリの機能セットを強化する取り組みを主導してきました。彼らの作業は、Conanバージョン2のサポートを実装しながら、この機能をGAの準備に近づけることに重点を置いてきました。この共同作業は、共同開発プログラムがGitLabのパッケージレジストリ機能に大きな改善をもたらす方法を示しています。

彼らは、[Raimund Hook](https://gitlab.com/stingrayza)（GitLabのシニアフルスタックエンジニア、コントリビューターサクセス）によって推薦されました。彼は、Conanパッケージレジストリ機能に関する彼らの継続的な共同作業と継続的なイテレーションを強調しました。彼らの仕事はGitLabの価値観を体現しており、プラットフォーム上のすべてのConanユーザーに利益をもたらします。

Océane LegrandはScaniaのフルスタック開発者であり、AWSでセルフホストされたGitLabインスタンスの保守を担当しています。「オープンソースで取り組んでいる作業は、GitLabとScaniaの両方に影響を与えます」とOcéaneは述べています。「共同開発プログラムを通じてコントリビュートすることで、Rubyとバックグラウンド移行の経験など、新しいスキルを習得できました。Scaniaのチームがアップグレード中にイシューに直面したとき、私はプログラムを通じてすでにそれを経験していたため、トラブルシューティングを行うことができました。」

顧客が当社の製品およびエンジニアリングチームと直接協力して新機能を開発し、既存の機能を強化する[GitLabの共同開発プログラムについて詳しく知る](https://about.gitlab.com/community/co-create/)。

## 主要な機能 {#primary-features}

### 保護されたコンテナリポジトリでセキュリティを強化 {#enhance-security-with-protected-container-repositories}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/container_registry/container_repository_protection_rules.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/480385)

{{< /details >}}

GitLabのコンテナレジストリに、コンテナイメージの管理におけるセキュリティと制御の課題に対処する新機能である保護されたコンテナリポジトリのロールアウトを発表できることを嬉しく思います。組織は、機密性の高いコンテナリポジトリへの不正アクセス、偶発的な変更、詳細な制御の欠如、およびコンプライアンスの維持の困難さにしばしば苦しんでいます。このソリューションは、厳格なアクセス制御、プッシュ、プル、および管理操作に対する詳細な権限、そしてGitLab CI/CDパイプラインとのシームレスな統合により、強化されたセキュリティを提供します。

保護されたコンテナリポジトリは、セキュリティ漏洩のリスクと重要なアセットへの偶発的な変更を減らすことで、ユーザーに価値を提供します。この機能は、開発速度を犠牲にすることなくセキュリティを維持することでワークフローを効率化し、コンテナレジストリ全体のガバナンスを向上させ、重要なコンテナ資産が組織のニーズに応じて保護されているという安心感を提供します。

この機能と[保護されたパッケージ](https://gitlab.com/groups/gitlab-org/-/epics/5574)機能は、`gerardo-navarro`とSiemensのクルーによるコミュニティコントリビュートです。GerardoとSiemensのクルーの皆様、GitLabへの多大なコントリビュートに感謝いたします！GerardoとSiemensのクルーがこの変更にどのようにコントリビュートしたかについて詳しく知りたい場合は、Gerardoが外部コントリビューターとしての経験に基づいてGitLabへのコントリビュートの学習内容とベストプラクティスを共有しているこの[ビデオ](https://www.youtube.com/watch?v=5-nQ1_Mi7zg)をご覧ください。

### リリースに関連するデプロイを一覧表示する {#list-the-deployments-related-to-a-release}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/releases/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/501169)

{{< /details >}}

GitLabは以前からGitタグからのリリースの作成とデプロイの追跡をサポートしていましたが、この情報は以前は複数の別々の場所に存在し、まとめるのが困難でした。これで、リリースページでリリースに関連するすべてのデプロイを直接確認できます。リリースマネージャーは、リリースがどこにデプロイされたか、どの環境がデプロイを保留しているかを迅速に確認できます。これは、タグ付けされたデプロイのリリースノートを表示する既存のデプロイページインテグレーションを補完します。

[Anton Kalmykov](https://gitlab.com/antonkalmykov)氏が両方の機能をGitLabにコントリビュートしてくださったことに感謝いたします。

### 機械学習モデル実験の追跡がGAに {#machine-learning-model-experiments-tracking-in-ga}

<!-- categories: MLOps -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/ml/experiment_tracking/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9341)

{{< /details >}}

機械学習モデルを作成する際、データサイエンティストはモデルのパフォーマンスを向上させるために、さまざまなパラメータ、設定、および特徴量エンジニアリングで実験することがよくあります。このすべてのメタデータと関連するアーティファクトを追跡し、データサイエンティストが後で実験をレプリケートできるようにすることは、簡単なことではありません。機械学習実験の追跡により、パラメータ、メトリクス、およびアーティファクトをGitLabに直接ログ記録できるため、後で簡単にアクセスでき、すべての実験データをGitLab環境内に保持できます。この機能は、強化されたデータ表示、強化された権限、GitLabとのより深いインテグレーション、およびバグ修正とともに、一般提供が開始されました。

### GitLab Dedicated向けのLinux上のホスト型Runnerが限定提供開始 {#hosted-runners-on-linux-for-gitlab-dedicated-now-in-limited-availability}

<!-- categories: GitLab Dedicated, GitLab Hosted Runners -->

{{< details >}}

- プラン: Gold
- リンク: [ドキュメント](../../administration/dedicated/hosted_runners.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509142)

{{< /details >}}

GitLab Dedicated向けのLinux上のホスト型Runnerの限定提供を開始できることを嬉しく思います。

Runnerフリートの管理は複雑であり、すべてのCI/CDジョブが開発者の要求を満たすようにスケールすることを確実にするには、かなりの経験が必要です。

GitLab Dedicated向けのホスト型Runnerを使用すると、CI/CDジョブに完全に管理されたRunnerを使用できます。これにより、独自のRunnerインフラストラクチャを維持する必要がなくなり、GitLab Dedicatedと同じセキュリティ、柔軟性、および効率性をRunnerに提供します。

ホスト型Runnerは、ピーク時や大規模プロジェクトでの最適なパフォーマンスを確保するために、CI/CDの要求に合わせて自動的にスケールします。限定提供リリースには、2～32vCPU、8～128GBのメモリを備えたさまざまなサイズのLinux Runnerが含まれます。

限定提供期間中にGitLab Dedicated向けのホスト型Runnerへのアクセスをリクエストするには、GitLabの担当者にお問い合わせください。

### macOS上の大規模M2 Proホスト型Runner (ベータ) {#large-m2-pro-hosted-runners-on-macos-beta}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/macos.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/ci-cd/shared-runners/-/epics/19)

{{< /details >}}

M2 ProのパフォーマンスをモバイルDevOpsチームに提供します！

M1 Runnerの最大2倍、x86-64 macOS Runnerの6倍のパフォーマンスにより、アプリケーションをビルドおよびデプロイする際の開発チームの開発速度を向上させることができます。

GitLab CI/CDに完全に統合されたオンデマンドで利用できるため、チームはAppleエコシステム向けにアプリケーションをより迅速に作成、テスト、およびデプロイできます。

`.gitlab-ci.yml`ファイルで`saas-macos-large-m2pro`をタグとして使用して、新しいM2 Pro Runnerを今すぐお試しください。

## エージェント型コア {#agentic-core}

### GitLab MLOps Pythonクライアントベータ {#gitlab-mlops-python-client-beta}

<!-- categories: MLOps -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://gitlab.com/gitlab-org/modelops/mlops/gitlab-mlops) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/16193)

{{< /details >}}

データサイエンティストと機械学習エンジニアは主にPython環境で作業しますが、彼らの機械学習ワークフローをGitLabのMLOps機能と統合するには、多くの場合、コンテキストの切り替えとGitLabのAPI構造の理解が必要です。これにより、開発プロセスで摩擦が生じ、実験の追跡、モデルアーティファクトの管理、およびチームメンバーとの共同作業の能力が低下する可能性があります。

新しいGitLab MLOps Pythonクライアントは、GitLabのMLOps機能にシームレスなPython的なインターフェースを提供します。データサイエンティストは、Pythonスクリプトおよびノートブックから直接、GitLabの[実験の追跡](../../user/project/ml/experiment_tracking/_index.md)機能と[モデルレジストリ](../../user/project/ml/model_registry/_index.md)機能を使用できるようになりました。クライアントには以下が含まれます:

- **GitLab Experiment Tracking**: GitLab内で機械学習実験を簡単に追跡することができます。
- **Model Registry Integration**: GitLabのモデルレジストリでモデルを登録および管理します。
- **Experiment Management**: クライアントから直接実験を作成および管理します。
- **Run Tracking**: 簡単にトレーニング実行を開始および監視します。

このインテグレーションにより、データサイエンティストはモデル開発に集中しながら、MLライフサイクルメタデータをGitLabに自動的にキャプチャすることができます。Pythonクライアントは既存のMLワークフローとシームレスに連携し、最小限のセットアップで済むため、GitLabのMLOps機能をデータサイエンスコミュニティがよりアクセスしやすくなります。

より幅広いPythonおよびデータサイエンスコミュニティからのコントリビュートを歓迎し、[プロジェクトのリポジトリ](https://gitlab.com/gitlab-org/modelops/mlops/gitlab-mlops)でフィードバックを直接共有してください。

## 規模とデプロイ {#scale-and-deployments}

### 削除待ちのサブグループとプロジェクトを表示 {#view-subgroups-and-projects-pending-deletion}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/_index.md#view-inactive-groups) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/457718)

{{< /details >}}

グループを削除対象としてマークすると、影響を受けるすべてのサブグループとプロジェクトの表示レベルが必要になります。以前は、削除対象としてマークされたグループのみが「削除待ち」のラベルを表示していましたが、そのサブグループやプロジェクトは表示されず、どのコンテンツが削除予定であるかを特定することが困難でした。

現在、グループが削除対象としてマークされると、そのすべてのサブグループとプロジェクトに「削除待ち」のラベルが表示されます。この改善された表示レベルは、グループ階層全体でアクティブなコンテンツとまもなく削除されるコンテンツを迅速に区別するのに役立ちます。

### イシューまたはマージリクエストで複数のTo-Doアイテムを追跡する {#track-multiple-to-do-items-in-an-issue-or-merge-request}

<!-- categories: Notifications -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/todos.md#actions-that-create-to-do-items) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/28355)

{{< /details >}}

これで、単一のイシューまたはマージリクエスト内で複数のディスカッションとメンションを追跡することができます。新しい複数のTo-Doアイテム機能により、それぞれのメンションまたはアクションごとに個別のTo-Doアイテムを受け取ることができ、重要な更新や注意喚起のリクエストを見逃すことがなくなります。この機能強化により、作業をより効果的に管理し、チームのニーズにより効率的に対応できます。

### グループのプロジェクト作成保護にオーナーが含まれるようになりました {#project-creation-protection-for-groups-now-includes-owners}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/_index.md#specify-who-can-add-projects-to-a-group) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/354355)

{{< /details >}}

プロジェクト作成は、**Allowed to create projects**設定を使用して、グループ内の特定の役割に制限できます。オーナーロールがオプションとして利用可能になり、グループのオーナーロールを持つユーザーに新しいプロジェクト作成を制限できるようになりました。このロールは以前は選択オプションとして利用できませんでした。

このコントリビュートをしてくれた[@yasuk](https://gitlab.com/yasuk)に感謝します！

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### シークレット検出に修正ステップが含まれるようになりました {#secret-detection-now-includes-remediation-steps}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/secret_detection/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/505757)

{{< /details >}}

公開されたシークレットを迅速に修正することは、攻撃者が公開された認証情報を使用してシステムに侵入するリスクを最小限に抑えるために重要です。適切な修正には、シークレットを単に削除するだけでなく、認証情報をローテーションすることや、潜在的な不正アクセスを調査することなど、複数のステップが必要です。システムを安全に保つために、シークレット検出には、検出されたシークレットの種類ごとに特定の修正ステップが含まれるようになりました。このガイダンスは、公開を体系的に対処し、セキュリティ漏洩のリスクを軽減するのに役立ちます。修正ステップは、パイプラインの完了時にすべての脆弱性に表示されます。

### 脆弱性を解決したコミットを見つける {#find-the-commit-that-resolved-a-vulnerability}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/372799)

{{< /details >}}

以前は、脆弱性が検出されなくなっても、脆弱性がいつ、どこで解決されたかを確認する方法をユーザーに提供していませんでした。現在、脆弱性が解決されたコミットSHAへのリンクを表示し、解決プロセスに関するトレーサビリティとインサイトを向上させます。これにより、セキュリティチームと開発チームが協力して脆弱性をより効果的に管理しやすくなります。

### プロジェクトメンバーをコードオーナーとして定義するためにロールを使用する {#use-roles-to-define-project-members-as-code-owners}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/codeowners/reference.md#add-a-role-as-a-code-owner) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/282438)

{{< /details >}}

これで、`CODEOWNERS`ファイルでロールをコードオーナーとして使用して、ロールベースの専門知識と承認をより効率的に管理できます。個々のユーザーをリストする代わりに、次の構文を使用できます:

- `@@developers` - デベロッパーロールを持つすべてのユーザーを参照します。
- `@@maintainers` - メンテナーロールを持つすべてのユーザーを参照します。
- `@@owners` - オーナーロールを持つすべてのユーザーを参照します。

例えば、`* @@maintainers`を追加して、リポジトリ内のすべての変更にメンテナーからの承認を要求します。

これにより、チームメンバーがプロジェクトに参加、離脱、またはロールを変更する際のコードオーナー管理が簡素化されます。GitLabは指定されたロールを持つすべてのユーザーを自動的に含めるため、`CODEOWNERS`ファイルは手動で更新しなくても常に最新の状態を保ちます。

### Kubernetesのダッシュボードで一時停止中のFlux調整を表示する {#view-paused-flux-reconciliations-on-the-dashboard-for-kubernetes}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/501339)

{{< /details >}}

以前は、KubernetesのダッシュボードからFlux調整を一時停止しても、一時停止状態を明確に示すインジケータはありませんでした。既存のステータスインジケーターセットに新しい「一時停止」ステータスを追加し、Flux調整が一時停止された時期を明確にし、デプロイの状態をより明確に表示できるようにしました。

### Kubernetesのダッシュボードでポッドを検索する {#search-for-pods-on-the-dashboard-for-kubernetes}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/508010)

{{< /details >}}

Kubernetesのダッシュボードで、大規模なデプロイから特定のポッドを見つけるのは時間がかかる場合があります。新しい検索バーを使用すると、ポッドを名前で素早くフィルタリングできます。検索は利用可能なすべてのポッドで機能し、ステータスフィルターと組み合わせて、監視またはトラブルシューティングを行う必要がある正確なポッドを見つけることができます。

### マージリクエスト承認ポリシーで複数の個別の承認アクションをサポート {#support-multiple-distinct-approval-actions-in-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/12319)

{{< /details >}}

以前は、マージリクエスト承認ポリシーはポリシーごとに単一の承認ルールのみをサポートしており、「OR」条件で積み重ねられた1組の承認者のみを許可していました。その結果、多様なロール、個々の承認者、または個別のグループからの階層化されたセキュリティ承認を適用することがより困難でした。

この更新により、各マージリクエスト承認ポリシーに対して最大5つの承認ルールを作成でき、より柔軟で堅牢な承認ポリシーが可能になります。各ルールは異なる承認者またはロールを指定でき、各ルールは独立して評価されます。例えば、セキュリティチームは、Group Aから1人の承認者、Group Bから1人の承認者、または特定のロールから1人、指定されたグループから別の1人を要求するなど、複雑な承認ワークフローを定義でき、機密性の高いワークフローでのコンプライアンスと強化された制御を確保します。

この改善の例には、以下が含まれます:

- **Distinct role approvals:** デベロッパーロールからの1つの承認と、メンテナーロールからの別の1つの承認。
- **Role and group approvals**: デベロッパーまたはメンテナーからの1つの承認と、Security Groupのメンバーからの個別の承認。
- **Distinct group approvals:** Python Expertsグループのメンバーからの1つの承認と、Security Groupのメンバーからの別の個別の承認。

### GitLab Pagesのプライマリドメインリダイレクト {#primary-domain-redirect-for-gitlab-pages}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/pages/_index.md#primary-domain)

{{< /details >}}

これで、GitLab Pagesでプライマリドメインを設定して、カスタムドメインからのすべてのリクエストをプライマリドメインに自動的にリダイレクトできるようになりました。これにより、SEOランキングの維持に役立ち、訪問者を最初にサイトにアクセスするために使用したURLに関係なく、優先ドメインに誘導することで一貫したブランド体験を提供します。

### パッケージ保護されたパッケージで依存関係を保護する {#safeguard-your-dependencies-with-protected-packages}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/packages/package_registry/package_protection_rules.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/323971)

{{< /details >}}

保護されたPyPIパッケージのサポートを発表できることを嬉しく思います。これは、GitLabパッケージレジストリのセキュリティと安定性を強化するために設計された新機能です。ペースの速いソフトウェア開発の世界では、パッケージの偶発的な変更または削除が、開発プロセス全体を混乱させる可能性があります。保護されたパッケージは、意図しない変更から最も重要な依存関係を保護できるようにすることで、この問題に対処します。

GitLab 17.8以降、保護ルールを作成することでPyPIパッケージを保護できます。パッケージが保護ルールに一致する場合、指定されたユーザーのみがパッケージを更新または削除できます。この機能により、偶発的な変更を防止し、規制要件へのコンプライアンスを改善し、手動での監視の必要性を減らすことでワークフローを合理化できます。

### エピック用のカスタマイズ可能な色 {#customizable-colors-for-epics}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md#epic-color) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509924)

{{< /details >}}

既存の値やカスタムRGBまたは16進コードを含む、拡張された色のオプションセットを使用して、エピックを分類する柔軟性が向上しました。この強化されたビジュアルカスタマイズにより、エピックをスクワッド、会社のイニシアチブ、または階層レベルに簡単に紐付け、ロードマップやエピックボードでの作業の優先順位付けと整理を簡素化できます。

あなたの管理者は[エピック](../../user/group/epics/_index.md#epics-as-work-items)の新しい外観を有効にする必要があります。

### エピックの祖先 {#epic-ancestors}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/epics/_index.md#relationships-between-epics-and-other-items) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509920)

{{< /details >}}

再設計された祖先ウィジェット（各エピックの上部にパンくずリストのような形式で目立つように表示される）により、[エピック階層](../../user/group/epics/_index.md#relationships-between-epics-and-other-items)のナビゲーションがより簡単になりました。即時および究極の親をひと目で確認できることで、エピック間の関係を素早く把握でき、プロジェクト構造の明確な概要を維持し、関連するエピック間を簡単に移動できます。

あなたの管理者は[エピック](../../user/group/epics/_index.md#epics-as-work-items)の新しい外観を有効にする必要があります。

### エピックヘルスステータス {#epic-health-status}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md#health-status) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509922)

{{< /details >}}

新しいエピックのヘルスステータス機能により、プロジェクトの進捗状況を簡単に伝えることができるようになりました。ステータスを「順調」、「注意が必要」、「危険」に設定することで、エピックの健全性を素早く視覚的に確認でき、リスクを管理し、プロジェクト全体のステータスについて利害関係者に情報を提供できます。

あなたの管理者は[エピック](../../user/group/epics/_index.md#epics-as-work-items)の新しい外観を有効にする必要があります。

### エピック親 {#epic-parent}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/epics/_index.md#relationships-between-epics-and-other-items) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509923)

{{< /details >}}

これで、イシューの場合と同様に、エピックから直接親を追加することで、エピックの階層を簡単に管理できます。この効率化されたプロセスにより、作業の整理の柔軟性が向上し、エピック間の関係を素早く確立し、プロジェクトの明確な構造を維持できます。

あなたの管理者は[エピック](../../user/group/epics/_index.md#epics-as-work-items)の新しい外観を有効にする必要があります。

### エピックに費やした時間を追跡する {#track-time-spent-on-epics}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/time_tracking.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509930)

{{< /details >}}

これで、エピックで直接時間を追跡することができ、プロジェクトの時間管理をより詳細に制御できます。この新機能により、プロジェクトのさまざまな側面に費やした時間を記録でき、スプリントやマイルストーンを通じて作業を進める際に、進捗状況を監視し、スケジュールを守り、予算を管理するのに役立ちます。

### エピック、イシュー、および目標の子アイテムにイテレーションフィールドを表示する {#show-iteration-field-on-child-items-in-epics-issues-and-objectives}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/iterations/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/510005)

{{< /details >}}

エピックの詳細を表示する際、プランナーは、どの子イシューがイテレーション（スプリント）に計画されているか、まだ計画されていないかを確認できる必要があります。これにより、チームは定義されたすべての作業がスプリントに割り当てられていることをより簡単に確認できます。

エピックの場合、あなたの管理者は[エピック](../../user/group/epics/_index.md#epics-as-work-items)の新しい外観を有効にする必要があります。

### エピック用のWebhook {#webhooks-for-epics}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/webhook_events.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509928)

{{< /details >}}

エピックWebhookを使用してワークフロー自動化を強化し、エピックで変更が発生するたびに、お好みのツールでリアルタイムの更新を受け取ることができます。GitLabを他のサービスと統合することで、コラボレーションを強化し、プロジェクト開発の最新情報を把握し、アプリケーション間を常に切り替えることなくプロセスを効率化できます。

あなたの管理者は[エピック](../../user/group/epics/_index.md#epics-as-work-items)の新しい外観を有効にする必要があります。

### 脆弱性をサポートされているWebhookイベントとして追加 {#add-vulnerabilities-as-supported-webhook-events}

<!-- categories: Webhooks, Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/webhook_events.md#vulnerability-events) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/366770)

{{< /details >}}

脆弱性に関連するアクションのイベントを生成するWebhookインテグレーションを導入し、外部リソースとの自動化と統合を可能にします。例えば、脆弱性が作成されたときや脆弱性のステータスが変更されたときにイベントが生成されます。

### `override_ci`戦略の中央集約型ワークフロールールを適用する {#enforce-centralized-workflow-rules-for-the-override_ci-strategy}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/pipeline_execution_policies.md#override_project_ci) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/512123)

{{< /details >}}

パイプライン実行ポリシーでは、`override_ci`戦略がワークフロールールの使用をサポートするようになり、ポリシーで定義されたジョブのポリシー適用、および`include:project`を使用する際のプロジェクトの設定で定義されたジョブの適用を支援します。ポリシーでワークフロールールを定義することで、プロジェクトでブランチパイプラインの使用を防ぐルールを設定するなど、特定のルールに基づいてパイプライン実行ポリシーによって実行されるジョブをフィルタリングできます。

ワークフロールールの使用をポリシーで定義されたジョブのみを対象とするように分離するには、ポリシーでグローバルに定義するのではなく、ジョブのルールを定義するのがベストプラクティスです。または、個別の`include`フィールドを使用してジョブとルールをグループ化できます。

以前は、`override_ci`戦略を使用する場合、ワークフロールールはパイプライン実行ポリシーで定義されたジョブにのみ適用できました。

`inject_ci`戦略は変更されず、ワークフロールールは、プロジェクトのワークフロールールに影響を与えることなく、ポリシージョブがいつ適用されるかを制御するためにのみ使用できます。

### パイプライン実行ポリシーで`skip_ci`を設定可能にする {#make-skip_ci-configurable-for-pipeline-execution-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/pipeline_execution_policies.md#skip_ci-type) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15647)

{{< /details >}}

パイプライン実行ポリシー (PEP) の新しい設定オプションを導入し、`[skip ci]`ディレクティブの処理における柔軟性を高めました。この機能は、セマンティックリリースなど、特定の自動化されたプロセスにおいて、重要なセキュリティおよびコンプライアンスチェックが実行されていることを確認しながら、パイプライン実行をバイパスする必要があるシナリオに対処します。

この機能を使用するには、パイプライン実行ポリシーYAML設定で`skip_ci`を`allowed: false`に設定するか、ポリシーエディタで**ユーザーがパイプラインをスキップできないようにする**を有効にします。次に、`[skip ci]`の使用が許可されているユーザーまたはサービスアカウントを指定します。デフォルトでは、すべてのユーザーはパイプライン実行ジョブのスキップをブロックされます。ただし、例外として`skip_ci`設定内で除外されている場合は除きます。

### スケジュールされたスキャン実行ポリシーパイプラインの並行処理を管理する {#manage-concurrency-of-scheduled-scan-execution-pipelines}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/scan_execution_policies.md#concurrency-control) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13997)

{{< /details >}}

グローバルなスケジュールされたスキャン実行ポリシーのスケーラビリティを向上させるため、スキャン実行ポリシーで時間枠を設定する新機能を導入しました。`time_window`プロパティは、最適なパフォーマンスを確保するためにポリシーが新しいスケジュールを作成および実行する時間枠を定義します。

新しいプロパティを使用するには、YAMLモードを使用してポリシーを更新し、[`time_window`スキーマ](../../user/application_security/policies/scan_execution_policies.md#time_window-schema)に従ってください。スケジュールが実行される時間枠の値を秒単位で指定できます。例えば、24時間枠の場合は`86400`。次に、`distribution: random`フィールドと値を指定して、定義された時間枠全体でスケジュールをランダムな時間に実行するように強制します。

### コンプライアンスセンターの「フレームワーク」レポートタブのUIパフォーマンスのスケーリング {#scaling-ui-performance-for-the-frameworks-report-tab-in-the-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate、Premium
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_frameworks_report.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/477394)

{{< /details >}}

GitLab 17.8では、コンプライアンスセンターの**フレームワーク**レポートタブに数千のコンプライアンスフレームワークがある場合でも、コンプライアンスセンターが迅速かつ応答性を維持できるようにバックエンドに変更を加えました。

さらに、詳細情報を探して**フレームワーク**タブのフレームワークをクリックすると、GitLabは右側のポップアップメニューの情報の一部として、その特定のフレームワークにアタッチされている最大1,000のプロジェクトを返します。

### GitLab Community Editionで利用可能なパイプライン制限 {#pipeline-limits-available-in-gitlab-community-edition}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/settings/continuous_integration.md#set-cicd-limits) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/287669)

{{< /details >}}

管理者は、GitLab Community Editionのインストールに対してCI/CD制限を設定することで、パイプラインリソースの使用を制御できるようになりました。以前は、この機能はGitLab Enterprise Editionでのみ利用可能でした。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.8)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.8)
- [UI改善](https://papercuts.gitlab.com/?milestone=17.8)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
