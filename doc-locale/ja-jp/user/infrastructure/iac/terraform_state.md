---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab管理のTerraform/OpenTofuの状態
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- ピリオドを含む状態名のサポートは、GitLab 15.7で`allow_dots_on_tf_state_names`という名前の[フラグとともに](../../../administration/feature_flags.md)導入されました。デフォルトでは無効になっています。
- GitLab 16.0では、ピリオドを含む状態名のサポートが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/385597)されています。機能フラグ`allow_dots_on_tf_state_names`を削除しました。

{{< /history >}}

チーム全体でインフラストラクチャのステートファイルを管理するには、セキュリティと信頼性の両方が必要とされます。GitLab管理のOpenTofuの状態により、状態管理の一般的な課題が解消されます。最小限の設定で、OpenTofuの状態をGitLabプロジェクトの通常の拡張機能にすることができます。この統合により、インフラストラクチャの定義、コード、および状態をすべて1つの安全な場所に保持できます。

GitLab管理のOpenTofuの状態を使用すると、次のことが可能になります。

- 保存時に自動で暗号化してステートファイルを安全に保存する
- 組み込みのバージョニングで変更を追跡し、誰がいつ何を変更したかを特定する
- 個別の認証システムを作成するのではなく、GitLab権限モデルを使用してアクセスを制御する
- ステートファイルを競合または破損させることなくチーム間で共同作業を行う
- 既存のGitLab CI/CDパイプラインとシームレスに統合する
- CI/CDジョブとローカル開発環境の両方から状態にリモートでアクセスする

{{< alert type="warning" >}}

