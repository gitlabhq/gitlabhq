---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab関数を作成
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

A GitLab Functionは、関数のインターフェースと実装を定義する`func.yml`ファイルを持つディレクトリです。関数は、ローカルで実行することも、OCIレジストリに公開して、ジョブやプロジェクト全体で再利用することもできます。

CI/CDジョブでの関数の使用に関する情報は、[GitLab Functions](_index.md)を参照してください。関数の例については、[GitLab Functions examples](examples.md)を参照してください。

## 関数の構造 {#function-structure}

関数は、最低限`func.yml`ファイルと、実装に必要なすべてのサポートファイルを含むディレクトリです:

```plaintext
my-function/
├── func.yml
└── my-script.sh
```

`func.yml`ファイルには、`---`で区切られた2つのYAMLドキュメントが含まれています。関数の入力と出力を定義する仕様と、関数が行うことを記述する定義です。

```yaml
# Document 1: spec
spec:
  inputs:
    message:
      type: string
  outputs:
    result:
      type: string
---
# Document 2: definition
exec:
  command: ["${{ func_dir }}/my-script.sh", "${{ inputs.message }}"]
```

## 仕様: 入力と出力を宣言 {#spec-declare-inputs-and-outputs}

この仕様は、関数のインターフェースを記述しています。

### 入力 {#inputs}

各入力には`type`が必要です。`default`値を持つ入力はオプションです。デフォルト値を持たない入力は、呼び出し元によって提供されなければなりません。

入力名には英数字とアンダースコアを使用する必要があり、数字で始めることはできません。

入力は次のいずれかの型である必要があります:

| タイプ      | 例                 | 説明             |
|:----------|:------------------------|:------------------------|
| `array`   | `["a","b"]`             | 型付けされていないアイテムのリスト |
| `boolean` | `true`                  | 真偽値           |
| `number`  | `56.77`                 | 64ビット浮動小数点数            |
| `string`  | `"brown cow"`           | テキスト                    |
| `struct`  | `{"k1":"v1","k2":"v2"}` | 構造化されたコンテンツ      |

例: 

```yaml
spec:
  inputs:
    # Required string input
    message:
      type: string

    # Optional input with a default
    count:
      type: number
      default: 1

    # Struct input for passing structured data
    config:
      type: struct
      default: {}
```

### 出力 {#outputs}

出力は、関数が後続のステップに返す値を定義します。各出力には`type`が必要です。`default`値を持つ出力はオプションです。関数が出力値を書き込まない場合、デフォルト値が使用されます。

出力は、入力と同じ型と命名規則を使用します。

例: 

```yaml
spec:
  outputs:
    # Required string output
    artifact_path:
      type: string

    # Optional output with a default
    compressed:
      type: boolean
      default: false
```

ランタイム時に、関数は`${{ output_file }}`で指定されたパスに出力値を書き込みます。各行は、`name`および`value`フィールドを持つJSONオブジェクトである必要があります:

```shell
echo '{"name":"artifact_path","value":"/dist/app.tar.gz"}' >> "${{ output_file }}"
echo '{"name":"compressed","value":true}' >> "${{ output_file }}"
```

### 出力の委譲 {#delegate-outputs}

関数に複数のステップがあり、関数の出力を特定の1つのステップから取得したい場合は、仕様で`outputs: delegate`を、定義で`delegate: <step_name>`を使用します:

```yaml
spec:
  outputs: delegate
---
run:
  - name: build
    func: ./build
  - name: package
    func: ./package
delegate: package  # use the package step outputs as this function outputs
```

## 定義: 関数を実装 {#definition-implement-the-function}

`func.yml`内の2番目のドキュメントは、実装を記述しています。関数を実装する方法は2つあります。

### `exec` {#exec}

`exec`を使用して、単一のコマンドまたはスクリプトを実行します。コマンドはShellなしでOSに直接渡されるため、文字列の配列である必要があります。

```yaml
spec:
  inputs:
    message:
      type: string
---
exec:
  command: ["./greet", "${{ inputs.message }}"]
```

ワーキングディレクトリはデフォルトで`CI_PROJECT_DIR`です。それをオーバーライドするには、`work_dir`を使用します。`work_dir`キーワードは、`exec`定義にのみ有効であり、`run:`定義には有効ではありません。

