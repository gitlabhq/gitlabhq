# Dynamic Application Security Testing with GitLab CI/CD

[Dynamic Application Security Testing (DAST)](https://en.wikipedia.org/wiki/Dynamic_program_analysis)
is using the popular open source tool [OWASP ZAProxy](https://github.com/zaproxy/zaproxy)
to perform an analysis on your running web application.

It can be very useful combined with [Review Apps](../review_apps/index.md).

## Example

All you need is a GitLab Runner with the Docker executor (the shared Runners on
GitLab.com will work fine). You can then add a new job to `.gitlab-ci.yml`,
called `dast`:

```yaml
dast:
  image: registry.gitlab.com/gitlab-org/security-products/zaproxy
  variables:
    website: "https://example.com"
  allow_failure: true
  script:
    - mkdir /zap/wrk/
    - /zap/zap-baseline.py -J gl-dast-report.json -t $website || true
    - cp /zap/wrk/gl-dast-report.json .
  artifacts:
    paths: [gl-dast-report.json]
```

The above example will create a `dast` job in your CI/CD pipeline which will run
the tests on the URL defined in the `website` variable (change it to use your
own) and finally write the results in the `gl-dast-report.json` file. You can
then download and analyze the report artifact in JSON format.

It's also possible to authenticate the user before performing DAST checks:

```yaml
dast:
  image: registry.gitlab.com/gitlab-org/security-products/zaproxy
  variables:
    website: "https://example.com"
    login_url: "https://example.com/sign-in"
  allow_failure: true
  script:
    - mkdir /zap/wrk/
    - /zap/zap-baseline.py -J gl-dast-report.json -t $website
        --auth-url $login_url
        --auth-username "john.doe@example.com"
        --auth-password "john-doe-password" || true
    - cp /zap/wrk/gl-dast-report.json .
  artifacts:
    paths: [gl-dast-report.json]
```
See [zaproxy documentation](https://gitlab.com/gitlab-org/security-products/zaproxy)
to learn more about authentication settings.

TIP: **Tip:**
Starting with [GitLab Ultimate][ee] 10.4, this information will
be automatically extracted and shown right in the merge request widget. To do
so, the CI job must be named `dast` and the artifact path must be
`gl-dast-report.json`.
[Learn more about DAST results shown in merge requests](../../user/project/merge_requests/dast.md).

[ee]: https://about.gitlab.com/products/
