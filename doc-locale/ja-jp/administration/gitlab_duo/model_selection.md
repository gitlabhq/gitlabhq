---
stage: AI Platform
group: AI Model Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo機能の大規模言語モデルを設定する。
title: モデル選択
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

すべてのGitLab Duo機能には、GitLabが選択したデフォルトの大規模言語モデル（LLM）があります。

GitLabは、機能のパフォーマンスを最適化するために、このデフォルトモデルを更新できます。そのため、ユーザーが何も操作しなくても、機能のモデルが変更される場合があります。

各機能にデフォルトモデルを使用しない場合、または特定の要件がある場合は、利用可能な他のサポート対象のモデルの配列から選択できます。

機能に特定のモデルを選択した場合、別のモデルを選択するまで、その機能はそのモデルを使用します。

## インスタンスのモデルを選択する {#select-a-model-for-the-instance}

{{< history >}}

- GitLab 18.4で`instance_level_model_selection`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/19144)されました。デフォルトでは有効になっています。
- GitLab 18.5のGitLab Dedicatedに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208017)されました。
- 機能フラグ`instance_level_model_selection`は、GitLab 18.6で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209698)されました。
- GitLab 18.6でGitLab Duo CoreおよびProを含めるように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210969)されました。

{{< /history >}}

特定機能のデフォルトモデルを選択でき、そのデフォルトはインスタンス全体に適用されます。特定のモデルを選択しない場合、すべてのGitLab Duo機能はデフォルトのGitLabモデルを使用します。

> [!note]
> GitLab Self-Managedインスタンスでオフラインライセンスをお持ちの場合、GitLab Duo Agent Platformの機能のモデルを変更するには、[GitLab Duo Agent Platform Self-Hosted](../../subscriptions/subscription-add-ons.md)アドオンが必要です。

前提条件: 

- 管理者である必要があります。

機能のモデルを選択するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **AI機能の設定**で、**GitLab Duoのモデルを設定する**を選択します。**AI機能の設定**が表示されない場合は、GitLab Duo Enterpriseアドオンがインスタンスに設定されていることを確認してください。
1. 設定したい機能について、ドロップダウンリストからデフォルトとして設定するモデルを選択します。
1. オプション。セクション内のすべての機能にモデルを適用するには、**すべてに適用**を選択します。

### Agentic Chatのモデルを選択する {#select-a-model-for-agentic-chat}

{{< history >}}

- GitLab 19.1で、GitLab Duo Agentic Chatで使用できるモデルを特定のモデルに制限する機能が[追加](https://gitlab.com/groups/gitlab-org/-/work_items/22028)されました。

{{< /history >}}

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **Configure AI features**で、**GitLab Duo Agentic Chat**セクションに移動します。
1. ドロップダウンリストからモデルを選択し、デフォルトモデルとして設定します。他のモデルへのアクセスを制限する予定がある場合は、GitLab管理のモデルをデフォルトとして選択します。
1. オプション。Agentic Chatでユーザーが選択できるその他のモデルを制限するには:

   1. **利用可能なモデル**の下で、**設定**を選択します。
   1. **利用可能なモデル: Agentic Chat**ダイアログで、**特定のモデルに制限**チェックボックスをオンにします。
   1. Agentic Chatで使用できるようにするモデルを選択します。
   1. **保存**を選択します。

   > [!note]
   > Agentic Chatを特定のモデルに制限するには、GitLab管理のモデルをデフォルトのモデルとして選択する必要があります。Agentic Chatを特定のモデルに制限しない場合、ユーザーはすべてのGitLab管理のモデルから選択できます。
