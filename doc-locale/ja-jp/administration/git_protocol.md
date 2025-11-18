---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Self-Managed用にGitプロトコルv2を設定します。
title: Gitプロトコルv2の構成
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Gitプロトコルv2は、v1ワイヤプロトコルをいくつかの点で改善し、HTTPリクエストに対してGitLabでデフォルトで有効になっています。SSHを有効にするには、管理者による追加の設定が必要です。

新機能と改善点の詳細については、[GoogleオープンソースBlog](https://opensource.googleblog.com/2018/05/introducing-git-protocol-version-2.html)をご覧ください。

## 前提要件 {#prerequisites}

クライアント側からは、`git` `v2.18.0`以降がインストールされている必要があります。

サーバー側からは、SSHを設定するには、`sshd`サーバーが`GIT_PROTOCOL`環境変数を受け入れるように設定する必要があります。

[GitLab Helm Charts](https://docs.gitlab.com/charts/)および[All-in-one Dockerイメージ](../install/docker/_index.md)を使用するインストールでは、SSHサービスはすでに`GIT_PROTOCOL`環境変数を受け入れるように設定されています。ユーザーはこれ以上何をする必要もありません。

Linuxパッケージからのインストール、またはセルフコンパイルインストールの場合は、次の行を`/etc/ssh/sshd_config`ファイルに追加して、サーバーのSSH設定を手動で更新します:

```plaintext
AcceptEnv GIT_PROTOCOL
```

SSHデーモンを設定したら、変更を有効にするために再起動します:

```shell
# CentOS 6 / RHEL 6
sudo service sshd restart

# All other supported distributions
sudo systemctl restart ssh
```

## 手順 {#instructions}

新しいプロトコルを使用するには、クライアントは`-c protocol.version=2`設定をGitコマンドに渡すか、グローバルに設定する必要があります:

```shell
git config --global protocol.version 2
```

### HTTP connections {#http-connections}

クライアントがGit v2を使用していることを確認します:

```shell
GIT_TRACE_CURL=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | grep Git-Protocol
```

`Git-Protocol`ヘッダーが送信されていることを確認してください:

```plaintext
16:29:44.577888 http.c:657              => Send header: Git-Protocol: version=2
```

サーバーがGit v2を使用していることを確認します:

```shell
GIT_TRACE_PACKET=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | head
```

Gitプロトコルv2を使用した応答例:

```shell
$ GIT_TRACE_PACKET=1 git -c protocol.version=2 ls-remote https://your-gitlab-instance.com/group/repo.git 2>&1 | head
10:42:50.574485 pkt-line.c:80           packet:          git< # service=git-upload-pack
10:42:50.574653 pkt-line.c:80           packet:          git< 0000
10:42:50.574673 pkt-line.c:80           packet:          git< version 2
10:42:50.574679 pkt-line.c:80           packet:          git< agent=git/2.18.1
10:42:50.574684 pkt-line.c:80           packet:          git< ls-refs
10:42:50.574688 pkt-line.c:80           packet:          git< fetch=shallow
10:42:50.574693 pkt-line.c:80           packet:          git< server-option
10:42:50.574697 pkt-line.c:80           packet:          git< 0000
10:42:50.574817 pkt-line.c:80           packet:          git< version 2
10:42:50.575308 pkt-line.c:80           packet:          git< agent=git/2.18.1
```

### SSH Connections {#ssh-connections}

クライアントがGit v2を使用していることを確認します:

```shell
GIT_SSH_COMMAND="ssh -v" git -c protocol.version=2 ls-remote ssh://git@your-gitlab-instance.com/group/repo.git 2>&1 | grep GIT_PROTOCOL
```

`GIT_PROTOCOL`環境変数が送信されていることを確認してください:

```plaintext
debug1: Sending env GIT_PROTOCOL = version=2
```

サーバー側では、[HTTPからの同じ例](#http-connections)を使用して、URLをSSHを使用するように変更できます。

### 接続のGitプロトコルv2バージョンを監視します {#observe-git-protocol-version-of-connections}

本番環境で使用されているGitプロトコルバージョンを監視する方法については、[関連ドキュメント](gitaly/monitoring.md#queries)を参照してください。
