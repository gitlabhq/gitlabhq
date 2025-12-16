---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Buildahを使用してマルチプラットフォームイメージをビルドする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Buildahを使用して、複数のCPUアーキテクチャ用のイメージをビルドします。マルチプラットフォームビルドでは、異なるハードウェアプラットフォームで動作するイメージが作成され、Dockerは各デプロイターゲットに適切なイメージを自動的に選択します。

## 前提要件 {#prerequisites}

- イメージのビルド元となるDockerfile
- （オプション）異なるCPUアーキテクチャで実行されているGitLab Runner

## マルチプラットフォームイメージをビルドする {#build-multi-platform-images}

Buildahを使用してマルチプラットフォームイメージをビルドするには、次の手順を実行します:

1. ターゲットアーキテクチャごとに個別のビルドジョブを設定します。
1. アーキテクチャ固有のイメージを組み合わせるジョブを作成します。
1. 結合されたマニフェストをレジストリにプッシュするようにジョブを設定します。

それぞれのアーキテクチャでジョブを実行することで、CPU命令の変換によるパフォーマンスの問題を回避できます。ただし、必要に応じて、単一のアーキテクチャで両方のビルドを実行できます。非ネイティブアーキテクチャ用にビルドすると、ビルド時間が遅くなる可能性があります。

次の例では、2つの[GitLabホスト型Runner（Linux）](../../ci/runners/hosted_runners/linux.md)を使用します:

- `saas-linux-small-arm64`
- `saas-linux-small-amd64`

```yaml
stages:
  - build

variables:
  STORAGE_DRIVER: vfs
  BUILDAH_FORMAT: docker
  FQ_IMAGE_NAME: "$CI_REGISTRY_IMAGE:latest"

default:
  image: quay.io/buildah/stable
  before_script:
    - echo "$CI_REGISTRY_PASSWORD" | buildah login -u "$CI_REGISTRY_USER" --password-stdin $CI_REGISTRY

build-amd64:
  stage: build
  tags:
    - saas-linux-small-amd64
  script:
    - buildah build --platform=linux/amd64 -t $CI_REGISTRY_IMAGE:amd64 .
    - buildah push $CI_REGISTRY_IMAGE:amd64

build-arm64:
  stage: build
  tags:
    - saas-linux-small-arm64
  script:
    - buildah build --platform=linux/arm64/v8 -t $CI_REGISTRY_IMAGE:arm64 .
    - buildah push $CI_REGISTRY_IMAGE:arm64

create_manifest:
  stage: build
  needs: ["build-arm64", "build-amd64"]
  tags:
    - saas-linux-small-amd64
  script:
    - buildah manifest create $FQ_IMAGE_NAME
    - buildah manifest add $FQ_IMAGE_NAME docker://$CI_REGISTRY_IMAGE:amd64
    - buildah manifest add $FQ_IMAGE_NAME docker://$CI_REGISTRY_IMAGE:arm64
    - buildah manifest push --all $FQ_IMAGE_NAME
```

このパイプラインは、`amd64`および`arm64`でタグ付けされたアーキテクチャ固有のイメージを作成し、それらを`latest`タグで使用可能な単一のマニフェストに結合します。

## トラブルシューティング {#troubleshooting}

### 認証エラーでビルドに失敗する {#build-fails-with-authentication-errors}

レジストリの認証に失敗した場合は、次のようにします:

- `CI_REGISTRY_USER`および`CI_REGISTRY_PASSWORD`変数が利用可能であることを確認します。
- ターゲットレジストリへのプッシュ権限があることを確認します。
- 外部レジストリの場合は、プロジェクトのCI/CD変数で認証情報が正しく設定されていることを確認してください。

### マルチプラットフォームビルドに失敗する {#multi-platform-builds-fail}

マルチプラットフォームビルドの問題:

- `Dockerfile`のベースイメージがターゲットアーキテクチャをサポートしていることを確認します。
- アーキテクチャ固有の依存関係がすべてのターゲットプラットフォームで利用可能であることを確認します。
- アーキテクチャ固有のロジックのために、`Dockerfile`で条件ステートメントを使用することを検討してください。

### エラー: `Error during unshare(CLONE_NEWUSER): Operation not permitted` {#error-error-during-unshareclone_newuser-operation-not-permitted}

Buildahまたは[Docker BuildKit](using_buildkit.md)をルートレスコンテナモードで使用して、CI/CDジョブでDockerイメージをビルドすると、`Error during unshare(CLONE_NEWUSER): Operation not permitted`が発生する可能性があります。

このエラーは、ルートレスコンテナのビルドに必要なセキュリティオプションが設定されていない場合に発生します。

この問題を解決するには、Runnerの`config.toml`ファイルの`[runners.docker]`セクションを設定します:

```toml
[runners.docker]
  security_opt = ["seccomp:unconfined", "apparmor:unconfined"]
```

詳細については、[BuildKitルートレスコンテナDockerビルドおよびセキュリティ要件](https://github.com/moby/buildkit/blob/master/docs/rootless.md#docker)を参照してください。
