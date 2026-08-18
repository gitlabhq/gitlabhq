---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Cobertura XML 보고서를 사용하여 머지 리퀘스트 diffs에서 줄별 테스트 커버리지 주석을 표시합니다.
title: Cobertura 커버리지 시각화
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Cobertura XML 보고서를 사용하여 머지 리퀘스트 diffs에 줄별 커버리지 주석을 표시합니다. GitLab은 Cobertura XML 보고서를 읽고 각 변경된 줄에 커버됨(녹색), 커버되지 않음(빨강), 또는 로드되었지만 실행되지 않음(주황색)으로 주석을 답니다. GitLab은 파이프라인의 모든 스테이지에서 모든 작업의 보고서를 포함합니다.

커버리지 시각화는 [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report) 키워드를 사용합니다. 머지 리퀘스트 위젯에 커버리지 백분율을 표시하거나 커버리지 기록 그래프를 채우지 않습니다. 커버리지 백분율을 표시하려면 [`coverage`](../../../ci/yaml/_index.md#coverage) 키워드를 별도로 구성합니다.

[Cobertura XML](https://cobertura.github.io/cobertura/) 형식은 원래 Java용으로 개발되었지만 대부분의 커버리지 프레임워크는 플러그인 또는 내장 내보내기를 통해 이를 지원합니다:

- [simplecov-cobertura](https://rubygems.org/gems/simplecov-cobertura) (Ruby)
- [gocover-cobertura](https://github.com/boumenot/gocover-cobertura) (Go)
- [cobertura](https://www.npmjs.com/package/cobertura) (Node.js)
- [Istanbul](https://istanbul.js.org/docs/advanced/alternative-reporters/#cobertura) (JavaScript)
- [Coverage.py](https://coverage.readthedocs.io/en/coverage-5.0.4/cmd.html#xml-reporting) (Python)
- [PHPUnit](https://github.com/sebastianbergmann/phpunit-documentation-english/blob/master/src/textui.rst#command-line-options) (PHP)

## 예시 CI/CD 구성 {#example-cicd-configurations}

다음 예시는 다양한 프로그래밍 언어에 대해 CI/CD 작업을 구성하는 방법을 보여줍니다. [`coverage-report`](https://gitlab.com/gitlab-org/ci-sample-projects/coverage-report/) 데모 프로젝트에서 작동하는 예시를 볼 수도 있습니다.

### JavaScript 예시 {#javascript-example}

다음 `.gitlab-ci.yml` 예시는 [Mocha](https://mochajs.org/)와 [nyc](https://github.com/istanbuljs/nyc)를 사용하여 커버리지 아티팩트를 생성합니다:

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

### Java 및 Kotlin 예시 {#java-and-kotlin-examples}

GitLab 17.6 이상은 JaCoCo 형식을 기본적으로 지원합니다. 새 프로젝트의 경우 [기본 JaCoCo 보고서](jacoco.md)를 사용합니다.

다음 예시는 [jacoco2cobertura](https://gitlab.com/haynes/jacoco2cobertura) Docker 이미지를 사용하여 JaCoCo 보고서를 Cobertura 형식으로 변환합니다.

#### Maven 예시 {#maven-example}

`test-jdk11` 작업은 [Maven](https://maven.apache.org/)을 사용하여 JaCoCo XML 아티팩트를 생성합니다. `coverage-jdk11` 작업은 이를 Cobertura 형식으로 변환합니다:

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
  # The `visualize` stage does not exist by default.
  # Define it first, or use an existing stage like `deploy`.
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

#### Gradle 예시 {#gradle-example}

`test-jdk11` 작업은 [Gradle](https://gradle.org/)을 사용하여 JaCoCo XML 아티팩트를 생성합니다. `coverage-jdk11` 작업은 이를 Cobertura 형식으로 변환합니다:

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
  # The `visualize` stage does not exist by default.
  # Define it first, or use an existing stage like `deploy`.
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

### Python 예시 {#python-example}

다음 `.gitlab-ci.yml` 예시는 [pytest-cov](https://pytest-cov.readthedocs.io/)를 사용하여 테스트 커버리지 데이터를 수집합니다:

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

### PHP 예시 {#php-example}

다음 `.gitlab-ci.yml` 예시는 [PHPUnit](https://phpunit.readthedocs.io/)을 사용하여 테스트 커버리지 데이터를 수집하고 보고서를 생성합니다.

최소한의 [`phpunit.xml`](https://docs.phpunit.de/en/11.0/configuration.html) 파일(참고할 수 있는 [이 예시 리포지토리](https://gitlab.com/yookoala/code-coverage-visualization-with-php/))을 사용하여 테스트를 실행하고 `coverage.xml`를 생성할 수 있습니다:

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

[Codeception](https://codeception.com/)은 PHPUnit을 통해 [`run`](https://codeception.com/docs/reference/Commands#run)을 사용하여 Cobertura 보고서를 생성하는 것도 지원합니다. 생성된 파일의 경로는 `--coverage-cobertura` 옵션과 [`paths`](https://codeception.com/docs/reference/Configuration#paths) 구성([단위 테스트 스위트](https://codeception.com/docs/05-UnitTests)용)에 따라 다릅니다. `.gitlab-ci.yml`을 구성하여 적절한 경로에서 Cobertura를 찾습니다.

### C/C++ 예시 {#cc-example}

다음 `.gitlab-ci.yml` 예시는 C/C++와 `gcc` 또는 `g++`를 사용하며 [`gcovr`](https://gcovr.com/en/stable/)을 사용하여 Cobertura XML 형식의 커버리지 출력 파일을 생성합니다.

이 예제는 다음을 가정합니다.

- `Makefile`은 `cmake`에 의해 `build` 디렉토리에 생성되며, 이전 스테이지의 다른 작업에서 생성됩니다. `automake`을 사용하여 `Makefile`를 생성하는 경우 `make check` 대신 `make test`를 호출합니다.
- `cmake` (또는 `automake`)은 컴파일러 옵션 `--coverage`을 설정했습니다.

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

### Go 예시 {#go-example}

다음 `.gitlab-ci.yml` 예시는 다음을 사용합니다:

- [`go test`](https://go.dev/doc/tutorial/add-a-test)를 사용하여 테스트를 실행합니다.
- [`gocover-cobertura`](https://github.com/boumenot/gocover-cobertura)를 사용하여 Go의 커버리지 프로필을 Cobertura XML 형식으로 변환합니다.

이 예시는 [Go 모듈](https://go.dev/ref/mod)이 사용되고 있다고 가정합니다. `-covermode count` 옵션은 `-race` 플래그와 함께 작동하지 않습니다. `-race`을 사용하면서 코드 커버리지를 생성하려면 `-covermode atomic`로 전환합니다. 이는 더 느립니다.

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

### Ruby 예시 {#ruby-example}

다음 `.gitlab-ci.yml` 예시는 다음을 사용합니다:

- [`rspec`](https://rspec.info/)를 사용하여 테스트를 실행합니다.
- [`simplecov`](https://github.com/simplecov-ruby/simplecov)와 [`simplecov-cobertura`](https://github.com/dashingrocket/simplecov-cobertura)를 사용하여 커버리지 프로필을 기록하고 Cobertura XML 형식의 보고서를 생성합니다.

이 예제는 다음을 가정합니다.

- [`bundler`](https://bundler.io/)는 종속성 관리에 사용되며, `rspec`, `simplecov`, 및 `simplecov-cobertura`가 `Gemfile`에 추가됩니다.
- `CoberturaFormatter`이 `spec_helper.rb`의 `SimpleCov.formatters` 구성에 추가되었습니다.

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

## 문제 해결 {#troubleshooting}

경로 확인 실패, 파일 크기 제한, 주석이 표시되지 않는 문제 등 커버리지 시각화 문제 해결에 대해서는 [커버리지 시각화 문제 해결](coverage_visualization.md#troubleshooting)을 참조합니다.
