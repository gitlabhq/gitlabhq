---
stage: Monitor
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Use GitLab Observability with a .NET application'
---

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history of the [**Distributed tracing** feature](../../development/tracing.md).
<!-- Update this note when observability_features flag is removed -->

In this tutorial, you'll learn how to create, configure, instrument, and monitor a .NET Core application using GitLab Observability features.

## Before you begin

To follow along this tutorial, you must have:

- A GitLab Ultimate subscription for GitLab.com or GitLab Self-Managed
- A local installation of [.NET](https://dotnet.microsoft.com/en-us/)
- Basic knowledge of Git, .NET, and the core concepts of [OpenTelemetry](https://opentelemetry.io/)

## Create a GitLab project

First, create a GitLab project and a corresponding access token.

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create blank project**.
1. Enter the project details.
   - In the **Project name** field, enter `dotnet-O11y-tutorial`.
1. Select **Create project**.
1. In the `dotnet-O11y-tutorial` project, on the left sidebar, select **Settings > Access tokens**.
1. Create an access token with the `api` scope and Developer role. Store the token value somewhere safe.
   You'll need it later.

## Create a .NET application

Next, we'll create a .NET web application that we can instrument. For this tutorial, let's create a toy application that returns animal emojis.

1. Clone the `dotnet-O11y-tutorial` project and `cd` to the `dotnet-O11y-tutorial` directory.
1. Create a web application by running:

   ```shell
   dotnet new web
   ```

1. Create an animal controller file by running the following:

   ```shell
   touch AnimalController.cs
   ```

1. Replace the contents of `AnimalController.cs` with the following:

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

1. In the `Properties` subdirectory, replace the contents of `launchSettings.json` with the following:

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

1. Replace the contents of `Program.cs` with the following:

   ```cs
   var builder = WebApplication.CreateBuilder(args);

   builder.Services.AddControllers();

   var app = builder.Build();

   app.MapControllers();

   app.Run();
   ```

1. Build and run the application:

   ```shell
   dotnet build
   dotnet run
   ```

1. Visit `http://localhost:8080/animals/dog`, and you should see the emoji 🐶.

## Instrument the application

1. Install the required OpenTelemetry packages:

   ```shell
   dotnet add package OpenTelemetry.Exporter.OpenTelemetryProtocol
   dotnet add package OpenTelemetry.Extensions.Hosting
   dotnet add package OpenTelemetry.Exporter.Console
   dotnet add package OpenTelemetry.Instrumentation.AspNetCore --prerelease
   dotnet add package OpenTelemetry.Instrumentation.Http --prerelease
   ```

1. Replace the contents of `Program.cs` with the following:

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

1. Find your project ID:
   1. On the `dotnet-O11y-tutorial` project overview page, in the upper-right corner, select **Actions** (**{ellipsis_v}**).
   1. Select **Copy project ID**. Save the copied ID for later.

1. Configure your application with instrumentation.
   If you're using GitLab Self-Managed, replace `gitlab.com` with your GitLab Self-Managed instance hostname.
1. Run your application.

   ```shell
   env OTEL_EXPORTER_OTLP_ENDPOINT="https://gitlab.com/api/v4/projects/{{PROJECT_ID}}/observability" \
   OTEL_EXPORTER_OTLP_HEADERS="PRIVATE-TOKEN={{ACCESS_TOKEN}}" \
   OTEL_LOG_LEVEL="debug" \
   dotnet run
   ```

1. Visit `http://localhost:8080/animals/dog` to generate some events.

## View the information in GitLab

To view the exported information from your test project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Monitor**, then either **Logs**, **Metrics**, or **Traces**.
