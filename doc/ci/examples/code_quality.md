---
disqus_identifier: 'https://docs.gitlab.com/ee/ci/examples/code_climate.html'
type: reference, howto
---

# Analyze your project's Code Quality

CAUTION: **Caution:**
The job definition shown below is supported on GitLab 11.11 and later versions.
It also requires the GitLab Runner 11.5 or later.
For earlier versions, use the [previous job definitions](#previous-job-definitions).

This example shows how to run Code Quality on your code by using GitLab CI/CD
and Docker.

First, you need GitLab Runner with
[docker-in-docker executor](../docker/using_docker_build.md#use-docker-in-docker-workflow-with-docker-executor).

Once you set up the Runner, include the CodeQuality template in your CI config:

```yaml
include:
  - template: Code-Quality.gitlab-ci.yml
```

The above example will create a `code_quality` job in your CI/CD pipeline which
will scan your source code for code quality issues. The report will be saved as a
[Code Quality report artifact](../yaml/README.md#artifactsreportscodequality-starter)
that you can later download and analyze.
Due to implementation limitations we always take the latest Code Quality artifact available.

TIP: **Tip:**
For [GitLab Starter][ee] users, this information will be automatically
extracted and shown right in the merge request widget.
[Learn more on Code Quality in merge requests](../../user/project/merge_requests/code_quality.md).

CAUTION: **Caution:**
On self-managed instances, if a malicious actor compromises the Code Quality job
definition they will be able to execute privileged docker commands on the Runner
host. Having proper access control policies mitigates this attack vector by
allowing access only to trusted actors.

## Previous job definitions

CAUTION: **Caution:**
Before GitLab 11.5, Code Quality job and artifact had to be named specifically
to automatically extract report data and show it in the merge request widget.
While these old job definitions are still maintained they have been deprecated
and may be removed in next major release, GitLab 12.0.
You are advised to update your current `.gitlab-ci.yml` configuration to reflect that change.

For GitLab 11.5 and earlier, the job should look like:

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
    reports:
      codequality: gl-code-quality-report.json
```

For GitLab 11.4 and earlier, the job should look like:

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

Alternatively the job name could be `codeclimate` or `codequality`
and the artifact name could be `codeclimate.json`.
These names have been deprecated with GitLab 11.0
and may be removed in next major release, GitLab 12.0.

For GitLab 10.3 and earlier, the job should look like:

```yaml
codequality:
  image: docker:latest
  variables:
    DOCKER_DRIVER: overlay
  services:
    - docker:dind
  script:
    - docker pull codeclimate/codeclimate:0.69.0
    - docker run --env CODECLIMATE_CODE="$PWD" --volume "$PWD":/code --volume /var/run/docker.sock:/var/run/docker.sock --volume /tmp/cc:/tmp/cc codeclimate/codeclimate:0.69.0 init
    - docker run --env CODECLIMATE_CODE="$PWD" --volume "$PWD":/code --volume /var/run/docker.sock:/var/run/docker.sock --volume /tmp/cc:/tmp/cc codeclimate/codeclimate:0.69.0 analyze -f json > codeclimate.json || true
  artifacts:
    paths: [codeclimate.json]
```

[cli]: https://github.com/codeclimate/codeclimate
[ee]: https://about.gitlab.com/pricing/
