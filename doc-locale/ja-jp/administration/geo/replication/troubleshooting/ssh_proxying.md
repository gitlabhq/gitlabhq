---
stage: GitLab Dedicated
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo SSH応答コードエラーのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## NGINX Ingressを使用するCloud NativeデプロイでSSHプルおよびプッシュが際限なくハングする {#ssh-pull-and-push-hang-indefinitely-on-cloud-native-deployments-using-nginx-ingress}

> [!note]
> この問題は、バンドルされたNGINX Ingressを使用するCloud Native GitLabデプロイにのみ影響します。IngressコントローラーとしてEnvoyを使用するデプロイはこの問題の影響を受けません。

Helmチャートを使用してデプロイされたセカンダリサイトからのSSHプッシュとプルは、以下の機能フラグが有効な場合に際限なくハングすることがあります:

- `geo_proxy_fetch_ssh_to_primary`
- `geo_proxy_push_ssh_to_primary`

これらのフラグは、Geoセカンダリに対して開始されたGit操作のSSHプロキシパスを変更します。これらはGitLabバージョン19.4.0以降でデフォルトで有効になっています。

この問題は、webservice IngressにおけるNGINXリクエストのバッファリングが原因です。GitLab Shellはストリーミングリクエストボディを送信しますが、Gitクライアントはrefアドバタイズメントを待ちます。NGINXはリクエストボディを待ち、Gitクライアントは応答を待つため、リクエストはWorkhorseに到達しません。

これを修正するには、デプロイに合ったオプションを選択してください:

- GitLab 18.11以前の場合: 両方の機能フラグを無効にします:
  - `geo_proxy_fetch_ssh_to_primary`
  - `geo_proxy_push_ssh_to_primary`
- GitLab 19.0以降の場合:
  - Ingressコントローラーとして[Envoy Gateway](https://docs.gitlab.com/charts/installation/migration/envoy_gateway_migration/)を使用するようにアップグレードします。

バンドルされたNGINX Ingressを使用している間は、両方の機能フラグを有効にしたままにしないでください。そうしないと、ユーザーはGeoセカンダリ経由でのSSHフェッチやプッシュを完了できない場合があります。

技術的な詳細については、[Geo proxied git fetch error: fatal: the remote end hung up unexpectedly](https://gitlab.com/gitlab-org/gitlab/-/work_items/454707)を参照してください。

## エラー: GeoセカンダリでSSH経由でプッシュする際に`Net::ReadTimeout` {#error-netreadtimeout-when-pushing-through-ssh-on-a-geo-secondary}

GeoセカンダリサイトでSSH経由で大きなリポジトリをプッシュする際に、タイムアウトが発生する場合があります。これは、Railsがプッシュをプライマリにプロキシし、60秒のデフォルトタイムアウトがあるためです。[このGeoイシューで説明されています](https://gitlab.com/gitlab-org/gitlab/-/issues/7405)。この問題は、`geo_proxy_push_ssh_to_primary`機能フラグが無効になっている場合にのみ発生します。

現在の回避策は次のとおりです:

- 代わりにHTTP経由でプッシュします。Workhorseがリクエストをプライマリにプロキシします（またはGeoプロキシが有効になっていない場合はプライマリにリダイレクトします）。
- プライマリに直接プッシュします。

ログの例（`gitlab-shell.log`）:

```plaintext
Failed to contact primary https://primary.domain.com/namespace/push_test.git\\nError: Net::ReadTimeout\",\"result\":null}" code=500 method=POST pid=5483 url="http://127.0.0.1:3000/api/v4/geo/proxy_git_push_ssh/push"
```
