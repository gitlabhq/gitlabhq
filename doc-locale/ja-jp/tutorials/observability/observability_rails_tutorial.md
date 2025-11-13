---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: Ruby on RailsアプリケーションでGitLab可観測性を使用する'
---

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。
<!-- Update this note when observability_features flag is removed -->

{{< /alert >}}

このチュートリアルでは、GitLab可観測性機能を使用して、Ruby on Railsアプリケーションを作成、設定、インストルメント、および監視する方法を学習します。

## はじめる前 {#before-you-begin}

まず、以下を確認してください:

- GitLab.comまたはSelf-ManagedインスタンスのGitLab Ultimateサブスクリプション
- Ruby on Railsのローカルインストール
- Git、Ruby on Rails、および[OpenTelemetry](https://opentelemetry.io/)のコアコンセプトに関する基本的な知識

## 新しいGitLabプロジェクトを作成 {#create-a-new-gitlab-project}

まず、新しいGitLabプロジェクトと対応するアクセストークンを作成します。このチュートリアルでは、プロジェクト名`animals`を使用します。

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. プロジェクトの詳細を入力します。
   - **プロジェクト名**フィールドに`animals`と入力します。
1. **プロジェクトを作成**を選択します。
1. `animals`プロジェクトの左側のサイドバーで、**設定** > **アクセストークン**を選択します。
1. `api`スコープとデベロッパーロールでアクセストークンを作成します。トークンの値は後で必要になるため、安全な場所に保管してください。

## Railsアプリケーションを作成 {#create-a-rails-application}

次に、インストルメントできる新しいRuby on Railsアプリケーションが必要です。このチュートリアルでは、動物のリストを保存するための簡単なアプリケーションを作成しましょう。

アプリケーションを作成するには:

1. コマンドラインから、以下を実行します:

   ```shell
   rails new animals
   ```

1. `animals`ディレクトリに移動し、アプリケーションを実行します:

   ```shell
   cd animals
   rails server -p 8080
   ```

1. Webブラウザで`http://localhost:8080`にアクセスし、アプリケーションが正しく実行されていることを確認してください。
1. Animalクラスのモデルスキャフォールドを作成し、生成されたデータベース移行を実行します:

   ```shell
   rails generate scaffold Animal species:string number_of_legs:integer dangerous:boolean
   rails db:migrate
   ```

1. アプリケーションを再度実行し、`http://localhost:8080/animals`で動物のリストにアクセスします。動物を作成、編集、削除して、すべてが期待どおりに機能することを確認してください。
1. OpenTelemetry gemとdotenv gemをGemfileに追加します:

   ```shell
   bundle add opentelemetry-sdk opentelemetry-instrumentation-all opentelemetry-exporter-otlp dotenv
   ```

1. 設定を処理する初期化子を作成し、環境変数を格納するための`.env`ファイルを追加します:

   ```shell
   touch config/initializers/opentelemetry.rb
   touch .env
   ```

1. `config/initializers/opentelemetry.rb`を編集し、次のコードを追加します:

   ```ruby
   require 'opentelemetry/sdk'
   require 'opentelemetry/instrumentation/all'
   require 'opentelemetry-exporter-otlp'

   OpenTelemetry::SDK.configure do |c|
     c.service_name = 'animals-rails'
     c.use_all()
   end
   ```

1. プロジェクトIDを見つけます:
   1. `animal`プロジェクトの概要ページの右上隅にある**アクション**（{{< icon name="ellipsis_v" >}}）を選択します。
   1. **Copy project ID**（プロジェクトIDをコピー）を選択します。コピーしたIDを後で使用するために保存します。

1. `.env`を編集し、次のコードを追加します:

   ```shell
   OTEL_EXPORTER = "otlphttp"
   OTEL_EXPORTER_OTLP_ENDPOINT = "https://gitlab.com/api/v4/projects/{{PROJECT_ID}}/observability"
   OTEL_EXPORTER_OTLP_HEADERS = "PRIVATE-TOKEN={{ACCESS_TOKEN}}"
   OTEL_LOG_LEVEL = "debug"
   ```

   必ず`PROJECT_ID`と`ACCESS_TOKEN`を、以前に取得した値に置き換えてください。Self-Managedインスタンスを使用している場合は、`gitlab.com`をGitLab Self-Managedインスタンスのホスト名に置き換えます。

## トレースを表示 {#view-traces}

GitLab可観測性トレーシングを使用するように設定されたアプリケーションがあるため、GitLab.comでエクスポートされたトレースを表示できます。

エクスポートされたトレースを表示するには:

1. `animals`アプリケーションを再度起動します。
1. `http://localhost:8080/animals`にアクセスし、アプリケーションでいくつかのアクションを実行します。
1. `animals`プロジェクトの左側のサイドバーで、**モニタリング** > **トレース**を選択します。すべてが正しく動作している場合は、各コントローラーアクションのトレースが表示されます。

   ![メトリクスUI](img/rails_metrics_ui_v17_3.png)

1. オプション。トレースを選択して、そのスパンを表示します。

   ![トレースUI](img/rails_single_trace_v17_3.png)

おつかれさまでした。アプリケーションが正常に作成され、GitLab可観測性機能を使用するように設定され、アプリケーションが作成したトレースが検査されました。この簡単なアプリケーションで引き続き実験するか、より複雑なアプリケーションを設定してトレースをエクスポートしてみてください。

可観測性トレーシングはまだ本番環境での使用に対応していません。Ruby on RailsアプリケーションでOpenTelemetryコレクターを使用するログまたはメトリクスに対する公式サポートはありません。
