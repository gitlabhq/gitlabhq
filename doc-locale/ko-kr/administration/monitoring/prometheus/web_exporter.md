---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 웹 익스포터(전용 메트릭 서버)
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

주 애플리케이션 서버와 별도로 메트릭을 수집하여 GitLab 모니터링의 안정성과 성능을 개선합니다. 전용 메트릭 서버는 모니터링 트래픽을 사용자 요청으로부터 격리하여 메트릭 수집이 애플리케이션 성능에 영향을 주지 않도록 합니다.

중형에서 대규모 설치의 경우, 이러한 분리는 최대 사용 시간 동안 더 일관된 데이터 수집을 제공할 수 있으며 높은 부하 기간 동안 중요한 메트릭 손실의 위험을 줄일 수 있습니다.

## GitLab 메트릭 수집 작동 방식 {#how-gitlab-metrics-collection-works}

Prometheus를 사용하여 GitLab을 모니터링할 때, GitLab은 사용량, 부하 및 성능과 관련된 데이터를 샘플링하는 다양한 수집기를 실행합니다. GitLab은 하나 이상의 Prometheus 익스포터를 실행하여 이 데이터를 Prometheus 스크레이퍼에서 사용 가능하게 할 수 있습니다. Prometheus 익스포터는 메트릭 데이터를 Prometheus 스크레이퍼가 이해하는 형식으로 직렬화하는 HTTP 서버입니다.

> [!note]
> 이 페이지는 웹 애플리케이션 메트릭에 관한 내용입니다. 백그라운드 작업 메트릭을 내보내는 방법을 알아보려면 [Sidekiq 메트릭 서버 구성](../../sidekiq/_index.md#configure-the-sidekiq-metrics-server)을 참조하세요.

웹 애플리케이션 메트릭을 내보낼 수 있는 두 가지 메커니즘을 제공합니다:

- 주 Rails 애플리케이션을 통해서입니다. 이는 우리가 사용하는 애플리케이션 서버인 Puma가 자체 `/-/metrics` 엔드포인트를 통해 메트릭 데이터를 사용 가능하게 만든다는 의미입니다. 이것이 기본값이며 GitLab 메트릭에서 설명합니다. 수집된 메트릭 양이 적은 소규모 GitLab 설치에서는 이 기본값을 사용해야 합니다.
- 전용 메트릭 서버를 통해서입니다. 이 서버를 활성화하면 Puma는 메트릭을 제공하는 것을 유일한 책임으로 하는 추가 프로세스를 시작합니다. 이 방식은 매우 큰 GitLab 설치의 경우 더 나은 장애 격리 및 성능을 제공하지만 추가 메모리 사용이 필요합니다. 높은 성능과 가용성을 추구하는 중형에서 대규모 GitLab 설치의 경우 이 방식을 권장합니다.

전용 서버와 Rails `/-/metrics` 엔드포인트는 모두 동일한 데이터를 제공하므로 기능적으로는 동등하며 성능 특성에만 차이가 있습니다.

전용 서버를 활성화하려면:

1. [Prometheus 활성화](_index.md#configuring-prometheus)
1. `/etc/gitlab/gitlab.rb`을 편집하여 다음 줄을 추가(또는 찾아 주석 해제)합니다. `puma['exporter_enabled']`가 `true`로 설정되어 있는지 확인하세요:

   ```ruby
   puma['exporter_enabled'] = true
   puma['exporter_address'] = "127.0.0.1"
   puma['exporter_port'] = 8083
   ```

1. Prometheus 스크레이퍼를 구성합니다:
   - GitLab 번들 Prometheus를 사용 중인 경우, 해당 [`scrape_config`가 `localhost:8083/metrics`을 가리키는지](_index.md#adding-custom-scrape-configurations) 확인하세요.
   - 외부 Prometheus 서버를 사용 중인 경우, [새 엔드포인트를 스크레이핑하도록 외부 서버를 구성](_index.md#using-an-external-prometheus-server)하세요.
1. 파일을 저장하고 [GitLab 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

이제 `localhost:8083/metrics`에서 메트릭을 제공하고 스크레이핑할 수 있습니다.

## HTTPS 활성화 {#enable-https}

{{< history >}}

- [GitLab 15.2에서 도입](https://gitlab.com/gitlab-org/gitlab/-/issues/364771)되었습니다.

{{< /history >}}

HTTPS를 통해 메트릭을 제공하려면 HTTP 대신 익스포터 설정에서 TLS를 활성화합니다:

1. `/etc/gitlab/gitlab.rb`을 편집하여 다음 줄을 추가(또는 찾아 주석 해제)합니다:

   ```ruby
   puma['exporter_tls_enabled'] = true
   puma['exporter_tls_cert_path'] = "/path/to/certificate.pem"
   puma['exporter_tls_key_path'] = "/path/to/private-key.pem"
   ```

1. 파일을 저장하고 [GitLab을 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

TLS가 활성화되면 앞서 설명한 것처럼 동일한 `port`과 `address`가 사용됩니다. 메트릭 서버는 HTTP와 HTTPS를 동시에 제공할 수 없습니다.

## 관련 항목 {#related-topics}

- [GitLab Docker 설치](../../../install/docker/_index.md)
- [Prometheus를 사용한 GitLab 모니터링](_index.md)
- [GitLab 메트릭](_index.md#gitlab-metrics)
- [Puma 작업](../../operations/puma.md)

## 문제 해결 {#troubleshooting}

### Docker 컨테이너의 공간 부족 {#docker-container-runs-out-of-space}

Docker에서 GitLab을 실행할 때 컨테이너의 공간이 부족할 수 있습니다. 이는 웹 익스포터와 같이 공간 사용을 증가시키는 특정 기능을 활성화할 때 발생할 수 있습니다.

이 문제를 해결하려면 [`shm-size`를 업데이트](../../../install/docker/troubleshooting.md#devshm-mount-not-having-enough-space-in-docker-container)하세요.
