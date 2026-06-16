---
stage: Release Notes
group: Monthly Release
date: 2024-12-19
title: "GitLab 17.7リリースノート"
description: "GitLab 17.7に新しいプランナーユーザーロールが搭載されました。"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024年12月19日に、GitLab 17.7が次の機能を搭載してリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Vedant Jain {#this-months-notable-contributor-vedant-jain}

誰もがGitLabコミュニティのコントリビューターを[推薦](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)できます！活躍中の候補者を支援するか、新しい推薦を追加してください！ 🙌

Vedantは、貢献への積極的なアプローチ、提供へのコミットメント、コラボレーションスキルで知られる、傑出したコミュニティコントリビューターです。彼はフィードバックを受け入れ、それを自身の仕事に組み込み、必要に応じて支援を求めることに優れており、彼のコントリビューションが完了するだけでなく、GitLabの基準も満たすことを保証しています。

彼のコントリビューションには、[作業アイテム属性を単一のリスト/ボードに抽象化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172191) 、[作業アイテムのメタデータの順序付け](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173033) 、および[作業アイテムウィジェットの折りたたまれた状態を記憶](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171228)によるプロジェクト管理プロセスの合理化が含まれます。Vedantは、UI内のドキュメントへのリンク（[1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170633) 、[2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170534)）も修正し、製品全体のUXを向上させる重要な取り組みの一環としてテクニカルライティングチームを支援しました。

[Amanda Rueda](https://gitlab.com/amandarueda)、シニアGitLabの製品計画担当プロダクトマネージャーは、Vedantを指名し、彼の積極的でコミュニティ志向のマインドセットを強調しました。「Vedantの取り組みは、ユーザーのニーズに対応するだけでなく、彼のコントリビューションを通じて、より安定した信頼性の高いGitLab環境を共同で作成しています。バグの修正、ユーザービリティの向上、およびメンテナンスの取り組みにコントリビューションすることで、彼は製品全体の品質向上に不可欠な役割を果たしました。彼の積極的なアプローチとグループ横断的なコントリビューションは、GitLabのイテレーション、顧客とのコラボレーション、継続的な改善というコアバリューを体現しており、コミュニティにおける傑出したコントリビューターとなっています。」

「私のコントリビューションを達成するのを助けてくれたすべての人に感謝します」とVedantは述べています。「良い影響を与えることができ、さらに多くのコントリビューションを楽しみにしています。」

Vedantは、モダンなデータチーム向けのアクティブなメタデータプラットフォームであるAtlanのフロントエンドエンジニアであり、Google Summer of Code 2024のメンターでもあります。

Vedantのすべてのコントリビューションと、GitLabにコントリビューションしてくださるすべてのオープンソースコミュニティに深く感謝いたします！

## 主要な機能 {#primary-features}

### 新しいプランナーユーザーロール {#new-planner-user-role}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/permissions.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/482733)

{{< /details >}}

新しいプランナーロールを導入し、エピック、ロードマップ、Kanbanボードなどのアジャイルプランニングツールへのカスタマイズされたアクセスを、過剰なプロビジョニングなしで提供します。[権限](../../user/permissions.md)。この変更により、ワークフローを安全に保ち、最小権限の原則に沿ったものにしながら、より効果的にコラボレーションできるようになります。

### インスタンス管理者は、どのインテグレーションを有効にできるかを制御できます {#instance-administrators-can-control-which-integrations-can-be-enabled}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../administration/settings/project_integration_management.md#integration-allowlist) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/500610)

{{< /details >}}

インスタンス管理者は、GitLabインスタンスでどのインテグレーションを有効にできるかを制御する許可リストを設定できるようになりました。空の許可リストが設定されている場合、そのインスタンスではインテグレーションは許可されません。許可リストが設定された後、新しいGitLabインテグレーションはデフォルトでは許可リストに含まれません。

以前に有効になっていたインテグレーションで、後で許可リスト設定によってブロックされたものは無効になります。これらのインテグレーションが再び許可された場合、既存の設定で再有効化されます。

### ダイレクト転送で利用できる新しいユーザーコントリビューションとメンバーシップのマッピング {#new-user-contribution-and-membership-mapping-available-in-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/import/direct_transfer_migrations.md) | [関連エピック](https://gitlab.com/gitlab-org/gitlab/-/issues/478054)

{{< /details >}}

ユーザーのコントリビューションとメンバーシップのマッピングの新しいメソッドが、GitLabインスタンス間で[直接転送](../../user/group/import/_index.md)によって移行する際に利用できるようになりました。この機能は、インポートプロセスを管理するユーザーと、コントリビューションの再割り当てを受け取るユーザーの両方に、柔軟性と制御を提供します。新しい方法では、次のことができます:

- インポートが完了した後、既存のユーザーにメンバーシップとコントリビューションを宛先インスタンスで再割り当てします。インポートしたすべてのメンバーシップとコントリビューションは、最初にプレースホルダーユーザーにマップされます。すべてのコントリビューションは、宛先インスタンスで再割り当てするまで、プレースホルダーに関連付けられたまま表示されます。
- 送信元と宛先のインスタンスで異なるメールアドレスを持つユーザーのメンバーシップとコントリビューションをマップします。

宛先インスタンスでユーザーにコントリビューションを再割り当てすると、ユーザーは再割り当てを承諾または拒否できます。

詳細については、[ユーザーコントリビューションとメンバーシップのマッピングによる移行の合理化](https://about.gitlab.com/blog/streamline-migrations-with-user-contribution-and-membership-mapping/)を参照してください。フィードバックを残すには、[イシュー502565](https://gitlab.com/gitlab-org/gitlab/-/issues/502565)にコメントを追加してください。

### 後続のスキャンで検出されなかった脆弱性を自動的に解決する {#auto-resolve-vulnerabilities-when-not-found-in-subsequent-scans}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/vulnerability_management_policy.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/5708)

{{< /details >}}

GitLabの[セキュリティスキャナー](../../user/application_security/_index.md)は、アプリケーションコード内の既知の脆弱性や潜在的な弱点を特定するのに役立ちます。フィーチャーブランチをスキャンすることで、新しい弱点や脆弱性が表面化し、マージする前に修正することができます。プロジェクトのデフォルトブランチにすでに存在する脆弱性の場合、これらをフィーチャーブランチで修正すると、次のデフォルトブランチスキャンが実行されたときに、その脆弱性は検出されなくなったものとしてマークされます。どの脆弱性が検出されなくなったかを知ることは有益ですが、それらを閉じるには、それぞれを手動で解決済みとしてマークする必要があります。新しい[アクティビティフィルター](../../user/application_security/vulnerability_report/_index.md#activity-filter)や[ステータスの一括変更](../../user/application_security/vulnerability_report/_index.md#change-status-of-vulnerabilities)を使用する場合でも、解決するべきものが多数ある場合、これは時間がかかる可能性があります。

私たちは、自動スキャンによって検出されなくなった脆弱性が自動的に解決済みに設定されることを望むユーザー向けに、新しいポリシータイプである*脆弱性管理ポリシー*を導入しています。新しいAuto-resolveオプションを使用して新しいポリシーを構成し、適切なプロジェクトに適用するだけです。特定の重大度の脆弱性のみ、または特定のセキュリティスキャナーからの脆弱性のみを自動解決するようにポリシーを構成することもできます。設定されると、次にプロジェクトのデフォルトブランチがスキャンされたときに、検出されなくなった既存の脆弱性は解決済みとしてマークされます。このアクションは、アクティビティノート、アクションが発生したタイムスタンプ、および脆弱性が削除されたと判断されたパイプラインで、脆弱性レコードを更新します。

### パーソナルアクセストークン、プロジェクトアクセストークン、およびグループアクセストークンをUIでローテーションする {#rotate-personal-project-and-group-access-tokens-in-the-ui}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/personal_access_tokens.md#rotate-a-personal-access-token) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/241523)

{{< /details >}}

これで、UIを使用してパーソナルアクセストークン、プロジェクトアクセストークン、およびグループアクセストークンをローテーションできるようになりました。以前は、これを行うにはAPIを使用する必要がありました。

ありがとうございました[shangsuru](https://gitlab.com/shangsuru)さんのコントリビューションに感謝します！

### プロジェクト全体のCI/CDコンポーネント使用状況を追跡する {#track-cicd-component-usage-across-projects}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#cicatalogresourcecomponentusage) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/466575)

{{< /details >}}

中央のDevOpsチームは、CI/CDコンポーネントがパイプライン全体でどこで使用されているかを追跡する必要があることが多く、それらをより適切に管理および最適化するためです。表示レベルがないと、古くなったコンポーネントの使用状況を特定したり、採用率を理解したり、コンポーネントのライフサイクルをサポートしたりすることが困難です。

これに対処するため、組織のパイプライン全体でコンポーネントが使用されているプロジェクトのリストをDevOpsチームが確認できる新しいGraphQLのクエリを追加しました。この機能により、DevOpsチームは重要なインサイトを得ることで、生産性を向上させ、より良い意思決定を行うことができます。

### すべてのティアで利用可能なLinux Arm上の小規模なホスト型Runner {#small-hosted-runner-on-linux-arm-available-to-all-tiers}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/linux.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/501423)

{{< /details >}}

GitLab.com向けに、すべてのティアで利用可能なLinux Arm上の小規模なホスト型Runnerを導入できることを嬉しく思います。この2 vCPUのArm Runnerは、GitLab CI/CDと完全に統合されており、Armアーキテクチャ上でネイティブにアプリケーションをビルドおよびテストできます。

私たちは業界最速のCI/CDビルド速度を提供することを決意しており、チームがさらに短いフィードバックサイクルを達成し、最終的にソフトウェアをより速く提供するのを楽しみにしています。

## 規模とデプロイ {#scale-and-deployments}

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

バグのため、GitLab 17.6以前のFIPS Linuxパッケージは、システムのLibgcryptを使用せず、通常のLinuxパッケージにバンドルされているLibgcryptと同じものを使用していました。

このイシューは、AmazonLinux 2を除くGitLab 17.7のすべてのFIPS Linuxパッケージで修正されました。AmazonLinux 2のLibgcryptバージョンは、FIPS Linuxパッケージに同梱されているGPGMEおよびGPGのバージョンと互換性がありません。

AmazonLinux 2用のFIPS Linuxパッケージは、通常のLinuxパッケージにバンドルされているのと同じLibgcryptを引き続き使用します。そうしないと、GPGMEとGnuPGをダウングレードしなければなりません。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### 高度なSASTにおける検出精度の向上 {#improved-detection-accuracy-in-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14685)

{{< /details >}}

高度なSASTを更新し、次の脆弱性クラスをより正確に検出できるようにしました:

- C#: OSコマンドインジェクションとSQLインジェクション。
- Go: パストラバーサル。
- Java: コードインジェクション、ヘッダーまたはログにおけるCRLFインジェクション、クロスサイトリクエストフォージェリ（CSRF）、不適切な証明書検証、脆弱な逆シリアル化、安全でないリフレクション、およびXML外部エンティティ（XXE）インジェクション。
- JavaScript: コードインジェクション。

また、C#（ASP.NET）およびJava（JSF、HttpServlet）のユーザー入力ソースの検出を改善し、一貫性のために重大度レベルを更新しました。

各言語で高度なSASTが検出する脆弱性のタイプを確認するには、[高度なSASTのカバレッジ](../../user/application_security/sast/advanced_sast_coverage.md)を参照してください。この改善されたクロスファイル、クロスファンクションスキャンを使用するには、[高度なSASTを有効](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast)にしてください。すでに高度なSASTを有効にしている場合は、新しいルールが[自動的にアクティブ化](../../user/application_security/sast/rules.md#how-rule-updates-are-released)されます。

### KEVによる効率的なリスク優先順位付け {#efficient-risk-prioritization-with-kev}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#cveenrichmenttype) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/11912)

{{< /details >}}

GitLab 17.7で、既知の悪用された脆弱性カタログ（KEV）のサポートが追加されました。[KEV Catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog)はCISAによって管理されており、実際に悪用されたCVEのリストをキュレーションしています。KEVを活用することで、スキャン結果の優先順位をより適切に設定し、脆弱性が環境に与える潜在的な影響を評価するのに役立てることができます。

このデータは、GraphQLを介してコンポジション解析ユーザーが利用できます。GitLab UIでこのデータを表示することをサポートするための[作業が計画](https://gitlab.com/gitlab-org/gitlab/-/issues/427441)されています。

### 高度なSAST向けに拡張されたコードフロービュー {#expanded-code-flow-view-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md#code-flow)

{{< /details >}}

高度なSASTの[コードフロービュー](../../user/application_security/sast/gitlab_advanced_sast.md#code-flow)は、脆弱性が表示されるあらゆる場所で利用できるようになりました。これには以下が含まれます:

- [脆弱性レポート](../../user/application_security/vulnerability_report/_index.md)。
- [マージリクエストセキュリティウィジェット](../../user/application_security/sast/_index.md#merge-request-widget)。
- [パイプラインセキュリティレポート](../../user/application_security/detect/security_scanning_results.md)。
- [マージリクエストの変更ビュー](../../user/application_security/sast/_index.md#merge-request-changes-view)。

新しいビューはGitLab.comで有効になっています。GitLabセルフマネージドでは、GitLab 17.7（MR変更ビュー）およびGitLab 17.6（その他のすべてのビュー）から、新しいビューがデフォルトで有効になります。サポートされているバージョンと機能フラグの詳細については、[コードフロー機能の可用性](../../user/application_security/sast/gitlab_advanced_sast.md#code-flow)を参照してください。

高度なSASTの詳細については、[発表ブログ](https://about.gitlab.com/blog/gitlab-advanced-sast-is-now-generally-available/)を参照してください。

### GitLab Duo Chatに新しい`/help`コマンド {#new-help-command-in-gitlab-duo-chat}

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/examples.md#gitlab-duo-chat-slash-commands) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/462122)

{{< /details >}}

GitLab Duo Chatの強力な機能を発見しましょう！`/help`をチャットメッセージフィールドに入力するだけで、それがあなたのために何ができるかをすべて探ることができます。

試してみて、GitLab Duo Chatがあなたの仕事をいかにスムーズかつ効率的にできるかを確認してください。

### `environment.action: access`と`prepare`を設定すると、`auto_stop_in`タイマーがリセットされます {#setting-environmentaction-access-and-prepare-resets-the-auto_stop_in-timer}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/yaml/_index.md#environmentauto_stop_in) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)

{{< /details >}}

以前は、`action: prepare`、`action: verify`、および`action: access`ジョブを`auto_stop_in`設定と共に使用した場合、タイマーはリセットされませんでした。18.0以降では、`action: prepare`と`action: access`がタイマーをリセットしますが、`action: verify`は変更しません。

現時点では、`prevent_blocking_non_deployment_jobs`機能フラグを有効にすることで、新しい実装に変更できます。

複数の破壊的な変更は、`environment.action: prepare | verify | access`値の動作を区別することを目的としています。`environment.action: access`キーワードは、タイマーのリセットを除き、現在の動作に最も近いものになります。

将来の互換性イシューを防ぐために、これらのキーワードの使用法を確認する必要があります。以下のイシューで、これらの提案された変更について詳しく学んでください:

- [イシュー437132](https://gitlab.com/gitlab-org/gitlab/-/issues/437132)
- [イシュー437133](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)
- [イシュー437142](https://gitlab.com/gitlab-org/gitlab/-/issues/437142)

### Kubernetes 1.31のサポート {#kubernetes-131-support}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/501390)

{{< /details >}}

このリリースでは、2024年8月にリリースされたKubernetesバージョン1.31の完全なサポートが追加されました。アプリをKubernetesにデプロイする場合、接続されているクラスターを最新のバージョンにアップグレードし、すべての機能を活用できるようになりました。

詳細については、当社の[Kubernetesサポートポリシーとその他のサポートされているKubernetesバージョン](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)を参照してください。

### CI/CDジョブからネームスペースとFluxリソースパスを設定する {#set-namespace-and-flux-resource-path-from-cicd-job}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/500164)

{{< /details >}}

Kubernetes用のダッシュボードを使用するには、環境設定からKubernetes接続用のエージェントを選択し、オプションでネームスペースとFluxリソースを構成して調整ステータスを追跡する必要があります。GitLab 17.6では、CI/CD設定を持つエージェントを選択するサポートを追加しました。しかし、ネームスペースとFluxリソースの設定には、依然としてUIを使用するか、APIコールを行う必要がありました。17.7では、`environment.kubernetes.namespace`と`environment.kubernetes.flux_resource_path`属性を使用して、CI/CD構文でダッシュボードを完全に設定できます。

### 認証情報インベントリ内のグループアクセストークンとプロジェクトアクセストークン {#group-and-project-access-tokens-in-credentials-inventory}

<!-- categories: System Access -->

{{< details >}}

- プラン: Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/credentials_inventory.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/498333)

{{< /details >}}

グループアクセストークンとプロジェクトアクセストークンが、GitLab.comの認証情報インベントリに表示されるようになりました。以前は、パーソナルアクセストークンとSSHキーのみが表示されていました。インベントリ内の追加のトークンタイプにより、グループ全体の認証情報のより完全な全体像が得られます。

### 拡張されたトークン有効期限通知 {#extended-token-expiration-notifications}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../security/tokens/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/464040)

{{< /details >}}

以前は、トークン有効期限メール通知は、期限切れの7日前にのみ送信されていました。現在、これらの通知は、期限切れの30日前と60日前にも送信されます。通知の頻度と日付範囲の増加により、ユーザーは間もなく期限切れになる可能性のあるトークンをより意識するようになります。

### Unicode 15.1絵文字サポート 🦖🍋‍🟩🐦‍🔥 {#unicode-151-emoji-support-}

<!-- categories: Markdown -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](https://gitlab-org.gitlab.io/ruby/gems/tanuki_emoji/) | [関連イシュー](https://gitlab.com/gitlab-org/ruby/gems/tanuki_emoji/-/issues/28)

{{< /details >}}

GitLabのバージョン以前では、絵文字のサポートは古いUnicode標準に限定されており、一部の新しい絵文字は利用できませんでした。

GitLab 17.7ではUnicode 15.1のサポートが導入され、最新の絵文字が追加されました。これにより、ティラノサウルス🦖、ライム🍋‍🟩、フェニックス🐦‍🔥のような魅力的な新しいオプションが含まれ、最新のシンボルで自分自身を表現できます。

さらに、このアップデートは絵文字の多様性を高め、文化、言語、アイデンティティ全体でより大きな表現を保証し、プラットフォームでコミュニケーションする際に誰もが疎外感を感じないようにします。

### 優先するテキストエディタをデフォルトとして設定する {#set-your-preferred-text-editor-as-default}

<!-- categories: Text Editors -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/preferences.md#set-the-default-text-editor) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/423104)

{{< /details >}}

このバージョンでは、よりパーソナライズされた編集エクスペリエンスのために、デフォルトのテキストエディタを設定する機能が導入されます。この変更により、リッチテキストエディタ、プレーンテキストエディタのいずれかを選択するか、またはデフォルトなしを選択できるようになり、コンテンツの作成および編集方法に柔軟性がもたらされます。

このアップデートにより、エディタインターフェースを個々の好みやチームの標準に合わせることで、よりスムーズなワークフローが保証されます。この機能強化により、GitLabは引き続きすべてのユーザーに対してカスタマイズと使いやすさを優先します。

### アクセストークン用の新しい説明フィールド {#new-description-field-for-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/personal_access_tokens.md#create-a-personal-access-token) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/443819)

{{< /details >}}

個人、プロジェクト、グループ、または代理アクセストークンを作成する際に、そのトークンの説明をオプションで入力できるようになりました。これにより、トークンがどこでどのように使用されているかなどの追加のコンテキストを提供できます。

### APIを使用してグループでシークレットプッシュ保護を有効にする {#enable-secret-push-protection-in-your-groups-with-apis}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/group_security_settings.md)

{{< /details >}}

このリリースにより、[REST API](../../api/group_security_settings.md)と[GraphQL API](../../api/graphql/reference/_index.md#mutationsetgroupsecretpushprotection)を介して、グループ内のすべてのプロジェクトでシークレットプッシュ保護を有効にできるようになりました。これにより、プロジェクトごとではなく、グループごとに効率的にシークレットプッシュ保護を有効にできます。プッシュ保護が有効または無効になるたびに、監査イベントがログに記録されます。

### エンタープライズユーザーをリストする新しいAPIエンドポイント {#new-api-endpoint-to-list-enterprise-users}

<!-- categories: System Access -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/group_enterprise_users.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/438366)

{{< /details >}}

グループオーナーは、専用のAPIエンドポイントを使用して、エンタープライズユーザーと関連するすべての属性をリストできるようになりました。

### カスタムロールからオーナーベースロールを削除する {#remove-owner-base-role-from-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/custom_roles/_index.md#create-a-custom-member-role) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/474273)

{{< /details >}}

オーナーベースロールは、カスタムロールの作成時に利用できなくなりました。これは、パーミッションが追加的であるため、追加の値を提供しなかったためです。オーナーベースロールを持つ既存のカスタムロールは、この変更による影響を受けません。

### コンプライアンスセンターのナビゲーションとユーザービリティの改善 {#navigation-and-usability-improvements-for-the-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate、Premium
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_frameworks_report.md)

{{< /details >}}

私たちは、グループとプロジェクトの両方で、コンプライアンスセンターのユーザーエクスペリエンスに対する反復的かつ重要な改善を継続しています。

GitLab 17.7では、2つの重要な改善を提供しました:

- ユーザーはコンプライアンスセンターの**プロジェクト**タブでグループによってフィルタリングできるようになり、ユーザーは適切なプロジェクトとそのプロジェクトに添付されているコンプライアンスフレームワークを適用、フィルタリング、検索するための別のオプションが提供されます。
- プロジェクトのコンプライアンスセンターに**フレームワーク**タブが追加され、ユーザーはその特定のプロジェクトに添付されているコンプライアンスフレームワークを検索できるようになりました。

フレームワークの追加または編集は、プロジェクトではなくグループで行われることに注意してください。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.7)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.7)
- [UI改善](https://papercuts.gitlab.com/?milestone=17.7)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
