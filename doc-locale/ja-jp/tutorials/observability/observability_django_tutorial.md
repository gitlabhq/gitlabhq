---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: DjangoアプリケーションでGitLab可観測性を使用する'
---

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。
<!-- Update this note when observability_features flag is removed -->

{{< /alert >}}

このチュートリアルでは、GitLab可観測性の機能を使用してDjangoアプリケーションを作成、設定、インストルメント、および監視する方法を説明します。

<!-- vale gitlab_base.SentenceSpacing = NO -->
<!-- vale gitlab_base.FutureTense = NO -->

## はじめる前 {#before-you-begin}

このチュートリアルを進めるには、以下が必要です:

- GitLab.comまたはSelf-ManagedインスタンスのGitLab Ultimateサブスクリプション
- Python 3とDjangoのローカルインスタンス（`python -m pip install Django`でインストールできます）。
- GitとPythonの基本的な知識
- [OpenTelemetry](https://opentelemetry.io/)のコアコンセプトの基本的な知識

## GitLabプロジェクトを作成する {#create-a-gitlab-project}

まず、GitLabプロジェクトと対応するアクセストークンを作成します。このチュートリアルでは、`animals`というプロジェクト名を使用します。

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。
1. **空のプロジェクトの作成**を選択します。
1. プロジェクトの詳細を入力してください。
   - **プロジェクト名**フィールドに、`animals`と入力します。
1. **プロジェクトを作成**を選択します。
1. `animals`プロジェクトの左側のサイドバーで、**設定** > **アクセストークン**を選択します。
1. `api`スコープとデベロッパーロールを持つアクセストークンを作成します。後で必要になるため、トークンの値を安全な場所に保管してください。

## Djangoアプリケーションを作成する {#create-a-django-application}

アプリケーションを作成するには:

1. コマンドラインから、次のコマンドを実行します:

   ```shell
   python -m django startproject animals_app
   ```

1. Djangoサーバーが正しく実行されていることを確認します:

   ```shell
   python manage.py runserver
   ```

1. `http://localhost:8000`にアクセスして、サーバーが正しく実行されていることを確認します。
1. Djangoプロジェクトには、プロジェクト内に複数のアプリケーションが含まれています。偽の動物のリストを管理するアプリケーションを作成するには、次のコマンドを実行します:

   ```shell
   python manage.py startapp animals
   ```

1. 新しい`animals`アプリケーションの初期ビューを作成するには、`animals/views.py`ファイルに次のコードを追加します:

   ```python
   from django.http import HttpResponse

   def index(request):
       return HttpResponse("This is where the list of animals will be shown.")
   ```

1. `animals/urls.py`に、次のコードを追加します:

   ```python
   from django.urls import path
   from . import views

   urlpatterns = [
       path('', views.index, name='index'),
   ]
   ```

1. さらに、room `urls.py`を更新して、`animals`アプリを含めます:

   ```python
   path('animals/', include('animals.urls'))
   ```

1. `animals_app/settings.py`で、アプリケーションを追加します:

   ```python
   INSTALLED_APPS = [
       ...
       'animals.apps.AnimalsConfig',
   ]
   ```

1. `animals/models.py`で、動物を定義するモデルを作成します:

   ```python
   from django.db import models
   class Animal(models.Model):
       name = models.CharField(max_length=200)
       number_of_legs = models.IntegerField(default=2)
       dangerous = models.BooleanField(default=False)
   ```

1. モデルを定義したら、データベースの移行を作成します。これにより、データベースへの変更を記述するファイルが作成されます。

   ```shell
   python manage.py makemigrations animals
   ```

1. 新しく作成された移行を実行します:

   ```shell
   python manage.py migrate
   ```

## OpenTelemetryでアプリケーションをインストルメント化する {#instrument-the-application-with-opentelemetry}

1. 必要な依存関係をインストールします:

   ```shell
   pip install opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp-proto-http
   ```

1. メトリクスとトレーシングには、異なるインポートが必要です。`manage.py`ファイルで、必要なモジュールをインポートします:

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

1. アプリケーションをインストルメント化するには、`manage.py`ファイルに次のコードを追加します。
   - `{{PROJECT_ACCESS_TOKEN}}`と`{{PROJECT_ID}}`を、プロジェクトの値に置き換えます。
   - Self-Managedインスタンスを使用している場合は、`gitlab.com`をSelf-Managedインスタンスのホスト名に置き換えます。

   ```python
   resource = Resource(attributes={
       SERVICE_NAME: "animals-django"
   })
   os.environ.setdefault('OTEL_EXPORTER_OTLP_HEADERS', "PRIVATE-TOKEN={{PROJECT_ACCESS_TOKEN}}")
   traceProvider = TracerProvider(resource=resource)
   processor = BatchSpanProcessor(OTLPSpanExporter(endpoint="https://gitlab.com/api/v4/projects/{{PROJECT_ID}}/observability/v1/traces"))
   traceProvider.add_span_processor(processor)
   trace.set_tracer_provider(traceProvider)

   reader = PeriodicExportingMetricReader(
       OTLPMetricExporter(endpoint="https://gitlab.com/api/v4/projects/{{PROJECT_ID}}/observability/v1/metrics")
   )
   meterProvider = MeterProvider(resource=resource, metric_readers=[reader])
   metrics.set_meter_provider(meterProvider)
   meter = metrics.get_meter("default.meter")

   """Run administrative tasks."""
   os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'animals_app.settings')
   DjangoInstrumentor().instrument()
   ```

  このコードは、サービス名`animals-django`を定義し、GitLabで認証し、アプリケーションをインストルメント化します。

1. トレーシングの収集を開始するには、Djangoサーバーを再起動します。`/animals`を数回更新すると、GitLab UIにトレーシングが表示されます。

   ![Djangoトレース](img/django_traces_v17_3.png)

1. オプション。Djangoはまた、特定のメトリクスをデフォルトでGitLabにエクスポートしますが、カスタムメトリクスもサポートされています。たとえば、ページが読み込むたびにカウンタメトリクスをインクリメントするには、次のコードを追加します:

   ```python
   meter = metrics.get_meter("default.meter")
    work_counter = meter.create_counter(
        "animals.viewed.counter", unit="1", description="Counts the number of times the list of animals was viewed"
    )

    work_counter.add(1)
   ```

  ![Djangoメトリクス](img/django_metrics_v17_3.png)

<!-- vale gitlab_base.SentenceSpacing = YES -->
