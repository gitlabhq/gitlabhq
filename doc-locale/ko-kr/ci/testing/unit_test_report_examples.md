---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Ruby, Go, Java, Python, JavaScript 등 다양한 언어를 위한 JUnit XML 구성 예제입니다."
title: 단위 테스트 보고서 예제
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이러한 예제를 다양한 언어와 테스트 프레임워크에서 단위 테스트 보고서를 구성하기 위한 지침으로 사용합니다. 단위 테스트 보고서는 테스트 프레임워크가 JUnit XML 형식 출력을 생성하고 CI/CD 작업이 결과를 아티팩트로 업로드할 수 있어야 합니다.

`.gitlab-ci.yml` 파일에 추가할 개별 작업 구성을 다음 예제에서 보여줍니다. 모든 예제는 다음을 사용합니다:

- `artifacts:when: always`: 테스트가 실패한 경우에도 보고서를 업로드합니다.
- `artifacts:reports:junit`: JUnit XML 파일 위치를 지정합니다.
- `before_script` 패키지 설치(필요한 경우)

각 예제는 프로젝트에 복사하고 조정할 수 있는 기능성 작업입니다. 다음을 수행해야 할 수도 있습니다:

- `image:` 사양을 환경에 맞게 추가하거나 수정합니다.
- 종속성에 대한 패키지 설치 명령을 수정합니다.
- 프로젝트 구조와 일치하도록 파일 경로를 변경합니다.
- 테스트 설정과 일치하도록 테스트 명령을 업데이트합니다.

설정 지침 및 문제 해결은 [단위 테스트 보고서](unit_test_reports.md)를 참조합니다.

## 도구별 JUnit 출력 구성 {#junit-output-configuration-by-tool}

| 언어     | 도구                    | JUnit 출력 플래그 |
| ------------ | ----------------------- | ----------------- |
| .NET         | `JunitXML.TestLogger`   | `--logger:"junit;LogFilePath=report.xml"` |
| C/C++        | GoogleTest              | `--gtest_output="xml:report.xml"` |
| C/C++        | CUnit                   | `CUnitCI.h` 매크로를 사용하여 자동 생성됩니다 |
| Flutter/Dart | `junitreport`           | `\| tojunit -o report.xml` |
| Go           | `gotestsum`             | `--junitfile report.xml` |
| Helm         | `helm-unittest`         | `-t JUnit -o report.xml` |
| Java         | Gradle                  | `build/test-results/test/`에서 자동 생성됩니다 |
| Java         | Maven                   | `target/surefire-reports/` 및 `target/failsafe-reports/`에서 자동 생성됩니다 |
| JavaScript   | `jest-junit`            | `--reporters=jest-junit` |
| JavaScript   | `karma-junit-reporter`  | `--reporters junit` |
| JavaScript   | `mocha-gitlab-reporter` | `--reporter mocha-gitlab-reporter` |
| PHP          | PHPUnit                 | `--log-junit report.xml` |
| Python       | `pytest`                | `--junitxml=report.xml` |
| Ruby         | `rspec_junit_formatter` | `--format RspecJunitFormatter --out report.xml` |
| Rust         | `cargo2junit`           | `\| cargo2junit > report.xml` |

## .NET {#net}

