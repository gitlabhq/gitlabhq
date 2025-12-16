---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dockerビルドのトラブルシューティング
---

## エラー: `docker: Cannot connect to the Docker daemon at tcp://docker:2375` {#error-docker-cannot-connect-to-the-docker-daemon-at-tcpdocker2375}

このエラーは、[Docker-in-Docker](using_docker_build.md#use-docker-in-docker) v19.03以降を使用している場合によく発生します:

```plaintext
docker: Cannot connect to the Docker daemon at tcp://docker:2375. Is the docker daemon running?
```

このエラーは、DockerがTLSで自動的に起動するために発生します。

- 初めて設定する場合は、[DockerイメージでDocker executorを使用する](using_docker_build.md#use-docker-in-docker)を参照してください。
- v18.09以前からアップグレードする場合は、[アップグレードガイド](https://about.gitlab.com/blog/2019/07/31/docker-in-docker-with-docker-19-dot-03/)を参照してください。

このエラーは、Docker-in-Dockerサービスが完全に起動する前にアクセスしようとした場合に、[Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/#using-dockerdind)でも発生する可能性があります。詳細については、[イシュー27215](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27215)を参照してください。

## Dockerの`no such host`エラー {#docker-no-such-host-error}

`docker: error during connect: Post https://docker:2376/v1.40/containers/create: dial tcp: lookup docker on x.x.x.x:53: no such host`というエラーが表示されることがあります。

この問題は、サービスイメージ名に[レジストリホスト名が含まれている](../services/_index.md#available-settings-for-services)場合に発生する可能性があります。例: 

```yaml
default:
  image: docker:24.0.5-cli
  services:
    - registry.hub.docker.com/library/docker:24.0.5-dind
```

サービスのホスト名は[完全なイメージ名から派生](../services/_index.md#accessing-the-services)します。ただし、より短いサービスホスト名`docker`が想定されています。サービスの解決とアクセスを許可するには、サービス名`docker`の明示的なエイリアスを追加します:

```yaml
default:
  image: docker:24.0.5-cli
  services:
    - name: registry.hub.docker.com/library/docker:24.0.5-dind
      alias: docker
```

## エラー: `Cannot connect to the Docker daemon at unix:///var/run/docker.sock` {#error-cannot-connect-to-the-docker-daemon-at-unixvarrundockersock}

`dind`サービスにアクセスするために`docker`コマンドを実行しようとすると、次のエラーが発生する可能性があります:

```shell
$ docker ps
Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
```

ジョブに次の環境変数が定義されていることを確認してください:

- `DOCKER_HOST`
- `DOCKER_TLS_CERTDIR`（オプション）
- `DOCKER_TLS_VERIFY`（オプション）

Dockerクライアントを提供するイメージをアップデートすることもできます。たとえば、[`docker/compose`イメージは廃止されている](https://hub.docker.com/r/docker/compose)ため、[`docker`](https://hub.docker.com/_/docker)に置き換える必要があります。

[Runnerイシュー30944](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30944#note_1514250909)で説明されているように、このエラーは、ジョブが以前に非推奨の[Docker `--link`パラメータ](https://docs.docker.com/network/links/#environment-variables)から派生した環境変数（`DOCKER_PORT_2375_TCP`など）に依存していた場合に発生する可能性があります。次の場合、ジョブはこのエラーで失敗します:

- CI/CDイメージが、`DOCKER_PORT_2375_TCP`などのレガシー変数に依存している。
- [Runner機能フラグ`FF_NETWORK_PER_BUILD`](https://docs.gitlab.com/runner/configuration/feature-flags.html)が`true`に設定されている。
- `DOCKER_HOST`が明示的に設定されてない。

## エラー: `unauthorized: incorrect username or password` {#error-unauthorized-incorrect-username-or-password}

このエラーは、非推奨の変数である`CI_BUILD_TOKEN`を使用すると表示されます:

```plaintext
Error response from daemon: Get "https://registry-1.docker.io/v2/": unauthorized: incorrect username or password
```

ユーザーがこのエラーを受け取らないようにするには、次のようにする必要があります:

- 代わりに[CI_JOB_TOKEN](../jobs/ci_job_token.md)を使用する。
- `gitlab-ci-token/CI_BUILD_TOKEN`から`$CI_REGISTRY_USER/$CI_REGISTRY_PASSWORD`に変更する。

## 接続中に`no such host`エラーが発生した場合 {#error-during-connect-no-such-host}

このエラーは、`dind`サービスの起動に失敗した場合に表示されます:

```plaintext
error during connect: Post "https://docker:2376/v1.24/auth": dial tcp: lookup docker on 127.0.0.11:53: no such host
```

ジョブログを確認して、`mount: permission denied (are you root?)`が表示されているかどうかを確認します。例: 

```plaintext
Service container logs:
2023-08-01T16:04:09.541703572Z Certificate request self-signature ok
2023-08-01T16:04:09.541770852Z subject=CN = docker:dind server
2023-08-01T16:04:09.556183222Z /certs/server/cert.pem: OK
2023-08-01T16:04:10.641128729Z Certificate request self-signature ok
2023-08-01T16:04:10.641173149Z subject=CN = docker:dind client
2023-08-01T16:04:10.656089908Z /certs/client/cert.pem: OK
2023-08-01T16:04:10.659571093Z ip: can't find device 'ip_tables'
2023-08-01T16:04:10.660872131Z modprobe: can't change directory to '/lib/modules': No such file or directory
2023-08-01T16:04:10.664620455Z mount: permission denied (are you root?)
2023-08-01T16:04:10.664692175Z Could not mount /sys/kernel/security.
2023-08-01T16:04:10.664703615Z AppArmor detection and --privileged mode might break.
2023-08-01T16:04:10.665952353Z mount: permission denied (are you root?)
```

これは、GitLab Runnerに`dind`サービスを開始する権限がないことを示しています:

1. `privileged = true`が`config.toml`で設定されていることを確認してください。
1. これらの特権Runnerを使用するには、CIジョブに適切なRunnerタグがあることを確認してください。

## エラー: `cgroups: cgroup mountpoint does not exist: unknown` {#error-cgroups-cgroup-mountpoint-does-not-exist-unknown}

Docker Engine 20.10によって導入された既知の非互換性があります。

ホストがDocker Engineバージョン20.10 以降を使用している場合、20.10よりも前のバージョンの`docker:dind`サービスは期待どおりに動作しません。

サービス自体は問題なく起動しますが、コンテナイメージを構築しようとすると、次のエラーが発生します:

```plaintext
cgroups: cgroup mountpoint does not exist: unknown
```

この問題を解決するには、`docker:dind`コンテナを少なくとも20.10.xバージョン（`docker:24.0.5-dind`など）にアップデートします。

反対の構成（`docker:24.0.5-dind`サービスと、バージョン19.06.x以前のホスト上のDocker Engine）は、問題なく動作します。最適な方針は、ジョブ環境のバージョンを頻繁にテストして最新のものにアップデートすることです。これにより、新機能を利用でき、セキュリティが強化されます。また、この特定のケースでは、Runnerホスト上の基盤となるDocker Engineのアップグレードがジョブに対して透過的になります。

## エラー: `failed to verify certificate: x509: certificate signed by unknown authority` {#error-failed-to-verify-certificate-x509-certificate-signed-by-unknown-authority}

このエラーは、カスタムまたはプライベート証明書（Zscaler証明書など）が使用されているDocker-in-Docker環境で、`docker build`や`docker pull`などのDockerコマンドが実行された場合に表示されることがあります:

```plaintext
error pulling image configuration: download failed after attempts=6: tls: failed to verify certificate: x509: certificate signed by unknown authority
```

このエラーは、Docker-in-Docker環境のDockerコマンドが2つの異なるコンテナを使用するために発生します:

- **build container**（ビルドコンテナ）はDockerクライアント（`/usr/bin/docker`）を実行し、ジョブのスクリプトコマンドを実行します。
- **service container**（サービスコンテナ）（多くの場合、`svc`という名前）は、ほとんどのDockerコマンドを処理するDockerデーモンを実行します。

組織がカスタム証明書を使用している場合、両方のコンテナにこれらの証明書が必要です。両方のコンテナで適切な証明書が設定されていないと、外部レジストリまたはサービスに接続するDocker操作は証明書エラーで失敗します。

この問題を解決するには、次のようにします:

1. ルート証明書を`CA_CERTIFICATE`という名前の[CI/CD変数](../variables/_index.md#define-a-cicd-variable-in-the-ui)として保存します。証明書は次の形式である必要があります:

   ```plaintext
   -----BEGIN CERTIFICATE-----
   (certificate content)
   -----END CERTIFICATE-----
   ```

1. Dockerデーモンを起動する前に、証明書をサービスコンテナにインストールするように、パイプラインを設定します。例: 

   ```yaml
   image_build:
     stage: build
     image:
       name: docker:19.03
     variables:
       DOCKER_HOST: tcp://localhost:2375
       DOCKER_TLS_CERTDIR: ""
       CA_CERTIFICATE: "$CA_CERTIFICATE"
     services:
       - name: docker:19.03-dind
         command:
           - /bin/sh
           - -c
           - |
             echo "$CA_CERTIFICATE" > /usr/local/share/ca-certificates/custom-ca.crt && \
             update-ca-certificates && \
             dockerd-entrypoint.sh || exit
     script:
       - docker info
       - docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD $DOCKER_REGISTRY
       - docker build -t "${DOCKER_REGISTRY}/my-app:${CI_COMMIT_REF_NAME}" .
       - docker push "${DOCKER_REGISTRY}/my-app:${CI_COMMIT_REF_NAME}"
   ```
