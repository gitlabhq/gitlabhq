---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dockerコンテナで実行されているGitLabのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

Dockerコンテナにをインストールする際、以下の問題が発生する可能性があります。

## 潜在的な問題の診断 {#diagnose-potential-problems}

Dockerコンテナ内のGitLabインスタンスのトラブルシューティングを行う際に、以下のコマンドが役立ちます:

コンテナログを読み取ります:

```shell
sudo docker logs gitlab
```

実行中のコンテナに入ります:

```shell
sudo docker exec -it gitlab /bin/bash
```

[Linuxパッケージのインストール](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md)を管理するのと同じように、コンテナ内からGitLabコンテナを管理できます。

## 500 Internal Error {#500-internal-error}

Dockerイメージを更新する際、すべてのパスに`500`ページが表示される問題が発生する場合があります。この問題が発生した場合は、コンテナを再起動してください:

```shell
sudo docker restart gitlab
```

## ユーザー権限の問題 {#permission-problems}

古いGitLab Dockerイメージから更新する場合、ユーザー権限の問題が発生する可能性があります。これは、以前のイメージのユーザー権限が正しく保持されなかった場合に発生します。すべてのファイルのユーザー権限を修正するスクリプトがあります。

コンテナを修正するには、`update-permissions`を実行し、その後コンテナを再起動します:

```shell
sudo docker exec gitlab update-permissions
sudo docker restart gitlab
```

## リソース`ruby_block`でアクションの実行中にエラーが発生しました {#error-executing-action-run-on-resource-ruby_block}

このエラーは、WindowsまたはMacでOracle VirtualBoxとDocker Toolboxを使用し、Dockerボリュームを使用する場合に発生します:

```plaintext
Error executing action run on resource ruby_block[directory resource: /data/GitLab]
```

`/c/Users`ボリュームはVirtualBox共有フォルダーとしてマウントされており、すべてのPOSIXファイルシステム機能をサポートしていません。ディレクトリの所有権とユーザー権限は、再マウントしない限り変更できず、GitLabは失敗します。

Docker Toolboxを使用する代わりに、プラットフォームのネイティブDockerインストールを使用するように切り替えます。

ネイティブDockerインストール（Windows 10 Home Edition、またはWindows 7/8）を使用できない場合、代替ソリューションは、Docker Toolbox Boot2dockerのVirtualBox共有の代わりにNFSマウントを設定することです。

## Linux ACLのイシュー {#linux-acl-issues}

DockerホストでファイルACLを使用している場合、GitLabが機能するためには、`docker`グループにボリュームへのフルアクセスが必要です:

```shell
getfacl $GITLAB_HOME

# file: $GITLAB_HOME
# owner: XXXX
# group: XXXX
user::rwx
group::rwx
group:docker:rwx
mask::rwx
default:user::rwx
default:group::rwx
default:group:docker:rwx
default:mask::rwx
default:other::r-x
```

これらの値が正しくない場合は、次のコマンドで設定します:

```shell
sudo setfacl -mR default:group:docker:rwx $GITLAB_HOME
```

デフォルトグループの名前は`docker`です。グループ名を変更した場合は、コマンドを調整する必要があります。

## `/dev/shm`マウントにDockerコンテナ内の十分なスペースがない {#devshm-mount-not-having-enough-space-in-docker-container}

GitLabには、GitLabのヘルスとパフォーマンスに関する統計情報を公開するためのPrometheusメトリクスエンドポイントが`/-/metrics`に付属しています。これに必要なファイルは、一時ファイルシステム（`/run`や`/dev/shm`など）に書き込まれます。

デフォルトでは、Dockerは共有メモリーディレクトリ（`/dev/shm`にマウント）に64 MBを割り当てます。これは、生成されたすべてのPrometheusメトリクス関連ファイルを保持するには不十分であり、次のようなエラーログが生成されます:

```plaintext
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
```

**管理者**エリアでPrometheusメトリクスをオフにできますが、この問題を解決するための推奨される解決策は、少なくとも256 MBの共有メモリを設定して[インストール](configuration.md#pre-configure-docker-container)することです。`docker run`を使用する場合は、スイッチ`--shm-size 256m`を渡すことができます。`docker-compose.yml`ファイルを使用する場合は、`shm_size`キーを設定できます。

## Dockerコンテナは、`json-file`が原因でスペースを使い果たします {#docker-containers-exhausts-space-due-to-the-json-file}

Dockerは[`json-file`デフォルトのログドライバー](https://docs.docker.com/config/containers/logging/configure/#configure-the-default-logging-driver)を使用しますが、デフォルトではログローテーションを実行しません。このログローテーションの欠如の結果として、`json-file`ドライバーによって保存されたログファイルは、大量の出力を生成するコンテナに対してかなりの量のディスク領域を消費する可能性があります。これにより、ディスク容量が不足する可能性があります。これに対処するには、可能であれば、ログドライバーとして[`journald`](https://docs.docker.com/config/containers/logging/journald/)を使用するか、ネイティブログローテーションをサポートする[別のサポートされているドライバー](https://docs.docker.com/config/containers/logging/configure/#supported-logging-drivers)を使用します。

## Dockerの起動時にバッファオーバーフローエラーが発生しました {#buffer-overflow-error-when-starting-docker}

このバッファオーバーフローエラーが発生した場合は、`/var/log/gitlab`の古いログファイルをパージする必要があります:

```plaintext
buffer overflow detected : terminated
xargs: tail: terminated by signal 6
```

古いログファイルを削除すると、エラーを修正し、インスタンスのクリーンな起動を確実にできます。

## ThreadErrorはスレッド操作を作成できません許可されていません {#threaderror-cant-create-thread-operation-not-permitted}

```plaintext
can't create Thread: Operation not permitted
```

このエラーは、[clone3関数をサポートしていないホスト](https://github.com/moby/moby/issues/42680)で、新しい`glibc`バージョンでビルドされたコンテナを実行すると発生します。GitLab 16.0以降では、コンテナイメージには、新しい`glibc`バージョンでビルドされたUbuntu 22.04 Linuxパッケージが含まれています。

この問題は、[Docker 20.10.10](https://github.com/moby/moby/pull/42836)のような新しいコンテナランタイムツールでは発生しません。

このイシューを解決するには、Dockerをバージョン20.10.10以降にアップデートしてください。
