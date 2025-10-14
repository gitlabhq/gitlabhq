---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Docker-in-Dockerでレジストリに対して認証する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Docker-in-Dockerを使用する場合、サービスによって新しいDockerデーモンが起動されるため、[標準の認証方法](using_docker_images.md#access-an-image-from-a-private-container-registry)は機能しません。

## オプション1: `docker login`を実行する {#option-1-run-docker-login}

[`before_script`](../yaml/_index.md#before_script)で、`docker login`を実行します。

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

Docker Hubにサインインするには、`$DOCKER_REGISTRY`を空のままにするか、削除します。

## オプション2: 各ジョブで`~/.docker/config.json`をマウントする {#option-2-mount-dockerconfigjson-on-each-job}

GitLab Runnerの管理者は、認証設定を含むファイルを`~/.docker/config.json`にマウントできます。そうすると、Runnerが取得するすべてのジョブはすでに認証済みです。公式の`docker:24.0.5`イメージを使用している場合、ホームディレクトリは`/root`です。

設定ファイルをマウントした場合、`~/.docker/config.json`を変更する`docker`コマンドは失敗します。たとえば`docker login`は、ファイルが読み取り専用としてマウントされているために失敗します。読み取り専用属性を変更しないでください。問題を引き起こす原因となります。

次に示すのは、[`DOCKER_AUTH_CONFIG`](using_docker_images.md#determine-your-docker_auth_config-data)ドキュメントに従った`/opt/.docker/config.json`の例です。

```json
{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "bXlfdXNlcm5hbWU6bXlfcGFzc3dvcmQ="
        }
    }
}
```

### Docker {#docker}

ファイルを含めるように[ボリュームマウント](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#volumes-in-the-runnersdocker-section)を更新します。

```toml
[[runners]]
  ...
  executor = "docker"
  [runners.docker]
    ...
    privileged = true
    volumes = ["/opt/.docker/config.json:/root/.docker/config.json:ro"]
```

### Kubernetes {#kubernetes}

このファイルの内容で[ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/)を作成します。そのためには、次のようなコマンドを実行します。

```shell
kubectl create configmap docker-client-config --namespace gitlab-runner --from-file /opt/.docker/config.json
```

ファイルを含めるように[ボリュームマウント](https://docs.gitlab.com/runner/executors/kubernetes/#custom-volume-mount)を更新します。

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
      sub_path = "config.json"
```

## オプション3: `DOCKER_AUTH_CONFIG`を使用する {#option-3-use-docker_auth_config}

すでに[`DOCKER_AUTH_CONFIG`](using_docker_images.md#determine-your-docker_auth_config-data)が定義されている場合は、その変数を使用して、それを`~/.docker/config.json`に保存できます。

この認証は、次の複数の方法で定義できます。

- Runner設定ファイル内の[`pre_build_script`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)で定義する。
- [`before_script`](../yaml/_index.md#before_script)で定義する。
- [`script`](../yaml/_index.md#script)で定義する。

次の例は[`before_script`](../yaml/_index.md#before_script)を示しています。どの実装方法でも、同じコマンドが適用されます。

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
