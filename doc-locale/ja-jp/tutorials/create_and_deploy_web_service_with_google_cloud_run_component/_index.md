---
stage: Verify
group: tutorials
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: Google Cloud RunコンポーネントでWebサービスを作成してデプロイする'
---

[Google Cloud Runコンポーネント](https://gitlab.com/google-gitlab-components/cloud-run)を使用して、Artifact Registryに保存されているコンテナイメージからWebサービスをデプロイする方法を説明します。

## はじめる前 {#before-you-begin}

1. [Google Cloudインテグレーションのセットアップ](../set_up_gitlab_google_integration/_index.md)の手順に従って以下を行います:

   - Google Cloud IAMを設定します。
   - GitLabをGoogle Artifact Registryに接続します。
   - Google CloudでCI/CDジョブを実行するようにGitLab Runnerを設定します。

1. このページのコマンドを実行するには、次のいずれかの開発環境で`gcloud` CLIを設定します:

   - [Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shell)
   - [ローカル](https://cloud.google.com/sdk/docs/install)。

1. 次のコマンドを実行して、デフォルトのGoogle Cloudプロジェクトを設定します:

   ```shell
   gcloud config set project PROJECT_ID
   ```

   デフォルトプロジェクトを設定すると、`--project`フラグを`gcloud`コマンドに渡す必要がなくなります。

1. Compute Engine APIとCloud Run APIを有効にします:

   ```shell
   gcloud services enable compute.googleapis.com artifactregistry.googleapis.com run.googleapis.com
   ```

1. 次のロールをワークロードIDプールに付与します:

   - Cloud Storage管理者（`roles/run.admin`）サービスを取得、作成、更新します。
   - サービスアカウントとして操作を実行するサービスアカウントユーザー（`roles/iam.serviceAccountUser`）

   `developer_access=true`属性マッピングに一致するワークロードIDプール内のすべてのプリンシパルに`roles/run.admin`および`roles/iam.serviceAccountUser`ロールを付与するには、次のコマンドを実行します:

   ```shell
   # Replace ${PROJECT_ID}, ${PROJECT_NUMBER}, ${LOCATION}, ${POOL_ID} with your values below
   WORKLOAD_IDENTITY=principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.developer_access/true
   gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="${WORKLOAD_IDENTITY}" --role="roles/run.admin"
   gcloud projects add-iam-policy-binding ${PROJECT_ID} --member="${WORKLOAD_IDENTITY}" --role="roles/iam.serviceAccountUser"
   ```

## 新しいGitLabプロジェクトでIAMインテグレーションを構成する {#configure-the-iam-integration-in-a-new-gitlab-project}

組織またはグループのインテグレーションのためにGoogle IAMを設定したら、その組織またはグループの新しいプロジェクトでインテグレーションを再利用できます:

1. 組織またはグループで[新しいGitLabプロジェクトを作成](../../user/project/_index.md)します。
1. GitLabプロジェクトで、**設定** > **インテグレーション**を選択します。
1. **Google Cloud IAM**を選択します。
1. **Google Cloudプロジェクト**セクションで、以下を入力します:

   - **プロジェクトID**：ワークロードIDプールのGoogle CloudプロジェクトID
   - **プロジェクト番号**：同じプロジェクトのGoogle Cloudプロジェクト番号

   Google CloudプロジェクトIDと番号を確認するには、[プロジェクトの識別](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)を参照してください。

1. **ワークロードアイデンティティフェデレーション**セクションに、以下を入力します:

   - **プールID**：ワークロードIDプールに付けた名前。
   - **プロバイダーID**：OIDCプロバイダーに付けた名前。

   ヒント：これらの値は、インテグレーションのセットアップに最初に使用したGitLabプロジェクトからコピーできます。

1. **変更を保存**を選択します。提供されているスクリプトは、ワークロードIDプールを作成するため、実行しないでください。既に存在します。

## 新しいGitLabプロジェクトでGoogle Artifact Registryインテグレーションを構成する {#configure-the-google-artifact-registry-integration-in-a-new-gitlab-project}

複数のコンテナイメージをArtifact Registryに保存できます。新しいGitLabプロジェクトで同じリポジトリを再利用するには、プロジェクトでGoogle Artifact Managementインテグレーションを構成します。

1. GitLabプロジェクトで、**設定** > **インテグレーション**を選択します。
1. **Googleアーティファクトの管理**を選択します
1. **リポジトリ**セクションに、以下を入力します:

   - **Google CloudプロジェクトID**：使用するArtifact RegistryリポジトリのプロジェクトID
   - **リポジトリ名**：リポジトリ名
   - **リポジトリの場所**：リポジトリの場所

1. **変更を保存**を選択します。ワークロードIDプールは、グループまたは組織内のGitLabユーザーにArtifact Registryの閲覧者とライターのロールを既に許可しているため、提供されているスクリプトは実行しないでください。

## GitLabリポジトリをクローンする {#clone-your-gitlab-repository}

SSHまたはHTTPSを使用してGitLabリポジトリを作業環境にクローンするには、[Gitリポジトリをローカルコンピューターにクローンする](../../topics/git/clone.md)の手順に従ってください。

## Dockerfileを作成する {#create-a-dockerfile}

1. クローンされたリポジトリに、`Dockerfile`Dockerfileという名前の新しいファイルを作成します。
1. 以下をコピーして`Dockerfile`Dockerfileに貼り付けます:

   ```dockerfile
   FROM python:3.12.4

   ARG name

   RUN mkdir web

   RUN cat <<EOF > web/index.html
   <!DOCTYPE html>
   <html>
       <head>
           <title>Home</title>
       </head>
       <body>
           <h1 color="green">Welcome to $name</h1>
       </body>
   </html>
   EOF

   CMD ["python3", "-m", "http.server", "8080", "-d", "web"]
   ```

1. `Dockerfile`DockerfileをGitに追加し、コミットして、GitLabリポジトリにプッシュします:

   ```shell
   git add Dockerfile
   git commit -m "add dockerfile"
   git push
   ```

   ユーザー名と[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)の入力を求められます。

DockerfileはHTTP Webサービスを作成します。

## パイプラインを作成する {#create-a-pipeline}

Dockerイメージをビルドし、GitLabコンテナレジストリにプッシュし、イメージをGoogle Artifact Registryにコピーし、Cloud Runを使用してGoogle Cloudインフラストラクチャにデプロイするパイプラインを作成します。

1. GitLabプロジェクトで、[`.gitlab-ci.yml`ファイル](../../ci/quick_start/_index.md#create-a-gitlab-ciyml-file)を作成します。

1. イメージをビルドし、GitLabコンテナレジストリにプッシュし、Google Artifact Registryにコピーし、Cloud Runを使用してデプロイするパイプラインを作成するには、`.gitlab-ci.yml`ファイルの内容を次のように変更します。

   次の例では、以下を置き換えます:

   - `LOCATION`：Google Artifact Registryリポジトリを作成したGoogle Cloudリージョン。
   - `PROJECT`：Artifact RegistryリポジトリのGoogle CloudプロジェクトID。
   - `REPOSITORY`：Google Artifact RegistryリポジトリのリポジトリID。

   ```yaml
   variables:
     IMAGE_TAG: v$CI_PIPELINE_ID
     AR_IMAGE: LOCATION-docker.pkg.dev/PROJECT/REPOSITORY/python-service

   stages:
     - build
     - push
     - deploy

   build-job:
     stage: build
     services:
       - docker:24.0.5-dind
     image: docker:git
     before_script:
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
     script:
       - docker build -t $CI_REGISTRY_IMAGE:$IMAGE_TAG --build-arg="name=Cloud Run" .
       - docker push $CI_REGISTRY_IMAGE:$IMAGE_TAG

   include:
     - component: gitlab.com/google-gitlab-components/artifact-registry/upload-artifact-registry@0.1.0
       inputs:
         stage: push
         source: $CI_REGISTRY_IMAGE:$IMAGE_TAG
         target: $AR_IMAGE:$IMAGE_TAG

     - component: gitlab.com/google-gitlab-components/cloud-run/deploy-cloud-run@0.1.0
       inputs:
         stage: deploy
         image: $AR_IMAGE:$IMAGE_TAG
         project_id: PROJECT
         region: LOCATION
         service: python-service

   ```

1. `.gitlab-ci.yml`ファイルをGitに追加し、コミットして、GitLabリポジトリにプッシュします。

このパイプラインは、以下を完了します:

- Docker-in-Dockerを使用してイメージ`python-service`をビルドします。
- GitLabコンテナレジストリにイメージを保存します。
- [Google Artifact Registry GitLabコンポーネント](https://gitlab.com/explore/catalog/google-gitlab-components/artifact-registry)を使用して、イメージをGoogle Artifact Registryにプッシュします。
- [Google Cloud Runコンポーネント](https://gitlab.com/google-gitlab-components/cloud-run)を使用して`python-service`をデプロイします。

## Google Cloud Runでサービスを表示する {#view-your-service-in-google-cloud-run}

1. Google Cloud Consoleで、[Cloud Runページ](https://console.cloud.google.com/run)に移動します。
1. **サービス**タブで作成したサービスを選択します。

   サービスの**メトリクス**タブが表示され、サービスのリージョン、URL、およびその他の詳細を表示できます。

## サービスをプロキシして表示する {#proxy-your-service-to-view}

サービスはプライベートであるため、認証を行わないと、Google Cloud ConsoleにリストされているURLから表示できません。サービスをテストするには、`gcloud` CLIを使用して認証を行い、サービスを`http://localhost:8080`にプロキシできます。

サービスをローカルでプロキシするには、次のコマンドを実行します:

```shell
gcloud run services proxy SERVICE \
    --project PROJECT_ID \
    --region=LOCATION
```

`http://localhost:8080`でウェルカムページを表示できます。

## クリーンアップ {#clean-up}

このページで使用されているリソースに対してGoogle Cloudアカウントに料金が発生しないようにするには、Google Cloudリソース、またはGoogle Cloudプロジェクト全体を削除できます。

ワークロードIDプールを含むプロジェクトを削除すると、すべてのセットアップ手順に再度従わない限り、インテグレーションを使用できません。

GitLabとGoogleの価格設定およびプロジェクト管理については、次のリソースを参照してください:

- [GitLabの価格](https://about.gitlab.com/free-trial/devsecops)
- [Googleの価格](https://cloud.google.com/pricing)
- [GitLabプロジェクトを削除する](../../user/project/working_with_projects.md#delete-a-project)

### Google Artifact Registryリポジトリを削除する {#delete-your-google-artifact-registry-repository}

Google Artifact Registryリポジトリを削除するには、このセクションの手順に従ってください。Google Cloudプロジェクト全体を削除する場合は、[プロジェクトを削除する](#delete-your-google-cloud-project)の手順に従ってください。

リポジトリを削除する前に、保持するイメージが別の場所で使用可能になっていることを確認してください。

リポジトリを削除するには、次のコマンドを実行します:

```shell
gcloud artifacts repositories delete REPOSITORY \
    --location=LOCATION
```

以下を置き換えます:

- Google Artifact RegistryリポジトリIDと`REPOSITORY`
- リポジトリの場所と`LOCATION`

### Cloud Runサービスを削除する {#delete-your-cloud-run-service}

1. Google Cloud Consoleで、[Cloud Runページ](https://console.cloud.google.com/run)に移動します。
1. サービスの横にあるチェックボックスをオンにします。
1. **削除**を選択します。

### Google Cloudプロジェクトを削除する {#delete-your-google-cloud-project}

**Caution**（注意）: プロジェクトを削除すると、次の影響があります:

- **Everything in the project is deleted**（プロジェクト内のすべてが削除されます）。このドキュメントのタスクに既存のプロジェクトを使用した場合、それを削除すると、プロジェクトで行った他の作業もすべて削除されます。
- **Custom project IDs are lost**（カスタムプロジェクトIDは失われます）。このプロジェクトを作成したときに、将来使用するカスタムプロジェクトIDを作成した可能性があります。appspot.com URLなど、プロジェクトIDを使用するURLを保持するには、プロジェクト全体を削除する代わりに、プロジェクト内の選択したリソースを削除します。

Google Cloudで複数のアーキテクチャ、チュートリアル、またはクイックスタートチュートリアルを調査することを計画している場合、プロジェクトを再利用すると、プロジェクトのクォータ制限を超えることを回避できます。

1. Google Cloud Consoleで、[**Manage resources**（リソースの管理）ページ](https://console.cloud.google.com/iam-admin/projects)に移動します。
1. プロジェクトリストで、削除するプロジェクトを選択し、**削除**を選択します。
1. ダイアログで、プロジェクトIDを入力し、**Shut down**（シャットダウン）を選択してプロジェクトを削除します。

## 関連トピック {#related-topics}

- [Cloud Runの詳細](https://cloud.google.com/run/docs/overview/what-is-cloud-run)。
