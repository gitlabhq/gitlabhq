---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: ビルド来歴データでコンテナイメージにアノテーションを付与する'
description: Cosignを使用して、GitLab CI/CDパイプラインでビルドの来歴データでコンテナイメージに注釈を付け、署名します。
---

注釈は、ビルドプロセスに関する貴重なメタデータを提供します。この情報は、監査と追跡可能性に使用されます。セキュリティインシデントが発生した場合、詳細な来歴データがあれば、調査と修正プロセスを大幅にスピードアップできます。

このチュートリアルでは、Cosignを使用してコンテナイメージのビルド、署名、注釈の処理を自動化するGitLabパイプラインをセットアップする方法について説明します。`.gitlab-ci.yml`ファイルを設定して、Dockerイメージをビルド、プッシュ、署名し、GitLabレジストリにプッシュできます。

コンテナイメージに注釈を付けるには、次の手順に従います:

1. [イメージとサービスイメージを設定する](#set-image-and-service-image)。
1. [CI/CD変数](#define-cicd-variables)を定義します。
1. [OIDCトークンを準備する](#prepare-oidc-token)。
1. [コンテナを準備する](#prepare-the-container)。
1. [イメージをビルドしてプッシュする](#build-and-push-the-image)。
1. [Cosignでイメージに署名する](#sign-the-image-with-cosign)。
1. [署名と注釈を確認する](#verify-the-signature-and-annotations)。

すべてをまとめると、`.gitlab-ci.yml`は、このチュートリアルの最後に記載されている[サンプル設定](#example-gitlab-ciyml-configuration)のようになります。

## はじめる前 {#before-you-begin}

以下が必要です:

- Cosign v2.0以降がインストールされている必要があります。
- GitLab Self-Managedの場合、署名を表示するには、[メタデータデータベースで構成されたGitLabコンテナレジストリ](../../../administration/packages/container_registry_metadata_database.md)が必要です。

## イメージとサービスイメージを設定する {#set-image-and-service-image}

`.gitlab-ci.yml`ファイルで、`docker:cli`イメージを使用し、DockerコマンドをCI/CDジョブで実行できるようにDocker-in-Dockerサービスを有効にします。

```yaml
build_and_sign:
  stage: build
  image: docker:cli
  services:
    - docker:dind  # Enable Docker-in-Docker service to allow Docker commands inside the container
```

## CI/CD変数を定義する {#define-cicd-variables}

GitLab CI/CD定義済み変数を使用して、イメージタグ付けとURIの変数を定義します。

```yaml
variables:
  IMAGE_TAG: $CI_COMMIT_SHORT_SHA  # Use the commit short SHA as the image tag
  IMAGE_URI: $CI_REGISTRY_IMAGE:$IMAGE_TAG  # Construct the full image URI with the registry, project path, and tag
  COSIGN_YES: "true"  # Automatically confirm actions in Cosign without user interaction
  FF_SCRIPT_SECTIONS: "true"  # Enables GitLab's CI script sections for better multi-line script output
```

## OIDCトークンを準備する {#prepare-oidc-token}

Cosignでキーレス署名を行うためのOIDCトークンをセットアップします。

```yaml
id_tokens:
  SIGSTORE_ID_TOKEN:
    aud: sigstore  # Provide an OIDC token for keyless signing with Cosign
```

## コンテナを準備する {#prepare-the-container}

`.gitlab-ci.yml`ファイルの`before_script`セクションで以下を行います:

- Cosignとjq（JSON処理用）をインストールします: `apk add --no-cache cosign jq`
- CI/CDジョブトークンを使用してGitLabコンテナレジストリログインを有効にします: `docker login -u "gitlab-ci-token" -p "$CI_JOB_TOKEN" "$CI_REGISTRY"`

パイプラインは、必要な環境をセットアップすることから開始します。

## イメージをビルドしてプッシュする {#build-and-push-the-image}

`.gitlab-ci.yml`ファイルの`script`セクションに、Dockerイメージをビルドし、GitLabコンテナレジストリにプッシュするための次のコマンドを入力します。

```yaml
- docker build --pull -t "$IMAGE_URI" .
- docker push "$IMAGE_URI"
```

このコマンドは、現在のディレクトリのDockerfileを使用してイメージを作成し、レジストリにプッシュします。

## Cosignでイメージに署名する {#sign-the-image-with-cosign}

イメージをビルドしてGitLabコンテナレジストリにプッシュした後、Cosignを使用して署名します。

`.gitlab-ci.yml`ファイルの`script`セクションに、次のコマンドを入力します:

```yaml
- IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE_URI")
- |
  cosign sign "$IMAGE_DIGEST" \
    --registry-referrers-mode oci-1-1 \
    --annotations "com.gitlab.ci.user.name=$GITLAB_USER_NAME" \
    --annotations "com.gitlab.ci.pipeline.id=$CI_PIPELINE_ID" \
    # Additional annotations removed for readability
    --annotations "tag=$IMAGE_TAG"
```

このステップでは、イメージダイジェストを取得します。次に、Cosignを使用してイメージに署名し、いくつかの注釈を追加します。

## 署名と注釈を確認する {#verify-the-signature-and-annotations}

イメージに署名した後、署名と追加された注釈を確認することが重要です。

`.gitlab-ci.yml`ファイルに、`cosign verify`コマンドを使用した確認ステップを含めます:

```yaml
- |
  cosign verify \
    --annotations "tag=$IMAGE_TAG" \
    --certificate-identity "$CI_PROJECT_URL//.gitlab-ci.yml@refs/heads/$CI_COMMIT_REF_NAME" \
    --certificate-oidc-issuer "$CI_SERVER_URL" \
    "$IMAGE_URI" | jq .
```

この確認ステップでは、イメージに添付されている来歴データが正しいこと、および改ざんされていないことを確認します。`cosign verify`コマンドは、署名を確認し、注釈をチェックします。出力には、署名処理中にイメージに追加したすべての注釈が表示されます。

出力には、以前に追加されたすべての注釈（以下を含む）が表示されます:

- GitLabユーザー名
- パイプラインIDとURL
- ジョブIDとURL
- コミットSHAと参照名
- プロジェクトパス
- イメージソースとリビジョン

これらの注釈を確認することにより、イメージの来歴データがそのまま残り、ビルドプロセスに基づいて予想される内容と一致することを確認できます。

## `.gitlab-ci.yml`の設定例 {#example-gitlab-ciyml-configuration}

上記のすべての手順に従うと、`.gitlab-ci.yml`ファイルは次のようになります:

```yaml
stages:
  - build

build_and_sign:
  stage: build
  image: docker:cli
  services:
    - docker:dind  # Enable Docker-in-Docker service to allow Docker commands inside the container
  variables:
    IMAGE_TAG: $CI_COMMIT_SHORT_SHA  # Use the commit short SHA as the image tag
    IMAGE_URI: $CI_REGISTRY_IMAGE:$IMAGE_TAG  # Construct the full image URI with the registry, project path, and tag
    COSIGN_YES: "true"  # Automatically confirm actions in Cosign without user interaction
    FF_SCRIPT_SECTIONS: "true"  # Enables GitLab's CI script sections for better multi-line script output
  id_tokens:
    SIGSTORE_ID_TOKEN:
      aud: sigstore  # Provide an OIDC token for keyless signing with Cosign
  before_script:
    - apk add --no-cache cosign jq  # Install Cosign (mandatory) and jq (optional)
    - docker login -u "gitlab-ci-token" -p "$CI_JOB_TOKEN" "$CI_REGISTRY"  # Log in to the Docker registry using GitLab CI token
  script:
    # Build the Docker image using the specified tag and push it to the registry
    - docker build --pull -t "$IMAGE_URI" .
    - docker push "$IMAGE_URI"

    # Retrieve the digest of the pushed image to use in the signing step
    - IMAGE_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE_URI")

    # Sign the image using Cosign with annotations that provide metadata about the build and tag annotation to allow verifying
    # the tag->digest mapping (https://github.com/sigstore/cosign?tab=readme-ov-file#tag-signing)
    - |
      cosign sign "$IMAGE_DIGEST" \
        --registry-referrers-mode oci-1-1 \
        --annotations "com.gitlab.ci.user.name=$GITLAB_USER_NAME" \
        --annotations "com.gitlab.ci.pipeline.id=$CI_PIPELINE_ID" \
        --annotations "com.gitlab.ci.pipeline.url=$CI_PIPELINE_URL" \
        --annotations "com.gitlab.ci.job.id=$CI_JOB_ID" \
        --annotations "com.gitlab.ci.job.url=$CI_JOB_URL" \
        --annotations "com.gitlab.ci.commit.sha=$CI_COMMIT_SHA" \
        --annotations "com.gitlab.ci.commit.ref.name=$CI_COMMIT_REF_NAME" \
        --annotations "com.gitlab.ci.project.path=$CI_PROJECT_PATH" \
        --annotations "org.opencontainers.image.source=$CI_PROJECT_URL" \
        --annotations "org.opencontainers.image.revision=$CI_COMMIT_SHA" \
        --annotations "tag=$IMAGE_TAG"

    # Verify the image signature using Cosign to ensure it matches the expected annotations and certificate identity
    - |
      cosign verify \
        --annotations "tag=$IMAGE_TAG" \
        --certificate-identity "$CI_PROJECT_URL//.gitlab-ci.yml@refs/heads/$CI_COMMIT_REF_NAME" \
        --certificate-oidc-issuer "$CI_SERVER_URL" \
        "$IMAGE_URI" | jq .  # Use jq to format the verification output for easier readability
```
