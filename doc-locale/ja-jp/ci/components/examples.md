---
stage: Verify
group: Pipeline Authoring
info: This page is maintained by Developer Relations, author @dnsmichi, see https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation
title: CI/CDコンポーネントの例
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## コンポーネントをTestする

コンポーネントの機能によっては、[コンポーネントのTest](_index.md#test-the-component)にはリポジトリに追加ファイルが必要になる場合があります。たとえば、特定のプログラミング言語で Lint、ビルド、Testを行うコンポーネントには、実際のソースコードサンプルが必要です。同じリポジトリにソースコードの例、設定ファイルなどを配置できます。

たとえば、コード品質 CI/CDコンポーネントには、[Test用のコードサンプル](https://gitlab.com/components/code-quality/-/tree/main/src)がいくつかあります。

### 例:Rust言語CI/CDコンポーネントをTestする

コンポーネントの機能によっては、[コンポーネントのTest](_index.md#test-the-component)にはリポジトリに追加ファイルが必要になる場合があります。

Rustプログラミング言語の次の「hello world」の例では、簡略化のために`cargo` ツールチェーンを使用します。

1. CI/CDコンポーネントのルートディレクトリに移動します。
1. `cargo init` コマンドを使用して、新しいRustプロジェクトを初期化します。

   ```shell
   cargo init
   ```

   このコマンドは、`src/main.rs` 「hello world」の例を含む、必要なすべてのプロジェクトファイルを作成します。このステップは、`cargo build` を使用してコンポーネントジョブでRustソースコードをビルドするのに十分です。

   ```plaintext
   tree
   .
   ├── Cargo.toml
   ├── LICENSE.md
   ├── README.md
   ├── src
   │   └── main.rs
   └── templates
       └── build.yml
   ```

1. コンポーネントにRustソースコードをビルドするジョブがあることを確認します（例：`templates/build.yml`）。

   ```yaml
   spec:
     inputs:
       stage:
         default: build
         description: 'Defines the build stage'
       rust_version:
         default: latest
         description: 'Specify the Rust version, use values from https://hub.docker.com/_/rust/tags Defaults to latest'
   ---

   "build-$[[ inputs.rust_version ]]":
     stage: $[[ inputs.stage ]]
     image: rust:$[[ inputs.rust_version ]]
     script:
       - cargo build --verbose
   ```

   この例:

   - `stage` インプットと `rust_version` インプットは、デフォルト値から変更できます。CI/CDジョブは、`build-` プレフィックスで始まり、`rust_version` インプットに基づいて名前を動的に作成します。コマンド `cargo build --verbose` は、Rustソースコードをコンパイルします。

1. プロジェクトの `.gitlab-ci.yml` 設定ファイルで、コンポーネントの `build` テンプレートをTestします。

   ```yaml
   include:
     # include the component located in the current project from the current SHA
     - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
       inputs:
         stage: build

   stages: [build, test, release]
   ```

1. Testなどを実行するには、Rustコードに追加の関数とテストを追加し、`templates/test.yml` で `cargo test` を実行するコンポーネントテンプレートとジョブを追加します。

   ```yaml
   spec:
     inputs:
       stage:
         default: test
         description: 'Defines the test stage'
       rust_version:
         default: latest
         description: 'Specify the Rust version, use values from https://hub.docker.com/_/rust/tags Defaults to latest'
   ---

   "test-$[[ inputs.rust_version ]]":
     stage: $[[ inputs.stage ]]
     image: rust:$[[ inputs.rust_version ]]
     script:
       - cargo test --verbose
   ```

1. `test` コンポーネントテンプレートを含めることで、パイプラインで追加のジョブをTestします。

   ```yaml
   include:
     # include the component located in the current project from the current SHA
     - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
       inputs:
         stage: build
     - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/test@$CI_COMMIT_SHA
       inputs:
         stage: test

   stages: [build, test, release]
   ```

## CI/CDコンポーネントのパターン

このセクションでは、CI/CDコンポーネントで一般的なパターンを実装するための実践的な例を示します。

### ブール値のインプットを使用して、ジョブを条件付きでConfigureする

`boolean` タイプのインプットと [`extends`](../yaml/_index.md#extends) 機能を組み合わせることで、2つの条件でジョブを構成できます。

たとえば、`boolean` インプットを使用して複雑なキャッシュ動作をConfigureするには:

```yaml
spec:
  inputs:
    enable_special_caching:
      description: 'If set to `true` configures a complex caching behavior'
      type: boolean
---

.my-component:enable_special_caching:false:
  extends: null

.my-component:enable_special_caching:true:
  cache:
    policy: pull-push
    key: $CI_COMMIT_SHA
    paths: [...]

my-job:
  extends: '.my-component:enable_special_caching:$[[ inputs.enable_special_caching ]]'
  script: ... # run some fancy tooling
```

このパターンは、ジョブの `extends` キーワードに `enable_special_caching` インプットを渡すことによって機能します。`enable_special_caching` が `true` か `false` かに応じて、定義済みの非表示ジョブ（`.my-component:enable_special_caching:true` または `.my-component:enable_special_caching:false`）から適切な設定が選択されます。

### `options` を使用してジョブを条件付きでConfigureする

`if` および `elseif` の条件と同様の動作で、複数のオプションを使用してジョブを構成できます。任意の数の条件に対して、`string` タイプと複数の `options` を使用して [`extends`](../yaml/_index.md#extends) を使用します。

たとえば、3つの異なるオプションを使用して複雑なキャッシュ動作をConfigureするには:

```yaml
spec:
  inputs:
    cache_mode:
      description: Defines the caching mode to use for this component
      type: string
      options:
        - default
        - aggressive
        - relaxed
---

.my-component:cache_mode:default:
  extends: null

.my-component:cache_mode:aggressive:
  cache:
    policy: push
    key: $CI_COMMIT_SHA
    paths: ['*/**']

.my-component:cache_mode:relaxed:
  cache:
    policy: pull-push
    key: $CI_COMMIT_BRANCH
    paths: ['bin/*']

my-job:
  extends: '.my-component:cache_mode:$[[ inputs.cache_mode ]]'
  script: ... # run some fancy tooling
```

この例では、`cache_mode` インプットは、`default`、`aggressive`、および `relaxed` のオプションを提供し、それぞれが異なる非表示ジョブに対応しています。`extends: '.my-component:cache_mode:$[[ inputs.cache_mode ]]'` でコンポーネントジョブを拡張することにより、ジョブは選択されたオプションに基づいて正しいキャッシュ設定を動的に継承します。

## CI/CDコンポーネントの移行例

このセクションでは、CI/CDテンプレートとパイプライン設定を再利用可能なCI/CDコンポーネントに移行するための実践的な例を示します。

### CI/CDコンポーネントの移行例:Go

ソフトウェア開発ライフサイクル全体のパイプラインは、複数のジョブとステージで構成できます。プログラミング言語用のCI/CDテンプレートは、単一のテンプレートファイルで複数のジョブを提供する場合があります。実践として、次のGo CI/CDテンプレートを移行する必要があります。

```yaml
default:
  image: golang:latest

stages:
  - test
  - build
  - deploy

format:
  stage: test
  script:
    - go fmt $(go list ./... | grep -v /vendor/)
    - go vet $(go list ./... | grep -v /vendor/)
    - go test -race $(go list ./... | grep -v /vendor/)

compile:
  stage: build
  script:
    - mkdir -p mybinaries
    - go build -o mybinaries ./...
  artifacts:
    paths:
      - mybinaries
```

{{< alert type="note" >}}

すべてのジョブではなく、1つのジョブの移行から開始することもできます。以下の手順に従い、最初のイテレーションでは `build` CI/CDジョブのみを移行します。

{{< /alert >}}

CI/CDテンプレートの移行には、次の手順が含まれます:

1. CI/CDジョブと依存関係を分析し、移行アクションを定義します:
   - `image` 設定はグローバルであるため、[ジョブ定義に移動する必要があります](_index.md#avoid-using-global-keywords)。
   - `format` ジョブは、1つのジョブで複数の `go` コマンドを実行します。パイプラインの効率性を高めるために、`go test` コマンドは別のジョブに移動する必要があります。
   - `compile` ジョブは `go build` を実行し、`build` に名前を変更する必要があります。
1. パイプラインの効率性を向上させるための最適化戦略を定義します。
   - `stage` ジョブ属性は、さまざまなCI/CDパイプラインのコンシューマーを許可するように設定可能である必要があります。
   - `image` キーは、ハードコードされたイメージtag `latest` を使用します。より柔軟で再利用可能なパイプラインのために、`latest` をデフォルト値として持つ [`golang_version` をインプットとして追加](../yaml/inputs.md)します。インプットは、Docker Hubイメージtagの値と一致する必要があります。
   - `compile` ジョブは、バイナリをハードコードされたターゲットディレクトリ `mybinaries` にビルドします。これは、動的な[インプット](../yaml/inputs.md)とデフォルト値 `mybinaries` で強化できます。
1. ジョブごとに1つのテンプレートに基づいて、新しいコンポーネントの[ディレクトリ構造](_index.md#directory-structure)のテンプレートを作成します。

   - テンプレートの名前は、`go` コマンドに従う必要があります（例：`format.yml`、`build.yml`、および `test.yml`）。
   - 新しいプロジェクトを作成し、Gitリポジトリを初期化し、すべての変更を追加/コミットし、remote originを設定してプッシュします。CI/CDコンポーネントプロジェクトパスのURLを変更します。
   - [コンポーネントを作成する](_index.md#write-a-component)ためのガイダンスで概説されているように、追加のファイルを作成します:`README.md`、`LICENSE.md`、`.gitlab-ci.yml`、`.gitignore`。次のShellコマンドは、Goコンポーネント構造を初期化します:

   ```shell
   git init

   mkdir templates
   touch templates/{format,build,test}.yml

   touch README.md LICENSE.md .gitlab-ci.yml .gitignore

   git add -A
   git commit -avm "Initial component structure"

   git remote add origin https://gitlab.example.com/components/golang.git

   git push
   ```

1. CI/CDジョブをテンプレートとして作成します。`build` ジョブから開始します。
   - `spec` セクションで、次のインプットを定義します:`stage`、`golang_version`、および `binary_directory`。
   - `inputs.golang_version` にアクセスして、動的なジョブ名定義を追加します。
   - `inputs.golang_version` にアクセスして、動的なGoイメージバージョンの同様のパターンを使用します。
   - `inputs.stage` 値にステージを割り当てます。
   - `inputs.binary_directory` からバイナリディレクターを作成し、`go build` のパラメータとして追加します。
   - アーティファクトパスを `inputs.binary_directory` に定義します。

     ```yaml
     spec:
       inputs:
         stage:
           default: 'build'
           description: 'Defines the build stage'
         golang_version:
           default: 'latest'
           description: 'Go image version tag'
         binary_directory:
           default: 'mybinaries'
           description: 'Output directory for created binary artifacts'
     ---

     "build-$[[ inputs.golang_version ]]":
       image: golang:$[[ inputs.golang_version ]]
       stage: $[[ inputs.stage ]]
       script:
         - mkdir -p $[[ inputs.binary_directory ]]
         - go build -o $[[ inputs.binary_directory ]] ./...
       artifacts:
         paths:
           - $[[ inputs.binary_directory ]]
     ```

   - `format` ジョブテンプレートは同じパターンに従いますが、`stage` と `golang_version` インプットのみが必要です。

     ```yaml
     spec:
       inputs:
         stage:
           default: 'format'
           description: 'Defines the format stage'
         golang_version:
           default: 'latest'
           description: 'Golang image version tag'
     ---

     "format-$[[ inputs.golang_version ]]":
       image: golang:$[[ inputs.golang_version ]]
       stage: $[[ inputs.stage ]]
       script:
         - go fmt $(go list ./... | grep -v /vendor/)
         - go vet $(go list ./... | grep -v /vendor/)
     ```

   - `test` ジョブテンプレートは同じパターンに従いますが、`stage` と `golang_version` インプットのみが必要です。

     ```yaml
     spec:
       inputs:
         stage:
           default: 'test'
           description: 'Defines the format stage'
         golang_version:
           default: 'latest'
           description: 'Golang image version tag'
     ---

     "test-$[[ inputs.golang_version ]]":
       image: golang:$[[ inputs.golang_version ]]
       stage: $[[ inputs.stage ]]
       script:
         - go test -race $(go list ./... | grep -v /vendor/)
     ```

1. コンポーネントをテストするには、`.gitlab-ci.yml` 設定ファイルを変更し、[Test](_index.md#test-the-component)を追加します。

   - `build` ジョブのインプットとして、`golang_version` に別の値を指定します。
   - CI/CDコンポーネントパスのURLを変更します。

     ```yaml
     stages: [format, build, test]

     include:
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/format@$CI_COMMIT_SHA
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
         inputs:
           golang_version: "1.21"
       - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/test@$CI_COMMIT_SHA
         inputs:
           golang_version: latest
     ```

1. CI/CDコンポーネントをTestするためのGoソースコードを追加します。`go` コマンドは、ルートディレクトリに `go.mod` と `main.go` を含むGoプロジェクトを想定しています。

   - Goモジュールを初期化します。CI/CDコンポーネントパスのURLを変更します。

     ```shell
     go mod init example.gitlab.com/components/golang
     ```

   - たとえば、`Hello, CI/CD component` を印刷するメイン関数を使用して、`main.go` ファイルを作成します。コードコメントを使用すると、[GitLab Duo コード提案](../../user/project/repository/code_suggestions/_index.md)を使用してGoコードを生成できます。

     ```go
     // Specify the package, import required packages
     // Create a main function
     // Inside the main function, print "Hello, CI/CD Component"

     package main

     import "fmt"

     func main() {
       fmt.Println("Hello, CI/CD Component")
     }
     ```

   - ディレクトリツリーは次のようになります:

     ```plaintext
     tree
     .
     ├── LICENSE.md
     ├── README.md
     ├── go.mod
     ├── main.go
     └── templates
         ├── build.yml
         ├── format.yml
         └── test.yml
     ```

[CI/CDテンプレートをコンポーネントに変換する](_index.md#convert-a-cicd-template-to-a-component)セクションの残りの手順に従って、移行を完了します:

1. 変更をコミットしてプッシュし、CI/CDパイプラインの結果を検証します。
1. [コンポーネントの作成](_index.md#write-a-component)に関するガイダンスに従って、`README.md` と `LICENSE.md` ファイルを更新します。
1. [コンポーネントをリリース](_index.md#publish-a-new-release)し、CI/CDカタログで検証します。
1. CI/CDコンポーネントをステージ/本番環境に追加します。

[GitLabが保持されるGoコンポーネント](https://gitlab.com/components/go)は、Go CI/CDテンプレートからの移行が成功した例を提供し、インプットとコンポーネントのベストプラクティスで強化されています。Gitの履歴を調べて詳細を確認できます。
