---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: .NETアプリケーションでGitLab可観測性を使用する'
---

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。
<!-- Update this note when observability_features flag is removed -->

{{< /alert >}}

このチュートリアルでは、GitLab可観測性の機能を使用して、.NET Coreアプリケーションを作成、構成、インストルメント、および監視する方法を学習します。

## はじめる前 {#before-you-begin}

このチュートリアルを進めるには、以下が必要です:

- GitLab.comまたはSelf-ManagedインスタンスのGitLab Ultimateサブスクリプション
- [.NET](https://dotnet.microsoft.com/en-us/)のローカルインストール
- Git、.NET、および[OpenTelemetry](https://opentelemetry.io/)のコア概念に関する基本的な知識

## GitLabプロジェクトを作成 {#create-a-gitlab-project}

まず、GitLabプロジェクトと対応するアクセストークンを作成します。

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. プロジェクトの詳細を入力してください。
   - **プロジェクト名**フィールドに、`dotnet-O11y-tutorial`と入力します。
1. **プロジェクトを作成**を選択します。
1. `dotnet-O11y-tutorial`プロジェクトの左側のサイドバーで、**設定** > **アクセストークン**を選択します。
1. `api`スコープとデベロッパーロールでアクセストークンを作成します。トークンの値を安全な場所に保管してください。これは後で必要になります。

## .NETアプリケーションを作成 {#create-a-net-application}

次に、計測できる.NET Webアプリケーションを作成します。このチュートリアルでは、動物の絵文字を返すおもちゃのアプリケーションを作成しましょう。

1. `dotnet-O11y-tutorial`プロジェクトをクローンし、`cd`を`dotnet-O11y-tutorial`ディレクトリに移動します。
1. Webアプリケーションをビルドには、以下を実行します:

   ```shell
   dotnet new web
   ```

1. 次のコマンドを実行して、動物コントローラーファイルを作成します:

   ```shell
   touch AnimalController.cs
   ```

1. `AnimalController.cs`の内容を以下に置き換えます:

   ```cs
   using Microsoft.AspNetCore.Mvc;

   public class AnimalsController : ControllerBase
   {
       private Dictionary<string, string> animals = new Dictionary<string, string>
       {
           { "dog", "🐶" },
           { "cat", "🐱" },
           { "fish", "🐟" }
       };

       private ILogger<AnimalsController> logger;

       public AnimalsController(ILogger<AnimalsController> logger)
       {
           this.logger = logger;
       }

       [HttpGet("/animals/{animal}")]
       public IActionResult GetAnimal([FromRoute] string animal)
       {
           if (animals.TryGetValue(animal, out string? emoji))
           {
               logger.LogInformation("Animal emoji found for: {animal}", animal);
               return Ok(emoji);
           }
           else
           {
               logger.LogInformation("Could not find animal emoji for: {animal}", animal);
               return NotFound("Animal not found");
           }
       }
   }
   ```

1. `Properties`ディレクトリにある`launchSettings.json`の内容を以下に置き換えます:

   ```json
   {
     "$schema": "http://json.schemastore.org/launchsettings.json",
     "profiles": {
       "http": {
         "commandName": "Project",
         "dotnetRunMessages": true,
         "launchBrowser": true,
         "applicationUrl": "http://localhost:8080",
         "environmentVariables": {
           "ASPNETCORE_ENVIRONMENT": "Development"
         }
       }
     }
   }
   ```

1. `Program.cs`の内容を以下に置き換えます:

   ```cs
   var builder = WebApplication.CreateBuilder(args);

   builder.Services.AddControllers();

   var app = builder.Build();

   app.MapControllers();

   app.Run();
   ```

1. アプリケーションをビルドして実行します:

   ```shell
   dotnet build
   dotnet run
   ```

1. `http://localhost:8080/animals/dog`にアクセスすると、絵文字🐶が表示されます。

## アプリケーションをインストルメント化 {#instrument-the-application}

1. 必要なOpenTelemetryパッケージをインストールします:

   ```shell
   dotnet add package OpenTelemetry.Exporter.OpenTelemetryProtocol
   dotnet add package OpenTelemetry.Extensions.Hosting
   dotnet add package OpenTelemetry.Exporter.Console
   dotnet add package OpenTelemetry.Instrumentation.AspNetCore --prerelease
   dotnet add package OpenTelemetry.Instrumentation.Http --prerelease
   ```

1. `Program.cs`の内容を以下に置き換えます:

   ```cs
   using OpenTelemetry.Exporter;
   using OpenTelemetry.Logs;
   using OpenTelemetry.Metrics;
   using OpenTelemetry.Resources;
   using OpenTelemetry.Trace;

   var builder = WebApplication.CreateBuilder(args);

   const string serviceName = "dotnet-O11y-tutorial";

   string otelHeaders = Environment.GetEnvironmentVariable("OTEL_EXPORTER_OTLP_HEADERS") ?? "empty";
   string otelBaseUrl = Environment.GetEnvironmentVariable("OTEL_EXPORTER_OTLP_ENDPOINT") ?? "empty";

   builder.Services.AddOpenTelemetry()
       .ConfigureResource(resource => resource.AddService(serviceName))
       .WithTracing(tracing => tracing
           .AddSource(serviceName)
           .AddHttpClientInstrumentation()
           .AddAspNetCoreInstrumentation()
           .AddOtlpExporter(options =>
           {
               options.Endpoint = new Uri(otelBaseUrl + "/traces");
               options.Headers = otelHeaders;
               options.Protocol = OtlpExportProtocol.HttpProtobuf;
           }))
       .WithMetrics(metrics => metrics
           .AddMeter(serviceName)
           .AddHttpClientInstrumentation()
           .AddAspNetCoreInstrumentation()
           .AddOtlpExporter(options =>
           {
               options.Endpoint = new Uri(otelBaseUrl + "/metrics");
               options.Headers = otelHeaders;
               options.Protocol = OtlpExportProtocol.HttpProtobuf;
           }))
       .WithLogging(logging => logging
           .AddConsoleExporter()
           .AddOtlpExporter(options =>
           {
               options.Endpoint = new Uri(otelBaseUrl + "/logs");
               options.Headers = otelHeaders;
               options.Protocol = OtlpExportProtocol.HttpProtobuf;
           }));

   builder.Services.AddControllers();

   var app = builder.Build();

   app.MapControllers();

   app.Run();
   ```

1. プロジェクトIDを見つけます:
   1. `dotnet-O11y-tutorial`プロジェクトの概要ページの右上隅で、**アクション**（{{< icon name="ellipsis_v" >}}）を選択します。
   1. **Copy project ID**（プロジェクトIDをコピー）を選択します。コピーしたIDを後で使用するために保存します。

1. インストルメンテーションでアプリケーションを構成します。Self-Managedインスタンスを使用している場合は、`gitlab.com`をSelf-Managedインスタンスのホスト名に置き換えてください。
1. アプリケーションを実行します。

   ```shell
   env OTEL_EXPORTER_OTLP_ENDPOINT="https://gitlab.com/api/v4/projects/{{PROJECT_ID}}/observability" \
   OTEL_EXPORTER_OTLP_HEADERS="PRIVATE-TOKEN={{ACCESS_TOKEN}}" \
   OTEL_LOG_LEVEL="debug" \
   dotnet run
   ```

1. `http://localhost:8080/animals/dog`にアクセスして、いくつかのイベントを生成します。

## GitLabで情報を表示 {#view-the-information-in-gitlab}

テストプロジェクトからエクスポートされた情報を表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング**を選択し、次に**ログ**、**メトリクス**、または**トレース**を選択します。
