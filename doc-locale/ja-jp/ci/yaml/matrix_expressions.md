---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CDでのジョブマトリックス式
---

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423553)されました。この機能は[ベータ版](../../policy/development_stages_support.md#beta)です。

{{< /history >}}

マトリックス式を使用すると、[`parallel:matrix`](_index.md#parallelmatrix)識別子に基づいて動的なジョブ依存関係を有効にし、`parallel:matrix`ジョブ間に1対1マッピングを作成できます。

マトリックス式には、[入力式](expressions.md#inputs-context)と比較していくつかの制限があります:

- コンパイル時のみ: 識別子は、ジョブの実行中ではなく、パイプラインの作成時に解決されます。
- 文字列の置換のみ: 複雑なロジックや変換はありません。
- マトリックス識別子のみ: CI/CD変数または入力を参照できません。

## 構文 {#syntax}

マトリックス式は、`$[[ matrix.IDENTIFIER ]]`構文を使用して、ジョブ依存関係の`parallel:matrix`識別子を参照します。例: 

```yaml
needs:
  - job: build
    parallel:
      matrix:
        - OS: ['$[[ matrix.OS ]]']
          ARCH: ['$[[ matrix.ARCH ]]']
```

### `needs:parallel:matrix`のマトリックス式 {#matrix-expressions-in-needsparallelmatrix}

マトリックス式を使用すると、ジョブ依存関係のマトリックス識別子を動的に参照し、すべての組み合わせを手動で指定しなくても、マトリックスジョブ間に1対1マッピングを確立できます。

例: 

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."
  parallel:
    matrix:
      - PROVIDER: [aws, gcp]
        STACK: [monitoring, app1, app2]

linux:test:
  stage: test
  script: echo "Testing linux..."
  parallel:
    matrix:
      - PROVIDER: [aws, gcp]
        STACK: [monitoring, app1, app2]
  needs:
    - job: linux:build
      parallel:
        matrix:
          - PROVIDER: ['$[[ matrix.PROVIDER ]]']
            STACK: ['$[[ matrix.STACK ]]']
```

この例では、すべての`linux:build`ジョブと`linux:test`ジョブの間に1対1の依存関係マッピングが作成されます:

- `linux:test: [aws, monitoring]`は`linux:build: [aws, monitoring]`に依存します
- `linux:test: [aws, app1]`は`linux:build: [aws, app1]`に依存します
- すべての6つの`parallel:matrix`値の組み合わせに同じことが当てはまります。

`matrix.`式を使用すると、各マトリックスの組み合わせを手動で指定する必要はありません。

マトリックス式は、現在のジョブのマトリックス設定からのみ識別子を参照します。

### YAMLアンカーを使用して`parallel:matrix`設定を再利用する {#use-yaml-anchors-to-reuse-parallelmatrix-configuration}

[YAMLアンカー](yaml_optimization.md#anchors)を使用すると、複雑な`parallel:matrix`設定と依存関係を持つ複数のジョブにわたって`parallel:matrix`設定を再利用できます。

例: 

```yaml
stages:
  - compile
  - test
  - deploy

.build_matrix: &build_matrix
  parallel:
    matrix:
      - OS: ["ubuntu", "alpine"]
        ARCH: ["amd64", "arm64"]
        VARIANT: ["slim", "full"]

compile_binary:
  stage: compile
  script:
    - echo "Compiling for $OS-$ARCH-$VARIANT"
  <<: *build_matrix

integration_test:
  stage: test
  script:
    - echo "Testing $OS-$ARCH-$VARIANT"
  <<: *build_matrix
  needs:
    - job: compile_binary
      parallel:
        matrix:
          - OS: ['$[[ matrix.OS ]]']
            ARCH: ['$[[ matrix.ARCH ]]']
            VARIANT: ['$[[ matrix.VARIANT ]]']

deploy_artifact:
  stage: deploy
  script:
    - echo "Deploying $OS-$ARCH-$VARIANT"
  <<: *build_matrix
  needs:
    - job: integration_test
      parallel:
        matrix:
          - OS: ['$[[ matrix.OS ]]']
            ARCH: ['$[[ matrix.ARCH ]]']
            VARIANT: ['$[[ matrix.VARIANT ]]']
```

この設定では、24個のジョブが作成されます: 各ステージングの8つのジョブ（2つの`OS`×2つの`ARCH`×2つの`VARIANT`の組み合わせ）で、ステージング間に1対1の依存関係があります。

### 値のサブセットを使用する {#use-a-subset-of-values}

マトリックス式を特定の値と組み合わせて、依存関係の選択的なサブセットを作成できます:

```yaml
stages:
  - prepare
  - build
  - test

.full_matrix: &full_matrix
  parallel:
    matrix:
      - PLATFORM: ["linux", "windows", "macos"]
        VERSION: ["16", "18", "20"]

.platform_only: &platform_only
  parallel:
    matrix:
      - PLATFORM: ["linux", "windows", "macos"]

prepare_env:
  stage: prepare
  script:
    - echo "Preparing $PLATFORM with Node.js $VERSION"
  <<: *full_matrix

build_project:
  stage: build
  script:
    - echo "Building on $PLATFORM"
  needs:
    - job: prepare_env
      parallel:
        matrix:
          - PLATFORM: ['$[[ matrix.PLATFORM ]]']
            VERSION: ["18"]  # Only depend on Node.js 18 preparations
  <<: *platform_only
```

この例では、次のようになります。

- `prepare_env`は`parallel:matrix`を使用して9つのジョブを作成します: 3つの`PLATFORM`×3つの`VERSIONS`。
- `build_project`は`parallel:matrix`を使用して3つのジョブを作成します: 3つの`PLATFORM`値のみ。
- 各`build_project`ジョブは、すべてのプラットフォーム（`PLATFORM`）のNode.js `18`（`VERSION`）のみに依存します。

または、[すべての依存関係を手動で設定する](../jobs/job_control.md#specify-a-parallelized-job-using-needs-with-multiple-parallelized-jobs)こともできます。

## 関連トピック {#related-topics}

- [マトリックスを使用した並列ジョブ](../jobs/job_control.md#parallelize-large-jobs)
- [`needs`を使用したジョブ依存関係](needs.md)
- [CI式](expressions.md)の概要
- [YAMLの最適化](yaml_optimization.md)
