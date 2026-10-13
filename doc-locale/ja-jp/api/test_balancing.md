---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: テストバランシングAPI
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 19.4で`parallel_test_balancing`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/607450)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

このAPIを使用して、テスト時間を基に[`parallel:`](../ci/yaml/_index.md#parallel) CI/CDジョブのノード全体にテストを分散させ、すべてのノードがほぼ同時に完了するようにします。

テスト分割は、ノード全体に分散される作業単位です。ファイルで分割する場合、各テスト分割はテストファイルです。ノードは、静的テスト分割を共有の保留中プールにシードし、完了するたびに、実行時間の予算に基づいてテスト分割のバッチを繰り返しリクエストします。高速なノードほど多くの作業を吸収します。ノードが再試行されると、元々割り当てられたテスト分割の正確なセットを受け取ります。

両方のエンドポイント:

- 実行中の並列ジョブから呼び出す必要があり、[CI/CDジョブトークン](../ci/jobs/ci_job_token.md)（`CI_JOB_TOKEN`）で認証されている必要があります。
- 呼び出し元ジョブが`parallel:`キーワードを使用しない場合、`422 Unprocessable Entity`が返されます。
- パイプライン作成から30日以上前に作成されたパイプラインの場合、`422 Unprocessable Entity`が返されます。これは、テストバランシングデータ（再試行を含む）がパイプライン作成から30日間保持されるためです。

## 並列ジョブのテストバランシングを初期化する {#initialize-test-balancing-for-a-parallel-job}

呼び出し元の静的テスト分割をジョブグループの共有保留プールにシードし、最初のテスト分割のバッチを取得します。ノードがすでにテスト分割を要求している場合（たとえば、ジョブが再試行された場合やクラッシュから回復した場合）、以前に要求されたテストセットは変更されずに返され、`test_splits`パラメータは無視されます。

このエンドポイントは、シードによってジョブグループの共有プール内のテスト分割数が50,000を超える場合、`422 Unprocessable Entity`を返します。

```plaintext
POST /job/test_balancing/initialize
```

サポートされている属性は以下のとおりです: 

| 属性                         | タイプ            | 必須 | 説明 |
|-----------------------------------|-----------------|----------|-------------|
| `test_splits`                     | ハッシュの配列 | はい      | このノードに割り当てられた静的分割のテスト分割。最大1,000エントリ。 |
| `test_splits[].path`              | 文字列          | はい      | リポジトリのルートからの相対パスでのテスト分割のパス。最大1024文字。 |
| `test_splits[].expected_duration` | 浮動小数点数           | いいえ       | テスト分割の予想される期間（秒単位）。指定されていない場合、デフォルトは300です。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                         | タイプ   | 説明 |
|-----------------------------------|--------|-------------|
| `mode`                            | 文字列 | プールがシードされ、最初のバッチが取得された場合は`seed`、以前に取得されたテストセットが再実行された場合は`retry`。 |
| `test_splits`                     | 配列  | ノードが実行すべきテスト分割。`retry`の場合、完全な元のテストセット。 |
| `test_splits[].path`              | 文字列 | リポジトリのルートからの相対パスでのテスト分割のパス。 |
| `test_splits[].expected_duration` | 浮動小数点数  | シード時の予想される期間（秒単位）。指定されていない場合、デフォルトは300です。 |

リクエスト例: 

```shell
curl --request POST \
  --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"test_splits": [{"path": "spec/models/user_spec.rb", "expected_duration": 12.5}]}' \
  --url "https://gitlab.example.com/api/v4/job/test_balancing/initialize"
```

レスポンス例: 

```json
{
  "mode": "seed",
  "test_splits": [
    {
      "path": "spec/models/user_spec.rb",
      "expected_duration": 12.5
    }
  ]
}
```

## 次のテストバッチをリクエストする {#request-the-next-batch-of-tests}

呼び出し元ノードのために、保留中のテスト分割の時間予算付きバッチをアトミックに要求します（最も遅いものから優先）。空の`test_splits`配列は、キューが空になり、ノードがバッチのリクエストを停止すべきであることを意味します。

サーバーは、共有プール内の残りの予想される期間の合計に基づいて、バッチサイズを自動的に選択します。大量の期間が残っている場合、サーバーはリクエスト数を減らすためにより大きなバッチを返します。プールが枯渇するにつれて、サーバーはノード間で作業のバランスが保たれるようにより小さなバッチを返します。

```plaintext
POST /job/test_balancing/request
```

このエンドポイントは属性を受け取りません。

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                         | タイプ   | 説明 |
|-----------------------------------|--------|-------------|
| `test_splits`                     | 配列  | ノードが実行すべきテスト分割。キューが空の場合、空。 |
| `test_splits[].path`              | 文字列 | リポジトリのルートからの相対パスでのテスト分割のパス。 |
| `test_splits[].expected_duration` | 浮動小数点数  | シード時の予想される期間（秒単位）。指定されていない場合、デフォルトは300です。 |

リクエスト例: 

```shell
curl --request POST \
  --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  --url "https://gitlab.example.com/api/v4/job/test_balancing/request"
```

レスポンス例: 

```json
{
  "test_splits": [
    {
      "path": "spec/features/login_spec.rb",
      "expected_duration": 210.4
    }
  ]
}
```