コマンドが`func.yml`と同じディレクトリ内のファイルを参照する必要がある場合は、`work_dir`を`${{ func_dir }}`に設定します:

```yaml
exec:
  command: ["./build.sh"]
  work_dir: "${{ func_dir }}"
```

コマンドがゼロ以外の終了コードで終了した場合、関数は失敗します。

### `run` {#run}

`run`を、他の関数を順次呼び出す関数に使用します。

シーケンス内のいずれかのステップが失敗した場合、関数は失敗します。シーケンスの後続のステップは、失敗後には実行されません。

```yaml
spec:
  inputs:
    environment:
      type: string
  outputs:
    url:
      type: string
---
run:
  - name: build
    func: ./build
  - name: push
    func: registry.example.com/my-org/push:1.0.0
    inputs:
      artifact: ${{ steps.build.outputs.artifact_path }}
  - name: deploy
    func: ./deploy
    inputs:
      env: ${{ inputs.environment }}
      image: ${{ steps.push.outputs.image_ref }}
outputs:
  url: ${{ steps.deploy.outputs.url }}
```

### 環境変数を設定する {#set-environment-variables}

定義で`env`を使用して、`exec`コマンドまたは`run:`シーケンス内のすべてのステップの環境変数を設定します。値は式を使用できます:

```yaml
spec:
---
run:
  - name: test
    func: ./run-tests
env:
  GOFLAGS: "-race"
  TARGET_ENV: "${{ inputs.environment }}"
```

## 環境変数をエクスポート {#export-environment-variables}

環境変数を関数実行後のジョブの残りのすべてのステップで利用可能にするには、`${{ export_file }}`に書き込みます。各行は、`name`および`value`フィールドを持つJSONオブジェクトである必要があります:

```shell
echo '{"name":"INSTALL_PATH","value":"/opt/myapp"}' >> "${{ export_file }}"
```

`string`、`number`、`boolean`の値のみが環境変数としてエクスポートできます。

