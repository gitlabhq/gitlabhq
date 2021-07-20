---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Running tests that require special setup

## Jenkins spec

The [`jenkins_build_status_spec`](https://gitlab.com/gitlab-org/gitlab/-/blob/163c8a8c814db26d11e104d1cb2dcf02eb567dbe/qa/qa/specs/features/ee/browser_ui/3_create/jenkins/jenkins_build_status_spec.rb) spins up a Jenkins instance in a Docker container based on an image stored in the [GitLab-QA container registry](https://gitlab.com/gitlab-org/gitlab-qa/container_registry).
The Docker image it uses is preconfigured with some base data and plugins.
The test then configures the GitLab plugin in Jenkins with a URL of the GitLab instance that are used
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
WEBDRIVER_HEADLESS=false bin/qa Test::Instance::All http://localhost -- qa/specs/features/ee/browser_ui/3_create/jenkins/jenkins_build_status_spec.rb
```

The test automatically spins up a Docker container for Jenkins and tear down once the test completes.

However, if you need to run Jenkins manually outside of the tests, use this command:

```shell
docker run \
  --hostname localhost \
  --name jenkins-server \
  --env JENKINS_HOME=jenkins_home \
  --publish 8080:8080 \
  registry.gitlab.com/gitlab-org/gitlab-qa/jenkins-gitlab:version1
```

Jenkins is available on `http://localhost:8080`.

Admin username is `admin` and password is `password`.

It is worth noting that this is not an orchestrated test. It is [tagged with the `:orchestrated` meta](https://gitlab.com/gitlab-org/gitlab/-/blob/163c8a8c814db26d11e104d1cb2dcf02eb567dbe/qa/qa/specs/features/ee/browser_ui/3_create/jenkins/jenkins_build_status_spec.rb#L5)
only to prevent it from running in the pipelines for live environments such as Staging.

### Troubleshooting

If Jenkins Docker container exits without providing any information in the logs, try increasing the memory used by
the Docker Engine.

## Gitaly Cluster tests

The tests tagged `:gitaly_ha` are orchestrated tests that can only be run against a set of Docker containers as configured and started by [the `Test::Integration::GitalyCluster` GitLab QA scenario](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#testintegrationgitalycluster-ceeefull-image-address).

As described in the documentation about the scenario noted above, the following command runs the tests:

```shell
gitlab-qa Test::Integration::GitalyCluster EE
```

However, that removes the containers after it finishes running the tests. If you would like to do further testing, for example, if you would like to run a single test via a debugger, you can use [the `--no-tests` option](https://gitlab.com/gitlab-org/gitlab-qa#command-line-options) to make `gitlab-qa` skip running the tests, and to leave the containers running so that you can continue to use them.

```shell
gitlab-qa Test::Integration::GitalyCluster EE --no-tests
```

When all the containers are running, the output of the `docker ps` command shows which ports the GitLab container can be accessed on. For example:

```plaintext
CONTAINER ID   ...     PORTS                                    NAMES
d15d3386a0a8   ...     22/tcp, 443/tcp, 0.0.0.0:32772->80/tcp   gitlab-gitaly-cluster
```

That shows that the GitLab instance running in the `gitlab-gitaly-cluster` container can be reached via `http://localhost:32772`. However, Git operations like cloning and pushing are performed against the URL revealed via the UI as the clone URL. It uses the hostname configured for the GitLab instance, which in this case matches the Docker container name and network, `gitlab-gitaly-cluster.test`. Before you can run the tests you need to configure your computer to access the container via that address. One option is to [use Caddy server as described for running tests against GDK](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/run_qa_against_gdk.md#workarounds).

Another option is to use NGINX.

In both cases you must configure your machine to translate `gitlab-gitaly-cluster.test` into an appropriate IP address:

```shell
echo '127.0.0.1 gitlab-gitaly-cluster.test' | sudo tee -a /etc/hosts
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

Finally, configure NGINX to pass requests for `gitlab-gitaly-cluster.test` to the GitLab instance:

```plaintext
# On Debian/Ubuntu, in /etc/nginx/sites-enabled/gitlab-cluster
# On macOS, in /usr/local/etc/nginx/nginx.conf

server {
  server_name gitlab-gitaly-cluster.test;
  client_max_body_size 500m;

  location / {
    proxy_pass http://127.0.0.1:32772;
    proxy_set_header Host gitlab-gitaly-cluster.test;
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
WEBDRIVER_HEADLESS=false bin/qa Test::Instance::All http://gitlab-gitaly-cluster.test -- --tag gitaly_cluster
```

Once you have finished testing you can stop and remove the Docker containers:

```shell
docker stop gitlab-gitaly-cluster praefect postgres gitaly3 gitaly2 gitaly1
docker rm gitlab-gitaly-cluster praefect postgres gitaly3 gitaly2 gitaly1
```

## Guide to run and debug Monitor tests

### How to set up

To run the Monitor tests locally, against the GDK, please follow the preparation steps below:

1. Complete the [Prerequisites](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/auto_devops/index.md#prerequisites-for-gitlab-team-members-only), at least through step 5. Note that the monitor tests do not require permissions to work with GKE because they use [k3s as a Kubernetes cluster provider](https://github.com/rancher/k3s).
1. The test setup deploys the app in a Kubernetes cluster, using the Auto DevOps deployment strategy.
To enable Auto DevOps in GDK, follow the [associated setup](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/auto_devops/index.md#setup) instructions. If you have problems, review the [troubleshooting guide](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/auto_devops/tips_and_troubleshooting.md) or reach out to the `#gdk` channel in the internal GitLab Slack.
1. Do [secure your GitLab instance](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/auto_devops/index.md#secure-your-gitlab-instance) since it is now publicly accessible on `https://[YOUR-PORT].qa-tunnel.gitlab.info`.
1. Install the Kubernetes command line tool known as `kubectl`. Use the [official installation instructions](https://kubernetes.io/docs/tasks/tools/).

You might see NGINX issues when you run `gdk start` or `gdk restart`. In that case, run `sft login` to revalidate your credentials and regain access the QA Tunnel.

### How to run

Navigate to the folder in `/your-gdk/gitlab/qa` and issue the command:

```shell
QA_DEBUG=true WEBDRIVER_HEADLESS=false GITLAB_ADMIN_USERNAME=rootusername GITLAB_ADMIN_PASSWORD=rootpassword GITLAB_QA_ACCESS_TOKEN=your_token_here GITLAB_QA_ADMIN_ACCESS_TOKEN=your_token_here CLUSTER_API_URL=https://kubernetes.docker.internal:6443 bundle exec bin/qa Test::Instance::All https://[YOUR-PORT].qa-tunnel.gitlab.info/ -- qa/specs/features/browser_ui/8_monitor/all_monitor_core_features_spec.rb --tag kubernetes --tag orchestrated --tag requires_admin
```

The following includes more information on the command:

-`QA_DEBUG` - Set to `true` to verbosely log page object actions.
-`WEBDRIVER_HEADLESS` - When running locally, set to `false` to allow browser tests to be visible - watch your tests being run.
-`GITLAB_ADMIN_USERNAME` - Admin username to use when adding a license.
-`GITLAB_ADMIN_PASSWORD` - Admin password to use when adding a license.
-`GITLAB_QA_ACCESS_TOKEN` and `GITLAB_QA_ADMIN_ACCESS_TOKEN` - A valid personal access token with the `api` scope. This is used for API access during tests, and is used in the version that staging is currently running. The `ADMIN_ACCESS_TOKEN` is from a user with admin access. Used for API access as an admin during tests.
-`CLUSTER_API_URL` - Use the address `https://kubernetes.docker.internal:6443` . This address is used to enable the cluster to be network accessible while deploying using Auto DevOps.
-`https://[YOUR-PORT].qa-tunnel.gitlab.info/` - The address of your local GDK
-`qa/specs/features/browser_ui/8_monitor/all_monitor_core_features_spec.rb` - The path to the monitor core specs
-`--tag` - the meta-tags used to filter the specs correctly

At the moment of this writing, there are two specs which run monitor tests:

-`qa/specs/features/browser_ui/8_monitor/all_monitor_core_features_spec.rb` - has the specs of features in GitLab Free
-`qa/specs/features/ee/browser_ui/8_monitor/all_monitor_features_spec.rb` - has the specs of features for paid GitLab (Enterprise Edition)

### How to debug

The monitor tests follow this setup flow:

1. Creates a k3s cluster on your local machine.
1. Creates a project that has Auto DevOps enabled and uses an Express template (NodeJS) for the app to be deployed.
1. Associates the created cluster to the project and installs GitLab Runner, Prometheus and Ingress which are the needed components for a successful deployment.
1. Creates a CI pipeline with 2 jobs (`build` and `production`) to deploy the app on the Kubernetes cluster.
1. Goes to Operation > Metrics menu to verify data is being received and the app is being monitored successfully.

The test requires a number of components. The setup requires time to collect the metrics of a real deployment.
The complexity of the setup may lead to problems unrelated to the app. The following sections include common strategies to debug possible issues.

#### Deployment with Auto DevOps

When debugging issues in the CI or locally in the CLI, open the Kubernetes job in the pipeline.
In the job log window, click on the top right icon labeled as *"Show complete raw"* to reveal raw job logs.
You can now search through the logs for *Job log*, which matches delimited sections like this one:

```shell
------- Job log: -------
```

A Job log is a subsection within these logs, related to app deployment. We use two jobs: `build` and `production`.
You can find the root causes of deployment failures in these logs, which can compromise the entire test.
If a `build` job fails, the `production` job doesn't run, and the test fails.

The long test setup does not take screenshots of failures, which is a known [issue](https://gitlab.com/gitlab-org/quality/team-tasks/-/issues/270).
However, if the spec fails (after a successful deployment) then you should be able to find screenshots which display the feature failure.
To access them in CI, go to the main job log window, look on the left side panel's Job artifacts section, and click Browse.

#### Common issues

**Container Registry**

When enabling Auto DevOps in the GDK, you may see issues with the Container Registry, which stores
images of the app to be deployed.

You can access the Registry is available by opening an existing project. On the left hand menu,
select `Packages & Registries > Container Registries`. If the Registry is available, this page should load normally.

Also, the Registry should be running in Docker:

```shell
$ docker ps

CONTAINER ID        IMAGE                                                                              COMMAND                  CREATED             STATUS              PORTS                    NAMES
f035f339506c        registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:v2.9.1-gitlab   "/bin/sh -c 'exec /b…"   3 hours ago         Up 3 hours          0.0.0.0:5000->5000/tcp   jovial_proskuriakova
```

The `gdk status` command shows if the registry is running:

```shell
run: ./services/registry: (pid 2662) 10875s, normally down; run: log: (pid 65148) 177993s
run: ./services/tunnel_gitlab: (pid 2650) 10875s, normally down; run: log: (pid 65154) 177993s
run: ./services/tunnel_registry: (pid 2651) 10875s, normally down; run: log: (pid 65155) 177993s
```

Also, restarting Docker and then, on the Terminal, issue the command
`docker login https://[YOUR-REGISTRY-PORT].qa-tunnel.gitlab.info:443` and use
the GDK credentials to sign in. Note that the Registry port and GDK port aren't
the same. When configuring Auto DevOps in GDK, the `gdk reconfigure` command
outputs the port of the Registry:

```shell
*********************************************
Tunnel URLs

GitLab: https://[PORT].qa-tunnel.gitlab.info
Registry: https://[PORT].qa-tunnel.gitlab.info
*********************************************
```

These Tunnel URLs are used by the QA SSH Tunnel generated when enabling Auto DevOps on the GDK.

**Pod Eviction**

Pod eviction happens when a node in a Kubernetes cluster is running out of memory or disk. After many local deployments this issue can happen. The UI shows that installing Prometheus, GitLab Runner and Ingress failed. How to be sure it is an Eviction? While the test is running, open another Terminal window and debug the current Kubernetes cluster by `kubectl get pods --all-namespaces`. If you observe that Pods have *Evicted status* such as the install-runner here:

```shell
$ kubectl get pods --all-namespaces

NAMESPACE             NAME                                      READY   STATUS    RESTARTS   AGE
gitlab-managed-apps   install-ingress                           0/1     Pending   0          25s
gitlab-managed-apps   install-prometheus                        0/1     Pending   0          12s
gitlab-managed-apps   install-runner                            0/1     Evicted   0          75s
```

You can free some memory with either of the following commands: `docker prune system` or `docker prune volume`.

## Geo tests

Geo end-to-end tests can run locally against a [Geo GDK setup](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/geo.md) or on Geo spun up in Docker containers.

### Using Geo GDK

Run from the [`qa/` directory](https://gitlab.com/gitlab-org/gitlab/-/blob/f7272b77e80215c39d1ffeaed27794c220dbe03f/qa) with both GDK Geo primary and Geo secondary instances running:

```shell
WEBDRIVER_HEADLESS=false bundle exec bin/qa QA::EE::Scenario::Test::Geo --primary-address http://localhost:3001 --secondary-address http://localhost:3002 --without-setup
```

### Using Geo in Docker

You can use [GitLab-QA Orchestrator](https://gitlab.com/gitlab-org/gitlab-qa) to orchestrate two GitLab containers and configure them as a Geo setup.

Geo requires an EE license. To visit the Geo sites in your browser, you need a reverse proxy server (for example, [NGINX](https://www.nginx.com/)).

1. Export your EE license

   ```shell
   export EE_LICENSE=$(cat <path/to/your/gitlab_license>)
   ```

1. (Optional) Pull the GitLab image

   This step is optional because pulling the Docker image is part of the [`Test::Integration::Geo` orchestrated scenario](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/d8c5c40607c2be0eda58bbca1b9f534b00889a0b/lib/gitlab/qa/scenario/test/integration/geo.rb). However, it's easier to monitor the download progress if you pull the image first, and the scenario skips this step after checking that the image is up to date.

   ```shell
   # For the most recent nightly image
   docker pull gitlab/gitlab-ee:nightly

   # For a specific release
   docker pull gitlab/gitlab-ee:13.0.10-ee.0

   # For a specific image
   docker pull registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/gitlab-ee:examplesha123456789
   ```

1. Run the [`Test::Integration::Geo` orchestrated scenario](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/d8c5c40607c2be0eda58bbca1b9f534b00889a0b/lib/gitlab/qa/scenario/test/integration/geo.rb) with the `--no-teardown` option to build the GitLab containers, configure the Geo setup, and run Geo end-to-end tests. Running the tests after the Geo setup is complete is optional; the containers keep running after you stop the tests.

   ```shell
   # Using the most recent nightly image
   gitlab-qa Test::Integration::Geo EE --no-teardown

   # Using a specific GitLab release
   gitlab-qa Test::Integration::Geo EE:13.0.10-ee.0 --no-teardown

   # Using a full image address
   GITLAB_QA_ACCESS_TOKEN=your-token-here gitlab-qa Test::Integration::Geo registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/gitlab-ee:examplesha123456789 --no-teardown
    ```

   You can use the `--no-tests` option to build the containers only, and then run the [`EE::Scenario::Test::Geo` scenario](https://gitlab.com/gitlab-org/gitlab/-/blob/f7272b77e80215c39d1ffeaed27794c220dbe03f/qa/qa/ee/scenario/test/geo.rb) from your GDK to complete setup and run tests. However, there might be configuration issues if your GDK and the containers are based on different GitLab versions. With the `--no-teardown` option, GitLab-QA uses the same GitLab version for the GitLab containers and the GitLab QA container used to configure the Geo setup.

1. To visit the Geo sites in your browser, proxy requests to the hostnames used inside the containers. NGINX is used as the reverse proxy server for this example.

   _Map the hostnames to the local IP in `/etc/hosts` file on your machine:_

   ```plaintext
   127.0.0.1 gitlab-primary.geo gitlab-secondary.geo
   ```

   _Note the assigned ports:_

   ```shell
   $ docker port gitlab-primary

   80/tcp -> 0.0.0.0:32768

   $ docker port gitlab-secondary

   80/tcp -> 0.0.0.0:32769
   ```

   _Configure the reverse proxy server with the assigned ports in `nginx.conf` file (usually found in `/usr/local/etc/nginx` on a Mac):_

   ```plaintext
   server {
     server_name gitlab-primary.geo;
     location / {
       proxy_pass http://localhost:32768; # Change port to your assigned port
       proxy_set_header Host gitlab-primary.geo;
     }
   }

   server {
     server_name gitlab-secondary.geo;
     location / {
       proxy_pass http://localhost:32769; # Change port to your assigned port
       proxy_set_header Host gitlab-secondary.geo;
     }
   }
   ```

   _Start or reload the reverse proxy server:_

   ```shell
   sudo nginx
   # or
   sudo nginx -s reload
   ```

1. To run end-to-end tests from your local GDK, run the [`EE::Scenario::Test::Geo` scenario](https://gitlab.com/gitlab-org/gitlab/-/blob/f7272b77e80215c39d1ffeaed27794c220dbe03f/qa/qa/ee/scenario/test/geo.rb) from the [`gitlab/qa/` directory](https://gitlab.com/gitlab-org/gitlab/-/blob/f7272b77e80215c39d1ffeaed27794c220dbe03f/qa). Include `--without-setup` to skip the Geo configuration steps.

   ```shell
   QA_DEBUG=true GITLAB_QA_ACCESS_TOKEN=[add token here] GITLAB_QA_ADMIN_ACCESS_TOKEN=[add token here] bundle exec bin/qa QA::EE::Scenario::Test::Geo \
   --primary-address http://gitlab-primary.geo \
   --secondary-address http://gitlab-secondary.geo \
   --without-setup
   ```

   If the containers need to be configured first (for example, if you used the `--no-tests` option in the previous step), run the `QA::EE::Scenario::Test::Geo scenario` as shown below to first do the Geo configuration steps, and then run Geo end-to-end tests. Make sure that `EE_LICENSE` is (still) defined in your shell session.

   ```shell
   QA_DEBUG=true bundle exec bin/qa QA::EE::Scenario::Test::Geo \
   --primary-address http://gitlab-primary.geo \
   --primary-name gitlab-primary \
   --secondary-address http://gitlab-secondary.geo \
   --secondary-name gitlab-secondary
   ```

1. Stop and remove containers

   ```shell
   docker stop gitlab-primary gitlab-secondary
   docker rm gitlab-primary gitlab-secondary
   ```

#### Notes

- You can find the full image address from a pipeline by [following these instructions](https://about.gitlab.com/handbook/engineering/quality/guidelines/tips-and-tricks/#running-gitlab-qa-pipeline-against-a-specific-gitlab-release). You might be prompted to set the `GITLAB_QA_ACCESS_TOKEN` variable if you specify the full image address.
- You can increase the wait time for replication by setting `GEO_MAX_FILE_REPLICATION_TIME` and `GEO_MAX_DB_REPLICATION_TIME`. The default is 120 seconds.
- To save time during tests, create a Personal Access Token with API access on the Geo primary node, and pass that value in as `GITLAB_QA_ACCESS_TOKEN` and `GITLAB_QA_ADMIN_ACCESS_TOKEN`.

## LDAP Tests

Tests that are tagged with `:ldap_tls` and `:ldap_no_tls` meta are orchestrated tests where the sign-in happens via LDAP.

These tests spin up a Docker container [(`osixia/openldap`)](https://hub.docker.com/r/osixia/openldap) running an instance of [OpenLDAP](https://www.openldap.org/).
The container uses fixtures [checked into the GitLab-QA repository](https://gitlab.com/gitlab-org/gitlab-qa/-/tree/9ffb9ad3be847a9054967d792d6772a74220fb42/fixtures/ldap) to create
base data such as users and groups including the admin group. The password for [all users](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/9ffb9ad3be847a9054967d792d6772a74220fb42/fixtures/ldap/2_add_users.ldif) including [the `tanuki` user](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/9ffb9ad3be847a9054967d792d6772a74220fb42/fixtures/ldap/tanuki.ldif) is `password`.

A GitLab instance is also created in a Docker container based on our [General LDAP setup](../../../administration/auth/ldap/index.md#general-ldap-setup) documentation.

Tests that are tagged `:ldap_tls` enable TLS on GitLab using the certificate [checked into the GitLab-QA repository](https://gitlab.com/gitlab-org/gitlab-qa/-/tree/9ffb9ad3be847a9054967d792d6772a74220fb42/tls_certificates/gitlab).

The certificate was generated with OpenSSL using this command:

```shell
openssl req -x509 -newkey rsa:4096 -keyout gitlab.test.key -out gitlab.test.crt -days 3650 -nodes -subj "/C=US/ST=CA/L=San Francisco/O=GitLab/OU=Org/CN=gitlab.test"
```

The OpenLDAP container also uses its [auto-generated TLS certificates](https://github.com/osixia/docker-openldap#use-auto-generated-certificate).

### Running LDAP tests with TLS enabled

To run the LDAP tests on your local with TLS enabled, follow these steps:

1. Include the following entry in your `/etc/hosts` file:

   `127.0.0.1    gitlab.test`

   You can then run tests against GitLab in a Docker container on `https://gitlab.test`. Please note that the TLS certificate [checked into the GitLab-QA repository](https://gitlab.com/gitlab-org/gitlab-qa/-/tree/9ffb9ad3be847a9054967d792d6772a74220fb42/tls_certificates/gitlab) is configured for this domain.
1. Run the OpenLDAP container with TLS enabled. Change the path to [`gitlab-qa/fixtures/ldap`](https://gitlab.com/gitlab-org/gitlab-qa/-/tree/9ffb9ad3be847a9054967d792d6772a74220fb42/fixtures/ldap) directory to your local checkout path:

   ```shell
   docker network create test && docker run --name ldap-server --net test --hostname ldap-server.test --volume /path/to/gitlab-qa/fixtures/ldap:/container/service/slapd/assets/config/bootstrap/ldif/custom:Z --env LDAP_TLS_CRT_FILENAME="ldap-server.test.crt" --env LDAP_TLS_KEY_FILENAME="ldap-server.test.key" --env LDAP_TLS_ENFORCE="true" --env LDAP_TLS_VERIFY_CLIENT="never" osixia/openldap:latest --copy-service
   ```

1. Run the GitLab container with TLS enabled. Change the path to [`gitlab-qa/tls_certificates/gitlab`](https://gitlab.com/gitlab-org/gitlab-qa/-/tree/9ffb9ad3be847a9054967d792d6772a74220fb42/tls_certificates/gitlab) directory to your local checkout path:

   ```shell
   sudo docker run \
      --hostname gitlab.test \
      --net test \
      --publish 443:443 --publish 80:80 --publish 22:22 \
      --name gitlab \
      --volume /path/to/gitlab-qa/tls_certificates/gitlab:/etc/gitlab/ssl \
      --env GITLAB_OMNIBUS_CONFIG="gitlab_rails['ldap_enabled'] = true; gitlab_rails['ldap_servers'] = {\"main\"=>{\"label\"=>\"LDAP\", \"host\"=>\"ldap-server.test\", \"port\"=>636, \"uid\"=>\"uid\", \"bind_dn\"=>\"cn=admin,dc=example,dc=org\", \"password\"=>\"admin\", \"encryption\"=>\"simple_tls\", \"verify_certificates\"=>false, \"base\"=>\"dc=example,dc=org\", \"user_filter\"=>\"\", \"group_base\"=>\"ou=Global Groups,dc=example,dc=org\", \"admin_group\"=>\"AdminGroup\", \"external_groups\"=>\"\", \"sync_ssh_keys\"=>false}}; letsencrypt['enable'] = false; external_url 'https://gitlab.test'; gitlab_rails['ldap_sync_worker_cron'] = '* * * * *'; gitlab_rails['ldap_group_sync_worker_cron'] = '* * * * *'; " \
      gitlab/gitlab-ee:latest
   ```

1. Run an LDAP test from [`gitlab/qa`](https://gitlab.com/gitlab-org/gitlab/-/tree/d5447ebb5f99d4c72780681ddf4dc25b0738acba/qa) directory:

   ```shell
   GITLAB_LDAP_USERNAME="tanuki" GITLAB_LDAP_PASSWORD="password" QA_DEBUG=true WEBDRIVER_HEADLESS=false bin/qa Test::Instance::All https://gitlab.test qa/specs/features/browser_ui/1_manage/login/log_into_gitlab_via_ldap_spec.rb
   ```

### Running LDAP tests with TLS disabled

To run the LDAP tests on your local with TLS disabled, follow these steps:

1. Run OpenLDAP container with TLS disabled. Change the path to [`gitlab-qa/fixtures/ldap`](https://gitlab.com/gitlab-org/gitlab-qa/-/tree/9ffb9ad3be847a9054967d792d6772a74220fb42/fixtures/ldap) directory to your local checkout path:

   ```shell
   docker network create test && docker run --net test --publish 389:389 --publish 636:636 --name ldap-server --hostname ldap-server.test --volume /path/to/gitlab-qa/fixtures/ldap:/container/service/slapd/assets/config/bootstrap/ldif/custom:Z --env LDAP_TLS="false" osixia/openldap:latest --copy-service
   ```

1. Run the GitLab container:

  ```shell
  sudo docker run \
    --hostname localhost \
    --net test \
    --publish 443:443 --publish 80:80 --publish 22:22 \
    --name gitlab \
    --env GITLAB_OMNIBUS_CONFIG="gitlab_rails['ldap_enabled'] = true; gitlab_rails['ldap_servers'] = {\"main\"=>{\"label\"=>\"LDAP\", \"host\"=>\"ldap-server.test\", \"port\"=>389, \"uid\"=>\"uid\", \"bind_dn\"=>\"cn=admin,dc=example,dc=org\", \"password\"=>\"admin\", \"encryption\"=>\"plain\", \"verify_certificates\"=>false, \"base\"=>\"dc=example,dc=org\", \"user_filter\"=>\"\", \"group_base\"=>\"ou=Global Groups,dc=example,dc=org\", \"admin_group\"=>\"AdminGroup\", \"external_groups\"=>\"\", \"sync_ssh_keys\"=>false}}; gitlab_rails['ldap_sync_worker_cron'] = '* * * * *'; gitlab_rails['ldap_group_sync_worker_cron'] = '* * * * *'; " \
  gitlab/gitlab-ee:latest
  ```

1. Run an LDAP test from [`gitlab/qa`](https://gitlab.com/gitlab-org/gitlab/-/tree/d5447ebb5f99d4c72780681ddf4dc25b0738acba/qa) directory:

   ```shell
   GITLAB_LDAP_USERNAME="tanuki" GITLAB_LDAP_PASSWORD="password" QA_DEBUG=true WEBDRIVER_HEADLESS=false bin/qa Test::Instance::All http://localhost qa/specs/features/browser_ui/1_manage/login/log_into_gitlab_via_ldap_spec.rb
   ```
