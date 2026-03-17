---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Coberturaカバレッジレポート
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

カバレッジ解析を機能させるには、適切にフォーマットされた[Cobertura XML](https://cobertura.github.io/cobertura/)レポートを[`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)に提供する必要があります。この形式は元々Java用に開発されたものですが、他の言語やプラットフォームのほとんどのカバレッジ解析フレームワークには、それをサポートするプラグインがあります。次に例を示します:

- [simplecov-cobertura](https://rubygems.org/gems/simplecov-cobertura)（Ruby）
- [gocover-cobertura](https://github.com/boumenot/gocover-cobertura)（Go）
- [cobertura](https://www.npmjs.com/package/cobertura) (Node.js)

その他のカバレッジ解析フレームワークは、追加設定なしでこの形式をサポートしています。次に例を示します:

- [Istanbul](https://istanbul.js.org/docs/advanced/alternative-reporters/#cobertura) (JavaScript)
- [Coverage.py](https://coverage.readthedocs.io/en/coverage-5.0.4/cmd.html#xml-reporting) (Python)
- [PHPUnit](https://github.com/sebastianbergmann/phpunit-documentation-english/blob/master/src/textui.rst#command-line-options) (PHP)

設定後、マージリクエストがカバレッジレポートを収集するパイプラインをトリガーすると、カバレッジ情報が差分ビューに表示されます。これには、パイプライン内の任意のステージの任意のジョブからのレポートが含まれます。カバレッジは各行に次のように表示されます:

- `covered`（緑）：テストで少なくとも1回チェックされた行
- `no test coverage`（オレンジ）：読み込まれたものの、一度も実行されなかった行
- カバレッジ情報なし：インストルメント化されていないか、読み込まれていない行

カバレッジバーにカーソルを合わせると、テストでその行がチェックされた回数など、詳細情報が表示されます。

テストカバレッジレポートをアップロードしても、以下は有効になりません:

- マージリクエストウィジェットの[テストカバレッジ結果](_index.md#view-coverage-results)。
- [コードカバレッジ履歴](_index.md#view-coverage-history)。

これらは個別に設定する必要があります。

## 制限 {#limits}

Cobertura形式のXMLファイルには、100個の`<source>`ノードの制限が適用されます。Coberturaレポートが100個のノードを超えると、マージリクエストの差分ビューで不一致が発生したり、一致しなくなる可能性があります。

単一のCobertura XMLファイルは、10 MiBを超えることはできません。大規模なプロジェクトの場合は、Cobertura XMLをより小さなファイルに分割します。詳細については、[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/328772)を参照してください。多数のファイルを送信すると、カバレッジがマージリクエストに表示されるまでに数分かかることがあります。

この視覚化は、パイプラインが完了した後にのみ表示されます。パイプラインに[ブロック手動ジョブ](../../jobs/job_control.md#types-of-manual-jobs)がある場合、パイプラインは続行する前に手動ジョブを待機し、完了とはみなされません。ブロック手動ジョブが実行されなかった場合、視覚化を表示できません。

ジョブが複数のレポートを生成する場合は、[アーティファクトパス](../../jobs/job_artifacts.md#with-wildcards)でワイルドカードを使用します。

### クラスパスの自動修正 {#automatic-class-path-correction}

カバレッジレポートが変更されたファイルを適切に照合するのは、`filename``class`要素にプロジェクトルートからの相対パスを含む完全なパスが含まれている場合に限ります。ただし、一部のカバレッジ解析フレームワークでは、生成されたCobertura XMLの`filename`パスには、代わりにクラスパッケージディレクトリからの相対パスが含まれています。

プロジェクトルートからの相対パスである`class`パスをインテリジェントに推測するために、Cobertura XMLパーサーは次の方法で完全なパスをビルドしようとします:

- `sources`要素から`source`パスの一部を抽出し、クラス`filename`パスと組み合わせます。
- 候補パスがプロジェクトに存在するかどうかをチェックします。
- 一致する最初の候補をクラスの完全パスとして使用します。

#### パス修正の例 {#path-correction-example}

例として、次のC#プロジェクトを考えます:

- 完全パスが`test-org/test-cs-project`。
- プロジェクトルートからの相対パスである次のファイル:

  ```shell
  Auth/User.cs
  Lib/Utils/User.cs
  ```

- Cobertura XMLからの`sources`。次の形式のパス`<CI_BUILDS_DIR>/<PROJECT_FULL_PATH>/...`:

  ```xml
  <sources>
    <source>/builds/test-org/test-cs-project/Auth</source>
    <source>/builds/test-org/test-cs-project/Lib/Utils</source>
  </sources>
  ```

パーサー:

- `Auth`と`Lib/Utils`を`sources`から抽出し、これらを使用してプロジェクトルートからの相対パスである`class`パスを決定します。
- これらの抽出された`sources`とクラスのファイル名を組み合わせます。たとえば、`filename`の値が`User.cs`の`class`要素がある場合、パーサーは一致する最初の候補パス（`Auth/User.cs`）を取得します。
- 各`class`要素について、抽出された`source`パスごとに最大100回の反復で一致するものを探そうとします。ファイルツリーに一致するパスが見つからないままこの制限に達すると、クラスは最終的なカバレッジレポートに含まれません。

クラスパスの自動修正は、次のJavaプロジェクトでも機能します:

- 完全パスが`test-org/test-java-project`。
- プロジェクトルートからの相対パスである次のファイル:

  ```shell
  src/main/java/com/gitlab/security_products/tests/App.java
  ```

- Cobertura XMLからの`sources`:

  ```xml
  <sources>
    <source>/builds/test-org/test-java-project/src/main/java/</source>
  </sources>
  ```

- `class`要素（`filename`の値が`com/gitlab/security_products/tests/App.java`）:

  ```xml
  <class name="com.gitlab.security_products.tests.App" filename="com/gitlab/security_products/tests/App.java" line-rate="0.0" branch-rate="0.0" complexity="6.0">
  ```

> [!note]
> クラスパスの自動修正は、`source`形式の`<CI_BUILDS_DIR>/<PROJECT_FULL_PATH>/...`パスでのみ機能します。パスがこのパターンに従わない場合、`source`は無視されます。パーサーは、`filename`要素の`class`にプロジェクトルートからの相対パスである完全なパスが含まれていると想定します。

## テストカバレッジ設定の例 {#example-test-coverage-configurations}

このセクションでは、さまざまなプログラミング言語のテストカバレッジ設定の例を示します。[`coverage-report`](https://gitlab.com/gitlab-org/ci-sample-projects/coverage-report/)デモンストレーションプロジェクトで動作例を確認することもできます。

### JavaScriptの例 {#javascript-example}

次の`.gitlab-ci.yml`の例では、[Mocha](https://mochajs.org/) JavaScriptテストと[nyc](https://github.com/istanbuljs/nyc)カバレッジツールを使用して、カバレッジアーティファクトを生成します:

```yaml
test:
  script:
    - npm install
    - npx nyc --reporter cobertura mocha
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
```

### JavaとKotlinの例 {#java-and-kotlin-examples}

GitLab 17.6以降は、JaCoCo形式をネイティブでサポートしています。新しいプロジェクトの場合は、[ネイティブJaCoCoレポート](jacoco.md)を使用してください。

次の例では、[jacoco2cobertura](https://gitlab.com/haynes/jacoco2cobertura) Dockerイメージを使用して、JaCoCoレポートをCobertura形式に変換します。

#### Mavenの例 {#maven-example}

`test-jdk11`ジョブは、[Maven](https://maven.apache.org/)を使用してJaCoCo XMLアーティファクトを生成します。`coverage-jdk11`ジョブは、それをCobertura形式に変換します:

```yaml
test-jdk11:
  stage: test
  image: maven:3.6.3-jdk-11
  script:
    - mvn $MAVEN_CLI_OPTS clean org.jacoco:jacoco-maven-plugin:prepare-agent test jacoco:report
  artifacts:
    paths:
      - target/site/jacoco/jacoco.xml

coverage-jdk11:
  # The `visualize` stage does not exist by default
  # Define it first, or use an existing stage like `deploy`
  stage: visualize
  image: registry.gitlab.com/haynes/jacoco2cobertura:1.0.11
  script:
    # Convert report from JaCoCo to Cobertura, using relative project path
    - python /opt/cover2cover.py target/site/jacoco/jacoco.xml $CI_PROJECT_DIR/src/main/java/
        > target/site/cobertura.xml
  needs: ["test-jdk11"]
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: target/site/cobertura.xml
```

#### Gradleの例 {#gradle-example}

`test-jdk11`ジョブは、[Gradle](https://gradle.org/)を使用してJaCoCo XMLアーティファクトを生成します。`coverage-jdk11`ジョブは、それをCobertura形式に変換します:

```yaml
test-jdk11:
  stage: test
  image: gradle:6.6.1-jdk11
  script:
    - gradle test jacocoTestReport # JaCoCo must be configured to create an XML report
  artifacts:
    paths:
      - build/jacoco/jacoco.xml

coverage-jdk11:
  # The `visualize` stage does not exist by default
  # Define it first, or use an existing stage like `deploy`
  stage: visualize
  image: registry.gitlab.com/haynes/jacoco2cobertura:1.0.11
  script:
    # Convert report from JaCoCo to Cobertura, using relative project path
    - python /opt/cover2cover.py build/jacoco/jacoco.xml $CI_PROJECT_DIR/src/main/java/
        > build/cobertura.xml
  needs: ["test-jdk11"]
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: build/cobertura.xml
```

### Pythonの例 {#python-example}

次の`.gitlab-ci.yml`の例では、[pytest-cov](https://pytest-cov.readthedocs.io/)を使用してテストカバレッジデータを収集します:

```yaml
run tests:
  stage: test
  image: python:3
  script:
    - pip install pytest pytest-cov
    - pytest --cov --cov-report term --cov-report xml:coverage.xml
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
```

### PHPの例 {#php-example}

PHPの次の`.gitlab-ci.yml`例では、[PHPUnit](https://phpunit.readthedocs.io/)を使用してテストカバレッジデータを収集し、レポートを生成します。

最小限の[`phpunit.xml`](https://docs.phpunit.de/en/11.0/configuration.html)ファイルを使用すると（[このレポートの例](https://gitlab.com/yookoala/code-coverage-visualization-with-php/)を参照）、テストを実行して`coverage.xml`を生成できます:

```yaml
run tests:
  stage: test
  image: php:latest
  variables:
    XDEBUG_MODE: coverage
  before_script:
    - apt-get update && apt-get -yq install git unzip zip libzip-dev zlib1g-dev
    - docker-php-ext-install zip
    - pecl install xdebug && docker-php-ext-enable xdebug
    - php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    - php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    - composer install
    - composer require --dev phpunit/phpunit phpunit/php-code-coverage
  script:
    - php ./vendor/bin/phpunit --coverage-text --coverage-cobertura=coverage.cobertura.xml
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.cobertura.xml
```

[Codeception](https://codeception.com/)は、PHPUnitを介して、[`run`](https://codeception.com/docs/reference/Commands#run)でCoberturaレポートの生成もサポートしています。生成されるファイルのパスは、`--coverage-cobertura`オプションと、[`paths`](https://codeception.com/docs/reference/Configuration#paths)の設定（[単体テストスイート](https://codeception.com/docs/05-UnitTests)）によって異なります。`.gitlab-ci.yml`を設定して、適切なパスでCoberturaを見つけます。

### C/C++の例 {#cc-example}

コンパイラとして`gcc`または`g++`を使用したC/C++の次の`.gitlab-ci.yml`例では、[`gcovr`](https://gcovr.com/en/stable/)を使用して、Cobertura XML形式でカバレッジ出力ファイルを生成します。

この例では、以下を前提としています。

- `Makefile`が、前のステージの別のジョブで、`build`ディレクトリ内の`cmake`によって作成されていること。(`automake`を使用して`Makefile`を生成する場合は、`make test`の代わりに`make check`を呼び出す必要があります。)
- `cmake`（または`automake`）がコンパイラオプション`--coverage`を設定していること。

```yaml
run tests:
  stage: test
  script:
    - cd build
    - make test
    - gcovr --xml-pretty --exclude-unreachable-branches --print-summary -o coverage.xml --root ${CI_PROJECT_DIR}
  artifacts:
    name: ${CI_JOB_NAME}-${CI_COMMIT_REF_NAME}-${CI_COMMIT_SHA}
    expire_in: 2 days
    reports:
      coverage_report:
        coverage_format: cobertura
        path: build/coverage.xml
```

### Goの例 {#go-example}

Goの次の`.gitlab-ci.yml`例では、次のものを使用します:

- テストを実行するための[`go test`](https://go.dev/doc/tutorial/add-a-test)。
- GoのカバレッジプロファイルをCobertura XML形式に変換するための[`gocover-cobertura`](https://github.com/boumenot/gocover-cobertura)。

この例では、[Goモジュール](https://go.dev/ref/mod)が使用されていることを前提としています。`-covermode count`オプションは、`-race`フラグでは機能しません。`-race`フラグを使用しながらコードカバレッジを生成する場合は、`-covermode atomic`に切り替える必要があります。これは`-covermode count`よりも低速です。詳細については、[このブログ投稿](https://go.dev/blog/cover)を参照してください。

```yaml
run tests:
  stage: test
  image: golang:1.17
  script:
    - go install
    - go test ./... -coverprofile=coverage.txt -covermode count
    - go get github.com/boumenot/gocover-cobertura
    - go run github.com/boumenot/gocover-cobertura < coverage.txt > coverage.xml
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
```

### Rubyの例 {#ruby-example}

Rubyの次の`.gitlab-ci.yml`例では、以下を使用します。

- テストを実行するための[`rspec`](https://rspec.info/)。
- カバレッジプロファイルを記録し、Cobertura XML形式でレポートを作成するための[`simplecov`](https://github.com/simplecov-ruby/simplecov)と[`simplecov-cobertura`](https://github.com/dashingrocket/simplecov-cobertura)。

この例では、以下を前提としています。

- [`bundler`](https://bundler.io/)が、依存関係管理に使用されていること。`rspec`、`simplecov`、および`simplecov-cobertura` gemが`Gemfile`に追加されていること。
- `CoberturaFormatter`が、`spec_helper.rb`ファイルの`SimpleCov.formatters`設定に追加されていること。

```yaml
run tests:
  stage: test
  image: ruby:3.1
  script:
    - bundle install
    - bundle exec rspec
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/coverage.xml
```

## トラブルシューティング {#troubleshooting}

### テストカバレッジの視覚化が表示されない {#test-coverage-visualization-not-displayed}

テストカバレッジの視覚化が差分ビューに表示されない場合は、カバレッジレポート自体をチェックして、以下を確認できます:

- 差分ビューで表示しているファイルが、カバレッジレポートに記載されていること。
- レポート内の`source`ノードと`filename`ノードが、[予想される構造](#automatic-class-path-correction)に従って、リポジトリ内のファイルと一致すること。
- パイプラインが完了していること。パイプラインが[手動ジョブでブロック](../../jobs/job_control.md#types-of-manual-jobs)されている場合、パイプラインは完了とはみなされません。
- カバレッジレポートファイルが[制限](#limits)を超えていないこと。

レポートアーティファクトは、デフォルトではダウンロードできません。ジョブの詳細ページからレポートをダウンロードできるようにする場合は、アーティファクトの`paths`にカバレッジレポートを追加します:

```yaml
artifacts:
  paths:
    - coverage/cobertura-coverage.xml
  reports:
    coverage_report:
      coverage_format: cobertura
      path: coverage/cobertura-coverage.xml
```
