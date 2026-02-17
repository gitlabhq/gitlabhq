---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: JUnit XML configuration examples for Ruby, Go, Java, Python, JavaScript, and other languages.
title: Unit test report examples
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use these examples as guidelines for configuring unit test reports in different languages and testing frameworks.
Unit test reports require your test framework to generate JUnit XML format output and your CI/CD job to upload the results as artifacts.

The following examples show individual job configurations to add to your `.gitlab-ci.yml` file.
All examples use:

- `artifacts:when: always` to upload reports even when tests fail.
- `artifacts:reports:junit` to specify the JUnit XML file location.
- Package installation in `before_script` when required.

Each example is a functional job that you can copy and adapt for your project.
You might need to:

- Add or modify the `image:` specification for your environment.
- Modify package installation commands for your dependencies.
- Change file paths to match your project structure.
- Update test commands to match your testing setup.

For setup instructions and troubleshooting, see [unit test reports](unit_test_reports.md).

## JUnit output configuration by tool

| Language     | Tool                    | JUnit output flag |
| ------------ | ----------------------- | ----------------- |
| .NET         | `JunitXML.TestLogger`   | `--logger:"junit;LogFilePath=report.xml"` |
| C/C++        | GoogleTest              | `--gtest_output="xml:report.xml"` |
| C/C++        | CUnit                   | Automatic with `CUnitCI.h` macros |
| Flutter/Dart | `junitreport`           | `\| tojunit -o report.xml` |
| Go           | `gotestsum`             | `--junitfile report.xml` |
| Helm         | `helm-unittest`         | `-t JUnit -o report.xml` |
| Java         | Gradle                  | Automatic in `build/test-results/test/` |
| Java         | Maven                   | Automatic in `target/surefire-reports/` and `target/failsafe-reports/` |
| JavaScript   | `jest-junit`            | `--reporters=jest-junit` |
| JavaScript   | `karma-junit-reporter`  | `--reporters junit` |
| JavaScript   | `mocha-gitlab-reporter` | `--reporter mocha-gitlab-reporter` |
| PHP          | PHPUnit                 | `--log-junit report.xml` |
| Python       | `pytest`                | `--junitxml=report.xml` |
| Ruby         | `rspec_junit_formatter` | `--format RspecJunitFormatter --out report.xml` |
| Rust         | `cargo2junit`           | `\| cargo2junit > report.xml` |

## .NET

Generate JUnit XML reports with .NET using the [`JunitXML.TestLogger`](https://www.nuget.org/packages/JunitXml.TestLogger/) NuGet package:

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

This example expects a solution in the root folder of the repository, with one or more project files in sub-folders.
One result file is produced per test project, and each file is placed in the artifacts folder.
The formatting arguments improve the readability of test data in the test widget.

## C/C++

### GoogleTest

Generate JUnit XML reports with [GoogleTest](https://github.com/google/googletest) using built-in XML output:

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

If there are multiple `gtest` executables created for different architectures (`x86`, `x64` or `arm`),
make sure each test has a unique filename. The results are then aggregated together.

### CUnit

Generate JUnit XML reports with CUnit
using [`CUnitCI.h` macros](https://cunity.gitlab.io/cunit/group__CI.html):

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

## Flutter or Dart

Generate JUnit XML reports with Flutter or Dart using the [`junitreport`](https://pub.dev/packages/junitreport) package:

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

This example uses the `junitreport` package to convert `flutter test` output into JUnit report XML format.

## Go

Generate JUnit XML reports with Go using [`gotestsum`](https://github.com/gotestyourself/gotestsum):

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

## Helm

Generate JUnit XML reports with Helm using the [`Helm Unittest`](https://github.com/helm-unittest/helm-unittest#docker-usage) plugin:

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

The `-f tests/*[._]test.yaml` flag configures `helm-unittest` to look for files in the `tests/` directory that end in either `.test.yaml` or `_test.yaml`.

## Java

### Gradle

Generate JUnit XML reports with [Gradle](https://gradle.org/) using built-in test reporting:

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

If there are multiple test tasks defined, `gradle` generates multiple directories under `build/test-results/`.
In that case, you can leverage glob matching by defining the following path: `build/test-results/test/**/TEST-*.xml`.

### Maven

Generate JUnit XML reports with Maven using [Surefire](https://maven.apache.org/surefire/maven-surefire-plugin/)
and [Failsafe](https://maven.apache.org/surefire/maven-failsafe-plugin/) test reports:

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

## JavaScript

### Jest

Generate JUnit XML reports with Jest using the [`jest-junit`](https://github.com/jest-community/jest-junit) npm package:

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

To make the job pass when there are no `.test.js` files with unit tests,
add the `--passWithNoTests` flag to the end of the `jest` command in the `script:` section.

### Karma

Generate JUnit XML reports with Karma using the [`karma-junit-reporter`](https://github.com/karma-runner/karma-junit-reporter) npm package:

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

### Mocha

For a Mocha configuration example, see [`mocha-gitlab-reporter`](https://github.com/X-Guardian/mocha-gitlab-reporter?tab=readme-ov-file#gitlab-ci-configuration).

## PHP

Generate JUnit XML reports with PHP using [`PHPUnit`](https://phpunit.de/index.html):

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

You can also configure this option using [XML](https://docs.phpunit.de/en/11.0/configuration.html#the-junit-element) in the `phpunit.xml` configuration file.

## Python

Generate JUnit XML reports with Python using [`pytest`](https://pytest.org/):

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

## Ruby

Generate JUnit XML reports with RSpec using the [`rspec_junit_formatter`](https://github.com/sj26/rspec_junit_formatter) gem:

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

## Rust

Generate JUnit XML reports with Rust using [`cargo2junit`](https://crates.io/crates/cargo2junit):

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

To retrieve JSON output from `cargo test`, you must enable the nightly compiler.
The tool is installed in the current directory.
