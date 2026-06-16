---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo 사이트 업그레이드
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

> [!warning]
> Geo 사이트를 업데이트하기 전에 이 섹션을 주의 깊게 읽으세요. 버전별 업그레이드 단계를 따르지 않으면 예상치 못한 다운타임이 발생할 수 있습니다. 특정 질문이 있으시면 [지원팀에 문의](https://about.gitlab.com/support/#contact-support)하세요. 데이터베이스 주요 버전 업그레이드는 Geo 세컨더리에 [PostgreSQL 복제를 다시 초기화](https://docs.gitlab.com/omnibus/settings/database/#upgrading-a-geo-instance)해야 합니다. 이는 Linux 패키지 데이터베이스와 외부 관리 데이터베이스 모두에 적용됩니다. 이로 인해 예상보다 더 큰 다운타임이 발생할 수 있습니다.

Geo 사이트 업그레이드에는 다음이 포함됩니다:

1. 업그레이드할 버전 또는 업그레이드 대상 버전에 따라 버전별 업그레이드 단계:
   - [GitLab 19 업그레이드 노트](../../../update/versions/gitlab_19_changes.md)
   - [GitLab 18 업그레이드 노트](../../../update/versions/gitlab_18_changes.md)
   - [GitLab 17 업그레이드 노트](../../../update/versions/gitlab_17_changes.md)
   - [GitLab 16 업그레이드 노트](../../../update/versions/gitlab_16_changes.md)
   - [GitLab 15 업그레이드 노트](../../../update/versions/gitlab_15_changes.md)
1. [일반 업그레이드 단계](#general-upgrade-steps)(모든 업그레이드용)

## 일반 업그레이드 단계 {#general-upgrade-steps}

> [!note]
> 이 일반 업그레이드 단계는 다중 노드 설정에서 다운타임이 필요합니다. 다운타임을 피하려면 [무중단 업그레이드](../../../update/zero_downtime.md#upgrade-multi-node-geo-instances) 사용을 고려하세요.

새로운 GitLab 버전이 릴리스되면 Geo 사이트를 업그레이드할 때 **프라이머리** 및 모든 **세컨더리** 사이트를 업그레이드합니다:

1. 선택사항. [**세컨더리** 사이트의 복제 일시 중지](pause_resume_replication.md)하여 **세컨더리** 사이트의 재해 복구(DR) 기능을 보호합니다. 더 높은 위험도의 업그레이드 기간 동안 정리된 DR 체크포인트를 보존하는 것이 우선순위인 경우 복제를 일시 중지하세요. 업그레이드 중에 세컨더리를 최신 상태로 유지하고 일반적으로 읽기 트래픽을 제공하는 것이 우선순위인 경우 복제를 일시 중지하지 않으세요. 특히 무중단 접근 방식에서는 더욱 그렇습니다.
1. **프라이머리** 사이트의 각 노드에 SSH로 접속합니다.
1. [**프라이머리** 사이트에서 GitLab 업그레이드](../../../update/package/_index.md)합니다.
1. **프라이머리** 사이트에서 테스트를 수행합니다. 특히 DR을 보호하기 위해 1단계에서 복제를 일시 중지한 경우 더욱 그렇습니다. 업그레이드 후 테스트에 대한 자세한 내용은 [업그레이드 상태 확인 실행](../../../update/plan_your_upgrade.md#run-upgrade-health-checks)을 참조하세요.
1. 프라이머리 사이트와 세컨더리 사이트 모두의 `/etc/gitlab/gitlab-secrets.json` 파일에 있는 시크릿이 동일한지 확인합니다. 파일은 사이트의 모든 노드에서 동일해야 합니다.
1. **세컨더리** 사이트의 각 노드에 SSH로 접속합니다.
1. [각 **세컨더리** 사이트에서 GitLab 업그레이드](../../../update/package/_index.md)합니다.
1. 1단계에서 복제를 일시 중지한 경우 [각 **세컨더리**에서 복제 재개](../_index.md#pausing-and-resuming-replication)하세요. 그런 다음 각 **세컨더리** 사이트에서 Puma 및 Sidekiq을 다시 시작합니다. 이는 이전에 업그레이드된 **프라이머리** 사이트에서 복제된 새로운 데이터베이스 스키마에 대해 초기화되도록 하기 위함입니다.

   ```shell
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart puma
   ```

1. [테스트](#check-status-after-upgrading) **프라이머리** 및 **세컨더리** 사이트를 진행하고 각각의 버전을 확인합니다.

### 업그레이드 후 상태 확인 {#check-status-after-upgrading}

업그레이드 프로세스가 완료되었으므로 이제 모든 것이 제대로 작동하는지 확인할 수 있습니다:

1. 프라이머리 및 세컨더리 사이트의 애플리케이션 노드에서 Geo Rake 작업을 실행합니다. 모든 것이 녹색이어야 합니다:

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

1. **프라이머리** 사이트의 Geo 대시보드에서 오류가 있는지 확인합니다.
1. **프라이머리** 사이트에 코드를 푸시하여 데이터 복제를 테스트하고 **세컨더리** 사이트에서 수신되는지 확인합니다.

문제가 발생하면 [Geo 문제 해결 가이드](troubleshooting/_index.md)를 참조하세요.
