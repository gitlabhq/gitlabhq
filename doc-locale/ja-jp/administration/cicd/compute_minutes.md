---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: 計算、割り当て、購入情報
title: コンピューティング時間管理
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.1で「CI/CD時間」から「コンピューティングクォータ」または「コンピューティング時間」に[名前が変更](https://gitlab.com/groups/gitlab-com/-/epics/2150)されました。

{{< /history >}}

管理者は、プロジェクトがジョブを[インスタンスRunner](../../ci/runners/runners_scope.md)で実行するために使用できる時間を、月ごとに制限できます。この制限は、[compute minutes quota](../../ci/pipelines/compute_minutes.md)で追跡されます。グループとプロジェクトRunnerは、コンピューティング割り当ての対象ではありません。

GitLab Self-Managedの場合: 

- コンピューティングクォータはデフォルトで無効になっています。
- 管理者は、ネームスペースが毎月のクォータをすべて使用した場合、[さらに割り当てコンピューティング時間](#set-the-compute-quota-for-a-group)を割り当てることができます。
- [コストファクター](../../ci/pipelines/compute_minutes.md#compute-usage-calculation)は、すべてのプロジェクトで`1`です。

GitLab.comの場合: 

- 適用されるクォータとコストファクターについては、[コンピューティング時間](../../ci/pipelines/compute_minutes.md)を参照してください。
- GitLabチームのメンバーとしてコンピューティング時間を管理するには、[GitLab.comのコンピューティング時間管理](dot_com_compute_minutes.md)を参照してください。

[トリガージョブ](../../ci/yaml/_index.md#trigger)はRunner上で実行されないため、[`strategy:depend`](../../ci/yaml/_index.md#triggerstrategy)を使用して[ダウンストリームパイプライン](../../ci/pipelines/downstream_pipelines.md)のステータスを待機する場合でも、コンピューティング時間は消費されません。トリガーされたダウンストリームパイプラインは、他のパイプラインと同じようにコンピューティング時間を消費します。

## すべてのネームスペースにコンピューティングクォータを設定する {#set-the-compute-quota-for-all-namespaces}

デフォルトでは、GitLabインスタンスにコンピューティングクォータはありません。クォータのデフォルト値は`0`で、これは無制限です。

前提要件: 

- GitLab管理者である必要があります。

すべてのネームスペースに適用されるデフォルトクォータを変更するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **CI/CD**を選択します。
1. **継続的インテグレーションとデプロイ**を展開します。
1. **コンピューティングクォータ**ボックスに制限を入力します。
1. **変更を保存**を選択します。

特定のネームスペースにクォータがすでに定義されている場合、この値はそのクォータを変更しません。

## グループのコンピューティングクォータを設定する {#set-the-compute-quota-for-a-group}

グローバル値をオーバーライドして、グループのコンピューティングクォータを設定できます。

前提要件: 

- GitLab管理者である必要があります。
- グループはトップレベルグループである必要があり、サブグループであってはなりません。

グループまたはネームスペースのコンピューティングクォータを設定するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **グループ**を選択します。
1. 更新するグループで、**編集**を選択します。
1. **コンピューティングクォータ**ボックスに、コンピューティング時間の最大数を入力します。
1. **変更を保存**を選択します。

代わりに、[グループの更新](../../api/groups.md#update-group-attributes)または[ユーザーの更新](../../api/users.md#modify-a-user)を使用することもできます。

## コンピューティング使用量をリセット {#reset-compute-usage}

管理者は、当月のネームスペースのコンピューティング使用量をリセットできます。

### 個人ネームスペースの使用量をリセット {#reset-usage-for-a-personal-namespace}

1. [**管理者**エリア](../admin_area.md#administering-users)でユーザーを見つけます。
1. **編集**を選択します。
1. **制限**で、**コンピューティングの使用状況をリセットする**を選択します。

### グループネームスペースの使用量をリセット {#reset-usage-for-a-group-namespace}

1. [**管理者**エリア](../admin_area.md#administering-groups)でグループを見つけます。
1. **編集**を選択します。
1. **権限とグループ機能**で、**コンピューティングの使用状況をリセットする**を選択します。
