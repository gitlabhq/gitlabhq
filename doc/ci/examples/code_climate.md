# Analyze project code quality with Code Climate CLI

This example shows how to run [Code Climate CLI][cli] on your code by using
GitLab CI and Docker.

First, you need GitLab Runner with [docker-in-docker executor][dind].

Once you set up the Runner, add a new job to `.gitlab-ci.yml`, called `codequality`:

```yaml
codequality:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - export SP_VERSION=$(echo "$CI_SERVER_VERSION" | sed 's/^\([0-9]*\)\.\([0-9]*\).*/\1-\2-stable/')
    - docker run --env SOURCE_CODE="$PWD" --volume "$PWD":/code --volume /var/run/docker.sock:/var/run/docker.sock "registry.gitlab.com/gitlab-org/security-products/codequality:$SP_VERSION" /code
  artifacts:
    paths: [codeclimate.json]
```

The above example will create a `codequality` job in your CI/CD pipeline which
will scan your source code for code quality issues. The report will be saved
as an artifact that you can later download and analyze.

TIP: **Tip:**
Starting with [GitLab Starter][ee] 9.3, this information will
be automatically extracted and shown right in the merge request widget. To do
so, the CI/CD job must be named `codequality` and the artifact path must be
`codeclimate.json`.
[Learn more on code quality diffs in merge requests](https://docs.gitlab.com/ee/user/project/merge_requests/code_quality_diff.html).

[cli]: https://github.com/codeclimate/codeclimate
[dind]: ../docker/using_docker_build.md#use-docker-in-docker-executor
[ee]: https://about.gitlab.com/products/
