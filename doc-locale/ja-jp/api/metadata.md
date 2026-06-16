---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: メタデータAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/357032)されました。
- `enterprise`がGitLab 15.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103969)されました。
- `kas.externalK8sProxyUrl`はGitLab 17.6で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172373)。

{{< /history >}}

指定されたGitLabインスタンスのメタデータ情報を取得します。

```plaintext
GET /metadata
GET /version
```

レスポンスボディの属性:

| 属性                 | 型           | 説明                                                                                                                   |
|:--------------------------|:---------------|:------------------------------------------------------------------------------------------------------------------------------|
| `version`                 | 文字列         | GitLabインスタンスのバージョン。                                                                                               |
| `revision`                | 文字列         | GitLabインスタンスのリビジョン。                                                                                              |
| `kas`                     | オブジェクト         | Kubernetes向けGitLabエージェントサーバー (KAS)に関するメタデータ。                                                                  |
| `kas.enabled`             | ブール値        | KASが有効であるかどうかを示します。                                                                                             |
| `kas.externalUrl`         | stringまたはnull | エージェントがKASと通信するために使用するURL。`kas.enabled`が`false`の場合、`null`です。                                      |
| `kas.externalK8sProxyUrl` | stringまたはnull | KubernetesツールがKAS Kubernetes APIプロキシと通信するために使用するURL。`kas.enabled`が`false`の場合、`null`です。 |
| `kas.version`             | stringまたはnull | KASのバージョン。`kas.enabled`が`false`の場合、またはGitLabインスタンスがKASからサーバー情報をフェッチできなかった場合、`null`です。         |
| `enterprise`              | ブール値        | GitLabインスタンスがEnterprise Editionであるかどうかを示します。                                                                      |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/metadata"
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/version"
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
