---
stage: Release Notes
group: Monthly Release
date: 2025-07-17
title: "GitLab 18.2 リリースノート"
description: "GitLab 18.2 がリリースされました。IDE での Duo Agent Platform（ベータ版）が含まれます"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年7月17日、GitLab 18.2 が以下の機能とともにリリースされました。

また、今月の注目コントリビューターをはじめ、すべてのコントリビューターの皆さんに感謝申し上げます。

## 今月の注目コントリビューター: Markus Siebert

[Markus Siebert](https://gitlab.com/m-s-db) 氏は、DB Systel GmbH のプラットフォームエンジニアです。GitLab CI/CD にネイティブな AWS Secrets Manager サポートを追加するコミュニティの取り組みを主導し、パイプラインにおけるシークレット管理というエンタープライズの重要なニーズに応えています。わずか6週間で172件もの活動を記録した Markus 氏は、[Add functionality to retrieve secrest from AWS Secrets Manager](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5587)、[Add GitLab CI config entry for AWS SSM ParameterStore](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191803)、[Documentation for AWS Secrets Manager](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192378) など、複数のマージリクエストを通じて AWS Secrets Manager と AWS Systems Manager Parameter Store の両方のサポート実装に精力的に取り組んできました。

「Markus 氏の取り組みにより、AWS 環境の GitLab ユーザーはサードパーティツールやカスタムスクリプトに頼ることなく、CI/CD のシークレットを安全に管理できるようになります。これは AWS サービスを標準化しているエンタープライズユーザーにとって特に価値があります」と、Markus 氏を推薦した GitLab の Secure 担当シニアバックエンドエンジニア [Aditya Tiwari](https://gitlab.com/atiwari71) 氏は述べています。

初期実装からドキュメント作成まで、フィードバックに基づいてマージリクエストを積極的に維持・改善しながらこの機能を完成させた Markus 氏の献身は、コミュニティコントリビューションの模範であり、AWS ユーザーのために GitLab をより良くするコミュニティ主導の開発の力を示しています。

このコントリビューションは [GitLab Co-Create Program](https://about.gitlab.com/community/co-create/) を通じて提供されました。

GitLab への貴重なコントリビューションに感謝します、Markus！

## 主要機能

### IDE での Duo Agent Platform（ベータ版）

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/556038)

{{< /details >}}

Duo Agent Platform は、エージェント型チャットとエージェントフローを VS Code および JetBrains IDE に直接統合し、コードベースや GitLab プロジェクトとの自然な会話ベースのインタラクションを実現します。

エージェント型チャットは、ファイルの作成・編集、パターンマッチングや grep を使ったコードベース全体の検索、コードに関する即時回答など、素早い会話形式のタスクに適しています。エージェントフローは、より大規模な実装や包括的な計画に対応し、高レベルのアイデアをコンセプトからアーキテクチャへと具体化しながら、イシュー、マージリクエスト、コミット、CI/CDパイプライン、セキュリティ脆弱性などの GitLab リソースにアクセスします。どちらも、ドキュメント、コードパターン、プロジェクト探索のためのインテリジェントな検索機能を提供し、素早い編集から複雑なプロジェクト分析まであらゆる作業をサポートします。

このプラットフォームは、外部データソースやツールへの接続のために Model Context Protocol（MCP）もサポートしており、AI 機能が GitLab の範囲を超えたコンテキストを活用できます。

詳細はブログ記事 [GitLab Duo Agent Platform Public Beta: Next-gen AI orchestration and more](https://about.gitlab.com/blog/gitlab-duo-agent-platform-public-beta/) をご覧ください。

はじめに、[Duo Agent Platform ドキュメント](../../user/duo_agent_platform/_index.md)、[VS Code セットアップガイド](../../user/gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-vs-code)、[JetBrains セットアップガイド](../../user/gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-jetbrains-ides)をご参照ください。

### イシューとタスクのカスタムワークフローステータス

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/work_items/status.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14794)

{{< /details >}}

設定可能なステータスにより、基本的なオープン/クローズのシステムを超えて、チームの実際のワークフローステージを通じて作業アイテムを追跡できます。

ラベルに頼る代わりに、プロセスを正確に反映するカスタムステータスを定義できるようになりました。設定可能なステータスにより、以下のことが可能になります。

- チームの実際のプロセスに合わせた**カスタムワークフローの定義**。
- 検索、更新、レポートが容易な適切なステータスによる**ワークフローラベルの置き換え**。
- イシューのクローズを超えて「完了」または「キャンセル」による**完了結果の明確化**。
- より良いプロジェクトインサイトのための作業アイテムステータスに基づく**正確なフィルタリングとレポート**。
- イシューが列間を移動する際の自動更新を伴う**イシューボードでのステータス使用**。
- 効率的なワークフロー管理のための複数の作業アイテムにわたる**ステータスの一括更新**。
- リンクされた作業アイテムのステータス可視性による**依存関係の追跡**。

カスタムワークフローステータスは**コメントでのクイックアクション**もサポートし、GitLab のオープン/クローズシステムと自動的に同期します。

この機能の改善にご協力ください。ご意見やご提案は[フィードバックイシュー](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/35235)にお寄せください。

### 新しいマージリクエストホームページ

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/merge_requests/homepage.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13448)

{{< /details >}}

作成者とレビュアーの両方として数十のマージリクエストを抱えている場合、複数のプロジェクトにわたるコードレビューの管理は大変な作業になりがちです。

新しいマージリクエストホームページは、今すぐ注意が必要なものをインテリジェントに優先順位付けすることで、レビュー作業のナビゲーション方法を変革します。2つの強力な表示モードがあります。

- **ワークフロービュー**は、コードレビューワークフローのステージ別に作業をグループ化し、レビュー状態ごとにマージリクエストを整理します。
- **ロールビュー**は、作成者かレビュアーかによってマージリクエストをグループ化し、責任の明確な分離を提供します。

**アクティブ**タブには注意が必要なマージリクエストが表示され、**マージ済み**には最近完了した作業が表示され、**検索**では包括的なフィルタリング機能を利用できます。

新しいホームページは、作成済みと割り当て済みの両方のマージリクエストを組み合わせることで可視性を拡大し、委任された作業を見逃すことがなくなります。

### イミュータブルコンテナタグによるセキュリティの向上（ベータ版）

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/packages/container_registry/immutable_container_tags.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15139)

