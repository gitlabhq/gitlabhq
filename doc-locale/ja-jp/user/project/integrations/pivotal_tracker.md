---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pivotal Tracker
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Pivotal Trackerインテグレーションは、Pivotal Trackerストーリーへのコメントとしてコミットメッセージを追加します。

有効にすると、コミットメッセージに、ハッシュ記号とストーリーIDが続く角かっこ（`[#555]`など）が含まれていないか確認されます。見つかったすべてのストーリーIDにコミットメッセージが追加されます。

次のメッセージを含むストーリーを閉じることもできます: `fix [#555]`。次の単語を使用できます:

- `fix`
- `fixed`
- `fixes`
- `complete`
- `completes`
- `completed`
- `finish`
- `finished`
- `finishes`
- `delivers`

Pivotal Tracker APIドキュメントの[ソースコミットエンドポイント](https://www.pivotaltracker.com/help/api/rest/v5#Source_Commits)の詳細をお読みください。

[Pivotal Tracker APIドキュメント](../../../api/project_integrations.md#pivotal-tracker)も参照してください。

## Pivotal Trackerを設定する {#set-up-pivotal-tracker}

Pivotal Trackerで、[APIトークンを作成](https://www.pivotaltracker.com/help/articles/api_token/)します。

GitLabで次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Pivotal Tracker**を選択します。
1. **有効**トグルが有効になっていることを確認します。
1. Pivotal Trackerで生成したトークンを貼り付けます。
1. オプション。この設定を特定のブランチに制限するには、カンマで区切って**Restrict to branch**（ブランチに制限）フィールドに入力します。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。
