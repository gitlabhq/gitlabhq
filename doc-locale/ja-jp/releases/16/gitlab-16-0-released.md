---
stage: Release Notes
group: Monthly Release
date: 2023-05-22
title: "GitLab 16.0リリースノート"
description: "GitLab 16.0のValue Streams Dashboardが一般公開されました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023年5月22日にGitLab 16.0が以下の機能とともにリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Jimmy Berry {#this-months-notable-contributor-jimmy-berry}

Jimmyは[マージリクエストのセキュリティウィジェットを改善](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117594)し、マージリクエストの完了したパイプライン上でブランチを比較するために使用されるマージベースを修正しました。以前は、マージリクエストのセキュリティウィジェットは、リポジトリのmainブランチで完了したパイプラインの最新のセキュリティスキャンを比較していました。マージリクエストのセキュリティウィジェットにおける脆弱性の発見を正確にするために、ロジックを調整し、フィーチャーブランチがmainから分岐した時点でのフィーチャーブランチとmainブランチを比較する必要がありました。この変更がなければ、ユーザーは誤解を招く結果を目にする可能性があります。これはすでに我々のロードマップ上の[イシュー](https://gitlab.com/groups/gitlab-org/-/epics/10092)でしたが、Jimmyは彼らだけでなく、すべてのGitLabユーザーのためにこの改善にコントリビュートし、加速させました。

Jimmyは[次のように述べました](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/34100#note_1395183419):

> オープンソースプロジェクトに多数コントリビュートしてきましたが、これほど役立つレビュープロセスを経験したことはありません。

Jimmy、脆弱性の発見に関するロジックのイテレーションを行うのを助け、GitLabのセキュリティ機能を改善してくれてありがとうございます！

## 主要な機能 {#primary-features}

### Value Streams Dashboardが一般公開されました {#value-streams-dashboard-is-now-generally-available}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/value_streams_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/403304)

{{< /details >}}

この[新しいダッシュボード](https://youtu.be/EA9Sbks27g4)は、意思決定者が傾向とパターンを特定し、ソフトウエアデリバリーを最適化するのに役立つメトリクスに対する戦略的なインサイトを提供します。GitLab Value Streams Dashboardの最初のイテレーションは、バリューストリームライフサイクル（[バリューストリーム分析](../../user/group/value_stream_analytics/_index.md) 、[DORA4](../../user/analytics/dora_metrics.md) ）、および[脆弱性](../../user/application_security/vulnerability_report/_index.md)のメトリクスをベンチマークすることで、チームがソフトウエアデリバリーワークフローを継続的に改善できるようにすることに焦点を当てています。

組織は[Value Streams Dashboard](../../user/analytics/value_streams_dashboard.md)を使用して、これらのメトリクスを一定期間追跡するおよび比較し、下降傾向を早期に特定し、セキュリティエクスポージャーを理解し、個々のGitLabプロジェクトやメトリクスを掘り下げて改善のためのアクションを取ることができます。

この単一アプリケーションとして構築された統合データストアによる包括的なビューは、役員から個人のコントリビューターまで、すべての関係者がサードパーティツールを購入または維持することなく、ソフトウェア開発ライフサイクルへの表示レベルを持つことを可能にします。

### Linux上のGitLab SaaS Runnerのアップサイジング {#upsizing-gitlab-saas-runners-on-linux}

<!-- categories: GitLab Runner SaaS -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/linux.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/388162)

{{< /details >}}

お客様のご要望にお応えしました。CI/CDビルド速度で最高クラスとなるための取り組みとして、Linux上のすべてのGitLab SaaS Runnerの仮想CPUとRAMを2倍にします。その際、[コスト要素](../../ci/pipelines/compute_minutes.md)は増加しません。

パイプラインの実行速度が向上し、生産性が向上することを楽しみにしています。

### Linux上のGPU対応SaaS Runner {#gpu-enabled-saas-runners-on-linux}

<!-- categories: GitLab Runner SaaS -->

{{< details >}}

- プラン: Silver, Gold
- リンク: [ドキュメント](../../ci/runners/hosted_runners/linux.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/358026)

{{< /details >}}

GitLab Runner内でより強力なコンピューティングハードウェアを提供することで、DevSecOpsのベストプラクティスをデータサイエンスにもたらすことを目指しています。以前は、データサイエンティストはコンピューティング負荷の高いワークロードを抱えていたため、GitLabでジョブが迅速に実行されないことがありました。

現在、Linux上のGPU対応SaaS Runnerにより、これらのワークロードはGitLab.comを使用してシームレスにサポートできます。

さあ、もう待つ必要はありません。本日、新しいRunnerをお試しいただき、この[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/403008)でご意見をお聞かせください。皆様のフィードバックをお待ちしております！

### macOS上のApple silicon (M1) GitLab SaaS Runner - ベータ {#apple-silicon-m1-gitlab-saas-runners-on-macos---beta}

<!-- categories: GitLab Hosted Runnersit -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/macos.md#example-gitlab-ciyml-file) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/342848)

{{< /details >}}

モバイルDevOpsチームは、Appleエコシステム向けアプリケーションをシームレスに作成、テスト、デプロイするために、Apple silicon (M1) [macOS上のGitLab SaaS Runner](../../ci/runners/hosted_runners/macos.md)でCI/CDワークフロー全体を実行できるようになりました。

ホストされているx86-64 macOS Runnerの最大**three times**のパフォーマンスで、GitLab CI/CDと統合された安全なオンデマンドGitLab Runnerビルド環境でmacOSを必要とするアプリケーションをビルドするおよびデプロイする際の開発チームの開発速度を向上させます。

### コメントテンプレート {#comment-templates}

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/comment_templates.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/7565)

{{< /details >}}

イシュー、エピック、またはマージリクエストでコメントしていると、同じコメントを繰り返し書く必要があるかもしれません。常にバグレポートについてより詳しい情報を求める必要があるかもしれません。クイックアクションを介して、トリアージプロセスの一部としてラベルを適用しているかもしれません。あるいは、すべてのコードレビューを面白いgifや適切な絵文字で終わらせるのが好きなだけかもしれません。🎉

コメントテンプレートを使用すると、GitLab内のコメントボックスに適用できる保存済みの応答を作成し、ワークフローを高速化できます。コメントテンプレートを作成するには、**ユーザー設定 > コメントテンプレート**に移動して、テンプレートを記入します。保存後、任意のテキストエリアで**コメントテンプレートの挿入**アイコンを選択すると、保存された応答が適用されます。

これは、返信を標準化し、時間を節約するための素晴らしい方法です！

### GitLab UIからフォークを更新 {#update-your-fork-from-the-gitlab-ui}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/forking_workflow.md#update-your-fork) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/330243)

{{< /details >}}

フォークの管理がさらに簡単になりました。フォークが遅れている場合は、GitLab UIで**フォークを更新**を選択して、アップストリームの変更に追いつかせます。フォークが進んでいる場合は、**マージリクエストを作成**を選択して、変更をアップストリームプロジェクトにコントリビュートします。以前はどちらの操作もコマンドラインを使用する必要がありました。

プロジェクトのメインページおよび**リポジトリ > ファイル**で、フォークがどれくらいのコミット数先行（または遅延）しているかを確認します。マージコンフリクトが存在する場合、UIはコマンドラインからGitを使用してそれらを解決する方法についてのガイダンスを提供します。

### 特定のブランチのみをミラー {#mirror-specific-branches-only}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/mirror/_index.md#mirror-specific-branches) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/1893)

{{< /details >}}

多くのブランチを持つ多忙なリポジトリをミラーする必要があるものの、そのうちのいくつかしか必要ないという状況ですか？必要なブランチのみに一致する正規表現を作成することで、ミラーするブランチの数を制限します。

以前は、ミラーにはリポジトリ全体、またはすべての保護ブランチをミラーする必要がありました。この新しい柔軟性により、ミラーがプッシュまたはプルするデータ量を減らし、機密性の高いブランチを公開ミラーから除外できます。

### 新しいWeb IDEエクスペリエンスが一般公開されました {#new-web-ide-experience-now-generally-available}

<!-- categories: Web IDE -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/web_ide/_index.md)

