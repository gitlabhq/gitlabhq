---
stage: Shared responsibility based on functional area
group: Shared responsibility based on functional area
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Redis 내보내기
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

[Redis 내보내기](https://github.com/oliver006/redis_exporter) 를 통해 다양한 [Redis](https://redis.io) 메트릭을 측정할 수 있습니다. 내보낸 항목에 대한 자세한 내용은 [업스트림 설명서를 읽으세요](https://github.com/oliver006/redis_exporter/blob/master/README.md#whats-exported).

자체 컴파일 설치의 경우 직접 설치 및 구성해야 합니다.

Redis 내보내기를 활성화하려면:

1. [Prometheus 활성화](_index.md#configuring-prometheus)
1. `/etc/gitlab/gitlab.rb`을 편집합니다.
1. 다음 줄을 추가(또는 찾아서 주석 해제)하고 `true`로 설정했는지 확인합니다:

   ```ruby
   redis_exporter['enable'] = true
   ```

1. 파일을 저장하고 [GitLab을 재구성](../../restart_gitlab.md#reconfigure-a-linux-package-installation)하여 변경 사항을 적용합니다.

Prometheus는 `localhost:9121`에서 노출된 Redis 내보내기에서 성능 데이터 수집을 시작합니다.

## Redis 내보내기 플래그 구성 {#configure-the-redis-exporter-flags}

`redis_exporter['flags']` 설정을 사용하여 [명령줄 플래그](https://github.com/oliver006/redis_exporter/blob/master/README.md#command-line-flags)를 전달하고 모니터링 요구 사항에 따라 Redis 내보내기 동작을 사용자 지정할 수 있습니다.

> [!note]
> `redis.addr`는 `gitlab_rails[redis_*]` 값(예: `gitlab_rails[redis_host]`)으로 구성되므로 사용할 수 없습니다.

Redis 내보내기 플래그를 구성하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하고 플래그를 추가합니다(예제):

   ```ruby
   redis_exporter['flags'] = {
     'redis.password' => 'your-redis-password',
     'namespace' => 'redis',
     'web.listen-address' => ':9121',
     'web.telemetry-path' => '/metrics'
   }
   ```

1. GitLab을 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```
