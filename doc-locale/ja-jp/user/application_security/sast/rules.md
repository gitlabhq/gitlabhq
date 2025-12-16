---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SASTルール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabの静的アプリケーションセキュリティテスト（SAST）では、一連の[GitLabアナライザー](analyzers.md)を使用して、コードに潜在的な脆弱性がないかスキャンします。どのアナライザーを実行するかは、リポジトリで見つかったプログラミング言語に基づいて自動的に選択されます。

各アナライザーはコードを処理し、ルールを使用してコード内の考えられる脆弱性を検出します。アナライザーのルールは、レポートする脆弱性の種類を決定します。

## スコープルール {#scope-of-rules}

SASTは、セキュリティ上の弱点と脆弱性に焦点を当てています。一般的なバグを見つけたり、コードの全体的な品質や保守性を評価したりすることを目的としていません。

GitLabは、実用的なセキュリティ上の弱点と脆弱性を特定することに重点を置いて、検出ルールセットを管理します。このルールセットは、最も影響力のある脆弱性に対して幅広いカバレッジを提供すると同時に、誤検出（脆弱性が存在しない場合にレポートされる脆弱性）を最小限に抑えるように設計されています。

SASTはデフォルトの設定で使用するように設計されていますが、必要に応じて[検出ルールを設定する](#configure-rules-in-your-projects)こともできます。

## ルールのソース {#source-of-rules}

SASTで使用される脆弱性検出ルールは、使用されるアナライザー（GitLab高度な静的アプリケーションセキュリティテストまたはSemgrepベースのアナライザー）によって異なります。

### GitLab高度なSAST {#gitlab-advanced-sast}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

GitLabは、[GitLab高度な静的アプリケーションセキュリティテスト](gitlab_advanced_sast.md)のルールを作成、維持、サポートしています。そのルールは、GitLab高度な静的アプリケーションセキュリティテストスキャンエンジンのクロスファイル、クロスファンクション分析機能を活用するためにカスタムビルドされています。GitLab高度な静的アプリケーションセキュリティテストルールセットはオープンソースではなく、他のアナライザーと同一のルールセットでもありません。

GitLab高度な静的アプリケーションセキュリティテストが検出する脆弱性の種類の詳細については、[いつ脆弱性がレポートされるか](gitlab_advanced_sast.md#when-vulnerabilities-are-reported)を参照してください。

### Semgrepベースのアナライザー {#semgrep-based-analyzer}

GitLabは、SemgrepベースのGitLab SASTアナライザーで使用されるルールを作成、維持、サポートしています。このアナライザーは、単一のCI/CDパイプラインジョブで[多くの言語](_index.md#supported-languages-and-frameworks)をスキャンします。次のものを組み合わせます:

- Semgrepオープンソースエンジン。
- GitLab管理の検出ルールセット。これは[GitLab管理のオープンソース`sast-rules`プロジェクト](https://gitlab.com/gitlab-org/security-products/sast-rules)で管理されています。
- [脆弱性の追跡](_index.md#advanced-vulnerability-tracking)に関するGitLab独自のテクノロジー。

### その他のアナライザー {#other-analyzers}

GitLab SASTは、他のアナライザーを使用して、残りの[サポートされている言語](_index.md#supported-languages-and-frameworks)をスキャンします。これらのスキャンのルールは、各スキャナーのアップストリームプロジェクトで定義されています。

## ルールの更新リリース方法 {#how-rule-updates-are-released}

GitLabは、顧客からのフィードバックと内部調査に基づいて、ルールを定期的に更新します。ルールは、各アナライザーのコンテナイメージの一部としてリリースされます。[特定のバージョンにアナライザーを手動で固定する](_index.md#pinning-to-minor-image-version)場合を除き、更新されたアナライザーとルールが自動的にリリースされます。

アナライザーとそのルールは、関連する更新プログラムが利用可能な場合、[少なくとも月1回](../detect/vulnerability_scanner_maintenance.md)更新されます。

### ルール更新ポリシー {#rule-update-policies}

SASTルールのアップデートは、[破壊的な変更](../../../update/terminology.md#breaking-change)ではありません。つまり、ルールは事前の通知なしに追加、削除、または更新される可能性があります。

ただし、ルールの変更をより便利で理解しやすいものにするために、GitLabは次のことを行います:

- 計画または完了した[ルールの変更](#important-rule-changes)をドキュメント化します。
- Semgrepベースのアナライザーの場合、削除されたルールからの[検出結果を自動的に解決する](_index.md#automatic-vulnerability-resolution)。
- [アクティビティーが「検出されなくなった」脆弱性のステータスを一括で変更](../vulnerability_report/_index.md#change-status-of-vulnerabilities)できます。
- 既存の脆弱性レコードに影響を与える可能性のある提案されたルールの変更を評価します。

## プロジェクトでルールを設定する {#configure-rules-in-your-projects}

変更を加える具体的な理由がない限り、デフォルトのSASTルールを使用する必要があります。デフォルトのルールセットは、ほとんどのプロジェクトに関連するように設計されています。

ただし、必要に応じて、[使用するルールをカスタマイズ](#apply-local-rule-preferences)したり、[ルールの変更をロールアウトする方法を制御](#coordinate-rule-rollouts)したりできます。

### ローカルルールの優先順位を適用する {#apply-local-rule-preferences}

SASTスキャンで使用されるルールをカスタマイズしたい理由は次のとおりです:

- 組織が特定の脆弱性クラスに優先順位を割り当てている（たとえば、他のクラスの脆弱性の前にクロスサイトスクリプティング（XSS）またはSQLインジェクションに対処することを選択するなど）。
- 特定のルールが誤検出の結果であるか、コードベースのコンテキストでは無関係であると考えています。

プロジェクトをスキャンするために使用するルールを変更したり、重大度を調整したり、その他の優先順位を適用したりするには、[ルールセットをカスタマイズする](customize_rulesets.md)を参照してください。カスタマイズが他のユーザーの役に立つ場合は、[GitLabへの問題レポート](#report-a-problem-with-a-gitlab-sast-rule)を検討してください。

### ルールのロールアウトを調整する {#coordinate-rule-rollouts}

ルールの変更のロールアウトを制御するには、[特定のバージョンにSASTアナライザーを固定](_index.md#pinning-to-minor-image-version)できます。

複数のプロジェクトで同時にこれらの変更を行う場合は、次の変数の設定を検討してください:

- [グループレベルのCI/CD変数](../../../ci/variables/_index.md#for-a-group)。
- [スキャン実行ポリシー](../policies/scan_execution_policies.md)のカスタムCI/CD変数。

## GitLab SASTルールに関する問題のレポート {#report-a-problem-with-a-gitlab-sast-rule}
<!-- This title is intended to match common search queries users might make. -->

GitLabは、SASTで使用されるルールセットへのコントリビュートを歓迎します。コントリビュートは、以下に対処する可能性があります:

- 潜在的な誤検出の結果。
- SASTが実際に存在する可能性のある脆弱性をレポートしなかった偽陰性の結果。
- ルールの名前、重大度評価、説明、ガイダンス、またはその他の説明コンテンツ。

検出ルールがすべてのユーザーに対して改善される可能性があると思われる場合は、以下を検討してください:

- [`sast-rules`リポジトリにマージリクエストを送信する](https://gitlab.com/gitlab-org/security-products/sast-rules)。詳細については、[コントリビュート手順](https://gitlab.com/gitlab-org/security-products/sast-rules#contributing)を参照してください。
- [`gitlab-org/gitlab`イシュートラッカーにイシューを提出する](https://gitlab.com/gitlab-org/gitlab/-/issues/)。
  - `@gitlab-bot label ~"group::static analysis" ~"Category:SAST"`とコメントを投稿して、イシューが適切なトリアージワークフローに着地するようにします。

## 重要なルールの変更 {#important-rule-changes}

GitLabは、[定期的に](#how-rule-updates-are-released) SASTルールを更新します。このセクションでは、最も重要な変更点について説明します。詳細については、リリースのお知らせと、提供されている変更履歴のリンクを参照してください。

### Semgrepベースのアナライザーのルールの変更 {#rule-changes-in-the-semgrep-based-analyzer}

Semgrepベースのスキャン用のGitLab管理ルールセットへの主な変更点は次のとおりです:

- GitLab 16.3以降、GitLab静的な解析および誤検出の結果が多すぎるか、実用的な真陽性の結果が十分に得られない傾向があるルールの削除に取り組んでいます。これらの削除されたルールからの既存の検出結果は[自動的に解決されます](_index.md#automatic-vulnerability-resolution) 。[セキュリティダッシュボード](../security_dashboard/_index.md#project-security-dashboard)または[脆弱性 レポート](../vulnerability_report/_index.md)のデフォルトビューには表示されなくなりました。この作業は[エピック10907](https://gitlab.com/groups/gitlab-org/-/epics/10907)で追跡されます。
- GitLab 16.0〜16.2では、GitLab脆弱性調査チームは、各結果に含まれているガイダンスを更新しました。
- GitLab 15.10では、`detect-object-injection`ルールが[デフォルトで削除](https://gitlab.com/gitlab-org/gitlab/-/issues/373920)され、その検出結果は[自動的に解決されました](_index.md#automatic-vulnerability-resolution)。

詳細については、[`sast-rules`の変更履歴](https://gitlab.com/gitlab-org/security-products/sast-rules/-/blob/main/CHANGELOG.md)を参照してください。

### 他のアナライザーのルールの変更 {#rule-changes-in-other-analyzers}

各[アナライザー](analyzers.md)の変更履歴ファイルを参照して、各バージョンに含まれる新しいルールや更新されたルールなど、変更の詳細を確認してください。
