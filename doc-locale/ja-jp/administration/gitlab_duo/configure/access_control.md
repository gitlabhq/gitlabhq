---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo Agent Platformへのアクセスを設定します。
title: GitLab Duo Agent Platformへのアクセスを設定
---

{{< details >}}

- プラン: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/583909)されました。

{{< /history >}}

GitLab Duoをグループで[オンまたはオフに](../../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-on-or-off)したり、GitLab DuoとエージェントPlatformへのアクセスを特定のグループにのみ制限したりできます。

## エージェントプラットフォーム機能へのアクセスを付与する {#give-access-to-agent-platform-features}

{{< history >}}

- デフォルトの**グループなし**ルールは[GitLab 18.10で導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225728)。
- **Member access**セクションと**No group**ルールは、GitLab 18.11で[名称変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229785)されました。

{{< /history >}}

{{< tabs >}}

{{< tab title="On GitLab.com" >}}

前提条件: 

- トップレベルグループのオーナーロール。

トップレベルグループの特定のエージェントプラットフォーム機能へのアクセスを付与するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **Limit access based on group membership**の下で、**グループの追加**を選択します。
1. ドロップダウンリストから、既存のサブグループを選択します。

   最初のグループを追加すると、デフォルトの**All eligible users**ルールも追加されます。このルールを使用して、他のすべてのユーザーのアクセスを設定できます。このルールは、GitLab Duoまたはエージェントプラットフォームへのアクセスがなく、既存のすべてのグループが削除されると自動的に削除されます。

1. 直接のグループメンバーがアクセスできる機能を選択します。
1. **変更を保存**を選択します。

これらの設定は、次のユーザーに適用されます:

- **Limit access based on group membership**の下で設定されたグループのいずれかの直接メンバーであり、このトップレベルグループ内のプロジェクトまたはグループでAIアクションを実行しているユーザー。
- トップレベルグループを[デフォルトのGitLab Duoネームスペース](../../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace)として持ち、AIアクションが行われるトップレベルグループのメンバーではないユーザー。

グループベースのアクセス制御を設定する場合、トップレベルグループの直接のサブグループであるグループのみを選択できます。アクセス制御ルールでは、ネストされたサブグループを使用できません。

> [!note]
> グループが設定されている場合、GitLab DuoおよびエージェントPlatform機能にアクセスするには、ユーザーはいずれかのグループの直接メンバーである必要があります。または、**All eligible users**設定を使用できます。アクセスは、他のアクセス方法によっても決定されます。{{< /tab >}}

{{< tab title="GitLab Self-Managedの場合" >}}

前提条件: 

- 管理者アクセス権が必要です。

インスタンスの特定のエージェントプラットフォーム機能へのアクセスを付与するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **Limit access based on group membership**の下で、**グループの追加**を選択します。
1. ドロップダウンリストから既存のグループを選択します。

   最初のグループを追加すると、デフォルトの**All eligible users**ルールも追加されます。このルールを使用して、他のすべてのユーザーのアクセスを設定できます。このルールは、GitLab Duoまたはエージェントプラットフォームへのアクセスがなく、既存のすべてのグループが削除されると自動的に削除されます。

1. 直接のグループメンバーがアクセスできる機能を選択します。
1. **変更を保存**を選択します。

これらの設定は、**Limit access based on group membership**の下で設定されたグループのいずれかの直接メンバーであるユーザーに適用されます。ユーザーは、これらの機能がオンになっているときに、それらにアクセスできるようになります。

グループベースのアクセス制御を設定する場合、トップレベルグループのみを選択できます。サブグループはアクセス制御ルールで使用できません。

> [!note]
> グループが設定されている場合、GitLab DuoおよびエージェントPlatform機能にアクセスするには、ユーザーはいずれかのグループの直接メンバーである必要があります。または、**All eligible users**設定を使用できます。アクセスは、他のアクセス方法によっても決定されます。{{< /tab >}}

{{< /tabs >}}

