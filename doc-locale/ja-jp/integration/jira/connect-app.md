---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab for Jira Cloudアプリ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="note" >}}

このページには、GitLab for Jira Cloudアプリのユーザー向けドキュメントが含まれています。管理者向けドキュメントについては、[GitLab for Jira Cloudアプリの管理](../../administration/settings/jira_cloud_app.md)を参照してください。

{{< /alert >}}

[GitLab for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud)アプリを使用すると、GitLabとJira Cloudを接続して、開発情報をリアルタイムで同期できます。この情報は、[Jira開発パネル](development_panel.md)で表示できます。

GitLab for Jira Cloudアプリを使用して、トップレベルグループまたはサブグループをリンクできます。プロジェクトやパーソナルネームスペースを直接リンクすることはできません。

GitLab.comでGitLab for Jira Cloudアプリを設定するには、[GitLab for Jira Cloudアプリをインストール](#install-the-gitlab-for-jira-cloud-app)します。

アプリを設定した後、Atlassianが開発および管理している[プロジェクトツールチェーン](https://support.atlassian.com/jira-software-cloud/docs/what-is-the-connections-feature/)を使用して、[GitLabリポジトリをJiraプロジェクトにリンク](https://support.atlassian.com/jira-software-cloud/docs/link-repositories-to-a-project/#Link-repositories-using-the-toolchain-feature)できます。プロジェクトツールチェーンは、GitLabとJira Cloud間で開発情報を同期する方法には影響しません。

Jira Data CenterまたはJira Serverには、Atlassianが開発および管理している[Jira DVCSコネクタ](dvcs/_index.md)を使用してください。

## Jiraに同期されたGitLabデータ

グループをリンクした後、[JiraのイシューIDをメンション](development_panel.md#information-displayed-in-the-development-panel)すると、そのグループ内のすべてのプロジェクトでは、次のGitLabデータがJiraに同期されます。

- 既存のプロジェクトデータ（グループをリンクする前）:
  - 最後の400件のマージリクエスト
  - 最後の400個のブランチと、それらの各ブランチへの最後のコミット（GitLab 15.11以降）
- 新しいプロジェクトデータ（グループをリンクした後）:
  - マージリクエスト
    - マージリクエスト作成者
  - ブランチ
  - コミット
    - コミット作成者
  - パイプライン
  - デプロイ
  - 機能フラグ

## GitLab for Jira Cloudアプリをインストールする

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com

{{< /details >}}

前提要件:

- ネットワークは、GitLabとJira間の受信接続と送信接続を許可する必要があります。
- 特定の[Jiraユーザー要件](../../administration/settings/jira_cloud_app.md#jira-user-requirements)を満たしている必要があります。

GitLab for Jira Cloudアプリをインストールするには、次の手順に従います。

1. Jiraの上部のバーで、**アプリ ＞ その他のアプリを探す**を選択し、`GitLab for Jira Cloud`を検索します。
1. **GitLab for Jira Cloud**を選択してから、**今すぐ取得**を選択します。

または、[Atlassian Marketplaceからアプリを直接入手](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud)してください。

これで、[GitLab for Jira Cloudアプリを設定](#configure-the-gitlab-for-jira-cloud-app)できます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> 概要については、[Installing the GitLab for Jira Cloud app from the Atlassian Marketplace for GitLab.com（Atlassian MarketplaceからGitLab.com向けのGitLab for Jira Cloudアプリをインストールする（英語））](https://youtu.be/52rB586_rs8?list=PL05JrBw4t0Koazgli_PmMQCER2pVH7vUT)を参照してください。
<!-- Video published on 2024-10-30 -->

## GitLab for Jira Cloudアプリを設定する

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 16.1で、**ネームスペースを追加**が**グループをリンク**に[名称変更](https://gitlab.com/gitlab-org/gitlab/-/issues/331432)されました。

{{< /history >}}

前提要件:

- 少なくともGitLabグループのメンテナーロールを持っている必要があります。
- 特定の[Jiraユーザー要件](../../administration/settings/jira_cloud_app.md#jira-user-requirements)を満たしている必要があります。

GitLab for Jira Cloudアプリを1つ以上のGitLabグループにリンクすることで、GitLabからJiraにデータを同期できます。GitLab for Jira Cloudアプリを設定するには、次の手順に従います。

<!-- markdownlint-disable MD044 -->

1. Jiraの上部のバーで、**アプリ ＞ アプリの管理**を選択します。
1. **GitLab for Jira**を展開します。アプリのインストール方法に応じて、アプリの名前は次のようになります。
   - **GitLab for Jira（gitlab.com）**: [Atlassian Marketplaceからアプリをインストールした場合](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?tab=overview&hosting=cloud)。
   - **GitLab for Jira （`<gitlab.example.com>`）**: [アプリを手動でインストールした場合](../../administration/settings/jira_cloud_app.md#install-the-gitlab-for-jira-cloud-app-manually)。
1. **始める**を選択します。
1. 任意。GitLab Self-ManagedをJiraにリンクするには、**GitLabのバージョンを変更**を選択します。
   1. すべてのチェックボックスをオンにし、**次へ**を選択します。
   1. **GitLabインスタンスURL**を入力し、**保存**を選択します。
1. **GitLabにサインイン**を選択します。

   {{< alert type="note" >}}

   [グループのパスワード認証が無効になっている](../../user/group/saml_sso/_index.md#disable-password-authentication-for-enterprise-users)[Enterpriseユーザー](../../user/enterprise_user/_index.md)は、まずグループのシングルサインオンURLでGitLabにサインインする必要があります。

   {{< /alert >}}

1. **認証**を選択します。これで、グループのリストが表示されるようになります。
1. **グループをリンク**を選択します。
1. グループにリンクするには、**リンク**を選択します。

<!-- markdownlint-enable MD044 -->

GitLabグループにリンクした後:

- そのグループ内のすべてのプロジェクトについて、データがJiraに同期されます。最初のデータ同期は、1分あたり20個のプロジェクトのバッチで実行されます。多数のプロジェクトを含むグループの場合、一部のプロジェクトのデータ同期は遅延します。
- GitLab for Jira Cloudアプリのインテグレーションは、グループとそのグループ内のすべてのサブグループまたはプロジェクトに対して自動的に有効になります。このインテグレーションにより、[Jira Service Managementを設定](#configure-jira-service-management)できるようになります。

## Jira Service Managementを設定する

{{< history >}}

- GitLab 17.2で`enable_jira_connect_configuration`という名前の[フラグ](../../administration/feature_flags.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/460663)されました。デフォルトで無効になっています。
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/467117)になりました。機能フラグ`enable_jira_connect_configuration`が削除されました。

{{< /history >}}

{{< alert type="note" >}}

この機能はコミュニティのコントリビュートとして追加されたものであり、GitLabコミュニティのみによって開発および管理されています。

{{< /alert >}}

前提要件:

- GitLab for Jira Cloudアプリが[インストール](#install-the-gitlab-for-jira-cloud-app)されている必要があります。
- GitLab for Jira Cloudアプリの設定で[リンクされるGitLabグループ](#configure-the-gitlab-for-jira-cloud-app)。

GitLabをITサービスプロジェクトに接続して、デプロイを追跡できます。

設定は、GitLabのGitLab for Jira Cloudアプリインテグレーションで行われます。インテグレーションは、[GitLabグループがリンク](#configure-the-gitlab-for-jira-cloud-app)された後、GitLabのグループ、そのサブグループ、およびプロジェクトに対して有効になります。

GitLab for Jira Cloudアプリインテグレーションの有効化と無効化は、グループのリンクを通じて完全に自動的に行われ、GitLabインテグレーションフォームまたはAPIを介して行われることはありません。

Jira Service Managementで、次の手順を実行します。

1. サービスプロジェクトで、**プロジェクトの設定 ＞ 変更の管理**に移動します。
1. **パイプラインの接続 ＞ GitLab**を選択し、設定フローの最後にある**サービスID**をコピーします。

GitLabで、次の手順を実行します。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **設定 > インテグレーション**を選択します。
1. **GitLab for Jira Cloudアプリ**を選択します。インテグレーションが無効になっている場合は、最初に[GitLabグループをリンク](#configure-the-gitlab-for-jira-cloud-app)して、グループ、そのサブグループ、およびプロジェクトに対して、GitLab for Jira Cloudアプリインテグレーションを有効にします。
1. **サービスID**フィールドに、このプロジェクトにマップするサービスIDを入力します。複数のサービスIDを使用するには、各サービスIDの間にカンマを追加します。

最大100個のサービスをマップできます。

Jiraでのデプロイ追跡の詳細については、[Set up deployment tracking（デプロイ追跡の設定）](https://support.atlassian.com/jira-service-management-cloud/docs/set-up-deployment-tracking/)を参照してください。

### GitLabでデプロイゲートを設定する

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/473774)されました。

{{< /history >}}

{{< alert type="note" >}}

この機能はコミュニティのコントリビュートとして追加されたものであり、GitLabコミュニティのみによって開発および管理されています。

{{< /alert >}}

デプロイゲートを設定して、変更リクエストの承認のために、そのリクエストをGitLabからJira Service Managementに送信することができます。デプロイゲートを使用すると、選択した環境へのGitLabのデプロイはすべてJira Service Managementに自動的に送信され、承認された場合にのみデプロイされます。

#### サービスアカウントトークンを作成する

GitLabでサービスアカウントトークンを作成するには、まずパーソナルアクセストークンを作成する必要があります。このトークンは、Jira Service ManagementでGitLabのデプロイを管理するために使用されるサービスアカウントトークンを認証します。

サービスアカウントトークンを作成するには、次の手順に従います。

1. [サービスアカウントユーザーを作成](../../api/user_service_accounts.md#create-a-service-account-user)します。
1. パーソナルアクセストークンを使用して、[サービスアカウントをグループまたはプロジェクトに追加](../../api/members.md#add-a-member-to-a-group-or-project)します。
1. [サービスアカウントを保護環境に追加](../../ci/environments/protected_environments.md#protecting-environments)します。
1. パーソナルアクセストークンを使用して、[サービスアカウントトークンを生成](../../api/group_service_accounts.md#create-a-personal-access-token-for-a-service-account-user)します。
1. サービスアカウントトークンの値をコピーします。

#### デプロイゲートを有効にする

デプロイゲートを有効にするには:

- GitLabで、次の手順を実行します。

  1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
  1. **設定 > インテグレーション**を選択します。
  1. **GitLab for Jira Cloudアプリ**を選択します。
  1. **デプロイゲート**で、**デプロイゲートを有効にする**チェックボックスをオンにします。
  1. **環境ティア**テキストボックスに、デプロイゲートを有効にする環境の名前を入力します。カンマで区切られた複数の環境名を入力できます（例: `production, staging, testing, development`）。小文字のみを使用してください。
  1. **変更の保存**を選択します。

- Jira Service Managementで、次の手順を実行します。

  1. [デプロイゲートを設定](https://support.atlassian.com/jira-service-management-cloud/docs/set-up-deployment-gating/)します。
  1. **サービスアカウントトークン**テキストボックスに、[GitLabからコピーしたサービスアカウントトークンの値を貼り付け](#create-the-service-account-token)ます。

#### サービスアカウントを保護環境に追加する

GitLabの保護環境にサービスアカウントを追加するには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、プロジェクトを見つけます。
1. **設定 ＞ CI/CD**を選択します。
1. **保護環境**を展開し、**環境を保護**を選択します。
1. **環境を選択**ドロップダウンリストから、保護する環境を選択します（例: **ステージ**）。
1. **デプロイ許可**ドロップダウンリストから、この環境にデプロイできるユーザーを選択します（例: **デベロッパー + メンテナー**）。
1. **承認者**ドロップダウンリストから、[作成したサービスアカウント](#create-the-service-account-token)を選択します。
1. **保護**を選択します。

#### APIリクエストの例

- サービスアカウントユーザーを作成します。

  ```shell
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "name=<name_of_your_choice>&username=<username_of_your_choice>"  "<https://gitlab.com/api/v4/groups/<group_id>/service_accounts"
  ```

- パーソナルアクセストークンを使用して、サービスアカウントをグループまたはプロジェクトに追加します。

  ```shell
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
       --data "user_id=<service_account_id>&access_level=30" "https://gitlab.com/api/v4/groups/<group_id>/members"
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
       --data "user_id=<service_account_id>&access_level=30" "https://gitlab.com/api/v4/projects/<project_id>/members"
  ```

- パーソナルアクセストークンを使用して、サービスアカウントトークンを生成します。

  ```shell
  curl --request POST --header "PRIVATE-TOKEN: <your_access_token>"
  "https://gitlab.com/api/v4/groups/<group_id>/service_accounts/<service_account_id>/personal_access_tokens" --data "scopes[]=api,read_user,read_repository" --data "name=service_accounts_token"
  ```

## GitLab for Jira Cloudアプリを更新する

アプリのほとんどの更新は自動的に行われます。詳細については、[Atlassianのドキュメント](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/)を参照してください。

アプリに追加の権限が必要な場合は、[Jiraで更新を手動で承認](https://developer.atlassian.com/platform/marketplace/upgrading-and-versioning-cloud-apps/#changes-that-require-manual-customer-approval)する必要があります。

## セキュリティに関する考慮事項

GitLab for Jira Cloudアプリは、GitLabとJiraを接続します。データは2つのアプリケーション間で共有する必要があり、両方向でアクセス権を付与する必要があります。

### JiraへのGitLabアクセス

[GitLab for Jira Cloudアプリを設定](#configure-the-gitlab-for-jira-cloud-app)すると、GitLabはJiraから**共有シークレットトークン**を受け取ります。このトークンは、Jiraプロジェクトに対して、GitLab `READ`、`WRITE`、および`DELETE`[アプリスコープ](https://developer.atlassian.com/cloud/jira/software/scopes-for-connect-apps/#scopes-for-atlassian-connect-apps)を付与します。これらのスコープは、Jiraプロジェクトの開発パネルで情報を更新するために必要です。このトークンは、アプリがインストールされているJiraプロジェクトを除いて、他のAtlassian製品へのGitLabアクセスを許可しません。

トークンは`AES256-GCM`で暗号化され、GitLabに保存されます。JiraプロジェクトからGitLab for Jira Cloudアプリがアンインストールされると、GitLabはトークンを削除します。

### GitLabへのJiraアクセス

Jiraは、GitLabへのアクセス権を取得しません。

### GitLabからJiraに送信されるデータ

Jiraに送信されるすべてのデータについては、[Jiraに同期されたGitLabデータ](#gitlab-data-synced-to-jira)を参照してください。

Jiraに送信される特定のデータプロパティの詳細については、データ同期に関係する[シリアライザークラス](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/atlassian/jira_connect/serializers)を参照してください。

### JiraからGitLabに送信されるデータ

GitLab for Jira Cloudアプリがインストールまたはアンインストールされると、GitLabはJiraから[ライフサイクルイベント](https://developer.atlassian.com/cloud/jira/platform/connect-app-descriptor/#lifecycle)を受信します。イベントには、後続のライフサイクルイベントを検証したり、[Jiraにデータを送信する](#data-sent-from-gitlab-to-jira)ときに認証したりするための[トークン](#gitlab-access-to-jira)が含まれます。Jiraからのライフサイクルイベントリクエストは[検証](https://developer.atlassian.com/cloud/jira/platform/security-for-connect-apps/#validating-installation-lifecycle-requests)されます。

Atlassian MarketplaceのGitLab for Jira Cloudアプリを使用するGitLab Self-Managedインスタンスの場合、GitLab.comはライフサイクルイベントを処理して、GitLab Self-Managedインスタンスに転送します。詳細については、[アプリのライフサイクルイベントのGitLab.com処理](../../administration/settings/jira_cloud_app.md#gitlabcom-handling-of-app-lifecycle-events)を参照してください。

### Jiraによって保存されるデータ

[Jiraに送信されたデータ](#data-sent-from-gitlab-to-jira)は、Jiraによって保存され、[Jira開発パネル](development_panel.md)に表示されます。

GitLab for Jira Cloudアプリがアンインストールされると、Jiraはこのデータを完全に削除します。このプロセスは非同期で行われ、数時間かかる場合があります。

### Atlassian Marketplaceのプライバシーとセキュリティの詳細

詳細については、[privacy and security details of the Atlassian Marketplace listing（Atlassian Marketplaceリストのプライバシーとセキュリティの詳細）](https://marketplace.atlassian.com/apps/1221011/gitlab-for-jira-cloud?tab=privacy-and-security&hosting=cloud)を参照してください。

## トラブルシューティング

GitLab for Jira Cloudアプリを操作する際に、以下の問題が発生する可能性があります。

管理者向けドキュメントについては、[GitLab for Jira Cloudアプリの管理](../../administration/settings/jira_cloud_app_troubleshooting.md)を参照してください。

### エラー: `Failed to link group`

GitLab for Jira Cloudアプリを接続する際に、次のエラーが発生する場合があります。

```plaintext
Failed to link group. Please try again.
```

権限が不十分なため、Jiraからユーザー情報をフェッチきない場合、`403 Forbidden`が返されます。

この問題を解決するには、特定の[Jiraユーザー要件](../../administration/settings/jira_cloud_app.md#jira-user-requirements)を満たしていることを確認してください。
