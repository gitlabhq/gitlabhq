---
stage: Release Notes
group: Monthly Release
date: 2025-08-21
title: "GitLab 18.3リリースノート"
description: "GitLab 18.3がVisual StudioのGitLab Duo Agent Platform（ベータ版）を搭載してリリースされました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年8月21日、GitLab 18.3は次の機能を搭載してリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Ahmed Kashkoush {#this-months-notable-contributor-ahmed-kashkoush}

18.3において、[Ahmed Kashkoush](https://gitlab.com/ahmad-kashkoush)氏を今月の注目すべきコントリビューターとして表彰できることを大変光栄に思います。

Ahmed氏は、この夏に[Google Summer of Codeへの参加](https://gitlab.com/ahmad-kashkoush/gsoc-2025-final-report)を通じて、[GitLab Web IDE](https://gitlab.com/gitlab-org/gitlab-web-ide)の傑出したコントリビューターとなっています。彼は、長年のコミュニティからの要望に直接応え、不可欠なGit操作を一貫して提供してきました。彼の5つの重要なMRには、[コミットおよび強制プッシュ機能](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/497) 、[更新確認メッセージ](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/540) 、[コミット修正機能](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/507) 、[ブランチ作成操作](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/534) 、および[ブランチ削除機能](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/539)が含まれています。

新機能の実装に加え、Ahmed氏はWeb IDEからの既存のコミット修正に関する5年以上前の機能リクエストを解決しました。これはコミュニティから24の賛成票を得た機能です。彼の包括的なブランチ管理実装により、Web IDEはローカル開発環境との機能の同等性に近づき、ユーザーが基本的なGit操作のためにインターフェースを切り替える必要がなくなりました。Ahmed氏の作業は、Web IDEを開発者にとってより利用しやすくすることで、「誰もがコントリビュートすることができる」という[GitLabのミッション](https://handbook.gitlab.com/handbook/company/mission/)を直接支援しています。

Google Summer of Codeプログラム全体を通して彼のメンターを務めたGitLabのスタッフフロントエンドエンジニアである[Enrique Alcántara](https://gitlab.com/ealcantara)によってノミネートされました。「Ahmedは実際のユーザーの課題解決に献身的に取り組んでいます」とEnriqueは言います。「彼の仕事は、集中したコントリビューターがGitLabのコア機能の改善に与える影響を示しています。」

Ahmed氏のコントリビュートは、オープンソース開発におけるメンターシップとコミュニティ連携の力を示し、ローカル環境に関係なく開発者にとってGitLabをより利用しやすいものにしています。

Ahmedさん、GitLab Web IDEへの素晴らしいコントリビュートをありがとうございます！

## 主要な機能 {#primary-features}

### Visual StudioのGitLab Duo Agent Platform（ベータ版） {#duo-agent-platform-in-visual-studio-beta}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/duo_agent_platform/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/179)

{{< /details >}}

Visual Studio向けGitLab Duo Agent Platformの公開ベータ版リリースを発表できることを嬉しく思います！このリリースにより、Visual StudioユーザーはGitLab Duo Agent Platformの高度なAI搭載機能をIDE内で直接利用できるようになります。

GitLab Duo Agent Platformは、2つの強力な機能をワークフローにもたらします:

- **Agentic chat**: ファイル作成編集、パターンマッチングやgrepによるコードベース検索、コードに関する即時回答など、会話型タスクをVisual Studioを離れることなく迅速に実行できます。
- **Agent flows**: 包括的な計画と実装のサポートにより、より大規模で複雑なタスクに取り組むことができます。エージェントフローは、イシュー、MR、コミット、CI/CDパイプライン、セキュリティ脆弱性などのGitLabリソースを活用し、上位レベルのアイデアをアーキテクチャとコードに変換するのに役立ちます。

両方の機能は、ドキュメント、コードパターン、プロジェクト情報にわたるインテリジェントな検索を提供し、迅速な編集から詳細なプロジェクト分析へとシームレスに移行できるようになります。

今すぐVisual StudioでGitLab Duo Agent Platformのベータ版を試して、開発ワークフローにおける新しいレベルの生産性とAIアシスタンスを体験してください。

### 埋め込みビュー（GLQLによる） {#embedded-views-powered-by-glql}

<!-- categories: Markdown, Wiki, Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/glql/_index.md#embedded-views) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15008)

{{< /details >}}

このリリースでは、GLQLを搭載した埋め込みビューを一般公開しました。Wikiページ、エピックの説明、イシューのコメント、MRなど、作業が行われる場所でGitLabデータの動的でクエリ可能なビューを作成および埋め込みます。

埋め込みビューは、複数の場所を移動することなく、チームが作業の進捗を追跡するための安定した基盤を提供します。使い慣れた構文を使用してイシュー、MR、エピック、その他の作業アイテムをクエリし、結果をカスタマイズ可能なフィールドとフィルタリングを備えたテーブルまたはリストとして表示します。

埋め込みビューは、静的なドキュメントをプロジェクトデータと同期する生きたダッシュボードに変え、チームがコンテキストを維持し、ワークフロー全体でコラボレーションを改善するのに役立ちます。

埋め込みビューの強化を継続するにあたり、皆様のフィードバックを歓迎します。[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509792)で皆様のご意見やご提案をお聞かせください。

### 直接転送による移行 {#migration-by-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/import/direct_transfer_migrations.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11398)

{{< /details >}}

直接転送による移行が一般公開されました。GitLabインスタンス間でGitLabグループとプロジェクトを直接転送で移行するには、GitLab UIまたは[REST API](../../api/bulk_imports.md)を使用できます。

[エクスポートファイルをアップロードして移行する](../../user/project/settings/import_export.md#migrate-projects-by-uploading-an-export-file)のと比較して、直接転送は次のとおりです:

- 大規模なプロジェクトでより確実に動作します。
- ソースとターゲットのインスタンス間のより大きなバージョンギャップを持つ移行をサポートします。
- 移行プロセスと結果に対するより良いインサイトを提供します。

GitLab.comでは、直接転送による移行がデフォルトで有効になっています。GitLab Self-ManagedおよびGitLab Dedicatedでは、管理者が[機能を有効にする](../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)必要があります。

### CI/CDジョブトークンのきめ細かい権限 {#fine-grained-permissions-for-cicd-job-tokens}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../ci/jobs/fine_grained_permissions.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15258)

{{< /details >}}

パイプラインセキュリティの柔軟性が向上しました。ジョブトークンは、パイプライン内のリソースへのアクセスを提供する一時的な認証情報です。これまでは、これらのトークンはユーザーから完全な権限を継承しており、しばしば不必要に広範なアクセス能力をもたらしていました。

新しいジョブトークンのきめ細かい権限機能により、ジョブトークンがプロジェクト内でアクセスできる特定のリソースを正確に制御できるようになりました。これにより、CI/CDワークフローで最小権限の原則を実装し、CI/CDジョブトークンを使用してプロジェクトにアクセスする際に、ジョブがタスクを完了するために必要な最小アクセスのみを付与できます。

パイプラインにおける長期的なトークンへの依存を減らすため、[追加のきめ細かい権限](https://gitlab.com/groups/gitlab-org/-/epics/6310)の追加に積極的に取り組んでいます。

### GitLab Duo Self-HostedでGitLab Duoコードレビューが利用可能（ベータ版） {#code-review-available-on-gitlab-duo-self-hosted-beta}

<!-- categories: Code Suggestions, Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/524929)

{{< /details >}}

GitLab Duo Self-HostedでGitLab Duoコードレビューを使用できるようになりました。この機能はGitLab Duo Self-Hostedでベータ版として提供されており、Mistral、Meta Llama、Anthropic Claude、およびOpenAI GPTモデルファミリーをサポートしています。

データ主権を損なうことなく開発プロセスを加速するために、GitLab Duo Self-HostedでGitLab Duoコードレビューを使用してください。GitLab DuoコードレビューがMRをレビューする際、潜在的なバグを特定し、直接適用できる改善策を提案します。人間がレビューを依頼する前に、GitLab Duoコードレビューを使用して変更をイテレーションし、改善してください。

GitLab Duoコードレビューに関するフィードバックは、[イシュー517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)でお寄せください。

### GitLab Duoコードレビューの指示をカスタマイズする {#customize-instructions-for-gitlab-duo-code-review}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/merge_requests/duo_in_merge_requests.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/545136)

{{< /details >}}

GitLab Duoコードレビュー用のカスタム命令を使用して、プロジェクト全体で一貫したコードレビュー基準を適用します。グロブパターンを使用して異なるファイルタイプに固有のレビュー基準を定義し、言語固有の規則が最も重要な場所で適用されるようにします。

カスタム命令を使用すると、次のことができます:

- チームのコードレビュー基準を記述します
- グロブパターンを使用してファイル固有の命令を定義します
- カスタム命令を参照する、明確にラベル付けされたフィードバックを観察します

カスタム命令を記述した`.GitLab/duo/mr-review-instructions.YAML`ファイルをリポジトリ内に作成するだけです。GitLab Duoはこれらの命令を自動的にレビューに組み込み、フィードバックを提供する際に特定の命令グループを引用します。

この機能を改善するために、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)でご意見やご提案をお寄せください。

### GitLab Duo Self-Hostedに独自のモデルを持ち込む（ベータ版） {#bring-your-own-models-to-gitlab-duo-self-hosted-beta}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/517581)

{{< /details >}}

GitLab Duo Self-Hostedでは、GitLab Duo機能で使用するために独自のモデルを持ち込むことができるようになりました。この機能はベータ版であり、GitLab Duo Enterpriseをご利用のすべてのGitLab Self-Managedのお客様が利用できます。インスタンス管理者は、サポートされているGitLab Duo機能で使用するために、互換性のある任意のモデルを設定できます。

この機能はGitLab Duo Self-Hostedの柔軟性を高めますが、GitLabはすべてのGitLab Duo機能がすべての互換モデルで動作することを保証することはできません。インスタンス管理者は、選択したモデルの互換性とパフォーマンスを検証する責任があります。GitLabは、選択したモデルまたはプラットフォームに固有の問題に対するテクニカルサポートを提供しません。

### GitLab Duo Self-Hostedでのハイブリッドモデル選択（ベータ版） {#hybrid-model-selection-on-gitlab-duo-self-hosted-beta}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17192)

{{< /details >}}

GitLab Duo Self-Hostedで、GitLab AIベンダーモデルとプライベートに設定されたセルフホストモデルを組み合わせて使用できるようになりました。この機能はベータ版であり、GitLab Duo Enterpriseをご利用のすべてのGitLab Self-Managedのお客様が利用できます。

GitLab Duo Self-Hostedのハイブリッドモデルにより、GitLab Self-Managedのインスタンス管理者は、機能ごとにセルフホストモデルとAIゲートウェイ、またはGitLab AIベンダーモデルとGitLabホスト型AIゲートウェイを選択できるようになりました。これにより、管理者はセキュリティとスケーラビリティの要件のバランスを取ることができます。ハイブリッドモデル選択に関するフィードバックは、[イシュー561048](https://gitlab.com/gitlab-org/gitlab/-/issues/561048)をご覧ください。

### コンプライアンスフレームワークコントロールの違反の表面化（ベータ版） {#surfacing-violations-of-compliance-framework-controls-beta}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_violations_report.md)

{{< /details >}}

以前は、コンプライアンス違反レポートは、グループ内のすべてのプロジェクトにおけるMRアクティビティの概要を提供していました。職務分離の懸念に関連する利用可能なコンプライアンス違反は次のとおりです:

- MRの作成者が自身のMRを承認した場合を検出します。
- MRが2つ未満の承認でマージされた場合。

しかし、ユーザーからのフィードバックによると、違反分類が実際のコンプライアンスユースケースと十分に整合していないため、混乱し理解しにくいということが判明しました。

GitLab 18.3では、違反レポートを大幅に強化し、職務分離を超えてコンプライアンスフレームワークにおけるコンプライアンスコントロールと要件の違反を含めるように拡張しました。各カスタムコンプライアンスフレームワークコントロールには、違反に関する詳細なコンテキストを提供する関連監査イベントがあります。具体的には、誰が違反を犯したのか、いつ発生したのか、どのように修正するのかなどです。これにはユーザー名とIPアドレス、さらに実用的な修正の提案が含まれます。

これらの改善により、コンプライアンスマネージャーは、組織が特定のコンプライアンスフレームワークを遵守していることを確認するための、より強力で関連性の高いコンテキストを得ることができ、同時に、非コンプライアンスを効果的に特定、是正、防止できるという安心感も得られます。

### 新しいWeb IDEのソース管理操作 {#new-web-ide-source-control-operations}

<!-- categories: Web IDE -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/web_ide/_index.md#use-source-control)

{{< /details >}}

Web IDEにおける追加のソース管理機能の発表を嬉しく思います。ブラウザを離れることなく、Gitワークフローをより効率的に管理できます。**Source Control**パネルで、次のことができるようになりました:

- ブランチを作成および削除します。
- 既存のブランチからブランチを作成し、それをベースとします。
- 最後のコミットを修正して、すばやく修正します。
- インターフェースから直接変更を強制プッシュします。

これらの機能強化により、Git操作をすぐに利用できるようになります。利用可能な機能については、[ソース管理を使用](../../user/project/web_ide/_index.md#use-source-control)を参照してください。

### AWS Secrets ManagerのGitLab CI/CDサポート {#aws-secrets-manager-support-for-gitlab-cicd}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../ci/secrets/aws_secrets_manager.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17822)

{{< /details >}}

AWS Secrets Managerに保存されているシークレットを、CI/CDジョブで簡単に取得して使用できるようになりました。AWSとの新しいインテグレーションにより、GitLab CI/CDを介したAWS Secrets Managerとのやり取りのプロセスが簡素化され、AWSのお客様のビルドおよびデプロイプロセスが合理化されます！

[Markus Siebert](https://gitlab.com/m-s-db)と[Henry Sachs](https://gitlab.com/DerAstronaut)がGitLabの[共同開発プログラム](https://about.gitlab.com/community/co-create/)を通じてこの機能の構築を支援してくれたことに感謝します！

### カスタム管理者ロール {#custom-admin-role}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15069)

{{< /details >}}

カスタム管理者ロールは、GitLab Self-ManagedおよびGitLab Dedicatedのインスタンスに対して、管理者エリアにきめ細かい権限をもたらします。完全なアクセス権を付与する代わりに、管理者はユーザーが必要とする特定の機能のみにアクセスできる特殊なロールを作成できるようになりました。この機能は、組織が管理機能の最小権限の原則を実装し、過剰な権限によるアクセスから生じるセキュリティリスクを軽減し、運用の効率性を向上させるのに役立ちます。

ご質問がある場合、実装経験を共有したい場合、または改善の可能性についてチームと直接関わりたい場合は、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509376)をご覧ください。

## エージェント型コア {#agentic-core}

### GitLab Duo Self-Hostedで使用できるモデルの追加 {#more-models-available-for-use-with-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/560016)

{{< /details >}}

GitLab Duo Enterpriseをご利用のGitLab Self-Managedのお客様は、Anthropic Claude 4をGitLab Duo Self-Hostedで使用できるようになりました。Claude 4はAWS Bedrockでサポートされています。オープンソースのOpenAI GPT OSS 20Bおよび120Bが実験モデルとして追加され、vLLM、Azure OpenAI、およびAWS Bedrockで利用可能です。これらのモデルをGitLab Duo Self-Hostedで使用することに関するフィードバックは、[イシュー523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918)をご覧ください。

## 規模とデプロイ {#scale-and-deployments}

### あなたの作業でのグループ向け新しいナビゲーションエクスペリエンス {#new-navigation-experience-for-groups-in-your-work}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/_index.md#group-visibility) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/502487)

{{< /details >}}

**あなたの作業**のグループ概要が大幅に改善されたことを発表できることを嬉しく思います。これにより、グループの発見とアクセスが効率化されます。新しいタブ付きインターフェースには、アクセス可能なグループの包括的なビューを提供する**メンバー**タブと、削除待ちのグループを追跡する**非アクティブ**タブが含まれています。また、適切な権限を持つユーザー向けに、リストビューに**編集**アクションと**削除**アクションを追加することで、グループ管理を効率化しました。これらの改善により、お客様にとって最も重要なグループを見つけて管理することが容易になることを願っています。

この更新に関するフィードバックを歓迎します！新しいナビゲーションシステムでの経験を共有するために、[エピック18401](https://gitlab.com/groups/gitlab-org/-/epics/18401)でのディスカッションにご参加ください。

### 強化された**管理者**エリアプロジェクトリスト {#enhanced-admin-area-projects-list}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/admin_area.md#administering-projects) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17782)

{{< /details >}}

GitLab管理者に、より一貫したエクスペリエンスを提供するために、**管理者**エリアプロジェクトリストをアップグレードしました:

- 遅延削除保護: プロジェクトの削除は、GitLab全体で使用されている安全な削除フローと同じになり、偶発的なデータ損失を防ぎます。
- より高速な操作: ページのリロードなしでプロジェクトをフィルター、ソート、ページ分割し、より応答性の高いエクスペリエンスを実現します。
- 一貫したインターフェース: プロジェクトリストは、GitLab全体の他のプロジェクトリストの外観と動作に一致するようになりました。

この更新により、管理者のエクスペリエンスがGitLabのデザイン標準に準拠し、データを保護するための重要な安全機能が追加されます。今後のプロジェクト管理の機能強化は、プラットフォーム全体のすべてのプロジェクトリストに自動的に表示されます。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### 依存関係スキャンアナライザーのファイル場所情報の改善 {#improved-file-location-information-for-dependency-scanning-analyzer}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#customizing-behavior-with-the-cicd-template) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/537716)

{{< /details >}}

依存関係のソースをトレースできることは、特に脆弱性の修正において重要です。以前は、依存関係スキャンアナライザーは、期限切れになったジョブアーティファクトにリンクされることがありました。これにより、依存関係のソースをトレースすることが困難になっていました。依存関係スキャンアナライザーは、依存関係を導入したプロジェクトファイルにリンクできるようになりました。このオプションを有効にすると、依存関係リストおよび脆弱性レポート内のリンクは信頼できます。ユーザーは、依存関係スキャンジョブに対して`DS_FF_LINK_COMPONENTS_TO_GIT_FILES=true`を設定することで、この機能を有効にできます。

### ライセンス情報のユーザー定義ソース {#user-defined-source-for-license-information}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#use-cyclonedx-report-as-a-source-of-license-information) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/501662)

{{< /details >}}

ユーザーは、GitLabライセンスデータベースとCycloneDX SBOMレポートのどちらのライセンス情報ソースを優先するかを選択できるようになりました。これにより、ユーザーはオープンソース依存関係のライセンス情報の調達において、より高い柔軟性を得ることができます。ライセンス情報のソースを定義したいユーザーは、[セキュリティ設定UI](../../user/application_security/detect/security_configuration.md#with-the-ui)を使用して選択できます。デフォルトでは、ライセンス情報のソースとしてSBOMデータを使用します。

### 簡潔なDASTジョブ出力 {#concise-dast-job-output}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dast/browser/troubleshooting.md#what-is-dast-doing) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18342)

{{< /details >}}

GitLab 18.3では、動的な解析セキュリティテストジョブの出力にいくつかの改善が導入されました。

この改善されたジョブ出力は、スキャン結果を理解し、障害をトラブルシューティングするのに役立つ明確で構造化された情報を提供します。

ジョブ出力の各セクションは簡潔で直感的であり、出力の下部にはトラブルシューティングドキュメントへのリンクがあります。簡潔なジョブ出力をオーバーライドするには、DAST設定で`DAST_FF_DIAGNOSTIC_JOB_OUTPUT: "true"`を設定します。

### インスタンスレベルのコンプライアンスおよびセキュリティポリシー管理（ベータ版） {#instance-level-compliance-and-policy-management-beta}

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)

{{< /details >}}

エンタープライズユーザーは、複数のトップレベルグループにわたってコンプライアンスフレームワークとセキュリティポリシーを管理したいと考えています。これは、インスタンス内のすべてのグループが次の場合によく当てはまります:

- 同じコンプライアンスフレームワークを共有します。たとえば、グループ内のすべてのプロジェクトがISO 27001標準に準拠する必要がある場合などです。
- 同様のセキュリティポリシーを適用します。たとえば、すべてのグループが同じパイプライン実行ポリシーを共有する場合などです。

GitLab 18.3では、GitLab Self-Managedインスタンス向けにコンプライアンスおよびセキュリティポリシー管理がベータ版で利用できるようになりました。単一のトップレベルグループからコンプライアンスフレームワークとセキュリティポリシーを作成、設定、割り当て、そしてGitLab Self-Managedインスタンス全体の他のすべてのトップレベルグループにそれらを適用できるようになりました。

コンプライアンスおよびセキュリティポリシーのトップレベルグループを使用すると、コンプライアンスフレームワークとセキュリティポリシーを管理および編集できる信頼できる唯一の情報源が手に入ります。グループ管理者は、これらのコンプライアンスフレームワークとセキュリティポリシーをそれらのグループ内のすべてのプロジェクトに適用できます。

選択したトップレベルグループから主要なフレームワークとセキュリティポリシーを管理することで、GitLab Self-Managedインスタンス全体で主要なコンプライアンスとセキュリティ要件を管理および実施することが容易になります。ただし、グループは、それらのグループで発生する可能性のある特定の状況またはワークフローに対処するために、独自のコンプライアンスフレームワークとセキュリティポリシーを作成する機能を保持しています。

この機能はGitLab Self-Managedのお客様向けです。なぜなら、GitLab.comおよびGitLab Dedicatedのお客様は、すでに単一のトップレベルグループまたはネームスペース内でポリシーを一元的に管理できるためです。

### シャロークローンによるワークスペースの高速起動 {#faster-workspace-startup-with-shallow-cloning}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/workspace/_index.md#shallow-cloning)

{{< /details >}}

ワークスペースは、起動時間を短縮するためにシャロークローンを使用するようになりました。初期化中、GitLabは完全なGit履歴ではなく、最新のコミット履歴のみをダウンロードします。ワークスペースが起動した後、Gitはシャロークローンをバックグラウンドでフルクローンに変換します。

この機能はすべての新しいワークスペースに自動的に適用され、設定は不要であり、開発ワークフローに影響を与えません。

### GitLab管理のOpenTofuおよびTerraformステート用新しいCLIコマンド {#new-cli-commands-for-gitlab-managed-opentofu-and-terraform-states}

<!-- categories: GitLab CLI, Infrastructure as Code -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/infrastructure/iac/terraform_state.md) | [関連イシュー](https://gitlab.com/gitlab-org/cli/-/issues/7954)

{{< /details >}}

GitLab CLI（`glab`）に、新しいトップレベルコマンド`opentofu`が追加されました。`opentofu`コマンドは、GitLab管理のOpenTofuおよびTerraformステートを支援するために、`terraform`および`tf`コマンドにエイリアスされています。

次のコマンドが追加されました:

- `glab opentofu init`: ステートバックエンドをローカルで初期化します。
- `glab opentofu state list`: プロジェクト内のすべてのステートをリストします。
- `glab opentofu state download`: 最新のステートまたは特定のバージョンをダウンロードします。
- `glab opentofu state delete`: ステート全体または特定のバージョンを削除します。
- `glab opentofu state lock`: ステートをロックします。
- `glab opentofu state unlock`: ステートをアンロックします

`opentofu`コマンドでステートを管理するには、少なくとも`glab` 1.66以降が必要です。

### Kubernetes 1.33のサポート {#kubernetes-133-support}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/538906)

{{< /details >}}

GitLabはKubernetesバージョン1.33を完全にサポートするようになりました。アプリをKubernetesにデプロイする場合、接続されたクラスターを最新バージョンにアップグレードし、そのすべての機能を活用できます。

詳細については、[GitLab機能でサポートされているKubernetesバージョン](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)を参照してください。

### OAuthアプリのSSO認証サポート {#oauth-apps-support-sso-authentication}

<!-- categories: Pages, System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../api/oauth2.md#authorization-code-flow)

{{< /details >}}

OAuthアプリケーションは、組織のシングルサインオン要件とシームレスにインテグレーションできるようになりました。以前は、ユーザーはまずGitLabで認証し、次にSSOで認証するする必要があり、不要な摩擦と複雑さを生じていました。

現在、OAuthアプリケーションは、必要に応じてSSO認証を自動的にトリガーするために、認可リクエストでパラメータを指定できます。これにより、次のものが提供されます:

- ユーザー向け統合認証エクスペリエンス
- 組織のSSOポリシーへの自動コンプライアンス
- すべてのGitLabインテグレーションにおける一貫したセキュリティ
- パラメータを追加するだけで、デベロッパー向けのシンプルな実装

お客様のOAuthインテグレーションはSSOポリシーを自動的に尊重するようになり、混乱を招く認証ワークフローを排除しつつセキュリティを維持します。

### GitLab Pagesサイトのユニークドメインのデフォルトを制御する {#control-unique-domains-default-for-gitlab-pages-sites}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../administration/pages/_index.md#disable-unique-domains-by-default)

{{< /details >}}

管理者は、新しいGitLab Pagesサイトのユニークドメインのデフォルト動作を設定できるようになりました。デフォルトでは、新しいPagesサイトはサイト間のクッキー共有を防ぐためにユニークなドメインURL（`my-project-1a2b3c.example.com`など）を使用します。

インスタンスのこの新しい設定により、新しいPagesサイトをデフォルトでパスベースのURL（`my-namespace.example.com/my-project`など）を使用するように設定できます。これにより、組織はGitLab Pagesの動作をワークフローとセキュリティ要件に合わせることができます。

ユーザーは個々のプロジェクトに対してこの設定をオーバーライドできますが、既存のPagesサイトには影響しません。

### Wiki機能の強化 {#enhancements-to-wiki-functionality}

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/discussions/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16403)

{{< /details >}}

このリリースでは、Wikiエクスペリエンスが3つの主要な改善によって強化されました。具体的には、Wikiページを購読したり、ページ編集中にWikiコメントを表示したり、Wikiページコメントをソートしたりできるようになりました。

これらの機能強化により、チームはドキュメントでより効果的にコラボレーションできるようになります:

- コンテキスト内で直接コンテンツをディスカッションします。
- 改善点と修正点を提案します。
- ドキュメントを正確かつ最新の状態に保ちます。
- 知識と専門知識を共有します。

これらの更新により、GitLab Wikiは、直接的なフィードバックとディスカッションを通じてプロジェクトとともに進化する生きたドキュメントとなります。

### エピックの担当者、マイルストーンなどの一括編集 {#bulk-edit-epic-assignees-milestones-and-more}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md#bulk-edit-epics) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11901)

{{< /details >}}

グループ内のより多くのエピック属性を一括編集できるようになりました。ラベルに加えて、複数のエピックの担当者、ヘルスステータス、サブスクリプション、機密性、およびマイルストーンを一度に更新できるようになりました。

この機能強化により、複数のエピックに同じ変更を同時に適用することで、多数のエピックをより迅速に管理できます。

### API経由でCI/CD設定へのアクセスをパイプライン実行ポリシーに付与する {#grant-pipeline-execution-policies-access-to-cicd-configurations-via-api}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../api/projects.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/524124)

{{< /details >}}

Projects REST APIを使用して、新しい`spp_repository_pipeline_access`フィールドでセキュリティポリシープロジェクト内の**パイプライン実行ポリシー**設定をプログラムで有効または無効にできます。以前は、この設定はGitLab UIを通じてのみ管理可能でした。この強化により、次のことができるようになりました:

- 現在の**パイプライン実行ポリシー**ステータスを`GET`する。
- 設定をプログラムで有効または無効にするために`PUT`します。

この改善は、スケールでセキュリティポリシーを管理するチーム向けのより良い自動化とインテグレーションワークフローを可能にします。

### 脆弱性レポートでのOWASP 2021によるグループ化 {#group-by-owasp-2021-in-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#advanced-vulnerability-management) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/532703)

{{< /details >}}

プロジェクトおよびグループの脆弱性レポートでは、脆弱性をOWASP Top 10 2021カテゴリでグループ化できるようになりました。GitLab.comおよびGitLab Dedicatedインスタンスでのみ利用可能です。

### スキャン実行ポリシーテンプレート {#scan-execution-policy-templates}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/scan_execution_policies.md#scan-execution-policy-editor) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11919)

{{< /details >}}

スキャン実行ポリシーテンプレートは、一般的なユースケースに基づいてスキャン実行ポリシーを迅速に作成するのに役立ちます。3つのテンプレートから選択してください:

- MRセキュリティ
- スケジュールされたスキャン
- リリースセキュリティ

テンプレートを選択したら、どのGitLabセキュリティスキャンをテンプレートで有効にするかを選択して、すぐに開始できます。より高度なユースケースがある場合は、カスタム設定に切り替えて、特定のブランチパターン、パイプラインソースなどでポリシーを拡張できます。

### セキュリティポリシー監査イベント {#security-policy-audit-events}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/audit_event_streaming.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15869)

{{< /details >}}

GitLab Ultimateは、各セキュリティポリシープロジェクト内でイベントが整理および一元化された、セキュリティポリシー管理のための包括的な監査イベントを提供するようになりました。

セキュリティチームは次のことができるようになりました:

- 詳細なメタデータで、すべてのポリシー変更を追跡します。
- スキャンおよびパイプライン実行の失敗を含む、強制の失敗を監視します。
- スキップされたスキャン実行およびパイプライン実行のパイプラインを監視します。
- ポリシー違反でマージされたMRを含む、各プロジェクト内のポリシー違反を検出します。
- 制限を超過した場合にアラートを受信します。
- ポリシー設定エラーを検出します。
- 大容量シナリオでは、ストリーミングのみのオプションを使用します。

新しい監査イベントは次のとおりです:

- [security_policy_create](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_create](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_create.yml).yml)
- [security_policy_delete](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_delete](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_delete.yml).yml)
- [security_policy_update](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_update](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_update.yml).yml)
- [security_policy_merge_request_merged_with_policy_violations](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_merge_request_merged_with_policy_violations](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_merge_request_merged_with_policy_violations.yml).yml)
- [security_policy_yaml_invalidated](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_yaml_invalidated](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_yaml_invalidated.yml).yml)
- [security_policies_limit_exceeded](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_yaml_invalidated.yml)
- [security_policy_violations_detected](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_violations_detected](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_violations_detected.yml).yml) (ストリーミングのみ)
- [security_policy_pipeline_failed](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_pipeline_failed](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_pipeline_failed.yml).yml) (ストリーミングのみ)
- [security_policy_pipeline_skipped](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_pipeline_skipped](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_pipeline_skipped.yml).yml) (ストリーミングのみ)
- [merge_request_branch_bypassed_by_security_policy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/audit_events/types/[merge_request_branch_bypassed_by_security_policy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/audit_events/types/merge_request_branch_bypassed_by_security_policy.yml).yml)

