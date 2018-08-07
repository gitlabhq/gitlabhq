# Collect Test Reports in Verify stage

As of GitLab 11.2, you can collect test reports to concreate your [Verify](link) step in DevOps toolchain.

All you need is to specify `artifacts:reports` keyword in gitlab-ci.yml, and specify paths of generated test reports (See more [available formats](link)).

For instance, we have three jobs in `test` stage and we want to collect JUnit test reports from each job.

```yaml
rspec 0 3:
  stage: test
  script:
  - bundle install
  - rspec spec/lib/ --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml

rspec 1 3:
  stage: test
  script:
  - bundle install
  - rspec spec/models/ --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml

rspec 2 3:
  stage: test
  script:
  - bundle install
  - rspec spec/features/ --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
```

At first, in order to create a JUnit format report, you customize `script`.
In this example, [`RSpec JUnit Formatter`](https://github.com/sj26/rspec_junit_formatter) is used to generate JUnit test reports from `rspec` command.
After each job has been executed by [GitLab-runner](link), `rspec.xml` are stored in GitLab, and it surfaces in GitLab UI e.g. [Merge request widget](link).

NOTE: **Note:**
> - You can find a relevant tool in each programming language. e.g. [Phython](https://pypi.org/project/junit-xml/) [Go](https://github.com/jstemmer/go-junit-report)

[junit-specification]: https://www.ibm.com/support/knowledgecenter/en/SSQ2R2_14.1.0/com.ibm.rsar.analysis.codereview.cobol.doc/topics/cac_useresults_junit.html
