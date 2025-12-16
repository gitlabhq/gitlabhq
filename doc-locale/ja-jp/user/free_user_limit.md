---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 無料ユーザーの制限
---

{{< details >}}

- プラン: Free
- 提供形態: GitLab.com

{{< /details >}}

GitLab.comで非公開の表示レベルの新しいトップレベルグループに、最大5人のユーザーを追加できます。

ネームスペースが2022年12月28日より前に作成された場合、このユーザー制限は2023年6月13日に適用されました。

5人を超えるユーザーがいる非公開のトップレベルネームスペースは、読み取り専用状態になります。これらのネームスペースは、次のいずれにも新しいデータを書き込むことができません:

- リポジトリ
- Git Large File Storage（LFS）
- パッケージ
- レジストリ。

制限されているアクションの完全なリストについては、[読み取り専用ネームスペース](read_only_namespaces.md)を参照してください。

ユーザー制限は、Freeティアのユーザーには適用されません:

- GitLab.comの場合:
  - パブリックトップレベルグループ
  - 個人用ネームスペース（デフォルトで公開されているため）
  - 有料ティア
  - 次の[コミュニティプログラム](https://about.gitlab.com/community/):
    - オープンソース団体向けGitLab
    - 教育団体向けGitLab
    - スタートアップ向けGitLab
- [GitLab Self-Managedサブスクリプション](../subscriptions/self_managed/_index.md)

詳細については、[エキスパートにお問い合わせください](https://page.gitlab.com/usage_limits_help.html)。

## ネームスペースのユーザー数を確認する {#determine-namespace-user-counts}

非公開の表示レベルのトップレベルネームスペースのすべてのユニークユーザーは、5人のユーザー制限にカウントされます。これには、ネームスペース内のグループ、サブグループ、およびプロジェクトのすべてのユーザーが含まれます。

たとえば、2つのグループ、`example-1`と`example-2`があるとします。

`example-1`グループには次のものがあります:

- 1人のグループオーナー、`A`。
- 1人のメンバー`B`がいる`subgroup-1`というサブグループが1つ。
  - `subgroup-1`は、`example-1`のメンバーとして`A`を継承します。
- 2人のメンバー`C`と`D`がいる`subgroup-1`の`project-1`というプロジェクトが1つ。
  - `project-1`は、`subgroup-1`のメンバーとして`A`と`B`を継承します。

ネームスペース`example-1`には、`A`、`B`、`C`、および`D`の4人のユニークメンバーがいるため、5人のユーザー制限を超えることはありません。

`example-2`グループには次のものがあります:

- 1人のグループオーナー、`A`。
- 1人のメンバー`B`がいる`subgroup-2`というサブグループが1つ。
  - `subgroup-2`は、`example-2`のメンバーとして`A`を継承します。
- 2人のメンバー`C`と`D`がいる`subgroup-2`の`project-2a`というプロジェクトが1つ。
  - `project-2a`は、`subgroup-2`のメンバーとして`A`と`B`を継承します。
- 2人のメンバー`E`と`F`がいる`subgroup-2`の`project-2b`というプロジェクトが1つ。
  - `project-2b`は、`subgroup-2`のメンバーとして`A`と`B`を継承します。

ネームスペース`example-2`には、`A`、`B`、`C`、`D`、`E`、および`F`の6人のユニークメンバーがいるため、5人のユーザー制限を超えています。

## グループネームスペース内のメンバーを管理する {#manage-members-in-your-group-namespace}

Freeユーザー制限を管理するために、ネームスペース内のすべてのプロジェクトとグループのメンバーの総数を表示および管理できます。

前提要件: 

- グループのオーナーロールが必要です。

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **使用量クォータ**を選択します。
1. すべてのメンバーを表示するには、**シート**タブを選択します。

このページでは、ネームスペース内のすべてのメンバーを表示および管理できます。たとえば、メンバーを削除するには、**ユーザーを削除**を選択します。

## 組織のサブスクリプションにグループを含める {#include-a-group-in-an-organizations-subscription}

組織に複数のグループがある場合、（PremiumまたはUltimateプラン）有料とFreeティアサブスクリプションが組み合わされている可能性があります。Freeティアサブスクリプションを持つグループがユーザー制限を超えると、そのネームスペースは[読み取り専用](read_only_namespaces.md)になります。

Freeティアサブスクリプションを持つグループのユーザー制限を削除するには、それらのグループを組織のサブスクリプションに含めます:

1. グループがサブスクリプションに含まれているかどうかを確認するには、[そのグループのサブスクリプションの詳細を表示](../subscriptions/manage_subscription.md#view-subscription)します。

   グループにFreeティアサブスクリプションがある場合、それは組織のサブスクリプションには含まれていません。

1. 有料のPremiumまたはUltimateプランサブスクリプションにグループを含めるには、組織のトップレベルネームスペースに[そのグループを転送](group/manage.md#transfer-a-group)します。

有料のPremiumまたはUltimateプランのサブスクリプションをお持ちの場合でも、グループに5人のユーザー制限が適用されている場合は、[お客様のサブスクリプションがリンクされている](../subscriptions/manage_subscription.md#link-subscription-to-a-group)ことを確認してください:

- 正しいトップレベルネームスペース。
- お客様の[GitLabカスタマーポータル](../subscriptions/billing_account.md)アカウント。

### 転送されたグループがサブスクリプションコストに与える影響 {#impact-of-transferred-groups-on-subscription-costs}

グループを組織のサブスクリプションに転送すると、シート数が増加する可能性があります。これにより、サブスクリプションに追加費用が発生する可能性があります。

たとえば、あなたの会社にはグループAとグループBがあります:

- グループAには、有料のPremiumまたはUltimateプランサブスクリプションがあり、5人のユーザーがいます。
- グループBにはFreeティアサブスクリプションがあり、8人のユーザーがいますが、そのうち4人はグループAのメンバーです。
- グループBは、5人のユーザー制限を超えているため、読み取り専用状態です。
- 読み取り専用状態を削除するために、グループBを会社のサブスクリプションに転送します。
- あなたの会社は、グループAのメンバーではないグループBの4人のメンバーに対して、4つのシートの追加費用が発生します。

トップレベルネームスペースの一部ではないユーザーは、アクティブな状態を維持するために追加のシートが必要です。詳細については、[サブスクリプションのシートを購入](../subscriptions/manage_users_and_seats.md#buy-more-seats)を参照してください。

## 5人のユーザー制限を増やす {#increase-the-five-user-limit}

GitLab.comのFreeサブスクリプションティアでは、非公開の表示レベルのトップレベルグループの5人のユーザーの制限を増やすことはできません。

大規模なチームの場合は、有料のPremiumまたはUltimateプランにアップグレードする必要があります。これらのティアはユーザーを制限せず、チームの生産性を向上させるための機能がさらに多くあります。詳細については、[GitLab Self-Managedでサブスクリプションティアをアップグレードする](../subscriptions/manage_subscription.md#upgrade-subscription-tier)を参照してください。

アップグレードを決定する前に有料のティアを試すには、GitLab Ultimateプランの[トライアル](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com/ee/user/free_user_limit.html)を開始してください。

## グループネームスペース外の個人プロジェクトでメンバーを管理する {#manage-members-in-personal-projects-outside-a-group-namespace}

個人プロジェクトは、トップレベルグループのネームスペースに配置されていません。各個人プロジェクトのユーザーを管理できます。個人プロジェクトには、5人以上のユーザーを含めることができます。

次のことができるように、[個人プロジェクトをグループに移動](../tutorials/move_personal_project_to_group/_index.md)する必要があります:

- ユーザー数を5人以上に増やします。
- 有料ティアのサブスクリプション、追加のコンピューティング時間、またはストレージを購入します。
- グループで[GitLabの機能](https://about.gitlab.com/pricing/feature-comparison/)を使用します。
- GitLab Ultimateプランの[トライアル](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com/ee/user/free_user_limit.html)を開始します。
