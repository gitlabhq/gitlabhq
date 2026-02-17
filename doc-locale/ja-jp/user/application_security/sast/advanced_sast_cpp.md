---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Advanced SAST C/C++ の設定
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.6で[ベータ](../../../policy/development_stages_support.md#beta)として[導入](https://gitlab.com/groups/gitlab-org/-/work_items/18368)されました。
- GitLab 18.8で[一般提供](https://gitlab.com/groups/gitlab-org/-/work_items/18369)になりました。

{{< /history >}}

## はじめに {#getting-started}

パイプラインでアナライザーを実行するには、SASTテンプレートを含め、GitLab高度なSASTを有効にします:

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
  - component: gitlab.com/components/sast/sast@main
    inputs:
      run_advanced_sast_cpp: "true"

variables:
  SAST_COMPILATION_DATABASE: "compile_commands.json"
```

この最小限の設定では、プロジェクトがコンパイルデータベース（CDB）を生成できることを前提としています。次のセクションでは、その作成方法について説明します。

## 前提条件 {#prerequisites}

GitLab高度なSAST CPPアナライザーは、ソースファイルを正しく解析および分析するために、コンパイルデータベース（CDB）を必要とします。

CDBは、各変換ユニットのエントリを1つ含むJSONファイル（`compile_commands.json`）です。通常、各エントリは以下を指定します:

- ファイルのビルドに使用されるコンパイラコマンド
- コンパイラフラグとインクルードパス
- コンパイルが実行される作業ディレクトリ

CDBを使用すると、アナライザーは正確なビルド環境を再現し、正確な解析中とセマンティック分析を保証できます。

### CDBを作成 {#create-a-cdb}

CDBの生成方法は、ビルドシステムによって異なります。以下に一般的な例を示します。

#### 例: CMake {#example-cmake}

[CMake](https://cmake.org/)は、`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`パラメータを`cmake`呼び出しに追加することにより、CDBを直接生成できます:

```shell
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

このオプションは、プロジェクトを構成し、`compile_commands.json`ファイルを`build`フォルダーに生成します。これは、各ソースファイルのコンパイラコマンドを記録します。

GitLab高度なSAST CPPアナライザーは、このファイルに依存して、ビルド環境を正確に再現します。

生成された`compile_commands.json`ファイルを、次のビルドジョブの例の[ジョブアーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートします:

```yaml
<YOUR-BUILD-JOB-NAME>:
  image: ubuntu:24.04
  before_script:
    - apt update -qq && apt install -y -qq cmake build-essential
  script:
    - mkdir -p build
    - cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    - make -j$(nproc)
  artifacts:
    paths:
      - build/compile_commands.json # Pass the CDB file to the gitlab-advanced-sast-cpp job
```

#### さまざまなビルドシステムの例 {#examples-for-various-build-systems}

CDBを作成し、さまざまなビルドシステムでGitLab高度なSAST CPPを実行する完全な例もあります:

- [CMakeの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/advanced-sast-cpp/highway/-/merge_requests/1)
- [Mesonの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/advanced-sast-cpp/highway/-/merge_requests/2)
- [compiledbの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/advanced-sast-cpp/highway/-/merge_requests/5)
- [compiledb-goの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/advanced-sast-cpp/highway/-/merge_requests/7)
- [Make + Bearの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/advanced-sast-cpp/highway/-/merge_requests/4)
- [Ninja + Bearの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/advanced-sast-cpp/highway/-/merge_requests/3)
- [Bazelの例](https://gitlab.com/gitlab-org/security-products/demos/experiments/advanced-sast-cpp/highway/-/merge_requests/8)

### アナライザーにCDBを提供する {#provide-the-cdb-to-the-analyzer}

`SAST_COMPILATION_DATABASE`変数を使用して、GitLab高度なSAST CPPアナライザーにCDBの場所を指示します:

```yaml
variables:
  SAST_COMPILATION_DATABASE: YOUR_COMPILATION_DATABASE.json
```

`SAST_COMPILATION_DATABASE`が指定されていない場合、GitLab高度なSAST CPPアナライザーは、デフォルトでプロジェクトルートディレクトリにある`compile_commands.json`という名前のファイルを使用します。

`compile_commands.json`ファイルを生成するビルドジョブは、`gitlab-advanced-sast-cpp`ジョブが使用するために、[ジョブアーティファクト](../../../ci/jobs/job_artifacts.md)としてエクスポートする必要があります:

```yaml
variables:
  SAST_COMPILATION_DATABASE: build/compile_commands.json

<YOUR-BUILD-JOB-NAME>:
  image: ubuntu:24.04
  before_script:
    - apt update -qq && apt install -y -qq cmake build-essential
  script:
    - mkdir -p build
    - cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    - make -j$(nproc)
  artifacts:
    paths:
      - build/compile_commands.json # Pass the CDB file to the gitlab-advanced-sast-cpp job
```

または、[CDBのキャッシュ](#caching-a-cdb)をレビューします。

### 最適化: 効率性のための並列実行 {#optimization-parallel-execution-for-efficiency}

CDBを複数のパーティションに分割することにより、アナライザーを並列実行できます。[`GitLab Advanced SAST CPP`リポジトリ](https://gitlab.com/gitlab-org/security-products/demos/sast/gitlab-advanced-sast-cpp-templates/-/blob/main/templates/scripts.yml)は、これに役立つヘルパースクリプトを提供します。

1. スクリプトを含めます:

   ```yaml
   include:
     - project: "gitlab-org/security-products/demos/sast/gitlab-advanced-sast-cpp-templates"
       file: "templates/scripts.yml"
   ```

1. ヘルパースクリプトを参照して、ビルドジョブでCDBを分割します:

   ```yaml
   <YOUR-BUILD-JOB-NAME>:
     script:
       - <your-script to generate the CDB>
       - !reference [.gitlab-advanced-sast-cpp-scripts]
       - split_cdb "${BUILD_DIR}" 1 4 # Split into 4 fragments
     artifacts:
       paths:
         - ${BUILD_DIR} # Pass the split CDB files to the parallelized gitlab-advanced-sast-cpp jobs
   ```

   {{< alert type="note" >}}`split_cdb`は、`${BUILD_DIR}/compile_commands.json`を読み取るようにハードコードされています。`split_cdb`を呼び出す前に、ビルドがこの正確な場所にCDBを生成することを確認してください。{{< /alert >}}

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

   - `parallel: 4`は、4つのジョブにわたって実行をシャードします。
   - `${CI_NODE_INDEX}`（1、2、3、4）は、正しいCDBフラグメントを選択します。
   - `needs`は、アナライザージョブがビルドジョブによって生成されたアーティファクトを受信することを保証します。

この設定では、ビルドジョブは1つの`compile_commands.json`を生成します。`split_cdb`スクリプトは複数のパーティションを作成し、アナライザージョブは並列実行され、各ジョブが1つのパーティションを処理します。

## ルールセットの設定 {#ruleset-configuration}

GitLab高度なSAST CPPは、[カスタムルールセット](customize_rulesets.md)をサポートします。ここで、「ルール」はGitLab高度なSAST CPPチェッカーです。

カスタムルールセットは、[パススルー](customize_rulesets.md#build-a-custom-configuration-using-a-passthrough-chain-for-semgrep) （[`CodeChecker`設定ファイル](https://github.com/Ericsson/codechecker/blob/master/docs/config_file.md)で構成される）で作成できます。

パススルー設定は、次のように処理されます:

- `targetDir`と`target`は無視されます。パススルーを処理した後、結果のフラグは`CodeChecker`に直接渡されます
- `overwrite`モードは設定全体を置き換え、`append`モードはフラグを追加します
- 特定の`CodeChecker`フラグはカスタマイズできません。アナライザーフラグ`-o`、`--output`、および解析フラグ`-o, --output, -e, --export`などです
- `server`と`store`の設定項目は無視されます

たとえば、次の`.gitlab/sastconfig.toml`があるとします:

```toml
[gitlab-advanced-sast-cpp]
    description = "My ruleset"

    [[gitlab-advanced-sast-cpp.passthrough]]
        # replace the GitLab default configuration with my own
        mode  = "overwrite"
        type  = "url"
        value = "https://example.com/gitlab-advanced-sast-cpp.yaml"

    [[gitlab-advanced-sast-cpp.passthrough]]
        # append flags from a file in the current repository
        mode  = "append"
        type  = "file"
        value = "gitlab-advanced-sast-cpp.yml"
```

次のコンテンツが`https://example.com/gitlab-advanced-sast-cpp.yaml`にあるとします:

```yaml
analyzer:
  - --disable-all
  - --enable=core.DivideZero
```

および`gitlab-advanced-sast-cpp.yml`を含む:

```yaml
analyzer:
  - --enable=core.CallAndMessage
```

有効な結果の設定は次のようになります:

```yaml
analyzer:
  - --disable-all
  - --enable=core.DivideZero
  - --enable=core.CallAndMessage
```

## トラブルシューティング {#troubleshooting}

### `cdb-rebase`を使用したパスのリベース {#rebasing-paths-with-cdb-rebase}

CDB内のパスがCI/CDジョブのコンテナパスと一致しない場合は、[cdb-rebase](https://gitlab.com/gitlab-org/security-products/analyzers/clangsa/-/tree/main/cmd/cdb-rebase)で調整します。

インストール:

```shell
go install gitlab.com/gitlab-org/secure/tools/cdb-rebase@latest
```

バイナリは`$GOPATH/bin`または`$HOME/go/bin`にインストールされます。このディレクトリが`PATH`にあることを確認してください。

使用例:

```shell
cdb-rebase compile_commands.json /host/path /container/path > rebased_compile_commands.json
```

### CDBを修正する {#fixing-the-cdb}

ビルド環境がスキャン環境と異なる場合、生成されたCDBの調整が必要になる場合があります。[jq](https://jqlang.org)を使用して変更するか、[事前定義されたヘルパースクリプト](https://gitlab.com/gitlab-org/security-products/demos/sast/gitlab-advanced-sast-cpp-templates/-/blob/main/templates/scripts.yml)のシェル関数である`cdb_append`を使用します。

`cdb_append`は、コンパイラオプションを既存のCDBに追加します。以下を受け入れます:

- 最初の引数: `compile_commands.json`を含むフォルダー
- 後続の引数: 追加する追加のコンパイラオプション

CI/CDの例:

```yaml
include:
  - project: "gitlab-org/security-products/demos/sast/gitlab-advanced-sast-cpp-templates"
    file: "templates/scripts.yml"

<YOUR-BUILD-JOB-NAME>:
  script:
    - !reference [.gitlab-advanced-sast-cpp-scripts]
    - <your-script to generate the CDB>
    - cdb_append "${BUILD_DIR}" "-I'$PWD/include-cache'" "-Wno-error=register"
```

### CDBをキャッシュする {#caching-a-cdb}

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

完全な例については、デモプロジェクト[`cached-cdb`](https://gitlab.com/gitlab-org/security-products/demos/experiments/advanced-sast-cpp/cached-db)を参照してください。

### CDB内の絶対パスを処理する {#handling-absolute-paths-in-a-cdb}

[デモプロジェクト](https://gitlab.com/gitlab-org/security-products/demos/experiments/advanced-sast-cpp/cached-db/-/blob/1a36792b744d7a6ad396a8ac8114ca8947e45b62/.gitlab-ci.yml#L27)では、`bear`はDockerジョブの[ビルドディレクトリ](https://docs.gitlab.com/runner/configuration/advanced-configuration/#default-build-directory)から実行されます。CDBのパスは絶対パスであり、[/builds/$CI_PROJECT_PATH](../../../ci/variables/predefined_variables.md)に基づいています。アナライザージョブ`gitlab-advanced-sast-cpp`は同じ場所で実行されるため、パスは正しいです。

スキャン中にCDBが利用できないパスで生成された場合は、リベースする必要があります。アナライザーイメージに含まれている`cdb-rebase`ツールは、`directory`、`file`、および`output`パスを書き換えます。

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

完全なデモンストレーションについては、[cdb-rebase-demo](https://gitlab.com/gitlab-org/security-products/demos/experiments/advanced-sast-cpp/cdb-rebase-demo)を参照してください

単純なパスのリベースを超えて、`cdb-rebase`はビルド環境とスキャン環境の間でインクルードファイルを管理することもできます:

- 外部ヘッダーをキャッシュします: `--include-cache`を使用すると、ソースツリーの外部にあるヘッダーはポータブルキャッシュにコピーされます。
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

`cde-rebase`ツールはGoがインストールされている環境でも使用できるため、生成時にCDBをリベースすることができます（例：

```shell
go install gitlab.com/gitlab-org/security-products/analyzers/clangsa/cmd/cdb-rebase@latest
bear -o compile_commands_abs.json -- make
cdb-rebase -i compile_commands_abs.json -o compile_commands.json -s "$PWD" -d .
```

注: 上記の`go install`コマンドは、`cdb-rebase`を`GOBIN`パスにインストールします。これは、`go env GOBIN`で確認できます。

### ヘッダーファイルがないために、スキャンのカバレッジが部分的になる {#partial-scan-coverage-due-to-missing-header-files}

スキャンジョブで必要なシステムまたはサードパーティのヘッダーファイルが使用できない場合、スキャンのカバレッジが部分的になることがあります。ビルドジョブ中にインストールされたヘッダーは、明示的にスキャンジョブに転送し、コンパイルデータベースに記録されているインクルードパスを介して解決できるようにする必要があります。

一般的な方法の1つは、必要なヘッダーをキャッシュし、コンパイルデータベースを更新してそれらを参照することです:

```shell
# Create and populate an include cache
mkdir -p include-cache
dpkg -L <build-dependency-packages> | sed -n 's:^/usr/include/::p' > headers.txt
rsync -a --files-from=headers.txt /usr/include/ include-cache/

# Add cached headers to compile flags
cdb_append . "-I'$PWD/include-cache'"
```

完全なデモンストレーションについては、[例](https://gitlab.com/gitlab-org/security-products/demos/experiments/advanced-sast-cpp/OpenSceneGraph/-/merge_requests/4)を参照してください。
