---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo에 강등된 사이트 다시 도입하기
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

장애 조치(failover) 후 강등된 **프라이머리** 사이트를 새로운 **세컨더리** 사이트로 복원하거나 원래 **프라이머리** 사이트를 복원할 수 있습니다. 이 프로세스는 두 가지 단계로 구성됩니다:

1. 이전 **프라이머리** 사이트를 **세컨더리** 사이트로 변경합니다.
1. **세컨더리** 사이트를 **프라이머리** 사이트로 승격합니다.

> [!warning]
>
> - 이 사이트의 데이터 일관성에 대해 의문이 있으면 처음부터 설정해야 합니다.
> - 강등된 프라이머리는 더 이상 Geo와 동기화되지 않는 독립형 GitLab 서버로 간주됩니다.
>
>   새로운 세컨더리 사이트로 다시 추가하기 전에 이전 프라이머리로서의 모든 남은 구성이 제거되었는지 확인하세요.

## 이전 **프라이머리** 사이트를 **세컨더리** 사이트로 구성하기 {#configure-the-former-primary-site-to-be-a-secondary-site}

이전 **프라이머리** 사이트가 현재 **프라이머리** 사이트와 동기화되지 않았으므로 첫 번째 단계는 이전 **프라이머리** 사이트를 최신 상태로 가져오는 것입니다. 디스크에 저장된 리포지토리 및 업로드와 같은 데이터 삭제는 이전 **프라이머리** 사이트를 다시 동기화할 때 재생되지 않으므로 디스크 사용량이 증가할 수 있습니다. 또는 이를 피하기 위해 [새로운 **세컨더리** GitLab 인스턴스를 설정](../setup/_index.md)할 수 있습니다.

이전 **프라이머리** 사이트를 최신 상태로 가져오려면:

