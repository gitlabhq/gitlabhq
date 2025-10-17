---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duoの利用可能性の制御
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise。
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- AI機能をオン/オフにする[設定の導入](https://gitlab.com/groups/gitlab-org/-/epics/12404)（GitLab 16.10）。
- [AI機能をオン/オフにする設定をUIに追加](https://gitlab.com/gitlab-org/gitlab/-/issues/441489)（GitLab 16.11）。

{{< /history >}}

[サブスクリプション](../../subscriptions/subscription-add-ons.md)をお持ちの場合、GitLab Duoはデフォルトでオンになっています。

GitLab Duoのオン/オフを切り替えることができます: 

- GitLab.comの場合: トップレベルグループ、その他のグループまたはサブグループ、およびプロジェクトの場合。
- GitLab Self-Managedの場合: インスタンス、グループまたはサブグループ、およびプロジェクトの場合。

GitLab Duo Core（GitLab Duoの機能のサブセット）のオン/オフを切り替えることもできます。

## GitLab Duo Coreのオン/オフを切り替える {#turn-gitlab-duo-core-on-or-off}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/538857)されました。
- GitLab 18.2で、GitLabの可用性設定、およびグループ、サブグループ、プロジェクトの制御が[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/551895)されました。
- UIのGitLab Duo Chat (Classic) が、GitLab 18.3で[Coreに追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)されました。

{{< /history >}}

[GitLab Duo Core](feature_summary.md)は、PremiumとUltimateのサブスクリプションに含まれています。

- GitLab 17.11以前からの既存の顧客の場合は、WebまたはIDEの機能をオンにして、GitLab Duo Coreの使用を開始する必要があります。
- GitLab 18.0以降の新規顧客の場合、GitLab Coreは自動的にオンになり、それ以上のアクションは必要ありません。

2025年5月15日より前にPremiumまたはUltimateプランのサブスクリプションをお持ちの既存ユーザーがGitLab 18.0以降にアップグレードする場合は、GitLab Duo Coreをオンにする必要があります。

### GitLab.com {#on-gitlabcom}

GitLab.comでは、トップレベルグループ (ネームスペース) のGitLab Duo Coreの可用性を変更できます。

前提要件: 

- トップレベルグループのオーナーロールが必要です。

GitLab Duo Coreの利用可否を変更するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **このネームスペースにおけるGitLab Duoの可用性**で、オプションを選択します。
1. **GitLab Duo Core**で、**WebとIDE機能を有効にする**チェックボックスをオンまたはオフにします。GitLab Duoの可用性で**常にオフ**を選択した場合、この設定にアクセスできません。
1. **変更を保存**を選択します。

変更が有効になるまで、最大10分かかる場合があります。

### GitLab Self-Managed {#on-gitlab-self-managed}

GitLab Self-Managedでは、インスタンスのGitLab Duo Coreの可用性を変更できます。

前提要件: 

- 管理者である必要があります。

GitLab Duo Coreの利用可否を変更するには: 

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **このインスタンスにおけるGitLab Duoの可用性**で、オプションを選択します。
1. **GitLab Duo Core**で、**WebとIDE機能を有効にする**チェックボックスをオンまたはオフにします。GitLab Duoの可用性で**常にオフ**を選択した場合、この設定にアクセスできません。
1. **変更を保存**を選択します。

## GitLab Duoのオン/オフを切り替える {#turn-gitlab-duo-on-or-off}

[サブスクリプション](../../subscriptions/subscription-add-ons.md)をお持ちの場合、GitLab Duoはデフォルトでオンになっています。さまざまなグループおよびプロジェクトについて、その可用性を変更することを選択できます。

### GitLab.com {#on-gitlabcom-1}

GitLab.comでは、トップレベルグループ、他のグループ、サブグループ、およびプロジェクトに対するGitLab Duoの可用性を制御できます。

#### トップレベルグループの場合 {#for-a-top-level-group}

前提要件: 

- グループのオーナーロールが必要です。

トップレベルグループのGitLab Duoの可用性を変更するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、トップレベルグループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **このネームスペースにおけるGitLab Duoの可用性**で、オプションを選択します。
1. **変更を保存**を選択します。

すべてのサブグループとプロジェクトに対して、GitLab Duoの可用性が変更されます。

#### グループまたはサブグループの場合 {#for-a-group-or-subgroup}

前提要件: 

- グループのオーナーロールが必要です。

グループまたはサブグループに対するGitLab Duoの可用性を変更するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、グループまたはサブグループを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **このグループにおけるGitLab Duoの利用可能性**で、オプションを選択します。
1. **変更を保存**を選択します。

すべてのサブグループとプロジェクトに対して、GitLab Duoの可用性が変更されます。

#### プロジェクトの場合 {#for-a-project}

前提要件: 

- プロジェクトのオーナーロールが必要です。

プロジェクトに対するGitLab Duoの可用性を変更するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**を展開する。
1. 「**このプロジェクトではAIネイティブ機能を使用する**」切替をオンまたはオフにします。
1. **変更を保存**を選択します。

### GitLab Self-Managed {#on-gitlab-self-managed-1}

GitLab Self-Managedでは、インスタンス、グループ、サブグループ、またはプロジェクトに対するGitLab Duoの可用性を制御できます。

#### インスタンスの場合 {#for-an-instance}

前提要件: 

- 管理者である必要があります。

インスタンスに対するGitLab Duoの可用性を変更するには: 

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **設定の変更**を選択します。
1. **このインスタンスにおけるGitLab Duoの可用性**で、オプションを選択します。
1. **変更を保存**を選択します。

GitLab Duoの可用性は、インスタンス全体に対して変更されます。

#### グループまたはサブグループの場合 {#for-a-group-or-subgroup-1}

前提要件: 

- グループとサブグループのオーナーロールが必要です。

グループまたはサブグループに対するGitLab Duoの可用性を変更するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、グループまたはサブグループを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duoの機能**を展開します。
1. **このグループにおけるGitLab Duoの利用可能性**で、オプションを選択します。
1. **変更を保存**を選択します。

すべてのサブグループとプロジェクトに対して、GitLab Duoの可用性が変更されます。

#### プロジェクトの場合 {#for-a-project-1}

前提要件: 

- プロジェクトのオーナーロールが必要です。

プロジェクトに対するGitLab Duoの可用性を変更するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **GitLab Duo**を展開する。
1. 「**このプロジェクトではAIネイティブ機能を使用する**」切替をオンまたはオフにします。
1. **変更を保存**を選択します。

GitLab Duoの可用性は、プロジェクトに対して変更されます。

### 以前のGitLabのバージョン {#for-earlier-gitlab-versions}

バージョンが以前のGitLabでGitLab Duoをオンまたはオフにする方法については、[以前のGitLabバージョンのGitLab Duoの可用性の制御](turn_on_off_earlier.md)を参照してください。

## ベータ版および実験版の機能をオンにする {#turn-on-beta-and-experimental-features}

実験版およびベータ版のGitLab Duo機能は、デフォルトでオフになっています。これらの機能には、[テスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)が適用されます。

### GitLab.com {#on-gitlabcom-2}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< tabs >}}

{{< tab title="17.4以降" >}}

GitLab 17.4以降では、次の手順に従って、GitLab.comでグループに対してGitLab Duoの実験版およびベータ版の機能をオンにします。

{{< alert type="note" >}}

GitLab 17.4-17.6では、トップレベルグループに対してのみこの設定を変更できます。（サブグループには必要な設定がありません）。GitLab 17.7以降では、すべてのグループで設定を利用できます。

{{< /alert >}}

前提要件: 

- トップレベルグループのオーナーロールが必要です。

トップレベルグループのGitLab Duoの実験版およびベータ版の機能をオンにするには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **GitLab Duo**を選択します。
1. **GitLab Duo**セクションで、**設定の変更**を選択します。
1. **機能のプレビュー**で、**GitLab Duoの実験版およびベータ版の機能を有効にする**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

GitLab 17.3以前では、次の手順に従って、GitLab.comでグループに対してGitLab Duoの実験版およびベータ版の機能をオンにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **GitLab Duoの実験版およびベータ版の機能**で、**GitLab Duoの実験版およびベータ版の機能の使用**チェックボックスをオンにします。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< /tabs >}}

