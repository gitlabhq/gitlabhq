---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 計画ワークフローでWikiを使用する
description: />epics
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Wikiは、計画ツールと連携します。これは別のツールではありません。Wikiページをエピック、イシュー、ボードにリンクできます。GitLab Query Language（GLQL）による組み込みビューを使用すると、Wikiページにイシューや作業アイテムのライブで自動更新されるビューを表示でき、ドキュメントを動的なダッシュボードに変えることができます。Wikiをイシュー、エピック、ボードと接続して、ドキュメントと計画が連携するスムーズなワークフローを作成する方法を学びましょう。

Wikiは、計画ツールに次の機能を提供することで役立ちます:

- 豊富なドキュメントスペース: イシューの説明に収まらない、複雑な要件、設計上の決定、およびプロセスドキュメント。
- バージョン管理されたナレッジ: 仕様と決定の変更を時系列で追跡する。
- ライブデータビュー: GLQLクエリを埋め込み、リアルタイムのイシューと作業アイテムのデータをWikiページに直接表示します。
- 永続的なコンテキスト: イシューがクローズされた後も、決定の背後にある「理由」を保持します。
- 中央参照元: チームのプロセス、標準、および合意のための信頼できる唯一の情報源。
- 柔軟な書式設定: テーブル、図、および完全なMarkdownサポートを備えた長文コンテンツ。
- 統合されたアクセス制御: WikiはGitLabの既存のロールと権限システムを使用するため、チームメンバーは個別の認証なしで、プロジェクトロールに基づいて適切なWikiアクセスを自動的に持ちます。

## 前提条件 {#prerequisites}

このガイドを効果的に使用するには、以下に精通している必要があります:

- [GitLab Wiki](_index.md)
- [GitLab Flavored Markdown](../../markdown.md)
- さまざまな作業アイテム（[イシュー](../issues/_index.md)や[エピック](../../group/epics/_index.md)など）を作成および管理する

## Wikiページを作業アイテムに接続する {#connect-wiki-pages-to-work-items}

Wikiドキュメントと計画アイテム間のリンクを作成し、接続されたナレッジネットワークを構築します。

### Wikiドキュメントをエピックにリンクする {#link-wiki-documentation-to-epics}

エピックには、エピックの説明には長すぎる詳細な仕様が必要となることがよくあります。完全なドキュメントをWikiに保持します:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **計画** > **Wiki**を選択します。
1. 詳細な要件を含むWikiページ（例えば、slug `product-requirements`付き）を作成します。
1. トップバーで**検索または移動先**を選択し、プロジェクトのグループを見つけます。
1. **計画** > **作業アイテム**を選択します。
1. フィルターバーで、**タイプ**、演算子**等しい**、値**エピック**を選択します。
1. 目的のエピックを特定し、そのタイトルを選択します。
1. エピックの説明で、Wikiページにリンクします:

   ```markdown
   ## Requirements

   See full specification: [[product-requirements]]

   Or with custom text: [[Full PRD|product-requirements]]

   Or use the full URL:
   [Full PRD](https://gitlab.example.com/group/project/-/wikis/product-requirements)
   ```

1. Wikiページで、エピックにリンクし直します:

   ```markdown
   Related epic: &123
   ```

例のユースケース:

- 製品要件ドキュメント（PRD）
- 技術設計仕様
- ユーザー調査結果
- 競合分析
- 成功メトリクスとKPI

### イシューからWikiを参照する {#reference-wiki-from-issues}

イシューをWikiページにリンクして、実装の詳細、標準、ガイドを表示します:

```markdown
## Implementation notes

Follow our [[API-design-standards]] when implementing this endpoint.

For local setup, see [[Development Setup Guide|development-environment-setup]].

Definition of Done: [[team-dod]]
```

例のユースケース:

- コーディング標準とスタイルガイド
- 開発環境のセットアップ
- テスト手順
- デプロイ手順書
- トラブルシューティングガイド
- オンボーディングドキュメント

### Wikiから作業アイテムにリンクする {#link-from-wiki-to-work-items}

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

他のプロジェクトのWikiページへのリンク:

```markdown
## Related documentation

See the backend team's API guide: [[backend/api:api-standards]]

Or use the alternative syntax: [wiki_page:backend/api:api-standards]

With custom text: [[Backend API Standards|backend/api:api-standards]]
```

## 埋め込みビューで動的ダッシュボードを作成する {#create-dynamic-dashboards-with-embedded-views}

{{< history >}}

- GitLab 17.4で`glql_integration`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/14767)されました。デフォルトでは無効になっています。
- GitLab.comのGitLab 17.4で、グループとプロジェクトのサブセットに対して有効になりました。
- [変更](https://gitlab.com/gitlab-org/gitlab/-/issues/476990)されました。実験からベータへ、GitLab 17.10で。
- GitLab 17.10の[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/work_items/476990)。
- GitLab 18.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/554870)になりました。機能フラグ`glql_integration`は削除されました。

{{< /history >}}

[GitLab Query Language（GLQL）](../../glql/_index.md)を使用して、Wikiページをライブダッシュボードに変換します。データが変更されると、埋め込みビューは自動的に更新され、Wikiを離れることなく計画データのリアルタイムの表示レベルを提供します。