この強化は、セキュリティポリシー変更、設定エラー、および適用ギャップへのアクセスを保証することで、お客様のセキュリティ対策状況を強化し、より迅速なインシデント対応と徹底した監査機能を実現します。

### 承認ポリシーに対するサービスアカウントおよびアクセストークンの例外 {#service-account-and-access-token-exceptions-for-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#access-token-and-service-account-exceptions) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18112)

{{< /details >}}

新しい**Service Account & Access Token Exceptions**機能により、必要に応じてサービスアカウントとアクセストークンをマージリクエスト承認ポリシーをバイパスするように指定できます。これにより、既知の自動化の摩擦が排除され、セキュリティコントロールが維持されます。

**主な機能は次のとおりです:**

- 自動化されたワークフローのサポート: 特定のサービスアカウント、ボットユーザー、グループアクセストークン、およびプロジェクトアクセストークンを設定して、CI/CDパイプライン、プルミラーリング、および自動バージョン更新の承認要件をバイパスすることができます。サービスアカウントは、承認されたトークンを使用して保護ブランチに直接プッシュすることができますが、人間ユーザーの制限は維持されます。
- 緊急アクセスと監査: 包括的な監査証跡により、重大なインシデントに対するブレークグラスシナリオを有効にします。すべてのバイパスイベントは、コンテキストと理由付けを含む詳細な監査ログを生成し、コンプライアンス要件をサポートしつつ、停止やセキュリティ修正中の迅速な対応を可能にします。
- GitOpsインテグレーション: リポジトリのミラーリング、外部CIシステム（Jenkins、CloudBees）、自動変更履歴生成、GitFlowリリースプロセスなどの一般的な自動化の課題を解決します。サービスアカウントは、特定のプロジェクトとブランチにスコープされたトークンベースのアクセスを持つ最小アクセス権限を受け取ります。

