---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Ruby、Go、Java、Python、JavaScript、その他の言語用のJUnit XML設定例。
title: 単体テストレポートの例
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

これらの例を、さまざまな言語やテストフレームワークで単体テストレポートを設定するためのガイドラインとして使用してください。単体テストレポートには、テストフレームワークがJUnit XML形式の出力を生成し、CI/CDジョブが結果をアーティファクトとしてアップロードする必要があります。

次の例は、`.gitlab-ci.yml`ファイルに追加する個々のジョブ設定を示しています。すべての例で以下を使用しています:

- テストが失敗した場合でもレポートをアップロードするための`artifacts:when: always`。
- JUnit XMLファイルの場所を指定するための`artifacts:reports:junit`。
- 必要な場合の`before_script`でのパッケージのインストール。

各例は、プロジェクトに合わせてコピーおよび変更できる機能的なジョブです。必要に応じて以下を行います:

- 環境に合わせて`image:`仕様を追加または変更します。
- 依存関係に合わせてパッケージのインストールコマンドを変更します。
- プロジェクトの構造に合わせてファイルのパスを変更します。
- テスト設定に合わせてテストコマンドを更新します。

セットアップ手順とトラブルシューティングについては、[単体テストレポート](unit_test_reports.md)を参照してください。

## ツール別のJUnit出力設定 {#junit-output-configuration-by-tool}

| 言語     | ツール                    | JUnit出力フラグ |
| ------------ | ----------------------- | ----------------- |
| .NET         | `JunitXML.TestLogger`   | `--logger:"junit;LogFilePath=report.xml"` |
| C/C++        | GoogleTest              | `--gtest_output="xml:report.xml"` |
| C/C++        | CUnit                   | `CUnitCI.h`マクロで自動。 |
| Flutter/Dart | `junitreport`           | `\| tojunit -o report.xml` |
| Go           | `gotestsum`             | `--junitfile report.xml` |
| Helm         | `helm-unittest`         | `-t JUnit -o report.xml` |
| Java         | Gradle                  | `build/test-results/test/`で自動。 |
| Java         | Maven                   | `target/surefire-reports/`および`target/failsafe-reports/`で自動。 |
| JavaScript   | `jest-junit`            | `--reporters=jest-junit` |
| JavaScript   | `karma-junit-reporter`  | `--reporters junit` |
| JavaScript   | `mocha-gitlab-reporter` | `--reporter mocha-gitlab-reporter` |
| PHP          | PHPUnit                 | `--log-junit report.xml` |
| Python       | `pytest`                | `--junitxml=report.xml` |
| Ruby         | `rspec_junit_formatter` | `--format RspecJunitFormatter --out report.xml` |
| Rust         | `cargo2junit`           | `\| cargo2junit > report.xml` |

## .NET {#net}

NuGetパッケージ[`JunitXML.TestLogger`](https://www.nuget.org/packages/JunitXml.TestLogger/)を使用して、.NETでJUnit XMLレポートを生成します:

```yaml
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

この例では、リポジトリのルートフォルダーにソリューションがあり、サブフォルダーに1つ以上のプロジェクトファイルがあることを想定しています。テストプロジェクトごとに1つの結果ファイルが生成され、各ファイルはアーティファクトフォルダーに配置されます。引数をフォーマットすることで、テストウィジェット内のテストデータの可読性が向上します。

## C/C++ {#cc}

### GoogleTest {#googletest}

組み込みのXML出力を使用して、[GoogleTest](https://github.com/google/googletest)でJUnit XMLレポートを生成します:

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

複数の`gtest`実行可能ファイルが異なるアーキテクチャ (`x86`、`x64`、または`arm`) 用に作成されている場合は、各テストが一意のファイル名を持つようにしてください。結果はその後、集約されます。

### CUnit {#cunit}

[`CUnitCI.h`マクロ](https://cunity.gitlab.io/cunit/group__CI.html)を使用してCUnitでJUnit XMLレポートを生成します:

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

## FlutterまたはDart {#flutter-or-dart}

FlutterまたはDartで[`junitreport`](https://pub.dev/packages/junitreport)パッケージを使用してJUnit XMLレポートを生成します:

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

この例では、`junitreport`パッケージを使用して、`flutter test`出力をJUnitレポートXML形式に変換します。

## Go {#go}

Goで[`gotestsum`](https://github.com/gotestyourself/gotestsum)を使用してJUnit XMLレポートを生成します:

```yaml
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

## Helm {#helm}

Helmで[`Helm Unittest`](https://github.com/helm-unittest/helm-unittest#docker-usage)プラグインを使用してJUnit XMLレポートを生成します:

```yaml
helm:
  image: helmunittest/helm-unittest:latest
  stage: test
  script:
    - '-t JUnit -o report.xml -f tests/*[._]test.yaml .'
  artifacts:
    when: always
    reports:
      junit: report.xml
```

`-f tests/*[._]test.yaml`フラグは、`helm-unittest`が`tests/`ディレクトリで`.test.yaml`または`_test.yaml`のいずれかで終わるファイルを探すように設定します。

## Java {#java}

### Gradle {#gradle}

組み込みのテスト報告を使用して、[Gradle](https://gradle.org/)でJUnit XMLレポートを生成します:

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

複数のテストタスクが定義されている場合、`gradle`は`build/test-results/`の下に複数のディレクトリを生成します。その場合、次のパスを定義することで、グロブマッチングを活用できます: `build/test-results/test/**/TEST-*.xml`。

### Maven {#maven}

[Surefire](https://maven.apache.org/surefire/maven-surefire-plugin/)および[Failsafe](https://maven.apache.org/surefire/maven-failsafe-plugin/)テストレポートを使用してMavenでJUnit XMLレポートを生成します:

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

## JavaScript {#javascript}

### Jest {#jest}

[`jest-junit`](https://github.com/jest-community/jest-junit) NPMパッケージを使用してJestでJUnit XMLレポートを生成します:

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

[`karma-junit-reporter`](https://github.com/karma-runner/karma-junit-reporter) NPMパッケージを使用してKarmaでJUnit XMLレポートを生成します:

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

Mochaの設定例については、[`mocha-gitlab-reporter`](https://github.com/X-Guardian/mocha-gitlab-reporter?tab=readme-ov-file#gitlab-ci-configuration)を参照してください。

## PHP {#php}

PHPで[`PHPUnit`](https://phpunit.de/index.html)を使用してJUnit XMLレポートを生成します:

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

`phpunit.xml`設定ファイルで[XML](https://docs.phpunit.de/en/11.0/configuration.html#the-junit-element)を使用してこのオプションを設定することもできます。

## Python {#python}

Pythonで[`pytest`](https://pytest.org/)を使用してJUnit XMLレポートを生成します:

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

## Ruby {#ruby}

[`rspec_junit_formatter`](https://github.com/sj26/rspec_junit_formatter) gemを使用してRSpecでJUnit XMLレポートを生成します:

```yaml
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

## Rust {#rust}

Rustで[`cargo2junit`](https://crates.io/crates/cargo2junit)を使用してJUnit XMLレポートを生成します:

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

`cargo test`からJSON出力を取得するには、nightlyコンパイラを有効にする必要があります。このツールは現在のディレクトリにインストールされます。
