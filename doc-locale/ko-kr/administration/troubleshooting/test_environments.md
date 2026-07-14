---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 테스트 환경을 위한 앱
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

이것은 GitLab 지원 팀의 테스트 환경과 관련된 정보 모음으로, 문제 해결 시 사용할 수 있습니다. 투명성을 위해 여기에 나열되어 있으며, 이러한 도구에 경험이 있는 사용자에게 유용할 수 있습니다. 현재 GitLab 문제가 발생하는 경우, 이 정보를 사용하기 전에 먼저 [지원 옵션](https://about.gitlab.com/support/)을 확인하는 것이 좋습니다.

> [!note]
> 이 페이지는 처음에 지원 엔지니어를 위해 작성되었으므로 일부 링크는 GitLab 내부에서만 사용 가능합니다.

## Docker {#docker}

다음은 클라우드에서 실행되는 Docker 컨테이너에서 테스트되었습니다. 지원 엔지니어는 [이 문서](https://gitlab.com/gitlab-com/dev-resources/tree/master/dev-resources#running-docker-containers)를 참조하여 `dev-resources`에서 Docker 컨테이너를 실행하는 방법을 확인하세요. 다른 설정은 테스트되지 않았지만 기여는 환영합니다.

### GitLab {#gitlab}

[공식 Docker 설치 방법](../../install/docker/_index.md)을 참조하여 Docker에서 GitLab을 실행하는 방법을 확인하세요.

### SAML {#saml}

#### 인증을 위한 SAML {#saml-for-authentication}

다음 예시에서 `<GITLAB_IP_OR_DOMAIN>`과 `<SAML_IP_OR_DOMAIN>`를 바꿀 때 IP 또는 도메인 이름 앞에 프로토콜(`http://` 또는 `https://`)을 추가하는 것이 중요합니다.

[`test-saml-idp` Docker 이미지](https://hub.docker.com/r/jamedjo/test-saml-idp)를 사용하여 작업을 수행할 수 있습니다:

```shell
docker run --name gitlab_saml -p 8080:8080 -p 8443:8443 \
-e SIMPLESAMLPHP_SP_ENTITY_ID=<GITLAB_IP_OR_DOMAIN> \
-e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=<GITLAB_IP_OR_DOMAIN>/users/auth/saml/callback \
-d jamedjo/test-saml-idp
```

다음은 `/etc/gitlab/gitlab.rb`에도 포함되어야 합니다. [SAML 문서](../../integration/saml.md) 를 참조하여 자세한 내용을 확인하고 [기본 사용자 이름, 비밀번호 및 이메일](https://hub.docker.com/r/jamedjo/test-saml-idp/#usage) 목록도 확인하세요.

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

#### GitLab.com용 GroupSAML {#groupsaml-for-gitlabcom}

[GDK SAML 문서](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/saml.md)를 참조하세요.

### Elasticsearch {#elasticsearch}

```shell
docker run -d --name elasticsearch \
-p 9200:9200 -p 9300:9300 \
-e "discovery.type=single-node" \
docker.elastic.co/elasticsearch/elasticsearch:5.5.1
```

브라우저에서 `curl "http://<IP_ADDRESS>:9200/_cat/health"`을 통해 작동하는지 확인하세요. Elasticsearch에서 기본 사용자 이름은 `elastic`이고 기본 비밀번호는 `changeme`입니다.

### Kroki {#kroki}

[Kroki 문서](../integration/kroki.md#docker)에서 Docker에서 Kroki를 실행하는 방법을 확인하세요.

### PlantUML {#plantuml}

[PlantUML 문서](../integration/plantuml.md#docker)에서 Docker에서 PlantUML을 실행하는 방법을 확인하세요.

### Jira {#jira}

```shell
docker run -d -p 8081:8080 cptactionhank/atlassian-jira:latest
```

브라우저에서 `<IP_ADDRESS>:8081`로 이동하여 설정하세요. 이는 Jira 라이선스가 필요합니다.

### Grafana {#grafana}

```shell
docker run -d --name grafana -e "GF_SECURITY_ADMIN_PASSWORD=gitlab" -p 3000:3000 grafana/grafana
```

`<IP_ADDRESS>:3000`에서 접근할 수 있습니다.
