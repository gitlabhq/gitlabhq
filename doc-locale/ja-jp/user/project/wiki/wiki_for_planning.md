---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 計画ワークフローでWikiを使用する
description: GitLab Wikiを計画ワークフローで活用します。ドキュメントをエピック、イシュー、およびボードに接続します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Wikiは、計画ツールと連携します。これは独立したツールではありません。Wikiページをエピック、イシュー、およびボードにリンクできます。GitLabクエリ言語（GLQL）を利用した埋め込みビューを使用すると、Wikiページにイシューと作業アイテムのライブで自動更新されるビューを表示し、ドキュメントを動的なダッシュボードに変えることができます。イシュー、エピック、およびボードとWikiを接続して、ドキュメントと計画が連携するスムーズなワークフローを作成する方法について説明します。

Wikiは、次のものを提供することで、計画ツールを支援します:

- 豊富なドキュメントスペース: イシューの説明に収まらない、複雑な要件、設計上の意思決定、およびプロセスドキュメント。
- バージョン管理されたナレッジ: 仕様と決定に対する変更を長期にわたって追跡します。
- ライブデータビュー: GLQLクエリを埋め込んで、リアルタイムのイシューと作業アイテムデータをWikiページに直接表示します。
- 永続的なコンテキスト: イシューがクローズされた後も、意思決定の背後にある「理由」を保持します。
- 一元的な参照: チームのプロセス、標準、および合意事項に関する信頼できる唯一の情報源。
- 柔軟なフォーマット: 完全なMarkdownサポートによる表、図、および長文コンテンツ。
- 統合されたアクセス制御: WikiはGitLabの既存のロールとアクセス許可システムを使用するため、チームメンバーは、個別の認証なしに、プロジェクトロールに基づいて適切なWikiアクセス制御を自動的に利用できます。

## 前提要件 {#prerequisites}

このガイドを効果的に使用するには、以下について理解しておく必要があります:

- [GitLab Wikiの基本](_index.md)
- [GitLab Flavored Markdown](../../markdown.md)
- [イシュー](../issues/_index.md)や[エピック](../../group/epics/_index.md)など、さまざまな作業アイテムの作成と管理

## Wikiページを作業アイテムに接続する {#connect-wiki-pages-to-work-items}

Wikiドキュメントと計画項目間のリンクを作成して、接続されたナレッジネットワークを構築します。

### Wikiドキュメントをエピックにリンクする {#link-wiki-documentation-to-epics}

エピックでは、エピックの説明が長すぎる詳細な仕様が必要になることがよくあります。完全なドキュメントをWikiに保持します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **Wiki**を選択します。
1. 詳細な要件を記述したWikiページを作成します（たとえば、スラグ`product-requirements`を使用）。
1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトのグループを見つけます。
1. 左側のサイドバーで**Plan**>**エピック**を選択し、エピックを見つけます。
1. エピックの説明で、Wikiページへのリンクを作成します:

   ```markdown
   ## Requirements

   See full specification: [[product-requirements]]

   Or with custom text: [[Full PRD|product-requirements]]

   Or use the full URL:
   [Full PRD](https://gitlab.example.com/group/project/-/wikis/product-requirements)
   ```

1. Wikiページで、エピックへのバックリンクを作成します:

   ```markdown
   Related epic: &123
   ```

想定されるユースケースは次のとおりです:

- 製品要件ドキュメント（PRD）
- 技術設計仕様
- ユーザー調査結果
- 競合分析
- 成功メトリクスとKPI

### イシューからWikiを参照する {#reference-wiki-from-issues}

実装の詳細、標準、およびガイドについて、イシューをWikiページにリンクします:

```markdown
## Implementation notes

Follow our [[API-design-standards]] when implementing this endpoint.

For local setup, see [[Development Setup Guide|development-environment-setup]].

Definition of Done: [[team-dod]]
```

想定されるユースケースは次のとおりです:

- コーディングの標準とスタイルガイド
- 開発環境のセットアップ
- テストケース手順
- デプロイ手順書
- トラブルシューティングガイド
- オンボーディングドキュメント

### Wikiから作業アイテムへのリンク {#link-from-wiki-to-work-items}

イシューとエピックをWikiページで直接参照します:

```markdown
## Current sprint goals

- Implement user authentication: #1234
- Fix performance regression: #1235
- Update API documentation: #1236

## Q3 roadmap

Major initiatives:
- Authentication overhaul: &10
- Performance improvements: &11
- API v2 release: &12
```

### クロスプロジェクトWiki参照 {#cross-project-wiki-references}

他のプロジェクトのWikiページにリンクします:

```markdown
## Related documentation

See the backend team's API guide: [[backend/api:api-standards]]

Or use the alternative syntax: [wiki_page:backend/api:api-standards]

With custom text: [[Backend API Standards|backend/api:api-standards]]
```

## 埋め込みビューを使用して動的なダッシュボードを作成する {#create-dynamic-dashboards-with-embedded-views}

{{< history >}}

- GitLab 17.4で`glql_integration`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/14767)されました。デフォルトでは無効になっています。
- GitLab.comのGitLab 17.4で、グループとプロジェクトのサブセットに対して有効になりました。
- GitLab 17.10で実験的機能からベータに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/476990)されました。
- GitLab 17.10のGitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/554870)になりました。機能フラグ`glql_integration`は削除されました。

{{< /history >}}

[GitLab Query Language](../../glql/_index.md)（GLQL）を使用して、Wikiページをライブダッシュボードに変換します。埋め込みビューは、データが変更されると自動的に更新され、Wikiを離れることなく、計画データへのリアルタイム表示レベルを提供します。

{{< alert type="note" >}}

埋め込みビューには、パフォーマンスに関する考慮事項があります。大規模なクエリは、タイムアウトになるか、レート制限される場合があります。タイムアウトが発生した場合は、フィルターを追加するか、`limit`パラメータを減らすことで、クエリのスコープを縮小してください。

{{< /alert >}}

### 基本的な埋め込みビューの構文 {#basic-embedded-view-syntax}

GLQLクエリを埋め込むには、言語識別子として`glql`を含むコードを使用します:

````yaml
```glql
display: table
title: Sprint 18.5 Dashboard
description: Current sprint work items
fields: title, assignee, state, health, labels, milestone, updated
limit: 20
sort: updated desc
query: project = "gitlab-org/gitlab" and milestone = "18.5" and opened = true
```
````

これにより、現在のマイルストーンのすべてのオープンイシューを示すライブテーブルが作成され、イシューが作成、変更、またはクローズされると自動的に更新されます。

### 計画ダッシュボードの例 {#planning-dashboard-examples}

Wikiページで直接、包括的な計画ダッシュボードを作成します。

{{< alert type="note" >}}

このセクション全体の例では、`project = "group/project"`を実際のプロジェクトパス（`project = "gitlab-org/gitlab"`や`project = "my-team/my-project"`など）に置き換えてください。

{{< /alert >}}

前提要件: 

- クエリされたイシューと作業アイテムを表示するためのアクセス許可が必要です。

スプリントの概要ダッシュボード:

````yaml
```glql
display: table
title: Sprint Overview
description: All work for the current sprint
fields: title, assignee, state, labels("priority::*") as "Priority", health, due
limit: 30
sort: due asc
query: project = "group/project" and milestone = "Current Sprint" and opened = true
```
````

重大なバグトラッカー:

````yaml
```glql
display: table
title: Critical Bugs
description: High-priority bugs requiring immediate attention
fields: title, assignee, labels, created, updated
limit: 10
query: project = "group/project" and label = "bug" and label = "severity::1" and opened = true
```
````

チームのワークロードビュー:

````yaml
```glql
display: list
title: Team Work In Progress
description: Active work items by team member
fields: title, assignee, milestone, due
limit: 15
sort: assignee asc
query: project = "group/project" and assignee in (alice, bob, charlie) and label = "workflow::in dev"
```
````

個人のタスクリスト:

````yaml
```glql
display: orderedList
title: My Tasks
description: Tasks assigned to me, sorted by priority
fields: title, labels("priority::*") as "Priority", due
limit: 10
sort: due asc
query: type = Task and assignee = currentUser() and opened = true
```
````

埋め込みビューは以下をサポートしています:

- 複数の表示形式: `table`、`list`、または`orderedList`
- カスタムフィールド: 表示するフィールドを選択してください
- ソート: 任意のフィールドで昇順または降順に並べ替えます
- フィルタリング: 複数の条件で複雑なクエリを使用する
- ページネーション: **更に表示**を使用して、追加の結果を読み込む
- 動的関数: パーソナライズされたビューには`currentUser()`を使用し、日付ベースのクエリには`today()`を使用します

## Wikiによる計画ワークフロー {#planning-workflows-with-wiki}

### スプリント計画と実行 {#sprint-planning-and-execution}

スプリント全体で接続されたドキュメントフローを作成します:

#### スプリント前の計画 {#pre-sprint-planning}

1. 要件収集: Wikiで詳細な要件をドキュメント化します
1. エピックの作成: Wikiの仕様を参照するエピックを作成する
1. ストーリーの分解: 関連するWikiドキュメントにイシューをリンクします
1. 見積もりメモ: Wikiで見積もりの理由をドキュメント化します

#### スプリント中 {#during-sprint}

- 毎日のスタンドアップ: ブロックされたイシューへのリンクを含む毎日のWikiページを作成します
- 技術的な決定: 実装イシューへのリンクを含む設計上の決定をドキュメント化する
- 障害: イシュー参照を使用してWikiでブロッカーを追跡します

#### スプリント後 {#post-sprint}

- レトロスペクティブ: 以下を参照するWikiレトロスペクティブページを作成します:
  - 完了したイシュー
  - ベロシティメトリクス
  - アクションアイテム（新しいイシューとして）
  - 学んだ教訓

### 長期計画ドキュメント {#long-term-planning-documentation}

ロードマップに接続する戦略的なドキュメントを維持します:

#### ロードマップドキュメント構造 {#roadmap-documentation-structure}

```plaintext
roadmap/
├── 2025-strategy
├── q1-okrs
├── q2-okrs
├── architecture-decisions/
│   ├── adr-001-microservices
│   ├── adr-002-authentication
└── technical-debt-registry
```

各ページは、関連するエピックにリンクし、イシュー参照を通じて進捗状況を追跡します。

#### アーキテクチャの意思決定レコード {#architecture-decision-records}

トレーサビリティを備えた技術的な意思決定をドキュメント化します。次のようなテンプレートを使用できます:

```markdown
# ADR-001: Adopt microservices architecture

## Status

Accepted

## Context

[Detailed context...]

## Decision

[Decision details...]

## Consequences

[Impact analysis...]

## Implementation

- Infrastructure epic: &50
- Service extraction: #2001, #2002, #2003
- Monitoring setup: #2004
```

### 機能横断型チームのコラボレーション {#cross-functional-collaboration}

機能横断型チームのコラボレーションハブとしてWikiを使用します:

#### 設計ドキュメント {#design-documentation}

- 設計仕様を実装イシューにリンクする
- 使用例を含むコンポーネントライブラリを維持する
- エピック参照を使用して設計上の意思決定をドキュメント化する

#### APIドキュメント {#api-documentation}

- 実装イシューにリンクするAPIドキュメントを生成します
- マイルストーン参照を使用してバージョニング情報を維持する
- テストイシューにリンクされているサンプルコードを含める

#### 品質保証テスト計画 {#qa-test-plans}

- エピックの要件にリンクされたテスト戦略
- イシュートレーサビリティを備えたテストケースリポジトリ
- イシューの例を含むバグパターンドキュメント

## ナビゲーションと検出パターン {#navigation-and-discovery-patterns}

### イシューとボードからWikiを見つけやすくする {#make-wiki-discoverable-from-issues-and-boards}

#### イシューとエピックのテンプレート {#issue-and-epic-templates}

テンプレートにWiki参照を含めます:

```markdown
## Prerequisites

- [ ] Review [[contribution-guidelines]]
- [ ] Check [[security-checklist]]
- [ ] Read relevant documentation in [[project-wiki-home]]

## Implementation

- [ ] Follow [[coding-standards]]
- [ ] Update [[api-documentation]] if needed
- [ ] Add tests per [[testing-guidelines]]
```

#### マイルストーンの説明 {#milestone-descriptions}

Wiki計画ドキュメントへのリンク:

```markdown
## Milestone 18.5

Sprint dates: 2025-02-01 to 2025-02-14

- [[Sprint 18.5 Goals|sprint-18-5-goals]]
- [[Sprint 18.5 Capacity|sprint-18-5-capacity]]
- [[Known Issues|known-issues-and-workarounds]]
```

