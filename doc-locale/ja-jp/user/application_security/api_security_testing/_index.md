---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: APIセキュリティテストアナライザー
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [名前が変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/457449) GitLab 17.0で「DAST APIアナライザー」から「APIセキュリティテストアナライザー」へ。

{{< /history >}}

Web APIをテストして、他のQAプロセスでは見逃される可能性のあるバグや潜在的なセキュリティ上の問題を検出します。他のセキュリティスキャナーや独自のテストプロセスに加えて、APIセキュリティテストを使用します。APIセキュリティテストは、CI/CDワークフロー、[オンデマンド](../dast/on-demand_scan.md)、またはその両方の一部として実行できます。

{{< alert type="warning" >}}

本番環境サーバーに対してAPIセキュリティテストを実行しないでください。APIが実行できる機能が実行できるだけでなく、APIでバグをトリガーする可能性もあります。これには、データの変更や削除などのアクションが含まれます。テストサーバーに対してのみAPIセキュリティテストを実行してください。

{{< /alert >}}

## はじめに {#getting-started}

CI/CD設定ファイルを編集して、APIセキュリティテストを開始します。

前提要件: 

- サポートされているAPIタイプのいずれかを使用するWeb APIが必要です:
  - REST API
  - SOAP
  - GraphQL
  - フォームの本文、JSON、またはXML
