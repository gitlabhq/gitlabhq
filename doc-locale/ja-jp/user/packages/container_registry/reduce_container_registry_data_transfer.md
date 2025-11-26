---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナレジストリのデータ転送を削減する
description: GitLabコンテナレジストリでのデータ転送量を削減するためのヒント。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コンテナレジストリからイメージまたはタグがダウンロードされる頻度によっては、データ転送量が非常に多くなることがあります。このページでは、コンテナレジストリでのデータ転送量を削減するための推奨事項とヒントを紹介します。

## データ転送量の確認 {#check-data-transfer-use}

転送量の使用状況は、GitLab UI内では確認できません。[GitLab-#350905](https://gitlab.com/gitlab-org/gitlab/-/issues/350905)は、この情報を表面化させる作業を追跡するエピックです。

## イメージサイズの決定 {#determine-image-size}

イメージのサイズを決定するには、以下のツールとテクニックを使用します:

- [Skopeo](https://github.com/containers/skopeo): Skopeo `inspect`コマンドを使用して、APIコールを通じてレイヤー数とサイズを調べます。したがって、`docker pull IMAGE`を実行する前に、このデータを調査できます。

- Docker in CI: Dockerでイメージをプッシュする前にGitLab CIを使用する際に、イメージサイズを調べて記録します。例: 

  ```shell
  docker inspect "$CI_REGISTRY_IMAGE:$IMAGE_TAG" \
        | awk '/"Size": ([0-9]+)[,]?/{ printf "Final Image Size: %d\n", $2 }'
  ```

- [Dive](https://github.com/wagoodman/dive)は、Dockerイメージ、レイヤーの内容を調査し、サイズを削減する方法を発見するためのツールです。

## イメージサイズの削減 {#reduce-image-size}

### より小さなベースイメージを使用する {#use-a-smaller-base-image}

[Alpine Linux](https://alpinelinux.org/)のような、より小さなベースイメージの使用を検討してください。Alpineイメージは約5MBで、[Debian](https://hub.docker.com/_/debian)のような一般的なベースイメージよりも数倍小さくなっています。アプリケーションがGo言語アプリケーションなどの自己完結型の静的バイナリとして配布されている場合は、Docker [scratch](https://hub.docker.com/_/scratch/)ベースイメージの使用も検討できます。

特定のベースイメージOSを使用する必要がある場合は、`-slim`または`-minimal`バリアントを探してください。これはイメージサイズの削減に役立ちます。

また、ベースイメージの上にインストールするオペレーティングシステムのパッケージにも注意してください。これらは数百MBにもなる可能性があります。インストールするパッケージの数を必要最小限に抑えるようにしてください。

[Multi-stage builds](#use-multi-stage-builds)は、一時的なビルド依存関係をクリーンアップする上で強力な味方となります。

次のようなツールを使用することも検討してください:

- [DockerSlim](https://github.com/docker-slim/docker-slim)は、コンテナイメージのサイズを削減するための一連のコマンドを提供します。
- [Distroless](https://github.com/GoogleContainerTools/distroless)イメージには、アプリケーションとそのランタイム依存関係のみが含まれています。標準的なLinuxディストリビューションで見られるようなパッケージマネージャー、Shell、その他のプログラムは含まれていません。

### レイヤーを最小限に抑える {#minimize-layers}

Dockerfileのすべての命令は新しいレイヤーにつながり、その命令中に適用されたファイルシステムの変更を記録します。一般的に、より多くの、またはより大きなレイヤーは、より大きなイメージにつながります。Dockerfileでパッケージをインストールするために、レイヤーの数を最小限に抑えるようにしてください。そうしないと、ビルドプロセス内の各ステップがイメージサイズを大きくする可能性があります。

レイヤーの数とサイズを削減するための複数の戦略があります。たとえば、インストールするオペレーティングシステムのパッケージごとに`RUN`コマンドを使用する代わりに（パッケージごとにレイヤーにつながります）、単一の`RUN`コマンドですべてのパッケージをインストールして、ビルドプロセスのステップ数を減らし、イメージのサイズを小さくすることができます。

もう1つの有用な戦略は、すべての一時的なビルド依存関係を削除し、パッケージのインストール前後にオペレーティングシステムのパッケージマネージャーのキャッシュを無効にするか、空にすることを確認することです。

イメージをビルドする際は、関連ファイルのみをコピーするようにしてください。Dockerの場合、[`.dockerignore`](https://docs.docker.com/reference/dockerfile/#dockerignore-file)を使用すると、ビルドプロセスで無関係なファイルが確実に無視されるようになります。

[DockerSlim](https://github.com/docker-slim/docker-slim)など、他のサードパーティツールを使用してイメージを縮小できます。不適切に使用すると、アプリケーションが特定の条件下で動作するために必要な依存関係が削除される可能性があることに注意してください。したがって、後でイメージを縮小しようとするのではなく、ビルドプロセス中にイメージを小さくするように努めることをお勧めします。

### マルチステージビルドを使用する {#use-multi-stage-builds}

[multi-stage builds](https://docs.docker.com/build/building/multi-stage/)では、Dockerfileで複数の`FROM`ステートメントを使用します。各`FROM`命令は異なるベースイメージを使用でき、それぞれが新しいビルドステージを開始します。あるステージから別のステージにアーティファクトを選択的にコピーして、最終的なイメージに不要なものをすべて残しておくことができます。これは、ビルド依存関係をインストールする必要があるが、最終的なイメージにそれらを存在させる必要がない場合に特に役立ちます。

## イメージプルポリシーを使用する {#use-an-image-pull-policy}

`docker`または`docker+machine` executorを使用する場合、[`pull_policy`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)パラメータをrunnerの`config.toml`に設定して、Dockerイメージをプルするときにrunnerがどのように動作するかを定義できます。大きくてめったに更新されないイメージを使用する際にデータの転送を回避するには、リモートレジストリからイメージをプルする際に`if-not-present`プルポリシーの使用を検討してください。

## Dockerレイヤーキャッシュを使用してください {#use-docker-layer-caching}

`docker build`を実行すると、`Dockerfile`内の各コマンドはレイヤーになります。これらのレイヤーはキャッシュとして保持され、変更がない場合は再利用できます。`docker build`コマンドのキャッシュソースとして使用するタグ付きイメージを指定するには、`--cache-from`引数を使用します。複数の`--cache-from`引数を使用すると、複数のイメージをキャッシュソースとして指定できます。これにより、ビルドを高速化し、転送されるデータ量を削減できます。詳細については、[Dockerレイヤーのキャッシュに関するドキュメント](../../../ci/docker/using_docker_build.md#make-docker-in-docker-builds-faster-with-docker-layer-caching)を参照してください。

## 自動化の頻度の確認 {#check-automation-frequency}

特定の間隔で定期的なタスクを実行するために、コンテナイメージにバンドルされた自動化スクリプトを作成することがよくあります。自動化がGitLab.com以外のサービスにGitLabレジストリからコンテナイメージをプルしている場合、これらの間隔の頻度を減らすことができます。

## 関連するイシュー {#related-issues}

- ベースイメージであるDockerイメージが更新されたときに、イメージをリビルドしたい場合があります。ただし、この機能を活用するには、[パイプラインのサブスクリプション制限が低すぎます](https://gitlab.com/gitlab-org/gitlab/-/issues/225278)。回避策として、毎日または1日に複数回リビルドできます。[GitLab-#225278](https://gitlab.com/gitlab-org/gitlab/-/issues/225278)は、このワークフローを支援するために制限の引き上げを提案しています。
