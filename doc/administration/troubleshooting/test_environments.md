---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Apps for a testing environment **(FREE SELF)**

This is the GitLab Support Team's collection of information regarding testing environments,
for use while troubleshooting. It is listed here for transparency, and it may be useful
for users with experience with these tools. If you are currently having an issue with
GitLab, you may want to check your [support options](https://about.gitlab.com/support/)
first, before attempting to use this information.

NOTE:
This page was initially written for Support Engineers, so some of the links
are only available internally at GitLab.

## Docker

The following were tested on Docker containers running in the cloud. Support Engineers,
please see [these docs](https://gitlab.com/gitlab-com/dev-resources/tree/master/dev-resources#running-docker-containers)
on how to run Docker containers on `dev-resources`. Other setups haven't been tested,
but contributions are welcome.

### GitLab

Please see [our Docker test environment docs](../../install/digitaloceandocker.md#create-new-gitlab-container)
for how to run GitLab on Docker. When spinning this up with `docker-machine`, ensure
you change a few things:

1. Update the name of the `docker-machine` host. You can see a list of hosts
   with `docker-machine ls`.
1. Expose the necessary ports using the `-p` flag. Docker normally doesn't
   allow access to any ports it uses outside of the container, so they must be
   explicitly exposed.
1. Add any necessary `gitlab.rb` configuration to the
   `GITLAB_OMNIBUS_CONFIG` variable.

For example, when the `docker-machine` host we want to use is `do-docker`:

```shell
docker run --detach --name gitlab \
--env GITLAB_OMNIBUS_CONFIG="external_url 'http://$(docker-machine ip do-docker)'; gitlab_rails['gitlab_shell_ssh_port'] = 2222;" \
--hostname $(docker-machine ip do-docker) \
-p 80:80 -p 2222:22 \
gitlab/gitlab-ee:11.5.3-ee.0
```

### SAML

#### SAML for Authentication

We can use the [`test-saml-idp` Docker image](https://hub.docker.com/r/jamedjo/test-saml-idp)
to do the work for us:

```shell
docker run --name gitlab_saml -p 8080:8080 -p 8443:8443 \
-e SIMPLESAMLPHP_SP_ENTITY_ID=<GITLAB_IP_OR_DOMAIN> \
-e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=<GITLAB_IP_OR_DOMAIN>/users/auth/saml/callback \
-d jamedjo/test-saml-idp
```

The following will also need to go in your `/etc/gitlab/gitlab.rb`. See [our SAML docs](../../integration/saml.md)
for more, as well as the list of [default usernames, passwords, and emails](https://hub.docker.com/r/jamedjo/test-saml-idp/#usage).

```ruby
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_allow_single_sign_on'] = ['saml']
gitlab_rails['omniauth_sync_email_from_provider'] = 'saml'
gitlab_rails['omniauth_sync_profile_from_provider'] = ['saml']
gitlab_rails['omniauth_sync_profile_attributes'] = ['email']
gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'saml'
gitlab_rails['omniauth_block_auto_created_users'] = false
gitlab_rails['omniauth_auto_link_ldap_user'] = false
gitlab_rails['omniauth_auto_link_saml_user'] = true
gitlab_rails['omniauth_providers'] = [
  {
    "name" => "saml",
    "label" => "SAML",
    "args" => {
      assertion_consumer_service_url: '<GITLAB_IP_OR_DOMAIN>/users/auth/saml/callback',
      idp_cert_fingerprint: '119b9e027959cdb7c662cfd075d9e2ef384e445f',
      idp_sso_target_url: '<SAML_IP_OR_DOMAIN>:8080/simplesaml/saml2/idp/SSOService.php',
      issuer: '<GITLAB_IP_OR_DOMAIN>',
      name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
    }
  }
]
```

#### GroupSAML for GitLab.com

See [the GDK SAML documentation](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/saml.md).

### Elasticsearch

```shell
docker run -d --name elasticsearch \
-p 9200:9200 -p 9300:9300 \
-e "discovery.type=single-node" \
docker.elastic.co/elasticsearch/elasticsearch:5.5.1
```

Then confirm it works in the browser at `curl "http://<IP_ADDRESS>:9200/_cat/health"`.
Elasticsearch's default username is `elastic` and password is `changeme`.

### Kroki

See [our Kroki docs](../integration/kroki.md#docker)
on running Kroki in Docker.

### PlantUML

See [our PlantUML docs](../integration/plantuml.md#docker)
on running PlantUML in Docker.

### Jira

```shell
docker run -d -p 8081:8080 cptactionhank/atlassian-jira:latest
```

Then go to `<IP_ADDRESS>:8081` in the browser to set it up. This requires a
Jira license.

### Grafana

```shell
docker run -d --name grafana -e "GF_SECURITY_ADMIN_PASSWORD=gitlab" -p 3000:3000 grafana/grafana
```

Access it at `<IP_ADDRESS>:3000`.