{{< /details >}}

コンテナレジストリは、現代の DevSecOps チームにとって重要なインフラです。しかし、保護されたコンテナタグがあっても、組織は依然として課題に直面しています。タグが作成された後、十分な権限を持つユーザーがそれを変更できてしまいます。これは、本番環境の安定性のためにコンテナイメージの特定のタグ付きバージョンに依存するチームにとってリスクをもたらします。承認されたユーザーによる変更であっても、意図しない変更が生じたり、デプロイの整合性が損なわれたりする可能性があります。

イミュータブルコンテナタグを使用すると、意図しない変更からコンテナイメージを保護できます。イミュータブルルールに一致するタグが作成された後は、誰もコンテナイメージを変更できません。以下のことが可能になります。

- RE2 正規表現パターンを使用して、プロジェクトごとに最大5つの保護ルール（保護ルールとイミュータブルルールの組み合わせ）を作成する。
- latest、セマンティックバージョン（例: v1.0.0）、リリース候補などの重要なタグをあらゆる変更から保護する。
- イミュータブルタグがクリーンアップポリシーから自動的に除外されるようにする。

イミュータブルコンテナタグには次世代コンテナレジストリが必要で、GitLab.com ではデフォルトで有効になっています。GitLab Self-Managed インスタンスでイミュータブルコンテナタグを使用するには、[メタデータデータベース](../../administration/packages/container_registry_metadata_database.md)を有効にする必要があります。

### GitLab Duo を使用した Premium および Ultimate のグループとプロジェクトの制御

<!-- categories: Code Suggestions, Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/gitlab_duo/turn_on_off.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/551895)

{{< /details >}}

GitLab Premium および Ultimate ユーザーは、グループとプロジェクトの IDE における Code Suggestions と GitLab Duo Chat の利用可否を変更できるようになりました。以前は、インスタンスまたはトップレベルグループの利用可否のみ変更できました。

