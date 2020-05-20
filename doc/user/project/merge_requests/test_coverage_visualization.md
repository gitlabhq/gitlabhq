---
type: reference, howto
---

# Test Coverage Visualization

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/3708) in GitLab 12.9.

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

## Example test coverage configuration

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

## Enabling the feature

This feature comes with the `:coverage_report_view` feature flag disabled by
default. This feature is disabled due to some performance issues with very large
data sets. When [the performance issue](https://gitlab.com/gitlab-org/gitlab/issues/211410)
is resolved, the feature will be enabled by default.

To enable this feature, ask a GitLab administrator with Rails console access to
run the following command:

```ruby
Feature.enable(:coverage_report_view)
```
