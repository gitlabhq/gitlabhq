---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 시간대 변경하기
description: 인스턴스의 시간대를 변경합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

> [!note]
> 사용자는 프로필에서 [시간대를 설정](../user/profile/_index.md#set-your-time-zone)할 수 있습니다. 새 사용자는 기본 시간대가 없으며, 프로필에 표시되기 전에 명시적으로 설정해야 합니다. GitLab.com에서 기본 시간대는 UTC입니다.

GitLab의 기본 시간대는 UTC이지만, 원하는 시간대로 변경할 수 있습니다.

GitLab 인스턴스의 시간대를 업데이트하려면:

1. 지정된 시간대는 [tz 형식](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)이어야 합니다. `timedatectl` 명령을 사용하여 사용 가능한 시간대를 확인할 수 있습니다:

   ```shell
   timedatectl list-timezones
   ```

1. 시간대를 `America/New_York`로 변경합니다(예: 미국 뉴욕).

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   gitlab_rails['time_zone'] = 'America/New_York'
   ```

1. 파일을 저장한 다음 GitLab을 재구성하고 다시 시작합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="Helm 차트(Kubernetes)" >}}

1. Helm 값을 내보냅니다:

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. `gitlab_values.yaml`을 편집합니다:

   ```yaml
   global:
     time_zone: 'America/New_York'
   ```

1. 파일을 저장하고 새 값을 적용합니다:

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. `docker-compose.yml`을 편집합니다:

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['time_zone'] = 'America/New_York'
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="직접 컴파일(소스)" >}}

1. `/home/git/gitlab/config/gitlab.yml`을 편집합니다:

   ```yaml
   production: &base
     gitlab:
       time_zone: 'America/New_York'
   ```

1. 파일을 저장하고 GitLab을 다시 시작합니다:

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}
