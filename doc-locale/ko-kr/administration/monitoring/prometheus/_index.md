---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Prometheus를 사용한 GitLab 모니터링
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

[Prometheus](https://prometheus.io)는 강력한 시계열 모니터링 서비스로, GitLab 및 기타 소프트웨어 제품을 모니터링할 수 있는 유연한 플랫폼을 제공합니다.

GitLab은 Prometheus를 통한 기본 제공 모니터링을 제공하며, GitLab 서비스의 고품질 시계열 모니터링에 대한 액세스를 제공합니다.

Prometheus와 이 페이지에 나열된 다양한 내보내기는 Linux 패키지에 번들로 포함되어 있습니다. 추가된 시간 선택 기간은 각 내보내기의 설명서를 참조하세요. 자체 컴파일된 설치의 경우 직접 설치해야 합니다. 이후 릴리스에서는 추가 GitLab 메트릭이 캡처됩니다.

Prometheus 서비스는 기본적으로 켜져 있습니다.

Prometheus와 해당 내보내기는 사용자를 인증하지 않으며 액세스할 수 있는 모든 사용자가 사용할 수 있습니다.

## Prometheus 작동 방식 {#how-prometheus-works}

Prometheus는 데이터 소스에 주기적으로 연결하여 [다양한 내보내기](#bundled-software-metrics)를 통해 성능 메트릭을 수집함으로써 작동합니다. 모니터링 데이터를 보고 작업하려면 [Prometheus에 직접 연결](#viewing-performance-metrics) 하거나 [Grafana](https://grafana.com)와 같은 대시보드 도구를 사용할 수 있습니다.

## Prometheus 구성 {#configuring-prometheus}

자체 컴파일 설치의 경우 직접 설치 및 구성해야 합니다.

Prometheus와 해당 내보내기는 기본적으로 켜져 있습니다. Prometheus는 `gitlab-prometheus` 사용자로 실행되며 `http://localhost:9090`에서 수신 대기합니다. 기본적으로 Prometheus는 GitLab 서버 자체에서만 액세스할 수 있습니다. 각 내보내기는 개별적으로 비활성화되지 않는 한 Prometheus의 모니터링 대상으로 자동으로 설정됩니다.

Prometheus 및 모든 내보내기와 향후 추가되는 모든 내보내기를 비활성화하려면:

1. `/etc/gitlab/gitlab.rb`을 편집합니다.
1. 다음 줄을 추가하거나 찾아 주석 처리를 제거하고 `false`로 설정해야 합니다:

   ```ruby
   prometheus_monitoring['enable'] = false
   sidekiq['metrics_enabled'] = false

   # Already set to `false` by default, but you can explicitly disable it to be sure
   puma['exporter_enabled'] = false
   ```

1. 파일을 저장하고 [GitLab을 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

### Prometheus가 수신 대기하는 포트 및 주소 변경 {#changing-the-port-and-address-prometheus-listens-on}

> [!warning]
> Prometheus가 수신 대기하는 포트는 변경할 수 있지만 변경하면 안 됩니다. 이 변경 사항은 GitLab 서버에서 실행 중인 다른 서비스에 영향을 주거나 충돌할 수 있습니다. 위험을 감수하고 진행하세요.

GitLab 서버 외부에서 Prometheus에 액세스하려면 Prometheus가 수신 대기하는 주소/포트를 변경합니다:

1. `/etc/gitlab/gitlab.rb`을 편집합니다.
1. 다음 줄을 추가하거나 찾아 주석 처리를 제거합니다:

   ```ruby
   prometheus['listen_address'] = 'localhost:9090'
   ```

   `localhost:9090`을 Prometheus가 수신 대기하려는 주소 또는 포트로 바꿉니다. `localhost` 이외의 호스트에서 Prometheus에 액세스하도록 허용하려면 호스트를 생략하거나 `0.0.0.0`을 사용하여 공개 액세스를 허용합니다:

   ```ruby
   prometheus['listen_address'] = ':9090'
   # or
   prometheus['listen_address'] = '0.0.0.0:9090'
   ```

1. 파일을 저장하고 [GitLab 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

### 사용자 정의 스크래핑 구성 추가 {#adding-custom-scrape-configurations}

`prometheus['scrape_configs']`을 `/etc/gitlab/gitlab.rb`에서 편집하여 Linux 패키지 번들 Prometheus에 대한 추가 스크래핑 대상을 구성할 수 있습니다. [Prometheus 스크래핑 대상 구성](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Cscrape_config%3E) 구문을 사용합니다.

다음은 `http://1.1.1.1:8060/probe?param_a=test&param_b=additional_test`을 스크래핑하기 위한 예제 구성입니다:

```ruby
prometheus['scrape_configs'] = [
  {
    'job_name': 'custom-scrape',
    'metrics_path': '/probe',
    'params' => {
      'param_a' => ['test'],
      'param_b' => ['additional_test'],
    },
    'static_configs' => [
      'targets' => ['1.1.1.1:8060'],
    ],
  },
]
```

### Linux 패키지를 사용하는 독립 실행형 Prometheus {#standalone-prometheus-using-the-linux-package}

Linux 패키지를 사용하여 Prometheus를 실행하는 독립 실행형 모니터링 노드를 구성할 수 있습니다. 외부 [Grafana](../performance/grafana_configuration.md)를 이 모니터링 노드로 구성하여 대시보드를 표시할 수 있습니다.

독립 실행형 모니터링 노드는 [여러 노드로 이루어진 GitLab 배포](../../reference_architectures/_index.md)에 권장됩니다.

다음 단계는 Linux 패키지를 사용하여 Prometheus를 실행하는 모니터링 노드를 구성하는 데 필요한 최소한의 단계입니다:

1. 모니터링 노드로 SSH 접속합니다.
1. [설치](https://about.gitlab.com/install/): GitLab 다운로드 페이지에서 **steps 1 and 2**를 사용하여 원하는 Linux 패키지를 설치하지만 나머지 단계는 수행하지 마세요.
1. 다음 단계를 위해 Consul 서버 노드의 IP 주소 또는 DNS 레코드를 수집해야 합니다.
1. `/etc/gitlab/gitlab.rb`을 편집하고 다음 내용을 추가합니다:

   ```ruby
   roles ['monitoring_role']

   external_url 'http://gitlab.example.com'

   # Prometheus
   prometheus['listen_address'] = '0.0.0.0:9090'
   prometheus['monitor_kubernetes'] = false

   # Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] = true
   consul['configuration'] = {
      retry_join: %w(10.0.0.1 10.0.0.2 10.0.0.3), # The addresses can be IPs or FQDNs
   }

   # Nginx - For Grafana access
   nginx['enable'] = true
   ```

1. `sudo gitlab-ctl reconfigure`을 실행하여 구성을 컴파일합니다.

다음 단계는 다른 모든 노드에서 모니터링 노드의 위치를 알려주는 것입니다:

1. `/etc/gitlab/gitlab.rb`을 편집하고 다음 줄을 추가하거나 찾아 주석 처리를 제거합니다:

   ```ruby
   # can be FQDN or IP
   gitlab_rails['prometheus_address'] = '10.0.0.1:9090'
   ```

   `10.0.0.1:9090`은 Prometheus 노드의 IP 주소 및 포트입니다.

1. 파일을 저장하고 [GitLab을 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

`consul['monitoring_service_discovery'] = true`을 사용하여 모니터링 서비스 검색이 활성화되면 `/etc/gitlab/gitlab.rb`에서 `prometheus['scrape_configs']`이 설정되지 않았는지 확인합니다. `consul['monitoring_service_discovery'] = true`과 `prometheus['scrape_configs']`을 `/etc/gitlab/gitlab.rb`에 모두 설정하면 오류가 발생합니다.

### 외부 Prometheus 서버 사용 {#using-an-external-prometheus-server}

> [!warning]
> Prometheus 및 대부분의 내보내기는 인증을 지원하지 않습니다. 로컬 네트워크 외부에 노출하지 않는 것이 좋습니다.

GitLab이 외부 Prometheus 서버로 모니터링되도록 허용하려면 몇 가지 구성 변경이 필요합니다.

외부 Prometheus 서버를 사용하려면:

1. `/etc/gitlab/gitlab.rb`을 편집합니다.
1. 번들로 제공되는 Prometheus를 비활성화합니다:

   ```ruby
   prometheus['enable'] = false
   ```

1. 각 번들 서비스의 [내보내기](#bundled-software-metrics)를 네트워크 주소에서 수신 대기하도록 설정합니다. 예를 들어:

   ```ruby
   node_exporter['listen_address'] = '0.0.0.0:9100'
   gitlab_workhorse['prometheus_listen_addr'] = "0.0.0.0:9229"

   # Rails nodes
   gitlab_exporter['listen_address'] = '0.0.0.0'
   gitlab_exporter['listen_port'] = '9168'
   registry['debug_addr'] = '0.0.0.0:5001'

   # Sidekiq nodes
   sidekiq['listen_address'] = '0.0.0.0'

   # Redis nodes
   redis_exporter['listen_address'] = '0.0.0.0:9121'

   # PostgreSQL nodes
   postgres_exporter['listen_address'] = '0.0.0.0:9187'

   # Gitaly nodes
   gitaly['configuration'] = {
      # ...
      prometheus_listen_addr: '0.0.0.0:9236',
   }

   # Pgbouncer nodes
   pgbouncer_exporter['listen_address'] = '0.0.0.0:9188'
   ```

1. 필요한 경우 [공식 설치 지침](https://prometheus.io/docs/prometheus/latest/installation/)을 사용하여 전용 Prometheus 인스턴스를 설치하고 설정합니다.
1. **전체** GitLab Rails(Puma, Sidekiq) 서버에서 Prometheus 서버 IP 주소 및 수신 대기 포트를 설정합니다. 예를 들어:

   ```ruby
   gitlab_rails['prometheus_address'] = '192.168.0.1:9090'
   ```

1. NGINX 메트릭을 스크래핑하려면 NGINX를 구성하여 Prometheus 서버 IP를 허용해야 합니다. 예를 들어:

   ```ruby
   nginx['status']['options'] = {
         "server_tokens" => "off",
         "access_log" => "off",
         "allow" => "192.168.0.1",
         "deny" => "all",
   }
   ```

   여러 Prometheus 서버가 있는 경우 둘 이상의 IP 주소를 지정할 수 있습니다:

   ```ruby
   nginx['status']['options'] = {
         "server_tokens" => "off",
         "access_log" => "off",
         "allow" => ["192.168.0.1", "192.168.0.2"],
         "deny" => "all",
   }
   ```

1. Prometheus 서버가 [GitLab 메트릭](#gitlab-metrics) 엔드포인트에서 가져올 수 있도록 허용하려면 Prometheus 서버 IP 주소를 [모니터링 IP 허용 목록](../ip_allowlist.md)에 추가합니다:

   ```ruby
   gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '192.168.0.1']
   ```

1. 각 번들 서비스의 [내보내기](#bundled-software-metrics)를 네트워크 주소에서 수신 대기하도록 설정할 때 인스턴스의 방화벽을 업데이트하여 Prometheus IP에서만 활성화된 내보내기에 대한 트래픽을 허용합니다. 내보내기 서비스 및 [해당 포트](../../package_information/defaults.md#ports)의 전체 참조 목록이 제공됩니다.
1. [GitLab 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.
1. Prometheus 서버의 구성 파일을 편집합니다.
1. 각 노드의 내보내기를 Prometheus 서버의 [스크래핑 대상 구성](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Cscrape_config%3E)에 추가합니다. 예를 들어 `static_configs`를 사용하는 샘플 스니펫입니다:

   ```yaml
   scrape_configs:
     - job_name: nginx
       static_configs:
         - targets:
           - 1.1.1.1:8060
     - job_name: redis
       static_configs:
         - targets:
           - 1.1.1.1:9121
     - job_name: postgres
       static_configs:
         - targets:
           - 1.1.1.1:9187
     - job_name: node
       static_configs:
         - targets:
           - 1.1.1.1:9100
     - job_name: gitlab-workhorse
       static_configs:
         - targets:
           - 1.1.1.1:9229
     - job_name: gitlab-rails
       metrics_path: "/-/metrics"
       scheme: https
       static_configs:
         - targets:
           - 1.1.1.1
     - job_name: gitlab-sidekiq
       static_configs:
         - targets:
           - 1.1.1.1:8082
     - job_name: gitlab_exporter_database
       metrics_path: "/database"
       static_configs:
         - targets:
           - 1.1.1.1:9168
     - job_name: gitlab_exporter_sidekiq
       metrics_path: "/sidekiq"
       static_configs:
         - targets:
           - 1.1.1.1:9168
     - job_name: gitaly
       static_configs:
         - targets:
           - 1.1.1.1:9236
     - job_name: registry
       static_configs:
         - targets:
           - 1.1.1.1:5001
   ```

   > [!warning]
   > 스니펫의 `gitlab-rails` 작업은 GitLab을 HTTPS를 통해 액세스할 수 있다고 가정합니다. 배포에서 HTTPS를 사용하지 않으면 작업 구성이 `http` 스키마 및 포트 80을 사용하도록 조정됩니다.

1. Prometheus 서버를 다시 로드합니다.

### 스토리지 보존 크기 구성 {#configure-the-storage-retention-size}

Prometheus에는 로컬 스토리지를 구성하기 위한 여러 사용자 정의 플래그가 있습니다:

- `storage.tsdb.retention.time`: 이전 데이터를 제거할 시기입니다. `15d`을 기본값으로 설정합니다. 이 플래그가 기본값 이외의 다른 값으로 설정된 경우 `storage.tsdb.retention`을 재정의합니다.
- `storage.tsdb.retention.size`: (실험적) 유지할 스토리지 블록의 최대 바이트 수입니다. 가장 오래된 데이터가 먼저 제거됩니다. `0`(비활성화됨)을 기본값으로 설정합니다. 이 플래그는 실험적이며 향후 릴리스에서 변경될 수 있습니다. 지원되는 단위: `B`, `KB`, `MB`, `GB`, `TB`, `PB`, `EB`입니다. 예를 들어, `512MB`.

스토리지 보존 크기를 구성하려면:

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   prometheus['flags'] = {
     'storage.tsdb.path' => "/var/opt/gitlab/prometheus/data",
     'storage.tsdb.retention.time' => "7d",
     'storage.tsdb.retention.size' => "2GB",
     'config.file' => "/var/opt/gitlab/prometheus/prometheus.yml"
   }
   ```

1. GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 성능 메트릭 보기 {#viewing-performance-metrics}

`http://localhost:9090`을 방문하여 Prometheus에서 기본으로 제공하는 대시보드를 볼 수 있습니다.

GitLab 인스턴스에서 SSL을 활성화한 경우 동일한 FQDN을 사용할 때 [HSTS](https://en.wikipedia.org/wiki/HTTP_Strict_Transport_Security) 때문에 GitLab과 같은 브라우저에서 Prometheus에 액세스하지 못할 수 있습니다. [GitLab 테스트 프로젝트가 존재](https://gitlab.com/gitlab-org/multi-user-prometheus) 하여 액세스를 제공하지만 그 사이에 몇 가지 해결 방법이 있습니다. 별도의 FQDN 사용, 서버 IP 사용, Prometheus용 별도 브라우저 사용, HSTS 재설정 또는 [NGINX 프록시](https://docs.gitlab.com/omnibus/settings/nginx/#inserting-custom-nginx-settings-into-the-gitlab-server-block)를 사용합니다.

Prometheus에서 수집한 성능 데이터는 Prometheus 콘솔에서 직접 또는 호환되는 대시보드 도구를 통해 볼 수 있습니다. Prometheus 인터페이스는 수집한 데이터로 작업할 수 있는 [유연한 쿼리 언어](https://prometheus.io/docs/prometheus/latest/querying/basics/)를 제공하여 출력을 시각화할 수 있습니다. 더 많은 기능을 갖춘 대시보드를 사용하려면 Grafana를 사용할 수 있으며 [Prometheus에 대한 공식 지원](https://prometheus.io/docs/visualization/grafana/)이 있습니다.

## 샘플 Prometheus 쿼리 {#sample-prometheus-queries}

다음은 사용할 수 있는 샘플 Prometheus 쿼리입니다.

> [!note]
> 이 예제는 모든 설정에서 작동하지 않을 수 있습니다. 추가 조정이 필요할 수 있습니다.

- **% CPU utilization**: `1 - avg without (mode,cpu) (rate(node_cpu_seconds_total{mode="idle"}[5m]))`
- **% Memory available**: `((node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) or ((node_memory_MemFree_bytes + node_memory_Buffers_bytes + node_memory_Cached_bytes) / node_memory_MemTotal_bytes)) * 100`
- **Data transmitted**: `rate(node_network_transmit_bytes_total{device!="lo"}[5m])`
- **Data received**: `rate(node_network_receive_bytes_total{device!="lo"}[5m])`
- **Disk read IOPS**: `sum by (instance) (rate(node_disk_reads_completed_total[1m]))`
- **Disk write IOPS**: `sum by (instance) (rate(node_disk_writes_completed_total[1m]))`
- **RPS via GitLab transaction count**: `sum(irate(gitlab_transaction_duration_seconds_count{controller!~'HealthController|MetricsController'}[1m])) by (controller, action)`

## Grafana 데이터 소스로서의 Prometheus {#prometheus-as-a-grafana-data-source}

Grafana를 사용하면 Prometheus 성능 메트릭을 데이터 소스로 가져올 수 있으며 메트릭을 그래프와 대시보드로 렌더링할 수 있습니다. 이는 시각화에 도움이 됩니다.

단일 서버 GitLab 설정을 위한 Prometheus 대시보드를 추가하려면:

1. Grafana에서 새 데이터 소스를 만듭니다.
1. **유형**의 경우 `Prometheus`을 선택합니다.
1. 데이터 소스에 이름을 지정합니다(예: GitLab).
1. **Prometheus server URL**에서 Prometheus 수신 대기 주소를 추가합니다.
1. **HTTP method**를 `GET`로 설정합니다.
1. 구성을 저장하고 테스트하여 작동하는지 확인합니다.

## GitLab 메트릭 {#gitlab-metrics}

GitLab은 자체 내부 서비스 측정항목을 모니터링하고 `/-/metrics` 엔드포인트에서 사용 가능하게 합니다. 다른 내보내기와 달리 이 엔드포인트는 사용자 트래픽과 동일한 URL 및 포트에서 사용 가능하므로 인증이 필요합니다.

[GitLab 메트릭](gitlab_metrics.md)에 대해 자세히 알아봅니다.

## 번들 소프트웨어 메트릭 {#bundled-software-metrics}

Linux 패키지에 번들로 제공되는 GitLab 종속성 중 많은 항목이 Prometheus 메트릭을 내보내도록 사전 구성되어 있습니다.

### 노드 내보내기 {#node-exporter}

노드 내보내기를 사용하면 메모리, 디스크 및 CPU 사용률과 같은 다양한 시스템 리소스를 측정할 수 있습니다.

[노드 내보내기에 대해 자세히 알아봅니다](node_exporter.md).

### 웹 내보내기 {#web-exporter}

웹 내보내기는 전용 메트릭 서버로, 최종 사용자 및 Prometheus 트래픽을 두 개의 별도 애플리케이션으로 분할하여 성능과 가용성을 향상시킵니다.

[웹 내보내기에 대해 자세히 알아봅니다](web_exporter.md).

### Redis 내보내기 {#redis-exporter}

Redis 내보내기를 사용하면 다양한 Redis 메트릭을 측정할 수 있습니다.

[Redis 내보내기에 대해 자세히 알아봅니다](redis_exporter.md).

### PostgreSQL 내보내기 {#postgresql-exporter}

PostgreSQL 내보내기를 사용하면 다양한 PostgreSQL 메트릭을 측정할 수 있습니다.

[PostgreSQL 내보내기에 대해 자세히 알아봅니다](postgres_exporter.md).

### PgBouncer 내보내기 {#pgbouncer-exporter}

PgBouncer 내보내기를 사용하면 다양한 PgBouncer 메트릭을 측정할 수 있습니다.

[PgBouncer 내보내기에 대해 자세히 알아봅니다](pgbouncer_exporter.md).

### 레지스트리 내보내기 {#registry-exporter}

레지스트리 익스포터를 사용하여 다양한 레지스트리 메트릭을 측정할 수 있습니다.

[레지스트리 내보내기에 대해 자세히 알아봅니다](registry_exporter.md).

### GitLab 내보내기 {#gitlab-exporter}

GitLab 내보내기를 사용하면 Redis 및 데이터베이스에서 가져온 다양한 GitLab 메트릭을 측정할 수 있습니다.

[GitLab 내보내기에 대해 자세히 알아봅니다](gitlab_exporter.md).

## 문제 해결 {#troubleshooting}

### `/var/opt/gitlab/prometheus`이 너무 많은 디스크 공간을 사용합니다 {#varoptgitlabprometheus-consumes-too-much-disk-space}

Prometheus 모니터링을 **not** 경우:

1. [Prometheus를 비활성화](_index.md#configuring-prometheus)합니다.
1. `/var/opt/gitlab/prometheus` 아래의 데이터를 삭제합니다.

Prometheus 모니터링을 사용하는 경우:

1. Prometheus를 중지합니다. 실행 중인 상태에서 데이터를 삭제하면 데이터 손상이 발생할 수 있습니다:

   ```shell
   gitlab-ctl stop prometheus
   ```

1. `/var/opt/gitlab/prometheus/data` 아래의 데이터를 삭제합니다.
1. 서비스를 다시 시작합니다:

   ```shell
   gitlab-ctl start prometheus
   ```

1. 서비스가 실행 중인지 확인합니다:

   ```shell
   gitlab-ctl status prometheus
   ```

1. 선택사항. [스토리지 보존 크기를 구성](_index.md#configure-the-storage-retention-size)합니다.

### 모니터링 노드가 데이터를 수신하지 않음 {#monitoring-node-not-receiving-data}

모니터링 노드가 데이터를 수신하지 않으면 내보내기가 데이터를 캡처하는지 확인합니다:

```shell
curl "http[s]://localhost:<EXPORTER LISTENING PORT>/metrics"
```

또는

```shell
curl "http[s]://localhost:<EXPORTER LISTENING PORT>/-/metrics"
```
