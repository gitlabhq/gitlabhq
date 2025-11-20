---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナイメージをビルドしてコンテナレジストリにプッシュする
description: DockerコマンドまたはCI/CDパイプラインを使用して、GitLabレジストリにコンテナイメージをビルドしてプッシュします。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

コンテナイメージをビルドしてプッシュする前に、コンテナレジストリで[認証](authenticate_with_container_registry.md)する必要があります。

## Dockerコマンドを使用する {#use-docker-commands}

Dockerコマンドを使用して、コンテナイメージをコンテナレジストリにビルドおよびプッシュできます:

1. コンテナレジストリで[認証](authenticate_with_container_registry.md)します。
1. Dockerコマンドを実行して、ビルドまたはプッシュします。次に例を示します:

   - ビルドする:

     ```shell
     docker build -t registry.example.com/group/project/image .
     ```

   - プッシュする:

     ```shell
     docker push registry.example.com/group/project/image
     ```

## GitLab CI/CDを使用する {#use-gitlab-cicd}

[GitLab CI/CD](../../../ci/_index.md)を使用して、コンテナイメージをビルド、プッシュ、テスト、およびコンテナレジストリからデプロイします。

### `.gitlab-ci.yml`ファイルを設定する {#configure-your-gitlab-ciyml-file}

`.gitlab-ci.yml`ファイルを設定して、コンテナイメージをコンテナレジストリにビルドおよびプッシュできます。

- 複数のジョブで認証が必要な場合は、認証コマンドを`before_script`に入力します。
- ビルドする前に、`docker build --pull`を使用してベースイメージへの変更を取得します。少し時間がかかりますが、イメージが最新の状態に保たれます。
- 各`docker run`の前に、明示的な`docker pull`を実行して、ビルドされたばかりのイメージを取得します。このステップは、イメージをローカルにキャッシュする複数のRunnerを使用している場合に特に重要です。

  イメージタグにGit SHAを使用すれば、各ジョブが一意になり、古いイメージが使用されるのを防ぐことができます。ただし、依存関係が変更された後に特定のコミットを再ビルドすると、古いイメージが使用される可能性があります。
- 複数のジョブが同時に実行される可能性があるため、`latest`タグに直接ビルドしないでください。

### Docker-in-Dockerコンテナイメージを使用する {#use-a-docker-in-docker-container-image}

コンテナレジストリまたは依存プロキシで、独自のDocker-in-Docker（DinD）コンテナイメージを使用できます。

DinDを使用して、CI/CDパイプラインからコンテナ化されたアプリケーションをビルド、テスト、およびデプロイします。

前提要件: 

