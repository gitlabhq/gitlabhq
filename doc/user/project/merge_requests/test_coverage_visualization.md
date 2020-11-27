---
stage: Verify
group: Testing
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Test Coverage Visualization

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3708) in GitLab 12.9.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/249811) in GitLab 13.5.

With the help of [GitLab CI/CD](../../../ci/README.md), you can collect the test
coverage information of your favorite testing or coverage-analysis tool, and visualize
this information inside the file diff view of your merge requests (MRs). This will allow you
to see which lines are covered by tests, and which lines still require coverage, before the
MR is merged.

![Test Coverage Visualization Diff View](img/test_coverage_visualization_v12_9.png)

## How test coverage visualization works

Collecting the coverage information is done via GitLab CI/CD's
[artifacts reports feature](../../../ci/pipelines/job_artifacts.md#artifactsreports).
You can specify one or more coverage reports to collect, including wildcard paths.
GitLab will then take the coverage information in all the files and combine it
together.

For the coverage analysis to work, you have to provide a properly formatted
[Cobertura XML](https://cobertura.github.io/cobertura/) report to
[`artifacts:reports:cobertura`](../../../ci/pipelines/job_artifacts.md#artifactsreportscobertura).
This format was originally developed for Java, but most coverage analysis frameworks
for other languages have plugins to add support for it, like:

- [simplecov-cobertura](https://rubygems.org/gems/simplecov-cobertura) (Ruby)
- [gocover-cobertura](https://github.com/t-yuki/gocover-cobertura) (Golang)

Other coverage analysis frameworks support the format out of the box, for example:

- [Istanbul](https://istanbul.js.org/docs/advanced/alternative-reporters/#cobertura) (JavaScript)
- [Coverage.py](https://coverage.readthedocs.io/en/coverage-5.0.4/cmd.html#xml-reporting) (Python)

Once configured, if you create a merge request that triggers a pipeline which collects
coverage reports, the coverage will be shown in the diff view. This includes reports
from any job in any stage in the pipeline. The coverage will be displayed for each line:

- `covered` (green): lines which have been checked at least once by tests
- `no test coverage` (orange): lines which are loaded but never executed
- no coverage information: lines which are non-instrumented or not loaded

Hovering over the coverage bar will provide further information, such as the number
of times the line was checked by tests.

NOTE: **Note:**
The Cobertura XML parser currently does not support the `sources` element and ignores it. It is assumed that
the `filename` of a `class` element contains the full path relative to the project root.

## Example test coverage configurations

### JavaScript example

The following [`gitlab-ci.yml`](../../../ci/yaml/README.md) example uses [Mocha](https://mochajs.org/)
JavaScript testing and [NYC](https://github.com/istanbuljs/nyc) coverage-tooling to
generate the coverage artifact:

```yaml
test:
  script:
    - npm install
    - npx nyc --reporter cobertura mocha
  artifacts:
    reports:
      cobertura: coverage/cobertura-coverage.xml
```

### Java and Kotlin examples

#### Maven example

The following [`gitlab-ci.yml`](../../../ci/yaml/README.md) example for Java or Kotlin uses [Maven](https://maven.apache.org/)
to build the project and [Jacoco](https://www.eclemma.org/jacoco/) coverage-tooling to
generate the coverage artifact.
You can check the [Docker image configuration and scripts](https://gitlab.com/haynes/jacoco2cobertura) if you want to build your own image.

GitLab expects the artifact in the Cobertura format, so you have to execute a few
scripts before uploading it. The `test-jdk11` job tests the code and generates an
XML artifact. The `coverage-jdk-11` job converts the artifact into a Cobertura report:

```yaml
test-jdk11:
  stage: test
  image: maven:3.6.3-jdk-11
  script:
    - 'mvn $MAVEN_CLI_OPTS clean org.jacoco:jacoco-maven-plugin:prepare-agent test jacoco:report'
  artifacts:
    paths:
      - target/site/jacoco/jacoco.xml

coverage-jdk11:
  # Must be in a stage later than test-jdk11's stage.
  # The `visualize` stage does not exist by default.
  # Please define it first, or chose an existing stage like `deploy`.
  stage: visualize
  image: haynes/jacoco2cobertura:1.0.4
  script:
    # convert report from jacoco to cobertura
    - 'python /opt/cover2cover.py target/site/jacoco/jacoco.xml src/main/java > target/site/cobertura.xml'
    # read the <source></source> tag and prepend the path to every filename attribute
    - 'python /opt/source2filename.py target/site/cobertura.xml'
  needs: ["test-jdk11"]
  dependencies:
    - test-jdk11
  artifacts:
    reports:
      cobertura: target/site/cobertura.xml
```

#### Gradle example

The following [`gitlab-ci.yml`](../../../ci/yaml/README.md) example for Java or Kotlin uses [Gradle](https://gradle.org/)
to build the project and [Jacoco](https://www.eclemma.org/jacoco/) coverage-tooling to
generate the coverage artifact.
You can check the [Docker image configuration and scripts](https://gitlab.com/haynes/jacoco2cobertura) if you want to build your own image.

GitLab expects the artifact in the Cobertura format, so you have to execute a few
scripts before uploading it. The `test-jdk11` job tests the code and generates an
XML artifact. The `coverage-jdk-11` job converts the artifact into a Cobertura report:

```yaml
test-jdk11:
  stage: test
  image: gradle:6.6.1-jdk11
  script:
    - 'gradle test jacocoTestReport' # jacoco must be configured to create an xml report
  artifacts:
    paths:
      - build/jacoco/jacoco.xml

coverage-jdk11:
  # Must be in a stage later than test-jdk11's stage.
  # The `visualize` stage does not exist by default.
  # Please define it first, or chose an existing stage like `deploy`.
  stage: visualize
  image: haynes/jacoco2cobertura:1.0.4
  script:
    # convert report from jacoco to cobertura
    - 'python /opt/cover2cover.py build/jacoco/jacoco.xml src/main/java > build/cobertura.xml'
    # read the <source></source> tag and prepend the path to every filename attribute
    - 'python /opt/source2filename.py build/cobertura.xml'
  needs: ["test-jdk11"]
  dependencies:
    - test-jdk11
  artifacts:
    reports:
      cobertura: build/cobertura.xml
```

### Python example

The following [`gitlab-ci.yml`](../../../ci/yaml/README.md) example for Python uses [pytest-cov](https://pytest-cov.readthedocs.io/) to collect test coverage data and [coverage.py](https://coverage.readthedocs.io/) to convert the report to use full relative paths.
The information isn't displayed without the conversion.

This example assumes that the code for your package is in `src/` and your tests are in `tests.py`:

```yaml
run tests:
  stage: test
  image: python:3
  script:
    - pip install pytest pytest-cov
    - pytest --cov=src/ tests.py
    - coverage xml
  artifacts:
    reports:
      cobertura: coverage.xml
```