1. 뒤처진 이전 **프라이머리** 사이트에 SSH로 연결합니다.
1. 존재할 경우 `/etc/gitlab/gitlab-cluster.json`을(를) 제거합니다. ([`gitlab-cluster.json` 파일이란?](https://docs.gitlab.com/omnibus/development/reconfigure_in_detail/#gitlab-clusterjson-file))

   **세컨더리** 사이트로 다시 추가될 사이트가 `gitlab-ctl geo promote` 명령어로 승격된 경우 `/etc/gitlab/gitlab-cluster.json`을(를) 포함할 수 있습니다. 예를 들어 `gitlab-ctl reconfigure` 중에 다음과 같은 출력을 볼 수 있습니다:

   ```plaintext
   The 'geo_primary_role' is defined in /etc/gitlab/gitlab-cluster.json as 'true' and overrides the setting in the /etc/gitlab/gitlab.rb
   ```

   그렇다면 `/etc/gitlab/gitlab-cluster.json`은(는) 사이트(다중 노드 설정을 사용하는 경우)의 모든 Sidekiq, PostgreSQL, Gitaly 및 Rails 노드에서 삭제되어야 `/etc/gitlab/gitlab.rb`이(가) 다시 진실의 단일 소스가 됩니다.

1. 모든 서비스가 실행 중인지 확인합니다:

   ```shell
   sudo gitlab-ctl start
   ```

   > [!note]
   > - [**프라이머리** 사이트를 영구적으로 비활성화](_index.md#step-1-permanently-disable-the-primary-site)한 경우 지금 해당 단계를 실행 취소해야 합니다. Debian/Ubuntu/CentOS7+와 같은 systemd를 사용하는 배포판의 경우 `sudo systemctl enable gitlab-runsvdir`을(를) 실행해야 합니다. CentOS 6과 같은 systemd가 없는 배포판의 경우 GitLab 인스턴스를 처음부터 설치하고 [설정 지침](../setup/_index.md)을 따라 **세컨더리** 사이트로 설정해야 합니다. 이 경우 다음 단계를 따를 필요가 없습니다.
   > - 재해 복구 절차 중에 이 사이트의 [DNS 레코드를 변경](_index.md#optional-updating-the-primary-domain-dns-record) 한 경우 이 절차 중에 [이 사이트에 대한 모든 쓰기를 차단](planned_failover.md#prevent-updates-to-the-primary-site)해야 할 수 있습니다.

1. [Geo 설정](../setup/_index.md)합니다. 이 경우 **세컨더리** 사이트는 이전 **프라이머리** 사이트를 말합니다.
   1. [PgBouncer](../../postgresql/pgbouncer.md)가 **current secondary** 사이트(프라이머리였을 때)에서 활성화된 경우 `/etc/gitlab/gitlab.rb`을(를) 편집하고 `sudo gitlab-ctl reconfigure`을(를) 실행하여 비활성화합니다.
   1. 그러면 **세컨더리** 사이트에서 데이터베이스 복제를 설정할 수 있습니다.
   1. 다시 도입된 **세컨더리** 사이트에서 Geo 추적 데이터베이스 스키마를 초기화합니다.

      `gitlab-ctl replicate-geo-database`은(는) 주요 `gitlabhq_production` 데이터베이스만 복제합니다. Geo 추적 데이터베이스(`gitlabhq_geo_production`)는 **세컨더리** 사이트에 로컬이며 일반적으로 `sudo gitlab-ctl reconfigure`에 의해 `geo_secondary['auto_migrate']`을(를) 통해 마이그레이션됩니다. `auto_migrate`이(가) 비활성화되거나 추적 데이터베이스가 외부이거나 마지막 재구성 실행 시 비어 있었던 경우 Geo Log Cursor가 중지되고 모든 동기화 유형이 0%로 유지됩니다.

      이 경우 **세컨더리** 사이트의 Rails 또는 Sidekiq 노드에서:
      
      1. [추적 데이터베이스 마이그레이션을 수동으로 실행](../setup/external_database.md#set-up-the-database-schema)합니다.
      1. Geo Log Cursor를 다시 시작하여 새 스키마를 선택합니다:

         ```shell
         sudo gitlab-ctl restart geo-logcursor
         ```

      1. 계속하기 전에 추적 데이터베이스가 올바르게 설정되었는지 확인합니다:

         ```shell
         # Confirm the tracking database has tables
         sudo gitlab-geo-psql -d gitlabhq_geo_production -c "\dt"

         # Confirm all tracking database migrations are applied
         sudo gitlab-rake db:migrate:status:geo | grep -w down

         # Run the full Geo check
         sudo gitlab-rake gitlab:geo:check
         ```

      `db:migrate:status:geo` 명령어는 `down` 마이그레이션을 반환하지 않아야 하고 `gitlab:geo:check`은(는) 출력에서 `GitLab Geo tracking database is correctly configured ... yes`를 보고해야 합니다.

   1. OpenBao를 위한 JWT 대상 구성합니다. GitLab Secrets Manager를 활성화했고 프라이머리 및 세컨더리 사이트가 동일한 JWT 대상을 공유하지 않는 경우 다시 추가된 세컨더리의 Helm 값에서 `jwt_audience`을(를) 새로운 프라이머리의 OpenBao URL로 설정합니다:

      ```yaml
      global:
        openbao:
          enabled: true
          url: https://openbao.old-primary.example.com:8200
          jwt_audience: https://openbao.promoted.example.com:8200
      ```

원래 **프라이머리** 사이트를 잃어버린 경우 [설정 지침](../setup/_index.md)을 따라 새로운 **세컨더리** 사이트를 설정합니다.

## **세컨더리** 사이트를 **프라이머리** 사이트로 승격하기 {#promote-the-secondary-site-to-primary-site}

초기 복제가 완료되고 **프라이머리** 사이트와 **세컨더리** 사이트가 거의 동기화되면 [계획된 장애 조치](planned_failover.md)를 수행할 수 있습니다.

## **세컨더리** 사이트 복원 {#restore-the-secondary-site}

두 개의 사이트를 다시 갖는 것이 목표인 경우 **세컨더리** 사이트에 대해 첫 번째 단계([이전 **프라이머리** 사이트를 **세컨더리** 사이트로 구성](#configure-the-former-primary-site-to-be-a-secondary-site))를 반복하여 **세컨더리** 사이트를 다시 온라인 상태로 가져와야 합니다.

### 추가 **세컨더리** 사이트 복원 {#restoring-additional-secondary-sites}

세 개 이상의 **세컨더리** 사이트가 있는 경우 나머지 사이트를 지금 온라인 상태로 가져올 수 있습니다. 남은 각 사이트에 대해 [복제 프로세스를 시작](../setup/database.md#step-3-initiate-the-replication-process)하고 **프라이머리** 사이트와 함께 수행합니다.

## **세컨더리** 사이트의 데이터 재전송 건너뛰기 {#skipping-re-transfer-of-data-on-a-secondary-site}

세컨더리 사이트를 추가할 때 프라이머리에서 동기화될 수 있는 데이터가 포함되어 있으면 Geo는 데이터 재전송을 방지합니다.

- Git 리포지토리는 `git fetch`으로 전송되며 누락된 참조만 전송합니다.
- Geo의 컨테이너 레지스트리 동기화 코드는 태그 및 다이제스트의 튜플을 비교하고 누락된 것만 가져옵니다.
- [Blobs](#skipping-re-transfer-of-blobs)는 첫 번째 동기화에서 존재하면 건너뜁니다.

사용 사례:

- 계획된 장애 조치를 수행하고 이를 세컨더리 사이트로 연결하여 이전 프라이머리 사이트를 강등합니다. 재구성하지 않습니다.
- 여러 개의 세컨더리 Geo 사이트가 있습니다. 계획된 장애 조치를 수행하고 다른 세컨더리 Geo 사이트를 재구성하지 않고 다시 연결합니다.
- 세컨더리 사이트를 승격 및 강등하여 장애 조치 테스트를 수행하고 재구성하지 않고 다시 연결합니다.
- 백업을 복원하고 사이트를 세컨더리 사이트로 연결합니다.
- 동기화 문제를 해결하기 위해 세컨더리 사이트에 데이터를 수동으로 복사합니다.
- 문제를 해결하기 위해 Geo 추적 데이터베이스에서 레지스트리 테이블 행을 삭제하거나 자릅니다.
- 문제를 해결하기 위해 Geo 추적 데이터베이스를 재설정합니다.

### Blobs 재전송 건너뛰기 {#skipping-re-transfer-of-blobs}

{{< history >}}

- `geo_skip_download_if_exists`라는 이름의 [플래그와 함께](../../feature_flags/_index.md) GitLab 16.8에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/352530). 기본적으로 비활성화됨.
- GitLab 16.9에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/435788)합니다. 기능 플래그 `geo_skip_download_if_exists` 제거됨.

{{< /history >}}

기존 블롭 데이터가 있는 세컨더리 사이트를 추가하면 세컨더리 Geo 사이트는 해당 데이터의 재전송을 방지합니다. 이는 다음에 적용됩니다:

- 작업 아티팩트
- CI 파이프라인 아티팩트
- CI 보안 파일
- LFS 객체
- 머지 리퀘스트 차이
- 패키지 파일
- 페이지 배포
- Terraform 상태 버전
- 업로드
- 종속성 프록시 매니페스트
- 종속성 프록시 블롭

세컨더리 사이트의 복사본이 실제로 손상된 경우 백그라운드 검증이 결국 실패하고 블롭이 다시 동기화됩니다.

Blobs는 Geo 추적 데이터베이스에서 해당 레지스트리 레코드가 없는 경우에만 이러한 방식으로 건너뜁니다. 재동기화는 거의 항상 의도적이고 실수로 전송을 건너뛸 위험이 있으므로 조건이 엄격합니다.
