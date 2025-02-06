---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Unit test report examples
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

[Unit test reports](unit_test_reports.md) can be generated for many languages and packages.
Use these examples as guidelines for configuring your pipeline to generate unit test reports
for the listed languages and packages. You might need to edit the examples to match
the version of the language or package you are using.

## Ruby

Use the following job in `.gitlab-ci.yml`. This includes the `artifacts:paths` keyword to provide a link to the Unit test report output file.

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

## Go

Use the following job in `.gitlab-ci.yml`:

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

## Java

There are a few tools that can produce JUnit report format XML file in Java.

### Gradle

In the following example, `gradle` is used to generate the test reports.
If there are multiple test tasks defined, `gradle` generates multiple
directories under `build/test-results/`. In that case, you can leverage glob
matching by defining the following path: `build/test-results/test/**/TEST-*.xml`:

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

In [GitLab Runner 13.0](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2620)
and later, you can use `**`.

### Maven

For parsing [Surefire](https://maven.apache.org/surefire/maven-surefire-plugin/)
and [Failsafe](https://maven.apache.org/surefire/maven-failsafe-plugin/) test
reports, use the following job in `.gitlab-ci.yml`:

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

## Python example

This example uses pytest with the `--junitxml=report.xml` flag to format the output
into the JUnit report XML format:

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

## C/C++

There are a few tools that can produce JUnit report format XML files in C/C++.

### GoogleTest

In the following example, `gtest` is used to generate the test reports.
If there are multiple `gtest` executables created for different architectures (`x86`, `x64` or `arm`),
you are required to run each test providing a unique filename. The results
are then aggregated together.

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

### CUnit

[CUnit](https://cunity.gitlab.io/cunit/) can be made to produce [JUnit report format XML files](https://cunity.gitlab.io/cunit/group__CI.html)
automatically when run using its `CUnitCI.h` macros:

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

## .NET

The [JunitXML.TestLogger](https://www.nuget.org/packages/JunitXml.TestLogger/) NuGet
package can generate test reports for .Net Framework and .Net Core applications. The following
example expects a solution in the root folder of the repository, with one or more
project files in sub-folders. One result file is produced per test project, and each file
is placed in the artifacts folder. This example includes optional formatting arguments, which
improve the readability of test data in the test widget. A full .Net Core
[example is available](https://gitlab.com/Siphonophora/dot-net-cicd-test-logging-demo).

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

## JavaScript

There are a few tools that can produce JUnit report format XML files in JavaScript.

### Jest

The [jest-junit](https://github.com/jest-community/jest-junit) npm package can generate
test reports for JavaScript applications. In the following `.gitlab-ci.yml` example,
the `javascript` job uses Jest to generate the test reports:

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

To make the job pass when there are no `.test.js` files with unit tests, add the
`--passWithNoTests` flag to the end of the `jest` command in the `script:` section.

### Karma

The [Karma-junit-reporter](https://github.com/karma-runner/karma-junit-reporter)
npm package can generate test reports for JavaScript applications. In the following
`.gitlab-ci.yml` example, the `javascript` job uses Karma to generate the test reports:

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

The [JUnit Reporter for Mocha](https://github.com/michaelleeallen/mocha-junit-reporter)
NPM package can generate test reports for JavaScript applications. In the following
`.gitlab-ci.yml` example, the `javascript` job uses Mocha to generate the test reports:

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

## Flutter or Dart

This example `.gitlab-ci.yml` file uses the [JUnit Report](https://pub.dev/packages/junitreport)
package to convert the `flutter test` output into JUnit report XML format:

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

## PHP

This example uses [PHPUnit](https://phpunit.de/index.html) with the `--log-junit` flag.
You can also add this option using
[XML](https://docs.phpunit.de/en/11.0/configuration.html#the-junit-element)
in the `phpunit.xml` configuration file.

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

## Rust

This example uses [cargo2junit](https://crates.io/crates/cargo2junit),
which is installed in the current directory.
To retrieve JSON output from `cargo test`, you must enable the nightly compiler.

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

## Helm

This example uses [Helm Unittest](https://github.com/helm-unittest/helm-unittest#docker-usage) plugin, with the `-t junit` flag to format the output to a JUnit report in XML format.

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

The `-f tests/*[._]test.yaml` flag configures `helm-unittest` to look for files in the `tests/` directory that end in either:

- `.test.yaml`
- `_test.yaml`