{{< /details >}}

導入以来、Web IDEの使いやすさ、パフォーマンス、安定性についてイテレーションを行うことで、リモート開発ワークスペースやコード提案などの機能を強力な基盤の上に構築できるようになりました。

我々はWeb IDEベータに対して圧倒的に肯定的なフィードバックを受け取り、GitLab 16.0から、これをGitLab全体でデフォルトのマルチファイルコードエディタにします。

### 公開GitLabプロジェクトで利用可能なベータ版ワークスペース {#workspaces-available-in-beta-for-public-projects}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/workspace/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10122)

{{< /details >}}

ローカル開発環境のトラブルシューティングや、理解しがたいパッケージインストールエラーの解釈に何時間も、あるいは何日も費やすのをやめましょう。これで、コード内で一貫性があり、安定した安全な開発環境を定義し、オンデマンドで作成できるようになります。これらすべてがワークスペース内で可能です。

ワークスペースは、クラウド上の個人用の一時的な開発環境として機能します。ローカル開発環境の必要性を排除することで、コードにより集中し、依存関係に煩わされることが少なくなります。新しいGitLabプロジェクトへのオンボーディングプロセスを加速させ、数日ではなく数分で稼働させることができます。

Kubernetes向けGitLabエージェントが設定され、選択したセルフホストクラスターまたはクラウドプラットフォームに[依存関係がインストール](../../user/workspace/_index.md)されたら、`.devfile.yaml`ファイルで開発環境を定義し、公開GitLabプロジェクトに保存できます。その後、あなたとエージェントにアクセスできる他のデベロッパーは、`.devfile.yaml`ファイルに基づいてワークスペースを作成し、組み込みのWeb IDEで直接編集できます。コンテナへの完全なターミナルアクセスが可能になり、より効率性的に作業できます。完了したとき、または何か問題が発生した場合は、ワークスペースをシャットダウンし、次の開発タスクのために新しいワークスペースを開始できます。

この短いビデオでは、現在のベータ版におけるワークスペースのライフサイクルを説明します。ワークスペースの詳細については[ドキュメント](../../user/workspace/_index.md)を参照し、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/410031)でご意見をお聞かせください。

### SecureFlagによるセキュリティトレーニング {#security-training-with-secureflag}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/_index.md#enable-security-training-for-vulnerabilities) | [関連イシュー](https://gitlab.com/gitlab-com/alliances/alliances/-/issues/297)

{{< /details >}}

セキュリティがシフトレフトするにつれて、ガイダンスなしでセキュリティの発見を修復することは困難になる可能性があります。デベロッパーは、脆弱性を解決し、機能のビルドするを継続できるように、実用的なアドバイスを必要としています。検出された特定の脆弱性に関連するコンテキストトレーニングは、GitLab 14.9でリリースされました。

このリリースでは、脆弱性のCWEに基づいたSecureFlagとのインテグレーションを追加します。SecureFlagのトレーニングソリューションは、ライブ環境で脆弱性を修復する演習を含んでおり、実際の環境に転用できる点でユニークです。

### トークンローテーションAPI {#token-rotation-api}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../security/tokens/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/403042)

{{< /details >}}

以前は、トークンをローテーションするには、トークンのオーナーが手動で新しいトークンを作成し、既存のトークンを置き換える必要がありました。

現在、トークンのオーナーは`:rotate` APIエンドポイントを使用して、パーソナルアクセストークン、グループ、およびプロジェクトアクセストークンをプログラムでローテーションできます。

### AIを活用したワークフロー機能 {#ai-powered-workflow-features}

<!-- categories: Code Suggestions, Workflow Automation, Intelligent Code Security -->

{{< details >}}

- プラン: Gold
- リンク: [ドキュメント](../../development/ai_features/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/10524)

{{< /details >}}

GitLabはAIを活用したDevSecOpsプラットフォームへと進化しています。先月、さまざまなGitLab機能における効率性と生産性を向上させるための10の新しい実験を導入しました。これらはすべてAIを活用しています。

これらのAIを活用したワークフローは、ソフトウェア開発ライフサイクルのあらゆる段階で効率性を高め、サイクルタイムを短縮します。

