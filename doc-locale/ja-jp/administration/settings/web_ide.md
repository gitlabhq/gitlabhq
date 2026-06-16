---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: VS Code拡張機能とWebビューを分離するために、Web IDEが使用するワイルドカードドメインを指定します
title: Web IDE拡張機能ホストドメイン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

拡張機能ホストドメインは、[拡張機能マーケットプレース](../../user/project/web_ide/_index.md#manage-extensions)を使用してインストールされたサードパーティのコードを分離するために、Web IDEが使用するワイルドカードドメイン名です。Web IDEは、サンドボックス環境で拡張機能を実行するために、Webブラウザの[同一オリジン](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy)ポリシーに依存しています。

GitLabは、`*.cdn.web-ide.gitlab-static.net`というデフォルトの拡張機能ホストドメインを提供しており、すべてのGitLab提供形態においてデフォルトで利用できます。このワイルドカードドメインは、VS Codeの静的アセットをホストする外部HTTPサーバーを指します。各拡張機能は独自のサブドメインから提供されます。オフライン環境では、ユーザーのウェブブラウザはこの外部HTTPサーバーに接続できず、その結果、Web IDEの機能が制限されます。

この制限を回避するために、GitLabインスタンス管理者は、カスタム拡張機能ホストドメインをセットアップできます。カスタム拡張機能ホストドメインはGitLabインスタンス自体を指し、デフォルトのソリューションと同様に、VS Codeの静的アセットも配信できます。

> [!warning]
> Web IDE拡張機能ホストドメインで、過度に広範なワイルドカードドメインを設定すると、重大なセキュリティリスクがあります。設定ミスにより、GitLabインスタンスおよび関連するすべてのデータが侵害される可能性があります。

## カスタム拡張機能ホストドメインをセットアップする {#set-up-custom-extension-host-domain}

前提条件: 

- 管理者である必要があります。

これらの手順は、デフォルトのNGINXインストールを使用する[Linuxパッケージインストール](../../install/package/_index.md)を対象としています。GitLab管理者およびDevOpsエンジニアは、他のインストール方法に合わせてこのガイドを調整してください。

1. ガイドに従って、[NGINXの設定にカスタム設定を追加](https://docs.gitlab.com/omnibus/settings/nginx/#insert-custom-settings-into-the-nginx-configuration)し、`server`ブロックを追加します。このブロックは、拡張機能ホストドメインのリクエストを処理するようにNGINXを設定します。次のコードスニペットは参照用の設定例です。`<extension-host-domain-placeholder>`を、Web IDE拡張機能ホストドメインのワイルドカードドメイン名に置き換えてください:

   ```nginx
   server {
     listen *:443 ssl;
     server_name *.<extension-host-domain-placeholder>;

     ssl_certificate /etc/gitlab/ssl/<extension-host-domain-placeholder>.pem;
     ssl_certificate_key /etc/gitlab/ssl/<extension-host-domain-placeholder>-key.pem;

     ## Individual nginx logs for this GitLab vhost
     access_log  /var/log/gitlab/nginx/gitlab_access.log gitlab_access;
     error_log   /var/log/gitlab/nginx/gitlab_error.log;

     location /assets/ {
       client_max_body_size 0;
       gzip off;

       proxy_read_timeout      300;
       proxy_connect_timeout   300;
       proxy_redirect          off;

       proxy_http_version 1.1;

       proxy_set_header    Host                $http_host;
       proxy_set_header    X-Real-IP           $remote_addr;
       proxy_set_header    X-Forwarded-For     $remote_addr;
       proxy_set_header    X-Forwarded-Proto   $scheme;

       proxy_pass http://gitlab-workhorse;
     }
   }
   ```

1. ファイルを保存し、変更を反映するために[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)します。次に、GitLabアプリケーションを開きます。
1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **Web IDE**を展開します。
1. **拡張機能ホストドメイン**テキストボックスに、カスタム拡張機能ホストドメインを入力します。
1. **変更を保存**を選択します。

変更を保存したら、Web IDEでプロジェクトを開き、エディタがカスタム拡張機能ホストを使用していることを確認できます。

## 単一originフォールバック {#single-origin-fallback}

> [!warning]
> 単一originのフォールバックはデフォルトで有効になっており、セキュリティ上のリスクがあります。フォールバックを無効にし、代わりに拡張機能ホストドメインがCORS設定、ウェブブラウザのセキュリティポリシー、またはプロキシサーバーによってブロックされていないことを確認する必要があります。

デフォルトでは、Web IDEはマルチオリジンモードで実行され、VS Codeの静的アセットは別の拡張機能ホストドメインから提供されます。この分離により、悪意のあるアクターが拡張機能ホストを悪用して、GitLabのインスタンスへの認証されたリクエストを行うことを防ぎます。

ただし、ネットワークまたはCORSの制限により拡張機能ホストドメインに到達できない場合、Web IDEは自動的に単一オリジンモードにフォールバックします。このモードでは、Web IDEはGitLabアプリケーションと同じoriginからVS Codeのアセットを提供するため、アタックサーフェスが増加し、セキュリティ脆弱性が発生します。

**単一ソースのフォールバックを有効にする**設定は、拡張ホストドメインに到達できない場合に、Web IDEが単一オリジンモードにフォールバックできるかどうかを制御します。

前提条件: 

- 管理者アクセス権が必要です。

この設定を構成するには、次の手順に従います。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **Web IDE**を展開します。
1. **単一ソースのフォールバックを有効にする**チェックボックスを選択またはクリアします。
1. **変更を保存**を選択します。
