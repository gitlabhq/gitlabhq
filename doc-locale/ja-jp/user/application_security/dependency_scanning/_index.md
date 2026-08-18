---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 依存関係スキャン
description: 脆弱性、修正、設定、アナライザー、レポート
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

依存関係スキャンは、プロジェクトの依存関係における、ランタイム、開発、および推移的（ネストされた）パッケージを含む既知のセキュリティ脆弱性を特定します。GitLabは、それぞれ異なるワークフローに適した複数の依存関係スキャン手法を提供しています。以下の概要を使用して、プロジェクトに合った手法を選択してください。

## 利用可能なスキャン方法 {#available-scanning-methods}

### 依存関係スキャンにSBOMを使用 {#dependency-scanning-using-sbom}

パイプラインで依存関係スキャンアナライザーによって生成されたCycloneDX SBOMアーティファクトを、GitLab Advisory Databaseと照合してスキャンします。これは、新規プロジェクトに推奨される手法であり、GitLabにおける依存関係スキャンの長期的な方向性でもあります。

詳細については、[SBOMを使用した依存関係スキャン](dependency_scanning_sbom/_index.md)を参照してください。

### 継続的な依存関係スキャン {#continuous-dependency-scanning}

GitLab Advisory Databaseが更新されるたびに、デフォルトブランチの最新の成功したパイプラインからのSBOMコンポーネントを継続的に再スキャンするため、パイプラインを再実行することなく、新たに開示された脆弱性が明らかになります。

詳細については、[Continuous依存関係スキャン](continuous_dependency_scanning/_index.md)を参照してください。

### Gemnasiumを使用した依存関係スキャン {#dependency-scanning-with-gemnasium}

依存関係を検出し、CI/CDジョブでGitLab Advisory Databaseと照合する、元のパイプラインベースのアナライザーです。

> [!warning]
> Gemnasiumアナライザーに基づいた依存関係スキャンは、GitLab 17.9で非推奨となり、GitLab 20.0で削除が提案されています。移行のガイダンスについては、[移行ガイド](migration_guide_to_sbom_based_scans.md)を参照してください。詳細については、[エピック15961](https://gitlab.com/groups/gitlab-org/-/epics/20456)を参照してください。

詳細については、[レガシー依存関係スキャンページ](legacy_dependency_scanning/_index.md)を参照してください。

### 動作の依存関係を分析（Libbehave） {#analyze-dependencies-for-behaviors-libbehave}

依存関係のランタイム動作を分析し、既知のCVEを超えた不審なアクティビティや悪意のあるアクティビティを明らかにする実験です。

詳細については、[動作の依存関係を分析](experiment_libbehave_dependency.md)を参照してください。

## スキャン方法の比較 {#comparison-of-scanning-methods}

| 方法                             | ステータス               | トリガー            | 最適な用途                                                   |
| ---------------------------------- | -------------------- | ------------------ | ---------------------------------------------------------- |
| SBOMを使用した依存関係スキャン     | 一般提供 | パイプライン           | 新規プロジェクト、SBOMファーストワークフロー                         |
| Continuous依存関係スキャン     | 一般提供 | Advisory DB更新 | パイプラインを再実行することなく、新たに開示されたCVEを検出します。 |
| Gemnasiumを使用した依存関係スキャン | 非推奨（17.9）    | パイプライン           | 移行待ちの既存プロジェクト                        |
| 動作の依存関係を分析 | 実験的機能           | パイプライン           | 悪意のあるパッケージの動作を検出                       |

## AIネイティブ機能 {#ai-native-features}

### エージェント型の破壊的変更の解決 {#agentic-breaking-change-resolution}

依存関係を更新するマージリクエストのパイプラインが失敗した場合、GitLab Duoは失敗を分析し、解決するための修正を提供できます。

詳細については、[エージェント型破壊的変更の解決（依存関係の更新用）](agentic-breaking-change-resolution.md)を参照してください。

## 脆弱性データベースにコントリビュートする {#contributing-to-the-vulnerability-database}

脆弱性を検索するには、[`GitLab advisory database`](https://advisories.gitlab.com/)を検索します。[新しい脆弱性を送信](https://gitlab.com/gitlab-org/security-products/gemnasium-db/blob/master/CONTRIBUTING.md)することもできます。
