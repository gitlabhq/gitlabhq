---
stage: Systems
group: Cloud Connector
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: IP 허용 목록
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 프로브될 때 상태 확인 정보를 제공하는 [모니터링 엔드포인트](health_check.md)를 제공합니다.

IP 허용 목록을 통해 해당 엔드포인트에 대한 액세스를 제어하려면 단일 호스트를 추가하거나 IP 범위를 사용할 수 있습니다:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을(를) 열고 다음을 추가하거나 주석을 제거합니다:

   ```ruby
   gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '192.168.0.1']
   ```

1. 파일을 저장하고 [재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

`gitlab.webservice.monitoring.ipWhitelist` 키 아래에서 필요한 IP를 설정할 수 있습니다. 예를 들어:

```yaml
gitlab:
   webservice:
      monitoring:
         # Monitoring IP allowlist
         ipWhitelist:
         # Defaults
         - 0.0.0.0/0
         - ::/0
```

{{< /tab >}}

{{< tab title="소스에서 직접 컴파일(source)" >}}

1. `config/gitlab.yml`을 편집합니다:

   ```yaml
   monitoring:
     # by default only local IPs are allowed to access monitoring resources
     ip_whitelist:
       - 127.0.0.0/8
       - 192.168.0.1
   ```

1. 파일을 저장하고 [다시 시작](../restart_gitlab.md#self-compiled-installations)하여 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}