この強化により、現代のDevOps自動化ニーズに対する柔軟性のある厳格なセキュリティポリシーが維持され、カスタム回避策を排除しつつガバナンスコントロールを保持します。

### セッションタイムアウト属性に対するSAML SSOサポート {#saml-sso-support-for-session-timeout-attribute}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/saml_sso/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/262074)

{{< /details >}}

GitLabは、Identity Provider（IdP）からのSAMLアサーション内の`SessionNotOnOrAfter`属性を自動的に検出し、尊重するようになりました。この属性が存在する場合、GitLabはユーザーセッションをIdPによって指定された時間に有効期限が切れるように設定し、組織全体で一貫したセッション管理を保証します。この機能は設定変更を必要としません。IdPが属性を提供する場合、GitLabは指定された有効期限を自動的に尊重します。

### 追加のサービスアカウントメール設定オプション {#additional-service-account-email-configuration-options}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/profile/service_accounts.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/537976)

{{< /details >}}

デフォルトでは、GitLabは新しいサービスアカウント向けにメールアドレスを自動的に生成します。組織は、UIを通じてサービスアカウントにカスタムメールアドレスを割り当てることができるようになりました。以前は、カスタムメール設定はサービスアカウントAPIを通じてのみ可能でした。この変更により、組織は指定されたメールアドレスに通知をより適切にルーティングできるようになります。