[`JunitXML.TestLogger`](https://www.nuget.org/packages/JunitXml.TestLogger/) NuGet 패키지를 사용하여 .NET으로 JUnit XML 보고서를 생성합니다:

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

이 예제에서는 리포지토리 루트 폴더에 하나 이상의 프로젝트 파일이 있는 솔루션을 기대합니다. 테스트 프로젝트당 하나의 결과 파일이 생성되며 각 파일은 아티팩트 폴더에 배치됩니다. 서식 지정 인수는 테스트 위젯의 테스트 데이터 가독성을 향상시킵니다.

## C/C++ {#cc}

### GoogleTest {#googletest}

[GoogleTest](https://github.com/google/googletest)를 사용하여 JUnit XML 보고서를 생성합니다(기본 제공 XML 출력):

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

다양한 아키텍처(`x86`, `x64` 또는 `arm`)에 대해 생성된 `gtest` 실행 파일이 여러 개 있는 경우 각 테스트에 고유한 파일명이 있는지 확인합니다. 그런 다음 결과가 함께 집계됩니다.

### CUnit {#cunit}

[`CUnitCI.h` 매크로](https://cunity.gitlab.io/cunit/group__CI.html)를 사용하여 CUnit으로 JUnit XML 보고서를 생성합니다:

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

## Flutter 또는 Dart {#flutter-or-dart}

[`junitreport`](https://pub.dev/packages/junitreport) 패키지를 사용하여 Flutter 또는 Dart로 JUnit XML 보고서를 생성합니다:

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

이 예제에서는 `junitreport` 패키지를 사용하여 `flutter test` 출력을 JUnit 보고서 XML 형식으로 변환합니다.

## Go {#go}

[`gotestsum`](https://github.com/gotestyourself/gotestsum)를 사용하여 Go로 JUnit XML 보고서를 생성합니다:

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

[`Helm Unittest`](https://github.com/helm-unittest/helm-unittest#docker-usage) 플러그인을 사용하여 Helm으로 JUnit XML 보고서를 생성합니다:

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

`-f tests/*[._]test.yaml` 플래그는 `helm-unittest`를 구성하여 `tests/` 디렉터리에서 `.test.yaml` 또는 `_test.yaml`로 끝나는 파일을 찾습니다.

## Java {#java}

### Gradle {#gradle}

[Gradle](https://gradle.org/)를 사용하여 기본 제공 테스트 보고로 JUnit XML 보고서를 생성합니다:

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

정의된 테스트 작업이 여러 개인 경우 `gradle`는 `build/test-results/` 아래에 여러 디렉터리를 생성합니다. 이 경우 다음 경로를 정의하여 글로브 일치를 활용할 수 있습니다: `build/test-results/test/**/TEST-*.xml`

### Maven {#maven}

[Surefire](https://maven.apache.org/surefire/maven-surefire-plugin/) 및 [Failsafe](https://maven.apache.org/surefire/maven-failsafe-plugin/) 테스트 보고서를 사용하여 Maven으로 JUnit XML 보고서를 생성합니다:

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

[`jest-junit`](https://github.com/jest-community/jest-junit) npm 패키지를 사용하여 Jest로 JUnit XML 보고서를 생성합니다:

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

단위 테스트가 있는 `.test.js` 파일이 없을 때 작업을 통과하려면 `script:` 섹션의 `jest` 명령 끝에 `--passWithNoTests` 플래그를 추가합니다.

### Karma {#karma}

[`karma-junit-reporter`](https://github.com/karma-runner/karma-junit-reporter) npm 패키지를 사용하여 Karma로 JUnit XML 보고서를 생성합니다:

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

Mocha 구성 예제는 [`mocha-gitlab-reporter`](https://github.com/X-Guardian/mocha-gitlab-reporter?tab=readme-ov-file#gitlab-ci-configuration)를 참조합니다.

## PHP {#php}

[`PHPUnit`](https://phpunit.de/index.html)를 사용하여 PHP로 JUnit XML 보고서를 생성합니다:

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

[XML](https://docs.phpunit.de/en/11.0/configuration.html#the-junit-element)을 사용하여 `phpunit.xml` 구성 파일에서 이 옵션을 구성할 수도 있습니다.

## Python {#python}

[`pytest`](https://pytest.org/)를 사용하여 Python으로 JUnit XML 보고서를 생성합니다:

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

[`rspec_junit_formatter`](https://github.com/sj26/rspec_junit_formatter) gem을 사용하여 RSpec으로 JUnit XML 보고서를 생성합니다:

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

[`cargo2junit`](https://crates.io/crates/cargo2junit)를 사용하여 Rust로 JUnit XML 보고서를 생성합니다:

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

`cargo test`에서 JSON 출력을 검색하려면 nightly 컴파일러를 활성화해야 합니다. 도구는 현재 디렉터리에 설치됩니다.
