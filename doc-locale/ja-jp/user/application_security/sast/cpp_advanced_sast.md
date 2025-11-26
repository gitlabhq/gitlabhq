---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Advanced SAST C/C++ 設定
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

## はじめに {#getting-started}

アナライザーをパイプラインで実行するには、SASTテンプレートを含め、GitLab Advanced SASTを有効にします:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml

variables:
  GITLAB_ADVANCED_SAST_CPP_ENABLED: "true"
  SAST_COMPILATION_DATABASE: "compile_commands.json"
```

または、[SASTコンポーネント](https://gitlab.com/components/sast/-/blob/main/templates/sast.yml)を使用します:

```yaml
include:
  - component: gitlab.com/components/sast/sast
    inputs:
      run_advanced_sast_cpp: "true"

variables:
  SAST_COMPILATION_DATABASE: "compile_commands.json"
```

この最小限の設定は、プロジェクトがコンパイルデータベース（CDB）を生成できることを前提としています。次のセクションでは、その作成方法について説明します。

## 前提要件 {#prerequisites}

GitLab Advanced SAST CPPアナライザーは、ソースファイルを正しく解析および分析するために、コンパイルデータベース（CDB）を必要とします。

CDBは、各翻訳単位に対して1つのエントリを含むJSONファイル（`compile_commands.json`）です。各エントリは通常、以下を指定します:

- ファイルのビルドに使用されるコンパイラコマンド
- コンパイラフラグとインクルードパス
- コンパイルが実行される作業ディレクトリ

CDBを使用すると、アナライザーは正確なビルド環境を再現し、正確な解析とセマンティック分析を保証できます。

### CDBを作成する {#create-a-cdb}

CDBの生成方法は、ビルドシステムによって異なります。以下に一般的な例を示します。

#### 例: CMake {#example-cmake}

[CMake](https://cmake.org/)は、`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`を使用してCDBを直接生成できます:

```shell
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

このオプションは、プロジェクトをビルドしません。各ソースファイルのコンパイラコマンドを記録する`build`フォルダーに`compile_commands.json`ファイルが生成されます。GitLab Advanced SAST CPPアナライザーは、このファイルを利用してビルド環境を正確に再現します。

#### さまざまなビルドシステムの例 {#examples-for-various-build-systems}

CDBを作成し、GitLab Advanced SAST CPPをさまざまなビルドシステムで実行する完全な例もあります:

- [CMakeの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/1)
- [Mesonの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/2)
- [compiledbの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/5)
- [compiledb-goの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/7)
- [Make + Bearの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/4)
- [Ninja + Bearの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/3)
- [Bazelの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/highway/-/merge_requests/8)

### アナライザーにCDBを提供する {#provide-the-cdb-to-the-analyzer}

`SAST_COMPILATION_DATABASE`変数を使用して、GitLab Advanced SAST CPPアナライザーにCDBの場所を指示します:

```yaml
variables:
  SAST_COMPILATION_DATABASE: YOUR_COMPILATION_DATABASE.json
```

SAST_COMPILATION_DATABASEが指定されていない場合、GitLab Advanced SAST CPPアナライザーは、プロジェクトルートにある`compile_commands.json located`という名前のファイルを使用することをデフォルトとします。

### 最適化: 効率性のための並列実行 {#optimization-parallel-execution-for-efficiency}

