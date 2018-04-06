# Dependency Scanning with GitLab CI/CD

NOTE: **Note:**
In order to use this tool, a [GitLab Ultimate][ee] license
is needed.

This example shows how to run Dependency Scanning on your
project's dependencies by using GitLab CI/CD.

First, you need GitLab Runner with [docker-in-docker executor](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-in-docker-executor).
You can then add a new job to `.gitlab-ci.yml`, called `dependency_scanning`:

```yaml
dependency_scanning:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - export SP_VERSION=$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')
    - docker run
        --env DEP_SCAN_DISABLE_REMOTE_CHECKS="${DEP_SCAN_DISABLE_REMOTE_CHECKS:-false}" \
        --volume "$PWD:/code" \
        --volume /var/run/docker.sock:/var/run/docker.sock \
        "registry.gitlab.com/gitlab-org/security-products/dependency-scanning:$SP_VERSION" /code
  artifacts:
    paths: [gl-dependency-scanning-report.json]
```

The above example will create a `dependency_scanning` job in the `test` stage and will create the required report artifact. Check the
[Auto-DevOps template](https://gitlab.com/gitlab-org/gitlab-ci-yml/blob/master/Auto-DevOps.gitlab-ci.yml)
for a full reference.

The results are sorted by the priority of the vulnerability:

1. High
1. Medium
1. Low
1. Unknown
1. Everything else

Behind the scenes, the [GitLab Dependency Scanning Docker image](https://gitlab.com/gitlab-org/security-products/dependency-scanning)
is used to detect the languages/package managers and in turn runs the matching scan tools.

Some security scanners require to send a list of project dependencies to GitLab
central servers to check for vulnerabilities. To learn more about this or to
disable it, check the [GitLab Dependency Scanning documentation](https://gitlab.com/gitlab-org/security-products/dependency-scanning#remote-checks).

TIP: **Tip:**
Starting with [GitLab Ultimate][ee] 10.7, this information will
be automatically extracted and shown right in the merge request widget. To do
so, the CI job must be named `dependency_scanning` and the artifact path must be
`gl-dependency-scanning-report.json`. Make sure your pipeline has a stage nammed `test`,
or specify another existing stage inside the `dependency_scanning` job.
[Learn more on dependency scanning results shown in merge requests](../../user/project/merge_requests/dependency_scanning.md).

## Supported languages and package managers

See [the full list of supported languages and package managers](../../user/project/merge_requests/dependency_scanning.md#supported-languages-and-frameworks).

[ee]: https://about.gitlab.com/products/
