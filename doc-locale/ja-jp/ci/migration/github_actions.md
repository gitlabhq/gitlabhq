---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitHub Actionsから移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitHub ActionsからGitLab CI/CDへの移行を行う場合、GitHub Actionワークフローをレプリケートするだけでなく、強化するCI/CDパイプラインを作成できます。

## 主な類似点と相違点 {#key-similarities-and-differences}

GitHub ActionsとGitLab CI/CDはどちらも、コードのビルド、テスト、デプロイを自動化するパイプラインを生成するために使用されます。両者には以下のような類似点があります:

- CI/CD機能は、プロジェクトのリポジトリに保存されているコードに直接アクセスできます。
- パイプライン設定はYAMLで記述され、プロジェクトのリポジトリに保存されます。
- パイプラインは設定可能であり、異なるステージで実行できます。
- 各ジョブは異なるコンテナイメージを使用できます。

さらに、両者にはいくつかの重要な違いがあります:

- GitHubにはサードパーティ製アクションをダウンロードするためのマーケットプレイスがあり、追加のサポートやライセンスが必要となる場合があります。
- GitLab Self-Managedは水平方向と垂直方向の両方のスケーリングをサポートしていますが、GitHub Enterprise Serverは垂直方向のスケーリングのみをサポートしています。
- GitLabはすべての機能を社内で維持サポートしており、一部のサードパーティ製インテグレーションはテンプレートを通じてアクセスできます。
- GitLabは組み込みのコンテナレジストリを提供します。
- GitLabはネイティブなKubernetesのデプロイをサポートしています。
- GitLabはきめ細かいセキュリティポリシーを提供します。

## 機能と概念の比較 {#comparison-of-features-and-concepts}

多くのGitHubの機能と概念には、GitLabに同じ機能を提供する同等のものがあります。

### 設定ファイル {#configuration-file}

