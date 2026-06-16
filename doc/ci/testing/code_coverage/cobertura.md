---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Display line-by-line test coverage annotations in merge request diffs using Cobertura XML reports.
title: Cobertura coverage visualization
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use Cobertura XML reports to display line-by-line coverage annotations in merge request
diffs. GitLab reads the Cobertura XML report and annotates each changed line as covered
(green), not covered (red), or loaded but never executed (orange).
GitLab includes reports from any job in any stage in the pipeline.

Coverage visualization uses the [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)
keyword. It does not display a coverage percentage in the MR widget or populate coverage history graphs.
To display a coverage percentage, configure the
[`coverage`](../../../ci/yaml/_index.md#coverage) keyword separately.

The [Cobertura XML](https://cobertura.github.io/cobertura/) format was originally
developed for Java, but most coverage frameworks support it through plugins or built-in
exporters:

- [simplecov-cobertura](https://rubygems.org/gems/simplecov-cobertura) (Ruby)
- [gocover-cobertura](https://github.com/boumenot/gocover-cobertura) (Go)
- [cobertura](https://www.npmjs.com/package/cobertura) (Node.js)
- [Istanbul](https://istanbul.js.org/docs/advanced/alternative-reporters/#cobertura) (JavaScript)
- [Coverage.py](https://coverage.readthedocs.io/en/coverage-5.0.4/cmd.html#xml-reporting) (Python)
- [PHPUnit](https://github.com/sebastianbergmann/phpunit-documentation-english/blob/master/src/textui.rst#command-line-options) (PHP)

## Example CI/CD configurations

The following examples show how to configure CI/CD jobs for different programming languages.
You can also see a working example in the
[`coverage-report`](https://gitlab.com/gitlab-org/ci-sample-projects/coverage-report/)
demonstration project.

### JavaScript example

The following `.gitlab-ci.yml` example uses [Mocha](https://mochajs.org/) and
[nyc](https://github.com/istanbuljs/nyc) to generate the coverage artifact:

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

### Java and Kotlin examples

GitLab 17.6 and later supports JaCoCo format natively.
For new projects, use [native JaCoCo reports](jacoco.md).

The following examples use the [jacoco2cobertura](https://gitlab.com/haynes/jacoco2cobertura)
Docker image to convert JaCoCo reports to Cobertura format.

#### Maven example

The `test-jdk11` job uses [Maven](https://maven.apache.org/) to generate a JaCoCo XML
artifact. The `coverage-jdk11` job converts it to Cobertura format:

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

#### Gradle example

The `test-jdk11` job uses [Gradle](https://gradle.org/) to generate a JaCoCo XML artifact.
The `coverage-jdk11` job converts it to Cobertura format:

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

### Python example

The following `.gitlab-ci.yml` example uses [pytest-cov](https://pytest-cov.readthedocs.io/)
to collect test coverage data:

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

### PHP example

The following `.gitlab-ci.yml` example uses [PHPUnit](https://phpunit.readthedocs.io/)
to collect test coverage data and generate the report.

With a minimal [`phpunit.xml`](https://docs.phpunit.de/en/11.0/configuration.html) file
(you can reference
[this example repository](https://gitlab.com/yookoala/code-coverage-visualization-with-php/)),
you can run the tests and generate `coverage.xml`:

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

[Codeception](https://codeception.com/), through PHPUnit, also supports generating a
Cobertura report with [`run`](https://codeception.com/docs/reference/Commands#run).
The path for the generated file depends on the `--coverage-cobertura` option and
[`paths`](https://codeception.com/docs/reference/Configuration#paths) configuration
for the [unit test suite](https://codeception.com/docs/05-UnitTests). Configure
`.gitlab-ci.yml` to find Cobertura in the appropriate path.

### C/C++ example

The following `.gitlab-ci.yml` example for C/C++ with `gcc` or `g++` uses
[`gcovr`](https://gcovr.com/en/stable/) to generate the coverage output file in
Cobertura XML format.

This example assumes:

- The `Makefile` is created by `cmake` in the `build` directory, in another job in a
  previous stage. If you use `automake` to generate the `Makefile`, call `make check`
  instead of `make test`.
- `cmake` (or `automake`) has set the compiler option `--coverage`.

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

### Go example

The following `.gitlab-ci.yml` example uses:

- [`go test`](https://go.dev/doc/tutorial/add-a-test) to run tests.
- [`gocover-cobertura`](https://github.com/boumenot/gocover-cobertura) to convert Go's
  coverage profile into Cobertura XML format.

This example assumes [Go modules](https://go.dev/ref/mod) are being used. The
`-covermode count` option does not work with the `-race` flag.
To generate code coverage while also using `-race`, switch to `-covermode atomic`, which is slower.

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

### Ruby example

The following `.gitlab-ci.yml` example uses:

- [`rspec`](https://rspec.info/) to run tests.
- [`simplecov`](https://github.com/simplecov-ruby/simplecov) and
  [`simplecov-cobertura`](https://github.com/dashingrocket/simplecov-cobertura) to record
  the coverage profile and create a report in Cobertura XML format.

This example assumes:

- [`bundler`](https://bundler.io/) is used for dependency management, with `rspec`,
  `simplecov`, and `simplecov-cobertura` added to your `Gemfile`.
- `CoberturaFormatter` has been added to your `SimpleCov.formatters` configuration in
  `spec_helper.rb`.

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

## Troubleshooting

For troubleshooting coverage visualization, including path resolution failures, file size
limits, and annotations not appearing, see
[coverage visualization troubleshooting](coverage_visualization.md#troubleshooting).
