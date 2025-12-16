---
stage: Software Supply Chain Security
group: Compliance
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'チュートリアル: コンプライアンスパイプラインを作成する（非推奨）'
---

<!--- start_remove The following content will be removed on remove_date: '2026-08-15' -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

この機能は、GitLab 17.3で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159841)となり、19.0で削除される予定です。代わりに[パイプライン実行ポリシー](../../user/application_security/policies/pipeline_execution_policies.md)タイプを使用してください。これは破壊的な変更です。詳細については、[移行ガイド](../../user/compliance/compliance_pipelines.md#pipeline-execution-policies-migration)を参照してください。

{{< /alert >}}

<!-- vale gitlab_base.FutureTense = NO -->

[コンプライアンスパイプライン](../../user/compliance/compliance_pipelines.md)を使用すると、特定のコンプライアンス関連ジョブがグループ内のすべてのプロジェクトのパイプラインで確実に実行されるようにすることができます。コンプライアンスパイプラインは、[コンプライアンスフレームワーク](../../user/compliance/compliance_frameworks/_index.md)を通じてプロジェクトに適用されます。

このチュートリアルでは、以下のことを行います:

1. [新しいグループ](#create-a-new-group)を作成します。
1. [コンプライアンスパイプラインの設定用の新規プロジェクト](#create-a-new-compliance-pipeline-project)を作成します。
1. 他のプロジェクトに適用する[コンプライアンスフレームワーク](#configure-compliance-framework)を設定します。
1. [新規プロジェクトを作成し、コンプライアンスフレームワーク](#create-a-new-project-and-apply-the-compliance-framework)を適用します。
1. [コンプライアンスパイプラインの設定と通常のパイプラインの設定を組み合わせます](#combine-pipeline-configurations)。

## はじめる前 {#before-you-begin}

- 新しいトップレベルグループを作成する権限が必要です。

## 新しいグループを作成 {#create-a-new-group}

コンプライアンスフレームワークは、トップレベルグループで設定されます。このチュートリアルでは、以下のトップレベルグループを作成します:

- 2つのプロジェクトが含まれています:
  - コンプライアンスパイプラインの設定を保存するためのコンプライアンスパイプラインプロジェクト。
  - コンプライアンスパイプラインの設定で定義されたジョブをパイプラインで実行する必要がある別のプロジェクト。
- プロジェクトに適用するコンプライアンスフレームワークがあります。

新しいグループを作成するには:

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規グループ**を選択します。
1. **グループを作成**を選択します。
1. **グループ名**フィールドに、`Tutorial group`と入力します。
1. **グループを作成**を選択します。

## 新しいコンプライアンスパイプラインプロジェクトを作成します {#create-a-new-compliance-pipeline-project}

これで、コンプライアンスパイプラインプロジェクトを作成する準備ができました。このプロジェクトには、コンプライアンスフレームワークが適用されたすべてのプロジェクトに適用する[コンプライアンスパイプラインの設定](../../user/compliance/compliance_pipelines.md#example-configuration)が含まれています。

コンプライアンスパイプラインプロジェクトを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、`Tutorial group`グループを見つけます。
1. **新規プロジェクト**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. **プロジェクト名**フィールドに、`Tutorial compliance project`と入力します。
1. **プロジェクトを作成**を選択します。

`Tutorial compliance project`にコンプライアンスパイプラインの設定を追加するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、`Tutorial compliance project`プロジェクトを見つけます。
1. **ビルド** > **パイプラインエディタ**を選択します。
1. **パイプラインの設定**を選択します。
1. パイプラインエディタで、デフォルトの設定を以下のように置き換えます:

   ```yaml
   ---
   compliance-job:
     script:
       - echo "Running compliance job required for every project in this group..."
   ```

1. **変更をコミットする**を選択します。

## コンプライアンスフレームワークを設定します {#configure-compliance-framework}

コンプライアンスフレームワークは、[新しいグループ](#create-a-new-group)で設定されます。

コンプライアンスフレームワークを設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、`Tutorial group`グループを見つけます。
1. **セキュリティ** > **コンプライアンスセンター**を選択します。
1. ページで、**フレームワーク**タブを選択します。
1. **新規フレームワーク**を選択します。
1. **名前**フィールドに、`Tutorial compliance framework`と入力します。
1. **説明**フィールドに、`Compliance framework for tutorial`と入力します。
1. **コンプライアンスパイプラインの設定 (オプション)**フィールドに、`.gitlab-ci.yml@tutorial-group/tutorial-compliance-project`と入力します。
1. **背景色**フィールドで、お好みの色を選択します。
1. **フレームワークを追加**を選択します。

便宜上、新しいコンプライアンスフレームワークをグループ内のすべての新しいプロジェクトのデフォルトに設定します:

1. 左側のサイドバーで、**検索または移動先**を選択して、`Tutorial group`グループを見つけます。
1. **セキュリティ** > **コンプライアンスセンター**を選択します。
1. ページで、**フレームワーク**タブを選択します。
1. `Tutorial compliance framework`を選択し、**フレームワークを編集**を選択します。
1. **デフォルトとして設定**を選択します。
1. **変更を保存**を選択します。

## 新規プロジェクトを作成し、コンプライアンスフレームワークを適用します {#create-a-new-project-and-apply-the-compliance-framework}

コンプライアンスフレームワークの準備ができたので、グループにプロジェクトを作成すると、パイプラインでコンプライアンスパイプラインの設定が自動的に実行されるようになります。

コンプライアンスパイプラインの設定を実行するための新しいプロジェクトを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、`Tutorial group`グループを見つけます。
1. **新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. **プロジェクト名**フィールドに、`Tutorial project`と入力します。
1. **プロジェクトを作成**を選択します。

プロジェクトページに、`Tutorial compliance framework`というラベルが表示されています。これは、グループのデフォルトのコンプライアンスフレームワークとして設定されているためです。

他のパイプラインの設定がない場合、`Tutorial project`は、`Tutorial compliance project`のコンプライアンスパイプラインの設定で定義されたジョブを実行できます。

`Tutorial project`でコンプライアンスパイプラインの設定を実行するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、`Tutorial project`プロジェクトを見つけます。
1. **ビルド** > **パイプライン**を選択します。
1. **パイプラインを新規作成**を選択します。
1. **パイプラインを新規作成**ページで、**パイプラインの実行**を選択します。

パイプラインが**test**（test）ステージングで`compliance-job`という名前のジョブを実行することに注目してください。よくできました。最初のコンプライアンスジョブを実行しました。

## パイプラインの設定を組み合わせます {#combine-pipeline-configurations}

プロジェクトで独自のジョブとコンプライアンスパイプラインのジョブを実行する場合は、コンプライアンスパイプラインの設定とプロジェクトの通常パイプラインの設定を組み合わせる必要があります。

パイプラインの設定を組み合わせるには、通常のパイプラインの設定を定義し、コンプライアンスパイプラインの設定を更新して参照する必要があります。

通常のパイプラインの設定を作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、`Tutorial project`プロジェクトを見つけます。
1. **ビルド** > **パイプラインエディタ**を選択します。
1. **パイプラインの設定**を選択します。
1. パイプラインエディタで、デフォルトの設定を以下のように置き換えます:

   ```yaml
   ---
   project-job:
     script:
       - echo "Running project job..."
   ```

1. **変更をコミットする**を選択します。

新しいプロジェクトパイプラインの設定をコンプライアンスパイプラインの設定と組み合わせるには:

1. 左側のサイドバーで、**検索または移動先**を選択して、`Tutorial compliance project`プロジェクトを見つけます。
1. **ビルド** > **パイプラインエディタ**を選択します。
1. 既存の設定に、以下を追加します:

   ```yaml
   include:
     - project: 'tutorial-group/tutorial-project'
       file: '.gitlab-ci.yml'
    ```

1. **変更をコミットする**を選択します。

通常のパイプラインの設定がコンプライアンスパイプラインの設定と組み合わされていることを確認するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、`Tutorial project`プロジェクトを見つけます。
1. **ビルド** > **パイプライン**を選択します。
1. **パイプラインを新規作成**を選択します。
1. **パイプラインを新規作成**ページで、**パイプラインの実行**を選択します。

パイプラインが**test**（test）ステージングで2つのジョブを実行することに注目してください:

- `compliance-job`
- `project-job`

おめでとうございます。コンプライアンスパイプラインを作成および設定しました。

[コンプライアンスパイプラインの設定例](../../user/compliance/compliance_pipelines.md#example-configuration)をさらにご覧ください。

<!--- end_remove -->