### 新しいグループ概要コンプライアンスダッシュボード

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_overview_dashboard.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13909)

{{< /details >}}

コンプライアンスセンターは、コンプライアンスチームがグループのコンプライアンスステータスレポート、違反レポート、コンプライアンスフレームワークを管理するための中心的な場所です。

新しいグループ概要コンプライアンスダッシュボードにより、コンプライアンスマネージャーはグループ内のすべてのプロジェクトにわたるコンプライアンス情報の集約ビューを得られます。この最初のイテレーションでは、以下の情報が表示されます。

- 特定のコンプライアンスフレームワークでカバーされているプロジェクトの割合。
- グループ内のすべてのプロジェクトで失敗した要件の割合。
- グループ内のすべてのプロジェクトで失敗したコントロールの割合。
- 「注意」が必要な特定のフレームワーク。

この新しいグループ概要により、コンプライアンスマネージャーはコンプライアンス対策状況の明確な全体像を提供する単一の統合ビューを持てるようになりました。

### インスタンスのワークスペース Kubernetes エージェントのマッピング

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/workspace/gitlab_agent_configuration.md#allow-a-cluster-agent-for-workspaces-on-the-instance) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16485)

{{< /details >}}

GitLab 管理者は、インスタンスに対して有効なワークスペース Kubernetes エージェントをマッピングできるようになりました。ユーザーはそのインスタンス内の任意のグループまたはプロジェクトからワークスペースを作成できます。

これにより、組織がワークスペース Kubernetes エージェントを一度プロビジョニングするだけで、インスタンス全体の現在および将来のすべてのプロジェクトからそれらのエージェントにアクセスできるようになり、ワークスペースのスケーラビリティが大幅に向上します。

### セキュリティレポートの PDF エクスポートのダウンロード

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md#export-as-pdf) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16989)

{{< /details >}}

脆弱性管理の取り組みの状態と進捗を他のステークホルダーに伝えるために、各プロジェクトまたはグループのセキュリティダッシュボードを PDF ドキュメントとしてエクスポートできるようになりました。

### 集中型セキュリティポリシー管理（ベータ版）

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md#set-up-centralized-security-policy-management) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17392)

{{< /details >}}

コンプライアンスが重要な大規模組織では、複数のプロジェクトやグループに分散したポリシーの管理に苦労することがよくあります。一元的な可視性がなければ、一貫した適用を確保することは時間のかかる課題となり、コンプライアンスリスクが高まります。

集中型セキュリティポリシー管理は、単一の指定されたコンプライアンスおよびセキュリティポリシー（CSP）グループを通じて、GitLab 組織全体でセキュリティポリシーを作成、管理、適用するための統一されたアプローチを導入します。これにより、セキュリティチームは以下のことができます。

- **ポリシーを一度定義してどこにでも適用**: CSP を通じてインスタンス全体のセキュリティポリシーを一度作成し、すべてのグループとプロジェクトに自動的に適用する。
- **ビジネスユニットポリシーの設定**: トップレベルグループは、CSP グループから組織のポリシーを継承しながら、独自のポリシーセットを設定できる。
- **最小権限の原則への準拠を確保**: インスタンスに適用される中央ポリシー管理レイヤーを確立する。

このベータリリースは、集中型ポリシー管理の基盤フレームワークを確立し、グループ、プロジェクト、またはインスタンスに設定可能な既存のすべてのセキュリティポリシータイプをサポートします。

## エージェントコア

### GitLab Duo Self-Hosted で Mistral Small が利用可能に

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18202)

{{< /details >}}

GitLab Duo Self-Hosted で Mistral Small を使用できるようになりました。このモデルは GitLab Self-Managed インスタンスで利用可能で、GitLab Duo Self-Hosted 上の GitLab Duo Chat と Code Suggestions に完全対応した初のオープンソースモデルです。

## スケールとデプロイ

### 管理者がユーザー確認なしにコントリビューションを再割り当て可能に

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523259)

{{< /details >}}

