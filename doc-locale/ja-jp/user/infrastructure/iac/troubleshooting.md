---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: TerraformとGitLabのインテグレーションに関するトラブルシューティング
---

TerraformとGitLabのインテグレーションを使用している場合、トラブルシューティングが必要なイシューが発生することがあります。

## `gitlab_group_share_group`リソースが、サブグループの状態が更新されたときに検出されない {#gitlab_group_share_group-resources-not-detected-when-subgroup-state-is-refreshed}

GitLab Terraformプロバイダーは、[「権限を持つユーザーがAPIから`share_with_groups`取得できない」](https://gitlab.com/gitlab-org/gitlab/-/issues/328428)というイシューが原因で、既存の`gitlab_group_share_group`リソースを検出できない場合があります。これにより、Terraformが既存のリソースを再作成しようとするため、`terraform apply`の実行時にエラーが発生します。

たとえば、次のグループ/サブグループの設定について考えてみます:

```plaintext
parent-group
├── subgroup-A
└── subgroup-B
```

各設定項目の意味は次のとおりです:

- ユーザー`user-1`が`parent-group`、`subgroup-A`、および`subgroup-B`を作成します。
- `subgroup-A`は`subgroup-B`と共有されます。
- ユーザー`terraform-user`は、両方のサブグループへの継承された`owner`アクセスを持つ`parent-group`のメンバーです。

Terraformのステートファイルが更新されると、プロバイダーによって発行されたAPIクエリ`GET /groups/:subgroup-A_id`は、`shared_with_groups`配列内の`subgroup-B`の詳細を返しません。これによりエラーが発生します。

この回避策として、次のいずれかの条件を適用してください:

1. `terraform-user`がすべてのサブグループリソースを作成します。
1. `subgroup-B`の`terraform-user`ユーザーにメンテナーまたはオーナーロールを付与します。
1. `terraform-user`は`subgroup-B`へのアクセスを継承し、`subgroup-B`には少なくとも1つのプロジェクトが含まれています。

## Terraformステートファイルのトラブルシューティング {#troubleshooting-terraform-state}

### 前のジョブのプランで`terraform apply`のCIジョブでTerraformステートファイルをロックできません {#cant-lock-terraform-state-files-in-ci-jobs-for-terraform-apply-with-a-previous-jobs-plan}

`terraform init`に`-backend-config=`を渡すと、Terraformはこれらの値をプランキャッシュファイル内に保持します。これには、`password`の値が含まれます。

その結果、プランを作成し、後で別のCIジョブで同じプランを使用するには、`-backend-config=password=$CI_JOB_TOKEN`を使用すると、エラー`Error: Error acquiring the state lock`が発生する可能性があります。これは、`$CI_JOB_TOKEN`の値が現在のジョブの期間中のみ有効であるために発生します。

回避策として、CIジョブで[httpバックエンド設定変数](https://www.terraform.io/language/settings/backends/http#configuration-variables)を使用します。これは、[GitLab CIを使用した開始方法](terraform_state.md#initialize-an-opentofu-state-as-a-backend-by-using-gitlab-cicd)の手順に従うと、バックグラウンドで発生するものです。

### エラー: `"address": required field is not set` {#error-address-required-field-is-not-set}

デフォルトでは、`TF_ADDRESS`を`${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/terraform/state/${TF_STATE_NAME}`に設定します。ジョブで`TF_STATE_NAME`または`TF_ADDRESS`を設定しない場合、ジョブはエラーメッセージ`Error: "address": required field is not set`で失敗します。

これを解決するには、エラーを返したジョブで`TF_ADDRESS`または`TF_STATE_NAME`のいずれかにアクセスできることを確認します:

1. ジョブの[CI/CD環境スコープ](../../../ci/variables/_index.md#for-a-project)を設定します。
1. 前の手順の環境スコープに合わせて、ジョブの[環境](../../../ci/yaml/_index.md#environment)を設定します。

### 状態の更新エラー: HTTPリモートステートファイルエンドポイントには認証が必要です {#error-refreshing-state-http-remote-state-endpoint-requires-auth}

これを解決するには、以下を確認してください:

- 使用するアクセストークンに`api`スコープがある。
- `TF_HTTP_PASSWORD` CI/CD変数を設定している場合は、次のいずれかを確認してください:
  - `TF_PASSWORD`と同じ値を設定します
  - CI/CDジョブで明示的に使用しない場合は、`TF_HTTP_PASSWORD`変数を削除します。

### デベロッパーロールが破壊的なコマンドへのアクセスを有効にする {#enable-developer-role-access-to-destructive-commands}

デベロッパーロールを持つユーザーが破壊的なコマンドを実行できるようにするには、回避策が必要です:

1. `api`スコープで[プロジェクトアクセストークンを作成](../../project/settings/project_access_tokens.md#create-a-project-access-token)します。
1. `TF_USERNAME`と`TF_PASSWORD`をCI/CD変数に追加します:
   1. `TF_USERNAME`の値をプロジェクトアクセストークンのユーザー名に設定します。
   1. `TF_PASSWORD`の値をプロジェクトアクセストークンのパスワードに設定します。
   1. オプション。変数を保護ブランチまたは保護タグで実行されるパイプラインでのみ利用可能にするには、変数を保護してください。

### ステートファイル名にピリオドが含まれている場合、ステートファイルが見つかりません {#state-not-found-if-the-state-name-contains-a-period}

GitLab 15.6以前は、ステートファイル名にピリオドが含まれており、Terraformがステートファイルのロックを試みると、404エラーを返していました。

`-lock=false`をTerraformコマンドに追加することで、この制限を回避できました。GitLabバックエンドはリクエストを受け入れましたが、内部的にはピリオドとそれに続くすべての文字をステートファイル名から削除しました。たとえば、`foo.bar`という名前のステートファイルは、`foo`として保存されます。ただし、この回避策は推奨されておらず、ステートファイル名の衝突を引き起こす可能性さえありました。

GitLab 15.7以降では、[ピリオドを含むステートファイル名がサポートされています](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106861)。`-lock=false`回避策を使用し、GitLab 15.7以降にアップグレードすると、ジョブが失敗する可能性があります。この失敗は、GitLabバックエンドが完全なステートファイル名で新しいステートファイルを保存し、既存のステートファイル名と異なることが原因で発生します。

失敗するジョブを修正するには、ステートファイル名を変更して、ピリオドとそれに続く文字を除外します。

`TF_HTTP_ADDRESS`、`TF_HTTP_LOCK_ADDRESS`、および`TF_HTTP_UNLOCK_ADDRESS`が設定されている場合は、そこにステートファイル名を必ず更新してください。

または、[OpenTofuステートファイルを移行することもできます](terraform_state.md#migrate-to-a-gitlab-managed-opentofu-state)。

### ステートファイルの保存エラー: HTTPエラー: 404 {#error-saving-state-http-error-404}

このエラーは、ステートファイル名にフォワードスラッシュ（`/`）文字が含まれている場合に発生する可能性があります。これを解決するには、ステートファイル名にフォワードスラッシュ（`/`）文字が含まれていないことを確認してください。
