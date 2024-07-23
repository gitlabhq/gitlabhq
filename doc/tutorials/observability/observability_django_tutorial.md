---
stage: Monitor
group: Observability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Tutorial: Use GitLab Observability with a Django application

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com
**Status:** Beta

> - Observability features [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124966) in GitLab 17.3 [with a flag](../../administration/feature_flags.md) named `observability_features`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

In this tutorial, we'll show you how to create, configure, instrument and monitor a Django application using GitLab observability features.

<!-- vale gitlab.SentenceSpacing = NO -->

## Before you begin

To follow along this tutorial, you should have:

- A GitLab Ultimate subscription for GitLab.com
- A local installation of Python 3 and Django (You can install it with `python -m pip install Django`.)
- Basic knowledge of Git and Python
- Basic knowledge of the core concepts of [OpenTelemetry](https://opentelemetry.io/)

## Create a GitLab project

First, create a GitLab project and a corresponding access token.
This tutorial uses the project name `animals`.

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create blank project**.
1. Enter the project details.
   - In the **Project name** field, enter `animals`.
1. Select **Create project**.
1. In the `animals` project, on the left sidebar, select **Settings > Access tokens**.
1. Create an access token with the Owner role and the `read_api` and `write_observability` scopes. Store the token value somewhere safe—you'll need it later.

## Create a Django application

To create an application:

1. From the command line, run the command:

   ```shell
   python -m django startproject animals_app
   ```

1. Check that the Django server is running correctly:

   ```shell
   python manage.py runserver
   ```

1. Ensure that the server is running correctly by visiting `http://localhost:8000`.
1. A Django projects contains multiple applications within a project. To create an application to manage our list of fake animals, run the command:

   ```shell
   python manage.py startapp animals
   ```

1. To create the initial view for the new `animals` application, in the `animals/views.py` file add the following code:

   ```python
   from django.http import HttpResponse

   def index(request):
       return HttpResponse("This is where the list of animals will be shown.")
   ```

1. In `animals/urls.py`, add the following code:

   ```python
   from django.urls import path
   from . import views

   urlpatterns = [
       path('', views.index, name='index'),
   ]
   ```

1. Additionally, update the room `urls.py` to include the `animals` app:

   ```python
   path('animals/', include('animals.urls'))
   ```

1. In `animals_app/settings.py`, add the application:

   ```python
   INSTALLED_APPS = [
       ...
       'animals.apps.AnimalsConfig',
   ]
   ```

1. In `animals/models.py`, create a model to define an animal:

   ```python
   from django.db import models
   class Animal(models.Model):
       name = models.CharField(max_length=200)
       number_of_legs = models.IntegerField(default=2)
       dangerous = models.BooleanField(default=False)
   ```

1. With the model defined, create a database migration. This will create a file that describes the changes to the database.

   ```shell
   python manage.py makemigrations animals
   ```

1. Run the newly created migration:

   ```shell
   python manage.py migrate
   ```

## Instrument the application with OpenTelemetry

1. Install the required dependencies:

   ```shell
   pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp-proto-http
   ```

1. Metrics and traces require different imports. In the `manage.py` file, import the required modules:

   ```python
   from opentelemetry.instrumentation.django import DjangoInstrumentor

   from opentelemetry.sdk.resources import SERVICE_NAME, Resource

   from opentelemetry import trace
   from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
   from opentelemetry.sdk.trace import TracerProvider
   from opentelemetry.sdk.trace.export import BatchSpanProcessor

   from opentelemetry import metrics
   from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter
   from opentelemetry.sdk.metrics import MeterProvider
   from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader, ConsoleMetricExporter
   ```

1. To instrument the application, in the `manage.py` file add the following code (replacing `{{PROJECT_ACCESS_TOKEN}}`, `{{NAMESPACE_ID}}`, and `{{PROJECT_ID}}` with the values from your project and root namespace):

   ```python
   resource = Resource(attributes={
       SERVICE_NAME: "animals-django"
   })
   os.environ.setdefault('OTEL_EXPORTER_OTLP_HEADERS', "PRIVATE-TOKEN={{PROJECT_ACCESS_TOKEN}}")
   traceProvider = TracerProvider(resource=resource)
   processor = BatchSpanProcessor(OTLPSpanExporter(endpoint="https://observe.gitlab.com/v3/{{NAMESPACE_ID}}/{{PROJECT_ID}}/ingest/traces"))
   traceProvider.add_span_processor(processor)
   trace.set_tracer_provider(traceProvider)

   reader = PeriodicExportingMetricReader(
       OTLPMetricExporter(endpoint="https://observe.gitlab.com/v3/{{NAMESPACE_ID}}/{{PROEJCT_ID}}/ingest/metrics")
   )
   meterProvider = MeterProvider(resource=resource, metric_readers=[reader])
   metrics.set_meter_provider(meterProvider)
   meter = metrics.get_meter("default.meter")

   """Run administrative tasks."""
   os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'animals_app.settings')
   DjangoInstrumentor().instrument()
   ```

  This code defines the service name `animals-django`, authenticates with GitLab, and instruments the application.

1. To start collecting traces, restart the Django server. After refreshing `/animals` a few times, you should see traces in the GitLab UI.

  ![Django traces](img/django_traces.png)

1. Optional. Django will also export certain metrics by default to GitLab, but custom metrics are supported too. For example, to increment a counter metric every time a page is loaded, add the following code:

   ```python
   meter = metrics.get_meter("default.meter")
    work_counter = meter.create_counter(
        "animals.viewed.counter", unit="1", description="Counts the number of times the list of animals was viewed"
    )

    work_counter.add(1)
   ```

  ![Django metrics](img/django_metrics.png)

<!-- vale gitlab.SentenceSpacing = YES -->