#### ボードの説明 {#board-descriptions}

Wikiワークフロードキュメントを参照します:

```markdown
This board follows our [[Kanban Workflow Guide|kanban-workflow-guide]].

For column definitions, see [[Board Column Definitions|board-column-definitions]].
```

### Wikiに作業アイテムを表示する {#surface-work-items-in-wiki}

#### インデックスページを作成する {#create-index-pages}

関連するイシューを収集するWikiページをビルドします:

```markdown
# Open bugs dashboard

## Critical (P1)

- #1001 - Database connection timeout
- #1002 - Authentication bypass

## High (P2)

- #1003 - Performance degradation
- #1004 - UI rendering issue

## By component

### Authentication

- #1001, #1005, #1009

### API

- #1002, #1006, #1010
```

#### 階層型Wiki構造を使用する {#use-hierarchical-wiki-structure}

フォルダーと相対リンクを使用してWikiページを整理します:

```markdown
# Team handbook

## Processes

- [Sprint Planning](processes/sprint-planning) - How we plan sprints
- [Code Review](processes/code-review) - Review standards and SLAs
- [Incident Response](processes/incident-response) - On-call procedures

## Go up to parent page

[Back to Documentation](../documentation)
```

## 実践的な例 {#practical-examples}

### 例1: 機能開発ワークフロー {#example-1-feature-development-workflow}

Wikiインテグレーションを使用した完全な機能開発サイクル:

1. プロダクトマネージャー:

   - 市場調査を含む`feature-x-prd` Wikiページを作成します。
   - 次のリンク付きでエピック&100を作成します: `[[Feature X PRD|feature-x-prd]]`。
   - Wikiに受け入れ基準を追加します。

1. エンジニアリングリード:

   - `feature-x-technical-design` Wikiページを作成します。
   - 設計ドキュメントをエピック&100にリンクします。
   - Wiki参照を使用して、実装イシュー＃201〜205を作成します。

1. エンジニア:

   - MRの説明でWiki設計ドキュメントを参照します。
   - 意思決定の変更でWikiを更新します。
   - イシューをWikiトラブルシューティングガイドにリンクします。

1. 品質保証エンジニア:

   - `feature-x-test-plan` Wikiページを作成します。
   - テストイシュー＃301〜305をテスト計画にリンクします。
   - イシュー参照を使用して、Wikiでテスト結果をドキュメント化します。

1. テクニカルライター:

   - Wikiでユーザードキュメントを更新します。
   - ドキュメントイシュー＃401を作成します。
   - Wikiの変更を機能エピックにリンクします。

### 例2: ライブダッシュボードを備えたチームナレッジベース {#example-2-team-knowledge-base-with-live-dashboards}

リアルタイムのインサイトを得るために、埋め込みビューを使用してチームハンドブックを構成します:

````markdown
# Engineering team handbook

## Current sprint status

```glql
display: table
title: Sprint Progress
fields: title, assignee, state, labels("workflow::*") as "Status"
limit: 20
query: project = "team/project" and milestone = "Sprint 23" and opened = true
```

## Processes

- [[Sprint Planning Process|sprint-planning-process]] - How we plan sprints
- [[Code Review Guidelines|code-review-guidelines]] - Review standards and SLAs
- [[Incident Response|incident-response]] - On-call procedures

## Technical standards

- [[API Design Standards|API-design-standards]] - REST API conventions
- [[Database Schema Guide|database-schema-guide]] - Schema design rules
- [[Security Checklist|security-checklist]] - Security requirements

## Work management

