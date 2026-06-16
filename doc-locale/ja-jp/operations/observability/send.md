---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: アプリケーションのパフォーマンスをモニタリングし、パフォーマンスに関するイシューをトラブルシューティングを行う。
ignore_in_report: true
title: GitLab可観測性にテレメトリデータを送信する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

可観測性を設定したら、データをGitLabに送信できます。

開始するには、[CI/CDパイプラインデータ](ci_cd.md)を表示するか、[テストデータを送信](#send-test-data)するか、[テンプレートを使用](#gitlab-observability-templates)してください。

## 可観測性データを表示 {#view-observability-data}

GitLab可観測性の設定後:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**可観測性** > **サービス**を選択します。
1. 詳細を表示するサービスを選択します。

![GitLab.com可観測性ダッシュボード](img/gitLab_o11y_gitlab_com_dashboard_v18_1.png "GitLab.com可観測性ダッシュボード")

## アプリケーションをインスツルメントする {#instrument-your-application}

アプリケーションにOpenTelemetryインストゥルメンテーションを追加するには:

1. ご使用の言語用のOpenTelemetry SDKを追加します。
1. OTLP exporterをGitLab可観測性インスタンスに指定するように設定します。
1. 推奨されるリソース属性を設定します。
1. スパンと属性を追加して、操作とメタデータを追跡します。

言語固有のガイドラインについては、[OpenTelemetryドキュメント](https://opentelemetry.io/docs/instrumentation/)を参照してください。

### 推奨されるリソース属性 {#recommended-resource-attributes}

これらのリソース属性を使用してOpenTelemetry SDKを設定し、テレメトリーデータをGitLabプロジェクトとコードにリンクします。これにより、トレースとコミットの関連付けや、例外からの自動イシュー作成などの機能が有効になります。

| リソース属性 | GitLab CI/CD変数 | 説明 |
| --- | --- | --- |
| `gitlab.project.id` | `CI_PROJECT_ID` | テレメトリーをGitLabプロジェクトにリンクします。GitLab Duoインテグレーションに必要です。 |
| `gitlab.project.name` | `CI_PROJECT_NAME` | ダッシュボードに表示するための人間が判読できるプロジェクト名。 |
| `service.version` | `CI_COMMIT_SHA` | 実行中のコードのコミットSHA。トレースとエラーをデプロイされた正確なバージョンに関連付けることができます。 |
| `deployment.environment.name` | `CI_ENVIRONMENT_NAME` | コードが実行されている環境（たとえば、`production`または`staging`）。 |

`service.version`および`deployment.environment.name`は、[OpenTelemetryのセマンティック規約](https://opentelemetry.io/docs/specs/semconv/resource/)です。`gitlab.*`の属性は、GitLab固有のコンテキストにベンダーネームスペースを使用します。

これら4つの変数はすべて、[GitLab CI/CDで事前定義されており](../../ci/variables/predefined_variables.md)、アプリケーションがパイプラインで実行される場合でも、追加の設定は不要です。ローカル開発の場合、これらの環境変数を手動で設定するか、空のデフォルトを受け入れます。

次のRubyの例は、これらの属性を設定する方法を示しています:

```ruby
OpenTelemetry::SDK.configure do |c|
  c.resource = OpenTelemetry::SDK::Resources::Resource.create(
    'gitlab.project.id'           => ENV.fetch('CI_PROJECT_ID', ''),
    'gitlab.project.name'         => ENV.fetch('CI_PROJECT_NAME', ''),
    'service.version'             => ENV.fetch('CI_COMMIT_SHA', ''),
    'deployment.environment.name' => ENV.fetch('CI_ENVIRONMENT_NAME', '')
  )

  c.use_all
end
```

他の言語の場合は、その言語のOpenTelemetry SDKを使用して同じリソース属性を設定します。属性名と環境変数は、すべての言語で同一です。

## テストデータを送信 {#send-test-data}

OpenTelemetry SDKを使用してサンプルテレメトリーデータを送信することで、GitLab可観測性のインストールをテストできます。この例ではRubyを使用していますが、OpenTelemetryには[多くの言語用のSDK](https://opentelemetry.io/docs/instrumentation/)があります。

### 前提条件 {#prerequisites}

- ローカルマシンにRubyがインストールされていること。
- 必要なgem:

  ```shell
  gem install opentelemetry-sdk opentelemetry-exporter-otlp
  ```

### 基本的なテストスクリプトを作成 {#create-a-basic-test-script}

`test_o11y.rb`という名前のファイルに、次のコンテンツを作成します:

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

OpenTelemetry::SDK.configure do |c|
  # Define service information
  resource = OpenTelemetry::SDK::Resources::Resource.create({
    'service.name' => 'test-service',
    'service.version' => '1.0.0',
    'deployment.environment.name' => 'production',
    'gitlab.project.id' => ENV.fetch('CI_PROJECT_ID', ''),
    'gitlab.project.name' => ENV.fetch('CI_PROJECT_NAME', '')
  })
  c.resource = resource

  # Configure OTLP exporter to send to GitLab Observability
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: 'http://[your-o11y-instance-ip]:4318/v1/traces'
      )
    )
  )
end

# Get tracer and create spans
tracer = OpenTelemetry.tracer_provider.tracer('basic-demo')

# Create parent span
tracer.in_span('parent-operation') do |parent|
  parent.set_attribute('custom.attribute', 'test-value')
  puts "Created parent span: #{parent.context.hex_span_id}"

  # Create child span
  tracer.in_span('child-operation') do |child|
    child.set_attribute('custom.child', 'child-value')
    puts "Created child span: #{child.context.hex_span_id}"
    sleep(1)
  end
end

puts "Waiting for export..."
sleep(5)
puts "Done!"
```

`[your-o11y-instance-ip]`をGitLab可観測性インスタンスのIPアドレスまたはホスト名に置き換えます。

### テストを実行 {#run-the-test}

1. スクリプトを実行します:

   ```shell
   ruby test_o11y.rb
   ```

1. **可観測性** > **サービス**に移動します。`test-service`サービスを選択して、トレースとスパンを表示します。

## GitLab可観測性テンプレート {#gitlab-observability-templates}

GitLabは、すぐに可観測性を使い始めるのに役立つ、事前構築済みのダッシュボードテンプレートを提供します。これらのテンプレートは、[GitLab可観測性テンプレート](https://gitlab.com/gitlab-org/embody-team/experimental-observability/o11y-templates/)で入手できます。

### 利用可能なテンプレート {#available-templates}

**Standard OpenTelemetry dashboards**: アプリケーションを標準のOpenTelemetryライブラリでインストゥルメントする場合、これらのプラグアンドプレイのダッシュボードテンプレートを使用できます:

- アプリケーションパフォーマンス監視ダッシュボード
- サービス依存関係の可視化
- エラー率とレイテンシーの追跡

**GitLab-specific dashboards**: GitLab OpenTelemetryデータをGitLab可観測性インスタンスに送信すると、これらのダッシュボードをすぐに使用してインサイトを得ることができます:

- GitLabアプリケーションパフォーマンスメトリクス
- GitLabサービス稼働状況モニタリング
- GitLab固有のトレース分析

**CI/CD observability**: リポジトリには、GitLab可観測性CI/CDダッシュボードテンプレートJSONファイルと連携するOpenTelemetryインストゥルメンテーションを備えた、GitLab CI/CDパイプラインの例が含まれています。これにより、CI/CDパイプラインのパフォーマンスを監視し、ボトルネックを特定できます。

### テンプレートの使用 {#using-the-templates}

1. リポジトリからテンプレートをクローンまたはダウンロードします。
1. サンプルアプリケーションダッシュボードのサービス名を、ご自身のサービス名と一致するように更新します。
1. JSONファイルをGitLab可観測性インスタンスにインポートします。
1. [アプリケーションをインスツルメントする](#instrument-your-application)セクションで説明されているように、標準のOpenTelemetryライブラリを使用してテレメトリーデータを送信するようにアプリケーションを設定します。
1. ダッシュボードは、アプリケーションのテレメトリーデータとともにGitLab可観測性で利用可能になりました。

## 関連トピック {#related-topics}

- [可観測性のトラブルシューティング](troubleshooting.md)
