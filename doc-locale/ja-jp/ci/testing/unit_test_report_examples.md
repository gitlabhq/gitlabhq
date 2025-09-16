---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 単体テストレポートの例
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[単体テストレポート](unit_test_reports.md)は、多くの言語とパッケージに対して生成できます。これらの例をガイドラインとして、リストされた言語とパッケージの単体テストレポートを生成するようにパイプラインを設定します。使用している言語またはパッケージのバージョンに合わせて、例を編集する必要がある場合があります。

## Ruby {#ruby}

`.gitlab-ci.yml`で次のジョブを使用します。これには、単体テストレポートの出力ファイルへのリンクを提供する`artifacts:paths`キーワードが含まれています。

```yaml
## Use https://github.com/sj26/rspec_junit_formatter to generate a JUnit report format XML file with rspec
ruby:
  image: ruby:3.0.4
  stage: test
  before_script:
    - apt-get update -y && apt-get install -y bundler
  script:
    - bundle install
    - bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml
  artifacts:
    when: always
    paths:
      - rspec.xml
    reports:
      junit: rspec.xml
```

## Go {#go}

`.gitlab-ci.yml`で次のジョブを使用します。

```yaml
## Use https://github.com/gotestyourself/gotestsum to generate a JUnit report format XML file with go
golang:
  stage: test
  script:
    - go install gotest.tools/gotestsum@latest
    - gotestsum --junitfile report.xml --format testname
  artifacts:
    when: always
    reports:
      junit: report.xml
```

## Java {#java}

Javaには、JUnitレポート形式のXMLファイルを生成できるツールがいくつかあります。

### Gradle {#gradle}

次の例では、`gradle`を使用してテストレポートを生成します。複数のテストタスクが定義されている場合、`gradle`は`build/test-results/`の下に複数のディレクトリを生成します。その場合は、次のパスを定義して、globマッチングを利用できます: `build/test-results/test/**/TEST-*.xml`。

```yaml
java:
  stage: test
  script:
    - gradle test
  artifacts:
    when: always
    reports:
      junit: build/test-results/test/**/TEST-*.xml
```

### Maven {#maven}

