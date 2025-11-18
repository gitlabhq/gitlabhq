---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duoの可用性 - 以前のバージョン
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo ProまたはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- AI機能をオン/オフにする[設定の導入](https://gitlab.com/groups/gitlab-org/-/epics/12404)（GitLab 16.10）。
- [AI機能をオン/オフにする設定をUIに追加](https://gitlab.com/gitlab-org/gitlab/-/issues/441489)（GitLab 16.11）。

{{< /history >}}

GitLab Duo ProまたはEnterpriseの場合、GitLab Duoのオン/オフをグループ、プロジェクト、またはインスタンスに対して切り替えることができます。

{{< alert type="note" >}}

この情報は、GitLab 18.1と以前のバージョンに適用されます。GitLab 18.2以降では、[最新のドキュメント](turn_on_off.md)をご覧ください。

{{< /alert >}}

グループ、プロジェクト、またはインスタンスに対してGitLab Duoをオフにすると、次のようになります。:

- コード、イシュー、脆弱性などのリソースにアクセスするGitLab Duo機能は使用できなくなります。
- コード提案は利用できなくなります。
- GitLab Duo Chatは利用できなくなります。

## グループまたはサブグループの場合 {#for-a-group-or-subgroup}

{{< tabs >}}

{{< tab title="17.8～18.1" >}}

GitLab 17.8以降では、次の手順に従って、グループ（サブグループとプロジェクトを含む）のGitLab Duoをオンまたはオフにします。

前提要件:

- グループのオーナーロールが必要です。

グループまたはサブグループに対してGitLab Duoをオンまたはオフにするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループまたはサブグループを見つけます。
1. デプロイの種類とグループのレベルに基づいて、設定に移動します。:
   - GitLab.comトップレベルグループの場合: **設定** > **GitLab Duo**を選択し、**設定の変更**を選択します。
   - GitLab.comサブグループの場合: **設定** > **一般**を選択し、**GitLab Duoの機能**を展開します。
   - GitLab Self-Managed（すべてのグループとサブグループ）の場合: **設定** > **一般**を選択し、**GitLab Duoの機能**を展開します。
1. オプションを選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.7" >}}

GitLab 17.7では、次の手順に従って、グループ（サブグループとプロジェクトを含む）のGitLab Duoをオンまたはオフにします。

{{< alert type="note" >}}

GitLab 17.7の場合:

- GitLab.comでは、GitLab Duo設定ページはトップレベルグループでのみ利用可能で、サブグループでは利用できません。

- GitLab Self-Managedの場合、GitLab Duo設定ページはグループまたはサブグループでは利用できません。

{{< /alert >}}

前提要件: 

- グループのオーナーロールが必要です。

トップレベルグループに対してGitLab Duoをオンまたはオフにするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. オプションを選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.4-17.6" >}}

GitLab 17.4-17.6で、次の手順に従って、グループとそのサブグループおよびプロジェクトに対してGitLab Duoをオンまたはオフにします。

{{< alert type="note" >}}

GitLab 17.4-17.6の場合:

- GitLab.comでは、GitLab Duo設定ページはトップレベルグループでのみ利用可能で、サブグループでは利用できません。

- GitLab Self-Managedの場合、GitLab Duo設定ページはグループまたはサブグループでは利用できません。

{{< /alert >}}

前提要件: 

- グループのオーナーロールが必要です。

トップレベルグループに対してGitLab Duoをオンまたはオフにするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. オプションを選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

GitLab 17.3以前では、次の手順に従って、グループとそのサブグループおよびプロジェクトに対してGitLab Duoをオンまたはオフにします。

前提要件:

- グループのオーナーロールが必要です。

グループまたはサブグループに対してGitLab Duoをオンまたはオフにするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループまたはサブグループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **Use GitLab Duo features**（GitLab Duo機能の使用）チェックボックスをオンまたはオフにします。
1. オプション。**すべてのサブグループに実施する**チェックボックスをオンにして、設定をすべてのサブグループにカスケードします。

   ![カスケード設定](img/disable_duo_features_v17_1.png)

{{< /tab >}}

{{< /tabs >}}

## プロジェクトの場合 {#for-a-project}

{{< tabs >}}

{{< tab title="17.4～18.1" >}}

GitLab 17.4以降では、次の手順に従って、プロジェクトに対してGitLab Duoをオンまたはオフにします。

前提要件:

- プロジェクトのオーナーロールが必要です。

プロジェクトに対してGitLab Duoをオンまたはオフにするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **GitLab Duo**で、切替をオンまたはオフにします。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

GitLab 17.3以前では、次の手順に従って、プロジェクトに対してGitLab Duoをオンまたはオフにします。

1. [GitLab GraphQL API `projectSettingsUpdate`](../../api/graphql/reference/_index.md#mutationprojectsettingsupdate)ミューテーションを使用します。
1. [`duo_features_enabled`](../../api/graphql/getting_started.md#update-project-settings)設定を`true`または`false`に設定します。

{{< /tab >}}

{{< /tabs >}}

## インスタンスの場合 {#for-an-instance}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< tabs >}}

{{< tab title="17.7～18.1" >}}

GitLab 17.7以降では、次の手順に従って、インスタンスに対してGitLab Duoをオンまたはオフにします。

前提要件:

- 管理者である必要があります。

インスタンスに対してGitLab Duoをオンまたはオフにするには:

1. 左側のサイドバーの下部で、**管理者エリア**を選択します。
1. **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. オプションを選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.4-17.6" >}}

GitLab 17.4-17.6では、次の手順に従って、インスタンスに対してGitLab Duoをオンまたはオフにします。

前提要件:

- 管理者である必要があります。

インスタンスに対してGitLab Duoをオンまたはオフにするには:

1. 左側のサイドバーの下部で、**管理者エリア**を選択します。
1. **設定** > **一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. オプションを選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

GitLab 17.3以前では、次の手順に従って、インスタンスに対してGitLab Duoをオンまたはオフにします。

前提要件:

- 管理者である必要があります。

インスタンスに対してGitLab Duoをオンまたはオフにするには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **AI-powered features**（AI搭載機能）を展開します。
1. **Use Duo features**（Duo機能の使用）チェックボックスをオンまたはオフにします。
1. オプション。**すべてのサブグループに実施する**チェックボックスをオンにして、インスタンス内のすべてのグループに設定をカスケードします。

{{< /tab >}}

{{< /tabs >}}
