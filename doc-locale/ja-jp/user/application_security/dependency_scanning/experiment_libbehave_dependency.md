---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 動作の依存関係を分析
description: Libbehaveは、マージリクエストで追加された新しい依存関係を危険な動作についてスキャンし、各動作にリスクスコアを割り当てます。結果は、ジョブの出力、マージリクエストコメント、およびジョブのアーティファクトに表示されます。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

Libbehaveは試験的な機能で、マージリクエストパイプライン中に依存関係をスキャンして、新たに追加されたライブラリと、潜在的に危険な動作を特定します。従来の依存関係スキャンが既知の脆弱性を検索するのに対し、Libbehaveは依存関係が示す機能と動作に関するインサイトを提供します。

Libbehaveによって検出された各機能には、次のいずれかの「リスクの高さ」スコアが割り当てられます:

- 情報: リスクはありませんが、依存関係の機能をカタログ化するのに役立つ場合があります（JSONの使用など）。
- 低: 小規模なリスク。暗号化の使用など、依存関係がセキュリティに敏感なアクションを実行していることを強調表示できます。
- 中: 中程度のレベルのリスク。ファイルシステムとの対話、または機密データが保存またはアクセスされる可能性のある環境変数の読み取りに使用できます。
- 高: 最高レベルのリスク。これらの動作は、OSコマンドの実行や動的なコードの評価など、セキュリティの脆弱性で一般的に悪用されます。

Libbehaveが検出する機能には、以下が含まれます:

- OSコマンドの実行
- 動的コードの実行（eval）
- ファイルの読み取り/書き込み
- ネットワークソケットのオープン
- アーカイブの読み取り/展開（ZIP/tar/Gzip）
- HTTPクライアント、Redis、Elastic Cache、リレーショナル管理データベース（RMDB）サーバー、SSH、Gitを使用した外部サービスとの対話
- さまざまな形式でのデータのシリアル化: XML、YAML、MessagePack、Protocol Buffers、JSON、および言語固有の形式
- テンプレート
- 一般的なフレームワーク
- ファイルのアップロード/ダウンロード

