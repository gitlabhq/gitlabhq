---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: MavenビルドをJenkinsからに移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

JenkinsでMavenビルドを使用している場合は、[Java Spring](https://gitlab.com/gitlab-org/project-templates/spring)プロジェクトテンプレートを使用してGitLabに移行できます。このテンプレートでは、基盤となる依存関係の管理にMavenを使用します。

## Jenkinsの設定例 {#sample-jenkins-configurations}

次の3つのJenkinsの例では、それぞれ異なる方法でMavenプロジェクトをテスト、ビルド、およびシェルエージェントにインストールします:

- シェル実行によるフリースタイル
- Mavenタスクプラグインを使用したフリースタイル
- Jenkinsfileを使用した宣言型パイプライン

3つの例はすべて、3つの異なるステージングで、同じ3つのコマンドを順番に実行します:

- `mvn test`: コードベースで見つかったテストを実行します
- `mvn package -DskipTests`: POMで定義された実行可能なタイプにコードをコンパイルし、最初のステージングでテストが完了しているため、テストの実行をスキップします。
- `mvn install -DskipTests`: コンパイルされた実行可能ファイルをエージェントのローカルMaven `.m2`リポジトリにインストールし、テストの実行を再度スキップします。

これらの例では、単一の永続的なJenkinsエージェントを使用します。これには、Mavenがエージェントにプリインストールされている必要があります。この実行方法は、[シェルexecutor](https://docs.gitlab.com/runner/executors/shell.html)を使用するに似ています。

### シェル実行によるフリースタイル {#freestyle-with-shell-execution}

Jenkinsの組み込みシェル実行オプションを使用して、エージェント上のシェルから`mvn`コマンドを直接呼び出す場合、設定は次のようになります:

![Mavenコマンドがシェルコマンドとして定義されたビルドステップを示すJenkins UI。](img/maven-freestyle-shell_v16_4.png)

### Mavenタスクプラグインを使用したフリースタイル {#freestyle-with-maven-task-plugin}

[Mavenビルドライフサイクル](https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html)で特定のゴールを宣言して実行するためにJenkinsでMavenプラグインを使用する場合、設定は次のようになります:

![Mavenプラグインを使用してMavenコマンドが定義されたビルドステップを示すJenkins UI。](img/maven-freestyle-plugin_v16_4.png)

このプラグインでは、MavenをJenkinsエージェントにインストールする必要があり、Mavenコマンドを呼び出すためのスクリプトラッパーを使用します。

### 宣言型パイプラインの使用 {#using-a-declarative-pipeline}

宣言型パイプラインを使用する場合、設定は次のようになります:

```groovy
pipeline {
    agent any
    tools {
        maven 'maven-3.6.3'
        jdk 'jdk11'
    }
    stages {
        stage('Build') {
            steps {
                sh "mvn package -DskipTests"
            }
        }
        stage('Test') {
            steps {
                sh "mvn test"
            }
        }
        stage('Install') {
            steps {
                sh "mvn install -DskipTests"
            }
        }
    }
}
```

この例では、プラグインの代わりにシェル実行コマンドを使用します。

デフォルトでは、宣言型パイプライン設定は、Jenkinsパイプライン設定、または`Jenksinfile`のGitリポジトリに直接保存されます。

## Jenkinsの設定をに変換する {#convert-jenkins-configuration-to-gitlab-cicd}

前の例はすべてわずかに異なりますが、同じパイプライン設定でに移行できます。

前提要件: 

- シェルexecutorを備えた
- シェルランナーにインストールされているMaven 3.6.3およびJava 11 JDK

この例は、Jenkinsでのビルド、テスト、インストールの動作と構文を模倣しています。

 パイプラインでは、コマンドはステージにグループ化された「ジョブ」で実行されます。`.gitlab-ci.yml`設定ファイルで移行された設定は、2つのグローバルキーワード（`stages`と`variables`）と、それに続く3つのジョブで構成されます:

```yaml
stages:
  - build
  - test
  - install

variables:
  MAVEN_OPTS: >-
    -Dhttps.protocols=TLSv1.2
    -Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository
  MAVEN_CLI_OPTS: >-
    -DskipTests

build-JAR:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS package

test-code:
  stage: test
  script:
    - mvn test

install-JAR:
  stage: install
  script:
    - mvn $MAVEN_CLI_OPTS install
```

この例では: 

- `stages`は、順番に実行される3つのステージを定義します。前のJenkinsの例と同様に、テストジョブが最初に実行され、次にビルドジョブ、最後にインストールジョブが実行されます。
- `variables`は、すべてのジョブで使用できる[CI/CD変数](../../variables/_index.md)を定義します:
  - `MAVEN_OPTS`は、Mavenの実行時に必要なMaven環境変数です:
    - `-Dhttps.protocols=TLSv1.2`は、パイプライン内のすべてのHTTPリクエストに対して、TLSプロトコルをバージョン1.2に設定します。
    - `-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository`は、ローカルMavenリポジトリの場所をランナー上のGitLabプロジェクトディレクトリに設定して、ジョブがリポジトリにアクセスして変更できるようにします。
  - `MAVEN_CLI_OPTS`は、`mvn`コマンドに追加される特定の引数です:
    - `-DskipTests`は、Mavenビルドライフサイクルの`test`ステージをスキップします。
- `test-code`、`build-JAR`、および`install-JAR`は、パイプラインで実行するジョブのユーザー定義名です:
  - `stage`は、ジョブが実行されるステージを定義します。1つのパイプラインには1つ以上のステージが含まれ、1つのステージには1つ以上のジョブが含まれます。この例には3つのステージがあり、それぞれに1つのジョブがあります。
  - `script`は、そのジョブで実行するコマンドを定義します。`steps`内の`Jenkinsfile`に似ています。ジョブはイメージコンテナ内で実行される複数のコマンドを順番に実行できますが、この例では、ジョブはそれぞれ1つのコマンドのみを実行します。

### Dockerコンテナでジョブを実行する {#run-jobs-in-docker-containers}

Jenkinsのサンプルと同様に、このビルド処理を処理するために永続的なマシンを使用する代わりに、この例では一時的なDockerコンテナを使用して実行を処理します。コンテナを使用すると、仮想マシンとそれにインストールされているMavenバージョンをメンテナンスする必要がなくなります。また、パイプラインの機能を展開および拡張する柔軟性も向上します。

前提要件: 

- プロジェクトで使用できるDocker executorを備えた。GitLab.comを使用している場合は、パブリックインスタンスRunnerを使用できます。

この移行されたパイプライン設定は、3つのグローバルキーワード（`stages`、`default`、`variables`）と、それに続く3つのジョブで構成されます。この設定では、[前の例](#convert-jenkins-configuration-to-gitlab-cicd)と比較して、改善されたパイプラインのために追加の機能を利用しています:

```yaml
stages:
  - build
  - test
  - install

default:
  image: maven:3.6.3-openjdk-11
  cache:
    key: $CI_COMMIT_REF_SLUG
    paths:
      - .m2/

variables:
  MAVEN_OPTS: >-
    -Dhttps.protocols=TLSv1.2
    -Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository
  MAVEN_CLI_OPTS: >-
    -DskipTests

build-JAR:
  stage: build
  script:
    - mvn $MAVEN_CLI_OPTS package

test-code:
  stage: test
  script:
    - mvn test

install-JAR:
  stage: install
  script:
    - mvn $MAVEN_CLI_OPTS install
```

この例では: 

- `stages`は、順番に実行される3つのステージを定義します。前のJenkinsの例と同様に、テストジョブが最初に実行され、次にビルドジョブ、最後にインストールジョブが実行されます。
- `default`は、デフォルトですべてのジョブで再利用する標準設定を定義します:
  - `image`は、使用するDockerイメージコンテナと、その中でコマンドを実行することを定義します。この例では、必要なものがすべてインストールされている公式Maven Dockerイメージです。
  - `cache`は、依存関係をキャッシュして再利用するために使用されます:
    - `key`は、特定のキャッシュアーカイブの一意の識別子です。この例では、[事前定義されたCI/CD変数](../../variables/predefined_variables.md)として自動生成された、Gitコミットrefsの短縮バージョンです。同じコミットrefsに対して実行されるジョブは、同じキャッシュを再利用します。
    - `paths`は、キャッシュに含めるディレクトリまたはファイルです。この例では、ジョブの実行間で依存関係を再インストールしないように、`.m2/`ディレクトリをキャッシュします。
- `variables`は、すべてのジョブで使用できる[CI/CD変数](../../variables/_index.md)を定義します:
  - `MAVEN_OPTS`は、Mavenの実行時に必要なMaven環境変数です:
    - `-Dhttps.protocols=TLSv1.2`は、パイプライン内のすべてのHTTPリクエストに対して、TLSプロトコルをバージョン1.2に設定します。
    - `-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository`は、ローカルMavenリポジトリの場所をランナー上のGitLabプロジェクトディレクトリに設定して、ジョブがリポジトリにアクセスして変更できるようにします。
  - `MAVEN_CLI_OPTS`は、`mvn`コマンドに追加される特定の引数です:
    - `-DskipTests`は、Mavenビルドライフサイクルの`test`ステージをスキップします。
- `test-code`、`build-JAR`、および`install-JAR`は、パイプラインで実行するジョブのユーザー定義名です:
  - `stage`は、ジョブが実行されるステージを定義します。1つのパイプラインには1つ以上のステージが含まれ、1つのステージには1つ以上のジョブが含まれます。この例には3つのステージがあり、それぞれに1つのジョブがあります。
  - `script`は、そのジョブで実行するコマンドを定義します。`steps`内の`Jenkinsfile`に似ています。ジョブはイメージコンテナ内で実行される複数のコマンドを順番に実行できますが、この例では、ジョブはそれぞれ1つのコマンドのみを実行します。