- 次のいずれかの形式でAPIの仕様が必要です:
  - [OpenAPI v2またはv3仕様](configuration/enabling_the_analyzer.md#openapi-specification)
  - [GraphQLのGraphQLスキーマ](configuration/enabling_the_analyzer.md#graphql-schema)
  - [HTTPアーカイブ（HAR）](configuration/enabling_the_analyzer.md#http-archive-har)
  - [Postman Collection v2.0またはv2.1](configuration/enabling_the_analyzer.md#postman-collection)

  各スキャンは、1つの仕様のみをサポートします。複数の仕様をスキャンするには、複数のスキャンを使用します。
- Linux/amd64で、[GitLab Runner](../../../ci/runners/_index.md)と[`docker`executor](https://docs.gitlab.com/runner/executors/docker.html)が利用可能です。
- デプロイされたターゲットアプリケーションが必要です。詳細については、[デプロイメントオプション](#application-deployment-options)を参照してください。
- `dast`ステージが、`deploy`ステージの後、CI/CDパイプライン定義に追加されます。例: 

  ```yaml
  stages:
    - build
    - test
    - deploy
    - dast
  ```

APIセキュリティテストを有効にするには、環境の固有のニーズに基づいて、GitLab CI/CD設定YAMLを変更する必要があります。次のものを使用して、スキャンするAPIを指定できます:

- [OpenAPI v2またはv3仕様](configuration/enabling_the_analyzer.md#openapi-specification)
- [GraphQLのGraphQLスキーマ](configuration/enabling_the_analyzer.md#graphql-schema)
- [HTTPアーカイブ（HAR）](configuration/enabling_the_analyzer.md#http-archive-har)
- [Postman Collection v2.0またはv2.1](configuration/enabling_the_analyzer.md#postman-collection)

## 結果について理解する {#understanding-the-results}

セキュリティスキャンの出力を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**ビルド** > **パイプライン**を選択します。
1. パイプラインを選択します。
1. **セキュリティ**タブを選択します。
1. 脆弱性を選択して、次の詳細を表示します:
   - ステータス: 脆弱性がトリアージされたか、解決されたかを示します。
   - 説明: 脆弱性の原因、潜在的な影響、推奨される修正手順について説明しています。
   - 重大度: 影響に基づいて6つのレベルに分類されます。[重大度レベルの詳細はこちらをご覧ください](../vulnerabilities/severities.md)。
   - スキャナー: 脆弱性を検出したアナライザーを示します。
   - 方法: 脆弱なサーバーインタラクションタイプを確立します。
   - URL: 脆弱性の場所を示します。
   - 証拠: 特定の脆弱性の存在を証明するテストケースを記述します
   - 識別子: CWE識別子など、脆弱性の分類に使用される参照の一覧です。

セキュリティスキャンの結果をダウンロードすることもできます:

- パイプラインの**セキュリティ**タブで、**結果をダウンロード**を選択します。

詳細については、[パイプラインセキュリティレポート](../detect/security_scanning_results.md)を参照してください。

{{< alert type="note" >}}

発見がフィーチャーブランチ上に生成されます。その発見がデフォルトブランチにマージされると、脆弱性になります。この区別は、セキュリティ対策状況を評価する上で重要です。

{{< /alert >}}

## 最適化 {#optimization}

APIセキュリティテストを最大限に活用するには、次の推奨事項に従ってください:

- アナライザーの最新バージョンを実行するには、[常にプルポリシー](https://docs.gitlab.com/runner/executors/docker.html#using-the-always-pull-policy)を使用するようにRunnerを設定します。
- デフォルトでは、APIセキュリティテストは、パイプライン内の前のジョブで定義されたすべてのアーティファクトをダウンロードします。DASTDASTジョブがテスト対象のURLを定義するために`environment_url.txt`に依存していない場合、または以前のジョブで作成された他のファイルに依存していない場合は、アーティファクトをダウンロードしないでください。アーティファクトのダウンロードを回避するには、依存関係がないことを指定するように、アナライザーCI/CDジョブを拡張します。たとえば、APIセキュリティテストアナライザーの場合、次の内容を`.gitlab-ci.yml`ファイルに追加します:

  ```yaml
  api_security:
    dependencies: []
  ```

特定のアプリケーションまたは環境のAPIセキュリティテストを設定するには、[構成オプション](configuration/_index.md)の完全なリストを参照してください。

## ロールアウトする {#roll-out}

CI/CDパイプラインで実行すると、APIセキュリティテストスキャンはデフォルトで`dast`ステージで実行されます。APIセキュリティテストスキャンで最新のコードが確実に検査されるようにするには、CI/CDパイプラインが`dast`ステージの前のステージのテスト環境に変更をデプロイするようにします。

パイプラインが実行ごとに同じWebサーバーにデプロイするように設定されている場合、別のパイプラインの実行中にパイプラインを実行すると、競合状態が発生し、1つのパイプラインが別のパイプラインからのコードを上書きする可能性があります。スキャンされるAPIは、APIセキュリティテストスキャンの期間中、変更から除外する必要があります。APIへの唯一の変更は、APIセキュリティテストスキャナーからのものである必要があります。スキャン中のAPIに加えられた変更（たとえば、ユーザー、スケジュールされたタスク、データベースの変更、コードの変更、他のパイプライン、または他のスキャナー）は、不正確な結果を引き起こす可能性があります。

### APIセキュリティテストスキャン構成例 {#example-api-security-testing-scanning-configurations}

次のプロジェクトは、APIセキュリティテストスキャンを示しています:

- [OpenAPI v3仕様プロジェクトの例](https://gitlab.com/gitlab-org/security-products/demos/api-dast/openapi-v3-example)
- [OpenAPI v2仕様プロジェクトの例](https://gitlab.com/gitlab-org/security-products/demos/api-dast/openapi-example)
- [HTTPアーカイブ（HAR）プロジェクトの例](https://gitlab.com/gitlab-org/security-products/demos/api-dast/har-example)
- [Postman Collectionプロジェクトの例](https://gitlab.com/gitlab-org/security-products/demos/api-dast/postman-example)
- [GraphQLプロジェクトの例](https://gitlab.com/gitlab-org/security-products/demos/api-dast/graphql-example)
- [SOAPプロジェクトの例](https://gitlab.com/gitlab-org/security-products/demos/api-dast/soap-example)
- [Seleniumを使用した認証トークン](https://gitlab.com/gitlab-org/security-products/demos/api-dast/auth-token-selenium)

### アプリケーションデプロイのオプション {#application-deployment-options}

APIセキュリティテストには、スキャンするためにデプロイされたアプリケーションを利用できる必要があります。

ターゲットアプリケーションの複雑さに応じて、APIセキュリティテストテンプレートをデプロイおよび設定する方法がいくつかあります。

#### レビューアプリ {#review-apps}

レビューアプリは、DASTDASTターゲットアプリケーションをデプロイする最も複雑な方法です。このプロセスを支援するために、GitLabはGoogle Kubernetes Engine（GKE）を使用したレビューアプリのデプロイを作成しました。この例は[レビューアプリ - GKE](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke)プロジェクトにあり、さらに[README.md](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke/-/blob/master/README.md)のDASTDASTのレビューアプリを設定する詳細な手順があります。

#### Dockerサービス {#docker-services}

アプリケーションがDockerコンテナを使用している場合は、DASTDASTを使用してデプロイおよびスキャンするための別のオプションがあります。Dockerビルドジョブが完了し、イメージがコンテナレジストリに追加されたら、イメージを[サービス](../../../ci/services/_index.md)として使用できます。

`.gitlab-ci.yml`でサービス定義を使用することにより、DASTDASTアナライザーでサービスをスキャンできます。

ジョブに`services`セクションを追加すると、`alias`を使用して、サービスへのアクセスに使用できるホスト名を定義します。次の例では、`alias: yourapp` `dast`ジョブ定義の部分は、デプロイされたアプリケーションへのURLがホスト名として`yourapp`を使用することを意味します（`https://yourapp/`）。

```yaml
stages:
  - build
  - dast

include:
  - template: API-Security.gitlab-ci.yml

# Deploys the container to the GitLab container registry
deploy:
  services:
  - name: docker:dind
    alias: dind
  image: docker:20.10.16
  stage: build
  script:
    - docker login -u gitlab-ci-token -p $CI_JOB_TOKEN $CI_REGISTRY
    - docker pull $CI_REGISTRY_IMAGE:latest || true
    - docker build --tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA --tag $CI_REGISTRY_IMAGE:latest .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker push $CI_REGISTRY_IMAGE:latest

api_security:
  services: # use services to link your app container to the dast job
    - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      alias: yourapp

variables:
  APISEC_TARGET_URL: https://yourapp
```

ほとんどのアプリケーションは、データベースやキャッシュサービスなどの複数のサービスに依存しています。デフォルトでは、servicesフィールドで定義されたサービスは互いに通信できません。サービス間の通信を許可するには、`FF_NETWORK_PER_BUILD` [機能フラグ](https://docs.gitlab.com/runner/configuration/feature-flags.html#available-feature-flags)を有効にします。

```yaml
variables:
  FF_NETWORK_PER_BUILD: "true" # enable network per build so all services can communicate on the same network

services: # use services to link the container to the dast job
  - name: mongo:latest
    alias: mongo
  - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    alias: yourapp
```

## サポートを受けるか、改善をリクエストしてください {#get-support-or-request-an-improvement}

特定の問題のサポートを受けるには、[ヘルプチャンネル](https://about.gitlab.com/get-help/)を使用してください。

[GitLab.comのGitLabイシュートラッカー](https://gitlab.com/gitlab-org/gitlab/-/issues)は、APIセキュリティテストに関するバグや機能提案に最適な場所です。APIセキュリティテストに関する新しいイシューをオープンする際は、適切な担当者が迅速に確認できるように、`~"Category:API Security"`ラベルを使用してください。

独自のものを送信する前に、同様のエントリについて[イシュートラッカーを検索してください。他の誰かが同じイシューまたは機能提案を抱えている可能性が高くなります。](https://gitlab.com/gitlab-org/gitlab/-/issues)絵文字リアクションでサポートを示すか、ディスカッションに参加してください。

予期したとおりに動作しない動作が発生した場合は、コンテキスト情報を提供することを検討してください:

- GitLab Self-Managedインスタンスを使用している場合は、GitLabのバージョン。
- `.gitlab-ci.yml`ジョブ定義。
- ジョブコンソールの完全な出力。
- スキャナーのログファイルは、`gl-api-security-scanner.log`という名前のジョブアーティファクトとして利用できます。

{{< alert type="warning" >}}

**Sanitize data attached to a support issue**（サポートイシューに添付されたデータをサニタイズします）。認証情報、パスワード、トークン、キー、シークレットなど、機密情報を削除します。

{{< /alert >}}

## 用語集 {#glossary}

- アサート: アサーションは、チェックによって脆弱性をトリガーするために使用される検出モジュールです。多くのアサーションには設定があります。チェックでは、複数のアサーションを使用できます。たとえば、ログ分析、応答分析、ステータスコードは、チェックで一緒に使用される一般的なアサーションです。複数のアサーションを含むチェックを使用すると、オンとオフを切り替えることができます。
- チェック: 特定のタイプのテストを実行するか、特定のタイプの脆弱性のチェックを実行しました。たとえば、SQLSQLインジェクションチェックは、SQLSQLインジェクションの脆弱性についてDASTDASTテストを実行します。APIセキュリティテストスキャナーは、いくつかのチェックで構成されています。チェックはプロファイルでオンとオフを切り替えることができます。
- プロファイル: 設定ファイルには、1つ以上のテストプロファイル、またはサブ設定があります。フィーチャーブランチのプロファイルと、mainブランチの追加テストを含む別のプロファイルがある場合があります。
