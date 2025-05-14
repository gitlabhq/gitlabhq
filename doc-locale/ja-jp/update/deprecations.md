---
stage: none
group: none
info: "See the Technical Writers assigned to Development Guidelines: https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines"
toc: false
title: バージョンごとの非推奨化と削除
---

次のGitLabの機能は非推奨となっており、使用は推奨されません。

- 各非推奨機能は、将来のリリースで削除されます。
- 一部の機能は、削除すると破壊的な変更を引き起こします。
- GitLab.comでは、非推奨機能は、リリースまでの1か月間にいつでも削除される可能性があります。
- 削除された機能のドキュメントを表示するには、[GitLabドキュメントのアーカイブ](https://docs.gitlab.com/archives/)を参照してください。
- GraphQL APIの非推奨化については、[非推奨のアイテムなしでAPIコールが機能することを確認](https://docs.gitlab.com/api/graphql/#verify-against-the-future-breaking-change-schema)する必要があります。

この非推奨情報の高度な検索とフィルタリングについては、[カスタマーサクセスチームが構築したツール](https://gitlab-com.gitlab.io/cs-tools/gitlab-cs-tools/what-is-new-since/?tab=deprecations)をお試しください。

[REST APIの非推奨化](https://docs.gitlab.com/api/rest/deprecations/)については、別途ドキュメントに記載されています。

{{< icon name="rss" >}}**今後の破壊的な変更の通知を受け取るには**、このURL（`https://about.gitlab.com/breaking-changes.xml`）をRSSフィードリーダーに追加してください。

<!-- vale off -->

<!--
DO NOT EDIT THIS PAGE DIRECTLY

This page is automatically generated from the template located at
`data/deprecations/templates/_deprecation_template.md.erb`, using
the YAML files in `/data/deprecations` by the rake task
located at `lib/tasks/gitlab/docs/compile_deprecations.rake`,

For deprecation authors (usually Product Managers and Engineering Managers):

- To add a deprecation, use the example.yml file in `/data/deprecations/templates` as a template.
- For more information about authoring deprecations, check the the deprecation item guidance:
  https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-doc

For deprecation reviewers (Technical Writers only):

- To update the deprecation doc, run: `bin/rake gitlab:docs:compile_deprecations`
- To verify the deprecations doc is up to date, run: `bin/rake gitlab:docs:check_deprecations`
- For more information about updating the deprecation doc, see the deprecation doc update guidance:
  https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-doc
-->

<div class="js-deprecation-filters"></div>
<div class="milestone-wrapper" data-milestone="20.0">

## GitLab 20.0

<div class="deprecation breaking-change" data-milestone="20.0">

### GitLab Runner Docker Machine Executorは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.5</span>で発表
- GitLab <span class="milestone">20.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/498268)を参照してください。

</div>

[GitLab Runner Docker Machine Executor](https://docs.gitlab.com/runner/executors/docker_machine/)は非推奨となり、GitLab 20.0（2027年5月）でサポート対象機能として製品から完全に削除されます。Docker Machineの代替となる、Amazon Web Services（AWS）EC2、Google Compute Engine（GCE）、Microsoft Azure仮想マシン（VM）用の GitLab開発プラグインを備えた[GitLab Runner Autoscaler](https://docs.gitlab.com/runner/runner_autoscale/)が一般提供されています。この発表に伴い、GitLab Runnerチームは、GitLabが管理するDocker Machineフォークに対するコミュニティからのコントリビューションを受け付けなくなり、新たに特定されたバグを解決することもなくなります。

</div>
</div>

<div class="milestone-wrapper" data-milestone="19.0">

## GitLab 19.0

<div class="deprecation breaking-change" data-milestone="19.0">

### コンテナレジストリのAzureストレージドライバー

<div class="deprecation-notes">

- GitLab <span class="milestone">17.10</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/523096)を参照してください。

</div>

コンテナレジストリの従来のAzureストレージドライバーはGitLab 17.10で非推奨となり、GitLab 19.0で削除されます。コンテナレジストリにAzureオブジェクトストレージを使用している場合は、新しい`azure_v2`ドライバーを使用するように設定を更新する必要があります。

`azure_v2`ストレージドライバーは、従来のドライバーと比較して、信頼性の向上、パフォーマンスの向上、および保守性の高いコードベースを提供します。これらの改善により、レジストリの使用状況が拡大するにつれてパフォーマンスの問題を防ぐことができます。

`azure_v2`ドライバーに移行するには:

1. 従来の`azure`ドライバーの代わりに、`azure_v2`ドライバーを使用するようにレジストリ設定ファイルを更新します。
1. 必要に応じて、新しいドライバーの構成設定を調整します。
1. 本番環境にデプロイする前に、非本番環境で新しい設定をテストします。

ストレージドライバー設定の更新の詳細については、[オブジェクトストレージの使用](https://docs.gitlab.com/administration/packages/container_registry/#use-object-storage)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### 保護された変数とマルチプロジェクトパイプラインの動作変更

<div class="deprecation-notes">

- GitLab <span class="milestone">16.10</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/432328)を参照してください。

</div>

プロジェクトで十分な権限を持つユーザーが保護された変数を安全でないプロジェクトに転送できる場合があるため、この変更は、保護された変数の値が公開されるリスクを最小限に抑えるセキュリティ強化です。

ダウンストリームのパイプラインを介して[CI/CD変数を転送する](https://docs.gitlab.com/ci/pipelines/downstream_pipelines/#pass-cicd-variables-to-a-downstream-pipeline)ことは一部のワークフローで役立ちますが、[保護された変数](https://docs.gitlab.com/ci/variables/#protect-a-cicd-variable)には追加の注意が必要です。これらは、特定の保護ブランチまたはタグでのみ使用することを目的としています。

GitLab 19.0では、保護された変数が特定の状況でのみ渡されるように、変数の転送が更新されます:

- プロジェクトレベルの保護された変数は、同じプロジェクト（子パイプライン）のダウンストリームのパイプラインにのみ転送できます。
- グループレベルの保護された変数は、ソースプロジェクトと同じグループに属するプロジェクトのダウンストリームのパイプラインにのみ転送できます。

パイプラインが保護された変数の転送に依存している場合は、上記の2つのオプションに準拠するように設定を更新するか、保護された変数の転送を回避します。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### コンプライアンスパイプライン

<div class="deprecation-notes">

- GitLab <span class="milestone">17.3</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/groups/gitlab-org/-/epics/11275)を参照してください。

</div>

現在、コンプライアンスまたはセキュリティ関連のジョブがプロジェクトパイプラインで確実に実行されるようにするには、次の2つの方法があります。

- [コンプライアンスパイプライン](https://docs.gitlab.com/user/group/compliance_pipelines/)。
- [セキュリティポリシー](https://docs.gitlab.com/user/application_security/policies/)。

プロジェクトのすべてのパイプラインで必要なジョブが確実に実行されるようにするための一元的な場所を提供するために、GitLab 17.3でコンプライアンスパイプラインを非推奨にし、GitLab 19.0でこの機能を削除します。

お客様は、できるだけ早くコンプライアンスパイプラインから新しい[パイプライン実行ポリシータイプ](https://docs.gitlab.com/user/application_security/policies/pipeline_execution_policies/)に移行する必要があります。詳細については、[移行ガイド](https://docs.gitlab.com/user/group/compliance_pipelines/#pipeline-execution-policies-migration)と[ブログ記事](https://about.gitlab.com/blog/2024/10/01/why-gitlab-is-deprecating-compliance-pipelines-in-favor-of-security-policies/)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### カバレッジファジングは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">18.0</span>で発表
- GitLab <span class="milestone">18.0</span>でサポート終了
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/517841)を参照してください。

</div>

カバレッジファジングは非推奨となり、GitLab 18.0以降はサポートされません。この機能は、GitLab 19.0で完全に削除されます。

カバレッジファジングでは、いくつかのオープンソースファザーがGitLabに統合されました。影響を受ける場合は、オープンソースファザーをスタンドアロンアプリケーションとして統合するか、[GitLab Advanced SAST](https://docs.gitlab.com/ee/user/application_security/sast/gitlab_advanced_sast.html)のような別のセキュリティ機能に移行することができます。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### JavaScriptベンダーライブラリの依存関係スキャン

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/501308)を参照してください。

</div>

依存関係スキャンのGemnasiumアナライザーによって提供される[JavaScriptベンダーライブラリの依存関係スキャン](https://docs.gitlab.com/user/application_security/dependency_scanning/#javascript)機能は、GitLab 17.9で非推奨になります。

この機能はGemnasiumアナライザーの使用時は引き続き機能しますが、新しい依存関係スキャンアナライザーに移行すると使用できなくなります。詳細については、[移行ガイド](https://docs.gitlab.com/user/application_security/dependency_scanning/migration_guide_to_sbom_based_scans/)を参照してください。

代替機能は[ベンダーライブラリの依存関係スキャン](https://gitlab.com/groups/gitlab-org/-/epics/7186)で開発されますが、その提供のタイムラインは設定されていません。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### GitLab SBOM脆弱性スキャナーへの依存関係スキャンのアップグレード

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/501308)を参照してください。

</div>

依存関係スキャン機能は、GitLab SBOM脆弱性スキャナーにアップグレードされます。この変更の一環として、Gemnasiumアナライザー（以前はCI/CDパイプラインで使用）はGitLab 17.9で非推奨になります。

これは、[SBOMを使用した依存関係スキャン](https://docs.gitlab.com/user/application_security/dependency_scanning/dependency_scanning_sbom/)機能と、依存関係とその関係（依存関係グラフ）の検出に重点を置いた[新しい依存関係スキャンアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/dependency-scanning)に置き換えられます。このアップグレードは基本的な変更を表しています。新しいシステムは、CIパイプライン内でセキュリティ分析を実行する代わりに、すでに[継続的な脆弱性スキャン](https://docs.gitlab.com/user/application_security/continuous_vulnerability_scanning/)で使用されているGitLabの組み込みSBOM脆弱性スキャナーを使用します。

GitLab 17.9の時点では、この新機能はベータ版です。したがって、一般公開されるまで、GitLabは引き続きGemnasiumアナライザーをサポートします。その場合に限り、Gemnasiumアナライザーは[サポート終了](https://docs.gitlab.com/update/terminology/#end-of-support)となります。

このアップグレードでは大幅な変更と機能削除が導入されるため、自動的には実装されません。Gemnasiumアナライザーを使用する既存のCI/CDジョブは、CI設定の混乱を防ぐために、デフォルトで引き続き機能します。

以下に示す詳細な変更をよく確認し、移行を支援するために[移行ガイド](https://docs.gitlab.com/user/application_security/dependency_scanning/migration_guide_to_sbom_based_scans/)を参照してください。

- CI/CD設定の混乱を防ぐために、アプリケーションが安定した依存関係スキャンCI/CDテンプレート（`Dependency-Scanning.gitlab-ci.yml`）を使用している場合、依存関係スキャンはGemnasiumアナライザーに基づく既存のCI/CDジョブのみを使用します。
- アプリケーションが最新の依存関係スキャンCI/CDテンプレート（`Dependency-Scanning.latest.gitlab-ci.yml`）を使用している場合、依存関係スキャンはGemnasiumアナライザーに基づく既存のCI/CDジョブを使用し、新しい依存関係スキャンアナライザーも、サポートされているファイルタイプで実行されます。また、すべてのプロジェクトに対して新しい依存関係スキャンアナライザーを強制的に適用することを選択することもできます。
- この機能が成熟するにつれて、他の移行パスも検討される可能性があります。
- [Gemnasiumアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/gemnasium/)プロジェクト、および対応するコンテナイメージ（すべてのタグとバリアント）: `gemnasium`、`gemnasium-maven`、`gemnasium-python`は非推奨となります。これらのイメージはGitLabコンテナレジストリから削除されません。
- Gemnasiumアナライザーに関連付けられている次のCI/CD変数も非推奨です。これらの変数はGemnasiumアナライザーの使用時は引き続き機能しますが、新しい依存関係スキャンアナライザーに移行した後は有効になりません。変数も別のコンテキストで使用されている場合、非推奨は依存関係スキャン機能にのみ適用されます（たとえば、`GOOS`と`GOARCH`は依存関係スキャン機能に固有ではありません）。`DS_EXCLUDED_ANALYZERS`、`DS_GRADLE_RESOLUTION_POLICY`、`DS_IMAGE_SUFFIX`、`DS_JAVA_VERSION`、`DS_PIP_DEPENDENCY_PATH`、`DS_PIP_VERSION`、`DS_REMEDIATE_TIMEOUT`、`DS_REMEDIATE`、`GEMNASIUM_DB_LOCAL_PATH`、`GEMNASIUM_DB_REF_NAME`、`GEMNASIUM_DB_REMOTE_URL`、`GEMNASIUM_DB_UPDATE_DISABLED`、`GEMNASIUM_LIBRARY_SCAN_ENABLED`、`GOARCH`、`GOFLAGS`、`GOOS`、`GOPRIVATE`、`GRADLE_CLI_OPTS`、`GRADLE_PLUGIN_INIT_PATH`、`MAVEN_CLI_OPTS`、`PIP_EXTRA_INDEX_URL`、`PIP_INDEX_URL`、`PIPENV_PYPI_MIRROR`、`SBT_CLI_OPTS`。
- 次の[CI/CDコンポーネント](https://gitlab.com/components/dependency-scanning/#components)は非推奨です: Android、Rust、Swift、Cocoapods。これらは、サポートされているすべての言語とパッケージマネージャーを網羅する[メインの依存関係スキャンCI/CDコンポーネント](https://gitlab.com/components/dependency-scanning/-/tree/main/templates/main?ref_type=heads)に置き換えられます。
- [脆弱性の解決](https://docs.gitlab.com/user/application_security/vulnerabilities/#resolve-a-vulnerability)機能**（Yarn プロジェクトの場合）**は、GitLab 17.9で非推奨になります。この機能はGemnasiumアナライザーの使用時は引き続き機能しますが、新しい依存関係スキャンアナライザーに移行すると使用できなくなります。詳細については、対応する[非推奨のお知らせ](https://docs.gitlab.com/update/deprecations/#resolve-a-vulnerability-for-dependency-scanning-on-yarn-projects)を参照してください。
- [JavaScriptベンダーライブラリの依存関係スキャン](https://docs.gitlab.com/user/application_security/dependency_scanning/#javascript)機能は、GitLab 17.9で非推奨になります。この機能はGemnasiumアナライザーの使用時は引き続き機能しますが、新しい依存関係スキャンアナライザーに移行すると使用できなくなります。詳細については、対応する[非推奨のお知らせ](https://docs.gitlab.com/update/deprecations/#dependency-scanning-for-javascript-vendored-libraries)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### 監査イベントAPIでキーセットページネーションを適用する

<div class="deprecation-notes">

- GitLab <span class="milestone">17.8</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/382338)を参照してください。

</div>

インスタンス、グループ、およびプロジェクトの監査イベントAPIは現在、オプションのキーセットページネーションをサポートしています。GitLab 18.0では、これらのAPIでキーセットページネーションを適用します。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### KubernetesとのGitLab Self-Managed証明書ベースのインテグレーション

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)を参照してください。

</div>

Kubernetesとの証明書ベースのインテグレーションは[非推奨となり、削除されます](https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/)。

GitLab Self-Managedの場合、GitLab 15.0で[機能フラグ](https://docs.gitlab.com/administration/feature_flags/#enable-or-disable-the-feature)`certificate_based_clusters`を導入するため、証明書ベースのインテグレーションを有効にしたままにすることができます。ただし、機能フラグはデフォルトで無効になるため、この変更は**破壊的な変更**です。

GitLab 19.0では、機能とその関連コードの両方を削除します。19.0で最終的に削除されるまで、このインテグレーションに基づいて構築された機能は、機能フラグを有効にすると引き続き動作します。機能が削除されるまで、GitLabは発生したセキュリティおよび重大な問題を修正し続けます。

Kubernatesとのより堅牢で安全かつ信頼性の高いインテグレーションを行うには、[Kubernetes用エージェント](https://docs.gitlab.com/user/clusters/agent/)を使用してKubernetesクラスターをGitLabに接続することをお勧めします。[移行方法はこちらです。](https://docs.gitlab.com/user/infrastructure/clusters/migrate_to_gitlab_agent/)

明示的な削除日が設定されていますが、新しいソリューションに機能の同等性が備わるまでは、この機能を削除する予定はありません。削除のブロッカーの詳細については、[この問題](https://gitlab.com/gitlab-org/configure/general/-/issues/199)を参照してください。

この非推奨化に関する最新情報と詳細については、[このエピック](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)に従ってください。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### パイプラインサブスクリプション

<div class="deprecation-notes">

- GitLab <span class="milestone">17.6</span>で発表
- GitLab <span class="milestone">18.0</span>でサポート終了
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/501460)を参照してください。

</div>

[パイプラインサブスクリプション](https://docs.gitlab.com/ci/pipelines/#trigger-a-pipeline-when-an-upstream-project-is-rebuilt-deprecated)機能は非推奨となり、GitLab 18.0以降はサポートされなくなり、GitLab 19.0で完全に削除される予定です。パイプラインサブスクリプションは、アップストリームプロジェクトのタグパイプラインに基づいてダウンストリームパイプラインを実行するために使用されます。

代わりに、別のパイプラインが実行されたときにパイプラインをトリガーするには、[パイプライントリガー トークンを利用したCI/CDジョブ](https://docs.gitlab.com/ci/triggers/#use-a-cicd-job)を使用してください。この方法は、パイプラインサブスクリプションよりも信頼性が高く、柔軟性があります。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### Yarnプロジェクトでの依存関係スキャンの脆弱性を解決する

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/501308)を参照してください。

</div>

依存関係スキャンのGemnasiumアナライザーによって提供されるYarnプロジェクトの[脆弱性の解決](https://docs.gitlab.com/user/application_security/vulnerabilities/#resolve-a-vulnerability)機能は、GitLab 17.9で非推奨になります。

この機能はGemnasiumアナライザーの使用時は引き続き機能しますが、新しい依存関係スキャンアナライザーに移行すると使用できなくなります。詳細については、[移行ガイド](https://docs.gitlab.com/user/application_security/dependency_scanning/migration_guide_to_sbom_based_scans/)を参照してください。

代替機能は[自動修正ビジョン](https://gitlab.com/groups/gitlab-org/-/epics/7186)の一部として計画されていますが、その提供のタイムラインは設定されていません。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### 単一のデータベースの実行は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.1</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/411239)を参照してください。

</div>

GitLab 19.0以降では、[CI機能用に個別のデータベース](https://gitlab.com/groups/gitlab-org/-/epics/7509)が必要になります。ほとんどのデプロイメントで管理が容易になるため、両方のデータベースを同じPostgresインスタンスで実行することをお勧めします。

この変更により、GitLab.comのような最大のGitLabインスタンスのスケーラビリティが向上します。この変更は、すべてのインストール方法、つまり、Omnibus GitLab、GitLab Helm チャート、GitLab Operator、GitLab Dockerイメージ、およびソースからのインストールに適用されます。GitLab 19.0にアップグレードする前に、2つのデータベースに[移行](https://docs.gitlab.com/administration/postgresql/multiple_databases/)していることを確認してください。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### コンテナレジストリのS3ストレージドライバー（AWS SDK v1）

<div class="deprecation-notes">

- GitLab <span class="milestone">17.10</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/523095)を参照してください。

</div>

AWS SDK v1を使用するコンテナレジストリのS3ストレージドライバーは非推奨となり、GitLab 19.0で削除されます。コンテナレジストリにS3オブジェクトストレージを使用している場合は、新しい`s3_v2`ドライバーを使用するように設定を更新する必要があります。

`s3_v2`ストレージドライバーはAWS SDK v2に基づいており、パフォーマンスの向上、セキュリティの強化、AWSからの継続的なサポートを提供します。これは、2025年7月31日にサポートが終了する非推奨の[AWS SDK v1](https://aws.amazon.com/blogs/developer/announcing-end-of-support-for-aws-sdk-for-go-v1-on-july-31-2025/)を置き換えるために、2025年5月から利用可能になります。

`s3_v2`ドライバーに移行するには:

1. `s3`の代わりに、`s3_v2`設定を使用するようにレジストリ設定ファイルを更新します。
1. AWS SDK v2は署名バージョン4のみをサポートしているため、移行がまだの場合は、認証のために署名バージョン2から署名バージョン4に移行します。
1. 本番環境にデプロイする前に、非本番環境で設定をテストします。

ストレージドライバー設定の更新の詳細については、[オブジェクトストレージの使用](https://docs.gitlab.com/administration/packages/container_registry/#use-object-storage)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### 単一データベース接続は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/387898)を参照してください。

</div>

以前は、[GitLabデータベース](https://docs.gitlab.com/omnibus/settings/database/)の設定には、単一の`main:`セクションがありました。これは非推奨となります。新しい設定には、`main:`セクションと`ci:`セクションの両方があります。

この非推奨化は、ソースからGitLabをコンパイルするユーザーに影響を与えます。これらのユーザーは、[`ci:`セクションを追加](https://docs.gitlab.com/install/installation/#configure-gitlab-db-settings)する必要があります。Omnibus、Helmチャート、およびOperatorは、GitLab 16.0以降、この設定を自動的に処理します。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### Slack通知インテグレーション

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/435909)を参照してください。

</div>

すべてのSlack機能をGitLab for Slackアプリに統合しているため、Slack通知インテグレーションは非推奨となりました。Slackワークスペースへの通知を管理するには、GitLab for Slackアプリを使用します。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### `Project.services` GraphQLフィールドは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/388424)を参照してください。

</div>

`Project.services` GraphQLフィールドは非推奨です。代わりに、[問題389904](https://gitlab.com/gitlab-org/gitlab/-/issues/389904)で`Project.integrations`フィールドが提案されています。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### `scanResultPolicies` GraphQLフィールドは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.8</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/439199)を参照してください。

</div>

16.10では、スキャン結果ポリシーの名前がマージリクエスト承認ポリシーに変更され、ポリシータイプに対するスコープと機能の変更がより正確に反映されるようになりました。

その結果、GraphQLエンドポイントを更新しました。`scanResultPolicies`の代わりに`approvalPolicies`を使用してください。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### `incoming_email`および`service_desk_email`の`sidekiq`配信メソッドは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.0</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/398132)を参照してください。

</div>

`incoming_email`および`service_desk_email`の`sidekiq`配信メソッドは非推奨であり、GitLab 19.0で削除される予定です。

GitLabは、`mail_room`と呼ばれる別のプロセスを使用して、メールをインジェストします。現在、GitLab管理者は、`mail_room`からインジェストされたメールをGitLabに配信するために、`sidekiq`または`webhook`配信メソッドを使用するようにGitLabインスタンスを設定できます。

`mail_room`は、非推奨の`sidekiq`配信メソッドを使用して、ジョブデータを GitLab Redisキューに直接書き込みます。これは、配信メソッドとRedisの設定が強く結合していることを意味します。もう 1 つのデメリットは、ジョブペイロード圧縮などのフレームワークの最適化が見送られることです。

`mail_room`は、`webhook`配信メソッドを使用して、インジェストされたメール本文をGitLab APIにプッシュします。この方法では、`mail_room`はRedisの設定を知る必要がなく、GitLabアプリケーションが処理ジョブを追加します。`mail_room`は共有シークレットキーで認証します。

Omnibusインストールを再設定すると、このシークレットキーファイルが自動的に生成されるため、シークレットファイル構成設定は必要ありません。

次のコマンドを実行し、`incoming_email_secret_file`および`service_desk_email_secret_file`でシークレットファイルを参照することにより、カスタムシークレットキーファイル（32文字の Base64エンコード）を設定できます（常に絶対パスを指定）。

```shell
echo $( ruby -rsecurerandom -e "puts SecureRandom.base64(32)" ) > ~/.gitlab-mailroom-secret
```

複数のマシンでGitLabを実行する場合は、マシンごとにシークレットキーファイルを用意する必要があります。

GitLab管理者は、`sidekiq`の代わりに、`incoming_email_delivery_method`および`service_desk_email_delivery_method`用のWebhook配信メソッドに切り替えることをお勧めします。

[問題393157](https://gitlab.com/gitlab-org/gitlab/-/issues/393157)では、一般的にメールのインジェストの改善を追跡します。これにより、インフラストラクチャのセットアップが簡素化され、近い将来、GitLabの管理方法がいくつかの点で改善されることを期待しています。

</div>

<div class="deprecation breaking-change" data-milestone="19.0">

### `workflow:rules`テンプレート

<div class="deprecation-notes">

- GitLab <span class="milestone">17.0</span>で発表
- GitLab <span class="milestone">19.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/456394)を参照してください。

</div>

[`workflow:rules`](https://docs.gitlab.com/ci/yaml/workflow/#workflowrules-templates)テンプレートは非推奨となり、使用は推奨されなくなっています。これらのテンプレートを使用すると、パイプラインの柔軟性が大幅に制限され、新しい`workflow`機能を使いにくくなります。

これは、CI/CDテンプレートから移行し、[CI/CDコンポーネント](https://docs.gitlab.com/ci/components/)を優先するための小さな一歩です。[CI/CDカタログ](https://docs.gitlab.com/ci/components/#cicd-catalog)で代替を検索するか、パイプラインに明示的に[`workflow:rules`を追加](https://docs.gitlab.com/ci/yaml/workflow/)できます。

</div>
</div>

<div class="milestone-wrapper" data-milestone="18.3">

## GitLab 18.3

<div class="deprecation breaking-change" data-milestone="18.3">

### Ubuntu 20.04用のLinuxパッケージ

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.3</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8915)を参照してください。

</div>

Ubuntu 20.04のUbuntu標準サポートは[2025年5月に終了](https://wiki.ubuntu.com/Releases)します。

したがって、GitLab 18.3以降、Linuxパッケージインストール用のUbuntu 20.04ディストリビューションのパッケージは提供されなくなります。GitLab 18.2が、Ubuntu 20.04用のLinuxパッケージを含む最後のGitLabバージョンになります。継続的なサポートを受けるには、Ubuntu 22.04にアップグレードする必要があります。

</div>
</div>

<div class="milestone-wrapper" data-milestone="18.0">

## GitLab 18.0

<div class="deprecation breaking-change" data-milestone="18.0">

### API Discoveryはデフォルトでブランチパイプラインを使用します

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/515487)を参照してください。

</div>

GitLab 18.0では、API Discovery のCI/CDテンプレート（`API-Discovery.gitlab-ci.yml`）のデフォルトの動作を更新します。

GitLab 18.0より前では、このテンプレートはMRが開いている場合にデフォルトで[マージリクエスト（MR）パイプライン](https://docs.gitlab.com/ci/pipelines/merge_request_pipelines/)でジョブが実行されるように設定します。GitLab 18.0以降、このテンプレートの動作を、他のASTスキャナーの[安定版テンプレートエディション](https://docs.gitlab.com/user/application_security/detect/roll_out_security_scanning/#template-editions)の動作に合わせます。

- デフォルトでは、テンプレートはブランチパイプラインでスキャンジョブを実行します。
- MRが開いている場合に代わりにMRパイプラインを使用するには、CI/CD変数`AST_ENABLE_MR_PIPELINES: true`を設定します。この新しい変数の実装は、[問題410880](https://gitlab.com/gitlab-org/gitlab/-/issues/410880)で追跡されます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Amazon S3署名バージョン2

<div class="deprecation-notes">

- GitLab <span class="milestone">17.8</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/container-registry/-/issues/1449)を参照してください。

</div>

署名バージョン2を使用してコンテナレジストリでAmazon S3バケットへのリクエストを認証することは非推奨です。

継続的な互換性とセキュリティを確保するには、署名バージョン4に移行してください。この変更には、S3バケット構成設定の更新と、GitLabコンテナレジストリ設定が署名バージョン4に対応していることの確認が必要です。

移行するには:

1. GitLabコンテナレジストリ設定で、S3ストレージバックエンドの設定を確認します。
1. 設定されている場合は、`v4auth: false`オプションを削除します。
1. 既存の認証情報がv4認証で動作することを確認します。

これらの変更を加えた後に問題が発生した場合は、AWS認証情報の再生成を試してください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### アプリケーションセキュリティテストアナライザーのメジャーバージョンの更新

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/513417)を参照してください。

</div>

アプリケーションセキュリティテストステージでは、GitLab 18.0のリリースと連携して、アナライザーのメジャーバージョンが引き上げられます。

デフォルトの組み込みテンプレートを使用していない場合、またはアナライザーのバージョンを固定している場合は、固定バージョンを削除するか、最新のメジャーバージョンに更新するために、CI/CDジョブ定義を更新する必要があります。

GitLab 17.0からGitLab 17.11のユーザーは、GitLab 18.0のリリースまでアナライザーの更新を引き続き利用できます。その後、新しく修正されたバグとリリースされた機能は、アナライザーの新しいメジャーバージョンでのみリリースされます。

メンテナンスポリシーに従い、バグや機能を非推奨バージョンにバックポートすることはありません。必要に応じて、セキュリティパッチは最新の3つのマイナーリリース内でバックポートされます。

具体的には、次のアナライザーは非推奨となっており、GitLab 18.0リリース以降は更新されなくなります:

- GitLab Advanced SAST: バージョン1
- コンテナスキャン: バージョン7
- Gemnasium: バージョン5
- DAST: バージョン5
- DAST API: バージョン4
- Fuzz API: バージョン4
- IaC スキャン: バージョン5
- パイプラインシークレット検出: バージョン6
- 静的アプリケーションセキュリティテスト（SAST）: [すべてのアナライザー](https://docs.gitlab.com/user/application_security/sast/analyzers/)のバージョン5
  - `kics`
  - `kubesec`
  - `pmd-apex`
  - `semgrep`
  - `sobelow`
  - `spotbugs`

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### 今後および開始済みのマイルストーンフィルターの動作変更

<div class="deprecation-notes">

- GitLab <span class="milestone">17.7</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/501294)を参照してください。

</div>

「今後」および「開始済み」の特別なフィルターの動作は、今後の GitLabメジャーリリース 18.0で変更される予定です。両方のフィルターの新しい動作は、[問題429728](https://gitlab.com/gitlab-org/gitlab/-/issues/429728#proposed-issue-filter-logic-for-upcoming-and-started-milestones)に概説されています。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### CI/CDジョブトークン - **許可されたグループとプロジェクト**の許可リストの適用

<div class="deprecation-notes">

- GitLab <span class="milestone">16.5</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/383084)を参照してください。

</div>

GitLab 15.9で導入された[**許可されたグループとプロジェクト**設定](https://docs.gitlab.com/ci/jobs/ci_job_token/#add-a-group-or-project-to-the-job-token-allowlist)（GitLab 16.3で**このプロジェクト_への_アクセスを制限**から名前が変更されました）を使用すると、プロジェクトへのCI/CDジョブトークンアクセスを制御できます。**このプロジェクトと許可リスト内のすべてのグループおよびプロジェクトのみ**に設定すると、許可リストに追加されたグループまたはプロジェクトのみがジョブトークンを使用してプロジェクトにアクセスできます。

GitLab 15.9より前に作成されたプロジェクトでは、許可リストはデフォルトで無効になっており（[**すべてのグループとプロジェクト**](https://docs.gitlab.com/ci/jobs/ci_job_token/#allow-any-project-to-access-your-project)アクセス設定が選択されています）、どのプロジェクトからでもジョブトークンアクセスを許可していました。許可リストは、すべての新しいプロジェクトでデフォルトで有効になっています。古いプロジェクトでは、許可リストが無効になっているか、アクセスを無制限にするために**すべてのグループとプロジェクト**オプションを手動で選択している可能性があります。

GitLab 17.6以降、GitLab Self-ManagedおよびGitLab Dedicatedインスタンスの管理者は、オプションで[すべてのプロジェクトに対してこのより安全な設定を適用](https://docs.gitlab.com/administration/settings/continuous_integration/#job-token-permissions)できます。この設定により、プロジェクトメンテナーは**すべてのグループとプロジェクト**を選択できなくなります。この変更により、プロジェクト間のセキュリティレベルが向上します。GitLab 18.0では、この設定はGitLab.com、GitLab Self-Managed、およびGitLab Dedicatedでデフォルトで有効になります。

この変更に備えて、クロスプロジェクト認証にジョブトークンを使用するプロジェクトメンテナーは、プロジェクトの**許可されたグループとプロジェクト**許可リストを設定する必要があります。次に、設定を**このプロジェクトと許可リスト内のすべてのグループおよびプロジェクトのみ**に変更する必要があります。

CI/CDジョブトークンで認証してプロジェクトにアクセスする必要があるプロジェクトを特定するために、GitLab 17.6では、プロジェクトへの[ジョブトークン認証を追跡](https://about.gitlab.com/releases/2024/11/21/gitlab-17-6-released/#track-cicd-job-token-authentications)する方法も導入しました。そのデータを使用して、CI/CIジョブトークン許可リストを設定できます。

GitLab 17.10では、ジョブトークン認証ログからCI/CDジョブトークン許可リストを自動的に設定する[移行ツール](https://docs.gitlab.com/ee/ci/jobs/ci_job_token.html#auto-populate-a-projects-allowlist)を導入しました。[GitLab 18.0で許可リストが一般的に適用](https://docs.gitlab.com/ee/update/deprecations.html#cicd-job-token---authorized-groups-and-projects-allowlist-enforcement)される前に、この移行ツールを使用して許可リストを設定して使用することをお勧めします。GitLab 18.0では、以前に発表されたように、許可リストの自動設定と適用が行われます。

この移行ツールは、GitLab 18.3で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### CI/CDジョブトークン - **プロジェクトからのアクセスを制限**設定の削除

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/395708)を参照してください。

</div>

GitLab 14.4では、より安全にするために、[プロジェクトのCI/CDジョブトークン（`CI_JOB_TOKEN`）_からの_アクセスを制限](https://docs.gitlab.com/ci/jobs/ci_job_token/#limit-your-projects-job-token-access)する設定を導入しました。この設定は、**CI_JOB_TOKENアクセスを制限**と呼ばれていました。GitLab 16.3では、明確にするために、この設定の名前を**このプロジェクト_からの_アクセスを制限**に変更しました。

GitLab 15.9では、[**許可されたグループとプロジェクト**](https://docs.gitlab.com/ci/jobs/ci_job_token/#add-a-group-or-project-to-the-job-token-allowlist)と呼ばれる代替設定を導入しました。この設定は、許可リストを使用して、プロジェクト_への_ジョブトークンアクセスを制御します。この新しい設定は、元の設定よりも大幅に改善されています。最初のイテレーションは GitLab 16.0で非推奨となり、GitLab 18.0で削除される予定です。

**このプロジェクト_からの_アクセスを制限**設定は、すべての新しいプロジェクトでデフォルトで無効になっています。GitLab 16.0以降では、どのプロジェクトでも無効にした後、この設定を再度有効にすることはできません。代わりに、**許可されたグループとプロジェクト**設定を使用して、プロジェクトへのジョブトークンアクセスを制御します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### CodeClimateベースのコード品質スキャンを削除

<div class="deprecation-notes">

- GitLab <span class="milestone">17.3</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/471677)を参照してください。

</div>

GitLab 18.0では、CodeClimateベースのコード品質スキャンを削除します。その代わりに、CI/CDパイプラインで品質ツールを直接使用し、[ツールのレポートをアーティファクトとして提供](https://docs.gitlab.com/ci/testing/code_quality/#import-code-quality-results-from-a-cicd-job)する必要があります。多くのツールは必要なレポート形式をすでにサポートしており、[文書化された手順](https://docs.gitlab.com/ci/testing/code_quality/#integrate-common-tools-with-code-quality)に従って統合できます。

この変更は、次の方法で実装する予定です。

1. スキャンを実行しないように[`Code-Quality.gitlab-ci.yml` CI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Code-Quality.gitlab-ci.yml)を変更します。現在、このテンプレートはCodeClimateベースのスキャンを実行しています。(18.0以降もテンプレートを`include`パイプラインへの影響を軽減するために、テンプレートを削除するのではなく、テンプレートを変更する予定です。)
1. Auto DevOpsの一部として、CodeClimateベースのスキャンを実行しなくなります。

CodeClimateベースのスキャンは、ただちに[限定的な更新](https://docs.gitlab.com/update/terminology/#deprecation)のみを受け取ります。GitLab 18.0でサポートが終了した後、それ以上の更新は提供しません。ただし、以前に公開されたコンテナイメージを削除したり、カスタムCI/CDパイプラインジョブ定義を使用してそれらを実行する機能を削除したりすることはありません。

詳細については、[品質違反のコードをスキャンする](https://docs.gitlab.com/ci/testing/code_quality/#scan-code-for-quality-violations)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### コンテナスキャンのデフォルトの重大度しきい値を`medium`に設定

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/515358)を参照してください。

</div>

コンテナスキャンのセキュリティ機能は多くのセキュリティ検出を生成しますが、このボリュームはエンジニアリングチームによる管理が難しいことがよくあります。重大度しきい値を`medium`に変更することで、`medium`未満の重大度を持つ検出が報告されない、より妥当なデフォルトをユーザーに提供します。GitLab 18.0以降、`CS_SEVERITY_THRESHOLD`環境変数のデフォルト値は、`unknown`ではなく`medium`に設定されます。その結果、重大度レベルが`low`および`unknown`のセキュリティ検出は、デフォルトでは報告されなくなります。そのため、デフォルトブランチで以前は報告されていたこれらの重大度の脆弱性は、コンテナスキャンの次回の実行時に、検出されなくなったものとしてマークされます。これらの検出を引き続き表示するには、`CS_SEVERITY_THRESHOLD`変数を目的のレベルに設定する必要があります。

</div>

<div class="deprecation " data-milestone="18.0">

### DASTの`dast_crawl_extract_element_timeout`および`dast_crawl_search_element_timeout`変数は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/517250)を参照してください。

</div>

DAST変数`DAST_CRAWL_EXTRACT_ELEMENT_TIMEOUT`および`DAST_CRAWL_SEARCH_ELEMENT_TIMEOUT`は非推奨となり、GitLab 18.0で削除されます。これらの変数は導入時、特定のブラウザ操作に対して、きめ細かいタイムアウト制御を提供していました。これらのインタラクションは現在、共通のタイムアウト値によって管理されているため、変数は不要になっています。さらに、根本的な実装の問題により、DASTブラウザベースのアナライザーの導入以来、変数は機能していません。これらの2つの変数を削除すると、DAST設定が簡素化され、ユーザーのオンボーディングエクスペリエンスが向上します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### DASTの`dast_devtools_api_timeout`変数のデフォルト値の低下

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/517254)を参照してください。

</div>

`DAST_DEVTOOLS_API_TIMEOUT`環境変数は、DASTスキャンがブラウザからの応答を待機する時間を決定します。GitLab 18.0より前は、変数の静的な値は45秒でした。GitLab 18.0以降、`DAST_DEVTOOLS_API_TIMEOUT`環境変数は動的な値を持ち、これは他のタイムアウト設定に基づいて計算されます。ほとんどの場合、45秒の値は、多くのスキャナー機能のタイムアウト値を上回っていました。動的に計算された値により、`DAST_DEVTOOLS_API_TIMEOUT`変数が適用されるケースが増え、より有用になります。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GitLab Runnerの`FF_GIT_URLS_WITHOUT_TOKENS`機能フラグをデフォルトで`true`に設定

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/518709)を参照してください。

</div>

GitLab Runner 18.0では、トークンリークの可能性を制限するために、`FF_GIT_URLS_WITHOUT_TOKENS`機能フラグのデフォルト値が`true`に変更されます。

この変更は、次のユーザーに影響します。

- ジョブ間でGit認証情報状態を共有するexecutor（たとえば、shell executor）を使用するユーザー。
- キャッシュされたGit認証情報ヘルパーがインストールされているユーザー（たとえば、[gitforwindows](https://gitforwindows.org/)は、デフォルトでシステム全体に[Git Credential Manager（GCM）](https://github.com/git-ecosystem/git-credential-manager)をインストールします）。
- ビルドを並行して実行するユーザー。

問題を回避するには、キャッシュされたGit認証情報ヘルパーをGitLab Runnerで使用しないか、ジョブを分離された環境で実行するexecutorを使用するか、ジョブをシリアルでのみ実行するようにしてください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### 依存プロキシトークンスコープの適用

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/426887)を参照してください。

</div>

コンテナの依存プロキシは、スコープを検証せずに、パーソナルアクセストークンまたはグループアクセストークンを使用して、`docker login`および`docker pull`リクエストを受け入れます。

GitLab 18.0では、依存プロキシには、認証に`read_registry`と`write_registry`の両方のスコープが必要です。この変更後、これらのスコープを持たないトークンを使用した認証試行は拒否されます。

これは破壊的な変更です。アップグレードする前に、[必要なスコープ](https://docs.gitlab.com/user/packages/dependency_proxy/#authenticate-with-the-dependency-proxy-for-container-images)を持つ新しいアクセストークンを作成し、これらの新しいトークンを使用してワークフロー変数とスクリプトを更新します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### リポジトリX-RayのCIジョブ実装を非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">17.6</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/500146)を参照してください。

</div>

GitLab 18.0は、リポジトリX-Ray CIジョブを削除します。

- CIジョブを使用した[リポジトリX-Ray](https://docs.gitlab.com/user/project/repository/code_suggestions/repository_xray/)の初期実装は、GitLab 17.6で非推奨になっています。
- このCIジョブは、プロジェクトのデフォルトブランチに新しいコミットがプッシュされるとトリガーされる、自動化された[バックグラウンドジョブ](https://docs.gitlab.com/user/project/repository/code_suggestions/repository_xray/#how-repository-x-ray-works)に置き換えられます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### ライセンススキャンCI/CDアーティファクトレポートタイプを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/439301)を参照してください。

</div>

CI/CD[アーティファクトレポート](https://docs.gitlab.com/ci/yaml/artifacts_reports/)タイプはGitLab 16.9で非推奨となり、GitLab 18.0で削除されます。このキーワードを使用するCI/CD設定は、GitLab 18.0では機能しなくなります。

アーティファクトレポートタイプは、GitLab 16.3で従来のライセンススキャンCI/CDジョブが削除されたため、使用されなくなりました。代わりに、[CycloneDXファイルのライセンススキャン](https://docs.gitlab.com/user/compliance/license_scanning_of_cyclonedx_files/)を使用する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Terraform CI/CDテンプレートを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/438010)を参照してください。

</div>

Terraform CI/CDテンプレートは非推奨となり、GitLab 18.0で削除されます。これは、次のテンプレートに影響します。

- `Terraform.gitlab-ci.yml`
- `Terraform.latest.gitlab-ci.yml`
- `Terraform/Base.gitlab-ci.yml`
- `Terraform/Base.latest.gitlab-ci.yml`

GitLab 16.9では、非推奨についてユーザーに通知する新しいジョブがテンプレートに追加されました。この警告は、影響を受けるパイプラインでプレースホルダージョブを使用して`deprecated-and-will-be-removed-in-18.0`ジョブを上書きすることでオフにできます。

GitLabは、ジョブイメージ内の`terraform`バイナリを、BSLに基づいてライセンスされたバージョンに更新できません。

Terraformの使用を続行するには、[テンプレート](https://gitlab.com/gitlab-org/terraform-images)とTerraformイメージを複製し、必要に応じてメンテナンスします。GitLabには、カスタムビルドイメージへの移行に関する[詳細な手順](https://gitlab.com/gitlab-org/terraform-images)が用意されています。

代替として、GitLab.comで新しいOpenTofu CI/CDコンポーネントを使用するか、GitLab Self-Managedで新しいOpenTofu CI/CDテンプレートを使用することをお勧めします。CI/CDコンポーネントはGitLab Self-Managedではまだ利用できませんが、[問題#415638](https://gitlab.com/gitlab-org/gitlab/-/issues/415638)ではこの機能を追加することが提案されています。CI/CDコンポーネントがGitLab Self-Managedで利用可能になると、OpenTofu CI/CDテンプレートは削除されます。

新しいOpenTofu CI/CDコンポーネントの詳細については、[こちら](https://gitlab.com/components/opentofu)をご覧ください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### ライセンスメタデータ形式V1を非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/438477)を参照してください。

</div>

ライセンスメタデータ形式V1データセットは非推奨となっていて、GitLab 18.0で削除されます。

`package_metadata_synchronization`機能フラグを有効にしているユーザーは、GitLab 16.3以降にアップグレードし、機能フラグ設定を削除することをお勧めします。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `NamespaceProjectSortEnum` GraphQL APIでの`STORAGE` enumの非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">17.7</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/396284)を参照してください。

</div>

GitLab GraphQL APIの`NamespaceProjectSortEnum`の`STORAGE` enumは、GitLab 18.0で削除されます。

この変更に備えるため、`NamespaceProjectSortEnum`とやり取りするGraphQLクエリを確認し、更新することをお勧めします。`STORAGE`フィールドへの参照を`EXCESS_REPO_STORAGE_SIZE_DESC`に置き換えます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `ProjectMonthlyUsageType` GraphQL APIでの`name`フィールドの非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">17.7</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/381894)を参照してください。

</div>

GitLab GraphQL APIの`ProjectMonthlyUsageType`の`name`フィールドは、GitLab 18.0で削除されます。

この変更に備えるため、`ProjectMonthlyUsageType`とやり取りするGraphQLクエリを確認し、更新することをお勧めします。`name`フィールドへの参照を`project.name`に置き換えます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### サポートが終了したSASTジョブはCI/CDテンプレートから削除されます

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/519133)を参照してください。

</div>

GitLab 18.0では、以前のリリースでサポート終了になったアナライザージョブを削除するために、SAST CI/CDテンプレートを更新します。次のジョブは、`SAST.gitlab-ci.yml`および`SAST.latest.gitlab-ci.yml`から削除されます。

- `bandit-sast`（[15.4でサポート終了](#sast-analyzer-consolidation-and-cicd-template-changes)）
- `brakeman-sast`（[17.0でサポート終了](#sast-analyzer-coverage-changing-in-gitlab-170)）
- `eslint-sast`（[15.4でサポート終了](#sast-analyzer-consolidation-and-cicd-template-changes)）
- `flawfinder-sast`（[17.0でサポート終了](#sast-analyzer-coverage-changing-in-gitlab-170)）
- `gosec-sast`（[15.4でサポート終了](#sast-analyzer-consolidation-and-cicd-template-changes)）
- `mobsf-android-sast`（[17.0でサポート終了](#sast-analyzer-coverage-changing-in-gitlab-170)）
- `mobsf-ios-sast`（[17.0でサポート終了](#sast-analyzer-coverage-changing-in-gitlab-170)）
- `nodejs-scan-sast`（[17.0でサポート終了](#sast-analyzer-coverage-changing-in-gitlab-170)）
- `phpcs-security-audit-sast`（[17.0でサポート終了](#sast-analyzer-coverage-changing-in-gitlab-170)）
- `security-code-scan-sast`（[16.0でサポート終了](#sast-analyzer-coverage-changing-in-gitlab-160)）

各アナライザーがサポート終了になった時点で、デフォルトで実行されないようにジョブの`rules`を更新し、更新のリリースを停止しました。ただし、これらのジョブを引き続き使用するか、パイプラインに存在するジョブに依存するようにテンプレートをカスタマイズしている可能性があります。上記のジョブに依存するカスタマイズがある場合は、CI/CDパイプラインの混乱を回避するために、18.0にアップグレードする前に[必要なアクション](https://gitlab.com/gitlab-org/gitlab/-/issues/519133#actions-required)を実行してください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### ユーザープロファイルの表示レベル更新監査イベントタイプのスペルミスを修正

<div class="deprecation-notes">

- GitLab <span class="milestone">17.8</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/474386)を参照してください。

</div>

監査イベントタイプのスペルミスを修正するために、GitLab 18.0では、`user_profile_visiblity_updated`イベントタイプの名前を`user_profile_visibility_updated`に変更します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GitLab Advanced SASTはデフォルトで有効

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/513685)を参照してください。

</div>

GitLab 18.0では、GitLab Ultimateを使用しているプロジェクトでデフォルトで[GitLab Advanced SAST](https://docs.gitlab.com/user/application_security/sast/gitlab_advanced_sast)を有効にするように、[SAST CI/CDテンプレート](https://docs.gitlab.com/user/application_security/sast#stable-vs-latest-sast-templates)を更新します。この変更前は、CI/CD変数`GITLAB_ADVANCED_SAST_ENABLED`を`true`に設定した場合にのみ、GitLab Advanced SASTアナライザーが有効になっていました。

Advanced SASTは、クロスファイル、クロスファンクションスキャンと新しいルールセットを使用して、より正確な結果を提供します。Advanced SASTは[サポートされる言語](https://docs.gitlab.com/user/application_security/sast/gitlab_advanced_sast#supported-languages)のカバレッジを引き継ぎ、以前のスキャナーでのその言語のスキャンを無効にします。自動化されたプロセスは、各プロジェクトのデフォルトブランチでの最初のスキャン後に、以前のスキャナーからの結果が引き続き検出される場合はこの結果を移行します。

Advanced SASTでは、プロジェクトのスキャンが詳細に行われるため、プロジェクトのスキャンに時間がかかる場合があります。必要に応じて、CI/CD変数`GITLAB_ADVANCED_SAST_ENABLED`を`false`に設定して、[GitLab Advanced SAST](https://docs.gitlab.com/user/application_security/sast/gitlab_advanced_sast#disable-gitlab-advanced-sast-scanning)を無効にできます。この変数をプロジェクト、グループ、またはポリシーで今すぐ設定して、GitLab 18.0でデフォルトで高度なSASTが有効になるのを防ぐことができます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GraphQL APIのGitLab Runnerプラットフォームとセットアップ手順

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/387937)を参照してください。

</div>

GitLab Runnerプラットフォームとインストール手順を取得するための`runnerPlatforms`および`runnerSetup`クエリは非推奨となり、GraphQL APIから削除されます。インストール手順については、[GitLab Runnerドキュメント](https://docs.gitlab.com/runner/)を使用してください

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Runner OperatorのGitLab Runner登録トークン

<div class="deprecation-notes">

- GitLab <span class="milestone">15.6</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/382077)を参照してください。

</div>

OpenShiftおよびKubernetes Vanilla Operatorを使用してKubernetesにRunnerをインストールする[`runner-registration-token`](https://docs.gitlab.com/runner/install/operator/#install-the-kubernetes-operator)パラメータは非推奨になっています。代わりに、認証トークンがRunnerの登録に使用されます。登録トークン、および特定の設定引数のサポートは、GitLab 18.0で削除されます。詳細については、[新しいRunner登録ワークフローへの移行](https://docs.gitlab.com/ci/runners/new_creation_workflow/)を参照してください。認証トークンに対して無効になっている設定引数は次のとおりです。

- `--locked`
- `--access-level`
- `--run-untagged`
- `--tag-list`

この変更は破壊的な変更です。代わりに、`gitlab-runner register`コマンドで[認証トークン](https://docs.gitlab.com/ci/runners/runners_scope/)を使用する必要があります。

GitLab 17.0以降で[Runner登録ワークフローが中断されないようにする方法](https://docs.gitlab.com/ci/runners/new_creation_workflow/#prevent-your-runner-registration-workflow-from-breaking)も参照してください。

</div>

<div class="deprecation " data-milestone="18.0">

### Alpineバージョン用のGitLab Runnerのサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">17.7</span>で発表
- GitLab <span class="milestone">18.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38369)を参照してください。

</div>

GitLab Runnerバージョン17.7以降は、特定のバージョンの代わりに、単一のAlpineバージョン（`latest`）のみをサポートします。Alpineバージョン3.18および3.19は、記載されているEOL日までサポートされます。それに対して、LTSリリースであるUbuntu 20.04は、EOL日までサポートされ、その時点で最新のLTSリリースに移行します。

Alpineコンテナをアップグレードするときは、コンテナイメージが[サポートされている名前付きバージョン](https://docs.gitlab.com/runner/install/support-policy/)、`latest`（GitLab Runnerイメージの場合）、または`alpine-latest`（GitLab Runnerヘルパーイメージの場合）を使用していることを確認してください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GitLabチャートでのNGINXコントローラーイメージv1.3.1の使用

<div class="deprecation-notes">

- GitLab <span class="milestone">17.6</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5794)を参照してください。

</div>

GitLab 17.6では、GitLabチャートはデフォルトのNGINXコントローラーイメージをv1.11.2に更新しました。この新しいバージョンでは、Ingress NGINXバンドルされたサブチャートに追加された新しいRBACルールが必要です。

この変更は、17.5.1、17.4.3、および17.3.6にバックポートされています。

Helmキー`nginx-ingress.rbac.create`を`false`に設定して、RBACルールを自身で管理したいユーザーもいます。独自の RBAC ルールを管理しているユーザーが新しいv1.11.2バージョンを導入する前に、必要な新しいルールを追加するための時間を与えるために、`nginx-ingress.rbac.create: false`を検出し、新しいRBACルールを必要としないNGINXイメージv1.3.1をチャートで強制的に使用し続けるフォールバックメカニズムを実装しました。

独自のNGINX RBACルールを管理しているが、新しいNGINXコントローラーイメージv1.11.2をすぐに利用したい場合は、次の手順に従ってください。

1. [私たちが行ったように](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3901/diffs?commit_id=93a3cbdb5ad83db95e12fa6c2145df0800493d8b)、新しいRBACルールをクラスターに追加します。
1. `nginx-ingress.controller.image.disableFallback`をtrueに設定します。

GitLab 18.0で、このフォールバックサポートとNGINXコントローラーイメージv1.3.1のサポートを削除する予定です。

詳細については、[チャートのリリース ページ](https://docs.gitlab.com/charts/releases/8_0/#upgrade-to-86x-851-843-836)を参照してください。

</div>

<div class="deprecation " data-milestone="18.0">

### Gitalyレート制限

<div class="deprecation-notes">

- GitLab <span class="milestone">17.7</span>で発表
- GitLab <span class="milestone">18.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitaly/-/issues/5011)を参照してください。

</div>

Git操作とリポジトリのレイテンシーの性質が非常に変動的であるため、Gitaly [RPCベースのレート制限](https://docs.gitlab.com/administration/gitaly/monitoring/#monitor-gitaly-rate-limiting)は効果的ではありません。適切なレート制限の設定は難しく、有害なアクションでは1秒あたりに目に付く十分なリクエストが生成されることはまれなため、すぐに時代遅れになることがよくあります。

Gitaly はすでに [並行処理制限](https://docs.gitlab.com/administration/gitaly/concurrency_limiting/)と、本番環境でうまく機能することが証明されている[アダプティブ制限アドオン](https://docs.gitlab.com/administration/gitaly/concurrency_limiting/#adaptive-concurrency-limiting)をサポートしています。

Gitalyは外部ネットワークやロードバランサーなどの外部保護レイヤに直接公開されていないため、より優れた保護手段が提供され、レート制限の効果が低下します。

そのため、より信頼性の高い並行処理制限を優先して、レート制限を非推奨にしています。Gitaly RPCベースのレート制限はGitLab 18.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### to-doアイテムのGraphQL `target`フィールドを`targetEntity`に置換

<div class="deprecation-notes">

- GitLab <span class="milestone">17.4</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/484987)を参照してください。

</div>

特定の状況下では、to-doアイテムの`target`フィールドがnullになる可能性があります。GraphQLスキーマは現在、このフィールドを非nullとして宣言しています。新しい`targetEntity`フィールドはnullとすることができ、非nullの`target`フィールドを置き換えます。`currentUser.todos.target`フィールドを使用するGraphQLクエリを更新して、代わりに新しい`currentUser.todos.targetEntity`フィールドを使用するようにします。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GraphQLの`dependencyProxyTotalSizeInBytes`フィールドの非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.1</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/414236)を参照してください。

</div>

GraphQLを使用して、GitLab依存プロキシで使用されるストレージの量をクエリできます。ただし、`dependencyProxyTotalSizeInBytes`フィールドは約2ギガバイトに制限されており、依存プロキシにとっては必ずしも十分な大きさではありません。その結果、`dependencyProxyTotalSizeInBytes`は非推奨となり、GitLab 17.0で削除されます。

代わりに、GitLab 16.1で導入された`dependencyProxyTotalSizeBytes`を使用してください。

</div>

<div class="deprecation " data-milestone="18.0">

### OWASP Top 10 2017によるグループ脆弱性レポートは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.0</span>で発表
- GitLab <span class="milestone">18.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/458835)を参照してください。

</div>

OWASP Top 10 2017で脆弱性レポートをグループ化することは非推奨であり、OWASP Top 10 2021でグループ化することに置き換えられました。将来的には、脆弱性レポートのグループ化のためにOWASP Top 10の最新バージョンをサポートする予定です。この変更に伴い、この機能が使用する2017 GraphQL API enumも非推奨にして削除します。詳細については、[この問題](https://gitlab.com/gitlab-org/gitlab/-/issues/488433)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### パイプライン変数の使用に対するデフォルトのセキュリティの強化

<div class="deprecation-notes">

- GitLab <span class="milestone">17.7</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/502382)を参照してください。

</div>

GitLabは、セキュアバイデフォルトの実践を重視しています。これを尊重するために、CI/CD変数の使用に関する最小権限の原則がサポートされるように、いくつかの変更を行います。現在、デベロッパーロール以上のユーザーは、検証やオプトインなしで、デフォルトで[パイプライン変数](https://docs.gitlab.com/ci/variables/#use-pipeline-variables)を使用できます。18.0で、GitLabは[パイプライン変数の制限](https://docs.gitlab.com/ci/variables/#restrict-pipeline-variables)を更新し、デフォルトで有効にします。この変更の結果、パイプラインCI/CD変数を使用する機能は、デフォルトですべてのユーザーに対して制限されます。必要に応じて、パイプライン変数を使用できる最小ロールでこの設定を手動で更新できますが、できるだけ制限することをお勧めします。

プロジェクト設定APIで現在の設定を有効にして、許可されるロールをメンテナー以上に引き上げることで、パイプライン変数に対してよりセキュアバイデフォルトのエクスペリエンスを使い始めることができます。推奨される[オーナーのみ、またはだれもなし](https://docs.gitlab.com/ci/variables/#restrict-pipeline-variables)に最小ロールを引き上げることもできます。17.7以降、これはGitLab.comの新しいネームスペースのすべての新しいプロジェクトのデフォルトになります。プロジェクト設定UIからこれを制御するオプションを追加することで、これをより簡単に管理することも計画しています。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### 従来のGeo Prometheusのリポジトリチェックメトリクス

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/426659)を参照してください。

</div>

[Geoセルフサービスフレームワーク](https://docs.gitlab.com/development/geo/framework/)へのプロジェクトの移行に続いて、Geoセカンダリサイトで`git fsck`を使用した[リポジトリチェック](https://docs.gitlab.com/administration/repository_checks/)のサポートを削除しました。次のGeo関連の[Prometheus](https://docs.gitlab.com/administration/monitoring/prometheus/)メトリクスは非推奨となり、GitLab 18.0で削除されます。以下の表に、非推奨のメトリクスとそれぞれの代替メトリクスを示します。代替メトリクスは、GitLab 16.3.0以降で使用できます。

| 非推奨のメトリクス                 |  代替メトリクス        |
| --------------------------------- | -------------------------- |
| `geo_repositories`                | `geo_project_repositories` |
| `geo_repositories_checked`        |  利用可能なものはありません            |
| `geo_repositories_checked_failed` |  利用可能なものはありません            |

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### 従来のWeb IDEは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/513938)を参照してください。

</div>

Vueベースの従来のGitLab Web IDE実装は、GitLabから削除されます。この変更は、GitLab 15.11以降デフォルトのWeb IDEエクスペリエンスとなっているGitLab VSCode ForkベースのWeb IDEへの移行が成功したことによるものです。

この削除は、従来のWeb IDE実装にまだアクセスしているユーザーに影響します。

この削除に備えるため、GitLabインスタンスで`vscode_web_ide`機能フラグが以前に無効にされていた場合は、このフラグを有効にします。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### ポリシーごとに許可されるスキャン実行ポリシーアクションの数を制限

<div class="deprecation-notes">

- GitLab <span class="milestone">17.5</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/510897)を参照してください。

</div>

ポリシーごとに許可される最大スキャン実行ポリシーアクションに対して、新しい制限が追加されました。この変更は、17.4で導入され、機能フラグ`scan_execution_policy_action_limit`と`scan_execution_policy_action_limit_group`に組み込まれました。有効にすると、スキャン実行ポリシーの最初のアクション10個のみが処理されます。

制限を追加することで、セキュリティポリシーのパフォーマンスとスケーラビリティを確保できます。

追加のアクションが必要な場合は、既存のポリシーを10個以下のアクションに制限します。次に、セキュリティポリシープロジェクトごとに5つのスキャン実行ポリシーの制限内で、追加のアクションを含む新しいスキャン実行ポリシーを作成します。

GitLab Self-Managed管理者の場合は、`scan_execution_policies_action_limit`アプリケーション設定でカスタム制限を設定できます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Prometheusサブチャートのメジャーアップデート

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5927)を参照してください。

</div>

GitLab 18.0およびGitLabチャート9.0では、Prometheusサブチャートが15.3から27.3に更新されます。この更新に伴い、Prometheus 3がデフォルトで提供されます。

アップグレードを実行するには、手動による手順が必要です。Alertmanager、ノードExporter、またはPushgatewayが有効になっている場合は、Helmの値も更新する必要があります。

詳細については、[移行ガイド](https://docs.gitlab.com/charts/releases/9_0/#prometheus-upgrade)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `gitlab-runner-helper-images` Linux OSパッケージを`gitlab-runner`のオプションの依存関係にする

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/517765)を参照してください。

</div>

現在、`gitlab-runner` OSパッケージは`gitlab-runner-helper-images`パッケージに依存しています。`gitlab-runner-helper-images`パッケージは、複数のOSアーキテクチャ用の`gitlab-runner-helper` Dockerイメージのエクスポートされたアーカイブを提供します。アーカイブは最大500MBですが、一部のユーザーのみが必要です。必要な依存関係があるということは、提供されるエクスポートされたRunnerヘルパーイメージを必要としない場合でも、ユーザーは後者のパッケージを強制的にインストールする必要があることを意味します。

GitLab 18.0でこの依存関係はオプションになり、エクスポートされたヘルパーイメージが必要なユーザーは明示的にインストールする必要があります。これは、非常に特有のケースでは、ヘルパーDockerイメージをプルしようとしたときにCIジョブが失敗する可能性があることを意味します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GitLab.comでの脆弱性のための新しいデータ保持制限

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/groups/gitlab-org/-/epics/16629)を参照してください。

</div>

GitLab 18.0では、システムパフォーマンスと信頼性を向上させるために、GitLab.com Ultimateのお客様向けに新しいデータ保持制限を導入します。データ保持制限は、脆弱性データの保存期間に影響します。12か月以上経過し、更新されていない脆弱性は、コールドストレージアーカイブに自動的に移送されます。これらのアーカイブは次のように機能します。

- GitLab UIからアクセスしてダウンロードできます。
- 3年間保持されます。
- 3年後に完全に削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### OpenTofu CI/CDテンプレート

<div class="deprecation-notes">

- GitLab <span class="milestone">17.1</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/components/opentofu/-/issues/43#note_1913822299)を参照してください。

</div>

16.8でOpenTofu CI/CDテンプレートを導入したのは、CI/CDコンポーネントがGitLab Self-Managedでまだ利用できなかったためです。[GitLab Self-ManagedのGitLab CI/CDコンポーネント](https://docs.gitlab.com/ci/components/#use-a-gitlabcom-component-in-a-self-managed-instance)の導入に伴い、CI/CDコンポーネントを優先して、冗長なOpenTofu CI/CDテンプレートを削除します。

CI/CDテンプレートからコンポーネントへの移行については、[OpenTofuコンポーネントのドキュメント](https://gitlab.com/components/opentofu#usage-on-self-managed)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### パイプラインジョブの制限をコミットAPIに拡張

<div class="deprecation-notes">

- GitLab <span class="milestone">17.7</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/436361)を参照してください。

</div>

GitLab 18.0以降、[アクティブなパイプラインのジョブの最大数](https://docs.gitlab.com/administration/instance_limits/#number-of-jobs-in-active-pipelines)は、[コミットAPI](https://docs.gitlab.com/api/commits/#set-the-pipeline-status-of-a-commit)を使用してジョブを作成する場合にも適用されます。インテグレーションを見直して、設定済みのジョブ制限内に収まるようにしてください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### パイプラインAPIのキャンセルエンドポイントが、キャンセルできないパイプラインのエラーを返却

<div class="deprecation-notes">

- GitLab <span class="milestone">17.6</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/414963)を参照してください。

</div>

パイプラインをキャンセルできるかどうかに関係なく、パイプラインAPIキャンセルエンドポイント[`POST /projects/:id/pipelines/:pipeline_id/cancel`](https://docs.gitlab.com/api/pipelines/#cancel-a-pipelines-jobs)は`200`の成功レスポンスを返します。GitLab 18.0以降、パイプラインをキャンセルできない場合、エンドポイントは`422 Unprocessable Entity`エラーを返します。パイプラインキャンセルリクエストを行うときに、`422`ステータスコードを処理するようにAPIインテグレーションを更新します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### PostgreSQL 14および15はサポート終了

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/521663)を参照してください。

</div>

GitLabは[PostgreSQLの年間アップグレードケイデンス](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/data-access/database-framework/postgresql-upgrade-cadence/)に従います。

PostgreSQL 14および15のサポートは、GitLab 18.0で削除される予定です。GitLab 18.0では、PostgreSQL 16が最小要件のPostgreSQLバージョンになります。

PostgreSQL 14および15は、GitLab 17のリリースサイクル全体でサポートされます。PostgreSQL 16は、GitLab 18.0より前にアップグレードしたいインスタンスでもサポートされます。

Omnibus Linuxパッケージを使用してインストールした単一のPostgreSQLインスタンスを実行している場合、17.11で自動アップグレードが試行される場合があります。アップグレードに対応できるように、十分なディスク容量があることを確認してください。詳細については、[Omnibusデータベースのドキュメント](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server)を参照してください。

</div>

<div class="deprecation " data-milestone="18.0">

### グループ設定のプロジェクトページは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.0</span>で発表
- GitLab <span class="milestone">17.9</span>でサポート終了
- GitLab <span class="milestone">18.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/443347)を参照してください。

</div>

グループのオーナーは、グループに含まれるプロジェクトを一覧表示するグループ設定のプロジェクトページにアクセスできます。このページには、プロジェクトの作成、編集、または削除のオプションと、各プロジェクトのメンバーページへのリンクがあります。この機能はすべて、グループの概要ページとプロジェクトのそれぞれのメンバーページで利用できます。グループ設定のプロジェクトページは、利用率が低く、アクセスが制限されているため、非推奨になります。この変更は、ユーザーインターフェイスにのみ影響します。基盤となるAPIは引き続き利用できるため、プロジェクトの作成、編集、削除は、引き続き[プロジェクトAPI](https://docs.gitlab.com/api/projects/)を使用して実行できます。17.9では、このページからグループの概要ページへのリダイレクトを実装します。プロジェクトページは、18.0でグループ設定から完全に削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### セキュアコンテナレジストリのパブリック使用は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.4</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/470641)を参照してください。

</div>

GitLab 18.0では、`registry.gitlab.com/gitlab-org/security-products/`の下のコンテナレジストリにアクセスできなくなります。[GitLab 14.8以降](https://docs.gitlab.com/update/deprecations/#secure-and-protect-analyzer-images-published-in-new-location)、正しい場所は`registry.gitlab.com/security-products`の下です（アドレスに`gitlab-org`がないことに注意してください）。

この変更により、GitLab[脆弱性スキャナー](https://docs.gitlab.com/user/application_security/#vulnerability-scanner-maintenance)のリリースプロセスのセキュリティが向上します。

`registry.gitlab.com/security-products/`の下の同等のレジストリを使用することをお勧めします。これは、GitLabセキュリティスキャナーイメージの標準的な場所です。関連するGitLab CIテンプレートはすでにこの場所を使用しているため、変更されていないテンプレートを使用するユーザーは変更する必要はありません。

オフラインデプロイでは、[特定のスキャナーの指示](https://docs.gitlab.com/user/application_security/offline_deployments/#specific-scanner-instructions)を確認して、必要なスキャナーイメージをミラーリングするために正しい場所が使用されていることを確認する必要があります。

</div>

<div class="deprecation " data-milestone="18.0">

### REST APIエンドポイント`pre_receive_secret_detection_enabled`は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/514413)を参照してください。

</div>

REST APIエンドポイント`pre_receive_secret_detection_enabled`は、`secret_push_protection_enabled`を優先して非推奨になっています。機能`pre_receive_secret_detection`の名前の変更を`secret_push_protection`に反映するために、APIフィールドの名前をいくつか変更します。古い名前を使用するワークフローが中断しないようにするには、GitLab 18.0より前に`pre_receive_secret_detection_enabled`エンドポイントの使用を停止する必要があります。代わりに、新しい`secret_push_protection_enabled`エンドポイントを使用してください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Raspberry Pi 32ビットパッケージは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/519113)を参照してください。

</div>

GitLabバージョン18.0以降、Raspberry Piの32ビットパッケージは提供されなくなります。64ビットのRaspberry Pi OSを使用し、[`arm64` Debianパッケージをインストールする](https://about.gitlab.com/install/#debian)必要があります。32ビットOSでのデータのバックアップと64ビットOSへの復元については、[PostgreSQLのオペレーティングシステムのアップグレード](https://docs.gitlab.com/administration/postgresql/upgrading_os/)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### 一般的なユーザー、プロジェクト、およびグループAPIエンドポイントのレート制限

<div class="deprecation-notes">

- GitLab <span class="milestone">17.4</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/480914)を参照してください。

</div>

一般的に使用される[ユーザー](https://docs.gitlab.com/administration/settings/user_and_ip_rate_limits/)、[プロジェクト](https://docs.gitlab.com/administration/settings/rate_limit_on_projects_api/)、および[グループ](https://docs.gitlab.com/administration/settings/rate_limit_on_groups_api/)エンドポイントについて、デフォルトでレート制限が有効になります。これらのレート制限をデフォルトで有効にすると、API の大量使用が広範なユーザーエクスペリエンスに悪影響を与える可能性を減らすことで、システム全体の安定性を向上させることができます。レート制限を超えてリクエストを行った場合、[HTTP 429](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/429)エラーコードと[追加のレート制限ヘッダー](https://docs.gitlab.com/administration/settings/user_and_ip_rate_limits/#response-headers)を返します。

デフォルトのレート制限は、GitLab.comで確認できるリクエストレートに基づいて、ほとんどの使用を混乱させることがないように、意図的にかなり高く設定されています。インスタンス管理者は、すでに設定されている他のレート制限と同様に、管理者エリアで必要に応じて上限または下限を設定できます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `POST /api/v4/runners` エンドポイントの登録トークンとサーバー側のRunner引数

<div class="deprecation-notes">

- GitLab <span class="milestone">15.6</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/379743)を参照してください。

</div>

`/api/v4/runners`エンドポイントでの`POST`メソッド操作における登録トークンと特定のRunner設定引数のサポートは、非推奨となります。このエンドポイントは、APIを介してインスタンス、グループ、またはプロジェクトレベルでGitLabインスタンスにRunnerを[登録](https://docs.gitlab.com/api/runners/#create-a-runner)します。GitLab 18.0では、登録トークンと特定の設定引数のサポートで、HTTP `410 Gone`ステータスコードが返されるようになります。詳細については、[新しいRunner登録ワークフローへの移行](https://docs.gitlab.com/ci/runners/new_creation_workflow/#prevent-your-runner-registration-workflow-from-breaking)を参照してください。

Runner認証トークンに対して無効になっている設定引数は次のとおりです。

- `--locked`
- `--access-level`
- `--run-untagged`
- `--maximum-timeout`
- `--paused`
- `--tag-list`
- `--maintenance-note`

この変更は破壊的な変更です。設定を追加するには[UIでRunnerを作成](https://docs.gitlab.com/ci/runners/runners_scope/)し、代わりに`gitlab-runner register`コマンドでRunner認証トークンを使用する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `gitlab-runner register`コマンドの登録トークンとサーバー側のRunner引数

<div class="deprecation-notes">

- GitLab <span class="milestone">15.6</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/380872)を参照してください。

</div>

Runnerを[登録](https://docs.gitlab.com/runner/register/)するコマンド`gitlab-runner register`の登録トークンと特定の設定引数は、非推奨となります。代わりに、認証トークンがRunnerの登録に使用されます。登録トークン、および特定の設定引数のサポートは、GitLab 18.0で削除されます。詳細については、[新しいRunner登録ワークフローへの移行](https://docs.gitlab.com/ci/runners/new_creation_workflow/)を参照してください。認証トークンに対して無効になっている設定引数は次のとおりです。

- `--locked`
- `--access-level`
- `--run-untagged`
- `--maximum-timeout`
- `--paused`
- `--tag-list`
- `--maintenance-note`

この変更は破壊的な変更です。設定を追加するには[UIでRunnerを作成](https://docs.gitlab.com/ci/runners/runners_scope/)し、代わりに`gitlab-runner register`コマンドで認証トークンを使用する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `allowed_pull_policies`にないコンテナイメージプルポリシーを拒否する

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/516107)を参照してください。

</div>

設定されているすべてのプルポリシーは、Runnerの`config.toml`ファイルで指定された[`allowed_pull_policies`設定](https://docs.gitlab.com/runner/executors/docker/#allow-docker-pull-policies)に存在する必要があります。そうでない場合、ジョブは`incompatible pull policy`エラーで失敗します。

現在の実装では、複数のプルポリシーが定義されている場合、他のポリシーが含まれていなくても、少なくとも1つのプルポリシーが`allowed-pull-policies`のポリシーと一致すると、ジョブは合格になります。

GitLab 18.0では、プルポリシーがいずれも`allowed-pull-policies`のポリシーと一致しない場合にのみ、ジョブは失敗します。ただし、現在の動作とは異なり、ジョブは`allowed-pull-policies`にリストされているプルポリシーのみを使用します。この違いにより、現在合格になっているジョブがGitLab 18.0では失敗する可能性があります。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `ContainerRepository` GraphQL API の`migrationState`フィールドを削除

<div class="deprecation-notes">

- GitLab <span class="milestone">17.6</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/459869)を参照してください。

</div>

GitLab GraphQL APIの`ContainerRepositoryType`の`migrationState`フィールドは、GitLab 18.0で削除されます。この非推奨化は、APIを効率化し、改善するための取り組みの一環です。

この変更に備えるため、`ContainerRepositoryType`とやり取りするGraphQLクエリを確認し、更新することをお勧めします。`migrationState`フィールドへの参照を削除し、それに応じてアプリケーションロジックを調整します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GraphQL から`previousStageJobsOrNeeds`を削除

<div class="deprecation-notes">

- GitLab <span class="milestone">17.0</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/424417)を参照してください。

</div>

`previousStageJobsOrNeeds`フィールドは、`previousStageJobs`フィールドと`needs`フィールドに置き換えられたため、GraphQLから削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### duoProAssignedUsersCount GraphQLフィールドを削除

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/498671)を参照してください。

</div>

18.0では、`duoProAssignedUsersCount` GraphQLフィールドを削除します。ユーザーが[`aiMetrics` API](https://docs.gitlab.com/api/graphql/reference/#aimetrics)でこのフィールドを使用している場合に問題が発生する可能性があり、代わりに`duoAssignedUsersCount`を使用できます。この削除は、[GitLab Duo ProおよびDuoシートが割り当てられたユーザーの両方をカウントするための修正](https://gitlab.com/gitlab-org/gitlab/-/issues/485510)の一部です。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `setPreReceiveSecretDetection` GraphQL変異の名前を`setSecretPushProtection`に変更

<div class="deprecation-notes">

- GitLab <span class="milestone">17.7</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/514414)を参照してください。

</div>

`setPreReceiveSecretDetection` GraphQL変異の名前が`setSecretPushProtection`に変更されました。また、機能`pre_receive_secret_detection`の名前変更を`secret_push_protection`に反映するために、変異の応答の一部フィールドの名前も変更します。古い名前を使用するワークフローが中断しないようにするために、GitLab 18.0より前に次のことを行う必要があります。

- 古い変異名`setPreReceiveSecretDetection`の使用を停止します。代わりに、名前`setSecretPushProtection`を使用します。
- フィールド`pre_receive_secret_detection_enabled`への参照を`secret_push_protection_enabled`に変更します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GitGuardianシークレット検出をスキップするオプションの名前を変更

<div class="deprecation-notes">

- GitLab <span class="milestone">17.3</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/470119)を参照してください。

</div>

GitGuardianシークレット検出、`[skip secret detection]`および`secret_detection.skip_all`をスキップするオプションは非推奨となり、GitLab 18.0で削除されます。代わりに、`[skip secret push protection]`と`secret_push_protection.skip_all`を使用する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### PipelineSchedulePermissionsでGraphQLフィールド`take_ownership_pipeline_schedule`を`admin_pipeline_schedule`に置換

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/391941)を参照してください。

</div>

GraphQL フィールド`take_ownership_pipeline_schedule`は非推奨になります。ユーザーがパイプラインスケジュールの所有権を取得できるかどうかを判断するには、代わりに`admin_pipeline_schedule`フィールドを使用します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `add_on_purchase` GraphQLフィールドを`add_on_purchases`に置換

<div class="deprecation-notes">

- GitLab <span class="milestone">17.4</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/476858)を参照してください。

</div>

GraphQLフィールド`add_on_purchase`はGitLab 17.4で非推奨となり、GitLab 18.0で削除されます。代わりに`add_on_purchases`フィールドを使用します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### コンテナレジストリ通知の`threshold`を`maxretries`に置換

<div class="deprecation-notes">

- GitLab <span class="milestone">17.1</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/container-registry/-/issues/1243)を参照してください。

</div>

レジストリで発生するイベントに応じて[Webhook通知](https://docs.gitlab.com/administration/packages/container_registry/#configure-container-registry-notifications)を送信するようにコンテナレジストリを設定できます。この設定では、`threshold`パラメーターと`backoff`パラメーターを使用して、再試行前に一定期間バックオフするまでに許可される失敗回数を指定します。

問題は、イベントが成功するか、レジストリがシャットダウンされるまで、イベントがメモリに保持されることです。イベントが適切に送信されない場合、レジストリ側でメモリとCPUの使用量が多くなる可能性があるため、これは理想的ではありません。また、イベントのキューに追加された新しいイベントも遅延します。

イベントをドロップする前にイベントを再試行する回数を制御するために、新しい`maxretries`パラメーターが追加されました。そのため、イベントがメモリに永久に保持されないようにするために、`maxretries`を優先して`threshold`パラメーターは非推奨となりました。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### ネームスペース`add_on_purchase` GraphQLフィールドを`add_on_purchases`に置換

<div class="deprecation-notes">

- GitLab <span class="milestone">17.5</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/489850)を参照してください。

</div>

ネームスペースGraphQLフィールド`add_on_purchase`はGitLab 17.5で非推奨となり、GitLab 18.0で削除されます。代わりに、ルート`add_on_purchases`フィールドを使用します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Runner `active` GraphQLフィールドを`paused`に置換

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/351109)を参照してください。

</div>

GitLab GraphQL APIエンドポイントで出現する`active`識別子は、GitLab 18.0で名前が`paused`に変更されます。

- `CiRunner`プロパティ。
- `runnerUpdate`変異の`RunnerUpdateInput`入力タイプ。
- `runners`、`Group.runners`、および`Project.runners`クエリ。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### RunnersRegistrationTokenReset GraphQL変異は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.7</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/505703)を参照してください。

</div>

Runner登録トークンのサポートは非推奨となります。その結果、登録トークンをリセットするためのサポートも非推奨となっていて、GitLab 18.0で削除されます。

新しい[GitLab Runnerトークンアーキテクチャ](https://docs.gitlab.com/ci/runners/new_creation_workflow/)の一部として、RunnerをGitLabインスタンスにバインドする新しいメソッドが実装されました。詳細については、[エピック7633](https://gitlab.com/groups/gitlab-org/-/epics/7633)を参照してください。この新しいアーキテクチャでは、Runnerを登録する新しいメソッドが導入され、従来の[Runner登録トークン](https://docs.gitlab.com/security/tokens/#runner-registration-tokens-deprecated)が不要になります。GitLab 18.0では、新しいGitLab Runnerトークンアーキテクチャで実装されたRunner登録メソッドのみがサポートされます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### SASTジョブはグローバルキャッシュ設定の使用を停止

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/512564)を参照してください。

</div>

GitLab 18.0では、SASTおよびIaCスキャンを更新して、デフォルトで[CI/CDジョブキャッシュの使用を明示的に無効に](https://docs.gitlab.com/ci/caching/#disable-cache-for-specific-jobs)します。

この変更は、次のCI/CDテンプレートに影響します。

- SAST: `SAST.gitlab-ci.yml`。
- IaCスキャン: `SAST-IaC.gitlab-ci.yml`。

すでに`latest`テンプレート`SAST.latest.gitlab-ci.yml`と`SAST-IaC.latest.gitlab-ci.yml`を更新しました。これらのテンプレートバージョンの詳細については、[安定版と最新版のテンプレート](https://docs.gitlab.com/user/application_security/sast/#stable-vs-latest-sast-templates)を参照してください。

キャッシュディレクトリはほとんどのプロジェクトでスキャンの対象外であるため、キャッシュを取得するとタイムアウトまたは誤検知の結果が発生する可能性があります。

プロジェクトのスキャン時にキャッシュを使用する必要がある場合は、プロジェクトのCI設定で[`cache`](https://docs.gitlab.com/ci/yaml/#cache)プロパティを[オーバーライド](https://docs.gitlab.com/user/application_security/sast/#overriding-sast-jobs)して、前の動作を復元できます。

</div>

<div class="deprecation " data-milestone="18.0">

### シークレット検出アナライザーは、デフォルトではrootユーザーとして実行されない

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/476160)を参照してください。

</div>

GitLab 18.0以降、シークレット検出アナライザーは、デフォルトでrootユーザーを使用しなくなります。この変更の結果として、何らかの影響を受けることはないはずです。ただし、`before_script`または`after_script`を使用してイメージに変更を加えた場合、問題が発生する可能性があります。GitLabは、`before_script`と`after_script`のこの使用をサポートしていません。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### パブリックAPIのサブスクリプション関連APIエンドポイントは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/515371#note_2319368251)を参照してください。

</div>

パブリックREST APIの次のエンドポイントが削除されます。

- `POST /api/v4/namespaces/:namespace_id/minutes`
- `GET /api/v4/namespaces/:namespace_id/subscription_add_on_purchase/:id`
- `POST /api/v4/namespaces/:id/gitlab_subscription`
- `PUT /api/v4/namespaces/:id/gitlab_subscription`
- `PUT /api/v4/user/:id/credit_card_validation`
- `PUT /api/v4/namespaces/:namespace_id/subscription_add_on_purchase/:id`
- `POST /api/v4/namespaces/:namespace_id/subscription_add_on_purchase/:id`
- `PATCH /api/v4/namespaces/:previous_namespace_id/minutes/move/:target_namespace_id`
- `DELETE /api/v4/internal/upcoming_reconciliations`
- `PUT /api/v4/internal/upcoming_reconciliations`
- `PUT /api/v4/namespaces/:id`

これらのエンドポイントは、サブスクリプションポータルによってGitLab.comのサブスクリプション情報を管理するために使用されていました。それらの使用法は、今後のセルアーキテクチャをサポートするために、JWT認証を備えた内部エンドポイントに置き換えられました。パブリックAPIのエンドポイントは、誤って再度使用されないように、また機能に不具合が生じた場合のメンテナンスの負担を軽減するために削除されています。

これらは内部で使用されていたエンドポイントであるため、この変更の結果として、何らかの影響を受けることはないはずです。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Runner登録トークンをリセットするREST APIエンドポイントのサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">15.7</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/383341)を参照してください。

</div>

Runner登録トークンのサポートは非推奨となります。その結果、登録トークンをリセットするためのREST APIエンドポイントも非推奨となり、GitLab 18.0でHTTP `410 Gone`ステータスコードが返されるようになります。非推奨のエンドポイントは次のとおりです。

- `POST /runners/reset_registration_token`
- `POST /projects/:id/runners/reset_registration_token`
- `POST /groups/:id/runners/reset_registration_token`

新しい[GitLab Runnerトークンアーキテクチャ](https://docs.gitlab.com/ci/runners/new_creation_workflow/)の一部として、RunnerをGitLabインスタンスにバインドする新しいメソッドを実装する予定です。作業は[このエピック](https://gitlab.com/groups/gitlab-org/-/epics/7633)で計画されています。この新しいアーキテクチャでは、Runnerを登録する新しいメソッドが導入され、従来の[Runner登録トークン](https://docs.gitlab.com/security/tokens/#runner-registration-tokens-deprecated)は不要になります。GitLab 18.0以降では、新しいGitLab Runnerトークンアーキテクチャによって実装されたRunner登録メソッドのみがサポートされます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### SUSE Linux Enterprise Server 15 SP2のサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8888)を参照してください。

</div>

SUSE Linux Enterprise Server（SLES）15 SP2の長期サービスとサポート（LTSS）は、2024年12月に終了しました。

したがって、Linuxパッケージインストール用のSLES SP2ディストリビューションはサポートされなくなります。継続的なサポートを受けるには、SLES 15 SP6にアップグレードする必要があります。

</div>

<div class="deprecation " data-milestone="18.0">

### SpotBugsスキャンの一部としてのプロジェクトビルドのサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>でサポート終了
- GitLab <span class="milestone">18.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/513409)を参照してください。

</div>

SpotBugs [SASTアナライザー](https://docs.gitlab.com/user/application_security/sast/#supported-languages-and-frameworks)は、スキャン対象のアーティファクトが存在しない場合にビルドを実行できます。これは通常、単純なプロジェクトではうまく機能しますが、複雑なビルドでは失敗する可能性があります。

GitLab 18.0以降、SpotBugsアナライザーのビルドの失敗を解決するには、次の手順を実行する必要があります。

1. プロジェクトを[事前コンパイル](https://docs.gitlab.com/user/application_security/sast/#pre-compilation)します。
1. スキャンするアーティファクトをアナライザーに渡します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GitLabの従来の要件IIDは、作業アイテムIIDを優先して非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/390263)を参照してください。

</div>

要件を作業[アイテムタイプ](https://docs.gitlab.com/development/work_items/#work-items-and-work-item-types)に移行した結果、新しいIIDに移行します。GitLab 18.0で従来のIIDおよび既存の形式のサポートが終了するため、ユーザーは新しいIIDの使用を開始する必要があります。従来の要件IIDは、GitLab 18.0で削除されるまで引き続き利用できます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `agentk`コンテナレジストリはCloud Native GitLabに移行

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/630)を参照してください。

</div>

`agentk`コンテナレジストリを[プロジェクト固有のレジストリ](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/container_registry/1223205)から[Cloud Native GitLab（CNG）レジストリ](https://gitlab.com/gitlab-org/build/CNG/container_registry/8241772)に移動します。GitLab 18.0以降、CNGで構築された`agentk`イメージは、プロジェクト固有のレジストリにミラーリングされます。新しいイメージは古いイメージと同等ですが、新しいイメージは`amd64`および`arm64`アーキテクチャのみをサポートします。32 ビットの`arm`アーキテクチャはサポートされていません。GitLab 19.0以降、プロジェクト固有のレジストリは`agentk`の更新を受信しません。`agentk`コンテナをローカルレジストリにミラーリングする場合は、ミラーのソースを[CNGレジストリ](https://gitlab.com/gitlab-org/build/CNG/container_registry/8241772)に変更する必要があります。

公式の[GitLabエージェントHelmチャート](https://gitlab.com/gitlab-org/charts/gitlab-agent/)を使用している場合、GitLab 18.0では新しい`agentk`イメージは新しい場所からシームレスにデプロイを開始します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `ci_job_token_scope_enabled`プロジェクトAPI属性は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.4</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/423091)を参照してください。

</div>

GitLab 16.1では、[ジョブトークンスコープのAPIエンドポイント](https://gitlab.com/gitlab-org/gitlab/-/issues/351740)が導入されました。[プロジェクトAPI](https://docs.gitlab.com/api/projects/)では、`ci_job_token_scope_enabled`属性は非推奨となり、17.0で削除されます。代わりに[ジョブトークンスコープAPI](https://docs.gitlab.com/api/project_job_token_scopes/)を使用する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `ciJobTokenScopeRemoveProject`の`direction` GraphQL引数は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/383084)を参照してください。

</div>

`ciJobTokenScopeRemoveProject`変異の`direction` GraphQL引数は非推奨になります。GitLab 15.9で発表された[デフォルトのCI/CDジョブトークンスコープの変更](https://docs.gitlab.com/update/deprecations/#default-cicd-job-token-ci_job_token-scope-changed)に続いて、`direction`引数はデフォルトで`INBOUND`になり、GitLab 17.0で`OUTBOUND`は有効ではなくなります。GitLab 18.0で`direction`引数を削除します。

プロジェクトのトークンアクセス方向を制御するために`direction`引数で`OUTBOUND`を使用している場合、ジョブトークンを使用するパイプラインは認証に失敗するリスクがあります。パイプラインが引き続き期待どおりに実行されるようにするには、[プロジェクトの許可リストに他のプロジェクトを明示的に追加](https://docs.gitlab.com/ci/jobs/ci_job_token/#add-a-group-or-project-to-the-job-token-allowlist)する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `heroku/builder:22`イメージは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.4</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/cluster-integration/auto-build-image/-/issues/79)を参照してください。

</div>

Cloud Native Buildpack（CNB）ビルダーイメージがAuto DevOps Buildプロジェクトで`heroku/builder:24`に更新されました。ほとんどの場合、変更によって混乱が発生することはないと考えていますが、Auto DevOpsの一部のユーザー、特にAuto Buildのユーザーにとっては、これは破壊的な変更となる可能性があります。ワークロードの影響をより深く理解するには、以下を確認してください。

- [Heroku-24スタックのリリースノート](https://devcenter.heroku.com/articles/heroku-24-stack#what-s-new)
- [Heroku-24スタックのアップグレードノート](https://devcenter.heroku.com/articles/heroku-24-stack#upgrade-notes)
- [Herokuスタックパッケージ](https://devcenter.heroku.com/articles/stack-packages)

これらの変更は、パイプラインが[Auto DevOpsのAuto Buildステージ](https://docs.gitlab.com/topics/autodevops/stages/#auto-build)によって提供される[`auto-build-image`](https://gitlab.com/gitlab-org/cluster-integration/auto-build-image)を使用している場合に影響します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### APIでのノートの機密性の切り替え

<div class="deprecation-notes">

- GitLab <span class="milestone">14.10</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/350670)を参照してください。

</div>

RESTおよびGraphQL APIを使用したノートの機密性の切り替えは非推奨となります。ノートの機密属性の更新は、いかなる手段でもサポートされなくなっています。エクスペリエンスを簡素化し、プライベート情報が意図せずに公開されるのを防ぐために、これを変更しています。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### CI/CDコンポーネントをカタログにリリースするためのツールを更新

<div class="deprecation-notes">

- GitLab <span class="milestone">17.7</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/groups/gitlab-org/-/epics/12788)を参照してください。

</div>

GitLab 18.0以降、CI/CDコンポーネントをカタログにリリースする内部プロセスが変更されます。[推奨されるCI/CDコンポーネントリリースプロセス](https://docs.gitlab.com/ci/components/#publish-a-new-release)を使用している場合（`release`キーワードと`registry.gitlab.com/gitlab-org/release-cli:latest`コンテナイメージを使用）、変更を加える必要はありません。このコンテナイメージの`latest`バージョン（`v0.22.0`）には、[GLab](https://gitlab.com/gitlab-org/cli/) `v1.53.0`が含まれており、GitLab 18.0以降のCI/CDカタログへのすべてのリリースに使用されます。その他の場合:

- コンテナイメージを特定のバージョンに固定する必要がある場合は、`v0.22.0`以降（`registry.gitlab.com/gitlab-org/release-cli:v0.22.0`）を使用して、リリースプロセスでGLabが利用可能であることを確認してください。
- RunnerにRelease CLIツールを手動でインストールした場合は、それらのRunnerにGLab `v1.53.0`以降をインストールする必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### CI/CDジョブトークンをJWT標準に更新

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/509578)を参照してください。

</div>

GitLab 18.0では、CI/CDジョブトークンがデフォルトでJWT標準に移行します。すべての新しいプロジェクトはこの標準を使用しますが、既存のプロジェクトは引き続きレガシー形式を使用します。既存のプロジェクトは、GitLab 18.0のリリース前にJWT標準に切り替えることができます。問題が発生した場合は、GitLab 18.3リリースまで、[CI/CDトークンにレガシー形式を使用](https://docs.gitlab.com/ci/jobs/ci_job_token#use-legacy-format-for-cicd-tokens)できます。

GitLab 18.3では、すべてのCI/CDジョブトークンがJWT標準を使用する必要があります。このリリースより前は、トークンを一時的に従来のジョブトークン形式にリバートすることができます。

既知の問題:

1. GitLab RunnerのAWS Fargate Drive 0.5.0以前のバージョンは、JWT標準と互換性がありません。[AWS Fargateカスタムexecutorドライバー](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws_fargate/)のユーザーは、0.5.1以降にアップグレードする必要があります。移行手順については、[ドキュメント](https://gitlab.com/gitlab-org/ci-cd/custom-executor-drivers/fargate/-/tree/master/docs)を参照してください。
1. 非常に長いJWT標準は、一部のCI/CD設定ファイルで使用されている`echo $CI_JOB_TOKEN | base64`コマンドを壊します。代わりに`echo $CI_JOB_TOKEN | base64 -w0`コマンドを使用できます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### ワークスペース`editor` GraphQLフィールドは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.8</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/508155)を参照してください。

</div>

`editor`フィールドは内部的に使用されません。次のGraphQL要素では非推奨になります。

- `Workspace`タイプ。
- `workspaceCreate`変異へのインプット。

この変更に備えるには:

- `Workspace`タイプと相互に作用するGraphQLクエリを確認して更新します。
- `editor`フィールドへの参照を削除します。
- それに応じてアプリケーションロジックを調整します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### ZenTaoのインテグレーション

<div class="deprecation-notes">

- GitLab <span class="milestone">15.7</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/377825)を参照してください。

</div>

[ZenTao製品のインテグレーション](https://docs.gitlab.com/user/project/integrations/zentao/)は非推奨となっていて、JiHu GitLabコードベースに移行します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN`は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.11</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/453949)を参照してください。

</div>

[`GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN`](https://docs.gitlab.com/administration/environment_variables/#supported-environment-variables)環境変数は非推奨となります。GitLabはGitLab 15.8で新しい[GitLab Runnerトークンアーキテクチャ](https://docs.gitlab.com/architecture/blueprints/runner_tokens/)を導入しました。これにより、Runnerを登録する新しいメソッドが導入され、従来のRunner登録トークンは不要になります。新しいワークフローへの移行に関するガイダンスについては、[ドキュメント](https://docs.gitlab.com/ci/runners/new_creation_workflow/)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `RemoteDevelopmentAgentConfig` GraphQLタイプは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/509787)を参照してください。

</div>

`RemoteDevelopmentAgentConfig`タイプは内部で使用されなくなっています。`ClusterAgent`タイプでは非推奨となります。

この変更に備えるには:

- `RemoteDevelopmentAgentConfig`タイプと相互に作用するGraphQLクエリを確認して更新します。
- 実験的なタイプ`workspacesAgentConfig`に切り替えます。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `ciJobTokenScopeAddProject` GraphQL変異は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.5</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/474175)を参照してください。

</div>

GitLab 18.0での[CI/CDジョブトークンの今後のデフォルトの動作変更](https://docs.gitlab.com/update/deprecations/#default-cicd-job-token-ci_job_token-scope-changed)に伴い、関連する機能が利用できなくなるため、関連する`ciJobTokenScopeAddProject` GraphQL変異も非推奨になります。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `ciMinutesUsed` GraphQLフィールドの名前を`ciDuration`に変更

<div class="deprecation-notes">

- GitLab <span class="milestone">17.5</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/497364)を参照してください。

</div>

`CiRunnerUsage`および`CiRunnerUsageByProject`タイプの`ciDuration`フィールドは、以前の`ciMinutesUsed`フィールドを置き換えます。これらのタイプから`ciMinutesUsed`へのすべての参照を`ciDuration`に更新します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `defaultMaxHoursBeforeTermination`と`maxHoursBeforeTerminationLimit`のフィールドは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/509787)を参照してください。

</div>

`defaultMaxHoursBeforeTermination`および`maxHoursBeforeTerminationLimit`フィールドは内部で使用されなくなっています。これらは`WorkspacesAgentConfig`タイプでは非推奨となります。

この削除は、ワークスペースのセットアップに関連付けられている[エージェント設定](https://docs.gitlab.com/user/workspace/gitlab_agent_configuration/#workspace-settings)ファイルにも適用されます。

この変更に備えるには:

- `WorkspacesAgentConfig`タイプと相互に作用するGraphQLクエリを確認して更新します。
- `defaultMaxHoursBeforeTermination`および`maxHoursBeforeTerminationLimit`フィールドへの参照を削除します。
- エージェント設定ファイルからフィールド`default_max_hours_before_termination`と`max_hours_before_termination_limit`を削除します。
- それに応じてアプリケーションロジックを調整します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### Gitalyストレージを設定するための`git_data_dirs`

<div class="deprecation-notes">

- GitLab <span class="milestone">16.0</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8786)を参照してください。

</div>

LinuxパッケージインスタンスのGitalyストレージを設定するための`git_data_dirs`の使用のサポートは、[16.0以降](https://docs.gitlab.com/update/versions/gitlab_16_changes/#gitaly-configuration-structure-change)非推奨になっていて、18.0で削除されます。

移行手順については、[`git_data_dirs`からの移行](https://docs.gitlab.com/omnibus/settings/configuration/#migrating-from-git_data_dirs)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `kpt`ベースの`agentk`は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/656)を参照してください。

</div>

GitLab 18.0では、Kubernetesエージェントの`kpt`ベースのインストールに対するサポートを削除します。代わりに、サポートされているいずれかのインストール方法でエージェントをインストールする必要があります。

- Helm（推奨）
- GitLab CLI
- Flux

`kpt`からHelmに移行するには、[エージェントのインストールに関するドキュメント](https://docs.gitlab.com/user/clusters/agent/install/)に従って、`kpt`でデプロイされた`agentk`インスタンスを上書きしてください。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `maxHoursBeforeTermination` GraphQLフィールドは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.9</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/509787)を参照してください。

</div>

`maxHoursBeforeTermination` GraphQLフィールドは、内部では使用されなくなっています。次のGraphQL要素では非推奨となります。

- `Workspace`タイプ。
- `workspaceCreate`変異へのインプット。

この変更に備えるには:

- `Workspace`タイプと相互に作用するGraphQLクエリを確認して更新します。
- `maxHoursBeforeTermination`フィールドへの参照を削除します。
- それに応じてアプリケーションロジックを調整します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### `mergeTrainIndex`および`mergeTrainsCount` GraphQLフィールドは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">17.5</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/473759)を参照してください。

</div>

`MergeRequest`のGraphQLフィールド`mergeTrainIndex`と`mergeTrainsCount`は非推奨です。マージトレインでのマージリクエストの位置を判断するには、代わりに`MergeTrainCar`の`index`フィールドを使用します。マージトレイン内のMRの数を取得するには、代わりに`MergeTrains::TrainType`の`cars`から`count`を使用します。

</div>

<div class="deprecation breaking-change" data-milestone="18.0">

### GitLab Runner Helmチャートの`runnerRegistrationToken`パラメーター

<div class="deprecation-notes">

- GitLab <span class="milestone">15.6</span>で発表
- GitLab <span class="milestone">18.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/381111)を参照してください。

</div>

KubernetesにRunnerをインストールするためにGitLab Helmチャートを使用する[`runnerRegistrationToken`](https://docs.gitlab.com/runner/install/kubernetes/)パラメーターは非推奨です。

新しい[GitLab Runnerトークンアーキテクチャ](https://docs.gitlab.com/ci/runners/new_creation_workflow/)の一部として、`runnerToken`を利用してRunnerをGitLabインスタンスにバインドする新しい方法を実装する予定です。作業は[このエピック](https://gitlab.com/groups/gitlab-org/-/epics/7633)で計画されています。

GitLab 18.0以降、新しいGitLab Runnerトークンアーキテクチャによって導入されたRunnerを登録する方法が、サポートされる唯一の方法になります。

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.9">

## GitLab 17.9

<div class="deprecation " data-milestone="17.9">

### openSUSE Leap 15.5のサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">17.6</span>で発表
- GitLab <span class="milestone">17.9</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8778)を参照してください。

</div>

[openSUSE Leapの長期サービスとサポート（LTSS）は2024年12月に終了](https://en.opensuse.org/Lifetime#openSUSE_Leap)します。

そのため、Linuxパッケージインストールでは、openSUSE Leap 15.5ディストリビューションをサポートしなくなります。継続的なサポートを受けるには、openSUSE Leap 15.6にアップグレードする必要があります。

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.8">

## GitLab 17.8

<div class="deprecation " data-milestone="17.8">

### CentOS 7のサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">17.6</span>で発表
- GitLab <span class="milestone">17.8</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8714)を参照してください。

</div>

[CentOS 7の長期サービスとサポート（LTSS）は2024年6月に終了](https://www.redhat.com/en/topics/linux/centos-linux-eol)しました。

そのため、Linuxパッケージインストールでは、CentOS 7ディストリビューションをサポートしなくなります。継続的なサポートを受けるには、別のオペレーティングシステムにアップグレードする必要があります。

</div>

<div class="deprecation " data-milestone="17.8">

### Oracle Linux 7のサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">17.6</span>で発表
- GitLab <span class="milestone">17.8</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8746)を参照してください。

</div>

[Oracle Linux 7の長期サービスとサポート（LTSS）は2024年12月に終了](https://wiki.debian.org/LTS)します。

そのため、Linuxパッケージインストールでは、Oracle Linux 7ディストリビューションをサポートしなくなります。継続的なサポートを受けるには、Oracle Linux 8にアップグレードする必要があります。

</div>

<div class="deprecation " data-milestone="17.8">

### Raspberry Pi OS Busterのサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">17.6</span>で発表
- GitLab <span class="milestone">17.8</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8734)を参照してください。

</div>

Raspberry Pi OS Buster（以前はRaspbian Busterとして知られていました）の長期サービスとサポート（LTSS）は、2024年6月に終了しました。

そのため、Linuxパッケージインストールでは、PiOS Busterディストリビューションをサポートしなくなります。継続的なサポートを受けるには、PiOS Bullseyeにアップグレードする必要があります。

</div>

<div class="deprecation " data-milestone="17.8">

### Red Hat Enterprise Linux 7のサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">17.6</span>で発表
- GitLab <span class="milestone">17.8</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8714)を参照してください。

</div>

Red Hat Enterprise Linux（RHEL）7は、[2024年6月にメンテナンスサポートを終了](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux/rhel-7-end-of-maintenance)しました。

そのため、RHEL 7およびRHEL 7互換のオペレーティングシステムのLinuxパッケージは公開されなくなります。継続的なサポートを受けるには、RHEL 8にアップグレードする必要があります。

</div>

<div class="deprecation " data-milestone="17.8">

### Scientific Linux 7のサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">17.6</span>で発表
- GitLab <span class="milestone">17.8</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8745)を参照してください。

</div>

[Scientific Linux 7の長期サービスとサポート（LTSS）は、2024年6月に終了](https://scientificlinux.org/downloads/sl-versions/sl7/)しました。

そのため、Linuxパッケージインストールでは、Scientific Linuxディストリビューションをサポートしなくなります。別のRHEL互換オペレーティングシステムにアップグレードする必要があります。

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.7">

## GitLab 17.7

<div class="deprecation breaking-change" data-milestone="17.7">

### `/repository/tree` REST APIエンドポイントのエラー処理が`404`を返却

<div class="deprecation-notes">

- GitLab <span class="milestone">16.5</span>で発表
- GitLab <span class="milestone">17.7</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/420865)を参照してください。

</div>

GitLab 17.7では、リストリポジトリツリーAPIエンドポイント`/projects/:id/repository/tree`のエラー処理動作は、要求されたパスが見つからない場合に更新されます。エンドポイントはステータスコード`404 Not Found`を返すようになりました。以前は、ステータスコードは`200 OK`でした。

この変更はGitLab 16.5のGitLab.comで有効になっていて、GitLab 17.7のSelf-Managedインスタンスで使用できるようになります。

実装が、存在しないパスに対して空の配列を持つ`200`ステータスコードを受信することに依存している場合は、新しい`404`応答を処理するようにエラー処理を更新する必要があります。

</div>

<div class="deprecation " data-milestone="17.7">

### TLS 1.0と1.1のサポートは終了

<div class="deprecation-notes">

- GitLab <span class="milestone">17.4</span>で発表
- GitLab <span class="milestone">17.7</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164512)を参照してください。

</div>

[OpenSSLバージョン1.1.1の長期サポート（LTS）は2023年9月に終了](https://endoflife.date/openssl)しました。したがって、OpenSSL 3がGitLab 17.7のデフォルトになります。GitLabはOpenSSL 3をバンドルしているため、オペレーティングシステムを変更する必要はありません。

OpenSSL 3へのアップグレードにより:

- GitLabでは、すべての発信および受信TLS接続にTLS 1.2以降が必要です。
- TLS/SSL証明書には、少なくとも112ビットのセキュリティが必要です。2048ビット未満のRSA、DSA、DHキー、および224ビット未満のECCキーは禁止されています。

詳細については、[GitLab 17.5の変更点](https://docs.gitlab.com/update/versions/gitlab_17_changes/#1750)を参照してください。

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.6">

## GitLab 17.6

<div class="deprecation " data-milestone="17.6">

### Debian 10のサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">17.3</span>で発表
- GitLab <span class="milestone">17.6</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8607)を参照してください。

</div>

[Debian 10の長期サービスとサポート（LTSS）は2024年6月に終了](https://wiki.debian.org/LTS)しました。

そのため、Linuxパッケージインストールでは、Debian 10ディストリビューションをサポートしなくなります。継続的なサポートを受けるには、Debian 11またはDebian 12にアップグレードする必要があります。

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.4">

## GitLab 17.4

<div class="deprecation " data-milestone="17.4">

### パイプラインビューからニーズタブを削除

<div class="deprecation-notes">

- GitLab <span class="milestone">17.1</span>で発表
- GitLab <span class="milestone">17.4</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/336560)を参照してください。

</div>

**ジョブの依存関係**グループ化オプションを指定した通常のパイプラインビューに表示される情報を複製するようになるため、パイプラインビューからニーズタブを削除します。今後もメインパイプライングラフのビューを改善していきます。

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.3">

## GitLab 17.3

<div class="deprecation " data-milestone="17.3">

### FIPS準拠のセキュアアナライザーをUBI MinimalからUBI Microに変更

<div class="deprecation-notes">

- GitLab <span class="milestone">17.2</span>で発表
- GitLab <span class="milestone">17.3</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/471869)を参照してください。

</div>

セキュリティの脆弱性のためのコードスキャンに使用される一部のアナライザーのベースイメージを更新します。Red Hat Universal Base Image（UBI）に基づいたアナライザーイメージのみを変更しているため、この変更は、[FIPSモード](https://docs.gitlab.com/development/fips_compliance/)をセキュリティスキャン用に特に有効にしている場合にのみ影響します。GitLabセキュリティスキャンが使用するデフォルトイメージは、UBIに基づいていないため影響を受けません。

GitLab 17.3では、UBIベースのアナライザーのベースイメージをUBI Minimalから、不要なパッケージが少なく、パッケージマネージャーが省略された[UBI Micro](https://www.redhat.com/en/blog/introduction-ubi-micro)に変更します。更新されたイメージは小さくなり、オペレーティングシステムによって提供されるパッケージの脆弱性の影響を受けにくくなります。

GitLabサポートチームの[サポートステートメント](https://about.gitlab.com/support/statement-of-support/#ci-cd-templates)は、アナライザーイメージの特定のコンテンツに依存するものを含め、ドキュメント化されていないカスタマイズを除外します。たとえば、`before_script`に追加のパッケージをインストールすることは、サポートされている修正ではありません。それでも、このタイプのカスタマイズに依存する場合は、[この変更に関する非推奨化の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/471869#action-required)を参照して、この変更への対応方法を学習するか、現在のカスタマイズに関するフィードバックを提供してください。

</div>
</div>

<div class="milestone-wrapper" data-milestone="17.0">

## GitLab 17.0

<div class="deprecation breaking-change" data-milestone="17.0">

### Kubernetesのエージェントのオプション`ca-cert-file`の名前変更

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/437728)を参照してください。

</div>

Kubernetes向けGitLabエージェント（agentk）では、`--ca-cert-file`コマンドラインオプションとそれに対応する`config.caCert` Helmチャート値の名前がそれぞれ`--kas-ca-cert-file`と`config.kasCaCert`に変更されました。

古い`--ca-cert-file`オプションと`config.caCert`オプションは非推奨になり、GitLab 17.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### HerokuishのAuto DevOpsサポートは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/211643)を参照してください。

</div>

HerokuishのAuto DevOpsサポートは、[Cloud Native Buildpacks](https://docs.gitlab.com/topics/autodevops/stages/#auto-build-using-cloud-native-buildpacks)を優先して非推奨になります。[HerokuishからCloud Native Buildpacksにビルドを移行する](https://docs.gitlab.com/topics/autodevops/stages/#moving-from-herokuish-to-cloud-native-buildpacks)必要があります。GitLab 14.0からは、Auto BuildはデフォルトでCloud Native Buildpacksを使用します。

Cloud Native Buildpacksは自動テストをサポートしていないため、Auto DevOpsの自動テスト機能も非推奨です。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### ダッシュ（`-`）文字を含む自動生成されたMarkdownアンカーリンク

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/440733)を参照してください。

</div>

GitLabは、すべての見出しに対して自動的にアンカーリンクを作成するため、MarkdownドキュメントまたはWikiページの特定の位置にリンクできます。ただし、一部のエッジケースでは、自動生成されたアンカーは、多くのユーザーが予想するよりも少ないダッシュ（`-`）文字で作成されます。たとえば、`## Step - 1`の見出しでは、他のほとんどのMarkdownツールとLinterは`#step---1`を予期します。しかし、GitLabは`#step-1`のアンカーを生成し、連続するダッシュは1つに圧縮されます。

GitLab 17.0では、連続するダッシュを削除しないようにすることで、自動生成されたアンカーを業界標準に合わせます。17.0では、Markdownドキュメントがあり、複数のダッシュを持つ可能性のある見出しにリンクしている場合は、このエッジケースを回避するために見出しを更新する必要があります。上記の例では、ページ内リンクが引き続き機能するように、`## Step - 1`を`## Step 1`に変更できます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### CiRunner.projectsのデフォルトの並べ替えを`id_desc`に変更

<div class="deprecation-notes">

- GitLab <span class="milestone">16.0</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/372117)を参照してください。

</div>

`CiRunner.projects`のフィールドのデフォルトの並べ替え順の値が、`id_asc`から`id_desc`に変更されます。返されるプロジェクトの順序が`id_asc`になることが信頼できる場合は、選択を明示的にするためにスクリプトを変更してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### 一般的な設定でのコンプライアンスフレームワーク

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/422783)を参照してください。

</div>

コンプライアンスフレームワークの管理を、[コンプライアンスセンター](https://docs.gitlab.com/user/compliance/compliance_center/)のフレームワークおよびプロジェクトレポートに移動しました。

そのため、GitLab 17.0では、グループおよびプロジェクトの**全般**設定ページからコンプライアンスフレームワークの管理を削除します。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### SwiftおよびOSSストレージドライバーのコンテナレジストリのサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">16.6</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/container-registry/-/issues/1141)を参照してください。

</div>

コンテナレジストリは、ストレージドライバーを使用して、さまざまなオブジェクトストレージプラットフォームと連携します。各ドライバーのコードは比較的自己完結型ですが、これらのドライバーのメンテナンス負荷は高くなっています。各ドライバーの実装は一意であり、ドライバーを変更するには、その特定のドライバーに関する高度なドメイン専門知識が必要です。

メンテナンスコストを削減するために、OSS（Object Storage Service）およびOpenStack Swiftのサポートを非推奨にしています。どちらもアップストリームのDocker Distributionからすでに削除されています。これは、[オブジェクトストレージのサポート](https://docs.gitlab.com/administration/object_storage/#supported-object-storage-providers)に関して、より広範なGitLab製品の提供内容とコンテナレジストリを整合させるのに役立ちます。

OSS には[S3互換モード](https://www.alibabacloud.com/help/en/oss/developer-reference/compatibility-with-amazon-s3)があるため、サポートされているドライバーに移行できない場合は、それを使用することを検討してください。Swiftは、S3ストレージドライバーでも必要な[S3 API操作に対応](https://docs.openstack.org/swift/latest/s3_compat.html)しています。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### DAST ZAPの高度な設定変数の非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">15.7</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/383467)を参照してください。

</div>

GitLab 15.7で新しいブラウザベースのDASTアナライザーが一般公開になったため、将来的にはデフォルトのDASTアナライザーにすることを目指しています。これに備えて、従来のDAST変数`DAST_ZAP_CLI_OPTIONS`および`DAST_ZAP_LOG_CONFIGURATION`は非推奨となり、GitLab 17.0で削除される予定です。これらの変数は、OWASP ZAPに基づいていた従来のDASTアナライザーの高度な設定を可能にしていました。これらの機能はZAPの動作に固有のものであるため、新しいブラウザベースのアナライザーには含まれません。

これらの3つの変数は、GitLab 17.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### 依存関係スキャンでのSBOMメタデータプロパティの誤り

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/438779)を参照してください。

</div>

GitLab 17.0では、CycloneDX SBOM レポートの次のメタデータプロパティのサポートが削除されます。

- `gitlab:dependency_scanning:input_file`
- `gitlab:dependency_scanning:package_manager`

これらのプロパティは、GitLab 15.7で依存関係スキャンによって生成されたSBOMに追加されました。ただし、これらのプロパティは正しくなく、[GitLab CycloneDXプロパティ分類](https://docs.gitlab.com/development/sec/cyclonedx_property_taxonomy/)に準拠していませんでした。この問題に対処するために、次の正しいプロパティがGitLab 15.11で追加されました。

- `gitlab:dependency_scanning:input_file:path`
- `gitlab:dependency_scanning:package_manager:name`

正しくないプロパティは、下位互換性を保つために保持されていました。これらは現在非推奨であり、17.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### sbt 1.0.Xの依存関係スキャンのサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">16.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/415835)を参照してください。

</div>

sbtの非常に古いバージョンをサポートすると、メンテナンスコストを増やすことなく、このパッケージマネージャーでの追加のユースケースのサポートを改善することができなくなります。

sbtのバージョン1.1.0は6年前にリリースされており、依存関係スキャンが機能しなくなるため、1.0.xからアップグレードすることをお勧めします。

</div>

<div class="deprecation " data-milestone="17.0">

### 一時ストレージの増加に関連するGraphQLフィールを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.7</span>で発表
- GitLab <span class="milestone">17.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/385720)を参照してください。

</div>

GraphQLフィールドの`isTemporaryStorageIncreaseEnabled`と`temporaryStorageIncreaseEndsOn`は非推奨になりました。これらのGraphQLフィールドは、一時ストレージの増加プロジェクトに関連しています。プロジェクトはキャンセルされていて、フィールドは使用されていませんでした。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### コンテナスキャンのGrypeスキャナーを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/439164)を参照してください。

</div>

GitLab Container ScanningアナライザーでのGrypeスキャナーのサポートは、GitLab 16.9で非推奨になります。

GitLab 17.0以降、Grypeアナライザーは、[サポートに関する声明](https://about.gitlab.com/support/statement-of-support/#version-support)で説明されている限定的な修正を除き、保守されなくなります。

Trivyスキャナーを使用する`CS_ANALYZER_IMAGE`のデフォルト設定を使用することをお勧めします。

Grypeアナライザーイメージの既存の現在のメジャーバージョンは、GitLab 19.0まで最新のアドバイザリーデータベースとオペレーティングシステムパッケージで更新され続けます。その時点で、アナライザーは動作を停止します。

19.0の後もGrypeを引き続き使用するには、[セキュリティスキャナーのインテグレーションに関するドキュメント](https://docs.gitlab.com/development/integrations/secure/)を参照して、GitLabとの独自のインテグレーションを作成する方法を確認してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### ライセンススキャンCIテンプレートを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/439157)を参照してください。

</div>

GitLab 17.0では、ライセンススキャンCIテンプレートが削除されます。

- [`Jobs/License-Scanning.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/6d9956863d3cd066edc50a29767c2cd4a939c6fd/lib/gitlab/ci/templates/Jobs/License-Scanning.gitlab-ci.yml)
- [`Jobs/License-Scanning.latest.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/6d9956863d3cd066edc50a29767c2cd4a939c6fd/lib/gitlab/ci/templates/Jobs/License-Scanning.latest.gitlab-ci.yml)
- [`Security/License-Scanning.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/6d9956863d3cd066edc50a29767c2cd4a939c6fd/lib/gitlab/ci/templates/Security/License-Scanning.gitlab-ci.yml)

上記のテンプレートのいずれかを含むCI設定は、GitLab 17.0では機能しなくなります。

代わりに、[CycloneDXファイルのライセンススキャン](https://docs.gitlab.com/user/compliance/license_scanning_of_cyclonedx_files/)を使用することをお勧めします。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### 依存関係スキャンおよびライセンススキャンでPython 3.9を非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/441201)を参照してください。

</div>

GitLab 16.9以降、依存関係スキャンおよびライセンススキャンでのPython 3.9のサポートは非推奨になります。GitLab 17.0では、Python 3.10が依存関係スキャンCI/CDジョブのデフォルトバージョンです。

GitLab 17.0以降、依存関係スキャンおよびライセンススキャン機能は、[互換性のあるロックファイル](https://docs.gitlab.com/user/application_security/dependency_scanning/#obtaining-dependency-information-by-parsing-lockfiles)なしでは、Python 3.9を必要とするプロジェクトをサポートしなくなります。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GitLab RunnerでWindows CMDを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.1</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/414864)を参照してください。

</div>

GitLab 11.11では、WindowsバッチexecutorであるCMD Shellは、PowerShellを優先して、GitLab Runnerで非推奨になりました。それ以降も、CMD ShellはGitLab Runnerで引き続きサポートされています。ただし、これにより、エンジニアリングチームとWindowsでRunner を使用しているお客様の両方にとって、複雑さが増しています。17.0で、GitLab RunnerからのWindows CMDのサポートを完全に削除する予定です。お客様は、Shell executorでWindows上でRunnerを使用する場合は、PowerShellを使用するように計画する必要があります。お客様は、削除の問題の[問題29479](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29479)でフィードバックを提供したり、質問したりできます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `CiRunnerManager`で複製された`CiRunner` GraphQLフィールドを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.2</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/415185)を参照してください。

</div>

これらのフィールド（`architectureName`、`ipAddress`、`platformName`、`revision`、`version`）は、Runner設定内でグループ化されたRunnerマネージャーの導入により重複しているため、[GraphQL `CiRunner`](https://docs.gitlab.com/api/graphql/reference/#cirunner)タイプから非推奨になりました。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### TerraformモジュールCI/CDテンプレートで`fmt`ジョブを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/440249)を参照してください。

</div>

TerraformモジュールCI/CDテンプレートの`fmt`ジョブは非推奨となり、GitLab 17.0で削除されます。これは、次のテンプレートに影響します。

- `Terraform-Module.gitlab-ci.yml`
- `Terraform/Module-Base.gitlab-ci.yml`

次のものを使用して、Terraform `fmt`ジョブを手動でパイプラインに追加し直すことができます。

```yaml
fmt:
  image: hashicorp/terraform
  script: terraform fmt -chdir "$TF_ROOT" -check -diff -recursive
```

[OpenTofu CI/CDコンポーネント](https://gitlab.com/components/opentofu)の`fmt`テンプレートを使用することもできます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### 脆弱性管理機能から`message`フィールドを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.1</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/411573)を参照してください。

</div>

このMRは、`VulnerabilityCreate` GraphQL変異の`message`フィールド、および脆弱性エクスポートの`AdditionalInfo`列を非推奨にします。メッセージフィールドは、GitLab 16.0でセキュリティレポートスキーマから削除され、他の場所では使用されなくなっています。

</div>

<div class="deprecation " data-milestone="17.0">

### GitLab Runner Kubernetes executorで`terminationGracePeriodSeconds`を非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.3</span>で発表
- GitLab <span class="milestone">17.0</span>でサポート終了
- GitLab <span class="milestone">17.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28165)を参照してください。

</div>

GitLab Runner Kubernetes executor設定である`terminationGracePeriodSeconds`は非推奨となり、GitLab 17.0で削除されます。KubernetesでGitLab Runnerワーカーポッドのクリーンアップと終了を管理するには、代わりに`cleanupGracePeriodSeconds`と`podTerminationGracePeriodSeconds`を設定する必要があります。`cleanupGracePeriodSeconds`と`podTerminationGracePeriodSeconds`の使用方法については、[GitLab Runner Executorに関するドキュメント](https://docs.gitlab.com/runner/executors/kubernetes/#other-configtoml-settings)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### 機能フラグAPIで`version`フィールドを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/437986)を参照してください。

</div>

[機能フラグREST API](https://docs.gitlab.com/api/feature_flags/)の`version`フィールドは非推奨となり、GitLab 17.0で削除されます。

`version`フィールドが削除されると、従来の機能フラグを作成する方法はなくなります。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### デベロッパーロールから脆弱性状態の変更を非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.4</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/424133)を参照してください。

</div>

デベロッパーが脆弱性状態を変更する機能は、現在非推奨になっています。今後のGitLab 17.0リリースで破壊的な変更を加え、この機能を デベロッパーロールから削除する予定です。デベロッパーにこの権限を引き続き付与したいユーザーは、デベロッパー用の[カスタムロールを作成](https://docs.gitlab.com/user/permissions/#custom-roles)し、`admin_vulnerability`権限を追加して、このアクセス権を付与できます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GitLab Self-Managedでグループオーナーのカスタムロール作成を非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/439284)を参照してください。

</div>

GitLab Self-Managed 17.0では、グループオーナーに対するカスタムロールの作成が削除されます。この機能は、管理者専用のインスタンスレベルにのみ移動します。グループオーナーは、グループレベルでカスタムロールを割り当てることができます。

GitLab.comのグループオーナーは、引き続きカスタムロールを管理し、グループレベルで割り当てることができます。

APIを使用してGitLab Self-Managedでカスタムロールを管理する場合、新しいインスタンスエンドポイントが追加されており、これはAPI操作を続行するために必須です。

- インスタンス上のすべてのメンバーロールを一覧表示 - `GET /api/v4/member_roles`
- インスタンスにメンバーロールを追加 - `POST /api/v4/member_roles`
- インスタンスからメンバーロールを削除 - `DELETE /api/v4/member_roles/:id`

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL VulnerabilityTypeからのフィールド`hasSolutions`を非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.3</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/414895)を参照してください。

</div>

GraphQLフィールド`Vulnerability.hasSolutions`は非推奨となり、GitLab 17.0で削除されます。代わりに`Vulnerability.hasRemediations`を使用してください。

</div>

<div class="deprecation " data-milestone="17.0">

### 従来のShellのエスケープおよびクォートRunner Shell executorを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">15.11</span>で発表
- GitLab <span class="milestone">17.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/406679)を参照してください。

</div>

変数の展開を処理するためのRunnerの従来のエスケープシーケンスメカニズムは、準最適なAnsi-Cクォート実装を実装します。このメソッドは、Runnerが二重引用符で囲まれた引数を展開することを意味します。15.11の時点で、Runner Shell executorでの従来のエスケープおよびクォートメソッドを非推奨にしています。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### サインインページのカスタムテキストに関連する非推奨のパラメータ

<div class="deprecation-notes">

- GitLab <span class="milestone">16.2</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124461)を参照してください。

</div>

パラメータの`sign_in_text`と`help_text`は、[設定API](https://docs.gitlab.com/api/settings/)では非推奨です。サインインページとサインアップページにカスタムテキストを追加するには、[外観API](https://docs.gitlab.com/api/appearance/)の`description`フィールドを使用します。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Windows Server 2022を優先してWindows Server 2019を非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/438554)を参照してください。

</div>

Windows上のGitLab.com Runner用のWindows Server 2022（ベータ版）のリリースを最近発表しました。それに伴い、GitLab 17.0で Windows 2019を非推奨にします。

Windows 2022の使用への移行方法の詳細については、[GitLab.com RunnerのWindows 2022サポートが利用可能になりました](https://about.gitlab.com/blog/2024/01/22/windows-2022-support-for-gitlab-saas-runners/)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### DingTalk OmniAuthプロバイダー

<div class="deprecation-notes">

- GitLab <span class="milestone">15.10</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/390855)を参照してください。

</div>

GitLabにDingTalk OmniAuthプロバイダーを提供する`omniauth-dingtalk` gemは、次のメジャーリリースであるGitLab 17.0で削除されます。このgemはほとんど使用されておらず、JiHuエディションに適しています。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Gitaly設定内のストレージの重複

<div class="deprecation-notes">

- GitLab <span class="milestone">16.10</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitaly/-/issues/5598)を参照してください。

</div>

同じストレージパスを指す複数のGitalyストレージの設定のサポートは非推奨であり、GitLab 17.0で削除されます。GitLab 17.0以降では、このタイプの設定でエラーが発生します。

このタイプの設定のサポートを削除する理由は、バックグラウンドリポジトリのメンテナンスで問題が発生する可能性があり、将来のGitalyストレージの実装と互換性がないためです。

インスタンス管理者は、`gitlab.rb`設定ファイルの`gitaly['configuration']`セクションの`storage`エントリを更新して、各ストレージが一意のパスで設定されていることを確認する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### ダウンストリームパイプラインで修正されたファイルタイプ変数の展開

<div class="deprecation-notes">

- GitLab <span class="milestone">16.6</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/419445)を参照してください。

</div>

以前は、別のCI/CD変数で[ファイルタイプCI/CD変数](https://docs.gitlab.com/ci/variables/#use-file-type-cicd-variables)を参照しようとすると、CI/CD変数はファイルの内容を含むように展開されていました。この動作は、一般的なシェル変数展開ルールに準拠していなかったため、正しくありませんでした。CI/CD変数の参照は、ファイルの内容ではなく、ファイルへのパスのみを含むように展開する必要があります。これは[GitLab 15.7のほとんどのユースケースで修正されました](https://gitlab.com/gitlab-org/gitlab/-/issues/29407)。残念ながら、CI/CD変数をダウンストリームパイプラインに渡すことは、まだ修正されていないエッジケースでしたが、GitLab 17.0で修正される予定です。

この変更により、`.gitlab-ci.yml`ファイルで設定された変数は、ファイル変数を参照してダウンストリームパイプラインに渡すことができ、ファイル変数もダウンストリームパイプラインに渡されます。ダウンストリームパイプラインは、ファイルの内容ではなく、ファイルパスへの変数参照を展開します。

この破壊的な変更により、ダウンストリームパイプラインでのファイル変数の展開に依存するユーザーワークフローが混乱する可能性があります。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Geo: デザインとプロジェクトの従来のレプリケーション詳細ルート（非推奨）

<div class="deprecation-notes">

- GitLab <span class="milestone">16.4</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/424002)を参照してください。

</div>

従来のデータ型から[Geoセルフサービスフレームワーク](https://docs.gitlab.com/development/geo/framework/)への移行の一環として、次のレプリケーション詳細ルートは非推奨になります。

- デザイン`/admin/geo/replication/designs`は`/admin/geo/sites/<Geo Node/Site ID>/replication/design_management_repositories`に置き換えられました
- プロジェクト`/admin/geo/replication/projects`は`/admin/geo/sites/<Geo Node/Site ID>/replication/projects`に置き換えられました

GitLab 16.4から17.0までは、従来のルートのルックアップは自動的に新しいルートにリダイレクトされます。17.0でリダイレクトを削除します。従来のルートを使用する可能性のあるブックマークまたはスクリプトを更新してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GitLab Helmチャートの値`gitlab.kas.privateApi.tls.*`は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/4097)を参照してください。

</div>

KASとHelmチャートコンポーネント間のTLS通信を容易にするために、`global.kas.tls.*` Helm値を導入しました。古い値`gitlab.kas.privateApi.tls.enabled`と`gitlab.kas.privateApi.tls.secretName`は非推奨となり、GitLab 17.0で削除される予定です。

新しい値ではKASのTLSを有効にするための合理化された包括的な方法が提供されるため、`gitlab.kas.privateApi.tls.*`の代わりに`global.kas.tls.*`を使用する必要があります。`gitlab.kas.privateApi.tls.*`の詳細については、以下を参照してください。

- `global.kas.tls.*`値を導入する[マージリクエスト](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2888)。
- [非推奨の`gitlab.kas.privateApi.tls.*`に関するドキュメント](https://docs.gitlab.com/charts/charts/gitlab/kas/#enable-tls-communication-through-the-gitlabkasprivateapi-attributes-deprecated)。
- [新しい`global.kas.tls.*`に関するドキュメント](https://docs.gitlab.com/charts/charts/globals/#tls-settings-1)。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GitLab RunnerのProvenanceメタデータSLSA v0.2ステートメント

<div class="deprecation-notes">

- GitLab <span class="milestone">16.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36869)を参照してください。

</div>

RunnerはProvenanceメタデータを生成し、現在SLSA v0.2に準拠するステートメントを生成するようにデフォルト設定されています。SLSA v1.0がリリースされ、GitLabでサポートされるようになったため、v0.2ステートメントは非推奨となり、GitLab 17.0での削除が計画されています。SLSA v1.0ステートメントは、GitLab 17.0で新しいデフォルトのステートメント形式になる予定です。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### サポートされていないメソッドによるGraphQL APIアクセス

<div class="deprecation-notes">

- GitLab <span class="milestone">17.0</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/442520)を参照してください。

</div>

GitLab 17.0以降、GraphQLへのアクセスを、[すでにドキュメント化されているサポート対象のトークンタイプ](https://docs.gitlab.com/api/graphql/#token-authentication)を通してのみ行うように制限します。

ドキュメント化されたサポート対象のトークンタイプをすでに使用している顧客には、破壊的な変更はありません。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL `networkPolicies`リソースは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/421440)を参照してください。

</div>

`networkPolicies`[GraphQLリソース](https://docs.gitlab.com/api/graphql/reference/#projectnetworkpolicies)は非推奨となっていて、GitLab 17.0で削除されます。GitLab 15.0以降、このフィールドはデータを返していません。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQLフィールド`confidential`をノート上で`internal`に変更

<div class="deprecation-notes">

- GitLab <span class="milestone">15.5</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/371485)を参照してください。

</div>

`Note`の`confidential`フィールドは非推奨となり、`internal`に名前が変更されます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQLフィールド`registrySizeEstimated`は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.2</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/416509)を参照してください。

</div>

明確にするため、GraphQLフィールド`registrySizeEstimated`の名前を、対応するものと一致するように`containerRegistrySizeIsEstimated`に変更しました。`registrySizeEstimated`はGitLab 16.2で非推奨となっていて、GitLab 17.0で削除されます。代わりにGitLab 16.2で導入された`containerRegistrySizeIsEstimated`を使用してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQLフィールド`totalWeight`は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.3</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/416219)を参照してください。

</div>

GraphQLを使用して、イシューボードのイシューの合計ウェイトをクエリできます。ただし、`totalWeight`フィールドは最大サイズ2147483647に制限されています。その結果、`totalWeight`は非推奨となり、GitLab 17.0で削除されます。

代わりに、GitLab 16.2で導入された`totalIssueWeight`を使用してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQLのタイプ`RunnerMembershipFilter`の名前を`CiRunnerMembershipFilter`に変更

<div class="deprecation-notes">

- GitLab <span class="milestone">16.0</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/409333)を参照してください。

</div>

GraphQLのタイプ`RunnerMembershipFilter`の名前が`CiRunnerMembershipFilter`に変更されました。GitLab 17.0では、`RunnerMembershipFilter`タイプのエイリアスが削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL:`SharedRunnersSetting` enumの`DISABLED_WITH_OVERRIDE`値は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/385636)を参照してください。

</div>

GitLab 17.0では、`SharedRunnersSetting` GraphQL enumタイプの`DISABLED_WITH_OVERRIDE`値が削除されます。代わりに`DISABLED_AND_OVERRIDABLE`を使用してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL: `canDestroy`と`canDelete`のサポートを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.6</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/390754)を参照してください。

</div>

パッケージレジストリのユーザーインターフェースは、GitLab GraphQL APIに依存しています。誰もが簡単にコントリビュートできるように、すべてのGitLab製品領域でフロントエンドが一貫してコーディングされていることが重要です。ただし、GitLab 16.6より前は、パッケージレジストリUIの権限処理が製品の他の領域とは異なっていました。

16.6では、パッケージレジストリをGitLabの他の部分と連携させるために、`Types::PermissionTypes::Package`タイプの`UserPermissions`フィールドを新たに追加しました。この新しいフィールドは、`Package`、`PackageBase`、および`PackageDetailsType`タイプの`canDestroy`フィールドを置き換えます。また、`ContainerRepository`、`ContainerRepositoryDetails`、および`ContainerRepositoryTag`のフィールド`canDelete`も置き換えます。GitLab 17.0では、`canDestroy`フィールドと`canDelete`フィールドが削除されます。

これは17.0で完了する破壊的な変更です。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### HashiCorp Vaultインテグレーションは、デフォルトで`CI_JOB_JWT` CI/CDジョブトークンの使用を停止

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/366798)を参照してください。

</div>

JWTとOIDCを使用してCIワークフローのセキュリティを向上させる取り組みの一環として、ネイティブHashiCorpインテグレーションもGitLab 16.0で更新されています。Vaultからシークレットを取得するために[`secrets:vault`](https://docs.gitlab.com/ci/yaml/#secretsvault)キーワードを使用するすべてのプロジェクトは、[IDトークンを使用するように設定](https://docs.gitlab.com/ci/secrets/id_token_authentication/#configure-automatic-id-token-authentication)する必要があります。IDトークンは15.7で導入されました。

この変更に備えるには、新しい[`id_tokens`](https://docs.gitlab.com/ci/yaml/#id_tokens)キーワードを使用し、`aud`クレームを設定します。バインドされたオーディエンスの前に`https://`が付いていることを確認してください。

GitLab 15.9から15.11では、[**JSON Web Token（JWT）アクセスを制限する**設定を有効にする](https://docs.gitlab.com/ci/secrets/id_token_authentication/#enable-automatic-id-token-authentication)ことができます。これにより、古いトークンがジョブに公開されるのを防ぎ、[`secrets:vault`キーワードのIDトークン認証](https://docs.gitlab.com/ci/secrets/id_token_authentication/#configure-automatic-id-token-authentication)が有効になります。

GitLab 16.0以降:

- この設定は削除されます。
- `id_tokens`キーワードを使用するCI/CDジョブは、`secrets:vault`でIDトークンを使用でき、利用可能な`CI_JOB_JWT*`トークンはありません。
- `id_tokens`キーワードを使用しないジョブは、GitLab 17.0まで`CI_JOB_JWT*`トークンを引き続き使用できます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Auto DevOpsビルドのHerokuイメージのアップグレード

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/437937)を参照してください。

</div>

GitLab 17.0では、`auto-build-image`プロジェクトは`heroku/builder:20`イメージから`heroku/builder:22`にアップグレードされます。

新しいイメージの動作をテストするには、CI/CD変数の`AUTO_DEVOPS_BUILD_IMAGE_CNB_BUILDER`を`heroku/builder:22`に設定します。

GitLab 17.0以降も`heroku/builder:20`を引き続き使用するには、`AUTO_DEVOPS_BUILD_IMAGE_CNB_BUILDER`を`heroku/builder:20`に設定します。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### 内部コンテナレジストリAPIタグの削除エンドポイント

<div class="deprecation-notes">

- GitLab <span class="milestone">16.4</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/container-registry/-/issues/1094)を参照してください。

</div>

DockerレジストリHTTP API V2仕様（後に[OCIディストリビューション仕様](https://github.com/opencontainers/distribution-spec/blob/main/spec.md)に置き換えられました）には、タグの削除操作が含まれていませんでした。また、（タグではなくマニフェストの削除を含む）安全ではなく低速な回避策を使用して、同じ目的を達成する必要がありました。

タグの削除は重要な機能であるため、DockerおよびOCIディストリビューション仕様の範囲を超えてV2 APIを拡張し、GitLabコンテナレジストリにタグ削除操作を追加しました。

それ以降、OCIディストリビューション仕様はいくつかの更新が行われ、[`DELETE /v2/<name>/manifests/<tag>`エンドポイント](https://github.com/opencontainers/distribution-spec/blob/main/spec.md#deleting-tags)を使用してタグ削除操作を実行できるようになりました。

これにより、コンテナレジストリにはまったく同じ機能を提供する2つのエンドポイントが残されています。`DELETE /v2/<name>/tags/reference/<tag>`はカスタムGitLabタグ削除エンドポイントであり、`DELETE /v2/<name>/manifests/<tag>`はGitLab 16.4で導入されたOCI準拠のタグ削除エンドポイントです。

カスタムGitLabタグ削除エンドポイントのサポートはGitLab 16.4で非推奨となり、GitLab 17.0で削除される予定です。

このエンドポイントは、パブリック[GitLabコンテナレジストリAPI](https://docs.gitlab.com/api/container_registry/)ではなく、**内部**コンテナレジストリアプリケーションAPIによって使用されます。ほとんどのコンテナレジストリユーザーは、何も操作を行う必要はありません。新しいOCI準拠のエンドポイントに移行する際、タグの削除に関連するすべてのGitLab UIおよびAPI機能はそのまま残ります。

内部コンテナレジストリAPIにアクセスし、元のタグ削除エンドポイントを使用する場合は、新しいエンドポイントに更新する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### JWT `/-/jwks`インスタンスエンドポイントは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.7</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/221031)を参照してください。

</div>

GitLab 17.0で[古いJSON Webトークンバージョンが非推奨](https://docs.gitlab.com/update/deprecations/?removal_milestone=17.0#old-versions-of-json-web-tokens-are-deprecated)になることで、`/oauth/discovery/keys`のエイリアスである関連する`/-/jwks`エンドポイントは不要になり、削除されます。認証設定で`jwks_url`を指定している場合は、代わりに設定を`oauth/discovery/keys`に更新し、エンドポイントでの`/-/jwks`の使用箇所をすべて削除します。認証設定で`oauth_discovery_keys`をすでに使用し、エンドポイントで`/-/jwks`エイリアスをすでに使用している場合は、エンドポイントから`/-/jwks`を削除します。たとえば、`https://gitlab.example.com/-/jwks`を`https://gitlab.example.com`に変更します。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### 従来のGeo Prometheusメトリクス

<div class="deprecation-notes">

- GitLab <span class="milestone">16.6</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/430192)を参照してください。

</div>

[Geoセルフサービスフレームワーク](https://docs.gitlab.com/development/geo/framework/)へのプロジェクトの移行後、多くの[Prometheus](https://docs.gitlab.com/administration/monitoring/prometheus/)メトリクスを非推奨にしました。次のGeo関連のPrometheusメトリクスは非推奨となり、17.0で削除されます。以下の表に、非推奨のメトリクスとそれぞれの代替メトリクスを示します。代替メトリクスは、GitLab 16.3.0以降で使用できます。

| 非推奨のメトリクス                        |  代替メトリクス                            |
| ---------------------------------------- | ---------------------------------------------- |
| `geo_repositories_synced`                | `geo_project_repositories_synced`              |
| `geo_repositories_failed`                | `geo_project_repositories_failed`              |
| `geo_repositories_checksummed`           | `geo_project_repositories_checksummed`         |
| `geo_repositories_checksum_failed`       | `geo_project_repositories_checksum_failed`     |
| `geo_repositories_verified`              | `geo_project_repositories_verified`            |
| `geo_repositories_verification_failed`   | `geo_project_repositories_verification_failed` |
| `geo_repositories_checksum_mismatch`     |  利用可能なものはありません                                |
| `geo_repositories_retrying_verification` |  利用可能なものはありません                                |

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### ライセンスリストは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/436100)を参照してください。

</div>

今日のGitLabでは、プロジェクトのすべてのライセンスとそのライセンスを使用するすべてのコンポーネントのリストを、ライセンスリストで確認できます。16.8の時点で、ライセンスリストは非推奨であり、破壊的な変更として17.0で削除される予定です。[グループ依存関係リスト](https://docs.gitlab.com/user/application_security/dependency_list/)のリリースと、プロジェクトおよびグループの依存関係リストでライセンスごとにフィルター処理できる機能により、プロジェクトまたはグループが依存関係リストで使用しているすべてのライセンスにアクセスできるようになりました。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### sbt 1.0.Xのライセンススキャンのサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">16.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/437591)を参照してください。

</div>

GitLab 17.0では、sbt 1.0.xのライセンススキャンのサポートが削除されます。

sbt 1.0.xからのアップグレードをお勧めします。

</div>

<div class="deprecation " data-milestone="17.0">

### Ubuntu 18.04のLinuxパッケージ

<div class="deprecation-notes">

- GitLab <span class="milestone">16.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8082)を参照してください。

</div>

Ubuntu 18.04の標準サポートは、[2023年6月に終了しました](https://wiki.ubuntu.com/Releases)。

GitLab 17.0以降、Ubuntu 18.04のLinuxパッケージは提供されません。

GitLab 17.0以降に備えるには:

1. GitLabインスタンスを実行しているサーバーをUbuntu 18.04から Ubuntu 20.04またはUbuntu 22.04に移行します。
1. 現在使用しているUbuntuのバージョンに対応したLinuxパッケージを使用して、GitLabインスタンスをアップグレードします。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### リポジトリディレクトリの一覧表示Rakeタスク

<div class="deprecation-notes">

- GitLab <span class="milestone">16.7</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/384361)を参照してください。

</div>

`gitlab-rake gitlab:list_repos` Rakeタスクは機能せず、GitLab 17.0で削除されます。GitLabを移行する場合は、代わりに[バックアップと復元](https://docs.gitlab.com/administration/operations/moving_repositories/#recommended-approach-in-all-cases)を使用してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GraphQL APIを使用してパッケージ設定を変更する機能を提供するメンテナーロール

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/370471)を参照してください。

</div>

メンテナーロールを持つユーザーがGraphQL APIを使用してグループの**パッケージとレジストリ**の設定を変更する機能はGitLab 15.8で非推奨となり、GitLab 17.0で削除される予定です。これらの設定には以下が含まれます。

- [重複するパッケージのアップロードの許可または禁止](https://docs.gitlab.com/user/packages/maven_repository/#do-not-allow-duplicate-maven-packages)。
- [パッケージリクエストの転送](https://docs.gitlab.com/user/packages/maven_repository/#request-forwarding-to-maven-central)。
- [依存関係プロキシのライフサイクルルールの有効化](https://docs.gitlab.com/user/packages/dependency_proxy/reduce_dependency_proxy_storage/)。

GitLab 17.0以降では、GitLab UIまたはGraphQL APIを使用してグループの**パッケージとレジストリ**の設定を変更するには、グループのオーナーロールが必要です。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### 依存関係スキャンおよびライセンススキャンでの3.8.8より前のMavenバージョンのサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/438772)を参照してください。

</div>

GitLab 17.0では、3.8.8より前のMavenバージョンの依存関係スキャンとライセンススキャンのサポートが削除されます。

3.8.8以降にアップグレードすることをお勧めします。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Sidekiqオプションの最小並行処理と最大並行処理

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/439687)を参照してください。

</div>

- Linuxパッケージ（Omnibus）インストールの場合、[`sidekiq['min_concurrency']`および`sidekiq['max_concurrency']`](https://docs.gitlab.com/administration/sidekiq/extra_sidekiq_processes/#manage-thread-counts-explicitly)の設定はGitLab 16.9で非推奨となり、GitLab 17.0で削除されます。

  GitLab 16.9以降では、`sidekiq['concurrency']`を使用して、各プロセスで明示的にスレッド数を設定できます。

  上記の変更は、Linuxパッケージ（Omnibus）インストールにのみ適用されます。

- GitLab Helmチャートインストールの場合、`SIDEKIQ_CONCURRENCY_MIN`または`SIDEKIQ_CONCURRENCY_MAX`を`extraEnv`として`sidekiq`サブチャートに渡すことは、GitLab 16.10で非推奨となり、GitLab 17.0で削除されます。

  `concurrency`オプションを使用すると、各プロセスで明示的にスレッド数を設定できます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `/users` REST APIエンドポイントのオフセットページネーションは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.5</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/426547)を参照してください。

</div>

`/users` REST APIのオフセットページネーションはGitLab 16.5で非推奨となり、GitLab 17.0で削除される予定です。代わりに[キーセットページネーション](https://docs.gitlab.com/api/rest/#keyset-based-pagination)を使用してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### 古いバージョンの JSON Webトークンは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/366798)を参照してください。

</div>

OIDCをサポートする[IDトークン](https://docs.gitlab.com/ci/secrets/id_token_authentication/)は、GitLab 15.7で導入されました。これらのトークンは、古いJSON Web Token（JWT）よりも設定がしやすく、OIDCに準拠しており、ID トークンが明示的に設定されているCI/CDジョブでのみ使用できます。IDトークンは、すべてのジョブで公開されている古い`CI_JOB_JWT*` JSON Webトークンよりも安全であるため、これらの古いJSON Webトークンは非推奨になります。

- `CI_JOB_JWT`
- `CI_JOB_JWT_V1`
- `CI_JOB_JWT_V2`

この変更に備えるには、パイプラインを設定して、非推奨のトークンの代わりに[IDトークン](https://docs.gitlab.com/ci/yaml/#id_tokens)を使用するようにします。OIDC準拠のため、`iss`クレームは、`CI_JOB_JWT_V2`トークンで以前に導入された、完全修飾ドメイン名（`https://example.com` など）を使用するようになりました。

GitLab 15.9から15.11では、[**JSON Web Token（JWT）アクセスを制限する**設定を有効にする](https://docs.gitlab.com/ci/secrets/id_token_authentication/#enable-automatic-id-token-authentication)ことができます。これにより、古いトークンがジョブに公開されるのを防ぎ、[`secrets:vault`キーワードのIDトークン認証](https://docs.gitlab.com/ci/secrets/id_token_authentication/#configure-automatic-id-token-authentication)が有効になります。

GitLab 16.0以降:

- この設定は削除されます。
- `id_tokens`キーワードを使用するCI/CDジョブは、`secrets:vault`でIDトークンを使用でき、利用可能な`CI_JOB_JWT*`トークンはありません。
- `id_tokens`キーワードを使用しないジョブは、GitLab 17.0まで`CI_JOB_JWT*`トークンを引き続き使用できます。

GitLab 17.0では、非推奨のトークンは完全に削除され、CI/CDジョブで使用できなくなります。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### OmniAuth Facebookは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.2</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/416000)を参照してください。

</div>

OmniAuth Facebookのサポートは GitLab 17.0で削除されます。最後のgemリリースは2021年に行われ、現在は保守されていません。現在の使用率は0.1%未満です。OmniAuth Facebookを使用している場合は、サポートが削除される前に、[サポートされているプロバイダー](https://docs.gitlab.com/integration/omniauth/#supported-providers)に切り替えてください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### APIペイロードのパッケージパイプラインのページネーション

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/289956)を参照してください。

</div>

`/api/v4/projects/:id/packages`へのAPIリクエストは、パッケージのページネーションされた結果を返します。各パッケージは、この応答ですべてのパイプラインを一覧表示します。パッケージが数百または数千の関連するパイプラインを持つ可能性があるため、これはパフォーマンス上の懸念事項です。

マイルストーン17.0では、API応答から`pipelines`属性を削除します。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### PostgreSQL 13のサポートの停止

<div class="deprecation-notes">

- GitLab <span class="milestone">16.0</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/groups/gitlab-org/-/epics/9065)を参照してください。

</div>

GitLabは[PostgreSQLの年間アップグレードケイデンス](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/data_stores/database/postgresql-upgrade-cadence/)に従います。

PostgreSQL 13のサポートは、GitLab 17.0で削除される予定です。GitLab 17.0では、PostgreSQL 14が最低限必要なPostgreSQLのバージョンとなります。

PostgreSQL 13は、GitLab 16リリースサイクル全体でサポートされます。PostgreSQL 14は、GitLab 17.0より前にアップグレードするインスタンスでもサポートされます。Omnibus Linuxパッケージを使用してインストールした単一のPostgreSQLインスタンスを実行している場合、16.11で自動アップグレードが試行される可能性があります。アップグレードに対応できるように、十分なディスク容量があることを確認してください。詳細については、[Omnibusデータベースのドキュメント](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### プロキシベースのDASTは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.6</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/430966)を参照してください。

</div>

GitLab 17.0以降、プロキシベースのDASTはサポートされません。動的な解析を通じてセキュリティ検出のためにプロジェクトの分析を継続するには、ブラウザベースのDASTに移行してください。プロキシベースのDASTの上に構築されたインキュベーション機能である**Breach and Attack Simulation**も、この非推奨化の対象に含まれており、17.0以降はサポートされません。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Sidekiqの実行に使用されるキューセレクターは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>でサポート終了
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/390787)を参照してください。

</div>

[キューセレクター](https://docs.gitlab.com/administration/sidekiq/processing_specific_job_classes/#queue-selectors)（一連のキューをリッスンする複数のプロセスを持つ）と[ネゲート設定](https://docs.gitlab.com/administration/sidekiq/processing_specific_job_classes/#negate-settings)を使用してSidekiqを実行することは非推奨であり、17.0で完全に削除されます。

キューセレクターから、[すべてのプロセスでのすべてのキューのリッスン](https://docs.gitlab.com/administration/sidekiq/extra_sidekiq_processes/#start-multiple-processes)に移行できます。たとえば、現在Sidekiqがキューセレクター（`sidekiq['queue_selector'] = true`）で`/etc/gitlab/gitlab.rb`の`sidekiq['queue_groups']`に4つの要素で示されるように4つのプロセスで実行されている場合、Sidekiqを変更して、たとえば`sidekiq['queue_groups'] = ['*'] * 4`のように4つすべてのプロセスですべてのキューをリッスンするようにできます。このアプローチは、[リファレンスアーキテクチャ](https://docs.gitlab.com/administration/reference_architectures/5k_users/#configure-sidekiq)でも推奨されています。Sidekiqは、マシン内のCPUの数と同じ数のプロセスを効果的に実行できることに注意してください。

上記のアプローチはほとんどのインスタンスで推奨されますが、Sidekiqは[ルーティングルール](https://docs.gitlab.com/administration/sidekiq/processing_specific_job_classes/#routing-rules)を使用して実行することもでき、これはGitLab.comでも使用されています。[キューセレクターからルーティングルールへの移行ガイド](https://docs.gitlab.com/administration/sidekiq/processing_specific_job_classes/#migrating-from-queue-selectors-to-routing-rules)に従うことができます。ジョブが完全に失われることを避けるために、移行には注意が必要です。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Linux上の小さなGitLab.com Runnerからのタグの削除

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30829)を参照してください。

</div>

ラベルとして使用されていたという歴史的な理由から、小規模なLinux GitLab.com Runnerには多くのタグが付与されていました。`saas-linux-small-amd64`だけを使用するようにタグを効率化し、すべてのGitLab.com Runnerで一貫性を持たせたいと考えています。

タグ`docker`、`east-c`、`gce`、`git-annex`、`linux`、`mongo`、`mysql`、`postgres`、`ruby`、`shared`は非推奨になります。

詳細については、[Linux上の小規模なSaaS Runnerからのタグの削除](https://about.gitlab.com/blog/2023/08/15/removing-tags-from-small-saas-runner-on-linux/)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### 必要なパイプライン設定は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/389467)を参照してください。

</div>

必要なパイプライン設定は GitLab 17.0で削除されます。これは、UltimateプランのGitLab Self-Managedのユーザーに影響します。

必要なパイプライン設定を次のいずれかに置き換える必要があります。

- [コンプライアンスフレームワークにスコープされたセキュリティポリシー](https://docs.gitlab.com/user/application_security/policies/scan_execution_policies/#security-policy-scopes)（試験段階）。
- [コンプライアンスパイプライン](https://docs.gitlab.com/user/group/compliance_pipelines/)（現在利用可能）。

これらの代替ソリューションをお勧めするのは、必要なパイプラインを特定のコンプライアンスフレームワークラベルに割り当てることができ、柔軟性が向上するためです。

コンプライアンスパイプラインは将来的に非推奨となり、セキュリティポリシーに移行します。詳細については、[移行と非推奨のエピック](https://gitlab.com/groups/gitlab-org/-/epics/11275)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GitLab 17.0でのSASTアナライザーのカバレッジ変更

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/412060)を参照してください。

</div>

GitLab SASTでデフォルトで使用される[アナライザー](https://docs.gitlab.com/user/application_security/sast/analyzers/)のサポート数を削減しています。これは、さまざまなプログラミング言語で、より高速で一貫性のあるユーザーエクスペリエンスを実現するための長期的な戦略の一環です。

GitLab 17.0では、以下を行います。

1. [SAST CI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)から一連の言語固有のアナライザーを削除し、[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)で[GitLabがサポートする検出ルール](https://docs.gitlab.com/user/application_security/sast/rules/)でカバレッジを置き換えます。次のアナライザーは現在非推奨となっており、GitLab 17.0でサポートが終了します。
   1. [Brakeman](https://gitlab.com/gitlab-org/security-products/analyzers/brakeman)（Ruby、Ruby on Rails）
   1. [Flawfinder](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder)（C、C++）
   1. [MobSF](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf)（Android、iOS）
   1. [NodeJS Scan](https://gitlab.com/gitlab-org/security-products/analyzers/nodejs-scan)（Node.js）
   1. [PHPCS Security Audit](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit)（PHP）
1. [SAST CI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)を変更して、KotlinおよびScalaコードの[SpotBugsベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)の実行を停止します。代わりに、これらの言語は、[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)で[GitLabがサポートする検出ルール](https://docs.gitlab.com/user/application_security/sast/rules/)を使用してスキャンされます。

ただちに有効になるため、非推奨のアナライザーはセキュリティ更新のみを受け取ります。その他のルーチン改善または更新は保証されません。GitLab 17.0でアナライザーがサポート終了になると、それ以上の更新は提供されません。ただし、これらのアナライザー用に以前に公開されたコンテナイメージを削除したり、カスタムCI/CDパイプラインジョブ定義を使用して実行する機能を削除したりすることはありません。

脆弱性管理システムは、ほとんどの既存の検出結果を更新して、新しい検出ルールと一致するようにします。新しいアナライザーに移行されない検出結果は、[自動的に解決](https://docs.gitlab.com/user/application_security/sast/#automatic-vulnerability-resolution)されます。詳細については、[脆弱性の翻訳ドキュメント](https://docs.gitlab.com/user/application_security/sast/analyzers/#vulnerability-translation)を参照してください。

削除されたアナライザーにカスタマイズを適用した場合、またはパイプラインでSemgrepベースのアナライザーを現在無効にしている場合は、[この変更に関する非推奨の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/412060#action-required)に詳述されているように対応する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `_EXCLUDED_ANALYZERS`変数を使用したスキャン実行ポリシーによるプロジェクト変数のオーバーライド

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/424513)を参照してください。

</div>

[SEP変数を最高の優先度で適用する](https://gitlab.com/gitlab-org/gitlab/-/issues/424028)ことを配信および検証した後、意図しない動作が発見され、ユーザーがパイプライン設定で`_EXCLUDED_PATHS`を設定し、ポリシーとパイプライン設定の両方で`_EXCLUDED_ANALYZERS`を設定できないようにしました。

スキャン実行変数が適切に適用されるようにするため、GitLabスキャンアクションを使用してスキャン実行ポリシーに`_EXCLUDED_ANALYZERS`または`_EXCLUDED_PATHS`変数を指定した場合に、その変数が、除外されたアナライザーに対して定義されたプロジェクト変数をオーバーライドするようになります。

ユーザーは、17.0より前に機能フラグを有効にして、この動作を適用できます。17.0では、`_EXCLUDED_ANALYZERS`/`_EXCLUDED_PATHS`変数を活用するプロジェクトで、その変数が定義されたスキャン実行ポリシーは、デフォルトでオーバーライドされます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### セキュアアナライザーのメジャーバージョン更新

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/438123)を参照してください。

</div>

セキュアなステージでは、GitLab 17.0のリリースと連携して、アナライザーのメジャーバージョンが引き上げられます。

デフォルトの内蔵テンプレートを使用していない場合、またはアナライザーのバージョンを固定している場合は、CI/CDジョブ定義を更新して、固定されたバージョンを削除するか、最新のメジャーバージョンに更新する必要があります。

GitLab 16.0 - 16.11のユーザーは、GitLab 17.0のリリースまでは通常どおりアナライザーの更新を引き続き利用できます。その後、新たに修正されたバグやリリースされた機能はすべて、アナライザーの新しいメジャーバージョンでのみリリースされます。

メンテナンスポリシーに従い、バグや機能を非推奨バージョンにバックポートすることはありません。必要に応じて、セキュリティパッチは最新の3つのマイナーリリース内でバックポートされます。

具体的には、次のアナライザーは非推奨となり、GitLab 17.0のリリース後は更新されなくなります。

- コンテナスキャン: バージョン6
- 依存関係スキャン: バージョン4
- DAST: バージョン4
- DAST API: バージョン3
- Fuzz API: バージョン3
- IaCスキャン: バージョン4
- シークレット検出: バージョン5
- 静的アプリケーションセキュリティテスト（SAST）: [すべてのアナライザー](https://docs.gitlab.com/user/application_security/sast/analyzers/)のバージョン4
  - `brakeman`
  - `flawfinder`
  - `kubesec`
  - `mobsf`
  - `nodejs-scan`
  - `phpcs-security-audit`
  - `pmd-apex`
  - `semgrep`
  - `sobelow`
  - `spotbugs`

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### セキュリティポリシーフィールド`match_on_inclusion`は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/424513)を参照してください。

</div>

[スキャン結果ポリシーの追加フィルターのサポート](https://gitlab.com/groups/gitlab-org/-/epics/6826#note_1341377224)では、`newly_detected`フィールドを`new_needs_triage`および`new_dismissed`の2つのオプションに分割しました。セキュリティポリシーYAMLに両方のオプションを含めることで、元の`newly_detected`フィールドと同じ結果が得られます。ただし、`new_needs_triage`のみを使用することで、フィルターを絞り込んで、無視された検出結果を無視できるようになりました。[エピック10203](https://gitlab.com/groups/gitlab-org/-/epics/10203#note_1545826313)でのディスカッションに基づき、YAML定義の明確化のため、`match_on_inclusion`フィールドの名前を`match_on_inclusion_license`に変更しました。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### セキュリティポリシーフィールド`newly_detected`は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.5</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/422414)を参照してください。

</div>

[スキャン結果ポリシーの追加フィルターのサポート](https://gitlab.com/groups/gitlab-org/-/epics/6826#note_1341377224)では、`newly_detected`フィールドを`new_needs_triage`および`new_dismissed`の2つのオプションに分割しました。セキュリティポリシーYAMLに両方のオプションを含めることで、元の`newly_detected`フィールドと同じ結果が得られます。ただし、`new_needs_triage`のみを使用することで、フィルターを絞り込んで、無視された検出結果を無視できるようになりました。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### 自己ホスト型Sentryバージョン21.4.1以前のサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/435791)を参照してください。

</div>

自己ホスト型Sentryバージョン21.4.1以前のサポートは非推奨となり、GitLab 17.0で削除されます。

自己ホスト型Sentryのバージョンが21.4.1以前の場合、GitLab 17.0以降にアップグレードすると、GitLabインスタンスからエラーを収集できなくなる可能性があります。GitLabインスタンスからSentryインスタンスへのエラーの送信を続行するには、Sentryをバージョン21.5.0以降にアップグレードします。詳細については、[Sentryドキュメント](https://develop.sentry.dev/self-hosted/releases/)を参照してください。

注: 非推奨のサポートは、管理者向けの[GitLabインスタンスのエラー追跡機能](https://docs.gitlab.com/omnibus/settings/configuration/#error-reporting-and-logging-with-sentry)を対象としています。非推奨のサポートは、デベロッパー自身のデプロイ済みアプリケーション用の[GitLabエラー追跡](https://docs.gitlab.com/operations/error_tracking/#sentry-error-tracking)には関連していません。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### バックアップ用のカスタムスキーマの設定のサポートは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/435210)を参照してください。

</div>

Linuxパッケージインストールの場合は`/etc/gitlab/gitlab.rb`の`gitlab_rails['backup_pg_schema'] = '<schema_name>'`を設定し、自己コンパイルインストールの場合は`config/gitlab.yml`を編集することにより、バックアップ用のカスタムスキーマを使用するようにGitLabを設定できました。

この設定は利用できましたが、効果はなく、意図した目的を果たしていませんでした。この構成設定はGitLab 17.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### GitHubインポーターRakeタスク

<div class="deprecation-notes">

- GitLab <span class="milestone">16.6</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/428225)を参照してください。

</div>

GitHubインポーターRakeタスクはGitLab 16.6で非推奨となりました。Rakeタスクは、APIでサポートされているいくつかの機能が欠落していて、積極的にメンテナンスされていません。

このRakeタスクはGitLab 17.0で削除されます。

代わりに、[API](https://docs.gitlab.com/api/import/#import-repository-from-github)または[UI](https://docs.gitlab.com/user/project/import/github/)を使用して GitHubリポジトリをインポートできます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Visual Reviewsツールは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/387751)を参照してください。

</div>

顧客の利用と機能が限られているため、Review AppsのVisual Reviews機能は非推奨となり、削除されます。計画された代替手段はなく、ユーザーはGitLab 17.0の前にVisual Reviewsの使用を停止する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `gitlab-runner exec`コマンドは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.7</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/385235)を参照してください。

</div>

`gitlab-runner exec`コマンドは非推奨となり、16.0でGitLab Runnerから完全に削除されます。`gitlab-runner exec`機能は当初、GitLabインスタンスへの更新をコミットしなくても、ローカルシステムでGitLab CIパイプラインを検証できるようにするために開発されました。ただし、GitLab CIの継続的な進化に伴い、すべてのGitLab CI機能を`gitlab-runner exec`に複製することはもはや実現可能ではありませんでした。パイプライン構文と検証の[シミュレーション](https://docs.gitlab.com/ci/pipeline_editor/#simulate-a-cicd-pipeline)は、GitLabパイプラインエディターで利用できます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Kubernetes向けGitLabエージェントのプルベースのデプロイ機能は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.2</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/406545)を参照してください。

</div>

Kubernetes向けGitLabエージェントに組み込まれているプルベースのデプロイ機能は、Fluxおよび関連するインテグレーションを優先して非推奨とします。

Kubernetes向けGitLabエージェントは**非推奨ではありません**。この変更は、エージェントのプルベースの機能のみに影響します。他のすべての機能はそのまま残り、GitLabは引き続きKubernetes向けエージェントをサポートします。

エージェントをプルベースのデプロイに使用する場合は、[Fluxに移行する](https://docs.gitlab.com/user/clusters/agent/gitops/agent/#migrate-to-flux)必要があります。FluxはGitOps向けの成熟したCNCFプロジェクトであるため、[2023年2月にFluxをGitLabと統合](https://about.gitlab.com/blog/2023/02/08/why-did-we-choose-to-integrate-fluxcd-with-gitlab/)することを決定しました。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Twitter OmniAuthログインオプションはGitLab Self-Managedに対して非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.3</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-com/Product/-/issues/11417)を参照してください。

</div>

Twitter OAuth 1.0a OmniAuthは、使用率が低く、gemのサポートがないため、非推奨となっていて、GitLab 17.0でGitLab Self-Managedに対して削除されます。代わりに、[サポートされている別のOmniAuthプロバイダー](https://docs.gitlab.com/integration/omniauth/#supported-providers)を使用してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### 統合承認ルールは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.1</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/groups/gitlab-org/-/epics/9662)を参照してください。

</div>

統合承認ルールは、より柔軟性の高い複数の承認ルールを優先して非推奨となります。破壊的な変更を行わないと、統合承認ルールを複数の承認ルールに移行できない場合があります。手動での移行を支援するため、移行ドキュメントを導入しました。

統合承認ルールが削除される前に手動で移行しない場合、GitLabは自動的に設定を移行します。複数の承認ルールを使用すると、承認ルールをきめ細かく設定できるようになるため、GitLabに移行を任せた場合、自動移行によって、予想以上に制限の厳しいルールになる可能性があります。予想以上に多くの承認が必要な問題が発生した場合は、移行ルールを確認してください。

GitLab 15.11では、統合承認ルールのUIサポートが削除されました。APIを使用して統合承認ルールにアクセスすることもできます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### Linux上のGitLab.com Runnerのオペレーティングシステムバージョンのアップグレード

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/ci-cd/shared-runners/infrastructure/-/issues/60)を参照してください。

</div>

GitLabは、Linux上のGitLab.com Runnerのジョブ実行に使用される一時的なVMのコンテナ最適化オペレーティングシステム（COS）をアップグレードしています。そのCOSのアップグレードには、Docker Engineのバージョン19.03.15からバージョン23.0.5へのアップグレードが含まれており、ここでは既知の互換性の問題が発生します。

バージョン20.10より前のDocker-in-Docker、またはv1.9.0より古いKanikoイメージは、コンテナランタイムを検出できず、失敗します。

詳細については、[Linux上のSaaS Runnerのオペレーティングシステムバージョンのアップグレード](https://about.gitlab.com/blog/2023/10/04/updating-the-os-version-of-saas-runners-on-linux/)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### 脆弱性の信頼度フィールド

<div class="deprecation-notes">

- GitLab <span class="milestone">15.4</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/372332)を参照してください。

</div>

GitLab 15.3では、[バージョン15より前のセキュリティレポートスキーマは非推奨](https://docs.gitlab.com/update/deprecations/#security-report-schemas-version-14xx)になりました。脆弱性の検出結果の`confidence`属性は、`15-0-0`より前のスキーマバージョンにのみ存在し、GitLab 15.4がスキーマバージョン`15-0-0`をサポートしているため、事実上非推奨になっています。レポートとパブリックAPIの一貫性を維持するため、GraphQL APIの脆弱性関連コンポーネントの`confidence`属性は非推奨となっていて、17.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `after_script`キーワードはキャンセルされたジョブに対して実行

<div class="deprecation-notes">

- GitLab <span class="milestone">16.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/437789)を参照してください。

</div>

[`after_script`](https://docs.gitlab.com/ci/yaml/#after_script) CI/CDキーワードは、ジョブのメイン`script`セクションの後に追加コマンドを実行するために使用されます。これは多くの場合、ジョブで使用された環境またはその他のリソースをクリーンアップするために使用されます。多くのユーザーにとって、ジョブがキャンセルされた場合に`after_script`コマンドが実行されないという事実は、予想外であり、望ましくありませんでした。17.0では、キーワードが更新され、ジョブのキャンセル後にもコマンドが実行されるようになります。`after_script`キーワードを使用するCI/CD設定が、キャンセルされたジョブに対しても実行を処理できることを確認してください。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `dependency_files`は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/396376)を参照してください。

</div>

現在のGitLabでは、プロジェクトの依存関係リストは、依存関係スキャンレポートの`dependency_files`の内容を使用して生成されます。ただし、グループ依存関係リストとの一貫性を維持するために、GitLab 17.0以降では、プロジェクトの依存関係リストは、PostgreSQLデータベースに保存されているCycloneDX SBOMレポートアーティファクトを使用します。そのため、依存関係スキャンレポートスキーマの`dependency_files`プロパティは非推奨となり、17.0で削除されます。

この非推奨化の一環として、[`dependency_path`](https://docs.gitlab.com/user/application_security/dependency_list/#dependency-paths)も非推奨となり、17.0で削除されます。GitLabは、同様の情報を提供するために、[CycloneDX仕様を使用した依存関係グラフ](https://gitlab.com/gitlab-org/gitlab/-/issues/441118)の実装を進めます。

さらに、コンテナスキャンCIジョブは、オペレーティングシステムコンポーネントのリストを提供するために[依存関係スキャンレポートを生成しなくなります](https://gitlab.com/gitlab-org/gitlab/-/issues/439782)。このレポートはCycloneDX SBOMレポートに置き換えられるためです。コンテナスキャン用の`CS_DISABLE_DEPENDENCY_LIST`環境変数は使用されなくなり、同様に17.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### DORA APIの`metric`フィルターと`value`フィールド

<div class="deprecation-notes">

- GitLab <span class="milestone">16.8</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/393172)を参照してください。

</div>

複数のDORAメトリクスを、新しいメトリクスフィールドを使用して同時にクエリできるようになりました。GraphQL DORA APIの`metric`フィルターと`value`フィールドは、GitLab 17.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `omniauth-azure-oauth2` gemは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/408989)を参照してください。

</div>

GitLabユーザーは、`omniauth-azure-oauth2` gemを使用してGitLabで認証できます。17.0では、このgemは`omniauth_openid_connect` gemに置き換えられます。新しいgemには、古いgemと同じ機能がすべて含まれていますが、アップストリームのメンテナンスもあり、セキュリティと集中メンテナンスに適しています。

この変更のために、ユーザーは移行時にOAuth 2.0プロバイダーに再接続する必要があります。混乱を回避するために、17.0より前の任意のタイミングで[`omniauth_openid_connect`を新しいプロバイダーとして追加](https://docs.gitlab.com/administration/auth/oidc/#configure-multiple-openid-connect-providers)してください。新しいログインボタンが表示されたら、手動で認証情報を再接続する必要があります。17.0 より前に`omniauth_openid_connect` gemを実装しない場合、ユーザーはAzureログインボタンを使用してサインインできなくなり、管理者が適切なgemを実装するまで、ユーザー名とパスワードを使用してサインインする必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `omnibus_gitconfig`設定項目は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.10</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitaly/-/issues/5132)を参照してください。

</div>

`omnibus_gitconfig['system']`設定項目は非推奨となりました。`omnibus_gitconfig['system']`を使用してGitalyのカスタムGit設定を設定する場合は、GitLab 17.0にアップグレードする前に、`gitaly[:configuration][:git][:config]`の下のGitaly設定を直接使用してGitを設定する必要があります。

例:

```ruby
  gitaly[:configuration][:git][:config] = [
    {
      key: 'fetch.fsckObjects',
      value: 'true',
    },
    # ...
  ]
```

設定キーの形式は、CLI フラグ`git -c <configuration>`を介して`git`に渡される内容と一致する必要があります。

既存のキーを予期される形式に変換する際に問題が発生した場合は、Gitaly のLinuxパッケージ生成設定ファイルで正しい形式の既存のキーを確認してください。デフォルトでは、設定ファイルは`/var/opt/gitlab/gitaly/config.toml`にあります。

Gitalyによって管理されている次の設定オプションを削除する必要があります。これらのキーをGitalyに移行する必要はありません。

- `pack.threads=1`
- `receive.advertisePushOptions=true`
- `receive.fsckObjects=true`
- `repack.writeBitmaps=true`
- `transfer.hideRefs=^refs/tmp/`
- `transfer.hideRefs=^refs/keep-around/`
- `transfer.hideRefs=^refs/remotes/`
- `core.alternateRefsCommand="exit 0 #"`
- `core.fsyncObjectFiles=true`
- `fetch.writeCommitGraph=true`

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `postgres_exporter['per_table_stats']`構成設定

<div class="deprecation-notes">

- GitLab <span class="milestone">16.4</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8164)を参照してください。

</div>

Linuxパッケージは、バンドルされている PostgreSQL exporter用のカスタムクエリを提供します。これには、 `postgres_exporter['per_table_stats']`構成設定によって制御される`per_table_stats`クエリが含まれていました。

PostgreSQL exporterは、同じメトリクスを提供する`stat_user_tables`コレクターを提供するようになりました。`postgres_exporter['per_table_stats']`を有効にしていた場合は、代わりに`postgres_exporter['flags']['collector.stat_user_tables']`を有効にします。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### `projectFingerprint` GraphQLフィールド

<div class="deprecation-notes">

- GitLab <span class="milestone">15.1</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/343475)を参照してください。

</div>

脆弱性検出の[`project_fingerprint`](https://gitlab.com/groups/gitlab-org/-/epics/2791)属性は、`uuid`属性を優先して非推奨になります。UUIDv5値を使用して検出を識別することにより、関連するエンティティを検出に簡単に関連付けることができます。`project_fingerprint`属性は検出の追跡に使用されなくなり、GitLab 17.0で削除されます。16.1以降、`project_fingerprint`の出力は`uuid`フィールドと同じ値を返します。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### パブリックプロジェクトの`repository_download_operation`監査イベントタイプ

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/383218)を参照してください。

</div>

監査イベントタイプ`repository_download_operation`は現在、すべてのプロジェクトのダウンロード（パブリックプロジェクトとプライベートプロジェクトの両方）についてデータベースに保存されています。パブリックプロジェクトの場合、この監査イベントは認証されていないユーザーによってトリガーされる可能性があるため、監査目的ではあまり役に立ちません。

GitLab 17.0以降、`repository_download_operation`監査イベントタイプは、プライベートプロジェクトまたは内部プロジェクトに対してのみトリガーされます。パブリックプロジェクトのダウンロード用に、`public_repository_download_operation`という新しい監査イベントタイプを追加します。この新しい監査イベントタイプは、ストリーミング専用になります。

</div>

<div class="deprecation breaking-change" data-milestone="17.0">

### npmパッケージのアップロードが非同期で行われるようになりました

<div class="deprecation-notes">

- GitLab <span class="milestone">16.9</span>で発表
- GitLab <span class="milestone">17.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/433009)を参照してください。

</div>

GitLabパッケージレジストリは、npmとYarnをサポートしています。npmまたはYarnパッケージをアップロードする場合、アップロードは同期されます。ただし、同期アップロードには既知の問題があります。たとえば、GitLabは[オーバーライド](https://gitlab.com/gitlab-org/gitlab/-/issues/432876)などの機能をサポートしていません。

17.0以降、npmおよびYarnパッケージは非同期でアップロードされます。これは、パッケージが公開されるとすぐに利用可能になることを期待するパイプラインが存在する可能性があるため、破壊的な変更です。

回避策として、[パッケージAPI](https://docs.gitlab.com/api/packages/)を使用してパッケージを確認する必要があります。

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.9">

## GitLab 16.9

<div class="deprecation " data-milestone="16.9">

### `lfs_check`機能フラグの非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">16.6</span>で発表
- GitLab <span class="milestone">16.9</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/233550)を参照してください。

</div>

GitLab 16.9では、`lfs_check`機能フラグを削除します。この機能フラグは[4年前に導入](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/60588)されたもので、LFS整合性チェックを有効にするかどうかを制御します。機能フラグはデフォルトで有効になっていますが、一部の顧客はLFS整合性チェックでパフォーマンスの問題が発生し、明示的に無効にしていました。

LFS整合性チェックの[パフォーマンスを大幅に改善](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/61355)した後、機能フラグを削除する準備ができました。フラグが削除された後、現在この機能を無効にしている環境では、機能が自動的に有効になります。

この機能フラグが環境で無効になっていて、パフォーマンスの問題が懸念される場合は、有効にして、16.9で削除される前にパフォーマンスを監視してください。有効にした後にパフォーマンスの問題が発生した場合は、[この問題のフィードバック](https://gitlab.com/gitlab-org/gitlab/-/issues/233550)でお知らせください。

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.8">

## GitLab 16.8

<div class="deprecation " data-milestone="16.8">

### openSUSE Leap 15.4パッケージ

<div class="deprecation-notes">

- GitLab <span class="milestone">16.5</span>で発表
- GitLab <span class="milestone">16.8</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8212)を参照してください。

</div>

openSUSE Leap 15.4のサポートとセキュリティアップデートは、[2023年11月に終了](https://en.opensuse.org/Lifetime#openSUSE_Leap)します。

GitLab 15.4では、openSUSE Leap 15.5のパッケージを提供していました。GitLab 15.8以降は、openSUSE Leap 15.4のパッケージを提供しません。

GitLab 15.8以降に備えるには、次の手順を実行する必要があります。

1. インスタンスをopenSUSE Leap 15.4からopenSUSE Leap 15.5に移行します。
1. openSUSE Leap 15.4のGitLab提供パッケージから、openSUSE Leap 15.5のGitLab提供パッケージに切り替えます。

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.7">

## GitLab 16.7

<div class="deprecation breaking-change" data-milestone="16.7">

### Shimoのインテグレーション

<div class="deprecation-notes">

- GitLab <span class="milestone">15.7</span>で発表
- GitLab <span class="milestone">16.7</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/377824)を参照してください。

</div>

**Shimoワークスペースのインテグレーション**は非推奨となっていて、JiHu GitLabコードベースに移行します。

</div>

<div class="deprecation breaking-change" data-milestone="16.7">

### `user_email_lookup_limit` APIフィールド

<div class="deprecation-notes">

- GitLab <span class="milestone">14.9</span>で発表
- GitLab <span class="milestone">16.7</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

`user_email_lookup_limit` [APIフィールド](https://docs.gitlab.com/api/settings/)はGitLab 14.9で非推奨となり、GitLab 16.7で削除されました。機能が削除されるまで、`user_email_lookup_limit`は`search_rate_limit`にエイリアスされ、既存のワークフローは引き続き機能します。

`user_email_lookup_limit`のレート制限を変更するAPIコールは、代わりに`search_rate_limit`を使用する必要があります。

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.6">

## GitLab 16.6

<div class="deprecation breaking-change" data-milestone="16.6">

### ジョブトークン許可リストは、パブリックプロジェクトと内部プロジェクトを対象としています

<div class="deprecation-notes">

- GitLab <span class="milestone">16.3</span>で発表
- GitLab <span class="milestone">16.6</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/420678)を参照してください。

</div>

16.6以降、**パブリック**または**内部**のプロジェクトは、[**このプロジェクトへのアクセスを制限する**](https://docs.gitlab.com/ci/jobs/ci_job_token/#add-a-group-or-project-to-the-job-token-allowlist)が有効になっている場合、プロジェクトの許可リストに**ない**プロジェクトからのジョブトークンリクエストを承認しなくなります。

**このプロジェクトへのアクセスを制限する**設定が有効になっている[パブリックまたは内部](https://docs.gitlab.com/user/public_access/#change-project-visibility)プロジェクトがある場合は、承認を継続するために、ジョブトークンリクエストを行うプロジェクトをプロジェクトの許可リストに追加する必要があります。

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.5">

## GitLab 16.5

<div class="deprecation " data-milestone="16.5">

### ロックされたLDAPグループへの非LDAP同期メンバーの追加は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">16.0</span>で発表
- GitLab <span class="milestone">16.5</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/213311)を参照してください。

</div>

`ldap_settings_unlock_groups_by_owners`機能フラグを有効にすることで、非LDAP同期ユーザーをロックされたLDAPグループに追加できるようになりました。この[機能](https://gitlab.com/gitlab-org/gitlab/-/issues/1793)は、常にデフォルトで無効になっており、機能フラグで管理されます。SAMLインテグレーションとの継続性を保つために、また非同期グループメンバーを許可すると、ディレクトリサービスを使用する「信頼できる唯一の情報源」の原則に反するため、この機能を削除します。この機能が削除されると、LDAPと同期されていないLDAPグループメンバーは、そのグループへのアクセス権を失います。

</div>

<div class="deprecation breaking-change" data-milestone="16.5">

### Geo: ハウスキーピングRakeタスク

<div class="deprecation-notes">

- GitLab <span class="milestone">16.3</span>で発表
- GitLab <span class="milestone">16.5</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/416384)を参照してください。

</div>

[Geoセルフサービスフレームワーク（SSF）](https://docs.gitlab.com/development/geo/framework/)へのレプリケーションと検証の移行の一環として、プロジェクトリポジトリの従来のレプリケーションは[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130565)されました。その結果、レガシーコードに依存していた次のRakeタスクも削除されました。これらのRakeタスクによって実行される作業は、定期的に、またはトリガーイベントに基づいて自動的にトリガーされるようになりました。

| Rakeタスク | 代替手段 |
| --------- | ----------- |
| `geo:git:housekeeping:full_repack` | [UIに移動しました](https://docs.gitlab.com/administration/housekeeping/#heuristical-housekeeping)。SSFには相当するRakeタスクはありません。 |
| `geo:git:housekeeping:gc` | 常に新しいリポジトリに対して実行され、その後、必要なときに実行されます。SSFには相当するRakeタスクはありません。 |
| `geo:git:housekeeping:incremental_repack` | 必要なときに実行されます。SSFには相当するRakeタスクはありません。 |
| `geo:run_orphaned_project_registry_cleaner` | レジストリ[整合性ワーカー](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/geo/secondary/registry_consistency_worker.rb)によって定期的に実行され、孤立したレジストリを削除します。SSFには相当するRakeタスクはありません。 |
| `geo:verification:repository:reset` | UIに移動しました。SSFには相当するRakeタスクはありません。 |
| `geo:verification:wiki:reset` | UIに移動しました。SSFには相当するRakeタスクはありません。 |

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.3">

## GitLab 16.3

<div class="deprecation breaking-change" data-milestone="16.3">

### バンドルされたGrafanaは非推奨となり、無効になりました

<div class="deprecation-notes">

- GitLab <span class="milestone">16.0</span>で発表
- GitLab <span class="milestone">16.3</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7772)を参照してください。

</div>

Omnibus GitLabにバンドルされているGrafanaのバージョンは、16.0で[非推奨となって無効になり](https://docs.gitlab.com/administration/monitoring/performance/grafana_configuration/#deprecation-of-bundled-grafana)、16.3で削除されます。バンドルされたGrafanaを使用している場合は、次のいずれかに移行する必要があります。

- Grafanaの別の実装。詳細については、[新しいGrafanaインスタンスへの切り替え](https://docs.gitlab.com/administration/monitoring/performance/grafana_configuration/#switch-to-new-grafana-instance)を参照してください。
- 選択した別の可観測性プラットフォーム。

現在提供されているGrafanaのバージョンは、サポートされなくなったバージョンです。

GitLabバージョン16.0 - 16.2では、[バンドルされたGrafanaを再度有効にする](https://docs.gitlab.com/administration/monitoring/performance/grafana_configuration/#temporary-workaround)ことができます。ただし、バンドルされたGrafanaの有効化は、GitLab 16.3以降では機能しなくなります。

</div>

<div class="deprecation breaking-change" data-milestone="16.3">

### ライセンスコンプライアンスCIテンプレート

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.3</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/387561)を参照してください。

</div>

**更新: **以前に、GitLab 16.0で既存のライセンスコンプライアンスCIテンプレートを削除すると発表しました。ただし、[CycloneDXファイルのライセンススキャン](https://docs.gitlab.com/user/compliance/license_scanning_of_cyclonedx_files/)に関するパフォーマンスの問題のため、代わりに16.3でこれを行います。

GitLab[**ライセンスコンプライアンス**](https://docs.gitlab.com/user/compliance/license_approval_policies/)CI/CDテンプレートは非推奨となり、GitLab 16.3リリースで削除される予定です。

ライセンスコンプライアンスにGitLabを引き続き使用するには、CI/CDパイプラインから**ライセンスコンプライアンス**テンプレートを削除し、**依存関係スキャン**テンプレートを追加します。**依存関係スキャン**テンプレートは必要なライセンス情報を収集できるようになったため、個別のライセンスコンプライアンスジョブを実行する必要はなくなりました。

**ライセンスコンプライアンス**CI/CDテンプレートを削除する前に、インスタンスが新しいライセンススキャン方法をサポートするバージョンにアップグレードされていることを確認してください。

依存関係スキャナーを大規模にすばやく使用できるようにするために、グループレベルでスキャン実行ポリシーを設定して、グループ内のすべてのプロジェクトに対してSBOMベースのライセンススキャンを適用することができます。次に、CI/CD設定から`Jobs/License-Scanning.gitlab-ci.yml`テンプレートの包含を削除できます。

従来のライセンスコンプライアンス機能を引き続き使用する場合は、`LICENSE_MANAGEMENT_VERSION CI`変数を`4`に設定します。この変数は、プロジェクト、グループ、またはインスタンスレベルで設定できます。この設定の変更により、新しいアプローチを採用しなくても、既存のバージョンのライセンスコンプライアンスを引き続き使用できます。

この従来のアナライザーのバグや脆弱性は修正されなくなります。

| CIパイプラインの包含内容 | GitLab <= 15.8 | 15.9 <= GitLab < 16.3 | GitLab >= 16.3 |
| ------------- | ------------- | ------------- | ------------- |
| DSテンプレートとLSテンプレートの両方 | LSジョブからのライセンスデータが使用されます | LSジョブからのライセンスデータが使用されます | DSジョブからのライセンスデータが使用されます |
| DSテンプレートは含まれますが、LSテンプレートは含まれません | ライセンスデータなし | DSジョブからのライセンスデータが使用されます | DSジョブからのライセンスデータが使用されます |
| LSテンプレートは含まれますが、DSテンプレートは含まれません | LSジョブからのライセンスデータが使用されます | LSジョブからのライセンスデータが使用されます | ライセンスデータなし |

</div>

<div class="deprecation breaking-change" data-milestone="16.3">

### RSAキーサイズの制限

<div class="deprecation-notes">

- GitLab <span class="milestone">16.3</span>で発表
- GitLab <span class="milestone">16.3</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/groups/gitlab-org/-/epics/11186)を参照してください。

</div>

Goバージョン1.20.7以降では、RSAキーを最大8192ビットに制限する`maxRSAKeySize`定数が追加されています。その結果、8192ビットを超えるRSAキーはGitLabでは機能しなくなります。8192ビットを超えるRSAキーは、これより小さいサイズで再生成する必要があります。

ログに`tls: server sent certificate containing RSA key larger than 8192 bits`のようなエラーが含まれているためにこの問題に気づく場合もあります。キーの長さをテストするには、コマンド`openssl rsa -in <your-key-file> -text -noout | grep "Key:"`を使用します。

</div>

<div class="deprecation breaking-change" data-milestone="16.3">

### Twitter OmniAuthログインオプションをGitLab.comから削除

<div class="deprecation-notes">

- GitLab <span class="milestone">16.3</span>で発表
- GitLab <span class="milestone">16.3</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-com/Product/-/issues/11417)を参照してください。

</div>

Twitter OAuth 1.0a OmniAuthは、使用率が低く、gemのサポートがなく、この機能の機能的なサインインオプションがないため、GitLab 16.3ではGitLab.comで非推奨となり、削除されます。TwitterでGitLab.comにサインインする場合は、パスワードで、または別の[サポートされているOmniAuthプロバイダー](https://gitlab.com/users/sign_in)でサインインできます。

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.1">

## GitLab 16.1

<div class="deprecation " data-milestone="16.1">

### Alpine 3.12、3.13、3.14に基づくGitLab Runnerイメージ

<div class="deprecation-notes">

- GitLab <span class="milestone">15.11</span>で発表
- GitLab <span class="milestone">16.1</span>でサポート終了
- GitLab <span class="milestone">16.1</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29639)を参照してください。

</div>

次のサポートが終了したAlpineバージョンに基づいて、Runnerイメージの公開を停止します。

- Alpine 3.12
- Alpine 3.13
- Alpine 3.14（2023年5月23日にサポート終了）

</div>
</div>

<div class="milestone-wrapper" data-milestone="16.0">

## GitLab 16.0

<div class="deprecation breaking-change" data-milestone="16.0">

### Auto DevOpsによるデフォルトでのPostgreSQLデータベースのプロビジョニングを終了

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/343988)を参照してください。

</div>

現在、Auto DevOpsは、デフォルトでクラスター内PostgreSQLデータベースをプロビジョニングしています。GitLab 16.0では、データベースはオプトインしたユーザーに対してのみプロビジョニングされます。この変更は、より堅牢なデータベース管理を必要とする本番環境のデプロイをサポートします。

Auto DevOpsにクラスター内データベースをプロビジョニングさせる場合は、`POSTGRES_ENABLED` CI/CD変数を`true`に設定します。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Azure Storage Driverにより正しいルートプレフィックスをデフォルト設定

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/container-registry/-/issues/854)を参照してください。

</div>

コンテナレジストリのAzure Storage Driverは、デフォルトのルートディレクトリとして`//`に書き込みます。このデフォルトのルートディレクトリは、Azure UI内の一部の場所では`/<no-name>/`として表示されます。このストレージドライバーを使用する以前のデプロイをサポートするために、この従来の動作を維持してきました。ただし、別のストレージドライバーからAzureに移行する場合、この動作は、`trimlegacyrootprefix: true`を設定して、余分な先頭のスラッシュなしでストレージドライバーがルートパスを構築するように設定するまで、すべてのデータを非表示にします。

ストレージドライバーの新しいデフォルト設定では、`trimlegacyrootprefix: true`が設定され、`/`がデフォルトのルートディレクトリになります。混乱を回避するために、現在の設定に`trimlegacyrootprefix: false`を追加できます。

この破壊的な変更は、GitLab 16.0で発生します。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### バンドルされたGrafana Helmチャートは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.10</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/4353)を参照してください。

</div>

GitLab HelmチャートにバンドルされているGrafana Helmチャートは非推奨であり、GitLab Helmチャート7.0リリース（GitLab 16.0とともにリリース）で削除されます。

バンドルされたGrafana Helmチャートは、GitLab HelmチャートのPrometheusメトリクスに接続されたGrafana UIを提供するためにオンにできるオプションのサービスです。

GitLab Helmチャートが現在提供しているGrafanaのバージョンは、サポート対象のGrafanaバージョンではなくなります。バンドルされたGrafanaを使用している場合は、[Grafana Labsの新しいチャートバージョン](https://artifacthub.io/packages/helm/grafana/grafana)、または信頼できるプロバイダーのGrafana Operatorに切り替える必要があります。

新しいGrafanaインスタンスで、[GitLabが提供するPrometheusをデータソースとして設定](https://docs.gitlab.com/administration/monitoring/performance/grafana_configuration/#configure-grafana)し、[GrafanaをGitLab UIに接続](https://docs.gitlab.com/administration/monitoring/performance/grafana_configuration/#integrate-with-gitlab-ui)することができます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### CAS OmniAuthプロバイダー

<div class="deprecation-notes">

- GitLab <span class="milestone">15.3</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/369127)を参照してください。

</div>

GitLabにCAS OmniAuthプロバイダーを提供する`omniauth-cas3` gemは、次回のメジャーリリースであるGitLab 16.0で削除されます。このgemの使用頻度は非常に低く、アップストリームのメンテナンスが不足しているため、GitLabを[OmniAuth 2.0にアップグレード](https://gitlab.com/gitlab-org/gitlab/-/issues/30073)することはできません。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### HashiCorp Vaultからシークレットが返されない場合、CI/CDジョブは失敗します

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/353080)を参照してください。

</div>

ネイティブのHashiCorp Vaultインテグレーションを使用すると、Vaultからシークレットが返されない場合、CI/CDジョブは失敗します。GitLab 16.0より前に、設定が常にシークレットを返すようにするか、この変更を処理するようにパイプラインを更新してください。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### マルチモジュールAndroidプロジェクトでのMobSFベースのSASTアナライザーの動作の変更

<div class="deprecation-notes">

- GitLab <span class="milestone">16.0</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/408396)を参照してください。

</div>

**更新: **以前に、MobSFベースのGitLab SASTアナライザーがマルチモジュールAndroidプロジェクトをスキャンする方法の変更を発表しました。その変更はキャンセルされていて、対応は必要ありません。

スキャンする単一のモジュールを変更する代わりに、[マルチモジュールのサポートを改善](https://gitlab.com/gitlab-org/security-products/analyzers/mobsf/-/merge_requests/73)しました。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `/approvals` APIエンドポイントを使用したマージリクエストの承認の変更

<div class="deprecation-notes">

- GitLab <span class="milestone">14.0</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/353097)を参照してください。

</div>

マージリクエストに必要な承認を変更するために、GitLab 14.0で非推奨になった`/approvals` APIエンドポイントを使用しないでください。

代わりに、[`/approval_rules`エンドポイント](https://docs.gitlab.com/api/merge_request_approvals/#merge-request-level-mr-approvals)を使用して、マージリクエストの承認ルールを[作成](https://docs.gitlab.com/api/merge_request_approvals/#create-merge-request-level-rule)または[更新](https://docs.gitlab.com/api/merge_request_approvals/#update-merge-request-level-rule)します。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Conanプロジェクトレベルの検索エンドポイントはプロジェクト固有の結果を返却

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/384455)を参照してください。

</div>

[プロジェクトレベル](https://docs.gitlab.com/user/packages/conan_repository/#add-a-remote-for-your-project)または[インスタンスレベル](https://docs.gitlab.com/user/packages/conan_repository/#add-a-remote-for-your-instance)のエンドポイントでGitLab Conanリポジトリを使用できます。各レベルがConan検索コマンドをサポートしています。ただし、プロジェクトレベルの検索エンドポイントは、ターゲットプロジェクトの外部からもパッケージを返します。

この意図しない機能は、GitLab 15.8で非推奨となり、GitLab 16.0で削除されます。プロジェクトレベルの検索エンドポイントは、ターゲットプロジェクトのパッケージのみを返します。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GitLab Runner Helmチャートの設定フィールド

<div class="deprecation-notes">

- GitLab <span class="milestone">15.6</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/379064)を参照してください。

</div>

GitLab 13.6以降、ユーザーは[GitLab Runner Helmチャートで任意のRunner設定を指定](https://docs.gitlab.com/runner/install/kubernetes/)できます。この機能を実装したとき、GitLab Helmチャート設定のGitLab Runnerに固有の値は非推奨になりました。非推奨の値はGitLab 16.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### 環境変数を使用したRedis設定ファイルのパスの設定は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/388255)を参照してください。

</div>

`GITLAB_REDIS_CACHE_CONFIG_FILE`や`GITLAB_REDIS_QUEUES_CONFIG_FILE`のような環境変数を使用してRedis設定ファイルの場所を指定することはできなくなりました。代わりに、`config/redis.cache.yml`や`config/redis.queues.yml`などのデフォルトの設定ファイルの場所を使用してください。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Dockerを参照するコンテナスキャン変数

<div class="deprecation-notes">

- GitLab <span class="milestone">15.4</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/371840)を参照してください。

</div>

変数名に`DOCKER_`がプレフィックスとして付いているすべてのコンテナスキャン変数は非推奨です。これには、`DOCKER_IMAGE`、`DOCKER_PASSWORD`、`DOCKER_USER`、および`DOCKERFILE_PATH`変数が含まれます。これらの変数のサポートは、GitLab 16.0リリースで削除されます。非推奨の名前の代わりに、[新しい変数名](https://docs.gitlab.com/user/application_security/container_scanning/#available-cicd-variables)である`CS_IMAGE`、`CS_REGISTRY_PASSWORD`、`CS_REGISTRY_USER`、および`CS_DOCKERFILE_PATH`を使用します。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### コンテナレジストリのプルスルーキャッシュ

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/container-registry/-/issues/842)を参照してください。

</div>

コンテナレジストリの[プルスルーキャッシュ](https://docs.docker.com/docker-hub/mirror/)はGitLab 15.8で非推奨となり、GitLab 16.0で削除されます。プルスルーキャッシュは、アップストリームの[Docker Distributionプロジェクト](https://github.com/distribution/distribution)の一部です。ただし、Docker HubからコンテナイメージをプロキシおよびキャッシュできるGitLab依存プロキシを優先して、プルスルーキャッシュを削除します。プルスルーキャッシュを削除すると、機能を犠牲にすることなく、アップストリームクライアントコードも削除できます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GitLab for Jira CloudアプリのCookie認証

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/387299)を参照してください。

</div>

GitLab for Jira CloudアプリのCookie認証は、OAuth認証を優先して非推奨になりました。GitLab Self-Managedでは、GitLab for Jira Cloudアプリを引き続き使用するには、[OAuth認証を設定](https://docs.gitlab.com/integration/jira/connect-app/#set-up-oauth-authentication-for-self-managed-instances)する必要があります。OAuthがないと、リンクされたネームスペースを管理できません。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### DASTテンプレートを使用したDAST APIスキャンは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.7</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/384198)を参照してください。

</div>

新しいDAST APIアナライザーとDAST APIスキャンの`DAST-API.gitlab-ci.yml`テンプレートへの移行に伴い、DASTアナライザーでAPIをスキャンする機能を削除します。APIスキャンでの`DAST.gitlab-ci.yml`または`DAST-latest.gitlab-ci.yml`テンプレートの使用は、GitLab 15.7の時点で非推奨となり、GitLab 16.0では機能しなくなります。`DAST-API.gitlab-ci.yml`テンプレートを使用してください。設定の詳細については[DAST APIアナライザー](https://docs.gitlab.com/user/application_security/dast_api/#configure-dast-api-with-an-openapi-specification)ドキュメントを参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### DAST API変数

<div class="deprecation-notes">

- GitLab <span class="milestone">15.7</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/383467)を参照してください。

</div>

GitLab 15.6の新しいDAST APIアナライザーへの切り替えにより、2つの従来のDAST API変数が非推奨になります。変数`DAST_API_HOST_OVERRIDE`および`DAST_API_SPECIFICATION`は、DAST APIスキャンには使用されなくなります。

OpenAPI仕様のホストを自動的にオーバーライドするために`DAST_API_TARGET_URL`を使用することを優先して、`DAST_API_HOST_OVERRIDE`は推奨されなくなりました。

`DAST_API_SPECIFICATION`は`DAST_API_OPENAPI`を優先して非推奨になりました。テストをガイドするためにOpenAPI仕様を引き続き使用するには、`DAST_API_SPECIFICATION`変数を`DAST_API_OPENAPI`変数に置き換える必要があります。値は同じままでかまいませんが、変数名を置き換える必要があります。

これらの2つの変数は、GitLab 16.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### DASTレポート変数の非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">15.7</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/384340)を参照してください。

</div>

GitLab 15.7で新しいブラウザベースのDASTアナライザーが一般公開になったため、将来的にはデフォルトのDASTアナライザーにすることを目指しています。これに備えて、従来のDAST変数`DAST_HTML_REPORT`、`DAST_XML_REPORT`、`DAST_MARKDOWN_REPORT`が非推奨になり、GitLab 16.0で削除される予定です。これらのレポートは従来のDASTアナライザーに依存しており、新しいブラウザベースのアナライザーに実装する予定はありません。GitLab 16.0の時点で、これらのレポートアーティファクトは生成されなくなります。

これらの3つの変数は、GitLab 16.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Java 13、14、15、および16の依存関係スキャンサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/387560)を参照してください。

</div>

GitLabは、Javaバージョン13、14、15、および16の依存関係スキャンサポートを非推奨にしており、今後のGitLab 16.0リリースでそのサポートを削除する予定です。これらのバージョンのOracle PremierおよびExtended Supportが終了したため、これは[Oracleサポートポリシー](https://www.oracle.com/java/technologies/java-se-support-roadmap.html)と一致しています。これにより、GitLabは依存関係スキャンJavaサポートで今後のLTSバージョンに重点を置くこともできます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `updated_at`と`updated_at`を一緒に使用しない場合、デプロイAPIはエラーを返します

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/328500)を参照してください。

</div>

デプロイAPIは、`updated_at`フィルタリングと`updated_at`ソートを一緒に使用しない場合、エラーを返すようになります。一部のユーザーは、`updated_at`でフィルタリングして`updated_at`ソートを使用せずに「最新」のデプロイを取得していましたが、これは誤った結果をもたらす可能性があります。代わりに、それらを一緒に使用するか、`finished_at`でフィルタリングし、`finished_at`でソートするように移行する必要があります。これにより、「最新のデプロイ」が一貫して得られます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### 従来のGitaly設定方法を非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352609)を参照してください。

</div>

環境変数`GIT_CONFIG_SYSTEM`と`GIT_CONFIG_GLOBAL`を使用してGitalyを設定することは[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/352609)です。これらの変数は、標準の[`config.toml` Gitaly設定](https://docs.gitlab.com/administration/gitaly/reference/)に置き換えられます。

`GIT_CONFIG_SYSTEM`と`GIT_CONFIG_GLOBAL`を使用してGitalyを設定するGitLabインスタンスは、`config.toml`を使用して設定するように切り替える必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### 非推奨のConsul httpメトリクス

<div class="deprecation-notes">

- GitLab <span class="milestone">15.10</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7278)を参照してください。

</div>

Linuxパッケージで提供されるConsulは、GitLab 16.0以降、以前の非推奨のConsulメトリクスを提供しなくなります。

GitLab 14.0では、[Consulが1.9.6に更新](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/5344)され、一部のテレメトリメトリクスが`consul.http`パスに存在することは非推奨になりました。GitLab 16.0では、`consul.http`パスが削除されます。

Consulメトリクスを使用するモニタリングがある場合は、`consul.http`の代わりに`consul.api.http`を使用するように更新します。詳細については、[Consul 1.9.0の非推奨化に関する注意](https://github.com/hashicorp/consul/releases/tag/v1.9.0)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GitLab.comでの`CI_PRE_CLONE_SCRIPT`変数の非推奨化と計画された削除

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/391896)を参照してください。

</div>

GitLab.com Runnerでサポートされている[`CI_PRE_CLONE_SCRIPT`変数](https://docs.gitlab.com/ci/runners/saas/linux_saas_runner/#pre-clone-script)は、GitLab 15.9の時点で非推奨となり、16.0で削除されます。`CI_PRE_CLONE_SCRIPT`変数を使用すると、RunnerがGit initとget fetchを実行する前に、CI/CDジョブでコマンドを実行できます。この機能の仕組みについて詳しくは、[Pre-clone script](https://docs.gitlab.com/ci/runners/saas/linux_saas_runner/#pre-clone-script)を参照してください。別の方法として、[`pre_get_sources_script`](https://docs.gitlab.com/ci/yaml/#hookspre_get_sources_script)を使用できます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### グループにプロジェクトをインポートする機能を提供するデベロッパーロール

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/387891)を参照してください。

</div>

グループのデベロッパーロールを持つユーザーがそのグループにプロジェクトをインポートする機能はGitLab 15.8で非推奨となり、GitLab 16.0で削除されます。GitLab 16.0以降、グループのメンテナーロール以上のユーザーのみがそのグループにプロジェクトをインポートできます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### PHPおよびPython用の開発依存関係の報告

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/375505)を参照してください。

</div>

GitLab 16.0では、GitLab依存関係スキャンアナライザーは、Python/pipenvプロジェクトとPHP/composerプロジェクトの両方について、開発依存関係の報告を開始します。これらの開発依存関係の報告を希望しないユーザーは、CI/CDファイルで`DS_INCLUDE_DEV_DEPENDENCIES: false`を設定する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### MarkdownでのGrafanaパネルの埋め込みは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/389477)を参照してください。

</div>

GitLab Flavored MarkdownでのGrafanaパネルの追加機能は15.9で非推奨となり、16.0で削除されます。この機能を[GitLab可観測性UI](https://gitlab.com/gitlab-org/opstrace/opstrace-ui)で[チャートを埋め込む](https://gitlab.com/groups/gitlab-org/opstrace/-/epics/33)機能に置き換える予定です。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### CI/CDパラメーターの文字長の強制検証

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/372770)を参照してください。

</div>

CI/CD[ジョブ名](https://docs.gitlab.com/ci/jobs/#job-name)には厳密な255文字の制限がありますが、他のCI/CDパラメーターには、制限を超えないことを保証する検証がまだありません。

GitLab 16.0では、検証が追加され、以下も厳密に255文字に制限されます。

- `stage`キーワード。
- `ref`。これは、Git branchまたはパイプライン用のタグ名です。
- 外部CI/CDインテグレーションで使用される`description`パラメーターと`target_url`パラメーター。

GitLab Self-Managedのユーザーは、255文字を超えるパラメーターを使用しないように、パイプラインを更新する必要があります。GitLab.comのユーザーは、これらがデータベースですでに制限されているため、何も変更する必要はありません。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### 環境検索クエリには3文字以上が必要

<div class="deprecation-notes">

- GitLab <span class="milestone">15.10</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/382532)を参照してください。

</div>

GitLab 16.0以降、APIで環境を検索する場合、3文字以上を使用する必要があります。この変更は、検索操作のスケーラビリティを確保するのに役立ちます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GraphQL ReleaseAssetLinkタイプの外部フィールド

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

[GraphQL API](https://docs.gitlab.com/api/graphql/)では、[`ReleaseAssetLink`タイプ](https://docs.gitlab.com/api/graphql/reference/#releaseassetlink)の`external`フィールドを使用して、[リリースリンク](https://docs.gitlab.com/user/project/releases/release_fields/#links)がGitLabインスタンスの内部であるか外部であるかを示していました。GitLab 15.9の時点では、すべてのリリースリンクを外部として扱うため、このフィールドはGitLab 15.9で非推奨となり、GitLab 16.0で削除されます。`external`フィールドは削除され、代替されないため、ワークフローの混乱を避けるために、このフィールドの使用を中止してください。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### ReleasesおよびRelease Links APIの外部フィールド

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

[Releases API](https://docs.gitlab.com/api/releases/)と[Release Links API](https://docs.gitlab.com/api/releases/links/)では、`external`フィールドを使用して、[リリースリンク](https://docs.gitlab.com/user/project/releases/release_fields/#links)がGitLabインスタンスの内部であるか外部であるかを示していました。GitLab 15.9の時点では、すべてのリリースリンクを外部として扱うため、このフィールドはGitLab 15.9で非推奨となり、GitLab 16.0で削除されます。`external`フィールドは削除され、代替されないため、ワークフローの混乱を避けるために、このフィールドの使用を中止してください。

</div>

<div class="deprecation " data-milestone="16.0">

### Geo: プロジェクトリポジトリの再ダウンロードは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.11</span>で発表
- GitLab <span class="milestone">16.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/388868)を参照してください。

</div>

セカンダリジオサイトでは、プロジェクトリポジトリを「再ダウンロード」するボタンは非推奨です。再ダウンロードロジックには、発生した場合に解決が困難な固有のデータ整合性の問題があります。このボタンはGitLab 16.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GitLab管理者には保護されたブランチまたはタグを変更する権限が必要

<div class="deprecation-notes">

- GitLab <span class="milestone">16.0</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/12776)を参照してください。

</div>

GitLab管理者は、保護されたブランチまたはタグに対してアクションを実行する権限が明示的に付与されていない限り、そのアクションを実行できなくなりました。これらのアクションには、[保護されたブランチ](https://docs.gitlab.com/user/project/repository/branches/protected/)へのプッシュとマージ、ブランチの保護解除、[保護されたタグ](https://docs.gitlab.com/user/project/protected_tags/)の作成が含まれます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GitLab自己モニタリングプロジェクト

<div class="deprecation-notes">

- GitLab <span class="milestone">14.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/348909)を参照してください。

</div>

GitLab自己モニタリングにより、インスタンス管理者はインスタンスのヘルスを監視するためのツールが利用できます。この機能はGitLab 14.9で非推奨となり、16.0で削除される予定です。

</div>

<div class="deprecation " data-milestone="16.0">

### GitLab.comインポーター

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-com/Product/-/issues/4895)を参照してください。

</div>

GitLab.comインポーターはGitLab 15.8で非推奨となっていて、GitLab 16.0で削除されます。

GitLab.comインポーターは、UIを介してGitLab.comからGitLab Self-Managedインスタンスにプロジェクトをインポートするために2015年に導入されました。この機能はGitLab Self-Managedでのみ使用できます。[直接転送によるGitLabグループおよびプロジェクトの移行](https://docs.gitlab.com/user/group/import/#migrate-groups-by-direct-transfer-recommended)はGitLab.comインポーターに取って代わり、よりまとまりのあるインポート機能を提供します。

概要については、[移行されたグループ項目](https://docs.gitlab.com/user/group/import/#migrated-group-items)および[移行されたプロジェクト項目](https://docs.gitlab.com/user/group/import/#migrated-project-items)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GraphQL API Runnerの状態での`paused`の返却を停止

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/344648)を参照してください。

</div>

GitLab 16.0では、GitLab Runner GraphQL APIエンドポイントは状態として`paused`や`active`を返しません。今後のREST API v5では、GitLab Runnerのエンドポイントも`paused`や`active`を返しません。

Runnerの状態は、`online`、`offline`、`not_connected`など、Runnerの接続状態のみに関連します。状態`paused`と`active`は表示されなくなります。

Runnerが`paused`かどうかを確認する場合、APIユーザーは代わりにブール属性`paused`が`true`であるかどうかを確認することをお勧めします。Runnerが`active`かどうかを確認する場合は、`paused`が`false`であるかどうかを確認します。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Jira Cloud用のJira DVCSコネクタ

<div class="deprecation-notes">

- GitLab <span class="milestone">15.1</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/groups/gitlab-org/-/epics/7508)を参照してください。

</div>

Jira Cloud用の[Jira DVCSコネクタ](https://docs.gitlab.com/integration/jira/dvcs/)は非推奨となっていて、GitLab 16.0で削除されます。Jira CloudでJira DVCSコネクタを使用している場合は、[GitLab for Jira Cloudアプリ](https://docs.gitlab.com/integration/jira/connect-app/)に移行してください。

Jira DVCSコネクタはJira 8.13以前でも非推奨です。Jira DVCSコネクタは、Jira 8.14以降のJira ServerまたはJira Data Centerでのみ使用できます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GitLab HelmチャートのKASメトリクスポート

<div class="deprecation-notes">

- GitLab <span class="milestone">15.7</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/383039)を参照してください。

</div>

[GitLab Helmチャート](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2839)の新しい`gitlab.kas.observability.port`設定フィールドを優先して、`gitlab.kas.metrics.port`は非推奨になりました。このポートはメトリクスだけにとどまらない多くの目的に使用されるため、設定の混乱を避けるためにこの変更が必要になりました。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### 従来のGitaly設定方法

<div class="deprecation-notes">

- GitLab <span class="milestone">15.10</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/393574)を参照してください。

</div>

Omnibus GitLab内のGitaly設定は、すべてのGitaly関連の設定キーが標準のGitaly設定に一致する単一の設定構造になるように更新されました。そのため、以前の設定構造は非推奨になります。

単一の設定構造はGitLab 15.10から利用可能ですが、下位互換性は維持されます。削除後は、単一の設定構造を使用してGitalyを設定する必要があります。できるだけ早くGitalyの設定を更新する必要があります。

この変更により、Omnibus GitLabとソースインストールの整合性が向上し、両方に対してより優れたドキュメントとツールを提供できるようになります。

[アップグレード手順](https://docs.gitlab.com/update/#gitaly-omnibus-gitlab-configuration-structure-change)を使用して、できるだけ早く新しい設定構造に更新する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### 従来のPraefect設定方法

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/390291)を参照してください。

</div>

以前は、Praefect設定キーは設定ファイル全体に散在していました。現在、これらはPraefect設定に一致する単一の設定構造になっているため、以前の設定方法は非推奨になります。

単一の設定構造はGitLab 15.9から利用可能ですが、下位互換性は維持されます。削除後は、単一の設定構造を使用してPraefectを設定する必要があります。[アップグレード手順](https://docs.gitlab.com/update/#praefect-omnibus-gitlab-configuration-structure-change)を使用して、できるだけ早くPraefect設定を更新する必要があります。

この変更により、Omnibus GitLabのPraefect設定がPraefectの設定構造に準拠します。以前は、階層と設定キーが一致しませんでした。この変更により、Omnibus GitLabとソースインストールの整合性が向上し、両方に対してより優れたドキュメントとツールを提供できるようになります。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### 従来のURLの置き換えまたは削除

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/214217)を参照してください。

</div>

GitLab 16.0では、GitLabアプリケーションから従来のURLが削除されます。

GitLab 9.0でサブグループが導入されたとき、グループパスの終わりを示すために`/-/`区切り記号がURLに追加されました。GitLabのすべてのURLで、プロジェクト、グループ、およびインスタンスレベルの機能にこの区切り記号が使用されるようになりました。

`/-/`区切り記号を使用しないURLは、GitLab 16.0で削除される予定です。これらのURLの完全なリストとその代替については、[問題28848](https://gitlab.com/gitlab-org/gitlab/-/issues/28848#release-notes)を参照してください。

従来のURLを参照するスクリプトまたはブックマークを更新します。GitLab APIはこの変更の影響を受けません。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### ライセンスチェックとライセンスコンプライアンスページのポリシータブ

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/390417)を参照してください。

</div>

**ライセンスチェック機能**は非推奨となり、GitLab 16.0で削除される予定です。さらに、ライセンスコンプライアンスページのポリシータブと、ライセンスチェック機能に関連するすべてのAPIは非推奨となり、GitLab 16.0で削除される予定です。検出されたライセンスに基づいて承認を引き続き適用したい場合、代わりに新しい[ライセンス承認ポリシー](https://docs.gitlab.com/user/compliance/license_approval_policies/)を作成することをお勧めします。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### 外部認証によるパーソナルアクセストークンとデプロイトークンのアクセスの制限

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/387721)を参照してください。

</div>

外部認証を有効にすると、パーソナルアクセストークン（PAT）とデプロイトークンは、コンテナまたはパッケージレジストリにアクセスできなくなります。この多層防御のセキュリティ対策は、16.0でデプロイされます。PATとデプロイトークンを使用してこれらのレジストリにアクセスするユーザーの場合、この対策によりこれらのトークンの使用が中断されます。コンテナまたはパッケージレジストリでトークンを使用するには、外部認証を無効にします。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GitLab Helmチャート用の主要なバンドルHelmチャートの更新

<div class="deprecation-notes">

- GitLab <span class="milestone">15.10</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3442)を参照してください。

</div>

GitLab 16.0と同時に、GitLab Helmチャートは7.0のメジャーバージョンをリリースします。次の主要なバンドルチャートの更新が含まれます。

- GitLab 16.0では、[PostgreSQL 12のサポートが削除され、PostgreSQL 13が新しい最小バージョンになります](#postgresql-12-deprecated)。
  - 本番環境対応の外部データベースを使用するインストールでは、アップグレードする前に、より新しいPostgreSQLバージョンへの移行を完了する必要があります。
  - [非本番環境バンドルPostgreSQL 12チャート](https://docs.gitlab.com/charts/installation/tools/#postgresql)を使用するインストールでは、チャートが新しいバージョンにアップグレードされます。詳細については、[問題4118](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/4118)を参照してください
- [非本番環境バンドルRedisチャート](https://docs.gitlab.com/charts/installation/tools/#redis)を使用するインストールでは、チャートが新しいバージョンにアップグレードされます。詳細については、[問題3375](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3375)を参照してください
- [バンドルされたcert-managerチャート](https://docs.gitlab.com/charts/installation/tls/#option-1-cert-manager-and-lets-encrypt)を使用するインストールでは、チャートが新しいバージョンにアップグレードされます。詳細については、[問題4313](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/4313)を参照してください

完全なGitLab Helmチャート7.0アップグレード手順は、[アップグレードドキュメント](https://docs.gitlab.com/charts/installation/upgrade/)で入手できます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Managed Licenses API

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/390417)を参照してください。

</div>

Managed Licenses APIは現在非推奨となっており、GitLab 16.0で削除される予定です。

</div>

<div class="deprecation " data-milestone="16.0">

### プロジェクトごとのアクティブなパイプラインの最大数制限（`ci_active_pipelines`）

<div class="deprecation-notes">

- GitLab <span class="milestone">15.3</span>で発表
- GitLab <span class="milestone">16.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/368195)を参照してください。

</div>

[**プロジェクトごとのアクティブなパイプラインの最大数**制限](https://docs.gitlab.com/administration/settings/continuous_integration/#set-cicd-limits) は、デフォルトでは有効になっておらず、GitLab 16.0で削除されます。この制限は、Railsコンソールで[`ci_active_pipelines`](https://docs.gitlab.com/administration/instance_limits/#number-of-pipelines-running-concurrently)の下で設定することもできます。代わりに、同様の保護を提供する、推奨されている他のレート制限を使用してください。

- [**パイプラインのレート制限**](https://docs.gitlab.com/administration/settings/rate_limit_on_pipelines_creation/)。
- [**現在アクティブなパイプライン内のジョブの総数**](https://docs.gitlab.com/administration/settings/continuous_integration/#set-cicd-limits)。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Prometheusを通じたパフォーマンスメトリクスのモニタリング

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/346541)を参照してください。

</div>

GitLabは、Prometheusインスタンスに格納されているデータを表示することにより、ユーザーがパフォーマンスメトリクスを閲覧できるようにします。GitLabは、ダッシュボードにもこれらのメトリクスを表示します。ユーザーは、以前に設定した外部Prometheusインスタンスに接続するか、PrometheusをGitLab Managed Appとして設定できます。ただし、Kubernetesクラスターとの証明書ベースのインテグレーションはGitLabでは非推奨であるため、Prometheusに依存するGitLabのメトリクス機能も非推奨となっています。これには、ダッシュボードでのメトリクスの表示も含まれます。GitLabは、[Opstrace](https://about.gitlab.com/press/releases/2021-12-14-gitlab-acquires-opstrace-to-expand-its-devops-platform-with-open-source-observability-solution/)に基づいて単一のユーザーエクスペリエンスを開発するために取り組んでいます。Opstraceインテグレーションの作業をフォローするための[問題が存在](https://gitlab.com/groups/gitlab-org/-/epics/6976)があります。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### 有効期限切れのないアクセストークン

<div class="deprecation-notes">

- GitLab <span class="milestone">15.4</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/369122)を参照してください。

</div>

既存のプロジェクトアクセストークンに有効期限が自動的に適用されるかどうかは、お使いのGitLabの提供形態と、GitLab 16.0以降にアップグレードした時期によって異なります。

- GitLab.comでは、16.0マイルストーン期間中に、有効期限のない既存のプロジェクトアクセストークンには、現在の日付より365日後の有効期限が自動的に付与されました。
- GitLab Self-Managedで、GitLab 15.11以前からGitLab 16.0以降にアップグレードした場合:
  - 2024年7月23日以前に、有効期限のない既存のプロジェクトアクセストークンには、現在の日付より365日後の有効期限が自動的に付与されました。この変更は破壊的な変更です。
  - 2024年7月24日以降、有効期限日のない既存のプロジェクトアクセストークンには、有効期限日が設定されていませんでした。

GitLab Self-Managedで、次のいずれかのGitLabバージョンを新規インストールした場合、既存のプロジェクトアクセストークンに有効期限が自動的に適用されることはありません。

- 16.0.9
- 16.1.7
- 16.2.10
- 16.3.8
- 16.4.6
- 16.5.9
- 16.6.9
- 16.7.9
- 16.8.9
- 16.9.10
- 16.10.9
- 16.11.7
- 17.0.5
- 17.1.3
- 17.2.1

有効期限のないアクセストークンは無期限に有効であるため、アクセストークンが漏洩した場合、セキュリティリスクが生じます。有効期限のあるアクセストークンの方が優れているため、GitLab 15.3以降では、[デフォルトの有効期限](https://gitlab.com/gitlab-org/gitlab/-/issues/348660)を設定します。

GitLab 16.0では、有効期限のない[個人](https://docs.gitlab.com/user/profile/personal_access_tokens/)、[プロジェクト](https://docs.gitlab.com/user/project/settings/project_access_tokens/)、または[グループ](https://docs.gitlab.com/user/group/settings/group_access_tokens/)アクセストークンには、自動的に1年後の有効期限が設定されます。

デフォルトが適用される前に、会社のセキュリティポリシーに沿ってアクセストークンに有効期限を設定することをお勧めします。

- GitLab.comでは16.0マイルストーン期間中。
- GitLab Self-Managedでは、16.0にアップグレードされたとき。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### 非標準のデフォルトRedisポートは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/388269)を参照してください。

</div>

GitLabがRedis設定ファイルなしで起動した場合、GitLabは、`localhost:6380`、`localhost:6381`、および`localhost:6382`の3つのRedisサーバーに接続できると想定します。GitLabが`localhost:6379`に1つのRedisサーバーがあると想定するように、この動作を変更します。

3つのサーバーを維持したい管理者は、`config/redis.cache.yml`、`config/redis.queues.yml`、および`config/redis.shared_state.yml`ファイルを編集してRedis URLを設定する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### 削除保護設定のプロジェクトをすぐに削除するオプションは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/389557)を参照してください。

</div>

**管理者**エリアのグループおよびプロジェクト削除保護設定には、グループおよびプロジェクトをすぐに削除するオプションがありました。16.0以降、このオプションは利用できなくなり、グループとプロジェクトの遅延削除がデフォルトの動作になります。

このオプションは、グループ設定として表示されなくなります。GitLab Self-Managedのユーザーは、引き続き削除遅延期間を定義するオプションを持ち、GitLab.comのユーザーには、調整できない7日間のデフォルトの保持期間があります。ただし、プロジェクト設定からはプロジェクトを、グループ設定からはグループを引き続きすぐに削除できます。

デフォルトでグループとプロジェクトをすぐに削除するオプションは、ユーザーが誤ってこのアクションを実行し、グループとプロジェクトを完全に失うことを防ぐために非推奨になりました。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### PostgreSQL 12は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.0</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/349185)を参照してください。

</div>

PostgreSQL 12のサポートは、GitLab 16.0で削除される予定です。GitLab 16.0では、PostgreSQL 13が必要なPostgreSQLの最小バージョンになります。

PostgreSQL 12は、GitLab 15リリースサイクル全体でサポートされます。PostgreSQL 13は、GitLab 16.0より前にアップグレードしたいインスタンスでもサポートされます。

PostgreSQL 13のサポートは、GitLab 15.2でGeoに追加されました。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### プロジェクトAPIフィールド`operations_access_level`は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/385798)を参照してください。

</div>

プロジェクトAPIの`operations_access_level`フィールドは非推奨になります。このフィールドは、特定の機能を制御するフィールド（`releases_access_level`、`environments_access_level`、`feature_flags_access_level`、`infrastructure_access_level`、および`monitor_access_level`）に置き換えられました。

</div>

<div class="deprecation " data-milestone="16.0">

### ベアリポジトリをインポートするためのRakeタスク

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-com/Product/-/issues/5255)を参照してください。

</div>

ベアリポジトリをインポートするためのRakeタスク（`gitlab:import:repos`）は、GitLab 15.8で非推奨となり、GitLab 16.0で削除されます。

このRakeタスクは、リポジトリのディレクトリツリーをGitLabインスタンスにインポートします。これらのリポジトリは、機能するためにRakeタスクが特定のディレクトリ構造または特定のカスタムGit設定（`gitlab.fullpath`）に依存しているため、あらかじめGitLabによって管理されている必要があります。

このRakeタスクを使用してリポジトリをインポートするには、制限があります。Rakeタスク:

- プロジェクトおよびプロジェクトWikiリポジトリのみを認識し、デザイン、グループWiki、またはスニペットのリポジトリをサポートしません。
- サポートされていない場合でも、非ハッシュストレージプロジェクトのインポートが可能です。
- Git config `gitlab.fullpath`が設定されていることが前提となります。[エピック8953](https://gitlab.com/groups/gitlab-org/-/epics/8953)は、この設定のサポートを削除することを提案しています。

`gitlab:import:repos` Rakeタスクを使用する代わりに、次の方法があります。

- [エクスポートファイル](https://docs.gitlab.com/user/project/settings/import_export/)または[直接転送](https://docs.gitlab.com/user/group/import/#migrate-groups-by-direct-transfer-recommended)を使用してプロジェクトを移行すると、リポジトリも移行。
- [URLでのリポジトリ](https://docs.gitlab.com/user/project/import/repo_by_url/)のインポート。
- [GitLab以外のソースからの](https://docs.gitlab.com/user/project/import/)リポジトリのインポート。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Redis 5は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.3</span>で発表
- GitLab <span class="milestone">15.6</span>でサポート終了
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/331468)を参照してください。

</div>

GitLab 13.9、Omnibus GitLabパッケージおよびGitLab Helmチャート 4.9では、Redisバージョンが[Redis 6に更新](https://about.gitlab.com/releases/2021/02/22/gitlab-13-9-released/#omnibus-improvements)されました。Redis 5は2022年4月にサポートが終了し、GitLab 15.6の時点ではサポートされなくなります。独自のRedis 5.0インスタンスを使用している場合は、GitLab 16.0以降にアップグレードする前に、Redis 6.0以降にアップグレードする必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `POST /jobs/request` Runnerエンドポイントから`job_age`パラメーターを削除

<div class="deprecation-notes">

- GitLab <span class="milestone">15.2</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/334253)を参照してください。

</div>

GitLab Runnerとの通信で使用される、`POST /jobs/request` API エンドポイントから返される`job_age`パラメーターは、GitLabとRunnerのどの機能でも使用されたことがありません。このパラメーターはGitLab 16.0で削除されます。

これは、このエンドポイントから返されるこのパラメーターに依存する独自のRunnerを開発した人にとっては、破壊的な変更になる可能性があります。これは、GitLab.comのパブリック共有Runnerを含む、公式にリリースされたバージョンのGitLab Runnerを使用している人にとっては、破壊的な変更ではありません。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### GitLab 16.0でのSASTアナライザーのカバレッジの変更

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/390416)を参照してください。

</div>

GitLab SASTは、さまざまな[アナライザー](https://docs.gitlab.com/user/application_security/sast/analyzers/)を使用してコードをスキャンし、脆弱性を確認します。

GitLab SASTでデフォルトで使用されるアナライザーのサポート数を削減しています。これは、さまざまなプログラミング言語で、より高速で一貫性のあるユーザーエクスペリエンスを実現するための長期的な戦略の一環です。

GitLab 16.0以降、GitLab SAST CI/CDテンプレートは、.NETに[セキュリティコードスキャン](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan)ベースのアナライザーを使用しなくなり、サポート終了状態になります。このアナライザーを[SAST CI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)から削除し、[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)のC#用のGitLabサポート検出ルールに置き換えます。

このアナライザーはただちに有効になり、セキュリティアップデートのみを受信します。その他のルーチン改善または更新は保証されません。GitLab 16.0でこのアナライザーのサポートが終了した後、それ以上の更新は提供されません。ただし、このアナライザー用に以前に公開されたコンテナイメージを削除したり、カスタムCI/CDパイプラインジョブを使用して実行する機能を削除したりすることはありません。

非推奨のアナライザーからの脆弱性の検出をすでに無視している場合、置換後の機能では以前の無視が尊重されます。システム動作は以下に依存します。

- Semgrepベースのアナライザーの実行を過去に除外したかどうか。
- プロジェクトの脆弱性レポートに表示される脆弱性を最初に検出したアナライザー。

詳細については、[脆弱性の翻訳ドキュメント](https://docs.gitlab.com/user/application_security/sast/analyzers/#vulnerability-translation)を参照してください。

影響を受けるアナライザーにカスタマイズを適用した場合、またはパイプラインでSemgrepベースのアナライザーを現在無効にしている場合は、[この変更に関する非推奨の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/390416#breaking-change)に詳述されているように対応する必要があります。

**更新: **この変更の範囲を縮小しました。GitLab 16.0では、次の変更は行いません。

1. [PHPCS Security Audit](https://gitlab.com/gitlab-org/security-products/analyzers/phpcs-security-audit)に基づくアナライザーのサポートを削除し、[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)でGitLabが管理する検出ルールに置き換えます。
1. [SpotBugsベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)のスコープからScalaを削除し、[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)でGitLabが管理する検出ルールに置き換えます。

PHPCS Security Auditベースのアナライザーを置き換える作業は[問題364060](https://gitlab.com/gitlab-org/gitlab/-/issues/364060)で追跡され、ScalaスキャンをSemgrepベースのアナライザーに移行する作業は[問題362958](https://gitlab.com/gitlab-org/gitlab/-/issues/362958)で追跡されます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### セキュアアナライザーのメジャーバージョン更新

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/390912)を参照してください。

</div>

セキュアなステージでは、GitLab 16.0のリリースと連携して、アナライザーのメジャーバージョンが引き上げられます。この引き上げにより、以下のアナライザーの明確な区別が可能になります。

- 2023年5月22日より前にリリースされたもの
- 2023年5月22日以降にリリースされたもの

デフォルトの内蔵テンプレートを使用していない場合、またはアナライザーのバージョンを固定している場合は、固定されたバージョンを削除するか、CI/CDジョブ定義を更新して、最新のメジャーバージョンに更新する必要があります。GitLab 13.0 - 15.10のユーザーは、GitLab 16.0のリリースまでは通常どおりアナライザーの更新を引き続き利用できます。その後、新たに修正されたバグやリリースされた機能はすべて、アナライザーの新しいメジャーバージョンでのみリリースされます。[メンテナンスポリシー](https://docs.gitlab.com/policy/maintenance/)に従い、バグや機能を非推奨バージョンにバックポートすることはありません。必要に応じて、セキュリティパッチは最新の3つのマイナーリリース内でバックポートされます。具体的には、以下は非推奨となっており、16.0 GitLabリリース以降は更新されなくなります。

- APIファジング: バージョン2
- コンテナスキャン: バージョン5
- カバレッジファジング: バージョン3
- 依存関係スキャン: バージョン3
- 動的アプリケーションセキュリティテスト（DAST）: バージョン3
- DAST API: バージョン2
- IaCスキャン: バージョン3
- ライセンススキャン: バージョン4
- シークレット検出: バージョン4
- 静的アプリケーションセキュリティテスト（SAST）: [すべてのアナライザー](https://docs.gitlab.com/user/application_security/sast/#supported-languages-and-frameworks)のバージョン3
  - `brakeman`: バージョン3
  - `flawfinder`: バージョン3
  - `kubesec`: バージョン3
  - `mobsf`: バージョン3
  - `nodejs-scan`: バージョン3
  - `phpcs-security-audit`: バージョン3
  - `pmd-apex`: バージョン3
  - `security-code-scan`: バージョン3
  - `semgrep`: バージョン3
  - `sobelow`: バージョン3
  - `spotbugs`: バージョン3

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### セキュアスキャンのCI/CDテンプレートは、新しいジョブの`rules`を使用

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/391822)を参照してください。

</div>

セキュリティスキャンのためのGitLab管理のCI/CDテンプレートは、GitLab 16.0リリースで更新されます。この更新には、CI/CDテンプレートの最新バージョンですでにリリースされている改善が含まれます。これらの変更は、カスタマイズされたCI/CDパイプライン設定を混乱させる可能性があるため、最新のテンプレートバージョンでリリースしました。

更新されたすべてのテンプレートで、値が`"true"`の場合のみスキャンを無効にするように、`SAST_DISABLED`や`DEPENDENCY_SCANNING_DISABLED`などの変数の定義を更新しています。以前は、値が`"false"`であっても、スキャンは無効になっていました。

次のテンプレートが更新されます。

- APIファジング: [`API-Fuzzing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)
- コンテナスキャン: [`Container-Scanning.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Container-Scanning.gitlab-ci.yml)
- カバレッジガイドファジング: [`Coverage-Fuzzing.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Coverage-Fuzzing.gitlab-ci.yml)
- DAST: [`DAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST.gitlab-ci.yml)
- DAST API: [`DAST-API.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/DAST-API.gitlab-ci.yml)
- 依存関係スキャン: [`Dependency-Scanning.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.gitlab-ci.yml)
- IaCスキャン: [`SAST-IaC.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST-IaC.gitlab-ci.yml)
- AST: [`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)
- シークレット検出: [`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml)

上記のテンプレートのいずれかを使用していて、`_DISABLED`変数を使用しているが、`"true"`以外の値を設定している場合は、16.0リリース前にパイプラインをテストすることをお勧めします。

**更新: **以前、影響を受けるテンプレートの`rules`を更新して、デフォルトで[マージリクエストパイプライン](https://docs.gitlab.com/ci/pipelines/merge_request_pipelines/)で実行することを発表しました。しかし、[非推奨に関する問題で説明されている](https://gitlab.com/gitlab-org/gitlab/-/issues/388988#note_1372629948)互換性の問題により、GitLab 16.0でこの変更を行うことはなくなりました。上記のように、`_DISABLED`変数の変更は引き続きリリースします。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### セキュリティレポートスキーマバージョン14.x.x

<div class="deprecation-notes">

- GitLab <span class="milestone">15.3</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/366477)を参照してください。

</div>

バージョン 14.x.xの[セキュリティレポートスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas)は非推奨となります。

GitLab 15.8以降、スキーマバージョン14.x.xを使用する[セキュリティレポートスキャナーのインテグレーション](https://docs.gitlab.com/development/integrations/secure/)では、パイプラインの**セキュリティ**タブに非推奨の警告が表示されます。

GitLab 16.0以降、この機能は削除されます。スキーマバージョン14.x.xを使用するセキュリティレポートでは、パイプラインの**セキュリティ**タブでエラーが発生します。

詳細については、[セキュリティレポートの検証](https://docs.gitlab.com/user/application_security/#security-report-validation)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Kubernetes向けGitLabエージェントの設定におけるStarboardディレクティブ

<div class="deprecation-notes">

- GitLab <span class="milestone">15.4</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/368828)を参照してください。

</div>

GitLabコンテナスキャン機能は、Starboardのインストールを必要としなくなります。その結果、Kubernetes向けGitLabエージェントの設定ファイルでの`starboard:`ディレクティブの使用は非推奨となり、GitLab 16.0で削除される予定です。`container_scanning:`ディレクティブを使用するように設定ファイルを更新します。

</div>

<div class="deprecation " data-milestone="16.0">

### Windows Server 2004および20H2に基づくGitLab Runnerイメージの公開を停止

<div class="deprecation-notes">

- GitLab <span class="milestone">16.0</span>で発表
- GitLab <span class="milestone">16.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/31001)を参照してください。

</div>

Windows Server 2004および20H2のサポートが終了するため、GitLab 16.0の時点で、これらのオペレーティングシステムに基づくGitLab Runnerイメージは提供されなくなります。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Praefectカスタムメトリクスのエンドポイント設定のサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/390266)を参照してください。

</div>

`prometheus_exclude_database_from_default_metrics`設定値の使用のサポートはGitLab 15.9で非推奨となり、GitLab 16.0で削除されます。この設定値を使用するとパフォーマンスが低下するため、削除します。この変更は、次のメトリクスが`/metrics`で使用できなくなることを意味します。

- `gitaly_praefect_unavailable_repositories`。
- `gitaly_praefect_verification_queue_depth`。
- `gitaly_praefect_replication_queue_depth`。

これには、`/db_metrics`もスクレイプするようにメトリクス収集ターゲットを更新する必要がある場合もあります。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Terraform状態名でのピリオド（`.`）のサポートによる、既存の状態の破損の可能性

<div class="deprecation-notes">

- GitLab <span class="milestone">15.7</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/385564)を参照してください。

</div>

以前は、ピリオドを含むTerraform状態名はサポートされていませんでした。ただし、回避策を使用して、ピリオドを含む状態名を使用することもできました。

GitLab 15.7では、ピリオドを含む状態名の[完全なサポートが追加](https://docs.gitlab.com/user/infrastructure/iac/troubleshooting/#state-not-found-if-the-state-name-contains-a-period)されました。回避策を使用してこれらの状態名を処理する場合は、ジョブが失敗したり、Terraformを初めて実行したように見えたりする場合があります。

この問題を解決するには:

  1. ピリオドとそれに続く文字を除外して、状態ファイルの参照を変更します。
     - たとえば、状態名が`state.name`の場合は、すべての参照を`state`に変更します。
  1. Terraformコマンドを実行します。

ピリオドを含む完全な状態名を使用するには、[完全な状態ファイルに移行](https://docs.gitlab.com/user/infrastructure/iac/terraform_state/#migrate-to-a-gitlab-managed-terraform-state)します。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### API はKubernetes向けエージェントの失効したトークンの返却を停止

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/382129)を参照してください。

</div>

現在、[クラスターエージェントAPI](https://docs.gitlab.com/api/cluster_agents/#list-tokens-for-an-agent)エンドポイントへのGETリクエストは、失効したトークンを返すことができます。GitLab 16.0では、GETリクエストは失効したトークンを返しません。

これらのエンドポイントに対する呼び出しを確認し、失効したトークンを使用しないようにしてください。

この変更は、次のRESTおよびGraphQL APIエンドポイントに影響します。

- REST API:
  - [トークンを一覧表示する](https://docs.gitlab.com/api/cluster_agents/#list-tokens-for-an-agent)
  - [1つのトークンを取得する](https://docs.gitlab.com/api/cluster_agents/#get-a-single-agent-token)
- GraphQL:
  - [`ClusterAgent.tokens`](https://docs.gitlab.com/api/graphql/reference/#clusteragenttokens)

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### Phabricatorタスクインポーターは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.7</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-com/Product/-/issues/4894)を参照してください。

</div>

Phabricatorタスクインポーターは非推奨になります。プロジェクトとしてのPhabricator自体は、2021年6月1日以降、積極的にメンテナンスされなくなります。このツールを使用したインポートは確認されていません。GitLabで公開されている関連問題のアクティビティはありません。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### 最新のTerraformテンプレートは現在の安定版テンプレートを上書き

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/386001)を参照してください。

</div>

GitLabのメジャーバージョンがリリースされるたびに、安定版のTerraformテンプレートを現在の最新テンプレートで更新します。この変更は、[クイックスタート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform.gitlab-ci.yml)テンプレートと[ベース](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform/Base.gitlab-ci.yml)テンプレートに影響します。

新しいテンプレートにはデフォルトのルールが付属しているため、更新するとTerraformパイプラインが壊れる可能性があります。たとえば、Terraformジョブがダウンストリームパイプラインとしてトリガーされる場合、GitLab 16.0ではルールはジョブをトリガーしません。

変更に対応するには、`.gitlab-ci.yml`ファイルで[`rules`](https://docs.gitlab.com/ci/yaml/#rules)を調整する必要がある場合があります。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### マージリクエストでの`/draft`クイックアクションの動作の切り替え

<div class="deprecation-notes">

- GitLab <span class="milestone">15.4</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/365365)を参照してください。

</div>

クイックアクションを介してマージリクエストの下書き状態を切り替える動作をより明確にするために、`/draft`クイックアクションの切替動作を非推奨にして削除します。GitLab 16.0リリース以降、`/draft`はマージリクエストを下書きに設定するだけとなり、新しい`/ready`クイックアクションを使用して下書き状態が削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `vulnerabilityFindingDismiss`変異での`id`フィールドの使用

<div class="deprecation-notes">

- GitLab <span class="milestone">15.3</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/367166)を参照してください。

</div>

`vulnerabilityFindingDismiss` GraphQL変異を使用して、脆弱性の検出の状態を`Dismissed`に設定できます。以前は、この変異は`id`フィールドを使用して検出を一意に識別していました。ただし、これはパイプラインセキュリティータブからの検出の無視では機能しませんでした。したがって、識別子としての`id`フィールドの使用は、`uuid`フィールドを優先して削除されました。識別子として'uuid'フィールドを使用すると、パイプラインセキュリティータブから検出を無視できます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### サードパーティのコンテナレジストリの使用は非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/376216)を参照してください。

</div>

GitLabを認証エンドポイントとして使用するサードパーティのコンテナレジストリの使用はGitLab 15.8で非推奨となり、GitLab 16.0で[サポート終了](https://docs.gitlab.com/development/deprecation_guidelines/#terminology)が予定されています。これは、コンテナイメージを検索、表示、および削除するために、外部レジストリをGitLabユーザーインターフェイスに接続しているGitLab Self-Managedのユーザーに影響します。

GitLabコンテナレジストリとサードパーティのコンテナレジストリの両方をサポートすることは、メンテナンス、コード品質、および下位互換性にとって困難です。これにより、[効率的](https://handbook.gitlab.com/handbook/values/#efficiency)な状態を維持する能力が妨げられます。その結果、今後はこの機能をサポートしません。

この変更は、パイプラインを使用してコンテナイメージを外部レジストリにプルおよびプッシュする機能には影響しません。

GitLab.com用の新しい[GitLabコンテナレジストリ](https://gitlab.com/groups/gitlab-org/-/epics/5523)バージョンをリリースして以来、サードパーティのコンテナレジストリでは利用できない追加機能の実装を開始しました。これらの新機能により、[クリーンアップポリシー](https://gitlab.com/groups/gitlab-org/-/epics/8379)など、大幅なパフォーマンス改善を達成できました。[新機能](https://gitlab.com/groups/gitlab-org/-/epics/5136)の提供に注力しており、そのほとんどはGitLabコンテナレジストリでのみ利用可能な機能が必要になります。この非推奨化により、より堅牢な統合レジストリエクスペリエンスと機能セットの提供に注力することで、長期的に断片化とユーザーの不満を軽減できます。

今後、GitLabコンテナレジストリでのみ利用可能な新機能の開発とリリースに引き続き投資していきます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### パスの最後にグローバルIDを持つ作業アイテムのパスは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.10</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/393836)を参照してください。

</div>

作業アイテムURLでのグローバルIDの使用は非推奨です。将来的には、内部ID（IID）のみがサポートされます。

GitLabは複数の作業アイテムタイプをサポートしているため、`https://gitlab.com/gitlab-org/gitlab/-/work_items/<global_id>`などのパスには、たとえば、[タスク](https://docs.gitlab.com/user/tasks/)や[OKR](https://docs.gitlab.com/user/okrs/)が表示されることがあります。

GitLab 15.10では、最後にクエリパラメーター（`iid_path`）を追加することにより、そのパスで内部 ID（IID）を使用するサポートを追加しました（`https://gitlab.com/gitlab-org/gitlab/-/work_items/<iid>?iid_path=true`の形式）。

GitLab 16.0では、作業アイテムパスでグローバルIDを使用する機能が削除されます。パスの最後にある数値は、最後にクエリパラメーターを追加しなくても、内部ID（IID）と見なされます。サポートされる形式は、`https://gitlab.com/gitlab-org/gitlab/-/work_items/<iid>`のみです。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `CI_BUILD_*`定義済み変数

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352957)を参照してください。

</div>

`CI_BUILD_*`で始まる定義済みのCI/CD変数はGitLab 9.0で非推奨となっていて、GitLab 16.0で削除されます。これらの変数をまだ使用している場合は、機能的に同一である置換[定義済み変数](https://docs.gitlab.com/ci/variables/predefined_variables/)に必ず変更してください。

| 削除された変数      | 代替変数    |
| --------------------- |------------------------ |
| `CI_BUILD_BEFORE_SHA` | `CI_COMMIT_BEFORE_SHA`  |
| `CI_BUILD_ID`         | `CI_JOB_ID`             |
| `CI_BUILD_MANUAL`     | `CI_JOB_MANUAL`         |
| `CI_BUILD_NAME`       | `CI_JOB_NAME`           |
| `CI_BUILD_REF`        | `CI_COMMIT_SHA`         |
| `CI_BUILD_REF_NAME`   | `CI_COMMIT_REF_NAME`    |
| `CI_BUILD_REF_SLUG`   | `CI_COMMIT_REF_SLUG`    |
| `CI_BUILD_REPO`       | `CI_REPOSITORY_URL`     |
| `CI_BUILD_STAGE`      | `CI_JOB_STAGE`          |
| `CI_BUILD_TAG`        | `CI_COMMIT_TAG`         |
| `CI_BUILD_TOKEN`      | `CI_JOB_TOKEN`          |
| `CI_BUILD_TRIGGERED`  | `CI_PIPELINE_TRIGGERED` |

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `POST ci/lint` APIエンドポイントは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.7</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/381669)を参照してください。

</div>

`POST ci/lint` APIエンドポイントは15.7で非推奨となり、16.0で削除されます。このエンドポイントは、CI/CD設定オプションのすべての範囲を検証しません。代わりに、CI/CD設定を適切に検証する[`POST /projects/:id/ci/lint`](https://docs.gitlab.com/api/lint/#validate-a-ci-yaml-configuration-with-a-namespace)を使用してください。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### DORA API用の`environment_tier`パラメーター

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/365939)を参照してください。

</div>

混乱と重複を避けるため、`environment_tier`パラメーターは`environment_tiers`パラメーターを優先して非推奨になります。新しい`environment_tiers`パラメーターを使用すると、DORA APIは複数のプランに対して集計されたデータを同時に返すことができます。`environment_tier`パラメーターはGitLab 16.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `PipelineSecurityReportFinding` GraphQLタイプ用の`name`フィールド

<div class="deprecation-notes">

- GitLab <span class="milestone">15.1</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/346335)を参照してください。

</div>

以前、新しい`title`フィールドを含めるように、[`PipelineSecurityReportFinding` GraphQLタイプが更新されました](https://gitlab.com/gitlab-org/gitlab/-/issues/335372)。このフィールドは現在の`name`フィールドのエイリアスであり、特定性の低い`name`フィールドは冗長になっています。`name`フィールドは、GitLab 16.0で`PipelineSecurityReportFinding`タイプから削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `started`イテレーションの状態

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/334018)を参照してください。

</div>

[イテレーションGraphQL API](https://docs.gitlab.com/api/graphql/reference/#iterationstate)および[イテレーションREST API](https://docs.gitlab.com/api/iterations/#list-project-iterations)の`started`イテレーション状態は非推奨となります。

GitLab 16.0でGraphQL APIバージョンは削除されます。この状態は、マイルストーンなど、他の時間ベースのエンティティの命名と一致する`current`状態（すでに利用可能）に置き換えられています。

次のv5 REST APIバージョンまで、REST APIバージョンで`started`状態のサポートを継続する予定です。

</div>

<div class="deprecation breaking-change" data-milestone="16.0">

### `vulnerabilityFindingDismiss` GraphQL変異

<div class="deprecation-notes">

- GitLab <span class="milestone">15.5</span>で発表
- GitLab <span class="milestone">16.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/375645)を参照してください。

</div>

`VulnerabilityFindingDismiss` GraphQL変異は非推奨となり、GitLab 16.0で削除されます。この変異は、ユーザーが脆弱性検出IDを利用できなかったため（このフィールドは[15.3で非推奨](https://docs.gitlab.com/update/deprecations/#use-of-id-field-in-vulnerabilityfindingdismiss-mutation)になりました）、あまり使用されていませんでした。ユーザーは代わりに、脆弱性レポートの脆弱性を無視するには`VulnerabilityDismiss`、CIパイプラインセキュリティタブのセキュリティ検出を無視するには`SecurityFindingDismiss`を使用する必要があります。

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.11">

## GitLab 15.11

<div class="deprecation " data-milestone="15.11">

### openSUSE Leap 15.3パッケージ

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">15.11</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7371)を参照してください。

</div>

openSUSE Leap 15.3のディストリビューションサポートおよびセキュリティ更新は[2022年12月に終了](https://en.opensuse.org/Lifetime#Discontinued_distributions)しました。

GitLab 15.7以降、openSUSE Leap 15.4のパッケージの提供を開始しており、15.11のマイルストーンでopenSUSE Leap 15.3のパッケージの提供を停止します。

- openSUSE Leap 15.3パッケージから、提供されている15.4パッケージに切り替えます。

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.10">

## GitLab 15.10

<div class="deprecation breaking-change" data-milestone="15.10">

### OpenStack SwiftおよびRackspace APIを使用した自動バックアップのアップロード

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">15.10</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/387976)を参照してください。

</div>

OpenStack SwiftおよびRackspace APIを使用した**リモートストレージへのバックアップのアップロード**のサポートを非推奨にします。これらのAPIのサポートは、積極的にメンテナンスされなくなり、Ruby 3用に更新されていないサードパーティライブラリに依存しています。GitLabは、セキュリティパッチの最新の状態を維持するために、Ruby 2のEOLより前にRuby 3に切り替えています。

- OpenStackを使用している場合は、Swiftの代わりにS3 APIを使用するように設定を変更する必要があります。
- Rackspaceストレージを使用している場合は、別のプロバイダーに切り替えるか、バックアップタスクの完了後にバックアップファイルを手動でアップロードする必要があります。

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.9">

## GitLab 15.9

<div class="deprecation breaking-change" data-milestone="15.9">

### KubernetesとのGitLab.com証明書ベースのインテグレーション

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">15.9</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)を参照してください。

</div>

Kubernetesとの証明書ベースのインテグレーションは[非推奨となり、削除されます](https://about.gitlab.com/blog/2021/11/15/deprecating-the-cert-based-kubernetes-integration/)。GitLab 15.0以降、GitLab.comユーザーとして、新しいネームスペースで証明書ベースのアプローチを使用してGitLabとクラスターを統合できなくなります。現在のユーザーのインテグレーションは、ネームスペースごとに有効になります。

Kubernatesとのより堅牢で安全かつ信頼性の高いインテグレーションを行うには、[Kubernetes用エージェント](https://docs.gitlab.com/user/clusters/agent/)を使用してKubernetesクラスターをGitLabに接続することをお勧めします。[移行方法はこちらです。](https://docs.gitlab.com/user/infrastructure/clusters/migrate_to_gitlab_agent/)

明示的な削除日が設定されていますが、新しいソリューションに機能の同等性が備わるまでは、この機能を削除する予定はありません。削除のブロッカーの詳細については、[この問題](https://gitlab.com/gitlab-org/configure/general/-/issues/199)を参照してください。

この非推奨化に関する最新情報と詳細については、[このエピック](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)に従ってください。

GitLab Self-Managedのお客様は、[機能フラグ](https://docs.gitlab.com/update/deprecations/#self-managed-certificate-based-integration-with-kubernetes)を使用して引き続き機能を使用できます。

</div>

<div class="deprecation breaking-change" data-milestone="15.9">

### Web IDEでのライブプレビューの利用停止

<div class="deprecation-notes">

- GitLab <span class="milestone">15.8</span>で発表
- GitLab <span class="milestone">15.9</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/383889)を参照してください。

</div>

Web IDEのライブプレビュー機能は、静的なWebアプリケーションのクライアント側のプレビューを提供するように設計されていました。ただし、設定手順が複雑で、サポートされているプロジェクトタイプの範囲が狭いため、その有用性は限られています。GitLab 15.7でWeb IDEベータ版が導入されたことで、フルサーバー側のランタイム環境に接続できるようになりました。Web IDEでの拡張機能のインストールに対する今後のサポートにより、ライブプレビューで利用できるワークフローよりも高度なワークフローもサポートします。GitLab 15.9以降、Web IDEでライブプレビューは利用できなくなります。

</div>

<div class="deprecation breaking-change" data-milestone="15.9">

### `omniauth-authentiq` gemの利用停止

<div class="deprecation-notes">

- GitLab <span class="milestone">15.9</span>で発表
- GitLab <span class="milestone">15.9</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/389452)を参照してください。

</div>

`omniauth-authentiq`は、GitLabの一部であったOmniAuth戦略gemです。認証サービスを提供する会社であるAuthentiqが閉鎖されました。したがって、gemは削除されます。

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.7">

## GitLab 15.7

<div class="deprecation breaking-change" data-milestone="15.7">

### `.gitlab-ci.yml`でのファイルタイプ変数の展開

<div class="deprecation-notes">

- GitLab <span class="milestone">15.5</span>で発表
- GitLab <span class="milestone">15.7</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/29407)を参照してください。

</div>

以前は、エイリアスファイル変数を参照または適用した変数は、`File`型変数の値を展開していました。たとえば、ファイルの内容です。この動作は、一般的なシェル変数展開ルールに準拠していなかったため、正しくありませんでした。`File`型変数に保存されているシークレットまたは機密情報を漏洩するために、ユーザーが$echoコマンドを変数と一緒に入力パラメーターとして実行する可能性がありました。

この破壊的な変更によりこの問題が修正されますが、この動作に対処するユーザーワークフローが混乱する可能性があります。この変更により、エイリアスファイル変数を参照または適用するジョブ変数展開は、ファイルの内容などの値の代わりに、`File`型変数のファイル名またはパスに展開されます。

</div>

<div class="deprecation " data-milestone="15.7">

### Flowdockインテグレーション

<div class="deprecation-notes">

- GitLab <span class="milestone">15.7</span>で発表
- GitLab <span class="milestone">15.7</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/379197)を参照してください。

</div>

2022年8月15日にサービスが終了したため、2022年12月22日の時点でFlowdockインテグレーションを削除します。

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.6">

## GitLab 15.6

<div class="deprecation " data-milestone="15.6">

### Gitリポジトリストレージ用のNFS

<div class="deprecation-notes">

- GitLab <span class="milestone">14.0</span>で発表
- GitLab <span class="milestone">15.6</span>で削除

</div>

Gitaly Clusterの一般提供（[GitLab 13.0で導入](https://about.gitlab.com/releases/2020/05/22/gitlab-13-0-released/)）に伴い、GitLab 14.0でGitリポジトリストレージ用のNFSの開発（バグ修正、パフォーマンスの改善など）を非推奨としました。GitリポジトリのNFSについては14.x全体でテクニカルサポートを引き続き提供しますが、2022年11月22日にNFSのサポートをすべて削除します。これは当初2022年5月22日に計画されていましたが、Gitaly Clusterの継続的な成熟を可能にするために、サポートを非推奨とする日付を延長することにしました。詳細については、公式の[サポートステートメント](https://about.gitlab.com/support/statement-of-support/#gitaly-and-nfs)をご覧ください。

Gitaly Clusterは、お客様に次のような大きなメリットをもたらします。

- [変数のレプリケーション係数](https://docs.gitlab.com/administration/gitaly/#replication-factor)。
- [強力な整合性](https://docs.gitlab.com/administration/gitaly/#strong-consistency)。
- [分散読み取り機能](https://docs.gitlab.com/administration/gitaly/#distributed-reads)。

現在GitリポジトリにNFSを使用しているお客様は、[Gitaly Clusterへの移行](https://docs.gitlab.com/administration/gitaly/#migrate-to-gitaly-cluster)に関するドキュメントを確認して、移行を計画することをお勧めします。

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.4">

## GitLab 15.4

<div class="deprecation " data-milestone="15.4">

### バンドルされたGrafanaは非推奨

<div class="deprecation-notes">

- GitLab <span class="milestone">15.3</span>で発表
- GitLab <span class="milestone">15.4</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6972)を参照してください。

</div>

GitLab 15.4では、バンドルされたGrafanaを、GitLabがメンテナンスするGrafanaのフォークに切り替えます。

[GrafanaのCVEが特定](https://nvd.nist.gov/vuln/detail/CVE-2022-31107)されました。バンドルしていたGrafanaの古いバージョンが長期サポートを受けなくなったため、このセキュリティ脆弱性を軽減するには、独自のフォークに切り替える必要があります。

以前のバージョンのGrafanaとの非互換性は発生しないはずです。バンドルされたバージョンを使用している場合も、Grafanaの外部インスタンスを使用している場合も同様です。

</div>

<div class="deprecation breaking-change" data-milestone="15.4">

### SASTアナライザーの統合とCI/CDテンプレートの変更

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.4</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352554)を参照してください。

</div>

GitLab SASTは、さまざまな[アナライザー](https://docs.gitlab.com/user/application_security/sast/analyzers/)を使用してコードをスキャンし、脆弱性を確認します。

より優れた一貫性のあるユーザーエクスペリエンスを提供するための長期的な戦略の一環として、GitLab SASTで使用されるアナライザーの数を減らしています。アナライザーのセットを効率化すると、[イテレーション](https://handbook.gitlab.com/handbook/values/#iteration)の高速化、[結果](https://handbook.gitlab.com/handbook/values/#results)の向上、および[効率性の向上](https://handbook.gitlab.com/handbook/values/#efficiency)（ほとんどの場合、CI Runnerの使用量の削減を含む）が可能になります。

GitLab 15.4では、GitLab SASTは次のアナライザーを使用しなくなります。

- [ESLint](https://gitlab.com/gitlab-org/security-products/analyzers/eslint)（JavaScript、TypeScript、React）
- [Gosec](https://gitlab.com/gitlab-org/security-products/analyzers/gosec)（Go）
- [Bandit](https://gitlab.com/gitlab-org/security-products/analyzers/bandit)（Python）

注: この変更は当初GitLab 15.0で計画されていましたが、GitLab 15.4に延期されました。

これらのアナライザーは[GitLab管理のSAST CI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)から削除され、[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)に置き換えられます。これらのアナライザーはただちに有効になり、セキュリティアップデートのみを受信します。その他のルーチン改善または更新は保証されません。これらのアナライザーがサポート終了になると、それ以上の更新は提供されません。これらのアナライザー用に以前に公開したコンテナイメージは削除しません。そのような変更は、[非推奨化、削除、または破壊的な変更の発表](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#deprecations-removals-and-breaking-changes)として発表します。

また、[SpotBugs](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)アナライザーのスコープからJavaを削除し、[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)に置き換えます。この変更により、Javaコードのスキャンが簡単になり、コンパイルが不要になります。この変更は、[GitLab管理のSAST CI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)の自動言語検出部分に反映されます。SpotBugsベースのアナライザーは、Groovy、Kotlin、およびScalaを引き続きカバーすることに注意してください。

非推奨のアナライザーの1つからの脆弱性の検出をすでに無視している場合、置換後の機能では以前の無視が尊重されます。システム動作は以下に依存します。

- Semgrepベースのアナライザーの実行を過去に除外したかどうか。
- プロジェクトの脆弱性レポートに表示される脆弱性を最初に検出したアナライザー。

詳細については、[脆弱性の翻訳ドキュメント](https://docs.gitlab.com/user/application_security/sast/analyzers/#vulnerability-translation)を参照してください。

影響を受けるアナライザーのいずれかにカスタマイズを適用した場合、またはパイプラインで現在Semgrepアナライザーを無効にしている場合は、[この変更に関する非推奨の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352554#breaking-change)で詳しく説明されているように対処する必要があります。

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.3">

## GitLab 15.3

<div class="deprecation " data-milestone="15.3">

### 脆弱性レポートの状態による並べ替え

<div class="deprecation-notes">

- GitLab <span class="milestone">15.0</span>で発表
- GitLab <span class="milestone">15.3</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/360516)を参照してください。

</div>

脆弱性レポートを`State`列で並べ替える機能は、基盤となるデータモデルのリファクタリングにより、GitLab 14.10で無効になり、機能フラグで管理されるようになりました。この値での並べ替えの性能を保つためには、さらなるリファクタリングが必要になるため、機能フラグはデフォルトでオフのままになっています。`State`列を使用した並べ替えが非常に少ないため、コードベースを簡素化し、不要なパフォーマンス低下を防ぐために、機能フラグは代わりに削除されます。

</div>

<div class="deprecation " data-milestone="15.3">

### 脆弱性レポートのツールによる並べ替え

<div class="deprecation-notes">

- GitLab <span class="milestone">15.1</span>で発表
- GitLab <span class="milestone">15.3</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/362962)を参照してください。

</div>

脆弱性レポートを`Tool`列（スキャンタイプ）で並べ替える機能は、基盤となるデータモデルのリファクタリングにより、GitLab 14.10で無効になり、機能フラグで管理されるようになりました。この値での並べ替えの性能を保つためには、さらなるリファクタリングが必要になるため、機能フラグはデフォルトでオフのままになっています。`Tool`列を使用した並べ替えが非常に少ないため、コードベースを簡素化し、不要なパフォーマンス低下を防ぐために、GitLab 15.3で機能フラグは代わりに削除されます。

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.1">

## GitLab 15.1

<div class="deprecation " data-milestone="15.1">

### Debian 9のサポートを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">14.9</span>で発表
- GitLab <span class="milestone">15.1</span>で削除

</div>

[Debian 9 Stretchの長期サービスとサポート（LTSS）は2022年7月に終了](https://wiki.debian.org/LTS)します。そのため、GitLabパッケージでは、Debian 9ディストリビューションをサポートしなくなります。ユーザーは、Debian 10またはDebian 11にアップグレードできます。

</div>
</div>

<div class="milestone-wrapper" data-milestone="15.0">

## GitLab 15.0

<div class="deprecation breaking-change" data-milestone="15.0">

### リポジトリプッシュイベントの監査イベント

<div class="deprecation-notes">

- GitLab <span class="milestone">14.3</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/337993)を参照してください。

</div>

**リポジトリイベント**の監査イベントは非推奨となり、GitLab 15.0で削除されます。

これらのイベントは常にデフォルトで無効になっており、機能フラグを使用して手動で有効にする必要がありました。これらを有効にすると、生成されるイベントが多すぎてGitLabインスタンスの速度が大幅に低下する可能性があります。このため、これらは削除されています。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### オブジェクトストレージのバックグラウンドアップロード

<div class="deprecation-notes">

- GitLab <span class="milestone">14.9</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/26600)を参照してください。

</div>

[オブジェクトストレージ機能](https://docs.gitlab.com/administration/object_storage/)の全体的な複雑さとメンテナンスの負担を軽減するために、`background_upload`を使用してファイルをアップロードするサポートは非推奨となり、GitLab 15.0で完全に削除されます。[オブジェクトストレージ用の削除されたバックグラウンドアップロード設定](https://docs.gitlab.com/omnibus/update/gitlab_15_changes/)の[15.0 固有の変更点](https://docs.gitlab.com/omnibus/update/gitlab_15_changes/#removed-background-uploads-settings-for-object-storage)を確認してください。

これは、オブジェクトストレージプロバイダーの小さなサブセットに影響を与えます。

- **OpenStack**: OpenStackをご利用のお客様は、Swiftの代わりにS3 APIを使用するように設定を変更する必要があります。
- **RackSpace**: RackSpaceベースのオブジェクトストレージをご利用のお客様は、データを別のプロバイダーに移行する必要があります。

GitLabは、影響を受けるお客様の移行を支援するために、追加のガイダンスを公開します。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### CI/CDジョブ名の長さ制限

<div class="deprecation-notes">

- GitLab <span class="milestone">14.6</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/342800)を参照してください。

</div>

GitLab 15.0では、CI/CDジョブ名の文字数を255文字に制限します。ジョブ名が255文字の制限を超えるパイプラインは、15.0のリリース後に動作しなくなります。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### インスタンス（共有）Runnerをプロジェクト（特定）Runnerに変更

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/345347)を参照してください。

</div>

GitLab 15.0では、インスタンス（共有）Runnerをプロジェクト（特定）Runnerに変更できなくなります。

ユーザーはインスタンスRunnerをプロジェクトRunnerに誤って変更することが多く、元に戻すことができません。GitLabでは、セキュリティ上の理由から、プロジェクトRunnerを共有Runnerに変更することはできません。1つのプロジェクトを対象としたRunnerが、インスタンス全体のジョブを実行するように設定される可能性があります。

複数のプロジェクトにRunnerを追加する必要がある管理者は、1つのプロジェクトにRunnerを登録してから、管理者ビューに移動して追加のプロジェクトを選択することができます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### コンテナネットワークとホストのセキュリティ

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

GitLabコンテナネットワークセキュリティおよびコンテナホストセキュリティのカテゴリに関連するすべての機能は、GitLab 14.8で非推奨となり、GitLab 15.0で削除される予定です。この機能の代替が必要なユーザーは、GitLabの外部でインストールして管理できる潜在的なソリューションとして、次のオープンソースプロジェクトを評価することをお勧めします。[AppArmor](https://gitlab.com/apparmor/apparmor)、[Cilium](https://github.com/cilium/cilium)、[Falco](https://github.com/falcosecurity/falco)、[FluentD](https://github.com/fluent/fluentd)、[Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/)。

これらのテクノロジーをGitLabに統合するには、[クラスター管理プロジェクトテンプレート](https://docs.gitlab.com/user/clusters/management_project_template/)のコピーに目的のHelmチャートを追加します。GitLab [CI/CD](https://docs.gitlab.com/user/clusters/agent/ci_cd_workflow/)を通じてコマンドを呼び出すことにより、これらのHelmチャートを本番環境にデプロイします。

この変更の一環として、GitLab内の次の特定の機能が非推奨となり、GitLab 15.0で削除される予定です。

- **セキュリティとコンプライアンス > 脅威モニタリング**ページ。
- **セキュリティとコンプライアンス > ポリシー**ページにある`Network Policy`セキュリティポリシータイプ。
- GitLabを介して次のテクノロジーとのインテグレーションを管理する機能。AppArmor、Cilium、Falco、FluentD、Pod Security Policies。
- 上記の機能に関連するすべてのAPI。

追加のコンテキストが必要な場合や、この変更に関するフィードバックを提供する場合は、公開されている[非推奨に関する問題](https://gitlab.com/groups/gitlab-org/-/epics/7476)を参照してください。

</div>

<div class="deprecation " data-milestone="15.0">

### 14.0.0より前のコンテナスキャンスキーマ

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除

</div>

14.0.0より前のバージョンの[コンテナスキャンレポートスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)は、GitLab 15.0でサポートされなくなります。レポートで宣言されているスキーマバージョンに対して検証に合格しないレポートも、GitLab 15.0でサポートされなくなります。

パイプラインジョブアーティファクトとして[コンテナスキャンセキュリティレポートを出力することにより、GitLabと統合](https://docs.gitlab.com/development/integrations/secure/#report)するサードパーティツールが影響を受けます。すべての出力レポートが、最小バージョン14.0.0で正しいスキーマに準拠していることを確認する必要があります。バージョンが低いレポート、または宣言されたスキーマバージョンに対して検証に失敗したレポートは処理されず、脆弱性の検出結果は、MR、パイプライン、脆弱性レポートに表示されません。

移行を支援するため、GitLab 14.10以降では、非準拠レポートが発生すると、脆弱性レポートに[警告](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)が表示されます。

</div>

<div class="deprecation " data-milestone="15.0">

### 14.0.0より前のカバレッジガイドファジングスキーマ

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除

</div>

バージョン14.0.0より前の[カバレッジガイドファジングレポートスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)は、GitLab 15.0でサポートされなくなります。レポートで宣言されているスキーマバージョンに対して検証に合格しないレポートも、GitLab 15.0でサポートされなくなります。

パイプラインジョブアーティファクトとして[カバレッジガイドファジングセキュリティレポートを出力することによりGitLabと統合](https://docs.gitlab.com/development/integrations/secure/#report)するサードパーティツールが影響を受けます。すべての出力レポートが、最小バージョン14.0.0で正しいスキーマに準拠していることを確認する必要があります。バージョンが低いレポート、または宣言されたスキーマバージョンに対して検証に失敗したレポートは処理されず、脆弱性の検出結果は、MR、パイプライン、脆弱性レポートに表示されません。

移行を支援するため、GitLab 14.10以降では、非準拠レポートが発生すると、脆弱性レポートに[警告](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)が表示されます。

</div>

<div class="deprecation " data-milestone="15.0">

### 14.0.0より前のDASTスキーマ

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除

</div>

14.0.0より前のバージョンの[DASTレポートスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)は、GitLab 15.0でサポートされなくなります。レポートで宣言されているスキーマバージョンに対して検証に合格しないレポートも、GitLab 15.0でサポートされなくなります。

パイプラインジョブアーティファクトとして[DASTセキュリティレポートを出力することにより、GitLabと統合](https://docs.gitlab.com/development/integrations/secure/#report)するサードパーティツールが影響を受けます。すべての出力レポートが、最小バージョン14.0.0で正しいスキーマに準拠していることを確認する必要があります。バージョンが低いレポート、または宣言されたスキーマバージョンに対して検証に失敗したレポートは処理されず、脆弱性の検出結果は、MR、パイプライン、脆弱性レポートに表示されません。

移行を支援するため、GitLab 14.10以降では、非準拠レポートが発生すると、脆弱性レポートに[警告が表示](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)されます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### 依存関係スキャンPython 3.9および3.6イメージの非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/334060)を参照してください。

</div>

Pythonプロジェクトに依存関係スキャンを使用しているユーザーを対象として、Python 3.6を使用するデフォルトの`gemnasium-python:2`イメージと、Python 3.9を使用するカスタム`gemnasium-python:2-python-3.9`イメージを非推奨にします。GitLab 15.0以降の新しいデフォルトイメージは、Python 3.9用になります。[Phython 3.9がサポートされるバージョン](https://endoflife.date/python)であり、3.6[はサポートされなくなる](https://endoflife.date/python)ためです。

Python 3.9または3.9互換のプロジェクトを使用しているユーザーは、アクションを実行する必要はなく、依存関係のスキャンはGitLab 15.0で開始されるはずです。新しいコンテナを今すぐテストする場合は、このコンテナ（15.0で削除されます）を使用してプロジェクトでテストパイプラインを実行してください。Python 3.9イメージを使用します。

```yaml
gemnasium-python-dependency_scanning:
  image:
    name: registry.gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python:2-python-3.9
```

Python 3.6を使用しているユーザーの場合、GitLab 15.0以降では、依存関係スキャンのためにデフォルトテンプレートを使用できなくなります。非推奨の`gemnasium-python:2`アナライザーイメージを使用するように切り替える必要があります。これによって影響を受ける場合は、[この問題](https://gitlab.com/gitlab-org/gitlab/-/issues/351503)にコメントしてください。必要に応じて、こちらで削除の延長を検討します。

3.9の特別な例外イメージを使用しているユーザーは、代わりにデフォルト値を使用し、コンテナを上書きしないようにする必要があります。3.9の特別な例外イメージを使用しているかどうかを確認するには、`.gitlab-ci.yml`ファイルで次の参照を確認してください。

```yaml
gemnasium-python-dependency_scanning:
  image:
    name: registry.gitlab.com/gitlab-org/security-products/analyzers/gemnasium-python:2-python-3.9
```

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### 依存関係スキャンのデフォルトJavaバージョンを17に変更

<div class="deprecation-notes">

- GitLab <span class="milestone">14.10</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

GitLab 15.0では、依存関係スキャンの場合、スキャナーが予期するJavaのデフォルトバージョンが11から17に更新されます。Java 17は[最新の長期サポート（LTS）バージョン](https://en.wikipedia.org/wiki/Java_version_history)です。依存関係スキャンは、同じ[バージョン範囲（8、11、13、14、15、16、17）](https://docs.gitlab.com/user/application_security/dependency_scanning/#supported-languages-and-package-managers)を引き続きサポートしており、デフォルトバージョンのみが変更されます。プロジェクトが以前のJava 11のデフォルトを使用している場合は、一致するように[`DS_Java_Version`変数を設定](https://docs.gitlab.com/user/application_security/dependency_scanning/#configuring-specific-analyzers-used-by-dependency-scanning)してください。

</div>

<div class="deprecation " data-milestone="15.0">

### 14.0.0より前の依存関係スキャンスキーマ

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除

</div>

14.0.0より前のバージョンの[依存関係スキャンのレポートスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)は、GitLab 15.0でサポートされなくなります。レポートで宣言されているスキーマバージョンに対して検証に合格しないレポートも、GitLab 15.0でサポートされなくなります。

パイプラインジョブアーティファクトとして[依存関係スキャンセキュリティレポートを出力することによりGitLabと統合](https://docs.gitlab.com/development/integrations/secure/#report)するサードパーティツールが影響を受けます。すべての出力レポートが、最小バージョン14.0.0で正しいスキーマに準拠していることを確認する必要があります。バージョンが低いレポート、または宣言されたスキーマバージョンに対して検証に失敗したレポートは処理されず、脆弱性の検出結果は、MR、パイプライン、脆弱性レポートに表示されません。

移行を支援するため、GitLab 14.10以降では、非準拠レポートが発生すると、脆弱性レポートに[警告が表示](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)されます。

</div>

<div class="deprecation " data-milestone="15.0">

### Geo管理者UIルートを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/351345)を参照してください。

</div>

GitLab 13.0では、Geo管理者UIに新しいプロジェクトとデザインのレプリケーションの詳細ルートを導入しました。これらのルートは、`/admin/geo/replication/projects`と`/admin/geo/replication/designs`です。従来のルートを保持し、新しいルートにリダイレクトしました。GitLab 15.0では、従来のルート`/admin/geo/projects`および`/admin/geo/designs`のサポートを削除します。従来のルートを使用する可能性のあるブックマークまたはスクリプトを更新してください。

</div>

<div class="deprecation " data-milestone="15.0">

### カスタムGeo:db:* Rakeタスクを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/351945)を参照してください。

</div>

GitLab 14.8では、[`geo:db:*` Rakeタスクを、[複数のデータベースのRails 6サポートを使用するようにGeo追跡データベースを切り替えた](https://gitlab.com/groups/gitlab-org/-/epics/6458)後に可能になった組み込みタスクに置き換えます。](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/77269/diffs)次の`geo:db:*`タスクは、対応する`db:*:geo`タスクに置き換えられます。

- `geo:db:drop` -> `db:drop:geo`
- `geo:db:create` -> `db:create:geo`
- `geo:db:setup` -> `db:setup:geo`
- `geo:db:migrate` -> `db:migrate:geo`
- `geo:db:rollback` -> `db:rollback:geo`
- `geo:db:version` -> `db:version:geo`
- `geo:db:reset` -> `db:reset:geo`
- `geo:db:seed` -> `db:seed:geo`
- `geo:schema:load:geo` -> `db:schema:load:geo`
- `geo:db:schema:dump` -> `db:schema:dump:geo`
- `geo:db:migrate:up` -> `db:migrate:up:geo`
- `geo:db:migrate:down` -> `db:migrate:down:geo`
- `geo:db:migrate:redo` -> `db:migrate:redo:geo`
- `geo:db:migrate:status` -> `db:migrate:status:geo`
- `geo:db:test:prepare` -> `db:test:prepare:geo`
- `geo:db:test:load` -> `db:test:load:geo`
- `geo:db:test:purge` -> `db:test:purge:geo`

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### 機能フラグPUSH_RULES_SUPERSEDE_CODE_OWNERSを非推奨化

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/262019)を参照してください。

</div>

機能フラグ`PUSH_RULES_SUPERSEDE_CODE_OWNERS`は、GitLab 15.0で削除されます。削除すると、プッシュルールはコードオーナーよりも優先されます。コードオーナーの承認が必要な場合でも、特定のユーザーがコードをプッシュすることを明示的に許可するプッシュルールは、コードオーナー設定よりも優先されます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Elasticsearch 6.8

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/350275)を参照してください。

</div>

Elasticsearch 6.8はGitLab 14.8で非推奨となり、GitLab 15.0で削除される予定です。Elasticsearch 6.8を使用しているお客様は、GitLab 15.0にアップグレードする前に、Elasticsearchのバージョンを7.xにアップグレードする必要があります。すべてのElasticsearchの改善を活用するために、最新バージョンのElasticsearch 7を使用することをお勧めします。

Elasticsearch 6.8は、[GitLab 15.0でサポートする予定](https://gitlab.com/gitlab-org/gitlab/-/issues/327560)のAmazon OpenSearchとも互換性がありません。

</div>

<div class="deprecation " data-milestone="15.0">

### セキュリティレポートスキーマの強制検証

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/groups/gitlab-org/-/epics/6968)を参照してください。

</div>

14.0.0より前のバージョンの[セキュリティレポートスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases) は、GitLab 15.0でサポートされなくなります。レポートで宣言されているスキーマバージョンに対して検証に合格しないレポートも、GitLab 15.0でサポートされなくなります。

パイプラインジョブアーティファクトとして[セキュリティレポートを出力することによりGitLabと統合](https://docs.gitlab.com/development/integrations/secure/#report)するセキュリティツールが影響を受けます。すべての出力レポートが、最小バージョン14.0.0で正しいスキーマに準拠していることを確認する必要があります。バージョンが低いレポート、または宣言されたスキーマバージョンに対して検証に失敗したレポートは処理されず、脆弱性の検出結果は、MR、パイプライン、脆弱性レポートに表示されません。

移行を支援するため、GitLab 14.10以降では、非準拠レポートが発生すると、脆弱性レポートに[警告](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)が表示されます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### 外部ステータスチェックAPIの破壊的な変更

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

[外部ステータスチェックAPI](https://docs.gitlab.com/api/status_checks/) は、元々状態チェックに合格としてマークするために、デフォルトで合格するリクエストをサポートするために実装されました。デフォルトで合格するリクエストは現在非推奨です。具体的には、以下が非推奨です。

- `status`フィールドを含まないリクエスト。
- `status`フィールドが`approved`に設定されているリクエスト。

GitLab 15.0以降、状態チェックは、`status`フィールドが存在し、かつ`passed`に設定されている場合にのみ、合格状態に更新されます。リクエストのタイプごとの動作:

- `status`フィールドが含まれていない場合、`422`エラーで拒否されます。詳細については、[関連問題問題](https://gitlab.com/gitlab-org/gitlab/-/issues/338827)を参照してください。
- `passed`以外の値が含まれている場合、状態チェックが失敗します。詳細については、[関連問題問題](https://gitlab.com/gitlab-org/gitlab/-/issues/339039)を参照してください。

この変更に合わせて、外部状態チェックを一覧表示するAPIコールでも、合格した状態チェックに対して`approved`ではなく`passed`の値が返されるようになります。

</div>

<div class="deprecation " data-milestone="15.0">

### デーモンとして実行される GitLab Pages

<div class="deprecation-notes">

- GitLab <span class="milestone">14.9</span>で発表
- GitLab <span class="milestone">15.0</span>で削除

</div>

15.0では、GitLab Pagesのデーモンモードのサポートは削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### GitLab Serverless

<div class="deprecation-notes">

- GitLab <span class="milestone">14.3</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/groups/gitlab-org/configure/-/epics/6)を参照してください。

</div>

GitLab Serverlessは、自動デプロイとモニタリングによるKnativeベースのサーバーレス開発をサポートするための機能セットです。

GitLab Serverlessの機能は、十分なユーザーの反響が得られなかったため、削除することにしました。さらに、KubernetesとKnativeの継続的な進歩を考えると、現在の実装は最新バージョンでは動作しません。

</div>

<div class="deprecation " data-milestone="15.0">

### ライセンスコンプライアンスでのGodepのサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/327057)を参照してください。

</div>

Go用のGodep依存関係マネージャーは、2020年にGoによって非推奨とされ、Goモジュールに置き換えられました。メンテナンスコストを削減するため、Godepプロジェクトのライセンスコンプライアンスを14.7から非推奨とし、GitLab 15.0で削除します。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### GraphQL IDとGlobalIDの互換性

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/257883)を参照してください。

</div>

後方互換性のために追加した GraphQLプロセッサへの非標準の拡張機能を削除します。この拡張機能はGraphQLクエリの検証を変更し、通常は拒否される引数に`ID`タイプを使用できるようにしたものです。一部の引数は元々`ID`タイプでした。これらは、特定の種類の`ID`に変更されました。この変更は、次の場合に破壊的な変更になる可能性があります。

- GraphQLを使用する。
- クエリシグネチャの引数に`ID`タイプを使用する。

一部のフィールドの引数では、まだ`ID`タイプが使用されています。これらは通常、IID値またはネームスペースパス用です。たとえば、`Query.project(fullPath: ID!)`などがあります。

影響を受けるフィールドの引数と影響を受けないフィールドの引数のリストについては、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352832)を参照してください。

GitLabサーバーから取得したスキーマデータを使用して、クエリをローカルで検証することで、この変更による影響があるかどうかをテストできます。これを行うには、関連するGitLabインスタンスのGraphQLエクスプローラーツールを使用します。例：`https://gitlab.com/-/graphql-explorer`。

たとえば、次のクエリは、破壊的な変更を示しています。

```graphql
# a query using the deprecated type of Query.issue(id:)
# WARNING: This will not work after GitLab 15.0
query($id: ID!) {
  deprecated: issue(id: $id) {
    title, description
  }
}
```

上記のクエリは、`Query.issue(id:)`のタイプが実際には`IssueID!`であるため、GitLab 15.0のリリース後には機能しません。

代わりに、次の2つの形式のいずれかを使用する必要があります。

```graphql
# This will continue to work
query($id: IssueID!) {
  a: issue(id: $id) {
    title, description
  }
  b: issue(id: "gid://gitlab/Issue/12345") {
    title, description
  }
}
```

このクエリは現在機能し、GitLab 15.0以降も引き続き機能します。最初の形式（シグネチャで名前付きタイプとして`ID`を使用）のクエリは、他の2つの形式（シグネチャで正しい適切なタイプを使用するか、インライン引数式を使用）のいずれかに変換する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### パッケージ設定でのGraphQL権限の変更

<div class="deprecation-notes">

- GitLab <span class="milestone">14.9</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

GitLab Packageステージは、GitLabを使用してすべての依存関係を管理できるように、パッケージレジストリ、コンテナレジストリ、および依存プロキシを備えています。これらの各製品カテゴリには、APIを使用して調整できるさまざまな設定があります。

GraphQLの権限モデルが更新されます。15.0以降、ゲスト、レポーター、およびデベロッパーのロールを持つユーザーは、これらの設定を更新できなくなります。

- [パッケージレジストリ設定](https://docs.gitlab.com/api/graphql/reference/#packagesettings)
- [コンテナレジストリクリーンアップポリシー](https://docs.gitlab.com/api/graphql/reference/#containerexpirationpolicy)
- [依存プロキシの有効期限ポリシー](https://docs.gitlab.com/api/graphql/reference/#dependencyproxyimagettlgrouppolicy)
- [グループの依存プロキシの有効化](https://docs.gitlab.com/api/graphql/reference/#dependencyproxysetting)

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### GitLab Runner SSH executorに必要な既知のホスト

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28192)を参照してください。

</div>

[GitLab 14.3](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/3074)で、GitLab Runner `config.toml`ファイルに構成設定を追加しました。この設定である[`[runners.ssh.disable_strict_host_key_checking]`](https://docs.gitlab.com/runner/executors/ssh/#security)は、SSH executorで厳密なホストキーチェックを使用するかどうかを制御します。

GitLab 15.0以降、この設定オプションのデフォルト値は、`true`から`false`に変更されます。これは、GitLab Runner SSH executorを使用する場合に、厳密なホストキーチェックが適用されることを意味します。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### ライセンスコンプライアンスAPIの従来の承認状態名

<div class="deprecation-notes">

- GitLab <span class="milestone">14.6</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/335707)を参照してください。

</div>

`managed_licenses` APIでライセンスポリシーの承認状態の従来の名前（`blacklisted`、`approved`）を非推奨にしましたが、APIクエリと応答では引き続き使用されています。これらは15.0で削除されます。

ライセンスコンプライアンスAPIを使用している場合は、`approved`および`blacklisted`クエリパラメーターの使用を停止する必要があります。これらは現在、`allowed`および`denied`です。15.0では、応答で`approved`と`blacklisted`の使用も停止されるため、15.0リリースで破損しないように新旧の値を使用するようにカスタムツールを調整する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### 従来のデータベース設定

<div class="deprecation-notes">

- GitLab <span class="milestone">14.3</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/338182)を参照してください。

</div>

`database.yml`にある[GitLabデータベース](https://docs.gitlab.com/omnibus/settings/database/)設定の構文が変更され、従来の形式は非推奨になります。従来の形式は単一のPostgreSQLアダプターの使用をサポートしていましたが、新しい形式は複数のデータベースをサポートするように変更されています。`main:`データベースは、最初の設定アイテムとして定義する必要があります。

この設定はOmnibusで自動的に処理されるため、この非推奨化は主にソースからGitLabをコンパイルするユーザーに影響します。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### GitLab でのログの生成

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/346485)を参照してください。

</div>

GitLabのログ生成機能を使用すると、ユーザーはELKスタック（Elasticsearch、Logstash、およびKibana）をインストールして、アプリケーションログを集約および管理できます。ユーザーはGitLabで関連するログを検索できます。ただし、Kubernetesクラスターと GitLab Managed Appsとの証明書ベースの統合を非推奨として以来、GitLab内でのログの記録のために推奨されるソリューションはありません。詳細については、[OpstraceとGitLabのインテグレーション](https://gitlab.com/groups/gitlab-org/-/epics/6976)に関問題を参照してください。

</div>

<div class="deprecation " data-milestone="15.0">

### `custom_hooks_dir`設定をGitLab ShellからGitalyに移動

<div class="deprecation-notes">

- GitLab <span class="milestone">14.9</span>で発表
- GitLab <span class="milestone">15.0</span>で削除

</div>

[`custom_hooks_dir`](https://docs.gitlab.com/administration/server_hooks/#create-a-global-server-hook-for-all-repositories)設定はGitalyで設定されるようになり、GitLab 15.0でGitLab Shellから削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### OAuthの暗黙的付与

<div class="deprecation-notes">

- GitLab <span class="milestone">14.0</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

OAuthの暗黙的付与認証フローは、次期メジャーリリースである GitLab 15.0で削除されます。OAuthの暗黙的付与を使用するすべてのアプリケーションは、代替の[サポートされているOAuthフロー](https://docs.gitlab.com/api/oauth2/)に切り替える必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### 有効期限のないOAuthトークン

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

デフォルトでは、すべての新しいアプリケーションは2時間後にアクセストークンの有効期限が切れます。GitLab 14.2以前では、OAuthアクセストークンに有効期限はありませんでした。GitLab 15.0では、既存のトークンで有効期限がまだないものには、自動的に有効期限が生成されます。

GitLab 15.0のリリース前には、トークンの有効期限を設定するよう[オプトイン](https://docs.gitlab.com/integration/oauth_provider/#access-token-expiration)する必要があります。

1. アプリケーションを編集します。
1. **アクセストークンの有効期限を設定する**を選択して有効にします。トークンを失効させる必要があります。そうしないと、有効期限が設定されません。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### OmniAuth Kerberos gem

<div class="deprecation-notes">

- GitLab <span class="milestone">14.3</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/337384)を参照してください。

</div>

次のメジャーリリースであるGitLab 15.0で、`omniauth-kerberos` gemが削除されます。

このgemはメンテナンスされておらず、使用頻度は非常に低いです。そのため、この認証方法のサポートは削除する予定であり、代わりにKerberos [SPNEGO](https://en.wikipedia.org/wiki/SPNEGO)インテグレーションを使用することをお勧めします。[アップグレード手順](https://docs.gitlab.com/integration/kerberos/#upgrading-from-password-based-to-ticket-based-kerberos-sign-ins)に従って、`omniauth-kerberos`インテグレーションから、サポートされているインテグレーションにアップグレードできます。

Kerberos SPNEGOインテグレーションは非推奨にしていません。非推奨にするのは古いパスワードベースのKerberosインテグレーションのみです。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### PAT有効期限のオプションの適用

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/351962)を参照してください。

</div>

PAT有効期限の適用を無効にする機能は、セキュリティの観点からすると一般的ではありません。この一般的でない機能により、ユーザーにとって予期しない動作が引き起こされる可能性があることが懸念されます。セキュリティ機能での予期しない動作は本質的に危険であるため、この機能を削除することにしました。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### SSH有効期限のオプションでの適用

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/351963)を参照してください。

</div>

SSH有効期限の適用を無効にする機能は、セキュリティの観点からすると一般的ではありません。この一般的でない機能により、ユーザーにとって予期しない動作が引き起こされる可能性があることが懸念されます。セキュリティ機能での予期しない動作は本質的に危険であるため、この機能を削除することにしました。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Java 8の標準装備のSASTサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352549)を参照してください。

</div>

[GitLab SAST SpotBugsアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/spotbugs)は、[Java、Scala、Groovy、およびKotlinコード](https://docs.gitlab.com/user/application_security/sast/#supported-languages-and-frameworks)をスキャンし、セキュリティの脆弱性を確認します。技術的な理由により、アナライザーは最初にコードをコンパイルしてからスキャンする必要があります。[プリコンパイル戦略](https://docs.gitlab.com/user/application_security/sast/#pre-compilation)を使用しない限り、アナライザーはプロジェクトのコードを自動的にコンパイルしようとします。

15.0より前のGitLabバージョンでは、コンパイルを容易にするために、アナライザーイメージにJava 8およびJava 11ランタイムが含まれています。

GitLab 15.0では、次のようになります。

- イメージのサイズを小さくするために、アナライザーイメージからJava 8を削除します。
- Java 17でのコンパイルを容易にするために、アナライザーイメージにJava 17を追加します。

アナライザー環境にあるJava 8を利用している場合は、[この変更のための非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352549#breaking-change)の記載に従って対処する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### 高度な検索の移行の古いインデックス

<div class="deprecation-notes">

- GitLab <span class="milestone">14.10</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/359133)を参照してください。

</div>

高度な検索の移行では通常、長期間にわたって複数のコードパスをサポートする必要があるため、安全なクリーンアップが可能になったら、それらをクリーンアップすることが重要です。GitLabのメジャーバージョンアップグレードは、完全に移行されていないインデックスの後方互換性を削除するための安全な時期として使用します。詳細については、[アップグレードドキュメント](https://docs.gitlab.com/update/#upgrading-to-a-new-major-version)を参照してください。

</div>

<div class="deprecation " data-milestone="15.0">

### 仮名化機能

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/219952)を参照してください。

</div>

仮名化機能は一般的に使用されておらず、大規模なデータベースで本番環境の問題を引き起こしたり、オブジェクトストレージの開発を妨げたりする可能性があります。これは非推奨と見なされるようになり、GitLab 15.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `instanceStatisticsMeasurements` GraphQL ノードを介した使用状況トレンドのクエリ

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/332323)を参照してください。

</div>

`instanceStatisticsMeasurements` GraphQLノードの名前は13.10 で`usageTrendsMeasurements`に変更され、古いフィールド名は非推奨としてマークされています。既存のGraphQLクエリを修正するには、`instanceStatisticsMeasurements`を`usageTrendsMeasurements`に置き換えます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### リクエストプロファイリング

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352488)を参照してください。

</div>

[リクエストプロファイリング](https://docs.gitlab.com/administration/monitoring/performance/)はGitLab 14.8で非推奨となり、GitLab 15.0で削除される予定です。

[プロファイリングツールを統合](https://gitlab.com/groups/gitlab-org/-/epics/7327)し、より簡単にアクセスできるように取り組んでいます。この機能の使用を[評価](https://gitlab.com/gitlab-org/gitlab/-/issues/350152)したところ、広く使用されていないことがわかりました。また、この機能は、アクティブにメンテナンスされなくなった、最新バージョンのRuby用に更新されていない、または高負荷のページ読み込みのプロファイルで頻繁にクラッシュするいくつかのサードパーティ製gemに依存しています。

詳細については、[非推奨に関する問題の概要セクション](https://gitlab.com/gitlab-org/gitlab/-/issues/352488#deprecation-summary)を確認してください。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Premiumプランで必要なパイプライン設定

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

[必要なパイプライン設定](https://docs.gitlab.com/administration/settings/continuous_integration/#required-pipeline-configuration-deprecated)機能は、Premiumのお客様にはGitLab 14.8で非推奨となり、GitLab 15.0で削除される予定です。この機能は、GitLab Ultimateのお客様には非推奨ではありません。

この機能をGitLab Ultimateプランに移行する変更は、この機能に対する要求が主に経営幹部から発生していることを考慮し、機能を当社の[価格に関する考え方](https://handbook.gitlab.com/handbook/company/pricing/#three-tiers)とより良く合致させることを目的としています。

この変更は、GitLabが次の関連するUltimateプランの機能との階層化戦略において整合性を保つのにも役立ちます。[セキュリティポリシー](https://docs.gitlab.com/user/application_security/policies/)と[コンプライアンスフレームワークパイプライン](https://docs.gitlab.com/user/project/settings/#compliance-pipeline-configuration)。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Retire-JS依存関係スキャンツール

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/350510)を参照してください。

</div>

14.8の時点で、retire.jsジョブは依存関係スキャンから非推奨になっています。非推奨の間は、引き続きCI/CDテンプレートに含まれます。GitLab 15.0で2022年5月22日に、依存関係スキャンからretire.jsを削除します。JavaScriptスキャン機能は、Gemnasiumによって引き続きカバーされているため、影響を受けません。

DS_EXCLUDED_ANALYZERSを使用してretire.jsを明示的に除外した場合は、15.0でクリーンアップ（参照を削除）する必要があります。`retire-js-dependency_scanning`ジョブに関連するパイプラインの依存関係スキャンの設定をカスタマイズした場合は、15.0で削除される前にgemnasium-dependency_scanningに切り替えて、パイプラインが失敗しないようにする必要があります。retire.jsを参照するためにDS_EXCLUDED_ANALYZERSを使用していない場合、または特にretire.js用にテンプレートをカスタマイズしていない場合は、対応は不要です。

</div>

<div class="deprecation " data-milestone="15.0">

### 14.0.0より前のSASTスキーマ

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除

</div>

14.0.0より前のバージョンの[SASTレポートスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)は、GitLab 15.0ではサポートされなくなります。レポートで宣言されているスキーマバージョンに対して検証に合格しないレポートも、GitLab 15.0でサポートされなくなります。

パイプラインジョブアーティファクトとして [SASTセキュリティレポートを出力することにより、GitLabと統合](https://docs.gitlab.com/development/integrations/secure/#report)するサードパーティツールが影響を受けます。すべての出力レポートが、最小バージョン14.0.0で正しいスキーマに準拠していることを確認する必要があります。バージョンが低いレポート、または宣言されたスキーマバージョンに対して検証に失敗したレポートは処理されず、脆弱性の検出結果は、MR、パイプライン、脆弱性レポートに表示されません。

移行を支援するため、GitLab 14.10以降では、非準拠レポートが発生すると、脆弱性レポートに[警告](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)が表示されます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### .NET 2.1用のSASTサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352553)を参照してください。

</div>

GitLab SASTセキュリティコードスキャンアナライザーは、.NETコードをスキャンして、セキュリティの脆弱性を確認します。技術的な理由により、アナライザーは最初にコードをビルドしてスキャンする必要があります。

15.0より前のGitLabバージョンでは、デフォルトのアナライザーイメージ（バージョン2）には、次のサポートが含まれています。

- .NET 2.1
- .NET 3.0および.NET Core 3.0
- .NET Core 3.1
- .NET 5.0

GitLab 15.0では、このアナライザーのデフォルトのメジャーバージョンをバージョン2からバージョン3に変更します。この変更の内容は次のとおりです。

- [脆弱性の重大度値](https://gitlab.com/gitlab-org/gitlab/-/issues/350408)と[その他の新機能と改善](https://gitlab.com/gitlab-org/security-products/analyzers/security-code-scan/-/blob/master/CHANGELOG.md)を追加します。
- .NET 2.1のサポートを削除します。
- .NET 6.0、Visual Studio 2019、およびVisual Studio 2022のサポートを追加します。

バージョン3は[GitLab 14.6で発表](https://about.gitlab.com/releases/2021/12/22/gitlab-14-6-released/#sast-support-for-net-6)され、オプションのアップグレードとして利用できるようになりました。

デフォルトでアナライザーイメージにある.NET 2.1のサポートを利用している場合は、[この変更のための非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352553#breaking-change)の記載に従って対処する必要があります。

</div>

<div class="deprecation " data-milestone="15.0">

### 非推奨のシークレット検出設定変数

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352565)を参照してください。

</div>

[GitLabシークレット検出のカスタマイズ](https://docs.gitlab.com/user/application_security/secret_detection/#customizing-settings)をより簡単かつ信頼性の高いものにするために、以前にCI/CD設定で設定できた変数の一部を非推奨にします。

次の変数は現在、履歴スキャンのオプションをカスタマイズできますが、[GitLab管理のCI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/Secret-Detection.gitlab-ci.yml)との連携が不十分であり、現在は非推奨です。

- `SECRET_DETECTION_COMMIT_FROM`
- `SECRET_DETECTION_COMMIT_TO`
- `SECRET_DETECTION_COMMITS`
- `SECRET_DETECTION_COMMITS_FILE`

`SECRET_DETECTION_ENTROPY_LEVEL`は以前は、コードベース内の文字列の無秩序化レベルのみを考慮するルールを設定できましたが、現在は非推奨となっています。このタイプの無秩序化のみのルールは、許容できない数の不正確な結果（誤検出）を作成していて、サポートされなくなりました。

GitLab 15.0では、シークレット検出[アナライザー](https://docs.gitlab.com/user/application_security/terminology/#analyzer)を更新して、これらの非推奨のオプションを無視します。[`SECRET_DETECTION_HISTORIC_SCAN` CI/CD変数](https://docs.gitlab.com/user/application_security/secret_detection/#available-cicd-variables)を設定して、コミット履歴の履歴スキャンを設定することもできます。

詳細については、[この変更のための非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352565)を参照してください。

</div>

<div class="deprecation " data-milestone="15.0">

### 14.0.0より前のシークレット検出スキーマ

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除

</div>

14.0.0より前のバージョンの[シークレット検出レポートスキーマ](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/releases)は、GitLab 15.0ではサポートされなくなります。レポートで宣言されているスキーマバージョンに対して検証に合格しないレポートも、GitLab 15.0でサポートされなくなります。

パイプラインジョブアーティファクトとして [シークレット検出セキュリティレポートを出力することにより、GitLabと統合](https://docs.gitlab.com/development/integrations/secure/#report)するサードパーティツールが影響を受けます。すべての出力レポートが、最小バージョン14.0.0で正しいスキーマに準拠していることを確認する必要があります。バージョンが低いレポート、または宣言されたスキーマバージョンに対して検証に失敗したレポートは処理されず、脆弱性の検出結果は、MR、パイプライン、脆弱性レポートに表示されません。

移行を支援するため、GitLab 14.10以降では、非準拠レポートが発生すると、脆弱性レポートに[警告](https://gitlab.com/gitlab-org/gitlab/-/issues/335789#note_672853791)が表示されます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### 新しい場所で公開されたSecureおよびProtectアナライザーのイメージ

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352564)を参照してください。

</div>

GitLabは、さまざまな[アナライザー](https://docs.gitlab.com/user/application_security/terminology/#analyzer)を使用して[セキュリティの脆弱性をスキャン](https://docs.gitlab.com/user/application_security/)します。各アナライザーはコンテナイメージとして配布されます。

GitLab 14.8以降、GitLab SecureおよびProtectアナライザーの新しいバージョンは、`registry.gitlab.com/security-products`の下の新しいレジストリの場所に公開されます。

この変更を反映するために、[GitLab管理のCI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Security)のデフォルト値を更新します。

- コンテナスキャンを除くすべてのアナライザーについて、変数`SECURE_ANALYZERS_PREFIX`を新しいイメージレジストリの場所に更新します。
- コンテナスキャンの場合、デフォルトのイメージアドレスは既に更新されています。コンテナスキャンには`SECURE_ANALYZERS_PREFIX`変数はありません。

将来のリリースでは、`registry.gitlab.com/gitlab-org/security-products/analyzers`へのイメージの公開を停止します。イメージの公開が停止されたら、手動でイメージをプルして別のレジストリにプッシュする場合は、対応する必要があります。この状況は、[オフラインデプロイ](https://docs.gitlab.com/user/application_security/offline_deployments/)の場合によくあります。対応しないと、それ以上の更新は受信されません。

詳細については、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352564)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### SecureおよびProtectアナライザーのメジャーバージョン更新

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/350936)を参照してください。

</div>

SecureおよびProtectのステージでは、GitLab 15.0リリースと連携して、アナライザーのメジャーバージョンが引き上げられます。このメジャーバージョンの引き上げにより、以下のアナライザーの明確な区別が可能になります。

- 2022年5月22日より前にリリースされたもの。これらのレポートは、厳格なスキーマ検証の対象_ではありません_。
- 2022年5月22日より後にリリースされたもの。これらのレポートは、厳格なスキーマ検証の対象_です_。

デフォルトの内蔵テンプレートを使用していない場合、またはアナライザーのバージョンを固定している場合は、固定されたバージョンを削除するか、CI/CDジョブ定義を更新して、最新のメジャーバージョンに更新する必要があります。GitLab 12.0 - 14.10のユーザーは、GitLab 15.0のリリースまで通常どおりアナライザーの更新を引き続き利用できます。その後、[メンテナンスポリシー](https://docs.gitlab.com/policy/maintenance/)に従ってバグや新機能のバックポートを行わないため、アナライザーの新しいメジャーバージョンで新たに修正されたバグや新しくリリースされた機能は、非推奨バージョンでは利用できなくなります。必要なセキュリティパッチは、最新の3つのマイナーリリース内でバックポートされるためです。具体的には、次の点は非推奨となっており、15.0 GitLabリリース以降は更新されません。

- APIセキュリティ: バージョン1
- コンテナスキャン: バージョン4
- カバレッジファジング: バージョン2
- 依存関係スキャン: バージョン2
- 動的アプリケーションセキュリティテスト（DAST）: バージョン2
- Infrastructure as Code（IaC）スキャン: バージョン1
- ライセンススキャン: バージョン3
- シークレット検出: バージョン3
- 静的アプリケーションセキュリティテスト（SAST）: [すべてのアナライザー](https://docs.gitlab.com/user/application_security/sast/#supported-languages-and-frameworks)のバージョン2（ただし、現在はバージョン3の`gosec`を除く）
  - `bandit`: バージョン2
  - `brakeman`: バージョン2
  - `eslint`: バージョン2
  - `flawfinder`: バージョン2
  - `gosec`: バージョン3
  - `kubesec`: バージョン2
  - `mobsf`: バージョン2
  - `nodejs-scan`: バージョン2
  - `phpcs-security-audit`: バージョン2
  - `pmd-apex`: バージョン2
  - `security-code-scan`: バージョン2
  - `semgrep`: バージョン2
  - `sobelow`: バージョン2
  - `spotbugs`: バージョン2

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Sidekiqメトリクスとヘルスチェックの設定

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/347509)を参照してください。

</div>

単一のプロセスとポートを使用してSidekiqメトリクスとヘルスチェックをエクスポートすることは非推奨になります。15.0でサポートが削除されます。

安定性と可用性を向上させ、エッジケースでのデータ損失を防ぐために、[2つの個別のプロセスからメトリクスとヘルスチェックをエクスポート](https://gitlab.com/groups/gitlab-org/-/epics/6409)するようにSidekiqを更新しました。これらは2つの個別のサーバーであるため、15.0では、メトリクスとヘルスチェックに個別のポートを明示的に設定するために設定変更が必要になります。`sidekiq['health_checks_*']`用に新しく導入された設定は、常に`gitlab.rb`で設定する必要があります。詳細については、[Sidekiqの設定](https://docs.gitlab.com/administration/sidekiq/)に関するドキュメントを確認してください。

これらの変更では、新しいエンドポイントをスクレイプするためのPrometheus、または新しいヘルスチェックポートをターゲットとして正常に機能させるためのk8sヘルスチェックのいずれかのアップデートも必要です。そうしないと、メトリクスまたはヘルスチェックが表示されなくなります。

非推奨期間中、これらの設定はオプションであり、GitLabはSidekiqヘルスチェックポートを`sidekiq_exporter`と同じポートにデフォルト設定し、1つのサーバーのみを実行します（現在の動作は変更されません）。両方が設定され、異なるポートが提供されている場合にのみ、個別のメトリクスサーバーが起動してSidekiqメトリクスを提供します。これは、15.0でのSidekiqの動作と同様です。

</div>

<div class="deprecation " data-milestone="15.0">

### 静的サイトエディタ

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/347137)を参照してください。

</div>

静的サイトエディタは、GitLab 15.0以降は利用できなくなります。GitLab全体のMarkdown編集のエクスペリエンスの改善でも同様のメリットが得られますが、より幅広い範囲で利用できます。静的サイトエディタへの受信リクエストは、[Web IDE](https://docs.gitlab.com/user/project/web_ide/)にリダイレクトされます。

静的サイトエディタの現在のユーザーは、既存のプロジェクトから設定ファイルを削除する方法などの詳細について、[ドキュメント](https://docs.gitlab.com/user/project/web_ide/)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### SLES 12 SP2のサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

SUSE Linux Enterprise Server（SLES）12 SP2の長期サービスとサポート（LTSS）は、[2021年3月31日に終了しました](https://www.suse.com/lifecycle/)。SP2のCA証明書には、期限切れのDSTルート証明書が含まれており、新しいCA証明書パッケージの更新は取得されていません。いくつかの[回避策](https://gitlab.com/gitlab-org/gitlab-omnibus-builder/-/merge_requests/191)を実装しましたが、ビルドを正常に実行し続けることはできません。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### Gitalyと残りのGitLabの間にデプロイされたgRPC対応プロキシのサポート

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

推奨もドキュメント化もされていませんが、Gitalyと残りのGitLabの間にgRPC対応プロキシをデプロイすることができました。たとえば、NGINXやEnvoyなどです。gRPC対応プロキシをデプロイする機能は[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/352517)です。現在、Gitaly接続にgRPC対応プロキシを使用している場合は、TCPまたはTLSプロキシ（OSIレイヤ4）を使用するようにプロキシ設定を変更する必要があります。

Gitaly Clusterは、GitLab 13.12でgRPC対応プロキシとの互換性がなくなりました。Gitaly Clusterを使用していない場合でも、すべてのGitLabインストールはgRPC対応プロキシと互換性がなくなります。

一部の内部RPCトラフィックを（gRPCではなく）カスタムプロトコルで送信することで、スループットが向上し、Goガベージコレクションのレイテンシーが短縮されます。詳細については、[関連するエピック](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/463)を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### テストカバレッジプロジェクトのCI/CD設定

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

テストカバレッジパターンを簡単に設定するために、GitLab 15.0では、[テストカバレッジ解析用のプロジェクト設定](https://docs.gitlab.com/ci/pipelines/settings/#add-test-coverage-results-using-project-settings-removed)が削除されます。

代わりに、プロジェクトの`.gitlab-ci.yml`を使用して、`coverage`キーワードで正規表現を指定して、マージリクエストでテストカバレッジ結果を設定します。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### GitLabのトレーシング

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/346540)を参照してください。

</div>

GitLabのトレーシングは、オープンソースのエンドツーエンド分散トレーシングシステムであるJaegerとのインテグレーションです。GitLabユーザーはJaegerインスタンスにアクセスして、デプロイされたアプリケーションのパフォーマンスに関するインサイトを得て、特定のリクエストを処理する各関数またはマイクロサービスを追跡できます。GitLabのトレーシングはGitLab 14.7で非推奨となり、15.0で削除される予定です。可能な代替手段での作業を追跡するには、[OpstraceとGitLabのインテグレーション](https://gitlab.com/groups/gitlab-org/-/epics/6976)に関する問題を参照してください。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### コンテナレジストリグループレベルAPIの更新

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/336912)を参照してください。

</div>

マイルストーン15.0では、`tags`および`tags_count`パラメーターのサポートが、[グループからレジストリリポジトリを取得](https://docs.gitlab.com/api/container_registry/#within-a-group)するコンテナレジストリAPIから削除されます。

`GET /groups/:id/registry/repositories`エンドポイントは残りますが、タグに関する情報は返されません。タグに関する情報を取得するには、既存の`GET /registry/repositories/:id`エンドポイントを使用できます。このエンドポイントは、現在と同様に`tags`および`tag_count`オプションを引き続きサポートします。後者は、イメージリポジトリごとに1回呼び出す必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### バリューストリーム分析のフィルタリング計算の変更

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/343210)を参照してください。

</div>

バリューストリーム分析での日付フィルターの動作を変更します。イシューまたはマージリクエストが作成された時刻でフィルタリングする代わりに、日付フィルターは指定されたステージの終了イベント時刻でフィルタリングします。これにより、この変更がロールアウトされた後では、数値が完全に異なるものになります。

バリューストリーム分析のメトリクスを監視し、日付フィルターを利用している場合は、データが失われないように、この変更の前にデータを保存する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### 脆弱性チェック

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

脆弱性チェック機能はGitLab 14.8で非推奨となり、GitLab 15.0で削除される予定です。代わりに、新しいセキュリティ承認機能に移行することをお勧めします。これを行うには、**セキュリティとコンプライアンス>ポリシー**に移動して、新しいスキャン結果ポリシーを作成します。

新しいセキュリティ承認機能は、脆弱性チェックに似ています。たとえば、どちらもセキュリティの脆弱性を含むMRの承認を要求できます。ただし、セキュリティ承認機能は、以前のエクスペリエンスを次のような点で改善します。

- セキュリティ承認ルールを編集できるユーザーをユーザーが選択できます。そのため、独立したセキュリティまたはコンプライアンスチームは、開発プロジェクトのメンテナーによるルール変更ができないようにルールを管理できます。
- 複数のルールを作成してチェーン化し、スキャナーの種類ごとに異なる重大度しきい値でフィルタリングできるようにすることができます。
- セキュリティ承認ルールに対する望ましい変更について、2段階の承認プロセスを適用できます。
- 単一の中央集中型ルールセットのメンテナンスを容易にするために、単一のセキュリティポリシーセットを複数の開発プロジェクトに適用できます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### 基本の`PackageType`の`Versions`

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/327453)を参照してください。

</div>

[パッケージレジストリ GraphQL API](https://gitlab.com/groups/gitlab-org/-/epics/6318)を作成する作業の一環として、パッケージグループは基本の`PackageType`型の`Version`型を非推奨とし、[`PackageDetailsType`](https://docs.gitlab.com/api/graphql/reference/#packagedetailstype)に移行しました。

マイルストーン15.0では、`PackageType`から`Version`を完全に削除します。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `apiFuzzingCiConfigurationCreate` GraphQL変異

<div class="deprecation-notes">

- GitLab <span class="milestone">14.6</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/333233)を参照してください。

</div>

APIファジング設定スニペットはクライアント側で生成されるようになり、APIリクエストは不要になりました。したがって、GitLabで使用されなくなる`apiFuzzingCiConfigurationCreate`変異は非推奨になります。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `artifacts:reports:cobertura`キーワード

<div class="deprecation-notes">

- GitLab <span class="milestone">14.7</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/348980)を参照してください。

</div>

現在、GitLabのテストカバレッジの可視化では、Coberturaレポートのみがサポートされています。15.0以降、`artifacts:reports:cobertura`キーワードは[`artifacts:reports:coverage_report`](https://gitlab.com/gitlab-org/gitlab/-/issues/344533)に置き換えられます。Coberturaは15.0でサポートされる唯一のレポートファイルになりますが、これはGitLabが他のレポートタイプをサポートするための最初のステップです。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `defaultMergeCommitMessageWithDescription` GraphQL APIフィールド

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/345451)を参照してください。

</div>

GraphQL APIフィールド`defaultMergeCommitMessageWithDescription`は非推奨となっていて、GitLab 15.0で削除されます。コミットメッセージテンプレートが設定されたプロジェクトの場合、テンプレートは無視されます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `dependency_proxy_for_private_groups`機能フラグ

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/276777)を参照してください。

</div>

[GitLab-#11582](https://gitlab.com/gitlab-org/gitlab/-/issues/11582)によってパブリックグループが依存プロキシを使用する方法が変更されたため、機能フラグを追加しました。この変更前は、認証なしで依存プロキシを使用できました。この変更により、依存プロキシを使用するには認証が必要になります。

マイルストーン15.0では、機能フラグを完全に削除します。今後は、依存プロキシを使用する際に認証する必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### コンテナレジストリの`htpasswd`認証

<div class="deprecation-notes">

- GitLab <span class="milestone">14.9</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

コンテナレジストリは、`htpasswd`での[認証](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#auth)をサポートしています。これは、`bcrypt`を使用してハッシュされたパスワードを含む、[Apache `htpasswd`ファイル](https://httpd.apache.org/docs/2.4/programs/htpasswd.html)に依存しています。

GitLab（製品）のコンテキストで使用されないため、`htpasswd`認証はGitLab 14.9で非推奨となり、GitLab 15.0で削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `version`フィールドの`pipelines`フィールド

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/342882)を参照してください。

</div>

GraphQLには、パッケージバージョンのパイプラインを取得するために[`PackageDetailsType`](https://docs.gitlab.com/api/graphql/reference/#packagedetailstype)で使用できる2つの`pipelines`フィールドがあります。

- `versions`フィールドの`pipelines`フィールド。これにより、パッケージのすべてのバージョンに関連付けられたすべてのパイプラインが返されます。これにより、メモリ内で無制限の数のオブジェクトがプルされ、パフォーマンス上の懸念が生じる可能性があります。
- 特定の`version`の`pipelines`フィールド。これにより、その単一のパッケージバージョンに関連付けられたパイプラインのみが返されます。

考えられるパフォーマンスの問題を軽減するために、マイルストーン15.0で`versions`フィールドの`pipelines`フィールドを削除します。パッケージのすべてのバージョンのすべてのパイプラインを取得できなくなりますが、そのバージョンの残りの`pipelines`フィールドを使用して、単一のバージョンのパイプラインを取得できます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `PipelineSecurityReportFinding` GraphQLの`projectFingerprint`

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

[`PipelineSecurityReportFinding`](https://docs.gitlab.com/api/graphql/reference/#pipelinesecurityreportfinding) GraphQLオブジェクトの`projectFingerprint`フィールドは非推奨になります。このフィールドには、一意性を判断するために使用されるセキュリティ検出の「フィンガープリント」が含まれています。フィンガープリントを計算する方法が変更され、異なる値が生成されています。今後は、新しい値がUUIDフィールドに公開されます。`projectFingerprint`フィールドで以前に利用可能だったデータは、最終的に完全に削除されます。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `gitlab-ctl`からの`promote-db`コマンド

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/345207)を参照してください。

</div>

GitLab 14.5で、フェイルオーバー時にGeoセカンダリノードをプライマリにプロモートするコマンド`gitlab-ctl promote`を導入しました。このコマンドは、マルチノードGeoセカンダリサイトでデータベースノードをプロモートするために使用される`gitlab-ctl promote-db`を置き換えます。`gitlab-ctl promote-db`は引き続きそのまま機能し、GitLab 15.0まで使用できます。Geoをご利用のお客様は、ステージング環境で新しい`gitlab-ctl promote`コマンドのテストを開始し、フェイルオーバー手順に新しいコマンドを組み込むことをお勧めします。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### `gitlab-ctl`からの`promote-to-primary-node`コマンド

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/345207)を参照してください。

</div>

GitLab 14.5で、フェイルオーバー時にGeoセカンダリノードをプライマリにプロモートするコマンド`gitlab-ctl promote`を導入しました。このコマンドは、シングルノードGeoサイトでのみ使用可能だった`gitlab-ctl promote-to-primary-node`を置き換えます。`gitlab-ctl promote-to-primary-node`は引き続きそのまま機能し、GitLab 15.0まで使用できます。Geoをご利用のお客様は、ステージング環境で新しい`gitlab-ctl promote`コマンドのテストを開始し、フェイルオーバー手順に新しいコマンドを組み込むことをお勧めします。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### CI/CD設定の`type`および`types`キーワード

<div class="deprecation-notes">

- GitLab <span class="milestone">14.6</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

GitLab 15.0では、`type`および`types` CI/CDキーワードが削除されます。これらのキーワードを使用するパイプラインは動作を停止するため、同じ動作をする`stage`および`stages`に切り替える必要があります。

</div>

<div class="deprecation breaking-change" data-milestone="15.0">

### bundler-audit依存関係スキャンツール

<div class="deprecation-notes">

- GitLab <span class="milestone">14.6</span>で発表
- GitLab <span class="milestone">15.0</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/289832)を参照してください。

</div>

14.6の時点で、bundler-auditは依存関係スキャンから非推奨になっています。非推奨の間は、引き続きCI/CDテンプレートに存在します。bundler-auditは、2022年5月22日に15.0で依存関係スキャンから削除します。この削除後も、Rubyスキャン機能はGemnasiumによって引き続きカバーされているため、影響を受けません。

DS_EXCLUDED_ANALYZERSを使用してbundler-auditを明示的に除外した場合は、15.0でクリーンアップ（参照を削除）する必要があります。パイプラインの依存関係スキャンの設定（たとえば、`bundler-audit-dependency_scanning`ジョブを編集するなど）をカスタマイズした場合は、パイプラインが失敗しないように、15.0で削除される前にgemnasium-dependency_scanningに切り替えることができます。DS_EXCLUDED_ANALYZERSを使用してbundler-auditを参照したり、テンプレートを特にbundler-audit用にカスタマイズしたりしていない場合は、措置を講じる必要はありません。

</div>
</div>

<div class="milestone-wrapper" data-milestone="14.10">

## GitLab 14.10

<div class="deprecation breaking-change" data-milestone="14.10">

### Composer依存関係をダウンロードするための権限の変更

<div class="deprecation-notes">

- GitLab <span class="milestone">14.9</span>で発表
- GitLab <span class="milestone">14.10</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）

</div>

GitLab Composerリポジトリを使用して、PHP依存関係のプッシュ、検索、そのメタデータのフェッチ、ダウンロードができます。これらのすべてのアクションには認証が必要ですが、依存関係のダウンロードは例外です。

認証なしでComposer依存関係をダウンロードすることはGitLab 14.9で非推奨となり、GitLab 15.0で削除されます。GitLab 15.0以降では、Composer依存関係をダウンロードするには認証が必要となります。

</div>
</div>

<div class="milestone-wrapper" data-milestone="14.9">

## GitLab 14.9

<div class="deprecation " data-milestone="14.9">

### 設定可能なGitaly `per_repository`選択戦略

<div class="deprecation-notes">

- GitLab <span class="milestone">14.8</span>で発表
- GitLab <span class="milestone">14.9</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/352612)を参照してください。

</div>

`per_repository` Gitaly選択戦略の設定は[非推奨](https://gitlab.com/gitlab-org/gitlab/-/issues/352612)です。`per_repository`はGitLab 14.0以降、唯一のオプションです。

この変更は、コードベースをクリーンに保つための定期的なメンテナンスの一部です。

</div>

<div class="deprecation breaking-change" data-milestone="14.9">

### 統合されたエラー追跡はデフォルトで無効

<div class="deprecation-notes">

- GitLab <span class="milestone">14.9</span>で発表
- GitLab <span class="milestone">14.9</span>で削除（[破壊的な変更](https://docs.gitlab.com/update/terminology/#breaking-change)）
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/gitlab/-/issues/353639)を参照してください。

</div>

GitLab 14.4で、GitLabはSentryの代替となる統合されたエラー追跡バックエンドをリリースしました。この機能により、データベースのパフォーマンスの問題が発生しました。GitLab 14.9では、統合されたエラー追跡がGitLab.comから削除され、GitLab Self-Managedでデフォルトでオフになりました。この機能の今後の開発を検討している間は、[プロジェクト設定でエラー追跡をSentryに変更](https://docs.gitlab.com/operations/error_tracking/#sentry-error-tracking)して、Sentryバックエンドに切り替えることを検討してください。

この削除に関する追加の背景については、[統合されたエラー追跡をデフォルトで無効化](https://gitlab.com/groups/gitlab-org/-/epics/7580)を参照してください。フィードバックがある場合は、[フィードバック: 統合されたエラー追跡の削除](https://gitlab.com/gitlab-org/gitlab/-/issues/355493)にコメントを追加してください。

</div>
</div>

<div class="milestone-wrapper" data-milestone="14.8">

## GitLab 14.8

<div class="deprecation " data-milestone="14.8">

### openSUSE Leap 15.2パッケージ

<div class="deprecation-notes">

- GitLab <span class="milestone">14.5</span>で発表
- GitLab <span class="milestone">14.8</span>で削除
- この変更について議論したり、詳細を確認したりするには、[非推奨に関する問題](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6427)を参照してください。

</div>

openSUSE Leap 15.2のディストリビューションサポートとセキュリティ更新は[2021年12月に終了](https://en.opensuse.org/Lifetime#openSUSE_Leap)します。

14.5以降、openSUSE Leap 15.3のパッケージを提供しており、14.8 マイルストーンでopenSUSE Leap 15.2のパッケージの提供を停止します。

</div>
</div>

<div class="milestone-wrapper" data-milestone="14.6">

## GitLab 14.6

<div class="deprecation " data-milestone="14.6">

### Release CLIを汎用パッケージとして配布

<div class="deprecation-notes">

- GitLab <span class="milestone">14.2</span>で発表
- GitLab <span class="milestone">14.6</span>で削除

</div>

[release-cli](https://gitlab.com/gitlab-org/release-cli)は、GitLab 14.2以降、[汎用パッケージ](https://gitlab.com/gitlab-org/release-cli/-/packages)としてリリースされます。GitLab 14.5までは引き続きバイナリとしてS3にデプロイし、GitLab 14.6でS3での配布を停止します。

</div>
</div>

<div class="milestone-wrapper" data-milestone="14.5">

## GitLab 14.5

<div class="deprecation " data-milestone="14.5">

### Task Runnerポッドの名前をToolboxに変更

<div class="deprecation-notes">

- GitLab <span class="milestone">14.2</span>で発表
- <span class="milestone">GitLab 14.5</span>で削除

</div>

Task Runnerポッドは、GitLabアプリケーション内で定期的なハウスキーピングタスクを実行するために使用され、GitLab Runnerと混同されることがよくあります。したがって、[Task Runnerは名前がToolboxに変更されます](https://gitlab.com/groups/gitlab-org/charts/-/epics/25)。

これにより、サブチャートの名前が`gitlab/task-runner`から`gitlab/toolbox`に変更されます。結果として得られるポッドには、`{{ .Release.Name }}-toolbox`のような名前が付けられます。これは多くの場合、`gitlab-toolbox`になります。それらは、`app=toolbox`のラベルで特定できます。

</div>
</div>

{{< alert type="disclaimer" />}}