> [!note]
> 埋め込みビューにはパフォーマンス上の考慮事項があります。大規模なクエリは、タイムアウトするか、レート制限される可能性があります。もしタイムアウトが発生した場合は、より多くのフィルターを追加するか、`limit`パラメータを減らすことで、クエリのスコープを縮小してください。

### 基本的な埋め込みビューの構文 {#basic-embedded-view-syntax}

GLQLクエリを埋め込むには、`glql`を言語識別子として持つコードブロックを使用します:

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

これにより、現在のマイルストーンにおけるすべてのオープンなイシューを示すライブテーブルが作成され、イシューが作成、変更、またはクローズされると自動的に更新されます。

### プランニングダッシュボードの例 {#planning-dashboard-examples}

Wikiページで直接、包括的な計画ダッシュボードを作成します。

> [!note]
> このセクションの例では、`project = "group/project"`を実際のプロジェクトパス（`project = "gitlab-org/gitlab"`や`project = "my-team/my-project"`など）に置き換えてください。

前提条件: 

- クエリされたイシューと作業アイテムを表示するための権限が必要です。

スプリント概要ダッシュボード:

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

クリティカルなバグトラッカー:

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

チームワークロードビュー:

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
- カスタムフィールド: 表示するフィールドを選択します
- ソート: 任意のフィールドで昇順または降順にソートします
- フィルター: 複数の条件を持つ複雑なクエリを使用します
- ページネーション: **更に表示**で追加の結果を読み込みます
- 動的関数: パーソナライズされたビューには`currentUser()`を、日付ベースのクエリには`today()`を使用します。

## Wikiを使ったプランニングワークフロー {#planning-workflows-with-wiki}

### スプリント計画と実行 {#sprint-planning-and-execution}

スプリント全体にわたる接続されたドキュメントフローを作成します:

#### 事前スプリントプランニング {#pre-sprint-planning}

1. 要件収集: ドキュメントの詳細な要件をWikiに記入します
1. エピックの作成: Wiki仕様を参照するエピックを作成します。
1. ストーリーの分解: イシューを関連するWikiドキュメントにリンクします。
1. 見積もりメモ: ドキュメントの見積もり理由をWikiに記入します。

#### スプリント中 {#during-sprint}

- 毎日のスタンドアップ: 毎日、ブロックされたイシューへのリンクを含むWikiページを作成します。
- 技術的決定: 実装イシューへのリンクを付けて設計決定をドキュメント化します。
- 障害: Wikiでブロッカーをイシュー参照とともに追跡する。

#### スプリント後 {#post-sprint}

- レトロスペクティブ: 以下を参照するWikiのレトロスペクティブページを作成します:
  - 完了したイシュー
  - 開発速度メトリクス
  - アクションアイテム（新規イシューとして）
  - 学んだこと

### 長期プランニングドキュメント {#long-term-planning-documentation}

あなたのロードマップに接続する戦略的なドキュメントを維持します:

#### ロードマップドキュメントの構造 {#roadmap-documentation-structure}

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

各ページは関連するエピックにリンクし、イシュー参照を通じて進行状況を追跡する。

#### アーキテクチャ決定レコード {#architecture-decision-records}

トレーサビリティのある技術的決定をドキュメント化します。これと類似したテンプレートを使用できます:

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

### クロスファンクションコラボレーション {#cross-functional-collaboration}

Wikiを機能横断型チームのコラボレーションハブとして使用します:

#### 設計ドキュメント {#design-documentation}

- 設計仕様を実装イシューにリンクします。
- 使用例を含むコンポーネントライブラリを維持します
- エピック参照を使用して設計決定をドキュメント化します。

#### APIドキュメント {#api-documentation}

- 実装イシューにリンクするAPIドキュメントを生成します。
- マイルストーン参照を使用してバージョニング情報を維持します。
- テストイシューにリンクされた例のコードを含めます。

#### QAテスト計画 {#qa-test-plans}

- エピック要件にリンクされたテスト戦略
- テストケースリポジトリとイシュートレーサビリティ
- バグパターンドキュメントとイシューの例

## ナビゲーションと発見パターン {#navigation-and-discovery-patterns}

### イシューやボードからWikiを発見可能にする {#make-wiki-discoverable-from-issues-and-boards}

#### イシューおよびエピックテンプレート {#issue-and-epic-templates}

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

#### 階層的なWiki構造を使用する {#use-hierarchical-wiki-structure}

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

## 実用的な例 {#practical-examples}

### 例1: 機能開発ワークフロー {#example-1-feature-development-workflow}

Wikiインテグレーションを使用した完全な機能開発サイクル:

1. プロダクトマネージャー:

   - 市場調査を含む`feature-x-prd` Wikiページを作成します。
   - リンク`[[Feature X PRD|feature-x-prd]]`付きのエピック &100を作成します。
   - Wikiに受け入れ基準を追加します。

1. エンジニアリングリード:

   - `feature-x-technical-design` Wikiページを作成します。
   - 設計ドキュメントをエピック &100にリンクします。
   - Wiki参照付きの実装イシュー #201-205を作成します。