サポートされている各パッケージマネージャータイプのLibbehaveのデモについては、[Libbehaveのデモプロジェクト](https://gitlab.com/gitlab-org/security-products/demos/experiments/libbehave)をご覧ください。

## サポートされている言語とパッケージマネージャー {#supported-languages-and-package-managers}

Libbehaveでは、次の言語とパッケージマネージャーがサポートされています:

- C#（[NuGet](https://www.nuget.org/)）
  - `Directory.Build.props`ファイルを読み取ります（プロパティ値が見つかった場合は置き換えます）
  - `*.deps.json`ファイルを読み取ります
  - `**/*.dll`および`**/*.exe`ファイルを読み取ります
- Go
  - `go.mod`ファイルを読み取ります
- Java（[Maven](https://maven.org)）
  - `pom.xml`ファイルを読み取ります（プロパティ値が見つかった場合は置き換えます）
  - `**/gradle.lockfile*`ファイルを読み取ります
- JavaScript/TypeScript ([npmjs](https://npmjs.com))
  - `**/package-lock.json`ファイルを読み取ります
  - `**/yarn.lock`ファイルを読み取ります
  - `**/pnpm-lock.yaml`ファイルを読み取ります
- Python（[PyPi](https://pypi.org)）
  - `**/*requirements*.txt`ファイルを読み取ります
  - `**/poetry.lock`ファイルを読み取ります
  - `**/Pipfile.lock`ファイルを読み取ります
  - `**/setup.py`ファイルを読み取ります
  - eggまたはwheelインストールディレクトリ内のパッケージを読み取ります:
    - `**/*dist-info/METADATA`、`**/*egg-info/PKG-INFO`、`**/*DIST-INFO/METADATA`、および`**/*EGG-INFO/PKG-INFO`ファイルを読み取ります
- PHP（[Composer/Packagist](https://packagist.org/)）
  - `**/installed.json`ファイルを読み取ります
  - `**/composer.lock`ファイルを読み取ります
  - `**/php/.registry/.channel.*/*.reg"`ファイルを読み取ります
- Ruby（[Rubygems](https://rubygems.org)）
  - `**/Gemfile.lock`ファイルを読み取ります
  - `**/specifications/**/*.gemspec`ファイルを読み取ります
  - `**/*.gemspec`ファイルを読み取ります

上記のファイルは、ファイルがソースブランチで変更された場合にのみ、新しい依存関係について分析されます。

## 設定 {#configuration}

前提要件: 

- パイプラインは、定義されたソースブランチとターゲットブランチを持つアクティブな[マージリクエストパイプライン](../../../ci/pipelines/merge_request_pipelines.md)の一部です。
- プロジェクトには、[サポートされている言語](#supported-languages-and-package-managers)のいずれかが含まれています。
- プロジェクトは、新しい依存関係をソースブランチまたはフィーチャーブランチに追加しています。
- マージリクエスト（MR）コメントの場合、ゲストレベルの[プロジェクトアクセストークン](../../project/settings/project_access_tokens.md)、およびソースブランチが保護ブランチであるか、**変数の保護** CI/CD変数の[オプションがオフになっている](../../../ci/variables/_index.md#for-a-project)ことを確認してください。

Libbehaveは[CI/CDコンポーネント](../../../ci/components/_index.md)を介して公開されます。有効にするには、プロジェクトの`.gitlab-ci.yml`ファイルを次のように設定します:

```yaml
include:
  - component: $CI_SERVER_FQDN/security-products/experiments/libbehave/libbehave@v0.1.0
    inputs:
      stage: test
```

上記の設定により、テストステージングのLibbehave CIコンポーネントが有効になります。これにより、`libbehave-experiment`という名前の新しいジョブが作成されます。

### MRコメントの設定 {#configuring-mr-comments}

LibbehaveのMRコメントを設定するには:

1. 次の属性を持つ[プロジェクトアクセストークン](../../project/settings/project_access_tokens.md)を作成します:
   - ゲストレベルのアクセス
     - トークンの名前を入力します（例：`libbehave-bot`）。
     - `api`スコープを選択します。

   プロジェクトアクセストークンをクリップボードにコピーします。これは次のステップで必要になります。
1. [プロジェクトCI/CD変数](../../../ci/variables/_index.md)としてトークンを追加します:
   - **表示レベル**を「マスク」に設定します。
   - 保護ブランチ以外のブランチからのアクセスを許可するには、**フラグ**の「変数の保護」オプションをオフにします。
   - キーの変数名を`BEHAVE_TOKEN`に設定します。
   - 値を、新しく作成したプロジェクトアクセストークンに設定します。
1. CI/CDコンポーネントは自動的に`BEHAVE_TOKEN`を使用するため、コンポーネント入力で指定する必要はありません。

```yaml
include:
  - component: gitlab.com/security-products/experiments/libbehave/libbehave@v0.1.0
    inputs:
      stage: test
```

この設定により、Libbehaveは分析結果を含むMRコメントを作成できます。

### 利用可能なCI/CDの入力と変数 {#available-cicd-inputs-and-variables}

CI/CD変数を使用して、Libbehaveの[CIコンポーネント](https://gitlab.com/security-products/experiments/libbehave)をカスタマイズできます。

次の変数は、Libbehaveの実行方法の動作を設定します。

| CI/CD変数                        | CLI引数 | デフォルト | 説明                                                          |
|---------------------------------------|--------------|---------|----------------------------------------------------------------------|
| `CI_MERGE_REQUEST_SOURCE_BRANCH_NAME` | `-source`    | `""`    | 差分を比較するソースブランチ（例：フィーチャーブランチ）          |
| `CI_MERGE_REQUEST_TARGET_BRANCH_NAME` | `-target`    | `""`    | 差分を比較するターゲットブランチ（例：main）                    |
| `BEHAVE_TIMEOUT`                      | `-timeout`   | `"30m"` | パッケージの分析とダウンロードに許可される最大時間（例: 30m) |
| `BEHAVE_TOKEN`                        | `-token`     | `""`    | オプション。アクセストークン（MRコメントを作成するために必要）            |
| `CI_PROJECT_ID`                       | `-project`   | `""`    | オプション。結果を含むMRノートを作成するためのプロジェクトID                  |
| `CI_MERGE_REQUEST_IID`                | `-mrid`      | `""`    | オプション。結果を含むMRノートを作成するためのマージリクエストID            |

次のフラグを使用できますが、テストされていないため、デフォルト値のままにする必要があります:

| CI/CD変数         | CLI引数     | デフォルト       | 説明                 |
|------------------------|------------------|---------------|-----------------------------|
| `BEHAVE_RULE_PATHS`    | `-rules`         | `"/dist"`     | ルールファイルへのパス。 |
| `BEHAVE_TARGET_DIR`    | `-dir`           | `""`          | behaveを実行するターゲットディレクトリ。 |
| `BEHAVE_NO_GIT_IGNORE` | `-no-git-ignore` | `true`        | `.gitignore`内のファイルをスキャンするかどうか。引数を指定するとスキャンされません。デフォルトではスキャンされます。 |
| `BEHAVE_OUTPUT_PATH`   | `-output`        | `"behaveout"` | スキャン結果、抽出されたアーティファクト、レポート結果を格納するパス。 |
| `BEHAVE_INCLUDE_LANG`  | `-include-lang`  | `""`          | 言語を含めます。 `csharp`、`go`、`java`、`js`、`php`、`python`、または`ruby`のいずれか1つを「,」で区切ると、指定されていないその他すべてが除外されます。 |
| `BEHAVE_EXCLUDE_LANG`  | `-exclude-lang`  | `""`          | 言語を除外します。 `csharp`、`go`、`java`、`js`、`php`、`python`、または`ruby`のいずれか1つを「,」で区切ると、指定されていないその他すべてが含まれます。 |
| `BEHAVE_EXCLUDE_FILES` | `-exclude-`      | `""`          | ファイルまたはパスを正規表現で除外します。個々の正規表現は「,」で区切られます。 |

すべての変数をテストしたわけではないため、機能するものもあれば、機能しないものもあります。必要な変数が機能しない場合は、[機能リクエストを送信する](https://gitlab.com/gitlab-org/gitlab/-/issues/new?issuable_template=Feature%20proposal%20-%20detailed&issue[title]=Docs%20feedback%20-%20feature%20proposal:%20Write%20your%20title)か、コードにコントリビュートしてその機能を使用できるようにすることをおすすめします。

## 依存関係の検出と分析 {#dependency-detection-and-analysis}

Libbehaveは、新しく追加されたすべての依存関係に関する調査結果を分析してレポートし、[マージリクエストパイプライン](../../../ci/pipelines/merge_request_pipelines.md)で実行することを目的としています。つまり、マージリクエストに新しい依存関係が含まれていない場合、Libbehaveは結果を返しません。

検出の仕組みは、使用する言語とパッケージマネージャーによって異なります。デフォルトでは、これらのサポートされているパッケージマネージャーは、パッケージマネージャー関連ファイルを解析して、どの依存関係が追加されているかを特定します。この情報は収集され、特定されたパッケージのアーティファクトをダウンロードするために、それぞれのパッケージマネージャーAPIを呼び出し出すために使用されます。

ダウンロード後、依存関係が抽出され、設定された一連のチェックとともに、Semgrepに基づく静的な解析手法を使用して分析されます。

JavaおよびC#の場合、静的な解析を実行する前に、バイナリアーティファクトを逆コンパイルするための追加の手順が実行されます。

### 既知の問題 {#known-issues}

各言語には、既知の問題があります。

`Gemfile.lock`や`requirements.txt`などのすべてのパッケージファイルは、明示的なバージョンを提供する必要があります。バージョン範囲はサポートされていません。

<!-- markdownlint-disable MD003 -->
<!-- markdownlint-disable MD020 -->
#### C# {#c}
<!-- markdownlint-disable MD020 -->
<!-- markdownlint-enable MD003 -->

- `.props`または`.csproj`ファイル内のプロパティまたは変数の置換は、ネストされたプロジェクトファイルを考慮しません。抽出された変数とその値のグローバルセットに一致する変数を置き換えます。
- ダウンロードされた依存関係を逆コンパイルするため、ソースからコード行への変換が1:1にならない場合があります。
- Libbehaveは、NuGetパッケージに存在するすべての.NETバージョンを逆コンパイルします。これは将来的に最適化される可能性があります。
  - たとえば、一部の依存関係は、異なるフレームワークバージョンをターゲットとする単一のアーカイブに複数のDLLをパッケージ化します（例：net20/Some.dll、net45/Some.dll）。

#### Java {#java}

- `pom.xml`ファイルの[継承](https://maven.apache.org/pom.html#inheritance)をサポートしていません。
- Mavenのみをサポートし、カスタムJFrogまたはその他のアーティファクトリポジトリはサポートしません。
- ダウンロードされた依存関係を逆コンパイルするため、ソースからコード行への変換が1:1にならない場合があります。

#### Python {#python}

- 分析のためにPyPiからソースパッケージをダウンロードしようとします。ソースパッケージがない場合、Libbehaveは最初に利用可能な`bdist_wheel`パッケージをダウンロードしますが、これはターゲットOSと一致しない可能性があります。

## 出力 {#output}

Libbehaveは次の出力を生成します:

- **Job summary**（ジョブサマリー）: 調査結果のサマリーは、依存関係が検出した機能をすばやく表示するために、CI/CD出力ジョブコンソールに直接出力されます。
- **MR comment summary**（MRコメントサマリー）: 調査結果のサマリーは、レビューを容易にするために、MRコメントノートとして出力されます。これには、MRノートセクションに書き込むためのジョブアクセスを許可するように設定されたアクセストークンが必要です。
- **HTML artifact**（HTMLアーティファクト）: 検索可能なライブラリのセットと特定された機能、および調査結果をトリガーした正確なコード行を含むHTMLアーティファクト。

### ジョブサマリー {#job-summary}

このジョブサマリーには特別な設定は必要なく、分析が成功すると常に表示されます。

ジョブサマリーの出力がどのように表示されるかの例:

```plaintext
# Job output #

[=== libbehave: New packages detected ===]
🔺 4 new packages have been detected in this MR.
[= java - open-vulnerability-clients 6.1.7 =]
The https://mvnrepository.com/artifact/io.github.jeremylong/open-vulnerability-clients package was found to exhibit the following behaviors:
    - 🟧 GzipReadArchive (Risk: Medium)
-----------------
[= java - jdiagnostics 1.0.7 =]
The https://mvnrepository.com/artifact/org.anarres.jdiagnostics/jdiagnostics package was found to exhibit the following behaviors:
    - 🟥 CryptoMD5 (Risk: High)
    - 🟧 WriteFile (Risk: Medium)
    - 🟧 ReadFile (Risk: Medium)
    - 🟧 ReadEnvVars (Risk: Medium)
-----------------
[= java - commons-dbcp2 2.12.0 =]
The https://mvnrepository.com/artifact/org.apache.commons/commons-dbcp2 package was found to exhibit the following behaviors:
    - 🟥 JavaObjectSerialization (Risk: High)
    - 🟧 Passwords (Risk: Medium)
-----------------
[= java - jmockit 1.49 =]
The https://mvnrepository.com/artifact/org.jmockit/jmockit package was found to exhibit the following behaviors:
    - 🟥 JavaObjectSerialization (Risk: High)
    - 🟧 WriteFile (Risk: Medium)
    - 🟧 ReadFile (Risk: Medium)
    - 🟨 CryptoRAND (Risk: Low)
-----------------
```

### MRコメントサマリー {#mr-comment-summary}

MRコメントサマリーの出力では、Libbehaveコンポーネントが設定されているプロジェクト用に、ゲストレベルのアクセス権を持つアクセストークンを作成する必要があります。アクセストークンは、[プロジェクト用に設定する](../../../ci/variables/_index.md#for-a-project)必要があります。フィーチャーブランチはデフォルトで保護されていないため、**変数の保護**設定がオフになっていることを確認してください。そうでない場合、Libbehaveジョブはアクセストークンの値を読み取りできません。

![MRコメントサマリー出力の例](img/libbehave_mr_comment_v17_4.png)

### HTMLアーティファクト {#html-artifact}

HTMLアーティファクトは、ジョブアーティファクトの出力（`behaveout/gl-libbehave.html`）に表示され、ジョブアーティファクトのダウンロードでアクセスできる必要があります。

![HTMLアーティファクトサマリー出力](img/libbehave_html_artifact_v17_4.png)

## オフライン環境（サポートされていません） {#offline-environment-not-supported}

Libbehaveは、さまざまなパッケージマネージャーから依存関係を直接プルするため、オフライン環境では機能しません。

## トラブルシューティング {#troubleshooting}

### ジョブが実行されていません {#job-is-not-run}

Libbehaveジョブが実行されていない場合は、[マージリクエストパイプライン](../../../ci/pipelines/merge_request_pipelines.md)を実行するようにプロジェクトが設定されていることを確認してください。

### MRコメントが追加されていません {#mr-comment-is-not-being-added}

これは通常、`BEHAVE_TOKEN`が設定されていないことが原因です。アクセストークンにゲストレベルのアクセス権があり、**変数の保護**オプションが**設定** > **CI/CD**変数設定でオフになっていることを確認します。

#### エラー: `{401 Permission Denied}` {#error-401-permission-denied}

これは通常、`BEHAVE_TOKEN`に正しい値が含まれていないことが原因です。アクセストークンにゲストレベルのアクセス権があることを確認します。
