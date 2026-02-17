---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アテステーションAPI
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.5で`slsa_provenance_statement`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/547865)されました。デフォルトでは無効になっています。

{{< /history >}}

> [!flag] この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

このAPIを使用して、[provenanceアテステーション](../ci/pipeline_security/slsa/provenance_v1.md)を操作します。

## Provenanceアテステーション {#provenance-attestations}

一部のエンドポイントは、レスポンスの一部として[Sigstoreバンドル](https://docs.sigstore.dev/about/bundle/)を返します。これらは、[glab](https://docs.gitlab.com/cli/)または[cosign](https://github.com/sigstore/cosign)を使用して検証できます。Provenanceの詳細については、[SLSA provenance仕様](../ci/pipeline_security/slsa/provenance_v1.md)を参照してください

## すべてのアテステーションをリスト表示 {#list-all-attestations}

{{< history >}}

- 18.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205784)。

{{< /history >}}

特定のプロジェクトとSHA-256ハッシュのすべてのアテステーションのリストを取得します。

```plaintext
GET /:id/attestations/:subject_digest
```

サポートされている属性: 

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `subject_digest` | 文字列 | はい | アーティファクトの16進エンコードされたSHA-256ハッシュ |

リクエスト例: 

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects/namespace%2fproject/attestations/5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa"
```

レスポンス例:

```json
[
  {
    "id": 1,
    "iid": 1,
    "created_at": "2025-10-07T20:59:27.085Z",
    "updated_at": "2025-10-07T20:59:27.085Z",
    "expire_at": "2027-10-07T20:59:26.967Z",
    "project_id": 1,
    "build_id": 1,
    "status": "success",
    "predicate_kind": "provenance",
    "predicate_type": "https://slsa.dev/provenance/v1",
    "subject_digest": "76c34666f719ef14bd2b124a7db51e9c05e4db2e12a84800296d559064eebe2c",
    "download_url": "https://gitlab.example.com/api/v4/projects/1/attestations/1/download"
  }
]
```

## アテステーションをダウンロード {#download-attestation}

{{< history >}}

- 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212141)。

{{< /history >}}

プロジェクトおよびアテステーションIIDで特定のprovenance Sigstoreバンドルをダウンロードします。バンドル自体は、レスポンス本文で返されます。このファイル形式の詳細については、関連する[Sigstoreドキュメント](https://docs.sigstore.dev/about/bundle/)を参照してください

```plaintext
GET /:id/attestations/:attestation_iid/download
```

サポートされている属性: 

| 属性 | 型 | 必須 | 説明 |
| --------- | ---- | -------- | ----------- |
| `id` | 整数または文字列 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `attestation_iid` | 整数 | はい | リストアテステーションAPIエンドポイントによって返されるアテステーションのIID。 |

リクエスト例: 

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/projects/72356192/attestations/1/download
```

レスポンス例:

```json
{
  "mediaType": "application/vnd.dev.sigstore.bundle.v0.3+json",
  "verificationMaterial": {
    "certificate": {
      "rawBytes": "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"
    },
    "tlogEntries": [
[...]
```
