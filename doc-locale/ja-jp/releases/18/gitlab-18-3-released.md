---
stage: Release Notes
group: Monthly Release
date: 2025-08-21
title: "GitLab 18.3 リリースノート"
description: "GitLab 18.3 がリリースされました。Visual Studio 向け Duo Agent Platform（ベータ版）が搭載されています"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年8月21日、GitLab 18.3 が以下の機能とともにリリースされました。

また、今月の注目コントリビューターをはじめ、すべてのコントリビューターの皆様に感謝申し上げます。

## 今月の注目コントリビューター: Ahmed Kashkoush

18.3 では、[Ahmed Kashkoush](https://gitlab.com/ahmad-kashkoush) さんを注目コントリビューターとして表彰できることを嬉しく思います。

Ahmed さんは、今夏の [Google Summer of Code への参加](https://gitlab.com/ahmad-kashkoush/gsoc-2025-final-report)を通じて、[GitLab Web IDE](https://gitlab.com/gitlab-org/gitlab-web-ide) への優れたコントリビューターとして活躍されました。長年にわたるコミュニティからのリクエストに直接応える形で、重要な Git 操作を継続的に実装してきました。
5 件の大規模なマージリクエストには、[コミットと強制プッシュ機能](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/497)、[更新確認メッセージ](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/540)、[コミット修正機能](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/507)、[ブランチ作成操作](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/534)、[ブランチ削除機能](https://gitlab.com/gitlab-org/gitlab-web-ide/-/merge_requests/539)が含まれています。

新機能の実装にとどまらず、Ahmed さんはコミュニティから 24 件のサムズアップを獲得していた、Web IDE からの既存コミット修正という 5 年以上前からの機能リクエストを解決しました。
包括的なブランチ管理の実装により、Web IDE はローカル開発環境との機能の同等性に近づき、基本的な Git 操作のためにインターフェースを切り替える必要がなくなりました。
Ahmed さんの取り組みは、Web IDE を開発者にとってより使いやすくすることで、「誰もがコントリビュートできる」という [GitLab のミッション](https://handbook.gitlab.com/handbook/company/mission/)を直接支援するものです。

Ahmed さんは、Google Summer of Code プログラムを通じてメンターを務めた GitLab のスタッフフロントエンドエンジニア、[Enrique Alcántara](https://gitlab.com/ealcantara) さんから推薦されました。
「Ahmed さんは、実際のユーザーの課題を解決することへの献身を示してくれました」と Enrique さんは語ります。
「彼の取り組みは、集中したコントリビューターが GitLab のコア機能の改善にどれほどの影響を与えられるかを示しています。」

Ahmed さんのコントリビューションは、オープンソース開発におけるメンターシップとコミュニティコラボレーションの力を示すものであり、ローカル環境に関わらず、すべての開発者にとって GitLab をより使いやすくするものです。

Ahmed さん、GitLab の Web IDE への素晴らしいコントリビューションに感謝します！

## 主要機能

### Visual Studio 向け Duo Agent Platform（ベータ版）

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/duo_agent_platform/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/179)

{{< /details >}}

Visual Studio 向け Duo Agent Platform のパブリックベータ版リリースをお知らせします。このリリースにより、Visual Studio ユーザーは IDE 内で直接 Duo Agent Platform の高度な AI 機能を利用できるようになりました。

Duo Agent Platform は、ワークフローに 2 つの強力な機能をもたらします。

- **Agentic Chat**: ファイルの作成・編集、パターンマッチングや grep を使ったコードベースの検索、コードに関する即時回答など、会話形式のタスクを Visual Studio を離れることなく素早く実行できます。
- **エージェントフロー**: 包括的な計画と実装サポートにより、より大規模で複雑なタスクに取り組めます。エージェントフローは、イシュー、マージリクエスト、コミット、CI/CD パイプライン、セキュリティ脆弱性などの GitLab リソースを活用して、高レベルのアイデアをアーキテクチャとコードに変換するのに役立ちます。

両機能は、ドキュメント、コードパターン、プロジェクト情報にわたるインテリジェントな検索を提供し、クイック編集から詳細なプロジェクト分析までシームレスに移行できるようにします。

Visual Studio で Duo Agent Platform ベータ版を今すぐお試しいただき、開発ワークフローにおける新たな生産性と AI アシスタンスをご体験ください。

### 埋め込みビュー（GLQL 搭載）

<!-- categories: Markdown, Wiki, Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/glql/_index.md#embedded-views) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15008)

{{< /details >}}

このリリースでは、GLQL を搭載した埋め込みビューが一般公開されます。GitLab データの動的でクエリ可能なビューを、作業が行われる場所（Wiki ページ、エピックの説明、イシューのコメント、マージリクエスト）に直接作成・埋め込むことができます。

埋め込みビューは、複数の場所を移動することなく作業の進捗を追跡するための安定した基盤をチームに提供します。使い慣れた構文でイシュー、マージリクエスト、エピック、その他の作業アイテムをクエリし、カスタマイズ可能なフィールドとフィルタリングを使用してテーブルまたはリストとして結果を表示できます。

埋め込みビューは、静的なドキュメントをプロジェクトデータと常に同期したダッシュボードに変換し、チームがワークフロー全体でコンテキストを維持し、コラボレーションを向上させるのに役立ちます。

埋め込みビューの継続的な改善に向けて、ご意見をお待ちしています。[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509792)にてご意見・ご提案をお寄せください。

### ダイレクト転送によるマイグレーション

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/import/direct_transfer_migrations.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11398)

{{< /details >}}

ダイレクト転送によるマイグレーションが一般公開されました。ダイレクト転送で GitLab インスタンス間の GitLab グループとプロジェクトをマイグレーションするには、GitLab UI または [REST API](../../api/bulk_imports.md) を使用できます。

[エクスポートファイルのアップロードによるマイグレーション](../../user/project/settings/import_export.md#migrate-projects-by-uploading-an-export-file)と比較して、ダイレクト転送では以下の利点があります。

- 大規模プロジェクトでより確実に動作します。
- ソースインスタンスと宛先インスタンス間のバージョン差が大きいマイグレーションをサポートします。
- マイグレーションプロセスと結果に関するより優れたインサイトを提供します。

GitLab.com では、ダイレクト転送によるマイグレーションがデフォルトで有効になっています。GitLab Self-Managed および GitLab Dedicated では、管理者が[機能を有効化](../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)する必要があります。

### CI/CD ジョブトークンのきめ細かい権限

<!-- categories: Permissions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../ci/jobs/fine_grained_permissions.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15258)

{{< /details >}}

パイプラインのセキュリティがより柔軟になりました。ジョブトークンは、パイプライン内のリソースへのアクセスを提供する一時的な認証情報です。これまで、これらのトークンはユーザーの完全な権限を継承していたため、不必要に広範なアクセス権限が付与されることがありました。

新しいジョブトークンのきめ細かい権限機能により、プロジェクト内でジョブトークンがアクセスできる特定のリソースを正確に制御できるようになりました。これにより、CI/CD ワークフローに最小権限の原則を実装し、CI/CD ジョブトークンでプロジェクトにアクセスする際に、ジョブがタスクを完了するために必要な最小限のアクセスのみを付与できます。

パイプラインにおける長期トークンへの依存を減らすため、[追加のきめ細かい権限](https://gitlab.com/groups/gitlab-org/-/epics/6310)の追加に積極的に取り組んでいます。

### GitLab Duo Self-Hosted でのコードレビュー（ベータ版）

<!-- categories: Code Suggestions, Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/524929)

{{< /details >}}

GitLab Duo Self-Hosted で GitLab Duo コードレビューが利用できるようになりました。この機能は GitLab Duo Self-Hosted でベータ版として提供されており、Mistral、Meta Llama、Anthropic Claude、OpenAI GPT モデルファミリーをサポートしています。

GitLab Duo Self-Hosted でコードレビューを使用することで、データ主権を損なうことなく開発プロセスを加速できます。コードレビューがマージリクエストをレビューすると、潜在的なバグを特定し、直接適用できる改善提案を行います。コードレビューを使用して、人間にレビューを依頼する前に変更を反復・改善してください。

コードレビューに関するフィードバックは[イシュー 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386) にてお寄せください。

### GitLab Duo コードレビューのカスタム指示

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/merge_requests/duo_in_merge_requests.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/545136)

{{< /details >}}

GitLab Duo コードレビューのカスタム指示を使用して、プロジェクト全体で一貫したコードレビュー基準を適用できます。glob パターンを使用してファイルタイプごとに特定のレビュー基準を定義し、言語固有の規約が最も重要な場所に適用されるようにします。

カスタム指示を使用すると、以下のことができます。

- チームのコードレビュー基準を記述する
- glob パターンを使用してファイル固有の指示を定義する
- カスタム指示を参照する明確にラベル付けされたフィードバックを確認する

リポジトリに `.GitLab/duo/mr-review-instructions.YAML` ファイルを作成し、カスタム指示を記述するだけです。GitLab Duo はこれらの指示をレビューに自動的に組み込み、フィードバック提供時に特定の指示グループを引用します。

[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)にてご意見・ご提案をお寄せいただき、この機能の改善にご協力ください。

### GitLab Duo Self-Hosted への独自モデルの持ち込み（ベータ版）

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/517581)

{{< /details >}}

GitLab Duo Self-Hosted で、GitLab Duo 機能に使用する独自のモデルを持ち込めるようになりました。この機能はベータ版で、GitLab Duo Enterprise を利用するすべての GitLab Self-Managed のお客様が利用できます。インスタンス管理者は、サポートされている GitLab Duo 機能で使用する互換性のあるモデルを設定できます。

この機能により GitLab Duo Self-Hosted の柔軟性が向上しますが、すべての GitLab Duo 機能がすべての互換モデルで動作することを GitLab は保証できません。インスタンス管理者は、選択したモデルの互換性とパフォーマンスを検証する責任があります。GitLab は、選択したモデルまたはプラットフォームに固有の問題に対するテクニカルサポートを提供しません。

### GitLab Duo Self-Hosted でのハイブリッドモデル選択（ベータ版）

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17192)

