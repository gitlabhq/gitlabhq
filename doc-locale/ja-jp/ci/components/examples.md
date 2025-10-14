---
stage: Verify
group: Pipeline Authoring
info: This page is maintained by Developer Relations, author @dnsmichi, see https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation
title: CI/CDコンポーネントの例
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## コンポーネントをテストする {#test-a-component}

コンポーネントの機能によっては、[コンポーネントをテストする](_index.md#test-the-component)ために、リポジトリに追加ファイルが必要になる場合があります。たとえば、特定のプログラミング言語でソフトウェアをlint、ビルド、テストするコンポーネントには、実際のソースコードのサンプルが必要です。ソースコードの例、設定ファイルなどを同じリポジトリに配置できます。

たとえば、コード品質CI/CDコンポーネントには、[テスト用のコードサンプル](https://gitlab.com/components/code-quality/-/tree/main/src)がいくつかあります。

### 例: Rust言語のCI/CDコンポーネントをテストする {#example-test-a-rust-language-cicd-component}

コンポーネントの機能によっては、[コンポーネントをテストする](_index.md#test-the-component)ために、リポジトリに追加ファイルが必要になる場合があります。

次に示すRustプログラミング言語の「hello world」の例では、簡略化のために`cargo`ツールチェーンを使用しています。

1. CI/CDコンポーネントのルートディレクトリに移動します。
1. `cargo init`コマンドを使用して、新しいRustプロジェクトを初期化します。

   ```shell
   cargo init
   ```

   このコマンドは、`src/main.rs`の「hello world」サンプルを含む、必要なすべてのプロジェクトファイルを作成します。コンポーネントジョブ内で`cargo build`を使用してRustソースコードをビルドするには、このステップだけで十分です。

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

1. Rustソースコードをビルドするジョブがコンポーネントに含まれていることを確認します。その例として、以下に`templates/build.yml`を示します。

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

   この例では:

   - `stage`と`rust_version`の入力はデフォルト値から変更できます。CI/CDジョブは、`build-`プレフィックスで始まり、`rust_version`入力に基づいて名前を動的に作成します。コマンド`cargo build --verbose`でRustソースコードをコンパイルします。

1. プロジェクトの`.gitlab-ci.yml`設定ファイルで、コンポーネントの`build`テンプレートをテストします。

   ```yaml
   include:
     # include the component located in the current project from the current SHA
     - component: $CI_SERVER_FQDN/$CI_PROJECT_PATH/build@$CI_COMMIT_SHA
       inputs:
         stage: build

   stages: [build, test, release]
   ```

1. テストやその他の処理を実行するには、Rustコードに関数とテストを追加し、`cargo test`を実行するコンポーネントテンプレートとジョブを`templates/test.yml`に追加します。

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

1. `test`コンポーネントテンプレートを含めることで、パイプラインで追加のジョブをテストします。

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

## CI/CDコンポーネントのパターン {#cicd-component-patterns}

このセクションでは、CI/CDコンポーネントで一般的なパターンを実装するための実践的な例を示します。

### ブール値の入力を使用してジョブを条件付きで設定する {#use-boolean-inputs-to-conditionally-configure-jobs}

`boolean`型の入力と[`extends`](../yaml/_index.md#extends)機能を組み合わせることで、2つの条件分岐を持つジョブを構成できます。

たとえば、`boolean`入力を使用して複雑なキャッシュ動作を設定するには、次のようにします。

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

このパターンは、ジョブの`extends`キーワードに`enable_special_caching`入力を渡すことによって機能します。`enable_special_caching`が`true`か`false`かに応じて、定義済みの非表示ジョブ（`.my-component:enable_special_caching:true`または`.my-component:enable_special_caching:false`）から適切な設定が選択されます。

### `options`を使用してジョブを条件付きで設定する {#use-options-to-conditionally-configure-jobs}

複数のオプションを持つジョブを構成し、`if`や`elseif`の条件と同様の動作を実現できます。[`extends`](../yaml/_index.md#extends)に`string`型と複数の`options`を組み合わせることで、任意の数の条件を設定できます。

たとえば、3つの異なるオプションを使用して複雑なキャッシュ動作を設定するには、次のようにします。

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

この例では、`cache_mode`入力は`default`、`aggressive`、`relaxed`のオプションを提供し、それぞれ異なる非表示ジョブに対応しています。`extends: '.my-component:cache_mode:$[[ inputs.cache_mode ]]'`でコンポーネントジョブを拡張することにより、ジョブは選択されたオプションに基づいて正しいキャッシュ設定を動的に継承します。

## CI/CDコンポーネントの移行例 {#cicd-component-migration-examples}

このセクションでは、CI/CDテンプレートとパイプライン設定を再利用可能なCI/CDコンポーネントに移行するための実践的な例を示します。

### CI/CDコンポーネントの移行例: Go {#cicd-component-migration-example-go}

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

より段階的なアプローチとして、一度に1つのジョブを移行します。まず`build`ジョブから始め、その後`format`ジョブ、`test`ジョブの順に同じ手順を繰り返します。

{{< /alert >}}

CI/CDテンプレートを移行するには、次の手順を実行します。

1. CI/CDジョブと依存関係を分析し、移行アクションを定義します。
   - `image`設定はグローバルであるため、[ジョブ定義に移動する必要があります](_index.md#avoid-using-global-keywords)。
   - `format`ジョブは、1つのジョブで複数の`go`コマンドを実行します。パイプラインの効率性を高めるために、`go test`コマンドは別のジョブに移動する必要があります。
   - `compile`ジョブは`go build`を実行しているため、`build`に名前を変更する必要があります。
1. パイプラインの効率性を向上させるための最適化戦略を定義します。
   - さまざまなCI/CDパイプラインの利用者が活用できるように、`stage`ジョブ属性は設定可能でなければなりません。
   - `image`キーは、ハードコーディングされたイメージタグ`latest`を使用します。より柔軟で再利用可能なパイプラインにするため、`latest`をデフォルト値とする[`golang_version`を入力として](../inputs/_index.md)追加します。入力は、Docker Hubのイメージタグの値と一致する必要があります。
   - `compile`ジョブは、バイナリをハードコーディングされたターゲットディレクトリ`mybinaries`にビルドします。これは、`mybinaries`をデフォルト値とする動的な[入力](../inputs/_index.md)として拡張できます。
1. ジョブごとに1つのテンプレートを基にして、新しいコンポーネントのテンプレート用[ディレクトリ構造](_index.md#directory-structure)を作成します。

   - テンプレートの名前は、`go`コマンドに従う必要があります（例: `format.yml`、`build.yml`、`test.yml`）。
   - 新しいプロジェクトを作成し、Gitリポジトリを初期化し、すべての変更を追加/コミットし、リモートoriginを設定してプッシュします。CI/CDコンポーネントプロジェクトのパスに合わせてURLを変更します。
   - [コンポーネントを作成する](_index.md#write-a-component)ためのガイダンスで概説されているように、追加のファイルとして`README.md`、`LICENSE.md`、`.gitlab-ci.yml`、`.gitignore`を作成します。次のShellコマンドは、Goコンポーネント構造を初期化します。

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

1. CI/CDジョブをテンプレートとして作成します。`build`ジョブから開始します。
   - `spec`セクションで、`stage`、`golang_version`、`binary_directory`の各入力を定義します。
   - `inputs.golang_version`にアクセスして、動的なジョブ名の定義を追加します。
   - `inputs.golang_version`にアクセスして、Goイメージのバージョンも同様に動的に指定します。
   - `inputs.stage`値にステージを割り当てます。
   - `inputs.binary_directory`からバイナリディレクトリを作成し、`go build`のパラメータとして追加します。
   - アーティファクトのパスを`inputs.binary_directory`として定義します。

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

   - `format`ジョブテンプレートは同じパターンに従いますが、必要なのは`stage`と`golang_version`の入力のみです。

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

   - `test`ジョブテンプレートは同じパターンに従いますが、必要なのは`stage`と`golang_version`の入力のみです。

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

1. コンポーネントをテストするために、`.gitlab-ci.yml`設定ファイルを変更し、[テスト](_index.md#test-the-component)を追加します。

   - `build`ジョブの入力として、`golang_version`に別の値を指定します。
   - CI/CDコンポーネントのパスに合わせてURLを変更します。

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

1. CI/CDコンポーネントをテストするためのGoソースコードを追加します。`go`コマンドは、ルートディレクトリに`go.mod`と`main.go`を含むGo言語プロジェクトを想定しています。

   - Goモジュールを初期化します。CI/CDコンポーネントのパスに合わせてURLを変更します。

     ```shell
     go mod init example.gitlab.com/components/golang
     ```

   - たとえば、`Hello, CI/CD component`を出力するmain関数を持つ`main.go`ファイルを作成します。コードコメントを使用して、[GitLab Duoコード提案](../../user/project/repository/code_suggestions/_index.md)でGoコードを生成できます。

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

   - ディレクトリツリーは次のようになります。

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

[CI/CDテンプレートをコンポーネントに変換する](_index.md#convert-a-cicd-template-to-a-component)セクションの残りの手順に従って、移行を完了します。

1. 変更をコミットしてプッシュし、CI/CDパイプラインの結果を検証します。
1. [コンポーネントを作成する](_index.md#write-a-component)に記載されたガイダンスに従って、`README.md`と`LICENSE.md`ファイルを更新します。
1. [コンポーネントをリリース](_index.md#publish-a-new-release)し、CI/CDカタログで検証します。
1. CI/CDコンポーネントをstagingステージ/本番環境に追加します。

[GitLabが管理するGoコンポーネント](https://gitlab.com/components/go)は、Go CI/CDテンプレートからの移行の成功例を示しており、入力とコンポーネントのベストプラクティスによって強化されています。詳細については、Gitの履歴をご覧ください。
