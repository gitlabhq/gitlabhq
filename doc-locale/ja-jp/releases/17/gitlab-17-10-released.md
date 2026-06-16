---
stage: Release Notes
group: Monthly Release
date: 2025-03-20
title: "GitLab 17.10リリースノート"
description: "GitLab 17.10がDuo Code Reviewのベータ版としてリリースされました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年3月20日、GitLab 17.10は以下の機能を搭載してリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Alexey Butkeev {#this-months-notable-contributor-alexey-butkeev}

誰もがGitLabコミュニティのコントリビューターを[推薦](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)できます！活躍中の候補者を支援するか、新しい推薦を追加してください！ 🙌

[Alexey Butkeev](https://gitlab.com/abutkeev)は、世界的なリーチとUXを強化するコントリビュートをしている、高く評価されているコミュニティのコントリビューターです。彼のインパクトのあるローカライズと翻訳に対するコントリビュートは、当社の多様性、包括性、帰属意識の価値を体現しています。

「17.10のMVPに選ばれ、GitLabをより利用しやすく包括的にすることに貢献できることを光栄に思います」とAlexeyは述べています。「ローカライズはチームの取り組みであり、このような協力的なコミュニティの一員であることを感謝しています。」

彼のコードコントリビュートに加えて、AlexeyはGitLabとCrowdinを介して翻訳エラーを見つけ、文書化し、修正するイニシアチブを取りました。彼の徹底した調査と問題解決が、彼を17.10 MVPにしています。

Alexeyは、GitLabのグローバリゼーションテクノロジーのシニアマネージャーである[Oleksandr Pysaryuk](https://gitlab.com/opysaryuk)によって推薦され、GitLabのグローバリゼーション＆ローカライズ担当ディレクターである[Daniel Sullivan](https://gitlab.com/djsulliv)によってサポートされました。「GitLabでのあなたの仕事とサポートに深く感謝しています」とDanielは述べています。「私たちがよりグローバルにサポートされる企業になるのを助けてくれてありがとう！」

GitLabをより包括的で透明性の高いものにしてくれたAlexeyに感謝します！

## 主要な機能 {#primary-features}

### Duo Code Reviewがベータ版で利用可能に {#duo-code-review-available-in-beta}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code)

{{< /details >}}

コードレビューは、ソフトウェア開発の重要な活動です。それは、プロジェクトへのコントリビュートがコード品質とセキュリティを維持および改善し、エンジニアにとってメンターシップとフィードバックの道となることを保証します。また、ソフトウェア開発プロセスにおいて最も時間のかかる活動の1つでもあります。

Duo Code Reviewは、コードレビュープロセスの次の進化です。

Duo Code Reviewは、開発プロセスを加速できます。マージリクエストで初期レビューを実行すると、潜在的なバグを特定し、さらなる改善を提案するのに役立ちます。その一部はブラウザから直接適用できます。イテレーションを行い、別の人間をループに追加する前に変更を改善するために使用してください。

**Try it out:**

- コードレビューをすぐに開始するには、マージリクエストに`@GitLabDuo`をレビュアーとして追加します。
- 変更に関するフィードバックを改善するには、コメントで`@GitLabDuo`に言及してください。

Duo Code Reviewの今後の進捗状況は、エピック[13008](https://gitlab.com/groups/gitlab-org/-/epics/13008)および関連する子エピックで追跡できます。フィードバックはイシュー[517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)で提供できます。

### GitLab Duo Self-Hostedで根本原因分析が利用可能に {#root-cause-analysis-available-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/_index.md#feature-versions-and-status) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13759)

{{< /details >}}

GitLab Duo Self-Hostedで[GitLab Duo根本原因分析](https://about.gitlab.com/blog/developing-gitlab-duo-blending-ai-and-root-cause-analysis-to-fix-ci-cd/)が利用できるようになりました。この機能は、GitLab Duo Self-Hostedを使用するGitLab Self-Managedインスタンス向けにベータ版として提供されており、Mistral、Anthropic、およびOpenAI GPTモデルファミリーをサポートしています。

GitLab Duo Self-Hostedの根本原因分析を使用すると、データ主権を損なうことなく、CI/CDパイプラインで失敗したジョブのトラブルシューティングをより迅速に行うことができます。根本原因分析は、失敗したジョブログを分析し、ジョブの失敗の根本原因を迅速に特定し、修正を提案します。

注: この機能は現在、機能が制限されており、完全な機能は17.11で計画されています。追加情報は[トラブルシューティングドキュメント](../../administration/gitlab_duo_self_hosted/troubleshooting.md#feature-not-accessible-or-feature-button-not-visible)およびイシュー[527128](https://gitlab.com/gitlab-org/gitlab/-/issues/527128)で利用できます。

GitLab Duo Self-Hosted向け根本原因分析に関するフィードバックは、[イシュー523912](https://gitlab.com/gitlab-org/gitlab/-/issues/523912)にお寄せください。

### GitLab Dedicatedのフェイルオーバーインスタンスで利用可能な拡張AWSリージョン {#expanded-aws-regions-available-for-gitlab-dedicated-failover-instances}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- プラン: Gold
- リンク: [ドキュメント](../../administration/dedicated/create_instance/data_residency_high_availability.md)

{{< /details >}}

GitLab Dedicatedの顧客は、フェイルオーバーインスタンスをホストする場所を選択する際に、拡張されたAWSリージョンのリストから選択できるようになりました。[ディザスターリカバリー](../../administration/dedicated/disaster_recovery.md)のためです。

追加のフェイルオーバーサポートを拡張することで、GitLab Dedicatedの顧客は、データレジデンシーのニーズを満たすためにどのAWSリージョンを使用する必要があるかに関わらず、GitLab Dedicatedのディザスターリカバリー機能を完全に利用できます。

これらの新しく利用可能なリージョンは、フェイルオーバーインスタンスのホスティングにのみ利用できます。これは、GitLab Dedicatedが依存する特定のAWS機能を完全にサポートしていないためです。

### GitLab Query Language（GLQL）ビューベータ版 {#gitlab-query-language-views-beta}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/glql/_index.md#embedded-views) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14938)

{{< /details >}}

GitLab全体で進行中の作業を追跡し、理解するには、これまで複数の場所をナビゲートする必要があり、チームの効率性を低下させ、貴重な時間を消費していました。

このリリースでは、GLQLビューのベータ版が導入され、既存のワークフローで動的かつリアルタイムの作業追跡を直接作成できます。

GLQLビューは、Wikiページ、エピックの説明、イシューコメント、およびマージリクエスト全体のMarkdownコードブロックにライブデータクエリを埋め込みます。

以前は実験的な機能として利用可能でしたが、GLQLビューは現在、割り当て先、作成者、ラベル、マイルストーンなどの主要フィールド全体で論理式と演算子を使用した高度なフィルタリングをサポートするベータ版に移行しました。ビューの表示をテーブルまたはリストとしてカスタマイズし、表示されるフィールドを制御し、結果の制限を設定して、チーム向けの焦点を絞った実用的なインサイトを作成できます。

チームは、必要な情報にアクセスしながらコンテキストを維持し、共通の理解を形成し、コラボレーションを改善できます。これらすべてを現在のワークフローを離れることなく行えます。

この機能の強化を継続するにあたり、GLQLビューに関する[フィードバックをお待ちしております](https://gitlab.com/gitlab-org/gitlab/-/issues/509791)。

### 強化されたMarkdownエクスペリエンス {#enhanced-markdown-experience}

<!-- categories: Markdown -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/markdown.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/7654)

{{< /details >}}

GitLab Flavored Markdownは、いくつかの強力な改善によって強化されました:

- **Improved math and image handling**:
  - グループまたはセルフホストインスタンスで[数式レンダリング](../../user/markdown.md#math-equations)の制限を無効にして、より複雑な数式を処理できるようにします。
  - ピクセル値またはパーセンテージを使用して[画像サイズ](../../user/markdown.md#change-image-or-video-dimensions)を正確に制御し、コンテンツのレイアウトをより適切に管理します。
- **Enhanced editor experience**:
  - Enter/Returnを押すと、リストが自動的に継続されます。
  - キーボードショートカットを使用して、テキストを左右にシフトします。
  - 説明リスト構文を使用して、明確な用語定義のペアを作成します。
  - 動画の幅を柔軟に調整します。
- **Better content organization**:
  - 自動展開する[要約クイックビュー](../../user/markdown.md#show-item-summary)（URLに`+s`を追加）でコンテンツをより簡単にナビゲートします。
  - 参照されている[イシューのタイトル](../../user/markdown.md#show-item-title)が自動的にレンダリングされます（URLに`+`を追加）。
  - [`include`構文](../../user/markdown.md#includes)を使用して、コンテンツをモジュール式に整理します。
  - [アラートボックス](../../user/markdown.md#alerts)を使用して、視覚的に異なるコールアウトと警告を作成します。

これらの改善により、GitLab Flavored Markdownは、ドキュメントを作成および保守するチームにとってより強力になり、コンテンツの提示方法と整理方法においてより大きな柔軟性を提供します。

### プロジェクト全体でのDevOpsパフォーマンスのDORAメトリクスによる新しい可視化 {#new-visualization-of-devops-performance-with-dora-metrics-across-projects}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/value_streams_dashboard.md#projects-by-dora-metric) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/408516)

{{< /details >}}

[Value Streams Dashboard](https://www.youtube.com/watch?v=EA9Sbks27g4)に新たに加わった**Projects by DORA metric**パネルをご紹介できることを嬉しく思います。この表には、トップレベルグループ内のすべてのプロジェクトが、[4つのDORAメトリクス](https://about.gitlab.com/solutions/value-stream-management/dora/#overview)に分類されて表示されます。マネージャーは、この表を使用して、ハイ、ミディアム、および低パフォーマンスのプロジェクトを特定できます。この情報は、データに基づいた意思決定を行い、リソースを効果的に割り当て、ソフトウエアデリバリーの速度、安定性、信頼性を向上させるイニシアチブに焦点を当てるのにも役立ちます。

The [DORAメトリクス](../../user/analytics/dora_metrics.md)はGitLabで標準で利用可能であり、[**DORA Performers score**パネル](https://about.gitlab.com/blog/inside-dora-performers-score-in-gitlab-value-streams-dashboard/)と組み合わせることで、経営陣は組織のDevOpsの健全性を全体的に把握できます。

### 新しいイシューの見た目がベータ版で登場 {#new-issues-look-now-in-beta}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/issues/_index.md)

{{< /details >}}

イシューは、エピックやタスクと共通のフレームワークを共有するようになり、リアルタイム更新とワークフローの改善が特徴です:

- **Drawer view:** リストまたはボードから項目をドロワーで開くと、現在のコンテキストを離れることなく素早く表示できます。上部にあるボタンで全ページ表示に展開できます。
- **Change type:** 「種類の変更」アクション（「エピックにプロモート」を置き換えます）を使用して、エピック、イシュー、タスク間でタイプを変換します。
- **開始日:** イシューがエピックおよびタスクと機能を合わせて開始日をサポートするようになりました。
- **Ancestry:** 完全な階層は、サイドバーのタイトルと親フィールドの上に表示されます。関係を管理するには、新しい[クイックアクション](../../user/project/quick_actions.md)コマンド`/set_parent`、`/remove_parent`、`/add_child`、および`/remove_child`を使用します。
- **Controls:** すべての操作は、トップメニュー（縦方向の省略記号）からアクセスできるようになり、スクロール時もスティッキーヘッダーに表示されたままになります。
- **Development:** イシューまたはタスクに関連するすべての開発項目（マージリクエスト、ブランチ、および機能フラグ）が、単一の便利なリストに統合されました。
- **Layout:** UIの改善により、イシュー、エピック、タスク、およびマージリクエスト間のエクスペリエンスがよりシームレスになり、ワークフローをより効率的にナビゲートできるようになります。
- **Linked items:** 改善されたリンクオプションを使用して、タスク、イシュー、エピック間の関係を作成します。ドラッグ＆ドロップでリンクタイプを変更し、ラベルとクローズされた項目の表示レベルを切り替えます。

### エピック、イシュー、タスク、目標と主な成果（OKR）の説明テンプレート {#description-templates-for-epics-issues-tasks-objectives-and-key-results}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/description_templates.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16088)

{{< /details >}}

これで、説明テンプレートを使用することで、ワークフローを効率化し、作業アイテム（エピック、タスク、OKR）全体で一貫性を維持できます。

この強力な追加機能により、標準化されたテンプレートを作成できるため、時間を節約し、新しい作業アイテムを作成するたびにすべての重要な情報が確実に含まれるようになります。

### 脆弱性の重大度を変更 {#change-the-severity-of-a-vulnerability}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#change-or-override-vulnerability-severity) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/16157)

{{< /details >}}

脆弱性をトリアージする際、組織独自のセキュリティコンテキストとリスク許容度に基づいて重大度レベルを調整する柔軟性が必要です。これまで、セキュリティスキャナーによって割り当てられたデフォルトの重大度レベルに依存する必要がありましたが、これは特定の環境のリスクレベルを正確に反映していない可能性があります。

これで、特定の脆弱性発生の重大度を手動で変更して、組織のセキュリティニーズにより適切に合わせることができます。これにより、次のことが可能になります:

- 任意の脆弱性の重大度レベルを**クリティカル**、**高**、**中**、**低**、**情報**、または**不明**に調整します。
- 脆弱性レポートから複数の脆弱性の重大度を一度に変更します。
- どの脆弱性にカスタム重大度レベルがあるかを視覚的なインジケーターで簡単に特定できます。

すべての重大度の変更は、脆弱性履歴および監査イベントで追跡され、プロジェクトのメンテナーロール以上を持つチームメンバー、または`admin_vulnerability`パーミッションを持つカスタムロールによってのみ上書きできます。この機能により、セキュリティチームは脆弱性の優先順位付けにおいて、より高い柔軟性と制御を得ることができます。

## エージェント型コア {#agentic-core}

### GitLab Duo Chatがサイズ変更可能に {#gitlab-duo-chat-is-now-resizable}

<!-- categories: Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-the-gitlab-ui) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/499849)

{{< /details >}}

GitLab UIで、Duo Chatドロワーのサイズを変更できるようになりました。これにより、コード出力の表示が容易になり、バックグラウンドでGitLabを操作しながらチャットを開いたままにすることができます。

### Manage multiple conversations in GitLab Duo Chat {#manage-multiple-conversations-in-gitlab-duo-chat}

<!-- categories: Duo Chat -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/_index.md#have-multiple-conversations) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16108)

{{< /details >}}

複数の会話により、GitLab Duo Chatで異なるトピック間のコンテキストを維持することが容易になりました。新しい会話を作成したり、会話の履歴を閲覧したり、会話間を切り替えたりできます。

以前は、新しい会話を開始すると、既存のチャットのコンテキストが失われました。これで、異なるトピックに関する複数の会話を管理できます。各会話は独自のコンテキストを維持するため、例えば、ある会話でコードの説明に関する追加の質問をしたり、別の会話で作業計画を準備したりすることができます。

以前のディスカッションを再訪する必要がある場合は、新しいチャット履歴アイコンを選択して、すべての最近の会話を表示します。会話は最新のアクティビティによって自動的に整理されるため、中断した場所から再開するのが容易になります。

プライバシー保護のため、30日間アクティビティがない会話は自動的に削除され、いつでも手動で会話を削除できます。

この機能は現在、ウェブUIのGitLab.comでのみ利用可能です。GitLab Self-ManagedインスタンスやIDEインテグレーションでは利用できません。

[イシュー526013](https://gitlab.com/gitlab-org/gitlab/-/issues/526013)であなたの経験を共有してください。

### GitLab Duo Self-HostedでAI搭載機能のモデルを選択 {#select-models-for-ai-powered-features-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#select-a-self-hosted-model-for-a-feature) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/524174)

{{< /details >}}

GitLab Duo Self-Hostedでは、セルフマネージドインスタンス上で、個々のGitLab Duo Chatサブ機能に対して個別のサポートされているモデルを選択できるようになりました。チャットサブ機能のモデル選択と設定は現在ベータ版です。

フィードバックを残すには、[イシュー524175](https://gitlab.com/gitlab-org/gitlab/-/issues/524175)にアクセスしてください。

### GitLab Duo Self-Hostedコード提案でAIインパクトダッシュボードが利用可能に {#ai-impact-dashboard-available-on-gitlab-duo-self-hosted-code-suggestions}

<!-- categories: Self-Hosted Models, Value Stream Management, DORA Metrics -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/analytics/duo_and_sdlc_trends.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523807)

{{< /details >}}

これで、セルフマネージドインスタンスでAIインパクトダッシュボードをGitLab Duo Self-Hostedコード提案と共に使用して、GitLab Duoが生産性に与える影響を理解するのに役立てることができます。AIインパクトダッシュボードはGitLab Duo Self-Hostedとベータ版で提供されており、この機能はセルフマネージドインスタンスとVS Code、Microsoft Visual Studio、JetBrains、Neovim IDEで使用できます。

AIインパクトダッシュボードを使用して、AIの使用傾向をリードタイム、サイクルタイム、DORA、および脆弱性などのメトリクスと比較できます。これにより、GitLab Duo Self-Hostedを使用してエンドツーエンドのワークストリームで節約される時間を測定し、開発者の活動よりもビジネス成果に焦点を当て続けることができます。

AIインパクトダッシュボードに関するフィードバックは、[イシュー456105](https://gitlab.com/gitlab-org/gitlab/-/issues/456105)にお寄せください。

### GitLab Duo Self-Hostedコード提案およびチャットでMeta Llama 3モデルが利用可能に {#meta-llama-3-models-available-for-gitlab-duo-self-hosted-code-suggestions-and-chat}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523917)

{{< /details >}}

GitLab Duo Self-Hostedで選択されたMeta Llama 3モデルを使用できるようになりました。これらのモデルは、GitLab Duo Chatおよびコード提案をサポートするために、GitLab Duo Self-Hosted向けにベータ版で提供されています。

GitLab Duo Self-Hostedでこれらのモデルを使用することに関するフィードバックは、[イシュー523912](https://gitlab.com/gitlab-org/gitlab/-/issues/523917)にお寄せください。

## 規模とデプロイ {#scale-and-deployments}

### プレースホルダーユーザーが作成されたときのタイムスタンプ {#timestamps-of-when-placeholder-users-were-created}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/import/mapping/post_migration_mapping.md#placeholder-user-attributes) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/507297)

{{< /details >}}

以前は、グループやプロジェクトをインポートした際に、[プレースホルダーユーザー](../../user/import/mapping/post_migration_mapping.md#placeholder-users)がいつ作成されたかを確認できませんでした。このリリースにより、タイムスタンプが追加され、移行の進捗状況を追跡し、発生した問題をトラブルシューティングできるようになりました。

### To-Do項目の一括編集 {#bulk-edit-to-do-items}

<!-- categories: Notifications -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/todos.md#bulk-edit-to-do-items) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/16564)

{{< /details >}}

改善された一括編集機能により、To-Doリストを効率的に管理できるようになりました。複数のTo-Do項目を選択し、一度に完了済みまたは一時停止としてマークすることで、タスクに対する制御が強化され、より少ない労力で整理された状態を維持できます。

### To-Do項目を一時停止 {#snooze-to-do-items}

<!-- categories: Notifications -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/todos.md#snooze-to-do-items) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/17712)

{{< /details >}}

To-Doリストの通知を一時停止できるようになり、一時的に項目を非表示にして、今最も重要なことに集中できます。集中するために1時間必要であるか、明日タスクを再訪したいかにかかわらず、通知がいつ再表示されるかを細かく制御でき、ワークフローをより効果的に管理するのに役立ちます。

### CSVファイルを使用して再割り当てをリクエストする {#request-reassignment-by-using-a-csv-file}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/import/mapping/reassignment.md#request-reassignment-by-using-a-csv-file) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16765)

{{< /details >}}

このリリースにより、ユーザーコントリビュートマッピングはCSVファイルを使用した一括再割り当てをサポートするようになりました。多数のプレースホルダーユーザーを持つ大規模なユーザーベースがある場合、オーナーロールを持つグループメンバーは次のことができます:

1. 事前入力されたCSVテンプレートをダウンロードします。
1. 宛先インスタンスからGitLabのユーザー名または公開メールを追加します。
1. 完成したファイルをアップロードして、すべてのコントリビュートを一括で再割り当てします。

この方法は、UIを介した手間のかかる手動の再割り当てを不要にします。大規模な移行をさらに効率化するために、CSVベースの再割り当てに対するAPIサポートも利用できるようになりました。

### あなたの作業内のプロジェクトの新しいナビゲーションエクスペリエンス {#new-navigation-experience-for-projects-in-your-work}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/working_with_projects.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/465889)

{{< /details >}}

**Your Work**のプロジェクト概要に大幅な改善が行われたことを発表できることを嬉しく思います。これは、プロジェクトの発見とアクセス方法を効率化するために設計されています。このアップデートでは、ユーザーがプロジェクトを操作する方法をよりよく反映する、より直感的なタブベースのナビゲーションシステムが導入されています。

- 新しい**コントリビュート済み**タブ（以前は**Yours**）には、個人プロジェクトを含む、あなたがコントリビュートしたすべてのプロジェクトが表示され、開発アクティビティを追跡しやすくなります。
- メインナビゲーションに目立つように表示されるようになった**個人**タブで、個々のプロジェクトをより迅速に見つけることができます。
- **メンバー**タブ（以前は**すべて**）を通じてチームプロジェクトにアクセスできます。このタブには、メンバーシップを持つすべてのプロジェクトが表示されます。
- **非アクティブ**タブ（以前は**削除保留中**）には、アーカイブされたプロジェクトと削除保留中のプロジェクトの両方が包括的に表示されます。

さらに、適切な権限があれば、**Your Work**のプロジェクト概要からプロジェクトを直接編集または削除できるようになりました。これらの変更は、より効率的でユーザーフレンドリーなGitLabエクスペリエンスを作成するという当社のコミットメントを反映しています。新しいレイアウトにより、最も重要なプロジェクトに集中でき、異なるプロジェクトカテゴリ間を移動する時間を削減できます。

この更新に関するフィードバックを歓迎します！新しいナビゲーションシステムに関する経験を共有するために、[エピック16662](https://gitlab.com/groups/gitlab-org/-/epics/16662)のディスカッションに参加してください。

### プロジェクト作成権限設定の改善 {#improved-project-creation-permission-settings}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/507410)

{{< /details >}}

プロジェクト作成権限設定を改善し、より明確で直感的、かつ当社のセキュリティ原則に沿ったものにしました。改善された設定には次のものが含まれます:

- 「デフォルトプロジェクト作成保護」ドロップダウンを「プロジェクト作成に必要な最小ロール」に名称変更し、設定の目的を明確に反映させました。
- プラットフォーム全体の一貫性を保つため、「デベロッパー+メンテナー」ドロップダウンオプションを「デベロッパー」に名称変更しました。
- ドロップダウンオプションを最も制限的なものから最も制限的でないアクセスレベルの順に並べ替えました。

これらの変更により、グループ内でプロジェクトを作成できるロールをより簡単に理解および設定できるようになり、管理者は適切なアクセス制御をより確実に適用できるようになります。

このコントリビュートをしてくれた[@yasuk](https://gitlab.com/yasuk)に感謝します！

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### pub (Dart) パッケージマネージャー向けの依存関係スキャンのサポート {#dependency-scanning-support-for-pub-dart-package-manager}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/342468)

{{< /details >}}

依存関係スキャンは、Dartの公式パッケージマネージャーであるpubのサポートを追加しました。このサポートは、依存関係スキャンの[最新テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Dependency-Scanning.latest.gitlab-ci.yml)と[CI/CDコンポーネント](https://gitlab.com/explore/catalog/components/dependency-scanning)に追加されました。

この追加は、ユーザーの1人であるAlexandre Larocheからのコミュニティコントリビュートでした。GitLabコンポジション解析チームは、私たちの製品を改善するためのこのコントリビュートに感謝しています。Alexandre、本当にありがとうございます。GitLabへの貢献について詳しく知りたい場合は、[コミュニティコントリビュートプログラム](https://about.gitlab.com/community/contribute/)をご確認ください。

### フレームワークページでドロップダウンリストからデフォルトのコンプライアンスフレームワークを選択 {#select-a-compliance-framework-as-default-from-the-dropdown-list-on-the-frameworks-page}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate、Premium
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_frameworks_report.md#set-and-remove-a-compliance-framework-as-default) | [関連エピック](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181500)

{{< /details >}}

ユーザーはGitLabコンプライアンスセンターでデフォルトのコンプライアンスフレームワークを設定できます。これは、そのグループで作成されるすべての新規およびインポートされたプロジェクトに適用されます。デフォルトのコンプライアンスフレームワークには、ユーザーがそれを識別できるように**デフォルト**ラベルが付いています。

コンプライアンスフレームワークをデフォルトとして設定しやすくするため、トップレベルグループのコンプライアンスセンターのリストフレームワークページで、フレームワークドロップダウンリストを使用してユーザーがフレームワークをデフォルトとして設定できる機能が導入されます。この機能は、サブグループまたはプロジェクトのコンプライアンスセンターでは利用できません。

### Git blameで特定のrevisionを無視 {#ignore-specific-revisions-in-git-blame}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/files/git_blame.md#ignore-specific-revisions)

{{< /details >}}

リポジトリの履歴を閲覧する際、プロジェクトの意味のある変更とは関連しないコミットが存在する場合があります。これは次の場合に発生します:

- 機能を変更せずに、あるライブラリから別のライブラリに変更するリファクタリング。
- コードフォーマッターまたはLinterを実装して、コードベース全体を標準化する必要がある場合。

`blame`でプロジェクトの履歴を確認すると、これらの種類のコミットにより、発生した変更を理解することが困難になります。Gitは、プロジェクト内の`.git-blame-ignore-revs`ファイルでこれらのコミットを識別することをサポートしています。GitLabでは、「Blame環境設定」ドロップダウンリストでblame表示を切り替えてこれらの特定のリビジョンを表示または非表示にできるようになり、プロジェクトの履歴を理解しやすくなりました。

### CODEOWNERSのパス除外 {#path-exclusions-for-codeowners}

<!-- categories: Source Code Management, Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/codeowners/reference.md#exclusion-patterns)

{{< /details >}}

チームが`CODEOWNERS`ファイルを設定する場合、パスやファイルタイプに広範なマッチングパターンを含めることが一般的です。これらの広範な設定は、ドキュメント、自動化されたビルドファイル、またはその他のパターンで特定のコードオーナーが必要ない場合に問題となる可能性があります。

これで、特定のパスを無視するために、`CODEOWNERS`ファイルをパス除外で設定できます。これは、特定のファイルやパスをコードオーナーの承認の必要性から除外したい場合に役立ちます。

### ブランチルールでのスカッシュ設定の構成 {#configurable-squash-settings-in-branch-rules}

<!-- categories: Source Code Management, Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/branches/branch_rules.md#edit-squash-commits-option)

{{< /details >}}

異なるGitワークフローでは、ブランチ間でマージする際のコミットの処理に異なる戦略が必要です。以前のバージョンのGitLabでは、マージ時にコミットをスカッシュするかどうか、およびそれがどの程度強制されるべきかについて、単一の戦略しか設定できませんでした。この設定は、エラーが発生しやすかったり、デベロッパーが異なるブランチターゲットのプロジェクト規則に従うために特定の選択を行う必要があったりする可能性がありました。

これで、ブランチルールを通じて、各保護ブランチのスカッシュ設定を設定できます。たとえば、次のことができます:

- `feature`ブランチから`develop`ブランチへマージする際に、履歴をクリーンに保つためにスカッシュを必須とします。
- コミット履歴をそのまま維持したい場合は、`develop`ブランチから`main`ブランチへのマージ時にスカッシュを無効にします。

この柔軟性により、プロジェクト全体で一貫したコミット履歴が保証され、ワークフロー内の各ブランチの固有のニーズを尊重しながら、手動によるデベロッ2ッパーの介入を必要としません。

### トークン有効期限通知の配布範囲の拡大 {#wider-distribution-for-token-expiration-notifications}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/manage.md#expiry-emails-for-group-and-project-access-tokens) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/463016)

{{< /details >}}

以前は、アクセストークンの有効期限切れ通知メールは、トークンが有効期限切れとなるグループおよびプロジェクトの直接メンバーにのみ送信されていました。これで、設定が有効になっている場合、これらの通知は継承されたグループおよびプロジェクトメンバーにも送信されます。この配布範囲の拡大により、有効期限が切れる前にトークンを管理しやすくなります。

### `needs`パイプライン実行ポリシーにおけるステートメントのコンプライアンスへの対応 {#handling-of-needs-statements-in-pipeline-execution-policies-for-compliance}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/pipeline_execution_policies.md#pipeline_execution_policy-schema) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/469256)

{{< /details >}}

パイプライン実行に対する制御を強化するため、`.pipeline-policy-pre`予約ステージで強制されるジョブは、そのジョブが`needs`ステートメントを定義しているかどうかにかかわらず、後続のステージのジョブが開始される前に完了する必要があります。以前は、`.pipeline-policy-pre`ステージで定義されたジョブと、`needs`ステートメントを持つ後続のパイプライン内のジョブは、パイプラインが実行されるとすぐに開始されていました。この強化により、後続のステージのジョブは、依存関係のない他のジョブを開始する前に`.pipeline-policy-pre`が完了するのを待つ必要があり、順序付けられた実行を強制し、セキュリティポリシー内でのコンプライアンスを保証するのに役立ちます。

お客様は、デベロッパーのジョブが実行される前にコンプライアンスとセキュリティチェックを強制するために、予約されたステージに依存しています。一般的なユースケースは、チェックがパスしない場合にパイプライン全体を失敗させるセキュリティまたはコンプライアンスチェックを強制することです。ジョブが順序を無視して実行されることを許可すると、この強制をバイパスし、ポリシーの意図を弱める可能性があります。この改善により、コンプライアンスの強制に対するより一貫したアプローチが提供されます。

`needs`の動作を上書きせずにパイプラインの最初にジョブを挿入するには、17.9で導入された新しいカスタムステージ機能を使用して、ジョブがカスタムステージを使用するように設定します。

### アクセストークンでプライベートPagesに認証 {#authenticate-to-private-pages-with-an-access-token}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/pages/pages_access_control.md#authenticate-with-an-access-token)

{{< /details >}}

これで、アクセストークンを使用してプログラムでプライベートなGitLab Pagesサイトに認証できるようになり、Pagesコンテンツとのインタラクションを自動化しやすくなりました。以前は、制限されたPagesサイトにアクセスするには、GitLab UIを介したインタラクティブな認証が必要でした。

この強力な強化により、生産性が向上し、セキュリティを維持しながら、デベロッパーがプライベートPagesコンテンツと対話し、配布する方法の柔軟性が高まります。

### コード提案とGitLab Duo Chatの傾向に関する新しいインサイト {#new-insights-into-gitlab-duo-code-suggestions-and-gitlab-duo-chat-trends}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/analytics/duo_and_sdlc_trends.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/477246)

{{< /details >}}

AIインパクトダッシュボードのAI比較メトリクスパネルは、コード提案の承認率とGitLab Duo Chatの使用量（前月比%）の月間（MoM）追跡を提供するようになりました。これらの新しいトレンドベースのインサイトは、既存のDuoコード提案とDuoチャットタイルを補完し、これらのメトリクスの30日間のスナップショットを提供します。これらの追加メトリクスにより、マネージャーは、コード提案の承認率とDuoチャットの使用量を他のSDLCメトリクスと時系列で比較することで、ソフトウェア開発プロセスにおけるAIの影響をより適切に測定し、パターンを特定できます。

### 依存プロキシ向けDocker Hub認証 {#docker-hub-authentication-for-the-dependency-proxy}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/dependency_proxy/_index.md#authenticate-with-docker-hub) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/331741)

{{< /details >}}

コンテナイメージ用のGitLab依存プロキシは、Docker Hubとの認証をサポートするようになり、レート制限によるパイプラインの失敗を回避し、プライベートイメージへのアクセスを可能にします。

2025年4月1日より、Docker Hubは、未認証ユーザーに対してより厳格なプル制限（IPv4アドレスまたはIPv6 /64サブネットあたり6時間ごとに100回）を適用します。認証がない場合、これらの制限に達するとパイプラインが失敗する可能性があります。

このリリースにより、Docker Hubの認証をGraphQL APIを通じて、Docker Hubの認証情報、[パーソナルアクセストークン](https://docs.docker.com/security/for-developers/access-tokens/) 、または[組織アクセストークン](https://docs.docker.com/security/for-admins/access-tokens/)を使用して設定できます。UI設定のサポートはGitLab 17.11で利用可能になります。

### パッケージレジストリに監査イベントを追加 {#package-registry-adds-audit-events}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/audit_event_types.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/329588)

{{< /details >}}

パッケージレジストリの操作は監査イベントとして記録されるようになり、チームはパッケージがいつ公開または削除されたかを追跡して、コンプライアンス要件を満たすことができます。

このリリース以前は、誰がパッケージを公開または変更したかを追跡する組み込みの方法はありませんでした。チームは、これらのアクティビティのログを維持するために、独自の追跡システムを作成するか、パッケージの変更を手動で記録する必要がありました。これで、各監査イベントは、誰が変更を行ったか、いつ発生したか、どのように認証されたか、およびパッケージで何が変更されたかを正確に示します。

プロジェクトの監査イベントは、グループネームスペースまたは個々のプロジェクトオーナーのためにプロジェクト自体に保存されます。グループは、ストレージニーズを管理するために監査イベントをオフにできます。

### 認証情報インベントリでアクセストークンを並べ替える {#sort-access-tokens-in-credentials-inventory}

<!-- categories: System Access -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/credentials_inventory.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/513181)

{{< /details >}}

これで、認証情報インベントリ内で、オーナー、作成日、最終使用日で個人、プロジェクト、およびグループアクセストークンを並べ替えることができます。これにより、アクセストークンをより迅速に見つけて識別できます。このコントリビュートをしてくれた[Chaitanya Sonwane](https://gitlab.com/chaitanyason9)に感謝します！

### トークン情報APIでトークンを識別して失効 {#identify-and-revoke-tokens-with-token-information-api}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../api/admin/token.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15777)

{{< /details >}}

GitLab管理者は、統合されたAPIを使用してトークンを識別し、失効できるようになりました。以前は、管理者は特定のタイプのトークンに関連するエンドポイントを使用する必要がありました。このAPIは、タイプに関係なく失効を許可します。サポートされているトークンタイプのリストについては、[トークン情報API](../../api/admin/token.md)を参照してください。

このコントリビュートをしてくれた[Nicholas Wittstruck](https://gitlab.com/nwittstruck)とSiemensのチームに感謝します！

### GitLab OIDCプロバイダーとのトークン期間の構成 {#configurable-token-duration-with-gitlab-oidc-provider}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/auth/oidc.md#configure-a-custom-duration-for-id-tokens) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/377654)

{{< /details >}}

GitLabをOpenID Connect（OIDC）プロバイダーとして使用する場合、`id_token_expiration`属性を使用してIDトークンの期間を設定できるようになりました。以前は、IDトークンの固定有効期限は120秒でした。

このコントリビュートをしてくれた[Henry Sachs](https://gitlab.com/DerAstronaut)に感謝します！

### OmniAuthプロファイル属性をユーザーにマップ {#map-omniauth-profile-attributes-to-user}

<!-- categories: User Management -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../integration/omniauth.md#keep-omniauth-user-profiles-up-to-date) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/505575)

{{< /details >}}

これで、OmniAuth Identity Provider（IdP）の組織およびタイトルプロファイル属性をユーザーのGitLabプロファイルにマップできるようになりました。これにより、IdPがこれらの属性の信頼できる唯一の情報源となり、ユーザーはそれらを変更できなくなります。

### 有効期限切れトークンの拡張Webhookトリガー {#extended-webhook-triggers-for-expiring-tokens}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/manage.md#add-additional-webhook-triggers-for-group-access-token-expiration) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/499732)

{{< /details >}}

これで、プロジェクトまたはグループアクセストークンの有効期限が切れる60日および30日前にWebhookイベントをトリガーできるようになりました。以前は、これらのWebhookイベントは有効期限が切れる7日前にのみトリガーされていました。これは、既存の有効期限切れトークンのメール通知スケジュールと一致するオプションの設定です。

### GitLab Runner 17.10 {#gitlab-runner-1710}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 17.10もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [インスタンス使用前のオートスケーラーexecutorヘルスチェックの実行](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38271)
- [Docker executorボリュームを展開](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38249)
- [サービス向けのデバイス追加のためのDocker executor設定を追加](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6208)

#### バグ修正 {#bug-fixes}

- [Windows `gitlab-runner-helper`イメージが`/opt/step-runner’ パスの無効なボリューム仕様により失敗します](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38632)
- [GitLab Runner 17.7.0以降でRPMパッケージのリポジトリのミラーリングが正常に動作していません](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38409)
- [GitLab CI/CDで`git submodule update --remote`を実行するとエラーが返されます](https://gitlab.com/gitlab-org/gitlab/-/issues/359825)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-10-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.10)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.10)
- [UI改善](https://papercuts.gitlab.com/?milestone=17.10)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
