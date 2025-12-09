---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: メタデータAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/357032)されました。
- `enterprise`がGitLab 15.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103969)されました。
- `kas.externalK8sProxyUrl`GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172373)。

{{< /history >}}

このGitLabインスタンスのメタデータ情報を取得します。

```plaintext
GET /metadata
```

レスポンスボディ属性:

| 属性                 | 型           | 説明                                                                                                                   |
|:--------------------------|:---------------|:------------------------------------------------------------------------------------------------------------------------------|
| `version`                 | 文字列         | インスタンスのGitLabのバージョン。                                                                                               |
| `revision`                | 文字列         | GitLabインスタンスのリビジョン。                                                                                              |
| `kas`                     | オブジェクト         | Kubernetes用GitLabエージェントサーバー（KAS）に関するメタデータ。                                                                  |
| `kas.enabled`             | ブール値        | KASが有効かどうかを示します。                                                                                             |
| `kas.externalUrl`         | 文字列または | エージェントがKASと通信するために使用するURL。`kas.enabled`が`false`の場合、`null`です。                                      |
| `kas.externalK8sProxyUrl` | 文字列または | KubernetesツールがKAS Kubernetes APIプロキシと通信するために使用するURL。`kas.enabled`が`false`の場合、`null`です。 |
| `kas.version`             | 文字列または | KASのバージョン。`kas.enabled`が`false`の場合、またはGitLabインスタンスがKASからサーバー情報のフェッチに失敗した場合、`null`になります。         |
| `enterprise`              | ブール値        | GitLabインスタンスがEnterprise Editionかどうかを示します。                                                                      |

リクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/metadata"
```

レスポンス例:

```json
{
  "version": "18.1.1-ee",
  "revision": "ceb07b24cb0",
  "kas": {
    "enabled": true,
    "externalUrl": "grpc://gitlab.example.com:8150",
    "externalK8sProxyUrl": "https://gitlab.example.com:8150/k8s-proxy",
    "version": "18.1.1"
  },
  "enterprise": true
}
```
