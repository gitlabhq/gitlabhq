# Static application security testing of your docker image with GitLab CI/CD

NOTE: **Note:**
In order to use this tool, a [GitLab Enterprise Edition Ultimate][ee] license
is needed.

All you need is a GitLab Runner with the Docker executor (the shared Runners on
GitLab.com will work fine). You can then add a new job to `.gitlab-ci.yml`,
called `sast:image`:

```yaml
sast:image:
  image: docker:latest
  variables:
    DOCKER_DRIVER: overlay2
  allow_failure: true
  services:
    - docker:dind
  script:
    - setup_docker
    - docker run -d --name db arminc/clair-db:latest
    - docker run -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:v2.0.1
    - apk add -U wget ca-certificates
    - docker pull ${CI_APPLICATION_REPOSITORY}:${CI_APPLICATION_TAG}
    - wget https://github.com/arminc/clair-scanner/releases/download/v6/clair-scanner_linux_386
    - mv clair-scanner_linux_386 clair-scanner
    - chmod +x clair-scanner
    - touch clair-whitelist.yml
    - ./clair-scanner -c http://docker:6060 --ip $(hostname -i) -r gl-sast-image-report.json -l clair.log -w clair-whitelist.yml ${CI_APPLICATION_REPOSITORY}:${CI_APPLICATION_TAG} || true
  artifacts:
    paths: [gl-sast-image-report.json]
```

The above example will create a `sast:image` job in your CI pipeline and will allow
you to download and analyze the report artifact in JSON format.


TODO: TELL ABOUT WHITELISTING HERE. 

TIP: **Tip:**
Starting with GitLab Enterprise Edition Ultimate 10.3, this information will
be automatically extracted and shown right in the merge request widget. To do
so, the CI job must be named `sast:image` and the artifact path must be
`gl-sast-image-report.json`.
[Learn more on application security testing results shown in merge requests](../../user/project/merge_requests/sast-image.md).

[ee]: https://about.gitlab.com/gitlab-ee/
