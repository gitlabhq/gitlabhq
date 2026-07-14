---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo 비활성화
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

테스트 후 일반 Linux 패키지 설치 설정으로 되돌리거나, 재해 복구 상황이 발생하여 Geo를 일시적으로 비활성화하려는 경우, 이 지침을 사용하여 Geo 설정을 비활성화할 수 있습니다.

Geo를 비활성화하는 것과 정확하게 제거한 경우 보조 Geo 사이트가 없는 활성 Geo 설정을 유지하는 것 사이에는 기능상 차이가 없어야 합니다.

Geo를 비활성화하려면 다음 단계를 따릅니다:

1. [모든 보조 Geo 사이트 제거](#remove-all-secondary-geo-sites)
1. [UI에서 프라이머리 사이트 제거](#remove-the-primary-site-from-the-ui)
1. [보조 복제 슬롯 제거](#remove-secondary-replication-slots)
1. [Geo 관련 구성 제거](#remove-geo-related-configuration)
1. [선택사항입니다. PostgreSQL 설정을 되돌려 암호를 사용하고 IP에서 수신 대기](#optional-revert-postgresql-settings-to-use-a-password-and-listen-on-an-ip)

## 모든 보조 Geo 사이트 제거 {#remove-all-secondary-geo-sites}

Geo를 비활성화하려면 먼저 모든 보조 Geo 사이트를 제거해야 하며, 이는 이러한 사이트에서 복제가 더 이상 발생하지 않음을 의미합니다. 설명서에 따라 [보조 Geo 사이트를 제거](remove_geo_site.md)할 수 있습니다.

계속 사용하려는 현재 사이트가 보조 사이트인 경우 먼저 이를 프라이머리로 승격해야 합니다. 다음 단계를 사용하여 [보조 사이트를 승격하는 방법](../disaster_recovery/_index.md#step-2-promoting-a-secondary-site)에 대해 알아볼 수 있습니다.

## UI에서 프라이머리 사이트 제거 {#remove-the-primary-site-from-the-ui}

**프라이머리** 사이트를 제거하려면:

1. [모든 보조 Geo 사이트 제거](remove_geo_site.md)
1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **Geo** > **노드**를 선택합니다.
1. **삭제** 노드에 대해 **프라이머리**를 선택합니다.
1. 프롬프트가 나타나면 **삭제**를 선택하여 확인합니다.

## 보조 복제 슬롯 제거 {#remove-secondary-replication-slots}

보조 복제 슬롯을 제거하려면 프라이머리 Geo 노드에서 PostgreSQL 콘솔(`sudo gitlab-psql`)에서 다음 쿼리 중 하나를 실행합니다:

- 이미 PostgreSQL 클러스터가 있는 경우, 같은 클러스터에서 보조 데이터베이스가 제거되지 않도록 이름별로 개별 복제 슬롯을 삭제합니다. 다음을 사용하여 모든 이름을 가져온 다음 각 개별 슬롯을 삭제할 수 있습니다:

  ```sql
  SELECT slot_name, slot_type, active FROM pg_replication_slots; -- view present replication slots
  SELECT pg_drop_replication_slot('slot_name'); -- where slot_name is the one expected from the previous command
  ```

- 모든 보조 복제 슬롯을 제거하려면:

  ```sql
  SELECT pg_drop_replication_slot(slot_name) FROM pg_replication_slots;
  ```

## Geo 관련 구성 제거 {#remove-geo-related-configuration}

1. 프라이머리 Geo 사이트의 각 노드에 대해 노드에 SSH 접속하고 루트로 로그인합니다:

   ```shell
   sudo -i
   ```

1. `/etc/gitlab/gitlab.rb`를 편집하고 `geo_primary_role`을 활성화한 모든 줄을 제거하여 Geo 관련 구성을 제거합니다:

   ```ruby
   ## In pre-11.5 documentation, the role was enabled as follows. Remove this line.
   geo_primary_role['enable'] = true

   ## In 11.5+ documentation, the role was enabled as follows. Remove this line.
   roles ['geo_primary_role']
   ```

1. 이러한 변경을 수행한 후 변경 사항이 적용되도록 [GitLab을 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)합니다.

## (선택사항) PostgreSQL 설정을 되돌려 암호를 사용하고 IP에서 수신 대기 {#optional-revert-postgresql-settings-to-use-a-password-and-listen-on-an-ip}

PostgreSQL 관련 설정을 제거하고 기본값으로 되돌리려는 경우(대신 소켓 사용), `/etc/gitlab/gitlab.rb` 파일에서 다음 줄을 안전하게 제거할 수 있습니다:

```ruby
postgresql['sql_user_password'] = '...'
gitlab_rails['db_password'] = '...'
postgresql['listen_address'] = '...'
postgresql['md5_auth_cidr_addresses'] =  ['...', '...']
```
