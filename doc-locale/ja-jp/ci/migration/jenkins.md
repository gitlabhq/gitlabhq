---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Jenkinsから移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

JenkinsからGitLab CI/CDに移行する場合、Jenkinsのワークフローをレプリケートおよび強化するCI/パイプラインを作成できます。

## 主な類似点と相違点 {#key-similarities-and-differences}

GitLab CI/CDとJenkinsは、いくつかの類似点があるCI/ツールです。GitLabとJenkinsの両方:

- ジョブのコレクションにステージを使用します。
- コンテナベースのビルドをサポートします。

さらに、両者にはいくつかの重要な違いがあります:

- GitLab CI/CDのパイプラインはすべて、YAML形式の設定ファイルで設定されます。Jenkinsは、Groovy形式の設定ファイル（宣言型パイプライン）またはJenkins DSL（スクリプト型パイプライン）のいずれかを使用します。
- GitLabは、マルチテナントSaaSサービスである[GitLab.com](../../subscriptions/gitlab_com/_index.md)と、完全に分離されたシングルテナントSaaSサービスである[GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md)を提供しています。独自の[Self-Managedインスタンス](../../subscriptions/self_managed/_index.md)を実行することもできます。Jenkinsのデプロイメントは、セルフホストである必要があります。
- GitLabは、すぐに使用できるソースコード管理（SCM）を提供します。Jenkinsでは、コードを保存するために、別のSCMソリューションが必要です。
- GitLabは、組み込みのコンテナイメージレジストリを提供します。Jenkinsでは、コンテナイメージを保存するために、別のソリューションが必要です。
- GitLabは、コードをスキャンするための組み込みテンプレートを提供します。Jenkinsでは、コードをスキャンするために、サードパーティのプラグインが必要です。

## 機能とコンセプトの比較 {#comparison-of-features-and-concepts}

多くのJenkinsの機能とコンセプトには、同じ機能を提供するGitLabと同等の機能があります。

### 設定ファイル {#configuration-file}

Jenkinsは[`Jenkinsfile`（Groovy形式）](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/)で設定できます。GitLab CI/CDは、デフォルトで`.gitlab-ci.yml`ファイルを使用します。

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

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
stages:
  - hello

hello-job:
  stage: hello
  script:
    - echo "Hello World"
