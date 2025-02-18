---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Running tests that require special setup
---

## Jenkins tests

The [`jenkins_build_status_spec`](https://gitlab.com/gitlab-org/gitlab/-/blob/24a86debf49f3aed6f2ecfd6e8f9233b3a214181/qa/qa/specs/features/browser_ui/3_create/jenkins/jenkins_build_status_spec.rb)
spins up a Jenkins instance in a Docker container with the Jenkins GitLab plugin pre-installed. Due to a license restriction we are unable to distribute this image.
To build a QA compatible image, visit the [third party images project](https://gitlab.com/gitlab-org/quality/third-party-docker-public), where third party Dockerfiles can be found.
The project also has instructions for forking and building the images automatically in CI.

Some extra environment variables for the location of the forked repository are also needed.

- `QA_THIRD_PARTY_DOCKER_REGISTRY` (the container registry where the repository/images are hosted, for example `registry.gitlab.com`)
- `QA_THIRD_PARTY_DOCKER_REPOSITORY` (the base repository path where the images are hosted, for example `registry.gitlab.com/<project path>`)
- `QA_THIRD_PARTY_DOCKER_USER` (a username that has access to the container registry for this repository)
- `QA_THIRD_PARTY_DOCKER_PASSWORD` (a password/token for the username to authenticate with)

The test configures the GitLab plugin in Jenkins with a URL of the GitLab instance that are used
to run the tests. Bi-directional networking is needed between a GitLab instance and Jenkins, so GitLab can also be started in a Docker container.

To start a Docker container for GitLab based on the nightly image:

```shell
docker run \
  --publish 80:80 \
  --name gitlab \
  --hostname localhost \
  --network test
  gitlab/gitlab-ee:nightly
```

To run the tests from the `/qa` directory:

```shell
export QA_THIRD_PARTY_DOCKER_REGISTRY=<registry>
export QA_THIRD_PARTY_DOCKER_REPOSITORY=<repository>
export QA_THIRD_PARTY_DOCKER_USER=<user with registry access>
export QA_THIRD_PARTY_DOCKER_PASSWORD=<password for user>
export WEBDRIVER_HEADLESS=0
bin/qa Test::Instance::All http://localhost -- qa/specs/features/ee/browser_ui/3_create/jenkins/jenkins_build_status_spec.rb
```

The test automatically spins up a Docker container for Jenkins and tear down once the test completes.

If you need to run Jenkins manually outside of the tests, refer to the README for the
[third party images project](https://gitlab.com/gitlab-org/quality/third-party-docker-public/-/blob/main/jenkins/README.md)

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

## Tests that require a runner

To execute tests that use a runner without errors, while creating the GitLab Docker instance the `--hostname` parameter in the Docker `run` command should be given a specific interface IP address or a non-loopback hostname accessible from the runner container. Having `localhost` (or `127.0.0.1`) as the GitLab hostname won't work (unless the GitLab Runner is created with the Docker network as `host`)

Examples of tests which require a runner:

- `qa/qa/specs/features/ee/browser_ui/13_secure/create_merge_request_with_secure_spec.rb`
- `qa/qa/specs/features/browser_ui/4_verify/runner/register_runner_spec.rb`

Example:

```shell
docker run \
  --detach \
  --hostname interface_ip_address \
  --publish 80:80 \
  --name gitlab \
  --restart always \
  --volume ~/ee_volume/config:/etc/gitlab \
  --volume ~/ee_volume/logs:/var/log/gitlab \
  --volume ~/ee_volume/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:latest
```

Where `interface_ip_address` is your local network's interface IP, which you can find with the `ifconfig` command.
The same would apply to GDK running with the instance address as `localhost` too.

## Geo tests

Geo end-to-end tests can run locally against a [Geo GDK setup](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/geo.md) or on Geo spun up in Docker containers.

### Using Geo GDK

Run from the [`qa/` directory](https://gitlab.com/gitlab-org/gitlab/-/blob/f7272b77e80215c39d1ffeaed27794c220dbe03f/qa) with both GDK Geo primary and Geo secondary instances running:

```shell
WEBDRIVER_HEADLESS=false bundle exec bin/qa QA::EE::Scenario::Test::Geo --primary-address http://localhost:3001 --secondary-address http://localhost:3002 --without-setup
```

### Using Geo in Docker

You can use [GitLab-QA Orchestrator](https://gitlab.com/gitlab-org/gitlab-qa) to orchestrate two GitLab containers and configure them as a Geo setup.

Geo requires an EE license. To visit the Geo sites in your browser, you need a reverse proxy server (for example, [NGINX](https://www.f5.com/go/product/welcome-to-nginx)).

1. Export your EE license

   ```shell
   export EE_LICENSE=$(cat <path/to/your/gitlab_license>)
   ```

1. Optional. Pull the GitLab image

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
   QA_LOG_LEVEL=debug GITLAB_QA_ACCESS_TOKEN=[add token here] GITLAB_QA_ADMIN_ACCESS_TOKEN=[add token here] bundle exec bin/qa QA::EE::Scenario::Test::Geo \
   --primary-address http://gitlab-primary.geo \
   --secondary-address http://gitlab-secondary.geo \
   --without-setup
   ```

   If the containers need to be configured first (for example, if you used the `--no-tests` option in the previous step), run the `QA::EE::Scenario::Test::Geo scenario` as shown below to first do the Geo configuration steps, and then run Geo end-to-end tests. Make sure that `EE_LICENSE` is (still) defined in your shell session.

   ```shell
   QA_LOG_LEVEL=debug bundle exec bin/qa QA::EE::Scenario::Test::Geo \
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

- You can find the full image address from a pipeline by [following these instructions](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/tips-and-tricks/#running-gitlab-qa-pipeline-against-a-specific-gitlab-release). You might be prompted to set the `GITLAB_QA_ACCESS_TOKEN` variable if you specify the full image address.
- You can increase the wait time for replication by setting `GEO_MAX_FILE_REPLICATION_TIME` and `GEO_MAX_DB_REPLICATION_TIME`. The default is 120 seconds.
- To save time during tests, create a personal access token with API access on the Geo primary node, and pass that value in as `GITLAB_QA_ACCESS_TOKEN` and `GITLAB_QA_ADMIN_ACCESS_TOKEN`.

## Group SAML Tests

Tests that are tagged with `:group_saml` meta are orchestrated tests where the user accesses a group via SAML SSO.

These tests depend on a SAML IDP Docker container ([jamedjo/test-SAML-idp](https://hub.docker.com/r/jamedjo/test-saml-idp)). The tests spin up the container themselves.

To run these tests on your computer against the GDK:

1. Add these settings to your `gitlab.yml` file:

   ```yaml
   omniauth:
     enabled: true
     providers:
       - { name: 'group_saml' }
   ```

1. Run a group SAML test from [`gitlab/qa`](https://gitlab.com/gitlab-org/gitlab/-/tree/d5447ebb5f99d4c72780681ddf4dc25b0738acba/qa) directory:

   ```shell
   QA_DEBUG=true CHROME_HEADLESS=false bundle exec bin/qa Test::Instance::All http://localhost:3000 qa/specs/features/ee/browser_ui/1_manage/group/group_saml_enforced_sso_spec.rb -- --tag orchestrated
   ```

For instructions on how to run these tests using the `gitlab-qa` gem, refer to [the GitLab QA documentation](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#testintegrationgroupsaml-eefull-image-address).

## Instance SAML Tests

Tests that are tagged with `:instance_saml` meta are orchestrated tests where the instance level sign-in happens using SAML SSO.

These tests require a SAML IDP Docker container ([jamedjo/test-SAML-idp](https://hub.docker.com/r/jamedjo/test-saml-idp)) to be configured and running.

To run these tests on your computer against the GDK:

1. Add these settings to your `gitlab.yml` file:

   ```yaml
   omniauth:
     enabled: true
     allow_single_sign_on: ["saml"]
     block_auto_created_users: false
     auto_link_saml_user: true
     providers:
       - { name: 'saml',
         args: {
         assertion_consumer_service_url: 'http://gdk.test:3000/users/auth/saml/callback',
         idp_cert_fingerprint: '11:9b:9e:02:79:59:cd:b7:c6:62:cf:d0:75:d9:e2:ef:38:4e:44:5f',
         idp_sso_target_url: 'https://gdk.test:8443/simplesaml/saml2/idp/SSOService.php',
         issuer: 'http://gdk.test:3000',
         name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
       } }
   ```

1. Start the SAML IDP Docker container:

   ```shell
   docker run --name=group_saml_qa_idp -p 8080:8080 -p 8443:8443 \
   -e SIMPLESAMLPHP_SP_ENTITY_ID=http://localhost:3000 \
   -e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=http://localhost:3000/users/auth/saml/callback \
   -d jamedjo/test-saml-idp
   ```

1. Run the test from [`gitlab/qa`](https://gitlab.com/gitlab-org/gitlab/-/tree/d5447ebb5f99d4c72780681ddf4dc25b0738acba/qa) directory:

   ```shell
   QA_DEBUG=true CHROME_HEADLESS=false bundle exec bin/qa Test::Instance::All http://localhost:3000 qa/specs/features/browser_ui/1_manage/login/login_via_instance_wide_saml_sso_spec.rb -- --tag orchestrated
   ```

For instructions on how to run these tests using the `gitlab-qa` gem, refer to [the GitLab QA documentation](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#testintegrationinstancesaml-ceeefull-image-address).

## LDAP Tests

Tests that are tagged with `:ldap_tls` and `:ldap_no_tls` meta are orchestrated tests where the sign-in happens via LDAP.

These tests spin up a Docker container [(`osixia/openldap`)](https://hub.docker.com/r/osixia/openldap) running an instance of [OpenLDAP](https://www.openldap.org/).
The container uses fixtures [checked into the GitLab-QA repository](https://gitlab.com/gitlab-org/gitlab-qa/-/tree/9ffb9ad3be847a9054967d792d6772a74220fb42/fixtures/ldap) to create
base data such as users and groups including the administrator group. The password for [all users](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/9ffb9ad3be847a9054967d792d6772a74220fb42/fixtures/ldap/2_add_users.ldif) including [the `tanuki` user](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/9ffb9ad3be847a9054967d792d6772a74220fb42/fixtures/ldap/tanuki.ldif) is `password`.

A GitLab instance is also created in a Docker container based on our [LDAP setup](../../../../administration/auth/ldap/_index.md) documentation.

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

   You can then run tests against GitLab in a Docker container on `https://gitlab.test`. The TLS certificate [checked into the GitLab-QA repository](https://gitlab.com/gitlab-org/gitlab-qa/-/tree/9ffb9ad3be847a9054967d792d6772a74220fb42/tls_certificates/gitlab) is configured for this domain.
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
   GITLAB_LDAP_USERNAME="tanuki" GITLAB_LDAP_PASSWORD="password" QA_LOG_LEVEL=debug WEBDRIVER_HEADLESS=false bin/qa Test::Instance::All https://gitlab.test qa/specs/features/browser_ui/1_manage/login/log_into_gitlab_via_ldap_spec.rb
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
   GITLAB_LDAP_USERNAME="tanuki" GITLAB_LDAP_PASSWORD="password" QA_LOG_LEVEL=debug WEBDRIVER_HEADLESS=false bin/qa Test::Instance::All http://localhost qa/specs/features/browser_ui/1_manage/login/log_into_gitlab_via_ldap_spec.rb
   ```

## SMTP tests

Tests that are tagged with `:smtp` meta tag are orchestrated tests that ensure email notifications are received by a user.

These tests require a GitLab instance with SMTP enabled and integrated with an SMTP server, [MailHog](https://github.com/mailhog/MailHog).

To run these tests locally against the GDK:

1. Add these settings to your `gitlab.yml` file:

   ```yaml
   smtp:
     enabled: true
     address: "mailhog.test"
     port: 1025
   ```

1. Start MailHog in a Docker container:

   ```shell
   docker network create test && docker run \
     --network test \
     --hostname mailhog.test \
     --name mailhog \
     --publish 1025:1025 \
     --publish 8025:8025 \
     mailhog/mailhog:v1.0.0
   ```

1. Run the test from [`gitlab/qa`](https://gitlab.com/gitlab-org/gitlab/-/tree/d5447ebb5f99d4c72780681ddf4dc25b0738acba/qa) directory:

   ```shell
   QA_LOG_LEVEL=debug WEBDRIVER_HEADLESS=false bin/qa Test::Instance::All http://localhost:3000 qa/specs/features/browser_ui/2_plan/email/trigger_email_notification_spec.rb -- --tag orchestrated
   ```

For instructions on how to run these tests using the `gitlab-qa` gem, refer to [the GitLab QA documentation](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md#testintegrationsmtp-ceeefull-image-address).

## Targeting canary vs non-canary components in live environments

Use the `QA_COOKIES` ENV variable to have the entire test target a `canary` (`staging-canary` or `canary`) or `non-canary` (`staging` or `production`) environment.

Locally, that would mean prepending the ENV variable to your call to bin/qa. To target the `canary` version of that environment:

```shell
QA_COOKIES="gitlab_canary=true" WEBDRIVER_HEADLESS=false bin/qa Test::Instance::Staging <YOUR SPECIFIC TAGS OR TESTS>
```

Alternatively, you may set the cookie to `false` to ensure the `non-canary` version is targeted.

You can also export the cookie for your current session to avoid prepending it each time:

```shell
export QA_COOKIES="gitlab_canary=true"
```

### Updating the cookie within a running spec

Within a specific test, you can target either the `canary` or `non-canary` nodes within live environments, such as `staging` and `production`.

For example, to switch back and forth between the two environments, you could utilize the `target_canary` method:

```ruby
it 'tests toggling between canary and non-canary nodes' do
  Runtime::Browser.visit(:gitlab, Page::Main::Login)

  # After starting the browser session, use the target_canary method ...

  Runtime::Browser::Session.target_canary(true)
  Flow::Login.sign_in

  verify_session_on_canary(true)

  Runtime::Browser::Session.target_canary(false)

  # Refresh the page ...

  verify_session_on_canary(false)

  # Log out and clean up ...
end

def verify_session_on_canary(enable_canary)
  Page::Main::Menu.perform do |menu|
    aggregate_failures 'testing session log in' do
      expect(menu.canary?).to be(enable_canary)
    end
  end
end
```

You can verify whether GitLab is appropriately redirecting your session to the `canary` or `non-canary` nodes with the `menu.canary?` method.

The above spec is verbose, written specifically this way to ensure the idea behind the implementation is clear. We recommend following the practices detailed within our [Beginner's guide to writing end-to-end tests](../beginners_guide/_index.md).

## Tests for GitLab as OpenID Connect (OIDC) and OAuth provider

To run the [`login_via_oauth_and_oidc_with_gitlab_as_idp_spec`](https://gitlab.com/gitlab-org/gitlab/-/blob/2e2c8bcfa4f68cd39041806af531038ce4d2ab04/qa/qa/specs/features/browser_ui/1_manage/login/login_via_oauth_and_oidc_with_gitlab_as_idp_spec.rb) on your local machine:

1. Make sure your GDK is set to run on a non-localhost address such as `gdk.test:3000`.
1. Configure a [loopback interface to 172.16.123.1](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/6fe7b46403229f12ab6d903f99b024e0b82cb94a/doc/howto/local_network.md#create-loopback-interface).
1. Make sure Docker Desktop or Rancher Desktop is running.
1. Add an entry to your `/etc/hosts` file for `gitlab-oidc-consumer.bridge` and `gitlab-oauth-consumer.bridge` pointing to `127.0.0.1`.
1. From the `qa` directory, run the following command. To set the GitLab image you want to use, update the `RELEASE` variable. For example, to use the latest EE image, set `RELEASE` to `gitlab/gitlab-ee:latest`:

   ```shell
   bundle install

   RELEASE_REGISTRY_URL='registry.gitlab.com' RELEASE_REGISTRY_USERNAME='<your_gitlab_username>' RELEASE_REGISTRY_PASSWORD='<your_gitlab_personal_access_token>' RELEASE='registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/gitlab-ee:c0ae46db6b31ea231b2de88961cd687acf634179' GITLAB_QA_ADMIN_ACCESS_TOKEN="<your_gdk_admin_personal_access_token>" QA_DEBUG=true CHROME_HEADLESS=false bundle exec bin/qa Test::Instance::All http://gdk.test:3000 qa/specs/features/browser_ui/1_manage/login/login_via_oauth_and_oidc_with_gitlab_as_idp_spec.rb
   ```

## Product Analytics tests

Product Analytics e2e tests require Product Analytics services running and connected to your GDK.

In order to run Product Analytics services, devkit can be used. Instructions to set it up and connect to your GDK can be found in the [devkit project's `README.md`](https://gitlab.com/gitlab-org/analytics-section/product-analytics/devkit).

Additionally, the following setup is required on the GDK:

- Set environment variables for product analytics configuration. The following variables are default for running devkit locally.

  ```shell
  export PA_CONFIGURATOR_URL=http://test:test@localhost:4567
  export PA_COLLECTOR_HOST=http://localhost:9091
  export PA_CUBE_API_URL=http://localhost:4000
  export PA_CUBE_API_KEY=thisisnotarealkey43ff15165ce01e4ff47d75092e3b25b2c0b20dc27f6cd5a8aed7b7bd855df88c9e0748d7afd37adda6d981c16177b086acf496bbdc62dbb
  ```

- Ultimate license applied.
  - [How to request the license](https://handbook.gitlab.com/handbook/developer-onboarding/#working-on-gitlab-ee-developer-licenses).
  - [How to activate GitLab EE with a license file or key](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/license_file.md#activate-gitlab-ee-with-a-license-file-or-key).
- Simulate SaaS enabled. Instructions can be [found here](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/ee_features.md#simulate-a-saas-instance).

Once Product Analytics services are running and are connected to your GDK, the tests can be executed with:

```shell
bundle exec rspec qa/specs/features/ee/browser_ui/8_monitor/product_analytics/onboarding_spec.rb
```

## Tests that require a global server hook

The [`tag_revision_trigger_prereceive_hook_spec`](https://gitlab.com/gitlab-org/gitlab/-/blob/c3342dac0c6c8e9e11ec049b910eac832600b0bf/qa/qa/specs/features/api/3_create/repository/tag_revision_trigger_prereceive_hook_spec.rb) requires a global server hook to be pre-configured in the target test environment. When running this tests against a local GDK, the server hook will need to be configured with:

```shell
# From the gdk directory
mkdir -p gitaly-custom-hooks/pre-receive.d
cp gitlab/qa/gdk/pre-receive gitaly-custom-hooks/pre-receive.d
chmod +x gitaly-custom-hooks/pre-receive.d/pre-receive
```

More information on global server hooks can be found in the [server hooks documentation](../../../../administration/server_hooks.md#create-the-global-server-hook)