**ディザスタリカバリ計画**OpenTofuのステートファイルは、ディスク上およびオブジェクトストレージ内で、[db_key_baseアプリケーション設定](../../../development/application_secrets.md#secret-entries)由来のキーを使用して、lockbox Ruby gemで暗号化されます。[ステートファイルを復号化するには、GitLabが利用可能である必要があります](https://gitlab.com/gitlab-org/gitlab/-/issues/335739)。オフラインの場合、GitLabが必要とするインフラストラクチャ（仮想マシン、Kubernetesクラスター、ネットワークコンポーネントなど）のデプロイにGitLabを使用しても、ステートファイルに簡単にアクセスしたり、復号化したりすることはできません。さらに、GitLabのブートストラップに必要なOpenTofuモジュールまたはその他の依存関係をGitLabが提供している場合、これらにアクセスできなくなります。この問題を回避するには、これらの依存関係をホストまたはバックアップするために別途調整を行うか、障害点を共有しない別のGitLabインスタンスを使用することを検討してください。

{{< /alert >}}

## 前提要件

GitLab Self-Managedの場合、OpenTofuのステートファイルにGitLabを使用する前に、次のことを行う必要があります。

- 管理者が[Terraform/OpenTofuの状態ストレージを設定します](../../../administration/terraform_state.md)。
- プロジェクトの**インフラストラクチャ**メニューをオンにします。
  1. **設定 > 一般**に移動します。
  1. **表示レベル、プロジェクトの機能、権限**を展開します。
  1. **インフラストラクチャ**でトグルをオンにします。

## GitLab CI/CDを使用して、OpenTofuの状態をバックエンドとして初期化する

前提要件:

- `tofu apply`を使用して、状態のロック、ロック解除、および書き込みを行うには、メンテナー以上のロールが必要です。
- `tofu plan -lock=false`を使用して状態を読み取るには、デベロッパー以上のロールが必要です。

{{< alert type="warning" >}}

他のジョブアーティファクトと同様に、OpenTofuプランのデータは、リポジトリに対するゲストロールを持つすべてのユーザーが表示できます。OpenTofuおよびGitLabは、いずれもデフォルトではプランファイルを暗号化しません。OpenTofuの`plan.json`ファイルまたは`plan.cache`ファイルに、パスワード、アクセストークン、証明書などの機密データが含まれている場合は、プランの出力を暗号化するか、プロジェクトの表示設定を変更する必要があります。また、[パブリックパイプライン](../../../ci/pipelines/settings.md#change-pipeline-visibility-for-non-project-members-in-public-projects)を**無効にし**、[アーティファクトのアクセスフラグを「デベロッパー」](../../../ci/yaml/_index.md#artifactsaccess)（`access: 'developer'`）に設定する必要があります。この設定により、アーティファクトは、GitLab管理者と、デベロッパー以上のロールを持つプロジェクトメンバーのみがアクセスできるようになります。

{{< /alert >}}

GitLab CI/CDをバックエンドとして設定するには:

1. OpenTofuプロジェクトで、`backend.tf`などの`.tf`ファイルに[HTTPバックエンド](https://opentofu.org/docs/language/settings/backends/http/)を定義します。

   ```hcl
   terraform {
     backend "http" {
     }
   }
   ```

1. プロジェクトリポジトリのルートディレクトリに`.gitlab-ci.yml`ファイルを作成します。[OpenTofu CI/CDコンポーネント](https://gitlab.com/components/opentofu)を使用して、`.gitlab-ci.yml`ファイルを形成します。
1. プロジェクトをGitLabにプッシュします。このアクションにより、`gitlab-tofu init`、`gitlab-tofu validate`、および`gitlab-tofu plan`コマンドを実行するパイプラインがトリガーされます。
1. 前のパイプラインから手動の`deploy`ジョブをトリガーします。このアクションにより`gitlab-tofu apply`コマンドが実行され、定義されたインフラストラクチャがプロビジョニングされます。

上記のコマンドからの出力は、ジョブログで表示できるはずです。

`gitlab-tofu` CLIは、`tofu` CLIのラッパーです。

### OpenTofuの環境変数をカスタマイズする

CI/CDジョブの定義時に、[OpenTofu HTTP設定変数](https://opentofu.org/docs/language/settings/backends/http/#configuration-variables)を使用できます。

`init`をカスタマイズし、OpenTofuの設定をオーバーライドするには、`init -backend-config=...`アプローチではなく環境変数を使用します。`-backend-config`を使用すると、設定は次のようになります。

- `plan`コマンドの出力にキャッシュされます。
- 通常は`apply`コマンドに転送されます。

この設定により、[CIジョブでステートファイルをロックできない](troubleshooting.md#cant-lock-terraform-state-files-in-ci-jobs-for-terraform-apply-with-a-previous-jobs-plan)などの問題が発生する可能性があります。

## ローカルマシンから状態にアクセスする

ローカルマシンからGitLab管理のOpenTofuの状態にアクセスできます。

{{< alert type="warning" >}}

GitLabのクラスター化されたデプロイでは、ローカルストレージを使用しないでください。ノード間で状態が分割され、後続のOpenTofuの実行に矛盾が生じる可能性があります。代わりに、リモートストレージリソースを使用してください。

{{< /alert >}}

1. OpenTofuの状態が[CI/CD用に初期化されている](#initialize-an-opentofu-state-as-a-backend-by-using-gitlab-cicd)ことを確認します。
1. 自動入力されたOpenTofu `init`コマンドをコピーします。

   1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
   1. **操作 > Terraform状態**を選択します。
   1. 使用する環境の横にある**アクション**（{{< icon name="ellipsis_v" >}}）を選択し、**Terraform initコマンドをコピー**を選択します。

1. ターミナルを開き、ローカルマシンでこのコマンドを実行します。

## GitLab管理のOpenTofuの状態に移行する

OpenTofuは、バックエンドの変更時または再設定時に状態をコピーする操作をサポートしています。これらのアクションを使用して、別のバックエンドからGitLab管理のOpenTofuの状態に移行します。

GitLab管理のOpenTofuの状態への移行に必要なコマンドを実行するには、ローカルターミナルを使用する必要があります。

以下の例は、状態名の変更方法を示しています。別の状態のストレージバックエンドからGitLab管理のOpenTofuの状態に移行するには、同じワークフローが必要です。

これらのコマンドは[ローカルマシン](#access-the-state-from-your-local-machine)で実行する必要があります。

### 初期バックエンドを設定する

```shell
PROJECT_ID="<gitlab-project-id>"
TF_USERNAME="<gitlab-username>"
TF_PASSWORD="<gitlab-personal-access-token>"
TF_ADDRESS="https://gitlab.com/api/v4/projects/${PROJECT_ID}/terraform/state/old-state-name"

tofu init \
  -backend-config=address=${TF_ADDRESS} \
  -backend-config=lock_address=${TF_ADDRESS}/lock \
  -backend-config=unlock_address=${TF_ADDRESS}/lock \
  -backend-config=username=${TF_USERNAME} \
  -backend-config=password=${TF_PASSWORD} \
  -backend-config=lock_method=POST \
  -backend-config=unlock_method=DELETE \
  -backend-config=retry_wait_min=5
```

```plaintext
Initializing the backend...

Successfully configured the backend "http"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
re-run this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### バックエンドを変更する

`tofu init`が古い状態の場所を認識する`.terraform/`ディレクトリを作成したので、新しい場所を教えることができます。

```shell
TF_ADDRESS="https://gitlab.com/api/v4/projects/${PROJECT_ID}/terraform/state/new-state-name"

terraform init \
  -migrate-state \
  -backend-config=address=${TF_ADDRESS} \
  -backend-config=lock_address=${TF_ADDRESS}/lock \
  -backend-config=unlock_address=${TF_ADDRESS}/lock \
  -backend-config=username=${TF_USERNAME} \
  -backend-config=password=${TF_PASSWORD} \
  -backend-config=lock_method=POST \
  -backend-config=unlock_method=DELETE \
  -backend-config=retry_wait_min=5
```

```plaintext
Initializing the backend...
Backend configuration changed!

Terraform has detected that the configuration specified for the backend
has changed. Terraform will now check for existing state in the backends.


Acquiring state lock. This may take a few moments...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "http" backend to the
  newly configured "http" backend. No existing state was found in the newly
  configured "http" backend. Do you want to copy this state to the new "http"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes


Successfully configured the backend "http"! Terraform will automatically
use this backend unless the backend configuration changes.

Initializing provider plugins...

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

`yes`と入力すると、状態が古い場所から新しい場所にコピーされます。その後、GitLab CI/CDでの実行に戻ることができます。

## GitLabバックエンドをリモートデータソースとして使用する

GitLab管理のOpenTofuの状態バックエンドを[OpenTofuデータソース](https://opentofu.org/docs/language/state/remote-state-data/)として使用できます。

1. `main.tf`またはその他の関連ファイルで、これらの変数を宣言します。値は空のままにします。

   ```hcl
   variable "example_remote_state_address" {
     type = string
     description = "Gitlab remote state file address"
   }

   variable "example_username" {
     type = string
     description = "Gitlab username to query remote state"
   }

   variable "example_access_token" {
     type = string
     description = "GitLab access token to query remote state"
   }
   ```

1. 前の手順の値をオーバーライドするには、`example.auto.tfvars`という名前のファイルを作成します。このファイルは、プロジェクトリポジトリで**バージョニングしないでください**。

   ```plaintext
   example_remote_state_address = "https://gitlab.com/api/v4/projects/<TARGET-PROJECT-ID>/terraform/state/<TARGET-STATE-NAME>"
   example_username = "<GitLab username>"
   example_access_token = "<GitLab personal access token>"
   ```

1. `.tf`ファイルで、[OpenTofu入力変数](https://opentofu.org/docs/language/values/variables/)を使用してデータソースを定義します。

   ```hcl
   data "terraform_remote_state" "example" {
     backend = "http"

     config = {
       address = var.example_remote_state_address
       username = var.example_username
       password = var.example_access_token
     }
   }
   ```

   - **address（アドレス）**: データソースとして使用するリモート状態バックエンドのURLです。たとえば、`https://gitlab.com/api/v4/projects/<TARGET-PROJECT-ID>/terraform/state/<TARGET-STATE-NAME>`などです。
   - **username（ユーザー名）**: データソースで認証するためのユーザー名です。[パーソナルアクセストークン](../../profile/personal_access_tokens.md)を認証に使用している場合、この値はGitLabのユーザー名になります。GitLab CI/CDを使用している場合、この値は`'gitlab-ci-token'`になります。
   - **password（パスワード）**: データソースで認証を行うためのパスワードです。パーソナルアクセストークンを認証に使用している場合、この値はトークン値になります（トークンには**API**スコープが必要です）。GitLab CI/CD を使用している場合、この値は`${CI_JOB_TOKEN}` CI/CD変数の内容になります。

データソースからの出力は、`data.terraform_remote_state.example.outputs.<OUTPUT-NAME>`を使用してTerraformリソースで参照できるようになりました。

ターゲットプロジェクトでOpenTofuの状態を読み取るには、デベロッパー以上のロールが必要です。

## OpenTofuのステートファイルを管理する

OpenTofuのステートファイルを表示するには:

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **操作 > Terraform状態**を選択します。

このUIの改善を追跡するための[エピックが存在します](https://gitlab.com/groups/gitlab-org/-/epics/4563)。

### 個々のOpenTofuの状態バージョンを管理する

個々の状態バージョンは、GitLab REST APIを使用して管理できます。

デベロッパー以上のロールがある場合は、シリアル番号を使用して状態バージョンを取得できます。

```shell
curl --header "Private-Token: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<your_project_id>/terraform/state/<your_state_name>/versions/<version-serial>"
```

メンテナー以上のロールがある場合は、シリアル番号を使用して状態バージョンを削除できます。

```shell
curl --header "Private-Token: <your_access_token>" --request DELETE "https://gitlab.example.com/api/v4/projects/<your_project_id>/terraform/state/<your_state_name>/versions/<version-serial>"
```

### ステートファイルを削除する

メンテナー以上のロールがある場合は、ステートファイルを削除できます。

1. 左側のサイドバーで、**操作 > Terraform状態**を選択します。
1. **アクション**列で、**アクション**（{{< icon name="ellipsis_v" >}}）を選択し、次に**ステートファイルとバージョンを削除**を選択します。

### APIを使用してステートファイルを削除する

パーソナルアクセストークンを使用してREST APIにリクエストを送信することで、ステートファイルを削除できます。

```shell
curl --header "Private-Token: <your_access_token>" --request DELETE "https://gitlab.example.com/api/v4/projects/<your_project_id>/terraform/state/<your_state_name>"
```

[CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)と基本認証も使用できます。

```shell
curl --user "gitlab-ci-token:$CI_JOB_TOKEN" --request DELETE "https://gitlab.example.com/api/v4/projects/<your_project_id>/terraform/state/<your_state_name>"
```

[GraphQL API](../../../api/graphql/reference/_index.md#mutationterraformstatedelete)も使用できます。

## 関連トピック

- [GitLab管理のTerraform 状態のトラブルシューティング](troubleshooting.md)
- [サンプルプロジェクト: カスタムVPCでのAWS EC2インスタンスのTerraformデプロイ](https://gitlab.com/gitlab-org/configure/examples/gitlab-terraform-aws)
