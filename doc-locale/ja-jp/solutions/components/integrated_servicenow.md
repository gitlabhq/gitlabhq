---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: 統合された変更管理 - ServiceNow
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ServiceNowのバージョン: 最新バージョン、Xanadu、および以前のバージョンとの下位互換性

{{< /details >}}

このドキュメントでは、ServiceNow DevOps Change Velocityを使用して、GitLabが統合されたServiceNowソリューションで変更管理をオーケストレーションを行うための手順と機能の詳細について説明します。

ServiceNow DevOps Change Velocityインテグレーションを使用すると、ServiceNowのGitLabリポジトリとCI/CDパイプラインのアクティビティーに関する情報を追跡できます。

これにより、GitLab CI/CDパイプラインとインテグレーションされたときに、変更リクエストの作成が自動化され、ポリシー基準に基づいて変更リクエストが自動的に承認されます。

このドキュメントでは、次の方法について説明します。

1. ServiceNowとGitLabをChange Velocityとインテグレーションして、変更管理を行います。
1. GitLab CI/CDパイプラインで、ServiceNowに変更リクエストを自動的に作成します。
1. CABのレビューと承認が必要な場合は、ServiceNowで変更リクエストを承認します。
1. 変更リクエストの承認に基づいて、本番環境へのデプロイを開始します。

## はじめに {#getting-started}

### ソリューションコンポーネントをダウンロード {#download-the-solution-component}