[AIを活用したワークフロー](https://about.gitlab.com/solutions/ai/)の詳細をご覧ください。

### コード提案の改善 {#code-suggestions-improvements}

<!-- categories: Code Suggestions -->

{{< details >}}

- プラン: Gold、Silver、Free
- リンク: [ドキュメント](../../user/project/repository/code_suggestions/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/9814)

{{< /details >}}

コード提案は、この機能がベータ版である間、すべてのユーザーにFreeでGitLab.comで利用できるようになりました。チームは、開発中にコードを提案する生成AIの助けを借りて、効率性を高めることができます。

当初の6つの言語から、現在は13の言語にまでサポートを拡張しました: C/C++、C#、Go、Java、JavaScript、Python、PHP、Ruby、Rust、Scala、Kotlin、およびTypeScript。

提案の品質を向上させるため、コード提案の基盤となるAIモデルに毎週改善を加えています。AIは非決定論的であるため、週ごとに同じ提案が得られない可能性があることをご留意ください。

これらの[改善点と今後の展望](https://about.gitlab.com/blog/code-suggestions-for-all-during-beta/)について詳しく読む。

### エラー追跡が一般公開されました {#error-tracking-is-now-generally-available}

<!-- categories: Error Tracking -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../operations/error_tracking.md)

{{< /details >}}

GitLabのエラー追跡は、デベロッパーがアプリケーションによって生成されたエラーを発見し、表示できるようにする機能で、GitLab.comで一般公開されました！GitLabのエラー追跡は、コードが開発、ビルドする、デプロイ、リリースされるのと同じインターフェースでエラー情報を直接表示することで、効率性と認識を高めるのに役立ちます。

このリリースでは、[GitLab統合エラー追跡](../../operations/error_tracking.md)と[Sentryベース](../../operations/error_tracking.md)の両方のバックエンドをサポートしています。

### プロジェクトレベルのバリューストリーム分析向けのカスタムバリューストリーム {#custom-value-streams-for-project-level-value-stream-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/value_stream_analytics/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/382496)

{{< /details >}}

完全なワークストリームへの表示レベルを向上させるため、プロジェクトレベルのバリューストリーム分析 (VSA) に[概要パイプラインステージ](../../user/group/value_stream_analytics/_index.md)と[カスタムバリューストリームを作成](../../user/group/value_stream_analytics/_index.md)するオプションを追加しています。

これまでは、これらの機能はグループレベルのVSAでのみ利用可能でした。

## 規模とデプロイ {#scale-and-deployments}

### プロジェクトリストAPIの未認証ユーザーに対するレート制限 {#rate-limit-for-unauthenticated-users-of-the-projects-list-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/settings/rate_limit_on_projects_api.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/388435)

{{< /details >}}

プロジェクトリストAPIの未認証ユーザーは、今後レート制限の対象となります。

GitLab.comでは、制限は一意のIPアドレスごとに10分あたり400リクエストに設定されています。

Self-Managed GitLabのインスタンスのユーザーは、デフォルトで同じレート制限を受けますが、管理者は必要に応じてレート制限を変更できます。プロジェクトリストAPIに対して10分あたり400を超えるリクエストを行う必要があるユーザーは、[GitLabアカウントに登録](https://about.gitlab.com/pricing/)することをお勧めします。

### Self-Managed GitLabは2つのデータベース接続を使用します {#self-managed-gitlab-uses-two-database-connections}

<!-- categories: Cell -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/settings/database.html#configuring-multiple-database-connections) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9627)

{{< /details >}}

16.0から、GitLabのセルフマネージドインストールには、1つではなくデフォルトで2つのデータベース接続が備わります。この変更により、GitLabのセルフマネージドバージョンはGitLab.comと同様に動作し、GitLabのセルフマネージドバージョンでCI機能に[個別のデータベース](https://gitlab.com/groups/gitlab-org/-/epics/7509)を有効にするための一歩となります。

この変更は、Omnibus GitLab、GitLabチャート、GitLab Operator、GitLab Dockerイメージ、およびソースからのインストール方法に適用されます。

### フォロワーを無効にするオプション {#option-to-disable-followers}

<!-- categories: System Access, User Profile -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/_index.md#disable-following-and-being-followed-by-other-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/325558)

{{< /details >}}

ユーザープロフィールに不要なフォロワーが付くのを防ぎたいというユーザーからフィードバックをいただいています。皆様の懸念に耳を傾け、ユーザープロフィール設定内の設定でフォローを無効にできるようになりました。

この機能を無効にすると、誰もあなたをフォローできなくなり、あなたも誰もフォローできなくなります。既存のフォローおよびフォロワーの関係はすべて削除され、カウントはゼロに設定されます。

### グループおよびGitLabプロジェクトの遅延削除がデフォルトに設定されました {#delayed-group-and-project-deletion-set-as-default}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/gitlab_com/_index.md#delayed-project-deletion) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/389557)

{{< /details >}}

GitLabプロジェクトとグループの偶発的な削除を防ぐため、GitLab 16.0以降、遅延削除機能はすべてのUltimateおよびPremiumプランのお客様に対してデフォルトで有効になります。

セルフマネージドユーザーは引き続き1日から90日の間で削除遅延期間を定義するオプションがありますが、SaaSユーザーは調整不可能なデフォルトの保持期間が7日間です。

UltimateおよびPremiumグループのユーザーは、グループまたはプロジェクトの設定から2段階の削除プロセスを経て、グループまたはGitLabプロジェクトを即座に削除できます。

この変更は、より安全な削除プロセスに貢献し、偶発的な削除の防止に役立つと信じています。ぜひ[\#396996](https://gitlab.com/gitlab-org/gitlab/-/issues/396996)イシューでフィードバックをお寄せください。

### GitLabチャートの改善 {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/charts/)

{{< /details >}}

- GitLab 16.0への更新は、cert-managerをバージョン1.11.xにアップデートします。このcert-managerアップデートには、アップグレード前に[必ずお読みいただく必要がある破壊的な変更](https://cert-manager.io/docs/release-notes/release-notes-1.10/#breaking-changes-you-must-read-this-before-you-upgrade)が含まれています。これらの変更には、GitLabのメジャーリリース中に行うのが最適なコンテナ名の変更が含まれています。更新された機能の詳細については、[cert-manager 1.11のリリースノート](https://cert-manager.io/docs/release-notes/release-notes-1.11)を参照してください。
- PostgreSQL 12はサポートされなくなりました。最小要件バージョンはPostgreSQL 13であり、PostgreSQL 14のサポートが追加されました。GitLabの新しいチャートインストールにはデフォルトでPostgreSQL 14が含まれており、アップグレードは[バンドルされたPostgreSQLバージョンのアップグレード](https://docs.gitlab.com/charts/installation/database_upgrade.html)の手順に従う必要があります。
- GitLab 16.0への更新には、Redisサブチャートをバージョン16.13.2（Redis 6.2.7を含む）に更新する内容が含まれています。
- バンドルされたGrafanaチャートを削除しました。バンドルされたGrafanaを使用している場合、[Grafana Labsの新しいチャートバージョン](https://artifacthub.io/packages/helm/grafana/grafana)または信頼できるプロバイダーからのGrafana Operatorに切り替える必要があります。
- GitLab 16.0には、webserviceとSidekiqの[レジストリサービスの詳細](https://docs.gitlab.com/charts/charts/globals.html#configure-registry-settings)が`global.registry.*`設定に含まれており、両方に値が存在するため簡素化されています。オーバーライドを使用することで、以前の動作を維持できます。
- [サポートされる最小Helmバージョン](https://docs.gitlab.com/charts/installation/tools.html#helm)は3.5.2です。
- GitLab RunnerのデフォルトバージョンはUbuntu 22.04になりました。

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- PostgreSQL 12はサポートされなくなりました。最小要件バージョンはPostgreSQL 13です。パッケージ版PostgreSQL 12のユーザーは、GitLab 16.0をインストールする前に[データベースのアップグレード](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)を実行する必要があります。
- Omnibus GitLab Dockerイメージの新しいベースOSはUbuntu 22.04です。
- GitLab 16.0では、Consul 1.9で非推奨になったConsulの古いテレメトリーエンドポイントが無効になります。これにより、[Consulを新しいバージョンに更新](https://developer.hashicorp.com/consul/docs/v1.12.x/agent/config/config-files#telemetry-parameters)できます。
- GitLab 16.0には、Red Hat Enterprise Linux (RHEL) 9および互換性のあるディストリビューション向けのパッケージが含まれています。
- GitLab 16.0には[Mattermost 7.10](https://mattermost.com/)と[セキュリティアップデート](https://mattermost.com/security-updates/)が含まれています。以前のバージョンからのアップグレードをお勧めします。

### Freeユーザーが利用可能な追加登録機能 {#additional-registration-features-available-to-free-users}

<!-- categories: Product Analytics -->

{{< details >}}

- プラン: Free
- リンク: [ドキュメント](../../administration/settings/usage_statistics.md#registration-features-program) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10508)

{{< /details >}}

GitLab Freeのお客様で、GitLab Enterprise Editionを実行しているSelf-Managedインスタンスをお持ちの場合、[登録機能](../../administration/settings/usage_statistics.md#registration-features-program)プログラムの下でさらに5つの有料機能にアクセスできるようになりました:

- [パスワードの複雑性ポリシー](../../administration/settings/sign_up_restrictions.md)
- [説明変更履歴](../../user/discussions/_index.md#view-description-change-history)
- [イシューボードの設定](../../user/project/issue_board.md#configurable-issue-boards)
- [メンテナンスモード](../../administration/maintenance_mode/_index.md)
- [カバレッジガイドファズテスト](../../user/application_security/coverage_fuzzing/_index.md)

これらの機能にアクセスするには、GitLabに登録し、[Service Ping](../../administration/settings/usage_statistics.md#enable-registration-features)を通じてアクティビティデータを送信してください。

### コラボレーターを追加アイテムとしてインポート {#import-collaborators-as-an-additional-item-to-import}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/import/github.md#select-additional-items-to-import) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/398154)

{{< /details >}}

GitLab 15.10では、GitHub GitLabプロジェクトのインポート中に、GitHubリポジトリのコラボレーターをGitLabプロジェクトのメンバーとしてマッピングを開始しました。これにより混乱が生じ、一部のGitHubコラボレーターが予期せず追加されてシートを消費したという[フィードバック](https://gitlab.com/gitlab-org/gitlab/-/issues/398154)を受けました。

GitLab 16.0では、我々はイテレーションを行うし、GitHubリポジトリのコラボレーターを[追加のインポートアイテム](../../user/project/import/github.md#select-additional-items-to-import)のリストに追加しました。これにより、ユーザーはこれらのユーザーをインポートしないオプションと、それらをインポートすることの潜在的な影響を理解するオプションが得られます。

このオプションはデフォルトで選択されています。選択したままにすると、新しいユーザーがグループまたはネームスペースのシートを使用し、[プロジェクトオーナーと同じくらい高い](../../user/project/import/github.md#collaborators-members)権限が付与される可能性があります。直接のコラボレーターのみがインポートされます。外部のコラボレーターはインポートされません。

### GitHubリポジトリをインポートするためにフィルタリング {#filter-github-repositories-to-import}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/import/github.md#filter-repositories-list) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/385113)

{{< /details >}}

もしGitHubで多くのリポジトリを所有または共同作業している場合、現在のフィルタリングオプションを使用すると、GitLabにインポートしたいリポジトリを見つけるのに苦労するかもしれません。

適切なリポジトリをより簡単に見つけるために、追加のフィルターを追加しました。3つのタブを使用して、インポートできるリポジトリのサブセットをリスト表示できるようになりました:

- 所有するリポジトリをリスト表示する**オーナー**。
- 共同作業しているリポジトリをリスト表示する**Collaborator**。
- GitHub組織に属するリポジトリをリスト表示する**GitHub organization**。

**組織**タブで、検索をさらに絞り込み、特定の組織を選択して、その組織に属するリポジトリのみをリスト表示できます。

### 他のグループまたはGitLabプロジェクトのオーナーによって完了したTo Doアイテムを完了済みとしてマーク {#mark-to-do-items-completed-by-other-group-or-project-owners-done}

<!-- categories: Groups & Projects, User Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/todos.md#actions-that-mark-a-to-do-item-as-done) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/374726)

{{< /details >}}

ユーザーがグループまたはGitLabプロジェクトのアクセスリクエストを提出すると、そのリクエストはグループまたはGitLabプロジェクトのオーナーのTo Doリストに表示されます。複数のオーナーを持つグループやGitLabプロジェクトの場合、そのリクエストは各オーナーのTo Doリストに表示されます。

この新しい機能により、他のオーナーによってすでに完了されたTo Doアイテムは、他のオーナーのTo Doリストで完了済みとしてマークされます。

### 新しいナビゲーションエクスペリエンスにオプトイン {#opt-in-to-a-new-navigation-experience}

<!-- categories: Navigation & Settings -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../tutorials/left_sidebar/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9044)

{{< /details >}}

GitLab 16.0には、まったく新しいナビゲーションエクスペリエンスが搭載されています！開始するには、UIの右上にあるアバターに移動し、**New navigation**切替をオンにします。左サイドバーは、過去1年間に受けたユーザーからのフィードバックに基づいて、新しく改善されたデザインに変更されます。

[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/409005)で、あなたの体験をお聞かせください。このフィードバックに基づいて、新しいナビゲーションをユーザーベース全体で段階的に有効にし、最終的には古いナビゲーションを削除します。

### ユーザーのセッション期間を制限 {#limit-session-length-for-users}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/profile/_index.md#session-duration) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/30819)

{{< /details >}}

管理者は、サインイン時にユーザーの「ログイン状態を記憶する」オプションを削除できるため、セッションが延長されず、ユーザーは再認証を強制されます。セッションの期間を制限すると、インスタンスのセキュリティが向上する可能性があります。

### Jiraパーソナルアクセストークンで認証する {#authenticate-with-jira-personal-access-tokens}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../integration/jira/configure.md#configure-the-integration) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/8222)

{{< /details >}}

以前は、[Jiraイシューのインテグレーション](../../integration/jira/configure.md)をJiraのユーザー名とパスワードでのみ認証することができました。

現在、[Jiraパーソナルアクセストークン](https://confluence.atlassian.com/enterprise/using-personal-access-tokens-1026032365.html)を使用して認証することができます。Jira Data CenterまたはJira ServerをJira 8.14以降で使用している場合に限ります。Jiraパーソナルアクセストークンは、ユーザー名とパスワードに代わる、より安全な手段です。

### サービスデスクの自動返信におけるイシューの説明のプレースホルダー {#placeholder-for-issue-description-in-service-desk-automated-replies}

<!-- categories: Service Desk -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/service_desk/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/223751)

{{< /details >}}

サービスデスクのリクエスタが、自動お礼メールの返信で元のリクエストを確認できることは有用です。

今回のリリースでは、サービスデスクの管理者が元のリクエストをお礼メールに含めることができるように、`%{ISSUE_DESCRIPTION}`プレースホルダーを追加しました。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### リアルタイムのマージリクエスト更新 {#real-time-merge-request-updates}

<!-- categories: Web IDE -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/merge_requests/_index.md)

{{< /details >}}

マージリクエストで作業する場合、承認、パイプライン、または変更をマージする機能に影響を与える可能性のあるその他の情報について、最新の情報が表示されていることを確認することが重要です。これまで、これはマージリクエストの更新を行うか、ポーリングによる更新を待つことを意味していました。

マージリクエスト内のマージボタンウィジェットと承認ウィジェットの両方のエクスペリエンスを改善し、マージリクエストでリアルタイムに更新されるようになりました。これは、変更をより迅速に提供し、最新の情報を確認しながらマージリクエストを進めることができるという信頼性を向上させる素晴らしい改善です。

マージリクエストにおける[リアルタイムの改善](https://gitlab.com/groups/gitlab-org/-/epics/1812)のためのさらなる領域を検討しており、更新にご期待ください。

### 多数の脆弱性を無視する際に理由を指定 {#provide-a-reason-when-dismissing-vulnerabilities-in-bulk}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#change-status-of-vulnerabilities) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/408366)

{{< /details >}}

脆弱性レポートで1つまたは複数の脆弱性を選択すると、それらのステータスを一括で変更できます。

今回のリリースでは、無視するステータスを選択する際に却下理由を選択できるようになり、脆弱性のステータスを変更する際にコメントを追加できるようになりました。

### 一括操作を使用せずにコンプライアンスフレームワークを追加および削除 {#add-and-remove-compliance-frameworks-without-using-bulk-actions}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_projects_report.md#apply-a-compliance-framework-to-projects-in-a-group)

{{< /details >}}

GitLab 15.11では、コンプライアンスフレームワークレポートにコンプライアンスフレームワークの一括[追加](../../user/compliance/compliance_center/compliance_projects_report.md#apply-a-compliance-framework-to-projects-in-a-group)と[削除](../../user/compliance/compliance_center/compliance_projects_report.md#remove-a-compliance-framework-from-projects-in-a-group)機能を追加しました。

GitLab 16.0では、レポートのテーブル行から直接プロジェクトにコンプライアンスフレームワークを追加および削除できるようになりました。

GitLab 16.0より前は、グループの設定でフレームワークを作成および編集する必要がありました。

GitLab 16.0では、コンプライアンスフレームワークレポートで独自のコンプライアンスフレームワークを作成または編集することもできます。これにより、フレームワーク作成ワークフローが簡素化され、フレームワークを管理する際のコンテキスト切り替えの必要性が軽減されます。

### コンプライアンス違反をターゲットブランチ名でフィルタリング {#filter-compliance-violations-by-target-branch-name}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_projects_report.md)

{{< /details >}}

GitLab 16.0より前は、コンプライアンス違反レポートにはすべてのブランチのすべての違反が表示されていました。

新しい**ターゲットブランチを検索**フィールドを使用して違反をフィルタリングできるようになり、最も懸念しているブランチに焦点を当てることができます。

### スキャン結果ポリシーに対するロールベースの承認アクションのサポート {#support-role-based-approval-action-for-scan-result-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/8018)

{{< /details >}}

ロールベースの承認アクションを使用すると、スキャン結果ポリシーを設定して、オーナー、メンテナー、デベロッパーなど、GitLabがサポートするロールからの承認を要求できます。

これにより、個々の承認者または定義されたユーザーグループを要求する以上の柔軟性が得られ、特に大規模な組織全体で、GitLabですでに活用しているロールに基づいてポリシーを適用することが容易になります。

### ブラウザベースのDASTによるアウトオブバンドアプリケーションセキュリティテストの導入 {#introducing-out-of-band-application-security-testing-through-browser-based-dast}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dast/browser/_index.md)

{{< /details >}}

以前、GitLabのDASTアナライザーは、アクティブチェックの実行中にコールバック攻撃をサポートしていませんでした。これは、アウトオブバンドアプリケーションセキュリティテスト（OAST）がDASTスキャンとは別に設定される必要があることを意味していました。

現在、ブラウザベースのDASTアナライザーの設定を[拡張](../../user/application_security/dast/browser/_index.md)することでOASTを実行し、コールバック攻撃を有効にできます。

今回のリリースでは、[BAS.latest.GitLab-ci.yml](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/BAS.latest.gitlab-ci.yml)テンプレートを導入します。Breach and Attack Simulation CI/CDテンプレートには、ブラウザベースのDASTアナライザー用のジョブ設定機能があり、コンテナ間のネットワーキングを有効にして、サービスコンテナに対する拡張DASTスキャンをCI/CDパイプラインに追加します。

私たちは、新しいBreach and Attack Simulation機能を継続的に開発するために反復しています。ブラウザベースのDASTへのコールバック攻撃の追加に関する[フィードバック](https://gitlab.com/gitlab-org/gitlab/-/issues/404809)をお待ちしております。

### CI/CDパイプラインを使用したMaven/Gradleパッケージのインポート {#import-mavengradle-packages-by-using-cicd-pipelines}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/package_registry/_index.md#to-import-packages) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/389338)

{{< /details >}}

MavenまたはGradleのリポジトリをGitLabへ移行することを検討していましたが、移行計画に時間をかけることができませんでしたか？GitLabは、Maven/GradleパッケージインポーターのMVCローンチを発表できることを誇りに思います。

現在、Packagesインポーターツールを使用して、ArtifactoryなどのMaven/Gradle準拠のあらゆるレジストリからパッケージをインポートできます。

このツールを使用するには、GitLabにインポートしたいパッケージの詳細を含む`config.yml`ファイルを作成するだけです。その後、インポーターを`.gitlab-ci.yml`パイプライン設定ファイルに追加すると、残りの処理はインポーターが行います。これはパイプライン内で実行され、すべてのパッケージをGitLabパッケージレジストリにインポートするジョブを持つ子パイプラインを動的に生成します。

### ScalaでMavenレジストリからパッケージをダウンロード {#download-packages-from-the-maven-registry-with-scala}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/maven_repository/_index.md#install-a-package) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/212854)

{{< /details >}}

GitLabパッケージレジストリは、Scalaビルドツール（`sbt`）を使用したMavenパッケージのダウンロードをサポートするようになりました。以前は、レジストリからのMavenパッケージのダウンロードにおいてBasic認証がサポートされていなかったため、Scalaユーザーにはダウンロードする方法がありませんでした。結果として、Scalaユーザーはレジストリの利用をブロックされるか、代替手段としてMaven（`mvn`）またはGradleを使用する必要がありました。

Scalaのサポートを追加することで、よりデータ集約型のプロジェクトでパッケージレジストリを使用できるようになることを願っています。

なお、`sbt`を使用したアーティファクトの公開はまだサポートされていませんが、公開のサポート追加にご興味がある場合は[イシュー408479](https://gitlab.com/gitlab-org/gitlab/-/issues/408479)をご確認ください。

### タスク、目標と主な成果におけるTo-Doアイテムの追加または解決 {#add-or-resolve-to-do-items-on-tasks-objectives-and-key-results}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/todos.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9750)

{{< /details >}}

GitLab [To-Do](../../user/todos.md)が広く採用されている機能であることは承知していますが、タスク、目標と主な成果では利用できませんでした。

今回のリリースでは、作業アイテムレコードからTo-Doアイテムをオン/オフに切り替える機能が導入されます。

### GitLab Pagesのユニークなサブドメイン {#gitlab-pages-unique-subdomains}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/pages/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9347)

{{< /details >}}

以前のバージョンのGitLabでは、同じトップレベルグループにある異なるGitLab Pagesサイトのクッキーは、GitLab PagesのデフォルトURL形式のため、同じトップレベルにある他のプロジェクトでも可視でした。

現在、各GitLab Pagesプロジェクトに一意のサブドメインを割り当てることで、サイトを保護できます。

### タスク、目標と主な成果に絵文字リアクションを追加 {#add-emoji-reactions-on-tasks-objectives-and-key-results}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/emoji_reactions.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9987)

{{< /details >}}

現在、タスク、目標と主な成果に作業アイテムに対する絵文字リアクションを追加して、コントリビュートすることができます。

このリリースより前は、イシュー、マージリクエスト、スニペット、およびエピックにのみリアクションを追加できました。

### クイックアクションから作業アイテムタイプを変更 {#change-work-item-type-from-quick-action}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/quick_actions.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/385227)

{{< /details >}}

この追加のクイックアクションにより、主な成果を目標に変換できるようになりました。

### ラベルにカスタムカラーを選択 {#pick-custom-colors-for-labels}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/labels.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/361846)

{{< /details >}}

これまで、ラベルに指定できる色の数は固定されていました。

今回のリリースでは、ラベル管理にカラーピッカーが導入され、ラベルに任意の範囲の色を選択できるようになりました。

### タスク、目標と主な成果の子レコードの順序を変更 {#reorder-child-records-for-tasks-objectives-and-key-results}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/okrs.md#reorder-objective-and-key-result-children) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9548)

{{< /details >}}

[タスク](../../user/tasks.md)またはOKRのユーザーであれば、ウィジェット内の子レコードの順序を変更できたらと何度も思ったことがあるでしょう！

この作業により、ユーザーは作業アイテムウィジェット内で子レコードの順序を変更できるようになり、相対的な優先度を示したり、次に何が来るかを通知したりできるようになります。

### カスタムバリューストリーム分析の新しいパイプラインステージイベント {#new-stage-events-for-custom-value-stream-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/value_stream_analytics/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/361983)

{{< /details >}}

バリューストリーム分析は、2つの新しいパイプラインステージイベント（イシューの初回割り当てとマージリクエストの初回割り当て）で拡張されました。これらのイベントは、アイテムが最初にユーザーに割り当てられるまでにかかる時間を測定するのに役立ちます。

この機能を実装するために、GitLabはGitLab 16.0で割り当てイベントの履歴の保存を開始しました。これは、GitLab 16.0より前のイシューおよびMRの割り当てイベントが利用できないことを意味します。

### デプロイフリーズがアクティブなときにメッセージを表示 {#display-message-when-deploy-freeze-is-active}

<!-- categories: Environment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/releases/_index.md#prevent-unintentional-releases-by-setting-a-deploy-freeze) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/212460)

{{< /details >}}

現在、デプロイフリーズが有効な場合、GitLabは環境ページにメッセージを表示します。これにより、チームはフリーズが発生する時期と、デプロイが許可されない時期を確実に把握できます。

### SASTアナライザーの更新 {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/analyzers.md) | [関連イシュー](../../user/application_security/_index.md)

{{< /details >}}

GitLab SASTには、GitLab静的な解析チームが積極的に保守、更新、サポートする[多くのセキュリティアナライザー](../../user/application_security/sast/_index.md#supported-languages-and-frameworks)が含まれています。16.0リリースマイルストーン中に、以下の更新を公開しました:

- Semgrepベースのアナライザーには、更新された[GitLab管理のスキャンルール](https://gitlab.com/gitlab-org/security-products/sast-rules)が含まれています。詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md#v423)を参照してください。ルールを次のように更新しました:
  - 2017年のOWASP Top Tenに基づいていることを示すために、OWASPのマッピングを更新しました。[`@artem-fedorov`](https://gitlab.com/artem-fedorov)によるこの[コミュニティコントリビュート](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/merge_requests/196)に感謝します。
  - `PyYAML.load`ルールにおける追加のケースを処理しました。[`@stevep-arm`](https://gitlab.com/stevep-arm)によるこの[コミュニティコントリビュート](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/merge_requests/237)に感謝します。
  - GitLab脆弱性調査チームによる改訂に基づき、Cルールに関する説明とガイダンスを大幅に改善しました。
  - [Scalaコードのスキャン](https://docs.gitlab.com/#faster-easier-scala-scanning-in-sast)のサポートを追加。
- Flawfinderベースのアナライザーは、コメント内の「ignore」ディレクティブを無視するための[`--neverignore`フラグを渡すこと](../../user/application_security/sast/_index.md#security-scanner-configuration)をサポートするようになりました。詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/flawfinder/-/blob/master/CHANGELOG.md#v401)を参照してください。
- KICSベースのアナライザーはKICSバージョン1.7.0に更新されました。詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md#v401)を参照してください。
- MobSFベースのアナライザーは、複数のモジュールとプロジェクトをサポートするようになり、複数のバグレポートを解決します。詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md#v401)を参照してください。

また、[以前発表したとおり](../../update/deprecations.md#secure-analyzers-major-version-update)、GitLab 16.0の一部として各アナライザーのメジャーバージョン番号を増やしました。

[GitLab管理のSASTテンプレート](../../user/application_security/sast/_index.md) （[`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)）を含め、GitLab 16.0以降を実行している場合、これらの更新を自動的に受け取ります。特定のアナライザーのバージョンを維持し、自動更新を防ぐには、[そのバージョンを固定](../../user/application_security/sast/_index.md)できます。

以前の変更については、[先月の更新](https://about.gitlab.com/releases/2023/04/22/gitlab-15-11-released/#static-analysis-analyzer-updates)を参照してください。

### シークレット検出の更新 {#secret-detection-updates}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/application_security/secret_detection/_index.md) | [関連イシュー](../../user/application_security/_index.md)

{{< /details >}}

私たちはGitLabシークレット検出アナライザーの更新を定期的にリリースしています。GitLab 16.0マイルストーン中に、私たちは次のことを行いました:

- 以下のGitLab管理の検出ルールを[追加](../../user/application_security/secret_detection/_index.md)しました:
  - Meta、Oculus、InstagramのAPI用アクセストークン。
  - Segment Public API用トークン。
- Gitleaksのスキャンエンジンをバージョン8.16.3に更新しました。
- リポジトリに単一のコミットしか存在しない場合にスキャンが妨げられる[バグを修正](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/merge_requests/212)しました。
- アナライザーのメジャーバージョンを`5`に増やしました（[以前発表したとおり](../../update/deprecations.md#secure-analyzers-major-version-update)）。

詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/CHANGELOG.md#v501)を参照してください。

[GitLab管理のシークレット検出テンプレート](../../user/application_security/secret_detection/_index.md) （[`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml)）を使用し、GitLab 16.0以降を実行している場合、これらの更新を自動的に受け取ります。特定のアナライザーのバージョンを維持し、自動更新を防ぐには、[そのバージョンを固定](../../user/application_security/secret_detection/_index.md)できます。

以前の変更については、[先月の更新](https://about.gitlab.com/releases/2023/04/22/gitlab-15-11-released/#static-analysis-analyzer-updates)を参照してください。

### ブラウザベースのDASTのパフォーマンス改善 {#browser-based-dast-performance-improvements}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dast/browser/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9945)

{{< /details >}}

ブラウザベースのDASTアナライザーがスキャンを実行する方法を最適化しました。これらの改善により、ブラウザベースのアナライザーでDASTスキャンを実行するのにかかる時間が大幅に短縮されました。以下の改善が行われました:

- スキャン中にどこに時間が費やされているかを判断するのに役立つログサマリー統計を追加しました。これは、環境変数`DAST_BROWSER_LOG="stat:debug"`を含めることで有効にできます。
- パッシブチェックを並行して実行することで最適化しました。
- HTTPレスポンスボディの内容と一致させる際に使用される正規表現をキャッシュすることで、パッシブチェックを最適化しました。
- DASTがページの読み込みが完了したかどうかを判断する方法を最適化しました。現在、除外されたドキュメントタイプやスコープ外のURLは待機しません。
- ページ読み込み後にDOMが迅速に安定するページの待機時間を短縮しました。

これらの改善により、スキャンされるアプリケーションの複雑さとサイズに応じて、ブラウザベースのDASTスキャン時間が50%～80%削減されました。この割合の減少はすべてのスキャンで見られるわけではありませんが、ブラウザベースのDASTスキャンは完了するまでに大幅に短い時間で済むはずです。

### SASTにおける、より速く簡単なScalaスキャン {#faster-easier-scala-scanning-in-sast}

<!-- categories: SAST -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/362958)

{{< /details >}}

GitLab静的アプリケーションセキュリティテスト（SAST）は、Scalaコード向けのSemgrepベースのスキャンを提供するようになりました。この作業は、[GitLab 14.10](https://about.gitlab.com/releases/2022/04/22/gitlab-14-10-released/#faster-easier-java-scanning-in-sast)でのSemgrepベースのJavaスキャンの以前の導入に基づいています。[Semgrepベースのスキャンに移行](../../user/application_security/sast/analyzers.md#transition-to-semgrep-based-scanning)した他の言語と同様に、ScalaスキャンカバレッジはGitLab管理の検出ルールを使用して、さまざまなセキュリティイシューを検出します。

新しいSemgrepベースのスキャンは、SpotBugsベースの既存のアナライザーよりも大幅に高速に実行されます。また、スキャン前にコードをコンパイルする必要がないため、使い方も簡単です。

GitLabの静的な解析および脆弱性調査チームは協力してルールをSemgrep形式に翻訳し、既存のほとんどのルールを保持しました。また、ルールの変換時に、それらを更新、洗練、テストしました。

[GitLab管理のSASTテンプレート](../../user/application_security/sast/_index.md) （[`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)）を使用している場合、Scalaコードが見つかるたびにSemgrepベースとSpotBugsベースの両方のアナライザーが実行されます。GitLab Ultimateでは、セキュリティダッシュボードが2つのアナライザーからの結果を組み合わせるため、重複する脆弱性レポートが表示されることはありません。

将来のリリースでは、[GitLab管理のSASTテンプレート](../../user/application_security/sast/_index.md) （[`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)）を変更し、Scalaコードに対してSemgrepベースのアナライザーのみを実行するようにします。SpotBugsベースのアナライザーは、GroovyやKotlinを含む他の言語のコードをスキャンします。Semgrepベースのスキャンのみを使用したい場合は、[SpotBugsを早期に無効化](https://gitlab.com/gitlab-org/gitlab/-/issues/412060)できます。

新しいSemgrepベースのScalaスキャンに関するご質問、フィードバック、またはイシューがありましたら、[イシューを提出](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Bug&add_related_issue=362958&issue[title]=Feedback%20on%20SAST%20Semgrep%20Scala%20support&issue[description]=%2Flabel%20~%22group%3A%3Astatic%20analysis%22)してください。喜んでお手伝いいたします。

### ユーザーとして管理者エリアでインスタンスRunnerを作成 {#create-an-instance-runner-in-the-admin-area-as-a-user}

<!-- categories: Runner Fleet -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner/register/) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/383139/)

{{< /details >}}

この新しいワークフローでは、GitLabインスタンスに新しいRunnerを追加するために、認証されたユーザーがGitLab UIでRunnerを作成し、必須の設定メタデータを含める必要があります。この方法により、Runnerはユーザーに簡単にトレースできるようになり、管理者がビルドイシューのトラブルシューティングを行う際や、セキュリティインシデントに対応する際に役立ちます。

### キャンセルされたときのダウンストリームパイプラインのジョブミラーステータスをトリガー {#trigger-job-mirror-status-of-downstream-pipeline-when-cancelled}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/yaml/_index.md#triggerstrategy) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/220794)

{{< /details >}}

以前は、`strategy: depends`で設定されたトリガージョブは、ダウンストリームパイプラインのジョブステータスをミラーしていました。ダウンストリームパイプラインが`running`ステータスだった場合、トリガージョブも`running`とマークされていました。残念ながら、ダウンストリームジョブが完了せず、`canceled`ステータスだった場合、トリガージョブのステータスは誤って`failed`と失敗と表示されていました。

今回のリリースでは、`strategy: depend`を使用してトリガージョブを更新し、ダウンストリームパイプラインのステータスを正確に反映するようにしました。ダウンストリームパイプラインがキャンセルされた場合、トリガーもキャンセル済みと表示されます。

この変更は、既存のパイプライン、特にトリガージョブのステータスが失敗とマークされることに依存するジョブがある場合に影響を与える可能性があります。この動作変更に対応するために、パイプラインの設定を見直し、必要な調整を行うことをお勧めします。

### CI/CDコンポーネント {#cicd-components}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/components/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9945)

{{< /details >}}

今回のリリースでは、実験的機能としてCI/CDコンポーネントが利用可能になったことをお知らせできることを嬉しく思います。CI/CDコンポーネントは、プロジェクトのCI/CDの設定の一部、またはパイプライン全体を構成するために使用できる再利用可能な単一目的のビルディングブロックです。

[`inputs`](../../ci/yaml/includes.md)キーワードと組み合わせると、CI/CDコンポーネントははるかに柔軟になります。設定するコンポーネントは、ジョブ名、変数、認証情報などに使用できる値を入力することで、正確なニーズに合わせて設定できます。

### Runnerを作成するためのREST APIエンドポイント {#rest-api-endpoint-to-create-a-runner}

<!-- categories: Runner Fleet -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../api/users.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390427)

{{< /details >}}

ユーザーは、新しいREST APIエンドポイント、`POST /user/runners`を使用して、ユーザーに関連付けられたRunnerの作成を自動化できるようになりました。Runnerが作成されると、認証トークンが生成されます。この新しいエンドポイントは、次世代のGitLab Runnerトークンアーキテクチャのワークフローをサポートします。

### CI/CDパイプラインにおけるキャッシュごとのフォールバックキャッシュキー {#per-cache-fallback-cache-keys-in-cicd-pipelines}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/caching/_index.md#per-cache-fallback-keys) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/22213)

{{< /details >}}

キャッシュを使用すると、以前のジョブまたはパイプラインで既にフェッチされた依存関係を再利用することで、パイプラインを高速化できます。しかし、まだキャッシュがない場合、ジョブがゼロから開始し、すべての依存関係をフェッチする必要があるため、キャッシュの利点は失われます。

以前、キャッシュが見つからない場合に使用する単一のフォールバックキャッシュを導入しました。これはグローバルに定義できます。これは、すべてのジョブで類似のキャッシュを使用するプロジェクトに役立ちました。GitLab 16.0では、キャッシュごとのフォールバックキーでこの機能を改善しました。各ジョブのキャッシュに対して最大5つのフォールバックキーを定義でき、ジョブが有用なキャッシュなしで実行されるリスクを大幅に軽減します。さまざまなキャッシュがある場合でも、必要に応じて適切なフォールバックキャッシュを使用できるようになりました。

### ユーザーとしてグループRunnerを作成 {#create-a-group-runner-as-a-user}

<!-- categories: Runner Fleet -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/383143/)

{{< /details >}}

この新しいワークフローでは、GitLabグループに新しいRunnerを追加するために、認証されたユーザーがGitLab UIでRunnerを作成し、必須の設定メタデータを含める必要があります。この方法により、Runnerはユーザーに簡単にトレースできるようになり、管理者がビルドイシューのトラブルシューティングを行う際や、セキュリティインシデントに対応する際に役立ちます。

### 含まれるCI/CD設定ファイルの最大数を設定可能 {#configurable-maximum-number-of-included-cicd-configuration-files}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/settings/continuous_integration.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/207270)

{{< /details >}}

`include`キーワードを使用すると、複数のファイルからCI/CDの設定を構成できます。たとえば、長い`.gitlab-ci.yml`ファイルを複数のファイルに分割して可読性を高めたり、複数のプロジェクトで1つのCI/CD設定ファイルを再利用したりできます。

以前は、単一のCI/CD設定には最大150個のファイルを含めることができましたが、GitLab 16.0では管理者がインスタンス設定でこの制限を別の値に変更できます。

### ユーザーとしてプロジェクトRunnerを作成 {#create-project-runners-as-a-user}

<!-- categories: Runner Fleet -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/383144)

{{< /details >}}

この新しいワークフローでは、プロジェクトに新しいRunnerを追加するために、認証されたユーザーがGitLab UIでRunnerを作成し、必須の設定メタデータを含める必要があります。

この方法により、Runnerはユーザーに簡単にトレースできるようになり、管理者がビルドイシューのトラブルシューティングを行う際や、セキュリティインシデントに対応する際に役立ちます。

### `projects/:id/jobs` APIエンドポイントのレート制限が引き下げられました {#rate-limit-for-the-projectsidjobs-api-endpoint-reduced}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../security/rate_limits.md#project-jobs-api-endpoint) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/382985)

{{< /details >}}

以前は、`GET /api/:version/projects/:id/jobs`は1分あたり2000の認証済みリクエストにレート制限されていました。

これを他のレート制限と整合させ、効率性と信頼性を向上させるため、制限を1分あたり600の認証済みリクエストに引き下げました。

### GitLab Runner 16.0 {#gitlab-runner-160}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 16.0もリリースします！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに送信する、軽量で拡張性の高いエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [Google Compute Engine用GitLab Runnerオートスケールプラグイン - 実験](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29217)

すべての変更点のリストは、GitLab Runnerの[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-0-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.0)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.0)
- [UI改善](https://papercuts.gitlab.com/?milestone=16.0)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