{{< /details >}}

GitLab Duo Self-Hosted で、GitLab AI ベンダーモデルとプライベートに設定されたセルフホストモデルを組み合わせて使用できるようになりました。この機能はベータ版で、GitLab Duo Enterprise のすべてのお客様が GitLab Self-Managed で利用できます。

GitLab Duo Self-Hosted のハイブリッドモデルにより、GitLab Self-Managed インスタンス管理者は、機能ごとにセルフホストモデルとセルフホスト AI ゲートウェイ、または GitLab AI ベンダーモデルと GitLab ホスト型 AI ゲートウェイを選択できるようになりました。これにより、管理者はセキュリティとスケーラビリティの要件のバランスを取ることができます。ハイブリッドモデル選択に関するフィードバックは、[イシュー 561048](https://gitlab.com/gitlab-org/gitlab/-/issues/561048) をご覧ください。

### コンプライアンスフレームワーク管理の違反の表示（ベータ版）

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_violations_report.md)

{{< /details >}}

以前、コンプライアンス違反レポートは、グループ内のすべてのプロジェクトのマージリクエストアクティビティの概要を提供していました。利用可能なコンプライアンス違反は、以下のような職務分離に関するものでした。

- マージリクエストの作成者が自分のマージリクエストを承認した場合の検出。
- 2 件未満の承認でマージリクエストがマージされた場合。

