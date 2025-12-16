---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD式
---

CI/CD式を使用すると、特殊なコンテキストで変数と入力を参照することにより、CI/CDパイプラインで動的な設定が有効になります。パイプラインの作成前に、GitLabはパイプライン設定内の式を評価します。

## Configuration式 {#configuration-expressions}

Configuration式は、`$[[ ]]`構文を使用し、パイプラインの作成時（コンパイル時）に評価されます。これによって、さまざまなコンテキストに基づいて動的な設定が可能になります。

すべての設定式は、以下の特性を共有しています:

- **コンパイル時評価**: 値は、ジョブの実行中ではなく、パイプライン設定が作成されるときに解決されます。多数の式を使用すると、パイプラインの作成時間が長くなる可能性がありますが、ジョブの実行時間には影響しません。
- **静的解決**: 動的ロジックを実行したり、ランタイムジョブの状態にアクセスしたりすることはできません。

Configuration式は、値にアクセスするためのさまざまなコンテキストをサポートしています:

| コンテキスト                           | 構文                     | 利用可否設定 | 目的 |
|-----------------------------------|----------------------------|--------------|---------|
| [入力コンテキスト](#inputs-context) | `$[[ inputs.INPUT_NAME ]]` | GitLab 17.0  | 再利用可能な設定でCI/CDの入力機能を参照してください。 |
| [マトリックスコンテキスト](#matrix-context) | `$[[ matrix.IDENTIFIER ]]` | GitLab 18.6 (ベータ)  | ジョブの依存関係にある`parallel:matrix`識別子を参照します。 |

### 入力コンテキスト {#inputs-context}

{{< history >}}

- GitLab 15.11でベータ機能として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391331)されました。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062)になりました。

{{< /history >}}

`inputs.`コンテキストを使用して、`$[[ inputs.INPUT_NAME ]]`構文を使用して、再利用可能な設定で[GitLab CI/CDの入力機能](../inputs/_index.md)を参照します。

例: 

```yaml
spec:
  inputs:
    environment:
      default: production
    job-stage:
      default: test
---
scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

`input.`式には、次の特性があります:

- 型の検証: 検証を備えた`string`、`number`、`boolean`、および`array`型をサポートします。入力検証は、無効な値でのパイプラインの作成を防ぎます。
- 関数のサポート: `expand_vars`や`truncate`のような定義済みの関数は値を操作できます。
- スコープ: 定義されたファイルで使用可能であるか、`include:inputs`で明示的に渡されます。

### マトリックスコンテキスト {#matrix-context}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/423553)されました。この機能は[ベータ版](../../policy/development_stages_support.md#beta)です。

{{< /history >}}

[`matrix.`コンテキスト](matrix_expressions.md)を使用して、`$[[ matrix.IDENTIFIER ]]`構文を使用して[`parallel:matrix`](_index.md#parallelmatrix)値を参照します。ジョブの依存関係で使用して、`parallel:matrix`ジョブ間の動的な1対1マッピングを有効にします。

例: 

```yaml
.os-arch-matrix:
  parallel:
    matrix:
      - OS: [ubuntu, alpine]
        ARCH: [amd64, arm64]

build:
  script: echo "Testing $OS on $ARCH"
  parallel: !reference [.os-arch-matrix, parallel]

test:
  script: echo "Testing $OS on $ARCH"
  parallel: !reference [.os-arch-matrix, parallel]
  needs:
    - job: build
      parallel:
        matrix:
          - OS: ['$[[ matrix.OS ]]']
            ARCH: ['$[[ matrix.ARCH ]]']
```

`matrix.`式には、次の特性があります:

- ジョブレベルの`parallel:matrix`にスコープされます: 現在のジョブの値のみを参照できます。
- 自動マッピング: ステージ間でマトリックスジョブ間に1対1の依存関係を作成します

## 関連トピック {#related-topics}

- [GitLab CI/CDの入力機能](../inputs/_index.md)
- [マトリックス式](matrix_expressions.md)
- [YAMLの最適化](yaml_optimization.md)