- [Docker-in-Docker](../../../ci/docker/using_docker_build.md#use-docker-in-docker)を設定します。

{{< tabs >}}

{{< tab title="コンテナレジストリから" >}}

GitLabコンテナレジストリに格納されているイメージを使用する場合は、このアプローチを使用します。

`.gitlab-ci.yml`ファイルでは、:

- `image`と`services`を更新して、レジストリを指すようにしてください。
- サービス[エイリアス](../../../ci/services/_index.md#available-settings-for-services)を追加します。

`.gitlab-ci.yml`は次のようになります:

```yaml
build:
  image: $CI_REGISTRY/group/project/docker:24.0.5-cli
  services:
    - name: $CI_REGISTRY/group/project/docker:24.0.5-dind
      alias: docker
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

{{< /tab >}}

{{< tab title="依存プロキシを使用する場合" >}}

このアプローチを使用すると、ビルドを高速化し、レート制限を回避するために、Docker Hubのような外部レジストリからイメージをキャッシュできます。

`.gitlab-ci.yml`ファイルでは、:

- `image`と`services`を更新して、依存プロキシのプレフィックスを使用します。
- サービス[エイリアス](../../../ci/services/_index.md#available-settings-for-services)を追加します。

`.gitlab-ci.yml`は次のようになります:

```yaml
build:
  image: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/docker:24.0.5-cli
  services:
    - name: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}/docker:24.0.5-dind
      alias: docker
  stage: build
  script:
    - docker build -t my-docker-image .
    - docker run my-docker-image /script/to/run/tests
```

{{< /tab >}}

{{< /tabs >}}

サービスエイリアスの設定を忘れると、コンテナイメージは`dind`サービスを見つけることができず、次のようなエラーが表示されます:

```plaintext
error during connect: Get http://docker:2376/v1.39/info: dial tcp: lookup docker on 192.168.0.1:53: no such host
```

## GitLab CI/CDを使用したコンテナレジストリの例 {#container-registry-examples-with-gitlab-cicd}

RunnerでDocker-in-Dockerを使用している場合、`.gitlab-ci.yml`ファイルは次のようになります:

```yaml
build:
  image: docker:24.0.5-cli
  stage: build
  services:
    - docker:24.0.5-dind
  script:
    - echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin
    - docker build -t $CI_REGISTRY/group/project/image:latest .
    - docker push $CI_REGISTRY/group/project/image:latest
```

`.gitlab-ci.yml`ファイルで[CI/CD変数](../../../ci/variables/_index.md)を使用できます。例: 

```yaml
build:
  image: docker:24.0.5-cli
  stage: build
  services:
    - docker:24.0.5-dind
  variables:
    IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
  script:
    - echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin
    - docker build -t $IMAGE_TAG .
    - docker push $IMAGE_TAG
```

前の例では:

- `$CI_REGISTRY_IMAGE`は、このプロジェクトに関連付けられたレジストリのアドレスに解決されます。
- `$IMAGE_TAG`は、レジストリアドレスとイメージタグ付けである`$CI_COMMIT_REF_SLUG`を組み合わせたカスタム変数です。[`$CI_COMMIT_REF_NAME`定義済み変数](../../../ci/variables/predefined_variables.md#predefined-variables)は、ブランチまたはタグ名に解決され、フォワードスラッシュを含めることができます。コンテナイメージのタグにフォワードスラッシュを含めることはできません。代わりに`$CI_COMMIT_REF_SLUG`を使用してください。

次の例では、CI/CDタスクを4つのパイプラインステージに分割し、2つのテストを並行して実行します。

`build`はコンテナレジストリに保存され、後続のステージで使用され、必要に応じてコンテナイメージをダウンロードします。`main`ブランチに変更をプッシュすると、パイプラインはイメージに`latest`というタグ名を付け、アプリケーション固有のデプロイスクリプトを使用してデプロイします:

```yaml
default:
  image: docker:24.0.5-cli
  services:
    - docker:24.0.5-dind
  before_script:
    - echo "$CI_REGISTRY_PASSWORD" | docker login $CI_REGISTRY -u $CI_REGISTRY_USER --password-stdin

stages:
  - build
  - test
  - release
  - deploy

variables:
  # Use TLS https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#tls-enabled
  DOCKER_HOST: tcp://docker:2376
  DOCKER_TLS_CERTDIR: "/certs"
  CONTAINER_TEST_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
  CONTAINER_RELEASE_IMAGE: $CI_REGISTRY_IMAGE:latest

build:
  stage: build
  script:
    - docker build --pull -t $CONTAINER_TEST_IMAGE .
    - docker push $CONTAINER_TEST_IMAGE

test1:
  stage: test
  script:
    - docker pull $CONTAINER_TEST_IMAGE
    - docker run $CONTAINER_TEST_IMAGE /script/to/run/tests

test2:
  stage: test
  script:
    - docker pull $CONTAINER_TEST_IMAGE
    - docker run $CONTAINER_TEST_IMAGE /script/to/run/another/test

release-image:
  stage: release
  script:
    - docker pull $CONTAINER_TEST_IMAGE
    - docker tag $CONTAINER_TEST_IMAGE $CONTAINER_RELEASE_IMAGE
    - docker push $CONTAINER_RELEASE_IMAGE
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

deploy:
  stage: deploy
  script:
    - ./deploy.sh
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  environment: production
```

{{< alert type="note" >}}

前の例では、`docker pull`を明示的に呼び出しています。`image:`を使用してコンテナイメージを暗黙的にプルし、[Docker](https://docs.gitlab.com/runner/executors/docker.html)または[Kubernetes](https://docs.gitlab.com/runner/executors/kubernetes/) executorのいずれかを使用する場合は、[`pull_policy`](https://docs.gitlab.com/runner/executors/docker.html#set-the-always-pull-policy)が`always`に設定されていることを確認してください。

{{< /alert >}}
