---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Web APIファズテスト
description: テスト、セキュリティ、脆弱性、自動化、エラー。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Web APIファズテストは、予期しない値をAPI操作パラメータに渡し、バックエンドで予期しない動作やエラーを引き起こします。ファズテストを使用して、他の品質保証プロセスでは見逃される可能性のあるバグや潜在的な脆弱性を発見します。

ファズテストは、[GitLab Secure](../_index.md)の他のセキュリティスキャナーや独自のテストプロセスに追加して使用する必要があります。[GitLab CI/CD](../../../ci/_index.md)を使用している場合、CI/CDワークフローの一部としてファズテストを実行できます。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[WebAPI Fuzzing - Advanced Security Testing](https://www.youtube.com/watch?v=oUHsfvLGhDk)を参照してください。

## はじめに {#getting-started}

CI/CD設定を編集して、APIファジングを開始します。

前提要件: 

- サポートされているAPIタイプのうちの1つを使用するWeb API:
  - REST API
  - SOAP
  - GraphQL
  - フォーム本文、JSON、またはXML
- 次のいずれかの形式のAPI仕様:
  - OpenAPI v2またはv3仕様
  - GraphQLのスキーマ
  - HTTPアーカイブ（HAR）
  - Postman Collection v2.0またはv2.1
- Linux/amd64で`docker` executorを使用できるRunner。
- デプロイされたターゲット・アプリケーション。
- `fuzz`ステージが、`deploy`ステージの後に、CI/CDパイプライン定義に追加されます:

  ```yaml
  stages:
    - build
    - test
    - deploy
    - fuzz
  ```

APIファジングを有効にするには:

- [Web APIファジング設定フォーム](configuration/enabling_the_analyzer.md#web-api-fuzzing-configuration-form)を使用します。

  このフォームでは、最も一般的なAPIファジングオプションの値を選択し、GitLab CI/CD設定ファイルに貼り付けることができるYAMLスニペットを作成できます。

## 結果について理解する {#understanding-the-results}

セキュリティスキャンの出力を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**ビルド** > **パイプライン**を選択します。
1. パイプラインを選択します。
1. **セキュリティ**タブを選択します。
1. 脆弱性を選択して、次の詳細を表示します:
   - ステータス: 脆弱性がトリアージされたか、解決されたかを示します。
   - 説明: 脆弱性の原因、潜在的な影響、推奨される修正手順について説明しています。
   - 重大度: 影響に基づいて6つのレベルに分類されます。詳細については、[重大度レベル](../vulnerabilities/severities.md)を参照してください。
   - スキャナー: 脆弱性を検出したアナライザーを示します。
   - 方法: 脆弱性のあるサーバーのインタラクション・タイプを確立します。
   - URL: 脆弱性の場所を示します。
   - 証拠: 特定の脆弱性の存在を証明するためのテストケースを記述します
   - 識別子: CWE識別子など、脆弱性の分類に使用される参照の一覧です。

セキュリティスキャンの結果をダウンロードすることもできます:

- パイプラインの**セキュリティ**タブで、**結果をダウンロード**を選択します。

詳細については、[パイプラインセキュリティレポート](../detect/security_scanning_results.md)を参照してください。

{{< alert type="note" >}}

発見がフィーチャーブランチ上に生成されます。その発見がデフォルトブランチにマージされると、脆弱性になります。この区別は、セキュリティ対策状況を評価する上で重要です。

{{< /alert >}}

## 最適化 {#optimization}

APIファジングを最大限に活用するには、次の推奨事項に従ってください:

- アナライザーの最新バージョンを実行するには、`pull_policy: always`を使用するようにRunnerを設定します。
- デフォルトでは、APIファジングは、パイプライン内の以前のジョブで定義されたすべてのアーティファクトをダウンロードします。APIファジングジョブが、テスト対象のURLを定義するために`environment_url.txt`に依存していない場合、または以前のジョブで作成されたその他のファイルに依存していない場合は、アーティファクトをダウンロードしないでください。

  アーティファクトのダウンロードを避けるには、アナライザーのCI/CDジョブを拡張して、依存関係がないことを指定します。たとえば、APIファジングアナライザーの場合は、次の内容を`.gitlab-ci.yml`ファイルに追加します:

  ```yaml
  apifuzzer_fuzz:
    dependencies: []
  ```

### アプリケーションデプロイのオプション {#application-deployment-options}

APIファジングでは、スキャンに使用できるデプロイ済みのアプリケーションが必要です。

ターゲット・アプリケーションの複雑さに応じて、APIファジングテンプレートをデプロイおよび設定する方法にはいくつかのオプションがあります。

#### レビューアプリ {#review-apps}

レビューアプリは、APIファジングターゲットアプリケーションをデプロイするための最も複雑な方法です。このプロセスを支援するために、GitLabはGoogle Kubernetes Engine（GKE）を使用したレビューアプリのデプロイを作成しました。この例は、[Review apps - GKE](https://gitlab.com/gitlab-org/security-products/demos/dast/review-app-gke)プロジェクト、およびDASTでレビューアプリを設定するための詳細な手順にあります。

#### Docker services {#docker-services}

アプリケーションがDockerコンテナを使用している場合は、APIファジングでデプロイおよびスキャンするための別のオプションがあります。Dockerビルドジョブが完了し、イメージがレジストリに追加された後、イメージをサービスとして使用できます。

`.gitlab-ci.yml`でサービス定義を使用することにより、DASTアナライザーでサービスをスキャンできます。

ジョブに`services`セクションを追加する場合、`alias`はサービスへのアクセスに使用できるホスト名を定義するために使用されます。次の例では、`alias: yourapp`部分の`dast`ジョブ定義は、デプロイされたアプリケーションへのURLがホスト名として`yourapp`を使用することを意味します: `https://yourapp/`

```yaml
stages:
  - build
  - fuzz

include:
  - template: API-Fuzzing.gitlab-ci.yml

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

apifuzzer_fuzz:
  services: # use services to link your app container to the dast job
    - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
      alias: yourapp

variables:
  FUZZAPI_TARGET_URL: https://yourapp
```

ほとんどのアプリケーションは、データベースやキャッシュサービスなどの複数のサービスに依存しています。デフォルトでは、サービス・フィールドで定義されたサービスは、相互に通信できません。サービス間の通信を許可するには、`FF_NETWORK_PER_BUILD`機能フラグを有効にします。

```yaml
variables:
  FF_NETWORK_PER_BUILD: "true" # enable network per build so all services can communicate on the same network

services: # use services to link the container to the dast job
  - name: mongo:latest
    alias: mongo
  - name: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    alias: yourapp
```

## ロールアウトする {#roll-out}

Web APIファジングはCI/CDパイプラインの`fuzz`ステージで実行されます。APIファジングが最新のコードをスキャンできるようにするには、CI/CDパイプラインが`fuzz`ステージより前のいずれかのステージでテスト環境への変更をデプロイする必要があります。

パイプラインが実行ごとに同じWebサーバーにデプロイするように設定されている場合、別のパイプラインの実行中にパイプラインを実行すると、あるパイプラインが別のコードを上書きする競合状態が発生する可能性があります。スキャンするAPIは、ファジングスキャンの期間中、変更から除外する必要があります。APIに対する唯一の変更は、ファジングスキャナーからのものである必要があります。スキャン中にAPIに加えられた変更（たとえば、ユーザー、スケジュールされたタスク、データベースの変更、コードの変更、他のパイプライン、または他のスキャナー）は、不正確な結果を引き起こす可能性があります。

次のメソッドを使用して、Web APIファジングスキャンを実行できます:

- OpenAPI仕様（バージョン2および3）
- GraphQLスキーマ
- HTTPアーカイブ（HAR）
- Postmanコレクション（バージョン2.0および2.1）

### APIファジングプロジェクトの例 {#example-api-fuzzing-projects}

- [OpenAPI v2仕様プロジェクトの例](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/openapi)
- [HTTPアーカイブ（HAR）プロジェクトの例](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing-example/-/tree/har)
- [Postman Collectionプロジェクトの例](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/postman-api-fuzzing-example)
- [GraphQLプロジェクトの例](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/graphql-api-fuzzing-example)
- [SOAPプロジェクトの例](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/soap-api-fuzzing-example)
- [Seleniumを使用した認証トークン](https://gitlab.com/gitlab-org/security-products/demos/api-fuzzing/auth-token-selenium)

## サポートを受けるか、改善をリクエストする {#get-support-or-request-an-improvement}

特定の問題に対するサポートを受けるには、[ヘルプチャンネルの取得](https://about.gitlab.com/get-help/)を使用してください。

[GitLab.comのGitLabイシュートラッカー](https://gitlab.com/gitlab-org/gitlab/-/issues)は、APIセキュリティとAPIファジングに関するバグや機能提案に最適な場所です。APIファジングに関する新しいイシューをオープンするときに`~"Category:API Security"`ラベルを使用すると、適切な担当者によって迅速にレビューされます。

独自のエントリを送信する前にイシュートラッカーで同様のエントリを検索してください。他の誰かが同じイシューまたは機能提案を持っている可能性が高くなります。絵文字リアクションでサポートを示したり、ディスカッションに参加したりできます。

予期したとおりに動作しない動作が発生した場合は、コンテキスト情報を提供することを検討してください:

- GitLab Self-Managedインスタンスを使用している場合は、GitLabのバージョン。
- `.gitlab-ci.yml`ジョブ定義。
- 完全なジョブコンソール出力。
- スキャナーのログファイルは、`gl-api-security-scanner.log`という名前のジョブアーティファクトとして使用できます。

{{< alert type="warning" >}}

イシューを送信するときは、機密情報を含めないでください。パスワード、トークン、キーなどの認証情報を削除します。

{{< /alert >}}

## 用語集 {#glossary}

- Assert: アサーションは、チェックによってフォルトをトリガーするために使用される検出モジュールです。多くのアサーションには、設定があります。チェックは、複数のアサーションを使用できます。たとえば、ログ分析、応答分析、およびステータスコードは、チェックによって一緒に使用される一般的なアサーションです。複数のアサーションを含むチェックでは、それらをオン/オフにできます。
- Check: 特定のタイプのテストを実行するか、脆弱性のタイプをチェックするために実行します。たとえば、JSONファジングCheckは、JSONペイロードのファズテストを実行します。APIファザーは、いくつかのチェックで構成されています。チェックはプロファイルでオン/オフにできます。
- Fault: ファジング中に、Assertによって識別された失敗はフォルトと呼ばれます。フォルトは、セキュリティの脆弱性、セキュリティ以外の問題、または誤検出であるかどうかを判断するために調査されます。フォルトには、調査されるまで既知の脆弱性タイプはありません。脆弱性タイプの例は、SQLインジェクションとサービス拒否です。
- Profile: 設定ファイルには、1つ以上のテストプロファイル、またはサブ設定があります。フィーチャーブランチのプロファイルと、mainブランチの追加テストを含む別のプロファイルがある場合があります。
