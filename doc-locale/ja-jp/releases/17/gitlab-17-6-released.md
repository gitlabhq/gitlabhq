---
stage: Release Notes
group: Monthly Release
date: 2024-11-21
title: "GitLab 17.6リリースノート"
description: "GitLab 17.6では、セルフホストモデルをGitLab Duo Chatに利用できるようになりました。"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024年11月21日、GitLab 17.6は以下の機能をリリースしました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Joel Gerber {#this-months-notable-contributor-joel-gerber}

誰もがGitLabコミュニティのコントリビューターを[推薦](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)できます！活躍中の候補者を支援するか、新しい推薦を追加してください！ 🙌

Joelは、私たちのCIコンポーネントへの貴重なコントリビューターとして、マージリクエストに関する洞察に満ちたフィードバックや、複雑なディスカッションへの思慮深いコメントで評価されました。彼のコントリビュートには、CI/CDカタログの[UIの洗練](https://gitlab.com/gitlab-org/gitlab/-/issues/464703) 、GitLab Terraform Providerの高度に要求されたドキュメントの改善、[ジョブログ](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164595)タイムスタンプ、そして[UI/UX](https://gitlab.com/gitlab-org/gitlab/-/issues/482524#note_2089551197)チームへのフィードバックが含まれます。

Joelは[HackerOne](https://www.hackerone.com/)のスタッフソフトウェアエンジニアであり、GitLabのスタッフフルスタックエンジニア、コントリビューターサクセスの[Lee Tickett](https://gitlab.com/leetickett-gitlab)によって、彼のコントリビュートと貴重なフィードバックに対して推薦されました。

GitLabのシニア製品デザイナーである[Gina Doyle](https://gitlab.com/gdoyle)が、推薦に加わりました。「MRプロセスをより複雑にする内部ディスカッションが盛んに行われていました」とGinaは述べています。「しかし、Joelはディスカッションの中で粘り強く積極的に取り組み、コントリビュートを完了しました。」

「JoelはCI/CDカタログのUIの洗練イシューにもコントリビュートしました」とGitLabのスタッフ製品デザイナーである[Sunjung Park](https://gitlab.com/sunjungp)は述べています。「これにより、私たちのユーザーインターフェースは美しく、他の領域との整合性が保たれます。」

Joelのすべてのコントリビュート、そしてGitLabにコントリビュートしてくださるすべてのオープンソースコミュニティに深く感謝いたします！

## 主要な機能 {#primary-features}

### GitLab Duo Chatにセルフホストモデルを使用 {#use-self-hosted-model-for-gitlab-duo-chat}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/501267)

{{< /details >}}

選択した大規模言語モデル（LLM）を独自のインフラストラクチャでホストし、それらのモデルをGitLab Duo Chatのソースとして構成できるようになりました。この機能はベータ版であり、UltimateとDuo Enterpriseのサブスクリプションで、Self-ManagedインスタンスのGitLab環境で利用できます。

セルフホストモデルを使用すると、オンプレミスまたはプライベートクラウドでホストされているモデルを、GitLab Duo Chatまたはコード提案（GitLab 17.5でベータ機能として導入）のソースとして使用できます。コード提案については、現在、vLLMまたはAWS Bedrock上のオープンソースMistralモデル、AWS Bedrock上のClaude 3.5 Sonnet、およびAzure OpenAI上のOpenAIモデルをサポートしています。Chatについては、現在、vLLMまたはAWS Bedrock上のオープンソースMistralモデル、およびAWS Bedrock上のClaude 3.5 Sonnetをサポートしています。セルフホストモデルを有効にすることで、完全なデータ主権とプライバシーを維持しながら、生成AIの力を活用できます。

[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/501268)501268にフィードバックをお寄せください。

### マージリクエストのレビュアー割り当ての強化 {#enhanced-merge-request-reviewer-assignments}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/merge_requests/reviews/_index.md#request-a-review)

{{< /details >}}

変更を慎重に作成し、マージリクエストを準備したら、次のステップはそれを前進させるのに役立つレビュアーを特定することです。あなたのマージリクエストに適したレビュアーを特定するには、適切な承認者が誰であるか、そして提案している変更の主題エキスパート（コードオーナー）が誰であるかを理解する必要があります。

これで、レビュアーを割り当てる際、サイドバーはあなたのマージリクエストの承認要件とレビュアーとの間に接続を作成します。各承認ルールを表示し、その承認ルールを満たし、マージリクエストを前進させることができる承認者の中から選択します。[オプションのコードオーナーセクション](../../user/project/codeowners/reference.md#optional-sections)を使用する場合、それらのルールもサイドバーに表示され、変更に適した主題エキスパートを特定するのに役立ちます。

強化されたレビュアーの割り当ては、GitLabで割り当てられたレビュアーにインテリジェンスを適用する次の進化です。このイテレーションは、提案されたレビュアーから学んだこと、およびマージリクエストを前進させるための最適なレビュアーを効果的に特定する方法に基づいて構築されています。レビュアーの割り当ての[今後のイテレーション](https://gitlab.com/groups/gitlab-org/-/epics/14808)では、可能なレビュアーを推薦およびランク付けするために使用されるインテリジェンスを引き続き強化します。

### ワークスペースでのプライベートコンテナレジストリのサポート {#support-for-private-container-registries-in-workspaces}

<!-- categories: Remote Development -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/workspace/configuration.md#configure-support-for-private-container-registries)

{{< /details >}}

GitLabのワークスペースは、プライベートコンテナレジストリのサポートを提供するようになりました。この設定により、任意のプライベートレジストリからコンテナイメージをプルできます。お使いのKubernetesクラスターに有効なイメージプルシークレットがある限り、[GitLabエージェントの設定](../../user/workspace/gitlab_agent_configuration.md)でそのシークレットを参照できます。

この機能は、特にカスタムまたはサードパーティのコンテナレジストリを使用するチームにとってワークフローを簡素化し、コンテナ化された開発環境の柔軟性とセキュリティを向上させます。

### ワークスペースで拡張機能マーケットプレースが利用可能に {#extension-marketplace-now-available-in-workspaces}

<!-- categories: Remote Development -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/web_ide/_index.md#manage-extensions)

{{< /details >}}

拡張機能マーケットプレースがワークスペースで利用可能になりました。拡張機能マーケットプレースを使用すると、サードパーティの拡張機能を発見、インストール、および管理して、開発エクスペリエンスを向上させることができます。何千もの拡張機能から選択して、生産性を向上させたり、ワークフローをカスタマイズしたりできます。

拡張機能マーケットプレースはデフォルトで無効になっています。開始するには、ユーザー設定に移動し、[拡張機能マーケットプレース](../../user/profile/preferences.md#integrate-with-the-extension-marketplace)を有効にしてください。エンタープライズユーザーの場合、トップレベルグループのオーナーロールを持つユーザーのみが[拡張機能マーケットプレース](../../user/enterprise_user/_index.md#enable-the-extension-marketplace-for-enterprise-users)を有効にできます。

### 遅延終了によるワークスペースライフサイクルの改善 {#improved-workspace-lifecycle-with-delayed-termination}

<!-- categories: Remote Development -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/workspace/_index.md#automatic-workspace-stop-and-termination)

{{< /details >}}

このリリースにより、ワークスペースは、設定されたタイムアウトが経過すると、終了ではなく停止するようになりました。この機能により、常にワークスペースを再起動し、中断したところから再開できます。

デフォルトでは、ワークスペースは自動的に次のように処理されます。

- ワークスペースが最後に開始または再起動されてから36時間後に停止
- ワークスペースが最後に停止されてから722時間後に終了

これらの設定は、[GitLabエージェントの設定](../../user/workspace/gitlab_agent_configuration.md)で構成できます。

この機能により、ワークスペースは停止後約1ヶ月間利用可能です。これにより、ワークスペースのリソースを最適化しながら、進捗状況を維持できます。

### デプロイ詳細ページにリリースノートを表示 {#display-release-notes-on-deployment-details-page}

<!-- categories: Continuous Delivery -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/deployment_approvals.md#view-blocked-deployments) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/493260)

{{< /details >}}

デプロイで承認を求められた内容について疑問に思ったことはありませんか？以前のバージョンでは、内容とテスト手順の詳細な説明を含むリリースを作成できましたが、関連する環境固有のデプロイではこのデータが表示されませんでした。GitLabが関連するデプロイ詳細ページにリリースノートを表示するようになったことをお知らせできることを嬉しく思います。

GitLabのリリースは常にGitタグから作成されるため、リリースノートはタグによってトリガーされたパイプラインに関連するデプロイでのみ表示されます。

この機能は[Anton Kalmykov](https://gitlab.com/antonkalmykov)によってGitLabにコントリビュートされました。ありがとうございます！

### 管理者設定: CI/CDジョブトークン許可リストの強制 {#admin-setting-to-enforce-cicd-job-token-allowlist}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/continuous_integration.md#access-job-token-permission-settings) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/496647)

{{< /details >}}

以前、私たちはデフォルトのCI/CDジョブトークン（`CI_JOB_TOKEN`）の動作が[GitLab 18.0で変更される](../../update/deprecations.md#cicd-job-token---authorized-groups-and-projects-allowlist-enforcement)ことを発表しました。これにより、プロジェクトへのアクセスを継続したい場合は、個々の[プロジェクトまたはグループをプロジェクトのジョブトークン許可リストに明示的に追加する](../../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)必要があります。

現在、Self-ManagedインスタンスおよびDedicatedインスタンスの管理者に、このより安全な設定をインスタンス上のすべてのプロジェクトに強制する機能を提供しています。この設定を有効にすると、すべてのプロジェクトは、CI/CDジョブトークンを認証に使用したい場合、許可リストを利用する必要があります。*注: この設定を強力なセキュリティポリシーの一部として有効にすることをお勧めします。*

### CI/CDジョブトークンの認証を追跡 {#track-cicd-job-token-authentications}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/jobs/ci_job_token.md#job-token-authentication-log) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/467292)

{{< /details >}}

以前は、他のどのプロジェクトがCI/CDジョブトークンで認証してプロジェクトにアクセスしているかを追跡するのは困難でした。プロジェクトへのアクセスを監査および制御しやすくするために、認証ログを追加しました。

この認証ログを使用すると、UIおよびダウンロード可能なCSVファイルの両方で、ジョブトークンを使用してプロジェクトに認証した他のプロジェクトのリストを表示できます。このデータは、プロジェクトアクセスを監査し、ジョブトークン許可リストを埋めるのに役立ち、[プロジェクトにアクセスできるプロジェクトをより強力に制御](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project)できるようにします。

### 脆弱性レポートのグループ化 {#vulnerability-report-grouping}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#group-vulnerabilities) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10164)

{{< /details >}}

ユーザーは、グループ内の脆弱性を表示する機能を必要とします。これにより、セキュリティアナリストは一括アクションを利用して、トリアージタスクを最適化できます。さらに、ユーザーはグループに一致する脆弱性の数（つまり、OWASP Top 10の脆弱性がいくつあるか）を確認できます。

### モデルレジストリが一般提供開始 {#model-registry-now-generally-available}

<!-- categories: MLOps -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/ml/model_registry/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14998)

{{< /details >}}

一般提供が開始されたGitLabのモデルレジストリは、既存のGitLabワークフローの一部として機械学習モデルを管理するための一元化されたハブです。モデルバージョンを追跡し、アーティファクトとメタデータを保存し、モデルカードに包括的なドキュメントを維持できます。

シームレスなインテグレーションのために構築されたモデルレジストリは、[MLflowクライアント](../../user/project/ml/experiment_tracking/mlflow_client.md)とネイティブに連携し、CI/CDパイプラインに直接接続することで、自動化されたモデルのデプロイとテストを可能にします。データサイエンティストは直感的なUIまたは既存のMLflowワークフローを通じてモデルを管理でき、MLOpsチームはセマンティックバージョニングとCI/CDインテグレーションを活用して、[GitLab API](../../api/model_registry.md)内ですべての本番環境デプロイを効率化できます。

私たちの[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/504458)に気軽にコメントを残してください。後ほどご連絡いたします！GitLabインスタンスで、**デプロイ > モデルレジストリ**に移動して、今すぐ始めましょう。

### GitLab Dedicatedの新しいテナントネットワーキング設定 {#new-tenant-networking-configurations-for-gitlab-dedicated}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/dedicated/configure_instance/network_security.md#outbound-privatelink-connections)

{{< /details >}}

GitLab Dedicatedテナント管理者として、スイッチボードを使用して送信プライベートリンクとプライベートホストゾーンを設定できるようになりました。スイッチボードで定期的なスナップショットを表示することで、ネットワーク接続を監視することもできます。

送信プライベートリンクとプライベートホストゾーンは、AWSアカウント内のリソースとGitLab Dedicated間のセキュアなネットワーク接続を確立します。

### SASTおよびDASTセキュリティスキャナーの新しい準拠チェック {#new-adherence-checks-for-sast-and-dast-security-scanners}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_status_report.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/12661)

{{< /details >}}

GitLabは、SAST、シークレット検出、依存関係スキャン、コンテナスキャンなど、幅広いセキュリティスキャナーを提供しており、アプリケーションの脆弱性をチェックできます。

監査担当者および関連するコンプライアンス当局に対し、アプリケーションがリポジトリにセキュリティスキャナーを設定することを義務付ける規制基準を遵守していることを示す方法が必要です。

これらの標準への準拠を示すのに役立つよう、このリリースには、コンプライアンスセンターの標準準拠レポートの一部として、2つの新しいチェックが含まれています。これらの新しいチェックは、グループ内のプロジェクトに対してSASTとDASTが有効になっているかどうかを確認します。これらのチェックは、SASTとDASTセキュリティスキャナーがプロジェクトで正しく実行され、パイプラインの結果に正しいアーティファクトが含まれていることを確認します。

## 規模とデプロイ {#scale-and-deployments}

### グループWebhookのプロジェクトイベント {#project-events-for-group-webhooks}

<!-- categories: Webhooks -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/webhook_events.md#project-events) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/359044)

{{< /details >}}

このリリースでは、グループWebhookにプロジェクトイベントを追加しました。プロジェクトイベントは、次の場合にトリガーされます。

- グループでプロジェクトが作成された。
- グループでプロジェクトが削除された。

これらのイベントは、[グループWebhook](../../user/project/integrations/webhooks.md#group-webhooks)に対してのみトリガーされます。

### 割り当てられたGitLab DuoシートでGitLab Duoユーザーをフィルタリング {#filter-gitlab-duo-users-by-assigned-seat}

<!-- categories: Add-on Provisioning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: GitLab Duo Pro, GitLab Duo Enterprise
- リンク: [ドキュメント](../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14683)

{{< /details >}}

以前のGitLabバージョンでは、GitLab Duoシート割り当てページに表示されるユーザーリストをフィルタリングできなかったため、どのユーザーに以前GitLab Duoシートが割り当てられたかを確認するのが困難でした。これで、割り当て済みシート = はい、または割り当て済みシート = いいえでユーザーリストをフィルタリングして、現在GitLab Duoシートが割り当てられているか、または割り当てられていないユーザーを確認できるようになり、シート割り当ての調整が容易になります。

### GitLab Duoシート割り当てメールの更新 {#gitlab-duo-seat-assignment-email-update}

<!-- categories: Seat Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170507)

{{< /details >}}

Self-Managedインスタンスのすべてのユーザーは、GitLab Duoシートが割り当てられたときにメールを受信します。

以前は、Duo Enterpriseシートを割り当てられたユーザーや、一括割り当てによってアクセスを許可されたユーザーには通知されませんでした。誰かに言われるか、GitLab UIに新しい機能があることに気づかない限り、自分がシートを割り当てられたことはわかりませんでした。

このメールを無効にするには、管理者は`duo_seat_assignment_email_for_sm`FFを無効にできます。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### EPSSによる効率的なリスク優先順位付け {#efficient-risk-prioritization-with-epss}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#cveenrichmenttype) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/11544)

{{< /details >}}

GitLab 17.6では、Exploit Prediction Scoring System（EPSS）のサポートを追加しました。EPSSは、各CVEに0から1の間のスコアを付与し、今後30日以内にCVEが悪用される確率を示します。EPSSを活用することで、スキャン結果の優先順位をより適切に設定し、脆弱性が環境に与える潜在的な影響を評価できます。

このデータは、GraphQLを介してコンポジション解析ユーザーが利用できます。

### APIを介してプロジェクトでシークレットプッシュ保護を有効にする {#enable-secret-push-protection-in-your-projects-via-api}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/projects.md)

{{< /details >}}

シークレットプッシュ保護をプログラムで有効にするのがより簡単になりました。アプリケーション設定REST APIを更新し、次のことができるようになりました:

1. 自己管理インスタンスで機能を有効にし、プロジェクトごとに有効にできるようにします。
1. プロジェクトで機能が有効になっているかどうかを確認します。
1. 指定されたプロジェクトで機能を有効にします。

### 適用された除外に関するシークレットプッシュ保護監査イベント {#secret-push-protection-audit-events-for-applied-exclusions}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/secret_detection/exclusions.md)

{{< /details >}}

シークレットプッシュ保護の除外が適用された際に、監査イベントがログに記録されるようになりました。これにより、セキュリティチームは、プロジェクトの除外リストにあるシークレットがプッシュされることを許可されたあらゆる事象を監査および追跡できます。

### 自動化されたリポジトリX-Ray {#automated-repository-x-ray}

<!-- categories: Code Suggestions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/project/repository/code_suggestions/repository_xray.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/14100)

{{< /details >}}

リポジトリX-Rayは、プロジェクトの依存関係に関する追加のコンテキストを提供することで、GitLab Duoコード提案のコード生成リクエストを強化し、コードレコメンデーションの精度と関連性を向上させます。これにより、コード生成の品質が向上します。以前は、リポジトリX-Rayは、設定および管理する必要があるCIジョブを使用していました。

現在、新しいコミットがプロジェクトのデフォルトブランチにプッシュされると、リポジトリX-Rayはバックグラウンドジョブを自動的にトリガーし、リポジトリ内の適用可能な設定ファイルをスキャンして解析します。

### GitLab Duoの企業ネットワークサポート {#corporate-network-support-for-gitlab-duo}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../editor_extensions/language_server/_index.md#enable-proxy-authentication) | [関連イシュー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/159)

{{< /details >}}

GitLab Duoプラグインの最新アップデートでは、高度なプロキシ認証が導入されました。これにより、開発者は厳格な企業ファイアウォールを持つ環境でシームレスに接続できます。既存のHTTPプロキシサポートに基づいて、この機能強化により認証された接続が可能になります。VS CodeおよびJetBrainsIDEでのDuo機能への安全で中断のないアクセスを保証します。

このアップデートは、制限されたネットワーク環境で安全な認証済み接続を必要とする開発者にとって非常に重要です。これにより、すべてのDuo機能がセキュリティを損なうことなく利用可能な状態を維持します。

### 指定された日時にマージ {#merge-at-a-scheduled-date-and-time}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/merge_requests/auto_merge.md#prevent-merge-before-a-specific-date)

{{< /details >}}

一部のマージリクエストは、特定の日時が経過するまでマージのために保留する必要がある場合があります。その日時が過ぎたら、マージの権限を持つ人を見つけて、対応してくれることを期待する必要があります。これが営業時間外であるか、タイムラインが重要である場合、タスクのために事前に準備する必要があるかもしれません。

これで、マージリクエストを作成または編集する際に、`merge after`日付を指定できます。この日付は、マージリクエストがその日付を過ぎるまでマージされないようにするために使用されます。この新しい機能を、以前リリースされた[自動マージの改善](https://about.gitlab.com/releases/2024/09/19/gitlab-17-4-released/#auto-merge-when-all-checks-pass)と組み合わせることで、将来的にマージリクエストをマージするようにスケジュールする柔軟性が得られます。

[Niklas van Schrick](https://gitlab.com/Taucher2003)の素晴らしいコントリビュートに心から感謝いたします！

### `glab agent bootstrap`コマンドに値のサポートを追加 {#add-support-for-values-to-the-glab-agent-bootstrap-command}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/cluster/agent/bootstrap.md#options) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/482844)

{{< /details >}}

前回のリリースでは、GitLab CLIツールへの簡単なエージェントブートストラップのサポートを導入しました。GitLab 17.6は、カスタムHelm値のサポートにより、`glab cluster agent bootstrap`コマンドをさらに改善します。生成された`HelmRelease`リソースをカスタマイズするには、`--helm-release-values`および`--helm-release-values-from`フラグを使用できます。

### CI/CDジョブの環境でGitLabエージェントを選択 {#select-a-gitlab-agent-for-an-environment-in-a-cicd-job}

<!-- categories: Environment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md#configure-a-dashboard-for-a-dynamic-environment) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/467912)

{{< /details >}}

Kubernetes用のダッシュボードを使用するには、環境設定からKubernetes接続用のエージェントを選択する必要があります。これまで、エージェントはUIまたは（GitLab 17.5からは）APIからのみ選択でき、CI/CDからダッシュボードを構成するのは困難でした。GitLab 17.6では、`environment.kubernetes.agent`構文を使用してエージェント接続を構成できます。さらに、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/500164)500164は、CI/CD設定からネームスペースとFluxリソースを選択するためのサポートを追加することを提案しています。

### 特権アクションの監査イベント {#audit-events-for-privileged-actions}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/compliance/audit_event_types.md#groups-and-projects) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/486532)

{{< /details >}}

特権的な設定関連の管理者アクションに対する追加の監査イベントが利用可能になりました。これらの設定が変更された時期の記録は、監査証跡を提供することでセキュリティを向上させるのに役立ちます。

### マージリクエストがマージされた場合の新しい監査イベント {#new-audit-event-when-merge-requests-are-merged}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/audit_event_types.md#compliance-management) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/442279)

{{< /details >}}

このリリースにより、マージリクエストがマージされると、`merge_request_merged`という新しい監査イベントタイプがトリガーされ、マージリクエストに関する主要な情報（以下を含む）が含まれます:

- マージリクエストのタイトル
- マージリクエストの説明または概要
- マージに必要だった承認数
- マージに付与された承認数
- どのユーザーがマージリクエストを承認したか
- コミッターがマージリクエストを承認するかどうか
- 作成者がマージリクエストを承認したかどうか
- マージの日時
- コミット履歴からのSHAのリスト

### OTP認証器とWebAuthnデバイスを独立して無効にする {#disable-otp-authenticator-and-webauthn-devices-independently}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/account/two_factor_authentication.md#disable-two-factor-authentication) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/393419)

{{< /details >}}

OTP認証器とWebAuthnデバイスを個別に、または同時に無効にできるようになりました。以前は、OTP認証器を無効にすると、WebAuthnデバイスも無効になりました。この2つが独立して動作するようになったため、これらの認証方法に対するより詳細な制御が可能になります。

### トークンに関する情報を取得するためにAPIを使用する {#use-api-to-get-information-about-tokens}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../api/admin/token.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/443597)

{{< /details >}}

管理者は、新しいトークン情報APIを使用して、パーソナルアクセストークン、デプロイトークン、およびフィードトークンに関する情報を取得できます。トークン情報を公開する他のAPIエンドポイントとは異なり、このエンドポイントを使用すると、管理者はトークンのタイプを知らなくてもトークン情報を取得できます。

[Nicholas Wittstruck](https://gitlab.com/nwittstruck)とシーメンスチームの残りのメンバーの皆様、コントリビュートありがとうございます！

### 新しい場所からのサインインメールでの詳細情報 {#more-information-in-sign-in-emails-from-new-locations}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/profile/notifications.md#notifications-for-unknown-sign-ins) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/296128)

{{< /details >}}

GitLabは、新しい場所からのサインインが検出された場合にオプションでメールを送信します。以前は、このメールにはIPアドレスのみが含まれており、場所と関連付けるのは困難でした。このメールには、都市と国の場所情報も含まれるようになりました。

[Henry Helm](https://gitlab.com/shangsuru)のコントリビュートに感謝いたします！

### グループ保護ブランチの変更防止 {#prevent-modification-of-group-protected-branches}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#approval_settings) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13776)

{{< /details >}}

マージリクエスト承認ポリシーがグループブランチの変更を防止するように設定されている場合、ポリシーはグループ用に構成された保護ブランチを考慮するようになりました。この設定により、グループレベルで保護ブランチされているブランチが保護解除されないように保証されます。保護ブランチは、ブランチの削除やブランチへの強制プッシュなど、特定のアクションを制限します。この動作をオーバーライドし、新しい`approval_settings.block_group_branch_modification`プロパティを使用して特定のトップレベルグループの例外を宣言することで、グループオーナーが必要に応じて保護ブランチを一時的に変更できるようにすることができます。

この新しいプロジェクトオーバーライド設定は、グループ保護ブランチ設定がセキュリティおよびコンプライアンス要件を回避するために変更されることを防止し、保護ブランチのより安定した強制を保証します。

### トップレベルグループオーナーはサービスアカウントを作成できる {#top-level-group-owners-can-create-service-accounts}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/settings/account_and_limit_settings.md#allow-top-level-group-owners-to-create-service-accounts) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/468806)

{{< /details >}}

現在、GitLab自己管理型では管理者のみがサービスアカウントを作成できます。現在、トップレベルグループオーナーがサービスアカウントを作成できるオプションの設定があります。これにより、管理者は、サービスアカウントを作成できる幅広いロールを許可するか、管理者のみのタスクとして維持するかを選択できます。

### サービスアカウントバッジ {#service-accounts-badge}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/service_accounts.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/439768)

{{< /details >}}

サービスアカウントには指定されたバッジが付与され、ユーザーリストで簡単に識別できるようになりました。以前は、これらのアカウントには`bot`バッジしかなく、それらとグループおよびプロジェクトアクセストークンを区別するのが困難でした。

### 任意のCI/CDジョブでPagesサイトをデプロイ {#deploy-your-pages-site-with-any-cicd-job}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/pages/_index.md#user-defined-job-names)

{{< /details >}}

パイプライン設計の柔軟性を高めるため、Pagesデプロイジョブに`pages`という名前を付ける必要がなくなりました。任意のCI/CDジョブで`pages`属性を使用するだけで、Pagesデプロイをトリガーできるようになりました。

### GitLab Duo Pro用AIインパクト分析API {#ai-impact-analytics-api-for-gitlab-duo-pro}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#aimetrics)

{{< /details >}}

GitLab Duo Proのお客様は、`aiMetrics`GraphQLAPIを使用してAIインパクト分析メトリクスにプログラムでアクセスできるようになりました。メトリクスには、割り当てられたGitLab Duoシートの数、GitLab Duo Chatユーザー、およびコード提案ユーザーが含まれます。APIは、表示および承認されたコード提案の粒度の高いカウントも提供します。このデータを使用すると、コード提案の承認率を計算し、Duo ProユーザーによるGitLab Duo Chatとコード提案の採用状況をよりよく理解できます。AIインパクト分析メトリクスをバリューストリーム分析およびDORAメトリクスと組み合わせることで、Duo Chatとコード提案の採用がチームの生産性にどのように影響しているかについて、より深いインサイトを得ることができます。

### 表示からクローズ済みアイテムを簡単に削除 {#easily-remove-closed-items-from-your-view}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/456941)

{{< /details >}}

**クローズアイテムを表示**トグルをオフにすることで、リンクされたアイテムリストと子アイテムリストからクローズ済みアイテムを非表示にできるようになりました。この追加により、表示をより詳細に制御でき、複雑なプロジェクトでの視覚的な煩雑さを減らしながら、アクティブな作業に集中できます。

### ユーザーレベルのGitLab Duo Enterprise使用状況メトリクスをクエリする {#query-user-level-gitlab-duo-enterprise-usage-metrics}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#aiusermetrics) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/483049)

{{< /details >}}

このリリース以前は、Duo EnterpriseユーザーごとのGitLab Duo Chatとコード提案の使用状況データを取得することはできませんでした。17.6では、GraphQLAPIを追加し、アクティブなDuo Enterpriseユーザーごとのコード提案の承認数とDuo Chatインタラクションの可視性を提供します。APIは、どのDuo Enterprise機能が誰によってどれくらいの頻度で使用されているかについて、より詳細なインサイトを得るのに役立ちます。これは、GitLab内で[より包括的なDuo Enterprise使用状況データを提供](https://gitlab.com/groups/gitlab-org/-/epics/15026)するという私たちの目標に向けた最初のイテレーションです。

### CycloneDX SBOMからのライセンスデータのサポート {#support-for-license-data-from-cyclonedx-sboms}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/415935)

{{< /details >}}

ライセンススキャナーは、[サポートされているパッケージタイプ](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#supported-languages-and-package-managers)を含むCycloneDX SBOMから、依存関係のライセンスを消費する機能を持つようになりました。

CycloneDX SBOMの`licenses`フィールドが利用可能な場合、ユーザーはSBOMからライセンスデータを確認できます。SBOMにライセンス情報がない場合でも、ライセンスデータベースからこのデータを提供し続けます。

### macOS Sequoia 15およびXcode 16のジョブイメージ {#macos-sequoia-15-and-xcode-16-job-image}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/macos.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/502852)

{{< /details >}}

macOS Sequoia 15とXcode 16を使用して、Appleデバイスの最新世代向けアプリケーションを作成、テスト、デプロイできるようになりました。

GitLabのmacOS上の[ホストされたRunner](../../ci/runners/hosted_runners/macos.md)は、安全でオンデマンドのビルド環境で開発チームがmacOSアプリケーションをより迅速にビルドおよびデプロイできるよう支援します。これはGitLab CI/CDと統合されています。

今日から`.gitlab-ci.yml`ファイルで`macos-15-xcode-16`イメージを使用して試してみてください。

### JaCoCoのテストカバレッジ可視化機能が一般提供開始 {#jacoco-test-coverage-visualization-now-generally-available}

<!-- categories: Code Testing and Coverage -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/testing/code_coverage/jacoco.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/227345)

{{< /details >}}

マージリクエスト差分ビューで、JaCoCoのテストカバレッジ結果を直接確認できるようになりました。この可視化により、どの行がテストでカバーされており、マージする前に追加のカバレッジが必要な行を迅速に特定できます。

### GitLab Runner 17.6 {#gitlab-runner-176}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 17.6もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### バグ修正 {#bug-fixes}

- [GitLab Runner 17.5.0でポッドがアタッチ可能になるのに失敗](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38260)
- [Fleetingプラグインのインストール時に`exec format error`でRunnerがクラッシュ](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38247)
- [cgroup v2が有効なKubernetesexecutorポッドがOOMKilled時にハングする](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38244)
- [設定テンプレートでRunnerを登録する際にRunnerのデフォルトが尊重されない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38231)
- [Execモード使用時にGitLab Runnerがポーリング期間中にKubernetesポッドがアタッチ可能になるのを待機する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37244)
- [機能フラグ`FF_GIT_URLS_WITHOUT_TOKENS`が有効な場合に認証の問題が発生する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38268)

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.6)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.6)
- [UI改善](https://papercuts.gitlab.com/?milestone=17.6)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
