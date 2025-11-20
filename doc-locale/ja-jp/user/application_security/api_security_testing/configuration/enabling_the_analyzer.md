---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アナライザーを有効にする
---

次の方法でAPIのスキャン対象を指定できます:

- [OpenAPI v2またはv3の仕様](#openapi-specification)
- [GraphQL Schema](#graphql-schema)
- [HTTP Archive (HAR)](#http-archive-har)
- [Postman Collection v2.0またはv2.1](#postman-collection)

## OpenAPI仕様 {#openapi-specification}

[OpenAPI仕様](https://www.openapis.org/)（以前のSwagger仕様）は、REST API用のAPI記述フォーマットです。このセクションでは、OpenAPI仕様を使用してAPIセキュリティテストスキャンを構成し、テスト対象のAPIに関する情報を提供する方法について説明します。OpenAPI仕様は、ファイルシステムのリソースまたはURLとして提供されます。JSONとYAMLのOpenAPI形式の両方がサポートされています。

APIセキュリティテストでは、OpenAPIドキュメントを使用してリクエスト本文を生成します。リクエスト本文が必要な場合、本文の生成は次の本文タイプに制限されます:

- `application/x-www-form-urlencoded`
- `multipart/form-data`
- `application/json`
- `application/xml`

## OpenAPIとメディアタイプ {#openapi-and-media-types}

メディアタイプ（以前はMIMEタイプとして知られていた）は、送信されるファイル形式と形式コンテンツの識別子です。OpenAPIドキュメントを使用すると、特定のオペレーションが異なるメディアタイプを受け入れることを指定できるため、特定のリクエストは異なるファイルコンテンツを使用してデータを送信できます。例として、ユーザーデータを更新する`PUT /user`オペレーションは、XML（メディアタイプ`application/xml`）またはJSON（メディアタイプ`application/json`）形式でデータを受け入れることができます。OpenAPI 2.xでは、グローバルまたはオペレーションごとに許可されるメディアタイプを指定でき、OpenAPI 3.xでは、オペレーションごとに許可されるメディアタイプを指定できます。APIセキュリティテストでは、リストされたメディアタイプをチェックし、サポートされている各メディアタイプのサンプルデータを生成しようとします。

- デフォルトの動作は、使用するサポートされているメディアタイプの1つを選択することです。最初にサポートされているメディアタイプがリストから選択されます。この動作は構成可能です。

異なるメディアタイプ（たとえば、`application/json`や`application/xml`）を使用して同じオペレーション（たとえば、`POST /user`）をテストすることは、必ずしも望ましいとは限りません。たとえば、ターゲットアプリケーションがリクエストコンテンツタイプに関係なく同じコードを実行する場合、テストセッションの完了に時間がかかり、ターゲットアプリに応じてリクエスト本文に関連する重複した脆弱性がレポートされる可能性があります。

環境変数`APISEC_OPENAPI_ALL_MEDIA_TYPES`を使用すると、特定のオペレーションのリクエストを生成するときに、サポートされているすべてのメディアタイプを1つではなく使用するかどうかを指定できます。環境変数`APISEC_OPENAPI_ALL_MEDIA_TYPES`が任意の値に設定されている場合、APIセキュリティテストは、特定の操作で、サポートされているすべてのメディアタイプのリクエストを1つではなく生成しようとします。これにより、提供された各メディアタイプに対してテストが繰り返されるため、テストに時間がかかるようになります。

または、変数`APISEC_OPENAPI_MEDIA_TYPES`を使用して、それぞれテストされるメディアタイプのリストを提供します。複数のメディアタイプを提供すると、選択した各メディアタイプに対してテストが実行されるため、テストに時間がかかるようになります。環境変数`APISEC_OPENAPI_MEDIA_TYPES`がメディアタイプのリストに設定されている場合、リクエストの作成時に、リストされたメディアタイプのみが含まれます。

`APISEC_OPENAPI_MEDIA_TYPES`内の複数のメディアタイプは、コロン（`:`）で区切られています。たとえば、リクエストの生成をメディアタイプ`application/x-www-form-urlencoded`と`multipart/form-data`に制限するには、環境変数`APISEC_OPENAPI_MEDIA_TYPES`を`application/x-www-form-urlencoded:multipart/form-data`に設定します。このリストでサポートされているメディアタイプのみがリクエストの作成時に含まれますが、サポートされていないメディアタイプは常にスキップされます。メディアタイプのテキストには、さまざまなセクションが含まれている場合があります。たとえば、`application/vnd.api+json; charset=UTF-8`は、`type "/" [tree "."] subtype ["+" suffix]* [";" parameter]`の複合です。リクエストの生成時にメディアタイプのフィルタリングを実行する場合、パラメータは考慮されません。

環境変数`APISEC_OPENAPI_ALL_MEDIA_TYPES`と`APISEC_OPENAPI_MEDIA_TYPES`を使用すると、メディアタイプの処理方法を決定できます。これらの設定は相互に排他的です。両方が有効になっている場合、APIセキュリティテストはエラーをレポートします。

### OpenAPI仕様を使用したAPIセキュリティテストの構成 {#configure-api-security-testing-with-an-openapi-specification}

OpenAPI仕様を使用してAPIセキュリティテストスキャンを構成するには、次の手順に従います:

1. [次のものを含めます](../../../../ci/yaml/_index.md#includetemplate) [`API-Security.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)あなたの`.gitlab-ci.yml`ファイル。

1. [設定ファイル](variables.md#configuration-files)には、さまざまなチェックが有効になっている複数のテストプロファイルが定義されています。`Quick`プロファイルから開始することをお勧めします。このプロファイルを使用したテストはより迅速に完了するため、構成の検証が容易になります。`APISEC_PROFILE` CI/CD変数を`.gitlab-ci.yml`ファイルに追加して、プロファイルを指定します。

1. OpenAPI仕様の場所をファイルまたはURLとして指定します。変数`APISEC_OPENAPI`を追加して場所を指定します。

1. ターゲットAPIインスタンスのベースURLも必要です。変数`APISEC_TARGET_URL`または`environment_url.txt`ファイルを使用して指定します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加すると、動的な環境でのテストに最適です。GitLab CI/CDパイプライン中に動的に作成されたアプリに対してAPIセキュリティテストを実行するには、`environment_url.txt`ファイルにURLを永続化させます。APIセキュリティテストは、そのファイルを自動的に解析中して、スキャンターゲットを見つけます。[AutoデブオプスCI YAMLの例](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)を参照してください。

OpenAPI仕様を使用した完全な構成例:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
```

これは、APIセキュリティテストの最小限の構成です。ここから、次のことができます:

- [最初のスキャンの実行](#running-your-first-scan)。
- [認証の追加](customizing_analyzer_settings.md#authentication)。
- [誤検出の処理](#handling-false-positives)の方法について説明します。

## HTTP Archive (HAR) {#http-archive-har}

[HTTP Archive format (HAR)](../../api_fuzzing/create_har_files.md)は、HTTPトランザクションをログに記録するためのアーカイブファイル形式です。GitLab APIセキュリティテストスキャナーで使用する場合、HARファイルには、テストするWeb APIを呼び出すレコードが含まれている必要があります。APIセキュリティテストスキャナーはすべてのリクエストを抽出し、それらを使用してテストを実行します。

HARファイルを生成するには、さまざまなツールを使用できます:

- [Insomnia Core](https://insomnia.rest/): APIクライアント
- [Chrome](https://www.google.com/chrome/): ブラウザ
- [Firefox](https://www.mozilla.org/en-US/firefox/): ブラウザ
- [Fiddler](https://www.telerik.com/fiddler): Webデバッグプロキシ
- [GitLab HAR Recorder](https://gitlab.com/gitlab-org/security-products/har-recorder): コマンドライン

{{< alert type="warning" >}}

HARファイルには、認証トークン、APIキー、セッションクッキーなどの機密情報が含まれている場合があります。リポジトリに追加する前に、HARファイルの内容をレビューすることをお勧めします。

{{< /alert >}}

### HARファイルを使用したAPIセキュリティテストスキャン {#api-security-testing-scanning-with-a-har-file}

APIセキュリティテストを構成して、テストするターゲットAPIに関する情報を提供するHARファイルを使用するには、次の手順を実行します:

1. [次のものを含めます](../../../../ci/yaml/_index.md#includetemplate) [`API-Security.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)あなたの`.gitlab-ci.yml`ファイル。

1. [設定ファイル](variables.md#configuration-files)には、さまざまなチェックが有効になっている複数のテストプロファイルが定義されています。`Quick`プロファイルから開始することをお勧めします。このプロファイルを使用したテストはより迅速に完了するため、構成の検証が容易になります。

   変数`APISEC_PROFILE`を`.gitlab-ci.yml`ファイルに追加してプロファイルを指定します。

1. HARファイルの場所を指定します。ファイルパスまたはURLとして場所を指定できます。変数`APISEC_HAR`を追加して場所を指定します。

1. ターゲットAPIインスタンスのベースURLも必要です。変数`APISEC_TARGET_URL`または`environment_url.txt`ファイルを使用して指定します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加すると、動的な環境でのテストに最適です。GitLab CI/CDパイプライン中に動的に作成されたアプリに対してAPIセキュリティテストを実行するには、`environment_url.txt`ファイルにURLを永続化させます。APIセキュリティテストは、そのファイルを自動的に解析中して、スキャンターゲットを見つけます。[AutoデブオプスCI YAMLの例](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)を参照してください。

HARファイルを使用した完全な構成例:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_HAR: test-api-recording.har
  APISEC_TARGET_URL: http://test-deployment/
```

この例は、APIセキュリティテストの最小限の構成です。ここから、次のことができます:

- [最初のスキャンの実行](#running-your-first-scan)。
- [認証の追加](customizing_analyzer_settings.md#authentication)。
- [誤検出の処理](#handling-false-positives)の方法について説明します。

## GraphQL Schema {#graphql-schema}

{{< history >}}

- GraphQLスキーマのサポートはGitLab 15.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/352780)。

{{< /history >}}

GraphQLは、APIのクエリ言語であり、従来のREST APIの代替手段です。APIセキュリティテストは、複数の方法でGraphQLエンドポイントのテストをサポートしています:

- GraphQLスキーマを使用したテスト。GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352780)されました。
- GraphQLクエリのレコーディング（HAR）を使用したテスト。
- GraphQLクエリを含むPostman Collectionを使用したテスト。

このセクションでは、GraphQLスキーマを使用したテストの方法について説明します。APIセキュリティテストのGraphQLスキーマのサポートにより、[イントロスペクション](https://graphql.org/learn/introspection/)をサポートするエンドポイントからスキーマをクエリできます。GraphiQLなどのツールが機能するように、イントロスペクションはデフォルトで有効になっています。イントロスペクションを有効にする方法の詳細については、GraphQLフレームワークのドキュメントを参照してください。

### GraphQLエンドポイントURLを使用したAPIセキュリティテストスキャン {#api-security-testing-scanning-with-a-graphql-endpoint-url}

APIセキュリティテストのGraphQLサポートにより、スキーマのGraphQLエンドポイントをクエリできます。

{{< alert type="note" >}}

GraphQLエンドポイントは、このメソッドが正しく機能するために、イントロスペクションクエリをサポートしている必要があります。

{{< /alert >}}

APIセキュリティテストを構成して、テストするターゲットAPIに関する情報を提供するGraphQLエンドポイントURLを使用するには、次の手順を実行します:

1. [次のものを含めます](../../../../ci/yaml/_index.md#includetemplate) [`API-Security.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)あなたの`.gitlab-ci.yml`ファイル。

1. `/api/graphql`などのGraphQLエンドポイントへのパスを指定します。変数`APISEC_GRAPHQL`を追加して、場所を指定します。

1. ターゲットAPIインスタンスのベースURLも必要です。変数`APISEC_TARGET_URL`または`environment_url.txt`ファイルを使用して指定します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加すると、動的な環境でのテストに最適です。詳細については、[動的環境ソリューション](../troubleshooting.md#dynamic-environment-solutions)セクションを参照してください。

GraphQLエンドポイントパスを使用した完全な構成例:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

api_security:
  variables:
    APISEC_GRAPHQL: /api/graphql
    APISEC_TARGET_URL: http://test-deployment/
```

この例は、APIセキュリティテストの最小限の構成です。ここから、次のことができます:

- [最初のスキャンの実行](#running-your-first-scan)。
- [認証の追加](customizing_analyzer_settings.md#authentication)。
- [誤検出の処理](#handling-false-positives)の方法について説明します。

### GraphQLスキーマファイルを使用したAPIセキュリティテストスキャン {#api-security-testing-scanning-with-a-graphql-schema-file}

APIセキュリティテストでは、GraphQLスキーマファイルを使用して、イントロスペクションが無効になっているGraphQLエンドポイントを理解し、テストできます。GraphQLスキーマファイルを使用するには、イントロスペクションJSON形式である必要があります。GraphQLスキーマは、オンラインのサードパーティツールを使用して、イントロスペクションJSON形式に変換できます。[https://transform.tools/graphql-to-introspection-json](https://transform.tools/graphql-to-introspection-json)。

APIセキュリティテストを構成して、テストするターゲットAPIに関する情報を提供するGraphQLスキーマファイルを使用するには、次の手順を実行します:

1. [次のものを含めます](../../../../ci/yaml/_index.md#includetemplate) [`API-Security.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)あなたの`.gitlab-ci.yml`ファイル。

1. `/api/graphql`などのGraphQLエンドポイントパスを指定します。変数`APISEC_GRAPHQL`を追加して、パスを指定します。

1. GraphQLスキーマファイルの場所を指定します。ファイルパスまたはURLとして場所を指定できます。変数`APISEC_GRAPHQL_SCHEMA`を追加して、場所を指定します。

1. ターゲットAPIインスタンスのベースURLも必要です。変数`APISEC_TARGET_URL`または`environment_url.txt`ファイルを使用して指定します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加すると、動的な環境でのテストに最適です。詳細については、[動的環境ソリューション](../troubleshooting.md#dynamic-environment-solutions)セクションを参照してください。

GraphQLスキーマファイルを使用した完全な構成例:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

api_security:
  variables:
    APISEC_GRAPHQL: /api/graphql
    APISEC_GRAPHQL_SCHEMA: test-api-graphql.schema
    APISEC_TARGET_URL: http://test-deployment/
```

GraphQLスキーマファイルURLを使用した完全な構成例:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

api_security:
  variables:
    APISEC_GRAPHQL: /api/graphql
    APISEC_GRAPHQL_SCHEMA: http://file-store/files/test-api-graphql.schema
    APISEC_TARGET_URL: http://test-deployment/
```

この例は、APIセキュリティテストの最小限の構成です。ここから、次のことができます:

- [最初のスキャンの実行](#running-your-first-scan)。
- [認証の追加](customizing_analyzer_settings.md#authentication)。
- [誤検出の処理](#handling-false-positives)の方法について説明します。

## Postman Collection {#postman-collection}

[Postman APIクライアント](https://www.postman.com/product/api-client/)は、さまざまなタイプのAPIを呼び出すためにデベロッパーとテスターが使用する一般的なツールです。API定義は、APIセキュリティテストで使用するために[Postman Collectionファイルとしてエクスポートできます](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)。エクスポートするときは、サポートされているバージョンのPostman Collection（v2.0またはv2.1）を選択してください。

GitLab APIセキュリティテストスキャナーで使用する場合、Postman Collectionには、有効なデータでテストするWeb APIの定義が含まれている必要があります。APIセキュリティテストスキャナーはすべてのAPI定義を抽出し、それらを使用してテストを実行します。

{{< alert type="warning" >}}

Postman Collectionファイルには、認証トークン、APIキー、セッションクッキーなどの機密情報が含まれている場合があります。リポジトリに追加する前に、Postman Collectionファイルの内容をレビューすることをお勧めします。

{{< /alert >}}

### Postman Collectionファイルを使用したAPIセキュリティテストスキャン {#api-security-testing-scanning-with-a-postman-collection-file}

APIセキュリティテストを構成して、テストするターゲットAPIに関する情報を提供するPostman Collectionファイルを使用するには、次の手順を実行します:

1. [含める](../../../../ci/yaml/_index.md#includetemplate) [`API-Security.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)。

1. [設定ファイル](variables.md#configuration-files)には、さまざまなチェックが有効になっている複数のテストプロファイルが定義されています。`Quick`プロファイルから開始することをお勧めします。このプロファイルを使用したテストはより迅速に完了するため、構成の検証が容易になります。

   変数`APISEC_PROFILE`を`.gitlab-ci.yml`ファイルに追加してプロファイルを指定します。

1. Postman Collectionファイルの場所をファイルまたはURLとして指定します。変数`APISEC_POSTMAN_COLLECTION`を追加して場所を指定します。

1. ターゲットAPIインスタンスのベースURLも必要です。変数`APISEC_TARGET_URL`または`environment_url.txt`ファイルを使用して指定します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加すると、動的な環境でのテストに最適です。GitLab CI/CDパイプライン中に動的に作成されたアプリに対してAPIセキュリティテストを実行するには、`environment_url.txt`ファイルにURLを永続化させます。APIセキュリティテストは、そのファイルを自動的に解析中して、スキャンターゲットを見つけます。[AutoデブオプスCI YAMLの例](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)を参照してください。

Postman Collectionを使用した完全な構成例:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection_serviceA.json
  APISEC_TARGET_URL: http://test-deployment/
```

これは、APIセキュリティテストの最小限の設定です。ここから、次のことができます:

- [最初のスキャンを実行](#running-your-first-scan)。
- [認証の追加](customizing_analyzer_settings.md#authentication)。
- [誤検出](#handling-false-positives)の処理方法について説明します。

### Postman変数 {#postman-variables}

{{< history >}}

- Postman環境ファイル形式のサポートがGitLab 15.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)。
- 複数の変数ファイルのサポートがGitLab 15.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)。
- Postman変数スコープのサポート: グローバルおよび環境がGitLab 15.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)。

{{< /history >}}

#### Postmanクライアントの変数 {#variables-in-postman-client}

Postmanでは、デベロッパーがさまざまなリクエストのさまざまな部分で使用できるプレースホルダーを定義できます。これらのプレースホルダーは、[変数の使用](https://learning.postman.com/docs/sending-requests/variables/variables/#using-variables)で説明されているように、変数と呼ばれます。変数を使用すると、リクエストとスクリプトで値を保存して再利用できます。たとえば、ドキュメントに変数を追加するために、コレクションをエディタで編集できます:

![コレクション変数タブビューを編集](img/dast_api_postman_collection_edit_variable_v18_5.png)

または、代わりに、環境に変数を追加することもできます:

![環境変数ビューを編集](img/dast_api_postman_environment_edit_variable_v18_5.png)

次に、URL、ヘッダーなどのセクションで変数を使用できます:

![変数ビューを使用してリクエストを編集](img/dast_api_postman_request_edit_v18_5.png)

Postmanは、優れたユーザーエクスペリエンスを備えた基本的なクライアントツールから、スクリプトでAPIをテストし、セカンダリリクエストをトリガーする複雑なコレクションを作成し、変数を設定できるようにする、より複雑なエコシステムに成長しました。Postmanエコシステムのすべての機能がサポートされているわけではありません。たとえば、スクリプトはサポートされていません。Postmanサポートの主な焦点は、Postmanクライアントで使用されるPostmanコレクションの定義と、ワークスペース、環境、およびコレクション自体で定義された関連変数をインジェストすることです。

Postmanでは、さまざまなスコープで変数を作成できます。各スコープには、Postmanツールで異なるレベルの表示レベルがあります。たとえば、すべてのオペレーション定義とワークスペースに表示される_グローバル環境スコープ_で変数を作成できます。また、特定環境が使用するために選択されている場合にのみ表示および使用される、特定の_環境スコープ_で変数を作成することもできます。一部のスコープは常に利用できるとは限りません。たとえば、Postmanエコシステムでは、Postmanクライアントでリクエストを作成できますが、これらのリクエストには_ローカル_スコープはありませんが、テストスクリプトはあります。

Postmanの変数スコープは、非常に難しいトピックになる可能性があり、誰もが精通しているわけではありません。先に進む前に、Postmanのドキュメントから[変数のスコープ](https://learning.postman.com/docs/sending-requests/variables/variables/#variable-scopes)を読むことを強くお勧めします。

前述のように、さまざまな変数スコープがあり、それぞれに目的があり、Postmanドキュメントに柔軟性を提供するために使用できます。Postmanドキュメントごとの変数の値の計算方法に関する重要な注意事項があります:

{{< alert type="note" >}}

同じ名前の変数が2つの異なるスコープで宣言されている場合、最も狭いスコープの変数に保存されている値が使用されます。たとえば、グローバル変数という名前の`username`とローカル変数という名前の`username`がある場合、リクエストの実行時にローカル値が使用されます。

{{< /alert >}}

以下は、PostmanクライアントとAPIセキュリティテストでサポートされている変数スコープの要約です:

- **Global Environment (Global) scope**（グローバル環境（グローバル）スコープ）は、ワークスペース全体で使用できる特別な事前定義済みの環境です。_グローバル環境_スコープを_グローバル_スコープと呼ぶこともできます。Postmanクライアントを使用すると、グローバル環境をJSONファイルにエクスポートできます。これは、APIセキュリティテストで使用できます。
- **環境スコープ**は、Postmanクライアントでユーザーによって作成された変数の名前付きグループです。Postmanクライアントは、グローバル環境とともに、単一のアクティブ環境をサポートします。アクティブなユーザー作成環境で定義された変数は、グローバル環境で定義された変数よりも優先されます。Postmanクライアントを使用すると、環境をJSONファイルにエクスポートできます。これは、APIセキュリティテストで使用できます。
- **Collection scope**（コレクションスコープ）は、特定のコレクションで宣言された変数のグループです。コレクションの変数は、宣言されたコレクション、およびネストされたリクエストまたはコレクションで使用できます。コレクションスコープで定義された変数は、_グローバル環境_スコープ、および_環境スコープ_よりも優先されます。Postmanクライアントは、1つ以上のコレクションをJSONファイルにエクスポートできます。このJSONファイルには、選択したコレクション、リクエスト、およびコレクションの変数が含まれています。
- **API security testing scope**（APIセキュリティテストスコープ）は、APIセキュリティテストによって追加された新しいスコープであり、ユーザーが追加の変数を提供したり、他のサポートされているスコープで定義された変数をオーバーライドしたりできるようにします。このスコープは、Postmanではサポートされていません。_APIセキュリティテストスコープ_変数は、[カスタムJSONファイル形式](#api-security-testing-scope-custom-json-file-format)を使用して提供されます。
  - 環境またはコレクションで定義された値をオーバーライドする
  - スクリプトから変数を定義する
  - サポートされていない_データのスコープ_からデータの単一行を定義する
- **Data scope**（データスコープ）は、名前と値がJSONまたはCSVファイルから取得される変数のグループです。[ニューマン](https://learning.postman.com/docs/collections/using-newman-cli/command-line-integration-with-newman/)または[Postmanコレクションランナー](https://learning.postman.com/docs/collections/running-collections/intro-to-collection-runs/)のようなPostmanコレクションランナーは、コレクションのリクエストを、エントリがJSONまたはCSVファイルにある回数だけ実行します。これらの変数の良いユースケースは、Postmanでスクリプトを使用してテストを自動化することです。APIセキュリティテストでは、CSVまたはJSONファイルからデータを読み取ることは**not**（できません）。
- **Local scope**（ローカルスコープ）は、Postmanスクリプトで定義されている変数です。APIセキュリティテストでは、Postmanスクリプト、および拡張機能によって、スクリプトで定義された変数はサポートされ**not**（ません）。サポートされているスコープの1つ、またはカスタムJSON形式で定義することにより、スクリプトで定義された変数の値を引き続き提供できます。

すべてのスコープがAPIセキュリティテストでサポートされているわけではなく、スクリプトで定義された変数はサポートされていません。次の表は、最も広いスコープから最も狭いスコープで並べ替えられています。

| スコープ                      | Postman | APIセキュリティテスト | コメント                                    |
|----------------------------|:-------:|:--------------------:|:-------------------------------------------|
| グローバル環境         |   はい   |         はい          | 特別な事前定義済み環境            |
| 環境                |   はい   |         はい          | 名前付き環境                         |
| コレクション                 |   はい   |         はい          | Postmanコレクションで定義         |
| APIセキュリティのスコープ |   いいえ    |         はい          | APIセキュリティテストによって追加されたカスタムスコープ |
| データ:                       |   はい   |          いいえ          | CSVまたはJSON形式の外部ファイル       |
| ローカル                      |   はい   |          いいえ          | スクリプトで定義された変数               |

さまざまなスコープで変数を定義およびエクスポートする方法の詳細については、以下を参照してください:

- [コレクション変数を定義する](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-collection-variables)
- [環境](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-environment-variables)変数を定義する
- [グローバル変数](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-global-variables)を定義する

##### Postmanクライアントからエクスポートする {#exporting-from-postman-client}

Postmanクライアントを使用すると、さまざまなファイル形式をエクスポートできます。たとえば、PostmanコレクションまたはPostman環境をエクスポートできます。エクスポートされた環境は、（常に利用可能な）グローバル環境、または以前に作成したカスタム環境にすることができます。Postmanコレクションをエクスポートすると、_コレクション_および_ローカル_スコープの変数の宣言のみが含まれる場合があります。_環境_スコープの変数は含まれていません。

_環境_スコープの変数の宣言を取得するには、特定の環境をその時点でエクスポートする必要があります。各エクスポートされたファイルには、選択した環境の変数のみが含まれています。

サポートされているさまざまなスコープで変数をエクスポートする方法の詳細については、以下を参照してください:

- [コレクションをエクスポートする](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)
- [環境をエクスポートする](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [グローバル環境をダウンロード](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)

#### APIセキュリティテストスコープ、カスタムJSONファイル形式 {#api-security-testing-scope-custom-json-file-format}

カスタムJSONファイル形式は、各オブジェクトプロパティが変数名を表し、プロパティ値が変数値を表すJSONオブジェクトです。このファイルは、お気に入りのテキストエディタを使用して作成することも、パイプラインの以前のジョブで生成することもできます。

この例では、APIセキュリティテストスコープに2つの変数`base_url`と`token`を定義します:

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### APIセキュリティテストでのスコープの使用 {#using-scopes-with-api-security-testing}

スコープ：_グローバル_、_環境_、_コレクション_、および_GitLab APIセキュリティテスト_は、[GitLab 15.1以降](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)でサポートされています。GitLab 15.0以前は、_コレクション_と_GitLab APIセキュリティテスト_スコープのみをサポートしています。

次の表に、スコープファイル/URLをAPIセキュリティテスト設定変数にマッピングするためのクイック参照を示します:

| スコープ              |  提供方法 |
| ------------------ | --------------- |
| グローバル環境 | APISEC_POSTMAN_COLLECTION_VARIABLES |
| 環境        | APISEC_POSTMAN_COLLECTION_VARIABLES |
| コレクション         | APISEC_POSTMAN_COLLECTION           |
| APIセキュリティのスコープ | APISEC_POSTMAN_COLLECTION_VARIABLES |
| データ:               | サポートされていません   |
| ローカル              | サポートされていません   |

Postmanコレクションドキュメントには、_コレクション_スコープの変数が自動的に含まれます。Postmanコレクションは、`APISEC_POSTMAN_COLLECTION`設定変数で提供されます。この変数は、単一の[エクスポートされたPostmanコレクション](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)に設定できます。

他のスコープからの変数は、`APISEC_POSTMAN_COLLECTION_VARIABLES`設定変数を介して提供されます。この設定変数は、[GitLab 15.1以降](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)のコンマ（`,`）区切りのファイルリストをサポートします。GitLab 15.0以前は、1つの単一ファイルのみをサポートします。必要なスコープ情報が提供されるため、提供されるファイルの順序は重要ではありません。

設定変数`APISEC_POSTMAN_COLLECTION_VARIABLES`は、以下に設定できます:

- [エクスポートされたグローバル環境](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)
- [エクスポートされた環境](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [APIセキュリティテストカスタムJSON形式](#api-security-testing-scope-custom-json-file-format)

#### 未定義Postman変数 {#undefined-postman-variables}

APIセキュリティテストエンジンが、Postmanコレクションファイルが使用しているすべての変数参照を見つけられない可能性があります。いくつかのユースケースがあります:

- あなたは_データ_または_ローカル_スコープの変数を使用しており、前述のように、これらのスコープはAPIセキュリティテストではサポートされていません。したがって、これらの変数の値が[APIセキュリティテストスコープ](#api-security-testing-scope-custom-json-file-format)を介して提供されていないと仮定すると、_データ_と_ローカル_スコープの変数の値は未定義です。
- 変数名が正しく入力されておらず、名前が定義された変数と一致しません。
- Postmanクライアントは、APIセキュリティテストでサポートされていない新しい動的変数をサポートしています。

可能であれば、APIセキュリティテストは、未定義の変数を処理する場合と同様の動作に従います。変数参照のテキストは同じままであり、テキストの置換はありません。同じ動作は、サポートされていない動的変数にも適用されます。

たとえば、Postmanコレクションのリクエスト定義が変数`{{full_url}}`を参照しており、変数が見つからない場合、値`{{full_url}}`で変更されずに残ります。

#### 動的なPostman変数 {#dynamic-postman-variables}

ユーザーがさまざまなスコープレベルで定義できる変数に加えて、Postmanには、_動的_変数と呼ばれる事前定義された変数のセットがあります。[_動的_変数](https://learning.postman.com/docs/tests-and-scripts/write-scripts/variables-list/)はすでに定義されており、それらの名前にはドル記号（`$`）がプレフィックスとして付けられています。たとえば、`$guid`です。_動的な_変数は他の変数と同様に使用でき、Postmanクライアントでは、リクエスト/コレクションの実行中にランダムな値が生成されます。

APIセキュリティテストとPostmanの重要な違いは、APIセキュリティテストでは、同じ動的変数の使用ごとに同じ値が返されることです。これは、同じ動的変数を使用するたびにランダムな値を返すPostmanクライアントの動作とは異なります。言い換えれば、APIセキュリティテストでは動的変数に静的な値を使用し、Postmanではランダムな値を使用します。

スキャンプロセス中にサポートされる動的変数は次のとおりです:

| 変数    | 値       |
| ----------- | ----------- |
| `$guid` | `611c2e81-2ccb-42d8-9ddc-2d0bfa65c1b4` |
| `$isoTimestamp` | `2020-06-09T21:10:36.177Z` |
| `$randomAbbreviation` | `PCI` |
| `$randomAbstractImage` | `http://no-a-valid-host/640/480/abstract` |
| `$randomAdjective` | `auxiliary` |
| `$randomAlphaNumeric` | `a` |
| `$randomAnimalsImage` | `http://no-a-valid-host/640/480/animals` |
| `$randomAvatarImage` | `https://no-a-valid-host/path/to/some/image.jpg` |
| `$randomBankAccount` | `09454073` |
| `$randomBankAccountBic` | `EZIAUGJ1` |
| `$randomBankAccountIban` | `MU20ZPUN3039684000618086155TKZ` |
| `$randomBankAccountName` | `Home Loan Account` |
| `$randomBitcoin` | `3VB8JGT7Y4Z63U68KGGKDXMLLH5` |
| `$randomBoolean` | `true` |
| `$randomBs` | `killer leverage schemas` |
| `$randomBsAdjective` | `viral` |
| `$randomBsBuzz` | `repurpose` |
| `$randomBsNoun` | `markets` |
| `$randomBusinessImage` | `http://no-a-valid-host/640/480/business` |
| `$randomCatchPhrase` | `Future-proofed heuristic open architecture` |
| `$randomCatchPhraseAdjective` | `Business-focused` |
| `$randomCatchPhraseDescriptor` | `bandwidth-monitored` |
| `$randomCatchPhraseNoun` | `superstructure` |
| `$randomCatsImage` | `http://no-a-valid-host/640/480/cats` |
| `$randomCity` | `Spinkahaven` |
| `$randomCityImage` | `http://no-a-valid-host/640/480/city` |
| `$randomColor` | `fuchsia` |
| `$randomCommonFileExt` | `wav` |
| `$randomCommonFileName` | `well_modulated.mpg4` |
| `$randomCommonFileType` | `audio` |
| `$randomCompanyName` | `Grady LLC` |
| `$randomCompanySuffix` | `Inc` |
| `$randomCountry` | `Kazakhstan` |
| `$randomCountryCode` | `MD` |
| `$randomCreditCardMask` | `3622` |
| `$randomCurrencyCode` | `ZMK` |
| `$randomCurrencyName` | `Pound Sterling` |
| `$randomCurrencySymbol` | `£` |
| `$randomDatabaseCollation` | `utf8_general_ci` |
| `$randomDatabaseColumn` | `updatedAt` |
| `$randomDatabaseEngine` | `Memory` |
| `$randomDatabaseType` | `text` |
| `$randomDateFuture` | `Tue Mar 17 2020 13:11:50 GMT+0530 (India Standard Time)` |
| `$randomDatePast` | `Sat Mar 02 2019 09:09:26 GMT+0530 (India Standard Time)` |
| `$randomDateRecent` | `Tue Jul 09 2019 23:12:37 GMT+0530 (India Standard Time)` |
| `$randomDepartment` | `Electronics` |
| `$randomDirectoryPath` | `/usr/local/bin` |
| `$randomDomainName` | `trevor.info` |
| `$randomDomainSuffix` | `org` |
| `$randomDomainWord` | `jaden` |
| `$randomEmail` | `Iva.Kovacek61@no-a-valid-host.com` |
| `$randomExampleEmail` | `non-a-valid-user@example.net` |
| `$randomFashionImage` | `http://no-a-valid-host/640/480/fashion` |
| `$randomFileExt` | `war` |
| `$randomFileName` | `neural_sri_lanka_rupee_gloves.gdoc` |
| `$randomFilePath` | `/home/programming_chicken.cpio` |
| `$randomFileType` | `application` |
| `$randomFirstName` | `Chandler` |
| `$randomFoodImage` | `http://no-a-valid-host/640/480/food` |
| `$randomFullName` | `Connie Runolfsdottir` |
| `$randomHexColor` | `#47594a` |
| `$randomImageDataUri` | `data:image/svg+xml;charset=UTF-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20version%3D%221.1%22%20baseProfile%3D%22full%22%20width%3D%22undefined%22%20height%3D%22undefined%22%3E%20%3Crect%20width%3D%22100%25%22%20height%3D%22100%25%22%20fill%3D%22grey%22%2F%3E%20%20%3Ctext%20x%3D%220%22%20y%3D%2220%22%20font-size%3D%2220%22%20text-anchor%3D%22start%22%20fill%3D%22white%22%3Eundefinedxundefined%3C%2Ftext%3E%20%3C%2Fsvg%3E` |
| `$randomImageUrl` | `http://no-a-valid-host/640/480` |
| `$randomIngverb` | `navigating` |
| `$randomInt` | `494` |
| `$randomIP` | `241.102.234.100` |
| `$randomIPV6` | `dbe2:7ae6:119b:c161:1560:6dda:3a9b:90a9` |
| `$randomJobArea` | `Mobility` |
| `$randomJobDescriptor` | `Senior` |
| `$randomJobTitle` | `International Creative Liaison` |
| `$randomJobType` | `Supervisor` |
| `$randomLastName` | `Schneider` |
| `$randomLatitude` | `55.2099` |
| `$randomLocale` | `ny` |
| `$randomLongitude` | `40.6609` |
| `$randomLoremLines` | `Ducimus in ut mollitia.\nA itaque non.\nHarum temporibus nihil voluptas.\nIste in sed et nesciunt in quaerat sed.` |
| `$randomLoremParagraph` | `Ab aliquid odio iste quo voluptas voluptatem dignissimos velit. Recusandae facilis qui commodi ea magnam enim nostrum quia quis. Nihil est suscipit assumenda ut voluptatem sed. Esse ab voluptas odit qui molestiae. Rem est nesciunt est quis ipsam expedita consequuntur.` |
| `$randomLoremParagraphs` | `Voluptatem rem magnam aliquam ab id aut quaerat. Placeat provident possimus voluptatibus dicta velit non aut quasi. Mollitia et aliquam expedita sunt dolores nam consequuntur. Nam dolorum delectus ipsam repudiandae et ipsam ut voluptatum totam. Nobis labore labore recusandae ipsam quo.` |
| `$randomLoremSentence` | `Molestias consequuntur nisi non quod.` |
| `$randomLoremSentences` | `Et sint voluptas similique iure amet perspiciatis vero sequi atque. Ut porro sit et hic. Neque aspernatur vitae fugiat ut dolore et veritatis. Ab iusto ex delectus animi. Voluptates nisi iusto. Impedit quod quae voluptate qui.` |
| `$randomLoremSlug` | `eos-aperiam-accusamus, beatae-id-molestiae, qui-est-repellat` |
| `$randomLoremText` | `Quisquam asperiores exercitationem ut ipsum. Aut eius nesciunt. Et reiciendis aut alias eaque. Nihil amet laboriosam pariatur eligendi. Sunt ullam ut sint natus ducimus. Voluptas harum aspernatur soluta rem nam.` |
| `$randomLoremWord` | `est` |
| `$randomLoremWords` | `vel repellat nobis` |
| `$randomMACAddress` | `33:d4:68:5f:b4:c7` |
| `$randomMimeType` | `audio/vnd.vmx.cvsd` |
| `$randomMonth` | `February` |
| `$randomNamePrefix` | `Dr.` |
| `$randomNameSuffix` | `MD` |
| `$randomNatureImage` | `http://no-a-valid-host/640/480/nature` |
| `$randomNightlifeImage` | `http://no-a-valid-host/640/480/nightlife` |
| `$randomNoun` | `bus` |
| `$randomPassword` | `t9iXe7COoDKv8k3` |
| `$randomPeopleImage` | `http://no-a-valid-host/640/480/people` |
| `$randomPhoneNumber` | `700-008-5275` |
| `$randomPhoneNumberExt` | `27-199-983-3864` |
| `$randomPhrase` | `You can't program the monitor without navigating the mobile XML program!` |
| `$randomPrice` | `531.55` |
| `$randomProduct` | `Pizza` |
| `$randomProductAdjective` | `Unbranded` |
| `$randomProductMaterial` | `Steel` |
| `$randomProductName` | `Handmade Concrete Tuna` |
| `$randomProtocol` | `https` |
| `$randomSemver` | `7.0.5` |
| `$randomSportsImage` | `http://no-a-valid-host/640/480/sports` |
| `$randomStreetAddress` | `5742 Harvey Streets` |
| `$randomStreetName` | `Kuhic Island` |
| `$randomTransactionType` | `payment` |
| `$randomTransportImage` | `http://no-a-valid-host/640/480/transport` |
| `$randomUrl` | `https://no-a-valid-host.net` |
| `$randomUserAgent` | `Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.9.8; rv:15.6) Gecko/20100101 Firefox/15.6.6` |
| `$randomUserName` | `Jarrell.Gutkowski` |
| `$randomUUID` | `6929bb52-3ab2-448a-9796-d6480ecad36b` |
| `$randomVerb` | `navigate` |
| `$randomWeekday` | `Thursday` |
| `$randomWord` | `withdrawal` |
| `$randomWords` | `Samoa Synergistic sticky copying Grocery` |
| `$timestamp` | `1562757107` |

#### 例: グローバルスコープ {#example-global-scope}

この例では、[_グローバル_スコープが呼び出され](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)、Postman Clientから`global-scope.json`としてエクスポートされ、`APISEC_POSTMAN_COLLECTION_VARIABLES`変数を介してAPIセキュリティテストに提供されます。

`APISEC_POSTMAN_COLLECTION_VARIABLES`を使用する例を次に示します:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: global-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### 例: 環境 {#example-environment-scope}

この例では、[_環境_スコープが呼び出され](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)、Postman Clientから`environment-scope.json`としてエクスポートされ、`APISEC_POSTMAN_COLLECTION_VARIABLES`変数を介してAPIセキュリティテストに提供されます。

`APISEC_POSTMAN_COLLECTION_VARIABLES`を使用する例を次に示します:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: environment-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### 例: コレクションスコープ {#example-collection-scope}

_コレクション_スコープ変数は、エクスポートされたPostmanコレクションファイルに入力された状態で含まれており、`APISEC_POSTMAN_COLLECTION`変数を介して提供されます。

`APISEC_POSTMAN_COLLECTION`を使用する例を次に示します:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### 例: APIセキュリティのスコープ {#example-api-security-testing-scope}

APIセキュリティテストスコープは、APIセキュリティテストでサポートされていない_データ_と_ローカル_スコープ変数を定義し、別のスコープで定義された既存の変数の値を変更するという2つの主な目的で使用されます。APIセキュリティテストスコープは、`APISEC_POSTMAN_COLLECTION_VARIABLES`変数を介して提供されます。

`APISEC_POSTMAN_COLLECTION_VARIABLES`を使用する例を次に示します:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: dast-api-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

ファイル`dast-api-scope.json`は、[カスタムJSONファイル形式](#api-security-testing-scope-custom-json-file-format)を使用します。このJSONは、プロパティのキー/バリューペアを含むオブジェクトです。キーは変数の名前で、値は変数の値です。例: 

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### 例: 複数のスコープ {#example-multiple-scopes}

この例では、_グローバル_スコープ、_環境_スコープ、および_コレクション_スコープが設定されています。最初の手順は、さまざまなスコープをエクスポートすることです。

- [_グローバル_スコープをエクスポートする](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)（`global-scope.json`）
- [_環境_スコープをエクスポートする](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)（`environment-scope.json`）
- _コレクション_スコープを含むPostmanコレクションをエクスポートする（`postman-collection.json`）

Postmanコレクションは`APISEC_POSTMAN_COLLECTION`変数を使用して提供され、その他のスコープは`APISEC_POSTMAN_COLLECTION_VARIABLES`を使用して提供されます。APIセキュリティテストでは、各ファイルで提供されるデータを使用して、提供されたファイルがどのスコープに一致するかを識別できます。

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### 例: 変数の値を変更する {#example-changing-a-variables-value}

エクスポートされたスコープを使用する場合、APIセキュリティテストで使用するために変数の値を変更する必要があることがよくあります。たとえば、_コレクション_スコープ変数には、`api_version`という名前の変数が含まれており、値は`v2`ですが、テストでは`v1`の値が必要です。エクスポートされたコレクションを変更して値を変更する代わりに、APIセキュリティテストスコープを使用して値を変更できます。これは、_APIセキュリティテスト_スコープが他のすべてのスコープよりも優先されるためです。

_コレクション_スコープ変数は、エクスポートされたPostmanコレクションファイルに入力された状態で含まれており、`APISEC_POSTMAN_COLLECTION`変数を介して提供されます。

APIセキュリティテストスコープは、`APISEC_POSTMAN_COLLECTION_VARIABLES`変数を介して提供されますが、最初にファイルを作成する必要があります。ファイル`dast-api-scope.json`は、[カスタムJSONファイル形式](#api-security-testing-scope-custom-json-file-format)を使用します。このJSONは、プロパティのキー/バリューペアを含むオブジェクトです。キーは変数の名前で、値は変数の値です。例: 

```json
{
  "api_version": "v1"
}
```

CI定義:

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: dast-api-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

#### 例: 複数のスコープで変数の値を変更する {#example-changing-a-variables-value-with-multiple-scopes}

エクスポートされたスコープを使用する場合、APIセキュリティテストで使用するために変数の値を変更する必要があることがよくあります。たとえば、_環境_スコープに、`api_version`という名前の変数が含まれており、値は`v2`ですが、テストでは`v1`の値が必要です。エクスポートされたファイルを変更して値を変更する代わりに、APIセキュリティテストスコープを使用できます。これは、_APIセキュリティテスト_スコープが他のすべてのスコープよりも優先されるためです。

この例では、_グローバル_スコープ、_環境_スコープ、_コレクション_スコープ、および_APIセキュリティテスト_スコープが設定されています。最初の手順は、さまざまなスコープをエクスポートおよび作成することです。

- [_グローバル_スコープをエクスポートする](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)（`global-scope.json`）
- [_環境_スコープをエクスポートする](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)（`environment-scope.json`）
- _コレクション_スコープを含むPostmanコレクションをエクスポートする（`postman-collection.json`）

APIセキュリティテストスコープは、[カスタムJSONファイル形式](#api-security-testing-scope-custom-json-file-format)を使用して、ファイル`dast-api-scope.json`を作成することで使用されます。このJSONは、プロパティのキー/バリューペアを含むオブジェクトです。キーは変数の名前で、値は変数の値です。例: 

```json
{
  "api_version": "v1"
}
```

Postmanコレクションは`APISEC_POSTMAN_COLLECTION`変数を使用して提供され、その他のスコープは`APISEC_POSTMAN_COLLECTION_VARIABLES`を使用して提供されます。APIセキュリティテストでは、各ファイルで提供されるデータを使用して、提供されたファイルがどのスコープに一致するかを識別できます。

```yaml
stages:
  - dast

include:
  - template: Security/API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_POSTMAN_COLLECTION: postman-collection.json
  APISEC_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json,dast-api-scope.json
  APISEC_TARGET_URL: http://test-deployment/
```

## 最初のスキャンを実行する {#running-your-first-scan}

正しく設定されている場合、CI/CDパイプラインには、`dast`ステージと`dast_api`ジョブが含まれます。無効な設定が指定されている失敗場合にのみ、ジョブが失敗します。通常の操作では、テスト中に脆弱性が特定された場合でも、ジョブは常に成功します。

脆弱性は、スイート名とともに**セキュリティ**パイプラインタブに表示されます。リポジトリのデフォルトブランチに対してテストする場合、APIセキュリティテストの脆弱性は、セキュリティおよびコンプライアンスの脆弱性レポートにも表示されます。

報告される脆弱性の数が過剰になるのを防ぐために、APIセキュリティテストアナライザーは、操作ごとに報告する脆弱性の数を制限します。

## APIセキュリティテスト脆弱性の表示 {#viewing-api-security-testing-vulnerabilities}

APIセキュリティテストアナライザーは、収集および使用されるJSONレポートを生成し、[GitLab脆弱性画面に脆弱性を入力します](#view-details-of-an-api-security-testing-vulnerability)。

報告される誤検出の数を制限するために行える設定の変更については、[誤検出の処理](#handling-false-positives)を参照してください。

### APIセキュリティテスト脆弱性の詳細の表示 {#view-details-of-an-api-security-testing-vulnerability}

脆弱性の詳細を表示するには、次の手順に従います:

1. 脆弱性は、プロジェクトまたはマージリクエストで表示できます:

   - プロジェクトで、プロジェクトの**セキュリティ** > **脆弱性レポート**ページに移動します。このページには、デフォルトブランチのすべての脆弱性のみが表示されます。
   - マージリクエストで、マージリクエストの**セキュリティ**セクションに移動し、**全て展開**ボタンを選択します。APIセキュリティテストの脆弱性は、「**DAST detected N potential vulnerabilities**（DASTがN個の潜在的な脆弱性を検出しました）」というラベルのセクションで利用できます。タイトルを選択して、脆弱性の詳細を表示します。

1. 脆弱性のタイトルを選択して詳細を表示します。次の表では、これらの詳細について説明します。

   | フィールド               | 説明                                                                             |
   |:--------------------|:----------------------------------------------------------------------------------------|
   | 説明         | 変更された内容を含む脆弱性の説明。                           |
   | プロジェクト             | 脆弱性が検出されたネームスペースとプロジェクト。                          |
   | メソッド              | 脆弱性の検出に使用されたHTTPメソッド。                                           |
   | URL                 | 脆弱性が検出されたURL。                                            |
   | リクエスト             | 脆弱性を引き起こしたHTTPリクエスト。                                         |
   | 未変更のレスポンス | 未変更のリクエストからのレスポンス。これは、一般的な作業応答がどのように見えるかです。 |
   | 実際の結果     | テストリクエストから受信したレスポンス。                                                    |
   | エビデンス            | 脆弱性が発生したと判断した方法。                                             |
   | 識別子         | この脆弱性を見つけるために使用されるAPIセキュリティテストチェック。                         |
   | 重大度            | 脆弱性の重大度。                                                          |
   | スキャナーの種類        | テストの実行に使用されるスキャナー。                                                        |

### セキュリティダッシュボード {#security-dashboard}

セキュリティダッシュボードは、グループ、プロジェクト、パイプライン内のすべての脆弱性の概要を把握するのに適した場所です。詳細については、[セキュリティダッシュボードのドキュメント](../../security_dashboard/_index.md)を参照してください。

### 脆弱性の操作 {#interacting-with-the-vulnerabilities}

脆弱性が見つかったら、操作できます。詳細については、[脆弱性に対処](../../vulnerabilities/_index.md)する方法をお読みください。

### 誤検出の処理 {#handling-false-positives}

誤検出は、いくつかの方法で処理できます:

- 脆弱性を無視します。
- 一部のチェックには、脆弱性が特定されたタイミングを検出するいくつかの方法があり、_アサーション_と呼ばれます。アサーションをオフにして設定することもできます。たとえば、APIセキュリティテストスキャナーは、デフォルトでHTTPステータスコードを使用して、何かが実際の問題であるかどうかを識別します。APIがテスト中に500エラーを返した場合、これにより脆弱性が作成されます。一部のフレームワークは500エラーを頻繁に返すため、これは必ずしも望ましいとは限りません。
- 誤検出を生成するチェックをオフにします。これにより、チェックで脆弱性が生成されなくなります。チェックの例としては、SQLインジェクションチェックやJSONハイジャックチェックなどがあります。

#### チェックをオフにする {#turn-off-a-check}

チェックは特定の種類のテストを実行し、特定の設定プロファイルに対してオンとオフを切り替えることができます。指定された[設定ファイル](variables.md#configuration-files)は、使用できるいくつかのプロファイルを定義します。設定ファイルのプロファイル定義には、スキャン中にアクティブになっているすべてのチェックがリストされています。特定のチェックをオフにするには、設定ファイルのプロファイル定義から削除します。プロファイルは、設定ファイルの`Profiles`セクションで定義されています。

プロファイル定義の例:

```yaml
Profiles:
  - Name: Quick
    DefaultProfile: Empty
    Routes:
      - Route: *Route0
        Checks:
          - Name: ApplicationInformationCheck
          - Name: CleartextAuthenticationCheck
          - Name: FrameworkDebugModeCheck
          - Name: HtmlInjectionCheck
          - Name: InsecureHttpMethodsCheck
          - Name: JsonHijackingCheck
          - Name: JsonInjectionCheck
          - Name: SensitiveInformationCheck
          - Name: SessionCookieCheck
          - Name: SqlInjectionCheck
          - Name: TokenCheck
          - Name: XmlInjectionCheck
```

JSONハイジャックチェックをオフにするには、次の行を削除します:

```yaml
          - Name: JsonHijackingCheck
```

これにより、次のYAMLが得られます:

```yaml
- Name: Quick
  DefaultProfile: Empty
  Routes:
    - Route: *Route0
      Checks:
        - Name: ApplicationInformationCheck
        - Name: CleartextAuthenticationCheck
        - Name: FrameworkDebugModeCheck
        - Name: HtmlInjectionCheck
        - Name: InsecureHttpMethodsCheck
        - Name: JsonInjectionCheck
        - Name: SensitiveInformationCheck
        - Name: SessionCookieCheck
        - Name: SqlInjectionCheck
        - Name: TokenCheck
        - Name: XmlInjectionCheck
```

#### チェックのアサーションをオフにする {#turn-off-an-assertion-for-a-check}

アサーションは、チェックによって生成されたテストで脆弱性を検出します。多くのチェックは、ログ分析、レスポンス分析、ステータスコードなどの複数のアサーションをサポートしています。脆弱性が見つかった場合、使用されたアサーションが提供されます。どの主張がデフォルトでオンになっているかを識別するには、設定ファイルでチェックのデフォルト設定を参照してください。セクションは`Checks`と呼ばれます。

この例は、SQLインジェクションチェックを示しています:

```yaml
- Name: SqlInjectionCheck
  Configuration:
    UserInjections: []
  Assertions:
    - Name: LogAnalysisAssertion
    - Name: ResponseAnalysisAssertion
    - Name: StatusCodeAssertion
```

ここでは、3つのアサーションがデフォルトでオンになっていることがわかります。誤検出の一般的な原因は`StatusCodeAssertion`です。オフにするには、`Profiles`セクションで設定を変更します。この例では、他の2つのアサーション（`LogAnalysisAssertion`、`ResponseAnalysisAssertion`）のみを提供します。これにより、`SqlInjectionCheck`は`StatusCodeAssertion`を使用できなくなります:

```yaml
Profiles:
  - Name: Quick
    DefaultProfile: Empty
    Routes:
      - Route: *Route0
        Checks:
          - Name: ApplicationInformationCheck
          - Name: CleartextAuthenticationCheck
          - Name: FrameworkDebugModeCheck
          - Name: HtmlInjectionCheck
          - Name: InsecureHttpMethodsCheck
          - Name: JsonHijackingCheck
          - Name: JsonInjectionCheck
          - Name: SensitiveInformationCheck
          - Name: SessionCookieCheck
          - Name: SqlInjectionCheck
            Assertions:
              - Name: LogAnalysisAssertion
              - Name: ResponseAnalysisAssertion
          - Name: TokenCheck
          - Name: XmlInjectionCheck
```
