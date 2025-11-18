---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Google Cloud Compute EngineでRunnerをプロビジョニングする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 16.10で`google_cloud_support_feature_flag`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438316)されました。この機能は[ベータ版](../../policy/development_stages_support.md)です。
- GitLab 17.1の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)になりました。機能フラグ`google_cloud_support_feature_flag`は削除されました。

{{< /history >}}

GitLab.comのプロジェクトRunnerまたはグループRunnerを作成し、Google Cloudプロジェクトでプロビジョニングできます。Runnerを作成すると、GitLabユーザーインターフェースに、Google CloudプロジェクトでRunnerを自動的にプロビジョニングするための画面上の指示とスクリプトが表示されます。

Runnerを作成すると、Runner認証トークンがRunnerに割り当てられます。[GRIT](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit) Terraformスクリプトは、このトークンを使用してRunnerを登録します。Runnerは、ジョブキューからジョブを取得するときに、トークンを使用してGitLabで認証。

プロビジョニング後、オートスケールRunnerフリートは、Google CloudでCI/CDジョブを実行する準備ができています。Runnerマネージャーは、一時的なRunnerを自動的に作成します。

前提要件: 

- グループRunnerの場合: グループのオーナーロール。
- プロジェクトRunnerの場合: プロジェクトのメンテナーロール。
- Google Cloud Platformプロジェクトの場合: [オーナー](https://cloud.google.com/iam/docs/understanding-roles#owner) IAMロール。
- Google Cloud Platformプロジェクトの[課金が有効](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled#confirm_billing_is_enabled_on_a_project)。
- Google CloudプロジェクトのIAMロールで認証された、稼働中の[`gcloud`CLIツール](https://cloud.google.com/sdk/docs/install)。
- [Terraform v1.5以降](https://releases.hashicorp.com/terraform/1.5.7/)および[Terraform CLIツール](https://developer.hashicorp.com/terraform/install)。
- Bashがインストールされたターミナル。

グループRunnerまたはプロジェクトRunnerを作成し、Google Cloudでプロビジョニングするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 新しいRunnerを作成します。
   - 新しいグループRunnerを作成するには、**Build > Runners > New group runner**（ビルド > Runners > 新しいグループRunner）を選択します。
   - 新しいプロジェクトRunnerを作成するには、**Settings > CI/CD > Runners > New project runner**（設定 > CI/CD > Runners > 新しいプロジェクトRunner）を選択します。
1. **タグ**セクションの**タグ**フィールドに、ジョブタグを入力してRunnerが実行できるジョブを指定します。タグ付けされたジョブに加えて、タグ付けされていないジョブにRunnerを使用するには、**Run untagged**（タグなしで実行）を選択します。
1. オプション。**設定**セクションで、Runnerの説明と追加の設定を追加します。
1. **Runnerを作成**を選択します。
1. **プラットフォーム**セクションで、**Google Cloud**を選択します。
1. **環境**で、Google Cloud環境の次の詳細を入力します:

   - **Google CloudプロジェクトID**
   - **リージョン**
   - **ゾーン**
   - **マシンタイプ**

1. **Set up GitLab Runner**（GitLab Runnerのセットアップ）で、**セットアップ手順**を選択します。ダイアログで:

   1. 必要なサービス、サービスアカウント、および権限を有効にするには、**Configure Google Cloud project**（Google Cloudプロジェクトを設定する）で、各Google Cloudプロジェクトに対してBashを1回実行します。
   1. **Install and register GitLab Runner**（GitLab Runnerのインストールと登録）からの設定を含む`main.tf`ファイルを作成します。このスクリプトは、Runnerマネージャーを実行するために、Google Cloudプロジェクトでインフラストラクチャをプロビジョニングするために[GitLab Runner Infrastructure Toolkit](https://gitlab.com/gitlab-org/ci-cd/runner-tools/grit/-/blob/main/docs/scenarios/google/linux/docker-autoscaler-default/index.md)（GRIT）を使用します。

スクリプトを実行すると、RunnerマネージャーがRunner認証トークンに接続されます。Runnerマネージャーがオンラインとして表示され、ジョブの受信を開始するまでに最大1分かかる場合があります。
