# Dynamic Application Security Testing with GitLab CI/CD

This example shows how to run
[Dynamic Application Security Testing (DAST)](https://en.wikipedia.org/wiki/Dynamic_program_analysis)
on your project's source code by using GitLab CI/CD.

DAST is using the popular open source tool
[OWASP ZAProxy](https://github.com/zaproxy/zaproxy) to perform an analysis.

All you need is a GitLab Runner with the Docker executor (the shared Runners on
GitLab.com will work fine). You can then add a new job to `.gitlab-ci.yml`,
called `dast`:

```yaml
dast:
  image: owasp/zap2docker-stable
  script:
    - mkdir /zap/wrk/
    - /zap/zap-baseline.py -J gl-dast-report.json -t https://example.com || true
    - cp /zap/wrk/gl-dast-report.json .
  artifacts:
    paths: [gl-dast-report.json]
```

The above example will create a `dast` job in your CI pipeline and will allow
you to download and analyze the report artifact in JSON format.

TIP: **Tip:**
Starting with [GitLab Enterprise Edition Ultimate][ee] 10.4, this information will
be automatically extracted and shown right in the merge request widget. To do
so, the CI job must be named `dast` and the artifact path must be
`gl-dast-report.json`.
[Learn more on dynamic application security testing results shown in merge requests](../../user/project/merge_requests/dast.md).

[ee]: https://about.gitlab.com/gitlab-ee/
