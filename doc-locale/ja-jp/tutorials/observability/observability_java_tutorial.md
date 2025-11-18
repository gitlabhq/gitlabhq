---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: Java SpringアプリケーションでGitLab可観測性を使用する'
---

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。
<!-- Update this note when observability_features flag is removed -->

{{< /alert >}}

このチュートリアルでは、GitLab可観測性Java Springアプリケーションを作成、設定、インストルメント、および監視する方法を学習します。

## はじめる前 {#before-you-begin}

このチュートリアルを進めるには、以下が必要です:

- GitLab.comまたはSelf-ManagedインスタンスGitLab Ultimateサブスクリプション
- Ruby on Railsのローカルインストール
- Git、Spring、および[OpenTelemetry](https://opentelemetry.io/)のコア概念に関する基本的な知識

## GitLabプロジェクトを作成します {#create-a-gitlab-project}

まず、GitLabプロジェクトと対応するアクセストークンを作成します。

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **テンプレートから作成**を選択します。
1. **Spring**を選択し、次に**テンプレートを使用**を選択します。
1. プロジェクトの詳細を入力します。
   - **プロジェクト名**フィールドに、`test-spring-o11y`などの名前を入力します。
1. **プロジェクトを作成**を選択します。
1. `test-sprint-o11y`プロジェクトの左側のサイドバーで、**設定** > **アクセストークン**を選択します。
1. `api`スコープとデベロッパーロールでアクセストークンを作成します。トークンの値を安全な場所に保管してください。これは後で必要になります。

## アプリケーションを実行する {#run-the-application}

次に、アプリケーションが動作することを確認するために、アプリケーションを実行します。

1. GitLabからプロジェクトをクローンした後、IntelliJ（またはお好みのIDE）で開きます。
1. `src/main/java/com.example.demo/DemoApplication`を開き、アプリケーションを実行します:

   ![アプリケーションのスクリーンショットを実行](img/java_start_application_v17_3.png)

1. 初期化後、アプリケーションは`http://localhost:8000`で使用可能になります。それをテストし、IDEで**停止**ボタンを選択します。

## OpenTelemetry依存関係を追加します {#add-the-opentelemetry-dependencies}

自動インストルメンテーションを使用してアプリケーションをインストルメントします:

1. `pom.xml`ファイルで、必要な依存関係を追加します:

   ```xml
   <dependency>
       <groupId>io.opentelemetry</groupId>
       <artifactId>opentelemetry-api</artifactId>
   </dependency>
   <dependency>
       <groupId>io.opentelemetry</groupId>
       <artifactId>opentelemetry-sdk-extension-autoconfigure</artifactId>
   </dependency>
   <dependency>
       <groupId>io.opentelemetry</groupId>
       <artifactId>opentelemetry-sdk-extension-autoconfigure-spi</artifactId>
   </dependency>
   ```

   ```xml
   <dependencyManagement>
       <dependencies>
           <dependency>
               <groupId>io.opentelemetry</groupId>
               <artifactId>opentelemetry-bom</artifactId>
               <version>1.40.0</version>
               <type>pom</type>
               <scope>import</scope>
           </dependency>
       </dependencies>
   </dependencyManagement>
   ```

1. **Update Maven Changes**（Mavenの変更を更新）を選択して、依存関係を更新します:

   ![Mavenの変更アップデートUI](img/maven_changes_v17_3.png)

1. OpenTelemetryリポジトリからOpenTelemetry Javaエージェントファイルをダウンロードします。

   ```shell
   curl --location --http1.0 "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar"
   ```

## 環境変数を定義する {#define-environment-variables}

OpenTelemetry自動設定ライブラリは、環境変数から設定を読み取ります。

1. 右上隅のメニューから、**Edit Configurations**（構成の編集）を選択します:

   ![構成の編集](img/java_edit_configuration_v17_3.png)

1. 構成メニューで、**Environment Variables**（環境変数）フィールドのアイコンを選択します。

   ![構成メニュー](img/java_configuration_menu_v17_3.png)

1. 次の環境変数のセットを追加し、`{{PATH_TO_JAVA_AGENT}}`、`{{PROJECT_ID}}`、`{{PROJECT_ACCESS_TOKEN}}`、および`{{SERVICE_NAME}}`を正しい値に置き換えます。GitLab Self-Managedインスタンスを使用している場合は、`gitlab.com`をGitLab Self-Managedインスタンスのインスタンスホスト名に置き換えます。
   - `JAVA_TOOL_OPTIONS=-javaagent:{{PATH_TO_JAVA_AGENT}}/opentelemetry-javaagent.jar`
   - `OTEL_EXPORTER_OTLP_ENDPOINT=https://gitlab.com/api/v4/projects/{{PROJECT_ID}}/observability`
   - `OTEL_EXPORTER_OTLP_HEADERS=PRIVATE-TOKEN\={{PROJECT_ACCESS_TOKEN}}`
   - `OTEL_EXPORTER=otlphttp`
   - `OTEL_METRIC_EXPORT_INTERVAL=15000`
   - `OTEL_SERVICE_NAME=example-java-application`

1. アプリケーションを再起動し、`http://localhost:8000`でページを数回リロードします。

## GitLabで情報を表示します {#view-the-information-in-gitlab}

テストプロジェクトからエクスポートされた情報を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング**、**ログ**、**メトリクス**、または**トレース**のいずれかを選択します。
