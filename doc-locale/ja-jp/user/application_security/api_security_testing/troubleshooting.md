---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: APIセキュリティテストジョブのトラブルシューティング
---

## APIセキュリティテストジョブがN時間後にタイムアウトする {#api-security-testing-job-times-out-after-n-hours}

大規模なリポジトリの場合、APIセキュリティテストジョブは[Linux上の小型ホスト型Runner](../../../ci/runners/hosted_runners/linux.md#machine-types-available-for-linux---x86-64)でタイムアウトする可能性があります。これはデフォルトで設定されています。これがジョブで発生する場合は、[より大きなRunner](performance.md#using-a-larger-runner)にスケールする必要があります。

支援については、次のドキュメントのセクションを参照してください:

- [パフォーマンス調整とテスト速度](performance.md)
- [より大きなRunnerの使用](performance.md#using-a-larger-runner)
- [パスによる操作の除外](configuration/customizing_analyzer_settings.md#exclude-paths)
- [低速操作の除外](performance.md#excluding-slow-operations)

## APIセキュリティテストジョブの完了に時間がかかりすぎる {#api-security-testing-job-takes-too-long-to-complete}

[パフォーマンス調整とテスト速度](performance.md)を参照してください

## エラー: `Error waiting for DAST API 'http://127.0.0.1:5000' to become available` {#error-error-waiting-for-dast-api-http1270015000-to-become-available}

APIセキュリティテストアナライザーのv1.6.196以前のバージョンにはバグが存在し、特定の条件下でバックグラウンドプロセスが失敗する可能性があります。解決策は、より新しいバージョンのAPIセキュリティテストアナライザーにアップデートすることです。

バージョン情報は、`dast_api`ジョブのジョブの詳細にあります。

イシューがv1.6.196以降のバージョンで発生している場合は、サポートに連絡して、次の情報を提供してください:

1. このトラブルシューティングセクションを参照し、イシューを動的な解析チームにエスカレーションするように依頼してください。
1. ジョブの完全なコンソール出力。
1. `gl-api-security-scanner.log`ファイルは、ジョブのアーティファクトとして入手できます。ジョブの詳細ページの右側のパネルで、**閲覧**を選択します。
1. `dast_api`ファイルからの`.gitlab-ci.yml`ジョブ定義。

## `Failed to start scanner session (version header not found)` {#failed-to-start-scanner-session-version-header-not-found}

APIセキュリティテストエンジンは、スキャナーアプリケーションコンポーネントとの接続を確立できない場合に、エラーメッセージを出力します。エラーメッセージは、`dast_api`ジョブのジョブの出力ウィンドウに表示されます。このイシューの一般的な原因は、`APISEC_API`変数をデフォルトから変更することです。

**エラーメッセージ**

- `Failed to start scanner session (version header not found).`

**解決策**:

- `APISEC_API`変数を`.gitlab-ci.yml`ファイルから削除します。値は、APIセキュリティテストCI/CDテンプレートから継承されます。値を手動で設定する代わりに、このメソッドをお勧めします。
- 変数の削除が不可能な場合は、[APIセキュリティテストCI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Security/API-Security.gitlab-ci.yml)の最新バージョンでこの値が変更されているかどうかを確認してください。その場合は、`.gitlab-ci.yml`ファイル内の値を更新します。

## `Failed to start session with scanner. Please retry, and if the problem persists reach out to support.` {#failed-to-start-session-with-scanner-please-retry-and-if-the-problem-persists-reach-out-to-support}

APIセキュリティテストエンジンは、スキャナーアプリケーションコンポーネントとの接続を確立できない場合に、エラーメッセージを出力します。エラーメッセージは、`dast_api`ジョブのジョブの出力ウィンドウに表示されます。このイシューの一般的な原因は、バックグラウンドコンポーネントが選択されたポートを既に使用されているため使用できないことです。このエラーは、タイミングが関係している場合（チャンネル競合）に断続的に発生する可能性があります。このイシューは、他のサービスがコンテナにマップされ、ポートの競合が発生しているKubernetes環境で最も頻繁に発生します。

回避策に進む前に、エラーメッセージがポートが既に使用されているために生成されたことを確認することが重要です。これが原因であったことを確認するには、次のようにします:

1. ジョブコンソールに移動します。

1. アーティファクト`gl-api-security-scanner.log`を探します。**ダウンロード**を選択してすべてのアーティファクトをダウンロードしてからファイルを検索するか、**閲覧**を選択して直接検索を開始できます。

1. テキストエディタでファイル`gl-api-security-scanner.log`を開きます。

1. エラーメッセージがポートが既に使用されているために生成された場合は、ファイルに次のようなメッセージが表示されます:

   ```log
   Failed to bind to address http://127.0.0.1:5500: address already in use.
   ```

以前のメッセージのテキスト`http://[::]:5000`は、状況によっては異なり、たとえば`http://[::]:5500`または`http://127.0.0.1:5500`になる可能性があります。エラーメッセージの残りの部分が同じである限り、ポートが既に使用されていると想定しても安全です。

ポートが既に使用されているという証拠が見つからない場合は、ジョブコンソール出力に表示される同じエラーメッセージに対処する他のトラブルシューティングセクションを確認してください。他にオプションがない場合は、適切なチャンネルを介して、[サポートを受けるか、改善をリクエストする](_index.md#get-support-or-request-an-improvement)ことをお勧めします。

イシューがポートが既に使用されていたために発生したことを確認できる場合は、CI/CD変数`APISEC_API_PORT`を使用して、スキャナーバックグラウンドコンポーネントの別のポートを指定します。

**解決策**:

1. `.gitlab-ci.yml`ファイルが設定変数`APISEC_API_PORT`を定義していることを確認します。
1. `APISEC_API_PORT`の値を、1024より大きい使用可能な任意のポート番号に更新します。提案されたポート番号がGitLabで使用されていないことを確認する必要があります。GitLabで使用するポートの完全なリストについては、[Package defaults](../../../administration/package_information/defaults.md#ports)を参照してください。

## `Application cannot determine the base URL for the target API` {#application-cannot-determine-the-base-url-for-the-target-api}

APIセキュリティテストエンジンは、OpenAPIドキュメントを検査した後、ターゲットAPIを判別できない場合にエラーメッセージを出力します。このエラーメッセージは、ターゲットAPIが`.gitlab-ci.yml`ファイルで設定されていない場合、`environment_url.txt`ファイルで使用できない場合、およびOpenAPIドキュメントを使用して計算できなかった場合に表示されます。

APIセキュリティテストエンジンがさまざまなソースを確認するときに、ターゲットAPIを取得しようとする優先順位があります。最初に、`APISEC_TARGET_URL`を使用しようとします。環境変数が設定されていない場合、APIセキュリティテストエンジンは`environment_url.txt`ファイルを使用しようとします。ファイル`environment_url.txt`がない場合、APIセキュリティテストエンジンはOpenAPIドキュメントのコンテンツと`APISEC_OPENAPI`（URLが指定されている場合）で提供されるURLを使用して、ターゲットAPIを計算しようとします。

最適なソリューションは、ターゲットAPIがデプロイごとに変更されるかどうかに依存します。静的環境では、ターゲットAPIは各デプロイで同じです。この場合、[静的環境ソリューション](#static-environment-solution)を参照してください。ターゲットAPIがデプロイごとに変更される場合は、[動的環境ソリューション](#dynamic-environment-solutions)を適用する必要があります。

## APIセキュリティテストジョブは一部のパスを操作から除外します {#api-security-testing-job-excludes-some-paths-from-operations}

一部のパスが操作から除外されていることがわかった場合は、以下を確認してください:

- 変数`DAST_API_EXCLUDE_URLS`が、テストする操作を除外するように設定されていません。
- `consumes`配列が定義されており、ターゲット定義JSONファイルに有効な型があります。

  定義例については、[プロジェクトターゲット定義ファイルの例](https://gitlab.com/gitlab-org/security-products/demos/api-dast/openapi-example/-/blob/12e2b039d08208f1dd38a1e7c52b0bda848bb449/rest_target_openapi.json?plain=1#L13)を参照してください。

### 静的環境ソリューション {#static-environment-solution}

このソリューションは、ターゲットAPI URLが変更されない（静的である）パイプライン用です。

**Add environmental variable**（環境変数を追加）

ターゲットAPIが同じままである環境の場合は、`APISEC_TARGET_URL`環境変数を使用してターゲットURLを指定することをお勧めします。`.gitlab-ci.yml`で、変数`APISEC_TARGET_URL`を追加します。変数は、APIテストターゲットのベースURLに設定する必要があります。例: 

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OPENAPI: test-api-specification.json
```

### 動的環境ソリューション {#dynamic-environment-solutions}

動的環境では、ターゲットAPIは異なるデプロイごとに変更されます。この場合、複数の可能なソリューションがあります。`environment_url.txt`ファイルは動的環境を扱うときに使用することをお勧めします。

**Use environment_url.txt**（environment_url.txtを使用）

ターゲットAPI URLが各パイプライン中に変更される動的環境をサポートするために、APIセキュリティテストエンジンは、使用するURLを含む`environment_url.txt`ファイルの使用をサポートします。このファイルはリポジトリにチェックインされませんが、代わりにテストターゲットをデプロイするジョブによってパイプライン中に作成され、パイプライン内の以降のジョブで使用できるアーティファクトとして収集されます。`environment_url.txt`ファイルを作成するジョブは、APIセキュリティテストエンジンのジョブの前に実行する必要があります。

1. テストターゲットデプロイメントジョブを変更して、ベースURLをプロジェクトのルートにある`environment_url.txt`ファイルに追加します。
1. アーティファクトとして`environment_url.txt`を収集するテストターゲットデプロイメントジョブを変更します。

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

## 無効なスキーマでOpenAPIを使用する {#use-openapi-with-an-invalid-schema}

ドキュメントが無効なスキーマで自動生成されるか、タイムリーな方法で手動で編集できない場合があります。これらのシナリオでは、APIセキュリティテストは、変数`APISEC_OPENAPI_RELAXED_VALIDATION`を設定することにより、緩和された検証を実行できます。予期しない動作を防ぐために、完全に準拠したOpenAPIドキュメントを提供することをお勧めします。

### 非準拠のOpenAPIファイルを編集する {#edit-a-non-compliant-openapi-file}

OpenAPI仕様に準拠していない要素を検出して修正するには、エディタを使用することをお勧めします。エディタは通常、ドキュメントの検証を提供し、スキーマ準拠のOpenAPIドキュメントを作成するための提案を提供します。推奨されるエディタは次のとおりです:

| エディタ | OpenAPI 2.0 | OpenAPI 3.0.x | OpenAPI 3.1.x |
|--------|-------------|---------------|---------------|
| [Stoplight Studio](https://stoplight.io/solutions) | {{< icon name="check-circle" >}} YAML、JSON | {{< icon name="check-circle" >}} YAML、JSON | {{< icon name="check-circle" >}} YAML、JSON |
| [Swagger Editor](https://editor.swagger.io/)       | {{< icon name="check-circle" >}} YAML、JSON | {{< icon name="check-circle" >}} YAML、JSON | {{< icon name="dotted-circle" >}} YAML、JSON |

OpenAPIドキュメントが手動で生成される場合は、エディタにドキュメントを読み込むみ、準拠していないものを修正します。ドキュメントが自動的に生成される場合は、エディタに読み込むんでスキーマの問題を特定し、アプリケーションに移動して、使用しているフレームワークに基づいて修正を実行します。

### OpenAPI緩和された検証を有効にする {#enable-openapi-relaxed-validation}

緩和された検証は、OpenAPIドキュメントがOpenAPI仕様を満たすことができないが、それでも異なるツールで使用するのに十分なコンテンツがある場合を対象としています。検証が実行されますが、ドキュメントスキーマに関して厳密ではありません。

APIセキュリティテストは、OpenAPI仕様に完全に準拠していないOpenAPIドキュメントを使用しようとすることができます。APIセキュリティテストに緩和された検証を実行するように指示するには、変数`APISEC_OPENAPI_RELAXED_VALIDATION`を任意の値に設定します。例:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_PROFILE: Quick
  APISEC_TARGET_URL: http://test-deployment/
  APISEC_OPENAPI: test-api-specification.json
  APISEC_OPENAPI_RELAXED_VALIDATION: 'On'
```

## `No operation in the OpenAPI document is consuming any supported media type` {#no-operation-in-the-openapi-document-is-consuming-any-supported-media-type}

APIセキュリティテストは、OpenAPIドキュメントで指定されたメディアタイプを使用してリクエストを生成します。サポートされているメディアタイプが不足しているためにリクエストを作成できない場合は、エラーがスローされます。

**エラーメッセージ**

- `Error, no operation in the OpenApi document is consuming any supported media type. Check 'OpenAPI Specification' to check the supported media types.`

**解決策**:

1. [OpenAPI仕様](configuration/enabling_the_analyzer.md#openapi-specification)セクションでサポートされているメディアタイプをレビューします。
1. 少なくとも特定の操作がサポートされているメディアタイプのいずれかを受け入れるように、OpenAPIドキュメントを編集します。または、サポートされているメディアタイプをOpenAPIドキュメントレベルで設定し、すべての操作に適用することができます。このステップでは、サポートされているメディアタイプがアプリケーションで受け入れられるように、アプリケーションに変更が必要になる場合があります。

## エラー: `The SSL connection could not be established, see inner exception.` {#error-the-ssl-connection-could-not-be-established-see-inner-exception}

APIセキュリティテストは、古くなったプロトコルや暗号など、幅広いTLS設定と互換性があります。幅広いサポートにもかかわらず、次のような接続エラーが発生する可能性があります:

```plaintext
Error, error occurred trying to download `<URL>`:
There was an error when retrieving content from Uri:' <URL>'.
Error:The SSL connection could not be established, see inner exception.
```

このエラーは、APIセキュリティテストが、指定されたURLでサーバーとの安全な接続を確立できなかったために発生します。

この問題を解決するには:

エラーメッセージのホストが非TLS接続をサポートしている場合は、設定で`https://`を`http://`に変更します。たとえば、次の設定でエラーが発生した場合:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: https://test-deployment/
  APISEC_OPENAPI: https://specs/openapi.json
```

`APISEC_OPENAPI`のプレフィックスを`https://`から`http://`に変更します:

```yaml
stages:
  - dast

include:
  - template: API-Security.gitlab-ci.yml

variables:
  APISEC_TARGET_URL: https://test-deployment/
  APISEC_OPENAPI: http://specs/openapi.json
```

URLにアクセスするために非TLS接続を使用できない場合は、サポートチームにお問い合わせください。

[testssl.shツール](https://testssl.sh/)を使用して調査を迅速化できます。bashシェルがあり、影響を受けるサーバーに接続されているマシンから:

1. 最新リリース`zip`または`tar.gz`ファイルをダウンロードし、<https://github.com/drwetter/testssl.sh/releases>から抽出します。
1. `./testssl.sh --log https://specs`を実行します。
1. ログファイルをサポートチケットに添付してください。

## `ERROR: Job failed: failed to pull image` {#error-job-failed-failed-to-pull-image}

このエラーメッセージは、アクセスするために認証を必要とする（公開されていない）コンテナイメージからプルするときに発生します。

ジョブコンソール出力では、エラーは次のようになります:

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

**解決策**:

認証の認証情報は、[プライベートコンテナレジストリからイメージにアクセスする](../../../ci/docker/using_docker_images.md#access-an-image-from-a-private-container-registry)ドキュメントセクションで概説されているメソッドを使用して提供されます。使用されるメソッドは、コンテナレジストリプロバイダーとその設定によって指示されます。クラウドプロバイダー（Azure、Google Cloud（GCP）、AWSなど）などのサードパーティが提供するコンテナレジストリを使用している場合は、プロバイダーのドキュメントで、レジストリへの認証方法を確認してください。

次の例では、[静的に定義された認証情報](../../../ci/docker/using_docker_images.md#use-statically-defined-credentials)認証メソッドを使用します。この例では、コンテナレジストリは`registry.example.com`であり、イメージは`my-target-app:latest`です。

1. `DOCKER_AUTH_CONFIG`の変数の値を計算する方法を理解するには、[`DOCKER_AUTH_CONFIG`データを決定する方法](../../../ci/docker/using_docker_images.md#determine-your-docker_auth_config-data)をお読みください。設定変数`DOCKER_AUTH_CONFIG`には、適切な認証情報を提供するためのDockerJSON設定が含まれています。たとえば、プライベートコンテナレジストリ:`registry.example.com`に認証情報`abcdefghijklmn`でアクセスするには、DockerJSONは次のようになります:

   ```json
   {
       "auths": {
           "registry.example.com": {
               "auth": "abcdefghijklmn"
           }
       }
   }
   ```

1. `DOCKER_AUTH_CONFIG`をCI/CD変数として追加します。設定変数を`.gitlab-ci.yml`ファイルに直接追加する代わりに、プロジェクトの[CI/CD変数](../../../ci/variables/_index.md#for-a-project)を作成する必要があります。
1. ジョブを再実行すると、静的に定義された認証情報を使用して、プライベートコンテナレジストリ`registry.example.com`にサインインし、イメージ`my-target-app:latest`をプルできるようになります。成功した場合、ジョブコンソールには次のような出力が表示されます:

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

## 連続したスキャン間で脆弱性の結果が異なる {#differing-vulnerability-results-between-consecutive-scans}

連続したスキャンは、コードまたは設定の変更がない場合でも、異なる脆弱性の調査結果を返す可能性があります。これは主に、ターゲット環境とその状態に関連する予測不可能性と、スキャナーによって送信されるリクエストの並列化が原因です。スキャン時間を最適化するために、複数のリクエストがスキャナーによって並行して送信されます。これは、ターゲットサーバーがリクエストに応答する正確な順序が事前に決定されていないことを意味します。

OSコマンドやSQLインジェクションなどのリクエストと応答の間の時間の長さによって検出されるタイミング攻撃の脆弱性は、サーバーが読み込まれており、特定のしきい値内のテストへの応答を処理できない場合に検出される可能性があります。サーバーが読み込まれていない場合の同じスキャン実行では、これらの脆弱性に対して肯定的な調査結果が返されない可能性があり、結果が異なる可能性があります。ターゲットサーバーのプロファイル、[パフォーマンスの調整とテスト速度](performance.md)、およびテスト中の最適なサーバーパフォーマンスのベースラインを確立することは、前述の要因により誤検出が表示される可能性のある場所を特定するのに役立ちます。

## エラー: `sudo: The "no new privileges" flag is set, which prevents sudo from running as root.` {#error-sudo-the-no-new-privileges-flag-is-set-which-prevents-sudo-from-running-as-root}

アナライザーのv5バージョンから、ルート以外のユーザーがデフォルトで使用されます。特権操作を実行するときに`sudo`を使用する必要があります。

このエラーは、コンテナが新しい権限を取得するのを防ぐ特定のコンテナデーモンの設定で発生します。ほとんどの設定では、これはデフォルトの設定ではありません。多くの場合、セキュリティ強化ガイドの一部として、具体的に設定されたものです。

**エラーメッセージ**

このイシューは、`before_script`または`APISEC_PRE_SCRIPT`の実行時に生成されるエラーメッセージによって識別できます:

```shell
$ sudo apk add nodejs

sudo: The "no new privileges" flag is set, which prevents sudo from running as root.

sudo: If sudo is running in a container, you may need to adjust the container configuration to disable the flag.
```

**解決策**:

このイシューは、次の方法で回避策を講じることができます:

- `root`ユーザーとしてコンテナを実行します。この構成がすべての場合に機能するとは限らないため、テストする必要があります。これは、CICD設定を変更し、`whoami`が`root`を返し、`gitlab`を返さないことを確認するためにジョブの出力を確認することで実行できます。`gitlab`が表示されている場合は、別の回避策を使用してください。テストにより変更が成功したことが確認されたら、`before_script`を削除できます。

  ```yaml
  api_security:
    image:
      name: $SECURE_ANALYZERS_PREFIX/$APISEC_IMAGE:$APISEC_VERSION$APISEC_IMAGE_SUFFIX
      docker:
        user: root
   before_script:
     - whoami
  ```

  _ジョブコンソールの出力例:_

  ```log
  Executing "step_script" stage of the job script
  Using docker image sha256:8b95f188b37d6b342dc740f68557771bb214fe520a5dc78a88c7a9cc6a0f9901 for registry.gitlab.com/security-products/api-security:5 with digest registry.gitlab.com/security-products/api-security@sha256:092909baa2b41db8a7e3584f91b982174772abdfe8ceafc97cf567c3de3179d1 ...
  $ whoami
  root
  $ /peach/analyzer-api-security
  17:17:14 [INF] API Security: Gitlab API Security
  17:17:14 [INF] API Security: -------------------
  17:17:14 [INF] API Security:
  17:17:14 [INF] API Security: version: 5.7.0
  ```

- コンテナをラップし、ビルド時に依存関係を追加します。このオプションには、一部の顧客で要件となる可能性がある、rootよりも低い権限で実行できるという利点があります。

  1. 既存のイメージをラップする新しい`Dockerfile`を作成します。

     ```yaml
     ARG SECURE_ANALYZERS_PREFIX
     ARG APISEC_IMAGE
     ARG APISEC_VERSION
     ARG APISEC_IMAGE_SUFFIX
     FROM $SECURE_ANALYZERS_PREFIX/$APISEC_IMAGE:$APISEC_VERSION$APISEC_IMAGE_SUFFIX
     USER root

     RUN pip install ...
     RUN apk add ...

     USER gitlab
     ```

  1. APIセキュリティテストジョブの開始前に、新しいイメージをローカルコンテナレジストリにプッシュします。イメージは、`api_security`ジョブが完了した後に削除する必要があります。

     ```shell
     TARGET_NAME=apisec-$CI_COMMIT_SHA
     docker build -t $TARGET_IMAGE \
       --build-arg "SECURE_ANALYZERS_PREFIX=$SECURE_ANALYZERS_PREFIX" \
       --build-arg "APISEC_IMAGE=$APISEC_IMAGE" \
       --build-arg "APISEC_VERSION=$APISEC_VERSION" \
       --build-arg "APISEC_IMAGE_SUFFIX=$APISEC_IMAGE_SUFFIX" \
       .
     docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
     docker push $TARGET_IMAGE
     ```

  1. `api_security`ジョブを拡張し、新しいイメージ名を使用します。

     ```yaml
     api_security:
       image: apisec-$CI_COMMIT_SHA
     ```

  1. レジストリから一時コンテナを削除します。[コンテナイメージの削除に関する情報については、こちらのドキュメントページをご覧ください。](../../packages/container_registry/delete_container_registry_images.md)

- GitLab Runner設定を変更して、no-new-privilegesフラグを無効にします。これはセキュリティ上の影響を与える可能性があるため、運用チームおよびセキュリティチームと話し合う必要があります。

## `Index was outside the bounds of the array.    at Peach.Web.Runner.Services.RunnerOptions.GetHeaders()` {#index-was-outside-the-bounds-of-the-array----at-peachwebrunnerservicesrunneroptionsgetheaders}

このエラーメッセージは、APIセキュリティテストアナライザーが、`APISEC_REQUEST_HEADERS`または`APISEC_REQUEST_HEADERS_BASE64`の設定変数の値を解析中できないことを示しています。

**エラーメッセージ**

このイシューは、2つのエラーメッセージで識別できます。1つ目のエラーメッセージはジョブコンソールの出力に表示され、2つ目のエラーメッセージは`gl-api-security-scanner.log`ファイルに表示されます。

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

**解決策**:

このイシューは、不正な形式の`APISEC_REQUEST_HEADERS`または`APISEC_REQUEST_HEADERS_BASE64`変数が原因で発生します。期待される形式は、コンマで区切られた`Header: value`構造の1つ以上のヘッダーです。解決策は、期待されるものと一致するように構文を修正することです。

_有効な例:_

- `Authorization: Bearer XYZ`
- `X-Custom: Value,Authorization: Bearer XYZ`

_無効な例:_

- `Header:,value`
- `HeaderA: value,HeaderB:,HeaderC: value`
- `Header`
