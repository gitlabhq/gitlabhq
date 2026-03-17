---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Freeプランのユーザーおよびグループ制限
---

{{< details >}}

- プラン: Free
- 提供形態: GitLab.com

{{< /details >}}

Freeプランをご利用の場合、以下のユーザーおよびグループ制限が適用されます。

## Freeユーザー制限 {#free-user-limit}

GitLab.comで新たに作成されたトップレベルグループのネームスペース（プライベート表示レベル）には、最大5人のユーザーを追加できます。

このネームスペースが2022年12月28日より前に作成された場合、このユーザー制限は2023年6月13日に適用されました。

5人を超えるユーザーがいるトップレベルグループのネームスペース（プライベート表示レベル）は、読み取り専用状態になります。これらのネームスペースは、以下のいずれにも新しいデータを書き込むことはできません:

- リポジトリ
- Git Large File Storage（LFS）
- パッケージ
- レジストリ。

読み取り専用ネームスペースで制限されるアクションの全リストについては、[read-only namespaces](read_only_namespaces.md)を参照してください。

Freeプランのユーザーには、ユーザー制限は適用されません:

- GitLab.comの場合:
  - 公開トップレベルグループ
  - パーソナルネームスペース（デフォルトで公開されているため）
  - 有料プラン
  - 以下の[コミュニティプログラム](https://about.gitlab.com/community/):
    - オープンソース団体向けGitLab
    - 教育団体向けGitLab
    - スタートアップ向けGitLab
- [GitLab Self-Managedサブスクリプション](../subscriptions/manage_subscription.md)

詳細については、[専門家にご相談](https://page.gitlab.com/usage_limits_help.html)ください。

## トップレベルグループ制限 {#top-level-group-limits}

2026年1月27日以降にFreeプランで作成されたアカウントは、3つのトップレベルグループ（グループネームスペース）に制限されます。あなたの[パーソナルネームスペース](namespace/_index.md#types-of-namespaces)は、この制限には含まれません。この制限は、Ultimateのトライアル中であるアカウントにも適用されます。

さらにグループを作成するには、有料プランにアップグレードしてください。

## ネームスペースのユーザー数を決定する {#determine-namespace-user-counts}

プライベート表示レベルのトップレベルグループネームスペースのすべてのユニークユーザーは、5人制限の対象となります。これには、ネームスペース内のグループ、サブグループ、およびプロジェクトのすべてのユーザーが含まれます。

たとえば、`example-1`と`example-2`の2つのグループがあります。

グループ`example-1`には以下が含まれます:

- 1人のグループオーナー、`A`。
- メンバーが1人のサブグループ`subgroup-1`（メンバーは`B`）。
  - `subgroup-1`は`example-1`からメンバーとして`A`を継承します。
- サブグループ`subgroup-1`には、メンバーが2人のプロジェクト`project-1`（メンバーは`C`と`D`）があります。
  - `project-1`は`subgroup-1`からメンバーとして`A`と`B`を継承します。

ネームスペース`example-1`には、`A`、`B`、`C`、`D`の4人のユニークなメンバーがいるため、5人制限を超えていません。

グループ`example-2`には以下が含まれます:

- 1人のグループオーナー、`A`。
- メンバーが1人のサブグループ`subgroup-2`（メンバーは`B`）。
  - `subgroup-2`は`example-2`からメンバーとして`A`を継承します。
- サブグループ`subgroup-2`には、メンバーが2人のプロジェクト`project-2a`（メンバーは`C`と`D`）があります。
  - `project-2a`は`subgroup-2`からメンバーとして`A`と`B`を継承します。
- サブグループ`subgroup-2`には、メンバーが2人のプロジェクト`project-2b`（メンバーは`E`と`F`）があります。
  - `project-2b`は`subgroup-2`からメンバーとして`A`と`B`を継承します。

ネームスペース`example-2`には、`A`、`B`、`C`、`D`、`E`、`F`の6人のユニークなメンバーがいるため、5人制限を超えています。

## グループネームスペースのメンバーを管理する {#manage-members-in-your-group-namespace}

Freeのユーザー制限を管理するために、ネームスペース内のすべてのプロジェクトとグループのメンバーの総数を表示および管理できます。

前提条件: 

- グループのオーナーロールが必要です。

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **使用量クォータ**を選択します。
1. 全てのメンバーを表示するには、**シート**タブを選択してください。

このページでは、ネームスペース内のすべてのメンバーを表示および管理できます。たとえば、メンバーを削除するには、**ユーザーを削除**を選択します。

## 組織のサブスクリプションにグループを含める {#include-a-group-in-an-organizations-subscription}

組織内に複数のグループがある場合、有料（PremiumまたはUltimateプラン）およびFreeプランのサブスクリプションの組み合わせになっている場合があります。Freeプランのサブスクリプションを持つグループがユーザー制限を超えると、そのネームスペースは[read-only](read_only_namespaces.md)になります。

Freeプランのサブスクリプションを持つグループのユーザー制限を解除するには、それらのグループを組織のサブスクリプションに含めます:

1. グループがサブスクリプションに含まれているか確認するには、[そのグループのサブスクリプション詳細を表示](../subscriptions/manage_subscription.md#view-subscription)してください。

   そのグループがFreeプランのサブスクリプションを持っている場合、それは組織のサブスクリプションに含まれていません。

1. 有料のPremiumまたはUltimateプランのサブスクリプションにグループを含めるには、そのグループを[組織のトップレベルネームスペースに移行](group/manage.md#transfer-a-group)してください。

有料のPremiumまたはUltimateプランのサブスクリプションをお持ちの場合でも、グループに5人制限が適用されている場合は、[サブスクリプション](../subscriptions/manage_subscription.md#link-subscription-to-a-group)が以下のいずれかにリンクされていることを確認してください:

- 正しいトップレベルグループネームスペース。
- あなたの[GitLabカスタマーポータル](../subscriptions/billing_account.md)アカウント。

### 移行されたグループがサブスクリプションコストに与える影響 {#impact-of-transferred-groups-on-subscription-costs}

グループを組織のサブスクリプションに移行すると、シート数が増加する場合があります。これにより、サブスクリプションに追加費用が発生する可能性があります。

たとえば、あなたの会社にはグループAとグループBがあります:

- グループAは有料のPremiumまたはUltimateプランのサブスクリプションを持ち、5人のユーザーがいます。
- グループBはFreeプランのサブスクリプションを持ち、8人のユーザーがいますが、そのうち4人はグループAのメンバーです。
- グループBは5人制限を超えているため、読み取り専用状態です。
- 読み取り専用状態を解除するために、グループBを会社のサブスクリプションに移行します。
- あなたの会社は、グループAのメンバーではないグループBの4人のメンバーに対して、4シート分の追加費用を負担します。

トップレベルグループネームスペースの一部ではないユーザーは、アクティブな状態を維持するために追加のシートを必要とします。詳細については、[サブスクリプションのシートを購入する](../subscriptions/manage_users_and_seats.md#buy-more-seats)を参照してください。

## 5人制限を増やす {#increase-the-five-user-limit}

GitLab.comのFreeプランのサブスクリプションでは、プライベート表示レベルのトップレベルグループに対する5人のユーザー制限を増やすことはできません。

より大規模なチームの場合は、有料のPremiumまたはUltimateプランにアップグレードしてください。これらのプランはユーザーを制限せず、チームの生産性を向上させるためのより多くの機能を提供します。詳細については、[GitLab Self-Managedでサブスクリプションプランをアップグレード](../subscriptions/manage_subscription.md#upgrade-subscription-tier)を参照してください。

アップグレードを決定する前に有料プランを試すには、GitLab Ultimateの[無料トライアル](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com/user/free_user_limit/)を開始してください。

## グループネームスペース外のパーソナルプロジェクトでメンバーを管理する {#manage-members-in-personal-projects-outside-a-group-namespace}

パーソナルプロジェクトはトップレベルグループネームスペースにはありません。各パーソナルプロジェクトのユーザーを管理できます。パーソナルプロジェクトには5人以上のユーザーを配置できます。

次のことができるように、[パーソナルプロジェクトをグループに移動](../tutorials/move_personal_project_to_group/_index.md)する必要があります:

- ユーザー数を5人より多くする。
- 有料プランのサブスクリプション、追加のコンピューティング時間、またはストレージを購入する。
- グループ内で[GitLabの機能](https://about.gitlab.com/pricing/feature-comparison/)を使用する。
- GitLab Ultimateの[無料トライアル](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com/user/free_user_limit/)を開始する。
