---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Google CloudワークロードアイデンティティフェデレーションとIAMポリシー
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 16.10で`google_cloud_support_feature_flag`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141127)されました。
- GitLab 17.1の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)になりました。機能フラグ`google_cloud_support_feature_flag`は削除されました。

{{< /history >}}

[Google Artifact Managementインテグレーション](../user/project/integrations/google_artifact_management.md)のようなGoogle Cloudインテグレーションを使用するには、[Workload Identityプールとプロバイダ](https://cloud.google.com/iam/docs/workload-identity-federation)を作成し、設定する必要があります。Google Cloudインテグレーションは、ワークロードアイデンティティフェデレーションを使用して、JSON Webトークン（JWT）トークンを使用することにより、OpenID Connect（OIDC）を介してGitLabワークロードがGoogle Cloudリソースにアクセスできるようにします。

## ワークロードアイデンティティフェデレーション {#workload-identity-federation}

ワークロードアイデンティティフェデレーションを使用すると、Identity and Access Management（IAM）を使用して、外部アイデンティティ管理に[IAMロール](https://cloud.google.com/iam/docs/overview#roles)を付与できます。

従来、Google Cloudの外部で実行されているアプリケーションは、Google Cloudリソースにアクセスするために[サービスアカウントキー](https://cloud.google.com/iam/docs/service-account-creds#key-types)を使用していました。ただし、サービスアカウントキーは強力な認証情報であるため、適切に管理されていない場合はセキュリティリスクが生じる可能性があります。

アイデンティティフェデレーションを使用すると、Identity and Access Management（IAM）を使用して、サービスアカウントを必要とせずに、外部アイデンティティ管理にIAMロールを直接付与できます。このアプローチにより、サービスアカウントとそのキーに関連するメンテナンスとセキュリティの負担が軽減されます。

## Workload identityプール {#workload-identity-pools}

_Workload identityプール_は、Google Cloud上の非Googleアイデンティティ管理を管理できるエンティティです。

Google Cloudインテグレーション上のGitLabでは、Google Cloudに認証するためのWorkload identityプールの設定について説明します。この設定には、GitLabロールの属性をGoogle Cloud IAMポリシーのIAMクレームにマップすることが含まれます。Google Cloudインテグレーション上のGitLabで使用可能なGitLabの属性の完全なリストについては、[OIDCカスタムクレーム](#oidc-custom-claims)を参照してください。

## Workload Identityプールプロバイダ {#workload-identity-pool-providers}

_Workload Identityプールプロバイダ_は、Google CloudとIdentity Provider（IdP）との関係を記述するエンティティです。GitLabは、Google Cloudインテグレーション上のGitLabのWorkload identityプールのIdPです。

外部ワークロードのアイデンティティフェデレーションの詳細については、[ワークロードアイデンティティフェデレーション](https://cloud.google.com/iam/docs/workload-identity-federation)を参照してください。

Google Cloudインテグレーション上のデフォルトのGitLabは、GitLab組織レベルでGitLabからGoogle Cloudへの認証を設定することを前提としています。プロジェクトごとにGoogle Cloudへのアクセス制御を行う場合は、Workload identityプールプロバイダのIAMポリシーを設定する必要があります。GitLab組織からGoogle Cloudにアクセスできるユーザーを制御する方法の詳細については、[IAMによるアクセス制御](https://cloud.google.com/docs/gitlab)を参照してください。

## ワークロードアイデンティティフェデレーションによるGitLab認証 {#gitlab-authentication-with-workload-identity-federation}

Workload identityプールとプロバイダーをGitLabロールと権限をIAMロールにマップするように設定したら、GitLabからGoogle Cloudにワークロードをデプロイするためにランナーをプロビジョニングできます。[`identity`](../ci/yaml/_index.md#identity)キーワードを、Google Cloudでの認可のために`google_cloud`に設定します。

Google Cloudインテグレーション上のGitLabを使用したランナーのプロビジョニングの詳細については、チュートリアル[Google Cloudでのランナーのプロビジョニングする](../ci/runners/provision_runners_google_cloud.md)を参照してください。

## ワークロードアイデンティティフェデレーションを作成し、設定する {#create-and-configure-a-workload-identity-federation}

ワークロードアイデンティティフェデレーションを設定するには、次のいずれかの方法があります:

- ガイド付き設定のためにGitLab UIを使用します。
- Google Cloud CLIを使用して、ワークロードアイデンティティフェデレーションを手動で設定します。

### GitLab UI {#with-the-gitlab-ui}

GitLab UIを使用してワークロードアイデンティティフェデレーションを設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. Google Cloud IAMインテグレーションを見つけて、**設定する**を選択します。
1. **Guided setup**（ガイド付き設定）を選択し、指示に従います。

{{< alert type="note" >}}

既知の問題により、ガイド付き設定でスクリプトを実行した後、Google Cloud IAMインテグレーションのページのフィールドが入力されない場合があります。フィールドが空の場合は、ページを更新してください。詳細については、[issue 448831](https://gitlab.com/gitlab-org/gitlab/-/issues/448831)を参照してください。

{{< /alert >}}

### Google Cloud CLIを使用する {#with-the-google-cloud-cli}

前提要件: 

- Google Cloud CLIは、Google Cloudで[インストールおよび認証されている](https://cloud.google.com/sdk/docs/install)必要があります。
- Google Cloudでワークロードアイデンティティフェデレーションを管理するには、[権限](https://cloud.google.com/iam/docs/manage-workload-identity-pools-providers#required-roles)が必要です。

1. 次のコマンドでWorkload identityプールを作成します。これらの値を置き換えます:

   - `<your_google_cloud_project_id>`を[Google CloudプロジェクトID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)に置き換えます。セキュリティを向上させるには、リソースおよびCI/CDプロジェクトとは別に、アイデンティティ管理専用のプロジェクトを使用します。
   - `<your_identity_pool_id>`をプールに使用するIDに置き換えます。これは、4〜32文字の小文字、数字、またはハイフンである必要があります。競合を避けるために、一意のIDを使用してください。IAMポリシーの管理を容易にするため、GitLabプロジェクトIDまたはプロジェクトパスを含める必要があります。たとえば`gitlab-my-project-name`などです。

   ```shell
   gcloud iam workload-identity-pools create <your_identity_pool_id> \
            --project="<your_google_cloud_project_id>" \
            --location="global" \
            --display-name="Workload identity pool for GitLab project ID"
   ```

1. 次のコマンドを使用して、OIDCプロバイダーをWorkload identityプールに追加します。これらの値を置き換えます:

   - `<your_identity_provider_id>`をプロバイダーに使用するIDに置き換えます。これは、4〜32文字の小文字、数字、またはハイフンである必要があります。競合を避けるために、アイデンティティプールで一意のIDを使用してください。たとえば`gitlab`などです。
   - `<your_google_cloud_project_id>`を[Google CloudプロジェクトID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)に置き換えます。
   - `<your_identity_pool_id>`を前のステップで作成したWorkload identityプールのIDに置き換えます。
   - `<your_issuer_uri>`をIdentity Provider発行者URIに置き換えます。これは、手動設定を選択したときにIAMインテグレーションページからコピーでき、値と完全に一致する必要があります。パラメータには、トップレベルグループのパスを含める必要があります。たとえば、プロジェクトが`my-root-group/my-subgroup/project-a`にある場合、`issuer-uri`は`https://auth.gcp.gitlab.com/oidc/my-root-group`に設定する必要があります。

   ```shell
   gcloud iam workload-identity-pools providers create-oidc "<your_identity_provider_id>" \
         --location="global" \
         --project="<your_google_cloud_project_id>" \
         --workload-identity-pool="<your_identity_pool_id>" \
         --issuer-uri="<your_issuer_uri>" \
         --display-name="GitLab OIDC provider" \
         --attribute-mapping="attribute.guest_access=assertion.guest_access,\
   attribute.reporter_access=assertion.reporter_access,\
   attribute.developer_access=assertion.developer_access,\
   attribute.maintainer_access=assertion.maintainer_access,\
   attribute.owner_access=assertion.owner_access,\
   attribute.namespace_id=assertion.namespace_id,\
   attribute.namespace_path=assertion.namespace_path,\
   attribute.project_id=assertion.project_id,\
   attribute.project_path=assertion.project_path,\
   attribute.user_id=assertion.user_id,\
   attribute.user_login=assertion.user_login,\
   attribute.user_email=assertion.user_email,\
   attribute.user_access_level=assertion.user_access_level,\
   google.subject=assertion.sub"
   ```

- `attribute-mapping`パラメータには、アクセスを許可するためにIdentity and Access Management（IAM）ポリシーで使用される対応するアイデンティティ管理の属性へのJWT IDトークンに含まれるOIDCカスタムクレーム間のマッピングを含める必要があります。詳細については、[サポートされているOIDCカスタムクレーム](google_cloud_iam.md#oidc-custom-claims)を参照してください。これを使用して、[Google Cloudへのアクセスを制御](https://cloud.google.com/docs/gitlab#control-access-google)できます。

特定のGitLabプロジェクトまたはグループへの[アイデンティティ管理トークンアクセス](https://cloud.google.com/iam/docs/workload-identity-federation#mapping)を制限するには、属性条件を使用します。プロジェクトには属性`assertion.project_id`を使用し、グループには属性`assertion.namespace_id`を使用します。詳細については、[属性条件を定義](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#gitlab-saas_2)する方法に関するGoogle Cloudドキュメントを参照してください。属性条件を定義したら、[Workload Identityプールプロバイダを更新できます](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#update_attribute_condition_on_a_workload_identity_provider)。

Workload identityプールとプロバイダーを作成したら、GitLabでセットアップを完了します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. Google Cloud IAMインテグレーションを見つけて、**設定する**を選択します。
1. **Manual setup**（手動設定）を選択します
1. フィールドに入力します。
   - **[プロジェクトID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)**: ワークロードIDプールおよびプロバイダーを作成したGoogle CloudプロジェクトのプロジェクトID。例: `my-sample-project-191923`。
   - 同じGoogle Cloudプロジェクトの**[プロジェクト番号](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)**。例: `314053285323`。
   - このインテグレーション用に作成したWorkload identityプールの**プールID**。
   - このインテグレーション用に作成したWorkload Identityプールプロバイダの**プロバイダーID**。

### OIDCカスタムクレーム {#oidc-custom-claims}

IDトークンには、次のカスタムクレームが含まれます:

| クレーム名              | 使用時                      | 説明                                                                                              |
| ----------------------- | ------------------------- | -------------------------------------------------------------------------------------------------------- |
| `namespace_id`          | プロジェクトイベント         | グループまたはユーザーレベルのネームスペースのID。                                                                 |
| `namespace_path`        | プロジェクトイベント         | グループまたはユーザーレベルのネームスペースのパス。                                                               |
| `project_id`            | プロジェクトイベント         | プロジェクトのID。                                                                                       |
| `project_path`          | プロジェクトイベント         | プロジェクトのパス。                                                                                     |
| `root_namespace_id`     | グループイベント時           | トップレベルグループまたはユーザーレベルのネームスペースのID。                                                            |
| `root_namespace_path`   | グループイベント時           | トップレベルグループまたはユーザーレベルのネームスペースのパス。                                                          |
| `user_id`               | ユーザーによってトリガーされたイベント時    | ユーザーのID。                                                                                          |
| `user_login`            | ユーザーによってトリガーされたイベント時    | ユーザーのユーザー名。                                                                                    |
| `user_email`            | ユーザーによってトリガーされたイベント時    | ユーザーのメールアドレス。                                                                                       |
| `ci_config_ref_uri`     | CI/CDパイプラインの実行中 | トップレベルグループのCIパイプライン定義へのrefsパス。                                                    |
| `ci_config_sha`         | CI/CDパイプラインの実行中 | `ci_config_ref_uri`のGitコミットSHA。                                                              |
| `job_id`                | CI/CDパイプラインの実行中 | CIジョブのID。                                                                                        |
| `pipeline_id`           | CI/CDパイプラインの実行中 | CIパイプラインのID。                                                                                   |
| `pipeline_source`       | CI/CDパイプラインの実行中 | CIパイプラインソース。                                                                                      |
| `project_visibility`    | CI/CDパイプラインの実行中 | CIパイプラインが実行されているプロジェクトの表示レベル。                                             |
| `ref`                   | CI/CDパイプラインの実行中 | CIジョブのGit refs。                                                                                  |
| `ref_path`              | CI/CDパイプラインの実行中 | CIジョブの完全修飾参照。                                                                      |
| `ref_protected`         | CI/CDパイプラインの実行中 | Git refsが保護されているかどうか。                                                                             |
| `ref_type`              | CI/CDパイプラインの実行中 | Git refsタイプ。                                                                                            |
| `runner_environment`    | CI/CDパイプラインの実行中 | CIジョブで使用されるRunnerのタイプ。                                                                   |
| `runner_id`             | CI/CDパイプラインの実行中 | CIジョブを実行しているRunnerのID。                                                                   |
| `sha`                   | CI/CDパイプラインの実行中 | CIジョブのコミットSHA。                                                                           |
| `environment`           | CI/CDパイプラインの実行中 | CIジョブのデプロイ先となる環境。                                                                       |
| `environment_protected` | CI/CDパイプラインの実行中 | デプロイされた環境が保護されている場合は、それ以外の場合は。                                                                    |
| `environment_action`    | CI/CDパイプラインの実行中 | CIジョブで指定された環境アクション。                                                              |
| `deployment_tier`       | CI/CDパイプラインの実行中 | CIジョブが指定する環境のデプロイ層。                                                 |
| `user_access_level`     | ユーザーによってトリガーされたイベント時    | ユーザーのロール（値は`guest`、`reporter`、`developer`、`maintainer`、`owner`）。                 |
| `guest_access`          | ユーザーによってトリガーされたイベント時    | ユーザーが少なくとも`guest`ロールを持っているかどうかを、「true」または「false」の文字列で示します。      |
| `reporter_access`       | ユーザーによってトリガーされたイベント時    | ユーザーが少なくとも`reporter`ロールを持っているかどうかを、「true」または「false」の文字列で示します。   |
| `developer_access`      | ユーザーによってトリガーされたイベント時    | ユーザーが少なくとも`developer`ロールを持っているかどうかを、「true」または「false」の文字列で示します。  |
| `maintainer_access`     | ユーザーによってトリガーされたイベント時    | ユーザーが少なくとも`maintainer`ロールを持っているかどうかを、「true」または「false」の文字列で示します。 |
| `owner_access`          | ユーザーによってトリガーされたイベント時    | ユーザーが少なくとも`owner`ロールを持っているかどうかを、「true」または「false」の文字列で示します。      |

これらのクレームは、[IDトークンクレーム](../ci/secrets/id_token_authentication.md#token-payload)のスーパーセットです。すべての値は文字列型です。詳細と値の例については、IDトークンクレームのドキュメントを参照してください。

## Google Cloudへのアクセスを制御する {#control-access-to-google-cloud}

[ワークロードアイデンティティフェデレーションをセットアップ](#create-and-configure-a-workload-identity-federation)すると、多くの標準的なGitLabクレーム（たとえば、`user_access_level`）がGoogle Cloud属性に自動的にマップされます。

GitLab組織からGoogle Cloudにアクセスできるユーザーをさらにカスタマイズできます。これを行うには、[Common Expression言語（CEL）](https://github.com/google/cel-spec/blob/master/doc/intro.md#introduction)を使用して、Google Cloudインテグレーション上のGitLabの[OIDCカスタム属性](#oidc-custom-claims)に基づいてプリンシパルを設定します。

たとえば、GitLabの`maintainer`ロールを持つユーザーがGitLabプロジェクト`gitlab-org/my-project`からGoogle Artifactレジストリにアーティファクトをプッシュできるようにするには、次のようにします:

1. Google Cloud Consoleにサインインし、[**Workload Identity Federation**（ワークロードアイデンティティフェデレーション）ページ](https://console.cloud.google.com/iam-admin/workload-identity-pools?supportedpurview=project)に移動します。

1. **表示名**列で、ワークロードIDプールを選択します。

1. **Providers**（プロバイダー） セクションで、編集するワークロードIDプロバイダーの横にある**編集** ({{< icon name="pencil" >}}) を選択して、**プロバイダーの詳細**を開きます。

1. **Attribute mapping**セクションで、**Add mapping**を選択します。
1. **Google N**テキストボックスに、次のように入力します:

   ```shell
   attribute.my_project_maintainer
   ```

1. **OIDC N**テキストボックスに、次のCEL式を入力します:

   ```shell
   assertion.maintainer_access=="true" && assertion.project_path=="gitlab-org/my-project"
   ```

1. **保存**を選択します。

   Google属性`my_project_maintainer`は、GitLabクレーム`maintainer_access==true`と`project_path=="gitlab-org/my-project"`にマップされます。

1. Google Cloud Consoleで、[**IAM**ページ](https://console.cloud.google.com/iam-admin/iam?supportedpurview=project)に移動します。

1. **アクセス許可**を選択します。
1. **New principals**（新しいプリンシパル）テキストボックスに、次の形式で`attribute.my_project_maintainer/true`を含むプリンシパルセットを入力します:

   ```shell
   principalSet://iam.googleapis.com/projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/<POOL_ID>/attribute.my_project_maintainer/true
   ```

   次の行を置き換えます:

   - `<PROJECT_NUMBER>`をGoogle Cloudプロジェクト番号に置き換えます。プロジェクト番号を確認するには、[プロジェクトの識別](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)を参照してください。
   - `<POOL_ID>`をワークロードアイデンティティ管理プールIDに置き換えます。

1. **ロールを選択**ドロップダウンリストで、**Google Artifact Registry Writer role**（Google Artifactレジストリライターロール）（`roles/artifactregistry.writer`）を選択します。
1. **保存**を選択します。

ロールは、プロジェクト`gitlab-org/my-project`のGitLabで`maintainer`ロールを持つユーザーを含むプリンシパルセットに付与されます。

他のGitLabプロジェクトがGoogle Artifactレジストリにアーティファクトをプッシュできないようにするには、Google Cloud ConsoleでIAMポリシーを表示し、必要に応じてロールを削除または編集できます。

## IAMポリシーを表示する {#view-your-iam-policies}

Google Cloud Consoleにサインインし、[**IAM**ページ](https://console.cloud.google.com/iam-admin/iam?supportedpurview=project)に移動します

**View by principals**（プリンシパルで表示）または**View by roles**（ロールで表示）を選択できます。