1. アカウントチームから招待コードを入手してください。
1. 招待コードを使用して、[ソリューションコンポーネントウェブストア](https://cloud.gitlab-accelerator-marketplace.com)からソリューションコンポーネントをダウンロードします。

## 変更管理のインテグレーションオプション {#integration-options-for-change-management}

GitLabとServiceNowをインテグレーションする方法は複数あります。このソリューションコンポーネントには、次のオプションがあります:

1. 組み込みの変更リクエストプロセス用のServiceNow DevOps Changeベロシティ
1. ベロシティコンテナイメージを使用したカスタム変更リクエストによるServiceNow DevOps Changeベロシティ
1. カスタム変更リクエストプロセス用のServiceNow Rest API

## ServiceNow DevOps Changeベロシティ {#servicenow-devops-change-velocity}

ServiceNowストアからDevOps Changeベロシティをインストールして構成すると、DevOps Changeワークスペースで直接変更を自動作成することで、変更制御を有効にできます。

### 組み込みの変更リクエストプロセス {#built-in-change-request-process}

ServiceNow DevOps Changeベロシティは、通常の変更プロセス用の組み込みの変更リクエストモデルを提供し、自動的に作成された変更リクエストにはデフォルトの命名規則があります。

通常の変更プロセスでは、本番環境へのデプロイパイプラインジョブを実行する前に、変更リクエストが承認される必要があります。

#### パイプラインと変更リクエストジョブの設定 {#setup-the-pipeline-and-change-request-jobs}

ソリューションリポジトリの`gitlab-ci-workflow1.yml`サンプルパイプラインを開始点として使用します。自動変更作成を有効にし、変更属性をパイプラインを介して渡す手順については、以下を確認してください。

注: 詳細な手順については、[DevOpsの変更リクエスト作成を自動化する](https://www.servicenow.com/docs/bundle/yokohama-it-service-management/page/product/enterprise-dev-ops/task/automate-devops-change-request.html)を参照してください。

以下は、概要レベルの手順です:

1. DevOps Changeワークスペースから、[変更]タブに移動し、[変更の自動化]を選択します。

   ![変更の自動化]オプションが選択されたDevOps Changeワークスペース。](img/snow_automate_cr_creation_v17_9.png)

1. [アプリケーション]フィールドで、変更リクエストの作成を自動化するパイプラインに関連付けるアプリケーションを選択し、[次へ]を選択します。
1. 自動変更リクエストの作成をトリガーするステップ（ステージング）があるパイプラインを選択します。たとえば、変更リクエスト作成ステップなどです。
1. 変更リクエストの自動作成をトリガーするパイプラインのステップを選択します。
1. 変更フィールドで変更属性を指定し、[変更受領]オプションを選択して、変更受領を有効にします。
1. パイプラインを変更し、対応するコードスニペットを使用して、変更制御を有効にし、変更属性を指定します。たとえば、変更制御が有効になっているジョブに次の2つの設定を追加します:

   ```yaml
      when: manual
      allow_failure: false
   ```

    ![変更制御をサポートするように更新されたGitLab CI/CDパイプラインジョブ。](img/snow_automated_cr_pipeline_update_v17_9.png)

#### 変更管理によるパイプラインの実行 {#run-pipeline-with-change-management}

前の手順が完了すると、プロジェクトのCDパイプラインは、`gitlab-ci-workflow1.yml`サンプルパイプラインに示されているジョブを組み込むことができます。

変更管理でパイプラインを実行するには:

1. ServiceNowでは、パイプラインのステージングの1つに対して変更制御が有効になっています。

   ![パイプラインで変更制御が有効になっているServiceNowステージング。](img/snow_change_control_enabled_v17_9.png)

1. GitLabでは、変更制御機能を使用するパイプラインジョブが実行されます。

   ![変更承認のために一時停止されたGitLabパイプライン。](img/snow_pipeline_pause_for_approval_v17_9.png)

1. ServiceNowでは、変更リクエストがServiceNowで自動的に作成されます。

   ![ServiceNowの変更リクエストは承認待ちです。](img/snow_cr_waiting_for_approval_v17_9.png)

1. ServiceNowで、変更リクエストを承認します。

   ![ServiceNowの変更リクエストが承認済みとしてマークされました。](img/snow_cr_approved_v17_9.png)

1. パイプラインが再開され、変更リクエストの承認時に本番環境へのデプロイの次のジョブを開始します。

   ![変更承認後に再開されるGitLabパイプライン。](img/snow_pipeline_resumes_v17_9.png)

### ベロシティコンテナイメージによるカスタムアクション {#custom-actions-with-velocity-container-image}

ServiceNowカスタムアクションをDevOps ChangeベロシティDockerイメージ経由で使用して、変更リクエストのタイトル、説明、変更計画、ロールバック計画、デプロイされるアーティファクトに関連するデータ、およびパッケージ登録を設定します。これにより、パイプラインメタデータを変更リクエストの説明として渡す代わりに、変更リクエストの説明をカスタマイズできます。

#### パイプラインと変更リクエストジョブの設定 {#setup-the-pipeline-and-change-request-jobs-1}

これはServiceNow DevOps Changeベロシティへのアドオンであるため、以前のセットアップ手順は同じです。Dockerイメージをパイプライン定義に含めるだけで済みます。

このリポジトリの`gitlab-ci-workflow2.yml`サンプルパイプラインを例として使用します。

1. ジョブで使用するイメージを指定します。必要に応じて、イメージバージョンを更新します。

   ```yaml
      image: servicenowdocker/sndevops:5.0.0
   ```

1. 特定のアクションにはCLIを使用します。たとえば、sndevops CLIを使用して変更リクエストを作成するには

   ```yaml
   sndevopscli create change -p {
        "changeStepDetails": {
          "timeout": 3600,
          "interval": 100
        },
        "autoCloseChange": true,
        "attributes": {
          "short_description": "'"${CHANGE_REQUEST_SHORT_DESCRIPTION}"'",
          "description": "'"${CHANGE_REQUEST_DESCRIPTION}"'",
          "assignment_group": "'"${ASSIGNMENT_GROUP_ID}"'",
          "implementation_plan": "'"${CR_IMPLEMENTATION_PLAN}"'",
          "backout_plan": "'"${CR_BACKOUT_PLAN}"'",
          "test_plan": "'"${CR_TEST_PLAN}"'"
        }
      }

   ```

#### カスタム変更管理によるパイプラインの実行 {#run-pipeline-with-custom-change-management}

`gitlab-ci-workflow2.yml`サンプルパイプラインを開始点として使用します。前の手順が完了すると、プロジェクトのCDパイプラインは、`gitlab-ci-workflow2.yml`サンプルパイプラインに示されているジョブを組み込むことができます。

カスタム変更管理でパイプラインを実行するには:

1. ServiceNowでは、パイプラインのステージングの1つに対して変更制御が有効になっています。

   ![カスタム変更フローを使用して変更制御が有効になっているServiceNowステージング。](img/snow_change_control_enabled_v17_9.png)

1. GitLabでは、変更制御機能を使用するパイプラインジョブが実行されます。

   ![変更リクエスト作成ワークフロー2](img/snow_cr_creation_workflow2_v17_9.png)

1. ServiceNowでは、`servicenowdocker/sndevops`イメージを使用して、パイプライン変数の値から提供されるカスタムタイトル、説明、およびその他のフィールドを使用して、変更リクエストが作成されます。

   ![パイプラインからのカスタム値で作成されたServiceNow変更リクエスト。](img/snow_pipeline_workflow2_v17_9.png)

1. GitLabでは、変更リクエスト番号とその他の情報をパイプラインの詳細で確認できます。パイプラインジョブは、変更リクエストが承認されるまで実行されたままであり、その後、次のジョブに進みます。

   ![承認ワークフロー2後のパイプライン変更の詳細](img/snow_pipeline_details_workflow2_v17_9.png)

1. ServiceNowで、変更リクエストを承認します。

   ![パイプラインの詳細ワークフロー2](img/snow_pipeline_cr_details_workflow2_v17_9.png)

1. GitLabでは、パイプラインジョブが再開され、変更リクエストの承認時に本番環境へのデプロイである次のジョブを開始します。

   ![パイプラインがワークフロー2を再開します](img/snow_pipeline_resumes_workflow2_v17_9.png)
