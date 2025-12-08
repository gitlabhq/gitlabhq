---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザーをモデレートする
---

オーナーロールがグループに割り当てられている場合、[承認](manage.md#user-cap-for-groups)、BAN、または休止中のメンバーを自動的に削除できます。

{{< alert type="note" >}}

このトピックは、グループ内のユーザーモデレーションに特に関連しています。GitLab Self-Managedに関連する情報については、[管理ドキュメント](../../administration/moderate_users.md)を参照してください。

{{< /alert >}}

## BANとBANの解除 {#ban-and-unban-users}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 15.8で`limit_unique_project_downloads_per_namespace_user`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/modelops/anti-abuse/team-tasks/-/issues/155)されました。デフォルトでは無効になっています。
- GitLab 15.6の[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/365724)で有効になりました。
- GitLab 18.0[で一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183101)になりました。機能フラグ`limit_unique_project_downloads_per_namespace_user`は削除されました。

{{< /history >}}

グループのオーナーは、ユーザーをBANおよびBANの解除することにより、ユーザーアクセスをモデレートできます。ユーザーをグループからブロックする場合は、そのユーザーをBANする必要があります。

BANされたユーザー:

- そのグループまたは任意のリポジトリにアクセスできません。
- [スラッシュコマンド](../project/integrations/gitlab_slack_application.md#slash-commands)を使用できません。
- [シート](../free_user_limit.md)を占有しません。

### ユーザーのBAN {#ban-a-user}

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>グループレベルでのユーザーのBANに関するデモについては、[ネームスペースレベルBAN - ユーザーのBAN](https://youtu.be/1rbi1uEJmOI)を参照してください。

前提要件: 

- 最上位トップレベルグループでオーナーロールを持っている必要があります。
- トップレベルグループで、BANするユーザーにオーナーロールがある場合は、[ユーザーを降格させる](manage.md#change-the-owner-of-a-group)必要があります。

ユーザーを手動でBANするには:

1. トップレベルグループに移動します。
1. 左側のサイドバーで、**管理** > **メンバー**を選択します。
1. BANするメンバーの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）を選択します。
1. ドロップダウンリストから、**メンバーをBAN**を選択します。

### ユーザーのBANの解除 {#unban-a-user}

GraphQL APIでユーザーのBANの解除を行うには、[`Mutation.namespaceBanDestroy`](../../api/graphql/reference/_index.md#mutationnamespacebandestroy)を参照してください。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>グループレベルでのユーザーのBANの解除に関するデモについては、[ネームスペースレベルBAN - ユーザーのBANの解除](https://www.youtube.com/watch?v=mTQVbP3MQrs)を参照してください。

前提要件: 

- 最上位トップレベルグループでオーナーロールを持っている必要があります。

ユーザーのBANの解除を行うには:

1. トップレベルグループに移動します。
1. 左側のサイドバーで、**管理** > **メンバー**を選択します。
1. **BAN**タブを選択します。
1. BANの解除するアカウントで、**BANの解除**を選択します。

## 休止中のメンバーを自動的に削除 {#automatically-remove-dormant-members}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 17.1で`group_remove_dormant_members`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/461339)されました。デフォルトでは無効になっています。
- GitLab 17.9で[ベータ](../../policy/development_stages_support.md#beta)機能として[リリース](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178851)されました。

{{< /history >}}

前提要件: 

- グループのオーナーロールを持っている必要があります。

指定された期間（デフォルトおよび最小は90日）グループ内でアクティビティーがないグループメンバーを自動的に削除できます。次のアクションはアクティビティーとしてカウントされます:

- `clone`や`push`など、Git HTTP/SSHイベントを介してプロジェクトを操作します。
- ダッシュボード、プロジェクト、イシュー、マージリクエスト、設定など、GitLabのページにアクセスします。
- グループのスコープでRESTまたはGraphQL APIを使用します。

休止中の[エンタープライズユーザー](../enterprise_user/_index.md)は削除されませんが、[非アクティブ化](../../administration/moderate_users.md#deactivate-and-reactivate-users)されます。これらのユーザーが再度サインインすると、アカウントが再度アクティブ化され、アクセスが復元されます。

{{< alert type="note" >}}

2025-01-22より前に追加されたメンバーのアクティビティーは記録されていません。これらのメンバーは、90日以上休止している場合でも、2025-04-22まで削除されません。

{{< /alert >}}

休止中のメンバーの自動削除をオンにするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. **権限とグループ機能**を展開します。
1. **休止中のメンバー**までスクロールします。
1. **非アクティブ日数の経過後に、休止中のメンバーを削除する**チェックボックスを選択します。
1. **削除前の非アクティブ日数**フィールドに、削除までの日数を入力します。最小値は90日、最大値は1827日（5年）です。
1. **変更を保存**を選択します。

メンバーが非アクティブ日数に達し、グループから削除された後:

- GitLab.comへのアクセス権は引き続きあります。
- そのグループへのアクセス権はありません。
- グループへのコントリビュートは、削除されたメンバーに割り当てられたままになります。
