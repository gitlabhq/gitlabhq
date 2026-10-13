---
title: Geo SSHプロキシがデフォルトで有効化
tier: [ Premium, Ultimate ]
offering: [ self_managed ]
stage: GitLab Dedicated
documentation_link: '../../../administration/geo/replication/troubleshooting/ssh_proxying'
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/454707"
categories: [ Geo Replication ]
---

Geo SSHプロキシがデフォルトで有効化

GitLab 19.4では、以下の機能フラグがデフォルトで有効になりました。

- `geo_proxy_fetch_ssh_to_primary`
- `geo_proxy_push_ssh_to_primary`

Geo SSHプロキシは、Geoセカンダリサイトへのフェッチおよびプッシュをプライマリサイトにプロキシする際に、より信頼性の高いパスを提供します。また、[プッシュオプションを使用したプッシュ](https://gitlab.com/gitlab-org/gitlab/-/issues/417186)や[大規模リポジトリからのフェッチ](https://gitlab.com/gitlab-org/gitlab/-/issues/454707)など、プロキシ経由の操作が失敗していた長年のバグも解決されます。

**Cloud Native GitLabデプロイメントにおける対応が必要**

**バンドルされたNGINX Ingress**を使用するCloud Native GitLabデプロイメントでは、以下のいずれかの対応が必要です。

- このロールアウト前に[Gateway APIとEnvoy Gatewayへの移行](https://docs.gitlab.com/charts/installation/migration/envoy_gateway_migration/)を実施する、**または**
- ロールアウト後に両方の機能フラグを無効にする。

これらの対応を行わない場合、Geoセカンダリ経由のSSHフェッチおよびプッシュがハングまたはタイムアウトする可能性があります。

詳細については、SSHプロキシに関する[Geoトラブルシューティングドキュメント](../../../administration/geo/replication/troubleshooting/ssh_proxying.md)を参照してください。
