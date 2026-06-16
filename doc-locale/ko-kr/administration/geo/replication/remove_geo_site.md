---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 세컨더리 Geo 사이트 제거
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

**세컨더리** 사이트는 **프라이머리** 사이트의 Geo 관리 페이지를 사용하여 Geo 클러스터에서 제거할 수 있습니다. **세컨더리** 사이트를 제거하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **Geo** > **노드**를 선택합니다.
1. 제거하려는 **세컨더리** 사이트에서 **삭제**를 선택합니다.
1. 프롬프트가 나타나면 **삭제**를 선택하여 확인합니다.

**세컨더리** 사이트가 Geo 관리 페이지에서 제거된 후에는 이 사이트를 중지하고 제거해야 합니다. 세컨더리 Geo 사이트의 각 노드에 대해:

1. GitLab을 중지합니다:

   ```shell
   sudo gitlab-ctl stop
   ```

1. GitLab을 제거합니다:

   > [!note]
   > GitLab 데이터를 인스턴스에서도 정리해야 하는 경우 [Linux 패키지 및 모든 데이터 제거](https://docs.gitlab.com/omnibus/installation/#uninstall-the-linux-package-omnibus) 방법을 참조하세요.

   ```shell
   # Stop gitlab and remove its supervision process
   sudo gitlab-ctl uninstall

   # Debian/Ubuntu
   sudo dpkg --remove gitlab-ee

   # Redhat/Centos
   sudo rpm --erase gitlab-ee
   ```

GitLab이 **세컨더리** 사이트의 각 노드에서 제거된 후에는 복제 슬롯을 **프라이머리** 사이트의 데이터베이스에서 다음과 같이 삭제해야 합니다:

1. **프라이머리** 사이트의 데이터베이스 노드에서 PostgreSQL 콘솔 세션을 시작합니다:

   ```shell
   sudo gitlab-psql
   ```

   > [!note]
   > `gitlab-rails dbconsole`는 복제 슬롯을 관리할 때 수퍼사용자 권한이 필요하기 때문에 작동하지 않습니다.

1. 관련 복제 슬롯의 이름을 찾습니다. 이는 복제 명령 `gitlab-ctl replicate-geo-database`을 실행할 때 `--slot-name`으로 지정된 슬롯입니다.

   ```sql
   SELECT * FROM pg_replication_slots;
   ```

1. **세컨더리** 사이트의 복제 슬롯을 제거합니다:

   ```sql
   SELECT pg_drop_replication_slot('<name_of_slot>');
   ```
