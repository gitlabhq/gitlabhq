---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: APIファジングジョブのトラブルシューティング
---

## APIファジングジョブがN時間後にタイムアウトする {#api-fuzzing-job-times-out-after-n-hours}

大規模なリポジトリの場合、APIファジングジョブは[small hosted runner on Linux](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64)でタイムアウトする可能性があります。デフォルトで設定されています。この問題がジョブで発生した場合は、[larger runner](performance.md#using-a-larger-runner)にスケールする必要があります。

以下のドキュメントセクションを参照してください:

- [Performance tuning and testing speed](performance.md)
- [Using a larger Runner](performance.md#using-a-larger-runner)
- [Excluding operations byパス](configuration/customizing_analyzer_settings.md#exclude-paths)
- [Excluding slow operations](performance.md#excluding-slow-operations)

## APIファジングジョブの完了に時間がかかりすぎる {#api-fuzzing-job-takes-too-long-to-complete}

[performance tuning and testing speed](performance.md)を参照してください。

## エラー: `Error waiting for API fuzzing 'http://127.0.0.1:5000' to become available` {#error-error-waiting-for-api-fuzzing-http1270015000-to-become-available}

v1.6.196以前のAPIファジングアナライザーのバージョンにはバグがあり、特定の条件下でバックグラウンドプロセスが失敗する可能性があります。解決策は、より新しいバージョンのAPIファジングアナライザーに更新することです。

バージョン情報は、`apifuzzer_fuzz`ジョブのジョブ詳細で見つけることができます。

バージョンv1.6.196以降で問題が発生している場合は、サポートに連絡し、以下の情報を提供してください:

1. このトラブルシューティングセクションを参照し、イシューを動的な解析チームにエスカレートするよう依頼してください。
1. ジョブの完全なコンソール出力。
1. ジョブアーティファクトとして利用可能な`gl-api-security-scanner.log`ファイル。ジョブ詳細ページの右側のパネルで、**閲覧**ボタンを選択します。
1. `apifuzzer_fuzz`ジョブの定義を`.gitlab-ci.yml`ファイルから。

**エラーメッセージ**

- [GitLab 15.6以降](https://gitlab.com/gitlab-org/gitlab/-/issues/376078)では、`Error waiting for API Fuzzing 'http://127.0.0.1:5000' to become available`
- GitLab 15.5以前では、`Error waiting for API Security 'http://127.0.0.1:5000' to become available`。

### `Failed to start session with scanner. Please retry, and if the problem persists reach out to support.` {#failed-to-start-session-with-scanner-please-retry-and-if-the-problem-persists-reach-out-to-support}

APIファジングエンジンは、スキャナーアプリケーションコンポーネントとの接続を確立できない場合にエラーメッセージを出力します。エラーメッセージは、`apifuzzer_fuzz`ジョブのジョブ出力ウィンドウに表示されます。このイシューの一般的な原因は、バックグラウンドコンポーネントが、すでに使用中の選択されたポートを使用できないことです。このエラーは、タイミングが関係する場合（競合状態）、断続的に発生する可能性があります。このイシューは、他のサービスがコンテナにマップされ、ポート競合を引き起こすKubernetes環境で最も頻繁に発生します。

解決策に進む前に、エラーメッセージがポートがすでに使用されていたために生成されたことを確認することが重要です。これが原因であったことを確認するには:

1. ジョブコンソールに移動します。

1. アーティファクト`gl-api-security-scanner.log`を探します。**ダウンロード**を選択してすべてのアーティファクトをダウンロードし、ファイルを検索するか、**閲覧**を選択して直接検索を開始できます。

1. テキストエディタで`gl-api-security-scanner.log`ファイルを開きます。

1. ポートがすでに使用されていたためにエラーメッセージが生成された場合、ファイルに次のようなメッセージが表示されます:

- [GitLab 15.5以降](https://gitlab.com/gitlab-org/gitlab/-/issues/367734)の場合:

  ```log
  Failed to bind to address http://127.0.0.1:5500: address already in use.
  ```

- GitLab 15.4以前の場合:

  ```log
  Failed to bind to address http://[::]:5000: address already in use.
  ```

前のメッセージのテキスト`http://[::]:5000`は、あなたのケースでは異なる可能性があり、たとえば`http://[::]:5500`または`http://127.0.0.1:5500`である可能性があります。エラーメッセージの残りの部分が同じである限り、ポートがすでに使用されていたと安全に推測できます。

ポートがすでに使用されていたという証拠が見つからない場合は、ジョブコンソールの出力に表示される同じエラーメッセージに対処する他のトラブルシューティングセクションを確認してください。他に選択肢がない場合は、適切なチャンネルを通じて[get support or request an improvement](_index.md#get-support-or-request-an-improvement)してください。

ポートがすでに使用されていたためにイシューが発生したことを確認したら。次に、[GitLab 15.5以降](https://gitlab.com/gitlab-org/gitlab/-/issues/367734)で設定変数`FUZZAPI_API_PORT`が導入されました。この設定変数を使用すると、スキャナーバックグラウンドコンポーネントの固定ポート番号を設定できます。

**解決策**

1. `.gitlab-ci.yml`ファイルが設定変数`FUZZAPI_API_PORT`を定義していることを確認してください。
1. `FUZZAPI_API_PORT`の値を1024より大きい利用可能なポート番号に更新します。新しい値がGitLabによって使用されていないことを確認してください。GitLabで使用するポートの完全なリストについては、[パッケージのデフォルト](../../../administration/package_information/defaults.md#ports)を参照してください。

## エラー: `Errors were found during validation of the document using the published OpenAPI schema` {#error-errors-were-found-during-validation-of-the-document-using-the-published-openapi-schema}

APIファジングジョブの開始時に、OpenAPI Specificationは[publishedスキーマ](https://github.com/OAI/OpenAPI-Specification/tree/master/schemas)に対して検証されます。このエラーは、提供されたOpenAPI Specificationに検証エラーがある場合に表示されます:

```plaintext
Error, the OpenAPI document is not valid.
Errors were found during validation of the document using the published OpenAPI schema
```

OpenAPI Specificationを手動で作成する際、およびスキーマが生成される際にもエラーが発生する可能性があります。

自動的に生成されるOpenAPI Specificationsの場合、検証エラーは、コード注釈の不足が原因であることがよくあります。

**エラーメッセージ**

- `Error, the OpenAPI document is not valid. Errors were found during validation of the document using the published OpenAPI schema`
  - `OpenAPI 2.0 schema validation error ...`
  - `OpenAPI 3.0.x schema validation error ...`

**解決策**

**For generated OpenAPI Specifications**

1. 検証エラーを特定します。
   1. [Swagger Editor](https://editor.swagger.io/)を使用して、仕様内の検証の問題を特定します。Swaggerエディタの視覚的な特性により、何を変更する必要があるかを理解しやすくなります。
   1. あるいは、ログファイル出力をチェックし、スキーマ検証の警告を探すこともできます。これらは、`OpenAPI 2.0 schema validation error`や`OpenAPI 3.0.x schema validation error`のようなメッセージでプレフィックスされています。検証に失敗するたびに、`location`と`description`に関する追加情報が提供されます。JSONスキーマ検証メッセージは複雑になる可能性があり、エディタはスキーマドキュメントの検証に役立ちます。
1. 使用しているフレームワーク/技術スタックのOpenAPI生成に関するドキュメントを確認してください。正しいOpenAPIドキュメントを生成するために必要な変更を特定します。
1. 検証のイシューが解決されたら、パイプラインを再実行します。

**For manually created OpenAPI Specifications**

1. 検証エラーを特定します。
   1. 最も簡単な解決策は、視覚ツールを使用してOpenAPIドキュメントを編集および検証することです。例えば、[Swagger Editor](https://editor.swagger.io/)はスキーマエラーと可能な解決策をハイライトします。
   1. あるいは、ログファイル出力をチェックし、スキーマ検証の警告を探すこともできます。これらは、`OpenAPI 2.0 schema validation error`や`OpenAPI 3.0.x schema validation error`のようなメッセージでプレフィックスされています。検証に失敗するたびに、`location`と`description`に関する追加情報が提供されます。検証の失敗をそれぞれ修正し、OpenAPIドキュメントを再提出してください。JSONスキーマ検証メッセージは複雑になる可能性があり、エディタはスキーマドキュメントの検証に役立ちます。
1. 検証のイシューが解決されたら、パイプラインを再実行します。

## `Failed to start scanner session (version header not found)` {#failed-to-start-scanner-session-version-header-not-found}

APIファジングエンジンは、スキャナーアプリケーションコンポーネントとの接続を確立できない場合にエラーメッセージを出力します。エラーメッセージは、`apifuzzer_fuzz`ジョブのジョブ出力ウィンドウに表示されます。このイシューの一般的な原因は、変数`FUZZAPI_API`をデフォルトから変更することです。

**エラーメッセージ**

- `Failed to start scanner session (version header not found).`

**解決策**

- `.gitlab-ci.yml`ファイルから変数`FUZZAPI_API`を削除します。この値はAPIファジングCI/CDテンプレートから継承されます。手動で値を設定する代わりに、この方法を使用してください。
- 変数の削除が不可能な場合は、[APIファジングCI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Fuzzing.gitlab-ci.yml)の最新バージョンでこの値が変更されているかどうかを確認してください。もしそうであれば、`.gitlab-ci.yml`ファイルの値を更新してください。

## `Application cannot determine the base URL for the target API` {#application-cannot-determine-the-base-url-for-the-target-api}

APIファジングアナライザーは、OpenAPIドキュメントを検査した後、ターゲットAPIを特定できない場合にエラーメッセージを出力します。このエラーメッセージは、ターゲットAPIが`.gitlab-ci.yml`ファイルで設定されておらず、`environment_url.txt`ファイルでも利用できず、OpenAPIドキュメントを使用して計算できなかった場合に表示されます。

APIファジングアナライザーが異なるソースをチェックする際にターゲットAPIを取得しようとする優先順位があります。まず、`FUZZAPI_TARGET_URL`を使用しようとします。環境変数が設定されていない場合、APIファジングアナライザーは`environment_url.txt`ファイルを使用しようとします。`environment_url.txt`ファイルがない場合、APIファジングアナライザーは、OpenAPIドキュメントのコンテンツと`FUZZAPI_OPENAPI`で提供されるURL（URLが提供されている場合）を使用してターゲットAPIを計算しようとします。

最適な解決策は、ターゲットAPIが各デプロイごとに変更されるかどうかによって異なります:

- ターゲットAPIが各デプロイで同じである場合（静的環境）、[static environment解決策](#static-environment-solution)を使用します。
- ターゲットAPIが各デプロイで変更される場合は、[dynamic environment解決策](#dynamic-environment-solutions)を使用します。

### 静的環境解決策 {#static-environment-solution}

この解決策は、ターゲットAPI URLが変更されない（静的である）パイプラインを対象としています。

**Add environmental variable**

ターゲットAPIが同じままである環境では、`FUZZAPI_TARGET_URL`環境変数を使用してターゲットURLを指定する必要があります。`.gitlab-ci.yml`ファイルに、変数`FUZZAPI_TARGET_URL`を追加します。変数は、APIテストターゲットのベースURLに設定する必要があります。例: 

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OPENAPI: test-api-specification.json
```

### 動的環境解決策 {#dynamic-environment-solutions}

動的環境では、ターゲットAPIはデプロイごとに変更されます。この場合、複数の可能な解決策があります: 動的環境を扱う際には`environment_url.txt`ファイルの使用を検討してください。

**Use environment_url.txt**

ターゲットAPI URLが各パイプライン中に変更される動的環境をサポートするために、APIファジングは使用するURLを含む`environment_url.txt`ファイルの使用をサポートしています。このファイルはリポジトリにチェックインされず、代わりにテストターゲットをデプロイするジョブによってパイプライン中に作成され、その後のパイプラインのジョブで使用できるアーティファクトとして収集されます。`environment_url.txt`ファイルを作成するジョブは、APIファジングジョブの前に実行される必要があります。

1. プロジェクトのルートにある`environment_url.txt`ファイルにベースURLを追加して、テストターゲットデプロイメントジョブを変更します。
1. `environment_url.txt`をアーティファクトとして収集するようにテストターゲットデプロイメントジョブを変更します。

例: 

```yaml
deploy-test-target:
  script:
    # Perform deployment steps
    # Create environment_url.txt (example)
    - echo http://${CI_PROJECT_ID}-${CI_ENVIRONMENT_SLUG}.example.org > environment_url.txt

  artifacts:
    paths:
      - environment_url.txt
```

## 不正な形式のスキーマを持つOpenAPIの使用 {#use-openapi-with-an-invalid-schema}

ドキュメントが不正な形式のスキーマで自動生成されるか、タイムリーに手動で編集できない場合があります。そのようなシナリオでは、APIファジングは変数`FUZZAPI_OPENAPI_RELAXED_VALIDATION`を設定することで、緩やかな検証を実行できます。予期しない動作を防ぐために、完全に準拠したOpenAPIドキュメントを提供してください。

### 非準拠のOpenAPIファイルを編集する {#edit-a-non-compliant-openapi-file}

OpenAPI仕様に準拠していない要素を検出して修正するには、エディタを使用します。エディタは通常、ドキュメントの検証と、スキーマ準拠のOpenAPIドキュメントを作成するための提案を提供します。推奨されるエディタは以下のとおりです:

| エディタ                                             | OpenAPI 2.0                   | OpenAPI 3.0.x                 | OpenAPI 3.1.x |
|----------------------------------------------------|-------------------------------|-------------------------------|---------------|
| [Swagger Editor](https://editor.swagger.io/)       | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="dotted-circle" >}} YAML, JSON |
| [Stoplight Studio](https://stoplight.io/solutions) | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="check-circle" >}} YAML, JSON | {{< icon name="check-circle" >}} YAML, JSON |

OpenAPIドキュメントが手動で生成された場合は、エディタにドキュメントを読み込み、準拠していないものをすべて修正してください。ドキュメントが自動的に生成された場合は、エディタに読み込み、スキーマ内のイシューを特定した後、アプリケーションに移動し、使用しているフレームワークに基づいて修正を実行してください。

### OpenAPIの緩和された検証を有効にする {#enable-openapi-relaxed-validation}

緩和された検証は、OpenAPIドキュメントがOpenAPI仕様を満たせない場合でも、異なるツールで消費できる十分なコンテンツを持っているケースを対象としています。検証は実行されますが、ドキュメントスキーマに関しては厳密ではありません。

APIファジングは、OpenAPI仕様に完全に準拠していないOpenAPIドキュメントを消費しようとすることができます。APIファジングアナライザーに緩和された検証を実行させるには、変数`FUZZAPI_OPENAPI_RELAXED_VALIDATION`を任意の値に設定します。例えば:

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_PROFILE: Quick-10
  FUZZAPI_TARGET_URL: http://test-deployment/
  FUZZAPI_OPENAPI: test-api-specification.json
  FUZZAPI_OPENAPI_RELAXED_VALIDATION: 'On'
```

## `No operation in the OpenAPI document is consuming any supported media type` {#no-operation-in-the-openapi-document-is-consuming-any-supported-media-type}

APIファジングは、OpenAPIドキュメントで指定されたメディアタイプを使用してリクエストを生成します。サポートされているメディアタイプがないためにリクエストを作成できない場合、エラーがスローされます。

**エラーメッセージ**

- `Error, no operation in the OpenApi document is consuming any supported media type. Check 'OpenAPI Specification' to check the supported media types.`

**解決策**

1. [OpenAPI仕様](configuration/enabling_the_analyzer.md#openapi-specification)セクションでサポートされているメディアタイプを確認してください。
1. OpenAPIドキュメントを編集し、少なくとも指定された操作がサポートされているメディアタイプのいずれかを受け入れるようにします。あるいは、サポートされているメディアタイプをOpenAPIドキュメントレベルで設定し、すべての操作に適用することもできます。このステップでは、サポートされているメディアタイプがアプリケーションによって受け入れられるように、アプリケーションに変更を加える必要がある場合があります。

## エラー: `The SSL connection could not be established, see inner exception.` {#error-the-ssl-connection-could-not-be-established-see-inner-exception}

APIファジングは、古いプロトコルや暗号を含む幅広いTLS設定と互換性があります。幅広いサポートにもかかわらず、次のような接続エラーが発生する可能性があります:

```plaintext
Error, error occurred trying to download `<URL>`:
There was an error when retrieving content from Uri:' <URL>'.
Error:The SSL connection could not be established, see inner exception.
```

このエラーは、APIファジングが指定されたURLのサーバーとのセキュアな接続を確立できなかったために発生します。

この問題を解決するには、以下の手順に従います:

エラーメッセージのホストが非TLS接続をサポートしている場合は、設定で`https://`を`http://`に変更します。例えば、以下の設定でエラーが発生した場合:

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: https://test-deployment/
  FUZZAPI_OPENAPI: https://specs/openapi.json
```

`FUZZAPI_OPENAPI`のプレフィックスを`https://`から`http://`に変更します:

```yaml
stages:
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

variables:
  FUZZAPI_TARGET_URL: https://test-deployment/
  FUZZAPI_OPENAPI: http://specs/openapi.json
```

非TLS接続を使用してURLにアクセスできない場合は、サポートチームに連絡して支援を求めてください。

[testssl.shツール](https://testssl.sh/)を使用して調査を迅速化できます。bash Shellが搭載され、影響を受けるサーバーに接続できるマシンから:

1. 最新のリリース`zip`または`tar.gz`ファイルを<https://github.com/drwetter/testssl.sh/releases>からダウンロードして展開します。
1. `./testssl.sh --log https://specs`を実行します。
1. ログファイルをサポートチケットに添付してください。

## `ERROR: Job failed: failed to pull image` {#error-job-failed-failed-to-pull-image}

このエラーメッセージは、アクセスに認証が必要な（公開されていない）コンテナレジストリからイメージをプルする際に発生します。

ジョブコンソールの出力では、エラーは次のようになります:

```plaintext
Running with gitlab-runner 15.6.0~beta.186.ga889181a (a889181a)
  on blue-2.shared.runners-manager.gitlab.com/default XxUrkriX
Resolving secrets
00:00
Preparing the "docker+machine" executor
00:06
Using Docker executor with image registry.gitlab.com/security-products/api-security:2 ...
Starting service registry.example.com/my-target-app:latest ...
Pulling docker image registry.example.com/my-target-app:latest ...
WARNING: Failed to pull image with policy "always": Error response from daemon: Get https://registry.example.com/my-target-app/manifests/latest: unauthorized (manager.go:237:0s)
ERROR: Job failed: failed to pull image "registry.example.com/my-target-app:latest" with specified policies [always]: Error response from daemon: Get https://registry.example.com/my-target-app/manifests/latest: unauthorized (manager.go:237:0s)
```

**エラーメッセージ**

- GitLab 15.9以前では、`ERROR: Job failed: failed to pull image`の後に`Error response from daemon: Get IMAGE: unauthorized`が続きます。

**解決策**

認証認証情報は、[Access an image from a privateコンテナレジストリ](../../../ci/docker/using_docker_images.md#access-an-image-from-a-private-container-registry)ドキュメントセクションに概説されている方法を使用して提供されます。使用される方法は、コンテナレジストリプロバイダーとその設定によって決定されます。クラウドプロバイダー（Azure、Google Cloud (GCP)、AWSなど）のようなサードパーティが提供するコンテナレジストリを使用している場合は、コンテナレジストリに認証する方法に関するドキュメントをプロバイダーのドキュメントで確認してください。

次の例では、[statically defined認証情報](../../../ci/docker/using_docker_images.md#use-statically-defined-credentials)認証方法を使用しています。この例では、コンテナレジストリは`registry.example.com`で、イメージは`my-target-app:latest`です。

1. `DOCKER_AUTH_CONFIG`の変数値を計算する方法を理解するために、[Determine your `DOCKER_AUTH_CONFIG` data](../../../ci/docker/using_docker_images.md#determine-your-docker_auth_config-data)を読んでください。設定変数`DOCKER_AUTH_CONFIG`には、適切な認証情報を提供するためのDocker JSON設定が含まれています。例えば、認証情報`abcdefghijklmn`を使用してプライベートコンテナレジストリ`registry.example.com`にアクセスする場合、Docker JSONは次のようになります:

   ```json
   {
       "auths": {
           "registry.example.com": {
               "auth": "abcdefghijklmn"
           }
       }
   }
   ```

1. `DOCKER_AUTH_CONFIG`をCI/CD変数として追加します。設定変数を`.gitlab-ci.yml`ファイルに直接追加する代わりに、プロジェクト[CI/CD変数](../../../ci/variables/_index.md#for-a-project)を作成する必要があります。
1. ジョブを再実行すると、静的に定義された認証情報がプライベートコンテナレジストリ`registry.example.com`にサインインするために使用され、イメージ`my-target-app:latest`をプルできるようになります。成功すると、ジョブコンソールに次のような出力が表示されます:

   ```log
   Running with gitlab-runner 15.6.0~beta.186.ga889181a (a889181a)
     on blue-4.shared.runners-manager.gitlab.com/default J2nyww-s
   Resolving secrets
   00:00
   Preparing the "docker+machine" executor
   00:56
   Using Docker executor with image registry.gitlab.com/security-products/api-security:2 ...
   Starting service registry.example.com/my-target-app:latest ...
   Authenticating with credentials from $DOCKER_AUTH_CONFIG
   Pulling docker image registry.example.com/my-target-app:latest ...
   Using docker image sha256:139c39668e5e4417f7d0eb0eeb74145ba862f4f3c24f7c6594ecb2f82dc4ad06 for registry.example.com/my-target-app:latest with digest registry.example.com/my-target-
   app@sha256:2b69fc7c3627dbd0ebaa17674c264fcd2f2ba21ed9552a472acf8b065d39039c ...
   Waiting for services to be up and running (timeout 30 seconds)...
   ```

## エラー: `sudo: The "no new privileges" flag is set, which prevents sudo from running as root.` {#error-sudo-the-no-new-privileges-flag-is-set-which-prevents-sudo-from-running-as-root}

アナライザーのv5以降、デフォルトではroot以外のユーザーが使用されます。これは、特権操作を実行する際に`sudo`の使用を必要とします。

このエラーは、実行中のコンテナが新しい権限を取得できないようにする特定のコンテナデーモン設定で発生します。ほとんどの設定では、これはデフォルトの設定ではなく、セキュリティ強化ガイドの一部として具体的に設定されたものです。

**エラーメッセージ**

このイシューは、`before_script`または`FUZZAPI_PRE_SCRIPT`が実行されたときに生成されるエラーメッセージによって特定できます:

```shell
$ sudo apk add nodejs

sudo: The "no new privileges" flag is set, which prevents sudo from running as root.

sudo: If sudo is running in a container, you may need to adjust the container configuration to disable the flag.
```

**解決策**

このイシューは、次の方法で回避策できます:

- コンテナを`root`ユーザーとして実行します。この設定は、すべての場合で機能しない可能性があるため、テストすることをお勧めします。これは、CICD設定を変更し、ジョブの出力をチェックして、`whoami`が`root`を返し、`gitlab`を返さないことを確認することによって行うことができます。`gitlab`が表示される場合は、別の回避策を使用してください。テスト後、`before_script`は削除できます。

  ```yaml
  apifuzzer_fuzz:
    image:
      name: $SECURE_ANALYZERS_PREFIX/$FUZZAPI_IMAGE:$FUZZAPI_VERSION$FUZZAPI_IMAGE_SUFFIX
      docker:
        user: root
   before_script:
     - whoami
  ```

  _ジョブコンソール出力例:_

  ```log
  Executing "step_script" stage of the job script
  Using docker image sha256:8b95f188b37d6b342dc740f68557771bb214fe520a5dc78a88c7a9cc6a0f9901 for registry.gitlab.com/security-products/api-security:5 with digest registry.gitlab.com/security-products/api-security@sha256:092909baa2b41db8a7e3584f91b982174772abdfe8ceafc97cf567c3de3179d1 ...
  $ whoami
  root
  $ /peach/analyzer-api-fuzzing
  17:17:14 [INF] API Security: Gitlab API Security
  17:17:14 [INF] API Security: -------------------
  17:17:14 [INF] API Security:
  17:17:14 [INF] API Security: version: 5.7.0
  ```

- コンテナをラップし、ビルド時に依存関係を追加します。このオプションには、rootよりも低い権限で実行できるという利点があり、一部の顧客にとっては要件となる場合があります。

  1. 既存のイメージをラップする新しい`Dockerfile`を作成します。

     ```yaml
     ARG SECURE_ANALYZERS_PREFIX
     ARG FUZZAPI_IMAGE
     ARG FUZZAPI_VERSION
     ARG FUZZAPI_IMAGE_SUFFIX
     FROM $SECURE_ANALYZERS_PREFIX/$FUZZAPI_IMAGE:$FUZZAPI_VERSION$FUZZAPI_IMAGE_SUFFIX
     USER root

     RUN pip install ...
     RUN apk add ...

     USER gitlab
     ```

  1. 新しいイメージをビルドし、APIファジングジョブが開始する前にローカルコンテナレジストリにプッシュします。イメージはジョブが完了した後で削除する必要があります。

     ```shell
     TARGET_NAME=apifuzz-$CI_COMMIT_SHA
     docker build -t $TARGET_IMAGE \
       --build-arg "SECURE_ANALYZERS_PREFIX=$SECURE_ANALYZERS_PREFIX" \
       --build-arg "FUZZAPI_IMAGE=$APISEC_IMAGE" \
       --build-arg "FUZZAPI_VERSION=$APISEC_VERSION" \
       --build-arg "FUZZAPI_IMAGE_SUFFIX=$APISEC_IMAGE_SUFFIX" \
       .
     docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
     docker push $TARGET_IMAGE
     ```

  1. `apifuzzer_fuzz`ジョブを拡張し、新しいイメージ名を使用します。

     ```yaml
     apifuzzer_fuzz:
       image: apifuzz-$CI_COMMIT_SHA
     ```

  1. 一時的なコンテナをレジストリから削除します。コンテナイメージの削除に関する情報については、[this documentation page](../../packages/container_registry/delete_container_registry_images.md)を参照してください。

- GitLab Runnerの設定を変更し、no-new-privilegesフラグを無効にします。これはセキュリティ上の影響を及ぼす可能性があるため、運用チームおよびセキュリティチームと話し合う必要があります。

## `Index was outside the bounds of the array at Peach.Web.Runner.Services.RunnerOptions.GetHeaders()` {#index-was-outside-the-bounds-of-the-array-at-peachwebrunnerservicesrunneroptionsgetheaders}

このエラーメッセージは、APIファジングアナライザーが`FUZZAPI_REQUEST_HEADERS`または`FUZZAPI_REQUEST_HEADERS_BASE64`設定変数の値を解析できないことを示しています。

**エラーメッセージ**

このイシューは2つのエラーメッセージによって特定できます。最初のエラーメッセージはジョブコンソールの出力に表示され、2番目のエラーメッセージは`gl-api-security-scanner.log`ファイルに表示されます。

_ジョブコンソールからのエラーメッセージ:_

```plaintext
05:48:38 [ERR] API Security: Testing failed: An unexpected exception occurred: Index was outside the bounds of the array.
```

_`gl_api_security-scanner.log`からのエラーメッセージ:_

```plaintext
08:45:43.616 [ERR] <Peach.Web.Core.Services.WebRunnerMachine> Unexpected exception in WebRunnerMachine::Run()
System.IndexOutOfRangeException: Index was outside the bounds of the array.
   at Peach.Web.Runner.Services.RunnerOptions.GetHeaders() in /builds/gitlab-org/security-products/analyzers/api-fuzzing-src/web/PeachWeb/Runner/Services/[RunnerOptions.cs:line 362
   at Peach.Web.Runner.Services.RunnerService.Start(Job job, IRunnerOptions options) in /builds/gitlab-org/security-products/analyzers/api-fuzzing-src/web/PeachWeb/Runner/Services/RunnerService.cs:line 67
   at Peach.Web.Core.Services.WebRunnerMachine.Run(IRunnerOptions runnerOptions, CancellationToken token) in /builds/gitlab-org/security-products/analyzers/api-fuzzing-src/web/PeachWeb/Core/Services/WebRunnerMachine.cs:line 321
08:45:43.634 [WRN] <Peach.Web.Core.Services.WebRunnerMachine> * Session failed: An unexpected exception occurred: Index was outside the bounds of the array.
08:45:43.677 [INF] <Peach.Web.Core.Services.WebRunnerMachine> Finished testing. Performed a total of 0 requests.
```

**解決策**

このイシューは、不正な形式の`FUZZAPI_REQUEST_HEADERS`または`FUZZAPI_REQUEST_HEADERS_BASE64`変数が原因で発生します。予期される形式は、`Header: value`構造の1つまたは複数のヘッダーをコンマで区切ったものです。解決策は、予期されるものと一致するように構文を修正することです。

_有効な例:_

- `Authorization: Bearer XYZ`
- `X-Custom: Value,Authorization: Bearer XYZ`

_無効な例:_

- `Header:,value`
- `HeaderA: value,HeaderB:,HeaderC: value`
- `Header`
