---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: アナライザーを有効にする
---

スキャンするAPIを次のように指定できます:

- [OpenAPI v2またはv3仕様](#openapi-specification)
- [GraphQLのスキーマ](#graphql-schema)
- [HTTP Archive (HAR)](#http-archive-har)
- [Postman Collection v2.0またはv2.1](#postman-collection)

## OpenAPI仕様 {#openapi-specification}

The [OpenAPI仕様](https://www.openapis.org/) (旧Swagger仕様) は、REST APIのAPI記述フォーマットです。このセクションでは、APIセキュリティテストのスキャンを構成して、OpenAPI仕様を使用してターゲットAPIのテストに関する情報を提供する方法を説明します。OpenAPI仕様は、ファイルシステムリソースまたはURLとして提供されます。JSONとYAMLの両方のOpenAPI形式がサポートされています。

APIセキュリティテストでは、OpenAPIドキュメントを使用してリクエストボディを生成します。リクエストボディが必要な場合、ボディの生成は次のボディタイプに制限されます:

- `application/x-www-form-urlencoded`
- `multipart/form-data`
- `application/json`
- `application/xml`

## OpenAPIとメディアタイプ {#openapi-and-media-types}

メディアタイプ（旧MIMEタイプ）は、ファイル形式および送信される形式コンテンツの識別子です。OpenAPIドキュメントを使用すると、特定の操作が異なるメディアタイプを受け入れるように指定でき、したがって、特定のリクエストで異なるファイルコンテンツを使用してデータを送信できます。例えば、`PUT /user`操作は、XML (メディアタイプ`application/xml`) またはJSON (メディアタイプ`application/json`) 形式のいずれかでユーザーデータを受け入れることができます。OpenAPI 2.xでは、メディアタイプをグローバルまたは操作ごとに指定でき、OpenAPI 3.xでは、操作ごとにメディアタイプを指定できます。APIセキュリティテストは、リストされたメディアタイプをチェックし、サポートされている各メディアタイプに対してサンプルデータを生成しようとします。

- デフォルトの動作は、使用するサポートされているメディアタイプのいずれかを選択することです。リストから最初にサポートされているメディアタイプが選択されます。この動作は構成可能です。

異なるメディアタイプ（例えば、`application/json`と`application/xml`）を使用して同じ操作（例えば、`POST /user`）をテストすることは、常に望ましいとは限りません。例えば、ターゲットアプリケーションがリクエストコンテンツタイプに関わらず同じコードを実行する場合、テストセッションの完了に時間がかかり、ターゲットアプリによってはリクエストボディに関連する重複した脆弱性を報告する可能性があります。

環境変数`APISEC_OPENAPI_ALL_MEDIA_TYPES`を使用すると、特定の操作に対するリクエストを生成する際に、サポートされているすべてのメディアタイプを使用するかどうかを指定できます。環境変数`APISEC_OPENAPI_ALL_MEDIA_TYPES`が任意の値に設定されている場合、APIセキュリティテストは、特定の操作で単一のメディアタイプの代わりにサポートされているすべてのメディアタイプに対してリクエストを生成しようとします。これにより、提供された各メディアタイプに対してテストが繰り返されるため、テストに時間がかかります。

あるいは、変数`APISEC_OPENAPI_MEDIA_TYPES`を使用して、それぞれテストされるメディアタイプのリストを提供します。複数のメディアタイプを提供すると、選択された各メディアタイプに対してテストが実行されるため、テストに時間がかかります。環境変数`APISEC_OPENAPI_MEDIA_TYPES`がメディアタイプのリストに設定されている場合、リクエストの作成時にはリストされたメディアタイプのみが含まれます。

`APISEC_OPENAPI_MEDIA_TYPES`内の複数のメディアタイプはコロン (`:`) で区切られます。例えば、リクエストの生成をメディアタイプ`application/x-www-form-urlencoded`と`multipart/form-data`に制限するには、環境変数`APISEC_OPENAPI_MEDIA_TYPES`を`application/x-www-form-urlencoded:multipart/form-data`に設定します。このリストでサポートされているメディアタイプのみがリクエストの作成時に含まれ、サポートされていないメディアタイプは常にスキップされます。メディアタイプのテキストには、異なるセクションが含まれる場合があります。例えば、`application/vnd.api+json; charset=UTF-8`は`type "/" [tree "."] subtype ["+" suffix]* [";" parameter]`の複合です。リクエスト生成時にメディアタイプのフィルタリングを実行する際、パラメータは考慮されません。

環境変数`APISEC_OPENAPI_ALL_MEDIA_TYPES`と`APISEC_OPENAPI_MEDIA_TYPES`を使用すると、メディアタイプの処理方法を決定できます。これらの設定は相互に排他的です。両方が有効な場合、APIセキュリティテストはエラーをレポートします。

### OpenAPI仕様を使用してAPIセキュリティテストを構成する {#configure-api-security-testing-with-an-openapi-specification}

OpenAPI仕様を使用してAPIセキュリティテストのスキャンを構成するには:

1. ご自身の`.gitlab-ci.yml`ファイルに[`API-Security.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)を[インクルード](../../../../ci/yaml/_index.md#includetemplate)します。

1. The [設定ファイル](variables.md#configuration-files)には、異なるチェックが有効化された複数のテストプロファイルが定義されています。`Quick`プロファイルから始めます。このプロファイルでのテストは迅速に完了し、設定の検証を容易にします。`.gitlab-ci.yml`ファイルに`APISEC_PROFILE` CI/CD変数を追加してプロファイルを提供します。

1. OpenAPI仕様の場所をファイルまたはURLとして提供します。`APISEC_OPENAPI`変数を追加して場所を指定します。

1. ターゲットAPIインスタンスのベースURLも必要です。`APISEC_TARGET_URL`変数または`environment_url.txt`ファイルを使用して提供します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加することは、動的環境でのテストに非常に役立ちます。GitLab CI/CDパイプライン中に動的に作成されたアプリに対してAPIセキュリティテストを実行するには、アプリのURLを`environment_url.txt`ファイルに保持させます。APIセキュリティテストは、そのファイルを自動的に解析して、スキャンターゲットを見つけます。この例は、GitLabの[Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)で確認できます。

OpenAPI仕様を使用する完全な設定例:

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

これは、APIセキュリティテストの最小設定です。ここから、次のことができます:

- 最初の[スキャン](#running-your-first-scan)を実行します。
- [認証](customizing_analyzer_settings.md#authentication)を追加します。
- [誤検出の処理](#handling-false-positives)について学びます。

## HTTP Archive (HAR) {#http-archive-har}

The [HTTP Archive format (HAR)](../../api_fuzzing/create_har_files.md)は、HTTPトランザクションをログに記録するためのアーカイブファイル形式です。GitLab APIセキュリティテストスキャナーで使用する場合、HARファイルにはテスト対象のWeb APIを呼び出す記録が含まれている必要があります。APIセキュリティテストスキャナーは、すべてのリクエストを抽出して、テストを実行するために使用します。

HARファイルを生成するために、さまざまなツールを使用できます:

- [Insomnia Core](https://insomnia.rest/): APIクライアント
- [Chrome](https://www.google.com/chrome/): ブラウザ
- [Firefox](https://www.mozilla.org/en-US/firefox/): ブラウザ
- [Fiddler](https://www.telerik.com/fiddler): Webデバッグプロキシ
- [GitLab HAR Recorder](https://gitlab.com/gitlab-org/security-products/har-recorder): コマンドライン

> [!warning] HARファイルには、認証トークン、APIキー、セッションクッキーなどの機密情報が含まれる場合があります。HARファイルの内容をリポジトリに追加する前に確認してください。

### HARファイルを使用したAPIセキュリティテストのスキャン {#api-security-testing-scanning-with-a-har-file}

ターゲットAPIのテストに関する情報を提供するHARファイルを使用するようにAPIセキュリティテストを構成するには:

1. ご自身の`.gitlab-ci.yml`ファイルに[`API-Security.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)を[インクルード](../../../../ci/yaml/_index.md#includetemplate)します。

1. The [設定ファイル](variables.md#configuration-files)には、異なるチェックが有効化された複数のテストプロファイルが定義されています。`Quick`プロファイルから始めます。このプロファイルでのテストは迅速に完了し、設定の検証を容易にします。

   `.gitlab-ci.yml`ファイルに`APISEC_PROFILE` CI/CD変数を追加してプロファイルを提供します。

1. HARファイルの場所を提供します。場所はパスまたはURLとして提供できます。`APISEC_HAR`変数を追加して場所を指定します。

1. ターゲットAPIインスタンスのベースURLも必要です。`APISEC_TARGET_URL`変数または`environment_url.txt`ファイルを使用して提供します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加することは、動的環境でのテストに非常に役立ちます。GitLab CI/CDパイプライン中に動的に作成されたアプリに対してAPIセキュリティテストを実行するには、アプリのURLを`environment_url.txt`ファイルに保持させます。APIセキュリティテストは、そのファイルを自動的に解析して、スキャンターゲットを見つけます。この例は、GitLabの[Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)で確認できます。

HARファイルを使用する完全な設定例:

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

これは、APIセキュリティテストの最小設定です。ここから、次のことができます:

- 最初の[スキャン](#running-your-first-scan)を実行します。
- [認証](customizing_analyzer_settings.md#authentication)を追加します。
- [誤検出の処理](#handling-false-positives)について学びます。

## GraphQLのスキーマ {#graphql-schema}

{{< history >}}

- GraphQLのスキーマのサポートは、GitLab 15.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/352780)。

{{< /history >}}

GraphQLは、ご自身のAPIのクエリ言語であり、REST APIに代わるものです。APIセキュリティテストは、GraphQLエンドポイントを複数の方法でテストすることをサポートします:

- GraphQLのスキーマを使用してテストします。GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352780)されました。
- GraphQLクエリの記録 (HAR) を使用してテストします。
- Postman Collectionに含まれるGraphQLクエリを使用してテストします。

このセクションでは、GraphQLのスキーマを使用してテストする方法をドキュメント化します。APIセキュリティテストにおけるGraphQLのスキーマのサポートは、[イントロスペクション](https://graphql.org/learn/introspection/)をサポートするエンドポイントからスキーマをクエリすることができます。イントロスペクションは、GraphiQLのようなツールが機能するようにデフォルトで有効になっています。イントロスペクションを有効にする方法の詳細については、ご自身のGraphQLフレームワークドキュメントを参照してください。

### GraphQLエンドポイントURLを使用したAPIセキュリティテストのスキャン {#api-security-testing-scanning-with-a-graphql-endpoint-url}

APIセキュリティテストにおけるGraphQLのサポートは、GraphQLエンドポイントからスキーマをクエリすることができます。

> [!note]このメソッドが正しく機能するには、GraphQLエンドポイントがイントロスペクションクエリをサポートしている必要があります。

ターゲットAPIのテストに関する情報を提供するGraphQLエンドポイントURLを使用するようにAPIセキュリティテストを構成するには:

1. ご自身の`.gitlab-ci.yml`ファイルに[`API-Security.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)を[インクルード](../../../../ci/yaml/_index.md#includetemplate)します。

1. GraphQLエンドポイントへのパスを提供します（例: `/api/graphql`）。`APISEC_GRAPHQL`変数を追加して場所を指定します。

1. ターゲットAPIインスタンスのベースURLも必要です。`APISEC_TARGET_URL`変数または`environment_url.txt`ファイルを使用して提供します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加することは、動的環境でのテストに非常に役立ちます。詳細については、[動的環境ソリューション](../troubleshooting.md#dynamic-environment-solutions)を参照してください。

GraphQLエンドポイントパスを使用する完全な設定例:

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

これは、APIセキュリティテストの最小設定です。ここから、次のことができます:

- 最初の[スキャン](#running-your-first-scan)を実行します。
- [認証](customizing_analyzer_settings.md#authentication)を追加します。
- [誤検出の処理](#handling-false-positives)について学びます。

### GraphQLのスキーマファイルを使用したAPIセキュリティテストのスキャン {#api-security-testing-scanning-with-a-graphql-schema-file}

APIセキュリティテストでは、イントロスペクションが無効になっているGraphQLエンドポイントを理解しテストするために、GraphQLのスキーマファイルを使用できます。GraphQLのスキーマファイルを使用するには、イントロスペクションJSON形式である必要があります。GraphQLのスキーマは、オンラインのサードパーティツール ([https://transform.tools/graphql-to-introspection-json](https://transform.tools/graphql-to-introspection-json)) を使用して、イントロスペクションJSON形式に変換できます。

ターゲットAPIのテストに関する情報を提供するGraphQLのスキーマファイルを使用するようにAPIセキュリティテストを構成するには:

1. ご自身の`.gitlab-ci.yml`ファイルに[`API-Security.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)を[インクルード](../../../../ci/yaml/_index.md#includetemplate)します。

1. GraphQLエンドポイントのパスを提供します（例: `/api/graphql`）。`APISEC_GRAPHQL`変数を追加してパスを指定します。

1. GraphQLのスキーマファイルの場所を提供します。場所はパスまたはURLとして提供できます。`APISEC_GRAPHQL_SCHEMA`変数を追加して場所を指定します。

1. ターゲットAPIインスタンスのベースURLも必要です。`APISEC_TARGET_URL`変数または`environment_url.txt`ファイルを使用して提供します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加することは、動的環境でのテストに非常に役立ちます。詳細については、[動的環境ソリューション](../troubleshooting.md#dynamic-environment-solutions)を参照してください。

GraphQLのスキーマファイルを使用する完全な設定例:

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

GraphQLのスキーマファイルURLを使用する完全な設定例:

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

これは、APIセキュリティテストの最小設定です。ここから、次のことができます:

- 最初の[スキャン](#running-your-first-scan)を実行します。
- [認証](customizing_analyzer_settings.md#authentication)を追加します。
- [誤検出の処理](#handling-false-positives)について学びます。

## Postman Collection {#postman-collection}

The [Postman API Client](https://www.postman.com/product/api-client/)は、開発者やテスターがさまざまな種類のAPIを呼び出すために使用する人気のツールです。API定義は、APIセキュリティテストで使用するために、[Postman Collectionファイルとしてエクスポートすることができます](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)。エクスポートする際は、サポートされているPostman Collectionのバージョン（v2.0またはv2.1）を選択してください。

GitLab APIセキュリティテストスキャナーで使用する場合、Postman Collectionには、有効なデータでテストするWeb APIの定義が含まれている必要があります。APIセキュリティテストスキャナーは、すべてのAPI定義を抽出し、それらを使用してテストを実行します。

> [!warning] Postman Collectionファイルには、認証トークン、APIキー、セッションクッキーなどの機密情報が含まれている場合があります。Postman Collectionファイルの内容をリポジトリに追加する前に確認してください。

### Postman Collectionファイルを使用したAPIセキュリティテストのスキャン {#api-security-testing-scanning-with-a-postman-collection-file}

ターゲットAPIのテストに関する情報を提供するPostman Collectionファイルを使用するようにAPIセキュリティテストを構成するには:

1. [`API-Security.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)を[インクルード](../../../../ci/yaml/_index.md#includetemplate)します。

1. The [設定ファイル](variables.md#configuration-files)には、異なるチェックが有効化された複数のテストプロファイルが定義されています。`Quick`プロファイルから始めます。このプロファイルでのテストは迅速に完了し、設定の検証を容易にします。

   `.gitlab-ci.yml`ファイルに`APISEC_PROFILE` CI/CD変数を追加してプロファイルを提供します。

1. Postman Collectionファイルの場所をファイルまたはURLとして提供します。`APISEC_POSTMAN_COLLECTION`変数を追加して場所を指定します。

1. ターゲットAPIインスタンスのベースURLも必要です。`APISEC_TARGET_URL`変数または`environment_url.txt`ファイルを使用して提供します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加することは、動的環境でのテストに非常に役立ちます。GitLab CI/CDパイプライン中に動的に作成されたアプリに対してAPIセキュリティテストを実行するには、アプリのURLを`environment_url.txt`ファイルに保持させます。APIセキュリティテストは、そのファイルを自動的に解析して、スキャンターゲットを見つけます。この例は、GitLabの[Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)で確認できます。

Postman Collectionを使用する完全な設定例:

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

これは、APIセキュリティテストの最小設定です。ここから、次のことができます:

- 最初の[スキャン](#running-your-first-scan)を実行します。
- [認証](customizing_analyzer_settings.md#authentication)を追加します。
- [誤検出の処理](#handling-false-positives)について学びます。

### Postman変数 {#postman-variables}

{{< history >}}

- Postman Environmentファイル形式のサポートは、GitLab 15.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)。
- 複数の変数ファイルのサポートは、GitLab 15.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)。
- Postman変数のスコープのサポート: グローバルと環境はGitLab 15.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)。

{{< /history >}}

#### Postman Clientの変数 {#variables-in-postman-client}

Postmanでは、開発者がリクエストのさまざまな部分で使用できるプレースホルダーを定義できます。これらのプレースホルダーは、[変数の使用](https://learning.postman.com/docs/sending-requests/variables/variables/#using-variables)で説明されているように変数と呼ばれます。変数を使用して、リクエストとスクリプトで値を保存および再利用できます。例えば、Collectionを編集してドキュメントに変数を追加できます:

![Edit collection variable tab View](img/dast_api_postman_collection_edit_variable_v18_5.png)

または、Environmentに変数を追加することもできます:

![Edit environment variables View](img/dast_api_postman_environment_edit_variable_v18_5.png)

その後、URL、ヘッダーなどのセクションで変数を使用できます:

![Edit request using variables View](img/dast_api_postman_request_edit_v18_5.png)

Postmanは、優れたUXエクスペリエンスを持つ基本的なクライアントツールから、スクリプトでAPIをテストしたり、二次リクエストをトリガーする複雑なCollectionを作成したり、途中で変数を設定したりできる、より複雑なエコシステムへと成長しました。Postmanエコシステムのすべての機能がサポートされているわけではありません。例えば、スクリプトはサポートされていません。Postmanサポートの主な焦点は、Postman Clientで使用されるPostman Collectionの定義と、ワークスペース、環境、およびCollection自体で定義されている関連変数をインジェストすることです。

Postmanでは、異なるスコープで変数を作成できます。各スコープは、Postmanツールで異なる表示レベルを持ちます。例えば、すべての操作定義とワークスペースから参照できる_グローバル環境_スコープで変数を作成できます。また、特定の_環境_スコープで変数を作成することもできます。これは、特定の環境が使用するために選択された場合にのみ表示され、使用されます。一部のスコープは常に利用できるわけではありません。例えば、PostmanエコシステムではPostman Clientでリクエストを作成できますが、これらのリクエストには_ローカル_スコープはありませんが、テストスクリプトにはあります。

Postmanの変数スコープは、難しいトピックであり、誰もが精通しているわけではありません。先に進む前に、Postmanドキュメントの[Variable Scopes](https://learning.postman.com/docs/sending-requests/variables/variables/#variable-scopes)をお読みください。

前述のとおり、さまざまな変数スコープがあり、それぞれに目的があり、Postmanドキュメントにさらなる柔軟性をもたらすために使用できます。Postmanドキュメントによると、変数の値がどのように計算されるかについて重要な注意点があります:

> [!note]同じ名前の変数が2つの異なるスコープで宣言されている場合、最も狭いスコープの変数に格納されている値が使用されます。例えば、グローバル変数`username`とローカル変数`username`がある場合、リクエストの実行時にはローカル値が使用されます。

以下は、Postman ClientとAPIセキュリティテストによってサポートされている変数スコープの概要です:

- **Global Environment (Global) scope**は、ワークスペース全体で利用できる特殊な事前定義済み環境です。_グローバル環境_スコープを_グローバル_スコープと呼ぶこともできます。Postman Clientでは、グローバル環境をJSONファイルにエクスポートでき、これはAPIセキュリティテストで使用できます。
- **環境スコープ**は、Postman Clientでユーザーが作成した変数の名前付きグループです。Postman Clientは、グローバル環境と共に単一のアクティブな環境をサポートします。アクティブなユーザー作成環境で定義された変数は、グローバル環境で定義された変数よりも優先されます。Postman Clientでは、ご自身の環境をJSONファイルにエクスポートでき、これはAPIセキュリティテストで使用できます。
- **Collection scope**は、特定のCollectionで宣言された変数のグループです。Collection変数は、宣言されているCollectionと、ネストされたリクエストまたはCollectionで利用できます。Collectionスコープで定義された変数は、_グローバル環境_スコープおよび_環境_スコープよりも優先されます。Postman Clientは1つまたは複数のCollectionをJSONファイルにエクスポートでき、このJSONファイルには選択されたCollection、リクエスト、およびCollection変数が含まれます。
- **API security testing scope**は、APIセキュリティテストによって追加された新しいスコープで、ユーザーが追加の変数を提供したり、他のサポートされているスコープで定義された変数をオーバーライドしたりできるようにします。このスコープはPostmanではサポートされていません。_APIセキュリティテストスコープ_変数は、[カスタムJSONファイル形式](#api-security-testing-scope-custom-json-file-format)を使用して提供されます。
  - 環境またはCollectionで定義された値をオーバーライドする
  - スクリプトから変数を定義する
  - サポートされていない_データ_スコープから単一のデータ行を定義する
- **Data scope**は、名前と値がJSONまたはCSVファイルから取得される変数のグループです。[Newman](https://learning.postman.com/docs/collections/using-newman-cli/command-line-integration-with-newman/)や[Postman Collection Runner](https://learning.postman.com/docs/collections/running-collections/intro-to-collection-runs/)のようなPostman Collection Runnerは、JSONまたはCSVファイルにエントリがある回数だけ、Collection内のリクエストを実行します。これらの変数の優れたユースケースは、Postmanのスクリプトを使用してテストを自動化することです。APIセキュリティテストは、CSVまたはJSONファイルからのデータ読み取りを**not**。
- **Local scope**は、Postmanスクリプトで定義される変数です。APIセキュリティテストは、Postmanスクリプト、および拡張してスクリプトで定義された変数を**not**。スクリプトで定義された変数の値は、サポートされているいずれかのスコープまたはカスタムJSON形式で定義することで、引き続き提供できます。

すべてのスコープがAPIセキュリティテストでサポートされているわけではなく、スクリプトで定義された変数はサポートされていません。次の表は、最も広いスコープから最も狭いスコープの順に並べられています。

| スコープ                      | Postman | APIセキュリティテスト | コメント                                    |
|----------------------------|:-------:|:--------------------:|:-------------------------------------------|
| Global Environment         |   √   |         √          | 特殊な事前定義済み環境            |
| 環境                |   √   |         √          | 名前付き環境                         |
| Collection                 |   √   |         √          | ご自身のPostman Collectionで定義されています         |
| APIセキュリティテストスコープ |   いいえ    |         √          | APIセキュリティテストによって追加されたカスタムスコープ |
| Data                       |   √   |          いいえ          | CSVまたはJSON形式の外部ファイル       |
| Local                      |   √   |          いいえ          | スクリプトで定義された変数               |

異なるスコープで変数を定義およびエクスポートする方法の詳細については、以下を参照してください:

- [Collection変数の定義](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-collection-variables)
- [環境変数の定義](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-environment-variables)
- [グローバル変数の定義](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-global-variables)

##### Postman Clientからのエクスポート {#exporting-from-postman-client}

Postman Clientでは、さまざまなファイル形式をエクスポートできます。例えば、Postman CollectionやPostman Environmentをエクスポートできます。エクスポートされた環境は、グローバル環境（常に利用可能）であることも、以前に作成したカスタム環境であることもできます。Postman Collectionをエクスポートする場合、_Collection_と_ローカル_スコープの変数の宣言のみが含まれる場合があります。 _環境_スコープの変数は含まれません。

_環境_スコープの変数の宣言を取得するには、その時点で特定の環境をエクスポートする必要があります。エクスポートされた各ファイルには、選択された環境の変数のみが含まれます。

異なるサポートされているスコープでの変数のエクスポートの詳細については、以下を参照してください:

- [Collectionのエクスポート](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)
- [環境のエクスポート](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [グローバル環境のダウンロード](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)

#### APIセキュリティテストスコープ、カスタムJSONファイル形式 {#api-security-testing-scope-custom-json-file-format}

カスタムJSONファイル形式は、各オブジェクトプロパティが変数名を表し、プロパティ値が変数値を表すJSONオブジェクトです。このファイルは、ご自身の好きなテキストエディタを使用して作成することも、パイプライン内の以前のジョブによって生成することもできます。

この例では、APIセキュリティテストスコープで2つの変数`base_url`と`token`を定義しています:

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### APIセキュリティテストでのスコープの使用 {#using-scopes-with-api-security-testing}

スコープ (_グローバル_、_環境_、_Collection_、および_GitLab APIセキュリティテスト_) は、[GitLab 15.1以降](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)でサポートされています。GitLab 15.0以前では、_Collection_と_GitLab APIセキュリティテスト_のスコープのみがサポートされています。

次の表は、スコープファイル/URLをAPIセキュリティテストの設定変数にマッピングするためのクイック参照を提供します:

| スコープ              |  提供方法 |
| ------------------ | --------------- |
| Global environment | APISEC_POSTMAN_COLLECTION_VARIABLES |
| 環境        | APISEC_POSTMAN_COLLECTION_VARIABLES |
| Collection         | APISEC_POSTMAN_COLLECTION           |
| APIセキュリティテストスコープ | APISEC_POSTMAN_COLLECTION_VARIABLES |
| Data               | サポートされていません   |
| Local              | サポートされていません   |

Postman Collectionドキュメントには、_Collection_スコープの変数が自動的に含まれます。Postman Collectionは、設定変数`APISEC_POSTMAN_COLLECTION`を使用して提供されます。この変数は、単一の[エクスポートされたPostman Collection](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)に設定できます。

他のスコープの変数は、`APISEC_POSTMAN_COLLECTION_VARIABLES`設定変数を介して提供されます。この設定変数は、[GitLab 15.1以降](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)でカンマ (`,`) 区切りのファイルリストをサポートします。GitLab 15.0以前では、単一のファイルのみをサポートしていました。提供されるファイルの順序は重要ではありません。ファイルがスコープ情報を提供するためです。

設定変数`APISEC_POSTMAN_COLLECTION_VARIABLES`は、以下に設定できます:

- [エクスポートされたGlobal environment](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)
- [エクスポートされた環境](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [API security testingカスタムJSON形式](#api-security-testing-scope-custom-json-file-format)

#### 未定義のPostman変数 {#undefined-postman-variables}

APIセキュリティテストエンジンが、ご自身のPostman Collectionファイルが使用しているすべての変数参照を見つけられない可能性があります。いくつかのケースが考えられます:

- ご自身が_データ_スコープまたは_ローカル_スコープの変数を使用しており、前述のとおりこれらのスコープはAPIセキュリティテストでサポートされていません。したがって、これらの変数の値が[APIセキュリティテストスコープ](#api-security-testing-scope-custom-json-file-format)を介して提供されていないと仮定すると、_データ_スコープと_ローカル_スコープの変数の値は未定義です。
- 変数名が正しく入力されておらず、定義された変数と一致しません。
- Postman Clientは、APIセキュリティテストでサポートされていない新しい動的変数をサポートしています。

可能な場合、APIセキュリティテストは、未定義の変数を扱う際にPostman Clientと同じ動作に従います。変数参照のテキストは同じままで、テキスト置換は行われません。同じ動作は、サポートされていないすべての動的変数にも適用されます。

例えば、Postman Collection内のリクエスト定義が変数`{{full_url}}`を参照し、その変数が見つからない場合、値`{{full_url}}`のまま変更されません。

#### 動的Postman変数 {#dynamic-postman-variables}

ユーザーがさまざまなスコープレベルで定義できる変数に加えて、Postmanには_動的_変数と呼ばれる事前定義された変数のセットがあります。[_動的_変数](https://learning.postman.com/docs/tests-and-scripts/write-scripts/variables-list/)はすでに定義されており、その名前にはドル記号 (`$`) がプレフィックスとして付けられています（例: `$guid`）。_動的_変数は他の変数と同様に使用でき、Postman Clientでは、リクエスト/Collectionの実行中にランダムな値を生成します。

APIセキュリティテストとPostmanの重要な違いは、APIセキュリティテストが同じ動的変数の各使用に対して同じ値を返すことです。これは、同じ動的変数を使用するたびにランダムな値を返すPostman Clientの動作とは異なります。言い換えれば、APIセキュリティテストは動的変数に静的な値を使用し、Postmanはランダムな値を使用します。

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

この例では、[Postman Clientから_グローバル_スコープがエクスポート](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)され、`global-scope.json`としてAPIセキュリティテストに`APISEC_POSTMAN_COLLECTION_VARIABLES`設定変数を介して提供されます。

`APISEC_POSTMAN_COLLECTION_VARIABLES`の使用例を以下に示します:

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

#### 例: Environment Scope {#example-environment-scope}

この例では、[Postman Clientから_環境_スコープがエクスポート](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)され、`environment-scope.json`としてAPIセキュリティテストに`APISEC_POSTMAN_COLLECTION_VARIABLES`設定変数を介して提供されます。

`APISEC_POSTMAN_COLLECTION_VARIABLES`の使用例を以下に示します:

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

#### 例: Collection Scope {#example-collection-scope}

_Collection_スコープの変数は、エクスポートされたPostman Collectionファイルに含まれ、`APISEC_POSTMAN_COLLECTION`設定変数を介して提供されます。

`APISEC_POSTMAN_COLLECTION`の使用例を以下に示します:

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

#### 例: API security testing scope {#example-api-security-testing-scope}

APIセキュリティテストスコープは、APIセキュリティテストでサポートされていない_データ_スコープと_ローカル_スコープの変数を定義すること、および別のスコープで定義された既存の変数の値を変更することという2つの主な目的で使用されます。APIセキュリティテストスコープは、`APISEC_POSTMAN_COLLECTION_VARIABLES`設定変数を介して提供されます。

`APISEC_POSTMAN_COLLECTION_VARIABLES`の使用例を以下に示します:

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

ファイル`dast-api-scope.json`は、[カスタムJSONファイル形式](#api-security-testing-scope-custom-json-file-format)を使用します。このJSONは、プロパティ用のキー/バリューペアを持つオブジェクトです。キーは変数の名前であり、値は変数の値です。例: 

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### 例: 複数のスコープ {#example-multiple-scopes}

この例では、_グローバル_スコープ、_環境_スコープ、および_Collection_スコープが構成されています。最初のステップは、さまざまなスコープをエクスポートすることです。

- [_グローバル_スコープをエクスポート](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)して`global-scope.json`として保存します
- [_環境_スコープをエクスポート](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)して`environment-scope.json`として保存します
- _Collection_スコープを含むPostman Collectionをエクスポートして`postman-collection.json`として保存します

Postman Collectionは`APISEC_POSTMAN_COLLECTION`変数を使用して提供され、他のスコープは`APISEC_POSTMAN_COLLECTION_VARIABLES`を使用して提供されます。APIセキュリティテストは、各ファイルで提供されたデータを使用して、提供されたファイルがどのスコープに一致するかを識別できます。

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

#### 例: 変数の値の変更 {#example-changing-a-variables-value}

エクスポートされたスコープを使用する場合、APIセキュリティテストで使用するために変数の値を変更する必要があることがよくあります。例えば、_Collection_スコープの変数に`v2`という値を持つ`api_version`という名前の変数が含まれている場合でも、テストには`v1`の値が必要です。エクスポートされたCollectionを変更して値を変更する代わりに、APIセキュリティテストスコープを使用してその値を変更できます。これは、_APIセキュリティテスト_スコープが他のすべてのスコープよりも優先されるため機能します。

_Collection_スコープの変数は、エクスポートされたPostman Collectionファイルに含まれ、`APISEC_POSTMAN_COLLECTION`設定変数を介して提供されます。

APIセキュリティテストスコープは、`APISEC_POSTMAN_COLLECTION_VARIABLES`設定変数を介して提供されます。ただし、まずファイルを作成します。ファイル`dast-api-scope.json`は、[カスタムJSONファイル形式](#api-security-testing-scope-custom-json-file-format)を使用します。このJSONは、プロパティ用のキー/バリューペアを持つオブジェクトです。キーは変数の名前であり、値は変数の値です。例: 

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

#### 例: 複数のスコープを持つ変数の値を変更する {#example-changing-a-variables-value-with-multiple-scopes}

エクスポートされたスコープを使用する場合、APIセキュリティテストで使用するために変数の値を変更する必要があることがよくあります。例えば、_環境_スコープに`v2`という値を持つ`api_version`という名前の変数が含まれている場合でも、テストには`v1`の値が必要です。エクスポートされたファイルを変更して値を変更する代わりに、APIセキュリティテストスコープを使用できます。これは、_APIセキュリティテスト_スコープが他のすべてのスコープよりも優先されるため機能します。

この例では、_グローバル_スコープ、_環境_スコープ、_Collection_スコープ、および_APIセキュリティテスト_スコープが構成されています。最初のステップは、さまざまなスコープをエクスポートして作成することです。

- [_グローバル_スコープをエクスポート](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)して`global-scope.json`として保存します
- [_環境_スコープをエクスポート](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)して`environment-scope.json`として保存します
- _Collection_スコープを含むPostman Collectionをエクスポートして`postman-collection.json`として保存します

APIセキュリティテストスコープは、[カスタムJSONファイル形式](#api-security-testing-scope-custom-json-file-format)を使用してファイル`dast-api-scope.json`を作成することで使用されます。このJSONは、プロパティ用のキー/バリューペアを持つオブジェクトです。キーは変数の名前であり、値は変数の値です。例: 

```json
{
  "api_version": "v1"
}
```

Postman Collectionは`APISEC_POSTMAN_COLLECTION`変数を使用して提供され、他のスコープは`APISEC_POSTMAN_COLLECTION_VARIABLES`を使用して提供されます。APIセキュリティテストは、各ファイルで提供されたデータを使用して、提供されたファイルがどのスコープに一致するかを識別できます。

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

## 最初のスキャンの実行 {#running-your-first-scan}

正しく構成されている場合、CI/CDパイプラインには`dast`ステージと`dast_api`ジョブが含まれます。ジョブは、無効な設定が提供された場合にのみ失敗します。通常の操作中、テスト中に脆弱性が識別されたとしても、ジョブは常に成功します。

脆弱性は、**セキュリティ**パイプラインタブにスイート名とともに表示されます。リポジトリのデフォルトブランチに対してテストを実行すると、APIセキュリティテストの脆弱性は、セキュリティおよびコンプライアンスの脆弱性レポートにも表示されます。

過剰な数の脆弱性がレポートされるのを防ぐために、APIセキュリティテストスキャナーは、操作ごとにレポートする脆弱性の数を制限します。

## APIセキュリティテストの脆弱性を表示する {#viewing-api-security-testing-vulnerabilities}

APIセキュリティテストアナライザーは、収集されて[GitLab脆弱性画面に脆弱性を取り込むために](#view-details-of-an-api-security-testing-vulnerability)使用されるJSONレポートを生成します。

[誤検出の処理](#handling-false-positives)に関する情報については、誤検出の数を制限するために行うことができる設定変更を参照してください。

### APIセキュリティテストの脆弱性の詳細を表示する {#view-details-of-an-api-security-testing-vulnerability}

脆弱性の詳細を表示するには、次の手順に従います:

1. プロジェクトまたはマージリクエストで脆弱性を表示できます:

   - プロジェクトで、プロジェクトの**セキュリティ** > **脆弱性レポート**ページに移動します。このページには、デフォルトブランチからの脆弱性のみが表示されます。
   - マージリクエストで、マージリクエストの**セキュリティ**セクションに移動し、**全て展開**ボタンを選択します。APIセキュリティテストの脆弱性は、**DAST detected N potential vulnerabilities**とラベル付けされたセクションで利用できます。タイトルを選択して脆弱性の詳細を表示します。

1. 脆弱性のタイトルを選択して詳細を表示します。以下の表にこれらの詳細を示します。

   | フィールド               | 説明                                                                             |
   |:--------------------|:----------------------------------------------------------------------------------------|
   | 説明         | 変更された内容を含む脆弱性の説明。                           |
   | プロジェクト             | 脆弱性が検出されたネームスペースとプロジェクト。                          |
   | 方法              | 脆弱性の検出に使用されたHTTPメソッド。                                           |
   | URL                 | 脆弱性が検出されたURL。                                            |
   | リクエスト             | 脆弱性を引き起こしたHTTPリクエスト。                                         |
   | 変更されていないレスポンス | 変更されていないリクエストからのレスポンス。典型的な動作中のレスポンスは、変更されていないレスポンスのように見えます。|
   | 実際のレスポンス     | テストリクエストから受信したレスポンス。                                                    |
   | 証拠            | GitLabが脆弱性が発生したと判断した方法。                                         |
   | 識別子         | この脆弱性を見つけるために使用されたAPIセキュリティテストチェック。                         |
   | 重大度            | 脆弱性の重大度。                                                          |
   | スキャナータイプ        | テストの実行に使用されるスキャナー。                                                        |

### セキュリティダッシュボード {#security-dashboard}

セキュリティダッシュボードは、グループ、プロジェクト、パイプライン内のすべての脆弱性の概要を把握するのに適した場所です。詳細については、[セキュリティダッシュボードドキュメント](../../security_dashboard/_index.md)を参照してください。

### 脆弱性との対話 {#interacting-with-the-vulnerabilities}

脆弱性が見つかったら、それと対話できます。[脆弱性への対処方法](../../vulnerabilities/_index.md)の詳細を読み取ります。

### 誤検出の処理 {#handling-false-positives}

誤検出は、いくつかの方法で処理できます:

- 脆弱性を無視する。
- 一部のチェックには、脆弱性が識別されたときに検出するいくつかの方法があり、これらは_アサーション_と呼ばれます。アサーションは、オフにして構成することもできます。例えば、APIセキュリティテストスキャナーは、デフォルトでHTTPステータスcodeを使用して、何かが実際の問題であるかどうかを特定するのに役立てます。テスト中にAPIが500エラーを返すと、これは脆弱性を作成します。これは、一部のフレームワークが頻繁に500エラーを返すため、常に望ましいとは限りません。
- 誤検出を生成しているチェックをオフにします。これにより、チェックが脆弱性を生成するのを防ぎます。チェックの例には、SQLインジェクションチェックとJSON Hijackingチェックがあります。

#### チェックをオフにする {#turn-off-a-check}

チェックは特定のタイプのテストを実行し、特定の設定プロファイルでオン/オフを切り替えることができます。提供された[設定ファイル](variables.md#configuration-files)は、使用できるいくつかのプロファイルを定義しています。設定ファイル内のプロファイル定義には、スキャン中にアクティブなすべてのチェックがリストされています。特定のチェックをオフにするには、設定ファイル内のプロファイル定義から削除します。プロファイルは、設定ファイルの`Profiles`セクションで定義されています。

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

JSON Hijacking Checkをオフにするには、これらの行を削除します:

```yaml
          - Name: JsonHijackingCheck
```

これにより、次のYAMLになります:

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

アサーションは、チェックによって生成されたテスト内の脆弱性を検出します。多くのチェックは、ログ分析、レスポンス分析、ステータスcodeなど、複数のアサーションをサポートしています。脆弱性が見つかると、使用されたアサーションが提供されます。どのAssertationがデフォルトでオンになっているかを識別するには、設定ファイルのChecksデフォルト設定を参照してください。セクションは`Checks`と呼ばれます。

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

ここでは、3つのアサーションがデフォルトでオンになっていることがわかります。誤検出の一般的な原因は`StatusCodeAssertion`です。これをオフにするには、`Profiles`セクションでその設定を変更します。この例では、他の2つのアサーション（`LogAnalysisAssertion`、`ResponseAnalysisAssertion`）のみを提供します。これにより、`SqlInjectionCheck`が`StatusCodeAssertion`を使用するのを防ぎます:

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
