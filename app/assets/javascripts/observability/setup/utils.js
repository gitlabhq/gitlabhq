export function extractHost(endpoint) {
  return endpoint.replace(/^https?:\/\//, '');
}

export function rubySnippet(endpoint) {
  // eslint-disable-next-line @gitlab/no-hardcoded-urls -- code snippet example, not a GitLab URL
  return `# Gemfile
gem 'opentelemetry-sdk'
gem 'opentelemetry-exporter-otlp'

# config/initializers/opentelemetry.rb
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

OpenTelemetry::SDK.configure do |c|
  c.resource = OpenTelemetry::SDK::Resources::Resource.create(
    'service.name'                => ENV['CI_PROJECT_NAME'] || 'my-service',
    'service.version'             => ENV['CI_COMMIT_SHA'],
    'deployment.environment.name' => ENV['CI_ENVIRONMENT_NAME'],
    'gitlab.project.id'           => ENV['CI_PROJECT_ID'],
    'gitlab.project.name'         => ENV['CI_PROJECT_NAME']
  )

  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: '${endpoint}/v1/traces'
      )
    )
  )
end`;
}

export function pythonSnippet(endpoint) {
  // eslint-disable-next-line @gitlab/no-hardcoded-urls -- code snippet example, not a GitLab URL
  return `# pip install opentelemetry-sdk opentelemetry-exporter-otlp
import os
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource

resource = Resource.create({
    "service.name": os.environ.get("CI_PROJECT_NAME", "my-service"),
    "service.version": os.environ.get("CI_COMMIT_SHA"),
    "deployment.environment.name": os.environ.get("CI_ENVIRONMENT_NAME"),
    "gitlab.project.id": os.environ.get("CI_PROJECT_ID"),
    "gitlab.project.name": os.environ.get("CI_PROJECT_NAME"),
})

provider = TracerProvider(resource=resource)
processor = BatchSpanProcessor(OTLPSpanExporter(
    endpoint="${endpoint}/v1/traces"
))
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)`;
}

export function goSnippet(endpoint) {
  const host = extractHost(endpoint);
  // eslint-disable-next-line @gitlab/no-hardcoded-urls -- code snippet example, not a GitLab URL
  return `// go get go.opentelemetry.io/otel/sdk
// go get go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp
package main

import (
\t"context"
\t"os"

\t"go.opentelemetry.io/otel"
\t"go.opentelemetry.io/otel/attribute"
\t"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
\t"go.opentelemetry.io/otel/sdk/resource"
\tsdktrace "go.opentelemetry.io/otel/sdk/trace"
\tsemconv "go.opentelemetry.io/otel/semconv/v1.24.0"
)

func initTracer() (*sdktrace.TracerProvider, error) {
\texporter, err := otlptracehttp.New(context.Background(),
\t\totlptracehttp.WithEndpoint("${host}"),
\t\totlptracehttp.WithURLPath("/v1/traces"),
\t)
\tif err != nil {
\t\treturn nil, err
\t}

\tres, _ := resource.New(context.Background(),
\t\tresource.WithAttributes(
\t\t\tsemconv.ServiceName(os.Getenv("CI_PROJECT_NAME")),
\t\t\tsemconv.ServiceVersion(os.Getenv("CI_COMMIT_SHA")),
\t\t\tsemconv.DeploymentEnvironmentName(os.Getenv("CI_ENVIRONMENT_NAME")),
\t\t\tattribute.String("gitlab.project.id", os.Getenv("CI_PROJECT_ID")),
\t\t\tattribute.String("gitlab.project.name", os.Getenv("CI_PROJECT_NAME")),
\t\t),
\t)

\ttp := sdktrace.NewTracerProvider(
\t\tsdktrace.WithBatcher(exporter),
\t\tsdktrace.WithResource(res),
\t)
\totel.SetTracerProvider(tp)
\treturn tp, nil
}`;
}

export function nodejsSnippet(endpoint) {
  // eslint-disable-next-line @gitlab/no-hardcoded-urls -- code snippet example, not a GitLab URL
  return `// npm install @opentelemetry/sdk-node @opentelemetry/exporter-trace-otlp-http
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { Resource } = require('@opentelemetry/resources');

const sdk = new NodeSDK({
  resource: new Resource({
    'service.name': process.env.CI_PROJECT_NAME || 'my-service',
    'service.version': process.env.CI_COMMIT_SHA,
    'deployment.environment.name': process.env.CI_ENVIRONMENT_NAME,
    'gitlab.project.id': process.env.CI_PROJECT_ID,
    'gitlab.project.name': process.env.CI_PROJECT_NAME,
  }),
  traceExporter: new OTLPTraceExporter({
    url: '${endpoint}/v1/traces',
  }),
});

sdk.start();`;
}

export function javaSnippet(endpoint) {
  // eslint-disable-next-line @gitlab/no-hardcoded-urls -- code snippet example, not a GitLab URL
  return `// build.gradle:
//   implementation 'io.opentelemetry:opentelemetry-sdk'
//   implementation 'io.opentelemetry:opentelemetry-exporter-otlp'

import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;
import io.opentelemetry.exporter.otlp.trace.OtlpHttpSpanExporter;
import io.opentelemetry.sdk.resources.Resource;
import io.opentelemetry.api.common.Attributes;

Resource resource = Resource.getDefault().merge(
    Resource.create(Attributes.builder()
        .put("service.name", System.getenv("CI_PROJECT_NAME"))
        .put("service.version", System.getenv("CI_COMMIT_SHA"))
        .put("deployment.environment.name", System.getenv("CI_ENVIRONMENT_NAME"))
        .put("gitlab.project.id", System.getenv("CI_PROJECT_ID"))
        .put("gitlab.project.name", System.getenv("CI_PROJECT_NAME"))
        .build())
);

SdkTracerProvider tracerProvider = SdkTracerProvider.builder()
    .addSpanProcessor(BatchSpanProcessor.builder(
        OtlpHttpSpanExporter.builder()
            .setEndpoint("${endpoint}/v1/traces")
            .build())
        .build())
    .setResource(resource)
    .build();

OpenTelemetrySdk.builder()
    .setTracerProvider(tracerProvider)
    .buildAndRegisterGlobal();`;
}

export function dotnetSnippet(endpoint) {
  // eslint-disable-next-line @gitlab/no-hardcoded-urls -- code snippet example, not a GitLab URL
  return `// dotnet add package OpenTelemetry.Exporter.OpenTelemetryProtocol
using OpenTelemetry;
using OpenTelemetry.Trace;
using OpenTelemetry.Resources;

var resourceBuilder = ResourceBuilder.CreateDefault()
    .AddService(
        serviceName: Environment.GetEnvironmentVariable("CI_PROJECT_NAME") ?? "my-service",
        serviceVersion: Environment.GetEnvironmentVariable("CI_COMMIT_SHA"))
    .AddAttributes(new Dictionary<string, object>
    {
        ["deployment.environment.name"] = Environment.GetEnvironmentVariable("CI_ENVIRONMENT_NAME") ?? "",
        ["gitlab.project.id"] = Environment.GetEnvironmentVariable("CI_PROJECT_ID") ?? "",
        ["gitlab.project.name"] = Environment.GetEnvironmentVariable("CI_PROJECT_NAME") ?? "",
    });

Sdk.CreateTracerProviderBuilder()
    .SetResourceBuilder(resourceBuilder)
    .AddOtlpExporter(opts =>
    {
        opts.Endpoint = new Uri("${endpoint}/v1/traces");
    })
    .Build();`;
}

const SNIPPET_GENERATORS = {
  ruby: rubySnippet,
  python: pythonSnippet,
  go: goSnippet,
  nodejs: nodejsSnippet,
  java: javaSnippet,
  dotnet: dotnetSnippet,
};

export function generateSnippet(key, endpoint) {
  return SNIPPET_GENERATORS[key]?.(endpoint) || '';
}