エクスポートされた変数が`env:`およびより広範な環境とどのように相互作用するかについての詳細は、[環境変数](_index.md#environment-variables)を参照してください。

## 式 {#expressions}

式は`${{ }}`構文を使用し、関数が実行される直前に評価されます。それらは、`inputs`の値、`env`の値、`exec`コマンド引数、および`work_dir`に表示されます。

[式](_index.md#expressions)で説明されているものに加えて、以下のコンテキスト変数が関数定義内で利用可能です:

| 変数                                  | 説明                                                                                 |
|:------------------------------------------|:--------------------------------------------------------------------------------------------|
| `inputs.<name>`                           | この関数に渡される名前付き入力の値。                                       |
| `func_dir`                                | この`func.yml`を含むディレクトリへの絶対パス。バンドルされたファイルを参照するために使用します。  |
| `output_file`                             | 出力を書き込むためのパス。                                                       |
| `export_file`                             | 環境変数をエクスポートするためのパス。                                       |
| `steps.<step_name>.outputs.<output_name>` | 名前付きステップからの出力（`run:`定義でのみ利用可能）。                            |

## 完全な例 {#complete-example}

以下の関数は、ファイルパスを受け入れ、`gzip`で圧縮し、圧縮されたファイルへのパスを返します。

### 関数を作成 {#create-the-function}

ディレクトリのレイアウト:

```plaintext
compress/
├── func.yml
└── compress.sh
```

`func.yml`: 

```yaml
spec:
  inputs:
    input_path:
      type: string
  outputs:
    output_path:
      type: string
---
exec:
  command: ["${{ func_dir }}/compress.sh", "${{ inputs.input_path }}", "${{ output_file }}"]
```

`compress.sh`（実行可能である必要があります）:

```shell
#!/usr/bin/env sh
set -e

INPUT_PATH="$1"
OUTPUT_FILE="$2"

gzip --keep "$INPUT_PATH"

echo "{\"name\":\"output_path\",\"value\":\"${INPUT_PATH}.gz\"}" >> "$OUTPUT_FILE"
```

### ジョブから関数を使用 {#use-the-function-from-a-job}

この関数には、ジョブ環境に`gzip`が必要です。この例では、`gzip`がジョブが実行されるインスタンスで既に利用可能であると想定しています。そうでない場合は、`script:`ステップで最初にインストールするか、`compress`を呼び出す前にインストールを処理する関数を実行できます。

```yaml
my-job:
  run:
    - name: compress_artifact
      func: ./compress
      inputs:
        input_path: "dist/app.tar"
    - name: list_compressed
      script: ls -lh ${{ steps.compress_artifact.outputs.output_path }}
```

その他の関数の例については、[GitLab関数の例](examples.md)を参照してください。

## 関数をビルドしてリリース {#build-and-release-functions}

関数はOCIイメージとして配布されます。ステップRunnerは、関数イメージをビルドおよび公開するための2つの組み込み関数を提供します。

### ビルド {#build}

`builtin://function/oci/build`関数は、プロジェクトディレクトリ内のファイルからマルチアーキテクチャ関数OCIイメージをビルドし、`CI_PROJECT_DIR`内に`function-image.tar`としてアーカイブします。

`common.files`はすべてのプラットフォームで共有されるファイルをコピーします。`platforms.<os/arch>.files`は、そのプラットフォーム固有のファイルをコピーします。どちらの場合も、マップキーはイメージ内の宛先パスであり、値は`CI_PROJECT_DIR`に対するソースパスです。

以下の例では、`function-image.tar`は`linux/amd64`と`linux/arm64`の2つのプラットフォームをサポートする関数OCIイメージです。各プラットフォームイメージには、`func.yml`、`my-script.sh`、`bin/my-binary`の3つのファイルがあります。プラットフォームバイナリに同じファイル名を使用することで、`func.yml`はプラットフォーム非依存性を維持します。

<!-- vale gitlab_base.Substitutions = NO -->
```yaml
build_function:
  artifacts:
    paths:
      - function-image.tar
  run:
    - name: build
      func: builtin://function/oci/build
      inputs:
        version: "1.2.3"
        common:
          files:
            func.yml: func.yml
            my-script.sh: my-script.sh
        platforms:
          linux/amd64:
            files:
              bin/my-binary: bin/linux-amd64/my-binary
          linux/arm64:
            files:
              bin/my-binary: bin/linux-arm64/my-binary
```
<!-- vale gitlab_base.Substitutions = YES -->

### リリース {#release}

`builtin://function/oci/publish`関数は、`function/oci/build`からのアーカイブをOCIレジストリに公開します。

公開関数は、関数イメージタグにセマンティックバージョニングを使用します: `1.0.0`、`1.1.0`、`2.0.0`。関数は`function-image.tar`ファイルからバージョンを抽出します。公開は、必要に応じて`major`、`major.minor`、`major.minor.patch`、および`latest`タグを更新します。

リリース候補は、`1.2.0-rc1`のようなプレリリースサフィックスを使用します。リリース候補を公開すると、正確な`major.minor.patch-prerelease`タグのみが作成されます。それは`major`、`major.minor`、または`latest`タグを更新しません。

```yaml
publish_function:
  needs: [build_function]
  run:
    - name: publish
      func: builtin://function/oci/publish
      inputs:
        archive: function-image.tar  # version is baked into the tar file
        to_repository: registry.example.com/my-org/my-function
```

### レジストリに認証する {#authenticate-to-a-registry}

プライベートレジストリに公開するには、`function/oci/publish`を実行する前に認証します。[Docker Auth](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth)関数を使用して、`DOCKER_AUTH_CONFIG`を公開する前のステップとして生成およびエクスポートします:

```yaml
publish_function:
  needs: [build_function]
  run:
    - name: auth
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth:1
      inputs:
        registry: ${{ vars.CI_REGISTRY }}
        username: ${{ vars.CI_REGISTRY_USER }}
        password: ${{ vars.CI_REGISTRY_PASSWORD }}
    - name: publish
      func: builtin://function/oci/publish
      inputs:
        archive: function-image.tar
        to_repository: ${{ vars.CI_REGISTRY_IMAGE }}
```

`docker-auth`は`DOCKER_AUTH_CONFIG`をすべての後続ステップにエクスポートするため、`function/oci/publish`が自動的にそれを検出します。

公開されると、呼び出し元はレジストリのURLとタグを使用して関数を参照します:

```yaml
run:
  - name: run_my_function
    func: registry.example.com/my-org/my-function:1.2.3
```
