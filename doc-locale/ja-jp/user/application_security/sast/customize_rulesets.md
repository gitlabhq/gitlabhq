---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabでSASTアナライザーのルールを、無効化、オーバーライド、またはデフォルトルールを置き換えることでカスタマイズします。
title: ルールセットをカスタマイズする
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.2で、曖昧なパススルーrefsの指定に対するサポートを[有効化しました](https://gitlab.com/gitlab-org/security-products/analyzers/ruleset/-/merge_requests/18)。

{{< /history >}}

各SASTアナライザーは、ルールセット設定ファイルを通じて異なるレベルのカスタマイズをサポートしています。SemgrepベースのSASTアナライザーと高度なSASTアナライザーには、[デフォルトのルールセット](rules.md)があります。

## ルールセット用語集 {#ruleset-glossary}

ルール: 特定の脆弱性をスキャンする個別のセキュリティチェックまたは検出パターン。

ルールセット: `sast-ruleset.toml`ファイルで定義されている、ルールとその設定のコレクション。

パススルー: パススルーとは、ファイル、Gitリポジトリ、URL、またはインライン設定からルールセットのカスタマイズを取得する設定ソースです。複数のパススルーをチェーンに結合でき、それぞれが以前の設定を上書きするか追加できます。

## ルールのカスタマイズオプション {#rule-customization-options}

SASTルールセットにはデフォルトのルールが含まれていますが、組織ごとにセキュリティ要件が異なります。ルールを無効にしたり、そのメタデータをオーバーライドしたり、ルールを置き換えたり追加したりすることで、これらのルールセットをカスタマイズできます。

下の表は、各アナライザータイプで利用できるカスタマイズオプションを示しています。

| カスタマイズ                          | GitLab高度なSAST                                                                                                                                             | GitLab Semgrep             | [Other analyzers](analyzers.md#official-analyzers) |
|----------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------|----------------------------------------------------|
| デフォルトルールを無効にする               | {{< yes >}}                                                                                                                                                      | {{< yes >}}                | {{< yes >}}                                        |
| デフォルトルールのメタデータをオーバーライドする  | {{< yes >}}                                                                                                                                                      | {{< yes >}}                | {{< yes >}}                                        |
| デフォルトルールを置き換えるか追加する | デフォルトの非汚染構造ルール、およびファイルとrawパススルーの適用動作の変更をサポートします。その他のパススルータイプは無視されます。 | フルパススルーをサポートします。 | {{< no >}}                                         |

> [!note]
> GitLabのサポートスコープは、Semgrepアナライザーのインテグレーションとデフォルトのルールセットに限定されます。デフォルトのルールを置き換えたり追加したりする場合、結果として発生する可能性のある互換性の問題を管理する必要があります。詳細については、[Semgrep analyzer compatibility documentation](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/COMPATIBILITY.md)を参照してください。

### デフォルトルールを無効にする {#disable-default-rules}

任意のSASTアナライザーのデフォルトルールを無効にできます。たとえば、組織のポリシーに基づいて特定のルールを除外することがあります。

以下の例を参照してください:

- [デフォルトの高度なSASTルールを無効にする](#disable-default-gitlab-advanced-sast-rules)
- [その他のSASTアナライザーのデフォルトルールを無効にする](#disable-default-rules-of-other-sast-analyzers)

### デフォルトルールのメタデータをオーバーライドする {#override-metadata-of-default-rules}

任意のSASTアナライザーのデフォルトルールの特定の属性をオーバーライドできます。たとえば、組織のポリシーに基づいて脆弱性の重大度をオーバーライドしたり、脆弱性レポートに表示するメッセージを変更したりできます。

例については、[デフォルトのルールメタデータをオーバーライドする](#override-default-rule-metadata)を参照してください。

### デフォルトルールを置き換えるか追加する {#replace-or-add-to-the-default-rules}

SemgrepベースのSASTアナライザーと高度なSASTアナライザーのデフォルトルールを置き換えたり追加したりできます。デフォルトでは、カスタムルールセットを定義すると、デフォルトのルールセットが置き換えられます。デフォルトルールセットに追加するには、[ルールセット設定ファイル](#configuration-methods)で`keepdefaultrules`を`true`に設定する必要があります。

以下の例を参照してください:

- [高度なSASTのデフォルトルールを置き換える](#replace-the-default-rules-of-gitlab-advanced-sast)
- [`semgrep`のデフォルトルールを置き換えるか追加する](#replace-or-add-to-the-default-rules-of-semgrep)

### ルールセットカスタマイズの影響 {#effects-of-ruleset-customization}

以下の表は、SASTルールセットをカスタマイズしたときに発生することを示しています:

| アクション                     | スキャン動作                                                                                                                                                               | パイプラインセキュリティタブ                                                                                                      | 脆弱性レポート                                                                                                                                   |
|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| ルールを無効にする             | アナライザーは引き続き脆弱性をスキャンしますが、ルールの結果はスキャン完了後に削除されます。高度なSASTは、最初のスキャンから無効なルールを除外するします。 | 無効化される前にそのルールによって検出された検出結果は、次のパイプライン実行後には表示されなくなります。                        | 無効化される前にルールによって検出された脆弱性は、[**検出されませんでした**](../vulnerability_report/_index.md#activity-filter)とマークされます。 |
| メタデータをオーバーライドする          | スキャン動作の変更はありません。                                                                                                                                                 | ルールがオーバーライドされる前に検出された検出結果のメタデータは、次のパイプライン実行後に更新されます。               | ルールがオーバーライドされる前に検出された脆弱性のメタデータが更新されます。                                                                 |
| デフォルトルールセットを置き換える | カスタムルールセットをサポートするアナライザーでは、デフォルトのルールセットは使用されません。                                                                                               | デフォルトルールセットのルールによって、置き換えられる前に検出された検出結果は、次のパイプライン実行後には表示されなくなります。 | デフォルトルールセットのルールによって検出された脆弱性は、[**検出されませんでした**](../vulnerability_report/_index.md#activity-filter)とマークされます。 |

## 設定方法 {#configuration-methods}

ルールセットのカスタマイズは、以下の方法で提供できます:

ローカルルールセットファイル: カスタマイズを`sast-ruleset.toml`ファイルで定義し、リポジトリにコミットします。このアプローチにより、ルールセット設定はバージョン管理下でソースコードとともに管理されます。

リモートルールセットファイル: ルールセットファイルがホストされているリモートの場所（Gitリポジトリ、URL、またはその他のソース）を指定します。このアプローチにより、ルールセットを一元的に管理し、複数のプロジェクトで再利用できます。

> [!note]
> ローカルの`.gitlab/sast-ruleset.toml`ファイルは、リモートルールセットファイルよりも優先されます。

パススルー（ルールセットに結合できる設定ソース）を使用してカスタマイズを提供します。

すべてのルールセットのカスタマイズは、[SASTルールセットスキーマ](#schema)に準拠する必要があります。

### ローカルルールセットファイルを使用する {#use-a-local-ruleset-file}

カスタマイズをソースコードと一緒に保存したい場合は、ローカルルールセットファイルを使用します。ローカルのカスタマイズは個別のプロジェクトにのみ適用されます。

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。

ローカルルールセットファイルを作成するには:

1. まだ存在しない場合は、プロジェクトのルートに`.gitlab`ディレクトリを作成します。
1. `.gitlab`ディレクトリに`sast-ruleset.toml`という名前のファイルを作成します。
1. カスタムルールセットを`sast-ruleset.toml`ファイルに追加します。
1. ローカルルールセットファイルをリポジトリにコミットします。

ローカルルールセットファイルの[例](#examples)を参照してください。

### リモートルールセットファイルを使用する {#use-a-remote-ruleset-file}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393452)されました。

{{< /history >}}

複数のプロジェクトに同じカスタマイズを適用したい場合は、リモートルールセットファイルを使用します。リモートルールセットファイルは、それを使用するプロジェクトのリポジトリの外部に保存されます。

リモートルールセットファイルを使用するには、以下を行います:

- リモートルールセットを作成します。
- 各プロジェクトからリモートルールセットを参照します。

> [!note]
> ローカルの`.gitlab/sast-ruleset.toml`ファイルは、リモートルールセットファイルよりも優先されます。

#### リモートルールセットファイルを作成する {#create-a-remote-ruleset-file}

複数のプロジェクトの中央ルールセットとしてリモートルールセットファイルを作成します。

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。

リモートルールセットを作成するには:

- プロジェクトのリポジトリにルールセットを作成します。

  例となるルールセットファイルについては、[例](#examples)を参照してください。

#### リモートルールセットファイルを参照する {#reference-the-remote-ruleset-file}

プロジェクトにルールを適用するために、リモートルールセットファイルを参照します。

前提条件: 

- プロジェクトのメンテナーまたはオーナーのロール。
- [プロジェクトのリモートルールセット](#create-a-remote-ruleset-file)。
- リモートルールセットが保存されているプロジェクトへの読み取りアクセス権。たとえば、ジョブトークンまたはグループアクセストークンを使用します。

各プロジェクトでリモートルールセットファイルを参照するには、以下を行います:

- リモートルールセットファイルの場所を指定するために、CI/CD変数`SAST_RULESET_GIT_REFERENCE`変数を設定します。

  リモートルールセットファイルの参照は、プロジェクトURI、オプションの認証、およびオプションのGit SHAを指定するために、[Git URL](https://git-scm.com/docs/git-clone#_git_urls)と同様の形式を使用します。変数は以下の形式を使用します:

  ```plaintext
  [<AUTH_USER>[:<AUTH_PASSWORD>]@]<PROJECT_PATH>[@<GIT_SHA>]
  ```

以下の例は、SASTを有効にし、リモートルールセットファイルを使用します。この例では、ファイルは`example-ruleset-project`のデフォルトブランチのパス`.gitlab/sast-ruleset.toml`にコミットされます。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SAST_RULESET_GIT_REFERENCE: "gitlab.com/example-group/example-ruleset-project"
```

高度な例については、[プライベートリモート設定の例を指定する](#specify-a-private-remote-configuration)を参照してください。

#### リモート設定ファイルのトラブルシューティング {#troubleshooting-remote-configuration-files}

リモート設定ファイルがカスタマイズを正しく適用していないように見える場合、原因は以下のとおりです:

1. あなたのリポジトリにはローカルの`.gitlab/sast-ruleset.toml`ファイルがあります。
   - デフォルトでは、リモート設定が変数として設定されていても、ローカルファイルが存在する場合はそれが使用されます。
   - ローカル設定ファイルを無視するには、[SECURE_ENABLE_LOCAL_CONFIGURATION CI/CD変数](../../../ci/variables/_index.md)を`false`に設定します。
1. 認証に問題があります。
   - これが問題の原因であるかどうかを確認するには、認証を必要としないリポジトリの場所から設定ファイルを参照してみてください。

## スキーマ {#schema}

ルールセット設定ファイルはTOML構文を使用します。以下のセクションでは、各設定要素の構造と有効な設定について説明します。

### トップレベルセクション {#top-level-section}

トップレベルセクションには、[TOMLテーブル](https://toml.io/en/v1.0.0#table)として定義された1つ以上の設定セクションが含まれます。

| 設定       | 説明                                                                                                                                            |
|---------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| `[$analyzer]` | アナライザーの設定セクションを宣言します。名前は、[SASTアナライザー](analyzers.md#official-analyzers)のリストで定義されている名前に従います。 |

設定例:

```toml
[semgrep]
...
```

既存のルールを変更する設定セクションを作成したり、カスタムルールセットをビルドしたりすることは避けてください。後者はデフォルトルールを完全に置き換えるためです。

### `[$analyzer]`設定セクション {#analyzer-configuration-section}

`[$analyzer]`セクションでは、アナライザーの動作をカスタマイズできます。有効なプロパティは、作成している設定の種類によって異なります。

| 設定                 | 適用対象    | 説明                                                                                                                                                                                                                                                                                                   |
|-------------------------|---------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `[[$analyzer.ruleset]]` | デフォルトルール | 既存のルールへの変更を定義します。                                                                                                                                                                                                                                                                    |
| `interpolate`           | すべて           | `true`に設定すると、設定内で`$VAR`を使用して環境変数を評価できます。シークレットやトークンが漏洩しないように、この機能は注意して使用してください。（デフォルト: `false`）                                                                                                                           |
| `description`           | パススルー  | カスタムルールセットの説明。                                                                                                                                                                                                                                                                            |
| `targetdir`             | パススルー  | 最終的な設定が永続化されるディレクトリ。空の場合、ランダムな名前のディレクトリが作成されます。ディレクトリには最大100 MBのファイルを含めることができます。SASTジョブが非ルートユーザー権限で実行されている場合は、ユーザーがこのディレクトリに対する読み取りおよび書き込み権限を持っていることを確認してください。 |
| `validate`              | パススルー  | `true`に設定すると、各パススルーのコンテンツが検証されます。検証は、`yaml`、`xml`、`json`、および`toml`コンテンツに対して機能します。適切なバリデーターは、`[[$analyzer.passthrough]]`セクションの`target`パラメータで使用されている拡張子に基づいて識別されます。（デフォルト: `false`）                    |
| `timeout`               | パススルー  | パススルーチェーンを評価するために費やされる最大時間で、タイムアウトする前の時間です。タイムアウトは300秒を超えることはできません。（デフォルト: 60）                                                                                                                                                                          |
| `keepdefaultrules`      | パススルー  | `true`に設定すると、アナライザーのデフォルトルールが、定義されたパススルーと連携して有効になります。（デフォルト: `false`）                                                                                                                                                                                 |

#### `interpolate` {#interpolate}

> [!warning]
> シークレットの漏洩リスクを軽減するため、この機能は注意して使用してください。

以下の例は、`$GITURL`環境変数を使用してプライベートリポジトリにアクセスする設定を示しています。この変数にはユーザー名とトークン（例: `https://user:token@url`）が含まれているため、それらは設定ファイルに明示的に保存されません。

```toml
[semgrep]
  description = "My private Semgrep ruleset"
  interpolate = true

  [[semgrep.passthrough]]
    type  = "git"
    value = "$GITURL"
    ref = "main"
```

### `[[$analyzer.ruleset]]`セクション {#analyzerruleset-section}

`[[$analyzer.ruleset]]`セクションは、単一のデフォルトルールを対象とし、変更します。アナライザーごとに最大20個のこれらのセクションを定義できます。

| 設定                          | 説明                                             |
|----------------------------------|---------------------------------------------------------|
| `disable`                        | ルールを無効にするかどうか。（デフォルト: `false`） |
| `[$analyzer.ruleset.identifier]` | 変更するデフォルトルールを選択します。                |
| `[$analyzer.ruleset.override]`   | ルールに対するオーバーライドを定義します。                     |

設定例:

```toml
[semgrep]
  [[semgrep.ruleset]]
    disable = true
    ...
```

### `[$analyzer.ruleset.identifier]`セクション {#analyzerrulesetidentifier-section}

`[$analyzer.ruleset.identifier]`セクションは、変更したいデフォルトルールの識別子を定義します。

| 設定 | 説明                                           |
|---------|-------------------------------------------------------|
| `type`  | デフォルトルールで使用される識別子のタイプ。      |
| `value` | デフォルトルールで使用される識別子の値。 |

`type`と`value`の正しい値は、アナライザーによって生成される[`gl-sast-report.json`](_index.md#download-a-sast-report)を見ることで調べることができます。このファイルは、アナライザーのCIジョブからジョブアーティファクトとしてダウンロードできます。

たとえば、以下のスニペットは、3つの識別子を持つ`semgrep`ルールからの検出結果を示しています。JSONオブジェクト内の`type`と`value`キーは、このセクションで指定すべき値に対応しています。

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

### `[$analyzer.ruleset.override]`セクション {#analyzerrulesetoverride-section}

`[$analyzer.ruleset.override]`セクションでは、デフォルトルールの属性をオーバーライドできます。

| 設定       | 説明                                                                                         |
|---------------|-----------------------------------------------------------------------------------------------------|
| `description` | 問題の詳細な説明。                                                                |
| `message`     | （非推奨）問題の説明。                                                            |
| `name`        | ルールの名前。                                                                               |
| `severity`    | ルールの重大度。有効なオプションは次のとおりです: `Critical`、`High`、`Medium`、`Low`、`Unknown`、`Info` |

> [!note]
> `message`はアナライザーによって入力されたものですが、`name`と`description`の使用が推奨されるため、[非推奨](https://gitlab.com/gitlab-org/security-products/analyzers/report/-/blob/1d86d5f2e61dc38c775fb0490ee27a45eee4b8b3/vulnerability.go#L22)となりました。

設定例:

```toml
[semgrep]
  [[semgrep.ruleset]]
    [semgrep.ruleset.override]
      severity = "Critical"
      name = "Command injection"
    ...
```

### `[[$analyzer.passthrough]]`セクション {#analyzerpassthrough-section}

> [!note]
> パススルー設定は、[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)でのみ利用可能です。

`[[$analyzer.passthrough]]`セクションでは、アナライザー用のカスタム設定をビルドできます。アナライザーごとに最大20個のこれらのセクションを定義できます。パススルーは、アナライザーのデフォルトルールを置き換える完全な設定に評価される_パススルーチェーン_に構成されます。

パススルーは順序どおりに評価されます。チェーンで後からリストされるパススルーは、優先順位が高く、以前のパススルーによって生成されたデータを上書きするか追加できます（`mode`によって異なります）。これは、既存の設定を使用または変更する必要がある場合に便利です。

単一のパススルーによって生成される設定のサイズは10 MBに制限されます。

| 設定     | 適用対象     | 説明                                                                                                                                                                   |
|-------------|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type`      | すべて            | `file`、`raw`、`git`、`url`のいずれかです。                                                                                                                                         |
| `target`    | すべて            | パススルー評価によって書き込まれるデータを含むターゲットファイル。空の場合、ランダムなファイル名が使用されます。                                                               |
| `mode`      | すべて            | `overwrite`の場合、`target`ファイルは上書きするされます。`append`の場合、新しいコンテンツが`target`ファイルに追加されます。`git`タイプは`overwrite`のみをサポートします。（デフォルト: `overwrite`） |
| `ref`       | `type = "git"` | ブランチ、タグ、またはプルするSHAの名前を含みます。                                                                                                                      |
| `subdir`    | `type = "git"` | Gitリポジトリのサブディレクトリを設定ソースとして選択するために使用されます。                                                                                              |
| `value`     | すべて            | `file`、`url`、および`git`タイプの場合、ファイルまたはGitリポジトリの場所を定義します。`raw`タイプの場合、インライン設定が含まれます。                            |
| `validator` | すべて            | パススルーの評価後、ターゲットファイルでバリデーター（`xml`、`yaml`、`json`、`toml`）を明示的に実行するために使用されます。                                                |

#### パススルータイプ {#passthrough-types}

| 種類   | 説明                                          |
|--------|------------------------------------------------------|
| `file` | Gitリポジトリに存在するファイルを使用します。    |
| `raw`  | 設定をインラインで提供します。                    |
| `git`  | リモートGitリポジトリから設定をプルします。 |
| `url`  | HTTPを使用して設定をフェッチします。                  |

> [!warning] 
> 
> `raw`パススルーをYAMLスニペットで使用する場合、`sast-ruleset.toml`ファイル内のすべてのインデントをスペースとしてフォーマットすることをお勧めします。YAMLの仕様では、タブではなくスペースが義務付けられており、インデントが適切に表現されていない限り、アナライザーはカスタムルールセットの解析に失敗します。

## 例 {#examples}

以下の例は、一般的なシナリオでのルールセットのカスタマイズ方法を示しています。各例で使用されている設定オプションを理解するには、スキーマセクションを使用してください。

### 高度なSASTのデフォルトルールを置き換える {#replace-the-default-rules-of-gitlab-advanced-sast}

以下のカスタムルールセット設定により、高度なSASTアナライザーのデフォルトルールセットは、スキャン対象のリポジトリ内の`my-gitlab-advanced-sast-rules.yaml`という名前のファイルに含まれるカスタムルールセットに置き換えられます。

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

### デフォルトの高度なSASTルールを無効にする {#disable-default-gitlab-advanced-sast-rules}

高度なSASTルールを無効にするか、そのメタデータを編集できます。以下の例は、異なる基準に基づいてルールを無効にします:

- 脆弱性のクラス全体を識別子するCWE識別子。
- 高度なSASTで使用される特定の検出戦略を識別子する高度なSASTルールID。
- 互換性のために高度なSASTの検出結果に含まれる、関連するSemgrepルールID。この追加メタデータにより、両方のアナライザーが同じ場所で類似の検出結果を作成した場合に、検出結果を自動的に移行できます。

これらの識別子は、各脆弱性の[脆弱性](../vulnerabilities/_index.md)の詳細に表示されます。また、各識別子とその関連する`type`を[ダウンロード可能なSASTレポートアーティファクト](_index.md#download-a-sast-report)で確認できます。

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

### その他のSASTアナライザーのデフォルトルールを無効にする {#disable-default-rules-of-other-sast-analyzers}

以下のカスタムルールセット設定により、以下のルールはレポートから省略されます:

- `gosec.G106-1`の`semgrep_id`または`322`の`cwe`を持つ`semgrep`ルール。
- `sql_injection`の`sobelow_rule_id`を持つ`sobelow`ルール。
- `memcpy`の`flawfinder_func_name`を持つ`flawfinder`ルール。

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

### デフォルトルールのメタデータをオーバーライドする {#override-default-rule-metadata}

以下のカスタムルールセット設定により、`semgrep`で検出されたタイプ`CWE`、値`322`の脆弱性の重大度は`Critical`にオーバーライドされます。

```toml
[semgrep]
  [[semgrep.ruleset]]
    [semgrep.ruleset.identifier]
      type = "cwe"
      value = "322"
    [semgrep.ruleset.override]
      severity = "Critical"
```

### `semgrep`のデフォルトルールを置き換えるか追加する {#replace-or-add-to-the-default-rules-of-semgrep}

以下のカスタムルールセット設定により、`semgrep`アナライザーのデフォルトルールセットは、スキャン対象のリポジトリ内の`my-semgrep-rules.yaml`という名前のファイルに含まれるカスタムルールセットに置き換えられます。

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

### `semgrep`用のパススルーチェーンを使用したカスタム設定をビルドする {#build-a-custom-configuration-using-a-passthrough-chain-for-semgrep}

以下のカスタムルールセット設定により、`semgrep`アナライザーのデフォルトルールセットは、4つのパススルーのチェーンを評価することによって生成されたカスタムルールセットに置き換えられます。各パススルーは、コンテナ内の`/sgrules`ディレクトリに書き込まれるファイルを生成します。Gitリモートが応答しない場合に備えて、60秒の`timeout`が設定されます。

この例では、異なるパススルータイプが示されています:

- 2つの`git`パススルーで、1つ目は`myrules`Gitリポジトリから`develop`ブランチをプルし、2つ目は`sast-rules`リポジトリからリビジョン`97f7686`をプルし、`go`サブディレクトリ内のファイルのみを考慮します。
  - `sast-rules`エントリは、設定の後の方に表示されるため、優先順位が高くなります。
  - 2つのチェックアウト間でファイル名が衝突する場合、`sast-rules`リポジトリのファイルが`myrules`リポジトリのファイルを上書きするします。
- `raw`パススルーは、その`value`を`/sgrules/insecure.yml`に書き込みます。
- `url`パススルーは、URLでホストされている設定をフェッチし、`/sgrules/gosec.yml`に書き込みます。

その後、`/sgrules`の下にある最終的な設定でSemgrepが実行するされます。

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

### チェーン内のパススルーのモードを設定する {#configure-the-mode-for-passthroughs-in-a-chain}

チェーン内のパススルー間で発生するファイル名の競合をどのように処理するかを選択できます。デフォルトの動作は、既存の同じ名前のファイルを上書きすることですが、代わりに`mode = append`を選択して、後のファイルのコンテンツを以前のファイルに追加することもできます。

`append`モードは、`file`、`url`、および`raw`パススルータイプでのみ使用できます。

以下のカスタムルールセット設定では、2つの`raw`パススルーが`/sgrules/my-rules.yml`ファイルを繰り返し組み立てるために使用され、そのファイルがSemgrepにルールセットとして提供されます。各パススルーは、単一のルールをルールセットに追加します。最初のパススルーは、[Semgrepルール構文](https://semgrep.dev/docs/writing-rules/rule-syntax)に従って、トップレベルの`rules`オブジェクトを初期化する役割を担います。

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

以下の例は、SASTを有効にし、共有ルールセットカスタマイズファイルを使用します:

- このファイルは、認証を必要とするプライベートプロジェクトからダウンロードされます。この例では、CI/CD変数に安全に保存されている[グループアクセストークン](../../group/settings/group_access_tokens.md)を使用します。
- このファイルは、デフォルトブランチではなく、特定のGitコミットSHAでチェックアウトされます。

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  SAST_RULESET_GIT_REFERENCE: "oauth2:$GROUP_ACCESS_TOKEN@gitlab.com/example-group/example-ruleset-project@c8ea7e3ff126987fb4819cc35f2310755511c2ab"
```

### デモンストレーションプロジェクト {#demonstration-projects}

これらのいくつかの設定オプションを示す[デモンストレーションプロジェクト](https://gitlab.com/gitlab-org/security-products/demos/SAST-analyzer-configurations)を参照してください。

これらのプロジェクトの多くは、リモートルールセットを使用してルールをオーバーライドまたは無効にする方法を示しており、対象となるアナライザーごとにグループ化されています。

リモートルールセットの設定に関するビデオデモンストレーションも視聴できます:

- [リモートルールセットを使用したIaCアナライザー](https://youtu.be/VzJFyaKpA-8)