管理者は、ユーザー確認なしにプレースホルダーユーザーからアクティブユーザーへのコントリビューションの再割り当てができるようになりました。この機能は、ユーザーが再割り当てを承認するためのメールを確認しなかった場合にプロセスが停滞するという、大規模組織の主要な課題に対処します。

ユーザーの代理が有効になっている GitLab インスタンスでは、管理者はユーザー管理ワークフローを効率化しながらデータの整合性を維持できます。ユーザーは再割り当て完了後も通知メールを受け取り、プロセス全体の透明性が確保されます。

### プレースホルダーユーザーから非アクティブユーザーへの再割り当て

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523260)

{{< /details >}}

以前は、管理者はプレースホルダーユーザーからアクティブユーザーへのコントリビューションとメンバーシップの再割り当てのみ可能でした。

GitLab Self-Managed では、管理者はプレースホルダーユーザーから非アクティブユーザーへのコントリビューションとメンバーシップの再割り当てもできるようになりました。この機能により、GitLab インスタンス上のブロック済み、BAN 済み、または非アクティブ化されたユーザーのコントリビューション履歴とメンバーシップ情報を保持できます。

管理者はまずこの設定を有効にする必要があり、有効にすると、この設定は再割り当て中のユーザー確認をスキップしながら安全なアクセス制御を維持することでユーザー管理を効率化します。

## 統合 DevOps とセキュリティ

### マルチアーキテクチャコンテナイメージのコンテナスキャンサポート

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/container_scanning/_index.md#available-cicd-variables) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/543144)

{{< /details >}}

コンテナスキャンに Linux Arm64 コンテナイメージバリアントが追加されました。Linux Arm64 Runner で実行する場合、アナライザーはエミュレーションを必要とせず、より高速な解析が可能になります。また、`TRIVY_PLATFORM` 環境変数をスキャンしたいプラットフォームに設定することで、マルチアーキテクチャイメージをスキャンできるようになりました。

### コンテナスキャンのアーカイブファイルサポートの改善

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/container_scanning/_index.md#scanning-archive-formats) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/501077)

{{< /details >}}

GitLab 18.2 では、コンテナスキャンのアーカイブファイルスキャンサポートが改善されました。特定のパッケージの脆弱性が複数のイメージで見つかった場合、スキャンされた各イメージに帰属する脆弱性が表示されるようになりました。

### JavaScript の静的到達可能性サポート

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/static_reachability.md#supported-languages-and-package-managers) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/502334)

{{< /details >}}

コンポジション解析が JavaScript ライブラリの静的到達可能性をサポートするようになりました。静的到達可能性によって生成されたデータを、トリアージと修正の意思決定に活用できます。静的到達可能性データは、EPSS、KEV、CVSS スコアと組み合わせて使用することで、脆弱性のより焦点を絞ったビューを提供できます。

### DAST ログイン成功検証のサポート改善

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dast/browser/configuration/variables.md#authentication) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/435942)

{{< /details >}}

以前は、`DAST_AUTH_SUCCESS_IF_AT_URL` 変数は認証成功を検証するために完全な URL の一致が必要でした。これは静的なランディングページを持つアプリケーションでは問題なく機能しましたが、ログイン後の URL にログインごとの動的な要素が含まれるアプリケーションでは困難が生じていました。

`DAST_AUTH_SUCCESS_IF_AT_URL` 変数でワイルドカードパターンを使用して動的な URL パターンに一致させられるようになりました。この機能強化により、セッション間で正確な URL が変わる場合でも認証成功を検証するための柔軟性が提供されます。

### 時間ベースのワンタイムパスワード MFA の DAST サポート

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dast/browser/configuration/authentication.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13633)

{{< /details >}}

動的解析が時間ベースのワンタイムパスワード（TOTP）多要素認証をサポートするようになりました。

TOTP MFA が有効なプロジェクトで DAST スキャンを実行して、包括的なセキュリティテストを確保できます。この機能強化により、MFA がデプロイされている本番環境を反映した設定でアプリケーションをテストすることで、より正確なスキャン結果が得られます。

### 監査ストリーミング宛先へのストリーミングの無効化

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../administration/compliance/audit_event_streaming.md#activate-or-deactivate-streaming-destinations) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/537096)

