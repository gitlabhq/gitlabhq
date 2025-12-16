---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: カスタムルールセットスキーマ
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

パイプラインシークレット検出の動作をカスタマイズするには、[さまざまな種類のルールセットのカスタマイズ](configure.md#customize-analyzer-rulesets)を使用できます。

## スキーマ {#schema}

パイプラインシークレット検出ルールセットのカスタマイズは、厳密なスキーマに準拠する必要があります。以下のセクションでは、利用可能な各オプションと、そのセクションに適用されるスキーマについて説明します。

### トップレベルのセクション {#the-top-level-section}

トップレベルのセクションには、1つ以上の設定セクションが含まれており、[TOMLテーブル](https://toml.io/en/v1.0.0#table)として定義されています。

| 設定     | 説明                                        |
|-------------|----------------------------------------------------|
| `[secrets]` | アナライザーの設定セクションを宣言します。 |

設定例:

```toml
[secrets]
...
```

### `[secrets]`設定セクション {#the-secrets-configuration-section}

`[secrets]`セクションでは、アナライザーの動作をカスタマイズできます。有効なプロパティは、作成する設定の種類によって異なります。

| 設定               | 適用対象       | 説明                                                                                                                                                                                                                                                                              |
|-----------------------|------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `[[secrets.ruleset]]` | 定義済みのルール | 既存のルールに対する変更を定義します。                                                                                                                                                                                                                                               |
| `interpolate`         | すべて              | `true`に設定すると、設定で`$VAR`を使用して環境変数を評価できます。シークレットまたはトークンが流出しないように、この機能の使用には注意してください。（`false`デフォルト）                                                                                                      |
| `description`         | パススルー     | カスタムルールセットの説明。                                                                                                                                                                                                                                                       |
| `targetdir`           | パススルー     | 最終的な設定が永続化されるディレクトリ。空の場合、ランダムな名前のディレクトリが作成されます。ディレクトリには、最大100 MBのファイルを格納できます。                                                                                                                   |
| `validate`            | パススルー     | `true`に設定すると、各パススルーのコンテンツが検証されます。`yaml`、`xml`、`json`、および`toml`コンテンツの検証が機能します。適切な検証ツールは、`[[secrets.passthrough]]`セクションの`target`パラメータで使用されている拡張子に基づいて識別されます。（`false`デフォルト） |
| `timeout`             | パススルー     | タイムアウトする前に、パススルーチェーンの評価に費やす最大時間。タイムアウトは300秒を超えることはできません。（デフォルト: 60）                                                                                                                                                     |

#### `interpolate` {#interpolate}

{{< alert type="warning" >}}

シークレットが流出するリスクを軽減するために、この機能の使用には注意してください。

{{< /alert >}}

以下の例は、`$GITURL`環境変数を使用してプライベートリポジトリにアクセスする設定を示しています。この変数には、ユーザー名とトークン（例: `https://user:token@url`）が含まれているため、設定ファイルに明示的に保存されることはありません。

```toml
[secrets]
  description = "My private remote ruleset"
  interpolate = true

  [[secrets.passthrough]]
    type  = "git"
    value = "$GITURL"
    ref = "main"
```

### `[[secrets.ruleset]]`セクション {#the-secretsruleset-section}

`[[secrets.ruleset]]`セクションは、単一の定義済みルールを対象とし、変更します。アナライザーに対して、これらのセクションを1つ以上定義できます。

| 設定                        | 説明                                             |
|--------------------------------|---------------------------------------------------------|
| `disable`                      | ルールを無効にするかどうか。デフォルト: `false` |
| `[secrets.ruleset.identifier]` | 変更する定義済みのルールを選択します。             |
| `[secrets.ruleset.override]`   | ルールのオーバーライドを定義します。                     |

設定例:

```toml
[secrets]
  [[secrets.ruleset]]
    disable = true
    ...
```

### `[secrets.ruleset.identifier]`セクション {#the-secretsrulesetidentifier-section}

`[secrets.ruleset.identifier]`セクションは、変更する定義済みルールの識別子を定義します。

| 設定 | 説明 |
| --------| ----------- |
| `type`  | 定義済みのルールで使用される識別子のタイプ。 |
| `value` | 定義済みのルールで使用される識別子の値。 |

`type`と`value`の正しい値を判断するには、アナライザーによって生成された[`gl-secret-detection-report.json`](_index.md#secret-detection-results)を表示します。このファイルは、アナライザーのCI/CDジョブからジョブアーティファクトとしてダウンロードできます。

たとえば、以下のスニペットは、1つの識別子を持つ`gitlab_personal_access_token`ルールからの検出結果を示しています。JSONオブジェクトの`type`と`value`キーは、このセクションで指定する必要がある値に対応しています。

```json
...
  "vulnerabilities": [
    {
      "id": "fccb407005c0fb58ad6cfcae01bea86093953ed1ae9f9623ecc3e4117675c91a",
      "category": "secret_detection",
      "name": "GitLab personal access token",
      "description": "GitLab personal access token has been found in commit 5c124166",
      ...
      "identifiers": [
        {
          "type": "gitleaks_rule_id",
          "name": "Gitleaks rule ID gitlab_personal_access_token",
          "value": "gitlab_personal_access_token"
        }
      ]
    }
    ...
  ]
...
```

設定例:

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.identifier]
      type = "gitleaks_rule_id"
      value = "gitlab_personal_access_token"
    ...
```

### `[secrets.ruleset.override]`セクション {#the-secretsrulesetoverride-section}

`[secrets.ruleset.override]`セクションでは、定義済みのルールの属性をオーバーライドできます。

| 設定       | 説明                                                                                         |
|---------------|-----------------------------------------------------------------------------------------------------|
| `description` | 問題の詳細な説明。                                                                |
| `message`     | （非推奨）問題の説明。                                                            |
| `name`        | ルールの名前。                                                                               |
| `severity`    | ルールの重大度。有効なオプションは、`Critical`、`High`、`Medium`、`Low`、`Unknown`、`Info`です。 |

{{< alert type="note" >}}

`message`はGitLabアナライザーによって入力された状態ですが、[deprecated](https://gitlab.com/gitlab-org/security-products/analyzers/report/-/blob/1d86d5f2e61dc38c775fb0490ee27a45eee4b8b3/vulnerability.go#L22)になり、`name`と`description`に置き換えられました。

{{< /alert >}}

設定例:

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.override]
      severity = "Medium"
      name = "systemd machine-id"
    ...
```

### カスタムルール形式 {#custom-rule-format}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/511321)されました。

{{< /history >}}

カスタムルールを作成する場合、[Gitleaksの標準ルール形式](https://github.com/gitleaks/gitleaks?tab=readme-ov-file#configuration)と、GitLab固有の追加フィールドの両方を使用できます。各ルールで使用できる設定を以下に示します:

| 設定 | 必須 | 説明 |
|---------|-------------|-------------|
| `title` | いいえ | ルールにカスタムタイトルを設定するGitLab固有のフィールド。 |
| `description` | はい | ルールが検出するものの詳細な説明。 |
| `remediation` | いいえ | ルールがトリガーされたときに修正ガイダンスを提供するGitLab固有のフィールド。 |
| `regex` | はい | シークレットの検出に使用される正規表現パターン。 |
| `keywords` | いいえ | 正規表現を適用する前にコンテンツを事前にフィルタリングするためのキーワードのリスト。 |
| `id` | はい |  ルールの一意な識別子。 |

使用可能なすべてのフィールドを含むカスタムルールの例:

```toml
[[rules]]
  title = "API Key Detection Rule"
  description = "Detects potential API keys in the codebase"
  remediation = "Rotate the exposed API key and store it in a secure credential manager"
  id = "custom_api_key"
  keywords = ["apikey", "api_key"]
  regex = '''api[_-]key[_-][a-zA-Z0-9]{16,}'''
```

拡張ルールセット内のルールと同じIDを共有するカスタムルールを作成すると、カスタムルールが優先されます。カスタムルールのすべてのプロパティが、拡張ルールから対応する値を置き換えます。

カスタムルールを使用したデフォルトルールの拡張例:

```toml
title = "Extension of GitLab's default Gitleaks config"

[extend]
  path = "/gitleaks.toml"

[[rules]]
  title = "Custom API Key Rule"
  description = "Detects custom API key format"
  remediation = "Rotate the exposed API key"
  id = "custom_api_123"
  keywords = ["testing"]
  regex = '''testing-key-[1-9]{3}'''
```

### `[[secrets.passthrough]]`セクション {#the-secretspassthrough-section}

`[[secrets.passthrough]]`セクションでは、アナライザーのカスタム設定を合成できます。

このセクションは、アナライザーごとに最大20個まで定義できます。次に、パススルーは、アナライザーの定義済みルールを置き換えるか、または拡張するために使用できる完全な設定に評価されるパススルーチェーンに構成されます。

パススルーは順番に評価されます。チェーンで後からリストされるパススルーは、優先順位が高く、（`mode`に応じて）以前のパススルーによって生成されたデータを上書きまたは追加できます。既存の設定を使用または変更する必要がある場合は、パススルーを使用します。

単一のパススルーによって生成される設定のサイズは、10 MBに制限されています。

| 設定     | 適用対象     | 説明                                                                                                                                                                   |
|-------------|----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `type`      | すべて            | `file`、`raw`、`git`、`url`のいずれかです。                                                                                                                                        |
| `target`    | すべて            | パススルー評価によって書き込まれたデータを格納するターゲットファイル。空の場合、ランダムなファイル名が使用されます。                                                               |
| `mode`      | すべて            | `overwrite`の場合、`target`ファイルは上書きされます。`append`の場合、新しいコンテンツは`target`ファイルに追加されます。`git`タイプは`overwrite`のみをサポートします。デフォルト: `overwrite` |
| `ref`       | `type = "git"` | プルするブランチ、タグ、またはSHAの名前が含まれています。                                                                                                                     |
| `subdir`    | `type = "git"` | 設定ソースとしてGitリポジトリのサブディレクトリを選択するために使用されます。                                                                                              |
| `auth`      | `type = "git"` | [プライベートGitリポジトリに格納されている設定](configure.md#with-a-private-remote-ruleset)を使用する場合に使用する認証情報を提供するために使用されます。                       |
| `value`     | すべて            | `file`、`url`、および`git`タイプの場合、ファイルまたはGitリポジトリの場所を定義します。`raw`タイプの場合、インライン設定が含まれます。                            |
| `validator` | すべて            | パススルーの評価後、ターゲットファイルで検証ツール（`xml`、`yaml`、`json`、`toml`）を明示的に実行するために使用されます。                                                |

#### パススルーのタイプ {#passthrough-types}

| 型   | 説明                                           |
|--------|-------------------------------------------------------|
| `file` | 同じGitリポジトリに保存されているファイルを使用します。 |
| `raw`  | ルールセットの設定をインラインで提供します。             |
| `git`  | リモートGitリポジトリから設定をプルします。  |
| `url`  | HTTPを使用して設定をフェッチします。                   |
