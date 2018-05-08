# Dependencies license management with GitLab CI/CD

NOTE: **Note:**
In order to use this tool, a [GitLab Ultimate][ee] license
is needed.

This example shows how to run the License Management tool on your
project's dependencies by using GitLab CI/CD.

First, you need GitLab Runner with [docker-in-docker executor](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-in-docker-executor).
You can then add a new job to `.gitlab-ci.yml`, called `license_management`:

```yaml
license_management:
  image: registry.gitlab.com/gitlab-org/security-products/license-management:latest
  allow_failure: true
  script:
    - /run.sh .
  artifacts:
    paths: [gl-license-report.json]
```

The above example will create a `license_management` job in the `test` stage and will create the required report artifact. Check the
[Auto-DevOps template](https://gitlab.com/gitlab-org/gitlab-ci-yml/blob/master/Auto-DevOps.gitlab-ci.yml)
for a full reference.


TIP: **Tip:**
Starting with [GitLab Ultimate][ee] 10.8, this information will
be automatically extracted and shown right in the merge request widget. To do
so, the CI job must be named `license_management` and the artifact path must be
`gl-license-report.json`. Make sure your pipeline has a stage nammed `test`,
or specify another existing stage inside the `license_management` job.
[Learn more on license management results shown in merge requests](../../user/project/merge_requests/license_management.md).


[ee]: https://about.gitlab.com/products/
