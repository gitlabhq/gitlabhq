# Analyze your project's Code Quality

This example shows how to run Code Quality on your code by using GitLab CI/CD
and Docker.

First, you need GitLab Runner with [docker-in-docker executor][dind].

Once you set up the Runner, add a new job to `.gitlab-ci.yml`, called `code_quality`:

```yaml
code_quality:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - export SP_VERSION=$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')
    - docker run
        --env SOURCE_CODE="$PWD"
        --volume "$PWD":/code
        --volume /var/run/docker.sock:/var/run/docker.sock
        "registry.gitlab.com/gitlab-org/security-products/codequality:$SP_VERSION" /code
  artifacts:
    paths: [gl-code-quality-report.json]
```

The above example will create a `code_quality` job in your CI/CD pipeline which
will scan your source code for code quality issues. The report will be saved
as an artifact that you can later download and analyze.

TIP: **Tip:**
Starting with [GitLab Starter][ee] 9.3, this information will
be automatically extracted and shown right in the merge request widget. To do
so, the CI/CD job must be named `code_quality` and the artifact path must be
`gl-code-quality-report.json`.
[Learn more on Code Quality in merge requests](https://docs.gitlab.com/ee/user/project/merge_requests/code_quality.html).

CAUTION: **Caution:**
Code Quality was previously using `codeclimate` and `codequality` for job name and
`codeclimate.json` for the artifact name. While these old names
are still maintained they have been deprecated with GitLab 11.0 and may be removed
in next major release, GitLab 12.0. You are advised to update your current `.gitlab-ci.yml`
configuration to reflect that change.

[cli]: https://github.com/codeclimate/codeclimate
[dind]: ../docker/using_docker_build.md#use-docker-in-docker-executor
[ee]: https://about.gitlab.com/pricing/
