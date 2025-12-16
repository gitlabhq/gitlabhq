---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: BuildKitでDockerイメージを作成
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[BuildKit](https://docs.docker.com/build/buildkit/)は、Dockerが使用するビルドエンジンであり、マルチプラットフォームのビルドとビルドキャッシュを提供します。

## BuildKitのメソッド {#buildkit-methods}

BuildKitには、Dockerイメージをビルドするための次のメソッドがあります:

| メソッド            | セキュリティ要件     | コマンド                 | 必要な場合 |
| ----------------- | ------------------------ | ------------------------ | ----------------- |
| BuildKitルートレス | 特権コンテナなし | `buildctl-daemonless.sh` | 最大限のセキュリティ、またはKanikoの代替 |
| Docker Buildx     | 以下が必要です`docker:dind`   | `docker buildx`          | 使い慣れたDockerワークフロー |
| ネイティブBuildKit   | 以下が必要です`docker:dind`   | `buildctl`               | BuildKitの詳細な制御 |

## 前提要件 {#prerequisites}

- Docker executorを使用するGitLab Runner
- Docker Buildxを使用するには、Docker 19.03以降が必要です
- `Dockerfile`を使用したプロジェクト

## BuildKitルートレス {#buildkit-rootless}

スタンドアロンモードのBuildKitは、Dockerデーモンの依存関係なしに、ルートレスイメージのビルドを提供します。この方法では、特権コンテナが完全に排除され、Kanikoビルドの直接的な代替手段が提供されます。

他の方法との主な違い:

- `moby/buildkit:rootless`イメージを使用
- ルートレス操作のために`BUILDKITD_FLAGS: --oci-worker-no-process-sandbox`を含める
- `buildctl-daemonless.sh`を使用して、BuildKitデーモンを自動的に管理する
- Dockerデーモンまたは特権コンテナの依存関係なし
- 手動レジストリ認証の設定が必要

### コンテナレジストリで認証する {#authenticate-with-container-registries}

GitLab CI/CDは、定義済み変数を介して、GitLabコンテナレジストリの自動認証を提供します。BuildKitルートレスの場合は、Docker設定ファイルを手動で作成する必要があります。

#### GitLabコンテナレジストリを使用して認証する {#authenticate-with-the-gitlab-container-registry}

GitLabは、これらの定義済み変数を自動的に提供します:

- `CI_REGISTRY`: レジストリURL
- `CI_REGISTRY_USER`: レジストリユーザー名
- `CI_REGISTRY_PASSWORD`: レジストリパスワード

ルートレスビルドの認証を構成するには、`before_script`構成をジョブに追加します。例: 

```yaml
before_script:
  - mkdir -p ~/.docker
  - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
```

#### 複数のレジストリで認証する {#authenticate-with-multiple-registries}

追加のコンテナレジストリで認証するには、`before_script`セクションで認証エントリを結合します。例: 

```yaml
before_script:
  - mkdir -p ~/.docker
  - |
    echo "{
      \"auths\": {
        \"${CI_REGISTRY}\": {
          \"auth\": \"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"
        },
        \"docker.io\": {
          \"auth\": \"$(printf "%s:%s" "${DOCKER_HUB_USER}" "${DOCKER_HUB_PASSWORD}" | base64 | tr -d '\n')\"
        }
      }
    }" > ~/.docker/config.json
```

#### 依存プロキシで認証する {#authenticate-with-the-dependency-proxy}

GitLab依存プロキシを介してイメージをプルするには、`before_script`セクションで認証を構成します。例: 

```yaml
before_script:
  - mkdir -p ~/.docker
  - |
    echo "{
      \"auths\": {
        \"${CI_REGISTRY}\": {
          \"auth\": \"$(printf "%s:%s" "${CI_REGISTRY_USER}" "${CI_REGISTRY_PASSWORD}" | base64 | tr -d '\n')\"
        },
        \"$(echo -n $CI_DEPENDENCY_PROXY_SERVER | awk -F[:] '{print $1}')\": {
          \"auth\": \"$(printf "%s:%s" ${CI_DEPENDENCY_PROXY_USER} "${CI_DEPENDENCY_PROXY_PASSWORD}" | base64 | tr -d '\n')\"
        }
      }
    }" > ~/.docker/config.json
```

詳細については、[CI/CD内で認証する](../../user/packages/dependency_proxy/_index.md#authenticate-within-cicd)を参照してください。

### ルートレスモードでイメージをビルドする {#build-images-in-rootless-mode}

Dockerデーモンの依存関係なしにイメージをビルドするには、この例のようなジョブを追加します:

```yaml
build-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

### ルートレスモードでマルチプラットフォームイメージをビルドする {#build-multi-platform-images-in-rootless-mode}

ルートレスモードで複数のアーキテクチャのイメージをビルドするには、ターゲットプラットフォームを指定するようにジョブを構成します。例: 

```yaml
build-multiarch-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --opt platform=linux/amd64,linux/arm64 \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

### ルートレスモードでキャッシュを使用する {#use-caching-in-rootless-mode}

後続のビルドを高速化するためにレジストリベースのキャッシュを有効にするには、ビルドジョブでキャッシュのインポートとエクスポートを構成します。例: 

```yaml
build-cached-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
    CACHE_IMAGE: $CI_REGISTRY_IMAGE:cache
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --export-cache type=registry,ref=$CACHE_IMAGE \
        --import-cache type=registry,ref=$CACHE_IMAGE \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

### ルートレスモードでレジストリミラーを使用する {#use-a-registry-mirror-in-rootless-mode}

レジストリミラーを使用すると、イメージのプルが高速化され、レート制限やネットワーク制限に役立ちます。

レジストリミラーを構成するには、ミラーエンドポイントを指定する`buildkit.toml`ファイルを作成します。例: 

```yaml
build-mirror-rootless:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox --config /tmp/buildkit.toml
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
    - cat <<'EOF' > /tmp/buildkit.toml
      [registry."docker.io"]
        mirrors = ["mirror.example.com"]
      EOF
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

この例では、`mirror.example.com`をレジストリミラーURLに置き換えます。

### プロキシ設定を構成する {#configure-proxy-settings}

GitLab RunnerがHTTP(S) プロキシの背後で動作する場合は、ジョブで変数としてプロキシ設定を構成します。例: 

```yaml
build-behind-proxy:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
    http_proxy: <your-proxy>
    https_proxy: <your-proxy>
    no_proxy: <your-no-proxy>
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --build-arg http_proxy=$http_proxy \
        --build-arg https_proxy=$https_proxy \
        --build-arg no_proxy=$no_proxy \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

この例では、`<your-proxy>`と`<your-no-proxy>`をプロキシ構成に置き換えます。

### カスタムCA証明書を追加する {#add-custom-certificates}

カスタムCA証明書を使用してレジストリにプッシュするには、ビルドする前にコンテナの証明書ストアに証明書を追加します。例: 

```yaml
build-with-custom-certs:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  stage: build
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - |
      echo "-----BEGIN CERTIFICATE-----
      ...
      -----END CERTIFICATE-----" >> /etc/ssl/certs/ca-certificates.crt
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

この例では、証明書のプレースホルダーを実際の証明書の内容に置き換えます。

## KanikoからBuildKitに移行する {#migrate-from-kaniko-to-buildkit}

BuildKitルートレスは、Kanikoの安全な代替手段です。パフォーマンスの向上、キャッシュの改善、セキュリティ機能の強化を実現しながら、ルートレス操作を維持します。

### 設定を更新 {#update-your-configuration}

BuildKitルートレスメソッドを使用するように、既存のKaniko構成を更新します。例: 

前: Kanikoを使用:

```yaml
build:
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  script:
    - /kaniko/executor
      --context $CI_PROJECT_DIR
      --dockerfile $CI_PROJECT_DIR/Dockerfile
      --destination $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

後: BuildKitルートレスを使用:

```yaml
build:
  image:
    name: moby/buildkit:rootless
    entrypoint: [""]
  variables:
    BUILDKITD_FLAGS: --oci-worker-no-process-sandbox
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl-daemonless.sh build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

## BuildKitの代替メソッド {#alternative-buildkit-methods}

ルートレスビルドが不要な場合、BuildKitには`docker:dind`サービスを必要とする追加のメソッドが用意されていますが、使い慣れたワークフローまたは高度な機能が提供されます。

### Docker Buildx {#docker-buildx}

Docker Buildxは、使い慣れたコマンド構文を維持しながら、BuildKit機能を使用してDockerビルド機能を拡張します。この方法では、`docker:dind`サービスが必要です。

#### 基本的なイメージをビルドする {#build-basic-images}

DockerイメージをBuildxでビルドするには、`docker:dind`サービスでジョブを構成し、`buildx`ビルダーを作成します。例: 

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"

build-image:
  image: docker:cli
  services:
    - docker:dind
  stage: build
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker buildx create --use --driver docker-container --name builder
    - docker buildx inspect --bootstrap
  script:
    - docker buildx build --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --push .
  after_script:
    - docker buildx rm builder
```

#### マルチプラットフォームイメージをビルドする {#build-multi-platform-images}

マルチプラットフォームビルドでは、単一のビルドコマンドで異なるアーキテクチャのイメージが作成されます。結果として得られるマニフェストは複数のアーキテクチャをサポートし、Dockerはデプロイターゲットごとに適切なイメージを自動的に選択します。

複数のアーキテクチャのイメージをビルドするには、`--platform`フラグを追加して、ターゲットアーキテクチャを指定します。例: 

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"

build-multiplatform:
  image: docker:cli
  services:
    - docker:dind
  stage: build
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker buildx create --use --driver docker-container --name multibuilder
    - docker buildx inspect --bootstrap
  script:
    - docker buildx build
        --platform linux/amd64,linux/arm64
        --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        --push .
  after_script:
    - docker buildx rm multibuilder
```

#### ビルドキャッシュを使用する {#use-build-caching}

レジストリベースのキャッシュは、ビルドレイヤーをコンテナレジストリに格納し、ビルド間で再利用できるようにします。

`mode=max`オプションは、すべてのレイヤーをキャッシュにエクスポートし、後続のビルドのために最大限の再利用の可能性を提供します。

ビルドキャッシュを使用するには、ビルドコマンドにキャッシュオプションを追加します。例: 

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"
  CACHE_IMAGE: $CI_REGISTRY_IMAGE:cache

build-with-cache:
  image: docker:cli
  services:
    - docker:dind
  stage: build
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker buildx create --use --driver docker-container --name cached-builder
    - docker buildx inspect --bootstrap
  script:
    - docker buildx build
        --cache-from type=registry,ref=$CACHE_IMAGE
        --cache-to type=registry,ref=$CACHE_IMAGE,mode=max
        --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        --push .
  after_script:
    - docker buildx rm cached-builder
```

### ネイティブBuildKit {#native-buildkit}

ネイティブBuildKit `buildctl`コマンドを使用して、ビルドプロセスをより詳細に制御します。この方法では、`docker:dind`サービスが必要です。

BuildKitを直接使用するには、BuildKitイメージと`docker:dind`サービスでジョブを構成します。例: 

```yaml
variables:
  DOCKER_TLS_CERTDIR: "/certs"

build-with-buildkit:
  image: moby/buildkit:latest
  services:
    - docker:dind
  stage: build
  before_script:
    - mkdir -p ~/.docker
    - echo "{\"auths\":{\"$CI_REGISTRY\":{\"username\":\"$CI_REGISTRY_USER\",\"password\":\"$CI_REGISTRY_PASSWORD\"}}}" > ~/.docker/config.json
  script:
    - |
      buildctl build \
        --frontend dockerfile.v0 \
        --local context=. \
        --local dockerfile=. \
        --output type=image,name=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA,push=true
```

## トラブルシューティング {#troubleshooting}

### 認証エラーでビルドが失敗する {#build-fails-with-authentication-errors}

レジストリ認証の失敗が発生した場合:

- `CI_REGISTRY_USER`変数と`CI_REGISTRY_PASSWORD`変数が使用可能であることを確認します。
- ターゲットレジストリへのプッシュ権限があることを確認してください。
- 外部レジストリの場合は、プロジェクトのCI/CD変数で認証情報が正しく構成されていることを確認してください。

### ルートレスビルドが権限エラーで失敗する {#rootless-build-fails-with-permission-errors}

ルートレスモードでの権限関連の問題の場合:

- `BUILDKITD_FLAGS: --oci-worker-no-process-sandbox`が設定されていることを確認してください。
- GitLab Runnerに十分なリソースが割り当てられていることを確認します。
- `Dockerfile`で特権操作が試行されていないことを確認します。

Kubernetes Runnerで`[rootlesskit:child ] error: failed to share mount point: /: permission denied`が表示される場合、AppArmorはBuildKitに必要なマウントsyscallをブロックしています。

この問題を解決するには、Runner構成に以下を追加します:

```toml
[runners.kubernetes.pod_annotations]
  "container.apparmor.security.beta.kubernetes.io/build" = "unconfined"
```

### エラー: `invalid local: stat path/to/image/Dockerfile: not a directory` {#error-invalid-local-stat-pathtoimagedockerfile-not-a-directory}

`invalid local: stat path/to/image/Dockerfile: not a directory`というエラーが表示されることがあります。

この問題は、`--local dockerfile=`パラメータのディレクトリパスの代わりにファイルを指定すると発生します。BuildKitは、`Dockerfile`という名前のファイルを含むディレクトリパスを予期しています。

この問題を解決するには、ファイル全体のパスの代わりにディレクトリパスを使用します。例: 

- 使用: `--local dockerfile=path/to/image`
- 使用しない: `--local dockerfile=path/to/image/Dockerfile`

### マルチプラットフォームビルドが失敗する {#multi-platform-builds-fail}

マルチプラットフォームビルドの問題の場合:

- `Dockerfile`のベースイメージがターゲットアーキテクチャをサポートしていることを確認します。
- アーキテクチャ固有の依存関係が、すべてのターゲットプラットフォームで使用できることを確認します。
- アーキテクチャ固有のロジックのために、`Dockerfile`で条件ステートメントを使用することを検討してください。
