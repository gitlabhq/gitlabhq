---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アナライザー設定をカスタマイズする
---

APIファジングの動作は、CI/CD変数によって変更できます。

APIファジングの設定ファイルは、リポジトリの`.gitlab`ディレクトリに存在する必要があります。

{{< alert type="warning" >}}

GitLabセキュリティスキャンツールのすべてのカスタマイズは、これらの変更をデフォルトブランチにマージする前に、マージリクエストでテストする必要があります。そうしないと、誤検出が多数発生するなど、予期しない結果が生じる可能性があります。

{{< /alert >}}

## 認証 {#authentication}

認証は、ヘッダーまたはCookieとして認証トークンを提供することで処理されます。認証フローを実行したり、トークンを計算したりするスクリプトを提供できます。

### HTTP Basic認証 {#http-basic-authentication}

[HTTP Basic認証](https://en.wikipedia.org/wiki/Basic_access_authentication)は、HTTPプロトコルに組み込まれ、[トランスポートレイヤーセキュリティ（TLS）](https://en.wikipedia.org/wiki/Transport_Layer_Security)と組み合わせて使用される認証方法です。

[CI/CD変数を作成](../../../../ci/variables/_index.md#for-a-project)して、パスワード（例: `TEST_API_PASSWORD`）を作成し、マスクするように設定することをお勧めします。GitLabプロジェクトのページの**設定** > **CI/CD**の**変数**セクションからCI/CD変数を作成できます。[マスクされた変数の制限事項](../../../../ci/variables/_index.md#mask-a-cicd-variable)により、変数として追加する前に、パスワードをBase64エンコードする必要があります。

最後に、2つのCI/CD変数を`.gitlab-ci.yml`ファイルに追加します:

- `FUZZAPI_HTTP_USERNAME`: 認証用のユーザー名。
- `FUZZAPI_HTTP_PASSWORD_BASE64`: 認証用のBase64エンコードされたパスワード。

```yaml
stages:
    - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_HAR: test-api-recording.har
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_HTTP_USERNAME: testuser
  FUZZAPI_HTTP_PASSWORD_BASE64: $TEST_API_PASSWORD
```

### Rawパスワード {#raw-password}

パスワードをBase64エンコードしたくない場合（またはGitLab 15.3以前のバージョンを使用している場合）は、`FUZZAPI_HTTP_PASSWORD_BASE64`を使用する代わりに、rawパスワード`FUZZAPI_HTTP_PASSWORD`を指定できます。

### Bearerトークン {#bearer-tokens}

Bearerトークンは、OAuth2やJSON Webトークン（JWT）など、いくつかの異なる認証メカニズムで使用されます。Bearerトークンは、`Authorization` HTTPヘッダーを使用して送信されます。APIファジングでベアラートークンを使用するには、次のいずれかが必要です:

- 有効期限切れにならないトークン
- テストの長さに耐えるトークンを生成する方法
- APIファジングが呼び出してトークンを生成できるPythonスクリプト

#### トークンは有効期限切れになりません {#token-doesnt-expire}

Bearerトークンが有効期限切れにならない場合は、`FUZZAPI_OVERRIDES_ENV`変数を使用して指定します。この変数のコンテンツは、APIファジングの送信HTTPリクエストに追加するヘッダーとCookieを提供するJSONスニペットです。

`FUZZAPI_OVERRIDES_ENV`を使用してベアラートークンを提供するには、次の手順に従います:

1. [CI/CD変数を作成](../../../../ci/variables/_index.md#for-a-project)します。たとえば、値`{"headers":{"Authorization":"Bearer dXNlcm5hbWU6cGFzc3dvcmQ="}}`（トークンを代入）を使用して`TEST_API_BEARERAUTH`を作成します。GitLabプロジェクトのページの**設定** > **CI/CD**の**変数**セクションからCI/CD変数を作成できます。

1. `.gitlab-ci.yml`ファイルで、作成したばかりの変数に`FUZZAPI_OVERRIDES_ENV`を設定します:

   ```yaml
   stages:
     - fuzz

   include:
     - template: API-Fuzzing.gitlab-ci.yml

   variables:
     FUZZAPI_PROFILE: Quick-10
     FUZZAPI_OPENAPI: test-api-specification.json
     FUZZAPI_TARGET_URL: http://test-deployment/
     FUZZAPI_OVERRIDES_ENV: $TEST_API_BEARERAUTH
   ```

1. 認証が機能していることを検証するには、APIファジングテストを実行し、ファジングログとテストAPIのアプリケーションログをレビューします。オーバーライドコマンドの詳細については、[上書きセクション](#overrides)を参照してください。

#### テストランタイムで生成されたトークン {#token-generated-at-test-runtime}

Bearerトークンを生成する必要があり、テスト中に有効期限が切れない場合は、トークンを含むファイルをAPIファジングに提供できます。以前のステージングとジョブ、またはAPIファジングジョブの一部で、このファイルを生成できます。

APIファジングは、次の構造のJSONファイルを受信することを想定しています:

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

このファイルは、以前のステージングで生成し、`FUZZAPI_OVERRIDES_FILE`CI/CD変数を介してAPIファジングに提供できます。

`.gitlab-ci.yml`ファイルで`FUZZAPI_OVERRIDES_FILE`を設定します:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
```

認証が機能していることを検証するには、APIファジングテストを実行し、ファジングログとテストAPIのアプリケーションログをレビューします。

#### トークンの有効期限が短い {#token-has-short-expiration}

Bearerトークンを生成する必要があり、スキャンの完了前に有効期限が切れる場合は、APIファザーが指定された間隔で実行するプログラムまたはスクリプトを指定できます。指定されたスクリプトは、Python 3とBashがインストールされているAlpine Linuxパッケージのコンテナで実行されます。Pythonスクリプトが追加のパッケージを必要とする場合は、これを検出し、ランタイム時にパッケージをインストールする必要があります。

スクリプトは、特定の形式でベアラートークンを含むJSONファイルを作成する必要があります:

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

正しい操作のために、それぞれ設定された3つのCI/CD変数を指定する必要があります:

- `FUZZAPI_OVERRIDES_FILE`: 指定されたコマンドが生成するJSONファイル。
- `FUZZAPI_OVERRIDES_CMD`: JSONファイルを生成するコマンド。
- `FUZZAPI_OVERRIDES_INTERVAL`: コマンドを実行する間隔（秒単位）。

例: 

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
  FUZZAPI_OVERRIDES_CMD: renew_token.py
  FUZZAPI_OVERRIDES_INTERVAL: 300
```

認証が機能していることを検証するには、APIファジングテストを実行し、ファジングログとテストAPIのアプリケーションログをレビューします。

## APIファジングプロファイル {#api-fuzzing-profiles}

GitLabは[`gitlab-api-fuzzing-config.yml`](https://gitlab.com/gitlab-org/security-products/analyzers/api-fuzzing/-/blob/master/gitlab-api-fuzzing-config.yml)設定ファイルを提供します。これには、特定の数のテストを実行するいくつかのテストプロファイルが含まれています。各プロファイルのランタイムは、テスト数の増加とともに増加します。

| プロファイル   | ファジングテスト（パラメータごと） |
|:----------|:---------------------------|
| Quick-10  | 10 |
| Medium-20 | 20 |
| Medium-50 | 50 |
| Long-100  | 100 |

## オーバーライド {#overrides}

APIファジングは、たとえば、リクエスト内の特定の項目を追加またはオーバーライドする方法を提供します:

- ヘッダー
- Cookie
- クエリ文字列
- フォームデータ
- JSONノード
- XMLノード

これを使用すると、セマンティックバージョンヘッダー、認証などを挿入できます。[認証セクション](#authentication)には、その目的でオーバーライドを使用する例が含まれています。

オーバーライドはJSONドキュメントを使用します。各タイプのオーバーライドはJSONオブジェクトで表されます:

```json
{
  "headers": {
    "header1": "value",
    "header2": "value"
  },
  "cookies": {
    "cookie1": "value",
    "cookie2": "value"
  },
  "query":      {
    "query-string1": "value",
    "query-string2": "value"
  },
  "body-form":  {
    "form-param1": "value",
    "form-param2": "value"
  },
  "body-json":  {
    "json-path1": "value",
    "json-path2": "value"
  },
  "body-xml" :  {
    "xpath1":    "value",
    "xpath2":    "value"
  }
}
```

単一のヘッダーを設定する例:

```json
{
  "headers": {
    "Authorization": "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

ヘッダーとCookieの両方を設定する例:

```json
{
  "headers": {
    "Authorization": "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  },
  "cookies": {
    "flags": "677"
  }
}
```

`body-form`オーバーライドを設定する使用例:

```json
{
  "body-form":  {
    "username": "john.doe"
  }
}
```

リクエスト本文にフォームデータコンテンツのみが含まれている場合、オーバーライドエンジンは`body-form`を使用します。

`body-json`オーバーライドを設定する使用例:

```json
{
  "body-json":  {
    "$.credentials.access-token": "iddqd!42.$"
  }
}
```

オブジェクト`body-json`の各JSONプロパティ名は、[JSONパス](https://goessner.net/articles/JsonPath/)式に設定されます。JSONパス式`$.credentials.access-token`は、値`iddqd!42.$`で上書きされるノードを識別します。リクエスト本文に[JSON](https://www.json.org/json-en.html)コンテンツのみが含まれている場合、オーバーライドエンジンは`body-json`を使用します。

たとえば、本文が次のJSONに設定されている場合:

```json
{
    "credentials" : {
        "username" :"john.doe",
        "access-token" : "non-valid-password"
    }
}
```

次のように変更されます:

```json
{
    "credentials" : {
        "username" :"john.doe",
        "access-token" : "iddqd!42.$"
    }
}
```

`body-xml`オーバーライドを設定する例を次に示します。最初のエントリはXML属性を上書きし、2番目のエントリはXML要素を上書きします:

```json
{
  "body-xml" :  {
    "/credentials/@isEnabled": "true",
    "/credentials/access-token/text()" : "iddqd!42.$"
  }
}
```

オブジェクト`body-xml`の各JSONプロパティ名は、[XPath v2](https://www.w3.org/TR/xpath20/)式に設定されます。XPath式`/credentials/@isEnabled`は、値`true`でオーバーライドする属性ノードを識別します。XPath式`/credentials/access-token/text()`は、値`iddqd!42.$`でオーバーライドする要素ノードを識別します。リクエスト本文に[XML](https://www.w3.org/XML/)コンテンツのみが含まれている場合、オーバーライドエンジンは`body-xml`を使用します。

たとえば、本文が次のXMLに設定されている場合:

```xml
<credentials isEnabled="false">
  <username>john.doe</username>
  <access-token>non-valid-password</access-token>
</credentials>
```

次のように変更されます:

```xml
<credentials isEnabled="true">
  <username>john.doe</username>
  <access-token>iddqd!42.$</access-token>
</credentials>
```

このJSONドキュメントは、ファイルまたは環境変数として提供できます。JSONドキュメントを生成するコマンドを提供することもできます。コマンドは、有効期限が切れる値をサポートするために、一定の間隔で実行できます。

### ファイルの使用 {#using-a-file}

JSONをファイルとしてオーバーライドするには、`FUZZAPI_OVERRIDES_FILE`CI/CD変数を設定します。パスは、ジョブの現在の作業ディレクトリに対する相対パスです。

`.gitlab-ci.yml`の例を次に示します:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
```

### CI/CD変数の使用 {#using-a-cicd-variable}

CI/CD変数としてJSONをオーバーライドするには、`FUZZAPI_OVERRIDES_ENV`変数を使用します。これにより、マスクおよび保護できる変数としてJSONを配置できます。

この`.gitlab-ci.yml`の例では、`FUZZAPI_OVERRIDES_ENV`変数がJSONに直接設定されています:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_ENV: '{"headers":{"X-API-Version":"2"}}'
```

この`.gitlab-ci.yml`の例では、`SECRET_OVERRIDES`変数がJSONを提供します。これは[UIで定義されたグループまたはインスタンスレベルのCI/CD変数です](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui):

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_ENV: $SECRET_OVERRIDES
```

### コマンドの使用 {#using-a-command}

値を生成または再生成する必要がある場合は、APIファザーが指定された間隔で実行するプログラムまたはスクリプトを提供できます。指定されたスクリプトは、Python 3とBashがインストールされているAlpine Linuxパッケージのコンテナで実行されます。

実行するプログラムまたはスクリプトに環境変数`FUZZAPI_OVERRIDES_CMD`を設定する必要があります。指定されたコマンドは、以前に定義したように、オーバーライドJSONファイルを作成します。

NodeJSやRubyなどの他のスクリプトランタイムをインストールするか、オーバーライドコマンドの依存関係をインストールする必要がある場合があります。この場合、これらの前提条件を提供するスクリプトのファイルパスに`FUZZAPI_PRE_SCRIPT`を設定する必要があります。`FUZZAPI_PRE_SCRIPT`によって提供されるスクリプトは、アナライザーが起動する前に1回実行されます。

{{< alert type="note" >}}

昇格された権限を必要とするアクションを実行する場合は、`sudo`コマンドを使用します。たとえば`sudo apk add nodejs`などです。

{{< /alert >}}

Alpine Linuxパッケージのインストールについては、[Alpine Linuxパッケージのパッケージ管理](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management)ページを参照してください。

正しい操作のために、それぞれ設定された3つのCI/CD変数を指定する必要があります:

- `FUZZAPI_OVERRIDES_FILE`: 指定されたコマンドによって生成されたファイル。
- `FUZZAPI_OVERRIDES_CMD`: オーバーライドJSONファイルを定期的に生成するコマンドをオーバーライドします。
- `FUZZAPI_OVERRIDES_INTERVAL`: コマンドを実行する間隔（秒単位）。

オプション:

- `FUZZAPI_PRE_SCRIPT`: アナライザーが起動する前に、ランタイムまたは依存関係をインストールするスクリプト。

{{< alert type="warning" >}}

Alpine Linuxパッケージでスクリプトを実行するには、最初にコマンド[`chmod`](https://www.gnu.org/software/coreutils/manual/html_node/chmod-invocation.html)を使用して[実行権限](https://www.gnu.org/software/coreutils/manual/html_node/Setting-Permissions.html)を設定する必要があります。たとえば、すべての人に`script.py`の実行権限を設定するには、コマンド: `sudo chmod a+x script.py`を使用します。必要に応じて、実行権限がすでに設定されている`script.py`をバージョン管理できます。

{{< /alert >}}

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
  FUZZAPI_OVERRIDES_CMD: renew_token.py
  FUZZAPI_OVERRIDES_INTERVAL: 300
```

### デバッグオーバーライド {#debugging-overrides}

デフォルトでは、オーバーライドコマンドの出力は非表示になっています。オーバーライドコマンドがゼロ以外の終了コードを返す場合、コマンドはジョブ出力の一部として表示されます。オプションで、`FUZZAPI_OVERRIDES_CMD_VERBOSE`変数を任意の値に設定して、生成されたときにオーバーライドコマンド出力を表示できます。これは、オーバーライドスクリプトをテストするときに役立ちますが、テストの速度が低下するため、後で無効にする必要があります。

ジョブが完了または失敗すると収集されるログファイルに、スクリプトからメッセージを書き込むこともできます。ログファイルは、特定の場所に作成し、命名規則に従う必要があります。

スクリプトがジョブの通常の実行中に予期せず失敗した場合に備えて、オーバーライドスクリプトに基本的なログをいくつか追加すると便利です。ログファイルはジョブのアーティファクトとして自動的に含まれるため、ジョブが完了した後にダウンロードできます。

例に従って、環境変数`FUZZAPI_OVERRIDES_CMD`で`renew_token.py`を提供しました。スクリプトには2つの注意点があります:

- ログファイルは、環境変数`CI_PROJECT_DIR`で示された場所に保存されます。
- ログファイル名は`gl-*.log`と一致する必要があります。

```python
#!/usr/bin/env python

# Example of an overrides command

# Override commands can update the overrides json file
# with new values to be used.  This is a great way to
# update an authentication token that will expire
# during testing.

import logging
import json
import os
import requests
import backoff

# [1] Store log file in directory indicated by env var CI_PROJECT_DIR
working_directory = os.environ.get( 'CI_PROJECT_DIR')
overrides_file_name = os.environ.get('FUZZAPI_OVERRIDES_FILE', 'api-fuzzing-overrides.json')
overrides_file_path = os.path.join(working_directory, overrides_file_name)

# [2] File name should match the pattern: gl-*.log
log_file_path = os.path.join(working_directory, 'gl-user-overrides.log')

# Set up logger
logging.basicConfig(filename=log_file_path, level=logging.DEBUG)

# Use `backoff` decorator to retry in case of transient errors.
@backoff.on_exception(backoff.expo,
                      (requests.exceptions.Timeout,
                       requests.exceptions.ConnectionError),
                       max_time=30)
def get_auth_response():
    authorization_url = 'https://authorization.service/api/get_api_token'
    return requests.get(
        f'{authorization_url}',
        auth=(os.environ.get('AUTH_USER'), os.environ.get('AUTH_PWD'))
    )

# In our example, access token is retrieved from a given endpoint
try:

    # Performs a http request, response sample:
    # { "Token" : "abcdefghijklmn" }
    response = get_auth_response()

    # Check that the request is successful. may raise `requests.exceptions.HTTPError`
    response.raise_for_status()

    # Gets JSON data
    response_body = response.json()

# If needed specific exceptions can be caught
# requests.ConnectionError                  : A network connection error problem occurred
# requests.HTTPError                        : HTTP request returned an unsuccessful status code. [Response.raise_for_status()]
# requests.ConnectTimeout                   : The request timed out while trying to connect to the remote server
# requests.ReadTimeout                      : The server did not send any data in the allotted amount of time.
# requests.TooManyRedirects                 : The request exceeds the configured number of maximum redirections
# requests.exceptions.RequestException      : All exceptions that related to Requests
except json.JSONDecodeError as json_decode_error:
    # logs errors related decoding JSON response
    logging.error(f'Error, failed while decoding JSON response. Error message: {json_decode_error}')
    raise
except requests.exceptions.RequestException as requests_error:
    # logs  exceptions  related to `Requests`
    logging.error(f'Error, failed while performing HTTP request. Error message: {requests_error}')
    raise
except Exception as e:
    # logs any other error
    logging.error(f'Error, unknown error while retrieving access token. Error message: {e}')
    raise

# computes object that holds overrides file content.
# It uses data fetched from request
overrides_data = {
    "headers": {
        "Authorization": f"Token {response_body['Token']}"
    }
}

# log entry informing about the file override computation
logging.info("Creating overrides file: %s" % overrides_file_path)

# attempts to overwrite the file
try:
    if os.path.exists(overrides_file_path):
        os.unlink(overrides_file_path)

    # overwrites the file with our updated dictionary
    with open(overrides_file_path, "wb+") as fd:
        fd.write(json.dumps(overrides_data).encode('utf-8'))
except Exception as e:
    # logs any other error
    logging.error(f'Error, unknown error when overwriting file {overrides_file_path}. Error message: {e}')
    raise

# logs informing override has finished successfully
logging.info("Override file has been updated")

# end
```

オーバーライドコマンドの例では、Pythonスクリプトは`backoff`ライブラリに依存しています。Pythonスクリプトを実行する前にライブラリがインストールされていることを確認するために、`FUZZAPI_PRE_SCRIPT`は、オーバーライドコマンドの依存関係をインストールするスクリプトに設定されています。たとえば、次のスクリプト`user-pre-scan-set-up.sh`のようにします:

```shell
#!/bin/bash

# user-pre-scan-set-up.sh
# Ensures python dependencies are installed

echo "**** install python dependencies ****"

sudo pip3 install --no-cache --upgrade --break-system-packages \
    requests \
    backoff

echo "**** python dependencies installed ****"

# end
```

`FUZZAPI_PRE_SCRIPT`を新しい`user-pre-scan-set-up.sh`スクリプトに設定するように設定を更新する必要があります。例: 

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_PRE_SCRIPT: user-pre-scan-set-up.sh
  FUZZAPI_OVERRIDES_FILE: api-fuzzing-overrides.json
  FUZZAPI_OVERRIDES_CMD: renew_token.py
  FUZZAPI_OVERRIDES_INTERVAL: 300
```

前のサンプルでは、スクリプト`user-pre-scan-set-up.sh`を使用して、オーバーライドコマンドで後で使用できる新しいランタイムまたはアプリケーションをインストールすることもできます。

## パスの除外 {#exclude-paths}

APIをテストする場合、特定のパスを除外すると便利な場合があります。たとえば、認証サービスまたはAPIの以前のバージョンのテストを除外する場合があります。パスを除外するには、`FUZZAPI_EXCLUDE_PATHS`CI/CD変数を使用します。この変数は、`.gitlab-ci.yml`ファイルで指定されます。複数のパスを除外するには、`;`文字を使用してエントリを区切ります。指定されたパスでは、単一文字のワイルドカード`?`と、複数文字のワイルドカードに`*`を使用できます。

パスが除外されていることを確認するには、ジョブ出力の`Tested Operations`と`Excluded Operations`の部分をレビューします。`Tested Operations`の下にリストされている除外されたパスは表示されません。

```plaintext
2021-05-27 21:51:08 [INF] API Fuzzing: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API Fuzzing: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API Fuzzing: ------------------------------------------------
2021-05-27 21:51:08 [INF] API Fuzzing: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API Fuzzing: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Fuzzing: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Fuzzing: ------------------------------------------------
```

### パスの除外例 {#examples-of-excluding-paths}

この例では、`/auth`リソースを除外しています。これは、子リソース（`/auth/child`）を除外するものではありません。

```yaml
variables:
  FUZZAPI_EXCLUDE_PATHS: /auth
```

`/auth`、および子リソース（`/auth/child`）を除外するには、ワイルドカードを使用します。

```yaml
variables:
  FUZZAPI_EXCLUDE_PATHS: /auth*
```

複数のパスを除外するには、`;`文字を使用します。この例では、`/auth*`と`/v1/*`を除外しています。

```yaml
variables:
  FUZZAPI_EXCLUDE_PATHS: /auth*;/v1/*
```

## パラメータを除外 {#exclude-parameters}

APIをテストしている間、テストからパラメータ（クエリ文字列、ヘッダー、または本文要素）を除外したい場合があります。これは、パラメータが常に失敗を引き起こしたり、テストの速度を低下させたり、その他の理由で必要になる場合があります。パラメータを除外するには、次の変数のいずれかを使用できます: `FUZZAPI_EXCLUDE_PARAMETER_ENV`または`FUZZAPI_EXCLUDE_PARAMETER_FILE`。

`FUZZAPI_EXCLUDE_PARAMETER_ENV`を使用すると、除外されたパラメータを含むJSON文字列を指定できます。これは、JSONが短く、頻繁に変更できない場合に適したオプションです。別のオプションは、変数`FUZZAPI_EXCLUDE_PARAMETER_FILE`です。この変数は、リポジトリにチェックインしたり、別のジョブによってアーティファクトとして作成したり、`FUZZAPI_PRE_SCRIPT`を使用してプリスクリプトからランタイム時に生成したりできるファイルパスに設定されます。

### JSONドキュメントを使用したパラメータの除外 {#exclude-parameters-using-a-json-document}

JSONドキュメントには、どのパラメータを除外するかを特定するために特定のプロパティを使用するJSONオブジェクトが含まれています。スキャン処理中に特定のパラメータを除外するために、次のプロパティを指定できます:

- `headers`: 特定のヘッダーを除外するには、このプロパティを使用します。プロパティの値は、除外するヘッダー名の配列です。名前は大文字と小文字が区別されません。
- `cookies`: 特定のCookieを除外するには、このプロパティの値を使用します。プロパティの値は、除外するCookie名の配列です。名前は大文字と小文字が区別されます。
- `query`: クエリ文字列から特定のフィールドを除外するには、このプロパティを使用します。プロパティの値は、除外するクエリ文字列のフィールド名の配列です。名前は大文字と小文字が区別されます。
- `body-form`: このプロパティを使用して、メディアタイプ`application/x-www-form-urlencoded`を使用するリクエストから特定のフィールドを除外します。プロパティの値は、除外する本文のフィールド名の配列です。名前は大文字と小文字が区別されます。
- `body-json`: このプロパティを使用して、メディアタイプ`application/json`を使用するリクエストから特定のJSONノードを除外します。プロパティの値は配列であり、配列の各エントリは[JSONパス](https://goessner.net/articles/JsonPath/)式です。
- `body-xml`: このプロパティを使用して、メディアタイプ`application/xml`を使用するリクエストから特定のXMLノードを除外します。プロパティの値は配列であり、配列の各エントリは[XPath v2](https://www.w3.org/TR/xpath20/)式です。

次のJSONドキュメントは、パラメータを除外するための予期される構造の例です。

```json
{
  "headers": [
    "header1",
    "header2"
  ],
  "cookies": [
    "cookie1",
    "cookie2"
  ],
  "query": [
    "query-string1",
    "query-string2"
  ],
  "body-form": [
    "form-param1",
    "form-param2"
  ],
  "body-json": [
    "json-path-expression-1",
    "json-path-expression-2"
  ],
  "body-xml" : [
    "xpath-expression-1",
    "xpath-expression-2"
  ]
}
```

### 例 {#examples}

#### 単一のヘッダーの除外 {#excluding-a-single-header}

ヘッダー`Upgrade-Insecure-Requests`を除外するには、`header`プロパティの値を、ヘッダー名`[ "Upgrade-Insecure-Requests" ]`を持つ配列に設定します。たとえば、JSONドキュメントは次のようになります:

```json
{
  "headers": [ "Upgrade-Insecure-Requests" ]
}
```

ヘッダー名では大文字と小文字は区別されないため、ヘッダー名`UPGRADE-INSECURE-REQUESTS`は`Upgrade-Insecure-Requests`と同等です。

#### ヘッダーと2つのCookieの両方の除外 {#excluding-both-a-header-and-two-cookies}

ヘッダー`Authorization`とCookie `PHPSESSID`および`csrftoken`を除外するには、`headers`プロパティの値を、ヘッダー名`[ "Authorization" ]`を持つ配列に設定し、`cookies`プロパティの値を、Cookie名`[ "PHPSESSID", "csrftoken" ]`を持つ配列に設定します。たとえば、JSONドキュメントは次のようになります:

```json
{
  "headers": [ "Authorization" ],
  "cookies": [ "PHPSESSID", "csrftoken" ]
}
```

#### `body-form`パラメータの除外 {#excluding-a-body-form-parameter}

`application/x-www-form-urlencoded`を使用するリクエストで、`password`フィールドを除外するには、`body-form`プロパティの値を、フィールド名`[ "password" ]`を持つ配列に設定します。たとえば、JSONドキュメントは次のようになります:

```json
{
  "body-form":  [ "password" ]
}
```

リクエストがコンテンツタイプ`application/x-www-form-urlencoded`を使用する場合、除外パラメータは`body-form`を使用します。

#### JSONパスを使用した特定のJSONノードの除外 {#excluding-a-specific-json-nodes-using-json-path}

ルートオブジェクトの`schema`プロパティを除外するには、`body-json`プロパティの値を、JSONパス式`[ "$.schema" ]`を持つ配列に設定します。

JSONパス式は、JSONノードを識別するために特別な構文を使用します。`$`はJSONドキュメントのルートを参照し、`.`は現在のオブジェクト(この場合、ルートオブジェクト)を参照し、テキスト`schema`はプロパティ名を参照します。したがって、JSONパス式`$.schema`は、ルートオブジェクトのプロパティ`schema`を参照します。たとえば、JSONドキュメントは次のようになります:

```json
{
  "body-json": [ "$.schema" ]
}
```

リクエストがコンテンツタイプ`application/json`を使用する場合、除外パラメータは`body-json`を使用します。`body-json`の各エントリは、[JSONパス式](https://goessner.net/articles/JsonPath/)であることが想定されます。JSONパスでは、`$`、`*`、`.`などの文字には特別な意味があります。

#### JSONパスを使用した複数のJSONノードの除外 {#excluding-multiple-json-nodes-using-json-path}

ルートレベルで`users`の配列の各エントリにあるプロパティ`password`を除外するには、`body-json`プロパティの値を、JSONパス式`[ "$.users[*].paswword" ]`を持つ配列に設定します。

JSONパス式は、ルートノードを参照するために`$`で始まり、現在のノードを参照するために`.`を使用します。次に、`users`を使用してプロパティを参照し、`[`および`]`文字を使用して、使用する配列内のインデックスを囲みます。インデックスとして数値を指定する代わりに、`*`を使用して任意のインデックスを指定します。インデックスの参照の後には、`.`があり、これは、プロパティ名`password`が前に付いた、配列内の指定されたインデックスを参照します。

たとえば、JSONドキュメントは次のようになります:

```json
{
  "body-json": [ "$.users[*].paswword" ]
}
```

リクエストがコンテンツタイプ`application/json`を使用する場合、除外パラメータは`body-json`を使用します。`body-json`の各エントリは、[JSONパス式](https://goessner.net/articles/JsonPath/)であることが想定されます。JSONパスでは、`$`、`*`、`.`などの文字には特別な意味があります。

#### XML属性の除外 {#excluding-an-xml-attribute}

ルート要素`credentials`にある`isEnabled`という名前の属性を除外するには、`body-xml`プロパティの値を、XPath式`[ "/credentials/@isEnabled" ]`を持つ配列に設定します。

XPath式`/credentials/@isEnabled`は、XMLドキュメントのルートを示すために`/`で始まり、その後に、一致する要素の名前を示す単語`credentials`が続きます。以前のXML要素のノードを参照するために`/`を使用し、名前`isEnable`が属性であることを示すために文字`@`を使用します。

たとえば、JSONドキュメントは次のようになります:

```json
{
  "body-xml": [
    "/credentials/@isEnabled"
  ]
}
```

リクエストがコンテンツタイプ`application/xml`を使用する場合、除外パラメータは`body-xml`を使用します。`body-xml`の各エントリは、[XPath v2式](https://www.w3.org/TR/xpath20/)であることが想定されます。XPath式では、`@`、`/`、`:`、`[`、`]`などの文字には特別な意味があります。

#### XML要素のテキストの除外 {#excluding-an-xml-elements-text}

ルートノード`credentials`に含まれる`username`要素のテキストを除外するには、`body-xml`プロパティの値を、XPath式`[/credentials/username/text()" ]`を持つ配列に設定します。

XPath式`/credentials/username/text()`では、最初の文字`/`はルートXMLノードを参照し、その後にXML要素の名前`credentials`を示します。同様に、文字`/`は現在の要素を参照し、その後に新しいXML要素の名前`username`が続きます。最後のパートには、現在の要素を参照する`/`があり、現在の要素のテキストを識別する`text()`というXPath関数を使用します。

たとえば、JSONドキュメントは次のようになります:

```json
{
  "body-xml": [
    "/credentials/username/text()"
  ]
}
```

リクエストがコンテンツタイプ`application/xml`を使用する場合、除外パラメータは`body-xml`を使用します。`body-xml`の各エントリは、[XPath v2式](https://www.w3.org/TR/xpath20/)であることが想定されます。XPath式では、`@`、`/`、`:`、`[`、`]`などの文字には特別な意味があります。

#### XML要素の除外 {#excluding-an-xml-element}

ルートノード`credentials`に含まれる要素`username`を除外するには、`body-xml`プロパティの値を、XPath式`[/credentials/username" ]`を持つ配列に設定します。

XPath式`/credentials/username`では、最初の文字`/`はルートXMLノードを参照し、その後にXML要素の名前`credentials`を示します。同様に、文字`/`は現在の要素を参照し、その後に新しいXML要素の名前`username`が続きます。

たとえば、JSONドキュメントは次のようになります:

```json
{
  "body-xml": [
    "/credentials/username"
  ]
}
```

リクエストがコンテンツタイプ`application/xml`を使用する場合、除外パラメータは`body-xml`を使用します。`body-xml`の各エントリは、[XPath v2式](https://www.w3.org/TR/xpath20/)であることが想定されます。XPath式では、`@`、`/`、`:`、`[`、`]`などの文字には特別な意味があります。

#### ネームスペースを持つXMLノードの除外 {#excluding-an-xml-node-with-namespaces}

ネームスペース`s`で定義され、`credentials`ルートノードに含まれるXML要素`login`を除外するには、`body-xml`プロパティの値を、XPath式`[ "/credentials/s:login" ]`を持つ配列に設定します。

XPath式`/credentials/s:login`では、最初の文字`/`はルートXMLノードを参照し、その後にXML要素の名前`credentials`を示します。同様に、文字`/`は現在の要素を参照し、その後に新しいXML要素の名前`s:login`が続きます。名前には文字`:`が含まれています。この文字は、ネームスペースとノード名を区切ります。

ネームスペース名は、本文リクエストの一部であるXMLドキュメントで定義されている必要があります。仕様ドキュメントHAR、OpenAPI、またはPostmanコレクションファイルでネームスペースを確認できます。

```json
{
  "body-xml": [
    "/credentials/s:login"
  ]
}
```

リクエストがコンテンツタイプ`application/xml`を使用する場合、除外パラメータは`body-xml`を使用します。`body-xml`の各エントリは、[XPath v2式](https://www.w3.org/TR/xpath20/)であることが想定されます。XPath式では、`@`、`/`、`:`、`[`、`]`などの文字には特別な意味があります。

### JSON文字列の使用 {#using-a-json-string}

除外JSONドキュメントを設定するには、JSON文字列で変数`FUZZAPI_EXCLUDE_PARAMETER_ENV`を設定します。次の例では、`.gitlab-ci.yml`、`FUZZAPI_EXCLUDE_PARAMETER_ENV`変数はJSON文字列に設定されます:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_EXCLUDE_PARAMETER_ENV: '{ "headers": [ "Upgrade-Insecure-Requests" ] }'
```

### ファイルの使用 {#using-a-file-1}

除外JSONドキュメントを提供するには、JSONファイルパスで変数`FUZZAPI_EXCLUDE_PARAMETER_FILE`を設定します。ファイルパスは、ジョブの現在の作業ディレクトリに対する相対パスです。次の例の`.gitlab-ci.yml`ファイルでは、`FUZZAPI_EXCLUDE_PARAMETER_FILE`変数はJSONファイルのパスに設定されています:

```yaml
stages:
     - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_EXCLUDE_PARAMETER_FILE: api-fuzzing-exclude-parameters.json
```

`api-fuzzing-exclude-parameters.json`は、[パラメータドキュメントを除外する](#exclude-parameters-using-a-json-document)の構造に従うJSONドキュメントです。

## URLの除外 {#exclude-urls}

パスで除外する代わりに、`FUZZAPI_EXCLUDE_URLS` CI/CD変数を使用して、URL内の他のコンポーネントでフィルタリングできます。この変数は、`.gitlab-ci.yml`ファイルで設定できます。変数は、コンマ(`,`)で区切られた複数の値を格納できます。各値は正規表現です。各エントリが正規表現であるため、`.*`などのエントリは、すべてに一致する正規表現であるため、すべてのURLを除外します。

ジョブの出力で、`FUZZAPI_EXCLUDE_URLS`から提供された正規表現に一致するURLがあるかどうかを確認できます。一致するオペレーションは、**Excluded Operations**（除外されたオペレーション） セクションにリストされています。**Excluded Operations**（除外されたオペレーション） にリストされているオペレーションは、**Tested Operations**（テストされたオペレーション） セクションにリストされていてはなりません。たとえば、ジョブの出力の次の部分:

```plaintext
2021-05-27 21:51:08 [INF] API Fuzzing: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API Fuzzing: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API Fuzzing: ------------------------------------------------
2021-05-27 21:51:08 [INF] API Fuzzing: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API Fuzzing: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Fuzzing: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API Fuzzing: ------------------------------------------------
```

{{< alert type="note" >}}

`FUZZAPI_EXCLUDE_URLS`の各値は正規表現です。`.`、`*`、`$`などの文字は、[の正規表現](https://en.wikipedia.org/wiki/Regular_expression#Standards)で特別な意味を持ちます。

{{< /alert >}}

### 例 {#examples-1}

#### URLと子リソースの除外 {#excluding-a-url-and-child-resources}

次の例では、URL `http://target/api/auth`とその子リソースを除外します。

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://target/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_EXCLUDE_URLS: http://target/api/auth
```

#### 2つのURLを除外し、その子リソースを許可する {#excluding-two-urls-and-allow-their-child-resources}

URL `http://target/api/buy`と`http://target/api/sell`を除外しますが、その子リソースのスキャンを許可します。たとえば、`http://target/api/buy/toy`や`http://target/api/sell/chair`などです。値`http://target/api/buy/$,http://target/api/sell/$`を使用できます。この値は2つの正規表現を使用しており、それぞれが`,`文字で区切られています。したがって、`http://target/api/buy$`と`http://target/api/sell$`が含まれます。各正規表現では、末尾の`$`文字は、一致するURLが終了する場所を示します。

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://target/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_EXCLUDE_URLS: http://target/api/buy/$,http://target/api/sell/$
```

#### 2つのURLとその子リソースの除外 {#excluding-two-urls-and-their-child-resources}

URL: `http://target/api/buy`と`http://target/api/sell`、およびその子リソースを除外するには。複数のURLを提供するには、次のように`,`文字を使用します:

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://target/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_EXCLUDE_URLS: http://target/api/buy,http://target/api/sell
```

#### 正規表現を使用したURLの除外 {#excluding-url-using-regular-expressions}

正確に`https://target/api/v1/user/create`と`https://target/api/v2/user/create`、またはその他のバージョン(`v3`、`v4`など)を除外するには、`https://target/api/v.*/user/create$`を使用します。前の正規表現:

- `.`は任意の文字を示します。
- `*`はゼロ回以上を示します。
- `$`は、URLがそこで終了する必要があることを示します。

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://target/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_EXCLUDE_URLS: https://target/api/v.*/user/create$
```

## ヘッダーファジング {#header-fuzzing}

ヘッダーファジングは、多くのテクノロジスタックで発生する誤検出が多いため、デフォルトで無効になっています。ヘッダーファジングを有効にする場合は、ファジングに含めるヘッダーのリストを指定する必要があります。

デフォルトの設定ファイルの各プロファイルには、`GeneralFuzzingCheck`のエントリがあります。このチェックは、ヘッダーファジングを実行します。`Configuration`セクションで、ヘッダーファジングを有効にするには、`HeaderFuzzing`および`Headers`の設定を変更する必要があります。

このスニペットは、ヘッダーファジングが無効になっている`Quick-10`プロファイルのデフォルト設定を示しています:

```yaml
- Name: Quick-10
  DefaultProfile: Empty
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
        HeaderFuzzing: false
        Headers:
    - Name: JsonFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
    - Name: XmlFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
```

`HeaderFuzzing`は、ヘッダーファジングのオン/オフを切り替えるブール値です。デフォルトの設定は、オフの場合は`false`です。ヘッダーファジングをオンにするには、この設定を`true`に変更します:

```yaml
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: true
        Headers:
```

`Headers`は、ファジングするヘッダーのリストです。リストされているヘッダーのみがファジングされます。APIで使用されるヘッダーをファジングするには、構文`- Name: HeaderName`を使用して、そのエントリを追加します。たとえば、カスタムヘッダー`X-Custom`をファジングするには、`- Name: X-Custom`を追加します:

```yaml
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: true
        Headers:
          - Name: X-Custom
```

これで、ヘッダー`X-Custom`をファジングする設定ができました。同じ表記法を使用して、追加のヘッダーをリストします:

```yaml
    - Name: GeneralFuzzingCheck
      Configuration:
        FuzzingCount: 10
        UnicodeFuzzing: true
        HeaderFuzzing: true
        Headers:
          - Name: X-Custom
          - Name: X-AnotherHeader
```

必要に応じて、各プロファイルに対してこの設定を繰り返します。
