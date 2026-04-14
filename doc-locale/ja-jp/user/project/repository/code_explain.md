---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ファイル内のコードを説明する
---

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: GitLab Duo ProまたはEnterprise、GitLab Duo with Amazon Q
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< collapsible title="モデル情報" >}}

- [デフォルトLLM](../../gitlab_duo/model_selection.md#default-models)
- Amazon QのLLM: Amazon Q Developer
- [セルフホストモデル対応のGitLab Duo](../../../administration/gitlab_duo_self_hosted/_index.md)で利用可能

{{< /collapsible >}}

{{< history >}}

- GitLab 16.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/429915)になりました。
- GitLab 17.6以降、GitLab Duoアドオンが必須になりました。
- GitLab 18.6で[デフォルトLLMが更新](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/issues/1541)され、Claude Sonnet 4.5になりした。

{{< /history >}}

他の人が作成したコードを理解するのに多くの時間を費やしている場合、またはなじみのない言語で書かれたコードを理解するのに苦労している場合は、GitLab Duoにコードの説明を依頼できます。

前提条件: 

- [実験](../../gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)的機能とベータ機能の設定が有効になっているグループに少なくとも1つ所属している必要があります。
- プロジェクトを表示するためのアクセス権が必要です。

ファイル内のコードを説明するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. コードを含むファイルを選択します。
1. 説明が必要な行を選択します。
1. 左側で、疑問符（{{< icon name="question" >}}）を選択します。表示するには、選択した最初の行までスクロールする必要がある場合があります。

   ![選択した行と、コードを説明するために使用できる疑問符のアイコンを示すファイルビュー。](img/explain_code_v17_1.png)

GitLab Duo Chatがコードを説明します。説明の生成には時間がかかる場合があります。

必要に応じて、説明の品質に関するフィードバックを提供できます。

大規模言語モデルが正しい結果を生成することを保証することはできません。説明は注意して使用してください。

次の場所でもコードを説明できます。

- [マージリクエスト](../merge_requests/changes.md#explain-code-in-a-merge-request)。
- [IDE](../../gitlab_duo_chat/examples.md#explain-selected-code)。
