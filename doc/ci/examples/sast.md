# Static Application Security Testing with GitLab CI/CD **[ULTIMATE]**

This example shows how to run
[Static Application Security Testing (SAST)](https://en.wikipedia.org/wiki/Static_program_analysis)
on your project's source code by using GitLab CI/CD.

First, you need GitLab Runner with [docker-in-docker executor](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-in-docker-executor).
You can then add a new job to `.gitlab-ci.yml`, called `sast`:

```yaml
sast:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - export SP_VERSION=$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')
    - docker run
        --env SAST_CONFIDENCE_LEVEL="${SAST_CONFIDENCE_LEVEL:-3}"
        --volume "$PWD:/code"
        --volume /var/run/docker.sock:/var/run/docker.sock
        "registry.gitlab.com/gitlab-org/security-products/sast:$SP_VERSION" /app/bin/run /code
  artifacts:
    paths: [gl-sast-report.json]
```

The above example will create a `sast` job in the `test` stage and will create the required report artifact. Check the
[Auto-DevOps template](https://gitlab.com/gitlab-org/gitlab-ci-yml/blob/master/Auto-DevOps.gitlab-ci.yml)
for a full reference.

The results are sorted by the priority of the vulnerability:

1. High
1. Medium
1. Low
1. Unknown
1. Everything else

Behind the scenes, the [GitLab SAST Docker image](https://gitlab.com/gitlab-org/security-products/sast)
is used to detect the languages/frameworks and in turn runs the matching scan tools.

Some security scanners require to send a list of project dependencies to GitLab
central servers to check for vulnerabilities. To learn more about this or to
disable it, check the [GitLab SAST tool documentation](https://gitlab.com/gitlab-org/security-products/sast#remote-checks).

TIP: **Tip:**
Starting with [GitLab Ultimate][ee] 10.3, this information will
be automatically extracted and shown right in the merge request widget. To do
so, the CI job must be named `sast` and the artifact path must be
`gl-sast-report.json`. Make sure your pipeline has a stage nammed `test`, or specify another existing stage inside the `sast` job.
[Learn more on application security testing results shown in merge requests](../../user/project/merge_requests/sast.md).

## Supported languages and frameworks

See [the full list of supported languages and frameworks](../../user/project/merge_requests/sast.md#supported-languages-and-frameworks).

[ee]: https://about.gitlab.com/products/
