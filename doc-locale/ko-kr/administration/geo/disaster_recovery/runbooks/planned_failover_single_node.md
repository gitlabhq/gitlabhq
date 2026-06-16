---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
ignore_in_report: true
title: 재해 복구(Geo) 프로모션 런북
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed
- 상태:  실험

{{< /details >}}

재해 복구(Geo) 프로모션 런북입니다.

> [!warning]
> 이 [런북](../../../../policy/development_stages_support.md#experiment)은 실험입니다. 완전하고 프로덕션이 준비된 문서를 보려면 [재해 복구 문서](../_index.md)를 참조하세요.

## 단일 노드 구성을 위한 Geo 계획된 장애 조치 {#geo-planned-failover-for-a-single-node-configuration}

| 구성 요소   | 구성                |
|:------------|:-----------------------------|
| PostgreSQL  | Linux 패키지에서 관리 |
| Geo 사이트    | 단일 노드                  |
| 세컨더리 | 1개                          |

이 런북은 1개의 세컨더리를 가진 단일 노드 Geo 사이트의 계획된 장애 조치 과정을 안내합니다. 다음의 일반적인 아키텍처를 가정합니다:

프라이머리 사이트:

- GitLab 노드

세컨더리 사이트:

- GitLab 노드

이 가이드는 다음 결과를 생성합니다:

1. 오프라인 프라이머리.
1. 이제 새 프라이머리인 승격된 세컨더리.

다루지 않는 항목:

1. 이전 **프라이머리**를 세컨더리로 다시 추가합니다.
1. 새 세컨더리 추가합니다.

### 준비 {#preparation}

> [!note]
> 다음 단계를 수행하기 전에 프로모션을 위해 **세컨더리**에 대한 `root` 액세스 권한이 있는지 확인하세요. Geo 레플리카를 프로모션하고 장애 조치를 수행하는 자동화된 방법이 없습니다.

**세컨더리** 사이트에서 **운영자 영역** > **Geo** 대시보드로 이동하여 상태를 확인합니다. 복제된 객체 (녹색으로 표시)는 100%에 가까워야 하며 실패 (빨간색으로 표시)가 없어야 합니다. 아직 복제되지 않은 많은 비율의 객체(회색으로 표시)가 있다면 사이트가 완료될 때까지 더 많은 시간을 할애하는 것을 고려하세요.

![세컨더리 사이트의 동기화 상태를 표시하는 Geo 운영자 대시보드.](img/geo_dashboard_v14_0.png)

객체가 복제되지 않는 경우 유지 보수 기간을 예약하기 전에 조사해야 합니다. 계획된 장애 조치 후 복제되지 않은 모든 항목은 **lost**입니다.

복제 실패의 일반적인 원인은 **프라이머리** 사이트에서 데이터가 누락되는 것입니다. 백업에서 데이터를 복원하거나 누락된 데이터에 대한 참조를 제거하여 이러한 실패를 해결할 수 있습니다.

유지 관리 기간은 Geo 복제 및 검증이 완전히 완료될 때까지 끝나지 않습니다. 기간을 최대한 짧게 유지하려면 활성 사용 중에 이러한 프로세스가 최대 100%에 가까운지 확인해야 합니다.

**세컨더리** 사이트가 여전히 **프라이머리** 사이트에서 데이터를 복제하고 있는 경우 불필요한 데이터 손실을 방지하려면 다음 단계를 따르세요:

1. [읽기 전용 모드](https://gitlab.com/gitlab-org/gitlab/-/issues/14609)가 구현될 때까지 **프라이머리**에 대한 수동 업데이트를 방지해야 합니다. 귀하의 **세컨더리** 사이트는 여전히 유지 보수 창 동안 **프라이머리** 사이트에 대한 읽기 전용 액세스가 필요합니다:

   1. 예약된 시간에 클라우드 공급자 또는 사이트의 방화벽을 사용하여 **프라이머리** 사이트에서 **세컨더리** 사이트의 IP와 사용자의 IP를 **except** 모든 HTTP, HTTPS 및 SSH 트래픽을 차단합니다.

      예를 들어 **프라이머리** 사이트에서 다음 명령을 실행할 수 있습니다:

      ```shell
      sudo iptables -A INPUT -p tcp -s <secondary_site_ip> --destination-port 22 -j ACCEPT
      sudo iptables -A INPUT -p tcp -s <your_ip> --destination-port 22 -j ACCEPT
      sudo iptables -A INPUT --destination-port 22 -j REJECT

      sudo iptables -A INPUT -p tcp -s <secondary_site_ip> --destination-port 80 -j ACCEPT
      sudo iptables -A INPUT -p tcp -s <your_ip> --destination-port 80 -j ACCEPT
      sudo iptables -A INPUT --tcp-dport 80 -j REJECT

      sudo iptables -A INPUT -p tcp -s <secondary_site_ip> --destination-port 443 -j ACCEPT
      sudo iptables -A INPUT -p tcp -s <your_ip> --destination-port 443 -j ACCEPT
      sudo iptables -A INPUT --tcp-dport 443 -j REJECT
      ```

      이 시점부터 사용자는 **프라이머리** 사이트에서 데이터를 보거나 변경할 수 없습니다. 또한 **세컨더리** 사이트에 로그인할 수도 없습니다. 그러나 유지 보수 기간의 나머지 동안 기존 세션이 작동해야 하므로 공개 데이터는 전체적으로 액세스할 수 있습니다.

   1. **프라이머리** 사이트가 다른 IP를 통해 브라우저에서 방문하여 HTTP 트래픽으로 차단되는지 확인합니다. 서버가 연결을 거부해야 합니다.

   1. **프라이머리** 사이트가 SSH를 통한 Git 트래픽으로 차단되는지 확인하고 SSH 원격 URL이 있는 기존 Git 리포지토리를 풀링하려고 시도합니다. 서버가 연결을 거부해야 합니다.

   1. **프라이머리** 사이트에서:
      1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
      1. 왼쪽 사이드바에서 **모니터링** > **백그라운드 작업**을 선택합니다.
      1. Sidekiq 대시보드에서 **Cron**을 선택합니다.
      1. `Disable All`을(를) 선택하여 비-Geo 주기적 백그라운드 작업을 비활성화합니다.
      1. `geo_sidekiq_cron_config_worker` cron 작업에 대해 `Enable`을(를) 선택합니다. 이 작업은 계획된 장애 조치가 성공적으로 완료되는 데 필수적인 여러 다른 cron 작업을 다시 활성화합니다.

1. 모든 데이터 복제 및 확인을 완료합니다:

   > [!warning]
   > 모든 데이터가 자동으로 복제되는 것은 아닙니다. [제외된 항목](../planned_failover.md#not-all-data-is-automatically-replicated)에 대해 자세히 알아보세요.

   1. Geo에서 관리하지 않는 모든 [데이터](../../replication/datatypes.md#replicated-data-types)를 수동으로 복제하는 경우 지금 최종 복제 프로세스를 트리거하세요.
   1. **프라이머리** 사이트에서:
      1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
      1. 왼쪽 사이드바에서 **모니터링** > **백그라운드 작업**을 선택합니다.
      1. Sidekiq 대시보드에서 **Queues**를 선택하고 이름에 `geo`가 있는 항목을 제외한 모든 큐가 0으로 떨어질 때까지 기다립니다. 이러한 큐에는 사용자가 제출한 작업이 포함되어 있습니다. 완료되기 전에 장애 조치하면 작업이 손실됩니다.
      1. 왼쪽 사이드바에서 **Geo** > **사이트**를 선택하고 장애 조치 중인 **세컨더리** 사이트에 대해 다음 조건이 참인지 확인할 때까지 기다립니다:

         - 모든 복제 미터가 100% 복제됨, 0% 실패.
         - 모든 확인 미터가 100% 확인됨, 0% 실패.
         - 데이터베이스 복제 지연 시간은 0 ms입니다.
         - Geo 로그 커서는 최신 (0 이벤트 뒤쪽)입니다.

   1. **세컨더리** 사이트에서:
      1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
      1. 왼쪽 사이드바에서 **모니터링** > **백그라운드 작업**을 선택합니다.
      1. Sidekiq 대시보드에서 **Queues**를 선택하고 모든 `geo` 큐가 대기 중인 0개, 실행 중인 0개의 작업으로 떨어질 때까지 기다립니다.
      1. [무결성 점검 실행](../../../raketasks/check.md)을 수행하여 CI 아티팩트, LFS 객체 및 파일 스토리지의 업로드 무결성을 검증합니다.

   이 시점에서 **세컨더리** 사이트에는 **프라이머리** 사이트가 가지고 있는 모든 항목의 최신 복사본이 있으므로 장애 조치할 때 아무것도 손실되지 않습니다.

1. 이 최종 단계에서는 **프라이머리** 사이트를 영구적으로 비활성화해야 합니다.

   > [!warning]
   > **프라이머리** 사이트가 오프라인 상태가 되면 **세컨더리** 사이트에 복제되지 않은 **프라이머리** 사이트에 저장된 데이터가 있을 수 있습니다. 진행하면 이 데이터는 손실된 것으로 취급되어야 합니다.

   [**프라이머리** 도메인 DNS 레코드를 업데이트](../_index.md#optional-updating-the-primary-domain-dns-record)할 계획이라면 지금 TTL을 낮춰 전파 속도를 높일 수 있습니다.

   장애 조치를 수행할 때 두 개의 다른 GitLab 인스턴스에서 쓰기가 발생할 수 있는 스플릿 브레인 상황을 피하고자 합니다. 따라서 장애 조치를 준비하려면 **프라이머리** 사이트를 비활성화해야 합니다:

   - **프라이머리** 사이트에 SSH 액세스 권한이 있는 경우 GitLab을 중지하고 비활성화합니다:

     ```shell
     sudo gitlab-ctl stop
     ```

     서버가 예기치 않게 재부팅될 경우 GitLab이 다시 시작되지 않도록 방지합니다:

     ```shell
     sudo systemctl disable gitlab-runsvdir
     ```

     > [!note]
     >
     > - CentOS 6 이상에서는 머신이 재부팅할 때 GitLab이 시작되지 않도록 방지하기가 어려운 경우가 있습니다([이슈 3058](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3058) 참조). `sudo yum remove gitlab-ee`를 사용하여 GitLab 패키지를 완전히 제거하는 것이 가장 안전할 수 있습니다.
     > - Ubuntu 14.04 LTS 같은 이전 버전이나 Upstart init 시스템을 기반으로 하는 다른 배포판을 사용하는 경우, `root`로 머신이 재부팅할 때 GitLab이 시작되지 않도록 방지할 수 있습니다 `initctl stop gitlab-runsvvdir && echo 'manual' > /etc/init/gitlab-runsvdir.override && initctl reload-configuration`.

   - **프라이머리** 사이트에 SSH 액세스 권한이 없는 경우 머신을 오프라인 상태로 만들고 재부팅되지 않도록 방지합니다. 이를 달성할 수 있는 많은 방법이 있으므로 단일 권장 사항을 피합니다. 다음 작업을 수행해야 할 수 있습니다:

     - 로드 밸런서를 다시 구성합니다.
     - DNS 레코드를 변경합니다(**프라이머리** DNS 레코드를 **세컨더리** 사이트로 가리킵니다. **프라이머리** 사이트 사용을 중지합니다).
     - 가상 서버를 중지합니다.
     - 방화벽을 통해 트래픽을 차단합니다.
     - **프라이머리** 사이트에서 객체 저장소 권한을 취소합니다.
     - 머신의 물리적 연결을 끊습니다.

### **세컨더리** 사이트 승격 {#promoting-the-secondary-site}

세컨더리를 프로모션할 때 다음을 참고합니다:

- 이때 새로운 **세컨더리**를 추가하지 않아야 합니다. 새로운 **세컨더리**를 추가하려면 **세컨더리**를 **프라이머리**로 프로모션하는 전체 프로세스를 완료한 후 수행하세요.
- 이 프로세스 중에 `ActiveRecord::RecordInvalid: Validation failed: Name has already been taken` 오류가 발생하면 [문제 해결 조언](../failover_troubleshooting.md#fixing-errors-during-a-failover-or-when-promoting-a-secondary-to-a-primary-site)을 읽으세요.

세컨더리 사이트를 프로모션하려면:

1. **세컨더리** 사이트에 SSH 접속하여 다음 명령 중 하나를 실행합니다:

   - 세컨더리 사이트를 프라이머리로 승격하려면:

     ```shell
     sudo gitlab-ctl geo promote
     ```

   - **without any further confirmation** 사이트를 프라이머리로 승격하되 추가 확인 없이:

     ```shell
     sudo gitlab-ctl geo promote --force
     ```

1. 이전에 **세컨더리** 사이트에 사용한 URL을 사용하여 새로 승격된 **프라이머리** 사이트에 연결할 수 있는지 확인합니다.

   성공한 경우 **세컨더리** 사이트가 이제 **프라이머리** 사이트로 승격되었습니다.

### 다음 단계 {#next-steps}

지리적 중복성을 최대한 빨리 복구하려면 [새 **세컨더리** 사이트 추가](../../setup/_index.md)해야 합니다. 이를 수행하려면 이전 **프라이머리**를 새 세컨더리로 다시 추가하고 다시 온라인으로 전환할 수 있습니다.
