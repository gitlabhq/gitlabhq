---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: さまざまな環境におけるGitLab CI/CD変数の使用法と展開。
title: 変数を使用できる場所
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[CI/CD変数](_index.md)ドキュメントで説明されているように、さまざまな変数を定義できます。すべてのGitLab CI/CD機能に使用できる変数もありますが、使用範囲がある程度制限されているものもあります。

このドキュメントでは、さまざまなタイプの変数をどこでどのように使用できるかについて説明します。

## 変数の使用 {#variables-usage}

定義された変数は、次の2つの場所で使用できます:

1. GitLab側（`.gitlab-ci.yml`ファイル内）。
1. GitLab Runner側（`config.toml`内）。

### `.gitlab-ci.yml`ファイル {#gitlab-ciyml-file}

{{< history >}}

- `CI_ENVIRONMENT_SLUG`を除き、`CI_ENVIRONMENT_*`変数のサポートがGitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128694)されました。

{{< /history >}}

| 定義                                                              | 展開可否 | 展開場所        | 説明 |
|:------------------------------------------------------------------------|:-----------------|:-----------------------|:------------|
| [`after_script`](../yaml/_index.md#after_script)                        | 可              | スクリプト実行Shell | 変数の展開は、[実行Shell環境](#execution-shell-environment)が行います。 |
| [`artifacts:name`](../yaml/_index.md#artifactsname)                     | 可              | Runner                 | 変数の展開は、GitLab Runnerの[内部変数展開メカニズム](#gitlab-runner-internal-variable-expansion-mechanism)が行います。 |
| [`artifacts:paths`](../yaml/_index.md#artifactspaths)                   | 可              | Runner                 | 変数の展開は、GitLab Runnerの[内部変数展開メカニズム](#gitlab-runner-internal-variable-expansion-mechanism)が行います。 |
| [`artifacts:exclude`](../yaml/_index.md#artifactsexclude)               | 可              | Runner                 | 変数の展開は、GitLab Runnerの[内部変数展開メカニズム](#gitlab-runner-internal-variable-expansion-mechanism)が行います。 |
| [`before_script`](../yaml/_index.md#before_script)                      | 可              | スクリプト実行Shell | 変数の展開は、[実行Shell環境](#execution-shell-environment)が行います。 |
| [`cache:key`](../yaml/_index.md#cachekey)                               | 可              | Runner                 | 変数の展開は、GitLab Runnerの[内部変数展開メカニズム](#gitlab-runner-internal-variable-expansion-mechanism)が行います。 |
| [`cache:paths`](../yaml/_index.md#cachepaths)                           | 可              | Runner                 | 変数の展開は、GitLab Runnerの[内部変数展開メカニズム](#gitlab-runner-internal-variable-expansion-mechanism)が行います。 |
| [`cache:policy`](../yaml/_index.md#cachepolicy)                         | 可              | Runner                 | 変数の展開は、GitLab Runnerの[内部変数展開メカニズム](#gitlab-runner-internal-variable-expansion-mechanism)が行います。 |
| [`environment:name`](../yaml/_index.md#environmentname)                 | 可              | GitLab                 | `environment:url`と似ていますが、変数展開は次の変数をサポートしていません:<br/><br/>- `CI_ENVIRONMENT_*`変数。<br/>- [永続変数](#persisted-variables)。 |
| [`environment:url`](../yaml/_index.md#environmenturl)                   | 可              | GitLab                 | 変数の展開は、GitLabの[内部変数展開メカニズム](#gitlab-internal-variable-expansion-mechanism)が行います。<br/><br/>ジョブに定義されたすべての変数（プロジェクト/グループ変数、`.gitlab-ci.yml`からの変数、トリガーからの変数、パイプラインスケジュールからの変数）がサポートされています。<br/><br/>GitLab Runnerの`config.toml`で定義された変数と、ジョブの`script`で作成された変数はサポートされていません。 |
| [`environment:deployment_tier`](../yaml/_index.md#environmentdeployment_tier) | 可              | GitLab                 | `environment:url`と似ていますが、変数展開は次の変数をサポートしていません:<br/><br/>- `CI_ENVIRONMENT_*`変数。<br/>- [永続変数](#persisted-variables)。 |
| [`environment:auto_stop_in`](../yaml/_index.md#environmentauto_stop_in) | 可              | GitLab                 | 変数の展開は、GitLabの[内部変数展開メカニズム](#gitlab-internal-variable-expansion-mechanism)が行います。<br/><br/> 代入される変数の値は、人間が判読可能な自然言語形式の期間である必要があります。詳細については、[サポートされている値](../yaml/_index.md#environmentauto_stop_in)を参照してください。 |
| [`environment:kubernetes:agent`](../yaml/_index.md#environmentkubernetes) | 可            | GitLab                 | `environment:url`と似ていますが、変数展開は次の変数をサポートしていません:<br/><br/>- `CI_ENVIRONMENT_*`変数。<br/>- [永続変数](#persisted-variables)。 |
| [`environment:kubernetes:namespace`](../yaml/_index.md#environmentkubernetes) | 可        | GitLab                 | `environment:url`と似ていますが、変数展開は次の変数をサポートしていません:<br/><br/>- `CI_ENVIRONMENT_*`変数。<br/>- [永続変数](#persisted-variables)。 |
| [`id_tokens:aud`](../yaml/_index.md#id_tokens)                          | 可              | GitLab                 | 変数の展開は、GitLabの[内部変数展開メカニズム](#gitlab-internal-variable-expansion-mechanism)が行います。変数展開はGitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/414293)されました。 |
| [`image`](../yaml/_index.md#image)                                      | 可              | Runner                 | 変数の展開は、GitLab Runnerの[内部変数展開メカニズム](#gitlab-runner-internal-variable-expansion-mechanism)が行います。 |
| [`include`](../yaml/_index.md#include)                                  | 可              | GitLab                 | 変数の展開は、GitLabの[内部変数展開メカニズム](#gitlab-internal-variable-expansion-mechanism)が行います。<br/><br/>サポートされている変数の詳細については、[includeで変数を使用する](../yaml/includes.md#use-variables-with-include)を参照してください。 |
| [`resource_group`](../yaml/_index.md#resource_group)                    | 可              | GitLab                 | `environment:url`と似ていますが、変数展開は次の変数をサポートしていません:<br/>- `CI_ENVIRONMENT_URL`。<br/>- [永続変数](#persisted-variables)。 |
| [`rules:changes`](../yaml/_index.md#ruleschanges)                       | 不可               | GitLab                 | 変数の展開は、GitLabの[内部変数展開メカニズム](#gitlab-internal-variable-expansion-mechanism)が行います。 |
| [`rules:changes:compare_to`](../yaml/_index.md#ruleschangescompare_to)  | 不可               | GitLab                 | 変数の展開は、GitLabの[内部変数展開メカニズム](#gitlab-internal-variable-expansion-mechanism)が行います。 |
| [`rules:exists`](../yaml/_index.md#rulesexists)                         | 不可               | GitLab                 | 変数の展開は、GitLabの[内部変数展開メカニズム](#gitlab-internal-variable-expansion-mechanism)が行います。 |
| [`rules:if`](../yaml/_index.md#rulesif)                                 | 可              | GitLab                 | 変数の展開は、GitLabの[内部変数展開メカニズム](#gitlab-internal-variable-expansion-mechanism)が行います。 |
| [`script`](../yaml/_index.md#script)                                    | 可              | スクリプト実行Shell | 変数の展開は、[実行Shell環境](#execution-shell-environment)が行います。 |
| [`services:name`](../yaml/_index.md#services)                           | 可              | Runner                 | 変数の展開は、GitLab Runnerの[内部変数展開メカニズム](#gitlab-runner-internal-variable-expansion-mechanism)が行います。 |
| [`services`](../yaml/_index.md#services)                                | 可              | Runner                 | 変数の展開は、GitLab Runnerの[内部変数展開メカニズム](#gitlab-runner-internal-variable-expansion-mechanism)が行います。 |
| [`tags`](../yaml/_index.md#tags)                                        | 可              | GitLab                 | 変数の展開は、GitLabの[内部変数展開メカニズム](#gitlab-internal-variable-expansion-mechanism)が行います。 |
| [`trigger`および`trigger:project`](../yaml/_index.md#trigger)            | 可              | GitLab                 | 変数の展開は、GitLabの[内部変数展開メカニズム](#gitlab-internal-variable-expansion-mechanism)が行います。`trigger:project`の変数展開は、GitLab 15.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/367660)されました。 |
| [`variables`](../yaml/_index.md#variables)                              | 可              | GitLab/Runner          | 変数の展開は、まずGitLabの[内部変数展開メカニズム](#gitlab-internal-variable-expansion-mechanism)が行い、認識されない変数または利用できない変数は、GitLab Runnerの[内部変数展開メカニズム](#gitlab-runner-internal-variable-expansion-mechanism)が展開します。 |
| [`workflow:name`](../yaml/_index.md#workflowname)                       | 可              | GitLab                 | 変数の展開は、GitLabの[内部変数展開メカニズム](#gitlab-internal-variable-expansion-mechanism)が行います。<br/><br/>`workflow`で使用できるすべての変数がサポートされています:<br/>\- プロジェクト/グループ変数。<br/>\- グローバル`variables`および`workflow:rules:variables`（ルールに一致する場合）。<br/>\- 親パイプラインから継承された変数。<br/>\- トリガーからの変数。<br/>\- パイプラインスケジュールからの変数。<br/><br/>GitLab Runner `config.toml`で定義された変数、ジョブで定義された変数、[永続変数](#persisted-variables)はサポートされていません。 |

### `config.toml`ファイル {#configtoml-file}

| 定義                           | 展開可否 | 説明 |
|:-------------------------------------|:-----------------|:------------|
| `runners.environment`                | 可              | 変数の展開は、GitLab Runnerの[内部変数展開メカニズム](#gitlab-runner-internal-variable-expansion-mechanism)が行います |
| `runners.kubernetes.pod_labels`      | 可              | 変数の展開は、GitLab Runnerの[内部変数展開メカニズム](#gitlab-runner-internal-variable-expansion-mechanism)が行います |
| `runners.kubernetes.pod_annotations` | 可              | 変数の展開は、GitLab Runnerの[内部変数展開メカニズム](#gitlab-runner-internal-variable-expansion-mechanism)が行います |

`config.toml`の詳細については、[GitLab Runnerのドキュメント](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)を参照してください。

## 展開メカニズム {#expansion-mechanisms}

次の3つの展開メカニズムがあります:

- GitLab
- GitLab Runner
- 実行Shell環境

### GitLabの内部変数展開メカニズム {#gitlab-internal-variable-expansion-mechanism}

展開対象の部分は、`$variable`、`${variable}`、`%variable%`のいずれかの形式で記述する必要があります。各形式は、どのOS/Shellがジョブを処理するかに関係なく同じように処理されます。これは、Runnerがジョブを取得する前に、GitLabで展開が行われるためです。

#### ネストされた変数展開 {#nested-variable-expansion}

GitLabは、ジョブ変数の値を再帰的に展開してから、Runnerに送信します。例として、次のシナリオについて説明します:

```yaml
- BUILD_ROOT_DIR: '${CI_BUILDS_DIR}'
- OUT_PATH: '${BUILD_ROOT_DIR}/out'
- PACKAGE_PATH: '${OUT_PATH}/pkg'
```

Runnerは、有効で完全な形式のパスを受け取ります。たとえば、`${CI_BUILDS_DIR}`が`/output`の場合、`PACKAGE_PATH`は`/output/out/pkg`になります。

利用できない変数への参照は、そのまま残されます。この場合、Runnerはランタイムに[変数値を展開しようとします](#gitlab-runner-internal-variable-expansion-mechanism)。たとえば、`CI_BUILDS_DIR`のような変数は、Runnerがランタイムにのみ認識します。

### GitLab Runnerの内部変数展開メカニズム {#gitlab-runner-internal-variable-expansion-mechanism}

- サポート対象: プロジェクト/グループ変数、`.gitlab-ci.yml`変数、`config.toml`変数、およびトリガー、パイプラインスケジュール、手動パイプラインからの変数。
- サポート対象外: スクリプト内で定義された変数（例: `export MY_VARIABLE="test"`）。

Runnerは、変数展開にGoの`os.Expand()`メソッドを使用します。つまり、`$variable`および`${variable}`として定義された変数のみを処理します。もう1つ重要な点として、展開は1回しか行われないため、ネストされた変数は、変数の定義の順序によって、またGitLabで[ネストされた変数の展開](#nested-variable-expansion)が有効になっているかどうかによって、動作する場合としない場合があります。

アーティファクトおよびキャッシュのアップロードの場合、Runnerは変数展開にGoの`os.Expand()`ではなく、[mvdan.cc/sh/v3/expand](https://pkg.go.dev/mvdan.cc/sh/v3/expand)を使用します。これは、`mvdan.cc/sh/v3/expand`が[パラメータ展開](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html)をサポートしているためです。

### 実行Shell環境 {#execution-shell-environment}

これは、`script`実行中に発生する展開フェーズです。その動作は、使用されるShell（`bash`、`sh`、`cmd`、PowerShell）によって異なります。たとえば、ジョブの`script`に`echo $MY_VARIABLE-${MY_VARIABLE_2}`という行がある場合、bash/shでは適切に処理されるはずですが（変数が定義されているかどうかに応じて、空の文字列や値に置き換えられる）、Windowsの`cmd`またはPowerShellでは異なる変数構文を使用するため動作しません。

サポート対象:

- `script`では、Shellでデフォルトとして利用可能なすべての変数（たとえば、すべてのbash/sh Shellに存在するはずの`$PATH`）と、GitLab CI/CDで定義されたすべての変数（プロジェクト/グループ変数、`.gitlab-ci.yml`の変数、`config.toml`の変数、トリガーおよびパイプラインスケジュールからの変数）を使用できます。
- `script`では、前の行で定義されたすべての変数も使用できます。したがって、たとえば、`export MY_VARIABLE="test"`のように変数を定義する場合:
  - `before_script`で定義すると、`before_script`の後続の行と、関連する`script`のすべての行で使用できます。
  - `script`で定義すると、`script`の後続の行で使用できます。
  - `after_script`で定義すると、`after_script`の後続の行で使用できます。

`after_script`スクリプトの場合、次のようになります:

- 同じ`after_script`セクション内で、そのスクリプトの前に定義された変数のみを使用できます。
- `before_script`と`script`で定義された変数は使用できません。

このような制限があるのは、`after_script`スクリプトが[別のShellコンテキスト](../yaml/_index.md#after_script)で実行されるためです。

## 永続変数 {#persisted-variables}

一部の定義済み変数は、永続変数と呼ばれます。永続変数のサポート条件は次のとおりです:

- サポート対象: [展開場所](#gitlab-ciyml-file)が次の場所に定義されている場合:
  - Runner。
  - スクリプト実行Shell。
- サポート対象外:
  - [展開場所](#gitlab-ciyml-file)がGitLabに定義されている場合。
  - `rules`[変数式](../jobs/job_rules.md#cicd-variable-expressions)内。

[パイプライントリガージョブ](../yaml/_index.md#trigger)は、ジョブレベルの永続変数は使用できませんが、パイプラインレベルの永続変数は使用できます。

永続変数の一部にはトークンが含まれており、セキュリティ上の理由から、一部の定義では使用できません。

パイプラインレベルの永続変数:

- `CI_PIPELINE_ID`
- `CI_PIPELINE_URL`

ジョブレベルの永続変数:

- `CI_DEPLOY_PASSWORD`
- `CI_DEPLOY_USER`
- `CI_JOB_ID`
- `CI_JOB_STARTED_AT`
- `CI_JOB_TOKEN`
- `CI_JOB_URL`
- `CI_PIPELINE_CREATED_AT`
- `CI_REGISTRY_PASSWORD`
- `CI_REGISTRY_USER`
- `CI_REPOSITORY_URL`

## 環境スコープを持つ変数 {#variables-with-an-environment-scope}

環境スコープで定義された変数がサポートされています。たとえば、`review/staging/*`のスコープで定義された変数`$STAGING_SECRET`がある場合、一致する変数式に基づいて、次のような動的環境を使用するジョブが作成されます:

```yaml
my-job:
  stage: staging
  environment:
    name: review/$CI_JOB_STAGE/deploy
  script:
    - 'deploy staging'
  rules:
    - if: $STAGING_SECRET == 'something'
```
