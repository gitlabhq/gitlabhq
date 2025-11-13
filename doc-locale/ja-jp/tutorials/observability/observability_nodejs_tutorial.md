---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: NodeJSアプリケーションでGitLab可観測性を使用する'
---

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。
<!-- Update this note when observability_features flag is removed -->

{{< /alert >}}

このチュートリアルでは、GitLab GitLab可観測性の機能を使用して、NodeJSアプリケーションを構成、計測、監視する方法を学びます。

## はじめる前 {#before-you-begin}

以下のものがあることを確認してください:

- GitLab.comまたはSelf-ManagedインスタンスのGitLab Ultimateサブスクリプション
- NodeJSのローカルインストール
- Git、NodeJS、JavaScript、および[OpenTelemetry](https://opentelemetry.io/)のコアコンセプトに関する基本的な知識

## 新しいGitLabプロジェクトを作成します {#create-a-new-gitlab-project}

まず、新しいGitLabプロジェクトと対応するアクセストークンを作成します。このチュートリアルでは、プロジェクト名`nodejs-O11y-tutorial`を使用します。

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **テンプレートから作成**を選択します。
1. NodeJS Expressの**テンプレートを使用**を選択します。
1. プロジェクトの詳細を入力してください。
   - **プロジェクト名**フィールドに、`nodejs-O11y-tutorial`を入力します。
1. **プロジェクトを作成**を選択します。
1. `nodejs-O11y-tutorial`プロジェクトの左側のサイドバーで、**設定** > **アクセストークン**を選択します。
1. `api`スコープとデベロッパーロールでアクセストークンを作成します。トークンの値は後で必要になるため、安全な場所に保管してください。

## NodeJSアプリケーションをインストルメント化する {#instrument-your-nodejs-application}

次に、NodeJSアプリケーションをインストルメント化する必要があります。

1. 以下を実行して、[NodeJS](https://nodejs.org/en)がインストールされていることを確認します:

   ```shell
   node -v
   ```

1. `nodejs-O11y-tutorial`プロジェクトをクローンし、`cd` `nodejs-O11y-tutorial`ディレクトリに移動します。
1. 以下を実行して依存関係をインストールします:

   ```shell
   npm install
   ```

1. アプリケーションを実行します:

   ```shell
   PORT=8080 node server.js
   ```

1. Webブラウザで`http://localhost:8080`にアクセスし、アプリケーションが正しく実行されていることを確認します。
1. OpenTelemetryパッケージを追加します:

   ```shell
   npm install --save @opentelemetry/api \
     @opentelemetry/auto-instrumentations-node
   ```

1. プロジェクトIDを見つけます:
   1. `nodejs-O11y-tutorial`プロジェクトの概要ページの右上隅で、**アクション**（{{< icon name="ellipsis_v" >}}）を選択します。
   1. **Copy project ID**（プロジェクトIDをコピー）を選択します。コピーしたIDを後で使用するために保存します。

1. インストルメンテーションを使用してプロジェクトを構成し、実行します:

   ```shell
   env OTEL_TRACES_EXPORTER="otlphttp" \
   OTEL_EXPORTER_OTLP_ENDPOINT="https://gitlab.com/api/v4/projects/{{PROJECT_ID}}/observability" \
   OTEL_EXPORTER_OTLP_HEADERS="PRIVATE-TOKEN={{ACCESS_TOKEN}}" \
   OTEL_SERVICE_NAME="nodejs-O11y-tutorial" \
   OTEL_LOG_LEVEL="debug" \
   NODE_OPTIONS="--require @opentelemetry/auto-instrumentations-node/register" \
   PORT=8080 node server.js
   ```

   `PROJECT_ID`と`ACCESS_TOKEN`を、先ほど取得した値に置き換えてください。GitLab Self-Managedインスタンスを使用している場合は、`gitlab.com`をGitLab Self-Managedインスタンスのホスト名に置き換えます。

## トレースを表示 {#view-traces}

可観測性トレーシングを使用するように構成されたアプリケーションがあるので、GitLab.comでエクスポートされたトレースを表示できます。

エクスポートされたトレースを表示するには:

1. インストルメンテーションを使用して、`nodejs-O11y-tutorial`アプリケーションを再度起動します。
1. `http://localhost:8080/`にアクセスし、アプリケーションでいくつかのアクションを実行します。
1. `nodejs-O11y-tutorial`プロジェクトの左側のサイドバーで、**モニタリング** > **トレース**を選択します。すべてが正しく動作している場合は、リクエストごとにトレースが表示されます。

   ![メトリクスのUI](img/nodejs_metrics_ui_v17_3.png)

1. オプション。トレースを選択して、そのスパンを表示します。

   ![トレースUI](img/nodejs_single_trace_v17_3.png)

おつかれさまでした。アプリケーションが正常に作成され、GitLab可観測性の機能を使用するように構成され、アプリケーションが作成したトレースが検証されました。このアプリケーションで実験を継続するか、より複雑なアプリケーションを構成してトレースをエクスポートしてみてください。

可観測性トレーシングはまだ本番環境での使用に対応していません。NodeJSアプリケーションでOpenTelemetryコレクターを使用して、ログまたはメトリクスの公式サポートはありません。
