# Dynamic Application Security Testing with GitLab CI/CD

CAUTION: **Caution:**
The job definition shown below is supported on GitLab 11.5 and later versions.
It also requires the GitLab Runner 11.5 or later.
For earlier versions, use the [previous job definitions](#previous-job-definitions).

[Dynamic Application Security Testing (DAST)](https://en.wikipedia.org/wiki/Dynamic_program_analysis)
is using the popular open source tool [OWASP ZAProxy](https://github.com/zaproxy/zaproxy)
to perform an analysis on your running web application.
Since it is based on [ZAP Baseline](https://github.com/zaproxy/zaproxy/wiki/ZAP-Baseline-Scan)
DAST will perform passive scanning only;
it will not actively attack your application.

It can be very useful combined with [Review Apps](../review_apps/index.md).

## Example

First, you need GitLab Runner with
[docker-in-docker executor](../docker/using_docker_build.md#use-docker-in-docker-executor).

Once you set up the Runner, add a new job to `.gitlab-ci.yml` that
generates the expected report:

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
    reports:
      dast: gl-dast-report.json
```

The above example will create a `dast` job in your CI/CD pipeline which will run
the tests on the URL defined in the `website` variable (change it to use your
own) and scan it for possible vulnerabilities. The report will be saved as a
[DAST report artifact](https://docs.gitlab.com/ee//ci/yaml/README.html#artifactsreportsdast)
that you can later download and analyze.
Due to implementation limitations we always take the latest DAST artifact available.

It's also possible to authenticate the user before performing DAST checks:

```yaml
dast:
  image: registry.gitlab.com/gitlab-org/security-products/zaproxy
  variables:
    website: "https://example.com"
    login_url: "https://example.com/sign-in"
    username: "john.doe@example.com"
    password: "john-doe-password"
  allow_failure: true
  script:
    - mkdir /zap/wrk/
    - /zap/zap-baseline.py -J gl-dast-report.json -t $website
        --auth-url $login_url
        --auth-username $username
        --auth-password $password || true
    - cp /zap/wrk/gl-dast-report.json .
  artifacts:
    reports:
      dast: gl-dast-report.json
```
See [zaproxy documentation](https://gitlab.com/gitlab-org/security-products/zaproxy)
to learn more about authentication settings.

TIP: **Tip:**
For [GitLab Ultimate][ee] users, this information will
be automatically extracted and shown right in the merge request widget.
[Learn more on DAST in merge requests](https://docs.gitlab.com/ee/user/project/merge_requests/dast.html).

## Previous job definitions

CAUTION: **Caution:**
Before GitLab 11.5, DAST job and artifact had to be named specifically
to automatically extract report data and show it in the merge request widget.
While these old job definitions are still maintained they have been deprecated
and may be removed in next major release, GitLab 12.0.
You are advised to update your current `.gitlab-ci.yml` configuration to reflect that change.

For GitLab 11.4 and earlier, the job should look like:

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

[ee]: https://about.gitlab.com/pricing/
