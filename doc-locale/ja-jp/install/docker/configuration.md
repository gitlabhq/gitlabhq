---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dockerコンテナで実行されているGitLabを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

このコンテナは公式のLinuxパッケージを使用しているため、固有の設定ファイル`/etc/gitlab/gitlab.rb`を使用してインスタンスを構成できます。

## 設定ファイルを編集する

GitLabの設定ファイルにアクセスするには、実行中のコンテナのコンテキストでShellセッションを開始します。

1. セッションを開始します。

   ```shell
   sudo docker exec -it gitlab /bin/bash
   ```

   または、`/etc/gitlab/gitlab.rb`をエディタで直接開くこともできます。

   ```shell
   sudo docker exec -it gitlab editor /etc/gitlab/gitlab.rb
   ```

1. お好みのテキストエディタで`/etc/gitlab/gitlab.rb`を開き、次のフィールドを更新します。

   1. `external_url`フィールドを、GitLabインスタンスの有効なURLに設定します。

   1. GitLabからメールを受信するには、[SMTP設定](https://docs.gitlab.com/omnibus/settings/smtp.html)を構成します。GitLab Dockerイメージには、SMTPサーバーがプリインストールされていません。

   1. 必要に応じて[HTTPSを有効](https://docs.gitlab.com/omnibus/settings/ssl/)にします。

1. ファイルを保存し、コンテナを再起動してGitLabを再設定します。

   ```shell
   sudo docker restart gitlab
   ```

GitLabは、コンテナが起動するたびに再設定が行われます。GitLabのその他の設定オプションについては、[設定に関するドキュメント](https://docs.gitlab.com/omnibus/settings/configuration.html)を参照してください。

## Dockerコンテナを事前設定する

Dockerの実行コマンドに環境変数`GITLAB_OMNIBUS_CONFIG`を追加すると、GitLab Dockerイメージを事前に設定できます。この変数は、任意の`gitlab.rb`設定を含めることができ、コンテナの`gitlab.rb`ファイルが読み込まれる前に評価されます。この動作により、外部GitLab URLの設定やデータベースの構成、その他[Linuxパッケージテンプレート](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-config-template/gitlab.rb.template)から任意のオプションを作成できます。`GITLAB_OMNIBUS_CONFIG`に含まれる設定は、`gitlab.rb`設定ファイルには書き込まれず、読み込み時に評価されます。複数の設定を指定するには、コロン(`;`)で区切ります。

次の例では、外部URLを設定し、LFSを有効にして、[Prometheusに必要な最小shmサイズ](troubleshooting.md#devshm-mount-not-having-enough-space-in-docker-container)でコンテナを起動します。

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'; gitlab_rails['lfs_enabled'] = true;" \
  --publish 443:443 --publish 80:80 --publish 22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:<version>-ee.0
```

`docker run`コマンドを実行するたびに、`GITLAB_OMNIBUS_CONFIG`オプションを指定する必要があります。`GITLAB_OMNIBUS_CONFIG`の内容は、後続の実行では保持_されません_。

### パブリックIPアドレスでGitLabを実行する

Dockerで`--publish`フラグを変更することにより、指定したIPアドレスを使用し、すべてのトラフィックをGitLabコンテナに転送するように設定できます。

IP`198.51.100.1`でGitLabを公開するには:

```shell
sudo docker run --detach \
  --hostname gitlab.example.com \
  --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com'" \
  --publish 198.51.100.1:443:443 \
  --publish 198.51.100.1:80:80 \
  --publish 198.51.100.1:22:22 \
  --name gitlab \
  --restart always \
  --volume $GITLAB_HOME/config:/etc/gitlab \
  --volume $GITLAB_HOME/logs:/var/log/gitlab \
  --volume $GITLAB_HOME/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:<version>-ee.0
```

これにより、`http://198.51.100.1/`および`https://198.51.100.1/`でGitLabインスタンスにアクセスできます。

## 異なるポートでGitLabを公開する

GitLabはコンテナ内の[特定のポート](../../administration/package_information/defaults.md)を使用します。

デフォルトのポート`80`(HTTP)、`443`(HTTPS)、または`22`(SSH) とは異なるホストのポートを使用する場合は、個別の`--publish`ディレクティブを`docker run`コマンドに追加する必要があります。

たとえば、Webインターフェイスをホストのポート`8929`で、SSHサービスをポート`2424`で公開するには:

1. 次の`docker run`コマンドを使用します。

   ```shell
   sudo docker run --detach \
     --hostname gitlab.example.com \
     --env GITLAB_OMNIBUS_CONFIG="external_url 'http://gitlab.example.com:8929'; gitlab_rails['gitlab_shell_ssh_port'] = 2424" \
     --publish 8929:8929 --publish 2424:22 \
     --name gitlab \
     --restart always \
     --volume $GITLAB_HOME/config:/etc/gitlab \
     --volume $GITLAB_HOME/logs:/var/log/gitlab \
     --volume $GITLAB_HOME/data:/var/opt/gitlab \
     --shm-size 256m \
     gitlab/gitlab-ee:<version>-ee.0
   ```

   {{< alert type="note" >}}

   ポートを公開する形式は`hostPort:containerPort`です。[受信ポートの公開](https://docs.docker.com/network/#published-ports)については、Dockerドキュメントを参照してください。

   {{< /alert >}}

1. 実行中のコンテナを入力します。

   ```shell
   sudo docker exec -it gitlab /bin/bash
   ```

1. エディターで`/etc/gitlab/gitlab.rb`を開き、`external_url`を設定します。

   ```ruby
   # For HTTP
   external_url "http://gitlab.example.com:8929"

   or

   # For HTTPS (notice the https)
   external_url "https://gitlab.example.com:8929"
   ```

   このURLで指定されたポートは、Dockerがホストに公開したポートと一致する必要があります。また、NGINXリッスンポートが`nginx['listen_port']`で明示的に設定されていない場合は、代わりに`external_url`が使用されます。詳細については、[NGINXのドキュメント](https://docs.gitlab.com/omnibus/settings/nginx.html)を参照してください。

1. SSHポートを設定します。

   ```ruby
   gitlab_rails['gitlab_shell_ssh_port'] = 2424
   ```

1. 最後に、GitLabを再設定します。

   ```shell
   gitlab-ctl reconfigure
   ```

上記の例に従うと、Webブラウザは`<hostIP>:8929`でGitLabインスタンスにアクセスし、ポート`2424`でSSHをプッシュできます。

[Docker Compose](installation.md#install-gitlab-by-using-docker-compose)セクションで、異なるポートを使用する`docker-compose.yml`の例を確認できます。

## 複数のデータベース接続を設定する

[GitLab 16.0](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6850)以降、GitLabはデフォルトで、同じPostgreSQLデータベースを指す2つのデータベース接続を使用します。

何らかの理由で、単一のデータベース接続に戻したい場合は:

1. コンテナ内の`/etc/gitlab/gitlab.rb`を編集します。

   ```shell
   sudo docker exec -it gitlab editor /etc/gitlab/gitlab.rb
   ```

1. 次の行を追加します。

   ```ruby
   gitlab_rails['databases']['ci']['enable'] = false
   ```

1. コンテナを再起動します。

   ```shell
   sudo docker restart gitlab
   ```

## 次のステップ

インストールの設定を完了したら、認証オプションやサインアップ制限など、[推奨される次の手順](../next_steps.md)を実行することを検討してください。
