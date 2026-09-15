---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duoへのアクセスを設定します。
title: GitLab Duoへのアクセスを設定
---

{{< details >}}

- プラン: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier)、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/583909)されました。

{{< /history >}}

グループのGitLab Duoを[オンまたはオフにしたり](../../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-on-or-off)、1つ以上のグループのGitLab Duoへのアクセスを制限したりできます。

## GitLab Duoへのアクセスを制限 {#restrict-access-to-gitlab-duo}

{{< history >}}

- デフォルトの**グループなし**ルールは[GitLab 18.10で導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225728)。
- **Member access**セクションと**No group**ルールは、GitLab 18.11で[名称変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229785)されました。

{{< /history >}}

{{< tabs >}}

{{< tab title="GitLab.com" >}}

前提条件: 

- トップレベルグループのオーナーロール。

トップレベルグループのGitLab Duoへのアクセスを制限するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **グループメンバーシップに基づいてアクセス権を制限する**で、**グループの追加**を選択します。
1. ドロップダウンリストからグループを選択します。

   最初のグループを選択すると、デフォルトで**すべての対象ユーザー**ルールも追加されます。このルールを使用して、他のすべてのユーザーのアクセスを設定できます。このルールは、グループがGitLab Duo Non-AgenticまたはGitLab Duo Agent Platformへのアクセス権を持たず、既存のすべてのグループが削除された場合に自動的に削除されます。

1. グループの直接メンバーがGitLab Duo Non-AgenticおよびGitLab Duo Agent Platformにアクセスできるかどうかを選択します。
1. **変更を保存**を選択します。

これらの設定は、次のユーザーに適用されます:

- **グループメンバーシップに基づいてアクセス権を制限する**の下で設定されたグループのいずれかの直接メンバーであり、トップレベルグループのプロジェクトまたはサブグループでAIアクションを実行するユーザー。
- トップレベルグループを[default GitLab Duo namespace](../../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace)として持ち、AIアクションが実行されるトップレベルグループのメンバーではないユーザー。

アクセス制御を設定する場合、トップレベルグループの直接サブグループであるグループのみを選択できます。アクセス制御ルールでは、ネストされたサブグループを使用できません。

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

前提条件: 

- 管理者アクセス権。

インスタンスのGitLab Duoへのアクセスを制限するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **グループメンバーシップに基づいてアクセス権を制限する**で:
   - 既存のグループを追加するには、**グループの追加**を選択します。
   - 新しいグループを作成するには、**グループを作成**を選択します。
1. ドロップダウンリストからグループを選択します。

   最初のグループを選択すると、デフォルトで**すべての対象ユーザー**ルールも追加されます。このルールを使用して、他のすべてのユーザーのアクセスを設定できます。このルールは、グループがGitLab Duo Non-AgenticまたはGitLab Duo Agent Platformへのアクセス権を持たず、既存のすべてのグループが削除された場合に自動的に削除されます。

1. グループの直接メンバーがGitLab Duo Non-AgenticおよびGitLab Duo Agent Platformにアクセスできるかどうかを選択します。
1. **変更を保存**を選択します。

これらの設定は、**グループメンバーシップに基づいてアクセス権を制限する**の下で設定されたグループのいずれかの直接メンバーであるユーザーに適用されます。

アクセス制御を設定する場合、トップレベルグループのみを選択できます。サブグループはアクセス制御ルールで使用できません。

{{< /tab >}}

{{< /tabs >}}