[Surefire](https://maven.apache.org/surefire/maven-surefire-plugin/)および[Failsafe](https://maven.apache.org/surefire/maven-failsafe-plugin/)テストレポートを解析するには、`.gitlab-ci.yml`で次のジョブを使用します。

```yaml
java:
  stage: test
  script:
    - mvn verify
  artifacts:
    when: always
    reports:
      junit:
        - target/surefire-reports/TEST-*.xml
        - target/failsafe-reports/TEST-*.xml
```

## Pythonの例 {#python-example}

この例では、`--junitxml=report.xml`フラグを指定したpytestを使用して、出力をJUnitレポートのXML形式に整形します。

```yaml
pytest:
  stage: test
  script:
    - pytest --junitxml=report.xml
  artifacts:
    when: always
    reports:
      junit: report.xml
```

## C/C++ {#cc}

C/C++には、JUnitレポート形式のXMLファイルを生成できるツールがいくつかあります。

### GoogleTest {#googletest}

次の例では、`gtest`を使用してテストレポートを生成します。異なるアーキテクチャ（`x86`、`x64`、または`arm`）用に複数の`gtest`実行可能ファイルが作成されている場合は、一意のファイル名を指定して各テストを実行する必要があります。結果はその後、集約されます。

```yaml
cpp:
  stage: test
  script:
    - gtest.exe --gtest_output="xml:report.xml"
  artifacts:
    when: always
    reports:
      junit: report.xml
```

### CUnit {#cunit}

[CUnit](https://cunity.gitlab.io/cunit/)は、次のように`CUnitCI.h`マクロを使用して実行すると、[JUnitレポート形式のXMLファイル](https://cunity.gitlab.io/cunit/group__CI.html)を自動的に生成するように設定できます。

```yaml
cunit:
  stage: test
  script:
    - ./my-cunit-test
  artifacts:
    when: always
    reports:
      junit: ./my-cunit-test.xml
```

## .NET {#net}

[JunitXML.TestLogger](https://www.nuget.org/packages/JunitXml.TestLogger/) NuGetパッケージは、.Net Frameworkおよび.Net Coreアプリケーション用のテストレポートを生成できます。次の例では、リポジトリのルートフォルダーにソリューションがあり、サブフォルダーに1つ以上のプロジェクトファイルがあることを想定しています。テストプロジェクトごとに1つの結果ファイルが生成され、各ファイルはアーティファクトフォルダーに配置されます。この例には、テストウィジェットでのテストデータの可読性を向上させるオプションの書式設定引数が含まれています。完全な.Net Coreの例については、[こちら](https://gitlab.com/Siphonophora/dot-net-cicd-test-logging-demo)をご覧ください。

```yaml
## Source code and documentation are here: https://github.com/spekt/junit.testlogger/

Test:
  stage: test
  script:
    - 'dotnet test --test-adapter-path:. --logger:"junit;LogFilePath=..\artifacts\{assembly}-test-result.xml;MethodFormat=Class;FailureBodyFormat=Verbose"'
  artifacts:
    when: always
    paths:
      - ./**/*test-result.xml
    reports:
      junit:
        - ./**/*test-result.xml
```

## JavaScript {#javascript}

JavaScriptには、JUnitレポート形式のXMLファイルを生成できるツールがいくつかあります。

### Jest {#jest}

[jest-junit](https://github.com/jest-community/jest-junit) npmパッケージは、JavaScriptアプリケーションのテストレポートを生成できます。次の`.gitlab-ci.yml`の例では、`javascript`ジョブはJestを使用してテストレポートを生成しています。

```yaml
javascript:
  image: node:latest
  stage: test
  before_script:
    - 'yarn global add jest'
    - 'yarn add --dev jest-junit'
  script:
    - 'jest --ci --reporters=default --reporters=jest-junit'
  artifacts:
    when: always
    reports:
      junit:
        - junit.xml
```

単体テストを含む`.test.js`ファイルがない場合でもジョブを成功させるには、`script:`セクションの`jest`コマンドの最後に`--passWithNoTests`フラグを追加します。

### Karma {#karma}

[Karma-junit-reporter](https://github.com/karma-runner/karma-junit-reporter) npmパッケージは、JavaScriptアプリケーションのテストレポートを生成できます。次の`.gitlab-ci.yml`の例では、`javascript`ジョブはKarmaを使用してテストレポートを生成しています。

```yaml
javascript:
  stage: test
  script:
    - karma start --reporters junit
  artifacts:
    when: always
    reports:
      junit:
        - junit.xml
```

### Mocha {#mocha}

[Mocha用JUnit Reporter](https://github.com/michaelleeallen/mocha-junit-reporter) npmパッケージは、JavaScriptアプリケーションのテストレポートを生成できます。次の`.gitlab-ci.yml`の例では、`javascript`ジョブはMochaを使用してテストレポートを生成しています。

```yaml
javascript:
  stage: test
  script:
    - mocha --reporter mocha-junit-reporter --reporter-options mochaFile=junit.xml
  artifacts:
    when: always
    reports:
      junit:
        - junit.xml
```

## FlutterまたはDart {#flutter-or-dart}

この例の`.gitlab-ci.yml`ファイルは、[JUnit Report](https://pub.dev/packages/junitreport)パッケージを使用して、`flutter test`出力をJUnitレポートのXML形式に変換します。

```yaml
test:
  stage: test
  script:
    - flutter test --machine | tojunit -o report.xml
  artifacts:
    when: always
    reports:
      junit:
        - report.xml
```

## PHP {#php}

この例では、`--log-junit`フラグを指定した[PHPUnit](https://phpunit.de/index.html)を使用します。`phpunit.xml`設定ファイルで[XML](https://docs.phpunit.de/en/11.0/configuration.html#the-junit-element)を使用して、このオプションを追加することもできます。

```yaml
phpunit:
  stage: test
  script:
    - composer install
    - vendor/bin/phpunit --log-junit report.xml
  artifacts:
    when: always
    reports:
      junit: report.xml
```

## Rust {#rust}

この例では、現在のディレクトリにインストールされている[cargo2junit](https://crates.io/crates/cargo2junit)を使用します。`cargo test`からJSON出力を取得するには、nightlyコンパイラを有効にする必要があります。

```yaml
run unittests:
  image: rust:latest
  stage: test
  before_script:
    - cargo install --root . cargo2junit
  script:
    - cargo test -- -Z unstable-options --format json --report-time | bin/cargo2junit > report.xml
  artifacts:
    when: always
    reports:
      junit:
        - report.xml
```

## Helm {#helm}

この例では、[Helm Unittest](https://github.com/helm-unittest/helm-unittest#docker-usage)プラグインを使用し、`-t junit`フラグを指定して、出力をJUnitレポートのXML形式に整形します。

```yaml
helm:
  image: helmunittest/helm-unittest:latest
  stage: test
  script:
    - '-t JUnit -o report.xml -f tests/*[._]test.yaml .'
  artifacts:
    reports:
      junit: report.xml
```

`-f tests/*[._]test.yaml`フラグは、`tests/`ディレクトリ内の次のいずれかで終わるファイルを検索するように`helm-unittest`を設定します。

- `.test.yaml`
- `_test.yaml`
