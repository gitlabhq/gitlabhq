# Running tests that require special setup

## Jenkins spec

The [`jenkins_build_status_spec`](https://gitlab.com/gitlab-org/gitlab/blob/163c8a8c814db26d11e104d1cb2dcf02eb567dbe/qa/qa/specs/features/ee/browser_ui/3_create/jenkins/jenkins_build_status_spec.rb) spins up a Jenkins instance in a Docker container based on an image stored in the [GitLab-QA container registry](https://gitlab.com/gitlab-org/gitlab-qa/container_registry).
The Docker image it uses is preconfigured with some base data and plugins.
The test then configures the GitLab plugin in Jenkins with a URL of the GitLab instance that will be used
to run the tests. Unfortunately, the GitLab Jenkins plugin does not accept ports so `http://localhost:3000` would
not be accepted. Therefore, this requires us to run GitLab on port 80 or inside a Docker container.

To start a Docker container for GitLab based on the nightly image:

```shell
docker run \
  --publish 80:80 \
  --name gitlab \
  --hostname localhost \
  gitlab/gitlab-ee:nightly
```

To run the tests from the `/qa` directory:

```shell
CHROME_HEADLESS=false bin/qa Test::Instance::All http://localhost -- qa/specs/features/ee/browser_ui/3_create/jenkins/jenkins_build_status_spec.rb
```

The test will automatically spinup a Docker container for Jenkins and tear down once the test completes.

However, if you need to run Jenkins manually outside of the tests, use this command:

```shell
docker run \
  --hostname localhost \
  --name jenkins-server \
  --env JENKINS_HOME=jenkins_home \
  --publish 8080:8080 \
  registry.gitlab.com/gitlab-org/gitlab-qa/jenkins-gitlab:version1
```

Jenkins will be available on `http://localhost:8080`.

Admin username is `admin` and password is `password`.

It is worth noting that this is not an orchestrated test. It is [tagged with the `:orchestrated` meta](https://gitlab.com/gitlab-org/gitlab/blob/163c8a8c814db26d11e104d1cb2dcf02eb567dbe/qa/qa/specs/features/ee/browser_ui/3_create/jenkins/jenkins_build_status_spec.rb#L5)
only to prevent it from running in the pipelines for live environments such as Staging.

### Troubleshooting

If Jenkins Docker container exits without providing any information in the logs, try increasing the memory used by
the Docker Engine.
