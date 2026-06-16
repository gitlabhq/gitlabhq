---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dockerコンテナで実行されているGitLabのトラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabをDockerコンテナにインストールする際、以下の問題が発生する可能性があります。

## 潜在的な問題の診断 {#diagnose-potential-problems}

Dockerコンテナ内のGitLabインスタンスのトラブルシューティング時に、以下のコマンドが役立ちます:

コンテナログの読み取り:

```shell
sudo docker logs gitlab
```

実行中のコンテナに入る:

```shell
sudo docker exec -it gitlab /bin/bash
```

[Linux package installation](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/README.md)を管理するのと同じように、コンテナ内からGitLabコンテナを管理できます。

## 500内部エラー {#500-internal-error}

Dockerイメージを更新する際、すべてのパスが`500`ページを表示する問題に遭遇する場合があります。この問題が発生した場合は、コンテナを再起動してください:

```shell
sudo docker restart gitlab
```

## パーミッションの問題 {#permission-problems}

古いGitLab Dockerイメージから更新する際、パーミッションの問題に遭遇する可能性があります。これは、以前のイメージでユーザー権限が正しく保持されなかった場合に発生します。すべてのファイルのパーミッションを修正するスクリプトがあります。

コンテナを修正するには、`update-permissions`を実行してからコンテナを再起動してください:

```shell
sudo docker exec gitlab update-permissions
sudo docker restart gitlab
```

## リソース`ruby_block`でアクション実行中にエラー {#error-executing-action-run-on-resource-ruby_block}

このエラーは、WindowsまたはMacでOracle VirtualBoxとDocker Toolboxを使用し、Dockerボリュームを利用している場合に発生します:

```plaintext
Error executing action run on resource ruby_block[directory resource: /data/GitLab]
```

`/c/Users`ボリュームはVirtualBox共有フォルダーとしてマウントされており、すべてのPOSIXファイルシステム機能をサポートしていません。ディレクトリの所有権とパーミッションは再マウントせずに変更できず、GitLabは失敗します。

Docker Toolboxを使用する代わりに、お使いのプラットフォームのネイティブなDockerインストールを使用してください。

ネイティブのDockerインストールを使用できない場合（Windows 10 Home Edition、またはWindows 7/8）、代替策として、Docker Toolbox Boot2docker用にVirtualBox共有の代わりにNFSマウントを設定する方法があります。

## Linux ACLの問題 {#linux-acl-issues}

DockerホストでファイルACLを使用している場合、GitLabが機能するためには、`docker`グループがボリュームへのフルアクセスを必要とします:

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

これらの値が正しくない場合は、以下で設定してください:

```shell
sudo setfacl -mR default:group:docker:rwx $GITLAB_HOME
```

デフォルトグループの名前は`docker`です。グループ名を変更した場合は、コマンドを調整する必要があります。

## `/dev/shm`マウントがDockerコンテナ内で十分なスペースを持っていない {#devshm-mount-not-having-enough-space-in-docker-container}

GitLabには、GitLabの健全性とパフォーマンスに関する統計を公開するために、`/-/metrics`にPrometheusメトリクスエンドポイントが付属しています。これに必要なファイルは、一時ファイルシステム（`/run`や`/dev/shm`など）に書き込まれます。

デフォルトでは、Dockerは共有メモリディレクトリ（`/dev/shm`にマウント）に64 MBを割り当てます。これは、生成されるすべてのPrometheusメトリクス関連ファイルを保持するには不十分であり、以下のようなエラーログが生成されます:

```plaintext
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/gauge_all_sidekiq_0-1.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
writing value to /dev/shm/gitlab/sidekiq/histogram_sidekiq_0-0.db failed with unmapped file
```

**管理者**エリアでPrometheusメトリクスをオフにすることはできますが、この問題を修正するための推奨される解決策は、共有メモリを少なくとも256 MBに設定して[install](configuration.md#pre-configure-docker-container)することです。`docker run`を使用する場合、`--shm-size 256m`フラグを渡すことができます。`docker-compose.yml`ファイルを使用する場合、`shm_size`キーを設定できます。

## Dockerコンテナが`json-file`によりスペースを使い果たす {#docker-containers-exhausts-space-due-to-the-json-file}

Dockerは[`json-file`デフォルトロギングドライバー](https://docs.docker.com/config/containers/logging/configure/#configure-the-default-logging-driver)を使用します。これはデフォルトではログのローテーションを行いません。このローテーション不足の結果、`json-file`ドライバーによって保存されたログファイルは、多くの出力を生成するコンテナにとって、かなりのディスクスペースを消費する可能性があります。これはディスクスペースの枯渇につながる可能性があります。これに対処するには、利用可能な場合は[`journald`](https://docs.docker.com/config/containers/logging/journald/)をロギングドライバーとして使用するか、ネイティブのローテーションをサポートする[別のサポートされているドライバー](https://docs.docker.com/config/containers/logging/configure/#supported-logging-drivers)を使用してください。

## Docker起動時のバッファオーバーフローエラー {#buffer-overflow-error-when-starting-docker}

このバッファオーバーフローエラーが発生した場合は、`/var/log/gitlab`内の古いログファイルをパージする必要があります:

```plaintext
buffer overflow detected : terminated
xargs: tail: terminated by signal 6
```

古いログファイルを削除するとエラーの修正に役立ち、インスタンスのクリーンな起動が保証されます。

## 以前のインストールからのデータを再利用する際のエラー {#errors-when-reusing-data-from-a-previous-installation}

別のインスタンスからデータを再利用する際に、以下の問題が発生する可能性があります。

### 起動時の`stat: missing operand`エラー {#stat-missing-operand-error-on-startup}

このエラーは、Linuxパッケージインストールから移行する際に、`git-data/repositories`ディレクトリがホストボリューム内にないか、壊れたシンボリックリンクである場合に発生します:

```plaintext
stat: missing operand
Expected process to exit with [0], but received '1'
Ran stat --printf='%U' $(readlink -f /var/opt/gitlab/git-data/repositories) returned 1
```

ホスト上で、不足しているディレクトリを作成し、コンテナを再起動します:

```shell
sudo mkdir -p $GITLAB_HOME/data/git-data/repositories
sudo docker restart <container_name>
```

完全な移行ガイドについては、[LinuxパッケージGitLabインスタンスをDockerに移行する](migrate.md)を参照してください。

### コンテナがすぐに終了し、再起動ループによって`docker exec`がブロックされる {#container-exits-immediately-and-restart-loop-blocks-docker-exec}

コンテナが起動に失敗し、再起動を繰り返す場合、調査のために`docker exec`を使用することはできません。代わりに、イメージ内で直接Shellを起動してください:

```shell
docker run --rm -it --entrypoint /bin/bash gitlab/gitlab-ee:<version>
```

このShellを使用して、予期されるディレクトリ構造を検査し、ホストにマウントされているボリュームと比較してください。

## ThreadError can't create Thread Operation not permitted {#threaderror-cant-create-thread-operation-not-permitted}

```plaintext
can't create Thread: Operation not permitted
```

このエラーは、新しい`glibc`バージョンでビルドされたコンテナを[clone3関数をサポートしないホスト](https://github.com/moby/moby/issues/42680)で実行している場合に発生します。GitLab 16.0以降では、コンテナイメージにはUbuntu 22.04 Linuxパッケージが含まれており、これは新しい`glibc`バージョンでビルドされています。

この問題は、[Docker 20.10.10](https://github.com/moby/moby/pull/42836)のような新しいコンテナランタイムツールでは発生しません。

この問題を解決するには、Dockerをバージョン20.10.10以降に更新してください。
