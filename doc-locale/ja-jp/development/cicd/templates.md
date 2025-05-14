---
stage: Verify
group: Pipeline Authoring
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GitLab CI/CDテンプレートの作成ガイド（非推奨）
---

{{< alert type="note" >}}

GitLabは、[CI/CDカタログ](../../ci/components/_index.md#cicd-catalog)の導入により、コードベースに対する新たなCI/CDテンプレートのコントリビュートの受け付けを終了しました。それに代わるものとして、カタログ用の[CI/CDコンポーネント](../../ci/components/_index.md)をチームメンバーが作成することを推奨します。この移行に伴い、共有のCI/CDリソースのモジュール性と保守性が向上します。また、新たなCI/CDテンプレートをコントリビュートする際の複雑性を回避できます。既存のテンプレートを更新する必要がある場合は、それに対応するCI/CDコンポーネントも更新する必要があります。CI/CDテンプレートに対応するコンポーネントがまだ存在しない場合は、[対応するコンポーネントの作成](components.md)を検討してください。これを行うことで、GitLabの新しい開発プラクティスに沿って、テンプレートとコンポーネントの機能の同期を保つことができます。

{{< /alert >}}

このドキュメントでは、[GitLabのCI/CDテンプレート](../../ci/examples/_index.md#cicd-templates)の作成方法について説明します。

## CI/CDテンプレートの要件

CI/CDテンプレートの新規作成または更新の際、マージリクエスト（MR）を送信する前に以下のことを行う必要があります。

- テンプレートを適切な[ディレクトリ](#template-directories)に配置します。
- [CI/CDテンプレートの作成ガイドライン](#template-authoring-guidelines)に従います。
- テンプレートの名前を`*.gitlab-ci.yml`形式に沿って設定します。
- 有効な[`.gitlab-ci.yml`構文](../../ci/yaml/_index.md)を用います。[CI/CD lintツール](../../ci/yaml/lint.md)を使って、構文の有効性を検証します。
- [テンプレートメトリクスを追加](#add-metrics)します。
- マージリクエストでユーザー向けの変更が生じる場合には、[変更履歴](../changelog.md)を含めます。
- [テンプレートレビュープロセス](#contribute-cicd-template-merge-requests)に従います。
- （オプション、ただし強く推奨）レビュアーがアクセス可能なサンプルのGitLabプロジェクトで、テンプレートをテストします。テンプレートが必要とするデータや設定は、レビュアー自身で作成できない場合があります。サンプルのプロジェクトがあると、レビュアーがテンプレートの正確性を検証する際に役立ちます。レビュー用のマージリクエストの送信に先立ち、サンプルのプロジェクトでパイプラインを成功させておく必要があります。

## テンプレートディレクトリ

テンプレートファイルはすべて`lib/gitlab/ci/templates`に保存します。一般的なテンプレートは、このディレクトリに保存します。ただし、一部の種類のテンプレートは、それぞれ専用の特定のディレクトリに保存します。[新しいファイルUIでテンプレートを選択](#make-sure-the-new-template-can-be-selected-in-ui)できるかどうかは、テンプレートのあるディレクトリによって決まります。

| サブディレクトリ  | UIで選択可能か | テンプレートの種類 |
|----------------|------------------|---------------|
| `/*`（ルート）    | 可              | 一般的なテンプレート。 |
| `/AWS/*`       | 不可               | クラウドデプロイメント（AWS）関連のテンプレート。 |
| `/Jobs/*`      | 不可               | Auto DevOps関連のテンプレート。 |
| `/Pages/*`     | 可              | GitLab Pagesで静的サイトジェネレーターを使用するためのサンプルのテンプレート。 |
| `/Security/*`  | 可              | セキュリティスキャナー関連のテンプレート。 |
| `/Terraform/*` | 不可               | Infrastructure as Code（Terraform）関連のテンプレート。 |
| `/Verify/*`    | 可              | テスト機能に関連するテンプレート。 |
| `/Workflows/*` | 不可               | 「`workflow:`」キーワードを使用するためのサンプルのテンプレート。 |

## テンプレート作成ガイドライン

以下のガイドラインに従って、標準に準拠したテンプレートを送信するようにしてください。

### テンプレートの種類

テンプレートには2つの種類があり、それによってテンプレートの記述方法と使用方法が異なります。テンプレートの記述方式は、次の2種類のいずれかに1つに従う必要があります。

**パイプラインテンプレート**は、プロジェクトの構造や言語などに合わせた、エンドツーエンドのCI/CDワークフローを提供します。通常、他の`.gitlab-ci.yml`ファイルが存在しないプロジェクトで、独立して使用します。

パイプラインテンプレートを作成する場合:

- `image`や`before_script`などの[グローバルキーワード](../../ci/yaml/_index.md#global-keywords)を、テンプレート上部の[`default`](../../ci/yaml/_index.md#default)セクションに配置します。
- 既存の`.gitlab-ci.yml`ファイルで`includes`キーワードを使用してテンプレートを作成するかどうかを、[コードコメント](#explain-the-template-with-comments)で明確に指定します。

**ジョブテンプレート**は、既存のCI/CDワークフローに追加できる特定のジョブを提供し、特定のタスクを実行します。通常は[`includes`](../../ci/yaml/_index.md#global-keywords)キーワードを使用して、既存の`.gitlab-ci.yml`ファイルに追加して使用します。またコンテンツをコピーして既存の`.gitlab-ci.yml`ファイルに貼り付けることもできます。

ユーザーがほとんど、またはまったく変更せずに現在のパイプラインに追加できるよう、ジョブテンプレートを設定します。他のパイプライン設定と競合するリスクを軽減するように設定する必要があります。

ジョブテンプレートを作成する場合:

- [グローバル](../../ci/yaml/_index.md#global-keywords)キーワードや[`default`](../../ci/yaml/_index.md#default)キーワードを使用しないでください。ルート`.gitlab-ci.yml`にテンプレートが含まれている場合、グローバルキーワードやデフォルトキーワードが上書きされ、予期しない動作が起こることがあります。ジョブテンプレートに特定のステージが必要な場合は、ユーザーがステージをメインの`.gitlab-ci.yml`設定に手動で追加する必要があることを、コードコメントで説明します。
- `includes`キーワードを使用するようにテンプレートを設計しているか、既存の設定にコピーするように設計しているかを、[コードコメント](#explain-the-template-with-comments)に明記します。
- 最新バージョンと安定バージョンでテンプレートを[バージョニング](#versioning)し、[下位互換性](#backward-compatibility)の問題の回避を検討します。このタイプのテンプレートのメンテナンスはより複雑になります。`includes`でインポートされたテンプレートの変更は、テンプレートを使用するすべてのプロジェクトのパイプラインを中断する場合があるためです。

テンプレートを作成する際に留意すべきその他のポイント:

| テンプレート設計ポイント                               | パイプラインテンプレート | ジョブテンプレート |
|------------------------------------------------------|--------------------|---------------|
| `stages`を含むグローバルキーワードの使用         | 可                | 不可            |
| ジョブの定義                                     | 可                | 可           |
| 新しいファイルUI内での選択                   | 可                | 不可            |
| `include`で他のジョブテンプレートを含める       | 可                | 不可            |
| `include`で他のパイプラインテンプレートを含める | 不可                 | 不可            |

### 構文のガイドライン

テンプレートをより簡単に追跡できるように、テンプレートはすべて一貫したフォーマットで、明確な構文スタイルを使用する必要があります。

各ジョブの`before_script`、`script`、`after_script`キーワードは [ShellCheck](https://www.shellcheck.net/)を使用してLintし、可能な限り[Shellスクリプトの標準とスタイルガイドライン](../shell_scripting_guide/_index.md)を遵守する必要があります。

ShellCheck は、[Bash](https://www.gnu.org/software/bash/)を使用して実行するようスクリプトを設計していることを想定しています。Bash ShellCheckルールと互換性のないシェルにスクリプトを使用するテンプレートは、ShellCheck Lintから除外できます。スクリプトを除外するには、[`scripts/lint_templates_bash.rb`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/scripts/lint_templates_bash.rb)の`EXCLUDED_TEMPLATES`リストに追加します。

#### デフォルトブランチをハードコード化しない

ハードコード化した`main`ブランチの代わりに[`$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH`](../../ci/variables/predefined_variables.md)を使用し、`master`は絶対に使用しないでください。

```yaml
job:
  rules:
    if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  script:
    echo "example job"
```

#### `only`または`except`の代わりに`rules`を使用する

可能な限り[`only`や`except`](../../ci/yaml/_index.md#only--except)の使用を避けてください。[`rules`](../../ci/yaml/_index.md#rules)が推奨構文になり、onlyやexceptはもう使用しません。

```yaml
job2:
  script:
    - echo
  rules:
    - if: $CI_COMMIT_BRANCH
```

#### 長いコマンドを分割する

コマンドが非常に長い場合、または`-o`や`--option`のようなコマンドラインフラグが多い場合:

- フラグを複数行のコマンドに分割して、コマンドの各部を簡単に見られるようにします。
- フラグに長い名前が利用可能な場合は、それを使用します。

たとえば、`docker run --e SOURCE_CODE="$PWD" -v "$PWD":/code -v /var/run/docker.sock:/var/run/docker.sock "$CODE_QUALITY_IMAGE" /code`のような短いCLIフラグを持つ長いコマンドの場合:

```yaml
job1:
  script:
    - docker run
        --env SOURCE_CODE="$PWD"
        --volume "$PWD":/code
        --volume /var/run/docker.sock:/var/run/docker.sock
        "$CODE_QUALITY_IMAGE" /code
```

`|`や`>`YAMLオペレータを使用して[複数行コマンドを分割](../../ci/yaml/script.md#split-long-commands)することもできます。

### コメントでテンプレートを説明する

新しいファイルメニューからテンプレートの内容にアクセスできますが、それがテンプレートに関する情報をユーザーが確認できる唯一の場所である可能性があります。テンプレートの動作はテンプレート自体で明確にドキュメント化することが重要です。

次のガイドラインでは、すべてのテンプレート送信で想定される基本的なコメントについて説明します。コメントがユーザーや[テンプレートのレビュアー](#contribute-cicd-template-merge-requests)に役立つと思われる場合は、必要に応じてコメントを追加します。

#### 要件と期待値を説明する

ファイルの先頭にある`#`コメントで、テンプレートの使用方法の詳細を提示します。これには以下が含まれます。

- リポジトリ/プロジェクトの要件。
- 期待される動作。
- テンプレートを使用する前にユーザーが編集する必要がある箇所。
- テンプレートを設定ファイルにコピーして貼り付けるか、既存のパイプラインで`include`キーワードを用いてテンプレートを使用するか。
- 変数をプロジェクトの CI/CD 設定に保存する必要があるか。

```yaml
# Use this template to publish an application that uses the ABC server.
# You can copy and paste this template into a new `.gitlab-ci.yml` file.
# You should not add this template to an existing `.gitlab-ci.yml` file by using the `include:` keyword.
#
# Requirements:
# - An ABC project with content saved in /content and tests in /test
# - A CI/CD variable named ABC-PASSWORD saved in the project CI/CD settings. The value
#   should be the password used to deploy to your ABC server.
# - An ABC server configured to listen on port 12345.
#
# You must change the URL on line 123 to point to your ABC server and port.
#
# For more information, see https://gitlab.com/example/abcserver/README.md

job1:
  ...
```

#### 変数がテンプレートの動作にどう影響するかを説明する

テンプレートが変数を使用する場合は、最初に定義している`#`コメントでその説明をします。変数が自明である場合は、コメントを省略できます。

```yaml
variables:                        # Good to have a comment here, for example:
  TEST_CODE_PATH: <path/to/code>  # Update this variable with the relative path to your Ruby specs

job1:
  variables:
    ERROR_MESSAGE: "The $TEST_CODE_PATH path is invalid"  # (No need for a comment here, it's already clear)
  script:
    - echo ${ERROR_MESSAGE}
```

#### ローカル変数以外の変数には、すべて大文字の名前を使用する

変数をCI/CD設定または`variables`キーワードを介して提供することを想定している場合、その変数には、アンダースコア（`_`）で単語を区切ったすべて大文字の名前を使用する必要があります。

```yaml
.with_login:
  before_script:
    # SECRET_TOKEN should be provided via the project settings
    - echo "$SECRET_TOKEN" | docker login -u my-user --password-stdin my-registry
```

小文字の名前は、`script`キーワードの1つでローカルに定義している変数にオプションとして使用できます。

```yaml
job1:
  script:
    - response="$(curl "https://example.com/json")"
    - message="$(echo "$response" | jq -r .message)"
    - 'echo "Server responded with: $message"'
```

### 下位互換性

`include:template:`キーワードでテンプレートを動的にインクルードする場合があります。*既存*のテンプレートを変更する場合は、**絶対に**既存のプロジェクトのCI/CDを中断しないようにします。

たとえばテンプレート内のジョブ名を変更すると、既存のプロジェクトのパイプラインを中断する可能性があります。次のコンテンツに`Performance.gitlab-ci.yml`という名前のテンプレートがあるとします。

```yaml
performance:
  image: registry.gitlab.com/gitlab-org/verify-tools/performance:v0.1.0
  script: ./performance-test $TARGET_URL
```

ユーザーは、`performance`ジョブに引数を渡してこのテンプレートを含めます。これは_ジョブ_の`.gitlab-ci.yml`でCI/CD変数`TARGET_URL`を指定すると実行できます。

```yaml
include:
  template: Performance.gitlab-ci.yml

performance:
  variables:
    TARGET_URL: https://awesome-app.com
```

テンプレート内のジョブ名`performance`が`browser-performance`に名前変更されたら、ユーザーの`.gitlab-ci.yml`は、インクルードされたテンプレートに`performance`という名前のジョブがなくなったため、すぐにlintエラーが発生します。よってユーザーはワークフローを煩わせる可能性のある`.gitlab-ci.yml`を修正しなければなりません。

破壊的変更を安全に導入するには、[バージョニング](#versioning) セクションを参照してください。

## バージョニング

現在のテンプレートに依存している、既存のプロジェクトに影響を与えずに破壊的変更を導入するには、[安定](#stable-version)している[最新](#latest-version)のバージョンを使用します。

安定テンプレートは通常、メジャーバージョンリリースでのみ破壊的変更を受け入れますが、最新テンプレートは、どのリリースの破壊的変更でも受け入れることができます。メジャーリリースのマイルストーンでは、最新テンプレートが新しい安定テンプレートになります（最新テンプレートは削除される可能性があります）。

最新テンプレートの追加は安全ですが、メンテナンスの負担を伴います。

- GitLabは、GitLabの次のメジャーリリース時に最新テンプレートの内容で安定テンプレートを上書きする、DRIを選択する必要があります。DRIは変更に問題があるユーザーをサポートする責任を負います。
- 新たに非破壊的変更を加える場合は、可能な限り、安定テンプレートと最新テンプレートの両方を一致させるように更新する必要があります。
- 多くのユーザーが最新テンプレートの存在継続に直接的に依存している可能性があるため、最新テンプレートは想定よりも長く残ることがあります。

新たな最新テンプレートを追加する前に、変更が破壊的変更であっても、代わりに安定テンプレートに変更を加えることができるかを確認します。テンプレートがコピーペーストの使用のみを意図しているなら、安定バージョンを直接変更できる可能性があります。マイナーマイルストーンで安定テンプレートに破壊的変更を行う前に、以下を確認します。

- これは[パイプラインテンプレート](#template-types)であり、`includes`を使用するようには設計していないことを説明する[コードコメント](#explain-requirements-and-expectations)があること。
- [CI/CDテンプレート使用状況メトリクス](#add-metrics)に使用状況を表示しないこと。メトリクスがテンプレートの使用状況をゼロと表示する場合、テンプレートで`include`を積極的に使用していないこと。

### 安定バージョン

安定したCI/CDテンプレートは、メジャーリリースマイルストーンでのみ破壊的変更を導入するテンプレートです。テンプレートの安定バージョンには`<template-name>.gitlab-ci.yml`のような名前を付けます。たとえば`Jobs/Deploy.gitlab-ci.yml`などです。

`15.0`のようなGitLabのメジャーマイルストーンリリースで利用できる[最新テンプレート](#latest-version)をコピーして、新しい安定テンプレートを作成できます。すべての破壊的変更は、[バージョンごとの非推奨と削除](../../update/deprecations.md)ページで告知する必要があります。

次の場合、`15.1`のようなマイナーGitLabリリースで安定テンプレートバージョンを変更できます。

- 変更が[破壊的変更](#backward-compatibility)ではないこと。
- 変更を[最新のテンプレート](#latest-version)（存在する場合）に移植すること。

### 最新バージョン

`latest`とマークしたテンプレートは、[破壊的変更](#backward-compatibility)を加える場合でも、任意のリリースで更新できます。最新バージョンと見なされる場合は、テンプレート名に`.latest`を追加します（たとえば`Jobs/Deploy.latest.gitlab-ci.yml`）。

[破壊的変更](#backward-compatibility)を導入する場合は、**必ず**[アップグレードパス](#verify-breaking-changes)をテストしてドキュメント化してください。通常、予期しない問題でユーザーを驚かせる可能性があるため、最新テンプレートを最適なオプションとして推奨しないでください。

`latest`テンプレートがまだ存在しない場合、[安定テンプレート](#stable-version)をコピーできます。

### 以前の安定テンプレートを含める方法

ユーザーは、現在のGitLabパッケージにバンドルされていない、以前の[安定テンプレート](#stable-version)を使用することがあります。たとえばGitLab 15.0とGitLab 16.0の安定テンプレートは非常に異なっているかもしれず、その場合ユーザーはGitLab 16.0にアップグレードした後でもGitLab 15.0テンプレートを引き続き使用したいと考えます。

`include:remote`を使用して以前のテンプレートバージョンを含める方法を説明するメモをテンプレートまたはドキュメントに追加できます。他のテンプレートを`include: template`でインクルードする場合は、`include: remote`と組み合わせることができます。

```yaml
# To use the v13 stable template, which is not included in v14, fetch the specific
# template from the remote template repository with the `include:remote:` keyword.
# If you fetch from the GitLab canonical project, use the following URL format:
# https://gitlab.com/gitlab-org/gitlab/-/raw/<version>/lib/gitlab/ci/templates/<template-name>
include:
  - template: Auto-DevOps.gitlab-ci.yml
  - remote: https://gitlab.com/gitlab-org/gitlab/-/raw/v13.0.1-ee/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml
```

### さらに詳しく

GitLab CI/CDテンプレートにバージョニングの概念を導入することには、[未解決のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/17716)があります。そのイシューを確認して、経過を見守ります。

## テスト

各CI/CDテンプレートはテストして、公開しても安全であることを確認する必要があります。

### 手動QA

最小限のデモプロジェクトでテンプレートをテストすることを強く推奨します。これを行うには、次の手順に従います。

1. <https://gitlab.com>に公開サンプルプロジェクトを作成します。
1. 推奨テンプレートを使用し、`.gitlab-ci.yml`をプロジェクトに追加します。
1. パイプラインを実行し、起こり得るすべての事例（マージリクエストパイプライン、スケジュールなど）で、すべてが適切に実行されることを確認します。
1. 新しいテンプレートを追加するマージリクエストの説明で、プロジェクトにリンクします。

これはレビュアーがテンプレートを安全にマージできることを確認する際に役立つ情報です。

### 新しいテンプレートがUIで選択できることを確認する

一部のディレクトリにあるテンプレートは、[**新しいファイル**UI](#template-directories)でも選択できます。いずれかのディレクトリにテンプレートを追加する場合は、ドロップダウンリストに正しく表示されることを確認します。

![CI/CDテンプレートの選択](img/ci_template_selection_v13_1.png)

### RSpecテストを作成する

パイプラインジョブが正しく生成されることを確認するには、RSpecテストを作成する必要があります。

1. `spec/lib/gitlab/ci/templates/<template-category>/<template-name>_spec.rb`にテストファイルを追加します
1. `Ci::CreatePipelineService`を介してパイプラインジョブが適切に作成されるかテストします。

### 破壊的変更を確認する

[`latest`テンプレート](#latest-version)に破壊的変更を導入する場合は、以下を行う必要があります。

1. [安定テンプレート](#stable-version)からのアップグレードパスをテストします。
1. ユーザーがどのような種類のエラーに遭遇するかを確認します。
1. トラブルシューティングガイドとしてドキュメント化します。

この情報は、メジャーバージョンのGitLabリリースで[安定テンプレート](#stable-version)を更新した場合に、ユーザーにとって重要となります。

### メトリクスを追加する

すべてのCI/CDテンプレートには、その使用状況を追跡するよう定義したメトリクスも必要です。CI/CDテンプレートの月間使用状況レポートは、[Sisense（GitLab チームメンバーのみ）](https://app.periscopedata.com/app/gitlab/785953/Pipeline-Authoring-Dashboard?widget=13440051&udv=0)で確認できます。テンプレートを選択して、その単一のテンプレートのグラフを表示します。

新しいテンプレートのメトリクス定義を追加するには、次の手順を実行します。

1. [GitLab GDK](https://gitlab.com/gitlab-org/gitlab-development-kit#installation)をインストールして起動します。
1. GDKの`gitlab`ディレクトリで、新しいテンプレートを含むブランチをチェックアウトします。
1. 新しいテンプレートイベント名を、毎週および毎月のCI/CDテンプレートの合計数メトリクスに追加します。
   - [`config/metrics/counts_7d/20210216184557_ci_templates_total_unique_counts_weekly.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/counts_7d/20210216184557_ci_templates_total_unique_counts_weekly.yml)
   - [`config/metrics/counts_28d/20210216184559_ci_templates_total_unique_counts_monthly.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/counts_28d/20210216184559_ci_templates_total_unique_counts_monthly.yml)

1. [新しいメトリクス定義を追加](../internal_analytics/metrics/metrics_instrumentation.md#create-a-new-metric-instrumentation-class)するには、上記のイベント名と同じ名前を次のコマンドの最後の引数にします。

   ```shell
   bundle exec rails generate gitlab:usage_metric_definition:redis_hll ci_templates <template_metric_event_name>
   ```

   出力は次のようになります。

   ```shell
   $ bundle exec rails generate gitlab:usage_metric_definition:redis_hll ci_templates p_ci_templates_my_template_name
         create  config/metrics/counts_7d/20220120073740_p_ci_templates_my_template_name_weekly.yml
         create  config/metrics/counts_28d/20220120073746_p_ci_templates_my_template_name_monthly.yml
   ```

1. 新しく生成された両方のファイルを次のように編集します。

   - `name:`と`performance_indicator_type:`: 削除します（不要）。
   - `introduced_by_url:`: テンプレートを追加するMRのURL。
   - `data_source:`: `redis_hll`に設定します。
   - `description`: このメトリクスが何を計測するのか簡単な説明を追加します。例: `Count of pipelines using the latest Auto Deploy template`
   - `product_*`: [セクション、ステージ、グループ、機能カテゴリ](https://handbook.gitlab.com/handbook/product/categories/#devops-stages)を、[メトリクスディクショナリガイド](../internal_analytics/metrics/metrics_dictionary.md#metrics-definition-and-validation)に従って設定します。こういったキーワードに何を使用すべきかわからない場合は、マージリクエストでヘルプを求めることができます。
   - 各ファイルの末尾に以下を追加します。

     ```yaml
     options:
       events:
         - p_ci_templates_my_template_name
     ```

1. 変更をコミットしてプッシュします。

たとえば、これらは[5つの詳細な本番環境アプリテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/5-Minute-Production-App.gitlab-ci.yml)のメトリクス設定ファイルです。

- 毎週および毎月のメトリクス定義:
  - [`config/metrics/counts_7d/20210901223501_p_ci_templates_5_minute_production_app_weekly.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/1a6eceff3914f240864b2ca15ae2dc076ea67bf6/config/metrics/counts_7d/20210216184515_p_ci_templates_5_min_production_app_weekly.yml)
  - [`config/metrics/counts_28d/20210901223505_p_ci_templates_5_minute_production_app_monthly.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/counts_28d/20210216184517_p_ci_templates_5_min_production_app_monthly.yml)
- メトリクスのカウント総数:
  - [`config/metrics/counts_7d/20210216184557_ci_templates_total_unique_counts_weekly.yml#L19`](https://gitlab.com/gitlab-org/gitlab/-/blob/4e01ef2b094763943348655ef77008aba7a052ae/config/metrics/counts_7d/20210216184557_ci_templates_total_unique_counts_weekly.yml#L19)
  - [`config/metrics/counts_28d/20210216184559_ci_templates_total_unique_counts_monthly.yml#L19`](https://gitlab.com/gitlab-org/gitlab/-/blob/4e01ef2b094763943348655ef77008aba7a052ae/config/metrics/counts_28d/20210216184559_ci_templates_total_unique_counts_monthly.yml#L19)

## セキュリティ

テンプレートには、悪意のあるコードが含まれている可能性があります。たとえばジョブに`export`シェルコマンドを含むテンプレートは、ジョブログでシークレットプロジェクトのCI/CD変数を誤って公開する可能性があります。安全かどうか不明な場合は、セキュリティの専門家にクロス検証を依頼する必要があります。

## CI/CDテンプレートのマージリクエストにコントリビュートする

CI/CDテンプレートのMRを作成して`ci::templates`をラベル付けしたら、DangerBotがコードをレビューできる1人のレビュアーと1人のメンテナーを提案します。マージリクエストのレビューの準備ができたら、レビュアーに[メンション](../../user/discussions/_index.md#mentions)し、CI/CDテンプレートの変更のレビューを依頼します。[CI/CD テンプレートMRのDangerBotタスク](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44688)を追加した、マージリクエストの詳細を参照してください。
