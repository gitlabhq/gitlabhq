---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabをBeyond Identityとインテグレーションして、ユーザーアカウントに追加されたGPGキーを検証します。
title: Beyond Identity
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/431433)されました。

{{< /history >}}

GitLabでは、ユーザーは[GPGキーをプロファイルに追加](../repository/signed_commits/gpg.md)した後、コミットに署名できます。[Beyond Identity](https://www.beyondidentity.com/)とのGitLabインテグレーションにより、この機能が拡張されます。

設定すると、このインテグレーションはBeyond Identityを使用して、ユーザーがプロファイルに追加する新しいGPGキーを検証します。検証に合格しないキーは拒否され、ユーザーは新しいキーをアップロードする必要があります。

ユーザーが署名されたコミットをGitLabインスタンスにプッシュすると、GitLabは受信前チェックを実行して、ユーザーのプロファイルに保存されているGPGキーに対してそれらのコミットを検証します。これにより、検証されたキーで署名されたコミットのみが受け入れられるようになります。

## インスタンスのBeyond Identityインテグレーションを設定する {#set-up-the-beyond-identity-integration-for-your-instance}

前提要件: 

- GitLabインスタンスへの管理者アクセス権が必要です。
- GitLabプロファイルで使用されているメールアドレスは、Beyond Identity Authenticatorのキーに割り当てられたメールと同じである必要があります。
- Beyond Identity APIトークンが必要です。Sales Engineerにリクエストできます。

インスタンスのBeyond Identityインテグレーションを有効にするには、次の手順を実行します:

1. 管理者としてGitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **インテグレーション**を選択します。
1. **Beyond Identity**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. **APIトークン**に、Beyond Identityから受け取ったAPIトークンを貼り付けます。
1. **変更を保存**を選択します。

インスタンスのBeyond Identityインテグレーションが有効になりました。

## GPGキーの検証 {#gpg-key-verification}

ユーザーがプロファイルにGPGキーを追加すると、キーが検証されます:

- キーがBeyond Identity Authenticatorによって発行されなかった場合、受け入れられます。
- キーがBeyond Identity Authenticatorによって発行されたが、キーが無効な場合、拒否されます。たとえば、ユーザーのGitLabプロファイルで使用されているメールが、Beyond Identity Authenticatorのキーに割り当てられたメールと異なる場合などです。

ユーザーがコミットをプッシュすると、GitLabは、そのコミットがユーザープロファイルにアップロードされたGPG署名によって署名されていることを確認します。署名を検証できない場合、プッシュは拒否されます。Webコミットは署名なしで受け入れられます。

## サービスアカウントのプッシュチェックをスキップする {#skip-push-check-for-service-accounts}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/454369)されました。

{{< /history >}}

前提要件: 

- GitLabインスタンスへの管理者アクセス権が必要です。

[サービスアカウント](../../profile/service_accounts.md)のプッシュチェックをスキップするには:

1. 管理者としてGitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **インテグレーション**を選択します。
1. **Beyond Identity**を選択します。
1. **Exclude service accounts**（サービスアカウントを除外） チェックボックスを選択します。
1. **変更を保存**を選択します。

## Beyond Identityチェックからグループまたはプロジェクトを除外する {#exclude-groups-or-projects-from-the-beyond-identity-check}

{{< history >}}

- GitLab 17.0で`beyond_identity_exclusions`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/454372)されました。デフォルトでは有効になっています。
- グループを除外するオプションは、GitLab 17.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/454372)。
- GitLab 17.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/457893)。機能フラグ`beyond_identity_exclusions`は削除されました。

{{< /history >}}

前提要件: 

- GitLabインスタンスへの管理者アクセス権が必要です。

Beyond Identityチェックからグループまたはプロジェクトを除外するには:

1. 管理者としてGitLabにサインインします。
1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **インテグレーション**を選択します。
1. **Beyond Identity**を選択します。
1. **除外リスト**タブを選択します。
1. **除外を追加**を選択します。
1. ドロワーで、除外するグループまたはプロジェクトを検索して選択します。
1. **除外を追加**を選択します。