この設定は、グループに属する[すべてのプロジェクトにカスケードされます](../project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)。

### GitLab Self-Managed {#on-gitlab-self-managed-2}

{{< tabs >}}

{{< tab title="17.4以降" >}}

GitLab 17.4以降では、次の手順に従って、GitLab Self-Managedインスタンスに対してGitLab Duoの実験版およびベータ版の機能をオンにします。

{{< alert type="note" >}}

GitLab 17.4-17.6では、GitLab Duo設定ページはSelf-Managedインスタンスで利用できます。GitLab 17.7以降では、設定ページにはさらに多くの設定オプションが含まれています。

{{< /alert >}}

前提要件: 

- 管理者である必要があります。

インスタンスのGitLab Duoの実験的およびベータ版機能をオンにするには、次の手順に従います。

1. 左側のサイドバーの下部で、**管理者エリア**を選択します。
1. **設定** > **GitLab Duo**を選択します。
1. **設定の変更**を展開します。
1. **機能のプレビュー**で、**GitLab Duoの実験版およびベータ版の機能の使用**を選択します。
1. **変更を保存**を選択します。

{{< /tab >}}

{{< tab title="17.3以前" >}}

GitLab Duo Chatがまだ[一般提供](../gitlab_duo_chat/turn_on_off.md#for-gitlab-self-managed)されていないGitLabバージョンでGitLab Duoのベータ版および実験的機能を有効にするには、GitLab Duo Chatのドキュメントを参照してください。

{{< /tab >}}

{{< /tabs >}}
