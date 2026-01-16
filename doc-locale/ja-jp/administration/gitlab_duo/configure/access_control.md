---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duo Agent Platformへのアクセスを設定します。
title: Agent Platformへのアクセスを設定する
---

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/583909)。

{{< /history >}}

[グループのGitLab Duoのオン/オフを切り替える](../../../user/gitlab_duo/turn_on_off.md)ことができます。

さらに、Agent Platformの機能のみにアクセスできる特定のグループを指定できます。

## Agent Platformの機能へのユーザーアクセスを許可する {#give-a-user-access-to-agent-platform-features}

特定のAgent Platform機能へのユーザーアクセスを許可するには、次の手順を実行します。

{{< tabs >}}

{{< tab title="インスタンスの場合" >}}

前提条件: 

- 管理者である必要があります。

特定の機能へのユーザーアクセスを許可するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **メンバーのアクセス**で、**グループを追加**を選択します。 
1. 検索ボックスを使用して、既存のグループを選択します。
1. グループメンバーがアクセスできる機能を選択します。
1. **変更を保存**を選択します。

ユーザーは、アクセス権を持ち、機能が有効になっているインスタンス内のどこからでもこれらの機能にアクセスできるようになりました。

{{< /tab >}}

{{< tab title="GitLab.comの場合" >}}

前提条件: 

- トップレベルネームスペースの管理者である必要があります。
- 既存のグループ、またはDAPユーザー用に新しいグループを作成する機能。

特定の機能へのユーザーアクセスを許可するには:

1. 上部のバーで、**検索または移動先**を選択し、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **メンバーのアクセス**で、**グループを追加**を選択します。 
1. 検索ボックスを使用して、既存のグループを選択します。
1. グループメンバーがアクセスできる機能を選択します。
1. **変更を保存**を選択します。

これらの設定は、以下に適用されます:

- トップレベルグループが[デフォルトのGitLab Duoのネームスペース](../../gitlab_duo/model_selection.md)であるユーザー。
- デフォルトのネームスペースを介してアクセスできないが、現在のトップレベルグループで機能を使用できるユーザー。

{{< /tab >}}

{{< /tabs >}}

グループメンバーシップを手動で管理しない場合は、[LDAPまたはSAMLを使用してメンバーシップを同期](#synchronize-group-membership)できます。

### 複数のグループメンバーシップ {#multiple-group-membership}

ユーザーが複数のグループに割り当てられている場合、割り当てられているすべてのグループから機能を取得します。例: 

- グループAでは、従来の機能にのみアクセスできます。
- グループBでは、フローにのみアクセスできます。

従来の機能とフローの両方にアクセスできるようになります。

### グループが構成されていない場合 {#when-no-group-is-configured}

グループが構成されていない場合:

- GitLab.com: トップレベルネームスペースのすべてのメンバーは、Duo Agent Platform機能を使用できます。追加の制御（ネームスペース全体の機能を無効にするなど）も適用されます。
- GitLab Self-Managed: インスタンス内のすべてのユーザーは、Agent Platform機能を使用できます。

すべてのシナリオで、ネームスペースまたはインスタンス全体の機能を無効にするなどの追加の制御が引き続き適用されます。

### グループメンバーシップを同期 {#synchronize-group-membership}

認証にLDAPまたはSAMLを使用する場合は、グループメンバーシップを自動的に同期できます:

1. DAPユーザーを表すグループを含めるように、LDAPまたはSAMLプロバイダーを構成します。
1. GitLabで、グループがLDAP/SAMLプロバイダーにリンクされていることを確認します。
1. ユーザーがプロバイダーグループから追加または削除されると、グループメンバーシップが自動的に更新されます。

詳細については、以下を参照してください: 

- [LDAPグループの同期](../../auth/ldap/_index.md)
- [GitLab Self-ManagedのSAML](../../../integration/saml.md)
- [GitLab.comのSAML](../../../user/group/saml_sso/_index.md)

## ユースケース {#use-cases}

グループを使用して、段階的なロールアウトを実装したり、テストを実施したりできます。

### 段階的なロールアウト {#phased-rollout}

Agent Platformの段階的なロールアウトを実装するには:

1. パイロットユーザーのグループを作成します（例: `pilot-users`）。
1. ユーザーのサブセットをこのグループに割り当てます。
1. 機能性を検証し、ユーザーをトレーニングする際に、徐々にグループにユーザーを追加します。
1. 完全なロールアウトの準備ができたら、すべてのユーザーをグループに割り当てます。

### テストと検証 {#testing-and-validation}

制御された環境でAgent Platformの機能をテストするには:

1. テスト用の専用グループを作成します（例: `agent-testers`）。
1. テストネームスペースまたはプロジェクトを作成します。
1. `agent-testers`グループにテストユーザーを追加します。
1. 広範なロールアウトの前に、機能性を検証し、ユーザーをトレーニングします。

## 関連トピック {#related-topics}

- [GitLab Duoをオンにする](../../../user/gitlab_duo/turn_on_off.md)