```

### Jenkinsのパイプラインの構文 {#jenkins-pipeline-syntax}

Jenkinsの設定は、セクションとディレクティブを含む`pipeline`ブロックで構成されています。GitLab CI/CDには同様の機能があり、YAMLキーワードで設定されます。

#### セクション {#sections}

| Jenkins  | GitLab         | 説明 |
|----------|----------------|-------------|
| `agent`  | `image`        | Jenkinsのパイプラインはエージェント上で実行され、`agent`セクションでは、パイプラインの実行方法と使用するDockerコンテナを定義します。GitLabのジョブはRunner上で実行され、`image`キーワードは使用するコンテナを定義します。独自のRunnerをKubernetesまたは任意のホストに設定できます。 |
| `post`   | `after_script`または`stage` | Jenkinsの`post`セクションでは、ステージまたはパイプラインの最後に実行する必要があるアクションを定義します。GitLabでは、ジョブの最後に実行するコマンドには`after_script`を使用し、ジョブ内の他のコマンドの前に実行するアクションには`before_script`を使用します。ジョブを実行する正確なステージを選択するには、`stage`を使用します。GitLabは、常に他の定義されたステージの前に、または後に実行される`.pre`と`.post`の両方のステージをサポートしています。 |
| `stages` | `stages`       | Jenkinsのステージはジョブのグループです。GitLab CI/CDでもステージが使用されますが、より柔軟性があります。複数の独立したジョブを持つ複数のステージを持つことができます。最上位レベルでステージとその実行順序を定義するには`stages`を使用し、ジョブレベルでそのジョブのステージを定義するには`stage`を使用します。 |
| `steps`  | `script`       | Jenkins `steps`は、実行する内容を定義します。GitLab CI/CDは、同様の`script`セクションを使用します。`script`セクションは、順番に実行する各コマンドのエントリを含むYAML配列です。 |

#### ディレクティブ {#directives}

| Jenkins       | GitLab         | 説明 |
|---------------|----------------|-------------|
| `environment` | `variables`    | Jenkinsは、環境変数に`environment`を使用します。GitLab CI/CDは、ジョブの実行中に使用できるだけでなく、より動的なパイプラインの設定にも使用できるCI/CD変数を定義するために、`variables`キーワードを使用します。これらは、GitLab UIのCI/CD設定でも設定できます。 |
| `options`     | 該当なし | Jenkinsは、タイムアウトやリトライ値などの追加の設定に`options`を使用します。GitLabにはオプション用の別のセクションは必要ありません。すべての設定は、ジョブまたはパイプラインレベルでCI/キーワードとして追加されます（例: `timeout`または`retry`）。 |
| `parameters`  | 該当なし | Jenkinsでは、パイプラインをトリガーするときにパラメータが必要になる場合があります。パラメータはGitLabではCI/CI/CD変数で処理され、パイプラインの設定、プロジェクト設定、UIを介して手動で、またはAPIを介して、実行時に手動でなど、多くの場所で定義できます。 |
| `triggers`    | `rules`        | Jenkinsでは、`triggers`は、cron表記などを介して、パイプラインを再度実行するタイミングを定義します。GitLab CI/CDは、Gitの変更やマージリクエストの更新など、さまざまな理由でパイプラインを自動的に実行できます。`rules`キーワードを使用して、ジョブを実行するイベントを制御します。スケジュールされたパイプラインは、プロジェクト設定で定義されています。 |
| `tools`       | 該当なし | Jenkinsでは、`tools`は環境にインストールする追加のツールを定義します。GitLabには同様のキーワードはありません。推奨事項は、ジョブに必要な正確なツールを使用して事前にビルドされたコンテナイメージを使用することです。これらのイメージはキャッシュされ、パイプラインに必要なツールがすでに含まれるようにビルドできます。ジョブに追加のツールが必要な場合は、`before_script`セクションの一部としてインストールできます。 |
| `input`       | 該当なし | Jenkinsでは、`input`はユーザー入力のプロンプトを追加します。`parameters`と同様に、入力はGitLabではCI/CI/CD変数を介して処理されます。 |
| `when`        | `rules`        | Jenkinsでは、`when`はステージを実行するタイミングを定義します。GitLabには`when`キーワードもあり、ジョブが合格または失敗した場合など、以前のジョブのステータスに基づいてジョブの実行を開始するかどうかを定義します。ジョブを特定のパイプラインに追加するタイミングを制御するには、`rules`を使用します。 |

### 共通設定 {#common-configurations}

このセクションでは、一般的なCI/CI/CD設定GitLab CI/CDに変換する方法を示します。

[Jenkinsパイプライン](https://www.jenkins.io/doc/book/pipeline/)は、新しいコミットのプッシュなど、特定のイベントが発生したときにトリガーされる自動化されたCI/ジョブを生成します。Jenkinsのパイプラインは、`Jenkinsfile`で定義されています。GitLabの同等のものは、[`.gitlab-ci.yml`設定ファイル](../yaml/_index.md)です。

Jenkinsにはソースコードを保存する場所がないため、`Jenkinsfile`は別のソースコントロールリポジトリに保存する必要があります。

#### ジョブ {#jobs}

ジョブは、特定の結果を達成するために、一連のシーケンスで実行される一連のコマンドです。

たとえば、コンテナをビルドしてから、本番環境にデプロイします（`Jenkinsfile`の場合）:

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
- コードをビルドするためのジョブを実行します。
  - ビルドされた実行可能ファイルをアーティファクトとして保存します。
- `staging`にデプロイする2番目のジョブを追加します。これは次のとおりです:
  - コミットが`staging`ブランチをターゲットにしている場合にのみ存在します。
  - ビルドステージが成功した後に開始します。
  - 以前のジョブからビルドされた実行可能ファイルアーティファクトを使用します。

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
  artifacts:
    paths:
      - bin/hello
```

##### 並列 {#parallel}

Jenkinsでは、以前のジョブに依存しないジョブは、`parallel`セクションに追加すると並行して実行できます。

次に、`Jenkinsfile`の例を示します:

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

この場合、ジョブを並行して実行するために、追加の設定は必要ありません。ジョブは、デフォルトで並行して実行されます。各ジョブに十分なRunnerがある場合は、異なるRunnerで実行されます。Javaジョブは、`staging`ブランチが変更された場合にのみ実行するように設定されています。

##### マトリックス {#matrix}

GitLabでは、ジョブでを使用して、単一のパイプライン内で複数のジョブを並行して実行できます。ただし、ジョブのインスタンスごとに異なる変数の値を使用します。Jenkinsはマトリックスを順番に実行します。

