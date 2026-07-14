---
stage: Application Security Testing
group: Dynamic Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: APIディスカバリ
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/groups/gitlab-org/-/epics/9302)されました。API Discovery機能は[ベータ](../../../../policy/development_stages_support.md)版です。

{{< /history >}}

API Discoveryはアプリケーションを分析し、公開するWeb APIを記述したOpenAPIドキュメントを生成します。このスキーマドキュメントは、Web APIのセキュリティスキャンを実行するために、[APIセキュリティテストアナライザー](../../api_security_testing/_index.md)または[APIファジング](../../api_fuzzing/_index.md)で使用できます。

## サポートされているフレームワーク {#supported-frameworks}

- [Java Spring-Boot](#java-spring-boot)

## API Discoveryはいつ実行されますか？ {#when-does-api-discovery-run}

API Discoveryは、パイプライン内でスタンドアロンのジョブとして実行されます。結果のOpenAPIドキュメントはジョブアーティファクトとしてキャプチャされるため、以降のパイプラインステージの他のジョブで使用できます。

API Discoveryは、`test`パイプラインステージでデフォルトで実行されます。`test`パイプラインステージは、通常、APIセキュリティテストやAPIファジングなどの他のセキュリティ機能で使用されるパイプラインステージの前に実行されるため、選択されました。

## API Discoveryの設定例 {#example-api-discovery-configurations}

以下のプロジェクトがAPI Discoveryを示しています:

- [Java Spring Boot v2 Pet Storeの例](https://gitlab.com/gitlab-org/security-products/demos/api-discovery/java-spring-boot-v2-petstore)

## Java Spring-Boot {#java-spring-boot}

[Spring Boot](https://spring.io/projects/spring-boot/)は、スタンドアロンのプロダクション対応のSpringベースアプリケーションを作成するための一般的なフレームワークです。

### サポートされているアプリケーション {#supported-applications}

- Spring Boot: v2.X (>= 2.1)
- Java: 11、17 (LTSバージョン)
- 実行可能JAR

API Discoveryは、Spring Bootのメジャーバージョン2、マイナーバージョン1以降をサポートしています。バージョン2.0.Xは、API Discoveryに影響を与える既知のバグがあり、2.1で修正されたため、サポートされていません。

メジャーバージョン3は将来的にサポートされる予定です。メジャーバージョン1のサポートは予定されていません。

API Discoveryは、JavaランタイムのLTSバージョンでテストされ、公式にサポートされています。他のバージョンでも動作する可能性があり、非LTSバージョンからのバグ報告も歓迎します。

Spring Boot [実行可能JAR](https://docs.spring.io/spring-boot/redirect.html?page=executable-jar#appendix.executable-jar.nested-jars.jar-structure)としてビルドされたアプリケーションのみがサポートされています。

### パイプラインジョブとして設定 {#configure-as-pipeline-job}

API Discoveryを実行する最も簡単な方法は、当社のCIテンプレートに基づくパイプラインジョブを使用することです。この方法で実行する場合、必要な依存関係がインストールされたコンテナイメージ（適切なJavaランタイムなど）を提供します。詳細については、[Image Requirements](#image-requirements)を参照してください。

1. [image requirements](#image-requirements)を満たすコンテナイメージがレジストリにアップロードされます。コンテナレジストリで認証が必要な場合は、[このヘルプセクション](../../../../ci/docker/using_docker_images.md#access-an-image-from-a-private-container-registry)を参照してください。
1. `build`パイプラインステージのジョブで、アプリケーションをビルドし、結果のSpring Boot実行可能JARをジョブアーティファクトとして設定します。
1. API Discoveryテンプレートを`.gitlab-ci.yml`ファイルに含めます。

   ```yaml
   include:
      - template: Security/API-Discovery.gitlab-ci.yml
   ```

   `include`ステートメントは`.gitlab-ci.yml`ファイルごとに1つのみ許可されます。他のファイルを含める場合は、単一の`include`ステートメントに結合してください。

   ```yaml
   include:
      - template: Security/API-Discovery.gitlab-ci.yml
      - template: Security/DAST-API.gitlab-ci.yml
   ```

1. `.api_discovery_java_spring_boot`から拡張する新しいジョブを作成します。デフォルトのパイプラインステージは`test`であり、オプションで任意の値に変更できます。

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
   ```

1. ジョブの`image`を設定します。

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
   ```

1. アプリケーションに必要なJavaクラスパスを提供します。これには、ステップ2からの互換性のあるビルドアーティファクトと、追加の依存関係が含まれます。この例では、ビルドアーティファクトは`build/libs/spring-boot-app-0.0.0.jar`であり、必要なすべての依存関係を含んでいます。変数`API_DISCOVERY_JAVA_CLASSPATH`はクラスパスを提供するために使用されます。

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
   ```

1. オプション。提供されたイメージにAPI Discoveryに必要な依存関係がない場合、`before_script`を使用して追加できます。この例では、`eclipse-temurin:17-jre-alpine`コンテナにはAPI Discoveryで必要な`curl`が含まれていません。依存関係はDebianパッケージマネージャー`apt`を使用してインストールできます:

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
       before_script:
           - apk add --no-cache curl
   ```

1. オプション。提供されたイメージが自動的に`JAVA_HOME`環境変数を設定しない場合、またはパスに`java`を含めない場合、`API_DISCOVERY_JAVA_HOME`変数を使用できます。

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
           API_DISCOVERY_JAVA_HOME: /opt/java
   ```

1. オプション。`API_DISCOVERY_PACKAGES`のパッケージレジストリが公開されていない場合、`API_DISCOVERY_PACKAGE_TOKEN`変数を使用してGitLab APIとレジストリへの読み取りアクセス権を持つトークンを提供します。これは、`gitlab.com`を使用しており、`API_DISCOVERY_PACKAGES`変数をカスタマイズしていない場合は必要ありません。次の例では、`GITLAB_READ_TOKEN`という名前の[カスタムCI/CD変数](../../../../ci/variables/_index.md#define-a-cicd-variable-in-the-ui)を使用してトークンを保存します。

   ```yaml
   api_discovery:
       extends: .api_discovery_java_spring_boot
       image: eclipse-temurin:17-jre-alpine
       variables:
           API_DISCOVERY_JAVA_CLASSPATH: build/libs/spring-boot-app-0.0.0.jar
           API_DISCOVERY_PACKAGE_TOKEN: $GITLAB_READ_TOKEN
   ```

API Discoveryジョブが正常に実行されると、OpenAPIドキュメントは`gl-api-discovery-openapi.json`というジョブアーティファクトとして利用可能になります。

#### イメージの要件 {#image-requirements}

- Linuxコンテナイメージ。
- Javaバージョン11または17が正式にサポートされていますが、他のバージョンも互換性がある可能性が高いです。
- `curl`コマンド。
- `/bin/sh`のShell（`busybox`、`sh`、または`bash`など）。

### 利用可能なCI/CD変数 {#available-cicd-variables}

| CI/CD変数                              | 説明        |
|---------------------------------------------|--------------------|
| `API_DISCOVERY_DISABLED`                    | テンプレートジョブルールを使用している場合、API Discoveryジョブを無効にします。 |
| `API_DISCOVERY_DISABLED_FOR_DEFAULT_BRANCH` | テンプレートジョブルールを使用している場合、デフォルトブランチパイプラインのAPI Discoveryジョブを無効にします。 |
| `API_DISCOVERY_JAVA_CLASSPATH`              | ターゲットSpring Bootアプリケーションを含むJavaクラスパス。（`build/libs/sample-0.0.0.jar`） |
| `API_DISCOVERY_JAVA_HOME`                   | 提供された場合、`JAVA_HOME`を設定するために使用されます。 |
| `API_DISCOVERY_PACKAGES`                    | GitLabプロジェクトパッケージAPIプレフィックス（デフォルトは`$CI_API_V4_URL/projects/42503323/packages`）。 |
| `API_DISCOVERY_PACKAGE_TOKEN`               | GitLabパッケージAPIを呼び出すためのGitLabトークン。`API_DISCOVERY_PACKAGES`が非公開プロジェクトに設定されている場合にのみ必要です。 |
| `API_DISCOVERY_VERSION`                     | 使用するAPI Discoveryバージョン（デフォルトは`1`）。完全なバージョン番号`1.1.0`を指定することで、バージョンを固定するために使用できます。 |

## サポートを受けるか、改善をリクエストする {#get-support-or-request-an-improvement}

特定の問題のサポートを受けるには、[ヘルプチャンネルの利用](https://about.gitlab.com/get-help/)をご利用ください。

GitLab.com上の[GitLabイシュートラッカー](https://gitlab.com/gitlab-org/gitlab/-/issues)は、API Discoveryに関するバグや機能提案に最適な場所です。API Discoveryに関する新しいイシューを開く際に`~"Category:API Security"`ラベルを使用すると、適切な担当者によって迅速にレビューされます。

ご自身で提出する前に、[イシュートラッカーを検索](https://gitlab.com/gitlab-org/gitlab/-/issues)して類似のエントリがないか確認してください。他の誰かが同じイシューまたは機能提案をしていた可能性が高いです。絵文字リアクションでサポートを示すか、ディスカッションに参加してください。

期待通りに動作しない動作が発生した場合は、次のコンテキスト情報を提供することを検討してください:

- GitLab Self-Managedインスタンスを使用している場合のGitLabバージョン。
- `.gitlab-ci.yml`ジョブ定義。
- 完全なジョブコンソール出力。
- 使用中のフレームワークとそのバージョン（例：「Spring Boot v2.3.2」）。
- 言語ランタイムとそのバージョン（例：「Eclipse Temurin v17.0.1」）。

<!-- - Scanner log file is available as a job artifact named `gl-api-discovery.log`. -->

> [!warning]
> **サポートイシューに添付するデータはサニタイズしてください**。機密情報（認証情報、パスワード、トークン、キー、シークレットなど）を削除してください。
