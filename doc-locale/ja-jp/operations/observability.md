---
stage: none
group: Embody
info: This page is owned by https://handbook.gitlab.com/handbook/ceo/office-of-the-ceo/embody-team/
description: アプリケーションのパフォーマンスをモニタリングし、パフォーマンスのイシューのトラブルシューティングを行います。
ignore_in_report: true
title: 可観測性
---

{{< details >}}

- プラン: Free
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.1で[導入](https://gitlab.com/experimental-observability/documentation/-/issues/6)されました。これは[実験的機能](../policy/development_stages_support.md)です。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

GitLab可観測性 (O11y) を使用して以下を行います:

- 統合された可観測性ダッシュボードを通じてアプリケーションのパフォーマンスをモニタリングします。
- 単一のプラットフォームで分散トレーシング、ログ、メトリクスを表示します。
- アプリケーションのパフォーマンスのボトルネックを特定し、トラブルシューティングを行います。

{{< alert type="disclaimer" />}}

可観測性をGitLab自体に追加することで、ユーザーは[これらの（計画された）機能](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues/8)を利用できるようになります。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[GitLab Experimental Observability (O11y) Introduction](https://www.youtube.com/watch?v=XI9ZruyNEgs)を参照してください。
<!-- Video published on 2025-06-18 -->

GitLab O11yの興味深い使用方法に関する会話に、GitLab O11y [Discordチャンネル](https://discord.com/channels/778180511088640070/1379585187909861546)で参加してください。

## GitLabの可観測性を選ぶ理由 {#why-gitlab-observability}

- **Cost-effective open source model**（費用対効果の高いオープンソースモデル）: 可観測性をあらゆる規模のチームが利用できるように、シート単位のライセンスではなく、コンピューティングリソースに対してのみ料金を支払います。機能や修正に直接コントリビュートすることで、プラットフォームが特定のニーズを満たすように進化することを保証できます。
- **Simplified access management**（簡素化されたアクセス管理）: 新しいエンジニアは、コードリポジトリへのアクセス権を取得すると、自動的に本番環境の可観測性データへのアクセス権を取得し、時間のかかるプロビジョニングプロセスを排除できます。この統合されたアクセスモデルにより、チームメンバーは管理上の遅延なしに、トラブルシューティングやモニタリングの取り組みにすぐにコントリビュートできるようになります。
- **Enhanced development workflow**（強化された開発ワークフロー）: 開発者はコードの変更をアプリケーションのパフォーマンスメトリクスと直接関連付けることができるため、デプロイでイシューが発生した場合でも簡単に特定できます。このコードコミットとランタイムの動作間の緊密なインテグレーションにより、デバッグが迅速化され、平均解決時間が短縮されます。
- **Shift-left observability**（シフトレフト可観測性）: チームは、可観測性データを開発プロセスに統合することで、開発サイクルのできるだけ早い段階でパフォーマンスのイシューやアノマリを検出できます。このプロアクティブなアプローチにより、問題の修正にかかるコストと影響が軽減されます。オープンソースの性質により、本番環境の可観測性をミラーリングする包括的なステージング環境をより簡単かつ費用対効果の高い方法でオーケストレーションを行うことができます。
- **Streamlined incident response**（合理化されたインシデント対応）: イシューが発生した場合、チームは最近のデプロイ、コードの変更、および関係する開発者に関するコンテキストをより迅速に把握し、より迅速なトリアージと解決を支援できます。このインテグレーションは、コードと運用データの両方に対して、単一の画面を提供します。
- **Data next to decisions**（意思決定に役立つデータ）: リアルタイムのパフォーマンスメトリクスとユーザーの行動データが開発環境でアクセスできるようになり、チームは機能の優先順位、技術的負債、および最適化の取り組みについて情報に基づいた意思決定を行うことができます。
- **Compliance and audit trails**（コンプライアンスと監査証跡）: このインテグレーションにより、コードの変更をシステムの動作にリンクする包括的な監査証跡が作成されます。これは、コンプライアンス要件およびインシデント後の分析に役立ちます。
- **Reduced tool switching**（ツール切り替えの削減）: 開発チームは、使い慣れたGitLab環境を離れることなく、モニタリングデータ、アラート、パフォーマンスのインサイトにアクセスできるため、生産性の向上と認知的オーバーヘッドの削減に役立ちます。

{{< tabs >}}

{{< tab title="GitLab.com" >}}

## 前提要件 {#prerequisites}

- グループのデベロッパーロール以上を持っている必要があります。
- グループでGitLabの可観測性が有効になっている必要があります

## GitLabの可観測性へのアクセスをリクエストします {#request-access-to-gitlab-observability}

グループでGitLabの可観測性がまだ有効になっていない場合は、次のようにします:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**可観測性**を選択します。
1. **アクセスをリクエスト**を選択します。
1. **可観測性を有効にする**を選択します。
1. 可観測性のインスタンスの準備が完了したことを確認するメール通知をお待ちください。

メールには、アプリケーションをインストルメントするためのOpenTelemetry（`OTEL`）エンドポイントURLが含まれています。

![可観測性を有効にするボタン](img/gitLab_o11y_enable_button_v18_1.png "可観測性を有効にするボタン")

## GitLabの可観測性にアクセスする {#access-gitlab-observability}

アクセス権が付与されたら:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**可観測性**を選択します。

左側のサイドバーに**可観測性**が表示されない場合は、`https://gitlab.com/groups/<group_path>/-/observability/services`に直接アクセスしてください。

![GitLab.comの可観測性ダッシュボード](img/gitLab_o11y_gitlab_com_dashboard_v18_1.png "GitLab.comの可観測性ダッシュボード")

## テレメトリデータをGitLab.comの可観測性に送信する {#send-telemetry-data-to-gitlabcom-observability}

アクセス確認メールで提供されたOTELエンドポイントURLを使用して、アプリケーションのOpenTelemetry計測を構成します。

### 設定例 {#example-configuration}

確認メールのURLで`YOUR_OTEL_ENDPOINT_URL`を置き換えます:

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

OpenTelemetry::SDK.configure do |c|
resource = OpenTelemetry::SDK::Resources::Resource.create({
'service.name' => 'your-service-name',
'service.version' => '1.0.0',
'deployment.environment' => 'production'
})
c.resource = resource

c.add_span_processor(
OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
OpenTelemetry::Exporter::OTLP::Exporter.new(
endpoint: 'YOUR_OTEL_ENDPOINT_URL'
)
)
)
end
```

他のプログラミング言語については、[OpenTelemetryドキュメント](https://opentelemetry.io/docs/instrumentation/)を参照してください。

{{< /tab >}}

{{< tab title="セルフホスト" >}}

## GitLab可観測性インスタンスを設定する {#set-up-a-gitlab-observability-instance}

可観測性データは、GitLab.comインスタンスとは別のアプリケーションで収集されます。GitLabインスタンスの問題は、可観測性データの収集または表示に影響を与えず、その逆も同様です。

前提要件:

- 次の条件を満たすEC2インスタンスまたは同様の仮想マシンが必要です:
  - 最小: t3.large (2仮想CPU、8 GB RAM)。
  - 推奨: 本番環境で使用する場合は、t3.xlarge (4仮想CPU、16 GB RAM)。
  - 少なくとも100 GBのストレージ容量。
- DockerとDocker Composeがインストールされている必要があります。
- GitLabバージョンが18.1以降である必要があります
- GitLabインスタンスが可観測性インスタンスに接続されている必要があります。

### サーバーとストレージをプロビジョニングする {#provision-server-and-storage}

AWS EC2の場合:

1. 少なくとも2つの仮想CPUと8 GBのRAMを備えたEC2インスタンスを起動します。
1. 少なくとも100 GBのEBSボリュームを追加します。
1. SSHを使用してインスタンスに接続します。

### ストレージボリュームをマウントする {#mount-storage-volume}

```shell
sudo mkdir -p /mnt/data
sudo mount /dev/xvdbb /mnt/data  # Replace xvdbb with your volume name
sudo chown -R $(whoami):$(whoami) /mnt/data
```

永続的なマウントの場合は、`/etc/fstab`に追加します:

```shell
echo '/dev/xvdbb /mnt/data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
```

### Dockerをインストール {#install-docker}

Ubuntu/Debianの場合:

```shell
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $(whoami)
```

Amazon Linux 2023の場合:

```shell
sudo dnf update
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $(whoami)
```

ログアウトして再度ログインするか、次を実行します:

```shell
newgrp docker
```

### マウントされたボリュームを使用するようにDockerを構成する {#configure-docker-to-use-the-mounted-volume}

```shell
sudo mkdir -p /mnt/data/docker
sudo bash -c 'cat > /etc/docker/daemon.json << EOF
{
  "data-root": "/mnt/data/docker"
}
EOF'
sudo systemctl restart docker
```

以下で確認します:

```shell
docker info | grep "Docker Root Dir"
```

### GitLabの可観測性をインストールする {#install-gitlab-observability}

```shell
cd /mnt/data
git clone -b main https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y.git
cd gitlab_o11y/deploy/docker
docker-compose up -d
```

タイムアウトエラーが発生した場合は、次を使用します:

```shell
COMPOSE_HTTP_TIMEOUT=300 docker-compose up -d
```

### （オプション）: 外部ClickHouseデータベースを使用する {#optional-use-an-external-clickhouse-database}

必要に応じて、独自のClickHouseデータベースを使用できます。

前提要件:

- 外部ClickHouseインスタンスがアクセス可能であり、必要な認証認証情報で適切に構成されていることを確認してください。

`docker-compose up -d`を実行する前に、次の手順を完了してください:

1. `docker-compose.yml`ファイルを開きます。
1. `docker-compose.yml`を開き、以下をコメントアウトします:
   - `clickhouse`および`zookeeper`サービス。
   - `x-clickhouse-defaults`および`x-clickhouse-depend`セクション。
1. 次のファイルで、`clickhouse:9000`のすべての出現箇所を、関連するClickHouseエンドポイントおよびTCPポート（たとえば、`my-clickhouse.example.com:9000`）に置き換えます。ClickHouseインスタンスで認証が必要な場合は、接続文字列を更新して認証情報を含める必要もあります:
   - `docker-compose.yml`
   - `otel-collector-config.yaml`
   - `prometheus-config.yml`

### GitLabの可観測性のネットワークアクセスを構成する {#configure-network-access-for-gitlab-observability}

テレメトリデータを適切に受信するには、GitLab O11yインスタンスのセキュリティグループで特定のポートを開く必要があります:

1. **AWS Console**（AWSコンソール） > **EC2**（EC2） > **Security Groups**（セキュリティグループ）に移動します。
1. GitLab O11yインスタンスにアタッチされたセキュリティグループを選択します。
1. **Edit inbound rules**（受信ルールを編集） を選択します。
1. 次のルールをに追加します:
   - 種類: カスタムTCP、ポート: 8080、ソース: UIアクセスの場合は、自分のIPまたは0.0.0.0/0
   - 種類: カスタムTCP、ポート: 4317、ソース: OTLP gRPCの場合は、自分のIPまたは0.0.0.0/0
   - 種類: カスタムTCP、ポート: 4318、ソース: OTLP HTTPの場合は、自分のIPまたは0.0.0.0/0
   - 種類: カスタムTCP、ポート: 9411、ソース: Zipkin（オプション）の場合は、自分のIPまたは0.0.0.0/0
   - 種類: カスタムTCP、ポート: 14268、ソース: Jaeger HTTP（オプション）の場合は、自分のIPまたは0.0.0.0/0
   - 種類: カスタムTCP、ポート: 14250、ソース: Jaeger gRPC（オプション）の場合は、自分のIPまたは0.0.0.0/0
1. **Save rules**（ルールを保存） を選択します。

### GitLabの可観測性にアクセスする {#access-gitlab-observability-1}

次の場所でGitLab O11y UIにアクセスします:

```plaintext
http://[your-instance-ip]:8080
```

## GitLabをGitLabの可観測性に接続する {#connect-gitlab-to-gitlab-observability}

### GitLabを構成し、機能フラグを有効にする {#configure-gitlab-and-enable-the-feature-flag}

Railsコンソールを使用して、グループのGitLab O11y URLを構成し、機能フラグを有効にします:

1. Railsコンソールにアクセスします:

   ```shell
   docker exec -it gitlab gitlab-rails console
   ```

1. グループの可観測性設定を構成し、機能フラグを有効にします:

   ```ruby
   group = Group.find_by_path('your-group-name')

   Observability::GroupO11ySetting.create!(
     group_id: group.id,
     o11y_service_url: 'your-o11y-instance-url',
     o11y_service_user_email: 'your-email@example.com',
     o11y_service_password: 'your-secure-password',
     o11y_service_post_message_encryption_key: 'your-super-secret-encryption-key-here-32-chars-minimum'
   )

   Feature.enable(:observability_sass_features, group)

   Feature.enabled?(:observability_sass_features, group)
   ```

   以下の値を置き換えます:
   - 実際のグループパスで`your-group-name`
   - GitLab O11yインスタンスURL（例：`http://192.168.1.100:8080`）で`your-o11y-instance-url`
   - 優先する認証情報でメールとパスワード
   - セキュアな32文字以上の文字列を使用した暗号化キー

   最後のコマンドは、機能が有効になっていることを確認するために`true`を返す必要があります。

{{< /tab >}}

{{< /tabs >}}

## GitLabで可観測性を使用する {#use-observability-with-gitlab}

GitLab O11yを構成した後、GitLabに埋め込まれたダッシュボードにアクセスするには:

1. 左側のサイドバーで、**検索または移動先**を選択し、機能フラグが有効になっているグループを見つけます。
1. 左側のサイドバーで、**可観測性**を選択します。

左側のサイドバーに**可観測性**が表示されない場合は、`http://<gitlab_instance>/groups/<group_path>/-/observability/services`に直接アクセスしてください。

![GitLab Experimental可観測性の例](img/gitLab_o11y_example_v18_1.png "GitLab可観測性の例")

## テレメトリデータをGitLabの可観測性に送信する {#send-telemetry-data-to-gitlab-observability}

OpenTelemetry SDKを使用してサンプルテレメトリデータを送信することにより、GitLab O11yのインストールをテストできます。この例ではRubyを使用していますが、OpenTelemetryには多くの言語のSDKがあります。

前提要件:

- Rubyがローカルマシンにインストールされていること
- 必要なgem:

  ```shell
  gem install opentelemetry-sdk opentelemetry-exporter-otlp
  ```

### 基本的なテストスクリプトを作成する {#create-a-basic-test-script}

次のコンテンツを含む`test_o11y.rb`という名前のファイルを作成します:

```ruby
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'

OpenTelemetry::SDK.configure do |c|
  # Define service information
  resource = OpenTelemetry::SDK::Resources::Resource.create({
    'service.name' => 'test-service',
    'service.version' => '1.0.0',
    'deployment.environment' => 'production'
  })
  c.resource = resource

  # Configure OTLP exporter to send to GitLab O11y
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

`[your-o11y-instance-ip]`をGitLab O11yインスタンスのIPアドレスまたはホスト名に置き換えます。

### テストを実行する {#run-the-test}

1. スクリプトを実行します:

   ```shell
   ruby test_o11y.rb
   ```

1. GitLab O11yダッシュボードを確認します:
   - `http://[your-o11y-instance-ip]:8080`を開きます
   - 「サービス」セクションに移動します
   - 「test-service」サービスを探します
   - それを選択して、トレーシングとスパンを表示します

## アプリケーションをインストルメントする {#instrument-your-application}

アプリケーションにOpenTelemetry計測を追加するには:

1. 言語のOpenTelemetry SDKを追加します。
1. GitLab O11yインスタンスを指すようにOTLPエクスポーターを構成します。
1. 操作とメタデータを追跡するために、スパンと属性を追加します。

言語固有のガイドラインについては、[OpenTelemetryドキュメント](https://opentelemetry.io/docs/instrumentation/)を参照してください。

## GitLab可観測性テンプレート {#gitlab-observability-templates}

GitLabは、可観測性を迅速に開始できるように、事前に構築されたダッシュボードテンプレートを提供します。これらのテンプレートは、[Experimental Observability O11y Templates](https://gitlab.com/gitlab-org/embody-team/experimental-observability/o11y-templates/)で入手できます。

### 利用可能なテンプレート {#available-templates}

**Standard OpenTelemetry dashboards**（標準のOpenTelemetryダッシュボード）: 標準のOpenTelemetryライブラリでアプリケーションをインストルメントする場合は、これらのプラグアンドプレイダッシュボードテンプレートを使用できます:

- アプリケーションパフォーマンスモニタリングダッシュボード
- サービス依存関係の可視化
- エラー率とレイテンシーの追跡

**GitLab-specific dashboards**（GitLab固有のダッシュボード）: GitLab OpenTelemetryデータをGitLab O11yインスタンスに送信する場合は、これらのダッシュボードを使用して、すぐに使用できるインサイトを得ます:

- GitLabアプリケーションパフォーマンスメトリクス
- GitLabサービスのヘルスモニタリング
- GitLab固有のトレーシング分析

**CI/CD observability**（CI/CD可観測性）: このリポジトリには、GitLab O11y CI/CDダッシュボードテンプレートJSONファイルで動作するOpenTelemetry計測を備えた、サンプルGitLab CI/CDパイプラインが含まれています。これにより、CI/CDパイプラインのパフォーマンスをモニタリングし、ボトルネックを特定できます。

### テンプレートを使用する {#using-the-templates}

1. リポジトリからテンプレートを複製またはダウンロードします。
1. サンプルアプリケーションダッシュボードのサービス名を、サービス名と一致するように更新します。
1. JSONファイルをGitLab O11yインスタンスにインポートします。
1. [アプリケーションをインストルメントする](#instrument-your-application)セクションで説明されているように、標準のOpenTelemetryライブラリを使用してテレメトリデータを送信するようにアプリケーションを構成します。
1. ダッシュボードは、GitLab O11yのアプリケーションのテレメトリデータで使用できるようになりました。

## トラブルシューティング {#troubleshooting}

### GitLab可観測性インスタンスのイシュー {#gitlab-observability-instance-issues}

コンテナのステータスを確認します:

```shell
docker ps
```

コンテナログを表示します:

```shell
docker logs [container_name]
```

### メニューが表示されない {#menu-doesnt-appear}

1. 機能フラグがグループに対して有効になっていることを確認します:

   ```ruby
   Feature.enabled?(:observability_sass_features, Group.find_by_path('your-group-name'))
   ```

1. O11Y_URL環境変数が設定されていることを確認します:

   ```ruby
   group = Group.find_by_path('your-group-name')
   group.observability_group_o11y_setting&.o11y_service_url
   ```

1. ルートが適切に登録されていることを確認します:

   ```ruby
   Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?('observability') }.map(&:path)
   ```

### デバッグに関する問題 {#performance-issues}

SSH接続の問題が発生している場合、またはパフォーマンスが低下している場合:

- インスタンスタイプが最小要件（2 vCPU、8 GB RAM）を満たしていることを確認します
- より大きなインスタンスタイプへのサイズ変更を検討してください
- ディスク容量を確認し、必要に応じて増やしてください

### テレメトリが表示されない {#telemetry-doesnt-show-up}

テレメトリデータがGitLab O11yに表示されない場合:

1. セキュリティグループでポート4317および4318が開いていることを確認します。
1. 次のコマンドで接続をテストします:

   ```shell
   nc -zv [your-o11y-instance-ip] 4317
   nc -zv [your-o11y-instance-ip] 4318
   ```

1. コンテナログにエラーがないか確認します:

   ```shell
   docker logs otel-collector-standard
   docker logs o11y-otel-collector
   docker logs o11y
   ```

1. gRPC（4317）の代わりにHTTPエンドポイント（4318）を使用してみてください。
1. OpenTelemetryのセットアップに詳細なデバッグ情報を追加します。
