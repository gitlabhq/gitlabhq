---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duoの利用可能性の制御
---

{{< history >}}

- GitLab 16.10で、導入されたAI機能をオフにする[設定](https://gitlab.com/groups/gitlab-org/-/epics/12404)を導入。
- GitLab 16.11で、[UIに追加されたAI機能をオフにする設定](https://gitlab.com/gitlab-org/gitlab/-/issues/441489)を導入。

{{< /history >}}

一般提供されているGitLab Duo機能は、アクセス権を持つすべてのユーザーに対して自動的にオンになります。

- [GitLab Duo ProまたはEnterpriseアドオンのサブスクリプション](../../subscriptions/subscription-add-ons.md)が必要です。
- [コード提案](../project/repository/code_suggestions/_index.md)のような一般提供されている一部の機能では、アクセス権を付与するユーザーに[シートを割り当てる](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats)必要もあります。

{{< alert type="note" >}}

GitLab Duoセルフホストをオンにするには、[GitLab DuoセルフホストにアクセスするようにGitLabを設定する](../../administration/gitlab_duo_self_hosted/configure_duo_features.md)を参照してください。

{{< /alert >}}

## GitLab Duo機能をオフにする

グループ、プロジェクト、またはインスタンスに対してGitLab Duoをオフにできます。

グループ、プロジェクト、またはインスタンスに対してGitLab Duoをオフにすると、次のようになります。

- コード、イシュー、脆弱性などのリソースにアクセスするGitLab Duo機能が使用できなくなります。
- コード提案が利用できなくなります。
- GitLab Duo Chatが利用できなくなります。

### グループに対してオフにする

{{< tabs >}}

{{< tab title="17.8以降" >}}

GitLab 17.8以降では、次の手順に従って、グループ（サブグループとプロジェクトを含む）のGitLab Duoをオフにします。

前提条件:

- グループのオーナーのロールが必要です。

グループのGitLab Duoをオフにするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、サブグループを見つけます。
1. 設定に進みます。
   - GitLab.comの場合は、**設定 > 一般**を選択し、**GitLab Duoの機能**を展開します。
   - GitLab Self-Managedの場合は、**設定 > GitLab Duo**を選択し、**設定の変更**を選択します。
1. 次のオプションを選択します。
   - グループのGitLab Duoをオフにするものの、他のグループまたはプロジェクトではオンにできるようにするには、**デフォルトでオフ**を選択します。
   - グループのGitLab Duoをオフにし、他のグループまたはプロジェクトがオンにできないようにするには、**常にオフ**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.7" >}}

GitLab 17.7では、次の手順に従って、グループ（サブグループとプロジェクトを含む）のGitLab Duoをオフにします。

{{< alert type="note" >}}

GitLab 17.7では、GitLab Self-Managedのグループまたはサブグループ、あるいはGitLab.comのサブグループに対してGitLab Duoをオフにすることはできません。

{{< /alert >}}

前提条件:

- グループのオーナーのロールが必要です。

グループのGitLab Duoをオフにするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、グループを見つけます。
1. **設定 > GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. 次のオプションを選択します。
   - グループのGitLab Duoをオフにするものの、他のプロジェクトではオンにできるようにするには、**デフォルトでオフ**を選択します。
   - グループのGitLab Duoをオフにし、プロジェクトがオンにできないようにするには、**常にオフ**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.4-17.6" >}}

GitLab 17.4-17.6では、次の手順に従って、グループとそのサブグループおよびプロジェクトのGitLab Duoをオフにします。

前提条件:

- グループのオーナーのロールが必要です。

グループのGitLab Duoをオフにするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、グループを見つけます。
1. **設定 > 一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. 次のオプションを選択します。
   - グループのGitLab Duoをオフにするものの、他のグループまたはプロジェクトではオンにできるようにするには、**デフォルトでオフ**を選択します。
   - グループのGitLab Duoをオフにし、他のグループまたはプロジェクトがオンにできないようにするには、**常にオフ**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

GitLab 17.3以前では、次の手順に従って、グループとそのサブグループおよびプロジェクトのGitLab Duoをオフにします。

前提条件:

- グループのオーナーのロールが必要です。

1. 左側のサイドバーで、**検索または移動**を選択して、グループを見つけます。
1. **設定 > 一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **Use GitLab Duo features**チェックボックスをオフにします。
1. （オプション）**すべてのサブグループに実施する**チェックボックスをオンにして、設定をすべてのサブグループにカスケードします。

   ![カスケード設定](img/disable_duo_features_v17_1.png)

{{< /tab >}}

{{< /tabs >}}

### プロジェクトに対してオフにする

{{< tabs >}}

{{< tab title="17.4以降" >}}

GitLab 17.4以降では、次の手順に従って、プロジェクトのGitLab Duoをオフにします。

前提条件:

- プロジェクトのオーナーのロールが必要です。

プロジェクトのGitLab Duoをオフにするには、以下の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択し、プロジェクトを探します。
1. **設定 > 一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **GitLab Duo**で、トグルをオフにします。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

GitLab 17.3以前では、次の手順に従って、プロジェクトのGitLab Duoをオフにします。

1. GitLab GraphQL API [`projectSettingsUpdate`](../../api/graphql/reference/_index.md#mutationprojectsettingsupdate)変異を使用します。
1. [`duo_features_enabled`](../../api/graphql/getting_started.md#update-project-settings)設定を`false`に設定します（デフォルトは`true`です）。

{{< /tab >}}

{{< /tabs >}}

### インスタンスに対してオフにする

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< tabs >}}

{{< tab title="17.7以降" >}}

GitLab 17.7以降では、次の手順に従って、インスタンスのGitLab Duoをオフにします。

前提条件:

- 管理者である必要があります。

インスタンスのGitLab Duoをオフにするには、以下の手順に従います。

1. 左側のサイドバーの下部にある**管理者エリア**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. 次のオプションを選択します。
   - インスタンスのGitLab Duoをオフにするものの、グループとプロジェクトではオンにできるようにするには、**デフォルトでオフ**を選択します。
   - インスタンスのGitLab Duoをオフにし、グループまたはプロジェクトがオンにできないようにするには、**常にオフ**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.4-17.6" >}}

GitLab 17.4-17.6では、次の手順に従って、インスタンスのGitLab Duoをオフにします。

前提条件:

- 管理者である必要があります。

インスタンスのGitLab Duoをオフにするには、以下の手順に従います。

1. 左側のサイドバーの下部にある**管理者エリア**を選択します。
1. **設定 > 一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. 次のオプションを選択します。
   - インスタンスのGitLab Duoをオフにするものの、グループとプロジェクトではオンにできるようにするには、**デフォルトでオフ**を選択します。
   - インスタンスのGitLab Duoをオフにし、グループまたはプロジェクトがオンにできないようにするには、**常にオフ**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

GitLab 17.3以前では、次の手順に従って、インスタンスのGitLab Duoをオフにします。

前提条件:

- 管理者である必要があります。

インスタンスのGitLab Duoをオフにするには、以下の手順に従います。

1. 左側のサイドバーの下部にある**管理者**を選択します。
1. **設定 > 一般**を選択します。
1. **AI搭載機能**を展開します。
1. **Use Duo features**チェックボックスをオフにします。
1. （オプション）**すべてのサブグループに実施する**チェックボックスをオンにして、インスタンス内のすべてのグループに設定をカスケードします。

{{< /tab >}}

{{< /tabs >}}

{{< alert type="note" >}}

管理者による特定のグループまたはプロジェクトの設定の[オーバーライドを許可するイシューが存在します](https://gitlab.com/gitlab-org/gitlab/-/issues/441532)。

{{< /alert >}}

## ベータ版および実験的機能をオンにする

実験的およびベータ版のGitLab Duo機能は、デフォルトでオフになっています。これらの機能には、[テスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)が適用されます。

### GitLab.comの場合

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< tabs >}}

{{< tab title="17.4以降" >}}

GitLab 17.4以降では、次の手順に従って、GitLab.comでグループのGitLab Duoの実験的およびベータ版機能をオンにします。

前提条件:

- トップレベルグループのオーナーロールが必要です。

トップレベルグループのGitLab Duoの実験的およびベータ版機能をオンにするには、以下の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択して、グループを見つけます。
1. **設定 > 一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **GitLab Duoプレビュー機能**で、**GitLab Duoの実験的およびベータ版機能を使用**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

GitLab 17.3以前では、次の手順に従って、GitLab.comでグループのGitLab Duoの実験的およびベータ版機能をオンにします。

1. 左側のサイドバーで、**検索または移動**を選択して、グループを見つけます。
1. **設定 > 一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **GitLab Duo experiment and beta features**で、**Use experiment and beta GitLab Duo features**チェックボックスをオンにします。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< /tabs >}}

この設定は、グループに属する[すべてのプロジェクトにカスケードされます](../project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)。

### Self-Managedの場合

{{< tabs >}}

{{< tab title="17.4以降" >}}

GitLab 17.4以降では、次の手順に従って、GitLab Self-ManagedインスタンスのGitLab Duoの実験的およびベータ版機能をオンにします。

前提条件:

- 管理者である必要があります。

インスタンスのGitLab Duoの実験的およびベータ版機能をオンにするには、次の手順に従います。

1. 左側のサイドバーの下部にある**管理者エリア**を選択します。
1. **設定 > 一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **GitLab Duoプレビュー機能**で、**GitLab Duoの実験的およびベータ版機能を使用**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

GitLab Duo Chatがまだ一般提供されていないGitLabバージョンでGitLab Duoのベータ版および実験的機能を有効にするには、[GitLab Duo Chatのドキュメント](../gitlab_duo_chat/turn_on_off.md#for-self-managed)を参照してください。

{{< /tab >}}

{{< /tabs >}}
