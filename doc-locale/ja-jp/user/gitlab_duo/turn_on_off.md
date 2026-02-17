---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duoの可用性を制御する
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.10で、[AI機能をオン/オフにする設定が導入](https://gitlab.com/groups/gitlab-org/-/epics/12404)されました。
- GitLab 16.11で、[AI機能をオン/オフにする設定がUIに追加](https://gitlab.com/gitlab-org/gitlab/-/issues/441489)されました。
- [flowの実行のオン/オフを切り替える設定が追加されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203733)（GitLab 18.4）。
- [基本flowと個々のflowのオン/オフを切り替える設定が追加されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215242)（GitLab 18.8）。

{{< /history >}}

[サブスクリプション](../../subscriptions/subscription-add-ons.md)をお持ちの場合、GitLab Duoはデフォルトでオンになっています。

GitLab Duoのオン/オフを切り替えることができます: 

- GitLab.com: トップレベルグループ、その他のグループまたはサブグループ、およびプロジェクト。
- GitLab Self-Managed: インスタンス、グループまたはサブグループ、およびプロジェクト。

GitLab Duo Core（GitLab Duo機能のサブセット）のオン/オフを切り替えることもできます。

GitLab Duoのオンとオフを切り替えると、GitLab Duoの機能（GitLab Duo Chatなど）もオンとオフが切り替わります。

## GitLab Duo Coreのオン/オフを切り替える {#turn-gitlab-duo-core-on-or-off}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/538857)されました。
- GitLab 18.2で、GitLabの可用性設定、およびグループ、サブグループ、プロジェクトの制御が[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/551895)されました。
- UIのGitLab Duo Chat（クラシック）が、GitLab 18.3で[Coreに追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)されました。

{{< /history >}}

[GitLab Duo Core](feature_summary.md)は、PremiumとUltimateのサブスクリプションに含まれています。

- GitLab 17.11以前からの既存の顧客である場合は、GitLab Duo Coreの機能を有効にする必要があります。
- GitLab 18.0以降の新規のお客様の場合、GitLab Duo Coreは自動的にオンになり、それ以上の操作は必要ありません。

2025年5月15日より前にPremiumまたはUltimateのサブスクリプションをお持ちの既存ユーザーがGitLab 18.0以降にアップグレードする場合は、GitLab Duo Coreを利用するにはオンにする必要があります。

### GitLab.com {#on-gitlabcom}

GitLab.comでは、トップレベルグループ（(ネームスペース）のGitLab Duo Coreの可用性を変更できます。

前提条件: 

- トップレベルグループのオーナーロールが必要です。

GitLab Duo Coreの可用性を変更するには: 

1. 上部のバーで、**検索または移動先**を選択し、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duoの可用性**で、オプションを選択します。
1. **GitLab Duo Core**で、**GitLab Duo Coreの機能を有効にする**チェックボックスを選択またはクリアします。GitLab Duoの可用性で**常にオフ**を選択した場合、この設定にアクセスできません。
1. **変更を保存**を選択します。

変更が反映されるまで、最大10分かかる場合があります。

### GitLab Self-Managed {#on-gitlab-self-managed}

GitLab Self-Managedでは、インスタンスのGitLab Duo Coreの可用性を変更できます。

前提条件: 

- 管理者である必要があります。

GitLab Duo Coreの可用性を変更するには: 

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duoの可用性**で、オプションを選択します。
1. **GitLab Duo Core**で、**GitLab Duo Coreの機能を有効にする**チェックボックスを選択またはクリアします。GitLab Duoの可用性で**常にオフ**を選択した場合、この設定にアクセスできません。
1. **変更を保存**を選択します。

## GitLab Duo Agent Platformのオン/オフを切り替えます {#turn-gitlab-duo-agent-platform-on-or-off}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215778)されました。

{{< /history >}}

GitLab Duo Agent Platformには、GitLab Duo Chat（エージェント型）、エージェント、flowが含まれています。この設定はデフォルトでオンになっています。

この設定は、他のGitLab Duoの設定をオーバーライドしません。GitLab Duo Agent Platformを機能させるには:

- GitLab Duoが有効になっている必要があります。
- GitLab Duo Agent Platformはベータ版であるため、実験的機能とベータ機能を有効にする必要があります。

### GitLab.com {#on-gitlabcom-1}

GitLab.comでは、トップレベルグループ（ネームスペース）のGitLab Duo Agent Platformの可用性を制御できます。

前提条件: 

- トップレベルグループのオーナーロールが必要です。

GitLab Duo Agent Platformの可用性を変更するには:

1. 上部のバーで、**検索または移動先**を選択し、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duo Agent Platform**で、**GitLab Duo Chat(エージェント)、agent、およびflowを有効にする**チェックボックスを選択またはクリアします。
1. **変更を保存**を選択します。

GitLab Duo Agent Platformの可用性は、すべてのサブグループとプロジェクトで変更されます。

GitLab Duo Agent Platformをオフにすると、flowと[基本エージェント](../duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off)に関する関連設定が非表示になります。

### GitLab Self-Managed {#on-gitlab-self-managed-1}

GitLab Self-Managedでは、インスタンスのGitLab Duo Agent Platformの可用性を制御できます。

前提条件: 

- 管理者である必要があります。

GitLab Duo Agent Platformの可用性を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duo Agent Platform**で、**GitLab Duo Chat(エージェント)、agent、およびflowを有効にする**チェックボックスを選択またはクリアします。
1. **変更を保存**を選択します。

GitLab Duo Agent Platformをオフにすると、flowと[基本エージェント](../duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off)に関する関連設定が非表示になります。

## GitLab Duoのオン/オフを切り替える {#turn-gitlab-duo-on-or-off}

[サブスクリプション](../../subscriptions/subscription-add-ons.md)をお持ちの場合、GitLab Duoはデフォルトでオンになっています。異なるグループやプロジェクトでの可用性を変更することができます。

### GitLab.com {#on-gitlabcom-2}

GitLab.comでは、トップレベルグループ、他のグループ、サブグループ、およびプロジェクトに対するGitLab Duoの可用性を制御できます。

#### トップレベルグループの場合 {#for-a-top-level-group}

前提条件: 

- グループのオーナーロールが必要です。

トップレベルグループのGitLab Duoの可用性を変更するには: 

1. 上部のバーで、**検索または移動先**を選択し、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duoの可用性**で、オプションを選択します。
1. **flowの実行の許可**切替を使用して、エージェントをGitLab UIで実行できるかどうかを制御します。オンにすると、エージェントはCI/CDパイプラインで実行され、コンピューティング時間を消費します。
1. [基本flow](../duo_agent_platform/flows/foundational_flows/_index.md)を使用するには、**基本flowを許可する**切替をオンにします。個々の基本flowも、トップレベルグループでオンにする必要があります。特定のflowのドキュメントをレビューして、追加の前提条件を確認してください。これらの設定がグループ全体に反映され、機能が利用可能になるまで数分かかる場合があります。
1. **変更を保存**を選択します。

すべてのサブグループとプロジェクトのGitLab Duoの可用性が変更されます。

#### グループまたはサブグループの場合 {#for-a-group-or-subgroup}

前提条件: 

- グループのオーナーロールが必要です。

グループまたはサブグループのGitLab Duoの可用性を変更するには: 

1. 上部のバーで、**検索または移動先**を選択し、グループまたはサブグループを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **GitLab Duoの可用性**で、オプションを選択します。
1. [基本flow](../duo_agent_platform/flows/foundational_flows/_index.md)を使用するには、**基本flowを許可する**切替をオンにします。個々の基本flowは、対応するflowがトップレベルグループでオンになっており、flowのドキュメントからの追加の前提条件が満たされている場合にのみ使用できます。
1. **flowの実行の許可**切替を使用して、エージェントをGitLab UIで実行できるかどうかを制御します。オンにすると、エージェントはCI/CDパイプラインで実行され、コンピューティング時間を消費します。
1. **変更を保存**を選択します。

すべてのサブグループとプロジェクトのGitLab Duoの可用性が変更されます。

#### プロジェクトの場合 {#for-a-project}

前提条件: 

- プロジェクトのオーナーまたはメンテナーのロールが必要です。

プロジェクトのGitLab Duoの可用性を変更するには: 

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**を展開します。
1. **このプロジェクトでAIネイティブ機能を使用する**をオンまたはオフにします。
1. [基本flow](../duo_agent_platform/flows/foundational_flows/_index.md)を使用するには、**基本flowを許可する**切替をオンにします。個々の基本flowは、対応するflowがトップレベルグループでオンになっており、flowのドキュメントからの追加の前提条件が満たされている場合にのみ使用できます。
1. **flowの実行の許可**切替を使用して、エージェントをGitLab UIで実行できるかどうかを制御します。オンにすると、エージェントはCI/CDパイプラインで実行され、コンピューティング時間を消費します。
1. **変更を保存**を選択します。

### GitLab Self-Managed {#on-gitlab-self-managed-2}

GitLab Self-Managedでは、インスタンス、グループ、サブグループ、またはプロジェクトに対するGitLab Duoの可用性を制御できます。

#### インスタンスの場合 {#for-an-instance}

前提条件: 

- 管理者である必要があります。

インスタンスのGitLab Duoの可用性を変更するには: 

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duoの可用性**で、オプションを選択します。
1. **flowの実行の許可**切替を使用して、エージェントをGitLab UIで実行できるかどうかを制御します。オンにすると、エージェントはCI/CDパイプラインで実行され、コンピューティング時間を消費します。
1. **変更を保存**を選択します。

インスタンス全体のGitLab Duo可用性が変更されます。

#### グループまたはサブグループの場合 {#for-a-group-or-subgroup-1}

前提条件: 

- グループとサブグループのオーナーロールが必要です。

グループまたはサブグループのGitLab Duoの可用性を変更するには: 

1. 上部のバーで、**検索または移動先**を選択し、グループまたはサブグループを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **GitLab Duoの可用性**で、オプションを選択します。
1. **flowの実行の許可**切替を使用して、エージェントをGitLab UIで実行できるかどうかを制御します。オンにすると、エージェントはCI/CDパイプラインで実行され、コンピューティング時間を消費します。
1. **変更を保存**を選択します。

すべてのサブグループとプロジェクトのGitLab Duoの可用性が変更されます。

#### プロジェクトの場合 {#for-a-project-1}

前提条件: 

- プロジェクトのオーナーまたはメンテナーのロールが必要です。

プロジェクトのGitLab Duoの可用性を変更するには: 

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**を展開します。
1. **このプロジェクトでAIネイティブ機能を使用する**をオンまたはオフにします。
1. **flowの実行の許可**切替を使用して、エージェントをGitLab UIで実行できるかどうかを制御します。オンにすると、エージェントはCI/CDパイプラインで実行され、コンピューティング時間を消費します。
1. **変更を保存**を選択します。

プロジェクトのGitLab Duo可用性が変更されます。

### 以前のGitLabバージョン {#for-earlier-gitlab-versions}

以前のGitLabバージョンでGitLab Duoのオン/オフを切り替える方法については、[以前のGitLabバージョンでGitLab Duoの可用性を制御する](turn_on_off_earlier.md)を参照してください。

## ベータ版および実験的機能をオンにする {#turn-on-beta-and-experimental-features}

GitLab Duoの実験的機能とベータ版機能は、デフォルトでオフになっています。これらの機能には、[テスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)が適用されます。

### GitLab.com {#on-gitlabcom-3}

前提条件: 

- トップレベルグループのオーナーロールが必要です。

トップレベルグループでGitLab Duoの実験的機能とベータ版機能をオンにするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **機能のプレビュー**で、**GitLab Duoの実験的機能とベータ版機能を有効にする**を選択します。
1. **変更を保存**を選択します。

この設定は、グループに属する[すべてのプロジェクトにカスケードされます](../project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)。

### GitLab Self-Managed {#on-gitlab-self-managed-3}

{{< tabs >}}

{{< tab title="17.4以降" >}}

GitLab 17.4以降では、次の手順に従って、GitLab Self-ManagedインスタンスのGitLab Duoの実験的機能およびベータ版機能をオンにします。

{{< alert type="note" >}}

GitLab 17.4から17.6では、Self-ManagedインスタンスでGitLab Duo設定ページが利用可能です。GitLab 17.7以降では、設定ページにはさらに多くの設定オプションが含まれています。

{{< /alert >}}

前提条件: 

- 管理者である必要があります。

インスタンスのGitLab Duoの実験的機能およびベータ版機能をオンにするには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を展開します。
1. **機能プレビュー**で、**Use experiment and beta GitLab Duo features**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

前提条件: 

- 管理者であること。
- [ネットワーク接続](../../administration/gitlab_duo/configure/gitlab_self_managed.md)が有効になっていること。
- [サイレントモード](../../administration/silent_mode/_index.md)が無効になっていること。

インスタンスのGitLab Duoの実験的機能およびベータ版機能をオンにするには:

1. 右上隅で、**管理者**を選択します。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を展開します。
1. **機能プレビュー**で、**Use experiment and beta GitLab Duo features**を選択します。
1. **変更を保存**を選択します。
1. GitLab Duo Chatをすぐに動作させるには、[手動でサブスクリプションを同期](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)します。

   サブスクリプションを手動で同期しない場合、インスタンスでGitLab Duo Chatがアクティブになるまでに最大24時間かかることがあります。

{{< /tab >}}

{{< /tabs >}}
