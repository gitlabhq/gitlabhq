---
stage: Create
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: VS Code拡張機能のカスタムクエリ
---

GitLabワークフロー拡張機能は、[サイドバー](_index.md#view-issues-and-merge-requests)をVS Codeに追加します。このサイドバーには、プロジェクトごとのデフォルトの検索クエリが表示されます:

- Issues assigned to me（自分に割り当てられたイシュー）
- Issues created by me（自分が作成したイシュー）
- Merge requests assigned to me（自分に割り当てられたマージリクエスト）
- Merge requests created by me（自分が作成したマージリクエスト）
- Merge requests I'm reviewing（自分がレビュー中のマージリクエスト）

デフォルトのクエリに加えて、[カスタムクエリを作成](#create-a-custom-query)できます。

## VS Codeで検索クエリの結果を表示する {#view-search-query-results-in-vs-code}

前提要件: 

- GitLabプロジェクトのメンバーであること。
- 拡張機能を[インストール済み](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)。
- [セットアップ](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/tree/main/#setup)の説明に従って、GitLabインスタンスにサインインしました。

プロジェクトの検索結果を表示するには:

1. 左側の垂直メニューバーで**GitLab Workflow**（{{< icon name="tanuki" >}}）を選択して、拡張機能サイドバーを表示します。
1. サイドバーで**イシューとマージリクエスト**を展開します。
1. プロジェクトを選択してクエリを表示し、実行するクエリを選択します。
1. クエリタイトルの下で、表示したい検索結果を選択します。
1. 検索結果がマージリクエストの場合、VS Codeで表示するものを選択します:
   - **概要**: マージリクエストの説明、ステータス、およびコメント。
   - このマージリクエストで変更されたすべてのファイル名。ファイルを選択して、変更の差分を表示します。
1. 検索結果がイシューの場合、それを選択して、VS Codeでその説明、履歴、コメントを表示します。

## カスタムクエリを作成 {#create-a-custom-query}

定義したカスタムクエリはすべて、[VS Codeサイドバー](_index.md#view-issues-and-merge-requests)の**Issues and Merge requests**（イシューとマージリクエスト）に表示されるデフォルトのクエリをオーバーライドします。

拡張機能のデフォルトのクエリをオーバーライドして独自のクエリに置き換えるには:

1. VS Codeの上部バーで、**コード** > **設定** > **設定**に移動します。
1. 右上隅で、**Open Settings (JSON)**（設定を開く（JSON））を選択して、`settings.json`ファイルを編集します。
1. ファイル内で、この例のように`gitlab.customQueries`を定義します。各クエリは、`gitlab.customQueries` JSON配列内のエントリである必要があります:

   ```json
   {
     "gitlab.customQueries": [
       {
         "name": "Issues assigned to me",
         "type": "issues",
         "scope": "assigned_to_me",
         "noItemText": "No issues assigned to you.",
         "state": "opened"
       }
     ]
   }
   ```

1. オプション。`gitlab.customQueries`をカスタマイズすると、定義はすべてのデフォルトのクエリをオーバーライドします。デフォルトのクエリを復元するには、拡張機能の`default`配列からコピーします[`desktop.package.json`ファイル](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/blob/8e4350232154fe5bf0ef8a6c0765b2eac0496dc7/desktop.package.json#L955-998)。
1. 変更を保存します。

### すべてのクエリでサポートされるパラメータ {#supported-parameters-for-all-queries}

すべてのアイテムタイプがすべてのパラメータをサポートしているわけではありません。これらのパラメータは、すべてのクエリタイプに適用されます:

| パラメータ    | 必須 | デフォルト           | 定義 |
|--------------|----------|-------------------|------------|
| `name`       | {{< icon name="check-circle" >}}対応 | 該当なし               | GitLabパネルに表示するラベル。 |
| `noItemText` | {{< icon name="dotted-circle" >}}対象外       | `No items found.` | クエリがアイテムを返さない場合に表示するテキスト。 |
| `type`       | {{< icon name="dotted-circle" >}}対象外       | `merge_requests`  | 返すアイテムタイプ。使用可能な値: `issues`、`merge_requests`、`epics`、`snippets`、`vulnerabilities`。スニペットは、他のフィルターを[サポートしていません](../../api/project_snippets.md)。エピックは、GitLabプレミアムおよびUltimateプランでのみ使用できます。|

### イシュー、エピック、マージリクエストのクエリでサポートされるパラメータ {#supported-parameters-for-issue-epic-and-merge-request-queries}

| パラメータ          | 必須               | デフォルト      | 定義 |
|--------------------|------------------------|--------------|------------|
| `assignee`         | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | 指定されたユーザー名に割り当てられたアイテムを返します。`None`は、割り当てられていないGitLabアイテムを返します。`Any`は、アサイン先を持つGitLabアイテムを返します。エピックおよび脆弱性では使用できません。 |
| `author`           | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | 指定されたユーザー名で作成されたアイテムを返します。 |
| `confidential`     | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | 非公開イシューまたは公開イシューをフィルタリングします。イシューでのみ利用可能です。 |
| `createdAfter`     | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | 指定された日付より後に作成されたアイテムを返します。 |
| `createdBefore`    | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | 指定された日付より前に作成されたアイテムを返します。 |
| `draft`            | {{< icon name="dotted-circle" >}}対象外 | `no`         | `yes`は[ドラフト状態](../../user/project/merge_requests/drafts.md)のマージリクエストのみを返し、`no`はドラフト状態ではないマージリクエストのみを返します。マージリクエストでのみ使用できます。 |
| `excludeAssignee`  | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | 指定されたユーザー名に割り当てられていないアイテムを返します。イシューでのみ利用可能です。現在のユーザーの場合は、`<current_user>`に設定します。 |
| `excludeAuthor`    | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | 指定されたユーザー名で作成されなかったアイテムを返します。イシューでのみ利用可能です。現在のユーザーの場合は、`<current_user>`に設定します。 |
| `excludeLabels`    | {{< icon name="dotted-circle" >}}対象外 | `[]`         | ラベル名の配列。イシューでのみ利用可能です。返されたアイテムには、配列内のラベルがありません。定義済みの名前では大文字と小文字が区別されません。 |
| `excludeMilestone` | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | 除外するマイルストーンのタイトル。イシューでのみ利用可能です。 |
| `excludeSearch`    | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | タイトルまたは説明に検索キーがないGitLabアイテムを検索します。イシューでのみ動作します。 |
| `labels`           | {{< icon name="dotted-circle" >}}対象外 | `[]`         | ラベル名の配列。返されたアイテムには、配列内のすべてのラベルがあります。`None`はラベルのないアイテムを返し、`Any`は少なくとも1つのラベルを持つアイテムを返します。定義済みの名前では大文字と小文字が区別されません。 |
| `maxResults`       | {{< icon name="dotted-circle" >}}対象外 | 20           | 表示する結果の数。 |
| `milestone`        | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | マイルストーンのタイトル。`None`はマイルストーンのないすべてのアイテムをリストし、`Any`は割り当てられたマイルストーンを持つすべてのアイテムをリストします。エピックおよび脆弱性では使用できません。 |
| `orderBy`          | {{< icon name="dotted-circle" >}}対象外 | `created_at` | 選択した値で順序付けられたエンティティを返します。使用可能な値: `created_at`、`updated_at`、`priority`、`due_date`、`relative_position`、`label_priority`、`milestone_due`、`popularity`、`weight`。一部の値はイシューに固有で、一部の値はマージリクエストに固有です。詳細については、[マージリクエスト](../../api/merge_requests.md#list-merge-requests)を参照してください。 |
| `reviewer`         | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | このユーザー名にレビューを割り当てられたマージリクエストを返します。現在のユーザーの場合は、`<current_user>`に設定します。`None`は、レビュアーのいないアイテムを返し、`Any`はレビュアーのいるアイテムを返します。 |
| `scope`            | {{< icon name="dotted-circle" >}}対象外 | `all`        | 指定されたスコープのGitLabアイテムを返します。エピックには適用されません。使用可能な値: `assigned_to_me`、`created_by_me`、`all`。 |
| `search`           | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | タイトルと説明に対してGitLabアイテムを検索します。 |
| `searchIn`         | {{< icon name="dotted-circle" >}}対象外 | `all`        | `excludeSearch`検索属性のスコープを変更します。使用可能な値: `all`、`title`、`description`。イシューでのみ動作します。 |
| `sort`             | {{< icon name="dotted-circle" >}}対象外 | `desc`       | 昇順または降順でソートされたイシューを返します。使用可能な値: `asc`、`desc`。 |
| `state`            | {{< icon name="dotted-circle" >}}対象外 | `opened`     | すべてのイシュー、または特定の状態に一致するイシューのみを返します。使用可能な値: `all`、`opened`、`closed`。 |
| `updatedAfter`     | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | 指定された日付より後に更新されたアイテムを返します。 |
| `updatedBefore`    | {{< icon name="dotted-circle" >}}対象外 | 該当なし          | 指定された日付より前に更新されたアイテムを返します。 |

### 脆弱性レポートのクエリでサポートされるパラメータ {#supported-parameters-for-vulnerability-report-queries}

脆弱性レポートは、他のエントリタイプと[共通のクエリパラメータを共有していません](../../api/vulnerability_findings.md)。この表にリストされている各パラメータは、脆弱性レポートでのみ動作します:

| パラメータ          | 必須               | デフォルト        | 定義 |
|--------------------|------------------------|----------------|------------|
| `confidenceLevels` | {{< icon name="dotted-circle" >}}対象外 | `all`          | 指定された信頼水準に属する脆弱性を返します。使用できる値は、`undefined`、`ignore`、`unknown`、`experimental`、`low`、`medium`、`high`、`confirmed`です。 |
| `reportTypes`      | {{< icon name="dotted-circle" >}}対象外 | 該当なし | 指定されたレポートタイプに属する脆弱性を返します。使用可能な値: `sast`、`dast`、`dependency_scanning`、`container_scanning`。 |
| `scope`            | {{< icon name="dotted-circle" >}}対象外 | `dismissed`    | 指定されたスコープの脆弱性の検出結果を返します。使用可能な値: `all`、`dismissed`。詳細については、[脆弱性の検出結果API](../../api/vulnerability_findings.md)を参照してください。 |
| `severityLevels`   | {{< icon name="dotted-circle" >}}対象外 | `all`          | 指定された重大度レベルに属する脆弱性を返します。使用可能な値: `undefined`、`info`、`unknown`、`low`、`medium`、`high`、`critical`。 |
