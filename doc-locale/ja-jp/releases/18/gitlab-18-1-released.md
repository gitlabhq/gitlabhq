---
stage: Release Notes
group: Monthly Release
date: 2025-06-19
title: "GitLab 18.1リリースノート"
description: "GitLab 18.1がリリースされ、Maven仮想レジストリのベータ版が利用可能になりました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年6月19日、GitLab 18.1が以下の機能を備えてリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Chaitanya Sonwane {#this-months-notable-contributor-chaitanya-sonwane}

Chaitanya Sonwaneは、一貫した認証の改善を通じて、GitLabのセキュリティ機能を推進しています。[2025年にマージされた13のコントリビュートにより](https://contributors.gitlab.com/users/chaitanyason9?fromDate=2025-01-01&toDate=2025-12-31)、彼の仕事は認証情報インベントリのフィルタリング、サービスアカウント管理、作業アイテムのユーザービリティを向上させました。彼は以前、サービスアカウントのトークン統計で[GitLab 17.11の主要な機能](https://about.gitlab.com/releases/2025/04/17/gitlab-17-11-released/#token-statistics-for-service-account-management)を提供しました。これにより、「一目でわかる」情報が提供され、サービスアカウントの管理が容易になりました。Chaitanyaは現在、[作業アイテムリストのソート設定をコンテキスト固有にする](https://gitlab.com/gitlab-org/gitlab/-/issues/503587)ことで、GitLabの製品計画におけるユーザーエクスペリエンスをさらに向上させています。

Chaitanyaの仕事は、GitLab組織のセキュリティを直接強化し、プロジェクト全体でのサービスアカウントの使用状況をより良く可視化します。チームは、認証情報をより効果的に追跡し、ローテーションできるようになりました。これにより、セキュリティ上の脆弱性につながる、孤立した認証情報や忘れられた認証情報のリスクが軽減されます。

「Chaitanyaの認証情報インベントリとサービスアカウントへのコントリビュートは、どちらもセキュリティ分野で非常に価値のあるコントリビュートです」と、認証グループ、ソフトウェアサプライチェーンセキュリティステージのシニアフロントエンドエンジニアである[Eduardo Sanz-Garcia](https://gitlab.com/eduardosanz)は述べています。Eduardoは、GitLabの認証チームからの推薦を支持しました。

「Chaitanyaは、トークン統計の概念の実装において重要な役割を果たしました」とEduardoは付け加えています。「彼の認証情報インベントリ作業は、認証情報の追跡可能性とモニタリングを強化するための、非常に要望の多かった機能を提供しました。これは素晴らしいコントリビュートでした！」

ChaitanyaはTATA AIGのソフトウェアエンジニアです。彼は積極的にセキュリティ問題に取り組み、自身のコントリビュートに対する改善について一貫してフォローアップしています。

GitLabのセキュリティ基盤とその他の製品へのChaitanyaの貢献に感謝します！

## 主要な機能 {#primary-features}

### Maven仮想レジストリがベータ版として利用可能になりました {#maven-virtual-registry-now-available-in-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/virtual_registry/maven/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14137)

{{< /details >}}

Maven仮想レジストリは、GitLabでのMaven依存関係管理を簡素化します。Maven仮想レジストリがない場合、各プロジェクトはMaven Central、プライベートリポジトリ、またはGitLabパッケージレジストリから依存関係にアクセスするように設定する必要があります。このアプローチでは、シーケンシャルなリポジトリクエリによってビルドが遅くなり、セキュリティ監査とコンプライアンスレポート作成が複雑になります。

Maven仮想レジストリは、複数のアップストリームリポジトリを単一のエンドポイントの背後に集約することで、これらの問題に対処します。プラットフォームエンジニアは、Maven Central、プライベートレジストリ、およびGitLabパッケージレジストリを単一のURLで設定できます。インテリジェントなキャッシュにより、ビルドパフォーマンスが向上し、GitLabの認証システムと統合されます。組織は、設定のオーバーヘッドの削減、ビルドの高速化、およびセキュリティとコンプライアンスを向上させるための集中型アクセス制御から恩恵を受けます。

Maven仮想レジストリは現在、PremiumおよびUltimateのお客様向けに、GitLab.comとGitLabセルフマネージドの両方でベータ版として利用可能です。GAリリースには、レジストリ設定用のWebベースのUI、共有可能なアップストリーム機能、キャッシュ管理のライフサイクルポリシー、強化された分析などの追加機能が含まれます。現在のベータ版の制限には、トップレベルグループあたり最大20の仮想レジストリと、仮想レジストリあたり20のアップストリームが含まれ、ベータ期間中はAPIのみの設定が利用可能です。

Maven仮想レジストリベータプログラムにご参加いただき、最終リリースの形成にご協力ください。ベータ参加者は、機能への早期アクセス、GitLab製品チームとの直接的な関与、および評価期間中の優先サポートを受けられます。ベータプログラムに参加するには、[イシュー498139](https://gitlab.com/gitlab-org/gitlab/-/issues/498139)で関心を示し、ユースケースの詳細を提供してください。また、[イシュー543045](https://gitlab.com/gitlab-org/gitlab/-/issues/543045)でフィードバックと提案を共有してください。

### Duoコードレビューが一般公開されました {#duo-code-review-is-now-generally-available}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

Duoコードレビューは現在一般公開されており、本番環境での使用準備が整っています。このAIを活用したコードレビューアシスタントは、マージリクエストにインテリジェントで自動化されたフィードバックを提供することで、従来のコードレビュープロセスを変革します。人間のレビュアーが関与する前に、潜在的なバグ、セキュリティの脆弱性、およびコード品質の問題を特定するのに役立ち、レビュープロセス全体をより効率的かつ徹底的にします。これには以下が含まれます:

- **Automated initial review**: Duoコードレビューは、コード変更を分析し、潜在的な問題、改善点、ベストプラクティスに関する包括的なフィードバックを提供します。
- **Interactive refinement**: `@GitLabDuo`をマージリクエストコメントでメンションして、特定の変更や質問に関する的を絞ったフィードバックを得ます。
- **Actionable suggestions**: 多くの提案はブラウザから直接適用でき、改善プロセスを合理化します。
- **Context-aware analysis**: 変更されたファイルの理解を活用し、関連性の高いプロジェクト固有の推奨事項を提供します。

コードレビューをリクエストするには:

- マージリクエストで、`@GitLabDuo`を`/assign_reviewer @GitLabDuo`クイックアクションを使用してレビュアーとして追加するか、GitLab Duoを直接レビュアーとして割り当てます。
- `@GitLabDuo`をコメントでメンションして、特定の質問をしたり、ディスカッションスレッドに関する集中的なフィードバックをリクエストしたりします。
- プロジェクトの設定で自動レビューを有効にすると、GitLab Duoがすべての新しいマージリクエストを自動的にレビューします。

Duoコードレビューは、チームがより高いコード品質基準を維持しながら、手動のレビューサイクルに費やす時間を削減するのに役立ちます。問題を早期に発見し、教育的なフィードバックを提供することで、開発チームにとって品質ゲートと学習ツールの両方として機能します。

\*\*ベータリリースにおけるDuoコードレビューの動作の[概要をご覧ください](https://www.youtube.com/watch?v=FlHqfMMfbzQ)。

この機能の改善を継続するために、[イシュー517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)であなたの経験とフィードバックを共有してください。

### ネイティブGitLab認証情報のパスワード侵害検出 {#compromised-password-detection-for-native-gitlab-credentials}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/user_passwords.md#compromised-password-detection) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/549865)

{{< /details >}}

GitLab.comにサインインすると、GitLab.comはアカウントの認証情報の安全なチェックを実行します。パスワードが既知の漏洩の一部である場合、GitLabはバナーを表示し、メールで通知を送信します。これらの通知には、認証情報を更新する方法に関する手順が含まれています。

最大限のセキュリティのために、GitLabはGitLab用にユニークで強力なパスワードを使用し、2要素認証を有効にし、定期的にアカウントアクティビティをレビューすることを推奨しています。

注: この機能は、ネイティブGitLabユーザー名とパスワードにのみ利用可能です。SSO認証情報はチェックされません。

### [SLSA](https://slsa.dev/)レベル1コンプライアンスをCI/CDコンポーネントで達成 {#achieve-slsa-level-1-compliance-with-cicd-components}

<!-- categories: Artifact Security -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../ci/pipeline_security/slsa/_index.md#sign-and-verify-slsa-provenance-with-a-cicd-component) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15859)

{{< /details >}}

Runnerによって生成されたSLSA準拠の[アーティファクト来歴メタデータ](../../ci/runners/configure_runners.md#artifact-provenance-metadata)に署名し、検証するためのGitLabの新しいCI/CDコンポーネントを使用して、SLSAレベル1コンプライアンスを達成できるようになりました。これらのコンポーネントは、再利用可能なモジュールとして[Sigstore Cosignの機能](../../ci/yaml/signing_examples.md)をラップし、CI/CDワークフローに簡単に統合できます。

## 規模とデプロイ {#scale-and-deployments}

### コード検索におけるファイルごとの複数の一致 {#multiple-matches-per-file-in-code-search}

<!-- categories: Code Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../integration/zoekt/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13127)

{{< /details >}}

完全一致コードの検索（ベータ版）は、同じファイルからの複数の検索結果を単一のビューに統合するようになりました。この改善点:

- 隣接する一致間のコンテキストを保持し、分離された行を表示しません。
- 一致が近い場合に重複するコンテンツを排除することで、視覚的な乱雑さを軽減します。
- ファイルごとの一致数を明確に表示することで、ナビゲーションを強化します。
- エディタで見るようにコードを表示することで、可読性が向上します。

この変更により、リポジトリ全体でコードパターンを見つけて理解することがより効率的になりました。

### GraphQL APIの`projectMembers`に対する新しい`accessLevels`引数 {#new-accesslevels-argument-for-projectmembers-in-graphql-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#projectprojectmembers) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/541386)

{{< /details >}}

当社のGraphQL APIの`projectMembers`フィールドに`accessLevels`引数が追加されたことを発表できることを嬉しく思います。この引数を使用して、APIコールから直接アクセスレベルでプロジェクトメンバーをフィルタリングできます。以前は、プロジェクトメンバーのリスト全体をフェッチしてローカルでフィルターを適用する必要があり、これによりかなりの計算オーバーヘッドが追加されていました。これで、プロジェクトの権限分析と所有権グラフの生成がより高速でリソース効率的になりました。この機能強化は、複雑な権限構造を持つ大規模なデプロイを管理する組織にとって特に価値があります。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### DAST検出の同等性とシークレット検出デフォルトルール {#dast-detection-parity-with-secret-detection-default-rules}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dast/browser/checks/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/549990)

{{< /details >}}

DASTアナライザーは、GitLabのシークレット検出アナライザーで使用される同じデフォルトのシークレット検出ルールを自動的にインジェストするようになりました。この改善により、両方で検出されるシークレットのタイプの一貫性が保証されます。

### 外部カスタムコントロールの`Name`を定義 {#define-a-name-for-external-custom-controls}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_frameworks/_index.md#external-controls) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/527007)

{{< /details >}}

以前は、カスタムコンプライアンスフレームワークを作成する際に、外部カスタムコントロールの名前を定義できなかったため、GitLabコントロールと並べてリスト表示されたときに外部コントロールを識別することが困難でした。

外部カスタムコントロールを定義する際のワークフローの一部として`Name`フィールドを追加しました。これにより、複数の外部カスタムコントロールを作成し、それぞれを一意の名前で明確に定義できるようになります。

### コンプライアンスフレームワークUIにおける要件のページネーション {#pagination-for-requirements-in-compliance-frameworks-ui}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_frameworks/_index.md#add-requirements) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/531039)

{{< /details >}}

コンプライアンスフレームワークを作成する際、最大50の要件を指定できます。

しかし、これほど多くの要件を持つコンプライアンスフレームワークは、UIで多くのスペースを消費するため、ナビゲートが非常に困難になります。

このリリースでは、要件のページネーションを導入し、コンプライアンスフレームワークに多数の要件が関連付けられている場合に、ユーザーが要件をナビゲート、検索、選択しやすくしました。

### UIパフォーマンスとコンプライアンスセンターのフィルタリング機能の改善 {#ui-performance-and-filtering-improvements-for-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

コンプライアンスセンターが提供するUIパフォーマンスとフィルタリングオプションの改善を継続しています。このリリースでは、次のことを行いました:

- UIの速度と、特に多数の要件とプロジェクトがあるページの**Edit Framework**のパフォーマンスを向上させました。
- コンプライアンスセンターの**Compliance status report**タブで、要件、プロジェクト、またはフレームワークでグループ化できる新しいフィルタリングオプションを導入しました。

これらの改善を提供することで、コンプライアンスセンターおよび関連機能が、コンプライアンスセンターを定期的に使用するお客様のために大規模で動作し続けることを保証します。

### コンプライアンスステータスレポートにおけるコントロールステータスのポップアップ {#control-status-pop-up-in-the-compliance-status-report}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_status_report.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/521757)

{{< /details >}}

コンプライアンスステータスレポートのコントロールには、次の3つの異なるステータスがあります:

- 合格
- 失敗
- 保留中

要件に添付されているコントロールの数にかかわらず、少なくとも1つのコントロールが「保留中」だった場合、要件行全体も「保留中」として表示されていました。これは、失敗したコントロールを可視化するための確立されたUXパターンから逸脱していました。このパターンでは、少なくとも1つのコントロールが失敗した場合でも、要件に関連付けられたコントロールの数が表示されていました。

「保留中」のコントロールに対するさらなるコンテキストと情報を提供するために、要件行ステータスにカーソルを合わせると、各コントロールのステータスがリスト表示されるポップアップを提供するようになりました。これで、「保留中」という単一のステータスを見るだけでなく、どのコントロールが保留中で、どのコントロールが潜在的に成功し失敗しているかを理解できるようになりました。

### レビューパネルによる強化されたマージリクエストのレビューエクスペリエンス {#enhanced-merge-request-review-experience-with-review-panel}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/project/merge_requests/reviews/_index.md#submit-a-review) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/525841)

{{< /details >}}

マージリクエストをレビューする際、レビューを提出する前に、提供したすべてのコメントとフィードバックを確認できることは貴重です。以前は、このエクスペリエンスは最後のコメントと保留中のコメントを表示するための追加のポップアップの間で分断されており、全体像を把握することが困難でした。

コードレビューを実施する際、すべての保留中の下書きコメントを1つの整理されたビューに統合する専用のドロワーにアクセスできるようになりました。強化されたレビューパネルは、レビュー提出インターフェースをよりアクセスしやすい場所に移動させ、保留中のコメント数を示す番号付きのバッジを提供します。パネルを開くと、すべての下書きコメントがスクロール可能なリストに整理されて表示され、提出前にフィードバックをレビューおよび管理しやすくなります。

### 権限チェックによるCODEOWNERSファイルの検証強化 {#enhanced-codeowners-file-validation-with-permission-checks}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/project/codeowners/troubleshooting.md#validate-your-codeowners-file) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15598)

{{< /details >}}

GitLabは現在、基本的な構文チェックを超えるCODEOWNERSファイルの強化された検証を提供しています。CODEOWNERSファイルを表示すると、GitLabは包括的な検証を自動的に実行し、マージリクエストワークフローに影響を与える前に、構文と権限の両方の問題を特定するのに役立ちます。

強化された検証は、CODEOWNERSファイルの最初の200の一意のユーザーおよびグループ参照をチェックし、次のことを確認します:

- 参照されているすべてのユーザーとグループがプロジェクトへのアクセス権を持っています。
- ユーザーはマージリクエストを承認するために必要な権限を持っています。
- グループは少なくともデベロッパーレベル以上のアクセス権を持っています。
- グループには、マージリクエストの承認権限を持つユーザーが少なくとも1人含まれています。

このプロアクティブな検証は、設定の問題を早期に発見することで承認ワークフローの混乱を防ぎ、コードオーナーがマージリクエストが作成されたときに、実際にレビュー責任を果たすことを保証します。

### ワークスペースの初期化と`postStart`イベントのカスタム設定 {#custom-workspace-initialization-with-poststart-events}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/workspace/_index.md#user-defined-poststart-events)

{{< /details >}}

GitLabワークスペースは、devfileでのカスタム`postStart`イベントをサポートするようになりました。これにより、ワークスペース起動後に自動的に実行されるコマンドを定義できます。これらのイベントを使用して、次のことができます:

- 開発依存関係を設定します。
- 環境を設定します。
- 手動での介入なしに、プロジェクトをすぐに生産的にするための初期化スクリプトを実行します。

### VS Codeでダウンストリームパイプラインジョブログを表示 {#view-downstream-pipeline-job-logs-in-vs-code}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/editor_extensions/visual_studio_code/cicd/) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895)

{{< /details >}}

VS Code用GitLab Workflow拡張機能は、ダウンストリームパイプラインからのジョブログをエディタに直接表示するようになりました。以前は、子パイプラインからのログを表示するには、GitLab Webインターフェースに切り替える必要がありました。

この機能は、[共同開発プログラム](https://about.gitlab.com/community/co-create/)を通じて開発されました。このコントリビュートをしてくださったTim Ryanに心から感謝します！

### 非アクティブなパーソナルアクセストークンの表示 {#view-inactive-personal-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/profile/personal_access_tokens.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/425053)

{{< /details >}}

GitLabは、アクセストークンの有効期限が切れるか、または失効された後に、自動的に非アクティブ化します。これで、これらの非アクティブなトークンをレビューできます。以前は、アクセストークンは非アクティブになった後は表示されませんでした。この変更により、これらのトークンタイプの追跡可能性とセキュリティが向上します。

### GitLab Query Language (GLQL) ビューのエピックサポートベータ {#epic-support-for-gitlab-query-language-views-beta}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/glql/fields.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/issues/30)

{{< /details >}}

GitLab Query Language (GLQL) ビューに大幅な改善を加えました。これで、クエリでエピックをタイプとして使用して、グループ全体でエピックを検索したり、親エピックでクエリしたりできるようになりました！

これは、当社の計画と追跡機能にとって大きな進歩であり、エピックレベルでのクエリと整理がこれまで以上に容易になります。

### 高度なSASTのPHPサポート {#php-support-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md#supported-languages) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14273)

{{< /details >}}

GitLab高度なSASTにPHPのサポートを追加しました。この新しいクロスファイル、クロスファンクションスキャンサポートを使用するには、[Advanced SASTを有効](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast)にしてください。すでに高度なSASTを有効にしている場合、PHPサポートは自動的にアクティブ化されます。

高度なSASTが各言語で検出する脆弱性のタイプを確認するには、[高度なSASTカバレッジページ](../../user/application_security/sast/advanced_sast_coverage.md)を参照してください。

### 依存関係リストでコンポーネントバージョンでフィルタリング {#filter-by-component-version-in-the-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md#filter-dependency-list) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16431)

{{< /details >}}

これで依存関係リストは、コンポーネントのバージョン番号によるフィルタリングをサポートします。複数のバージョン（例: `version=1.1,1.2,1.4`）を選択できますが、範囲はサポートされていません。この機能は、グループとプロジェクトの両方で利用できます。

### パイプライン実行ポリシーにおける変数の優先順位コントロール {#variable-precedence-controls-in-pipeline-execution-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/pipeline_execution_policies.md#variables_override-type) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16430)

{{< /details >}}

セキュリティチームは、セキュリティ保証とデベロッパーエクスペリエンスの間で繊細なバランスを取ることがよくあります。セキュリティスキャンが適切に強制されることを保証することは重要ですが、セキュリティアナライザーは、適切に実行するために開発チームからの特定の入力を必要とする場合があります。変数の優先順位コントロールにより、セキュリティチームは、新しい`variables_override`設定オプションを通じて、パイプライン実行ポリシーで変数がどのように処理されるかについて詳細な制御を持つようになりました。

この新しい設定を使用すると、次のことができます:

- プロジェクト固有のコンテナイメージパス（`CS_IMAGE`）を許可するコンテナスキャンポリシーを適用します。
- `SAST_EXCLUDED_PATHS`のような低リスク変数を許可し、`SAST_DISABLED`のような高リスク変数をブロックします。
- グローバルCI/CD変数（`AWS_CREDENTIALS`など）で保護（マスクまたは非表示）されたグローバルに共有される認証情報を定義し、プロジェクトレベルのCI/CD変数を通じて、必要に応じてプロジェクト固有のオーバーライドを許可します。

この強力な機能は、2つのアプローチをサポートしています:

- **Lock variables by default**（`allow: false`）: 例外としてリストする特定のものを除き、すべての変数をロックします。
- **Allow variables by default**（`allow: true`）: 変数のカスタマイズを許可しますが、例外としてリストすることで重大なリスクを制限します。

パイプライン実行ポリシーがCI/CDジョブのソースである場合の追跡可能性とトラブルシューティングを改善するために、開発者とセキュリティチームがポリシーによって実行されたジョブログを特定するのに役立つジョブログも導入しています。ジョブログは、変数のオーバーライドの影響に関する詳細を提供し、変数がポリシーによってオーバーライドされているか、またはロックされているかを理解するのに役立ちます。

**Real-world impact**

この機能強化は、セキュリティ要件と開発者の柔軟性の間のギャップを埋めます:

- セキュリティチームは、プロジェクト固有のカスタマイズを許可しながら、標準化されたスキャンを強制できます。
- 開発者は、ポリシーの例外をリクエストすることなく、プロジェクト固有の変数を制御できます。
- 組織は、開発ワークフローを中断することなく、一貫したセキュリティポリシーを実装できます。

この重要な変数制御の課題を解決することで、GitLabは組織が、チームがソフトウェアを効率的に提供するために必要な柔軟性を犠牲にすることなく、堅牢なセキュリティポリシーを実装することを可能にします。

### ボットユーザーと人間ユーザーのフィルタリング {#filter-for-bot-and-human-users}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/moderate_users.md#view-users-by-type) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/541186)

{{< /details >}}

確立されたGitLabインスタンスには、多数の人間ユーザーとボットユーザーが存在することがよくあります。これで、管理者エリアのユーザーリストをユーザータイプでフィルタリングできるようになりました。ユーザーをフィルタリングすると、次のことができます:

- 自動化されたアカウントとは別に、人間ユーザーを迅速に識別して管理します。
- 特定のユーザータイプに対して、対象を絞った管理アクションを実行します。
- ユーザー監査と管理ワークフローを簡素化します。

### ユーザープロファイル内の[ORCID](https://orcid.org/)識別子 {#orcid-identifier-in-user-profile}

<!-- categories: User Profile -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/profile/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/23543)

{{< /details >}}

GitLabは現在、ユーザープロファイルでORCID識別子をサポートしており、研究者や学術コミュニティにとってGitLabをよりアクセスしやすく、価値のあるものにしています。[ORCID](https://orcid.org/)（Open Researcher and Contributor ID）は、研究者が他の研究者と区別される永続的なデジタル識別子を提供し、研究者と彼らの専門的活動との間の自動リンクをサポートし、彼らの仕事が適切に認識されることを保証します。

この機能は、Artois大学の修士課程学生であるThomas LabaletteとErwan Hivinが、[Daniel Le Berre](https://www.ouvrirlascience.fr/appointment-of-daniel-le-berre-as-the-national-coordinator-for-higher-education-and-research-software-forges-in-france/)の監督の下、コミュニティコントリビュートとして開発したもので、学術コミュニティからの長年の要望に応えるものです。

### サービスアカウントパイプライン通知を購読する {#subscribe-to-service-account-pipeline-notifications}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/profile/notifications.md#notifications-about-failed-pipeline-that-doesnt-exist) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/515629)

{{< /details >}}

これで、サービスアカウントによってトリガーされるパイプラインイベントの通知を購読できます。通知は、パイプラインが合格、失敗、または修正されたときに送信されます。以前は、これらの通知は、サービスアカウントが有効なカスタムメールアドレスを持っている場合にのみ、サービスアカウントのメールアドレスに送信されていました。

[Densett](https://gitlab.com/[Densett](https://gitlab.com/Densett)) 、[Gilles Dehaudt](https://gitlab.com/tonton1728) 、[Lenain](https://gitlab.com/lenaing) 、[Geoffrey McQuat](https://gitlab.com/gmcquat) 、および[Raphaël Bihoré](https://gitlab.com/rbihore)のコントリビュートに感謝します！

### Duo脆弱性の修正のSASTカバレッジの増加 {#increased-sast-coverage-for-duo-vulnerability-resolution}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/_index.md#supported-vulnerabilities-for-vulnerability-resolution) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/534307)

{{< /details >}}

以前は、検出された脆弱性を次のCommon Weakness Enumeration（CWE）識別子で手動で解決する必要がありました:

- CWE-78 (コマンドインジェクション)
- CWE-89 (SQLインジェクション)

現在、Duo脆弱性の修正は、これらの脆弱性を自動的に修正できます。

### GitLab Runner 18.1 {#gitlab-runner-181}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.1もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### バグ修正 {#bug-fixes}

- [GitLab 17.10または17.11にアップグレードすると、Runnerがジョブをリクエストしたときに`404`応答を受け取る可能性があります](https://gitlab.com/gitlab-org/gitlab/-/issues/543351)。

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-1-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-1-stable/CHANGELOG.md).md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.1)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.1)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.1)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
