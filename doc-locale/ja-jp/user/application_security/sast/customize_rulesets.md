---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 定義済みのルールを無効化、オーバーライド、または置き換えることによって、GitLabでSASTアナライザールールをカスタマイズします。
title: ルールセットをカスタマイズする
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.2で、あいまいなパススルー参照の指定のサポートを[有効化](https://gitlab.com/gitlab-org/security-products/analyzers/ruleset/-/merge_requests/18)しました。

{{< /history >}}

スキャン対象のリポジトリで[ルールセット設定ファイルを定義](#create-the-configuration-file)することで、SASTアナライザーの動作をカスタマイズできます。

## アナライザーごとのカスタマイズオプション {#customization-options-by-analyzer}

| カスタマイズ                                                                                           | GitLab高度なSAST                                                                                                                                             | GitLab Semgrep             | [その他のアナライザー](analyzers.md#official-analyzers) |
|---------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------|----------------------------------------------------|
| [定義済みのルールを無効にする](#disable-predefined-rules)                                                   | {{< icon name="check-circle-filled" >}}対応                                                                                                                                                              | {{< icon name="check-circle-filled" >}}対応                        | {{< icon name="check-circle-filled" >}}対応                                                |
| [定義済みのルールのメタデータをオーバーライドする](#override-metadata-of-predefined-rules)                         | {{< icon name="check-circle-filled" >}}対応                                                                                                                                                              | {{< icon name="check-circle-filled" >}}対応                        | {{< icon name="check-circle-filled" >}}対応                                                |
| [パススルーを使用して、定義済みのルールをカスタム設定に置き換えます](#build-a-custom-configuration) | 定義済みの非taint、構造ルール、およびファイルとrawパススルーの適用動作の変更をサポートします。その他のパススルーの型は無視されます。 | 完全なパススルーをサポート | {{< icon name="dash-circle" >}}対象外                                                 |

## 定義済みのルールを無効にする {#disable-predefined-rules}

任意のSASTアナライザーの定義済みのルールを無効にできます。

ルールを無効にすると:

- カスタムルールセットをサポートするすべてのSASTアナライザーは、脆弱性のスキャンを引き続き行います。結果はスキャン完了後の処理ステップとして削除され、[`gl-sast-report.json`アーティファクト](_index.md#download-a-sast-report)には表示されません。GitLab高度なSASTは、初期スキャンから無効なルールを除外することで異なります。
- 無効になっているルールの検出結果は、[パイプラインセキュリティタブ](../detect/security_scanning_results.md)に表示されなくなります。
- デフォルトのブランチ上の無効なルールの既存の検出結果は、[脆弱性レポート](../vulnerability_report/_index.md)で[`No longer detected`](../vulnerability_report/_index.md#activity-filter)としてマークされます。

Semgrepベースのアナライザーは、無効になっているルールを異なる方法で処理します:

- Semgrepベースのアナライザーでルールを無効にすると、`sast-ruleset.toml`ファイルをデフォルトのブランチにマージした後、そのルールの既存の脆弱性の検出結果は[自動的に解決されます](_index.md#automatic-vulnerability-resolution)。

この動作の設定方法については、[スキーマ](#schema)セクションと[例](#examples)セクションを参照してください。

## 定義済みのルールのメタデータをオーバーライドする {#override-metadata-of-predefined-rules}

任意のSASTアナライザーの定義済みルールの特定の属性をオーバーライドできます。これは、既存のワークフローまたはツールにSASTを適合させる場合に役立ちます。たとえば、組織のポリシーに基づいて脆弱性の重大度をオーバーライドしたり、脆弱性レポートに表示する別のメッセージを選択したりできます。

この動作の設定方法については、[スキーマ](#schema)セクションと[例](#examples)セクションを参照してください。

## カスタム設定をビルドする {#build-a-custom-configuration}

[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)および[GitLab高度なSAST](https://gitlab.com/gitlab-org/security-products/analyzers/gitlab-advanced-sast)アナライザーの[GitLabで管理されているルールセット](rules.md)を独自のルールに置き換えることができます。

カスタマイズはパススルーを使用して提供します。これらはランタイム時にパススルーチェーンに構成され、評価されて完全な設定が生成されます。次に、基盤となるスキャナーがこの新しい設定に対して実行されます。

複数のパススルータイプがあり、リポジトリにコミットされたファイルの使用や、ルールセット設定ファイルへのインラインなど、さまざまな方法で設定を提供できます。また、チェーン内の後続のパススルーの処理方法を選択することもできます。以前の設定をオーバーライドしたり、追加したりできます。

この動作の設定方法については、[スキーマ](#schema)セクションと[例](#examples)セクションを参照してください。

## 設定ファイルを作成します。 {#create-the-configuration-file}

ルールセット設定ファイルを作成するには:

1. プロジェクトのルートに`.gitlab`ディレクトリを作成します（まだ存在しない場合）。
1. `.gitlab`ディレクトリに`sast-ruleset.toml`という名前のファイルを作成します。

## リモート設定ファイルを指定する {#specify-a-remote-configuration-file}

{{< history >}}

- 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393452)されました。

{{< /history >}}

[CI/CD変数](../../../ci/variables/_index.md)を設定して、現在のリポジトリの外部に保存されているルールセット設定ファイルを使用できます。これにより、複数のプロジェクトに同じルールを適用できます。

`SAST_RULESET_GIT_REFERENCE`変数は、プロジェクトのURI、オプションの認証、およびオプションのGitセキュアハッシュアルゴリズムを指定するための[Git URI](https://git-scm.com/docs/git-clone#_git_urls)と同様の形式を使用します。変数は、次の形式を使用します:

```plaintext
[<AUTH_USER>[:<AUTH_PASSWORD>]@]<PROJECT_PATH>[@<GIT_SHA>]
```

{{< alert type="note" >}}

プロジェクトに`.gitlab/sast-ruleset.toml`ファイルがコミットされている場合、そのローカル設定が優先され、`SAST_RULESET_GIT_REFERENCE`で指定されたファイルは使用されません。

{{< /alert >}}

次の例では、[SASTを有効にする](_index.md#configure-sast-in-your-cicd-yaml)、および共有ルールセットのカスタマイズファイルを使用します。この例では、ファイルは`example-ruleset-project`のデフォルトのブランチの`.gitlab/sast-ruleset.toml`にコミットされます。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SAST_RULESET_GIT_REFERENCE: "gitlab.com/example-group/example-ruleset-project"
```

高度な使用法については、[プライベートリモート設定の指定例](#specify-a-private-remote-configuration)を参照してください。

### リモート設定ファイルのトラブルシューティング {#troubleshooting-remote-configuration-files}

リモート設定ファイルがカスタマイズを正しく適用していないように見える場合、原因として考えられるのは次のとおりです:

1. リポジトリにローカルの`.gitlab/sast-ruleset.toml`ファイルがあります。
   - デフォルトでは、リモート設定が変数として設定されている場合でも、ローカルファイルが存在する場合は使用されます。
   - [SECURE_ENABLE_LOCAL_CONFIGURATION CI/CD変数](../../../ci/variables/_index.md)を`false`に設定して、ローカル設定ファイルを無視できます。
1. 認証に問題があります。
   - これが問題の原因であるかどうかを確認するには、認証を必要としないリポジトリの場所から設定ファイルを参照してみてください。

## スキーマ {#schema}

### トップレベルセクション {#the-top-level-section}

トップレベルセクションには、[TOMLテーブル](https://toml.io/en/v1.0.0#table)として定義された1つ以上の設定セクションが含まれています。

| 設定 | 説明 |
| --------| ----------- |
| `[$analyzer]` | アナライザーの設定セクションを宣言します。名前は、[SASTアナライザー](analyzers.md#official-analyzers)のリストで定義されている名前に従います。 |

設定例:

```toml
[semgrep]
...
```

既存のルールを修正してカスタムルールセットをビルドする設定セクションを作成しないでください。後者は定義済みのルールを完全に置き換えるためです。

### `[$analyzer]`設定セクション {#the-analyzer-configuration-section}

`[$analyzer]`セクションでは、アナライザーの動作をカスタマイズできます。有効なプロパティは、作成する設定の種類によって異なります。

| 設定 | 適用対象 | 説明 |
| --------| -------------- | ----------- |
| `[[$analyzer.ruleset]]` | 定義済みのルール | 既存のルールに対する変更を定義します。 |
| `interpolate` | すべて | `true`に設定すると、設定で`$VAR`を使用して環境変数を評価できます。流出したシークレットまたはトークンがリークしないように、この機能は慎重に使用してください。(デフォルト: `false`) |
| `description` | パススルー | カスタムルールセットの説明。 |
| `targetdir`   | パススルー | 最終的な設定が永続化されるディレクトリ。空の場合、ランダムな名前のディレクトリが作成されます。このディレクトリには、最大100MBのファイルを格納できます。SASTジョブがルート以外のユーザー権限で実行されている場合は、ユーザーにこのディレクトリの読み取りおよび書き込み権限があることを確認してください。 |
| `validate`    | パススルー | `true`に設定すると、各パススルーのコンテンツが検証されます。検証は、`yaml`、`xml`、`json`、および`toml`コンテンツに対して機能します。適切なvalidatorは、`[[$analyzer.passthrough]]`セクションの`target`パラメータで使用されている拡張子に基づいて識別されます。(デフォルト: `false`) |
| `timeout`     | パススルー | タイムアウトになる前に、パススルーチェーンの評価に費やす最大時間。タイムアウトは300秒を超えることはできません。(デフォルト: 60) |
| `keepdefaultrules`  | パススルー | `true`に設定すると、アナライザーのデフォルトルールが、定義されたパススルーと組み合わせてアクティブになります。(デフォルト: `false`) |

#### `interpolate` {#interpolate}

{{< alert type="warning" >}}

流出したシークレットのリスクを軽減するため、この機能は慎重に使用してください。

{{< /alert >}}

以下の例は、プライベートリポジトリにアクセスするために`$GITURL`環境変数を使用する設定を示しています。この変数には、ユーザー名とトークン（`https://user:token@url`など）が含まれているため、設定ファイルに明示的に保存されることはありません。

```toml
[semgrep]
  description = "My private Semgrep ruleset"
  interpolate = true

  [[semgrep.passthrough]]
    type  = "git"
    value = "$GITURL"
    ref = "main"
```

### `[[$analyzer.ruleset]]`セクション {#the-analyzerruleset-section}

`[[$analyzer.ruleset]]`セクションは、単一の事前定義されたルールを対象とし、変更します。アナライザーごとに、これらのセクションを1つ以上定義できます。

| 設定 | 説明 |
| --------| ----------- |
| `disable` | ルールを無効にするかどうか。(デフォルト: `false`) |
| `[$analyzer.ruleset.identifier]` | 変更する事前定義されたルールを選択します。 |
| `[$analyzer.ruleset.override]` | ルールのオーバーライドを定義します。 |

設定例:

```toml
[semgrep]
  [[semgrep.ruleset]]
    disable = true
    ...
```

### `[$analyzer.ruleset.identifier]`セクション {#the-analyzerrulesetidentifier-section}

`[$analyzer.ruleset.identifier]`セクションは、変更する事前定義されたルールの識別子を定義します。

| 設定 | 説明 |
| --------| ----------- |
| `type`  | 事前定義されたルールで使用される識別子の型。 |
| `value` | 事前定義されたルールで使用される識別子の値。 |

`type`と`value`の正しい値を調べるには、アナライザーによって生成された[`gl-sast-report.json`](_index.md#download-a-sast-report)を表示します。このファイルは、アナライザーのCIジョブからジョブアーティファクトとしてダウンロードできます。

たとえば、以下のスニペットは、3つの識別子を持つ`semgrep`ルールからの検出結果を示しています。JSONオブジェクトの`type`キーと`value`キーは、このセクションで指定する必要がある値に対応しています。

```json
...
  "vulnerabilities": [
    {
      "id": "7331a4b7093875f6eb9f6eb1755b30cc792e9fb3a08c9ce673fb0d2207d7c9c9",
      "category": "sast",
      "message": "Key Exchange without Entity Authentication",
      "description": "Audit the use of ssh.InsecureIgnoreHostKey\n",
      ...
      "identifiers": [
        {
          "type": "semgrep_id",
          "name": "gosec.G106-1",
          "value": "gosec.G106-1"
        },
        {
          "type": "cwe",
          "name": "CWE-322",
          "value": "322",
          "url": "https://cwe.mitre.org/data/definitions/322.html"
        },
        {
          "type": "gosec_rule_id",
          "name": "Gosec Rule ID G106",
          "value": "G106"
        }
      ]
    }
    ...
  ]
...
```

設定例:

```toml
[semgrep]
  [[semgrep.ruleset]]
    [semgrep.ruleset.identifier]
      type = "semgrep_id"
      value = "gosec.G106-1
    ...
```

### `[$analyzer.ruleset.override]`セクション {#the-analyzerrulesetoverride-section}

`[$analyzer.ruleset.override]`セクションでは、事前定義されたルールの属性をオーバーライドできます。

| 設定 | 説明 |
| --------| ----------- |
| `description`  | 問題の詳細な説明。 |
| `message` | （非推奨）問題の説明。 |
| `name` | ルールの名前。 |
| `severity` | ルールの重大度。有効なオプションは、`Critical`、`High`、`Medium`、`Low`、`Unknown`、`Info`)です。 |

{{< alert type="note" >}}

`message`はアナライザーによって入力されたものですが、`name`および`description`を優先して[非推奨](https://gitlab.com/gitlab-org/security-products/analyzers/report/-/blob/1d86d5f2e61dc38c775fb0490ee27a45eee4b8b3/vulnerability.go#L22)になりました。

{{< /alert >}}

設定例:

```toml
[semgrep]
  [[semgrep.ruleset]]
    [semgrep.ruleset.override]
      severity = "Critical"
      name = "Command injection"
    ...
```

### `[[$analyzer.passthrough]]`セクション {#the-analyzerpassthrough-section}

{{< alert type="note" >}}

パススルー設定は、[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)でのみ使用できます。

{{< /alert >}}

`[[$analyzer.passthrough]]`セクションでは、アナライザーのカスタム設定をビルドできます。アナライザーごとに、これらのセクションを最大20個定義できます。パススルーは、アナライザーの事前定義されたルールを置き換える完全な設定に評価される_パススルーチェーン_に構成されます。

パススルーは順番に評価されます。チェーンの後の方にリストされているパススルーは優先度が高く、以前のパススルーによって生成されたデータをオーバーライドまたは追加できます（`mode`によって異なります）。これは、既存の設定を使用または変更する必要がある場合に役立ちます。

単一のパススルーによって生成される設定のサイズは、10MBに制限されています。

| 設定 | 適用対象 | 説明 |
| ------- | ---------- | ----------- |
| `type` | すべて |  `file`、`raw`、`git`、`url`のいずれかです。 |
| `target` | すべて | パススルー評価によって書き込まれたデータを含むターゲットファイル。空の場合、ランダムなファイル名が使用されます。 |
| `mode` | すべて | `overwrite`の場合、`target`ファイルは上書きされます。`append`の場合、新しいコンテンツが`target`ファイルに追加されます。`git`型は`overwrite`のみをサポートしています。(デフォルト: `overwrite`) |
| `ref` | `type = "git"` | プルするブランチ、タグ、またはSHAの名前が含まれています |
| `subdir` | `type = "git"` | 設定ソースとしてGitリポジトリのサブディレクトリを選択するために使用されます。 |
| `value` | すべて | `file`、`url`、および`git`型の場合、ファイルまたはGitリポジトリの場所を定義します。`raw`型の場合、インライン設定が含まれます。 |
| `validator` | すべて | パススルーの評価後、ターゲットファイルでバリデーター（`xml`、`yaml`、`json`、`toml`）を明示的に呼び出すために使用されます。 |

#### パススルータイプ {#passthrough-types}

| 型   | 説明 |
| ------ | ----------- |
| `file` | Gitリポジトリに存在するファイルを使用します。 |
| `raw`  | インラインで設定を指定します。 |
| `git`  | リモートGitリポジトリから設定をプルします。 |
| `url`  | HTTPを使用して設定をフェッチします。 |

{{< alert type="warning" >}}

YAMLスニペットで`raw`パススルーを使用する場合、`sast-ruleset.toml`ファイルのすべてのインデントをスペースとしてフォーマットすることをお勧めします。YAML仕様では、タブよりもスペースが優先されることが義務付けられており、インデントがそれに応じて表現されない限り、アナライザーはカスタムルールセットを解析できません。

{{< /alert >}}

## 例 {#examples}

### ファイルパススルーを使用して、GitLab高度なSASTのカスタム設定をビルドする {#build-a-custom-configuration-using-a-file-passthrough-for-gitlab-advanced-sast}

次のカスタムルールセット設定では、GitLab高度なSASTアナライザーの事前定義されたルールセットが、スキャンされるリポジトリ内の`my-gitlab-advanced-sast-rules.yaml`というファイルに含まれるカスタムルールセットに置き換えられます。

```yaml
# my-gitlab-advanced-sast-rules.yaml
---
rules:
- id: my-custom-rule
  pattern: print("Hello World")
  message: |
    Unauthorized use of Hello World.
  severity: ERROR
  languages:
  - python
```

```toml
[gitlab-advanced-sast]
  description = "My custom ruleset for Semgrep"

  [[gitlab-advanced-sast.passthrough]]
    type  = "file"
    value = "my-gitlab-advanced-sast-rules.yaml"
```

### 事前定義されたGitLab高度なSASTルールを無効にする {#disable-predefined-gitlab-advanced-sast-rules}

GitLab高度なSASTルールを無効にしたり、それらのメタデータを編集したりできます。次の例では、さまざまな基準に基づいてルールを無効にします:

- 脆弱性のクラス全体を識別するCWE識別子。
- GitLab高度なSASTルールID。これは、GitLab高度なSASTで使用される特定の検出戦略を識別します。
- 関連付けられたSemgrepルールID。これは、互換性のためにGitLab高度なSASTの検出結果に含まれています。この追加のメタデータを使用すると、両方のアナライザーが同じ場所に同様の検出結果を作成した場合に、検出結果を自動的に移行できます。

これらの識別子は、各脆弱性の[脆弱性の詳細](../vulnerabilities/_index.md)に表示されます。各識別子とその関連付けられた`type`は、[ダウンロード可能なSASTレポートアーティファクト](_index.md#download-a-sast-report)でも確認できます。

```toml
[gitlab-advanced-sast]
  [[gitlab-advanced-sast.ruleset]]
    disable = true
    [gitlab-advanced-sast.ruleset.identifier]
      type = "cwe"
      value = "89"

  [[gitlab-advanced-sast.ruleset]]
    disable = true
    [gitlab-advanced-sast.ruleset.identifier]
      type = "gitlab-advanced-sast_id"
      value = "java-spring-csrf-unrestricted-requestmapping-atomic"

  [[gitlab-advanced-sast.ruleset]]
    disable = true
    [gitlab-advanced-sast.ruleset.identifier]
      type = "semgrep_id"
      value = "java_cookie_rule-CookieHTTPOnly"
```

### 他のSASTアナライザーの事前定義されたルールを無効にする {#disable-predefined-rules-of-other-sast-analyzers}

次のカスタムルールセット設定では、次のルールがレポートから除外されます:

- `semgrep`ルール。値が`gosec.G106-1`の`semgrep_id`、または値が`322`の`cwe`。
- `sobelow`ルール。値が`sql_injection`の`sobelow_rule_id`。
- `flawfinder`ルール。値が`memcpy`の`flawfinder_func_name`。

```toml
[semgrep]
  [[semgrep.ruleset]]
    disable = true
    [semgrep.ruleset.identifier]
      type = "semgrep_id"
      value = "gosec.G106-1"

  [[semgrep.ruleset]]
    disable = true
    [semgrep.ruleset.identifier]
      type = "cwe"
      value = "322"

[sobelow]
  [[sobelow.ruleset]]
    disable = true
    [sobelow.ruleset.identifier]
      type = "sobelow_rule_id"
      value = "sql_injection"

[flawfinder]
  [[flawfinder.ruleset]]
    disable = true
    [flawfinder.ruleset.identifier]
      type = "flawfinder_func_name"
      value = "memcpy"
```

### 事前定義されたルールメタデータをオーバーライドする {#override-predefined-rule-metadata}

次のカスタムルールセット設定では、型が`CWE`、値が`322`の`semgrep`で見つかった脆弱性の重大度が`Critical`にオーバーライドされます。

```toml
[semgrep]
  [[semgrep.ruleset]]
    [semgrep.ruleset.identifier]
      type = "cwe"
      value = "322"
    [semgrep.ruleset.override]
      severity = "Critical"
```

### ファイルパススルーを使用して`semgrep`のカスタム設定をビルドする {#build-a-custom-configuration-using-a-file-passthrough-for-semgrep}

次のカスタムルールセット設定では、`semgrep`アナライザーの事前定義されたルールセットが、スキャンされるリポジトリ内の`my-semgrep-rules.yaml`というファイルに含まれるカスタムルールセットに置き換えられます。

```yaml
# my-semgrep-rules.yml
---
rules:
- id: my-custom-rule
  pattern: print("Hello World")
  message: |
    Unauthorized use of Hello World.
  severity: ERROR
  languages:
  - python
```

```toml
[semgrep]
  description = "My custom ruleset for Semgrep"

  [[semgrep.passthrough]]
    type  = "file"
    value = "my-semgrep-rules.yml"
```

### パススルーチェーンを使用して`semgrep`のカスタム設定をビルドする {#build-a-custom-configuration-using-a-passthrough-chain-for-semgrep}

次のカスタムルールセット設定では、`semgrep`アナライザーの事前定義されたルールセットが、4つのパススルールールセットに置き換えられます。各パススルーコンテナ内の`/sgrules`ディレクトリに書き込まれるファイルを生成します。Gitリポジトリが応答しない場合に備えて、60秒の`timeout`が設定されます。

この例では、さまざまなパススルータイプが示されています:

- 2つの`git`パススルー。1つ目は、`myrules` Gitリポジトリから`develop`ブランチをプルし、2つ目は、`sast-rules`リポジトリからリビジョン`97f7686`をプルし、`go`サブディレクトリ内のファイルのみを考慮します。
  - `sast-rules`エントリは、設定の後半に表示されるため、優先度が高くなります。
  - 2つのチェックアウト間でファイル名の競合がある場合、`sast-rules`リポジトリのファイルは`myrules`リポジトリのファイルを上書きします。
- `raw`パススルーは、`value`を`/sgrules/insecure.yml`に書き込みます。
- `url`パススルー設定をフェッチし、`/sgrules/gosec.yml`に書き込みます。

その後、Semgrepは`/sgrules`にある最終的な設定で呼び出されます。

```toml
[semgrep]
  description = "My custom ruleset for Semgrep"
  targetdir = "/sgrules"
  timeout = 60

  [[semgrep.passthrough]]
    type  = "git"
    value = "https://gitlab.com/user/myrules.git"
    ref = "develop"

  [[semgrep.passthrough]]
    type  = "git"
    value = "https://gitlab.com/gitlab-org/secure/gsoc-sast-vulnerability-rules/playground/sast-rules.git"
    ref = "97f7686db058e2141c0806a477c1e04835c4f395"
    subdir = "go"

  [[semgrep.passthrough]]
    type  = "raw"
    target = "insecure.yml"
    value = """
rules:
- id: "insecure"
  patterns:
    - pattern: "func insecure() {...}"
  message: |
    Insecure function insecure detected
  metadata:
    cwe: "CWE-200: Exposure of Sensitive Information to an Unauthorized Actor"
  severity: "ERROR"
  languages:
    - "go"
"""

  [[semgrep.passthrough]]
    type  = "url"
    value = "https://semgrep.dev/c/p/gosec"
    target = "gosec.yml"
```

### チェーン内のパススルー設定する {#configure-the-mode-for-passthroughs-in-a-chain}

チェーン内のパススルー間で発生するファイル名の競合を処理する方法を選択できます。デフォルトの動作は、同じ名前の既存のファイルを上書きすることですが、代わりに`mode = append`を選択して、後続のファイルの内容を以前のファイルに追加できます。

`append`モードは、`file`、`url`、および`raw`パススルータイプでのみ使用できます。

次のカスタムルールセット設定では、2つの`raw`パススルーを使用して、`/sgrules/my-rules.yml`ファイルを繰り返し組み立てます。これは、ルールセットとしてSemgrepに提供されます。各パススルールールセットに単一のルールを追加します。最初のパススルーは、[Semgrepのルール構文](https://semgrep.dev/docs/writing-rules/rule-syntax)に従って、トップレベルの`rules`オブジェクトを初期化する役割を担います。

```toml
[semgrep]
  description = "My custom ruleset for Semgrep"
  targetdir = "/sgrules"
  validate = true

  [[semgrep.passthrough]]
    type  = "raw"
    target = "my-rules.yml"
    value = """
rules:
- id: "insecure"
  patterns:
    - pattern: "func insecure() {...}"
  message: |
    Insecure function 'insecure' detected
  metadata:
    cwe: "..."
  severity: "ERROR"
  languages:
    - "go"
"""

  [[semgrep.passthrough]]
    type  = "raw"
    mode  = "append"
    target = "my-rules.yml"
    value = """
- id: "secret"
  patterns:
    - pattern-either:
        - pattern: '$MASK = "..."'
    - metavariable-regex:
        metavariable: "$MASK"
        regex: "(password|pass|passwd|pwd|secret|token)"
  message: |
    Use of hard-coded password
  metadata:
    cwe: "..."
  severity: "ERROR"
  languages:
    - "go"
"""
```

```yaml
# /sgrules/my-rules.yml
rules:
- id: "insecure"
  patterns:
    - pattern: "func insecure() {...}"
  message: |
    Insecure function 'insecure' detected
  metadata:
    cwe: "..."
  severity: "ERROR"
  languages:
    - "go"
- id: "secret"
  patterns:
    - pattern-either:
        - pattern: '$MASK = "..."'
    - metavariable-regex:
        metavariable: "$MASK"
        regex: "(password|pass|passwd|pwd|secret|token)"
  message: |
    Use of hard-coded password
  metadata:
    cwe: "..."
  severity: "ERROR"
  languages:
    - "go"
```

### プライベートリモート設定を指定する {#specify-a-private-remote-configuration}

次の例では、[SASTを有効にする](_index.md#configure-sast-in-your-cicd-yaml)、共有ルールセットのカスタマイズファイルを使用します。ファイルは次のとおりです:

- CI変数内に安全に保存されている[グループアクセストークン](../../group/settings/group_access_tokens.md)を使用して、認証を必要とするプライベートプロジェクトからダウンロードされます。
- デフォルトブランチの代わりに特定のGitコミットSHAでチェックアウトされます。

グループアクセストークンに関連付けられたユーザー名の検索方法については、[グループアクセストークン](../../group/settings/group_access_tokens.md#bot-users-for-groups)を参照してください。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SAST_RULESET_GIT_REFERENCE: "group_2504721_bot_7c9311ffb83f2850e794d478ccee36f5:$PERSONAL_ACCESS_TOKEN@gitlab.com/example-group/example-ruleset-project@c8ea7e3ff126987fb4819cc35f2310755511c2ab"
```

### デモプロジェクト {#demo-projects}

これらの設定オプションの一部を示す[デモプロジェクト](https://gitlab.com/gitlab-org/security-products/demos/SAST-analyzer-configurations)があります。

これらのプロジェクトの多くは、リモートルールセットを使用してルールをオーバーライドまたは無効にすることを示しており、それらが対象とするアナライザーによってグループ化されています。

リモートルールセットの設定について説明するビデオデモもいくつかあります:

- [リモートルールセットを備えたIaCアナライザー](https://youtu.be/VzJFyaKpA-8)