グループメンバーシップを手動で管理しない場合は、[LDAPまたはSAMLを使用してメンバーシップを同期](#synchronize-group-membership)できます。

### グループメンバーシップ {#group-membership}

ユーザーが複数のグループに割り当てられている場合、そのユーザーは割り当てられたすべてのグループの機能にアクセスできます。たとえば、ユーザーがグループAでGitLab Duo Non-Agenticへのアクセス権を持ち、グループBでGitLab Duo Agent Platformへのアクセス権を持つ場合、そのユーザーは両方の機能セットにアクセスできます。

**すべての対象ユーザー**ルールが設定されている場合、次のユーザーはGitLab Duo Non-AgenticとGitLab Duo Agent Platformの両方にアクセスできます:

- GitLab.comの場合: トップレベルグループのすべてのメンバー。
- GitLab Self-Managed: すべてのユーザー。

追加の制御（トップレベルグループまたはインスタンスの機能を無効にするなど）は引き続き適用されます。

#### グループメンバーシップを同期する {#synchronize-group-membership}

認証にLDAPまたはSAMLを使用する場合は、グループメンバーシップを自動的に同期できます:

1. LDAPまたはSAMLプロバイダーを設定して、GitLab Duo Agent Platformユーザーを表すグループを含めます。
1. GitLabで、グループがLDAPまたはSAMLプロバイダーにリンクされていることを確認します。
1. プロバイダー側のグループでユーザーが追加または削除されると、グループメンバーシップが自動的に更新されます。

詳細については、以下を参照してください:

- [LDAPグループ同期](../../auth/ldap/_index.md)
- [GitLab Self-ManagedのSAML](../../../integration/saml.md)
- [GitLab.comのSAML](../../../user/group/saml_sso/_index.md)

## アクセス制御を使用する {#using-access-control}

アクセス制御は、段階的なロールアウトやテストと検証に利用できます。

### 段階的なロールアウト {#phased-rollouts}

GitLab Duoの段階的なロールアウトを実装するには:

1. パイロットユーザーのグループを作成します（例: `pilot-users`）。
1. 一部のユーザーをこのグループに追加します。
1. 機能を検証し、ユーザーをトレーニングしながら、徐々にグループにユーザーを追加します。
1. 本格的なロールアウトの準備ができたら、すべてのユーザーをグループに追加します。

### テストと検証 {#testing-and-validation}

制御された環境でGitLab Duoの機能をテストするには:

1. テスト専用のグループを作成します（例: `agent-testers`）。
1. テストグループまたはプロジェクトを作成します。
1. `agent-testers`グループにテストユーザーを追加します。
1. 幅広いロールアウトの前に、機能を検証し、ユーザーをトレーニングします。

## トラブルシューティング {#troubleshooting}

### ユーザーがGitLab Duo機能にアクセスできません {#user-cannot-access-gitlab-duo-features}

ユーザーがGitLab Duo機能にアクセスできないシナリオは次のとおりです:

- グループに対してGitLab Duo Non-AgenticまたはGitLab Duo Agent Platformへのアクセスが設定されていません。
- グループに対してGitLab Duo Non-AgenticまたはGitLab Duo Agent Platformへのアクセスが設定されていますが、次のいずれかに該当します:
  - ユーザーがグループの直接メンバーではない。
  - **すべての対象ユーザー**ルールが設定されていません。

この問題を解決するには、次のいずれかを実行します。

- ユーザーを設定されたグループのいずれかに直接メンバーとして追加します。
- **すべての対象ユーザー**にGitLab Duo Non-AgenticまたはGitLab Duo Agent Platformへのアクセス権を付与します。
- すべてのグループメンバーシップアクセスルールを削除します。

### 特定のグループでGitLab Duoサイドバーが表示されない {#gitlab-duo-sidebar-does-not-display-for-certain-groups}

GitLab 18.8と以前のバージョンでは、グループにGitLab Duo Agent Platformへのアクセス権を付与しても、GitLab Duo Non-Agenticへのアクセス権を付与しない場合、そのグループのメンバーにはGitLab Duoサイドバーが表示されません。回避策として、グループがGitLab Duo Non-AgenticとGitLab Duo Agent Platformの両方にアクセスできることを確認してください。

このイシューを解決するには、GitLab 18.9以降にアップグレードしてください。
