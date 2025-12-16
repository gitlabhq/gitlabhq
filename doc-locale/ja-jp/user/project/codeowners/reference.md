---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: "`CODEOWNERS`ファイルの構文"
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`CODEOWNERS`ファイルは構文を使用して所有権ルールを定義します。ファイルの各行はルールを表し、ファイルパスのパターンと1人以上のオーナーを指定します。主な要素は次のとおりです:

- ファイルパス: 特定のファイル、ディレクトリ、またはワイルドカード。
- GitLabコードオーナー: ユーザー、グループ、またはロールに`@mentions`を使用します。
- コメント: `#`で始まる行は無視されます。インラインコメントはサポートされていません。コメントにリストされているGitLabコードオーナーはすべて解析されます。
- セクション: `[Section name]`を使用して定義されるルールのグループ化（オプション）。

{{< alert type="note" >}}

エントリがセクション内で重複している場合、[最後のエントリが使用されます](advanced.md#define-code-owners-for-specific-files-or-directories)。ファイルの後半で定義されたルールは、前半で定義されたルールよりも優先されます。

{{< /alert >}}

次に例を示します:

```plaintext
# Specify a default Code Owner for all files with a wildcard:
* @default-owner

# Specify multiple Code Owners to a specific file:
README.md @doc-team @tech-lead

# Specify a Code Owner to all files with a specific extension:
*.rb @ruby-owner

# Specify Code Owners with usernames or email addresses:
LICENSE @legal janedoe@gitlab.com

# Use group names to match groups and nested groups:
README @group @group/with-nested/subgroup

# Specify a Code Owner to a directory and all its contents:
/docs/ @all-docs
/docs/* @root-docs
/docs/**/*.md @markdown-docs  # Match specific file types in any subdirectory
/db/**/index.md @index-docs   # Match a specific file name in any subdirectory

# Use a section to group related rules:
[Documentation]
ee/docs    @docs
docs       @docs

# Assign a role as a Code Owner:
/config/ @@maintainer
```

## セクション {#sections}

`CODEOWNERS`ファイルでは、セクションは個別に分析され、常に適用される名前付き領域です。セクションを定義するまで、GitLabは`CODEOWNERS`ファイル全体を1つのセクションとして処理します。セクションを追加すると、GitLabがファイルを評価する方法が変わります:

- GitLabは、[セクションのないエントリ](advanced.md#regular-entries-and-sections)（最初のセクションヘッダーより前に定義されたルールを含む）を、名前のない別のセクションとして処理します。
- 各セクションは、ルールを個別に適用します。
- セクションごとに1つのGitLabコードオーナーパターンのみがファイルパスに一致します。
- ファイルの後半で定義されたルールは、前半で定義されたルールよりも優先されます。

たとえば、`CODEOWNERS`ファイルに、`README`ファイルのGitLabコードオーナーを定義するセクションがあるとします:

```plaintext
* @admin

[README Owners]
README.md @user1 @user2
internal/README.md @user4

[README other owners]
README.md @user3
```

- ルートディレクトリにある`README.md`のGitLabコードオーナーは次のようになります:
  - 名前のないセクションからの`@admin`。
  - `[README Owners]`からの`@user1`と`@user2`。
  - `[README other owners]`からの`@user3`。
- `internal/README.md`のGitLabコードオーナーは次のようになります:
  - 名前のないセクションからの`@admin`。
  - `[README Owners]`の最後のエントリからの`@user4`。
  - `[README other owners]`からの`@user3`。（`[README Owners]`の両方の行がこのファイル名に一致しますが、セクション内の最後の行のみが保持されます）

`CODEOWNERS`ファイルにセクションを追加するには、セクション名を角かっこで囲んで入力し、その後にファイルまたはディレクトリと、ユーザー、グループ、またはサブグループを入力します:

```plaintext
[README Owners]
README.md @user1 @user2
internal/README.md @user2
```

マージリクエストウィジェットの各GitLabコードオーナーは、ラベルの下にリストされます。以下の画像は、`Default`、`Frontend`、`Technical Writing`の各セクションを示しています:

![MRウィジェット - セクション別GitLabコードオーナー](img/sectional_code_owners_v17_4.png)

セクションの設定オプションの詳細については、以下を参照してください:

- [デフォルトのGitLabコードオーナーとオプションのセクション](advanced.md#default-code-owners-and-optional-sections)
- [標準のエントリとセクション](advanced.md#regular-entries-and-sections)
- [名前が重複しているセクション](advanced.md#sections-with-duplicate-names)

### セクションの見出しと名前 {#section-headings-and-names}

セクションの見出しには名前が必要です。セクション名は大文字と小文字は区別されず、[名前が重複しているセクション](advanced.md#sections-with-duplicate-names)は結合されます。保護ブランチの場合のみ、次のように指定できます:

- 承認を必須にする（デフォルト）。
- オプションにする（プレフィックス`^`を付ける）。
- 特定の数の承認を必須にする。詳細については、[グループの継承と資格](advanced.md#group-inheritance-and-eligibility)および[承認がオプションとして表示される](troubleshooting.md#approvals-shown-as-optional)を参照してください。
- デフォルトのオーナーを含める。

例:

```plaintext
# Required section
[Section name]

# Optional section
^[Section name]

# Section requiring 5 approvals
[Section name][5]

# Section with @username as default owner
[Section name] @username

# Section with @group and @subgroup as default owners and requiring 2 approvals
[Section name][2] @group @subgroup
```

### セクションにデフォルトのGitLabコードオーナーを設定する {#set-default-code-owner-for-a-section}

セクション内の複数のファイルパスが同じ所有権を共有する場合は、セクションにデフォルトのGitLabコードオーナーを定義します。特定の行でセクションのデフォルトをオーバーライドしない限り、そのセクション内のすべてのパスがこのデフォルトを継承します。

デフォルトのオーナーは、ファイルパスに特定のオーナーが指定されていない場合に適用されます。ファイルパスの横に定義された特定のオーナーは、デフォルトのオーナーをオーバーライドします。

次に例を示します:

```plaintext
[Documentation] @docs-team
docs/
README.md

[Database] @database-team @agarcia
model/db/
config/db/database-setup.md @docs-team
```

この例では: 

- `@docs-team`は、`Documentation`セクション内のすべての項目を所有します。
- `@database-team`と`@agarcia`は、`config/db/database-setup.md`を除く、`Database`セクションのすべての項目を所有します。この項目には`@docs-team`に割り当てるオーバーライドがあります。

[標準のエントリとセクションを一緒に](advanced.md#regular-entries-and-sections)使用するときに、セクション内のエントリがセクションなしのエントリをオーバーライドしない場合とこの動作を比較してください。

### オプションのセクション {#optional-sections}

GitLabコードオーナーファイルでオプションのセクションを指定できます。オプションのセクションを使用すると、コードベースのさまざまな部分に対して責任者を指定できますが、その責任者の承認は必要ありません。このアプローチにより、頻繁に更新されるが、厳格なレビューを必要としないプロジェクトの部分に対して、緩和されたポリシーを適用できます。

セクション全体をオプションとして扱うには、セクション名の先頭にキャレット`^`文字を付けます。

この例では、`[Go]`セクションがオプションです:

```plaintext
[Documentation]
*.md @root

[Ruby]
*.rb @root

^[Go]
*.go @root
```

オプションのGitLabコードオーナーセクションは、マージリクエストで説明の下に表示されます:

![MRウィジェット - オプションのGitLabコードオーナーセクション](img/optional_code_owners_sections_v17_4.png)

セクションがファイル内で複製され、そのうちの1つがオプションとしてマークされ、もう1つはオプションとしてマークされていない場合、そのセクションは必須になります。

`CODEOWNERS`ファイル内のオプションのセクションは、マージリクエストを使用して変更が送信された場合にのみ、オプションとして処理されます。変更が保護ブランチに直接送信された場合、セクションがオプションとしてマークされている場合でも、GitLabコードオーナーからの承認が必要になります。

## 対象となるコードオーナー {#eligible-code-owners}

適格性ルールにより、有効なコードオーナーが決定されます。具体的なルールは、`CODEOWNERS`ファイル内の参照方法（ユーザー名、グループ、またはロール）に応じて適用されます。

### ユーザーの適格性 {#user-eligibility}

コードオーナーの対象となるには、ユーザー名（`@username`）で参照されるユーザーがプロジェクトで承認されている必要があります。次のルールが適用されます:

- プロジェクトとグループの表示レベル設定は、適格性に影響しません。
- [グループからBAN](../../group/moderate_users.md)されたユーザーは、GitLabコードオーナーになることはできません。
- 対象となるユーザーは、次のようなメンバーシップを持つユーザーです:
  - 少なくともデベロッパーロールを持つプロジェクトへの直接的なメンバーシップ。
  - プロジェクトのグループ（直接または継承）のメンバーシップ。
  - プロジェクトのグループの祖先のメンバーシップ。
  - プロジェクトに招待されたグループの直接または継承メンバーシップ。
  - プロジェクトのグループに招待されたグループの直接メンバーシップ（継承ではない）。
  - プロジェクトのグループの祖先に招待されたグループの直接メンバーシップ（継承ではない）。

### グループの適格性 {#group-eligibility}

グループ名（`@group_name`）またはネストされたグループ名（`@nested/group/names`）でグループを参照する場合、次のルールが適用されます:

- グループの表示レベル設定は、適格性に影響しません。
- 参照されるグループの直接メンバーのみが対象となります。継承メンバーは含まれません。
- 対象となるグループは、次のようなグループです:
  - プロジェクトのグループ。
  - プロジェクトのグループの祖先。
  - デベロッパーロール以上のデベロッパーロール以上の権限でプロジェクトに招待されたグループ。

### ロールの適格性 {#role-eligibility}

ロール（`@@role`）を参照する場合、次のルールが適用されます:

- GitLabコードオーナーとして使用できるのは、デベロッパー、メンテナー、およびオーナーのロールのみです。
- 指定したロールが割り当てられた直接のプロジェクトメンバーのみが対象となります。
- ロールには上位のロールは含まれません。たとえば、`@@developer`を指定しても、メンテナーロールまたはオーナーロールが割り当てられたユーザーは含まれません。

グループの継承と適格性に関するより複雑なシナリオについては、[グループの継承と適格性](advanced.md#group-inheritance-and-eligibility)を参照してください。

## ロールをGitLabコードオーナーとして追加する {#add-a-role-as-a-code-owner}

{{< history >}}

- GitLab 17.7で`codeowner_role_approvers`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/282438)されました。
- GitLab 17.8の[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/497504)で有効になりました。
- GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/512623)になりました。機能フラグ`codeowner_role_approvers`は削除されました。

{{< /history >}}

直接のプロジェクトメンバーのロールをGitLabコードオーナーとして追加または設定できます:

- `@@`プレフィックスを使用してロールを設定します。
- デベロッパー、メンテナー、オーナーのロールのみ使用できます。
- ロールには上位のロールは含まれません。たとえば、`@@developer`を指定しても、メンテナーロールまたはオーナーロールが割り当てられたユーザーは含まれません。
- 指定したロールが割り当てられた直接のプロジェクトメンバーのみに、GitLabコードオーナーの資格があります。
- 複数形のロールを指定することも可能です。たとえば、`@@developers`は受け入れられます。

次の例では、デベロッパーロールまたはメンテナーロールが割り当てられた直接のプロジェクトメンバー全員を`file.md`のGitLabコードオーナーとして設定します:

1. `CODEOWNERS`ファイルを開きます。
1. 次のパターンを使用して行を追加します:

   ```plaintext
   file.md @@developer @@maintainer
   ```

1. ファイルを保存します。
1. 変更をコミットしてマージします。

## グループをGitLabコードオーナーとして追加する {#add-a-group-as-a-code-owner}

グループまたはサブグループの直接メンバーをGitLabコードオーナーとして設定できます。グループメンバーシップの詳細については、[メンバーシップの種類](../members/_index.md#membership-types)を参照してください。

前提要件: 

- グループを[プロジェクトに招待する](../members/sharing_projects_groups.md#invite-a-group-to-a-project)必要があります。

グループまたはサブグループの直接のメンバーをGitLabコードオーナーとして設定するには:

1. `CODEOWNERS`ファイルを開きます。
1. 次のいずれかのパターンに従うテキストを入力します:

   ```plaintext
   # All direct group members as Code Owners for a file
   file.md @group-x

   # All direct subgroup members as Code Owners for a file
   file.md @group-x/subgroup-y

   # All direct group and direct subgroup members as Code Owners for a file
   file.md @group-x @group-x/subgroup-y
   ```

1. ファイルを保存します。
1. 変更をコミットしてマージします。

### 設定例 {#example-configuration}

```plaintext
[Maintainers]
* @gitlab-org/maintainers/group-name
```

この例では: 

- グループ`group-name`が、`[Maintainers]`セクションの下にリストされています。
- `group-name`には、次の直接メンバーが含まれています:

  ![グループメンバーのリスト。](img/direct_group_members_v17_9.png)

- マージリクエスト承認ウィジェットでは、同じ直接メンバーが`Maintainers`としてリストされています:

  ![マージリクエストのメンテナー。](img/merge_request_maintainers_v17_9.png)

{{< alert type="note" >}}

[グローバルSAMLグループメンバーシップロック](../../group/saml_sso/group_sync.md#global-saml-group-memberships-lock)が有効になっている場合、グループまたはサブグループをGitLabコードオーナーとして設定することはできません。詳細については、[グローバルSAMLグループメンバーシップロックとの非両立性](troubleshooting.md#incompatibility-with-global-group-memberships-locks)を参照してください。

{{< /alert >}}

問題が発生した場合は、[ユーザーが承認者候補として表示されない](troubleshooting.md#user-not-shown-as-possible-approver)を参照してください。

## パスの一致 {#path-matching}

パスは、絶対パス、相対パス、ディレクトリパス、ワイルドカードパス、またはGlobstarパスにすることができ、リポジトリのルートと照合されます。

### 絶対パス {#absolute-paths}

`/`で始まるパスは、リポジトリのルートから一致します:

```plaintext
# Matches only README.md in the root.
/README.md

# Matches only README.md inside the /docs directory.
/docs/README.md
```

### 相対パス {#relative-paths}

先頭に`/`がないパスは、[Globstarパス](#globstar-paths)として扱われます:

```plaintext
# Matches /README.md, /internal/README.md, /app/lib/README.md
README.md @username

# Matches /internal/README.md, /docs/internal/README.md, /docs/api/internal/README.md
internal/README.md
```

{{< alert type="note" >}}

Globstarパスを使用する場合は、意図しない一致に注意してください。たとえば、先頭に`/`がない`README.md`は、リポジトリの任意のディレクトリまたはサブディレクトリ内の任意の`README.md`ファイルに一致します。

{{< /alert >}}

### ディレクトリパス {#directory-paths}

ディレクトリとそのサブディレクトリ内のすべてのファイルに一致させるには、`/`でパスを終了します:

```plaintext
# Matches all files in /docs/ and its subdirectories
/docs/
```

### ワイルドカードパス {#wildcard-paths}

複数の文字に一致させるには、`*`を使用します:

```plaintext
# Any markdown files in the docs directory
/docs/*.md @username

# /docs/index file of any filetype
# For example: /docs/index.md, /docs/index.html, /docs/index.xml
/docs/index.* @username

# Any file in the docs directory with 'spec' in the name.
# For example: /docs/qa_specs.rb, /docs/spec_helpers.rb, /docs/runtime.spec
/docs/*spec* @username

# README.md files one level deep within the docs directory
# For example: /docs/api/README.md
/docs/*/README.md @username
```

### Globstarパス {#globstar-paths}

複数のディレクトリレベルにわたってファイルまたはパターンを一致させるには、`**`を使用します:

```plaintext
# For example: /docs/index.md, /docs/api/index.md, and /docs/api/graphql/index.md.
/docs/**/index.md
```

ディレクトリ内のすべてのファイルに一致させるには、末尾にスラッシュ（`/`）が付いた[ディレクトリパス](#directory-paths)を使用します。

### 除外パターン {#exclusion-patterns}

{{< history >}}

- GitLab 17.10で`codeowners_file_exclusions`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/180162)されました。
- GitLab 17.10の[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/517075)で有効になりました。
- GitLab 17.11[で一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/517309)になりました。機能フラグ`codeowners_file_exclusions`は削除されました。

{{< /history >}}

ファイルまたはパスの先頭に`!`を付けて、コードオーナーの承認がそのファイルまたはパスに要求されないようにします。除外はそのセクションに適用されます。次の例では、このようになります:

- `pom.xml`除外はデフォルトセクションに適用されます。
- `/config/**/*.rb`除外は、RubyセクションのRubyファイルにのみ影響します。

```plaintext
# All files require approval from @username
* @username

# Except pom.xml which needs no approval
!pom.xml

[Ruby]
# All ruby files require approval from @ruby-team
*.rb @ruby-team

# Except Ruby files in the config directory
!/config/**/*.rb
```

次のガイドラインは、除外パターンの動作を説明しています:

- 除外はそのセクションで順番に評価されます。次に例を示します:

  ```plaintext
  * @default-owner
  !*.rb                      # Excludes all Ruby files.
  /special/*.rb @ruby-owner  # This won't take effect as *.rb is already excluded.
  ```

- パターンが除外された後に、同じセクションに再度含めることはできません:

  ```plaintext
  [Ruby]
  *.rb @ruby-team           # All Ruby files need Ruby team approval.
  !/config/**/*.rb          # Ruby files in config don't need Ruby team approval.
  /config/routes.rb @ops    # This won't take effect as config Ruby files are excluded.
  ```

- 除外パターンに一致するファイルは、そのセクションのコードオーナーの承認を必要としません。オーナーごとに異なる除外が必要な場合は、複数のセクションを使用します:

  ```plaintext
  [Ruby]
  *.rb @ruby-team
  !/config/**/*.rb        # Config Ruby files don't need Ruby team approval.

  [Config]
  /config/ @ops-team      # Config files still require ops-team approval.
  ```

- 自動的に更新されるファイルに除外を使用します:

  ```plaintext
  * @default-owner

  # Files updated by automation don't need approval.
  !package-lock.json
  !yarn.lock
  !**/generated/          # Any files in generated directories.
  !.gitlab-ci.yml
  ```

## エントリオーナー {#entry-owners}

エントリには1人以上のオーナーが必要です。グループ、サブグループ、ユーザーがオーナーになることができます。

```plaintext
/path/to/entry.rb @group
/path/to/entry.rb @group/subgroup
/path/to/entry.rb @user
/path/to/entry.rb @group @group/subgroup @user
```

グループをGitLabコードオーナーとして追加する方法の詳細については、[グループをGitLabコードオーナーとして追加する](#add-a-group-as-a-code-owner)を参照してください。

## 関連トピック {#related-topics}

- [GitLabコードオーナー](_index.md)
- [高度な`CODEOWNERS`の設定](advanced.md)
- [マージリクエスト承認](../merge_requests/approvals/_index.md)
- [保護ブランチ](../repository/branches/protected.md)
- [コードオーナーのトラブルシューティング](troubleshooting.md)