CDBを複数のフラグメントに分割することにより、アナライザーを並列で実行できます。[`GitLab Advanced SAST CPP`リポジトリ](https://gitlab.com/gitlab-org/security-products/analyzers/clangsa/-/blob/main/templates/scripts.yml)は、このためのヘルパースクリプトを提供します。

1. スクリプトを含めます:

   ```yaml
   include:
     - project: "gitlab-org/security-products/analyzers/clangsa"
       file: "templates/scripts.yml"
   ```

1. ヘルパースクリプトを参照し、ビルドジョブでCDBを分割します:

   ```yaml
   <YOUR-BUILD-JOB-NAME>:
     script:
       - <your-script to generate the CDB>
       - !reference [.clangsa-scripts]
       - split_cdb "${BUILD_DIR}" 1 4 # Split into 4 fragments
     artifacts:
       paths:
         - ${BUILD_DIR} # Pass the split CDB files to the parallelized gitlab-advanced-sast-cpp jobs
   ```

   {{< alert type="note" >}} `split_cdb`は、`${BUILD_DIR}/compile_commands.json`を読み取るようにハードコードされています。`split_cdb`を呼び出す前に、ビルドでこの正確な場所にCDBが生成されるようにしてください。{{< /alert >}}

1. 並列アナライザージョブを実行します:

   ```yaml
   gitlab-advanced-sast-cpp:
     parallel: 4
     variables:
       SAST_COMPILATION_DATABASE: "${BUILD_DIR}/compile_commands${CI_NODE_INDEX}.json"
     needs:
       - job: <YOUR-BUILD-JOB-NAME>
         artifacts: true
   ```

    - `parallel: 4`は、4つのジョブにまたがって実行をシャードします。
    - `${CI_NODE_INDEX}`（1、2、3、4）は、正しいCDBフラグメントを選択します。
    - `needs`は、アナライザージョブがビルドジョブによって生成されたアーティファクトを受信するようにします。

このセットアップでは、ビルドジョブは単一の`compile_commands.json`を生成します。`split_cdb`スクリプトは複数のパーティションを作成し、アナライザージョブは並列で実行され、各ジョブが1つのパーティションを処理します。

## トラブルシューティング {#troubleshooting}

### `cdb-rebase`リベースパス {#rebasing-paths-with-cdb-rebase}

CDB内のパスがCIジョブのコンテナパスと一致しない場合は、[cdb-rebase](https://gitlab.com/gitlab-org/security-products/analyzers/clangsa/-/tree/main/cmd/cdb-rebase)を使用して調整します。

インストール:

```shell
go install gitlab.com/gitlab-org/secure/tools/cdb-rebase@latest
```

バイナリは`$GOPATH/bin`または`$HOME/go/bin`にインストールされます。このディレクトリが`PATH`にあることを確認します。

使用例:

```shell
cdb-rebase compile_commands.json /host/path /container/path > rebased_compile_commands.json
```

### CDBの修正 {#fixing-the-cdb}

ビルド環境がスキャン環境と異なる場合、生成されたCDBは調整が必要になる場合があります。[jq](https://jqlang.org)で変更するか、[事前定義されたヘルパースクリプト](https://gitlab.com/gitlab-org/security-products/analyzers/clangsa/-/blob/main/templates/scripts.yml)のシェル関数である`cdb_append`を使用します。

`cdb_append`は、既存のCDBにコンパイラオプションを追加します。以下を受け入れます:

- 最初の引数: `compile_commands.json`を含むフォルダー
- 後続の引数: 付加する追加のコンパイラオプション

CIの例:

```yaml
include:
  - project: "gitlab-org/security-products/analyzers/clangsa"
    file: "templates/scripts.yml"

<YOUR-BUILD-JOB-NAME>:
  script:
    - !reference [.clangsa-scripts]
    - <your-script to generate the CDB>
    - cdb_append "${BUILD_DIR}" "-I'$PWD/include-cache'" "-Wno-error=register"
```

### CDBのキャッシュ {#caching-a-cdb}

コンパイルと分析の処理を高速化するために、CDBを[キャッシュ](../../../ci/caching/_index.md)できます。

```yaml
.cdb_cache:
  cache: &cdb_cache
    key:
      files:
        - Makefile
        - src/
    paths:
      - compile_commands.json

<YOUR-BUILD-JOB-NAME>:
  script:
    - <your-script to generate the CDB>
  cache:
    <<: *cdb_cache
    policy: pull-push

gitlab-advanced-sast-cpp:
  cache:
    <<: *cdb_cache
    policy: pull
```

完全な例については、デモプロジェクト[`cached-cdb`](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/cached-db)を参照してください。

### CDBで絶対パスを処理する {#handling-absolute-paths-in-a-cdb}

この[デモプロジェクト](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/cached-db/-/blob/1a36792b744d7a6ad396a8ac8114ca8947e45b62/.gitlab-ci.yml#L27)では、`bear`はDockerジョブの[ビルドディレクトリ](https://docs.gitlab.com/runner/configuration/advanced-configuration/#default-build-directory)から実行されます。CDBパスは絶対パスであり、[/builds/$CI_PROJECT_PATH](../../../ci/variables/predefined_variables.md)に基づいています。アナライザージョブ`gitlab-advanced-sast-cpp`は同じ場所で実行されるため、パスは正しいです。

分析中にCDBが利用できないパスで生成された場合は、リベースする必要があります。アナライザーイメージに含まれる`cdb-rebase`ツールは、`directory`、`file`、および`output`パスを書き換えます。

例: 

```yaml
gitlab-advanced-sast-cpp:
  before-script:
    # Rebase the original CDB to be relative to the current directory.
    #
    # ORIGINAL_CDB_PATH     - Path to the CDB artifact from a previous job (e.g., artifacts/compile_commands.json)
    # ORIGINAL_CDB_BASEPATH - The absolute path to the project root when the ORIGINAL_CDB_PATH was generated.
    #                         (e.g., /mnt/custom_build_area/my-project or /home/user/my-project)
    - /cdb-rebase   --input "$ORIGINAL_CDB_PATH" \
                    --output compile_commands.json \
                    --src "$ORIGINAL_CDB_BASEPATH" \
                    --dst .
```

完全なデモンストレーションについては、[cdb--demo](https://gitlab.com/gitlab-org/security-products/demos/experiments/cpp-advanced-sast/cdb-rebase-demo)を参照してください

単純なパスのリベース以外に、`cdb-rebase`はビルド環境とスキャン環境の間でインクルードファイルを管理することもできます:

- 外部ヘッダーをキャッシュする: `--include-cache`を使用すると、ソースツリー外のヘッダーがポータブルキャッシュにコピーされます。
- インクルードパスを追加する: `--include`を使用すると、キャッシュする追加のインクルードディレクトリを指定します。
- ファイルを除外する: `--exclude`を使用すると、引き継ぎたくないヘッダーをスキップします。

例: 

```shell
/cdb-rebase --src /my-project \
            --dst /scan-env \
            --input build/compile_commands.json \
            --output rebased_cdb.json \
            --include-cache include-cache \
            --include third_party/include \
            --exclude dummy.h
```

`cde-rebase`ツールはGoがインストールされた環境でも使用できるため、CDBの生成時にリベースすることが可能です。例: 

```shell
go install gitlab.com/gitlab-org/security-products/analyzers/clangsa/cmd/cdb-rebase@latest
bear -o compile_commands_abs.json -- make
cdb-rebase -i compile_commands_abs.json -o compile_commands.json -s "$PWD" -d .
```

注: 上記の`go install`コマンドは、`cdb-rebase`を`GOBIN`パスにインストールします。これは、`go env GOBIN`で確認できます。
