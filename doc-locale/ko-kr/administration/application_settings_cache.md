---
stage: None
group: Unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 애플리케이션 캐시 간격
description: GitLab 애플리케이션 캐시를 관리합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

기본적으로 GitLab은 애플리케이션 설정을 60초 동안 캐시합니다. 애플리케이션 설정 변경과 사용자가 애플리케이션에서 그 변경 사항을 인식하는 사이에 더 많은 지연을 갖도록 해당 간격을 늘려야 할 경우가 있습니다.

이 값을 `0` 초보다 크게 설정하는 것을 권장합니다. `0`로 설정하면 모든 요청에 대해 `application_settings` 테이블이 로드됩니다. 이로 인해 Redis 및 PostgreSQL에 추가 부하가 발생합니다.

## 애플리케이션 캐시 만료 간격 변경 {#change-the-expiration-interval-for-application-cache}

만료 값을 변경하려면:

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. `/etc/gitlab/gitlab.rb`을 편집합니다:

   ```ruby
   gitlab_rails['application_settings_cache_seconds'] = 60
   ```

1. 파일을 저장한 후 GitLab을 재구성 및 다시 시작하여 변경 사항을 적용합니다:

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

{{< /tab >}}

{{< tab title="자체 컴파일(소스)" >}}

1. `config/gitlab.yml`을 편집합니다:

   ```yaml
   gitlab:
     application_settings_cache_seconds: 60
   ```

1. 파일을 저장한 후 [다시 시작](restart_gitlab.md#self-compiled-installations)하여 GitLab의 변경 사항을 적용합니다.

{{< /tab >}}

{{< /tabs >}}
