---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Google CloudインテグレーションAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: 実験的機能

{{< /details >}}

このAPIを使用して、Google Cloudインテグレーションと連携します。詳細については、[GitLabとGoogle Cloudインテグレーション](../ci/gitlab_google_cloud_integration/_index.md)を参照してください。

## プロジェクトレベルのGoogle Cloudインテグレーションスクリプト {#project-level-google-cloud-integration-scripts}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141870)されました。これは[実験的機能](../policy/development_stages_support.md)です。

{{< /history >}}

### ワークロードアイデンティティフェデレーション作成スクリプト {#workload-identity-federation-creation-script}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141870)されました。

{{< /history >}}

プロジェクトのメンテナーまたはオーナーロールを持つユーザーは、次のエンドポイントを使用して、Google Cloudでワークロードアイデンティティフェデレーションを作成し設定するShellスクリプトをクエリすることができます:

```plaintext
GET /projects/:id/google_cloud/setup/wlif.sh
```

サポートされている属性は以下のとおりです: 

| 属性                                         | 型             | 必須 | 説明                                                                                                      |
|---------------------------------------------------|------------------|----------|------------------------------------------------------------------------------------------------------------------|
| `id`                                              | 整数          | はい      | プロジェクトのID。                                                                                                |
| `google_cloud_project_id`                         | 文字列           | はい      | ワークロードアイデンティティフェデレーション用のGoogle CloudプロジェクトID。                                                    |
| `google_cloud_workload_identity_pool_id`          | 文字列           | いいえ       | 作成するGoogle Cloud Workload IdentityプールID。`gitlab-wlif`がデフォルトです。                              |
| `google_cloud_workload_identity_pool_display_name`| 文字列           | いいえ       | 作成するGoogle Cloud Workload Identityプールの表示名。`WLIF for GitLab integration`がデフォルトです。   |
| `google_cloud_workload_identity_pool_provider_id` | 文字列           | いいえ       | 作成するGoogle Cloud Workload IdentityプールプロバイダのID。`gitlab-wlif-oidc-provider`がデフォルトです。       |
| `google_cloud_workload_identity_pool_provider_display_name`| 文字列  | いいえ       | 作成するGoogle Cloud Workload Identityプールプロバイダの表示名。`GitLab OIDC provider`がデフォルトです。 |

リクエスト例: 

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<your_project_id>/google_cloud/setup/wlif.sh"
```

### Google Cloudインテグレーションのセットアップスクリプト {#script-to-set-up-a-google-cloud-integration}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144787)されました。

{{< /history >}}

プロジェクトのメンテナーまたはオーナーロールを持つユーザーは、次のエンドポイントを使用して、Google CloudインテグレーションをセットアップするShellスクリプトをクエリすることができます:

```plaintext
GET /projects/:id/google_cloud/setup/integrations.sh
```

[Google Artifact Managementインテグレーション](../user/project/integrations/google_artifact_management.md)のみがサポートされています。このスクリプトは、Google ArtifactレジストリにアクセスするためのIAMポリシーを作成します:

- [Artifact Registry Reader](https://cloud.google.com/artifact-registry/docs/access-control#roles)ロールは、レポーターロール以上のメンバーに付与されます
- [Artifact Registry Writer](https://cloud.google.com/artifact-registry/docs/access-control#roles)ロールは、デベロッパーロール以上のメンバーに付与されます

サポートされている属性は以下のとおりです: 

| 属性                                   | 型    | 必須 | 説明                                                                 |
|---------------------------------------------|---------|----------|-----------------------------------------------------------------------------|
| `id`                                        | 整数 | はい      | GitLabプロジェクトのID。                                                           |
| `enable_google_cloud_artifact_registry`     | ブール値 | はい      | Google Artifact Managementインテグレーションを有効にするかどうかを示すフラグ。 |
| `google_cloud_artifact_registry_project_id` | 文字列  | はい      | Artifactレジストリ用のGoogle CloudプロジェクトID。                          |

リクエスト例: 

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<your_project_id>/google_cloud/setup/integrations.sh"
```

### Runnerのプロビジョニング用にGoogle Cloudプロジェクトを設定するスクリプト {#script-to-configure-a-google-cloud-project-for-runner-provisioning}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145525)されました。

{{< /history >}}

プロジェクトのメンテナーまたはオーナーロールを持つユーザーは、次のエンドポイントを使用して、Runnerのプロビジョニングおよび実行用にGoogle Cloudプロジェクトを設定するShellスクリプトをクエリすることができます:

```plaintext
GET /projects/:id/google_cloud/setup/runner_deployment_project.sh
```

このスクリプトは、指定されたGoogle Cloudプロジェクトで準備設定手順を実行します。具体的には、必要なサービスを有効にし、`GRITProvisioner`ロールと`grit-provisioner`サービスアカウントを作成します。

サポートされている属性は以下のとおりです: 

| 属性                 | 型    | 必須 | 説明                            |
|---------------------------|---------|----------|----------------------------------------|
| `id`                      | 整数 | はい      | GitLabプロジェクトのID。            |
| `google_cloud_project_id` | 文字列  | はい      | Google CloudプロジェクトのID。    |

リクエスト例: 

```shell
curl --request GET \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://gitlab.com/api/v4/projects/<your_project_id>/google_cloud/setup/runner_deployment_project.sh?google_cloud_project_id=<your_google_cloud_project_id>"
```
