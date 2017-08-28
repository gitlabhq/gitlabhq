# Analyze project code quality with Code Climate CLI

This example shows how to run [Code Climate CLI][cli] on your code by using
GitLab CI and Docker.

First, you need GitLab Runner with [docker-in-docker executor][dind].

Once you set up the Runner, add a new job to `.gitlab-ci.yml`, called `codequality`:

```yaml
codequality:
  image: docker:latest
  variables:
    DOCKER_DRIVER: overlay
  services:
    - docker:dind
  script:
    - docker pull codeclimate/codeclimate
    - docker run --env CODECLIMATE_CODE="$PWD" --volume "$PWD":/code --volume /var/run/docker.sock:/var/run/docker.sock --volume /tmp/cc:/tmp/cc codeclimate/codeclimate init
    - docker run --env CODECLIMATE_CODE="$PWD" --volume "$PWD":/code --volume /var/run/docker.sock:/var/run/docker.sock --volume /tmp/cc:/tmp/cc codeclimate/codeclimate analyze -f json > codeclimate.json
  artifacts:
    paths: [codeclimate.json]
```

This will create a `codequality` job in your CI pipeline and will allow you to
download and analyze the report artifact in JSON format.

For GitLab [Enterprise Edition Starter][ee] users, this information can be automatically
extracted and shown right in the merge request widget. [Learn more on code quality
diffs in merge requests](../../user/project/merge_requests/code_quality_diff.md).

[cli]: https://github.com/codeclimate/codeclimate
[dind]: ../docker/using_docker_build.md#use-docker-in-docker-executor
[ee]: https://about.gitlab.com/gitlab-ee/
