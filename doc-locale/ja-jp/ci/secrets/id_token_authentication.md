---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ID トークンを使用した OpenID Connect（OIDC）認証
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.7 [で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356986)。

{{< /history >}}

GitLab CI/CD の[IDトークン](../yaml/_index.md#id_tokens)を使用して、サードパーティサービスで認証できます。

## IDトークン

[IDトークン](../yaml/_index.md#id_tokens)は、GitLab CI/CDジョブに追加できるJSON Web Token（JWT）です。これらは、サードパーティサービスとの OIDC 認証に使用でき、[`secrets`](../yaml/_index.md#secrets)キーワードによって HashiCorp Vault での認証に使用されます。

IDトークンは`.gitlab-ci.yml`でConfigureします。次に例を示します。

```yaml
job_with_id_tokens:
  id_tokens:
    FIRST_ID_TOKEN:
      aud: https://first.service.com
    SECOND_ID_TOKEN:
      aud: https://second.service.com
  script:
    - first-service-authentication-script.sh $FIRST_ID_TOKEN
    - second-service-authentication-script.sh $SECOND_ID_TOKEN
```

この例では、2つのトークンは異なる`aud`クレームを持っています。サードパーティサービスは、バインドされたオーディエンスに一致する`aud`クレームを持たないトークンを拒否するようにConfigureできます。この機能を使用して、トークンが認証できるサービスの数を減らします。これにより、トークンが侵害された場合の重大度が軽減されます。

### トークンのペイロード

各IDトークンには、次の標準クレームが含まれています。

| フィールド                                                              | 説明 |
|--------------------------------------------------------------------|-------------|
| [`iss`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.1) | トークンの発行者。これはGitLabインスタンスのドメイン（「issuer」クレーム）です。 |
| [`sub`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.2) | トークンのサブジェクト（「subject」クレーム）。デフォルトは`project_path:{group}/{project}:ref_type:{type}:ref:{branch_name}`です。[プロジェクトAPI](../../api/projects.md#edit-a-project)でプロジェクトに対してConfigureできます。 |
| [`aud`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.3) | トークンの対象オーディエンス（「audience」クレーム）。[IDトークン](../yaml/_index.md#id_tokens)設定で指定されます。デフォルトではGitLabインスタンスのドメイン。 |
| [`exp`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.4) | 有効期限（「expiration time」クレーム）。 |
| [`nbf`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.5) | トークンが有効になる時刻（「not before」クレーム）。 |
| [`iat`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.6) | JWTが発行された時刻（「issued at」クレーム）。 |
| [`jti`](https://www.rfc-editor.org/rfc/rfc7519.html#section-4.1.7) | トークンの固有識別子（「JWT ID」クレーム）。 |

トークンには、GitLabによって提供されるカスタムクレームも含まれています。

| フィールド                   | 時期                         | 説明                                                                                                                                                                                                                                                                                                      |
|-------------------------|------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `namespace_id`          | 常時                       | IDでグループまたはユーザーレベルのネームスペースにスコープを設定するために使用します。                                                                                                                                                                                                                                                        |
| `namespace_path`        | 常時                       | パスでグループまたはユーザーレベルのネームスペースにスコープを設定するために使用します。                                                                                                                                                                                                                                                      |
| `project_id`            | 常時                       | IDでプロジェクトにスコープを設定するために使用します。                                                                                                                                                                                                                                                                              |
| `project_path`          | 常時                       | パスでプロジェクトにスコープを設定するために使用します。                                                                                                                                                                                                                                                                            |
| `user_id`               | 常時                       | ジョブを実行しているユーザーのID。                                                                                                                                                                                                                                                                                |
| `user_login`            | 常時                       | ジョブを実行しているユーザーのユーザー名。                                                                                                                                                                                                                                                                          |
| `user_email`            | 常時                       | ジョブを実行しているユーザーのメール。                                                                                                                                                                                                                                                                             |
| `user_access_level`     | 常時                       | ジョブを実行しているユーザーのアクセスレベル。GitLab 16.9[で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/432052)。                                                                                                                                                                                                                                                                            |
| `user_identities`       | ユーザー設定      | ユーザーの外部IDのリスト（GitLab 16.0[で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/387537)）。                                                                                                                                                                                      |
| `pipeline_id`           | 常時                       | パイプラインのID。                                                                                                                                                                                                                                                                                              |
| `pipeline_source`       | 常時                       | [パイプラインソース](../jobs/job_rules.md#common-if-clauses-with-predefined-variables)。                                                                                                                                                                                                                                           |
| `job_id`                | 常時                       | ジョブのID。                                                                                                                                                                                                                                                                                                   |
| `ref`                   | 常時                       | ジョブのGit refs。                                                                                                                                                                                                                                                                                             |
| `ref_type`              | 常時                       | Git refタイプ、`branch`または`tag`。                                                                                                                                                                                                                                                                          |
| `ref_path`              | 常時                       | ジョブの完全修飾refs。例：`refs/heads/main`。GitLab 16.0[で導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119075)。                                                                                                                                                      |
| `ref_protected`         | 常時                       | Git refが保護されている場合は`true`、それ以外の場合は`false`。                                                                                                                                                                                                                                                           |
| `groups_direct`         | ユーザーは0〜200のグループの直接メンバーです | ユーザーの直接メンバーシップグループのパス。ユーザーが200を超えるグループの直接メンバーである場合、省略されます。（GitLab 16.11[で導入](https://gitlab.com/gitlab-org/gitlab/-/issues/435848)され、GitLab 17.3の`ci_jwt_groups_direct` [機能フラグ](../../administration/feature_flags.md)の背後に置かれました。 |
| `environment`           | ジョブは環境を指定します | このジョブのデプロイ先の環境。                                                                                                                                                                                             |
| `environment_protected` | ジョブは環境を指定します | デプロイされた環境が保護されている場合は`true`、それ以外の場合は`false`。                                                                                                                                                              |
| `deployment_tier`       | ジョブは環境を指定します | ジョブが指定する環境の[デプロイメントプラン](../environments/_index.md#deployment-tier-of-environments)。GitLab 15.2[で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/363590)。                                                                                                             |
| `environment_action`    | ジョブは環境を指定します | ジョブで指定された[環境アクション（`environment:action`）](../environments/_index.md)。（GitLab 16.5[で導入](https://gitlab.com/gitlab-org/gitlab/-/)）                                                                                                                                               |
| `runner_id`             | 常時                       | ジョブを実行しているRunnerのID。GitLab 16.0[で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/404722)。                                                                                                                                                                                           |
| `runner_environment`    | 常時                       | ジョブで使用されるRunnerのタイプ。`gitlab-hosted`または`self-hosted`のいずれかになります。GitLab 16.0[で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/404722)。                                                                                                                                           |
| `sha`                   | 常時                       | ジョブのコミットSHA。GitLab 16.0[で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/404722)。                                                                                                                                                                                                   |
| `ci_config_ref_uri`     | 常時                       | トップレベルのパイプライン定義へのrefsパス（例：`gitlab.example.com/my-group/my-project//.gitlab-ci.yml@refs/heads/main`）。GitLab 16.2[で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/404722)。パイプライン定義が同じプロジェクトにない場合、このクレームは`null`です。 |
| `ci_config_sha`         | 常時                       | `ci_config_ref_uri`のGitコミットSHA。GitLab 16.2[で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/404722)。パイプライン定義が同じプロジェクトにない場合、このクレームは`null`です。                                                                                               |
| `project_visibility`    | 常時                       | パイプラインが実行されているプロジェクトの[表示レベル](../../user/public_access.md)。`internal`、`private`、または`public`を指定できます。GitLab 16.3[で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/418810)。                                                                                        |

```json
{
  "namespace_id": "72",
  "namespace_path": "my-group",
  "project_id": "20",
  "project_path": "my-group/my-project",
  "user_id": "1",
  "user_login": "sample-user",
  "user_email": "sample-user@example.com",
  "user_identities": [
      {"provider": "github", "extern_uid": "2435223452345"},
      {"provider": "bitbucket", "extern_uid": "john.smith"}
  ],
  "pipeline_id": "574",
  "pipeline_source": "push",
  "job_id": "302",
  "ref": "feature-branch-1",
  "ref_type": "branch",
  "ref_path": "refs/heads/feature-branch-1",
  "ref_protected": "false",
  "groups_direct": ["mygroup/mysubgroup", "myothergroup/myothersubgroup"],
  "environment": "test-environment2",
  "environment_protected": "false",
  "deployment_tier": "testing",
  "environment_action": "start",
  "runner_id": 1,
  "runner_environment": "self-hosted",
  "sha": "714a629c0b401fdce83e847fc9589983fc6f46bc",
  "project_visibility": "public",
  "ci_config_ref_uri": "gitlab.example.com/my-group/my-project//.gitlab-ci.yml@refs/heads/main",
  "ci_config_sha": "714a629c0b401fdce83e847fc9589983fc6f46bc",
  "jti": "235b3a54-b797-45c7-ae9a-f72d7bc6ef5b",
  "iss": "https://gitlab.example.com",
  "iat": 1681395193,
  "nbf": 1681395188,
  "exp": 1681398793,
  "sub": "project_path:my-group/my-project:ref_type:branch:ref:feature-branch-1",
  "aud": "https://vault.example.com"
}
```

IDトークンはRS256を使用してエンコードされ、専用の秘密キーで署名されます。トークンの有効期限は、ジョブのタイムアウトが指定されている場合はジョブのタイムアウトに設定され、タイムアウトが指定されていない場合は5分に設定されます。

## サードパーティサービスでのIDトークン認証

IDトークンを使用して、サードパーティサービスでOIDC認証を行うことができます。次に例を示します。

- [HashiCorp Vault](hashicorp_vault.md)
- [Google Cloud Secret Manager](gcp_secret_manager.md#configure-gitlab-cicd-to-use-gcp-secret-manager-secrets)
- [Azure Key Vault](azure_key_vault.md#use-azure-key-vault-secrets-in-a-cicd-job)

## トラブルシューティング

### `400: missing token`状態コード

このエラーは、IDトークンに必要な基本コンポーネントの1つ以上が欠落しているか、予期したとおりにConfigureされていないことを示しています。

問題を特定するには、管理者は失敗した特定の方法について、インスタンスの`exceptions_json.log`で詳細を確認できます。

### `GitLab::Ci::Jwt::NoSigningKeyError`

`exceptions_json.log`ファイル内のこのエラーは、署名キーがデータベースから欠落しており、トークンを生成できなかったことが原因である可能性があります。これがイシューであることを検証するには、インスタンスのPostgreSQLターミナルで次のクエリを実行します。

```sql
SELECT encrypted_ci_jwt_signing_key FROM application_settings;
```

返された値が空の場合は、次のRailsスニペットを使用して新しいキーを生成し、内部的に置き換えます。

```ruby
  key = OpenSSL::PKey::RSA.new(2048).to_pem

  ApplicationSetting.find_each do |application_setting|
    application_setting.update(ci_jwt_signing_key: key)
  end
```
