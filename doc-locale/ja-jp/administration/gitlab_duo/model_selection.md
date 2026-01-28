---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duo機能の大規模言語モデルを設定する。
title: モデル選択
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Core、Pro、またはEnterprise
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

すべてのGitLab Duo機能には、GitLabが選択したデフォルトの大規模言語モデル（LLM）があります。

GitLabは、機能のパフォーマンスを最適化するために、このデフォルトモデルを更新できます。そのため、お客様が何も操作しなくても、機能のモデルが変更される場合があります。

各機能にデフォルトモデルを使用しない場合、または特定の要件がある場合は、サポートされている利用可能な他のモデルを配列から選択できます。

機能に特定のモデルを選択した場合、別のモデルを選択するまで、その機能はそのモデルを使用します。

## インスタンスのモデルを選択する {#select-a-model-for-the-instance}

{{< history >}}

- GitLab 18.4で`instance_level_model_selection`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/19144)されました。デフォルトでは有効になっています。
- GitLab 18.5のGitLab Dedicatedに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208017)されました。
- 機能フラグ`instance_level_model_selection`は、GitLab 18.6で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209698)されました。
- GitLab 18.6でGitLab Duo CoreおよびProを含めるように[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210969)されました。

{{< /history >}}

インスタンス全体に適用される機能のモデルを選択できます。特定のモデルを選択しない場合、すべてのGitLab Duo機能はデフォルトのGitLabモデルを使用します。

前提条件: 

- 管理者である必要があります。

機能のモデルを選択するには:

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**GitLab Duo**を選択します。
1. **AI機能の設定**で、**GitLab Duoのモデルを設定する**を選択します。**AI機能の設定**が表示されない場合は、GitLab Duo Enterpriseアドオンがインスタンスに設定されていることを確認してください。
1. 設定する機能で、ドロップダウンリストからモデルを選択します。
1. オプション。セクション内のすべての機能にモデルを適用するには、**すべてに適用**を選択します。