### エンタープライズユーザーの強化 {#enterprise-user-enhancements}

<!-- categories: System Access -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/enterprise_user/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9262)

{{< /details >}}

GitLab 18.3では、組織がユーザーのプライバシーとライフサイクル管理をより詳細に制御できるエンタープライズユーザーの機能強化が導入されました。

グループオーナーは、Users APIを使用して、独自のネームスペース内のエンタープライズユーザーを削除できるようになりました。この破壊的なアクションは、ユーザーのコントリビュートを解除し、システム全体のGhostユーザーに関連付けます。このオプションは、自動SCIMインポートで誤って作成されたユーザーのクリーンアップや、ユーザー名とメールの再利用が必要なフェデレーション環境の管理に特に価値があります。

さらに、組織はユーザープロフィールでエンタープライズユーザーのメールを非表示にできるようになり、すべてのエンタープライズユーザーに対してより広範なメールプライバシーの強制を提供します。

### SSHキーセキュリティ警告 {#ssh-key-security-warnings}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/ssh.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/432624)

{{< /details >}}

ユーザーが脆弱なSSHキーをアップロードしたときに、GitLab UIにセキュリティ警告が表示されるようになりました。この警告は、古いキータイプまたはビット長が不十分なキー（2048ビット未満）に対して表示されます。この変更は、SSHキーセキュリティのベストプラクティスについてユーザーを教育し、より強力な暗号学的キーの使用を奨励するのに役立ちます。

