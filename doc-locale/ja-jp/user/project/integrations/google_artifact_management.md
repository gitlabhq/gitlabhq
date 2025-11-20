---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Google Artifact Management
description: GoogleアーティファクトレジストリをGitLabプロジェクトに接続して、プッシュ、プル、およびDockerとOCIイメージを表示します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 16.10で`google_cloud_support_feature_flag`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141127)されました。この機能は[ベータ版](../../../policy/development_stages_support.md)です。
- GitLab 17.1の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)になりました。機能フラグ`google_cloud_support_feature_flag`は削除されました。

{{< /history >}}

GoogleアーティファクトManagementインテグレーションを使用すると、[Googleアーティファクトレジストリ](https://cloud.google.com/artifact-registry)リポジトリを設定し、GitLabプロジェクトに接続できます。

Googleアーティファクトレジストリをプロジェクトに接続すると、[Googleアーティファクトレジストリ](https://cloud.google.com/artifact-registry)リポジトリ内のDockerおよび[OCI](https://opencontainers.org/)イメージを表示、プッシュ、およびプルできます。

## GitLabプロジェクトでGoogleアーティファクトレジストリをセットアップする {#set-up-the-google-artifact-registry-in-a-gitlab-project}

前提要件: 

- 少なくともGitLabプロジェクトのメンテナーロールを持っている必要があります。
- アーティファクトレジストリリポジトリを使用して、Google Cloudプロジェクトへのアクセスを管理するには、[必要な権限](https://cloud.google.com/iam/docs/granting-changing-revoking-access#required-permissions)が必要です。
- Google Cloudへの認証を行うには、[ワークロードID連携](../../../integration/google_cloud_iam.md) (WLIF) プールとプロバイダーを設定する必要があります。
- 次の設定の[Googleアーティファクトレジストリリポジトリ](https://cloud.google.com/artifact-registry/docs/repositories):
  - [Docker](https://cloud.google.com/artifact-registry/docs/supported-formats)形式。
  - [標準](https://cloud.google.com/artifact-registry/docs/repositories/create-repos)モード。他のリポジトリ形式とモードはサポートされていません。

GoogleアーティファクトレジストリリポジトリをGitLabプロジェクトに接続するには:

1. GitLabの左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Googleアーティファクトの管理**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. フィールドに入力します:
   - **Google CloudプロジェクトID**: アーティファクトレジストリリポジトリが配置されている[Google CloudプロジェクトID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)。
   - **リポジトリ名**: アーティファクトレジストリリポジトリの名前。
   - **リポジトリの場所**: アーティファクトレジストリリポジトリの[Google Cloudの場所](https://cloud.google.com/about/locations)。
1. 画面の指示に従って、Google Cloud Identity and Access Management (IAM)ポリシーをセットアップします。ポリシーの種類の詳細については、[IAMポリシー](#iam-policies)を参照してください。
1. **変更を保存**を選択します。

これで、サイドバーの**デプロイ**の下に**Googleアーティファクトのレジストリ**エントリが表示されるはずです。

## Googleアーティファクトレジストリに保存されているイメージを表示する {#view-images-stored-in-the-google-artifact-registry}

前提要件: 

- Googleアーティファクトレジストリがプロジェクトで[設定](google_artifact_management.md#set-up-the-google-artifact-registry-in-a-gitlab-project)されている必要があります。

接続されているアーティファクトレジストリリポジトリ内のイメージのリストをGitLab UIに表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **デプロイ** > **Googleアーティファクトのレジストリ**を選択します。
1. イメージの詳細を表示するには、イメージを選択します。
1. Google Cloudコンソールでイメージを表示するには、**Google Cloudで開く**を選択します。そのアーティファクトレジストリリポジトリを表示するには、[必要な権限](https://cloud.google.com/artifact-registry/docs/repositories/list-repos#required_roles)が必要です。

## CI/CD {#cicd}

### 定義済み変数 {#predefined-variables}

アーティファクトレジストリインテグレーションをアクティブ化すると、次の定義済みの環境変数がCI/CDで使用可能になります。これらの環境変数を使用して、接続されているリポジトリにイメージをプルまたはプッシュするなど、アーティファクトレジストリを操作できます。

| 変数                                       | GitLab | Runner | 説明 |
|------------------------------------------------|--------|--------|-------------|
| `GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID`          | 16.10  | 16.10  | アーティファクトレジストリリポジトリが配置されているGoogle CloudプロジェクトID。 |
| `GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME`     | 16.10  | 16.10  | 接続されているアーティファクトレジストリリポジトリの名前。 |
| `GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION` | 16.10  | 16.10  | 接続されているアーティファクトレジストリリポジトリのGoogle Cloudの場所。 |

### Googleアーティファクトレジストリで認証する {#authenticate-with-the-google-artifact-registry}

パイプラインの実行中にGoogleアーティファクトレジストリで認証するようにパイプラインを設定できます。GitLabは、設定された[ワークロードID](../../../integration/google_cloud_iam.md) IAMポリシーを使用し、`GOOGLE_APPLICATION_CREDENTIALS`および`CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE`の認証情報を入力された状態にします。これらの認証情報は、[gcloudコマンドラインインターフェース](https://cloud.google.com/sdk/gcloud)や[crane](https://github.com/google/go-containerregistry/blob/main/cmd/crane/README.md)などのクライアントツールによって自動的に検出されます。

Googleアーティファクトレジストリで認証するには、プロジェクトの`.gitlab-ci.yml`ファイルで、`google_cloud`に設定された[`identity`](../../../ci/yaml/_index.md#identity)キーワードを使用します。

#### IAMポリシー {#iam-policies}

Google Cloudプロジェクトには、GoogleアーティファクトManagementインテグレーションを使用するための特定のIAMポリシーが必要です。[このインテグレーションを設定](#set-up-the-google-artifact-registry-in-a-gitlab-project)すると、画面の指示に従って、Google Cloudプロジェクトで次のIAMポリシーを作成できます:

- [アーティファクトレジストリReader](https://cloud.google.com/iam/docs/understanding-roles#artifactregistry.reader)ロールを、[ゲスト](../../permissions.md#roles)ロール以上のGitLabプロジェクトメンバーに付与します。
- [アーティファクトレジストリWriter](https://cloud.google.com/iam/docs/understanding-roles#artifactregistry.writer)ロールを、[デベロッパー](../../permissions.md#roles)ロール以上のGitLabプロジェクトメンバーに付与します。

これらのIAMポリシーを手動で作成するには、次の`gcloud`コマンドを使用します。これらの値を置き換えます:

- `<your_google_cloud_project_id>`を、アーティファクトレジストリリポジトリが配置されているGoogle Cloudプロジェクトの[ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)に置き換えます。
- `<your_workload_identity_pool_id>`を、ワークロードIDプールのIDに置き換えます。これは、[Google Cloud IAMインテグレーション](../../../integration/google_cloud_iam.md)に使用されるのと同じ値です。
- `<your_google_cloud_project_number>`を、ワークロードIDプールが配置されているGoogle Cloudプロジェクトの[番号](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)に置き換えます。これは、[Google Cloud IAMインテグレーション](../../../integration/google_cloud_iam.md)に使用されるのと同じ値です。

```shell
gcloud projects add-iam-policy-binding '<your_google_cloud_project_id>' \
  --member='principalSet://iam.googleapis.com/projects/<your_google_cloud_project_number>/locations/global/workloadIdentityPools/<your_workload_identity_pool_id>/attribute.guest_access/true' \
  --role='roles/artifactregistry.reader'

gcloud projects add-iam-policy-binding '<your_google_cloud_project_id>' \
  --member='principalSet://iam.googleapis.com/projects/<your_google_cloud_project_number>/locations/global/workloadIdentityPools/<your_workload_identity_pool_id>/attribute.developer_access/true' \
  --role='roles/artifactregistry.writer'
```

利用可能なクレームのリストについては、[OIDCカスタムクレーム](../../../integration/google_cloud_iam.md#oidc-custom-claims)を参照してください。

### 例 {#examples}

#### gcloudコマンドラインインターフェースを使用してイメージをリストする {#use-gcloud-cli-to-list-images}

```yaml
list-images:
  image: gcr.io/google.com/cloudsdktool/google-cloud-cli:466.0.0-alpine
  identity: google_cloud
  script:
    - gcloud artifacts docker images list $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/app
```

#### craneを使用してイメージをリストする {#use-crane-to-list-images}

```yaml
list-images:
  image:
    name: gcr.io/go-containerregistry/crane:debug
    entrypoint: [""]
  identity: google_cloud
  before_script:
    # Temporary workaround for https://github.com/google/go-containerregistry/issues/1886
    - wget -q "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v2.1.22/docker-credential-gcr_linux_amd64-2.1.22.tar.gz" -O - | tar xz -C /tmp && chmod +x /tmp/docker-credential-gcr && mv /tmp/docker-credential-gcr /usr/bin/
    - docker-credential-gcr configure-docker --registries=$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev
  script:
    - crane ls $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/app
```

#### Dockerでイメージをプルする {#pull-an-image-with-docker}

次の例は、Googleが提供する[スタンドアロンのDocker認証情報ヘルパー](https://cloud.google.com/artifact-registry/docs/docker/authentication#standalone-helper)を使用して、Dockerの認証をセットアップする方法を示しています。

```yaml
pull-image:
  image: docker:24.0.5
  identity: google_cloud
  services:
    - docker:24.0.5-dind
  variables:
    # The following two variables ensure that the DinD service starts in TLS
    # mode and that the Docker CLI is properly configured to communicate with
    # the API. More details about the importance of this can be found at
    # https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-the-docker-executor-with-docker-in-docker
    DOCKER_HOST: tcp://docker:2376
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - wget -q "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v2.1.22/docker-credential-gcr_linux_amd64-2.1.22.tar.gz" -O - | tar xz -C /tmp && chmod +x /tmp/docker-credential-gcr && mv /tmp/docker-credential-gcr /usr/bin/
    - docker-credential-gcr configure-docker --registries=$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev
  script:
    - docker pull $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/app:v0.1.0
```

#### CI/CDコンポーネントを使用してイメージをコピーする {#copy-an-image-by-using-a-cicd-component}

Googleは、[`upload-artifact-registry`](https://gitlab.com/explore/catalog/google-gitlab-components/artifact-registry) CI/CDコンポーネントを提供します。これを使用して、GitLabコンテナレジストリからアーティファクトレジストリにイメージをコピーできます。

`upload-artifact-registry`コンポーネントを使用するには、次の内容を`.gitlab-ci.yml`に追加します:

```yaml
include:
  - component: gitlab.com/google-gitlab-components/artifact-registry/upload-artifact-registry@main
    inputs:
      stage: deploy
      source: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
      target: $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/$CI_PROJECT_NAME:$CI_COMMIT_SHORT_SHA
```

詳細については、[コンポーネントドキュメント](https://gitlab.com/explore/catalog/google-gitlab-components/artifact-registry)を参照してください。

`upload-artifact-registry`コンポーネントを使用すると、アーティファクトレジストリへのイメージのコピーが簡素化され、このインテグレーションの推奨される方法です。DockerまたはCraneを使用する場合は、次の例を参照してください。

#### Dockerを使用してイメージをコピーする {#copy-an-image-by-using-docker}

次の例では、[スタンドアロンのDocker認証情報ヘルパー](https://cloud.google.com/artifact-registry/docs/docker/authentication#standalone-helper)の代わりに、`gcloud` CLIを使用してDocker認証をセットアップします。

```yaml
copy-image:
  image: gcr.io/google.com/cloudsdktool/google-cloud-cli:466.0.0-alpine
  identity: google_cloud
  services:
    - docker:24.0.5-dind
  variables:
    SOURCE_IMAGE: $CI_REGISTRY_IMAGE:v0.1.0
    TARGET_IMAGE: $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/app:v0.1.0
    DOCKER_HOST: tcp://docker:2375
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - gcloud auth configure-docker $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev
  script:
    - docker pull $SOURCE_IMAGE
    - docker tag $SOURCE_IMAGE $TARGET_IMAGE
    - docker push $TARGET_IMAGE
```

#### Craneを使用してイメージをコピーする {#copy-an-image-by-using-crane}

```yaml
copy-image:
  image:
    name: gcr.io/go-containerregistry/crane:debug
    entrypoint: [""]
  identity: google_cloud
  variables:
    SOURCE_IMAGE: $CI_REGISTRY_IMAGE:v0.1.0
    TARGET_IMAGE: $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/app:v0.1.0
  before_script:
    # Temporary workaround for https://github.com/google/go-containerregistry/issues/1886
    - wget -q "https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v2.1.22/docker-credential-gcr_linux_amd64-2.1.22.tar.gz" -O - | tar xz -C /tmp && chmod +x /tmp/docker-credential-gcr && mv /tmp/docker-credential-gcr /usr/bin/
    - docker-credential-gcr configure-docker --registries=$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev
  script:
    - crane auth login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - crane copy $SOURCE_IMAGE $TARGET_IMAGE
```