しかし、ユーザーフィードバックにより、実際のコンプライアンスユースケースとの整合性が取れていないため、ユーザーが違反の分類を混乱しやすく理解しにくいと感じていることが明らかになりました。

GitLab 18.3 では、職務分離を超えてコンプライアンスフレームワーク内のコンプライアンス管理と要件の違反を含めることで、違反レポートを大幅に強化しています。
各カスタムコンプライアンスフレームワーク管理には、違反に関する詳細なコンテキストを提供する関連監査イベントがあります。違反を行ったユーザー、発生日時、修正方法などが含まれます。
これには、ユーザーの名前と IP アドレス、および実行可能な修正提案が含まれます。

これらの改善により、コンプライアンスマネージャーは組織が特定のコンプライアンスフレームワークに準拠していることを確認するためのより強力で関連性の高いコンテキストを得られるとともに、コンプライアンス違反を効果的に特定、修正、防止できるという安心感を提供します。

### Web IDE の新しいソース管理操作

<!-- categories: Web IDE -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/web_ide/_index.md#use-source-control)

{{< /details >}}

Web IDE に追加のソース管理機能が追加されたことをお知らせします。ブラウザを離れることなく、Git ワークフローをより効率的に管理できます。**ソース管理**パネルで以下の操作が可能になりました。

- ブランチの作成と削除。
- 既存のブランチをベースとして新しいブランチを作成。
- 最後のコミットを修正してクイック修正を行う。
- インターフェースから直接変更を強制プッシュ。

これらの機能強化により、Git 操作をすぐに利用できるようになります。利用可能な機能については、[ソース管理の使用](../../user/project/web_ide/_index.md#use-source-control)をご覧ください。

### GitLab CI/CD での AWS Secrets Manager サポート

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../ci/secrets/aws_secrets_manager.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17822)

{{< /details >}}

AWS Secrets Manager に保存されたシークレットを CI/CD ジョブで簡単に取得して使用できるようになりました。AWS との新しいインテグレーションにより、GitLab CI/CD を通じた AWS Secrets Manager との連携プロセスが簡素化され、AWS をご利用のお客様のビルドおよびデプロイプロセスの効率化に役立ちます！

