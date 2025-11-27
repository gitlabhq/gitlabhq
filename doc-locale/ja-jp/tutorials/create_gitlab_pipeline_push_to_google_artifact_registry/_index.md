---
stage: Verify
group: tutorials
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: Google Artifact RegistryにプッシュするGitLabパイプラインを作成する'
---

GitLabをGoogle Cloudに接続し、Compute Engine上のRunnerを使用して、Artifact RegistryにイメージをプッシュするGitLabパイプラインを作成する方法について説明します。

## はじめる前 {#before-you-begin}

1. このページのコマンドを実行するには、次のいずれかの開発環境で`gcloud` CLIをセットアップします:

   - [Cloud Shell](https://cloud.google.com/shell/docs/using-cloud-shell)
   - [ローカルshell](https://cloud.google.com/sdk/docs/install)。

1. Google Cloudプロジェクトを作成または選択します。

   {{< alert type="note" >}}

   この手順で作成するリソースを保持する予定がない場合は、既存のプロジェクトを選択する代わりに、新しいGoogle Cloudプロジェクトを作成してください。これらの手順を完了したら、プロジェクトを削除して、プロジェクトに関連付けられているすべてのリソースを削除できます。

   {{< /alert >}}

   Google Cloudプロジェクトを作成するには、次のコマンドを実行します:

   ```shell
   gcloud projects create PROJECT_ID
   ```

   `PROJECT_ID`を、作成するGoogle Cloudプロジェクトの名前に置き換えます。

1. 作成したGoogle Cloudプロジェクトを選択します:

   ```shell
   gcloud config set project PROJECT_ID
   ```

   `PROJECT_ID`をGoogle Cloudプロジェクト名に置き換えます。

1. [Google Cloudプロジェクトで課金が有効になっていることを確認してください](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#console)。

1. Compute EngineとArtifact RegistryのAPIを有効にします:

   ```shell
   gcloud services enable compute.googleapis.com artifactregistry.googleapis.com
   ```

1. [Google CloudワークロードアイデンティティフェデレーションとIAMポリシー](../../integration/google_cloud_iam.md)の手順に従って、Google CloudとのGitLabインテグレーションをセットアップします。

1. [標準モードのDocker形式のArtifact Registryリポジトリを作成します](https://cloud.google.com/artifact-registry/docs/repositories/create-repos#create)。

1. [GitLabプロジェクトでGoogle Artifact Registryをセットアップする](../../user/project/integrations/google_artifact_management.md)の手順に従って、Artifact RegistryリポジトリをGitLabプロジェクトに接続します。

## GitLabリポジトリをクローンする {#clone-your-gitlab-repository}

1. SSHまたはHTTPSを使用して、GitLabリポジトリを作業環境にクローンするには、[Gitリポジトリをローカルコンピューターにクローンする](../../topics/git/clone.md)の手順に従ってください。

1. ローカルShellで作業している場合は、[Terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform)をインストールします。TerraformはCloud Shellに既にインストールされています。

## Dockerfileを作成する {#create-a-dockerfile}

1. クローンしたリポジトリに、`Dockerfile`という名前の新しいファイルを作成します。
1. 次の内容を`Dockerfile`にコピーして貼り付けます。

   ```dockerfile
   # Dockerfile for test purposes. Generates a new random image in every build.
   FROM alpine:3.15.11
   RUN dd if=/dev/urandom of=random bs=10 count=1
   ```

1. `Dockerfile`をGitに追加し、コミットして、GitLabリポジトリにプッシュします。

   ```shell
   git add Dockerfile
   git commit -m "add dockerfile"
   git push
   ```

   ユーザー名と[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)を入力するように求められます。

Dockerfileはビルドごとに新しいランダムなイメージを生成し、テストのみを目的としています。

## Google Compute EngineでCIRunnerの継続的インテグレーション（CI）を有効にする {#enable-continuous-integration-ci-runners-on-google-compute-engine}

[GitLab Runner](https://docs.gitlab.com/runner/)は、GitLab CICI/CDと連携してパイプラインでジョブを実行するアプリケーションです。Google Cloud上のGitLabインテグレーションは、Compute Engine上でオートスケールRunnerフリートの設定を支援し、一時的なRunnerを作成して複数のジョブを同時に実行するRunnerマネージャーを提供します。

オートスケールRunnerフリートをセットアップするには、[Google CloudでCI/CDジョブを実行するようにGitLab Runnerをセットアップする](../set_up_gitlab_google_integration/_index.md#set-up-gitlab-runner-to-execute-your-cicd-jobs-on-google-cloud)の手順に従ってください。CI/CDジョブを実行するRunnerの環境としてGoogle Cloudを選択し、残りの設定の詳細を入力します。

Runnerの詳細を入力したら、セットアップ手順に従って、Google Cloudプロジェクトを設定し、GitLab Runnerをインストールして登録し、提供されているterraformを作業環境に適用して設定を適用します。

## パイプラインを作成する {#create-a-pipeline}

Dockerイメージをビルドし、GitLabコンテナレジストリにプッシュし、イメージをGoogle Artifact Registryにコピーするパイプラインを作成します。

1. GitLabプロジェクトで、[`.gitlab-ci.yml`ファイル](../../ci/quick_start/_index.md#create-a-gitlab-ciyml-file)を作成します。

1. Dockerイメージをビルドし、GitLabコンテナレジストリにプッシュし、イメージをGoogle Artifact Registryにコピーするパイプラインを作成するには、`.gitlab-ci.yml`ファイルの内容を次のように変更します。

   例では、以下を置き換えます:

   - `LOCATION`: Google Artifact Registryリポジトリを作成したGoogle Cloudリージョン。
   - `PROJECT`: Google CloudプロジェクトID。
   - `REPOSITORY`: Google Artifact RegistryリポジトリのリポジトリID。

   ```yaml
   stages:
     - build
     - deploy

   variables:
     GITLAB_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

   build-sample-image:
     image: docker:24.0.5-cli
     stage: build
     services:
       - docker:24.0.5-dind
     before_script:
       - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
     script:
       - docker build -t $GITLAB_IMAGE .
       - docker push $GITLAB_IMAGE

   include:
     - component: gitlab.com/google-gitlab-components/artifact-registry/upload-artifact-registry@0.1.0
       inputs:
         stage: deploy
         source: $GITLAB_IMAGE
         target: LOCATION-docker.pkg.dev/PROJECT/REPOSITORY/image:v1.0.0
   ```

このパイプラインは、Docker in Dockerを使用してイメージ`docker:24.0.5`をビルドし、GitLabコンテナレジストリに保存し、[Google Artifact Registry GitLabコンポーネント](https://gitlab.com/explore/catalog/google-gitlab-components/artifact-registry)を使用して、バージョン`v1.0.0`でGoogle Artifact Registryリポジトリにプッシュします。

## アーティファクトを表示する {#view-your-artifacts}

GitLabでアーティファクトを表示するには:

1. GitLabプロジェクトの左側のサイドバーで、**ビルド** > **アーティファクト**を選択します。
1. ビルドの詳細を表示するアーティファクトの名前を選択します。

Google Artifact Registryでアーティファクトを表示するには:

1. [Google Cloud Consoleで**リポジトリ**ページを開きます](https://console.cloud.google.com/artifacts)。
1. リンクされたリポジトリの名前を選択します。
1. イメージの名前を選択して、バージョン名とタグを表示します。
1. イメージバージョンの名前を選択して、バージョンのビルド、プル、マニフェスト情報を表示します。

## クリーンアップ {#clean-up}

このページで使用されているリソースに対してGoogle Cloudアカウントに料金が発生しないようにするには、Google Cloudプロジェクトを削除します。プロジェクトを保持する場合は、Google Artifact Registryリポジトリを削除できます。

GitLabとGoogle Artifact Registryの価格とプロジェクト管理については、次のリソースを参照してください:

- [GitLabの価格](https://about.gitlab.com/free-trial/devsecops)
- [GitLabプロジェクトを削除する](../../user/project/working_with_projects.md#delete-a-project)
- [Google Artifact Registryの価格](https://cloud.google.com/artifact-registry/pricing)

### Google Artifact Registryリポジトリを削除する {#delete-your-google-artifact-registry-repository}

Google Cloudプロジェクトを保持し、Google Artifact Registryリポジトリリソースのみを削除する場合は、このセクションの手順に従ってください。Google Cloudプロジェクト全体を削除する場合は、[プロジェクトを削除する](#delete-your-google-cloud-project)の手順に従ってください。

リポジトリを削除する前に、保持するイメージが別の場所で使用可能になっていることを確認してください。

リポジトリを削除するには、次のコマンドを実行します:

```shell
gcloud artifacts repositories delete REPOSITORY \
    --location=LOCATION
```

以下を置き換えてください:

- `REPOSITORY`をGoogle Artifact RegistryリポジトリIDに置き換えます
- `LOCATION`をリポジトリの場所に置き換えます

### Google Cloudプロジェクトを削除する {#delete-your-google-cloud-project}

**Caution**（注意）: プロジェクトを削除すると、次の影響があります:

- **Everything in the project is deleted**（プロジェクト内のすべてが削除されます）。このドキュメントのタスクに既存のプロジェクトを使用した場合は、それを削除すると、プロジェクトで行った他の作業もすべて削除されます。
- **Custom project IDs are lost**（カスタムプロジェクトIDが失われます）。このプロジェクトを作成したときに、将来使用するカスタムプロジェクトIDを作成した可能性があります。appspot.com URLなど、プロジェクトIDを使用するURLを保持するには、プロジェクト全体を削除する代わりに、プロジェクト内の選択したリソースを削除します。

複数のアーキテクチャ、チュートリアル、またはGoogle Cloudのクイックスタートチュートリアルを調査する場合は、プロジェクトを再利用すると、プロジェクトのクォータ制限を超えることを回避できます。

1. Google Cloud Consoleで、[**Manage resources**（リソースの管理）ページ](https://console.cloud.google.com/iam-admin/projects)に移動します。
1. プロジェクトリストで、削除するプロジェクトを選択し、**削除**を選択します。
1. ダイアログで、プロジェクトIDを入力し、**Shut down**（シャットダウン）を選択してプロジェクトを削除します。

## 関連トピック {#related-topics}

- [GitLab CI/CDの設定ファイルを最適化](../../ci/yaml/yaml_optimization.md)する方法を学びます。
- Google Cloud上のGitLabインテグレーションが、IAMとワークロードアイデンティティフェデレーションを使用してGoogle Cloudへのアクセス制御を制御する方法については、[IAMによるアクセス制御](https://cloud.google.com/docs/gitlab)を参照してください。