{{< /details >}}

以前は、監査ストリーミング宛先へのストリーミングを一時的に無効化する方法がありませんでした。ストリーム接続のトラブルシューティングや、設定を削除して最初からやり直すことなく設定を変更するなど、さまざまな理由でこれが必要になる場合があります。

GitLab 18.2 では、監査ストリームをアクティブまたは非アクティブに切り替える機能が追加されました。監査ストリームが非アクティブの場合、監査イベントは選択した宛先にストリーミングされなくなります。再アクティブ化すると、監査イベントは再び選択した宛先にストリーミングされます。

### すべての監査ストリーミング宛先のフィルター機能

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/audit_event_streaming.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/524939)

{{< /details >}}

以前は、一部の監査ストリーミング宛先では利用可能なフィルタリング機能がすべて使えませんでした。

UI を通じてすべての宛先のフィルター機能をサポートするようになりました。以下によるフィルタリングが可能です。

- 監査イベントタイプ別。
- グループまたはプロジェクト別。

この変更により、AWS や GCP などの監査イベント宛先でも監査イベントをフィルタリングできるようになりました。

### エピックの表示設定の構成

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/393559)

{{< /details >}}

作業アイテムのリストを表示する際に表示されるメタデータを完全に制御できるようになり、最も重要な情報に集中しやすくなりました。

以前は、すべてのメタデータフィールドが常に表示されており、作業アイテムのスキャンが煩雑になることがありました。担当者、ラベル、日付、マイルストーンなどの特定のフィールドのオン/オフを切り替えてビューをカスタマイズできるようになりました。

### エピックページでエピックをドロワーまたはフルページで開く

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md#open-epics-in-a-drawer) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/536620)

{{< /details >}}

ドロワービューとフルページナビゲーションを切り替える新しいトグルにより、リストページからエピックを開く方法を選択できるようになりました。

ドロワーを使用してエピックリストのコンテキストを維持しながらエピックの詳細を素早く確認するか、詳細な編集や包括的なナビゲーションのためにより多くの画面スペースが必要な場合はフルページを開くことができます。

### 長期計画の強化のためにエピックに[マイルストーン](../../user/project/milestones/_index.md)を割り当てる

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/milestones/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/329)

{{< /details >}}

エピックに[マイルストーン](../../user/project/milestones/_index.md)を直接割り当てられるようになり、戦略的イニシアチブから実行まで自然な計画のカスケードが生まれます。この機能強化により、四半期計画や SAFe プログラムインクリメントなどの長期的な計画ケイデンスをエピックと整合させることができます。同時に、イテレーションを開発スプリントに集中させることができます。

この明確な階層により、管理上のオーバーヘッドを削減し、戦略的イニシアチブが組織のタイムフレームに対してどのように進捗しているかをより良く把握できます。

### エピックをチームメンバーに割り当てる

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md#assignees) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/4231)

{{< /details >}}

エピックを個人に割り当てられるようになり、戦略的イニシアチブの監督責任者が明確になりました。エピックの担当者により、ポートフォリオレベルでの所有権を特定し、長期目標に対するより迅速な意思決定と明確な責任を実現できます。チームはエピックの進捗、依存関係、またはスコープの変更について誰に連絡すべきかをすぐに確認できます。

### GLQL ビューのソートとページネーション

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/glql/_index.md#presentation-syntax) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/502701)

{{< /details >}}

このリリースでは、GLQL ビューのソートとページネーションが強化され、大規模なデータセットの操作が容易になりました。

期日、ヘルスステータス、人気度などの主要フィールドでソートして、最も関連性の高いアイテムをすばやく見つけられるようになりました。新しい「さらに読み込む」ページネーションシステムにより、データ読み込みをより細かく制御でき、圧倒的なフルページ結果の代わりにオンデマンドで読み込まれる管理しやすいチャンクに置き換えられます。

これらの改善により、チームは複雑なプロジェクトデータを効率的にナビゲートし、任意の時点で最も重要なことに集中できます。

### GitLab Flavored Markdown の作業アイテム参照とエディタの改善

<!-- categories: Markdown -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/markdown.md#gitlab-specific-references) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/7654)

