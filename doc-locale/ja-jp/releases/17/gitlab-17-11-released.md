---
stage: Release Notes
group: Monthly Release
date: 2025-04-17
title: "GitLab 17.11リリースノート"
description: "GitLab 17.11は、要件とコンプライアンスコントロールを備えたカスタムコンプライアンスフレームワークのカスタマイズ機能とともにリリースされました。"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年4月17日、GitLab 17.11は次の機能を備えてリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Heidi Berry {#this-months-notable-contributor-heidi-berry}

17.11の注目すべきコントリビューターとして、[Heidi Berry](https://gitlab.com/heidi.berry)氏を認定できることを嬉しく思います。

Heidi氏は、[GitLab Terraform Provider](https://gitlab.com/gitlab-org/terraform-provider-gitlab)および[client-go](https://gitlab.com/gitlab-org/api/client-go)プロジェクトにおける傑出したコントリビューターです。過去数回のリリースにおいて、彼女は、[グループSAMLリンクでのカスタムロール](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/1949)の使用、[グループのブランチ保護のデフォルト](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2113)設定、および[サービスアカウントトークンの自動トークンローテーション](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2206)など、多くの要望のあった機能を一貫して提供してきました。

機能開発以外にも、Heidi氏はメンテナンス活動に尽力しており、[イシューバックログの絞り込み](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/issues/1035#note_2305643918) 、[可読性を向上させるための古いテストの更新](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2298) 、そしてより良い例による[ドキュメント](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2201)の強化を行ってきました。彼女のclient-goへのコントリビュートは特に価値があります。このライブラリは、Terraformプロバイダーやglabなど、顧客とGitLabの両方がGitLabと連携するために使用する多くのダウンストリームプロジェクトを支えているためです。

「オープンソースへのコントリビュートを試してみたいなら、client-goとterraform-provider-GitLabを試してみてください」とHeidi氏は言います。「始めるのに役立つ素晴らしいドキュメントがあり、メンテナーがサポートしてくれます。私はこれらのプロジェクトを使って、Go言語を実践的に学ぶことを楽しみました。」

Heidi氏は、Kinglandのエンタープライズアーキテクトであり、GitLabコミュニティコアチームのメンバーである別のコミュニティコントリビューター、[Patrick Rice](https://gitlab.com/PatrickRice)氏によって推薦されました。Patrick氏は次のように述べています: 「17のリリースサイクル全体でこれまでに100以上のコントリビュートがマージされ、さらに多くのイシューコメントがあり、Heidi氏はGitLabとTerraformに多大な貢献をしてくれました。あなたの多大なコントリビュートに心から感謝いたします！」

「Heidiは素晴らしい仕事をしています」と、GitLabのDeploy::Environments担当シニアバックエンドエンジニアである[Timo Furrer](https://gitlab.com/timofurrer)は語りました。「彼女は常に一歩先を行き、client-goで必要なSDKコードを実装しています。Heidiは多くのコードをコントリビュートするだけでなく、イシューのトリアージも支援しています。これは非常に大きな助けであり、このようなコミュニティ主導のプロジェクトが持続できる理由です。」

Heidi氏はThe Co-operative Groupのリードソフトウェアエンジニアで、デベロッパーエクスペリエンスを効率的、安全、そして可能な限り手間のかからないものにするのを支援しています。

Heidiさん、GitLabへの多大なコントリビュートに感謝いたします！

## 主要な機能 {#primary-features}

### 要件とコンプライアンスコントロールでコンプライアンスフレームワークをカスタマイズする {#customize-compliance-frameworks-with-requirements-and-compliance-controls}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_status_report.md)

{{< /details >}}

以前は、GitLabのコンプライアンスフレームワークは、プロジェクトに特定のコンプライアンス要件があるか、追加の監視が必要であることを識別するためのラベルとして作成できました。このラベルは、グループ内のすべてのプロジェクトにセキュリティポリシーを適用するためのスコープメカニズムとして使用できます。

このリリースでは、コンプライアンスマネージャーがGitLabでより詳細なコンプライアンス監視を行うための新しい方法として「要件」を導入します。

要件として、カスタムコンプライアンスフレームワークの一部として、組織として従うべきさまざまなコンプライアンス標準、法律、規制から特定の要件を定義できます。

また、提供するコンプライアンスコントロール (以前はコンプライアンスチェックとして知られていました) の数を5から50以上に拡大しています！これらの50の既製の (OOTB) コントロールは、コンプライアンスフレームワークの要件にマップできます。

これらのコントロールは、プロジェクト、セキュリティ、およびマージリクエストの設定をGitLabインスタンス全体でチェックし、SOC2、NIST、ISO 27001、GitLab CISベンチマークなど、さまざまなコンプライアンス標準、法律、規制に基づく要件を満たすのに役立ちます。

これらのコントロールへのコンプライアンス遵守は、標準コンプライアンス遵守レポートに反映されます。これは、要件とそれらの要件へのマッピングを考慮に入れるように再設計されています。

OOTBコントロールを拡張することに加えて、GitLabプラットフォーム外に存在する項目、プログラム、またはシステムのための外部コントロールに要件をマップできるようになりました。これらのマッピングにより、GitLabコンプライアンスセンターを、コンプライアンス監視および監査証跡のニーズに関して、信頼できる唯一の情報源として使用できます。

### GitLab Eclipseプラグインのベータ版が利用可能 {#gitlab-eclipse-plugin-available-in-beta}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](https://docs.gitlab.com/editor_extensions/eclipse/setup/) | [関連エピック](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/89)

{{< /details >}}

[Eclipse Marketplace](https://marketplace.eclipse.org/content/gitlab-eclipse)で利用可能になったGitLab Eclipseプラグインのベータリリースを発表できることを嬉しく思います。この強力な新しいプラグインは、GitLabのDuo機能をEclipse IDEに直接拡張し、Duo ChatとAIを利用したコード提案へのシームレスなアクセスを提供します。

プラグインは現在ベータ版であるため、認証オプションの拡張や最終的なユーザーエクスペリエンスの改善など、機能強化に積極的に取り組んでいます。皆様のフィードバックは貴重です。[イシュー162](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/162)でフィードバックをいただくことで、GitLab Eclipseプラグインをさらに改善するためのご意見をお聞かせください。

### GitLab Duo Self-Hostedでより多くのGitLab Duo機能が利用可能に {#more-gitlab-duo-features-now-available-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/_index.md#feature-versions-and-status) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17072)

{{< /details >}}

GitLab [Duo](https://about.gitlab.com/gitlab-duo/) Self-Hostedで、ご自身のGitLab Self-Managedインスタンスでより多くのGitLab Duo機能を利用できるようになりました。次の機能がベータ版で利用可能です:

- [根本原因分析](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)
- [脆弱性の説明](../../user/application_security/analyze/duo.md)
- [脆弱性の修正](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution)
- [AIインパクトダッシュボード](../../user/analytics/duo_and_sdlc_trends.md)
- [ディスカッションサマリー](../../user/discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat)
- [Merge Request Commit Message](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)
- [マージリクエストサマリー](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes)
- [CLI用GitLab Duo](https://docs.gitlab.com/editor_extensions/gitlab_cli/#gitlab-duo-for-the-cli)

[コードレビューサマリー](../../user/project/merge_requests/duo_in_merge_requests.md#summarize-a-code-review)も、GitLab Duo Self-Hostedで実験的に利用できます。

### Self-ManagedインスタンスのWeb IDE向け拡張機能マーケットプレース {#extension-marketplace-for-web-ide-on-self-managed-instances}

<!-- categories: Web IDE -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/settings/vscode_extension_marketplace.md)

{{< /details >}}

Web IDEの拡張機能マーケットプレースがSelf-Managedユーザー向けにリリースされたことを発表できることを嬉しく思います。拡張機能マーケットプレースを使用すると、サードパーティの拡張機能を発見、インストール、および管理して、開発エクスペリエンスを向上させることができます。

デフォルトでは、GitLabインスタンスはOpen VSX拡張レジストリを使用するように設定されています。これを有効にするには、[デフォルトの拡張レジストリを有効にする](../../administration/settings/vscode_extension_marketplace.md#enable-the-extension-registry)手順に従ってください。

独自のレジストリまたはカスタムレジストリを使用したい場合は、[カスタム拡張レジストリを接続](../../administration/settings/vscode_extension_marketplace.md#modify-the-extension-registry)するオプションもあります。これにより、利用可能な拡張機能をより柔軟に管理できます。

拡張機能マーケットプレースを有効にした後も、個々のユーザーは引き続き使用をオプトインする必要があります。[Preferences](https://gitlab.com/-/profile/preferences)設定の**インテグレーション**セクションに移動することで、これを行うことができます。

一部の拡張機能はローカルランタイム環境を必要とし、Web専用バージョンと互換性がないことに注意することが重要です。それにもかかわらず、利用可能な数千の拡張機能から選択して、生産性を高め、ワークフローをカスタマイズすることができます。

### GitLab Duo with Amazon Qが一般公開されました {#gitlab-duo-with-amazon-q-is-generally-available}

<!-- categories: Code Suggestions -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/duo_amazon_q/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16879)

{{< /details >}}

包括的なGitLab AIを活用したDevSecOpsプラットフォームと、自律型Amazon Q AIエージェントを単一の統合ソリューションに統合した共同提供であるGitLab Duo with Amazon Qの一般公開を発表できることを嬉しく思います。GitLab Duo with Amazon Qは、AIエージェントを開発ワークフローに直接統合し、開発者がツールを切り替えることなく主要なタスクを高速化できるようにします。GitLab DevSecOpsプラットフォーム内のインテリジェントなエージェントとして機能し、これらのエージェントはコード生成、テスト、レビュー、Javaのモダナイゼーションなどの時間のかかるプロセスを自動化し、チームがセキュリティと品質基準を維持しながらイノベーションに集中できるよう支援します。

GitLab Duo with Amazon Qは、開発チームに大きなメリットをもたらします:

- アイデアからコードまでの機能開発を効率化: イシューの説明をマージ可能なコードに数分で直接変換する`/q dev`を使用します。
- レガシーコードを悩むことなくモダナイズ: `/q transform`を使用して、Javaのモダナイゼーションプロセス全体を自動化します。
- 品質を犠牲にすることなくコードレビューを高速化: `/q review`を使用して、マージリクエストでコード品質とセキュリティに関する即座のインテリジェントなフィードバックを取得します。
- 安心してリリースするためのテストを自動化: `/q test`を使用して、アプリケーションロジックを理解する包括的な単体テストを生成します。

### 保護タグでセキュリティを強化する {#enhance-security-with-protected-container-tags}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/container_registry/protected_container_tags.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523893)

{{< /details >}}

コンテナレジストリは、最新のDevSecOpsチームにとって重要なインフラです。これまで、デベロッパーロール以上のGitLabユーザーは、プロジェクト内の任意のコンテナタグをプッシュしたり削除したりでき、本番環境に不可欠なコンテナイメージへの偶発的または不正な変更のリスクを生み出していました。

保護タグを使用すると、特定のコンテナタグをプッシュまたは削除できるユーザーをきめ細かく制御できます。次のことができます: 

- プロジェクトごとに最大5つの保護ルールを作成できます。
- RE2正規表現パターンを使用して、`latest`のようなタグ、セマンティックバージョン (例: `v1.0.0`)、または安定したリリースタグ (例: `main-stable`) を保護します。
- プッシュおよび削除操作をメンテナー、オーナー、または管理者ロールに制限します。
- 保護タグがクリーンアップポリシーによって削除されるのを防ぎます。

この機能には次世代のコンテナレジストリが必要であり、これはGitLab.comでデフォルトで有効になっています。GitLab Self-Managedインスタンスでは、[メタデータデータベース](../../administration/packages/container_registry_metadata_database.md)を有効にして保護タグを使用する必要があります。

### レジストリを保護されたMavenパッケージで保護する {#safeguard-your-registry-with-protected-maven-packages}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/packages/package_registry/package_protection_rules.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/323969)

{{< /details >}}

GitLabパッケージレジストリのセキュリティと安定性を強化するために、保護されたMavenパッケージのサポートを導入できることを嬉しく思います。パッケージの偶発的な変更は、開発プロセス全体を中断させる可能性があります。保護されたパッケージを使用すると、最も重要な依存関係を意図しない変更から保護できます。

GitLab 17.11では、保護ルールを作成することでMavenパッケージを保護できるようになりました。パッケージが保護ルールと一致する場合、指定されたユーザーのみがパッケージの新しいバージョンをプッシュできます。パッケージ保護ルールは、偶発的な上書きを防ぎ、規制要件へのコンプライアンスを改善し、手動監視の必要性を低減します。

Mavenおよびその他のパッケージ形式の[保護されたパッケージ](https://gitlab.com/groups/gitlab-org/-/epics/5574)サポートは、`gerardo-navarro`とSiemensチームからのコミュニティコントリビュートです。Gerardo氏とSiemensチームの皆様、GitLabへの多くのコントリビュートに感謝いたします！Gerardo氏とSiemensチームがこの変更にどのようにコントリビュートしたかについて詳しく知りたい場合は、Gerardo氏が外部コントリビューターとしての経験に基づいてGitLabへのコントリビュートに関する彼の学びとベストプラクティスを共有しているこの[ビデオ](https://www.youtube.com/watch?v=5-nQ1_Mi7zg)をご覧ください。

### エピック、イシュー、タスクのカスタムフィールド {#epic-issue-and-task-custom-fields}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/work_items/custom_fields.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14904)

{{< /details >}}

このリリースでは、イシュー、エピック、タスク、目標と主な成果向けのテキスト、数値、単一選択、複数選択のカスタムフィールドを設定できます。これまでラベルが作業アイテムを分類する主要な方法でしたが、カスタムフィールドは、計画アーティファクトに構造化されたメタデータを追加するための、よりユーザーフレンドリーなアプローチを提供します。

カスタムフィールドはトップレベルグループで設定され、すべてのサブグループとプロジェクトにカスケードされます。フィールドを1つ以上の作業アイテムタイプにマップし、イシューとエピックのリストでカスタムフィールド値によってフィルターできます。

### 新しいイシューの外観が一般公開されました {#new-issue-look-now-generally-available}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/issues/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/525547)

{{< /details >}}

このリリースより、新しいイシューの外観が一般公開され、従来のイシューエクスペリエンスに置き換わります。イシューは、エピックやタスクと共通のフレームワークを共有するようになり、リアルタイム更新とワークフローの改善が特徴です:

- **Drawer view:** リストまたはボードからドロワーで項目を開き、現在のコンテキストを離れることなく素早く表示できます。上部にあるボタンで、全ページ表示に展開することができます。
- **Change type:** 「種類の変更」アクション（「エピックにプロモート」を置き換えます）を使用して、エピック、イシュー、タスク間でタイプを変換します。
- **開始日:** イシューがエピックおよびタスクと機能を合わせて開始日をサポートするようになりました。
- **Ancestry:** 完全な階層は、サイドバーのタイトルと親フィールドの上に表示されます。関係を管理するには、新しいクイックアクションコマンド`/set_parent`、`/remove_parent`、`/add_child`、および`/remove_child`を使用します。
- **Controls:** すべての操作は、トップメニュー（縦方向の省略記号）からアクセスできるようになり、スクロール時もスティッキーヘッダーに表示されたままになります。
- **Development:** イシューまたはタスクに関連するすべての開発項目（マージリクエスト、ブランチ、および機能フラグ）が、単一の便利なリストに統合されました。
- **Layout:** UIの改善により、イシュー、エピック、タスク、およびマージリクエスト間のエクスペリエンスがよりシームレスになり、ワークフローをより効率的にナビゲートできるようになります。
- **Linked items:** 改善されたリンクオプションを使用して、タスク、イシュー、エピック間の関係を作成します。ドラッグ＆ドロップでリンクタイプを変更し、ラベルとクローズされた項目の表示レベルを切り替えます。

### サービスアカウントUI {#service-accounts-ui}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/service_accounts.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9965)

{{< /details >}}

GitLab UIでサービスアカウントを作成および管理するための専用スペースを使用できるようになりました。このインターフェースにより、GitLabリソースへの自動アクセスを作成、モニタリング、および制御できます。以前は、この機能はAPIでのみ利用可能でした。

### Duo ProとDuo Enterpriseのシートの自動割り当て {#automated-duo-pro-and-duo-enterprise-seat-assignment}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/group/saml_sso/group_sync.md#manage-gitlab-duo-seat-assignment) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/502496)

{{< /details >}}

SAMLグループ同期を使用して、Duo ProまたはDuo Enterpriseのシートをユーザーに自動的に割り当てできるようになりました。GitLabグループに利用可能なDuo ProまたはDuo Enterpriseのシートがある限り、Identity Providerからマップされたユーザーには自動的にシートが割り当てられます。これにより、シートの割り当てを管理する手間が省けます。

### CI/CDパイプライン入力 {#cicd-pipeline-inputs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/inputs/_index.md#for-a-pipeline)

{{< /details >}}

CI/CD変数は、動的なCI/CDワークフローに不可欠であり、環境変数、コンテキスト変数、ツール設定、およびマトリックス変数など、さまざまな用途に使用されます。しかし、デベロッパーは、手動でパイプラインの動作を変更するために、[パイプライン変数](../../ci/variables/_index.md#use-pipeline-variables)をパイプラインに挿入するためにCI/CD変数に依存することがあり、パイプライン変数の優先順位が高いため、いくつかのリスクがあります。

GitLab 17.11以降では、スケジュールされたパイプライン、ダウンストリームパイプライン、パイプライントリガーされたパイプライン、およびその他のケースを含め、パイプライン変数を使用する代わりに`inputs`を使用してパイプラインの動作を安全に変更できます。入力は、デベロッパーにCI/CDジョブランタイム時に動的コンテンツを挿入するための、より構造化された柔軟なソリューションを提供します。入力に切り替えると、[パイプライン変数へのアクセスを完全に無効にする](../../ci/variables/_index.md#restrict-pipeline-variables)ことができます。

ぜひお試しいただき、この専用の[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/533802)を通じてフィードバックを共有していただければ幸いです。

## エージェント型コア {#agentic-core}

### GitLab Duo ChatがAnthropic Claude Sonnet 3.7を使用するようになりました {#gitlab-duo-chat-now-uses-anthropic-claude-sonnet-37}

<!-- categories: Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/examples.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/521034)

{{< /details >}}

GitLab Duo Chatは、ほとんどの質問に回答するためにClaude 3.5 Sonnetに代わり、Anthropic Claude Sonnet 3.7をベースモデルとして使用するようになりました。

Claude 3.7 Sonnetは、コード記述と推論の能力が大幅に向上し、コードの生成、テキストデータの処理、および複雑なDevSecOpsの質問への回答において、さらに優れています。これらの分野で、より詳細で正確なChat応答に気づくでしょう。

このアップグレードはすべてのChat機能に適用され、Chatインターフェース全体で一貫した改善されたエクスペリエンスを保証します。

### GitLab Duo Self-Hostedコード提案でコンテキストとしてファイルを開くことが可能に {#open-files-as-context-now-available-on-gitlab-duo-self-hosted-code-suggestions}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/repository/code_suggestions/context.md#using-open-files-as-context) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16611)

{{< /details >}}

GitLab Duo Self-Hostedでは、コード提案を使用する際に、IDEのタブで開いている[ファイル](../../user/project/repository/code_suggestions/context.md#using-open-files-as-context)をコンテキストとして使用できるようになりました。

### GitLab Duo Self-HostedのAIを活用した機能ごとに個別のモデルを選択 {#select-individual-models-for-ai-powered-features-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#select-a-self-hosted-model-for-a-feature) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17099)

{{< /details >}}

GitLab Duo Self-Hostedでは、GitLab Self-Managedインスタンスで、各GitLab Duo機能およびサブ機能に対して個別のサポートされているモデルを設定できるようになりました。

フィードバックを残すには、[イシュー524175](https://gitlab.com/gitlab-org/gitlab/-/issues/524175)にアクセスしてください。

### GitLab Duo Chatとコード提案向けのLlama 3モデルが一般公開されました {#llama-3-models-generally-available-for-gitlab-duo-chat-and-code-suggestions}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15678)

{{< /details >}}

Llama 3モデルが、GitLab Duo Self-HostedでGitLab Duo Chatとコード提案をサポートするために一般公開されました。

これらのモデルをGitLab Duo Self-Hostedで使用することに関するフィードバックは、[イシュー523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918)をご覧ください。

### Manage multiple conversations in GitLab Duo Chat {#manage-multiple-conversations-in-gitlab-duo-chat}

<!-- categories: Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/_index.md#have-multiple-conversations) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16108)

{{< /details >}}

GitLab Duo Chatとの複数の会話が、ウェブUIのGitLab Self-Managedインスタンスで利用可能になりました。新しい会話を作成したり、会話履歴を閲覧したり、コンテキストを失うことなく会話間を切り替えることができます。

プライバシー保護のため、30日間アクティビティがない会話は自動的に削除され、いつでも手動で会話を削除できます。GitLab Self-Managedでは、管理者が会話の保持期間を短縮できます。

[イシュー526013](https://gitlab.com/gitlab-org/gitlab/-/issues/526013)であなたの経験を共有してください。

## 規模とデプロイ {#scale-and-deployments}

### すべての自動無効化されたWebhookが自動的に再有効化されます {#all-auto-disabled-webhooks-now-automatically-re-enable}

<!-- categories: Webhooks -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/webhooks.md#auto-disabled-webhooks) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/396577)

{{< /details >}}

このリリースにより、`4xx`エラーを返すWebhookが自動的に再有効化されるようになりました。すべてのエラー（`4xx`、`5xx`、またはサーバーエラー）は同じように扱われ、より予測可能な動作と容易なトラブルシューティングを可能にします。この変更は、[こちらのブログ記事](https://about.gitlab.com/blog/gitlab-webhooks-get-smarter-with-self-healing-capabilities/)で発表されました。

失敗したWebhookは1分間一時的に無効になり、最大24時間まで延長されます。Webhookが40回連続して失敗すると、永続的に無効になります。

GitLab 17.10以前に永久に無効化されたWebhookに対してデータ移行が行われました。

- GitLab.comの場合、これらの変更は自動的に適用されます。
- GitLab Self-ManagedとGitLab Dedicatedの場合、これらの変更は`auto_disabling_webhooks``ops`フラグが有効になっているインスタンスのみに影響します。

[Phawin](https://gitlab.com/lifez)の[このコミュニティコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/166329)に感謝します！

### ゴーストユーザーのコントリビュートがインポート中に自動マップされます {#ghost-user-contributions-auto-mapped-during-imports}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/import/mapping/post_migration_mapping.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/514014)

{{< /details >}}

以前は、ゴーストユーザーのコントリビュートにより、手動での再割り当てが必要なプレースホルダー参照が作成され、移行時に余分な作業が発生していました。現在、新しい[コントリビュートおよびメンバーシップのマッピング機能](../../user/import/mapping/post_migration_mapping.md)を使用するインポーター、直接転送による移行、GitHub、Bitbucket Server、およびGiteaインポーターは、ゴーストユーザーのコントリビュートをよりインテリジェントに処理します。GitLabにコンテンツをインポートする際、ソースインスタンスでゴーストユーザーによって以前に行われたコントリビュートは、宛先インスタンスのゴーストユーザーに自動的にマップされるようになりました。

この機能強化により、ゴーストユーザーのコントリビュートに対する不要なプレースホルダーユーザーの作成が排除され、ユーザーマッピングインターフェースの煩雑さが軽減され、移行プロセスが簡素化されます。

### GitLab.comへのインポート時のコントリビュート再割り当てにおけるSAML検証 {#saml-verification-for-contribution-reassignment-when-importing-to-gitlabcom}

<!-- categories: Importers -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/import/mapping/reassignment.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/513686)

{{< /details >}}

このマイルストーンでは、GitLab.comへのインポート時のコントリビュート再割り当てにSAML検証チェックを追加しました。これらのチェックは、SAML SSOが有効なグループでの再割り当てエラーを防ぎます。

GitLab.comにインポートし、GitLab.comグループにSAML SSOを使用する場合、コントリビュートとメンバーシップを再割り当てする前に、すべてのユーザーがSAMLIDをGitLab.comアカウントにリンクする必要があります。SAMLIDを検証していないユーザーにコントリビュートを再割り当てすると、エラーメッセージが表示されます。これらのメッセージは、グループメンバーシップが正しく関連付けられるようにするための手順を説明しています。

### 管理者エリアでプレースホルダーユーザーをフィルタリングする {#filter-placeholder-users-in-admin-area}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/admin_area.md#administering-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/521974)

{{< /details >}}

以前は、インポート中に作成されたプレースホルダーユーザーは、**管理者**エリアの**ユーザー**ページで通常のユーザーと混ざって表示され、明確な区別がありませんでした。

このリリースにより、管理者は**管理者**エリアの**ユーザー**ページにある検索ボックスからプレースホルダーアカウントをフィルタリングできるようになりました。これを行うには、ドロップダウンリストで`Type`を選択し、次に`Placeholder`を選択します。

### プレースホルダーユーザーのユーザー制限がグループ使用量クォータに表示されます {#placeholder-user-limits-appear-in-group-usage-quotas}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/import/mapping/post_migration_mapping.md#placeholder-user-limits) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/486691)

{{< /details >}}

GitLab.comへのインポートの場合、プレースホルダーユーザーはトップレベルグループごとに制限されます。これらの制限は、GitLabライセンスとシート数によって異なります。このリリースにより、UIでトップレベルグループのプレースホルダーユーザーの使用状況と制限を確認できるようになりました。

現在の使用状況と制限を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。このグループはトップレベルにある必要があります。
1. **設定 > 使用量クォータ**を選択します。
1. **インポート**タブを選択します。

### Geo - 新しいレプリカブルビュー {#geo---new-replicables-view}

<!-- categories: Disaster Recovery, Geo-replication -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/geo/_index.md)

{{< /details >}}

Geoのレプリカブルビューに新しいルックアンドフィールを導入します。この新しいエクスペリエンスは、GitLabの他の部分とより適切に連携し、Geoセカンダリサイトの同期および検証ステータスをレビューするための、より合理化され、すっきりとしたインターフェースを提供します。さらに、各レプリカブル項目にはクリック可能な詳細ビューが用意され、主要および副次的なチェックサム、エラー詳細などの情報が提供されます。この情報は、Geo同期イシューのトラブルシューティングをはるかに容易にします。

### Linuxパッケージの改善 {#linux-package-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/) | [関連イシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8504)

{{< /details >}}

GitLab 18.0では、PostgreSQLの最小サポートバージョンはバージョン16になります。この変更に備え、[PostgreSQLクラスター](../../administration/postgresql/replication_and_failover.md)を使用しないインスタンスでは、GitLab 17.11へのアップグレード時にPostgreSQLをバージョン16に自動的にアップグレードしようとします。

[PostgreSQLクラスター](../../administration/postgresql/replication_and_failover.md)を使用する場合、または[この自動アップグレードをオプトアウトする](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades)場合は、GitLab 18.0にアップグレードするために[手動でPostgreSQL 16にアップグレードする](https://docs.gitlab.com/omnibus/settings/database/#upgrade-packaged-postgresql-server)必要があります。

### デプロイ前のイベントデータ共有無効化切り替えオプション {#pre-deployment-opt-out-toggle-to-disable-event-data-sharing}

<!-- categories: Application Instrumentation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/settings/event_data.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/510333)

{{< /details >}}

GitLab 18.0では、GitLab Self-ManagedおよびGitLab Dedicatedインスタンスからのイベントレベルの製品使用データ収集を有効にする予定です。集計データとは異なり、イベントレベルのデータはGitLabに利用状況に関するより深いインサイトを提供し、プラットフォームのユーザーエクスペリエンスを改善し、機能の採用を増やすことを可能にします。

GitLab 17.11から、イベントデータ収集が開始される前にオプトアウトする機能が提供され、事実上、事前に参加を選択できるようになります。オプトアウトの方法に関する詳細については、ドキュメントをご覧ください。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### シークレットプッシュ保護とパイプラインシークレット検出のルールカバレッジの増加 {#increased-rule-coverage-for-secret-push-protection-and-pipeline-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/secret_detection/detected_secrets.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/534106)

{{< /details >}}

GitLabシークレット検出は、17の新しいシークレットプッシュ保護ルールと12の新しいパイプラインシークレット検出ルールを含む、大幅な更新を受けました。既存のルールの一部も、品質を向上させ、誤検出を減らすために更新されました。詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/blob/main/CHANGELOG.md#v090)のv0.9.0を参照してください。

### Pythonサポート付き静的到達可能性ベータ {#static-reachability-beta-with-python-support}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/static_reachability.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15781)

{{< /details >}}

コンポジション解析チームは、Python用の静的到達可能性のベータサポートをリリースしました。このベータリリースは、安定性、可観測性の強化に焦点を当てており、より容易な設定を介してより良いユーザーエクスペリエンスを提供します。

静的到達可能性は、ソフトウェアコンポジション解析 (SCA) の結果を強化します。GitLab高度なSASTを搭載した静的到達可能性は、プロジェクトのソースコードをスキャンして、どのオープンソース依存関係が使用されているかを特定します。

静的到達可能性によって生成されたデータを、トリアージと修正の意思決定の一部として使用できます。静的到達可能性データは、CVSSとEPSSスコア、およびKEVインジケーターと併用して、脆弱性のより焦点を絞ったビューを提供することもできます。

この機能に関するフィードバックをお待ちしております。ご質問、コメント、または当チームとの連携をご希望の場合は、この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/535498)をご覧ください。

### 反映型XSSチェックの動的な解析サポート {#dynamic-analysis-support-for-reflected-xss-checks}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dast/browser/checks/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/525861)

{{< /details >}}

動的な解析チームは、[CWE-79](https://cwe.mitre.org/data/definitions/79.html)のチェックを導入しました。この作業により、当社のDASTスキャナーは反映型XSS攻撃をチェックできます。

反映型XSSのチェックはデフォルトで有効になっています。このチェックをオフにするには、設定で`DAST_FF_XSS_ATTACK: false`を設定します。ご質問やフィードバックがある場合は、[イシュー525861](https://gitlab.com/gitlab-org/gitlab/-/issues/525861)をご覧ください。

### コード提案でインポートされたファイルをコンテキストとして使用する {#use-imported-files-as-context-in-code-suggestions}

<!-- categories: Code Suggestions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/project/repository/code_suggestions/context.md#using-imported-files-as-context) | [関連エピック](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/58)

{{< /details >}}

GitLab Duoコード提案は、IDEでインポートされたファイルを使用して、提案の品質を向上させることができるようになりました。インポートされたファイルは、プロジェクトに関する追加のコンテキストを提供します。インポートされたファイルのコンテキストは、JavaScriptおよびTypeScriptファイルでサポートされています。

### コンプライアンスフレームワーク作成時にプロジェクトを割り当てる {#assign-projects-when-creating-compliance-frameworks}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate、Premium
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_frameworks/_index.md#apply-a-compliance-framework-to-a-project) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/500520)

{{< /details >}}

以前は、コンプライアンスフレームワークを作成した後、コンプライアンスセンターの**プロジェクト**タブに移動することなく、新しいコンプライアンスフレームワークをプロジェクトに割り当てることはできませんでした。この状況は、グループでの新しいコンプライアンスフレームワークの作成に不要な摩擦を生み出していました。

GitLab 17.11では、コンプライアンスフレームワークを作成する際に、作成前に複数のプロジェクトをコンプライアンスフレームワークに割り当てるオプションを提供する新しいステップを導入しました。

この新機能:

- コンプライアンスフレームワーク作成ワークフローを維持するのに役立ちます。
- コンプライアンスフレームワークがグループ内のプロジェクトと連携して、グループ全体のコンプライアンス遵守をモニタリングおよび強制することを理解するためのガイダンスを提供します。

### Kubernetes 1.32のサポート {#kubernetes-132-support}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509283)

{{< /details >}}

このリリースでは、2024年12月にリリースされたKubernetesバージョン1.32の完全なサポートが追加されます。アプリをKubernetesにデプロイする場合、接続されているクラスターを最新のバージョンにアップグレードし、すべての機能を活用できるようになりました。

[当社のKubernetesサポートポリシーおよびその他のサポートされているKubernetesバージョン](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)の詳細については、こちらをご覧ください。

### Switchboardで複数のIdentity Providerを使用してSAMLシングルサインオンを設定する {#configure-saml-single-sign-on-with-multiple-identity-providers-in-switchboard}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- プラン: Gold
- リンク: [ドキュメント](../../administration/dedicated/configure_instance/authentication/saml.md)

{{< /details >}}

GitLab Dedicatedインスタンスに対して、最大10個のIdentity Provider (IdP) でSAMLシングルサインオン (SSO) を設定できるようになりました。

GitLab Dedicatedインスタンスで利用可能なすべてのSAML設定オプションは、各個別のIdPに対して設定できます。

以前に複数のIdPを設定していた場合は、既存のすべてのSAML設定をSwitchboardで直接表示および編集できるようになりました。

### 依存プロキシのDocker Hub認証UI {#docker-hub-authentication-ui-for-the-dependency-proxy}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/dependency_proxy/_index.md#authenticate-with-docker-hub) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/521954)

{{< /details >}}

GitLab依存プロキシにおけるDocker Hub認証のUIサポートを発表できることを嬉しく思います。この機能は当初GitLab 17.10でGraphQLAPIサポートのみで導入されましたが、現在はより簡単な設定のためのユーザーインターフェースが含まれています。

この機能強化により、グループの設定ページから直接Docker Hub認証を設定できるようになり、以下のことが可能になります:

- レート制限によるパイプラインの失敗を回避します。
- プライベートDocker Hubイメージにアクセスします。
- Docker Hubの認証情報、[パーソナルアクセストークン](https://docs.docker.com/security/for-developers/access-tokens/) 、または[組織のアクセストークン](https://docs.docker.com/security/for-admins/access-tokens/)を安全に保存します。

この合理化されたアプローチにより、GraphQLAPIを使用することなく、CI/CDパイプラインでDocker Hubイメージへの中断のないアクセスを維持しやすくなります。

### 進行中の作業制限をウェイトで設定する {#set-work-in-progress-limits-by-weight}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/issue_board.md#work-in-progress-limits) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/119208)

{{< /details >}}

イシュー数に加えてウェイトで進行中の作業制限を設定できるようになり、チームのワークロードを管理する上でより柔軟性が得られます。

イシューの数だけでなく、各タスクの複雑さや労力に基づいて作業の流れを制御します。イシューウェイトを使用して労力を表すチームは、特定のボードリスト内のイシューの合計ウェイトを制限することで、過剰なコミットをしないようにできるようになりました。

この機能を使用して、チームの生産性を最適化し、さまざまなタスクの複雑さを考慮した、よりバランスの取れたワークフローを作成します。

### Wikiサイドバーのスタイルが改善されました {#improved-wiki-sidebar-styling}

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/wiki/_index.md#customize-sidebar)

{{< /details >}}

カスタムWikiサイドバーは、見出しサイズが縮小され、リストの左パディングが改善され、スタイリングが向上しました。これらの人間工学に基づいた機能強化により、`_sidebar`Wikiページを通じて作成されたカスタムナビゲーションの可読性が向上します。

カスタムサイドバーは、チームが独自の知識ベース構造に合った方法でWikiコンテンツを整理するのに役立ちます。このスタイリングアップデートにより、サイドバーはスキャンしやすくなり、チームメンバーが関連情報をより迅速に見つけられるようにする、より明確な視覚的階層が作成されます。

### GLQLビューで最終コメントを列として表示する {#display-last-comment-as-a-column-in-glql-views}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/glql/fields.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/512154)

{{< /details >}}

GLQLビューは、イシューまたはマージリクエストの最終コメントを列として表示するようになりました。GLQLクエリに`lastComment`をフィールドとして含めることで、現在のコンテキストを離れることなく最新の更新を表示できます。

以前は、最終コメントを表示するために各イシューまたはマージリクエストを個別に開く必要があり、時間がかかり、進捗状況の概要を素早く把握することが困難でした。この改善により、進行中の会話とステータス更新を一目で確認できる表示レベルが提供され、チームが勢いを維持するのに役立ちます。

この機能強化および一般的なGLQLビューに関するフィードバックを、弊社の[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509791)でお待ちしております。

### GitLab Pages用のNuxtプロジェクトテンプレート {#nuxt-project-template-for-gitlab-pages}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/pages/getting_started/pages_new_project_template.md)

{{< /details >}}

GitLabは最も人気のある静的サイトジェネレーター (SSG) 用のテンプレートを提供しており、Vue.js上に構築された強力なフレームワークであるNuxtを使用してGitLab Pagesサイトを作成できるようになりました。Nuxtは、設定のオーバーヘッドを削減し、モダンでパフォーマンスの高いウェブアプリケーションを構築したいチームにとって特に価値があります。

この追加により、初期設定と設定に時間を費やすことなく、組み込みのCI/CDパイプラインとモダンなデベロッパーエクスペリエンスでPagesサイトを迅速に立ち上げるためのオプションが広がります。

### プロジェクト依存関係リストのCycloneDXエクスポート {#cyclonedx-export-for-the-project-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md#export) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/524733)

{{< /details >}}

多くの組織は現在、規制要件を満たし、ソフトウェアサプライチェーンのセキュリティをさらに高めるために、ソフトウェア部品表 (SBOM) を要求しています。以前は、依存関係リストをGitLabからJSONまたはCSVファイルとしてのみエクスポートできました。現在、GitLabは広く採用されているCycloneDX形式で依存関係リストをエクスポートすることにより、SBOMを生成できます。

SBOMをCycloneDXファイルとして直接ダウンロードするには、依存関係リストで**エクスポート** > **CycloneDX (JSON) としてエクスポートする**を選択します。

### 依存関係リストと脆弱性レポートのエクスポートのメール配信 {#email-delivery-for-dependency-list-and-vulnerability-report-export}

<!-- categories: Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md#export) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/513149)

{{< /details >}}

以前は、依存関係リストまたは脆弱性レポートをエクスポートする際、エクスポートが完了するまでページに留まり、レポートをダウンロードする必要がありました。

現在、依存関係リストまたは脆弱性レポートのエクスポートが完了すると、ダウンロードリンク付きのメールで通知されます。

### CSV形式で依存関係リストをエクスポートする {#export-dependency-list-in-csv-format}

<!-- categories: Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md#export) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/435843)

{{< /details >}}

以前は、GitLabからCSVファイルとして依存関係リストをエクスポートすることはできませんでした。現在、依存関係リストをダウンロードする際、新しいCSVオプションを選択して、この形式でリストをエクスポートできます。

### ツールフィルターがスキャナーとレポートタイプフィルターに置き換えられました {#tool-filter-replaced-with-scanner-and-report-type-filters}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#report-type-filter) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/503371)

{{< /details >}}

以前は、脆弱性レポートの**tool**検索フィルターでは、スキャナーの種類（ESLintやGemnasiumなど）とレポートの種類（SASTやコンテナスキャンなど）を含む単一のツールグループに基づいて結果をフィルターできました。

適切なツールをより簡単に見つけられるように、**tool**フィルターを**scanner**フィルターと**report type**フィルターに置き換えました。これら各種類のツールに基づいて検索を個別にフィルターできるようになりました。

### CI/CDジョブの`source`値を保存してフィルターする {#store-and-filter-a-source-value-for-cicd-jobs}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/jobs.md#retrieve-a-job-by-job-id) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11796)

{{< /details >}}

GitLab 17.11では、CI/CDジョブのソース属性を追跡することで、ユーザーがビルドアーティファクトの起源を検証できる新機能を導入します。この機能強化は、セキュリティとコンプライアンスワークフローにとって特に価値があります。たとえば、組織はソフトウェアサプライチェーンのセキュリティ対策を実装したり、コンプライアンス目的でセキュリティスキャンの検証可能な証拠を要求したりできます。

GitLabのジョブは、その起源が以下からであるかどうかを識別する`source`値を保存および表示するようになりました:

- スキャン実行ポリシー
- パイプライン実行ポリシー
- 通常のパイプライン

**ビルド** > **ジョブ**ページで新しいフィルターオプションを使用するか、ジョブAPIを使用するか、またはアーティファクト検証のためにIDトークン`claims`を通じて`source`属性にアクセスできます。

この新機能により、次のことが可能になります:

- セキュリティスキャン結果の信頼性を検証します。
- ソースタイプでジョブをフィルターして、ポリシーが適用されたスキャンを迅速に特定します。
- 新しいIDトークンクレームを使用してアーティファクトの暗号学的検証を実装します。
- 適切な監査証跡により、コンプライアンス要件が満たされていることを確認します。

セキュリティおよびコンプライアンスチームは、この機能を活用して次のことができます:

- ジョブページで新しいフィルターを使用して、ポリシーによって強制されるジョブのみを表示します。
- ジョブAPIの`source`フィールドにアクセスすることで、タスクを自動化します。
- 新しいIDトークンクレームを使用してアーティファクト検証を実装します:
  - `job_source`: ジョブの起源を識別します。
  - `job_policy_ref_uri`: ポリシーファイル (ジョブがポリシーで定義されている場合) を指します。
  - `job_policy_ref_sha`: ポリシーのGitコミットSHAが含まれています。

### アクセストークンのソートオプションを強化 {#enhanced-sorting-options-for-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/personal_access_tokens.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/519716)

{{< /details >}}

UIとAPIでアクセストークンの追加のソートオプションが利用可能になりました。これらのソートオプションは、GitLabの既存のトークン管理機能を補完し、アクセストークンのインベントリをより詳細に制御し、アクセストークンのセキュリティをより適切に維持するのに役立ちます。新しいソートオプションは次のとおりです:

- 有効期限（昇順）でソート: 最も早く有効期限が切れるトークンを表示します。
- 有効期限（降順）でソート: 残りのライフタイムが最も長いトークンを表示します。
- 最終使用日（昇順）でソート: 最近使用されていないトークンを表示します。
- 最終使用日（降順）でソート: 最も最近使用されたトークンを表示します。

### サービスアカウント管理用のトークン統計 {#token-statistics-for-service-account-management}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/service_accounts.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/520472)

{{< /details >}}

サービスアカウントのトークン管理インターフェースに、トークンインベントリに関する情報を一目で提供する便利な統計ダッシュボードが追加されました。この情報は、トークンの状態を評価し、注意が必要なトークンを特定するのに役立ちます。統計ダッシュボードには、4つの主要なメトリクスが含まれています:

- アクティブなトークン: アクティブなトークンの総数を表示します。
- 有効期限切れ間近のトークン: 今後2週間で有効期限が切れるトークンを特定します。
- 失効されたトークン: 手動で失効されたトークンを追跡します。
- 有効期限切れのトークン: 以前に有効期限が切れたトークンをモニタリングします。 [Chaitanya Sonwane](https://gitlab.com/chaitanyason9)氏のコントリビュートに感謝します！

### 失敗したジョブのパイプライングラフの表示が改善されました {#improved-pipeline-graph-visualization-for-failed-jobs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/pipelines/_index.md#view-pipelines)

{{< /details >}}

パイプライングラフで、新しい視覚的インジケーターを使用して失敗したジョブを迅速に識別できるようになりました。失敗したジョブグループはパイプライングラフでハイライト表示され、失敗したジョブは各ステージの最上部にグループ化されます。この改善された視覚化は、複雑なパイプライン構造を検索することなく、パイプラインの失敗のトラブルシューティングを行うのに役立ちます。

### キャンセル中の状態にスタックしたCI/CDジョブを強制的にキャンセルする {#force-cancel-cicd-jobs-stuck-in-canceling-state}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/jobs/_index.md#force-cancel-a-job) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/467107)

{{< /details >}}

CI/CDジョブは、時々「キャンセル中」の状態にスタックし、デプロイまたは共有リソースへのアクセスをブロックする可能性があります。

メンテナー[ロール](../../user/permissions.md)を持つユーザーは、ジョブログページから直接、これらのスタックしたジョブを強制的にキャンセルできるようになり、問題のあるジョブを適切に終了させることができます。

### プロジェクトでのRunner管理の改善 {#improved-runner-management-in-projects}

<!-- categories: Fleet Visibility -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/runners_scope.md#project-runners)

{{< /details >}}

プロジェクト内でRunnerをより効率的に管理できるようになりました。Runnerは、以前の2列表示ではなく、単一列のレイアウトで表示され、独自のリストに整理されています。

この改善された整理により、Runnerを見つけて管理するのが簡単になり、割り当てられたプロジェクトのリスト、Runnerマネージャー、およびRunnerが実行したジョブなど、新しい機能が追加されました。GitLab 18.0で計画されている追加のRunner管理の改善については、[イシュー33803](https://gitlab.com/gitlab-org/gitlab/-/issues/33803)を参照してください。

### GitLab Runner 17.11 {#gitlab-runner-1711}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 17.11もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [GitLab Runner Windows実行可能ファイルのコード署名](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2483)

#### バグ修正 {#bug-fixes}

- [GitLab Runner 17.10.0でGitの設定をクリーンアップするとエラーが発生する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38681)
- [`FF_DISABLE_UMASK_FOR_KUBERNETES_EXECUTOR`フラグは`umask`コマンドを無効にしません](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38382)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-11-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.11)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.11)
- [UI改善](https://papercuts.gitlab.com/?milestone=17.11)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
