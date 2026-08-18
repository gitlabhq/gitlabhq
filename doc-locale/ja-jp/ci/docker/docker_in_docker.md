---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Docker-in-Dockerを使用する
description: Docker-in-Dockerを、DockerまたはKubernetes executorを使用してGitLab CI/CDジョブ用に構成します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Docker-in-Docker（`dind`）とは、登録されたRunnerが[Docker executor](https://docs.gitlab.com/runner/executors/docker/)または[Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/)を使用することを意味します。executorは、Dockerが提供する[Dockerのコンテナイメージ](https://hub.docker.com/_/docker/)を使用して、CI/CDジョブを実行する。

Dockerイメージには、すべての`docker`ツールが含まれており、イメージのコンテキストで、特権モードでジョブスクリプトを実行できます。

常に、`docker:24.0.5`のように、イメージの特定のバージョンを固定してください。`docker:latest`のようなタグを使用する場合、どのバージョンが使用されるかを制御できません。この操作は、新しいバージョンがリリースされたときに、互換性の問題を引き起こす可能性があります。

## Docker executorでの使用 {#use-with-docker-executor}

Docker executorを使用して、Dockerコンテナでジョブを実行できます。

### Docker executorでTLSが有効なDocker-in-Docker（推奨） {#docker-in-docker-with-tls-enabled-in-the-docker-executor-recommended}

Dockerデーモンは、TLS経由の接続をサポートしています。可能な場合はTLSを使用してください。TLSはDocker 19.03.12以降のデフォルトであり、[GitLab.comインスタンスRunner](../runners/_index.md)でサポートされています。

> [!warning]
> このタスクは`--docker-privileged`を有効にします。これにより、コンテナのセキュリティメカニズムが実質的に無効になり、ホストが権限昇格にさらされます。このアクションにより、コンテナのブレイクアウトが発生する可能性があります。詳細については、[Runtime privilege and Linux capabilities](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities)（ランタイム特権とLinux機能）を参照してください。

次の手順で、TLSを有効にしてDocker-in-Dockerを使用できます。

1. [GitLab Runner](https://docs.gitlab.com/runner/install/)をインストールします。
1. 次のように、コマンドラインからGitLab Runnerを登録します。`docker`および`privileged`モードを使用します。

   ```shell
   sudo gitlab-runner register -n \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --tag-list "tls-docker-runner" \
     --docker-image "docker:24.0.5-cli" \
     --docker-privileged \
     --docker-volumes "/certs/client"
   ```

   - このコマンドは、（ジョブレベルで指定されていない場合）`docker:24.0.5-cli`イメージを使用するように新しいRunnerを登録します。ビルドコンテナとサービスコンテナを起動するには、`privileged`モードを使用します。Docker-in-Dockerを使用する場合は、Dockerコンテナで常に`privileged = true`を使用する必要があります。
   - このコマンドは、`/certs/client`をサービスコンテナとビルドコンテナにマウントします。これは、Dockerクライアントがそのディレクトリ内の証明書を使用するために必要です。詳細については、[Dockerイメージのドキュメント](https://hub.docker.com/_/docker/)を参照してください。

   前述のコマンドは、次の例のような`config.toml`エントリを作成します。

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:24.0.5-cli"
       privileged = true
       disable_cache = false
       volumes = ["/certs/client", "/cache"]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. これで、ジョブスクリプトで`docker`を使用できるようになりました。`docker:24.0.5-dind`サービスを含めます:

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - docker:24.0.5-dind
     before_script:
       - docker info

   variables:
     # When you use the dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket. Docker 19.03 does this automatically
     # by setting the DOCKER_HOST in
     # https://github.com/docker-library/docker/blob/d45051476babc297257df490d22cbd806f1b11e4/19.03/docker-entrypoint.sh#L23-L29
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services.
     #
     # Specify to Docker where to create the certificates. Docker
     # creates them automatically on boot, and creates
     # `/certs/client` to share between the service and job
     # container, thanks to volume mount from config.toml
     DOCKER_TLS_CERTDIR: "/certs"

   build:
     stage: build
     tags:
       - tls-docker-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

### Docker executorでTLSが無効になっているDocker-in-Docker {#docker-in-docker-with-tls-disabled-in-the-docker-executor}

場合によっては、TLSを無効にする正当な理由があります。たとえば、使用しているGitLab Runnerの設定を制御できない場合などです。

1. 次のように、コマンドラインからGitLab Runnerを登録します。`docker`および`privileged`モードを使用します。

   ```shell
   sudo gitlab-runner register -n \
     --url "https://gitlab.com/" \
     --registration-token REGISTRATION_TOKEN \
     --executor docker \
     --description "My Docker Runner" \
     --tag-list "no-tls-docker-runner" \
     --docker-image "docker:24.0.5-cli" \
     --docker-privileged
   ```

   前述のコマンドは、次の例のような`config.toml`エントリを作成します。

   ```toml
   [[runners]]
     url = "https://gitlab.com/"
     token = TOKEN
     executor = "docker"
     [runners.docker]
       tls_verify = false
       image = "docker:24.0.5-cli"
       privileged = true
       disable_cache = false
       volumes = ["/cache"]
     [runners.cache]
       [runners.cache.s3]
       [runners.cache.gcs]
   ```

1. ジョブスクリプトに`docker:24.0.5-dind`サービスを含めます。

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - docker:24.0.5-dind
     before_script:
       - docker info

   variables:
     # When using dind service, you must instruct docker to talk with the
     # daemon started inside of the service. The daemon is available with
     # a network connection instead of the default /var/run/docker.sock socket.
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services
     #
     DOCKER_HOST: tcp://docker:2375
     #
     # This instructs Docker not to start over TLS.
     DOCKER_TLS_CERTDIR: ""

   build:
     stage: build
     tags:
       - no-tls-docker-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

### Docker-in-Dockerとビルドコンテナ間で共有するボリューム上でUnixソケットを使用する {#use-a-unix-socket-on-a-shared-volume-between-docker-in-docker-and-build-container}

[Docker executorでTLSを有効にしたDocker-in-Docker](#docker-in-docker-with-tls-enabled-in-the-docker-executor-recommended)のアプローチでは、`volumes = ["/certs/client", "/cache"]`で定義されたディレクトリは、[ビルド間で永続](https://docs.gitlab.com/runner/executors/docker/#persistent-storage)します。Docker executor Runnerを使用する複数のCI/CDジョブでDocker-in-Dockerサービスが有効になっている場合、各ジョブが同じディレクトリパスに書き込みます。このアプローチでは、競合が発生する可能性があります。

この競合に対処するには、Docker-in-Dockerサービスとビルドコンテナの間で共有されるボリューム上でUnixソケットを使用します。このアプローチは、パフォーマンスを向上させ、サービスとクライアント間の安全な接続を確立します。

以下は、ビルドコンテナとサービスコンテナ間で共有される一時ボリュームを設定した`config.toml`のサンプルです。

```toml
[[runners]]
  url = "https://gitlab.com/"
  token = TOKEN
  executor = "docker"
  [runners.docker]
    image = "docker:24.0.5-cli"
    privileged = true
    volumes = ["/runner/services/docker"] # Temporary volume shared between build and service containers.
```

Docker-in-Dockerサービスは`docker.sock`を作成します。Dockerクライアントは、このDocker Unixソケットボリュームを介して`docker.sock`に接続します。

```yaml
job:
  variables:
    # This variable is shared by both the DinD service and Docker client.
    # For the service, it will instruct DinD to create `docker.sock` here.
    # For the client, it tells the Docker client which Docker Unix socket to connect to.
    DOCKER_HOST: "unix:///runner/services/docker/docker.sock"
  services:
    - docker:24.0.5-dind
  image: docker:24.0.5-cli
  script:
    - docker version
```

### Docker executorでプロキシが有効になっているDocker-in-Docker {#docker-in-docker-with-proxy-enabled-in-the-docker-executor}

`docker push`コマンドを使用するには、プロキシの設定が必要になる場合があります。

詳細については、[dindサービスの使用時のプロキシ設定](https://docs.gitlab.com/runner/configuration/proxy/#proxy-settings-when-using-dind-service)を参照してください。

## Kubernetes executorでの使用 {#use-with-kubernetes-executor}

[Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/)を使用して、Dockerコンテナでジョブを実行できます。

### KubernetesでTLSが有効なDocker-in-Docker（推奨） {#docker-in-docker-with-tls-enabled-in-kubernetes-recommended}

次の手順で、KubernetesでTLSを有効にしてDocker-in-Dockerを使用できます。

1. [Helmチャート](https://docs.gitlab.com/runner/install/kubernetes/)を使用して、[`values.yml`ファイル](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137)を更新し、ボリュームマウントを指定します。

   ```yaml
   runners:
     tags: "tls-dind-kubernetes-runner"
     config: |
       [[runners]]
         [runners.kubernetes]
           image = "ubuntu:20.04"
           privileged = true
         [[runners.kubernetes.volumes.empty_dir]]
           name = "docker-certs"
           mount_path = "/certs/client"
           medium = "Memory"
   ```

1. ジョブに`docker:24.0.5-dind`サービスを含めます。

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - name: docker:24.0.5-dind
         variables:
           HEALTHCHECK_TCP_PORT: "2376"
     before_script:
       - docker info

   variables:
     # When using dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket.
     DOCKER_HOST: tcp://docker:2376
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services.
     #
     # Specify to Docker where to create the certificates. Docker
     # creates them automatically on boot, and creates
     # `/certs/client` to share between the service and job
     # container, thanks to volume mount from config.toml
     DOCKER_TLS_CERTDIR: "/certs"
     # These are usually specified by the entrypoint, however the
     # Kubernetes executor doesn't run entrypoints
     # https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4125
     DOCKER_TLS_VERIFY: 1
     DOCKER_CERT_PATH: "$DOCKER_TLS_CERTDIR/client"

   build:
     stage: build
     tags:
       - tls-dind-kubernetes-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

### KubernetesでTLSが無効になっているDocker-in-Docker {#docker-in-docker-with-tls-disabled-in-kubernetes}

KubernetesでTLSを無効にしてDocker-in-Dockerを使用するには、前述の例を次のように変更する必要があります。

- `values.yml`ファイルから`[[runners.kubernetes.volumes.empty_dir]]`セクションを削除する。
- `DOCKER_HOST: tcp://docker:2375`を指定し、ポートを`2376`から`2375`に変更する。
- `DOCKER_TLS_CERTDIR: ""`を指定し、TLSを無効にしてDockerを起動するように指示する。

例: 

1. [Helmチャート](https://docs.gitlab.com/runner/install/kubernetes/)を使用して、[`values.yml`ファイル](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/00c1a2098f303dffb910714752e9a981e119f5b5/values.yaml#L133-137)を更新します。

   ```yaml
   runners:
     tags: "no-tls-dind-kubernetes-runner"
     config: |
       [[runners]]
         [runners.kubernetes]
           image = "ubuntu:20.04"
           privileged = true
   ```

1. これで、ジョブスクリプトで`docker`を使用できるようになりました。`docker:24.0.5-dind`サービスを含めます:

   ```yaml
   default:
     image: docker:24.0.5-cli
     services:
       - name: docker:24.0.5-dind
         variables:
           HEALTHCHECK_TCP_PORT: "2375"
     before_script:
       - docker info

   variables:
     # When using dind service, you must instruct Docker to talk with
     # the daemon started inside of the service. The daemon is available
     # with a network connection instead of the default
     # /var/run/docker.sock socket.
     DOCKER_HOST: tcp://docker:2375
     #
     # The 'docker' hostname is the alias of the service container as described at
     # https://docs.gitlab.com/ci/services/#accessing-the-services.
     #
     # This instructs Docker not to start over TLS.
     DOCKER_TLS_CERTDIR: ""
   build:
     stage: build
     tags:
       - no-tls-dind-kubernetes-runner
     script:
       - docker build -t my-docker-image .
       - docker run my-docker-image /script/to/run/tests
   ```

## Docker-in-Dockerに関する既知の問題 {#known-issues-with-docker-in-docker}

Docker-in-Dockerは推奨される設定ですが、次の問題に注意してください。

- `docker-compose`コマンド: この設定において、デフォルトではこのコマンドは使用できません。ジョブスクリプトで`docker-compose`を使用するには、Docker Composeの[インストール手順](https://docs.docker.com/compose/install/)に従ってください。
- キャッシュ: 各ジョブは新しい環境で実行されます。各ビルドが独自のDockerエンジンインスタンスを取得するため、同時ジョブが競合を引き起こすことはありません。ただし、レイヤーがキャッシュされないため、ジョブが遅くなる可能性があります。[Dockerレイヤーキャッシュ](using_docker_build.md#docker-layer-caching)を参照してください。
- ストレージドライバー: デフォルトでは、以前のバージョンのDockerでは`vfs`ストレージドライバーを使用し、ジョブごとにファイルシステムをコピーします。Docker 17.09以降では`--storage-driver overlay2`を使用し、これが推奨されるストレージドライバーです。詳細については、[OverlayFSドライバーを使用する](using_docker_build.md#use-the-overlayfs-driver)を参照してください。
- ルートファイルシステム: `docker:24.0.5-dind`コンテナとRunnerコンテナはルートファイルシステムを共有しないため、ジョブの作業ディレクトリを子コンテナのマウントポイントとして使用できます。たとえば、子コンテナと共有するファイルがある場合は、`/builds/$CI_PROJECT_PATH`の下にサブディレクトリを作成し、それをマウントポイントとして使用できます。詳細については、[イシュー41227](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/41227)を参照してください。

  ```yaml
  variables:
    MOUNT_POINT: /builds/$CI_PROJECT_PATH/mnt
  script:
    - mkdir -p "$MOUNT_POINT"
    - docker run -v "$MOUNT_POINT:/mnt" my-docker-image
  ```
