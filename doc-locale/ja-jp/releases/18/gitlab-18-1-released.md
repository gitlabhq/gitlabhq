---
stage: Release Notes
group: Monthly Release
date: 2025-06-19
title: "GitLab 18.1 リリースノート"
description: "GitLab 18.1がリリースされました。Mavenバーチャルレジストリがベータ版として利用可能になりました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年6月19日、GitLab 18.1が以下の機能とともにリリースされました。

また、今月の注目コントリビューターをはじめ、すべてのコントリビューターの皆様に感謝申し上げます。

## 今月の注目コントリビューター: Chaitanya Sonwane

Chaitanya Sonwaneは、継続的な認証機能の改善を通じてGitLabのセキュリティ機能を強化しています。
[2025年に13件のコントリビューションがマージされ](https://contributors.gitlab.com/users/chaitanyason9?fromDate=2025-01-01&toDate=2025-12-31)、認証情報インベントリのフィルタリング、サービスアカウント管理、作業アイテムのユーザビリティが向上しました。
以前には[GitLab 17.11の主要機能](https://about.gitlab.com/releases/2025/04/17/gitlab-17-11-released/#token-statistics-for-service-account-management)としてサービスアカウントのトークン統計を実装し、サービスアカウントの管理を容易にする「一目でわかる」情報を提供しました。
現在、Chaitanyaは[作業アイテムリストのソート設定をコンテキスト固有に改善する](https://gitlab.com/gitlab-org/gitlab/-/issues/503587)取り組みを進め、GitLabのProduct Planningにおけるユーザーエクスペリエンスをさらに向上させています。

Chaitanyaの取り組みは、GitLab組織のセキュリティを直接強化し、プロジェクト全体のサービスアカウント使用状況の可視性を高めます。
チームは認証情報の追跡とローテーションをより効果的に行えるようになりました。
これにより、セキュリティ上の脆弱性を生む孤立した認証情報や忘れられた認証情報のリスクが軽減されます。

「Chaitanyaの認証情報インベントリとサービスアカウントへのコントリビューションは、セキュリティ分野において非常に価値あるものです」と、Software Supply Chain SecurityステージのAuthenticationグループのシニアフロントエンドエンジニアである[Eduardo Sanz-Garcia](https://gitlab.com/eduardosanz)は述べています。
EduardoはGitLabのAuthenticationチームからのノミネートを支持しました。

「Chaitanyaはトークン統計コンセプトの実装において中心的な役割を果たしました」とEduardoは付け加えます。
「彼の認証情報インベントリの取り組みは、認証情報の追跡可能性とモニタリングを強化するために多くのユーザーから要望されていた機能を実現しました。
素晴らしいコントリビューションです！」

ChaitanyaはTATA AIGのソフトウェアエンジニアです。
セキュリティ上の問題に積極的に取り組み、自身のコントリビューションの改善に継続的にフォローアップしています。

GitLabのセキュリティ基盤とその他の製品へのコントリビューションに感謝します！

## 主要機能

### Mavenバーチャルレジストリがベータ版として利用可能に {#maven-virtual-registry-now-available-in-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../user/packages/virtual_registry/maven/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14137)

{{< /details >}}

MavenバーチャルレジストリはGitLabにおけるMaven依存関係管理を簡素化します。Mavenバーチャルレジストリがない場合、Maven Central、プライベートリポジトリ、またはGitLabパッケージレジストリから依存関係にアクセスするために各プロジェクトを個別に設定する必要があります。このアプローチでは、リポジトリへの順次クエリによってビルドが遅くなり、セキュリティ監査やコンプライアンスレポートが複雑になります。

Mavenバーチャルレジストリは、複数のアップストリームリポジトリを単一のエンドポイントの背後に集約することでこれらの問題に対処します。プラットフォームエンジニアは、Maven Central、プライベートレジストリ、GitLabパッケージレジストリを1つのURLで設定できます。インテリジェントなキャッシュによってビルドパフォーマンスが向上し、GitLabの認証システムと統合されます。組織は設定のオーバーヘッドの削減、ビルドの高速化、セキュリティとコンプライアンスの向上のための一元的なアクセス制御というメリットを享受できます。

Mavenバーチャルレジストリは現在、GitLab.comとGitLab Self-Managed両方のGitLab PremiumおよびUltimateのお客様向けにベータ版として提供されています。GAリリースには、レジストリ設定のためのWebベースのユーザーインターフェース、共有可能なアップストリーム機能、キャッシュ管理のためのライフサイクルポリシー、強化された分析機能などの追加機能が含まれる予定です。現在のベータ版の制限として、トップレベルグループあたり最大20のバーチャルレジストリ、バーチャルレジストリあたり最大20のアップストリームがあり、ベータ期間中はAPIのみの設定が利用可能です。

エンタープライズのお客様には、最終リリースの形成に貢献するためにMavenバーチャルレジストリベータプログラムへの参加をお勧めします。ベータ参加者は、機能への早期アクセス、GitLab製品チームとの直接的な関与、評価中の優先サポートを受けられます。ベータプログラムに参加するには、[イシュー498139](https://gitlab.com/gitlab-org/gitlab/-/issues/498139)で関心を示してユースケースの詳細を提供し、[イシュー543045](https://gitlab.com/gitlab-org/gitlab/-/issues/543045)でフィードバックや提案を共有してください。

### Duo Code Reviewが一般提供開始 {#duo-code-review-is-now-generally-available}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

Duo Code Reviewが一般提供開始となり、本番環境での使用が可能になりました。このAI搭載コードレビューアシスタントは、マージリクエストに対してインテリジェントな自動フィードバックを提供することで、従来のコードレビュープロセスを変革します。人間のレビュアーが関与する前に潜在的なバグ、セキュリティ上の脆弱性、コード品質の問題を特定し、レビュープロセス全体をより効率的かつ徹底的なものにします。主な機能は以下のとおりです。

- **自動初期レビュー**: Duo Code Reviewがコードの変更を分析し、潜在的な問題、改善点、ベストプラクティスについて包括的なフィードバックを提供します。
- **インタラクティブな改善**: マージリクエストのコメントで`@GitLabDuo`をメンションすると、特定の変更や質問に対するターゲットを絞ったフィードバックが得られます。
- **実行可能な提案**: 多くの提案はブラウザから直接適用でき、改善プロセスを効率化します。
- **コンテキスト認識型分析**: 変更されたファイルの理解を活用して、関連性の高いプロジェクト固有の推奨事項を提供します。

コードレビューをリクエストするには:

- マージリクエストで、`/assign_reviewer @GitLabDuo`クイックアクションを使用してレビュアーとして`@GitLabDuo`を追加するか、GitLab Duoを直接レビュアーとして割り当てます。
- コメントで`@GitLabDuo`をメンションして、特定の質問をしたり、ディスカッションスレッドに対するフォーカスされたフィードバックをリクエストしたりします。
- プロジェクト設定で自動レビューを有効にすると、GitLab Duoがすべての新しいマージリクエストを自動的にレビューします。

Duo Code Reviewは、手動レビューサイクルに費やす時間を削減しながら、チームがより高いコード品質基準を維持するのに役立ちます。問題を早期に発見し、教育的なフィードバックを提供することで、開発チームの品質ゲートと学習ツールの両方として機能します。

**[概要を視聴する](https://www.youtube.com/watch?v=FlHqfMMfbzQ)** ベータリリース時のDuo Code Reviewの動作をご覧ください。

フィードバックや体験談は[イシュー517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386)で共有し、この機能の継続的な改善にご協力ください。

### ネイティブGitLab認証情報の侵害パスワード検出 {#compromised-password-detection-for-native-gitlab-credentials}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/user_passwords.md#compromised-password-detection) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/549865)

{{< /details >}}

GitLab.comへのサインイン時に、アカウントの認証情報のセキュアなチェックが実行されるようになりました。
パスワードが既知の漏洩に含まれている場合、GitLabはバナーを表示し、メール通知を送信します。
これらの通知には、認証情報の更新方法に関する手順が含まれています。

最大限のセキュリティを確保するために、GitLabではGitLab専用の強力なユニークパスワードの使用、2要素認証の有効化、アカウントアクティビティの定期的な確認を推奨しています。

注意: この機能はネイティブのGitLabユーザー名とパスワードにのみ対応しています。SSO認証情報はチェックされません。

### CI/CDコンポーネントで[SLSA](https://slsa.dev/) Level 1コンプライアンスを達成 {#achieve-slsa-level-1-compliance-with-cicd-components}

<!-- categories: Artifact Security -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../ci/pipeline_security/slsa/_index.md#sign-and-verify-slsa-provenance-with-a-cicd-component) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15859)

{{< /details >}}

GitLab Runnerが生成するSLSA準拠の[アーティファクトプロベナンスメタデータ](../../ci/runners/configure_runners.md#artifact-provenance-metadata)の署名と検証のための新しいCI/CDコンポーネントを使用して、SLSA Level 1コンプライアンスを達成できるようになりました。これらのコンポーネントは[Sigstore Cosignの機能](../../ci/yaml/signing_examples.md)をCI/CDワークフローに簡単に統合できる再利用可能なモジュールにラップしています。

## スケールとデプロイ {#scale-and-deployments}

### コード検索でファイルごとに複数の一致を表示 {#multiple-matches-per-file-in-code-search}

<!-- categories: Code Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../integration/zoekt/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13127)

{{< /details >}}

完全一致コードの検索（ベータ版）で、同じファイルからの複数の検索結果が単一のビューに統合されるようになりました。この改善により:

- 孤立した行を表示する代わりに、隣接する一致間のコンテキストが保持されます。
- 一致が近接している場合に重複コンテンツを排除することで、視覚的な煩雑さが軽減されます。
- ファイルごとの一致数を明確に表示することで、ナビゲーションが向上します。
- エディタで表示するのと同じようにコードを表示することで、可読性が向上します。

この変更により、リポジトリ全体のコードパターンの検索と理解がより効率的になりました。

### GraphQL APIの`projectMembers`に新しい`accessLevels`引数を追加 {#new-accesslevels-argument-for-projectmembers-in-graphql-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#projectprojectmembers) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/541386)

{{< /details >}}

GraphQL APIの`projectMembers`フィールドに`accessLevels`引数が追加されました。
この引数を使用すると、APIコールから直接アクセスレベルでプロジェクトメンバーをフィルタリングできます。
以前は、プロジェクトメンバーのリスト全体を取得してローカルでフィルタを適用する必要があり、大きな計算オーバーヘッドが生じていました。
これにより、プロジェクトのパーミッションの分析と所有権グラフの生成がより高速かつリソース効率的になりました。
この機能強化は、複雑なパーミッション構造を持つ大規模なデプロイを管理する組織にとって特に価値があります。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### DASTのシークレット検出デフォルトルールとの検出パリティ {#dast-detection-parity-with-secret-detection-default-rules}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dast/browser/checks/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/549990)

{{< /details >}}

DASTアナライザーが、GitLabのSecret Detectionアナライザーで使用されているものと同じデフォルトのシークレット検出ルールを自動的にインジェストするようになりました。この改善により、両者が検出するシークレットの種類の一貫性が確保されます。

### 外部カスタムコントロールに`Name`を定義 {#define-a-name-for-external-custom-controls}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_frameworks/_index.md#external-controls) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/527007)

{{< /details >}}

以前は、カスタムコンプライアンスフレームワークを作成する際に外部カスタムコントロールの名前を定義できなかったため、GitLabコントロールと並べてリストされた際に外部コントロールを識別することが困難でした。

外部カスタムコントロールを定義するワークフローの一部として`Name`フィールドが追加されました。これにより、複数の外部カスタムコントロールを作成し、それぞれに固有の名前を明確に定義できるようになりました。

### コンプライアンスフレームワークUIの要件にページネーションを追加 {#pagination-for-requirements-in-compliance-frameworks-ui}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_frameworks/_index.md#add-requirements) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/531039)

{{< /details >}}

コンプライアンスフレームワークを作成する際、最大50の要件を指定できます。

ただし、これほど多くの要件があるコンプライアンスフレームワークはユーザーインターフェースで多くのスペースを占有するため、ナビゲーションが非常に困難になります。

このリリースでは、コンプライアンスフレームワークに多数の要件が添付されている場合に、ユーザーがナビゲート、検索、選択しやすくするために要件のページネーションを導入しました。

### コンプライアンスセンターのUIパフォーマンスとフィルタリングの改善 {#ui-performance-and-filtering-improvements-for-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

コンプライアンスセンターが提供するUIパフォーマンスとフィルタリングオプションの改善を継続しています。このリリースでは:

- 特に多くの要件とプロジェクトがページに存在する場合の**フレームワークの編集**ページのUIスピードとパフォーマンスを改善しました。
- コンプライアンスセンターの**コンプライアンスステータスレポート**タブで、要件、プロジェクト、またはフレームワークでグループ化できる新しいフィルタリングオプションを導入しました。

これらの改善を提供することで、コンプライアンスセンターを定期的に使用するお客様に対して、コンプライアンスセンターと関連機能がスケールで引き続きパフォーマンスを発揮できるよう取り組んでいます。

### コンプライアンスステータスレポートのコントロールステータスポップアップ {#control-status-pop-up-in-the-compliance-status-report}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_status_report.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/521757)

{{< /details >}}

コンプライアンスステータスレポートのコントロールには3つの異なるステータスがあります:

- Pass（合格）
- Fail（不合格）
- Pending（保留中）

要件に添付されているコントロールの数に関わらず、少なくとも1つのコントロールが「保留中」であれば、要件行全体も「保留中」として表示されていました。これは、失敗したコントロールを視覚化するための確立されたUXパターンから逸脱していました。そのパターンでは、少なくとも1つのコントロールが失敗している場合でも、要件に関連するコントロールの数が表示されます。

「保留中」のコントロールに対してさらなるコンテキストと情報を提供するために、要件行のステータスにカーソルを合わせると、各コントロールのステータスが一覧表示されるポップアップが表示されるようになりました。「保留中」の単一ステータスを見るだけでなく、どのコントロールが保留中で、どのコントロールが成功または失敗している可能性があるかを把握できるようになりました。

### レビューパネルによるマージリクエストレビューエクスペリエンスの強化 {#enhanced-merge-request-review-experience-with-review-panel}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/project/merge_requests/reviews/_index.md#submit-a-review) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/525841)

{{< /details >}}

マージリクエストをレビューする際、レビューを送信する前に提供したすべてのコメントとフィードバックを確認できると便利です。以前は、最終コメントと保留中のコメントを確認するための追加ポップアップの間でエクスペリエンスが分断されており、完全な概要を把握することが困難でした。

コードレビューを実施する際、すべての保留中のドラフトコメントを1つの整理されたビューに統合した専用のドロワーにアクセスできるようになりました。強化されたレビューパネルは、レビュー送信インターフェースをよりアクセスしやすい場所に移動し、保留中のコメント数を示す番号付きバッジを提供します。パネルを開くと、すべてのドラフトコメントがスクロール可能なリストに整理されて表示され、送信前にフィードバックを確認・管理しやすくなります。

### パーミッションチェックによるCODEOWNERSファイル検証の強化 {#enhanced-codeowners-file-validation-with-permission-checks}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/project/codeowners/troubleshooting.md#validate-your-codeowners-file) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15598)

{{< /details >}}

GitLabは、基本的な構文チェックを超えたCODEOWNERSファイルの強化された検証を提供するようになりました。CODEOWNERSファイルを表示すると、GitLabは自動的に包括的な検証を実行し、マージリクエストワークフローに影響を与える前に構文とパーミッションの両方の問題を特定するのに役立ちます。

強化された検証は、CODEOWNERSファイル内の最初の200の固有ユーザーおよびグループ参照をチェックし、以下を検証します:

- 参照されているすべてのユーザーとグループがプロジェクトへのアクセス権を持っていること。
- ユーザーがマージリクエストを承認するために必要なパーミッションを持っていること。
- グループが少なくともデベロッパーレベル以上のアクセス権を持っていること。
- グループにマージリクエスト承認パーミッションを持つユーザーが少なくとも1人含まれていること。

このプロアクティブな検証は、設定の問題を早期に発見することで承認ワークフローの中断を防ぎ、マージリクエストが作成された際にコードオーナーが実際にレビュー責任を果たせることを確保します。

### `postStart`イベントによるカスタムワークスペース初期化 {#custom-workspace-initialization-with-poststart-events}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/workspace/_index.md#user-defined-poststart-events)

{{< /details >}}

GitLabワークスペースがdevfileでカスタム`postStart`イベントをサポートするようになりました。ワークスペース起動後に自動的に実行されるコマンドを定義できます。これらのイベントを使用して:

- 開発依存関係をセットアップする。
- 環境を設定する。
- 手動介入なしにプロジェクトをすぐに使える状態に準備する初期化スクリプトを実行する。

### VS Codeでダウンストリームパイプラインのジョブログを表示 {#view-downstream-pipeline-job-logs-in-vs-code}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/editor_extensions/visual_studio_code/cicd/) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1895)

{{< /details >}}

VS Code用GitLab Workflow拡張機能が、ダウンストリームパイプラインのジョブログをエディタ内に直接表示するようになりました。以前は、子パイプラインのログを表示するにはGitLabのWebインターフェースに切り替える必要がありました。

この機能は[GitLab Co-createプログラム](https://about.gitlab.com/community/co-create/)を通じて開発されました。このコントリビューションを行ったTim Ryanに特別な感謝を申し上げます！

### 非アクティブなパーソナルアクセストークンを表示 {#view-inactive-personal-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/profile/personal_access_tokens.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/425053)

{{< /details >}}

GitLabは、アクセストークンの有効期限が切れるか失効すると自動的に非アクティブ化します。これらの非アクティブなトークンを確認できるようになりました。以前は、アクセストークンは非アクティブになると表示されなくなっていました。この変更により、これらのトークンタイプの追跡可能性とセキュリティが向上します。

### GitLab Query Language ビューのエピックサポート（ベータ版） {#epic-support-for-gitlab-query-language-views-beta}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/glql/fields.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab-query-language/glql-rust/-/issues/30)

{{< /details >}}

GitLab Query Language（GLQL）ビューに重要な改善を加えました。クエリでエピックをタイプとして使用してグループ全体のエピックを検索し、親エピックでクエリを実行できるようになりました！

これはプランニングと追跡機能における大きな前進であり、エピックレベルでのクエリと整理がこれまで以上に容易になります。

### 高度なSASTのPHPサポート {#php-support-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md#supported-languages) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14273)

{{< /details >}}

GitLab Advanced SASTにPHPサポートを追加しました。
この新しいクロスファイル、クロスファンクションスキャンサポートを使用するには、[Advanced SASTを有効化](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast)してください。
すでにAdvanced SASTを有効化している場合、PHPサポートは自動的に有効になります。

Advanced SASTが各言語で検出する脆弱性の種類については、[Advanced SASTカバレッジページ](../../user/application_security/sast/advanced_sast_coverage.md)を参照してください。

### 依存関係リストでコンポーネントバージョンによるフィルタリング {#filter-by-component-version-in-the-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md#filter-dependency-list) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16431)

{{< /details >}}

依存関係リストでコンポーネントのバージョン番号によるフィルタリングがサポートされるようになりました。複数のバージョンを選択できます（例: `version=1.1,1.2,1.4`）が、範囲指定はサポートされていません。この機能はグループとプロジェクトの両方で利用できます。

### パイプライン実行ポリシーの変数優先度制御 {#variable-precedence-controls-in-pipeline-execution-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/pipeline_execution_policies.md#variables_override-type) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16430)

{{< /details >}}

セキュリティチームは、セキュリティ保証と開発者エクスペリエンスの間で微妙なバランスを取ることが多くあります。セキュリティスキャンが適切に実施されることを確保することは重要ですが、セキュリティアナライザーが適切に実行するために開発チームからの特定の入力を必要とする場合があります。変数優先度制御により、セキュリティチームは新しい`variables_override`設定オプションを通じて、パイプライン実行ポリシーでの変数の処理方法をきめ細かく制御できるようになりました。

この新しい設定を使用することで、以下が可能になります:

- プロジェクト固有のコンテナイメージパス（`CS_IMAGE`）を許可するコンテナスキャンポリシーを実施する。
- `SAST_DISABLED`などの高リスク変数をブロックしながら、`SAST_EXCLUDED_PATHS`などの低リスク変数を許可する。
- `AWS_CREDENTIALS`などのグローバルCI/CD変数でセキュリティ保護（マスクまたは非表示）されたグローバル共有認証情報を定義しながら、プロジェクトレベルのCI/CD変数を通じて適切な場合にプロジェクト固有のオーバーライドを許可する。

この強力な機能は2つのアプローチをサポートします:

- **デフォルトで変数をロック**（`allow: false`）: 例外としてリストした特定の変数を除き、すべての変数をロックします。
- **デフォルトで変数を許可**（`allow: true`）: 変数のカスタマイズを許可しますが、例外としてリストすることで重要なリスクを制限します。

パイプライン実行ポリシーがCI/CDジョブのソースである場合の追跡可能性とトラブルシューティングを改善するために、ポリシーによって実行されたジョブを開発者とセキュリティチームが識別するのに役立つジョブログも導入しています。ジョブログは変数オーバーライドの影響に関する詳細を提供し、変数がポリシーによってオーバーライドまたはロックされているかどうかを把握するのに役立ちます。

**実際の影響**

この機能強化は、セキュリティ要件と開発者の柔軟性のギャップを埋めます:

- セキュリティチームは、プロジェクト固有のカスタマイズを許可しながら標準化されたスキャンを実施できます。
- 開発者は、ポリシーの例外を要求することなくプロジェクト固有の変数の制御を維持できます。
- 組織は、開発ワークフローを中断することなく一貫したセキュリティポリシーを実装できます。

この重要な変数制御の課題を解決することで、GitLabは組織がチームがソフトウェアを効率的に提供するために必要な柔軟性を犠牲にすることなく、堅牢なセキュリティポリシーを実装できるようにします。

### ボットユーザーと人間ユーザーのフィルタリング {#filter-for-bot-and-human-users}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/moderate_users.md#view-users-by-type) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/541186)

{{< /details >}}

確立されたGitLabインスタンスには、多数の人間ユーザーとボットユーザーが存在することがよくあります。管理者エリアのユーザーリストをユーザータイプでフィルタリングできるようになりました。ユーザーのフィルタリングにより、以下が可能になります:

- 自動化されたアカウントとは別に人間ユーザーを素早く識別して管理する。
- 特定のユーザータイプに対してターゲットを絞った管理アクションを実行する。
- ユーザー監査と管理ワークフローを簡素化する。

### ユーザープロフィールの[ORCID](https://orcid.org/)識別子 {#orcid-identifier-in-user-profile}

<!-- categories: User Profile -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/profile/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/23543)

{{< /details >}}

GitLabがユーザープロフィールでORCID識別子をサポートするようになり、研究者や学術コミュニティにとってGitLabがより利用しやすく価値あるものになりました。[ORCID](https://orcid.org/)（Open Researcher and Contributor ID）は、研究者に他の研究者と区別するための永続的なデジタル識別子を提供し、研究者とその専門的活動の間の自動リンクをサポートして、研究成果が適切に認識されることを確保します。

この機能は、[Daniel Le Berre](https://www.ouvrirlascience.fr/appointment-of-daniel-le-berre-as-the-national-coordinator-for-higher-education-and-research-software-forges-in-france/)の指導のもと、Artois大学の修士課程学生であるThomas LabaletteとErwan Hivinによるコミュニティコントリビューションとして開発され、学術コミュニティからの長年の要望に応えるものです。

### サービスアカウントのパイプライン通知を購読 {#subscribe-to-service-account-pipeline-notifications}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/profile/notifications.md#notifications-about-failed-pipeline-that-doesnt-exist) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/515629)

{{< /details >}}

サービスアカウントによってトリガーされたパイプラインイベントの通知を購読できるようになりました。パイプラインが成功、失敗、または修正された際に通知が送信されます。以前は、これらの通知はサービスアカウントに有効なカスタムメールアドレスがある場合にのみ、そのメールアドレスに送信されていました。

[Densett](https://gitlab.com/[Densett](https://gitlab.com/Densett))、[Gilles Dehaudt](https://gitlab.com/tonton1728)、[Lenain](https://gitlab.com/lenaing)、[Geoffrey McQuat](https://gitlab.com/gmcquat)、[Raphaël Bihoré](https://gitlab.com/rbihore)のコントリビューションに感謝します！

### Duo脆弱性解決のSASTカバレッジ拡大 {#increased-sast-coverage-for-duo-vulnerability-resolution}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/_index.md#supported-vulnerabilities-for-vulnerability-resolution) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/534307)

{{< /details >}}

以前は、以下のCommon Weakness Enumeration（CWE）識別子を持つ検出された脆弱性を手動で解決する必要がありました:

- CWE-78（コマンドインジェクション）
- CWE-89（SQLインジェクション）

Duo脆弱性解決がこれらの脆弱性を自動的に修正できるようになりました。

### GitLab Runner 18.1 {#gitlab-runner-181}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.1もリリースします！GitLab Runnerは、CI/CDジョブを実行してGitLabインスタンスに結果を送信する高スケーラブルなビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### バグ修正 {#bug-fixes}

- [GitLab 17.10または17.11にアップグレードすると、RunnerがジョブをリクエストするときにRunnerが`404`レスポンスを受け取る場合があります](https://gitlab.com/gitlab-org/gitlab/-/issues/543351)。

すべての変更のリストはGitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-1-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-1-stable/CHANGELOG.md).md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.1)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.1)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.1)
- [非推奨と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
