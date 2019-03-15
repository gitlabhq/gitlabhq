# Container Scanning with GitLab CI/CD

CAUTION: **Caution:**
The job definition shown below is supported on GitLab 11.5 and later versions.
It also requires the GitLab Runner 11.5 or later.
For earlier versions, use the [previous job definitions](#previous-job-definitions).

You can check your Docker images (or more precisely the containers) for known
vulnerabilities by using [Clair](https://github.com/coreos/clair) and
[clair-scanner](https://github.com/arminc/clair-scanner), two open source tools
for Vulnerability Static Analysis for containers.

First, you need GitLab Runner with
[docker-in-docker executor](../docker/using_docker_build.md#use-docker-in-docker-executor).

Once you set up the Runner, add a new job to `.gitlab-ci.yml` that
generates the expected report:

```yaml
container_scanning:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
    ## Define two new variables based on GitLab's CI/CD predefined variables
    ## https://docs.gitlab.com/ee/ci/variables/#predefined-environment-variables
    CI_APPLICATION_REPOSITORY: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG
    CI_APPLICATION_TAG: $CI_COMMIT_SHA
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - docker run -d --name db arminc/clair-db:latest
    - docker run -p 6060:6060 --link db:postgres -d --name clair --restart on-failure arminc/clair-local-scan:v2.0.6
    - apk add -U wget ca-certificates
    - docker pull ${CI_APPLICATION_REPOSITORY}:${CI_APPLICATION_TAG}
    - wget https://github.com/arminc/clair-scanner/releases/download/v8/clair-scanner_linux_amd64
    - mv clair-scanner_linux_amd64 clair-scanner
    - chmod +x clair-scanner
    - touch clair-whitelist.yml
    - while( ! wget -q -O /dev/null http://docker:6060/v1/namespaces ) ; do sleep 1 ; done
    - retries=0
    - echo "Waiting for clair daemon to start"
    - while( ! wget -T 10 -q -O /dev/null http://docker:6060/v1/namespaces ) ; do sleep 1 ; echo -n "." ; if [ $retries -eq 10 ] ; then echo " Timeout, aborting." ; exit 1 ; fi ; retries=$(($retries+1)) ; done
    - ./clair-scanner -c http://docker:6060 --ip $(hostname -i) -r gl-container-scanning-report.json -l clair.log -w clair-whitelist.yml ${CI_APPLICATION_REPOSITORY}:${CI_APPLICATION_TAG} || true
  artifacts:
    reports:
      container_scanning: gl-container-scanning-report.json
```

The above example will create a `container_scanning` job in your CI/CD pipeline, pull
the image from the [Container Registry](../../user/project/container_registry.md)
(whose name is defined from the two `CI_APPLICATION_` variables) and scan it
for possible vulnerabilities. The report will be saved as a
[Container Scanning report artifact](../yaml/README.md#artifactsreportscontainer_scanning-ultimate)
that you can later download and analyze.
Due to implementation limitations we always take the latest Container Scanning artifact available.

If you want to whitelist some specific vulnerabilities, you can do so by defining
them in a [YAML file](https://github.com/arminc/clair-scanner/blob/master/README.md#example-whitelist-yaml-file),
in our case its named `clair-whitelist.yml`.

TIP: **Tip:**
For [GitLab Ultimate][ee] users, this information will
be automatically extracted and shown right in the merge request widget.
[Learn more on Container Scanning in merge requests](https://docs.gitlab.com/ee/user/project/merge_requests/container_scanning.html).

CAUTION: **Caution:**
Starting with GitLab 11.5, Container Scanning feature is licensed under the name `container_scanning`.
While the old name `sast_container` is still maintained, it has been deprecated with GitLab 11.5 and
may be removed in next major release, GitLab 12.0. You are advised to update your current `.gitlab-ci.yml`
configuration to reflect that change if you are using the `$GITLAB_FEATURES` environment variable.

## Previous job definitions

CAUTION: **Caution:**
Before GitLab 11.5, Container Scanning job and artifact had to be named specifically
to automatically extract report data and show it in the merge request widget.
While these old job definitions are still maintained they have been deprecated
and may be removed in next major release, GitLab 12.0.
You are advised to update your current `.gitlab-ci.yml` configuration to reflect that change.

For GitLab 11.4 and earlier, the job should look like:

```yaml
container_scanning:
  image: docker:stable
  variables:
    DOCKER_DRIVER: overlay2
    ## Define two new variables based on GitLab's CI/CD predefined variables
    ## https://docs.gitlab.com/ee/ci/variables/#predefined-environment-variables
    CI_APPLICATION_REPOSITORY: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG
    CI_APPLICATION_TAG: $CI_COMMIT_SHA
  allow_failure: true
  services:
    - docker:stable-dind
  script:
    - docker run -d --name db arminc/clair-db:latest
    - docker run -p 6060:6060 --link db:postgres -d --name clair --restart on-failure arminc/clair-local-scan:v2.0.6
    - apk add -U wget ca-certificates
    - docker pull ${CI_APPLICATION_REPOSITORY}:${CI_APPLICATION_TAG}
    - wget https://github.com/arminc/clair-scanner/releases/download/v8/clair-scanner_linux_amd64
    - mv clair-scanner_linux_amd64 clair-scanner
    - chmod +x clair-scanner
    - touch clair-whitelist.yml
    - while( ! wget -q -O /dev/null http://docker:6060/v1/namespaces ) ; do sleep 1 ; done
    - retries=0
    - echo "Waiting for clair daemon to start"
    - while( ! wget -T 10 -q -O /dev/null http://docker:6060/v1/namespaces ) ; do sleep 1 ; echo -n "." ; if [ $retries -eq 10 ] ; then echo " Timeout, aborting." ; exit 1 ; fi ; retries=$(($retries+1)) ; done
    - ./clair-scanner -c http://docker:6060 --ip $(hostname -i) -r gl-container-scanning-report.json -l clair.log -w clair-whitelist.yml ${CI_APPLICATION_REPOSITORY}:${CI_APPLICATION_TAG} || true
  artifacts:
    paths: [gl-container-scanning-report.json]
```

Alternatively the job name could be `sast:container`
and the artifact name could be `gl-sast-container-report.json`.
These names have been deprecated with GitLab 11.0
and may be removed in next major release, GitLab 12.0.

[ee]: https://about.gitlab.com/pricing/
