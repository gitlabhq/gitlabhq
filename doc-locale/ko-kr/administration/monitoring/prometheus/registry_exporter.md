---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 레지스트리 익스포터
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

레지스트리 익스포터를 사용하여 다양한 레지스트리 메트릭을 측정할 수 있습니다. 이를 활성화하려면:

1. [Prometheus 활성화](_index.md#configuring-prometheus)
1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 레지스트리에 [디버그 모드](https://docs.docker.com/registry/#debug)를 활성화합니다:

   ```ruby
   registry['debug_addr'] = "localhost:5001"  # localhost:5001/metrics
   ```

1. 파일을 저장하고 [GitLab을 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

Prometheus는 자동으로 `localhost:5001/metrics`에 노출된 레지스트리 익스포터에서 성능 데이터 수집을 시작합니다.

[← 주 Prometheus 페이지로 돌아가기](_index.md)