### GitLab Runner 18.3 {#gitlab-runner-183}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.3もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### バグ修正 {#bug-fixes}

- [GitLab 18.2.0では、Runnerはサブディレクトリファイルをキャッシュキーとして使用してジョブキャッシュをプルできません](https://gitlab.com/gitlab-org/gitlab/-/issues/556464)
- [Docker executorが断続的にジョブの開始に失敗し、`incorrect username or password`エラーメッセージを返します。](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38707)
- [`*_get_sources`フックの使用における`none`と`empty` Git戦略間の不整合](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38703)
- [非OLMマニフェストでデプロイされたオペレーターが誤ったデフォルトイメージを想定](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/228)
- [CRに`app.kubernetes.io/instance`ラベルがある場合、オペレーターが誤った名前でConfigMapを作成](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/183)
- [OpenShift 4.9上のオペレーター1.10.0が、Runner ConfigMapの作成に失敗し、`gitlab-runner`ネームスペースでポッドを開始できません](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/138)

#### 新機能 {#whats-new}

- [GitLab Runner OperatorがRunnerマネージャーポッドアノテーションをサポート](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/245)
- [GitLab Runner OperatorがOpenShift 4.19をサポート](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/253)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-3-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-3-stable/CHANGELOG.md).md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.3)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.3)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.3)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
