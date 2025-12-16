---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Asana
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.3でV1 Asana URL形式のサポートが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/523692)されました。

{{< /history >}}

Asanaインテグレーションにより、コミットメッセージがAsanaタスクへのコメントとして追加されます。有効にすると、コミットメッセージでAsanaタスクのURL（`https://app.asana.com/1/12345/project/67890/task/987654`など）または`#`で始まるタスクID（`#987654`など）が確認されます。見つかったすべてのタスクIDに、コミットコメントが追加されます。

メッセージ`fix #123456`を含めることで、タスクをクローズすることもできます。次のいずれかの単語を使用できます:

- `fix`
- `fixed`
- `fixes`
- `fixing`
- `close`
- `closes`
- `closed`
- `closing`

[AsanaインテグレーションAPIドキュメント](../../../api/project_integrations.md#asana)も参照してください。

## セットアップ {#setup}

Asanaで、パーソナルアクセストークンを作成します。[Asanaのパーソナルアクセストークンについて](https://developers.asana.com/docs/personal-access-token)。

GitLabで次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Asana**を選択します。
1. **有効**トグルが有効になっていることを確認します。
1. Asanaで生成したトークンを貼り付けます。
1. オプション。この設定を特定のブランチに制限するには、コンマで区切って**Restrict to branch**フィールドにリストします。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。
