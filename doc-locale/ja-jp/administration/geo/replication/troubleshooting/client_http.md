---
stage: Runtime
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GeoクライアントとHTTPレスポンスコードのエラーのトラブルシューティング
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

## クライアントエラーの修正 {#fixing-client-errors}

### LFS HTTP(S)クライアントリクエストからの認可エラー {#authorization-errors-from-lfs-https-client-requests}

2.4.2より前の[Git LFS](https://git-lfs.com/)のバージョンを実行している場合、問題が発生することがあります。[この認証イシュー](https://github.com/git-lfs/git-lfs/issues/3025)に記載されているように、セカンダリサイトからプライマリサイトにリダイレクトされたリクエストは、認可ヘッダーを適切に送信しません。これにより、無限の`Authorization <-> Redirect`ループ、または認可エラーメッセージが発生する可能性があります。

### エラー: GeoセカンダリでSSH経由でプッシュするときの`Net::ReadTimeout`タイムアウト {#error-netreadtimeout-when-pushing-through-ssh-on-a-geo-secondary}

GeoセカンダリサイトでSSH経由で大きなリポジトリをプッシュすると、タイムアウトが発生する場合があります。これは、[このGeoイシューで説明されているように](https://gitlab.com/gitlab-org/gitlab/-/issues/7405)、Railsがプッシュをプライマリにプロキシし、60秒のデフォルトタイムアウトがあるためです。

現在の回避策は次のとおりです:

- Gitalyプロキシがプライマリへのリクエストをプロキシする（またはGeoプロキシが有効になっていない場合はプライマリにリダイレクトする）代わりに、HTTP経由でプッシュします。
- プライマリに直接プッシュします。

ログの例（`gitlab-shell.log`）:

```plaintext
Failed to contact primary https://primary.domain.com/namespace/push_test.git\\nError: Net::ReadTimeout\",\"result\":null}" code=500 method=POST pid=5483 url="http://127.0.0.1:3000/api/v4/geo/proxy_git_push_ssh/push"
```

### Geoサイト間のOAuth認可を修復する {#repair-oauth-authorization-between-geo-sites}

Geoサイトをアップグレードする場合、OAuthを認証にのみ使用するセカンダリサイトにサインインできない可能性があります。その場合は、プライマリサイトで[Railsコンソール](../../../operations/rails_console.md)セッションを開始し、次の手順を実行します:

1. 影響を受けるノードを見つけるには、まず、所有しているすべてのGeoノードを一覧表示します:

   ```ruby
   GeoNode.all
   ```

1. 影響を受けるGeoノードを修復するには、IDを指定します:

   ```ruby
   GeoNode.find(<id>).repair
   ```

## HTTPレスポンスコードのエラー {#http-response-code-errors}

### セカンダリサイトがGeoプロキシで502エラーを返す {#secondary-site-returns-502-errors-with-geo-proxying}

[セカンダリサイトのGeoプロキシ](../../secondary_proxy/_index.md)が有効になっており、セカンダリサイトのユーザーインターフェースが502エラーを返す場合、プライマリサイトからプロキシされた応答ヘッダーが大きすぎる可能性があります。

この例と同様のエラーについて、NGINXログを確認してください:

```plaintext
2022/01/26 00:02:13 [error] 26641#0: *829148 upstream sent too big header while reading response header from upstream, client: 10.0.2.2, server: geo.staging.gitlab.com, request: "POST /users/sign_in HTTP/2.0", upstream: "http://unix:/var/opt/gitlab/gitlab-workhorse/sockets/socket:/users/sign_in", host: "geo.staging.gitlab.com", referrer: "https://geo.staging.gitlab.com/users/sign_in"
```

この問題を解決するには、以下を実行します:

1. セカンダリサイトのすべてのWebノードの`/etc/gitlab.rb`で`nginx['proxy_custom_buffer_size'] = '8k'`を設定します。
1. `sudo gitlab-ctl reconfigure`を使用して、**セカンダリ**を再構成します。

それでもこのエラーが発生する場合は、前の手順を繰り返して`8k`サイズを変更することで、バッファサイズをさらに大きくすることができます（たとえば、`16k`に倍増するなど）。

### Geo管理者エリアに`Unknown`がヘルスステータスとして表示され、「リクエストがステータスコード401で失敗しました」と表示される {#geo-admin-area-shows-unknown-for-health-status-and-request-failed-with-status-code-401}

ロードバランサーを使用している場合は、ロードバランサーの背後にあるノードの`/etc/gitlab/gitlab.rb`で、ロードバランサーのURLが`external_url`として設定されていることを確認してください。

プライマリサイトで、**管理者** > **Geo** > **設定**に移動し、**許可されているGeo IP**フィールドを見つけます。セカンダリサイトのIPアドレスがリストされていることを確認してください。

### プライマリサイトが`/admin/geo/replication/projects`へのアクセス時に500エラーを返す {#primary-site-returns-500-error-when-accessing-admingeoreplicationprojects}

プライマリGeoサイトの**管理者** > **Geo** > **Replication**（レプリケーション）（または`/admin/geo/replication/projects`）に移動すると、500エラーが表示されますが、セカンダリサイトの同じリンクは正常に機能します。プライマリの`production.log`には、次のようなエントリがあります:

```plaintext
Geo::TrackingBase::SecondaryNotConfigured: Geo secondary database is not configured
  from ee/app/models/geo/tracking_base.rb:26:in `connection'
  [..]
  from ee/app/views/admin/geo/projects/_all.html.haml:1
```

Geoプライマリサイトでは、このエラーは無視できます。

これは、GitLabが[Geoトラッキングデータベース](../../_index.md#geo-tracking-database)からレジストリを表示しようとしていることが原因で、トラッキングデータベースはプライマリサイトに存在しません（元のプロジェクトのみがプライマリに存在します。レプリケートされたプロジェクトは存在しないため、トラッキングデータベースは存在しません）。

### セカンダリサイトが400エラーを返す`Request header or cookie too large` {#secondary-site-returns-400-error-request-header-or-cookie-too-large}

このエラーは、プライマリサイトの内部URLが正しくない場合に発生する可能性があります。

たとえば、統合URLを使用し、プライマリサイトの内部URLが外部URLと等しい場合などです。これにより、セカンダリサイトがプライマリサイトの内部URLにリクエストをプロキシするときにループが発生します。

このイシューを修正するには、プライマリサイトの内部URLを次のURLに設定します:

- プライマリサイトに固有。
- すべてのセカンダリサイトからアクセス可能。

1. プライマリサイトにアクセスしてください。
1. [内部URLを設定します](../../../geo_sites.md#set-up-the-internal-urls)。

### セカンダリサイトが`Received HTTP code 403 from proxy after CONNECT`を返す {#secondary-site-returns-received-http-code-403-from-proxy-after-connect}

Linuxパッケージ（Omnibus）を使用してGitLabをインストールし、Gitalyの`no_proxy`[カスタム環境変数](https://docs.gitlab.com/omnibus/settings/environment-variables.html)を構成した場合、このイシューが発生する可能性があります。影響を受けるバージョン: 

- `15.4.6`
- `15.5.0`-`15.5.6`
- `15.6.0`-`15.6.3`
- `15.7.0`-`15.7.1`

これは、[Linuxパッケージ15.4.6以降に同梱されている、含まれているバージョンのcURLに導入されたバグ](https://github.com/curl/curl/issues/10122)が原因です。これが[修正された](https://about.gitlab.com/releases/2023/01/09/security-release-gitlab-15-7-2-released/)、以降のバージョンにアップグレードする必要があります。

このバグにより、すべてのワイルドカードドメイン（`.example.com`）は、`no_proxy`環境変数リストの最後のドメインを除いて無視されます。したがって、何らかの理由でバージョンをアップグレードできない場合は、ワイルドカードドメインをリストの最後に移動することで、このイシューを回避できます:

1. `/etc/gitlab/gitlab.rb`を編集します: 

   ```ruby
   gitaly['env'] = {
     "no_proxy" => "sever.yourdomain.org, .yourdomain.com",
   }
   ```

1. GitLabを再設定します:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

`no_proxy`リストに含めることができるワイルドカードドメインは1つだけです。

### Geo管理者エリアがセカンダリサイトの404エラーを返す {#geo-admin-area-returns-404-error-for-a-secondary-site}

`sudo gitlab-rake gitlab:geo:check`が**セカンダリサイトのRailsノード**が正常であることを示している場合でも、**セカンダリ**サイトの404 Not Foundエラーメッセージが、Geo**管理者**エリアで**プライマリ**サイトのWebインターフェースに返されます。

この問題を解決するには、以下を実行します:

- `sudo gitlab-ctl restart`を使用して**セカンダリサイトの各Rails、Sidekiq、Gitalyノード**を再起動してみてください。
- **セカンダリ**サイトがIPv6を使用してステータスを**プライマリ**サイトに送信しているかどうかを確認するには、Sidekiqノードで`/var/log/gitlab/gitlab-rails/geo.log`を確認してください。そうである場合は、`/etc/hosts`ファイルでIPv4を使用して**プライマリ**サイトにエントリを追加します。または、[**プライマリ**サイトでIPv6を有効にする](https://docs.gitlab.com/omnibus/settings/nginx.html#setting-the-nginx-listen-address-or-addresses)必要があります。
