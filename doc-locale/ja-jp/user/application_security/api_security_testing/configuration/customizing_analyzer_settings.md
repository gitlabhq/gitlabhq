---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: アナライザー設定をカスタマイズする
---

## 認証 {#authentication}

認証は、認証トークンをヘッダーまたはCookieとして提供することで処理されます。認証フローを実行するか、トークンを計算するスクリプトを提供できます。

### HTTP基本認証 {#http-basic-authentication}

[HTTP Basic認証](https://en.wikipedia.org/wiki/Basic_access_authentication)は、HTTPプロトコルに組み込まれ、[トランスポートレイヤーセキュリティ（TLS）](https://en.wikipedia.org/wiki/Transport_Layer_Security)と組み合わせて使用される認証方法です。

パスワードには[CI/CD変数を作成](../../../../ci/variables/_index.md#for-a-project)（例: `TEST_API_PASSWORD`）し、マスクされた変数に設定することをお勧めします。GitLabプロジェクトのページで、**設定** > **CI/CD**の**変数**セクションからCI/CD変数を作成できます。[マスクされた変数の制限](../../../../ci/variables/_index.md#mask-a-cicd-variable)のため、変数として追加する前に、パスワードをBase64でエンコードする必要があります。

最後に、`.gitlab-ci.yml`ファイルに2つのCI/CD変数を追加します:

- `APISEC_HTTP_USERNAME`: 認証用のユーザー名。
- `APISEC_HTTP_PASSWORD_BASE64`: 認証用のBase64エンコードされたパスワード。

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_HAR: test-api-recording.har
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_HTTP_USERNAME: testuser
  APISEC_HTTP_PASSWORD_BASE64: $TEST_API_PASSWORD
```

#### Rawパスワード {#raw-password}

パスワードをBase64でエンコードしない場合（またはGitLabバージョン15.3以前のバージョンを使用している場合）、`APISEC_HTTP_PASSWORD_BASE64`を使用する代わりに、rawパスワード`APISEC_HTTP_PASSWORD`を指定できます。

### ベアラートークン {#bearer-tokens}

ベアラートークンは、OAuth2やJSON Webトークン（JWT）など、いくつかの異なる認証メカニズムで使用されます。ベアラートークンは、`Authorization` HTTPヘッダーを使用して送信されます。APIセキュリティテストでベアラートークンを使用するには、次のいずれかが必要です:

- 有効期限切れにならないトークン。
- テストの長さに耐えるトークンを生成する方法。
- APIセキュリティテストが呼び出してトークンを生成できるPythonスクリプト。

#### トークンは有効期限切れにならない {#token-doesnt-expire}

ベアラートークンが有効期限切れにならない場合は、`APISEC_OVERRIDES_ENV`変数を使用して指定します。この変数のコンテンツは、APIセキュリティテストの発信HTTPリクエストに追加するヘッダーとCookieを提供するJSONスニペットです。

次の手順に従って、`APISEC_OVERRIDES_ENV`でベアラートークンを指定します:

1. [CI/CD変数を作成](../../../../ci/variables/_index.md#for-a-project)します。たとえば、値`{"headers":{"Authorization":"Bearer dXNlcm5hbWU6cGFzc3dvcmQ="}}`（トークンを代入）を持つ`TEST_API_BEARERAUTH`などです。GitLabプロジェクトのページで、**設定** > **CI/CD**の**変数**セクションからCI/CD変数を作成できます。`TEST_API_BEARERAUTH`の形式のため、変数をマスクすることはできません。トークンの値をマスクするには、トークン値を持つ2番目の変数を作成し、値`{"headers":{"Authorization":"Bearer $MASKED_VARIABLE"}}`で`TEST_API_BEARERAUTH`を定義します。

1. `.gitlab-ci.yml`ファイルで、作成したばかりの変数に`APISEC_OVERRIDES_ENV`を設定します:

   ```yaml
   stages:
     - dast

   include:
     - template: API-Security.gitlab-ci.yml

   variables:
     APISEC_PROFILE: Quick
     APISEC_OPENAPI: test-api-specification.json
     APISEC_TARGET_URL: http://test-deployment/
     APISEC_OVERRIDES_ENV: $TEST_API_BEARERAUTH
   ```

1. 認証が機能していることを検証するには、APIセキュリティテストを実行し、ジョブログとテストAPIのアプリケーションログファイルを確認します。

#### テストランタイムで生成されたトークン {#token-generated-at-test-runtime}

ベアラートークンを生成する必要があり、テスト中に有効期限が切れない場合は、トークンを含むファイルをAPIセキュリティテストに提供できます。前のステージングとジョブ、またはAPIセキュリティテストジョブの一部で、このファイルを生成できます。

APIセキュリティテストでは、次の構造のJSONファイルを受け取ることを想定しています:

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

このファイルは、前のステージングで生成し、`APISEC_OVERRIDES_FILE`CI/CD変数を介してAPIセキュリティテストに提供できます。

`.gitlab-ci.yml`ファイルで`APISEC_OVERRIDES_FILE`を設定します:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
```

認証が機能していることを検証するには、APIセキュリティテストを実行し、ジョブログとテストAPIのアプリケーションログファイルを確認します。

#### トークンの有効期限が短い {#token-has-short-expiration}

ベアラートークンを生成する必要があり、スキャンの完了前に有効期限が切れる場合は、APIセキュリティテストスキャナーが指定された間隔で実行するプログラムまたはスクリプトを提供できます。指定されたスクリプトは、Python 3とBashがインストールされたAlpine Linuxコンテナで実行されます。Pythonスクリプトに追加の依存関係パッケージが必要な場合は、これを検出し、ランタイム時にパッケージをインストールする必要があります。

スクリプトは、特定の形式でベアラートークンを含むJSONファイルを作成する必要があります:

```json
{
  "headers" : {
    "Authorization" : "Bearer dXNlcm5hbWU6cGFzc3dvcmQ="
  }
}
```

3つのCI/CD変数を指定する必要があります。各変数は正しく動作するように設定されています:

- `APISEC_OVERRIDES_FILE`: 指定されたコマンドが生成するJSONファイル。
- `APISEC_OVERRIDES_CMD`: JSONファイルを生成するコマンド。
- `APISEC_OVERRIDES_INTERVAL`: コマンドを実行する間隔（秒単位）。

例: 

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
  APISEC_OVERRIDES_CMD: renew_token.py
  APISEC_OVERRIDES_INTERVAL: 300
```

認証が機能していることを検証するには、APIセキュリティテストを実行し、ジョブログとテストAPIのアプリケーションログファイルを確認します。オーバーライドコマンドの詳細については、[オーバーライドセクション](#overrides)を参照してください。

## オーバーライド {#overrides}

APIセキュリティテストには、リクエスト内の特定の項目を追加またはオーバーライドする方法が用意されています。次に例を示します:

- ヘッダー
- Cookie
- クエリ文字列
- フォームデータ
- JSONノード
- XMLノード

これを使用すると、セマンティックバージョンヘッダー、認証などを挿入できます。[認証セクション](#authentication)には、その目的のためにオーバーライドを使用する例が含まれています。

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

`body-form`オーバーライドを設定するための使用例:

```json
{
  "body-form":  {
    "username": "john.doe"
  }
}
```

リクエストボディにフォームデータコンテンツのみが含まれている場合、オーバーライドエンジンは`body-form`を使用します。

`body-json`オーバーライドを設定するための使用例:

```json
{
  "body-json":  {
    "$.credentials.access-token": "iddqd!42.$"
  }
}
```

オブジェクト`body-json`の各JSONプロパティ名は、[JSONパス](https://goessner.net/articles/JsonPath/)式に設定されます。JSONパス式`$.credentials.access-token`は、値`iddqd!42.$`でオーバーライドされるノードを識別します。リクエストボディに[JSON](https://www.json.org/json-en.html)コンテンツのみが含まれている場合、オーバーライドエンジンは`body-json`を使用します。

たとえば、ボディが次のJSONに設定されているとします:

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

次に、`body-xml`オーバーライドを設定する例を示します。最初のエントリはXML属性をオーバーライドし、2番目のエントリはXML要素をオーバーライドします:

```json
{
  "body-xml" :  {
    "/credentials/@isEnabled": "true",
    "/credentials/access-token/text()" : "iddqd!42.$"
  }
}
```

オブジェクト`body-xml`の各JSONプロパティ名は、[XPath v2](https://www.w3.org/TR/xpath20/)式に設定されます。XPath式`/credentials/@isEnabled`は、値`true`でオーバーライドされる属性ノードを識別します。XPath式`/credentials/access-token/text()`は、値`iddqd!42.$`でオーバーライドされる要素ノードを識別します。リクエストボディに[XML](https://www.w3.org/XML/)コンテンツのみが含まれている場合、オーバーライドエンジンは`body-xml`を使用します。

たとえば、ボディが次のXMLに設定されているとします:

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

このJSONドキュメントは、ファイルまたは環境変数として指定できます。JSONドキュメントを生成するコマンドを指定することもできます。コマンドは、有効期限が切れる値をサポートするために、一定の間隔で実行できます。

### ファイルの使用 {#using-a-file}

オーバーライドJSONをファイルとして指定するには、`APISEC_OVERRIDES_FILE`CI/CD変数を設定します。パスは、ジョブの現在の作業ディレクトリに対する相対パスです。

次に`.gitlab-ci.yml`の例を示します:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
```

### CI/CD変数の使用 {#using-a-cicd-variable}

オーバーライドJSONをCI/CD変数として指定するには、`APISEC_OVERRIDES_ENV`変数を使用します。これにより、マスクおよび保護できる変数としてJSONを配置できます。

この`.gitlab-ci.yml`の例では、`APISEC_OVERRIDES_ENV`変数はJSONに直接設定されます:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_ENV: '{"headers":{"X-API-Version":"2"}}'
```

この`.gitlab-ci.yml`の例では、`SECRET_OVERRIDES`変数はJSONを提供します。これは[UIで定義されたグループまたはインスタンスCI/CD変数](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)です:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_ENV: $SECRET_OVERRIDES
```

### コマンドの使用 {#using-a-command}

値が生成されるか、有効期限が切れたときに再生成する必要がある場合は、指定された間隔でAPIセキュリティテストスキャナーが実行するプログラムまたはスクリプトを指定できます。指定されたコマンドは、Python 3とBashがインストールされたAlpine Linuxコンテナで実行されます。

環境変数`APISEC_OVERRIDES_CMD`を実行するプログラムまたはスクリプトに設定する必要があります。指定されたコマンドは、以前に定義したように、オーバーライドJSONファイルを作成します。

NodeJSやRubyなどの他のスクリプトランタイムをインストールするか、オーバーライドコマンドの依存関係をインストールする必要がある場合があります。この場合、これらの前提条件を提供するスクリプトのファイルパスに`APISEC_PRE_SCRIPT`を設定する必要があります。アナライザーの起動前に、`APISEC_PRE_SCRIPT`によって提供されるスクリプトが1回実行されます。

{{< alert type="note" >}}

昇格された権限を必要とするアクションを実行する場合は、`sudo`コマンドを使用します。たとえば`sudo apk add nodejs`などです。

{{< /alert >}}

Alpine Linuxパッケージのインストールについては、[Alpine Linuxパッケージ管理](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management)ページを参照してください。

3つのCI/CD変数を指定する必要があります。各変数は正しく動作するように設定されています:

- `APISEC_OVERRIDES_FILE`: 指定されたコマンドによって生成されたファイル。
- `APISEC_OVERRIDES_CMD`: JSONファイルを定期的に生成するオーバーライドコマンド。
- `APISEC_OVERRIDES_INTERVAL`: コマンドを実行する間隔（秒単位）。

オプション:

- `APISEC_PRE_SCRIPT`: スキャンが開始される前にランタイムまたは依存関係をインストールするスクリプト。

{{< alert type="warning" >}}

Alpine Linuxでスクリプトを実行するには、まずコマンド[`chmod`](https://www.gnu.org/software/coreutils/manual/html_node/chmod-invocation.html)を使用して、[実行権限](https://www.gnu.org/software/coreutils/manual/html_node/Setting-Permissions.html)を設定する必要があります。たとえば、全員に対して`script.py`の実行権限を設定するには、コマンド`sudo chmod a+x script.py`を使用します。必要に応じて、実行権限がすでに設定されている`script.py`をバージョン管理できます。

{{< /alert >}}

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
  APISEC_OVERRIDES_CMD: renew_token.py
  APISEC_OVERRIDES_INTERVAL: 300
```

### オーバーライドのデバッグ {#debugging-overrides}

デフォルトでは、オーバーライドコマンドの出力は非表示になっています。オプションで、変数`APISEC_OVERRIDES_CMD_VERBOSE`を任意の値に設定して、オーバーライドコマンドの出力を`gl-api-security-scanner.log`ジョブのアーティファクトファイルに記録できます。これは、オーバーライドスクリプトをテストするときに役立ちますが、テスト速度が低下するため、後で無効にする必要があります。

スクリプトから、ジョブの完了時または失敗時に収集されるログファイルにメッセージを書き込むこともできます。ログファイルは、特定の場所に作成し、命名規則に従う必要があります。

オーバーライドスクリプトに基本的なロギングを追加すると、ジョブの標準実行中にスクリプトが予期せず失敗した場合に役立ちます。ログファイルはジョブのアーティファクトとして自動的に含まれ、ジョブの完了後にダウンロードできます。

この例に従って、環境変数`APISEC_OVERRIDES_CMD`で`renew_token.py`を指定しました。スクリプトには2つの点があります:

- ログファイルは、環境変数`CI_PROJECT_DIR`で示される場所に保存されます。
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
overrides_file_name = os.environ.get('APISEC_OVERRIDES_FILE', 'dast-api-overrides.json')
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

オーバーライドコマンドの例では、Pythonスクリプトは`backoff`ライブラリに依存します。Pythonスクリプトを実行する前にライブラリがインストールされていることを確認するために、`APISEC_PRE_SCRIPT`はオーバーライドコマンドの依存関係をインストールするスクリプトに設定されます。たとえば、次のスクリプト`user-pre-scan-set-up.sh`

```shell
#!/bin/bash

# user-pre-scan-set-up.sh
# Ensures python dependencies are installed

echo "**** install python dependencies ****"

sudo pip3 install --no-cache --upgrade --break-system-packages \
    backoff

echo "**** python dependencies installed ****"

# end
```

`APISEC_PRE_SCRIPT`を新しい`user-pre-scan-set-up.sh`スクリプトに設定するように、設定を更新する必要があります。例: 

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_PRE_SCRIPT: ./user-pre-scan-set-up.sh
  APISEC_OVERRIDES_FILE: dast-api-overrides.json
  APISEC_OVERRIDES_CMD: renew_token.py
  APISEC_OVERRIDES_INTERVAL: 300
```

上記のサンプルでは、スクリプト`user-pre-scan-set-up.sh`を使用して、後で使用できる新しいランタイムまたはアプリケーションをインストールすることもできます。

## リクエストヘッダー {#request-headers}

リクエストヘッダー機能を使用すると、スキャンセッション中にヘッダーの固定値を指定できます。たとえば、設定変数`APISEC_REQUEST_HEADERS`を使用して、`Cache-Control`ヘッダーに固定値を設定できます。設定する必要があるヘッダーに`Authorization`ヘッダーなどの機密値が含まれている場合は、[マスクされた変数](../../../../ci/variables/_index.md#mask-a-cicd-variable)機能と[変数`APISEC_REQUEST_HEADERS_BASE64`](#base64)を組み合わせて使用します。

`Authorization`ヘッダーまたはその他のヘッダーをスキャンの進行中に更新する必要がある場合は、[オーバーライド](#overrides)機能の使用を検討してください。

変数`APISEC_REQUEST_HEADERS`を使用すると、カンマ（`,`）で区切られたヘッダーのリストを指定できます。これらのヘッダーは、スキャナーが実行する各リクエストに含まれます。リスト内の各ヘッダーエントリは、名前、その後にコロン（`:`）、その後に値で構成されます。キーまたは値の前の空白は無視されます。たとえば、値`max-age=604800`を持つヘッダー名`Cache-Control`を宣言する場合、ヘッダーエントリは`Cache-Control: max-age=604800`です。2つのヘッダー、`Cache-Control: max-age=604800`と`Age: 100`を使用するには、`APISEC_REQUEST_HEADERS`変数を`Cache-Control: max-age=604800, Age: 100`に設定します。

変数`APISEC_REQUEST_HEADERS`に異なるヘッダーが提供される順序は、結果に影響しません。`APISEC_REQUEST_HEADERS`を`Cache-Control: max-age=604800, Age: 100`に設定すると、`Age: 100, Cache-Control: max-age=604800`に設定するのと同じ結果になります。

### Base64 {#base64}

`APISEC_REQUEST_HEADERS_BASE64`変数は、`APISEC_REQUEST_HEADERS`と同じヘッダーのリストを受け入れますが、変数の値全体をBase64でエンコードする必要があるという違いがあります。たとえば、`APISEC_REQUEST_HEADERS_BASE64`変数を`Authorization: QmVhcmVyIFRPS0VO, Cache-control: bm8tY2FjaGU=`に設定するには、リストをBase64相当の`QXV0aG9yaXphdGlvbjogUW1WaGNtVnlJRlJQUzBWTywgQ2FjaGUtY29udHJvbDogYm04dFkyRmphR1U9`に変換し、Base64でエンコードされた値を使用する必要があります。文字セットの制限がある[マスクされた変数](../../../../ci/variables/_index.md#mask-a-cicd-variable)にシークレットヘッダー値を格納する場合に便利です。

{{< alert type="warning" >}}

Base64は、[マスクされた変数](../../../../ci/variables/_index.md#mask-a-cicd-variable)機能をサポートするために使用されます。Base64エンコードは、機密性の高い値は簡単にデコードできるため、それ自体はセキュリティ対策ではありません。

{{< /alert >}}

### 例: プレーンテキストを使用して各リクエストにヘッダーのリストを追加する {#example-adding-a-list-of-headers-on-each-request-using-plain-text}

次の`.gitlab-ci.yml`の例では、`APISEC_REQUEST_HEADERS`設定変数が、[リクエストヘッダー](#request-headers)で説明されているように、2つのヘッダー値を提供するように設定されています。

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_REQUEST_HEADERS: 'Cache-control: no-cache, Save-Data: on'
```

### 例: マスクされたCI/CD変数を使用する {#example-using-a-masked-cicd-variable}

次の`.gitlab-ci.yml`サンプルは、[マスクされた変数](../../../../ci/variables/_index.md#mask-a-cicd-variable)`SECRET_REQUEST_HEADERS_BASE64`が[UIで定義されたグループまたはインスタンスCI/CD変数](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)として定義されていることを前提としています。`SECRET_REQUEST_HEADERS_BASE64`の値は`WC1BQ01FLVNlY3JldDogc31jcnt0ISwgWC1BQ01FLVRva2VuOiA3MDVkMTZmNWUzZmI=`に設定されています。これは、`X-ACME-Secret: s3cr3t!, X-ACME-Token: 705d16f5e3fb`のBase64エンコードされたテキストバージョンです。その後、次のように使用できます:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_REQUEST_HEADERS_BASE64: $SECRET_REQUEST_HEADERS_BASE64
```

文字セットの制限がある[マスクされた変数](../../../../ci/variables/_index.md#mask-a-cicd-variable)にシークレットヘッダー値を格納する場合は、`APISEC_REQUEST_HEADERS_BASE64`を使用することを検討してください。

## パスの除外 {#exclude-paths}

APIをテストする場合、特定のパスを除外すると便利な場合があります。たとえば、認証サービスまたは古いバージョンのAPIのテストを除外する場合があります。パスを除外するには、`APISEC_EXCLUDE_PATHS`CI/CD変数を使用します。この変数は、`.gitlab-ci.yml`ファイルで指定します。複数のパスを除外するには、`;`文字を使用してエントリを区切ります。指定されたパスでは、単一文字のワイルドカード`?`と、複数文字のワイルドカードに`*`を使用できます。

パスが除外されていることを確認するには、ジョブ出力の`Tested Operations`と`Excluded Operations`の部分をレビューしてください。`Tested Operations`の下に、除外されたパスがリストされていないことを確認してください。

```plaintext
2021-05-27 21:51:08 [INF] API SECURITY: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API SECURITY: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API SECURITY: ------------------------------------------------
2021-05-27 21:51:08 [INF] API SECURITY: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API SECURITY: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API SECURITY: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API SECURITY: ------------------------------------------------
```

### 例 {#examples}

この例では、`/auth`リソースを除外しています。これは、子リソース（`/auth/child`）を除外するものではありません。

```yaml
variables:
  APISEC_EXCLUDE_PATHS: /auth
```

`/auth`と子リソース（`/auth/child`）を除外するには、ワイルドカードを使用します。

```yaml
variables:
  APISEC_EXCLUDE_PATHS: /auth*
```

複数のパスを除外するには、`;`文字を使用します。この例では、`/auth*`と`/v1/*`を除外します。

```yaml
variables:
  APISEC_EXCLUDE_PATHS: /auth*;/v1/*
```

パス内の1つ以上のネストされたレベルを除外するには、`**`を使用します。この例では、APIエンドポイントをテストしています。`/api/v1/`と`/api/v2/`のデータクエリをテストしており、`mass`、`brightness`、`coordinates`のデータを、`planet`、`moon`、`star`、`satellite`オブジェクトに対してリクエストします。スキャンできるパスの例を次に示しますが、これらに限定されません:

- `/api/v2/planet/coordinates`
- `/api/v1/star/mass`
- `/api/v2/satellite/brightness`

この例では、`brightness`エンドポイントのみをテストします:

```yaml
variables:
  APISEC_EXCLUDE_PATHS: /api/**/mass;/api/**/coordinates
```

### パラメータの除外 {#exclude-parameters}

APIのテスト中に、パラメータ（クエリ文字列、ヘッダー、または本文属性）をテストから除外したい場合があります。これは、パラメータが常に失敗の原因となったり、テスト速度が低下したり、その他の理由で必要になる場合があります。パラメータを除外するには、次の変数のいずれかを設定します: `APISEC_EXCLUDE_PARAMETER_ENV`または`APISEC_EXCLUDE_PARAMETER_FILE`。

`APISEC_EXCLUDE_PARAMETER_ENV`では、除外されたパラメータを含むJSON文字列を指定できます。これは、JSONが短く、あまり変更されない場合に適したオプションです。別のオプションは、変数`APISEC_EXCLUDE_PARAMETER_FILE`です。この変数には、リポジトリにチェックインしたり、別のジョブによってアーティファクトとして作成したり、`APISEC_PRE_SCRIPT`を使用してプリスクリプトでランタイム時に生成したりできるファイルパスが設定されます。

#### JSONドキュメントを使用したパラメータの除外 {#exclude-parameters-using-a-json-document}

JSONドキュメントにはJSONオブジェクトが含まれており、このオブジェクトは、除外するパラメータを特定するために特定のプロパティを使用します。スキャンプロセス中に特定のパラメータを除外するために、次のプロパティを指定できます:

- `headers`: このプロパティを使用して、特定のヘッダーを除外します。プロパティの値は、除外するヘッダー名の配列です。名前は大文字と小文字が区別されません。
- `cookies`: このプロパティの値を使用して、特定のCookieを除外します。プロパティの値は、除外するCookie名の配列です。名前では、大文字と小文字が区別されます。
- `query`: このプロパティを使用して、クエリ文字列から特定のフィールドを除外します。プロパティの値は、除外するクエリ文字列からのフィールド名の配列です。名前では、大文字と小文字が区別されます。
- `body-form`: このプロパティを使用して、メディアタイプ`application/x-www-form-urlencoded`を使用するリクエストから特定のフィールドを除外します。プロパティの値は、除外する本文からのフィールド名の配列です。名前では、大文字と小文字が区別されます。
- `body-json`: このプロパティを使用して、メディアタイプ`application/json`を使用するリクエストから特定のJSONノードを除外します。プロパティの値は配列で、配列の各エントリは[JSONパス](https://goessner.net/articles/JsonPath/)式です。
- `body-xml`: このプロパティを使用して、メディアタイプ`application/xml`を使用するリクエストから特定のXMLノードを除外します。プロパティの値は配列で、配列の各エントリは[XPath v2](https://www.w3.org/TR/xpath20/)式です。

したがって、次のJSONドキュメントは、パラメータを除外するための予期される構造の例です。

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

#### 例 {#examples-1}

##### 単一ヘッダーの除外 {#excluding-a-single-header}

ヘッダー`Upgrade-Insecure-Requests`を除外するには、`header`プロパティの値を、ヘッダー名を持つ配列に設定します: `[ "Upgrade-Insecure-Requests" ]`。たとえば、JSONドキュメントは次のようになります:

```json
{
  "headers": [ "Upgrade-Insecure-Requests" ]
}
```

ヘッダー名では大文字と小文字が区別されないため、ヘッダー名`UPGRADE-INSECURE-REQUESTS`は`Upgrade-Insecure-Requests`と同等です。

##### ヘッダーと2つのCookieの両方を除外 {#excluding-both-a-header-and-two-cookies}

ヘッダー`Authorization`とCookie `PHPSESSID`および`csrftoken`を除外するには、`headers`プロパティの値をヘッダー名`[ "Authorization" ]`を持つ配列に設定し、`cookies`プロパティの値をCookie名`[ "PHPSESSID", "csrftoken" ]`を持つ配列に設定します。たとえば、JSONドキュメントは次のようになります:

```json
{
  "headers": [ "Authorization" ],
  "cookies": [ "PHPSESSID", "csrftoken" ]
}
```

##### `body-form`パラメータの除外 {#excluding-a-body-form-parameter}

`application/x-www-form-urlencoded`を使用するリクエストで`password`フィールドを除外するには、`body-form`プロパティの値を、フィールド名`[ "password" ]`を持つ配列に設定します。たとえば、JSONドキュメントは次のようになります:

```json
{
  "body-form":  [ "password" ]
}
```

リクエストがコンテンツタイプ`application/x-www-form-urlencoded`を使用する場合、除外パラメータは`body-form`を使用します。

##### JSONパスを使用した特定のJSONノードの除外 {#excluding-a-specific-json-nodes-using-json-path}

ルートオブジェクト内の`schema`プロパティを除外するには、`body-json`プロパティの値を、JSONパス式`[ "$.schema" ]`を持つ配列に設定します。

JSONパス式は、JSONノードを識別するために特別な構文を使用します: `$`はJSONドキュメントのルートを参照し、`.`は現在のオブジェクト（この場合はルートオブジェクト）を参照し、テキスト`schema`はプロパティ名を参照します。したがって、JSONパス式`$.schema`は、ルートオブジェクト内のプロパティ`schema`を参照します。たとえば、JSONドキュメントは次のようになります:

```json
{
  "body-json": [ "$.schema" ]
}
```

リクエストがコンテンツタイプ`application/json`を使用する場合、除外パラメータは`body-json`を使用します。`body-json`の各エントリは、[JSONパス式](https://goessner.net/articles/JsonPath/)であると想定されます。JSONパスでは、`$`、`*`、`.`などの文字は、特別な意味を持ちます。

##### JSONパスを使用した複数のJSONノードの除外 {#excluding-multiple-json-nodes-using-json-path}

ルートレベルで`users`の配列の各エントリにあるプロパティ`password`を除外するには、`body-json`プロパティの値を、JSONパス式`[ "$.users[*].password" ]`を持つ配列に設定します。

JSONパス式は、ルートノードを参照するために`$`で始まり、現在のノードを参照するために`.`を使用します。次に、`users`を使用してプロパティを参照し、使用する配列のインデックスを囲むために文字`[`と`]`を使用します。インデックスとして数値を指定する代わりに、`*`を使用して任意のインデックスを指定します。インデックス参照の後には、`.`があり、これは属性名`password`が前に付いた、指定された任意の選択された配列内のインデックスを参照するようになりました。

たとえば、JSONドキュメントは次のようになります:

```json
{
  "body-json": [ "$.users[*].password" ]
}
```

リクエストがコンテンツタイプ`application/json`を使用する場合、除外パラメータは`body-json`を使用します。`body-json`の各エントリは、[JSONパス式](https://goessner.net/articles/JsonPath/)であると想定されます。JSONパスでは、`$`、`*`、`.`などの文字は、特別な意味を持ちます。

##### XML属性の除外 {#excluding-a-xml-attribute}

ルート要素`credentials`にある名前付きの属性`isEnabled`を除外するには、`body-xml`プロパティの値を、XPath式`[ "/credentials/@isEnabled" ]`を持つ配列に設定します。

XPath式`/credentials/@isEnabled`は、XMLドキュメントのルートを示すために`/`で始まり、その後に一致する要素の名前を示す単語`credentials`が続きます。前のXML要素のノードを参照するために`/`を使用し、名前`isEnable`が属性であることを示すために文字`@`を使用します。

たとえば、JSONドキュメントは次のようになります:

```json
{
  "body-xml": [
    "/credentials/@isEnabled"
  ]
}
```

リクエストがコンテンツタイプ`application/xml`を使用する場合、除外パラメータは`body-xml`を使用します。`body-xml`の各エントリは、[XPath v2式](https://www.w3.org/TR/xpath20/)であると想定されます。XPath式では、`@`、`/`、`:`、`[`、`]`などの文字は、特別な意味を持ちます。

##### XMLテキスト要素の除外 {#excluding-a-xml-texts-element}

ルートノード`credentials`に含まれる`username`要素のテキストを除外するには、`body-xml`プロパティの値を、XPath式`[/credentials/username/text()" ]`を持つ配列に設定します。

XPath式`/credentials/username/text()`では、最初の文字`/`はルートXMLノードを参照し、その後にXML要素の名前`credentials`が示されます。同様に、文字`/`は現在の要素を参照し、その後に新しいXML要素の名前`username`が続きます。最後の部分は、現在の要素を参照する`/`を持ち、現在の要素のテキストを識別する`text()`というXPath関数を使用します。

たとえば、JSONドキュメントは次のようになります:

```json
{
  "body-xml": [
    "/credentials/username/text()"
  ]
}
```

リクエストがコンテンツタイプ`application/xml`を使用する場合、除外パラメータは`body-xml`を使用します。`body-xml`の各エントリは、[XPath v2式](https://www.w3.org/TR/xpath20/)であると想定されます。XPath式では、`@`、`/`、`:`、`[`、`]`などの文字は、特別な意味を持ちます。

##### XML要素の除外 {#excluding-an-xml-element}

ルートノード`credentials`に含まれる要素`username`を除外するには、`body-xml`プロパティの値を、XPath式`[/credentials/username" ]`を持つ配列に設定します。

XPath式`/credentials/username`では、最初の文字`/`はルートXMLノードを参照し、その後にXML要素の名前`credentials`が示されます。同様に、文字`/`は現在の要素を参照し、その後に新しいXML要素の名前`username`が続きます。

たとえば、JSONドキュメントは次のようになります:

```json
{
  "body-xml": [
    "/credentials/username"
  ]
}
```

リクエストがコンテンツタイプ`application/xml`を使用する場合、除外パラメータは`body-xml`を使用します。`body-xml`の各エントリは、[XPath v2式](https://www.w3.org/TR/xpath20/)であると想定されます。XPath式では、`@`、`/`、`:`、`[`、`]`などの文字は、特別な意味を持ちます。

##### ネームスペースを持つXMLノードの除外 {#excluding-an-xml-node-with-namespaces}

ネームスペース`s`で定義され、`credentials`ルートノードに含まれるanXML要素`login`を除外するには、`body-xml`プロパティの値を、XPath式`[ "/credentials/s:login" ]`を持つ配列に設定します。

XPath式`/credentials/s:login`では、最初の文字`/`はルートXMLノードを参照し、その後にXML要素の名前`credentials`が示されます。同様に、文字`/`は現在の要素を参照し、その後に新しいXML要素の名前`s:login`が続きます。その名前に文字`:`が含まれていることに注意してください。この文字はネームスペースとノード名を区切ります。

ネームスペース名は、本文リクエストの一部であるXMLドキュメントで定義されている必要があります。仕様ドキュメントHAR、OpenAPI、またはPostmanコレクションファイルでネームスペースを確認できます。

```json
{
  "body-xml": [
    "/credentials/s:login"
  ]
}
```

リクエストがコンテンツタイプ`application/xml`を使用する場合、除外パラメータは`body-xml`を使用します。`body-xml`の各エントリは、[XPath v2式](https://www.w3.org/TR/xpath20/)であると想定されます。XPathでは、式文字（`@`、`/`、`:`、`[`、`]`など）は、特別な意味を持ちます。

#### JSON文字列の使用 {#using-a-json-string}

除外JSONドキュメントを提供するには、変数`APISEC_EXCLUDE_PARAMETER_ENV`にJSON文字列を設定します。次の例では、`.gitlab-ci.yml`で、`APISEC_EXCLUDE_PARAMETER_ENV`変数がJSON文字列に設定されています:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_EXCLUDE_PARAMETER_ENV: '{ "headers": [ "Upgrade-Insecure-Requests" ] }'
```

#### ファイルの使用 {#using-a-file-1}

除外JSONドキュメントを提供するには、変数`APISEC_EXCLUDE_PARAMETER_FILE`にJSONファイルのパスを設定します。ファイルのパスは、ジョブの現在の作業ディレクトリに対する相対パスです。次の例`.gitlab-ci.yml`のコンテンツでは、`APISEC_EXCLUDE_PARAMETER_FILE`変数はJSONファイルのパスに設定されています:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_OPENAPI: test-api-specification.json
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_EXCLUDE_PARAMETER_FILE: dast-api-exclude-parameters.json
```

`dast-api-exclude-parameters.json`は、[パラメータを除外するドキュメント](#exclude-parameters-using-a-json-document)の構造に従うJSONドキュメントです。

### URLの除外 {#exclude-urls}

パスで除外する代わりに、`APISEC_EXCLUDE_URLS`CI/CD変数を使用して、URLの他のコンポーネントでフィルタリングできます。この変数は、`.gitlab-ci.yml`ファイルで設定できます。この変数には、カンマ（`,`）で区切られた複数の値を格納できます。各値は、正規表現です。各エントリが正規表現であるため、`.*`のようなエントリは、すべてに一致する正規表現であるため、すべてのURLを除外します。

ジョブの出力で、`APISEC_EXCLUDE_URLS`から提供された正規表現に一致するURLがあるかどうかを確認できます。一致するオペレーションは、**Excluded Operations**（除外されたオペレーション）セクションにリストされています。**Excluded Operations**（除外されたオペレーション）にリストされているオペレーションは、**Tested Operations**（テスト済みオペレーション）セクションにリストされていてはなりません。次に、ジョブ出力の次の部分の例を示します:

```plaintext
2021-05-27 21:51:08 [INF] API SECURITY: --[ Tested Operations ]-------------------------
2021-05-27 21:51:08 [INF] API SECURITY: 201 POST http://target:7777/api/users CREATED
2021-05-27 21:51:08 [INF] API SECURITY: ------------------------------------------------
2021-05-27 21:51:08 [INF] API SECURITY: --[ Excluded Operations ]-----------------------
2021-05-27 21:51:08 [INF] API SECURITY: GET http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API SECURITY: POST http://target:7777/api/messages
2021-05-27 21:51:08 [INF] API SECURITY: ------------------------------------------------
```

{{< alert type="note" >}}

`APISEC_EXCLUDE_URLS`の各値は、正規表現です。`.`、`*`、`$`などの文字は、[正規表現](https://en.wikipedia.org/wiki/Regular_expression#Standards)で特別な意味を持ちます。

{{< /alert >}}

#### 例 {#examples-2}

##### URLと子リソースの除外 {#excluding-a-url-and-child-resources}

次の例では、URL `http://target/api/auth`とその子リソースを除外します。

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://target/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_EXCLUDE_URLS: http://target/api/auth
```

##### 2つのURLを除外し、その子リソースを許可する {#excluding-two-urls-and-allow-their-child-resources}

URL `http://target/api/buy`と`http://target/api/sell`を除外しますが、たとえば`http://target/api/buy/toy`や`http://target/api/sell/chair`などの子リソースのスキャンを許可します。`http://target/api/buy/$,http://target/api/sell/$`の値を使用できます。この値は、それぞれが`,`文字で区切られた2つの正規表現を使用しています。したがって、`http://target/api/buy$`と`http://target/api/sell$`が含まれます。各正規表現では、末尾の`$`文字は、一致するURLがどこで終わるかを示します。

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://target/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_EXCLUDE_URLS: http://target/api/buy/$,http://target/api/sell/$
```

##### 2つのURLとその子リソースの除外 {#excluding-two-urls-and-their-child-resources}

URL `http://target/api/buy`と`http://target/api/sell`、およびそれらの子リソースを除外するには、次のようにします。複数のURLを指定するには、次のように`,`文字を使用します:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://target/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_EXCLUDE_URLS: http://target/api/buy,http://target/api/sell
```

##### 正規表現を使用したURLの除外 {#excluding-url-using-regular-expressions}

`https://target/api/v1/user/create`と`https://target/api/v2/user/create`、またはその他のバージョン（`v3`、`v4`など）を正確に除外するには、次のようにします。前の正規表現では、`https://target/api/v.*/user/create$`を使用できます。`.`は任意の文字を示し、`*`はゼロ回以上の回数を示し、さらに`$`はURLがそこで終わる必要があることを示します。

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://target/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_EXCLUDE_URLS: https://target/api/v.*/user/create$
```