{{< /details >}}

GitLab Flavored Markdown で統一された `[work_item:123]` 構文を使用してイシュー、エピック、作業アイテムを参照できるようになりました。この新しい構文は、イシューの `#123` やエピックの `&123` などの既存の参照形式と並行して機能し、`[work_item:namespace/project/123]` によるクロスプロジェクト参照もサポートします。

プレーンテキストエディタには、Enter キーを押したときに[カーソルのインデントを維持する新しい設定](../../user/profile/preferences.md#maintain-cursor-indentation)も追加され、ネストされたリストやコードブロックなどの構造化されたコンテンツの作成が容易になりました。

### 脆弱性レポートの CSV エクスポートに脆弱性 ID を追加

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#exporting) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18033)

{{< /details >}}

以前は、脆弱性レポートの CSV エクスポートに脆弱性 ID が含まれていませんでした。CSV エクスポートに記載された各脆弱性の ID を確認できるようになりました。

### 脆弱性レポートの到達可能性フィルター

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#filtering-vulnerabilities) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/543346)

{{< /details >}}

脆弱性レポートのデータをフィルタリングして、到達可能な脆弱性のみを含めることができるようになりました。到達可能な脆弱性とは、以下の両方に該当する脆弱性です。

- Common Vulnerabilities and Exposures（CVE）リストに掲載されている。
- 明示的にインポートされているライブラリの一部である。

### 脆弱性 GraphQL API が追加情報を返すように

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#vulnerability) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/468913)

{{< /details >}}

GraphQL API を使用して、脆弱性が導入されたパイプラインと最後に検出されたパイプラインを特定できるようになりました。脆弱性 GraphQL API に以下が追加されました。

- `initialDetectedPipeline`: 脆弱性が導入された時期に関する追加のコミット情報（作成者のユーザー名など）を取得するために使用します。
- `latestDetectedPipeline`: 脆弱性が削除された時期に関する追加のコミット情報（コミット SHA など）を取得するために使用します。

### 承認ポリシーのソースブランチパターン例外

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#source-branch-exceptions) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18113)

{{< /details >}}

以前は、GitFlow を使用するチームが `release/*` ブランチを `main` にマージする際に承認のデッドロックが発生することがよくありました。ほとんどのコントリビューターがすでにリリース開発に参加しており、承認者として機能できなかったためです。

マージリクエスト承認ポリシーのブランチパターン例外は、特定のソース-ターゲットブランチの組み合わせに対して承認要件を自動的にバイパスすることでこの問題を解決します。フィーチャーから main へのマージには厳格な承認を設定しながら、リリースから main へのワークフローを効率化できます。

**主な機能:**

- **パターンベースの設定:** 承認要件をバイパスする `release/*` や `hotfix/*` などのソースブランチパターンを定義する
- **シームレスな統合:** ブランチ例外は既存のマージリクエスト承認ポリシーに直接統合され、UI または `policy.yml` ファイルを通じて設定可能。

これにより、標準的な開発ワークフローに対するマージリクエスト承認ポリシーのセキュリティ上の利点を維持しながら、複雑な回避策の必要性がなくなります。

### 依存関係パスの表示

<!-- categories: Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md#dependency-paths) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16815)

{{< /details >}}

以前は、依存関係が直接の依存関係なのか、依存関係の子孫によってインポートされた推移的な依存関係なのかを判断することが困難でした。

新しい依存関係パス機能を使用して、ライブラリが主にインポートされているのか推移的にインポートされているのかを判断できるようになりました。依存関係パスは、プロジェクトおよびグループの依存関係リストと脆弱性の詳細で確認できます。この機能により、開発者はライブラリのインポート方法に応じて修正への最も効率的なパスを判断できます。

### 認証情報インベントリにサービスアカウントトークンが含まれるように

<!-- categories: System Access -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../administration/credentials_inventory.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/421954)

{{< /details >}}

GitLab の認証情報インベントリでサービスアカウントトークンがサポートされるようになり、ソフトウェアサプライチェーン全体で使用されるさまざまな認証方法の可視性と制御が向上しました。認証情報インベントリは、組織全体で使用される認証情報の完全な全体像を提供します。

