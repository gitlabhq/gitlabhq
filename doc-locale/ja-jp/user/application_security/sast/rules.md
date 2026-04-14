---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: SASTルール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab静的アプリケーションセキュリティテスト（SAST）は、一連の[アナライザー](analyzers.md)を使用して、コード内の潜在的な脆弱性をスキャンします。アナライザーを実行するかは、リポジトリ内で検出されたプログラミング言語に基づいて自動的に選択されます。

各アナライザーはコードを処理し、ルールを使用してソースコード内の潜在的な脆弱性を見つけます。アナライザーのルールは、報告する脆弱性のタイプを決定します。

## ルールのスコープ {#scope-of-rules}

SASTは、セキュリティの脆弱性と脆弱性に焦点を当てています。一般的なバグを見つけたり、全体的なコード品質や保守性を評価することを目的としていません。

GitLabは、実用的なセキュリティの脆弱性と脆弱性の特定に焦点を当てて検出ルールセットを管理しています。このルールセットは、最も影響の大きい脆弱性に対して広範なカバレッジを提供し、誤検出（脆弱性が存在しないにもかかわらず報告された脆弱性）を最小限に抑えるように設計されています。

SASTはデフォルトの設定で使用するように設計されていますが、必要に応じて[検出ルールを構成](#configure-rules-in-your-projects)できます。

## ルールのソース {#source-of-rules}

SASTが使用する脆弱性検出ルールは、GitLab高度なSASTまたはSemgrepベースのアナライザーのいずれか、使用するアナライザーによって異なります。

### GitLab高度なSAST {#gitlab-advanced-sast}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

GitLabは、[GitLab高度なSAST](gitlab_advanced_sast.md)のルールを作成、保守、サポートしています。そのルールは、GitLab高度なSASTスキャンエンジンのクロスファイル、クロスファンクション分析機能を活用するようにカスタム構築されています。GitLab高度なSASTのルールセットはオープンソースではなく、他のどのアナライザーのルールセットとも異なります。

GitLab高度なSASTが検出する脆弱性のタイプについては、[脆弱性検出基準](gitlab_advanced_sast.md#vulnerability-detection-criteria)を参照してください。

### Semgrepベースのアナライザー {#semgrep-based-analyzer}

GitLabは、SemgrepベースのGitLab SASTアナライザーで使用されるルールを作成、保守、サポートしています。このアナライザーは、単一のCI/CDパイプラインジョブで[多くの言語](_index.md#supported-languages-and-frameworks)をスキャンします。以下の要素を組み合わせます:

- Semgrepのオープンソースエンジン。
- GitLabが管理する検出ルールセット。[GitLabが管理するオープンソースの`sast-rules`プロジェクト](https://gitlab.com/gitlab-org/security-products/sast-rules)で管理されています。
- [脆弱性の追跡](_index.md#advanced-vulnerability-tracking)のためのGitLab独自のテクノロジー。

### その他のアナライザー {#other-analyzers}

GitLab SASTは、残りの[サポートされている言語](_index.md#supported-languages-and-frameworks)をスキャンするために他のアナライザーを使用します。これらのスキャンのルールは、各スキャナーのアップストリームプロジェクトで定義されています。

## ルール更新のリリース方法 {#how-rule-updates-are-released}

GitLabは、顧客のフィードバックと社内調査に基づいて定期的にルールを更新しています。ルールは、各アナライザーのコンテナイメージの一部としてリリースされます。[アナライザーを特定のバージョンに手動で固定](_index.md#pin-analyzer-image-version)しない限り、更新されたアナライザーとルールが自動的に提供されます。

アナライザーとそのルールは、関連する更新が利用可能な場合、[少なくとも毎月](../detect/vulnerability_scanner_maintenance.md)更新されます。

### ルール更新ポリシー {#rule-update-policies}

SASTルールの更新は[破壊的な変更](../../../update/terminology.md#breaking-change)ではありません。これは、ルールが事前の通知なしに追加、削除、または更新される可能性があることを意味します。

ただし、ルール変更をより便利で分かりやすくするために、GitLabは次のことを行います:

- 計画されている、または完了した[ルール変更](#important-rule-changes)をドキュメント化します。
- Semgrepベースのアナライザーから削除されたルールからの検出結果を[自動的に解決](_index.md#automatic-vulnerability-resolution)します。
- [アクティビティが「検出されなくなりました」となっている脆弱性のステータスを一括で変更](../vulnerability_report/_index.md#change-status-of-vulnerabilities)できます。
- 提案されたルール変更が既存の脆弱性レコードに与える影響を評価します。

## プロジェクトでのルールの設定 {#configure-rules-in-your-projects}

変更を行う特別な理由がない限り、デフォルトのSASTルールを使用してください。デフォルトのルールセットは、ほとんどのプロジェクトに関連するように設計されています。

ただし、必要に応じて、[使用するルールをカスタマイズ](#apply-local-rule-preferences)したり、ルール変更の[ロールアウト方法を制御](#coordinate-rule-rollouts)したりできます。

### ローカルのルール設定を適用する {#apply-local-rule-preferences}

SASTスキャンで使用されるルールをカスタマイズしたい理由は次のとおりです:

- 組織が特定の脆弱性クラスに優先順位を付けている場合（例: 他の脆弱性クラスよりもクロスサイトスクリプティング（XSS）やSQLインジェクションに優先的に対処する場合など）。
- 特定のルールが誤検出結果である、またはコードベースのコンテキストに関連しないと考える場合。

プロジェクトのスキャンに使用されるルールを変更したり、その重大度を調整したり、その他の設定を適用したりするには、[ルールセットをカスタマイズ](customize_rulesets.md)するを参照してください。カスタマイズが他のユーザーにも役立つと思われる場合は、[GitLabに問題を報告](#report-a-problem-with-a-gitlab-sast-rule)することを検討してください。

### ルールロールアウトの調整 {#coordinate-rule-rollouts}

ルール変更のロールアウトを制御するには、[SASTアナライザーを特定のバージョンに固定](_index.md#pin-analyzer-image-version)できます。

これらの変更を複数のプロジェクトで同時に行いたい場合は、次の変数を設定することを検討してください:

- [グループレベルのCI/CD変数](../../../ci/variables/_index.md#for-a-group)。
- [スキャン実行ポリシー](../policies/scan_execution_policies.md)内のカスタムCI/CD変数。

## GitLab SASTルールに関する問題を報告する {#report-a-problem-with-a-gitlab-sast-rule}
<!-- This title is intended to match common search queries users might make. -->

GitLabは、SASTで使用されるルールセットへのコントリビュートを歓迎します。コントリビュートは以下に対応する可能性があります:

- 潜在的な脆弱性が正しくない場合の誤検出結果。
- SASTが実際に存在する潜在的な脆弱性を報告しなかった場合の偽陰性結果。
- ルールの名前、重大度評価、説明、ガイダンス、またはその他の説明内容。

検出ルールがすべてのユーザーにとって改善される可能性があると思われる場合は、次を検討してください:

- [`sast-rules`リポジトリ](https://gitlab.com/gitlab-org/security-products/sast-rules)へのマージリクエストの提出。詳細については、[コントリビュートの手順](https://gitlab.com/gitlab-org/security-products/sast-rules#contributing)を参照してください。
- [`gitlab-org/gitlab`のイシュートラッカー](https://gitlab.com/gitlab-org/gitlab/-/issues/)にイシューを提出すること。
  - `@gitlab-bot label ~"group::static analysis" ~"Category:SAST"`と書かれたコメントを投稿して、イシューが正しいトリアージワークフローに送られるようにします。

## 重要なルール変更 {#important-rule-changes}

GitLabはSASTルールを[定期的に](#how-rule-updates-are-released)更新しています。このセクションでは、最も重要な変更点に焦点を当てています。詳細については、リリースのお知らせおよび提供されている変更履歴リンクで確認できます。

### Semgrepベースのアナライザーにおけるルール変更 {#rule-changes-in-the-semgrep-based-analyzer}

Semgrepベースのスキャンに対するGitLab管理のルールセットへの主な変更点は次のとおりです:

- GitLab 16.3以降、GitLabの静的解析および脆弱性研究チームは、誤検出結果が多すぎる、または実用的な真陽性結果が不足している傾向のあるルールを削除する作業を進めています。これらの削除されたルールからの既存の検出結果は[自動的に解決](_index.md#automatic-vulnerability-resolution)されます。[セキュリティダッシュボード](../security_dashboard/_index.md#project-security-dashboard)や[脆弱性レポート](../vulnerability_report/_index.md)のデフォルトビューには表示されなくなります。この作業は[エピック10907](https://gitlab.com/groups/gitlab-org/-/epics/10907)で追跡されます。
- GitLab 16.0から16.2にかけて、GitLabの脆弱性研究チームは、各結果に含まれるガイダンスを更新しました。
- GitLab 15.10では、`detect-object-injection`ルールは[デフォルトで削除](https://gitlab.com/gitlab-org/gitlab/-/issues/373920)され、その検出結果は[自動的に解決](_index.md#automatic-vulnerability-resolution)されました。

詳細については、[`sast-rules`の変更履歴](https://gitlab.com/gitlab-org/security-products/sast-rules/-/blob/main/CHANGELOG.md)を参照してください。

### その他のアナライザーにおけるルール変更 {#rule-changes-in-other-analyzers}

新規または更新されたルールを含む、各バージョンに含まれる変更点の詳細については、各[アナライザー](analyzers.md)の変更履歴ファイルを参照してください。
