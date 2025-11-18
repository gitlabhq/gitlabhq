---
stage: none
group: Tutorials
info: For assistance with this tutorial, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: 'チュートリアル: Runnerの作成と登録を自動化する'
---

このチュートリアルでは、Runnerの作成と登録を自動化する方法について説明します。

Runnerの作成と登録を自動化するには:

1. [パーソナルアクセストークンを作成する](#create-a-personal-access-token)。
1. [Runner設定を作成する](#create-a-runner-configuration)。
1. [GitLab Runnerのインストールと登録を自動化する](#automate-runner-installation-and-registration)。
1. [同じ設定のRunnerを表示する](#view-runners-with-the-same-configuration)。

{{< alert type="note" >}}

このチュートリアルの手順では、Runner認証トークンを使用したRunnerの作成と登録について説明します。これは、非推奨となった登録トークンによる登録方法に代わるものです。詳細については、[新しいRunner登録ワークフロー](../../ci/runners/new_creation_workflow.md#the-new-runner-registration-workflow)を参照してください。

{{< /alert >}}

## はじめる前 {#before-you-begin}

- GitLab RunnerがGitLabインスタンスにインストールされている必要があります。
- インスタンスRunnerを作成するには、管理者である必要があります。
- グループRunnerを作成するには、管理者であるか、グループのオーナーロールを持っている必要があります。
- プロジェクトRunnerを作成するには、管理者であるか、プロジェクトのメンテナーロールを持っている必要があります。

## アクセストークンを作成する {#create-an-access-token}

REST APIを使用してRunnerを作成できるように、アクセストークンを作成します。

次のアクセストークンを作成できます:

- 共有Runner、グループRunner、プロジェクトRunnerで使用するパーソナルアクセストークン。
- グループRunnerおよびプロジェクトRunnerで使用するグループアクセストークンまたはプロジェクトアクセストークン。

アクセストークンは、GitLab UIで1回のみ表示されます。ページを離れると、トークンにアクセスできなくなります。HashiCorp VaultやKeeper Secrets Manager Terraformプラグインなどのシークレット管理ソリューションを使用して、トークンを保存することをおすすめします。

### パーソナルアクセストークンを作成する {#create-a-personal-access-token}

{{< history >}}

- GitLab 17.6で`buffered_token_expiration_limit`[フラグにより](../../administration/feature_flags/_index.md) 、最大許容ライフタイム制限が400日に[引き上げられました](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

拡張された最大許容ライフタイム制限の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**パーソナルアクセストークン**を選択します。
1. **新しいトークンを追加**を選択します。
1. トークンの名前と有効期限を入力します。
   - トークンは、その日付の午前0時（UTC）に有効期限切れになります。有効期限が2024-01-01のトークンは、2024-01-01の00:00:00 UTCに期限切れになります。
   - 有効期限を入力しない場合、有効期限は現在の日付より365日後に自動的に設定されます。
   - デフォルトでは、この日付は現在の日付より最大365日後に設定できます。GitLab 17.6以降では、[この制限を400日に延長](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)できます。
1. **スコープを選択**セクションで、**create_runner**（create_runner）チェックボックスをオンにします。
1. **Create personal access token**（パーソナルアクセストークンを作成）を選択します。

### プロジェクトアクセストークンまたはグループアクセストークンを作成する {#create-a-project-or-group-access-token}

{{< history >}}

- GitLab 17.6で`buffered_token_expiration_limit`[フラグにより](../../administration/feature_flags/_index.md) 、最大許容ライフタイム制限が400日に[引き上げられました](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

拡張された最大許容ライフタイム制限の可用性は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

{{< alert type="warning" >}}

プロジェクトアクセストークンは[内部ユーザー](../../administration/internal_users.md)として扱われます。内部ユーザーがプロジェクトアクセストークンを作成した場合、そのトークンは、表示レベルが[内部](../../user/public_access.md)に設定されているすべてのプロジェクトにアクセスできます。

{{< /alert >}}

プロジェクトアクセストークンを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. **設定** > **アクセストークン**を選択します。
1. **新しいトークンを追加**を選択します
1. 名前を入力します。トークン名は、グループまたはプロジェクトを表示する権限を持つすべてのユーザーに表示されます。
1. トークンの有効期限を入力します。
   - トークンは、その日付の午前0時（UTC）に有効期限切れになります。有効期限が2024-01-01のトークンは、2024-01-01の00:00:00 UTCに期限切れになります。
   - 有効期限を入力しない場合、有効期限は現在の日付より365日後に自動的に設定されます。
   - デフォルトでは、この日付は現在の日付より最大365日後に設定できます。GitLab 17.6以降では、[この制限を400日に延長](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)できます。

   - インスタンス全体の[最大ライフタイム](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)設定により、GitLab Self-Managedインスタンスで許可される最大ライフタイムが制限される場合があります。
1. **ロールを選択**ドロップダウンリストで、次の手順を実行します:
   - プロジェクトアクセストークンの場合は、**メンテナー**を選択します。
   - グループアクセストークンの場合は、**オーナー**を選択します。
1. **スコープを選択**セクションで、**create_runner**（create_runner）チェックボックスをオンにします。
1. **Create project access token**（プロジェクトアクセストークンを作成）を選択します。

## Runner設定を作成する {#create-a-runner-configuration}

Runner設定では、要件に合わせてRunnerを設定します。

Runner設定を作成すると、Runnerを登録するためのRunner認証が付与されます。1つまたは複数のRunnerを同じRunner認証トークンで登録すると、これらのRunnerを同じ設定にリンクできます。Runner設定は、`config.toml`ファイルに保存されます。

次のいずれかを使用して、Runner設定を作成できます:

- GitLab REST API。
- `gitlab_user_runner` Terraformリソース。

### GitLab REST APIを使用する場合 {#with-the-gitlab-rest-api}

はじめる前に、次のものが必要です:

- GitLabインスタンスのURL。たとえば、プロジェクトが`gitlab.example.com/yourname/yourproject`でホスティングされている場合、GitLabインスタンスのURLは`https://gitlab.example.com`です。
- グループRunnerまたはプロジェクトRunnerの場合は、グループまたはプロジェクトのID番号。ID番号は、プロジェクトまたはグループの概要ページで、プロジェクト名またはグループ名の下に表示されます。

[`POST /user/runners`](../../api/users.md#create-a-runner-linked-to-a-user) RESTエンドポイントでアクセストークンを使用してRunnerを作成します:

1. `curl`を使用し、エンドポイントを呼び出してRunnerを作成します:

   {{< tabs >}}

   {{< tab title="プロジェクト" >}}

   ```shell
   curl --silent --request POST --url "https://gitlab.example.com/api/v4/user/runners"
     --data "runner_type=project_type"
     --data "project_id=<project_id>"
     --data "description=<your_runner_description>"
     --data "tag_list=<your_comma_separated_job_tags>"
     --header "PRIVATE-TOKEN: <project_access_token>"
   ```

   {{< /tab >}}

   {{< tab title="グループ" >}}

   ```shell
   curl --silent --request POST --url "https://gitlab.example.com/api/v4/user/runners"
     --data "runner_type=group_type"
     --data "group_id=<group_id>"
     --data "description=<your_runner_description>"
     --data "tag_list=<your_comma_separated_job_tags>"
     --header "PRIVATE-TOKEN: <group_access_token>"
   ```

   {{< /tab >}}

   {{< tab title="共有" >}}

   ```shell
   curl --silent --request POST --url "https://gitlab.example.com/api/v4/user/runners"
     --data "runner_type=instance_type"
     --data "description=<your_runner_description>"
     --data "tag_list=<your_comma_separated_job_tags>"
     --header "PRIVATE-TOKEN: <personal_access_token>"
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. 返された`token`値を安全な場所またはシークレット管理ソリューションに保存します。`token`値は、API応答で1回のみ返されます。

### `gitlab_user_runner` Terraformリソースを使用する場合 {#with-the-gitlab_user_runner-terraform-resource}

TerraformでRunner設定を作成するには、[GitLab Terraformプロバイダー](https://gitlab.com/gitlab-org/terraform-provider-gitlab)の[`gitlab_user_runner` Terraformリソース](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/blob/main/docs/resources/user_runner.md?ref_type=heads)を使用します。

設定ブロックの例を次に示します:

```terraform
resource "gitlab_user_runner" "example_runner" {
  runner_type = "instance_type"
  description = "my-runner"
  tag_list = ["shell", "docker"]
}
```

## Runnerのインストールと登録を自動化する {#automate-runner-installation-and-registration}

パブリッククラウドの仮想マシンインスタンスでRunnerをホストする場合は、Runnerのインストールと登録を自動化できます。

Runnerとその設定を作成した後、同じRunner認証トークンを使用して、同じ設定で複数のRunnerを登録できます。たとえば、同じexecutorタイプとジョブタグを持つ複数のインスタンスRunnerをターゲットコンピューティングホストにデプロイできます。同じRunner認証トークンで登録された各Runnerには一意の`system_id`があります。このIDはGitLab Runnerによってランダムに生成され、ローカルファイルシステムに保存されます。

Runnerを登録し、Google Compute Engineにデプロイするために使用できる自動化GitLabワークフローの例を次に示します:

1. [Terraform Infrastructure as Code](../../user/infrastructure/iac/_index.md)を使用して、Google Cloud Platform（GCP）でホストされている仮想マシンにRunnerアプリケーションをインストールします。
1. [GCP Terraformプロバイダー](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance)で、`metadata`キーを使用して、GCP仮想マシンのRunner設定ファイルにRunner認証トークンを追加します。
1. ターゲットGitLabインスタンスにRunnerを登録するには、GCP Terraformプロバイダーから入力された`cloud-init`スクリプトを使用します。次に例を示します:

   ```shell
   #!/bin/bash
   apt update
   curl --location "https://packages.gitlab.com/install/repositories/runner/
   gitlab-runner/script.deb.sh" | bash
   GL_NAME=$(curl 169.254.169.254/computeMetadata/v1/instance/name
   --header "Metadata-Flavor:Google")
   GL_EXECUTOR=$(curl 169.254.169.254/computeMetadata/v1/instance/attributes/
   gl_executor --header "Metadata-Flavor:Google")
   apt update
   apt install -y gitlab-runner
   gitlab-runner register --non-interactive --name="$GL_NAME" --url="https://gitlab.com"
     --token="$RUNNER_TOKEN" --request-concurrency="12" --executor="$GL_EXECUTOR"
     --docker-image="alpine:latest"
   systemctl restart gitlab-runner
   ```

## 同じ設定のRunnerを表示する {#view-runners-with-the-same-configuration}

Runnerの作成と登録を自動化したので、GitLab UIで同じ設定を使用するRunnerを表示できます。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **CI/CD** > **Runners**を選択します。
1. 検索ボックスに、Runnerの説明を入力するか、Runnerのリストを検索します。
1. 同じ設定を使用するRunnerを表示するには、**詳細**タブの**Runners**の横にある**詳細を表示**を選択します。
