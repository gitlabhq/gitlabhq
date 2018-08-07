# Collect Test Reports in Verify stage

As of GitLab 11.2, you can collect test reports to concreate your [Verify](link) step in DevOps toolchain.

All you need is to specify `artifacts:reports` keyword in gitlab-ci.yml, and specify the most convenient format from [the available formats](link).

For example, we have three jobs in `test` stage and we want to collect JUnit test reports from each job.

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

You need to tweak `script` to create a JUnit format report, int this example, we use [`RSpec JUnit Formatter`](https://github.com/sj26/rspec_junit_formatter)
You can find other tools for other programming languages. Since [JUnit specification](junit-specification) is pretty simple, it would be possible to create your custom formatter.

After each job has been executed by [GitLab-runner](link), `rspec.xml` are stored in GitLab, and surface in [Merge request widget](link).

[junit-specification]: https://www.ibm.com/support/knowledgecenter/en/SSQ2R2_14.1.0/com.ibm.rsar.analysis.codereview.cobol.doc/topics/cac_useresults_junit.html
