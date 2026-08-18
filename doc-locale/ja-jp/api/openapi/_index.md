---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OpenAPI
description: "OpenAPI 3.0仕様を使用してGitLab REST APIを探索します"
---

GitLabは、[OpenAPI 3.0仕様](https://spec.openapis.org/oas/v3.0.3)（以前はSwaggerと呼ばれていました）を使用してREST APIをドキュメント化しています。これは、RESTful APIを記述するための標準的でプラットフォームに依存しない仕様です。APIコードは、REST APIの信頼できる唯一の情報源です。OpenAPI specは、APIコードから直接自動生成され、その実装と密接に結合されているため、ドキュメントは常に正確で最新の状態に保たれます。

GitLab APIの一般的な情報については、[GitLabを使用して拡張する](../_index.md)を参照してください。

## OpenAPI仕様ファイル {#openapi-specification-file}

raw OpenAPI 3.0仕様は、GitLabモノレポで入手できます:

- **ファイル:** [`doc/api/openapi/openapi_v3.yaml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/api/openapi/openapi_v3.yaml)
- **形式：** OpenAPI 3.0 (YAML)

> [!note]
> The OpenAPI 2.0仕様 (`openapi_v2.yaml`) は非推奨となり、更新は行われません。代わりに、OpenAPI 3.0仕様 (`openapi_v3.yaml`) を使用してください。

## 対話型REST APIドキュメント {#interactive-rest-api-documentation}

REST APIは、OpenAPI 3.0仕様を使用して完全にドキュメント化されています。[REST APIドキュメント](https://api.gitlab.com/ja-jp/rest/)で、すべてのエンドポイントを対話的に参照およびテストできます。

ドキュメントは、[スカラー](https://scalar.com/)（オープンソースのAPI参照ツール）を使用してレンダリングされます。これはGitLabのソースコードにあるOpenAPI specから自動的に生成されるため、常にAPIの現在の状態を反映しています。

### 認可認証情報を追加します {#add-authorization-credentials}

一部のエンドポイントには認証が必要です。GitLabは、HTTP BearerまたはOAuth 2.0認証情報による認証をサポートしています。

認可認証情報を追加するには:

1. [REST APIドキュメント](https://api.gitlab.com/ja-jp/rest/)にアクセスします。
1. 右側の**認証**パネルで、ドロップダウンリストから認証方法を選択します。
1. 認証情報を入力します:
   - `http`の場合は、[パーソナルアクセストークン](../../user/profile/personal_access_tokens.md)を入力します。
   - `oauth2`の場合は、GitLabをIdentity Providerとして認可フローを使用します。
1. **認証**を選択します。

セッション中は、認証情報が後続のすべてのリクエストに自動的に再利用されます。

### ライブリクエストを送信 {#send-a-live-request}

対話型リクエストツールを使用して、ライブリクエストをGitLabに送信します。

ライブリクエストを送信するには:

1. [REST APIドキュメント](https://api.gitlab.com/ja-jp/rest/)にアクセスします。
1. オペレーションを展開する。
1. **Test Request**を選択します。
1. 必須またはオプションのパラメータを入力します。
1. **送信**を選択します。

このツールは、`curl`コマンド、完全なリクエストURL、およびサーバー応答を表示します。
