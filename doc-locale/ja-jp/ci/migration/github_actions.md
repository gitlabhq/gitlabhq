---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitHub Actionsから移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitHub ActionsからGitLab CI/CDに移行する場合、GitHub Actionのワークフローをレプリケートするとともに機能強化するCI/CDパイプラインを作成できます。

## 主な類似点と相違点 {#key-similarities-and-differences}

GitHub ActionsとGitLab CI/CDはどちらも、コードのビルド、テスト、デプロイを自動化するためのパイプラインを生成するために使用されます。どちらも以下のような類似点があります:

- CI/CD機能は、プロジェクトリポジトリに保存されているコードに直接アクセスできます。
- YAMLで記述され、プロジェクトリポジトリに保存されているパイプライン設定。
- パイプラインは設定可能で、異なるステージングで実行できます。
- ジョブはそれぞれ異なるコンテナイメージを使用できます。

さらに、両者にはいくつかの重要な違いがあります:

- GitHubにはサードパーティ製のアクションをダウンロードするためのマーケットプレイスがあり、追加のサポートやライセンスが必要になる場合があります。
- GitLab Self-Managedは水平方向と垂直方向の両方のスケールをサポートしていますが、GitHub Enterprise Serverは垂直方向のスケールのみをサポートしています。
- GitLabはすべての機能を社内で維持およびサポートしており、一部のサードパーティのインテグレーションはテンプレートからアクセスできます。
- GitLabには、組み込みのコンテナレジストリが用意されています。
- GitLabにはネイティブのKubernetesデプロイサポートがあります。
- GitLabは、きめ細かいセキュリティポリシーを提供します。

## 機能と概念の比較 {#comparison-of-features-and-concepts}

多くのGitHubの機能と概念には、同じ機能を提供するGitLabに相当するものがあります。

### 設定ファイル {#configuration-file}

