---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Node exporter
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

[node exporter](https://github.com/prometheus/node_exporter)를 사용하면 메모리, 디스크 및 CPU 사용률과 같은 다양한 머신 리소스를 측정할 수 있습니다.

자체 컴파일 설치의 경우 직접 설치 및 구성해야 합니다.

node exporter를 활성화하려면:

1. [Prometheus 활성화](_index.md#configuring-prometheus)
1. `/etc/gitlab/gitlab.rb`을 편집합니다.
1. 다음 라인을 추가(또는 찾아서 주석 제거)하고 `true`으로 설정되어 있는지 확인합니다:

   ```ruby
   node_exporter['enable'] = true
   ```

1. 파일을 저장하고 변경 사항이 적용되도록 [GitLab 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

Prometheus는 `localhost:9100`에서 노출된 node exporter로부터 성능 데이터를 수집하기 시작합니다.