[GitLab の共同開発プログラム](https://about.gitlab.com/community/co-create/)を通じてこの機能の構築に貢献してくださった [Markus Siebert](https://gitlab.com/m-s-db) さんと [Henry Sachs](https://gitlab.com/DerAstronaut) さんに感謝します！

### カスタム管理者ロール

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15069)

{{< /details >}}

カスタム管理者ロールにより、GitLab Self-Managed および GitLab Dedicated インスタンスの管理者エリアに詳細な権限が導入されます。完全なアクセスを付与する代わりに、管理者はユーザーが必要とする特定の機能のみにアクセスする専門的なロールを作成できるようになりました。この機能は、組織が管理機能に最小権限の原則を実装し、過剰な権限によるセキュリティリスクを軽減し、運用効率を向上させるのに役立ちます。

ご質問、実装経験の共有、または潜在的な改善についてチームと直接やり取りをご希望の場合は、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509376)をご覧ください。

## エージェントコア

### GitLab Duo Self-Hosted で利用可能なモデルの追加

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/560016)

{{< /details >}}

GitLab Duo Enterprise を利用する GitLab Self-Managed のお客様は、GitLab Duo Self-Hosted で Anthropic Claude 4 を使用できるようになりました。
Claude 4 は AWS Bedrock でサポートされています。オープンソースの OpenAI GPT OSS 20B および 120B が実験的モデルとして追加され、vLLM、Azure OpenAI、AWS Bedrock で利用できます。GitLab Duo Self-Hosted でのこれらのモデルの使用に関するフィードバックは、[イシュー 523918](https://gitlab.com/gitlab-org/gitlab/-/issues/523918) をご覧ください。

## スケールとデプロイ

### 「自分の作業」のグループに対する新しいナビゲーション体験

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/_index.md#group-visibility) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/502487)

{{< /details >}}

**自分の作業**のグループ概要に大幅な改善を加えたことをお知らせします。グループの検索とアクセスを効率化するよう設計されています。
新しいタブ付きインターフェースには、アクセス可能なグループの包括的なビューを提供する**メンバー**タブと、削除待ちのグループを追跡する**非アクティブ**タブが含まれています。
また、適切な権限を持つユーザーのリストビューに**編集**と**削除**アクションを追加することで、グループ管理を効率化しました。
これらの改善により、最も重要なグループを見つけて管理しやすくなることを願っています。

このアップデートに関するフィードバックをお待ちしています！[エピック 18401](https://gitlab.com/groups/gitlab-org/-/epics/18401) のディスカッションに参加して、新しいナビゲーションシステムのご体験をお聞かせください。

### **管理者**エリアのプロジェクトリストの強化

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/admin_area.md#administering-projects) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17782)

{{< /details >}}

GitLab 管理者にとってより一貫したエクスペリエンスを提供するため、**管理者**エリアのプロジェクトリストをアップグレードしました。

- 遅延削除保護: プロジェクトの削除は、GitLab 全体で使用されているのと同じ安全な削除フローに従うようになり、誤ったデータ損失を防ぎます。
- より高速な操作: ページをリロードせずにプロジェクトのフィルタリング、ソート、ページネーションが可能になり、よりレスポンシブなエクスペリエンスを提供します。
- 一貫したインターフェース: プロジェクトリストが GitLab 全体の他のプロジェクトリストの外観と動作に合わせて統一されました。

このアップデートにより、管理者エクスペリエンスが GitLab デザイン標準に沿ったものになり、データを保護するための重要な安全機能が追加されました。プロジェクト管理の将来の機能強化は、プラットフォーム全体のすべてのプロジェクトリストに自動的に反映されます。

## 統合 DevOps とセキュリティ

### 依存関係スキャンアナライザーのファイル位置情報の改善

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#customizing-behavior-with-the-cicd-template) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/537716)

{{< /details >}}

依存関係をそのソースまでトレースできることは、特に脆弱性の修正において重要です。以前は、依存関係スキャンアナライザーが有効期限切れで削除されたジョブアーティファクトにリンクすることがありました。これにより、依存関係のソースまでトレースすることが困難でした。
依存関係スキャンアナライザーは、依存関係を導入したプロジェクトファイルにリンクできるようになりました。このオプションを有効にすると、依存関係リストと脆弱性レポートのリンクが確実に機能します。
ユーザーは、依存関係スキャンジョブに `DS_FF_LINK_COMPONENTS_TO_GIT_FILES=true` を設定することでこの機能を有効にできます。

### ライセンス情報のユーザー定義ソース

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#use-cyclonedx-report-as-a-source-of-license-information) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/501662)

{{< /details >}}

GitLab ライセンスデータベースと CycloneDX SBOM レポートのどちらのライセンス情報ソースを優先するかを選択できるようになりました。これにより、オープンソースの依存関係のライセンス情報のソースをより柔軟に選択できます。
ライセンス情報のソースを定義したいユーザーは、[セキュリティ設定 UI](../../user/application_security/detect/security_configuration.md#with-the-ui) を使用して選択できます。デフォルトでは、ライセンス情報のソースとして SBOM データを使用します。

### 簡潔な DAST ジョブ出力

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dast/browser/troubleshooting.md#what-is-dast-doing) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18342)

{{< /details >}}

GitLab 18.3 では、動的解析セキュリティテストのジョブ出力にいくつかの改善が導入されています。

この改善されたジョブ出力は、スキャン結果の理解と障害のトラブルシューティングに役立つ、明確で構造化された情報を提供します。

ジョブ出力の各セクションは簡潔で直感的であり、出力の最下部にトラブルシューティングドキュメントへのリンクが含まれています。
簡潔なジョブ出力をオーバーライドするには、DAST 設定で `DAST_FF_DIAGNOSTIC_JOB_OUTPUT: "true"` を設定してください。

### インスタンスレベルのコンプライアンスとポリシー管理（ベータ版）

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)

{{< /details >}}

エンタープライズユーザーは、複数のトップレベルグループにわたってコンプライアンスフレームワークとセキュリティポリシーを管理したいと考えています。
これは、インスタンス内のすべてのグループが以下の条件を満たす場合によく見られます。

- 同じコンプライアンスフレームワークを共有している場合。たとえば、グループ内のすべてのプロジェクトが ISO 27001 標準に準拠する必要がある場合。
- 同様のポリシーを適用している場合。たとえば、すべてのグループが同じパイプライン実行ポリシーを共有している場合。

GitLab 18.3 では、GitLab Self-Managed インスタンスのコンプライアンスとセキュリティポリシー管理がベータ版として利用可能になりました。単一のトップレベルグループからコンプライアンスフレームワークとセキュリティポリシーを作成、設定、割り当て、GitLab Self-Managed インスタンス全体の他のすべてのトップレベルグループに適用できるようになりました。

コンプライアンスとセキュリティポリシーのトップレベルグループを使用すると、コンプライアンスフレームワークとセキュリティポリシーを管理・編集できる信頼できる唯一の情報源を持つことができます。
グループ管理者は、これらのコンプライアンスフレームワークとセキュリティポリシーをグループ内のすべてのプロジェクトに適用できます。

選択したトップレベルのコンプライアンスとセキュリティポリシーグループから主要なフレームワークとポリシーを管理することで、GitLab Self-Managed インスタンス全体で主要なコンプライアンスとセキュリティのニーズを管理・適用しやすくなります。
ただし、グループはそれぞれのグループで発生する可能性のある特定の状況やワークフローに対応するために、独自のコンプライアンスフレームワークとセキュリティポリシーを作成する能力を引き続き保持します。

この機能は GitLab Self-Managed のお客様向けです。GitLab.com および GitLab Dedicated のお客様は、すでに単一のトップレベルグループまたはネームスペース内でポリシーを一元管理できるためです。

### シャロークローンによるワークスペースの起動時間の短縮

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/workspace/_index.md#shallow-cloning)

{{< /details >}}

ワークスペースは起動時間を短縮するためにシャロークローンを使用するようになりました。初期化中、GitLab は完全な Git 履歴の代わりに最新のコミット履歴のみをダウンロードします。ワークスペースの起動後、Git はバックグラウンドでシャロークローンを完全なクローンに変換します。

この機能はすべての新しいワークスペースに自動的に適用され、設定は不要で、開発ワークフローには影響しません。

### GitLab 管理の OpenTofu および Terraform ステートの新しい CLI コマンド

<!-- categories: GitLab CLI, Infrastructure as Code -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/infrastructure/iac/terraform_state.md) | [関連イシュー](https://gitlab.com/gitlab-org/cli/-/issues/7954)

{{< /details >}}

GitLab CLI（`glab`）に新しいトップレベルコマンド `opentofu` が追加されました。
`opentofu` コマンドは `terraform` および `tf` コマンドのエイリアスとして設定されており、GitLab 管理の OpenTofu および Terraform ステートの操作を支援します。

以下のコマンドが追加されました。

- `glab opentofu init`: ステートバックエンドをローカルで初期化します。
- `glab opentofu state list`: プロジェクト内のすべてのステートを一覧表示します。
- `glab opentofu state download`: 最新のステートまたは特定のバージョンをダウンロードします。
- `glab opentofu state delete`: ステート全体または特定のバージョンを削除します。
- `glab opentofu state lock`: ステートをロックします。
- `glab opentofu state unlock`: ステートのロックを解除します。

`opentofu` コマンドでステートを管理するには、`glab` 1.66 以降が必要です。

### Kubernetes 1.33 のサポート

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/538906)

{{< /details >}}

GitLab は Kubernetes バージョン 1.33 を完全にサポートするようになりました。アプリを Kubernetes にデプロイしている場合、接続されているクラスターを最新バージョンにアップグレードして、すべての機能を活用できます。

詳細については、[GitLab 機能でサポートされている Kubernetes バージョン](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)をご覧ください。

### OAuth アプリが SSO 認証をサポート

<!-- categories: Pages, System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../api/oauth2.md#authorization-code-flow)

{{< /details >}}

OAuth アプリケーションが組織のシングルサインオン要件とシームレスに統合できるようになりました。以前は、ユーザーは GitLab で一度、SSO で一度と 2 回認証する必要があり、不必要な摩擦と複雑さが生じていました。

OAuth アプリケーションは、認証リクエストにパラメーターを指定することで、必要に応じて SSO 認証を自動的にトリガーできるようになりました。これにより以下が提供されます。

- ユーザーへの統一された認証エクスペリエンス
- 組織の SSO ポリシーへの自動準拠
- すべての GitLab インテグレーションにわたる一貫したセキュリティ
- パラメーターを追加するだけの開発者向けシンプルな実装

OAuth インテグレーションは SSO ポリシーを自動的に遵守するようになり、セキュリティを維持しながら混乱を招く認証ワークフローを排除します。

### GitLab Pages サイトのユニークドメインデフォルトの制御

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../administration/pages/_index.md#disable-unique-domains-by-default)

{{< /details >}}

管理者は、新しい GitLab Pages サイトのユニークドメインのデフォルト動作を設定できるようになりました。デフォルトでは、新しい Pages サイトはサイト間の Cookie 共有を防ぐためにユニークドメイン URL（`my-project-1a2b3c.example.com` など）を使用します。

このインスタンスの新しい設定により、新しい Pages サイトがデフォルトでパスベースの URL（`my-namespace.example.com/my-project` など）を使用するように設定できます。これにより、組織は GitLab Pages の動作をワークフローとセキュリティ要件に合わせることができます。

ユーザーは個々のプロジェクトに対してこの設定をオーバーライドでき、既存の Pages サイトは影響を受けません。

### Wiki 機能の強化

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/discussions/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16403)

