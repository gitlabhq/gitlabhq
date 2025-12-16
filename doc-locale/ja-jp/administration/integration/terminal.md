---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Webターミナル（非推奨）
description: Webターミナルに関する情報。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.0で[GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/353410)で無効になりました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は、GitLab 14.5で[非推奨](https://gitlab.com/groups/gitlab-org/configure/-/epics/8)になりました。

{{< /alert >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。管理者が`certificate_based_clusters`という名前の[機能フラグを有効にする](../feature_flags/_index.md)と、この機能を使用できるようになります。

{{< /alert >}}

- 非推奨ではない[Web IDEからアクセスできるWebターミナル](../../user/project/web_ide/_index.md)について、詳しくはこちらをご覧ください。
- 非推奨ではない[実行中のCIジョブからアクセスできるWebターミナル](../../ci/interactive_web_terminal/_index.md)について、詳しくはこちらをご覧ください。

---

[Kubernetesインテグレーション](../../user/infrastructure/clusters/_index.md)の導入により、GitLabはKubernetesクラスターの認証情報を保存して使用できます。GitLabは、これらの認証情報を使用して、環境の[web terminals](../../ci/environments/_index.md#web-terminals-deprecated)へのアクセスを提供します。

{{< alert type="note" >}}

プロジェクトの[メンテナー](../../user/permissions.md)以上のユーザー権限を持つユーザーのみがWebターミナルにアクセスできます。

{{< /alert >}}

## Webターミナルの仕組み {#how-web-terminals-work}

Webターミナルのアーキテクチャと動作方法の詳細な概要は、[このドキュメント](https://gitlab.com/gitlab-org/gitlab-workhorse/blob/master/doc/channel.md)に記載されています。概要:

- GitLabは、ユーザーが独自のKubernetes認証情報を提供し、デプロイ時に作成するポッドに適切なラベルを付けることを前提としています。
- ユーザーが環境のターミナルページにアクセスすると、GitLabへのWebSocket接続を開くJavaScriptアプリケーションが提供されます。
- WebSocketは、Railsアプリケーションサーバーではなく、[Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse)で処理されます。
- Workhorseは、接続の詳細とユーザー権限についてRailsにクエリを送信します。Railsは、[Sidekiq](../sidekiq/sidekiq_troubleshooting.md)を使用してバックグラウンドでそれらについてKubernetesにクエリを送信します。
- Workhorseは、ユーザーのブラウザとKubernetes API間のプロキシサーバーとして機能し、2つの間でWebSocketフレームを渡します。
- Workhorseは定期的にRailsをポーリングし、ユーザーがターミナルにアクセスするユーザー権限を持たなくなった場合、または接続の詳細が変更された場合に、WebSocket接続を終了します。

## セキュリティ {#security}

GitLabと[GitLab Runner](https://docs.gitlab.com/runner/)は、インタラクティブなWebターミナルデータを暗号化された状態で保持し、すべてを認可ガードで保護するために、いくつかの予防措置を講じています。詳細については、以下をご覧ください。

- [`[session_server]`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-session_server-section)が設定されていない限り、インタラクティブなWebターミナルは完全に無効になります。
- ランナーが起動するたびに、`x509`証明書が生成され、`wss`（Web Socket Secure）接続に使用されます。
- 作成されたジョブごとに、ランダムなURLが生成され、ジョブの最後に破棄されます。このURLは、Webソケット接続を確立するために使用されます。セッションのURLの形式は`(IP|HOST):PORT/session/$SOME_HASH`です。ここで、`IP/HOST`と`PORT`は[`listen_address`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-session_server-section)に設定されています。
- 作成されたすべてのセッションURLには、`wss`接続を確立するために送信する必要がある認可ヘッダーがあります。
- セッションURLは、どのような方法でもユーザーに公開されません。GitLabは、すべての状態を内部的に保持し、それに応じてプロキシします。

## ターミナルサポートの有効化と無効化 {#enabling-and-disabling-terminal-support}

{{< alert type="note" >}}

AWS Classicロードバランサーは、Webソケットをサポートしていません。Webターミナルを機能させるには、AWS Networkロードバランサーを使用します。詳細については、[AWS Elasticロードバランシング製品の比較](https://aws.amazon.com/elasticloadbalancing/features/#compare)をお読みください。

{{< /alert >}}

WebターミナルはWebSocketを使用するため、Workhorseの前面にあるすべてのHTTP/HTTPSリバースプロキシは、チェーン内の次のプロキシに`Connection`および`Upgrade`ヘッダーを渡すように設定する必要があります。GitLabは、デフォルトでそうするように設定されています。

ただし、GitLabの前面で[ロードバランサー](../load_balancer.md)を実行する場合は、設定にいくつかの変更を加える必要がある場合があります。これらのガイドでは、一般的なリバースプロキシの選択に必要な手順について説明します:

- [Apache](https://httpd.apache.org/docs/2.4/mod/mod_proxy_wstunnel.html) :
- [NGINX](https://www.f5.com/company/blog/nginx/websocket-nginx/)
- [HAProxy](https://www.haproxy.com/blog/websockets-load-balancing-with-haproxy)
- [Varnish](https://varnish-cache.org/docs/4.1/users-guide/vcl-example-websockets.html)

Workhorseは、WebSocketリクエストを非WebSocketエンドポイントに渡さないため、これらのヘッダーのサポートをグローバルに有効にしても安全です。より狭いルールのセットが必要な場合は、`/terminal.ws`で終わるURLに制限できます。このアプローチでは、いくつかの誤検出が発生する可能性があります。

インストールを自分でコンパイルした場合は、設定にいくつかの変更を加える必要がある場合があります。詳細については、[ソースからのCommunity EditionおよびEnterprise Editionのアップグレード](../../update/upgrading_from_source.md#new-configuration-for-nginx-or-apache)をお読みください。

GitLabでWebターミナルのサポートを無効にするには、チェーン内の最初のHTTPリバースプロキシで`Connection`および`Upgrade`ホップバイホップヘッダーの通過を停止します。ほとんどのユーザーにとって、これはLinuxパッケージインストールにバンドルされているNGINXサーバーです。この場合、次の操作が必要です:

- `nginx['proxy_set_headers']``gitlab.rb`ファイルのセクションを見つけます
- ブロック全体がコメント化されていないことを確認し、`Connection`行と`Upgrade`行をコメントアウトするか削除します。

独自のロードバランサーについては、前にリストしたガイドで推奨されている設定の変更を元に戻すだけです。

これらのヘッダーが通過しない場合、WorkhorseはWebターミナルを使用しようとしているユーザーに`400 Bad Request`応答を返します。次に、`Connection failed`メッセージを受信します。

## WebSocket接続時間の制限 {#limiting-websocket-connection-time}

デフォルトでは、ターミナルセッションは期限切れになりません。GitLabインスタンスのターミナルセッションライフタイムを制限するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **Webターミナル**を選択します。
1. `max session time`を設定します。
