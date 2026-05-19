---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
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

{{< /history >}}

GitLab Duoはデフォルトでオンになっています。GitLab Duoには、[一連の機能](feature_summary.md)が含まれています。

GitLab Duoのオン/オフを切り替えることができます: 

- GitLab.com: トップレベルグループ、その他のグループまたはサブグループ、およびプロジェクト。
- GitLab Self-Managed: インスタンス、グループまたはサブグループ、およびプロジェクト。

## GitLab Duoのオン/オフを切り替える {#turn-gitlab-duo-on-or-off}

### GitLab.com {#on-gitlabcom}

#### トップレベルグループの場合 {#for-a-top-level-group}

前提条件: 

- トップレベルグループのオーナーロール。

トップレベルグループのGitLab Duoの利用可能性を変更するには:

1. 上部のバーで**検索または移動先**を選択し、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duoの可用性**で、オプションを選択します。
1. **変更を保存**を選択します。

すべてのサブグループとプロジェクトに対してGitLab Duoの可用性が変更されます。

#### グループまたはサブグループの場合 {#for-a-group-or-subgroup}

前提条件: 

- グループまたはサブグループのオーナーロール。

グループまたはサブグループに対してGitLab Duoの可用性を変更するには: 

1. トップバーで**検索または移動先**を選択し、グループまたはサブグループを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **GitLab Duoの可用性**で、オプションを選択します。
1. **変更を保存**を選択します。

すべてのサブグループとプロジェクトに対してGitLab Duoの可用性が変更されます。

#### プロジェクトの場合 {#for-a-project}

前提条件: 

- プロジェクトのオーナーまたはメンテナーロール。

プロジェクトに対してGitLab Duoの可用性を変更するには: 

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**を展開します。
1. **GitLab Duo**切替をオンまたはオフにします。
1. **変更を保存**を選択します。

### GitLab Self-Managed {#on-gitlab-self-managed}

#### インスタンスの場合 {#for-an-instance}

前提条件: 

- 管理者アクセス権が必要です。

インスタンスのGitLab Duoの利用可能性を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duoの可用性**で、オプションを選択します。
1. **変更を保存**を選択します。

#### グループまたはサブグループの場合 {#for-a-group-or-subgroup-1}

前提条件: 

- グループまたはサブグループのオーナーロール。

グループまたはサブグループに対してGitLab Duoの可用性を変更するには: 

1. トップバーで**検索または移動先**を選択し、グループまたはサブグループを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **GitLab Duoの可用性**で、オプションを選択します。
1. **変更を保存**を選択します。

すべてのサブグループとプロジェクトに対してGitLab Duoの可用性が変更されます。

#### プロジェクトの場合 {#for-a-project-1}

前提条件: 

- プロジェクトのオーナーまたはメンテナーロール。

プロジェクトに対してGitLab Duoの可用性を変更するには: 

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**を展開します。
1. **GitLab Duo**切替をオンまたはオフにします。
1. **変更を保存**を選択します。

### 以前のGitLabバージョンの場合 {#for-earlier-gitlab-versions}

以前のGitLabバージョンでGitLab Duoをオンまたはオフにする方法については、[以前のGitLabバージョンでGitLab Duoの利用可能性を制御](turn_on_off_earlier.md)を参照してください。

## GitLab Duo Coreのオン/オフを切り替える {#turn-gitlab-duo-core-on-or-off}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/538857)されました。
- GitLab Duoの利用可能性設定と、グループ、サブグループ、およびプロジェクトのコントロールが[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/551895)されました。GitLab 18.2。
- GitLab 18.3でGitLab Duo CoreにGitLab Duo Non-Agentic Chatが[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)されました。

{{< /history >}}

GitLab Duo Coreは、PremiumおよびUltimateサブスクリプションに含まれています。

- GitLab 17.11以前から利用を継続しているユーザーは、GitLab Duo Coreの機能をオンにする必要があります。
- GitLab 18.0以降の新規ユーザーの場合、GitLab Duo Coreは自動的にオンになり、それ以上のアクションは必要ありません。

2025年5月15日より前からPremiumまたはUltimateのサブスクリプションをお持ちの既存ユーザーがGitLab 18.0以降にアップグレードする場合は、GitLab Duo Coreを利用するにはオンにする必要があります。

### GitLab.com {#on-gitlabcom-1}

前提条件: 

- トップレベルグループのオーナーロール。

トップレベルグループのGitLab Duo Coreの利用可能性を変更するには:

1. 上部のバーで**検索または移動先**を選択し、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duoの可用性**で、オプションを選択します。
1. **GitLab Duo Core**で、**GitLab Duo Agent Platformのアクセスを有効にする**チェックボックスをオンまたはオフにします。GitLab Duoの可用性で**常にオフ**を選択した場合、この設定にアクセスできません。
1. **変更を保存**を選択します。

変更が反映されるまで、最大10分かかる場合があります。

### GitLab Self-Managed {#on-gitlab-self-managed-1}

前提条件: 

- 管理者アクセス権が必要です。

インスタンスのGitLab Duo Coreの利用可能性を変更するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **GitLab Duoの可用性**で、オプションを選択します。
1. **GitLab Duo Core**で、**GitLab Duo Agent Platformのアクセスを有効にする**チェックボックスをオンまたはオフにします。GitLab Duoの可用性で**常にオフ**を選択した場合、この設定にアクセスできません。
1. **変更を保存**を選択します。

## ベータ版および実験的機能をオンにする {#turn-on-beta-and-experimental-features}

GitLab Duoの実験的機能とベータ版機能は、デフォルトでオフになっています。これらの機能には、[テスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)が適用されます。

### GitLab.com {#on-gitlabcom-2}

前提条件: 

- トップレベルグループのオーナーロール。

トップレベルグループに対してGitLab Duoの実験的機能とベータ版機能をオンにするには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **機能プレビュー**で、**GitLab Duoの実験的機能とベータ版機能を有効にする**を選択します。
1. **変更を保存**を選択します。

この設定は、グループに属する[すべてのプロジェクトにカスケードされます](../project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)。

### GitLab Self-Managed {#on-gitlab-self-managed-2}

{{< tabs >}}

{{< tab title="17.4以降" >}}

GitLab 17.4以降では、次の手順に従って、GitLab Self-ManagedインスタンスのGitLab Duoの実験的およびベータ版機能をオンにします。

前提条件: 

- 管理者アクセス権が必要です。

インスタンスに対してGitLab Duoの実験的機能およびベータ版機能をオンにするには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **GitLab Duo**を選択します。
1. **設定の変更**を展開します。
1. **機能プレビュー**で、**GitLab Duoの実験的機能とベータ版機能を使用する**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

前提条件: 

- 管理者アクセス権が必要です。
- [ネットワーク接続](../../administration/gitlab_duo/configure/gitlab_self_managed.md)が有効。
- [サイレントモード](../../administration/silent_mode/_index.md)がオフになっています。

インスタンスに対してGitLab Duoの実験的機能およびベータ版機能をオンにするには:

1. 右上隅で、**管理者**を選択します。
1. 左サイドバーで、**設定** > **GitLab Duo**を選択します。
1. **設定の変更**を展開します。
1. **機能プレビュー**で、**GitLab Duoの実験的機能とベータ版機能を使用する**を選択します。
1. **変更を保存**を選択します。
1. GitLab Duo Chatをすぐに動作させるには、[手動でサブスクリプションを同期](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)します。

   サブスクリプションを手動で同期しない場合、インスタンスでGitLab Duo Chatがアクティブになるまで最大24時間かかることがあります。

{{< /tab >}}

{{< /tabs >}}