{{< /details >}}

このリリースでは、3 つの主要な改善を含む強化された Wiki エクスペリエンスが導入されます。Wiki ページをサブスクライブしたり、ページ編集中に Wiki コメントを表示したり、Wiki ページのコメントをソートしたりできるようになりました。

これらの機能強化により、チームはドキュメントでより効果的にコラボレーションできます。

- コンテキスト内でコンテンツを直接ディスカッションする。
- 改善点や修正点を提案する。
- ドキュメントを正確かつ最新の状態に保つ。
- 知識と専門知識を共有する。

これらのアップデートにより、GitLab Wiki は直接のフィードバックとディスカッションを通じてプロジェクトとともに進化するドキュメントになります。

### エピックの担当者、マイルストーンなどの一括編集

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md#bulk-edit-epics) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11901)

{{< /details >}}

グループ内でより多くのエピック属性を一括編集できるようになりました。ラベルに加えて、複数のエピックの担当者、ヘルスステータス、サブスクリプション、機密性、マイルストーンを一度に更新できるようになりました。

この機能強化により、複数のエピックに同じ変更を同時に適用できるため、大量のエピックをより迅速に管理できます。

### API を介したパイプライン実行ポリシーへの CI/CD 設定アクセスの付与

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../api/projects.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/524124)

