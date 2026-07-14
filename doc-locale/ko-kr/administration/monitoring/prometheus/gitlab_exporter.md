---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab exporter
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

[GitLab exporter](https://gitlab.com/gitlab-org/ruby/gems/gitlab-exporter)를 사용하여 GitLab 인스턴스의 성능 메트릭을 모니터링합니다. Linux 패키지 설치의 경우, GitLab exporter는 Redis 및 데이터베이스에서 메트릭을 가져오고 병목 현상, 리소스 소비 패턴 및 최적화 가능 영역에 대한 통찰력을 제공합니다.

자체 컴파일 설치의 경우 직접 설치 및 구성해야 합니다.

## GitLab exporter 활성화 {#enable-gitlab-exporter}

Linux 패키지 인스턴스에서 GitLab exporter를 활성화하려면:

1. [Prometheus 활성화](_index.md#configuring-prometheus)
1. `/etc/gitlab/gitlab.rb`을 편집합니다.
1. 다음 줄을 추가하거나 찾아서 주석 처리를 제거하고 `true`로 설정되어 있는지 확인합니다:

   ```ruby
   gitlab_exporter['enable'] = true
   ```

1. 파일을 저장하고 [GitLab 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

Prometheus는 `localhost:9168`에 노출된 GitLab exporter에서 자동으로 성능 데이터를 수집하기 시작합니다.

## 다른 Rack 서버 사용 {#use-a-different-rack-server}

기본적으로 GitLab exporter는 단일 스레드 Ruby 웹 서버인 [WEBrick](https://github.com/ruby/webrick)에서 실행됩니다. 성능 요구 사항에 더 잘 맞는 다른 Rack 서버를 선택할 수 있습니다. 예를 들어, 많은 수의 Prometheus scraper를 포함하지만 모니터링 노드가 몇 개만 있는 다중 노드 설정에서는 대신 Puma와 같은 다중 스레드 서버를 실행하도록 선택할 수 있습니다.

Rack 서버를 Puma로 변경하려면:

1. `/etc/gitlab/gitlab.rb`을 편집합니다.
1. 다음 줄을 추가하거나 찾아서 주석 처리를 제거하고 `puma`로 설정합니다:

   ```ruby
   gitlab_exporter['server_name'] = 'puma'
   ```

1. 파일을 저장하고 [GitLab 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

지원되는 Rack 서버는 `webrick`과 `puma`입니다.
