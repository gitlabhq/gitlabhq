---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Docker-in-Dockerでレジストリで認証する
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Docker-in-Dockerを使用する場合、サービスで新しい Docker デーモンが起動されるため、[標準認証方式](using_docker_images.md#access-an-image-from-a-private-container-registry)は機能しません。

## オプション1:`docker login` を実行

[`before_script`](../yaml/_index.md#before_script) で、`docker login` を実行します:

```yaml
default:
  image: docker:24.0.5
  services:
    - docker:24.0.5-dind

variables:
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  before_script:
    - echo "$DOCKER_REGISTRY_PASS" | docker login $DOCKER_REGISTRY --username $DOCKER_REGISTRY_USER --password-stdin
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

Docker Hub にサインインするには、`$DOCKER_REGISTRY` を空のままにするか、削除します。

## オプション2:各ジョブに `~/.docker/config.json` をマウントする

GitLab Runner の管理者である場合は、`~/.docker/config.json` に認証設定ファイルがマウントできます。すると、Runner が取得するすべてのジョブは既に認証されています。公式の `docker:24.0.5` イメージを使用している場合、ホームディレクトリは `/root` の下にあります。

設定ファイルをマウントすると、`~/.docker/config.json` を変更する `docker` コマンドは失敗します。たとえば、ファイルが読み取り専用としてマウントされているため、`docker login` は失敗します。読み取り専用から変更しないでください。問題が発生する原因となります。

次に、[`DOCKER_AUTH_CONFIG`](using_docker_images.md#determine-your-docker_auth_config-data) ドキュメントに従う `/opt/.docker/config.json` の例を示します。

```json
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ="
        }
    }
}
```

### Docker

ファイルを含めるように [ボリュームマウント](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#volumes-in-the-runnersdocker-section) を更新します。

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    volumes = ["/opt/.docker/config.json:/root/.docker/config.json:ro"]
```

### Kubernetes

このファイルの内容で [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) を作成します。これは、次のようなコマンドで実行できます:

```shell
kubectl create configmap docker-client-config --namespace gitlab-runner --from-file /opt/.docker/config.json
```

ファイルを含めるように [ボリュームマウント](https://docs.gitlab.com/runner/executors/kubernetes/#custom-volume-mount) を更新します。

```toml
[[runners]]
  ...
  executor = "kubernetes"
  [runners.kubernetes]
    image = "alpine:3.12"
    privileged = true
    [[runners.kubernetes.volumes.config_map]]
      name = "docker-client-config"
      mount_path = "/root/.docker/config.json"
      # If you are running GitLab Runner 13.5
      # or lower you can remove this
      sub_path = "config.json"
```

## オプション3:`DOCKER_AUTH_CONFIG` を使用

既に [`DOCKER_AUTH_CONFIG`](using_docker_images.md#determine-your-docker_auth_config-data) が定義されている場合は、変数を使用して `~/.docker/config.json` に保存できます。

この認証は、次のようないくつかの方法で定義できます:

- Runner 設定ファイルの [`pre_build_script`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section) で。
- [`before_script`](../yaml/_index.md#before_script) で。
- [`script`](../yaml/_index.md#script) で。

次の例は [`before_script`](../yaml/_index.md#before_script) を示しています。同じコマンドは、実装するソリューションにも適用されます。

```yaml
default:
  image: docker:24.0.5
  services:
    - docker:24.0.5-dind

variables:
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  before_script:
    - mkdir -p $HOME/.docker
    - echo $DOCKER_AUTH_CONFIG > $HOME/.docker/config.json
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```
