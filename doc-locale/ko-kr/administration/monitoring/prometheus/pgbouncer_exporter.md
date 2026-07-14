---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PgBouncer 익스포터
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

[PgBouncer 익스포터](https://github.com/prometheus-community/pgbouncer_exporter) 를 사용하면 다양한 [PgBouncer](https://www.pgbouncer.org/) 메트릭을 측정할 수 있습니다.

자체 컴파일 설치의 경우 직접 설치 및 구성해야 합니다.

PgBouncer 익스포터를 활성화하려면:

1. [Prometheus 활성화](_index.md#configuring-prometheus)
1. `/etc/gitlab/gitlab.rb`을 편집합니다.
1. 다음 줄을 추가(또는 찾아서 주석 해제)하고 `true`로 설정했는지 확인합니다:

   ```ruby
   pgbouncer_exporter['enable'] = true
   ```

1. 파일을 저장하고 [GitLab을 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

Prometheus가 `localhost:9188`에 노출된 PgBouncer 익스포터에서 성능 데이터를 수집하기 시작합니다.

[`pgbouncer_role`](https://docs.gitlab.com/omnibus/roles/#postgresql-roles) 역할이 활성화되면 PgBouncer 익스포터가 기본적으로 활성화됩니다.
