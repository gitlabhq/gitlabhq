---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクト
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## クエリフィールド {#query-fields}

以下のフィールドは必須です: [ネームスペース](#project-group)

| フィールド                                                    | 名前（およびエイリアス）       | 演算子  |
| -------------------------------------------------------- | ---------------------- | ---------- |
| [アーカイブのみ](#project-archived-only)                  | `archivedOnly`         | `=`、`!=`  |
| [グループ / ネームスペース](#project-group)                      | `namespace`、`group`   | `=`        |
| [コードカバレッジあり](#project-has-code-coverage)          | `hasCodeCoverage`      | `=`、`!=`  |
| [脆弱性あり](#project-has-vulnerabilities)      | `hasVulnerabilities`   | `=`、`!=`  |
| [アーカイブを含む](#project-include-archived)            | `includeArchived`      | `=`、`!=`  |
| [サブグループを含む](#project-include-subgroups)          | `includeSubgroups`     | `=`、`!=`  |
| [イシューを有効化](#project-issues-enabled)                | `issuesEnabled`        | `=`、`!=`  |
| [マージリクエストを有効化](#project-merge-requests-enabled)| `mergeRequestsEnabled` | `=`、`!=`  |

### アーカイブのみ {#project-archived-only}

**説明**: アーカイブ済みのプロジェクトのみを表示するようにフィルターします。

**指定可能な値の型**: `Boolean`（`true`または`false`）

**ノート**:

- `includeArchived`とは併用できません。

### グループ / ネームスペース {#project-group}

**説明**: プロジェクトをクエリするグループネームスペースを指定します。このフィールドは必須です。フィールド名として`namespace`または`group`を使用できます。

**指定可能な値の型**: `String`

### コードカバレッジあり {#project-has-code-coverage}

**説明**: プロジェクトにコードカバレッジレポートがあるかどうかでフィルターします。

**指定可能な値の型**: `Boolean`（`true`または`false`）

### 脆弱性あり {#project-has-vulnerabilities}

**説明**: プロジェクトにセキュリティ脆弱性があるかどうかでフィルターします。

**指定可能な値の型**: `Boolean`（`true`または`false`）

### アーカイブを含む {#project-include-archived}

**説明**: 結果にアーカイブ済みプロジェクトを含めます。

**指定可能な値の型**: `Boolean`（`true`または`false`）

**ノート**:

- `archivedOnly`とは併用できません。
- デフォルトでは、アーカイブ済みプロジェクトは含まれません。

### サブグループを含める {#project-include-subgroups}

**説明**: サブグループのプロジェクトを含めるかどうか。

**指定可能な値の型**: `Boolean`（`true`または`false`）

**ノート**:

- このフィールドは`namespace`または`group`フィールドでのみ使用できます。
- `namespace`または`group`が指定されている場合、デフォルトで`true`になります。

### イシューを有効化 {#project-issues-enabled}

**説明**: プロジェクトでイシューが有効になっているかどうかでフィルターします。

**指定可能な値の型**: `Boolean`（`true`または`false`）

### マージリクエストを有効化 {#project-merge-requests-enabled}

**説明**: プロジェクトでマージリクエストが有効になっているかどうかでフィルターします。

**指定可能な値の型**: `Boolean`（`true`または`false`）

## 表示フィールド {#display-fields}

| フィールド                            | 名前（およびエイリアス）                 | 説明 |
| -------------------------------- | -------------------------------- | ----------- |
| アーカイブ済み                         | `archived`                       | プロジェクトがアーカイブされているかどうかを表示 |
| Duo機能が有効             | `duoFeaturesEnabled`             | Duo機能が有効になっているかどうかを表示 |
| フォークした                           | `forked`                         | プロジェクトがフォークであるかどうかを表示 |
| フォーク数                      | `forksCount`                     | フォーク数を表示 |
| フルパス                        | `fullPath`                       | プロジェクトのフルパスを表示 |
| グループ                            | `group`                          | プロジェクトが属するグループを表示 |
| ID                               | `id`                             | プロジェクトIDを表示 |
| イシューを有効化                   | `issuesEnabled`                  | イシューが有効になっているかどうかを表示 |
| 最終アクティビティ                    | `lastActivity`、`lastActivityAt` | プロジェクトの最終アクティブ日時を表示 |
| マージリクエストを有効化           | `mergeRequestsEnabled`           | マージリクエストが有効になっているかどうかを表示 |
| 名前                             | `name`                           | プロジェクト名を表示 |
| 未解決のイシュー数                | `openIssuesCount`                | 未解決のイシュー数を表示 |
| 未解決のマージリクエスト数        | `openMergeRequestsCount`         | 未解決のマージリクエスト数を表示 |
| パス                             | `path`                           | プロジェクトパスを表示 |
| シークレットプッシュ保護が有効   | `secretPushProtectionEnabled`    | シークレットプッシュ保護が有効になっているかどうかを表示 |
| スター数                       | `starCount`                      | スター数を表示 |
| 表示レベル                       | `visibility`                     | プロジェクトの表示レベルを表示 |
| ウェブURL                          | `webUrl`                         | プロジェクトのウェブURLを表示 |

## ソートフィールド {#sort-fields}

| フィールド         | 名前（およびエイリアス）                 | 説明                    |
| ------------- | -------------------------------- | ------------------------------ |
| フルパス     | `fullPath`                       | フルパスでソート              |
| 最終アクティビティ | `lastActivity`、`lastActivityAt` | 最終アクティビティ日でソート     |
| パス          | `path`                           | パスでソート                   |

**ノート**:

- `lastActivity`は降順（`desc`）ソートのみをサポートしています。

**例**:

- `gitlab-org`グループのすべてのプロジェクトをパスでソートしてリスト表示:

  ````yaml
  ```glql
  display: table
  fields: name, fullPath, starCount, openIssuesCount
  sort: path asc
  query: type = Project and group = "gitlab-org"
  ```
  ````

- `gitlab-org`グループのすべてのプロジェクトを最終アクティブ日時でソートしてリスト表示:

  ````yaml
  ```glql
  display: table
  fields: name, fullPath, lastActivity
  sort: lastActivity desc
  query: type = Project and group = "gitlab-org"
  ```
  ````
