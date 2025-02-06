---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Apps for a testing environment
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

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
see [these docs](https://gitlab.com/gitlab-com/dev-resources/tree/master/dev-resources#running-docker-containers)
on how to run Docker containers on `dev-resources`. Other setups haven't been tested,
but contributions are welcome.

### GitLab

See [our official Docker installation method](../../install/docker/_index.md)
for how to run GitLab on Docker.

### SAML

#### SAML for Authentication

In the following examples, when replacing `<GITLAB_IP_OR_DOMAIN>` and `<SAML_IP_OR_DOMAIN>` it is important to prepend your IP or domain name, with the protocol (`http://` or `https://`) being used.

We can use the [`test-saml-idp` Docker image](https://hub.docker.com/r/jamedjo/test-saml-idp)
to do the work for us:

```shell
docker run --name gitlab_saml -p 8080:8080 -p 8443:8443 \
-e SIMPLESAMLPHP_SP_ENTITY_ID=<GITLAB_IP_OR_DOMAIN> \
-e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=<GITLAB_IP_OR_DOMAIN>/users/auth/saml/callback \
-d jamedjo/test-saml-idp
```

The following must also go in your `/etc/gitlab/gitlab.rb`. See [our SAML docs](../../integration/saml.md)
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
In Elasticsearch, the default username is `elastic`, and the default password is `changeme`.

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
