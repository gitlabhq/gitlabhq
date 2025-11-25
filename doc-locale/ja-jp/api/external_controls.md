---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部コントロールAPI
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

外部コントロールAPIを使用して、外部サービスを使用するチェックのステータスを設定します。

定期的なping機能を使用して外部コントロールを設定できます。Pingが有効になっている場合（デフォルト）、GitLabはコントロールステータスを12時間ごとに自動的に`pending`にリセットします。Pingが無効になっている場合、コントロールステータスはAPIコールでのみ更新されます。

## 外部コントロールのステータスを設定 {#set-status-of-an-external-control}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13658)されました。

{{< /history >}}

単一の外部コントロールの場合、APIを使用して、コントロールが外部サービスによるチェックに合格または失敗したことをGitLabに通知します。

### 認証 {#authentication}

外部コントロールAPIには、セキュリティのためにHMAC、タイムスタンプ、およびナンス認証が必要です。

### エンドポイント {#endpoint}

```plaintext
PATCH /api/v4/projects/:id/compliance_external_controls/:external_control_id/status
```

HTTPヘッダー:

| ヘッダー                |  型   | 必須 | 説明                                                                                   |
| --------------------- | ------- | -------- | --------------------------------------------------------------------------------------------- |
| `X-Gitlab-Timestamp`  | 文字列  | はい      | 現在のUnixタイムスタンプ。                                                                       |
| `X-Gitlab-Nonce`      | 文字列  | はい      | リプレイ攻撃を防ぐためのランダムな文字列またはトークン。                                             |
| `X-Gitlab-Hmac-Sha256`| 文字列  | はい      | リクエストのHMAC-SHA256署名。                                                         |

サポートされている属性は以下のとおりです:

| 属性                | 型    | 必須 | 説明                                                                                       |
| ------------------------ | ------- | -------- |---------------------------------------------------------------------------------------------------|
| `id`                     | 整数 | はい      | プロジェクトのID。                                                                                  |
| `external_control_id`    | 整数 | はい      | 外部コントロールのID。                                                                        |
| `status`                 | 文字列  | はい      | コントロールを合格としてマークするには`pass`に設定し、失敗させるには`fail`に設定します。                                |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性                | 型     | 説明                                   |
|--------------------------|----------|-----------------------------------------------|
| `status`                 | 文字列   | コントロールに設定されているステータス。 |

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