{{< /details >}}

Projects REST API を使用して、新しい `spp_repository_pipeline_access` フィールドでセキュリティポリシープロジェクトの**パイプライン実行ポリシー**設定をプログラムで有効または無効にできます。以前は、この設定は GitLab UI からのみ管理できました。この機能強化により、以下が可能になりました。

- 現在の**パイプライン実行ポリシー**ステータスを `GET` で取得する。
- `PUT` で設定をプログラムで有効または無効にする。

この改善により、大規模なセキュリティポリシーを管理するチームの自動化とインテグレーションワークフローが向上します。

### 脆弱性レポートでの OWASP 2021 によるグループ化

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#advanced-vulnerability-management) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/532703)

{{< /details >}}

プロジェクトとグループの脆弱性レポートで、OWASP Top 10 2021 カテゴリ別に脆弱性をグループ化できるようになりました。GitLab.com および GitLab Dedicated インスタンスのみで利用可能です。

### スキャン実行ポリシーテンプレート

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/scan_execution_policies.md#scan-execution-policy-editor) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11919)

{{< /details >}}

スキャン実行ポリシーテンプレートを使用すると、一般的なユースケースに基づいてスキャン実行ポリシーを素早く作成できます。3 つのテンプレートから選択できます。

- マージリクエストセキュリティ
- スケジュールスキャン
- リリースセキュリティ

