# Static Application Security Testing with GitLab CI/CD

NOTE: **Note:**
In order to use this tool, a [GitLab Enterprise Edition Ultimate][ee] license
is needed.

This example shows how to run
[Static Application Security Testing (SAST)](https://en.wikipedia.org/wiki/Static_program_analysis)
on your project's source code by using GitLab CI/CD.

All you need is a GitLab Runner with the Docker executor (the shared Runners on
GitLab.com will work fine). You can then add a new job to `.gitlab-ci.yml`,
called `sast`:

```yaml
sast:
  image: registry.gitlab.com/gitlab-org/gl-sast:latest
  script:
    - /app/bin/run .
  artifacts:
    paths: [gl-sast-report.json]
```

Behind the scenes, the [gl-sast Docker image](https://gitlab.com/gitlab-org/gl-sast)
is used to detect the language/framework and in turn runs the matching scan tool.

The above example will create a `sast` job in your CI pipeline and will allow
you to download and analyze the report artifact in JSON format.

The results are sorted by the priority of the vulnerability:

1. High
1. Medium
1. Low
1. Unknown
1. Everything else

TIP: **Tip:**
Starting with [GitLab Enterprise Edition Ultimate][ee] 10.3, this information will
be automatically extracted and shown right in the merge request widget. To do
so, the CI job must be named `sast` and the artifact path must be
`gl-sast-report.json`.
[Learn more on application security testing results shown in merge requests](../../user/project/merge_requests/sast.md).

## Supported languages and frameworks

The following languages and frameworks are supported.

| Language / framework | Scan tool |
| -------------------- | --------- |
| JavaScript    | [Retire.js](https://retirejs.github.io/retire.js)
| Python        | [bandit](https://github.com/openstack/bandit) |
| Ruby          | [bundler-audit](https://github.com/rubysec/bundler-audit) |
| Ruby on Rails | [brakeman](https://brakemanscanner.org) |

[ee]: https://about.gitlab.com/gitlab-ee/
