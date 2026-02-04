---
stage: AI-powered
group: Editor Extensions
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: VS Code拡張機能とWebビューを分離するために、Web IDEが使用するワイルドカードドメインを示します
title: Web IDE拡張機能ホストドメイン
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

拡張ホストドメインは、[拡張機能マーケットプレース](../../user/project/web_ide/_index.md#manage-extensions)を使用してインストールされたサードパーティのコードを分離するためにWeb IDEで使用されるワイルドカードドメイン名です。Web IDEは、サンドボックス環境で拡張機能を実行するために、Webブラウザの[同一生成元](https://developer.mozilla.org/en-US/docs/Web/Security/Same-origin_policy)ポリシーに依存しています。

GitLabは、デフォルトのGitLabオファリングすべてでデフォルトで使用できるデフォルトの拡張ホストドメイン`cdn.web-ide.gitlab-static.net`を提供します。このドメイン名は、VS Codeの静的アセットをホストする外部HTTPサーバーを指します。オフライン環境では、ユーザーのWebブラウザはこの外部HTTPサーバーに接続できないため、Web IDEの機能が制限されます。

この制限を回避するために、GitLabインスタンスの管理者は、カスタム拡張ホストドメインをセットアップできます。カスタム拡張ホストドメインは、デフォルトのソリューションと同様に、VS Codeの静的アセットも提供できるGitLabインスタンス自体を指します。

> [!warning]Web IDE拡張機能の拡張ホストドメインで、広すぎるワイルドカードドメインを設定すると、重大なセキュリティリスクがあります。設定ミスにより、GitLabインスタンスと関連するすべてのデータが侵害される可能性があります。

## カスタム拡張ホストドメインをセットアップする {#set-up-custom-extension-host-domain}

前提条件: 

- 管理者である必要があります。

これらの手順は、デフォルトのNGINXインストールを使用する[Linuxパッケージのインストール](../../install/package/_index.md)用です。GitLab管理者とDevOpsエンジニアは、このガイドを他のインストール方法に適合させる必要があります。

1. ガイドに従って[カスタム設定をNGINXの設定に挿入](https://docs.gitlab.com/omnibus/settings/nginx/#insert-custom-settings-into-the-nginx-configuration)し、`server`ブロックを追加します。このブロックは、拡張ホストドメインのリクエストを処理するようにNGINXを設定します。設定例として、次のコードスニペットを参照してください。`<extension-host-domain-placeholder>`をWeb IDE拡張機能の拡張ホストドメインのワイルドカードドメイン名に置き換えます:

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

1. ファイルを保存して、[GitLabを再設定](../restart_gitlab.md#reconfigure-a-linux-package-installation)し、変更を有効にします。次に、GitLabアプリケーションを開きます。
1. 右上隅で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **Web IDE**を展開します。
1. **拡張ホストドメイン**テキストボックスに、カスタム拡張ホストドメインを入力します。
1. **変更を保存**を選択します。

設定を保存したら、Web IDEでプロジェクトを開き、エディタでカスタム拡張機能ホストが使用されていることを確認できます。
