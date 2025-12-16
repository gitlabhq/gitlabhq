---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: テスト環境用アプリ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

これは、GitLabサポートチームがトラブルシューティングで使用する、テスト環境に関する情報をまとめたものです。これは透明性のためにここにリストされており、これらのツールを使用した経験のあるユーザーには役立つ場合があります。現在GitLabでイシューが発生している場合は、この情報を使用する前に、まず[サポートオプション](https://about.gitlab.com/support/)を確認してください。

{{< alert type="note" >}}

このページは当初、サポートエンジニア向けに書かれたものなので、一部のリンクはGitLab内でのみ利用可能です。

{{< /alert >}}

## Docker {#docker}

以下は、クラウドで実行されているDockerコンテナでテストされたものです。サポートエンジニアは、`dev-resources`でDockerコンテナを実行する方法について、[こちらのドキュメント](https://gitlab.com/gitlab-com/dev-resources/tree/master/dev-resources#running-docker-containers)を参照してください。他のセットアップはテストされていませんが、コントリビュートを歓迎します。

### GitLab {#gitlab}

DockerでGitLabを実行する方法については、[公式のDockerインストール方法](../../install/docker/_index.md)を参照してください。

### SAML {#saml}

#### SAML認証 {#saml-for-authentication}

以下の例では、`<GITLAB_IP_OR_DOMAIN>`および`<SAML_IP_OR_DOMAIN>`を置き換える場合、使用されているプロトコル（`http://`または`https://`）を使用して、IPまたはドメイン名を先頭に付けることが重要です。

作業を行うために、[`test-saml-idp` Dockerイメージ](https://hub.docker.com/r/jamedjo/test-saml-idp)を使用できます:

```shell
docker run --name gitlab_saml -p 8080:8080 -p 8443:8443 \
-e SIMPLESAMLPHP_SP_ENTITY_ID=<GITLAB_IP_OR_DOMAIN> \
-e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=<GITLAB_IP_OR_DOMAIN>/users/auth/saml/callback \
-d jamedjo/test-saml-idp
```

以下も`/etc/gitlab/gitlab.rb`に記述する必要があります。詳細および[デフォルトのユーザー名、パスワード、メール](https://hub.docker.com/r/jamedjo/test-saml-idp/#usage)のリストについては、[SAMLドキュメント](../../integration/saml.md)を参照してください。

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

#### GitLab.comのGroupSAML {#groupsaml-for-gitlabcom}

[GDK SAMLドキュメント](https://gitlab.com/gitlab-org/gitlab-development-kit/blob/main/doc/howto/saml.md)を参照してください。

### Elasticsearch {#elasticsearch}

```shell
docker run -d --name elasticsearch \
-p 9200:9200 -p 9300:9300 \
-e "discovery.type=single-node" \
docker.elastic.co/elasticsearch/elasticsearch:5.5.1
```

次に、ブラウザで`curl "http://<IP_ADDRESS>:9200/_cat/health"`が動作することを確認します。Elasticsearchでは、デフォルトのユーザー名は`elastic`、デフォルトのパスワードは`changeme`です。

### Kroki {#kroki}

DockerでのKrokiの実行については、[Krokiドキュメント](../integration/kroki.md#docker)を参照してください。

### PlantUML {#plantuml}

DockerでのPlantUMLの実行については、[PlantUMLドキュメント](../integration/plantuml.md#docker)を参照してください。

### Jira {#jira}

```shell
docker run -d -p 8081:8080 cptactionhank/atlassian-jira:latest
```

次に、ブラウザで`<IP_ADDRESS>:8081`に移動してセットアップします。これにはJiraライセンスが必要です。

### Grafana {#grafana}

```shell
docker run -d --name grafana -e "GF_SECURITY_ADMIN_PASSWORD=gitlab" -p 3000:3000 grafana/grafana
```

`<IP_ADDRESS>:3000`でアクセスします。
