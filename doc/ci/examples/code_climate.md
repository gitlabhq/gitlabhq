# Analyze project code quality with Code Climate CLI

This example shows how to run [Code Climate CLI][cli] on your code by using\
GitLab CI and Docker.

First, you need GitLab Runner with [docker-in-docker executor](../docker/using_docker_build.md#use-docker-in-docker-executor).

Once you setup the Runner add new job to `.gitlab-ci.yml`:

```yaml
codeclimate:
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

This will create a `codeclimate` job in your CI pipeline and will allow you to
download and analyze the report artifact in JSON format.

[cli]: https://github.com/codeclimate/codeclimate
