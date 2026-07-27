---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Applications pour un environnement de test
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Ceci est la collection d'informations de l'équipe de support GitLab concernant les environnements de test, pour une utilisation lors du dépannage. Ces informations sont publiées ici par souci de transparence et peuvent être utiles aux utilisateurs ayant de l'expérience avec ces outils. Si vous rencontrez actuellement un problème avec GitLab, vous pouvez consulter vos [options de support](https://about.gitlab.com/support/) en premier lieu, avant de tenter d'utiliser ces informations.

> [!note]
> Cette page a été initialement rédigée pour les ingénieurs du support, c'est pourquoi certains liens ne sont disponibles qu'en interne chez GitLab.

## Docker {#docker}

Les éléments suivants ont été testés sur des conteneurs Docker s'exécutant dans le cloud. Les ingénieurs du support peuvent consulter [cette documentation](https://gitlab.com/gitlab-com/dev-resources/tree/master/dev-resources#running-docker-containers) pour savoir comment exécuter des conteneurs Docker sur `dev-resources`. Les autres configurations n'ont pas été testées, mais les contributions sont les bienvenues.

### GitLab {#gitlab}

Consultez [notre méthode d'installation officielle de Docker](../../install/docker/_index.md) pour savoir comment exécuter GitLab sur Docker.

### SAML {#saml}

#### SAML pour l'authentification {#saml-for-authentication}

Dans les exemples suivants, lors du remplacement de `<GITLAB_IP_OR_DOMAIN>` et de `<SAML_IP_OR_DOMAIN>`, il est important de faire précéder votre adresse IP ou nom de domaine du protocole utilisé (`http://` ou `https://`).

Nous pouvons utiliser l'[image Docker `test-saml-idp`](https://hub.docker.com/r/jamedjo/test-saml-idp) pour effectuer le travail à notre place :

```shell
docker run --name gitlab_saml -p 8080:8080 -p 8443:8443 \
-e SIMPLESAMLPHP_SP_ENTITY_ID=<GITLAB_IP_OR_DOMAIN> \
-e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=<GITLAB_IP_OR_DOMAIN>/users/auth/saml/callback \
-d jamedjo/test-saml-idp
```

Les éléments suivants doivent également être ajoutés dans votre `/etc/gitlab/gitlab.rb`. Consultez [notre documentation SAML](../../integration/saml.md) pour en savoir plus, ainsi que la liste des [noms d'utilisateur, mots de passe et adresses e-mail par défaut](https://hub.docker.com/r/jamedjo/test-saml-idp/#usage).

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

#### GroupSAML pour GitLab.com {#groupsaml-for-gitlabcom}

Consultez [la documentation GDK SAML](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/saml.md).

### Elasticsearch {#elasticsearch}

```shell
docker run -d --name elasticsearch \
-p 9200:9200 -p 9300:9300 \
-e "discovery.type=single-node" \
docker.elastic.co/elasticsearch/elasticsearch:5.5.1
```

Vérifiez ensuite que cela fonctionne dans le navigateur à l'adresse `curl "http://<IP_ADDRESS>:9200/_cat/health"`. Dans Elasticsearch, le nom d'utilisateur par défaut est `elastic` et le mot de passe par défaut est `changeme`.

### Kroki {#kroki}

Consultez [notre documentation Kroki](../integration/kroki.md#docker) sur l'exécution de Kroki dans Docker.

### PlantUML {#plantuml}

Consultez [notre documentation PlantUML](../integration/plantuml.md#docker) sur l'exécution de PlantUML dans Docker.

### Jira {#jira}

```shell
docker run -d -p 8081:8080 cptactionhank/atlassian-jira:latest
```

Rendez-vous ensuite à l'adresse `<IP_ADDRESS>:8081` dans le navigateur pour effectuer la configuration. Cela nécessite une licence Jira.

### Grafana {#grafana}

```shell
docker run -d --name grafana -e "GF_SECURITY_ADMIN_PASSWORD=gitlab" -p 3000:3000 grafana/grafana
```

Accédez-y à l'adresse `<IP_ADDRESS>:3000`.
