---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプライン作成時のレート制限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 15.0で`ci_enforce_throttle_pipelines_creation`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/362475)されました。デフォルトでは無効になっています。GitLab.comで有効になりました。
- 18.3ではデフォルトで[有効になっています](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196545)。

{{< /history >}}

ユーザーとプロセスが1分あたりにリクエストできるパイプライン数を制限できます。この制限は、リソースの節約と安定性の向上に役立ちます。

たとえば、制限を`10`に設定し、1分以内に[trigger API](../../ci/triggers/_index.md)に`11`件のリクエストが送信された場合、11件目のリクエストはブロックされます。エンドポイントへのアクセスは、1分後に再び許可されます。

この制限は次のとおりです:

- プロジェクト、コミット、ユーザーの同じ組み合わせに対して作成されたパイプラインの数に適用されます。
- IPアドレスごとには適用されません。
- デフォルトでは無効になっています。

制限を超えたリクエストは、`application_json.log`ファイルにログが記録されます。

## パイプラインのリクエスト制限を設定する {#set-a-pipeline-request-limit}

パイプラインのリクエスト数を制限するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **ネットワーク**を選択します。
1. 展開**Pipelines Rate Limits**（パイプラインレート制限）。
1. **Max requests per minute**（1分あたりの最大リクエスト数）に、`0`より大きい値を入力します。
1. **変更を保存**を選択します。
