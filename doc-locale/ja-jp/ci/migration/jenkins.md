---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Jenkinsから移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

JenkinsからGitLab CI/CDへ移行する場合、Jenkinsのワークフローをレプリケートする、あるいはそれを強化するCI/CDパイプラインを作成できます。

## 主な類似点と相違点 {#key-similarities-and-differences}

GitLab CI/CDとJenkinsは、いくつかの類似点を持つCI/CDツールです。GitLabとJenkinsの両方で:

- ジョブの集まりにはステージを使用します。
- コンテナベースのビルドをサポートします。

さらに、両者にはいくつかの重要な違いがあります:

- GitLab CI/CDパイプラインはすべてYAML形式の設定ファイルで設定されます。Jenkinsは、Groovy形式の設定ファイル（宣言型パイプライン）またはJenkins DSL（スクリプト型パイプライン）のいずれかを使用します。
- GitLabは、マルチテナントのSaaSサービスである[GitLab.com](../../subscriptions/manage_users_and_seats.md#gitlabcom-billing-and-usage)と、完全に分離されたシングルテナントのSaaSサービスである[GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md)を提供しています。また、独自の[GitLab Self-Managed](../../subscriptions/manage_subscription.md)インスタンスを実行することもできます。Jenkinsのデプロイはセルフホストである必要があります。
- GitLabは、ソースコード管理（SCM）をすぐに利用できる形で提供します。Jenkinsは、コードを保存するために別のSCMソリューションを必要とします。
- GitLabは、組み込みのコンテナレジストリを提供します。Jenkinsは、コンテナイメージを保存するために別のソリューションを必要とします。
- GitLabは、コードをスキャンするための組み込みテンプレートを提供します。Jenkinsは、コードをスキャンするためにサードパーティのプラグインを必要とします。

## 機能と概念の比較 {#comparison-of-features-and-concepts}

多くのJenkinsの機能と概念は、GitLabに同様の機能を提供する同等のものがあります。

### 設定ファイル {#configuration-file}

Jenkinsは、[Groovy形式の`Jenkinsfile`で](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/)設定できます。GitLab CI/CDは、デフォルトで`.gitlab-ci.yml`ファイルを使用します。

`Jenkinsfile`の例:

```groovy
pipeline {
    agent any

    stages {
        stage('hello') {
            steps {
                echo "Hello World"
            }
        }
    }
}
```

同等のGitLab CI/CD`.gitlab-ci.yml`ファイルは次のとおりです:

```yaml
stages:
  - hello

hello-job:
  stage: hello
  script:
    - echo "Hello World"
```

### Jenkinsパイプライン構文 {#jenkins-pipeline-syntax}

Jenkinsの設定は、セクションとディレクティブを持つ`pipeline`ブロックで構成されます。GitLab CI/CDは、YAMLキーワードで設定される同様の機能を持っています。

#### セクション {#sections}

| Jenkins  | GitLab         | 説明 |
|----------|----------------|-------------|
| `agent`  | `image`        | Jenkinsパイプラインはエージェント上で実行され、`agent`セクションはパイプラインの実行方法と使用するDockerコンテナを定義します。GitLabのジョブはRunner上で実行され、`image`キーワードは使用するコンテナを定義します。Kubernetesまたは任意のホストで独自のRunnerを設定できます。 |
| `post`   | `after_script`または`stage` | Jenkinsの`post`セクションは、ステージまたはパイプラインの最後に実行すべきアクションを定義します。GitLabでは、ジョブの最後に実行するコマンドには`after_script`を、ジョブ内の他のコマンドの前に実行するアクションには`before_script`を使用します。ジョブを実行する正確なステージを選択するには、`stage`を使用します。GitLabは、他のすべての定義されたステージの前後で常に実行される`.pre`と`.post`の両方のステージをサポートしています。 |
| `stages` | `stages`       | Jenkinsのステージはジョブのグループです。GitLab CI/CDもステージを使用しますが、より柔軟です。複数のステージをそれぞれ複数の独立したジョブで持つことができます。最上位レベルで`stages`を使用してステージとその実行順序を設定し、ジョブレベルで`stage`を使用してそのジョブのステージを定義します。 |
| `steps`  | `script`       | Jenkinsの`steps`は、実行する内容を定義します。GitLab CI/CDは、同様の`script`セクションを使用します。`script`セクションは、各コマンドを順に実行するための個別のエントリを持つYAML配列です。 |

#### ディレクティブ {#directives}

| Jenkins       | GitLab         | 説明 |
|---------------|----------------|-------------|
| `environment` | `variables`    | Jenkinsは、環境変数に`environment`を使用します。GitLab CI/CDは、ジョブの実行中だけでなく、より動的なパイプラインの設定にも使用できるCI/CD変数を定義するために`variables`キーワードを使用します。これらは、GitLab UIのCI/CD設定で設定することもできます。 |
| `options`     | 該当なし | Jenkinsは、タイムアウトやリトライ値などの追加の設定に`options`を使用します。GitLabはオプションの個別のセクションを必要とせず、すべての設定はジョブまたはパイプラインレベルで`timeout`または`retry`のようなCI/CDキーワードとして追加されます。 |
| `parameters`  | 該当なし | Jenkinsでは、パイプラインをトリガーする際にパラメータが必要になる場合があります。パラメータは、パイプラインの設定、プロジェクトの設定、ランタイムでUIを介して手動で、またはAPIなど、多くの場所で定義できるCI/CD変数によってGitLabで処理されます。 |
| `triggers`    | `rules`        | Jenkinsでは、`triggers`は、たとえばcron表記を通じて、パイプラインをいつ再度実行するかを定義します。GitLab CI/CDは、Gitの変更やマージリクエストの更新など、多くの理由でパイプラインを自動的に実行できます。ジョブを実行するイベントを制御するには、`rules`キーワードを使用します。スケジュールされたパイプラインは、プロジェクトの設定で定義されます。 |
| `tools`       | 該当なし | Jenkinsでは、`tools`は環境にインストールする追加ツールを定義します。GitLabには同様のキーワードはありません。ジョブに必要な正確なツールを組み込んだコンテナイメージを使用することが推奨されるためです。これらのイメージはキャッシュされ、パイプラインに必要なツールがすでに含まれるようにビルドできます。ジョブが追加のツールを必要とする場合、それらは`before_script`セクションの一部としてインストールできます。 |
| `input`       | 該当なし | Jenkinsでは、`input`はユーザー入力のプロンプトを追加します。`parameters`と同様に、入力はCI/CD変数を通じてGitLabで処理されます。 |
| `when`        | `rules`        | Jenkinsでは、`when`はステージを実行すべきタイミングを定義します。GitLabには、`when`キーワードもあります。これは、たとえばジョブが合格したか失敗したかなど、以前のジョブのステータスに基づいてジョブを開始すべきかを定義します。特定のパイプラインにジョブを追加するタイミングを制御するには、`rules`を使用します。 |

### 一般的な設定 {#common-configurations}

このセクションでは、一般的に使用されるCI/CDの設定について説明し、それらをJenkinsからGitLab CI/CDに変換する方法を示します。

[Jenkinsパイプライン](https://www.jenkins.io/doc/book/pipeline/)は、新しいコミットがプッシュするされるなど、特定のイベントが発生したときにトリガーするされる自動化されたCI/CDジョブを生成します。Jenkinsパイプラインは、`Jenkinsfile`で定義されます。GitLabの同等物は、[`.gitlab-ci.yml`設定ファイル](../yaml/_index.md)です。

Jenkinsはコードを保存する場所を提供しないため、`Jenkinsfile`は別のソースコントロールリポジトリに保存する必要があります。

#### ジョブ {#jobs}

ジョブは、特定の成果を達成するために設定された順序で実行される一連のコマンドです。

たとえば、`Jenkinsfile`でコンテナをビルドするし、それを本番環境にデプロイする場合:

```groovy
pipeline {
    agent any
    stages {
        stage('build') {
            agent { docker 'golang:alpine' }
            steps {
                apk update
                go build -o bin/hello
            }
            post {
              always {
                archiveArtifacts artifacts: 'bin/hello'
                onlyIfSuccessful: true
              }
            }
        }
        stage('deploy') {
            agent { docker 'golang:alpine' }
            when {
              branch 'staging'
            }
            steps {
                echo "Deploying to staging"
                scp bin/hello remoteuser@remotehost:/remote/directory
            }
        }
    }
}
```

この例では:

- `golang:alpine`コンテナイメージを使用します。
- コードをビルドするするためのジョブを実行します。
  - ビルドされた実行可能ファイルをアーティファクトとして保存します。
- `staging`にデプロイするための2番目のジョブを追加します。これは:
  - コミットが`staging`ブランチをターゲットにしている場合にのみ存在します。
  - ビルドステージが成功した後に開始されます。
  - 以前のジョブからのビルドされた実行可能アーティファクトを使用します。

同等のGitLab CI/CD`.gitlab-ci.yml`ファイルは次のとおりです:

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
  artifacts:
    paths:
      - bin/hello
```

##### 並列 {#parallel}

Jenkinsでは、以前のジョブに依存しないジョブは、`parallel`セクションに追加すると並列で実行できます。

たとえば、`Jenkinsfile`で:

```groovy
pipeline {
    agent any
    stages {
        stage('Parallel') {
            parallel {
                stage('Python') {
                    agent { docker 'python:latest' }
                    steps {
                        sh "python --version"
                    }
                }
                stage('Java') {
                    agent { docker 'openjdk:latest' }
                    when {
                        branch 'staging'
                    }
                    steps {
                        sh "java -version"
                    }
                }
            }
        }
    }
}
```

この例では、異なるコンテナイメージを使用して、PythonとJavaのジョブを並列で実行します。Javaのジョブは、`staging`ブランチが変更された場合にのみ実行されます。

同等のGitLab CI/CD`.gitlab-ci.yml`ファイルは次のとおりです:

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

この場合、ジョブを並列で実行するために追加の設定は必要ありません。ジョブはデフォルトで並列実行され、すべてのジョブに対して十分な数のRunnerがあることを前提として、それぞれが異なるRunner上で実行されます。Javaのジョブは、`staging`ブランチが変更された場合にのみ実行されるように設定されています。

##### マトリックス {#matrix}

GitLabでは、マトリックスを使用して、単一のパイプラインでジョブを複数回並列で実行できますが、ジョブの各インスタンスには異なる変数値が設定されます。Jenkinsはマトリックスを順次実行します。

たとえば、`Jenkinsfile`で:

```groovy
matrix {
    axes {
        axis {
            name 'PLATFORM'
            values 'linux', 'mac', 'windows'
        }
        axis {
            name 'ARCH'
            values 'x64', 'x86'
        }
    }
    stages {
        stage('build') {
            echo "Building $PLATFORM for $ARCH"
        }
        stage('test') {
            echo "Building $PLATFORM for $ARCH"
        }
        stage('deploy') {
            echo "Building $PLATFORM for $ARCH"
        }
    }
}
```

同等のGitLab CI/CD`.gitlab-ci.yml`ファイルは次のとおりです:

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
    - echo "Testing $PLATFORM for $ARCH"
```

#### コンテナイメージ {#container-images}

GitLabでは、[image](../yaml/_index.md#image)キーワードを使用して、[個別の隔離されたDockerコンテナでCI/CDジョブを実行](../docker/using_docker_images.md)できます。

たとえば、`Jenkinsfile`で:

```groovy
stage('Version') {
    agent { docker 'python:latest' }
    steps {
        echo 'Hello Python'
        sh 'python --version'
    }
}
```

この例は、`python:latest`コンテナで実行されるコマンドを示しています。

同等のGitLab CI/CD`.gitlab-ci.yml`ファイルは次のとおりです:

```yaml
version-job:
  image: python:latest
  script:
    - echo "Hello Python"
    - python --version
```

#### 変数 {#variables}

GitLabでは、[CI/CD変数](../variables/_index.md)を定義するために`variables`キーワードを使用します。変数を使用して、設定データを再利用したり、より動的な設定を行ったり、重要な値を保存したりできます。変数は、グローバルまたはジョブごとに定義できます。

たとえば、`Jenkinsfile`で:

```groovy
pipeline {
    agent any
    environment {
        NAME = 'Fern'
    }
    stages {
        stage('English') {
            environment {
                GREETING = 'Hello'
            }
            steps {
                sh 'echo "$GREETING $NAME"'
            }
        }
        stage('Spanish') {
            environment {
                GREETING = 'Hola'
            }
            steps {
                sh 'echo "$GREETING $NAME"'
            }
        }
    }
}
```

この例は、変数をジョブ内のコマンドに値を渡すために使用できる方法を示しています。

同等のGitLab CI/CD`.gitlab-ci.yml`ファイルは次のとおりです:

```yaml
default:
  image: alpine:latest

stages:
  - greet

variables:
  NAME: "Fern"

english:
  stage: greet
  variables:
    GREETING: "Hello"
  script:
    - echo "$GREETING $NAME"

spanish:
  stage: greet
  variables:
    GREETING: "Hola"
  script:
    - echo "$GREETING $NAME"
```

変数は、[GitLab UIのCI/CD設定で設定](../variables/_index.md#define-a-cicd-variable-in-the-ui)することもできます。場合によっては、[保護された](../variables/_index.md#protect-a-cicd-variable)および[マスクされた](../variables/_index.md#mask-a-cicd-variable)変数をシークレット値に使用できます。これらの変数は、設定ファイルで定義された変数と同じようにパイプラインジョブでアクセスできます。

たとえば、`Jenkinsfile`で:

```groovy
pipeline {
    agent any
    stages {
        stage('Example Username/Password') {
            environment {
                AWS_ACCESS_KEY = credentials('aws-access-key')
            }
            steps {
                sh 'my-login-script.sh $AWS_ACCESS_KEY'
            }
        }
    }
}
```

同等のGitLab CI/CD`.gitlab-ci.yml`ファイルは次のとおりです:

```yaml
login-job:
  script:
    - my-login-script.sh $AWS_ACCESS_KEY
```

さらに、GitLab CI/CDは、パイプラインとリポジトリに関連する値を含む[定義済み変数](../variables/predefined_variables.md)をすべてのパイプラインとジョブで利用可能にします。

#### 式と条件 {#expressions-and-conditionals}

新しいパイプラインが開始されると、GitLabはそのパイプラインでどのジョブを実行すべきかを確認します。変数のステータスやパイプラインのタイプなどの要因に応じてジョブを実行するように設定できます。

たとえば、`Jenkinsfile`で:

```groovy
stage('deploy_staging') {
    agent { docker 'alpine:latest' }
    when {
        branch 'staging'
    }
    steps {
        echo "Deploying to staging"
    }
}
```

この例では、コミットするブランチが`staging`という名前の場合にのみジョブが実行されます。

同等のGitLab CI/CD`.gitlab-ci.yml`ファイルは次のとおりです:

```yaml
deploy_staging:
  stage: deploy
  script:
    - echo "Deploy to staging server"
  rules:
    - if: '$CI_COMMIT_BRANCH == staging'
```

#### Runner {#runners}

Jenkinsのエージェントと同様に、GitLabのRunnerはジョブを実行するホストです。GitLab.comを使用している場合、独自のRunnerをプロビジョニングすることなくジョブを実行するために[インスタンスRunnerフリート](../runners/_index.md)を使用できます。

JenkinsのエージェントをGitLab CI/CDで使用できるように変換するには、エージェントをアンインストールしてから、[Runnerをインストールして登録](../runners/_index.md)します。Runnerは多くのオーバーヘッドを必要としないため、使用していたJenkinsのエージェントと同様のプロビジョニングを使用できる可能性があります。

Runnerに関するいくつかの主要な詳細:

- Runnerは、インスタンス、グループ全体、または単一のプロジェクトに特化して[共有されるように設定](../runners/runners_scope.md)できます。
- よりきめ細かな制御のために[`tags`キーワード](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)を使用し、Runnerを特定のジョブに関連付けることができます。たとえば、専用の、より強力な、または特定のハードウェアを必要とするジョブにはタグを使用できます。
- GitLabには、[Runnerのオートスケール](https://docs.gitlab.com/runner/configuration/autoscale/)機能があります。オートスケールを使用して、必要なときにのみRunnerをプロビジョニングするし、不要なときにスケールするダウンします。

たとえば、`Jenkinsfile`で:

```groovy
pipeline {
    agent none
    stages {
        stage('Linux') {
            agent {
                label 'linux'
            }
            steps {
                echo "Hello, $USER"
            }
        }
        stage('Windows') {
            agent {
                label 'windows'
            }
            steps {
                echo "Hello, %USERNAME%"
            }
        }
    }
}
```

同等のGitLab CI/CD`.gitlab-ci.yml`ファイルは次のとおりです:

```yaml
linux_job:
  stage: build
  tags:
    - linux
  script:
    - echo "Hello, $USER"

windows_job:
  stage: build
  tags:
    - windows
  script:
    - echo "Hello, %USERNAME%"
```

#### アーティファクト {#artifacts}

GitLabでは、任意のジョブが[`artifacts`キーワード](../yaml/_index.md#artifacts)を使用して、ジョブの完了時に保存するアーティファクトのセットを定義できます。[アーティファクト](../jobs/job_artifacts.md)は、たとえばテストやデプロイのために、以降のジョブで使用できるファイルです。

たとえば、`Jenkinsfile`で:

```groovy
stages {
    stage('Generate Cat') {
        steps {
            sh 'touch cat.txt'
            sh 'echo "meow" > cat.txt'
        }
        post {
            always {
                archiveArtifacts artifacts: 'cat.txt'
                onlyIfSuccessful: true
            }
        }
    }
    stage('Use Cat') {
        steps {
            sh 'cat cat.txt'
        }
    }
  }
```

同等のGitLab CI/CD`.gitlab-ci.yml`ファイルは次のとおりです:

```yaml
stages:
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
  artifacts:
    paths:
      - cat.txt
```

#### キャッシュ {#caching}

ジョブが1つ以上のファイルをダウンロードして将来の高速アクセスに備えて保存すると、[キャッシュ](../caching/_index.md)が作成されます。同じキャッシュを使用する後続のジョブは、ファイルを再度ダウンロードする必要がないため、より高速に実行されます。キャッシュはRunnerに保存され、[分散キャッシュが有効](https://docs.gitlab.com/runner/configuration/autoscale/#distributed-runners-caching)な場合はS3にアップロードされます。Jenkinsコアはキャッシュ機能を提供しません。

たとえば、`.gitlab-ci.yml`ファイルで:

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache-$CI_COMMIT_REF_SLUG
    paths:
      - binaries/
```

### Jenkinsプラグイン {#jenkins-plugins}

Jenkinsでプラグインを通じて有効になる一部の機能は、GitLabで同様の機能を提供するキーワードと機能によってネイティブにサポートされています。例: 

| Jenkinsプラグイン                                                                    | GitLabの機能 |
|-----------------------------------------------------------------------------------|----------------|
| [Build Timeout](https://plugins.jenkins.io/build-timeout/)                        | [`timeout`キーワード](../yaml/_index.md#timeout) |
| [Cobertura](https://plugins.jenkins.io/cobertura/)                                | [カバレッジレポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportscoverage_report)と[コードカバレッジ](../testing/code_coverage/_index.md) |
| [コードカバレッジAPI](https://plugins.jenkins.io/code-coverage-api/)                | [コードカバレッジ](../testing/code_coverage/_index.md)と[カバレッジの可視化](../testing/code_coverage/_index.md#coverage-visualization) |
| [Embeddable Build Status](https://plugins.jenkins.io/embeddable-build-status/)    | [パイプラインステータスバッジ](../../user/project/badges.md#pipeline-status-badges) |
| [JUnit](https://plugins.jenkins.io/junit/)                                        | [JUnitテストレポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportsjunit)と[単体テストレポート](../testing/unit_test_reports.md) |
| [Mailer](https://plugins.jenkins.io/mailer/)                                      | [通知メール](../../user/profile/notifications.md) |
| [Parameterizedトリガープラグイン](https://plugins.jenkins.io/parameterized-trigger/) | [`trigger`キーワード](../yaml/_index.md#trigger)と[ダウンストリームパイプライン](../pipelines/downstream_pipelines.md) |
| [ロールベース認可戦略](https://plugins.jenkins.io/role-strategy/)    | GitLabの[権限とロール](../../user/permissions.md) |
| [Timestamper](https://plugins.jenkins.io/timestamper/)                            | [ジョブ](../jobs/_index.md)ログにはデフォルトでタイムスタンプが付けられます。 |

### セキュリティスキャン機能 {#security-scanning-features}

Jenkinsで、コード品質、セキュリティ、または静的アプリケーションスキャンなどのプラグインを使用したことがあるかもしれません。GitLabは、SDLCのすべての部分で脆弱性を検出するために、すぐに使用できる[セキュリティスキャナー](../../user/application_security/_index.md)を提供します。これらのプラグインは、テンプレートを使用してGitLabに追加できます。たとえば、パイプラインにSASTスキャンを追加するには、`.gitlab-ci.yml`に以下を追加します:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

CI/CD変数を使用することで、セキュリティスキャナーの動作をカスタマイズできます。たとえば、[SASTスキャナー](../../user/application_security/sast/_index.md#available-cicd-variables)を使用する場合などです。

### シークレット管理 {#secrets-management}

「シークレット」とよく呼ばれる特権情報は、CI/CDワークフローで必要となる機密情報または認証情報です。シークレットを使用して、ツール、アプリケーション、コンテナ、およびクラウドネイティブ環境で保護されたリソースや機密情報をアンロックすることができます。

Jenkinsでのシークレット管理は通常、`Secret`タイプフィールドまたはCredentialsプラグインで処理されます。Jenkinsの設定に保存されている認証情報は、Credentials Bindingプラグインを使用することで、環境変数としてジョブに公開できます。

GitLabでのシークレット管理には、外部サービス向けの[サポートされているインテグレーション](../secrets/_index.md)のいずれかを使用できます。これらのサービスはGitLabプロジェクトの外部でシークレットを安全に保存しますが、そのサービスに対してサブスクリプションが必要です。

GitLabは、OIDCをサポートする他のサードパーティサービスに対しても[OIDC認証](../secrets/id_token_authentication.md)をサポートしています。

さらに、認証情報をCI/CD変数に保存することで、ジョブで利用可能にできますが、プレーンテキストで保存されたシークレットは、[Jenkins](https://www.jenkins.io/doc/developer/security/secrets/#storing-secrets)と同様に偶発的な漏洩の危険性があります。機密情報は、常に[マスクされた](../variables/_index.md#mask-a-cicd-variable)および[保護された](../variables/_index.md#protect-a-cicd-variable)変数に保存する必要があります。これにより、リスクの一部が軽減されます。

また、プロジェクトにアクセスできるすべてのユーザーに公開されている`.gitlab-ci.yml`ファイルに、シークレットを変数として保存しないでください。機密情報を変数に保存する場合は、[プロジェクト、グループ、またはインスタンスの設定](../variables/_index.md#define-a-cicd-variable-in-the-ui)でのみ行うべきです。

[セキュリティガイドライン](../variables/_index.md#cicd-variable-security)を確認して、CI/CD変数の安全性を向上させてください。

## 移行の計画と実行 {#planning-and-performing-a-migration}

以下の推奨ステップのリストは、この移行を迅速に完了できた組織を観察した後に作成されました。

### 移行計画の作成 {#create-a-migration-plan}

移行を開始する前に、移行の準備のために[移行計画](plan_a_migration.md)を作成する必要があります。Jenkinsからの移行のために、準備として以下の質問を自問してください:

- 今日、Jenkinsのジョブでどのようなプラグインが使用されていますか？
  - これらのプラグインが具体的に何をするかご存知ですか？
  - いずれかのプラグインが一般的なビルドツールをラップしていますか？たとえば、Maven、Gradle、またはNPMですか？
- Jenkinsのエージェントには何がインストールされていますか？
- 共有ライブラリは使用されていますか？
- Jenkinsからどのように認証していますか？SSHキー、APIトークン、または他のシークレットを使用していますか？
- パイプラインからアクセスする必要がある他のプロジェクトはありますか？
- 外部サービスにアクセスするためのJenkinsに認証情報はありますか？たとえば、Ansible Tower、Artifactory、または他のクラウドプロバイダーやデプロイターゲットですか？

### 前提条件 {#prerequisites}

移行作業を行う前に、まず以下を実行する必要があります:

1. GitLabに慣れてください。
   - [主要なGitLab CI/CD機能](../_index.md)について読んでください。
   - [最初のGitLabパイプライン](../quick_start/_index.md)と、静的サイトをビルドする、テストする、デプロイする[より複雑なパイプライン](../quick_start/tutorial.md)を作成するためのチュートリアルに従ってください。
   - [CI/CD YAML構文リファレンス](../yaml/_index.md)を確認してください。
1. GitLabを設定してセットアップします。
1. GitLabインスタンスをテストします。
   - 共有GitLab.com Runnerを使用するか、新しいRunnerをインストールすることで、[Runner](../runners/_index.md)が利用可能であることを確認してください。

### 移行ステップ {#migration-steps}

1. プロジェクトをSCMソリューションからGitLabへ移行する。
   - （推奨）利用可能な[インポーター](../../user/import/_index.md)を使用して、外部SCMプロバイダーからの大量のインポートを自動化できます。
   - あなたは[URLでリポジトリをインポート](../../user/project/import/repo_by_url.md)できます。
1. 各プロジェクトに`.gitlab-ci.yml`ファイルを作成します。
1. Jenkinsの設定をGitLab CI/CDジョブに移行するし、マージリクエストに直接結果を表示するように設定します。
1. [クラウドデプロイテンプレート](../cloud_deployment/_index.md) 、[環境](../environments/_index.md) 、および[Kubernetes向けGitLabエージェント](../../user/clusters/agent/_index.md)を使用して、デプロイメントジョブを移行する。
1. 異なるプロジェクト間でCI/CDの設定を再利用できるかどうかを確認し、CI/CDテンプレートを作成して共有します。
1. [パイプライン効率性ドキュメント](../pipelines/pipeline_efficiency.md)を確認して、GitLab CI/CDパイプラインをより高速かつ高効率的にする方法を学んでください。

### 追加リソース {#additional-resources}

- [JenkinsFileラッパー](https://gitlab.com/gitlab-org/jfr-container-builder/)を使用して、プラグインを含む完全なJenkinsインスタンスをGitLab CI/CDジョブ内で実行できます。このツールを使用して、緊急性の低いパイプラインの移行を遅らせることで、GitLab CI/CDへの移行を容易にしてください。

  > [!note]
  > JenkinsFileラッパーはGitLabにはパッケージ化されておらず、サポート範囲外です。詳細については、[サポートに関する声明](https://about.gitlab.com/support/statement-of-support/)を参照してください。

ここで回答されていない質問がある場合は、[GitLabコミュニティフォーラム](https://forum.gitlab.com/)が優れたリソースとなりえます。