1. エンジニア:

   - マージリクエストの説明でWiki設計ドキュメントを参照します。
   - 決定の変更をWikiで更新します。
   - イシューをWikiトラブルシューティングガイドにリンクします。

1. QAエンジニア:

   - `feature-x-test-plan` Wikiページを作成します。
   - テストイシュー #301-305をテスト計画にリンクします。
   - イシュー参照付きのテスト結果をWikiでドキュメント化します。

1. テクニカルライター:

   - Wikiのユーザードキュメントを更新します。
   - ドキュメントイシュー #401を作成します。
   - Wikiの変更を機能エピックにリンクします。

### 例2: ライブダッシュボードを備えたチーム知識ベース {#example-2-team-knowledge-base-with-live-dashboards}

リアルタイムのインサイトのために、埋め込みビューでチームハンドブックを構造化します:

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

- [Issue board](https://gitlab.example.com/group/project/-/boards/123)
- [Current milestone](https://gitlab.example.com/group/project/-/milestones/45)
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
| カスタムテキスト付きのリンク            | `[[Display Text\|page-slug]]`             | `[[our API guide\|api-standards]]` |
| クロスプロジェクトWikiリンク          | `[[group/project:page-slug]]`             | `[[backend/api:rest-guide]]` |
| 代替Wiki構文          | `[wiki_page:page-slug]`                   | `[wiki_page:home]` |
| クロスプロジェクト代替        | `[wiki_page:namespace/project:page-slug]` | `[wiki_page:backend/api:home]` |
| 階層リンク（同じレベル）   | `[Link text](page-slug)`                  | `[Related](related-page)` |
| 階層リンク（親）       | `[Link text](../parent-page)`             | `[Up](../main)` |
| 階層リンク（子）        | `[Link text](child-page)`                 | `[Details](details)` |
| ルートリンク                        | `[Link text](/page-from-root)`            | `[Home](/home)` |
| 完全なURL                         | 標準Markdown                         | `[API Guide](https://gitlab.example.com/.../wikis/api-standards)` |

<!-- The `page-from-root` example is added as exception in `doc/.vale/gitlab_docs/InternalLinkFormat.yml` -->

### 作業アイテムの参照 {#referencing-work-items}

| アイテムの種類                 | 構文              | 例 |
| ------------------------- | ------------------- | ------- |
| イシュー（同じプロジェクト）      | `#123`              | `#123`  |
| イシュー（異なるプロジェクト） | `group/project#123` | `gitlab-org/gitlab#123` |
| マージリクエスト             | `!123`              | `!123`  |
| エピック                      | `&123`              | `&123`  |
| マイルストーン                 | `%"Milestone Name"` | `%"18.5"` |

### Wikiからイシューを作成する {#creating-issues-from-wiki}

イシューに変換できるWiki内のタスクリストを使用します:

```markdown
## Action items from retrospective

- [ ] Improve CI pipeline performance
- [ ] Update documentation
- [ ] Add monitoring for API endpoints
```

チェックボックスを選択し、**イシューの作成**を使用してタスクをイシューに変換します。

## 効果的なインテグレーションのヒント {#tips-for-effective-integration}

### ページslugを正しく使用する {#use-page-slugs-correctly}

- Wikiリンクはページslug（URLフレンドリーなバージョン）を使用します: `api-standards`（`API Standards`ではありません）。
- ページが存在しない場合、リンクを選択すると作成できます。
- 貼り付けられたWiki URLは、自動的に読み取り可能なテキストに変換されます（ハイフンはスペースになります）。

### 双方向リンクを維持する {#maintain-bidirectional-links}

- Wikiからイシューにリンクする際、イシューも更新してWikiページを参照するようにしてください。
- 検出を容易にするために、一貫した命名規則を使用します。
- WebhookまたはCI/CDでリンク作成を自動化することを検討します。

### 発見しやすくなるように整理する {#organize-for-discovery}

- すべての計画ドキュメントをインデックスするWikiホームページを作成します。
- 一貫したページ命名を使用します: `sprint-2025-01`、`adr-001`、`feature-name`。
- 大規模なWikiには、フォルダーと階層的な構造を使用します。
- ラベルタクソノミーに一致するカテゴリでWikiページをタグ付けする。

### ドキュメントを最新の状態に保つ {#keep-documentation-current}

- ドキュメントの更新を完了の定義に含めます。
- スプリントプランニング中にWikiページをレビューします。
- 古いページを`archive/`フォルダーにアーカイブします。

### テンプレートを使用する {#use-templates}

共通のドキュメント用のWikiテンプレートを作成します:

- スプリントプランニングテンプレート
- レトロスペクティブテンプレート
- 機能仕様テンプレート
- アーキテクチャ設計レコードテンプレート

## 関連トピック {#related-topics}

- [Wiki](_index.md)
- [イシュー](../issues/_index.md)
- [イシューボード](../issue_board.md)
- [エピック](../../group/epics/_index.md)
- [GitLab Query Language](../../glql/_index.md)
- [GitLab Flavored Markdown](../../markdown.md)