GitHub Actionsは、[workflow YAML設定ファイル](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions#understanding-the-workflow-file)で設定できます。GitLab CI/CDは、デフォルトで`.gitlab-ci.yml` YAMLファイルを使用します。

たとえば、GitHub Actions `workflow`ファイルでは、次のようになります:

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

GitHub Actionsの設定は、特定のキーワードを使用して`workflow` YAMLファイルで定義されます。GitLab CI/CDにも同様の機能があり、通常はYAMLキーワードで設定されます。

| GitHub    | GitLab         | 説明 |
|-----------|----------------|-------------|
| `env`     | `variables`    | `env`は、ワークフロー、ジョブ、またはステップで設定された変数を定義します。GitLabは、グローバルまたはジョブレベルで[CI/CD変数](../variables/_index.md)を定義するために`variables`を使用します。変数はUIで追加することもできます。 |
| `jobs`    | `stages`       | `jobs`は、ワークフローで実行されるすべてのジョブをグループ化します。GitLabは、ジョブをグループ化するために`stages`を使用します。 |
| `on`      | 該当なし | `on`は、ワークフローがいつトリガーされるかを定義します。GitLabはGitと緊密にインテグレーションされているため、トリガーのSCMポーリングオプションは必要ありませんが、必要に応じてジョブごとに設定できます。 |
| `run`     | 該当なし | ジョブで実行するコマンド。GitLabは、実行するコマンドごとに1つのエントリがある`script`キーワードの下にYAML配列を使用します。 |
| `runs-on` | `tags`         | `runs-on`は、ジョブが実行されるGitHub Runnerを定義します。GitLabは`tags`を使用してRunnerを選択します。 |
| `steps`   | `script`       | `steps`は、ジョブで実行されるすべてのステップをグループ化します。GitLabは、ジョブで実行されるすべてのコマンドをグループ化するために`script`を使用します。 |
| `uses`    | `include`      | `uses`は、`step`に追加するGitHub Actionを定義します。GitLabは`include`を使用して、他のファイルからジョブに設定を追加します。 |

### 共通設定 {#common-configurations}

このセクションでは、一般的に使用されるCI/CD設定について説明し、それらをGitHub ActionsからGitLab CI/CDに変換する方法を示します。

[GitHub Actionワークフロー](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions#workflows)は、特定のイベントが発生したとき（たとえば、新しいコミットをプッシュしたとき）にトリガーされる自動CI/CDジョブを生成します。GitHub Actionワークフローは、リポジトリのルートディレクトリにある`.github/workflows`ディレクトリで定義されたYAMLファイルです。GitLabに相当するものは`.gitlab-ci.yml`設定ファイルで、これもリポジトリのルートディレクトリにあります。

#### ジョブ {#jobs}

ジョブは、特定の成果を達成するために、一連のシーケンスで実行されるコマンドのセットです。たとえば、コンテナをビルドしたり、本番環境にデプロイしたりします。

たとえば、このGitHub Actions `workflow`はコンテナをビルドしてから本番環境にデプロイします。このジョブは順番に実行されます。`deploy`ジョブは`build`ジョブに依存するためです:

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
- コードをビルドするためのジョブを実行します。
  - ビルドされた実行可能ファイルをアーティファクトとして保存します。
- `staging`にデプロイするための2番目のジョブを実行します。これには以下も含まれます:
  - 実行する前に、ビルドジョブが成功する必要があります。
  - コミットのターゲットブランチ`staging`が必要です。
  - ビルドされた実行可能なアーティファクトを使用します。

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

GitHubとGitLabの両方で、ジョブはデフォルトで並行して実行されます。

たとえば、GitHub Actions `workflow`ファイルでは、次のようになります:

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

この例では、異なるコンテナイメージを使用して、PythonジョブとJavaジョブを並行して実行します。Javaジョブは、`staging`ブランチが変更された場合にのみ実行されます。

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

この場合、ジョブを並行して実行するために追加の設定は必要ありません。ジョブはデフォルトで並行して実行されます。すべてのジョブに十分なRunnerがある場合は、それぞれ異なるRunnerで実行されます。Javaジョブは、`staging`ブランチが変更された場合にのみ実行するように設定されています。

##### マトリックス {#matrix}

GitLabとGitHubの両方でを使用すると、単一のパイプラインでジョブを複数のインスタンスとして並列で実行できますが、ジョブのインスタンスごとに異なる変数値を使用できます。

たとえば、GitHub Actions `workflow`ファイルでは、次のようになります:

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

GitHub Actionsでは、ワークフローのトリガーを追加する必要があります。GitLabはGitと緊密にインテグレーションされているため、トリガーのSCMポーリングオプションは必要ありませんが、必要に応じてジョブごとに設定できます。

GitHub Actions設定のサンプル:

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

GitLabを使用すると、[分離された個別のDockerコンテナでCI/CDジョブを実行](../docker/using_docker_images.md)できます。[`image`](../yaml/_index.md#image)キーワードを使用します。

たとえば、GitHub Actions `workflow`ファイルでは、次のようになります:

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

GitLabはすべてのプロジェクトに、コンテナイメージをホストするための[コンテナレジストリ](../../user/packages/container_registry/_index.md)を提供します。コンテナイメージは、GitLab CI/CDパイプラインから直接ビルドおよび保存できます。

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

GitLabでは、`variables`キーワードを使用して、さまざまな[CI/CD変数](../variables/_index.md)をランタイムで定義します。パイプラインで設定データを再利用する必要がある場合は、変数を使用します。変数は、グローバルまたはジョブごとに定義できます。

たとえば、GitHub Actions `workflow`ファイルでは、次のようになります:

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

この例では、変数はジョブに異なる出力を提供します。

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

変数は、CI/CD設定のGitLab UIでセットアップすることもできます。ここでは、変数を[保護](../variables/_index.md#protect-a-cicd-variable)または[マスク](../variables/_index.md#mask-a-cicd-variable)できます。マスクされた変数はジョブログに隠されますが、保護された変数は保護ブランチまたはタグ付けのパイプラインでのみアクセスできます。

たとえば、GitHub Actions `workflow`ファイルでは、次のようになります:

```yaml
jobs:
  login:
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY: ${{ secrets.AWS_ACCESS_KEY }}
    steps:
      - run: my-login-script.sh "$AWS_ACCESS_KEY"
```

`AWS_ACCESS_KEY`変数がGitLabプロジェクト設定で定義されている場合、同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
login:
  script:
    - my-login-script.sh $AWS_ACCESS_KEY
```

さらに、[GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/contexts)と[GitLab CI/CD](../variables/predefined_variables.md)は、パイプラインとリポジトリに関連するデータを含む組み込み変数を提供します。

#### 条件 {#conditionals}

新しいパイプラインが開始されると、GitLabはパイプラインの設定をチェックして、どのジョブをそのパイプラインで実行するかを判断します。[`rules`キーワード](../yaml/_index.md#rules)を使用して、変数のステータスやパイプラインの種類などの条件に応じてジョブを実行するように設定できます。

たとえば、GitHub Actions `workflow`ファイルでは、次のようになります:

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

Runnerは、ジョブを実行するサービスです。GitLab.comを使用している場合は、[インスタンスRunnerフリート](../runners/_index.md)を使用して、独自の自己管理Runnerをプロビジョニングせずにジョブを実行できます。

Runnerに関する主な詳細は次のとおりです:

- Runnerは、[インスタンス](../runners/runners_scope.md)、グループ、または単一のプロジェクト専用に共有されるように設定できます。
- [`tags`キーワード](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)を使用してより細かく制御し、特定のジョブにRunnerを関連付けることができます。たとえば、専用、より強力な、または特定のハードウェアを必要とするジョブにタグを使用できます。
- GitLabには[オートスケール](https://docs.gitlab.com/runner/configuration/autoscale.html)があります。必要な場合にのみRunnerをプロビジョニングし、不要な場合はスケールダウンするには、オートスケールを使用します。

たとえば、GitHub Actions `workflow`ファイルでは、次のようになります:

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

GitLabでは、どのジョブでも[アーティファクト](../yaml/_index.md#artifacts)キーワードを使用して、ジョブの完了時に保存されるアーティファクトのセットを定義できます。[アーティファクト](../jobs/job_artifacts.md)は、後のジョブで使用できるファイルです。

たとえば、GitHub Actions `workflow`ファイルでは、次のようになります:

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

[キャッシュ](../caching/_index.md)は、ジョブが1つ以上のファイルをダウンロードし、将来のアクセスを高速化するために保存するときに作成されます。同じキャッシュを使用する後続のジョブは、ファイルを再度ダウンロードする必要がないため、より高速に実行されます。キャッシュはRunnerに保存され、[分散キャッシュが有効](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching)になっている場合はS3にアップロードされます。

たとえば、GitHub Actions `workflow`ファイルでは、次のようになります:

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

GitHubでは、Actionは頻繁に繰り返す必要のある一連の複雑なタスクであり、CI/CDパイプラインを再定義せずに再利用できるように保存されます。GitLabでは、アクションに相当するのは[`include`キーワード](../yaml/includes.md)です。これにより、[他のファイルからCI/CDパイプラインを追加](../yaml/includes.md)できます。GitLabに組み込まれたテンプレートファイルなど。

GitHub Actions設定のサンプル:

```yaml
- uses: hashicorp/setup-terraform@v2.0.3
```

同等のGitLab CI/CD設定は次のようになります:

```yaml
include:
  - template: Terraform.gitlab-ci.yml
```

これらの例では、`setup-terraform`GitHub actionと`Terraform.gitlab-ci.yml`GitLabテンプレートは完全に一致しません。これら2つの例は、複雑な設定を再利用する方法を示すためだけのものです。

### セキュリティスキャナーの機能 {#security-scanning-features}

GitLabは、SLDCのすべての部分の脆弱性を検出するために、すぐに使用できるさまざまな[セキュリティスキャナー](../../user/application_security/_index.md)を提供します。これらの機能をテンプレートを使用してGitLab CI/CDパイプラインに追加できます。

たとえば、SASTスキャンをパイプラインに追加するには、`.gitlab-ci.yml`に以下を追加します:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

CI/CD変数（たとえば、[SASTスキャナー](../../user/application_security/sast/_index.md#available-cicd-variables)を使用）を使用して、セキュリティスキャナーの動作をカスタマイズできます。

### シークレット管理 {#secrets-management}

特権情報（多くの場合「シークレット」と呼ばれる）は、CI/CDワークフローで必要な機密情報または認証情報です。シークレットを使用して、ツール、アプリケーション、コンテナ、およびクラウドネイティブ環境で保護されたリソースまたは機密情報のロックを解除する場合があります。

GitLabでのシークレット管理では、外部サービスの[サポートされているインテグレーション](../secrets/_index.md)のいずれかを使用できます。これらのサービスは、GitLabプロジェクトの外部にシークレットを安全に保存しますが、サービスのサブスクリプションが必要です。

GitLabは、OIDCをサポートする他のサードパーティサービスに対して[OIDC認証](../secrets/id_token_authentication.md)もサポートしています。

さらに、CI/CD変数に保存することで、ジョブで認証情報を利用できるようにすることができますが、プレーンテキストで保存されたシークレットは偶発的な暴露の影響を受けやすくなります。リスクを軽減するには、常に[マスク](../variables/_index.md#mask-a-cicd-variable)された変数と[保護](../variables/_index.md#protect-a-cicd-variable)された変数に機密情報を保存する必要があります。

また、`.gitlab-ci.yml`ファイルにシークレットを変数として保存しないでください。これは、プロジェクトへのアクセス権を持つすべてのユーザーに公開されます。機密情報を変数に格納する場合は、[プロジェクト、グループ、またはインスタンスの設定](../variables/_index.md#define-a-cicd-variable-in-the-ui)でのみ行ってください。

CI/CD変数の安全性を向上させるために、[セキュリティガイドライン](../variables/_index.md#cicd-variable-security)を確認してください。

## 移行の計画と実行 {#planning-and-performing-a-migration}

以下の推奨される手順のリストは、この移行を迅速に完了できた組織を観察した後に作成されました。

### 移行計画を作成する {#create-a-migration-plan}

移行を開始する前に、移行の準備をするために、[移行計画](plan_a_migration.md)を作成する必要があります。

### 前提要件 {#prerequisites}

何か移行作業をする前に、まず以下を行う必要があります:

1. GitLabに慣れてください。
   - [主要なGitLab CI/CD機能](../_index.md)についてお読みください。
   - チュートリアルに従って、[最初のGitLabパイプライン](../quick_start/_index.md)と、静的サイトをビルド、テスト、デプロイする[より複雑なパイプライン](../quick_start/tutorial.md)を作成します。
   - [CI/CD YAML構文参照](../yaml/_index.md)を確認します。
1. GitLabを設定し、設定してください。
1. GitLabインスタンスをテストします。
   - 共有GitLab.com Runnerを使用するか、新しいRunnerをインストールして、[Runnerが利用可能](../runners/_index.md)であることを確認します。

### 移行の手順 {#migration-steps}

1. GitHubからGitLabへのプロジェクトの移行:
   - （推奨）[GitHubインポーター](../../user/project/import/github.md)を使用して、外部SCMプロバイダーから大量のインポートを自動化できます。
   - [URLでリポジトリをインポートする](../../user/project/import/repo_by_url.md)ことができます。
1. 各プロジェクトに`.gitlab-ci.yml`を作成します。
1. GitHub ActionsジョブをGitLab CI/CDジョブに移行し、マージリクエストに結果を直接表示するように設定します。
1. [クラウドデプロイテンプレート](../cloud_deployment/_index.md) 、[環境](../environments/_index.md) 、および[Kubernetes向けGitLabエージェント](../../user/clusters/agent/_index.md)を使用して、デプロイメントジョブを移行します。
1. 複数のプロジェクトでCI/CD設定を再利用できるかどうかを確認し、[CI/CDテンプレート](../examples/_index.md#adding-templates-to-your-gitlab-installation)を作成して共有します。
1. GitLab CI/CDパイプラインをより高速かつ効率性を高める方法については、[パイプラインの効率性に関するドキュメント](../pipelines/pipeline_efficiency.md)を確認してください。

### 追加リソース {#additional-resources}

- [ビデオ: GitHubからActionsを含むGitLabに移行する方法](https://youtu.be/0Id5oMl1Kqs?feature=shared)
- [ブログ: GitHubからGitLabへの簡単な方法での移行](https://about.gitlab.com/blog/2023/07/11/github-to-gitlab-migration-made-easy/)

ここに記載されていない質問がある場合は、[GitLabコミュニティフォーラム](https://forum.gitlab.com/)が役立ちます。