- [Issue Board](https://gitlab.example.com/group/project/-/boards/123)
- [Current Milestone](https://gitlab.example.com/group/project/-/milestones/45)
- Label taxonomy: [[Label Definitions|label-definitions]]

## Onboarding

- [[New Developer Setup|new-developer-setup]] - Environment setup
- [[First Week Issues|first-week-issues]] - Good first issues: #101, #102, #103
- [[Team Contacts|team-contacts]] - Who to ask for what
````

## クイック参照 {#quick-reference}

### Wikiリンク構文 {#wiki-linking-syntax}

| 目的                          | 構文                                    | 例 |
| -------------------------------- | ----------------------------------------- | ------- |
| Wikiページへのリンク（同じプロジェクト） | `[[page-slug]]`                           | `[[api-standards]]` |
| カスタムテキスト付きリンク            | `[[Display Text\|page-slug]]`             | `[[our API guide\|api-standards]]` |
| クロスプロジェクトWikiリンク          | `[[group/project:page-slug]]`             | `[[backend/api:rest-guide]]` |
| 代替Wiki構文          | `[wiki_page:page-slug]`                   | `[wiki_page:home]` |
| クロスプロジェクトの代替        | `[wiki_page:namespace/project:page-slug]` | `[wiki_page:backend/api:home]` |
| 階層リンク（同じレベル）   | `[Link text](page-slug)`                  | `[Related](related-page)` |
| 階層リンク（親）       | `[Link text](../parent-page)`             | `[Up](../main)` |
| 階層リンク（子）        | `[Link text](child-page)`                 | `[Details](details)` |
| ルートリンク                        | `[Link text](/page-from-root)`            | `[Home](/home)` |
| フルURL                         | 標準Markdown                         | `[API Guide](https://gitlab.example.com/.../wikis/api-standards)` |

<!-- The `page-from-root` example is added as exception in doc/.vale/gitlab_docs/InternalLinkFormat.yml -->

### 作業アイテムを参照する {#referencing-work-items}

| アイテムの種類                 | 構文              | 例 |
| ------------------------- | ------------------- | ------- |
| イシュー（同じプロジェクト）      | `#123`              | `#123`  |
| イシュー（異なるプロジェクト） | `group/project#123` | `gitlab-org/gitlab#123` |
| マージリクエスト             | `!123`              | `!123`  |
| エピック                      | `&123`              | `&123`  |
| マイルストーン                 | `%"Milestone Name"` | `%"18.5"` |

### Wikiからイシューを作成する {#creating-issues-from-wiki}

イシューに変換できるWikiのタスクリストを使用します:

```markdown
## Action items from retrospective

- [ ] Improve CI pipeline performance
- [ ] Update documentation
- [ ] Add monitoring for API endpoints
```

チェックボックスを選択し、**イシューの作成**を使用して、タスクを追跡されたイシューに変換します。

## 効果的なインテグレーションのためのヒント {#tips-for-effective-integration}

### ページスラグを正しく使用する {#use-page-slugs-correctly}

- Wikiリンクはページスラグ（URLフレンドリーバージョン）を使用します: `API Standards`ではなく`api-standards`。
- ページが存在しない場合、リンクを選択すると作成できます。
- 貼り付けられたWiki URLは、読みやすいテキストに自動的に変換されます（ハイフンはスペースになります）。

### 双方向リンクを維持する {#maintain-bidirectional-links}

- Wikiからイシューにリンクする場合は、Wikiページを参照するようにイシューも更新してください。
- 見つけやすくするために、一貫した命名規則を使用してください。
- WebhookまたはCI/CDを使用して、リンクの作成を自動化することを検討してください。

### 見つけやすいように整理する {#organize-for-discovery}

- すべての計画ドキュメントのインデックスを作成するWikiホームページを作成します。
- 一貫したページ命名規則を使用します: `sprint-2025-01`、`adr-001`、`feature-name`。
- 大規模なWikiでは、フォルダーを使用して階層構造を使用します。
- ラベルの分類と一致するカテゴリでWikiページをタグ付けします。

### ドキュメントを最新の状態に保つ {#keep-documentation-current}

- 完了の定義にドキュメントの更新を含めます。
- スプリント計画中にWikiページをレビューします。
- 古くなったページを`archive/`フォルダーにアーカイブします。

### テンプレートを使用する {#use-templates}

一般的なドキュメント用のWikiテンプレートを作成します:

- スプリント計画テンプレート
- レトロスペクティブテンプレート
- 仕様テンプレートの機能
- アーキテクチャ決定レコードテンプレート

## 関連トピック {#related-topics}

- [Wiki](_index.md)
- [イシュー](../issues/_index.md)
- [イシューボード](../issue_board.md)
- [エピック](../../group/epics/_index.md)
- [GitLab Query Language（GLQL）](../../glql/_index.md)
- [GitLab Flavored Markdown](../../markdown.md)