GitHub Actionsは、[ワークフローYAMLファイル](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions#understanding-the-workflow-file)で設定できます。GitLab CI/CDは、デフォルトで`.gitlab-ci.yml` YAMLファイルを使用します。

たとえば、GitHub Actionsの`workflow`ファイルの場合:

```yaml
on: [push]
jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Hello World"
```

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
stages:
  - hello

hello:
  stage: hello
  script:
    - echo "Hello World"
```

### GitHub Actionsワークフローの構文 {#github-actions-workflow-syntax}

GitHub Actionsの設定は、特定のキーワードを使用して`workflow` YAMLファイルで定義されます。GitLab CI/CDも同様の機能を持ち、通常はYAMLキーワードで設定されます。

| GitHub    | GitLab         | 説明 |
|-----------|----------------|-------------|
| `env`     | `variables`    | `env`は、ワークフロー、ジョブ、またはステップで設定される変数を定義します。GitLabは`variables`を使用して、グローバルレベルまたはジョブレベルで[CI/CD変数](../variables/_index.md)を定義します。変数はUIでも追加できます。 |
| `jobs`    | `stages`       | `jobs`は、ワークフローで実行されるすべてのジョブをグループ化します。GitLabは`stages`を使用してジョブをグループ化します。 |
| `on`      | 該当なし | `on`は、ワークフローがトリガーされるタイミングを定義します。GitLabはGitと密接に統合されているため、SCMのポーリングオプションによるトリガーは必要ありませんが、必要に応じてジョブごとに設定できます。 |
| `run`     | 該当なし | ジョブで実行するコマンド。GitLabは`script`キーワードの下にYAML配列を使用し、実行する各コマンドのエントリを1つずつ配置します。 |
| `runs-on` | `tags`         | `runs-on`は、ジョブを実行するGitHub Runnerを定義します。GitLabは`tags`を使用してRunnerを選択します。 |
| `steps`   | `script`       | `steps`は、ジョブで実行されるすべてのステップをグループ化します。GitLabは`script`を使用して、ジョブで実行されるすべてのコマンドをグループ化します。 |
| `uses`    | `include`      | `uses`は、`step`に追加するGitHub Actionを定義します。GitLabは`include`を使用して、他のファイルから設定をジョブに追加します。 |

### 一般的な設定 {#common-configurations}

このセクションでは、よく使用されるCI/CD設定について説明し、GitHub ActionsからGitLab CI/CDへの変換方法を示します。

[GitHub Actionワークフロー](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions#workflows)は、新しいコミットのプッシュなど、特定のイベントが発生したときにトリガーされる自動化されたCI/CDジョブを生成します。GitHub Actionワークフローは、リポジトリのルートディレクトリにある`.github/workflows`ディレクトリで定義されるYAMLファイルです。GitLabの同等物は、リポジトリのルートディレクトリにも存在する`.gitlab-ci.yml`設定ファイルです。

#### ジョブ {#jobs}

ジョブは、コンテナのビルドや本番環境へのデプロイなど、特定の目的を達成するために決まった順序で実行される一連のコマンドです。

たとえば、このGitHub Actions `workflow`はコンテナをビルドし、それを本番環境にデプロイします。`deploy`ジョブは`build`ジョブに依存するため、ジョブは順次実行されます:

```yaml
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    container: golang:alpine
    steps:
      - run: apk update
      - run: go build -o bin/hello
      - uses: actions/upload-artifact@v3
        with:
          name: hello
          path: bin/hello
          retention-days: 7
  deploy:
    if: contains( github.ref, 'staging')
    runs-on: ubuntu-latest
    container: golang:alpine
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: hello
      - run: echo "Deploying to Staging"
      - run: scp bin/hello remoteuser@remotehost:/remote/directory
```

この例:

- `golang:alpine`コンテナイメージを使用します。
- コードをビルドするジョブを実行します。
  - ビルド実行ファイルをアーティファクトとして保存します。
- 2番目のジョブを実行して`staging`にデプロイします。これには以下も含まれます:
  - ビルドジョブが成功してから実行する必要があります。
  - コミットターゲットブランチが`staging`である必要があります。
  - ビルド実行ファイルアーティファクトを使用します。

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
default:
  image: golang:alpine

stages:
  - build
  - deploy

build-job:
  stage: build
  script:
    - apk update
    - go build -o bin/hello
  artifacts:
    paths:
      - bin/hello
    expire_in: 1 week

deploy-job:
  stage: deploy
  script:
    - echo "Deploying to Staging"
    - scp bin/hello remoteuser@remotehost:/remote/directory
  rules:
    - if: $CI_COMMIT_BRANCH == 'staging'
```

##### 並列 {#parallel}

GitHubとGitLabのどちらでも、ジョブはデフォルトで並列実行されます。

たとえば、GitHub Actionsの`workflow`ファイルの場合:

```yaml
on: [push]
jobs:
  python-version:
    runs-on: ubuntu-latest
    container: python:latest
    steps:
      - run: python --version
  java-version:
    if: contains( github.ref, 'staging')
    runs-on: ubuntu-latest
    container: openjdk:latest
    steps:
      - run: java -version
```

この例では、異なるコンテナイメージを使用して、PythonジョブとJavaジョブを並列で実行します。Javaジョブは、`staging`ブランチが変更された場合にのみ実行されます。

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
python-version:
  image: python:latest
  script:
    - python --version

java-version:
  image: openjdk:latest
  rules:
    - if: $CI_COMMIT_BRANCH == 'staging'
  script:
    - java -version
```

この場合、ジョブを並列実行させるための追加の設定は必要ありません。ジョブはデフォルトで並列実行され、すべてのジョブに対して十分なRunnerがある場合、それぞれ異なるRunnerで実行されます。Javaジョブは、`staging`ブランチが変更された場合にのみ実行されるように設定されています。

##### マトリックス {#matrix}

GitLabとGitHubのどちらでも、マトリックスを使用して、単一のパイプライン内でジョブを複数回並列実行できますが、ジョブの各インスタンスには異なる変数値が使用されます。

たとえば、GitHub Actionsの`workflow`ファイルの場合:

```yaml
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building $PLATFORM for $ARCH"
    strategy:
      matrix:
        platform: [linux, mac, windows]
        arch: [x64, x86]
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Testing $PLATFORM for $ARCH"
    strategy:
      matrix:
        platform: [linux, mac, windows]
        arch: [x64, x86]
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying $PLATFORM for $ARCH"
    strategy:
      matrix:
        platform: [linux, mac, windows]
        arch: [x64, x86]
```

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
stages:
  - build
  - test
  - deploy

.parallel-hidden-job:
  parallel:
    matrix:
      - PLATFORM: [linux, mac, windows]
        ARCH: [x64, x86]

build-job:
  extends: .parallel-hidden-job
  stage: build
  script:
    - echo "Building $PLATFORM for $ARCH"

test-job:
  extends: .parallel-hidden-job
  stage: test
  script:
    - echo "Testing $PLATFORM for $ARCH"

deploy-job:
  extends: .parallel-hidden-job
  stage: deploy
  script:
    - echo "Deploying $PLATFORM for $ARCH"
```

#### トリガー {#trigger}

GitHub Actionsでは、ワークフローにトリガーを追加する必要があります。GitLabはGitと密接に統合されているため、SCMのポーリングオプションによるトリガーは必要ありませんが、必要に応じてジョブごとに設定できます。

GitHub Actionsの設定例:

```yaml
on:
  push:
    branches:
      - main
```

同等のGitLab CI/CD設定は次のようになります:

```yaml
rules:
  - if: '$CI_COMMIT_BRANCH == main'
```

パイプラインは、[Cron構文を使用してスケジュール](../pipelines/schedules.md)することもできます。

#### コンテナイメージ {#container-images}

GitLabでは、[個別の隔離されたDockerコンテナでCI/CDジョブを実行](../docker/using_docker_images.md)するために、[`image`](../yaml/_index.md#image)キーワードを使用できます。

たとえば、GitHub Actionsの`workflow`ファイルの場合:

```yaml
jobs:
  update:
    runs-on: ubuntu-latest
    container: alpine:latest
    steps:
      - run: apk update
```

この例では、`apk update`コマンドは`alpine:latest`コンテナで実行されます。

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
update-job:
  image: alpine:latest
  script:
    - apk update
```

GitLabは、すべてのプロジェクトに[コンテナレジストリ](../../user/packages/container_registry/_index.md)を提供し、コンテナイメージをホストします。コンテナイメージは、GitLab CI/CDパイプラインから直接ビルドおよび保存できます。

例: 

```yaml
stages:
  - build

build-image:
  stage: build
  variables:
    IMAGE: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $IMAGE .
    - docker push $IMAGE
```

#### 変数 {#variables}

`variables`キーワードを使用して、ランタイム時に異なる[CI/CD変数](../variables/_index.md)を定義できます。変数は、パイプライン内で設定データを再利用する必要がある場合に使用します。変数は、グローバルに、またはジョブごとに定義できます。

たとえば、GitHub Actionsの`workflow`ファイルの場合:

```yaml
env:
  NAME: "fern"

jobs:
  english:
    runs-on: ubuntu-latest
    env:
      Greeting: "hello"
    steps:
      - run: echo "$GREETING $NAME"
  spanish:
    runs-on: ubuntu-latest
    env:
      Greeting: "hola"
    steps:
      - run: echo "$GREETING $NAME"
```

この例では、変数がジョブに対して異なる出力を提供します。

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
default:
  image: ubuntu-latest

variables:
  NAME: "fern"

english:
  variables:
    GREETING: "hello"
  script:
    - echo "$GREETING $NAME"

spanish:
  variables:
    GREETING: "hola"
  script:
    - echo "$GREETING $NAME"
```

変数は、GitLab UIのCI/CD設定からも設定でき、そこで変数を[保護する](../variables/_index.md#protect-a-cicd-variable)または[マスクする](../variables/_index.md#mask-a-cicd-variable)ことができます。マスクされた変数はジョブログに表示されませんが、保護された変数は、保護ブランチまたはタグのパイプラインでのみアクセスできます。

たとえば、GitHub Actionsの`workflow`ファイルの場合:

```yaml
jobs:
  login:
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY: ${{ secrets.AWS_ACCESS_KEY }}
    steps:
      - run: my-login-script.sh "$AWS_ACCESS_KEY"
```

`AWS_ACCESS_KEY`変数がGitLabプロジェクトの設定で定義されている場合、同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
login:
  script:
    - my-login-script.sh $AWS_ACCESS_KEY
```

さらに、[GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/contexts)と[GitLab CI/CD](../variables/predefined_variables.md)は、パイプラインとリポジトリに関連するデータを含む組み込み変数を提供します。

#### 条件式 {#conditionals}

新しいパイプラインが開始されると、GitLabはパイプライン設定をチェックし、そのパイプラインでどのジョブを実行すべきかを決定します。[`rules`キーワード](../yaml/_index.md#rules)を使用して、変数のステータスやパイプラインのタイプなどの条件に応じてジョブが実行されるように設定できます。

たとえば、GitHub Actionsの`workflow`ファイルの場合:

```yaml
jobs:
  deploy_staging:
    if: contains( github.ref, 'staging')
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploy to staging server"
```

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
deploy_staging:
  stage: deploy
  script:
    - echo "Deploy to staging server"
  rules:
    - if: '$CI_COMMIT_BRANCH == staging'
```

#### Runner {#runners}

Runnerはジョブを実行するサービスです。GitLab.comを使用している場合、独自のセルフマネージドRunnerをプロビジョニングすることなくジョブを実行するために、[インスタンスRunnerフリート](../runners/_index.md)を使用できます。

Runnerに関するいくつかの主要な詳細:

- Runnerは、インスタンス、グループ全体で共有されるように[設定](../runners/runners_scope.md)したり、単一のプロジェクト専用にしたりできます。
- よりきめ細かな制御のために[`tags`キーワード](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)を使用し、Runnerを特定のジョブと関連付けることができます。たとえば、専用の、より強力な、または特定のハードウェアを必要とするジョブにはタグを使用できます。
- GitLabには[オートスケール機能が](https://docs.gitlab.com/runner/configuration/autoscale/)あります。オートスケールを使用して、必要なときにのみRunnerをプロビジョニングし、不要なときにスケールダウンします。

たとえば、GitHub Actionsの`workflow`ファイルの場合:

```yaml
linux_job:
  runs-on: ubuntu-latest
  steps:
    - run: echo "Hello, $USER"

windows_job:
  runs-on: windows-latest
  steps:
    - run: echo "Hello, %USERNAME%"
```

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
linux_job:
  stage: build
  tags:
    - linux-runners
  script:
    - echo "Hello, $USER"

windows_job:
  stage: build
  tags:
    - windows-runners
  script:
    - echo "Hello, %USERNAME%"
```

#### アーティファクト {#artifacts}

GitLabでは、任意のジョブが[アーティファクト](../yaml/_index.md#artifacts)キーワードを使用して、ジョブの完了時に保存するアーティファクトのセットを定義できます。[アーティファクト](../jobs/job_artifacts.md)は、後のジョブで使用できるファイルです。

たとえば、GitHub Actionsの`workflow`ファイルの場合:

```yaml
on: [push]
jobs:
  generate_cat:
    steps:
      - run: touch cat.txt
      - run: echo "meow" > cat.txt
      - uses: actions/upload-artifact@v3
        with:
          name: cat
          path: cat.txt
          retention-days: 7
  use_cat:
    needs: [generate_cat]
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: cat
      - run: cat cat.txt
```

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
stage:
  - generate
  - use

generate_cat:
  stage: generate
  script:
    - touch cat.txt
    - echo "meow" > cat.txt
  artifacts:
    paths:
      - cat.txt
    expire_in: 1 week

use_cat:
  stage: use
  script:
    - cat cat.txt
```

#### キャッシュ {#caching}

A [キャッシュ](../caching/_index.md)は、ジョブが1つ以上のファイルをダウンロードし、将来のアクセスを高速化するためにそれらを保存するときに作成されます。同じキャッシュを使用する後続のジョブは、ファイルを再度ダウンロードする必要がないため、より高速に実行されます。キャッシュはRunnerに保存され、[分散キャッシュが有効になっている](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching)場合はS3にアップロードされます。

たとえば、GitHub Actionsの`workflow`ファイルの場合:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - run: echo "This job uses a cache."
    - uses: actions/cache@v3
      with:
        path: binaries/
        key: binaries-cache-$CI_COMMIT_REF_SLUG
```

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache-$CI_COMMIT_REF_SLUG
    paths:
      - binaries/
```

#### テンプレート {#templates}

GitHubでは、アクションは頻繁に繰り返す必要のある複雑なタスクのセットであり、CI/CDパイプラインを再定義することなく再利用を可能にするために保存されます。GitLabでは、アクションに相当するのは[`include`キーワード](../yaml/includes.md)です。これを使用すると、GitLabに組み込まれているテンプレートファイルを含め、[他のファイルからCI/CDパイプラインを追加](../yaml/includes.md)できます。

GitHub Actionsの設定例:

```yaml
- uses: hashicorp/setup-terraform@v2.0.3
```

同等のGitLab CI/CD設定は次のようになります:

```yaml
include:
  - template: Terraform.gitlab-ci.yml
```

これらの例では、`setup-terraform` GitHubアクションと`Terraform.gitlab-ci.yml` GitLabテンプレートは正確には一致しません。これらの2つの例は、複雑な設定をいかに再利用できるかを示すものです。

### セキュリティスキャン機能 {#security-scanning-features}

GitLabは、SLDCのすべての部分で脆弱性を検出するために、さまざまな組み込みの[セキュリティスキャナー](../../user/application_security/_index.md)を提供します。これらの機能をテンプレートを使用してGitLab CI/CDパイプラインに追加できます。

たとえば、SASTスキャンをパイプラインに追加するには、`.gitlab-ci.yml`に以下を追加します:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

CI/CD変数を使用してセキュリティスキャナーの動作をカスタマイズできます。たとえば、[SASTスキャナー](../../user/application_security/sast/_index.md#available-cicd-variables)を使用する場合です。

### シークレット管理 {#secrets-management}

特権情報（しばしば「シークレット」と呼ばれる）は、CI/CDワークフローで必要となる機密情報または認証情報です。シークレットを使用して、ツール、アプリケーション、コンテナ、クラウドネイティブ環境の保護されたリソースや機密情報をロック解除できます。

GitLabでのシークレット管理には、外部サービスの[サポートされているインテグレーション](../secrets/_index.md)のいずれかを使用できます。これらのサービスはGitLabプロジェクトの外部にシークレットを安全に保存しますが、そのサービスに対するサブスクリプションが必要です。

GitLabは、OIDCをサポートする他のサードパーティサービス向けの[OIDC認証](../secrets/id_token_authentication.md)もサポートしています。

さらに、認証情報をCI/CD変数に保存することでジョブで利用可能にすることができますが、プレーンテキストで保存されたシークレットは偶発的な漏洩の可能性があります。機密情報は常に[マスクされた変数](../variables/_index.md#mask-a-cicd-variable)および[保護された変数](../variables/_index.md#protect-a-cicd-variable)に保存し、リスクの一部を軽減する必要があります。

また、`.gitlab-ci.yml`ファイルにシークレットを変数として保存しないでください。これは、プロジェクトにアクセスできるすべてのユーザーに公開されます。機密情報を変数に保存するのは、[プロジェクト、グループ、またはインスタンスの設定](../variables/_index.md#define-a-cicd-variable-in-the-ui)でのみ行うべきです。

[セキュリティガイドライン](../variables/_index.md#cicd-variable-security)を確認して、CI/CD変数の安全性を向上させてください。

## 移行の計画と実行 {#planning-and-performing-a-migration}

以下の推奨ステップのリストは、この移行を迅速に完了できた組織を観察した後に作成されました。

### 移行計画を作成する {#create-a-migration-plan}

移行を開始する前に、移行の準備をするために[移行計画](plan_a_migration.md)を作成する必要があります。

### 前提条件 {#prerequisites}

移行作業を行う前に、まず以下を行う必要があります:

1. GitLabに慣れる。
   - [主要なGitLab CI/CD機能](../_index.md)について読みます。
   - [最初のGitLabパイプライン](../quick_start/_index.md)と、静的サイトをビルド、テスト、デプロイする[より複雑なパイプライン](../quick_start/tutorial.md)を作成するチュートリアルに従います。
   - [CI/CD YAML構文リファレンス](../yaml/_index.md)を確認します。
1. GitLabを設定してセットアップします。
1. GitLabインスタンスをテストします。
   - 共有GitLab.com Runnerを使用するか、新しいRunnerをインストールして、[Runner](../runners/_index.md)が利用可能であることを確認します。

### 移行ステップ {#migration-steps}

1. GitHubからGitLabへのプロジェクトを移行します:
   - (推奨) 外部SCMプロバイダからの大量のインポートを自動化するために、[GitHubインポーター](../../user/project/import/github.md)を使用できます。
   - [URLでリポジトリをインポート](../../user/project/import/repo_by_url.md)できます。
1. 各プロジェクトに`.gitlab-ci.yml`を作成します。
1. GitHub ActionsジョブをGitLab CI/CDジョブに移行し、マージリクエストに結果を直接表示するように設定します。
1. [クラウドデプロイテンプレート](../cloud_deployment/_index.md) 、[環境](../environments/_index.md) 、および[Kubernetes向けGitLabエージェント](../../user/clusters/agent/_index.md)を使用して、デプロイメントジョブを移行します。
1. 異なるプロジェクト間で再利用できるCI/CD設定があるか確認し、[CI/CDテンプレート](../examples/_index.md#adding-templates-to-your-gitlab-installation)を作成して共有します。
1. [パイプライン効率性ドキュメント](../pipelines/pipeline_efficiency.md)を確認して、GitLab CI/CDパイプラインをより高速で効率的にする方法を学びます。

### 追加リソース {#additional-resources}

- [動画: GitHubからGitLabへの移行方法（Actionsを含む）](https://youtu.be/0Id5oMl1Kqs?feature=shared)
- [ブログ: GitHubからGitLabへの移行を簡単に](https://about.gitlab.com/blog/github-to-gitlab-migration-made-easy/)

ここで回答されていない質問がある場合は、[GitLabコミュニティフォーラム](https://forum.gitlab.com/)が優れたリソースとなりえます。
