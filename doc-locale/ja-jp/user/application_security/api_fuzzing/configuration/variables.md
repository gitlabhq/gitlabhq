---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 利用可能なCI/CD変数
---

| CI/CD変数                                                                               | 説明 |
|----------------------------------------------------------------------------------------------|-------------|
| `SECURE_ANALYZERS_PREFIX`                                                                    | アナライザーをダウンロードするDockerレジストリのベースアドレスを指定します。 |
| `FUZZAPI_VERSION`                                                                            | APIファジングコンテナのバージョンを指定します。`5`がデフォルトです。 |
| `FUZZAPI_IMAGE_SUFFIX`                                                                       | コンテナイメージのサフィックスを指定します。デフォルトはnoneです。 |
| `FUZZAPI_API_PORT`                                                                           | APIファジングエンジンが使用する通信ポート番号を指定します。`5500`がデフォルトです。GitLab 15.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/367734)されました。 |
| `FUZZAPI_TARGET_URL`                                                                         | APIテスト対象のベースURLです。 |
| `FUZZAPI_TARGET_CHECK_SKIP`                                                                  | ターゲットが利用可能になるのを待機しないようにします。GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/442699)されました。 |
| `FUZZAPI_TARGET_CHECK_STATUS_CODE`                                                           | ターゲットの可用性チェックで予期されるステータス<codeを提供します。提供されない場合、500以外のステータス<codeであれば受け入れられます。GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/442699)されました。 |
| [`FUZZAPI_PROFILE`](customizing_analyzer_settings.md#api-fuzzing-profiles)                   | テスト中に使用する設定プロファイル。`Quick-10`がデフォルトです。 |
| [`FUZZAPI_EXCLUDE_PATHS`](customizing_analyzer_settings.md#exclude-paths)                    | テストからAPI URLパスを除外する。 |
| [`FUZZAPI_EXCLUDE_URLS`](customizing_analyzer_settings.md#exclude-urls)                      | テストからAPI URLを除外する。 |
| [`FUZZAPI_EXCLUDE_PARAMETER_ENV`](customizing_analyzer_settings.md#exclude-parameters)       | 除外するパラメータを含むJSON文字列。 |
| [`FUZZAPI_EXCLUDE_PARAMETER_FILE`](customizing_analyzer_settings.md#exclude-parameters)      | 除外するパラメータを含むJSONファイルへのパス。 |
| [`FUZZAPI_OPENAPI`](enabling_the_analyzer.md#openapi-specification)                          | OpenAPIの仕様ファイルまたはURL。 |
| [`FUZZAPI_OPENAPI_RELAXED_VALIDATION`](enabling_the_analyzer.md#openapi-specification)       | ドキュメントの検証を緩和します。デフォルトでは無効になっています。 |
| [`FUZZAPI_OPENAPI_ALL_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)          | リクエストの生成時に、サポートされているすべてのメディアタイプを1つではなく使用します。テスト時間が長くなる原因となります。デフォルトでは無効になっています。 |
| [`FUZZAPI_OPENAPI_MEDIA_TYPES`](enabling_the_analyzer.md#openapi-specification)              | テストで受け入れられるコロン（`:`）で区切られたメディアタイプ。デフォルトでは無効になっています。 |
| [`FUZZAPI_HAR`](enabling_the_analyzer.md#http-archive-har)                                   | HTTPアーカイブ（HAR）ファイル。 |
| [`FUZZAPI_GRAPHQL`](enabling_the_analyzer.md#graphql-schema)                                 | GraphQLエンドポイントへのパス（例：`/api/graphql`）。GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352780)されました。 |
| [`FUZZAPI_GRAPHQL_SCHEMA`](enabling_the_analyzer.md#graphql-schema)                          | JSON形式のGraphQLのスキーマのURLまたはファイル名。GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352780)されました。 |
| [`FUZZAPI_POSTMAN_COLLECTION`](enabling_the_analyzer.md#postman-collection)                  | Postman Collectionファイル。 |
| [`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`](enabling_the_analyzer.md#postman-variables)         | Postman変数の値を抽出するJSONファイルへのパス。コンマ区切り（`,`）ファイルのサポートはGitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)されました。 |
| [`FUZZAPI_OVERRIDES_FILE`](customizing_analyzer_settings.md#overrides)                       | オーバーライドを含むJSONファイルへのパス。 |
| [`FUZZAPI_OVERRIDES_ENV`](customizing_analyzer_settings.md#overrides)                        | オーバーライドするヘッダーを含むJSON文字列。 |
| [`FUZZAPI_OVERRIDES_CMD`](customizing_analyzer_settings.md#overrides)                        | オーバーライドコマンド。 |
| [`FUZZAPI_OVERRIDES_CMD_VERBOSE`](customizing_analyzer_settings.md#overrides)                | 任意の値に設定した場合。ジョブの出力の一部として、オーバーライドコマンドの出力が表示されます。 |
| `FUZZAPI_PER_REQUEST_SCRIPT`                                                                 | リクエストごとのスクリプトのフルパスとファイル名。[例については、デモプロジェクトを参照してください。](https://gitlab.com/gitlab-org/security-products/demos/api-dast/auth-with-request-example)GitLab 17.2で[導入](https://gitlab.com/groups/gitlab-org/-/epics/13691)されました。 |
| `FUZZAPI_PRE_SCRIPT`                                                                         | スキャンセッションを開始する前に、ユーザーコマンドまたはスクリプトを実行します。パッケージのインストールなどの特権操作には、`sudo`を使用する必要があります。 |
| `FUZZAPI_POST_SCRIPT`                                                                        | スキャンセッションの終了後に、ユーザーコマンドまたはスクリプトを実行します。パッケージのインストールなどの特権操作には、`sudo`を使用する必要があります。 |
| [`FUZZAPI_OVERRIDES_INTERVAL`](customizing_analyzer_settings.md#overrides)                   | オーバーライドコマンドを何秒ごとに実行するか。デフォルトは`0`（1回）です。 |
| [`FUZZAPI_HTTP_USERNAME`](customizing_analyzer_settings.md#http-basic-authentication)        | HTTP認証のユーザー名。 |
| [`FUZZAPI_HTTP_PASSWORD`](customizing_analyzer_settings.md#http-basic-authentication)        | HTTP認証のパスワード。 |
| [`FUZZAPI_HTTP_PASSWORD_BASE64`](customizing_analyzer_settings.md#http-basic-authentication) | Base64でエンコードされたHTTP認証のパスワード。GitLab 15.4で[導入](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing-src/-/merge_requests/702)されました。 |
| `FUZZAPI_SUCCESS_STATUS_CODES`                                                               | APIファジングテストのスキャンジョブが成功したかどうかを判断する、コンマ区切り（`,`）のHTTP成功ステータス<codeのリストを指定します。GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/442219)されました。例: `'200, 201, 204'` |