次に、`Jenkinsfile`の例を示します:

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
    - echo "Testing $PLATFORM for $ARCH"
```

#### コンテナイメージ {#container-images}

GitLabでは、[個別の分離されたDockerコンテナでCI/ジョブを実行](../docker/using_docker_images.md)するには、[image](../yaml/_index.md#image)キーワードを使用します。

次に、`Jenkinsfile`の例を示します:

```groovy
stage('Version') {
    agent { docker 'python:latest' }
    steps {
        echo 'Hello Python'
        sh 'python --version'
    }
}
```

この例は、`python:latest`コンテナで実行されているコマンドを示しています。

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
version-job:
  image: python:latest
  script:
    - echo "Hello Python"
    - python --version
```

#### 変数 {#variables}

GitLabでは、`variables`キーワードを使用して[CI/CI/CD変数](../variables/_index.md)を定義します。変数を使用すると、設定データを再利用したり、より動的な設定を行ったり、重要な値を保存したりできます。変数は、グローバルまたはジョブごとに定義できます。

次に、`Jenkinsfile`の例を示します:

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

この例は、変数を使用してジョブ内のコマンドに値を渡す方法を示しています。

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

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

変数は、[GitLab UIのCI/設定で設定](../variables/_index.md#define-a-cicd-variable-in-the-ui)することもできます。場合によっては、[保護された](../variables/_index.md#protect-a-cicd-variable)変数と[マスクされた](../variables/_index.md#mask-a-cicd-variable)変数をシークレット値に使用できます。これらの変数は、設定ファイルで定義された変数と同じように、パイプラインジョブでアクセスできます。

次に、`Jenkinsfile`の例を示します:

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

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

```yaml
login-job:
  script:
    - my-login-script.sh $AWS_ACCESS_KEY
```

さらに、GitLab CI/CDは、[定義済みの変数](../variables/predefined_variables.md)をすべてのパイプラインとジョブで使用できるようにします。これには、パイプラインとリポジトリに関連する値が含まれています。

#### 式と条件 {#expressions-and-conditionals}

新しいパイプラインが開始されると、GitLabはそのパイプラインで実行するジョブをチェックします。変数の状態やパイプラインの種類などの要因に応じて、ジョブを実行するように設定できます。

次に、`Jenkinsfile`の例を示します:

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

この例では、コミット先のブランチの名前が`staging`の場合にのみ、ジョブが実行されます。

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

Jenkinsエージェントと同様に、GitLab Runnerはジョブを実行するホストです。GitLab.comを使用している場合は、独自のRunnerをプロビジョニングせずに、[インスタンスRunnerフリート](../runners/_index.md)を使用してジョブを実行できます。

GitLab CI/CDで使用するためにJenkinsエージェントを変換するには、エージェントをアンインストールしてから、[Runnerをインストールして登録](../runners/_index.md)します。Runnerはそれほどオーバーヘッドを必要としないため、使用していたJenkinsエージェントと同様のプロビジョニングを使用できる場合があります。

Runnerに関する主な詳細:

- Runnerは、インスタンス、グループ全体で共有するように、または単一のプロジェクト専用にするように[設定](../runners/runners_scope.md)できます。
- より細かく制御するには、[`tags`キーワード](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)を使用し、Runnerを特定のジョブに関連付けます。たとえば、専用の、より強力な、または特定のハードウェアを必要とするジョブにタグを使用できます。
- GitLabには、[Runnerのオートスケール](https://docs.gitlab.com/runner/configuration/autoscale.html)があります。オートスケールを使用して、必要な場合にのみRunnerをプロビジョニングし、不要な場合はスケールダウンします。

次に、`Jenkinsfile`の例を示します:

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

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

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

GitLabでは、ジョブは[`artifacts`](../yaml/_index.md#artifacts)キーワードを使用して、ジョブの完了時に保存するアーティファクトの設定を定義できます。[アーティファクト](../jobs/job_artifacts.md)は、たとえばテストやデプロイなど、後のジョブで使用できるファイルです。

次に、`Jenkinsfile`の例を示します:

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

同等のGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

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

[キャッシュ](../caching/_index.md)は、ジョブが1つ以上のファイルをダウンロードし、将来のアクセスを高速化するために保存するときに作成されます。同じキャッシュを使用する後続のジョブは、ファイルを再度ダウンロードする必要がないため、より高速に実行されます。キャッシュはRunnerに保存され、[分散キャッシュが有効](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching)になっている場合はS3にアップロードされます。Jenkinsコアはキャッシュを提供しません。

たとえば、`.gitlab-ci.yml`という名前のファイルでは、次のようになります:

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

プラグインを介して有効になっているJenkinsの一部の機能は、同様の機能を提供するキーワードと機能を備えたGitLabでネイティブにサポートされています。例: 

| Jenkinsプラグイン                                                                    | GitLabの機能 |
|-----------------------------------------------------------------------------------|----------------|
| [ビルドタイムアウト](https://plugins.jenkins.io/build-timeout/)                        | [`timeout`キーワード](../yaml/_index.md#timeout) |
| [Cobertura](https://plugins.jenkins.io/cobertura/):                                | [カバレッジ](../yaml/artifacts_reports.md#artifactsreportscoverage_report)レポートアーティファクトおよび[Code Coverage](../testing/code_coverage/_index.md) |
| [Code coverage API](https://plugins.jenkins.io/code-coverage-api/)                | [Code Coverage](../testing/code_coverage/_index.md)と[カバレッジ](../testing/code_coverage/_index.md#coverage-visualization)の可視化 |
| [埋め込み可能なビルドステータス](https://plugins.jenkins.io/embeddable-build-status/)    | [パイプラインステータスバッジ](../../user/project/badges.md#pipeline-status-badges) |
| [JUnit](https://plugins.jenkins.io/junit/)                                        | [JUnitテストレポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportsjunit)と[単体テストレポート](../testing/unit_test_reports.md) |
| [メーラー](https://plugins.jenkins.io/mailer/)                                      | [通知メール](../../user/profile/notifications.md) |
| [パラメータ化されたトリガープラグイン](https://plugins.jenkins.io/parameterized-trigger/) | [`trigger`キーワード](../yaml/_index.md#trigger)と[ダウンストリームパイプライン](../pipelines/downstream_pipelines.md) |
| [ロールベースの認可戦略](https://plugins.jenkins.io/role-strategy/)    | GitLabの[権限とロール](../../user/permissions.md) |
| [タイムスタンパー](https://plugins.jenkins.io/timestamper/)                            | [ジョブ](../jobs/_index.md)ログはデフォルトでタイムスタンプされます |

### セキュリティスキャン機能 {#security-scanning-features}

Jenkinsで、コード品質、セキュリティ、または静的アプリケーションスキャンなどのプラグインを使用したことがあるかもしれません。GitLabには、SDLCのすべての部分の脆弱性を検出するために、すぐに使用できる[セキュリティスキャナー](../../user/application_security/_index.md)が用意されています。これらのプラグインは、テンプレートを使用してGitLabに追加できます。たとえば、パイプラインにSASTスキャンを追加するには、次の`.gitlab-ci.yml`を追加します:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

CI/CD変数を使用すると、[SASTスキャナー](../../user/application_security/sast/_index.md#available-cicd-variables)などを使用して、セキュリティスキャナーの動作をカスタマイズできます。

### シークレット管理 {#secrets-management}

特権情報、多くの場合「シークレット」と呼ばれるものは、CI/CDワークフローで必要な機密情報または認証情報です。シークレットを使用して、保護されたリソース、またはツール、アプリケーション、コンテナ、クラウドネイティブ環境内の機密情報のロックを解除できます。

Jenkinsのシークレット管理は通常、`Secret`タイプのフィールドまたはCredentialsプラグインで処理されます。Jenkins設定に保存されている認証情報は、Credentials Bindingプラグインを使用することにより、環境変数としてジョブに公開できます。

GitLabのシークレット管理では、外部サービスでサポートされている[インテグレーション](../secrets/_index.md)の1つを使用できます。これらのサービスは、GitLabプロジェクトの外部にシークレットを安全に保存しますが、サービスのサブスクリプションが必要です。

GitLabは、OIDCをサポートする他のサードパーティサービスに対して、[OIDC認証](../secrets/id_token_authentication.md)もサポートしています。

さらに、CI/CD変数に保存することで、ジョブで認証情報を使用できるようにすることもできます。ただし、プレーンテキストで保存されているシークレットは、[Jenkinsと同じように](https://www.jenkins.io/doc/developer/security/secrets/#storing-secrets)、誤って公開される可能性があります。リスクを軽減するために、[マスク](../variables/_index.md#mask-a-cicd-variable)された変数と[保護された](../variables/_index.md#protect-a-cicd-variable)変数に機密情報を常に保存する必要があります。

また、`.gitlab-ci.yml`ファイルに変数をシークレットとして保存しないでください。これは、プロジェクトへのアクセス権を持つすべてのユーザーに公開されます。機密情報を変数に保存することは、[プロジェクト、グループ、またはインスタンス設定](../variables/_index.md#define-a-cicd-variable-in-the-ui)でのみ行う必要があります。

CI/CD変数の安全性を向上させるには、[セキュリティガイドライン](../variables/_index.md#cicd-variable-security)を確認してください。

## 移行の計画と実行 {#planning-and-performing-a-migration}

次に示す推奨手順のリストは、この移行を迅速に完了できた組織を観察した後に作成されました。

### 移行計画を作成する {#create-a-migration-plan}

移行を開始する前に、移行の準備を行うために、[移行計画](plan_a_migration.md)を作成する必要があります。Jenkinsからの移行の場合は、準備として次の質問を自問してください:

- 現在、Jenkinsのジョブで使用されているプラグインは何ですか？
  - これらのプラグインが正確に何をするか知っていますか？
  - プラグインは、一般的なビルドツールをラップしますか？たとえば、Maven、Gradle、またはNPMですか？
- Jenkinsエージェントに何がインストールされていますか？
- 使用中の共有ライブラリはありますか？
- Jenkinsからどのように認証していますか？SSHキー、APIトークン、またはその他のシークレットを使用していますか？
- パイプラインからアクセスする必要がある他のGitLabプロジェクトはありますか？
- 外部サービスにアクセスするための認証情報がJenkinsにありますか？たとえば、Ansible Tower、Artifactory、またはその他のクラウドプロバイダーまたはデプロイターゲットですか？

### 前提要件 {#prerequisites}

何らかの移行作業を行う前に、まず以下を行う必要があります:

1. GitLabに慣れてください。
   - [主なGitLab CI/CD機能](../_index.md)についてお読みください。
   - [最初のGitLabパイプラインを](../quick_start/_index.md)作成し、静的サイトをビルド、テスト、およびデプロイする[より複雑なパイプラインを](../quick_start/tutorial.md)作成するためのチュートリアルに従ってください。
   - [CI/CD YAML構文リファレンス](../yaml/_index.md)を確認してください。
1. GitLabをセットアップして構成します。
1. GitLabインスタンスをテストします。
   - [GitLab Runner](../runners/_index.md)が利用可能であることを確認します。共有GitLab.com Runnerを使用するか、新しいRunnerをインストールします。

### 移行の手順 {#migration-steps}

1. SCMソリューションからGitLabにプロジェクトを移行します。
   - （推奨）利用可能な[インポーター](../../user/project/import/_index.md)を使用して、外部SCMプロバイダーからの大量インポートを自動化できます。
   - [URLでリポジトリをインポートする](../../user/project/import/repo_by_url.md)ことができます。
1. 各プロジェクトに`.gitlab-ci.yml`ファイルを作成します。
1. Jenkins設定をGitLab CI/CDジョブに移行し、マージリクエストに直接結果を表示するように構成します。
1. [クラウドデプロイテンプレート](../cloud_deployment/_index.md) 、[環境](../environments/_index.md) 、および[Kubernetes向けGitLabエージェント](../../user/clusters/agent/_index.md)を使用して、デプロイメントジョブを移行します。
1. 異なるプロジェクト間で再利用できるCI/CD設定があるかどうかを確認し、CI/CDテンプレートを作成して共有します。
1. [パイプラインの効率性に関するドキュメント](../pipelines/pipeline_efficiency.md)を確認して、GitLab CI/CDパイプラインをより高速かつ効率的にする方法を学んでください。

### その他のリソース {#additional-resources}

- [JenkinsFileラッパー](https://gitlab.com/gitlab-org/jfr-container-builder/)を使用して、プラグインを含むGitLab CI/CDジョブ内で完全なJenkinsインスタンスを実行できます。このツールを使用して、緊急性の低いパイプラインの移行を遅らせることにより、GitLab CI/CDへの移行を容易にしてください。

  {{< alert type="note" >}}

  JenkinsFileラッパーはGitLabにパッケージ化されておらず、サポートのスコープ外です。詳細については、[サポートステートメント](https://about.gitlab.com/support/statement-of-support/)を参照してください。

  {{< /alert >}}

ここに記載されていない質問がある場合は、[GitLabコミュニティフォーラム](https://forum.gitlab.com/)が役立ちます。
