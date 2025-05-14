---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabを再起動する方法
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab Self-Managed

{{< /details >}}

GitLabのインストール方法に応じて、サービスを再起動する方法が異なります。

{{< alert type="note" >}}

どの方法でも、短いダウンタイムが発生する可能性があります。

{{< /alert >}}

## Linuxパッケージインストール

[Linuxパッケージ](https://about.gitlab.com/install/)を使用してGitLabをインストールした場合、すでに`gitlab-ctl`が`PATH`にあるはずです。

`gitlab-ctl`はLinuxパッケージインストールと連携して、GitLab Railsアプリケーション（Puma）に加えて、次のような他のコンポーネントを再起動するために使用できます。

- GitLab Workhorse
- Sidekiq
- PostgreSQL（バンドル版を使用している場合）
- NGINX（バンドル版を使用している場合）
- Redis（バンドル版を使用している場合）
- [Mailroom](reply_by_email.md)
- Logrotate

### Linuxパッケージインストールを再起動する

ドキュメントの中で、GitLabの_再起動_を求められる場合があります。Linuxパッケージインストールを再起動するには、次を実行します。

```shell
sudo gitlab-ctl restart
```

出力は次のようになります。

```plaintext
ok: run: gitlab-workhorse: (pid 11291) 1s
ok: run: logrotate: (pid 11299) 0s
ok: run: mailroom: (pid 11306) 0s
ok: run: nginx: (pid 11309) 0s
ok: run: postgresql: (pid 11316) 1s
ok: run: redis: (pid 11325) 0s
ok: run: sidekiq: (pid 11331) 1s
ok: run: puma: (pid 11338) 0s
```

コンポーネントを個別に再起動するには、`restart`コマンドの後ろにサービス名を付加します。たとえば、NGINX**のみ**を再起動するには、次を実行します。

```shell
sudo gitlab-ctl restart nginx
```

GitLabサービスの状態を確認するには、次を実行します。

```shell
sudo gitlab-ctl status
```

すべてのサービスが`ok: run`と表示されていることに注目してください。

再起動中にコンポーネントがタイムアウトしたり（ログで`timeout`を探してください）、処理が停止したままになることがあります。そのような場合は、`gitlab-ctl kill <service>`を使用して、そのサービス（例: `sidekiq`）に`SIGKILL`シグナルを送信できます。その後、再起動は正常に動作するはずです。

どうしても再起動できない場合は、代わりにGitLabを再設定してみてください。

### Linuxパッケージインストールを再設定する

ドキュメントの中で、GitLabの_再設定_を求められる場合があります。この方法は、Linuxパッケージインストールにのみ適用されることに注意してください。

Linuxパッケージインストールを再設定するには、次を実行します。

```shell
sudo gitlab-ctl reconfigure
```

設定（`/etc/gitlab/gitlab.rb`）を変更した場合は、GitLabの再設定が必要になります。

`gitlab-ctl reconfigure`を実行すると、Linuxパッケージインストールの強化基盤となっている設定管理アプリケーションである[Chef](https://www.chef.io/products/chef-infra)が、いくつかのチェックを実行します。Chefは、ディレクトリ、権限、サービスが適切に配置され、機能していることを確認します。

設定ファイルのいずれかを変更した場合、ChefはGitLabコンポーネントの再起動も行います。

`/var/opt/gitlab`内のChefによって管理されているファイルを手動で編集した場合、`reconfigure`を実行するとその変更が元に戻り、それらのファイルに依存するサービスが再起動されます。

## 自己コンパイルによるインストール

公式インストールガイドに従って[自己コンパイルでインストール](../install/installation.md)した場合は、次のコマンドを実行してGitLabを再起動します。

```shell
# For systems running systemd
sudo systemctl restart gitlab.target

# For systems running SysV init
sudo service gitlab restart
```

これにより、Puma、Sidekiq、GitLab Workhorse、[Mailroom](reply_by_email.md)（有効になっている場合）が再起動されます。

## Helmチャートによるインストール

[クラウドネイティブなHelmチャート](https://docs.gitlab.com/charts/)を使用してインストールしたGitLabアプリケーション全体を再起動するための単一のコマンドはありません。通常は、関連するすべてのポッドを削除して、特定のコンポーネント（たとえば、`gitaly`、`puma`、`workhorse`、`gitlab-shell`）を個別に再起動すれば十分です。

```shell
kubectl delete pods -l release=<helm release name>,app=<component name>
```

リリース名は、`helm list`コマンドの出力から取得できます。

## Dockerインストール

[Dockerインストール](../install/docker/_index.md)で設定を変更した場合、その変更を有効にするには、次のコンテナを再起動する必要があります。

- メインの`gitlab`コンテナ
- 個別のコンポーネントコンテナ

たとえば、Sidekiqを個別のコンテナにデプロイした場合、コンテナを再起動するには、次を実行します。

```shell
sudo docker restart gitlab
sudo docker restart sidekiq
```