テンプレートを選択したら、テンプレートで有効にする GitLab セキュリティスキャンを選択して、すぐに使い始めることができます。より高度なユースケースがある場合は、カスタム設定に切り替えて、特定のブランチパターン、パイプラインソースなどでポリシーを拡張できます。

### セキュリティポリシーの監査イベント

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/audit_event_streaming.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15869)

{{< /details >}}

GitLab Ultimate では、セキュリティポリシー管理のための包括的な監査イベントが提供されるようになり、各セキュリティポリシープロジェクト内でイベントが整理・一元化されています。

セキュリティチームは以下のことができるようになりました。

- 詳細なメタデータを含むすべてのポリシー変更を追跡する。
- スキャンおよびパイプライン実行の失敗を含む適用失敗を監視する。
- スキップされたスキャン実行とパイプライン実行パイプラインを監視する。
- ポリシー違反のある MR のマージを含む、各プロジェクト内のポリシー違反を検出する。
- 制限を超えた場合にアラートを受け取る。
- ポリシー設定エラーを検出する。
- 大量シナリオ向けのストリーミング専用オプションを使用する。

新しい監査イベントには以下が含まれます。

- [security_policy_create](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_create](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_create.yml).yml)
- [security_policy_delete](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_delete](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_delete.yml).yml)
- [security_policy_update](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_update](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_update.yml).yml)
- [security_policy_merge_request_merged_with_policy_violations](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_merge_request_merged_with_policy_violations](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_merge_request_merged_with_policy_violations.yml).yml)
- [security_policy_yaml_invalidated](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_yaml_invalidated](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_yaml_invalidated.yml).yml)
- [security_policies_limit_exceeded](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_yaml_invalidated.yml)
- [security_policy_violations_detected](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_violations_detected](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_violations_detected.yml).yml)（ストリーミング専用）
- [security_policy_pipeline_failed](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_pipeline_failed](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_pipeline_failed.yml).yml)（ストリーミング専用）
- [security_policy_pipeline_skipped](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/[security_policy_pipeline_skipped](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/audit_events/types/security_policy_pipeline_skipped.yml).yml)（ストリーミング専用）
- [merge_request_branch_bypassed_by_security_policy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/audit_events/types/[merge_request_branch_bypassed_by_security_policy](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/audit_events/types/merge_request_branch_bypassed_by_security_policy.yml).yml)

この機能強化により、ポリシーの変更、設定エラー、適用のギャップにアクセスできるようになり、インシデント対応の迅速化と徹底的な監査機能が実現し、セキュリティ対策状況が強化されます。

### 承認ポリシーのサービスアカウントとアクセストークンの例外

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#access-token-and-service-account-exceptions) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18112)

{{< /details >}}

新しい**サービスアカウントとアクセストークンの例外**機能により、必要に応じてマージリクエスト承認ポリシーを回避できるサービスアカウントとアクセストークンを指定できます。これにより、既知の自動化の摩擦を排除しながら、セキュリティ管理を維持します。

**主な機能は以下のとおりです。**

- 自動化ワークフローのサポート: CI/CD パイプライン、プルミラーリング、自動バージョン更新の承認要件を回避するために、特定のサービスアカウント、ボットユーザー、グループアクセストークン、プロジェクトアクセストークンを設定します。サービスアカウントは、人間のユーザーへの制限を維持しながら、承認済みトークンを使用して保護ブランチに直接プッシュできます。
- 緊急アクセスと監査: 包括的な監査証跡を備えた重大インシデントのブレークグラスシナリオを有効にします。すべての回避イベントは、コンテキストと理由を含む詳細な監査ログを生成し、停止やセキュリティ修正時の迅速な対応を可能にしながらコンプライアンス要件をサポートします。
- GitOps インテグレーション: リポジトリミラーリング、外部 CI システム（Jenkins、CloudBees）、自動変更履歴生成、GitFlow リリースプロセスなど、一般的な自動化の課題をアンブロックします。サービスアカウントは、特定のプロジェクトとブランチにスコープされたトークンベースのアクセスで最小限の必要な権限を受け取ります。

