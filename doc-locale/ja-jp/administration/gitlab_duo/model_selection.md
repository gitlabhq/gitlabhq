---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLab Duo機能の大規模言語モデルを設定します。
title: モデルの選択
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo Enterprise
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

すべてのGitLab Duo機能には、GitLabによって選択された、事前選択済みのデフォルトの大規模言語モデル（LLM）があります。

GitLabは、機能のパフォーマンスを最適化するために、このデフォルトのLLMを更新できます。したがって、機能のLLMは、ユーザーが何も操作しなくても変更される可能性があります。

各機能にデフォルトのLLMを使用したくない場合、または特定の要件がある場合は、利用可能な他のサポートされているLLMの配列から選択できます。

機能に特定のLLMを選択した場合、別のLLMを選択するまで、その機能はそのLLMを使用します。

## インスタンスのモデルを選択 {#select-a-model-for-the-instance}

{{< history >}}

- `instance_level_model_selection`という名前の[フラグ](../../administration/feature_flags/_index.md)がGitLab 18.4で[導入](https://gitlab.com/groups/gitlab-org/-/epics/19144)されました。デフォルトでは有効になっています。
- [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208017) GitLab 18.5のGitLab Dedicatedへ。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

GitLab Self-Managedでは、インスタンス全体に適用される機能のモデルを選択できます。特定のモデルを選択しない場合、すべてのGitLab Duo機能はデフォルトのGitLabモデルを継承します。

前提要件: 

- 管理者である必要があります。

機能のモデルを選択するには:

1. 左側のサイドバーの下部にある**管理者**を選択します。
1. **GitLab Duo**を選択します。
1. **AI機能の設定**で、**GitLab Duoのモデルを設定する**を選択します。**AI機能の設定**が表示されない場合は、GitLab Duo Enterpriseアドオンがインスタンス用に構成されていることを確認してください。
1. 構成する機能について、ドロップダウンリストからLLMを選択します。
