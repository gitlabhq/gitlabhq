---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アナライザーを有効にする
---

前提要件: 

- 次のWeb APIタイプのうちの1つ:
  - REST API
  - SOAP
  - GraphQL
  - フォームの本文、JSON、またはXML
- テストするAPIを提供するための次のアセットのいずれか:
  - OpenAPI v2またはv3 API定義
  - テスト対象のAPIリクエストのHTTPアーカイブ（HAR）
  - Postman Collection v2.0またはv2.1

  {{< alert type="warning" >}}

  **一度もない**本番環境サーバーに対してファズテストを実行しないでください。APIが実行できる機能を実行できるだけでなく、APIでバグをトリガーする可能性もあります。これには、データを変更および削除するなどのアクションが含まれます。テストサーバーに対してのみファジングを実行してください。

  {{< /alert >}}

Web APIファジングを有効にするには、Web APIファジング設定フォームを使用します。

- 手動での設定手順については、APIタイプに応じて、それぞれのセクションを参照してください:
  - [OpenAPI仕様](#openapi-specification)
  - [GraphQLスキーマ](#graphql-schema)
  - [HTTPアーカイブ（HAR）](#http-archive-har)
  - [Postman Collection](#postman-collection)
- それ以外の場合は、[Web APIファジング設定フォーム](#web-api-fuzzing-configuration-form)を参照してください。

ファジング設定ファイルは、リポジトリの`.gitlab`ディレクトリに存在する必要があります。

## Web APIファジング設定フォーム {#web-api-fuzzing-configuration-form}

ファジング設定フォームを使用すると、プロジェクトのファジング設定を作成または変更できます。このフォームを使用すると、最も一般的なファジングオプションの値を選択し、GitLab CI/CD設定に貼り付けることができるYAMLスニペットを作成できます。

### UIでWeb APIファジングを設定する {#configure-web-api-fuzzing-in-the-ui}

ファジングスニペットを生成するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **セキュリティ** > **セキュリティ設定**を選択します。
1. **APIファジング**行で、**Enable API Fuzzing**（APIファジング）を有効にする]を選択します。
1. フィールドに入力します。詳細については、[利用可能なCI/CD変数](variables.md)を参照してください。
1. **コードスニペットの生成**を選択します。フォームで選択したオプションに対応するYAMLスニペットがモーダルで開きます。
1. 次のいずれかを実行します:
   1. スニペットをクリップボードにコピーするには、**コードのコピーのみ**を選択します。
   1. あなたのプロジェクトの`.gitlab-ci.yml`ファイルにスニペットを追加するには、**コードをコピーして`.gitlab-ci.yml`ファイルを開く**を選択してください。パイプラインエディタが開きます。
      1. スニペットを`.gitlab-ci.yml`ファイルに貼り付けます。
      1. **Lint**タブを選択して、編集した`.gitlab-ci.yml`ファイルが有効であることを確認します。
      1. **編集**タブを選択し、次に**変更をコミットする**を選択します。

スニペットが`.gitlab-ci.yml`ファイルにコミットされると、パイプラインにファジングジョブが含まれます。

## 仕様 {#openapi-specification}

[OpenAPI仕様](https://www.openapis.org/)（以前のSwagger仕様）は、REST APIのAPI記述形式です。このセクションでは、仕様を使用してファジングを設定し、テスト対象のターゲットAPIに関する情報を提供する方法について説明します。仕様は、ファイルシステムの参照またはURLとして提供されます。JSON形式とYAML形式の両方のOpenAPI形式がサポートされています。

ファジングは、OpenAPIドキュメントを使用してリクエスト本文を生成します。リクエスト本文が必要な場合、本文の生成は次の本文タイプに制限されます:

- `application/x-www-form-urlencoded`
- `multipart/form-data`
- `application/json`
- `application/xml`

## OpenAPIとメディアタイプ {#openapi-and-media-types}

メディアタイプ（以前はMIMEタイプと呼ばれていました）は、送信されるファイル形式および形式コンテンツの識別子です。OpenAPIドキュメントを使用すると、特定の操作で異なるメディアタイプを受け入れることができることを指定できるため、特定のリクエストで異なるファイルコンテンツを使用してデータを送信できます。たとえば、ユーザーデータを更新する`PUT /user`操作では、XML（メディアタイプ`application/xml`）またはJSON（メディアタイプ`application/json`）形式のデータを受け入れることができます。OpenAPI 2.xでは、受け入れられるメディアタイプをグローバルまたは操作ごとに指定でき、OpenAPI 3.xでは、操作ごとに受け入れられるメディアタイプを指定できます。ファジングは、リストされたメディアタイプをチェックし、サポートされている各メディアタイプのサンプルデータを生成しようとします。

- デフォルトの動作は、使用するサポートされているメディアタイプの1つを選択することです。最初にサポートされているメディアタイプがリストから選択されます。この動作は、設定可能です。

異なるメディアタイプ（たとえば、`application/json`と`application/xml`）を使用して同じ操作（たとえば、`POST /user`）をテストすることは、必ずしも望ましいとは限りません。たとえば、ターゲットアプリケーションがリクエストコンテンツタイプに関係なく同じコードを実行する場合、テストセッションの完了に時間がかかり、ターゲットアプリケーションに応じてリクエスト本文に関連する重複した脆弱性をレポートする可能性があります。

環境変数`FUZZAPI_OPENAPI_ALL_MEDIA_TYPES`を使用すると、特定の操作のリクエストを生成するときに、サポートされているすべてのメディアタイプを1つではなく使用するかどうかを指定できます。環境変数`FUZZAPI_OPENAPI_ALL_MEDIA_TYPES`が任意の値に設定されている場合、ファジングは、特定の操作で1つではなく、サポートされているすべてのメディアタイプのリクエストを生成しようとします。これにより、提供される各メディアタイプに対してテストが繰り返されるため、テストに時間がかかるようになります。

または、変数`FUZZAPI_OPENAPI_MEDIA_TYPES`を使用して、それぞれがテストされるメディアタイプのリストを提供します。複数のメディアタイプを指定すると、選択した各メディアタイプに対してテストが実行されるため、テストに時間がかかるようになります。環境変数`FUZZAPI_OPENAPI_MEDIA_TYPES`がメディアタイプのリストに設定されている場合、リクエストの作成時には、リストされたメディアタイプのみが含まれます。

`FUZZAPI_OPENAPI_MEDIA_TYPES`の複数のメディアタイプは、コロン（`:`）で区切る必要があります。たとえば、リクエストの生成をメディアタイプ`application/x-www-form-urlencoded`と`multipart/form-data`に制限するには、環境変数`FUZZAPI_OPENAPI_MEDIA_TYPES`を`application/x-www-form-urlencoded:multipart/form-data`に設定します。このリストでサポートされているメディアタイプのみがリクエストの作成時に含まれますが、サポートされていないメディアタイプは常にスキップされます。メディアタイプのテキストには、さまざまなセクションが含まれている場合があります。たとえば、`application/vnd.api+json; charset=UTF-8`は`type "/" [tree "."] subtype ["+" suffix]* [";" parameter]`の化合物です。パラメータは、リクエストの生成時にメディアタイプをフィルタリングする際には考慮されません。

環境変数`FUZZAPI_OPENAPI_ALL_MEDIA_TYPES`と`FUZZAPI_OPENAPI_MEDIA_TYPES`を使用すると、メディアタイプの処理方法を決定できます。これらの設定は相互に排他的です。両方が有効になっている場合、ファジングはエラーをレポートします。

### 仕様でWeb APIファジングを設定する {#configure-web-api-fuzzing-with-an-openapi-specification}

仕様を使用してGitLabでファジングを構成するには、次の手順に従います:

1. `fuzz`ステージングを`.gitlab-ci.yml`ファイルに追加します。

1. [次のものを含めます](../../../../ci/yaml/_index.md#includetemplate) [`API-Fuzzing.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)を`.gitlab-ci.yml`ファイルに追加します。

1. `FUZZAPI_PROFILE`CI/CD変数を`.gitlab-ci.yml`ファイルに追加して、プロファイルを提供します。プロファイルでは、実行するテストの回数を指定します。選択したプロファイルの`Quick-10`を代入します。詳細については、[ファジングプロファイル](customizing_analyzer_settings.md#api-fuzzing-profiles)を参照してください。

   ```yaml
   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. 仕様の場所を指定します。仕様は、ファイルまたはURLとして指定できます。`FUZZAPI_OPENAPI`変数を追加して場所を指定します。

1. ターゲットAPIインスタンスのベースURLを指定します。`FUZZAPI_TARGET_URL`変数または`environment_url.txt`ファイルのいずれかを使用します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加すると、動的な環境でテストするのに最適です。GitLab CI/CDパイプライン中に動的に作成されたアプリケーションに対してファジングを実行するには、アプリケーションが`environment_url.txt`ファイルにURLを保持するようにします。ファジングは、そのファイルを自動的に解析中して、スキャンターゲットを見つけます。[Auto DevOps CI YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)にその例があります。

仕様を使用した`.gitlab-ci.yml`ファイルの例:

   ```yaml
   stages:
     - fuzz

   include:
     - template: Security/API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_OPENAPI: test-api-specification.json
     FUZZAPI_TARGET_URL: http://test-deployment/
   ```

これは、ファジングの最小限の設定です。ここから、次のことができます:

- [最初のスキャンを実行する](#running-your-first-scan)。
- [認証](customizing_analyzer_settings.md#authentication)を追加します。
- [誤検出](#handling-false-positives)の処理方法について説明します。

ファジング設定オプションの詳細については、[利用可能なCI/CD変数](variables.md)を参照してください。

## HTTPアーカイブ（HAR） {#http-archive-har}

[HTTPアーカイブ形式（HAR）](http://www.softwareishard.com/blog/har-12-spec/)は、HTTPトランザクションを記録するためのアーカイブファイル形式です。GitLab API fuzzerとともに使用する場合、HARには、テストするWeb APIの呼び出しの記録が含まれている必要があります。API fuzzerは、すべてのリクエストを抽出し、それらを使用してテストを実行します。

HARファイルの作成方法など、詳細については、[HTTPアーカイブ形式](../create_har_files.md)を参照してください。

{{< alert type="warning" >}}

HARファイルには、認証トークン、APIキー、セッションクッキーなどの機密情報が含まれている場合があります。HARファイルの内容をリポジトリに追加する前に、確認することをお勧めします。

{{< /alert >}}

### HARファイルでWeb APIファジングを構成する {#configure-web-api-fuzzing-with-a-har-file}

HARファイルを使用するようにファジングを設定するには、次の手順に従います:

1. `fuzz`ステージングを`.gitlab-ci.yml`ファイルに追加します。

1. [次のものを含めます](../../../../ci/yaml/_index.md#includetemplate) [`API-Fuzzing.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)を`.gitlab-ci.yml`ファイルに追加します。

1. `FUZZAPI_PROFILE`CI/CD変数を`.gitlab-ci.yml`ファイルに追加して、プロファイルを提供します。プロファイルでは、実行するテストの回数を指定します。選択したプロファイルの`Quick-10`を代入します。詳細については、[ファジングプロファイル](customizing_analyzer_settings.md#api-fuzzing-profiles)を参照してください。

   ```yaml
   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. HAR仕様の場所を指定します。仕様は、ファイルまたはURLとして指定できます。`FUZZAPI_HAR`変数を追加して場所を指定します。

1. ターゲットAPIインスタンスのベースURLも必要です。`FUZZAPI_TARGET_URL`変数または`environment_url.txt`ファイルを使用して指定します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加すると、動的な環境でテストするのに最適です。GitLab CI/CDパイプライン中に動的に作成されたアプリケーションに対してファジングを実行するには、アプリケーションが`environment_url.txt`ファイルにドメインを保持するようにします。ファジングは、そのファイルを自動的に解析中して、スキャンターゲットを見つけます。[Auto DevOps CI YAMLのこの例](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)を参照してください。

HARファイルを使用した`.gitlab-ci.yml`ファイルの例:

   ```yaml
   stages:
     - fuzz

   include:
     - template: Security/API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_HAR: test-api-recording.har
     FUZZAPI_TARGET_URL: http://test-deployment/
   ```

この例は、ファジングの最小限の設定です。ここから、次のことができます:

- [最初のスキャンを実行する](#running-your-first-scan)。
- [認証](customizing_analyzer_settings.md#authentication)を追加します。
- [誤検出](#handling-false-positives)の処理方法について説明します。

ファジング設定オプションの詳細については、[利用可能なCI/CD変数](variables.md)を参照してください。

## GraphQLスキーマ {#graphql-schema}

{{< history >}}

- GraphQLスキーマのサポートは、[GitLab 15.4で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/352780)。

{{< /history >}}

GraphQLは、APIのクエリ言語であり、従来のREST APIの代替手段です。ファジングは、複数の方法でGraphQLエンドポイントのテストをサポートしています:

- GraphQLスキーマを使用したテスト。GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/352780)されました。
- GraphQLのクエリの記録（HAR）を使用したテスト。
- GraphQLのクエリを含むPostman Collectionを使用したテスト。

このセクションでは、GraphQLスキーマを使用したテスト方法について説明します。ファジングのGraphQLスキーマサポートは、イントロスペクションをサポートするエンドポイントからスキーマをクエリできます。イントロスペクションは、GraphiQLなどのツールが動作するようにデフォルトで有効になっています。

### GraphQLエンドポイントURLを使用したファジングスキャン {#api-fuzzing-scanning-with-a-graphql-endpoint-url}

ファジングのGraphQLサポートにより、GraphQLエンドポイントにスキーマをクエリできます。

{{< alert type="note" >}}

GraphQLエンドポイントは、このメソッドが正しく機能するために、イントロスペクションクエリをサポートしている必要があります。

{{< /alert >}}

ターゲットAPIに関する情報を提供するGraphQLエンドポイントURLを使用するようにファジングを設定するには、次の手順に従います:

1. [次のものを含めます](../../../../ci/yaml/_index.md#includetemplate) [`API-Fuzzing.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)を`.gitlab-ci.yml`ファイルに追加します。

1. GraphQLエンドポイントのパス（`/api/graphql`など）を指定します。`FUZZAPI_GRAPHQL`変数を追加して、パスを指定します。

1. ターゲットAPIインスタンスのベースURLも必要です。`FUZZAPI_TARGET_URL`変数または`environment_url.txt`ファイルを使用して指定します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加すると、動的な環境でテストするのに最適です。詳細については、ドキュメントの[動的な環境ソリューション](../troubleshooting.md#dynamic-environment-solutions)セクションを参照してください。

GraphQLエンドポイントURLを使用した構成の完了例:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

apifuzzer_fuzz:
  variables:
    FUZZAPI_GRAPHQL: /api/graphql
    FUZZAPI_TARGET_URL: http://test-deployment/
```

この例は、ファジングの最小限の設定です。ここから、次のことができます:

- [最初のスキャンを実行する](#running-your-first-scan)。
- [認証](customizing_analyzer_settings.md#authentication)を追加します。
- [誤検出](#handling-false-positives)の処理方法について説明します。

### GraphQLスキーマファイルを使用したファジング {#api-fuzzing-with-a-graphql-schema-file}

ファジングは、イントロスペクションが無効になっているGraphQLエンドポイントを理解してテストするために、GraphQLスキーマファイルを使用できます。GraphQLスキーマファイルを使用するには、イントロスペクションJSON形式である必要があります。GraphQLスキーマは、オンラインのサードパーティ製ツール[https://transform.tools/graphql-to-introspection-json](https://transform.tools/graphql-to-introspection-json)を使用して、イントロスペクションJSON形式に変換できます。

ターゲットAPIに関する情報を提供するGraphQlスキーマファイルを使用するようにファジングを設定するには、次の手順に従います:

1. [次のものを含めます](../../../../ci/yaml/_index.md#includetemplate) [`API-Fuzzing.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)を`.gitlab-ci.yml`ファイルに追加します。

1. GraphQLエンドポイントのパス（`/api/graphql`など）を指定します。`FUZZAPI_GRAPHQL`変数を追加して、パスを指定します。

1. GraphQLのスキーマファイルの場所を指定します。ファイルのパスまたはURLとして場所を指定できます。`FUZZAPI_GRAPHQL_SCHEMA`変数を追加して、場所を指定します。

1. ターゲットAPIインスタンスのベースURLも必要です。`FUZZAPI_TARGET_URL`変数または`environment_url.txt`ファイルを使用して指定します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加すると、動的環境でのテストに最適です。詳細については、ドキュメントの[動的環境ソリューション](../troubleshooting.md#dynamic-environment-solutions)のセクションを参照してください。

GraphQLのスキーマファイルを使用した完全な構成例:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

apifuzzer_fuzz:
  variables:
    FUZZAPI_GRAPHQL: /api/graphql
    FUZZAPI_GRAPHQL_SCHEMA: test-api-graphql.schema
    FUZZAPI_TARGET_URL: http://test-deployment/
```

GraphQLのスキーマファイルURLを使用した完全な構成例:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

apifuzzer_fuzz:
  variables:
    FUZZAPI_GRAPHQL: /api/graphql
    FUZZAPI_GRAPHQL_SCHEMA: http://file-store/files/test-api-graphql.schema
    FUZZAPI_TARGET_URL: http://test-deployment/
```

これは、APIファジングの最小構成です。ここから、次のことができます:

- [最初のスキャンを実行](#running-your-first-scan)。
- [認証](customizing_analyzer_settings.md#authentication)を追加します。
- [誤検出](#handling-false-positives)の処理方法を学びます。

## Postmanコレクション {#postman-collection}

[Postman APIクライアント](https://www.postman.com/product/api-client/)は、デベロッパーやテスターがさまざまな種類のAPIを呼び出すためによく使用するツールです。APIファジングで使用するために、API定義を[Postmanコレクションファイルとしてエクスポートできます](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)。エクスポートするときは、サポートされているバージョンのPostmanコレクション（v2.0またはv2.1）を選択してください。

GitLab APIアナライザーで使用する場合、Postmanコレクションには、有効なデータでテストするWeb APIの定義を含める必要があります。APIアナライザーは、すべてのAPI定義を抽出し、それらを使用してテストを実行します。

{{< alert type="warning" >}}

Postmanコレクションファイルには、認証トークン、APIキー、セッションクッキーなどの機密情報が含まれている場合があります。Postmanコレクションファイルの内容をリポジトリに追加する前に確認することをお勧めします。

{{< /alert >}}

### Postmanコレクションファイルを使用したWeb APIファジングの構成 {#configure-web-api-fuzzing-with-a-postman-collection-file}

Postmanコレクションファイルを使用するようにAPIファジングを構成するには:

1. `.gitlab-ci.yml`ファイルに`fuzz`ステージングを追加します。

1. `.gitlab-ci.yml`ファイルに[テンプレート](../../../../ci/yaml/_index.md#includetemplate)である[`API-Fuzzing.gitlab-ci.yml`を含めます](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)。

1. `.gitlab-ci.yml`ファイルに`FUZZAPI_PROFILE` CI/CD変数を追加して、プロファイルを指定します。プロファイルは、実行するテストの数を指定します。選択したプロファイルに`Quick-10`を代入します。詳細については、[APIファジングプロファイル](customizing_analyzer_settings.md#api-fuzzing-profiles)を参照してください。

   ```yaml
   variables:
     FUZZAPI_PROFILE: Quick-10
   ```

1. Postmanコレクションの仕様の場所を指定します。ファイルのURLとして仕様を指定できます。`FUZZAPI_POSTMAN_COLLECTION`変数を追加して、場所を指定します。

1. ターゲットAPIインスタンスのベースURLを指定します。`FUZZAPI_TARGET_URL`変数または`environment_url.txt`ファイルのいずれかを使用します。

   プロジェクトのルートにある`environment_url.txt`ファイルにURLを追加すると、動的環境でのテストに最適です。GitLab CI/CDパイプライン中に動的に作成されたアプリに対してAPIファジングを実行するには、アプリに`environment_url.txt`ファイルにそのドメインを永続化させます。APIファジングは、そのファイルを自動的に解析中して、スキャンターゲットを検索します。[当社のAuto DevOps CI YAMLの例](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)を参照してください。

Postmanコレクションファイルを使用する`.gitlab-ci.yml`ファイルの例:

   ```yaml
   stages:
     - fuzz

   include:
     - template: Security/API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_POSTMAN_COLLECTION: postman-collection_serviceA.json
     FUZZAPI_TARGET_URL: http://test-deployment/
   ```

これは、APIファジングの最小構成です。ここから、次のことができます:

- [最初のスキャンを実行](#running-your-first-scan)。
- [認証](customizing_analyzer_settings.md#authentication)を追加します。
- [誤検出](#handling-false-positives)の処理方法を学びます。

APIファジング構成オプションの詳細については、[利用可能なCI/CD変数](variables.md)を参照してください。

### Postman変数 {#postman-variables}

{{< history >}}

- Postman環境ファイル形式のサポートは、[GitLab 15.1で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)。
- 複数の変数ファイルのサポートは、[GitLab 15.1で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)。
- Postman変数のスコープのサポート: グローバル変数と環境は、[GitLab 15.1で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)。

{{< /history >}}

#### Postmanクライアントの変数 {#variables-in-postman-client}

Postmanを使用すると、デベロッパーはリクエストのさまざまな部分で使用できるプレースホルダーを定義できます。これらのプレースホルダーは、「[変数の使用](https://learning.postman.com/docs/sending-requests/variables/variables/)」で説明されているように、変数と呼ばれます。変数を使用すると、リクエストとスクリプトで値を保存して再利用できます。たとえば、コレクションを編集して、ドキュメントに変数を追加できます:

![コレクション変数タブビューの編集](img/api_fuzzing_postman_collection_edit_variable_v18_5.png)

または、環境に変数を追加することもできます:

![環境変数ビューの編集](img/api_fuzzing_postman_environment_edit_variable_v18_5.png)

次に、URL、ヘッダーなどのセクションで変数を使用できます:

![変数ビューを使用してリクエストを編集](img/api_fuzzing_postman_request_edit_v18_5.png)

Postmanは、優れたユーザーエクスペリエンスを備えた基本的なクライアントツールから、スクリプトでAPIをテストしたり、2次リクエストをトリガーする複雑なコレクションを作成したり、途中で変数を設定したりできる、より複雑なエコシステムに成長しました。Postmanエコシステムのすべての機能がサポートされているわけではありません。たとえば、スクリプトはサポートされていません。Postmanサポートの主な焦点は、Postmanクライアントで使用されるPostmanコレクション定義と、ワークスペース、環境、およびコレクション自体で定義された関連する変数をインジェストすることです。

Postmanでは、さまざまなスコープで変数を作成できます。各スコープには、Postmanツールのさまざまなレベルの表示レベルがあります。たとえば、すべての操作定義とワークスペースに表示されるグローバル環境スコープで変数を作成できます。また、特定の環境が使用するために選択されている場合にのみ表示および使用される特定の環境スコープで変数を作成することもできます。一部のスコープは常に利用できるとは限りません。たとえば、Postmanエコシステムでは、Postmanクライアントでリクエストを作成できます。これらのリクエストにはローカルスコープはありませんが、テストスクリプトにはあります。

Postmanの変数のスコープは、気が遠くなるようなトピックになる可能性があり、誰もが精通しているわけではありません。先に進む前に、Postmanドキュメントの[変数のスコープ](https://learning.postman.com/docs/sending-requests/variables/variables/#variable-scopes)をお読みになることを強くお勧めします。

前述のように、さまざまな変数のスコープがあり、それぞれに目的があり、Postmanドキュメントに柔軟性を提供するために使用できます。Postmanのドキュメントに従って、変数の値がどのように計算されるかについて重要な注意点があります:

{{< alert type="note" >}}

同じ名前の変数が2つの異なるスコープで宣言されている場合、最も狭いスコープの変数に格納されている値が使用されます。たとえば、`username`という名前のグローバル変数と、`username`という名前のローカル変数がある場合、リクエストの実行時にローカル値が使用されます。

{{< /alert >}}

次に、PostmanクライアントとAPIファジングでサポートされている変数のスコープの概要を示します:

- **Global environment (global) scope**（グローバル環境 (グローバル変数) スコープ）は、ワークスペース全体で使用できる特別な事前定義済みの環境です。グローバル環境スコープをグローバルスコープと呼ぶこともできます。Postmanクライアントを使用すると、グローバル環境をJSONファイルにエクスポートできます。これは、APIファジングで使用できます。
- **環境スコープ**は、Postmanクライアントでユーザーが作成した変数の名前付きグループです。Postmanクライアントは、グローバル環境とともに、単一のアクティブな環境をサポートしています。アクティブなユーザーが作成した環境で定義された変数は、グローバル環境で定義された変数よりも優先されます。Postmanクライアントを使用すると、環境をJSONファイルにエクスポートできます。これは、APIファジングで使用できます。
- **コレクションスコープ**は、特定のコレクションで宣言された変数のグループです。コレクション変数は、宣言されたコレクションとネストされたリクエストまたはコレクションで使用できます。コレクションスコープで定義された変数は、グローバル環境スコープと環境スコープよりも優先されます。Postmanクライアントは、1つ以上のコレクションをJSONファイルにエクスポートできます。このJSONファイルには、選択したコレクション、リクエスト、およびコレクション変数が含まれています。
- **API fuzzing scope**（APIファジングスコープ）は、ユーザーが追加の変数を提供したり、サポートされている他のスコープで定義されている変数をオーバーライドしたりできるように、APIファジングによって追加された新しいスコープです。このスコープは、Postmanではサポートされていません。APIファジングスコープ変数は、[カスタムJSONファイル形式](#api-fuzzing-scope-custom-json-file-format)を使用して提供されます。
  - 環境またはコレクションで定義された値をオーバーライドします
  - スクリプトから変数を定義する
  - サポートされていない_データスコープ_からデータの単一行を定義する
- **Data scope**（データスコープ）は、名前と値がJSONまたはCSVファイルからのものである変数のグループです。[Newman](https://learning.postman.com/docs/collections/using-newman-cli/command-line-integration-with-newman/)や[PostmanコレクションRunner](https://learning.postman.com/docs/collections/running-collections/intro-to-collection-runs/)などのPostmanコレクションランナーは、JSONまたはCSVファイルにエントリがある回数だけコレクション内のリクエストを実行します。これらの変数の良いユースケースは、Postmanでスクリプトを使用してテストを自動化することです。APIファジングは、CSVまたはJSONファイルからデータを読み取ることをサポート**not**（していません）。
- **Local scope**（ローカルスコープ）は、Postmanスクリプトで定義されている変数です。APIファジングは、Postmanスクリプトと、拡張機能によってスクリプトで定義された変数をサポート**not**（していません）。サポートされているスコープの1つまたはカスタムJSON形式で定義することにより、スクリプトで定義された変数の値を引き続き指定できます。

すべてのスコープがAPIファジングでサポートされているわけではなく、スクリプトで定義された変数はサポートされていません。次の表は、最も広いスコープから最も狭いスコープでソートされています。

| スコープ              | Postman   | APIファジング:  | コメント |
| ------------------ |:---------:|:-----------:| :-------|
| グローバル環境 | はい       | はい         | 特別な事前定義済みの環境 |
| 環境        | はい       | はい         | 名前付き環境 |
| コレクション         | はい       | はい         | Postmanコレクションで定義 |
| APIファジングスコープ  | いいえ        | はい         | APIファジングによって追加されたカスタムスコープ |
| データ:               | はい       | いいえ          | CSVまたはJSON形式の外部ファイル |
| ローカル              | はい       | いいえ          | スクリプトで定義された変数 |

さまざまなスコープで変数を定義してエクスポートする方法の詳細については、次を参照してください:

- [コレクション変数を定義する](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-collection-variables)
- [環境変数](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-environment-variables)の定義
- [グローバル変数を定義する](https://learning.postman.com/docs/sending-requests/variables/variables/#defining-global-variables)

#### Postmanクライアントからのエクスポート {#exporting-from-postman-client}

Postmanクライアントを使用すると、さまざまなファイル形式をエクスポートできます。たとえば、PostmanコレクションまたはPostman環境をエクスポートできます。エクスポートされた環境は、（常に利用可能な）グローバル環境であるか、以前に作成したカスタム環境にすることができます。Postmanコレクションをエクスポートすると、コレクションとローカルスコープの変数の宣言のみが含まれる場合があります。環境スコープの変数は含まれません。

環境スコープの変数の宣言を取得するには、その時点で特定の環境をエクスポートする必要があります。各エクスポートされたファイルには、選択した環境からの変数のみが含まれています。

さまざまなサポートされているスコープで変数をエクスポートする方法の詳細については、次を参照してください:

- [コレクションをエクスポートする](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)
- [環境をエクスポートする](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [グローバル環境をダウンロードする](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)

#### APIファジングスコープ、カスタムJSONファイル形式 {#api-fuzzing-scope-custom-json-file-format}

当社のカスタムJSONファイル形式は、各オブジェクトプロパティが変数名を表し、プロパティ値が変数値を表すJSONオブジェクトです。このファイルは、お気に入りのテキストエディタを使用して作成することも、パイプラインの以前のジョブで作成することもできます。

この例では、APIファジングスコープで2つの変数`base_url`と`token`を定義します:

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### APIファジングでのスコープの使用 {#using-scopes-with-api-fuzzing}

スコープ：グローバル変数、環境、コレクション、およびGitLab APIファジングは、[GitLab 15.1以降](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)でサポートされています。GitLab 15.0以前は、コレクションとGitLab APIファジングスコープのみをサポートしています。

次の表に、スコープファイル/URLをAPIファジング構成変数にマッピングするためのクイックリファレンスを示します:

| スコープ              |  提供方法 |
| ------------------ | --------------- |
| グローバル環境 | FUZZAPI_POSTMAN_COLLECTION_VARIABLES |
| 環境        | FUZZAPI_POSTMAN_COLLECTION_VARIABLES |
| コレクション         | FUZZAPI_POSTMAN_COLLECTION           |
| APIファジングスコープ  | FUZZAPI_POSTMAN_COLLECTION_VARIABLES |
| データ:               | サポートされていません   |
| ローカル              | サポートされていません   |

Postmanコレクションドキュメントには、コレクションスコープの変数が自動的に含まれています。Postmanコレクションは、構成変数`FUZZAPI_POSTMAN_COLLECTION`で提供されます。この変数は、[エクスポートされた単一のPostmanコレクション](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-collections)に設定できます。

他のスコープからの変数は、`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`構成変数を介して提供されます。この設定変数は、`,`（,）で区切られたファイルリストを[GitLab 15.1以降](https://gitlab.com/gitlab-org/gitlab/-/issues/356312)でサポートします。以前のGitLab 15.0では、サポートされるファイルは1つだけです。ファイルに必要なスコープ情報が提供されるため、指定されたファイルの順序は重要ではありません。

構成変数`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`は、以下に設定できます:

- [エクスポートされたグローバル環境](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)
- [エクスポートされた環境](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- [APIファジングカスタムJSON形式](#api-fuzzing-scope-custom-json-file-format)

#### 未定義のPostman変数 {#undefined-postman-variables}

APIファジングエンジンが、Postmanコレクションファイルで使用されているすべての変数参照を検出するとは限りません。考えられるケースは次のとおりです:

- データまたはローカルスコープの変数を使用していますが、前述のように、これらのスコープはAPIファジングではサポートされていません。したがって、これらの変数の値が[APIファジングのスコープ](#api-fuzzing-scope-custom-json-file-format)を介して提供されていないと仮定すると、データとローカルスコープの変数の値は未定義になります。
- 変数名が誤って入力され、その名前が定義された変数と一致しません。
- Postman Clientは、APIファジングでサポートされていない新しい動的変数をサポートしています。

可能な場合、APIファジングは、未定義の変数を処理する際に、Postman Clientと同じ動作に従います。変数参照のテキストは同じままであり、テキストの置換はありません。同じ動作は、サポートされていない動的変数にも適用されます。

たとえば、Postmanコレクションのリクエスト定義が変数`{{full_url}}`を参照していて、その変数が見つからない場合、値`{{full_url}}`で変更されずに残ります。

#### 動的Postman変数 {#dynamic-postman-variables}

ユーザーがさまざまなスコープレベルで定義できる変数に加えて、Postmanには動的変数と呼ばれる事前定義された変数のセットがあります。その[動的変数](https://learning.postman.com/docs/tests-and-scripts/write-scripts/variables-list/)は既に定義されており、それらの名前にはドル記号（`$`）がプレフィックスとして付加されています（例：`$guid`）。動的変数は他の変数と同様に使用でき、Postman Clientでは、リクエスト/コレクションの実行中にランダムな値を生成します。

APIファジングとPostmanの重要な違いは、APIファジングが同じ動的変数のそれぞれの使用に対して同じ値を返すことです。これは、同じ動的変数を使用するたびにランダムな値を返すPostman Clientの動作とは異なります。つまり、Postmanがランダムな値を使用するのに対し、APIファジングは動的変数に静的な値を使用します。

スキャン処理中にサポートされる動的変数は次のとおりです:

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

この例では、Postman Clientから[グローバルスコープがエクスポートされます](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)（`global-scope.json`）。これは、`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`設定変数を介してAPIファジングに提供されます。

`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`の使用例を以下に示します:

```yaml
stages:
     - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: global-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

#### 例: 環境範囲 {#example-environment-scope}

この例では、Postman Clientから[環境スコープがエクスポートされます](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)（`environment-scope.json`）。これは、`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`設定変数を介してAPIファジングに提供されます。

`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`の使用例を以下に示します:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: environment-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

#### 例: コレクションのスコープ {#example-collection-scope}

コレクションのスコープ変数は、エクスポートされたPostmanコレクションファイルに含められ、`FUZZAPI_POSTMAN_COLLECTION`設定変数を介して提供されます。

`FUZZAPI_POSTMAN_COLLECTION`の使用例を以下に示します:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: variable-collection-dictionary.json
```

#### 例: APIファジングのスコープ {#example-api-fuzzing-scope}

APIファジングのスコープは、APIファジングでサポートされていない_データ_と_ローカル_スコープの変数を定義すること、および別のスコープで定義された既存の変数の値を変更するという、2つの主な目的で使用されます。APIファジングのスコープは、`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`設定変数を介して提供されます。

`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`の使用例を以下に示します:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: api-fuzzing-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

ファイル`api-fuzzing-scope.json`は、[カスタムJSONファイル形式](#api-fuzzing-scope-custom-json-file-format)を使用します。このJSONは、プロパティのキーと値のペアを持つオブジェクトです。キーは変数の名前で、値は変数の値です。例: 

```json
{
  "base_url": "http://127.0.0.1/",
  "token": "Token 84816165151"
}
```

#### 例: 複数のスコープ {#example-multiple-scopes}

この例では、グローバルスコープ、環境スコープ、およびコレクションのスコープが構成されています。最初の手順は、さまざまなスコープをエクスポートすることです。

- `global-scope.json`として[グローバルスコープをエクスポートします](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)
- `environment-scope.json`として[環境スコープをエクスポートします](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- _コレクション_のスコープを`postman-collection.json`として含むPostmanコレクションをエクスポートします

Postmanコレクションは`FUZZAPI_POSTMAN_COLLECTION`変数を使用して提供されますが、他のスコープは`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`を使用して提供されます。APIファジングは、各ファイルで提供されるデータを使用して、提供されたファイルがどのスコープに一致するかを識別できます。

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

#### 例: 変数の値を変更する {#example-changing-variables-value}

エクスポートされたスコープを使用する場合、多くの場合、APIファジングで使用するために変数の値を変更する必要があります。たとえば、_コレクション_のスコープを持つ変数に、値`v2`の`api_version`という名前の変数が含まれている場合でも、テストでは値`v1`が必要です。値を変更するためにエクスポートされたコレクションを変更する代わりに、APIファジングのスコープを使用して値を変更できます。これは、APIファジングのスコープが他のすべてのスコープよりも優先されるために機能します。

コレクションのスコープ変数は、エクスポートされたPostmanコレクションファイルに含められ、`FUZZAPI_POSTMAN_COLLECTION`設定変数を介して提供されます。

APIファジングのスコープは、`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`設定変数を介して提供されますが、最初にファイルを作成する必要があります。ファイル`api-fuzzing-scope.json`は、[カスタムJSONファイル形式](#api-fuzzing-scope-custom-json-file-format)を使用します。このJSONは、プロパティのキーと値のペアを持つオブジェクトです。キーは変数の名前で、値は変数の値です。例: 

```json
{
  "api_version": "v1"
}
```

CI定義:

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: api-fuzzing-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

#### 例: 複数のスコープを使用して変数の値を変更する {#example-changing-a-variables-value-with-multiple-scopes}

エクスポートされたスコープを使用する場合、多くの場合、APIファジングで使用するために変数の値を変更する必要があります。たとえば、環境スコープに、値`v2`の`api_version`という名前の変数が含まれている場合でも、テストでは値`v1`が必要です。値を変更するためにエクスポートされたファイルを変更する代わりに、APIファジングのスコープを使用できます。これは、APIファジングのスコープが他のすべてのスコープよりも優先されるために機能します。

この例では、グローバルスコープ、環境スコープ、コレクションのスコープ、およびAPIファジングのスコープが構成されています。最初の手順は、さまざまなスコープをエクスポートして作成することです。

- `global-scope.json`として[グローバルスコープをエクスポートします](https://learning.postman.com/docs/sending-requests/variables/variables/#downloading-global-environments)
- `environment-scope.json`として[環境スコープをエクスポートします](https://learning.postman.com/docs/getting-started/importing-and-exporting/exporting-data/#export-environments)
- コレクションのスコープを含むPostmanコレクションを`postman-collection.json`としてエクスポートします

APIファジングのスコープは、[カスタムJSONファイル形式](#api-fuzzing-scope-custom-json-file-format)を使用してファイル`api-fuzzing-scope.json`を作成することによって使用されます。このJSONは、プロパティのキーと値のペアを持つオブジェクトです。キーは変数の名前で、値は変数の値です。例: 

```json
{
  "api_version": "v1"
}
```

Postmanコレクションは`FUZZAPI_POSTMAN_COLLECTION`変数を使用して提供されますが、他のスコープは`FUZZAPI_POSTMAN_COLLECTION_VARIABLES`を使用して提供されます。APIファジングは、各ファイルで提供されるデータを使用して、提供されたファイルがどのスコープに一致するかを識別できます。

```yaml
stages:
  - fuzz

include:
  - template: Security/API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_POSTMAN_COLLECTION: postman-collection.json
  FUZZAPI_POSTMAN_COLLECTION_VARIABLES: global-scope.json,environment-scope.json,api-fuzzing-scope.json
  FUZZAPI_TARGET_URL: http://test-deployment/
```

## 最初のスキャンの実行 {#running-your-first-scan}

正しく設定されている場合、CI/CDパイプラインには、`fuzz`ステージングと`apifuzzer_fuzz`または`apifuzzer_fuzz_dnd`のジョブが含まれます。このジョブは、無効な設定が提供されている場合にのみ失敗します。通常の操作中、ファジングテスト中にフォールトが識別された場合でも、ジョブは常に成功します。

フォールトは、スイート名とともに**セキュリティ**パイプラインタブに表示されます。リポジトリのデフォルトブランチに対してテストする場合、ファジングのフォールトは、セキュリティとコンプライアンスの脆弱性レポートにも表示されます。

報告されるフォールトの数が過剰になるのを防ぐため、APIファジングスキャナーは、報告するフォールトの数を制限します。

## ファジングのフォールトの表示 {#viewing-fuzzing-faults}

APIファジングアナライザーは、収集および使用されるJSONレポートを生成し、[GitLabの脆弱性画面にフォールトを入力した状態にします](#view-details-of-an-api-fuzzing-vulnerability)。ファジングのフォールトは、重大度が「不明」の脆弱性として表示されます。

APIファジングで見つかったフォールトには手動調査が必要であり、特定の脆弱性タイプに関連付けられていません。セキュリティ上の問題であるかどうか、および修正が必要かどうかを判断するには、調査が必要です。報告される誤検出の数を制限するために行える設定の変更については、[誤検出の処理](#handling-false-positives)を参照してください。

### APIファジングの脆弱性の詳細を表示する {#view-details-of-an-api-fuzzing-vulnerability}

APIファジングによって検出されたフォールトは、ライブWebアプリケーションで発生し、脆弱性であるかどうかを判断するために手動調査が必要です。ファジングのフォールトは、重大度が「不明」の脆弱性として含まれています。ファジングのフォールトの調査を容易にするために、送受信されたHTTPメッセージに関する詳細情報と、行われた変更の説明が提供されます。

ファジングのフォールトの詳細を表示するには、次の手順に従います:

1. プロジェクトまたはマージリクエストでフォールトを表示できます:

   - プロジェクトでは、プロジェクトの**セキュリティ** > **脆弱性レポート**ページに移動します。このページには、デフォルトブランチからのすべての脆弱性のみが表示されます。
   - マージリクエストでは、マージリクエストの**セキュリティ**セクションに移動し、**全て展開**ボタンを選択します。APIファジングのフォールトは、**API Fuzzing detected N potential vulnerabilities**（APIファジングで検出されたN個の潜在的な脆弱性）というラベルの付いたセクションで使用できます。タイトルを選択して、フォールトの詳細を表示します。

1. フォールトのタイトルを選択して、フォールトの詳細を表示します。次の表に、これらの詳細を示します。

   | フィールド               | 説明                                                                             |
   |:--------------------|:----------------------------------------------------------------------------------------|
   | 説明         | 何が変更されたかなど、フォールトの説明。                                   |
   | プロジェクト             | 脆弱性が検出されたネームスペースとプロジェクト。                          |
   | Method              | 脆弱性の検出に使用されたHTTPメソッド。                                           |
   | URL                 | 脆弱性が検出されたURL。                                            |
   | Request             | フォールトを引き起こしたHTTPリクエスト。                                                 |
   | 変更されていないレスポンス | 変更されていないリクエストからのレスポンス。これは、典型的な作業レスポンスがどのように見えるかです。 |
   | 実際のレスポンス     | ファジングされたリクエストから受信したレスポンス。                                                  |
   | エビデンス            | フォールトの発生をどのように判断したか。                                                     |
   | 識別子:         | このフォールトの発見に使用されたファジングチェック。                                              |
   | 重大度            | 調査結果の重大度は常に不明です。                                              |
   | スキャナータイプ        | テストの実行に使用されるスキャナー。                                                        |

### セキュリティダッシュボード {#security-dashboard}

ファジングのフォールトは、重大度が「不明」の脆弱性として表示されます。セキュリティダッシュボードは、グループ、プロジェクト、パイプラインのすべてのセキュリティ脆弱性の概要を把握するのに適した場所です。詳細については、[セキュリティダッシュボードのドキュメント](../../security_dashboard/_index.md)を参照してください。

### 脆弱性の操作 {#interacting-with-the-vulnerabilities}

ファジングのフォールトは、重大度が「不明」の脆弱性として表示されます。フォールトが見つかったら、それを操作できます。[脆弱性に対処](../../vulnerabilities/_index.md)する方法の詳細をお読みください。

## 誤検出の処理 {#handling-false-positives}

誤検出は、次の2つの方法で処理できます:

- 誤検出を生成しているチェックをオフにします。これにより、チェックによるフォールトの生成が防止されます。チェックの例としては、`JSONFuzzingCheck`と`FormBodyFuzzingCheck`があります。
- ファジングチェックには、フォールトが識別されたタイミングを検出するいくつかのメソッドがあり、「アサート」と呼ばれます。アサートもオフにして設定できます。たとえば、APIファジングでは、デフォルトでHTTPステータスコードを使用して、何が実際の問題であるかを識別します。APIがテスト中に500エラーを返すと、フォールトが作成されます。一部のフレームワークは500エラーを頻繁に返すため、これは必ずしも望ましいとは限りません。

### チェックをオフにする {#turn-off-a-check}

チェックは特定のタイプのテストを実行し、特定の設定プロファイルに対してオンとオフを切り替えることができます。デフォルト設定ファイルは、使用できるいくつかのプロファイルを定義します。設定ファイル内のプロファイル定義には、スキャン中にアクティブになるすべてのチェックがリストされます。特定のチェックをオフにするには、設定ファイルのプロファイル定義から削除します。プロファイルは、設定ファイルの`Profiles`セクションで定義されます。

プロファイルの定義例:

```yaml
Profiles:
  - Name: Quick-10
    DefaultProfile: Quick
    Routes:
      - Route: *Route0
        Checks:
          - Name: FormBodyFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: GeneralFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: JsonFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: XmlFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
```

`GeneralFuzzingCheck`をオフにするには、次の行を削除します:

```yaml
- Name: GeneralFuzzingCheck
  Configuration:
    FuzzingCount: 10
    UnicodeFuzzing: true
```

これにより、次のYAMLが得られます:

```yaml
- Name: Quick-10
  DefaultProfile: Quick
  Routes:
    - Route: *Route0
      Checks:
        - Name: FormBodyFuzzingCheck
          Configuration:
            FuzzingCount: 10
            UnicodeFuzzing: true
        - Name: JsonFuzzingCheck
          Configuration:
            FuzzingCount: 10
            UnicodeFuzzing: true
        - Name: XmlFuzzingCheck
          Configuration:
            FuzzingCount: 10
            UnicodeFuzzing: true
```

### チェックのアサーションをオフにします {#turn-off-an-assertion-for-a-check}

アサーションは、チェックによって生成されたテストの誤検出を検出します。多くのチェックは、ログ分析、レスポンス分析、ステータスコードなど、複数のアサーションをサポートしています。誤検出が見つかると、使用されたアサーションが提供されます。どのアサーションがデフォルトでオンになっているかを確認するには、設定ファイルでチェックのデフォルト設定を参照してください。セクションは`Checks`と呼ばれます。

この例は、`FormBodyFuzzingCheck`を示しています:

```yaml
Checks:
  - Name: FormBodyFuzzingCheck
    Configuration:
      FuzzingCount: 30
      UnicodeFuzzing: true
    Assertions:
      - Name: LogAnalysisAssertion
      - Name: ResponseAnalysisAssertion
      - Name: StatusCodeAssertion
```

ここでは、3つのアサーションがデフォルトでオンになっていることがわかります。誤検出の一般的な原因は`StatusCodeAssertion`です。オフにするには、`Profiles`セクションでその設定を変更します。この例では、他の2つのアサーション（`LogAnalysisAssertion`、`ResponseAnalysisAssertion`）のみを提供します。これにより、`FormBodyFuzzingCheck`が`StatusCodeAssertion`を使用できなくなります:

```yaml
Profiles:
  - Name: Quick-10
    DefaultProfile: Quick
    Routes:
      - Route: *Route0
        Checks:
          - Name: FormBodyFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
            Assertions:
              - Name: LogAnalysisAssertion
              - Name: ResponseAnalysisAssertion
          - Name: GeneralFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: JsonFuzzingCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
          - Name: XmlInjectionCheck
            Configuration:
              FuzzingCount: 10
              UnicodeFuzzing: true
```