この機能強化により、ガバナンス管理を維持しながら、カスタム回避策を排除し、現代の DevOps 自動化ニーズに対応した厳格なセキュリティポリシーが維持されます。

### SAML SSO のセッションタイムアウト属性のサポート

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/saml_sso/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/262074)

{{< /details >}}

GitLab は、Identity Provider（IdP）からの SAML アサーションの `SessionNotOnOrAfter` 属性を自動的に検出して遵守するようになりました。
この属性が存在する場合、GitLab は IdP で指定された時刻にユーザーセッションが期限切れになるように設定し、組織全体で一貫したセッション管理を確保します。この機能は設定変更を必要としません。IdP が属性を提供している場合、GitLab は指定された有効期限を自動的に遵守します。

### サービスアカウントのメール設定オプションの追加

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/profile/service_accounts.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/537976)

{{< /details >}}

デフォルトでは、GitLab は新しいサービスアカウントのメールアドレスを自動的に生成します。組織は UI を通じてサービスアカウントにカスタムメールアドレスを割り当てられるようになりました。以前は、カスタムメール設定はサービスアカウント API を通じてのみ可能でした。この変更により、組織は指定されたメールアドレスへの通知をより適切にルーティングできます。

### エンタープライズユーザーの機能強化

<!-- categories: System Access -->

{{< details >}}

- プラン: Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/enterprise_user/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9262)

{{< /details >}}

GitLab 18.3 では、組織がユーザーのプライバシーとライフサイクル管理をより細かく制御できるエンタープライズユーザーの機能強化が導入されます。

グループオーナーは、Users API を使用してネームスペース内のエンタープライズユーザーを削除できるようになりました。この破壊的なアクションはユーザーのコントリビューションのリンクを解除し、システム全体の Ghost ユーザーに関連付けます。このオプションは、自動化された SCIM インポートで誤って作成されたユーザーのクリーンアップや、ユーザー名とメールを再利用する必要があるフェデレーション環境の管理に特に役立ちます。

さらに、組織はユーザープロフィールのエンタープライズユーザーのメールを非表示にできるようになり、すべてのエンタープライズユーザーに対してより広範なメールプライバシーの適用が可能になりました。

### SSH キーのセキュリティ警告

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/ssh.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/432624)

{{< /details >}}

GitLab は、ユーザーが弱い SSH キーをアップロードした際に UI にセキュリティ警告を表示するようになりました。この警告は、古いキータイプまたはビット長が不十分なキー（2048 ビット未満）に対して表示されます。この変更により、SSH キーのセキュリティベストプラクティスについてユーザーを教育し、より強力な暗号学的キーの使用を促進します。

### GitLab Runner 18.3

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.3 もリリースします！GitLab Runner は、CI/CD ジョブを実行して結果を GitLab インスタンスに送り返す、高いスケーラビリティを持つビルドエージェントです。GitLab Runner は、GitLab に含まれるオープンソースの継続的インテグレーションサービスである GitLab CI/CD と連携して動作します。

#### バグ修正

- [GitLab 18.2.0 で、Runner がサブディレクトリファイルをキャッシュキーとして使用してジョブキャッシュをプルできない](https://gitlab.com/gitlab-org/gitlab/-/issues/556464)
- [Docker executor が断続的にジョブの開始に失敗し、`incorrect username or password` エラーメッセージを返す](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38707)
- [`none` と `empty` の Git ストラテジー間での `*_get_sources` フックの使用における不整合](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38703)
- [非 OLM マニフェストでデプロイされた Operator が誤ったデフォルトイメージを想定する](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/228)
- [CR に `app.kubernetes.io/instance` ラベルがある場合、Operator が誤った名前で ConfigMap を作成する](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/183)
- [OpenShift 4.9 上の Operator 1.10.0 が `gitlab-runner` ネームスペースで Runner ConfigMap の作成とポッドの起動に失敗する](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/138)

#### 新機能

- [GitLab Runner Operator が Runner マネージャーポッドアノテーションをサポートするようになりました](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/245)
- [GitLab Runner Operator が OpenShift 4.19 をサポートするようになりました](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/253)

すべての変更のリストは、GitLab Runner の [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-3-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-3-stable/CHANGELOG.md).md) に記載されています。

## 関連トピック

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.3)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.3)
- [UI の改善](https://papercuts.gitlab.com/?milestone=18.3)
- [非推奨と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
