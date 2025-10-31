---
stage: Verify
group: Tutorials
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: Google Cloudインテグレーションをセットアッする'
---

<!-- vale gitlab_base.FutureTense = NO -->

このチュートリアルでは、Google CloudをGitLabと統合して、Google Cloudに直接デプロイする方法について説明します。

Google Cloudインテグレーションをセットアップするには、次の手順に従ってください:

1. [Google Cloudアイデンティティおよびアクセス管理（IAM）で利用を保護する](#secure-your-usage-with-google-cloud-identity-and-access-management-iam)
1. [Google Artifact Registryリポジトリに接続する](#connect-to-a-google-artifact-registry-repository)
1. [Google CloudでCI/CDジョブを実行するようにGitLab Runnerをセットアップする](#set-up-gitlab-runner-to-execute-your-cicd-jobs-on-google-cloud)
1. [CI/CDコンポーネントを使用してGoogle Cloudにデプロイする](#deploy-to-google-cloud-with-cicd-components)

## はじめる前 {#before-you-begin}

インテグレーションを設定するには、次のことをする必要があります:

- 少なくともメンテナーロールを持つGitLabプロジェクトが必要です。
- 使用するGoogle Cloudプロジェクトの[オーナー](https://cloud.google.com/iam/docs/understanding-roles#owner) IAMロールが必要です。
- [Google Cloudプロジェクトの課金が有効になっている](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#confirm_billing_is_enabled_on_a_project)必要があります。
- Docker形式と標準モードのGoogle Artifact Registryリポジトリが必要です。
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install)と[Terraform](https://developer.hashicorp.com/terraform/install)をインストールします。

## Google Cloudアイデンティティおよびアクセス管理（IAM）で利用を保護する {#secure-your-usage-with-google-cloud-identity-and-access-management-iam}

Google Cloudの利用を保護するには、Google Cloud IAMインテグレーションをセットアップする必要があります。この手順の後、GitLabグループまたはプロジェクトがGoogle Cloudに接続されます。ワークロードアイデンティティフェデレーションを使用して、サービスアカウントキーを必要とせずに、関連するリスクを使用して、Google Cloudリソースの権限を処理できます。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループまたはプロジェクトを見つけます。グループでこれを設定すると、設定はデフォルトで内部のすべてのプロジェクトに適用されます。
1. **設定** > **インテグレーション**を選択します。
1. **Google Cloud IAM**を選択します。
1. **Guided setup**（ガイド付きセットアップ）を選択し、指示に従います。

## Google Artifact Registryリポジトリに接続する {#connect-to-a-google-artifact-registry-repository}

Google IAMインテグレーションがセットアップされたので、Google Artifact Registryリポジトリに接続できます。この手順の後、GitLabでGoogle Cloudアーティファクトを表示できます。

1. GitLabプロジェクトで、左側のサイドバーで、**設定** > **インテグレーション**を選択します。
1. **Googleアーティファクトのレジストリ**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. フィールドに入力します:
   - **[Google CloudプロジェクトID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)**: Artifact Registryリポジトリが配置されているGoogle CloudプロジェクトのID。
   - **リポジトリ名**: Artifact Registryリポジトリの名前。
   - **リポジトリの場所**: Artifact Registryリポジトリの場所。
1. **Configure Google Cloud IAM policies**（Google Cloud IAMポリシーを設定する）で、画面の指示に従ってGoogle CloudでIAMポリシーをセットアップします。これらのポリシーは、GitLabプロジェクトでArtifact Registryリポジトリを使用するために必要です。
1. **変更を保存**を選択します。
1. Google Cloudアーティファクトを表示するには、左側のサイドバーで**デプロイ** > **Googleアーティファクトのレジストリ**を選択します。

後の手順で、コンテナイメージをGoogle Artifact Registryにプッシュします。

## Google CloudでCI/CDジョブを実行するようにGitLab Runnerをセットアップする {#set-up-gitlab-runner-to-execute-your-cicd-jobs-on-google-cloud}

Google CloudでCI/CDジョブを実行するようにGitLab Runnerをセットアップできます。この手順の後、GitLabプロジェクトには、複数のジョブを同時に実行するために一時的なRunnerを作成するRunnerマネージャーを備えた、オートスケールRunnerフリートがあります。

1. GitLabプロジェクトで、左側のサイドバーで、**設定** > **CI/CD**を選択します。
1. **Runners**セクションを展開します。
1. **New project runner**（新しいプロジェクトRunner）を選択します。
1. フィールドに入力します。
   - **プラットフォーム**セクションで、**Google Cloud**を選択します。
   - **タグ**セクションの**タグ**フィールドに、ジョブタグを入力してRunnerが実行できるジョブを指定します。このRunnerのジョブタグがない場合は、**Run untagged**（タグなしで実行）を選択します。
   - オプション。**Runnerの説明**フィールドに、GitLabに表示されるRunnerの説明を追加します。
   - オプション。**設定**セクションで、その他の設定を追加します。
1. **Runnerを作成**を選択します。
1. **ステップ1のフィールドに入力します: 環境を指定**セクションで、RunnerがCI/CDジョブを実行するGoogle Cloudの環境を指定します。
1. **ステップ2の下: GitLab Runnerをセットアップする**で、**セットアップ手順**を選択します。
1. モーダルウィンドウ内の指示に従ってください。**ステップ1**は、Runnerをプロビジョニングする準備ができるように、Google Cloudプロジェクトに対して1回だけ行う必要があります。

手順に従うと、Runnerがオンラインになり、ジョブを実行できるようになるまでに1分かかる場合があります。

## CI/CDコンポーネントを使用してGoogle Cloudにデプロイする {#deploy-to-google-cloud-with-cicd-components}

開発のベストプラクティスは、パイプライン全体の整合性を維持するために、CI/CDコンポーネントなどの構文を再利用することです。

GitLabとGoogleのコンポーネントのライブラリを使用して、GitLabプロジェクトがGoogle Cloudリソースと対話できるようにすることができます。[GoogleのCI/CDコンポーネント](https://gitlab.com/google-gitlab-components)を参照してください。

### Google Artifact Registryにコンテナイメージをコピーする {#copy-container-images-to-google-artifact-registry}

開始する前に、コンテナイメージをビルドしてGitLabコンテナレジストリにプッシュする、動作するCI/CD設定が必要です。

GitLabコンテナレジストリからGoogle Artifact Registryにコンテナイメージをコピーするには、パイプラインに[GoogleのCI/CDコンポーネント](https://gitlab.com/explore/catalog/google-gitlab-components/artifact-registry)を含めます。この手順の後、新しいコンテナイメージがGitLabコンテナレジストリにプッシュされるたびに、Google Artifact Registryにもプッシュされます。

1. GitLabプロジェクトで、左側のサイドバーで、**ビルド** > **パイプラインエディタ**を選択します。
1. 既存の設定で、次のようにコンポーネントを追加します。
   - このジョブが実行されるステージで`<your_stage>`を置き換えます。イメージがビルドされ、GitLabコンテナレジストリにプッシュされた後である必要があります。

   ```yaml
   include:
     - component: gitlab.com/google-gitlab-components/artifact-registry/upload-artifact-registry@main
       inputs:
         stage: <your_stage>
         source: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
         target: $GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_LOCATION-docker.pkg.dev/$GOOGLE_ARTIFACT_REGISTRY_PROJECT_ID/$GOOGLE_ARTIFACT_REGISTRY_REPOSITORY_NAME/$CI_PROJECT_NAME:$CI_COMMIT_SHORT_SHA
   ```

1. 記述的なコミットメッセージを追加します。**ターゲットブランチ**はデフォルトブランチである必要があります。
1. **変更をコミットする**を選択します。
1. **ビルド** > **パイプライン**に移動し、新しいパイプラインが実行されていることを確認します。
1. パイプラインが正常に完了した後、Google Artifact Registryにコピーされたコンテナイメージを表示するには、左側のサイドバーで**デプロイ** > **Googleアーティファクトのレジストリ**を選択します。

### Google Cloudリリースを作成する {#create-a-google-cloud-deploy-release}

Google Cloudデプロイと統合するには、パイプラインに[GoogleのCI/CDコンポーネント](https://gitlab.com/explore/catalog/google-gitlab-components/cloud-deploy)を含めます。この手順の後、パイプラインはアプリケーションでGoogle Cloudデプロイリリースを作成します。

1. GitLabプロジェクトで、左側のサイドバーで、**ビルド** > **パイプラインエディタ**を選択します。
1. 既存の設定で、[Google Cloudデプロイコンポーネント](https://gitlab.com/explore/catalog/google-gitlab-components/cloud-deploy)を追加します。
1. コンポーネントの`inputs`を編集します。
1. 記述的なコミットメッセージを追加します。**ターゲットブランチ**はデフォルトブランチである必要があります。
1. **変更をコミットする**を選択します。
1. **ビルド** > **パイプライン**に移動し、新しいパイプラインが合格することを確認します。
1. パイプラインが正常に完了した後、リリースを表示するには、[Google Cloudドキュメント](https://cloud.google.com/deploy/docs/view-release)を参照してください。

以上です。Google CloudをGitLabと統合し、GitLabプロジェクトをGoogle Cloudにシームレスにデプロイしました。

## 関連トピック {#related-topics}

- [Google Cloud IAMインテグレーション](../../integration/google_cloud_iam.md)
- [Google Artifact Managementインテグレーション](../../user/project/integrations/google_artifact_management.md)
- [Google CloudでRunnerをプロビジョニングする](../../ci/runners/provision_runners_google_cloud.md)
