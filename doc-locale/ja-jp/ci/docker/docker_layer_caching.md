---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Dockerレイヤーのキャッシュを使用して、Docker-in-Dockerのビルドを高速化する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Docker-in-Dockerを使用すると、ビルドを作成するたびに、Dockerはイメージのすべてのレイヤーをダウンロードします。Dockerの最新バージョン（Docker 1.13以降）では、`docker build`ステップ中に既存のイメージをキャッシュとして使用できます。これにより、ビルドプロセスが大幅に高速化されます。

Docker 27.0.1以降では、デフォルトの`docker`ビルドドライバーは、`containerd`イメージストアが有効になっている場合にのみキャッシュバックエンドをサポートします。

Docker 27.0.1以降でDockerキャッシュを使用するには、次のいずれかを実行します:

- Dockerデーモン設定で`containerd`イメージストアを有効にします。
- 別のビルドドライバーを選択します。

詳細については、[キャッシュストレージバックエンド](https://docs.docker.com/build/cache/backends/)を参照してください。

## Dockerキャッシュの仕組み {#how-docker-caching-works}

`docker build`を実行すると、`Dockerfile`内の各コマンドがレイヤーを作成します。これらのレイヤーはキャッシュとして保持され、変更がない場合は再利用できます。1つのレイヤーを変更すると、後続のすべてのレイヤーが再作成されます。

`docker build`コマンドのキャッシュソースとして使用するタグ付きイメージを指定するには、`--cache-from`引数を使用します。複数の`--cache-from`引数を使用すると、複数のイメージをキャッシュソースとして指定できます。

## Dockerインラインキャッシュの例 {#docker-inline-caching-example}

次の例の`.gitlab-ci.yml`ファイルは、デフォルトの`docker build`コマンドで`inline`キャッシュバックエンドを使用したDockerキャッシュの使用方法を示しています。

```yaml
default:
  image: docker:27.4.1
  services:
    - docker:27.4.1-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

variables:
  # Use TLS https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#tls-enabled
  DOCKER_HOST: tcp://docker:2376
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  script:
    - docker pull $CI_REGISTRY_IMAGE:latest || true
    - docker build --build-arg BUILDKIT_INLINE_CACHE=1 --cache-from $CI_REGISTRY_IMAGE:latest --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest
```

`build`ジョブの`script`セクション:

1. 最初のコマンドは、`docker build`コマンドのキャッシュとして使用できるように、レジストリからイメージをプルしようとします。`--cache-from`引数で使用されるイメージは、キャッシュソースとして使用する前に、（`docker pull`を使用して）プルする必要があります。
1. 2番目のコマンドは、プルされたイメージがキャッシュとして使用可能であればそれを使用して（`--cache-from $CI_REGISTRY_IMAGE:latest`引数を参照）、Dockerイメージをビルドし、タグを付けます。`--build-arg BUILDKIT_INLINE_CACHE=1`は、[インラインキャッシュ](https://docs.docker.com/build/cache/backends/inline/)を使用するようにDockerに指示し、ビルドキャッシュをイメージ自体に埋め込みます。
1. 最後の2つのコマンドは、タグ付けされたDockerイメージをコンテナレジストリにプッシュして、後続のビルドのキャッシュとしても使用できるようにします。

## Dockerレジストリキャッシュの例 {#docker-registry-caching-example}

Dockerビルドを、レジストリ内の専用キャッシュイメージに直接キャッシュできます。

次の例の`.gitlab-ci.yml`ファイルは、`docker buildx build`コマンドと`registry`キャッシュバックエンドでDockerキャッシュを使用する方法を示しています。より高度なキャッシュオプションについては、[キャッシュストレージバックエンド](https://docs.docker.com/build/cache/backends/)を参照してください。

```yaml
default:
  image: docker:27.4.1
  services:
    - docker:27.4.1-dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

variables:
  # Use TLS https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#tls-enabled
  DOCKER_HOST: tcp://docker:2376
  DOCKER_TLS_CERTDIR: "/certs"

build:
  stage: build
  script:
    - docker context create my-builder
    - docker buildx create my-builder --driver docker-container --use
    - docker buildx build --push -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      --cache-to type=registry,ref=$CI_REGISTRY_IMAGE/cache-image,mode=max
      --cache-from type=registry,ref=$CI_REGISTRY_IMAGE/cache-image .
```

`build`ジョブの`script`:

1. `registry`キャッシュバックエンドをサポートする`docker-container` BuildKitドライバーを作成し、構成します。
1. 以下を使用してDockerイメージをビルドし、プッシュします:

   - `--cache-from type=registry,ref=$CI_REGISTRY_IMAGE/cache-image`を使用した専用キャッシュイメージ。
   - `--cache-to type=registry,ref=$CI_REGISTRY_IMAGE/cache-image,mode=max`を使用したキャッシュの更新。ここで、`max`モードは中間レイヤーをキャッシュします。
