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

The test will automatically spin up a Docker container for Jenkins and tear down once the test completes.

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

## Gitaly Cluster tests

The tests tagged `:gitaly_ha` are orchestrated tests that can only be run against a set of Docker containers as configured and started by [the `Test::Integration::GitalyCluster` GitLab QA scenario](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#testintegrationgitalycluster-ceeefull-image-address).

As described in the documentation about the scenario noted above, the following command will run the tests:

```shell
gitlab-qa Test::Integration::GitalyCluster EE
```

However, that will remove the containers after it finishes running the tests. If you would like to do further testing, for example, if you would like to run a single test via a debugger, you can use [the `--no-tests` option](https://gitlab.com/gitlab-org/gitlab-qa#command-line-options) to make `gitlab-qa` skip running the tests, and to leave the containers running so that you can continue to use them.

```shell
gitlab-qa Test::Integration::GitalyCluster EE --no-tests
```

When all the containers are running you will see the output of the `docker ps` command, showing on which ports the GitLab container can be accessed. For example:

```plaintext
CONTAINER ID   ...     PORTS                                    NAMES
d15d3386a0a8   ...     22/tcp, 443/tcp, 0.0.0.0:32772->80/tcp   gitlab-gitaly-ha
```

That shows that the GitLab instance running in the `gitlab-gitaly-ha` container can be reached via `http://localhost:32772`. However, Git operations like cloning and pushing are performed against the URL revealed via the UI as the clone URL. It uses the hostname configured for the GitLab instance, which in this case matches the Docker container name and network, `gitlab-gitaly-ha.test`. Before you can run the tests you need to configure your computer to access the container via that address. One option is to [use caddyserver as described for running tests against GDK](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/run_qa_against_gdk.md#workarounds).

Another option is to use NGINX.

In both cases you will need to configure your machine to translate `gitlab-gitlab-ha.test` into an appropriate IP address:

```shell
echo '127.0.0.1 gitlab-gitaly-ha.test' | sudo tee -a /etc/hosts
```

Then install NGINX:

```shell
# on macOS
brew install nginx

# on Debian/Ubuntu
apt install nginx

# on Fedora
yum install nginx
```

Finally, configure NGINX to pass requests for `gitlab-gitaly-ha.test` to the GitLab instance:

```plaintext
# On Debian/Ubuntu, in /etc/nginx/sites-enabled/gitlab-cluster
# On macOS, in /usr/local/etc/nginx/nginx.conf

server {
  server_name gitlab-gitaly-ha.test;
  client_max_body_size 500m;

  location / {
    proxy_pass http://127.0.0.1:32772;
    proxy_set_header Host gitlab-gitaly-ha.test;
  }
}
```

Restart NGINX for the configuration to take effect. For example:

```shell
# On Debian/Ubuntu
sudo systemctl restart nginx

# on macOS
sudo nginx -s reload
```

You could then run the tests from the `/qa` directory:

```shell
CHROME_HEADLESS=false bin/qa Test::Instance::All http://gitlab-gitaly-ha.test -- --tag gitaly_ha
```

Once you have finished testing you can stop and remove the Docker containers:

```shell
docker stop gitlab-gitaly-ha praefect postgres gitaly3 gitaly2 gitaly1
docker rm gitlab-gitaly-ha praefect postgres gitaly3 gitaly2 gitaly1
```