グループメンバーシップを手動で管理しない場合は、[LDAPまたはSAMLを使用してメンバーシップを同期](#synchronize-group-membership)できます。

### グループメンバーシップ {#group-membership}

ユーザーが複数のグループに割り当てられている場合、割り当てられたすべてのグループの機能にアクセスします。例: 

- グループAでは、ユーザーはGitLab Duo機能のみにアクセスできます。
- グループBでは、ユーザーはエージェントPlatformにのみアクセスできます。

この例では、ユーザーはGitLab Duo機能とエージェントPlatformの両方にアクセスできます。

A**All eligible users**が設定されている場合:

- GitLab.com: トップレベルグループのすべてのメンバーは、GitLab DuoおよびエージェントPlatform機能にアクセスできます。
- GitLab Self-Managed: すべてのユーザーは、GitLab DuoおよびエージェントPlatform機能にアクセスできます。

追加の制御（トップレベルグループまたはインスタンスの機能を無効にするなど）は引き続き適用されます。

#### グループメンバーシップを同期する {#synchronize-group-membership}

認証にLDAPまたはSAMLを使用する場合は、グループメンバーシップを自動的に同期できます:

1. LDAPまたはSAMLプロバイダーを設定して、エージェントプラットフォームユーザーを表すグループを含めます。
1. GitLabで、グループがLDAPまたはSAMLプロバイダーにリンクされていることを確認します。
1. プロバイダー側のグループでユーザーが追加または削除されると、グループメンバーシップが自動的に更新されます。

詳細については、以下を参照してください: 

- [LDAPグループ同期](../../auth/ldap/_index.md)
- [GitLab Self-ManagedのSAML](../../../integration/saml.md)
- [GitLab.comのSAML](../../../user/group/saml_sso/_index.md)

## アクセス制御を使用する {#using-access-control}

アクセス制御は、段階的なロールアウトやテストと検証に利用できます。

### 段階的なロールアウト {#phased-rollouts}

GitLab DuoまたはエージェントPlatformの段階的なロールアウトを実装するには:

1. パイロットユーザーのグループを作成します（例: `pilot-users`）。
1. 一部のユーザーをこのグループに追加します。
1. 機能を検証し、ユーザーをトレーニングしながら、徐々にグループにユーザーを追加します。
1. 本格的なロールアウトの準備ができたら、すべてのユーザーをグループに追加します。

### テストと検証 {#testing-and-validation}

管理された環境でGitLab DuoまたはエージェントPlatformの機能をテストするには:

1. テスト専用のグループを作成します（例: `agent-testers`）。
1. テストグループまたはプロジェクトを作成します。
1. `agent-testers`グループにテストユーザーを追加します。
1. 幅広いロールアウトの前に、機能を検証し、ユーザーをトレーニングします。

## トラブルシューティング {#troubleshooting}

### ユーザーがGitLab DuoまたはエージェントPlatform機能にアクセスできません {#user-cannot-access-gitlab-duo-or-agent-platform-features}

ユーザーがGitLab DuoまたはエージェントPlatform機能にアクセスできない場合、GitLab DuoまたはエージェントPlatformが次のいずれかの状態である可能性があります:

- ユーザーが直接メンバーであるグループに対して設定されていない。
- 設定されているが、次のいずれかである:
  - ユーザーがグループの直接メンバーではない。
  - **All eligible users**ルールが適切に設定されていない。

このイシューを解決するには、次のいずれかの操作を行います:

- ユーザーを設定されたグループに追加: ユーザーを設定されたグループのいずれかに直接メンバーとして追加します。
- グループのメンバーではないユーザーが機能にアクセスできるように、**All eligible users**ルールに対してGitLab DuoまたはエージェントPlatformをアクティブ化します。
- すべてのグループメンバーシップアクセスルールを削除します。

### 特定のグループでGitLab Duoサイドバーが表示されない {#gitlab-duo-sidebar-does-not-display-for-certain-groups}

GitLab 18.8以前では、グループにエージェントプラットフォームへのアクセスを付与しても、GitLab Duoへのアクセスを付与しない場合、そのグループのメンバーにはGitLab Duoサイドバーが表示されません。回避策として、グループがGitLab Duo機能とエージェントプラットフォーム機能の両方にアクセスできることを確認してください。

このイシューを解決するには、GitLab 18.9以降にアップグレードしてください。
