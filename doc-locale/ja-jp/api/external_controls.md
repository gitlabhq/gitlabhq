---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 外部コントロールAPI
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

外部サービスを使用するチェックのステータスを設定するには、外部コントロールAPIを使用します。

外部コントロールは定期的なping機能で設定できます。pingが有効な場合（デフォルト）、GitLabはコントロールステータスを`pending`に12時間ごとに自動的にリセットします。pingが無効な場合、コントロールステータスはAPIコールによってのみ更新されます。

## 外部コントロールのステータスを設定する {#set-status-of-an-external-control}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13658)されました。

{{< /history >}}

指定された外部コントロールのステータスを設定します。この操作を使用して、コントロールが外部サービスによるチェックに合格したか失敗したかをGitLabに通知します。

前提条件

- セキュリティのため、HMAC、タイムスタンプ、およびNonceの認証を使用する必要があります。

```plaintext
PATCH /api/v4/projects/:id/compliance_external_controls/:external_control_id/status
```

HTTPヘッダー:

| ヘッダー                |  型   | 必須 | 説明                                                                                   |
| --------------------- | ------- | -------- | --------------------------------------------------------------------------------------------- |
| `X-Gitlab-Timestamp`  | 文字列  | はい      | 現在のUnixタイムスタンプ。                                                                       |
| `X-Gitlab-Nonce`      | 文字列  | はい      | リプレイ攻撃を防ぐためのランダムな文字列またはトークン。                                             |
| `X-Gitlab-Hmac-Sha256`| 文字列  | はい      | リクエストのHMAC-SHA256署名。                                                         |

HMAC-SHA256署名を計算するには:

1. これらの値を次の順序で連結します:
   - `X-Gitlab-Timestamp`
   - `X-Gitlab-Nonce`
   - リクエストの完全なパス
   - `status`属性の値を、`status=<status>`の形式で指定します。
1. 連結された文字列のHMAC-SHA256を、シークレットキーを使用して計算します。

サポートされている属性は以下のとおりです: 

| 属性                | 型    | 必須 | 説明                                                                                       |
| ------------------------ | ------- | -------- |---------------------------------------------------------------------------------------------------|
| `id`                     | 整数 | はい      | プロジェクトのID。                                                                                  |
| `external_control_id`    | 整数 | はい      | 外部コントロールのID。                                                                        |
| `status`                 | 文字列  | はい      | コントロールを合格としてマークするには`pass`、失敗としてマークするには`fail`に設定します。                                |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性                | 型     | 説明                                   |
|--------------------------|----------|-----------------------------------------------|
| `status`                 | 文字列   | コントロールに設定されたステータス。 |

リクエスト例: 

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "X-Gitlab-Timestamp: <X-Gitlab-Timestamp>" \
  --header "X-Gitlab-Nonce: <X-Gitlab-Nonce>" \
  --header "X-Gitlab-Hmac-Sha256: <X-Gitlab-Hmac-Sha256>" \
  --header "Content-Type: application/json" \
  --data '{"status": "pass"}' \
  --url "https://gitlab.example.com/api/v4/projects/<id>/compliance_external_controls/<external_control_id>/status"
```

レスポンス例: 

```json
{
    "status":"pass"
}
```

## 関連トピック {#related-topics}

- [コンプライアンスフレームワーク](../user/compliance/compliance_frameworks/_index.md)