### 包括的なアセット可視性のためのセキュリティインベントリがベータ版に

<!-- categories: Security Asset Inventories -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/security_inventory/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16484)

{{< /details >}}

AppSec チームは、すべてのアセットにわたる組織のセキュリティ対策状況を包括的に把握する必要があります。以前は、GitLab のセキュリティワークフローは主にプロジェクトレベルのスキャナー設定とプロジェクトレベルの脆弱性に焦点を当てており、カバレッジのギャップを把握し、効率的なリスクベースの優先順位付けの決定を行うことが困難でした。

セキュリティインベントリは、GitLab インスタンス全体のセキュリティ対策状況の一元的なビューを提供し、AppSec チームが以下のことを可能にします。

- プロジェクトとグループ全体のセキュリティカバレッジを完全に把握する
- セキュリティスキャンが不足しているアセットや設定のギャップがあるアセットを特定する
- セキュリティ対策に集中すべき場所について、情報に基づいたリスクベースの決定を行う
- 時間の経過とともにセキュリティ対策状況の改善を追跡する

この機能は、個々のプロジェクトセキュリティと組織全体のセキュリティ戦略の間のギャップを埋め、効果的なセキュリティプログラム管理に必要なアセットインベントリの基盤を提供します。

### カスタム管理者ロールがベータ版に

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15069)

{{< /details >}}

カスタム管理者ロールにより、GitLab Self-Managed および GitLab Dedicated インスタンスの管理者エリアに詳細な権限が導入されます。フルアクセスを付与する代わりに、管理者はユーザーが必要とする特定の機能のみにアクセスする専門的なロールを作成できるようになりました。この機能は、組織が管理機能に最小権限の原則を実装し、過剰な権限によるセキュリティリスクを軽減し、運用効率を向上させるのに役立ちます。

この機能についてのコミュニティフィードバックを積極的に求めています。質問がある場合、実装経験を共有したい場合、または潜在的な改善について私たちのチームと直接関わりたい場合は、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509376)をご覧ください。

### トリガージョブがダウンストリームパイプラインのステータスをミラーリング可能に

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../ci/yaml/_index.md#triggerstrategy) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/431882)

{{< /details >}}

以前は、`strategy:depend` を使用するトリガージョブは、手動ジョブ、ブロックされたパイプライン、または実行中にステータスが変化する再試行されたパイプラインなどの複雑なパイプライン状態を処理する際に制限がありました。これにより、ダウンストリームパイプラインが実際には手動ジョブでブロックされているにもかかわらず、アクティブに実行中であるように見えることがありました。

新しい `strategy:mirror` キーワードは、ダウンストリームパイプラインの正確なリアルタイムステータスをミラーリングすることで、より細かいステータスレポートを提供します。ステータスには `running`、`manual`、`blocked`、`canceled` などの中間状態が含まれます。これにより、既存のワークフローを壊すことなく、ダウンストリームパイプラインの現在の状態を完全に把握できます。

### GitLab Runner 18.2

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.2 もリリースします。GitLab Runner は、CI/CD ジョブを実行して結果を GitLab インスタンスに送信する高スケーラブルなビルドエージェントです。GitLab Runner は、GitLab に含まれるオープンソースの継続的インテグレーションサービスである GitLab CI/CD と連携して動作します。

#### バグ修正

- [GitLab Runner 18.1.0 にアップグレード後、FIPS モードで Runner が失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38890)
- [`FF_USE_DUMB_INIT_WITH_KUBERNETES_EXECUTOR` でジョブポッドを起動できない](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/241)
- [`ubi-fips` イメージが GitLab Runner FIPS のデフォルトヘルパーイメージフレーバーではない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38273)
- [GitLab メンテナンスモードを無効にした後、Runner が長期間オフラインのままになる](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29181)

すべての変更のリストは GitLab Runner の [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-2-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-2-stable/CHANGELOG.md).md) にあります。

## 関連トピック

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.2)
- [パフォーマンスの改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.2)
- [UI の改善](https://papercuts.gitlab.com/?milestone=18.2)
- [非推奨と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
